defmodule GoldTest do
  use Gold.DefaultCase
  doctest Gold

  test "getbalance", %{btc: name} do
    assert Decimal.decimal?(Gold.getbalance!(name))
  end

  test "getnewaddress", %{btc: name} do
    address = Gold.getnewaddress!(name)
    
    assert String.length(address) >= 26
    assert String.length(address) <= 34
  end

  test "getnewaddress w/ account", %{btc: name} do
    address = Gold.getnewaddress!(name, "foo_account")
    
    assert String.length(address) >= 26
    assert String.length(address) <= 34

    account = Gold.getaccount!(name, address)
    
    assert account == "foo_account"
  end

  test "listtransactions", %{btc: name} do
    transactions = Gold.listtransactions!(name)
    
    assert is_list(transactions)
    assert Enum.all?(transactions, &Gold.Transaction.transaction?/1)
  end

  test "sendtoaddress -> generate -> gettransaction", %{btc: name} do
    # Generate blocks so we have some cash
    Gold.generate!(name, 101)
    address = Gold.getnewaddress!(name)
    txid = Gold.sendtoaddress!(name, address, Decimal.new("0.01"))
    tx = Gold.gettransaction!(name, txid)

    assert Gold.Transaction.transaction?(tx)

    # At this point, the transaction is only in our wallet and not yet
    # in the blockchain.
    assert tx.blockhash == nil

    # Now we generate a few blocks and check again.
    Gold.generate!(name, 10)

    tx = Gold.gettransaction!(name, txid)
    assert Gold.Transaction.transaction?(tx)
    assert tx.blockhash != nil
  end

end
