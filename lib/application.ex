defmodule HttpServer.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("starting the application")

    children = [
      {Task.Supervisor, name: HttpServer.ConnectionSupervisor},
      Supervisor.child_spec({Task, fn -> HttpServer.accept(4040) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: HttpServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
