defmodule Micropub.Handler do
  @behaviour PlugMicropub.HandlerBehaviour
  require Logger

  alias MicropubWeb.Router.Helpers
  alias Micropub.Store

  @access_token "abcd"

  @impl true
  def handle_create(type, properties, @access_token) do
    properties = handle_uploads(properties)
    params = %{type: type, properties: properties}
    uid = Store.create(params)
    {:ok, :created, Helpers.post_url(MicropubWeb.Endpoint, :get, uid)}
  end

  def handle_create(_, _, _), do: {:error, :insufficient_scope}

  @impl true
  def handle_update(url, replace, add, delete, @access_token) do
    uid = get_uid(url)
    Store.update(uid, replace, add, delete)
    :ok
  end

  def handle_update(_, _, _, _, _), do: {:error, :insufficient_scope}

  @impl true
  def handle_delete(url, @access_token) do
    uid = get_uid(url)
    Store.delete(uid)
    :ok
  end

  def handle_delete(_, _), do: {:error, :insufficient_scope}

  @impl true
  def handle_undelete(url, @access_token) do
    uid = get_uid(url)
    Store.undelete(uid)
    :ok
  end

  def handle_undelete(_, _), do: {:error, :insufficient_scope}

  @impl true
  def handle_config_query(@access_token) do
    # media_url = Helpers.url(MicropubWeb.Endpoint) <> "/micropub/media"
    media_url = "https://aac8937b.ngrok.io/micropub/media"
    {:ok, %{"media-endpoint": media_url}}
  end

  def handle_config_query(_), do: {:error, :insufficient_scope}

  @impl true
  def handle_source_query(url, filter_properties, @access_token) do
    uid = get_uid(url)
    case Store.get(uid) do
      nil -> {:error, :invalid_request}
      post ->
        case filter_properties do
          [] -> {:ok, post}
          filter_properties ->
            post =
              post
              |> Map.delete(:type)
              |> Map.update!(:properties, fn properties ->
                properties
                |> Enum.filter(fn {k, _} ->
                  Enum.member?(filter_properties, k)
                end)
                |> Map.new()
              end)
            {:ok, post}
        end
    end
  end

  def handle_source_query(_, _), do: {:error, :insufficient_scope}

  @impl true
  def handle_media(file, @access_token) do
    url = save_file(file)
    {:ok, url}
  end

  def handle_media(_, _), do: {:error, :insufficient_scope}

  defp get_uid(url) do
    url
    |> URI.parse()
    |> Map.fetch!(:path)
    |> Path.basename()
  end

  defp handle_uploads(properties) do
    properties
    |> _handle_uploads("photo")
    |> _handle_uploads("video")
  end

  defp _handle_uploads(properties, key) do
    if Map.has_key?(properties, key) do
      Map.update!(properties, key, fn entries ->
        Enum.map(entries, fn
          upload = %Plug.Upload{} -> save_file(upload)
          other -> other
        end)
      end)
    else
      properties
    end
  end

  defp save_file(file) do
    file = %{content_type: file.content_type, content: File.read!(file.path)}
    uuid = Store.create_media(file)
    Helpers.media_url(MicropubWeb.Endpoint, :get, uuid)
  end
end
