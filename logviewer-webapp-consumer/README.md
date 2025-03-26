# Log Viewer Webapp Consumer

**A terminal-style web application that displays streaming log data from a ZebraStream producer.**

This example demonstrates how a live data stream can be processed by code running in a web browser. The stream can be initiated both in a push-based or a pull-based manner (on demand). It can be generalized to any kind of data-driven web application working with data from one or multiple streams.

## Description

This application provides a terminal-like interface for viewing streaming log data. It features:
- Terminal-style green-on-black display
- Auto-scrolling log output
- Connection retry mechanism
- Authentication via a ZebraStream reader access token
- Simple connection dialog

## How to Use

1. Open the `logviewer.html` in a web browser
2. Press Enter to open the connection dialog
3. Enter the ZebraStream URL and optional access token (you may also include the access token as a query parameter in the URL)
4. Watch the logs appear in real-time

## Features

### Terminal Interface
- Classic green-on-black terminal aesthetic
- Monospace font for better log readability
- Auto-scrolling with overflow handling
- System message prefixes for status updates

### Connection Management
- Automatic reconnection on connection loss
- Up to 5 retry attempts with delay
- Support for authentication tokens
- Error handling with user feedback

### Input Dialog
- Clean modal interface for connection details
- URL input field
- Optional token input field
- Simple one-button submission

## Technical Details

The application uses:
- HTML5 Fetch API for streaming
- Native browser stream processing
- CSS Grid for layout
- Modern JavaScript async/await patterns

## Customization

You can modify:
- Retry settings (max attempts and delay)
- Terminal colors and styling
- System message format
- Connection dialog appearance

## Error Handling

The application handles various error scenarios:
- Network failures
- Authentication errors
- Invalid URLs
- Stream interruptions

## Usage Example

1. Start your ZebraStream producer (e.g., a log file streamer)
2. Open logviewer.html
3. Press Enter
4. Input the stream URL (either ZebraStream Connect API, e.g. https://connect.zebrastream.io/userspace/logs?mode=await-writer&timeout=3600, or ZebraStream Data API, e.g. https://data.zebrastream.io/userspace/logs)
5. Add authentication token if not passed as query parameter
6. Click OK to start receiving logs
