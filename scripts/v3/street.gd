extends Node3D

# ESPLORAZIONE (test 0.29.0): una strada notturna di [CITTÀ], Saul in terza persona con la camera alle spalle,
# un distributore che ronza in fondo. Avvicinati, ispezionalo: due righe di dialogo, poi il combattimento.
#
# Rendering usato (per cercare un eventuale crash): Camera3D prospettica, shader spatial UNSHADED fatti a mano
# (toon a due toni + nebbia nello shader), contorni con guscio rovesciato (seconda superficie, NON next_pass),
# bagliori trasparenti additivi, sfondo a colore pieno (niente cielo ne' shader del cielo), nessuna luce, nessuna ombra,
# nessun Label3D/Sprite3D: tutto il testo e' UI 2D.

const SPEED: float = 4.6
const R_PLAYER: float = 0.35
const BOUNDS := Rect2(-6.6, -42.5, 13.2, 54.0)        # x, z percorribili
const MACHINE_POS := Vector3(5.3, 0.14, -33.0)
const CCTV_POS := Vector3(-5.6, 0.14, -27.0)
const RECEIPT_POS := Vector3(3.7, 0.14, -28.6)
const AMBUSH_TIME: float = 4.5      # secondi fermi davanti al distributore prima che attacchi lui (solo con l'attacco a sorpresa attivo)

var player: CharacterVisual
var machine: VendingVisual
var cam: Camera3D
var cctv_head: Node3D
var yaw: float = 0.0
var pitch: float = 0.3
var dist: float = 4.8
var mode: String = "walk"          # intro | walk | dialog | leaving | end
var near: bool = false
var done: bool = false             # rientro dopo il combattimento
var won: bool = true

var _ui: CanvasLayer
var _touch: TouchControls
var _prompt: Label
var _goal: Label
var _dialog: DialogBox
var _pause_btn: Button
var _pause: Control
var _colliders: Array = []
var _mouse_drag: bool = false
var _shake: float = 0.0
var _cam_pos: Vector3
var _first: bool = true
var intro: bool = true             # apertura in medias res (cupola) prima della strada
var clues: Array = []              # indizi trovati
var _target: String = ""           # oggetto vicino con cui interagire: telecamera, scontrino, distributore
var _barks: Array = []
var _bark_lbl: Label
var _ambush_t: float = 0.0
var _receipt: Node3D
var _dome: MeshInstance3D
var _env: Environment
var _help: Label


func configure(args: Dictionary) -> void:
	done = bool(args.get("done", false))
	won = bool(args.get("won", true))
	intro = bool(args.get("intro", not done))
	clues = args.get("indizi", [])


func crumb() -> String:
	return "strada"


func _ready() -> void:
	Breadcrumb.mark("strada_carico")
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#120b22")
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	add_child(env)
	_env = e
	Toon.set_fog(Color("#1a1030"), 16.0, 60.0)

	var cb := CityBuilder.new(29)
	cb.street(12.0, -46.0)
	cb.crosswalk(-17.0)
	var z: float = 10.0
	for side in [-1.0, 1.0]:
		z = 11.0
		while z > -44.0:
			var l: float = cb.rng.randf_range(6.0, 10.0)
			cb.building(side, z, l - 0.3, cb.rng.randf_range(7.0, 10.0), cb.rng.randf_range(7.0, 18.0))
			z -= l
	cb.backdrop(-46.0)
	for i in 6:
		var lz: float = 6.0 - 9.0 * i
		cb.lamp(4.45 if i % 2 == 0 else -4.45, lz)
	cb.bin(-6.2, -4.0)
	cb.bin(6.2, -14.5)
	cb.bin(-6.2, -36.0)
	cb.hydrant(4.6, -7.5)
	cb.bench(-6.1, -21.5)
	cb.car(-2.7, -11.0, Color("#2f8fb0"))
	cb.car(2.7, -25.0, Color("#c0392b"))
	cb.moon(Vector3(-30, 46, -140), 9.0)
	cb.build(self)
	_colliders = cb.colliders
	_build_cctv()
	_build_receipt()

	machine = VendingVisual.new()
	machine.position = MACHINE_POS
	machine.rotation.y = PI * 0.5
	add_child(machine)
	_colliders.append({"rect": Rect2(MACHINE_POS.x - 0.55, MACHINE_POS.z - 0.7, 1.4, 1.4)})

	player = CharacterVisual.new()
	player.setup("saul")
	add_child(player)
	player.position = Vector3(1.2, 0.14, 8.0)
	if done:
		player.position = Vector3(3.2, 0.14, -30.5)
		player.rotation.y = -PI * 0.75
		yaw = -PI * 0.75 + PI
		machine.ko()

	cam = Camera3D.new()
	cam.fov = 62.0
	cam.near = 0.1
	cam.far = 160.0
	add_child(cam)
	cam.current = true
	_update_camera(1.0, true)
	_build_ui()
	_barks = (DialogData.all().get("camminata", []) as Array).duplicate()
	Breadcrumb.mark("strada")
	if done:
		_finale()
	elif intro:
		_intro()


func _build_cctv() -> void:
	# telecamera di sorveglianza su palo: segue il giocatore (qualcuno guarda...)
	var mb := MeshBatch.new()
	mb.prism(Transform3D(Basis(), Vector3.ZERO), 0.09, 0.07, 3.9, 6, Color("#2b2638"))
	var pole := mb.make_instance("CctvPole")
	pole.position = CCTV_POS
	add_child(pole)
	_colliders.append({"c": Vector2(CCTV_POS.x, CCTV_POS.z), "r": 0.25})
	cctv_head = Node3D.new()
	cctv_head.position = CCTV_POS + Vector3(0, 3.95, 0)
	add_child(cctv_head)
	var hb := MeshBatch.new()
	hb.box(Transform3D(Basis(), Vector3(0, 0, -0.18)), Vector3(0.26, 0.24, 0.55), Color("#d9d4e6"))
	hb.box(Transform3D(Basis(), Vector3(0, 0.15, -0.2)), Vector3(0.34, 0.04, 0.65), Color("#8a83a0"))
	hb.box(Transform3D(Basis(), Vector3(0, 0, -0.465)), Vector3(0.16, 0.16, 0.02), Color("#141019"), false)
	hb.box(Transform3D(Basis(), Vector3(0.08, 0.08, -0.47)), Vector3(0.04, 0.04, 0.02), Color(1.0, 0.1, 0.2, 0.0), false)
	cctv_head.add_child(hb.make_instance("CctvHead"))


func _build_receipt() -> void:
	# lo scontrino per terra (indizio) con un bagliore che pulsa
	if clues.has("scontrino") or done:
		return
	_receipt = Node3D.new()
	_receipt.position = RECEIPT_POS
	add_child(_receipt)
	var mb := MeshBatch.new()
	mb.box(Transform3D(Basis(Vector3.UP, 0.5), Vector3(0, 0.01, 0)), Vector3(0.16, 0.012, 0.3), Color(0.97, 0.95, 0.88, 0.0))
	_receipt.add_child(mb.make_instance("Receipt"))
	var g := MeshInstance3D.new()
	g.name = "Glow"
	g.mesh = MeshBatch.disc(0.7, Color(0.25, 0.9, 1.0, 0.5), 16, 0.02)
	g.material_override = Toon.glow()
	_receipt.add_child(g)


func _build_dome() -> void:
	# cupola che sigilla la citta' (solo nell'apertura): emisfero trasparente additivo
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
			var k0: float = 0.28 - 0.2 * float(i) / float(rings)
			var k1: float = 0.28 - 0.2 * float(i + 1) / float(rings)
			var c0 := Color(1.0, 0.24, 0.55, k0)
			var c1 := Color(1.0, 0.24, 0.55, k1)
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


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	var root := Control.new()
	Ui.place(root, 0, 0, 1, 1)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	_touch = TouchControls.new()
	root.add_child(_touch)
	_touch.action_pressed.connect(_interact)
	_touch.action2_pressed.connect(_strike)
	_goal = Ui.label("", 22, Ui.CREAM, null, 6)
	_goal.position = Vector2(24, 60 if Settings.show_fps else 20)
	root.add_child(_goal)
	_goal.text = "%s · NOTTE\nObiettivo: controlla il distributore che ronza in fondo alla strada" % GameConfig.CITY
	_prompt = Ui.label("", 26, Ui.YELLOW, Ui.display(), 8)
	Ui.place(_prompt, 0.5, 0.72, 0.5, 0.72, -400, 0, 400, 50)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_prompt)
	if not TouchUi.active():
		_help = Ui.label("WASD muovi · mouse o Q/R camera · E interagisci · F attacca · Esc pausa", 18, Color(1, 1, 1, 0.6), null, 4)
		Ui.place(_help, 0, 1.0, 1.0, 1.0, 24, -36, 0, -6)
		root.add_child(_help)
	_pause_btn = Ui.button("II", Ui.CREAM, 26, 70)
	Ui.place(_pause_btn, 1.0, 0, 1.0, 0, -94, 20, -24, 84)
	_pause_btn.pressed.connect(_open_pause)
	root.add_child(_pause_btn)
	_bark_lbl = Ui.label("", 24, Ui.CREAM, null, 8)
	Ui.place(_bark_lbl, 0.5, 0.16, 0.5, 0.16, -460, 0, 460, 70)
	_bark_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bark_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bark_lbl.modulate.a = 0.0
	root.add_child(_bark_lbl)
	_dialog = DialogBox.new()
	root.add_child(_dialog)


func _main() -> Node:
	return get_parent()


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if mode != "walk" or _pause != null:
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
	if mode == "walk" and _pause == null:
		_walk(delta)
		_check_barks()
	else:
		player.move_speed = 0.0
	if _receipt != null:
		var g: Node3D = _receipt.get_node("Glow")
		var k: float = 0.75 + 0.35 * sin(Time.get_ticks_msec() * 0.005)
		g.scale = Vector3(k, 1, k)
	# la telecamera di sorveglianza segue il giocatore
	if cctv_head != null:
		var to: Vector3 = player.position + Vector3(0, 1.2, 0) - cctv_head.position
		var want: float = atan2(-to.x, -to.z)
		cctv_head.rotation.y = lerp_angle(cctv_head.rotation.y, want, minf(1.0, delta * 2.0))
		cctv_head.rotation.x = lerpf(cctv_head.rotation.x, atan2(to.y, Vector2(to.x, to.z).length()), minf(1.0, delta * 2.0))
	_update_camera(delta, false)
	_update_prompt()
	_touch.visible = mode == "walk" and _pause == null
	_pause_btn.visible = mode == "walk"
	if _help != null:
		_help.visible = mode == "walk"


func _walk(delta: float) -> void:
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
		var want: float = atan2(-dir.x, -dir.z)
		player.rotation.y = lerp_angle(player.rotation.y, want, minf(1.0, delta * 12.0))
		var p: Vector3 = player.position + dir * SPEED * amt * delta
		player.position = _collide(p)


func _collide(p: Vector3) -> Vector3:
	var q := Vector2(p.x, p.z)
	for c in _colliders:
		if c.has("c"):
			var cc: Vector2 = c["c"]
			var rr: float = float(c["r"]) + R_PLAYER
			var d: Vector2 = q - cc
			if d.length() < rr:
				q = cc + (d.normalized() if d.length() > 0.001 else Vector2.RIGHT) * rr
		else:
			var r: Rect2 = (c["rect"] as Rect2).grow(R_PLAYER)
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
	q.x = clampf(q.x, BOUNDS.position.x, BOUNDS.end.x)
	q.y = clampf(q.y, BOUNDS.position.y, BOUNDS.end.y)
	return Vector3(q.x, p.y, q.y)


func _update_camera(delta: float, snap: bool) -> void:
	var target: Vector3 = player.position + Vector3(0, 1.45, 0)
	var desired: Vector3
	var look: Vector3
	if mode == "intro":
		# campo lungo dall'alto sulla citta' sotto la cupola
		desired = Vector3(-6.0, 24.0, 26.0)
		look = Vector3(0.0, 8.0, -24.0)
	elif (mode == "dialog" or mode == "leaving") and _target != "distributore":
		desired = player.position + Vector3(-2.2, 2.0, 3.0)
		look = player.position + Vector3(0.4, 1.4, -1.0)
	elif mode == "dialog" or mode == "leaving":
		# inquadratura di dialogo: di lato, Saul a sinistra e il distributore a destra
		var mid: Vector3 = (player.position + machine.position) * 0.5 + Vector3(0, 1.4, 0)
		desired = mid + Vector3(-3.6, 0.7, 3.4)
		look = mid + Vector3(0.4, 0.1, 0)
	else:
		var back := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		desired = target + back * dist * cos(pitch) + Vector3(0, dist * sin(pitch), 0) + right * 0.55
		# non entrare nei palazzi: si accorcia verso il giocatore
		var lim: float = 6.75
		if absf(desired.x) > lim:
			var k: float = (lim - absf(target.x)) / maxf(0.01, absf(desired.x - target.x))
			desired = target + (desired - target) * clampf(k, 0.15, 1.0)
		desired.y = maxf(desired.y, 0.6)
		look = target + right * 0.55 + Vector3(0, 0.1, 0)
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


func _dist_xz(p: Vector3) -> float:
	return Vector2(player.position.x - p.x, player.position.z - p.z).length()


func _update_prompt() -> void:
	near = false
	if mode == "walk" and not done:
		if _dist_xz(MACHINE_POS) < 2.6:
			_target = "distributore"
		elif _receipt != null and _dist_xz(RECEIPT_POS) < 1.7:
			_target = "scontrino"
		elif _dist_xz(CCTV_POS) < 3.0 and not clues.has("telecamera"):
			_target = "telecamera"
		else:
			_target = ""
		near = _target != ""
	var touch: bool = TouchUi.active()
	var surprise: bool = Settings.surprise and _target == "distributore"
	match _target:
		"distributore":
			if _ambush_t > AMBUSH_TIME * 0.5 and surprise:
				_prompt.text = "IL DISTRIBUTORE TI STA FISSANDO..."
			elif surprise:
				_prompt.text = "PARLA  ·  ATTACCA" if touch else "[E] ISPEZIONA   ·   [F] ATTACCA A SORPRESA"
			else:
				_prompt.text = "ISPEZIONA IL DISTRIBUTORE" if touch else "[E]  ISPEZIONA IL DISTRIBUTORE"
		"scontrino":
			_prompt.text = "RACCOGLI LO SCONTRINO" if touch else "[E]  RACCOGLI LO SCONTRINO"
		"telecamera":
			_prompt.text = "OSSERVA LA TELECAMERA" if touch else "[E]  OSSERVA LA TELECAMERA"
		_:
			_prompt.text = ""
	if mode != "walk":
		_prompt.text = ""
	_touch.act_label = {"distributore": "PARLA", "scontrino": "PRENDI", "telecamera": "GUARDA"}.get(_target, "")
	_touch.act_live = near
	_touch.act2_label = "ATTACCA" if surprise else ""


func _check_barks() -> void:
	# battute di Saul mentre cammina: non fermano il gioco
	if not _barks.is_empty() and player.position.z < float((_barks[0] as Dictionary).get("z", 0.0)):
		var b: Dictionary = _barks.pop_front()
		_bark(str(b.get("testo", "")))
	# agguato: se resti troppo davanti al distributore senza fare niente, attacca lui
	if Settings.surprise and not done and _target == "distributore" and mode == "walk":
		_ambush_t += get_process_delta_time()
		if _ambush_t > AMBUSH_TIME:
			_ambush()
	else:
		_ambush_t = 0.0


func _bark(text: String) -> void:
	_bark_lbl.text = "SAUL:  " + text
	_bark_lbl.add_theme_color_override("font_color", Color("#9ff0bd"))
	var tw := _bark_lbl.create_tween()
	tw.tween_property(_bark_lbl, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.0)
	tw.tween_property(_bark_lbl, "modulate:a", 0.0, 0.4)


# ---------------------------------------------------------------- apertura (in medias res)

func _intro() -> void:
	Breadcrumb.mark("apertura")
	mode = "intro"
	_goal.visible = false
	_build_dome()
	_env.background_color = Color("#2a0b22")
	_update_camera(1.0, true)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	_shake = 1.2
	_main().flash(0.7)
	Settings.buzz(80)
	await get_tree().create_timer(0.7).timeout
	_dialog.play(DialogData.lines("apertura"), DialogData.recap("apertura"))
	await _dialog.finished
	if not is_inside_tree():
		return
	# cartello "TRE ORE PRIMA"
	var card := ColorRect.new()
	card.color = Color(0.02, 0.01, 0.05, 1.0)
	Ui.place(card, 0, 0, 1, 1)
	card.modulate.a = 0.0
	(_ui.get_child(0) as Control).add_child(card)
	var t1 := Ui.label("TRE ORE PRIMA", 64, Ui.CREAM, Ui.display(), 10)
	Ui.place(t1, 0, 0.4, 1, 0.4, 0, 0, 0, 80)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t1)
	var t2 := Ui.label("Saul · una consegna come tante", 26, Color("#9ff0bd"), null, 6)
	Ui.place(t2, 0, 0.52, 1, 0.52, 0, 0, 0, 40)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(t2)
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.35)
	await tw.finished
	if _dome != null:
		_dome.queue_free()
		_dome = null
	_env.background_color = Color("#120b22")
	mode = "walk"
	_update_camera(1.0, true)
	mode = "intro_wait"
	await get_tree().create_timer(1.6).timeout
	var tw2 := create_tween()
	tw2.tween_property(card, "modulate:a", 0.0, 0.4)
	await tw2.finished
	card.queue_free()
	mode = "walk"
	_goal.visible = true
	Breadcrumb.mark("strada")


# ---------------------------------------------------------------- interazioni, indizi e passaggio alla battaglia

func _face(p: Vector3) -> void:
	var to: Vector3 = p - player.position
	player.rotation.y = atan2(-to.x, -to.z)


func _interact() -> void:
	if not near or mode != "walk":
		return
	var what: String = _target
	mode = "dialog"
	_touch.release_all()
	player.move_speed = 0.0
	_goal.visible = false
	Settings.buzz(20)
	match what:
		"telecamera":
			_face(CCTV_POS)
			_dialog.play(DialogData.lines("telecamera"), DialogData.recap("telecamera"))
			await _dialog.finished
			if not clues.has("telecamera"):
				clues.append("telecamera")
			_back_to_walk()
		"scontrino":
			_face(RECEIPT_POS)
			_dialog.play(DialogData.lines("scontrino"), DialogData.recap("scontrino"))
			await _dialog.finished
			if not clues.has("scontrino"):
				clues.append("scontrino")
			if _receipt != null:
				_receipt.queue_free()
				_receipt = null
			_toast_prompt("INDIZIO TROVATO: il distributore teme il VIOLA")
			_back_to_walk()
		"distributore":
			_face(MACHINE_POS)
			_dialog.play(DialogData.lines("distributore"), DialogData.recap("distributore"))
			await _dialog.finished
			mode = "leaving"
			await machine.wake().finished
			_go_battle("normale", 1.0)


func _back_to_walk() -> void:
	if is_inside_tree():
		mode = "walk"
		_goal.visible = true
		_target = ""


func _toast_prompt(text: String) -> void:
	_bark_lbl.text = text
	_bark_lbl.add_theme_color_override("font_color", Ui.CYAN)
	var tw := _bark_lbl.create_tween()
	tw.tween_property(_bark_lbl, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.6)
	tw.tween_property(_bark_lbl, "modulate:a", 0.0, 0.4)


# Attacco a sorpresa (stile Star Rail): colpisci il distributore prima che si svegli
func _strike() -> void:
	if mode != "walk" or _target != "distributore" or not Settings.surprise:
		return
	mode = "leaving"
	_touch.release_all()
	_goal.visible = false
	_face(MACHINE_POS)
	Settings.buzz(40)
	player.attack()
	await get_tree().create_timer(0.24).timeout
	machine.hit()
	_bark_lbl.text = "ATTACCO A SORPRESA!"
	_bark_lbl.add_theme_color_override("font_color", Ui.YELLOW)
	_bark_lbl.modulate.a = 1.0
	_go_battle("vantaggio", 1.0)


# Agguato: sei rimasto troppo davanti al distributore, si sveglia lui e attacca per primo
func _ambush() -> void:
	mode = "dialog"
	_touch.release_all()
	_goal.visible = false
	_face(MACHINE_POS)
	await machine.wake().finished
	_shake = 0.8
	_dialog.play(DialogData.lines("agguato"), DialogData.recap("agguato"))
	await _dialog.finished
	mode = "leaving"
	_go_battle("agguato", 0.9)


func _go_battle(ingresso: String, shake: float) -> void:
	_shake = shake
	Settings.buzz(80)
	_main().flash(0.8)
	await get_tree().create_timer(0.4).timeout
	if is_inside_tree():
		Breadcrumb.mark("battaglia_carico")
		_main().go("battle", {"from": "street", "ingresso": ingresso, "indizi": clues})


# Rientro dopo la battaglia: la voce dalla telecamera, poi la schermata di fine
func _finale() -> void:
	mode = "dialog"
	_target = "finale"
	_goal.visible = false
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	_dialog.play(DialogData.lines("finale"), DialogData.recap("finale"))
	await _dialog.finished
	_show_end()


# ---------------------------------------------------------------- fine del test

func _show_end() -> void:
	mode = "end"
	_goal.visible = false
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Ui.box(Color(0.07, 0.04, 0.12, 0.95), Ui.CREAM, 4, 6, 8))
	Ui.place(p, 0.5, 0.5, 0.5, 0.5, -360, -190, 360, 190)
	(_ui.get_child(0) as Control).add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var t := Ui.label("FINE DEL TEST %s" % GameConfig.VERSION, 34, Ui.YELLOW, Ui.display())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var msg := Ui.label("Se sei arrivato fin qui senza crash, il 3D regge sul tuo telefono.\nDimmi com'è andata: fluidità, calore, cosa non ti torna.", 22, Ui.CREAM)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(msg)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 16)
	vb.add_child(hb)
	var again := Ui.button("RIGIOCA", Ui.YELLOW, 24, 220)
	again.pressed.connect(func() -> void: _main().go("street"))
	hb.add_child(again)
	var menu := Ui.button("MENU", Ui.CREAM, 24, 220)
	menu.pressed.connect(func() -> void: _main().go("menu"))
	hb.add_child(menu)
	Breadcrumb.mark("fine")


# ---------------------------------------------------------------- pausa

func _open_pause() -> void:
	if _pause != null:
		return
	_touch.release_all()
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.05, 0.7)
	Ui.place(shade, 0, 0, 1, 1)
	(_ui.get_child(0) as Control).add_child(shade)
	_pause = shade
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	Ui.place(vb, 0.5, 0.5, 0.5, 0.5, -200, -150, 200, 150)
	shade.add_child(vb)
	var t := Ui.label("PAUSA", 40, Ui.YELLOW, Ui.display(), 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var b1 := Ui.button("RIPRENDI", Ui.YELLOW, 26)
	b1.pressed.connect(_close_pause)
	vb.add_child(b1)
	var b2 := Ui.button("IMPOSTAZIONI", Ui.CREAM, 22)
	b2.pressed.connect(func() -> void: shade.add_child(SettingsPanel.new()))
	vb.add_child(b2)
	var b3 := Ui.button("MENU", Color("#ff7a9c"), 22)
	b3.pressed.connect(func() -> void: _main().go("menu"))
	vb.add_child(b3)


func _close_pause() -> void:
	if _pause != null:
		_pause.queue_free()
		_pause = null
