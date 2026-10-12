class_name BattleStage
extends Control

# L'inquadratura della telecamera: parcheggio notturno, boss e combattenti.
# Tutto disegnato col codice (segnaposto): le figure vere sostituiranno le sagome.
# Coordinate di disegno 1280x720, scalate alle dimensioni reali del controllo.

const DW: float = 1280.0
const DH: float = 720.0
const HORIZON: float = 250.0
const BOSS_X: float = 780.0
const FLOOR_Y: float = 470.0        # dove i piedi toccano il suolo sullo schermo
const GEO_FLOOR: float = 600.0      # il suolo nelle coordinate con cui sono disegnate le figure
const ENTITY_SCALE: float = 0.76    # le figure sono disegnate in grande e ridotte qui

# Colori usati ogni frame: creati una volta sola
const K_0F3640: Color = Color("#0f3640")
const K_103C46: Color = Color("#103c46")
const K_7CF0FF: Color = Color("#7cf0ff")
const K_9CEAF5: Color = Color("#9ceaf5")
const K_041015: Color = Color("#041015")
const K_0C3038: Color = Color("#0c3038")
const K_08242C: Color = Color("#08242c")
const K_12505E: Color = Color("#12505e")
const K_071A20: Color = Color("#071a20")
const K_1A5A68: Color = Color("#1a5a68")
const K_D6FFFF: Color = Color("#d6ffff")
const K_0C222A: Color = Color("#0c222a")
const K_071218: Color = Color("#071218")
const K_050D10: Color = Color("#050d10")
const K_2A1018: Color = Color("#2a1018")
const K_0F3844: Color = Color("#0f3844")
const K_27808F: Color = Color("#27808f")
const K_06141A: Color = Color("#06141a")
const K_03090C: Color = Color("#03090c")
const K_0A1C22: Color = Color("#0a1c22")
const K_02060A: Color = Color("#02060a")
const K_12202A: Color = Color("#12202a")
const K_08181E: Color = Color("#08181e")
const K_050F13: Color = Color("#050f13")
const K_02080B: Color = Color("#02080b")
const K_0C1A1F: Color = Color("#0c1a1f")

var state: Dictionary = {}
var boss_hit: float = 0.0           # 1 = appena colpito, scende a 0
var local_player_id: String = ""    # il giocatore di questo schermo: la sua etichetta e' "TU"
var acting: String = ""             # unita' che sta agendo (segnalino rosso sopra di lei)
var acting_target: String = ""      # e chi sta subendo l'azione (cerchio rosso)
var hit_flash: Dictionary = {}      # unit_id -> intensita'
var _t: float = 0.0
var _positions: Dictionary = {}
var _moved: bool = false
var _zoomed: bool = false
var _shake: float = 0.0              # ampiezza dello scuotimento, scende da sola
var _punch: float = 0.0              # piccolo zoom d'impatto, scende da solo
var _cam: Vector2 = Vector2.ZERO     # spostamento "della camera" per la parallasse, -1..1
var _bg_static: StaticLayer = null    # sfondo disegnato: si disegna una volta sola
var _bg_boss: String = ""
var _bg_layers: Array = []           # strati dello sfondo dalla tua grafica (vuoto = sfondo disegnato)


# Livello che si disegna UNA volta (e di nuovo solo se cambia la dimensione). Con `cached`
# lo sfondo viene "fotografato" in una texture e a ogni frame costa un solo rettangolo
# invece delle decine di forme sovrapposte; senza (test, schermo assente) resta il disegno.
class StaticLayer extends Control:
	var painter: Callable
	var cached: bool = false
	var _sub: SubViewport = null
	var _inner: Control = null
	var _view: TextureRect = null

	func _draw() -> void:
		if cached:
			return
		if painter.is_valid():
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / BattleStage.DW, size.y / BattleStage.DH))
			painter.call(self)

	# Passa al disegno in texture. Da chiamare una volta, quando il livello e' nell'albero.
	func enable_cache() -> void:
		if cached:
			return
		cached = true
		_sub = SubViewport.new()
		_sub.disable_3d = true
		_sub.transparent_bg = false
		_sub.gui_disable_input = true
		_sub.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(_sub)
		_inner = Control.new()
		_inner.draw.connect(_paint_inner)
		_sub.add_child(_inner)
		_view = TextureRect.new()
		_view.texture = _sub.get_texture()
		_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_view.stretch_mode = TextureRect.STRETCH_SCALE
		_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_view)
		resized.connect(refresh)
		refresh()

	func _paint_inner() -> void:
		if painter.is_valid():
			_inner.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_inner.size.x / BattleStage.DW, _inner.size.y / BattleStage.DH))
			painter.call(_inner)

	# Ridisegna la texture (nuova dimensione, ripresa dell'app, nuovo sfondo).
	func refresh() -> void:
		if not cached or size.x < 1.0 or size.y < 1.0:
			return
		var pixels: float = 1.0
		if is_inside_tree():
			pixels = clampf(get_viewport().get_final_transform().get_scale().x, 1.0, 1.25)
		var want := Vector2i((size * pixels).ceil())
		if _sub.size != want:
			_sub.size = want
		_inner.size = Vector2(want)
		_inner.queue_redraw()
		_sub.render_target_update_mode = SubViewport.UPDATE_ONCE

	func _notification(what: int) -> void:
		if cached and (what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_WM_WINDOW_FOCUS_IN):
			refresh()


func _ready() -> void:
	_bg_static = StaticLayer.new()
	_bg_static.painter = _paint_procedural_background
	_bg_static.show_behind_parent = true
	_bg_static.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_static.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_static)
	if cache_background and DisplayServer.get_name() != "headless":
		_bg_static.enable_cache()


func _process(delta: float) -> void:
	_t += delta
	boss_hit = maxf(0.0, boss_hit - delta * 3.0)
	for uid in hit_flash.keys():
		hit_flash[uid] = maxf(0.0, float(hit_flash[uid]) - delta * 3.0)
	_shake = maxf(0.0, _shake - delta * 40.0)
	_punch = maxf(0.0, _punch - delta * 0.5)
	var want := Vector2.ZERO
	if size.x > 0.0:
		var m: Vector2 = get_local_mouse_position()
		want = Vector2(clampf(m.x / size.x * 2.0 - 1.0, -1.0, 1.0), clampf(m.y / size.y * 2.0 - 1.0, -1.0, 1.0))
	want.x += sin(_t * 0.4) * 0.35
	_cam = _cam.lerp(want, minf(1.0, delta * 3.0))
	if _shake > 0.0:
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_moved = true
	elif _moved:
		position = Vector2.ZERO
		_moved = false
	if _punch > 0.0:
		pivot_offset = size * 0.5
		scale = Vector2.ONE * (1.0 + _punch)
		_zoomed = true
	elif _zoomed:
		scale = Vector2.ONE
		_zoomed = false
	queue_redraw()


# Scuote l'inquadratura e la ingrandisce un attimo (colpi forti).
func impact(amount: float = 10.0, zoom: float = 0.03) -> void:
	_shake = maxf(_shake, amount)
	_punch = maxf(_punch, zoom)


func set_state(new_state: Dictionary) -> void:
	state = new_state
	if not state.is_empty():
		var boss_id: String = str(BattleState.boss(state)["char"])
		if boss_id != _bg_boss:
			_bg_boss = boss_id
			_bg_layers = ArtLibrary.background_layers(boss_id)
			if _bg_static != null:
				_bg_static.visible = _bg_layers.is_empty() and static_background
	_layout()


func flash(uid: String) -> void:
	if uid == BattleState.BOSS_ID:
		boss_hit = 1.0
	else:
		hit_flash[uid] = 1.0


# Posizione sullo schermo (nelle coordinate di questo controllo) del petto di un'unita'.
func anchor_of(uid: String) -> Vector2:
	var p: Vector2 = _positions.get(uid, Vector2(DW * 0.5, DH * 0.5))
	return Vector2(p.x * size.x / DW, p.y * size.y / DH)


# Da coordinate "figura" a coordinate dell'inquadratura, per un'entita' ancorata in gx.
func _map(p: Vector2, gx: float) -> Vector2:
	return Vector2(gx + (p.x - gx) * ENTITY_SCALE, FLOOR_Y + (p.y - GEO_FLOOR) * ENTITY_SCALE)


func fighter_x(index: int, count: int) -> float:
	var step: float = 200.0 if count <= 1 else minf(200.0, 430.0 / float(count - 1))
	return 150.0 + float(index) * step


func _layout() -> void:
	_positions.clear()
	_positions[BattleState.BOSS_ID] = _map(Vector2(BOSS_X, 360.0), BOSS_X)
	if state.is_empty():
		return
	var players: Array = state["players"]
	var n: int = players.size()
	for i in n:
		var gx: float = fighter_x(i, n)
		_positions[str(players[i]["active"])] = _map(Vector2(gx, GEO_FLOOR - 120.0), gx)


const SHADOW_COLOR: Color = Color(0, 0, 0, 0.5)
static var _unit_circles: Dictionary = {}      # n punti -> coseni e seni gia' calcolati
var _text_lines: Dictionary = {}               # testo disegnato -> TextLine pronto
var _tag_widths: Dictionary = {}               # testo -> larghezza (non si ricalcola ogni frame)


# Punti di un'ellisse. Coseni e seni di ogni n si calcolano una volta sola.
func _ellipse(center: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	if not _unit_circles.has(n):
		var table := PackedVector2Array()
		for i in n:
			var a: float = TAU * float(i) / float(n)
			table.append(Vector2(cos(a), sin(a)))
		_unit_circles[n] = table
	var unit: PackedVector2Array = _unit_circles[n]
	var out := PackedVector2Array()
	out.resize(n)
	for i in n:
		out[i] = Vector2(center.x + unit[i].x * rx, center.y + unit[i].y * ry)
	return out


func _tag_width(tag: String) -> float:
	if not _tag_widths.has(tag):
		_tag_widths[tag] = BattleTheme.display().get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	return float(_tag_widths[tag])


# Testo con la forma gia' calcolata: disegnare una stringa ogni frame costa molto di piu'
# che disegnare un TextLine gia' pronto. `pos` e' la linea di base, come in draw_string.
func _text(font: Font, pos: Vector2, text: String, font_size: int, color: Color) -> void:
	var key: String = "%d|%d|%s" % [font.get_instance_id(), font_size, text]
	var line: TextLine = _text_lines.get(key)
	if line == null:
		line = TextLine.new()
		line.add_string(text, font, font_size)
		_text_lines[key] = line
	line.draw(get_canvas_item(), pos - Vector2(0.0, line.get_line_ascent()), color)


# Imposta la trasformazione per disegnare una figura ancorata in gx.
func _entity_transform(gx: float) -> void:
	var base := Vector2(size.x / DW, size.y / DH)
	var t := Vector2(gx * (1.0 - ENTITY_SCALE), FLOOR_Y - GEO_FLOOR * ENTITY_SCALE)
	draw_set_transform(Vector2(t.x * base.x, t.y * base.y), 0.0, base * ENTITY_SCALE)


# Strumenti di misura (usati da tools/bench.gd): tempo speso a disegnare l'inquadratura.
static var static_background: bool = true      # false = sfondo ridisegnato a ogni frame (confronto)
static var cache_background: bool = true       # sfondo "fotografato" in una texture (false = comandi di disegno)
static var profile: bool = false
static var profile_usec: int = 0
static var profile_frames: int = 0


func _draw() -> void:
	var t0: int = Time.get_ticks_usec() if profile else 0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / DW, size.y / DH))
	if not static_background and _bg_layers.is_empty():
		_paint_procedural_background(self)
	_draw_background()
	_entity_transform(BOSS_X)
	_draw_boss()
	_draw_bench()
	_draw_fighters()
	_draw_markers()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if profile:
		profile_usec += Time.get_ticks_usec() - t0
		profile_frames += 1


# ---------- Sfondo ----------

# Sfondo dalle tue immagini: piu' strati che scorrono di poco, i lontani meno dei vicini.
func _draw_art_background() -> void:
	const FACTORS: Array = [0.012, 0.03, 0.06, 0.10]
	draw_rect(Rect2(0.0, 0.0, DW, DH), Color.BLACK)
	for i in _bg_layers.size():
		var tex: Texture2D = _bg_layers[i]
		var shift: Vector2 = _cam * -60.0 * float(FACTORS[mini(i, FACTORS.size() - 1)]) * 10.0
		var pad: float = 90.0
		draw_texture_rect(tex, Rect2(Vector2(-pad, -pad) + shift, Vector2(DW + pad * 2.0, DH + pad * 2.0)), false)


func _draw_background() -> void:
	if not _bg_layers.is_empty():
		_draw_art_background()


# Lo sfondo disegnato dal codice (quando non ci sono le tue immagini). Si esegue una volta
# sola, sul livello statico: `c` e' il nodo su cui disegnare.
func _paint_procedural_background(c: CanvasItem) -> void:
	# cielo a strisce
	var top: Color = K_041015
	var bottom: Color = K_0C3038
	var strips: int = 22
	for i in strips:
		var f: float = float(i) / float(strips - 1)
		c.draw_rect(Rect2(0.0, HORIZON * float(i) / float(strips), DW, HORIZON / float(strips) + 1.0), top.lerp(bottom, f))

	# palazzi lontani
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var x: float = -20.0
	while x < DW:
		var w: float = rng.randf_range(60.0, 150.0)
		var h: float = rng.randf_range(70.0, 190.0)
		c.draw_rect(Rect2(x, HORIZON - h, w, h), K_08242C)
		c.draw_rect(Rect2(x, HORIZON - h, w, 3.0), K_12505E)
		var wy: float = HORIZON - h + 14.0
		while wy < HORIZON - 12.0:
			var wx: float = x + 8.0
			while wx < x + w - 12.0:
				if rng.randf() < 0.28:
					c.draw_rect(Rect2(wx, wy, 7.0, 9.0), Color(CY_WINDOW, rng.randf_range(0.25, 0.8)))
				wx += 16.0
			wy += 20.0
		x += w + rng.randf_range(2.0, 14.0)

	# asfalto
	c.draw_rect(Rect2(0.0, HORIZON, DW, DH - HORIZON), K_071A20)
	var vp := Vector2(DW * 0.5, HORIZON)
	var lx: float = -900.0
	while lx < DW + 900.0:
		c.draw_line(vp, Vector2(lx, DH), Color(K_103C46, 0.75), 1.5)
		lx += 150.0
	for row in 9:
		var y: float = HORIZON + pow(float(row + 1), 2.0) * 4.6
		c.draw_line(Vector2(0.0, y), Vector2(DW, y), Color(K_0F3640, 0.6), 1.0)

	# strisce dei parcheggi
	for side in [-1.0, 1.0]:
		for j in 4:
			var base_x: float = DW * 0.5 + side * (190.0 + float(j) * 210.0)
			c.draw_line(vp + Vector2(side * 18.0 * float(j + 1), 0.0), Vector2(base_x + side * 120.0, DH), Color(K_9CEAF5, 0.28), 3.0)

	# lampioni
	for lamp_x in [70.0, 1210.0]:
		c.draw_line(Vector2(lamp_x, FLOOR_Y + 30.0), Vector2(lamp_x, 110.0), K_1A5A68, 6.0)
		c.draw_line(Vector2(lamp_x, 110.0), Vector2(lamp_x + (46.0 if lamp_x < 640.0 else -46.0), 98.0), K_1A5A68, 5.0)
		var lh: float = lamp_x + (46.0 if lamp_x < 640.0 else -46.0)
		c.draw_circle(Vector2(lh, 100.0), 9.0, K_D6FFFF)
		var cone: PackedVector2Array = PackedVector2Array([Vector2(lh, 104.0), Vector2(lh - 120.0, FLOOR_Y + 30.0), Vector2(lh + 120.0, FLOOR_Y + 30.0)])
		c.draw_colored_polygon(cone, Color(K_7CF0FF, 0.06))


const CY_WINDOW: Color = Color("#8ff6ff")


# ---------- Boss ----------

func _draw_boss() -> void:
	if state.is_empty():
		return
	var boss: Dictionary = BattleState.boss(state)
	var alive: bool = BattleState.is_alive(boss)
	var ratio: float = float(boss["hp"]) / float(boss["max_hp"])
	var enraged: bool = alive and ratio < BattleTypes.ENRAGE_BELOW
	var shake: Vector2 = Vector2(sin(_t * 90.0), cos(_t * 70.0)) * 5.0 * boss_hit
	var o: Vector2 = shake + Vector2(0.0, sin(_t * 1.3) * 1.5)

	# ombra
	draw_colored_polygon(_ellipse(Vector2(BOSS_X, GEO_FLOOR + 18.0), 210.0, 26.0, 24), SHADOW_COLOR)

	var body: Rect2
	var art: Texture2D = ArtLibrary.boss_image(str(boss["char"]), "battle")
	if art != null:
		body = _draw_boss_art(boss, art, alive, o)
	else:
		body = _draw_boss_body(boss, alive, enraged, o)

	if boss_hit > 0.0 and art == null:
		draw_rect(body, Color(1, 1, 1, 0.55 * boss_hit))

	# riquadro di tracciamento
	var br := Rect2(body.position - Vector2(26.0, 26.0), body.size + Vector2(52.0, 52.0))
	_brackets(br, BattleTheme.RD if alive else BattleTheme.CY_DARK, 5.0, 40.0)
	if alive:
		draw_line(Vector2(br.position.x + br.size.x * 0.5, br.position.y), Vector2(br.position.x + br.size.x * 0.5, br.position.y - 22.0), BattleTheme.RD, 3.0)


# Il boss disegnato dall'artista: i piedi sul suolo, altezza massima 440. Se esiste
# `hurt.png` la usa per un attimo quando viene colpito.
func _draw_boss_art(boss: Dictionary, art: Texture2D, alive: bool, o: Vector2) -> Rect2:
	var img: Texture2D = art
	if boss_hit > 0.4:
		var hurt: Texture2D = ArtLibrary.boss_image(str(boss["char"]), "hurt")
		if hurt != null:
			img = hurt
	var ts: Vector2 = img.get_size()
	var fit: float = minf(460.0 / ts.y, 520.0 / ts.x)
	var sz: Vector2 = ts * fit
	var rect := Rect2(Vector2(BOSS_X - sz.x * 0.5, GEO_FLOOR + 10.0 - sz.y) + o, sz)
	var tint: Color = Color.WHITE.lerp(Color(1.6, 1.6, 1.6), boss_hit) if alive else Color(0.25, 0.25, 0.3)
	draw_texture_rect(img, rect, false, tint)
	return rect


func _draw_boss_body(boss: Dictionary, alive: bool, enraged: bool, o: Vector2) -> Rect2:
	var body: Rect2
	match str(boss["char"]):
		"semaforo":
			body = _draw_semaforo(boss, alive, enraged, o)
		"tombino":
			body = _draw_tombino(boss, alive, enraged, o)
		"cabina":
			body = _draw_cabina(boss, alive, enraged, o)
		_:
			body = _draw_distributore(alive, enraged, o)
	return body


# Il distributore: ritorna il riquadro del corpo.
func _draw_distributore(alive: bool, enraged: bool, o: Vector2) -> Rect2:
	var body := Rect2(BOSS_X - 170.0 + o.x, 170.0 + o.y, 340.0, 430.0)
	var base_col: Color = K_0C222A if alive else K_071218
	draw_rect(body, base_col)
	draw_rect(body, BattleTheme.CY if alive else BattleTheme.CY_DARK, false, 3.0)

	# insegna in alto
	var sign_rect := Rect2(body.position.x + 12.0, body.position.y + 12.0, body.size.x - 24.0, 54.0)
	draw_rect(sign_rect, K_050D10)
	draw_rect(sign_rect, BattleTheme.RD if enraged else BattleTheme.CY_DIM, false, 2.0)
	var blink: float = 1.0 if (int(_t * 2.0) % 2 == 0 or not enraged) else 0.35
	var eye_col: Color = Color(BattleTheme.RD, blink) if alive else K_2A1018
	draw_rect(Rect2(sign_rect.position.x + 24.0, sign_rect.position.y + 16.0, 56.0, 22.0), eye_col)
	draw_rect(Rect2(sign_rect.end.x - 80.0, sign_rect.position.y + 16.0, 56.0, 22.0), eye_col)
	_text(BattleTheme.display(), Vector2(sign_rect.position.x + 96.0, sign_rect.position.y + 36.0), "ESAURITO", 22, BattleTheme.WH if alive else BattleTheme.CY_DARK)

	# vetrina con i prodotti
	var glass := Rect2(body.position.x + 16.0, body.position.y + 82.0, 210.0, 250.0)
	draw_rect(glass, K_0F3844)
	for shelf in 4:
		var sy: float = glass.position.y + 12.0 + float(shelf) * 60.0
		draw_line(Vector2(glass.position.x, sy + 52.0), Vector2(glass.end.x, sy + 52.0), K_27808F, 2.0)
		for col in 4:
			var px: float = glass.position.x + 14.0 + float(col) * 49.0
			var hot: bool = (shelf * 4 + col) % 5 == 0
			draw_rect(Rect2(px, sy + 14.0, 34.0, 36.0), Color(BattleTheme.RD, 0.8) if hot else Color(BattleTheme.CY, 0.34))
	draw_rect(glass, BattleTheme.CY_DIM, false, 2.0)

	# tastierino e fessura
	var pad := Rect2(body.position.x + 244.0, body.position.y + 90.0, 80.0, 150.0)
	draw_rect(pad, K_06141A)
	for r in 4:
		for c in 3:
			draw_rect(Rect2(pad.position.x + 8.0 + float(c) * 24.0, pad.position.y + 10.0 + float(r) * 34.0, 18.0, 24.0), Color(BattleTheme.CY, 0.55))
	draw_rect(Rect2(body.position.x + 250.0, body.position.y + 262.0, 68.0, 10.0), BattleTheme.CY_DARK)
	draw_rect(Rect2(body.position.x + 60.0, body.position.y + 350.0, 220.0, 56.0), K_03090C)
	draw_rect(Rect2(body.position.x + 60.0, body.position.y + 350.0, 220.0, 56.0), BattleTheme.CY_DIM, false, 2.0)
	return body


# Il semaforo: le tre luci mostrano la mossa annunciata. Ritorna il riquadro del corpo.
func _draw_semaforo(boss: Dictionary, alive: bool, enraged: bool, o: Vector2) -> Rect2:
	var cx: float = BOSS_X + o.x
	var move: String = str(state.get("telegraph", {}).get("move", ""))
	var lamp_cols: Array = [BattleTheme.unit_color("rosso"), BattleTheme.unit_color("giallo"), BattleTheme.unit_color("verde")]
	var lit: Array = [false, false, false]
	match move:
		"rosso":
			lit[0] = true
		"giallo":
			lit[1] = true
		"verde":
			lit[2] = true
		"lampeggio":
			var on: bool = int(_t * 4.0) % 2 == 0
			lit = [on, on, on]
	if not alive:
		lit = [false, false, false]

	# palo e base
	draw_rect(Rect2(cx - 16.0, 440.0 + o.y, 32.0, 160.0), K_0A1C22)
	draw_rect(Rect2(cx - 16.0, 440.0 + o.y, 32.0, 160.0), BattleTheme.CY_DIM, false, 2.0)
	draw_rect(Rect2(cx - 70.0, 586.0, 140.0, 16.0), K_0A1C22)
	draw_rect(Rect2(cx - 70.0, 586.0, 140.0, 16.0), BattleTheme.CY_DIM, false, 2.0)

	# cassa
	var body := Rect2(cx - 100.0, 140.0 + o.y, 200.0, 320.0)
	draw_rect(body, K_0C222A if alive else K_071218)
	draw_rect(body, BattleTheme.CY if alive else BattleTheme.CY_DARK, false, 3.0)
	draw_rect(Rect2(body.position.x + 8.0, body.position.y + 8.0, body.size.x - 16.0, 14.0), K_050D10)

	for i in 3:
		var c := Vector2(cx, body.position.y + 78.0 + float(i) * 96.0)
		draw_circle(c, 40.0, K_03090C)
		var col: Color = lamp_cols[i]
		if bool(lit[i]):
			var flicker: float = 1.0 if not enraged else (0.7 + 0.3 * sin(_t * 40.0))
			draw_circle(c, 52.0, Color(col, 0.18 * flicker))
			draw_circle(c, 36.0, Color(col, flicker))
		else:
			draw_circle(c, 36.0, Color(col, 0.12 if alive else 0.04))
		draw_arc(c, 40.0, 0.0, TAU, 32, BattleTheme.CY_DIM if alive else BattleTheme.CY_DARK, 2.0)
		# visiera
		draw_rect(Rect2(c.x - 46.0, c.y - 52.0, 92.0, 14.0), K_071218)
		draw_rect(Rect2(c.x - 46.0, c.y - 52.0, 92.0, 14.0), BattleTheme.CY_DARK, false, 2.0)
	return Rect2(cx - 100.0, 140.0 + o.y, 200.0, 462.0)


# Il tombino: il coperchio si solleva quando colpisce. Ritorna il riquadro del corpo.
func _draw_tombino(boss: Dictionary, alive: bool, enraged: bool, o: Vector2) -> Rect2:
	var cx: float = BOSS_X + o.x
	var col: Color = BattleTheme.unit_color(str(boss["color"]))
	var move: String = str(state.get("telegraph", {}).get("move", ""))
	var open_amount: float = 26.0 if alive and (move == "gorgo" or move == "risucchio") else 8.0
	if enraged:
		open_amount += 8.0 + sin(_t * 6.0) * 5.0
	var base_y: float = 560.0 + o.y

	# fessura: l'interno scuro con gli occhi
	var gap := Rect2(cx - 190.0, base_y - open_amount, 380.0, open_amount + 24.0)
	draw_rect(gap, K_02060A)
	if alive:
		var eye_col: Color = Color(col, 0.95)
		draw_rect(Rect2(cx - 100.0, base_y - open_amount * 0.7, 54.0, 9.0), eye_col)
		draw_rect(Rect2(cx + 46.0, base_y - open_amount * 0.7, 54.0, 9.0), eye_col)

	# tentacoli
	if alive:
		for k in 6:
			var x0: float = cx - 150.0 + float(k) * 60.0
			var h: float = 150.0 + float((k * 37) % 70) + sin(_t * 1.5 + float(k)) * 12.0
			var pts: PackedVector2Array = PackedVector2Array()
			for j in 11:
				var f: float = float(j) / 10.0
				pts.append(Vector2(x0 + sin(_t * 2.0 + float(k) + f * 4.0) * 16.0 * f, base_y - open_amount - h * f))
			draw_polyline(pts, K_12202A, 18.0 - 8.0 * 0.5)
			draw_polyline(pts, Color(col, 0.55), 3.0)

	# coperchio: ellisse con anelli
	var lid_y: float = base_y - open_amount - 18.0
	var lid: PackedVector2Array = _ellipse(Vector2(cx, lid_y), 205.0, 38.0, 32)
	draw_colored_polygon(lid, K_0C222A if alive else K_071218)
	for r in [0.78, 0.55, 0.32]:
		var ring: PackedVector2Array = _ellipse(Vector2(cx, lid_y), 205.0 * r, 38.0 * r, 32)
		ring.append(ring[0])
		draw_polyline(ring, BattleTheme.CY_DIM if alive else BattleTheme.CY_DARK, 2.0)
	var outline: PackedVector2Array = lid.duplicate()
	outline.append(lid[0])
	draw_polyline(outline, BattleTheme.CY if alive else BattleTheme.CY_DARK, 3.0)
	# crepa luminosa
	if alive:
		draw_polyline(PackedVector2Array([Vector2(cx - 60.0, lid_y - 10.0), Vector2(cx - 20.0, lid_y + 8.0), Vector2(cx + 14.0, lid_y - 6.0), Vector2(cx + 70.0, lid_y + 12.0)]), col, 3.0)

	return Rect2(cx - 210.0, 300.0 + o.y, 420.0, 300.0)


# La cabina telefonica: la cornetta penzola e il display mostra la mossa annunciata.
func _draw_cabina(boss: Dictionary, alive: bool, enraged: bool, o: Vector2) -> Rect2:
	var cx: float = BOSS_X + o.x
	var col: Color = BattleTheme.unit_color(str(boss["color"]))
	var move: String = str(state.get("telegraph", {}).get("move", ""))
	var ringing: bool = alive and move == "squillo"
	var body := Rect2(cx - 120.0, 150.0 + o.y, 240.0, 450.0)
	var frame_col: Color = col if alive else BattleTheme.CY_DARK
	# tetto
	draw_colored_polygon(PackedVector2Array([
		Vector2(body.position.x - 18.0, body.position.y + 30.0), Vector2(body.end.x + 18.0, body.position.y + 30.0),
		Vector2(body.end.x - 8.0, body.position.y), Vector2(body.position.x + 8.0, body.position.y)]), K_0C222A if alive else K_071218)
	draw_rect(Rect2(body.position.x + 40.0, body.position.y + 6.0, 160.0, 20.0), K_050D10)
	_text(BattleTheme.display(), Vector2(body.position.x + 74.0, body.position.y + 22.0), "TELEFONO", 16, BattleTheme.WH if alive else BattleTheme.CY_DARK)
	# telaio e vetri a riquadri
	var shift: float = sin(_t * 40.0) * 3.0 if ringing else 0.0
	var frame := Rect2(body.position.x + shift, body.position.y + 34.0, body.size.x, body.size.y - 34.0)
	draw_rect(frame, K_08181E if alive else K_050F13)
	for r in 4:
		for c in 3:
			var pane := Rect2(frame.position.x + 14.0 + float(c) * 70.0, frame.position.y + 14.0 + float(r) * 62.0, 62.0, 54.0)
			var lit: bool = alive and ((r * 3 + c + int(_t * 1.5)) % 7 == 0)
			draw_rect(pane, Color(col, 0.30) if lit else Color(BattleTheme.CY, 0.10))
			draw_rect(pane, Color(frame_col, 0.7), false, 2.0)
	draw_rect(frame, frame_col, false, 4.0)
	# display con gli occhi
	var disp := Rect2(frame.position.x + 60.0, frame.position.y + 270.0, 120.0, 60.0)
	draw_rect(disp, K_02080B)
	draw_rect(disp, BattleTheme.RD if enraged else BattleTheme.CY_DIM, false, 2.0)
	if alive:
		var blink: float = 1.0 if (int(_t * 2.0) % 2 == 0 or not enraged) else 0.3
		draw_rect(Rect2(disp.position.x + 20.0, disp.position.y + 20.0, 28.0, 14.0), Color(BattleTheme.RD, blink))
		draw_rect(Rect2(disp.end.x - 48.0, disp.position.y + 20.0, 28.0, 14.0), Color(BattleTheme.RD, blink))
	# cornetta penzolante
	var sway: float = sin(_t * 2.2) * 10.0 + (sin(_t * 30.0) * 6.0 if ringing else 0.0)
	var hook := Vector2(frame.end.x - 6.0, frame.position.y + 150.0)
	var tip := Vector2(hook.x + 40.0 + sway, hook.y + 130.0)
	var cord: PackedVector2Array = PackedVector2Array()
	for j in 9:
		var f: float = float(j) / 8.0
		cord.append(hook.lerp(tip, f) + Vector2(sin(f * 9.0 + _t * 3.0) * 6.0, 0.0))
	draw_polyline(cord, K_12202A, 6.0)
	draw_polyline(cord, Color(col, 0.6), 2.0)
	draw_rect(Rect2(tip.x - 14.0, tip.y, 28.0, 56.0), K_0C222A)
	draw_rect(Rect2(tip.x - 14.0, tip.y, 28.0, 56.0), frame_col, false, 3.0)
	# basamento
	draw_rect(Rect2(body.position.x - 14.0, body.end.y - 6.0, body.size.x + 28.0, 16.0), K_03090C)
	return Rect2(body.position.x - 20.0, body.position.y, body.size.x + 80.0, body.size.y + 10.0)


# ---------- Combattenti ----------

func _draw_fighters() -> void:
	if state.is_empty():
		return
	var players: Array = state["players"]
	for i in players.size():
		var p: Dictionary = players[i]
		var u: Dictionary = BattleState.unit(state, str(p["active"]))
		if u.is_empty():
			continue
		var gx: float = fighter_x(i, players.size())
		_entity_transform(gx)
		_draw_fighter(u, Vector2(gx, GEO_FLOOR - 120.0), i, str(p["id"]) == local_player_id or (local_player_id == "" and i == 0))


func _draw_fighter(u: Dictionary, chest: Vector2, index: int, is_lead: bool) -> void:
	var alive: bool = BattleState.is_alive(u)
	var col: Color = BattleTheme.unit_color(str(u["color"]))
	var bob: float = sin(_t * 2.0 + float(index)) * 2.5 if alive else 0.0
	var flash_v: float = float(hit_flash.get(u["id"], 0.0))
	var foot_y: float = GEO_FLOOR + 8.0
	var cx: float = chest.x
	var body_col: Color = col.darkened(0.55) if alive else K_0C1A1F
	if alive and flash_v > 0.0:
		body_col = body_col.lerp(BattleTheme.WH, flash_v)

	# ombra
	draw_colored_polygon(_ellipse(Vector2(cx, foot_y + 8.0), 54.0, 11.0, 16), SHADOW_COLOR)

	if not alive:
		# a terra
		draw_rect(Rect2(cx - 62.0, foot_y - 26.0, 124.0, 24.0), body_col)
		draw_circle(Vector2(cx + 70.0, foot_y - 16.0), 15.0, body_col)
		draw_line(Vector2(cx - 12.0, foot_y - 40.0), Vector2(cx + 12.0, foot_y - 60.0), BattleTheme.RD, 4.0)
		draw_line(Vector2(cx + 12.0, foot_y - 40.0), Vector2(cx - 12.0, foot_y - 60.0), BattleTheme.RD, 4.0)
		return

	var top: float = foot_y - 210.0 + bob
	var sprite: Texture2D = ArtLibrary.battle_sprite(str(u.get("char", "")))
	if sprite != null:
		_draw_fighter_sprite(sprite, cx, foot_y, bob, flash_v)
	else:
		_draw_fighter_body(cx, foot_y, top, body_col, col)
	_draw_fighter_frame(u, cx, top, col, index, is_lead, foot_y)


# Figura disegnata dall'utente: ancorata ai piedi, alta ~230 px.
# Chi comanda quell'operatore: TU, un compagno IA o un altro giocatore.
func _who_label(index: int, owner_id: String) -> String:
	if owner_id == local_player_id or (local_player_id == "" and index == 0):
		return "TU"
	var p: Dictionary = BattleState.player(state, owner_id)
	if bool(p.get("ai", false)):
		return "IA" + str(index)
	return str(p.get("name", "P%d" % (index + 1))).to_upper().left(6)


# Panchina: i compagni non in campo di ogni giocatore, dietro all'operatore attivo, piu' piccoli, scuri e trasparenti.
const BENCH_SCALE: float = 0.62
const BENCH_ALPHA: float = 0.42


func _draw_bench() -> void:
	if state.is_empty():
		return
	var players: Array = state["players"]
	var n: int = players.size()
	var step: float = 200.0 if n <= 1 else minf(200.0, 430.0 / float(n - 1))
	var dx: float = minf(88.0, step * 0.42)
	for i in n:
		var p: Dictionary = players[i]
		var gx: float = fighter_x(i, n)
		var k: int = 0
		for uid in p["team"]:
			if str(uid) == str(p["active"]):
				continue
			var u: Dictionary = BattleState.unit(state, str(uid))
			if u.is_empty():
				continue
			var side: float = -1.0 if k % 2 == 0 else 1.0
			_draw_bench_unit(u, gx + side * dx, k)
			k += 1


func _draw_bench_unit(u: Dictionary, gx: float, slot: int) -> void:
	var base := Vector2(size.x / DW, size.y / DH)
	var s: float = ENTITY_SCALE * BENCH_SCALE
	var lift: float = 30.0 + float(slot) * 6.0
	var origin := Vector2(gx * (1.0 - s), FLOOR_Y - lift - GEO_FLOOR * s)
	draw_set_transform(Vector2(origin.x * base.x, origin.y * base.y), 0.0, base * s)
	var alive: bool = BattleState.is_alive(u)
	var col: Color = BattleTheme.unit_color(str(u["color"]))
	var foot_y: float = GEO_FLOOR + 8.0
	var a: float = BENCH_ALPHA if alive else 0.3
	draw_colored_polygon(_ellipse(Vector2(gx, foot_y + 8.0), 54.0, 11.0, 16), Color(0, 0, 0, 0.3))
	if not alive:
		draw_line(Vector2(gx - 30.0, foot_y - 90.0), Vector2(gx + 30.0, foot_y - 30.0), Color(BattleTheme.RD, 0.7), 8.0)
		draw_line(Vector2(gx + 30.0, foot_y - 90.0), Vector2(gx - 30.0, foot_y - 30.0), Color(BattleTheme.RD, 0.7), 8.0)
	var sprite: Texture2D = ArtLibrary.battle_sprite(str(u.get("char", "")))
	if sprite != null:
		var h: float = 230.0
		var w: float = h * sprite.get_width() / maxf(1.0, float(sprite.get_height()))
		draw_texture_rect(sprite, Rect2(gx - w * 0.5, foot_y - h, w, h), false, Color(0.45, 0.5, 0.55, a))
	else:
		_draw_fighter_body(gx, foot_y, foot_y - 210.0, Color(col.darkened(0.6), a), Color(col, a))
	# nome e vita sotto i piedi (leggibili anche se la figura e' piccola)
	var ratio: float = float(u["hp"]) / maxf(1.0, float(u["max_hp"]))
	_text(BattleTheme.display(), Vector2(gx - 60.0, foot_y + 52.0), str(u["name"]).to_upper(), 30, Color(BattleTheme.WH, 0.75 if alive else 0.35))
	draw_rect(Rect2(gx - 60.0, foot_y + 62.0, 120.0, 10.0), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(gx - 60.0, foot_y + 62.0, 120.0 * ratio, 10.0), Color(BattleTheme.RD if ratio < 0.3 else BattleTheme.CY, 0.75))
	_entity_transform(BOSS_X)


# Segnalini di chi agisce (triangolo rosso) e di chi subisce (cerchio rosso), durante la riproduzione del round.
func _draw_markers() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / DW, size.y / DH))
	var pulse: float = 0.5 + 0.5 * sin(_t * 8.0)
	if acting != "" and _positions.has(acting):
		var p: Vector2 = _positions[acting]
		var y: float = p.y - (190.0 if acting != BattleState.BOSS_ID else 230.0) - pulse * 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(p.x - 20.0, y - 22.0), Vector2(p.x + 20.0, y - 22.0), Vector2(p.x, y + 6.0)]), BattleTheme.RD)
		draw_polyline(PackedVector2Array([Vector2(p.x - 20.0, y - 22.0), Vector2(p.x + 20.0, y - 22.0), Vector2(p.x, y + 6.0), Vector2(p.x - 20.0, y - 22.0)]), BattleTheme.WH, 2.0)
		_text(BattleTheme.display(), Vector2(p.x - 36.0, y - 30.0), "AGISCE", 18, BattleTheme.WH)
	if acting_target != "" and acting_target != acting and _positions.has(acting_target):
		var q: Vector2 = _positions[acting_target]
		draw_arc(q, 104.0 + pulse * 6.0, 0.0, TAU, 40, Color(BattleTheme.RD, 0.85), 4.0)
		draw_arc(q, 120.0 + pulse * 6.0, 0.4, 1.4, 12, Color(BattleTheme.WH, 0.9), 3.0)
		draw_arc(q, 120.0 + pulse * 6.0, 3.5, 4.5, 12, Color(BattleTheme.WH, 0.9), 3.0)


func clear_markers() -> void:
	acting = ""
	acting_target = ""


func _draw_fighter_sprite(tex: Texture2D, cx: float, foot_y: float, bob: float, flash_v: float) -> void:
	var h: float = 230.0
	var w: float = h * tex.get_width() / maxf(1.0, float(tex.get_height()))
	var tint: Color = Color.WHITE.lerp(Color(2.0, 2.0, 2.0), flash_v)
	draw_texture_rect(tex, Rect2(cx - w * 0.5, foot_y - h + bob, w, h), false, tint)


func _draw_fighter_body(cx: float, foot_y: float, top: float, body_col: Color, col: Color) -> void:
	# gambe
	draw_rect(Rect2(cx - 24.0, foot_y - 90.0, 20.0, 90.0), body_col)
	draw_rect(Rect2(cx + 4.0, foot_y - 90.0, 20.0, 90.0), body_col)
	# busto
	var torso: PackedVector2Array = PackedVector2Array([
		Vector2(cx - 40.0, top + 46.0), Vector2(cx + 40.0, top + 46.0), Vector2(cx + 30.0, foot_y - 86.0), Vector2(cx - 30.0, foot_y - 86.0)])
	draw_colored_polygon(torso, body_col)
	draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[0]]), col, 2.0)
	# braccia
	draw_line(Vector2(cx - 40.0, top + 52.0), Vector2(cx - 58.0, top + 118.0), body_col, 14.0)
	draw_line(Vector2(cx + 40.0, top + 52.0), Vector2(cx + 62.0, top + 112.0), body_col, 14.0)
	# testa
	draw_circle(Vector2(cx, top + 24.0), 24.0, body_col)
	draw_arc(Vector2(cx, top + 24.0), 24.0, 0.0, TAU, 28, col, 2.0)
	# visore
	draw_rect(Rect2(cx - 14.0, top + 18.0, 28.0, 8.0), col)


func _draw_fighter_frame(u: Dictionary, cx: float, top: float, col: Color, index: int, is_lead: bool, _foot_y: float) -> void:
	# riquadro e targhetta
	var rect := Rect2(cx - 82.0, top - 12.0, 164.0, 236.0)
	_brackets(rect, BattleTheme.RD if is_lead else col, 5.0 if is_lead else 3.0, 24.0)
	var tag: String = "%s · %s" % [_who_label(index, str(u.get("owner", ""))), str(u["name"]).to_upper()]
	var tw: float = _tag_width(tag)
	var tab: PackedVector2Array = PackedVector2Array([
		Vector2(rect.position.x, rect.position.y - 28.0), Vector2(rect.position.x + tw + 26.0, rect.position.y - 28.0),
		Vector2(rect.position.x + tw + 14.0, rect.position.y - 2.0), Vector2(rect.position.x - 8.0, rect.position.y - 2.0)])
	draw_colored_polygon(tab, BattleTheme.RD if is_lead else col)
	_text(BattleTheme.display(), Vector2(rect.position.x + 6.0, rect.position.y - 10.0), tag, 16, BattleTheme.BK)

	# stati
	var sx: float = rect.position.x
	var statuses: Dictionary = u["statuses"]
	for s in statuses:
		_text(BattleTheme.mono(), Vector2(sx, rect.end.y + 22.0), "[%s]" % BattleText.status_name(str(s)), 14, BattleTheme.CY)
		sx += 92.0
	if int(u["shield"]) > 0:
		draw_arc(Vector2(cx, top + 100.0), 100.0, PI * 1.15, PI * 1.85, 24, Color(BattleTheme.WH, 0.65), 4.0)


func _brackets(r: Rect2, col: Color, width: float, l: float) -> void:
	var p: Vector2 = r.position
	var e: Vector2 = r.end
	draw_polyline(PackedVector2Array([Vector2(p.x, p.y + l), p, Vector2(p.x + l, p.y)]), col, width)
	draw_polyline(PackedVector2Array([Vector2(e.x - l, p.y), Vector2(e.x, p.y), Vector2(e.x, p.y + l)]), col, width)
	draw_polyline(PackedVector2Array([Vector2(e.x, e.y - l), e, Vector2(e.x - l, e.y)]), col, width)
	draw_polyline(PackedVector2Array([Vector2(p.x + l, e.y), Vector2(p.x, e.y), Vector2(p.x, e.y - l)]), col, width)
