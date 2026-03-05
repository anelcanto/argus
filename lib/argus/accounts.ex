defmodule Argus.Accounts do
  @moduledoc false
  import Ecto.Query
  alias Argus.Accounts.{TeamMembership, User, UserToken}
  alias Argus.Repo

  defp token_secret,
    do: Application.get_env(:argus, :token_secret, "default_secret_change_in_prod")

  # --- User upsert ---

  def upsert_user_from_oauth(%{provider: "github"} = attrs) do
    encrypted_token = encrypt_token(attrs[:github_token])

    params = %{
      provider: "github",
      github_id: attrs.github_id,
      login: attrs.login,
      name: attrs[:name],
      avatar_url: attrs[:avatar_url],
      email: attrs[:email],
      github_token: encrypted_token
    }

    upsert_by_field(:github_id, params.github_id, params)
  end

  def upsert_user_from_oauth(%{provider: "gitlab"} = attrs) do
    encrypted_token = encrypt_gitlab_token(attrs[:gitlab_token])

    params = %{
      provider: "gitlab",
      gitlab_id: attrs.gitlab_id,
      login: attrs.login,
      name: attrs[:name],
      avatar_url: attrs[:avatar_url],
      email: attrs[:email],
      gitlab_token: encrypted_token,
      gitlab_username: attrs[:login]
    }

    upsert_by_field(:gitlab_id, params.gitlab_id, params)
  end

  # Backward compat: delegate to generic function
  def upsert_user_from_github(%{} = attrs) do
    upsert_user_from_oauth(Map.put(attrs, :provider, "github"))
  end

  defp upsert_by_field(field, value, params) do
    case Repo.get_by(User, [{field, value}]) do
      nil ->
        %User{}
        |> User.upsert_changeset(params)
        |> Repo.insert()

      existing ->
        existing
        |> User.upsert_changeset(params)
        |> Repo.update()
    end
  end

  def update_github_token(user, token) do
    encrypted = encrypt_token(token)

    user
    |> User.upsert_changeset(%{github_token: encrypted})
    |> Repo.update()
  end

  def update_gitlab_url(user, gitlab_url) do
    user
    |> User.upsert_changeset(%{gitlab_url: gitlab_url})
    |> Repo.update()
  end

  def update_gitlab_credentials(user, gitlab_token, gitlab_username) do
    encrypted = encrypt_gitlab_token(gitlab_token)

    user
    |> User.upsert_changeset(%{gitlab_token: encrypted, gitlab_username: gitlab_username})
    |> Repo.update()
  end

  def get_decrypted_gitlab_token(%User{gitlab_token: nil}), do: nil

  def get_decrypted_gitlab_token(%User{gitlab_token: encrypted}) do
    decrypt_gitlab_token(encrypted)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_login(login), do: Repo.get_by(User, login: login)

  def get_decrypted_token(%User{github_token: nil}), do: nil

  def get_decrypted_token(%User{github_token: encrypted}) do
    decrypt_token(encrypted)
  end

  # --- Session tokens ---

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from t in UserToken, where: t.token == ^token and t.context == "session")
    :ok
  end

  # --- Team memberships ---

  def get_team_members(lead_user_id) do
    from(m in TeamMembership,
      join: u in assoc(m, :member_user),
      where: m.lead_user_id == ^lead_user_id,
      select: u
    )
    |> Repo.all()
  end

  def add_team_member(lead_user_id, member_user_id) do
    %TeamMembership{}
    |> TeamMembership.changeset(%{lead_user_id: lead_user_id, member_user_id: member_user_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  # --- Token encryption ---

  defp encrypt_token(nil), do: nil

  defp encrypt_token(token) when is_binary(token) do
    Plug.Crypto.encrypt(token_secret(), "github_token", token)
  end

  defp decrypt_token(nil), do: nil

  defp decrypt_token(encrypted) when is_binary(encrypted) do
    case Plug.Crypto.decrypt(token_secret(), "github_token", encrypted, max_age: :infinity) do
      {:ok, token} -> token
      _ -> nil
    end
  end

  defp encrypt_gitlab_token(nil), do: nil

  defp encrypt_gitlab_token(token) when is_binary(token) do
    Plug.Crypto.encrypt(token_secret(), "gitlab_token", token)
  end

  defp decrypt_gitlab_token(nil), do: nil

  defp decrypt_gitlab_token(encrypted) when is_binary(encrypted) do
    case Plug.Crypto.decrypt(token_secret(), "gitlab_token", encrypted, max_age: :infinity) do
      {:ok, token} -> token
      _ -> nil
    end
  end
end
