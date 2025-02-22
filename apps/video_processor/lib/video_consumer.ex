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
    Enum.map(events, fn event ->
      IO.puts("processing #{event.file_name}, #{event.current_chunk} in #{inspect(self())}")
      # simulate processing
      Process.sleep(1000)
      GenServer.cast(Saver, {:save_chunk, event})

      Node.list()
      |> Enum.reject(&(&1 === :streaming_node_1@localhost))
      |> Enum.map(
        &:rpc.call(&1, Elixir.GenServer, :cast, [
          Elixir.VideoProcessor.Saver,
          {:save_chunk, event}
        ])
      )
      |> IO.inspect()
    end)

    {:noreply, [], state}
  end
end
