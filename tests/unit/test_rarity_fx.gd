extends SceneTree

# Animazioni per rarita' (comune, rara, epica, leggendaria).
#   godot --headless --path . -s res://tests/unit/test_rarity_fx.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _bursts(host: Control) -> int:
	var n: int = 0
	for c in host.get_children():
		if c is RarityFx.Burst:
			n += 1
	return n


func _run() -> void:
	await process_frame
	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)
	await process_frame

	_check("quattro colori diversi", RarityFx.COLORS.size() == 4 and RarityFx.color_of(0) != RarityFx.color_of(3))
	_check("durate crescenti con la rarita'", RarityFx.DURATION[1] < RarityFx.DURATION[2] and RarityFx.DURATION[2] < RarityFx.DURATION[3])
	_check("suoni diversi per rarita'", RarityFx.SOUNDS[0] != RarityFx.SOUNDS[1] and RarityFx.SOUNDS[2] != RarityFx.SOUNDS[3])
	for s in RarityFx.SOUNDS:
		_check("il suono '%s' esiste" % s, FileAccess.file_exists("res://assets/audio/sfx/%s.wav" % s) or ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % s))

	RarityFx.play(host, Vector2(300, 300), 0)
	_check("comune: nessun effetto", _bursts(host) == 0)
	for tier in [1, 2, 3]:
		RarityFx.play(host, Vector2(300, 300), tier)
		_check("rarita' %d: effetto creato" % tier, _bursts(host) == tier)
	await create_timer(1.1).timeout
	var left: int = _bursts(host)
	_check("gli effetti brevi spariscono da soli (resta solo la leggendaria)", left == 1)
	await create_timer(1.2).timeout
	_check("anche la leggendaria sparisce", _bursts(host) == 0)

	# riga che entra
	var row := Label.new()
	row.text = "PROVA"
	host.add_child(row)
	await process_frame
	RarityFx.reveal_row(host, row, 2, 0.1)
	_check("la riga parte nascosta", row.modulate.a == 0.0)
	await create_timer(0.7).timeout
	_check("poi compare", row.modulate.a > 0.95)

	var home: Vector2 = host.position
	RarityFx.shake(host, 10.0, 0.2)
	await create_timer(0.5).timeout
	_check("la vibrazione torna al posto", host.position == home)
	host.queue_free()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
