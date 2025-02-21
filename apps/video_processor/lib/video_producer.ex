defmodule VideoProcessor.VideoProducer do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, %{}}
  end

  def handle_cast(
        {:process_chunk, %{chunk: chunk, file_name: file_name, current_chunk: current_chunk}},
        state
      ) do
    {:noreply, [%{chunk: chunk, file_name: file_name, current_chunk: current_chunk} | state]}
  end

  def handle_demand(demand, state) when demand > 0 do
    {:noreply, state, []}
  end
end
