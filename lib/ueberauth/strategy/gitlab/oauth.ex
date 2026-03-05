defmodule Ueberauth.Strategy.Gitlab.OAuth do
  @moduledoc """
  OAuth2 client for GitLab. Supports configurable GitLab instance URLs.

  Configure via:

      config :ueberauth, Ueberauth.Strategy.Gitlab.OAuth,
        client_id: System.get_env("GITLAB_CLIENT_ID"),
        client_secret: System.get_env("GITLAB_CLIENT_SECRET"),
        site: "https://gitlab.com"   # or your self-hosted URL
  """
  use OAuth2.Strategy

  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__, [])
    gitlab_url = Keyword.get(config, :site, "https://gitlab.com")

    defaults = [
      strategy: __MODULE__,
      site: gitlab_url,
      authorize_url: "#{gitlab_url}/oauth/authorize",
      token_url: "#{gitlab_url}/oauth/token",
      headers: [{"user-agent", "argus-ueberauth"}]
    ]

    client_opts =
      defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    client_opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client()
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  # OAuth2.Strategy callbacks

  def authorize_url(client, params) do
    alias OAuth2.Strategy.AuthCode
    AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    alias OAuth2.Strategy.AuthCode

    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> AuthCode.get_token(params, headers)
  end
end
