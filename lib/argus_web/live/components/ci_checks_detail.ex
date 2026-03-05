defmodule ArgusWeb.Live.Components.CiChecksDetail do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]

  attr :checks, :list, required: true

  def ci_checks_detail(assigns) do
    ~H"""
    <div
      :if={length(@checks) > 0}
      class="mt-2 bg-gray-50 rounded-lg p-3 space-y-1 animate-expand-down"
    >
      <div :for={check <- @checks} class="flex items-center gap-2 text-xs text-gray-600">
        <.icon
          :if={check.conclusion == :success}
          name="hero-check-circle-mini"
          class="w-3.5 h-3.5 text-green-500 shrink-0"
        />
        <.icon
          :if={check.conclusion == :failure}
          name="hero-x-circle-mini"
          class="w-3.5 h-3.5 text-red-500 shrink-0"
        />
        <.icon
          :if={check.conclusion not in [:success, :failure]}
          name="hero-clock-mini"
          class="w-3.5 h-3.5 text-yellow-500 shrink-0"
        />
        <a :if={check.url} href={check.url} target="_blank" class="hover:underline truncate">
          {check.name}
        </a>
        <span :if={!check.url} class="truncate">{check.name}</span>
      </div>
    </div>
    """
  end
end
