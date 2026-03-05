defmodule Argus.Cache.PrCache do
  @moduledoc false
  import Ecto.Query
  alias Argus.Cache.CachedPullRequest
  alias Argus.PullRequests.{CheckStatus, PullRequest}
  alias Argus.Repo

  @stale_after_minutes 10

  def upsert_all(user_id, prs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(prs, fn pr ->
        source = pr.source || :github

        %{
          user_id: user_id,
          source: Atom.to_string(source),
          project_id: project_id_for(pr),
          github_pr_id: if(source == :github, do: pr.id, else: nil),
          number: pr.number,
          repo_owner: pr.repo_owner,
          repo_name: pr.repo_name,
          title: pr.title,
          url: pr.url,
          branch: pr.branch,
          base_branch: pr.base_branch,
          author_login: pr.author,
          is_draft: pr.draft || false,
          ci_state: pr.ci_state && Atom.to_string(pr.ci_state),
          check_runs: serialize_checks(pr.checks),
          review_state: pr.review_state,
          review_decision: pr.review_decision,
          unresolved_comment_count: pr.unresolved_comments || 0,
          has_merge_conflicts: pr.has_merge_conflicts || false,
          computed_state: pr.computed_state && Atom.to_string(pr.computed_state),
          pr_created_at: parse_dt(pr.created_at),
          pr_updated_at: parse_dt(pr.updated_at),
          inserted_at: now,
          updated_at: now
        }
      end)

    result =
      Repo.insert_all(
        CachedPullRequest,
        entries,
        on_conflict: {:replace_all_except, [:inserted_at]},
        conflict_target: [:user_id, :source, :repo_owner, :repo_name, :number]
      )

    delete_stale_gitlab_rows(user_id)

    result
  end

  def get_cached_prs(user_id) do
    from(c in CachedPullRequest, where: c.user_id == ^user_id, order_by: [desc: c.pr_updated_at])
    |> Repo.all()
    |> Enum.map(&PullRequest.from_cache/1)
    |> Enum.uniq_by(fn pr -> {pr.source, pr.repo_owner, pr.repo_name, pr.number} end)
  end

  def sync(user_id, current_pr_ids, source \\ "github") do
    from(c in CachedPullRequest,
      where:
        c.user_id == ^user_id and c.source == ^source and
          c.number not in ^current_pr_ids
    )
    |> Repo.delete_all()
  end

  def missing_source?(user_id, source) do
    count =
      from(c in CachedPullRequest,
        where: c.user_id == ^user_id and c.source == ^source,
        select: count(c.id)
      )
      |> Repo.one()

    count == 0
  end

  def stale?(user_id) do
    cutoff = DateTime.add(DateTime.utc_now(), -@stale_after_minutes * 60, :second)

    case from(c in CachedPullRequest,
           where: c.user_id == ^user_id,
           select: max(c.updated_at),
           limit: 1
         )
         |> Repo.one() do
      nil -> true
      last_updated -> DateTime.compare(last_updated, cutoff) == :lt
    end
  end

  def get_user_ids_for_repo(owner, repo_name) do
    from(c in CachedPullRequest,
      where: c.repo_owner == ^owner and c.repo_name == ^repo_name,
      select: c.user_id,
      distinct: true
    )
    |> Repo.all()
  end

  defp delete_stale_gitlab_rows(user_id) do
    from(c in CachedPullRequest,
      where: c.user_id == ^user_id and c.source == "gitlab" and like(c.repo_name, "%!%")
    )
    |> Repo.delete_all()
  end

  defp project_id_for(%{source: :gitlab, repo_owner: owner, repo_name: name})
       when is_binary(owner) and is_binary(name),
       do: "#{owner}/#{name}"

  defp project_id_for(_), do: nil

  defp serialize_checks(nil), do: []

  defp serialize_checks(checks) when is_list(checks) do
    Enum.map(checks, &CheckStatus.to_serializable/1)
  end

  defp parse_dt(nil), do: nil

  defp parse_dt(dt_string) when is_binary(dt_string) do
    case DateTime.from_iso8601(dt_string) do
      {:ok, dt, _} -> DateTime.truncate(dt, :second)
      _ -> nil
    end
  end

  defp parse_dt(%DateTime{} = dt), do: DateTime.truncate(dt, :second)
end
