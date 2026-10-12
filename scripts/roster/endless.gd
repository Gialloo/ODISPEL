class_name Endless
extends RefCounted

# CICLO INFINITO: una serie di bersagli sempre piu' duri, un piano dopo l'altro, finche' la squadra regge.
# Ogni piano e' una battaglia normale (stessi boss, stessa squadra); cambia solo la scala dei nemici,
# un modificatore a sorpresa dal piano 3 e i premi, che crescono col piano. Il record resta nel salvataggio.
#
# roster["endless"] = {"best": piano record, "runs": serie giocate}

const UNLOCK_BOSSES: int = 3            # per aprirlo servono 3 bersagli battuti almeno a NORMALE
const TIER_EVERY: int = 5               # ogni 5 piani sale la difficolta' base (fino a INCUBO)
const HP_STEP: float = 0.08             # +8% PV del bersaglio per piano
const ATK_STEP: float = 0.04            # +4% attacco per piano
const REWARD_STEP: float = 0.12         # +12% premi per piano
const BONUS_EVERY: int = 5              # ogni 5 piani, materiali extra
const MOD_FROM: int = 3                 # primo piano con modificatore

const MODS: Array = [
	{"id": "corazzato", "name": "CORAZZATO", "desc": "DIFESA +30%"},
	{"id": "furioso", "name": "FURIOSO", "desc": "ATTACCO +20%"},
	{"id": "resistente", "name": "RESISTENTE", "desc": "PV +25%"},
	{"id": "veloce", "name": "VELOCE", "desc": "VELOCITA' +20%"},
]


static func cleared_count(roster: Dictionary) -> int:
	var n: int = 0
	for id in BattleContent.BOSS_ORDER:
		if RosterState.cleared_tiers(roster, str(id)) >= 1:
			n += 1
	return n


static func available(roster: Dictionary) -> bool:
	return cleared_count(roster) >= UNLOCK_BOSSES


static func best(roster: Dictionary) -> int:
	return int(roster.get("endless", {}).get("best", 0))


# Il bersaglio del piano: a rotazione, con l'ordine che cambia a ogni giro cosi' non e' sempre lo stesso.
static func boss_for(floor_n: int) -> String:
	var order: Array = BattleContent.BOSS_ORDER
	var f: int = maxi(1, floor_n) - 1
	var cycle: int = f / order.size()
	return str(order[(f + cycle * 3) % order.size()])


static func tier_for(floor_n: int) -> int:
	return clampi((maxi(1, floor_n) - 1) / TIER_EVERY, 0, BattleContent.TIERS.size() - 1)


static func mod_for(floor_n: int) -> Dictionary:
	if floor_n < MOD_FROM:
		return {}
	return MODS[(floor_n * 7 + floor_n / 4) % MODS.size()]


static func hp_mult(floor_n: int) -> float:
	return 1.0 + HP_STEP * float(maxi(1, floor_n) - 1)


static func atk_mult(floor_n: int) -> float:
	return 1.0 + ATK_STEP * float(maxi(1, floor_n) - 1)


static func reward_mult(floor_n: int) -> float:
	return 1.0 + REWARD_STEP * float(maxi(1, floor_n) - 1)


# Scala il bersaglio dello stato di battaglia (dopo BattleState.create). Idempotente solo se chiamata una volta.
static func apply(state: Dictionary, floor_n: int) -> void:
	var boss: Dictionary = BattleState.boss(state)
	var hp: float = float(boss["max_hp"]) * hp_mult(floor_n)
	var atk: float = float(boss["atk"]) * atk_mult(floor_n)
	var def: float = float(boss["def"])
	var spd: float = float(boss["spd"])
	match str(mod_for(floor_n).get("id", "")):
		"corazzato":
			def *= 1.3
		"furioso":
			atk *= 1.2
		"resistente":
			hp *= 1.25
		"veloce":
			spd *= 1.2
	boss["max_hp"] = int(round(hp))
	boss["hp"] = int(round(hp))
	boss["atk"] = int(round(atk))
	boss["def"] = int(round(def))
	boss["spd"] = int(round(spd))
	state["endless"] = floor_n


# Premi del piano: i normali moltiplicati, piu' un bonus di materiali ogni BONUS_EVERY piani.
static func scale_rewards(rewards: Dictionary, floor_n: int) -> Dictionary:
	var m: float = reward_mult(floor_n)
	var out: Dictionary = rewards.duplicate(true)
	out["coins"] = int(round(float(out.get("coins", 0)) * m))
	var mats: Dictionary = out.get("materials", {})
	for k in mats:
		mats[k] = int(round(float(mats[k]) * m))
	if floor_n % BONUS_EVERY == 0:
		mats["nucleo"] = int(mats.get("nucleo", 0)) + 2
		mats["lega"] = int(mats.get("lega", 0)) + 2
	out["materials"] = mats
	return out


# Registra il risultato di un piano. Ritorna true se e' un nuovo record.
static func record(roster: Dictionary, floor_n: int, won: bool) -> bool:
	if not roster.has("endless"):
		roster["endless"] = {"best": 0, "runs": 0}
	var e: Dictionary = roster["endless"]
	var is_record: bool = false
	if won and floor_n > int(e.get("best", 0)):
		e["best"] = floor_n
		is_record = true
	if floor_n == 1:
		e["runs"] = int(e.get("runs", 0)) + 1
	return is_record


static func start(floor_n: int = 1) -> void:
	MissionConfig.set_endless(floor_n)
	SceneRouter.go("battle", true)
