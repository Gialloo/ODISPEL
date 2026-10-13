extends CanvasLayer

# Autoload "Feedback": tutto cio' che avvisa il giocatore sopra le schermate.
#  - avvisi (toast) impilati in alto al centro
#  - icona di attivita' con testo (in basso a destra) per i micro-caricamenti
#  - indicatore di salvataggio
#  - schermata di caricamento a tutto schermo con consigli
# Si usa tramite la classe Notify.

const TIPS: Array = [
	"Il telegrafo in alto a destra mostra la mossa del boss: guardalo prima di scegliere.",
	"PROVOCA obbliga gli attacchi a bersaglio singolo a colpire chi la usa.",
	"I colori contano: un colpo del colore giusto fa molti piu' danni.",
	"Cambiare operatore e' gratis e avviene prima di tutto: usalo per salvare chi sta per cadere.",
	"Il Tombino cura se stesso: concentra i danni e non lasciargli tempo.",
	"Il Semaforo cambia colore: ROSSO colpisce forte uno solo, VERDE tutti insieme.",
	"Potenzia l'operatore guida: e' quello che tutti vedono nella lobby.",
	"Ai livelli DIFFICILE e INCUBO i premi e i drop sono molto migliori.",
	"In multiplayer puoi consultare squadra ed equipaggio mentre aspetti gli altri.",
	"La SFIDA DEL GIORNO paga premi x3: vincila ogni giorno per far crescere la serie.",
	"Nel CICLO INFINITO i PV passano da un piano all'altro: scegli bene i potenziamenti.",
	"I MARCHI si accumulano sul boss: ogni marchio e' +10% di danno per tutta la squadra.",
	"L'aura delle Rondini potenzia l'attacco successivo: dopo averlo usato serve qualche round per ricaricarla.",
	"Il tasto indietro del telefono apre la PAUSA in battaglia.",
]

const TOAST_COLORS: Array = [BattleTheme.CY, BattleTheme.OK, BattleTheme.GOLD, BattleTheme.RD]
const MAX_TOASTS: int = 4
const MIN_LOADING_SECONDS: float = 0.5
const WIPE_SECONDS: float = 0.22

# attivita' in corso: nome -> testo (l'ultima inserita e' quella mostrata)
var _jobs: Dictionary = {}
var _saved_left: float = 0.0
var _saved_ok: bool = true

var _root: Control
var _toasts: VBoxContainer
var _spinner_box: HBoxContainer
var _spinner: Control
var _spinner_label: Label
var _loading: Control
var _loading_title: Label
var _loading_tip: Label
var _loading_bar: ColorRect
var _loading_fill: ColorRect
var _wipe: Wipe
var _busy_transition: bool = false
var _angle: float = 0.0


class Spinner extends Control:
	var done: bool = false
	var failed: bool = false
	var angle: float = 0.0

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.4
		if done:
			var col: Color = BattleTheme.RD if failed else BattleTheme.OK
			if failed:
				draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), col, 3.0)
				draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.6, -r * 0.6), col, 3.0)
			else:
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, 0), c + Vector2(-r * 0.15, r * 0.5), c + Vector2(r * 0.65, -r * 0.5)]), col, 3.0)
			return
		draw_arc(c, r, 0.0, TAU, 24, BattleTheme.CY_DARK, 3.0)
		draw_arc(c, r, angle, angle + TAU * 0.28, 12, BattleTheme.CY, 3.0)


# Stacco diagonale a tre bande (rosso, bianco, nero) come nei menu di Persona.
# cover: quanto lo schermo e' coperto, da sinistra (0..1); reveal: quanto e' stato riscoperto.
class Wipe extends Control:
	const SLANT: float = 240.0
	const BANDS: Array = [BattleTheme.RD, BattleTheme.WH, BattleTheme.BK]
	var cover: float = 0.0:
		set(v):
			cover = v
			queue_redraw()
	var reveal: float = 0.0:
		set(v):
			reveal = v
			queue_redraw()

	func _edge(k: float) -> float:
		return lerpf(-SLANT, size.x + SLANT, clampf(k, 0.0, 1.0))

	func _draw() -> void:
		if cover <= 0.0:
			return
		var h: float = size.y
		for i in BANDS.size():
			var end_x: float = _edge(cover * 1.5 - float(i) * 0.25)
			var start_x: float = _edge(reveal * 1.5 - float(BANDS.size() - 1 - i) * 0.25)
			if end_x <= start_x:
				continue
			draw_colored_polygon(PackedVector2Array([
				Vector2(start_x + SLANT, 0.0), Vector2(end_x + SLANT, 0.0),
				Vector2(end_x, h), Vector2(start_x, h)]), BANDS[i])


func _init() -> void:
	layer = 100
	name = "Feedback"


# Il tasto "indietro" di Android diventa ESC: ogni schermata lo gestisce come gia' fa con la tastiera.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# chiusura della finestra (X, Alt+F4): prima si chiede conferma
		ExitGuard.ask(null)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		for pressed in [true, false]:
			var ev := InputEventKey.new()
			ev.keycode = KEY_ESCAPE
			ev.physical_keycode = KEY_ESCAPE
			ev.pressed = pressed
			Input.parse_input_event(ev)


var _safe: Control
var _fps_label: Label
var _fps_acc: float = 0.0


func safe_layer() -> Node:
	return _safe if _safe != null else self


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)    # la chiusura passa dalla domanda "Vuoi uscire?"
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.build()
	add_child(_root)
	_safe = ScreenFrame.safe_holder(_root)
	_build_toasts()
	_build_fps()
	_build_spinner()
	_build_loading()
	_wipe = Wipe.new()
	_wipe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_STOP
	_wipe.visible = false
	_root.add_child(_wipe)


# Contatore dei fotogrammi (si accende dalle impostazioni): serve a capire se il telefono tiene il ritmo.
func _build_fps() -> void:
	_fps_label = BattleTheme.make_label("", 15, BattleTheme.OK)
	_fps_label.position = Vector2(8.0, 4.0)
	_fps_label.add_theme_color_override("font_outline_color", BattleTheme.BK)
	_fps_label.add_theme_constant_override("outline_size", 4)
	_fps_label.visible = false
	_safe.add_child(_fps_label)


func refresh_fps() -> void:
	if _fps_label != null:
		_fps_label.visible = Settings.show_fps


func _build_toasts() -> void:
	_toasts = VBoxContainer.new()
	_toasts.add_theme_constant_override("separation", 6)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.anchor_left = 0.5
	_toasts.anchor_right = 0.5
	_toasts.offset_left = -185.0
	_toasts.offset_right = 185.0
	_toasts.offset_top = 10.0
	_toasts.offset_bottom = 300.0
	_safe.add_child(_toasts)


func _build_spinner() -> void:
	_spinner_box = HBoxContainer.new()
	_spinner_box.add_theme_constant_override("separation", 8)
	_spinner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spinner_box.alignment = BoxContainer.ALIGNMENT_END
	_spinner_box.anchor_left = 1.0
	_spinner_box.anchor_right = 1.0
	_spinner_box.anchor_top = 1.0
	_spinner_box.anchor_bottom = 1.0
	_spinner_box.offset_left = -440.0
	_spinner_box.offset_right = -14.0
	_spinner_box.visible = false
	_safe.add_child(_spinner_box)

	_spinner_label = BattleTheme.make_label("", 14, BattleTheme.CY)
	_spinner_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_spinner_box.add_child(_spinner_label)

	_spinner = Spinner.new()
	_spinner.custom_minimum_size = Vector2(34, 34)
	_spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spinner_box.add_child(_spinner)
	_place_spinner()


func _build_loading() -> void:
	_loading = Control.new()
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading.visible = false
	_root.add_child(_loading)

	var bg := ColorRect.new()
	bg.color = BattleTheme.BK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.add_child(bg)

	ScreenFx.cctv(_loading)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -330.0
	box.offset_right = 330.0
	box.offset_top = -110.0
	box.offset_bottom = 110.0
	_loading.add_child(box)

	var rec := BattleTheme.make_label("● REC", 16, BattleTheme.RD)
	box.add_child(rec)
	_loading_title = BattleTheme.make_label("CARICAMENTO", 42, BattleTheme.CY, true)
	box.add_child(_loading_title)

	_loading_bar = ColorRect.new()
	_loading_bar.color = BattleTheme.CY_DARK
	_loading_bar.custom_minimum_size = Vector2(0, 14)
	box.add_child(_loading_bar)
	_loading_fill = ColorRect.new()
	_loading_fill.color = BattleTheme.RD
	_loading_fill.size = Vector2(0, 14)
	_loading_bar.add_child(_loading_fill)

	_loading_tip = BattleTheme.make_label("", 16, BattleTheme.WH)
	_loading_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loading_tip.custom_minimum_size = Vector2(660, 50)
	box.add_child(_loading_tip)


# ---------- Avvisi ----------

func show_toast(text: String, kind: int = 0) -> void:
	if _toasts == null:
		return
	while _toasts.get_child_count() >= MAX_TOASTS:
		var oldest: Node = _toasts.get_child(0)
		_toasts.remove_child(oldest)
		oldest.queue_free()

	Snd.play(["toast", "success", "toast", "error"][clampi(kind, 0, 3)])
	var color: Color = TOAST_COLORS[clampi(kind, 0, TOAST_COLORS.size() - 1)]
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", LobbyView._style(color))
	var label := BattleTheme.make_label(text, 15, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(350, 0)
	panel.add_child(label)
	panel.modulate.a = 0.0
	_toasts.add_child(panel)

	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(3.2 + 0.03 * text.length())
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


func toast_count() -> int:
	return _toasts.get_child_count() if _toasts != null else 0


# ---------- Icona di attivita' e salvataggio ----------

func begin_job(job: String, text: String) -> void:
	_jobs.erase(job)
	_jobs[job] = text
	_refresh_spinner()


func end_job(job: String) -> void:
	_jobs.erase(job)
	_refresh_spinner()


func has_job(job: String) -> bool:
	return _jobs.has(job)


func show_saved(ok: bool) -> void:
	_saved_ok = ok
	_saved_left = 1.4
	Snd.play("save" if ok else "error")
	_refresh_spinner()


func _refresh_spinner() -> void:
	if _spinner_box == null:
		return
	var sp: Spinner = _spinner as Spinner
	if not _jobs.is_empty():
		sp.done = false
		_spinner_label.text = str(_jobs[_jobs.keys().back()])
		_spinner_label.add_theme_color_override("font_color", BattleTheme.CY)
		_spinner_box.visible = true
	elif _saved_left > 0.0:
		sp.done = true
		sp.failed = not _saved_ok
		_spinner_label.text = "SALVATO" if _saved_ok else "SALVATAGGIO NON RIUSCITO"
		_spinner_label.add_theme_color_override("font_color", BattleTheme.OK if _saved_ok else BattleTheme.RD)
		_spinner_box.visible = true
	else:
		_spinner_box.visible = false
	sp.queue_redraw()


func spinner_text() -> String:
	return _spinner_label.text if _spinner_box != null and _spinner_box.visible else ""


# Sopra la barra della stanza, se c'e'.
func _place_spinner() -> void:
	var session: Node = get_node_or_null("/root/NetSession")
	var in_room: bool = session != null and session.get("manager") != null
	var bottom: float = -66.0 if in_room else -14.0
	_spinner_box.offset_bottom = bottom
	_spinner_box.offset_top = bottom - 36.0


func _process(delta: float) -> void:
	if _fps_label != null and Settings.show_fps:
		_fps_acc += delta
		if _fps_acc >= 0.25:
			_fps_acc = 0.0
			var fps: int = int(Engine.get_frames_per_second())
			_fps_label.visible = true
			_fps_label.text = "%d FPS" % fps
			_fps_label.add_theme_color_override("font_color", BattleTheme.OK if fps >= 50 else (BattleTheme.POP if fps >= 30 else BattleTheme.RD))
	elif _fps_label != null and _fps_label.visible:
		_fps_label.visible = false
	if _spinner_box == null:
		return
	if _spinner_box.visible:
		_place_spinner()
		var sp: Spinner = _spinner as Spinner
		if not sp.done:
			sp.angle += delta * 6.0
			sp.queue_redraw()
	if _saved_left > 0.0:
		_saved_left -= delta
		if _saved_left <= 0.0:
			_refresh_spinner()


# ---------- Schermata di caricamento ----------

func is_loading() -> bool:
	return _busy_transition


func _wipe_to(property: String, value: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_wipe, property, value, WIPE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


# Stacco diagonale, esegue l'azione (cambio scena) a schermo coperto, mostra la
# schermata di caricamento almeno MIN_LOADING_SECONDS, poi stacco di nuovo e scopre.
func transition(action: Callable, title: String = "CARICAMENTO", tip: String = "") -> void:
	if _busy_transition:
		action.call()
		return

	_busy_transition = true
	_loading_title.text = title
	_loading_tip.text = tip if tip != "" else "CONSIGLIO: " + str(TIPS[randi() % TIPS.size()])
	_loading_fill.size.x = 0.0
	_wipe.cover = 0.0
	_wipe.reveal = 0.0
	_wipe.visible = true
	Snd.play("wipe")

	await _wipe_to("cover", 1.0)

	# a schermo coperto: cambio scena e schermata di caricamento sotto
	action.call()
	_loading.modulate.a = 1.0
	_loading.visible = true
	await _wipe_to("reveal", 1.0)

	var started: int = Time.get_ticks_msec()
	var fill: Tween = create_tween()
	fill.tween_property(_loading_fill, "size:x", _loading_bar.size.x, MIN_LOADING_SECONDS)
	while float(Time.get_ticks_msec() - started) / 1000.0 < MIN_LOADING_SECONDS:
		await get_tree().process_frame

	_wipe.cover = 0.0
	_wipe.reveal = 0.0
	Snd.play("wipe")
	await _wipe_to("cover", 1.0)
	_loading.visible = false
	await _wipe_to("reveal", 1.0)
	_wipe.visible = false
	_busy_transition = false
