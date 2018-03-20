defmodule MicropubWeb.MediaController do

  use MicropubWeb, :controller

  alias Micropub.Store

  def get(conn, %{"uid" => uid}) do
    case Store.get_media(uid) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: :not_found})
      media ->
        conn
        |> put_resp_content_type(media.content_type)
        |> send_resp(:ok, media.content)
    end
  end

end

