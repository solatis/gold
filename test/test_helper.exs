defmodule Gold.DefaultCase do
  use ExUnit.CaseTemplate

  setup do        
    {:ok, btc: :regtest}
  end
end

ExUnit.start()
