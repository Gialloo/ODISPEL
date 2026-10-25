extends SceneTree

# Il motore copiato dalla V2 regge una battaglia completa con i quattro protagonisti V3 contro il Distributore.

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var team: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		check(BattleContent.CHARACTERS.has(id), "manca il personaggio " + id)
		team.append(BattleContent.default_entry(id))
	check(BattleContent.CHARACTERS.has("kira"), "i dati V2 servono ancora alle abilita' uniche")
	var wins: int = 0
	for seed_value in range(1, 21):
		var b: Dictionary = BattleState.create_solo("IO", team, [], "distributore", seed_value)
		check(b["players"].size() == 4, "quattro in campo")
		var guard: int = 0
		while str(b["winner"]) == "" and guard < 60:
			guard += 1
			SeqRound.begin(b)
			for e in SeqRound.order(b):
				if str(b["winner"]) != "":
					break
				if bool(e["boss"]):
					SeqRound.boss_action(b)
				else:
					SeqRound.player_action(b, str(e["player"]), BattleAI.choose(b, str(e["player"])))
			SeqRound.finish(b)
		check(str(b["winner"]) != "", "la battaglia finisce (seed %d)" % seed_value)
		if str(b["winner"]) == "players":
			wins += 1
	print("vittorie IA: %d/20" % wins)
	check(wins >= 10, "il mini combattimento deve essere vincibile (vittorie %d/20)" % wins)
	# boss segreto di prova: porta esattamente al 50% e al 25%, ignora scudi e difesa, non uccide mai
	var c: Dictionary = BattleState.create_solo("IO", team, [], "osservatore", 3)
	for p in BattleState.alive_players(c):
		BattleState.active_unit(c, str(p["id"]))["shield"] = 500
	var seen50: bool = false
	var seen25: bool = false
	for i in 12:
		BattleResolver._camera_cut(c, BattleState.boss(c), [])
		for p in BattleState.alive_players(c):
			var u: Dictionary = BattleState.active_unit(c, str(p["id"]))
			check(int(u["hp"]) >= 1, "l'Osservatore non uccide")
			if int(u["hp"]) == int(floor(float(u["max_hp"]) * 0.5)):
				seen50 = true
			if int(u["hp"]) == int(floor(float(u["max_hp"]) * 0.25)):
				seen25 = true
	check(seen50 and seen25, "l'Osservatore porta al 50% e al 25% esatti")
	check(BattleState.alive_players(c).size() == 4, "dopo l'Osservatore sono tutti vivi")
	# l'avviso nomina chi verra' colpito davvero: la previsione coincide con i colpi
	var d: Dictionary = BattleState.create_solo("IO", team, [], "osservatore", 5)
	for i in 6:
		var want: Array = []
		for pk in BattleResolver.camera_targets(d):
			want.append(str((pk["unit"] as Dictionary)["id"]))
		var ev: Array = []
		BattleResolver._camera_cut(d, BattleState.boss(d), ev)
		var got: Array = []
		for e in ev:
			if str(e.get("t", "")) == "damage":
				got.append(str(e["dst"]))
		check(want == got, "avviso dell'Osservatore: previsti %s, colpiti %s" % [want, got])
	# salvataggio a meta' area: posizione, indizi e nemici battuti tornano dopo il caricamento
	Story.save_path = "user://salvataggio_test.cfg"
	Story.new_game()
	Story.area_state = {"pos": Vector3(1, 0.14, -7), "yaw": 0.5, "clues": ["scontrino"], "defeated": ["f1"], "banter_used": {}}
	Story.save()
	Story.area_state = {}
	Story.load_game()
	check((Story.area_state.get("clues", []) as Array).has("scontrino"), "indizi salvati a meta' area")
	check(Story.area_state.get("pos", Vector3.ZERO) == Vector3(1, 0.14, -7), "posizione salvata a meta' area")
	Story.advance()
	Story.load_game()
	check(Story.area_state.is_empty(), "passando al passo dopo lo stato dell'area si azzera")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Story.save_path))
	check(UpdateCheck.newer("0.33.2", "0.33.1") and UpdateCheck.newer("0.34.0", "0.33.9") and not UpdateCheck.newer("0.33.1", "0.33.1")
		and not UpdateCheck.newer("0.32.9", "0.33.0") and UpdateCheck.newer("1.0", "0.99.9"), "confronto delle versioni per l'aggiornamento")
	check(BrokenCam.level_for(0.9) == 0.0 and BrokenCam.level_for(0.5) > 0.0 and BrokenCam.level_for(0.25) >= 0.99, "livelli della telecamera rotta")
	# articoli dei nemici nei messaggi di battaglia
	var b3: GDScript = load("res://scripts/v3/battle3d.gd")
	for pair in [["Semaforo", "il Semaforo"], ["Cabina", "la Cabina"], ["Specchio", "lo Specchio"], ["Orologio", "l'Orologio"],
			["L'Osservatore", "l'Osservatore"], ["Sirena", "la Sirena"], ["Scala mobile", "la Scala mobile"]]:
		check(b3.article(str(pair[0])) == str(pair[1]), "articolo: %s -> %s (non %s)" % [pair[0], pair[1], b3.article(str(pair[0]))])
	_timed_guard(team)
	_kits(team)
	_fase2(team)
	print("test_v3_engine: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)


# Guardia a tempo: stesso colpo annunciato, stesso seme. La guardia riduce il danno e carica l'ultimate,
# la parata perfetta lo riduce di piu' e contrattacca il boss. Il segnale vale per un solo colpo.
func _boss_hit(team: Array, grade: String) -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", team, [], "distributore", 11)
	SeqRound.begin(s)
	s["telegraph"] = {"move": "scarica", "target": str(s["players"][0]["id"])}
	var u: Dictionary = BattleState.active_unit(s, str(s["players"][0]["id"]))
	u["gauge"] = 0
	var boss: Dictionary = BattleState.boss(s)
	var boss_hp: int = int(boss["hp"])
	if grade != "":
		s["timed_guard"] = grade
	var ev: Array = SeqRound.boss_action(s)
	var taken: int = 0
	var parry: bool = false
	for e in ev:
		if str(e.get("t", "")) == "damage" and str(e.get("dst", "")) == str(u["id"]):
			taken += int(e["amount"])
		if str(e.get("t", "")) == "parry":
			parry = true
	return {"taken": taken, "gauge": int(u["gauge"]), "boss_lost": boss_hp - int(boss["hp"]), "parry": parry, "left": s.has("timed_guard")}


func _timed_guard(team: Array) -> void:
	var none: Dictionary = _boss_hit(team, "")
	var good: Dictionary = _boss_hit(team, "good")
	var perf: Dictionary = _boss_hit(team, "perfect")
	check(none["taken"] > 0, "senza guardia il colpo fa danno")
	check(good["taken"] < none["taken"], "la guardia a tempo riduce il danno (%d contro %d)" % [good["taken"], none["taken"]])
	check(perf["taken"] < good["taken"], "la parata perfetta riduce piu' della guardia (%d contro %d)" % [perf["taken"], good["taken"]])
	check(good["gauge"] > none["gauge"] and perf["gauge"] > good["gauge"], "parare carica l'ultimate (%d, %d, %d)" % [none["gauge"], good["gauge"], perf["gauge"]])
	check(perf["parry"] and perf["boss_lost"] > 0, "la parata perfetta contrattacca")
	check(not good["parry"] and perf["boss_lost"] > none["boss_lost"], "solo la parata perfetta aggiunge un contrattacco")
	check(not good["left"] and not perf["left"], "il segnale della guardia vale per un solo colpo")


# ---------------------------------------------------------------- kit dei quattro (Kits)

func _pid(s: Dictionary, char_id: String) -> String:
	for p in s["players"]:
		if str(BattleState.active_unit(s, str(p["id"]))["char"]) == char_id:
			return str(p["id"])
	return ""


func _u(s: Dictionary, char_id: String) -> Dictionary:
	return BattleState.active_unit(s, _pid(s, char_id))


func _fresh(team: Array, seed_value: int = 5) -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", team, [], "distributore", seed_value)
	SeqRound.begin(s)
	return s


func _has(ev: Array, t: String) -> bool:
	for e in ev:
		if str(e.get("t", "")) == t:
			return true
	return false


func _dmg_to(ev: Array, uid: String) -> int:
	var n: int = 0
	for e in ev:
		if str(e.get("t", "")) == "damage" and str(e.get("dst", "")) == uid and not bool(e.get("cost", false)):
			n += int(e["amount"])
	return n


func _kits(team: Array) -> void:
	# Lance · Copertura: prende lui il colpo annunciato su Nox
	var s: Dictionary = _fresh(team)
	s["telegraph"] = {"move": "scarica", "target": _pid(s, "nox")}
	_u(s, "ferri")["energy"] = 6
	SeqRound.player_action(s, _pid(s, "ferri"), {"swap": "", "move": "u_ferri_a", "target": ""})
	var ev: Array = SeqRound.boss_action(s)
	check(_has(ev, "cover_hit"), "Copertura: Lance si mette davanti")
	check(_dmg_to(ev, str(_u(s, "nox")["id"])) == 0 and _dmg_to(ev, str(_u(s, "ferri")["id"])) > 0, "Copertura: il colpo su Nox lo prende Lance")
	check(not _u(s, "ferri").has("cover"), "Copertura: vale un solo colpo")
	# Lance · Copertura quando il colpo e' per lui: guardia
	s = _fresh(team)
	s["telegraph"] = {"move": "scarica", "target": _pid(s, "ferri")}
	_u(s, "ferri")["energy"] = 6
	SeqRound.player_action(s, _pid(s, "ferri"), {"swap": "", "move": "u_ferri_a", "target": ""})
	check(_u(s, "ferri")["statuses"].has("guard"), "Copertura su di se': Lance in guardia")
	# Lance · Braccio della Legge toglie molto equilibrio
	s = _fresh(team)
	var boss: Dictionary = BattleState.boss(s)
	var bal: int = int(boss["balance"])
	_u(s, "ferri")["gauge"] = 100
	SeqRound.player_action(s, _pid(s, "ferri"), {"swap": "", "move": "u_ferri_ult", "target": ""})
	check(bal - int(boss["balance"]) >= Kits.ARM_BALANCE or int(boss.get("stun", 0)) > 0, "Braccio della Legge: equilibrio -%d" % (bal - int(boss["balance"])))
	# Saul · Testa o croce: escono tutte e due, con il loro effetto
	var heads: int = 0
	var tails: int = 0
	for sd in range(1, 30):
		s = _fresh(team, sd)
		_u(s, "saul")["energy"] = 6
		s["telegraph"] = {"move": "scarica", "target": _pid(s, "ferri")}
		ev = SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "u_saul_a", "target": ""})
		for e in ev:
			if str(e.get("t", "")) == "coin":
				if str(e["side"]) == "testa":
					heads += 1
					var crit: bool = false
					for e2 in ev:
						crit = crit or (str(e2.get("t", "")) == "damage" and bool(e2.get("crit", false)))
					check(crit, "Testa: critico sicuro")
				else:
					tails += 1
					check(_has(ev, "energy_gift"), "Croce: energia a un compagno")
	check(heads > 3 and tails > 3, "la moneta esce da tutte e due le parti (%d testa, %d croce)" % [heads, tails])
	# Saul · Fuori dalla luce
	s = _fresh(team)
	s["telegraph"] = {"move": "scarica", "target": _pid(s, "ferri")}
	ev = SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "attack", "target": ""})
	check(_has(ev, "kit_trait"), "Fuori dalla luce quando il boss guarda Lance")
	# Saul · Il colpo grosso ruba lo scudo
	s = _fresh(team)
	boss = BattleState.boss(s)
	boss["shield"] = 400
	_u(s, "saul")["gauge"] = 100
	SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "u_saul_ult", "target": ""})
	check(int(boss["shield"]) == 0 and int(_u(s, "nox")["shield"]) >= 100, "Il colpo grosso: scudo rubato e diviso")
	# Rio · Gran finale: l'Hype conta
	var dmg: Array = []
	for hype in [0, 100]:
		s = _fresh(team)
		_u(s, "zecca")["gauge"] = 100
		_u(s, "zecca")["hype"] = hype
		ev = SeqRound.player_action(s, _pid(s, "zecca"), {"swap": "", "move": "u_zecca_ult", "target": ""})
		dmg.append(_dmg_to(ev, BattleState.BOSS_ID))
		check(int(_u(s, "zecca").get("hype", 0)) < hype or hype == 0, "Gran finale consuma l'Hype")
	check(dmg[1] > dmg[0] * 3, "Gran finale con Hype pieno fa molto di piu' (%d contro %d)" % [dmg[1], dmg[0]])
	# Rio · Hype dalla parata perfetta di un compagno
	s = _fresh(team)
	s["telegraph"] = {"move": "scarica", "target": _pid(s, "ferri")}
	s["timed_guard"] = "perfect"
	SeqRound.boss_action(s)
	check(int(_u(s, "zecca").get("hype", 0)) >= Kits.HYPE_GAIN["perfect"], "Hype dalla parata perfetta")
	# Rio · con la maschera attira i colpi singoli
	var on_rio: int = 0
	var n: int = 0
	for sd in range(1, 80):
		s = BattleState.create_solo("IO", team, [], "distributore", sd)
		var mv: Dictionary = BattleContent.BOSS_MOVES[str(s["telegraph"]["move"])]
		if str(mv["target"]) == "one":
			n += 1
			if str(s["telegraph"]["target"]) == _pid(s, "zecca"):
				on_rio += 1
	check(n > 10 and float(on_rio) / float(n) > 0.35, "la maschera attira i colpi su Rio (%d su %d)" % [on_rio, n])
	# Nox · Pausa caffe' con tutti in salute: riposo e doppio turno
	s = _fresh(team)
	_u(s, "nox")["energy"] = 4
	ev = SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "u_nox_a", "target": _pid(s, "ferri")})
	check(_has(ev, "rest") and int(_u(s, "nox")["energy"]) == 4, "Pausa caffe': Nox si riposa senza spendere")
	SeqRound.finish(s)
	SeqRound.begin(s)
	var turns: int = 0
	for e in SeqRound.order(s):
		if str(e["unit"]) == str(_u(s, "nox")["id"]):
			turns += 1
	check(turns == 2, "dopo il riposo Nox agisce due volte (%d)" % turns)
	# Nox · Pausa caffe' su un ferito: cura ed energia
	s = _fresh(team)
	_u(s, "nox")["energy"] = 4
	_u(s, "saul")["hp"] = 100
	var en_before: int = int(_u(s, "saul")["energy"])
	ev = SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "u_nox_a", "target": _pid(s, "saul")})
	check(_has(ev, "heal") and int(_u(s, "saul")["energy"]) > en_before, "Pausa caffe': cura e da' energia")
	# Nox · Veglia per ultima
	s = _fresh(team)
	for c in ["ferri", "zecca", "saul"]:
		SeqRound.player_action(s, _pid(s, c), {"swap": "", "move": "attack", "target": ""})
	ev = SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "attack", "target": ""})
	check(_has(ev, "kit_trait"), "Veglia: Nox ultima del round")
	# Nox · Rispondo io: rianima, altrimenti annulla il prossimo colpo
	s = _fresh(team)
	var saul: Dictionary = _u(s, "saul")
	saul["hp"] = 0
	_u(s, "nox")["gauge"] = 100
	SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "u_nox_ult", "target": ""})
	check(int(saul["hp"]) > 0, "Rispondo io rianima chi e' KO")
	s = _fresh(team)
	_u(s, "nox")["gauge"] = 100
	s["telegraph"] = {"move": "scarica", "target": _pid(s, "ferri")}
	SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "u_nox_ult", "target": ""})
	ev = SeqRound.boss_action(s)
	check(_has(ev, "nullified") and _dmg_to(ev, str(_u(s, "ferri")["id"])) == 0, "Rispondo io annulla il colpo")


# Fase 2: RITMO per categoria, Guardia di slancio, Gran finale anticipato
func _fase2(team: Array) -> void:
	var s: Dictionary = _fresh(team)
	var ev: Array = SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "attack", "target": ""})
	check(not _has(ev, "rhythm"), "primo colpo senza RITMO")
	check(str(_u(s, "saul").get("last_cat", "")) == "attacco", "categoria attacco ricordata")
	ev = SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "attack", "target": ""})
	check(not _has(ev, "rhythm"), "attacco dopo attacco: niente RITMO")
	_u(s, "saul")["energy"] = 5
	ev = SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "u_saul_a", "target": ""})
	check(_has(ev, "rhythm"), "abilita' dopo attacco: RITMO")
	_u(s, "saul")["last_cat"] = "guardia"
	ev = SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "attack", "target": ""})
	check(_has(ev, "rhythm"), "attacco dopo guardia: RITMO")
	check(BattleContent.move_category("guard") == "guardia" and BattleContent.move_category("u_saul_ult") == "ultimate", "categorie")
	# Guardia di slancio: scudo a tutti e +1 energia in piu' rispetto alla guardia normale
	s = _fresh(team)
	var en0: int = int(_u(s, "nox")["energy"])
	var sh0: int = int(_u(s, "ferri")["shield"])
	ev = SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "guard", "target": ""}, true)
	check(_has(ev, "slancio_guard"), "guardia rapida = guardia di slancio")
	check(int(_u(s, "ferri")["shield"]) > sh0, "scudo anche ai compagni")
	check(int(_u(s, "nox")["energy"]) >= mini(BattleTypes.MAX_ENERGY, en0 + 2), "guardia di slancio: +2 energia")
	s = _fresh(team)
	ev = SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "guard", "target": ""})
	check(not _has(ev, "slancio_guard"), "guardia normale: niente scudo a tutti")
	# Gran finale anticipato: i compagni ricevono energia e Ultimate
	s = _fresh(team)
	_u(s, "zecca")["gauge"] = 100
	_u(s, "zecca")["hype"] = 30
	_u(s, "saul")["energy"] = 0
	_u(s, "saul")["gauge"] = 0
	ev = SeqRound.player_action(s, _pid(s, "zecca"), {"swap": "", "move": "u_zecca_ult", "target": ""})
	check(_has(ev, "finale_early"), "Gran finale sotto il 50% = anteprima")
	check(int(_u(s, "saul")["energy"]) >= 1 and int(_u(s, "saul")["gauge"]) >= 15, "anteprima: energia e Ultimate ai compagni")
	s = _fresh(team)
	_u(s, "zecca")["gauge"] = 100
	_u(s, "zecca")["hype"] = 80
	ev = SeqRound.player_action(s, _pid(s, "zecca"), {"swap": "", "move": "u_zecca_ult", "target": ""})
	check(not _has(ev, "finale_early"), "Gran finale pieno: niente anteprima, solo il colpo grosso")
