defmodule Gold.Mixfile do
  use Mix.Project

  def project do
    [app: :gold,
     version: "0.16.3",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: description(),
     consolidate_protocols: Mix.env != :test,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test, "coveralls.travis": :test, "coveralls.html": :test]
    ]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [{:decimal,   "~> 1.1 or ~> 2.0"},
     {:httpoison, "~> 0.7"},
     {:poison, "~> 3.0 or ~> 2.0"},
     {:earmark,   ">= 0.0.0", only: :dev},
     {:ex_doc,    ">= 0.0.0", only: :dev},
     {:excoveralls, "~> 0.6", only: :test}
    ]
  end

  defp description do
    """
    An Elixir library to interface with the Bitcoin core JSON-RPC API.
    """
  end

  defp package do
    [maintainers: ["Leon Mergen", "Bartosz Kalinowski"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/solatis/gold"}]
  end
end
