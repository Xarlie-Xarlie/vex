defmodule VideoProcessor.VideoConsumer do
  use GenStage

  alias VideoProcessor.Saver

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:consumer, :ok, subscribe_to: [{VideoProcessor.VideoProducer, max_demand: 1}]}
  end

  def handle_events(events, _from, state) do
    # Wait for a second.
    Process.sleep(1000)

    # Inspect the events.
    IO.inspect(events)

    Enum.map(events, fn event ->
      IO.puts("sending event: ")
      IO.inspect(event)

      GenServer.cast(Saver, {:save_chunk, event})

      Node.list()
      |> Enum.map(
        &:rpc.call(&1, GenServer, :cast, [{VideoProcessor.Saver, {:save_chunk, event}}])
      )
    end)

    {:noreply, [], state}
  end
end
