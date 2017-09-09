defmodule Mnemonex.Config do
  alias TheFuzz.Phonetic.MetaphoneAlgorithm, as: MPA

  @moduledoc """
  word list configuration state
  """

  defstruct [words: {}, word_indices: %{}, words_version: nil,
             metaphone_map: %{}, as_list: false,
             total_words: nil, base_words: nil, rem_words: nil,
             words_per_group: 0, groups_per_line: 0,
             word_sep: "", group_sep: "",
             line_prefix: "", line_suffix: ""
            ]

  @type t :: %__MODULE__{}

  # Update base/remainder if changed with word list change.
  @doc """
  initialize the word list state
  """
  def init(opts) do
      config      = Application.get_all_env(:mnemonex)
      short_words = config[:short_words]
      base_words  = config[:base_words]
      all_words   = combine_tuples(base_words, short_words)
      struct(__struct__(),
              words:           all_words,
              total_words:     tuple_size(all_words),
              base_words:      tuple_size(base_words),
              rem_words:       tuple_size(short_words),
              word_indices:    word_map(all_words),
              metaphone_map:   metaphone_map(all_words),
              words_version:   config[:words_version],
              as_list:         opts[:as_list],
              words_per_group: opts[:words_per_group],
              word_sep:        opts[:word_separator],
              groups_per_line: opts[:groups_per_line],
              group_sep:       opts[:group_separator],
              line_prefix:     opts[:line_prefix],
              line_suffix:     opts[:line_suffix],
            )
  end

  defp combine_tuples(first, second) do
    [first, second] |> Enum.map(&Tuple.to_list/1)
                    |> List.flatten
                    |> List.to_tuple
  end

  defp word_map(words) do
      words
        |> Tuple.to_list
        |> Enum.zip(0 .. tuple_size(words) - 1)
        |> Enum.reduce(%{}, fn({w, i}, acc) -> Map.put(acc, w, i) end)
  end

  defp map_uniqs({k, v}, {uniq, all}) do
     uniq = case Map.fetch(all, k) do
              {:ok, _ov} -> Map.delete(uniq, k)
              :error     -> Map.put(uniq, k, v)
            end
    all = Map.put(uniq, k, v)
    {uniq, all}
  end

  defp metaphone_map(words) do
      word_list = words |> Tuple.to_list
      word_list
         |> Enum.map(&MPA.compute/1)
         |> Enum.zip(word_list)
         |> Enum.reduce({%{}, %{}}, &map_uniqs/2)
         |> elem(0)
  end

end
