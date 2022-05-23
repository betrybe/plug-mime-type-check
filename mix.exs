defmodule PlugMimeTypeCheck.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :plug_mime_type_check,
      version: "0.1.3",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Plug Mime Type Check",
      source_url: "https://github.com/betrybe/plug-mime-type-check",
      description: description(),
      package: package()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp description() do
    "A Plug that checks the mime type of a uploaded file trough API request"
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/betrybe/plug-mime-type-check"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.3"},
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.28.4", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
