class_name Combos
extends RefCounted

# COMBO MODULARI: nessuna combo ha un'animazione sua. Ogni mossa ha dei TAG (ricavati da cio' che fa),
# le REGOLE dicono quale tag, usato da un compagno prima di te nello stesso round, si combina con quale tuo tag,
# e che effetto (danno, rottura, ultimate) e che preset visivo producono. Aggiungere una combo = aggiungere una riga.
#
# Tag: ATTACK (fa danno al boss) · HEAVY (colpo pesante o ultimate) · MARK (marchia) · DEBUFF (abbassa una statistica del boss)
#      SUPPORT (scudo o cura) · TAUNT (provoca) · MULTI (piu' colpi) · PIERCE (ignora difesa) · CLEANSE · ULT

# needs: tag che un altro operatore ha messo in campo prima di te (o che e' gia' sul boss); with: tag della tua mossa.
# mult: danno x · gauge: ultimate al tuo operatore (e meta' al compagno) · brk: punti di equilibrio tolti al boss in piu'
# fx: preset visivo (vedi ComboFx) · col: colore.
const RULES: Array = [
	{"id": "copertura", "name": "COPERTURA", "needs": "SUPPORT", "with": "ATTACK", "mult": 1.12, "gauge": 0, "brk": 0, "fx": "aura", "col": "#7cf0ff",
		"desc": "un compagno ha scudato o curato prima di te"},
	{"id": "traccia", "name": "TRACCIA", "needs": "MARK", "with": "ATTACK", "mult": 1.0, "gauge": 10, "brk": 0, "fx": "chain", "col": "#ffd25f",
		"desc": "il boss e' marchiato da un compagno"},
	{"id": "detonazione", "name": "DETONAZIONE", "needs": "MARK", "with": "HEAVY", "mult": 1.15, "gauge": 0, "brk": 2, "fx": "burst", "col": "#ff6b4a",
		"desc": "colpo pesante su un boss marchiato da un altro"},
	{"id": "frattura", "name": "FRATTURA", "needs": "DEBUFF", "with": "HEAVY", "mult": 1.15, "gauge": 0, "brk": 2, "fx": "shatter", "col": "#b07bff",
		"desc": "colpo pesante dopo che un compagno ha indebolito il boss"},
	{"id": "assedio", "name": "ASSEDIO", "needs": "TAUNT", "with": "ATTACK", "mult": 1.08, "gauge": 5, "brk": 0, "fx": "lock", "col": "#ff9a4a",
		"desc": "un compagno attira il boss mentre tu colpisci"},
	{"id": "raffica", "name": "RAFFICA", "needs": "ATTACK", "with": "PIERCE", "mult": 1.1, "gauge": 0, "brk": 1, "fx": "volley", "col": "#6bffb0",
		"desc": "colpo perforante subito dopo un attacco di un compagno"},
]

# Ogni combo oltre la prima nello stesso round aggiunge questo al danno (tetto 3 anelli).
const CHAIN_BONUS: float = 0.05
const CHAIN_MAX: int = 3


static func rule(id: String) -> Dictionary:
	for r in RULES:
		if str(r["id"]) == id:
			return r
	return {}


# Tag di una mossa, ricavati da come e' fatta (cosi' ogni mossa nuova e' gia' compatibile).
static func tags_of(move: Dictionary) -> Array:
	var t: Array = []
	if move.is_empty():
		return t
	var hits_enemy: bool = move.has("mult") and str(move.get("target", "")) == "enemy"
	if hits_enemy:
		t.append("ATTACK")
		if float(move["mult"]) >= 2.0 or str(move.get("kind", "")) == "ult":
			t.append("HEAVY")
		if int(move.get("hits", 1)) > 1:
			t.append("MULTI")
		if int(move.get("pierce", 0)) > 0:
			t.append("PIERCE")
	if move.has("status") and move["status"].has("mark"):
		t.append("MARK")
	if move.has("debuff"):
		t.append("DEBUFF")
	if move.has("shield") or move.has("heal"):
		if not hits_enemy:
			t.append("SUPPORT")
	if move.has("self_status") and move["self_status"].has("taunt"):
		t.append("TAUNT")
	if move.has("cleanse"):
		t.append("CLEANSE")
	if str(move.get("kind", "")) == "ult":
		t.append("ULT")
	return t


# Registra cio' che ha fatto un operatore (per le combo dei compagni piu' lenti).
static func record(state: Dictionary, actor: Dictionary, move: Dictionary) -> void:
	var list: Array = state.get("tags", [])
	list.append({"unit": str(actor["id"]), "tags": tags_of(move)})
	state["tags"] = list


# Combo attive per questo colpo: lista di regole (in ordine). Non modifica lo stato.
static func matching(state: Dictionary, actor: Dictionary, boss: Dictionary, my_tags: Array) -> Array:
	var seen: Array = []
	for entry in state.get("tags", []):
		if str(entry["unit"]) != str(actor["id"]) and BattleState.is_alive(BattleState.unit(state, str(entry["unit"]))):
			seen.append(entry)
	var mb: String = str(boss.get("marked_by", ""))
	if Marks.count(boss) > 0 and mb != "" and mb != str(actor["id"]) and BattleState.is_alive(BattleState.unit(state, mb)):
		seen.append({"unit": mb, "tags": ["MARK"]})
	var out: Array = []
	for r in RULES:
		if not my_tags.has(str(r["with"])):
			continue
		for entry in seen:
			if entry["tags"].has(str(r["needs"])):
				out.append({"rule": r, "with": str(entry["unit"])})
				break
	return out


# Testo per le regole del gioco, generato dalle regole stesse (cosi' non resta mai indietro).
static func describe_all() -> String:
	var parts: Array = []
	for r in RULES:
		var fx: Array = []
		if float(r["mult"]) > 1.0:
			fx.append("+%d%% danno" % int(round((float(r["mult"]) - 1.0) * 100.0)))
		if int(r["gauge"]) > 0:
			fx.append("+%d ULT" % int(r["gauge"]))
		if int(r["brk"]) > 0:
			fx.append("-%d equilibrio" % int(r["brk"]))
		parts.append("%s (%s): %s." % [str(r["name"]), ", ".join(fx), str(r["desc"])])
	return "Un compagno che agisce PRIMA di te prepara, tu chiudi. " + " ".join(parts) + " Ogni combo in piu' nello stesso round aggiunge +%d%% e la scena diventa piu' spettacolare." % int(round(CHAIN_BONUS * 100.0))
