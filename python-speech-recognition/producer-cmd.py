#!/usr/bin/env python3
import httpx
from decouple import config
import sys
import logging
import argparse
import subprocess
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Configuration  # TODO: read from .env file
WRITE_ACCESS_TOKEN = config('WRITE_ACCESS_TOKEN')  # Sender write token
CHUNK_SIZE = 16384  # 16KB (4 * 4096)

class ProcessStdout:
    def __init__(self, command: list):
        self.command = command  # Already a list of arguments
        self.process = None

    def __enter__(self):
        try:
            self.process = subprocess.Popen(
                self.command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=None, # inherits stdin from the parent process
                shell=False,
                text=False,
                # bufsize=CHUNK_SIZE
            )
            # Check process status without delay
            retcode = self.process.poll()
            if retcode is not None:  # Process has terminated
                _, stderr = self.process.communicate()
                if retcode != 0:  # Process failed
                    raise RuntimeError(f"Command failed with code {retcode}: {stderr.decode()}")

            # Process is still running
            return self.process.stdout
        except Exception as e:
            raise RuntimeError(f"Failed to execute command: {str(e)}")

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()

def chunkify(buffer):
    try:
        while chunk := buffer.read1(CHUNK_SIZE):
            yield chunk
    except KeyboardInterrupt:
        # Stop the data stream on interrupt
        logger.info("Received interrupt, stopping data stream")
        pass

def producer(command, connect_url, content_type):
    logger.info("Starting stream producer")
    
    with httpx.Client(timeout=None) as client:
        while True:
            try:
                logger.info("Waiting for receiver using Connect API")
                response = client.get(
                    connect_url,
                    params={"mode": "await-reader"},
                    headers={"Authorization": f"Bearer {WRITE_ACCESS_TOKEN}"}
                )
                response.raise_for_status()
                stream_url = response.text.strip()
                logger.info("Receiver connected successfully")
                break
            except (httpx.RequestError, httpx.HTTPStatusError) as e:
                logger.warning(f"Connection attempt failed: {str(e)}")
                time.sleep(1)  # Avoid busy waiting
                continue

        # Start the external process
        try:
            with ProcessStdout(command) as process_output:
                logger.info("External process started successfully")
                logger.info("Starting data transfer")
                with client.stream(
                    "PUT",
                    stream_url,
                    headers={
                        "Authorization": f"Bearer {WRITE_ACCESS_TOKEN}",
                        "Content-Type": content_type,  # Use the specified Content-Type
                    },
                    content=chunkify(process_output),
                    timeout=150.0
                ) as response:
                    response.raise_for_status()
                    logger.info(f"Transfer completed successfully with status code: {response.status_code}")
        except KeyboardInterrupt:
            logger.info("Received interrupt, stopping transfer")
            raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Stream output from command to ZebraStream')
    parser.add_argument('connect_url', help='ZebraStream Connect API URL')
    parser.add_argument('command', help='Command to execute')
    parser.add_argument('args', nargs=argparse.REMAINDER, help='Arguments for the command')
    parser.add_argument('--content-type', default='application/octet-stream', help='Content-Type for the HTTP request')
    args = parser.parse_args()

    command = [args.command] + args.args
    try:
        producer(command, args.connect_url, args.content_type)
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully")
        sys.exit(0)
    except Exception as e:
        logger.error(f"An error occurred: {str(e)}")
        sys.exit(1)
