#!/usr/bin/env python3
"""Genera tutti i suoni e le musiche di ODISPEL (sintesi, nessun campione esterno).

Uso:  python3 tools/make_audio.py
Scrive in assets/audio/sfx e assets/audio/music. Essendo sintetizzati da zero non
hanno problemi di licenza; per cambiare un suono basta modificare qui e rilanciare.
"""
import os
import numpy as np
from scipy.io import wavfile

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


def t_of(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack=0.005, decay=0.1, sustain=0.0, release=0.0):
    """Inviluppo semplice: attacco lineare, poi decadimento esponenziale."""
    e = np.exp(-np.arange(n) / (SR * max(decay, 1e-4)))
    a = max(1, int(SR * attack))
    e[:a] *= np.linspace(0, 1, a)
    if sustain > 0:
        e = np.maximum(e, sustain)
    if release > 0:
        r = int(SR * release)
        e[-r:] *= np.linspace(1, 0, r)
    return e


def sine(freq, seconds, phase=0.0):
    t = t_of(seconds)
    f = freq if np.ndim(freq) else np.full_like(t, freq)
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def square(freq, seconds):
    return np.sign(sine(freq, seconds)) * 0.6


def saw(freq, seconds):
    t = t_of(seconds)
    f = freq if np.ndim(freq) else np.full_like(t, freq)
    ph = (np.cumsum(f) / SR) % 1.0
    return 2 * ph - 1


def noise(seconds):
    return rng.uniform(-1, 1, int(SR * seconds))


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def sweep(f0, f1, seconds):
    t = t_of(seconds)
    return f0 + (f1 - f0) * (t / seconds)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def at(sound, offset, total):
    out = np.zeros(int(SR * total))
    s = int(SR * offset)
    out[s:s + len(sound)] += sound[:max(0, len(out) - s)]
    return out


def note_freq(name):
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    n = names[name[0]]
    if len(name) == 3:
        n += 1 if name[1] == "#" else -1
    octave = int(name[-1])
    return 440.0 * 2 ** ((n + 12 * (octave + 1) - 69) / 12)


def save(path, x, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * peak
    if not path.startswith("music/"):
        f = int(SR * 0.004)           # niente "clic" a fine suono
        x[-f:] *= np.linspace(1, 0, f)
    full = os.path.join(OUT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    wavfile.write(full, SR, (x * 32767).astype(np.int16))
    print("scritto", path, "%.2fs" % (len(x) / SR))


# ---------- Effetti ----------

def blip(freq, seconds=0.05, decay=0.03):
    s = seconds
    return sine(freq, s) * env(int(SR * s), 0.002, decay)


def make_sfx():
    save("sfx/click.wav", mix(blip(1300, 0.06, 0.02), blip(650, 0.06, 0.03) * 0.5))
    save("sfx/hover.wav", blip(950, 0.03, 0.012) * 0.4, 0.35)
    save("sfx/back.wav", mix(at(blip(900, 0.06, 0.03), 0, 0.2), at(blip(600, 0.08, 0.04), 0.06, 0.2)))
    save("sfx/toast.wav", mix(at(blip(1100, 0.12, 0.06), 0, 0.3), at(blip(1650, 0.15, 0.08), 0.07, 0.3)) * 0.8, 0.5)
    save("sfx/success.wav", mix(*[at(blip(note_freq(n), 0.2, 0.09), 0.08 * i, 0.5) for i, n in enumerate(["C5", "E5", "G5", "C6"])]), 0.7)
    save("sfx/ready.wav", mix(at(blip(note_freq("E5"), 0.14, 0.07), 0, 0.3), at(blip(note_freq("B5"), 0.18, 0.1), 0.09, 0.3)), 0.7)
    save("sfx/error.wav", lowpass(square(180, 0.25) * env(int(SR * 0.25), 0.004, 0.12), 1500) + 0.0, 0.7)
    save("sfx/save.wav", mix(at(blip(note_freq("G6"), 0.1, 0.05), 0, 0.25), at(blip(note_freq("C7"), 0.12, 0.06), 0.06, 0.25)), 0.35)

    n = int(SR * 0.28)
    thump = sine(sweep(180, 60, 0.28), 0.28) * env(n, 0.002, 0.07)
    crack = lowpass(noise(0.28), 4500) * env(n, 0.001, 0.04)
    save("sfx/hit.wav", mix(thump, crack * 0.8))
    n = int(SR * 0.32)
    thump = sine(sweep(110, 45, 0.32), 0.32) * env(n, 0.002, 0.09)
    crunch = lowpass(noise(0.32), 1800) * env(n, 0.001, 0.07)
    save("sfx/player_hit.wav", mix(thump * 1.1, crunch))
    n = int(SR * 0.35)
    ring = mix(sine(820, 0.35), sine(1230, 0.35) * 0.6, sine(1640, 0.35) * 0.3) * env(n, 0.001, 0.09)
    clang = lowpass(noise(0.05), 6000) * env(int(SR * 0.05), 0.001, 0.015)
    save("sfx/guard.wav", mix(ring, clang), 0.7)
    n = int(SR * 0.6)
    shimmer = sine(sweep(420, 880, 0.6), 0.6) * env(n, 0.03, 0.3) + sine(sweep(630, 1320, 0.6), 0.6) * env(n, 0.03, 0.25) * 0.5
    save("sfx/heal.wav", shimmer, 0.6)
    n = int(SR * 0.7)
    fall = sine(sweep(420, 70, 0.7), 0.7) * env(n, 0.002, 0.25)
    rumble = lowpass(noise(0.7), 900) * env(n, 0.002, 0.2)
    save("sfx/down.wav", mix(fall, rumble))
    n = int(SR * 0.7)
    rise = saw(sweep(60, 220, 0.7), 0.7) * (np.linspace(0.1, 1, n) ** 2)
    save("sfx/boss_charge.wav", lowpass(rise, 700) * env(n, 0.05, 1.0, 0.0, 0.1), 0.7)
    n = int(SR * 0.45)
    slam = sine(sweep(140, 40, 0.45), 0.45) * env(n, 0.002, 0.12)
    roar = lowpass(noise(0.45), 2500) * env(n, 0.001, 0.12)
    save("sfx/boss_attack.wav", mix(slam * 1.2, roar))
    n = int(SR * 0.22)
    whoosh = noise(0.22)
    whoosh = lowpass(whoosh, 400) * 0 + whoosh
    sw = lowpass(whoosh, 3000) * np.sin(np.pi * np.arange(n) / n)
    save("sfx/swap.wav", sw, 0.5)
    # stacco diagonale (cambio schermata): colpo di vento + tonfo
    n = int(SR * 0.35)
    wipe = lowpass(noise(0.35), 5000) * np.sin(np.pi * np.arange(n) / n) ** 2
    thud = sine(sweep(160, 70, 0.35), 0.35) * env(n, 0.002, 0.08) * 0.6
    save("sfx/wipe.wav", mix(wipe * 0.9, thud), 0.6)
    # sequenza ultimate: risalita metallica e colpo
    n = int(SR * 0.7)
    riser = saw(sweep(180, 900, 0.5), 0.5) * np.linspace(0.1, 1, int(SR * 0.5)) ** 1.5
    riser = lowpass(riser, 3000)
    boom = sine(sweep(120, 40, 0.5), 0.5) * env(int(SR * 0.5), 0.002, 0.14)
    save("sfx/cutin.wav", mix(riser * 0.8, at(boom, 0.38, 0.9) * 1.2, at(lowpass(noise(0.25), 4000) * env(int(SR * 0.25), 0.001, 0.07), 0.38, 0.9)), 0.8)
    # "voce" dei dialoghi: tic breve e basso, uno per lettera
    save("sfx/talk.wav", sine(300, 0.045) * env(int(SR * 0.045), 0.002, 0.02) + sine(600, 0.045) * env(int(SR * 0.045), 0.002, 0.015) * 0.3, 0.4)
    fan = [("C5", 0.0, 0.18), ("E5", 0.16, 0.18), ("G5", 0.32, 0.18), ("C6", 0.48, 0.9)]
    save("sfx/victory.wav", mix(*[at(mix(sine(note_freq(nm), d), sine(note_freq(nm) * 2, d) * 0.3) * env(int(SR * d), 0.01, d * 0.5), s, 1.6) for nm, s, d in fan]), 0.7)
    sad = [("A4", 0.0, 0.3), ("F4", 0.28, 0.3), ("D4", 0.56, 0.3), ("A3", 0.84, 1.0)]
    save("sfx/defeat.wav", mix(*[at(lowpass(saw(note_freq(nm), d), 1400) * env(int(SR * d), 0.01, d * 0.45), s, 2.0) for nm, s, d in sad]), 0.7)


def make_faction_sfx():
    """Suoni propri delle meccaniche di fazione: sparo, ricarica, contrattacco, critico, tratto."""
    n = int(SR * 0.2)
    bang = lowpass(noise(0.2), 6000) * env(n, 0.001, 0.035)
    kick = sine(sweep(260, 70, 0.2), 0.2) * env(n, 0.001, 0.05)
    save("sfx/shot.wav", mix(bang * 0.9, kick), 0.8)
    clack = lambda f: lowpass(noise(0.05), 7000) * env(int(SR * 0.05), 0.001, 0.012) + sine(f, 0.05) * env(int(SR * 0.05), 0.001, 0.015) * 0.5
    save("sfx/reload.wav", mix(at(clack(900), 0, 0.4), at(clack(1500), 0.14, 0.4), at(blip(2200, 0.08, 0.04) * 0.6, 0.22, 0.4)), 0.7)
    n = int(SR * 0.35)
    ring = mix(sine(1100, 0.35), sine(1650, 0.35) * 0.5) * env(n, 0.001, 0.1)
    save("sfx/counter.wav", mix(at(bang * 0.8, 0, 0.45), at(ring, 0.05, 0.45)), 0.8)
    n = int(SR * 0.3)
    ping = mix(sine(sweep(900, 2400, 0.3), 0.3), sine(sweep(1350, 3600, 0.3), 0.3) * 0.4) * env(n, 0.001, 0.12)
    crack = lowpass(noise(0.08), 6000) * env(int(SR * 0.08), 0.001, 0.02)
    save("sfx/crit.wav", mix(ping, crack * 0.8), 0.8)
    save("sfx/trait.wav", mix(at(blip(note_freq("E5"), 0.1, 0.05), 0, 0.3), at(blip(note_freq("A5"), 0.14, 0.07), 0.07, 0.3)) * 0.8, 0.5)


# ---------- Musica (cicli perfetti: i code delle note si riavvolgono) ----------

def put(track, sound, start_sample):
    """Somma `sound` in `track` a partire da start_sample, riavvolgendo la coda."""
    n = len(track)
    idx = (start_sample + np.arange(len(sound))) % n
    np.add.at(track, idx, sound)


def pluck(freq, seconds, bright=0.5):
    n = int(SR * seconds)
    s = mix(sine(freq, seconds), sine(freq * 2, seconds) * bright * 0.5, square(freq, seconds) * 0.15)
    return s * env(n, 0.003, seconds * 0.35)


def pad(freqs, seconds):
    n = int(SR * seconds)
    s = np.zeros(n)
    for f in freqs:
        for det in (-0.004, 0.0, 0.004):
            s += saw(f * (1 + det), seconds) * 0.12
    s = lowpass(s, 1100)
    a = int(SR * 0.6)
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    e[-a:] = np.linspace(1, 0, a)
    return s * e


def kick():
    n = int(SR * 0.22)
    return sine(sweep(130, 45, 0.22), 0.22) * env(n, 0.001, 0.07)


def snare():
    n = int(SR * 0.18)
    return lowpass(noise(0.18), 5000) * env(n, 0.001, 0.045) * 0.7 + sine(190, 0.18) * env(n, 0.001, 0.03) * 0.4


def hat():
    n = int(SR * 0.05)
    return noise(0.05) * env(n, 0.001, 0.012) * 0.25


CHORDS = [("A", ["A3", "C4", "E4"], "A2"), ("F", ["F3", "A3", "C4"], "F2"), ("C", ["C4", "E4", "G4"], "C2"), ("G", ["G3", "B3", "D4"], "G2")]


def music(bpm, bars_per_chord, chords_rounds, battle):
    beat = 60.0 / bpm
    bar = beat * 4
    total_bars = bars_per_chord * 4 * chords_rounds
    total = bar * total_bars
    track = np.zeros(int(SR * total))
    for b in range(total_bars):
        ch = CHORDS[(b // bars_per_chord) % 4]
        start = int(SR * b * bar)
        if b % bars_per_chord == 0:
            put(track, pad([note_freq(n) for n in ch[1]], bar * bars_per_chord + 0.8) * (0.9 if not battle else 0.6), start)
        bass = note_freq(ch[2])
        steps = 8 if battle else 4
        for i in range(steps):
            off = int(SR * (b * bar + i * bar / steps))
            dur = bar / steps * (0.9 if battle else 1.6)
            put(track, lowpass(saw(bass if (i % 4 != 3 or not battle) else bass * 1.5, dur), 500) * env(int(SR * dur), 0.004, dur * 0.5) * 0.9, off)
        arp_notes = [note_freq(n) * (2 if (j // 3) % 2 else 1) for j, n in enumerate(ch[1] * 4)]
        sub = 16 if battle else 8
        for i in range(sub):
            f = arp_notes[i % len(arp_notes)] * 2
            off = int(SR * (b * bar + i * bar / sub))
            put(track, pluck(f, bar / sub * 2.2, 0.6 if battle else 0.3) * (0.35 if battle else 0.28), off)
        if battle:
            for k in range(4):
                put(track, kick() * 0.9, int(SR * (b * bar + k * beat)))
                if k in (1, 3):
                    put(track, snare() * 0.8, int(SR * (b * bar + k * beat)))
            for k in range(8):
                put(track, hat(), int(SR * (b * bar + k * beat / 2 + beat / 4)))
    return track


def make_music():
    save("music/menu.wav", music(84, 1, 3, False), 0.55)
    save("music/battle.wav", music(138, 2, 2, True), 0.6)


if __name__ == "__main__":
    import sys
    if "--faction" in sys.argv:       # solo i suoni nuovi delle fazioni (non riscrive gli altri)
        make_faction_sfx()
    else:
        make_sfx()
        make_faction_sfx()
        make_music()
