"""Libreria di disegno delle icone ODISPEL (SVG 24x24, tratto bianco costante, angoli vivi).

Regole di costruzione (vedi docs/ICONE.md):
- griglia 24x24, margine 2, tratto 2 (1.5 per i dettagli piccoli), giunzioni a spigolo, estremita' squadrate;
- riempimenti 'morbidi' = bianco al 30%, 'pieni' = bianco; nessun testo, nessuno sfondo;
- le icone sono bianche: il gioco le tinge (GameIcon.color), quindi il significato sta nella FORMA.
"""
import math

SW = 2.0
SW_THIN = 1.5


def f(x):
    return ("%.2f" % x).rstrip("0").rstrip(".")


class B:
    """Costruttore di un'icona. Le coordinate dei glifi sono nella griglia 24; push() li sposta e li rimpicciolisce."""

    def __init__(self):
        self.el = []
        self.stack = [(0.0, 0.0, 1.0, SW)]

    # ---- trasformazioni
    def push(self, ox, oy, k, sw=None):
        cx, cy, ck, csw = self.stack[-1]
        self.stack.append((cx + ox * ck, cy + oy * ck, ck * k, sw if sw is not None else (SW_THIN if k < 0.7 else csw)))

    def pop(self):
        self.stack.pop()

    def P(self, x, y):
        ox, oy, k, _ = self.stack[-1]
        return ox + x * k, oy + y * k

    @property
    def k(self):
        return self.stack[-1][2]

    @property
    def sw(self):
        return self.stack[-1][3]

    # ---- primitive
    def poly(self, pts, fill=None, close=True, sw=None):
        q = [self.P(*p) for p in pts]
        d = "M" + " L".join("%s %s" % (f(x), f(y)) for x, y in q) + (" Z" if close else "")
        self._path(d, fill, close, sw)

    def line(self, a, b, sw=None):
        self.poly([a, b], None, False, sw)

    def polyline(self, pts, sw=None):
        self.poly(pts, None, False, sw)

    def circle(self, c, r, fill=None, sw=None):
        x, y = self.P(*c)
        r = r * self.k
        fa = ""
        if fill == "soft":
            fa = ' fill="#fff" fill-opacity=".3"'
        elif fill == "solid":
            fa = ' fill="#fff"'
        else:
            fa = ' fill="none"'
        st = "" if fill == "solid" else ' stroke="#fff" stroke-width="%s"' % f(sw or self.sw)
        self.el.append('<circle cx="%s" cy="%s" r="%s"%s%s/>' % (f(x), f(y), f(r), fa, st))

    def dot(self, c, r=1.4):
        self.circle(c, r, "solid")

    def arc(self, c, r, a0, a1, arrow=False, sw=None):
        """Arco da a0 a a1 (gradi, 0 = destra, senso orario sullo schermo)."""
        pts = []
        n = max(6, int(abs(a1 - a0) / 12))
        for i in range(n + 1):
            a = math.radians(a0 + (a1 - a0) * i / n)
            pts.append((c[0] + r * math.cos(a), c[1] + r * math.sin(a)))
        self.polyline_arc(pts, sw)
        if arrow:
            a = math.radians(a1)
            direction = 1 if a1 > a0 else -1
            tx, ty = -math.sin(a) * direction, math.cos(a) * direction
            px, py = pts[-1]
            s = 3.2
            nx, ny = -ty, tx
            self.poly([(px + tx * s, py + ty * s), (px - nx * s * .8, py - ny * s * .8), (px + nx * s * .8, py + ny * s * .8)], "solid")

    def polyline_arc(self, pts, sw=None):
        q = [self.P(*p) for p in pts]
        d = "M" + " L".join("%s %s" % (f(x), f(y)) for x, y in q)
        self._path(d, None, False, sw)

    def _path(self, d, fill, close, sw):
        fa = ' fill="none"'
        if fill == "soft":
            fa = ' fill="#fff" fill-opacity=".3"'
        elif fill == "solid":
            fa = ' fill="#fff"'
        self.el.append('<path d="%s"%s stroke="#fff" stroke-width="%s" stroke-linejoin="miter" stroke-miterlimit="4" stroke-linecap="%s"/>' % (d, fa, f(sw or self.sw), "square" if not close else "butt"))

    def svg(self, tone=None):
        return ('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">'
                + "".join(self.el) + "</svg>")


# ------------------------------------------------------------------ glifi base (griglia 24)
def heart(b, fill="soft"):
    b.poly([(12, 21), (3, 12), (3, 8), (6.5, 4.5), (12, 8), (17.5, 4.5), (21, 8), (21, 12)], fill)


def heart_crack(b):
    heart(b)
    b.polyline([(12, 8), (10, 12), (13.5, 14), (11, 18)], 1.5)


def shield(b, fill="soft"):
    b.poly([(12, 2), (20, 5.5), (20, 14), (12, 22), (4, 14), (4, 5.5)], fill)


def shield_crack(b):
    shield(b)
    b.polyline([(12, 2), (10.5, 8), (13.5, 12), (11, 22)], 1.5)


def shield_broken(b):
    b.poly([(11, 2.5), (4, 5.5), (4, 14), (10, 21), (9, 14), (11, 9)], "soft")
    b.poly([(14, 4), (20, 6.5), (20, 14), (13.5, 21.5), (14.5, 14), (13, 11)], "soft")


def sword(b, flip=False, ox=0.0, tip=True):
    fx = (lambda x: 24 - x) if flip else (lambda x: x)
    b.line((fx(3 + ox), 21), (fx(19 + ox), 5))
    b.line((fx(5.5 + ox), 12.5), (fx(11.5 + ox), 18.5))
    if tip:
        b.poly([(fx(19 + ox), 5), (fx(21 + ox), 3), (fx(21 + ox), 7)], "solid")


def blade_v(b):
    b.poly([(12, 2), (15, 14), (12, 17), (9, 14)], "soft")
    b.line((7, 17), (17, 17))
    b.line((12, 17), (12, 22))


def bolt(b, fill="soft"):
    b.poly([(14, 2), (5, 13), (11, 13), (9, 22), (19, 10), (13, 10)], fill)


def ring(b, c=(12, 12), r=9, sw=None):
    b.circle(c, r, None, sw)


def person(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.circle((12, 6.5), 3.6, "soft")
    b.poly([(5, 21), (5, 15), (8.5, 11.5), (15.5, 11.5), (19, 15), (19, 21)], "soft")
    b.pop()


def arrow_up(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.poly([(12, 3), (19, 11), (14, 11), (14, 21), (10, 21), (10, 11), (5, 11)], "solid")
    b.pop()


def arrow_down(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.poly([(12, 21), (19, 13), (14, 13), (14, 3), (10, 3), (10, 13), (5, 13)], "solid")
    b.pop()


def arrow_right(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.poly([(21, 12), (13, 5), (13, 10), (3, 10), (3, 14), (13, 14), (13, 19)], "solid")
    b.pop()


def arrow_left(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.poly([(3, 12), (11, 5), (11, 10), (21, 10), (21, 14), (11, 14), (11, 19)], "solid")
    b.pop()


def hourglass(b, ox=0.0, oy=0.0, k=1.0, empty=False):
    b.push(ox, oy, k)
    b.poly([(6, 3), (18, 3), (18, 6), (12, 12), (18, 18), (18, 21), (6, 21), (6, 18), (12, 12), (6, 6)], None)
    if not empty:
        b.poly([(8.5, 5), (15.5, 5), (12, 10)], "solid")
        b.poly([(8.5, 19), (15.5, 19), (12, 15)], "solid")
    b.pop()


def crosshair(b, ox=0.0, oy=0.0, k=1.0, dot=True, r=7.0, ticks=True):
    b.push(ox, oy, k)
    b.circle((12, 12), r)
    if dot:
        b.dot((12, 12), 1.6)
    if ticks:
        for a, c in (((12, 2), (12, 7)), ((12, 17), (12, 22)), ((2, 12), (7, 12)), ((17, 12), (22, 12))):
            b.line(a, c)
    b.pop()


def star4(b, ox=0.0, oy=0.0, k=1.0, fill="solid"):
    b.push(ox, oy, k)
    b.poly([(12, 2), (14, 10), (22, 12), (14, 14), (12, 22), (10, 14), (2, 12), (10, 10)], fill)
    b.pop()


def spark(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.poly([(12, 3), (13.6, 10.4), (21, 12), (13.6, 13.6), (12, 21), (10.4, 13.6), (3, 12), (10.4, 10.4)], "solid")
    b.pop()


def check(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.polyline([(4, 12.5), (9.5, 18), (20, 6)])
    b.pop()


def xmark(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.line((5, 5), (19, 19))
    b.line((19, 5), (5, 19))
    b.pop()


def plus(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.line((12, 5), (12, 19))
    b.line((5, 12), (19, 12))
    b.pop()


def slash(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.line((4, 20), (20, 4))
    b.pop()


def crack(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.polyline([(14, 2), (10, 9), (14, 13), (9, 22)])
    b.pop()


def drop(b, fill="soft"):
    b.poly([(12, 2), (19, 13), (17, 19), (12, 22), (7, 19), (5, 13)], fill)


def flame(b):
    b.poly([(12, 2), (17, 8), (20, 14), (17, 21), (12, 22), (7, 21), (4, 14), (8, 9), (9, 13), (11, 10)], "soft")


def crystal6(b):
    for a in range(0, 180, 60):
        r = math.radians(a + 90)
        b.line((12 + 10 * math.cos(r), 12 + 10 * math.sin(r)), (12 - 10 * math.cos(r), 12 - 10 * math.sin(r)))
    for a in range(0, 360, 60):
        r = math.radians(a + 90)
        x, y = 12 + 7 * math.cos(r), 12 + 7 * math.sin(r)
        b.line((x, y), (12 + 10 * math.cos(r) - 3 * math.cos(r + 1.0), 12 + 10 * math.sin(r) - 3 * math.sin(r + 1.0)), SW_THIN)


def lock(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.polyline([(7.5, 10), (7.5, 6.5), (9.5, 3.5), (14.5, 3.5), (16.5, 6.5), (16.5, 10)])
    b.poly([(5, 10), (19, 10), (19, 21), (5, 21)], "soft")
    b.dot((12, 15.5), 1.6)
    b.pop()


def eye(b, ox=0.0, oy=0.0, k=1.0, closed=False):
    b.push(ox, oy, k)
    if closed:
        b.polyline([(2, 12), (7, 15.5), (12, 17), (17, 15.5), (22, 12)])
        for x in (6, 12, 18):
            b.line((x, 15.5 if x != 12 else 17), (x, 19.5 if x != 12 else 21), SW_THIN)
    else:
        b.poly([(2, 12), (7, 6.5), (12, 5), (17, 6.5), (22, 12), (17, 17.5), (12, 19), (7, 17.5)], None)
        b.circle((12, 12), 3.2, "soft")
        b.dot((12, 12), 1.0)
    b.pop()


def bubble(b, ox=0.0, oy=0.0, k=1.0):
    b.push(ox, oy, k)
    b.poly([(3, 4), (21, 4), (21, 16), (13, 16), (7, 21), (8, 16), (3, 16)], "soft")
    b.pop()


def gear(b):
    pts = []
    for i in range(16):
        a = math.radians(i * 22.5)
        r = 10 if i % 2 == 0 else 7.5
        pts.append((12 + r * math.cos(a), 12 + r * math.sin(a)))
    b.poly(pts, "soft")
    b.circle((12, 12), 3)


def core(b, ox=0.0, oy=0.0, k=1.0, fill="solid", r=3.4):
    b.push(ox, oy, k)
    b.circle((12, 12), r, fill)
    b.pop()


def node(b, ox=0.0, oy=0.0, k=1.0, fill="soft", r=3.2):
    b.push(ox, oy, k)
    b.circle((12, 12), r, fill)
    b.pop()


def footprint(b, ox, oy, k=1.0):
    b.push(ox, oy, k)
    b.poly([(8, 3), (14, 3), (15.5, 9), (14, 14), (9, 14), (7.5, 9)], "soft")
    b.poly([(8.5, 16.5), (14, 16.5), (14, 21), (8.5, 21)], "soft")
    b.pop()


def hexagon(b, ox=0.0, oy=0.0, k=1.0, fill=None, r=10):
    b.push(ox, oy, k)
    b.poly([(12 + r * math.cos(math.radians(a)), 12 + r * math.sin(math.radians(a))) for a in range(30, 390, 60)], fill)
    b.pop()


def diamond(b, ox=0.0, oy=0.0, k=1.0, fill=None):
    b.push(ox, oy, k)
    b.poly([(12, 2), (21, 12), (12, 22), (3, 12)], fill)
    b.pop()


def chevron_up(b, y=0.0, k=1.0):
    b.push(0, y, k)
    b.polyline([(4, 15), (12, 7), (20, 15)])
    b.pop()


def seal(b, r=9, check_mark=False):
    b.circle((12, 12), r, "soft")
    b.circle((12, 12), r - 3.2, None, SW_THIN)
    if check_mark:
        check(b, 6, 6, 0.5)


def bars(b, x0, n, base=20, step=3.2, w=2.2):
    for i in range(n):
        h = 4 + i * 3
        b.poly([(x0 + i * step * 1.4, base), (x0 + i * step * 1.4 + w, base), (x0 + i * step * 1.4 + w, base - h), (x0 + i * step * 1.4, base - h)], "solid")
