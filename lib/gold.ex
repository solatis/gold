defmodule Gold do
  use GenServer

  require Logger

  alias Gold.Config
  alias Gold.Transaction

  ##
  # Client-side
  ##
  @doc """
  Starts GenServer link with Gold server.
  """
  def start_link(config), do: GenServer.start_link(__MODULE__, config)

  @doc """
  Returns server's total available balance.
  """
  def getbalance(name) do
    case GenServer.call(name, :getbalance) do
      {:ok, balance} -> 
        {:ok, btc_to_decimal(balance)}
      otherwise -> 
        otherwise
    end        
  end

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(name) do
    {:ok, balance} = getbalance(name)
    balance
  end

  @doc """
  Returns a new bitcoin address for receiving payments.
  """
  def getnewaddress(name), do: getnewaddress(name, "")

  @doc """
  Returns a new bitcoin address for receiving payments, raising an exception on failure.
  """
  def getnewaddress!(name), do: getnewaddress!(name, "")

  @doc """
  Returns a new bitcoin address for receiving payments.
  """
  def getnewaddress(name, account), do: GenServer.call(name, {:getnewaddress, [account]})

  @doc """
  Returns a new bitcoin address for receiving payments, raising an exception on failure.
  """
  def getnewaddress!(name, account) do
    {:ok, address} = getnewaddress(name, account)
    address
  end

  @doc """
  Returns the account associated with the given address.
  """
  def getaccount(name, address), do: GenServer.call(name, {:getaccount, [address]})

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
  def listtransactions(name), do: listtransactions(name, "*")

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(name), do: listtransactions!(name, "*")

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(name, account), do: listtransactions(name, account, 10)

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(name, account), do: listtransactions!(name, account, 10)

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(name, account, limit), do: listtransactions(name, account, limit, 0)

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(name, account, limit), do: listtransactions!(name, account, limit, 0)

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(name, account, limit, offset) do
    case GenServer.call(name, {:listtransactions, [account, limit, offset]}) do
      {:ok, transactions} ->
        {:ok, Enum.map(transactions, &Transaction.from_json/1)}
      otherwise ->
        otherwise
    end        
  end

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(name, account, limit, offset) do
    {:ok, transactions} = listtransactions(name, account, limit, offset)
    transactions
  end

  @doc """
  Get detailed information about in-wallet transaction.
  """
  def gettransaction(name, txid) do
    case GenServer.call(name, {:gettransaction, [txid]}) do
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
    GenServer.call(name, {:sendtoaddress, [address, amount]})
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
  def importaddress(name, address), do: importaddress(name, address, "")

  @doc """
  Add an address or pubkey script to the wallet without the associated private key,
  raising an exception on failure.
  """
  def importaddress!(name, address), do: importaddress!(name, address, "")

  @doc """
  Add an address or pubkey script to the wallet without the associated private key.
  """
  def importaddress(name, address, account), do: importaddress(name, address, account, true)

  @doc """
  Add an address or pubkey script to the wallet without the associated private key,
  raising an exception on failure.
  """
  def importaddress!(name, address, account), do: importaddress!(name, address, account, true)

  @doc """
  Add an address or pubkey script to the wallet without the associated private key.
  """
  def importaddress(name, address, account, rescan) do
    GenServer.call(name, {:importaddress, [address, account, rescan]})
  end

  @doc """
  Add an address or pubkey script to the wallet without the associated private key,
  raising an exception on failure.
  """
  def importaddress!(name, address, account, rescan) do
    {:ok, _} = importaddress(name, address, account, rescan)
    :ok
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns.
  """
  def generate(name, amount) do
    GenServer.call(name, {:generate, [amount]})
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns. Raises an
  exception on failure.
  """
  def generate!(name, amount) do
    {:ok, result} = generate(name, amount)
    result
  end

  ##
  # Server-side
  ##
  def handle_call(request, _from, config) 
      when is_atom(request), do: handle_rpc_request(request, [], config)
  def handle_call({request, params}, _from, config) 
      when is_atom(request) and is_list(params), do: handle_rpc_request(request, params, config)

  ##
  # Internal functions
  ##
  defp handle_rpc_request(method, params, config) when is_atom(method) do
    %Config{hostname: hostname, port: port, user: user, password: password} = config

    command = %{"jsonrpc": "2.0",
                "method": to_string(method),
                "params": params,
                "id": 1}

    headers = ["Authorization": "Basic " <> Base.encode64(user <> ":" <> password)]

    Logger.debug "Bitcoin RPC request for method: #{method}, params: #{inspect params}"

    case HTTPoison.post("http://" <> hostname <> ":" <> to_string(port) <> "/", Poison.encode!(command), headers) do
      {:ok, %{status_code: 200, body: body}} -> 
        case Poison.decode!(body) do
          %{"error" => nil, "result" => result} -> {:reply, {:ok, result}, config}
          %{"error" => error} -> {:reply, {:error, error}, config}
        end
      {:ok, %{status_code: 401}} -> 
        {:reply, :forbidden, config}
      {:ok, %{status_code: 404}} -> 
        {:reply, :notfound, config}
      {:ok, %{status_code: 500}} ->
        {:reply, :internal_server_error, config}
      otherwise -> 
        {:reply, otherwise, config}
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
  
end
