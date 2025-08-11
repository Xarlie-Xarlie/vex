defmodule VideoProcessor.Config do
  @moduledoc """
  Configuration module for VideoProcessor.
  """

  @doc """
  Gets the temporary directory for HLS outputs.
  """
  @spec hls_temp_dir() :: String.t()
  def hls_temp_dir do
    Application.get_env(:video_processor, :hls_temp_dir, default_hls_temp_dir())
  end

  @doc """
  Gets the HLS segment duration in seconds.
  """
  @spec hls_segment_duration() :: integer()
  def hls_segment_duration do
    Application.get_env(:video_processor, :hls_segment_duration, 10)
  end

  defp default_hls_temp_dir do
    temp_dir = System.tmp_dir!()
    Path.join([temp_dir, "vex_hls_output"])
  end
end