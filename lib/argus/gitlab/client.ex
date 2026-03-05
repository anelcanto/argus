defmodule Argus.Gitlab.Client do
  @moduledoc false
  require Logger

  defp default_base_url do
    Application.get_env(:argus, :gitlab_url, "https://gitlab.com") <> "/api/v4"
  end

  defp build_client(token, base_url) do
    Req.new(
      base_url: base_url || default_base_url(),
      headers: [
        {"authorization", "Bearer #{token}"},
        {"content-type", "application/json"}
      ],
      retry: :transient,
      retry_delay: fn attempt -> :timer.seconds(attempt * 2) end,
      max_retries: 3
    )
  end

  def list_open_mrs(token, username, base_url \\ nil) do
    client = build_client(token, build_base_url(base_url))

    case Req.get(client,
           url: "/merge_requests",
           params: [state: "opened", author_username: username, scope: "all", per_page: 100]
         ) do
      {:ok, %{status: 200, body: mrs}} ->
        {:ok, mrs}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("GitLab list_open_mrs failed: #{status} #{inspect(body)}")
        {:error, {:http_error, status}}

      {:error, reason} ->
        Logger.error("GitLab list_open_mrs error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_mr_details(token, project_id, mr_iid, base_url \\ nil) do
    client = build_client(token, build_base_url(base_url))

    case Req.get(client, url: "/projects/#{encode_id(project_id)}/merge_requests/#{mr_iid}") do
      {:ok, %{status: 200, body: mr}} ->
        {:ok, mr}

      {:ok, %{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_mr_pipelines(token, project_id, mr_iid, base_url \\ nil) do
    client = build_client(token, build_base_url(base_url))

    case Req.get(client,
           url: "/projects/#{encode_id(project_id)}/merge_requests/#{mr_iid}/pipelines"
         ) do
      {:ok, %{status: 200, body: pipelines}} ->
        {:ok, pipelines}

      {:ok, %{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_mr_discussions(token, project_id, mr_iid, base_url \\ nil) do
    client = build_client(token, build_base_url(base_url))

    case Req.get(client,
           url: "/projects/#{encode_id(project_id)}/merge_requests/#{mr_iid}/discussions",
           params: [per_page: 100]
         ) do
      {:ok, %{status: 200, body: discussions}} ->
        {:ok, discussions}

      {:ok, %{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate_token(token, base_url \\ nil) do
    client = build_client(token, build_base_url(base_url))

    case Req.get(client, url: "/user") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, %{id: to_string(body["id"]), username: body["username"]}}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Build full API base URL from a per-user gitlab_url override (or nil to use app default)
  defp build_base_url(nil), do: nil
  defp build_base_url(url), do: String.trim_trailing(url, "/") <> "/api/v4"

  # GitLab requires URL-encoded project IDs when using namespace/repo format
  defp encode_id(project_id) when is_integer(project_id), do: project_id
  defp encode_id(project_id) when is_binary(project_id), do: URI.encode_www_form(project_id)
end
