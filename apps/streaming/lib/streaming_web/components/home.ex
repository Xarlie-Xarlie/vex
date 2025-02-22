defmodule StreamingWeb.Components.Home do
  use Phoenix.Component

  embed_templates "home/*"

  def home(assigns) do
    ~H"""
    <.video_input uploading={@uploading} />
    <.progress_video_input progress={@progress} />
    """
  end
end
