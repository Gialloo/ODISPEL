extends SceneTree

# Replica della diretta: tiene i legami, azzera le scelte, conta i giri e lo dice sui cartelli.
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	Story.save_path = "user://salvataggio_replica.cfg"     # mai il salvataggio vero
	Story.new_game()
	_chk(Story.replica() == 0, "partita nuova senza replica")
	Story.set_flag("legame_ferri_saul")
	Story.set_flag("saul_tentato")
	Story.chapter = 3
	Story.new_replica()
	_chk(Story.replica() == 1, "prima replica")
	_chk(Story.has_flag("legame_ferri_saul"), "il legame resta")
	_chk(not Story.has_flag("saul_tentato"), "le scelte si rifanno")
	_chk(Story.chapter == 0 and Story.step == 0, "si riparte dall'inizio")
	Story.chapter = 1     # il capitolo 1 si apre con un cartello
	_chk(str(Story.current().get("titolo", "")).begins_with("REPLICA 1 · "), "il cartello dice replica")
	Story.chapter = 0
	_chk(Story.load_game() and Story.replica() == 1, "la replica si salva")
	Story.new_replica()
	_chk(Story.replica() == 2, "seconda replica")
	# NEW GAME+: la squadra resta com'e', fino a NG+10, nemici tarati sul 14 e poi +9 a giro, molta piu' esperienza
	Progress.data["lv"]["ferri"] = 27
	Progress.add_stolen("scarica", "prova")
	Story.new_replica()
	_chk(Progress.level("ferri") == 27 and (Progress.data["stolen"] as Array).has("scarica"), "la squadra resta com'e' nella replica")
	for _i in 20:
		Story.new_replica()
	_chk(Story.replica() == BattleTypes.REPLICA_MAX, "non si va oltre NG+10")
	_chk(BattleTypes.replica_level(1, 0) == 1 and BattleTypes.replica_level(11, 0) == 11, "la prima partita resta com'era")
	_chk(BattleTypes.replica_level(1, 1) == 14 and BattleTypes.replica_level(11, 1) == 24, "NG+1: nemici dal 14 al 24")
	_chk(BattleTypes.replica_level(1, 10) == 95 and BattleTypes.replica_level(11, 10) == 100, "NG+10: nemici dal 95 al 100")
	_chk(BattleTypes.replica_level(11, 99) == 100, "oltre NG+10 conta la decima")
	_chk(is_equal_approx(BattleTypes.story_hp_grow(11), 1.0 + BattleTypes.STORY_HP_PER_LEVEL * 10.0), "la scala dell'atto 1 non cambia")
	_chk(BattleTypes.story_atk_grow(100) < 1.0 + BattleTypes.STORY_ATK_PER_LEVEL * 99.0 * 0.8 and BattleTypes.story_hp_grow(100) > BattleTypes.story_hp_grow(50), "oltre il 12 i nemici crescono come la squadra")
	_chk(is_equal_approx(BattleTypes.replica_hard(4), BattleTypes.replica_hard(10)), "il +15% a giro si ferma al quarto")
	Progress.reset()
	var e0: int = Progress.battle_exp(14, true, 0, 0)
	var e1: int = Progress.battle_exp(14, true, 0, 1)
	_chk(e1 >= e0 * 2 - 1, "NG+1: almeno il doppio dell'esperienza")
	_chk(Progress.battle_exp(14, true, 0, 10) > e1, "a ogni giro ancora di piu'")
	Story.new_game()
	_chk(Story.replica() == 0 and not Story.has_flag("legame_ferri_saul"), "nuova partita azzera tutto")
	_chk(Progress.level("ferri") == 1, "nuova partita: squadra da capo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Story.save_path))
	print("test_v3_replica: " + ("OK" if fails == 0 else "FALLITO (%d)" % fails))
	quit(1 if fails > 0 else 0)
