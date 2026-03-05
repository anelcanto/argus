defmodule Argus.PullRequests.ReviewThread do
  @moduledoc false
  defstruct [:resolved, :author, :body]

  def from_api(%{"isResolved" => resolved} = thread) do
    first_comment = get_in(thread, ["comments", "nodes"]) |> List.first() || %{}

    %__MODULE__{
      resolved: resolved,
      author: get_in(first_comment, ["author", "login"]),
      body: first_comment["body"]
    }
  end
end
