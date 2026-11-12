extends SceneTree

# CONTROSEGNALE · schermate della scena: inizio, MIRINO, CONTRO, BLACKOUT, voto.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/cs_vetrina.gd -- <cartella> [nemico] [touch]

var out: String = "/tmp/cs_vetrina"
var enemy: String = "frammento"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		enemy = a[1]
	if a.size() > 2 and a[2] == "touch":
		TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _shot(n: String) -> void:
	for i in 3:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _run() -> void:
	await process_frame
	var sc: Node = load("res://scripts/controsegnale/cs_scene.gd").new()
	sc.configure({"enemy": enemy})
	root.add_child(sc)
	await create_timer(1.0).timeout
	await _shot("1_inizio")
	var b: CsBattle = sc.get("battle")
	b.press("rosso")
	b.press("giallo")
	await create_timer(0.1).timeout
	b.press("blu")
	while b.enemies[0]["attack"].is_empty():
		await process_frame
	await create_timer(0.35).timeout
	await _shot("2_mirino")
	while b.t < float(b.enemies[0]["attack"]["impact"]) - 0.01:
		await process_frame
	b.enemies[0]["segnale"] = 1.0 if b.enemies[0]["attack"]["color"] != "bianco" else b.enemies[0]["segnale"]
	if b.enemies[0]["attack"]["color"] == "bianco":
		b.dodge()
	else:
		b.press(b.enemies[0]["attack"]["color"])
	await create_timer(0.15).timeout
	await _shot("3_contro_blackout")
	await create_timer(1.2).timeout
	await _shot("4_blackout_finale")
	b.finale()
	b.enemies[0]["hp"] = 1
	b.diretta = 70.0
	b._damage_enemy(0, 5, "test")
	await create_timer(0.5).timeout
	await _shot("5_voto")
	quit(0)
