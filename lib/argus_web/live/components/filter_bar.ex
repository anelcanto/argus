defmodule ArgusWeb.Live.Components.FilterBar do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]

  attr :filters, :map, required: true
  attr :total, :integer, default: 0
  attr :filtered, :integer, default: 0

  def filter_bar(assigns) do
    ~H"""
    <div class="bg-white border-b border-gray-100 shadow-sm">
      <div class="max-w-screen-2xl mx-auto px-4 sm:px-6 py-2 space-y-2">
        <!-- Search row -->
        <div class="flex items-center gap-3">
          <div class="relative flex-1 sm:max-w-xs">
            <.icon
              name="hero-magnifying-glass-mini"
              class="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none"
            />
            <input
              type="text"
              placeholder="Search PRs…"
              value={@filters[:search]}
              phx-keyup="filter_search"
              phx-debounce="300"
              class="w-full rounded-full border-gray-200 text-sm py-1.5 pl-8 pr-3 focus:ring-1 focus:ring-gray-400 focus:border-gray-400"
            />
          </div>
          <span class="ml-auto text-xs text-gray-400 tabular-nums whitespace-nowrap">
            {@filtered} / {@total}
          </span>
        </div>
        
    <!-- Filter pills row — scrolls horizontally on mobile -->
        <div class="flex items-center gap-1.5 overflow-x-auto pb-1 -mx-4 px-4 sm:mx-0 sm:px-0">
          <!-- State filters -->
          <button
            :for={
              state <- [
                :all,
                :needs_attention,
                :waiting_on_ci,
                :needs_approval,
                :ready_to_merge,
                :draft
              ]
            }
            phx-click="filter_state"
            phx-value-state={state}
            class={
              pill_class(@filters[:state] == state or (state == :all and is_nil(@filters[:state])))
            }
          >
            {state_label(state)}
          </button>
          
    <!-- Divider -->
          <div class="shrink-0 w-px h-4 bg-gray-200 mx-1" />
          
    <!-- Platform filters -->
          <button
            :for={platform <- [:all, :github, :gitlab]}
            phx-click="filter_platform"
            phx-value-platform={platform}
            class={
              pill_class(
                @filters[:platform] == platform or
                  (platform == :all and is_nil(@filters[:platform]))
              )
            }
          >
            {platform_label(platform)}
          </button>
          
    <!-- Divider -->
          <div class="shrink-0 w-px h-4 bg-gray-200 mx-1" />
          
    <!-- Toggles -->
          <label class="shrink-0 flex items-center gap-1.5 text-xs text-gray-600 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={@filters[:hide_drafts]}
              phx-click="toggle_hide_drafts"
              class="rounded border-gray-300 text-gray-900 focus:ring-gray-400 w-3.5 h-3.5"
            /> Only Drafts
          </label>

          <label class="shrink-0 flex items-center gap-1.5 text-xs text-gray-600 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={@filters[:hide_dependabot]}
              phx-click="toggle_hide_dependabot"
              class="rounded border-gray-300 text-gray-900 focus:ring-gray-400 w-3.5 h-3.5"
            /> Only Bots
          </label>

          <label class="shrink-0 flex items-center gap-1.5 text-xs text-gray-600 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={@filters[:group_by_repo]}
              phx-click="toggle_group_by_repo"
              class="rounded border-gray-300 text-gray-900 focus:ring-gray-400 w-3.5 h-3.5"
            /> Group by Repo
          </label>

          <button
            :if={filters_active?(@filters)}
            phx-click="clear_filters"
            class="shrink-0 ml-1 flex items-center gap-1 text-xs text-gray-400 hover:text-gray-700 transition-colors"
          >
            <.icon name="hero-x-mark-mini" class="w-3 h-3" /> Clear
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp filters_active?(%{
         state: nil,
         search: "",
         hide_drafts: false,
         hide_dependabot: false,
         platform: nil,
         group_by_repo: false
       }),
       do: false

  defp filters_active?(_), do: true

  defp pill_class(true),
    do:
      "shrink-0 px-2.5 py-1 rounded-full text-xs font-medium transition-colors phx-click-loading:opacity-70 bg-gray-900 text-white"

  defp pill_class(false),
    do:
      "shrink-0 px-2.5 py-1 rounded-full text-xs font-medium transition-colors phx-click-loading:opacity-70 bg-gray-100 text-gray-600 hover:bg-gray-200"

  defp state_label(:all), do: "All"
  defp state_label(:needs_attention), do: "Attention"
  defp state_label(:waiting_on_ci), do: "CI"
  defp state_label(:needs_approval), do: "Review"
  defp state_label(:ready_to_merge), do: "Ready"
  defp state_label(:draft), do: "Draft"

  defp state_label(state),
    do: state |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp platform_label(:all), do: "All"
  defp platform_label(:github), do: "GitHub"
  defp platform_label(:gitlab), do: "GitLab"
end
