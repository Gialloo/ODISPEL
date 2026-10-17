# Adatta il disegno dell'energia ai 4 tasti del comando: le 4 sfere bianche cadono sui centri di
# ATTACK / SKILL / ULTIMATE / GUARD. Lascia intatta l'immagine HUD, deforma solo il disegno.
import sys, numpy as np
from PIL import Image
from scipy import ndimage as ndi
from scipy.interpolate import RBFInterpolator
src_path, out_path = sys.argv[1], sys.argv[2]
SC = float(sys.argv[3]) if len(sys.argv) > 3 else 1.1
W, H = 1280, 720
src = np.array(Image.open(src_path).convert("RGBA")).astype(np.float32)
# sfere nel disegno: alto, sinistra, destra, basso
orb = {"ATTACK": (327, 328), "GUARD": (269, 388), "SKILL": (395, 429), "ULTIMATE": (295, 457)}
C = np.array([365.0, 405.0]); R = 160.0
ang = {"ATTACK": -98, "SKILL": -8, "ULTIMATE": 82, "GUARD": 172}
tgt = {k: C + R * np.array([np.cos(np.radians(a)), np.sin(np.radians(a))]) for k, a in ang.items()}
mean_src = np.mean([orb[k] for k in orb], axis=0)
S = lambda p: (np.asarray(p) - mean_src) * SC + C            # similitudine di base
Si = lambda q: (np.asarray(q) - C) / SC + mean_src
# controlli (nello spazio di uscita): spostamento dell'inversa
cq, cd = [], []
for k in orb:
    cq.append(tgt[k]); cd.append(np.array(orb[k]) - Si(tgt[k]))
h, w = src.shape[:2]
for gx in np.linspace(0, w, 6):
    for gy in np.linspace(0, h, 6):
        p = np.array([gx, gy])
        if min(np.linalg.norm(p - np.array(o)) for o in orb.values()) > 190:
            cq.append(S(p)); cd.append(np.zeros(2))
rbf = RBFInterpolator(np.array(cq), np.array(cd), kernel="thin_plate_spline", smoothing=0.0)
gy, gx = np.mgrid[0:H, 0:W]
q = np.stack([gx.ravel(), gy.ravel()], 1).astype(np.float64)
sp = Si(q) + rbf(q)
out = np.zeros((H, W, 4), np.float32)
for c in range(4):
    out[..., c] = ndi.map_coordinates(src[..., c], [sp[:, 1], sp[:, 0]], order=1, mode="constant", cval=0).reshape(H, W)
Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA").save(out_path)
print("ok", {k: tuple(np.round(v).astype(int)) for k, v in tgt.items()})
