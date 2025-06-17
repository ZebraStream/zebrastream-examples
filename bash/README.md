# Bash Producer Client

**A simple bash script to stream command output through ZebraStream.**

This example demonstrates how to build a robust producer client in pure bash that can:
- Stream output from any command
- Handle connection failures with exponential backoff
- Support authentication
- Clean up processes on exit

## Requirements

- Bash 4.0 or higher
- curl with HTTP/1.1 support
- Standard Unix tools (date, pkill)

## Installation

No installation needed, just download the script and make it executable:
```bash
chmod +x zebrastream-producer.bash
```

## Configuration

Set required environment variables:
```bash
export ZEBRASTREAM_ACCESSTOKEN="your-token"
export ZEBRASTREAM_PATH="/your/stream/path"
```

Optional settings:
```bash

export ZEBRASTREAM_CONNECT_URL="https://connect.zebrastream.io/v0"  # default using global ZebraStream Connect API
export ZEBRASTREAM_MAX_RETRIES=5                                    # default, number of retries after connection errors
export ZEBRASTREAM_RETRY_DELAY=5                                    # default, initial retry timeout for exponential backoff
export ZEBRASTREAM_MIN_DISCONNECT_SECONDS=60                        # default, minimum duration to classify a connection error a disconnect
export ZEBRASTREAM_CONTENT_TYPE="text/plain"                        # default, change to any valid Tontent-Type header value
export ZEBRASTREAM_READ_MODE="blocking"                             # default 'blocking', can be set to 'nonblocking'
```

## Usage

```bash
# Stream a log file
ZEBRASTREAM_READ_MODE='nonblocking' ./zebrastream-producer.bash tail -f /var/log/syslog

# Stream command output
ZEBRASTREAM_READ_MODE='nonblocking' ./zebrastream-producer.bash journalctl -f

# Use with any command that produces output
./zebrastream-producer.bash vmstat 1
```

## Features

- Robust error handling
- Exponential backoff for retries
- Automatic reconnection
- Clean process termination
- Structured logging
- Support for interruption (Ctrl+C)
- Support for both blocking and non-blocking read modes (note that some older curl versions seem to have problems with non-blocking read mode, so the default is blocking)

## Limitations

- Commands requiring shell features (pipes, redirections) need a wrapper script
- No support for interactive commands
- Single producer command only

## Error Handling

The script handles various failure scenarios:
- Network connection issues
- Authentication failures
- Process termination
- Invalid responses

## Example Wrapper Script

For commands requiring shell features:

```bash
#!/bin/bash
# wrapper.sh
journalctl -f | grep -v DEBUG | sed 's/^/[myapp] /'
```

Then use it with:
```bash
export ZEBRASTREAM_READ_MODE='nonblocking'
./zebrastream-producer.bash ./wrapper.sh
```
