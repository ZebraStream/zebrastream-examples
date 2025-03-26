# Embedded Webapp Datastream Provider Example

**A simple web application that creates a typewriter effect with rainbow-colored text from streaming data.**

This example demonstrates how to add a web application data consumer to the beginning of a data stream. It can be applied to any single-shot data-driven web application, such as displaying a vehicle's current position on a map. The main advantage of this approach is that the producer has complete control over the lifecycle of the consumer application, and it only requires a single stream to deliver it.

## Description

The application consists of two main components that must be combined into a single streaming response:

- A web application (`typewriter-webapp.html`) that displays text with a typewriter effect
- A sample data file (`sample-data.txt`) containing the text to be displayed

## How It Works

1. The HTML application and the data must be concatenated and delivered as a single streaming response
2. First, send the complete HTML file content
3. Then stream the data from `sample-data.txt` line by line, possible with a time delay between the lines.
4. The webapp will automatically process the incoming data stream until it is closed.

## Implementation with ZebraStream

To use this example with ZebraStream:

Create a producer that:

- First sends the complete content of `typewriter-webapp.html`
- Then streams the content of `sample-data.txt` or similar data, that can be generated dynamically.

## Features

- Character-by-character typewriter animation
- Rainbow color effect for each character
- Line-by-line text processing
- Streaming data support

## How to Use

1. Set up the files:
   
   - Place `typewriter-webapp.html` and `sample-data.txt` in the same directory
   - Ensure `sample-data.txt` contains the text you want to display (one sentence per line)

2. Open `typewriter-webapp.html` in a web browser

The application will read the text from `sample-data.txt` and display it character by character with a rainbow color effect.

## Sample Data Format

The `sample-data.txt` file should contain plain text with one sentence per line. This data will be streamed after the HTML content:

```
Welcome to the typewriter effect!
Each line will appear one by one.
The text will be displayed in rainbow colors.
```

## Technical Details

The web application uses:

- HTML5 Streams API for processing the incoming data stream
- JavaScript for animation control
- CSS for styling and layout
- Dynamic color generation using HSL color space
- Built-in stream processing for handling the data appended after the HTML content

## Customization

You can modify the following aspects:

- Animation speed: Change the timeout values in `typewriter-webapp.html`
- Font size and styling: Modify the CSS in `typewriter-webapp.html`
- Text content: Edit `sample-data.txt` or replace it by a dynamic process that outputs phrases or sentences.