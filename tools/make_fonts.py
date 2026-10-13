#!/usr/bin/env python3
"""Prepara i font del gioco dagli zip di Google Fonts: tiene solo i caratteri che servono (latino + simboli) per
non appesantire il pacchetto. Merriweather ha un Nome Riservato (licenza OFL): la copia ridotta si chiama "OdispelSerif".
Uso: python3 tools/make_fonts.py cartella_con_Archivo_Black_Merriweather_Roboto  assets/fonts
"""
import os
import sys
from fontTools import subset
from fontTools.ttLib import TTFont

UNICODES = "U+0020-007E,U+00A0-00FF,U+2013-2014,U+2018-201D,U+2022,U+2026,U+20AC,U+2190-2193,U+2212,U+25B2,U+25B6,U+25BC,U+2605,U+2713"
JOBS = [
    ("Merriweather/static/Merriweather_24pt_SemiCondensed-Bold.ttf", "OdispelSerif-Bold.ttf", "OdispelSerif"),
    ("Archivo_Black/ArchivoBlack-Regular.ttf", "ArchivoBlack-Regular.ttf", None),
    ("Roboto/static/Roboto-Bold.ttf", "Roboto-Bold.ttf", None),
]


def main(src, dst):
    os.makedirs(dst, exist_ok=True)
    for rel, out, rename in JOBS:
        opts = subset.Options()
        opts.layout_features = ["kern", "liga", "locl", "mark", "mkmk", "tnum", "lnum"]
        opts.name_IDs = [1, 2, 3, 4, 5, 6, 16, 17]
        opts.notdef_outline = True
        font = TTFont(os.path.join(src, rel))
        sub = subset.Subsetter(opts)
        sub.populate(unicodes=subset.parse_unicodes(UNICODES))
        sub.subset(font)
        if rename:
            style = out.split("-")[1].split(".")[0]
            for rec in font["name"].names:
                if rec.nameID in (1, 16):
                    rec.string = rename
                elif rec.nameID in (4,):
                    rec.string = rename + " " + style
                elif rec.nameID == 6:
                    rec.string = rename + "-" + style
        font.save(os.path.join(dst, out))
        print(out, os.path.getsize(os.path.join(dst, out)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
