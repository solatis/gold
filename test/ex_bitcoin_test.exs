defmodule ExBitcoinTest do
  use ExUnit.Case
  doctest ExBitcoin

  test "the truth" do
    {:ok, pid} = 
      GenServer.start_link(ExBitcoin, 
                           %ExBitcoin.Config{hostname: "localhost", port: 18332, user: "bitcoinrpc", password: "changeme"})

    assert is_integer(ExBitcoin.getbalance!(pid))
  end

end
