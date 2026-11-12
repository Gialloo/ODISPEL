extends Node3D

# PROVA GREZZA 3 · il combattimento a scorrimento della prima prova grezza (vista di lato; l'isometrica resta con ISO = true),
# con la squadra da 4 a cambio rapido: in campo ne sta UNO solo, gli altri entrano col CAMBIO.
# Perché (autore, 12/11): l'arena circolare con due in campo era peggio; il secondo personaggio stava tra i piedi;
# il salto come tasto in più pesa sull'accessibilità → si torna allo scorrimento con lo scorri in su per saltare.
# Restano: colpo caricato (tieni premuto, rilascia), sospensione e schianto in aria, montante, cambio squadra.
# Comandi: tocco · tieni premuto (carica) · scorri → (verso) · ← (via) · ↑ (salto/lancio) · ↓ (giù) · due dita (postura)
#          · tocca un ritratto (cambio) · tasto PIANO.
# Computer: J o tasto sinistro (tieni per caricare) · D/→ o tasto destro verso · A/← via · W/↑/spazio su · S/↓ giù
#           · K/Q postura · E/Tab cambio · 1-4 scegli chi entra · P/F piano · Esc pausa. Funziona anche il controller.

const E = preload("res://scripts/prova_grezza/pg_engine.gd")
const COL: Dictionary = {"rosso": Color("#ff3d5a"), "blu": Color("#3f9dff"), "": Color("#ffd23f")}
const WHITE := Color("#fff4dc")
const SWIPE_MIN: float = 55.0
const HEADS: Array = [Color("#e8dcc8"), Color("#7ce0c3"), Color("#ffb36b"), Color("#c9a0ff")]   # chi è chi, a colpo d'occhio
# 12/11 notte, autore: «mi piaceva più orizzontale, era più snappy e responsive» → vista di lato fissa come la prima prova.
# L'isometrica resta qui: basta mettere ISO = true.
const ISO: bool = false
const CAM_SIZE: float = 7.6
const CAM_YAW: float = -32.0       # gradi: la strada corre in diagonale, il nemico sta più in là
const CAM_PITCH: float = 30.0

var eng: PgEngine
var cam: Camera3D
var _cam_home: Vector3
var _cam_x: float = 0.0
var _cam_off: Vector3
var _shake_t: float = 0.0
var _shake_p: float = 0.0
var _stop_id: int = 0

# corpi
var p_root: Node3D
var p_body: MeshInstance3D
var p_fist: MeshInstance3D
var p_mat: StandardMaterial3D
var p_head_mat: StandardMaterial3D
var _party_btns: Array = []
var _party_bars: Array = []
var _name_lab: Label
var e_root: Node3D
var e_body: MeshInstance3D
var e_mat: StandardMaterial3D
var e_eyes: StandardMaterial3D
var wall_r_mat: StandardMaterial3D
var _p_y: float = 0.0
var _e_y: float = 0.0

# interfaccia
var ui: CanvasLayer
var _ov: Control
var _flash: ColorRect
var _hp: ProgressBar
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
var _piano_panel: Control
var _piano_slots: Label
var _piano_prev: Label
var _piano_list: Array = []
var _pause_panel: Control
var _end_panel: Control

# gesti
var _touches: Dictionary = {}           # indice -> {from, t, used}
var _mouse_from: Vector2 = Vector2.INF
var _trail: Array = []                  # [da, a, vita]
var _speed_t: float = 0.0
var _hints_done: Dictionary = {}
var _hint_slow: bool = false
var _cancel_glow: float = 0.0
var paused: bool = false
var in_piano: bool = false


func configure(_args: Dictionary) -> void:
	pass


func _ready() -> void:
	eng = PgEngine.new(int(Time.get_ticks_msec()) % 100000, 4)
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
	if not ISO:
		# vista di lato fissa: niente inseguimento, lo schermo è il ring
		cam.fov = 50.0
		cam.position = Vector3(0, 2.3, 9.2)
		add_child(cam)
		cam.look_at(Vector3(0, 1.3, 0))
		cam.current = true
		_cam_home = cam.position
		_build_ui()
		Sfx.music_start("battaglia")
		_show_hint("prima", "Il nemico ti attacca: guarda la freccia", 2.2)
		return
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = CAM_SIZE
	cam.near = 0.1
	cam.far = 80.0
	var yaw: float = deg_to_rad(CAM_YAW)
	var pit: float = deg_to_rad(CAM_PITCH)
	_cam_off = Vector3(sin(yaw) * cos(pit), sin(pit), cos(yaw) * cos(pit)) * 24.0
	_cam_x = _wx((eng.px + eng.ex) * 0.5)
	add_child(cam)
	_cam_home = Vector3(_cam_x, 1.1, 0) + _cam_off
	cam.position = _cam_home
	cam.look_at(Vector3(_cam_x, 1.1, 0))
	cam.current = true
	_build_ui()
	Sfx.music_start("battaglia")
	_show_hint("prima", "Il nemico ti attacca: guarda la freccia", 2.2)


# ================================================================ mondo

func _wx(x: float) -> float:
	return x - (E.WALL_L + E.WALL_R) * 0.5


func _mat(c: Color, unshaded: bool = true, emit: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _box(size: Vector3, pos: Vector3, m: Material, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_arena() -> void:
	_box(Vector3(34, 0.2, 16), Vector3(0, -0.1, -2.0), _mat(Color("#21173a")))
	# piastrelle: in isometrica la griglia dice subito dov'è la strada
	for i in range(-8, 9):
		_box(Vector3(0.04, 0.02, 16), Vector3(i * 2.0, 0.005, -2.0), _mat(Color("#2a1e4a")))
	for j in range(-4, 3):
		_box(Vector3(34, 0.02, 0.04), Vector3(0, 0.005, j * 2.0 + 1.0), _mat(Color("#2a1e4a")))
	# riga del pavimento: la "strada" su cui si combatte
	_box(Vector3(E.WALL_R - E.WALL_L, 0.02, 0.08), Vector3(0, 0.01, 0.9), _mat(Color("#3a2a66")))
	# skyline dietro, solo sagome
	var hs: Array = [3.0, 5.5, 4.0, 6.5, 3.5, 5.0, 4.5]
	for i in hs.size():
		_box(Vector3(2.6, hs[i], 1.0), Vector3(-9.0 + i * 3.0, hs[i] * 0.5, -6.0), _mat(Color("#1a1030")))
	# i due muri: quello a destra è il bersaglio (insegna al neon che si accende quando ci sbatti il nemico)
	# a sinistra solo una transenna bassa: in isometrica un muro alto starebbe davanti al Manichino
	if ISO:
		_box(Vector3(0.5, 1.0, 3.0), Vector3(_wx(E.WALL_L) - 0.25, 0.5, 0), _mat(Color("#2b1f4a")))
	else:
		_box(Vector3(0.5, 5.0, 3.0), Vector3(_wx(E.WALL_L) - 0.25, 2.5, 0), _mat(Color("#2b1f4a")))
	_box(Vector3(0.5, 5.0, 3.0), Vector3(_wx(E.WALL_R) + 0.25, 2.5, 0), _mat(Color("#2b1f4a")))
	wall_r_mat = _mat(Color("#ff3d8b"), true)
	_box(Vector3(0.08, 2.4, 0.6), Vector3(_wx(E.WALL_R) - 0.02, 2.6, 0.6), wall_r_mat)
	wall_r_mat.albedo_color = Color("#5a1d3a")


func _build_bodies() -> void:
	# MANICHINO: busto, testa, pugno. Il colore dei bordi è la postura.
	p_root = Node3D.new()
	add_child(p_root)
	p_mat = _mat(COL["rosso"])
	p_body = MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.38
	cm.height = 1.7
	p_body.mesh = cm
	p_body.material_override = p_mat
	p_body.position = Vector3(0, 0.85, 0)
	p_root.add_child(p_body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.26
	sm.height = 0.52
	head.mesh = sm
	head.material_override = _mat(Color("#e8dcc8"))
	head.position = Vector3(0.05, 0.95, 0)
	p_body.add_child(head)
	p_head_mat = head.material_override
	p_head_mat.albedo_color = HEADS[0]
	p_fist = _box(Vector3(0.34, 0.26, 0.26), Vector3(0.35, 0.25, 0.25), _mat(WHITE), p_body)
	# DISTURBO: blocco scuro con due occhi; si piega indietro (AFFONDO) o si abbassa (SPAZZATA)
	e_root = Node3D.new()
	add_child(e_root)
	e_mat = _mat(Color("#3b2766"))
	e_body = _box(Vector3(1.1, 2.1, 0.9), Vector3(0, 1.05, 0), e_mat, e_root)
	e_eyes = _mat(Color("#ffd23f"))
	_box(Vector3(0.16, 0.16, 0.1), Vector3(-0.3, 0.55, 0.46), e_eyes, e_body)
	_box(Vector3(0.16, 0.16, 0.1), Vector3(-0.05, 0.55, 0.46), e_eyes, e_body)


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
	# in alto a sinistra: il Manichino
	var lt := VBoxContainer.new()
	Ui.place(lt, 0, 0, 0, 0, 24, 16, 440, 120)
	ui.add_child(lt)
	_name_lab = Ui.label("MANICHINO A", 24, WHITE, Ui.display(), 6)
	lt.add_child(_name_lab)
	_hp = _bar(Color("#46e07a"), 20, E.HP_MAX)
	lt.add_child(_hp)
	var fr := HBoxContainer.new()
	lt.add_child(fr)
	fr.add_child(Ui.label("FIATO", 18, Ui.CYAN, Ui.display(), 5))
	_fiato = _bar(Ui.CYAN, 14, E.FIATO_MAX)
	_fiato.custom_minimum_size.x = 330
	fr.add_child(_fiato)
	# in alto a destra: il nemico e il suo SEGNALE
	var rt := VBoxContainer.new()
	Ui.place(rt, 1, 0, 1, 0, -480, 16, -24, 140)
	ui.add_child(rt)
	var n := Ui.label("DISTURBO", 24, Ui.PINK, Ui.display(), 6)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rt.add_child(n)
	_ehp = _bar(Ui.PINK, 18, E.ENEMY_HP)
	rt.add_child(_ehp)
	_seg_lab = Ui.label("SEGNALE", 18, Ui.YELLOW, Ui.display(), 5)
	_seg_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rt.add_child(_seg_lab)
	_seg = _bar(Ui.YELLOW, 26, E.SEG_MAX)
	rt.add_child(_seg)
	# al centro in alto: il Registro
	_reg_lab = Ui.label("REGISTRO 0/%d" % E.DISCOVERIES.size(), 20, WHITE, Ui.display(), 5)
	_reg_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_reg_lab, 0.5, 0, 0.5, 0, -160, 18, 160, 50)
	ui.add_child(_reg_lab)
	_toast = Ui.label("", 26, Ui.YELLOW, Ui.display(), 7)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_toast, 0.5, 0, 0.5, 0, -400, 130, 400, 174)
	_toast.modulate.a = 0.0
	ui.add_child(_toast)
	# timbro grande al centro
	_stamp = Ui.label("", 72, WHITE, Ui.display(), 12)
	_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_stamp, 0.5, 0.5, 0.5, 0.5, -500, -200, 500, -100)
	_stamp.pivot_offset = Vector2(500, 50)
	_stamp.modulate.a = 0.0
	ui.add_child(_stamp)
	_sub = Ui.label("", 30, WHITE, Ui.display(), 7)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_sub, 0.5, 0.5, 0.5, 0.5, -500, -100, 500, -55)
	_sub.modulate.a = 0.0
	ui.add_child(_sub)
	_hint = Ui.label("", 30, WHITE, Ui.display(), 8)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_hint, 0.5, 1, 0.5, 1, -560, -150, 560, -100)
	_hint.modulate.a = 0.0
	ui.add_child(_hint)
	# in basso: postura (anche due dita) e PIANO
	_btn_post = Ui.button("ROSSO", COL["rosso"], 24, 170)
	Ui.place(_btn_post, 0, 1, 0, 1, 24, -96, 200, -24)
	_btn_post.focus_mode = Control.FOCUS_NONE
	_btn_post.pressed.connect(func() -> void: _gesture("postura"))
	ui.add_child(_btn_post)
	_btn_piano = Ui.button("PIANO", Ui.CYAN, 24, 170)
	Ui.place(_btn_piano, 1, 1, 1, 1, -200, -96, -24, -24)
	_btn_piano.focus_mode = Control.FOCUS_NONE
	_btn_piano.pressed.connect(_open_piano)
	ui.add_child(_btn_piano)
	# la squadra: un ritratto per membro, a destra come nei giochi a cambio rapido; toccarlo = CAMBIO
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	Ui.place(col, 1, 0.5, 1, 0.5, -150, -190, -24, 150)
	ui.add_child(col)
	for i in eng.party.size():
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		col.add_child(cell)
		var b := Ui.button(str(eng.party[i]["id"]).to_upper(), HEADS[i], 26, 126)
		b.custom_minimum_size.y = 52
		b.focus_mode = Control.FOCUS_NONE
		var idx: int = i
		b.pressed.connect(func() -> void: _switch(idx))
		cell.add_child(b)
		var hb := _bar(Color("#46e07a"), 8, E.HP_MAX)
		cell.add_child(hb)
		_party_btns.append(b)
		_party_bars.append(hb)
	var bp := Ui.button("II", WHITE, 22, 64)
	Ui.place(bp, 0.5, 1, 0.5, 1, -32, -84, 32, -30)
	bp.focus_mode = Control.FOCUS_NONE
	bp.pressed.connect(func() -> void: _toggle_pause())
	ui.add_child(bp)


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
	if not paused and not in_piano and eng.over == "":
		eng.step(delta)
		for ev in eng.take_events():
			_on_event(ev)
	_tutor()
	_sync(delta)
	_refresh()
	# scossa dell'inquadratura e segni del gesto (in tempo reale, anche durante il fermo immagine)
	var rd: float = delta / maxf(0.01, Engine.time_scale)
	if ISO:
		_cam_x = lerpf(_cam_x, _wx((eng.px + eng.ex) * 0.5), minf(1.0, rd * 4.0))
		_cam_home = Vector3(_cam_x, 1.1, 0) + _cam_off
	if _shake_t > 0.0:
		_shake_t -= rd
		var p: float = _shake_p * maxf(0.0, _shake_t)
		cam.position = _cam_home + Vector3(randf_range(-p, p), randf_range(-p, p), 0)
	else:
		cam.position = cam.position.lerp(_cam_home, 0.3)
	for t in _trail:
		t[2] -= rd
	_trail = _trail.filter(func(t: Array) -> bool: return t[2] > 0.0)
	_speed_t = maxf(0.0, _speed_t - rd)
	_cancel_glow = maxf(0.0, _cancel_glow - rd)
	_ov.queue_redraw()


func _sync(delta: float) -> void:
	# i corpi inseguono le posizioni del motore: si vede chi arretra e chi avanza davvero
	var k: float = minf(1.0, delta * 22.0)
	var py: float = 0.0
	if eng.st == "hover":
		py = 2.2 + sin(Time.get_ticks_msec() * 0.012) * 0.06
	elif eng.p_air > 0.0:
		py = 1.6 if eng.est == "air" else 1.1
	_p_y = lerpf(_p_y, py, minf(1.0, delta * 14.0))
	p_root.position = p_root.position.lerp(Vector3(_wx(eng.px), _p_y, 0), k)
	var ey: float = 1.9 if eng.est == "air" else 0.0
	_e_y = lerpf(_e_y, ey, minf(1.0, delta * 12.0))
	e_root.position = e_root.position.lerp(Vector3(_wx(eng.ex), _e_y, 0), k)
	# pose del Manichino
	var lean: float = 0.0
	var fist_x: float = 0.35
	var crouch: float = 1.0
	match eng.st:
		"atk":
			var mv: Dictionary = eng.move
			var f: float = clampf(eng.st_t / maxf(0.01, float(mv.get("hit", 0.1)) + 0.05), 0.0, 1.0)
			lean = -0.35 * f
			fist_x = 0.35 + 0.65 * f
			match str(mv.get("id", "")):
				"lancio", "montante":
					lean = 0.25
				"schiacciata", "schianto":
					lean = -0.8
				"scatto":
					lean = -0.55
					crouch = 0.9
		"charge":
			# carica: si abbassa e trema di più a ogni livello
			var lv: int = eng.charge_level()
			lean = -0.15 + sin(Time.get_ticks_msec() * 0.05) * 0.02 * lv
			crouch = 0.9 - 0.04 * lv
		"hover":
			lean = -0.3
		"dodge":
			lean = 0.4
			crouch = 0.8
		"hurt":
			lean = 0.55
			crouch = 0.85
	p_body.rotation.z = lerp_angle(p_body.rotation.z, lean, minf(1.0, delta * 20.0))
	p_body.scale.y = lerpf(p_body.scale.y, crouch, minf(1.0, delta * 18.0))
	p_fist.position.x = lerpf(p_fist.position.x, fist_x, minf(1.0, delta * 30.0))
	# il lampo bianco: la mossa si può annullare
	var col: Color = COL[eng.posture]
	if eng.can_cancel_now():
		col = col.lerp(Color.WHITE, 0.75)
		if _cancel_glow <= 0.0:
			_cancel_glow = 0.12
	elif eng.st in ["charge", "hover"] and eng.charge_level() >= 3:
		col = col.lerp(Ui.YELLOW, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03))
	p_mat.albedo_color = p_mat.albedo_color.lerp(col, minf(1.0, delta * 30.0))
	# pose del nemico
	var e_lean: float = 0.0
	var e_sc: float = 1.0
	var e_col := Color("#3b2766")
	var d: Dictionary = eng.danger()
	if not d.is_empty():
		var f2: float = clampf(1.0 - float(d["left"]) / maxf(0.1, float(d["impact"])), 0.0, 1.0)
		if d["kind"] == "affondo":
			e_lean = -0.35 * f2
			e_col = e_col.lerp(COL[d["color"]], 0.25 + 0.6 * f2)
		else:
			e_sc = 1.0 - 0.35 * f2
			e_col = e_col.lerp(COL[""], 0.2 + 0.5 * f2)
	match eng.est:
		"stun":
			e_lean = 0.3
		"crollo":
			e_lean = 0.5
			e_sc = 0.8
			e_col = Color("#6b6b80")
		"down":
			e_lean = 1.2
		"air":
			e_lean = 0.9 + sin(Time.get_ticks_msec() * 0.02) * 0.2
	e_body.rotation.z = lerp_angle(e_body.rotation.z, e_lean, minf(1.0, delta * 16.0))
	e_body.scale.y = lerpf(e_body.scale.y, e_sc, minf(1.0, delta * 16.0))
	e_mat.albedo_color = e_mat.albedo_color.lerp(e_col, minf(1.0, delta * 20.0))
	e_eyes.albedo_color = Color("#9a9aa8") if eng.est == "crollo" else (COL[d["color"]] if not d.is_empty() and d["kind"] == "affondo" else Color("#ffd23f"))


func _refresh() -> void:
	_hp.value = eng.hp
	_fiato.value = eng.fiato
	_ehp.value = eng.ehp
	_seg.value = eng.seg
	_seg_lab.text = "CROLLO!" if eng.est == "crollo" else "SEGNALE"
	_reg_lab.text = "REGISTRO %d/%d" % [eng.found.size(), E.DISCOVERIES.size()]
	_btn_post.text = eng.posture.to_upper()
	_btn_post.add_theme_stylebox_override("normal", Ui.box(COL[eng.posture]))
	_btn_piano.disabled = eng.fiato < E.PIANO_COST or eng.over != ""
	_btn_piano.text = "PIANO" if not eng.plan_active else "IN ONDA"
	_name_lab.text = str(eng.party[eng.active]["name"])
	var cd: bool = eng.time < eng.switch_ready
	for i in _party_btns.size():
		var m: Dictionary = eng.party[i]
		var b: Button = _party_btns[i]
		var hp: float = eng.hp if i == eng.active else float(m["hp"])
		_party_bars[i].value = hp
		var c: Color = HEADS[i]
		if m["ko"]:
			c = Color("#4a4458")
		elif i != eng.active and cd:
			c = c.darkened(0.5)
		b.add_theme_stylebox_override("normal", Ui.box(c, WHITE if i == eng.active else Ui.INK, 5 if i == eng.active else 2))
		b.text = "K.O." if m["ko"] else (("▶ " if i == eng.active else "") + str(m["id"]).to_upper())
		b.disabled = m["ko"]


# ================================================================ disegno sopra la scena

func _sp(x: float, y: float) -> Vector2:
	return cam.unproject_position(Vector3(_wx(x), y, 0))


func _draw_overlay() -> void:
	var d: Dictionary = eng.danger()
	if not d.is_empty():
		var left: float = float(d["left"])
		var w: float = eng.win_len()
		var in_win: bool = left <= w
		var head: Vector2 = cam.unproject_position(e_root.position + Vector3(0, 2.9, 0))
		var c: Color = COL[d["color"]] if d["kind"] == "affondo" else COL[""]
		# anello che si chiude all'impatto: quando diventa bianco è il momento
		var r: float = 34.0 + 70.0 * clampf(left / maxf(0.1, float(d["impact"])), 0.0, 1.0)
		_ov.draw_arc(head, 34.0, 0, TAU, 40, Color(WHITE, 0.5), 3.0)
		_ov.draw_arc(head, r, 0, TAU, 48, Color.WHITE if in_win else c, 10.0 if in_win else 5.0)
		if d["kind"] == "affondo":
			# freccia dritta verso il giocatore
			var to_p: float = (_road_dir() * -1.0).angle()
			var pts := PackedVector2Array()
			for q in [Vector2(-26, 0), Vector2(4, -20), Vector2(4, -8), Vector2(26, -8), Vector2(26, 8), Vector2(4, 8), Vector2(4, 20)]:
				pts.append(head + (q * -1.0).rotated(to_p))
			_ov.draw_colored_polygon(pts, c)
			_ov.draw_polyline(pts + PackedVector2Array([pts[0]]), Ui.INK, 3.0)
		else:
			# onda bassa a terra e sull'icona
			var foot: Vector2 = cam.unproject_position(Vector3(_wx(eng.ex), 0.1, 0.8))
			var wave := PackedVector2Array()
			var wave2 := PackedVector2Array()
			for i in 13:
				var xx: float = -24.0 + i * 4.0
				wave.append(head + Vector2(xx, sin(i * 0.9) * 8.0))
				var rdir: Vector2 = _road_dir()
				wave2.append(foot - rdir * i * 26.0 + rdir.orthogonal() * sin(i * 0.9 + Time.get_ticks_msec() * 0.02) * 10.0)
			_ov.draw_polyline(wave, c, 6.0)
			_ov.draw_polyline(wave2, Color(c, 0.85), 8.0)
	# CROLLO: il nemico è aperto
	if eng.est == "crollo":
		var cc: Vector2 = cam.unproject_position(e_root.position + Vector3(0, 1.2, 0))
		var fr: float = clampf(eng.est_t / E.CROLLO_TIME, 0.0, 1.0)
		_ov.draw_arc(cc, 110.0, -PI * 0.5, -PI * 0.5 + TAU * fr, 64, Ui.YELLOW, 10.0)
	# carica: un anello per livello; si chiude e cambia colore quando il livello sale
	if eng.st in ["charge", "hover"]:
		var cc2: Vector2 = cam.unproject_position(p_root.position + Vector3(0, 0.9, 0))
		var lv: int = eng.charge_level()
		var lvc: Array = [WHITE, WHITE, Ui.YELLOW, COL[eng.posture]]
		for k in range(1, lv + 1):
			_ov.draw_arc(cc2, 44.0 + 16.0 * k, 0, TAU, 40, Color(lvc[k], 0.9), 6.0)
		if lv < E.CHARGE_LV.size():
			var a0: float = float(E.CHARGE_LV[lv - 1]) if lv >= 1 else 0.0
			var a1: float = float(E.CHARGE_LV[lv])
			var fr2: float = clampf((eng.charge_t - a0) / maxf(0.01, a1 - a0), 0.0, 1.0)
			_ov.draw_arc(cc2, 44.0 + 16.0 * (lv + 1), -PI * 0.5, -PI * 0.5 + TAU * fr2, 40, Color(lvc[lv + 1], 0.6), 4.0)
		if eng.st == "hover":
			var fl: Vector2 = cam.unproject_position(Vector3(p_root.position.x, 0.05, 0))
			_ov.draw_line(cc2, fl, Color(Ui.YELLOW, 0.5), 3.0)
			_ov.draw_circle(fl, 26.0, Color(Ui.YELLOW, 0.35))
	# lampo bianco attorno al Manichino quando puoi annullare
	if eng.can_cancel_now():
		var pc: Vector2 = cam.unproject_position(p_root.position + Vector3(0, 0.9, 0))
		_ov.draw_arc(pc, 70.0, 0, TAU, 40, Color(1, 1, 1, 0.9), 6.0)
	# linee di velocità dell'affondo
	if _speed_t > 0.0:
		var pc2: Vector2 = cam.unproject_position(p_root.position + Vector3(0, 0.9, 0))
		var rd2: Vector2 = _road_dir()
		for i in 6:
			var off: Vector2 = rd2.orthogonal() * (-60.0 + i * 24.0)
			_ov.draw_line(pc2 + off - rd2 * 260.0, pc2 + off - rd2 * 60.0, Color(1, 1, 1, _speed_t * 4.0), 4.0)
	# la scia del dito
	for t in _trail:
		_ov.draw_line(t[0], t[1], Color(1, 1, 1, clampf(t[2] * 4.0, 0.0, 0.8)), 12.0)
		_ov.draw_circle(t[1], 12.0, Color(1, 1, 1, clampf(t[2] * 4.0, 0.0, 0.8)))
	# sotto il suggerimento: una mano disegnata che fa il gesto
	if _hint.modulate.a > 0.05 and _hint.has_meta("g"):
		var base := Vector2(_ov.size.x * 0.5, _ov.size.y - 210)
		var ph: float = fmod(Time.get_ticks_msec() * 0.0015, 1.0)
		var dirv: Vector2 = {"verso": Vector2(1, 0), "via": Vector2(-1, 0), "su": Vector2(0, -1), "giu": Vector2(0, 1)}.get(_hint.get_meta("g"), Vector2.ZERO)
		if _hint.get_meta("g") == "tieni":
			# tieni premuto: il cerchio si riempie invece di pulsare
			_ov.draw_circle(base, 20.0, Color(1, 1, 1, _hint.modulate.a * 0.9))
			_ov.draw_arc(base, 38.0, -PI * 0.5, -PI * 0.5 + TAU * ph, 40, Color(Ui.YELLOW, _hint.modulate.a), 8.0)
			return
		var a: float = _hint.modulate.a
		if dirv == Vector2.ZERO:
			_ov.draw_circle(base, 18.0 + 14.0 * ph, Color(1, 1, 1, a * (1.0 - ph)))
		else:
			var p0: Vector2 = base - dirv * 70.0
			_ov.draw_line(p0, p0 + dirv * 140.0 * ph, Color(1, 1, 1, a * 0.8), 10.0)
			_ov.draw_circle(p0 + dirv * 140.0 * ph, 16.0, Color(1, 1, 1, a))


# ================================================================ eventi del motore → sensazione

func _on_event(ev: Dictionary) -> void:
	match ev["type"]:
		"mossa":
			match ev["id"]:
				"affondo", "scatto", "entrata":
					_speed_t = 0.22 if ev["id"] == "scatto" else 0.18
					Sfx.play("schivata", 0.0, 1.1 if ev["id"] == "scatto" else 1.3)
				"montante":
					Sfx.play("schivata", 0.0, 0.9)
				"schianto":
					Sfx.play("schivata", 0.0, 0.7)
				"colpo", "aria":
					Sfx.play("schivata", 0.0, 1.6 + 0.1 * int(ev["chain"]), -8.0)
				"blackout":
					_flash_now(Color.BLACK, 0.95)
					_slowmo(0.25, 0.35)
		"colpito_nemico":
			var src: String = ev["src"]
			var big: bool = src in ["affondo", "schiacciata", "lancio", "scatto", "schianto", "montante", "entrata"] or float(ev["dmg"]) >= 20.0
			_sparks(e_root.position + Vector3(-0.5, 1.2 + _e_y * 0.2, 0.5), COL[eng.posture], 24 if big else 12)
			_number(int(ev["dmg"]), big)
			_knock()
			if ev["armor"]:
				Sfx.play("scudo", 0.0, 1.0, -4.0)
				_sub_text("INCASSA: SOLO IL CONTRO LO FERMA", Ui.CREAM)
			else:
				Sfx.play("colpo_forte" if big else "colpo", 0.0, randf_range(0.95, 1.1))
			_hitstop(0.08 if big else 0.045)
			_shake(0.12 if big else 0.06, 0.12 if big else 0.05)
		"contro":
			var c: Color = COL[ev["color"]]
			_hitstop(0.16 if ev["freq"] else 0.11)
			_flash_now(c if ev["freq"] else Color.WHITE, 0.55)
			_shake(0.25, 0.25)
			_punch(38.0 if ev["freq"] else 42.0)
			_sparks(e_root.position + Vector3(-0.5, 1.3, 0.5), c, 50)
			Sfx.play("critico")
			Sfx.word("BAM", true)
			var t: String = "FREQUENZA!" if ev["freq"] else "CONTRO!"
			if int(ev.get("lv", 0)) > 0:
				t = "CONTRO CARICATO!"
				_shake(0.35, 0.4)
			if ev.get("cambio", false):
				t = "CAMBIO IN DIFESA!"
			_stamp_text(t, c if ev["freq"] else Ui.CYAN)
			if ev["perfect"]:
				_sub_text("PERFETTO", Ui.YELLOW)
			_hide_hint()
		"un_altro":
			_sub_text("UN ALTRO! è fermo", Ui.YELLOW)
			_slowmo(0.35, 0.4)
		"troppo_presto":
			_sub_text("TROPPO PRESTO", Color("#ff7a9c"))
		"colpito":
			_flash_now(Color("#ff2a2a"), 0.45)
			_shake(0.3, 0.3)
			_hitstop(0.09)
			Sfx.play("ferita")
			_stamp_text("DOPPIO!" if ev["doppio"] else ("A TERRA" if ev["kind"] == "spazzata" else "AHI"), Color("#ff4b4b"))
		"schivata":
			Sfx.play("schivata")
			_sub_text("SCHIVATA PERFETTA  +FIATO" if ev["perfect"] else "SCHIVATA", Ui.CYAN)
			if ev["perfect"]:
				_slowmo(0.3, 0.3)
		"saltata":
			Sfx.play("schivata", 0.0, 0.8)
			_stamp_text("SALTATA!", Ui.YELLOW)
			_sub_text("ORA COLPISCI IN ARIA", WHITE)
			_slowmo(0.35, 0.3)
			_hide_hint()
		"castigo":
			_sub_text("CASTIGO x1,5", Ui.YELLOW)
		"nemico_a_vuoto":
			_sub_text("A VUOTO: PUNISCILO", Ui.CYAN)
		"muro":
			_stamp_text("AL MURO!", Ui.PINK)
			_shake(0.3, 0.35)
			_hitstop(0.12)
			Sfx.play("break", 0.0, 1.2, -4.0)
			wall_r_mat.albedo_color = Color("#ff3d8b")
			create_tween().tween_property(wall_r_mat, "albedo_color", Color("#5a1d3a"), 0.8)
		"lancio":
			_sub_text("IN ARIA: TOCCA!", WHITE)
		"schiacciata":
			var lv2: int = int(ev.get("lv", 0))
			_stamp_text("SCHIANTO!" if lv2 > 0 else "SCHIACCIATA!", Ui.YELLOW)
			_shake(0.3 + 0.08 * lv2, 0.35 + 0.1 * lv2)
			_hitstop(0.12 + 0.03 * lv2)
			if lv2 > 0:
				_sparks(Vector3(e_root.position.x, 0.2, 0.3), Ui.YELLOW, 40 + 15 * lv2)
		"carica":
			Sfx.play("ui_sposta", 0.0, 0.6, -6.0)
		"sospeso":
			_sub_text("SOSPESO: RILASCIA PER LO SCHIANTO", Ui.YELLOW)
		"carica_annullata":
			_sub_text("CARICA ANNULLATA", Ui.CYAN)
		"cambio":
			var to: int = int(ev["to"])
			p_head_mat.albedo_color = HEADS[to]
			p_mat.albedo_color = COL[eng.posture]
			var pop := create_tween().set_ignore_time_scale(true)
			p_root.scale = Vector3(0.4, 1.4, 0.4)
			pop.tween_property(p_root, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_sparks(p_root.position + Vector3(0, 1.0, 0), HEADS[to], 20)
			Sfx.play("ui_ok", 0.0, 1.1)
			if ev["staffetta"]:
				_stamp_text("STAFFETTA!", HEADS[to])
				_flash_now(HEADS[to], 0.3)
			elif not ev["difesa"]:
				_sub_text("ENTRA %s" % str(eng.party[to]["name"]), HEADS[to])
		"ko":
			_stamp_text("K.O.", Color("#ff4b4b"))
			_sub_text("%s È FUORI" % str(eng.party[int(ev["who"])]["name"]), Color("#ff7a9c"))
			_slowmo(0.3, 0.5)
		"annullo":
			_flash_now(Color.WHITE, 0.25)
			Sfx.play("ui_ok", 0.0, 1.5)
		"respiro":
			_sub_text("RESPIRO +FIATO", Ui.CYAN)
			Sfx.play("cura", 0.0, 1.2, -6.0)
		"postura":
			_flash_now(COL[ev["posture"]], 0.25)
			Sfx.play("ui_sposta", 0.0, 0.8 if ev["posture"] == "rosso" else 1.3, 4.0)
		"crollo":
			_stamp_text("CROLLO", Ui.YELLOW)
			_sub_text("SCORRI VERSO: BLACKOUT", WHITE)
			_hitstop(0.2)
			Sfx.play("break")
			_show_hint("crollo", "Scorri verso il nemico: BLACKOUT", 3.0, "verso")
		"blackout":
			_flash_now(Color.WHITE, 1.0)
			_shake(0.5, 0.5)
			_punch(34.0)
			_sparks(e_root.position + Vector3(0, 1.2, 0.5), Color.WHITE, 80)
			_stamp_text("BLACKOUT", WHITE)
			_number(int(ev["dmg"]), true)
			Sfx.play("colpo_finale")
		"crollo_finito":
			_sub_text("SI È RIPRESO", Color("#ff7a9c"))
		"scrollata":
			_sub_text("SI SCROLLA DI DOSSO", Color("#ff7a9c"))
			_shake(0.15, 0.15)
		"scoperta":
			_toast_text("NUOVO NEL REGISTRO: %s  (%d/%d)" % [ev["label"], ev["n"], ev["of"]])
			Sfx.play("combo", 0.0, 1.0 + 0.05 * int(ev["n"]))
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


# ---------------------------------------------------------------- il primo minuto: un gesto alla volta, quando serve

func _tutor() -> void:
	if eng.over != "" or paused or in_piano:
		return
	var d: Dictionary = eng.danger()
	if not d.is_empty() and float(d["left"]) <= eng.win_len() + 0.05:
		if d["kind"] == "affondo" and not _hints_done.has("affondo"):
			_hints_done["affondo"] = true
			_show_hint("", "Scorri VERSO il nemico: CONTRO", 2.5, "verso")
			_hint_slowmo()
		elif d["kind"] == "spazzata" and not _hints_done.has("spazzata"):
			_hints_done["spazzata"] = true
			_show_hint("", "Scorri IN SU: salta l'onda", 2.5, "su")
			_hint_slowmo()
	if eng.est == "stun" and eng.found.has("contro") and not _hints_done.has("tocco"):
		_hints_done["tocco"] = true
		_show_hint("", "Tocca per colpire, tocca ancora per la catena", 2.5, "tocco")
	if eng.found.has("contro") and eng.time > 12.0 and not _hints_done.has("tieni"):
		_hints_done["tieni"] = true
		_show_hint("", "TIENI PREMUTO: carichi. Rilascia: SCATTO (sulla freccia: CONTRO CARICATO)", 3.5, "tieni")
	if eng.found.size() >= 4 and not _hints_done.has("cambio"):
		_hints_done["cambio"] = true
		_show_hint("", "Tocca un ritratto a destra: CAMBIO. Nel lampo bianco è una STAFFETTA", 3.5)
	if eng.found.size() >= 3 and not _hints_done.has("postura"):
		_hints_done["postura"] = true
		_show_hint("", "Due dita: cambi postura. Stesso colore della freccia = FREQUENZA", 3.5)
	if eng.fiato >= E.PIANO_COST and eng.time > 40.0 and not _hints_done.has("piano"):
		_hints_done["piano"] = true
		_show_hint("", "PIANO: fermi il tempo e monti le prossime mosse", 3.0)


func _hint_slowmo() -> void:
	# il primo colpo di ogni tipo arriva al rallentatore: si impara guardando, non leggendo
	_hint_slow = true
	_slowmo(0.22, 0.5)


func _show_hint(key: String, text: String, hold: float, g: String = "") -> void:
	if key != "":
		if _hints_done.has(key):
			return
		_hints_done[key] = true
	_hint.text = text
	if g != "":
		_hint.set_meta("g", g)
	elif _hint.has_meta("g"):
		_hint.remove_meta("g")
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_hint, "modulate:a", 1.0, 0.15)
	tw.tween_interval(hold)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.4)


func _hide_hint() -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.3)


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
	_toast.scale = Vector2(1.2, 1.2)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_toast, "scale", Vector2.ONE, 0.15)
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
		_hint_slow = false


func _flash_now(c: Color, a: float) -> void:
	_flash.color = Color(c, a)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_flash, "color:a", 0.0, 0.25)


func _shake(dur: float, power: float) -> void:
	_shake_t = dur
	_shake_p = power / maxf(0.01, dur)


func _punch(fov: float) -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	if not ISO:
		tw.tween_property(cam, "fov", fov, 0.06)
		tw.tween_property(cam, "fov", 50.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		return
	tw.tween_property(cam, "size", CAM_SIZE * fov / 50.0, 0.06)
	tw.tween_property(cam, "size", CAM_SIZE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _knock() -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(e_body, "position:x", 0.25, 0.03)
	tw.tween_property(e_body, "position:x", 0.0, 0.15)


func _sparks(pos: Vector3, c: Color, n: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = n
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector3(1, 0.4, 0)
	p.spread = 70.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 11.0
	p.gravity = Vector3(0, -14, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var qm := BoxMesh.new()
	qm.size = Vector3(0.12, 0.12, 0.12)
	p.mesh = qm
	p.material_override = _mat(c)
	p.position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.8, true, false, true).timeout.connect(p.queue_free)


func _number(n: int, big: bool) -> void:
	var l := Ui.label(str(n), 46 if big else 32, Ui.YELLOW if not big else WHITE, Ui.display(), 8)
	var p: Vector2 = cam.unproject_position(e_root.position + Vector3(randf_range(-0.5, 0.5), 2.4, 0))
	l.position = p - Vector2(30, 20)
	ui.add_child(l)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(l, "position:y", p.y - 100.0, 0.6).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.tween_callback(l.queue_free)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# ================================================================ PIANO (moviola)

func _open_piano() -> void:
	if eng.fiato < E.PIANO_COST or eng.over != "" or in_piano:
		return
	in_piano = true
	Engine.time_scale = 1.0
	_piano_list = []
	_piano_panel = Control.new()
	_piano_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_piano_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.1, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_piano_panel.add_child(dim)
	var tl := Ui.label("PIANO · MOVIOLA  %05.2f" % eng.time, 34, Ui.CYAN, Ui.display(), 8)
	Ui.place(tl, 0.5, 0, 0.5, 0, -400, 120, 400, 170)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_piano_panel.add_child(tl)
	_piano_prev = Ui.label(_preview_text(), 26, WHITE, Ui.display(), 6)
	Ui.place(_piano_prev, 0.5, 0, 0.5, 0, -560, 175, 560, 215)
	_piano_prev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_piano_panel.add_child(_piano_prev)
	_piano_slots = Ui.label("", 30, Ui.YELLOW, Ui.display(), 6)
	Ui.place(_piano_slots, 0.5, 0.5, 0.5, 0.5, -560, -110, 560, -60)
	_piano_slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_piano_panel.add_child(_piano_slots)
	var row := GridContainer.new()
	row.columns = 4
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 10)
	Ui.place(row, 0.5, 0.5, 0.5, 0.5, -390, -40, 390, 110)
	_piano_panel.add_child(row)
	for a in [["tocco", "COLPO"], ["verso", "AFFONDO →"], ["carica", "CARICA"], ["su", "SU ↑"], ["giu", "GIÙ ↓"], ["via", "← INDIETRO"], ["postura", "POSTURA"], ["cambio", "CAMBIO"]]:
		var b := Ui.button(a[1], WHITE, 24, 180)
		b.focus_mode = Control.FOCUS_NONE
		var g: String = a[0]
		b.pressed.connect(func() -> void: _piano_add(g))
		row.add_child(b)
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 24)
	Ui.place(row2, 0, 1, 1, 1, 20, -130, -20, -50)
	_piano_panel.add_child(row2)
	var ok := Ui.button("VIA! (-%d FIATO)" % int(E.PIANO_COST), Ui.CYAN, 28, 300)
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(_piano_go)
	row2.add_child(ok)
	var no := Ui.button("ANNULLA", Ui.PINK, 28, 200)
	no.focus_mode = Control.FOCUS_NONE
	no.pressed.connect(_piano_close)
	row2.add_child(no)
	_piano_refresh()


func _preview_text() -> String:
	var p: Dictionary = eng.preview()
	if p.has("kind"):
		var c: String = (" " + str(p["color"]).to_upper()) if p["color"] != "" else ""
		return "In arrivo: %s%s fra %.1f s" % [str(p["kind"]).to_upper(), c, float(p["left"])]
	return "Il nemico è %s · distanza %.1f" % [{"idle": "fermo", "stun": "stordito", "rec": "scoperto", "air": "in aria", "down": "a terra", "crollo": "in CROLLO"}.get(p["enemy"], p["enemy"]), float(p["dist"])]


func _piano_add(g: String) -> void:
	if _piano_list.size() < 3:
		_piano_list.append(g)
	_piano_refresh()


func _piano_refresh() -> void:
	var names: Dictionary = {"tocco": "COLPO", "verso": "AFFONDO", "su": "SU", "giu": "GIÙ", "via": "INDIETRO", "postura": "POSTURA", "carica": "CARICA", "cambio": "CAMBIO"}
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
	Ui.place(pc, 0.5, 0.5, 0.5, 0.5, -420, -300, 420, 300)
	ui.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var t := Ui.label(title, 44, Ui.YELLOW, Ui.display(), 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if ended:
		var s := Ui.label("Tempo %d s · Registro %d/%d" % [int(eng.time), eng.found.size(), E.DISCOVERIES.size()], 24, WHITE, Ui.display(), 5)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	v.add_child(grid)
	for d in E.DISCOVERIES:
		var got: bool = eng.found.has(d[0])
		grid.add_child(Ui.label(("✓ " + d[1]) if got else "???", 22, Ui.CYAN if got else Color("#7d7397"), Ui.display(), 4))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	if not ended:
		var go := Ui.button("RIPRENDI", Ui.CYAN, 24, 200)
		go.pressed.connect(_toggle_pause)
		row.add_child(go)
	var again := Ui.button("RIPROVA", Ui.YELLOW, 24, 200)
	again.pressed.connect(func() -> void: _main().go("prova_iso"))
	row.add_child(again)
	var menu := Ui.button("MENU", Ui.PINK, 24, 160)
	menu.pressed.connect(func() -> void: _main().go("menu"))
	row.add_child(menu)
	return pc


func _end(won: bool) -> void:
	Engine.time_scale = 1.0
	await get_tree().create_timer(0.9).timeout
	_end_panel = _registro_panel("VITTORIA" if won else "SCONFITTA", true)


func _main() -> Node:
	return get_parent()


# ================================================================ gesti

func _gesture(g: String) -> void:
	if paused or in_piano or eng.over != "":
		return
	if _hint_slow and g in ["verso", "su"]:
		Engine.time_scale = 1.0
		_hint_slow = false
	eng.input(g)


func _switch(i: int) -> void:
	if paused or in_piano or eng.over != "":
		return
	eng.cancel_press()
	eng.switch_to(i)


func _press() -> void:
	if paused or in_piano or eng.over != "":
		return
	eng.press_attack()


func _release() -> void:
	if paused or in_piano or eng.over != "":
		eng.cancel_press()
		return
	eng.release_attack()


func _swipe(from: Vector2, to: Vector2) -> void:
	var dd: Vector2 = to - from
	_trail.append([from, to, 0.25])
	var g: String
	if absf(dd.x) >= absf(dd.y):
		g = "verso" if dd.x > 0.0 else "via"
	else:
		g = "giu" if dd.y > 0.0 else "su"
	# durante la carica: indietro annulla, ogni altro scorrimento la scarica subito
	if eng.st in ["charge", "hover"] and g != "via":
		eng.holding = true
		eng.release_attack()
		return
	eng.cancel_press()
	_gesture(g)


func _road_dir() -> Vector2:
	# la direzione "verso il nemico" sullo schermo: in isometrica la strada è in diagonale
	var a: Vector2 = cam.unproject_position(Vector3(0, 0, 0))
	var b: Vector2 = cam.unproject_position(Vector3(1, 0, 0))
	return (b - a).normalized()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var k: Key = (event as InputEventKey).keycode
		if k == KEY_J:
			if event.pressed:
				_press()
			else:
				_release()
			return
		if not event.pressed:
			return
		match k:
			KEY_D, KEY_RIGHT: _gesture("verso")
			KEY_A, KEY_LEFT: _gesture("via")
			KEY_W, KEY_UP, KEY_SPACE: _gesture("su")
			KEY_S, KEY_DOWN: _gesture("giu")
			KEY_K, KEY_Q: _gesture("postura")
			KEY_E, KEY_TAB: _switch(eng.next_alive())
			KEY_1, KEY_2, KEY_3, KEY_4: _switch(int(k) - int(KEY_1))
			KEY_P, KEY_F: _open_piano()
			KEY_ESCAPE: _toggle_pause()
		return
	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.button_index == JOY_BUTTON_X:
			if jb.pressed:
				_press()
			else:
				_release()
			return
		if not jb.pressed:
			return
		match jb.button_index:
			JOY_BUTTON_B, JOY_BUTTON_DPAD_RIGHT: _gesture("verso")
			JOY_BUTTON_DPAD_LEFT: _gesture("via")
			JOY_BUTTON_A, JOY_BUTTON_DPAD_UP: _gesture("su")
			JOY_BUTTON_DPAD_DOWN: _gesture("giu")
			JOY_BUTTON_Y: _gesture("postura")
			JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER: _switch(eng.next_alive())
			JOY_BUTTON_BACK: _open_piano()
			JOY_BUTTON_START: _toggle_pause()
		return
	# tocco: giù = inizia a caricare; lo scorrimento parte appena il dito supera la soglia (il CONTRO non aspetta il rilascio)
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _touches.size() >= 1:
				# secondo dito: postura
				for kk in _touches:
					_touches[kk]["used"] = true
				_touches[st.index] = {"from": st.position, "t": Time.get_ticks_msec(), "used": true}
				eng.cancel_press()
				_gesture("postura")
			else:
				_touches[st.index] = {"from": st.position, "t": Time.get_ticks_msec(), "used": false}
				_press()
		else:
			var tt: Dictionary = _touches.get(st.index, {})
			_touches.erase(st.index)
			if not tt.is_empty() and not tt["used"]:
				_trail.append([st.position, st.position, 0.15])
				_release()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		var tt2: Dictionary = _touches.get(sd.index, {})
		if not tt2.is_empty() and not tt2["used"] and sd.position.distance_to(tt2["from"]) >= SWIPE_MIN:
			tt2["used"] = true
			_swipe(tt2["from"], sd.position)
	# mouse sul computer (non quello simulato dal tocco): sinistro = colpo (tieni per caricare, trascina = scorri); destro = verso
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_gesture("verso")
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_from = mb.position
				_press()
			elif _mouse_from != Vector2.INF:
				_mouse_from = Vector2.INF
				_release()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_from != Vector2.INF:
		var mm := event as InputEventMouseMotion
		if mm.position.distance_to(_mouse_from) >= SWIPE_MIN:
			_swipe(_mouse_from, mm.position)
			_mouse_from = Vector2.INF
