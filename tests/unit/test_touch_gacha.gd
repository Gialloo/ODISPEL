extends SceneTree

# Modalita' touch, guida al reclutamento, forza per rarita'.
#   godot --headless --path . -s res://tests/unit/test_touch_gacha.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_touch_gacha_settings.cfg"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _stats(char_id: String) -> Dictionary:
	return BattleContent.compute_stats(BattleContent.default_entry(char_id, 1, 0))


func _run() -> void:
	await process_frame

	# --- rarita': quote e forza
	var odds: Array = BattleContent.rarity_odds()
	_check("quote: 55/30/12/3", odds == [55, 30, 12, 3])
	var total: int = 0
	for v in odds:
		total += int(v)
	_check("quote: sommano 100", total == 100)
	var rng := RNGState.new()
	rng.setup(12345)
	var counts: Array = [0, 0, 0, 0]
	for i in 4000:
		counts[BattleContent.roll_rarity(rng)] += 1
	_check("tiri: la comune e' la piu' frequente, la leggendaria la piu' rara",
		counts[0] > counts[1] and counts[1] > counts[2] and counts[2] > counts[3] and counts[3] > 0)
	var mult: Array = BattleContent.RARITY_STAT_MULT
	_check("moltiplicatori: crescono con la rarita'", mult[0] == 1.0 and mult[1] > mult[0] and mult[2] > mult[1] and mult[3] > mult[2])
	_check("moltiplicatori: uno per rarita'", mult.size() == BattleTypes.RARITIES.size())

	# stessa classe, rarita' diverse -> piu' rara = piu' forte
	var rex: Dictionary = _stats("rex")      # striker comune
	var kira: Dictionary = _stats("kira")    # striker rara
	_check("raro piu' forte del comune (striker)", int(kira["hp"]) > int(rex["hp"]) and int(kira["atk"]) > int(rex["atk"]))
	var dax: Dictionary = _stats("dax")      # vanguard comune
	var tana: Dictionary = _stats("tana")    # vanguard leggendaria
	_check("leggendario piu' forte del comune (vanguard)", int(tana["hp"]) > int(dax["hp"]) and int(tana["atk"]) > int(dax["atk"]) and int(tana["def"]) > int(dax["def"]))
	var elle: Dictionary = _stats("elle")    # warden comune
	var sera: Dictionary = _stats("sera")    # warden epica
	_check("epico piu' forte del comune (warden)", int(sera["hp"]) > int(elle["hp"]))
	var gear_prev: float = 0.0
	var gear_ok: bool = true
	for m in BattleContent.GEAR_RARITY_MULT:
		gear_ok = gear_ok and float(m) > gear_prev
		gear_prev = float(m)
	_check("equipaggiamento: forza cresce con la rarita'", gear_ok)

	# --- guida al reclutamento
	var pages: Array = GachaGuide.pages()
	_check("guida: 4 pagine", pages.size() == 4)
	var text: String = ""
	for p in pages:
		for l in p["lines"]:
			text += str(l["text"]) + "\n"
	_check("guida: spiega monete, nuclei e leghe", text.contains("MONETE") and text.contains("NUCLEI") and text.contains("LEGHE"))
	_check("guida: riporta le quote reali", text.contains("55%") and text.contains("30%") and text.contains("12%") and text.contains("3%"))
	_check("guida: riporta i costi", text.contains(str(Recruiting.SINGLE_COST)) and text.contains(str(Recruiting.TEN_COST)))
	_check("guida: riporta la garanzia", text.contains(str(Recruiting.PITY_LIMIT)))
	var all_named: bool = true
	for id in BattleContent.CHARACTERS:
		all_named = all_named and text.contains(str(BattleContent.CHARACTERS[id]["name"]))
	_check("guida: elenca tutti gli operatori", all_named)

	var host := Control.new()
	root.add_child(host)
	var g: GachaGuide = GachaGuide.open(host)
	await process_frame
	_check("guida: parte dalla prima pagina, 'indietro' spento", g.page == 0 and g._prev.disabled and not g._next.disabled)
	g.show_page(1, true)
	g.show_page(1, true)
	g.show_page(1, true)
	g.show_page(1, true)
	_check("guida: non esce dalle pagine", g.page == 3 and g._next.disabled)
	var closed_flag: Array = [false]
	g.closed.connect(func(): closed_flag[0] = true)
	var saved_path: String = Settings.path
	Settings.path = TMP
	Settings.gacha_guide_seen = false
	g._close()
	_check("guida: chiudendo si segna come vista", closed_flag[0] and Settings.gacha_guide_seen)
	Settings.gacha_guide_seen = false
	Settings.load_settings()
	_check("guida: 'vista' resta salvata", Settings.gacha_guide_seen)
	_check("guida: nei test (senza schermo) non si apre da sola", not Settings.should_show_gacha_guide())
	Settings.gacha_guide_seen = false
	Settings.path = saved_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))

	# --- pagina reclutamento
	var roster := RosterState.new_roster()
	var screen: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	screen.roster = roster
	screen.save_path = "user://test_touch_gacha_roster.json"
	root.add_child(screen)
	await process_frame
	screen.show_tab("reclutamento")
	_check("reclutamento: bottone COME FUNZIONA", screen.guide_button != null)
	var g1: GachaGuide = screen.open_gacha_guide()
	var g2: GachaGuide = screen.open_gacha_guide()
	_check("reclutamento: una sola guida aperta", g1 == g2 and g1 != null)
	g1.queue_free()
	await process_frame
	screen.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_touch_gacha_roster.json"))

	# --- touch
	TouchUi.force = false
	var pc: Button = Button.new()
	BattleTheme.style_button(pc, "normal", 16)
	_check("PC: bottone invariato", pc.custom_minimum_size.y == 0.0 and pc.get_theme_font_size("font_size") == 16)
	TouchUi.force = true
	var tb: Button = Button.new()
	tb.custom_minimum_size = Vector2(0, 30)
	BattleTheme.style_button(tb, "normal", 14)
	_check("touch: altezza minima", tb.custom_minimum_size.y >= TouchUi.MIN_HEIGHT)
	_check("touch: testo minimo", tb.get_theme_font_size("font_size") >= TouchUi.MIN_FONT)
	var big: Button = Button.new()
	big.custom_minimum_size = Vector2(0, 120)
	BattleTheme.style_button(big, "normal", 30)
	_check("touch: non rimpicciolisce i bottoni gia' grandi", big.custom_minimum_size.y == 120.0 and big.get_theme_font_size("font_size") == 30)
	var scr: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scr)
	await process_frame
	await process_frame
	var all_big: bool = scr._order_buttons.size() >= 3
	for ob in scr._order_buttons:
		all_big = all_big and (ob as Button).custom_minimum_size.y >= TouchUi.MIN_HEIGHT
	_check("touch: ordini di battaglia grandi", all_big)
	scr.queue_free()
	TouchUi.force = false

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
