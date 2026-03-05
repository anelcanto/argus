defmodule Argus.Accounts.TeamMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_memberships" do
    belongs_to :lead_user, Argus.Accounts.User
    belongs_to :member_user, Argus.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(membership \\ %__MODULE__{}, attrs) do
    membership
    |> cast(attrs, [:lead_user_id, :member_user_id])
    |> validate_required([:lead_user_id, :member_user_id])
    |> unique_constraint([:lead_user_id, :member_user_id])
  end
end
