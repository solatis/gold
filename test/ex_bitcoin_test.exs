defmodule GoldTest do
  use Gold.DefaultCase
  doctest Gold

  test "getbalance", %{btc: pid} do
    assert is_integer(Gold.getbalance!(pid))
  end

  test "getnewaddress", %{btc: pid} do
    address = Gold.getnewaddress!(pid)
    
    assert String.length(address) >= 26
    assert String.length(address) <= 34
  end

  test "getnewaddress w/ account", %{btc: pid} do
    address = Gold.getnewaddress!(pid, "foo_account")
    
    assert String.length(address) >= 26
    assert String.length(address) <= 34

    account = Gold.getaccount!(pid, address)
    
    assert account == "foo_account"
  end


end
