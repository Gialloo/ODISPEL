extends Control

# FINE DELL'ATTO 1: riepilogo delle scelte e dei legami, poi menu o ricomincia.

func configure(_args: Dictionary) -> void:
	pass


func crumb() -> String:
	return "fine"


func _ready() -> void:
	Breadcrumb.mark("fine")
	position = Vector2.ZERO
	size = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = Color("#140b24")
	Ui.place(bg, 0, 0, 1, 1)
	add_child(bg)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	Ui.place(vb, 0.1, 0.08, 0.9, 0.92)
	add_child(vb)
	var rep: int = Story.replica()
	vb.add_child(Ui.label("FINE DELL'ATTO 1" + (" · REPLICA %d" % rep if rep > 0 else ""), 44 if rep > 0 else 56, Ui.YELLOW, Ui.display(), 10))
	vb.add_child(Ui.label("Grazie per aver giocato. Dimmi cosa correggere: ritmo, battute, combattimenti, cosa ti ha annoiato.", 22, Ui.CREAM))
	var bonds: Array = []
	for bd in Story.active_bonds():
		bonds.append(str(bd.get("nome", "")))
	vb.add_child(Ui.label("Legami: " + (", ".join(bonds) if not bonds.is_empty() else "nessuno"), 22, Ui.PINK))
	var picks: Array = []
	if Story.has_flag("echo_fiducia"):
		picks.append("Ti sei fidato di Echo")
	if Story.has_flag("echo_diffidenza"):
		picks.append("Hai tenuto d'occhio Echo")
	if Story.has_flag("echo_tregua"):
		picks.append("Hai concesso una tregua a Echo")
	if Story.has_flag("echo_rancore"):
		picks.append("Echo vi guida, ma non è dei vostri")
	if Story.has_flag("saul_leale"):
		picks.append("Saul ha detto tutto agli altri")
	if Story.has_flag("saul_tentato"):
		picks.append("Saul ha tenuto la telefonata per sé")
	vb.add_child(Ui.label("Scelte: " + (" · ".join(picks) if not picks.is_empty() else "nessuna"), 22, Ui.CYAN))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	vb.add_child(hb)
	var a := Ui.button("MENU", Ui.YELLOW, 26, 240)
	a.pressed.connect(func() -> void: get_parent().go("menu"))
	hb.add_child(a)
	var b2 := Ui.button("RICOMINCIA", Ui.CREAM, 24, 260)
	b2.pressed.connect(func() -> void:
		Story.new_game()
		get_parent().next_story())
	hb.add_child(b2)
	var b3 := Ui.button("REPLICA DELLA DIRETTA", Ui.PINK, 24, 380)
	b3.pressed.connect(func() -> void:
		Story.new_replica()
		get_parent().next_story())
	hb.add_child(b3)
	vb.add_child(Ui.label("Rigiochi l'atto coi legami stretti, scelte da rifare, nemici più duri.", 20, Ui.CREAM))


func back() -> void:
	get_parent().go("menu")
