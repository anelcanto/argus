defmodule Argus.Repo.Migrations.CreateCachedPullRequests do
  use Ecto.Migration

  def change do
    create table(:cached_pull_requests) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :github_pr_id, :bigint, null: false
      add :number, :integer, null: false
      add :repo_owner, :string, null: false
      add :repo_name, :string, null: false
      add :title, :string
      add :url, :string
      add :branch, :string
      add :base_branch, :string
      add :author_login, :string
      add :is_draft, :boolean, default: false
      add :ci_state, :string
      add :check_runs, :map
      add :review_state, :string
      add :review_decision, :string
      add :unresolved_comment_count, :integer, default: 0
      add :has_merge_conflicts, :boolean, default: false
      add :computed_state, :string
      add :pr_created_at, :utc_datetime
      add :pr_updated_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cached_pull_requests, [:user_id, :repo_owner, :repo_name, :number])
    create index(:cached_pull_requests, [:user_id])
  end
end
