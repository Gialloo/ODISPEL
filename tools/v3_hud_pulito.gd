extends SceneTree

# Screenshot del feedback dei tester (6/11/2026): tendina delle ABILITA' contro un boss (le barre del nemico non devono
# coprirla), turno libero (HUD pulito) e chat della diretta di Rio durante una mossa (deve restare il tempo di leggerla).
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/v3_hud_pulito.gd -- <cartella>

var out: String = "/tmp/v3hudpulito"
var bt: Node


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	_run()


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("FOTO ", name)


func _wait_turn() -> void:
	var g: int = 0
	while not bool(bt.get("waiting")) and g < 4000:
		g += 1
		await process_frame


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	await process_frame
	bt = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	await _wait_turn()
	await _frames(60)
	await _shot("1_turno_libero")
	bt.call("_open_skills")
	await _frames(20)
	await _shot("2_tendina_abilita")
	bt.call("_close_skills")
	# la diretta di Rio: Hype alto, poi una mossa (la chat parla durante le mosse, non mentre si sceglie)
	var rio: Dictionary = Kits.unit_of_char(bt.b, Kits.RIO)
	if not rio.is_empty():
		rio["hype"] = 60
	var best: int = 0
	var after: bool = false
	for turn in 4:
		await _wait_turn()
		bt.call("_command", "attack")
		for i in 900:
			await process_frame
			var ch: Array = bt.get("_cam_hud").get("_chat")
			if ch.size() > best:
				best = ch.size()
				await _shot("3_chat_rio_%d" % best)
			if best >= 2 and not after and bool(bt.get("waiting")) and not ch.is_empty():
				after = true
				await _frames(10)
				await _shot("4_chat_mentre_si_sceglie")
			if bool(bt.get("waiting")):
				break
		if best >= 3 and after:
			break
	if best == 0:
		print("CHAT MAI APPARSA")
	quit()
