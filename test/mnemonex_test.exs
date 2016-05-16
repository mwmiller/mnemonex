defmodule Mnemonex.CoderTest do
  use PowerAssert

  setup context do
    {:ok, coder} = Mnemonex.Coder.start_link(Mnemonex.parse_coder_options([]), context.test)
    {:ok, coder: coder}
  end

  test "encode", %{coder: coder} do
    assert Mnemonex.encode(1,                   coder) ==  "acrobat\n"
    assert Mnemonex.encode(<<1>>,               coder) ==  "acrobat\n"
    assert Mnemonex.encode(<<1,2>>,             coder) ==  "opera-academy\n"
    assert Mnemonex.encode(<<1,2,3>>,           coder) ==  "kayak-cement-ego\n"
    assert Mnemonex.encode(<<1,2,3,4>>,         coder) ==  "papa-twist-alpine\n"
    assert Mnemonex.encode(<<1,2,3,4,5>>,       coder) ==  "papa-twist-alpine--admiral\n"
    assert Mnemonex.encode(<<1,2,3,4,5,6>>,     coder) ==  "papa-twist-alpine--shine-academy\n"
    assert Mnemonex.encode(<<1,2,3,4,5,6,7>>,   coder) ==  "papa-twist-alpine--chess-flute-ego\n"
    assert Mnemonex.encode(<<1,2,3,4,5,6,7,8>>, coder) ==  "papa-twist-alpine--content-sailor-athena\n";
    assert Mnemonex.encode(0x0102030405060708,  coder) ==  "papa-twist-alpine--content-sailor-athena\n";

    assert Mnemonex.encode(0xDEADBEEF,          coder) == "cigar-piano-round\n"
    assert Mnemonex.encode(<<222,173,190,239>>, coder) == "cigar-piano-round\n"
  end

  test "decode", %{coder: coder} do
    assert Mnemonex.decode("ACROBAT\n",                                  coder) == <<1>>
    assert Mnemonex.decode("Opera AcaDemy",                              coder) == <<1,2>>
    assert Mnemonex.decode("kayak-cement-ego",                           coder) == <<1,2,3>>
    assert Mnemonex.decode("papa-twist-alpine",                          coder) == <<1,2,3,4>>
    assert Mnemonex.decode("papa:twist:alpine:admiral",                  coder) == <<1,2,3,4,5>>
    assert Mnemonex.decode("papa/twist/alpine shine/academy",            coder) == <<1,2,3,4,5,6>>
    assert Mnemonex.decode("papa\ntwist\nalpine\nchess\nflute\nego\n",   coder) == <<1,2,3,4,5,6,7>>
    assert Mnemonex.decode("papa-twist-alpine--content-sailor-athena\n", coder) == <<1,2,3,4,5,6,7,8>>

    assert Mnemonex.decode("cigar-piano-round",                          coder) == <<222, 173, 190, 239>>
  end

  test "soundalike", %{coder: coder} do
    assert Mnemonex.decode("colombo-academy", coder) == Mnemonex.decode("columbo-academie", coder), "Both included == both sound-alike"
    assert Mnemonex.decode("hullo-analog", coder)    == Mnemonex.decode("hello-analogue", coder), "Mixed type on both sides"
  end

  test "fuzzy round trip", %{coder: coder} do
    test_em = fn
                 ([], _fun)      -> :noop
                 ([r|rest], fun) -> assert r |> Mnemonex.encode(coder) |> Mnemonex.decode(coder) == r
                                    fun.(rest, fun)
               end
    test_em.(FuzzData.random_bytes(1000), test_em)
  end

end
