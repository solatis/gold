defmodule PoisonedDecimal do

  defstruct [:decimal]

  def new(decimal = %Decimal{}) do
    %PoisonedDecimal{decimal: decimal}
  end

  def poison_params(params) do
    params |> Enum.map(&poison_param/1)
  end

  defp poison_param(decimal = %Decimal{}) do
    PoisonedDecimal.new(decimal)
  end
  defp poison_param(param), do: param

end