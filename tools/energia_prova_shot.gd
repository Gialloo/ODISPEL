extends SceneTree

# PROVA energia rossa della SKILL: screenshot statico e fotogrammi dell'animazione.
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/energia_prova_shot.gd -- <cartella_output>

var out_dir: String = "/tmp"


func _shot(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out_dir.path_join("en_%s.png" % name))


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.4).timeout
	scn.energy_mode = "off"
	scn._tap(scn.wheel_front.hits[1].get_center())
	await create_timer(1.2).timeout
	await _shot("0_senza")
	scn._cancel()
	await create_timer(0.8).timeout
	scn.energy_mode = "static"
	scn._tap(scn.wheel_front.hits[1].get_center())
	await create_timer(1.2).timeout
	await _shot("1_statica")
	scn._cancel()
	await create_timer(0.8).timeout
	scn.energy_mode = "anim"
	scn._tap(scn.wheel_front.hits[1].get_center())
	for i in 24:
		await create_timer(0.05).timeout
		if i % 1 == 0:
			await _shot("anim_%02d" % i)
	print("FINE energy_k=", scn.energy_k)
	quit(0)
