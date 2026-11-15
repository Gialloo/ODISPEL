# Saul v3 per il gioco Godot del Capitolo 1 (15/11/2026).
# Dal modello approvato (saul_v3_rig.blend) fa un .glb leggero per il telefono:
#  - posa di riposo rilassata (braccia giu', polso dritto, dita piegate verso il palmo) applicata come riposo;
#  - niente contorni a guscio e niente suddivisioni (il gioco disegna da se'), meno triangoli su corpo e capelli;
#  - ossa elastiche nuove: quattro catene per le falde del cappotto (Saul_Falda_*) e una per la coda (Saul_Coda_*),
#    pesate sul tessuto: in Godot le muove lo SpringBoneSimulator3D, con collisioni su gambe e fianchi;
#  - materiali semplici (colore o trama VRoid), trame grandi ridotte a 1024;
#  - solo le forme del viso che servono al gioco (battito di ciglia ed espressioni).
# Uso: blender -b saul_v3_rig.blend --python esporta_gioco.py -- <file.glb>
import bpy, bmesh, math, sys
from mathutils import Vector as Vec, Matrix
out = sys.argv[sys.argv.index('--') + 1]
sc = bpy.context.scene
A = bpy.data.objects['Saul_rig']; P = A.pose.bones
def upd(): bpy.context.view_layer.update()
def sel_only(objs, active=None):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]

# ---------- 0. colori veri dei tessuti: i materiali a cartone ritingono le trame VRoid (gilet oliva, cravatta grigia,
# pelle calda, trama di lana); il glTF non porta quei nodi, quindi il colore di base si "cuoce" in una trama nuova ----------
sc.render.engine = 'CYCLES'; sc.cycles.samples = 1; sc.cycles.device = 'CPU'; sc.render.bake.margin = 4
dummy = bpy.data.images.new('cotto_vuoto', 8, 8)
ALFA = {}                                  # trama cotta -> trama di partenza (per riprenderne la trasparenza)
for on in ('Saul_corpo', 'Saul_testa'):
    o = bpy.data.objects[on]
    for m in [s.material for s in o.material_slots if s.material]:
        nt = m.node_tree
        tn = nt.nodes.new('ShaderNodeTexImage'); tn.image = dummy
        src = next((n.image for n in nt.nodes if n.type == 'TEX_IMAGE' and n.image and n.image != dummy), None)
        if src is not None:
            w = min(1024, src.size[0]); h = max(8, src.size[1] * w // src.size[0])
            tn.image = bpy.data.images.new('cotto_' + m.name, w, h, alpha=True); ALFA[tn.image.name] = src
            mx = next((n for n in nt.nodes if n.type == 'MIX_RGB' and n.blend_type == 'MIX' and n.inputs['Fac'].is_linked
                      and n.inputs['Fac'].links[0].from_node.type == 'VALTORGB' and n.inputs['Fac'].links[0].from_node.inputs[0].is_linked
                      and n.inputs['Fac'].links[0].from_node.inputs[0].links[0].from_node.type == 'SHADERTORGB'), None)
            em = next(n for n in nt.nodes if n.type == 'EMISSION')
            if mx is not None: nt.links.new(mx.inputs['Color2'].links[0].from_socket, em.inputs[0])
            out_ = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output)
            nt.links.new(em.outputs[0], out_.inputs[0])        # niente trasparenza mentre si cuoce
        nt.nodes.active = tn; tn.select = True
    o.data.uv_layers.active_index = 0
    sel_only([o]); bpy.ops.object.bake(type='EMIT')
import numpy as np
for im in bpy.data.images:
    if im.name in ALFA:
        src = ALFA[im.name]
        if src.size[0] != im.size[0] or src.size[1] != im.size[1]:
            src = src.copy(); src.scale(im.size[0], im.size[1])
        a = np.empty(len(src.pixels), dtype=np.float32); src.pixels.foreach_get(a)
        b = np.empty(len(im.pixels), dtype=np.float32); im.pixels.foreach_get(b)
        b[3::4] = a[3::4]; im.pixels.foreach_set(b); im.pack()

# ---------- 1. posa rilassata ----------
bpy.context.view_layer.objects.active = A; bpy.ops.object.mode_set(mode='POSE')
def W(n): upd(); return A.matrix_world @ P[n].head
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
for s, sx in (('L', -1), ('R', 1)):
    # braccio un po' staccato dal fianco (il cappotto e' largo), avambraccio appena avanti, polso dritto
    aim(f'J_Bip_{s}_UpperArm', (0.30 * sx, 0.03, -1)); aim(f'J_Bip_{s}_LowerArm', (0.16 * sx, 0.16, -1)); aim(f'J_Bip_{s}_Hand', (0.16 * sx, 0.16, -1))
    sd = (W(f'J_Bip_{s}_Index1') - W(f'J_Bip_{s}_Little1')).normalized()
    for f, ang in (('Little', 34), ('Ring', 30), ('Middle', 26), ('Index', 18)):
        for k in (1, 2, 3): rotw(f'J_Bip_{s}_{f}{k}', sd, ang * (1.0 if k > 1 else 0.7))
    pn = (W(f'J_Bip_{s}_Middle1') - W(f'J_Bip_{s}_Hand')).normalized().cross(sd).normalized()
    for k in (1, 2): rotw(f'J_Bip_{s}_Thumb{k}', pn, -12)
bpy.ops.object.mode_set(mode='OBJECT'); upd()

# ---------- 2. via contorni e suddivisioni, si applicano gli spessori ----------
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
for o in meshes:
    for m in list(o.modifiers):
        if m.type == 'SOLIDIFY' and (m.use_flip_normals or m.material_offset >= 50): o.modifiers.remove(m)
        elif m.type == 'SUBSURF': o.modifiers.remove(m)
for o in meshes:
    if o.data.shape_keys: continue
    sel_only([o])
    for m in list(o.modifiers):
        if m.type != 'ARMATURE': bpy.ops.object.modifier_apply(modifier=m.name)

# ---------- 3. la posa diventa il riposo ----------
for o in meshes:
    arm = [m for m in o.modifiers if m.type == 'ARMATURE']
    if not arm or o.data.shape_keys: continue      # il viso segue solo testa e collo, che non si muovono
    sel_only([o]); nm = arm[0].name
    bpy.ops.object.modifier_copy(modifier=nm); bpy.ops.object.modifier_apply(modifier=nm)
sel_only([A]); bpy.ops.object.mode_set(mode='POSE'); bpy.ops.pose.select_all(action='SELECT'); bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode='OBJECT'); upd()

# ---------- 4. capelli, laccio e orecchini: da figli dell'osso a pelle sulla testa ----------
HEAD = 'J_Bip_C_Head'
hair = [o for o in meshes if o.parent == A and o.parent_type == 'BONE']
for o in hair:
    mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
    sel_only([o]); bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    vg = o.vertex_groups.new(name=HEAD); vg.add(list(range(len(o.data.vertices))), 1.0, 'REPLACE')
    o.parent = A; o.matrix_parent_inverse = A.matrix_world.inverted()
    md = o.modifiers.new('rig', 'ARMATURE'); md.object = A

# ---------- 5. ossa elastiche ----------
def world_verts(o): return [o.matrix_world @ v.co for v in o.data.vertices]
coat = bpy.data.objects['cappotto']; cv = world_verts(coat)
Z0 = W('J_Bip_C_Hips').z - 0.06; ZH = min(v.z for v in cv)
FALDE = {'Falda_AS': -45, 'Falda_AD': 45, 'Falda_DS': -135, 'Falda_DD': 135}    # angolo dal davanti (+Y), S = sinistra (-X)
NSEG = 3
def rad_at(phi, z):
    best = []
    for v in cv:
        if abs(v.z - z) < 0.05:
            a = math.degrees(math.atan2(v.x, v.y))
            if abs((a - phi + 180) % 360 - 180) < 20: best.append(Vec((v.x, v.y)).length)
    return max(best) if best else 0.2
sel_only([A]); bpy.ops.object.mode_set(mode='EDIT'); E = A.data.edit_bones
hips = E['J_Bip_C_Hips']
for n, phi in FALDE.items():
    par = hips; pts = []
    for k in range(NSEG + 1):
        z = Z0 + (ZH - Z0) * k / NSEG; r = rad_at(phi, z) * 0.92
        pts.append(Vec((r * math.sin(math.radians(phi)), r * math.cos(math.radians(phi)), z)))
    for k in range(NSEG):
        b = E.new(f'Saul_{n}_{k + 1}'); b.head = pts[k]; b.tail = pts[k + 1]; b.parent = par; b.use_connect = k > 0; par = b
# coda: dal laccio verso la punta, lungo il centro delle ciocche
coda = [o for o in hair if o.name.startswith('ciocca_coda')]
laccio = bpy.data.objects['ciocca_laccio']
root = sum(world_verts(laccio), Vec()) / len(laccio.data.vertices)
cpts = [v for o in coda for v in world_verts(o)]
far = max(cpts, key=lambda v: (v - root).length); L = (far - root).length
chain = [root]
for k in range(1, 4):
    t0, t1 = L * (k - 0.5) / 3, L * k / 3 + 0.02
    sel = [v for v in cpts if t0 <= (v - root).length <= t1] or [root + (far - root) * k / 3]
    chain.append(sum(sel, Vec()) / len(sel))
par = E[HEAD]
for k in range(3):
    b = E.new(f'Saul_Coda_{k + 1}'); b.head = chain[k]; b.tail = chain[k + 1]; b.parent = par; b.use_connect = k > 0; par = b
bpy.ops.object.mode_set(mode='OBJECT'); upd()

# pesi delle falde: sotto la vita il cappotto passa alle catene (sfumando), diviso per settore e altezza
def smooth(a, b, x): t = min(1, max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t)
names = list(FALDE)
for n in names:
    for k in range(NSEG): coat.vertex_groups.new(name=f'Saul_{n}_{k + 1}')
for v in coat.data.vertices:
    p = coat.matrix_world @ v.co
    wc = smooth(Z0 + 0.02, Z0 - 0.14, p.z)
    if wc <= 0: continue
    for g in v.groups: g.weight *= (1 - wc)
    a = math.degrees(math.atan2(p.x, p.y))
    ds = sorted(((abs((a - FALDE[n] + 180) % 360 - 180), n) for n in names))
    (d0, n0), (d1, n1) = ds[0], ds[1]
    ws = {n0: d1 / (d0 + d1 + 1e-6), n1: d0 / (d0 + d1 + 1e-6)}
    t = min(0.999, max(0.0, (Z0 - p.z) / (Z0 - ZH))) * NSEG
    k0 = int(t); f = t - k0
    for n, wn in ws.items():
        coat.vertex_groups[f'Saul_{n}_{k0 + 1}'].add([v.index], wc * wn * (1 - f), 'ADD')
        if k0 + 1 < NSEG: coat.vertex_groups[f'Saul_{n}_{k0 + 2}'].add([v.index], wc * wn * f, 'ADD')
# pesi della coda: lungo la catena, la radice resta sulla testa
for o in coda:
    for k in range(3): o.vertex_groups.new(name=f'Saul_Coda_{k + 1}')
    for v in o.data.vertices:
        p = o.matrix_world @ v.co; t = min(0.999, (p - root).length / L) * 3
        k0 = int(t); f = t - k0; wh = max(0.0, 1 - t * 1.5)
        o.vertex_groups[HEAD].add([v.index], wh, 'REPLACE')
        o.vertex_groups[f'Saul_Coda_{k0 + 1}'].add([v.index], (1 - wh) * (1 - f), 'REPLACE')
        if k0 + 1 < 3: o.vertex_groups[f'Saul_Coda_{k0 + 2}'].add([v.index], (1 - wh) * f, 'REPLACE')

# ---------- 6. un mesh per il corpo, uno per i capelli, il viso a parte (forme) ----------
body = bpy.data.objects['Saul_corpo']
md = body.modifiers.new('meno', 'DECIMATE'); md.ratio = 0.55; md.use_collapse_triangulate = True
sel_only([body]); bpy.ops.object.modifier_move_to_index(modifier='meno', index=0); bpy.ops.object.modifier_apply(modifier='meno')
for o in hair:
    if o.name.startswith('ciocca') and o.name != 'ciocca_laccio':
        md = o.modifiers.new('meno', 'DECIMATE'); md.ratio = 0.45
        sel_only([o]); bpy.ops.object.modifier_move_to_index(modifier='meno', index=0); bpy.ops.object.modifier_apply(modifier='meno')
vesti = [body] + [o for o in meshes if o.name.split('.')[0] in ('cappotto', 'manica', 'polsino', 'revers')]
sel_only(vesti, body); bpy.ops.object.join(); body.name = 'Saul_corpo'
hair[0].name = 'Saul_capelli_tmp'; sel_only(hair, hair[0]); bpy.ops.object.join(); capelli = bpy.context.view_layer.objects.active; capelli.name = 'Saul_capelli'
for o in (body, capelli):
    arm = [m for m in o.modifiers if m.type == 'ARMATURE']
    for m in arm[1:]: o.modifiers.remove(m)
face = bpy.data.objects['Saul_testa']
TIENI = {'Basis', 'EYE_Close', 'EYE_Close_R', 'EYE_Close_L', 'ALL_Joy', 'ALL_Angry', 'ALL_Sorrow', 'ALL_Surprised', 'ALL_Fun',
         'BRW_Angry', 'EYE_Angry', 'MTH_Fun', 'MTH_A', 'MTH_O', 'BRW_Joy', 'EYE_Joy', 'BRW_Sorrow', 'EYE_Sorrow', 'MTH_Sorrow'}
for kb in list(face.data.shape_keys.key_blocks):
    if kb.name not in TIENI: face.shape_key_remove(kb)
for o in (body, capelli, face):
    sel_only([o]); bpy.ops.object.material_slot_remove_unused()

# ---------- 7. due trame sole (atlante): sul telefono ogni materiale e' una draw call in piu' ----------
# Le trame "cotte" al punto 0 si incollano in un atlante 2048 (vesti e pelle) e in uno con la trasparenza (viso, occhi,
# ciglia, capelli dietro); i colori pieni (cappotto, fodera, capelli...) diventano quadratini. Gli UV si spostano li'.
import numpy as np
W_AT = 2048
OPACO = {'Body_00_SKIN': (0, 0, 1024, 1024), 'Tops': (1024, 0, 1024, 1024), 'Bottoms': (0, 1024, 1024, 1024),
         'Shoes': (1024, 1024, 512, 512), 'Tie': (1536, 1024, 256, 256)}
TRASP = {'Face_00_SKIN': (0, 0, 1024, 1024), 'HairBack': (1024, 0, 1024, 1024), 'Iris': (0, 1024, 1024, 512),
         'EyeWhite': (1024, 1024, 512, 256), 'Highlight': (1536, 1024, 512, 256), 'EyeExtra': (1024, 1280, 512, 256),
         'Mouth': (1536, 1280, 512, 512), 'Brow': (0, 1536, 1024, 256), 'Eyelash': (0, 1792, 1024, 256), 'Eyeline': (1024, 1792, 1024, 256)}
def srgb(c): return 1.055 * c ** (1 / 2.4) - 0.055 if c > 0.0031308 else 12.92 * c
def info_mat(m):
    nt = m.node_tree
    imgs = [n.image for n in nt.nodes if n.type == 'TEX_IMAGE' and n.image and n.image.name != 'cotto_vuoto']
    img = next((i for i in imgs if i.name.startswith('cotto_')), imgs[0] if imgs else None)
    rgb = next((tuple(n.outputs[0].default_value) for n in nt.nodes if n.type == 'RGB'), (0.5, 0.5, 0.5, 1))
    return img, rgb
def rect_of(name, table):
    return next((r for k, r in table.items() if k in name), None)
AT = {'opaco': np.zeros((W_AT, W_AT, 4), np.float32), 'trasp': np.zeros((W_AT, W_AT, 4), np.float32)}
AT['opaco'][..., 3] = 1.0
celle = {}
def cella(m, rgb):
    if m.name not in celle:
        i = len(celle); x = 1792 + (i % 16) * 16; y = 1024 + (i // 16) * 16
        AT['opaco'][y:y + 16, x:x + 16] = [srgb(rgb[0]), srgb(rgb[1]), srgb(rgb[2]), 1.0]
        celle[m.name] = ((x + 8) / W_AT, (y + 8) / W_AT)
    return celle[m.name]
fatti = set()
def incolla(m, img, tab, r):
    if m.name in fatti: return
    fatti.add(m.name); x, y, w, h = r
    c = img.copy(); c.scale(w, h); px = np.empty(w * h * 4, np.float32); c.pixels.foreach_get(px)
    AT[tab][y:y + h, x:x + w] = px.reshape(h, w, 4); bpy.data.images.remove(c)
body.name = 'Saul_corpo'
sel_only([body, capelli], body); bpy.ops.object.join(); body = bpy.context.view_layer.objects.active
for o in (body, face):
    uv = o.data.uv_layers.active.data; gruppi = []
    for p in o.data.polygons:
        m = o.material_slots[p.material_index].material; img, rgb = info_mat(m)
        tab = 'trasp' if rect_of(m.name, TRASP) else 'opaco'; r = rect_of(m.name, TRASP) or rect_of(m.name, OPACO)
        if img is not None and r is not None:
            incolla(m, img, tab, r); x, y, w, h = r
            for li in p.loop_indices:
                u, v = uv[li].uv; u = min(1, max(0, u)); v = min(1, max(0, v))
                uv[li].uv = ((x + 2 + u * (w - 4)) / W_AT, (y + 2 + v * (h - 4)) / W_AT)
        else:
            tab = 'opaco'; cu, cv_ = cella(m, rgb)
            for li in p.loop_indices: uv[li].uv = (cu, cv_)
        gruppi.append(tab)
    o.data.materials.clear()
    usati = sorted(set(gruppi))
    for t in usati: o.data.materials.append(bpy.data.materials.get('saul_' + t) or bpy.data.materials.new('saul_' + t))
    for p, t in zip(o.data.polygons, gruppi): p.material_index = usati.index(t)
for t in ('opaco', 'trasp'):
    im = bpy.data.images.new('saul_' + t, W_AT, W_AT, alpha=True); im.pixels.foreach_set(AT[t].ravel()); im.pack()
    m = bpy.data.materials['saul_' + t]; m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    bs = nt.nodes.new('ShaderNodeBsdfPrincipled'); o_ = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(bs.outputs[0], o_.inputs[0])
    bs.inputs['Roughness'].default_value = 1.0
    try: bs.inputs['Specular IOR Level'].default_value = 0.0
    except Exception: pass
    tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = im; nt.links.new(tx.outputs[0], bs.inputs['Base Color'])
    if t == 'trasp': nt.links.new(tx.outputs['Alpha'], bs.inputs['Alpha']); m.blend_method = 'CLIP'; m.alpha_threshold = 0.5
    else: m.blend_method = 'OPAQUE'
    m.use_backface_culling = False
capelli = body
if False:
    # vecchia via (un materiale per tessuto), tenuta per confronto
    # ---------- 7. materiali per il glTF ----------
    def lin(c): return c
    for m in bpy.data.materials:
        if not m.use_nodes or m.users == 0: continue
        nt = m.node_tree
        imgs = [n.image for n in nt.nodes if n.type == 'TEX_IMAGE' and n.image and n.image.name != 'cotto_vuoto']
        img = next((i for i in imgs if i.name.startswith('cotto_')), imgs[0] if imgs else None)
        rgb = next((tuple(n.outputs[0].default_value) for n in nt.nodes if n.type == 'RGB'), (0.5, 0.5, 0.5, 1))
        nt.nodes.clear(); bs = nt.nodes.new('ShaderNodeBsdfPrincipled'); o_ = nt.nodes.new('ShaderNodeOutputMaterial')
        nt.links.new(bs.outputs[0], o_.inputs[0]); bs.inputs['Roughness'].default_value = 1.0
        try: bs.inputs['Specular IOR Level'].default_value = 0.0
        except Exception: pass
        if img:
            if img.size[0] > 1024: img.scale(1024, max(1, img.size[1] * 1024 // img.size[0]))
            t = nt.nodes.new('ShaderNodeTexImage'); t.image = img; nt.links.new(t.outputs[0], bs.inputs['Base Color'])
            trasp = any(k in m.name for k in ('Eyelash', 'Eyeline', 'Brow', 'Highlight', 'EyeExtra', 'HairBack', 'Iris', 'Mouth'))
            if trasp:
                nt.links.new(t.outputs['Alpha'], bs.inputs['Alpha']); m.blend_method = 'CLIP'; m.alpha_threshold = 0.5
            else: m.blend_method = 'OPAQUE'
        else:
            bs.inputs['Base Color'].default_value = rgb; m.blend_method = 'OPAQUE'
        m.use_backface_culling = False
for o in [o for o in bpy.data.objects if o.type == 'MESH' and o not in (body, capelli, face)]:
    bpy.data.objects.remove(o)
info = (sum(len(p.vertices) - 2 for o in (body, capelli, face) for p in o.data.polygons))
print('TRIANGOLI', info, 'OSSA', len(A.data.bones), 'FORME', len(face.data.shape_keys.key_blocks))
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_skins=True, export_morph=True, export_animations=False,
                          export_apply=False, export_yup=True, export_materials='EXPORT', export_image_format='AUTO')
bpy.ops.wm.save_as_mainfile(filepath=out.replace('.glb', '_gioco.blend'))
