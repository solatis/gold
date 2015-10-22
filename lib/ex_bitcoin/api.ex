defmodule Gold.Api do
  use GenServer

  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def handle_call(:balance, _from, state) do
    Logger.debug "handling balance call!"
    {:reply, 123.4, state}
  end

  ##
  # Internal functions
  ##
  defp rpc_request(url) do
    
  end

end
