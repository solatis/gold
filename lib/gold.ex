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
  def getbalance(pid), do: getbalance(pid, "")

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(pid), do: getbalance!(pid, "")

  @doc """
  Returns server's total available balance.
  """
  def getbalance(pid, account), do: getbalance(pid, account, 1)

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(pid, account), do: getbalance!(pid, account, 1)

  @doc """
  Returns server's total available balance.
  """
  def getbalance(pid, account, confirmations), do: getbalance(pid, account, confirmations, false)

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(pid, account, confirmations), do: getbalance!(pid, account, confirmations, false)

  @doc """
  Returns server's total available balance.
  """
  def getbalance(pid, account, confirmations, watchonly) do
    case GenServer.call(pid, {:getbalance, [account, confirmations, watchonly]}) do
      {:ok, balance} -> 
        {:ok, btc_to_decimal(balance)}
      otherwise -> 
        otherwise
    end        
  end

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(pid, account, confirmations, watchonly) do
    {:ok, balance} = getbalance(pid, account, confirmations, watchonly)
    balance
  end

  @doc """
  Returns a new bitcoin address for receiving payments.
  """
  def getnewaddress(pid), do: getnewaddress(pid, "")

  @doc """
  Returns a new bitcoin address for receiving payments, raising an exception on failure.
  """
  def getnewaddress!(pid), do: getnewaddress!(pid, "")

  @doc """
  Returns a new bitcoin address for receiving payments.
  """
  def getnewaddress(pid, account), do: GenServer.call(pid, {:getnewaddress, [account]})

  @doc """
  Returns a new bitcoin address for receiving payments, raising an exception on failure.
  """
  def getnewaddress!(pid, account) do
    {:ok, address} = getnewaddress(pid, account)
    address
  end

  @doc """
  Returns the account associated with the given address.
  """
  def getaccount(pid, address), do: GenServer.call(pid, {:getaccount, [address]})

  @doc """
  Returns the account associated with the given address, raising an exception on failure.
  """
  def getaccount!(pid, address) do
    {:ok, account} = getaccount(pid, address)
    account
  end

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid), do: listtransactions(pid, "*")

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid), do: listtransactions!(pid, "*")

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid, account), do: listtransactions(pid, account, 10)

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account), do: listtransactions!(pid, account, 10)

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid, account, limit), do: listtransactions(pid, account, limit, 0)

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account, limit), do: listtransactions!(pid, account, limit, 0)

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid, account, limit, offset), do: listtransactions(pid, account, limit, offset, false)

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account, limit, offset), do: listtransactions!(pid, account, limit, offset, false)

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid, account, limit, offset, watchonly) do
    case GenServer.call(pid, {:listtransactions, [account, limit, offset, watchonly]}) do
      {:ok, transactions} ->
        {:ok, Enum.map(transactions, &Transaction.from_json/1)}
      otherwise ->
        otherwise
    end        
  end

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account, limit, offset, watchonly) do
    {:ok, transactions} = listtransactions(pid, account, limit, offset, watchonly)
    transactions
  end

  @doc """
  Get detailed information about in-wallet transaction.
  """
  def gettransaction(pid, txid) do
    case GenServer.call(pid, {:gettransaction, [txid]}) do
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
  def gettransaction!(pid, txid) do
    {:ok, tx} = gettransaction(pid, txid)
    tx
  end

  @doc """
  Send an amount to a given address.
  """
  def sendtoaddress(pid, address, %Decimal{} = amount) do
    GenServer.call(pid, {:sendtoaddress, [address, amount]})
  end

  @doc """
  Send an amount to a given address, raising an exception on failure.
  """
  def sendtoaddress!(pid, address, %Decimal{} = amount) do
    {:ok, txid} = sendtoaddress(pid, address, amount)
    txid
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns.
  """
  def generate(pid, amount) do
    GenServer.call(pid, {:generate, [amount]})
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns. Raises an
  exception on failure.
  """
  def generate!(pid, amount) do
    {:ok, result} = generate(pid, amount)
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
