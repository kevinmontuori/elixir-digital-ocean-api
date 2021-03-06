defmodule DigitalOceanApi.Mixfile do
  use Mix.Project

  def project do
    [ app: :digital_ocean_api,
      version: "0.0.1",
      elixir: "~> 0.12.4",
      compile_path: "ebin",
      deps: deps ]
  end

  def application do
    [ registered: [:digoc],
      mod: { DigOc.App, [] }
    ]
  end

  defp deps do
    [
     { :httpotion, github: "myfreeweb/httpotion"},
     { :json, github: "cblage/elixir-json"},
    ]
  end
end
