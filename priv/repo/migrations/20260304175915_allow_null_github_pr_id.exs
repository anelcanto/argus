defmodule Argus.Repo.Migrations.AllowNullGithubPrId do
  use Ecto.Migration

  def change do
    alter table(:cached_pull_requests) do
      modify :github_pr_id, :bigint, null: true
    end
  end
end
