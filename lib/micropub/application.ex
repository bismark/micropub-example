defmodule Micropub.Application do
  use Application

  def start(_type, _args) do
    children = [
      MicropubWeb.Endpoint,
      Micropub.Store
    ]

    opts = [strategy: :one_for_one, name: Micropub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    MicropubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
