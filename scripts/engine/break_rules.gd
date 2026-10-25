class_name BreakRules
extends RefCounted

# STRADE VERSO IL BREAK (Fase 3 del piano): ogni boss dell'atto si rompe in un modo suo, oltre al colore vincente.
# Il moltiplicatore vale solo per l'equilibrio tolto dai colpi (_chip_balance), mai per il danno.
#   charge  · Semaforo: rompilo mentre carica (colpo pesante annunciato)
#   call    · Cabina: chi e' "chiamato" (bersaglio annunciato) toglie il doppio
#   mirror  · Manichino: cambia tipo di mossa rispetto al compagno prima, o ti copia
#   open    · Cassaforte: colpiscila quando non ha lo scudo, prima che si chiuda
#   punish  · Autovelox: dopo una parata perfetta il colpo dopo toglie il doppio
# Nemici minori (frammenti): condizioni speciali, vedi MINOR.
const RULES: Dictionary = {
	"semaforo": {"rule": "charge", "name": "ROSSO FISSO", "short": "equilibrio x2 mentre carica", "hint": "Rompilo mentre carica: equilibrio x2 durante il colpo annunciato"},
	"cabina": {"rule": "call", "name": "LA CHIAMATA", "short": "chi è nel mirino: equilibrio x2", "hint": "Rispondi alla chiamata: chi è nel mirino toglie il doppio di equilibrio"},
	"manichino": {"rule": "mirror", "name": "LO SPECCHIO", "short": "cambia tipo di mossa: x1,5", "hint": "Non farti copiare: cambia tipo di mossa rispetto al compagno prima (x1,5, uguale x0,5)"},
	"cassaforte": {"rule": "open", "name": "LA COMBINAZIONE", "short": "senza scudo x1,5, con x0,5", "hint": "Colpiscila aperta: senza scudo equilibrio x1,5, con lo scudo x0,5"},
	"autovelox": {"rule": "punish", "name": "IL VERBALE", "short": "dopo la parata perfetta: x2", "hint": "Punisci dopo la parata perfetta: il colpo dopo toglie il doppio di equilibrio"},
}
const MINOR: Dictionary = {
	"frammento_rosso": {"rule": "armor", "name": "CORAZZA", "short": "solo il colore vincente", "hint": "Corazzato: solo il colore vincente fa danno pieno (gli altri metà)"},
	"frammento_verde": {"rule": "regen", "name": "RADICI", "short": "ricresce finché non lo rompi", "hint": "Ricresce: a fine round recupera PV, finché non lo rompi"},
	"frammento_blu": {"rule": "swift", "name": "SCATTO", "short": "veloce ma si rompe in fretta", "hint": "Veloce: agisce prima e colpisce spesso, ma si rompe in fretta"},
}
const PHASE2_CHARGE: float = 1.5     # dalla fase 2 tutti i boss: rompilo mentre carica (la fase cambia la domanda)
const MINOR_REGEN: float = 0.05
const SWIFT_BALANCE: float = 1.5


static func of(boss: Dictionary) -> Dictionary:
	var id: String = str(boss.get("char", ""))
	return RULES.get(id, MINOR.get(id, {}))


static func rule(boss: Dictionary) -> String:
	return str(of(boss).get("rule", ""))


static func _charging(state: Dictionary, boss: Dictionary) -> bool:
	var bm: Dictionary = BattleContent.BOSS_MOVES.get(str(state.get("telegraph", {}).get("move", "")), {})
	return not bm.is_empty() and int(boss.get("stun", 0)) == 0 and BattleResolver.is_heavy_boss_move(bm)


# Moltiplicatore dell'equilibrio per questo colpo. Consuma l'apertura dell'Autovelox.
static func balance_mult(state: Dictionary, boss: Dictionary, attacker: Dictionary) -> float:
	var m: float = 1.0
	match rule(boss):
		"charge":
			if _charging(state, boss):
				m = 2.0
		"call":
			if str(state.get("telegraph", {}).get("target", "")) == BattleState.slot_of(state, str(attacker["id"])):
				m = 2.0
		"mirror":
			m = float(boss.get("mirror_mult", 1.0))
		"open":
			m = 0.5 if int(boss.get("shield", 0)) > 0 else 1.5
		"punish":
			if bool(boss.get("opened", false)):
				boss["opened"] = false
				m = 2.0
		"swift":
			m = SWIFT_BALANCE
	if int(state.get("phase", 1)) >= 2 and _charging(state, boss):
		m = maxf(m, PHASE2_CHARGE)
	return m


# Danno: solo la Corazza del frammento rosso lo cambia.
static func dmg_mult(boss: Dictionary, attacker: Dictionary) -> float:
	if rule(boss) == "armor" and BattleTypes.color_multiplier(str(attacker["color"]), str(boss["color"])) <= 1.0:
		return 0.5
	return 1.0


# Una volta per azione, prima dei colpi: il Manichino confronta il tipo di mossa con quello del compagno prima.
static func on_act(state: Dictionary, actor: Dictionary, cat: String) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if rule(boss) != "mirror":
		return
	var prev: String = str(state.get("mirror_prev", ""))
	boss["mirror_mult"] = 1.0 if prev == "" else (0.5 if prev == cat else 1.5)
	state["mirror_prev"] = cat


static func on_perfect(state: Dictionary) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if rule(boss) == "punish":
		boss["opened"] = true


# Fine round: le Radici del frammento verde.
static func round_end(state: Dictionary, events: Array) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if rule(boss) != "regen" or not BattleState.is_alive(boss) or int(boss.get("stun", 0)) > 0 or bool(boss.get("exposed", false)):
		return
	var heal: int = mini(int(boss["max_hp"]) - int(boss["hp"]), int(round(float(boss["max_hp"]) * MINOR_REGEN)))
	if heal > 0:
		boss["hp"] = int(boss["hp"]) + heal
		events.append({"t": "heal", "src": boss["id"], "dst": boss["id"], "amount": heal})


static func hint(state: Dictionary) -> String:
	var boss: Dictionary = BattleState.boss(state)
	var r: Dictionary = of(boss)
	if int(state.get("phase", 1)) >= 2 and _charging(state, boss) and str(r.get("rule", "")) != "charge":
		return "CARICA IN CORSO: dalla fase 2 rompilo adesso, equilibrio x1,5"
	return "" if r.is_empty() else "%s · %s" % [str(r["name"]), str(r["hint"])]
