defmodule VideoProcessor.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {VideoProcessor.VideoProducer, :ok},
      {VideoProcessor.Saver, %{}},
      Supervisor.child_spec({VideoProcessor.VideoConsumer, []}, id: :c1),
      Supervisor.child_spec({VideoProcessor.VideoConsumer, []}, id: :c2),
      Supervisor.child_spec({VideoProcessor.VideoConsumer, []}, id: :c3),
      Supervisor.child_spec({VideoProcessor.VideoConsumer, []}, id: :c4)
    ]

    opts = [strategy: :one_for_one, name: VideoProcessor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
