defmodule Mnemonex do
  use Application

  @process :mnx_coder

  @moduledoc """
  Mnemonex application

  """

  @typedoc """
  A keyword list with output formatting options

  - `name`: registered process name (default: `:mnx_coder`)
  - `as_list`: return a list of unformatted words (default: `false`)
  - `words_per_group`: words per output group (default: `3`)
  - `word_separator`: combining words in a group (default: `-`)
  - `groups_per_line`: groups per output line (default: `2`)
  - `group_separator`: combining groups in a line (default: `--`)
  - `line_prefix`: prepended to each output line (default: empty string)
  - `line_suffix`: appended to each output line (default: `\n`)

  """
  @type coder_options :: [
          name: atom,
          as_list: boolean,
          words_per_group: pos_integer,
          word_separator: String.t(),
          groups_per_line: pos_integer,
          group_separator: String.t(),
          line_prefix: String.t(),
          line_suffix: String.t()
        ]

  @spec parse_coder_options(coder_options) :: coder_options
  @doc false
  def parse_coder_options(options) do
    [
      name: Keyword.get(options, :name, @process),
      as_list: Keyword.get(options, :as_list, false),
      words_per_group: Keyword.get(options, :words_per_group, 3),
      word_separator: Keyword.get(options, :word_separator, "-"),
      groups_per_line: Keyword.get(options, :groups_per_line, 2),
      group_separator: Keyword.get(options, :group_separator, "--"),
      line_prefix: Keyword.get(options, :line_prefix, ""),
      line_suffix: Keyword.get(options, :line_suffix, "\n")
    ]
  end

  @doc """
  application start
  """
  def start(_type, opts \\ []) do
    import Supervisor.Spec, warn: false

    filled_out = parse_coder_options(opts)

    children = [
      {Mnemonex.Coder, [filled_out, filled_out[:name]]}
    ]

    opts = [strategy: :one_for_one, name: Mnemonex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  encode a binary

  Unsigned big-endian integers may also be encoded, but note that there is presently
  no affordance to decode them back to same.

  The output format depends on configuration variables (described therein.)
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
  def decode(input, server \\ @process) when is_binary(input),
    do: GenServer.call(server, {:decode, input})
end
