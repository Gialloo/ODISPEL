#!/usr/bin/env python3
# Confronta due PNG pixel per pixel (regressione congelata dell'HUD, HUD Combat 2.0, 7/11/2026).
# Uso: python3 -I tools/confronta_png.py a.png b.png [differenze.png]
# Stampa quanti pixel cambiano e il rettangolo che li contiene; esce con 1 se c'e' anche un solo pixel diverso.
import sys
from PIL import Image, ImageChops

a = Image.open(sys.argv[1]).convert("RGB")
b = Image.open(sys.argv[2]).convert("RGB")
if a.size != b.size:
    print("MISURE DIVERSE", a.size, b.size)
    sys.exit(1)
d = ImageChops.difference(a, b)
box = d.getbbox()
if box:
    r, g, bl = (c.point(lambda v: 1 if v else 0) for c in d.split())
    n = ImageChops.lighter(ImageChops.lighter(r, g), bl).histogram()[1]   # pixel con almeno un canale diverso
else:
    n = 0
print("pixel diversi: %d su %d%s" % (n, a.size[0] * a.size[1], ("  zona %s" % (box,)) if box else ""))
if box and len(sys.argv) > 3:
    d.point(lambda v: 255 if v else 0).save(sys.argv[3])
sys.exit(1 if n else 0)
