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
	Story.new_game()
	_chk(Story.replica() == 0 and not Story.has_flag("legame_ferri_saul"), "nuova partita azzera tutto")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Story.save_path))
	print("test_v3_replica: " + ("OK" if fails == 0 else "FALLITO (%d)" % fails))
	quit(1 if fails > 0 else 0)
