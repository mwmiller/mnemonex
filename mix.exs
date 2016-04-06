defmodule Mnemonex.Mixfile do
  use Mix.Project

  def project do
    [app: :mnemonex,
     version: "0.0.2",
     elixir: "~> 1.2",
     name: "Mnemonex",
     source_url: "https://github.com/mwmiller/mnemonex",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger],
     mod: {Mnemonex, []}]
  end

  defp deps do
    [
      {:power_assert, "~> 0.0.8", only: :test},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, "~> 0.11.4", only: :dev},
    ]
  end

  defp description do
    """
    Mnemonex - a mnemonicode encoder/decoder
    """
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README*", "LICENSE*", ],
     maintainers: ["Matt Miller"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mwmiller/mnemonex",
             }
    ]
  end

end
