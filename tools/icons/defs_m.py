import math
from lib import *

M_ = []

FACTION_COLORS = {"libracorp": "#7cf0ff", "rondini": "#f2fdff", "magabondi": "#ffd25f", "kairos": "#ff2d55"}


def mk(detail, sw):
    b = B()
    b.stack = [(0.0, 0.0, 1.0, sw)]
    return b


# detail: 0 = compatta (HUD / roster, tratti spessi, riempimenti pieni), 1 = normale (monocromatiche e a colori), 2 = grande (menu, piu' dettaglio)
def libracorp(b, detail=1):
    fill = "solid" if detail == 0 else "soft"
    # Bilancia-L: il montante verticale E' il gambo della L; la base e' il piede della L; il braccio e' tenuto dal montante
    b.line((9, 3.5), (9, 21))
    b.line((9, 21), (22, 21))
    b.line((1.5, 6.5), (16.5, 6.5))
    if detail >= 1:
        b.poly([(7.2, 2), (10.8, 2), (9, 4.2)], "solid")
    for cx in (3.5, 14.5):
        b.line((cx, 6.5), (cx - 2.6, 13))
        b.line((cx, 6.5), (cx + 2.6, 13))
        b.poly([(cx - 3.6, 13), (cx + 3.6, 13), (cx + 2.2, 15.6), (cx - 2.2, 15.6)], fill)
    if detail == 2:
        b.line((13, 21), (13, 19.5), 1.2)
        b.line((17, 21), (17, 19.5), 1.2)
        b.line((21, 21), (21, 19.5), 1.2)


def rondini(b, detail=1):
    fill = "solid" if detail == 0 else "soft"
    b.poly([(12, 21), (1.5, 5), (8.5, 8), (12, 14.5)], fill)
    b.poly([(12, 21), (22.5, 5), (15.5, 8), (12, 14.5)], fill)
    b.poly([(12, 2.5), (13.7, 11), (10.3, 11)], "solid")
    if detail == 2:
        b.line((4.5, 9), (9, 12.5), 1.2)
        b.line((19.5, 9), (15, 12.5), 1.2)
        b.line((7, 12.5), (10, 15.5), 1.2)
        b.line((17, 12.5), (14, 15.5), 1.2)


def magabondi(b, detail=1):
    b.arc((12, 12), 9.5, -35, 215)
    b.arc((12, 12), 9.5, 250, 305) if detail == 2 else None
    # ago fuori asse
    ang = math.radians(-62)
    ca, sa = math.cos(ang), math.sin(ang)

    def r(x, y):
        return (12 + x * ca - y * sa, 12 + x * sa + y * ca)
    b.poly([r(0, -7.5), r(2.4, 0), r(0, 7.5), r(-2.4, 0)], "solid" if detail == 0 else "soft")
    b.dot((12, 12), 1.1)
    # linea che supera il bordo
    b.line((18.5, 4.5), (21, 2.5))
    if detail >= 1:
        b.line((2, 12), (4.5, 12), 1.5)
        b.line((12, 21.5), (12, 19), 1.5)


def kairos(b, detail=1):
    fill = "solid" if detail == 0 else "soft"
    b.poly([(3.5, 3), (18.5, 3), (12, 12)], fill)
    b.poly([(12.5, 12), (20.5, 21), (5.5, 21)], fill)
    b.arc((12, 12), 10.5, 20, 160)
    b.arc((12, 12), 10.5, 200, 340) if detail == 2 else b.arc((12, 12), 10.5, 200, 300)


EMBLEMS = [
    ("M01", "faction_libracorp", "LIBRACORP — Bilancia-L", "libracorp", libracorp,
     "bilancia a due piatti che e' una L: montante, base-piede, braccio e due piatti simmetrici"),
    ("M02", "faction_rondini", "RONDINI", "rondini", rondini, "due ali angolari che formano una V con punta centrale"),
    ("M03", "faction_magabondi", "MAGABONDI", "magabondi", magabondi, "bussola incompleta, ago fuori asse, linea che supera il bordo"),
    ("M04", "faction_kairos", "KAIROS", "kairos", kairos, "clessidra angolare disallineata con anello incompleto"),
]
