defmodule ArgusWeb.WebhookController do
  use ArgusWeb, :controller
  alias Argus.Cache.PrCache
  alias Argus.Sync.Poller

  def github(conn, params) do
    event = List.first(get_req_header(conn, "x-github-event")) || "unknown"
    handle_event(event, params)
    send_resp(conn, 200, "ok")
  end

  defp handle_event(event, %{"check_run" => check_run}) when event in ["check_run"] do
    repo = check_run["repository"] || %{}
    owner = get_in(repo, ["owner", "login"])
    repo_name = repo["name"]

    if owner && repo_name do
      Phoenix.PubSub.broadcast(
        Argus.PubSub,
        "ci_status:#{owner}/#{repo_name}",
        {:ci_updated, check_run}
      )

      broadcast_affected_users(owner, repo_name)
    end
  end

  defp handle_event(event, %{"pull_request" => pr})
       when event in ["pull_request"] do
    action = pr["action"]
    repo = pr["base"]["repo"] || %{}
    owner = get_in(repo, ["owner", "login"])
    repo_name = repo["name"]
    number = pr["number"]

    if action in ["opened", "closed", "reopened", "synchronize", "ready_for_review"] do
      Phoenix.PubSub.broadcast(
        Argus.PubSub,
        "pr_updates:#{owner}/#{repo_name}",
        {:pr_updated, number}
      )

      broadcast_affected_users(owner, repo_name)
    end
  end

  defp handle_event(_event, _params), do: :ok

  defp broadcast_affected_users(owner, repo_name) do
    user_ids = PrCache.get_user_ids_for_repo(owner, repo_name)

    for user_id <- user_ids do
      Poller.refresh_user(user_id)
    end
  end
end
