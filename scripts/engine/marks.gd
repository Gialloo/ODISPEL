class_name Marks
extends RefCounted

# MARCHI: una risorsa a pile sul nemico, giocata in modo diverso da ogni personaggio
# (chi li applica, chi li accumula, chi li spende). Ogni marchio da' +10% di danno al nemico,
# +15% se il colpo usa munizioni. Restano fino a quando qualcuno li consuma (max 6).
# Qui ci sono anche i malus a gradi sul boss (DEF/ATK/VEL giu') e la schivata del nascosto.

const MAX: int = 6
const PCT: float = 0.10
const AMMO_PCT: float = 0.15
const PLAYER_MARK_BONUS: float = 1.25      # un giocatore marchiato dal boss: come prima, a tempo
const GRADE_PM: int = 150                  # un grado di malus/bonus = 15% della statistica
const DEBUFF_TURNS: int = 2
const DODGE_PM: int = 400                  # probabilita' di schivare del NASCOSTO (per mille)


static func count(u: Dictionary) -> int:
	return int(u.get("marks", 0))


# Moltiplicatore di danno dei marchi su chi subisce il colpo.
static func bonus_mult(defender: Dictionary, ammo_hit: bool) -> float:
	if bool(defender.get("pvp_unit", false)):      # PvP: stesse pile del boss, solo finche' il marchio dura
		var k: int = count(defender) if defender.get("statuses", {}).has("mark") else 0
		return 1.0 + float(k) * (AMMO_PCT if ammo_hit else PCT)
	if str(defender.get("side", "")) == "player":
		return PLAYER_MARK_BONUS if defender.get("statuses", {}).has("mark") else 1.0
	var n: int = count(defender)
	if n <= 0:
		return 1.0
	return 1.0 + float(n) * (AMMO_PCT if ammo_hit else PCT)


# Applica n marchi al nemico. Fa scattare le passive ("ogni marchio ricarica munizioni").
static func add(state: Dictionary, target: Dictionary, n: int, events: Array) -> void:
	if n <= 0 or int(target.get("hp", 1)) <= 0:
		return       # niente marchi su chi e' gia' a terra
	target["marks"] = mini(MAX, count(target) + n)
	target["statuses"]["mark"] = 99
	state["marks_applied"] = int(state.get("marks_applied", 0)) + n
	events.append({"t": "marks", "unit": target["id"], "n": count(target), "added": n})
	for p in state["players"]:
		for uid in p["team"]:
			var u: Dictionary = BattleState.unit(state, uid)
			var per: float = Signatures.value(u, "mark_ammo")
			if per <= 0.0 or not BattleState.is_alive(u):
				continue
			for mate_id in p["team"]:
				var mate: Dictionary = BattleState.unit(state, mate_id)
				if BattleState.is_alive(mate) and int(mate["ammo_max"]) > 0:
					BattleResolver._change_ammo(mate, int(round(per * float(n))), events)


# Toglie tutti i marchi e ne ritorna il numero.
static func consume(target: Dictionary, events: Array) -> int:
	var n: int = count(target)
	if n > 0:
		target["marks"] = 0
		target["statuses"].erase("mark")
		events.append({"t": "marks", "unit": target["id"], "n": 0, "added": -n})
	return n


# Malus a gradi sul boss. stat: atk, def, spd.
static func debuff(target: Dictionary, stat: String, grades: int, events: Array) -> void:
	if not target.has("mods"):
		target["mods"] = []
	Factions.add_mod(target, "debuff_" + stat, stat, -GRADE_PM * grades, DEBUFF_TURNS)
	events.append({"t": "debuff", "unit": target["id"], "stat": stat, "grades": grades})


# Il boss non passa dal refresh delle aure: le sue modifiche si leggono qui.
static func boss_mult(u: Dictionary, stat: String) -> float:
	if str(u.get("side", "")) != "boss":
		return 1.0
	var pm: int = 0
	for m in u.get("mods", []):
		if str(m["stat"]) == stat:
			pm += int(m["pm"])
	return maxf(0.3, 1.0 + float(pm) / 1000.0)


# Nascosto: una parte dei colpi del boss va a vuoto. Tiro deterministico (stesso seme, stesso esito).
static func dodges(state: Dictionary, defender: Dictionary, attacker: Dictionary, salt: int) -> bool:
	if not defender.get("statuses", {}).has("hidden") or str(attacker.get("side", "")) != "boss":
		return false
	var key: String = "dodge|%s|%s|%s|%s|%d" % [str(state["rng_seed"]), str(state["round"]), str(attacker["id"]), str(defender["id"]), salt]
	var h: int = int(key.hash()) & 0xFFFFFFFF
	h = ((h ^ (h >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	h = ((h ^ (h >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return int(h % 1000) < DODGE_PM
