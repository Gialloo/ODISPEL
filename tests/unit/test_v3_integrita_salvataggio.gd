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
	_test_reject_invalid_progression_save()
	_test_backup_recovery()
	_test_reject_malformed_area()
	_test_repair_progression()
	_test_old_ids()
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


func _test_reject_invalid_progression_save() -> void:
	Story.chapter = 0
	Story.step = 0
	Story.flags = {"progressione_valida": true}
	Story.area_state = {}
	Progress.reset()
	check(Story.save(), "checkpoint con progressione valida scritto")
	Progress.data["lv"]["lance"] = Progress.MAX_LEVEL + 1
	check(not Story.save(), "progressione con livello oltre il massimo rifiutata")
	check(Story._read_valid_save(Story.save_path) != null, "il checkpoint precedente resta valido dopo errore progressione")
	check(Story.load_game(), "checkpoint precedente ancora caricabile dopo errore progressione")
	check(Progress.level("lance") == 1, "il livello precedente viene ripristinato")
	Progress.reset()


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


# Opzione 1B (decisione dell'autore 6/11/2026): in lettura la progressione riparabile si ripara invece di perdere la partita.
func _test_repair_progression() -> void:
	Progress.reset()
	Progress.grant(400)
	var good: Dictionary = Progress.data.duplicate(true)
	# 1. equipaggiamento non piu' valido (Ultimate di livello 100 a un livello basso, mossa inesistente)
	var bad_equip: Dictionary = good.duplicate(true)
	bad_equip["equip"]["lance"]["ult"] = "u_lance_ult5"
	bad_equip["equip"]["nox"]["skill"] = "mossa_che_non_esiste"
	check(not Progress.validate_save(bad_equip), "il validatore severo resta severo")
	var fixed: Variant = Progress.repair_save(bad_equip)
	check(fixed != null, "equipaggiamento non valido: la partita si ripara")
	if fixed != null:
		check(str(fixed["equip"]["lance"]["ult"]) == str(Progress.default_equip("lance")["ult"]), "lo slot non valido torna a quello di partenza")
		check(str(fixed["equip"]["nox"]["skill"]) == str(Progress.default_equip("nox")["skill"]), "la mossa inesistente torna a quella di partenza")
		check(int(fixed["lv"]["lance"]) == int(good["lv"]["lance"]), "il livello resta quello salvato")
		check(str(fixed["equip"]["rio"]["skill"]) == str(good["equip"]["rio"]["skill"]), "gli slot validi restano com'erano")
	# 2. chiavi e personaggi mancanti (salvataggio di una versione diversa)
	var partial: Dictionary = {"lv": {"lance": 4}, "exp": {"lance": 10}, "equip": {}}
	var fixed2: Variant = Progress.repair_save(partial)
	check(fixed2 != null and int(fixed2["lv"]["lance"]) == 4 and int(fixed2["lv"]["saul"]) == 1, "chiavi e personaggi mancanti tornano ai valori di partenza")
	# 3. valori fuori limite rientrano, mosse rubate sconosciute si tolgono
	var out_of_range: Dictionary = good.duplicate(true)
	out_of_range["lv"]["lance"] = Progress.MAX_LEVEL + 5
	out_of_range["exp"]["nox"] = 999999
	out_of_range["stolen"] = ["mossa_rubata_sparita"]
	out_of_range["stolen_from"] = {"mossa_rubata_sparita": "Nessuno"}
	var fixed3: Variant = Progress.repair_save(out_of_range)
	check(fixed3 != null and int(fixed3["lv"]["lance"]) == Progress.MAX_LEVEL and int(fixed3["exp"]["lance"]) == 0, "livello oltre il massimo riportato al massimo")
	check(fixed3 != null and int(fixed3["exp"]["nox"]) < Progress.exp_need(int(fixed3["lv"]["nox"])), "esperienza oltre la soglia riportata sotto")
	check(fixed3 != null and (fixed3["stolen"] as Array).is_empty() and (fixed3["stolen_from"] as Dictionary).is_empty(), "mosse rubate sconosciute tolte")
	# 4. dati davvero rotti: si rifiuta (il caricatore prova il backup)
	var broken: Dictionary = good.duplicate(true)
	broken["lv"]["lance"] = "dieci"
	check(Progress.repair_save(broken) == null, "livello testuale: dato rotto, rifiutato")
	broken["lv"]["lance"] = NAN
	check(Progress.repair_save(broken) == null, "livello non finito: rifiutato")
	check(Progress.repair_save("non un dizionario") == null, "progressione non dizionario: rifiutata")
	# 5. intero file: si carica riparato invece di "SALVATAGGIO NON LEGGIBILE"
	_remove_save_files()
	var cfg := ConfigFile.new()
	cfg.set_value("storia", "capitolo", 1)
	cfg.set_value("storia", "passo", 0)
	cfg.set_value("storia", "flag", {})
	cfg.set_value("squadra", "dati", bad_equip)
	cfg.save(Story.save_path)
	check(Story.load_game(), "un salvataggio con equipaggiamento non valido si carica")
	check(Progress.level("lance") == int(good["lv"]["lance"]), "dopo il caricamento il livello e' quello salvato")
	check(str(Progress.data["equip"]["lance"]["ult"]) == str(Progress.default_equip("lance")["ult"]), "dopo il caricamento lo slot e' riparato")
	Progress.reset()


# 0.59: gli id di Lance e Rio erano "ferri" e "zecca". Un salvataggio di prima si carica con gli id nuovi.
func _test_old_ids() -> void:
	Progress.reset()
	Progress.grant(400)
	var d: Dictionary = Progress.data.duplicate(true)
	var old: Dictionary = {}
	for k in d:
		if d[k] is Dictionary:
			var m: Dictionary = {}
			for c in d[k]:
				var key: String = "ferri" if c == "lance" else ("zecca" if c == "rio" else str(c))
				var val: Variant = d[k][c]
				if val is Dictionary:
					var eq: Dictionary = {}
					for slot in val:
						eq[slot] = str(val[slot]).replace("lance", "ferri").replace("rio", "zecca") if val[slot] is String else val[slot]
					val = eq
				m[key] = val
			old[k] = m
		else:
			old[k] = d[k]
	_remove_save_files()
	var cfg := ConfigFile.new()
	cfg.set_value("storia", "capitolo", 1)
	cfg.set_value("storia", "passo", 0)
	cfg.set_value("storia", "flag", {"visto_ferri": true, "parla": "zecca"})
	cfg.set_value("squadra", "dati", old)
	cfg.save(Story.save_path)
	check(old["lv"].has("ferri") and not old["lv"].has("lance"), "la prova usa davvero gli id vecchi")
	check(Story.load_game(), "un salvataggio con gli id vecchi si carica")
	check(Progress.level("lance") == int(d["lv"]["lance"]) and Progress.level("rio") == int(d["lv"]["rio"]), "i livelli di Lance e Rio passano agli id nuovi")
	check(str(Progress.data["equip"]["lance"]["ult"]) == str(d["equip"]["lance"]["ult"]), "l'equipaggiamento di Lance resta quello salvato")
	check(Story.flags.has("visto_lance") and str(Story.flags.get("parla", "")) == "rio", "anche i flag della storia usano gli id nuovi")
	check(str(Story.migrate_ids("ferrivecchi")) == "ferrivecchi", "le parole che contengono il vecchio id non cambiano")
	Progress.reset()
