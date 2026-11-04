#!/usr/bin/env python3
"""Genera TUTTI i suoni del combattimento V3 (effetti + musica a strati) da zero, solo con numpy e ffmpeg.

Perche' sintetizzati e non scaricati: sono nostri al 100% (licenza CC0, nessun obbligo di citazione), si rifanno
identici con un comando e si ritoccano cambiando un numero qui sotto (stessa regola dei dialoghi: si corregge lo
script e si rigenera, i file .ogg non si toccano a mano). Il suono e' elettronico e un po' "rotto", come la diretta
di Echo e i neon della citta' (STILE_VISIVO: notte urbana e neon).

Uso:  python3 tools/gen_suoni.py            -> scrive assets/audio/*.ogg e assets/audio/musica/*.ogg
Poi:  godot --headless --path . --import    (crea i .import)
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = np.random.default_rng(7)          # seme fisso: rigenerando escono gli stessi file


# ---------------------------------------------------------------- mattoncini
def T(sec):
    return np.arange(int(SR * sec)) / SR


def env_exp(n, k):
    """decadimento esponenziale: k = quante volte si dimezza... in pratica, piu' alto = piu' corto"""
    return np.exp(-k * np.arange(n) / SR)


def env_ad(n, a, d_k):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(a, 1e-4))
    return e * np.exp(-d_k * np.maximum(0.0, t - a))


def sweep(f0, f1, sec, curve=4.0):
    """fase di un sinusoide che scivola da f0 a f1 (esponenziale)"""
    t = T(sec)
    f = f1 + (f0 - f1) * np.exp(-curve * t / sec)
    return 2 * np.pi * np.cumsum(f) / SR


def noise(sec):
    return rng.uniform(-1, 1, int(SR * sec))


def band(x, lo=0.0, hi=SR / 2, soft=0.15):
    """filtro passa-banda in frequenza (FFT, bordi morbidi): per il rumore basta e avanza"""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    m = np.ones_like(f)
    if lo > 0:
        m *= 1 / (1 + (lo / np.maximum(f, 1e-3)) ** (2 / soft * 0.3))
    if hi < SR / 2:
        m *= 1 / (1 + (f / hi) ** (2 / soft * 0.3))
    return np.fft.irfft(X * m, len(x))


def saw(freq, t, bright=1.0, decay=0.0, detune=0.0):
    """dente di sega additivo (senza aliasing). bright < 1 taglia gli acuti; decay > 0 li spegne nel tempo (pizzicato)"""
    out = np.zeros_like(t)
    f = freq * (2 ** (detune / 1200))
    kmax = int(min(60, (SR / 2.2) / f))
    for k in range(1, kmax + 1):
        a = (1.0 / k) * (bright ** (k - 1))
        if a < 1e-4:
            break
        h = np.sin(2 * np.pi * f * k * t) * a
        if decay > 0:
            h *= np.exp(-decay * k * t)
        out += h
    return out


def square(freq, t, bright=1.0, decay=0.0):
    out = np.zeros_like(t)
    kmax = int(min(40, (SR / 2.2) / freq))
    for k in range(1, kmax + 1, 2):
        a = (1.0 / k) * (bright ** (k - 1))
        if a < 1e-4:
            break
        h = np.sin(2 * np.pi * freq * k * t) * a
        if decay > 0:
            h *= np.exp(-decay * k * t)
        out += h
    return out


def reverb(x, sec=1.2, mix=0.25, hi=6000):
    ir = band(noise(sec), 200, hi) * env_exp(int(SR * sec), 5.0 / sec)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    n = len(x) + len(ir)
    wet = np.fft.irfft(np.fft.rfft(x, n) * np.fft.rfft(ir, n), n)
    out = np.zeros(n)
    out[: len(x)] += x * (1 - mix)
    out += wet * mix
    return out


def drive(x, k=2.0):
    return np.tanh(x * k) / np.tanh(k)


def fade(x, a=0.002, r=0.01):
    x = x.copy()
    na, nr = int(SR * a), int(SR * r)
    if na:
        x[:na] *= np.linspace(0, 1, na)
    if nr:
        x[-nr:] *= np.linspace(1, 0, nr)
    return x


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def at(x, sec, total):
    out = np.zeros(int(SR * total))
    i = int(SR * sec)
    seg = x[: max(0, len(out) - i)]
    out[i: i + len(seg)] += seg
    return out


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) + 1e-9
    return x * (peak / m)


def write_ogg(path, x, q=4):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.clip(x, -1, 1)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav = tmp.name
    with wave.open(wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", str(q), path], check=True)
    os.unlink(wav)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ---------------------------------------------------------------- effetti
def kick_body(f0=150, f1=45, sec=0.3, k=9):
    return np.sin(sweep(f0, f1, sec, 6)) * env_exp(int(SR * sec), k)


def sfx_colpo():           # TAP: colpo normale, secco
    body = np.sin(sweep(220, 90, 0.12, 5)) * env_exp(int(SR * 0.12), 30)
    click = band(noise(0.03), 1500, 9000) * env_exp(int(SR * 0.03), 160)
    return norm(fade(mix(body * 0.9, click * 0.6)), 0.75)


def sfx_colpo_forte():     # ZAP: colpo grosso, elettrico (la luce colorata)
    s = 0.24
    t = T(s)
    ph = sweep(1400, 180, s, 5) + 3 * np.sin(2 * np.pi * 37 * t)
    zap = np.sign(np.sin(ph)) * 0.35 + np.sin(ph) * 0.4
    zap = band(zap, 120, 7000) * env_exp(len(t), 14)
    body = kick_body(170, 60, 0.2, 18)
    crack = band(noise(0.05), 2000, 12000) * env_exp(int(SR * 0.05), 90)
    return norm(fade(drive(mix(zap, body * 0.9, crack * 0.5), 1.6)), 0.85)


def sfx_critico():         # BAM: critico, pesante e lucido
    s = 0.6
    body = kick_body(160, 38, 0.45, 7)
    crack = band(noise(0.12), 800, 10000) * env_exp(int(SR * 0.12), 35)
    t = T(s)
    ting = (np.sin(2 * np.pi * 2350 * t) + 0.5 * np.sin(2 * np.pi * 3520 * t)) * env_exp(len(t), 9) * 0.25
    x = drive(mix(body * 1.1, crack * 0.8, ting), 2.2)
    return norm(fade(reverb(x, 0.8, 0.18), 0.001, 0.08), 0.95)


def sfx_scudo():           # CLANG: scudo e parata, metallo
    s = 0.9
    t = T(s)
    f = 520
    parts = [(1.0, 1.0, 5), (2.76, 0.6, 7), (5.40, 0.35, 10), (8.93, 0.2, 14), (13.3, 0.1, 20)]
    m = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-k * t) for r, a, k in parts)
    click = band(noise(0.02), 3000, 14000) * env_exp(int(SR * 0.02), 200)
    return norm(fade(mix(m * 0.6, click * 0.8), 0.001, 0.1), 0.8)


def sfx_ferita():          # THUD: colpo subito da uno dei tuoi, sordo
    body = kick_body(110, 42, 0.3, 12)
    thump = band(noise(0.15), 60, 900) * env_exp(int(SR * 0.15), 25)
    return norm(fade(drive(mix(body, thump * 0.6), 1.5)), 0.85)


def sfx_cura():            # PLING: cura, due campanelli che salgono
    s = 0.8
    t = T(s)
    a = np.sin(2 * np.pi * midi(88) * t) * env_ad(len(t), 0.005, 6)
    b = at(np.sin(2 * np.pi * midi(95) * t) * env_ad(len(t), 0.005, 5), 0.08, s)
    sp = band(noise(s), 6000, 14000) * env_ad(len(t), 0.05, 8) * 0.08
    return norm(fade(reverb(mix(a, b * 0.8, sp), 0.9, 0.3), 0.001, 0.1), 0.6)


def sfx_schivata():        # SWISH: schivata, aria
    s = 0.28
    n = noise(s)
    t = T(s)
    # banda che sale: tre fette di rumore che si passano il testimone
    lo = band(n, 500, 1500) * np.exp(-((t - 0.07) / 0.05) ** 2)
    mid = band(n, 1500, 4000) * np.exp(-((t - 0.13) / 0.05) ** 2)
    hi = band(n, 4000, 9000) * np.exp(-((t - 0.19) / 0.05) ** 2)
    return norm(fade(lo + mid + hi), 0.55)


def sfx_break():           # KRAK: BREAK, il vetro della telecamera che salta + botta nei bassi
    s = 1.6
    out = np.zeros(int(SR * s))
    # schegge: tanti "ping" acuti casuali nei primi 0,45 s
    for _ in range(70):
        st = abs(rng.normal(0, 0.12))
        if st > 0.5:
            continue
        f = rng.uniform(2200, 8500)
        d = rng.uniform(0.03, 0.12)
        tt = T(d)
        p = np.sin(2 * np.pi * f * tt) * np.exp(-tt * rng.uniform(30, 70)) * rng.uniform(0.1, 0.35)
        out += at(p, st, s)
    crash = band(noise(0.5), 1500, 14000) * env_exp(int(SR * 0.5), 9)
    sub = np.sin(sweep(90, 28, 1.2, 3)) * env_ad(int(SR * 1.2), 0.004, 2.8)
    hit = kick_body(180, 50, 0.3, 10)
    x = mix(out, crash * 0.6, sub * 0.9, hit * 0.9)
    return norm(fade(reverb(drive(x, 1.4), 1.4, 0.22), 0.001, 0.2), 0.95)


def sfx_camera():          # CAM: cambio di telecamera, scatto + scarica statica (leggero: capita spesso)
    s = 0.16
    n = noise(s)
    gate = (rng.uniform(0, 1, int(s * 400)) > 0.45).astype(float)
    gate = np.repeat(gate, int(SR * s) // len(gate) + 1)[: int(SR * s)]
    st = band(n, 1800, 7000) * gate * env_exp(len(n), 18)
    click = band(noise(0.012), 2500, 12000) * env_exp(int(SR * 0.012), 300)
    return norm(fade(mix(st * 0.5, click)), 0.45)


def sfx_combo():           # +1 COMBO: un "blip" che il gioco alza di tono a ogni colpo
    s = 0.14
    t = T(s)
    a = square(midi(81), t, 0.7) * env_exp(len(t), 25)
    b = at(square(midi(88), t, 0.7) * env_exp(len(t), 22), 0.045, s)
    return norm(fade(mix(a, b)), 0.4)


def sfx_ko():              # K.O.: segnale perso, la nota scende e resta la statica
    s = 0.95
    t = T(s)
    tone = np.sin(sweep(900, 90, s, 2.5)) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 14 * t))) * env_exp(len(t), 3)
    st = band(noise(s), 1500, 8000) * np.clip((t - 0.25) / 0.2, 0, 1) * env_exp(len(t), 2.5) * 0.35
    return norm(fade(mix(tone * 0.6, st), 0.002, 0.15), 0.7)


def sfx_colpo_finale():    # colpo finale sul nemico: la botta piu' grossa del gioco, con coda lunga
    s = 2.2
    body = kick_body(140, 30, 0.9, 3.5)
    crack = band(noise(0.25), 400, 12000) * env_exp(int(SR * 0.25), 14)
    tail = band(noise(1.8), 2500, 12000) * env_exp(int(SR * 1.8), 2.2) * 0.25
    x = drive(mix(body * 1.2, crack, tail), 2.0)
    return norm(fade(reverb(x, 2.0, 0.3), 0.001, 0.3)[: int(SR * s)], 0.97)


def sfx_cutin():           # cut-in dell'ULTIMATE: soffio che sale e schiocca
    s = 0.75
    t = T(s)
    n = noise(s)
    rise = np.clip(t / 0.6, 0, 1) ** 2
    wh = (band(n, 800, 3000) * (1 - rise) + band(n, 3000, 10000) * rise) * rise * (t < 0.62)
    tone = np.sin(2 * np.pi * np.cumsum(200 * 8 ** np.minimum(t / 0.62, 1)) / SR)
    tone *= rise * (t < 0.62) * 0.25
    snap = at(mix(kick_body(200, 60, 0.12, 25), band(noise(0.04), 2000, 12000) * env_exp(int(SR * 0.04), 80) * 0.6), 0.62, s)
    return norm(fade(mix(wh * 0.7, tone, snap)), 0.75)


def sfx_turno():           # tocca a te: due note morbide
    s = 0.4
    t = T(s)
    a = saw(midi(76), t, 0.45) * env_ad(len(t), 0.004, 10)
    b = at(saw(midi(83), t, 0.45) * env_ad(len(t), 0.004, 8), 0.07, s)
    return norm(fade(reverb(mix(a, b), 0.6, 0.25), 0.001, 0.08), 0.4)


def sfx_ui_sposta():
    t = T(0.035)
    return norm(fade(np.sin(2 * np.pi * 1800 * t) * env_exp(len(t), 120)), 0.25)


def sfx_ui_ok():
    s = 0.12
    t = T(s)
    a = square(midi(84), t, 0.5) * env_exp(len(t), 35)
    b = at(square(midi(91), t, 0.5) * env_exp(len(t), 30), 0.04, s)
    return norm(fade(mix(a, b)), 0.35)


def sfx_ui_indietro():
    s = 0.12
    t = T(s)
    a = square(midi(84), t, 0.5) * env_exp(len(t), 35)
    b = at(square(midi(77), t, 0.5) * env_exp(len(t), 30), 0.04, s)
    return norm(fade(mix(a, b)), 0.3)


def sfx_vittoria():        # fine battaglia vinta: arpeggio che sale e accordo aperto
    s = 3.2
    out = np.zeros(int(SR * s))
    notes = [69, 73, 76, 81, 85, 88]          # La maggiore che sale
    for i, n in enumerate(notes):
        t = T(0.5)
        out += at(saw(midi(n), t, 0.6, decay=4) * env_ad(len(t), 0.003, 6) * 0.5, i * 0.085, s)
    t = T(2.6)
    chord = sum(saw(midi(n), t, 0.55, detune=d) for n in (57, 64, 69, 73, 76) for d in (-7, 7)) * env_ad(len(t), 0.02, 1.3)
    out += at(chord * 0.18, 0.55, s)
    out += at(kick_body(150, 45, 0.4, 7) * 0.6, 0.55, s)
    out += at(band(noise(1.5), 4000, 14000) * env_exp(int(SR * 1.5), 2.5) * 0.12, 0.55, s)
    return norm(fade(reverb(out, 1.4, 0.25)[: int(SR * s)], 0.001, 0.4), 0.8)


def sfx_sconfitta():
    s = 2.6
    out = np.zeros(int(SR * s))
    for i, n in enumerate([69, 65, 62, 57]):
        t = T(0.9)
        out += at(saw(midi(n), t, 0.5, detune=-12) * env_ad(len(t), 0.01, 3) * 0.5, i * 0.28, s)
    out += at(band(noise(1.2), 1500, 7000) * env_ad(int(SR * 1.2), 0.3, 2.5) * 0.15, 1.0, s)
    return norm(fade(reverb(out, 1.4, 0.3)[: int(SR * s)], 0.001, 0.4), 0.65)


# ---------------------------------------------------------------- musica a strati
# Quattro strati lunghi uguale, suonati insieme e sempre a tempo (AudioStreamSynchronized): il gioco alza il volume
# degli strati col COMBO. base = sempre; ritmo = da 2 COMBO; arpeggio = da 3; melodia = da 5 (e col BREAK).
def music(name, bpm, chords, scale_root, lead):
    beat = 60.0 / bpm
    bars = len(chords) * 2
    L = bars * 4 * beat
    tail = 2.0
    N = int(SR * (L + tail))

    def place(buf, x, sec):
        i = int(SR * sec)
        seg = x[: N - i]
        buf[i: i + len(seg)] += seg

    def wrap(buf):          # la coda di fine giro ricade all'inizio: il giro si chiude senza scatto
        n = int(SR * L)
        out = buf[:n].copy()
        out[: N - n] += buf[n:]
        return out

    base = np.zeros(N)
    ritmo = np.zeros(N)
    arp = np.zeros(N)
    mel = np.zeros(N)
    # --- base: tappeto (accordi) + basso che pulsa in ottavi, con "respiro" a ogni battito
    for ci, ch in enumerate(chords):
        st = ci * 8 * beat
        d = 8 * beat
        t = T(d + 0.6)
        e = np.minimum(1, t / 0.25) * np.clip((d + 0.5 - t) / 0.5, 0, 1)
        pad = sum(saw(midi(n), t, 0.42, detune=dt) for n in ch for dt in (-9, 0, 9)) * e
        place(base, pad * 0.055, st)
        root = ch[0] - 12
        for k in range(16):
            tb = T(beat / 2)
            b = (np.sin(2 * np.pi * midi(root) * tb) + 0.35 * saw(midi(root), tb, 0.35)) * env_ad(len(tb), 0.006, 5)
            place(base, b * 0.32, st + k * beat / 2)
    # respiro: il tappeto si abbassa sul battito (come se ci fosse la cassa anche quando non c'e')
    t_all = np.arange(N) / SR
    pump = 0.6 + 0.4 * np.clip(((t_all % beat) / beat) * 3, 0, 1)
    base *= pump
    # --- ritmo: cassa in quattro, rullante sul 2 e 4, charleston in sedicesimi
    for bi in range(bars * 4):
        tb = bi * beat
        place(ritmo, kick_body(150, 45, 0.32, 9) * 0.75, tb)
        if bi % 2 == 1:
            sn = band(noise(0.2), 1200, 7000) * env_exp(int(SR * 0.2), 22) * 0.45
            sn += np.sin(2 * np.pi * 190 * T(0.2)) * env_exp(int(SR * 0.2), 30) * 0.3
            place(ritmo, sn, tb)
        for h in range(4):
            hat = band(noise(0.04), 7000, 16000) * env_exp(int(SR * 0.04), 90 if h % 2 == 0 else 140)
            place(ritmo, hat * (0.16 if h == 2 else 0.09), tb + h * beat / 4)
    # --- arpeggio: sedicesimi sulle note dell'accordo, pizzicati, con eco in terzine di ottavo puntato
    for ci, ch in enumerate(chords):
        tones = [ch[0], ch[1], ch[2], ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[0] + 12, ch[2]]
        for k in range(32):
            n = tones[k % len(tones)] + 12
            tb = T(beat / 2)
            p = square(midi(n), tb, 0.75, decay=7) * env_ad(len(tb), 0.002, 14)
            place(arp, p * 0.3, ci * 8 * beat + k * beat / 4)
    echo = np.zeros(N)
    dly = int(SR * beat * 0.75)
    for r in range(1, 4):
        echo[dly * r:] += arp[: N - dly * r] * (0.38 ** r)
    arp = arp + echo
    # --- melodia: frase del protagonista + piatto all'inizio di ogni giro di accordi
    for ci, ch in enumerate(chords):
        place(mel, band(noise(1.6), 4500, 15000) * env_exp(int(SR * 1.6), 2.2) * 0.12, ci * 8 * beat)
    for (stb, durb, n) in lead:
        d = durb * beat
        t = T(d + 0.15)
        vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.15) / 0.2, 0, 1)
        f = midi(n + scale_root)
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        v = sum(np.sin(ph * k) / k * (0.7 ** (k - 1)) for k in range(1, 10))
        e = np.minimum(1, t / 0.01) * np.clip((d + 0.12 - t) / 0.12, 0, 1)
        place(mel, v * e * 0.22, stb * beat)
    mel = reverb(mel, 1.0, 0.25)[:N]
    stems = {"base": wrap(base), "ritmo": wrap(ritmo), "arpeggio": wrap(arp), "melodia": wrap(mel)}
    # tutti insieme non devono saturare: stesso fattore per i quattro strati
    k = 0.92 / (np.max(np.abs(sum(stems.values()))) + 1e-9)
    for sname, x in stems.items():
        write_ogg(os.path.join(OUT, "musica", "%s_%s.ogg" % (name, sname)), x * k, q=3)
    print("  musica %s: %.2f s, %d bpm" % (name, L, bpm))


# melodie: (battito d'inizio, durata in battiti, semitono sopra la tonica)
LEAD_NEMICO = [
    (0, 1.5, 12), (1.5, 0.5, 15), (2, 1, 19), (3, 1, 17), (4, 2, 15), (6, 1, 14), (7, 1, 12),
    (8, 1.5, 8), (9.5, 0.5, 10), (10, 1, 12), (11, 1, 15), (12, 3, 12), (15, 1, 10),
    (16, 1.5, 7), (17.5, 0.5, 10), (18, 1, 12), (19, 1, 15), (20, 2, 19), (22, 2, 17),
    (24, 1.5, 14), (25.5, 0.5, 15), (26, 1, 17), (27, 1, 19), (28, 4, 22),
]
LEAD_BOSS = [
    (0, 1, 12), (1, 1, 13), (2, 2, 12), (4, 1, 15), (5, 1, 13), (6, 2, 12),
    (8, 1, 10), (9, 1, 12), (10, 2, 13), (12, 2, 15), (14, 2, 17),
    (16, 1, 19), (17, 1, 18), (18, 2, 17), (20, 1, 15), (21, 1, 13), (22, 2, 12),
    (24, 1, 13), (25, 1, 15), (26, 1, 17), (27, 1, 18), (28, 4, 19),
]

SFX = {
    "colpo": sfx_colpo, "colpo_forte": sfx_colpo_forte, "critico": sfx_critico, "scudo": sfx_scudo,
    "ferita": sfx_ferita, "cura": sfx_cura, "schivata": sfx_schivata, "break": sfx_break,
    "camera": sfx_camera, "combo": sfx_combo, "ko": sfx_ko, "colpo_finale": sfx_colpo_finale,
    "cutin": sfx_cutin, "turno": sfx_turno, "ui_sposta": sfx_ui_sposta, "ui_ok": sfx_ui_ok,
    "ui_indietro": sfx_ui_indietro, "vittoria": sfx_vittoria, "sconfitta": sfx_sconfitta,
}


def main():
    only = sys.argv[1:]
    for name, fn in SFX.items():
        if only and name not in only:
            continue
        write_ogg(os.path.join(OUT, name + ".ogg"), fn())
        print("  effetto", name)
    if not only or "musica" in only:
        # nemici: La minore, 128 bpm, Am F C G (notte, si corre)
        music("battaglia", 128, [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]], 57, LEAD_NEMICO)
        # boss: Re minore, 140 bpm, Dm Bb Gm A (piu' scuro, la dominante maggiore tira)
        music("boss", 140, [[50, 53, 57], [46, 50, 53], [43, 46, 50], [45, 49, 52]], 50, LEAD_BOSS)


if __name__ == "__main__":
    main()
