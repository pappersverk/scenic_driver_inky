defmodule ScenicDriverInky.MixProject do
  use Mix.Project

  def project do
    [
      app: :scenic_driver_inky,
      version: "0.1.0",
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.9"},
      {:scenic_driver_nerves_rpi, "~> 0.9"},
      {:rpi_fb_capture, "~> 0.1"},
      {:inky, path: "../inky"}
    ]
  end

  defp description do
    "Pimoroni Inky driver for Scenic"
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/lawik/scenic_driver_inky"}
    }
  end
end
