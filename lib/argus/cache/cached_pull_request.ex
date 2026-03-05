defmodule Argus.Cache.CachedPullRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cached_pull_requests" do
    field :source, :string, default: "github"
    field :project_id, :string
    field :github_pr_id, :integer
    field :number, :integer
    field :repo_owner, :string
    field :repo_name, :string
    field :title, :string
    field :url, :string
    field :branch, :string
    field :base_branch, :string
    field :author_login, :string
    field :is_draft, :boolean, default: false
    field :ci_state, :string
    field :check_runs, {:array, :map}
    field :review_state, :string
    field :review_decision, :string
    field :unresolved_comment_count, :integer, default: 0
    field :has_merge_conflicts, :boolean, default: false
    field :computed_state, :string
    field :pr_created_at, :utc_datetime
    field :pr_updated_at, :utc_datetime

    belongs_to :user, Argus.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(cached \\ %__MODULE__{}, attrs) do
    cached
    |> cast(attrs, [
      :user_id,
      :source,
      :project_id,
      :github_pr_id,
      :number,
      :repo_owner,
      :repo_name,
      :title,
      :url,
      :branch,
      :base_branch,
      :author_login,
      :is_draft,
      :ci_state,
      :check_runs,
      :review_state,
      :review_decision,
      :unresolved_comment_count,
      :has_merge_conflicts,
      :computed_state,
      :pr_created_at,
      :pr_updated_at
    ])
    |> validate_required([:user_id, :number, :repo_name, :source])
    |> unique_constraint([:user_id, :source, :repo_owner, :repo_name, :number])
  end
end
