#!/usr/bin/env python3
"""Rifinisce un ritratto 2D disegnato a mano per l'HUD (stessa ricetta del ritratto di Rio approvato dall'autore).

1. toglie i puntini staccati dal disegno (macchioline e residui della gomma attorno alla sagoma);
2. aggiunge il contorno d'inchiostro #120a1c di 12 px attorno alla sagoma (sulla tela 1536x2048), con il bordo morbido;
3. se serve rimpicciolisce (le varianti usano 768x1024: sul telefono il ritratto e' alto ~705 px, cosi' pesano un quarto).

Uso:
  python3 tools/rifinisci_ritratto.py ENTRATA.png USCITA.png [--larghezza 768] [--volto USCITA_VOLTO.png]

--volto ritaglia anche il volto piccolo 512x512 per la fila della squadra (occhi a y ~200, come chiede la guida).
Serve: pip install pillow numpy scipy
"""
import argparse

import numpy as np
from PIL import Image
from scipy import ndimage as nd

INK = (0x12, 0x0A, 0x1C)
CONTORNO = 12.0          # px sulla tela 1536x2048 (autore, 2/11/2026: «contorno di Rio a 12 px»)
MIN_PEZZO = 3000         # pezzi staccati piu' piccoli di cosi' (in px) sono sporco, non disegno
# Volto di Rio sulla tela 1536x2048: quadrato attorno agli occhi (occhio a ~ (770, 820)).
VOLTO = (480, 600, 1060, 1180)


def rifinisci(src: Image.Image) -> Image.Image:
    a = np.asarray(src.convert("RGBA")).astype(np.float32)
    alpha = a[..., 3]
    # 1) puntini staccati: si tengono solo i pezzi grandi
    lab, n = nd.label(alpha > 0, structure=np.ones((3, 3)))
    if n > 1:
        sizes = nd.sum(np.ones_like(alpha), lab, range(1, n + 1))
        keep = np.zeros(n + 1, dtype=bool)
        keep[1:] = sizes >= MIN_PEZZO
        a[~keep[lab]] = 0.0
        alpha = a[..., 3]
    # 2) contorno: distanza dalla sagoma, bordo morbido di 1 px
    sil = alpha > 127
    dist = nd.distance_transform_edt(~sil)
    ring = np.clip(CONTORNO + 0.5 - dist, 0.0, 1.0)
    out = np.zeros_like(a)
    fa = alpha / 255.0
    ra = np.maximum(ring, fa)
    for c in range(3):
        # il disegno sopra all'inchiostro (operatore "over")
        num = a[..., c] * fa + INK[c] * ring * (1.0 - fa)
        out[..., c] = np.where(ra > 0, num / np.maximum(ra, 1e-6), 0.0)
    out[..., 3] = ra * 255.0
    return Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGBA")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("entrata")
    p.add_argument("uscita")
    p.add_argument("--larghezza", type=int, default=0)
    p.add_argument("--volto", default="")
    k = p.parse_args()
    im = rifinisci(Image.open(k.entrata))
    if k.volto:
        im.crop(VOLTO).resize((512, 512), Image.LANCZOS).save(k.volto, optimize=True)
    if k.larghezza and k.larghezza < im.width:
        im = im.resize((k.larghezza, round(im.height * k.larghezza / im.width)), Image.LANCZOS)
    im.save(k.uscita, optimize=True)


if __name__ == "__main__":
    main()
