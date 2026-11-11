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
	while t < 20.0:
		var g: Node3D = mondo.guida()
		var d := Vector2(x - g.position.x, z - g.position.z)
		if d.length() < 0.4 or not mondo.controllo:
			break
		mondo.input_stick = d.normalized()
		await process_frame
		t += 1.0 / 60.0
	mondo.input_stick = Vector2.ZERO

func guida_di(chi: String) -> void:
	var giri := 0
	while mondo.gruppo[0] != chi and giri < 5:
		main.cambia_guida()
		giri += 1
		await aspetta(0.2)

func esamina_punto(x: float, z: float, nome: String) -> void:
	await cammina(x, z + 3.5)
	await aspetta(0.25)
	await foto(nome + "_avviso")
	await cammina(x, z)
	await aspetta(0.3)
	if main.punto_vicino == null:
		push_error("PROVA: nessun punto da esaminare a %s" % nome)
	else:
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
	await esamina_punto(2.2, -9.0, "bossoli")
	await esamina_punto(-1.9, -17.0, "distributore")
	await cammina(0.0, -21.0)
	await aspetta(0.6)
	await foto("sagoma")
	await esamina_punto(1.9, -26.6, "sacca")
	await cammina(0.0, -35.0)
	await aspetta(0.2)
	# la regia dell'incontro con Rio parte da sola
	while mondo.zona != "quartiere":
		await aspetta(0.3)
	await aspetta_libero()
	await foto("quartiere_libero")
	foto_righe = false
	await guida_di("saul")
	await esamina_punto(101.0, -13.8, "piastrella")
	await guida_di("nox")
	await esamina_punto(118.0, -20.0, "glifo")
	await guida_di("rio")
	await esamina_punto(112.0, 2.0, "grata")
	await guida_di("lance")
	await esamina_punto(122.0, -1.6, "transenna")
	foto_righe = true
	await guida_di("saul")
	await esamina_punto(106.0, 4.0, "manifesto")
	await guida_di("nox")
	await esamina_punto(115.0, -15.0, "palazzo")
	await aspetta(1.0)
	await foto("fine")
	print("PROVA OK: %d schermate, taccuino %d voci: %s" % [n, main.taccuino.size(), ", ".join(main.taccuino)])
	quit(0)
