#!/usr/bin/env python3
# Prepara le immagini del MENU A VENTAGLIO disegnato a mano dall'autore (Procreate, 7/11/2026).
# Uso: python3 tools/prepara_ventaglio.py <cartella con i disegni originali 1536x2048>
#   ventaglio_rosso.png / _blu / _viola / _verde  -> il ventaglio senza personaggio, ULTIMATE nel colore del personaggio
#   lance_senza_scritte.png + lance_livelli.png    -> il busto di Lance (la sagoma nera del secondo fa da ritaglio)
# Gli altri busti (Rio, Nox, Saul) nascono dai ritratti ufficiali dell'HUD (assets/portraits/hud/<id>_hud.png) ridotti a
# tre toni come quello di Lance: chiaro = colore pieno, mezzo = colore scuro, scuro = nero. Sono SEGNAPOSTO finche'
# l'autore non li disegna a mano (stessa tela 1536x2048, stessa posizione del busto di Lance).
# Tutto e' ridotto a 0,6 e riportato sulla tela comune (52, 560)-(1509, 1711) del foglio: il gioco li sovrappone e basta.
import sys, os
from PIL import Image, ImageDraw

SRC = sys.argv[1]
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "hud_ventaglio")
os.makedirs(OUT, exist_ok=True)
K = 0.6
CANVAS = (52, 560, 1509, 1711)              # zona usata del foglio (busto + ventaglio)
BUST = (52, 612, 670, 1375)                  # riquadro del busto di Lance sul foglio
COL = {"lance": "rosso", "nox": "blu", "rio": "viola", "saul": "verde"}   # colori di battaglia (menu.gd, STILE_VISIVO)
# ritaglio di ogni ritratto ufficiale (1536x2048) che finisce nel riquadro del busto: testa e spalle, volto a destra
CROP = {"rio": (100, 120, 1536, 1880), "nox": (250, 300, 1536, 1876), "saul": (0, 40, 1400, 1756)}


def find(name):
    for f in os.listdir(SRC):
        if f.endswith(name):
            return os.path.join(SRC, f)
    raise SystemExit("manca " + name)


def scaled(im):
    return im.resize((round(im.width * K), round(im.height * K)), Image.LANCZOS)


# 1) ventagli
for c in ["rosso", "blu", "viola", "verde"]:
    im = Image.open(find("ventaglio_%s.png" % c)).convert("RGBA").crop(CANVAS)
    scaled(im).save(os.path.join(OUT, "ventaglio_%s.png" % c), optimize=True)
    print("ventaglio", c)

# 2) busto di Lance: il disegno senza scritte ritagliato con la sagoma del livello nero
full = Image.open(find("lance_senza_scritte.png")).convert("RGBA")
sil = Image.open(find("lance_livelli.png")).convert("RGBA").getchannel("A")
bust = full.copy()
bust.putalpha(sil)
bust = bust.crop(BUST)
scaled(bust).save(os.path.join(OUT, "busto_lance.png"), optimize=True)
mask_lance = bust.getchannel("A")
print("busto lance", bust.size)

# 3) busti segnaposto dagli altri ritratti, in tre toni come Lance
red = Image.open(find("ventaglio_rosso.png")).convert("RGBA")
for cid, (x0, y0, x1, y1) in CROP.items():
    fan = Image.open(find("ventaglio_%s.png" % COL[cid])).convert("RGBA")
    base = fan.getpixel((1000, 1350))[:3]                     # colore della lama ULTIMATE
    hi = tuple(int(v * 0.9) for v in base)                    # come il volto di Lance (220 su 245)
    mid = tuple(int(v * 0.59) for v in base)                  # come la camicia di Lance (144 su 245)
    src = Image.open(os.path.join(ROOT, "assets", "portraits", "hud", "%s_hud.png" % cid)).convert("RGBA").crop((x0, y0, x1, y1))
    w, h = BUST[2] - BUST[0], BUST[3] - BUST[1]
    src = src.resize((w, h), Image.LANCZOS)
    px = src.load()
    out = Image.new("RGBA", (w, h))
    po = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 40:
                continue
            L = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            c = hi if L > 0.55 else (mid if L > 0.3 else (8, 6, 8))
            po[x, y] = c + (255,)
    # taglio in basso storto come il busto di Lance (dal foglio: (190,1341) -> (620,1298))
    cut = Image.new("L", (w, h), 255)
    ImageDraw.Draw(cut).polygon([(0, 1341 - BUST[1] + 8), (w, 1298 - BUST[1] - 4), (w, h), (0, h)], fill=0)
    a = out.getchannel("A")
    out.putalpha(Image.composite(a, Image.new("L", (w, h), 0), cut))
    scaled(out).save(os.path.join(OUT, "busto_%s.png" % cid), optimize=True)
    print("busto", cid)
