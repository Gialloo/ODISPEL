extends SceneTree
## Misura il peso di ogni zona: draw call, oggetti, luci, mesh.
## xvfb-run -a godot --path . --resolution 1280x720 -s tools/misura.gd
var main: Node

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_misura()

func _conta(n: Node, d: Dictionary) -> void:
	if n is MeshInstance3D and n.visible:
		d["mesh"] += 1
	if n is OmniLight3D or n is SpotLight3D:
		d["luci"] += 1
	for c in n.get_children():
		_conta(c, d)

func _misura() -> void:
	await process_frame
	var mondo = main.mondo
	main.ui.visible = false
	for z in ["vicolo", "rifugio", "quartiere", "nido"]:
		var dz: Dictionary = main.dati["zone"][z]
		mondo.carica_zona(z, ["lance", "nox", "saul", "rio"], dz.get("comparse", {}), dz.get("punti", []))
		for i in 20:
			await process_frame
		var d := {"mesh": 0, "luci": 0}
		_conta(mondo, d)
		var t0 := Time.get_ticks_usec()
		for i in 60:
			await process_frame
		var ms := (Time.get_ticks_usec() - t0) / 60000.0
		print("MISURA %-10s draw=%d oggetti=%d primitive=%d mesh=%d luci=%d ms/frame=%.1f" % [z,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), d["mesh"], d["luci"], ms])
	quit(0)
