class_name ColorGuide
extends ColorRect

# GUIDA AI COLORI nel menu pausa (autore, 7/11/2026: il tasto COLORI esce dalla battaglia e diventa una voce della pausa,
# con le spiegazioni intere). Tutti i numeri vengono dal motore (BattleTypes), cosi' se cambiano la guida resta giusta.

signal closed

const ORDER: Array = ["rosso", "verde", "blu", "giallo", "viola"]
const NOME: Dictionary = {"rosso": "ROSSO", "verde": "VERDE", "blu": "BLU", "giallo": "GIALLO", "viola": "VIOLA"}
const TXT: int = 20


func _init() -> void:
	color = Color(0.03, 0.01, 0.06, 0.96)
	Ui.place(self, 0, 0, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


static func _pct(m: float) -> int:
	return int(round((m - 1.0) * 100.0))


func _chip(c: String, sz: float = 24.0) -> ColorRect:
	var sq := ColorRect.new()
	sq.color = Ui.BATTLE_COLORS.get(c, Color.WHITE)
	sq.custom_minimum_size = Vector2(sz, sz)
	sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return sq


func _chain(colors: Array, sign: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for i in colors.size():
		if i > 0:
			row.add_child(Ui.label(sign, 24, Ui.CREAM, Ui.display()))
		row.add_child(_chip(str(colors[i]), 30.0))
	return row


func _section(parent: VBoxContainer, title: String, tcol: Color, body: String) -> void:
	parent.add_child(Ui.label(title, 26, tcol, Ui.display(), 6))
	var l := Ui.label(body, TXT, Ui.CREAM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 520
	parent.add_child(l)


func _build() -> void:
	var title := Ui.label("COLORI", 64, Ui.CREAM, Ui.display(), 12)
	title.rotation_degrees = -4.0
	Ui.place(title, 0, 0, 0, 0, 34, 14, 500, 100)
	add_child(title)
	var sub := Ui.label("Chi batte chi, cosa vuol dire DEBOLE A e come i colori aiutano il BREAK", TXT, Color(1, 1, 1, 0.85))
	Ui.place(sub, 0, 0, 1, 0, 40, 96, -40, 126)
	add_child(sub)

	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Ui.place(sc, 0, 0, 1, 1, 40, 140, -40, -100)
	add_child(sc)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 48)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)

	var adv: int = _pct(BattleTypes.COLOR_ADVANTAGE)
	var dis: int = _pct(BattleTypes.COLOR_DISADVANTAGE)
	var w2: int = _pct(BattleTypes.WEAK2_MULT)

	# colonna sinistra: la ruota e le due coppie
	left.add_child(Ui.label("LA RUOTA", 26, Ui.YELLOW, Ui.display(), 6))
	left.add_child(_chain(["rosso", "verde", "blu", "rosso"], ">"))
	var r1 := Ui.label("ROSSO batte VERDE, VERDE batte BLU, BLU batte ROSSO. Si gira sempre nello stesso verso.", TXT, Ui.CREAM)
	r1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r1.custom_minimum_size.x = 520
	left.add_child(r1)
	left.add_child(Ui.label("GIALLO E VIOLA", 26, Ui.YELLOW, Ui.display(), 6))
	left.add_child(_chain(["giallo", "viola"], "<>"))
	var r2 := Ui.label("GIALLO e VIOLA si battono a vicenda: chi colpisce l'altro ha sempre il colore vincente. Con ROSSO, VERDE e BLU sono neutri.", TXT, Ui.CREAM)
	r2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r2.custom_minimum_size.x = 520
	left.add_child(r2)
	_section(left, "NEUTRO", Ui.CREAM, "Stesso colore, oppure colori che non si toccano (ROSSO contro GIALLO, per esempio): danno normale, %d di equilibrio a colpo." % BattleTypes.BREAK_NEUTRAL)

	# colonna destra: debolezze, resistenze, secondo punto debole, la squadra
	_section(right, "DEBOLEZZA · COLORE VINCENTE", Ui.BATTLE_COLORS["verde"],
		"Se il tuo colore batte quello del nemico fai +%d%% di danno e togli %d di equilibrio a colpo invece di %d: arrivi prima al BREAK. Sotto il nome del nemico, DEBOLE A ti dice quale colore usare." % [adv, BattleTypes.BREAK_ADV, BattleTypes.BREAK_NEUTRAL])
	_section(right, "RESISTENZA · COLORE DEBOLE", Ui.BATTLE_COLORS["rosso"],
		"Se e' il nemico a battere il tuo colore fai %d%% di danno e togli solo %d di equilibrio. Meglio far colpire un compagno, o preparare con un marchio." % [dis, BattleTypes.BREAK_DISADV])
	_section(right, "SECONDO PUNTO DEBOLE", Ui.BATTLE_COLORS["giallo"],
		"Alcuni nemici gialli hanno un secondo colore che li ferisce: +%d%% di danno con quel colore. Vale solo se non hai gia' il colore vincente; lo trovi anche lui in DEBOLE A." % w2)
	_section(right, "MARCHIO E BREAK", Ui.CREAM,
		"Su un nemico marchiato ogni colpo toglie %d di equilibrio in piu', di qualsiasi colore. Colore vincente piu' marchio e' la strada piu' corta per il BREAK." % BattleTypes.BREAK_MARKED)
	right.add_child(Ui.label("LA SQUADRA", 26, Ui.YELLOW, Ui.display(), 6))
	for id in ["lance", "nox", "rio", "saul"]:
		var ch: Dictionary = BattleContent.CHARACTERS.get(id, {})
		var c: String = str(ch.get("color", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(_chip(c))
		var forte: String = NOME.get(str(BattleTypes.BEATS.get(c, "")), "")
		var debole: String = ""
		for o in ORDER:
			if str(BattleTypes.BEATS.get(o, "")) == c and str(BattleTypes.BEATS.get(c, "")) != o:
				debole = NOME[o]
		var t: String = "%s · %s: forte contro %s" % [str(ch.get("name", id)).to_upper(), NOME.get(c, c), forte]
		if debole != "":
			t += ", debole contro %s" % debole
		row.add_child(Ui.label(t, TXT, Ui.CREAM))
		right.add_child(row)

	var back := Ui.button("INDIETRO", Ui.CREAM, 26, 240)
	Ui.place(back, 0, 1, 0, 1, 30, -86, 270, -20)
	back.pressed.connect(_close)
	add_child(back)


func _close() -> void:
	closed.emit()
	queue_free()
