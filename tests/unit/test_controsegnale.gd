extends SceneTree

# CONTROSEGNALE · motore del combattimento in tempo reale a contrattacchi.
# Si prova: CONTRO giusto/sbagliato/perfetto, memoria del tocco, tocco troppo presto, tocchi simultanei, coda congelata,
# SFONDA e SCARTO, SPECCHIO, BLACKOUT + finale + RIAVVIO, DIRETTA che scende di un gradino, FURIA, RALLENTY,
# proposta di AMPIA, fase 2 del boss, VOTO, ripetibilità, e scontri interi con un giocatore preciso e uno impreciso.
const C = preload("res://scripts/controsegnale/cs_content.gd")

var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _b(enemy: String = "frammento") -> CsBattle:
	var b := CsBattle.new(["lance", "rio"], [enemy])
	b.auto_slow = false
	return b


func _run_to_attack(b: CsBattle) -> int:
	for _i in range(600):
		b.step(C.TICK)
		for i in range(b.enemies.size()):
			if not b.enemies[i]["attack"].is_empty():
				return i
	return -1


func _run_until(b: CsBattle, game_t: float) -> void:
	while b.t < game_t - 0.0001 and not b.over:
		b.step(C.TICK)


func _has(evs: Array, kind: String) -> bool:
	for e in evs:
		if e["t"] == kind:
			return true
	return false


# Giocatore simulato. offset: ritardo del tocco rispetto all'impatto. wrong_every: ogni N colpi sbaglia colore (0 = mai).
func _play(enemy: String, offset: float, wrong_every: int, seed_v: int = 3, limit: float = 400.0) -> CsBattle:
	var b := _b(enemy)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var faced: int = 0
	var handled: Dictionary = {}
	var k: int = 0
	while not b.over and b.t < limit:
		var ei: int = b._incoming()
		if ei >= 0:
			var a: Dictionary = b.enemies[ei]["attack"]
			var key: String = "%d_%f" % [ei, a["impact"]]
			if not handled.has(key) and b.t >= float(a["impact"]) + offset:
				handled[key] = true
				faced += 1
				if a["color"] == C.BIANCO:
					b.dodge()
				elif wrong_every > 0 and faced % wrong_every == 0:
					var others: Array = C.COLORS.filter(func(c): return c != a["color"])
					b.press(others[0])
				else:
					b.press(a["color"])
		else:
			for e in b.enemies:
				if b._in_blackout(e) and not e["finale_used"]:
					b.finale()
			var h: Dictionary = b.heroes[b.active]
			if h["queue"].size() < 2 and fmod(b.t, 0.25) < C.TICK:
				k += 1
				if k % 9 == 0 and int(h["set"]) == 1:
					b.toggle_set()
					b.press(C.COLORS[rng.randi() % 3])
					b.toggle_set()
				elif k % 5 == 0:
					b.partner_press(C.COLORS[k % 3])
				else:
					b.press(C.COLORS[k % 3])
		b.step(C.TICK)
	return b


func _initialize() -> void:
	# ------------------------------------------------ CONTRO perfetto, buono, colore sbagliato
	var b := _b()
	var ei: int = _run_to_attack(b)
	check(ei == 0, "il nemico attacca")
	var a: Dictionary = b.enemies[0]["attack"]
	var col: String = a["color"]
	var seg0: float = b.enemies[0]["segnale"]
	_run_until(b, float(a["impact"]))
	b.take_events()
	b.press(col)
	var evs: Array = b.take_events()
	check(_has(evs, "contro"), "CONTRO col colore giusto all'impatto")
	check(evs.filter(func(e): return e["t"] == "contro")[0]["perfect"], "all'impatto il CONTRO è perfetto")
	check(seg0 - float(b.enemies[0]["segnale"]) == C.SEGNALE_CONTRO_PERFECT, "il perfetto toglie il segnale pieno")
	check(int(b.heroes[0]["hp"]) == int(b.heroes[0]["max"]), "col CONTRO non si prende danno")

	b = _b()
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	_run_until(b, float(a["impact"]) - 0.25)
	b.press(a["color"])
	evs = b.take_events()
	var cs: Array = evs.filter(func(e): return e["t"] == "contro")
	check(cs.size() == 1 and not cs[0]["perfect"], "250 ms prima: CONTRO buono, non perfetto")

	b = _b()
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	_run_until(b, float(a["impact"]))
	var wrong: String = C.COLORS.filter(func(c): return c != a["color"])[0]
	b.press(wrong)
	evs = b.take_events()
	check(_has(evs, "colore_sbagliato"), "colore sbagliato: niente CONTRO")
	var dmg_w: int = int(b.heroes[0]["max"]) - int(b.heroes[0]["hp"])
	check(dmg_w == int(round(C.ENEMIES["frammento"]["dmg"] * C.WRONG_COLOR_DMG)), "colore sbagliato: danno a metà (%d)" % dmg_w)

	# ------------------------------------------------ D12 memoria del tocco e tocco troppo presto
	b = _b()
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	_run_until(b, float(a["impact"]) - C.WIN_GOOD_BEFORE - 0.06)
	b.press(a["color"])
	check(not b.buffered.is_empty(), "il tocco 60 ms prima della finestra viene ricordato")
	_run_until(b, float(a["impact"]))
	check(_has(b.take_events(), "contro"), "il tocco ricordato diventa CONTRO all'apertura della finestra")

	b = _b()
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	_run_until(b, float(a["impact"]) - 0.55)
	b.press(a["color"])
	evs = b.take_events()
	check(_has(evs, "presto") and int(b.heroes[0]["hp"]) == int(b.heroes[0]["max"]), "troppo presto: niente danno, solo «presto»")
	_run_until(b, float(a["impact"]))
	b.press(a["color"])
	check(_has(b.take_events(), "contro"), "dopo il tocco presto il CONTRO giusto vale ancora")

	# ------------------------------------------------ D12 tocchi simultanei
	b = _b()
	b.step(C.TICK)
	b.press(C.ROSSO)
	b.press(C.GIALLO)
	check(b.heroes[0]["queue"].size() == 1, "due tocchi nello stesso istante valgono uno")

	# ------------------------------------------------ D2 coda congelata, non persa
	b = _b()
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	b.heroes[0]["queue"] = []
	b.press(C.ROSSO)                      # prima della zona di pericolo: va in coda
	var qn: int = b.heroes[0]["queue"].size()
	_run_until(b, float(a["impact"]) - C.DANGER_LEAD + 0.05)
	b.heroes[0]["queue"].append({"move": C.HEROES["lance"]["set1"][C.BLU], "color": C.BLU})
	var before: int = b.heroes[0]["queue"].size()
	_run_until(b, float(a["impact"]) - 0.05)
	check(b.heroes[0]["queue"].size() == before, "con il MIRINO vicino la coda non avanza (D2)")
	b.press(a["color"])
	check(_has(b.take_events(), "contro"), "nella zona di pericolo il tocco è CONTRO, non mossa")
	_run_until(b, b.t + 1.0)
	check(b.heroes[0]["queue"].size() < before, "dopo il colpo la coda riparte")

	# ------------------------------------------------ SFONDA e SCARTO
	b = _b("sfondatore")
	b.enemies[0]["pi"] = 1                # il secondo colpo è bianco
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	check(a["color"] == C.BIANCO, "lo Sfondatore porta un colpo SFONDA")
	_run_until(b, float(a["impact"]))
	b.press(C.ROSSO)
	check(_has(b.take_events(), "sfonda"), "col colore lo SFONDA passa")
	check(int(b.heroes[0]["hp"]) == int(b.heroes[0]["max"]) - int(C.ENEMIES["sfondatore"]["dmg"]), "SFONDA: danno pieno")
	b = _b("sfondatore")
	b.enemies[0]["pi"] = 1
	_run_to_attack(b)
	_run_until(b, float(b.enemies[0]["attack"]["impact"]))
	b.dodge()
	evs = b.take_events()
	check(_has(evs, "scarto") and int(b.heroes[0]["hp"]) == int(b.heroes[0]["max"]), "SCARTO evita lo SFONDA")

	# ------------------------------------------------ D10 SPECCHIO
	b = _b("specchio")
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	check(a["color"] == C.ROSSO, "il Riflesso apre col rosso")
	b.enemies[0]["segnale"] = 30.0
	_run_until(b, float(a["impact"]))
	b.press(C.ROSSO)
	check(_has(b.take_events(), "specchio") and float(b.enemies[0]["segnale"]) == 30.0 + C.SEGNALE_SPECCHIO_HEAL, "contrare il colore dello SPECCHIO ridà segnale")

	# ------------------------------------------------ BLACKOUT, finale, RIAVVIO
	b = _b()
	b.enemies[0]["segnale"] = 5.0
	b.heroes[0]["ready"]["lance_r"] = 99.0
	_run_to_attack(b)
	_run_until(b, float(b.enemies[0]["attack"]["impact"]))
	b.press(b.enemies[0]["attack"]["color"])
	check(_has(b.take_events(), "blackout"), "segnale a zero: BLACKOUT")
	var hp0: int = b.enemies[0]["hp"]
	b.finale()
	evs = b.take_events()
	check(_has(evs, "finale") and _has(evs, "riavvio"), "finale e RIAVVIO")
	check(hp0 - int(b.enemies[0]["hp"]) >= int(b.enemies[0]["max"] * C.FINALE_FRAC), "il finale toglie almeno il 15% della vita")
	check(b.heroes[0]["ready"].is_empty(), "RIAVVIO azzera i cooldown")
	b.finale()
	check(not _has(b.take_events(), "finale"), "un solo finale per BLACKOUT")
	_run_until(b, b.t + C.BLACKOUT_TIME + 0.1)
	check(float(b.enemies[0]["segnale"]) == float(b.enemies[0]["segnale_max"]), "finito il BLACKOUT il segnale torna pieno")

	# ------------------------------------------------ D11 la DIRETTA scende di un gradino
	b = _b()
	b.diretta = 80.0
	_run_to_attack(b)
	b.diretta = 80.0
	_run_until(b, float(b.enemies[0]["attack"]["impact"]) + 0.2)
	check(b.diretta == float(C.DIRETTA_STEPS[1]), "colpito a gradino 2: scende al gradino 1 (%.0f), non a zero" % b.diretta)
	b = _b()
	b.diretta = 50.0
	b.enemies[0]["next_at"] = 999.0
	_run_until(b, 6.0)
	check(b.diretta == float(C.DIRETTA_STEPS[1]), "stando fermi la DIRETTA cala solo fino al gradino")

	# ------------------------------------------------ FURIA (D3)
	b = _b()
	b.enemies[0]["next_at"] = 999.0
	_run_until(b, 2.0 + C.FURIA_MAX / C.FURIA_RATE + 0.5)
	check(int(b.enemies[0]["furia_left"]) == C.FURIA_ATTACKS, "lasciato stare, il nemico entra in FURIA")

	# ------------------------------------------------ RALLENTY
	b = CsBattle.new(["lance", "rio"], ["frammento"])
	for _i in range(60):
		b.step(C.TICK)
	var t1: float = b.t
	for _i in range(60):
		b.step(C.TICK)
	check(b.is_slow() and b.t - t1 < 0.5, "dopo 1 s senza tocchi il tempo rallenta")
	b.press(C.ROSSO)
	check(not b.is_slow(), "un tocco toglie il RALLENTY")
	b.set_paused(true)
	var tp: float = b.t
	b.step(1.0)
	check(b.t == tp, "la PAUSA ferma il tempo")

	# ------------------------------------------------ proposta AMPIA
	b = _b()
	var hinted: bool = false
	for _k in range(3):
		_run_to_attack(b)
		_run_until(b, float(b.enemies[0]["attack"]["impact"]) + 0.3)
		hinted = hinted or _has(b.take_events(), "proponi_ampia")
	check(hinted, "dopo 3 colpi mancati Echo propone la finestra AMPIA")
	b = _b()
	b.wide = true
	_run_to_attack(b)
	a = b.enemies[0]["attack"]
	_run_until(b, float(a["impact"]) - C.WIN_GOOD_BEFORE * 1.4)
	b.press(a["color"])
	check(_has(b.take_events(), "contro"), "con AMPIA vale anche un tocco più largo")

	# ------------------------------------------------ fase 2 del boss
	b = _b("boss_ripetitore")
	b._damage_enemy(0, int(b.enemies[0]["max"]) / 2 + 1, "test")
	check(_has(b.take_events(), "fase2") and b.enemies[0]["specchio"] == C.BLU, "a metà vita il Ripetitore mette lo SPECCHIO sul blu")

	# ------------------------------------------------ scontri interi
	for en in ["frammento", "sfondatore", "specchio", "boss_ripetitore"]:
		var p: CsBattle = _play(en, 0.0, 0)
		var v: Dictionary = p.vote()
		check(p.over and p.won, "%s: il giocatore preciso vince" % en)
		check(p.t <= float(C.PAR_TIME[en]) * 1.6, "%s: durata %.0f s entro il tetto (par %.0f)" % [en, p.t, C.PAR_TIME[en]])
		check(v["voto"] in ["S", "A"], "%s: voto del preciso %s (%d)" % [en, v["voto"], v["punti"]])
		print("  %s preciso: %.0f s, voto %s %s" % [en, p.t, v["voto"], str(v)])
		var s: CsBattle = _play(en, 0.10, 4)
		var vs: Dictionary = s.vote()
		print("  %s impreciso: %s in %.0f s, voto %s, PV %d/%d" % [en, "vince" if s.won else "perde", s.t, vs["voto"], s.heroes[0]["hp"], s.heroes[1]["hp"]])
		if en != "boss_ripetitore":
			check(s.won, "%s: anche chi è in ritardo di 100 ms e sbaglia un colore su 4 vince (D12)" % en)
	var r1: CsBattle = _play("sfondatore", 0.03, 5, 7)
	var r2: CsBattle = _play("sfondatore", 0.03, 5, 7)
	check(r1.t == r2.t and r1.vote() == r2.vote(), "stessa partita, stesso risultato")

	print("controsegnale: %s (%d errori)" % ["OK" if fails == 0 else "FALLITO", fails])
	quit(1 if fails > 0 else 0)
