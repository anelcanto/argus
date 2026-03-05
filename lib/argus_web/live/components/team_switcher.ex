defmodule ArgusWeb.Live.Components.TeamSwitcher do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]

  attr :current_user, :map, required: true
  attr :team_members, :list, default: []
  attr :viewing_user_id, :any, default: nil

  def team_switcher(assigns) do
    ~H"""
    <div
      :if={@current_user.is_team_lead and length(@team_members) > 0}
      class="flex items-center gap-2"
    >
      <.icon name="hero-users-mini" class="w-4 h-4 text-gray-400 shrink-0" />
      <select
        phx-change="switch_user"
        class="text-sm border border-gray-200 rounded-lg px-2 py-1 focus:ring-1 focus:ring-gray-400 focus:border-gray-400"
      >
        <option value={@current_user.id} selected={is_nil(@viewing_user_id)}>
          My PRs
        </option>
        <option
          :for={member <- @team_members}
          value={member.id}
          selected={@viewing_user_id == member.id}
        >
          {member.login}
        </option>
      </select>
    </div>
    """
  end
end
