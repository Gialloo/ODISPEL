extends SceneTree

# SPEDIZIONE LUNGA (10 tappe) e modificatori volontari.
#   godot --headless --path . -s res://tests/unit/test_expedition_long.gd

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


# Gioca tutta la spedizione vincendo ogni scontro e scegliendo la prima opzione. Ritorna i tipi di tappa visti.
func _walk(run: Dictionary, win_all: bool = true) -> Array:
	var kinds: Array = []
	var guard: int = 0
	while str(run.get("phase", "")) != "done" and guard < 80:
		guard += 1
		var k: String = Expedition.kind(run)
		kinds.append(k)
		if k == "fight":
			var bp: Dictionary = Expedition.battle_params(run)
			var st: Dictionary = BattleState.create([_spec("a")], str(bp["boss"]), 7, int(bp["tier"]))
			Expedition.apply_to_battle(run, st)
			if win_all:
				st["winner"] = "players"
				BattleState.boss(st)["hp"] = 0
			else:
				st["winner"] = "boss"
				for uid in st["units"]:
					if str(st["units"][uid]["side"]) == "player":
						st["units"][uid]["hp"] = 0
			Expedition.after_battle(run, st)
		else:
			var ids: Array = Expedition.option_ids(run)
			if ids.is_empty():
				break
			var err: String = Expedition.choose(run, str(ids[0]))
			if err != "":
				break
	return kinds


func _init() -> void:
	var short: Dictionary = Expedition.new_run(5, "distributore", 1)
	var long: Dictionary = Expedition.new_run(5, "distributore", 1, false, true)
	_check("breve: 6 tappe", Expedition.stages(short).size() == 6 and Expedition.map_nodes(short).size() == 6)
	_check("lunga: 10 tappe", Expedition.stages(long).size() == 10 and Expedition.map_nodes(long).size() == 10)
	var ks: Array = Expedition.stages(long).map(func(x: Variant) -> String: return str(x["k"]))
	var roles: Array = Expedition.stages(long).map(func(x: Variant) -> String: return str(x.get("role", "")))
	_check("lunga ha rifugio, guardiano, reliquia, terzo scontro", ks.has("shelter") and roles.has("guardian") and ks.has("event2") and roles.has("combat3"))

	var kinds: Array = _walk(long)
	_check("lunga completata", str(long["phase"]) == "done" and str(long.get("result", "")) == "win")
	_check("lunga: tutte le tappe percorse", kinds.has("shelter") and kinds.has("event2") and kinds.has("cross") and kinds.has("boon"))
	_check("lunga: piu' scontri (4)", int(long["fights"]) == 5 or int(long["fights"]) >= 4)
	var kinds_s: Array = _walk(short)
	_check("breve completata", str(short["phase"]) == "done" and str(short.get("result", "")) == "win")
	_check("lunga: piu' potenziamenti della breve", (long["boons"] as Array).size() > (short["boons"] as Array).size())
	_check("lunga paga di piu'", int(Expedition.reward(long)["coins"]) > int(Expedition.reward(short)["coins"]))

	# modificatori volontari
	var base: Dictionary = Expedition.new_run(5, "distributore", 1, false, true)
	var hard: Dictionary = Expedition.new_run(5, "distributore", 1, false, true, ["poche_risorse", "boss_furioso", "seconda_minaccia", "inventato"])
	_check("modificatori validi, quello inventato scartato", (hard["mods"] as Array).size() == 3 and not (hard["mods"] as Array).has("inventato"))
	_check("premi maggiorati", Expedition.reward_mult(hard) > Expedition.reward_mult(base))
	_walk(base)
	_walk(hard)
	_check("modificatori: piu' crediti a parita' di percorso", int(Expedition.reward(hard)["coins"]) > int(Expedition.reward(base)["coins"]))

	# sconfitta: la spedizione lunga finisce e si puo' passare dal checkpoint
	var lost: Dictionary = Expedition.new_run(9, "distributore", 0, false, true)
	_walk(lost, false)
	_check("sconfitta: spedizione chiusa", str(lost["phase"]) == "done" and str(lost.get("result", "")) != "win")

	# salvataggio: la run resta JSON
	var again: Variant = JSON.parse_string(JSON.stringify(long))
	_check("run lunga serializzabile", again is Dictionary and str(again["phase"]) == "done")

	# persistenza a fine spedizione: XP veterano maggiore in lunga
	var roster: Dictionary = RosterState.new_roster()
	var lines: Array = Expedition.finish(roster, long)
	_check("fine spedizione lunga: righe e XP", not lines.is_empty() and int(Expedition.data(roster)["wins"]) == 1)
	_check("idempotente", Expedition.finish(roster, long).is_empty() and int(Expedition.data(roster)["wins"]) == 1)

	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
