defmodule OffBroadwayKafka.MixProject do
  use Mix.Project

  @github "https://github.com/UrbanOS-Public/off_broadway_kafka"

  def project do
    [
      app: :off_broadway_kafka_pipeline,
      version: "2.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @github,
      homepage_url: @github,
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env()),
      dialyzer: [plt_file: {:no_warn, ".plt/dialyzer.plt"}]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elsa_kafka, "~> 2.0"},
      {:broadway, "~> 1.0"},
      {:retry, "~> 0.15"},
      {:mock, "~> 0.3", only: [:dev, :test, :integration]},
      {:checkov, "~> 1.0", only: [:dev, :test, :integration]},
      {:divo, "~> 2.0", only: [:dev, :integration]},
      {:divo_kafka, "~> 1.0", only: [:dev, :integration]},
      {:patiently, "~> 0.2", only: [:test, :integration], override: true},
      {:ex_doc, "~> 0.21", only: [:dev], runtime: false},
      {:benchee, "~> 1.0", only: [:integration]},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Smartcitiesdata"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @github}
    ]
  end

  defp docs do
    [
      source_url: @github,
      extras: ["README.md"],
      # api_reference: false,
      source_url_pattern: "#{@github}/blob/master/%{path}#L%{line}"
    ]
  end

  defp description do
    "Implementation of Broadway that supports a Kafka producer"
  end

  defp elixirc_paths(env) when env in [:test, :integration], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(_), do: ["test/unit"]
end
