extends SceneTree
# Mappa del Test V2: godot -s tests/unit/test_world_v2.gd
var fails := 0
func ok(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)
func _tp(w, p: Vector2) -> void:
	w.player = p
	w._seed_trail()
	w._place_all()
func _init() -> void:
	_run()
func _run() -> void:
	Settings.tutorial_done = true
	WorldV2Ctx.reset()
	WorldV2Ctx.active = true
	var scn = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(0.5).timeout
	ok(scn.mode == "dialog", "intro all'avvio")
	while scn.mode == "dialog":
		scn._last_adv = -10.0
		scn._advance_dialog()
	ok(scn.mode == "walk", "dopo l'intro si cammina")
	ok(scn.chars.size() == mini(3, scn.roster["team"].size()), "front row: %d personaggi (panchina esclusa)" % scn.chars.size())
	# cammina: la posizione cambia, i muri fermano
	var p0: Vector2 = scn.player
	scn.test_move = Vector2(0, -1)
	await create_timer(0.5).timeout
	ok(scn.player.y < p0.y - 1.0, "il personaggio cammina")
	scn.player = Vector2(0, -2)
	scn.test_move = Vector2(-1, 0)
	await create_timer(6.0).timeout
	ok(scn.player.x >= -9.0 + 0.3, "il muro ovest ferma (x=%.2f)" % scn.player.x)
	# la serranda chiusa blocca la via nord
	scn.test_move = Vector2.ZERO
	_tp(scn, Vector2(0, -12))
	scn.test_move = Vector2(0, -1)
	await create_timer(1.5).timeout
	ok(scn.player.y > -15.0, "serranda chiusa blocca (z=%.2f)" % scn.player.y)
	scn.test_move = Vector2.ZERO
	# i seguaci stanno vicino
	for i in range(1, scn.chars.size()):
		var d: float = (scn.chars[i]["pos"] as Vector2).distance_to(scn.player)
		ok(d < 4.0, "seguace %d vicino (%.1f)" % [i, d])
	# oggetto interagibile
	_tp(scn, Vector2(4.6, -2.0))
	await create_timer(0.3).timeout
	ok(not scn._near.is_empty() and scn._near["id"] == "bacheca", "bacheca interagibile")
	scn._last_adv = -10.0
	scn._interact_pressed()
	ok(scn.mode == "dialog", "interazione apre il dialogo")
	while scn.mode == "dialog":
		scn._last_adv = -10.0
		scn._advance_dialog()
	# scheda del boss con colore e mosse dai dati
	var card: Array = scn._boss_card()
	var txt: String = JSON.stringify(card)
	ok(txt.contains("GIALLO") and txt.contains("VIOLA") and txt.contains("Scarica") and txt.contains("sanguinamento"), "scheda boss completa")
	# incontro: il sorvegliante vede, "!" e poi dialogo
	_tp(scn, Vector2(9.0, 2.0))
	var k := 0
	while scn.mode == "walk" and k < 40:
		await create_timer(0.05).timeout
		k += 1
	ok(scn.mode == "exclaim", "il sorvegliante fa '!' (mode=%s)" % scn.mode)
	ok((scn.trainers[0]["excl"] as Label3D).visible, "'!' visibile")
	k = 0
	while scn.mode != "dialog" and k < 120:
		await create_timer(0.05).timeout
		k += 1
	ok(scn.mode == "dialog", "dopo il '!' parte il dialogo")
	# fuori dal cono non scatta
	scn.mode = "walk"; scn.dlg.visible = false
	var t: Dictionary = scn.trainers[0]
	scn.player = Vector2(15, -0.3)
	ok(not scn._sees(t), "dietro/di lato non vede")
	scn.player = Vector2(10, 2)
	ok(scn._sees(t), "davanti vede")
	t["done"] = true
	ok(not scn._sees(t), "battuto non vede piu'")
	# esito battaglia: due vittorie aprono la serranda
	scn.free()
	WorldV2Ctx.reset(); WorldV2Ctx.active = true
	WorldV2Ctx.defeated = {"libracorp": true, "magabondo": true}
	var s2 = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(s2)
	await create_timer(0.3).timeout
	ok(s2.gate_open, "serranda aperta con due nulla osta")
	s2.mode = "walk"; s2.dlg.visible = false
	s2.player = Vector2(0, -12)
	s2.test_move = Vector2(0, -1)
	await create_timer(1.0).timeout
	ok(s2.player.y < -14.0, "serranda aperta: si passa (z=%.2f)" % s2.player.y)
	s2.test_move = Vector2.ZERO
	# sconfitta: ritorno al rifugio
	s2.free()
	WorldV2Ctx.reset(); WorldV2Ctx.active = true
	WorldV2Ctx.pending = "libracorp"; WorldV2Ctx.result = "lose"; WorldV2Ctx.pos = Vector2(12, 2)
	var s3 = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(s3)
	await create_timer(0.3).timeout
	ok(s3.player == s3.SPAWN, "sconfitta: torna al rifugio")
	ok(WorldV2Ctx.pending == "", "esito consumato")
	# la battaglia V2 torna alla mappa
	ok(WorldV2Ctx.back_scene() == "world_v2", "battaglia torna alla mappa")
	WorldV2Ctx.reset()
	ok(WorldV2Ctx.back_scene() == "squad_v2", "senza mappa torna alla squadra")
	print("world_v2: ", "OK" if fails == 0 else "FALLITI %d" % fails)
	quit(1 if fails > 0 else 0)
