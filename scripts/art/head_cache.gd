class_name HeadCache
extends RefCounted

# Cache dei volti anime. Disegnarli a ogni fotogramma costa molto (decine di poligoni ciascuno) ma cambiano solo con
# personaggio, colore ed espressione: si disegnano UNA volta in una piccola texture (SubViewport) e poi si riusano,
# tinti e ridimensionati come serve. Se la texture non e' ancora pronta (o non c'e' un display) si disegna a mano.
#
#   if not HeadCache.draw(self, head, r, char_id, col, expression, tint, HeadCache.BOTH): ...disegno diretto...

const HALF: float = 80.0               # la texture copre 160x160 unita' attorno al centro della testa (raggio base 27)
const BASE_R: float = 27.0
const BACK: int = 0                    # solo i capelli dietro
const FRONT: int = 1                   # solo il volto
const BOTH: int = 2                    # capelli + volto (quando nulla sta in mezzo)

static var _entries: Dictionary = {}   # chiave -> {} (in creazione) oppure {"vp": SubViewport, "ready_at": frame}
static var _host: Node = null


class Painter extends Control:
	var char_id: String = ""
	var col: Color = Color.WHITE
	var expression: String = "neutral"
	var layer: int = HeadCache.BOTH

	func _draw() -> void:
		var c := Vector2(HeadCache.HALF, HeadCache.HALF)
		if layer != HeadCache.FRONT:
			AnimeFace.hair_back(self, c, HeadCache.BASE_R, char_id, col, Color.WHITE)
		if layer != HeadCache.BACK:
			AnimeFace.face(self, c, HeadCache.BASE_R, char_id, col, Color.WHITE, expression)


# Contenitore delle texture: sta nell'albero finche' vive il gioco. Dopo una pausa dell'app le texture possono andare
# perse, quindi in quel caso si svuota tutto e si rifanno da capo.
class Host extends Node:
	func _notification(what: int) -> void:
		if what == NOTIFICATION_APPLICATION_RESUMED:
			HeadCache.clear()


static func clear() -> void:
	for k in _entries:
		var d: Dictionary = _entries[k]
		if d.has("vp") and is_instance_valid(d["vp"]):
			(d["vp"] as Node).queue_free()
	_entries.clear()


static func available() -> bool:
	return DisplayServer.get_name() != "headless" and Engine.get_main_loop() is SceneTree


# Risoluzione della texture in base a quanto grande finisce sullo schermo (scale = pixel per unita' base).
static func _bucket(on_screen: float) -> float:
	if on_screen < 0.6:
		return 0.5
	if on_screen < 1.2:
		return 1.0
	return 2.0


# Disegna il volto da `ci` (centro `center`, raggio `r`). Ritorna false se non e' possibile: allora si disegna a mano.
static func draw(ci: CanvasItem, center: Vector2, r: float, char_id: String, col: Color, expression: String, tint: Color, layer: int = BOTH) -> bool:
	if not available() or not ci.is_inside_tree():
		return false
	var unit: float = r / BASE_R
	var pixels: float = ci.get_global_transform_with_canvas().get_scale().x * unit
	var ss: float = _bucket(pixels)
	var key: String = "%s|%s|%s|%d|%.1f" % [char_id, col.to_html(), expression, layer, ss]
	var e: Variant = _entries.get(key)
	if e == null:
		_entries[key] = {}                 # si crea a fine fotogramma: non si aggiungono nodi mentre si disegna
		_make.call_deferred(ci.get_tree(), key, char_id, col, expression, layer, ss)
		return false
	var d: Dictionary = e
	if d.is_empty() or Engine.get_frames_drawn() < int(d["ready_at"]) or not is_instance_valid(d["vp"]):
		return false
	var tex: Texture2D = (d["vp"] as SubViewport).get_texture()
	var half: float = HALF * unit
	ci.draw_texture_rect(tex, Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0), false, tint)
	return true


static func _make(tree: SceneTree, key: String, char_id: String, col: Color, expression: String, layer: int, ss: float) -> void:
	if tree == null:
		_entries.erase(key)
		return
	if _host == null or not is_instance_valid(_host):
		_host = Host.new()
		_host.name = "HeadCacheHost"
		tree.root.add_child(_host)
	var vp := SubViewport.new()
	vp.size = Vector2i(int(HALF * 2.0 * ss), int(HALF * 2.0 * ss))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter := Painter.new()
	painter.char_id = char_id
	painter.col = col
	painter.expression = expression
	painter.layer = layer
	painter.scale = Vector2(ss, ss)
	painter.size = Vector2(HALF, HALF) * 2.0
	painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.add_child(painter)
	_host.add_child(vp)
	_entries[key] = {"vp": vp, "ready_at": Engine.get_frames_drawn() + 3}
