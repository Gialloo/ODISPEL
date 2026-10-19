extends Node3D

# AREA ESPLORABILE dell'atto 1 (configurata da data/atto1.json, sezione "aree"):
#   capo squadra controllato in terza persona + gli altri tre che lo seguono e chiacchierano (Banter, non blocca)
#   indizi da trovare (dialoghi Persona, alcuni svelano la debolezza del boss)
#   frammenti (anomalie minori): ATTACCA per il vantaggio, se ti toccano agguato
#   uscita (soglia dell'Anomalia) oppure boss finale con PARLA / ATTACCA / agguato
# Rendering come la demo: unshaded + toon nello shader, contorni a guscio, niente luci/ombre/cielo/Label3D.

const SPEED: float = 4.6
const R_PLAYER: float = 0.35
const AMBUSH_TIME: float = 4.5
const ORDER: Array = ["saul", "ferri", "nox", "zecca"]

var area_id: String = "strada"
var cfg: Dictionary = {}
var resume: Dictionary = {}
var player: CharacterVisual
var followers: Array = []
var cam: Camera3D
var cctv_head: Node3D
var yaw: float = 0.0
var pitch: float = 0.3
var dist: float = 4.8
var mode: String = "walk"          # intro | intro_wait | walk | dialog | leaving
var near: bool = false

var clues: Array = []              # indizi trovati in quest'area
var defeated: Array = []           # frammenti gia' battuti
var _target: String = ""           # "indizio:<id>", "nemico:<id>", "boss", "uscita"
var _focus: Vector3 = Vector3.ZERO
var _lay: Dictionary = {}
var _colliders: Array = []
var _markers: Dictionary = {}      # id indizio -> Node3D (bagliore)
var _enemies: Dictionary = {}      # id -> {"node": VendingVisual, "cfg": {...}, "home": Vector3}
var _boss: VendingVisual
var _secret: VendingVisual             # boss segreto di prova (telecamera rotta), solo dove "segreto" e' nei dati
var _exit_node: Node3D
var _trail: Array = []
var _ambush_t: float = 0.0
var _t: float = 0.0
var _enemy_t: float = 0.0          # tempo dei frammenti: scorre solo mentre si esplora (fermi in pausa e nei dialoghi)
var _grace: float = 0.0            # secondi senza agguati, tornando nell'area dopo una battaglia
var _points: Dictionary = {}       # punti delle chiacchiere (dal layout e dai dati), calcolati una volta

var _ui: CanvasLayer
var _root: Control
var _touch: TouchControls
var _prompt: Label
var _goal: Label
var _help: Label
var _toast_lbl: Label
var _dialog: DialogBox
var _banter: Banter
var _pause_btn: Button
var _pause: Control
var _mouse_drag: bool = false
var _shake: float = 0.0
var _cam_pos: Vector3
var _env: Environment
var _dome: MeshInstance3D


func configure(args: Dictionary) -> void:
	area_id = str(args.get("area", "strada"))
	resume = args.get("resume", {})


func crumb() -> String:
	return "strada"


static func _v3(a: Variant, y: float = 0.14) -> Vector3:
	var arr: Array = a
	return Vector3(float(arr[0]), y, float(arr[1]))


func _ready() -> void:
	Breadcrumb.mark("strada_carico")
	cfg = Story.area(area_id)
	clues = (resume.get("clues", []) as Array).duplicate()
	defeated = (resume.get("defeated", []) as Array).duplicate()
	var env := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = _env
	add_child(env)
	_lay = LayoutBuilder.build(str(cfg.get("layout", "strada")), int(cfg.get("seme", 29)), str(cfg.get("tema", "")), self)
	_env.background_color = _lay["bg"]
	var fog: Array = _lay["fog"]
	Toon.set_fog(fog[0], fog[1], fog[2])
	_colliders = _lay["colliders"]
	_points = (_lay.get("points", {}) as Dictionary).duplicate()
	for p in cfg.get("punti", []):
		_points[str(p["id"])] = Vector2(float(p["pos"][0]), float(p["pos"][1]))
	# tornando da una battaglia (persa o vinta) si riparte vicino al nemico: un attimo di respiro prima di un altro agguato
	if not resume.is_empty():
		_grace = 2.5
	if cfg.has("telecamera"):
		_build_cctv(_v3(cfg["telecamera"], 0.14))
	_build_clues()
	_build_enemies()
	_build_boss_and_exit()
	_build_party()
	cam = Camera3D.new()
	cam.fov = 62.0
	cam.near = 0.1
	cam.far = 160.0
	add_child(cam)
	cam.current = true
	_build_ui()
	_update_camera(1.0, true)
	Breadcrumb.mark("strada")
	if cfg.has("intro") and resume.is_empty():
		_intro()
	elif not resume.is_empty():
		# tornando da una battaglia vinta lo stato nuovo (nemico battuto) va anche su disco
		_persist()


# ---------------------------------------------------------------- costruzione

func _build_cctv(pos: Vector3) -> void:
	var mb := MeshBatch.new()
	mb.prism(Transform3D(Basis(), Vector3.ZERO), 0.09, 0.07, 3.9, 6, Color("#2b2638"))
	var pole := mb.make_instance("CctvPole")
	pole.position = pos
	add_child(pole)
	_colliders.append({"c": Vector2(pos.x, pos.z), "r": 0.25})
	cctv_head = Node3D.new()
	cctv_head.position = pos + Vector3(0, 3.95, 0)
	add_child(cctv_head)
	var hb := MeshBatch.new()
	hb.box(Transform3D(Basis(), Vector3(0, 0, -0.18)), Vector3(0.26, 0.24, 0.55), Color("#d9d4e6"))
	hb.box(Transform3D(Basis(), Vector3(0, 0.15, -0.2)), Vector3(0.34, 0.04, 0.65), Color("#8a83a0"))
	hb.box(Transform3D(Basis(), Vector3(0, 0, -0.465)), Vector3(0.16, 0.16, 0.02), Color("#141019"), false)
	hb.box(Transform3D(Basis(), Vector3(0.08, 0.08, -0.47)), Vector3(0.04, 0.04, 0.02), Color(1.0, 0.1, 0.2, 0.0), false)
	cctv_head.add_child(hb.make_instance("CctvHead"))


func _build_clues() -> void:
	for c in cfg.get("indizi", []):
		var id: String = str(c["id"])
		if clues.has(id) or id == "telecamera":
			continue
		var n := Node3D.new()
		n.position = _v3(c["pos"])
		add_child(n)
		if bool(c.get("oggetto", false)):
			var mb := MeshBatch.new()
			mb.box(Transform3D(Basis(Vector3.UP, 0.5), Vector3(0, 0.01, 0)), Vector3(0.18, 0.012, 0.3), Color(0.97, 0.95, 0.88, 0.0))
			n.add_child(mb.make_instance("Clue"))
		var g := MeshInstance3D.new()
		g.name = "Glow"
		g.mesh = MeshBatch.disc(0.75, Color(0.25, 0.9, 1.0, 0.45), 16, 0.02)
		g.material_override = Toon.glow()
		n.add_child(g)
		_markers[id] = n


func _build_enemies() -> void:
	for e in cfg.get("nemici", []):
		var id: String = str(e["id"])
		if defeated.has(id):
			continue
		var v := VendingVisual.new()
		v.kind = str(e.get("boss", "frammento_viola"))
		v.awake = true
		v.position = _v3(e["pos"], 0.0)
		add_child(v)
		_enemies[id] = {"node": v, "cfg": e, "home": v.position, "phase": randf() * TAU}


func _build_boss_and_exit() -> void:
	if cfg.has("boss"):
		var b: Dictionary = cfg["boss"]
		_boss = VendingVisual.new()
		_boss.kind = str(b.get("tipo", "distributore"))
		_boss.position = _v3(b["pos"], 0.14)
		_boss.rotation.y = deg_to_rad(float(b.get("rot", 0)))
		add_child(_boss)
		_colliders.append({"rect": Rect2(_boss.position.x - 0.8, _boss.position.z - 0.8, 1.6, 1.6)})
	if cfg.has("segreto"):
		var sg: Dictionary = cfg["segreto"]
		_secret = VendingVisual.new()
		_secret.kind = str(sg.get("tipo", "telecamera"))
		_secret.position = _v3(sg["pos"], 0.14)
		_secret.rotation.y = deg_to_rad(float(sg.get("rot", 0)))
		add_child(_secret)
		_colliders.append({"rect": Rect2(_secret.position.x - 0.7, _secret.position.z - 0.7, 1.4, 1.4)})
	if cfg.has("uscita"):
		var u: Dictionary = cfg["uscita"]
		_exit_node = Node3D.new()
		_exit_node.position = _v3(u["pos"], 0.0)
		add_child(_exit_node)
		var tipo: String = str(u.get("tipo", ""))
		if tipo != "":
			var v := VendingVisual.new()
			v.kind = tipo
			_exit_node.add_child(v)
			_colliders.append({"rect": Rect2(_exit_node.position.x - 0.8, _exit_node.position.z - 0.8, 1.6, 1.6)})
		var g := MeshInstance3D.new()
		g.name = "Glow"
		g.mesh = MeshBatch.disc(2.4, Color(0.75, 0.3, 1.0, 0.35), 20, 0.03)
		g.material_override = Toon.glow()
		_exit_node.add_child(g)


func _build_party() -> void:
	var lead: String = str(cfg.get("capo", "saul"))
	player = CharacterVisual.new()
	player.setup(lead)
	add_child(player)
	player.position = Vector3(1.2, 0.14, 8.0)
	if resume.has("pos"):
		player.position = resume["pos"]
		yaw = float(resume.get("yaw", 0.0))
	player.rotation.y = yaw
	var k: int = 0
	for id in ORDER:
		if id == lead:
			continue
		k += 1
		var f := CharacterVisual.new()
		f.setup(id)
		add_child(f)
		f.position = player.position + Vector3((k - 2) * 0.9, 0, 1.2 * k)
		followers.append(f)
	for i in 40:
		_trail.append(player.position + Vector3(0, 0, 0.3 * i))


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	_root = Control.new()
	Ui.place(_root, 0, 0, 1, 1)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	_touch = TouchControls.new()
	_root.add_child(_touch)
	_touch.action_pressed.connect(_interact)
	_touch.action2_pressed.connect(_strike)
	_goal = Ui.label("", 21, Ui.CREAM, null, 6)
	_goal.position = Vector2(24, 50 if Settings.show_fps else 16)
	_goal.text = "%s\n%s" % [Story.chapter_title(), str(cfg.get("obiettivo", ""))]
	_root.add_child(_goal)
	_banter = Banter.new()
	_banter.set_key = str(cfg.get("chiacchiere", area_id))
	_root.add_child(_banter)
	if resume.has("banter_used"):
		_banter.set("_used", (resume["banter_used"] as Dictionary).duplicate())
	_prompt = Ui.label("", 26, Ui.YELLOW, Ui.display(), 8)
	Ui.place(_prompt, 0.5, 0.72, 0.5, 0.72, -460, 0, 460, 50)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_prompt)
	_toast_lbl = Ui.label("", 26, Ui.CYAN, Ui.display(), 8)
	Ui.place(_toast_lbl, 0.5, 0.6, 0.5, 0.6, -560, 0, 560, 70)
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_lbl.modulate.a = 0.0
	_root.add_child(_toast_lbl)
	if not TouchUi.active():
		_help = Ui.label("WASD muovi · mouse o Q/R camera · E interagisci · F attacca · Esc pausa", 18, Color(1, 1, 1, 0.6), null, 4)
		Ui.place(_help, 0, 1.0, 1.0, 1.0, 24, -36, 0, -6)
		_root.add_child(_help)
	_pause_btn = Ui.button("II", Ui.CREAM, 26, 70)
	Ui.place(_pause_btn, 1.0, 0, 1.0, 0, -94, 20, -24, 84)
	_pause_btn.pressed.connect(_open_pause)
	_root.add_child(_pause_btn)
	_dialog = DialogBox.new()
	_root.add_child(_dialog)


func _main() -> Node:
	return get_parent()


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if mode != "walk" or _pause != null:
		_mouse_drag = false      # il tasto rilasciato durante un dialogo non arriva qui: niente camera che gira da sola dopo
		return
	# pausa anche col secondo dito (pollice sullo stick): Godot trasforma in clic solo il primo dito
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed \
			and _pause_btn.visible and _pause_btn.get_global_rect().grow(12).has_point((event as InputEventScreenTouch).position):
		get_viewport().set_input_as_handled()
		_open_pause()
		return
	if _touch.handle(event):
		get_viewport().set_input_as_handled()
		return
	if OS.has_feature("mobile"):
		return
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event
		if mbe.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_mouse_drag = mbe.pressed
		elif mbe.button_index == MOUSE_BUTTON_WHEEL_UP and mbe.pressed:
			dist = clampf(dist - 0.3, 3.2, 6.5)
		elif mbe.button_index == MOUSE_BUTTON_WHEEL_DOWN and mbe.pressed:
			dist = clampf(dist + 0.3, 3.2, 6.5)
	elif event is InputEventMouseMotion and _mouse_drag:
		var mm: InputEventMouseMotion = event
		yaw -= mm.relative.x * 0.006
		pitch = clampf(pitch + mm.relative.y * 0.004, 0.08, 0.75)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE:
			if _pause != null:
				_close_pause()
			elif mode == "walk":
				_open_pause()
		elif mode == "walk" and k in [KEY_E, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
			_interact()
		elif mode == "walk" and k == KEY_F:
			_strike()


func back() -> void:
	if _pause != null:
		_close_pause()
	elif mode == "walk":
		_open_pause()


func _key_vec() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1.0
	return v.limit_length(1.0)


# ---------------------------------------------------------------- aggiornamento

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_t += delta
	var moving: bool = false
	var exploring: bool = mode == "walk" and _pause == null
	if exploring:
		moving = _walk(delta)
		_enemy_t += delta
		_grace = maxf(0.0, _grace - delta)
	else:
		player.move_speed = 0.0
	_follow(delta)
	_animate_world(delta)
	_update_camera(delta, false)
	_update_target()
	_touch.visible = mode == "walk" and _pause == null
	_pause_btn.visible = mode == "walk"
	if _help != null:
		_help.visible = mode == "walk"
	_goal.visible = mode == "walk"
	_banter.paused = mode != "walk" or _pause != null
	_banter.visible = not _banter.paused     # i fumetti non si sovrappongono ai dialoghi e alla pausa
	_banter.tick(delta, player.position.z, moving, _near_points())
	# in pausa niente agguati (prima un frammento poteva toccarti col menu di pausa aperto)
	if exploring:
		_check_threats(delta)


func _walk(delta: float) -> bool:
	var v: Vector2 = _key_vec()
	if _touch.stick.length() > 0.08:
		v = _touch.stick
	var drag: Vector2 = _touch.take_cam_drag()
	yaw -= drag.x * 0.0065
	pitch = clampf(pitch + drag.y * 0.004, 0.08, 0.75)
	if Input.is_physical_key_pressed(KEY_Q):
		yaw += delta * 2.0
	if Input.is_physical_key_pressed(KEY_R):
		yaw -= delta * 2.0
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var mv: Vector3 = right * v.x + fwd * (-v.y)
	var amt: float = clampf(mv.length(), 0.0, 1.0)
	player.move_speed = amt
	if amt > 0.05:
		var dir: Vector3 = mv.normalized()
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 12.0))
		player.position = _collide(player.position + dir * SPEED * amt * delta, R_PLAYER)
		if player.position.distance_to(_trail[0]) > 0.3:
			_trail.push_front(player.position)
			if _trail.size() > 60:
				_trail.pop_back()
		return true
	return false


# I compagni seguono la scia del capo, a distanza
func _follow(delta: float) -> void:
	for i in followers.size():
		var f: CharacterVisual = followers[i]
		var idx: int = mini(_trail.size() - 1, 4 + 4 * i)
		var target: Vector3 = _trail[idx]
		target.x += (0.8 if i % 2 == 0 else -0.8)
		var d: Vector3 = target - f.position
		d.y = 0.0
		var len: float = d.length()
		if len > 0.25 and mode != "intro":
			var step: float = minf(len, SPEED * 1.15 * delta * clampf(len, 0.3, 1.6))
			f.position = _collide(f.position + d.normalized() * step, 0.3)
			f.rotation.y = lerp_angle(f.rotation.y, atan2(-d.x, -d.z), minf(1.0, delta * 10.0))
			f.move_speed = clampf(len * 0.8, 0.0, 1.0)
		else:
			f.move_speed = 0.0
			if mode == "dialog" or mode == "leaving":
				var to: Vector3 = _focus - f.position
				f.rotation.y = lerp_angle(f.rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * 4.0))
		# un compagno troppo vicino alla telecamera copre la scena: si nasconde finche' non si allontana
		if cam != null:
			var dc: Vector3 = f.position + Vector3(0, 1.0, 0) - cam.position
			f.visible = dc.length() > 2.0 and dc.dot(-cam.global_transform.basis.z) > 0.6


func _animate_world(delta: float) -> void:
	for id in _markers:
		var g: Node3D = (_markers[id] as Node3D).get_node("Glow")
		var k: float = 0.75 + 0.35 * sin(_t * 5.0)
		g.scale = Vector3(k, 1, k)
	for id in _enemies:
		var e: Dictionary = _enemies[id]
		var v: VendingVisual = e["node"]
		var ph: float = float(e["phase"]) + _enemy_t * 0.6
		v.position = (e["home"] as Vector3) + Vector3(sin(ph) * 1.6, 0, cos(ph * 0.7) * 1.2)
		var to: Vector3 = player.position - v.position
		v.rotation.y = lerp_angle(v.rotation.y, atan2(-to.x, -to.z) + PI, minf(1.0, delta * 2.0))
	if cctv_head != null:
		var to2: Vector3 = player.position + Vector3(0, 1.2, 0) - cctv_head.position
		cctv_head.rotation.y = lerp_angle(cctv_head.rotation.y, atan2(-to2.x, -to2.z), minf(1.0, delta * 2.0))
		cctv_head.rotation.x = lerpf(cctv_head.rotation.x, atan2(to2.y, Vector2(to2.x, to2.z).length()), minf(1.0, delta * 2.0))
	if _exit_node != null:
		var g2: Node3D = _exit_node.get_node("Glow")
		var k2: float = 0.85 + 0.15 * sin(_t * 3.0)
		g2.scale = Vector3(k2, 1, k2)


func _collide(p: Vector3, r_self: float) -> Vector3:
	var q := Vector2(p.x, p.z)
	for c in _colliders:
		if c.has("c"):
			var cc: Vector2 = c["c"]
			var rr: float = float(c["r"]) + r_self
			var d: Vector2 = q - cc
			if d.length() < rr:
				q = cc + (d.normalized() if d.length() > 0.001 else Vector2.RIGHT) * rr
		else:
			var r: Rect2 = (c["rect"] as Rect2).grow(r_self)
			if r.has_point(q):
				var dl: float = q.x - r.position.x
				var dr: float = r.end.x - q.x
				var dt: float = q.y - r.position.y
				var db: float = r.end.y - q.y
				var m: float = minf(minf(dl, dr), minf(dt, db))
				if m == dl:
					q.x = r.position.x
				elif m == dr:
					q.x = r.end.x
				elif m == dt:
					q.y = r.position.y
				else:
					q.y = r.end.y
	var bnd: Rect2 = _lay["bounds"]
	q.x = clampf(q.x, bnd.position.x, bnd.end.x)
	q.y = clampf(q.y, bnd.position.y, bnd.end.y)
	return Vector3(q.x, p.y, q.y)


func _update_camera(delta: float, snap: bool) -> void:
	var target: Vector3 = player.position + Vector3(0, 1.45, 0)
	var desired: Vector3
	var look: Vector3
	if mode == "intro":
		desired = Vector3(-6.0, 24.0, 26.0)
		look = Vector3(0.0, 8.0, -24.0)
	elif mode == "dialog" or mode == "leaving":
		var mid: Vector3 = (player.position + _focus) * 0.5 + Vector3(0, 1.4, 0)
		var side := Vector3(-(_focus - player.position).z, 0, (_focus - player.position).x).normalized()
		if side.x > 0.0:
			side = -side
		desired = mid + side * 3.6 + Vector3(0, 0.8, 0) + (player.position - _focus).normalized() * 1.5
		look = mid
	else:
		var back := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		desired = target + back * dist * cos(pitch) + Vector3(0, dist * sin(pitch), 0) + right * 0.55
		look = target + right * 0.55 + Vector3(0, 0.1, 0)
	var lim: float = float(_lay.get("cam_x", 6.75))
	if absf(desired.x) > lim:
		var k: float = (lim - absf(target.x)) / maxf(0.01, absf(desired.x - target.x))
		desired = target + (desired - target) * clampf(k, 0.15, 1.0)
	desired.y = clampf(desired.y, 0.6, float(_lay.get("cam_y", 99.0)))
	if snap:
		_cam_pos = desired
	else:
		_cam_pos = _cam_pos.lerp(desired, minf(1.0, delta * (4.0 if mode == "walk" else 2.5)))
	var sh := Vector3.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.5)
		var k2: float = _shake * Settings.shake * 0.25
		sh = Vector3(randf_range(-k2, k2), randf_range(-k2, k2), 0)
	cam.position = _cam_pos + sh
	cam.look_at(look + sh * 0.5, Vector3.UP)


func _d(p: Vector3) -> float:
	return Vector2(player.position.x - p.x, player.position.z - p.z).length()


func _near_points() -> Array:
	var out: Array = []
	var here := Vector2(player.position.x, player.position.z)
	for k in _points:
		if here.distance_to(_points[k]) < 3.5:
			out.append(str(k))
	return out


# Cosa c'e' vicino: il piu' importante vince (boss/uscita, poi nemici, poi indizi)
func _update_target() -> void:
	near = false
	if mode != "walk":
		_prompt.text = ""
		_touch.act_label = ""
		_touch.act2_label = ""
		return
	_target = ""
	var label: String = ""
	var key: String = ""
	if _boss != null and _d(_boss.position) < 2.8:
		_target = "boss"
	elif _secret != null and _d(_secret.position) < 2.8:
		_target = "segreto"
	elif _exit_node != null and _d(_exit_node.position) < 2.6:
		_target = "uscita"
	else:
		for id in _enemies:
			if _d((_enemies[id]["node"] as Node3D).position) < 2.6:
				_target = "nemico:" + str(id)
				break
		if _target == "":
			for c in cfg.get("indizi", []):
				var id2: String = str(c["id"])
				if clues.has(id2):
					continue
				if _d(_v3(c["pos"])) < float(c.get("raggio", 2.0)):
					_target = "indizio:" + id2
					label = str(c.get("etichetta", "GUARDA"))
					key = str(c.get("tasto", "GUARDA"))
					break
	near = _target != ""
	var touch: bool = TouchUi.active()
	var can_strike: bool = Settings.surprise and (_target == "boss" or _target.begins_with("nemico:"))
	if _target == "boss":
		if Settings.surprise and _ambush_t > AMBUSH_TIME * 0.5:
			_prompt.text = "TI STA FISSANDO..."
		else:
			_prompt.text = ("PARLA  ·  ATTACCA" if touch else "[E] AVVICINATI   ·   [F] ATTACCA A SORPRESA") if Settings.surprise else ("AVVICINATI" if touch else "[E]  AVVICINATI")
		key = "PARLA"
	elif _target == "segreto":
		_prompt.text = "???" if touch else "[E]  ???"
		key = "GUARDA"
	elif _target == "uscita":
		label = str((cfg["uscita"] as Dictionary).get("etichetta", "ENTRA"))
		key = str((cfg["uscita"] as Dictionary).get("tasto", "ENTRA"))
		_prompt.text = label if touch else "[E]  " + label
	elif _target.begins_with("nemico:"):
		_prompt.text = ("ATTACCA PRIMA CHE TI TOCCHI" if touch else "[F]  ATTACCA PRIMA CHE TI TOCCHI") if Settings.surprise else "FRAMMENTO D'ANOMALIA"
		key = ""
	elif _target.begins_with("indizio:"):
		_prompt.text = label if touch else "[E]  " + label
	else:
		_prompt.text = ""
	_touch.act_label = key
	_touch.act_live = key != ""
	_touch.act2_label = "ATTACCA" if can_strike else ""


# Frammenti che ti toccano e boss che ti fissa: agguato
func _check_threats(delta: float) -> void:
	if _grace > 0.0:
		_ambush_t = 0.0
		return
	for id in _enemies:
		if _d((_enemies[id]["node"] as Node3D).position) < 1.0:
			_enemy_battle(str(id), "agguato" if Settings.surprise else "normale")
			return
	if Settings.surprise and _target == "boss":
		_ambush_t += delta
		if _ambush_t > AMBUSH_TIME:
			_boss_ambush()
	else:
		_ambush_t = 0.0


# ---------------------------------------------------------------- apertura (solo prologo)

func _intro() -> void:
	Breadcrumb.mark("apertura")
	mode = "intro"
	_build_dome()
	var old_bg: Color = _env.background_color
	_env.background_color = Color("#2a0b22")
	_update_camera(1.0, true)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	_shake = 1.2
	_main().flash(0.7)
	Settings.buzz(80)
	await get_tree().create_timer(0.7).timeout
	var key: String = str(cfg["intro"])
	_dialog.play(DialogData.lines(key), DialogData.recap(key))
	await _dialog.finished
	if not is_inside_tree():
		return
	var card := ColorRect.new()
	card.color = Color(0.02, 0.01, 0.05, 1.0)
	Ui.place(card, 0, 0, 1, 1)
	card.modulate.a = 0.0
	_root.add_child(card)
	var txt: Array = cfg.get("intro_cartello", ["", ""])
	var t1 := Ui.label(str(txt[0]), 64, Ui.CREAM, Ui.display(), 10)
	Ui.place(t1, 0, 0.4, 1, 0.4, 0, 0, 0, 80)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t1)
	var t2 := Ui.label(str(txt[1]), 26, Color("#9ff0bd"), null, 6)
	Ui.place(t2, 0, 0.52, 1, 0.52, 0, 0, 0, 40)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t2)
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.35)
	await tw.finished
	if _dome != null:
		_dome.queue_free()
		_dome = null
	_env.background_color = old_bg
	mode = "intro_wait"
	_update_camera(1.0, true)
	await get_tree().create_timer(1.6).timeout
	var tw2 := create_tween()
	tw2.tween_property(card, "modulate:a", 0.0, 0.4)
	await tw2.finished
	card.queue_free()
	mode = "walk"
	Breadcrumb.mark("strada")


func _build_dome() -> void:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var rings: int = 10
	var segs: int = 28
	var r: float = 75.0
	for i in rings:
		for j in segs:
			var a0: float = PI * 0.5 * float(i) / float(rings)
			var a1: float = PI * 0.5 * float(i + 1) / float(rings)
			var b0: float = TAU * float(j) / float(segs)
			var b1: float = TAU * float(j + 1) / float(segs)
			var p := func(a: float, b: float) -> Vector3: return Vector3(cos(a) * cos(b) * r, sin(a) * r * 0.75, cos(a) * sin(b) * r - 20.0)
			# la cupola e' magenta rituale #E83DCE, il colore della magia (palette dell'IP)
			var c0 := Color(0.91, 0.24, 0.81, 0.28 - 0.2 * float(i) / float(rings))
			var c1 := Color(0.91, 0.24, 0.81, 0.28 - 0.2 * float(i + 1) / float(rings))
			v.append_array([p.call(a0, b0), p.call(a1, b0), p.call(a1, b1), p.call(a0, b0), p.call(a1, b1), p.call(a0, b1)])
			c.append_array([c0, c1, c1, c0, c1, c0])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_COLOR] = c
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_dome = MeshInstance3D.new()
	_dome.mesh = m
	_dome.material_override = Toon.glow()
	add_child(_dome)


# ---------------------------------------------------------------- interazioni

func _face(p: Vector3) -> void:
	var to: Vector3 = p - player.position
	player.rotation.y = atan2(-to.x, -to.z)
	_focus = p


func _clue_cfg(id: String) -> Dictionary:
	for c in cfg.get("indizi", []):
		if str(c["id"]) == id:
			return c
	return {}


func _interact() -> void:
	if not near or mode != "walk" or _pause != null:
		return
	var what: String = _target
	_touch.release_all()
	player.move_speed = 0.0
	Settings.buzz(20)
	if what.begins_with("indizio:"):
		var id: String = what.substr(8)
		var c: Dictionary = _clue_cfg(id)
		mode = "dialog"
		_face(_v3(c["pos"]))
		var key: String = str(c.get("dialogo", id))
		_dialog.play(DialogData.lines(key), DialogData.recap(key))
		await _dialog.finished
		if not clues.has(id):
			clues.append(id)
			_persist()
		if _markers.has(id):
			(_markers[id] as Node).queue_free()
			_markers.erase(id)
		if c.has("debolezza"):
			_toast("INDIZIO TROVATO: il nemico teme il %s" % str(c["debolezza"]), Ui.CYAN)
		mode = "walk"
		_banter.event(id)
	elif what == "uscita":
		var u: Dictionary = cfg["uscita"]
		mode = "dialog"
		_face(_exit_node.position)
		var key2: String = str(u.get("dialogo", ""))
		if key2 != "":
			_dialog.play(DialogData.lines(key2), DialogData.recap(key2))
			await _dialog.finished
		mode = "leaving"
		_shake = 0.7
		_main().flash(0.6)
		await get_tree().create_timer(0.35).timeout
		_carry_clues()
		Story.advance()
		_main().next_story()
	elif what == "segreto":
		# avviso con scelta: si combatte solo se il giocatore dice SI'
		var sg: Dictionary = cfg["segreto"]
		mode = "dialog"
		_face(_secret.position)
		Story.flags.erase("segreto_si")
		var ks: String = str(sg.get("dialogo", "segreto_avviso"))
		_dialog.play(DialogData.lines(ks), DialogData.recap(ks))
		await _dialog.finished
		if Story.has_flag("segreto_si"):
			Story.flags.erase("segreto_si")
			mode = "leaving"
			_secret_battle()
		else:
			mode = "walk"
	elif what == "boss":
		var b: Dictionary = cfg["boss"]
		mode = "dialog"
		_face(_boss.position)
		_dialog.play(DialogData.lines(str(b.get("dialogo", ""))), DialogData.recap(str(b.get("dialogo", ""))))
		await _dialog.finished
		mode = "leaving"
		await _boss.wake().finished
		_boss_battle("normale")


# Attacco a sorpresa (stile Star Rail): su un frammento o sul boss
func _strike() -> void:
	if mode != "walk" or _pause != null or not Settings.surprise:
		return
	if _target == "boss":
		mode = "leaving"
		_touch.release_all()
		_face(_boss.position)
		player.attack()
		await get_tree().create_timer(0.24).timeout
		_boss.hit()
		_toast("ATTACCO A SORPRESA!", Ui.YELLOW)
		_boss_battle("vantaggio")
	elif _target.begins_with("nemico:"):
		var id: String = _target.substr(7)
		mode = "leaving"
		_touch.release_all()
		var v: VendingVisual = _enemies[id]["node"]
		_face(v.position)
		player.attack()
		await get_tree().create_timer(0.24).timeout
		v.hit()
		_toast("ATTACCO A SORPRESA!", Ui.YELLOW)
		_enemy_battle(id, "vantaggio")


func _boss_ambush() -> void:
	var b: Dictionary = cfg["boss"]
	mode = "dialog"
	_touch.release_all()
	_face(_boss.position)
	await _boss.wake().finished
	_shake = 0.8
	var key: String = str(b.get("agguato", ""))
	if key != "":
		_dialog.play(DialogData.lines(key), DialogData.recap(key))
		await _dialog.finished
	mode = "leaving"
	_boss_battle("agguato")


# Gli indizi "debolezza" restano validi per il boss del passo successivo (es. dentro l'Anomalia)
func _carry_clues() -> void:
	var weak: Array = []
	for c in cfg.get("indizi", []):
		if clues.has(str(c["id"])) and c.has("debolezza"):
			weak.append(str(c["debolezza"]))
	Story.flags["debolezza_nota"] = weak


func _save_state(extra_defeated: String = "") -> void:
	var d: Array = defeated.duplicate()
	if extra_defeated != "":
		d.append(extra_defeated)
	Story.area_state = {"pos": player.position, "yaw": yaw, "clues": clues.duplicate(), "defeated": d,
		"banter_used": (_banter.get("_used") as Dictionary).duplicate()}


# Salva su disco il punto dell'area (posizione, indizi, nemici battuti): chi esce o chiude l'app riprende da qui
func _persist() -> void:
	if player == null or _banter == null:
		return
	_save_state()
	Story.save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if mode == "walk":
			_persist()


func _enemy_battle(id: String, ingresso: String) -> void:
	if mode == "transition":
		return
	mode = "transition"
	var e: Dictionary = _enemies[id]["cfg"]
	_save_state()
	var win_state: Dictionary = Story.area_state.duplicate(true)
	(win_state["defeated"] as Array).append(id)
	_go_battle({"boss": str(e.get("boss", "frammento_giallo")), "visual": str(e.get("boss", "frammento_giallo")), "livello": int(e.get("livello", 1)),
		"ingresso": ingresso, "arena": str(cfg.get("tema", "")) if cfg.has("tema") else str(cfg.get("layout", "strada")),
		"ritorno": {"tipo": "area", "area": area_id, "vinto": win_state, "perso": Story.area_state.duplicate(true)}, "minore": true, "indizi": []})


# Il boss segreto si puo' rifare quante volte si vuole: dopo la battaglia si torna qui, vinta o persa
func _secret_battle() -> void:
	if mode == "transition":
		return
	var sg: Dictionary = cfg["segreto"]
	_save_state()
	var st: Dictionary = Story.area_state.duplicate(true)
	_go_battle({"boss": str(sg.get("id", "osservatore")), "visual": str(sg.get("tipo", "telecamera")), "livello": int(sg.get("livello", 1)),
		"ingresso": "normale", "arena": str(sg.get("arena", "strada")), "pv": float(sg.get("pv", 1.0)), "atk": float(sg.get("atk", 1.0)),
		"ritorno": {"tipo": "area", "area": area_id, "vinto": st, "perso": st}, "minore": true, "debolezze": []})


func _boss_battle(ingresso: String) -> void:
	var b: Dictionary = cfg["boss"]
	_save_state()
	var weak: Array = []
	for c in cfg.get("indizi", []):
		if clues.has(str(c["id"])) and c.has("debolezza"):
			weak.append(str(c["debolezza"]))
	for w in Story.flags.get("debolezza_nota", []):
		if not weak.has(w):
			weak.append(w)
	_go_battle({"boss": str(b.get("id", "distributore")), "visual": str(b.get("tipo", "distributore")), "livello": int(b.get("livello", 1)),
		"ingresso": ingresso, "arena": str(b.get("arena", "strada")), "pv": float(b.get("pv", 1.0)), "atk": float(b.get("atk", 1.0)),
		"ritorno": {"tipo": "storia", "area": area_id, "perso": Story.area_state.duplicate(true)}, "debolezze": weak})


func _go_battle(args: Dictionary) -> void:
	Story.save()        # se l'app si chiude in battaglia si riprende davanti al nemico, non dall'inizio dell'area
	_shake = 0.8
	Settings.buzz(80)
	_main().flash(0.8)
	await get_tree().create_timer(0.4).timeout
	if is_inside_tree():
		Breadcrumb.mark("battaglia_carico")
		_main().go("battle", args)


func _toast(text: String, col: Color) -> void:
	_toast_lbl.text = text
	_toast_lbl.add_theme_color_override("font_color", col)
	var tw := _toast_lbl.create_tween()
	tw.tween_property(_toast_lbl, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.4)
	tw.tween_property(_toast_lbl, "modulate:a", 0.0, 0.4)


# ---------------------------------------------------------------- pausa

func _open_pause() -> void:
	if _pause != null:
		return
	_touch.release_all()
	_pause = HuddleMenu.new("MENU", _close_pause, _exit_to_menu, "Saul: «si riparte da qui, indizi compresi»")
	_root.add_child(_pause)


func _exit_to_menu() -> void:
	_persist()
	_main().go("menu")


func _close_pause() -> void:
	if _pause != null:
		_pause.queue_free()
		_pause = null
		HuddleMenu.quip(_root)
