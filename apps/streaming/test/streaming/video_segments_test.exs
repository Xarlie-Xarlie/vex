defmodule Streaming.VideoSegmentsTest do
  use ExUnit.Case, async: true
  use Streaming.DataCase

  alias Streaming.VideoSegments
  alias Streaming.Repo
  doctest VideoSegments

  describe "changeset/1" do
    test "increments last_saved_segments" do
      video_segment = %VideoSegments{last_saved_segments: 1}
      changeset = VideoSegments.changeset(video_segment)

      assert changeset.changes.last_saved_segments == 2
    end

    test "creates a valid changeset from attributes" do
      attrs = %{total_chunks: 10, last_saved_segments: 0, filename: "video.mp4"}
      changeset = VideoSegments.changeset(attrs)

      assert changeset.valid?
    end

    test "requires total_chunks, last_saved_segments, and filename" do
      changeset = VideoSegments.changeset(%{})

      refute changeset.valid?

      assert %{
               total_chunks: ["can't be blank"],
               last_saved_segments: ["can't be blank"],
               filename: ["can't be blank"]
             } = errors_on(changeset)
    end
  end

  describe "create_video_segment/1" do
    test "creates a video segment in the database" do
      attrs = %{total_chunks: 10, last_saved_segments: 0, filename: "video.mp4"}
      video_segment = VideoSegments.create_video_segment(attrs)

      assert video_segment.id
      assert video_segment.total_chunks == 10
      assert video_segment.last_saved_segments == 0
      assert video_segment.filename == "video.mp4"
    end
  end

  describe "increment_segment/1" do
    test "increments the last_saved_segments field" do
      video_segment =
        Repo.insert!(%VideoSegments{
          total_chunks: 10,
          last_saved_segments: 0,
          filename: "video.mp4"
        })

      updated_segment = VideoSegments.increment_segment(video_segment.id)

      assert updated_segment.last_saved_segments == 1
    end
  end
end
