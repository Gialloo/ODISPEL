extends SceneTree

# Schermata squadra: scheda equipaggiamento (mosse, passive, pezzi).
#
#   godot --headless --path . -s res://tests/unit/test_equip_ui.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_equip_ui_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _make() -> Control:
	var r: Dictionary = RosterState.new_roster()
	r["coins"] = 5000
	r["materials"] = {"nucleo": 20, "lega": 20}
	RosterState.add_drop(r, {"kind": "move", "id": "marchio"})
	RosterState.add_drop(r, {"kind": "move", "id": "cura"})
	RosterState.add_drop(r, {"kind": "move", "id": "spezzatutto"})
	RosterState.add_drop(r, {"kind": "passive", "id": "p_atk"})
	RosterState.add_drop(r, {"kind": "passive", "id": "p_hunter"})
	RosterState.new_gear(r, "arma", 1)
	RosterState.new_gear(r, "arma", 0)
	RosterState.new_gear(r, "petto", 2)
	var scene: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	scene.roster = r
	scene.save_path = TMP
	root.add_child(scene)
	return scene


func _enabled(box: Node) -> int:
	var n: int = 0
	for b in box.get_children():
		if b is Button and not b.disabled:
			n += 1
	return n


func _run() -> void:
	var s: Control = _make()
	await process_frame
	s.show_tab("equip")
	_check("pagina equipaggio", s._equip_page.visible and not s._team_page.visible)
	_check("8 slot", s._equip_slots_box.get_child_count() == 8)
	_check("operatore mostrato", s._equip_name.text.begins_with("KIRA"))

	# skill: slot 1 ha gia' colpo caricato; si aggiunge marchio al secondo
	s.select_equip_slot("skill1")
	_check("elenco skill con voci", s._equip_list.get_child_count() >= 3)
	_check("equipaggio marchio nel secondo slot", s.equip_item("marchio"))
	_check("kira ha 2 skill", s.roster["characters"]["kira"]["skills"] == ["colpo_caricato", "marchio"])
	_check("lo slot mostra la skill", s._equip_slots_box.get_child(1).text.contains("MARCHIO"))
	_check("la stessa skill due volte e' rifiutata", not s.equip_item("colpo_caricato"))
	_check("il messaggio spiega perche'", s.status_text.contains("Gia'"))
	_check("svuotare lo slot", s.equip_item("") and s.roster["characters"]["kira"]["skills"].size() == 1)
	s.select_equip_slot("skill0")
	_check("cambiare skill nel primo slot", s.equip_item("marchio") and s.roster["characters"]["kira"]["skills"][0] == "marchio")

	# nessuna copia libera: cura e' di elle (innata) + 1 drop = 2 copie
	s.cycle_char(1)
	_check("cambio operatore", s.selected != "kira")
	s.select_equip_slot("ult")
	_check("elenco ultimate", s._equip_list.get_child_count() >= 1)
	# la sola copia di spezzatutto e' di Kira (innata) piu' il drop: una e' libera,
	# poi un secondo operatore la prende e la terza richiesta non ha copie
	var free_before: int = int(s.roster["moves"]["spezzatutto"]) - RosterState._used(s.roster, "ult", "spezzatutto")
	_check("ultimate: calcolo delle copie libere coerente", free_before >= 0)
	s.cycle_char(-1)
	_check("si torna a kira", s.selected == "kira")
	s.select_equip_slot("ult")
	_check("ultimate libera equipaggiata", s.equip_item("spezzatutto"))

	# passive
	s.select_equip_slot("passive1")
	_check("seconda passiva", s.equip_item("p_hunter") and s.roster["characters"]["kira"]["passives"].size() == 2)
	s.select_equip_slot("passive1")
	s.equip_item("")
	_check("svuotare lo slot 2 lascia una sola passiva", s.roster["characters"]["kira"]["passives"].size() == 1)
	s.roster["characters"]["kira"]["passives"] = []
	_check("slot 2 con il primo vuoto: errore chiaro", not s.equip_item("p_atk") and s.status_text.contains("precedente"))
	s.roster["characters"]["kira"]["passives"] = ["p_atk"]
	s.equip_item("p_hunter")
	s.select_equip_slot("passive0")
	_check("la stessa passiva nell'altro slot rifiutata", not s.equip_item("p_hunter"))
	_check("svuota passiva", s.equip_item("") and s.roster["characters"]["kira"]["passives"].size() == 1)

	# pezzi
	s.select_equip_slot("arma")
	_check("elenco armi (svuota + 2 pezzi)", s._equip_list.get_child_count() == 3)
	var atk0: int = int(BattleContent.compute_stats(s.roster["characters"]["kira"])["atk"])
	_check("equipaggio un'arma", s.equip_item("g1") and s.gear_in_slot("kira", "arma") == "g1")
	_check("le statistiche salgono", int(BattleContent.compute_stats(s.roster["characters"]["kira"])["atk"]) > atk0)
	_check("la scheda mostra il pezzo", s._equip_slots_box.get_child(5).text.contains("RARA"))
	_check("l'altra arma sostituisce la prima", s.equip_item("g2") and s.gear_in_slot("kira", "arma") == "g2" and s.roster["gear"]["g1"]["equipped_by"] == "")
	_check("pezzo di un altro slot rifiutato", not s.equip_item("g3"))
	_check("c'e' il pulsante di potenziamento", s._equip_action.get_child_count() == 1)
	var lv0: int = int(s.roster["gear"]["g2"]["level"])
	_check("potenziamento pezzo", s.upgrade_gear("g2") and int(s.roster["gear"]["g2"]["level"]) == lv0 + 1)
	_check("statistiche del personaggio aggiornate", s.roster["characters"]["kira"]["gear"][0]["level"] == lv0 + 1)
	s.roster["materials"] = {}
	_check("senza leghe il potenziamento e' rifiutato", not s.upgrade_gear("g2") and s.status_text.contains("Leghe"))
	_check("togli il pezzo", s.equip_item("") and s.gear_in_slot("kira", "arma") == "")

	# un pezzo passa da un personaggio all'altro
	s.equip_item("g1")
	s.select("dax")
	s.cycle_char(0)
	s.selected = "dax"
	s.select_equip_slot("arma")
	s.refresh()
	_check("il pezzo di kira compare con l'indicazione", s._equip_list.get_child(1).text.contains("KIRA") or s._equip_list.get_child(2).text.contains("KIRA"))
	_check("dax prende il pezzo", s.equip_item("g1") and s.gear_in_slot("dax", "arma") == "g1" and s.gear_in_slot("kira", "arma") == "")

	_check("collezione valida", RosterState.validate(s.roster) == "")
	var saved: Dictionary = RosterStore.load_or_new(TMP)
	_check("tutto salvato", saved["characters"]["dax"]["gear"].size() == 1)

	# il percorso dalla scheda squadra
	s.show_tab("squadra")
	var has_btn: bool = false
	for b in s._action_box.get_children():
		if b is Button and b.text == "EQUIPAGGIO":
			has_btn = true
	_check("dalla scheda squadra si arriva all'equipaggio", has_btn)

	s.queue_free()
	var path: String = ProjectSettings.globalize_path(TMP)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
