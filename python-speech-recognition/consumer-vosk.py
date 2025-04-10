#!/usr/bin/env python3
import sys
import httpx
import argparse
from vosk import Model, KaldiRecognizer, SetLogLevel
import cysimdjson
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Configure Vosk logging - suppress all Vosk-related logging
SetLogLevel(-1)

# Configuration
MODEL_PATH = "vosk-model-small-en-us-0.15"  # download appropriate model from https://alphacephei.com/vosk/models
SAMPLE_RATE = 16000
CHUNK_SIZE = 8192

def process_audio_stream(url):
    logger.info("Initializing speech recognition model")
    # Initialize model and recognizer  TODO: delay until data is available
    model = Model(MODEL_PATH)
    recognizer = KaldiRecognizer(model, SAMPLE_RATE)
    json_parser = cysimdjson.JSONParser()
    # transcript_buffer = ""

    with httpx.Client(timeout=None) as client:
        with client.stream('GET', url, follow_redirects=True) as response:
            response.raise_for_status()
            logger.info("Started processing audio stream")
            for chunk in response.iter_bytes(chunk_size=CHUNK_SIZE):
                if recognizer.AcceptWaveform(chunk):
                    final = recognizer.Result()
                    parsed = json_parser.parse_string(final)
                    try:
                        transcript = parsed.at_pointer("/text")
                        if transcript:
                            print(transcript, flush=True)
                    except KeyError:
                        pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process streaming audio from URL using Vosk')
    parser.add_argument('url', help='URL to stream audio from')
    args = parser.parse_args()

    try:
        process_audio_stream(args.url)
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        sys.exit(1)
