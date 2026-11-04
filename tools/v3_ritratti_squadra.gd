extends SceneTree

# Ritratti a livelli di tutta la squadra nell'HUD (bozze approvate dall'autore, 4/11/2026): una schermata per il turno di
# ognuno (Lance, Nox, Saul e Rio) e una clip corta per vedere testa e pezzo che si muovono.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 --fixed-fps 30 -s tools/v3_ritratti_squadra.gd -- <cartella>
# Poi: ffmpeg -framerate 30 -i <cartella>/<id>_%03d.png -pix_fmt yuv420p <id>.mp4

var out: String = "/tmp/v3squadra"
var bt: Node


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	_run()


func _rec(id: String, frames: int) -> void:
	for i in frames:
		await process_frame
		var im: Image = root.get_viewport().get_texture().get_image()
		if i == frames - 1:
			im.save_png(out.path_join(id + ".png"))
		im.resize(1200, 540, Image.INTERPOLATE_BILINEAR)
		im.save_png(out.path_join("%s_%03d.png" % [id, i]))


func _run() -> void:
	await process_frame
	bt = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	for i in 3:
		await process_frame
	var g: int = 0
	while not bool(bt.get("waiting")) and g < 2000:
		g += 1
		await process_frame
	# il ritratto e' quello di chi e' di turno: per fotografarli tutti si cambia solo il disegno, il resto resta uguale
	var w: Node = bt.get("_wheel")
	for id in ["ferri", "nox", "saul", "zecca"]:
		w.call("set_who", id)
		w.set("appear", 0.0)
		await _rec(id, 50)                      # entrata e respiro
		bt.call("_pick", "attack")              # scatto: la testa e il pezzo frustano e si assestano
		await _rec(id + "_scatto", 40)
		bt.call("_pick", "")
		await _rec(id + "_dopo", 2)
		print("RITRATTO ", id)
	quit()
