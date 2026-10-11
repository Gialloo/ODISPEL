extends SceneTree

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _spec(id: String, ids: Array, ai: bool = false) -> Dictionary:
	var team: Array = []
	for c in ids:
		team.append(BattleContent.default_entry(str(c)))
	return {"id": id, "name": id, "ai": ai, "team": team}


func _two_players() -> Dictionary:
	return BattleState.create([_spec("a", ["kira", "dax", "elle"]), _spec("b", ["nova", "bruno", "mira"])], "distributore", 42)


func _init() -> void:
	_test_content()
	_test_colors_and_stats()
	_test_setup()
	_test_choices()
	_test_order_and_damage()
	_test_swap()
	_test_guard_taunt_status()
	_test_ult_and_energy()
	_test_death_and_end()
	_test_determinism_and_json()
	_test_solo_and_ai()
	_test_drops()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_content() -> void:
	_check("contenuti coerenti", BattleContent.validate().is_empty())


func _test_colors_and_stats() -> void:
	_check("rosso batte verde", BattleTypes.color_multiplier("rosso", "verde") == 1.5)
	_check("verde subisce da rosso", BattleTypes.color_multiplier("verde", "rosso") == 0.67)
	_check("giallo e viola si battono a vicenda", BattleTypes.color_multiplier("giallo", "viola") == 1.5 and BattleTypes.color_multiplier("viola", "giallo") == 1.5)
	_check("colori neutri", BattleTypes.color_multiplier("rosso", "blu") == 0.67 and BattleTypes.color_multiplier("rosso", "rosso") == 1.0)

	var base: Dictionary = BattleContent.compute_stats({"char": "dax", "level": 1, "rank": 0, "passives": [], "gear": []})
	var lv5: Dictionary = BattleContent.compute_stats({"char": "dax", "level": 5, "rank": 0, "passives": [], "gear": []})
	var rk2: Dictionary = BattleContent.compute_stats({"char": "dax", "level": 1, "rank": 2, "passives": [], "gear": []})
	_check("statistiche base vanguard", base["hp"] == 1300 and base["atk"] == 80)
	_check("il livello aumenta le statistiche", lv5["hp"] > base["hp"] and lv5["atk"] > base["atk"])
	_check("il rank aumenta le statistiche", rk2["hp"] > base["hp"])
	var geared: Dictionary = BattleContent.compute_stats({"char": "dax", "level": 1, "rank": 0, "passives": [], "gear": [
		{"slot": "arma", "rarity": 0, "level": 1}, {"slot": "petto", "rarity": 3, "level": 3}, {"slot": "stivali", "rarity": 1, "level": 1}]})
	_check("l'equipaggiamento aumenta ATK, HP, DEF e SPD", geared["atk"] > base["atk"] and geared["hp"] > base["hp"] and geared["def"] > base["def"] and geared["spd"] > base["spd"])
	var passive: Dictionary = BattleContent.compute_stats({"char": "dax", "level": 1, "rank": 0, "passives": ["p_hp"], "gear": []})
	_check("la passiva Tempra aumenta gli HP", passive["hp"] == 1430)


func _test_setup() -> void:
	var s: Dictionary = _two_players()
	_check("round iniziale 1", s["round"] == 1 and s["winner"] == "")
	_check("il primo della squadra e' attivo", BattleState.active_unit(s, "a")["char"] == "kira")
	_check("la vita del boss scala coi giocatori", BattleState.boss(s)["max_hp"] == 2 * int(BattleContent.BOSSES["distributore"]["hp_per_player"]))
	_check("mossa del boss annunciata", s["telegraph"]["move"] == "scarica" and ["a", "b"].has(s["telegraph"]["target"]))
	var one: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 1)
	_check("il boss e' meno forte contro un solo giocatore", BattleState.boss(one)["atk"] < BattleState.boss(s)["atk"])


func _test_choices() -> void:
	var s: Dictionary = _two_players()
	_check("attacco valido", BattleResolver.submit_choice(s, "a", {"move": "attack"}))
	_check("mossa sconosciuta rifiutata", not BattleResolver.submit_choice(s, "a", {"move": "fulmine"}))
	_check("skill non equipaggiata rifiutata", not BattleResolver.submit_choice(s, "a", {"move": "cura"}))
	BattleState.unit(s, "a:kira")["energy"] = 1
	_check("energia insufficiente rifiutata", not BattleResolver.submit_choice(s, "a", {"move": "colpo_caricato"}))
	_check("ultimate a barra vuota rifiutata", not BattleResolver.submit_choice(s, "a", {"move": "spezzatutto"}))
	_check("cambio con personaggio non in squadra rifiutato", not BattleResolver.submit_choice(s, "a", {"swap": "b:nova", "move": "attack"}))
	_check("giocatore sconosciuto rifiutato", not BattleResolver.submit_choice(s, "zzz", {"move": "attack"}))
	_check("non si risolve senza la scelta di tutti", not BattleResolver.can_resolve(s))
	BattleResolver.submit_choice(s, "b", {"move": "attack"})
	_check("si risolve quando tutti hanno scelto", BattleResolver.can_resolve(s))
	_check("risolvere senza scelte e senza forzare non fa nulla", BattleResolver.resolve_round(_two_players()).is_empty())


func _test_order_and_damage() -> void:
	var s: Dictionary = _two_players()
	BattleResolver.submit_choice(s, "a", {"move": "attack"})
	BattleResolver.submit_choice(s, "b", {"move": "attack"})
	var ev: Array = BattleResolver.resolve_round(s)
	var order: Array = []
	for e in ev:
		if e["t"] == "act":
			order.append(e["unit"])
		elif e["t"] == "boss_move":
			order.append("boss")
	# Nova 110, Kira 110, boss 105: a parita' di velocita' decide l'id
	_check("ordine per velocita' (giocatori 110 prima del boss 105)", order.size() == 3 and order[2] == "boss")
	_check("il round avanza", s["round"] == 2 and s["cycle_index"] == 1)
	_check("la mossa successiva del boss e' annunciata", s["telegraph"]["move"] == "raffica")
	var boss: Dictionary = BattleState.boss(s)
	_check("il boss ha subito danni", boss["hp"] < boss["max_hp"])
	# Kira (viola) contro boss giallo: vantaggio di colore
	var kira: Dictionary = BattleState.unit(s, "a:kira")
	var dax_target: Dictionary = BattleState.unit(s, "b:bruno")
	_check("il vantaggio di colore aumenta il danno", BattleResolver.calc_damage(kira, boss, 1.0) > BattleResolver.calc_damage(dax_target, boss, 1.0))
	var marked: Dictionary = boss.duplicate(true)
	marked["statuses"]["mark"] = 2
	_check("il marchio aumenta il danno subito", BattleResolver.calc_damage(kira, marked, 1.0) > BattleResolver.calc_damage(kira, boss, 1.0))


func _test_swap() -> void:
	var s: Dictionary = _two_players()
	_check("cambio libero valido", BattleResolver.submit_choice(s, "a", {"swap": "a:dax", "move": "attack"}))
	BattleResolver.submit_choice(s, "b", {"move": "attack"})
	var ev: Array = BattleResolver.resolve_round(s)
	_check("il cambio avviene e il nuovo personaggio agisce", BattleState.active_unit(s, "a")["char"] == "dax")
	var acted: bool = false
	for e in ev:
		if e["t"] == "act" and e["unit"] == "a:dax":
			acted = true
	_check("chi entra agisce nello stesso round", acted)
	_check("chi esce non agisce", not _acted(ev, "a:kira"))
	# in panchina si recupera piu' energia
	_check("la panchina recupera piu' energia", BattleState.unit(s, "a:kira")["energy"] == 2 + BattleTypes.REGEN_BENCH and BattleState.unit(s, "a:dax")["energy"] == 2 + BattleTypes.REGEN_ACTIVE)

	# passiva "entrata scudata" di Elle
	var s2: Dictionary = _two_players()
	BattleResolver.submit_choice(s2, "a", {"swap": "a:elle", "move": "attack"})
	BattleResolver.submit_choice(s2, "b", {"move": "attack"})
	var ev2: Array = BattleResolver.resolve_round(s2)
	var shielded: bool = false
	for e in ev2:
		if e["t"] == "shield" and e["dst"] == "a:elle":
			shielded = true
	_check("la passiva di entrata crea uno scudo", shielded)


func _acted(events: Array, uid: String) -> bool:
	for e in events:
		if e["t"] == "act" and e["unit"] == uid:
			return true
	return false


func _first_damage_to(events: Array, uid: String) -> int:
	for e in events:
		if e["t"] == "damage" and e["dst"] == uid:
			return int(e["amount"]) + int(e["absorbed"])
	return -1


func _test_guard_taunt_status() -> void:
	# guardia dimezza il danno subito
	var plain: Dictionary = BattleState.create([_spec("a", ["dax", "kira", "elle"])], "distributore", 7)
	var guarded: Dictionary = BattleState.create([_spec("a", ["dax", "kira", "elle"])], "distributore", 7)
	BattleResolver.submit_choice(plain, "a", {"move": "attack"})
	BattleResolver.submit_choice(guarded, "a", {"move": "guard"})
	var ev_plain: Array = BattleResolver.resolve_round(plain)
	var ev_guard: Array = BattleResolver.resolve_round(guarded)
	var d1: int = _first_damage_to(ev_plain, "a:dax")
	var d2: int = _first_damage_to(ev_guard, "a:dax")
	_check("la guardia dimezza il danno", d1 > 0 and abs(d2 * 2 - d1) <= 1)
	_check("la guardia agisce prima del boss (priorita')", ev_guard[0]["t"] == "act" and ev_guard[0]["move"] == "guard")

	# Provoca devia il colpo singolo sul provocatore
	var tau: Dictionary = BattleState.create([_spec("a", ["dax"]), _spec("b", ["kira"])], "distributore", 3)
	tau["telegraph"] = {"move": "scarica", "target": "b"}
	BattleState.unit(tau, "a:dax")["energy"] = 3
	BattleResolver.submit_choice(tau, "a", {"move": "provoca"})
	BattleResolver.submit_choice(tau, "b", {"move": "attack"})
	var ev_t: Array = BattleResolver.resolve_round(tau)
	_check("provoca devia il colpo singolo", _first_damage_to(ev_t, "a:dax") > 0 and _first_damage_to(ev_t, "b:kira") == -1)

	# Scossa fa sanguinare, il sanguinamento toglie PV a fine round, Purifica lo toglie
	var bl: Dictionary = BattleState.create([_spec("a", ["elle", "kira"])], "distributore", 5)
	bl["telegraph"] = {"move": "scossa", "target": "a"}
	BattleResolver.submit_choice(bl, "a", {"move": "attack"})
	var ev_b: Array = BattleResolver.resolve_round(bl)
	var bled: bool = false
	for e in ev_b:
		if e["t"] == "bleed":
			bled = true
	_check("la scossa causa sanguinamento", bled and BattleState.unit(bl, "a:elle")["statuses"].has("bleed"))

	var pur: Dictionary = BattleState.create([_spec("a", ["mira"])], "distributore", 5)
	BattleState.unit(pur, "a:mira")["statuses"]["bleed"] = 3
	BattleState.unit(pur, "a:mira")["energy"] = 3
	BattleResolver.submit_choice(pur, "a", {"move": "purifica", "target": "a"})
	BattleResolver.resolve_round(pur)
	_check("purifica rimuove il sanguinamento", not BattleState.unit(pur, "a:mira")["statuses"].has("bleed"))

	# Cura
	var cu: Dictionary = BattleState.create([_spec("a", ["elle", "kira"])], "distributore", 9)
	cu["telegraph"] = {"move": "raffica", "target": "a"}
	BattleState.unit(cu, "a:elle")["hp"] = 300
	BattleState.unit(cu, "a:elle")["energy"] = 4
	BattleResolver.submit_choice(cu, "a", {"move": "cura", "target": "a"})
	var ev_c: Array = BattleResolver.resolve_round(cu)
	var healed: int = 0
	for e in ev_c:
		if e["t"] == "heal":
			healed = int(e["amount"])
	_check("cura recupera PV", healed > 0)

	# marchio
	var mk: Dictionary = BattleState.create([_spec("a", ["nova"])], "distributore", 9)
	BattleState.unit(mk, "a:nova")["energy"] = 3
	BattleResolver.submit_choice(mk, "a", {"move": "marchio"})
	BattleResolver.resolve_round(mk)
	_check("marchio resta sul boss al round dopo", BattleState.boss(mk)["statuses"].has("mark"))


func _test_ult_and_energy() -> void:
	var s: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 11)
	var k: Dictionary = BattleState.unit(s, "a:kira")
	k["energy"] = 4
	BattleResolver.submit_choice(s, "a", {"move": "colpo_caricato"})
	BattleResolver.resolve_round(s)
	_check("la skill consuma energia (+ rigenerazione)", k["energy"] == 4 - 2 + BattleTypes.REGEN_ACTIVE)
	_check("colpire carica la barra", k["gauge"] >= BattleTypes.GAUGE_ON_HIT)

	k["gauge"] = 100
	var hp_before: int = int(BattleState.boss(s)["hp"])
	_check("ultimate valida con barra piena", BattleResolver.submit_choice(s, "a", {"move": "spezzatutto"}))
	BattleResolver.resolve_round(s)
	_check("l'ultimate svuota la barra (poi carica col colpo)", k["gauge"] <= 40)
	_check("l'ultimate fa molto danno", hp_before - int(BattleState.boss(s)["hp"]) > 300)

	# energia mai oltre il massimo
	for i in 10:
		k["energy"] = mini(BattleTypes.MAX_ENERGY, k["energy"] + 1)
	_check("energia limitata al massimo", k["energy"] <= BattleTypes.MAX_ENERGY)

	# scelta forzata non valida diventa attacco
	var s2: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 12)
	BattleState.player(s2, "a")["choice"] = {"swap": "", "move": "spezzatutto", "target": ""}
	var ev: Array = BattleResolver.resolve_round(s2)
	_check("mossa impossibile ripiega sull'attacco", ev.size() > 0 and ev[0]["move"] == "attack")


func _test_death_and_end() -> void:
	# l'attivo cade: entra il compagno con piu' vita
	var s: Dictionary = BattleState.create([_spec("a", ["kira", "dax", "elle"])], "distributore", 13)
	BattleState.unit(s, "a:kira")["hp"] = 1
	BattleState.unit(s, "a:elle")["hp"] = 100
	s["telegraph"] = {"move": "scarica", "target": "a"}
	BattleResolver.submit_choice(s, "a", {"move": "attack"})
	BattleResolver.resolve_round(s)
	_check("se l'attivo cade entra il compagno piu' sano", BattleState.unit(s, "a:kira")["hp"] == 0 and BattleState.active_unit(s, "a")["char"] == "dax")
	_check("non si puo' scegliere un personaggio sconfitto", not BattleResolver.submit_choice(s, "a", {"swap": "a:kira", "move": "attack"}))

	# vittoria dei giocatori
	var w: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 14)
	BattleState.boss(w)["hp"] = 5
	BattleResolver.submit_choice(w, "a", {"move": "attack"})
	var ev: Array = BattleResolver.resolve_round(w)
	_check("vittoria dei giocatori", w["winner"] == "players" and ev.back()["t"] == "end")
	_check("a battaglia finita non si fa altro", BattleResolver.resolve_round(w, true).is_empty() and not BattleResolver.submit_choice(w, "a", {"move": "attack"}))

	# vittoria del boss
	var l: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 15)
	BattleState.unit(l, "a:kira")["hp"] = 1
	BattleResolver.submit_choice(l, "a", {"move": "attack"})
	BattleResolver.resolve_round(l)
	_check("vittoria del boss se cadono tutti", l["winner"] == "boss")

	# il sanguinamento puo' uccidere
	var bl: Dictionary = BattleState.create([_spec("a", ["kira", "dax"])], "distributore", 16)
	BattleState.unit(bl, "a:kira")["hp"] = 3
	BattleState.unit(bl, "a:kira")["statuses"]["bleed"] = 2
	bl["telegraph"] = {"move": "raffica", "target": "a"}
	BattleResolver.submit_choice(bl, "a", {"swap": "a:dax", "move": "guard"})
	BattleResolver.resolve_round(bl)
	_check("il sanguinamento colpisce anche chi e' in panchina", BattleState.unit(bl, "a:kira")["hp"] == 0)


func _run_to_end(state: Dictionary) -> int:
	var guard: int = 0
	while state["winner"] == "" and guard < 100:
		BattleResolver.resolve_round(state, true)
		guard += 1
	return guard


func _test_determinism_and_json() -> void:
	var a: Dictionary = BattleState.create([_spec("a", ["kira", "dax", "elle"], true), _spec("b", ["nova", "bruno", "mira"], true)], "distributore", 99)
	var b: Dictionary = BattleState.create([_spec("a", ["kira", "dax", "elle"], true), _spec("b", ["nova", "bruno", "mira"], true)], "distributore", 99)
	_run_to_end(a)
	_run_to_end(b)
	_check("stesso seed, stessa battaglia", BattleState.to_json(a) == BattleState.to_json(b))
	var c: Dictionary = BattleState.create([_spec("a", ["kira", "dax", "elle"], true), _spec("b", ["nova", "bruno", "mira"], true)], "distributore", 100)
	_run_to_end(c)
	_check("seed diversi, battaglie diverse", BattleState.to_json(a) != BattleState.to_json(c))

	# salvataggio a meta' battaglia e ripresa: stesso risultato
	var x: Dictionary = BattleState.create([_spec("a", ["kira", "dax", "elle"], true), _spec("b", ["nova", "bruno", "mira"], true)], "distributore", 77)
	for i in 3:
		BattleResolver.resolve_round(x, true)
	var y: Dictionary = BattleState.from_json(BattleState.to_json(x))
	_check("JSON conserva lo stato", BattleState.to_json(x) == BattleState.to_json(y))
	_check("i numeri tornano interi dopo il JSON", y["round"] is int and BattleState.boss(y)["hp"] is int)
	_run_to_end(x)
	_run_to_end(y)
	_check("ripresa dal JSON: stessa conclusione", BattleState.to_json(x) == BattleState.to_json(y))


func _test_solo_and_ai() -> void:
	var team: Array = [BattleContent.default_entry("kira"), BattleContent.default_entry("dax"), BattleContent.default_entry("elle")]
	var spare: Array = [BattleContent.default_entry("nova"), BattleContent.default_entry("bruno"), BattleContent.default_entry("mira")]
	var s: Dictionary = BattleState.create_solo("Io", team, spare, "distributore", 5, 2)
	_check("solo: 1 umano + 2 IA", s["players"].size() == 3 and not s["players"][0]["ai"] and s["players"][1]["ai"] and s["players"][2]["ai"])
	_check("solo: le IA usano i personaggi fuori squadra", BattleState.unit(s, "ai1:nova").size() > 0 and BattleState.unit(s, "ai2:bruno").size() > 0)
	_check("solo: serve solo la scelta dell'umano", not BattleResolver.can_resolve(s))
	BattleResolver.submit_choice(s, "p1", {"move": "attack"})
	_check("solo: poi si risolve", BattleResolver.can_resolve(s))
	BattleResolver.resolve_round(s)
	_check("solo: il round avanza", s["round"] == 2)

	# le scelte dell'IA sono sempre valide
	var ok: bool = true
	var t: Dictionary = BattleState.create([_spec("a", ["kira", "dax", "elle"], true), _spec("b", ["nova", "bruno", "mira"], true)], "distributore", 31)
	var guard: int = 0
	while t["winner"] == "" and guard < 60:
		for p in t["players"]:
			if BattleState.player_alive(t, p) and BattleResolver.validate_choice(t, str(p["id"]), BattleAI.choose(t, str(p["id"]))) != "":
				ok = false
		BattleResolver.resolve_round(t, true)
		guard += 1
	_check("l'IA sceglie sempre mosse valide", ok)
	_check("la battaglia si conclude", t["winner"] != "" and guard < 60)


func _test_drops() -> void:
	var rng: RNGState = RNGState.new()
	rng.setup(5)
	var drops: Array = BattleContent.roll_drops("distributore", rng)
	_check("il boss lascia premi", drops.size() == 2)
	var valid: bool = true
	for d in drops:
		var table: Dictionary = BattleContent.MOVES if d["kind"] == "move" else BattleContent.PASSIVES
		if not table.has(d["id"]) or table[d["id"]]["rarity"] != d["rarity"]:
			valid = false
	_check("i premi esistono e hanno la rarita' dichiarata", valid)
	var rng2: RNGState = RNGState.new()
	rng2.setup(5)
	_check("i premi sono deterministici", BattleContent.roll_drops("distributore", rng2) == drops)
