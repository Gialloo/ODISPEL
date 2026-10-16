FILE test_battle.gd - PARTE 1 DI 2
Percorso: tests/unit/test_battle.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
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
	_test_kit_slots()
	_test_ult_and_energy()
	_test_death_and_end()
	_test_determinism_and_json()
	_test_solo_and_ai()
	_test_boss_scaling()
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
	_check("statistiche base vanguard", base["hp"] == 1495 and base["atk"] == 108)   # Dax: 1300 x1,15 vita e 90 x1,2 attacco (stat_mult di bilanciamento)
	_check("il livello aumenta le statistiche", lv5["hp"] > base["hp"] and lv5["atk"] > base["atk"])
	_check("il rank aumenta le statistiche", rk2["hp"] > base["hp"])
	var geared: Dictionary = BattleContent.compute_stats({"char": "dax", "level": 1, "rank": 0, "passives": [], "gear": [
		{"slot": "arma", "rarity": 0, "level": 1}, {"slot": "petto", "rarity": 3, "level": 3}, {"slot": "stivali", "rarity": 1, "level": 1}]})
	_check("l'equipaggiamento aumenta ATK, HP, DEF e SPD", geared["atk"] > base["atk"] and geared["hp"] > base["hp"] and geared["def"] > base["def"] and geared["spd"] > base["spd"])
	var passive: Dictionary = BattleContent.compute_stats({"char": "dax", "level": 1, "rank": 0, "passives": ["p_hp"], "gear": []})
	_check("la passiva Tempra aumenta gli HP", passive["hp"] == 1644)


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
```
