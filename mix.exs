defmodule Mnemonex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mnemonex,
      version: "1.2.2",
      elixir: "~> 1.7",
      name: "Mnemonex",
      source_url: "https://github.com/mwmiller/mnemonex",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger], mod: {Mnemonex, []}]
  end

  defp deps do
    [
      {:the_fuzz, "~> 0.5"},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.16", only: :dev},
      {:credo, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp description do
    """
    mnemonicode encoder/decoder
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Matt Miller"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mwmiller/mnemonex"}
    ]
  end
end
