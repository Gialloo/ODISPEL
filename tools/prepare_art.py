#!/usr/bin/env python3
"""Prepara le immagini prodotte da un'IA per ODISPEL: toglie lo sfondo a tinta unita, porta alla misura giusta, alleggerisce.

Uso:
  # una immagine: toglie lo sfondo verde, la porta a 1000x1400 ancorata in basso e la salva
  python3 tools/prepare_art.py file in.png out.png --size 1000x1400 [--key 00ff00] [--anchor bottom|center]

  # tutta una cartella (stessa regola per ogni PNG, in base al nome del file: neutral, happy, splash, cutin, icon, battle...)
  python3 tools/prepare_art.py cartella entrata/ uscita/ [--key 00ff00]

  # rende identico il corpo delle espressioni: prende il corpo da neutral.png e cambia solo il volto
  python3 tools/prepare_art.py facce art/characters/kira

Serve: pip install pillow numpy
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

EXPR = ["happy", "angry", "sad", "surprised", "hurt"]
SIZES = {  # nome file -> (larghezza, altezza, ancoraggio)
    "neutral": (1000, 1400, "bottom"), "happy": (1000, 1400, "bottom"), "angry": (1000, 1400, "bottom"),
    "sad": (1000, 1400, "bottom"), "surprised": (1000, 1400, "bottom"), "hurt": (1000, 1400, "bottom"),
    "portrait": (1000, 1400, "bottom"),
    "splash": (1200, 1600, "bottom"), "cutin": (1600, 900, "center"), "icon": (256, 256, "center"),
    "battle": (480, 640, "bottom"),
}
MAX_BYTES = 1_500_000


def parse_color(text):
    text = text.lstrip("#")
    return tuple(int(text[i:i + 2], 16) for i in (0, 2, 4))


def has_real_alpha(img):
    a = np.asarray(img.getchannel("A"))
    return (a < 250).mean() > 0.05


def key_out(img, key, tol_low=40.0, tol_high=110.0):
    """Sfondo a tinta unita -> trasparenza morbida, con recupero del colore sui bordi (niente alone)."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    k = np.array(key, dtype=np.float32)
    dist = np.sqrt(((rgb - k) ** 2).sum(axis=2))
    alpha = np.clip((dist - tol_low) / (tol_high - tol_low), 0.0, 1.0)
    # "smiscela" il colore della chiave dai pixel di bordo: c = (p - (1-a)*k) / a
    a3 = np.maximum(alpha, 1e-3)[..., None]
    mixed = (rgb - (1.0 - alpha)[..., None] * k) / a3
    edge = (alpha > 0) & (alpha < 1)
    out = np.where(edge[..., None], mixed, rgb)
    # nei pixel opachi vicino al bordo si toglie il riflesso della chiave (spill)
    band = Image.fromarray((alpha < 1.0).astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(7))
    near = np.asarray(band) > 0
    if key[1] > key[0] and key[1] > key[2]:           # verde
        cap = np.maximum(out[..., 0], out[..., 2]) + 6.0
        out[..., 1] = np.where(near, np.minimum(out[..., 1], cap), out[..., 1])
    elif key[0] > key[1] and key[2] > key[1]:         # magenta
        cap = out[..., 1] + 40.0
        out[..., 0] = np.where(near, np.minimum(out[..., 0], np.maximum(cap, out[..., 2])), out[..., 0])
    out = np.clip(out, 0, 255).astype(np.uint8)
    res = np.dstack([out, (alpha * 255).astype(np.uint8)])
    return Image.fromarray(res, "RGBA")


def fit(img, size, anchor):
    w, h = size
    iw, ih = img.size
    if abs((iw / ih) / (w / h) - 1.0) < 0.15:         # proporzioni vicine: riempie (taglia i margini in eccesso)
        k = max(w / iw, h / ih)
        r = img.resize((max(1, round(iw * k)), max(1, round(ih * k))), Image.LANCZOS)
        left = (r.width - w) // 2
        top = r.height - h if anchor == "bottom" else (r.height - h) // 2
        return r.crop((left, top, left + w, top + h))
    k = min(w / iw, h / ih)                           # altrimenti sta tutta dentro, con bordi trasparenti
    r = img.resize((max(1, round(iw * k)), max(1, round(ih * k))), Image.LANCZOS)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = (w - r.width) // 2
    y = h - r.height if anchor == "bottom" else (h - r.height) // 2
    canvas.paste(r, (x, y))
    return canvas


def save_light(img, path):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    img.save(path, optimize=True)
    if os.path.getsize(path) > MAX_BYTES:
        q = img.quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.FLOYDSTEINBERG)
        q.save(path, optimize=True)
    return os.path.getsize(path)


def prepare(src, dst, size, key, anchor):
    img = Image.open(src).convert("RGBA")
    if has_real_alpha(img):
        pass
    elif key is not None:
        img = key_out(img, key)
    else:
        print("  attenzione: %s non ha trasparenza e non e' stata data --key" % os.path.basename(src))
    out = fit(img, size, anchor)
    n = save_light(out, dst)
    print("%s -> %s  %dx%d  %.2f MB" % (os.path.basename(src), dst, size[0], size[1], n / 1e6))


def faces(folder):
    base_path = os.path.join(folder, "neutral.png")
    if not os.path.isfile(base_path):
        sys.exit("manca " + base_path)
    base = Image.open(base_path).convert("RGBA")
    b = np.asarray(base).astype(np.float32)
    H, W = b.shape[:2]
    os.makedirs(os.path.join(folder, "_originali"), exist_ok=True)
    for name in EXPR:
        p = os.path.join(folder, name + ".png")
        if not os.path.isfile(p):
            print("salto", name, "(manca)")
            continue
        raw = Image.open(p).convert("RGBA")
        if raw.size != base.size:
            raw = raw.resize(base.size, Image.LANCZOS)
        e = np.asarray(raw).astype(np.float32)
        diff = np.abs(e[..., :3] - b[..., :3]).max(axis=2) * (np.minimum(e[..., 3], b[..., 3]) / 255.0)
        diff = np.maximum(diff, np.abs(e[..., 3] - b[..., 3]))
        m = (diff > 38).astype(np.uint8) * 255
        m[int(H * 0.62):, :] = 0                               # solo testa e capelli: il corpo resta quello di neutral
        mask = Image.fromarray(m).filter(ImageFilter.MaxFilter(21)).filter(ImageFilter.GaussianBlur(10))
        mm = (np.asarray(mask).astype(np.float32) / 255.0)[..., None]
        out = b * (1.0 - mm) + e * mm
        res = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")
        res.save(os.path.join(folder, "_originali", name + ".png"), optimize=True) if False else None
        raw.save(os.path.join(folder, "_originali", name + ".png"), optimize=True)
        n = save_light(res, p)
        print("%s: corpo uguale a neutral, volto nuovo  (%.2f MB, area cambiata %.0f%%)" % (name, n / 1e6, 100.0 * float((mm > 0.5).mean())))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["file", "cartella", "facce"])
    ap.add_argument("a")
    ap.add_argument("b", nargs="?")
    ap.add_argument("--size", default="1000x1400")
    ap.add_argument("--key", default=None, help="colore dello sfondo da togliere, es. 00ff00")
    ap.add_argument("--anchor", default="bottom", choices=["bottom", "center"])
    args = ap.parse_args()
    key = parse_color(args.key) if args.key else None
    if args.cmd == "facce":
        faces(args.a)
    elif args.cmd == "file":
        w, h = (int(v) for v in args.size.lower().split("x"))
        prepare(args.a, args.b, (w, h), key, args.anchor)
    else:
        for f in sorted(os.listdir(args.a)):
            stem, ext = os.path.splitext(f)
            if ext.lower() != ".png" or stem not in SIZES:
                print("salto", f, "(nome non riconosciuto)")
                continue
            w, h, anchor = SIZES[stem]
            prepare(os.path.join(args.a, f), os.path.join(args.b, f), (w, h), key, anchor)


if __name__ == "__main__":
    main()
