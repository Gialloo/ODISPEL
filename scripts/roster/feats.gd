class_name Feats
extends RefCounted

# Imprese: obiettivi permanenti con premio fisso (niente fortuna). Si consultano nella schermata OBIETTIVI e il premio
# si riscuote a mano. Vivono nel salvataggio dell'operatore:
#   roster["stats"]  = {"plays": n, "wins": n}            (contatori delle battaglie)
#   roster["feats"]  = {"claimed": {id: true}}            (imprese gia' riscosse)
#
# Una impresa: {id, group, name, desc, goal, metric, arg, reward}. Il progresso si calcola dal salvataggio, quindi anche
# chi ha gia' battuto dei boss prima di questa versione trova le imprese pronte da riscuotere.

const TIER_NAMES: Array = ["NORMALE", "DIFFICILE", "INCUBO"]
const GROUPS: Array = ["MISSIONI", "BATTAGLIE", "OPERATORI", "POTENZIAMENTI", "INFINITO"]


static func stats(roster: Dictionary) -> Dictionary:
	if not roster.has("stats") or not (roster["stats"] is Dictionary):
		roster["stats"] = {"plays": 0, "wins": 0}
	return roster["stats"]


static func claimed(roster: Dictionary) -> Dictionary:
	if not roster.has("feats") or not (roster["feats"] is Dictionary):
		roster["feats"] = {"claimed": {}}
	if not roster["feats"].has("claimed"):
		roster["feats"]["claimed"] = {}
	return roster["feats"]["claimed"]


static func _feat(id: String, group: String, name: String, desc: String, goal: int, metric: String, arg: String, reward: Dictionary) -> Dictionary:
	return {"id": id, "group": group, "name": name, "desc": desc, "goal": goal, "metric": metric, "arg": arg, "reward": reward}


# Elenco completo (si costruisce una volta).
static var _all: Array = []


static func all() -> Array:
	if not _all.is_empty():
		return _all
	var out: Array = []
	# missioni: ogni boss a ogni difficolta'
	for boss_id in BattleContent.BOSS_ORDER:
		var title: String = MissionConfig.boss_title(str(boss_id))
		for t in BattleContent.TIERS.size():
			var coins: int = 600 + 500 * t + 200 * BattleContent.BOSS_ORDER.find(boss_id)
			var reward: Dictionary = {"coins": coins, "nucleo": 2 + t * 2, "lega": 1 + t * 2}
			if t == 2:
				reward["drop"] = {"kind": "move", "id": "cura_l" if BattleContent.BOSS_ORDER.find(boss_id) % 2 == 0 else "barriera_l"}
			out.append(_feat("boss_%s_%d" % [boss_id, t], "MISSIONI", "%s · %s" % [title, TIER_NAMES[t]], "Sconfiggi %s a %s." % [title, TIER_NAMES[t]], t + 1, "cleared", str(boss_id), reward))
	# battaglie
	for entry in [[1, "Primo contatto", 400], [5, "Squadra affiatata", 800], [15, "Veterani", 1500], [40, "Leggende di strada", 3000], [100, "Incubo della citta'", 6000]]:
		out.append(_feat("wins_%d" % entry[0], "BATTAGLIE", str(entry[1]), "Vinci %d battaglie." % entry[0], int(entry[0]), "wins", "", {"coins": int(entry[2]), "nucleo": 1 + int(entry[0]) / 10, "lega": int(entry[0]) / 15}))
	for entry in [[5, 600], [25, 1500], [75, 4000]]:
		out.append(_feat("plays_%d" % entry[0], "BATTAGLIE", "Sul campo", "Affronta %d battaglie (vinte o perse)." % entry[0], int(entry[0]), "plays", "", {"coins": int(entry[1]), "nucleo": 2}))
	# operatori
	for entry in [[1, 500], [10, 1500], [30, 4000], [75, 9000]]:
		out.append(_feat("pulls_%d" % entry[0], "OPERATORI", "Reclutatore", "Esegui %d reclutamenti." % entry[0], int(entry[0]), "pulls", "", {"coins": int(entry[1]), "nucleo": 2}))
	for entry in [[5, 700], [7, 1500], [10, 3500]]:
		out.append(_feat("owned_%d" % entry[0], "OPERATORI", "Collezione", "Possiedi %d operatori." % entry[0], int(entry[0]), "owned", "", {"coins": int(entry[1]), "nucleo": 3}))
	out.append(_feat("legend_1", "OPERATORI", "Una leggenda in squadra", "Possiedi un operatore leggendario.", 1, "owned_rarity", "3", {"coins": 2000, "nucleo": 4, "lega": 2, "drop": {"kind": "move", "id": "spezzatutto_l"}}))
	for entry in [[1, 500], [3, 1500], [5, 4000]]:
		out.append(_feat("rank_%d" % entry[0], "OPERATORI", "Rank %d" % entry[0], "Porta un operatore al rank %d." % entry[0], int(entry[0]), "max_rank", "", {"coins": int(entry[1]), "nucleo": 2 + int(entry[0])}))
	# potenziamenti
	for entry in [[5, 500], [10, 1200], [20, 3000], [35, 6500]]:
		out.append(_feat("level_%d" % entry[0], "POTENZIAMENTI", "Livello %d" % entry[0], "Porta un operatore al livello %d." % entry[0], int(entry[0]), "max_level", "", {"coins": int(entry[1]), "nucleo": 2 + int(entry[0]) / 5}))
	for entry in [[3, 600], [10, 1800], [25, 5000]]:
		out.append(_feat("gear_%d" % entry[0], "POTENZIAMENTI", "Arsenale", "Possiedi %d pezzi di equipaggiamento." % entry[0], int(entry[0]), "gear", "", {"coins": int(entry[1]), "lega": 3 + int(entry[0]) / 5}))
	out.append(_feat("moves_epic", "POTENZIAMENTI", "Abilita' epica", "Possiedi una abilita' epica.", 1, "move_rarity", "2", {"coins": 1500, "nucleo": 3, "drop": {"kind": "move", "id": "marchio_e"}}))
	out.append(_feat("moves_legend", "POTENZIAMENTI", "Abilita' leggendaria", "Possiedi una abilita' leggendaria.", 1, "move_rarity", "3", {"coins": 3500, "nucleo": 5, "lega": 4}))
	# ciclo infinito e sfida del giorno
	for entry in [[5, 800, 2], [10, 2000, 4], [20, 5000, 8], [35, 10000, 14]]:
		out.append(_feat("endless_%d" % entry[0], "INFINITO", "Piano %d" % entry[0], "Raggiungi il piano %d del Ciclo Infinito." % entry[0], int(entry[0]), "endless_best", "", {"coins": int(entry[1]), "nucleo": int(entry[2]), "lega": int(entry[2]) / 2}))
	for entry in [[3, 1000], [7, 3000], [14, 8000]]:
		out.append(_feat("daily_%d" % entry[0], "INFINITO", "Serie di %d giorni" % entry[0], "Vinci la Sfida del giorno per %d giorni di fila." % entry[0], int(entry[0]), "daily_best", "", {"coins": int(entry[1]), "nucleo": 3 + int(entry[0]) / 2, "lega": 2}))
	for f in out:
		if Profile.FEAT_ICONS.has(str(f["id"])):
			f["reward"]["icon"] = Profile.FEAT_ICONS[str(f["id"])]
	_all = out
	return out


static func by_id(id: String) -> Dictionary:
	for f in all():
		if str(f["id"]) == id:
			return f
	return {}


# Valore attuale della metrica (non limitato all'obiettivo).
static func value(roster: Dictionary, f: Dictionary) -> int:
	match str(f["metric"]):
		"cleared":
			return RosterState.cleared_tiers(roster, str(f["arg"]))
		"wins":
			return int(stats(roster).get("wins", 0))
		"plays":
			return int(stats(roster).get("plays", 0))
		"pulls":
			return int(roster.get("pulls", 0))
		"owned":
			return (roster["characters"] as Dictionary).size()
		"owned_rarity":
			var n: int = 0
			for id in roster["characters"]:
				if int(BattleContent.CHARACTERS.get(str(id), {}).get("rarity", 0)) >= int(f["arg"]):
					n += 1
			return n
		"max_rank":
			var best: int = 0
			for id in roster["characters"]:
				best = maxi(best, int(roster["characters"][id].get("rank", 0)))
			return best
		"max_level":
			var top: int = 0
			for id in roster["characters"]:
				top = maxi(top, int(roster["characters"][id].get("level", 1)))
			return top
		"gear":
			return (roster.get("gear", {}) as Dictionary).size()
		"endless_best":
			return Endless.best(roster)
		"daily_best":
			return int(roster.get("daily", {}).get("best", 0))
		"move_rarity":
			var c: int = 0
			for id in roster.get("moves", {}):
				if str(BattleContent.MOVES.get(str(id), {}).get("kind", "")) == "skill" and BattleContent.rarity_of("move", str(id)) >= int(f["arg"]) and int(roster["moves"][id]) > 0:
					c += 1
			return c
	return 0


static func progress(roster: Dictionary, f: Dictionary) -> int:
	return mini(value(roster, f), int(f["goal"]))


static func is_done(roster: Dictionary, f: Dictionary) -> bool:
	return value(roster, f) >= int(f["goal"])


static func is_claimed(roster: Dictionary, f: Dictionary) -> bool:
	return bool(claimed(roster).get(str(f["id"]), false))


static func can_claim(roster: Dictionary, f: Dictionary) -> bool:
	return is_done(roster, f) and not is_claimed(roster, f)


static func claimable_count(roster: Dictionary) -> int:
	var n: int = 0
	for f in all():
		if can_claim(roster, f):
			n += 1
	return n


static func done_count(roster: Dictionary) -> int:
	var n: int = 0
	for f in all():
		if is_claimed(roster, f):
			n += 1
	return n


# Riscuote un'impresa. Ritorna il premio dato ({} se non si puo').
static func claim(roster: Dictionary, id: String) -> Dictionary:
	var f: Dictionary = by_id(id)
	if f.is_empty() or not can_claim(roster, f):
		return {}
	var reward: Dictionary = f["reward"]
	roster["coins"] = int(roster.get("coins", 0)) + int(reward.get("coins", 0))
	for mat in ["nucleo", "lega"]:
		if int(reward.get(mat, 0)) > 0:
			roster["materials"][mat] = int(roster["materials"].get(mat, 0)) + int(reward[mat])
	if reward.has("drop"):
		RosterState.add_drop(roster, reward["drop"])
	if reward.has("icon"):
		Profile.unlock(str(reward["icon"]))
	claimed(roster)[id] = true
	return reward


# Riscuote tutte le imprese pronte. Ritorna quante.
static func claim_all(roster: Dictionary) -> int:
	var n: int = 0
	for f in all():
		if not claim(roster, str(f["id"])).is_empty():
			n += 1
	return n


# Registra una battaglia finita nei contatori.
static func record_battle(roster: Dictionary, victory: bool) -> void:
	var s: Dictionary = stats(roster)
	s["plays"] = int(s.get("plays", 0)) + 1
	if victory:
		s["wins"] = int(s.get("wins", 0)) + 1


static func reward_text(reward: Dictionary) -> String:
	var parts: Array = []
	if int(reward.get("coins", 0)) > 0:
		parts.append("%d MONETE" % int(reward["coins"]))
	if int(reward.get("nucleo", 0)) > 0:
		parts.append("%d NUCLEI" % int(reward["nucleo"]))
	if int(reward.get("lega", 0)) > 0:
		parts.append("%d LEGHE" % int(reward["lega"]))
	if reward.has("drop"):
		parts.append("ABILITA': %s" % BattleText.move_name(str(reward["drop"]["id"])))
	if reward.has("icon"):
		parts.append("ICONA: %s" % Profile.icon_name(str(reward["icon"])))
	return "  +  ".join(parts)
