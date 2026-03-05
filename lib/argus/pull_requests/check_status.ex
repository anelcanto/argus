defmodule Argus.PullRequests.CheckStatus do
  @moduledoc false
  defstruct [:name, :status, :conclusion, :url]

  def from_api(%{"name" => name} = run) do
    %__MODULE__{
      name: name,
      status: run["status"] && String.to_atom(run["status"]),
      conclusion: run["conclusion"] && String.to_atom(run["conclusion"]),
      url: run["html_url"]
    }
  end

  def to_serializable(%__MODULE__{} = c) do
    %{
      "name" => c.name,
      "status" => c.status && Atom.to_string(c.status),
      "conclusion" => c.conclusion && Atom.to_string(c.conclusion),
      "url" => c.url
    }
  end
end
