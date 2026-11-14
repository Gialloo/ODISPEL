extends Node3D
## La città: costruisce le zone, muove chi guida il gruppo con una camera
## dietro le spalle (alla Persona), fa seguire gli altri, gestisce le collisioni,
## le percezioni passive, le persone con cui parlare e gli inneschi della regia.
## Forme semplici: segnaposto da sostituire con i modelli veri.

signal avviso(chi: String, punto: Dictionary)      # chi guida nota qualcosa (balloon)
signal esamina_cambiato(punto)                     # punto vicino (o null)
signal innesco(id: String)                         # il giocatore è arrivato in un punto di regia

const VEL_PASSO := 2.8
const VEL_CORSA := 6.2
const ACCEL := 26.0
const FRENO := 34.0
const RAGGIO_CORPO := 0.36
const RAGGIO_AVVISO := 6.0
const RAGGIO_ESAMINA := 1.7
const PASSO_SCIA := 0.1
const DISTANZA_SEGUACI := 12

## Colori segnaposto dei quattro (streetwear e divise, guida di stile del 18/10).
const ASPETTO := {
	"lance": {"corpo": Color("#1b2238"), "gambe": Color("#11141f"), "accento": Color("#ff2340"), "pelle": Color("#e7b48f"), "capelli": Color("#15151c")},
	"nox": {"corpo": Color("#24365c"), "gambe": Color("#161a28"), "accento": Color("#2ef2ff"), "pelle": Color("#f1c9a5"), "capelli": Color("#3a2550")},
	"saul": {"corpo": Color("#45603a"), "gambe": Color("#4a4a4a"), "accento": Color("#d8ff3a"), "pelle": Color("#c98e66"), "capelli": Color("#3a2a1e")},
	"rio": {"corpo": Color("#7b3cff"), "gambe": Color("#2b2140"), "accento": Color("#ffd23a"), "pelle": Color("#d9a079"), "capelli": Color("#efeaff")},
}

var camera: Camera3D
var zona := ""
var gruppo: Array[String] = []          # chi segue il giocatore; gruppo[0] guida
var corpi := {}                         # tutti i personaggi presenti nella zona
var punti: Array = []
var fatti := {}                         # id -> true
var avvisati := {}
var inneschi: Array = []
var controllo := false
var input_stick := Vector2.ZERO
var input_camera := 0.0                 # rotazione della camera dal touch
var limiti := Rect2()
var regia_camera := false
var yaw := 0.0

var _solidi: Array[Rect2] = []
var _vel := Vector3.ZERO
var _scia: Array[Vector3] = []
var _punto_vicino = null
var _zona_root: Node3D
var _neon: Array[Node3D] = []
var _mat_vc: StandardMaterial3D
var _luccichii := {}   # 0.6: id traccia -> segno luminoso
var _tremolanti: Array = []
var _pose := {}                         # chi -> "rovista", "annusa", "accucciato", "seduto", ""
var _t := 0.0
var _mat_cache := {}
var _scossa := 0.0
var _trascina := false
var _pioggia_p: CPUParticles3D

const INQUADRATURE := {
	"alto": [Vector3(0.0, 7.0, 10.0), Vector3(0.0, 1.0, -8.0)],
	"rio_lontano": [Vector3(0.6, 2.0, -30.5), Vector3(0.9, 0.9, -45.0)],
	"rio_vicino": [Vector3(2.6, 1.25, -42.4), Vector3(0.9, 0.75, -45.2)],
	"lance_volto": [Vector3(-1.1, 1.7, -40.7), Vector3(0.0, 1.6, -38.3)],
	"due": [Vector3(3.2, 2.4, -39.0), Vector3(0.3, 0.9, -43.4)],
	"strada": [Vector3(-2.0, 2.2, -33.0), Vector3(0.5, 1.6, -22.0)],
	"rifugio_largo": [Vector3(-95.2, 4.2, 3.6), Vector3(-101.0, 0.6, -3.5)],
	"rifugio_porta": [Vector3(-97.4, 1.9, 0.6), Vector3(-100.0, 1.2, 4.0)],
	"panorama": [Vector3(110.0, 10.0, 21.0), Vector3(110.0, 4.0, -22.0)],
	"muro": [Vector3(112.5, 2.4, -22.0), Vector3(110.0, 3.0, -35.0)],
	"varco": [Vector3(113.0, 1.9, -28.0), Vector3(110.0, 2.2, -35.0)],
	"nido_ingresso": [Vector3(203.0, 3.2, 12.0), Vector3(200.0, 1.5, -6.0)],
	"cuore": [Vector3(204.5, 2.0, -36.0), Vector3(200.0, 3.0, -49.0)],
	"cuore_alto": [Vector3(200.0, 9.0, -32.0), Vector3(200.0, 2.0, -48.0)],
	"reperto": [Vector3(191.4, 1.0, -21.6), Vector3(189.6, 0.6, -24.0)],
	"dispensa": [Vector3(183.0, 3.0, -26.0), Vector3(174.0, 1.0, -34.0)],
	"culle": [Vector3(217.0, 3.2, -19.0), Vector3(226.0, 0.8, -22.0)],
}

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 60.0
	camera.far = 170.0
	add_child(camera)
	_ambiente()
	_pioggia()

# ================================================================ zone

func carica_zona(nome: String, membri: Array, comparse: Dictionary, dati_punti: Array) -> void:
	if _zona_root:
		_zona_root.queue_free()
	corpi.clear()
	_neon.clear()
	_tremolanti.clear()
	_solidi.clear()
	_pose.clear()
	_zona_root = Node3D.new()
	add_child(_zona_root)
	zona = nome
	gruppo.assign(membri)
	punti = dati_punti
	inneschi.clear()
	avvisati.clear()
	var partenza := Vector3.ZERO
	match nome:
		"vicolo":
			_costruisci_vicolo()
			partenza = Vector3(0, 0, 2.5)
			limiti = Rect2(-3.2, -47.0, 19.5, 53.0)
			inneschi = [{"id": "sagoma", "z_max": -24.0, "fatto": false}, {"id": "rio", "z_max": -36.0, "fatto": false}]
			_pioggia_p.emitting = true
		"rifugio":
			_costruisci_rifugio()
			partenza = Vector3(-100, 0, 2.6)
			limiti = Rect2(-106.0, -8.0, 12.0, 12.0)
			_pioggia_p.emitting = false
		"quartiere":
			_costruisci_quartiere()
			partenza = Vector3(110, 0, 17)
			limiti = Rect2(82.5, -36.0, 55.0, 57.5)
			_pioggia_p.emitting = true
		"nido":
			# PROPOSTA (0.5, approvato dall'autore il 14/11/2026): il luogo anomalo dietro il varco, dove sta il cuore del nido
			_costruisci_nido()
			partenza = Vector3(200, 0, 8)
			limiti = Rect2(167.5, -54.0, 65.0, 64.5)
			inneschi = [{"id": "sciame", "z_max": -37.0, "x_min": 188.0, "x_max": 212.0, "fatto": false},
				{"id": "ingordo", "z_max": 99.0, "x_max": 183.0, "fatto": false},   # 0.7: entrando nella dispensa
				{"id": "covata", "z_max": 99.0, "x_min": 217.0, "fatto": false}]   # 0.7: entrando nelle culle (sciame: 0.6, le guardie del cuore)
			_pioggia_p.emitting = false
	_unisci_statici()
	_luccichii.clear()
	for pt in dati_punti:
		if pt.get("tipo", "") == "traccia" and not fatti.has(pt["id"]):
			var l := _box(Vector3(pt["pos"][0], 0.5, pt["pos"][1]), Vector3(0.16, 0.16, 0.16), Color("#fff4c2"), 4.0)
			l.name = "luccichio_" + pt["id"]
			l.rotation = Vector3(PI / 4, 0, PI / 4)
			_luccichii[pt["id"]] = l
	for i in gruppo.size():
		var chi: String = gruppo[i]
		var p := _persona(chi)
		p.position = partenza + Vector3(0, 0, i * 1.2)
		p.rotation.y = PI
		_zona_root.add_child(p)
		corpi[chi] = p
	# comparse: personaggi presenti ma non nel gruppo {chi: {pos, rot, posa}}
	for chi in comparse:
		var c: Dictionary = comparse[chi]
		var p := _persona(chi)
		p.position = Vector3(c["pos"][0], c.get("y", 0.0), c["pos"][1])
		p.rotation.y = deg_to_rad(c.get("rot", 0.0))
		_zona_root.add_child(p)
		corpi[chi] = p
		_pose[chi] = c.get("posa", "")
		if c.get("sagoma", false):
			_sagoma(p, true)
	_scia.clear()
	for i in DISTANZA_SEGUACI * 5:
		_scia.append(partenza + Vector3(0, 0, i * PASSO_SCIA))
	_vel = Vector3.ZERO
	yaw = 0.0
	_punto_vicino = null
	_metti_camera(true)

func guida() -> Node3D:
	return corpi.get(gruppo[0]) if not gruppo.is_empty() else null

func testa(chi: String) -> Vector3:
	var c: Node3D = corpi.get(chi)
	if c == null:
		return Vector3.ZERO
	var alt := 1.95
	var posa: String = _pose.get(chi, "")
	if posa in ["rovista", "annusa", "accucciato"]:
		alt = 1.35
	elif chi == "rio":
		alt = 1.8
	return c.global_position + Vector3(0, alt, 0)

func cambia_guida() -> String:
	if gruppo.size() < 2:
		return gruppo[0]
	var vecchia := guida()
	gruppo.push_back(gruppo.pop_front())
	var nuova := guida()
	var tmp := nuova.position
	nuova.position = vecchia.position
	vecchia.position = tmp
	nuova.rotation.y = vecchia.rotation.y
	_punto_vicino = null
	esamina_cambiato.emit(null)
	return gruppo[0]

func segna_fatto(id: String) -> void:
	fatti[id] = true
	if _luccichii.has(id):
		if is_instance_valid(_luccichii[id]):
			_luccichii[id].queue_free()
		_luccichii.erase(id)
	_punto_vicino = null
	esamina_cambiato.emit(null)

# ================================================================ ciclo

func _unhandled_input(e: InputEvent) -> void:
	if not controllo:
		return
	if e is InputEventMouseButton and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_trascina = e.pressed
	elif e is InputEventMouseMotion and _trascina and not DisplayServer.is_touchscreen_available():
		yaw -= e.relative.x * 0.006

func _process(delta: float) -> void:
	var cuore: Node3D = _zona_root.get_node_or_null("cuore") if _zona_root else null
	if cuore:
		var b := 1.0 + 0.06 * pow(maxf(0.0, sin(_t * 3.4)), 8.0)
		cuore.scale = Vector3.ONE * b
	_t += delta
	for id in _luccichii:
		var l: Node3D = _luccichii[id]
		l.rotation.y = _t * 2.0
		l.position.y = 0.5 + sin(_t * 3.0) * 0.08
		l.scale = Vector3.ONE * (1.0 + 0.35 * maxf(0.0, sin(_t * 5.0 + l.position.x)))
	for n in _tremolanti:
		if is_instance_valid(n) and n.get_meta("acceso", true):
			n.visible = fmod(_t * 7.3 + n.get_meta("fase"), 9.0) > 0.6
	_anima_pose()
	if controllo:
		_muovi(delta)
		_percezioni()
		_controlla_inneschi()
	else:
		_ferma_passi(delta)
	if not regia_camera:
		_metti_camera(false, delta)
	if _scossa > 0.0:
		_scossa = maxf(0.0, _scossa - delta)
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _scossa * 0.25

func _muovi(delta: float) -> void:
	var g := guida()
	if g == null:
		return
	var dir := input_stick
	var cammina_piano := false
	if dir == Vector2.ZERO:
		dir = Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		cammina_piano = Input.is_physical_key_pressed(KEY_SHIFT)
		yaw += (float(Input.is_physical_key_pressed(KEY_Z)) - float(Input.is_physical_key_pressed(KEY_C))) * delta * 2.2
	yaw -= input_camera * delta * 2.6
	var forza := minf(1.0, dir.length())
	if forza > 0.0:
		dir = dir.normalized()
	# velocità: piano se lo stick è poco inclinato o si tiene Shift, corsa altrimenti
	var vmax := VEL_PASSO if (forza < 0.6 or cammina_piano) else VEL_CORSA
	var mondo_dir := Basis(Vector3.UP, yaw) * Vector3(dir.x, 0, dir.y)
	var voluta := mondo_dir * vmax * (1.0 if forza > 0.0 else 0.0)
	_vel = _vel.move_toward(voluta, (ACCEL if forza > 0.0 else FRENO) * delta)
	var p := _scivola(g.position, _vel * delta)
	g.position = p
	g.visible = true
	var vel_piana := Vector2(_vel.x, _vel.z).length()
	if vel_piana > 0.2:
		g.rotation.y = lerp_angle(g.rotation.y, atan2(_vel.x, _vel.z), minf(1.0, delta * 15.0))
	_passi(g, vel_piana, delta)
	if g.position.distance_to(_scia[0]) >= PASSO_SCIA:
		_scia.push_front(g.position)
		if _scia.size() > DISTANZA_SEGUACI * 6:
			_scia.pop_back()
	for i in range(1, gruppo.size()):
		var f: Node3D = corpi[gruppo[i]]
		var idx := mini(i * DISTANZA_SEGUACI, _scia.size() - 1)
		var meta: Vector3 = _scia[idx]
		var d := meta - f.position
		var v := 0.0
		if d.length() > 0.05:
			var prima := f.position
			f.position = f.position.lerp(meta, minf(1.0, delta * 7.0))
			v = prima.distance_to(f.position) / maxf(delta, 0.001)
			f.rotation.y = lerp_angle(f.rotation.y, atan2(d.x, d.z), minf(1.0, delta * 10.0))
		_passi(f, v, delta)
		f.visible = not _copre_guida(f.position, g.position)

## Un compagno che sta tra la camera e la guida la coprirebbe: come in esplorazione
## nei JRPG, in quel caso si nasconde e ricompare appena esce dall'inquadratura.
func _copre_guida(pos: Vector3, guida_pos: Vector3) -> bool:
	if camera == null or regia_camera:
		return false
	var c := Vector2(camera.position.x, camera.position.z)
	var gp := Vector2(guida_pos.x, guida_pos.z)
	var fp := Vector2(pos.x, pos.z)
	var linea := gp - c
	var lun := linea.length()
	if lun < 0.01:
		return false
	var t := (fp - c).dot(linea) / (lun * lun)
	if t <= 0.0 or t >= 1.05:
		return false
	return (c + linea * t).distance_to(fp) < 1.1

## Movimento con scivolamento sui muri: prova il passo intero, poi solo x, poi solo z.
func _scivola(da: Vector3, passo: Vector3) -> Vector3:
	var p := da + passo
	p.x = clampf(p.x, limiti.position.x, limiti.end.x)
	p.z = clampf(p.z, limiti.position.y, limiti.end.y)
	if not _urta(p):
		return p
	var px := Vector3(p.x, 0, da.z)
	if not _urta(px):
		_vel.z = 0.0
		return px
	var pz := Vector3(da.x, 0, p.z)
	if not _urta(pz):
		_vel.x = 0.0
		return pz
	_vel = Vector3.ZERO
	return da

func _urta(p: Vector3) -> bool:
	for r in _solidi:
		if r.grow(RAGGIO_CORPO).has_point(Vector2(p.x, p.z)):
			return true
	return false

func _passi(n: Node3D, v: float, delta: float) -> void:
	var c: Node3D = n.get_node_or_null("corpo")
	if c == null:
		return
	var k := clampf(v / VEL_CORSA, 0.0, 1.0)
	var fase: float = n.get_meta("fase_passo", 0.0) + delta * (6.0 + 8.0 * k) * (1.0 if v > 0.15 else 0.0)
	n.set_meta("fase_passo", fase)
	var amp := 0.95 * k + (0.3 if v > 0.15 else 0.0) * (1.0 - k)
	for nome in ["gamba_s", "gamba_d", "braccio_s", "braccio_d"]:
		var arto: Node3D = c.get_node_or_null(nome)
		if arto == null:
			continue
		var segno := 1.0 if nome.ends_with("_s") else -1.0
		if nome.begins_with("braccio"):
			segno = -segno
		var voluto := sin(fase) * amp * segno if v > 0.15 else 0.0
		arto.rotation.x = lerpf(arto.rotation.x, voluto, minf(1.0, delta * 14.0))
	if _pose.get(n.name, "") == "":
		c.position.y = absf(sin(fase)) * 0.07 * k
		c.rotation.x = lerpf(c.rotation.x, 0.12 * k + (0.18 if n.name == "rio" else 0.0), minf(1.0, delta * 8.0))

func _ferma_passi(delta: float) -> void:
	for chi in corpi:
		if _pose.get(chi, "") == "":
			_passi(corpi[chi], 0.0, delta)

func _percezioni() -> void:
	var g := guida()
	var chi := gruppo[0]
	var vicino = null
	var miglior := RAGGIO_ESAMINA
	for p in punti:
		var id: String = p["id"]
		if fatti.has(id):
			continue
		var per: String = p.get("chi", "tutti")
		if per != "tutti" and per != chi:
			continue
		var ok := true
		for r in p.get("richiede", []):
			if not fatti.has(r):
				ok = false
		if not ok:
			continue
		var pos := Vector3(p["pos"][0], 0, p["pos"][1])
		var d := Vector2(g.position.x - pos.x, g.position.z - pos.z).length()
		var chiave := id + "|" + chi
		if d < RAGGIO_AVVISO and not avvisati.has(chiave) and p.has("avviso"):
			avvisati[chiave] = true
			avviso.emit(chi, p)
		if d < miglior:
			miglior = d
			vicino = p
	if vicino != _punto_vicino:
		_punto_vicino = vicino
		esamina_cambiato.emit(vicino)

func _controlla_inneschi() -> void:
	var g := guida()
	for i in inneschi:
		if not i["fatto"] and g.position.z < i["z_max"] and g.position.x >= i.get("x_min", -INF) and g.position.x <= i.get("x_max", INF):
			i["fatto"] = true
			innesco.emit(i["id"])

## Camera dietro le spalle: si gira col dito (metà destra), col mouse o con Z/C.
## Se un muro sta tra la camera e il personaggio, la camera si avvicina.
func _metti_camera(subito: bool, delta := 0.0) -> void:
	var g := guida()
	if g == null:
		return
	var dist := 5.0 if zona != "quartiere" else 6.0
	var alt := 2.3 if zona != "quartiere" else 2.8
	var perno := g.position + Vector3(0, 1.35, 0)
	var dietro := Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
	var voluto := perno + dietro * dist + Vector3(0, alt - 1.35 + 0.6, 0)
	# se un muro sta tra il personaggio e la camera: la camera si avvicina e sale,
	# e guarda dall'alto (come negli interni dei JRPG) invece di finire nel muro
	var k := 1.0
	var t := 0.08
	while t <= 1.0:
		var prova := perno.lerp(voluto, t)
		var dentro := false
		for r in _solidi:
			if r.grow(0.3).has_point(Vector2(prova.x, prova.z)) and maxf(r.size.x, r.size.y) >= 1.8:
				dentro = true
				break
		if dentro:
			k = maxf(0.45, t - 0.08)
			break
		t += 0.04
	voluto = perno.lerp(voluto, k) + Vector3(0, (1.0 - k) * 3.2, 0)
	if subito:
		camera.position = voluto
	else:
		camera.position = camera.position.lerp(voluto, minf(1.0, delta * 9.0))
	camera.look_at(perno + Vector3(0, 0.15, 0) - dietro * 1.4, Vector3.UP)

# ================================================================ regia

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
	var g := guida()
	if g:
		yaw = g.rotation.y + PI

func muovi(chi: String, x: float, z: float, durata: float) -> void:
	var c: Node3D = corpi.get(chi)
	if c == null:
		return
	var d := Vector3(x, c.position.y, z) - c.position
	if d.length() > 0.05:
		c.rotation.y = atan2(d.x, d.z)
	var tw := create_tween()
	tw.tween_property(c, "position", Vector3(x, c.position.y, z), durata)
	var passi := create_tween().set_loops(int(maxf(1.0, durata * 6.0)))
	passi.tween_callback(func(): _passi(c, VEL_PASSO, 1.0 / 6.0)).set_delay(1.0 / 6.0)
	await tw.finished
	passi.kill()

func gira(chi: String, gradi: float) -> void:
	var c: Node3D = corpi.get(chi)
	if c:
		var tw := create_tween()
		tw.tween_property(c, "rotation:y", deg_to_rad(gradi), 0.3)
		await tw.finished

func posa(chi: String, p: String) -> void:
	_pose[chi] = p

func salta(chi: String, x: float, y: float, z: float) -> void:
	var c: Node3D = corpi.get(chi)
	if c == null:
		return
	_pose[chi] = ""
	var tw := create_tween()
	tw.tween_property(c, "position", Vector3(x, y, z), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished

func luce_rio() -> void:
	var r: Node3D = corpi.get("rio")
	if r:
		_sagoma(r, false)
	var l: OmniLight3D = _zona_root.get_node_or_null("luce_rio")
	if l:
		l.light_color = Color("#bfe8ff")
		l.light_energy = 2.2

func boato() -> void:
	_scossa = 1.6
	var tw := create_tween()
	for n in _neon:
		if is_instance_valid(n):
			tw.tween_callback(func():
				n.set_meta("acceso", false)
				n.visible = false).set_delay(0.12)
	for l in _zona_root.find_children("*", "OmniLight3D", true, false):
		tw.parallel().tween_property(l, "light_energy", 0.05, 0.8)

func _anima_pose() -> void:
	for chi in _pose:
		var c: Node3D = corpi.get(chi)
		if c == null:
			continue
		var b: Node3D = c.get_node_or_null("corpo")
		if b == null:
			continue
		var gs: Node3D = b.get_node_or_null("gamba_s")
		var gd: Node3D = b.get_node_or_null("gamba_d")
		match _pose[chi]:
			"rovista":
				b.rotation.x = 0.6 + sin(_t * 5.0) * 0.18
				b.position.y = -0.42
				_gambe(gs, gd, -1.2)
			"annusa":
				b.rotation.x = 0.4 + sin(_t * 14.0) * 0.05
				b.position.y = -0.4
				_gambe(gs, gd, -1.2)
			"accucciato":
				b.rotation.x = 0.35
				b.position.y = -0.42
				_gambe(gs, gd, -1.3)
			"seduto":
				b.rotation.x = 0.0
				b.position.y = -0.38
				_gambe(gs, gd, -1.5)
			"":
				pass

func _gambe(gs: Node3D, gd: Node3D, a: float) -> void:
	if gs:
		gs.rotation.x = a
	if gd:
		gd.rotation.x = a

# ================================================================ costruzione

## 0.6: unisce i pezzi fermi della zona in una mesh per materiale. Sul telefono ogni mesh
## è una draw call: così le zone passano da 200+ a qualche decina (misura: tools/misura.gd).
## Restano separati i pezzi con un nome, quelli che tremolano e quelli con figli.
func _unisci_statici() -> void:
	var gruppi := {}
	for n in _zona_root.get_children():
		if not _fondibile(n):
			continue
		var mi := n as MeshInstance3D
		if mi in _tremolanti:
			continue
		var neon := mi in _neon
		var k := "vc" if _semplice(mi) and not neon and mi.transparency == 0.0 else "%d|%s|%s" % [mi.material_override.get_instance_id(), mi.transparency, neon]
		if not gruppi.has(k):
			gruppi[k] = []
		gruppi[k].append(mi)
	for k in gruppi:
		var lista: Array = gruppi[k]
		if lista.size() < 2:
			continue
		var primo: MeshInstance3D = lista[0]
		var neon := primo in _neon
		var trasp := primo.transparency
		if neon:
			for mi in lista:
				_neon.erase(mi)
		var u := _fondi(_zona_root, lista, _mat_vertici() if k == "vc" else primo.material_override)
		u.transparency = trasp
		if neon:
			_neon.append(u)

## Pezzo senza nome, senza figli, visibile: si può fondere con gli altri.
func _fondibile(n: Node) -> bool:
	if not (n is MeshInstance3D) or n.get_child_count() > 0 or not n.visible:
		return false
	var nome := String(n.name)
	return (nome.begins_with("@") or nome.begins_with("MeshInstance3D")) and n.mesh != null

## Materiale opaco normale (né luminoso né lucido): basta il colore per vertice.
func _semplice(mi: MeshInstance3D) -> bool:
	var m := mi.material_override as StandardMaterial3D
	return m != null and not m.emission_enabled and m.metallic == 0.0

func _mat_vertici() -> StandardMaterial3D:
	if _mat_vc == null:
		_mat_vc = StandardMaterial3D.new()
		_mat_vc.vertex_color_use_as_albedo = true
		_mat_vc.vertex_color_is_srgb = true
		_mat_vc.roughness = 0.85
	return _mat_vc

## Fonde i pezzi in una sola mesh (posizione e colore di ciascuno nei vertici) e li toglie.
func _fondi(parent: Node3D, lista: Array, mat: Material) -> MeshInstance3D:
	var v := PackedVector3Array()
	var nn := PackedVector3Array()
	var cc := PackedColorArray()
	var ii := PackedInt32Array()
	for mi: MeshInstance3D in lista:
		var arr := mi.mesh.surface_get_arrays(0)
		var pv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var pn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx = arr[Mesh.ARRAY_INDEX]
		var base := v.size()
		var t: Transform3D = mi.transform
		var col: Color = (mi.material_override as StandardMaterial3D).albedo_color
		for q in pv:
			v.append(t * q)
			cc.append(col)
		for q in pn:
			nn.append((t.basis * q).normalized())
		if idx == null or idx.is_empty():
			for q in pv.size():
				ii.append(base + q)
		else:
			for q in idx:
				ii.append(base + q)
		parent.remove_child(mi)
		mi.free()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = nn
	arrays[Mesh.ARRAY_COLOR] = cc
	arrays[Mesh.ARRAY_INDEX] = ii
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var u := MeshInstance3D.new()
	u.mesh = am
	u.material_override = mat
	parent.add_child(u)
	return u

## Fonde i pezzi semplici di un nodo del personaggio (busto, un braccio, una gamba).
func _fondi_parte(n: Node3D) -> void:
	var lista := []
	for c in n.get_children():
		if _fondibile(c) and _semplice(c):
			lista.append(c)
	if lista.size() > 1:
		_fondi(n, lista, _mat_vertici())

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

func _box(pos: Vector3, size: Vector3, col: Color, emiss := 0.0, parent: Node3D = null, solido := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, emiss)
	mi.position = pos
	(parent if parent else _zona_root).add_child(mi)
	if solido:
		_solidi.append(Rect2(pos.x - size.x * 0.5, pos.z - size.z * 0.5, size.x, size.z))
	return mi

## Blocco solido da coordinate di pianta: x0..x1, z0..z1, altezza h.
func _blocco(x0: float, x1: float, z0: float, z1: float, h: float, col: Color) -> MeshInstance3D:
	return _box(Vector3((x0 + x1) * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h, z1 - z0), col, 0.0, null, true)

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

func _insegna(pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	var n := _box(pos, size, col, 3.0)
	_neon.append(n)
	# riflesso finto sul pavimento bagnato (trucco economico della guida di stile)
	var r := _box(Vector3(pos.x, 0.012, pos.z), Vector3(maxf(size.x, 0.6) * 1.2, 0.01, maxf(size.z, 0.6) * 1.3), col.darkened(0.6), 1.0)
	r.transparency = 0.5
	_neon.append(r)
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
	env.fog_density = 0.014
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
	p.amount = 240
	p.lifetime = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(8, 0.5, 8)
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
	_pioggia_p = p

func _finestre(x: float, z0: float, z1: float, faccia: float, seme: int, piani := 4) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var z := z0
	while z > z1:
		for piano in piani:
			var acc := rng.randf() < 0.18
			var col: Color = [Color("#ffcf7a"), Color("#7ad7ff"), Color("#c7ffb0")][rng.randi() % 3] if acc else Color("#141824")
			_box(Vector3(x + faccia * 0.02, 3.2 + piano * 2.4, z), Vector3(0.05, 1.0, 0.8), col, 1.4 if acc else 0.0)
		z -= rng.randf_range(2.2, 3.4)

func _finestre_z(z: float, x0: float, x1: float, faccia: float, seme: int, piani := 4) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var x := x0
	while x < x1:
		for piano in piani:
			var acc := rng.randf() < 0.18
			var col: Color = [Color("#ffcf7a"), Color("#7ad7ff"), Color("#c7ffb0")][rng.randi() % 3] if acc else Color("#141824")
			_box(Vector3(x, 3.2 + piano * 2.4, z + faccia * 0.02), Vector3(0.8, 1.0, 0.05), col, 1.4 if acc else 0.0)
		x += rng.randf_range(2.2, 3.4)

func _pavimento(centro: Vector3, size: Vector2) -> void:
	_box(centro + Vector3(0, -0.05, 0), Vector3(size.x, 0.1, size.y), Color("#0b0e14")).material_override = _mat(Color("#0b0e14"), 0.0, true)

# ---------------------------------------------------------------- vicolo

func _costruisci_vicolo() -> void:
	var muro := Color("#121621")
	_pavimento(Vector3(5, 0, -20), Vector2(30, 64))
	# strada principale x -3.2..3.2; cortile a destra (x 4..16, z -9..-23)
	_blocco(-8, -4, -52, 9, 12, muro)                    # palazzi a sinistra
	_blocco(4, 17, -9, 9, 12, muro)                      # palazzo a destra, prima del cortile
	_blocco(4, 17, -52, -23, 12, muro)                   # palazzo a destra, dopo il cortile
	_blocco(17, 20, -23, -9, 12, Color("#161a26"))       # fondo del cortile
	_blocco(-6, 6, 7, 9, 3, Color("#0d1018"))            # muretto alle spalle
	_finestre(-4.0, 6, -38, 1, 3)
	_finestre(4.0, 6, -8.5, -1, 7)
	_finestre(4.0, -24, -38, -1, 8)
	_finestre_z(-9.0, 5.0, 16.0, -1, 9, 3)
	_finestre_z(-23.0, 5.0, 16.0, 1, 10, 3)
	_box(Vector3(-3.4, 0.08, -20), Vector3(0.3, 0.16, 54), Color("#1b2030"))
	_box(Vector3(3.6, 0.08, -2), Vector3(0.3, 0.16, 14), Color("#1b2030"))
	_box(Vector3(3.6, 0.08, -33), Vector3(0.3, 0.16, 20), Color("#1b2030"))
	# insegne: poche e fortissime
	_insegna(Vector3(-3.95, 3.4, -4), Vector3(0.08, 0.5, 2.4), Color("#3dff8a"))
	_insegna(Vector3(3.95, 4.2, -2), Vector3(0.08, 1.6, 0.4), Color("#2ef2ff"))
	_insegna(Vector3(-3.95, 2.9, -27), Vector3(0.08, 0.35, 1.8), Color("#ff2340"))
	_insegna(Vector3(-3.95, 3.0, -34.5), Vector3(0.08, 0.4, 2.6), Color("#d8ff3a"))   # lavanderia
	_insegna(Vector3(16.9, 3.0, -16), Vector3(0.08, 0.5, 1.6), Color("#2a5cff"))
	_luce(Vector3(-2.6, 3.3, -4), Color("#3dff8a"), 1.4, 8.0)
	_luce(Vector3(2.6, 4.0, -2), Color("#2ef2ff"), 1.3, 8.0)
	_luce(Vector3(-2.6, 2.8, -27), Color("#ff2340"), 1.2, 7.0)
	_luce(Vector3(-2.6, 2.8, -34.5), Color("#d8ff3a"), 1.1, 6.0)
	_luce(Vector3(15.5, 3.0, -16), Color("#2a5cff"), 1.4, 9.0)
	for z in [-3.0, -11.0, -19.5, -29.0, -37.0]:
		_box(Vector3(0, 7.5 + fmod(absf(z), 2.0), z), Vector3(8.2, 0.04, 0.04), Color("#05060a"))
	# scala della lavanderia (scende nel seminterrato)
	_box(Vector3(-3.6, 0.6, -34.5), Vector3(0.6, 1.2, 2.2), Color("#20242e"), 0.0, null, true)
	_box(Vector3(-3.95, 1.1, -34.5), Vector3(0.05, 2.2, 1.4), Color("#0a0c12"))
	# bossoli nel muro di sinistra
	for k in 3:
		_box(Vector3(-3.97, 1.2 + k * 0.12, -6.0 + k * 0.1), Vector3(0.02, 0.05, 0.03), Color("#c9a24a"), 0.4)
	# distributore (l'unica cosa accesa)
	_box(Vector3(-3.5, 1.0, -27.0 + 2.6), Vector3(0.9, 2.0, 0.9), Color("#1d2a3a"), 0.0, null, true)
	_box(Vector3(-3.03, 1.25, -24.4), Vector3(0.02, 1.2, 0.7), Color("#ffb04a"), 1.6)
	# cortile: panni stesi, scala, cassonetto, zaino, pozzanghera
	for z in [-11.5, -14.0, -16.5]:
		_box(Vector3(10.5, 3.6, z), Vector3(12.5, 0.02, 0.02), Color("#0a0a0a"))
		for k in 5:
			_box(Vector3(6.5 + k * 2.1, 3.25, z), Vector3(0.7, 0.7, 0.03), [Color("#c8c2b5"), Color("#7a2a3a"), Color("#3a4a7a")][k % 3])
	_box(Vector3(6.0, 1.0, -21.6), Vector3(3.0, 2.0, 1.6), Color("#20242e"), 0.0, null, true)
	_box(Vector3(15.6, 0.65, -12.2), Vector3(1.0, 1.3, 1.9), Color("#20402c"), 0.0, null, true)
	_box(Vector3(15.7, 0.2, -13.9), Vector3(0.5, 0.35, 0.7), Color("#3b4230"))
	var poz := _box(Vector3(10.5, 0.015, -19.4), Vector3(1.6, 0.01, 1.1), Color("#8fd0ff"), 1.3)
	poz.name = "pozzanghera"
	# fondo: piano terra aperto del palazzo, saracinesca mezza alzata
	_box(Vector3(0, 7.5, -40.0), Vector3(8.2, 9, 0.5), Color("#151a26"))
	_box(Vector3(0, 2.85, -40.05), Vector3(7.8, 0.5, 0.25), Color("#3c4252"))
	_blocco(-4, 4, -52, -50, 12, muro)
	_box(Vector3(0, 3.45, -45.0), Vector3(8.2, 0.1, 10.0), Color("#0d1018"))
	var tubo := _box(Vector3(-0.3, 3.3, -48.2), Vector3(2.4, 0.09, 0.13), Color("#d8f6ff"), 4.0)
	tubo.set_meta("fase", 1.7)
	_tremolanti.append(tubo)
	_neon.append(tubo)
	var lr := _luce(Vector3(-0.2, 2.9, -47.8), Color("#7ab8ff"), 1.4, 9.0)
	lr.name = "luce_rio"
	_box(Vector3(-1.7, 0.45, -46.3), Vector3(1.2, 0.9, 1.0), Color("#3a2e22"))
	_box(Vector3(2.4, 0.5, -47.5), Vector3(1.0, 1.0, 1.0), Color("#2e2a24"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 9:
		_sfera(Vector3(0.9 + rng.randf_range(-0.8, 0.8), 0.1, -46.2 + rng.randf_range(-0.5, 0.5)), rng.randf_range(0.12, 0.26), Color("#6a2a7a").lerp(Color("#a14a6a"), rng.randf()))

# ---------------------------------------------------------------- rifugio

func _costruisci_rifugio() -> void:
	var muro := Color("#1a1f2c")
	_box(Vector3(-100, -0.05, -2), Vector3(14, 0.1, 14), Color("#2a2e36"))
	_blocco(-108, -106, -10, 6, 4, muro)
	_blocco(-94, -92, -10, 6, 4, muro)
	_blocco(-106, -94, -10, -8, 4, muro)
	_blocco(-106, -101, 4, 6, 4, muro)
	_blocco(-99, -94, 4, 6, 4, muro)
	_box(Vector3(-100, 1.2, 4.95), Vector3(2.0, 2.4, 0.15), Color("#4a3a2a"), 0.0, null, true)   # porta
	# lavatrici e asciugatrici lungo il muro di fondo
	for k in 6:
		var x := -105.0 + k * 1.6
		_box(Vector3(x, 0.5, -7.3), Vector3(1.4, 1.0, 1.2), Color("#d9dde4"), 0.0, null, true)
		_box(Vector3(x, 0.55, -6.69), Vector3(0.7, 0.7, 0.02), Color("#3a4a5a"), 0.4)
	_box(Vector3(-100, 3.0, -8.0), Vector3(1.4, 0.5, 0.05), Color("#2a3550"), 0.6)   # finestrella in alto
	# bancone a sinistra
	_box(Vector3(-104.6, 0.5, -2.0), Vector3(1.2, 1.0, 6.0), Color("#3a2e22"), 0.0, null, true)
	_box(Vector3(-105.5, 0.25, -2.6), Vector3(0.8, 0.5, 0.9), Color("#5a6a8a"))   # ceste di panni
	_box(Vector3(-105.5, 0.25, -0.8), Vector3(0.8, 0.5, 0.9), Color("#8a5a6a"))
	# cerchio di gesso di Nox
	var anello := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.15
	tm.outer_radius = 1.22
	tm.rings = 32
	anello.mesh = tm
	anello.material_override = _mat(Color("#bff6ff"), 1.8)
	anello.position = Vector3(-99.6, 0.01, -2.2)
	anello.scale = Vector3(1, 0.05, 1)
	_zona_root.add_child(anello)
	# neon da lavanderia
	var t1 := _box(Vector3(-100, 3.4, -3), Vector3(3.0, 0.08, 0.14), Color("#e8fbff"), 3.0)
	t1.set_meta("fase", 0.3)
	_tremolanti.append(t1)
	_luce(Vector3(-100, 3.2, -3), Color("#cfeeff"), 1.6, 12.0)
	_luce(Vector3(-99.6, 0.4, -2.2), Color("#2ef2ff"), 0.9, 4.0)

# ---------------------------------------------------------------- quartiere

func _costruisci_quartiere() -> void:
	var m1 := Color("#131826")
	var m2 := Color("#171c2a")
	_pavimento(Vector3(110, 0, -8), Vector2(62, 64))
	# isolati intorno alla piazza (x 96..124, z -20..8) con quattro strade
	_blocco(80, 106, -42, -20, 14, m1)
	_blocco(114, 140, -42, -20, 12, m2)
	_blocco(80, 96, -20, -10, 10, m2)
	_blocco(80, 96, -2, 8, 11, m1)
	_blocco(124, 140, -20, -10, 13, m1)
	_blocco(124, 140, -2, 8, 10, m2)
	_blocco(80, 106, 8, 26, 12, m2)
	_blocco(114, 140, 8, 26, 12, m1)
	_finestre(96.0, -10.5, -19.5, 1, 31, 3)
	_finestre(96.0, 7.5, -1.5, 1, 32, 3)
	_finestre(124.0, -10.5, -19.5, -1, 33, 4)
	_finestre(124.0, 7.5, -1.5, -1, 34, 3)
	_finestre_z(-20.0, 97.0, 105.0, 1, 35)
	_finestre_z(-20.0, 115.0, 123.0, 1, 36)
	_finestre_z(8.0, 97.0, 105.0, -1, 37)
	_finestre_z(8.0, 115.0, 123.0, -1, 38)
	# muri di carne: ogni strada finisce chiusa
	_muro_carne(Vector3(110, 0, -35.5), true, 41)
	_muro_carne(Vector3(110, 0, 23.0), true, 42)
	_muro_carne(Vector3(137.0, 0, -6), false, 43)
	_muro_carne(Vector3(83.0, 0, -6), false, 44)
	# edicola, panchina, lampioni, bacheca
	_box(Vector3(100, 1.2, -14.5), Vector3(2.6, 2.4, 1.8), Color("#2b3d2e"), 0.0, null, true)
	_box(Vector3(100, 2.5, -14.5), Vector3(3.0, 0.15, 2.2), Color("#1e2a20"))
	_box(Vector3(118, 0.35, 5.5), Vector3(2.2, 0.15, 0.6), Color("#3a2e22"), 0.0, null, true)
	for lp in [Vector3(99, 0, 4), Vector3(121, 0, -16), Vector3(110, 0, -8)]:
		_box(lp + Vector3(0, 2.2, 0), Vector3(0.12, 4.4, 0.12), Color("#20242e"), 0.0, null, true)
		_box(lp + Vector3(0, 4.45, 0), Vector3(0.5, 0.12, 0.5), Color("#ffe3a3"), 2.4)
	_luce(Vector3(99, 4.0, 4), Color("#ffd89a"), 1.2, 9.0)
	_luce(Vector3(121, 4.0, -16), Color("#ffd89a"), 1.2, 9.0)
	_box(Vector3(102, 1.5, 7.9), Vector3(2.0, 3.0, 0.2), Color("#262b38"))
	_box(Vector3(102, 1.7, 7.78), Vector3(0.8, 1.0, 0.03), Color("#e9e2cf"), 0.25)
	_insegna(Vector3(96.05, 3.2, -5), Vector3(0.08, 0.5, 3.0), Color("#3dff8a"))
	_insegna(Vector3(123.95, 3.6, -6), Vector3(0.08, 1.8, 0.45), Color("#ff2340"))
	_luce(Vector3(97.2, 3.2, -5), Color("#3dff8a"), 1.3, 8.0)
	_luce(Vector3(122.8, 3.4, -6), Color("#ff2340"), 1.1, 7.0)
	# saracinesca col glifo (Nox)
	_box(Vector3(123.9, 1.4, -15), Vector3(0.1, 2.8, 3.2), Color("#3c4252"))
	_box(Vector3(123.83, 1.5, -15), Vector3(0.02, 0.7, 0.7), Color("#2ef2ff"), 0.6)
	# grata (Rio)
	_box(Vector3(113, 0.02, 4), Vector3(1.2, 0.04, 0.8), Color("#05060a"))
	for k in 4:
		_box(Vector3(112.6 + k * 0.25, 0.05, 4), Vector3(0.05, 0.03, 0.7), Color("#8a3aa0"), 0.5)
	# transenna e scudo (Lance)
	_box(Vector3(120, 0.55, -2), Vector3(2.4, 0.15, 0.1), Color("#e8e8e8"), 0.0, null, true)
	_box(Vector3(120, 0.85, -2), Vector3(2.4, 0.15, 0.1), Color("#d22b2b"))
	_box(Vector3(120.4, 0.6, -2.9), Vector3(0.7, 1.1, 0.06), Color("#5a6a7a"))
	# palazzi alterati: la città resta riconoscibile, con escrescenze viola sopra
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 34:
		var p := Vector3(rng.randf_range(84, 105), rng.randf_range(1.0, 12.0), -20.3 + rng.randf_range(0, 0.6))
		_sfera(p, rng.randf_range(0.35, 1.3), Color("#5b1f78").lerp(Color("#b2367a"), rng.randf()), 0.35 if rng.randf() < 0.3 else 0.0)
	var ponte := _box(Vector3(110, 11.0, -27), Vector3(9.5, 1.0, 1.6), Color("#6b2a7a"))
	ponte.rotation_degrees = Vector3(0, 0, 4)
	_luce(Vector3(102, 3.5, -18), Color("#c04aff"), 1.5, 11.0)
	_luce(Vector3(110, 3.0, -31), Color("#c04aff"), 1.8, 10.0)

## Il nido: un budello di carne che dalla piazza scende fino a una camera col cuore.
## Corridoio (z 10..-12), caverna (z -12..-38), camera del cuore (z -38..-54).
func _costruisci_nido() -> void:
	var carne := Color("#3d1550")
	var carne2 := Color("#4a1a5e")
	_box(Vector3(201, -0.05, -22), Vector3(74, 0.1, 70), Color("#24102e"))
	_box(Vector3(201, 9.0, -22), Vector3(74, 0.5, 70), Color("#1a0a22"))   # volta
	# corridoio
	_blocco(186, 196, -12, 12, 9, carne)
	_blocco(204, 214, -12, 12, 9, carne2)
	_blocco(186, 214, 10, 12, 9, carne)
	# caverna, con due colonne di carne
	# 0.7: i muri della caverna si aprono su due ali (dispensa a ovest, culle a est)
	_blocco(184, 188, -40, -34, 9, carne2)
	_blocco(184, 188, -28, -12, 9, carne2)
	_blocco(212, 216, -40, -24, 9, carne)
	_blocco(212, 216, -18, -12, 9, carne)
	_costruisci_dispensa(carne, carne2)
	_costruisci_culle(carne, carne2)
	_blocco(195.5, 197.5, -26, -23, 9, carne2)
	_blocco(203, 205.5, -20, -17.5, 9, carne)
	# camera del cuore
	_blocco(184, 194, -56, -38, 9, carne)
	_blocco(206, 216, -56, -38, 9, carne2)
	_blocco(184, 216, -56, -54, 9, carne)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# bolle e sacche sui muri, alcune accese
	for k in 70:
		var lato := -1.0 if rng.randf() < 0.5 else 1.0
		var z := rng.randf_range(-52.0, 9.0)
		var x := 200.0 + lato * (3.9 if z > -12.0 else (11.8 if z > -38.0 else 5.9))
		if (lato < 0 and z < -27.5 and z > -34.5) or (lato > 0 and z < -17.5 and z > -24.5):
			continue   # 0.7: lì ora ci sono le aperture sulle ali
		_sfera(Vector3(x, rng.randf_range(0.3, 7.5), z), rng.randf_range(0.3, 1.1), carne.lerp(Color("#c0407a"), rng.randf()), 0.6 if rng.randf() < 0.3 else 0.0)
	# vene luminose a terra che portano al cuore (Nox)
	for k in 26:
		var t := float(k) / 25.0
		var z := lerpf(6.0, -46.0, t)
		var x := 200.0 + sin(t * 9.0) * (1.4 if z > -12.0 else 4.0)
		_box(Vector3(x, 0.03, z), Vector3(0.18, 0.04, 2.3), Color("#2ef2ff"), 1.4)
	# il bozzolo: dentro si vedono un casco da scooter e una ruota di bici
	_sfera(Vector3(193.0, 1.2, -16.0), 1.3, Color("#6b2a7a"), 0.0)
	_box(Vector3(193.6, 1.0, -15.0), Vector3(0.5, 0.4, 0.5), Color("#e8e8e8"))
	_box(Vector3(192.4, 0.7, -15.2), Vector3(0.08, 1.0, 1.0), Color("#20242e"))
	# l'orologio d'oro incastrato nella carne (Saul)
	_box(Vector3(210.9, 1.3, -30.0), Vector3(0.1, 0.25, 0.25), Color("#ffd23f"), 1.2)
	_luce(Vector3(210.0, 1.4, -30.0), Color("#ffd23f"), 0.6, 3.0)
	# la radio di un agente, inghiottita a metà (Lance)
	_box(Vector3(204.15, 1.0, -4.0), Vector3(0.2, 0.5, 0.25), Color("#2a2e36"))
	_box(Vector3(204.05, 1.2, -4.0), Vector3(0.02, 0.06, 0.06), Color("#ff2340"), 2.0)
	# il reperto, in una nicchia bassa della caverna (Rio): un frammento chiaro e liscio
	_box(Vector3(188.4, 0.35, -24.0), Vector3(0.05, 0.3, 0.22), Color("#f4f1ea"), 0.7)
	_luce(Vector3(189.0, 0.6, -24.0), Color("#a65bff"), 0.7, 3.0)
	# il cuore
	var cuore := _sfera(Vector3(200, 3.2, -49.0), 3.0, Color("#b2367a"), 0.5)
	cuore.name = "cuore"
	for k in 8:
		var a := TAU * k / 8.0
		var cavo := _box(Vector3(200 + cos(a) * 3.6, 3.2 + sin(a) * 3.0, -51.0), Vector3(0.5, 0.5, 4.0), carne2)
		cavo.look_at_from_position(cavo.position, Vector3(200, 3.2, -49.0))
	_solidi.append(Rect2(197.0, -52.0, 6.0, 6.0))
	_luce(Vector3(200, 4.0, -44.0), Color("#ff2bd6"), 2.2, 14.0)
	_luce(Vector3(200, 4.0, -24.0), Color("#c04aff"), 1.6, 14.0)
	_luce(Vector3(200, 3.5, 2.0), Color("#c04aff"), 1.2, 10.0)

## 0.7, PROPOSTA approvato dall'autore il 14/11/2026: l'ala ovest del nido, dove finisce quello che il nido ingoia.
func _costruisci_dispensa(carne: Color, carne2: Color) -> void:
	_blocco(164, 168, -48, -16, 9, carne)
	_blocco(164, 188, -48, -44, 9, carne2)
	_blocco(164, 188, -20, -16, 9, carne)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	# il mucchio: carrelli, bici, cartelli, scarpe, tutto impastato
	for k in 26:
		var p := Vector3(rng.randf_range(171.0, 177.0), rng.randf_range(0.2, 2.6), rng.randf_range(-37.0, -31.0))
		var b := _box(p, Vector3(rng.randf_range(0.3, 1.2), rng.randf_range(0.2, 0.8), rng.randf_range(0.3, 1.2)), [Color("#8a8f99"), Color("#c23a3a"), Color("#e8e8e8"), Color("#2a5aa8"), Color("#d8b33a"), Color("#20242e")][k % 6])
		b.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0, TAU), rng.randf_range(-0.6, 0.6))
	_sfera(Vector3(174.0, 0.6, -34.0), 2.6, carne2, 0.0)
	_solidi.append(Rect2(170.5, -37.5, 7.0, 7.0))
	# la fermata dell'autobus, palina e tabella (Saul)
	_box(Vector3(180.5, 1.5, -24.0), Vector3(0.12, 3.0, 0.12), Color("#9aa0a8"))
	_box(Vector3(180.5, 2.8, -24.0), Vector3(0.08, 0.7, 0.9), Color("#f2c21a"), 0.6)
	_box(Vector3(180.5, 1.9, -24.0), Vector3(0.06, 0.8, 0.6), Color("#f4f1ea"))
	# la vetrina di una gelateria, intera, piantata nella carne (Lance)
	_box(Vector3(170.2, 1.4, -24.0), Vector3(0.4, 2.2, 3.0), Color("#20242e"))
	_box(Vector3(170.45, 1.6, -24.0), Vector3(0.05, 1.4, 2.4), Color("#8fd0ff"), 0.8)
	for k in 24:
		var lato := -1.0 if k % 2 == 0 else 1.0
		var z := rng.randf_range(-43.0, -21.0)
		_sfera(Vector3(168.2 if lato < 0 else 187.0, rng.randf_range(0.5, 7.5), z) if k % 3 else Vector3(rng.randf_range(168.0, 186.0), rng.randf_range(0.5, 7.5), -43.6 if lato < 0 else -20.4), rng.randf_range(0.4, 1.2), carne.lerp(Color("#c0407a"), rng.randf()), 0.6 if rng.randf() < 0.3 else 0.0)
	_luce(Vector3(176.0, 4.0, -30.0), Color("#ff7a3a"), 1.4, 13.0)

## 0.7, PROPOSTA approvato dall'autore il 14/11/2026: l'ala est, le culle dove crescono le anomalie piccole.
func _costruisci_culle(carne: Color, carne2: Color) -> void:
	_blocco(232, 236, -36, -4, 9, carne2)
	_blocco(212, 236, -36, -32, 9, carne)
	_blocco(212, 236, -8, -4, 9, carne2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 113
	# le uova: sacche traslucide con un'ombra dentro
	for k in 14:
		var p := Vector3(rng.randf_range(218.0, 230.0), 0.0, rng.randf_range(-30.0, -10.0))
		var libero := absf(p.z + 21.0) < 2.5 or p.z > -16.5   # la fascia nord resta libera: si cammina fino alle tacche
		for q in [Vector3(221, 0, -26), Vector3(228, 0, -30), Vector3(226, 0, -24), Vector3(227, 0, -27)]:
			if p.distance_to(q) < 3.0:
				libero = true
		if libero:
			continue   # strade e punti da esaminare restano liberi
		var r := rng.randf_range(0.6, 1.1)
		_sfera(p + Vector3(0, r * 0.9, 0), r, Color("#b04a9a"), 0.35)
		_sfera(p + Vector3(0, r * 0.8, 0), r * 0.45, Color("#12061a"), 0.0)
		_solidi.append(Rect2(p.x - r, p.z - r, r * 2.0, r * 2.0))
	# la culla più piccola (Rio)
	_sfera(Vector3(225.4, 0.45, -10.6), 0.5, Color("#c06ab0"), 0.4)
	_sfera(Vector3(225.4, 0.42, -10.6), 0.22, Color("#12061a"), 0.0)
	# le tacche graffiate sul muro (Lance): qualcuno ha contato i giorni
	for k in 11:
		_box(Vector3(232.0 - 0.05, 1.4, -14.0 + k * 0.18), Vector3(0.04, 0.6 if k % 5 != 4 else 0.04, 0.04), Color("#f4f1ea"), 0.4)
	_box(Vector3(231.95, 1.4, -11.3), Vector3(0.04, 0.05, 0.9), Color("#f4f1ea"), 0.4)
	for k in 22:
		_sfera(Vector3(rng.randf_range(213.0, 231.0), rng.randf_range(4.0, 8.5), rng.randf_range(-31.0, -9.0)), rng.randf_range(0.4, 1.0), carne.lerp(Color("#c0407a"), rng.randf()), 0.6 if rng.randf() < 0.4 else 0.0)
	_luce(Vector3(224.0, 3.5, -20.0), Color("#ff2bd6"), 1.5, 13.0)

func _muro_carne(c: Vector3, lungo_x: bool, seme: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var size := Vector3(9.0, 11.0, 1.6) if lungo_x else Vector3(1.6, 11.0, 9.0)
	_box(c + Vector3(0, 5.5, 0), size, Color("#3d1550"), 0.0, null, true)
	for k in 22:
		var off := Vector3(rng.randf_range(-4.2, 4.2), rng.randf_range(0.4, 10.0), rng.randf_range(-0.6, 0.6))
		if not lungo_x:
			off = Vector3(off.z, off.y, off.x)
		_sfera(c + off, rng.randf_range(0.5, 1.4), Color("#5b1f78").lerp(Color("#c0407a"), rng.randf()), 0.5 if rng.randf() < 0.25 else 0.0)

# ---------------------------------------------------------------- personaggi

## Corpo segnaposto a due toni. Braccia e gambe sono perni separati così
## si muovono quando si cammina; le parti hanno nomi fissi per la regia.
func _persona(chi: String) -> Node3D:
	var a: Dictionary = ASPETTO[chi]
	var root := Node3D.new()
	root.name = chi
	var corpo := Node3D.new()
	corpo.name = "corpo"
	root.add_child(corpo)
	var h := 0.92 if chi == "rio" else 1.0
	for lato in [-1, 1]:
		var anca := Node3D.new()
		anca.name = "gamba_s" if lato == -1 else "gamba_d"
		anca.position = Vector3(0.13 * lato, 0.84 * h, 0)
		corpo.add_child(anca)
		_box(Vector3(0, -0.42 * h, 0), Vector3(0.19, 0.84 * h, 0.21), a["gambe"], 0.0, anca)
		_box(Vector3(0, -0.8 * h, 0.05), Vector3(0.21, 0.11, 0.34), Color("#e8e8ee") if chi in ["rio", "saul"] else Color("#0c0c10"), 0.0, anca)
		var spalla := Node3D.new()
		spalla.name = "braccio_s" if lato == -1 else "braccio_d"
		spalla.position = Vector3(0.34 * lato, 1.38 * h, 0)
		corpo.add_child(spalla)
		_box(Vector3(0, -0.28 * h, 0), Vector3(0.15, 0.58 * h, 0.17), a["corpo"], 0.0, spalla)
		_box(Vector3(0, -0.6 * h, 0), Vector3(0.11, 0.1, 0.12), a["pelle"], 0.0, spalla)
	_box(Vector3(0, 1.12 * h, 0), Vector3(0.54, 0.62 * h, 0.31), a["corpo"], 0.0, corpo)
	_sfera(Vector3(0, 1.64 * h, 0), 0.21, a["pelle"], 0.0, corpo)
	match chi:
		"lance":
			_box(Vector3(0, 1.82, 0.0), Vector3(0.45, 0.12, 0.45), Color("#141a2c"), 0.0, corpo)
			_box(Vector3(0, 1.77, 0.0), Vector3(0.46, 0.04, 0.46), a["accento"], 0.0, corpo)
			_box(Vector3(0, 1.77, 0.26), Vector3(0.36, 0.03, 0.2), Color("#141a2c"), 0.0, corpo)
			_box(Vector3(-0.34, 1.25, 0), Vector3(0.16, 0.08, 0.18), a["accento"], 0.0, corpo)
		"nox":
			_box(Vector3(0, 0.72, 0), Vector3(0.58, 0.66, 0.33), a["corpo"], 0.0, corpo)     # cappotto lungo
			_box(Vector3(0, 1.4, 0.02), Vector3(0.44, 0.1, 0.35), a["accento"], 0.0, corpo)  # sciarpa
			_sfera(Vector3(0, 1.72, -0.06), 0.22, a["capelli"], 0.0, corpo)
			_box(Vector3(0, 1.45, -0.18), Vector3(0.3, 0.5, 0.12), a["capelli"], 0.0, corpo)
		"saul":
			_box(Vector3(0, 1.84, 0.0), Vector3(0.41, 0.14, 0.41), Color("#2a2a2a"), 0.0, corpo)  # berretto di lana
			_box(Vector3(0.1, 1.12, 0.0), Vector3(0.06, 0.66, 0.34), Color("#5a4630"), 0.0, corpo) # tracolla
			_box(Vector3(0, 1.12, 0.17), Vector3(0.3, 0.3, 0.02), Color("#8a8a8a"), 0.0, corpo)   # felpa grigia
		"rio":
			# capelli bianchi dritti a punte
			for k in 7:
				var c := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.0
				cm.bottom_radius = 0.07
				cm.height = 0.36
				cm.radial_segments = 5
				c.mesh = cm
				c.material_override = _mat(a["capelli"])
				var ang := -1.2 + k * 0.4
				c.position = Vector3(sin(ang) * 0.12, 1.64 * h + 0.2, -0.04 - cos(ang) * 0.05)
				c.rotation = Vector3(-0.3, 0, -ang * 0.6)
				corpo.add_child(c)
			# la maschera: copre tutta la faccia
			var m := _box(Vector3(0, 1.62 * h, 0.15), Vector3(0.36, 0.34, 0.1), Color("#f2f0ea"), 0.0, corpo)
			m.name = "maschera"
			for lato in [-1, 1]:
				var occhio := _box(Vector3(0.08 * lato, 1.66 * h, 0.205), Vector3(0.1, 0.025, 0.02), Color("#c35bff"), 3.0, corpo)
				occhio.name = "occhio_%d" % (lato + 1)
			_box(Vector3(0, 1.55 * h, 0.205), Vector3(0.08, 0.015, 0.02), Color("#ffd23a"), 1.5, corpo)
	# 0.6: meno pezzi da disegnare, stesso aspetto
	_fondi_parte(corpo)
	for parte in corpo.get_children():
		if parte.name.begins_with("gamba") or parte.name.begins_with("braccio"):
			_fondi_parte(parte)
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
