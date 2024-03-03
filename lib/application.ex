defmodule HotDogServer.Application do
  use Application
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "42069")

    children = [
      {Task.Supervisor, name: HotDogServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> HotDogServer.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: HotDogServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
