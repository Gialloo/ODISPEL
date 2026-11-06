extends SceneTree

# Integrita' del salvataggio: validazione dei dati area e recupero dal backup.

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _remove_save_files() -> void:
	for suffix in ["", ".tmp", ".bak", ".bad"]:
		var path: String = Story.save_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	Story.save_path = "user://test_integrita_salvataggio.cfg"
	_remove_save_files()
	_test_area_validation()
	_test_reject_invalid_new_save()
	_test_backup_recovery()
	_test_reject_malformed_area()
	_remove_save_files()
	print("test_v3_integrita_salvataggio: " + ("OK" if fails == 0 else "%d FALLITI" % fails))
	quit(1 if fails > 0 else 0)


func _test_area_validation() -> void:
	check(Story.validate_area_state({}), "area vuota valida")
	check(Story.validate_area_state({
		"pos": Vector3(1.0, 0.14, 2.0),
		"yaw": 0.5,
		"clues": ["indizio_a"],
		"defeated": ["frammento_a"],
		"banter_used": {"battuta_a": true}
	}), "area salvata con tutti i campi attesi valida")
	check(not Story.validate_area_state({"pos": "1,2,3"}), "posizione serializzata come testo rifiutata")
	check(not Story.validate_area_state({"pos": Vector3(NAN, 0.0, 0.0)}), "coordinata NaN rifiutata")
	check(not Story.validate_area_state({"pos": Vector3(0.0, INF, 0.0)}), "coordinata infinita rifiutata")
	check(not Story.validate_area_state({"yaw": INF}), "yaw infinito rifiutato")
	check(not Story.validate_area_state({"yaw": "non-un-numero"}), "yaw con tipo errato rifiutato")
	check(not Story.validate_area_state({"clues": "indizio_a"}), "lista indizi con tipo errato rifiutata")
	check(not Story.validate_area_state({"defeated": [12]}), "identificativo nemico non testuale rifiutato")
	check(not Story.validate_area_state({"banter_used": ["battuta_a"]}), "registro chiacchiere non dizionario rifiutato")
	check(not Story.validate_area_state({"banter_used": {"battuta_a": "si"}}), "valore chiacchiera non booleano rifiutato")


func _test_reject_invalid_new_save() -> void:
	Story.chapter = 0
	Story.step = 0
	Story.flags = {"salvataggio_valido": true}
	Story.area_state = {"pos": Vector3(2.0, 0.14, 3.0), "yaw": 0.0}
	Progress.reset()
	check(Story.save(), "salvataggio di riferimento valido scritto")
	Story.area_state = {"pos": "posizione corrotta"}
	check(not Story.save(), "nuovo salvataggio malformato rifiutato")
	check(Story._read_valid_save(Story.save_path) != null, "il salvataggio principale valido resta intatto")
	check(not FileAccess.file_exists(Story.save_path + ".tmp"), "file temporaneo invalido rimosso")
	check(Story.load_game(), "il salvataggio valido resta caricabile dopo il rifiuto")
	check(Story.has_flag("salvataggio_valido"), "il checkpoint precedente resta disponibile")


func _test_backup_recovery() -> void:
	Story.chapter = 0
	Story.step = 0
	Story.flags = {"checkpoint_precedente": true}
	Story.area_state = {"pos": Vector3(1.0, 0.14, 2.0), "yaw": 0.25, "clues": ["indizio_a"], "defeated": [], "banter_used": {}}
	Progress.reset()
	check(Story.save(), "primo salvataggio valido scritto")
	Story.flags = {"checkpoint_nuovo": true}
	Story.area_state = {"pos": Vector3(3.0, 0.14, 4.0), "yaw": 0.75, "clues": [], "defeated": ["frammento_a"], "banter_used": {}}
	check(Story.save(), "secondo salvataggio valido scritto con backup del precedente")
	var corrupt := FileAccess.open(Story.save_path, FileAccess.WRITE)
	check(corrupt != null, "file principale apribile per simulare corruzione")
	if corrupt != null:
		corrupt.store_string("FILE CORROTTO")
		corrupt.close()
	check(Story.load_game(), "caricamento recupera il backup dopo corruzione del principale")
	check(Story.has_flag("checkpoint_precedente"), "recuperato il checkpoint precedente")
	check(not Story.has_flag("checkpoint_nuovo"), "non viene caricato il contenuto corrotto/nuovo")
	check(Story.area_state.get("pos", Vector3.ZERO) == Vector3(1.0, 0.14, 2.0), "recuperata anche la posizione area del backup")


func _test_reject_malformed_area() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("storia", "capitolo", 0)
	cfg.set_value("storia", "passo", 0)
	cfg.set_value("storia", "flag", {})
	cfg.set_value("storia", "area", {"pos": "posizione corrotta"})
	cfg.set_value("squadra", "dati", Progress.data)
	var path: String = Story.save_path + ".malformed"
	check(cfg.save(path) == OK, "fixture di salvataggio malformato scritta")
	check(Story._read_valid_save(path) == null, "salvataggio con posizione area malformata rifiutato")
	cfg.set_value("storia", "capitolo", Story.chapters().size())
	cfg.set_value("storia", "passo", 1)
	cfg.set_value("storia", "area", {})
	check(cfg.save(path) == OK, "fixture con capitolo conclusivo e passo errato scritta")
	check(Story._read_valid_save(path) == null, "stato conclusivo con passo diverso da zero rifiutato")
	cfg.set_value("storia", "passo", 0)
	check(cfg.save(path) == OK, "fixture conclusiva valida scritta")
	check(Story._read_valid_save(path) != null, "stato conclusivo canonico accettato")
	cfg.set_value("storia", "capitolo", "0")
	cfg.set_value("storia", "passo", 0)
	check(cfg.save(path) == OK, "fixture con capitolo testuale scritta")
	check(Story._read_valid_save(path) == null, "capitolo testuale rifiutato senza conversione implicita")
	cfg.set_value("storia", "capitolo", 0)
	cfg.set_value("storia", "passo", 0.5)
	check(cfg.save(path) == OK, "fixture con passo frazionario scritta")
	check(Story._read_valid_save(path) == null, "passo frazionario rifiutato")
	cfg.set_value("storia", "passo", NAN)
	check(cfg.save(path) == OK, "fixture con passo non finito scritta")
	check(Story._read_valid_save(path) == null, "passo NaN rifiutato")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
