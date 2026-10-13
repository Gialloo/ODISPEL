extends SceneTree

# Progressi e sblocchi: boss e livelli di difficolta' battuti. Usa file temporanei.
#
#   godot --headless --path . -s res://tests/unit/test_progress.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_progress_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _clean() -> void:
	var path: String = ProjectSettings.globalize_path(TMP)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _play_solo(src: SoloBattleSource, want_win: bool) -> void:
	var guard: int = 0
	while str(src.battle["winner"]) == "" and guard < 150:
		if want_win:
			src.submit_choice(BattleAI.choose(src.battle, "p1"))
		else:
			src.submit_choice({"move": "guard"})
		guard += 1


func _run() -> void:
	_clean()
	var r: Dictionary = RosterState.new_roster()
	_check("collezione nuova: nessun progresso", r["cleared"] == {} and RosterState.validate(r) == "")
	_check("il primo boss e' aperto", RosterState.is_boss_unlocked(r, "distributore"))
	_check("il secondo boss e' chiuso", not RosterState.is_boss_unlocked(r, "semaforo"))
	_check("il terzo boss e' chiuso", not RosterState.is_boss_unlocked(r, "tombino"))
	_check("boss sconosciuto chiuso", not RosterState.is_boss_unlocked(r, "drago"))
	_check("NORMALE aperto sul primo boss", RosterState.is_tier_unlocked(r, "distributore", 0))
	_check("DIFFICILE chiuso all'inizio", not RosterState.is_tier_unlocked(r, "distributore", 1))
	_check("tier fuori scala chiuso", not RosterState.is_tier_unlocked(r, "distributore", 3) and not RosterState.is_tier_unlocked(r, "distributore", -1))
	_check("tier di un boss chiuso e' chiuso", not RosterState.is_tier_unlocked(r, "semaforo", 0))

	_check("prima vittoria registrata", RosterState.mark_cleared(r, "distributore", 0))
	_check("progresso: 1 livello", RosterState.cleared_tiers(r, "distributore") == 1)
	_check("ripetere la stessa vittoria non cambia", not RosterState.mark_cleared(r, "distributore", 0))
	_check("si apre DIFFICILE", RosterState.is_tier_unlocked(r, "distributore", 1))
	_check("INCUBO ancora chiuso", not RosterState.is_tier_unlocked(r, "distributore", 2))
	_check("si apre il secondo boss", RosterState.is_boss_unlocked(r, "semaforo") and RosterState.is_tier_unlocked(r, "semaforo", 0))
	_check("il terzo resta chiuso", not RosterState.is_boss_unlocked(r, "tombino"))
	_check("vincere un livello piu' alto sale di piu'", RosterState.mark_cleared(r, "distributore", 2) and RosterState.cleared_tiers(r, "distributore") == 3)
	_check("una vittoria piu' bassa non toglie nulla", not RosterState.mark_cleared(r, "distributore", 0) and RosterState.cleared_tiers(r, "distributore") == 3)
	_check("boss o tier non validi rifiutati", not RosterState.mark_cleared(r, "drago", 0) and not RosterState.mark_cleared(r, "semaforo", 5) and not RosterState.mark_cleared(r, "semaforo", -1))
	_check("collezione valida con i progressi", RosterState.validate(r) == "")

	# validazione
	var bad: Dictionary = r.duplicate(true)
	bad["cleared"] = {"drago": 1}
	_check("progressi con boss sconosciuto rifiutati", RosterState.validate(bad) != "")
	bad["cleared"] = {"semaforo": 9}
	_check("progressi fuori scala rifiutati", RosterState.validate(bad) != "")
	bad["cleared"] = {"semaforo": -1}
	_check("progressi negativi rifiutati", RosterState.validate(bad) != "")
	bad["cleared"] = [1, 2]
	_check("progressi del tipo sbagliato rifiutati", RosterState.validate(bad) != "")
	var legacy: Dictionary = r.duplicate(true)
	legacy.erase("cleared")
	_check("senza il campo la collezione resta valida", RosterState.validate(legacy) == "")
	_check("senza il campo i progressi sono zero", RosterState.cleared_tiers(legacy, "distributore") == 0)

	# JSON
	var back: Dictionary = RosterState.from_json(RosterState.to_json(r))
	_check("i progressi sopravvivono al JSON", back["cleared"]["distributore"] == 3 and back["cleared"]["distributore"] is int)
	var old: Dictionary = JSON.parse_string(RosterState.to_json(RosterState.new_roster()))
	old.erase("cleared")
	var loaded: Dictionary = RosterState.from_json(JSON.stringify(old))
	_check("un salvataggio vecchio si carica con progressi vuoti", not loaded.is_empty() and loaded["cleared"] == {})

	# partita in solitaria
	var fresh: Dictionary = RosterState.new_roster()
	for id in ["kira", "dax", "elle"]:
		fresh["characters"][id]["level"] = 15
	var src := SoloBattleSource.new()
	src.save_path = TMP
	src.start(fresh, "distributore", 21, 1)
	_check("la partita solo parte al livello scelto", int(src.battle["tier"]) == 1)
	_play_solo(src, true)
	_check("battaglia vinta", str(src.battle["winner"]) == "players")
	var rw: Dictionary = src.finish()
	_check("premi maggiorati a DIFFICILE", int(rw["coins"]) == int(round(float(BattleContent.BOSSES["distributore"]["reward"]["coins"]) * float(BattleContent.tier_of(1)["reward"]))))
	var saved: Dictionary = RosterStore.load_or_new(TMP)
	_check("la vittoria a DIFFICILE sblocca INCUBO", RosterState.cleared_tiers(saved, "distributore") == 2 and RosterState.is_tier_unlocked(saved, "distributore", 2))
	src.finish()
	_check("registrare due volte non cambia nulla", RosterState.cleared_tiers(RosterStore.load_or_new(TMP), "distributore") == 2)

	# sconfitta: nessun progresso
	var weak: Dictionary = RosterState.new_roster()
	RosterState.set_team(weak, ["kira"])
	var src2 := SoloBattleSource.new()
	src2.save_path = TMP
	_clean()
	src2.start(weak, "tombino", 5, 2)
	_play_solo(src2, false)
	_check("battaglia persa", str(src2.battle["winner"]) == "boss")
	src2.finish()
	_check("la sconfitta non sblocca nulla", RosterState.cleared_tiers(RosterStore.load_or_new(TMP), "tombino") == 0)

	# tier fuori scala
	var src3 := SoloBattleSource.new()
	src3.save_path = TMP
	src3.start(RosterState.new_roster(), "distributore", 3, 99)
	_check("tier fuori scala ricondotto", src3.tier == 2 and int(src3.battle["tier"]) == 2)

	# rete: l'host avvia con boss e tier
	var game := GameState.new()
	game.setup("progress_test", 1, 1, 2)
	for i in 2:
		var p := PlayerState.new()
		p.setup("player_" + str(i + 1), "P" + str(i + 1), i + 1)
		game.party.add_player(p)
	var host := NetworkManager.new()
	host.is_host = true
	host.game = game
	host.local_player_id = "player_1"
	host.reward_save_path = TMP
	host._prepare_host_party()
	host._links["peerA"] = WebRTCLink.new()
	host._host_handle_message({"type": "hello", "name": "A", "token": "tok", "version": GameConfig.VERSION}, "peerA")
	_clean()
	_check("avvio in rete con boss e tier", host.host_start_battle("semaforo", 31, 2) and int(host.battle["tier"]) == 2 and str(BattleState.boss(host.battle)["char"]) == "semaforo")
	host.battle["winner"] = "players"
	host._broadcast_battle()
	host.finish()
	var net_saved: Dictionary = RosterStore.load_or_new(TMP)
	_check("la vittoria in rete registra boss e livello", RosterState.cleared_tiers(net_saved, "semaforo") == 3)
	_check("e i premi sono maggiorati", int(host.battle_rewards["coins"]) == int(round(float(BattleContent.BOSSES["semaforo"]["reward"]["coins"]) * float(BattleContent.tier_of(2)["reward"]))))
	host.free()

	_clean()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
