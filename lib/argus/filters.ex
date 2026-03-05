defmodule Argus.Filters do
  @moduledoc false
  @doc "Filter PRs by computed state"
  def by_state(prs, nil), do: prs
  def by_state(prs, :all), do: prs

  def by_state(prs, state) when is_atom(state) do
    Enum.filter(prs, &(&1.computed_state == state))
  end

  @doc "Filter PRs by CI status"
  def by_ci(prs, nil), do: prs
  def by_ci(prs, :all), do: prs

  def by_ci(prs, ci_state) when is_atom(ci_state) do
    Enum.filter(prs, &(&1.ci_state == ci_state))
  end

  @doc "Filter PRs by text search (title or repo)"
  def by_text(prs, nil), do: prs
  def by_text(prs, ""), do: prs

  def by_text(prs, query) do
    q = String.downcase(query)

    Enum.filter(prs, fn pr ->
      String.contains?(String.downcase(pr.title || ""), q) or
        String.contains?(String.downcase(pr.repo_name || ""), q)
    end)
  end

  @doc "Show only draft PRs"
  def hide_drafts(prs, true), do: Enum.filter(prs, & &1.draft)
  def hide_drafts(prs, _), do: prs

  @doc "Show only bot PRs"
  def hide_dependabot(prs, true) do
    Enum.filter(prs, fn pr ->
      String.starts_with?(pr.author || "", "dependabot") or
        String.starts_with?(pr.author || "", "renovate")
    end)
  end

  def hide_dependabot(prs, _), do: prs

  @doc "Filter PRs by platform source"
  def by_platform(prs, nil), do: prs
  def by_platform(prs, :all), do: prs

  def by_platform(prs, platform) when is_atom(platform) do
    Enum.filter(prs, &(&1.source == platform))
  end

  @doc "Apply all filters from a filter map"
  def apply_filters(prs, filters) do
    prs
    |> by_state(filters[:state])
    |> by_ci(filters[:ci_state])
    |> by_text(filters[:search])
    |> hide_drafts(filters[:hide_drafts])
    |> hide_dependabot(filters[:hide_dependabot])
    |> by_platform(filters[:platform])
  end
end
