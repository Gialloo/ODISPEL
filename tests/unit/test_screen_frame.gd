extends SceneTree

# Adattamento a schermi lunghi con notch (ScreenFrame), freccia di scelta, fulmine.
#   godot --headless --path . -s res://tests/unit/test_screen_frame.gd

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
	# riquadro centrato in una vista piu' larga (telefono 20:9)
	var box: Rect2 = ScreenFrame.box_for(Vector2(1600, 720), Vector4.ZERO)
	_check("20:9: il riquadro e' centrato", is_equal_approx(box.position.x, 160.0) and is_equal_approx(box.position.y, 0.0))
	_check("il riquadro e' sempre 1280x720", box.size == Vector2(1280, 720))
	var tall: Rect2 = ScreenFrame.box_for(Vector2(1280, 960), Vector4.ZERO)
	_check("4:3: il riquadro e' centrato in verticale", is_equal_approx(tall.position.y, 120.0) and is_equal_approx(tall.position.x, 0.0))
	var notch: Rect2 = ScreenFrame.box_for(Vector2(1440, 720), Vector4(100, 0, 60, 0))
	_check("notch: il riquadro sta tutto nell'area sicura", notch.position.x >= 100.0 and notch.end.x <= 1440.0 - 60.0 + 0.01)
	var tight: Rect2 = ScreenFrame.box_for(Vector2(1280, 720), Vector4(40, 0, 40, 0))
	_check("area sicura stretta: parte dal margine", is_equal_approx(tight.position.x, 40.0))

	# dimensione logica della finestra con margini
	ScreenFrame.test_insets = Vector4(100, 0, 60, 0)
	var cs: Vector2i = ScreenFrame.content_size(null)
	_check("la finestra logica include i margini", cs.x == 1440 and cs.y == 720)
	_check("view_insets restituisce i margini di prova", ScreenFrame.view_insets(null, Vector2(1440, 720)) == Vector4(100, 0, 60, 0))
	ScreenFrame.test_insets = Vector4.ZERO
	_check("senza margini la base e' 1280x720", ScreenFrame.content_size(null) == Vector2i(1280, 720))

	# gli sfondi escono dal riquadro, il resto no
	var holder := Control.new()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := HudPanel.new()
	var flat := Control.new()
	flat.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	holder.add_child(panel)
	holder.add_child(flat)
	_check("un ColorRect a tutto schermo e' uno sfondo", ScreenFrame.wants_bleed(bg))
	_check("un pannello no", not ScreenFrame.wants_bleed(panel))
	_check("un contenitore generico a tutto schermo no", not ScreenFrame.wants_bleed(flat))
	flat.set_meta("bleed", true)
	_check("con l'etichetta bleed si'", ScreenFrame.wants_bleed(flat))
	var dim := ColorRect.new()
	ScreenFrame.overshoot(dim)
	_check("overshoot copre ben oltre lo schermo", dim.offset_left <= -2000.0 and dim.offset_right >= 2000.0)
	holder.free()
	dim.free()

	# palco incorniciato: scala 1:1 e posizioni nelle coordinate del riquadro
	var stage := BattleStage.new()
	stage.size = Vector2(1600, 720)
	_check("palco non incorniciato: scala uniforme", is_equal_approx(stage._fit_scale(), 1.0))
	stage.set_frame_origin(Vector2(160, 0))
	_check("palco incorniciato: scala 1", is_equal_approx(stage._fit_scale(), 1.0) and stage._fit_origin() == Vector2(160, 0))
	stage.free()

	# fulmine: il percorso tiene ferme le estremita'
	var pts: PackedVector2Array = LightningFx.points(Vector2(10, 10), Vector2(310, 110), 5, 20.0, 8)
	_check("il fulmine parte e arriva dove deve", pts[0] == Vector2(10, 10) and pts[pts.size() - 1] == Vector2(310, 110))

	# chip munizioni: mai piu' di 6 icone
	var chip: InfoChip = InfoChip.ammo(10, 10, Color.WHITE)
	_check("le munizioni non superano 6 icone", chip._pips() == 6 and chip._pips_loaded() == 6)
	var half: InfoChip = InfoChip.ammo(5, 10, Color.WHITE)
	_check("le icone sono proporzionali", half._pips_loaded() == 3)
	chip.free()
	half.free()

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
