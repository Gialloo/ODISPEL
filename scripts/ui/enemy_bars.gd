extends Control
## 0.16: barre di vita dei nemici disegnate in 2D sopra la testa (stile richiesto dall'autore):
## bordo nero, vita rossa, vita appena tolta in bianco (resta finché i colpi continuano),
## sotto a sinistra la targhetta "LV n". Solo livello e salute, nient'altro.
## In 2D perché la vecchia barra 3D a cartellone non si accorciava (il billboard ignorava la scala)
## e perché così resta nitida e della stessa grandezza a ogni distanza, anche sul telefono.

const RED := Color(0.86, 0.1, 0.12)
const WHITE := Color(1, 1, 1)
const BACK := Color(0.16, 0.16, 0.18, 0.92)
const BLACK := Color(0, 0, 0)
const MAX_DIST := 34.0

var font: Font
## 0.18: numeri dei danni. Ogni colpo fa saltare il suo numero sopra il nemico: bianco per i colpi
## normali, oro e più grande per quelli forti (18+). Salgono, si allargano un attimo e svaniscono.
const POP_TIME := 0.75
const GOLD := Color(1.0, 0.78, 0.2)
var pops: Array = []                 # {pos, n, big, t, dx}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("dmg_pops")

func pop(at: Vector3, dmg: float, big: bool) -> void:
	if pops.size() > 40:
		pops.pop_front()
	pops.append({"pos": at, "n": int(round(dmg)), "big": big, "t": 0.0, "dx": randf_range(-44.0, 44.0)})

func _process(d: float) -> void:
	for p in pops:
		p.t += d
	pops = pops.filter(func(p): return p.t < POP_TIME)
	queue_redraw()

func _draw() -> void:
	if not Run.running:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var vh: float = get_viewport_rect().size.y
	var u: float = vh / 720.0           # misure pensate a 720 p, crescono con lo schermo
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_dead() or e.boss:       # il boss ha la sua barra grande in alto
			continue
		var head: Vector3 = e.global_position + Vector3(0, _head_h(e), 0)
		if cam.is_position_behind(head):
			continue
		var dist: float = cam.global_position.distance_to(head)
		if dist > MAX_DIST:
			continue
		_bar(cam.unproject_position(head), e, u)
	_draw_pops(cam, u)

func _draw_pops(cam: Camera3D, u: float) -> void:
	if font == null:
		return
	for p in pops:
		if cam.is_position_behind(p.pos):
			continue
		var k: float = p.t / POP_TIME
		var at: Vector2 = cam.unproject_position(p.pos)
		# scatto in su e piccolo rimbalzo di grandezza all'inizio
		var grow: float = 1.0 + 0.45 * maxf(0.0, 1.0 - p.t / 0.12)
		var fs := int(round((30.0 if p.big else 21.0) * u * grow))
		var txt := str(p.n)
		var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(at.x + p.dx * u - w * 0.5, at.y - 34.0 * u - 46.0 * u * (1.0 - pow(1.0 - k, 2.0)))
		var a: float = 1.0 if k < 0.6 else 1.0 - (k - 0.6) / 0.4
		draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(maxf(3.0, 4.0 * u)), Color(0, 0, 0, a))
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(GOLD if p.big else WHITE, a))

func _head_h(e: Node) -> float:
	if e.arch == "brute":
		return 2.45
	if e.arch == "conduit":
		return 2.35
	return 1.85

func _bar(at: Vector2, e: Node, u: float) -> void:
	var w := 96.0 * u
	var h := 8.0 * u
	var b := maxf(1.5, 2.0 * u)         # bordo nero
	if e.arch == "brute":
		w *= 1.3
	var r := Rect2(at.x - w * 0.5, at.y - h, w, h)
	draw_rect(r.grow(b), BLACK)
	draw_rect(r, BACK)
	var kw: float = clampf(e.hp_white / e.max_hp, 0.0, 1.0)
	var kr: float = clampf(e.hp / e.max_hp, 0.0, 1.0)
	if kw > kr:
		draw_rect(Rect2(r.position, Vector2(w * kw, h)), WHITE)
	if kr > 0.0:
		draw_rect(Rect2(r.position, Vector2(w * kr, h)), RED)
	# targhetta del livello: bianca con bordo nero, attaccata sotto a sinistra
	var fs := int(round(11.0 * u))
	var txt := "LV %d" % int(e.wave)
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if font else fs * 2.5
	var tag := Rect2(r.position.x, r.end.y + b, tw + 8.0 * u, fs + 3.0 * u)
	draw_rect(tag.grow(b * 0.75), BLACK)
	draw_rect(tag, Color(0.95, 0.95, 0.95))
	if font:
		draw_string(font, Vector2(tag.position.x + 4.0 * u, tag.end.y - 3.0 * u), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BLACK)
	# 0.18: colpi di fila sullo stesso nemico, finché il bianco è fermo
	if font and e.hit_chain >= 2 and e.hp_white > e.hp:
		var ht := "%d HITS" % e.hit_chain
		var hfs := int(round(13.0 * u))
		var hw: float = font.get_string_size(ht, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs).x
		var hp := Vector2(r.end.x - hw, r.position.y - b - 4.0 * u)
		draw_string_outline(font, hp, ht, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, int(maxf(2.0, 3.0 * u)), BLACK)
		draw_string(font, hp, ht, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, WHITE)
