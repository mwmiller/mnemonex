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

  defp word_x([], _s, acc), do: acc
  defp word_x([a|rest], s, acc), do: word_x(rest, s + 8, acc ||| bsl(a,s))

  defp to_words(_x,0,_base,acc), do: acc
  defp to_words(x,1,base,acc), do: to_words(x,0,base, [ x |> rem(base) | acc])
  defp to_words(x,2,base,acc), do: to_words(x,1,base, [ x |> div(base) |> rem(base) | acc])
  defp short_final_word(x,base,extra), do: to_words(x,2,base,[base +(x |> div(base) |> div(base) |> rem(base) |> rem(extra))])
  defp long_final_word(x,base), do: to_words(x,2,base,[x |> div(base) |> div(base) |> rem(base)])

  defp gather_words(<<>>,state,acc), do: acc |> Enum.reverse |> List.flatten |> Enum.map(fn n -> elem(state.words, n) end)
  defp gather_words(<<a,b,c,d,rest::binary>>,state,acc) do
     words = word_x([a,b,c,d],0,0) |> long_final_word(state.base_words)
     gather_words(rest,state,[words|acc])
  end
  defp gather_words(<<a,b,c>>,state,acc) do
     words = word_x([a,b,c],0,0) |> short_final_word(state.base_words,state.rem_words)
     gather_words(<<>>,state,[words|acc])
  end
  defp gather_words(<<a,b>>,state,acc) do
     words = word_x([a,b],0,0) |> to_words(2,state.base_words,[])
     gather_words(<<>>,state,[words|acc])
  end
  defp gather_words(<<a>>,state,acc) do
     words = word_x([a],0,0) |> to_words(1,state.base_words,[])
     gather_words(<<>>,state,[words|acc])
  end

  defp format_mnx(words, state) do
    words  |> combine(state.words_per_group, state.word_sep, [])
           |> combine(state.groups_per_line, state.group_sep, [])
           |> final_output(state)
  end

  defp combine([], _c, _s, acc), do: acc |> Enum.reverse
  defp combine(bits, count, sep, acc) do
      {these, rest} = Enum.split(bits,count)
      combine(rest, count, sep, [Enum.join(these, sep)|acc])
  end
  defp final_output(lines, state), do: state.line_prefix<>Enum.join(lines, state.line_suffix<>state.line_prefix)<>state.line_suffix

end
