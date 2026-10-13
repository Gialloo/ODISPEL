class_name BattleCoach
extends Control

# Prima partita guidata: una cosa alla volta. Ogni passo evidenzia un punto dello schermo e, se chiede
# un'azione, aspetta che il giocatore la faccia davvero; poi passa al successivo. I progressi si salvano
# (Settings.coach_step) e continuano anche nelle partite dopo. SALTA li chiude per sempre.
#
# note(evento, dato) viene chiamato dalla schermata di battaglia: "pick" (mossa scelta, dato = id mossa),
# "swap" (cambio scelto), "round" (un round e' finito).

signal finished

# kind: "pick_attack" | "pick_guard" | "pick_skill" | "swap" | "info" (si avanza col pulsante)
const STEPS: Array = [
	{"kind": "pick_attack", "target": "order0", "title": "1 · ATTACCA",
	"text": "Tocca ATTACCO: e' il comando base e non costa energia."},
	{"kind": "info", "target": "boss", "title": "2 · IL BOSS",
	"text": "Hai tolto integrita' al boss. Quando la barra arriva a zero hai vinto. Sotto meta' va in furia e colpisce piu' forte."},
	{"kind": "pick_guard", "target": "order1", "title": "3 · DIFENDITI",
	"text": "In ALLARME il boss annuncia la sua mossa. Prova la GUARDIA: dimezza i danni di questo round."},
	{"kind": "pick_skill", "target": "order2", "title": "4 · ABILITA'",
	"text": "Le abilita' costano energia (E) ma colpiscono o aiutano di piu'. Provane una."},
	{"kind": "info", "target": "ops", "title": "5 · COLORI E FRECCE",
	"text": "Accanto al nome: ▲ verde = il tuo colore batte quello del boss (+50% danni), ▼ rosso = sei in svantaggio (-33%)."},
	{"kind": "swap", "target": "ops", "title": "6 · CAMBIA OPERATORE",
	"text": "Tocca uno dei compagni in panchina (le caselle in basso): entra in campo gratis, prima di tutti. I guardiani in panchina aiutano comunque."},
	{"kind": "info", "target": "ops", "title": "7 · L'ULTIMATE",
	"text": "Combattendo si riempie la barra rossa: quando compare ULT! l'ultimate e' la tua mossa piu' forte."},
	{"kind": "info", "target": "auto", "title": "8 · AUTOPLAY",
	"text": "Non vuoi scegliere? AUTOPLAY fa combattere l'IA per te. Lo spegni quando vuoi. Buona fortuna!"},
]

var host: Control = null
var index: int = 0
var panel: HudPanel
var title_label: Label
var text_label: Label
var next_button: Button
var _t: float = 0.0
var _done: bool = false
var _wait_round: bool = false       # dopo un'azione si aspetta la fine del round prima del passo successivo


static func active() -> bool:
	Settings.ensure_loaded()
	return Settings.coach_step < STEPS.size() and DisplayServer.get_name() != "headless"


func setup(new_host: Control) -> BattleCoach:
	host = new_host
	index = clampi(Settings.coach_step, 0, STEPS.size() - 1)
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = HudPanel.new().setup("GUIDA", BattleTheme.OK)
	panel.margins = Vector4(14.0, 28.0, 14.0, 10.0)
	panel.position = Vector2(944.0, 516.0)
	panel.size = Vector2(320.0, 180.0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.set_content(box)
	title_label = BattleTheme.make_label("", 20, BattleTheme.WH, true)
	title_label.clip_text = true
	box.add_child(title_label)
	text_label = BattleTheme.make_label("", 14, BattleTheme.CY)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var skip := Button.new()
	skip.text = "SALTA"
	skip.custom_minimum_size = Vector2(96, 38)
	BattleTheme.style_button(skip, "normal", 14)
	skip.pressed.connect(skip_all)
	row.add_child(skip)
	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(0, 38)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BattleTheme.style_button(next_button, "primary", 15)
	next_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_button.pressed.connect(advance)
	row.add_child(next_button)
	_show()


func _step() -> Dictionary:
	return STEPS[clampi(index, 0, STEPS.size() - 1)]


func _show() -> void:
	var s: Dictionary = _step()
	title_label.text = str(s["title"])
	text_label.text = str(s["text"])
	var info: bool = str(s["kind"]) == "info"
	next_button.visible = info
	next_button.text = "AVANTI" if index < STEPS.size() - 1 else "FINE"
	panel.visible = true
	queue_redraw()


func target_control() -> Control:
	if host == null or not is_instance_valid(host):
		return null
	var key: String = str(_step()["target"])
	match key:
		"order0", "order1", "order2":
			var idx: int = int(key.substr(5))
			var list: Variant = host.get("_order_buttons")
			if list is Array and idx < (list as Array).size() and is_instance_valid(list[idx]):
				return list[idx]
		"boss":
			return host.get("_boss_panel") as Control
		"ops":
			return host.get("_ops_panel") as Control
		"auto":
			return host.get("_auto_button") as Control
	return null


# Avanti: salva il progresso.
func advance() -> void:
	if _done:
		return
	index += 1
	_wait_round = false
	Settings.coach_step = index
	Settings.save()
	if index >= STEPS.size():
		_finish()
		return
	_show()


func skip_all() -> void:
	Settings.coach_step = STEPS.size()
	Settings.save()
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()


# Eventi dalla battaglia.
func note(event: String, data: String = "") -> void:
	if _done:
		return
	var kind: String = str(_step()["kind"])
	match event:
		"pick":
			var mk: String = str(BattleContent.MOVES.get(data, {}).get("kind", "basic"))
			if (kind == "pick_attack" and data == "attack") or (kind == "pick_guard" and data == "guard") or (kind == "pick_skill" and (mk == "skill" or mk == "ult")):
				_wait_round = true
				panel.visible = false
				queue_redraw()
		"swap":
			if kind == "swap":
				advance()
		"round":
			if _wait_round:
				advance()


func _process(delta: float) -> void:
	_t += delta
	# durante il round (animazioni) o quando le mosse non si possono dare la guida sta zitta, tranne i passi informativi
	var kind: String = str(_step()["kind"])
	var busy: bool = host != null and (host.get("animating") == true or host.get("locked") == true or host.get("autoplay") == true)
	if not _wait_round and host != null:
		var can_show: bool = kind == "info" or not busy
		if panel.visible != can_show:
			panel.visible = can_show
	queue_redraw()


func _draw() -> void:
	if _done or not panel.visible:
		return
	var t: Control = target_control()
	if t == null or not t.is_visible_in_tree():
		return
	var r: Rect2 = t.get_global_rect()
	r.position -= global_position           # il riquadro dello schermo puo' essere spostato (ScreenFrame)
	r = r.grow(6.0)
	var pulse: float = 0.55 + 0.45 * sin(_t * 5.0)
	draw_rect(r, Color(BattleTheme.OK, pulse), false, 3.0)
	# freccia che collega la guida all'elemento
	var from: Vector2 = panel.position + Vector2(0.0, panel.size.y * 0.3)
	draw_line(from, r.get_center(), Color(BattleTheme.OK, 0.35 * pulse), 2.0)
