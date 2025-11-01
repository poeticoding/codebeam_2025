defmodule YoloTrack.MixProject do
  use Mix.Project

  def project do
    [
      app: :yolo_track,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {YoloTrack, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.11.0"},
      {:scenic_driver_local, "~> 0.11.0"},
      {:phoenix_pubsub, "~> 2.2"},

      {:nx, "~> 0.10"},
      {:exla, "~> 0.10"},
      {:evision, "~> 0.2.14"},
      {:yolo, path: "../yolo_elixir"}
    ]
  end
end
