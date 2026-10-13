class_name Weekly
extends RefCounted

# EVENTO DELLA SETTIMANA + MISSIONI SETTIMANALI + RECORD PERSONALI.
# L'evento: un boss e un modificatore decisi dalla settimana (uguali per tutti), piu' duro della sfida del giorno.
# La prima vittoria della settimana paga un premio grande; le settimane consecutive aumentano il bonus.
# Le missioni settimanali si completano giocando normalmente e pagano da sole.
# (Nessuna classifica online: servirebbe un server che verifica i risultati. Qui ci sono i record personali.)
#
# roster["weekly"] = {"week": id, "wins": n, "dailies": n, "event": bool, "claimed": [ids],
#                     "streak": settimane di fila, "last_event": id, "best_streak": n, "events_total": n}

const FLOOR: int = 8                  # scala dei nemici (piu' alta della sfida del giorno)
const BASE_MULT: float = 8.0          # premi dell'evento rispetto a una missione normale
const STREAK_STEP: float = 0.1
const STREAK_CAP: int = 5

# id, testo, obiettivo, premio (monete)
const MISSIONS: Array = [
	{"id": "wins", "text": "Vinci battaglie", "goal": 6, "coins": 300},
	{"id": "dailies", "text": "Supera la sfida del giorno", "goal": 3, "coins": 400},
	{"id": "event", "text": "Supera l'evento della settimana", "goal": 1, "coins": 600},
]


static func today() -> String:
	return Time.get_date_string_from_system()


# Numero di settimana (cambia il lunedi', alle 00:00 locali circa). Epoca: 1970-01-01 era un giovedi'.
static func week_id(day: String = "") -> int:
	var d: String = day if day != "" else today()
	var days: int = int(Time.get_unix_time_from_datetime_string(d + "T12:00:00")) / 86400
	return (days + 3) / 7


static func _h(week: int, salt: String) -> int:
	return absi(hash(str(week) + "|" + salt))


static func boss_for(roster: Dictionary, week: int = -1) -> String:
	var w: int = week if week >= 0 else week_id()
	var open: Array = []
	for id in BattleContent.BOSS_ORDER:
		if RosterState.is_boss_unlocked(roster, str(id)):
			open.append(str(id))
	if open.is_empty():
		return str(BattleContent.BOSS_ORDER[0])
	return str(open[_h(w, "boss") % open.size()])


static func mod_for(week: int = -1) -> Dictionary:
	var w: int = week if week >= 0 else week_id()
	return Endless.MODS[_h(w, "mod") % Endless.MODS.size()]


static func tier_for(roster: Dictionary, boss_id: String) -> int:
	return 1 if RosterState.cleared_tiers(roster, boss_id) >= 1 else 0


# Porta il blocco "weekly" alla settimana corrente (azzera i progressi della settimana vecchia, tiene i totali).
static func ensure_week(roster: Dictionary, week: int = -1) -> Dictionary:
	var w: int = week if week >= 0 else week_id()
	var e: Dictionary = roster.get("weekly", {})
	if int(e.get("week", -1)) != w:
		var last: int = int(e.get("last_event", -99))
		var streak: int = int(e.get("streak", 0)) if last == w - 1 else 0
		e = {
			"week": w, "wins": 0, "dailies": 0, "event": false, "claimed": [],
			"streak": streak, "last_event": last, "best_streak": int(e.get("best_streak", 0)),
			"events_total": int(e.get("events_total", 0)),
		}
		roster["weekly"] = e
	return roster["weekly"]


static func event_done(roster: Dictionary, week: int = -1) -> bool:
	return bool(ensure_week(roster, week).get("event", false))


static func streak(roster: Dictionary, week: int = -1) -> int:
	var w: int = week if week >= 0 else week_id()
	var e: Dictionary = ensure_week(roster, w)
	var last: int = int(e.get("last_event", -99))
	return int(e.get("streak", 0)) if (last == w or last == w - 1) else 0


static func reward_mult(roster: Dictionary, week: int = -1) -> float:
	return BASE_MULT * (1.0 + STREAK_STEP * float(mini(streak(roster, week), STREAK_CAP)))


static func progress(roster: Dictionary, id: String, week: int = -1) -> int:
	var e: Dictionary = ensure_week(roster, week)
	match id:
		"wins": return int(e.get("wins", 0))
		"dailies": return int(e.get("dailies", 0))
		"event": return 1 if bool(e.get("event", false)) else 0
	return 0


# Riscuote le missioni completate (una sola volta ciascuna). Ritorna le righe da mostrare.
static func _claim(roster: Dictionary, week: int) -> Array:
	var e: Dictionary = ensure_week(roster, week)
	var lines: Array = []
	for m in MISSIONS:
		var id: String = str(m["id"])
		if (e["claimed"] as Array).has(id):
			continue
		if progress(roster, id, week) >= int(m["goal"]):
			(e["claimed"] as Array).append(id)
			RosterState.apply_rewards(roster, {"coins": int(m["coins"]), "materials": {}})
			lines.append("MISSIONE SETTIMANALE: %s  +%d monete" % [str(m["text"]), int(m["coins"])])
	return lines


# Una battaglia vinta (qualsiasi). daily = e' una sfida del giorno pagata. Ritorna le notifiche.
static func record_win(roster: Dictionary, daily: bool = false, week: int = -1) -> Array:
	var w: int = week if week >= 0 else week_id()
	var e: Dictionary = ensure_week(roster, w)
	e["wins"] = int(e["wins"]) + 1
	if daily:
		e["dailies"] = int(e["dailies"]) + 1
	return _claim(roster, w)


# Vittoria dell'evento. Ritorna true se e' la prima della settimana (quella che paga il bonus).
static func record_event(roster: Dictionary, week: int = -1) -> bool:
	var w: int = week if week >= 0 else week_id()
	var e: Dictionary = ensure_week(roster, w)
	if bool(e["event"]):
		return false
	var s: int = streak(roster, w) + 1
	e["event"] = true
	e["streak"] = s
	e["last_event"] = w
	e["best_streak"] = maxi(int(e.get("best_streak", 0)), s)
	e["events_total"] = int(e.get("events_total", 0)) + 1
	return true


static func finish_notes(roster: Dictionary, week: int = -1) -> Array:
	return _claim(roster, week if week >= 0 else week_id())


static func start(roster: Dictionary) -> void:
	var boss: String = boss_for(roster)
	MissionConfig.set_daily(boss, tier_for(roster, boss), mod_for())
	MissionConfig.weekly = true
	SceneRouter.go("battle", true)


# Riepilogo dei record personali (al posto di una classifica online).
static func records_text(roster: Dictionary) -> String:
	var e: Dictionary = ensure_week(roster)
	var d: Dictionary = roster.get("daily", {})
	return "RECORD  ·  Ciclo Infinito: piano %d  ·  Serie del giorno: %d  ·  Eventi superati: %d (serie %d)" % [
		Endless.best(roster), int(d.get("best", 0)), int(e.get("events_total", 0)), int(e.get("best_streak", 0))]


static func missions_text(roster: Dictionary) -> String:
	var e: Dictionary = ensure_week(roster)
	var parts: Array = []
	for m in MISSIONS:
		var got: bool = (e["claimed"] as Array).has(str(m["id"]))
		parts.append("%s %s %d/%d" % ["✓" if got else "·", str(m["text"]), mini(progress(roster, str(m["id"])), int(m["goal"])), int(m["goal"])])
	return "\n".join(parts)
