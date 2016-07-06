defmodule Gold.Mixfile do
  use Mix.Project

  def project do
    [app: :gold,
     version: "0.12.0",
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
     {:poison,    "~> 1.5"},
     
     {:earmark,   "~> 0.1",  only: :dev},
     {:ex_doc,    "~> 0.10", only: :dev},
     {:ecto,      "~> 2.0"}, # a hack...
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
