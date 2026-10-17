extends SceneTree

# Accessibilita' nel Test V2: scosse, lampi, effetti ridotti e salto dell'ultimate rispettano le impostazioni del giocatore.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_accessibilita.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


# Le impostazioni si applicano DOPO l'avvio della scena (all'avvio il gioco rilegge il file delle impostazioni).
func _new_scene(shake: float, flash: float, light: bool, skip: bool) -> BattleV2:
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.0).timeout
	Settings.shake = shake
	Settings.flash = flash
	Settings.light_fx = light
	Settings.skip_cutin = skip
	return scn


func _any_emitting(scn: BattleV2) -> bool:
	for ps in scn.streaks:
		if (ps as CPUParticles2D).emitting:
			return true
	return false


func _run() -> void:
	Settings.tutorial_done = true
	var old: Dictionary = {"shake": Settings.shake, "flash": Settings.flash, "light": Settings.light_fx, "skip": Settings.skip_cutin}
	# A) tutto al minimo / effetti ridotti
	var a: BattleV2 = await _new_scene(0.0, 0.0, true, false)
	a._select(0)
	_check("shake 0: nessuna spinta della camera alla selezione", a.cam_v == Vector2.ZERO and is_zero_approx(a.zoom_v))
	_check("flash 0: nessun lampo alla selezione", is_zero_approx(a.flash))
	a._select(2)
	a._confirm()
	_check("flash 0: l'esplosione nera dell'ultimate non parte", a.ult_cut == 0)
	_check("shake 0: nessuna spinta alla conferma", a.cam_v == Vector2.ZERO and is_zero_approx(a.zoom_v))
	_check("flash 0: nessun lampo alla conferma", is_zero_approx(a.flash))
	await create_timer(0.4).timeout
	a._select(1)
	await create_timer(0.4).timeout
	_check("effetti ridotti: nessuna particella di scia", not _any_emitting(a))
	a.queue_free()
	await process_frame
	# B) tutto al massimo
	var b: BattleV2 = await _new_scene(1.0, 1.0, false, false)
	b._select(0)
	_check("shake 1: la camera viene spinta", b.cam_v.length() > 1.0)
	_check("flash 1: lampo alla selezione", is_equal_approx(b.flash, 1.0))
	b._select(2)
	b._confirm()
	_check("flash 1: l'esplosione dell'ultimate parte", b.ult_cut == BattleV2.CUT_FRAMES)
	b.queue_free()
	await process_frame
	# C) salto dell'ultimate
	var c: BattleV2 = await _new_scene(1.0, 1.0, false, true)
	c._select(2)
	c._confirm()
	_check("skip_cutin: nessuna esplosione", c.ult_cut == 0)
	c.queue_free()
	await process_frame
	# D) lampi a meta': il velo nero segue l'intensita'
	var d: BattleV2 = await _new_scene(1.0, 0.5, false, false)
	d.ult_hold = true
	d._select(2)
	d._confirm()
	await create_timer(0.3).timeout
	_check("flash 0.5: velo nero al 50%", is_equal_approx(d.cut_black.color.a, 0.5))
	d.ult_hold = false
	d.queue_free()
	await process_frame
	Settings.shake = old["shake"]
	Settings.flash = old["flash"]
	Settings.light_fx = old["light"]
	Settings.skip_cutin = old["skip"]
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
