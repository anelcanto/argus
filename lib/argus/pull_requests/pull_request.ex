defmodule Argus.PullRequests.PullRequest do
  @moduledoc false
  defstruct [
    :id,
    :number,
    :title,
    :url,
    :repo_owner,
    :repo_name,
    :branch,
    :base_branch,
    :author,
    :draft,
    :mergeable,
    :ci_state,
    :checks,
    :review_state,
    :review_decision,
    :unresolved_comments,
    :has_merge_conflicts,
    :computed_state,
    :created_at,
    :updated_at,
    source: :github
  ]

  alias Argus.PullRequests.{CheckStatus, PrState, ReviewThread}

  def from_api(issue, pr_details \\ nil, check_runs \\ [], review_data \\ %{}) do
    repo_url = issue["repository_url"] || ""
    [repo_owner, repo_name] = parse_repo_from_url(repo_url)

    checks = Enum.map(check_runs, &CheckStatus.from_api/1)
    threads = parse_review_threads(review_data)
    review_decision = review_data[:review_decision]

    ci_state = classify_ci(checks)
    unresolved = Enum.count(threads, &(not &1.resolved))

    mergeable = pr_details && pr_details["mergeable"]
    has_conflicts = mergeable == false

    pr = %__MODULE__{
      id: issue["id"],
      number: issue["number"],
      title: issue["title"],
      url: issue["html_url"],
      repo_owner: repo_owner,
      repo_name: repo_name,
      branch: get_in(pr_details || %{}, ["head", "ref"]),
      base_branch: get_in(pr_details || %{}, ["base", "ref"]),
      author: get_in(issue, ["user", "login"]),
      draft: issue["draft"] || false,
      mergeable: mergeable,
      ci_state: ci_state,
      checks: checks,
      review_state: review_decision,
      review_decision: review_decision,
      unresolved_comments: unresolved,
      has_merge_conflicts: has_conflicts,
      created_at: issue["created_at"],
      updated_at: issue["updated_at"]
    }

    %{pr | computed_state: PrState.classify(pr)}
  end

  def from_gitlab_api(mr, pipelines \\ [], discussions \\ []) do
    project = mr["references"] || %{}
    namespace = project["full"] || ""

    [repo_owner, repo_name] =
      case String.split(String.replace(namespace, ~r/![0-9]+$/, ""), "/", parts: 2) do
        [owner, name] -> [owner, name]
        _ -> [nil, to_string(mr["project_id"])]
      end

    ci_state = classify_gitlab_ci(pipelines)
    unresolved = count_unresolved_discussions(discussions)

    pr = %__MODULE__{
      id: mr["id"],
      number: mr["iid"],
      title: mr["title"],
      url: mr["web_url"],
      repo_owner: repo_owner,
      repo_name: repo_name,
      branch: mr["source_branch"],
      base_branch: mr["target_branch"],
      author: get_in(mr, ["author", "username"]),
      draft: mr["draft"] || false,
      mergeable: !mr["has_conflicts"],
      ci_state: ci_state,
      checks: [],
      review_state: nil,
      review_decision: nil,
      unresolved_comments: unresolved,
      has_merge_conflicts: mr["has_conflicts"] || false,
      created_at: mr["created_at"],
      updated_at: mr["updated_at"],
      source: :gitlab
    }

    %{pr | computed_state: PrState.classify(pr)}
  end

  def from_cache(cached) do
    %__MODULE__{
      id: cached.github_pr_id,
      number: cached.number,
      title: cached.title,
      url: cached.url,
      repo_owner: cached.repo_owner,
      repo_name: String.replace(cached.repo_name || "", ~r/![0-9]+$/, ""),
      branch: cached.branch,
      base_branch: cached.base_branch,
      author: cached.author_login,
      draft: cached.is_draft,
      ci_state: cached.ci_state && String.to_atom(cached.ci_state),
      checks: parse_cached_checks(cached.check_runs),
      review_state: cached.review_state,
      review_decision: cached.review_decision,
      unresolved_comments: cached.unresolved_comment_count || 0,
      has_merge_conflicts: cached.has_merge_conflicts,
      computed_state: cached.computed_state && String.to_atom(cached.computed_state),
      created_at: cached.pr_created_at,
      updated_at: cached.pr_updated_at,
      source: (cached.source && String.to_atom(cached.source)) || :github
    }
  end

  defp parse_repo_from_url(url) do
    case Regex.run(~r{/repos/([^/]+)/([^/]+)$}, url) do
      [_, owner, name] -> [owner, name]
      _ -> [nil, nil]
    end
  end

  defp parse_review_threads(%{threads: threads}), do: Enum.map(threads, &ReviewThread.from_api/1)
  defp parse_review_threads(_), do: []

  defp classify_ci([]), do: :pending

  defp classify_ci(checks) do
    cond do
      Enum.any?(checks, &(&1.conclusion == :failure)) -> :failing
      Enum.all?(checks, &(&1.conclusion == :success)) -> :passing
      true -> :pending
    end
  end

  defp parse_cached_checks(nil), do: []

  defp parse_cached_checks(check_runs) when is_list(check_runs) do
    Enum.map(check_runs, fn c ->
      %Argus.PullRequests.CheckStatus{
        name: c["name"],
        status: c["status"] && String.to_atom(c["status"]),
        conclusion: c["conclusion"] && String.to_atom(c["conclusion"]),
        url: c["url"]
      }
    end)
  end

  defp parse_cached_checks(_), do: []

  defp classify_gitlab_ci([]), do: :pending

  defp classify_gitlab_ci(pipelines) do
    latest = List.first(pipelines)

    case latest["status"] do
      "success" -> :passing
      "failed" -> :failing
      "canceled" -> :failing
      _ -> :pending
    end
  end

  defp count_unresolved_discussions(discussions) do
    Enum.count(discussions, fn d ->
      notes = d["notes"] || []
      Enum.any?(notes, fn n -> n["resolvable"] && !n["resolved"] end)
    end)
  end
end
