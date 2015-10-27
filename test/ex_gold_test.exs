defmodule GoldTest do
  use Gold.DefaultCase
  doctest Gold

  test "getbalance", %{btc: pid} do
    assert Decimal.decimal?(Gold.getbalance!(pid))
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

  test "listtransactions", %{btc: pid} do
    transactions = Gold.listtransactions!(pid)
    
    assert is_list(transactions)
    assert Enum.all?(transactions, &Gold.Transaction.transaction?/1)
  end

  test "sendtoaddress", %{btc: pid} do
    address = Gold.getnewaddress!(pid)
    txid = Gold.sendtoaddress!(pid, address, Decimal.new("0.01"))
    tx = Gold.gettransaction!(pid, txid)

    assert Gold.Transaction.transaction?(tx)
  end

end
