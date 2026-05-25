#!/usr/bin/env python3
"""
Generate simple beep sounds for the PWA
"""
import wave
import struct
import math

def generate_beep(filename, frequency, duration, sample_rate=44100):
    """Generate a simple sine wave beep"""
    num_samples = int(sample_rate * duration)

    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)

        for i in range(num_samples):
            # Generate sine wave with fade out
            t = i / sample_rate
            amplitude = 0.3 * (1 - t / duration)  # fade out
            sample = amplitude * math.sin(2 * math.pi * frequency * t)

            # Convert to 16-bit integer
            packed_value = struct.pack('h', int(sample * 32767))
            wav_file.writeframes(packed_value)

# Card sound: 800Hz, 0.2s
generate_beep('resources/card.wav', 800, 0.2)
print("✓ Generated resources/card.wav")

# Points sound: 1200Hz, 0.15s
generate_beep('resources/points.wav', 1200, 0.15)
print("✓ Generated resources/points.wav")
