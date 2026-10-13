class_name Objectives
extends RefCounted

# Obiettivi giornalieri: tre compiti nuovi ogni giorno, con un piccolo premio.
# Vivono nel salvataggio dell'operatore (roster["objectives"]). Si aggiornano da soli a
# fine battaglia e il premio viene dato subito quando l'obiettivo e' completo.
#
# roster["objectives"] = {"day": "2026-10-12", "list": [ {kind, boss, goal, progress, done, reward} ]}

const COUNT: int = 3
const KINDS: Array = ["play", "win", "win_boss", "win_hard", "boss_variety", "win_night", "breaks", "synergies", "flawless"]

# Spento solo dai test che contano le monete al centesimo.
static var enabled: bool = true


static func today() -> String:
	return Time.get_date_string_from_system()


# Prepara gli obiettivi del giorno se non ci sono (o se sono di ieri). Ritorna true se nuovi.
static func ensure_today(roster: Dictionary, day: String = "") -> bool:
	var d: String = day if day != "" else today()
	var cur: Dictionary = roster.get("objectives", {})
	if str(cur.get("day", "")) == d and cur.get("list", []).size() > 0:
		return false
	roster["objectives"] = {"day": d, "list": _generate(roster, d)}
	return true


static func _generate(roster: Dictionary, day: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(day)
	var open_bosses: Array = []
	for id in BattleContent.BOSS_ORDER:
		if RosterState.is_boss_unlocked(roster, str(id)):
			open_bosses.append(str(id))
	var kinds: Array = ["play", "win"]
	kinds.append("win_boss")
	var any_hard: bool = false
	for id in open_bosses:
		if RosterState.cleared_tiers(roster, str(id)) >= 1:
			any_hard = true
	if any_hard:
		kinds.append("win_hard")
	if open_bosses.size() >= 2:
		kinds.append("boss_variety")
	if open_bosses.size() >= 3:
		# obiettivi che invitano a sperimentare: rotture, sinergie, vittorie pulite
		kinds.append("breaks")
		kinds.append("synergies")
		kinds.append("flawless")
	var any_night: bool = false
	for id in open_bosses:
		if RosterState.cleared_tiers(roster, str(id)) >= 2:
			any_night = true
	if any_night:
		kinds.append("win_night")
	# tre tipi diversi, in ordine mescolato ma ripetibile
	for i in range(kinds.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = tmp
	var out: Array = []
	for k in mini(COUNT, kinds.size()):
		out.append(_make(str(kinds[k]), open_bosses, rng))
	return out


static func _make(kind: String, open_bosses: Array, rng: RandomNumberGenerator) -> Dictionary:
	var o: Dictionary = {"kind": kind, "boss": "", "goal": 1, "progress": 0, "done": false, "reward": {}}
	match kind:
		"play":
			o["goal"] = 3
			o["reward"] = {"coins": 300, "nucleo": 1}
		"win":
			o["goal"] = 2
			o["reward"] = {"coins": 500, "nucleo": 2}
		"win_boss":
			o["boss"] = str(open_bosses[rng.randi_range(0, open_bosses.size() - 1)])
			o["reward"] = {"coins": 600, "lega": 2}
		"win_hard":
			o["reward"] = {"coins": 900, "nucleo": 3}
		"boss_variety":
			o["goal"] = 2
			o["seen"] = []
			o["reward"] = {"coins": 700, "nucleo": 2, "lega": 1}
		"win_night":
			o["reward"] = {"coins": 1400, "nucleo": 4}
		"breaks":
			o["goal"] = 3
			o["reward"] = {"coins": 700, "nucleo": 2}
		"synergies":
			o["goal"] = 5
			o["reward"] = {"coins": 700, "lega": 2}
		"flawless":
			o["reward"] = {"coins": 1000, "nucleo": 3}
	return o


static func describe(o: Dictionary) -> String:
	match str(o["kind"]):
		"play":
			return "Affronta %d battaglie" % int(o["goal"])
		"win":
			return "Vinci %d battaglie" % int(o["goal"])
		"win_boss":
			return "Sconfiggi %s" % MissionConfig.boss_title(str(o["boss"]))
		"win_hard":
			return "Vinci a DIFFICILE o piu'"
		"boss_variety":
			return "Batti %d boss diversi" % int(o["goal"])
		"win_night":
			return "Vinci a INCUBO"
		"breaks":
			return "Causa %d ROTTURE al boss" % int(o["goal"])
		"synergies":
			return "Attiva %d SINERGIE tra compagni" % int(o["goal"])
		"flawless":
			return "Vinci senza nessun K.O."
	return str(o["kind"])


static func reward_text(reward: Dictionary) -> String:
	var parts: Array = []
	if int(reward.get("coins", 0)) > 0:
		parts.append("%d CREDITI" % int(reward["coins"]))
	if int(reward.get("nucleo", 0)) > 0:
		parts.append("%d NUCLEO" % int(reward["nucleo"]))
	if int(reward.get("lega", 0)) > 0:
		parts.append("%d LEGA" % int(reward["lega"]))
	return " + ".join(parts)


# Registra una battaglia finita. Ritorna i testi degli obiettivi appena completati.
static func record_battle(roster: Dictionary, boss_id: String, tier: int, victory: bool, day: String = "", stats: Dictionary = {}) -> Array:
	if not enabled:
		return []
	ensure_today(roster, day)
	var done_now: Array = []
	for o in roster["objectives"]["list"]:
		if bool(o["done"]):
			continue
		var hit: bool = false
		match str(o["kind"]):
			"play":
				hit = true
			"win":
				hit = victory
			"win_boss":
				hit = victory and str(o["boss"]) == boss_id
			"win_hard":
				hit = victory and tier >= 1
			"win_night":
				hit = victory and tier >= 2
			"boss_variety":
				var seen: Array = o.get("seen", [])
				hit = victory and not seen.has(boss_id)
				if hit:
					seen.append(boss_id)
					o["seen"] = seen
		var gain: int = 1
		match str(o["kind"]):
			"breaks":
				gain = int(stats.get("breaks", 0))
				hit = gain > 0
			"synergies":
				gain = int(stats.get("synergies", 0))
				hit = gain > 0
			"flawless":
				hit = victory and not stats.is_empty() and int(stats.get("downs", 0)) == 0
		if not hit:
			continue
		o["progress"] = int(o["progress"]) + gain
		if int(o["progress"]) >= int(o["goal"]):
			o["done"] = true
			_give(roster, o["reward"])
			done_now.append("OBIETTIVO: %s  (+%s)" % [describe(o), reward_text(o["reward"])])
	return done_now


static func _give(roster: Dictionary, reward: Dictionary) -> void:
	roster["coins"] = int(roster.get("coins", 0)) + int(reward.get("coins", 0))
	for mat in ["nucleo", "lega"]:
		if int(reward.get(mat, 0)) > 0:
			roster["materials"][mat] = int(roster["materials"].get(mat, 0)) + int(reward[mat])


static func completed(roster: Dictionary) -> int:
	var n: int = 0
	for o in roster.get("objectives", {}).get("list", []):
		if bool(o["done"]):
			n += 1
	return n
