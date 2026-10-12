extends SceneTree

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_turn.cfg"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	var none: Array = WebRTCLink.build_ice_servers("user://non_esiste.cfg")
	_check("senza TURN: solo STUN", none.size() == 1 and str(none[0]["urls"][0]).begins_with("stun:"))

	var cfg := ConfigFile.new()
	cfg.set_value("turn", "url", "turn:relay.example.com:80, turn:relay.example.com:443?transport=tcp,turns:relay.example.com:443?transport=tcp, http://sbagliato")
	cfg.set_value("turn", "user", "amici")
	cfg.set_value("turn", "pass", "segreto")
	cfg.save(TMP)
	var with: Array = WebRTCLink.build_ice_servers(TMP)
	_check("con TURN: STUN + TURN", with.size() == 2)
	_check("indirizzi TURN letti e filtrati (3 validi)", (with[1]["urls"] as Array).size() == 3)
	_check("credenziali lette", with[1]["username"] == "amici" and with[1]["credential"] == "segreto")
	_check("lo STUN resta", str(with[0]["urls"][0]).begins_with("stun:"))

	var bad := ConfigFile.new()
	bad.set_value("turn", "url", "ftp://niente")
	bad.save(TMP)
	_check("indirizzo non valido: nessun TURN", WebRTCLink.build_ice_servers(TMP).size() == 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	_check("l'esempio e' un file di impostazioni valido", ConfigFile.new().load("res://config/turn.cfg.example") == OK)

	var link: WebRTCLink = WebRTCLink.new()
	_check("la connessione parte con la lista di server", link.setup(true, WebRTCLink.build_ice_servers("user://non_esiste.cfg")))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
