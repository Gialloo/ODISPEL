extends SceneTree

# Riserva di squadra, reazioni, nuove combo, niente catene infinite.
#   godot --headless --path . -s res://tests/unit/test_reactions.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _spec(id: String) -> Dictionary:
	return {"id": id, "name": id, "ai": false, "team": [BattleContent.default_entry("kira"), BattleContent.default_entry("dax"), BattleContent.default_entry("elle")]}


# round con una carica pesante annunciata su "a"
func _heavy_state() -> Dictionary:
	var s: Dictionary = BattleState.create([_spec("a"), _spec("b")], "distributore", 5)
	var heavy: String = ""
	for mid in BattleContent.BOSS_MOVES:
		if BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES[mid]) and str(BattleContent.BOSS_MOVES[mid]["target"]) != "all":
			heavy = str(mid)
			break
	s["telegraph"] = {"move": heavy, "target": "a"}
	return s


func _has(ev: Array, t: String) -> bool:
	for e in ev:
		if str(e["t"]) == t:
			return true
	return false


func _init() -> void:
	var s: Dictionary = _heavy_state()
	_check("riserva iniziale", int(s["reserve"]) == BattleTypes.RESERVE_START)
	_check("le reazioni esistono", BattleContent.MOVES.has("schivata") and BattleContent.MOVES.has("intercettazione") and BattleContent.MOVES.has("interruzione"))
	_check("3 reazioni offerte contro una carica", BattleResolver.reactions_for(s, "a").size() == 3)
	_check("intercettazione non per il bersaglio", BattleResolver.validate_choice(s, "a", {"move": "intercettazione"}) != "")
	_check("intercettazione per un compagno", BattleResolver.validate_choice(s, "b", {"move": "intercettazione"}) == "")
	_check("schivata valida", BattleResolver.validate_choice(s, "a", {"move": "schivata"}) == "")

	# nessuna carica -> nessuna reazione
	var calm: Dictionary = BattleState.create([_spec("a")], "distributore", 5)
	calm["telegraph"] = {"move": "", "target": "a"}
	_check("senza carica niente reazioni", BattleResolver.reactions_for(calm, "a").is_empty())
	var light: String = ""
	for mid in BattleContent.BOSS_MOVES:
		if not BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES[mid]):
			light = str(mid)
			break
	calm["telegraph"] = {"move": light, "target": "a"}
	_check("mossa leggera: reazione rifiutata", BattleResolver.validate_choice(calm, "a", {"move": "schivata"}) != "")

	# riserva insufficiente
	var poor: Dictionary = _heavy_state()
	poor["reserve"] = 0
	_check("senza riserva niente reazione", BattleResolver.validate_choice(poor, "a", {"move": "schivata"}) != "")

	# schivata: nessun danno al bersaglio, riserva spesa
	var hp0: int = int(BattleState.unit(s, "a:kira")["hp"])
	BattleResolver.submit_choice(s, "a", {"move": "schivata"})
	BattleResolver.submit_choice(s, "b", {"move": "guard"})
	var ev: Array = BattleResolver.resolve_round(s)
	_check("evento react", _has(ev, "react"))
	var hit_a: bool = false
	for e in ev:
		if str(e["t"]) == "damage" and str(e["dst"]) == "a:kira" and str(e["src"]) == BattleState.BOSS_ID:
			hit_a = true
	_check("schivata: nessun colpo su chi schiva", not hit_a and int(BattleState.unit(s, "a:kira")["hp"]) == hp0)
	_check("riserva spesa (+1 di fine round)", int(s["reserve"]) == BattleTypes.RESERVE_START - 1 + BattleTypes.RESERVE_PER_ROUND)

	# intercettazione: il compagno prende il colpo ridotto
	var si: Dictionary = _heavy_state()
	BattleResolver.submit_choice(si, "a", {"move": "guard"})
	BattleResolver.submit_choice(si, "b", {"move": "intercettazione"})
	var evi: Array = BattleResolver.resolve_round(si)
	var took_b: bool = false
	var took_a: bool = false
	for e in evi:
		if str(e["t"]) == "damage" and str(e["src"]) == BattleState.BOSS_ID:
			if str(e["dst"]) == "b:kira":
				took_b = true
			if str(e["dst"]) == "a:kira":
				took_a = true
	_check("intercettazione: colpisce l'intercettatore", took_b and not took_a)

	# interruzione: toglie equilibrio, una sola a round
	var sx: Dictionary = _heavy_state()
	BattleResolver.submit_choice(sx, "a", {"move": "interruzione"})
	BattleResolver.submit_choice(sx, "b", {"move": "interruzione"})
	var bal0: int = int(BattleState.boss(sx)["balance"])
	var evx: Array = BattleResolver.resolve_round(sx)
	var n_react: int = 0
	for e in evx:
		if str(e["t"]) == "react":
			n_react += 1
	_check("una sola interruzione a round", n_react == 1)
	_check("l'interruzione toglie equilibrio", _has(evx, "balance"))
	_check("riserva: non spesa due volte", int(sx["reserve"]) == BattleTypes.RESERVE_START - 2 + BattleTypes.RESERVE_PER_ROUND)

	# interruzione che rompe -> carica saltata
	var sb: Dictionary = _heavy_state()
	BattleState.boss(sb)["balance"] = 2
	BattleResolver.submit_choice(sb, "a", {"move": "interruzione"})
	BattleResolver.submit_choice(sb, "b", {"move": "guard"})
	var evb: Array = BattleResolver.resolve_round(sb)
	_check("interruzione riuscita: boss stordito, carica saltata", _has(evb, "break") and _has(evb, "boss_stunned"))

	# due reazioni insieme, riserva per una sola: la seconda ripiega
	var sr: Dictionary = _heavy_state()
	sr["reserve"] = 1
	BattleResolver.submit_choice(sr, "a", {"move": "schivata"})
	BattleResolver.submit_choice(sr, "b", {"move": "schivata"})
	var evr: Array = BattleResolver.resolve_round(sr)
	var nr: int = 0
	for e in evr:
		if str(e["t"]) == "react":
			nr += 1
	_check("riserva finita: solo una reazione", nr == 1)

	# tetto della riserva e sprechi
	var sc: Dictionary = BattleState.create([_spec("a")], "distributore", 5)
	sc["reserve"] = BattleTypes.RESERVE_MAX
	BattleResolver.submit_choice(sc, "a", {"move": "guard"})
	BattleResolver.resolve_round(sc)
	_check("la riserva ha un tetto", int(sc["reserve"]) <= BattleTypes.RESERVE_MAX)
	_check("riserva sprecata contata", int(sc["stats"].get("wasted", 0)) >= 1)

	# combo nuove e tag
	_check("VINCOLO esiste", not Combos.rule("vincolo").is_empty())
	_check("GUARDIA SPEZZATA esiste", not Combos.rule("guardia").is_empty())
	_check("intimidisci = BIND", Combos.tags_of(BattleContent.MOVES["intimidisci"]).has("BIND"))
	_check("frattura = BREAKGUARD", Combos.tags_of(BattleContent.MOVES["frattura"]).has("BREAKGUARD"))

	# una causa produce la combo una sola volta
	var sk: Dictionary = BattleState.create([_spec("a"), _spec("b")], "distributore", 5)
	sk["tags"] = [{"unit": "b:kira", "tags": ["SUPPORT"]}]
	var actor: Dictionary = BattleState.unit(sk, "a:kira")
	var boss: Dictionary = BattleState.boss(sk)
	_check("combo disponibile", Combos.matching(sk, actor, boss, ["ATTACK"]).size() >= 1)
	var evs: Array = []
	BattleResolver._synergies(sk, actor, boss, evs, BattleContent.MOVES["attack"])
	_check("la stessa causa non scatta due volte", Combos.matching(sk, actor, boss, ["ATTACK"]).is_empty())
	var got_res: bool = false
	for e in evs:
		if str(e["t"]) == "reserve":
			got_res = true
	_check("la combo da' Riserva", got_res)
	BattleResolver._synergies(sk, actor, boss, evs, BattleContent.MOVES["attack"])
	var rc: int = 0
	for e in evs:
		if str(e["t"]) == "reserve":
			rc += 1
	_check("Riserva da combo una sola volta a round", rc == 1)

	# fase 2 prosciuga la riserva
	var sp: Dictionary = BattleState.create([_spec("a")], "distributore", 5)
	BattleState.boss(sp)["hp"] = int(float(BattleState.boss(sp)["max_hp"]) * 0.45)
	sp["reserve"] = 4
	BattleResolver.submit_choice(sp, "a", {"move": "guard"})
	var evp: Array = BattleResolver.resolve_round(sp)
	_check("la fase 2 prosciuga la Riserva", int(sp["reserve"]) < 4 + BattleTypes.RESERVE_PER_ROUND)

	# testo ed eventi
	for e in evx:
		_check("descrivibile: " + str(e["t"]), BattleText.describe(sx, e).has("text"))

	print("test_reactions: %d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
