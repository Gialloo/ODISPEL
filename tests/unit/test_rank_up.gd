extends SceneTree

# RANK UP manuale con le copie e potenziamenti del kit per rank (scalati sulla rarita').
#   godot --headless --path . -s res://tests/unit/test_rank_up.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _unit(id: String, rank: int) -> Dictionary:
	var st: Dictionary = BattleState.create([{"id": "p", "name": "P", "team": [BattleContent.default_entry(id, 1, rank)]}], "distributore", 5, 0)
	return BattleState.unit(st, BattleState.unit_id("p", id))


func _run() -> void:
	var r: Dictionary = RosterState.new_roster()
	_check("all'inizio nessuna copia", RosterState.copies(r, "kira") == 0)
	_check("una copia si conserva", RosterState.add_character(r, "kira") == "copy" and RosterState.copies(r, "kira") == 1)
	_check("il rank non sale da solo", int(r["characters"]["kira"]["rank"]) == 0)
	_check("con 1 copia si sale a rank 1", RosterState.can_rank_up(r, "kira") and RosterState.rank_up(r, "kira") and int(r["characters"]["kira"]["rank"]) == 1)
	_check("la copia e' stata spesa", RosterState.copies(r, "kira") == 0)
	_check("senza copie non si sale", not RosterState.rank_up(r, "kira") and int(r["characters"]["kira"]["rank"]) == 1)
	RosterState.add_character(r, "kira")
	_check("rank 2 costa 1 copia", RosterState.rank_cost(1) == 1 and RosterState.rank_up(r, "kira"))
	RosterState.add_character(r, "kira")
	_check("rank 3 ne costa 2: una non basta", RosterState.rank_cost(2) == 2 and not RosterState.rank_up(r, "kira"))
	RosterState.add_character(r, "kira")
	_check("con 2 copie si sale a rank 3", RosterState.rank_up(r, "kira") and int(r["characters"]["kira"]["rank"]) == 3 and RosterState.copies(r, "kira") == 0)
	var total: int = 0
	for c in RosterState.RANK_COPY_COST:
		total += int(c)
	_check("copie totali per il rank massimo", total == 9)
	_check("non posseduto: niente rank up", not RosterState.rank_up(r, "tana") and not RosterState.can_rank_up(r, "tana"))
	# rank massimo: la copia diventa monete
	r["characters"]["dax"]["rank"] = RosterState.MAX_RANK
	_check("a rank massimo la copia e' 'max'", RosterState.add_character(r, "dax") == "max")
	_check("rank massimo: non si sale oltre", not RosterState.rank_up(r, "dax"))
	# le copie non finiscono nella squadra di battaglia
	RosterState.add_character(r, "dax")
	RosterState.add_character(r, "elle")
	for e in RosterState.team_entries(r):
		_check("squadra di battaglia senza copie (%s)" % str(e["char"]), not e.has("copies"))
	_check("salvataggio valido con copie", RosterState.validate(r) == "")

	# bonus statistici per rarita'
	_check("bonus rank per rarita'", BattleContent.rank_bonus(0) == 0.04 and BattleContent.rank_bonus(1) == 0.05 and BattleContent.rank_bonus(2) == 0.06 and BattleContent.rank_bonus(3) == 0.08)

	# potenziamenti del kit
	_check("grado skill 1: rank 0=0, 1=1, 2=1, 4=2", Signatures.skill_grade(1, 0) == 0 and Signatures.skill_grade(1, 1) == 1 and Signatures.skill_grade(1, 2) == 1 and Signatures.skill_grade(1, 4) == 2)
	_check("grado skill 2: rank 1=0, 2=1, 3=1, 4=2", Signatures.skill_grade(2, 1) == 0 and Signatures.skill_grade(2, 2) == 1 and Signatures.skill_grade(2, 3) == 1 and Signatures.skill_grade(2, 4) == 2)
	_check("grado ultimate: rank 2=0, 3=1, 4=1, 5=2", Signatures.ult_grade(2) == 0 and Signatures.ult_grade(3) == 1 and Signatures.ult_grade(4) == 1 and Signatures.ult_grade(5) == 2)
	_check("skill 1 e 2 di un operatore con due uniche", Signatures.skill_slot("sera", "u_sera_a") == 1 and Signatures.skill_slot("sera", "u_sera_b") == 2)
	_check("skill 2 di chi ha una sola unica = la skill di base", Signatures.skill_slot("nova", "u_nova_a") == 1 and Signatures.skill_slot("nova", "marchio") == 2)
	_check("mossa estranea al kit: nessun grado", Signatures.skill_slot("nova", "cura") == 0)
	var k0: Dictionary = _unit("nova", 0)
	var k1: Dictionary = _unit("nova", 1)
	_check("rank 0: nessun potenziamento", Signatures.upgrade_mult(k0, "u_nova_a", "skill") == 1.0 and Signatures.upgrade_mult(k0, "spezzatutto", "ult") == 1.0)
	_check("rank 1 rara: skill 1 +10%", is_equal_approx(Signatures.upgrade_mult(k1, "u_nova_a", "skill"), 1.10) and Signatures.upgrade_mult(k1, "marchio", "skill") == 1.0)
	var k2: Dictionary = _unit("nova", 2)
	_check("rank 2: ora anche la skill 2", is_equal_approx(Signatures.upgrade_mult(k2, "marchio", "skill"), 1.10))
	_check("rank 2: l'ultimate no", Signatures.upgrade_mult(k2, "spezzatutto", "ult") == 1.0)
	var k3: Dictionary = _unit("nova", 3)
	_check("rank 3 rara: ultimate +12%", is_equal_approx(Signatures.upgrade_mult(k3, "spezzatutto", "ult"), 1.12))
	var k4: Dictionary = _unit("nova", 4)
	_check("rank 4: skill 1 e 2 a +20%", is_equal_approx(Signatures.upgrade_mult(k4, "u_nova_a", "skill"), 1.20) and is_equal_approx(Signatures.upgrade_mult(k4, "marchio", "skill"), 1.20))
	var k5: Dictionary = _unit("nova", 5)
	_check("rank 5 rara: ultimate +24%", is_equal_approx(Signatures.upgrade_mult(k5, "spezzatutto", "ult"), 1.24))
	_check("rank 5: risveglio con carica di partenza", bool(k5["awake"]))
	# piu' raro = piu' potenziamento
	var d4: Dictionary = _unit("dax", 4)
	var t4: Dictionary = _unit("tana", 4)
	_check("comune rank 4: +16%", is_equal_approx(Signatures.upgrade_mult(d4, "u_dax_a", "skill"), 1.16))
	_check("leggendaria rank 4: +30%", is_equal_approx(Signatures.upgrade_mult(t4, "u_tana_a", "skill"), 1.30))
	_check("ultimate leggendaria rank 5: +40%", is_equal_approx(Signatures.upgrade_mult(_unit("tana", 5), "bastione", "ult"), 1.40))

	# nel motore: lo stesso colpo fa piu' danno col rank
	var base_dmg: int = _dmg(0)
	var up_dmg: int = _dmg(1)
	_check("la skill potenziata fa piu' danno (rank 1 > rank 0)", up_dmg > base_dmg)

	# testi
	_check("testo rank 1", Signatures.rank_upgrade_text("nova", 1).begins_with("SKILL 1 POTENZIATA: RAFFICA MARCHIANTE"))
	_check("testo rank 3", Signatures.rank_upgrade_text("nova", 3).begins_with("ULTIMATE POTENZIATA"))
	_check("prossimo traguardo", Signatures.next_milestone("nova", 0).begins_with("RANK 1:") and Signatures.next_milestone("nova", 5) == "")

	# Angela: il drone potenziato da' piu' munizioni alla squadra
	var a3: Dictionary = _unit("angela", 4)
	_check("Angela: skill 1 = Drone munizioni potenziata a rank 4", Signatures.upgrade_grade(a3, "u_angela_b", "skill") == 2)


func _dmg(rank: int) -> int:
	var st: Dictionary = BattleState.create([{"id": "p", "name": "P", "team": [BattleContent.default_entry("nova", 1, rank)]}], "distributore", 5, 0)
	var actor: Dictionary = BattleState.unit(st, BattleState.unit_id("p", "nova"))
	actor["energy"] = 5
	var boss: Dictionary = BattleState.boss(st)
	boss["hp"] = 999999
	boss["max_hp"] = 999999
	var ev: Array = []
	BattleResolver._player_act(st, actor, "u_nova_a", "", ev)
	var total: int = 0
	for e in ev:
		if str(e["t"]) == "damage":
			total += int(e["amount"])
	return total
