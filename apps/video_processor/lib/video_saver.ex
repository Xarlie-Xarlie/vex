defmodule VideoProcessor.Saver do
  use GenServer

  alias VideoProcessor.HlsConverter

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:log, from, state) do
    GenServer.reply(from, state)
    {:reply, [], state}
  end

  @impl true
  def handle_cast({:remove_processed_file, file_name}, state) do
    File.close(file_name)
    
    # Start HLS conversion for the completed file
    spawn(fn ->
      case HlsConverter.convert_to_hls(file_name, HlsConverter.create_hls_output_dir(file_name)) do
        :ok ->
          IO.puts("HLS conversion completed for #{file_name}")
        {:error, reason} ->
          IO.puts("HLS conversion failed for #{file_name}: #{inspect(reason)}")
      end
    end)

    Map.drop(state, [file_name])
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_cast({:assign_file, %{file_name: file_name, total_chunks: total_chunks}}, state) do
    File.rm(file_name)
    file = File.open!(file_name, [:binary, :append])

    {:noreply,
     Map.put(state, file_name, %{
       total_chunks: total_chunks,
       next_chunk: 1,
       buffer: %{},
       file: file
     })}
  end

  @impl true
  def handle_cast(
        {:save_chunk, %{chunk: chunk, file_name: file_name, current_chunk: current_chunk}},
        state
      ) do
    case Map.get(state, file_name) do
      nil ->
        state

      %{total_chunks: ^current_chunk, next_chunk: ^current_chunk, buffer: %{}, file: file} ->
        IO.binwrite(file, chunk)
        File.close(file)
        
        # Convert the completed file to HLS
        spawn(fn ->
          case HlsConverter.convert_to_hls(file_name, HlsConverter.create_hls_output_dir(file_name)) do
            :ok ->
              IO.puts("HLS conversion completed for #{file_name}")
            {:error, reason} ->
              IO.puts("HLS conversion failed for #{file_name}: #{inspect(reason)}")
          end
        end)
        
        Map.drop(state, [file_name])

      %{next_chunk: ^current_chunk, file: file} ->
        IO.binwrite(file, chunk)
        Map.update!(state, file_name, &save_buffered(&1, file_name))

      %{next_chunk: next_chunk} when next_chunk !== current_chunk ->
        Map.update!(
          state,
          file_name,
          fn file_info ->
            %{file_info | buffer: Map.put(file_info.buffer, current_chunk, chunk)}
          end
        )
    end
    |> then(&{:noreply, &1})
  end

  defp save_buffered(
         %{total_chunks: total_chunks, next_chunk: next_chunk, buffer: %{}},
         file_name
       )
       when next_chunk > total_chunks do
    GenServer.cast(__MODULE__, {:remove_processed_file, file_name})
  end

  defp save_buffered(%{next_chunk: next_chunk, buffer: buffer, file: file} = file_info, file_name) do
    case Map.get(buffer, next_chunk) do
      nil ->
        %{file_info | next_chunk: next_chunk + 1}

      data ->
        IO.binwrite(file, data)

        Map.drop(buffer, [next_chunk])
        |> then(&%{file_info | next_chunk: next_chunk + 1, buffer: &1})
        |> save_buffered(file_name)
    end
  end
end
