defmodule Gold.DefaultCase do
  use ExUnit.CaseTemplate

  setup do        
    {:ok, btc: :bitcoin}
  end
end

ExUnit.start()
