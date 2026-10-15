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
const CARRY_HEAL: float = 0.25          # tra un piano e l'altro la squadra recupera il 25% dei PV massimi
const CARRY_REVIVE: float = 0.30        # chi e' caduto torna con il 30%

const MODS: Array = [
	{"id": "corazzato", "name": "CORAZZATO", "desc": "DIFESA +30%"},
	{"id": "furioso", "name": "FURIOSO", "desc": "ATTACCO +20%"},
	{"id": "resistente", "name": "RESISTENTE", "desc": "PV +25%"},
	{"id": "veloce", "name": "VELOCE", "desc": "VELOCITA' +20%"},
	{"id": "vampirico", "name": "VAMPIRICO", "desc": "SI CURA COLPENDO"},
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
	# il Ciclo Infinito si ferma a INCUBO: ABISSO e' una prova a parte (solo Missioni)
	return clampi((maxi(1, floor_n) - 1) / TIER_EVERY, 0, mini(2, BattleContent.TIERS.size() - 1))


static func mod_for(floor_n: int) -> Dictionary:
	if floor_n < MOD_FROM:
		return {}
	return MODS[(floor_n * 7 + floor_n / 4) % MODS.size()]


static func hp_mult(floor_n: int) -> float:
	var f: float = float(maxi(1, floor_n) - 1)
	return 1.0 + HP_STEP * f + 0.004 * f * f       # sale piu' in fretta dopo i primi piani: i potenziamenti si sommano


static func atk_mult(floor_n: int) -> float:
	var f: float = float(maxi(1, floor_n) - 1)
	return 1.0 + ATK_STEP * f + 0.002 * f * f


static func reward_mult(floor_n: int) -> float:
	return 1.0 + REWARD_STEP * float(maxi(1, floor_n) - 1)


# Scala il bersaglio dello stato di battaglia (dopo BattleState.create). Idempotente solo se chiamata una volta.
static func apply(state: Dictionary, floor_n: int, mod_override: String = "") -> void:
	var boss: Dictionary = BattleState.boss(state)
	var hp: float = float(boss["max_hp"]) * hp_mult(floor_n)
	var atk: float = float(boss["atk"]) * atk_mult(floor_n)
	var def: float = float(boss["def"])
	var spd: float = float(boss["spd"])
	var mod_id: String = mod_override if mod_override != "" else str(mod_for(floor_n).get("id", ""))
	match mod_id:
		"corazzato":
			def *= 1.3
		"furioso":
			atk *= 1.2
		"resistente":
			hp *= 1.25
		"veloce":
			spd *= 1.2
		"vampirico":
			state["boss_drain"] = 0.3
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


const TOP_SIZE: int = 5


# Fine serie (si perde): il piano raggiunto entra nella classifica locale dei migliori 5.
static func finish_run(roster: Dictionary, reached: int, day: String = "") -> void:
	if reached <= 0:
		return
	if not roster.has("endless"):
		roster["endless"] = {"best": 0, "runs": 0}
	var e: Dictionary = roster["endless"]
	var top: Array = e.get("top", [])
	top.append({"floor": reached, "day": day if day != "" else Time.get_date_string_from_system()})
	top.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["floor"]) > int(b["floor"]))
	while top.size() > TOP_SIZE:
		top.pop_back()
	e["top"] = top


static func top(roster: Dictionary) -> Array:
	return roster.get("endless", {}).get("top", [])


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


# PV a fine piano: {unit_id: hp} di tutta la squadra (anche IA e riserve).
static func carry_from(state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if str(u["side"]) == "player":
			out[str(uid)] = int(u["hp"])
	return out


# Al piano successivo: i PV si portano dietro, con un po' di recupero; i caduti tornano a meta' strada.
static func apply_carry(state: Dictionary, carry: Dictionary) -> void:
	for uid in carry:
		var u: Dictionary = BattleState.unit(state, str(uid))
		if u.is_empty():
			continue
		var mx: int = int(u["max_hp"])
		var hp: int = int(carry[uid])
		if hp <= 0:
			hp = int(ceil(float(mx) * CARRY_REVIVE))
		else:
			hp = hp + int(ceil(float(mx) * CARRY_HEAL))
		u["hp"] = clampi(hp, 1, mx)


# ---------- Potenziamenti di serie ----------
# Dopo ogni piano vinto se ne sceglie uno su tre; durano fino alla fine della serie e si possono ripetere (si sommano).
const BOONS: Dictionary = {
	"furia": {"name": "FURIA", "desc": "ATTACCO +8%"},
	"tempra": {"name": "TEMPRA", "desc": "PV MAX +10%"},
	"rapidita": {"name": "RAPIDITA'", "desc": "VELOCITA' +8%"},
	"corazza": {"name": "CORAZZA", "desc": "DIFESA +10%"},
	"scorta": {"name": "SCORTA", "desc": "ENERGIA +2 ALL'INIZIO"},
	"carica": {"name": "CARICA", "desc": "ULTIMATE +30% ALL'INIZIO"},
	"scudo": {"name": "SCUDO", "desc": "SCUDO 8% PV ALL'INIZIO"},
	"riflessi": {"name": "RIFLESSI", "desc": "LE REAZIONI COSTANO 1 RISERVA IN MENO"},
	"riserva": {"name": "RISERVA", "desc": "RISERVA DI SQUADRA +2 ALL'INIZIO"},
}
const BOON_ORDER: Array = ["furia", "tempra", "rapidita", "corazza", "scorta", "carica", "scudo", "riflessi", "riserva"]


# Tre proposte (sempre le stesse per lo stesso piano, cosi' ricaricare non cambia l'offerta).
static func offer(floor_n: int, count: int = 3) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("boon|%d" % floor_n)
	var pool: Array = BOON_ORDER.duplicate()
	var out: Array = []
	while out.size() < count and not pool.is_empty():
		out.append(pool.pop_at(rng.randi() % pool.size()))
	return out


static func boon_count(boons: Array, id: String) -> int:
	var n: int = 0
	for b in boons:
		if str(b) == id:
			n += 1
	return n


# Applica i potenziamenti agli operatori dei giocatori (dopo BattleState.create, prima del riporto PV).
static func apply_boons(state: Dictionary, boons: Array) -> void:
	if boons.is_empty():
		return
	state["react_discount"] = boon_count(boons, "riflessi")
	state["reserve"] = mini(BattleTypes.RESERVE_MAX, int(state.get("reserve", 0)) + 2 * boon_count(boons, "riserva"))
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if str(u["side"]) != "player":
			continue
		var base: Dictionary = u["base"]
		var f: int = boon_count(boons, "furia")
		var t: int = boon_count(boons, "tempra")
		var r: int = boon_count(boons, "rapidita")
		var c: int = boon_count(boons, "corazza")
		if f > 0:
			base["atk"] = int(round(float(base["atk"]) * (1.0 + 0.08 * float(f))))
		if r > 0:
			base["spd"] = int(round(float(base["spd"]) * (1.0 + 0.08 * float(r))))
		if c > 0:
			base["def"] = int(round(float(base["def"]) * (1.0 + 0.10 * float(c))))
		if t > 0:
			var extra: int = int(round(float(u["max_hp"]) * 0.10 * float(t)))
			u["max_hp"] = int(u["max_hp"]) + extra
			u["hp"] = int(u["hp"]) + extra
		u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + 2 * boon_count(boons, "scorta"))
		u["gauge"] = mini(BattleTypes.GAUGE_MAX, int(u["gauge"]) + 30 * boon_count(boons, "carica"))
		u["shield"] = int(u["shield"]) + int(round(float(u["max_hp"]) * 0.08 * float(boon_count(boons, "scudo"))))
	Factions.refresh(state)
