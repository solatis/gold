defmodule UtilTest do
  use Gold.DefaultCase
  import PoisonedDecimal

  @decimal Decimal.new("123")
  @pdecimal PoisonedDecimal.new(@decimal)

  test "btc_to_decimal returns properly formatted numbers" do
    assert (Gold.btc_to_decimal(100.0) |> Decimal.to_string(:normal)) == "100.00000000"
    assert (Gold.btc_to_decimal(0.0) |> Decimal.to_string(:normal)) == "0.00000000"
    assert (Gold.btc_to_decimal(-0.00000001) |> Decimal.to_string(:normal)) == "-0.00000001"
  end

  test "poisoning integer gives integer" do
    assert poison_params(123) == 123
  end

  test "poisoning string gives string" do
    assert poison_params("asdasd") == "asdasd"
  end

  test "poisoning float gives float" do
    assert poison_params(123.456) == 123.456
  end

  test "poisoning boolean gives boolean" do
    assert poison_params(true) == true 
  end

  test "poisoning atom gives atom" do
    assert poison_params(:test) == :test
  end

  test "poisoning tuple gives tuple" do
    assert poison_params({:a, :b, :c}) == {:a, :b, :c} 
  end

  test "poisoning two element tuple with Decimal gives two element tuple with PoisonedDecimal" do
    assert poison_params({:a, @decimal}) == {:a, @pdecimal} 
  end

  test "poisoning tuple with Decimal does not give tuple with PoisonedDecimal" do
    refute poison_params({@decimal}) == {@pdecimal} 
  end

  test "poisoning Decimal gives PoisonedDecimal" do
    assert poison_params(@decimal) == @pdecimal
  end

  test "poisoning PoisonedDecimal gives PoisonedDecimal" do
    assert poison_params(@pdecimal) == @pdecimal
  end

  test "poisoning map with Decimal gives map with PoisonedDecimal" do
    assert poison_params(%{d: @decimal}) == %{d: @pdecimal}
  end

  defmodule TestStruct do
    defstruct d: Decimal.new(0)
  end

  test "poisoning struct with Decimal gives struct with PoisonedDecimal" do
    assert poison_params(%TestStruct{d: @decimal}) == %TestStruct{d: @pdecimal}
  end 

  test "poisoning complicated map will give a proper poisoned map" do
    struct = %{
      a: @decimal,
      b: %{d: @decimal},
      c: %TestStruct{d: @decimal},
      d: @pdecimal,
      e: "decimal",
      f: :test,
      g: 1.643645,
      h: %{a: %{a: %{a: %{a: @decimal}, b: %TestStruct{d: @decimal}}}}
    }
    poisoned_struct = %{
      a: @pdecimal,
      b: %{d: @pdecimal},
      c: %TestStruct{d: @pdecimal},
      d: @pdecimal,
      e: "decimal",
      f: :test,
      g: 1.643645,
      h: %{a: %{a: %{a: %{a: @pdecimal}, b: %TestStruct{d: @pdecimal}}}}
    }
    assert poison_params(struct) == poisoned_struct
  end

end