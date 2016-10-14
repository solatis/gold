defimpl JSON.Encoder, for: Decimal do
  def encode(term) do
    << Decimal.to_string(term)::binary >>
  end

  def typeof(_term), do: :decimal
end