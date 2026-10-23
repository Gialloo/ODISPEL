class_name Tactics
extends RefCounted

# TATTICHE AVANZATE: ordini di squadra, potere con un prezzo, tecnica proibita, placche d'armatura, attacchi concatenati,
# eco, determinazione, sfide facoltative e maestria. Tutto deterministico (stesso seme = stesso risultato in rete).
# Il motore le chiama in pochi punti (vedi BattleResolver); ogni regola sta qui, in un solo posto.

# ---------- Ordini di squadra ----------
# Prima del round ogni giocatore puo' indicare un ordine; vale quello della maggioranza (in pareggio, del primo giocatore).
const ORDERS: Dictionary = {
	"concentra": {"name": "CONCENTRA", "desc": "Tutta la squadra colpisce il boss: +5% danno"},
	"proteggi": {"name": "PROTEGGI", "desc": "Ognuno parte con uno scudo del 4% dei PV"},
	"interrompi": {"name": "INTERROMPI", "desc": "Le Interruzioni tolgono 1 equilibrio in piu'"},
	"risorse": {"name": "RISORSE", "desc": "Se nessuno reagisce, +1 Riserva a fine round"},
}
const ORDER_ORDER: Array = ["concentra", "proteggi", "interrompi", "risorse"]
const FOCUS_MULT: float = 1.05
const PROTECT_SHIELD: float = 0.04

# ---------- Potere con un prezzo ----------
const PUSH: Dictionary = {
	"prezzo": {"name": "PREZZO", "mult": 1.4, "hp": 0.10, "lock": 1, "desc": "Danno x1.4, paghi il 10% dei PV e non puoi reagire al round dopo"},
	"proibita": {"name": "PROIBITA", "mult": 2.0, "hp": 0.25, "lock": 2, "desc": "Danno x2, paghi il 25% dei PV, niente reazioni per 2 round, e a fine spedizione resti segnato. Una volta a battaglia"},
}
const PUSH_ORDER: Array = ["prezzo", "proibita"]

# ---------- Placche d'armatura ----------
const PLATES: int = 2
const PLATE_PCT: float = 0.08          # PV di ogni placca, in % dei PV massimi del boss
const PLATE_SHARE: float = 0.4         # parte del danno che finisce sulla placca finche' esiste
const PLATE_DEF: float = 0.92          # difesa del boss dopo la rottura di una placca
const PLATE_BALANCE: int = 2
const PLATE_BOOST: float = 0.08        # il potere liberato: la mossa successiva del boss e' piu' forte

# ---------- Attacchi concatenati ----------
const CHAIN_EVERY: int = 4
const CHAIN_MULT: float = 0.7
const CHAIN_EXPOSE: int = 2

# ---------- Eco ----------
const ECHO_PCT: float = 0.4

# ---------- Determinazione ----------
const RESOLVE_BELOW: float = 0.3
const RESOLVE_MULT: float = 1.15
const RESOLVE_TURNS: int = 2

# ---------- Sfide facoltative ----------
const CHALLENGES: Dictionary = {
	"nessun_caduto": {"name": "NESSUNO CADE", "desc": "Vinci senza che nessun operatore vada a terra"},
	"rottura_veloce": {"name": "BREAK LAMPO", "desc": "Rompi l'equilibrio del boss entro il round 4"},
	"senza_cariche": {"name": "TUTTO SOTTO CONTROLLO", "desc": "Vinci senza cariche non gestite"},
	"riserva_viva": {"name": "RISERVA VIVA", "desc": "Vinci con almeno 3 di Riserva rimasti"},
}
const CHALLENGE_ORDER: Array = ["nessun_caduto", "rottura_veloce", "senza_cariche", "riserva_viva"]
const CHALLENGE_COINS: int = 120

# ---------- Maestria ----------
const MASTERY_STEP: int = 25           # usi per livello
const MASTERY_MAX: int = 3
const MASTERY_BONUS: float = 0.04      # danno/effetto per livello


# Preparazione di una battaglia nuova (dopo la creazione delle unita', prima del primo round).
static func setup(state: Dictionary) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if int(state.get("tier", 0)) >= 1:
		boss["plates"] = PLATES
		boss["plate_max"] = maxi(1, int(round(float(boss["max_hp"]) * PLATE_PCT)))
		boss["plate_hp"] = int(boss["plate_max"])
	var h: int = absi(hash("%s|sfida" % str(state.get("rng_seed", ""))))
	state["challenge"] = {"id": str(CHALLENGE_ORDER[h % CHALLENGE_ORDER.size()])}
	state["echo"] = 0


static func clean_order(raw: Variant) -> String:
	var s: String = str(raw)
	return s if ORDERS.has(s) else ""


static func clean_push(raw: Variant) -> String:
	var s: String = str(raw)
	return s if PUSH.has(s) else ""


# L'ordine della maggioranza (pareggio: il primo giocatore che l'ha scelto).
static func pick_order(state: Dictionary) -> String:
	var tally: Dictionary = {}
	for p in state["players"]:
		if p["choice"] == null or not BattleState.player_alive(state, p):
			continue
		var o: String = clean_order(p["choice"].get("order", ""))
		if o != "":
			tally[o] = int(tally.get(o, 0)) + 1
	var best: int = 0
	for o in tally:
		best = maxi(best, int(tally[o]))
	if best == 0:
		return ""
	for p in state["players"]:
		if p["choice"] == null:
			continue
		var o2: String = clean_order(p["choice"].get("order", ""))
		if o2 != "" and int(tally.get(o2, 0)) == best:
			return o2
	return ""


# Inizio risoluzione: ordine di squadra e prezzi pagati. Aggiunge eventi {"t": "order"} e {"t": "push"}.
static func begin_resolution(state: Dictionary, events: Array) -> void:
	state["order"] = pick_order(state)
	var order: String = str(state["order"])
	if order != "":
		var n: int = 0
		for p in state["players"]:
			if p["choice"] != null and clean_order(p["choice"].get("order", "")) == order:
				n += 1
		events.append({"t": "order", "id": order, "n": n})
		for p in state["players"]:
			var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
			if not BattleState.is_alive(u):
				continue
			if order == "concentra":
				u["order_mult"] = FOCUS_MULT
			elif order == "proteggi":
				var sh: int = int(round(float(u["max_hp"]) * PROTECT_SHIELD))
				u["shield"] = int(u["shield"]) + sh
				events.append({"t": "shield", "src": u["id"], "dst": u["id"], "amount": sh})
	for p in state["players"]:
		if p["choice"] == null:
			continue
		var pid: String = clean_push(p["choice"].get("push", ""))
		var actor: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if pid == "" or not BattleState.is_alive(actor):
			continue
		var move: Dictionary = BattleContent.MOVES.get(str(p["choice"].get("move", "")), {})
		if not move.has("mult"):
			continue                                   # il prezzo ha senso solo su un attacco
		if pid == "proibita" and bool(actor.get("forbidden", false)):
			continue                                   # una volta a battaglia
		var def: Dictionary = PUSH[pid]
		var paid: int = mini(int(actor["hp"]) - 1, int(round(float(actor["max_hp"]) * float(def["hp"]))))
		if paid > 0:
			actor["hp"] = int(actor["hp"]) - paid
		actor["push_mult"] = float(def["mult"])
		actor["noreact_until"] = int(state["round"]) + int(def["lock"])
		if pid == "proibita":
			actor["forbidden"] = true
		events.append({"t": "push", "unit": actor["id"], "id": pid, "cost": maxi(0, paid)})


# Una reazione e' bloccata per chi ha pagato un prezzo da poco.
static func reaction_locked(state: Dictionary, p: Dictionary) -> bool:
	var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
	return not u.is_empty() and int(u.get("noreact_until", 0)) >= int(state.get("round", 1))


# Moltiplicatore di danno di chi attacca (ordine, prezzo, determinazione, maestria della mossa).
static func damage_mult(attacker: Dictionary) -> float:
	var m: float = float(attacker.get("order_mult", 1.0)) * float(attacker.get("push_mult", 1.0))
	if int(attacker.get("resolve_turns", 0)) > 0:
		m *= RESOLVE_MULT
	return m


static func mastery_mult(actor: Dictionary, move_id: String) -> float:
	return 1.0 + MASTERY_BONUS * float(clampi(int(actor.get("mastery", {}).get(move_id, 0)), 0, MASTERY_MAX))


# DETERMINAZIONE: la prima volta che un operatore scende sotto il 30% dei PV (e resta in piedi), colpisce piu' forte per 2 round.
static func on_damaged(defender: Dictionary, events: Array) -> void:
	if str(defender.get("side", "")) != "player" or bool(defender.get("resolve_used", false)):
		return
	if int(defender["hp"]) <= 0 or float(defender["hp"]) >= float(defender["max_hp"]) * RESOLVE_BELOW:
		return
	defender["resolve_used"] = true
	defender["resolve_turns"] = RESOLVE_TURNS
	events.append({"t": "resolve", "unit": defender["id"]})


# Placche: una parte del colpo finisce sulla placca. Ritorna il danno che resta per i PV del boss.
static func plate_hit(state: Dictionary, defender: Dictionary, dmg: int, pierce: int, events: Array) -> int:
	if int(defender.get("plates", 0)) <= 0 or pierce > 0 or dmg <= 1:
		return dmg
	var part: int = mini(dmg - 1, int(round(float(dmg) * PLATE_SHARE)))
	defender["plate_hp"] = int(defender["plate_hp"]) - part
	var broke: bool = int(defender["plate_hp"]) <= 0
	if broke:
		defender["plates"] = int(defender["plates"]) - 1
		defender["plate_hp"] = int(defender["plate_max"]) if int(defender["plates"]) > 0 else 0
		defender["def"] = int(round(float(defender["def"]) * PLATE_DEF))
		state["boss_boost"] = int(round(PLATE_BOOST * 100.0))      # in % (intero: lo stato resta JSON)
	events.append({"t": "plate", "hit": part, "broke": broke, "left": int(defender["plates"])})
	return dmg - part


# Il boss ha una placca liberata che potenzia la mossa successiva?
static func boss_boost(state: Dictionary) -> float:
	var b: float = float(int(state.get("boss_boost", 0))) / 100.0
	state["boss_boost"] = 0
	return 1.0 + b


# ---------- Attacchi concatenati ----------

# Annuncio: dalla fase 2, ogni CHAIN_EVERY round il boss prepara una seconda mossa.
static func roll_chain(state: Dictionary, cycle: Array) -> void:
	var tele: Dictionary = state.get("telegraph", {})
	tele.erase("chain")
	if tele.is_empty() or int(state.get("phase", 1)) < 2 or int(state.get("round", 1)) % CHAIN_EVERY != 0:
		return
	var nxt: String = str(cycle[(int(state["cycle_index"]) + 1) % cycle.size()])
	if nxt != str(tele["move"]) and BattleContent.BOSS_MOVES.has(nxt):
		tele["chain"] = nxt
	state["telegraph"] = tele


# Dopo la prima mossa: se qualcuno ha reagito la catena si spezza e il boss resta esposto; altrimenti colpisce di nuovo.
static func chain_followup(state: Dictionary, boss: Dictionary, reacted: bool, rng: RNGState, events: Array) -> void:
	var tele: Dictionary = state.get("telegraph", {})
	var nxt: String = str(tele.get("chain", ""))
	if nxt == "" or bool(state.get("in_chain", false)) or not BattleState.is_alive(boss):
		return
	if BattleState.alive_players(state).is_empty():
		return
	if reacted:
		events.append({"t": "chain", "ok": false, "move": nxt})
		BattleResolver._drain_balance(boss, CHAIN_EXPOSE, boss, events)
		return
	events.append({"t": "chain", "ok": true, "move": nxt})
	state["in_chain"] = true
	BattleResolver._boss_act(state, boss, nxt, str(tele.get("target", "")), rng, events)
	state["in_chain"] = false


# ---------- Eco ----------

# A fine round: ricorda il colpo piu' forte dato al boss (serve all'evento ECO dell'arena) e la prima rottura.
static func track(state: Dictionary, events: Array) -> void:
	var top: int = 0
	for e in events:
		if str(e.get("t", "")) == "damage" and str(e.get("dst", "")) == BattleState.BOSS_ID and str(e.get("src", "")) != BattleState.BOSS_ID:
			top = maxi(top, int(e.get("amount", 0)))
	state["echo"] = top


# Fine round: cancella i bonus temporanei, applica l'ordine RISORSE e fa scorrere la determinazione.
static func end_round(state: Dictionary, events: Array) -> void:
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		u.erase("order_mult")
		u.erase("push_mult")
		if int(u.get("resolve_turns", 0)) > 0:
			u["resolve_turns"] = int(u["resolve_turns"]) - 1
	if str(state.get("order", "")) == "risorse" and (state.get("reactions", []) as Array).is_empty() and str(state["winner"]) == "":
		BattleResolver._gain_reserve(state, 1, "order", events)
	state["order"] = ""


# ---------- Sfide facoltative ----------

static func challenge_id(state: Dictionary) -> String:
	return str(state.get("challenge", {}).get("id", ""))


# La sfida facoltativa e' riuscita? (si guarda a battaglia vinta)
static func challenge_done(state: Dictionary) -> bool:
	if str(state.get("winner", "")) != "players":
		return false
	var st: Dictionary = state.get("stats", {})
	match challenge_id(state):
		"nessun_caduto":
			return int(st.get("downs", 0)) == 0
		"rottura_veloce":
			return int(st.get("break_round", 99)) <= 4
		"senza_cariche":
			return int(st.get("unhandled", 0)) == 0
		"riserva_viva":
			return int(state.get("reserve", 0)) >= 3
	return false


static func challenge_text(state: Dictionary) -> String:
	var c: Dictionary = CHALLENGES.get(challenge_id(state), {})
	return "%s: %s" % [str(c.get("name", "")), str(c.get("desc", ""))] if not c.is_empty() else ""


# ---------- Anteprima delle sinergie ----------

# Combo che la squadra puo' davvero fare: per ogni regola, esiste una mossa con il tag richiesto in un operatore e una con il tag
# di uso in un altro? Ritorna [{id, name, a, b}] con i nomi degli operatori coinvolti.
static func possible_combos(entries: Array) -> Array:
	var tagged: Array = []
	for e in entries:
		var moves: Array = ["attack"]
		for m in e.get("skills", []):
			moves.append(str(m))
		if str(e.get("ult", "")) != "":
			moves.append(str(e["ult"]))
		var tags: Array = []
		for mid in moves:
			for t in Combos.tags_of(BattleContent.MOVES.get(str(mid), {})):
				if not tags.has(t):
					tags.append(t)
		tagged.append({"name": str(BattleContent.CHARACTERS.get(str(e.get("char", "")), {}).get("name", e.get("char", ""))), "tags": tags})
	var out: Array = []
	for r in Combos.RULES:
		var found: bool = false
		for i in tagged.size():
			for j in tagged.size():
				if i != j and (tagged[i]["tags"] as Array).has(str(r["needs"])) and (tagged[j]["tags"] as Array).has(str(r["with"])):
					out.append({"id": str(r["id"]), "name": str(r["name"]), "a": tagged[i]["name"], "b": tagged[j]["name"]})
					found = true
					break
			if found:
				break
	return out
