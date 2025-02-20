defmodule Streaming.VideoSegments do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Ecto.Schema
  alias Streaming.Repo

  @type t :: %__MODULE__{}

  schema "videos_segments" do
    field :total_chunks, :integer
    field :last_saved_segments, :integer
    field :filename, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for incrementing the `last_saved_segments` field.

  ## Examples

      iex> video_segment = %Streaming.VideoSegments{last_saved_segments: 1}
      iex> changeset = Streaming.VideoSegments.changeset(video_segment)
      iex> changeset.changes.last_saved_segments
      2

      iex> attrs = %{total_chunks: 10, last_saved_segments: 0, filename: "video.mp4"}
      iex> changeset = Streaming.VideoSegments.changeset(attrs)
      iex> changeset.valid?
      true

  """
  @spec changeset(t() | map()) :: Changeset.t()
  def changeset(%__MODULE__{last_saved_segments: last_saved_segments} = video_segments) do
    video_segments
    |> change(last_saved_segments: last_saved_segments + 1)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:total_chunks, :last_saved_segments, :filename])
    |> validate_required([:total_chunks, :last_saved_segments, :filename])
  end

  @doc """
  Creates a video segment in the database.

  ## Examples

      iex> attrs = %{total_chunks: 10, last_saved_segments: 0, filename: "video.mp4"}
      iex> video_segment = Streaming.VideoSegments.create_video_segment(attrs)
      iex> video_segment.total_chunks
      10

  """
  @spec create_video_segment(map()) :: Schema.t()
  def create_video_segment(attrs) do
    changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Increments the `last_saved_segments` field of a video segment in the database.

  ## Examples

      iex> video_segment = Repo.insert!(%Streaming.VideoSegments{total_chunks: 10, last_saved_segments: 0, filename: "video.mp4"})
      iex> updated_segment = Streaming.VideoSegments.increment_segment(video_segment.id)
      iex> updated_segment.last_saved_segments
      1

  """
  @spec increment_segment(integer()) :: Schema.t()
  def increment_segment(id) do
    Repo.get!(__MODULE__, id)
    |> changeset()
    |> Repo.update!()
  end
end
