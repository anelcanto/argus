defmodule ArgusWeb.Live.Components.CountdownTimer do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]

  attr :seconds, :integer, required: true
  attr :max_seconds, :integer, default: 300

  def countdown_timer(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <span class="text-xs text-gray-400 tabular-nums">
        <.icon
          name="hero-arrow-path-mini"
          class={"w-3 h-3 mr-0.5 inline-block " <> if(@seconds <= 10, do: "animate-spin text-orange-500", else: "text-gray-400")}
        />Refreshing in {format_time(@seconds)}
      </span>
      <div class="hidden sm:block w-16 h-1 bg-gray-100 rounded-full overflow-hidden">
        <div
          class="h-full bg-gray-400 rounded-full transition-all duration-1000 ease-linear"
          style={"width: #{progress_pct(@seconds, @max_seconds)}%"}
        />
      </div>
    </div>
    """
  end

  defp format_time(seconds) when seconds >= 60 do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  defp format_time(seconds),
    do: "0:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"

  defp progress_pct(seconds, max_seconds) when max_seconds > 0,
    do: min(100, round(seconds / max_seconds * 100))

  defp progress_pct(_, _), do: 0
end
