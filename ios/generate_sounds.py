#!/usr/bin/env python3
"""
Generate sound effects for the iOS Belote app
"""
import wave
import struct
import math

def generate_melody(filename, notes, note_duration=0.15, sample_rate=44100):
    """
    Generate a melody from a list of frequencies
    notes: list of (frequency, duration_multiplier) tuples
    """
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)

        for freq, duration_mult in notes:
            duration = note_duration * duration_mult
            num_samples = int(sample_rate * duration)

            for i in range(num_samples):
                t = i / sample_rate
                # Envelope: quick attack, sustain, quick release
                if i < num_samples * 0.1:
                    amplitude = 0.4 * (i / (num_samples * 0.1))
                elif i > num_samples * 0.8:
                    amplitude = 0.4 * (1 - (i - num_samples * 0.8) / (num_samples * 0.2))
                else:
                    amplitude = 0.4

                sample = amplitude * math.sin(2 * math.pi * freq * t)
                packed_value = struct.pack('h', int(sample * 32767))
                wav_file.writeframes(packed_value)

# Notes musicales (fréquences approximatives)
C5 = 523   # Do
D5 = 587   # Ré
E5 = 659   # Mi
F5 = 698   # Fa
G5 = 784   # Sol
A5 = 880   # La
B5 = 988   # Si
C6 = 1047  # Do aigu

# 20 points (Valet d'atout) - Mélodie joyeuse ascendante type "jackpot"
generate_melody('sound_20.wav', [
    (C5, 0.5), (E5, 0.5), (G5, 0.5), (C6, 1.2)
])
print("✓ Generated sound_20.wav (Valet d'atout - 20pts)")

# 14 points (9 d'atout) - Mélodie joyeuse mais plus courte
generate_melody('sound_14.wav', [
    (E5, 0.6), (G5, 0.6), (B5, 1.0)
])
print("✓ Generated sound_14.wav (9 d'atout - 14pts)")

# 11 points (As) - Mélodie noble et satisfaisante
generate_melody('sound_11.wav', [
    (G5, 0.7), (A5, 0.7), (G5, 0.8)
])
print("✓ Generated sound_11.wav (As - 11pts)")

# 10 points (10) - Mélodie agréable
generate_melody('sound_10.wav', [
    (F5, 0.7), (A5, 0.9)
])
print("✓ Generated sound_10.wav (10 - 10pts)")

# 4 points et moins (Roi, Dame) - Son simple neutre
generate_melody('sound_low.wav', [
    (D5, 0.8)
])
print("✓ Generated sound_low.wav (Roi/Dame/8/7 - points faibles)")

# 0 points - Son discret
generate_melody('sound_0.wav', [
    (C5, 0.5)
])
print("✓ Generated sound_0.wav (cartes sans points)")

print("\n✅ All sound files generated!")
