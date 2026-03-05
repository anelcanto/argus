defmodule Argus.Repo.Migrations.GenericizeUsersForMultiProvider do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :github_id, :string, null: true
      add :gitlab_id, :string
      add :gitlab_url, :string
      add :provider, :string
    end

    execute "UPDATE users SET provider = 'github' WHERE provider IS NULL"

    create unique_index(:users, [:gitlab_id], where: "gitlab_id IS NOT NULL")
    drop_if_exists unique_index(:users, [:login])
    create unique_index(:users, [:provider, :login])
  end

  def down do
    drop_if_exists unique_index(:users, [:provider, :login])
    drop_if_exists unique_index(:users, [:gitlab_id])
    create unique_index(:users, [:login])

    alter table(:users) do
      modify :github_id, :string, null: false
      remove :gitlab_id
      remove :gitlab_url
      remove :provider
    end
  end
end
