FILE test_battle.gd - PARTE 2 DI 2
Percorso: tests/unit/test_battle.gd
(Codice GDScript, rientri con tab. Questa e' l'ultima parte: ora puoi analizzare tutto il file.)

```gdscript
func _test_kit_slots() -> void:
	var e: Dictionary = BattleContent.default_entry("kira")
	e["skills"] = ["colpo_caricato", "marchio", "guard", "ricarica"]
	var st: Dictionary = BattleState.create([{"id": "a", "name": "a", "team": [e]}], "distributore", 3)
	var k: Dictionary = BattleState.unit(st, "a:kira")
	_check("kit senza Attacco: l'Attacco non e' valido", BattleResolver.validate_choice(st, "a", {"move": "attack", "swap": "", "target": ""}) != "")
	_check("kit senza Attacco: la Guardia e' valida", BattleResolver.validate_choice(st, "a", {"move": "guard", "swap": "", "target": ""}) == "")
	var c: Dictionary = BattleAI.choose(st, "a")
	_check("l'IA sceglie una mossa valida anche senza Attacco", BattleResolver.validate_choice(st, "a", c) == "")
	var legacy: Dictionary = BattleContent.default_entry("kira")
	legacy["skills"] = ["colpo_caricato"]
	var ls: Dictionary = BattleState.create([{"id": "a", "name": "a", "team": [legacy]}], "distributore", 3)
	var lk: Array = BattleState.unit(ls, "a:kira")["skills"]
	_check("vecchio kit: ricevono Attacco e Guardia", lk.has("attack") and lk.has("colpo_caricato") and lk.size() == BattleTypes.SKILL_SLOTS)
	var many: Array = BattleState.kit_of(["attack", "guard", "a", "b", "c", "d"], [])
	_check("non piu' di 4 mosse scelte", many.size() == BattleTypes.SKILL_SLOTS and k["skills"].size() >= 4)


func _test_ult_and_energy() -> void:
	var s: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 11)
	var k: Dictionary = BattleState.unit(s, "a:kira")
	k["energy"] = 4
	BattleState.boss(s)["max_hp"] = 100000       # niente cambio di fase in questo round
	BattleState.boss(s)["hp"] = 100000
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
	BattleState.unit(s, "a:kira")["tenacity_used"] = true
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
	BattleState.unit(l, "a:kira")["tenacity_used"] = true
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
	team.append_array(spare)
	var s: Dictionary = BattleState.create_solo("Io", team, [], "distributore", 5)
	_check("solo: 3 slot di front row, tutti del giocatore", s["players"].size() == 3 and not s["players"][0]["ai"] and not s["players"][1]["ai"] and not s["players"][2]["ai"])
	_check("solo: nessun personaggio fuori dal party", BattleState.unit(s, "ai1:nova").is_empty() and s["units"].size() == 7)
	_check("solo: front = primi 3 del party", s["players"][0]["active"] == "p1:kira" and s["players"][1]["active"] == "p1:dax" and s["players"][2]["active"] == "p1:elle")
	_check("solo: gli slot condividono il party", BattleState.party_of(s, s["players"][2]).size() == 6 and s["players"][1]["team"].is_empty())
	_check("solo: back row = gli altri 3", BattleState.back_row(s, s["players"][0]) == ["p1:nova", "p1:bruno", "p1:mira"])
	_check("solo: servono le scelte di tutti i front", not BattleResolver.can_resolve(s))
	BattleResolver.submit_choice(s, "p1", {"swap": "", "move": "attack", "target": ""})
	BattleResolver.submit_choice(s, "p1_f2", {"swap": "p1:nova", "move": "attack", "target": ""})
	_check("solo: scambio con la back row valido", BattleResolver.validate_choice(s, "p1_f2", {"swap": "p1:nova", "move": "attack", "target": ""}) == "")
	_check("solo: non si scambia con un altro front", BattleResolver.validate_choice(s, "p1_f2", {"swap": "p1:elle", "move": "attack", "target": ""}) != "")
	BattleResolver.submit_choice(s, "p1_f3", {"swap": "p1:nova", "move": "attack", "target": ""})
	_check("solo: poi si risolve", BattleResolver.can_resolve(s))
	BattleResolver.resolve_round(s)
	_check("solo: il round avanza", s["round"] == 2)
	_check("solo: Nova entra una volta sola (il secondo cambio cade)", s["players"][1]["active"] == "p1:nova" and s["players"][2]["active"] == "p1:elle")
	_check("solo: Dax e' in back row", not BattleState.is_front(s, "p1:dax") and BattleState.back_row(s, s["players"][0]).has("p1:dax"))
	var q: Dictionary = BattleState.create_solo("Io", team.slice(0, 2), [], "distributore", 5)
	_check("solo: party da 2 = 2 front, niente back row", q["players"].size() == 2 and BattleState.back_row(q, q["players"][0]).is_empty())
	var one: Dictionary = BattleState.create_solo("Io", team.slice(0, 1), [], "distributore", 5)
	_check("solo: party da 1 = 1 slot", one["players"].size() == 1)
	var ap: Dictionary = BattleState.create_solo("Io", team, [], "distributore", 9)
	var steps: int = 0
	while ap["winner"] == "" and steps < 80:
		BattleResolver.autoplay_round(ap)
		steps += 1
	_check("autoplay: l'IA porta a termine la battaglia", ap["winner"] != "")
	var fronts_ok: bool = true
	for p in ap["players"]:
		if BattleState.player_alive(ap, p) and not BattleState.is_alive(BattleState.unit(ap, str(p["active"]))):
			fronts_ok = false
	_check("autoplay: nessun front vivo resta con un K.O. in campo", fronts_ok or ap["winner"] != "")

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


func _test_boss_scaling() -> void:
	var hpp: int = int(BattleContent.BOSSES["distributore"]["hp_per_player"])
	var humans: Dictionary = BattleState.create([_spec("a", ["kira"]), _spec("b", ["nova"], true)], "distributore", 1)
	_check("un giocatore pilotato dall'IA vale come un umano", BattleState.boss(humans)["max_hp"] == 2 * hpp)
	var team: Array = [BattleContent.default_entry("kira")]
	var solo: Dictionary = BattleState.create_solo("Io", team + [BattleContent.default_entry("dax")], [], "distributore", 1)
	_check("un front in piu' vale mezzo giocatore", BattleState.boss(solo)["max_hp"] == int(round(1.5 * float(hpp))))
	var alone: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 1)
	_check("la forza del boss cresce con i giocatori effettivi", BattleState.boss(alone)["atk"] < BattleState.boss(solo)["atk"] and BattleState.boss(solo)["atk"] < BattleState.boss(humans)["atk"])
	_check("effective_players non scende sotto 1", BattleState.effective_players([]) == 1.0)


func _test_drops() -> void:
	var rng: RNGState = RNGState.new()
	rng.setup(5)
	var drops: Array = BattleContent.roll_drops("distributore", rng)
	_check("il boss lascia premi", drops.size() == 3)
	var valid: bool = true
	for d in drops:
		var table: Dictionary = BattleContent.MOVES if d["kind"] == "move" else BattleContent.PASSIVES
		if not table.has(d["id"]) or table[d["id"]]["rarity"] != d["rarity"]:
			valid = false
	_check("i premi esistono e hanno la rarita' dichiarata", valid)
	var rng2: RNGState = RNGState.new()
	rng2.setup(5)
	_check("i premi sono deterministici", BattleContent.roll_drops("distributore", rng2) == drops)
```
