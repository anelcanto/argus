defmodule Argus.Sync.Poller do
  @moduledoc false
  use GenServer
  require Logger

  import Ecto.Query

  alias Argus.{Accounts, Repo}
  alias Argus.Accounts.User
  alias Argus.Cache.PrCache
  alias Argus.Github.Client, as: GithubClient
  alias Argus.Gitlab.Client, as: GitlabClient
  alias Argus.PullRequests.PullRequest

  @poll_interval :timer.minutes(5)
  @max_concurrency 5

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def refresh_user(user_id) do
    GenServer.cast(__MODULE__, {:refresh_user, user_id})
  end

  @impl true
  def init(_opts) do
    schedule_poll()
    {:ok, %{rate_limited: false}}
  end

  @impl true
  def handle_info(:poll, %{rate_limited: true} = state) do
    Logger.info("Poller: skipping poll due to rate limit")
    schedule_poll()
    {:noreply, %{state | rate_limited: false}}
  end

  def handle_info(:poll, state) do
    users = Repo.all(from u in User, select: u)
    poll_users(users)
    schedule_poll()
    {:noreply, state}
  end

  @impl true
  def handle_cast({:refresh_user, user_id}, state) do
    user = Accounts.get_user!(user_id)
    fetch_and_broadcast(user)
    {:noreply, state}
  end

  defp poll_users(users) do
    Task.async_stream(
      users,
      fn user -> fetch_and_broadcast(user) end,
      max_concurrency: @max_concurrency,
      timeout: :timer.minutes(2)
    )
    |> Stream.run()
  end

  defp fetch_and_broadcast(user) do
    {github_status, github_prs} = fetch_github_prs(user)
    {gitlab_status, gitlab_mrs} = fetch_gitlab_mrs(user)

    all_prs = github_prs ++ gitlab_mrs

    if all_prs != [] or has_any_token?(user) do
      github_ids = github_prs |> Enum.filter(&(&1.source == :github)) |> Enum.map(& &1.number)
      gitlab_ids = gitlab_mrs |> Enum.filter(&(&1.source == :gitlab)) |> Enum.map(& &1.number)

      PrCache.upsert_all(user.id, all_prs)
      if github_status == :ok, do: PrCache.sync(user.id, github_ids, "github")
      if gitlab_status == :ok, do: PrCache.sync(user.id, gitlab_ids, "gitlab")

      Phoenix.PubSub.broadcast(
        Argus.PubSub,
        "pr_updates:#{user.id}",
        {:prs_updated, all_prs}
      )
    end
  end

  defp has_any_token?(user) do
    not is_nil(Accounts.get_decrypted_token(user)) or
      not is_nil(Accounts.get_decrypted_gitlab_token(user))
  end

  defp fetch_github_prs(user) do
    token = Accounts.get_decrypted_token(user)

    if token do
      Logger.debug("Poller: fetching GitHub PRs for #{user.login}")

      case GithubClient.list_open_prs(token, user.login) do
        {:ok, issues} ->
          {:ok, enrich_github_prs(token, issues)}

        {:error, :rate_limited} ->
          Logger.warning("Poller: GitHub rate limited for user #{user.login}")
          {:error, []}

        {:error, reason} ->
          Logger.error("Poller: GitHub error for #{user.login}: #{inspect(reason)}")
          {:error, []}
      end
    else
      Logger.info(
        "Poller: skipping GitHub for #{user.login} — token decrypt returned nil (github_token in DB: #{not is_nil(user.github_token)})"
      )

      {:skip, []}
    end
  end

  defp fetch_gitlab_mrs(user) do
    token = Accounts.get_decrypted_gitlab_token(user)
    username = user.gitlab_username
    base_url = user.gitlab_url

    if token && username do
      case GitlabClient.list_open_mrs(token, username, base_url) do
        {:ok, mrs} ->
          {:ok, enrich_gitlab_mrs(token, mrs, base_url)}

        {:error, :unauthorized} ->
          Logger.warning("Poller: GitLab unauthorized for user #{username}")
          {:error, []}

        {:error, :rate_limited} ->
          Logger.warning("Poller: GitLab rate limited for user #{username}")
          {:error, []}

        {:error, reason} ->
          Logger.error("Poller: GitLab error for #{username}: #{inspect(reason)}")
          {:error, []}
      end
    else
      Logger.info(
        "Poller: skipping GitLab for #{user.login} (token=#{not is_nil(token)}, username=#{inspect(username)})"
      )

      {:skip, []}
    end
  end

  defp enrich_github_prs(token, issues) do
    Task.async_stream(
      issues,
      &enrich_github_issue(token, &1),
      max_concurrency: @max_concurrency,
      timeout: :timer.seconds(30)
    )
    |> Enum.flat_map(fn
      {:ok, pr} ->
        [pr]

      {:error, reason} ->
        Logger.warning("Poller: GitHub enrichment error #{inspect(reason)}") && []
    end)
  end

  defp enrich_github_issue(token, issue) do
    [owner, repo] = parse_repo(issue["repository_url"] || "")
    number = issue["number"]
    head_sha = get_in(issue, ["pull_request", "head", "sha"])

    pr_details =
      case GithubClient.get_pr_details(token, owner, repo, number) do
        {:ok, details} -> details
        _ -> nil
      end

    check_runs = fetch_check_runs(token, owner, repo, head_sha)

    review_data =
      case GithubClient.get_review_threads(token, owner, repo, number) do
        {:ok, data} -> data
        _ -> %{}
      end

    PullRequest.from_api(issue, pr_details, check_runs, review_data)
  end

  defp enrich_gitlab_mrs(token, mrs, base_url) do
    Task.async_stream(
      mrs,
      &enrich_gitlab_mr(token, &1, base_url),
      max_concurrency: @max_concurrency,
      timeout: :timer.seconds(30)
    )
    |> Enum.flat_map(fn
      {:ok, mr} ->
        [mr]

      {:error, reason} ->
        Logger.warning("Poller: GitLab enrichment error #{inspect(reason)}") && []
    end)
  end

  defp enrich_gitlab_mr(token, mr, base_url) do
    project_id = mr["project_id"]
    mr_iid = mr["iid"]

    pipelines =
      case GitlabClient.get_mr_pipelines(token, project_id, mr_iid, base_url) do
        {:ok, p} -> p
        _ -> []
      end

    discussions =
      case GitlabClient.get_mr_discussions(token, project_id, mr_iid, base_url) do
        {:ok, d} -> d
        _ -> []
      end

    PullRequest.from_gitlab_api(mr, pipelines, discussions)
  end

  defp fetch_check_runs(_token, _owner, _repo, nil), do: []

  defp fetch_check_runs(token, owner, repo, sha) do
    case GithubClient.get_check_runs(token, owner, repo, sha) do
      {:ok, runs} -> runs
      _ -> []
    end
  end

  defp parse_repo(url) do
    case Regex.run(~r{/repos/([^/]+)/([^/]+)$}, url) do
      [_, owner, name] -> [owner, name]
      _ -> [nil, nil]
    end
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end
end
