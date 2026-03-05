defmodule Argus.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @rand_size 32
  @session_validity_in_days 60

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string

    belongs_to :user, Argus.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %__MODULE__{token: token, context: "session", user_id: user.id}}
  end

  def verify_session_token_query(token) do
    query =
      from t in __MODULE__,
        join: u in assoc(t, :user),
        where: t.token == ^token and t.context == "session",
        where: t.inserted_at > ago(@session_validity_in_days, "day"),
        select: u

    {:ok, query}
  end
end
