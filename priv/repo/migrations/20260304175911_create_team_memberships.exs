defmodule Argus.Repo.Migrations.CreateTeamMemberships do
  use Ecto.Migration

  def change do
    create table(:team_memberships) do
      add :lead_user_id, references(:users, on_delete: :delete_all), null: false
      add :member_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:team_memberships, [:lead_user_id, :member_user_id])
    create index(:team_memberships, [:lead_user_id])
    create index(:team_memberships, [:member_user_id])
  end
end
