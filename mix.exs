defmodule ScenicDriverOLEDBonnet.MixProject do
  use Mix.Project

  def project do
    [
      app: :scenic_driver_oled_bonnet,
      version: "0.1.0",
      elixir: "~> 1.8",
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
      {:scenic_driver_gpio, "~> 0.1"},
      {:scenic_driver_nerves_rpi, "~> 0.9"},
      {:ssd1306, "~> 0.1", github: "nerves-training/ssd1306"},
      {:rpi_fb_capture, "~> 0.1"}
    ]
  end
end
