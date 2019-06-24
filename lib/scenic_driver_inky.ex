defmodule ScenicDriverInky do
  use Scenic.ViewPort.Driver

  alias Scenic.ViewPort.Driver
  require Logger

  @dithering_options [:halftone, false]
  @color_affinity_options [:high, :low]

  @default_color_affinity :low
  @default_color_high 180
  @default_color_low 75
  @default_dithering false

  # This driver is not in a hurry, fetch a new FB once a second at most.
  # Refresh takes 10+ seconds, this is practically hectic.
  @default_refresh_rate 1000
  # Lower doesn't make much sense for Inky
  @minimal_refresh_rate 100

  @impl true
  def init(viewport, size, config) do
    vp_supervisor = vp_supervisor(viewport)
    {:ok, _} = Driver.start_link({vp_supervisor, size, %{module: Scenic.Driver.Nerves.Rpi}})

    type = config[:type]
    accent = config[:accent]

    dithering =
      cond do
        config[:dithering] in @dithering_options -> config[:dithering]
        true -> @default_dithering
      end

    interval =
      cond do
        is_integer(config[:interval]) and config[:interval] > 100 -> config[:interval]
        is_integer(config[:interval]) -> @minimal_refresh_rate
        true -> @default_refresh_rate
      end

    color_affinity =
      cond do
        config[:color_affinity] in @color_affinity_options -> config[:color_affinity]
        true -> @default_color_affinity
      end

    color_low =
      cond do
        is_integer(config[:color_low]) and config[:color_low] >= 0 -> config[:color_low]
        true -> @default_color_low
      end

    color_high =
      cond do
        is_integer(config[:color_high]) and config[:color_high] > color_low -> config[:color_high]
        true -> @default_color_high
      end

    {:ok, inky_pid} = Inky.start_link(%{type: type, accent: accent})

    {width, height} = size
    {:ok, cap} =
      RpiFbCapture.start_link(width: width, height: height, display: 0)

    send(self(), :capture)

    {:ok,
     %{
       viewport: viewport,
       size: size,
       inky_pid: inky_pid,
       inky_accent: accent,
       cap: cap,
       last_crc: -1,
       dithering: dithering,
       color_affinity: color_affinity,
       color_high: color_high,
       color_low: color_low,
       interval: interval
     }}
  end

  @impl true
  def handle_info(:capture, state) do
    {:ok, frame} = RpiFbCapture.capture(state.cap, :rgb24)

    crc = :erlang.crc32(frame.data)

    cond do
      crc != state.last_crc ->
        {width, _height} = state.size
        dithering = state.dithering

        color_high = state.color_high
        color_low = state.color_low
        color_affinity = state.color_affinity

        pixels = for <<r::8, g::8, b::8 <- frame.data>>, do: {r, g, b}

        {_, _, pixel_data} =
          Enum.reduce(pixels, {0, 0, %{}}, fn pixel, {x, y, pixel_data} ->
            {r, g, b} = pixel

            r = clamp_color(r, x, y, color_high, color_low, color_affinity, dithering)
            g = clamp_color(g, x, y, color_high, color_low, color_affinity, dithering)
            b = clamp_color(b, x, y, color_high, color_low, color_affinity, dithering)
            pixel = {r, g, b}

            color =
              case pixel do
                {0, 0, 0} -> :black
                {255, 255, 255} -> :white
                _ -> state.inky_accent
              end

            pixel_data = Map.put(pixel_data, {x, y}, color)

            {x, y} =
              if x >= width - 1 do
                {0, y + 1}
              else
                {x + 1, y}
              end

            {x, y, pixel_data}
          end)

        Inky.set_pixels(state.inky_pid, pixel_data)

      true ->
        nil
    end

    Process.send_after(self(), :capture, state.interval)
    {:noreply, %{state | last_crc: crc}}
  end

  defp clamp_color(color_value, x, y, color_high, color_low, color_affinity, dithering) do
    if color_value > color_high do
      255
    else
      if color_value < color_low do
        0
      else
        dither(dithering, color_affinity, x, y)
      end
    end
  end

  defp dither(false, color_affinity, _, _) do
    case color_affinity do
      :high -> 255
      :low -> 0
    end
  end

  defp dither(:halftone, _, x, y) do
    draw = 255
    blank = 0
    odd_x = rem(x, 2) == 0
    odd_y = rem(y, 2) == 0

    case odd_x do
      true ->
        case odd_y do
          true -> draw
          false -> blank
        end

      false ->
        case odd_y do
          true -> blank
          false -> draw
        end
    end
  end

  defp vp_supervisor(viewport) do
    [supervisor_pid | _] =
      viewport
      |> Process.info()
      |> get_in([:dictionary, :"$ancestors"])

    supervisor_pid
  end
end
