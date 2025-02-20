defmodule Streaming.Repo.Migrations.CreateVideosSegments do
  use Ecto.Migration

  def change do
    create table(:videos_segments) do
      add :total_chunks, :integer
      add :last_saved_segments, :integer
      add :filename, :string

      timestamps(type: :utc_datetime)
    end
  end
end
