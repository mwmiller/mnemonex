defmodule Mnemonex.CoderTest do
  use PowerAssert

  setup context do
    {:ok, coder} = Mnemonex.Coder.start_link(context.test)
    {:ok, coder: coder}
  end

  test "encode", %{coder: coder} do
    assert Mnemonex.Coder.encode(1,                   coder) ==  "acrobat\n"
    assert Mnemonex.Coder.encode(<<1>>,               coder) ==  "acrobat\n"
    assert Mnemonex.Coder.encode(<<1,2>>,             coder) ==  "opera-academy\n"
    assert Mnemonex.Coder.encode(<<1,2,3>>,           coder) ==  "kayak-cement-ego\n"
    assert Mnemonex.Coder.encode(<<1,2,3,4>>,         coder) ==  "papa-twist-alpine\n"
    assert Mnemonex.Coder.encode(<<1,2,3,4,5>>,       coder) ==  "papa-twist-alpine--admiral\n"
    assert Mnemonex.Coder.encode(<<1,2,3,4,5,6>>,     coder) ==  "papa-twist-alpine--shine-academy\n"
    assert Mnemonex.Coder.encode(<<1,2,3,4,5,6,7>>,   coder) ==  "papa-twist-alpine--chess-flute-ego\n"
    assert Mnemonex.Coder.encode(<<1,2,3,4,5,6,7,8>>, coder) ==  "papa-twist-alpine--content-sailor-athena\n";
    assert Mnemonex.Coder.encode(0x0102030405060708,  coder) ==  "papa-twist-alpine--content-sailor-athena\n";
  end

  test "decode", %{coder: coder} do
    assert Mnemonex.Coder.decode("ACROBAT\n",                                  coder) == <<1>>
    assert Mnemonex.Coder.decode("Opera AcaDemy",                              coder) == <<1,2>>
    assert Mnemonex.Coder.decode("kayak-cement-ego",                           coder) == <<1,2,3>>
    assert Mnemonex.Coder.decode("papa-twist-alpine",                          coder) == <<1,2,3,4>>
    assert Mnemonex.Coder.decode("papa:twist:alpine:admiral",                  coder) == <<1,2,3,4,5>>
    assert Mnemonex.Coder.decode("papa/twist/alpine shine/academy",            coder) == <<1,2,3,4,5,6>>
    assert Mnemonex.Coder.decode("papa\ntwist\nalpine\nchess\nflute\nego\n",   coder) == <<1,2,3,4,5,6,7>>
    assert Mnemonex.Coder.decode("papa-twist-alpine--content-sailor-athena\n", coder) == <<1,2,3,4,5,6,7,8>>
  end

  test "fuzzy round trip", %{coder: coder} do
    test_em = fn
                 ([], _fun)      -> :noop
                 ([r|rest], fun) -> assert r |> Mnemonex.Coder.encode(coder) |> Mnemonex.Coder.decode(coder) == r
                                    fun.(rest, fun)
               end
    test_em.(FuzzData.random_bytes(1000), test_em)
  end

end
