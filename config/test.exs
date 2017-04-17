use Mix.Config

config :gold, :regtest, [
  hostname: "localhost",
  port: 8332,
  user: "bitcoinrpc",
  password: "changeme"
]

config :logger, level: :warn
