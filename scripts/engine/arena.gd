class_name Arena
extends RefCounted

# ARENA E COMPORTAMENTI: due regole che rendono ogni scontro diverso senza inventare nuovi boss.
#  - EVENTI DELL'ARENA: ogni 3 round (dal secondo) l'arena cambia. L'evento e' annunciato a inizio round e si risolve alla fine:
#    offre un'opportunita' e un rischio, mai solo decorazione.
#  - COMPORTAMENTI: ogni boss ha un modo di reagire che si impara a leggere (non solo statistiche).
# Tutto e' deterministico (dipende dal seme della battaglia): in multiplayer si ripete uguale per tutti.

const EVERY: int = 3
const FIRST: int = 2
const CONTAMINATION_PCT: float = 0.08     # PV massimi persi da chi resta nella zona
const SEAL_BALANCE: int = 3               # equilibrio tolto al boss se il sigillo si rompe
const SEAL_SHIELD: float = 0.04           # scudo del boss se nessuno lo rompe
const RAGE_STEP: float = 0.10             # per ogni cura nel round (punisce_cure), massimo 3
const RAGE_MAX: int = 3
const GUARD_PUNISH: float = 1.15
const MARK_SHIELD: float = 0.04

const EVENTS: Dictionary = {
	"contaminazione": {"name": "ZONA CONTAMINATA", "desc": "Chi e' sotto la nube perde il %d%% dei PV a fine round, a meno che si metta in GUARDIA o venga scambiato."},
	"eco": {"name": "ECO", "desc": "Il colpo piu' forte che hai dato al boss si ripete al %d%%. Prepara un colpo grosso nel round prima."},
	"sigillo": {"name": "SIGILLO", "desc": "Se almeno %d operatori attaccano il boss nello stesso round il sigillo si rompe: -%d equilibrio e +1 Riserva. Altrimenti il boss si copre di scudo."},
}
const EVENT_ORDER: Array = ["contaminazione", "sigillo", "eco"]

const BEHAVIORS: Dictionary = {
	"punisce_cure": {"name": "PUNISCE LE CURE", "desc": "Ogni cura nel round rende la sua mossa +10% (fino a +30%). Cura quando serve, non per abitudine."},
	"reagisce_marchi": {"name": "REAGISCE AI MARCHI", "desc": "Con 3 o piu' marchi si copre di scudo. Meglio consumarli (combo e detonazioni) che accumularli."},
	"punisce_guardia": {"name": "PUNISCE LA GUARDIA", "desc": "Se due o piu' operatori si mettono in guardia la sua mossa fa +15%. Difendersi tutti insieme non basta."},
}
const BEHAVIOR_ORDER: Array = ["punisce_cure", "reagisce_marchi", "punisce_guardia"]


# Comportamento di un boss (fisso per boss).
static func behavior_of(boss_id: String) -> String:
	var i: int = BattleContent.BOSS_ORDER.find(boss_id)
	if i < 0:
		i = absi(hash(boss_id))
	return str(BEHAVIOR_ORDER[i % BEHAVIOR_ORDER.size()])


# Annuncia l'evento del round (chiamata a inizio round).
static func roll(state: Dictionary) -> void:
	state["arena"] = {}
	var r: int = int(state.get("round", 1))
	if r < FIRST or (r - FIRST) % EVERY != 0 or str(state.get("winner", "")) != "":
		return
	var alive: Array = BattleState.alive_players(state)
	if alive.is_empty():
		return
	var h: int = absi(hash("%s|%d" % [str(state.get("rng_seed", "")), r]))
	var id: String = str(EVENT_ORDER[h % EVENT_ORDER.size()])
	var ev: Dictionary = {"id": id}
	if id == "contaminazione":
		var p: Dictionary = alive[(h / 7) % alive.size()]
		ev["player"] = str(p["id"])
		ev["unit"] = str(p["active"])
	state["arena"] = ev


# Frasi mostrate al giocatore mentre pianifica.
static func hint_lines(state: Dictionary) -> Array:
	var out: Array = []
	var ev: Dictionary = state.get("arena", {})
	if not ev.is_empty():
		var def: Dictionary = EVENTS[str(ev["id"])]
		if str(ev["id"]) == "contaminazione":
			var u: Dictionary = BattleState.unit(state, str(ev.get("unit", "")))
			out.append("ARENA · %s su %s: GUARDIA o cambio per evitarla" % [str(def["name"]), str(u.get("name", "")).to_upper()])
		elif str(ev["id"]) == "eco":
			out.append("ARENA · ECO: il colpo piu' forte del round scorso (%d) si ripete al %d%%" % [int(state.get("echo", 0)), int(round(Tactics.ECHO_PCT * 100.0))])
		else:
			out.append("ARENA · %s: attaccate in %d o piu' per romperlo" % [str(def["name"]), seal_need(state)])
	var boss_id: String = str(BattleState.boss(state).get("char", ""))
	var bid: String = behavior_of(boss_id)
	var known: Dictionary = state.get("known", {})
	if (known.get("behaviors", []) as Array).has(boss_id):
		out.append("NOTO · %s: %s" % [str(BEHAVIORS[bid]["name"]), str(BEHAVIORS[bid]["desc"])])
	elif not known.is_empty():
		out.append("Questo boss reagisce in un modo che non conosci ancora: osserva e lo annoterai nell'ARCHIVIO.")
	return out


static func seal_need(state: Dictionary) -> int:
	return mini(2, BattleState.alive_players(state).size())


# Risolve l'evento (fine round, prima del recupero). Aggiunge eventi {"t": "arena", ...}.
static func resolve(state: Dictionary, events: Array) -> void:
	var ev: Dictionary = state.get("arena", {})
	if ev.is_empty():
		return
	var boss: Dictionary = BattleState.boss(state)
	if str(ev["id"]) == "contaminazione":
		var u: Dictionary = BattleState.unit(state, str(ev.get("unit", "")))
		var p: Dictionary = BattleState.player(state, str(ev.get("player", "")))
		if not BattleState.is_alive(u) or p.is_empty():
			return
		var last: String = str(state.get("acts", {}).get(str(u["id"]), ""))
		var safe: bool = str(p["active"]) != str(u["id"]) or last == BattleTypes.ACTION_GUARD
		var amount: int = 0
		if not safe:
			amount = mini(int(u["hp"]) - 1, maxi(1, int(round(float(u["max_hp"]) * CONTAMINATION_PCT))))
			u["hp"] = int(u["hp"]) - amount
		events.append({"t": "arena", "id": "contaminazione", "ok": safe, "unit": u["id"], "amount": amount})
	elif str(ev["id"]) == "eco":
		var echo_dmg: int = int(round(float(state.get("echo", 0)) * Tactics.ECHO_PCT))
		if echo_dmg > 0 and BattleState.is_alive(boss):
			var shield_part: int = mini(int(boss["shield"]), echo_dmg)
			boss["shield"] = int(boss["shield"]) - shield_part
			boss["hp"] = maxi(0, int(boss["hp"]) - (echo_dmg - shield_part))
			if int(boss["hp"]) <= 0:
				BattleResolver._on_down(boss, events)
		events.append({"t": "arena", "id": "eco", "ok": echo_dmg > 0, "unit": "", "amount": echo_dmg})
	elif str(ev["id"]) == "sigillo":
		var attackers: Dictionary = {}
		for entry in state.get("tags", []):
			if entry["tags"].has("ATTACK"):
				attackers[str(entry["unit"])] = true
		var broke: bool = attackers.size() >= seal_need(state)
		events.append({"t": "arena", "id": "sigillo", "ok": broke, "unit": "", "amount": 0})
		if broke:
			BattleResolver._drain_balance(boss, SEAL_BALANCE, boss, events)
			BattleResolver._gain_reserve(state, 1, "arena", events)
		elif BattleState.is_alive(boss):
			var sh: int = int(round(float(boss["max_hp"]) * SEAL_SHIELD))
			boss["shield"] = int(boss["shield"]) + sh
			events.append({"t": "shield", "src": boss["id"], "dst": boss["id"], "amount": sh})
	state["arena"] = {}


# Moltiplicatore e eventi del comportamento del boss al momento di agire.
static func boss_behavior(state: Dictionary, boss: Dictionary, events: Array) -> float:
	var id: String = behavior_of(str(boss.get("char", "")))
	var mult: float = 1.0
	match id:
		"punisce_cure":
			var n: int = 0
			for e in state.get("events", []):
				if str(e.get("t", "")) == "heal" and str(BattleState.unit(state, str(e.get("dst", ""))).get("side", "")) == "player":
					n += 1
			n = mini(n, RAGE_MAX)
			if n > 0:
				mult = 1.0 + RAGE_STEP * float(n)
				events.append({"t": "behavior", "id": id, "n": n})
		"reagisce_marchi":
			if Marks.count(boss) >= 3:
				var sh: int = int(round(float(boss["max_hp"]) * MARK_SHIELD))
				boss["shield"] = int(boss["shield"]) + sh
				events.append({"t": "behavior", "id": id, "n": Marks.count(boss)})
				events.append({"t": "shield", "src": boss["id"], "dst": boss["id"], "amount": sh})
		"punisce_guardia":
			var g: int = 0
			for p in BattleState.alive_players(state):
				if BattleState.active_unit(state, str(p["id"])).get("statuses", {}).has("guard"):
					g += 1
			if g >= 2:
				mult = GUARD_PUNISH
				events.append({"t": "behavior", "id": id, "n": g})
	return mult
