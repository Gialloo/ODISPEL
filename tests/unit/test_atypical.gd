extends SceneTree

# Tratti atipici per rarita' e rifiniture dei kit (DEX con cure critiche, ecc.).
#   godot --headless --path . -s res://tests/unit/test_atypical.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _entry(id: String, style: String = "ortodosso") -> Dictionary:
	var e: Dictionary = BattleContent.default_entry(id)
	e["style"] = style
	return e


func _state(ids: Array, style: String = "atipico", boss: String = "distributore") -> Dictionary:
	var team: Array = []
	for id in ids:
		team.append(_entry(str(id), style))
	return BattleState.create([{"id": "p1", "name": "A", "team": team}], boss, 7, 0)


func _u(st: Dictionary, char_id: String) -> Dictionary:
	return BattleState.unit(st, BattleState.unit_id("p1", char_id))


func _init() -> void:
	_run()
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _run() -> void:
	# --- livelli per rarita'
	for id in BattleContent.CHARACTERS:
		var r: int = int(BattleContent.CHARACTERS[id]["rarity"])
		if r == 0:
			_check("%s (comune) non ha tratto proprio" % id, not Atypical.has_trait(str(id)))
		elif BattleContent.faction_of(str(id)) != "":
			_check("%s (rarita' %d) ha un tratto" % [id, r], Atypical.has_trait(str(id)))
	for id in ["tana", "dafne", "angela"]:
		_check("%s e' leggendario con tratto" % id, int(BattleContent.CHARACTERS[id]["rarity"]) == 3 and Atypical.has_trait(id))
	_check("descrizione con livello", Atypical.describe("tana").begins_with("ATIPICO (LEGGENDARIO): Baluardo che risponde"))
	_check("descrizione comune", Atypical.describe("dax").contains("nessun tratto proprio"))

	# --- ortodosso: nessun effetto
	var orto: Dictionary = _state(["tana", "kira"], "ortodosso")
	_check("ortodosso: niente tratti", not _u(orto, "tana").has("atyp") and not _u(orto, "kira").has("atyp"))
	_check("ortodosso: nessun mod extra", Atypical.mods_for(_u(orto, "kira")).is_empty())

	# --- rari: piccole aggiunte
	var rari: Dictionary = _state(["kira", "nova", "mira"])
	var k_at: Dictionary = _state(["kira"], "atipico")
	var k_or: Dictionary = _state(["kira"], "ortodosso")
	_check("kira (leggendaria): +6% critico, meno la meta' dell'aura che perde", int(_u(k_at, "kira")["crit"]) - int(_u(k_or, "kira")["crit"]) >= 20)
	_check("nova: parte con piu' energia", int(_u(rari, "nova")["energy"]) == BattleTypes.START_ENERGY + 1)
	_check("mira: +6% VEL e DIF (oltre al +5% atipico)", int(_u(rari, "mira")["spd"]) > int(round(float(_u(rari, "mira")["base"]["spd"]) * 1.1)) - 1)
	var ivo: Dictionary = _state(["ivo"])
	_check("ivo: +15 di ultimate di partenza", int(_u(ivo, "ivo")["gauge"]) >= 15 + Archetypes.QCK_START_GAUGE)

	# --- epici
	var epici: Dictionary = _state(["sera", "eco", "kira"])
	var sera: Dictionary = _u(epici, "sera")
	var kira: Dictionary = _u(epici, "kira")
	kira["gauge"] = 10
	_u(epici, "eco")["gauge"] = 60
	var ev: Array = []
	Atypical.end_of_round(epici, ev)
	_check("sera: passa ultimate all'alleato piu' scarico", int(kira["gauge"]) == 10 + Atypical.GAUGE_SHARE and ev.size() >= 1)
	_check("sera: lei non si carica da sola", int(sera["gauge"]) == int(_u(_state(["sera"]), "sera")["gauge"]))
	var eco: Dictionary = _u(epici, "eco")
	var boss: Dictionary = BattleState.boss(epici)
	var plain: float = Atypical.damage_mult(eco, boss)
	Marks.add(epici, boss, 1, [])
	_check("eco: nessun bonus senza malus", plain == 1.0)
	_check("eco: +15% sui bersagli marchiati", is_equal_approx(Atypical.damage_mult(eco, boss), 1.15))
	var nico: Dictionary = _state(["nico"])
	var nu: Dictionary = _u(nico, "nico")
	_check("nico: parte senza slancio", int(nu["momentum"]) == 0)
	Factions.on_hit_taken(nico, nu, [])
	_check("nico: colpito guadagna slancio", int(nu["momentum"]) == 1)
	var nico_o: Dictionary = _state(["nico"], "ortodosso")
	Factions.on_hit_taken(nico_o, _u(nico_o, "nico"), [])
	_check("nico ortodosso: niente slancio", int(_u(nico_o, "nico")["momentum"]) == 0)

	# --- leggendari
	# Tana: riflette parte del danno assorbito dallo scudo
	var tt: Dictionary = _state(["tana"])
	var tana: Dictionary = _u(tt, "tana")
	var tb: Dictionary = BattleState.boss(tt)
	tana["shield"] = 1000
	var hp0: int = int(tb["hp"])
	var evs: Array = []
	BattleResolver._hit(tt, tb, tana, 1.0, evs)
	var absorbed: int = 0
	for e in evs:
		if str(e["t"]) == "damage" and str(e["dst"]) == str(tana["id"]):
			absorbed = int(e["absorbed"])
	_check("tana: lo scudo ha assorbito", absorbed > 0)
	_check("tana: il boss subisce il 40% dell'assorbito", hp0 - int(tb["hp"]) == maxi(1, int(round(float(absorbed) * 0.4))))
	var to: Dictionary = _state(["tana"], "ortodosso")
	var tbo: Dictionary = BattleState.boss(to)
	_u(to, "tana")["shield"] = 1000
	var hpo: int = int(tbo["hp"])
	BattleResolver._hit(to, tbo, _u(to, "tana"), 1.0, [])
	_check("tana ortodossa: nessun riflesso", int(tbo["hp"]) == hpo)

	# Dafne: critico sicuro sul boss quasi finito + munizione indietro
	var dt: Dictionary = _state(["dafne"])
	var dafne: Dictionary = _u(dt, "dafne")
	var db: Dictionary = BattleState.boss(dt)
	db["hp"] = int(db["max_hp"]) * 25 / 100
	_check("dafne: critico forzato sotto il 30%", Atypical.forces_crit(dafne, db))
	db["hp"] = int(db["max_hp"]) * 60 / 100
	_check("dafne: nessun critico forzato sopra il 30%", not Atypical.forces_crit(dafne, db))
	db["hp"] = int(db["max_hp"]) * 20 / 100
	dafne["ammo"] = 2
	var dev: Array = []
	BattleResolver._hit(dt, dafne, db, 1.0, dev, 0, 0.0, true)
	var crit_seen: bool = false
	for e in dev:
		if str(e["t"]) == "damage" and e.has("crit"):
			crit_seen = true
	_check("dafne: il colpo e' critico", crit_seen)
	_check("dafne: il critico ridona una munizione", int(dafne["ammo"]) == 3)
	var do: Dictionary = _state(["dafne"], "ortodosso")
	var dob: Dictionary = BattleState.boss(do)
	_check("dafne ortodossa: nessun critico forzato", not Atypical.forces_crit(_u(do, "dafne"), dob))

	# Angela: calore a ogni munizione spesa
	var at: Dictionary = _state(["angela"])
	var angela: Dictionary = _u(at, "angela")
	var ab: Dictionary = BattleState.boss(at)
	_check("angela: parte senza calore", int(angela.get("heat", 0)) == 0 and Atypical.damage_mult(angela, ab) == 1.0)
	BattleResolver._change_ammo(angela, -3, [])
	_check("angela: 3 munizioni = 3 cariche", int(angela["heat"]) == 3)
	_check("angela: +9% di danno", is_equal_approx(Atypical.damage_mult(angela, ab), 1.09))
	BattleResolver._change_ammo(angela, 5, [])
	_check("angela: ricaricare non da' calore", int(angela["heat"]) == 3)
	for i in 6:
		BattleResolver._change_ammo(angela, -3, [])
		BattleResolver._change_ammo(angela, 12, [])
	_check("angela: tetto di 12 cariche", int(angela["heat"]) == Atypical.HEAT_MAX)
	var ao: Dictionary = _state(["angela"], "ortodosso")
	BattleResolver._change_ammo(_u(ao, "angela"), -3, [])
	_check("angela ortodossa: nessun calore", int(_u(ao, "angela").get("heat", 0)) == 0)

	# --- stato JSON-lossless
	var js: Variant = JSON.parse_string(JSON.stringify(at))
	_check("stato con tratti sopravvive a JSON", js is Dictionary and int((js["units"][str(angela["id"])] as Dictionary)["atyp"]["heat"]) == Atypical.HEAT_PM)

	# --- rifiniture dei kit
	var dex: Dictionary = _state(["elle"], "ortodosso")
	var elle: Dictionary = _u(dex, "elle")
	elle["base"]["crit"] = 1000
	elle["crit"] = 1000
	_check("DEX: cura sempre critica con critico 100%", Archetypes.support_crit_mult(dex, elle, elle, 1) == Archetypes.DEX_SUPPORT_CRIT)
	elle["crit"] = 0
	_check("DEX: nessun critico senza probabilita'", Archetypes.support_crit_mult(dex, elle, elle, 1) == 1.0)
	var red: Dictionary = _state(["dax"], "ortodosso")
	_check("non DEX: cure mai critiche", Archetypes.support_crit_mult(red, _u(red, "dax"), _u(red, "dax"), 1) == 1.0)
	_check("Elle: Respiro restituisce energia", int(Signatures.MOVES["u_elle_a"].get("energy", 0)) == 1)
	_check("Mira: Iniezione ha priorita'", int(Signatures.MOVES["u_mira_a"]["priority"]) >= 1)
	_check("Eco: le sue abilita' indeboliscono", Signatures.MOVES["u_eco_a"].has("debuff") and Signatures.MOVES["u_eco_b"].has("debuff"))
