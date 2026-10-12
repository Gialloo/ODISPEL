extends SceneTree

# Icone e nuovo archivio operatori (griglia, anteprima squadra, ritratto in equipaggiamento).
#   godot --headless --path . -s res://tests/unit/test_icons.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_icons_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _run() -> void:
	# ogni mossa ha un'icona conosciuta
	var all_known: bool = true
	for id in BattleContent.MOVES:
		all_known = all_known and GameIcon.KEYS.has(GameIcon.move_key(str(id)))
	_check("ogni mossa ha un'icona", all_known)
	_check("barriera = scudo", GameIcon.move_key("barriera") == "shield")
	_check("cura = croce", GameIcon.move_key("cura") == "heal")
	_check("ricarica = proiettile", GameIcon.move_key("ricarica") == "bullet")
	_check("marchio = mirino", GameIcon.move_key("marchio") == "target")
	_check("provoca = megafono", GameIcon.move_key("provoca") == "taunt")
	_check("ultimate = esplosione", GameIcon.move_key("spezzatutto") == "burst")
	_check("attacco = spada", GameIcon.move_key("attack") == "sword")
	var classes_ok: bool = true
	for c in BattleContent.CLASS_STATS:
		classes_ok = classes_ok and GameIcon.KEYS.has(str(c))
	_check("ogni classe ha un'icona", classes_ok)
	var fac_ok: bool = true
	for f in Factions.ORDER:
		fac_ok = fac_ok and GameIcon.faction_key(str(f)) != ""
	_check("ogni fazione ha un'icona", fac_ok)
	_check("equipaggiamento: tre pezzi", GameIcon.gear_key("arma") == "arma" and GameIcon.gear_key("petto") == "petto" and GameIcon.gear_key("stivali") == "stivali" and GameIcon.gear_key("skill0") == "")
	_check("valute: tre icone", GameIcon.KEYS.has("coin") and GameIcon.KEYS.has("nucleo") and GameIcon.KEYS.has("lega"))

	# disegna tutte le icone senza errori
	var holder := Control.new()
	holder.size = Vector2(400, 400)
	root.add_child(holder)
	for k in GameIcon.KEYS:
		holder.add_child(GameIcon.new().setup(str(k), Color.WHITE, 32.0))
	await process_frame
	await process_frame
	_check("tutte le icone si disegnano", holder.get_child_count() == GameIcon.KEYS.size())
	var b := Button.new()
	b.text = "ATTACCO"
	holder.add_child(b)
	GameIcon.attach(b, "sword", Color.WHITE, 20.0)
	_check("icona su pulsante: testo spostato", b.text.ends_with("ATTACCO") and b.text.length() > 7 and b.get_child_count() == 1)
	holder.queue_free()

	# archivio operatori
	var r: Dictionary = RosterState.new_roster()
	var scene: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	scene.roster = r
	scene.save_path = TMP
	root.add_child(scene)
	await process_frame
	_check("griglia: 13 mattonelle in 5 colonne", scene._list_box.get_child_count() == 13 and scene._list_box.columns == 5)
	_check("squadra: 3 carte", scene._slots_box.get_child_count() == 3)
	var icons_in_card: int = 0
	for c in scene._slots_box.get_child(0).get_children():
		if c is GameIcon:
			icons_in_card += 1
	_check("carta del posto: icone di classe e fazione", icons_in_card == 2)
	_check("scheda: icone accanto al nome", scene._detail_icons.get_child_count() == 2)
	scene.show_tab("equip")
	await process_frame
	_check("equip: ritratto dell'operatore modificato", scene._equip_portrait.char_id == scene.selected and scene._equip_portrait.char_id != "")
	_check("equip: icone di classe e fazione", scene._equip_icons.get_child_count() == 2)
	var slot_icons: bool = true
	for sb in scene._equip_slots_box.get_children():
		var has: bool = false
		for c in sb.get_children():
			has = has or c is GameIcon
		slot_icons = slot_icons and has
	_check("equip: ogni slot ha la sua icona", slot_icons)
	var cur: String = scene.selected
	scene.cycle_char(1)
	await process_frame
	_check("equip: cambiando operatore cambia il ritratto", scene._equip_portrait.char_id == scene.selected and scene.selected != cur)
	scene.queue_free()
	if FileAccess.file_exists(ProjectSettings.globalize_path(TMP)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
