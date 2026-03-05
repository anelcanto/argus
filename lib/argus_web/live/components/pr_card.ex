defmodule ArgusWeb.Live.Components.PrCard do
  @moduledoc false
  use Phoenix.Component
  import ArgusWeb.CoreComponents, only: [icon: 1]
  import ArgusWeb.Live.Components.Badge
  import ArgusWeb.Live.Components.PrStateBadge
  import ArgusWeb.Live.Components.CiStatusBadge
  import ArgusWeb.Live.Components.CiChecksDetail

  alias Argus.PullRequests.PrState

  attr :source, :atom, required: true

  defp platform_icon(%{source: :gitlab} = assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" class="w-3.5 h-3.5 shrink-0" fill="#FC6D26" aria-label="GitLab">
      <path d="m23.6004 9.5927-.0337-.0862L20.3.9814a.851.851 0 0 0-.3362-.405.8748.8748 0 0 0-.9997.0539.8748.8748 0 0 0-.29.4399l-2.2055 6.748H7.5375l-2.2057-6.748a.8573.8573 0 0 0-.29-.4412.8748.8748 0 0 0-.9997-.0537.8585.8585 0 0 0-.3362.4049L.4332 9.5015l-.0325.0862a6.0657 6.0657 0 0 0 2.0119 7.0105l.0113.0087.03.0213 4.976 3.7264 2.462 1.8633 1.4995 1.1321a1.0085 1.0085 0 0 0 1.2197 0l1.4995-1.1321 2.4619-1.8633 5.006-3.7489.0125-.01a6.0682 6.0682 0 0 0 2.0094-7.003z" />
    </svg>
    """
  end

  defp platform_icon(%{source: :github} = assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      class="w-3.5 h-3.5 shrink-0 text-gray-800"
      fill="currentColor"
      aria-label="GitHub"
    >
      <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
    </svg>
    """
  end

  defp platform_icon(assigns), do: ~H""

  attr :pr, :map, required: true
  attr :expanded, :boolean, default: false
  attr :pinned, :boolean, default: false

  def pr_card(assigns) do
    ~H"""
    <div
      id={"pr-#{@pr.source}-#{@pr.repo_owner}-#{@pr.repo_name}-#{@pr.number}"}
      class={"flex flex-col gap-2.5 rounded-xl border p-4 bg-white shadow-sm transition-shadow hover:shadow-md " <>
      if(@pinned, do: "border-blue-300 ring-1 ring-blue-100", else: "border-gray-200")}
    >
      
    <!-- Row 1: badges + actions -->
      <div class="flex items-start justify-between gap-2">
        <div class="flex items-center gap-1.5 flex-wrap min-w-0">
          <.pr_state_badge state={@pr.computed_state} />
          <.platform_icon source={@pr.source} />
          <.badge :if={@pr.draft} variant={:secondary}>Draft</.badge>
        </div>
        <div class="flex items-center gap-0.5 shrink-0">
          <button
            phx-click="toggle_pin"
            phx-value-pr={"#{@pr.source}:#{@pr.repo_owner}/#{@pr.repo_name}##{@pr.number}"}
            class={"p-0.5 rounded transition-colors " <>
              if(@pinned, do: "text-blue-500 bg-blue-50", else: "text-gray-300 hover:text-gray-500")}
            title={if @pinned, do: "Unpin", else: "Pin"}
          >
            <.icon
              name={if @pinned, do: "hero-bookmark-solid", else: "hero-bookmark"}
              class="w-4 h-4"
            />
          </button>
          <div
            id={"menu-#{@pr.source}-#{@pr.repo_owner}-#{@pr.repo_name}-#{@pr.number}"}
            phx-update="ignore"
          >
            <details class="relative">
              <summary class="p-0.5 rounded text-gray-300 hover:text-gray-500 transition-colors cursor-pointer list-none [&::-webkit-details-marker]:hidden">
                <.icon name="hero-ellipsis-horizontal-mini" class="w-4 h-4" />
              </summary>
              <div class="absolute right-0 top-6 z-30 bg-white border border-gray-200 rounded-lg shadow-md py-1 min-w-[130px]">
                <button
                  phx-click="close_pr"
                  phx-value-source={@pr.source}
                  phx-value-owner={@pr.repo_owner}
                  phx-value-repo={@pr.repo_name}
                  phx-value-number={@pr.number}
                  data-confirm="Close this PR?"
                  class="w-full flex items-center gap-2 px-3 py-1.5 text-xs text-red-600 hover:bg-red-50 transition-colors text-left"
                >
                  <.icon name="hero-x-mark-mini" class="w-3.5 h-3.5 shrink-0" /> Close PR
                </button>
              </div>
            </details>
          </div>
        </div>
      </div>
      
    <!-- Row 2: repo + number -->
      <div class="flex items-baseline gap-1.5">
        <span class="text-xs font-medium text-gray-500 truncate">
          {@pr.repo_owner}/{@pr.repo_name}
        </span>
        <span class="text-xs text-gray-300 shrink-0 tabular-nums">#{@pr.number}</span>
      </div>
      
    <!-- Row 3: title -->
      <a
        href={@pr.url}
        target="_blank"
        rel="noopener noreferrer"
        class="text-sm font-semibold text-gray-900 hover:text-blue-700 leading-snug line-clamp-2 transition-colors"
      >
        {@pr.title}
      </a>
      
    <!-- Row 4: branch + author + flags -->
      <div class="flex items-center gap-x-3 gap-y-1 text-xs text-gray-500 flex-wrap">
        <span :if={@pr.branch} class="font-mono text-gray-400 truncate max-w-[200px]">
          {@pr.branch} → {@pr.base_branch}
        </span>
        <span :if={@pr.author}>
          by <strong class="text-gray-600">{@pr.author}</strong>
        </span>
        <span :if={@pr.has_merge_conflicts} class="flex items-center gap-0.5 text-red-600 font-medium">
          <.icon name="hero-exclamation-triangle-mini" class="w-3.5 h-3.5 shrink-0" /> Conflicts
        </span>
        <span
          :if={@pr.unresolved_comments && @pr.unresolved_comments > 0}
          class="flex items-center gap-0.5 text-orange-600 font-medium"
        >
          <.icon name="hero-chat-bubble-oval-left-mini" class="w-3.5 h-3.5 shrink-0" />
          {@pr.unresolved_comments} unresolved
        </span>
      </div>
      
    <!-- Row 5: CI + attention items -->
      <div class="flex items-center justify-between gap-2 flex-wrap">
        <.ci_status_badge
          ci_state={@pr.ci_state}
          checks={@pr.checks || []}
          pr_number={@pr.number}
          expanded={@expanded}
        />
        <div :if={length(PrState.attention_items(@pr)) > 0} class="flex gap-1 flex-wrap">
          <.badge :for={item <- PrState.attention_items(@pr)} variant={:danger}>
            {item}
          </.badge>
        </div>
      </div>
      
    <!-- Expanded CI checks -->
      <.ci_checks_detail :if={@expanded} checks={@pr.checks || []} />
    </div>
    """
  end
end
