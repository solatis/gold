defmodule ExBitcoinTest do
  use ExBitcoin.DefaultCase
  doctest ExBitcoin

  test "getbalance", %{btc: pid} do
    assert is_integer(ExBitcoin.getbalance!(pid))
  end

end
