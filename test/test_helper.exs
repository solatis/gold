defmodule Gold.DefaultCase do
  use ExUnit.CaseTemplate

  setup do        
    {:ok, pid} = 
      Gold.start_link(%Gold.Config{hostname: "localhost", port: 18332, user: "bitcoinrpc", password: "changeme"})
       
    {:ok, btc: pid}
  end
end

ExUnit.start()
