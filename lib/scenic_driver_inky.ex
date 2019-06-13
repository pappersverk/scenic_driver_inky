defmodule ScenicDriverInky do
  use Scenic.ViewPort.Driver

  alias Scenic.ViewPort.Driver
  require Logger

  @impl true
  def init(viewport, size, _config) do
    vp_supervisor = vp_supervisor(viewport)
    {:ok, _} = Driver.start_link({vp_supervisor, size, %{module: Scenic.Driver.Nerves.Rpi}})

    inky = Inky.init(:phat, :red)

    {:ok, cap} =
      RpiFbCapture.start_link(width: inky.display.width, height: inky.display.height, display: 0)

    send(self(), :capture)

    {:ok,
     %{
       viewport: viewport,
       inky: inky,
       cap: cap,
       last_crc: -1
     }}
  end

  @impl true
  def handle_info(:capture, state) do
    {:ok, frame} = RpiFbCapture.capture(state.cap, :rgb24)

    crc = :erlang.crc32(frame.data)

    inky =
      cond do
        crc != state.last_crc ->
          pixels = for <<r::8, g::8, b::8 <- frame.data>>, do: {r, g, b}

          inky = state.inky

          tolerance = 50

          {_, _, inky} =
            Enum.reduce(pixels, {0, 0, inky}, fn pixel, {x, y, inky} ->
              {r, g, b} = pixel

              r = if r > tolerance, do: 255, else: 0
              g = if g > tolerance, do: 255, else: 0
              b = if b > tolerance, do: 255, else: 0
              pixel = {r, g, b}

              color =
                case pixel do
                  {0, 0, 0} -> :black
                  {255, 255, 255} -> :white
                  _ -> inky.display.accent
                end

              inky = Inky.set_pixel(inky, x, y, color)

              {x, y} =
                if x >= 211 do
                  {0, y + 1}
                else
                  {x + 1, y}
                end

              {x, y, inky}
            end)

          Inky.show(inky)

        true ->
          state.inky
      end

    # This driver is not in a hurry, fetch a new FB once a second at most.
    # Refresh takes 10+ seconds, this is practically hectic.
    Process.send_after(self(), :capture, 1000)
    {:noreply, %{state | last_crc: crc, inky: inky}}
  end

  defp vp_supervisor(viewport) do
    [supervisor_pid | _] =
      viewport
      |> Process.info()
      |> get_in([:dictionary, :"$ancestors"])

    supervisor_pid
  end
end
