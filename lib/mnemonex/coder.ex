defmodule Mnemonex.Coder do
  use GenServer
  use Bitwise

  @moduledoc """
  Mnemonex server process
  """

  @doc """
  Start a linked process
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    {:ok, Mnemonex.State.init}
  end

  def handle_call({:encode, string}, _from, state), do: {:reply, string |> gather_words(state,[]) |> format_mnx(state), state}
  def handle_call({:decode, string}, _from, state), do: {:reply, string |> gather_numbers(state) |> words_to_bin(state.base_words, <<>>), state}

  defp gather_numbers(string,state), do: Regex.scan(~r/[a-z]+/, string |> String.downcase)
                                          |> List.flatten
                                          |> Enum.map( fn w -> Map.fetch!(state.word_indices, w) end)

  defp x_to_bin(x,c), do: 0..(c-1) |> Enum.reduce(<<>>,fn s,a -> bsr(x,s*8)
                                                          |> :binary.encode_unsigned(:little)
                                                          |> binary_part(0,1) |> (&(a<>&1)).() end)
  defp multi_add([a], _base, acc), do: acc + a
  defp multi_add([x|rest], base, acc), do: multi_add(rest, base,x |> (&(acc + &1)).() |> (&(base * &1)).())
  defp words_to_bin([],_state, acc), do: acc
  defp words_to_bin([a,b,c|rest],base, acc) when c >= base do
      res =  [c - base, b, a] |> multi_add(base,0) |> x_to_bin(3)
      words_to_bin(rest, base, acc<>res)
  end
  defp words_to_bin([a,b,c|rest],base, acc) when c < base do
      res =  [c, b, a] |> multi_add(base,0) |> x_to_bin(4)
      words_to_bin(rest, base, acc<>res)
  end
  defp words_to_bin([a,b],base, acc) do
     res = [b,a] |> multi_add(base,0) |> x_to_bin(2)
     words_to_bin([], base, acc<>res)
  end
  defp words_to_bin([a],base, acc), do: words_to_bin([], base, acc<><<a>>)

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
