defmodule Mnemonex.Config do

  @moduledoc """
  word list configuration state
  """


  defstruct [words: {}, word_indices: %{}, words_version: nil,
            total_words: nil, base_words: nil, rem_words: nil,
            words_per_group: 3, groups_per_line: 2,
            word_sep: "-", group_sep: "--",
            line_prefix: "", line_suffix: "\n"]

  @type t :: %__MODULE__{}

  # Update base/remainder if changed with word list change.
  @doc """
  initialize the word list state

  Customized via the `:mnemonex` config.
  """
  def init do
      config      = Application.get_all_env(:mnemonex)
      short_words = config[:short_words]
      base_words  = config[:base_words]
      all_words   = combine_tuples(base_words,short_words)
      struct(__struct__,
              words: all_words,
              total_words:     tuple_size(all_words),
              base_words:      tuple_size(base_words),
              rem_words:       tuple_size(short_words),
              word_indices:    word_map(all_words),
              words_version:   config[:words_version],
              words_per_group: config[:words_per_group],
              word_sep:        config[:word_separator],
              groups_per_line: config[:groups_per_line],
              group_sep:       config[:group_separator],
              line_prefix:     config[:line_prefix],
              line_suffix:     config[:line_suffix],
            )
  end

  defp combine_tuples(first, second) do
    [first,second] |> Enum.map(&Tuple.to_list/1)
                   |> List.flatten
                   |> List.to_tuple
  end

  defp word_map(words) do
      words
        |> Tuple.to_list
        |> Enum.zip(0 .. tuple_size(words) - 1)
        |> Enum.reduce(%{}, fn({w,i},acc) -> Map.put(acc,w,i) end)
  end

end
