defmodule ArgusWeb.Live.Components.PrStateBadge do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.Live.Components.Badge

  @state_config %{
    ready_to_merge: {:success, "hero-check-circle-mini", "Ready to Merge"},
    needs_attention: {:danger, "hero-exclamation-triangle-mini", "Needs Attention"},
    waiting_on_ci: {:warning, "hero-clock-mini", "Waiting on CI"},
    needs_approval: {:info, "hero-chat-bubble-left-ellipsis-mini", "Needs Approval"},
    draft: {:secondary, "hero-pencil-square-mini", "Draft"}
  }

  attr :state, :atom, required: true

  def pr_state_badge(assigns) do
    {variant, icon_name, label} =
      Map.get(@state_config, assigns.state, {:secondary, nil, "Unknown"})

    assigns = assign(assigns, variant: variant, icon_name: icon_name, label: label)

    ~H"""
    <.badge variant={@variant} icon_name={@icon_name}>
      {@label}
    </.badge>
    """
  end
end
