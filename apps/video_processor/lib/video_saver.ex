defmodule VideoProcessor.Saver do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast({:remove_processed_file, file_name}, state) do
    Map.drop(state, [file_name])
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_cast({:assign_file, %{file_name: file_name, total_chunks: total_chunks}}, state) do
    # File.open!(file_name)
    {:noreply,
     Map.put(state, file_name, %{total_chunks: total_chunks, next_chunk: 1, buffer: %{}})}
  end

  @impl true
  def handle_cast(
        {:save_chunk, %{chunk: chunk, file_name: file_name, current_chunk: current_chunk}},
        state
      ) do
    case Map.get(state, file_name) do
      nil ->
        state

      %{total_chunks: ^current_chunk, next_chunk: ^current_chunk, buffer: %{}} ->
        IO.binwrite(chunk)
        File.close(file_name)
        Map.drop(state, [file_name])

      %{next_chunk: ^current_chunk} ->
        save_chunk(chunk, file_name, state)

      %{next_chunk: next_chunk} when next_chunk !== current_chunk ->
        Map.update!(
          state,
          file_name,
          fn %{total_chunks: total_chunks, next_chunk: next_chunk, buffer: buffer} ->
            %{
              total_chunks: total_chunks,
              next_chunk: next_chunk,
              buffer: Map.put(buffer, current_chunk, chunk)
            }
          end
        )
    end
    |> then(&{:noreply, &1})
  end

  defp save_chunk(chunk, file_name, state) do
    IO.binwrite(file_name, chunk)
    Map.update!(state, file_name, &save_buffered(&1, file_name, chunk))
  end

  defp save_buffered(
         %{total_chunks: total_chunks, next_chunk: next_chunk, buffer: %{}},
         file_name,
         nil
       )
       when next_chunk > total_chunks do
    GenServer.cast(__MODULE__, {:remove_processed_file, file_name})
  end

  defp save_buffered(
         %{total_chunks: total_chunks, next_chunk: next_chunk, buffer: buffer},
         file_name,
         nil
       ) do
    case Map.get(buffer, next_chunk) do
      nil ->
        buffer
        |> then(&%{total_chunks: total_chunks, next_chunk: next_chunk, buffer: &1})

      data ->
        IO.binwrite(file_name, data)

        Map.drop(buffer, [next_chunk])
        |> then(&%{total_chunks: total_chunks, next_chunk: next_chunk + 1, buffer: &1})
        |> save_buffered(file_name, nil)
    end
  end

  defp save_buffered(
         %{total_chunks: total_chunks, next_chunk: next_chunk, buffer: buffer},
         file_name,
         chunk
       ) do
    case Map.get(buffer, next_chunk + 1) do
      nil ->
        Map.put(buffer, next_chunk + 1, chunk)
        |> then(&%{total_chunks: total_chunks, next_chunk: next_chunk + 1, buffer: &1})

      data ->
        IO.binwrite(file_name, data)

        Map.drop(buffer, [next_chunk + 1])
        |> then(&%{total_chunks: total_chunks, next_chunk: next_chunk + 2, buffer: &1})
    end
    |> save_buffered(file_name, nil)
  end
end
