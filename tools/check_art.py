#!/usr/bin/env python3
"""Controlla una cartella di grafiche di ODISPEL prima di consegnarla.

Uso:  python3 tools/check_art.py <cartella_art> [--strict]
      (la cartella contiene characters/, bosses/, backgrounds/, logo.png)
Serve Pillow (pip install pillow). Esce con codice 1 se ci sono ERRORI.
Controlla: file presenti, nomi, PNG con trasparenza, proporzioni, personaggio ancorato in basso,
espressioni della stessa misura, peso dei file.
"""
import os
import sys
from PIL import Image

CHARS = {  # id: (nome, colore, rarita')
    "kira": "viola", "dax": "rosso", "elle": "verde", "bruno": "blu", "nova": "giallo", "mira": "blu", "rex": "rosso",
    "ivo": "blu", "sera": "verde", "eco": "giallo", "tana": "giallo", "nico": "rosso", "dafne": "verde", "angela": "giallo",
}
BOSSES = ["distributore", "semaforo", "tombino", "cabina", "ascensore", "manichino", "orologio", "specchio"]
EXPR = ["neutral", "happy", "angry", "sad", "surprised", "hurt"]
DIALOGUE_BG = ["cabina", "incrocio", "strada_notte", "tombino", "torre", "torre_orologio", "vetrina"]

# nome file -> (larghezza, altezza consigliate, tipo)   tipo: "figura" (trasparente, ancorata in basso), "quadrata", "scena" (puo' essere piena), "strato"
SPEC_CHAR = {
    **{e + ".png": (1000, 1400, "figura") for e in EXPR},
    "splash.png": (1200, 1600, "figura"),
    "cutin.png": (1600, 900, "figura"),
    "icon.png": (256, 256, "quadrata"),
    "battle.png": (480, 640, "figura"),
}
SPEC_BOSS = {"battle.png": (1000, 1000, "figura"), "hurt.png": (1000, 1000, "figura"), "portrait.png": (1000, 1400, "figura")}
MAX_BYTES = 2_500_000

errors, warnings, ok = [], [], 0


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def check_image(path, rel, spec, optional=False):
    global ok
    if not os.path.isfile(path):
        (warn if optional else err)("MANCA  " + rel)
        return None
    try:
        img = Image.open(path)
        img.load()
    except Exception as e:  # noqa
        err("ILLEGGIBILE  %s (%s)" % (rel, e))
        return None
    w, h, kind = spec
    if img.format != "PNG":
        err("%s non e' un PNG" % rel)
    if img.mode == "P" and "transparency" in img.info:
        img = img.convert("RGBA")          # PNG a 256 colori con trasparenza: va bene (e' piu' leggero)
    if img.mode != "RGBA":
        err("%s: serve PNG con canale alfa (RGBA), trovato %s" % (rel, img.mode))
        img = img.convert("RGBA")
    if abs(img.width / img.height - w / h) > 0.03:
        err("%s: proporzioni %dx%d, attese circa %dx%d" % (rel, img.width, img.height, w, h))
    if max(img.size) > 2048:
        warn("%s: lato %d > 2048, il gioco lo riduce da solo (consegna gia' ridotto)" % (rel, max(img.size)))
    if img.width < w * 0.5:
        warn("%s: piccolo (%dx%d, consigliato %dx%d)" % (rel, img.width, img.height, w, h))
    if os.path.getsize(path) > MAX_BYTES:
        warn("%s: pesa %.1f MB (obiettivo < 2.5 MB: ottimizza la PNG)" % (rel, os.path.getsize(path) / 1e6))
    alpha = img.getchannel("A")
    if kind in ("figura", "quadrata") and kind == "figura":
        corners = [alpha.getpixel(p) for p in [(0, 0), (img.width - 1, 0)]]
        if max(corners) > 8:
            err("%s: gli angoli in alto non sono trasparenti (serve sfondo trasparente)" % rel)
        bbox = alpha.point(lambda v: 255 if v > 16 else 0).getbbox()
        if bbox is None:
            err("%s: immagine completamente trasparente" % rel)
        else:
            bottom_gap = img.height - bbox[3]
            if bottom_gap > img.height * 0.04 and not rel.endswith("cutin.png"):
                err("%s: la figura non tocca il bordo basso (vuoto di %d px): i piedi/busto devono stare sul bordo inferiore" % (rel, bottom_gap))
            if bbox[0] <= 1 or bbox[2] >= img.width - 1:
                warn("%s: la figura tocca i bordi laterali (lascia un po' d'aria)" % rel)
    if kind == "quadrata" and img.width != img.height:
        err("%s: l'icona deve essere quadrata" % rel)
    ok += 1
    return img


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    root = sys.argv[1]
    strict = "--strict" in sys.argv
    for cid in CHARS:
        sizes = set()
        for name, spec in SPEC_CHAR.items():
            img = check_image(os.path.join(root, "characters", cid, name), "characters/%s/%s" % (cid, name), spec)
            if img is not None and name.replace(".png", "") in EXPR:
                sizes.add(img.size)
        if len(sizes) > 1:
            err("characters/%s: le 6 espressioni devono avere la STESSA misura, trovate %s" % (cid, sorted(sizes)))
    for b in BOSSES:
        for name, spec in SPEC_BOSS.items():
            check_image(os.path.join(root, "bosses", b, name), "bosses/%s/%s" % (b, name), spec, optional=(name == "hurt.png"))
    for i in range(1, 5):
        check_image(os.path.join(root, "backgrounds", "battle", "layer_%d.png" % i), "backgrounds/battle/layer_%d.png" % i, (1600, 900, "strato"))
    check_image(os.path.join(root, "backgrounds", "hub.png"), "backgrounds/hub.png", (1920, 1080, "scena"))
    check_image(os.path.join(root, "logo.png"), "logo.png", (1000, 280, "logo"))
    for n in DIALOGUE_BG:
        check_image(os.path.join(root, "backgrounds", "dialogue", n + ".png"), "backgrounds/dialogue/%s.png" % n, (1920, 1080, "scena"), optional=True)
    for line in errors:
        print("ERRORE   ", line)
    for line in warnings:
        print("avviso   ", line)
    print("\nfile controllati: %d   errori: %d   avvisi: %d" % (ok, len(errors), len(warnings)))
    return 1 if errors or (strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
