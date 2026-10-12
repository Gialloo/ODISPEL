class_name GachaGuide
extends Control

# Guida al reclutamento: valute, rarita', copie e garanzie. Le cifre arrivano dal
# codice del gioco (BattleContent, Recruiting), quindi non si possono dimenticare
# indietro se si cambia il bilanciamento. Si apre sopra la schermata con
# GachaGuide.open(nodo), o da sola la prima volta (Settings.should_show_gacha_guide).

signal closed

var page: int = 0
var heading: String = "COME FUNZIONA IL RECLUTAMENTO"
var _custom_pages: Array = []
var _title: Label
var _body: VBoxContainer
var _count: Label
var _prev: Button
var _next: Button


static func open(host: Node) -> GachaGuide:
	var g := GachaGuide.new()
	host.add_child(g)
	return g


# Stessa finestra con altre pagine (es. StrategyInfo.pages()): non tocca la "guida vista" del reclutamento.
static func open_pages(host: Node, title: String, custom: Array) -> GachaGuide:
	var g := GachaGuide.new()
	g.heading = title
	g._custom_pages = custom
	host.add_child(g)
	return g


func _page_list() -> Array:
	return _custom_pages if not _custom_pages.is_empty() else pages()


# Pagine: [{title, lines: [{text, color}]}]. Funzione statica, cosi' si prova nei test.
static func pages() -> Array:
	var rar: Array = BattleTypes.RARITIES
	var odds: Array = BattleContent.rarity_odds()
	var out: Array = []

	out.append({"title": "LE VALUTE", "lines": [
		_line("MONETE", BattleTheme.GOLD),
		_line("Le prendi vincendo i boss (di piu' a DIFFICILE e INCUBO) e con gli obiettivi di oggi. Anche se perdi ne ottieni un po'."),
		_line("Servono per RECLUTARE (%d per uno, %d per dieci) e per POTENZIARE operatori e pezzi." % [Recruiting.SINGLE_COST, Recruiting.TEN_COST]),
		_line("NUCLEI", BattleTheme.CY),
		_line("Cadono dai boss e dagli obiettivi. Servono, con le monete, per far salire di LIVELLO un operatore."),
		_line("LEGHE", BattleTheme.CY),
		_line("Cadono dai boss e dagli obiettivi. Servono, con le monete, per potenziare i PEZZI di equipaggiamento."),
		_line("Niente denaro vero: tutto si guadagna giocando.", BattleTheme.CY_DIM),
	]})

	var rows: Array = [_line("Ogni reclutamento estrae una rarita':")]
	for i in rar.size():
		var bonus: int = int(round((float(BattleContent.RARITY_STAT_MULT[i]) - 1.0) * 100.0))
		rows.append(_line("%-12s %2d%%   forza base +%d%%" % [str(rar[i]).to_upper(), int(odds[i]), bonus], BattleTheme.rarity_color(i)))
	rows.append(_line("Piu' e' rara, piu' l'operatore e' forte. Le altre cose le decidono classe, livello e rank."))
	var gear: Array = []
	for i in rar.size():
		gear.append("x%.1f" % float(BattleContent.GEAR_RARITY_MULT[i]))
	rows.append(_line("L'EQUIPAGGIAMENTO segue la stessa scala: " + " / ".join(gear) + ", e un pezzo raro sale piu' in alto di livello (max " + "/".join(PackedStringArray(BattleContent.GEAR_MAX_LEVEL.map(func(v): return str(v)))) + ")."))
	out.append({"title": "LE RARITA'", "lines": rows})

	out.append({"title": "COPIE E GARANZIE", "lines": [
		_line("Esce un operatore che hai gia'? Sale di RANK: +%d%% di statistiche a rank, fino al rank %d." % [int(round(BattleContent.RANK_BONUS * 100.0)), RosterState.MAX_RANK]),
		_line("A rank massimo la copia diventa monete: %d x (rarita' + 1)." % Recruiting.REFUND_PER_RARITY),
		_line("RECLUTA x10 costa %d invece di %d e garantisce almeno un RARO." % [Recruiting.TEN_COST, Recruiting.SINGLE_COST * 10]),
		_line("GARANZIA: se per %d reclutamenti di fila non esce un EPICO o un LEGGENDARIO, il successivo e' almeno EPICO." % Recruiting.PITY_LIMIT),
		_line("Il contatore resta salvato: non si azzera chiudendo il gioco.", BattleTheme.CY_DIM),
	]})

	var roster_lines: Array = []
	for i in range(rar.size() - 1, -1, -1):
		var names: Array = []
		for id in BattleContent.CHARACTERS:
			var def: Dictionary = BattleContent.CHARACTERS[id]
			if int(def["rarity"]) == i:
				names.append("%s (%s)" % [str(def["name"]), str(def["cls"])])
		roster_lines.append(_line("%s: %s" % [str(rar[i]).to_upper(), ", ".join(PackedStringArray(names))], BattleTheme.rarity_color(i)))
	roster_lines.append(_line("STRIKER colpisce forte, VANGUARD regge i colpi, WARDEN cura e protegge.", BattleTheme.CY_DIM))
	out.append({"title": "GLI OPERATORI", "lines": roster_lines})
	return out


static func _line(text: String, color: Color = BattleTheme.WH) -> Dictionary:
	return {"text": text, "color": color}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := HudPanel.new().setup(heading, BattleTheme.RD)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -520.0
	panel.offset_right = 520.0
	panel.offset_top = -330.0
	panel.offset_bottom = 330.0
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.set_content(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	_title = BattleTheme.make_label("", 30, BattleTheme.WH, true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_count = BattleTheme.make_label("", 16, BattleTheme.CY_DIM)
	head.add_child(_count)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_body)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	col.add_child(nav)
	_prev = _nav_button(nav, "INDIETRO", "normal")
	_prev.pressed.connect(show_page.bind(-1, true))
	var close := _nav_button(nav, "CHIUDI", "normal")
	close.pressed.connect(_close)
	_next = _nav_button(nav, "AVANTI", "primary")
	_next.pressed.connect(show_page.bind(1, true))
	show_page(0, false)


func _nav_button(parent: Control, text: String, kind: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 54)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BattleTheme.style_button(b, kind, 22)
	b.focus_mode = Control.FOCUS_NONE
	parent.add_child(b)
	return b


# delta = di quante pagine ci si sposta (relative = true) oppure la pagina da aprire.
func show_page(delta: int, relative: bool = true) -> void:
	var all: Array = _page_list()
	page = clampi(page + delta if relative else delta, 0, all.size() - 1)
	var data: Dictionary = all[page]
	_title.text = str(data["title"])
	_count.text = "%d / %d" % [page + 1, all.size()]
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	for l in data["lines"]:
		var lab := BattleTheme.make_label(str(l["text"]), 22 if TouchUi.active() else 19, l["color"])
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body.add_child(lab)
	_prev.disabled = page == 0
	_next.disabled = page == all.size() - 1


func _close() -> void:
	if _custom_pages.is_empty():
		Settings.finish_gacha_guide()
	closed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_close()
			KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER:
				if page == _page_list().size() - 1:
					_close()
				else:
					show_page(1, true)
			KEY_LEFT:
				show_page(-1, true)
		get_viewport().set_input_as_handled()
