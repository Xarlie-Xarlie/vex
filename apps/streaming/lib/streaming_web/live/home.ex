defmodule StreamingWeb.Home do
  use StreamingWeb, :live_view

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
    <.render_input_video uploading={@uploading} />
    <.render_progress progress={@progress} />
    """
  end

  defp render_input_video(assigns) do
    ~H"""
    <form class="flex items-center justify-center">
      <label
        id="fileupload"
        for="dropzone-file"
        class="flex flex-col items-center justify-center
        w-full h-64 border-2
        border-gray-300 border-dashed rounded-lg
        cursor-pointer bg-gray-50 dark:hover:bg-gray-800
        dark:bg-gray-700 hover:bg-gray-100 dark:border-gray-600
        dark:hover:border-gray-500 dark:hover:bg-gray-600"
      >
        <div class="flex flex-col items-center justify-center pt-5 pb-6">
          <svg
            class="w-8 h-8 mb-4 text-gray-500 dark:text-gray-400"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 20 16"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 13h3a3 3 
              0 0 0 
              0-6h-.025A5.56 5.56 0 
              0 0 16 
              6.5 5.5 5.5 
              0 0 0 
              5.207 5.021C5.137 5.017 
              5.071 5 5 
              5a4 4 0 
              0 0 0 
              8h2.167M10 15V6m0 0L8 
              8m2-2 2 2"
            />
          </svg>
          <p class="mb-2 text-sm text-gray-500 dark:text-gray-400">
            <span class="font-semibold">Click to upload</span> or drag and drop
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            SVG, PNG, JPG or GIF (MAX. 800x400px)
          </p>
        </div>
        <input
          id="dropzone-file"
          name="video"
          phx-hook="FileUpload"
          disabled={@uploading}
          type="file"
          class="hidden"
        />
      </label>
    </form>
    """
  end

  defp render_progress(assigns) do
    ~H"""
    <div :if={@progress !== 0}>
      <div class="flex justify-between mb-1">
        <span class="text-base font-medium text-blue-700">Flowbite</span>
        <span class="text-sm font-medium text-blue-700">{floor(@progress)}%</span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700">
        <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{@progress}%"}></div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("upload_chunk", params, socket) do
    %{"chunk" => chunk, "file_name" => file_name, "chunks_qty" => chunks_qty} = params

    %{
      upload_file_path: upload_file_path,
      chunks: chunks,
      file: file
    } = socket.assigns

    file =
      if is_nil(file),
        do: File.open!(upload_file_path <> file_name, [:binary, :append]),
        else: file

    binary_data = :erlang.list_to_binary(chunk)

    IO.binwrite(file, binary_data)

    socket
    |> assign(file: file)
    |> assign(chunks: chunks + 1)
    |> assign(progress: chunks * 100 / chunks_qty)
    |> assign(uploading: true)
    |> push_event("request_next_chunk", %{})
    |> then(&{:noreply, &1})
  end

  @impl Phoenix.LiveView
  def handle_event("upload_complete", _, %{assigns: %{file: file}} = socket) do
    File.close(file)

    socket
    |> assign(progress: 0, chunks: 1, file: nil, uploading: false)
    |> put_flash(:info, "File uploaded!")
    |> then(&{:noreply, &1})
  end

  @impl Phoenix.LiveView
  def handle_event("next_chunk", _params, socket) do
    {:noreply, push_event(socket, "request_next_chunk", %{})}
  end
end
