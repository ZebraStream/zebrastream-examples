# ZebraStream Examples

A collection of examples demonstrating different usage patterns of [ZebraStream](https://www.zebrastream.io) for various streaming data scenarios.

## Examples Overview

### [Embedded Webapp Data Stream Provider](embedded-webapp-datastream-provider/README.md)
A demonstration of embedding a web application at the start of a data stream. Shows how to combine a web app with its data stream in a single streaming response. Features a colorful typewriter animation driven by streaming text data.

### [Logviewer Web App Consumer](logviewer-webapp-consumer/README.md)
A terminal-style web application that consumes streaming log data. Demonstrates how to build an interactive web client that can connect to and display live data streams, with features like auto-reconnect and authentication support.

### [Python Speech Recognition](python-speech-recognition/README.md)
A distributed speech-to-text system that streams audio from one device to another for real-time transcription. Demonstrates how to use ZebraStream for binary data streaming between Python applications.

### [Bash Producer Client](bash/README.md)
A robust bash script for streaming command output through ZebraStream. Demonstrates how to build a reliable producer client with minimal dependencies, featuring automatic reconnection, exponential backoff, and proper process management.

## Project Structure

Each example is contained in its own directory and includes:
- Source code
- Documentation in README.md
- Sample data where applicable
- Implementation example for ZebraStream producer or consumer

## License

The code in this repository can be freely copied and used in your projects. It is in the public domain. See [LICENSE](LICENSE) for details.
