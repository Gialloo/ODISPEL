extends SceneTree

# Foto dei quattro livelli di impact frame (banco di prova).
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/impact_shot.gd -- <cartella> [lite]

func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	_run(a[0] if a.size() > 0 else "/tmp", a.size() > 1 and a[1] == "lite")


func _run(dir: String, lite: bool) -> void:
	if lite:
		Settings.light_fx = true
	var lab: ImpactLab = ImpactLab.open(root)
	await create_timer(0.4).timeout
	for lv in [1, 2, 3, 4]:
		lab._director = ImpactDirector.new()
		lab._fire(lv)
		var len_s: float = float(ImpactFrames.OVERLAY_LEN[lv])
		for k in 3:
			await create_timer(len_s * (0.12 + 0.3 * k)).timeout
			root.get_viewport().get_texture().get_image().save_png(dir.path_join("impact_L%d_%d%s.png" % [lv, k, "_lite" if lite else ""]))
		await create_timer(len_s + 0.1).timeout
	quit()
