"""
Voice Interface module for AgentRealm.
Captures audio from the microphone (or processes audio files)
and transcribes it using Gemini API (or local Whisper fallback).
Saves transcribed markdown notes to data/process/raw/.
"""

import os
import sys
import time
import wave
from datetime import datetime

# Ensure workspace root is in path
_WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if _WORKSPACE_ROOT not in sys.path:
    sys.path.append(_WORKSPACE_ROOT)

_RAW_NOTES_DIR = os.path.join(_WORKSPACE_ROOT, "data", "process", "raw")

def record_audio(output_filename: str, duration_seconds: int = 5, sample_rate: int = 16000):
    """
    Record audio from the default microphone and save as a WAV file.
    """
    print(f"[Voice] Preparing to record for {duration_seconds} seconds...")
    try:
        import sounddevice as sd
        print("[Voice] Recording started... Speak now!")
        recording = sd.rec(
            int(duration_seconds * sample_rate),
            samplerate=sample_rate,
            channels=1,
            dtype='int16'
        )
        sd.wait() # Wait until recording is finished
        print("[Voice] Recording finished. Saving to file...")
        
        with wave.open(output_filename, 'wb') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2) # 16-bit
            wf.setframerate(sample_rate)
            wf.writeframes(recording.tobytes())
            
        print(f"[Voice] Audio saved to {output_filename}")
        
    except ImportError:
        print("[Voice] 'sounddevice' package not found.")
        print("To record from microphone, please install: pip install sounddevice numpy")
        print("[Voice] Using keyboard input simulation for test purposes...")
        
        # Fallback simulation
        text = input("Please type your note instead (Voice fallback simulation): ")
        mock_wav(output_filename)
        return text
    return None

def mock_wav(filename: str):
    """Create a dummy WAV file if microphone recording falls back."""
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(b'\x00' * 32000)

def transcribe_audio(audio_path: str, simulated_text: str = None) -> str:
    """
    Transcribe an audio file using Gemini API or local Whisper.
    """
    if simulated_text:
        return simulated_text

    print(f"[Voice] Transcribing {os.path.basename(audio_path)}...")
    
    # 1. Attempt using Google Gemini Generative AI (Premium cloud transcription)
    try:
        import google.generativeai as genai
        api_key = os.environ.get("GOOGLE_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
            # Upload the audio file to Gemini
            print("[Voice] Uploading audio to Gemini API...")
            audio_file = genai.upload_file(path=audio_path)
            
            # Use Gemini to transcribe
            model = genai.GenerativeModel("gemini-1.5-flash")
            print("[Voice] Requesting transcript...")
            response = model.generate_content([
                audio_file,
                "Provide a clean, verbatim transcription of this audio recording in Markdown format."
            ])
            
            # Clean up the file from Gemini cloud
            genai.delete_file(audio_file.name)
            return response.text
    except Exception as e:
        print(f"[Voice] Gemini Cloud transcription skipped/failed: {e}")

    # 2. Attempt using local Whisper (Offline fallback)
    try:
        import whisper
        print("[Voice] Loading local Whisper model...")
        model = whisper.load_model("base")
        result = model.transcribe(audio_path)
        return result.get("text", "")
    except ImportError:
        print("[Voice] Local 'whisper' package not found (pip install openai-whisper).")
        
    return "Error: No transcription provider available (install openai-whisper or configure GOOGLE_API_KEY)."

def save_note(text: str):
    """
    Save transcribed text as a structured Markdown note in data/process/raw/.
    """
    os.makedirs(_RAW_NOTES_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    note_path = os.path.join(_RAW_NOTES_DIR, f"voice_note_{timestamp}.md")
    
    formatted_note = f"""# Voice Note — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

{text.strip()}

---
*Created via AgentRealm Voice Interface.*
"""
    with open(note_path, "w", encoding="utf-8") as f:
        f.write(formatted_note)
        
    print(f"✅ Voice note saved successfully: {note_path}")
    return note_path

def main():
    os.makedirs(_RAW_NOTES_DIR, exist_ok=True)
    temp_audio = os.path.join(_RAW_NOTES_DIR, "temp_voice.wav")
    
    # Record
    sim_text = record_audio(temp_audio, duration_seconds=5)
    
    # Transcribe
    transcript = transcribe_audio(temp_audio, simulated_text=sim_text)
    
    # Save
    if transcript.strip():
        save_note(transcript)
        
    # Clean up temp wave
    if os.path.exists(temp_audio):
        os.remove(temp_audio)

if __name__ == "__main__":
    main()
