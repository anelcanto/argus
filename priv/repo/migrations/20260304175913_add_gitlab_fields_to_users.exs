defmodule Argus.Repo.Migrations.AddGitlabFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :gitlab_token, :binary
      add :gitlab_username, :string
    end
  end
end
