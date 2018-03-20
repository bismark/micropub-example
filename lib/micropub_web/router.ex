defmodule MicropubWeb.Router do
  use MicropubWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/" do
    pipe_through(:api)
    forward("/micropub", PlugMicropub, handler: Micropub.Handler, json_encoder: Jason)
  end

  scope "/", MicropubWeb do
    pipe_through(:api)

    get("/post/:uid", PostController, :get)
  end

  scope "/", MicropubWeb do
    get("/media/:uid", MediaController, :get)
  end
end
