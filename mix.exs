defmodule GettextLLM.MixProject do
  use Mix.Project

  @version "0.1.0"

  @description "Elixir Gettext LLM based translation library"
  @repo_url "https://github.com/paulsabou/gettext_llm"

  def project do
    [
      app: :gettext_llm,
      version: @version,
      elixir: "~> 1.17",
      build_embedded: Mix.env() == :prod,
      deps: deps(),

      # Hex
      package: hex_package(),
      description: @description
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def hex_package do
    [
      maintainers: ["Paul Sabou"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @repo_url,
        "Changelog" => @repo_url <> "/blob/main/CHANGELOG.md"
      },
      files: ~w(lib mix.exs *.md)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:expo, "~> 1.1.0"},
      # Dev/test dependencies
      {:credo, "~> 1.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.35.1", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.17", only: [:test], runtime: false}
    ]
  end
end
