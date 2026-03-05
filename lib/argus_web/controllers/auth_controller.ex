defmodule ArgusWeb.AuthController do
  use ArgusWeb, :controller
  plug Ueberauth

  alias Argus.Accounts

  def request(conn, _params) do
    # Ueberauth handles the redirect to the OAuth provider
    conn
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, params) do
    provider = Map.get(params, "provider", "unknown")

    conn
    |> put_flash(:error, "Failed to authenticate with #{provider}: #{inspect(fails)}")
    |> redirect(to: "/login")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => "github"}) do
    attrs = %{
      provider: "github",
      github_id: to_string(auth.uid),
      login: auth.info.nickname,
      name: auth.info.name,
      avatar_url: auth.info.image,
      email: auth.info.email,
      github_token: auth.credentials.token
    }

    handle_oauth_result(conn, Accounts.upsert_user_from_oauth(attrs))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => "gitlab"}) do
    attrs = %{
      provider: "gitlab",
      gitlab_id: to_string(auth.uid),
      login: auth.info.nickname,
      name: auth.info.name,
      avatar_url: auth.info.image,
      email: auth.info.email,
      gitlab_token: auth.credentials.token
    }

    handle_oauth_result(conn, Accounts.upsert_user_from_oauth(attrs))
  end

  def delete(conn, _params) do
    if token = get_session(conn, :user_token) do
      Accounts.delete_user_session_token(token)
    end

    conn
    |> configure_session(drop: true)
    |> redirect(to: "/login")
  end

  defp handle_oauth_result(conn, {:ok, user}) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> put_session(:user_token, token)
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end

  defp handle_oauth_result(conn, {:error, changeset}) do
    conn
    |> put_flash(:error, "Authentication error: #{inspect(changeset.errors)}")
    |> redirect(to: "/login")
  end
end
