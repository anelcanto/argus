defmodule ArgusWeb.SettingsLive do
  use ArgusWeb, :live_view

  alias Argus.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    if is_nil(current_user) do
      {:ok, redirect(socket, to: "/login")}
    else
      form = to_form(%{"gitlab_url" => current_user.gitlab_url || ""})

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:form, form)
       |> assign(:saved, false)
       |> assign(:pat_flash, nil)}
    end
  end

  @impl true
  def handle_event("disconnect_github", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.disconnect_github(user) do
      {:ok, updated_user} ->
        {:noreply, assign(socket, :current_user, updated_user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to disconnect GitHub.")}
    end
  end

  @impl true
  def handle_event("disconnect_gitlab", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.disconnect_gitlab(user) do
      {:ok, updated_user} ->
        {:noreply, assign(socket, :current_user, updated_user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to disconnect GitLab.")}
    end
  end

  @impl true
  def handle_event("save_github_pat", %{"github_token" => token}, socket) do
    user = socket.assigns.current_user
    token = String.trim(token)

    case Accounts.save_github_pat(user, token) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:pat_flash, {:ok, :github})}

      {:error, :unauthorized} ->
        {:noreply,
         assign(socket, :pat_flash, {:error, :github, "Token is invalid or unauthorized."})}

      {:error, _} ->
        {:noreply, assign(socket, :pat_flash, {:error, :github, "Failed to validate token."})}
    end
  end

  @impl true
  def handle_event("save_gitlab_pat", %{"gitlab_token" => token}, socket) do
    user = socket.assigns.current_user
    token = String.trim(token)

    case Accounts.save_gitlab_pat(user, token) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:pat_flash, {:ok, :gitlab})}

      {:error, :unauthorized} ->
        {:noreply,
         assign(socket, :pat_flash, {:error, :gitlab, "Token is invalid or unauthorized."})}

      {:error, _} ->
        {:noreply, assign(socket, :pat_flash, {:error, :gitlab, "Failed to validate token."})}
    end
  end

  @impl true
  def handle_event("save_gitlab_url", %{"gitlab_url" => url}, socket) do
    user = socket.assigns.current_user
    url = String.trim(url)

    case Accounts.update_gitlab_url(user, if(url == "", do: nil, else: url)) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:form, to_form(%{"gitlab_url" => updated_user.gitlab_url || ""}))
         |> assign(:saved, true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save GitLab URL.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <header class="bg-white border-b border-gray-100 px-4 sm:px-6 py-3">
        <div class="max-w-2xl mx-auto flex items-center justify-between">
          <div class="flex items-center gap-3">
            <a href="/" class="text-gray-400 hover:text-gray-600 transition-colors">
              <.icon name="hero-arrow-left-mini" class="w-4 h-4" />
            </a>
            <h1 class="text-base font-bold text-gray-900">Settings</h1>
          </div>
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
        </div>
      </header>

      <main class="max-w-2xl mx-auto px-4 sm:px-6 py-8 space-y-8">
        <!-- Connected Providers -->
        <section class="bg-white rounded-xl border border-gray-100 p-6 space-y-4">
          <h2 class="text-sm font-semibold text-gray-900">Connected Providers</h2>
          <div class="space-y-3">
            <!-- GitHub -->
            <div class="flex items-center justify-between py-2 border-b border-gray-50">
              <div class="flex items-center gap-2.5">
                <svg class="w-4 h-4 text-gray-700" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
                </svg>
                <span class="text-sm text-gray-700">GitHub</span>
              </div>
              <div class="flex items-center gap-2">
                <span class={[
                  "text-xs font-medium px-2 py-0.5 rounded-full",
                  if(@current_user.github_id,
                    do: "bg-green-50 text-green-700",
                    else: "bg-gray-100 text-gray-500"
                  )
                ]}>
                  {if @current_user.github_id, do: "Connected", else: "Not connected"}
                </span>
                <%= if @current_user.github_id do %>
                  <%= if @current_user.provider == "github" do %>
                    <span
                      class="text-xs text-gray-400"
                      title="You logged in with GitHub — cannot disconnect your primary provider"
                    >
                      Primary
                    </span>
                  <% else %>
                    <button
                      phx-click="disconnect_github"
                      data-confirm="Disconnect GitHub? You will lose access to GitHub pull requests."
                      class="text-xs text-red-500 hover:text-red-700 font-medium"
                    >
                      Disconnect
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
            
    <!-- GitLab -->
            <div class="flex items-center justify-between py-2">
              <div class="flex items-center gap-2.5">
                <svg class="w-4 h-4 text-orange-500" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M22.65 14.39L12 22.13 1.35 14.39a.84.84 0 0 1-.3-.94l1.22-3.78 2.44-7.51A.42.42 0 0 1 4.82 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.49h8.1l2.44-7.51A.42.42 0 0 1 18.6 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.51L23 13.45a.84.84 0 0 1-.35.94z" />
                </svg>
                <span class="text-sm text-gray-700">GitLab</span>
              </div>
              <div class="flex items-center gap-2">
                <span class={[
                  "text-xs font-medium px-2 py-0.5 rounded-full",
                  if(@current_user.gitlab_id || @current_user.gitlab_token,
                    do: "bg-green-50 text-green-700",
                    else: "bg-gray-100 text-gray-500"
                  )
                ]}>
                  {if @current_user.gitlab_id || @current_user.gitlab_token,
                    do: "Connected",
                    else: "Not connected"}
                </span>
                <%= if @current_user.gitlab_id || @current_user.gitlab_token do %>
                  <%= if @current_user.provider == "gitlab" do %>
                    <span
                      class="text-xs text-gray-400"
                      title="You logged in with GitLab — cannot disconnect your primary provider"
                    >
                      Primary
                    </span>
                  <% else %>
                    <button
                      phx-click="disconnect_gitlab"
                      data-confirm="Disconnect GitLab? You will lose access to GitLab merge requests."
                      class="text-xs text-red-500 hover:text-red-700 font-medium"
                    >
                      Disconnect
                    </button>
                  <% end %>
                <% else %>
                  <a
                    href="/auth/gitlab"
                    class="text-xs text-orange-600 hover:text-orange-700 font-medium"
                  >
                    Connect
                  </a>
                <% end %>
              </div>
            </div>
          </div>
        </section>
        
    <!-- Personal Access Tokens -->
        <section class="bg-white rounded-xl border border-gray-100 p-6 space-y-5">
          <div>
            <h2 class="text-sm font-semibold text-gray-900">Personal Access Tokens</h2>
            <p class="text-xs text-gray-500 mt-1">
              Provide a PAT to override OAuth tokens, or to connect without OAuth.
            </p>
          </div>
          
    <!-- GitHub PAT -->
          <div class="space-y-2">
            <div class="flex items-center gap-2">
              <svg class="w-3.5 h-3.5 text-gray-700" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
              </svg>
              <span class="text-xs font-medium text-gray-700">GitHub Token</span>
            </div>
            <form phx-submit="save_github_pat" class="flex gap-2">
              <input
                type="password"
                name="github_token"
                placeholder="ghp_••••••••••••••••••••"
                autocomplete="off"
                class="flex-1 text-sm border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button
                type="submit"
                class="px-4 py-2 bg-gray-900 text-white text-sm font-medium rounded-lg hover:bg-gray-800 transition-colors whitespace-nowrap"
              >
                Save
              </button>
            </form>
            <%= case @pat_flash do %>
              <% {:ok, :github} -> %>
                <p class="text-xs text-green-600 font-medium">GitHub token saved successfully.</p>
              <% {:error, :github, msg} -> %>
                <p class="text-xs text-red-600">{msg}</p>
              <% _ -> %>
                <p class="text-xs text-gray-400">
                  Generate at github.com/settings/tokens/new — required scopes: <code>repo</code>, <code>read:org</code>,
                  <code>user:email</code>
                </p>
            <% end %>
          </div>
          
    <!-- GitLab PAT -->
          <div class="space-y-2">
            <div class="flex items-center gap-2">
              <svg class="w-3.5 h-3.5 text-orange-500" fill="currentColor" viewBox="0 0 24 24">
                <path d="M22.65 14.39L12 22.13 1.35 14.39a.84.84 0 0 1-.3-.94l1.22-3.78 2.44-7.51A.42.42 0 0 1 4.82 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.49h8.1l2.44-7.51A.42.42 0 0 1 18.6 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.51L23 13.45a.84.84 0 0 1-.35.94z" />
              </svg>
              <span class="text-xs font-medium text-gray-700">GitLab Token</span>
            </div>
            <form phx-submit="save_gitlab_pat" class="flex gap-2">
              <input
                type="password"
                name="gitlab_token"
                placeholder="glpat-••••••••••••••••••••"
                autocomplete="off"
                class="flex-1 text-sm border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button
                type="submit"
                class="px-4 py-2 bg-gray-900 text-white text-sm font-medium rounded-lg hover:bg-gray-800 transition-colors whitespace-nowrap"
              >
                Save
              </button>
            </form>
            <%= case @pat_flash do %>
              <% {:ok, :gitlab} -> %>
                <p class="text-xs text-green-600 font-medium">GitLab token saved successfully.</p>
              <% {:error, :gitlab, msg} -> %>
                <p class="text-xs text-red-600">{msg}</p>
              <% _ -> %>
                <p class="text-xs text-gray-400">
                  Generate at {@current_user.gitlab_url ||
                    Application.get_env(:argus, :gitlab_url, "https://gitlab.com")}/-/user_settings/personal_access_tokens — required scopes: <code>read_user</code>, <code>api</code>,
                  <code>read_api</code>
                </p>
            <% end %>
          </div>
        </section>
        
    <!-- GitLab Instance URL -->
        <section class="bg-white rounded-xl border border-gray-100 p-6 space-y-4">
          <div>
            <h2 class="text-sm font-semibold text-gray-900">GitLab Instance URL</h2>
            <p class="text-xs text-gray-500 mt-1">
              Override the default GitLab instance for your account. Leave blank to use the app default.
            </p>
          </div>

          <.form for={@form} phx-submit="save_gitlab_url" class="space-y-3">
            <div>
              <input
                type="url"
                name="gitlab_url"
                id="gitlab_url"
                value={@form[:gitlab_url].value}
                placeholder={Application.get_env(:argus, :gitlab_url, "https://gitlab.com")}
                class="w-full text-sm border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div class="flex items-center gap-3">
              <button
                type="submit"
                class="px-4 py-2 bg-gray-900 text-white text-sm font-medium rounded-lg hover:bg-gray-800 transition-colors"
              >
                Save
              </button>
              <span :if={@saved} class="text-xs text-green-600 font-medium">Saved!</span>
            </div>
          </.form>
        </section>
      </main>
    </div>
    """
  end
end
