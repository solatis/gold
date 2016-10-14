defmodule Gold.Mixfile do
  use Mix.Project

  def project do
    [app: :gold,
     version: "0.13.0",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     description: description]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [{:decimal,   "~> 1.1"},
     {:httpoison, "~> 0.7"},
     {:json, "~> 1.0"},
     {:earmark,   ">= 0.0.0"},
     {:ex_doc,    "~> 0.14"}
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
