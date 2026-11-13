extends SceneTree
## Fotografa la camera di esplorazione in punti fissi, senza giocare.
## xvfb-run -a godot --path . --resolution 1280x720 -s tools/inquadra.gd -- <cartella>
var out := "/tmp/inquadra"
const PROVE := [
	["vicolo", ["lance"], 0.0, 2.5, 0.0],
	["vicolo", ["lance"], 0.0, -10.0, 0.0],
	["vicolo", ["lance"], 12.0, -14.0, -1.57],
	["rifugio", ["lance", "nox", "saul", "rio"], -100.0, 2.6, 0.0],
	["rifugio", ["lance", "nox", "saul", "rio"], -98.0, -3.0, 1.57],
	["quartiere", ["lance", "nox", "saul", "rio"], 110.0, 17.0, 0.0],
	["quartiere", ["nox", "lance", "saul", "rio"], 121.5, -15.0, -1.57],
	["quartiere", ["lance", "nox", "saul", "rio"], 110.0, -6.0, 0.0],
	["nido", ["lance", "nox", "saul", "rio"], 200.0, 6.0, 0.0],
	["nido", ["lance", "nox", "saul", "rio"], 200.0, -28.0, 0.0],
	["nido", ["lance", "nox", "saul", "rio"], 200.0, -40.0, 0.0],
]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is CanvasLayer:
			c.visible = false
	var i := 0
	for p in PROVE:
		main._zona(p[0], p[1])
		var m = main.mondo
		var g: Node3D = m.guida()
		g.position = Vector3(p[2], 0, p[3])
		m.yaw = p[4]
		g.rotation.y = p[4] + PI
		for k in range(1, m.gruppo.size()):
			m.corpi[m.gruppo[k]].position = g.position + Basis(Vector3.UP, p[4]) * Vector3(0.9 * (k - 2), 0, 2.2)
		m._metti_camera(true)
		for f in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		i += 1
		root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, i, p[0]])
	quit(0)
