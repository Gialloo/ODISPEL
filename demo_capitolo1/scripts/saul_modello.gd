class_name SaulModello
extends Node3D
## Saul v3 (modello approvato dall'autore il 15/11/2026, base VRoid CC0, stesso stile di Lance) nel Capitolo 1.
## Il .glb ha lo scheletro umanoide VRoid (J_Bip_*): qui le ossa si muovono a mano, con gli stessi numeri dei corpi
## segnaposto (braccia e gambe che oscillano, pose «seduto», «accucciato»...), cosi' la regia e i passi non cambiano.
## Cappotto e coda hanno ossa elastiche (SpringBoneSimulator3D) con collisioni su gambe, fianchi e schiena:
## il cappotto passa dietro le gambe e la coda non entra nella schiena (richiesta dell'autore).
## Il file nasce da tools/blender/saul_esporta_gioco.py (si corregge lo script e si riesporta).

const PERCORSO := "res://assets/personaggi/saul/saul.glb"
const ALTEZZA := 1.78                     # come nel cast (data della V3)
const PASSO := 0.8                        # le gambe vere oscillano un po' meno dei pezzi a blocchi (il passo pieno sembrava un calcio)

## Espressioni del viso: le stesse dei ritratti dei dialoghi (tools/blender/saul_ritratti.py)
const ESPRESSIONI := {
	"neutro": {"BRW_Angry": 0.35, "EYE_Angry": 0.22, "MTH_Fun": 0.3},
	"felice": {"BRW_Joy": 0.5, "EYE_Joy": 0.45, "MTH_Fun": 0.9, "MTH_A": 0.12},
	"arrabbiato": {"ALL_Angry": 0.8},
	"sorpreso": {"ALL_Surprised": 0.8},
	"triste": {"BRW_Sorrow": 0.9, "EYE_Sorrow": 0.6, "MTH_Sorrow": 0.55},
	"serio": {"BRW_Angry": 0.55, "EYE_Angry": 0.4},
	"sfotto": {"BRW_Angry": 0.3, "EYE_Close_R": 0.45, "EYE_Angry": 0.25, "MTH_Fun": 0.7},
}

# angoli in radianti, nello spazio del personaggio (X = di lato; positivo = indietro, come i perni dei segnaposto)
var braccio_s := 0.0
var braccio_d := 0.0
var gamba_s := 0.0
var gamba_d := 0.0
var gomiti := 0.0                         # piega in piu' dei gomiti (in avanti)
var busto := 0.0                          # piega della schiena (positivo = in avanti)
var anca_giu := 0.0                       # metri: abbassa il bacino (accucciato, carica)

var _proxy: Node3D = null                 # il nodo "corpo": se ha i perni gamba_s, braccio_d... li si legge da li'
var _sk: Skeleton3D
var _sim: SpringBoneSimulator3D
var _visi: Array = []                     # MeshInstance3D con le forme del viso
var _ossa := {}
var _asse_x := Vector3.RIGHT              # l'asse X del personaggio nello spazio dello scheletro
var _occhi_t := 2.5
var _chiusura := 0.0
var _espr := "neutro"
var _mats: Array = []


static func esiste() -> bool:
	return ResourceLoader.exists(PERCORSO)


## illuminato = false: materiali senza luci (lo scontro e' tutto «unshaded»)
static func crea(illuminato := true) -> SaulModello:
	var s := SaulModello.new()
	s.name = "saul_modello"
	s._costruisci(illuminato)
	return s


func _costruisci(illuminato: bool) -> void:
	var inst: Node3D = (load(PERCORSO) as PackedScene).instantiate()
	inst.rotation.y = PI                  # il file guarda verso -Z, i personaggi del gioco verso +Z
	add_child(inst)
	_sk = inst.find_children("*", "Skeleton3D", true, false)[0]
	var alto := 0.0
	for c in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		alto = maxf(alto, mi.get_aabb().end.y)
		if mi.find_blend_shape_by_name("EYE_Close") >= 0:
			_visi.append(mi)
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i) as StandardMaterial3D
			if m == null:
				continue
			m = m.duplicate()
			m.roughness = 1.0
			m.metallic = 0.0
			m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			if illuminato:
				m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			else:
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mi.set_surface_override_material(i, m)
			_mats.append(m)
	if alto > 0.1:
		inst.scale = Vector3.ONE * (ALTEZZA / alto)
	for n in ["J_Bip_C_Hips", "J_Bip_C_Spine", "J_Bip_C_Chest", "J_Bip_L_UpperArm", "J_Bip_R_UpperArm", "J_Bip_L_LowerArm", "J_Bip_R_LowerArm",
			"J_Bip_L_UpperLeg", "J_Bip_R_UpperLeg", "J_Bip_L_LowerLeg", "J_Bip_R_LowerLeg"]:
		_ossa[n] = _sk.find_bone(n)
	_elastiche()
	espressione("neutro")


## Ossa elastiche: quattro falde del cappotto e la coda. Collisioni a capsula su cosce, stinchi, bacino e schiena.
func _elastiche() -> void:
	_sim = SpringBoneSimulator3D.new()
	_sim.name = "elastiche"
	_sk.add_child(_sim)
	var catene := [["Saul_Falda_AS_1", "Saul_Falda_AS_3"], ["Saul_Falda_AD_1", "Saul_Falda_AD_3"],
		["Saul_Falda_DS_1", "Saul_Falda_DS_3"], ["Saul_Falda_DD_1", "Saul_Falda_DD_3"], ["Saul_Coda_1", "Saul_Coda_3"]]
	_sim.setting_count = catene.size()
	for i in catene.size():
		var coda: bool = i == 4
		_sim.set_root_bone_name(i, catene[i][0])
		_sim.set_end_bone_name(i, catene[i][1])
		_sim.set_extend_end_bone(i, true)
		_sim.set_end_bone_direction(i, SkeletonModifier3D.BONE_DIRECTION_FROM_PARENT)
		_sim.set_end_bone_length(i, 0.06 if coda else 0.08)
		_sim.set_radius(i, 0.03 if coda else 0.045)
		_sim.set_stiffness(i, 1.6 if coda else 2.2)       # il cappotto di lana e' pesante: torna giu' presto
		_sim.set_drag(i, 0.45 if coda else 0.6)
		_sim.set_gravity(i, 0.4 if coda else 0.8)
		_sim.set_gravity_direction(i, Vector3.DOWN)
	# capsule tra un osso e il suo figlio, calcolate dal riposo dello scheletro
	for s in ["L", "R"]:
		_capsula("J_Bip_%s_UpperLeg" % s, "J_Bip_%s_LowerLeg" % s, 0.085)
		_capsula("J_Bip_%s_LowerLeg" % s, "J_Bip_%s_Foot" % s, 0.065)
	_capsula("J_Bip_C_Hips", "J_Bip_C_Spine", 0.13)
	_capsula("J_Bip_C_Spine", "J_Bip_C_Neck", 0.12)


func _capsula(osso: String, figlio: String, r: float) -> void:
	var b := _sk.find_bone(osso)
	var f := _sk.find_bone(figlio)
	if b < 0 or f < 0:
		return
	var gb := _sk.get_bone_global_rest(b)
	var gf := _sk.get_bone_global_rest(f)
	var loc_f: Vector3 = gb.affine_inverse() * gf.origin       # il figlio, visto dall'osso
	var c := SpringBoneCollisionCapsule3D.new()
	c.bone_name = osso
	c.radius = r
	c.height = loc_f.length() + r * 2.0
	c.position_offset = loc_f * 0.5
	c.rotation_offset = Quaternion(Vector3.UP, loc_f.normalized())
	_sim.add_child(c)


## Collega i perni del corpo segnaposto ("corpo" con gamba_s, gamba_d, braccio_s, braccio_d): li crea vuoti se mancano
func usa_perni(corpo: Node3D) -> void:
	_proxy = corpo
	for n in ["gamba_s", "gamba_d", "braccio_s", "braccio_d"]:
		if corpo.get_node_or_null(n) == null:
			var p := Node3D.new()
			p.name = n
			corpo.add_child(p)


func espressione(nome: String) -> void:
	if not ESPRESSIONI.has(nome):
		nome = "neutro"
	_espr = nome
	for mi: MeshInstance3D in _visi:
		for i in mi.mesh.get_blend_shape_count():
			var k := String(mi.mesh.get_blend_shape_name(i))
			if k != "EYE_Close":
				mi.set_blend_shape_value(i, float(ESPRESSIONI[nome].get(k, 0.0)))


## Rimette a posto le ossa elastiche (dopo un salto di posizione: il cappotto non deve frustare)
func riposa() -> void:
	if _sim:
		_sim.reset()


## Colore dei materiali (il bianco del colpo negli scontri): Color.WHITE per tornare normali
func tinta(c: Color) -> void:
	for m: StandardMaterial3D in _mats:
		m.albedo_color = c


func _ready() -> void:
	riposa.call_deferred()


func _process(delta: float) -> void:
	if _proxy != null:
		braccio_s = _rx("braccio_s")
		braccio_d = _rx("braccio_d")
		gamba_s = _passo(_rx("gamba_s"))
		gamba_d = _passo(_rx("gamba_d"))
	_occhi(delta)
	_posa()


func _passo(a: float) -> float:
	return a if a < -1.0 else a * PASSO        # seduto e accucciato restano pieni


func _rx(n: String) -> float:
	var p: Node3D = _proxy.get_node_or_null(n)
	return p.rotation.x if p else 0.0


func _occhi(delta: float) -> void:
	_occhi_t -= delta
	if _occhi_t <= 0.0:
		_occhi_t = randf_range(2.2, 5.0)
		_chiusura = 1.0
	_chiusura = maxf(0.0, _chiusura - delta * 8.0)
	var v := 1.0 - absf(_chiusura * 2.0 - 1.0) if _chiusura > 0.0 else 0.0
	for mi: MeshInstance3D in _visi:
		var i := mi.find_blend_shape_by_name("EYE_Close")
		mi.set_blend_shape_value(i, v)


# Le rotazioni si fanno attorno all'asse X del personaggio, sul giunto di ogni osso, a partire dal riposo.
func _posa() -> void:
	_asse_x = (_sk.global_transform.basis.inverse() * global_transform.basis * Vector3.RIGHT).normalized()
	var acc := {}                          # rotazione accumulata (spazio scheletro) di ogni osso toccato
	var g := {}                            # basi globali volute
	var ruota := {
		"J_Bip_C_Spine": busto * 0.5, "J_Bip_C_Chest": busto * 0.5,
		"J_Bip_L_UpperLeg": gamba_s, "J_Bip_R_UpperLeg": gamba_d,
		"J_Bip_L_LowerLeg": _ginocchio(gamba_s), "J_Bip_R_LowerLeg": _ginocchio(gamba_d),
		"J_Bip_L_UpperArm": braccio_s, "J_Bip_R_UpperArm": braccio_d,
		"J_Bip_L_LowerArm": -gomiti - 0.1 - maxf(0.0, -braccio_s) * 0.35, "J_Bip_R_LowerArm": -gomiti - 0.1 - maxf(0.0, -braccio_d) * 0.35,
	}
	var hb: int = _ossa["J_Bip_C_Hips"]
	if hb >= 0:
		var rp := _sk.get_bone_rest(hb).origin
		_sk.set_bone_pose_position(hb, rp + Vector3(0, -anca_giu / maxf(0.01, (get_child(0) as Node3D).scale.y), 0))
	for n in ["J_Bip_C_Spine", "J_Bip_C_Chest", "J_Bip_L_UpperLeg", "J_Bip_R_UpperLeg", "J_Bip_L_LowerLeg", "J_Bip_R_LowerLeg",
			"J_Bip_L_UpperArm", "J_Bip_R_UpperArm", "J_Bip_L_LowerArm", "J_Bip_R_LowerArm"]:
		var b: int = _ossa[n]
		if b < 0:
			continue
		var par := _sk.get_bone_parent(b)
		var r_par := Basis()
		var su := par
		while su >= 0:                     # l'antenato piu' vicino gia' ruotato (spalle e collo seguono il petto)
			if acc.has(su):
				r_par = acc[su]
				break
			su = _sk.get_bone_parent(su)
		var r: Basis = Basis(_asse_x, float(ruota[n])) * r_par
		acc[b] = r
		var gr := _sk.get_bone_global_rest(b).basis
		var gp := _sk.get_bone_global_rest(par).basis if par >= 0 else Basis()
		var voluta: Basis = r * gr
		var genitore: Basis = r_par * gp
		_sk.set_bone_pose_rotation(b, (genitore.inverse() * voluta).get_rotation_quaternion())


# Il ginocchio segue la coscia: seduto o accucciato lo stinco torna verticale; nel passo, la gamba dietro si piega.
func _ginocchio(a: float) -> float:
	return maxf(0.0, -a) * 1.0 + maxf(0.0, a) * 0.6
