defmodule ArgusWeb.Live.Components.Badge do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]

  attr :variant, :atom, default: :default
  attr :icon_name, :string, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={"inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold #{variant_classes(@variant)}"}>
      <.icon :if={@icon_name} name={@icon_name} class="w-3 h-3 shrink-0" />
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp variant_classes(:default), do: "bg-gray-900 text-white"

  defp variant_classes(:secondary),
    do: "bg-gray-100 text-gray-600 ring-1 ring-inset ring-gray-600/20"

  defp variant_classes(:success),
    do: "bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20"

  defp variant_classes(:warning),
    do: "bg-yellow-50 text-yellow-700 ring-1 ring-inset ring-yellow-600/20"

  defp variant_classes(:danger), do: "bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20"
  defp variant_classes(:info), do: "bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20"

  defp variant_classes(:platform),
    do: "bg-orange-50 text-orange-700 ring-1 ring-inset ring-orange-600/20"

  defp variant_classes(:outline),
    do: "bg-transparent ring-1 ring-inset ring-gray-300 text-gray-600"
end
