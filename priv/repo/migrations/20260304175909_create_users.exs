defmodule Argus.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :github_id, :string, null: false
      add :login, :string, null: false
      add :name, :string
      add :avatar_url, :string
      add :email, :string
      add :github_token, :binary
      add :is_team_lead, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:github_id])
    create unique_index(:users, [:login])
  end
end
