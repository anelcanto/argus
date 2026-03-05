defmodule Argus.PullRequests.PrState do
  @moduledoc false
  @doc """
  Classify a PR into a state atom.
  Priority: draft > needs_attention > waiting_on_ci > needs_approval > ready_to_merge
  """
  def classify(%{draft: true}), do: :draft

  def classify(pr) do
    cond do
      has_attention_items?(pr) -> :needs_attention
      pr.ci_state == :pending -> :waiting_on_ci
      pr.review_decision == "CHANGES_REQUESTED" -> :needs_approval
      pr.review_decision in ["APPROVED", nil] and pr.ci_state == :passing -> :ready_to_merge
      true -> :needs_approval
    end
  end

  @doc """
  Returns a list of human-readable reasons why a PR needs attention.
  """
  def attention_items(pr) do
    []
    |> maybe_add(pr.ci_state == :failing, "CI failing")
    |> maybe_add(pr.has_merge_conflicts, "Merge conflicts")
    |> maybe_add(
      (pr.unresolved_comments || 0) > 0,
      "#{pr.unresolved_comments} unresolved comment(s)"
    )
    |> maybe_add(pr.review_decision == "CHANGES_REQUESTED", "Changes requested")
  end

  defp has_attention_items?(pr) do
    pr.ci_state == :failing or
      pr.has_merge_conflicts or
      (pr.unresolved_comments || 0) > 0 or
      pr.review_decision == "CHANGES_REQUESTED"
  end

  defp maybe_add(list, false, _), do: list
  defp maybe_add(list, true, item), do: list ++ [item]
end
