extends SceneTree

# Compressione dei messaggi di rete: andata e ritorno, messaggi piccoli intatti, pacchetti falsi scartati.
#   godot --headless --path . -s res://tests/unit/test_pack.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	var s: Dictionary = BattleState.create_solo("T", [{"char": "kira"}, {"char": "dax"}, {"char": "elle"}], [{"char": "bruno"}, {"char": "eco"}], "distributore", 5)
	var text: String = JSON.stringify({"type": "battle_snapshot", "state": s, "time_left": 30})
	var packed: PackedByteArray = WebRTCLink.pack_text(text)
	print("[PACK] originale %d byte -> inviati %d byte" % [text.to_utf8_buffer().size(), packed.size()])
	_check("messaggio grosso: si comprime", packed.size() < text.to_utf8_buffer().size() / 2)
	_check("andata e ritorno identico", WebRTCLink.unpack_text(packed) == text)
	var small: String = JSON.stringify({"type": "ping"})
	var sp: PackedByteArray = WebRTCLink.pack_text(small)
	_check("messaggio piccolo: resta testo", sp == small.to_utf8_buffer() and WebRTCLink.unpack_text(sp) == small)
	var fake := PackedByteArray([1, 255, 255, 255, 255, 9, 9])
	_check("dimensione dichiarata enorme: scartato", WebRTCLink.unpack_text(fake) == "")
	var broken := PackedByteArray([1, 10, 0, 0, 0, 1, 2, 3])
	_check("dati rotti: scartato", WebRTCLink.unpack_text(broken) == "")
	_check("pacchetto vuoto: vuoto", WebRTCLink.unpack_text(PackedByteArray()) == "")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
