defmodule ArgusWeb.HealthController do
  use ArgusWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", time: DateTime.utc_now()})
  end
end
