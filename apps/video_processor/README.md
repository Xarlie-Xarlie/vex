# VideoProcessor

Video processing application that handles video chunk reconstruction and HLS conversion.

## Features

- **Chunk Processing**: Processes video chunks received from streaming app
- **File Reconstruction**: Reconstructs complete video files from chunks
- **HLS Conversion**: Converts video files to HLS format for streaming
- **GenStage Pipeline**: Uses producer/consumer pattern for scalable processing

## Architecture

- **VideoProducer**: Receives and broadcasts video chunk events
- **VideoConsumer**: Processes chunks and manages workflow
- **VideoSaver**: Reconstructs files and triggers HLS conversion
- **HlsConverter**: Converts videos to HLS format using Membrane framework

## HLS Output

Video files are automatically converted to HLS format with:
- Playlist file (`playlist.m3u8`)
- Video segments (`.ts` files)
- Configurable segment duration
- Unique output directories in temp folder

## Configuration

```elixir
config :video_processor,
  hls_temp_dir: "/custom/hls/output",
  hls_segment_duration: 10
```

## Dependencies

Core dependencies:
- `gen_stage`: For producer/consumer pipeline
- `membrane_core`: Video processing framework
- `membrane_hls_plugin`: HLS conversion support

See [HLS_IMPLEMENTATION.md](HLS_IMPLEMENTATION.md) for detailed implementation notes.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `video_processor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:video_processor, "~> 0.1.0"}
  ]
end
```

