#!/usr/bin/env python3
"""
ElevenLabs Text-to-Speech Script
Converts text to speech using the ElevenLabs API
"""

import os
import sys
from pathlib import Path
from elevenlabs import ElevenLabs, save

def text_to_speech(text, voice_id=None, output_path="output.mp3"):
    """
    Convert text to speech using ElevenLabs API
    
    Args:
        text (str): Text to convert to speech
        voice_id (str): Voice ID to use (optional, uses default if not provided)
        output_path (str): Path to save the audio file
    """
    # API key (will be replaced during distribution process)
    api_key = "sk_e2e11528e6b8def5523e25646be679f269f653a5bd157b5a"
    
    try:
        # Initialize the client
        client = ElevenLabs(api_key=api_key)
        
        # If no voice_id provided, list available voices
        if not voice_id:
            print("Fetching available voices...")
            voices = client.voices.get_all()
            
            if voices.voices:
                print("\nAvailable voices:")
                for i, voice in enumerate(voices.voices[:10]):  # Show first 10
                    print(f"{i+1}. {voice.name} (ID: {voice.voice_id})")
                    if voice.description:
                        print(f"   Description: {voice.description[:60]}...")
                
                # Use the first available voice
                voice_id = voices.voices[0].voice_id
                print(f"\nUsing voice: {voices.voices[0].name}")
            else:
                print("Error: No voices available")
                sys.exit(1)
        
        # Convert text to speech
        print(f"\nGenerating speech for: '{text}'")
        audio = client.text_to_speech.convert(
            voice_id=voice_id,
            text=text,
            model_id="eleven_multilingual_v2",
            output_format="mp3_44100_128"
        )
        
        # Save the audio file
        save(audio, output_path)
        print(f"Audio saved to: {output_path}")
        
        return output_path
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

def main():
    """Main function to handle command line usage"""
    if len(sys.argv) < 2:
        print("Usage: python elevenlabs_tts.py 'Your text to speak' [voice_id] [output_file]")
        print("\nExample:")
        print("  python elevenlabs_tts.py 'Hello, this is a test.'")
        print("  python elevenlabs_tts.py 'Hello, world!' JBFqnCBsd6RMkjVDRZzb hello.mp3")
        sys.exit(1)
    
    # Parse arguments
    text = sys.argv[1]
    voice_id = sys.argv[2] if len(sys.argv) > 2 else None
    output_file = sys.argv[3] if len(sys.argv) > 3 else "output.mp3"
    
    # Generate speech
    text_to_speech(text, voice_id, output_file)

if __name__ == "__main__":
    main()