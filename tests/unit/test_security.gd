extends SceneTree

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _init() -> void:
	Objectives.enabled = false
	var path: String = "user://test_sec_roster.json"
	for suffix in ["", ".bak", ".corrotto", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var r: Dictionary = RosterState.new_roster()
	r["coins"] = 1234
	_check("primo salvataggio", RosterStore._write(r, path))
	r["coins"] = 5678
	_check("secondo salvataggio", RosterStore._write(r, path))
	_check("c'e' la copia di sicurezza", FileAccess.file_exists(path + ".bak"))
	_check("la copia e' il salvataggio precedente", int(RosterStore.load_or_new(path + "")["coins"]) == 5678)
	# rovino il file principale
	_write(path, "{ questo non e' json")
	var back: Dictionary = RosterStore.load_or_new(path)
	_check("salvataggio rovinato: torna la copia", int(back.get("coins", -1)) == 1234)
	_check("il file rovinato e' messo da parte", FileAccess.file_exists(path + ".corrotto"))
	# rovino anche la copia: collezione nuova, ma il rovinato resta
	_write(path + ".bak", "xx")
	var fresh: Dictionary = RosterStore.load_or_new(path)
	_check("senza copie valide parte da nuovo", not fresh.is_empty() and int(fresh["coins"]) != 1234)
	# file principale sparito: usa la copia valida
	_write(path + ".bak", RosterState.to_json(r))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check("file sparito: usa la copia", int(RosterStore.load_or_new(path)["coins"]) == 5678)
	for suffix in ["", ".bak", ".corrotto", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

	# difese del canale
	var link: WebRTCLink = WebRTCLink.new()
	_check("pacchetto normale accettato", link._accept_packet(500, 1000))
	_check("pacchetto enorme scartato", not link._accept_packet(WebRTCLink.MAX_PACKET_BYTES + 1, 1001))
	var accepted: int = 0
	for i in 400:
		if link._accept_packet(100, 1002):
			accepted += 1
	_check("troppi messaggi al secondo scartati", accepted < 200)
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
