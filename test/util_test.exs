defmodule UtilTest do
  use Gold.DefaultCase
  import PoisonedDecimal

  @decimal Decimal.new("123")

  test "btc_to_decimal returns properly formatted numbers" do
    assert (Gold.btc_to_decimal(100.0) |> Decimal.to_string(:normal)) == "100.00000000"
    assert (Gold.btc_to_decimal(0.0) |> Decimal.to_string(:normal)) == "0.00000000"
    assert (Gold.btc_to_decimal(-0.00000001) |> Decimal.to_string(:normal)) == "-0.00000001"
  end

  test "poisoning Decimal gives PoisonedDecimal" do
    assert poison_params(@decimal) == PoisonedDecimal.new(@decimal)
  end

  test "poisoning map with Decimal gives map with PoisonedDecimal" do
    assert poison_params(%{d: @decimal}) == %{d: PoisonedDecimal.new(@decimal)}
  end

  defmodule TestStruct do
    defstruct d: Decimal.new(0)
  end

  test "poisoning struct with Decimal gives struct with PoisonedDecimal" do
    assert poison_params(%TestStruct{d: @decimal}) == %TestStruct{d: PoisonedDecimal.new(@decimal)}
  end 

end