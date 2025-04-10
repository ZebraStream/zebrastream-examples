# Python Speech Recognition Example

**A real-time speech-to-text system using streaming audio over ZebraStream.**

This example demonstrates how to build a distributed speech recognition system where an audio producer captures sound from one device and streams it to a consumer that performs speech recognition in real-time. The solution uses the Vosk speech recognition engine for offline speech recognition without cloud dependencies.

## Description

The system consists of two main components:
- An audio producer (`producer-cmd.py`) that captures audio and streams it
- A speech recognition consumer (`consumer-vosk.py`) that receives and transcribes the audio

## How It Works

1. The producer captures audio from a microphone or audio source using an external command (e.g., `arecord`)
2. The audio stream is sent through ZebraStream in raw PCM WAV format
3. The consumer receives the audio stream and processes it in real-time using Vosk
4. Transcribed text is output as it becomes available

## Requirements

- Python 3.7 or higher
- Vosk speech recognition engine
- Vosk model files (download from https://alphacephei.com/vosk/models)
- Audio capture tools (e.g., `arecord` on Linux)
- Python packages: httpx, python-decouple, vosk, cysimdjson

## Setup

1. Install dependencies:
   ```bash
   pip install httpx python-decouple vosk cysimdjson
   ```

2. Download a Vosk model:
   ```bash
   wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip
   unzip vosk-model-small-en-us-0.15.zip
   ```

3. Configure environment:
   ```bash
   # For producer
   export WRITE_ACCESS_TOKEN="your-zebrastream-token"

    # For consumer
   export READ_ACCESS_TOKEN="your-zebrastream-token"
   ```

## Usage Example

1. Start the audio producer (on the sending device):
   ```bash
   # Linux (using arecord)
   ./producer-cmd.py https://connect.zebrastream.io/your/stream/path \
     arecord -- -f S16_LE -r 16000 -c 1

   # macOS (using sox)
   ./producer-cmd.py https://connect.zebrastream.io/your/stream/path \
     rec -- -t raw -r 16000 -e signed -b 16 -c 1 -
   ```

2. Start the speech recognition consumer (on the receiving device):
   ```bash
   ./consumer-vosk.py "https://data.zebrastream.io/your/stream/path?accesstoken=${READ_ACCESS_TOKEN}&mode=await-writer&redirect=true"
   ```

## Technical Details

### Producer Features
- Supports any command that outputs raw audio
- Automatic reconnection on connection loss
- Configurable chunk size for streaming
- Error handling and graceful shutdown
- Progress logging

### Consumer Features
- Real-time speech recognition using Vosk
- Support for multiple languages via Vosk models
- Efficient JSON parsing with cysimdjson
- Continuous stream processing

## Audio Requirements

The audio stream must be:
- Single channel (mono)
- 16-bit signed integer PCM
- 16kHz sample rate
- Little-endian byte order

## Customization

You can modify:
- Vosk model (different languages or larger models)
- Audio capture parameters
- Buffer and chunk sizes
- Retry settings for connection handling

## Troubleshooting

Common issues:
- Incorrect audio format: Ensure audio matches requirements
- Missing Vosk model: Download and extract to correct path
- Network interruptions: Producer will automatically retry
- Permission issues: Check audio device access rights
