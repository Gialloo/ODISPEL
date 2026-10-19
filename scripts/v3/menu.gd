extends Control

# Menu iniziale: continua / nuova partita / capitoli, prova diretta del combattimento, impostazioni, info dispositivo.

var _t: float = 0.0
var _bg: Control


func crumb() -> String:
	return "menu"


func _ready() -> void:
	Breadcrumb.mark("menu")
	# il menu sta sotto un Node (non un Control): la misura si prende dalla finestra
	_fit()
	get_viewport().size_changed.connect(_fit)
	_bg = Control.new()
	Ui.place(_bg, 0, 0, 1, 1)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.draw.connect(_draw_bg)
	add_child(_bg)

	var col := VBoxContainer.new()
	Ui.place(col, 0.07, 0.07, 0.62, 0.93, 0, 0, 0, 0)
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	var title := Ui.label(GameConfig.TITLE, 100, Ui.CREAM, Ui.names(), 14)
	col.add_child(title)
	var sub := Ui.label(GameConfig.SUBTITLE, 30, Ui.YELLOW, Ui.display(), 8)
	col.add_child(sub)
	var ver := Ui.label("versione %s · prova tecnica per telefono" % GameConfig.VERSION, 20, Color(1, 1, 1, 0.7), null, 4)
	col.add_child(ver)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)

	var note: String = Breadcrumb.crash_note()
	if note != "":
		var n := Ui.label("ATTENZIONE: " + note + " Se è un crash, scrivi a Claude cosa stavi facendo.", 20, Ui.YELLOW, null, 4)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(n)

	var cont: bool = Story.has_save()
	if cont:
		var bc := Ui.button("CONTINUA", Ui.YELLOW, 34, 380)
		bc.pressed.connect(func() -> void:
			Story.load_game()
			_main().next_story())
		col.add_child(bc)
	var b1 := Ui.button("NUOVA PARTITA", Ui.CREAM if cont else Ui.YELLOW, 28 if cont else 34, 380)
	b1.pressed.connect(func() -> void:
		Story.new_game()
		_main().next_story())
	col.add_child(b1)
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	col.add_child(row1)
	var b2 := Ui.button("CAPITOLI", Ui.CYAN, 22, 185)
	b2.pressed.connect(_open_chapters)
	row1.add_child(b2)
	var b5 := Ui.button("BATTAGLIA", Ui.CREAM, 22, 185)
	b5.pressed.connect(func() -> void: _main().go("battle", {"from": "menu"}))
	row1.add_child(b5)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	col.add_child(row2)
	var b3 := Ui.button("IMPOSTAZIONI", Ui.CREAM, 22, 185 if not OS.has_feature("mobile") else 380)
	b3.pressed.connect(_open_settings)
	row2.add_child(b3)
	if not OS.has_feature("mobile"):
		var b4 := Ui.button("ESCI", Color("#ff7a9c"), 22, 185)
		b4.pressed.connect(func() -> void: _main().quit())
		row2.add_child(b4)
	for b in col.get_children():
		if b is Button:
			(b as Button).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var info := Ui.label(_device_info(), 16, Color(1, 1, 1, 0.55), null, 3)
	Ui.place(info, 0.0, 1.0, 1.0, 1.0, 24, -34, 0, -8)
	add_child(info)


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func _device_info() -> String:
	var gpu: String = RenderingServer.get_video_adapter_name()
	return "%s · %s · Godot %s · Compatibility (GLES3) · GPU: %s" % [OS.get_name(), OS.get_model_name(), Engine.get_version_info()["string"], gpu]


func _main() -> Node:
	return get_parent()


# Salta a un capitolo (per provare e correggere senza rigiocare tutto)
func _open_chapters() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.05, 0.85)
	Ui.place(shade, 0, 0, 1, 1)
	add_child(shade)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	Ui.place(vb, 0.5, 0.1, 0.5, 0.95, -330, 0, 330, 0)
	shade.add_child(vb)
	var t := Ui.label("CAPITOLI", 36, Ui.YELLOW, Ui.display(), 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var chs: Array = Story.chapters()
	for i in chs.size():
		var b := Ui.button(str(chs[i].get("titolo", "")), Ui.CREAM, 20, 640)
		var title: String = str(chs[i].get("titolo", ""))
		# saltare a un capitolo sovrascrive il salvataggio: col salvataggio gia' avviato si chiede conferma (secondo tocco)
		b.pressed.connect(func() -> void:
			if _progress_saved() and not b.has_meta("ok"):
				b.set_meta("ok", true)
				b.text = "PERDI I PROGRESSI. TOCCA DI NUOVO PER CONFERMARE"
				b.add_theme_color_override("font_color", Color("#c0143c"))
				get_tree().create_timer(3.0).timeout.connect(func() -> void:
					if is_instance_valid(b):
						b.remove_meta("ok")
						b.text = title
						b.remove_theme_color_override("font_color"))
				return
			Story.load_game()
			Story.start_chapter(i)
			_main().next_story())
		vb.add_child(b)
	var c := Ui.button("CHIUDI", Color("#ff7a9c"), 20, 640)
	c.pressed.connect(shade.queue_free)
	vb.add_child(c)


# C'e' una partita gia' avanzata (non solo l'inizio)?
func _progress_saved() -> bool:
	if not Story.has_save():
		return false
	var cfg := ConfigFile.new()
	if cfg.load(Story.save_path) != OK:
		return false
	return int(cfg.get_value("storia", "capitolo", 0)) > 0 or int(cfg.get_value("storia", "passo", 0)) > 0


func _open_settings() -> void:
	var p := SettingsPanel.new()
	add_child(p)


func back() -> void:
	_main().quit()


func _process(delta: float) -> void:
	_t += delta
	_bg.queue_redraw()


# Sfondo pop: notte viola, fasce oblique che scorrono, quattro silhouette di colore (i protagonisti)
func _draw_bg() -> void:
	var s: Vector2 = _bg.size
	_bg.draw_rect(Rect2(Vector2.ZERO, s), Color("#140b24"))
	var cols: Array = [Color("#e8343f"), Color("#39b7ff"), Color("#8e3df0"), Color("#2f8f5a")]
	for i in 4:
		var x: float = s.x * (0.56 + 0.11 * i) + sin(_t * 0.7 + i) * 6.0
		var w: float = s.x * 0.085
		var pts := PackedVector2Array([Vector2(x, s.y), Vector2(x + w, s.y), Vector2(x + w + s.x * 0.12, 0), Vector2(x + s.x * 0.12, 0)])
		_bg.draw_colored_polygon(pts, Color(cols[i].r, cols[i].g, cols[i].b, 0.55))
	var off: float = fmod(_t * 60.0, 80.0)
	for k in range(-2, int(s.x / 80.0) + 4):
		var x0: float = k * 80.0 + off
		_bg.draw_line(Vector2(x0, s.y), Vector2(x0 + 220, s.y - 220), Color(1, 1, 1, 0.04), 18.0)
	_bg.draw_rect(Rect2(0, s.y * 0.86, s.x, s.y * 0.14), Color(0.03, 0.02, 0.06, 0.8))
