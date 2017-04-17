# Gold

[![Build Status](https://travis-ci.org/kelostrada/gold.svg?branch=master)](https://travis-ci.org/kelostrada/gold)

Opinionated interface to Bitcoin core JSON-RPC API. Currently in MVP mode: architecture is ready and stable, doesn't fully implement all of the RPC commands yet, although this would be trivial to do. Open an issue (or better yet, create a pull request) if you want to see more functionality added.

Documentation: http://hexdocs.pm/gold/

## Usage

Add Gold as a dependency in your `mix.exs` file.

```elixir
def deps do
  [ { :gold, "~> 0.13" } ]
end
```

You will also need to configure your application to connect to the
correct node

```elixir
config :gold, :my_node, [
  hostname: "localhost",
  port: 8332,
  user: "bitcoinrpc",
  password: "changeme"
]
```

After you are done, run `mix deps.get` in your shell to fetch and compile Gold. Start an interactive Elixir shell with `iex -S mix`.

```iex
iex> Gold.getbalance!(:my_node)
#Decimal<9074.99999583>
iex> Gold.listtransactions!(:my_node)
[%Gold.Transaction{account: "", address: "mvZZq9C8ZiK85fLPL26N7n81D5jKu8SgcD",
  amount: #Decimal<12.50000226>,
  blockhash: "7e5ca54602567bec3fa7067344ae0916236e01d2c9f6cae80509b291f97edf0f",
  blockindex: 0, category: :immature, comment: nil, confirmations: 3, fee: nil,
  otheraccount: nil, time: 1442466804, timereceived: 1442466804,
  txid: "6c173c5b90bc0c565e15d0144d57e81ec9ce95aac86f0e77c354d7acf1fbf68b",
  vout: 0}]
```

## Testing

You need bitcoind in regtest mode to run tests. To get it go to: https://bitcoin.org/en/download.

After you are done installing you need to copy `bitcoin.conf` file to you `.bitcoin` directory (or just run bitcoind with proper parameters). You also have to start it with args: `-regtest -daemon`.

When you are done setting everything up you can run tests with `mix test`

## Features

  * Uses the [Decimal](https://github.com/ericmj/decimal) library for representing BTC amounts, to avoid loss of precision;
  * Directly maps [Bitcoin's RPC functions](https://bitcoin.org/en/developer-reference#rpcs);
