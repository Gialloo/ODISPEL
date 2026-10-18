# Ritratti SEGNAPOSTO di Echo (il Kairos delle telecamere): una telecamera di sorveglianza con l'obiettivo come occhio.
# Stesso formato dei ritratti dei protagonisti: 512x768, sfondo trasparente, "faccia" nella parte alta (la usano anche le chiacchiere).
# Uso: python3 tools/echo_portraits.py assets/portraits
import sys, math
from PIL import Image, ImageDraw, ImageFilter

W, H, K = 512, 768, 3            # disegno a 3x e poi riduco (bordi morbidi)
INK = (18, 10, 28, 255)
BODY = (217, 214, 224, 255)
BODY_D = (150, 146, 168, 255)
CYAN = (63, 224, 255, 255)
CYAN_D = (20, 120, 160, 255)
EXPR = ["neutro", "felice", "triste", "sorpreso", "serio", "arrabbiato", "sfotto"]


def s(v):
    return int(v * K)


def draw(expr):
    im = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    glow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    d = ImageDraw.Draw(im)
    cx, cy = 256, 250
    # alone ciano dietro
    g.ellipse([s(cx - 190), s(cy - 190), s(cx + 190), s(cy + 190)], fill=(63, 224, 255, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(s(40)))
    im.alpha_composite(glow)
    d = ImageDraw.Draw(im)
    # braccio di supporto e cavo che scendono (il "busto")
    d.rounded_rectangle([s(cx - 26), s(cy + 90), s(cx + 26), s(H + 20)], radius=s(14), fill=BODY_D, outline=INK, width=s(7))
    d.line([s(cx + 60), s(cy + 110), s(cx + 120), s(cy + 300), s(cx + 70), s(H + 20)], fill=INK, width=s(16), joint="curve")
    d.line([s(cx + 60), s(cy + 110), s(cx + 120), s(cy + 300), s(cx + 70), s(H + 20)], fill=(60, 56, 80, 255), width=s(8), joint="curve")
    # corpo della telecamera (leggermente inclinato verso chi guarda)
    d.rounded_rectangle([s(cx - 175), s(cy - 115), s(cx + 165), s(cy + 115)], radius=s(48), fill=BODY, outline=INK, width=s(9))
    d.rounded_rectangle([s(cx - 160), s(cy - 140), s(cx + 150), s(cy - 98)], radius=s(18), fill=BODY_D, outline=INK, width=s(8))
    # LED REC
    led = (255, 60, 90, 255) if expr != "triste" else (120, 60, 80, 255)
    d.ellipse([s(cx + 110), s(cy - 85), s(cx + 140), s(cy - 55)], fill=led, outline=INK, width=s(4))
    # obiettivo = occhio
    lx, ly, R = cx - 15, cy + 5, 92
    d.ellipse([s(lx - R), s(ly - R), s(lx + R), s(ly + R)], fill=(34, 30, 48, 255), outline=INK, width=s(9))
    r2 = 66 if expr != "sorpreso" else 74
    d.ellipse([s(lx - r2), s(ly - r2), s(lx + r2), s(ly + r2)], fill=CYAN_D)
    if expr == "felice":
        # occhio "a mezzaluna" degli anime: arco luminoso
        d.arc([s(lx - 52), s(ly - 30), s(lx + 52), s(ly + 60)], start=200, end=340, fill=CYAN, width=s(20))
    else:
        ir = {"sorpreso": 52, "serio": 44, "arrabbiato": 44}.get(expr, 48)
        d.ellipse([s(lx - ir), s(ly - ir), s(lx + ir), s(ly + ir)], fill=CYAN)
        pr = {"sorpreso": 12, "triste": 20}.get(expr, 22)
        dy = 10 if expr == "triste" else 0
        d.ellipse([s(lx - pr), s(ly - pr + dy), s(lx + pr), s(ly + pr + dy)], fill=(10, 30, 50, 255))
        d.ellipse([s(lx + 12), s(ly - 32), s(lx + 30), s(ly - 14)], fill=(255, 255, 255, 230))
    # palpebre = lamelle dell'otturatore
    lid = (60, 56, 80, 255)
    if expr in ("serio", "arrabbiato", "triste", "sfotto"):
        if expr == "serio":
            top = [(lx - R, ly - R), (lx + R, ly - R), (lx + R, ly - 26), (lx - R, ly - 26)]
            bot = [(lx - R, ly + R), (lx + R, ly + R), (lx + R, ly + 34), (lx - R, ly + 34)]
            polys = [top, bot]
        elif expr == "arrabbiato":
            polys = [[(lx - R, ly - R), (lx + R, ly - R), (lx + R, ly - 40), (lx - R, ly - 4)]]
        elif expr == "triste":
            polys = [[(lx - R, ly - R), (lx + R, ly - R), (lx + R, ly - 4), (lx - R, ly - 40)]]
        else:
            polys = [[(lx - R, ly - R), (lx + R, ly - R), (lx + R, ly - 10), (lx - R, ly - 10)]]
        mask = Image.new("L", im.size, 0)
        md = ImageDraw.Draw(mask)
        md.ellipse([s(lx - r2), s(ly - r2), s(lx + r2), s(ly + r2)], fill=255)
        layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        for p in polys:
            ld.polygon([(s(x), s(y)) for x, y in p], fill=lid)
            ld.line([(s(x), s(y)) for x, y in p[2:]] if len(p) == 4 else [], fill=INK, width=s(6))
        layer.putalpha(Image.composite(layer.getchannel("A"), Image.new("L", im.size, 0), mask))
        im.alpha_composite(layer)
        d = ImageDraw.Draw(im)
    if expr == "triste":
        d.polygon([(s(lx + 40), s(ly + 70)), (s(lx + 52), s(ly + 100)), (s(lx + 28), s(ly + 100))], fill=CYAN)
        d.ellipse([s(lx + 26), s(ly + 88), s(lx + 54), s(ly + 116)], fill=CYAN)
    # "bocca": una piccola fessura luminosa sotto l'obiettivo, cambia con l'umore
    mx, my = cx + 105, cy + 55
    if expr == "felice" or expr == "sfotto":
        d.arc([s(mx - 26), s(my - 22), s(mx + 26), s(my + 18)], start=20, end=160, fill=CYAN, width=s(7))
    elif expr in ("triste",):
        d.arc([s(mx - 24), s(my + 2), s(mx + 24), s(my + 38)], start=200, end=340, fill=CYAN, width=s(7))
    elif expr == "sorpreso":
        d.ellipse([s(mx - 10), s(my - 6), s(mx + 10), s(my + 16)], outline=CYAN, width=s(6))
    elif expr == "arrabbiato":
        d.line([s(mx - 24), s(my + 8), s(mx - 8), s(my), s(mx + 8), s(my + 8), s(mx + 24), s(my)], fill=CYAN, width=s(6))
    else:
        d.line([s(mx - 22), s(my + 6), s(mx + 22), s(my + 6)], fill=CYAN, width=s(6))
    return im.resize((W, H), Image.LANCZOS)


out = sys.argv[1] if len(sys.argv) > 1 else "assets/portraits"
for e in EXPR:
    draw(e).save(f"{out}/echo_{e}.png")
print("ok", len(EXPR))
