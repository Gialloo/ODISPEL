extends SceneTree

# ARCHETIPI DEI NEMICI (Review 01 del game director, 4/11/2026): ogni nemico dell'atto 1 ha un problema da porre e una
# lettura di Echo che sta sull'avviso (titolo e resto corto); la Scheggia, predatrice, punta il piu' ferito.
var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _team() -> Array:
	var t: Array = []
	for id in ["lance", "nox", "rio", "saul"]:
		t.append(BattleContent.default_entry(id))
	return t


func _init() -> void:
	for id in ["distributore", "semaforo", "cabina", "manichino", "cassaforte", "autovelox", "frammento_rosso", "frammento_verde", "frammento_blu", "gregario"]:
		var a: String = EnemyArchetypes.of(id)
		check(EnemyArchetypes.ARCHETYPES.has(a), "%s ha un archetipo (%s)" % [id, a])
		var parts: Array = CombatHud.notice_parts(EnemyArchetypes.reading(id))
		check(str(parts[1]) != "", "la lettura di %s sta sull'avviso: «%s»" % [id, EnemyArchetypes.reading(id)])
	# tutti e cinque gli archetipi sono usati nell'atto 1
	var used: Dictionary = {}
	for id in EnemyArchetypes.ENEMIES:
		used[EnemyArchetypes.of(str(id))] = true
	for a in EnemyArchetypes.ARCHETYPES:
		check(used.has(a), "archetipo usato: " + str(a))
	# la Scheggia punta il piu' ferito, con qualsiasi seme
	for seed_value in [1, 7, 42, 99]:
		var s: Dictionary = BattleState.create_solo("IO", _team(), [], "frammento_blu", seed_value)
		Gregario.add(s, "frammento_rosso")
		var hurt: Dictionary = {}
		for p in s["players"]:
			var u: Dictionary = BattleState.active_unit(s, str(p["id"]))
			if str(u["char"]) == "nox":
				u["hp"] = int(float(u["max_hp"]) * 0.3)
				hurt = p
		Gregario.telegraph(s)
		check(str(s["telegraph2"]["target"]) == str(hurt["id"]), "seme %d: la Scheggia punta Nox ferita" % seed_value)
	print("test_v3_archetipi: ", "OK" if fails == 0 else "%d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
