class_name PlayerStats
extends RefCounted

# Statistiche dell'operatore per il profilo: tutto si calcola dal salvataggio, niente di nuovo da salvare.


# Elenco di coppie [etichetta, valore] gia' pronte da mostrare.
static func rows(roster: Dictionary) -> Array:
	var st: Dictionary = Feats.stats(roster)
	var plays: int = int(st.get("plays", 0))
	var wins: int = int(st.get("wins", 0))
	var pvp_plays: int = int(st.get("pvp_plays", 0))
	var pvp_wins: int = int(st.get("pvp_wins", 0))
	var tiers_done: int = 0
	var tiers_all: int = BattleContent.BOSS_ORDER.size() * BattleContent.TIERS.size()
	for boss_id in BattleContent.BOSS_ORDER:
		tiers_done += RosterState.cleared_tiers(roster, str(boss_id))
	var owned: int = (roster["characters"] as Dictionary).size()
	var feats_all: int = Feats.all().size()
	return [
		["BATTAGLIE", str(plays)],
		["VITTORIE", "%d  (%s)" % [wins, percent(wins, plays)]],
		["BOSS BATTUTI", "%d / %d" % [tiers_done, tiers_all]],
		["OPERATORI", "%d / %d" % [owned, BattleContent.CHARACTERS.size()]],
		["RECLUTAMENTI", str(int(roster.get("pulls", 0)))],
		["PVP GIOCATE", str(pvp_plays)],
		["PVP VINTE", "%d  (%s)" % [pvp_wins, percent(pvp_wins, pvp_plays)]],
		["CICLO INFINITO", "PIANO %d" % Endless.best(roster)],
		["SERIE SFIDA", "%d GIORNI" % int(roster.get("daily", {}).get("best", 0))],
		["OBIETTIVI", "%d / %d" % [Feats.done_count(roster), feats_all]],
		["ARCHIVIO SCOPERTE", "%d / %d" % [Discoveries.count(roster), Discoveries.total()]],
		["TITOLI", "%d / %d" % [Titles.earned(roster, Profile.owned_icons()).size(), Titles.all().size()]],
		["POTERE TOTALE", str(Power.account(roster, Profile.owned_icons()))],
	]


static func percent(part: int, total: int) -> String:
	if total <= 0:
		return "0%"
	return "%d%%" % int(round(100.0 * float(part) / float(total)))
