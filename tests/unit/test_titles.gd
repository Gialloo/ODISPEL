extends SceneTree

# Titoli epici/leggendari (bonus permanenti dell'account) e Potere dei personaggi.
#   godot --headless --path . -s res://tests/unit/test_titles.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _reds() -> Array:
	var out: Array = []
	for id in BattleContent.CHARACTERS:
		if str(BattleContent.CHARACTERS[id]["color"]) == "rosso":
			out.append(str(id))
	out.sort()
	return out


func _init() -> void:
	var roster: Dictionary = RosterState.new_roster()
	_check("catalogo: epici e leggendari", Titles.all().size() > 40)
	for t in Titles.all():
		_check("titolo valido " + str(t["id"]), int(t["rarity"]) >= 2 and Titles.STATS.has(str(t["stat"])) and int(t["bp"]) > 0 and int(t["goal"]) > 0)
	# squadra iniziale: 1 rosso (Dax) -> nessun titolo del rosso
	_check("nessun titolo all'inizio", Titles.active(roster, []).is_empty())
	_check("nessun bonus", not Titles.has_bonus(Titles.bonus_for(roster, "dax", [])))

	# 2 rossi -> epico +0,5% danni ai soli rossi
	var reds: Array = _reds()
	_check("ci sono 4 rossi", reds.size() >= 4)
	for id in reds.slice(0, 2):
		if not RosterState.owns(roster, str(id)):
			RosterState.add_character(roster, str(id))
	var b: Dictionary = Titles.bonus_for(roster, "dax", [])
	_check("epico rosso: +0,5% danni", int(b["atk"]) == 50 and int(b["hp"]) == 0)
	_check("non vale per i non rossi", int(Titles.bonus_for(roster, "kira", [])["atk"]) == 0)
	# 4 rossi -> leggendario +1% (sostituisce, non si somma)
	for id in reds.slice(0, 4):
		if not RosterState.owns(roster, str(id)):
			RosterState.add_character(roster, str(id))
	_check("leggendario rosso: +1% (non +1,5%)", int(Titles.bonus_for(roster, "dax", [])["atk"]) == 100)
	_check("testo bonus", Titles.bonus_text(Titles.by_id("mc_rosso_l")).contains("1%") and Titles.bonus_text(Titles.by_id("mc_rosso_e")).contains("0,5%"))

	# titolo-icona: Baluardo leggendario +0,5% difesa a tutti
	var d0: int = int(Titles.bonus_for(roster, "kira", [])["def"])
	var d1: int = int(Titles.bonus_for(roster, "kira", ["l_vanguard"])["def"])
	_check("icona leggendaria: +0,5% difesa a tutti", d1 - d0 == 50)
	_check("vale anche per altri", int(Titles.bonus_for(roster, "dax", ["l_vanguard"])["def"]) >= 50)

	# effetto sulle statistiche
	var plain: Dictionary = {"char": "dax", "level": 10, "rank": 0}
	var boosted: Dictionary = plain.duplicate(true)
	boosted["acc"] = {"hp": 0, "atk": 1000, "def": 500}
	var s0: Dictionary = BattleContent.compute_stats(plain)
	var s1: Dictionary = BattleContent.compute_stats(boosted)
	_check("atk +10%", s1["atk"] > s0["atk"] and abs(float(s1["atk"]) / float(s0["atk"]) - 1.1) < 0.01)
	_check("def +5%", s1["def"] > s0["def"])
	_check("pv invariati", s1["hp"] == s0["hp"])
	var wild: Dictionary = plain.duplicate(true)
	wild["acc"] = {"atk": 999999}
	_check("tetto sul bonus assurdo", float(BattleContent.compute_stats(wild)["atk"]) <= float(s0["atk"]) * 1.151)

	# la squadra riceve i bonus e passa la validazione (anche online)
	var team: Array = RosterState.team_entries(roster)
	var dax_e: Dictionary = {}
	for e in team:
		if str(e["char"]) == "dax":
			dax_e = e
	_check("scheda con bonus", dax_e.has("acc") and int(dax_e["acc"]["atk"]) >= 100)
	_check("scheda valida", RosterState.validate_team(team) == "")
	var bad: Dictionary = plain.duplicate(true)
	bad["acc"] = {"atk": 99999}
	_check("bonus fuori misura rifiutato", RosterState.validate_entry(bad) != "")
	bad["acc"] = {"magia": 5}
	_check("statistica sconosciuta rifiutata", RosterState.validate_entry(bad) != "")
	bad["acc"] = 5
	_check("bonus non dizionario rifiutato", RosterState.validate_entry(bad) != "")

	# altre linee: classi, collezione, spedizioni
	var r2: Dictionary = RosterState.new_roster()
	Expedition.data(r2)["wins"] = 1
	_check("Esploratore (spedizione)", Titles.is_earned(r2, Titles.by_id("exp_e"), []) and not Titles.is_earned(r2, Titles.by_id("exp_l"), []))
	Expedition.data(r2)["wins"] = 5
	_check("Signore delle Spedizioni", Titles.is_earned(r2, Titles.by_id("exp_l"), []))
	var allc: Dictionary = RosterState.new_roster()
	for id in BattleContent.CHARACTERS:
		if not RosterState.owns(allc, str(id)):
			RosterState.add_character(allc, str(id))
	_check("collezionista leggendario con tutti", Titles.is_earned(allc, Titles.by_id("coll_l"), []))
	_check("tetto 15% rispettato", int(Titles.bonus_for(allc, "dax", Profile.ICONS.keys())["atk"]) <= Titles.MAX_BP)

	# POTERE
	var rp: Dictionary = RosterState.new_roster()
	var p0: int = Power.of_character(rp, "dax", [])
	_check("potere positivo", p0 > 0)
	rp["characters"]["dax"]["level"] = 20
	var p1: int = Power.of_character(rp, "dax", [])
	_check("il livello aumenta il potere", p1 > p0)
	rp["characters"]["dax"]["rank"] = 3
	var p2: int = Power.of_character(rp, "dax", [])
	_check("il rank aumenta il potere", p2 > p1)
	var gid: String = RosterState.new_gear(rp, "arma", 3, 10)
	_check("pezzo creato", gid != "")
	RosterState.equip_gear(rp, "dax", gid)
	var p3: int = Power.of_character(rp, "dax", [])
	_check("l'equipaggiamento aumenta il potere", p3 > p2)
	var p4: int = Power.of_character(rp, "dax", ["l_vanguard", "l_striker"])
	_check("i titoli aumentano il potere", p4 > p3)
	var bd: Dictionary = Power.breakdown(rp, "dax", ["l_vanguard", "l_striker"])
	_check("dettaglio somma al totale", int(bd["base"]) + int(bd["level"]) + int(bd["rank"]) + int(bd["gear"]) + int(bd["titles"]) == int(bd["total"]))
	_check("dettaglio tutto positivo", int(bd["level"]) > 0 and int(bd["rank"]) > 0 and int(bd["gear"]) > 0 and int(bd["titles"]) > 0)
	_check("non posseduto = 0", Power.of_character(rp, "tana", []) == 0 or RosterState.owns(rp, "tana"))
	var acc: int = Power.account(rp, [])
	_check("account >= squadra", acc >= Power.team(rp, []) and Power.team(rp, []) > 0)
	_check("gradi di potere", Power.tier_name(100) == "RECLUTA" and Power.tier_name(5000) == "MITICO")
	# crescita vista dal giocatore
	Power.mark_seen(rp, [])
	_check("nessuna differenza subito", Power.delta(rp, []) == 0)
	rp["characters"]["dax"]["level"] = 30
	_check("differenza dopo la crescita", Power.delta(rp, []) > 0)
	# salvataggio / caricamento conserva il potere
	var tmp: String = "user://test_titles.json"
	RosterStore.save(rp, tmp)
	var loaded: Dictionary = RosterStore.load_or_new(tmp)
	_check("salvataggio conserva il potere", Power.account(loaded, []) == Power.account(rp, []))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
