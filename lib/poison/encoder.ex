defimpl Poison.Encoder, for: PoisonedDecimal do
  @doc """
  Hacky way of JSON encoding Decimals for bitcoind
  """
  def encode(term, _opts) do
    << Decimal.to_string(term.decimal, :normal)::binary >>
  end
end
