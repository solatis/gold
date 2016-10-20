defmodule Gold.Mixfile do
  use Mix.Project

  def project do
    [app: :gold,
     version: "0.15.0",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     description: description,
     consolidate_protocols: Mix.env != :test
    ]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [{:decimal,   "~> 1.1"},
     {:httpoison, "~> 0.7"},
     {:poison, "~> 3.0"},
     {:earmark,   ">= 0.0.0", only: :dev},
     {:ex_doc,    ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    An Elixir library to interface with the Bitcoin core JSON-RPC API.
    """
  end

  defp package do
    [maintainers: ["Leon Mergen"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/solatis/gold"}]
  end
end
