extends SceneTree

# Gli effetti animati si creano, vivono e si cancellano da soli.
#   godot --headless --path . -s res://tests/unit/test_animfx.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	Settings.light_fx = false
	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var p := Vector2(400, 300)
	AnimFx.slash(host, p, Color.WHITE, 1.5)
	AnimFx.shockwave(host, p, Color.RED)
	AnimFx.sparks(host, p, Color.YELLOW)
	var hit := [false]
	AnimFx.projectile(host, Vector2(100, 300), p, Color.CYAN, func() -> void: hit[0] = true)
	AnimFx.rise(host, p)
	AnimFx.shield(host, p, false)
	AnimFx.shield(host, p, true)
	AnimFx.shards(host, p)
	AnimFx.round_banner(host, "CICLO 2")
	_check("effetti creati", host.get_child_count() >= 9)
	var t1: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 3000:
		await process_frame
	_check("il proiettile e' arrivato", hit[0])
	_check("gli effetti si cancellano da soli", host.get_child_count() == 0)
	var b := Button.new()
	host.add_child(b)
	AnimFx.glint(b)
	AnimFx.glint(b)
	_check("un solo bagliore per pulsante", b.get_child_count() == 1)
	var l := Label.new()
	host.add_child(l)
	AnimFx.count_up(l, 0, 500)
	var t2: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t2 < 900:
		await process_frame
	_check("il numero sale fino al valore", l.text == "500")
	var done := [false]
	AnimFx.portal(host, 0, func() -> void: done[0] = true)
	var t0: int = Time.get_ticks_msec()
	while not done[0] and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	_check("il portale finisce", done[0])
	print("RESULT: %d passed, %d failed" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
