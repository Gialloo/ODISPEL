class_name GameIcon
extends Control

# Icone disegnate in codice (segnaposto).
# Servono ad associare un'immagine alla parola: classi, fazioni, tipi di mossa, equipaggiamento, valute.
#
# Chiavi: striker vanguard warden | libracorp rondini magabondi kairos |
#         sword bolt shield heal target taunt bullet cleanse burst passive |
#         arma petto stivali | coin nucleo lega

const KEYS: Array = [
	"striker", "vanguard", "warden", "libracorp", "rondini", "magabondi", "kairos",
	"sword", "bolt", "shield", "heal", "target", "taunt", "bullet", "cleanse", "burst", "passive",
	"arma", "petto", "stivali", "coin", "nucleo", "lega", "book",
	"hp", "balance", "danger", "ko",
]

# Grammatica visiva di ODISPEL (0.24.35): significato stabile -> icona. Un solo posto da consultare.
# famiglia: stato | difesa | pericolo | azione | risorsa | equip. La forma dice COSA e', colore e riempimento dicono lo STATO.
# Il testo esplicito resta per i pericoli critici (rischio di KO): l'icona non lo sostituisce.
const SYMBOLS: Dictionary = {
	"hp": {"family": "stato", "name": "PV", "desc": "Punti vita attuali."},
	"shield": {"family": "difesa", "name": "SCUDO", "desc": "Protezione che assorbe il danno prima dei PV."},
	"balance": {"family": "difesa", "name": "EQUILIBRIO", "desc": "Tenuta del boss: se si svuota il boss si rompe e resta scoperto."},
	"danger": {"family": "pericolo", "name": "PERICOLO", "desc": "Un attacco annunciato rischia di mettere KO qualcuno."},
	"ko": {"family": "pericolo", "name": "K.O.", "desc": "Operatore a terra."},
	"sword": {"family": "azione", "name": "ATTACCO", "desc": "Mossa che infligge danno."},
	"heal": {"family": "azione", "name": "CURA", "desc": "Mossa che ripristina PV."},
	"taunt": {"family": "azione", "name": "PROVOCA", "desc": "Attira su di te il prossimo colpo."},
	"bullet": {"family": "risorsa", "name": "MUNIZIONI", "desc": "Colpi disponibili."},
	"burst": {"family": "risorsa", "name": "ULTIMATE", "desc": "Mossa speciale, pronta a carica piena."},
	"target": {"family": "azione", "name": "BERSAGLIO", "desc": "Mossa che applica uno stato al bersaglio."},
	"cleanse": {"family": "azione", "name": "PURIFICA", "desc": "Toglie gli stati negativi."},
}


static func describe(k: String) -> String:
	var d: Dictionary = SYMBOLS.get(k, {})
	return "" if d.is_empty() else "%s: %s" % [d["name"], d["desc"]]

var key: String = ""
var color: Color = BattleTheme.CY


func setup(new_key: String, new_color: Color = BattleTheme.CY, px: float = 24.0) -> GameIcon:
	key = new_key
	color = new_color
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


# Icona e colore di una mossa, ricavati da cio' che fa.
static func move_key(move_id: String) -> String:
	var m: Dictionary = BattleContent.MOVES.get(move_id, {})
	if m.is_empty():
		return "bolt"
	if str(m.get("kind", "")) == "ult":
		return "burst"
	if m.has("cleanse"):
		return "cleanse"
	if m.has("heal"):
		return "heal"
	if m.has("self_status") and m["self_status"].has("taunt"):
		return "taunt"
	if m.has("shield") or m.has("self_status"):
		return "shield"
	if m.has("ammo") or m.has("ammo_gain"):
		return "bullet"
	if m.has("status"):
		return "target"
	if float(m.get("mult", 1.0)) >= 2.0:
		return "bolt"
	return "sword"


static func move_color(move_id: String) -> Color:
	match move_key(move_id):
		"heal", "cleanse":
			return BattleTheme.OK
		"shield", "taunt":
			return BattleTheme.CY
		"bullet":
			return Hints.faction_color("libracorp")
		"burst":
			return BattleTheme.GOLD
		"target":
			return BattleTheme.WH
		_:
			return BattleTheme.RD


static func faction_key(faction: String) -> String:
	return faction if faction in ["libracorp", "rondini", "magabondi", "kairos"] else ""


static func gear_key(slot: String) -> String:
	return slot if slot in ["arma", "petto", "stivali"] else ""


static func currency_color(k: String) -> Color:
	match k:
		"coin":
			return BattleTheme.GOLD
		"nucleo":
			return BattleTheme.CY
		_:
			return Color("#c9dde2")


# Riga "icona + testo" (risorse, premi, elenchi).
static func line(icon_key: String, col: Color, text: String, font_size: int = 18, text_color: Color = BattleTheme.WH, px: float = 0.0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var size_px: float = px if px > 0.0 else float(font_size) + 4.0
	row.add_child(GameIcon.new().setup(icon_key, col, size_px))
	var l := BattleTheme.make_label(text, font_size, text_color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	return row


# Icona e colore di una riga di premio ("+300 CREDITI", "PEZZO: ARMA RARA", ...).
static func reward_key(text: String) -> Array:
	var t: String = text.to_upper()
	if "CREDITI" in t:
		return ["coin", currency_color("coin")]
	if "NUCLE" in t:
		return ["nucleo", currency_color("nucleo")]
	if "LEGH" in t or "LEGA" in t:
		return ["lega", currency_color("lega")]
	if t.begins_with("MOSSA"):
		return ["bolt", BattleTheme.RD]
	if t.begins_with("PASSIVA"):
		return ["passive", BattleTheme.CY]
	for g in ["ARMA", "PETTO", "STIVALI"]:
		if t.begins_with("PEZZO: " + g):
			return [g.to_lower(), BattleTheme.CY]
	return ["", BattleTheme.CY]


# Mette l'icona a sinistra di un pulsante e lascia lo spazio al testo.
static func attach(b: Button, icon_key: String, col: Color, px: float = 22.0) -> GameIcon:
	var ic := GameIcon.new().setup(icon_key, col, px)
	ic.anchor_top = 0.5
	ic.anchor_bottom = 0.5
	ic.offset_left = 14.0
	ic.offset_right = 14.0 + px
	ic.offset_top = -px * 0.5
	ic.offset_bottom = px * 0.5
	b.add_child(ic)
	var pad: int = int(ceil((px + 8.0) / maxf(float(b.get_theme_font_size("font_size")), 10.0)))
	b.text = " ".repeat(maxi(pad, 1)) + b.text
	return ic


func _ready() -> void:
	resized.connect(queue_redraw)


func _p(x: float, y: float) -> Vector2:
	var s: float = minf(size.x, size.y)
	return Vector2(x * s, y * s) + (size - Vector2(s, s)) * 0.5


func _poly(pts: Array, fill: bool = true, close: bool = true) -> void:
	var v := PackedVector2Array()
	for p in pts:
		v.append(_p(p[0], p[1]))
	var w: float = maxf(minf(size.x, size.y) * 0.08, 1.5)
	if fill:
		draw_colored_polygon(v, Color(color, 0.35))
	if close:
		v.append(v[0])
	draw_polyline(v, color, w, true)


func _line(a: Array, b: Array, width: float = 0.1) -> void:
	draw_line(_p(a[0], a[1]), _p(b[0], b[1]), color, maxf(minf(size.x, size.y) * width, 1.5), true)


func _circle(c: Array, r: float, fill: bool = false) -> void:
	var s: float = minf(size.x, size.y)
	if fill:
		draw_circle(_p(c[0], c[1]), r * s, color)
	else:
		draw_arc(_p(c[0], c[1]), r * s, 0.0, TAU, 28, color, maxf(s * 0.08, 1.5), true)


func _draw() -> void:
	match key:
		"sword", "striker":
			_line([0.28, 0.72], [0.86, 0.14], 0.12)
			_line([0.22, 0.52], [0.48, 0.78], 0.1)
			_line([0.28, 0.72], [0.12, 0.88], 0.1)
		"shield", "vanguard":
			_poly([[0.14, 0.14], [0.86, 0.14], [0.86, 0.5], [0.5, 0.92], [0.14, 0.5]])
			if key == "vanguard":
				_line([0.5, 0.24], [0.5, 0.72], 0.07)
		"heal", "warden":
			_poly([[0.38, 0.1], [0.62, 0.1], [0.62, 0.38], [0.9, 0.38], [0.9, 0.62], [0.62, 0.62], [0.62, 0.9], [0.38, 0.9], [0.38, 0.62], [0.1, 0.62], [0.1, 0.38], [0.38, 0.38]])
		"target":
			_circle([0.5, 0.5], 0.36)
			_circle([0.5, 0.5], 0.08, true)
			_line([0.5, 0.04], [0.5, 0.26], 0.07)
			_line([0.5, 0.74], [0.5, 0.96], 0.07)
			_line([0.04, 0.5], [0.26, 0.5], 0.07)
			_line([0.74, 0.5], [0.96, 0.5], 0.07)
		"taunt":
			_poly([[0.12, 0.4], [0.38, 0.4], [0.84, 0.14], [0.84, 0.86], [0.38, 0.6], [0.12, 0.6]])
			_line([0.26, 0.6], [0.34, 0.88], 0.1)
		"bullet":
			_poly([[0.36, 0.38], [0.5, 0.08], [0.64, 0.38]])
			_poly([[0.36, 0.38], [0.64, 0.38], [0.64, 0.9], [0.36, 0.9]])
			_line([0.36, 0.78], [0.64, 0.78], 0.06)
		"cleanse":
			_poly([[0.5, 0.08], [0.26, 0.56], [0.74, 0.56]], true)
			_circle([0.5, 0.62], 0.26)
		"burst":
			var pts: Array = []
			for i in 16:
				var r: float = 0.46 if i % 2 == 0 else 0.2
				var a: float = TAU * float(i) / 16.0 - PI * 0.5
				pts.append([0.5 + cos(a) * r, 0.5 + sin(a) * r])
			_poly(pts)
		"bolt":
			_poly([[0.58, 0.04], [0.2, 0.56], [0.46, 0.56], [0.36, 0.96], [0.8, 0.4], [0.54, 0.4]])
		"passive":
			_poly([[0.5, 0.06], [0.94, 0.5], [0.5, 0.94], [0.06, 0.5]])
			_line([0.5, 0.7], [0.5, 0.32], 0.08)
			_line([0.34, 0.46], [0.5, 0.3], 0.08)
			_line([0.66, 0.46], [0.5, 0.3], 0.08)
		"libracorp":
			_line([0.5, 0.18], [0.5, 0.86], 0.08)
			_line([0.28, 0.88], [0.72, 0.88], 0.08)
			_line([0.12, 0.26], [0.88, 0.26], 0.08)
			for sx in [0.12, 0.88]:
				_line([sx, 0.26], [sx - 0.1, 0.56], 0.05)
				_line([sx, 0.26], [sx + 0.1, 0.56], 0.05)
				_line([sx - 0.14, 0.58], [sx + 0.14, 0.58], 0.08)
		"rondini":
			_line([0.08, 0.26], [0.5, 0.78], 0.09)
			_line([0.92, 0.26], [0.5, 0.78], 0.09)
			_line([0.26, 0.2], [0.5, 0.5], 0.07)
			_line([0.74, 0.2], [0.5, 0.5], 0.07)
			_circle([0.5, 0.86], 0.06, true)
		"magabondi":
			_circle([0.5, 0.5], 0.42)
			_poly([[0.5, 0.14], [0.62, 0.5], [0.5, 0.86], [0.38, 0.5]])
			_line([0.14, 0.5], [0.86, 0.5], 0.04)
		"book":
			# libro aperto con le righe del testo
			_poly([[0.08, 0.2], [0.46, 0.28], [0.46, 0.9], [0.08, 0.82]])
			_poly([[0.92, 0.2], [0.54, 0.28], [0.54, 0.9], [0.92, 0.82]])
			_line([0.5, 0.2], [0.5, 0.94], 0.05)
			_line([0.16, 0.42], [0.38, 0.47], 0.04)
			_line([0.62, 0.47], [0.84, 0.42], 0.04)
			_circle([0.34, 0.1], 0.1)
			_circle([0.66, 0.1], 0.1)
		"kairos":
			_poly([[0.2, 0.1], [0.8, 0.1], [0.5, 0.5]])
			_poly([[0.5, 0.5], [0.8, 0.9], [0.2, 0.9]])
		"arma":
			_line([0.5, 0.08], [0.5, 0.68], 0.12)
			_line([0.28, 0.7], [0.72, 0.7], 0.09)
			_line([0.5, 0.7], [0.5, 0.94], 0.09)
		"petto":
			_poly([[0.2, 0.14], [0.38, 0.08], [0.5, 0.22], [0.62, 0.08], [0.8, 0.14], [0.88, 0.44], [0.72, 0.92], [0.28, 0.92], [0.12, 0.44]])
		"stivali":
			_poly([[0.3, 0.08], [0.62, 0.08], [0.62, 0.56], [0.92, 0.7], [0.92, 0.92], [0.3, 0.92]])
		"coin":
			_circle([0.5, 0.5], 0.42)
			_circle([0.5, 0.5], 0.26)
			_line([0.5, 0.34], [0.5, 0.66], 0.07)
		"nucleo":
			var hx: Array = []
			for i in 6:
				var a2: float = TAU * float(i) / 6.0
				hx.append([0.5 + cos(a2) * 0.44, 0.5 + sin(a2) * 0.44])
			_poly(hx)
			_circle([0.5, 0.5], 0.14, true)
		"lega":
			_poly([[0.1, 0.74], [0.28, 0.3], [0.72, 0.3], [0.9, 0.74]])
			_line([0.28, 0.3], [0.38, 0.74], 0.05)
			_line([0.72, 0.3], [0.62, 0.74], 0.05)
		"hp":
			# cuore stilizzato (poligono): PV
			_poly([[0.5, 0.92], [0.1, 0.5], [0.1, 0.3], [0.26, 0.12], [0.5, 0.3], [0.74, 0.12], [0.9, 0.3], [0.9, 0.5]])
		"balance":
			# barra con tacca centrale e riempimento a meta': equilibrio
			_poly([[0.06, 0.34], [0.94, 0.34], [0.94, 0.66], [0.06, 0.66]], false)
			_poly([[0.06, 0.34], [0.5, 0.34], [0.5, 0.66], [0.06, 0.66]])
			_line([0.5, 0.14], [0.5, 0.86], 0.07)
		"danger":
			# triangolo con punto esclamativo
			_poly([[0.5, 0.06], [0.95, 0.9], [0.05, 0.9]], false)
			_line([0.5, 0.36], [0.5, 0.62], 0.1)
			_circle([0.5, 0.77], 0.06, true)
		"ko":
			_circle([0.5, 0.5], 0.42)
			_line([0.3, 0.3], [0.7, 0.7], 0.1)
			_line([0.7, 0.3], [0.3, 0.7], 0.1)
		_:
			_circle([0.5, 0.5], 0.4)
