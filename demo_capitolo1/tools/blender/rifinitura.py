# Rifinitura di Saul v3: niente compenetrazioni (cappotto contro gambe, capelli contro testa e cappotto) e trama dei tessuti.
# anti_clip() si chiama dopo aver messo la posa: "cuoce" la posa nel cappotto e nei capelli e li sposta fuori dai corpi.
import bpy, bmesh, math
from mathutils import Vector as Vec
from mathutils.bvhtree import BVHTree

def upd(): bpy.context.view_layer.update()

def _world_coords(o, only_armature=True):
    """coordinate mondo dei vertici con la sola armatura applicata (stesso numero di vertici della mesh)"""
    saved=[(m, m.show_viewport, m.show_render) for m in o.modifiers]
    if only_armature:
        for m,_,_ in saved:
            if m.type!='ARMATURE': m.show_viewport=False
    upd(); dg=bpy.context.evaluated_depsgraph_get(); ev=o.evaluated_get(dg); me=ev.to_mesh()
    co=[ev.matrix_world@v.co for v in me.vertices]; ev.to_mesh_clear()
    for m,v,r in saved: m.show_viewport=v; m.show_render=r
    upd(); return co

def _bake(o, co):
    """fissa la posa nella mesh: toglie l'armatura e scrive le coordinate gia' deformate"""
    for m in list(o.modifiers):
        if m.type=='ARMATURE': o.modifiers.remove(m)
    inv=o.matrix_world.inverted()
    for v,c in zip(o.data.vertices,co): v.co=inv@c
    o.data.update()

def _neighbors(o):
    nb=[[] for _ in o.data.vertices]
    for e in o.data.edges:
        a,b=e.vertices; nb[a].append(b); nb[b].append(a)
    return nb

def _smooth_disp(disp, nb, it=6):
    for _ in range(it):
        new=[]
        for i,d in enumerate(disp):
            if not nb[i]: new.append(d); continue
            avg=sum((disp[j] for j in nb[i]),Vec())/len(nb[i])
            new.append(d if d.length>avg.length else d*0.5+avg*0.5)   # non perde mai la spinta piu' forte
        disp=new
    return disp

def _body_bvh(A, skip_hair=True, extra=()):
    """BVH del corpo in posa (solo armatura), senza la parte capelli del corpo VRoid"""
    verts=[]; polys=[]
    for name in ('Saul_corpo','Saul_testa')+tuple(extra):
        o=bpy.data.objects.get(name)
        if not o: continue
        co=_world_coords(o) if any(m.type=='ARMATURE' for m in o.modifiers) else [o.matrix_world@v.co for v in o.data.vertices]
        hair=[i for i,m in enumerate(o.data.materials) if m and 'HAIR' in m.name.upper()]
        base=len(verts); verts+=co
        for p in o.data.polygons:
            if skip_hair and p.material_index in hair: continue
            polys.append([base+i for i in p.vertices])
    return BVHTree.FromPolygons(verts,polys)

def _leg_capsules(A, body):
    """gambe come capsule lungo le ossa in posa; il raggio si misura sul corpo"""
    P=A.pose.bones; caps=[]
    for s in ('L','R'):
        pts=[A.matrix_world@P[f'J_Bip_{s}_{n}'].head for n in ('UpperLeg','LowerLeg','Foot')]
        for a,b in zip(pts,pts[1:]):
            samples=[]
            for k in range(7):
                c=a.lerp(b,k/6); hit=body.find_nearest(c,0.3)
                samples.append(min(0.12,(hit[0]-c).length) if hit[0] else 0.06)
            caps.append((a,b,samples))
    return caps

def anti_clip(A, margine_cappotto=0.03, margine_capelli=0.007):
    upd()
    P=A.pose.bones
    fwd=(A.matrix_world.to_3x3()@P['J_Bip_C_Hips'].matrix.to_3x3()@A.data.bones['J_Bip_C_Hips'].matrix_local.to_3x3().inverted()@Vec((0,1,0))).normalized()
    body=_body_bvh(A)
    hipz=(A.matrix_world@P['J_Bip_C_Hips'].head).z
    # --- cappotto: le gambe passano nell'apertura, il pannello resta dietro/di lato alla gamba ---
    caps=_leg_capsules(A, body)
    cap=bpy.data.objects['cappotto']; co=_world_coords(cap); nb=_neighbors(cap)
    for rnd in range(3):
        disp=[Vec() for _ in co]
        for i,v in enumerate(co):
            if v.z>hipz+0.02: continue
            for a,b,rs in caps:
                ab=b-a; t=max(0,min(1,(v-a).dot(ab)/ab.length_squared)); c=a+ab*t
                r=rs[min(6,int(round(t*6)))]+margine_cappotto; rad=v-c-ab.normalized()*(v-c).dot(ab.normalized())
                d=rad.length
                if d>=r: continue
                dr=rad/d if d>1e-5 else -fwd
                if dr.dot(fwd)>0:   # davanti alla gamba: lo giro di lato e indietro, cosi' il cappotto passa dietro
                    dr=(dr-fwd*dr.dot(fwd)*1.7).normalized()
                tgt=c+dr*r+ab.normalized()*(v-c).dot(ab.normalized())
                if (tgt-v).length>disp[i].length: disp[i]=tgt-v
        disp=_smooth_disp(disp,nb)
        co=[v+d for v,d in zip(co,disp)]
    # e fuori dal corpo (fianchi, sedere) con il margine dello spessore del tessuto
    for i,v in enumerate(co):
        hit=body.find_nearest(v,0.08)
        if hit[0] and (v-hit[0]).dot(hit[1])<margine_cappotto*0.6:
            co[i]=hit[0]+hit[1]*margine_cappotto*0.6
    _bake(cap,co)
    # --- capelli: ciocche fuori da testa, collo e cappotto (che ora e' fisso nella posa) ---
    upd()
    capp=bpy.data.objects['cappotto']; dg=bpy.context.evaluated_depsgraph_get()
    cev=capp.evaluated_get(dg); cme=cev.to_mesh()
    cb=BVHTree.FromPolygons([cev.matrix_world@v.co for v in cme.vertices],[list(p.vertices) for p in cme.polygons]); cev.to_mesh_clear()
    mossi=0
    for o in [x for x in bpy.data.objects if x.name.startswith('ciocca')]:
        upd(); co=[o.matrix_world@v.co for v in o.data.vertices]; nb=_neighbors(o); disp=[Vec() for _ in co]
        for i,v in enumerate(co):
            for tree,mg in ((body,margine_capelli),(cb,margine_capelli*1.6)):
                hit=tree.find_nearest(v+disp[i],0.06)
                if hit[0] is None: continue
                n=hit[1]; dd=(v+disp[i]-hit[0]).dot(n)
                if dd<mg: disp[i]+=n*(mg-dd)
        disp=_smooth_disp(disp,nb,4)
        if any(d.length>1e-4 for d in disp):
            mossi+=1; inv=o.matrix_world.inverted()
            for v,c,d in zip(o.data.vertices,co,disp): v.co=inv@(c+d)
            o.data.update()
    print('anti_clip: ciocche spostate',mossi)

# ---------------- tessuti ----------------
def _insert_color_mod(m, build):
    """moltiplica il colore base del materiale toon per una trama procedurale (in coordinate oggetto, segue il corpo)"""
    nt=m.node_tree
    sh=[n for n in nt.nodes if n.bl_idname=='ShaderNodeMixRGB' and n.blend_type=='MULTIPLY' and n.inputs[1].is_linked and not n.inputs[2].is_linked]
    if not sh: return False
    src=sh[0].inputs[1].links[0].from_socket
    targets=[l.to_socket for l in nt.links if l.from_socket==src]
    val=build(nt)
    mul=nt.nodes.new('ShaderNodeMixRGB'); mul.blend_type='MULTIPLY'; mul.inputs[0].default_value=1
    nt.links.new(src,mul.inputs[1]); nt.links.new(val,mul.inputs[2])
    for t in targets: nt.links.new(mul.outputs[0],t)
    return True

def _tc(nt):
    tc=nt.nodes.new('ShaderNodeTexCoord'); return tc.outputs['Object']

def _ramp(nt, sock, lo, hi):
    r=nt.nodes.new('ShaderNodeMapRange'); nt.links.new(sock,r.inputs[0]); r.inputs[3].default_value=lo; r.inputs[4].default_value=hi
    return r.outputs[0]

def _twill(nt, scale, lo, hi):
    """saia (lana del cappotto, pantaloni): righe diagonali fini + fiammato"""
    co=_tc(nt); w=nt.nodes.new('ShaderNodeTexWave'); w.wave_type='BANDS'; w.bands_direction='DIAGONAL'; w.inputs['Scale'].default_value=scale
    w.inputs['Distortion'].default_value=1.5; w.inputs['Detail'].default_value=1; nt.links.new(co,w.inputs['Vector'])
    n=nt.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value=scale*0.6; n.inputs['Detail'].default_value=6; nt.links.new(co,n.inputs['Vector'])
    mx=nt.nodes.new('ShaderNodeMath'); mx.operation='MULTIPLY_ADD'; nt.links.new(w.outputs['Fac'],mx.inputs[0]); mx.inputs[1].default_value=0.18; nt.links.new(n.outputs['Fac'],mx.inputs[2])   # righe appena accennate: piu' forti fanno moire'
    return _ramp(nt, mx.outputs[0], lo, hi)

def _weave(nt, scale, lo, hi):
    """tela (cotone della camicia, maglia del gilet): trama e ordito incrociati"""
    co=_tc(nt); a=nt.nodes.new('ShaderNodeTexWave'); a.bands_direction='X'; a.inputs['Scale'].default_value=scale; nt.links.new(co,a.inputs['Vector'])
    b=nt.nodes.new('ShaderNodeTexWave'); b.bands_direction='Z'; b.inputs['Scale'].default_value=scale; nt.links.new(co,b.inputs['Vector'])
    n=nt.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value=scale*0.35; n.inputs['Detail'].default_value=4; nt.links.new(co,n.inputs['Vector'])
    m1=nt.nodes.new('ShaderNodeMath'); m1.operation='MULTIPLY'; nt.links.new(a.outputs['Fac'],m1.inputs[0]); nt.links.new(b.outputs['Fac'],m1.inputs[1])
    m2=nt.nodes.new('ShaderNodeMath'); m2.operation='MULTIPLY_ADD'; nt.links.new(m1.outputs[0],m2.inputs[0]); m2.inputs[1].default_value=0.6; nt.links.new(n.outputs['Fac'],m2.inputs[2])
    return _ramp(nt, m2.outputs[0], lo, hi)

def tessuti():
    fatti=[]
    for m in bpy.data.materials:
        if not m.use_nodes: continue
        k=m.name
        if k in ('cappotto',): ok=_insert_color_mod(m, lambda nt:_twill(nt,70,0.92,1.05))
        elif k=='fodera': ok=_insert_color_mod(m, lambda nt:_weave(nt,220,0.92,1.04))
        elif 'Tops' in k: ok=_insert_color_mod(m, lambda nt:_weave(nt,150,0.90,1.04))
        elif 'Bottoms' in k: ok=_insert_color_mod(m, lambda nt:_twill(nt,110,0.90,1.06))
        elif 'Tie' in k: ok=_insert_color_mod(m, lambda nt:_twill(nt,160,0.88,1.06))
        elif k=='polsino': ok=_insert_color_mod(m, lambda nt:_weave(nt,150,0.92,1.03))
        else: continue
        fatti.append((k,ok))
    print('tessuti:',fatti)
