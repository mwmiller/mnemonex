ExUnit.start()

defmodule FuzzData do

  def random_bytes(n), do: gen_random_bytes(n, [])

  def gen_random_bytes(0, acc), do: acc
  def gen_random_bytes(n, acc), do: gen_random_bytes(n-1, [(:rand.uniform(20) |> :crypto.strong_rand_bytes) | acc])

end
