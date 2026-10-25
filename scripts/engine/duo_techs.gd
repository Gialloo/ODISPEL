class_name DuoTechs
extends RefCounted

# TECNICHE COMBINATE (Fase 5, alla Chrono Trigger): due personaggi fanno una cosa insieme.
# Si sceglie dal menu ABILITA' di uno dei due. Costa energia a entrambi e il compagno ci mette il suo turno:
# si puo' fare solo se il compagno e' in campo e non ha ancora agito in questo round (poi salta il suo turno).
# Non e' un bonus in percento: e' un'azione diversa, con un effetto che nessuno dei due fa da solo.
const COST: int = 2

# a / b = personaggi (id del codice: ferri = Lance, zecca = Rio). hits: [chi colpisce, moltiplicatore].
const DUOS: Dictionary = {
	"duo_ferri_nox": {"name": "Turno di notte", "a": "ferri", "b": "nox",
		"desc": "Lance fa da muro e Nox passa col thermos: scudo del 25% e cura del 20% a tutta la squadra.",
		"team_shield": 0.25, "team_heal": 0.20, "icon": "guard"},
	"duo_ferri_zecca": {"name": "Primo piano", "a": "ferri", "b": "zecca",
		"desc": "Rio inquadra, Lance colpisce in primo piano: colpo pesante di Lance, uno di Rio e +25 Hype.",
		"hits": [["ferri", 2.4], ["zecca", 1.1]], "hype": 25, "icon": "attack"},
	"duo_ferri_saul": {"name": "Scorta", "a": "ferri", "b": "saul",
		"desc": "Lance apre la strada, Saul passa dietro: due colpi e -10 equilibrio al nemico.",
		"hits": [["ferri", 1.4], ["saul", 1.6]], "balance": 10, "icon": "attack"},
	"duo_nox_zecca": {"name": "Fuori onda", "a": "nox", "b": "zecca",
		"desc": "Rio stacca la diretta e Nox rimette in piedi tutti: cura del 30% e +1 energia a tutta la squadra.",
		"team_heal": 0.30, "team_energy": 1, "icon": "guard"},
	"duo_nox_saul": {"name": "Caffè corretto", "a": "nox", "b": "saul",
		"desc": "Nox distrae, Saul sfila: lo scudo del nemico passa alla squadra e i due colpiscono.",
		"hits": [["saul", 1.3], ["nox", 1.0]], "steal_shield": true, "icon": "attack"},
	"duo_saul_zecca": {"name": "Gioco di prestigio", "a": "saul", "b": "zecca",
		"desc": "Saul fa sparire la carta, Rio la riprende: due colpi, -5 equilibrio e +15 Hype.",
		"hits": [["saul", 1.7], ["zecca", 1.4]], "balance": 5, "hype": 15, "icon": "attack"},
}


# Le mosse da aggiungere a BattleContent.MOVES (kind "duo": fuori dalle abilita' equipaggiabili).
static func moves() -> Dictionary:
	var out: Dictionary = {}
	for id in DUOS:
		var d: Dictionary = DUOS[id]
		out[id] = {"name": str(d["name"]), "kind": "duo", "cost": COST, "priority": 0, "rarity": 0,
			"target": "allies" if str(d["icon"]) == "guard" else "enemy", "desc": str(d["desc"]), "duo": true}
		if d.has("hits"):
			out[id]["mult"] = float(d["hits"][0][1])
	return out


static func partner_char(duo_id: String, char_id: String) -> String:
	var d: Dictionary = DUOS.get(duo_id, {})
	if str(d.get("a", "")) == char_id:
		return str(d.get("b", ""))
	if str(d.get("b", "")) == char_id:
		return str(d.get("a", ""))
	return ""


# Le tecniche di questo personaggio (con qualunque compagno della squadra).
static func of_char(char_id: String) -> Array:
	var out: Array = []
	for id in DUOS:
		if partner_char(str(id), char_id) != "":
			out.append(str(id))
	return out


# Il compagno in campo (unita' attiva di un altro slot) col personaggio giusto.
static func partner(state: Dictionary, actor: Dictionary, duo_id: String) -> Dictionary:
	var want: String = partner_char(duo_id, str(actor.get("char", "")))
	if want == "":
		return {}
	for p in BattleState.alive_players(state):
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if BattleState.is_alive(u) and str(u["id"]) != str(actor["id"]) and str(u.get("char", "")) == want:
			return u
	return {}


static func spent(state: Dictionary, uid: String) -> bool:
	return state.has("seq") and (state["seq"].get("spent", {}) as Dictionary).has(uid)


# "" se si puo' fare, altrimenti perche' no (testo per il menu).
static func error(state: Dictionary, actor: Dictionary, duo_id: String) -> String:
	if not DUOS.has(duo_id):
		return "tecnica sconosciuta"
	var mate: Dictionary = partner(state, actor, duo_id)
	if mate.is_empty():
		return "%s non è in campo" % _who(partner_char(duo_id, str(actor.get("char", ""))))
	if (state.get("acts", {}) as Dictionary).has(str(mate["id"])) or spent(state, str(mate["id"])):
		return "%s ha già agito in questo round" % _who(str(mate["char"]))
	if int(actor["energy"]) < COST or int(mate["energy"]) < COST:
		return "Servono %d EN a tutti e due" % COST
	return ""


static func _who(char_id: String) -> String:
	return {"ferri": "Lance", "zecca": "Rio", "nox": "Nox", "saul": "Saul"}.get(char_id, char_id.capitalize())


static func _unit_of_char(actor: Dictionary, mate: Dictionary, char_id: String) -> Dictionary:
	return actor if str(actor.get("char", "")) == char_id else mate


# Esegue la tecnica. Eventi: {"t": "duo", "id", "name", "unit", "with"} piu' danni, scudi, cure.
static func run(state: Dictionary, actor: Dictionary, duo_id: String, events: Array) -> void:
	var d: Dictionary = DUOS[duo_id]
	var mate: Dictionary = partner(state, actor, duo_id)
	if mate.is_empty():
		return
	actor["energy"] = int(actor["energy"]) - COST
	mate["energy"] = int(mate["energy"]) - COST
	var sp: Dictionary = state["seq"].get("spent", {})
	sp[str(mate["id"])] = true
	state["seq"]["spent"] = sp
	var acts: Dictionary = state.get("acts", {})
	acts[str(actor["id"])] = duo_id
	acts[str(mate["id"])] = duo_id
	state["acts"] = acts
	events.append({"t": "act", "unit": actor["id"], "move": duo_id})      # chi la lancia si muove come per un'abilita'
	events.append({"t": "duo", "id": duo_id, "name": str(d["name"]), "unit": actor["id"], "with": mate["id"]})
	var boss: Dictionary = BattleState.boss(state)
	if bool(d.get("steal_shield", false)) and int(boss.get("shield", 0)) > 0:
		var loot: int = int(boss["shield"])
		boss["shield"] = 0
		var mates: Array = []
		for p in BattleState.alive_players(state):
			var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
			if BattleState.is_alive(u):
				mates.append(u)
		var share: int = maxi(1, int(ceil(float(loot) / float(maxi(1, mates.size())))))
		for u in mates:
			u["shield"] = int(u["shield"]) + share
			events.append({"t": "shield", "src": actor["id"], "dst": u["id"], "amount": share})
	for h in d.get("hits", []):
		if not BattleState.is_alive(boss):
			break
		BattleResolver._hit(state, _unit_of_char(actor, mate, str(h[0])), boss, float(h[1]), events)
	if int(d.get("balance", 0)) > 0 and BattleState.is_alive(boss):
		BattleResolver._drain_balance(boss, int(d["balance"]), actor, events)
	for p in BattleState.alive_players(state):
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if not BattleState.is_alive(u):
			continue
		if float(d.get("team_shield", 0.0)) > 0.0:
			var sh: int = int(round(float(u["max_hp"]) * float(d["team_shield"])))
			u["shield"] = int(u["shield"]) + sh
			events.append({"t": "shield", "src": actor["id"], "dst": u["id"], "amount": sh})
		if float(d.get("team_heal", 0.0)) > 0.0:
			var got: int = mini(int(u["max_hp"]) - int(u["hp"]), int(round(float(u["max_hp"]) * float(d["team_heal"]))))
			if got > 0:
				u["hp"] = int(u["hp"]) + got
				events.append({"t": "heal", "src": actor["id"], "dst": u["id"], "amount": got})
		if int(d.get("team_energy", 0)) > 0:
			u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + int(d["team_energy"]))
	if str(d["icon"]) == "guard":
		state["duo_support_round"] = int(state.get("round", 0))
	if int(d.get("hype", 0)) > 0:
		Kits.add_hype(_unit_of_char(actor, mate, "zecca"), int(d["hype"]), events, "duo")
	BattleResolver._check_winner(state, events)


# IA: la tecnica giusta al momento giusto. Di supporto se qualcuno e' sotto il 35% (una ogni tre round), d'attacco a nemico rotto.
static func ai_pick(state: Dictionary, actor: Dictionary) -> String:
	var hurt: bool = false
	for p in BattleState.alive_players(state):
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if BattleState.is_alive(u) and float(u["hp"]) < float(u["max_hp"]) * 0.35:
			hurt = true
	var boss: Dictionary = BattleState.boss(state)
	var broken: bool = int(boss.get("stun", 0)) > 0
	var cured: bool = int(state.get("duo_support_round", -9)) >= int(state.get("round", 0)) - 3   # l'IA non spreca due turni a curare ogni round
	for id in of_char(str(actor.get("char", ""))):
		if error(state, actor, str(id)) != "":
			continue
		var support: bool = str(DUOS[id]["icon"]) == "guard"
		var mate: Dictionary = partner(state, actor, str(id))
		if not support and maxi(int(actor.get("gauge", 0)), int(mate.get("gauge", 0))) >= BattleTypes.GAUGE_MAX:
			continue    # con un'Ultimate pronta l'IA tira quella
		if (support and hurt and not cured) or (not support and broken):
			return str(id)
	return ""
