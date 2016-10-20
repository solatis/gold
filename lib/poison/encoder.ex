defimpl Poison.Encoder, for: PoisonedDecimal do
  def encode(term, _opts) do
    << Decimal.to_string(term.decimal, :normal)::binary >>
  end
end
