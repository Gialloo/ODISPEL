class_name BattleTheme
extends RefCounted

# Stile grafico del combattimento: telecamera di sorveglianza + HUD "arcade".
# Dominante celeste/ciano, accenti rossi aggressivi, bianco e nero.

# PALETTE A COLORI COMPLEMENTARI: ciano (tinta ~188) contro rosso-arancio (tinta ~8), opposti sul cerchio cromatico.
# Ciano = azione/amico/interfaccia, rosso-arancio = pericolo/nemico/attacco. Giallo = solo evidenza (punti focali), verde = esito positivo.
const CY: Color = Color("#7fdcec")        # ciano principale (alleato/interfaccia), un po' meno saturo: Art Bible
const CY_DIM: Color = Color("#a3cfd9")      # testi secondari: chiari, si leggono bene
const CY_DARK: Color = Color("#203a46")
const RD: Color = Color("#f0453c")        # rosso nemico/pericolo (distinto dall'arancio d'impatto)
const RD_DARK: Color = Color("#4d1c24")
const RD_TEXT: Color = Color("#ff6a60")     # rosso per TESTO sui pannelli: piu' chiaro del rosso nemico (il rosso pieno non arriva a contrasto 4,5)
const WH: Color = Color("#F5E9C9")        # avorio luminoso (Art Bible): testi e bordi chiari
const BK: Color = Color("#0b0c12")
const PANEL: Color = Color("#171923")      # carbone urbano (Art Bible)
const OK: Color = Color("#6bffb0")        # esito positivo (verde): solo per scritte di effetto (cure, schivate), mai per le barre
const HP: Color = Color("#d6eef0")        # PV degli alleati: bianco-ciano (rosso sotto il 30%, giallo lo scudo)
# Colori della Art Bible ufficiale (docs/ART_BIBLE.md)
const IMPACT: Color = Color("#FF7438")    # arancio impatto: ultimate pronta, scudi, picchi
const MAGENTA: Color = Color("#E83DCE")   # magenta rituale: segni importanti
const COSMIC: Color = Color("#7770F7")    # viola cosmico: profondita'
const GOLD: Color = Color("#ffd25f")      # evidenza / rarita' alta
const POP: Color = Color("#fff36b")       # giallo dei fumetti
# Stati dei comandi (battaglia PvE e PvP): un solo posto per questi valori.
const BTN_OFF_BG: Color = Color("#2d3140")      # comando non usabile: bordo
const BTN_OFF_TEXT: Color = Color("#9096a6")    # comando non usabile: testo
const BTN_PROGRESS: Color = Color("#d9d2bd")    # riempimento mentre l'ultimate si carica
const BTN_HOVER: Color = Color("#FFF4D6")       # comando usabile: sotto il dito/mouse
const BTN_HOVER_ULT: Color = Color("#ff9a6a")   # ultimate pronta: sotto il dito/mouse
const ICON_OFF: Color = Color("#6b777c")        # icona di un comando non usabile

# Colori di gioco dei personaggi (vantaggi di colore).
const UNIT_COLORS: Dictionary = {
	"rosso": Color("#ff4d6d"),
	"verde": Color("#6bffb0"),
	"blu": Color("#5aa8ff"),
	"giallo": Color("#ffd25f"),
	"viola": Color("#b07bff"),
}

static var _mono: Font = null
static var _display: Font = null
static var _hud: Font = null


static func unit_color(color_name: String) -> Color:
	return UNIT_COLORS.get(color_name, WH)


# GERARCHIA TIPOGRAFICA (tutti i font sono Google Fonts, licenza OFL, vedi assets/fonts/OFL-*.txt):
#   display()  Archivo Black   TITOLI, BOSS, SEZIONI: tutto MAIUSCOLO
#   hud()      Roboto Bold     HUD, STATISTICHE, TIMER, NUMERI: tutto MAIUSCOLO
#   logo()     Libre Caslon Condensed Bold   solo il titolo ODISPEL
#   menu()     Merriweather Bold   pulsanti e menu: Prima maiuscola, resto minuscolo, grassetto
#   mono()     Merriweather Bold   dialoghi, descrizioni, elenchi: Prima maiuscola, resto minuscolo
#   quote()    pensieri e citazioni (per ora come il testo normale)
# (La copia ridotta di Merriweather si chiama OdispelSerif: la licenza vieta di tenere il nome originale se si modifica il font.)
# I font Merriweather sono larghi: la versione "SemiCondensed" a 24 punti ottici tiene i testi corti.
# Le maiuscole/minuscole le sistema TextCase da solo in base al font del testo.
const TEXT_SCALE: float = 1.08
const FONT_DIR: String = "res://assets/fonts/"
static var _cache: Dictionary = {}


static func font(file: String) -> Font:
	if not _cache.has(file):
		_cache[file] = load(FONT_DIR + file + ".ttf")
	return _cache[file]


static func mono() -> Font:
	if _mono == null:
		_mono = font("OdispelSerif-Bold")
	return _mono


# Solo il logo ODISPEL: Libre Caslon Condensed Bold, MAIUSCOLO.
static func logo() -> Font:
	return font("LibreCaslonCondensed-Bold")


static func menu() -> Font:
	return font("OdispelSerif-Bold")


static func display() -> Font:
	if _display == null:
		_display = font("ArchivoBlack-Regular")
	return _display


static func hud() -> Font:
	if _hud == null:
		_hud = font("Roboto-Bold")
	return _hud


# Colpi critici e parole d'effetto: Archivo Black, MAIUSCOLO.
static func crit() -> Font:
	return display()


static func quote() -> Font:
	return font("OdispelSerif-Bold")


static func make_label(text: String, size: int = 16, color: Color = CY, use_display: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", display() if use_display else mono())
	var fsz: int = int(round(float(size) * (1.0 if use_display else TEXT_SCALE)))
	if TouchUi.active():
		fsz = maxi(int(round(float(fsz) * (1.0 if use_display or size >= 26 else 1.15))), 16)    # telefono: testo piccolo piu' grande, mai sotto 16
	l.add_theme_font_size_override("font_size", fsz)
	l.add_theme_color_override("font_color", color)
	if not use_display:
		# ombra netta: il testo piccolo resta leggibile su qualsiasi sfondo
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 1)
	if use_display:
		# contorno nero spesso: il testo "da fumetto" si legge su qualsiasi sfondo
		l.add_theme_color_override("font_outline_color", BK)
		l.add_theme_constant_override("outline_size", maxi(4, size / 7))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _box(bg: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(0)
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


# Gli stili dei pulsanti sono uguali per tutti: si creano una volta per tipo e si condividono.
static var _button_styles: Dictionary = {}


static func _styles_for(kind: String) -> Dictionary:
	if _button_styles.has(kind):
		return _button_styles[kind]
	var normal: SlantBox
	var hover: SlantBox
	var colors: Dictionary
	match kind:
		"primary":
			normal = SlantBox.make(IMPACT, WH, 16.0, BK, 3.0)
			hover = SlantBox.make(WH, IMPACT, 16.0, IMPACT, 3.0)
			colors = {"text": BK, "hover": BK}
		"ultimate":
			normal = SlantBox.make(BK, WH, 16.0, RD, 3.0)
			hover = SlantBox.make(WH, RD, 16.0, BK, 3.0)
			colors = {"text": WH, "hover": RD}
		_:
			normal = SlantBox.make(BK, CY, 14.0, CY_DARK, 2.0)
			hover = SlantBox.make(CY, BK, 14.0, CY_DIM, 2.0)
			colors = {"text": WH, "hover": BK}
	# grana leggera e lucentezza: chiare, cosi' si vedono anche sui colori scuri
	match kind:
		"primary":
			normal.hatch = Color(1, 1, 1, 0.22)
			hover.hatch = Color(0.8, 0.1, 0.2, 0.14)
		"ultimate":
			normal.hatch = Color(1, 1, 1, 0.18)
			hover.hatch = Color(0.8, 0.1, 0.2, 0.14)
		_:
			normal.hatch = Color(CY, 0.17)
			hover.hatch = Color(0, 0.1, 0.15, 0.12)
	normal.gloss = 0.13
	hover.gloss = 0.22
	var styles: Dictionary = {
		"normal": normal,
		"hover": hover,
		"disabled": SlantBox.make(Color(0.02, 0.06, 0.07), CY_DARK, 14.0, Color(0, 0, 0, 0), 2.0),
		"focus": StyleBoxEmpty.new(),
		"text": colors["text"],
		"hover_text": colors["hover"],
	}
	_button_styles[kind] = styles
	return styles


# kind: "primary" (rosso), "normal" (ciano), "ultimate" (bianco su rosso)
# I pulsanti sono parallelogrammi con ombra netta (stile Persona); sotto il mouse
# diventano pieni e si spostano un poco.
static func style_button(b: Button, kind: String = "normal", size: int = 22) -> void:
	var st: Dictionary = _styles_for(kind)
	b.add_theme_stylebox_override("normal", st["normal"])
	b.add_theme_stylebox_override("hover", st["hover"])
	b.add_theme_stylebox_override("pressed", st["hover"])
	b.add_theme_stylebox_override("disabled", st["disabled"])
	b.add_theme_stylebox_override("focus", st["focus"])
	b.add_theme_color_override("font_color", st["text"])
	b.add_theme_color_override("font_hover_color", st["hover_text"])
	b.add_theme_color_override("font_pressed_color", st["hover_text"])
	b.add_theme_color_override("font_disabled_color", Color("#8196a0"))
	b.add_theme_color_override("font_outline_color", BK if kind != "normal" else Color(0, 0, 0, 0.9))
	b.add_theme_constant_override("outline_size", 4 if kind != "normal" else 3)
	b.add_theme_font_override("font", menu())
	b.add_theme_font_size_override("font_size", TouchUi.fit(b, size))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


# Colore di una rarita' (comune, rara, epica, leggendaria).
static func rarity_color(rarity: int) -> Color:
	var colors: Array = [Color("#c9dde2"), CY, UNIT_COLORS["viola"], GOLD]
	return colors[clampi(rarity, 0, colors.size() - 1)]


# Comando di battaglia (PvE e PvP): usabile = avorio con testo nero; non usabile = nero con testo grigio; l'ultimate pronta
# e' arancio. Mentre si carica si riempie di avorio. side_margins = spazio interno sinistro/destro (icona e costo).
static func style_move_button(b: Button, usable: bool, gauge_progress: float, ready_ult: bool = false, side_margins: Vector2 = Vector2.ZERO) -> void:
	var box: SlantBox
	var txt_col: Color
	var outline: int = 0
	if usable:
		box = SlantBox.make(WH, BK, 14.0, Color(0, 0, 0, 0.55), 2.0)
		txt_col = BK
	else:
		box = SlantBox.make(BK, BTN_OFF_BG, 14.0, Color(0, 0, 0, 0.0), 2.0)
		txt_col = BTN_OFF_TEXT
		if gauge_progress > 0.0:
			box.progress = gauge_progress
			box.progress_color = BTN_PROGRESS
			txt_col = WH
			outline = 4
	var hov: SlantBox = box
	if usable:
		hov = SlantBox.make(BTN_HOVER, BK, 14.0, Color(0, 0, 0, 0.55), 2.0)
	if ready_ult:
		box = SlantBox.make(IMPACT, BK, 14.0, Color(0, 0, 0, 0.55), 2.0)
		hov = SlantBox.make(BTN_HOVER_ULT, BK, 14.0, Color(0, 0, 0, 0.55), 2.0)
	if side_margins != Vector2.ZERO:
		for bx in [box, hov]:
			bx.content_margin_left = side_margins.x
			bx.content_margin_right = side_margins.y
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("disabled", box)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(k, txt_col)
	b.add_theme_color_override("font_outline_color", BK)
	b.add_theme_constant_override("outline_size", outline)


# Riquadro piatto nella palette (carta di un giocatore, medaglia della fase): velo carbone + bordo di accento.
static func plate_box(edge: Color, border: int = 2, radius: int = 4, veil: float = 0.78) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PANEL, veil)
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	return sb
