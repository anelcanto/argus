defmodule ArgusWeb.Live.Components.EmptyState do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]

  attr :message, :string, default: "No open PRs"
  attr :subtext, :string, default: "You have no open pull requests right now."

  def empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-16 text-center">
      <div class="rounded-full bg-gray-100 p-4 mb-4">
        <.icon name="hero-check-badge" class="w-10 h-10 text-gray-400" />
      </div>
      <h3 class="text-lg font-semibold text-gray-700">{@message}</h3>
      <p class="text-sm text-gray-500 mt-1 max-w-xs">{@subtext}</p>
    </div>
    """
  end
end
