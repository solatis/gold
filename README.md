# Gold

Opinionated interface to Bitcoin core JSON-RPC API.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add gold to your list of dependencies in `mix.exs`:

        def deps do
          [{:gold, "~> 0.0.1"}]
        end

  2. Ensure gold is started before your application:

        def application do
          [applications: [:gold]]
        end
