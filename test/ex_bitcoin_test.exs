defmodule ExBitcoinTest do
  use ExBitcoin.DefaultCase
  doctest ExBitcoin

  test "getbalance", %{btc: pid} do
    assert is_integer(ExBitcoin.getbalance!(pid))
  end

  test "getnewaddress", %{btc: pid} do
    address = ExBitcoin.getnewaddress!(pid)
    
    assert String.length(address) >= 26
    assert String.length(address) <= 34
  end

  test "getnewaddress w/ account", %{btc: pid} do
    address = ExBitcoin.getnewaddress!(pid, "foo_account")
    
    assert String.length(address) >= 26
    assert String.length(address) <= 34

    account = ExBitcoin.getaccount!(pid, address)
    
    assert account == "foo_account"
  end


end
