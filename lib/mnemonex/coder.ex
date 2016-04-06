defmodule Mnemonex.Coder do
  use GenServer
  use Bitwise

  @moduledoc """
  Mnemonex server

  The encoding and decoding functions are exposed here via
  calls to the server process.
  """

  @doc """
  Start a child process

  The default application server is accessible via the atom `:mnx_coder`.
  As a convenience, all functions default to use this server.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
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
  @spec encode(binary | pos_integer, pid) :: binary
  def encode(input, server \\ :mnx_coder)
  def encode(input, server) when is_binary(input), do: GenServer.call(server, {:encode, input})
  def encode(input, server) when is_integer input and input > 0 do
    GenServer.call(server, {:encode, :binary.encode_unsigned(input)})
  end

  @doc """
  decode a mnemonicoded word list

  All non-alphabetic (ASCII) characters are treated as word breaks.  There is
  presently no graceful handling of improperly entered words.
  """
  @spec decode(binary, pid) :: binary
  def decode(input, server \\ :mnx_coder) when is_binary(input), do: GenServer.call(server, {:decode, input})

  def init(:ok) do
    {:ok, Mnemonex.State.init}
  end

  def handle_call({:encode, string}, _from, state), do: {:reply, string |> gather_words(state,[]) |> format_mnx(state), state}
  def handle_call({:decode, string}, _from, state), do: {:reply, string |> gather_numbers(state) |> words_to_bin(state, <<>>), state}

  defp gather_numbers(string,state), do: Regex.scan(~r/[a-z]+/, string |> String.downcase)
                                          |> List.flatten
                                          |> Enum.map( fn w -> Map.fetch!(state.word_indices, w) end)

  defp words_to_bin([],_state, acc), do: acc
  defp words_to_bin([a,b,c|rest],state, acc) do
      base = state.base_words
      extra = c >= base
      x = if extra, do: c - base, else: c
      x = x * base
      x = x + b
      x = x * base
      x = x + a
      res = if not extra, do: <<x, (x>>>8), (x>>>16), (x>>>24)>>, else: <<x, (x>>>8), (x>>>16)>>
      words_to_bin(rest, state, acc<>res)
  end
  defp words_to_bin([a,b],state, acc) do
     base = state.base_words
     x = b
     x = x * base
     x = x + a
     words_to_bin([], state, acc<><<x, (x >>> 8)>>)
  end
  defp words_to_bin([a],state, acc), do: words_to_bin([], state, acc<><<a>>)

  defp gather_words(<<>>,_state,acc), do: acc |> Enum.reverse |> List.flatten
  defp gather_words(<<a,b,c,d,rest::binary>>,state,acc) do
      base = state.base_words
      x = a
      x = x ||| (b <<< 8)
      x = x ||| (c <<< 16)
      x = x ||| (d <<< 24)
      words = [x |> rem(base), x |> div(base) |> rem(base), x |> div(base) |> div(base) |> rem(base)]
      |> Enum.map(fn n -> elem(state.words, n) end)
     gather_words(rest,state,[words|acc])
  end
  defp gather_words(<<a,b,c>>,state,acc) do
      base = state.base_words
      extra = state.rem_words
      x = a
      x = x ||| (b <<< 8)
      x = x ||| (c <<< 16)
      words = [x |> rem(base), x |> div(base) |> rem(base), base + (x |> div(base) |> div(base) |> rem(base) |> rem(extra))]
      |> Enum.map(fn n -> elem(state.words, n) end)
     gather_words(<<>>,state,[words|acc])
  end
  defp gather_words(<<a,b>>,state,acc) do
      base = state.base_words
      x = a
      x = x ||| (b <<< 8)
      words = [x |> rem(base), x |> div(base) |> rem(base)]
      |> Enum.map(fn n -> elem(state.words, n) end)
     gather_words(<<>>,state,[words|acc])
  end
  defp gather_words(<<a>>,state,acc), do: gather_words(<<>>,state,[elem(state.words, a|>rem(state.base_words))|acc])

  defp format_mnx(words, state) do
    words  |> group_words(state, [])
           |> group_lines(state, [])
           |> final_output(state)
  end

  defp group_words([], _state, acc), do: acc |> Enum.reverse
  defp group_words(words, state, acc) do
      {these, rest} = Enum.split(words,state.words_per_group)
      group_words(rest, state, [Enum.join(these, state.word_sep)|acc])
  end
  defp group_lines([], _state, acc), do: acc |> Enum.reverse
  defp group_lines(groups, state, acc) do
      {these, rest} = Enum.split(groups,state.groups_per_line)
      group_lines(rest, state, [Enum.join(these, state.group_sep)|acc])
  end
  defp final_output(lines, state), do: state.line_prefix<>Enum.join(lines, state.line_suffix<>state.line_prefix)<>state.line_suffix

end
