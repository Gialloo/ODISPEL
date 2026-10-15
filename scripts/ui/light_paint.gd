class_name LightPaint
extends Control

# LIGHT PAINTING: le abilita' sono tracciati di luce, come una foto a lunga esposizione.
#   FAZIONE  = la "mano" che dipinge (la forma del gesto)
#   COLORE   = la tinta e il comportamento delle particelle
#   FORMA    = che cosa fa la mossa: "line" (colpo), "ring" (scudo/protezione), "spiral" (cura),
#              "mark" (runa del Marchio), "crack" (crepe della Frattura), "swirl" (spirale di Intimidisci),
#              "slash" (fendente pesante, VFX-001 dell'art bible), "sigil" (firma personale di ogni personaggio, solo per gli ultimate)
# Durante il tratto il mondo si scurisce un attimo (dim): la luce e' l'evento, il resto e' il foglio.
# Facoltativo: se esiste art/fx/stroke_<fazione>.png (pennellata bianca su trasparente, disegnata in
# Procreate) il tratto usa quella pennellata al posto della linea generata dal codice.
# Solo grafica: non tocca mai la logica di battaglia. Si disegna da solo e sparisce.
# NON dipende da "effetti ridotti": e' la firma visiva del gioco, quindi si vede sempre. Con gli effetti ridotti
# (default sui telefoni) restano tratto e alone leggero, senza particelle, copie sfasate e velo scuro.

const HANDS: Array = ["libracorp", "rondini", "magabondi", "kairos"]
const MAX_PARTS: int = 70
# Palette ufficiale (Mini Art Bible v1.0, docs/ART_BIBLE.md). Il colore del personaggio resta il DOMINANTE;
# ogni mano ha un colore di SUPPORTO preso da qui e il nucleo e' sempre AVORIO (accento molto luminoso).
const PAL_CARBON: Color = Color("#171923")
const PAL_MAGENTA: Color = Color("#E83DCE")
const PAL_ORANGE: Color = Color("#FF7438")
const PAL_COSMIC: Color = Color("#7770F7")
const PAL_IVORY: Color = Color("#F5E9C9")
const SUPPORT: Dictionary = {"libracorp": PAL_COSMIC, "rondini": PAL_IVORY, "magabondi": PAL_ORANGE, "kairos": PAL_MAGENTA}
const SHAPES: Array = ["line", "slash", "ring", "spiral", "mark", "crack", "swirl", "sigil"]
# (punte, salto) di ogni firma: 10 stelle diverse; con le 4 varianti ogni personaggio ha la sua.
const SIGIL_STARS: Array = [[5, 2], [6, 2], [7, 2], [7, 3], [8, 3], [9, 2], [9, 4], [10, 3], [11, 3], [12, 5]]

static var max_live: int = 14
static var profile: bool = false          # prove: misura quanto costano _process e _draw
static var profile_usec: int = 0
static var profile_calls: int = 0
static var halo_enabled: bool = true      # per le prove: senza alone il tratto deve restare leggibile
static var _live: int = 0
static var _additive: CanvasItemMaterial = null
static var _dim_node: ColorRect = null
static var _dim_tween: Tween = null

var hand: String = "rondini"
var hue_name: String = "blu"
var shape: String = "line"
var from_pt: Vector2 = Vector2.ZERO
var to_pt: Vector2 = Vector2.ZERO
var power: float = 1.0
var life: float = 0.8
var draw_time: float = 0.22
var key: String = ""          # per la firma: id del personaggio
var delay: float = 0.0

var _t: float = 0.0
var _color: Color = Color.WHITE
var _path: PackedVector2Array = PackedVector2Array()
var _widths: PackedFloat32Array = PackedFloat32Array()
var _ghosts: Array = []
var _parts: Array = []
var _rng := RandomNumberGenerator.new()
var _impact_done: bool = false
var _last_emit: int = -1
var _scale: float = 1.0
var _warm: bool = false       # tratto di riscaldamento: quasi invisibile, serve solo a preparare la grafica
var _lite: bool = false       # effetti ridotti: solo il tratto, niente particelle, alone, copie ne' velo
var _support: Color = PAL_COSMIC
var _burst_dir: Vector2 = Vector2.RIGHT
var _filaments: Array = []    # code filamentose del fendente
var _skip: Dictionary = {}    # segmenti "a penna sollevata": indice -> true
var _brush: Texture2D = null
var _overlay: Control = null
var _mesh_halo := ArrayMesh.new()
var _mesh_color := ArrayMesh.new()
var _mesh_core := ArrayMesh.new()
var _built_head: float = -1.0
var _ghost_sig: String = ""


# Crea il tratto. Restituisce null se la mano non esiste o ci sono gia' troppi tratti vivi.
static func play(parent: Node, new_hand: String, new_hue: String, new_shape: String, a: Vector2, b: Vector2, new_power: float = 1.0, new_delay: float = 0.0, new_key: String = "", warm: bool = false) -> LightPaint:
	if not HANDS.has(new_hand) or _live >= max_live:
		return null
	var p := LightPaint.new()
	p.key = new_key
	p._warm = warm
	p.delay = new_delay
	p._t = -new_delay
	p.hand = new_hand
	p.hue_name = new_hue
	p.shape = new_shape
	p.from_pt = a
	p.to_pt = b
	p.power = new_power
	p._rng.seed = int(a.x * 31.0 + a.y * 17.0 + b.x * 13.0 + b.y * 7.0) & 0xfffff
	p._setup()
	_live += 1
	p.tree_exited.connect(func() -> void: _live = maxi(0, _live - 1))
	parent.add_child(p)
	if parent is Control and not p._lite and not warm:
		dim(parent, 0.26 if new_shape == "sigil" else 0.12, p.draw_time + new_delay)
	return p


# Prepara in anticipo la grafica dei tratti (mesh additive, particelle): al primo tratto vero la scheda video
# non deve compilare niente all'ultimo momento (e' la causa classica del piccolo scatto al primo colpo).
# Si chiama una volta quando si entra in battaglia: disegna due tratti quasi invisibili per un istante.
static func prewarm(host: Node) -> void:
	if not (host is Control):
		return
	for hand_name in ["rondini", "kairos"]:
		var p: LightPaint = play(host, hand_name, "rosso", "slash", Vector2(620.0, 360.0), Vector2(660.0, 380.0), 0.3, 0.0, "", true)
		if p != null:
			p.life = 0.2
			p.draw_time = 0.08


# Firma di un personaggio (ultimate): disegno grande, unico per ogni personaggio.
static func sigil(parent: Node, new_hand: String, new_hue: String, char_id: String, at: Vector2, new_power: float = 1.0) -> LightPaint:
	return play(parent, new_hand, new_hue, "sigil", at, at, new_power, 0.0, char_id)


# {n, k, variant}: la firma e' decisa dalla posizione del personaggio nell'elenco, quindi non cambia mai
# e due personaggi non hanno mai la stessa.
static func sigil_spec(char_id: String) -> Dictionary:
	var idx: int = maxi(0, BattleContent.CHARACTERS.keys().find(char_id))
	var star: Array = SIGIL_STARS[idx % SIGIL_STARS.size()]
	return {"n": int(star[0]), "k": int(star[1]), "variant": (idx / SIGIL_STARS.size()) % 4}


# Il mondo si scurisce un attimo mentre corre la luce (e' un solo velo riusato da tutti i tratti).
static func dim(host: Node, strength: float, hold: float) -> void:
	if not (host is Control):
		return
	if _dim_node == null or not is_instance_valid(_dim_node) or _dim_node.get_parent() != host:
		_dim_node = ColorRect.new()
		_dim_node.color = Color(0.02, 0.0, 0.06, 0.0)
		_dim_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dim_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		host.add_child(_dim_node)
		host.move_child(_dim_node, 0)       # sotto i tratti: scurisce il mondo, non la luce
	if _dim_tween != null and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = _dim_node.create_tween()
	_dim_tween.tween_property(_dim_node, "color:a", strength, 0.08)
	_dim_tween.tween_interval(maxf(0.05, hold))
	_dim_tween.tween_property(_dim_node, "color:a", 0.0, 0.4)


static func additive() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive


# La mano e la tinta in base a chi agisce (fazione e colore del personaggio).
static func hand_for(unit: Dictionary) -> String:
	var f: String = str(unit.get("faction", ""))
	return f if HANDS.has(f) else ""


func _setup() -> void:
	_color = BattleTheme.UNIT_COLORS.get(hue_name, Color("#f2fdff"))
	match Settings.quality_name():
		"ALTA":
			_scale = 1.0
		"MEDIA":
			_scale = 0.6
		_:
			_scale = 0.35
	_lite = Settings.light_fx
	_support = SUPPORT.get(hand, PAL_COSMIC)
	_burst_dir = (to_pt - from_pt).normalized() if from_pt.distance_to(to_pt) > 1.0 else Vector2.RIGHT
	# Tempi dell'art bible: tracciamento 50-180 ms, impatto 30-80 ms, dissolvenza 100-250 ms.
	match shape:
		"ring":
			draw_time = 0.3
			life = 0.75
		"spiral":
			draw_time = 0.36
			life = 0.85
		"swirl":
			draw_time = 0.34
			life = 0.8
		"mark":
			draw_time = 0.3
			life = 1.3          # il segno rituale resta un po' piu' a lungo
		"crack":
			draw_time = 0.2
			life = 0.6
		"sigil":
			draw_time = 0.8
			life = 1.8
		"slash":
			draw_time = 0.16
			life = 0.5
		_:
			draw_time = 0.18 if hand == "rondini" else 0.14
			life = draw_time + 0.3
	_brush = ArtLibrary.texture("fx/stroke_%s.png" % hand)
	_path = _build_path()
	_widths = PackedFloat32Array()
	for i in _path.size():
		var f: float = float(i) / float(maxi(1, _path.size() - 1))
		if shape == "slash":
			_widths.append(0.3 + 1.5 * (f / 0.35) if f < 0.35 else 1.8 * (1.0 - (f - 0.35) / 0.65) + 0.1)
			continue
		match hand:
			"rondini":
				_widths.append(0.35 + 0.9 * sin(f * PI))
			"magabondi":
				_widths.append(_rng.randf_range(0.5, 1.5))
			"libracorp":
				_widths.append(0.8)
			_:
				_widths.append(1.0)
	if hand == "kairos":
		var off: Array = [Vector2(15.0, -7.0), Vector2(-12.0, 9.0)]
		for i in off.size():
			_ghosts.append({"off": off[i], "ph": float(i) * 0.37})


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	material = additive()
	_make_overlay()


# ---------- Forme di base e "mano" ----------

func _build_path() -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"ring":
			var rx: float = 74.0 * (0.9 + 0.2 * power)
			var ry: float = rx * 0.78
			var n: int = 6 if hand == "libracorp" else 44
			for i in n + 1:
				var ang: float = -PI * 0.5 + TAU * float(i) / float(n) * (1.04 if hand != "libracorp" else 1.0)
				pts.append(to_pt + Vector2(cos(ang) * rx, sin(ang) * ry))
		"spiral":
			var n2: int = 14 if hand == "libracorp" else 40
			var turns: float = 1.6
			for i in n2 + 1:
				var f: float = float(i) / float(n2)
				var ang2: float = f * TAU * turns
				var rr: float = 52.0 * (1.0 - 0.45 * f) * (0.9 + 0.2 * power)
				pts.append(to_pt + Vector2(cos(ang2) * rr, 36.0 - f * 130.0 + sin(ang2) * rr * 0.35))
		"swirl":
			# spirale che si stringe e scende sul bersaglio
			var n5: int = 12 if hand == "libracorp" else 36
			for i in n5 + 1:
				var f5: float = float(i) / float(n5)
				var a5: float = f5 * TAU * 2.0
				var r5: float = 62.0 * (1.0 - 0.85 * f5) * (0.9 + 0.2 * power)
				pts.append(to_pt + Vector2(cos(a5) * r5, -30.0 + f5 * 60.0 + sin(a5) * r5 * 0.4))
		"mark":
			# runa: cerchio, asta che lo attraversa e una tacca
			var rm: float = 36.0 * (0.9 + 0.2 * power)
			var nm: int = 6 if hand == "libracorp" else 28
			for i in nm + 1:
				var am: float = -PI * 0.5 + TAU * float(i) / float(nm)
				pts.append(to_pt + Vector2(cos(am) * rm, sin(am) * rm))
			_pen_up(pts)
			pts.append(to_pt + Vector2(0.0, -rm * 1.5))
			pts.append(to_pt + Vector2(0.0, rm * 1.5))
			_pen_up(pts)
			pts.append(to_pt + Vector2(-rm * 0.7, rm * 0.55))
			pts.append(to_pt + Vector2(rm * 0.7, rm * 0.55))
		"crack":
			# ragnatela di crepe: raggi a zig-zag che partono dal punto d'impatto
			var rays: int = 7
			for r in rays:
				var ang_c: float = TAU * float(r) / float(rays) + 0.4
				var dirc := Vector2(cos(ang_c), sin(ang_c))
				_pen_up(pts)
				pts.append(to_pt)
				for j in range(1, 5):
					var side: float = 1.0 if j % 2 == 0 else -1.0
					pts.append(to_pt + dirc * float(j) * 20.0 * power + dirc.orthogonal() * side * 7.0)
		"sigil":
			pts = _sigil_path()
		"slash":
			pts = _slash_path()
		_:
			pts = _line_path()
	if hand == "magabondi":
		var jit: float = 2.5 if shape == "sigil" else 8.0
		for i in pts.size():
			pts[i] += Vector2(_rng.randf_range(-jit, jit), _rng.randf_range(-jit, jit)) * power
	elif hand == "kairos":
		for i in pts.size():
			pts[i] += Vector2(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-3.0, 3.0))
	return pts


# Solleva la penna: il prossimo punto aggiunto parte senza collegarsi al precedente.
func _pen_up(pts: PackedVector2Array) -> void:
	if pts.size() > 0:
		_skip[pts.size() - 1] = true


# VFX-001: fendente diagonale. Pennellata che si comprime e poi si assottiglia, con una coda di filamenti.
func _slash_path() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(38.0))
	if _burst_dir.x < 0.0:
		dir.x = -dir.x                # il fendente "arriva" dal lato di chi attacca
	var half: float = 120.0 * (0.9 + 0.25 * power)
	var start: Vector2 = to_pt - dir * half
	var finish: Vector2 = to_pt + dir * half
	var bulge: Vector2 = dir.orthogonal() * 14.0
	var n: int = 18
	for i in n + 1:
		var f: float = float(i) / float(n)
		pts.append(start.lerp(finish, f) + bulge * sin(f * PI))
	# coda filamentosa: tre fili sottili dietro l'inizio del fendente
	_filaments.clear()
	for k in 3:
		var fil := PackedVector2Array()
		var spread: float = (float(k) - 1.0) * 9.0
		var len_f: float = 70.0 + 28.0 * float(k)
		for j in 7:
			var g: float = float(j) / 6.0
			fil.append(start - dir * len_f * g + dir.orthogonal() * (spread * (1.0 - g * 0.4) + sin(g * 5.0 + float(k)) * 6.0))
		_filaments.append(fil)
	return pts


func _sigil_path() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var spec: Dictionary = sigil_spec(key)
	var n: int = int(spec["n"])
	var k: int = int(spec["k"])
	var variant: int = int(spec["variant"])
	var rad: float = 135.0 * (0.9 + 0.2 * power)
	var loops: int = _gcd(n, k)
	var per: int = n / loops
	for l in loops:
		_pen_up(pts)
		for i in per + 1:
			var vi: int = (l + i * k) % n
			var ang: float = -PI * 0.5 + TAU * float(vi) / float(n)
			pts.append(to_pt + Vector2(cos(ang), sin(ang) * 0.9) * rad)
	match variant:
		1:  # anello esterno
			_pen_up(pts)
			for i in 41:
				var a1: float = -PI * 0.5 + TAU * float(i) / 40.0
				pts.append(to_pt + Vector2(cos(a1), sin(a1) * 0.9) * rad * 1.18)
		2:  # poligono interno
			_pen_up(pts)
			for i in n + 1:
				var a2: float = -PI * 0.5 + TAU * float(i % n) / float(n)
				pts.append(to_pt + Vector2(cos(a2), sin(a2) * 0.9) * rad * 0.42)
		3:  # croce che attraversa
			_pen_up(pts)
			pts.append(to_pt + Vector2(0.0, -rad * 1.1))
			pts.append(to_pt + Vector2(0.0, rad * 1.1))
			_pen_up(pts)
			pts.append(to_pt + Vector2(-rad * 1.1, 0.0))
			pts.append(to_pt + Vector2(rad * 1.1, 0.0))
	if hand == "libracorp":
		return pts
	# le mani morbide infittiscono i punti (niente spigoli a scatti); gli stacchi si ricalcolano
	var old_skip: Dictionary = _skip
	_skip = {}
	var out := PackedVector2Array()
	for i in pts.size():
		if i > 0 and not old_skip.has(i - 1):
			for q in range(1, 5):
				out.append(pts[i - 1].lerp(pts[i], float(q) / 5.0))
		out.append(pts[i])
		if old_skip.has(i):
			_skip[out.size() - 1] = true
	return out


static func _gcd(a: int, b: int) -> int:
	return a if b == 0 else _gcd(b, a % b)


func _line_path() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var d: Vector2 = to_pt - from_pt
	match hand:
		"libracorp":
			# tracciato da circuito: angoli retti
			var midx: float = from_pt.x + d.x * 0.55
			pts.append(from_pt)
			pts.append(Vector2(midx, from_pt.y))
			pts.append(Vector2(midx, to_pt.y))
			pts.append(to_pt)
			return _densify(pts, 8)
		"rondini":
			# un solo arco morbido
			var n: int = 28
			var ctrl: Vector2 = (from_pt + to_pt) * 0.5 + Vector2(0.0, -maxf(40.0, d.length() * 0.3))
			for i in n + 1:
				var f: float = float(i) / float(n)
				pts.append(from_pt.lerp(ctrl, f).lerp(ctrl.lerp(to_pt, f), f))
			return pts
		"magabondi":
			# scarabocchio: va oltre il bersaglio e torna con un anello
			var over: Vector2 = to_pt + d.normalized() * 22.0
			var n3: int = 22
			for i in n3 + 1:
				var f2: float = float(i) / float(n3)
				pts.append(from_pt.lerp(over, f2) + d.orthogonal().normalized() * sin(f2 * TAU * 2.0) * 16.0 * power)
			return pts
		_:
			var n4: int = 18
			for i in n4 + 1:
				var f3: float = float(i) / float(n4)
				pts.append(from_pt.lerp(to_pt, f3))
			return pts


func _densify(src: PackedVector2Array, per_seg: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in src.size() - 1:
		for k in per_seg:
			out.append(src[i].lerp(src[i + 1], float(k) / float(per_seg)))
	out.append(src[src.size() - 1])
	return out


# ---------- Animazione ----------

func _process(delta: float) -> void:
	var t0: int = Time.get_ticks_usec() if profile else 0
	_process_inner(delta)
	if profile:
		profile_usec += Time.get_ticks_usec() - t0


func _process_inner(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	if _t < 0.0:
		return
	var head: int = _head_index()
	if _t < draw_time + 0.02 and head != _last_emit and head < _path.size():
		_last_emit = head
		_emit_at(_path[head], head)
	if (shape == "line" or shape == "slash") and not _impact_done and _t >= draw_time:
		_impact_done = true
		for i in int(round(4.0 * _scale * power)):
			_emit_at(to_pt, -1)
		if shape == "slash":
			# pochi frammenti arancio, tutti nella direzione del colpo
			for i in maxi(2, int(round(5.0 * _scale))):
				if _parts.size() < MAX_PARTS and not _lite:
					_parts.append({"pos": to_pt, "t": 0.0, "kind": "frag", "life": 0.3, "size": _rng.randf_range(4.0, 7.0),
						"vel": Vector2.from_angle(_burst_dir.angle() + _rng.randf_range(-0.9, 0.9)) * _rng.randf_range(160.0, 320.0)})
	elif shape == "sigil" and not _impact_done and _t >= draw_time:
		# la firma si chiude e si disperde come inchiostro
		_impact_done = true
		for i in int(round(34.0 * _scale)):
			_emit_at(_path[_rng.randi_range(0, _path.size() - 1)], -1)
	for p in _parts:
		p["t"] = float(p["t"]) + delta
		p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
		if bool(p.get("grav", false)):
			p["vel"] = Vector2(p["vel"]) + Vector2(0.0, 520.0) * delta
	_parts = _parts.filter(func(p: Dictionary) -> bool: return float(p["t"]) < float(p["life"]))
	# dissolvenza: solo trasparenza, niente ridisegno; si ridisegna solo quando qualcosa si muove davvero
	var fd: float = _fade_now()
	self_modulate.a = fd
	if _overlay != null:
		_overlay.self_modulate.a = fd
	if _t < draw_time + 0.001:
		queue_redraw()
	else:
		var sig: String = str(_ghost_offsets())
		if _built_head != _head_f() or sig != _ghost_sig:
			_ghost_sig = sig
			queue_redraw()
	if _overlay != null and (_t < draw_time + 0.1 or not _parts.is_empty() or shape == "sigil"):
		_overlay.queue_redraw()


func _head_index() -> int:
	var f: float = clampf(_t / draw_time, 0.0, 1.0)
	return int(f * float(_path.size() - 1))


# Particelle: il COLORE decide come si muove la luce.
func _emit_at(at: Vector2, idx: int) -> void:
	if _lite or _parts.size() >= MAX_PARTS:
		return
	var burst: bool = idx < 0
	var dirv: Vector2 = Vector2.RIGHT
	if idx >= 1:
		dirv = (_path[idx] - _path[idx - 1]).normalized()
	var count: int = 1 if not burst else 1
	for _i in count:
		var p: Dictionary = {"pos": at, "t": 0.0, "kind": hue_name, "vel": Vector2.ZERO, "life": 0.5, "size": 3.0}
		match hue_name:
			"rosso":  # scintille che schizzano
				var a: float = _rng.randf() * TAU if not (burst and shape != "sigil") else _burst_dir.angle() + _rng.randf_range(-1.0, 1.0)
				p["vel"] = Vector2(cos(a), sin(a)) * _rng.randf_range(140.0, 320.0)
				p["life"] = 0.32
			"giallo":  # pulviscolo caldo che sale
				p["vel"] = Vector2(_rng.randf_range(-22.0, 22.0), _rng.randf_range(-70.0, -28.0))
				p["life"] = 0.85
				p["size"] = _rng.randf_range(2.0, 3.6)
			"viola":  # fumo d'inchiostro che si allarga
				p["vel"] = Vector2(_rng.randf_range(-26.0, 26.0), _rng.randf_range(-34.0, 10.0))
				p["life"] = 0.9
				p["size"] = 6.5
			"verde":  # puntini ordinati che restano sul tratto
				p["vel"] = Vector2.ZERO
				p["life"] = 0.7
				p["size"] = 2.6
			_:  # blu: filamenti veloci lungo il tratto
				p["vel"] = dirv * -220.0 if not burst else Vector2.from_angle((_rng.randf() * TAU) if shape == "sigil" else _burst_dir.angle() + _rng.randf_range(-0.8, 0.8)) * 200.0
				p["life"] = 0.34
				p["dir"] = dirv
		_parts.append(p)
	# la mano dei Magabondi lascia gocce che cadono
	if hand == "magabondi" and not burst and _rng.randf() < 0.35 and _parts.size() < MAX_PARTS:
		_parts.append({"pos": at, "t": 0.0, "kind": "drip", "vel": Vector2(_rng.randf_range(-10.0, 10.0), 10.0), "life": 0.6, "size": 2.4, "grav": true})


# ---------- Disegno ----------
# Il tratto e' fatto di MESH (strisce di triangoli con colore per vertice): 3 forme per tratto invece di
# decine di cerchi e segmenti trasparenti sovrapposti. Mentre il tratto si traccia la mesh si ricostruisce;
# a tracciamento finito la geometria resta ferma e la dissolvenza e' solo un valore di trasparenza
# (self_modulate): nessun lavoro per fotogramma. Lampo, filamenti, rune e particelle stanno in un secondo
# livello (_overlay) che si ridisegna solo finche' qualcosa si muove.

class _Fx extends Control:
	var lp: LightPaint

	func _draw() -> void:
		if lp != null:
			lp._draw_overlay(self)


func _make_overlay() -> void:
	_overlay = _Fx.new()
	_overlay.lp = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.use_parent_material = true
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


func _fade_now() -> float:
	if _warm:
		return 0.004
	var hold: float = draw_time + (0.06 if shape == "line" or shape == "slash" else 0.12)
	if _t <= hold:
		return 1.0
	return pow(1.0 - clampf((_t - hold) / maxf(0.01, life - hold), 0.0, 1.0), 1.2)


func _base_width() -> float:
	return 8.0 * power * (0.8 if hand == "libracorp" else 1.0) * (1.6 if shape == "slash" else 1.0)


func _head_f() -> float:
	return clampf(_t / draw_time, 0.0, 1.0) * float(_path.size() - 1)


func _draw() -> void:
	var t0: int = Time.get_ticks_usec() if profile else 0
	_draw_inner()
	if profile:
		profile_usec += Time.get_ticks_usec() - t0
		profile_calls += 1


func _draw_inner() -> void:
	if _path.size() < 2 or _t < 0.0:
		return
	var hf: float = _head_f()
	if hf != _built_head:
		_built_head = hf
		_rebuild_meshes(hf)
	var ghosts_on: Array = _ghost_offsets()
	_draw_layers(Transform2D.IDENTITY, Color.WHITE)
	for g in ghosts_on:
		_draw_layers(Transform2D(0.0, g), Color(1, 1, 1, 0.55))


func _draw_layers(xf: Transform2D, tint: Color) -> void:
	if _brush != null:
		draw_mesh(_mesh_halo, _brush, xf, tint)
		draw_mesh(_mesh_color, _brush, xf, tint)
	else:
		if halo_enabled:
			draw_mesh(_mesh_halo, null, xf, tint)
		draw_mesh(_mesh_color, null, xf, tint)
	draw_mesh(_mesh_core, null, xf, tint)


# Kairos: copie sfasate che saltano (effetto glitch). Vuote con gli effetti ridotti.
func _ghost_offsets() -> Array:
	var out: Array = []
	if _lite:
		return out
	for g in _ghosts:
		if fposmod(_t * 17.0 + float(g["ph"]) * 5.0, 1.0) > 0.35:
			out.append(g["off"])
	return out


func _rebuild_meshes(hf: float) -> void:
	var w: float = _base_width()
	var halo_col: Color = _color.lerp(_support, 0.35)
	if _brush != null:
		# pennellata disegnata a mano: strato largo morbido + strato pieno, entrambi con la texture
		_strip(_mesh_halo, hf, w * 3.4, 0.0, halo_col, 0.30, 0, true)
		_strip(_mesh_color, hf, w * 1.8, 0.0, _color, 0.95, 0, true)
	else:
		_strip(_mesh_halo, hf, w * 2.3, 0.0, halo_col, 0.22, 1, false)
		_strip(_mesh_color, hf, w * 0.5, 0.0, _color, 0.9, 2, false)
	_strip(_mesh_core, hf, w * 0.19, 0.6, PAL_IVORY, 1.0, 0, false)


# Striscia di triangoli lungo il tratto. profile: 0 = bordo netto (2 vertici per sezione),
# 1 = a picco (bordi trasparenti, centro pieno), 2 = pieno con bordo sfumato (4 vertici).
func _strip(mesh: ArrayMesh, hf: float, half_mult: float, half_min: float, tint: Color, alpha: float, profile: int, with_uv: bool) -> void:
	mesh.clear_surfaces()
	var n: int = _path.size()
	var last: int = mini(int(hf), n - 2)
	var frac: float = clampf(hf - float(last), 0.0, 1.0)
	var total: float = float(maxi(1, n - 1))
	var per: int = 2 if profile == 0 else (3 if profile == 1 else 4)
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var sections: int = last + 2
	for i in sections:
		var pos: Vector2 = _path[i]
		if i == last + 1:
			pos = _path[last].lerp(_path[last + 1], frac)
		var nrm: Vector2 = _vertex_normal(_path, mini(i, n - 1))
		var half: float = maxf(half_min, half_mult * _widths[mini(i, n - 1)])
		var age: float = maxf(0.0, (hf - float(i)) / total)
		var a: float = alpha * clampf(1.0 - age * 0.9, 0.12, 1.0)
		var c_full := Color(tint, a)
		var c_zero := Color(tint, 0.0)
		var u: float = (float(i) if i <= last else float(last) + frac) / total
		match profile:
			0:
				verts.append(pos - nrm * half)
				verts.append(pos + nrm * half)
				cols.append(c_full)
				cols.append(c_full)
			1:
				verts.append(pos - nrm * half)
				verts.append(pos)
				verts.append(pos + nrm * half)
				cols.append(c_zero)
				cols.append(c_full)
				cols.append(c_zero)
			_:
				verts.append(pos - nrm * half * 1.35)
				verts.append(pos - nrm * half)
				verts.append(pos + nrm * half)
				verts.append(pos + nrm * half * 1.35)
				cols.append(c_zero)
				cols.append(c_full)
				cols.append(c_full)
				cols.append(c_zero)
		if with_uv:
			for k in per:
				uvs.append(Vector2(u, float(k) / float(per - 1)))
	var idx := PackedInt32Array()
	for i in sections - 1:
		if _skip.has(i):
			continue
		for k in per - 1:
			var a0: int = i * per + k
			var b0: int = a0 + 1
			var c0: int = a0 + per
			var d0: int = c0 + 1
			idx.append_array(PackedInt32Array([a0, b0, c0, b0, d0, c0]))
	if idx.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	if with_uv:
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


# Normale condivisa tra segmenti vicini (nessuna giuntura), allungata agli angoli vivi (spigolo pieno).
func _vertex_normal(pts: PackedVector2Array, i: int) -> Vector2:
	var n1 := Vector2.ZERO
	var n2 := Vector2.ZERO
	if i > 0 and not _skip.has(i - 1):
		n1 = (pts[i] - pts[i - 1]).orthogonal().normalized()
	if i < pts.size() - 1 and not _skip.has(i):
		n2 = (pts[i + 1] - pts[i]).orthogonal().normalized()
	if n1 == Vector2.ZERO and n2 == Vector2.ZERO:
		return Vector2.UP
	if n1 == Vector2.ZERO:
		return n2
	if n2 == Vector2.ZERO:
		return n1
	var m: Vector2 = (n1 + n2)
	if m.length() < 0.001:
		return n1
	m = m.normalized()
	return m / maxf(0.55, m.dot(n1))


# Livello sopra al tratto: lampo d'impatto, filamenti, rune, mirino e particelle.
func _draw_overlay(c: Control) -> void:
	if _path.size() < 2 or _t < 0.0:
		return
	if not _filaments.is_empty():
		_draw_filaments(c)
	if hand == "kairos":
		_draw_runes(c, _head_f())
	if shape == "line" and hand == "libracorp":
		_draw_reticle(c)
	if (shape == "line" or shape == "slash") and _t >= draw_time:
		# accento d'impatto: lampo breve (30-80 ms), distinto dal resto
		var k: float = clampf((_t - draw_time) / 0.07, 0.0, 1.0)
		var flash: float = (1.0 - k) * power
		c.draw_circle(to_pt, 24.0 * flash, Color(_color, 0.30 * (1.0 - k)))
		c.draw_circle(to_pt, 9.0 * flash, Color(PAL_IVORY, 0.9 * (1.0 - k)))
	_draw_parts(c)


# Coda filamentosa del fendente: fili sottili che si rivelano mentre il tratto passa.
func _draw_filaments(c: Control) -> void:
	var reveal: float = clampf(_t / (draw_time * 0.8), 0.0, 1.0)
	for fil in _filaments:
		var upto: int = int(reveal * float(fil.size() - 1))
		for i in upto:
			var tfade: float = 1.0 - float(i) / float(fil.size())
			c.draw_line(fil[i], fil[i + 1], Color(_support, 0.45 * tfade), 3.0, true)
			c.draw_line(fil[i], fil[i + 1], Color(PAL_IVORY, 0.75 * tfade), 1.2, true)


func _draw_reticle(c: Control) -> void:
	var s: float = 30.0 * power
	var col: Color = Color(PAL_IVORY, 0.9)
	var grow: float = 1.0 + (1.0 - clampf(_t / (draw_time + 0.2), 0.0, 1.0)) * 0.6
	s *= grow
	var l: float = s * 0.45
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner: Vector2 = to_pt + Vector2(s * sx, s * sy)
			c.draw_line(corner, corner - Vector2(l * sx, 0.0), col, 2.5)
			c.draw_line(corner, corner - Vector2(0.0, l * sy), col, 2.5)


func _draw_runes(c: Control, head_f: float) -> void:
	# segni a "pettine" lungo il tratto: rune incomplete
	var last: int = mini(int(head_f), _path.size() - 2)
	var i: int = 3
	while i <= last:
		var d: Vector2 = (_path[i + 1] - _path[i]).normalized().orthogonal()
		var len: float = 9.0 if i % 6 == 3 else 5.0
		c.draw_line(_path[i] - d * len, _path[i] + d * len, Color(_color, 0.8), 2.0)
		i += 4


func _draw_parts(c: Control) -> void:
	for p in _parts:
		var k: float = 1.0 - float(p["t"]) / float(p["life"])
		var pos: Vector2 = p["pos"]
		var sz: float = float(p["size"])
		match str(p["kind"]):
			"rosso":
				var v: Vector2 = Vector2(p["vel"]).normalized()
				c.draw_line(pos, pos - v * 12.0 * k, Color(1.0, 0.9, 0.85, k), 2.0)
				c.draw_circle(pos, sz * 0.8, Color(_color, k))
			"giallo":
				c.draw_circle(pos, sz, Color(_color, 0.8 * k))
			"viola":
				var r: float = sz * (1.0 + 2.2 * (1.0 - k))
				c.draw_circle(pos, r, Color(_color, 0.26 * k))
			"verde":
				c.draw_circle(pos, sz, Color(_color, k))
				c.draw_circle(pos, sz * 0.4, Color(1, 1, 1, k))
			"frag":
				var fv: Vector2 = Vector2(p["vel"]).normalized()
				c.draw_line(pos, pos - fv * 14.0 * k, Color(PAL_ORANGE, k), sz * 0.6)
				c.draw_circle(pos, sz * 0.5, Color(PAL_IVORY, k))
			"drip":
				c.draw_line(pos, pos - Vector2(0.0, 8.0), Color(_color, 0.9 * k), sz)
			_:
				var dv: Vector2 = p.get("dir", Vector2.RIGHT)
				c.draw_line(pos, pos + dv * 20.0 * k, Color(_color, 0.9 * k), 1.6)

