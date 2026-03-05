defmodule ArgusWeb.Plugs.WebhookSignature do
  @moduledoc false
  import Plug.Conn

  defp secret_key, do: Application.get_env(:argus, :github_webhook_secret, "")

  def init(opts), do: opts

  def call(conn, _opts) do
    with [signature | _] <- get_req_header(conn, "x-hub-signature-256"),
         {:ok, body, conn} <- read_body(conn),
         true <- valid_signature?(signature, body) do
      assign(conn, :raw_body, body)
    else
      _ ->
        conn
        |> send_resp(401, "Invalid webhook signature")
        |> halt()
    end
  end

  defp valid_signature?("sha256=" <> sig, body) do
    expected = :crypto.mac(:hmac, :sha256, secret_key(), body) |> Base.encode16(case: :lower)
    Plug.Crypto.secure_compare(sig, expected)
  end

  defp valid_signature?(_, _), do: false
end
