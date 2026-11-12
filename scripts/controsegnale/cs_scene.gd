extends Node3D

# CONTROSEGNALE · scena giocabile. Legge il motore (CsBattle) e lo mostra; tutte le regole stanno nel motore.
# Controlli telefono: tre tasti colore grandi a destra (mossa o CONTRO), SCARTO e CAMBIO a sinistra (anche swipe), SET, PAUSA.
# PC: J K L colori, SPAZIO scarto, Q cambio, E set, F finale, 1 2 3 mosse del compagno, ESC pausa.
# Tutorial a tappe (D1, D8): ogni scontro insegna una cosa sola, con una riga di Echo (provvisoria, la rivede la Voce dei personaggi).

const C = preload("res://scripts/controsegnale/cs_content.gd")

const ORDER: Array = ["frammento", "sfondatore", "specchio", "boss_ripetitore"]
const VISUAL: Dictionary = {"frammento": "frammento_giallo", "sfondatore": "cassaforte", "specchio": "manichino", "boss_ripetitore": "semaforo"}
const LESSON: Dictionary = {
	"frammento": "ECHO · Tocca i colori per colpire: si mettono in fila. Quando compare il MIRINO, tocca il SUO colore mentre si chiude: è un CONTRO.",
	"sfondatore": "ECHO · Mirino BIANCO = SFONDA. Non si contra: SCARTO all'ultimo (tasto o scorri il dito).",
	"specchio": "ECHO · Vedi lo SPECCHIO sul cartellino? Contrare quel colore gli ridà SEGNALE. Quello lo scarti.",
	"boss_ripetitore": "ECHO · SET cambia mosse: GUARDIA, CURA, TAG. Il TAG firma il nemico: quel colore fa più male e toglie più segnale.",
}
const COL: Dictionary = {"rosso": Color("#ff3d5a"), "giallo": Color("#ffd23f"), "blu": Color("#3f9dff"), "bianco": Color("#f4f4f4")}
const ENEMY_POS := Vector3(0, 0, -5.5)

var battle: CsBattle
var enemy_id: String = "frammento"
var cam: Camera3D
var hero_vis: Array = []
var enemy_vis: VendingVisual
var ui: CanvasLayer
var _overlay: Control
var _buttons: Dictionary = {}
var _btn_finale: Button
var _hero_labels: Array = []
var _hero_bars: Array = []
var _queue_labels: Array = []
var _enemy_hp: ProgressBar
var _enemy_seg: ProgressBar
var _enemy_name: Label
var _diretta_bar: ProgressBar
var _diretta_lab: Label
var _status: Label
var _stamp: Label
var _lesson: Label
var _end_panel: PanelContainer
var _ampia_panel: PanelContainer
var _swipe_from: Vector2 = Vector2.INF


func configure(args: Dictionary) -> void:
	enemy_id = str(args.get("enemy", "frammento"))


func _ready() -> void:
	battle = CsBattle.new(["lance", "rio"], [enemy_id])
	battle.wide = Settings.parry_wide          # la stessa impostazione della parata a turni
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#120b22")
	env.environment = e
	add_child(env)
	_build_arena()
	cam = Camera3D.new()
	cam.fov = 52.0
	cam.position = Vector3(0, 3.1, 5.2)
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, -3.0))
	cam.current = true
	var xs: Array = [-1.6, 1.6]
	for i in 2:
		var cv := CharacterVisual.new()
		cv.setup(str(battle.heroes[i]["id"]))
		cv.position = Vector3(xs[i], 0.1, 1.2)
		cv.stance = true
		add_child(cv)
		cv.look_at(Vector3(ENEMY_POS.x, cv.position.y, ENEMY_POS.z), Vector3.UP, true)
		hero_vis.append(cv)
	enemy_vis = VendingVisual.new()
	enemy_vis.kind = VISUAL.get(enemy_id, "frammento_giallo")
	enemy_vis.awake = true
	enemy_vis.position = ENEMY_POS
	add_child(enemy_vis)
	_build_ui()
	Sfx.music_start("boss" if enemy_id.begins_with("boss") else "battaglia")


func _build_arena() -> void:
	var floor_m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	floor_m.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#1c1430")
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_m.material_override = fm
	add_child(floor_m)
	# tre insegne al neon, una per frequenza: la strada è il canale della trasmissione
	var xs: Array = [-6.0, 0.0, 6.0]
	var cols: Array = ["rosso", "giallo", "blu"]
	for i in 3:
		var n := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.2, 0.25, 0.1)
		n.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = COL[cols[i]]
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		n.material_override = m
		n.position = Vector3(xs[i], 0.9, -13.0)
		add_child(n)


# ================================================================ UI

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	ui.add_child(_overlay)
	# nemico in alto al centro: nome, VITA, SEGNALE
	var top := VBoxContainer.new()
	Ui.place(top, 0.3, 0.0, 0.7, 0.0, 0, 12, 0, 120)
	ui.add_child(top)
	_enemy_name = Ui.label("", 26, Ui.CREAM, Ui.display(), 6)
	_enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_enemy_name)
	_enemy_hp = _bar(Color("#ff3d8b"), 18)
	top.add_child(_enemy_hp)
	_enemy_seg = _bar(Ui.CYAN, 12)
	top.add_child(_enemy_seg)
	_status = Ui.label("", 20, Ui.YELLOW, Ui.body(), 5)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_status)
	# squadra in alto a sinistra
	var party := VBoxContainer.new()
	Ui.place(party, 0.0, 0.0, 0.0, 0.0, 16, 12, 300, 200)
	ui.add_child(party)
	for i in 2:
		var l := Ui.label("", 22, Ui.CREAM, Ui.names(), 5)
		party.add_child(l)
		_hero_labels.append(l)
		var b := _bar(Color("#5dff9b"), 12)
		party.add_child(b)
		_hero_bars.append(b)
		var q := Ui.label("", 16, Color(1, 1, 1, 0.8), Ui.body(), 4)
		party.add_child(q)
		_queue_labels.append(q)
	# DIRETTA in basso al centro
	var dv := VBoxContainer.new()
	Ui.place(dv, 0.35, 1.0, 0.65, 1.0, 0, -70, 0, -16)
	ui.add_child(dv)
	_diretta_lab = Ui.label("", 20, Ui.PINK, Ui.display(), 5)
	_diretta_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(_diretta_lab)
	_diretta_bar = _bar(Ui.PINK, 14)
	dv.add_child(_diretta_bar)
	# tre tasti colore grandi a destra, a ventaglio
	var pos: Dictionary = {"rosso": Vector2(-500, -140), "giallo": Vector2(-340, -250), "blu": Vector2(-180, -140)}
	for c in C.COLORS:
		var b := Ui.button("", COL[c], 18, 150)
		b.custom_minimum_size = Vector2(150, 110)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.clip_text = true
		Ui.place(b, 1.0, 1.0, 1.0, 1.0, pos[c].x, pos[c].y, pos[c].x + 150, pos[c].y + 110)
		b.button_down.connect(func() -> void: battle.press(c))
		ui.add_child(b)
		_buttons[c] = b
	var bset := Ui.button("SET", Ui.CREAM, 20, 110)
	Ui.place(bset, 1.0, 1.0, 1.0, 1.0, -150, -330, -30, -270)
	bset.pressed.connect(battle.toggle_set)
	ui.add_child(bset)
	_btn_finale = Ui.button("BLACKOUT · FINALE", Ui.YELLOW, 26, 320)
	Ui.place(_btn_finale, 0.5, 0.5, 0.5, 0.5, -170, 60, 170, 130)
	_btn_finale.pressed.connect(battle.finale)
	_btn_finale.visible = false
	ui.add_child(_btn_finale)
	# a sinistra: SCARTO e CAMBIO, e le tre mosse del compagno
	var bd := Ui.button("SCARTO", Ui.CREAM, 24, 170)
	bd.custom_minimum_size = Vector2(170, 100)
	Ui.place(bd, 0.0, 1.0, 0.0, 1.0, 24, -130, 194, -30)
	bd.button_down.connect(battle.dodge)
	ui.add_child(bd)
	var bc := Ui.button("CAMBIO", Ui.CYAN, 20, 140)
	Ui.place(bc, 0.0, 1.0, 0.0, 1.0, 24, -210, 164, -150)
	bc.pressed.connect(battle.swap)
	ui.add_child(bc)
	for i in 3:
		var c: String = C.COLORS[i]
		var pb := Ui.button("•", COL[c], 22, 54)
		Ui.place(pb, 0.0, 1.0, 0.0, 1.0, 180 + i * 62, -210, 234 + i * 62, -150)
		pb.pressed.connect(func() -> void: battle.partner_press(c))
		ui.add_child(pb)
	var bp := Ui.button("II", Ui.CREAM, 22, 70)
	Ui.place(bp, 1.0, 0.0, 1.0, 0.0, -90, 16, -20, 76)
	bp.pressed.connect(func() -> void: battle.set_paused(not battle.paused))
	ui.add_child(bp)
	_stamp = Ui.label("", 64, Ui.YELLOW, Ui.display(), 12)
	_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_stamp, 0.2, 0.32, 0.8, 0.32, 0, 0, 0, 90)
	_stamp.modulate.a = 0.0
	ui.add_child(_stamp)
	_lesson = Ui.label(LESSON.get(enemy_id, ""), 20, Ui.CREAM, Ui.body(), 5)
	_lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.place(_lesson, 0.0, 0.0, 0.0, 0.0, 16, 150, 400, 290)
	ui.add_child(_lesson)
	get_tree().create_timer(9.0).timeout.connect(func() -> void:
		if is_instance_valid(_lesson):
			create_tween().tween_property(_lesson, "modulate:a", 0.0, 0.6))


func _bar(col: Color, h: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	b.add_theme_stylebox_override("fill", fg)
	b.add_theme_stylebox_override("background", bg)
	return b


# ================================================================ ciclo

func _process(delta: float) -> void:
	battle.step(delta)
	for ev in battle.take_events():
		_on_event(ev)
	_refresh()
	_overlay.queue_redraw()


func _refresh() -> void:
	var e: Dictionary = battle.enemies[0]
	var tag: String = ""
	if battle._tag_on(e, str(e["tag"])):
		tag = "  · TAG %s" % str(e["tag"]).to_upper()
	var spec: String = "  · SPECCHIO %s" % str(e["specchio"]).to_upper() if e["specchio"] != "" else ""
	_enemy_name.text = str(e["name"]).to_upper() + tag + spec
	_enemy_hp.max_value = float(e["max"])
	_enemy_hp.value = float(e["hp"])
	_enemy_seg.max_value = float(e["segnale_max"])
	_enemy_seg.value = float(e["segnale"])
	var st: String = ""
	if battle._in_blackout(e):
		st = "BLACKOUT"
	elif int(e["furia_left"]) > 0:
		st = "FURIA"
	if battle.is_slow():
		st += ("  " if st != "" else "") + "RALLENTY"
	if battle.paused:
		st = "PAUSA"
	if st == "":
		st = "SEGNALE %d/%d" % [int(e["segnale"]), int(e["segnale_max"])]
	_status.text = st
	_btn_finale.visible = battle._in_blackout(e) and not e["finale_used"]
	for i in 2:
		var h: Dictionary = battle.heroes[i]
		var mark: String = "▶ " if i == battle.active else "   "
		_hero_labels[i].text = mark + str(h["name"]).to_upper() + ("  KO" if h["ko"] else "") + ("  SET 2" if int(h["set"]) == 2 else "")
		_hero_bars[i].max_value = float(h["max"])
		_hero_bars[i].value = float(h["hp"])
		var names: Array = []
		for q in h["queue"]:
			names.append(str(q["move"]["name"]))
		_queue_labels[i].text = " → ".join(names)
	var s: int = C.step_of(battle.diretta)
	_diretta_lab.text = "DIRETTA x%.2f" % float(C.DIRETTA_MULT[s])
	_diretta_bar.value = battle.diretta
	var ah: Dictionary = battle.heroes[battle.active]
	var set_d: Dictionary = C.HEROES[ah["id"]]["set%d" % int(ah["set"])]
	for c in C.COLORS:
		var m: Dictionary = set_d[c]
		var left: float = float(ah["ready"].get(m["id"], 0.0)) - battle.t
		var b: Button = _buttons[c]
		b.text = str(m["name"]).to_upper() + ("\n%.1f" % left if left > 0.0 else "")
		b.modulate.a = 0.55 if left > 0.0 else 1.0


func _draw_overlay() -> void:
	# MIRINO: anello del colore del colpo che si stringe fino all'impatto; tutti i mirini restano a schermo (D5)
	for i in battle.enemies.size():
		var e: Dictionary = battle.enemies[i]
		var a: Dictionary = e["attack"]
		if a.is_empty():
			continue
		var p: Vector2 = cam.unproject_position(ENEMY_POS + Vector3(0, 1.4, 0))
		var left: float = maxf(0.0, float(a["impact"]) - battle.t)
		var k: float = clampf(left / float(a["windup"]), 0.0, 1.0)
		var col: Color = COL.get(str(a["color"]), Color.WHITE)
		var r_end: float = 46.0
		_overlay.draw_arc(p, r_end, 0, TAU, 48, Color(col, 0.5), 4.0)
		_overlay.draw_arc(p, r_end + 160.0 * k, 0, TAU, 64, col, 9.0)
		if absf(battle.t - float(a["impact"])) <= C.WIN_PERFECT * (C.WIDE_MULT if battle.wide else 1.0):
			_overlay.draw_circle(p, r_end - 6.0, Color(col, 0.6))
		var txt: String = "SFONDA" if a["color"] == C.BIANCO else ("SPECCHIO" if a["color"] == e["specchio"] else str(a["color"]).to_upper())
		_overlay.draw_string(Ui.display(), p + Vector2(-140, -r_end - 24), txt, HORIZONTAL_ALIGNMENT_CENTER, 280, 28, col)


func _on_event(ev: Dictionary) -> void:
	match str(ev["t"]):
		"contro":
			_show_stamp("CONTRO!" if not ev["perfect"] else "PERFETTO!", COL[str(ev["color"])])
			Sfx.word("CLANG", bool(ev["perfect"]))
			enemy_vis.tilt = 0.4
		"blackout":
			_show_stamp("BLACKOUT", Ui.YELLOW)
			Sfx.word("KRAK", true)
			enemy_vis.stunned = true
		"segnale_torna":
			enemy_vis.stunned = false
		"finale":
			_show_stamp("FINALE DI COPPIA", Ui.PINK)
			for cv in hero_vis:
				cv.attack()
		"specchio":
			_show_stamp("SPECCHIO: segnale +%d" % int(C.SEGNALE_SPECCHIO_HEAL), Ui.CREAM)
		"presto":
			_show_stamp("PRESTO", Color(1, 1, 1, 0.8), 0.5)
		"colpito", "sfonda", "colore_sbagliato":
			var hv: CharacterVisual = hero_vis[_hero_index(str(ev["hero"]))]
			hv.hit()
			Sfx.word("THUD")
			if ev["t"] == "sfonda":
				_show_stamp("SFONDA", Color.WHITE)
			elif ev["t"] == "colore_sbagliato":
				_show_stamp("COLORE SBAGLIATO", Ui.CREAM, 0.6)
		"scarto":
			_show_stamp("SCARTO" + (" PERFETTO" if ev["perfect"] else ""), Ui.CYAN, 0.6)
			Sfx.word("SWISH")
		"danno":
			if str(ev["src"]) != "contro" and str(ev["src"]) != "finale":
				hero_vis[battle.active].attack()
				Sfx.word("TAP")
			enemy_vis.hop = 0.25
		"furia":
			_show_stamp("FURIA", Color("#ff5a3d"))
		"fase2":
			_show_stamp("CAMBIO DI FREQUENZA", Ui.VIOLET)
		"tag":
			_show_stamp("TAG " + str(ev["color"]).to_upper(), COL[str(ev["color"])], 0.7)
		"ko":
			hero_vis[_hero_index(str(ev["hero"]))].ko()
		"rialzato":
			hero_vis[_hero_index(str(ev["hero"]))].revive()
		"proponi_ampia":
			_ask_ampia()
		"vittoria":
			enemy_vis.down = true
			_end(true, ev["voto"])
		"sconfitta":
			_end(false, battle.vote())


func _hero_index(id: String) -> int:
	for i in battle.heroes.size():
		if battle.heroes[i]["id"] == id:
			return i
	return 0


func _show_stamp(text: String, col: Color, hold: float = 0.9) -> void:
	_stamp.text = text
	_stamp.add_theme_color_override("font_color", col)
	_stamp.modulate.a = 1.0
	_stamp.scale = Vector2(1.15, 1.15)
	var tw := create_tween()
	tw.tween_property(_stamp, "scale", Vector2.ONE, 0.12)
	tw.tween_interval(hold)
	tw.tween_property(_stamp, "modulate:a", 0.0, 0.25)


# D12: dopo tre colpi mancati Echo propone la finestra AMPIA, senza punire.
func _ask_ampia() -> void:
	battle.set_paused(true)
	_ampia_panel = PanelContainer.new()
	_ampia_panel.add_theme_stylebox_override("panel", Ui.box(Ui.INK, Ui.CYAN))
	Ui.place(_ampia_panel, 0.5, 0.5, 0.5, 0.5, -300, -110, 300, 110)
	var v := VBoxContainer.new()
	_ampia_panel.add_child(v)
	var l := Ui.label("ECHO · Il segnale ti scappa? Allargo la finestra del CONTRO.", 22, Ui.CREAM, Ui.body(), 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var row := HBoxContainer.new()
	v.add_child(row)
	var yes := Ui.button("ALLARGA", Ui.CYAN, 22, 200)
	yes.pressed.connect(func() -> void:
		battle.wide = true
		_close_ampia())
	row.add_child(yes)
	var no := Ui.button("CE LA FACCIO", Ui.CREAM, 22, 220)
	no.pressed.connect(_close_ampia)
	row.add_child(no)
	ui.add_child(_ampia_panel)


func _close_ampia() -> void:
	_ampia_panel.queue_free()
	battle.set_paused(false)


func _end(won: bool, v: Dictionary) -> void:
	Sfx.music_stop(0.8)
	_end_panel = PanelContainer.new()
	_end_panel.add_theme_stylebox_override("panel", Ui.box(Ui.INK, Ui.PINK))
	Ui.place(_end_panel, 0.5, 0.5, 0.5, 0.5, -340, -100, 340, 100)
	var col := VBoxContainer.new()
	_end_panel.add_child(col)
	col.add_child(Ui.label(("VOTO DELLA DIRETTA: %s" % v["voto"]) if won else "SEGNALE PERSO", 40, Ui.YELLOW, Ui.display(), 8))
	col.add_child(Ui.label("tempo %d · danni %d · contro %d · varietà %d · diretta %d" % [v["tempo"], v["danni"], v["contro"], v["varieta"], v["diretta"]], 20, Ui.CREAM, Ui.body(), 3))
	var row := HBoxContainer.new()
	col.add_child(row)
	var again := Ui.button("RIPROVA", Ui.CREAM, 22, 170)
	again.pressed.connect(func() -> void: _main().go("controsegnale", {"enemy": enemy_id}))
	row.add_child(again)
	var idx: int = ORDER.find(enemy_id)
	if won and idx >= 0 and idx < ORDER.size() - 1:
		var nxt := Ui.button("PROSSIMO", Ui.YELLOW, 22, 190)
		nxt.pressed.connect(func() -> void: _main().go("controsegnale", {"enemy": ORDER[idx + 1]}))
		row.add_child(nxt)
	var menu := Ui.button("MENU", Ui.PINK, 22, 140)
	menu.pressed.connect(func() -> void: _main().go("menu"))
	row.add_child(menu)
	ui.add_child(_end_panel)


func _main() -> Node:
	return get_parent()


# ================================================================ tastiera e swipe

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_J: battle.press(C.ROSSO)
			KEY_K: battle.press(C.GIALLO)
			KEY_L: battle.press(C.BLU)
			KEY_SPACE: battle.dodge()
			KEY_Q: battle.swap()
			KEY_E: battle.toggle_set()
			KEY_F: battle.finale()
			KEY_1: battle.partner_press(C.ROSSO)
			KEY_2: battle.partner_press(C.GIALLO)
			KEY_3: battle.partner_press(C.BLU)
			KEY_ESCAPE: battle.set_paused(not battle.paused)
	# swipe in qualsiasi punto libero dello schermo = SCARTO
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_swipe_from = st.position if st.pressed else Vector2.INF
	elif event is InputEventScreenDrag and _swipe_from != Vector2.INF:
		if (event as InputEventScreenDrag).position.distance_to(_swipe_from) > 90.0:
			_swipe_from = Vector2.INF
			battle.dodge()
