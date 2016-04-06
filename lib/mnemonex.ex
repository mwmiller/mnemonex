defmodule Mnemonex do
  use Application

  @moduledoc """
  Mnemonex application

  The instance will be accessible from the process registry via
  the `:mnx_coder` atom.  In general, you should not need to know this
  as the `Coder` functions default to that instance.
  """

  @doc """
  application start

  Any supplied arguments are ignored.
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Mnemonex.Coder, [:mnx_coder])
    ]

    opts = [strategy: :one_for_one, name: Mnemonex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
