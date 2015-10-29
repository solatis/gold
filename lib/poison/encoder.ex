defimpl Poison.Encoder, for: Decimal do
  @doc """
  Implements custom Decimal encoder that allows serialization of Decimal objects
  into JSON using Poison.
  """

  def encode(decimal, _options) do
    Decimal.to_string(decimal)
  end
end
