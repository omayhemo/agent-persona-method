#!/usr/bin/env python3
"""
Simple ElevenLabs TTS Example
"""

import os
from elevenlabs import ElevenLabs, save

# API key (will be replaced during distribution process)
API_KEY = "sk_e2e11528e6b8def5523e25646be679f269f653a5bd157b5a"

# Initialize client
client = ElevenLabs(api_key=API_KEY)

# Text to convert
text = "The first move is what sets everything in motion."

# Generate speech (using a popular voice ID)
audio = client.text_to_speech.convert(
    voice_id="JBFqnCBsd6RMkjVDRZzb",  # George voice
    text=text,
    model_id="eleven_multilingual_v2"
)

# Save audio file
save(audio, "output.mp3")
print("Audio saved to output.mp3")