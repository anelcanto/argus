defmodule ArgusWeb.DashboardLive do
  use ArgusWeb, :live_view

  import ArgusWeb.Live.Components.PrCard
  import ArgusWeb.Live.Components.FilterBar
  import ArgusWeb.Live.Components.CountdownTimer
  import ArgusWeb.Live.Components.TeamSwitcher
  import ArgusWeb.Live.Components.EmptyState
  import ArgusWeb.Live.Components.Badge
  import ArgusWeb.Live.Components.SkeletonCard

  alias Argus.{Accounts, Filters}
  alias Argus.Cache.PrCache
  alias Argus.Sync.Poller

  @refresh_interval 300
  @tick_interval 1000
  @default_filters %{
    state: nil,
    search: "",
    hide_drafts: false,
    hide_dependabot: false,
    platform: nil,
    group_by_repo: false
  }

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    if is_nil(current_user) do
      {:ok, redirect(socket, to: "/login")}
    else
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Argus.PubSub, "pr_updates:#{current_user.id}")
        Process.send_after(self(), :tick, @tick_interval)
      end

      team_members =
        if current_user.is_team_lead do
          Accounts.get_team_members(current_user.id)
        else
          []
        end

      cached_prs = PrCache.get_cached_prs(current_user.id)

      socket =
        socket
        |> assign(:current_user, current_user)
        |> assign(:team_members, team_members)
        |> assign(:viewing_user_id, nil)
        |> assign(:prs, cached_prs)
        |> assign(:filters, @default_filters)
        |> assign(:expanded_checks, MapSet.new())
        |> assign(:pinned_prs, MapSet.new())
        |> assign(:countdown, @refresh_interval)
        |> assign(:stale, PrCache.stale?(current_user.id))

      if connected?(socket) and needs_refresh?(current_user) do
        Poller.refresh_user(current_user.id)
      end

      {:ok, socket}
    end
  end

  @impl true
  def handle_info({:prs_updated, prs}, socket) do
    {:noreply,
     socket
     |> assign(:prs, prs)
     |> assign(:stale, false)
     |> assign(:countdown, @refresh_interval)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @tick_interval)
    new_countdown = max(0, socket.assigns.countdown - 1)
    {:noreply, assign(socket, :countdown, new_countdown)}
  end

  @impl true
  def handle_event("restore_config", params, socket) do
    to_atom = fn
      nil -> nil
      "" -> nil
      s -> String.to_existing_atom(s)
    end

    filters = %{
      state: to_atom.(params["state"]),
      search: params["search"] || "",
      hide_drafts: params["hide_drafts"] || false,
      hide_dependabot: params["hide_dependabot"] || false,
      platform: to_atom.(params["platform"]),
      group_by_repo: params["group_by_repo"] || false
    }

    {:noreply, assign(socket, :filters, filters)}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(:filters, @default_filters) |> save_filters()}
  end

  def handle_event("filter_state", %{"state" => state}, socket) do
    state_atom = if state == "all", do: nil, else: String.to_existing_atom(state)
    {:noreply, socket |> update(:filters, &Map.put(&1, :state, state_atom)) |> save_filters()}
  end

  def handle_event("filter_search", %{"value" => query}, socket) do
    {:noreply, socket |> update(:filters, &Map.put(&1, :search, query)) |> save_filters()}
  end

  def handle_event("toggle_hide_drafts", _params, socket) do
    {:noreply,
     socket
     |> update(:filters, fn f -> Map.update(f, :hide_drafts, true, &(!&1)) end)
     |> save_filters()}
  end

  def handle_event("toggle_hide_dependabot", _params, socket) do
    {:noreply,
     socket
     |> update(:filters, fn f -> Map.update(f, :hide_dependabot, true, &(!&1)) end)
     |> save_filters()}
  end

  def handle_event("toggle_group_by_repo", _params, socket) do
    {:noreply,
     socket
     |> update(:filters, fn f -> Map.update(f, :group_by_repo, true, &(!&1)) end)
     |> save_filters()}
  end

  def handle_event("filter_platform", %{"platform" => platform}, socket) do
    platform_atom = if platform == "all", do: nil, else: String.to_existing_atom(platform)

    {:noreply,
     socket |> update(:filters, &Map.put(&1, :platform, platform_atom)) |> save_filters()}
  end

  def handle_event("toggle_checks", %{"pr" => pr_number_str}, socket) do
    pr_number = String.to_integer(pr_number_str)
    expanded = socket.assigns.expanded_checks

    new_expanded =
      if MapSet.member?(expanded, pr_number) do
        MapSet.delete(expanded, pr_number)
      else
        MapSet.put(expanded, pr_number)
      end

    {:noreply, assign(socket, :expanded_checks, new_expanded)}
  end

  def handle_event("toggle_pin", %{"pr" => pr_id_str}, socket) do
    pr_id = String.to_integer(pr_id_str)
    pins = socket.assigns.pinned_prs

    new_pins =
      if MapSet.member?(pins, pr_id) do
        MapSet.delete(pins, pr_id)
      else
        MapSet.put(pins, pr_id)
      end

    {:noreply, assign(socket, :pinned_prs, new_pins)}
  end

  def handle_event("switch_user", %{"value" => user_id_str}, socket) do
    current_user = socket.assigns.current_user

    {viewing_user_id, target_user_id} =
      case Integer.parse(user_id_str) do
        {id, ""} when id == current_user.id -> {nil, current_user.id}
        {id, ""} -> {id, id}
        _ -> {nil, current_user.id}
      end

    cached_prs = PrCache.get_cached_prs(target_user_id)

    if connected?(socket) do
      Phoenix.PubSub.unsubscribe(
        Argus.PubSub,
        "pr_updates:#{socket.assigns.viewing_user_id || current_user.id}"
      )

      Phoenix.PubSub.subscribe(Argus.PubSub, "pr_updates:#{target_user_id}")
    end

    {:noreply,
     socket
     |> assign(:viewing_user_id, viewing_user_id)
     |> assign(:prs, cached_prs)}
  end

  @impl true
  def render(assigns) do
    filtered_prs = Filters.apply_filters(assigns.prs, assigns.filters)

    sorted_prs =
      filtered_prs
      |> Enum.sort_by(fn pr ->
        pinned = if MapSet.member?(assigns.pinned_prs, pr.id), do: 0, else: 1
        {pinned, state_sort_key(pr.computed_state)}
      end)

    grouped_prs =
      if assigns.filters[:group_by_repo] do
        sorted_prs
        |> Enum.group_by(fn pr -> "#{pr.repo_owner}/#{pr.repo_name}" end)
        |> Enum.sort_by(fn {repo, _} -> repo end)
      else
        nil
      end

    github_count = Enum.count(assigns.prs, &(&1.source == :github))
    gitlab_count = Enum.count(assigns.prs, &(&1.source == :gitlab))

    assigns = assign(assigns, :filtered_prs, sorted_prs)
    assigns = assign(assigns, :filtered_count, length(sorted_prs))
    assigns = assign(assigns, :total_count, length(assigns.prs))
    assigns = assign(assigns, :github_count, github_count)
    assigns = assign(assigns, :gitlab_count, gitlab_count)
    assigns = assign(assigns, :grouped_prs, grouped_prs)

    ~H"""
    <div
      class="min-h-screen bg-gray-50"
      id="dashboard"
      phx-hook="ConfigStorage"
      data-email={@current_user.login}
    >
      <!-- Sticky header + filter combined -->
      <div class="sticky top-0 z-20">
        <!-- Header -->
        <header class="bg-white border-b border-gray-100 px-4 sm:px-6 py-3">
          <div class="max-w-screen-2xl mx-auto flex items-center justify-between gap-3 flex-wrap">
            <!-- Brand -->
            <div class="flex items-center gap-2.5">
              <h1 class="text-base font-bold text-gray-900 tracking-tight">Argus</h1>
              <span class="text-xs text-gray-400 hidden sm:inline">PR Monitor</span>
              <.badge :if={@stale} variant={:warning} icon_name="hero-clock-mini">Cached</.badge>
            </div>
            <!-- Right actions -->
            <div class="flex items-center gap-3">
              <.team_switcher
                current_user={@current_user}
                team_members={@team_members}
                viewing_user_id={@viewing_user_id}
              />
              <.countdown_timer seconds={@countdown} max_seconds={300} />
              <div class="flex items-center gap-2">
                <img
                  :if={@current_user.avatar_url}
                  src={@current_user.avatar_url}
                  class="w-6 h-6 rounded-full ring-1 ring-gray-200"
                />
                <span class="text-sm text-gray-700 font-medium hidden sm:inline">
                  {@current_user.login}
                </span>
              </div>
              <a
                href="/settings"
                class="text-xs text-gray-400 hover:text-gray-600 transition-colors"
                title="Settings"
              >
                <.icon name="hero-cog-6-tooth-mini" class="w-4 h-4" />
              </a>
              <a
                href="/auth/logout"
                data-method="delete"
                class="text-xs text-gray-400 hover:text-gray-600 transition-colors"
              >
                Logout
              </a>
            </div>
          </div>
        </header>
        <!-- Filter bar -->
        <.filter_bar
          filters={@filters}
          total={@total_count}
          filtered={@filtered_count}
          github_count={@github_count}
          gitlab_count={@gitlab_count}
        />
      </div>
      
    <!-- PR list -->
      <main class="max-w-screen-2xl mx-auto px-4 sm:px-6 py-5 pb-20">
        <!-- Skeleton loading: stale with no cached data -->
        <div
          :if={@stale and length(@prs) == 0}
          class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-3"
        >
          <.skeleton_cards count={6} />
        </div>
        
    <!-- Empty state: not stale and no PRs at all -->
        <.empty_state :if={not @stale and length(@prs) == 0} />
        
    <!-- No filter match -->
        <div
          :if={length(@filtered_prs) == 0 and length(@prs) > 0}
          class="text-center py-12 text-gray-400 text-sm"
        >
          No PRs match your filters.
        </div>
        
    <!-- PR grid (flat) -->
        <div
          :if={length(@filtered_prs) > 0 and is_nil(@grouped_prs)}
          class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-3"
        >
          <.pr_card
            :for={pr <- @filtered_prs}
            pr={pr}
            expanded={MapSet.member?(@expanded_checks, pr.number)}
            pinned={MapSet.member?(@pinned_prs, pr.id)}
          />
        </div>
        
    <!-- PR grid (grouped by repo) -->
        <div :if={length(@filtered_prs) > 0 and not is_nil(@grouped_prs)} class="space-y-6">
          <div :for={{repo, prs} <- @grouped_prs}>
            <h2 class="text-sm font-semibold text-gray-500 mb-2 flex items-center gap-1.5">
              <.icon name="hero-code-bracket-mini" class="w-3.5 h-3.5 text-gray-400" />
              {repo}
              <span class="font-normal text-gray-400">({length(prs)})</span>
            </h2>
            <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-3">
              <.pr_card
                :for={pr <- prs}
                pr={pr}
                expanded={MapSet.member?(@expanded_checks, pr.number)}
                pinned={MapSet.member?(@pinned_prs, pr.id)}
              />
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  defp save_filters(socket) do
    f = socket.assigns.filters

    push_event(socket, "config_changed", %{
      state: f[:state] && Atom.to_string(f[:state]),
      search: f[:search],
      hide_drafts: f[:hide_drafts],
      hide_dependabot: f[:hide_dependabot],
      platform: f[:platform] && Atom.to_string(f[:platform]),
      group_by_repo: f[:group_by_repo]
    })
  end

  defp needs_refresh?(user) do
    PrCache.stale?(user.id) or
      (not is_nil(user.gitlab_token) and PrCache.missing_source?(user.id, "gitlab")) or
      (not is_nil(user.github_token) and PrCache.missing_source?(user.id, "github"))
  end

  defp state_sort_key(:needs_attention), do: 1
  defp state_sort_key(:waiting_on_ci), do: 2
  defp state_sort_key(:needs_approval), do: 3
  defp state_sort_key(:ready_to_merge), do: 4
  defp state_sort_key(:draft), do: 5
  defp state_sort_key(_), do: 6
end
