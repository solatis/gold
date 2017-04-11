use Mix.Config

config :gold, :regtest, [
  hostname: "localhost",
  port: 18332,
  user: "bitcoinrpc",
  password: "changeme"
]

config :logger, level: :warn
