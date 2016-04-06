defmodule Mnemonex do
  use Application

  @process :mnx_coder

  @moduledoc """
  Mnemonex application

  The instance will be accessible from the process registry via
  the `:mnx_coder` atom.  In general, you should not need to know this
  as the useful functions default to that instance.
  """

  @doc """
  application start

  Any supplied arguments are ignored.
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Mnemonex.Coder, [@process])
    ]

    opts = [strategy: :one_for_one, name: Mnemonex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  encode a binary

  Unsigned big-endian integers may also be encoded, but note that there is presently
  no affordance to decode them back to same.

  The output will be formatted with 2 groups of three words per line:

  ```
  word0-word1-word2--word3-word4-word5
  word6-word7
  ```
  """
  @spec encode(binary | pos_integer, term) :: binary
  def encode(input, server \\ @process)
  def encode(input, server) when is_binary(input), do: GenServer.call(server, {:encode, input})
  def encode(input, server) when is_integer(input) and input > 0 do
    GenServer.call(server, {:encode, :binary.encode_unsigned(input)})
  end

  @doc """
  decode a mnemonicoded word list

  All non-alphabetic (ASCII) characters are treated as word breaks.  There is
  presently no graceful handling of improperly entered words.
  """
  @spec decode(binary, term) :: binary
  def decode(input, server \\ @process) when is_binary(input), do: GenServer.call(server, {:decode, input})

end
