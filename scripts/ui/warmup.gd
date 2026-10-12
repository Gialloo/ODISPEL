class_name Warmup
extends RefCounted

# Prepara in secondo piano quello che servira' tra poco, cosi' i cambi di schermata non
# aspettano il disco e la compilazione degli script: le schermate (scene + script) e la musica
# si caricano su un altro thread mentre si guarda l'hub, e due shader poco usati si
# "scaldano" disegnandoli una volta in un angolo (altrimenti il primo uso fa uno scatto).
# Non fa nulla nei test senza schermo.

static var _requested: Dictionary = {}


static func enabled() -> bool:
	return DisplayServer.get_name() != "headless"


# Carica in secondo piano tutte le schermate tranne quella corrente. Sicuro da richiamare piu' volte.
static func scenes(except_path: String = "") -> int:
	if not enabled():
		return 0
	var n: int = 0
	for key in SceneRouter.SCENES:
		var path: String = SceneRouter.path_of(str(key))
		if path == except_path or _requested.has(path):
			continue
		_requested[path] = true
		if ResourceLoader.load_threaded_request(path, "PackedScene") == OK:
			n += 1
	return n


# Musica ed effetti, per l'audio manager.
static func audio(paths: Array) -> int:
	if not enabled():
		return 0
	var n: int = 0
	for path in paths:
		if _requested.has(path) or not ResourceLoader.exists(str(path)):
			continue
		_requested[path] = true
		if ResourceLoader.load_threaded_request(str(path)) == OK:
			n += 1
	return n


# Disegna una volta, in un angolo e per due fotogrammi, gli shader che non sono sempre a schermo.
static func shaders(host: Control) -> void:
	if not enabled():
		return
	var rects: Array = []
	for fn in [ScreenFx.cctv, ScreenFx.halftone]:
		var r: ColorRect = fn.call(host)
		r.anchor_right = 0.0
		r.anchor_bottom = 0.0
		r.offset_right = 2.0
		r.offset_bottom = 2.0
		rects.append(r)
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	await tree.process_frame
	await tree.process_frame
	for r in rects:
		if is_instance_valid(r):
			r.queue_free()
