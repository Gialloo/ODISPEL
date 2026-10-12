extends SceneTree

# Imprese (obiettivi permanenti), mosse a livelli e bonus dalle statistiche, premi maggiorati.
#   godot --headless --path . -s res://tests/unit/test_feats_moves.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_feats_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _unit(extra: Dictionary = {}) -> Dictionary:
	var u: Dictionary = {"id": "a", "atk": 100, "def": 40, "spd": 100, "max_hp": 1000, "crit": 100, "color": "rosso", "side": "player", "statuses": [], "hp": 1000, "passives": []}
	u.merge(extra, true)
	return u


func _run() -> void:
	# --- mosse a livelli
	var m: Dictionary = BattleContent.MOVES
	for fam in ["cura", "barriera", "colpo_caricato", "marchio", "provoca", "purifica"]:
		_check("%s: 4 livelli (comune..leggendaria)" % fam, m.has(fam) and m.has(fam + "_r") and m.has(fam + "_e") and m.has(fam + "_l"))
		_check("%s: la rarita' sale con il livello" % fam, int(m[fam]["rarity"]) == 0 and int(m[fam + "_l"]["rarity"]) == 3)
	var key: Dictionary = {"cura": "heal", "barriera": "shield", "colpo_caricato": "mult", "marchio": "mult"}
	for fam in key:
		_check("%s: il valore base cresce a ogni livello" % fam, float(m[fam][key[fam]]) < float(m[fam + "_r"][key[fam]]) and float(m[fam + "_e"][key[fam]]) < float(m[fam + "_l"][key[fam]]))
		_check("%s: anche il bonus dalla statistica cresce" % fam, float(m[fam]["bonus"]["pct"]) < float(m[fam + "_l"]["bonus"]["pct"]))
	_check("cura comune: 1.4x + 5% PV max", is_equal_approx(float(m["cura"]["heal"]), 1.4) and float(m["cura"]["bonus"]["pct"]) == 5.0 and str(m["cura"]["bonus"]["stat"]) == "max_hp")
	_check("cura leggendaria: 2.8x + 10% PV max", is_equal_approx(float(m["cura_l"]["heal"]), 2.8) and float(m["cura_l"]["bonus"]["pct"]) == 10.0)
	_check("barriera usa la difesa", str(m["barriera"]["bonus"]["stat"]) == "def")
	_check("colpo caricato usa l'attacco", str(m["colpo_caricato"]["bonus"]["stat"]) == "atk")
	_check("marchio usa il critico", str(m["marchio"]["bonus"]["stat"]) == "crit")
	for ult in ["spezzatutto", "bastione", "rinascita"]:
		_check("ultimate %s: ha un bonus dalla statistica" % ult, m[ult].has("bonus"))
	_check("ultimate leggendaria piu' forte", float(m["spezzatutto_l"]["mult"]) > float(m["spezzatutto"]["mult"]) and int(m["spezzatutto_l"]["rarity"]) == 3)
	_check("i dati restano coerenti", BattleContent.validate().is_empty())
	var u: Dictionary = _unit()
	_check("bonus cura comune = 5% di 1000", is_equal_approx(BattleContent.move_bonus(u, m["cura"]), 50.0))
	_check("bonus cura leggendaria = 10% di 1000", is_equal_approx(BattleContent.move_bonus(u, m["cura_l"]), 100.0))
	_check("bonus barriera = % della difesa", is_equal_approx(BattleContent.move_bonus(u, m["barriera"]), 4.0))
	_check("bonus marchio: il critico conta x10 (10% = 1000)", is_equal_approx(BattleContent.move_bonus(u, m["marchio"]), 100.0))
	_check("mossa senza bonus: 0", BattleContent.move_bonus(u, m["attack"]) == 0.0)
	var weak: Dictionary = _unit({"max_hp": 500})
	_check("piu' PV max, piu' cura", BattleContent.move_bonus(u, m["cura"]) > BattleContent.move_bonus(weak, m["cura"]))
	var d1: int = BattleResolver.calc_damage(_unit(), _unit({"id": "b", "def": 0, "side": "boss"}), 1.0, 0, 0.0)
	var d2: int = BattleResolver.calc_damage(_unit(), _unit({"id": "b", "def": 0, "side": "boss"}), 1.0, 0, 100.0)
	_check("il danno piatto si somma", d2 - d1 >= 99 and d2 - d1 <= 101)

	# la cura di una battaglia vera usa il bonus
	var state: Dictionary = BattleState.create_solo("p1", [BattleContent.default_entry("elle"), BattleContent.default_entry("kira"), BattleContent.default_entry("dax")], [], "distributore", 5, 0)
	var healer: Dictionary = BattleState.active_unit(state, "p1")
	healer["skills"] = ["cura_l"]
	healer["energy"] = 6
	healer["hp"] = 100
	healer["max_hp"] = 1000
	var ev: Array = []
	BattleResolver._player_act(state, healer, "cura_l", "p1", ev)
	var healed: int = 0
	for e in ev:
		if str(e.get("t", "")) == "heal":
			healed = int(e["amount"])
	var expected: int = int(round(float(healer["atk"]) * 2.8 + 100.0))
	_check("la cura leggendaria cura atk*2.8 + 10% PV max", healed == mini(expected, 900))

	# --- drop: ogni livello puo' uscire
	var rng := RNGState.new()
	rng.setup(99)
	var seen: Dictionary = {}
	for i in 400:
		for d in BattleContent.roll_drops("cabina", rng, 2):
			seen[str(d["id"])] = true
	_check("i livelli alti possono cadere", seen.has("cura_l") or seen.has("barriera_l") or seen.has("colpo_caricato_l") or seen.has("marchio_l") or seen.has("provoca_l"))

	# --- imprese
	var r: Dictionary = RosterState.new_roster()
	_check("all'inizio niente da riscuotere", Feats.claimable_count(r) == 0)
	r["cleared"] = {"distributore": 2}
	_check("boss battuto a NORMALE e DIFFICILE: due imprese pronte", Feats.claimable_count(r) == 2)
	var coins0: int = int(r["coins"])
	var reward: Dictionary = Feats.claim(r, "boss_distributore_0")
	_check("riscossione: premio dato", not reward.is_empty() and int(r["coins"]) == coins0 + int(reward["coins"]))
	_check("non si riscuote due volte", Feats.claim(r, "boss_distributore_0").is_empty() and Feats.claimable_count(r) == 1)
	_check("non si riscuote cio' che non e' fatto", Feats.claim(r, "boss_distributore_2").is_empty())
	var moves0: int = (r["moves"] as Dictionary).size()
	r["cleared"] = {"distributore": 3}
	Feats.claim(r, "boss_distributore_1")
	var rw3: Dictionary = Feats.claim(r, "boss_distributore_2")
	_check("l'impresa INCUBO regala una abilita' leggendaria", rw3.has("drop") and (r["moves"] as Dictionary).size() == moves0 + 1 and RosterState._used(r, "skills", "cura_l") == 0 and int(r["moves"].get("cura_l", 0)) == 1)
	Feats.record_battle(r, true)
	Feats.record_battle(r, false)
	_check("contatori battaglie", int(r["stats"]["plays"]) == 2 and int(r["stats"]["wins"]) == 1)
	_check("impresa 'vinci 1 battaglia' pronta", Feats.can_claim(r, Feats.by_id("wins_1")))
	var n: int = Feats.claim_all(r)
	_check("riscuoti tutto", n >= 1 and Feats.claimable_count(r) == 0)
	_check("il salvataggio con le imprese si ricarica", RosterStore.save(r, TMP) and RosterStore.load_or_new(TMP).get("feats", {}).get("claimed", {}).has("wins_1"))
	if FileAccess.file_exists(ProjectSettings.globalize_path(TMP)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	_check("ogni impresa ha un premio", Feats.all().all(func(f: Dictionary) -> bool: return not (f["reward"] as Dictionary).is_empty()))
	var ids: Dictionary = {}
	for f in Feats.all():
		ids[str(f["id"])] = true
	_check("id delle imprese unici", ids.size() == Feats.all().size())

	# --- schermata
	await process_frame
	var scr: Control = load("res://scenes/feats/feats_screen.tscn").instantiate()
	var r2: Dictionary = RosterState.new_roster()
	r2["cleared"] = {"distributore": 1}
	scr.roster = r2
	scr.save_path = TMP
	root.add_child(scr)
	await process_frame
	await process_frame
	_check("schermata: parte su DA RISCUOTERE", scr.group == "DA RISCUOTERE" and scr.visible_feats().size() == 1)
	_check("schermata: una riga", scr._list.get_child_count() >= 2)
	_check("schermata: riscuoti tutto attivo", not scr.claim_all_button.disabled)
	scr.show_group("TUTTE")
	_check("schermata: tutte le imprese", scr.visible_feats().size() == Feats.all().size())
	scr.show_group("MISSIONI")
	_check("schermata: solo missioni", scr.visible_feats().size() == BattleContent.BOSS_ORDER.size() * BattleContent.TIERS.size())
	_check("schermata: riscossione", scr.claim("boss_distributore_0") and Feats.claimable_count(r2) == 0)
	scr.queue_free()
	if FileAccess.file_exists(ProjectSettings.globalize_path(TMP)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
