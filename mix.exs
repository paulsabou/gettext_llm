defmodule GettextLLM.MixProject do
  use Mix.Project

  @version "0.2.0"

  @description "Elixir Gettext LLM based translation library"
  @repo_url "https://github.com/paulsabou/gettext_llm"

  def project do
    [
      app: :gettext_llm,
      version: @version,
      elixir: "~> 1.17",
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      package: hex_package(),
      description: @description,

      # Docs
      name: "gettext_llm",
      docs: [
        source_ref: "v#{@version}",
        main: "GettextLLM",
        source_url: @repo_url
        # extras: ["CHANGELOG.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :telemetry]
    ]
  end

  def hex_package do
    [
      maintainers: ["Paul Sabou", "Adrian Codausi", "Goran Codausi"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @repo_url,
        "Changelog" => @repo_url <> "/blob/main/CHANGELOG.md"
      },
      files: ~w(lib mix.exs *.md)
    ]
  end

  defp deps do
    [
      # BEGIN --------------------------------- App core
      # Reading & writting PO files
      {:expo, "~> 1.1.0"},
      # For detecting the default locale to avoid unnecessary translation
      {:gettext, "~> 0.26.2"},
      # LLM API client & more
      {:langchain, "0.3.0-rc.0"},

      # END --------------------------------- App core

      # BEGIN --------------------------------- Developer Experience
      # Types annotations checks
      {:dialyxir, "~> 1.4", runtime: false},
      # Code style checker
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # Security checks
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      # Code documentation
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      # Deps security audits
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
      # END --------------------------------- Developer Experience
    ]
  end

  defp aliases do
    [
      test: ["test"],
      sobelow: ["sobelow --config .sobelow-conf"],
      prepare_commit: [
        "credo",
        "sobelow",
        "hex.audit",
        "deps.audit",
        "deps.unlock --check-unused",
        "format",
        "dialyzer"
      ]
    ]
  end
end
