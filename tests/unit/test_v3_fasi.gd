extends SceneTree

# Opzione 2C (decisione dell'autore 6/11/2026): i boss non saltano le fasi. Un colpo enorme in fase 1 si ferma al 25%
# (si entra in fase 2), in fase 2 a 1 PV (la fase 3 si vede sempre). I frammenti (comuni) non hanno soglia e cambiano fase
# una volta sola, come nella 0.58.0 (niente doppio scudo).

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _team() -> Array:
	var t: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		t.append(BattleContent.default_entry(id))
	return t


func _init() -> void:
	_boss_floor("cabina")
	_boss_floor("manichino")
	_fragment_no_floor()
	print("test_v3_fasi: " + ("OK" if fails == 0 else "%d FALLITI" % fails))
	quit(1 if fails > 0 else 0)


func _boss_floor(id: String) -> void:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], id, 7)
	var boss: Dictionary = BattleState.boss(s)
	var mx: int = int(boss["max_hp"])
	var p3: int = int(ceil(float(mx) * BattleTypes.PHASE_3_BELOW))
	check(Stability.category(boss) == "boss", "%s e' un boss" % id)
	# fase 1: il colpo enorme si ferma sulla soglia della fase 3
	var lost: int = BattleResolver.phase_capped_loss(s, boss, mx * 5)
	check(int(boss["hp"]) - lost == p3, "%s fase 1: un colpo enorme si ferma al 25%%" % id)
	check(BattleResolver.phase_capped_loss(s, boss, 10) == 10, "%s fase 1: un colpo normale non cambia" % id)
	boss["hp"] = p3
	check(BattleResolver.phase_capped_loss(s, boss, 50) == 0, "%s fase 1: sulla soglia non si scende finche' la fase 2 non e' registrata" % id)
	# cambio di fase registrato a fine round: una sola fase, effetti una volta
	var ev: Array = []
	var shield_before: int = int(boss["shield"])
	BattleResolver._check_phase(s, ev)
	check(int(s["phase"]) == 2, "%s: si entra in fase 2" % id)
	var shields: int = 0
	for e in ev:
		if str(e.get("t", "")) == "shield":
			shields += 1
	check(shields == 1 and int(boss["shield"]) > shield_before, "%s: uno scudo solo al cambio di fase" % id)
	# fase 2: non muore prima della fase 3
	boss["shield"] = 0
	lost = BattleResolver.phase_capped_loss(s, boss, mx * 5)
	check(int(boss["hp"]) - lost == 1, "%s fase 2: il colpo mortale lascia 1 PV" % id)
	boss["hp"] = 1
	BattleResolver._check_phase(s, [])
	check(int(s["phase"]) == 3, "%s: si entra in fase 3" % id)
	# fase 3: nessuna soglia, il colpo finale passa
	lost = BattleResolver.phase_capped_loss(s, boss, mx * 5)
	check(lost >= int(boss["hp"]), "%s fase 3: il colpo finale non ha soglia (puo' chiudere lo scontro)" % id)


func _fragment_no_floor() -> void:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], "frammento_giallo", 7)
	var boss: Dictionary = BattleState.boss(s)
	var mx: int = int(boss["max_hp"])
	check(Stability.category(boss) == "comune", "il frammento e' comune")
	check(BattleResolver.phase_capped_loss(s, boss, mx * 5) == mx * 5, "frammento: nessuna soglia (il tutorial si chiude in un round)")
	# da fase 1 a fase 3 in un colpo: un solo passaggio, uno scudo solo
	boss["hp"] = int(float(mx) * 0.1)
	var ev: Array = []
	BattleResolver._check_phase(s, ev)
	var shields: int = 0
	for e in ev:
		if str(e.get("t", "")) == "shield":
			shields += 1
	check(int(s["phase"]) == 3 and shields == 1, "frammento: salto di fase con effetti una volta sola, come nella 0.58.0")
