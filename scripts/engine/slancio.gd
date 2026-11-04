class_name Slancio
extends RefCounted

# SLANCIO PER PERSONAGGIO (Fase 2 del combattimento, handoff 5).
# Chi colpisce una debolezza compatibile ottiene SLANCIO: subito dopo un'azione rapida (solo ATTACCO o GUARDIA), che non e'
# il turno ordinario e costa +15 sul recupero gia' fissato (TL_SLANCIO_EXTRA, in BattleFlow).
#  - Una volta per round PER PERSONAGGIO (nel 0.52 era una volta per round per tutta la squadra): ogni eroe ha il suo.
#  - Debolezza compatibile = colore vincente sulla ruota oppure secondo punto debole (weak2), sul boss e sulla Scheggia.
#    Le debolezze multiple dello stesso colpo non danno un secondo SLANCIO.
#  - Si ripristina solo a inizio round (lo stato del round sta in state["seq"], che SeqRound.begin rifa' a ogni round):
#    cioe' quando tutti e quattro hanno fatto il turno ordinario (4.1, 5.4).
#  - KO e rianimazione non lo toccano: lo stato e' per unita' e il KO non lo azzera (5.5).
#  - SLANCIO PROTETTO (5.6): se il bersaglio non si puo' colpire per un impedimento obbligatorio (blocked), lo SLANCIO si
#    conserva (al massimo uno per eroe, anche attraverso KO e round) e si usa appena il bersaglio torna vulnerabile; la prima
#    protezione toglie una volta il +15. Se il bersaglio viene sconfitto, decade. Oggi nessun boss ha impedimenti dichiarati:
#    li porta la scheda boss della Fase 5 (campo "invuln" o "phase_shift" sull'unita'). Il motore e' pronto.
#
# Eventi: {"t": "slancio", "unit", "player", "dst", "why"} ("why" = "colore" o "weak2": il perche' per la UI, Fase 6);
#         {"t": "slancio_kept", "unit", "player", "dst"} quando lo SLANCIO viene protetto.


# Una sola regola di «colpo alla debolezza» per motore e UI: "colore" (ruota), "weak2" (secondo punto debole) o "".
static func weak_kind(attacker: Dictionary, defender: Dictionary) -> String:
	if attacker.is_empty() or defender.is_empty():
		return ""
	if BattleTypes.color_multiplier(str(attacker.get("color", "")), str(defender.get("color", ""))) > 1.0:
		return "colore"
	if BattleTypes.hits_weak2(attacker, defender):
		return "weak2"
	return ""


static func weak_hit(attacker: Dictionary, defender: Dictionary) -> bool:
	return weak_kind(attacker, defender) != ""


# Il bersaglio ha un impedimento obbligatorio (invulnerabile, in transizione di fase)? Dichiarato dalla scheda boss (Fase 5).
static func blocked(unit: Dictionary) -> bool:
	return int(unit.get("invuln", 0)) > 0 or bool(unit.get("phase_shift", false))


# Lo SLANCIO di questo eroe e' gia' stato preso in questo round?
static func used(state: Dictionary, uid: String) -> bool:
	return state.has("seq") and bool((state["seq"].get("slancio_by", {}) as Dictionary).get(uid, false))


static func kept(state: Dictionary) -> Dictionary:
	if not state.has("slancio_kept"):
		state["slancio_kept"] = {}
	return state["slancio_kept"]


# Dopo l'azione ordinaria di `actor`: se ha colpito una debolezza compatibile e il suo SLANCIO del round e' libero, lo ottiene.
static func check(state: Dictionary, actor: Dictionary, events: Array) -> void:
	if not BattleTypes.SLANCIO_ON or str(state["winner"]) != "" or not state.has("seq") or not BattleState.is_alive(actor):
		return
	var uid: String = str(actor["id"])
	if used(state, uid):
		return
	for e in events:
		if str(e.get("t", "")) != "damage" or str(e.get("src", "")) != uid or int(e.get("amount", 0)) <= 0:
			continue
		var dst: String = str(e.get("dst", ""))
		if not _enemy_ok(state, dst):
			continue
		var tgt: Dictionary = BattleState.unit(state, dst)
		var why: String = weak_kind(actor, tgt)
		if why == "":
			continue
		if not state["seq"].has("slancio_by"):
			state["seq"]["slancio_by"] = {}
		state["seq"]["slancio_by"][uid] = true
		var pid: String = BattleState.slot_of(state, uid)
		if blocked(tgt):
			var k: Dictionary = kept(state)
			if not k.has(uid):     # al massimo uno SLANCIO protetto per eroe: non si accumula
				k[uid] = {"player": pid, "dst": dst, "waive": true}
				events.append({"t": "slancio_kept", "unit": uid, "player": pid, "dst": dst})
			return
		events.append({"t": "slancio", "unit": uid, "player": pid, "dst": dst, "why": why})
		return


# SLANCI protetti pronti adesso (il bersaglio e' tornato vulnerabile), nell'ordine dato. Toglie quelli il cui bersaglio e'
# stato sconfitto (decadono, non passano a un altro). Chi e' KO adesso aspetta: lo conserva (5.6).
static func ready_kept(state: Dictionary) -> Array:
	var out: Array = []
	if not state.has("slancio_kept") or str(state["winner"]) != "":
		return out
	var k: Dictionary = state["slancio_kept"]
	for uid in k.keys():
		var tgt: Dictionary = BattleState.unit(state, str(k[uid]["dst"]))
		if tgt.is_empty() or not BattleState.is_alive(tgt):
			k.erase(uid)
			continue
		var u: Dictionary = BattleState.unit(state, str(uid))
		if blocked(tgt) or not BattleState.is_alive(u):
			continue
		out.append(str(uid))
	return out


# Consuma lo SLANCIO protetto di `uid` e ritorna la voce dell'azione rapida (vuota se non c'e').
static func take_kept(state: Dictionary, uid: String) -> Dictionary:
	var k: Dictionary = kept(state)
	if not k.has(uid):
		return {}
	var x: Dictionary = k[uid]
	k.erase(uid)
	return {"unit": uid, "player": str(x["player"]), "boss": false, "spd": -1, "extra": true, "quick": true, "slancio": true, "kept": true, "waive": bool(x.get("waive", false))}


static func _enemy_ok(state: Dictionary, dst: String) -> bool:
	if dst == BattleState.BOSS_ID:
		return true
	return dst == Gregario.ID and BattleTypes.SLANCIO_GREG
