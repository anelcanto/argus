defmodule ArgusWeb.LoginLive do
  use ArgusWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    github_configured? =
      Application.get_env(:ueberauth, Ueberauth.Strategy.Github.OAuth, [])
      |> Keyword.get(:client_id)
      |> then(&(not is_nil(&1) and &1 != ""))

    gitlab_configured? =
      Application.get_env(:ueberauth, Ueberauth.Strategy.Gitlab.OAuth, [])
      |> Keyword.get(:client_id)
      |> then(&(not is_nil(&1) and &1 != ""))

    {:ok,
     socket
     |> assign(:github_configured, github_configured?)
     |> assign(:gitlab_configured, gitlab_configured?)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-8 w-full max-w-sm space-y-6">
        <div class="space-y-1">
          <h1 class="text-xl font-bold text-gray-900">Argus</h1>
          <p class="text-sm text-gray-500">PR Monitor Dashboard</p>
        </div>

        <div class="space-y-3">
          <a
            :if={@github_configured}
            href="/auth/github"
            class="flex items-center justify-center gap-2.5 w-full px-4 py-2.5 bg-gray-900 text-white text-sm font-medium rounded-lg hover:bg-gray-800 transition-colors"
          >
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
            </svg>
            Sign in with GitHub
          </a>

          <a
            :if={@gitlab_configured}
            href="/auth/gitlab"
            class="flex items-center justify-center gap-2.5 w-full px-4 py-2.5 bg-orange-600 text-white text-sm font-medium rounded-lg hover:bg-orange-700 transition-colors"
          >
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M22.65 14.39L12 22.13 1.35 14.39a.84.84 0 0 1-.3-.94l1.22-3.78 2.44-7.51A.42.42 0 0 1 4.82 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.49h8.1l2.44-7.51A.42.42 0 0 1 18.6 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.51L23 13.45a.84.84 0 0 1-.35.94z" />
            </svg>
            Sign in with GitLab
          </a>

          <div
            :if={not @github_configured and not @gitlab_configured}
            class="text-sm text-gray-500 text-center py-4 space-y-2"
          >
            <p class="font-medium text-gray-700">No OAuth providers configured</p>
            <p>
              Set <code class="bg-gray-100 px-1 rounded">GITHUB_CLIENT_ID</code>
              or <code class="bg-gray-100 px-1 rounded">GITLAB_CLIENT_ID</code>
              to enable sign-in.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
