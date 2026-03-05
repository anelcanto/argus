defmodule ArgusWeb.Live.Components.SkeletonCard do
  @moduledoc false
  use Phoenix.Component

  attr :count, :integer, default: 4

  def skeleton_cards(assigns) do
    ~H"""
    <div
      :for={_ <- 1..@count}
      class="flex flex-col gap-2.5 rounded-xl border border-gray-200 p-4 bg-white shadow-sm animate-pulse"
    >
      <!-- Badge row -->
      <div class="flex items-center gap-1.5">
        <div class="rounded-full bg-gray-200 h-5 w-24"></div>
        <div class="rounded-full bg-gray-200 h-5 w-16"></div>
      </div>
      <!-- Repo/number row -->
      <div class="rounded bg-gray-200 h-3 w-32"></div>
      <!-- Title lines -->
      <div class="rounded bg-gray-200 h-4 w-full"></div>
      <div class="rounded bg-gray-200 h-4 w-3/4"></div>
      <!-- Meta row -->
      <div class="rounded bg-gray-200 h-3 w-48"></div>
      <!-- CI row -->
      <div class="rounded bg-gray-200 h-3 w-20"></div>
    </div>
    """
  end
end
