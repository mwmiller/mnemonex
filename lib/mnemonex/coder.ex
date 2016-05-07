defmodule Mnemonex.Coder do
  use GenServer
  use Bitwise
  alias TheFuzz.Phonetic.MetaphoneAlgorithm, as: MPA

  @moduledoc """
  Mnemonex server process
  """

  @doc """
  Start a linked process
  """
  def start_link(opts, name) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    {:ok, Mnemonex.Config.init(opts)}
  end

  def handle_call({:encode, string}, _from, state), do: {:reply, string |> gather_words(state,[]) |> format_mnx(state), state}
  def handle_call({:decode, string}, _from, state), do: {:reply, string |> gather_numbers(state) |> words_to_bin(state.base_words, <<>>), state}

  defp gather_numbers(string,state), do: Regex.scan(~r/[a-z]+/, string |> String.downcase)
                                          |> List.flatten
                                          |> Enum.map( fn w -> word_to_index(w,state) end)
  defp word_to_index(word, state) do
      case Map.fetch(state.word_indices, word) do
            {:ok, v} -> v
            :error   -> sounds_like = word |> MPA.compute
                        Map.fetch!(state.metaphone_map, sounds_like) |> word_to_index(state)
      end
  end

  defp right_size(x,c) when byte_size(x) >= c, do: binary_part(x,0,c)
  defp right_size(x,c) when byte_size(x) < c,  do: right_size(x<><<0>>,c)
  defp multi_add([a], _base, acc), do: acc + a
  defp multi_add([x|rest], base, acc), do: multi_add(rest, base,x |> (&(acc + &1)).() |> (&(base * &1)).())

  defp words_to_bin([],_state, acc), do: acc
  defp words_to_bin([a,b,c|rest],base, acc) when c >= base, do: words_to_bin(rest, base, acc<>make_binary([c - base, b, a], 3, base))
  defp words_to_bin([a,b,c|rest],base, acc) when c <  base, do: words_to_bin(rest, base, acc<>make_binary([c, b, a], 4, base))
  defp words_to_bin([a,b|rest],  base, acc),                do: words_to_bin(rest, base, acc<>make_binary([b, a], 2, base))
  defp words_to_bin([a|rest],    base, acc),                do: words_to_bin(rest, base, acc<>make_binary([a], 1, base))

  def make_binary(list,c,base), do: list |> multi_add(base,0) |> :binary.encode_unsigned(:little) |> right_size(c)

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
    if state.as_list do
      words
    else
      words  |> combine(state.words_per_group, state.word_sep, [])
             |> combine(state.groups_per_line, state.group_sep, [])
             |> final_output(state)
    end
  end

  defp combine([], _c, _s, acc), do: acc |> Enum.reverse
  defp combine(bits, count, sep, acc) do
      {these, rest} = Enum.split(bits,count)
      combine(rest, count, sep, [Enum.join(these, sep)|acc])
  end
  defp final_output(lines, state), do: state.line_prefix<>Enum.join(lines, state.line_suffix<>state.line_prefix)<>state.line_suffix

end
