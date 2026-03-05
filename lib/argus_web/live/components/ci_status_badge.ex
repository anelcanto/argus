defmodule ArgusWeb.Live.Components.CiStatusBadge do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]

  attr :ci_state, :atom, required: true
  attr :checks, :list, default: []
  attr :pr_number, :integer, required: true
  attr :expanded, :boolean, default: false

  def ci_status_badge(assigns) do
    ~H"""
    <button
      phx-click="toggle_checks"
      phx-value-pr={@pr_number}
      class="flex items-center gap-1.5 text-sm transition-opacity hover:opacity-80 phx-click-loading:opacity-50"
    >
      <span :if={@ci_state == :passing} class="flex items-center gap-1 text-green-600">
        <.icon name="hero-check-circle-mini" class="w-4 h-4 shrink-0" /> CI Passing
      </span>
      <span :if={@ci_state == :failing} class="flex items-center gap-1 text-red-600">
        <.icon name="hero-x-circle-mini" class="w-4 h-4 shrink-0" /> CI Failing
      </span>
      <span :if={@ci_state == :pending} class="flex items-center gap-1 text-yellow-600">
        <.icon name="hero-clock-mini" class="w-4 h-4 shrink-0" /> CI Pending
      </span>
      <span
        :if={@ci_state not in [:passing, :failing, :pending]}
        class="flex items-center gap-1 text-gray-400"
      >
        <.icon name="hero-minus-circle-mini" class="w-4 h-4 shrink-0" /> No CI
      </span>
      <span :if={length(@checks) > 0} class="text-gray-400 text-xs tabular-nums">
        ({length(@checks)})
      </span>
      <.icon
        :if={length(@checks) > 0}
        name={if @expanded, do: "hero-chevron-up-mini", else: "hero-chevron-down-mini"}
        class="w-3 h-3 text-gray-400"
      />
    </button>
    """
  end
end
