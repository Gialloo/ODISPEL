"""Crea art_templates/: un PNG segnaposto per ogni grafica, col nome e la misura giusti.
Uso: python tools/make_art_templates.py   (serve Pillow: pip install pillow)
"""
import os
from PIL import Image, ImageDraw

CHARS = ["kira", "dax", "elle", "bruno"]
BOSSES = ["distributore", "semaforo", "tombino", "cabina"]
EXPR = ["neutral", "happy", "angry", "sad", "surprised", "hurt"]
OUT = os.path.join(os.path.dirname(__file__), "..", "art_templates")


def make(rel, size, color):
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, size[0] - 3, size[1] - 3], outline=color + (255,), width=4)
    d.line([0, 0, size[0], size[1]], fill=color + (120,), width=2)
    d.line([0, size[1], size[0], 0], fill=color + (120,), width=2)
    d.text((16, 16), rel.replace("\\", "/") + "  %dx%d" % size, fill=(255, 255, 255, 255))
    img.save(path)


for c in CHARS:
    for e in EXPR:
        make("characters/%s/%s.png" % (c, e), (1000, 1400), (124, 240, 255))
    make("characters/%s/splash.png" % c, (1200, 1600), (255, 45, 85))
    make("characters/%s/cutin.png" % c, (1600, 900), (255, 45, 85))
    make("characters/%s/icon.png" % c, (256, 256), (255, 210, 95))
    make("characters/%s/battle.png" % c, (480, 640), (107, 255, 176))
for b in BOSSES:
    make("bosses/%s/battle.png" % b, (1000, 1000), (255, 45, 85))
    make("bosses/%s/hurt.png" % b, (1000, 1000), (255, 255, 255))
    make("bosses/%s/portrait.png" % b, (1000, 1400), (255, 45, 85))
for i in range(1, 5):
    make("backgrounds/battle/layer_%d.png" % i, (1400, 800), (42, 138, 154))
make("logo.png", (1000, 280), (255, 45, 85))
make("backgrounds/hub.png", (1920, 1080), (42, 138, 154))
make("backgrounds/dialogue/strada_notte.png", (1920, 1080), (42, 138, 154))
print("creati i modelli in", os.path.abspath(OUT))
