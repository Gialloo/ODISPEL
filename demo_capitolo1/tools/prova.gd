extends SceneTree
## Gioca la prova da sola e salva le schermate.
## xvfb-run -a godot --path . --resolution 1280x720 -s tools/prova.gd -- prova <cartella> [scelta=0|1]

var main: Node
var ui
var mondo
var out := "/tmp/prova"
var scelta := 0
var n := 0
var foto_righe := true

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("scelta="):
			scelta = int(a.substr(7))
		elif a != "prova":
			out = a
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_gioca()

func foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, nome])

func aspetta(s: float) -> void:
	await create_timer(s).timeout

## Fa avanzare i dialoghi da solo; fotografa le righe se richiesto.
func _avanzatore() -> void:
	while true:
		await aspetta(0.25)
		if ui.attivo and not ui._in_scelta and not ui._scrivendo and ui._box.visible:
			await aspetta(0.5)
			if foto_righe:
				await foto("riga")
			if ui.attivo and not ui._in_scelta:
				ui.avanti.emit()
		elif ui._in_scelta:
			await aspetta(0.5)
			await foto("scelta")
			ui.scelto.emit(scelta)

func aspetta_libero() -> void:
	var t := 0.0
	while main.occupato or not mondo.controllo:
		await aspetta(0.2)
		t += 0.2
		if t > 90.0:
			push_error("PROVA: bloccata in attesa")
			quit(1)
			return

func cammina(x: float, z: float) -> void:
	var t := 0.0
	var fermo := 0.0
	var ultimo := Vector3.ZERO
	while t < 20.0:
		var g: Node3D = mondo.guida()
		var d := Vector2(x - g.position.x, z - g.position.z)
		if d.length() < 0.35 or not mondo.controllo:
			break
		# lo stick è relativo alla camera: lo ruoto nel suo sistema
		var v := d.normalized().rotated(mondo.yaw)
		mondo.input_stick = v
		await process_frame
		t += 1.0 / 60.0
		fermo = fermo + 1.0 / 60.0 if g.position.distance_to(ultimo) < 0.005 else 0.0
		ultimo = g.position
		if fermo > 1.0:
			print("PROVA: fermo a %s verso (%.1f, %.1f)" % [g.position, x, z])
			break
	mondo.input_stick = Vector2.ZERO

func guida_di(chi: String) -> void:
	var giri := 0
	while mondo.gruppo[0] != chi and giri < 5:
		main.cambia_guida()
		giri += 1
		await aspetta(0.2)

## Percorre le tappe, poi si avvicina al punto ed esamina.
func esamina_punto(id: String, tappe: Array, nome := "") -> void:
	if nome == "":
		nome = id
	for tp in tappe:
		await cammina(tp[0], tp[1])
		await aspetta_libero()
	await aspetta(0.3)
	await foto(nome + "_avviso")
	var pt: Dictionary = {}
	for p in mondo.punti:
		if p["id"] == id:
			pt = p
	await cammina(pt["pos"][0], pt["pos"][1])
	await aspetta_libero()
	await cammina(pt["pos"][0], pt["pos"][1])
	await aspetta(0.3)
	if main.punto_vicino == null or main.punto_vicino["id"] != id:
		push_error("PROVA: punto %s non vicino (guida a %s)" % [id, mondo.guida().position])
		quit(1)
		return
	await foto(nome + "_vicino")
	main.esamina()
	await aspetta(0.4)
	await aspetta_libero()

func _gioca() -> void:
	await process_frame
	ui = main.ui
	mondo = main.mondo
	main.avvia()
	await aspetta(1.0)
	await foto("titolo")
	ui.avanti.emit()
	await aspetta(0.9)
	await foto("cartello")
	_avanzatore()
	await aspetta_libero()
	await foto("vicolo_libero")
	await esamina_punto("bossoli", [[-1.5, -3.0]])
	await esamina_punto("accendino", [[1.5, -9.0]])
	await esamina_punto("zaino", [[0.0, -14.0], [12.5, -14.2]])
	await esamina_punto("pozzanghera", [[9.0, -17.0]])
	await esamina_punto("distributore", [[0.0, -18.0], [-1.6, -23.0]])
	await esamina_punto("scarpa", [[0.5, -28.0]])
	await cammina(0.0, -28.0)
	await aspetta_libero()
	await cammina(0.0, -40.0)
	while mondo.zona != "rifugio":
		await aspetta(0.3)
	await aspetta_libero()
	await foto("rifugio_libero")
	await esamina_punto("parla_nox", [])
	await esamina_punto("parla_saul", [])
	await esamina_punto("parla_rio", [])
	await esamina_punto("calzino", [[-101.0, -4.5]])
	await esamina_punto("bacheca", [[-97.0, -3.0]])
	await esamina_punto("porta", [[-100.0, 1.5]])
	while mondo.zona != "quartiere":
		await aspetta(0.3)
	await aspetta_libero()
	await foto("quartiere_libero")
	foto_righe = false
	await guida_di("saul")
	await esamina_punto("piastrella", [[110.0, 4.0], [104.0, -18.0]])
	await guida_di("nox")
	await esamina_punto("glifo", [[120.0, -17.0]])
	await guida_di("rio")
	await esamina_punto("grata", [[112.0, 2.0]])
	await guida_di("lance")
	await esamina_punto("transenna", [[120.0, 1.0]])
	await esamina_punto("motorino", [[123.0, -6.0]])
	await esamina_punto("murale", [[110.0, -6.0], [96.0, -6.0]])
	foto_righe = true
	await guida_di("saul")
	await esamina_punto("manifesto", [[104.0, 5.0]])
	foto_righe = false
	await guida_di("nox")
	await esamina_punto("palazzo", [[103.0, -10.0]])
	foto_righe = true
	await esamina_punto("varco", [[110.0, -22.0]])
	# 0.5: dentro il varco, il nido
	while mondo.zona != "nido":
		await aspetta(0.3)
	await aspetta_libero()
	await foto("nido_libero")
	foto_righe = false
	await guida_di("lance")
	await esamina_punto("radio", [[201.5, -2.0]])
	await guida_di("nox")
	await esamina_punto("vene", [[200.5, -6.0]])
	await esamina_punto("telefono", [[199.0, 1.0]])
	await esamina_punto("bozzolo", [[199.0, -13.0], [196.5, -15.0]])
	await guida_di("saul")
	await esamina_punto("orologio", [[206.0, -22.0], [208.5, -29.0]])
	await esamina_punto("cuffie", [[208.0, -20.0]])
	await guida_di("rio")
	foto_righe = true
	await esamina_punto("reperto", [[200.0, -29.0], [192.5, -28.5], [191.0, -24.5]])
	# 0.7: la dispensa (ala ovest) e le culle (ala est)
	await esamina_punto("mucchio", [[190.0, -31.0], [186.0, -31.0], [181.0, -31.0]])
	foto_righe = false
	await esamina_punto("fototessera", [[175.0, -40.0]])
	await guida_di("saul")
	await esamina_punto("fermata", [[178.0, -27.0]])
	await guida_di("lance")
	await esamina_punto("vetrina", [[175.0, -24.0]])
	# 0.8: il pozzo, oltre la dispensa
	await esamina_punto("targa", [[169.0, -28.0], [166.0, -33.0], [160.0, -31.0], [144.0, -31.0]])
	await esamina_punto("pozzo", [[160.0, -30.0]])
	await esamina_punto("palloncino", [[160.0, -44.0]])
	await guida_di("nox")
	await esamina_punto("lampione", [[160.0, -30.0], [146.0, -27.0]])
	await guida_di("nox")
	foto_righe = true
	await esamina_punto("uova", [[160.0, -30.0], [166.0, -33.0], [169.0, -28.0], [180.0, -28.0], [186.0, -31.0], [200.0, -30.0], [208.0, -21.0], [219.0, -21.0]])
	foto_righe = false
	await guida_di("rio")
	await esamina_punto("culla", [[224.0, -15.0]])
	await guida_di("lance")
	await esamina_punto("tacche", [[229.0, -13.0]])
	await esamina_punto("fischietto", [[226.0, -24.0]])
	# 0.8: la gola, oltre le culle
	await guida_di("saul")
	await esamina_punto("voci", [[230.0, -21.0], [238.0, -21.0]])
	await guida_di("lance")
	await esamina_punto("casco", [[256.0, -21.0], [257.0, -33.0]])
	await esamina_punto("chiave", [[250.0, -36.0]])
	await guida_di("rio")
	await esamina_punto("scritta", [[250.0, -36.0], [256.0, -33.0], [256.0, -21.0], [241.0, -21.0], [241.0, -8.0], [252.0, -7.0]])
	await guida_di("lance")
	foto_righe = true
	await esamina_punto("cuore", [[241.0, -8.0], [241.0, -21.0], [230.0, -21.0], [214.0, -21.0], [208.0, -22.0], [200.0, -30.0], [200.0, -38.0]])
	await aspetta(3.0)
	await foto("fine")
	print("PROVA TRACCE: %s" % main.tracce())
	print("PROVA OK: %d schermate, fatti: %s" % [n, ", ".join(mondo.fatti.keys())])
	quit(0)
