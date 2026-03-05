defmodule Argus.Github.Client do
  @moduledoc false
  alias Argus.Github.Graphql
  require Logger

  @base_url "https://api.github.com"
  @graphql_url "https://api.github.com/graphql"

  defp build_client(token) do
    Req.new(
      base_url: @base_url,
      headers: [
        {"authorization", "token #{token}"},
        {"accept", "application/vnd.github+json"},
        {"x-github-api-version", "2022-11-28"}
      ],
      retry: :transient,
      retry_delay: fn attempt -> :timer.seconds(attempt * 2) end,
      max_retries: 3
    )
  end

  def list_open_prs(token, login, orgs \\ nil) do
    client = build_client(token)
    orgs = orgs || Application.get_env(:argus, :github_orgs, [])

    if orgs == [] do
      query = "is:pr is:open author:#{login}"
      fetch_pr_search(client, query)
    else
      items =
        orgs
        |> Task.async_stream(
          fn org ->
            query = "is:pr is:open author:#{login} org:#{org}"
            fetch_pr_search(client, query)
          end,
          timeout: :timer.seconds(30)
        )
        |> Enum.flat_map(fn
          {:ok, {:ok, fetched}} -> fetched
          _ -> []
        end)

      {:ok, items}
    end
  end

  defp fetch_pr_search(client, query) do
    case Req.get(client, url: "/search/issues", params: [q: query, per_page: 100]) do
      {:ok, %{status: 200, body: %{"items" => items}} = resp} ->
        track_rate_limit(resp)
        {:ok, items}

      {:ok, %{status: 403}} ->
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("GitHub PR search failed: #{status} #{inspect(body)}")
        {:error, {:http_error, status}}

      {:error, reason} ->
        Logger.error("GitHub PR search error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_pr_details(token, owner, repo, number) do
    client = build_client(token)

    case Req.get(client, url: "/repos/#{owner}/#{repo}/pulls/#{number}") do
      {:ok, %{status: 200, body: pr} = resp} ->
        track_rate_limit(resp)
        {:ok, pr}

      {:ok, %{status: 403}} ->
        {:error, :rate_limited}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_check_runs(token, owner, repo, ref) do
    client = build_client(token)

    case Req.get(client,
           url: "/repos/#{owner}/#{repo}/commits/#{ref}/check-runs",
           params: [per_page: 100]
         ) do
      {:ok, %{status: 200, body: %{"check_runs" => runs}} = resp} ->
        track_rate_limit(resp)
        {:ok, runs}

      {:ok, %{status: 403}} ->
        {:error, :rate_limited}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_review_threads(token, owner, repo, number) do
    query = Graphql.review_threads_query()

    client =
      Req.new(
        url: @graphql_url,
        headers: [
          {"authorization", "bearer #{token}"},
          {"content-type", "application/json"}
        ],
        retry: :transient,
        max_retries: 3
      )

    body =
      Jason.encode!(%{
        query: query,
        variables: %{owner: owner, repo: repo, number: number}
      })

    case Req.post(client, body: body) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        pr = get_in(data, ["repository", "pullRequest"]) || %{}
        threads = get_in(pr, ["reviewThreads", "nodes"]) || []
        review_decision = pr["reviewDecision"]
        {:ok, %{threads: threads, review_decision: review_decision}}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("GraphQL error: #{status} #{inspect(body)}")
        {:error, {:graphql_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate_token(token) do
    client = build_client(token)

    case Req.get(client, url: "/user") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, %{id: to_string(body["id"]), login: body["login"]}}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp track_rate_limit(%{headers: headers}) do
    remaining = headers["x-ratelimit-remaining"]

    if remaining && String.to_integer(List.first(remaining) || "60") < 10 do
      Logger.warning("GitHub rate limit low: #{remaining} remaining")
    end
  end
end
