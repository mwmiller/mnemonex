defmodule Mnemonex.MixProject do
  use Mix.Project

  def project do
    [
      app: :mnemonex,
      version: "1.2.4",
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
    [
      extra_applications: [:logger]
    ]
  end

  def deps do
    [
      {:the_fuzz, "~> 0.5"},
      {:ex_doc, "~> 0.23", only: :dev}
    ]
  end

  def description do
    """
    mnemonicode encoder/decoder
    """
  end

  def package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Matt Miller"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mwmiller/mnemonex"}
    ]
  end
end
