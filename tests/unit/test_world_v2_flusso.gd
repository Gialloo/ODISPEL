extends SceneTree
# Flusso mappa -> battaglia V2 -> mappa: godot -s tests/unit/test_world_v2_flusso.gd
var fails := 0
func ok(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)
func _init() -> void:
	_run()
func _wait_scene(key: String, secs: float) -> bool:
	var t := 0.0
	while t < secs:
		await create_timer(0.1).timeout
		t += 0.1
		if SceneRouter.is_current(key):
			return true
	return false
func _run() -> void:
	Settings.tutorial_done = true
	WorldV2Ctx.reset()
	WorldV2Ctx.active = true
	WorldV2Ctx.read["intro"] = true
	var w = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(w)
	current_scene = w
	await create_timer(0.3).timeout
	w.player = Vector2(12, 2)
	w._launch_battle("libracorp")
	ok(await _wait_scene("battle_v2", 8.0), "si arriva alla battaglia V2")
	ok(WorldV2Ctx.pending == "libracorp" and WorldV2Ctx.boss_id == "distributore", "contesto passato")
	await create_timer(1.0).timeout
	var b = current_scene
	ok(b != null and b.has_method("_exit"), "scena battaglia attiva")
	# fuga a meta' battaglia
	b._exit()
	ok(await _wait_scene("world_v2", 8.0), "si torna alla mappa")
	await create_timer(0.5).timeout
	ok(current_scene.player == current_scene.SPAWN, "fuga: torna al rifugio")
	# vittoria
	WorldV2Ctx.pending = "libracorp"
	WorldV2Ctx.result = "win"
	WorldV2Ctx.pos = Vector2(12, 2)
	current_scene.get_tree().reload_current_scene()
	await create_timer(0.8).timeout
	ok(bool(WorldV2Ctx.defeated.get("libracorp", false)), "vittoria registrata")
	ok(current_scene.trainers[0]["done"], "sorvegliante segnato come battuto")
	print("flusso: ", "OK" if fails == 0 else "FALLITI %d" % fails)
	quit(1 if fails > 0 else 0)
