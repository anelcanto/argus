defmodule Ueberauth.Strategy.Gitlab do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with GitLab.

  Supports self-hosted GitLab instances via the `GITLAB_URL` environment
  variable (defaults to `https://gitlab.com`).

      config :ueberauth, Ueberauth,
        providers: [
          gitlab: {Ueberauth.Strategy.Gitlab, [default_scope: "read_user api read_api"]}
        ]

      config :ueberauth, Ueberauth.Strategy.Gitlab.OAuth,
        client_id: System.get_env("GITLAB_CLIENT_ID"),
        client_secret: System.get_env("GITLAB_CLIENT_SECRET"),
        site: "https://gitlab.com"
  """
  use Ueberauth.Strategy,
    uid_field: :id,
    default_scope: "read_user",
    send_redirect_uri: true,
    oauth2_module: Ueberauth.Strategy.Gitlab.OAuth

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Info
  alias Ueberauth.Strategy.Gitlab.OAuth, as: GitlabOAuth

  def handle_request!(conn) do
    opts =
      []
      |> with_scopes(conn)
      |> with_state_param(conn)
      |> with_redirect_uri(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, module.authorize_url!(opts))
  end

  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = module.get_token!(code: code)

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      fetch_user(conn, token)
    end
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  def handle_cleanup!(conn) do
    conn
    |> put_private(:gitlab_user, nil)
    |> put_private(:gitlab_token, nil)
  end

  def uid(conn) do
    conn.private.gitlab_user["id"]
  end

  def credentials(conn) do
    token = conn.private.gitlab_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: []
    }
  end

  def info(conn) do
    user = conn.private.gitlab_user

    %Info{
      name: user["name"],
      nickname: user["username"],
      email: user["email"],
      image: user["avatar_url"],
      urls: %{web_url: user["web_url"]}
    }
  end

  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.gitlab_token,
        user: conn.private.gitlab_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :gitlab_token, token)

    case GitlabOAuth.get(token, "/api/v4/user") do
      {:ok, %OAuth2.Response{status_code: 401}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status, body: user}} when status in 200..399 ->
        put_private(conn, :gitlab_user, user)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      _ ->
        set_errors!(conn, [error("OAuth2", "unknown error")])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_scopes(opts, conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    Keyword.put(opts, :scope, scopes)
  end

  defp with_redirect_uri(opts, conn) do
    if option(conn, :send_redirect_uri) do
      Keyword.put(opts, :redirect_uri, callback_url(conn))
    else
      opts
    end
  end
end
