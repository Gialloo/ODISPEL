class_name Daily
extends RefCounted

# SFIDA DEL GIORNO: un bersaglio e un modificatore decisi dalla data (uguali per tutti i giocatori).
# La prima vittoria della giornata paga premi maggiorati; giorni di fila di vittorie aumentano il bonus.
#
# roster["daily"] = {"day": "2026-10-13" ultimo giorno vinto, "streak": giorni di fila, "best": record serie}

const FLOOR: int = 5                  # scala dei nemici (come il piano 5 del Ciclo Infinito)
const BASE_MULT: float = 3.0          # premi del giorno rispetto a una missione normale
const STREAK_STEP: float = 0.1        # +10% per ogni giorno di fila
const STREAK_CAP: int = 5             # fino a +50%


static func today() -> String:
	return Time.get_date_string_from_system()


static func _h(day: String, salt: String) -> int:
	return absi(hash(day + "|" + salt))


# Il bersaglio del giorno: sempre uno di quelli gia' aperti.
static func boss_for(roster: Dictionary, day: String = "") -> String:
	var d: String = day if day != "" else today()
	var open: Array = []
	for id in BattleContent.BOSS_ORDER:
		if RosterState.is_boss_unlocked(roster, str(id)):
			open.append(str(id))
	if open.is_empty():
		return str(BattleContent.BOSS_ORDER[0])
	return str(open[_h(d, "boss") % open.size()])


static func mod_for(day: String = "") -> Dictionary:
	var d: String = day if day != "" else today()
	return Endless.MODS[_h(d, "mod") % Endless.MODS.size()]


static func tier_for(roster: Dictionary, boss_id: String) -> int:
	# difficile se hai gia' battuto il bersaglio a NORMALE, altrimenti normale
	return 1 if RosterState.cleared_tiers(roster, boss_id) >= 1 else 0


static func done_today(roster: Dictionary, day: String = "") -> bool:
	var d: String = day if day != "" else today()
	return str(roster.get("daily", {}).get("day", "")) == d


static func _yesterday(day: String) -> String:
	var t: int = int(Time.get_unix_time_from_datetime_string(day + "T12:00:00"))
	return Time.get_date_string_from_unix_time(t - 86400)


# Serie in corso: se ieri non hai vinto, e' gia' finita.
static func streak(roster: Dictionary, day: String = "") -> int:
	var d: String = day if day != "" else today()
	var e: Dictionary = roster.get("daily", {})
	var last: String = str(e.get("day", ""))
	if last == d or last == _yesterday(d):
		return int(e.get("streak", 0))
	return 0


static func reward_mult(roster: Dictionary, day: String = "") -> float:
	return BASE_MULT * (1.0 + STREAK_STEP * float(mini(streak(roster, day), STREAK_CAP)))


# Registra una vittoria del giorno. Ritorna true se e' la prima di oggi (quella che paga il bonus).
static func record_win(roster: Dictionary, day: String = "") -> bool:
	var d: String = day if day != "" else today()
	if done_today(roster, d):
		return false
	var s: int = streak(roster, d) + 1
	var e: Dictionary = roster.get("daily", {})
	roster["daily"] = {"day": d, "streak": s, "best": maxi(int(e.get("best", 0)), s)}
	return true


static func scale_rewards(rewards: Dictionary, mult: float) -> Dictionary:
	var out: Dictionary = rewards.duplicate(true)
	out["coins"] = int(round(float(out.get("coins", 0)) * mult))
	var mats: Dictionary = out.get("materials", {})
	for k in mats:
		mats[k] = int(round(float(mats[k]) * mult))
	out["materials"] = mats
	return out


static func start(roster: Dictionary) -> void:
	var boss: String = boss_for(roster)
	MissionConfig.set_daily(boss, tier_for(roster, boss), mod_for())
	SceneRouter.go("battle", true)
