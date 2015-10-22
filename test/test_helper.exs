defmodule Gold.DefaultCase do
  use ExUnit.CaseTemplate

  setup do        
    {:ok, pid} = 
      GenServer.start_link(Gold, 
                           %Gold.Config{hostname: "localhost", port: 18332, user: "bitcoinrpc", password: "changeme"})
       
    {:ok, btc: pid}
  end
end

ExUnit.start()
