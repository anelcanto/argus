defmodule ArgusWeb.Plugs.FetchCurrentUser do
  @moduledoc false
  import Plug.Conn
  alias Argus.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    token = get_session(conn, :user_token)

    user =
      if token do
        Accounts.get_user_by_session_token(token)
      end

    assign(conn, :current_user, user)
  end
end
