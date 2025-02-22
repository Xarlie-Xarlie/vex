defmodule StreamingWeb.Home do
  use StreamingWeb, :live_view

  alias Streaming.LoadBalancer
  alias StreamingWeb.Components.Home

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:upload_file_path, Path.expand("~/Vídeos/") <> "/")
     |> assign(:chunks, 1)
     |> assign(:progress, 0)
     |> assign(:uploading, false)
     |> assign(:file, nil)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Home.home uploading={@uploading} progress={@progress} />
    """
  end

  @impl Phoenix.LiveView
  def handle_event("upload_chunk", params, socket) do
    %{"chunk" => chunk, "file_name" => file_name, "chunks_qty" => chunks_qty} = params

    %{
      upload_file_path: upload_file_path,
      chunks: chunks,
      file: file
    } = socket.assigns

    binary_data = :erlang.list_to_binary(chunk)

    node = LoadBalancer.get_next_node()

    if is_nil(file) do
      :rpc.call(node, Elixir.GenServer, :cast, [
        Elixir.VideoProcessor.Saver,
        {:assign_file, %{file_name: upload_file_path <> file_name, total_chunks: chunks_qty}}
      ])
    end

    :rpc.call(node, Elixir.VideoProcessor.VideoProducer, :sync_notify, [
      %{file_name: upload_file_path <> file_name, current_chunk: chunks, chunk: binary_data}
    ])

    socket
    |> assign(file: upload_file_path <> file_name)
    |> assign(chunks: chunks + 1)
    |> assign(progress: chunks * 100 / chunks_qty)
    |> assign(uploading: true)
    |> push_event("request_next_chunk", %{})
    |> then(&{:noreply, &1})
  end

  @impl Phoenix.LiveView
  def handle_event("upload_complete", _, socket) do
    socket
    |> assign(progress: 0, chunks: 1, file: nil, uploading: false)
    |> put_flash(:info, "File uploaded!")
    |> then(&{:noreply, &1})
  end
end
