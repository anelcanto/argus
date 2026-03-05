defmodule ArgusWeb.Router do
  use ArgusWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ArgusWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    if Mix.env() == :dev, do: plug(ArgusWeb.Plugs.DevAuthBypass)
    plug ArgusWeb.Plugs.FetchCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug ArgusWeb.Plugs.RequireAuth
  end

  pipeline :webhook do
    plug :accepts, ["json"]
    plug ArgusWeb.Plugs.WebhookSignature
  end

  # Public routes
  scope "/", ArgusWeb do
    pipe_through :browser
    live "/login", LoginLive, :index
  end

  # Auth routes (public)
  scope "/auth", ArgusWeb do
    pipe_through :browser
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  # Health check (public)
  scope "/", ArgusWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  # Webhook (no CSRF, signature-verified)
  scope "/webhooks", ArgusWeb do
    pipe_through :webhook
    post "/github", WebhookController, :github
  end

  # Protected routes
  scope "/", ArgusWeb do
    pipe_through [:browser, :authenticated]

    live "/", DashboardLive, :index
    live "/dashboard", DashboardLive, :index
    live "/settings", SettingsLive, :index
  end
end
