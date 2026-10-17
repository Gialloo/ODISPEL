extends SceneTree

# Misura il tempo per fotogramma della Battaglia V2 nei vari stati (sul render software e' un indicatore relativo, non assoluto).
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/battle_v2_perf.gd -- [opzioni]

var scn: BattleV2


func _avg(label: String, frames: int) -> float:
	await process_frame
	var t0: int = Time.get_ticks_usec()
	var worst: int = 0
	var last: int = t0
	for i in frames:
		await process_frame
		var n: int = Time.get_ticks_usec()
		worst = maxi(worst, n - last)
		last = n
	var avg: float = float(last - t0) / float(frames) / 1000.0
	print("%-34s medio %6.1f ms   peggiore %6.1f ms" % [label, avg, float(worst) / 1000.0])
	return avg


func _init() -> void:
	var opts: PackedStringArray = OS.get_cmdline_user_args()
	scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.5).timeout
	var groups: Dictionary = {
		"bg": [scn.bg_node], "paint_flat": scn.paint_flat, "paint_light": scn.paint_light, "particelle": scn.streaks,
		"lettere": [scn.wheel_letters], "fx": [scn.fx], "alone boss": [scn.glow_rect], "boss": [scn.boss_rect],
		"eroe": [scn.hero], "front": [scn.wheel_front], "ring": [scn.ring_fx], "hud": [scn.hud], "dim": [scn.dim]}
	var mode: String = opts[0] if opts.size() > 0 else "idle"
	if mode == "trans":
		await create_timer(1.0).timeout
		await _avg("libero (fermo)", 40)
		scn._slot_unit(scn.cur)["gauge"] = 100
		scn._build_cmds()
		scn._refresh()
		await create_timer(1.2).timeout
		scn._tap(scn.wheel_front.hits[1].get_center())
		await _avg("transizione SKILL (0,5 s)", 20)
		await _avg("SKILL scelta (fermo)", 40)
		scn._cancel()
		await create_timer(1.0).timeout
		scn._tap(scn.wheel_front.hits[2].get_center())
		await _avg("transizione ULT (0,5 s)", 20)
		await _avg("ULT scelta (fermo)", 40)
		quit(0)
		return
	if mode == "skill":
		scn._tap(scn.wheel_front.hits[1].get_center())
		await create_timer(1.2).timeout
	var base: float = await _avg("TUTTO (%s)" % mode, 40)
	scn.visible = false
	await _avg("scena nascosta (costo fisso)", 40)
	scn.visible = true
	scn.paint_svps[0].get_parent().remove_child(scn.paint_svps[0])
	await _avg("senza un SubViewport", 20)
	for g in groups.keys():
		for n in groups[g]:
			n.visible = false
		var v: float = await _avg("senza %s" % g, 40)
		print("    -> risparmio %5.1f ms" % (base - v))
		for n in groups[g]:
			n.visible = true
	quit(0)
