extends SceneTree
## Fotografa il Saul v3 in esplorazione: fermo, mentre corre (davanti, di lato, dietro: il cappotto e la coda), seduto
## e con le espressioni. Senza giocare.
## xvfb-run -a godot --path . --resolution 1280x720 -s tools/saul_vetrina.gd -- <cartella>
var out := "/tmp/saul_vetrina"

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
	main._zona("quartiere", ["saul", "lance", "nox", "rio"])
	var m = main.mondo
	var s: Node3D = m.corpi["saul"]
	s.position = Vector3(110, 0, 10)
	s.rotation.y = 0.0
	for k in ["lance", "nox", "rio"]:
		m.corpi[k].position = Vector3(108 + ["lance", "nox", "rio"].find(k) * 2.0, 0, 5)
	m.set_process(false)
	var cam := Camera3D.new()
	cam.fov = 40
	m.add_child(cam)
	cam.make_current()
	var modello: SaulModello = s.find_children("saul_modello", "", true, false)[0]
	modello.riposa()
	await _scatta(cam, s, Vector3(0, 1.2, 4.2), "01_fermo_davanti")
	await _scatta(cam, s, Vector3(3.6, 1.2, 2.0), "02_fermo_tre_quarti")
	await _scatta(cam, s, Vector3(0, 1.3, -4.2), "03_fermo_dietro")
	await _scatta(cam, s, Vector3(0, 1.62, 1.1), "04_volto", 1.55)
	# corsa: avanti lungo +Z, coi passi del gioco
	var t := 0.0
	while t < 1.4:
		var d := 1.0 / 60.0
		s.position.z += 5.0 * d
		m._passi(s, 5.0, d)
		t += d
		await process_frame
	for nome in [["05_corsa_lato", Vector3(4.2, 1.1, 0)], ["06_corsa_dietro", Vector3(1.2, 1.3, -4.0)], ["07_corsa_davanti", Vector3(0.8, 1.2, 4.0)]]:
		for f in 4:
			s.position.z += 5.0 / 60.0
			m._passi(s, 5.0, 1.0 / 60.0)
			await process_frame
		await _scatta(cam, s, nome[1], nome[0])
	m._pose["saul"] = "seduto"
	for f in 30:
		m._anima_pose()
		m._passi(s, 0.0, 1.0 / 60.0)
		await process_frame
	await _scatta(cam, s, Vector3(3.0, 1.0, 2.6), "08_seduto")
	m._pose["saul"] = ""
	var i := 9
	for e in ["felice", "arrabbiato", "sorpreso", "triste", "sfotto"]:
		modello.espressione(e)
		await _scatta(cam, s, Vector3(0.25, 1.62, 1.0), "%02d_viso_%s" % [i, e], 1.56)
		i += 1
	quit(0)


func _scatta(cam: Camera3D, s: Node3D, off: Vector3, nome: String, y_guarda := 1.0) -> void:
	cam.global_position = s.global_position + off
	cam.look_at(s.global_position + Vector3(0, y_guarda, 0))
	for f in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, nome])
