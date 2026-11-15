# Ritratti dei dialoghi del Capitolo 1 col Saul v3 (15/11/2026): mezzobusto 3/4 che guarda verso destra (LATO -1),
# sette espressioni con le forme del viso VRoid. Uso: blender -b saul_v3_rig.blend --python ritratti.py -- <cartella>
import bpy, math, sys, os
from mathutils import Vector as Vec, Matrix
out = sys.argv[sys.argv.index('--') + 1]
sc = bpy.context.scene; A = bpy.data.objects['Saul_rig']; P = A.pose.bones
bpy.context.view_layer.objects.active = A; bpy.ops.object.mode_set(mode='POSE')
def upd(): bpy.context.view_layer.update()
def W(n, tail=False): upd(); pb = P[n]; return A.matrix_world @ (pb.tail if tail else pb.head)
CH = {'UpperArm': 'LowerArm', 'LowerArm': 'Hand', 'Hand': 'Middle1', 'UpperLeg': 'LowerLeg', 'LowerLeg': 'Foot', 'Foot': 'ToeBase'}
def child(n):
    for k, v in CH.items():
        if n.endswith('_' + k): return n[:-len(k)] + v
    if n[-1] in '12': return n[:-1] + str(int(n[-1]) + 1)
def aim(n, d):
    upd(); pb = P[n]; h = pb.head.copy(); q = (P[child(n)].head - h).rotation_difference(Vec(d).normalized())
    pb.matrix = Matrix.Translation(h) @ q.to_matrix().to_4x4() @ Matrix.Translation(-h) @ pb.matrix.copy(); upd()
def rotw(n, axis, deg):
    upd(); pb = P[n]; h = pb.head.copy(); R = Matrix.Rotation(math.radians(deg), 4, Vec(axis).normalized())
    pb.matrix = Matrix.Translation(h) @ R @ Matrix.Translation(-h) @ pb.matrix.copy(); upd()
# braccia giu' lungo il fianco, polso dritto, dita appena piegate verso il palmo
for s, sx in (('L', -1), ('R', 1)):
    aim(f'J_Bip_{s}_UpperArm', (0.2 * sx, 0.02, -1)); aim(f'J_Bip_{s}_LowerArm', (0.12 * sx, 0.12, -1)); aim(f'J_Bip_{s}_Hand', (0.12 * sx, 0.12, -1))
    sd = (W(f'J_Bip_{s}_Index1') - W(f'J_Bip_{s}_Little1')).normalized()
    for f, ang in (('Little', 30), ('Ring', 26), ('Middle', 22), ('Index', 16)):
        for k in (1, 2, 3): rotw(f'J_Bip_{s}_{f}{k}', sd, ang * (1.0 if k > 1 else 0.7) * (-sx if s == 'L' else 1))
rotw('J_Bip_C_Hips', (0, 0, 1), 10); rotw('J_Bip_C_Neck', (0, 0, 1), -5); rotw('J_Bip_C_Head', (0, 0, 1), -8); rotw('J_Bip_C_Head', (1, 0, 0), 4)
bpy.ops.object.mode_set(mode='OBJECT'); upd()
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # rifinitura.py sta accanto a questo script
import rifinitura; rifinitura.anti_clip(A)
# luci come nei render approvati, sfondo trasparente
sc.render.engine = 'BLENDER_EEVEE_NEXT'; sc.view_settings.view_transform = 'Standard'; sc.eevee.taa_render_samples = 32
sc.render.film_transparent = True; sc.render.image_settings.color_mode = 'RGBA'
def sun(n, e, rot, c):
    l = bpy.data.lights.new(n, 'SUN'); l.energy = e; l.color = c; l.angle = 0.05; ob = bpy.data.objects.new(n, l); sc.collection.objects.link(ob); ob.rotation_euler = [math.radians(x) for x in rot]
sun('chiave', 4.2, (48, 0, 132), (1, 0.95, 0.88)); sun('contro', 2.2, (70, 0, 330), (0.4, 1, 0.65))
cam = bpy.data.cameras.new('c'); co = bpy.data.objects.new('cam', cam); sc.collection.objects.link(co); sc.camera = co
cam.lens = 92; sc.render.resolution_x = 1024; sc.render.resolution_y = 1536
loc = Vec((0.62, 2.35, 1.52)); tgt = Vec((0.0, 0.05, 1.415))
co.location = loc; co.rotation_euler = (tgt - loc).to_track_quat('-Z', 'Y').to_euler()
K = bpy.data.objects['Saul_testa'].data.shape_keys.key_blocks
ESPR = {
    'neutro': {'BRW_Angry': 0.35, 'EYE_Angry': 0.22, 'MTH_Fun': 0.30},
    'felice': {'BRW_Joy': 0.5, 'EYE_Joy': 0.45, 'MTH_Fun': 0.9, 'MTH_A': 0.12},
    'arrabbiato': {'BRW_Angry': 1.0, 'EYE_Angry': 0.6, 'MTH_Angry': 0.75},
    'sorpreso': {'BRW_Surprised': 1.0, 'EYE_Surprised': 0.8, 'MTH_O': 0.55},
    'triste': {'BRW_Sorrow': 0.9, 'EYE_Sorrow': 0.6, 'MTH_Sorrow': 0.55},
    'serio': {'BRW_Angry': 0.55, 'EYE_Angry': 0.4, 'MTH_Close': 0.6},
    'sfotto': {'BRW_Angry': 0.3, 'BRW_Fun': 0.4, 'EYE_Close_R': 0.45, 'EYE_Angry': 0.25, 'MTH_Fun': 0.7, 'MTH_Up': 0.25},
}
which = sys.argv[sys.argv.index('--') + 2].split(',') if len(sys.argv) > sys.argv.index('--') + 2 else list(ESPR)
for nome in which:
    for kb in K[1:]: kb.value = 0.0
    for k, v in ESPR[nome].items(): K[k].value = v
    sc.render.filepath = os.path.join(out, f'saul_{nome}.png'); bpy.ops.render.render(write_still=True)
