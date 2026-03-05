defmodule Argus.Repo.Migrations.AddSourceToCachedPullRequests do
  use Ecto.Migration

  def change do
    alter table(:cached_pull_requests) do
      add :source, :string, default: "github", null: false
      add :project_id, :string
    end

    # Drop old unique index (includes number, repo_owner, repo_name, user_id)
    drop_if_exists unique_index(:cached_pull_requests, [
                     :user_id,
                     :repo_owner,
                     :repo_name,
                     :number
                   ])

    # New index includes source so GitHub PR #1 and GitLab MR #1 can coexist
    create unique_index(:cached_pull_requests, [
             :user_id,
             :source,
             :repo_owner,
             :repo_name,
             :number
           ])
  end
end
