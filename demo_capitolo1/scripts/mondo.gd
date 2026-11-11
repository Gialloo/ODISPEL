extends Node3D
## La città: costruisce le zone, muove chi guida il gruppo, fa seguire gli altri,
## controlla le percezioni passive e gli inneschi della regia.
## Tutto fatto di forme semplici: è un segnaposto da sostituire con modelli veri.

signal avviso(chi: String, punto: Dictionary)      # chi guida nota qualcosa (balloon)
signal esamina_cambiato(punto)                     # punto esaminabile vicino (o null)
signal innesco(id: String)                         # regia: il giocatore è arrivato in un punto

const VEL := 5.0
const RAGGIO_AVVISO := 6.0
const RAGGIO_ESAMINA := 1.9
const PASSO_SCIA := 0.12
const DISTANZA_SEGUACI := 9    # quanti passi di scia tra un membro e l'altro

## Colori segnaposto dei quattro (streetwear e divise, guida di stile del 18/10).
const ASPETTO := {
	"lance": {"corpo": Color("#1b2238"), "gambe": Color("#11141f"), "accento": Color("#ff2340"), "pelle": Color("#e7b48f"), "capelli": Color("#15151c")},
	"nox": {"corpo": Color("#24365c"), "gambe": Color("#161a28"), "accento": Color("#2ef2ff"), "pelle": Color("#f1c9a5"), "capelli": Color("#3a2550")},
	"saul": {"corpo": Color("#45603a"), "gambe": Color("#4a4a4a"), "accento": Color("#d8ff3a"), "pelle": Color("#c98e66"), "capelli": Color("#3a2a1e")},
	"rio": {"corpo": Color("#7b3cff"), "gambe": Color("#2b2140"), "accento": Color("#ffd23a"), "pelle": Color("#d9a079"), "capelli": Color("#efeaff")},
}

var camera: Camera3D
var zona := ""
var gruppo: Array[String] = []          # gruppo[0] guida
var corpi := {}                         # chi -> Node3D
var punti: Array = []                   # punti della zona (dal JSON)
var fatti := {}                         # id punto -> true
var avvisati := {}                      # "id|chi" -> true
var inneschi: Array = []                # [{id, z_max, fatto}]
var controllo := false
var input_stick := Vector2.ZERO         # dal joystick touch
var limiti := Rect2()
var regia_camera := false

var _scia: Array[Vector3] = []
var _punto_vicino = null
var _zona_root: Node3D
var _neon_tremolanti: Array = []
var _rio_stato := ""
var _t := 0.0
var _mat_cache := {}

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 55.0
	camera.far = 160.0
	add_child(camera)
	_ambiente()
	_pioggia()

# ---------------------------------------------------------------- zone

func carica_zona(nome: String, membri: Array, dati_punti: Array) -> void:
	if _zona_root:
		_zona_root.queue_free()
	for c in corpi.values():
		c.queue_free()
	corpi.clear()
	_neon_tremolanti.clear()
	_zona_root = Node3D.new()
	add_child(_zona_root)
	zona = nome
	gruppo.assign(membri)
	punti = dati_punti
	inneschi.clear()
	var partenza := Vector3.ZERO
	if nome == "vicolo":
		_costruisci_vicolo()
		partenza = Vector3(0, 0, 1)
		limiti = Rect2(-2.7, -38.8, 5.4, 41.0)
		inneschi = [{"id": "sagoma", "z_max": -19.0, "fatto": false}, {"id": "rio", "z_max": -33.5, "fatto": false}]
	else:
		_costruisci_quartiere()
		partenza = Vector3(110, 0, 6)
		limiti = Rect2(95.5, -21.0, 29.0, 29.5)
	for i in gruppo.size():
		var chi: String = gruppo[i]
		var p := _persona(chi)
		p.position = partenza + Vector3(0, 0, i * 1.1)
		_zona_root.add_child(p)
		corpi[chi] = p
	_scia.clear()
	for i in DISTANZA_SEGUACI * 4:
		_scia.append(partenza + Vector3(0, 0, i * PASSO_SCIA))
	_punto_vicino = null
	_metti_camera(true)

func guida() -> Node3D:
	return corpi.get(gruppo[0]) if not gruppo.is_empty() else null

func testa(chi: String) -> Vector3:
	var c: Node3D = corpi.get(chi)
	if c == null:
		return Vector3.ZERO
	var alt := 1.25 if (chi == "rio" and _rio_stato != "") else 1.95
	return c.global_position + Vector3(0, alt, 0)

func cambia_guida() -> String:
	if gruppo.size() < 2:
		return gruppo[0]
	var vecchia := guida()
	gruppo.push_back(gruppo.pop_front())
	var nuova := guida()
	# la nuova guida prende il posto della vecchia, così la telecamera non salta
	var tmp := nuova.position
	nuova.position = vecchia.position
	vecchia.position = tmp
	_punto_vicino = null
	esamina_cambiato.emit(null)
	return gruppo[0]

func segna_fatto(id: String) -> void:
	fatti[id] = true
	_punto_vicino = null
	esamina_cambiato.emit(null)

# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	_t += delta
	for n in _neon_tremolanti:
		if is_instance_valid(n):
			var on := fmod(_t * 7.3 + n.get_meta("fase"), 9.0) > 0.6
			n.visible = on
	_anima_rio(delta)
	if controllo:
		_muovi(delta)
		_percezioni()
		_controlla_inneschi()
	if not regia_camera:
		_metti_camera(false, delta)

func _muovi(delta: float) -> void:
	var g := guida()
	if g == null:
		return
	var dir := input_stick
	if dir == Vector2.ZERO:
		dir = Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if dir.length() > 1.0:
		dir = dir.normalized()
	var passo := Vector3(dir.x, 0, dir.y) * VEL * delta
	var p := g.position + passo
	p.x = clampf(p.x, limiti.position.x, limiti.end.x)
	p.z = clampf(p.z, limiti.position.y, limiti.end.y)
	var mosso := p.distance_to(g.position)
	g.position = p
	if dir.length() > 0.1:
		var target_rot := atan2(dir.x, dir.y)
		g.rotation.y = lerp_angle(g.rotation.y, target_rot, minf(1.0, delta * 14.0))
		_cammina(g, delta)
	if mosso > 0.0 and g.position.distance_to(_scia[0]) >= PASSO_SCIA:
		_scia.push_front(g.position)
		if _scia.size() > DISTANZA_SEGUACI * 5:
			_scia.pop_back()
	for i in range(1, gruppo.size()):
		var f: Node3D = corpi[gruppo[i]]
		var idx := mini(i * DISTANZA_SEGUACI, _scia.size() - 1)
		var meta: Vector3 = _scia[idx]
		var d := meta - f.position
		if d.length() > 0.02:
			f.position = f.position.lerp(meta, minf(1.0, delta * 8.0))
			f.rotation.y = lerp_angle(f.rotation.y, atan2(d.x, d.z), minf(1.0, delta * 10.0))
			_cammina(f, delta)

func _cammina(n: Node3D, delta: float) -> void:
	var b: Node3D = n.get_node_or_null("corpo")
	if b:
		b.position.y = absf(sin(_t * 11.0)) * 0.06

func _percezioni() -> void:
	var g := guida()
	var chi := gruppo[0]
	var vicino = null
	for p in punti:
		var id: String = p["id"]
		if fatti.has(id):
			continue
		var per: String = p.get("chi", "tutti")
		if per != "tutti" and per != chi:
			continue
		var pos := Vector3(p["pos"][0], 0, p["pos"][1])
		var d := Vector2(g.position.x - pos.x, g.position.z - pos.z).length()
		var chiave := id + "|" + chi
		if d < RAGGIO_AVVISO and not avvisati.has(chiave):
			avvisati[chiave] = true
			avviso.emit(chi, p)
		if d < RAGGIO_ESAMINA:
			vicino = p
	if vicino != _punto_vicino:
		_punto_vicino = vicino
		esamina_cambiato.emit(vicino)

func _controlla_inneschi() -> void:
	var g := guida()
	for i in inneschi:
		if not i["fatto"] and g.position.z < i["z_max"]:
			i["fatto"] = true
			innesco.emit(i["id"])

func _metti_camera(subito: bool, delta := 0.0) -> void:
	var g := guida()
	if g == null:
		return
	var off := Vector3(0, 3.6, 6.0) if zona == "vicolo" else Vector3(0, 5.2, 7.4)
	var voluto := g.position + off
	var guarda := g.position + Vector3(0, 1.1, -2.6)
	if subito:
		camera.position = voluto
	else:
		camera.position = camera.position.lerp(voluto, minf(1.0, delta * 5.0))
	camera.look_at(guarda, Vector3.UP)

# ---------------------------------------------------------------- regia

const INQUADRATURE := {
	"rio_lontano": [Vector3(0.6, 2.0, -31.0), Vector3(0.9, 0.9, -45.0)],
	"rio_vicino": [Vector3(2.8, 1.3, -42.2), Vector3(0.9, 0.7, -45.2)],
	"lance_volto": [Vector3(-1.2, 1.75, -40.6), Vector3(0.0, 1.65, -38.2)],
	"due": [Vector3(4.3, 2.6, -39.0), Vector3(0.3, 0.9, -42.8)],
	"alto": [Vector3(0.0, 6.0, -36.0), Vector3(0.6, 0.0, -44.0)],
}

func camera_a(nome: String, durata: float) -> void:
	regia_camera = true
	var s: Array = INQUADRATURE.get(nome, [camera.position, camera.position + Vector3.FORWARD])
	if durata <= 0.0:
		camera.position = s[0]
		camera.look_at(s[1], Vector3.UP)
		return
	var da_pos := camera.position
	var da_look := camera.position - camera.global_transform.basis.z * 6.0
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(k: float):
		camera.position = da_pos.lerp(s[0], k)
		camera.look_at(da_look.lerp(s[1], k), Vector3.UP), 0.0, 1.0, durata)
	await tw.finished

func camera_libera() -> void:
	regia_camera = false

func lance_avanza(z: float, durata: float) -> void:
	var l: Node3D = corpi.get("lance")
	if l == null:
		return
	l.rotation.y = PI
	var tw := create_tween()
	tw.tween_property(l, "position", Vector3(0.0, 0, z), durata)
	await tw.finished

func rio_azione(a: String) -> void:
	var r: Node3D = _zona_root.get_node_or_null("rio_scena")
	if r == null:
		return
	match a:
		"rovista", "annusa", "ferma":
			_rio_stato = a
		"gira":
			_rio_stato = "ferma"
			var tw := create_tween()
			tw.tween_property(r, "rotation:y", 0.0, 0.35)
			await tw.finished
		"salta":
			_rio_stato = "ferma"
			var tw := create_tween()
			tw.tween_property(r, "position", Vector3(-1.7, 0.95, -46.2), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(r, "rotation:y", 0.35, 0.28)
			await tw.finished
		"torna":
			var tw := create_tween()
			tw.tween_property(r, "position", Vector3(0.9, 0, -45.2), 0.5)
			tw.parallel().tween_property(r, "rotation:y", PI, 0.5)
			await tw.finished
			_rio_stato = "rovista"

func rio_luce() -> void:
	var r: Node3D = _zona_root.get_node_or_null("rio_scena")
	if r:
		_sagoma(r, false)
	var l: OmniLight3D = _zona_root.get_node_or_null("luce_rio")
	if l:
		l.light_color = Color("#bfe8ff")
		l.light_energy = 2.2

func _anima_rio(_delta: float) -> void:
	if _zona_root == null:
		return
	var r: Node3D = _zona_root.get_node_or_null("rio_scena")
	if r == null:
		return
	var b: Node3D = r.get_node_or_null("corpo")
	if b == null:
		return
	match _rio_stato:
		"rovista":
			b.rotation.x = 0.55 + sin(_t * 5.0) * 0.18
			b.position.y = -0.45
		"annusa":
			b.rotation.x = 0.35 + sin(_t * 14.0) * 0.05
			b.position.y = -0.4
		_:
			b.rotation.x = lerpf(b.rotation.x, 0.2, 0.1)
			b.position.y = -0.4

# ---------------------------------------------------------------- costruzione

func _mat(col: Color, emiss := 0.0, lucido := false) -> StandardMaterial3D:
	var k := "%s|%s|%s" % [col.to_html(), emiss, lucido]
	if _mat_cache.has(k):
		return _mat_cache[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	if emiss > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emiss
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if lucido:
		m.metallic = 0.7
		m.roughness = 0.12
	else:
		m.roughness = 0.85
	_mat_cache[k] = m
	return m

func _box(pos: Vector3, size: Vector3, col: Color, emiss := 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, emiss)
	mi.position = pos
	(parent if parent else _zona_root).add_child(mi)
	return mi

func _sfera(pos: Vector3, r: float, col: Color, emiss := 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = _mat(col, emiss)
	mi.position = pos
	(parent if parent else _zona_root).add_child(mi)
	return mi

func _luce(pos: Vector3, col: Color, energia := 1.6, raggio := 9.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energia
	l.omni_range = raggio
	_zona_root.add_child(l)
	return l

func _neon(pos: Vector3, size: Vector3, col: Color, riflesso := true) -> MeshInstance3D:
	var n := _box(pos, size, col, 3.0)
	if riflesso:
		# riflesso finto sul pavimento bagnato (trucco economico della guida di stile)
		var r := _box(Vector3(pos.x, 0.012, pos.z + 0.6), Vector3(size.x * 0.8, 0.01, 2.6), col.darkened(0.55), 1.0)
		r.transparency = 0.45
	return n

func _ambiente() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#05070d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#4a5a80")
	env.ambient_light_energy = 1.25
	env.fog_enabled = true
	env.fog_light_color = Color("#0b1a1e")
	env.fog_density = 0.016
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.12
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sole := DirectionalLight3D.new()
	sole.light_color = Color("#5a78c8")
	sole.light_energy = 0.6
	sole.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sole)

func _pioggia() -> void:
	var p := CPUParticles3D.new()
	p.amount = 260
	p.lifetime = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(9, 0.5, 9)
	p.direction = Vector3(0.1, -1, 0)
	p.spread = 3.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 16.0
	p.initial_velocity_max = 20.0
	var q := QuadMesh.new()
	q.size = Vector2(0.015, 0.45)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.9, 1.0, 0.28)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	q.material = m
	p.mesh = q
	p.position = Vector3(0, 6, -4)
	camera.add_child(p)

func _finestre(x: float, z0: float, z1: float, faccia: float, seme: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var z := z0
	while z > z1:
		for piano in 4:
			if rng.randf() < 0.16:
				var col: Color = [Color("#ffcf7a"), Color("#7ad7ff"), Color("#c7ffb0")][rng.randi() % 3]
				_box(Vector3(x + faccia * 0.02, 3.2 + piano * 2.4, z), Vector3(0.05, 1.0, 0.8), col, 1.4)
			else:
				_box(Vector3(x + faccia * 0.02, 3.2 + piano * 2.4, z), Vector3(0.05, 1.0, 0.8), Color("#141824"))
		z -= rng.randf_range(2.2, 3.4)

func _costruisci_vicolo() -> void:
	var muro := Color("#121621")
	_box(Vector3(0, -0.05, -22), Vector3(9, 0.1, 54), Color("#0a0d12")).material_override = _mat(Color("#0b0e14"), 0.0, true)
	_box(Vector3(-4.6, 6, -20), Vector3(3, 12, 48), muro)
	_box(Vector3(4.6, 6, -20), Vector3(3, 12, 48), muro)
	_finestre(-3.08, 1, -40, 1, 3)
	_finestre(3.08, 1, -40, -1, 7)
	# marciapiedi e bordi
	_box(Vector3(-2.95, 0.08, -20), Vector3(0.3, 0.16, 46), Color("#1b2030"))
	_box(Vector3(2.95, 0.08, -20), Vector3(0.3, 0.16, 46), Color("#1b2030"))
	# insegne al neon (2-4 per scena)
	_neon(Vector3(-3.05, 3.4, -5), Vector3(0.08, 0.5, 2.4), Color("#3dff8a"))
	_neon(Vector3(3.05, 4.2, -13), Vector3(0.08, 1.6, 0.4), Color("#2ef2ff"))
	_neon(Vector3(-3.05, 2.9, -23), Vector3(0.08, 0.35, 1.8), Color("#ff2340"))
	_luce(Vector3(-2.2, 3.3, -5), Color("#3dff8a"), 1.4, 8.0)
	_luce(Vector3(2.2, 4.0, -13), Color("#2ef2ff"), 1.4, 8.0)
	_luce(Vector3(-2.2, 2.8, -23), Color("#ff2340"), 1.2, 7.0)
	# cavi tra i palazzi
	for z in [-3.0, -11.0, -19.5, -29.0]:
		_box(Vector3(0, 7.5 + fmod(absf(z), 2.0), z), Vector3(6.2, 0.04, 0.04), Color("#05060a"))
	# arredo: cassonetto, scatoloni, distributore
	_box(Vector3(2.3, 0.65, -25.0), Vector3(1.0, 1.3, 1.9), Color("#20402c"))
	_box(Vector3(2.45, 0.2, -26.4), Vector3(0.5, 0.35, 0.7), Color("#3b4230"))   # sacca nascosta
	_box(Vector3(-2.3, 0.3, -9.5), Vector3(0.7, 0.6, 0.7), Color("#3a2e22"))
	_box(Vector3(-2.25, 0.85, -9.4), Vector3(0.6, 0.5, 0.6), Color("#45362a"))
	var dist := _box(Vector3(-2.45, 1.0, -17.0), Vector3(0.9, 2.0, 0.9), Color("#1d2a3a"))
	_box(Vector3(-1.98, 1.25, -17.0), Vector3(0.02, 1.2, 0.7), Color("#9fe7ff"), 1.6, null)
	var _d = dist
	# bossoli nel muro (piccoli, quasi invisibili)
	for k in 3:
		_box(Vector3(3.09, 1.2 + k * 0.12, -9.0 + k * 0.1), Vector3(0.02, 0.05, 0.03), Color("#c9a24a"), 0.4)
	# fondo: piano terra aperto del palazzo, saracinesca mezza alzata
	_box(Vector3(0, 6, -50.5), Vector3(9, 12, 1), muro)
	_box(Vector3(0, 7.5, -40.0), Vector3(6.2, 9, 0.5), Color("#151a26"))
	_box(Vector3(0, 2.85, -40.05), Vector3(5.8, 0.5, 0.25), Color("#3c4252"))     # saracinesca
	_box(Vector3(0, 3.45, -45.0), Vector3(6.2, 0.1, 10.0), Color("#0d1018"))      # soffitto
	_box(Vector3(-0.3, 3.3, -48.2), Vector3(2.4, 0.08, 0.12), Color("#9fe7ff"), 3.0)  # tubo che tremola
	var tubo := _box(Vector3(-0.3, 3.3, -48.2), Vector3(2.4, 0.09, 0.13), Color("#d8f6ff"), 4.0)
	tubo.set_meta("fase", 1.7)
	_neon_tremolanti.append(tubo)
	var lr := _luce(Vector3(-0.2, 2.9, -47.8), Color("#7ab8ff"), 1.4, 9.0)
	lr.name = "luce_rio"
	# casse e resti organici
	_box(Vector3(-1.7, 0.45, -46.3), Vector3(1.2, 0.9, 1.0), Color("#3a2e22"))
	_box(Vector3(2.4, 0.5, -47.5), Vector3(1.0, 1.0, 1.0), Color("#2e2a24"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 9:
		_sfera(Vector3(0.9 + rng.randf_range(-0.8, 0.8), 0.1, -46.2 + rng.randf_range(-0.5, 0.5)), rng.randf_range(0.12, 0.26), Color("#6a2a7a").lerp(Color("#a14a6a"), rng.randf()))
	# Rio, girato di spalle, in controluce: da lontano è solo una sagoma
	var rio := _persona("rio")
	rio.name = "rio_scena"
	rio.position = Vector3(0.9, 0, -45.2)
	rio.rotation.y = PI
	_zona_root.add_child(rio)
	_sagoma(rio, true)
	_rio_stato = "rovista"

func _costruisci_quartiere() -> void:
	var o := Vector3(110, 0, -6)
	_box(o + Vector3(0, -0.05, 0), Vector3(44, 0.1, 44), Color("#0b0e14")).material_override = _mat(Color("#0b0e14"), 0.0, true)
	# palazzi intorno alla piazza
	var palazzi := [
		[Vector3(-19, 7, -10), Vector3(6, 14, 16)], [Vector3(-19, 5, 10), Vector3(6, 10, 14)],
		[Vector3(19, 6, -12), Vector3(6, 12, 14)], [Vector3(19, 8, 8), Vector3(6, 16, 14)],
		[Vector3(-6, 7, -19), Vector3(14, 14, 6)], [Vector3(12, 5, -19), Vector3(10, 10, 6)],
	]
	for pz in palazzi:
		_box(o + pz[0], pz[1], Color("#131826"))
	_finestre(o.x - 15.97, o.z + 2, o.z - 17, 1, 21)
	_finestre(o.x + 15.97, o.z + 14, o.z - 18, -1, 22)
	# edicola, panchina, lampioni
	_box(o + Vector3(-9, 1.2, -6), Vector3(2.4, 2.4, 1.6), Color("#2b3d2e"))
	_box(o + Vector3(-9, 2.5, -6), Vector3(2.8, 0.15, 2.0), Color("#1e2a20"))
	_box(o + Vector3(-4, 0.35, 10.5), Vector3(2.2, 0.15, 0.6), Color("#3a2e22"))
	for lp in [Vector3(-12, 0, 6), Vector3(12, 0, 6), Vector3(0, 0, -14)]:
		_box(o + lp + Vector3(0, 2.2, 0), Vector3(0.12, 4.4, 0.12), Color("#20242e"))
		_box(o + lp + Vector3(0, 4.45, 0), Vector3(0.5, 0.12, 0.5), Color("#ffe3a3"), 2.4)
	_luce(o + Vector3(-12, 4.0, 6), Color("#ffd89a"), 1.2, 9.0)
	_luce(o + Vector3(12, 4.0, 6), Color("#ffd89a"), 1.2, 9.0)
	# insegne
	_neon(o + Vector3(-15.95, 3.2, -2), Vector3(0.08, 0.5, 3.0), Color("#3dff8a"))
	_neon(o + Vector3(15.95, 3.6, -4), Vector3(0.08, 1.8, 0.45), Color("#ff2340"))
	_luce(o + Vector3(-14.8, 3.2, -2), Color("#3dff8a"), 1.3, 8.0)
	# saracinesca col glifo (Nox)
	_box(o + Vector3(8, 1.4, -15.95), Vector3(3.2, 2.8, 0.1), Color("#3c4252"))
	_box(o + Vector3(8, 1.5, -15.88), Vector3(0.7, 0.7, 0.02), Color("#2ef2ff"), 0.6)
	# grata (Rio) con filamenti viola
	_box(o + Vector3(2, 0.02, 8), Vector3(1.2, 0.04, 0.8), Color("#05060a"))
	for k in 4:
		_box(o + Vector3(1.6 + k * 0.25, 0.05, 8), Vector3(0.05, 0.03, 0.7), Color("#8a3aa0"), 0.5)
	# transenna e scudo (Lance)
	_box(o + Vector3(12, 0.55, 4), Vector3(2.4, 0.15, 0.1), Color("#e8e8e8"))
	_box(o + Vector3(12, 0.85, 4), Vector3(2.4, 0.15, 0.1), Color("#d22b2b"))
	_box(o + Vector3(12.4, 0.6, 3.2), Vector3(0.7, 1.1, 0.06), Color("#5a6a7a"))
	# manifesto (tutti)
	_box(o + Vector3(-4, 1.5, 11.05), Vector3(2.0, 3.0, 0.2), Color("#262b38"))         # bacheca
	_box(o + Vector3(-4, 1.7, 10.92), Vector3(0.8, 1.0, 0.03), Color("#e9e2cf"), 0.25)
	# palazzo alterato dai Kairos: la città resta riconoscibile, con escrescenze viola sopra
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var base := o + Vector3(5, 0, -16.2)
	for k in 26:
		var p := base + Vector3(rng.randf_range(-6, 6), rng.randf_range(0.5, 9.0), rng.randf_range(0, 0.6))
		_sfera(p, rng.randf_range(0.35, 1.1), Color("#5b1f78").lerp(Color("#b2367a"), rng.randf()), 0.35 if rng.randf() < 0.3 else 0.0)
	var ponte := _box(o + Vector3(12, 10.5, -12), Vector3(1.4, 0.9, 12), Color("#6b2a7a"))
	ponte.rotation_degrees = Vector3(0, 35, 8)
	_luce(o + Vector3(5, 3.5, -13), Color("#c04aff"), 1.5, 10.0)

## Corpo segnaposto: due toni, proporzioni anime. Le parti hanno nomi fissi
## così la regia può animarle.
func _persona(chi: String) -> Node3D:
	var a: Dictionary = ASPETTO[chi]
	var root := Node3D.new()
	root.name = chi
	var corpo := Node3D.new()
	corpo.name = "corpo"
	root.add_child(corpo)
	var bassa := chi == "rio"
	var h := 0.85 if bassa else 1.0
	for lato in [-1, 1]:
		_box(Vector3(0.13 * lato, 0.42 * h, 0), Vector3(0.18, 0.84 * h, 0.2), a["gambe"], 0.0, corpo)
		_box(Vector3(0.13 * lato, 0.04, 0.05), Vector3(0.2, 0.1, 0.32), Color("#e8e8ee") if chi == "rio" else Color("#0c0c10"), 0.0, corpo)
	var busto := _box(Vector3(0, 1.12 * h, 0), Vector3(0.52, 0.62 * h, 0.3), a["corpo"], 0.0, corpo)
	busto.name = "busto"
	for lato in [-1, 1]:
		_box(Vector3(0.33 * lato, 1.1 * h, 0), Vector3(0.14, 0.58 * h, 0.16), a["corpo"], 0.0, corpo)
	var testa := _sfera(Vector3(0, 1.62 * h, 0), 0.2, a["pelle"], 0.0, corpo)
	testa.name = "testa"
	match chi:
		"lance":
			_box(Vector3(0, 1.8, 0.02), Vector3(0.44, 0.12, 0.44), Color("#141a2c"), 0.0, corpo)
			_box(Vector3(0, 1.75, 0.02), Vector3(0.45, 0.04, 0.45), a["accento"], 0.0, corpo)
			_box(Vector3(0, 1.75, 0.24), Vector3(0.36, 0.03, 0.18), Color("#141a2c"), 0.0, corpo)
			_box(Vector3(-0.33, 1.2, 0), Vector3(0.15, 0.08, 0.17), a["accento"], 0.0, corpo)
		"nox":
			_box(Vector3(0, 0.75, 0), Vector3(0.56, 0.7, 0.32), a["corpo"], 0.0, corpo)     # cappotto lungo
			_box(Vector3(0, 1.38, 0), Vector3(0.42, 0.1, 0.34), a["accento"], 0.0, corpo)   # sciarpa
			_sfera(Vector3(0, 1.72, -0.06), 0.21, a["capelli"], 0.0, corpo)
		"saul":
			_box(Vector3(0, 1.82, 0.02), Vector3(0.4, 0.14, 0.4), Color("#2a2a2a"), 0.0, corpo)  # berretto di lana
			_box(Vector3(0.1, 1.1, 0), Vector3(0.06, 0.66, 0.34), Color("#5a4630"), 0.0, corpo)  # tracolla
		"rio":
			# capelli bianchi dritti a punte
			for k in 7:
				var c := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.0
				cm.bottom_radius = 0.07
				cm.height = 0.34
				cm.radial_segments = 5
				c.mesh = cm
				c.material_override = _mat(a["capelli"])
				var ang := -1.2 + k * 0.4
				c.position = Vector3(sin(ang) * 0.12, 1.62 * h + 0.2, -0.04 - cos(ang) * 0.05)
				c.rotation = Vector3(-0.3, 0, -ang * 0.6)
				corpo.add_child(c)
			for lato in [-1, 1]:
				var occhio := _sfera(Vector3(0.07 * lato, 1.62 * h + 0.02, 0.18), 0.03, Color("#c78bff"), 3.0, corpo)
				occhio.name = "occhio_%d" % lato
	return root

func _sagoma(n: Node3D, on: bool) -> void:
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if on:
			if not mi.has_meta("mat"):
				mi.set_meta("mat", mi.material_override)
			if not String(mi.name).begins_with("occhio"):
				mi.material_override = _mat(Color("#030305"))
		elif mi.has_meta("mat"):
			mi.material_override = mi.get_meta("mat")
