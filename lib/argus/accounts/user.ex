defmodule Argus.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :github_id, :string
    field :gitlab_id, :string
    field :gitlab_url, :string
    field :provider, :string
    field :login, :string
    field :name, :string
    field :avatar_url, :string
    field :email, :string
    field :github_token, :binary
    field :gitlab_token, :binary
    field :gitlab_username, :string
    field :is_team_lead, :boolean, default: false

    has_many :user_tokens, Argus.Accounts.UserToken
    has_many :cached_pull_requests, Argus.Cache.CachedPullRequest
    has_many :team_lead_memberships, Argus.Accounts.TeamMembership, foreign_key: :lead_user_id
    has_many :team_member_memberships, Argus.Accounts.TeamMembership, foreign_key: :member_user_id

    timestamps(type: :utc_datetime)
  end

  def upsert_changeset(user \\ %__MODULE__{}, attrs) do
    user
    |> cast(attrs, [
      :github_id,
      :gitlab_id,
      :gitlab_url,
      :provider,
      :login,
      :name,
      :avatar_url,
      :email,
      :github_token,
      :gitlab_token,
      :gitlab_username,
      :is_team_lead
    ])
    |> validate_required([:login, :provider])
    |> unique_constraint(:github_id)
    |> unique_constraint(:gitlab_id)
    |> unique_constraint(:login, name: :users_provider_login_index)
  end
end
