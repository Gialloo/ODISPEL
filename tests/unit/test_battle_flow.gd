extends SceneTree

# Premi e fine battaglia in rete (nuovo motore). Usa un file temporaneo.
#
#   godot --headless --path . -s res://tests/unit/test_battle_flow.gd

var passed: int = 0
var failed: int = 0
var _managers: Array[NetworkManager] = []
const TMP: String = "user://test_flow_roster_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _entries(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id)))
	return out


func _host() -> NetworkManager:
	var game := GameState.new()
	game.setup("flow_test", 1, 1, 2)
	for i in 2:
		var p := PlayerState.new()
		p.setup("player_" + str(i + 1), "P" + str(i + 1), i + 1)
		game.party.add_player(p)
	var m := NetworkManager.new()
	m.is_host = true
	m.game = game
	m.local_player_id = "player_1"
	m.reward_save_path = TMP
	m._prepare_host_party()
	_managers.append(m)
	m.set_local_team(_entries(["kira", "dax", "elle"]))
	m._links["peerA"] = WebRTCLink.new()
	m._host_handle_message({"type": "hello", "name": "A", "token": "tok", "version": GameConfig.VERSION, "team": _entries(["nova", "bruno", "mira"])}, "peerA")
	return m


func _play(m: NetworkManager) -> void:
	var guard: int = 0
	while str(m.battle["winner"]) == "" and guard < 100:
		m.submit_choice(BattleAI.choose(m.battle, "player_1"))
		var c: Dictionary = BattleAI.choose(m.battle, "player_2")
		c["type"] = "choice"
		m._host_handle_message(c, "peerA")
		guard += 1


func _clean() -> void:
	var path: String = ProjectSettings.globalize_path(TMP)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _run() -> void:
	_clean()
	_check("versione aggiornata al nuovo protocollo", GameConfig.VERSION != "0.1.0")

	var m: NetworkManager = _host()
	_check("la squadra dell'host e' quella scelta", m._player_teams["player_1"][0]["char"] == "kira")
	_check("avvio battaglia", m.host_start_battle("distributore", 777))
	_check("squadra dell'host usata in battaglia", str(BattleState.unit(m.battle, str(BattleState.player(m.battle, "player_1")["team"][0]))["char"]) == "kira")
	_check("nessun premio a battaglia in corso", m.battle_rewards.is_empty() and m.finish().is_empty())
	_play(m)
	_check("battaglia finita", str(m.battle["winner"]) != "")

	var expected: Dictionary = BattleRewards.for_battle(m.battle, "distributore", 777)
	_check("premi dell'host calcolati", m.battle_rewards == expected["player_1"])
	_check("ci sono premi (monete)", int(m.battle_rewards.get("coins", 0)) > 0)

	var start: Dictionary = RosterStore.load_or_new(TMP)
	var r1: Dictionary = m.finish()
	_check("finish ritorna i premi", r1 == m.battle_rewards)
	var saved: Dictionary = RosterStore.load_or_new(TMP)
	_check("monete aggiunte alla collezione", int(saved["coins"]) == int(start["coins"]) + int(r1["coins"]))
	m.finish()
	var saved2: Dictionary = RosterStore.load_or_new(TMP)
	_check("i premi non si danno due volte", int(saved2["coins"]) == int(saved["coins"]))
	_check("collezione valida", RosterState.validate(saved2) == "")

	# un'altra battaglia azzera premi e applicazione
	_check("seconda battaglia", m.host_start_battle("distributore", 888))
	_check("premi azzerati", m.battle_rewards.is_empty())
	_play(m)
	var exp2: Dictionary = BattleRewards.for_battle(m.battle, "distributore", 888)
	_check("premi della seconda battaglia", m.battle_rewards == exp2["player_1"])
	m.finish()
	var saved3: Dictionary = RosterStore.load_or_new(TMP)
	_check("e di nuovo assegnati", int(saved3["coins"]) == int(saved2["coins"]) + int(m.battle_rewards["coins"]))

	# lato client: i premi arrivano dall'host dentro lo snapshot
	var c := NetworkManager.new()
	_managers.append(c)
	c.reward_save_path = TMP
	var wire: Variant = JSON.parse_string(JSON.stringify({
		"type": "battle_snapshot",
		"state": BattleNet.snapshot_for(m.battle, "player_2"),
		"time_left": 0.0,
		"rewards": exp2["player_2"],
	}))
	c._client_handle_message(wire)
	_check("il client riceve i premi", c.battle_rewards == exp2["player_2"] and int(c.battle_rewards.get("coins", -1)) >= 0)
	_check("premi con numeri interi", c.battle_rewards.get("coins") is int)
	var before: Dictionary = RosterStore.load_or_new(TMP)
	c.finish()
	var after: Dictionary = RosterStore.load_or_new(TMP)
	_check("il client applica i suoi premi", int(after["coins"]) == int(before["coins"]) + int(c.battle_rewards["coins"]))
	c.finish()
	_check("e una volta sola", int(RosterStore.load_or_new(TMP)["coins"]) == int(after["coins"]))
	_check("collezione valida dopo i premi del client", RosterState.validate(RosterStore.load_or_new(TMP)) == "")

	# il client non vede il seed ne' puo' ricalcolare i premi
	_check("il client non ha il seed", c.battle["rng_seed"] == "0")

	# battaglia non finita: il client non applica nulla
	var d := NetworkManager.new()
	_managers.append(d)
	d.reward_save_path = TMP
	var mid: NetworkManager = _host()
	mid.host_start_battle("distributore", 5)
	d._client_handle_message(JSON.parse_string(JSON.stringify({"type": "battle_snapshot", "state": BattleNet.snapshot_for(mid.battle, "player_2"), "time_left": 9.0})))
	var coins_now: int = int(RosterStore.load_or_new(TMP)["coins"])
	d.finish()
	_check("a battaglia in corso finish non fa nulla", int(RosterStore.load_or_new(TMP)["coins"]) == coins_now)

	for x in _managers:
		x.free()
	_clean()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
