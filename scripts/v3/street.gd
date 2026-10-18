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

var player: CharacterVisual
var machine: VendingVisual
var cam: Camera3D
var cctv_head: Node3D
var yaw: float = 0.0
var pitch: float = 0.3
var dist: float = 4.8
var mode: String = "walk"          # walk | dialog | leaving | end
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


func configure(args: Dictionary) -> void:
	done = bool(args.get("done", false))
	won = bool(args.get("won", true))


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
	Breadcrumb.mark("strada")
	if done:
		_show_end()


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
	_goal = Ui.label("", 22, Ui.CREAM, null, 6)
	_goal.position = Vector2(24, 60 if Settings.show_fps else 20)
	root.add_child(_goal)
	_goal.text = "%s · NOTTE\nObiettivo: controlla il distributore che ronza in fondo alla strada" % GameConfig.CITY
	_prompt = Ui.label("", 26, Ui.YELLOW, Ui.display(), 8)
	Ui.place(_prompt, 0.5, 0.72, 0.5, 0.72, -400, 0, 400, 50)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_prompt)
	if not TouchUi.active():
		var help := Ui.label("WASD muovi · mouse o Q/R camera · E interagisci · Esc pausa", 18, Color(1, 1, 1, 0.6), null, 4)
		Ui.place(help, 0, 1.0, 1.0, 1.0, 24, -36, 0, -6)
		root.add_child(help)
	_pause_btn = Ui.button("II", Ui.CREAM, 26, 70)
	Ui.place(_pause_btn, 1.0, 0, 1.0, 0, -94, 20, -24, 84)
	_pause_btn.pressed.connect(_open_pause)
	root.add_child(_pause_btn)
	_dialog = DialogBox.new()
	root.add_child(_dialog)
	_dialog.finished.connect(_on_dialog_done)


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
	else:
		player.move_speed = 0.0
	# la telecamera di sorveglianza segue il giocatore
	if cctv_head != null:
		var to: Vector3 = player.position + Vector3(0, 1.2, 0) - cctv_head.position
		var want: float = atan2(-to.x, -to.z)
		cctv_head.rotation.y = lerp_angle(cctv_head.rotation.y, want, minf(1.0, delta * 2.0))
		cctv_head.rotation.x = lerpf(cctv_head.rotation.x, atan2(to.y, Vector2(to.x, to.z).length()), minf(1.0, delta * 2.0))
	_update_camera(delta, false)
	_update_prompt()
	_touch.visible = mode == "walk" and _pause == null


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
	if mode == "dialog" or mode == "leaving":
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


func _update_prompt() -> void:
	var d: float = Vector2(player.position.x - machine.position.x, player.position.z - machine.position.z).length()
	near = mode == "walk" and not done and d < 2.6
	if near:
		_prompt.text = "ISPEZIONA IL DISTRIBUTORE" if TouchUi.active() else "[E]  ISPEZIONA IL DISTRIBUTORE"
	else:
		_prompt.text = ""
	_touch.act_label = "GUARDA" if near else ""
	_touch.act_live = near


# ---------------------------------------------------------------- dialogo e passaggio alla battaglia

func _interact() -> void:
	if not near or mode != "walk":
		return
	mode = "dialog"
	_touch.release_all()
	player.move_speed = 0.0
	var to: Vector3 = machine.position - player.position
	player.rotation.y = atan2(-to.x, -to.z)
	_goal.visible = false
	Settings.buzz(20)
	_dialog.play(DialogData.lines("distributore"))


func _on_dialog_done() -> void:
	if mode != "dialog":
		return
	mode = "leaving"
	await machine.wake().finished
	_shake = 1.0
	Settings.buzz(80)
	if _main().has_method("flash"):
		_main().flash(0.8)
	await get_tree().create_timer(0.35).timeout
	if is_inside_tree():
		Breadcrumb.mark("battaglia_carico")
		_main().go("battle", {"from": "street"})


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
