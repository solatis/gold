defmodule Gold do
  use GenServer

  require Logger

  alias Gold.Config
  alias Gold.Transaction

  ##
  # Client-side
  ##
  def start_link(config), do: GenServer.start_link(__MODULE__, config)

  @doc """
  Returns server's total available balance.
  """
  def getbalance(pid) do
    case GenServer.call(pid, :getbalance) do
      {:ok, balance} -> 
        {:ok, btc_to_decimal(balance)}
      otherwise -> 
        otherwise
    end        
  end

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(pid) do
    {:ok, balance} = getbalance(pid)
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
  def listtransactions(pid), do: listtransactions(pid, "")

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid), do: listtransactions!(pid, "")

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
  def listtransactions(pid, account, limit, offset) do
    case GenServer.call(pid, {:listtransactions, [account, limit, offset]}) do
      {:ok, transactions} ->
        {:ok, Enum.map(transactions, &Transaction.from_json/1)}
      otherwise -> 
        otherwise
    end        
  end

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account, limit, offset) do
    {:ok, transactions} = listtransactions(pid, account, limit, offset)
    transactions
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
    %Decimal{sign: 1, coef: satoshi, exp: -8}
  end

  def btc_to_decimal(nil), do: nil
  
end
