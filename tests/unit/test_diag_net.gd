extends SceneTree

# Diagnostica di rete e messaggi d'errore comprensibili.
#   godot --headless --path . -s res://tests/unit/test_diag_net.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_check("setup WebRTC: spiega cosa fare", Diagnostics.friendly_network_error("setup WebRTC fallito").contains("zip"))
	_check("nessun host: spiega il codice", Diagnostics.friendly_network_error("nessun host nella stanza").contains("codice"))
	_check("altro errore: resta com'e'", Diagnostics.friendly_network_error("boh") == "boh")
	_check("il rapporto parla di rete", Diagnostics.report().contains("Rete: componente WebRTC"))
	_check("le righe di log sono al massimo quelle chieste", Diagnostics.net_log_lines(3).size() <= 3)
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
