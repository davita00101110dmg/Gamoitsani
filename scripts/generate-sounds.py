#!/usr/bin/env python3
"""
Synthesises the app's sound set into GamoitsaniDesign's resources.

Generated rather than sourced so there is no licensing question and the whole palette can
be retuned by editing numbers. Run from the repo root.

To use a real recording instead, drop it in Resources named after the case — gameOver.m4a,
correct.mp3 — and it wins over the .wav this writes. Nothing here needs changing, and
rerunning is still safe.
"""

import math
import struct
import wave
from pathlib import Path

OUT = Path("Libraries/Packages/GamoitsaniDesign/Sources/GamoitsaniDesign/Resources")
RATE = 44100

# Equal temperament from A4. Names are the ones used in the note lists below.
def note(name):
    step = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}[name[0]]
    octave = int(name[-1])
    if "#" in name:
        step += 1
    return 440.0 * (2 ** (step / 12 + (octave - 4)))


def tone(freq, duration, harmonics, decay, attack=0.004):
    """One struck note. Harmonics give it a body — a bare sine reads as a cheap beep."""
    samples = []
    count = int(RATE * duration)
    for i in range(count):
        t = i / RATE
        value = sum(a * math.sin(2 * math.pi * freq * m * t) for m, a in harmonics)
        # Exponential decay is what makes it sound struck rather than switched off.
        env = math.exp(-t * decay)
        if t < attack:
            env *= t / attack
        samples.append(value * env)
    return samples


def mix(layers):
    """Overlay (offset, samples) pairs into one buffer."""
    length = max(off + len(s) for off, s in layers)
    out = [0.0] * length
    for off, s in layers:
        for i, v in enumerate(s):
            out[off + i] += v
    return out


def sequence(notes, gap, **kw):
    """Notes struck in order, each starting `gap` seconds after the last."""
    return mix([(int(RATE * gap * i), tone(note(n), d, kw["harmonics"], kw["decay"]))
                for i, (n, d) in enumerate(notes)])


def write(name, samples, peak):
    """Normalise to `peak` and write 16-bit mono. Relative levels are deliberate: a tick
    that matches the buzzer would be exhausting over a whole game."""
    high = max(abs(v) for v in samples) or 1.0
    scale = peak / high
    frames = b"".join(
        struct.pack("<h", max(-32768, min(32767, int(v * scale * 32767))))
        for v in samples
    )
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(frames)
    return path, len(samples) / RATE


BELL = [(1, 1.0), (2, 0.42), (3, 0.18), (4.2, 0.08)]
SOFT = [(1, 1.0), (2, 0.22), (3, 0.06)]
HARSH = [(1, 1.0), (2, 0.6), (3, 0.45), (5, 0.3), (7, 0.2)]

SOUNDS = {
    # Up is right. Two notes, bright and quick, so it can fire repeatedly without tiring.
    "correct":   (sequence([("C6", 0.16), ("E6", 0.26)], 0.055, harmonics=BELL, decay=14), 0.62),
    # Down is wrong. Softer and lower, so a skip never feels louder than a score.
    "skip":      (sequence([("A4", 0.20), ("F4", 0.30)], 0.065, harmonics=SOFT, decay=11), 0.50),
    # Three notes and higher — the super word should sound like more than a correct.
    "superWord": (sequence([("C6", 0.14), ("E6", 0.14), ("G6", 0.34)], 0.05, harmonics=BELL, decay=11), 0.72),
    # 3 - 2 - 1. Dry and short; this plays three times in a row.
    "tick":      (tone(note("A5"), 0.07, SOFT, 42), 0.34),
    # The last five seconds. Urgent enough to lift your head, not to startle.
    "warning":   (tone(note("E5"), 0.11, [(1, 1.0), (2, 0.5), (3, 0.25)], 26), 0.46),
    # Time. The one deliberately unpleasant sound in the set.
    "timeUp":    (sequence([("A2", 0.34), ("F2", 0.46)], 0.16, harmonics=HARSH, decay=5), 0.85),
    # Final whistle. A major arpeggio, the only sound allowed to take its time.
    "gameOver":  (sequence([("C5", 0.20), ("E5", 0.20), ("G5", 0.20), ("C6", 0.60)],
                           0.115, harmonics=BELL, decay=6), 0.78),
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (samples, peak) in SOUNDS.items():
        path, seconds = write(name, samples, peak)
        print(f"  {path.name:14} {seconds:.2f}s  {path.stat().st_size / 1024:.0f} KB")
