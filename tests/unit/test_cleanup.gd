extends SceneTree

# Ottimizzazioni: materiali condivisi, stili dei pulsanti condivisi, schermata di battaglia
# che non ricostruisce i nodi se nulla e' cambiato, livello statico dello sfondo.
#   godot --headless --path . -s res://tests/unit/test_cleanup.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_cleanup_tmp.json"


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

	# --- ScreenFx
	var host := Control.new()
	root.add_child(host)
	var a: ColorRect = ScreenFx.cctv(host)
	var b: ColorRect = ScreenFx.cctv(host)
	_check("cctv: materiale condiviso", a.material == b.material and a.material != null)
	_check("cctv: non cattura il mouse", a.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var h1: ColorRect = ScreenFx.halftone(host)
	var h2: ColorRect = ScreenFx.halftone(host)
	_check("retino: materiale condiviso", h1.material == h2.material)
	var v1: ColorRect = ScreenFx.battle(host)
	var v2: ColorRect = ScreenFx.battle(host)
	_check("velo battaglia: materiale condiviso", v1.material == v2.material)
	var solid: ColorRect = ScreenFx.solid(host, BattleTheme.BK)
	_check("fondo pieno", solid.color == BattleTheme.BK and solid.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var before: int = host.get_child_count()
	ScreenFx.menu_overlays(host, BattleTheme.RD)
	_check("overlay dei menu: strisce + un solo velo", host.get_child_count() == before + 2)
	var shader_ok: bool = (load("res://shaders/battle_overlay.gdshader") as Shader) != null
	_check("shader unico compilato", shader_ok)

	# --- stili dei pulsanti condivisi
	var b1 := Button.new()
	var b2 := Button.new()
	BattleTheme.style_button(b1, "primary", 20)
	BattleTheme.style_button(b2, "primary", 30)
	_check("stili dei pulsanti: stesso oggetto", b1.get_theme_stylebox("normal") == b2.get_theme_stylebox("normal"))
	_check("stili diversi per tipo", b1.get_theme_stylebox("normal") != _styled("normal").get_theme_stylebox("normal"))
	_check("dimensione del testo per pulsante", b1.get_theme_font_size("font_size") == 20 and b2.get_theme_font_size("font_size") == 30)
	b1.free()
	b2.free()

	# --- Snd / Notify senza autoload nei test: non fanno nulla ne' falliscono
	Snd.play("click")
	Notify.toast("prova")
	_check("Snd e Notify tollerano l'assenza dei gestori", true)

	# --- Battaglia: i nodi non si ricostruiscono se non cambia nulla
	var src := SoloBattleSource.new()
	src.save_path = TMP
	src.start(RosterState.new_roster(), "distributore", 91)
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	scene.pending_source = src
	scene.event_delay = 0.0
	root.add_child(scene)
	await process_frame
	await process_frame
	var first_order: Node = scene._orders_box.get_child(0)
	var first_op: Node = scene._ops_box.get_child(0)
	scene._refresh_orders()
	scene._refresh_operators()
	_check("ordini: nodi invariati se lo stato e' lo stesso", scene._orders_box.get_child(0) == first_order)
	_check("operatori: nodi invariati se lo stato e' lo stesso", scene._ops_box.get_child(0) == first_op)
	var me: Dictionary = BattleState.player(scene.shown, "p1")
	var bench: String = str(BattleState.back_row(scene.shown, me)[0])
	scene._on_unit_pressed(bench)
	await process_frame
	_check("operatori: il cambio ricostruisce la lista", scene._ops_box.get_child(0) != first_op)
	_check("ordini: il cambio ricostruisce i pulsanti", scene._orders_box.get_child(0) != first_order)
	var shown_unit: Dictionary = BattleState.unit(scene.shown, bench)
	_check("ordini: un pulsante per azione base, skill e ultimate", scene._order_buttons.size() == (shown_unit["skills"] as Array).size() + 1)
	scene._on_unit_pressed(bench)
	await process_frame
	_check("ordini: annullare il cambio rimette i pulsanti", scene._order_buttons.size() == (BattleState.unit(scene.shown, scene.shown["players"][0]["active"])["skills"] as Array).size() + 1 and scene._orders_box.get_child_count() > 0)
	scene.locked = true
	scene._refresh_orders()
	_check("ordini: bloccando la schermata il ventaglio sparisce", scene._order_buttons.is_empty() and scene._orders_box.get_child_count() == 0)
	scene.locked = false
	scene._refresh_orders()
	_check("ordini: sbloccando si riaccendono", not scene._order_buttons[0].disabled)

	# orologio e timer: si aggiornano solo quando cambiano
	scene._process(0.016)
	var clock: String = scene._clock_label.text
	scene._process(0.016)
	_check("orologio: testo stabile nello stesso secondo", scene._clock_label.text == clock and clock != "")

	# --- Livello statico dello sfondo
	var stage: BattleStage = scene._stage
	_check("sfondo: il livello statico c'e' e si vede solo se non ci sono le tue immagini", stage._bg_static != null and stage._bg_static.visible == stage._bg_layers.is_empty())
	_check("sfondo disegnato: dietro al resto", stage._bg_static.show_behind_parent)
	_check("coseni gia' pronti per le ellissi", stage._ellipse(Vector2.ZERO, 10.0, 5.0, 16).size() == 16)
	_check("ellisse: punti sul bordo", is_equal_approx(stage._ellipse(Vector2(100, 50), 10.0, 5.0, 4)[0].x, 110.0))
	_check("testo in cache: stessa larghezza", stage._tag_width("ID-01 KIRA") == stage._tag_width("ID-01 KIRA") and stage._tag_width("ID-01 KIRA") > 0.0)
	scene.queue_free()
	await process_frame

	# con le tue immagini il livello statico si nasconde
	ArtLibrary.extra_roots = [ProjectSettings.globalize_path("user://test_cleanup_art")]
	var path: String = ProjectSettings.globalize_path("user://test_cleanup_art/backgrounds/battle/layer_1.png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var img := Image.create(32, 18, false, Image.FORMAT_RGBA8)
	img.save_png(path)
	ArtLibrary.refresh()
	var src2 := SoloBattleSource.new()
	src2.save_path = TMP
	src2.start(RosterState.new_roster(), "distributore", 5)
	var scene2: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	scene2.pending_source = src2
	root.add_child(scene2)
	await process_frame
	await process_frame
	_check("con grafiche di sfondo il livello statico e' nascosto", not scene2._stage._bg_static.visible)
	scene2.queue_free()
	await process_frame
	ArtLibrary.extra_roots = []
	ArtLibrary.refresh()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))

	# --- PortraitView: con la grafica non gira piu' per frame
	var pv := PortraitView.new().setup("kira", "bust")
	root.add_child(pv)
	await process_frame
	_check("ritratto senza grafica: animato", pv.is_processing())
	pv.queue_free()

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _styled(kind: String) -> Button:
	var b := Button.new()
	BattleTheme.style_button(b, "normal", 16)
	return b
