defmodule GoldTest do
  use Gold.DefaultCase
  doctest Gold

  test "supervisor starts" do
    {:ok, pid} = Gold.start(nil, [])
    assert pid
  end

  test "getbalance!", %{btc: name} do
    assert Decimal.decimal?(Gold.getbalance!(name))
  end

  test "getbalance", %{btc: name} do
    {:ok, balance} = Gold.getbalance(name)
    assert Decimal.decimal?(balance)
  end

  test "getbalance with invalid config" do
    assert Gold.getbalance(:test) == {:error, {:invalid_configuration, :test}}
  end

  test "getbalance with account", %{btc: name} do
    {:ok, balance} = Gold.getbalance(name, "")
    assert Decimal.decimal?(balance)
  end

  test "getnewaddress", %{btc: name} do
    address = Gold.getnewaddress!(name)
    assert String.length(address) >= 26
    assert String.length(address) <= 34
  end

  test "getnewaddress w/ account by getaccount!", %{btc: name} do
    address = Gold.getnewaddress!(name, "foo_account")
    assert String.length(address) >= 26
    assert String.length(address) <= 34

    account = Gold.getaccount!(name, address)
    assert account == "foo_account"
  end

  test "getaccount with invalid bitcoin address", %{btc: name} do
    assert Gold.getaccount(name, "asdfasdfasdf") == {:error, %{error: "Invalid Bitcoin address", status: :internal_server_error}}
  end

  test "getaccount! raises with invalid bitcoin address", %{btc: name} do
    assert_raise MatchError, fn ->
      Gold.getaccount!(name, "fasdfsdaf")
    end
  end

  test "listtransactions", %{btc: name} do
    transactions = Gold.listtransactions!(name)
    assert is_list(transactions)
    assert Enum.all?(transactions, &Gold.Transaction.transaction?/1)
  end

  test "listransactions with invalid input", %{btc: name} do
    assert Gold.listtransactions(name, "*", "AAA") == {:error,
      %{error: "JSON value is not an integer as expected", status: :internal_server_error}}
  end

  test "gettransaction with invalid input", %{btc: name} do
    assert Gold.gettransaction(name, "fsadfasdfasd") == {:error,
      %{error: "Invalid or non-wallet transaction id", status: :internal_server_error}}
  end

  test "sendtoaddress -> generate -> gettransaction", %{btc: name} do
    # Generate blocks so we have some cash
    Gold.generate!(name, 5)
    address = Gold.getnewaddress!(name)
    txid = Gold.sendtoaddress!(name, address, Decimal.new("0.01"))
    tx = Gold.gettransaction!(name, txid)

    assert Gold.Transaction.transaction?(tx)

    # At this point, the transaction is only in our wallet and not yet
    # in the blockchain.
    assert tx.blockhash == nil

    # Now we generate a few blocks and check again.
    Gold.generate!(name, 2)
    tx = Gold.gettransaction!(name, txid)
    assert Gold.Transaction.transaction?(tx)
    assert tx.blockhash != nil
  end

  test "importaddress", %{btc: name} do
    assert Gold.importaddress!(name, "mviKj9i2zQmoLVUGkLBMuDhwvAwDmfrAmZ") == :ok
  end

  test "importaddress with invalid input", %{btc: name} do
    assert Gold.importaddress(name, "asdasda") == {:error,
      %{error: "Invalid Bitcoin address or script", status: :internal_server_error}}
  end

  test "getblock!", %{btc: name} do
    [hash] = Gold.generate!(name, 1)
    block = Gold.getblock!(name, hash)
    assert block["confirmations"] == 1
    assert block["hash"] == hash
  end

  test "getblock with invalid hash", %{btc: name} do
    assert Gold.getblock(name, "asdasd") == {:error, %{error: "Block not found", status: :internal_server_error}}
  end

  test "getblockhash!", %{btc: name} do
    [hash] = Gold.generate!(name, 1)
    block = Gold.getblock!(name, hash)
    assert Gold.getblockhash!(name, block["height"]) == block["hash"]
  end

  test "getblockhash with invalid height", %{btc: name} do
    assert Gold.getblockhash(name, 100000) == {:error, %{error: "Block height out of range", status: :internal_server_error}}
  end

  test "error handling", %{btc: name} do
    {:error, %{error: "JSON integer out of range", status: :internal_server_error}} =
      Gold.generate(name, 0x80000000)
  end


  @info_floats ["relayfee", "paytxfee", "difficulty", "balance"]
  @info_integers ["walletversion", "version", "timeoffset", "protocolversion",
   "keypoolsize", "keypoololdest", "connections", "blocks"]

  @info_methods ~w(getinfo
                   getblockchaininfo
                   getmempoolinfo
                   getmemoryinfo
                   getmininginfo
                   getnetworkinfo
                   getpeerinfo
                   getwalletinfo)a

  Enum.each @info_methods, fn(method) ->

    test method, %{btc: name} do
      {:ok, info} = :erlang.apply(Gold, unquote(method), [name])
      Enum.each info, fn
        ({key, value}) when key in @info_floats -> assert is_float(value)
        ({key, value}) when key in @info_integers -> assert is_integer(value)
        (other) -> other
      end
    end

    method_bang = :"#{method}!"

    test method_bang, %{btc: name} do
      info = :erlang.apply(Gold, unquote(method_bang), [name])
      Enum.each info, fn
        ({key, value}) when key in @info_floats -> assert is_float(value)
        ({key, value}) when key in @info_integers -> assert is_integer(value)
        (other) -> other
      end
    end
  end
end
