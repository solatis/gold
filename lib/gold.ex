defmodule Gold do
  use Application

  require Logger

  alias Gold.Transaction

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    opts = [strategy: :one_for_one, name: Gold.Supervisor]
    Supervisor.start_link([], opts)
  end

  @doc """
  Returns wallet's total available balance, raising an exception on failure.
  """
  def getbalance(name, account \\ nil)
  def getbalance(name, nil) do
    call(name, :getbalance) |> handle_getbalance
  end
  def getbalance(name, account) do
    call(name, {:getbalance, [account]}) |> handle_getbalance
  end

  defp handle_getbalance({:ok, balance}), do:
    {:ok, btc_to_decimal(balance)}
  defp handle_getbalance(otherwise), do:
    otherwise

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(name, account \\ nil) do
    {:ok, balance} = getbalance(name, account)
    balance
  end

  @doc """
  Returns a new bitcoin address for receiving payments.
  """
  def getnewaddress(name, account \\ ""), do: call(name, {:getnewaddress, [account]})

  @doc """
  Returns a new bitcoin address for receiving payments, raising an exception on failure.
  """
  def getnewaddress!(name, account \\ "") do
    {:ok, address} = getnewaddress(name, account)
    address
  end

  @doc """
  Returns the account associated with the given address.
  """
  def getaccount(name, address), do: call(name, {:getaccount, [address]})

  @doc """
  Returns the account associated with the given address, raising an exception on failure.
  """
  def getaccount!(name, address) do
    {:ok, account} = getaccount(name, address)
    account
  end

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(name, account \\ "*", limit \\ 10, offset \\ 0) do
    case call(name, {:listtransactions, [account, limit, offset]}) do
      {:ok, transactions} ->
        {:ok, Enum.map(transactions, &Transaction.from_json/1)}
      otherwise ->
        otherwise
    end
  end

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(name, account \\ "*", limit \\ 10, offset \\ 0) do
    {:ok, transactions} = listtransactions(name, account, limit, offset)
    transactions
  end

  @doc """
  Get detailed information about in-wallet transaction.
  """
  def gettransaction(name, txid) do
    case call(name, {:gettransaction, [txid]}) do
      {:ok, transaction} ->
        {:ok, Transaction.from_json transaction}
      otherwise ->
        otherwise
    end
  end

  @doc """
  Get detailed information about in-wallet transaction, raising an exception on
  failure.
  """
  def gettransaction!(name, txid) do
    {:ok, tx} = gettransaction(name, txid)
    tx
  end

  @doc """
  Send an amount to a given address.
  """
  def sendtoaddress(name, address, %Decimal{} = amount) do
    call(name, {:sendtoaddress, [address, amount]})
  end

  @doc """
  Send an amount to a given address, raising an exception on failure.
  """
  def sendtoaddress!(name, address, %Decimal{} = amount) do
    {:ok, txid} = sendtoaddress(name, address, amount)
    txid
  end

  @doc """
  Add an address or pubkey script to the wallet without the associated private key.
  """
  def importaddress(name, address, account \\ "", rescan \\ true) do
    call(name, {:importaddress, [address, account, rescan]})
  end

  @doc """
  Add an address or pubkey script to the wallet without the associated private key,
  raising an exception on failure.
  """
  def importaddress!(name, address, account \\ "", rescan \\ true) do
    {:ok, _} = importaddress(name, address, account, rescan)
    :ok
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns.
  """
  def generate(name, amount) do
    call(name, {:generate, [amount]})
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns. Raises an
  exception on failure.
  """
  def generate!(name, amount) do
    {:ok, result} = generate(name, amount)
    result
  end

  @doc """
  https://bitcoin.org/en/developer-reference#getblock
  """
  def getblock(name, hash) do
    call(name, {:getblock, [hash]})
  end

  def getblock!(name, hash) do
    {:ok, block} = getblock(name, hash)
    block
  end

  @doc """
  https://bitcoin.org/en/developer-reference#getblockhash
  """
  def getblockhash(name, index) do
    call(name, {:getblockhash, [index]})
  end

  def getblockhash!(name, index) do
    {:ok, blockhash} = getblockhash(name, index)
    blockhash
  end

  @doc """
  https://bitcoin.org/en/developer-reference#getrawtransaction
  """
  def getrawtransaction(name, txid, verbose \\ 1) do
    call(name, {:getrawtransaction, [txid, verbose]})
  end

  def getrawtransaction!(name, txid, verbose \\ 1) do
    {:ok, tx} = getrawtransaction(name, txid, verbose)
    tx
  end

  @doc """
  https://bitcoin.org/en/developer-reference#getblockcount
  """
  def getblockcount(name) do
    call(name, {:getblockcount, []})
  end

  def getblockcount!(name) do
    {:ok, count} = getblockcount(name)
    count
  end

  @doc """
  https://bitcoin.org/en/developer-reference#gettxout
  """
  def gettxout(name, txid, n \\ 1) do
    call(name, {:gettxout, [txid, n]})
  end

  def gettxout!(name, txid, n \\ 1) do
    {:ok, txout} = gettxout(name, txid, n)
    txout
  end

  @info_methods ~w(getblockchaininfo
                   getmempoolinfo
                   gettxoutsetinfo
                   getinfo
                   getmemoryinfo
                   getmininginfo
                   getnetworkinfo
                   getpeerinfo
                   getwalletinfo)a

  Enum.each @info_methods, fn(method) ->
    @doc """
    https://bitcoin.org/en/developer-reference##{method}"
    """
    def unquote(method)(name) do
      call(name, {unquote(method), []})
    end

    @doc """
    https://bitcoin.org/en/developer-reference##{method}"
    """
    def unquote(:"#{method}!")(name) do
      {:ok, info} = call(name, {unquote(method), []})
      info
    end
  end

  @doc """
  Call generic RPC command
  """
  def call(name, method) when is_atom(method), do:
    call(name, {method, []})
  def call(name, {method, params}) when is_atom(method) do
    case load_config(name) do
      :undefined ->
        {:error, {:invalid_configuration, name}}
      config ->
        handle_rpc_request(method, params, config)
    end
  end

  ##
  # Internal functions
  ##
  defp handle_rpc_request(method, params, config) when is_atom(method) do
    %{hostname: hostname, port: port, user: user, password: password} = config

    Logger.debug "Bitcoin RPC request for method: #{method}, params: #{inspect params}"

    params = PoisonedDecimal.poison_params(params)

    command = %{"jsonrpc": "2.0",
                "method": to_string(method),
                "params": params,
                "id": 1}

    headers = ["Authorization": "Basic " <> Base.encode64(user <> ":" <> password)]

    options = [timeout: 30000, recv_timeout: 20000]

    case HTTPoison.post("http://" <> hostname <> ":" <> to_string(port) <> "/", Poison.encode!(command), headers, options) do
      {:ok, %{status_code: 200, body: body}} ->
        %{"error" => nil, "result" => result} = Poison.decode!(body)
        {:ok, result}
      {:ok, %{status_code: code, body: body}} ->
        handle_error(code, body)
    end
  end

  @statuses %{401 => :forbidden, 404 => :notfound, 500 => :internal_server_error}

  defp handle_error(status_code, error) do
    status = @statuses[status_code]
    Logger.debug "Bitcoin RPC error status #{status}: #{error}"
    case Poison.decode(error) do
      {:ok, %{"error" => %{"message" => message}}} ->
        {:error, %{status: status, error: message}}
      {:error, :invalid, _pos} ->
        {:error, %{status: status, error: error}}
      {:error, {:invalid, _token, _pos}} ->
        {:error, %{status: status, error: error}}
    end
  end

  @doc """
  Converts a float BTC amount to an Decimal.
  """
  def btc_to_decimal(btc) when is_float(btc) do
    satoshi_per_btc = :math.pow(10, 8)

    # Convert the bitcoins to integer to avoid any precision loss
    satoshi = round(btc * satoshi_per_btc)

    # Now construct a decimal
    %Decimal{sign: if(satoshi < 0, do: -1, else: 1), coef: abs(satoshi), exp: -8}
  end
  def btc_to_decimal(nil), do: nil

  defp load_config(name) do
    case :application.get_env(:gold, name) do
      {:ok, config} -> Enum.into(config, %{})
      :undefined -> :undefined
    end
  end

end
