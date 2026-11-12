extends Node3D

# PROVA GREZZA 2 · arena circolare in terza persona (decisione dell'autore del 12/11 sera: «come Qliphah, arena circolare»).
# Telecamera dietro il personaggio controllato, agganciata al nemico. Squadra da 4: due in campo, due dietro.
# TELEFONO: pollice sinistro = muoversi (levetta dove appoggi); destro = tocco (colpo), tieni (carica), scorri su (verso:
#   affondo/CONTRO), giù (indietro; in aria schiacciata), sinistra/destra (scarto laterale). Tasti: SALTO, CAMBIO, PIANO;
#   due dita = postura.
# PC: WASD muoversi · tasto sinistro colpo (tieni = carica) · tasto destro affondo/CONTRO · Maiusc schivata (con A/D di lato)
#   · Spazio salto · C schiacciata · Q postura · E cambio · F piano · Esc pausa.
# CONTROLLER: levetta sinistra · X colpo (tieni = carica) · Y affondo/CONTRO · A salto · B schivata (con la levetta di lato;
#   in aria schiacciata) · LB postura · RB cambio · Select piano · Start pausa.

const A = preload("res://scripts/prova_grezza/pg_arena.gd")
const COL: Dictionary = {"rosso": Color("#ff3d5a"), "blu": Color("#3f9dff"), "": Color("#ffd23f")}
const HEADS: Array = [Color("#fff4dc"), Color("#ffd23f"), Color("#46e07a"), Color("#b45cff")]
const WHITE := Color("#fff4dc")
const SWIPE_MIN: float = 55.0
const STICK_R: float = 90.0

var eng: PgArena
var cam: Camera3D
var _shake_t: float = 0.0
var _shake_p: float = 0.0
var _stop_id: int = 0
var _cam_pos: Vector3 = Vector3.ZERO
var _cam_look: Vector3 = Vector3.ZERO

var bodies: Array = []                   # per combattente: {root, body, fist, mat, ring}
var e_root: Node3D
var e_body: MeshInstance3D
var e_mat: StandardMaterial3D
var e_eyes: StandardMaterial3D
var _lane: MeshInstance3D
var _lane_mat: StandardMaterial3D
var _ring: MeshInstance3D
var _ring_fill: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _wall_mat: StandardMaterial3D
var _e_y: float = 0.0

var ui: CanvasLayer
var _ov: Control
var _flash: ColorRect
var _party_rows: Array = []              # {name: Label, bar: ProgressBar}
var _fiato: ProgressBar
var _ehp: ProgressBar
var _seg: ProgressBar
var _seg_lab: Label
var _reg_lab: Label
var _stamp: Label
var _sub: Label
var _toast: Label
var _hint: Label
var _btn_post: Button
var _btn_piano: Button
var _btn_cambio: Button
var _piano_panel: Control
var _piano_slots: Label
var _piano_list: Array = []
var _pause_panel: Control

var _stick_id: int = -1
var _stick_from: Vector2 = Vector2.ZERO
var _stick_v: Vector2 = Vector2.ZERO
var _act_id: int = -1
var _act_from: Vector2 = Vector2.ZERO
var _act_used: bool = false
var _two: bool = false
var _keys: Dictionary = {}
var _pad: Vector2 = Vector2.ZERO
var _mouse_down: bool = false
var _trail: Array = []
var _speed_t: float = 0.0
var _hints_done: Dictionary = {}
var paused: bool = false
var in_piano: bool = false


func configure(_args: Dictionary) -> void:
	pass


func _ready() -> void:
	eng = PgArena.new(int(Time.get_ticks_msec()) % 100000)
	eng.wide = Settings.parry_wide
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#140c26")
	env.environment = e
	add_child(env)
	_build_arena()
	_build_bodies()
	cam = Camera3D.new()
	cam.fov = 62.0
	add_child(cam)
	cam.current = true
	_update_cam(1.0)
	_build_ui()
	Sfx.music_start("battaglia")
	_show_hint("", "Muoviti attorno al nemico. Guarda la sua mira a terra" if not Ui.is_touch() else "Pollice sinistro: muoviti. Destro: tocca, tieni, scorri", 3.0)


# ================================================================ mondo

func _v3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)


func _mat(c: Color, alpha: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _mesh(mesh: Mesh, pos: Vector3, m: Material, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


func _boxm(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _build_arena() -> void:
	var floor_m := CylinderMesh.new()
	floor_m.top_radius = A.R
	floor_m.bottom_radius = A.R
	floor_m.height = 0.2
	floor_m.radial_segments = 48
	_mesh(floor_m, Vector3(0, -0.1, 0), _mat(Color("#21173a")))
	var out_m := CylinderMesh.new()
	out_m.top_radius = 30.0
	out_m.bottom_radius = 30.0
	out_m.height = 0.2
	_mesh(out_m, Vector3(0, -0.15, 0), _mat(Color("#160e2a")))
	# cerchi a terra per leggere le distanze
	for r in [3.0, 6.0]:
		var t := TorusMesh.new()
		t.inner_radius = r - 0.04
		t.outer_radius = r + 0.04
		t.rings = 48
		_mesh(t, Vector3(0, 0.01, 0), _mat(Color("#33255a")))
	# il bordo è il muro: paletti con la cima al neon
	_wall_mat = _mat(Color("#5a1d3a"))
	var post_m := _mat(Color("#2b1f4a"))
	for i in 40:
		var a: float = TAU * i / 40.0
		var p := Vector3(cos(a), 0, sin(a)) * (A.R + 0.15)
		var b := _mesh(_boxm(Vector3(1.2, 0.5, 0.3)), p + Vector3(0, 0.25, 0), post_m)
		b.rotation.y = -a + PI * 0.5
		var top := _mesh(_boxm(Vector3(1.2, 0.08, 0.32)), p + Vector3(0, 0.52, 0), _wall_mat)
		top.rotation.y = b.rotation.y
	# sagome della città attorno
	var rr := RandomNumberGenerator.new()
	rr.seed = 5
	for i in 18:
		var a2: float = TAU * i / 18.0
		var h: float = rr.randf_range(4.0, 10.0)
		var bb := _mesh(_boxm(Vector3(4.0, h, 3.0)), Vector3(cos(a2), 0, sin(a2)) * 22.0 + Vector3(0, h * 0.5, 0), _mat(Color("#1a1030")))
		bb.rotation.y = -a2
	# segni del pericolo a terra: corsia dell'AFFONDO, anello della SPAZZATA
	_lane_mat = _mat(Color(1, 0, 0, 0.3), true)
	_lane = _mesh(_boxm(Vector3(1.0, 0.02, 1.0)), Vector3.ZERO, _lane_mat)
	_lane.visible = false
	_ring_mat = _mat(Color(1, 0.8, 0.2, 0.5), true)
	var tm := TorusMesh.new()
	tm.inner_radius = A.ATTACKS["spazzata"]["radius"] - 0.3
	tm.outer_radius = A.ATTACKS["spazzata"]["radius"]
	tm.rings = 48
	_ring = _mesh(tm, Vector3(0, 0.03, 0), _ring_mat)
	_ring.visible = false
	var fill := CylinderMesh.new()
	fill.top_radius = 1.0
	fill.bottom_radius = 1.0
	fill.height = 0.02
	fill.radial_segments = 40
	_ring_fill = _mesh(fill, Vector3(0, 0.02, 0), _mat(Color(1, 0.8, 0.2, 0.22), true))
	_ring_fill.visible = false


func _build_bodies() -> void:
	for i in eng.fighters.size():
		var root := Node3D.new()
		add_child(root)
		var m := _mat(COL[eng.fighters[i].posture])
		var cm := CapsuleMesh.new()
		cm.radius = 0.36
		cm.height = 1.7
		var body := _mesh(cm, Vector3(0, 0.85, 0), m, root)
		var sm := SphereMesh.new()
		sm.radius = 0.26
		sm.height = 0.52
		_mesh(sm, Vector3(0, 0.95, 0), _mat(HEADS[i]), body)
		var fist := _mesh(_boxm(Vector3(0.26, 0.26, 0.34)), Vector3(0.25, 0.25, -0.35), _mat(WHITE), body)
		var tag := Label3D.new()
		tag.text = str(eng.fighters[i].id).to_upper()
		tag.font_size = 72
		tag.outline_size = 14
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.modulate = HEADS[i]
		tag.position = Vector3(0, 2.25, 0)
		root.add_child(tag)
		var rt := TorusMesh.new()
		rt.inner_radius = 0.55
		rt.outer_radius = 0.7
		var ring := _mesh(rt, Vector3(0, 0.04, 0), _mat(Ui.CYAN), root)
		root.position = _v3(eng.fighters[i].pos)
		bodies.append({"root": root, "body": body, "fist": fist, "mat": m, "ring": ring, "y": 0.0})
	e_root = Node3D.new()
	add_child(e_root)
	e_mat = _mat(Color("#3b2766"))
	e_body = _mesh(_boxm(Vector3(1.3, 2.3, 1.0)), Vector3(0, 1.15, 0), e_mat, e_root)
	e_eyes = _mat(Color("#ffd23f"))
	_mesh(_boxm(Vector3(0.2, 0.18, 0.1)), Vector3(-0.25, 0.6, -0.52), e_eyes, e_body)
	_mesh(_boxm(Vector3(0.2, 0.18, 0.1)), Vector3(0.25, 0.6, -0.52), e_eyes, e_body)


# ================================================================ interfaccia

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	_ov = Control.new()
	_ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ov.draw.connect(_draw_overlay)
	ui.add_child(_ov)
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	ui.add_child(_flash)
	# la squadra, in alto a sinistra
	var lt := VBoxContainer.new()
	lt.add_theme_constant_override("separation", 2)
	lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(lt, 0, 0, 0, 0, 20, 12, 380, 230)
	ui.add_child(lt)
	for i in eng.fighters.size():
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lt.add_child(row)
		var n := Ui.label("", 18, HEADS[i], Ui.display(), 5)
		n.custom_minimum_size.x = 170
		row.add_child(n)
		var b := _bar(Color("#46e07a"), 14, eng.fighters[i].maxhp)
		b.custom_minimum_size.x = 170
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		_party_rows.append({"name": n, "bar": b, "row": row})
	var fr := HBoxContainer.new()
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lt.add_child(fr)
	var fl := Ui.label("FIATO", 18, Ui.CYAN, Ui.display(), 5)
	fl.custom_minimum_size.x = 170
	fr.add_child(fl)
	_fiato = _bar(Ui.CYAN, 14, A.FIATO_MAX)
	_fiato.custom_minimum_size.x = 170
	_fiato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fr.add_child(_fiato)
	# il nemico, in alto a destra
	var rt := VBoxContainer.new()
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(rt, 1, 0, 1, 0, -460, 12, -20, 140)
	ui.add_child(rt)
	var en := Ui.label("DISTURBO", 24, Ui.PINK, Ui.display(), 6)
	en.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rt.add_child(en)
	_ehp = _bar(Ui.PINK, 16, A.ENEMY_HP)
	rt.add_child(_ehp)
	_seg_lab = Ui.label("SEGNALE", 18, Ui.YELLOW, Ui.display(), 5)
	_seg_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rt.add_child(_seg_lab)
	_seg = _bar(Ui.YELLOW, 24, A.SEG_MAX)
	rt.add_child(_seg)
	_reg_lab = Ui.label("", 20, WHITE, Ui.display(), 5)
	_reg_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_reg_lab, 0.5, 0, 0.5, 0, -160, 14, 160, 44)
	ui.add_child(_reg_lab)
	_toast = _center_label(26, Ui.YELLOW, 0.0, 120.0)
	_stamp = _center_label(72, WHITE, 0.5, -210.0)
	_stamp.pivot_offset = Vector2(500, 50)
	_sub = _center_label(30, WHITE, 0.5, -120.0)
	_hint = _center_label(28, WHITE, 1.0, -190.0)
	# tasti
	_btn_post = _btn("ROSSO", COL["rosso"], 1, 1, -560, -90, -400, -24, func() -> void: eng.input("postura"))
	_btn_piano = _btn("PIANO", Ui.CYAN, 1, 1, -380, -90, -220, -24, _open_piano)
	_btn_cambio = _btn("CAMBIO", Ui.YELLOW, 1, 1, -200, -180, -24, -110, func() -> void: eng.input("cambio"))
	_btn("SALTO", WHITE, 1, 1, -200, -96, -24, -24, func() -> void: _salto())
	_btn("II", WHITE, 0.5, 0, -32, 50, 32, 96, _toggle_pause)


func _center_label(size: int, c: Color, anchor_y: float, oy: float) -> Label:
	var l := Ui.label("", size, c, Ui.display(), 8 if size < 60 else 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(l, 0.5, anchor_y, 0.5, anchor_y, -560, oy, 560, oy + size + 16)
	l.modulate.a = 0.0
	ui.add_child(l)
	return l


func _btn(t: String, c: Color, ax: float, ay: float, l: float, tp: float, r: float, b: float, cb: Callable) -> Button:
	var bt := Ui.button(t, c, 22, r - l)
	Ui.place(bt, ax, ay, ax, ay, l, tp, r, b)
	bt.focus_mode = Control.FOCUS_NONE
	bt.pressed.connect(cb)
	ui.add_child(bt)
	return bt


func _bar(c: Color, h: int, mx: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = mx
	b.value = mx
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#120a1c")
	bg.border_color = WHITE
	bg.set_border_width_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = c
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


# ================================================================ ciclo

func _process(delta: float) -> void:
	var rd: float = delta / maxf(0.01, Engine.time_scale)
	_apply_move()
	if not paused and not in_piano and eng.over == "":
		eng.step(delta)
		for ev in eng.take_events():
			_on_event(ev)
	_tutor()
	_sync(delta)
	_update_cam(minf(1.0, rd * 6.0))
	_refresh()
	if _shake_t > 0.0:
		_shake_t -= rd
		var p: float = _shake_p * maxf(0.0, _shake_t)
		cam.position += Vector3(randf_range(-p, p), randf_range(-p, p), randf_range(-p, p))
	for t in _trail:
		t[2] -= rd
	_trail = _trail.filter(func(t: Array) -> bool: return t[2] > 0.0)
	_speed_t = maxf(0.0, _speed_t - rd)
	_ov.queue_redraw()


func _apply_move() -> void:
	var v: Vector2 = Vector2.ZERO
	if _keys.get(KEY_W, false):
		v.y += 1.0
	if _keys.get(KEY_S, false):
		v.y -= 1.0
	if _keys.get(KEY_A, false):
		v.x -= 1.0
	if _keys.get(KEY_D, false):
		v.x += 1.0
	if _stick_id >= 0:
		v = Vector2(_stick_v.x, -_stick_v.y)
	if _pad.length() > 0.2:
		v = Vector2(_pad.x, -_pad.y)
	eng.set_move(v)


func _update_cam(k: float) -> void:
	var f: PgArena.Fighter = eng.me()
	var fp: Vector3 = bodies[f.idx]["root"].position
	var ep: Vector3 = _v3(eng.epos)
	var fw: Vector3 = (ep - fp)
	fw.y = 0.0
	fw = fw.normalized() if fw.length() > 0.01 else Vector3(0, 0, -1)
	var right: Vector3 = fw.cross(Vector3.UP)
	var want: Vector3 = Vector3(fp.x, 0, fp.z) - fw * 6.4 + Vector3(0, 3.9, 0) + right * 1.7
	var look: Vector3 = ep.lerp(fp, 0.2) + Vector3(0, 1.0, 0) + right * 0.6
	if _cam_pos == Vector3.ZERO:
		_cam_pos = want
		_cam_look = look
	_cam_pos = _cam_pos.lerp(want, k)
	_cam_look = _cam_look.lerp(look, k)
	cam.position = _cam_pos
	cam.look_at(_cam_look)


func _sync(delta: float) -> void:
	var k: float = minf(1.0, delta * 22.0)
	for f in eng.fighters:
		var b: Dictionary = bodies[f.idx]
		var root: Node3D = b["root"]
		var py: float = 0.0
		if f.p_air > 0.0:
			py = 1.8 if (eng.est == "air" or f.st == "hover") else 1.1
		b["y"] = lerpf(float(b["y"]), py, minf(1.0, delta * 14.0))
		root.position = root.position.lerp(_v3(f.pos, float(b["y"])), k)
		root.visible = f.st != "ko"
		var to_e: Vector3 = _v3(eng.epos) - root.position
		root.rotation.y = lerp_angle(root.rotation.y, atan2(-to_e.x, -to_e.z), minf(1.0, delta * 16.0))
		var body: MeshInstance3D = b["body"]
		var lean: float = 0.0
		var fist_z: float = -0.35
		var sc: float = 1.0
		match f.st:
			"atk":
				var fr: float = clampf(f.st_t / maxf(0.01, float(f.move.get("hit", 0.1)) + 0.05), 0.0, 1.0)
				lean = -0.35 * fr
				fist_z = -0.35 - 0.6 * fr
				if f.move.get("id", "") in ["schiacciata", "schianto"]:
					lean = -0.8
				if f.move.get("id", "") == "montante":
					lean = 0.3
			"charge":
				lean = 0.25
				sc = 0.85 + 0.05 * sin(Time.get_ticks_msec() * 0.04)
			"hover":
				lean = -0.2
			"dodge":
				lean = 0.35
				sc = 0.8
			"hurt":
				lean = 0.6
				sc = 0.85
		body.rotation.x = lerp_angle(body.rotation.x, -lean, minf(1.0, delta * 20.0))
		body.scale.y = lerpf(body.scale.y, sc, minf(1.0, delta * 18.0))
		var fist: MeshInstance3D = b["fist"]
		fist.position.z = lerpf(fist.position.z, fist_z, minf(1.0, delta * 30.0))
		var c: Color = COL[f.posture]
		if eng.can_cancel_now(f):
			c = c.lerp(Color.WHITE, 0.75)
		if f.st == "charge" or f.st == "hover":
			c = c.lerp(Color.WHITE, 0.25 * eng.charge_level(f))
		var m: StandardMaterial3D = b["mat"]
		m.albedo_color = m.albedo_color.lerp(c, minf(1.0, delta * 30.0))
		(b["ring"] as Node3D).visible = f.idx == eng.active
	# nemico
	var ey: float = 1.9 if eng.est == "air" else 0.0
	_e_y = lerpf(_e_y, ey, minf(1.0, delta * 12.0))
	e_root.position = e_root.position.lerp(_v3(eng.epos, _e_y), k)
	e_root.rotation.y = lerp_angle(e_root.rotation.y, atan2(-eng.efacing.x, -eng.efacing.y), minf(1.0, delta * 14.0))
	var e_lean: float = 0.0
	var e_sc: float = 1.0
	var e_col := Color("#3b2766")
	var d: Dictionary = eng.danger()
	_lane.visible = false
	_ring.visible = false
	_ring_fill.visible = false
	if not d.is_empty():
		var left: float = float(d["left"])
		var f2: float = clampf(1.0 - left / maxf(0.1, float(d["impact"])), 0.0, 1.0)
		var on_me: bool = int(d["target"]) == eng.active
		var in_win: bool = left <= eng.win_len()
		if d["kind"] == "affondo":
			e_lean = 0.35 * f2
			var ac: Color = COL[d["color"]]
			e_col = e_col.lerp(ac, 0.25 + 0.6 * f2)
			var dir: Vector2 = d["dir"]
			var ln: float = float(A.ATTACKS["affondo"]["len"]) + A.BODY
			_lane.visible = true
			_lane.scale = Vector3(float(A.ATTACKS["affondo"]["width"]) * 2.0, 1.0, ln)
			_lane.position = _v3(eng.epos + dir * ln * 0.5, 0.03)
			_lane.rotation.y = atan2(dir.x, dir.y)
			_lane_mat.albedo_color = Color(Color.WHITE if (in_win and on_me) else ac, 0.25 + 0.35 * f2)
		else:
			e_sc = 1.0 - 0.35 * f2
			e_col = e_col.lerp(COL[""], 0.2 + 0.5 * f2)
			_ring.visible = true
			_ring_fill.visible = true
			_ring.position = _v3(eng.epos, 0.03)
			_ring_fill.position = _v3(eng.epos, 0.02)
			var rr: float = float(A.ATTACKS["spazzata"]["radius"])
			_ring_fill.scale = Vector3(rr * f2, 1.0, rr * f2)
			_ring_mat.albedo_color = Color(Color.WHITE if in_win else COL[""], 0.5 + 0.4 * f2)
	match eng.est:
		"stun":
			e_lean = -0.3
		"crollo":
			e_lean = -0.5
			e_sc = 0.8
			e_col = Color("#6b6b80")
		"down":
			e_lean = -1.3
		"air":
			e_lean = -0.9 + sin(Time.get_ticks_msec() * 0.02) * 0.2
	e_body.rotation.x = lerp_angle(e_body.rotation.x, e_lean, minf(1.0, delta * 16.0))
	e_body.scale.y = lerpf(e_body.scale.y, e_sc, minf(1.0, delta * 16.0))
	e_mat.albedo_color = e_mat.albedo_color.lerp(e_col, minf(1.0, delta * 20.0))
	e_eyes.albedo_color = Color("#9a9aa8") if eng.est == "crollo" else (COL[d["color"]] if not d.is_empty() and d["kind"] == "affondo" else Color("#ffd23f"))


func _refresh() -> void:
	for i in eng.fighters.size():
		var f: PgArena.Fighter = eng.fighters[i]
		var row: Dictionary = _party_rows[i]
		var where: String = "KO" if f.st == "ko" else ("▶ " if i == eng.active else ("  " if f.front else "· "))
		(row["name"] as Label).text = (where + f.name.replace("MANICHINO ", "MAN. ")) if f.st != "ko" else ("KO " + f.name.replace("MANICHINO ", "MAN. "))
		(row["bar"] as ProgressBar).value = f.hp
		(row["row"] as Control).modulate.a = 1.0 if f.front and f.st != "ko" else 0.5
	_fiato.value = eng.fiato
	_ehp.value = eng.ehp
	_seg.value = eng.seg
	_seg_lab.text = "CROLLO!" if eng.est == "crollo" else "SEGNALE"
	_reg_lab.text = "REGISTRO %d/%d" % [eng.found.size(), A.DISCOVERIES.size()]
	_btn_post.text = eng.me().posture.to_upper()
	_btn_post.add_theme_stylebox_override("normal", Ui.box(COL[eng.me().posture]))
	_btn_piano.disabled = eng.fiato < A.PIANO_COST or eng.over != ""
	_btn_cambio.disabled = eng.partner() == null or eng.time < eng.swap_ready


# ================================================================ disegno sopra la scena

func _draw_overlay() -> void:
	var d: Dictionary = eng.danger()
	if not d.is_empty():
		var left: float = float(d["left"])
		var in_win: bool = left <= eng.win_len()
		var head3: Vector3 = e_root.position + Vector3(0, 3.0, 0)
		if not cam.is_position_behind(head3):
			var head: Vector2 = cam.unproject_position(head3)
			var c: Color = COL[d["color"]] if d["kind"] == "affondo" else COL[""]
			var r: float = 30.0 + 60.0 * clampf(left / maxf(0.1, float(d["impact"])), 0.0, 1.0)
			_ov.draw_arc(head, 30.0, 0, TAU, 40, Color(WHITE, 0.5), 3.0)
			_ov.draw_arc(head, r, 0, TAU, 48, Color.WHITE if in_win else c, 9.0 if in_win else 5.0)
			if d["kind"] == "affondo":
				var pts := PackedVector2Array([head + Vector2(0, 24), head + Vector2(-20, -2), head + Vector2(-8, -2), head + Vector2(-8, -24),
					head + Vector2(8, -24), head + Vector2(8, -2), head + Vector2(20, -2)])
				_ov.draw_colored_polygon(pts, c)
			else:
				var wave := PackedVector2Array()
				for i in 13:
					wave.append(head + Vector2(-24.0 + i * 4.0, sin(i * 0.9) * 8.0))
				_ov.draw_polyline(wave, c, 6.0)
		# chi è il bersaglio
		var tp3: Vector3 = bodies[int(d["target"])]["root"].position + Vector3(0, 2.7, 0)
		if not cam.is_position_behind(tp3):
			var tp: Vector2 = cam.unproject_position(tp3)
			_ov.draw_string(Ui.display(), tp + Vector2(-12, 0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color("#ff4b4b"))
	var me: PgArena.Fighter = eng.me()
	var mp3: Vector3 = bodies[me.idx]["root"].position + Vector3(0, 0.9, 0)
	if not cam.is_position_behind(mp3):
		var mp: Vector2 = cam.unproject_position(mp3)
		if eng.can_cancel_now():
			_ov.draw_arc(mp, 64.0, 0, TAU, 40, Color(1, 1, 1, 0.9), 6.0)
		if me.st == "charge" or me.st == "hover":
			# tre tacche della carica
			var lv: int = eng.charge_level()
			for i in 3:
				var a0: float = -PI * 0.5 + i * TAU / 3.0 + 0.08
				_ov.draw_arc(mp, 80.0, a0, a0 + TAU / 3.0 - 0.16, 16, Ui.YELLOW if i < lv else Color(1, 1, 1, 0.25), 10.0)
		if _speed_t > 0.0:
			for i in 6:
				var yy: float = -60.0 + i * 24.0
				_ov.draw_line(mp + Vector2(yy, 60), mp + Vector2(yy * 1.6, 220), Color(1, 1, 1, _speed_t * 4.0), 4.0)
	if eng.est == "crollo":
		var cp3: Vector3 = e_root.position + Vector3(0, 1.2, 0)
		if not cam.is_position_behind(cp3):
			_ov.draw_arc(cam.unproject_position(cp3), 110.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(eng.est_t / A.CROLLO_TIME, 0.0, 1.0), 64, Ui.YELLOW, 10.0)
	# levetta del pollice sinistro
	if _stick_id >= 0:
		_ov.draw_arc(_stick_from, STICK_R, 0, TAU, 40, Color(1, 1, 1, 0.35), 4.0)
		_ov.draw_circle(_stick_from + _stick_v * STICK_R, 34.0, Color(1, 1, 1, 0.45))
	for t in _trail:
		_ov.draw_line(t[0], t[1], Color(1, 1, 1, clampf(t[2] * 4.0, 0.0, 0.8)), 12.0)
		_ov.draw_circle(t[1], 12.0, Color(1, 1, 1, clampf(t[2] * 4.0, 0.0, 0.8)))


# ================================================================ eventi → sensazione

func _ename(i: int) -> String:
	return str(eng.fighters[i].id).to_upper()


func _on_event(ev: Dictionary) -> void:
	match ev["type"]:
		"mossa":
			match ev["id"]:
				"affondo", "scatto", "entrata":
					if int(ev["who"]) == eng.active:
						_speed_t = 0.18
					Sfx.play("schivata", 0.0, 1.2)
				"colpo", "aria", "fianco":
					Sfx.play("schivata", 0.0, 1.6 + 0.1 * int(ev["chain"]), -8.0)
				"blackout":
					_flash_now(Color.BLACK, 0.95)
					_slowmo(0.25, 0.35)
		"colpito_nemico":
			var src: String = ev["src"]
			var mine: bool = int(ev["who"]) == eng.active
			var big: bool = src in ["affondo", "schiacciata", "schianto", "montante", "scatto", "entrata"] or float(ev["dmg"]) >= 20.0
			_sparks(e_root.position + Vector3(0, 1.3, 0), COL[eng.fighters[int(ev["who"])].posture], 26 if big else (12 if mine else 6))
			_number(int(ev["dmg"]), big, mine)
			_knock()
			if ev["armor"] and mine:
				Sfx.play("scudo", 0.0, 1.0, -4.0)
				_sub_text("INCASSA: SOLO IL CONTRO LO FERMA", Ui.CREAM)
			else:
				Sfx.play("colpo_forte" if big else "colpo", 0.0, randf_range(0.95, 1.1), 0.0 if mine else -8.0)
			if mine:
				_hitstop(0.08 if big else 0.045)
				_shake(0.12 if big else 0.06, 0.1 if big else 0.04)
		"contro":
			var c: Color = COL[ev["color"]]
			var lv: int = int(ev["lv"])
			_hitstop(0.14 + 0.04 * lv + (0.04 if ev["freq"] else 0.0))
			_flash_now(c if ev["freq"] else Color.WHITE, 0.55)
			_shake(0.25 + 0.1 * lv, 0.2 + 0.08 * lv)
			_punch(48.0 - 4.0 * lv)
			_sparks(e_root.position + Vector3(0, 1.3, 0), c, 50 + 20 * lv)
			Sfx.play("critico")
			Sfx.word("BAM", true)
			_stamp_text(("CONTRO CARICATO!" if lv > 0 else ("FREQUENZA!" if ev["freq"] else "CONTRO!")), c if ev["freq"] else Ui.CYAN)
			if ev["perfect"]:
				_sub_text("PERFETTO" + ("  ·  FREQUENZA" if ev["freq"] and lv > 0 else ""), Ui.YELLOW)
		"un_altro":
			_sub_text("UN ALTRO! è fermo", Ui.YELLOW)
			_slowmo(0.35, 0.4)
		"troppo_presto":
			_sub_text("TROPPO PRESTO", Color("#ff7a9c"))
		"carica":
			Sfx.play("ui_sposta", 0.0, 0.6, 2.0)
		"carica_annullata":
			_sub_text("CARICA ANNULLATA", WHITE)
		"sospeso":
			_sub_text("SOSPESO: RILASCIA PER SCHIACCIARE", WHITE)
		"colpito":
			var me_hit: bool = int(ev["who"]) == eng.active
			Sfx.play("ferita", 0.0, 1.0, 0.0 if me_hit else -6.0)
			if me_hit:
				_flash_now(Color("#ff2a2a"), 0.45)
				_shake(0.3, 0.3)
				_hitstop(0.09)
				_stamp_text("DOPPIO!" if ev["doppio"] else ("A TERRA" if ev["kind"] == "spazzata" else "AHI"), Color("#ff4b4b"))
			else:
				_sub_text("%s COLPITO" % _ename(int(ev["who"])), Color("#ff7a9c"))
		"schivata":
			if int(ev["who"]) == eng.active:
				Sfx.play("schivata")
				_sub_text("SCHIVATA PERFETTA  +FIATO" if ev["perfect"] else "SCHIVATA", Ui.CYAN)
				if ev["perfect"]:
					_slowmo(0.3, 0.3)
		"saltata":
			if int(ev["who"]) == eng.active:
				_stamp_text("SALTATA!", Ui.YELLOW)
				_sub_text("ORA COLPISCI IN ARIA", WHITE)
				_slowmo(0.35, 0.3)
		"castigo":
			_sub_text("CASTIGO x1,5", Ui.YELLOW)
		"alle_spalle":
			if int(ev["who"]) == eng.active:
				_sub_text("ALLE SPALLE", Ui.CYAN)
		"nemico_a_vuoto":
			_sub_text("A VUOTO: PUNISCILO", Ui.CYAN)
		"muro":
			_stamp_text("AL MURO!", Ui.PINK)
			_shake(0.3, 0.35)
			_hitstop(0.12)
			Sfx.play("break", 0.0, 1.2, -4.0)
			_wall_mat.albedo_color = Color("#ff3d8b")
			create_tween().tween_property(_wall_mat, "albedo_color", Color("#5a1d3a"), 0.8)
		"lancio":
			_sub_text("IN ARIA: TOCCA!", WHITE)
		"schiacciata":
			_stamp_text("SCHIACCIATA!", Ui.YELLOW)
			_shake(0.3 + 0.1 * int(ev["lv"]), 0.35)
			_hitstop(0.12)
		"annullo":
			_flash_now(Color.WHITE, 0.25)
			Sfx.play("ui_ok", 0.0, 1.5)
		"respiro":
			_sub_text("RESPIRO +FIATO", Ui.CYAN)
			Sfx.play("cura", 0.0, 1.2, -6.0)
		"postura":
			if int(ev["who"]) == eng.active:
				_flash_now(COL[ev["posture"]], 0.25)
				Sfx.play("ui_sposta", 0.0, 0.8 if ev["posture"] == "rosso" else 1.3, 4.0)
		"cambio":
			_flash_now(Color.WHITE, 0.3)
			Sfx.play("cutin", 0.0, 1.2, -4.0)
			_stamp_text("STAFFETTA!" if ev["staffetta"] else "CAMBIO", Ui.YELLOW if ev["staffetta"] else WHITE)
		"copertura":
			_stamp_text("COPERTURA!", Ui.CYAN)
			_sub_text("%s si mette in mezzo" % _ename(int(ev["who"])), WHITE)
			Sfx.play("scudo")
			_slowmo(0.3, 0.35)
		"ko":
			_stamp_text("%s KO" % _ename(int(ev["who"])), Color("#ff4b4b"))
		"entra":
			_sub_text("ENTRA %s" % _ename(int(ev["who"])), Ui.CYAN)
		"fila":
			_sub_text("ENTRA %s, ESCE %s" % [_ename(int(ev["in"])), _ename(int(ev["out"]))], Ui.CYAN)
		"crollo":
			_stamp_text("CROLLO", Ui.YELLOW)
			_sub_text("VERSO DI LUI: BLACKOUT", WHITE)
			_hitstop(0.2)
			Sfx.play("break")
		"blackout":
			_flash_now(Color.WHITE, 1.0)
			_shake(0.5, 0.5)
			_punch(40.0)
			_sparks(e_root.position + Vector3(0, 1.2, 0), Color.WHITE, 90)
			_stamp_text("BLACKOUT", WHITE)
			if int(ev["team"]) > 0:
				_sub_text("TUTTA LA SQUADRA DENTRO", Ui.CYAN)
			_number(int(ev["dmg"]), true, true)
			Sfx.play("colpo_finale")
		"crollo_finito":
			_sub_text("SI È RIPRESO", Color("#ff7a9c"))
		"scrollata":
			_sub_text("SI SCROLLA DI DOSSO", Color("#ff7a9c"))
			_shake(0.15, 0.15)
		"scoperta":
			_toast_text("NUOVO NEL REGISTRO: %s  (%d/%d)" % [ev["label"], ev["n"], ev["of"]])
			Sfx.play("combo", 0.0, 1.0 + 0.04 * int(ev["n"]))
		"piano_via":
			_sub_text("IN ONDA", Ui.CYAN)
		"piano_fine":
			if ev["why"] == "mani":
				_sub_text("PIANO INTERROTTO", Color("#ff7a9c"))
		"vittoria":
			Sfx.play("vittoria")
			_end(true)
		"sconfitta":
			Sfx.play("sconfitta")
			_end(false)


func _tutor() -> void:
	if eng.over != "" or paused or in_piano:
		return
	var touch: bool = Ui.is_touch()
	var d: Dictionary = eng.danger()
	if not d.is_empty() and int(d["target"]) == eng.active and float(d["left"]) <= eng.win_len() + 0.05:
		if d["kind"] == "affondo" and not _hints_done.has("affondo"):
			_hints_done["affondo"] = true
			_show_hint("", ("Scorri IN SU, verso di lui: CONTRO" if touch else "Tasto DESTRO quando la linea è bianca: CONTRO") + " · oppure scarta di lato", 3.0)
			_slowmo(0.22, 0.5)
		elif d["kind"] == "spazzata" and not _hints_done.has("spazzata"):
			_hints_done["spazzata"] = true
			_show_hint("", "SALTO sopra l'anello, o esci dal cerchio", 3.0)
			_slowmo(0.22, 0.5)
	if eng.found.has("contro") and not _hints_done.has("carica"):
		_hints_done["carica"] = true
		_show_hint("", ("Tieni premuto: carichi. Rilascia sull'AFFONDO: CONTRO CARICATO" if touch else "Tieni il tasto sinistro: carichi. Rilascia sull'AFFONDO: CONTRO CARICATO"), 3.5)
	if eng.found.size() >= 4 and not _hints_done.has("pausa"):
		_hints_done["pausa"] = true
		_show_hint("", "Colpo, colpo, PAUSA, colpo: MONTANTE", 3.0)
	if eng.time > 25.0 and not _hints_done.has("cambio"):
		_hints_done["cambio"] = true
		_show_hint("", "CAMBIO nel lampo bianco: STAFFETTA. Alle sue spalle il SEGNALE scende di più", 3.5)
	if eng.est == "crollo" and not _hints_done.has("crollo"):
		_hints_done["crollo"] = true
		_show_hint("", "CROLLO: verso di lui per il BLACKOUT di squadra", 3.0)


func _show_hint(_key: String, text: String, hold: float) -> void:
	_hint.text = text
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_hint, "modulate:a", 1.0, 0.15)
	tw.tween_interval(hold)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.4)


# ---------------------------------------------------------------- effetti

func _stamp_text(t: String, c: Color) -> void:
	_stamp.text = t
	_stamp.add_theme_color_override("font_color", c)
	_stamp.modulate.a = 1.0
	_stamp.scale = Vector2(1.5, 1.5)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_stamp, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_property(_stamp, "modulate:a", 0.0, 0.25)


func _sub_text(t: String, c: Color) -> void:
	_sub.text = t
	_sub.add_theme_color_override("font_color", c)
	_sub.modulate.a = 1.0
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.7)
	tw.tween_property(_sub, "modulate:a", 0.0, 0.3)


func _toast_text(t: String) -> void:
	_toast.text = t
	_toast.modulate.a = 1.0
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(1.8)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _hitstop(dur: float) -> void:
	_stop_id += 1
	var my: int = _stop_id
	Engine.time_scale = 0.03
	await get_tree().create_timer(dur, true, false, true).timeout
	if my == _stop_id:
		Engine.time_scale = 1.0


func _slowmo(sc: float, dur: float) -> void:
	_stop_id += 1
	var my: int = _stop_id
	Engine.time_scale = sc
	await get_tree().create_timer(dur, true, false, true).timeout
	if my == _stop_id:
		Engine.time_scale = 1.0


func _flash_now(c: Color, a: float) -> void:
	_flash.color = Color(c, a)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_flash, "color:a", 0.0, 0.25)


func _shake(dur: float, power: float) -> void:
	_shake_t = dur
	_shake_p = power / maxf(0.01, dur)


func _punch(fov: float) -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(cam, "fov", fov, 0.06)
	tw.tween_property(cam, "fov", 62.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _knock() -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(e_body, "position:y", 1.3, 0.03)
	tw.tween_property(e_body, "position:y", 1.15, 0.15)


func _sparks(pos: Vector3, c: Color, n: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = n
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector3(0, 0.6, 0)
	p.spread = 90.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 11.0
	p.gravity = Vector3(0, -14, 0)
	var qm := BoxMesh.new()
	qm.size = Vector3(0.12, 0.12, 0.12)
	p.mesh = qm
	p.material_override = _mat(c)
	p.position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.8, true, false, true).timeout.connect(p.queue_free)


func _number(n: int, big: bool, mine: bool) -> void:
	var p3: Vector3 = e_root.position + Vector3(randf_range(-0.6, 0.6), 2.6, 0)
	if cam.is_position_behind(p3):
		return
	var l := Ui.label(str(n), 46 if big else (32 if mine else 24), (WHITE if big else Ui.YELLOW) if mine else Color("#c9bde6"), Ui.display(), 8)
	var p: Vector2 = cam.unproject_position(p3)
	l.position = p - Vector2(30, 20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(l)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(l, "position:y", p.y - 100.0, 0.6).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.tween_callback(l.queue_free)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# ================================================================ PIANO

func _open_piano() -> void:
	if eng.fiato < A.PIANO_COST or eng.over != "" or in_piano:
		return
	in_piano = true
	Engine.time_scale = 1.0
	_piano_list = []
	_piano_panel = Control.new()
	_piano_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_piano_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.1, 0.2, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_piano_panel.add_child(dim)
	var tl := _plabel("PIANO · MOVIOLA  %05.2f" % eng.time, 34, Ui.CYAN, 110)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plabel(_preview_text(), 24, WHITE, 160)
	_piano_slots = _plabel("", 30, Ui.YELLOW, 215)
	var acts: Array = [["tocco", "COLPO"], ["carica", "CARICA"], ["verso", "AFFONDO"], ["salto", "SALTO"], ["giu", "GIÙ"],
		["sx", "← SCARTO"], ["dx", "SCARTO →"], ["via", "INDIETRO"], ["postura", "POSTURA"], ["cambio", "CAMBIO"], ["fila", "FILA"]]
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	Ui.place(grid, 0.5, 0.5, 0.5, 0.5, -560, -60, 560, 100)
	_piano_panel.add_child(grid)
	for a in acts:
		var b := Ui.button(a[1], WHITE, 20, 170)
		b.focus_mode = Control.FOCUS_NONE
		var g: String = a[0]
		b.pressed.connect(func() -> void: _piano_add(g))
		grid.add_child(b)
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 24)
	Ui.place(row2, 0, 1, 1, 1, 20, -120, -20, -40)
	_piano_panel.add_child(row2)
	var ok := Ui.button("VIA! (-%d FIATO)" % int(A.PIANO_COST), Ui.CYAN, 26, 300)
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(_piano_go)
	row2.add_child(ok)
	var no := Ui.button("ANNULLA", Ui.PINK, 26, 200)
	no.focus_mode = Control.FOCUS_NONE
	no.pressed.connect(_piano_close)
	row2.add_child(no)
	_piano_refresh()


func _plabel(t: String, size: int, c: Color, y: float) -> Label:
	var l := Ui.label(t, size, c, Ui.display(), 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(l, 0.5, 0, 0.5, 0, -600, y, 600, y + size + 14)
	_piano_panel.add_child(l)
	return l


func _preview_text() -> String:
	var p: Dictionary = eng.preview()
	var s: String = ""
	if p.has("kind"):
		var c: String = (" " + str(p["color"]).to_upper()) if p["color"] != "" else ""
		s = "In arrivo: %s%s su %s fra %.1f s" % [str(p["kind"]).to_upper(), c, p["target"], float(p["left"])]
	else:
		s = "Il nemico è %s" % {"idle": "fermo", "stun": "stordito", "rec": "scoperto", "air": "in aria", "down": "a terra", "crollo": "in CROLLO"}.get(p["enemy"], p["enemy"])
	return s + " · distanza %.1f%s" % [float(p["dist"]), " · SEI ALLE SUE SPALLE" if p["behind"] else ""]


func _piano_add(g: String) -> void:
	if _piano_list.size() < 3:
		_piano_list.append(g)
	_piano_refresh()


func _piano_refresh() -> void:
	var names: Dictionary = {"tocco": "COLPO", "carica": "CARICA", "verso": "AFFONDO", "salto": "SALTO", "giu": "GIÙ", "sx": "← SCARTO",
		"dx": "SCARTO →", "via": "INDIETRO", "postura": "POSTURA", "cambio": "CAMBIO", "fila": "FILA"}
	var s: Array = []
	for i in 3:
		s.append(names[_piano_list[i]] if i < _piano_list.size() else "___")
	_piano_slots.text = "  ›  ".join(s)


func _piano_go() -> void:
	if not _piano_list.is_empty():
		eng.start_plan(_piano_list)
	_piano_close()


func _piano_close() -> void:
	in_piano = false
	if _piano_panel:
		_piano_panel.queue_free()
		_piano_panel = null


# ================================================================ pausa e fine

func _toggle_pause() -> void:
	if eng.over != "" or in_piano:
		return
	paused = not paused
	if not paused:
		if _pause_panel:
			_pause_panel.queue_free()
		return
	Engine.time_scale = 1.0
	_pause_panel = _registro_panel("PAUSA", false)


func _registro_panel(title: String, ended: bool) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Ui.box(Color("#1a1030"), WHITE, 4, 10, 8))
	Ui.place(pc, 0.5, 0.5, 0.5, 0.5, -460, -320, 460, 320)
	ui.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var t := Ui.label(title, 40, Ui.YELLOW, Ui.display(), 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if ended:
		var s := Ui.label("Tempo %d s · Registro %d/%d" % [int(eng.time), eng.found.size(), A.DISCOVERIES.size()], 22, WHITE, Ui.display(), 5)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	v.add_child(grid)
	for d in A.DISCOVERIES:
		var got: bool = eng.found.has(d[0])
		grid.add_child(Ui.label(("✓ " + d[1]) if got else "???", 18, Ui.CYAN if got else Color("#7d7397"), Ui.display(), 4))
	var pas := Ui.label("Dietro: " + ", ".join(eng.fighters.filter(func(f: PgArena.Fighter) -> bool: return not f.front and f.st != "ko").map(
		func(f: PgArena.Fighter) -> String: return "%s (%s)" % [f.id.to_upper(), A.PASSIVE_TEXT[f.passive]])), 18, WHITE, Ui.display(), 4)
	pas.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(pas)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	if not ended:
		var go := Ui.button("RIPRENDI", Ui.CYAN, 22, 190)
		go.pressed.connect(_toggle_pause)
		row.add_child(go)
	var again := Ui.button("RIPROVA", Ui.YELLOW, 22, 190)
	again.pressed.connect(func() -> void: _main().go("prova_arena"))
	row.add_child(again)
	var menu := Ui.button("MENU", Ui.PINK, 22, 150)
	menu.pressed.connect(func() -> void: _main().go("menu"))
	row.add_child(menu)
	return pc


func _end(won: bool) -> void:
	Engine.time_scale = 1.0
	await get_tree().create_timer(0.9).timeout
	_registro_panel("VITTORIA" if won else "SCONFITTA", true)


func _main() -> Node:
	return get_parent()


# ================================================================ comandi

func _blocked() -> bool:
	return paused or in_piano or eng.over != ""


func _salto() -> void:
	if not _blocked():
		eng.input("salto")


func _gesture(g: String) -> void:
	if _blocked():
		return
	if g == "via" and eng.me().p_air > 0.0:
		g = "giu"
	eng.input(g)


func _swipe(from: Vector2, to: Vector2) -> void:
	var dd: Vector2 = to - from
	_trail.append([from, to, 0.25])
	if absf(dd.x) >= absf(dd.y):
		_gesture("dx" if dd.x > 0.0 else "sx")
	else:
		_gesture("via" if dd.y > 0.0 else "verso")


func _dodge_dir() -> String:
	var x: float = _pad.x if absf(_pad.x) > 0.3 else (-1.0 if _keys.get(KEY_A, false) else (1.0 if _keys.get(KEY_D, false) else 0.0))
	if x < -0.3:
		return "sx"
	if x > 0.3:
		return "dx"
	return "via"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var kc: Key = (event as InputEventKey).keycode
		_keys[kc] = event.pressed
		if event.pressed:
			match kc:
				KEY_SPACE: _salto()
				KEY_SHIFT: _gesture(_dodge_dir())
				KEY_C: _gesture("giu")
				KEY_Q: _gesture("postura")
				KEY_E: _gesture("cambio")
				KEY_F: _open_piano()
				KEY_J:
					if not _blocked():
						eng.press_attack()
				KEY_K: _gesture("verso")
				KEY_ESCAPE: _toggle_pause()
		elif kc == KEY_J:
			eng.release_attack()
		return
	# controller
	if event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if jm.axis == JOY_AXIS_LEFT_X:
			_pad.x = jm.axis_value
		elif jm.axis == JOY_AXIS_LEFT_Y:
			_pad.y = jm.axis_value
		return
	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.button_index == JOY_BUTTON_X:
			if jb.pressed and not _blocked():
				eng.press_attack()
			elif not jb.pressed:
				eng.release_attack()
		elif jb.pressed:
			match jb.button_index:
				JOY_BUTTON_Y: _gesture("verso")
				JOY_BUTTON_A: _salto()
				JOY_BUTTON_B: _gesture("giu" if eng.me().p_air > 0.0 else _dodge_dir())
				JOY_BUTTON_LEFT_SHOULDER: _gesture("postura")
				JOY_BUTTON_RIGHT_SHOULDER: _gesture("cambio")
				JOY_BUTTON_BACK: _open_piano()
				JOY_BUTTON_START: _toggle_pause()
		return
	# telefono: metà sinistra levetta, metà destra gesti
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var half: float = get_viewport().get_visible_rect().size.x * 0.5
		if st.pressed:
			if st.position.x < half and _stick_id < 0:
				_stick_id = st.index
				_stick_from = st.position
				_stick_v = Vector2.ZERO
			elif st.position.x >= half:
				if _act_id >= 0:
					# secondo dito a destra: postura
					_two = true
					eng.cancel_press()
					_gesture("postura")
					return
				_act_id = st.index
				_act_from = st.position
				_act_used = false
				_two = false
				if not _blocked():
					eng.press_attack()
		else:
			if st.index == _stick_id:
				_stick_id = -1
				_stick_v = Vector2.ZERO
			elif st.index == _act_id:
				_act_id = -1
				if not _act_used and not _two:
					_trail.append([st.position, st.position, 0.15])
					eng.release_attack()
				else:
					eng.cancel_press()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _stick_id:
			_stick_v = ((sd.position - _stick_from) / STICK_R).limit_length(1.0)
		elif sd.index == _act_id and not _act_used and sd.position.distance_to(_act_from) >= SWIPE_MIN:
			_act_used = true
			eng.cancel_press()
			_swipe(_act_from, sd.position)
	# mouse del computer (non quello simulato dal tocco)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and not _blocked():
				eng.press_attack()
			elif not mb.pressed:
				eng.release_attack()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_gesture("verso")
