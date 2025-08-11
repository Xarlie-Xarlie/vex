# HLS Video Processing Implementation

This document explains the implementation of the HLS (HTTP Live Streaming) video processing module for the VEX project.

## Overview

The implementation adds HLS conversion capability to the existing video processor app, allowing video chunks uploaded through the streaming app to be converted into HLS format for streaming.

## Architecture

### Current Flow
1. **Streaming App**: User uploads video file in chunks via LiveView
2. **Video Processor**: Receives chunks via RPC calls, processes them through GenStage pipeline
3. **Video Saver**: Reconstructs complete video files from chunks

### New HLS Flow
1. **Streaming App**: User uploads video file in chunks via LiveView (unchanged)
2. **Video Processor**: Receives chunks via RPC calls (unchanged)
3. **Video Saver**: Reconstructs complete video files AND triggers HLS conversion
4. **HLS Converter**: Converts complete video files to HLS format
5. **HLS Output**: Creates playlist.m3u8 and segment files in temp directory

## Implementation Details

### New Modules

#### 1. VideoProcessor.Config (`lib/config.ex`)
- Centralized configuration for video processing
- Configurable HLS temp directory and segment duration
- Uses Application environment or sensible defaults

#### 2. VideoProcessor.HlsConverter (`lib/hls_converter.ex`)
- Main interface for HLS conversion
- Handles dependency checking for Membrane framework
- Creates unique output directories for each conversion
- Provides mock implementation when dependencies unavailable

#### 3. VideoProcessor.HlsPipeline (`lib/hls_pipeline.ex`)
- Contains the actual Membrane pipeline implementation
- Uses Membrane.File.Source and Membrane.HLS.SinkBin
- Ready to be enabled when dependencies are available

### Modified Modules

#### VideoProcessor.Saver (`lib/video_saver.ex`)
- Added HLS conversion trigger when file processing completes
- Spawns async processes for HLS conversion to avoid blocking
- Maintains existing chunk reconstruction functionality

### Dependencies Added

```elixir
{:membrane_core, "~> 1.0"},
{:membrane_file_plugin, "~> 0.17.0"},
{:membrane_ffmpeg_swresample_plugin, "~> 0.20.0"},
{:membrane_hls_plugin, "~> 0.8.0"}
```

## Configuration

### Application Environment
```elixir
config :video_processor,
  hls_temp_dir: "/custom/hls/output",
  hls_segment_duration: 10
```

### Default Configuration
- **HLS Temp Directory**: `System.tmp_dir!/vex_hls_output`
- **Segment Duration**: 10 seconds
- **Playlist Name**: `playlist.m3u8`
- **Segment Template**: `segment_%05d.ts`

## Usage

### Automatic Processing
When a video file upload completes through the existing chunk upload mechanism, HLS conversion is automatically triggered:

1. User uploads video chunks via streaming app
2. VideoSaver reconstructs the complete file
3. HLS conversion starts automatically in background
4. HLS files are created in unique temp directory

### Manual Processing
```elixir
# Convert a video file to HLS
VideoProcessor.HlsConverter.convert_to_hls(
  "/path/to/video.mp4",
  "/output/directory"
)

# Create unique output directory
output_dir = VideoProcessor.HlsConverter.create_hls_output_dir("video.mp4")
```

## Output Structure

For each converted video, a directory is created with:
```
/tmp/vex_hls_output/video_1234567890/
├── playlist.m3u8          # HLS playlist file
├── segment_00000.ts       # Video segments
├── segment_00001.ts
└── ...
```

## Error Handling

- Graceful degradation when Membrane dependencies unavailable
- Mock implementation for development/testing
- Async processing prevents blocking main video pipeline
- Comprehensive error logging

## Testing

Run the test suite:
```bash
cd apps/video_processor
elixir test_runner.exs
```

Tests cover:
- Directory creation and management
- HLS conversion workflow
- Error handling scenarios
- Configuration functionality

## Future Enhancements

1. **Membrane Integration**: Enable full Membrane pipeline when dependencies available
2. **Quality Variants**: Support multiple quality levels (adaptive bitrate)
3. **Storage Integration**: Move from temp directories to persistent storage
4. **Progress Tracking**: Real-time conversion progress updates
5. **Cleanup**: Automatic cleanup of old HLS files