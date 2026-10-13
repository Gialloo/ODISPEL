extends SceneTree

# Quarto boss (Cabina), obiettivi giornalieri, apertura del reclutamento, menu animati.
#   godot --headless --path . -s res://tests/unit/test_objectives_cabina.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame

	# --- Cabina
	var b: Dictionary = BattleContent.BOSSES["cabina"]
	_check("cabina viene dopo il tombino", BattleContent.BOSS_ORDER.find("cabina") == BattleContent.BOSS_ORDER.find("tombino") + 1)
	var all_moves: bool = true
	for m in b["cycle"]:
		if not BattleContent.BOSS_MOVES.has(str(m)):
			all_moves = false
	_check("tutte le mosse della cabina esistono", all_moves)
	_check("la cabina ha un colore valido", BattleTheme.UNIT_COLORS.has(str(b["color"])))
	_check("premi della cabina > tombino", int(b["reward"]["coins"]) > int(BattleContent.BOSSES["tombino"]["reward"]["coins"]))
	var r: Dictionary = RosterState.new_roster()
	for id in ["distributore", "semaforo"]:
		RosterState.mark_cleared(r, id, 0)
	_check("cabina chiusa finche' non batti il tombino", not RosterState.is_boss_unlocked(r, "cabina"))
	RosterState.mark_cleared(r, "tombino", 0)
	_check("battere il tombino apre la cabina", RosterState.is_boss_unlocked(r, "cabina"))
	_check("novita': nuovo bersaglio cabina", RosterState.unlock_news("tombino", 0).any(func(l: String) -> bool: return l.contains("CABINA")))
	var team: Array = []
	for id in ["kira", "dax", "elle"]:
		team.append(BattleContent.default_entry(id, 10, 0))
	var st: Dictionary = BattleState.create_solo("IO", team, [], "cabina", 5, 2, 1)
	var steps: int = 0
	while str(st["winner"]) == "" and steps < 80:
		BattleResolver.autoplay_round(st)
		steps += 1
	_check("una battaglia contro la cabina si conclude", str(st["winner"]) != "")
	var back: Dictionary = BattleState.from_json(BattleState.to_json(st))
	_check("stato della cabina serializzabile", str(BattleState.boss(back)["char"]) == "cabina")

	# --- Obiettivi
	var ro: Dictionary = RosterState.new_roster()
	_check("primo giorno: obiettivi nuovi", Objectives.ensure_today(ro, "2026-10-12"))
	_check("stesso giorno: invariati", not Objectives.ensure_today(ro, "2026-10-12"))
	var list: Array = ro["objectives"]["list"]
	_check("tre obiettivi", list.size() == 3)
	var kinds: Dictionary = {}
	for o in list:
		kinds[str(o["kind"])] = true
	_check("tipi diversi", kinds.size() == 3)
	var ro2: Dictionary = RosterState.new_roster()
	Objectives.ensure_today(ro2, "2026-10-12")
	_check("stesso giorno = stessi obiettivi", JSON.stringify(ro["objectives"]) == JSON.stringify(ro2["objectives"]))
	var ro3: Dictionary = RosterState.new_roster()
	Objectives.ensure_today(ro3, "2026-10-13")
	_check("giorno nuovo: obiettivi rinnovati", ro3["objectives"]["day"] == "2026-10-13")
	_check("senza progressi niente 'vinci a difficile'", not _has_kind(ro, "win_hard"))
	var boss_goal: String = ""
	for o in list:
		if str(o["kind"]) == "win_boss":
			boss_goal = str(o["boss"])
	_check("l'obiettivo boss e' su un boss aperto", boss_goal == "" or boss_goal == "distributore")

	# giocare e vincere fa avanzare e dare il premio
	var coins0: int = int(ro["coins"])
	var done: Array = []
	for i in 3:
		done.append_array(Objectives.record_battle(ro, "distributore", 0, true, "2026-10-12"))
	_check("tre vittorie completano qualcosa", done.size() >= 2)
	_check("i premi arrivano subito", int(ro["coins"]) > coins0)
	_check("contatore obiettivi completati", Objectives.completed(ro) == done.size())
	var again: Array = Objectives.record_battle(ro, "distributore", 0, true, "2026-10-12")
	_check("un obiettivo gia' fatto non paga due volte", again.size() <= 1)
	_check("collezione ancora valida", RosterState.validate(ro) == "")
	var lost: Dictionary = RosterState.new_roster()
	Objectives.ensure_today(lost, "2026-10-12")
	Objectives.record_battle(lost, "distributore", 0, false, "2026-10-12")
	var played: int = 0
	var won: int = 0
	for o in lost["objectives"]["list"]:
		if str(o["kind"]) == "play":
			played = int(o["progress"])
		if str(o["kind"]) == "win":
			won = int(o["progress"])
	_check("la sconfitta conta come battaglia giocata ma non come vittoria", played <= 1 and won == 0)
	_check("testi leggibili", Objectives.describe(list[0]) != "" and Objectives.reward_text(list[0]["reward"]).contains("GOLD"))
	# nuovi tipi: boss diversi e INCUBO
	var rv: Dictionary = RosterState.new_roster()
	var mk: Dictionary = {"kind": "boss_variety", "boss": "", "goal": 2, "progress": 0, "done": false, "reward": {"coins": 10}, "seen": []}
	rv["objectives"] = {"day": "2026-10-12", "list": [mk]}
	Objectives.record_battle(rv, "distributore", 0, true, "2026-10-12")
	Objectives.record_battle(rv, "distributore", 0, true, "2026-10-12")
	_check("stesso boss due volte: non basta", int(mk["progress"]) == 1 and not bool(mk["done"]))
	Objectives.record_battle(rv, "semaforo", 0, true, "2026-10-12")
	_check("due boss diversi: completato", bool(mk["done"]))
	var rn: Dictionary = RosterState.new_roster()
	var nk: Dictionary = {"kind": "win_night", "boss": "", "goal": 1, "progress": 0, "done": false, "reward": {"coins": 10}}
	rn["objectives"] = {"day": "2026-10-12", "list": [nk]}
	Objectives.record_battle(rn, "distributore", 1, true, "2026-10-12")
	_check("INCUBO: difficile non basta", not bool(nk["done"]))
	Objectives.record_battle(rn, "distributore", 2, true, "2026-10-12")
	_check("INCUBO: vinto a incubo", bool(nk["done"]))
	_check("descrizioni nuove", Objectives.describe(mk).contains("2") and Objectives.describe(nk).contains("INCUBO"))
	Objectives.enabled = false
	_check("spento: niente progressi", Objectives.record_battle(RosterState.new_roster(), "distributore", 0, true).is_empty())
	Objectives.enabled = true
	var json_back: Dictionary = RosterState.from_json(RosterState.to_json(ro))
	_check("gli obiettivi sopravvivono al salvataggio", json_back.get("objectives", {}).get("day", "") == "2026-10-12")

	# --- Hub con obiettivi
	var hub: Control = load("res://scenes/hub/hub_demo.tscn").instantiate()
	hub.roster = RosterState.new_roster()
	root.add_child(hub)
	await process_frame
	await process_frame
	_check("hub: obiettivi preparati", hub.roster["objectives"]["list"].size() == 3)
	hub.queue_free()

	# --- Apertura reclutamento
	var host := Control.new()
	root.add_child(host)
	var results: Array = [
		{"char": "kira", "rarity": 1, "outcome": "new", "refund": 0},
		{"char": "tana", "rarity": 3, "outcome": "rank", "refund": 0},
		{"char": "dax", "rarity": 0, "outcome": "max", "refund": 40},
	]
	var pr: PullReveal = PullReveal.play(host, results)
	var fin: Array = [false]
	pr.finished.connect(func() -> void: fin[0] = true)
	await process_frame
	_check("apertura: parte dal primo", pr.index == 0 and str(pr.current()["char"]) == "kira")
	pr.advance()
	_check("apertura: secondo", pr.index == 1)
	pr.advance()
	pr.advance()
	_check("apertura: dopo l'ultimo c'e' il riepilogo", pr.summary)
	await process_frame
	pr.advance()
	await process_frame
	_check("apertura: si chiude", fin[0])
	var pr2: PullReveal = PullReveal.play(host, results)
	await process_frame
	pr2.skip_all()
	_check("salta: va al riepilogo", pr2.summary)
	pr2.skip_all()
	await process_frame
	var pr3: PullReveal = PullReveal.play(host, [results[0]])
	await process_frame
	pr3.advance()
	var single_ok: bool = pr3.finished_flag and not pr3.summary
	await process_frame
	_check("un solo risultato: niente riepilogo", single_ok)
	_check("colori delle rarita' diversi", PullReveal.color_of(0) != PullReveal.color_of(3))

	# --- Logo e sfondo
	var logo := OdispelLogo.new()
	host.add_child(logo)
	var back_drop: MenuBackdrop = MenuBackdrop.add_to(host, BattleTheme.RD)
	for i in 3:
		await process_frame
	_check("logo e sfondo disegnati", is_instance_valid(logo) and is_instance_valid(back_drop))

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _has_kind(ro: Dictionary, kind: String) -> bool:
	for o in ro["objectives"]["list"]:
		if str(o["kind"]) == kind:
			return true
	return false
