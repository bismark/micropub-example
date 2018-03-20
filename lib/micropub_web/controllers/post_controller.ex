defmodule MicropubWeb.PostController do
  use MicropubWeb, :controller

  alias Micropub.Store

  def get(conn, %{"uid" => uid}) do
    case Store.get(uid) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: :not_found})

      post ->
        json(conn, post)
    end
  end
end
