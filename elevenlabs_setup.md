# ElevenLabs TTS Setup Guide

## Installation

1. Install the ElevenLabs Python SDK:
```bash
pip install elevenlabs
```

## API Key Setup

1. Get your API key from [ElevenLabs Dashboard](https://elevenlabs.io)
2. Set it as an environment variable:

```bash
# Linux/Mac
export ELEVENLABS_API_KEY='your_api_key_here'

# Windows (Command Prompt)
set ELEVENLABS_API_KEY=your_api_key_here

# Windows (PowerShell)
$env:ELEVENLABS_API_KEY="your_api_key_here"
```

## Usage

### Simple Example
```bash
# Edit elevenlabs_simple.py and replace YOUR_API_KEY_HERE with your actual key
# Or set the environment variable as shown above
python elevenlabs_simple.py
```

### Full Featured Script
```bash
# Basic usage - will list available voices and use the first one
python elevenlabs_tts.py "Hello, this is a test."

# With specific voice ID
python elevenlabs_tts.py "Hello, world!" JBFqnCBsd6RMkjVDRZzb

# With voice ID and custom output file
python elevenlabs_tts.py "Welcome to ElevenLabs!" JBFqnCBsd6RMkjVDRZzb welcome.mp3
```

## Available Features

- **Multiple voices**: The script can list all available voices
- **Custom output**: Specify output filename
- **Error handling**: Proper error messages for missing API key
- **Model selection**: Uses the latest multilingual model
- **Audio format**: MP3 output at 44.1kHz, 128kbps

## Common Voice IDs

- `JBFqnCBsd6RMkjVDRZzb` - George
- `EXAVITQu4vr4xnSDxMaL` - Bella
- `MF3mGyEYCl7XYWbV9V6O` - Elli
- `TxGEqnHWrfWFTfGW9XjX` - Josh

## Troubleshooting

1. **"ELEVENLABS_API_KEY environment variable not set"**
   - Set the environment variable as shown above
   - Or edit the script and add your API key directly

2. **"No voices available"**
   - Check your API key is valid
   - Ensure you have an active ElevenLabs subscription

3. **Rate limiting**
   - Free tier has limited characters per month
   - Check your usage in the ElevenLabs dashboard