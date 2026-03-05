defmodule ArgusWeb.Plugs.DevAuthBypass do
  @moduledoc """
  Dev-only plug that auto-authenticates using the local `gh auth token`.
  Bypasses GitHub OAuth entirely. Never enabled in prod.
  """
  import Plug.Conn
  alias Argus.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :user_token) do
      maybe_update_credentials(conn)
    else
      token = String.trim(System.cmd("gh", ["auth", "token"]) |> elem(0))
      seed_and_login(conn, token)
    end
  end

  defp maybe_update_credentials(conn) do
    if get_session(conn, :creds_checked) do
      conn
    else
      user = Accounts.get_user_by_session_token(get_session(conn, :user_token))

      if user do
        github_token = String.trim(System.cmd("gh", ["auth", "token"]) |> elem(0))
        Accounts.update_github_token(user, github_token)
        maybe_set_gitlab_credentials(user)
        put_session(conn, :creds_checked, true)
      else
        conn
      end
    end
  end

  defp seed_and_login(conn, token) do
    gh_user = fetch_gh_user()

    attrs = %{
      provider: "github",
      github_id: to_string(gh_user["id"] || "0"),
      login: gh_user["login"] || "dev-user",
      name: gh_user["name"] || "Dev User",
      avatar_url: gh_user["avatar_url"],
      email: gh_user["email"],
      github_token: token
    }

    case Accounts.upsert_user_from_oauth(attrs) do
      {:ok, user} ->
        user = maybe_set_gitlab_credentials(user)
        session_token = Accounts.generate_user_session_token(user)
        put_session(conn, :user_token, session_token)

      _ ->
        conn
    end
  end

  defp maybe_set_gitlab_credentials(user) do
    gitlab_token = get_gitlab_token()
    gitlab_username = get_gitlab_username()

    if gitlab_token do
      case Accounts.update_gitlab_credentials(user, gitlab_token, gitlab_username) do
        {:ok, updated_user} -> updated_user
        _ -> user
      end
    else
      user
    end
  end

  defp fetch_gh_user do
    case System.cmd("gh", ["api", "user"], stderr_to_stdout: true) do
      {json, 0} -> Jason.decode!(json)
      _ -> %{}
    end
  end

  defp get_gitlab_token do
    gitlab_url = Application.get_env(:argus, :gitlab_url, "https://gitlab.com")
    host = URI.parse(gitlab_url).host

    case System.cmd("glab", ["config", "get", "token", "--host", host], stderr_to_stdout: true) do
      {token, 0} -> String.trim(token)
      _ -> System.get_env("GITLAB_TOKEN")
    end
  end

  defp get_gitlab_username do
    System.get_env("GITLAB_USERNAME", "")
  end
end
