class_name Banter
extends Control

# Chiacchiere della squadra mentre si esplora (stile Persona 5): fumetti con la faccina del personaggio a sinistra,
# uno sotto l'altro, che NON fermano il gioco. Testi e regole in data/dialoghi.json, sezione "chiacchiere".
#
# Ogni chiacchiera: {"id", "quando": {...}, "righe": [{"chi", "espr", "testo"}], "una_volta": true}
#   quando.tipo = "zona"     -> quando il giocatore supera una z (va verso il fondo: z che diminuisce)
#                 "vicino"   -> vicino a un punto della strada (quando.punto = nome passato da street.gd)
#                 "evento"   -> chiamata da codice (es. indizio trovato): quando.evento
#                 "fermo"    -> giocatore fermo per qualche secondo
#                 "caso"     -> ogni tanto, a caso, mentre si cammina
# Fra due chiacchiere c'e' sempre una pausa; durante i dialoghi grandi si aspetta.

const MAX_SHOWN: int = 3
const GAP_MIN: float = 4.0          # secondi minimi fra una chiacchiera e l'altra
const RANDOM_EVERY: Vector2 = Vector2(16.0, 26.0)
const IDLE_AFTER: float = 9.0

var _all: Array = []
var _used: Dictionary = {}
var _queue: Array = []              # righe in attesa di essere mostrate
var _line_t: float = 0.0
var _gap: float = 2.0
var _rand_t: float = 20.0
var _idle_t: float = 0.0
var _stack: VBoxContainer
var paused: bool = false
var set_key: String = "strada"     # quale gruppo di chiacchiere usare (una per area)


func _ready() -> void:
	Ui.place(self, 0, 0, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 10)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(_stack, 0, 0, 0, 0, 20, 120, 640, 560)
	add_child(_stack)
	_all = DialogData.banter(set_key)
	_rand_t = randf_range(RANDOM_EVERY.x, RANDOM_EVERY.y)


func busy() -> bool:
	return not _queue.is_empty() or _line_t > 0.0


# Controlli a ogni fotogramma da street.gd: posizione, se si muove, punti vicini
func tick(delta: float, z: float, moving: bool, near_points: Array) -> void:
	if paused:
		return
	if _line_t > 0.0:
		_line_t -= delta
		if _line_t <= 0.0:
			_next_line()
		return
	_gap -= delta
	if not moving:
		_idle_t += delta
	else:
		_idle_t = 0.0
		_rand_t -= delta
	if _gap > 0.0:
		return
	for b in _all:
		var q: Dictionary = b.get("quando", {})
		var tipo: String = str(q.get("tipo", ""))
		if _used.has(str(b.get("id", ""))):
			continue
		if (tipo == "zona" and z < float(q.get("z", 0.0))) or (tipo == "vicino" and near_points.has(str(q.get("punto", "")))):
			_play(b)
			return
	if _idle_t > IDLE_AFTER:
		_idle_t = -30.0
		if _play_random("fermo"):
			return
	if _rand_t <= 0.0:
		_rand_t = randf_range(RANDOM_EVERY.x, RANDOM_EVERY.y)
		_play_random("caso")


func event(name: String) -> void:
	for b in _all:
		var q: Dictionary = b.get("quando", {})
		if str(q.get("tipo", "")) == "evento" and str(q.get("evento", "")) == name and not _used.has(str(b.get("id", ""))):
			_play(b)
			return


func _play_random(tipo: String) -> bool:
	var pool: Array = []
	for b in _all:
		if str((b.get("quando", {}) as Dictionary).get("tipo", "")) == tipo and not _used.has(str(b.get("id", ""))):
			pool.append(b)
	if pool.is_empty():
		return false
	_play(pool[randi() % pool.size()])
	return true


func _play(b: Dictionary) -> void:
	if bool(b.get("una_volta", true)):
		_used[str(b.get("id", ""))] = true
	_queue.append_array(b.get("righe", []))
	if _line_t <= 0.0:
		_next_line()


func _next_line() -> void:
	if _queue.is_empty():
		_line_t = 0.0
		_gap = GAP_MIN
		return
	var ln: Dictionary = _queue.pop_front()
	var text: String = str(ln.get("testo", ""))
	_line_t = 1.6 + 0.05 * float(text.length())
	_add_bubble(str(ln.get("chi", "")), str(ln.get("espr", "neutro")), text)


func _add_bubble(who: String, expr: String, text: String) -> void:
	var col: Color = Ui.BATTLE_COLORS.get(str(BattleContent.CHARACTERS.get(who, {}).get("color", "")), Ui.YELLOW)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# faccina: la parte alta del ritratto in un riquadro col colore del personaggio
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _style(col, Ui.INK, 4, 0.0))
	frame.custom_minimum_size = Vector2(84, 84)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := TextureRect.new()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.custom_minimum_size = Vector2(76, 76)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path: String = "res://assets/portraits/%s_%s.png" % [who, expr]
	if not ResourceLoader.exists(path):
		path = "res://assets/portraits/%s_neutro.png" % who
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		var at := AtlasTexture.new()
		at.atlas = tex
		var sz: Vector2 = tex.get_size()
		at.region = Rect2(sz.x * 0.12, sz.y * 0.02, sz.x * 0.72, sz.x * 0.72)
		face.texture = at
	frame.add_child(face)
	row.add_child(frame)
	# fumetto bianco inclinato con il nome
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _style(Color(0.99, 0.97, 0.93), Ui.INK, 4, -0.12))
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_l := Ui.label(str(CastVisual.CAST.get(who, {}).get("name", who)).to_upper(), 18, col.darkened(0.25), Ui.display())
	vb.add_child(name_l)
	var t := Ui.label(text, 22 if Ui.is_touch() else 20, Ui.INK)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(420, 0)
	vb.add_child(t)
	bubble.add_child(vb)
	row.add_child(bubble)
	_stack.add_child(row)
	# entrata da sinistra, poi uscita dopo un po'
	row.modulate.a = 0.0
	row.position.x = -80.0
	var tw := row.create_tween()
	tw.tween_property(row, "modulate:a", 1.0, 0.15)
	tw.tween_interval(_line_t + 2.2)
	tw.tween_property(row, "modulate:a", 0.0, 0.35)
	tw.tween_callback(row.queue_free)
	while _stack.get_child_count() > MAX_SHOWN:
		var old: Node = _stack.get_child(0)
		_stack.remove_child(old)
		old.queue_free()
	Settings.buzz(4)


func _style(bg: Color, border: Color, bw: int, skew: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(4)
	s.skew = Vector2(skew, 0.0)
	s.shadow_color = Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, 0.85)
	s.shadow_size = 1
	s.shadow_offset = Vector2(5, 5)
	s.content_margin_left = 14 if skew != 0.0 else 4
	s.content_margin_right = 14 if skew != 0.0 else 4
	s.content_margin_top = 6 if skew != 0.0 else 4
	s.content_margin_bottom = 8 if skew != 0.0 else 4
	return s
