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
