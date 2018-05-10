defmodule TempStore.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      TempStore
    ]

    opts = [strategy: :one_for_one, name: TempStore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
