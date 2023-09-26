# Scenic Driver Inky

A library to provide a Scenic framework driver implementation for the Inky series of eInk displays from Pimoroni. Built on top of the pappersverk/inky library. All in Elixir.

The Scenic UI framework is the easiest way to render text and geometries to your Inky through Elixir.

This driver only runs on RPi devices as far as we know as it is based on the scenic rpi driver generating a framebuffer we can use.

## Installation

The package can be installed
by adding `scenic_driver_inky` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scenic_driver_inky, "~> 1.0.0"}
  ]
end
```

## Usage

This library provides the `ScenicDriverInky` driver module. A solid usage example is provided in [pappersverk/sample_scenic_inky](https://github.com/pappersverk/sample_scenic_inky). It boils down to driver configuration:

```
# Example for two color inky devices
config :sample_scenic_inky, :viewport, %{
  name: :main_viewport,
  default_scene: {SampleScenicInky.Scene.Main, nil},
  size: {212, 104},
  opts: [scale: 1.0],
  drivers: [
    [
      module: Scenic.Driver.Local,
    ],
    [
      module: ScenicDriverInky,
      opts: [
        type: :phat,
        accent: :red,
        opts: %{
          border: :black
        }
        # dithering: :halftone
      ]
    ]
  ]
}

# Example for the Impression:
config :sample_scenic_inky, :viewport,
  name: :main_viewport,
  default_scene: {SampleScenicInky.Scene.Main, nil},
  size: {600, 448},
  opts: [scale: 1.0],
  drivers: [
    [
      module: Scenic.Driver.Local,
    ],
    [
      module: ScenicDriverInky,
      opts: [type: :impression, color_low: 120, dithering: false]
    ]
  ]
```

Note: It is important to configure the ScenicLocalDriver because ScenicDriverInky reads from ScenicLocalDriver

For development on host, we recommend just using the glfw driver for scenic (also shown in the sample). It won't give you that sweet lo-fi representation of the Inky though, so be mindful of accidentally using all those colors when you do.

## Troubleshooting

Ensure that you are also running the `Scenic.Driver.Local` (this is included in the examples above).
And ensure that `Scenic.Driver.Local` isn't running with `scaled: true, centered: true`. If it is
then the inky display will also end up offset because ScenicDriverInky is reading from the output of
`Scenic.Driver.Local` (via the framebuffer).

