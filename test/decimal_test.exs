defmodule DecimalTest do
  use Gold.DefaultCase

  test "btc_to_decimal returns properly formatted numbers", %{btc: pid} do
    assert (Gold.btc_to_decimal(100.0) |> Decimal.to_string(:normal)) == "100.00000000"
    assert (Gold.btc_to_decimal(0.0) |> Decimal.to_string(:normal)) == "0.00000000"
    assert (Gold.btc_to_decimal(-0.00000001) |> Decimal.to_string(:normal)) == "-0.00000001"
  end

end