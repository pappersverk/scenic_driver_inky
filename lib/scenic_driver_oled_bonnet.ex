defmodule ScenicDriverOLEDBonnet do
  use Scenic.ViewPort.Driver

  alias Scenic.ViewPort.Driver
  require Logger

  @gpio_config [
    # Joystick press
    %{
      pin: 4,
      pull_mode: :pullup,
      low: {:key, {" ", :press, 0}},
      high: {:key, {" ", :release, 0}}
    },
    # Joystick up
    %{
      pin: 17,
      pull_mode: :pullup,
      low: {:key, {"up", :press, 0}},
      high: {:key, {"up", :release, 0}}
    },
    # Joystick right
    %{
      pin: 23,
      pull_mode: :pullup,
      low: {:key, {"right", :press, 0}},
      high: {:key, {"right", :release, 0}}
    },
    # Joystick down
    %{
      pin: 22,
      pull_mode: :pullup,
      low: {:key, {"down", :press, 0}},
      high: {:key, {"down", :release, 0}}
    },
    # Joystick left
    %{
      pin: 27,
      pull_mode: :pullup,
      low: {:key, {"left", :press, 0}},
      high: {:key, {"left", :release, 0}}
    },
    # #5
    %{
      pin: 5,
      pull_mode: :pullup,
      low: {:key, {"A", :press, 0}},
      high: {:key, {"A", :release, 0}}
    },
    # #6
    %{
      pin: 6,
      pull_mode: :pullup,
      low: {:key, {"S", :press, 0}},
      high: {:key, {"S", :release, 0}}
    }
  ]

  @impl true
  def init(viewport, size, _config) do
    vp_supervisor = vp_supervisor(viewport)
    {:ok, _} = Driver.start_link({vp_supervisor, size, %{module: Scenic.Driver.Nerves.Rpi}})

    {:ok, _} =
      Driver.start_link({vp_supervisor, size, %{module: ScenicDriverGPIO, opts: @gpio_config}})

    {:ok, i2c} = Circuits.I2C.open("i2c-1")
    {:ok, cap} = RpiFbCapture.start_link(width: 128, height: 64, display: 0)

    SSD1306.init(i2c)
    send(self(), :capture)

    {:ok,
     %{
       viewport: viewport,
       i2c: i2c,
       cap: cap,
       last_crc: -1
     }}
  end

  @impl true
  def handle_info(:capture, state) do
    {:ok, frame} = RpiFbCapture.capture(state.cap, :mono_column_scan)

    crc = :erlang.crc32(frame.data)

    if crc != state.last_crc do
      SSD1306.display(state.i2c, frame.data)
    end

    Process.send_after(self(), :capture, 50)
    {:noreply, %{state | last_crc: crc}}
  end

  defp vp_supervisor(viewport) do
    [supervisor_pid | _] =
      viewport
      |> Process.info()
      |> get_in([:dictionary, :"$ancestors"])

    supervisor_pid
  end
end
