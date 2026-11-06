extends SceneTree

# Clip del ritratto vivo dell'HUD (autore, 3/11/2026: «non sono vive»): entrata, respiro e strisce che scorrono, SKILL scelta,
# ULTIMATE scelta e confermata (cut-in col ritratto 2D).
# Salva un PNG per fotogramma a 30 fps fissi, poi: ffmpeg -framerate 30 -i <cartella>/f_%04d.png -pix_fmt yuv420p clip.mp4
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 --fixed-fps 30 -s tools/v3_ritratto_vivo.gd -- <cartella>

var out: String = "/tmp/v3vivo"
var bt: Node
var _n: int = 0


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	Settings.skip_cutin = false
	Settings.cutin_once = false
	RitrattoLampo.tempo_fisso = true      # i lampi contano i fotogrammi: nella clip durano quanto nel gioco
	_run()


func _rec(frames: int) -> void:
	for i in frames:
		await process_frame
		var im: Image = root.get_viewport().get_texture().get_image()
		im.resize(1200, 540, Image.INTERPOLATE_BILINEAR)
		im.save_png(out.path_join("f_%04d.png" % _n))
		_n += 1


func _run() -> void:
	await process_frame
	bt = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	for i in 3:
		await process_frame
	for uid in bt.b["units"]:
		if str(bt.b["units"][uid].get("char", "")) == "rio":
			bt.b["units"][uid]["gauge"] = BattleTypes.GAUGE_MAX      # ULTIMATE pronta, per poterla scegliere
	for k in 40:
		var g: int = 0
		while not bool(bt.get("waiting")) and g < 2000:
			g += 1
			await process_frame
		if str(bt.call("_unit_of", bt.get("cur_pid")).get("char", "")) == "rio":
			break
		bt.call("_pick", "guard")
		for i in 3:
			await process_frame
		bt.call("_pick", "guard")
	var w: Node = bt.get("_wheel")
	w.set("appear", 0.0)                 # rifà l'entrata per la clip
	await _rec(75)                       # entrata + respiro
	bt.call("_pick", "skill")
	await _rec(30)
	bt.call("_pick", "")
	await _rec(15)
	bt.call("_pick", "ult")
	await _rec(45)
	bt.call("_command", "ult")           # conferma: parte il cut-in con il ritratto 2D che attraversa lo schermo
	await _rec(90)
	print("FOTOGRAMMI ", _n)
	quit()
