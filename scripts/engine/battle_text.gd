class_name BattleText
extends RefCounted

# Testi in italiano per l'interfaccia e applicazione degli eventi a una copia
# "mostrata" dello stato, cosi' la grafica puo' riprodurre un round passo passo.

const STATUS_NAMES: Dictionary = {
	"guard": "GUARDIA",
	"taunt": "PROVOCA",
	"bleed": "SANGUINA",
	"mark": "MARCHIO",
	"hidden": "NASCOSTO",
	"ronda": "RONDA",
}


# Numero breve per i fumetti: 12345 resta com'e', da 100000 in su diventa 123K, 1.2M, 3.4B (non esce mai dallo schermo).
static func num(n: int) -> String:
	var a: int = absi(n)
	if a < 100000:
		return str(n)
	var sign: String = "-" if n < 0 else ""
	if a < 1000000:
		return "%s%dK" % [sign, a / 1000]
	if a < 1000000000:
		return "%s%.1fM" % [sign, float(a) / 1000000.0]
	if a < 1000000000000:
		return "%s%.1fB" % [sign, float(a) / 1000000000.0]
	return "%s%.1fT" % [sign, float(a) / 1000000000000.0]


static func move_name(move_id: String) -> String:
	if BattleContent.MOVES.has(move_id):
		return str(BattleContent.MOVES[move_id]["name"]).to_upper()
	if BattleContent.BOSS_MOVES.has(move_id):
		return str(BattleContent.BOSS_MOVES[move_id]["name"]).to_upper()
	return move_id.to_upper()


static func status_name(status_id: String) -> String:
	return str(STATUS_NAMES.get(status_id, status_id.to_upper()))


static func unit_name(state: Dictionary, uid: String) -> String:
	var u: Dictionary = BattleState.unit(state, uid)
	return str(u.get("name", uid)).to_upper()


# Descrizione breve di una mossa del giocatore (per i suggerimenti dei pulsanti).
static func _pct_text(v: float) -> String:
	return "%d" % int(v) if is_equal_approx(v, round(v)) else "%.1f" % v


static func move_hint(move_id: String) -> String:
	var m: Dictionary = BattleContent.MOVES.get(move_id, {})
	var parts: Array = []
	if m.has("mult"):
		parts.append("DANNO x%.1f" % float(m["mult"]))
	if m.has("heal"):
		parts.append("CURA x%.1f" % float(m["heal"]))
	if m.has("shield"):
		parts.append("SCUDO x%.1f" % float(m["shield"]))
	if m.has("bonus"):
		parts.append("+%s%% %s" % [_pct_text(float(m["bonus"]["pct"])), str(BattleContent.STAT_NAMES.get(m["bonus"]["stat"], ""))])
	if m.has("status"):
		for s in m["status"]:
			parts.append(status_name(str(s)))
	if m.has("self_status"):
		for s in m["self_status"]:
			parts.append(status_name(str(s)))
	if bool(m.get("cleanse", false)):
		parts.append("PURIFICA")
	if int(m.get("ammo", 0)) > 0:
		parts.append("MUN -%d" % int(m["ammo"]))
	if int(m.get("ammo_gain", 0)) > 0:
		parts.append("MUN +%d" % int(m["ammo_gain"]))
	if int(m.get("pierce", 0)) > 0:
		parts.append("PERFORA")
	if int(m.get("priority", 0)) > 0:
		parts.append("PRIORITA'")
	return " · ".join(parts)


# Una riga di log per un evento. kind: info | hit | heal | boss | down | end
static func describe(state: Dictionary, e: Dictionary) -> Dictionary:
	match str(e.get("t", "")):
		"swap":
			return {"text": "%s ENTRA IN CAMPO" % unit_name(state, str(e["to"])), "kind": "info"}
		"act":
			return {"text": "%s » %s" % [unit_name(state, str(e["unit"])), move_name(str(e["move"]))], "kind": "info"}
		"boss_move":
			var boss: Dictionary = BattleState.boss(state)
			return {"text": "%s » %s" % [str(boss["name"]).to_upper(), move_name(str(e["move"]))], "kind": "boss"}
		"damage":
			var extra: String = ""
			if int(e.get("absorbed", 0)) > 0:
				extra = " +S%d" % int(e["absorbed"])
			return {"text": "%s → %s [-%d%s]" % [unit_name(state, str(e["src"])), unit_name(state, str(e["dst"])), int(e["amount"]), extra], "kind": "hit"}
		"heal":
			return {"text": "%s RECUPERA %d PV" % [unit_name(state, str(e["dst"])), int(e["amount"])], "kind": "heal"}
		"shield":
			return {"text": "%s SCUDO +%d" % [unit_name(state, str(e["dst"])), int(e["amount"])], "kind": "heal"}
		"status":
			return {"text": "%s: %s" % [unit_name(state, str(e["unit"])), status_name(str(e["status"]))], "kind": "info"}
		"trait":
			if str(e.get("trait", "")) == "atipico":
				return {"text": "%s: %s" % [unit_name(state, str(e["unit"])), str(e.get("name", "TRATTO ATIPICO")).to_upper()], "kind": "info"}
			return {"text": "%s: PROTOCOLLO" % unit_name(state, str(e["unit"])), "kind": "info"}
		"counter":
			return {"text": "%s CONTRATTACCA" % unit_name(state, str(e["unit"])), "kind": "info"}
		"ronda":
			if int(e["on"]) == 1:
				return {"text": "%s: RONDA PRONTA (prossimo attacco potenziato)" % unit_name(state, str(e["unit"])), "kind": "heal"}
			return {"text": "%s LIBERA LA RONDA: ATTACCO POTENZIATO" % unit_name(state, str(e["unit"])), "kind": "hit"}
		"marks":
			if int(e["added"]) > 0:
				return {"text": "MARCHI SUL BERSAGLIO: %d  (+%d)" % [int(e["n"]), int(e["added"])], "kind": "info"}
			return {"text": "MARCHI CONSUMATI: %d" % -int(e["added"]), "kind": "hit"}
		"dodge":
			return {"text": "%s SCHIVA IL COLPO" % unit_name(state, str(e["unit"])), "kind": "heal"}
		"debuff":
			return {"text": "BERSAGLIO: %s -%d GRADO" % [str(BattleContent.STAT_NAMES.get(str(e["stat"]), str(e["stat"]).to_upper())), int(e["grades"])], "kind": "info"}
		"buff":
			return {"text": "%s POTENZIA LA SQUADRA" % unit_name(state, str(e["unit"])), "kind": "heal"}
		"summon":
			return {"text": "%s EVOCA %s" % [unit_name(state, str(e["unit"])), "UNA TORRETTA" if str(e["kind"]) == "turret" else "UN DRONE"], "kind": "info"}
		"summon_shot":
			return {"text": "%s SPARA (-1 MUN)" % ("TORRETTA" if str(e["kind"]) == "turret" else "DRONE"), "kind": "info"}
		"summon_end":
			return {"text": "%s DI %s %s" % [("TORRETTA" if str(e["kind"]) == "turret" else "DRONE"), unit_name(state, str(e["unit"])), "ESAURITO" if str(e["reason"]) == "ammo" else "PERSO"], "kind": "info"}
		"link":
			return {"text": "LINK x%d · %s + %s%s" % [int(e["n"]), unit_name(state, str(e["with"])), unit_name(state, str(e["unit"])), "  (UNISONO)" if str(e["kind"]) == "unison" else "  (CROSS: ULT +%d)" % BattleTypes.LINK_GAUGE], "kind": "link"}
		"link_break":
			return {"text": "CATENA INTERROTTA (x%d)" % int(e["n"]), "kind": "info"}
		"cleanse":
			return {"text": "%s PURIFICATO" % unit_name(state, str(e["unit"])), "kind": "heal"}
		"bleed":
			return {"text": "%s SANGUINA  [-%d]" % [unit_name(state, str(e["unit"])), int(e["amount"])], "kind": "hit"}
		"down":
			return {"text": "%s FUORI COMBATTIMENTO" % unit_name(state, str(e["unit"])), "kind": "down"}
		"arena":
			if str(e["id"]) == "contaminazione":
				return {"text": ("%s ESCE DALLA NUBE" % unit_name(state, str(e["unit"]))) if bool(e["ok"]) else ("ZONA CONTAMINATA: %s -%d PV" % [unit_name(state, str(e["unit"])), int(e["amount"])]), "kind": "info" if bool(e["ok"]) else "boss"}
			if str(e["id"]) == "eco":
				return {"text": ("ECO: IL COLPO SI RIPETE (-%s)" % num(int(e["amount"]))) if bool(e["ok"]) else "ECO: NESSUN COLPO DA RIPETERE", "kind": "link" if bool(e["ok"]) else "info"}
			return {"text": "SIGILLO ROTTO: BOSS DESTABILIZZATO" if bool(e["ok"]) else "SIGILLO INTATTO: IL BOSS SI COPRE", "kind": "info" if bool(e["ok"]) else "boss"}
		"behavior":
			var bdef: Dictionary = Arena.BEHAVIORS.get(str(e["id"]), {})
			return {"text": "%s (x%d)" % [str(bdef.get("name", "COMPORTAMENTO")), int(e.get("n", 0))], "kind": "boss"}
		"order":
			var od: Dictionary = Tactics.ORDERS.get(str(e["id"]), {})
			return {"text": "ORDINE DI SQUADRA: %s (x%d)" % [str(od.get("name", "")), int(e["n"])], "kind": "link"}
		"push":
			return {"text": "%s PAGA IL PREZZO: %s%s" % [unit_name(state, str(e["unit"])), str(Tactics.PUSH[str(e["id"])]["name"]), (" (-%d PV)" % int(e["cost"])) if int(e["cost"]) > 0 else ""], "kind": "boss" if str(e["id"]) == "proibita" else "info"}
		"plate":
			return {"text": ("PLACCA D'ARMATURA ROTTA! RESTANO %d" % int(e["left"])) if bool(e["broke"]) else ("PLACCA COLPITA (-%s)" % num(int(e["hit"]))), "kind": "link" if bool(e["broke"]) else "info"}
		"chain":
			return {"text": ("CATENA: IL BOSS COLPISCE ANCORA (%s)" % move_name(str(e["move"]))) if bool(e["ok"]) else "CATENA SPEZZATA: IL BOSS RESTA ESPOSTO", "kind": "boss" if bool(e["ok"]) else "link"}
		"resolve":
			return {"text": "%s: DETERMINAZIONE (+%d%% DANNO)" % [unit_name(state, str(e["unit"])), int(round((Tactics.RESOLVE_MULT - 1.0) * 100.0))], "kind": "heal"}
		"rescue":
			return {"text": "%s SOCCORRE %s (%d PV)" % [unit_name(state, str(e["unit"])), unit_name(state, str(e["who"])), int(e["hp"])], "kind": "heal"}
		"react":
			var rk: String = str(e["kind"])
			return {"text": "%s: %s" % [unit_name(state, str(e["unit"])), "SCHIVA LA CARICA" if rk == "dodge" else ("SI METTE IN MEZZO" if rk == "intercept" else "INTERROMPE LA CARICA")], "kind": "info"}
		"reserve":
			if int(e["delta"]) == 0:
				return {"text": "", "kind": "info"}
			return {"text": "RISERVA %s%d (%d)" % ["+" if int(e["delta"]) > 0 else "", int(e["delta"]), int(e["value"])], "kind": "info"}
		"phase":
			return {"text": "IL BOSS CAMBIA SCHEMA: FASE %d" % int(e["phase"]), "kind": "boss"}
		"tenacity":
			return {"text": "%s RESISTE CON 1 PV: ULTIMATE PRONTA" % unit_name(state, str(e["unit"])), "kind": "heal"}
		"adapt":
			return {"text": "IL BOSS SI ADATTA A %s (-%d%%)" % [move_name(str(e["move"])), int(round((1.0 - BattleTypes.ADAPT_MULT) * 100.0))], "kind": "boss"}
		"rhythm":
			return {"text": "%s: RITMO (+%d%% DANNO)" % [unit_name(state, str(e["unit"])), int(round((BattleTypes.RHYTHM_BONUS - 1.0) * 100.0))], "kind": "info"}
		"balance":
			return {"text": "EQUILIBRIO DEL BOSS -%d  (RESTANO %d)" % [int(e["amount"]), int(e["left"])], "kind": "info"}
		"break":
			return {"text": "BREAK! IL BOSS E' STORDITO", "kind": "link"}
		"boss_stunned":
			return {"text": "BOSS STORDITO: %s ANNULLATA" % move_name(str(e.get("move", ""))), "kind": "link"}
		"recover":
			if bool(e.get("soft", false)):
				return {"text": "", "kind": "info"}
			return {"text": "IL BOSS SI RIPRENDE", "kind": "info"}
		"synergy":
			return {"text": "SINERGIA %s · %s + %s" % [str(e["name"]), unit_name(state, str(e["with"])), unit_name(state, str(e["unit"]))], "kind": "link"}
		"end":
			return {"text": "OPERAZIONE RIUSCITA" if str(e["winner"]) == "players" else "OPERAZIONE FALLITA", "kind": "end"}
	return {"text": "", "kind": "info"}


# Applica un evento a una copia dello stato (solo cio' che si vede: PV, scudi,
# stati, cambi). Al termine del round la grafica si riallinea allo stato vero.
static func apply_to_display(state: Dictionary, e: Dictionary) -> void:
	match str(e.get("t", "")):
		"reserve":
			state["reserve"] = int(e["value"])
		"plate":
			var pb: Dictionary = BattleState.boss(state)
			pb["plates"] = int(e["left"])
		"arena":
			if int(e.get("amount", 0)) > 0 and str(e["id"]) == "eco":
				var eb: Dictionary = BattleState.boss(state)
				eb["hp"] = maxi(0, int(eb["hp"]) - int(e["amount"]))
			elif int(e.get("amount", 0)) > 0:
				var au: Dictionary = BattleState.unit(state, str(e["unit"]))
				if not au.is_empty():
					au["hp"] = maxi(1, int(au["hp"]) - int(e["amount"]))
		"rescue":
			var ru2: Dictionary = BattleState.unit(state, str(e["who"]))
			if not ru2.is_empty():
				ru2["hp"] = int(e["hp"])
				ru2["rescued"] = true
				ru2["statuses"] = {}
		"phase":
			state["phase"] = int(e["phase"])
		"balance":
			BattleState.boss(state)["balance"] = int(e["left"])
		"break":
			BattleState.boss(state)["stun"] = 1
			BattleState.boss(state)["exposed"] = true
		"boss_stunned":
			BattleState.boss(state)["stun"] = 0
		"recover":
			var bs: Dictionary = BattleState.boss(state)
			if not bool(e.get("soft", false)):
				bs["exposed"] = false
			bs["balance"] = int(e.get("left", bs.get("balance_max", 1)))
		"tenacity":
			var tu: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not tu.is_empty():
				tu["gauge"] = BattleTypes.GAUGE_MAX
		"swap":
			var p: Dictionary = BattleState.player(state, str(e["player"]))
			if not p.is_empty():
				p["active"] = str(e["to"])
		"marks":
			var mu: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not mu.is_empty():
				mu["marks"] = int(e["n"])
				if int(e["n"]) <= 0:
					mu["statuses"].erase("mark")
				else:
					mu["statuses"]["mark"] = 99
		"ronda":
			var ru: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not ru.is_empty():
				if int(e["on"]) == 1:
					ru["statuses"]["ronda"] = 99
				else:
					ru["statuses"].erase("ronda")
		"summon":
			var sl: Array = state["summons"]
			for i in range(sl.size() - 1, -1, -1):
				if str(sl[i]["owner"]) == str(e["unit"]) and str(sl[i]["kind"]) == str(e["kind"]):
					sl.remove_at(i)
			sl.append({"id": "%s:%s" % [str(e["kind"]), str(e["unit"])], "owner": str(e["unit"]), "kind": str(e["kind"])})
		"summon_end":
			var sl2: Array = state["summons"]
			for i in range(sl2.size() - 1, -1, -1):
				if str(sl2[i]["owner"]) == str(e["unit"]) and str(sl2[i]["kind"]) == str(e["kind"]):
					sl2.remove_at(i)
		"damage":
			var d: Dictionary = BattleState.unit(state, str(e["dst"]))
			if not d.is_empty():
				d["shield"] = maxi(0, int(d["shield"]) - int(e.get("absorbed", 0)))
				d["hp"] = maxi(0, int(d["hp"]) - int(e["amount"]))
		"bleed":
			var b: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not b.is_empty():
				b["hp"] = maxi(0, int(b["hp"]) - int(e["amount"]))
		"heal":
			var h: Dictionary = BattleState.unit(state, str(e["dst"]))
			if not h.is_empty():
				h["hp"] = mini(int(h["max_hp"]), int(h["hp"]) + int(e["amount"]))
		"shield":
			var s: Dictionary = BattleState.unit(state, str(e["dst"]))
			if not s.is_empty():
				s["shield"] = int(s["shield"]) + int(e["amount"])
		"status":
			var t: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not t.is_empty():
				t["statuses"][str(e["status"])] = int(e.get("turns", 1))
		"ammo":
			var am: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not am.is_empty():
				am["ammo"] = int(e["value"])
		"cleanse":
			var c: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not c.is_empty():
				c["statuses"].erase("bleed")
		"down":
			var k: Dictionary = BattleState.unit(state, str(e["unit"]))
			if not k.is_empty():
				k["hp"] = 0
				k["statuses"] = {}
				k["shield"] = 0
