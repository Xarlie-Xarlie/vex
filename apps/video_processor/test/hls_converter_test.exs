defmodule VideoProcessor.HlsConverterTest do
  use ExUnit.Case
  
  alias VideoProcessor.HlsConverter

  describe "HlsConverter" do
    test "get_temp_hls_dir/0 returns a valid directory path" do
      temp_dir = HlsConverter.get_temp_hls_dir()
      
      assert is_binary(temp_dir)
      assert String.contains?(temp_dir, "vex_hls_output")
    end

    test "create_hls_output_dir/1 creates a unique directory" do
      filename = "test_video.mp4"
      
      output_dir1 = HlsConverter.create_hls_output_dir(filename)
      :timer.sleep(10) # Ensure different timestamp
      output_dir2 = HlsConverter.create_hls_output_dir(filename)
      
      assert output_dir1 != output_dir2
      assert File.exists?(output_dir1)
      assert File.exists?(output_dir2)
      assert String.contains?(output_dir1, "test_video")
      assert String.contains?(output_dir2, "test_video")
      
      # Cleanup
      File.rm_rf!(output_dir1)
      File.rm_rf!(output_dir2)
    end

    test "create_hls_output_dir/1 creates directory structure" do
      filename = "sample.mov"
      
      output_dir = HlsConverter.create_hls_output_dir(filename)
      
      assert File.exists?(output_dir)
      assert File.dir?(output_dir)
      
      # Cleanup
      File.rm_rf!(output_dir)
    end
  end
end