extends SceneTree

# Roster 2: i dieci operatori nuovi sono completi e giocabili (PvE e PvP).
var passed: int = 0
var failed: int = 0
const NEW: Array = ["moro", "vesper", "nami", "oriel", "silex", "yuna", "rhea", "flux", "cato", "lyra"]
const OLD: Array = ["kira", "dax", "elle", "bruno", "nova", "mira", "rex", "ivo", "sera", "eco", "tana", "nico", "dafne", "angela"]


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_check("contenuti coerenti", BattleContent.validate().is_empty())
	_check("24 operatori", BattleContent.CHARACTERS.size() == 24)
	var fac: Dictionary = {}
	for id in NEW:
		var d: Dictionary = BattleContent.CHARACTERS[id]
		fac[d["faction"]] = int(fac.get(d["faction"], 0)) + 1
		_check("%s: mosse nel motore" % id, BattleContent.MOVES.has("u_%s_a" % id) and BattleContent.MOVES.has(str(d["ult"])))
		_check("%s: la skill unica e' nel kit" % id, Signatures.SKILLS[id].has("u_%s_a" % id))
		_check("%s: passiva unica" % id, Signatures.has_passive(id) and Signatures.passive_text(id, 0) != "")
		_check("%s: lore" % id, not Lore.character_text(id).is_empty())
		_check("%s: la mossa e' sua" % id, str(BattleContent.MOVES["u_%s_a" % id].get("unique", "")) == id)
	_check("fazioni: 3 Magabondi, 3 Kairos, 2 Rondini, 2 LibraCorp", fac.get("magabondi", 0) == 3 and fac.get("kairos", 0) == 3 and fac.get("rondini", 0) == 2 and fac.get("libracorp", 0) == 2)
	for id in OLD:
		_check("%s: invariato" % id, BattleContent.CHARACTERS.has(id) and Signatures.has_passive(id))
	# Kira, la mascotte: leggendaria, 2 abilita' uniche, non conta per l'impresa "leggenda"
	_check("Kira e' leggendaria (5 stelle)", int(BattleContent.CHARACTERS["kira"]["rarity"]) == 3)
	_check("Kira ha due abilita' uniche e un tratto da leggendaria", Signatures.SKILLS["kira"].size() == 2 and Atypical.has_trait("kira") and Atypical.trait_of("kira").has("fx"))
	var start_roster: Dictionary = RosterState.new_roster()
	_check("la mascotte iniziale non fa scattare 'Una leggenda in squadra'", not Feats.is_done(start_roster, Feats.by_id("legend_1")))
	_check("Lyra non ha mark_ammo (resta di Angela)", str(Signatures.PASSIVES["lyra"]["key"]) != "mark_ammo")
	# PvP: ognuno combatte e la partita finisce
	for id in NEW:
		var specs: Array = [
			{"id": "a", "name": "A", "ai": true, "team": [{"char": id, "level": 20, "rank": 2}]},
			{"id": "b", "name": "B", "ai": true, "team": [{"char": "kira", "level": 20, "rank": 2}]}]
		var end: Dictionary = PvpEngine.simulate(specs, "duel", true, 5)
		_check("%s: un 1v1 PvP finisce" % id, str(end["winner"]) != "")
	# --- banner di reclutamento ---
	var only_new: bool = true
	var cnt: Dictionary = {}
	for i in 400:
		var rb: Dictionary = {"pity": 0}
		var rng := RNGState.new()
		rng.setup(1000 + i)
		var cid: String = Recruiting._pick(BattleContent.roll_rarity(rng), rng, "nuovi")
		if not Recruiting.NEW_IDS.has(cid):
			only_new = false
	_check("banner nuovi: escono solo i dieci nuovi", only_new)
	var new_n: int = 0
	var old_n: int = 0
	for i in 3000:
		var rng2 := RNGState.new()
		rng2.setup(5000 + i)
		var cid2: String = Recruiting._pick(1, rng2, "standard")       # solo rari: moro, silex, rhea (nuovi) e kira, nova, mira, ivo (vecchi)
		if Recruiting.NEW_IDS.has(cid2):
			new_n += 1
		else:
			old_n += 1
	# tra i rari: 3 nuovi (peso 1) contro 4 storici (peso 2) -> nuovi = 3/11 = 27%
	_check("banner standard: i nuovi escono meno degli altri (peso dimezzato)", float(new_n) / 3000.0 > 0.2 and float(new_n) / 3000.0 < 0.35)
	var rr: Dictionary = RosterState.new_roster()
	rr["coins"] = 100000
	var res: Dictionary = Recruiting.pull(rr, 10, 7, "nuovi")
	var ok_new: bool = bool(res["ok"])
	for x in res["results"]:
		ok_new = ok_new and Recruiting.NEW_IDS.has(str(x["char"]))
	_check("x10 nel banner nuovi: tutti nuovi e costo uguale", ok_new and int(res["cost"]) == Recruiting.TEN_COST)
	print("RESULT: %d passed, %d failed" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
