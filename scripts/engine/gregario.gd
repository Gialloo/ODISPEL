class_name Gregario
extends RefCounted

# SCONTRI CON DUE NEMICI: accanto al nemico principale (il "boss" del motore, units["boss"]) puo' esserci una SCHEGGIA,
# un pezzo piu' piccolo di un altro colore (units["gregario"], side "boss"). E' un'aggiunta: senza scheggia tutto resta com'era.
#  - Ha solo PV e attacco: niente equilibrio, BREAK, fasi o catene (quelle restano del nemico principale).
#  - Nel suo turno colpisce una sola volta il bersaglio annunciato a inizio round (state["telegraph2"]).
#  - Le mosse "enemy" colpiscono il bersaglio scelto: choice.target = "gregario" la colpisce, altrimenti il nemico principale.
#  - Abbatterla da' +1 Riserva. La battaglia si vince quando cade il nemico principale: la scheggia, rimasta sola, si dissolve.
# Perche' cosi': la scelta del bersaglio diventa una domanda vera (togliere i colpi in piu' o puntare al BREAK) senza
# riscrivere il motore a un solo nemico (decisione dell'autore, 02/11/2026: «scontri con due nemici»).

const ID: String = "gregario"
const HP_K: float = 0.4          # PV della scheggia rispetto al nemico principale (gia' scalato per la storia)
const ATK_K: float = 0.5         # attacco rispetto al nemico principale
const SPD_BONUS: int = 6         # un po' piu' veloce: di solito agisce prima del principale
const HIT_MULT: float = 1.0
const RESERVE_ON_DOWN: int = 1
const NAME: String = "Scheggia"


# Aggiunge la scheggia di `char_id` (un frammento_<colore> di BattleContent.BOSSES) accanto al nemico principale.
static func add(state: Dictionary, char_id: String) -> Dictionary:
	if char_id == "" or not BattleContent.BOSSES.has(char_id):
		return {}
	var main: Dictionary = BattleState.boss(state)
	var def: Dictionary = BattleContent.BOSSES[char_id]
	var stats: Dictionary = {
		"hp": maxi(1, int(round(float(main["max_hp"]) * HP_K))),
		"atk": maxi(1, int(round(float(main["atk"]) * ATK_K))),
		"def": int(def["def"]),
		"spd": int(main["spd"]) + SPD_BONUS,
	}
	var u: Dictionary = BattleState._blank_unit(ID, char_id, "boss", "", def, "gregario", stats)
	u["name"] = NAME
	u["weak2"] = ""
	u["balance_max"] = 0
	u["balance"] = 0
	u["stun"] = 0
	u["exposed"] = false
	state["units"][ID] = u
	telegraph(state)
	return u


# Dopo che il nemico principale e' stato scalato (PV e attacco della storia), la scheggia si riallinea.
static func rescale(state: Dictionary) -> void:
	var u: Dictionary = unit(state)
	if u.is_empty():
		return
	var main: Dictionary = BattleState.boss(state)
	u["max_hp"] = maxi(1, int(round(float(main["max_hp"]) * HP_K)))
	u["hp"] = u["max_hp"]
	u["atk"] = maxi(1, int(round(float(main["atk"]) * ATK_K)))


static func unit(state: Dictionary) -> Dictionary:
	return state["units"].get(ID, {})


static func present(state: Dictionary) -> bool:
	return state["units"].has(ID)


static func alive(state: Dictionary) -> bool:
	return BattleState.is_alive(unit(state))


static func is_enemy(state: Dictionary, uid: String) -> bool:
	return str(state["units"].get(uid, {}).get("side", "")) == "boss"


# Il nemico colpito da una mossa "enemy": la scheggia solo se scelta e ancora in piedi.
static func target_unit(state: Dictionary, target: String) -> Dictionary:
	if target == ID and alive(state):
		return unit(state)
	return BattleState.boss(state)


# A inizio round la scheggia annuncia chi colpira'. E' una PREDATRICE (EnemyArchetypes, Review 01 del game director): punta
# chi in campo ha meno PV in proporzione, cosi' la domanda e' vera (abbatterla prima o proteggere il ferito); a parita' a caso.
# Prima sceglieva a caso tra chi era in piedi: la priorita' non si poteva leggere.
static func telegraph(state: Dictionary) -> void:
	if not alive(state):
		state.erase("telegraph2")
		return
	var list: Array = BattleState.alive_players(state)
	if list.is_empty():
		state.erase("telegraph2")
		return
	var low: float = INF
	var prey: Array = []
	for p in list:
		var au: Dictionary = BattleState.unit(state, str(p.get("active", "")))
		var r: float = float(au.get("hp", 1)) / maxf(1.0, float(au.get("max_hp", 1))) if not au.is_empty() else 1.0
		if r < low - 0.001:
			low = r
			prey = [p]
		elif absf(r - low) <= 0.001:
			prey.append(p)
	var rng: RNGState = BattleResolver._load_rng(state)
	var target: String = str(prey[rng.random_index(prey.size())]["id"])
	BattleResolver._save_rng(state, rng)
	state["telegraph2"] = {"move": "scheggia", "target": target}


# Il turno della scheggia: un colpo sul bersaglio annunciato (se e' caduto, su un altro in piedi).
static func act(state: Dictionary, events: Array) -> void:
	var u: Dictionary = unit(state)
	if not BattleState.is_alive(u) or str(state["winner"]) != "":
		return
	var pid: String = str(state.get("telegraph2", {}).get("target", ""))
	var t: Dictionary = BattleState.active_unit(state, pid) if pid != "" else {}
	if not BattleState.is_alive(t):
		t = {}
		for p in BattleState.alive_players(state):
			var cand: Dictionary = BattleState.active_unit(state, str(p["id"]))
			if BattleState.is_alive(cand):
				t = cand
				break
	if t.is_empty():
		return
	events.append({"t": "gregario_act", "unit": ID, "dst": str(t["id"])})
	BattleResolver._hit(state, u, t, HIT_MULT, events)


# Dopo un'azione: se la scheggia e' appena caduta, +1 Riserva (una volta sola).
static func after_events(state: Dictionary, events: Array) -> void:
	var u: Dictionary = unit(state)
	if u.is_empty() or bool(u.get("rewarded", false)) or BattleState.is_alive(u):
		return
	for e in events:
		if str(e.get("t", "")) == "down" and str(e.get("unit", "")) == ID:
			u["rewarded"] = true
			BattleResolver._gain_reserve(state, RESERVE_ON_DOWN, "gregario", events)
			return


# IA (AUTO): chi colpisce sceglie il bersaglio. Le Ultimate e chi ha il colore vincente sul principale vanno sul principale,
# cosi' anche il nemico rotto (BREAK); chi e' forte sulla scheggia la toglie di mezzo; altrimenti si toglie prima la scheggia.
static func with_target(state: Dictionary, pid: String, choice: Dictionary) -> Dictionary:
	if not alive(state) or choice.is_empty():
		return choice
	var mv: Dictionary = BattleContent.MOVES.get(str(choice.get("move", "")), {})
	if str(mv.get("target", "")) != "enemy" or str(choice.get("target", "")) != "":
		return choice
	var me: Dictionary = BattleState.active_unit(state, pid)
	var main: Dictionary = BattleState.boss(state)
	var g: Dictionary = unit(state)
	var pick: String = ID
	if str(mv.get("kind", "")) == "ult" or int(main.get("stun", 0)) > 0:
		pick = ""
	elif BattleTypes.color_multiplier(str(me.get("color", "")), str(main.get("color", ""))) > 1.0 \
		and BattleTypes.color_multiplier(str(me.get("color", "")), str(g.get("color", ""))) <= 1.0:
		pick = ""
	var out: Dictionary = choice.duplicate()
	out["target"] = pick
	return out
