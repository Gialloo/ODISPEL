extends SceneTree

# Clip delle correzioni dell'autore (3/11/2026): respiro leggero, passaggio da un personaggio all'altro, BREAK piu' bello.
# Salva un PNG per fotogramma a 30 fps fissi (--fixed-fps 30) in <cartella>/hud e <cartella>/break.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 --fixed-fps 30 -s tools/v3_hud_correzioni.gd -- <cartella>

var out: String = "/tmp/v3correzioni"
var bt: Node
var _n: int = 0


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out.path_join("hud"))
	DirAccess.make_dir_recursive_absolute(out.path_join("break"))
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	_run()


func _rec(dir: String, frames: int) -> void:
	for i in frames:
		await process_frame
		var im: Image = root.get_viewport().get_texture().get_image()
		im.resize(1200, 540, Image.INTERPOLATE_BILINEAR)
		im.save_png(out.path_join(dir).path_join("f_%04d.png" % _n))
		_n += 1


func _wait_turn() -> void:
	var g: int = 0
	while not bool(bt.get("waiting")) and g < 3000:
		g += 1
		await process_frame


func _run() -> void:
	await process_frame
	bt = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	# --- tre turni di fila: entrata di ogni personaggio, respiro, scelta ---
	var solo_break: bool = OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "break"
	for k in (0 if solo_break else 3):
		await _wait_turn()
		await _rec("hud", 55)
		bt.call("_pick", "attack")
		await _rec("hud", 20)
		bt.call("_command", "guard")
		await _rec("hud", 8)
	print("HUD ", _n)
	# --- BREAK: equilibrio del nemico a 1, poi un attacco ---
	_n = 0
	await _wait_turn()
	bt.b["units"][BattleState.BOSS_ID]["balance"] = 1
	bt.call("_command", "attack")
	await _rec("break", 110)
	print("BREAK ", _n)
	quit()
