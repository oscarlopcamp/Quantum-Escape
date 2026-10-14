#!/usr/bin/env python3
"""Render Quantum Escape's original, synchronized electronic music stems.

No downloaded samples, pretrained generators, or network access are used.
Requires the locally available NumPy package. Run from any directory with:
    python3 tools/generate_quantum_audio.py

Both stereo PCM WAVs last exactly 40 seconds: 16 bars at 96 BPM in 4/4.
The progression is Em9 / Cmaj7 / G6 / Dadd9, four bars per chord. The
ambient stem contains warm pads, a bell arpeggio, and quiet spatial echoes;
the pulse stem contains a restrained electronic beat and round bass.
Envelopes and echo tails wrap into the beginning, making the files loops.
The game can fade the pulse independently without changing the harmony.
"""

from __future__ import annotations

import math
from pathlib import Path
import wave

import numpy as np


SAMPLE_RATE = 22050
BPM = 96
BEAT = 60.0 / BPM
BARS = 16
DURATION = BARS * 4 * BEAT
FRAMES = round(SAMPLE_RATE * DURATION)
RNG = np.random.default_rng(240410)
OUTPUT = Path(__file__).resolve().parents[1] / "audio"

# MIDI pitches, voiced to keep the pad soft and give the melody space.
CHORDS = ((52, 59, 62, 66), (48, 55, 59, 64), (43, 55, 59, 64), (50, 57, 64, 66))
ARPEGGIOS = ((71, 74, 78, 76), (67, 71, 76, 74), (67, 71, 76, 74), (69, 74, 76, 78))
ROOTS = (40, 36, 31, 38)


def frequency(midi: int) -> float:
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def seconds(duration: float) -> np.ndarray:
    return np.arange(round(duration * SAMPLE_RATE), dtype=np.float64) / SAMPLE_RATE


def add(stem: np.ndarray, signal: np.ndarray, start: float, gain: float, pan: float = 0.0) -> None:
    """Circular overlap-add, including notes starting before sample zero."""
    first = round(start * SAMPLE_RATE) % FRAMES
    left = math.cos((pan + 1.0) * math.pi / 4.0) * gain
    right = math.sin((pan + 1.0) * math.pi / 4.0) * gain
    stereo = signal[:, None] * np.array((left, right))
    remaining = len(signal)
    cursor = 0
    while remaining:
        count = min(remaining, FRAMES - first)
        stem[first:first + count] += stereo[cursor:cursor + count]
        remaining -= count
        cursor += count
        first = 0


def edge_envelope(t: np.ndarray, duration: float, attack: float, release: float) -> np.ndarray:
    """Smooth zero-slope boundaries; an event can safely wrap the loop."""
    fade_in = np.sin(np.minimum(t / attack, 1.0) * math.pi / 2.0) ** 2
    fade_out = np.sin(np.clip((duration - t) / release, 0.0, 1.0) * math.pi / 2.0) ** 2
    return fade_in * fade_out


def make_pad(midi: int, voice: int) -> np.ndarray:
    duration = 4 * 4 * BEAT + 3.0
    t = seconds(duration)
    f = frequency(midi)
    phase = 2 * math.pi * f * t
    # Close detuning and slow harmonic motion provide width without a harsh saw.
    tone = 0.67 * np.sin(phase + 0.13 * np.sin(2 * math.pi * 0.23 * t + voice))
    tone += 0.19 * np.sin(phase * 1.0018 + 0.4)
    tone += 0.10 * np.sin(phase * 2 + 0.12 * np.sin(2 * math.pi * 0.17 * t))
    tone += 0.025 * np.sin(phase * 3 + 0.6)
    return tone * edge_envelope(t, duration, 3.0, 3.0)


def make_bell(midi: int, length: float = 1.9) -> np.ndarray:
    t = seconds(length)
    phase = 2 * math.pi * frequency(midi) * t
    tone = np.sin(phase) * np.exp(-t * 3.1)
    tone += 0.24 * np.sin(phase * 2) * np.exp(-t * 5.8)
    tone += 0.08 * np.sin(phase * 3) * np.exp(-t * 8.0)
    return tone * edge_envelope(t, length, 0.012, 0.18)


def make_bass(midi: int, duration: float) -> np.ndarray:
    t = seconds(duration)
    phase = 2 * math.pi * frequency(midi) * t
    tone = np.sin(phase) + 0.095 * np.sin(phase * 2) + 0.07 * np.sin(phase * 3)
    return tone * np.exp(-t * 0.65) * edge_envelope(t, duration, 0.018, 0.15)


def make_kick() -> np.ndarray:
    t = seconds(0.42)
    # Integral of an exponentially falling pitch: warm, rounded low drum.
    phase = 2 * math.pi * (43 * t + 60 * (1 - np.exp(-t * 34)) / 34)
    return np.sin(phase) * np.exp(-t * 11) * edge_envelope(t, 0.42, 0.004, 0.06)


def band_noise(length: float, low: float, high: float) -> tuple[np.ndarray, np.ndarray]:
    t = seconds(length)
    noise = RNG.normal(0.0, 1.0, len(t))
    spectrum = np.fft.rfft(noise)
    bins = np.fft.rfftfreq(len(t), 1.0 / SAMPLE_RATE)
    weight = np.clip((bins - low) / 400, 0, 1) * np.clip((high - bins) / 700, 0, 1)
    filtered = np.fft.irfft(spectrum * weight, n=len(t))
    filtered /= max(np.std(filtered), 1e-9)
    return t, filtered


def make_hat(accent: bool) -> np.ndarray:
    duration = 0.17 if accent else 0.10
    t, noise = band_noise(duration, 3900, 8500)
    return noise * np.exp(-t * (35 if accent else 56)) * edge_envelope(t, duration, 0.003, 0.035)


def make_snare() -> np.ndarray:
    t, noise = band_noise(0.24, 1100, 6000)
    body = np.sin(2 * math.pi * 180 * t) * np.exp(-t * 25)
    return (noise * 0.55 + body * 0.45) * np.exp(-t * 17) * edge_envelope(t, 0.24, 0.003, 0.05)


def circular_echo(stem: np.ndarray, delays: tuple[tuple[float, float], ...]) -> np.ndarray:
    result = stem.copy()
    for delay, gain in delays:
        # Each return swaps channels to spread the arpeggio across the field.
        result += np.roll(stem[:, ::-1], round(delay * SAMPLE_RATE), axis=0) * gain
    return result


def render() -> tuple[np.ndarray, np.ndarray]:
    pad = np.zeros((FRAMES, 2), dtype=np.float64)
    melody = np.zeros_like(pad)
    pulse = np.zeros_like(pad)
    for chord_index, notes in enumerate(CHORDS):
        start = chord_index * 16 * BEAT - 1.5
        for voice, note in enumerate(notes):
            add(pad, make_pad(note, voice), start, 0.026, (voice - 1.5) * 0.37)

    # Sixteenth-slot motif leaves breathing room. Repetition makes it melodic.
    motif = (0, 1, 2, 1, 3, 2, 1, 2)
    for bar in range(BARS):
        harmony = bar // 4
        for eighth in range(8):
            note = ARPEGGIOS[harmony][motif[eighth]]
            # A softly lowered turnaround at the end of each four-bar phrase.
            if bar % 4 == 3 and eighth >= 6:
                note -= 12
            gain = (0.047 if eighth % 2 == 0 else 0.034)
            pan = 0.40 * math.sin((bar * 8 + eighth) * math.pi / 4)
            add(melody, make_bell(note), (bar * 4 + eighth * 0.5) * BEAT, gain, pan)

        for offset, strength in ((0, 1.0), (2, 0.86)):
            add(pulse, make_kick(), (bar * 4 + offset) * BEAT, 0.19 * strength)
        for offset in (1, 3):
            add(pulse, make_snare(), (bar * 4 + offset) * BEAT, 0.034, -0.08)
        for eighth in range(8):
            accent = eighth % 2 == 1
            add(pulse, make_hat(accent), (bar * 4 + eighth * 0.5) * BEAT,
                0.012 if accent else 0.0075, 0.25 if accent else -0.25)

        # Bass answers the kick with small syncopations; a fifth lifts bar four.
        for offset, length, strength in ((0, 1.22, 1.0), (1.5, 0.88, 0.8), (2.75, 1.0, 0.85)):
            note = ROOTS[harmony]
            if bar % 4 == 3 and offset == 2.75:
                note += 7
            add(pulse, make_bass(note, length * BEAT), (bar * 4 + offset) * BEAT,
                0.083 * strength, -0.035)

    ambient = circular_echo(pad, ((0.13, 0.19), (0.31, 0.10)))
    ambient += circular_echo(melody, ((BEAT * 0.75, 0.32), (BEAT * 1.5, 0.17), (BEAT * 2.25, 0.07)))
    # Fixed composition gain, not per-file peak normalization: stems stay balanced.
    ambient *= 3.2
    pulse *= 2.8
    ambient -= np.mean(ambient, axis=0)
    pulse -= np.mean(pulse, axis=0)
    return ambient, pulse


def write_wave(name: str, samples: np.ndarray) -> None:
    peak = float(np.max(np.abs(samples)))
    rms = float(np.sqrt(np.mean(samples ** 2)))
    seam = float(np.max(np.abs(samples[0] - samples[-1])))
    # A healthy seam is no steeper than a normal sample transition in the loop.
    max_step = float(np.max(np.abs(np.diff(samples, axis=0))))
    assert peak < 0.75, f"Unexpected peak in {name}: {peak}"
    assert seam <= max_step + 1e-6, f"Unexpected discontinuity in {name}: {seam}"
    pcm = np.rint(samples * 32767).astype("<i2")
    with wave.open(str(OUTPUT / name), "wb") as destination:
        destination.setnchannels(2)
        destination.setsampwidth(2)
        destination.setframerate(SAMPLE_RATE)
        destination.writeframes(pcm.tobytes())
    print(f"{name}: {DURATION:.3f}s, stereo {SAMPLE_RATE}Hz, peak={peak:.4f}, "
          f"RMS={rms:.4f}, loop_step={seam:.6f}")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    ambient, pulse = render()
    combined_peak = float(np.max(np.abs(ambient + pulse)))
    assert combined_peak < 0.9, f"Combined stems exceed headroom: {combined_peak}"
    write_wave("quantum_ambient.wav", ambient)
    write_wave("quantum_pulse.wav", pulse)
    print(f"96 BPM | 16 bars | Em9/Cmaj7/G6/Dadd9 | combined peak={combined_peak:.4f}")


if __name__ == "__main__":
    main()
