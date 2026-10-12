class_name MissionConfig
extends RefCounted

# Missione scelta (boss e difficolta'): resta valida tra una scena e l'altra,
# cosi' RIGIOCA ripete la stessa battaglia.

static var boss_id: String = "distributore"
static var tier: int = 0


static func set_mission(new_boss: String, new_tier: int) -> void:
	if BattleContent.BOSSES.has(new_boss):
		boss_id = new_boss
	tier = clampi(new_tier, 0, BattleContent.TIERS.size() - 1)


static func boss_title(id: String) -> String:
	var b: Dictionary = BattleContent.BOSSES.get(id, {})
	return str(b.get("name", id)).to_upper()


# La missione migliore da proporre: l'ultima giocata se e' ancora la piu' utile,
# altrimenti il primo boss non ancora battuto a tutte le difficolta', al livello
# piu' alto che si puo' affrontare. Se hai fatto tutto, ripete l'ultima.
static func suggest(roster: Dictionary) -> Dictionary:
	for id in BattleContent.BOSS_ORDER:
		var boss: String = str(id)
		var cleared: int = RosterState.cleared_tiers(roster, boss)
		if RosterState.is_boss_unlocked(roster, boss) and cleared < BattleContent.TIERS.size():
			return {"boss": boss, "tier": cleared}
	return {"boss": boss_id, "tier": tier}
