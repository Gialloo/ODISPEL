extends SceneTree
## Fotografa i pezzi dell'interfaccia uno per uno, senza giocare.
## xvfb-run -a godot --path . --resolution 1280x720 -s tools/vetrina_ui.gd -- <cartella>
var out := "/tmp/vetrina_ui"
var n := 0

func foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, nome])

func aspetta(s: float) -> void:
	await create_timer(s).timeout

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var ui = main.ui
	main._zona("vicolo", ["lance"])
	main.mondo.camera_a("alto", 0.0)
	main._titolo()
	await aspetta(0.5)
	await foto("titolo")
	ui.avanti.emit()
	await aspetta(0.3)
	ui.nomi["nox"] = "NOX"
	ui.nomi["saul"] = "SAUL"
	for r in [
		{"narra": "Notte. Da tre sere, in questa via, i lampioni si spengono tutti insieme."},
		{"chi": "lance", "faccia": "serio", "testo": "Tre sere di fila, alla stessa ora. Una volta è un guasto. Tre no."},
		{"chi": "nox", "faccia": "neutro", "testo": "Non toccare niente. Se è magia, la stai già sporcando."},
		{"chi": "saul", "faccia": "sfotto", "testo": "Visto? Dico la verità e non mi crede nessuno. È la storia della mia vita."},
		{"chi": "rio", "testo": "Sniff."}]:
		ui.di(r)
		await aspetta(1.6)
		await foto("riga_" + str(r.get("chi", "narra")))
	ui.scegli(["Fermati! Mani dove le vedo!", "Lo prendo di sorpresa"])
	await aspetta(0.6)
	await foto("scelta")
	ui.scelto.emit(0)
	ui.chiudi()
	await aspetta(0.3)
	ui.vignetta("lance", "serio", "LANCE", 1.5)
	await aspetta(0.45)
	await foto("vignetta_lance")
	await aspetta(1.6)
	ui.vignetta("rio", "serio", "", 1.5)
	await aspetta(0.45)
	await foto("vignetta_rio")
	await aspetta(1.6)
	ui.trittico(["lance", "nox", "saul", "rio"], 1.5)
	await aspetta(0.7)
	await foto("trittico")
	await aspetta(1.5)
	ui.cartello("11 NOVEMBRE  ·  NOTTE", "Lance  ·  ricognizione, per conto suo")
	await aspetta(0.8)
	await foto("cartello")
	await aspetta(2.0)
	main._libera()
	main._hud.visible = true
	await aspetta(0.5)
	ui.balloon("lance", "Quel distributore è l'unica cosa accesa in tutta la via.", main.mondo.testa.bind("lance"), main.mondo.camera, 3.0)
	ui.onomato("CRUNCH")
	await aspetta(0.5)
	await foto("balloon")
	quit(0)
