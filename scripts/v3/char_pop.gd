class_name CharPop
extends CanvasLayer

# PERSONAGGI NITIDI E A COLORI SOPRA LA SCENA SBIANCATA (riferimento dell'autore, 3/11/2026: nel BREAK e nell'attacco di
# squadra il mondo si sbianca e si sfoca, i personaggi restano a colori). Come si separano dalla scena: i modelli della
# squadra stanno anche sullo strato 3D numero 2 (LAYER); una seconda telecamera che vede solo quello strato li disegna in
# una SubViewport col fondo trasparente, e la sua immagine va sopra al vetro rotto (strato 5) e sotto all'interfaccia (10).
# PRESTAZIONI: quando alpha e' 0 la SubViewport non si aggiorna e il rettangolo e' nascosto (costo zero); quando serve
# ridisegna solo i 4 personaggi, alla stessa risoluzione 3D ridotta del gioco.

const LAYER: int = 2          # bit dello strato 3D dei personaggi (1 = tutto il resto)

var src: Camera3D              # la telecamera della battaglia da copiare
var alpha: float = 0.0         # 0 = spento, 1 = personaggi pieni sopra la scena
var targets: Array = []        # i modelli della squadra (si rimettono sullo strato a ogni accensione: pezzi nuovi compresi)
var _was_on: bool = false

var _vp: SubViewport
var _cam: Camera3D
var _rect: TextureRect


# Mette tutti i modelli sotto n anche sullo strato dei personaggi (restano visibili alla telecamera normale).
static func mark(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers |= LAYER
	for c in n.get_children():
		mark(c)


func _ready() -> void:
	layer = 6
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vp.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.cull_mask = LAYER
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_cam.environment = e
	_vp.add_child(_cam)
	_rect = TextureRect.new()
	_rect.texture = _vp.get_texture()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	add_child(_rect)


func _process(_d: float) -> void:
	var on: bool = alpha > 0.01 and src != null and is_instance_valid(src)
	_rect.visible = on
	if on and not _was_on:
		for t in targets:
			if is_instance_valid(t):
				mark(t)
	_was_on = on
	if not on:
		if _vp.render_target_update_mode != SubViewport.UPDATE_DISABLED:
			_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var root_vp: Viewport = get_viewport()
	var sz: Vector2i = Vector2i(root_vp.get_visible_rect().size)
	if _vp.size != sz:
		_vp.size = sz
	_vp.scaling_3d_mode = root_vp.scaling_3d_mode
	_vp.scaling_3d_scale = root_vp.scaling_3d_scale
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_cam.global_transform = src.global_transform
	_cam.fov = src.fov
	_cam.near = src.near
	_cam.far = src.far
	_cam.current = true
	_rect.modulate.a = alpha
