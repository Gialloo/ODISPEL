extends Node

# Radice del gioco: tiene UNA schermata alla volta (menu, strada, battaglia).
# Prima di caricare la successiva libera del tutto la precedente e aspetta un fotogramma,
# cosi' due scene 3D non stanno mai in memoria insieme (era uno dei sospetti del crash Android della V2).

const SCREENS: Dictionary = {
	"menu": "res://scripts/v3/menu.gd",
	"area": "res://scripts/v3/area.gd",
	"scene": "res://scripts/v3/scene_screen.gd",
	"card": "res://scripts/v3/card_screen.gd",
	"ending": "res://scripts/v3/ending_screen.gd",
	"battle": "res://scripts/v3/battle3d.gd",
}

var current: Node = null
var _overlay: CanvasLayer
var _fade: ColorRect
var _fps: Label
var _busy: bool = false
var _pending: Array = []          # cambio di schermata chiesto durante un altro cambio: [schermata, argomenti]
var _going: Array = []            # cambio in corso: [schermata, argomenti]


func _ready() -> void:
	Breadcrumb.read_previous()
	Breadcrumb.mark("avvio")
	Settings.ensure_loaded()
	Settings.apply_fps()
	_fit_3d_resolution()
	get_viewport().size_changed.connect(_fit_3d_resolution)
	get_tree().set_auto_accept_quit(false)
	_overlay = CanvasLayer.new()
	_overlay.layer = 90
	add_child(_overlay)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.02, 0.06, 1.0)
	Ui.place(_fade, 0, 0, 1, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_fade)
	_build_carico()
	_fps = Ui.label("", 18, Ui.CREAM, null, 4)
	_fps.position = Vector2(12, 6)
	_overlay.add_child(_fps)
	var screen: String = "menu"
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--screen="):
			screen = str(a).substr(9)
	go(screen)
	if DisplayServer.get_name() != "headless":
		add_child(ShaderWarmup.new())


func _process(_delta: float) -> void:
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Breadcrumb.mark("uscita")
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		Breadcrumb.mark("pausa")
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if current != null and current.has_method("crumb"):
			Breadcrumb.mark(str(current.call("crumb")))
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current != null and current.has_method("back"):
			current.call("back")


func go(screen: String, args: Dictionary = {}) -> void:
	# Durante un cambio la richiesta non si perde: si esegue appena finito (l'ultima vince).
	# Prima veniva ignorata: un tocco sul cartello durante la dissolvenza faceva avanzare la storia
	# ma lasciava la schermata ferma, senza piu' modo di proseguire.
	if _busy:
		if _going != [screen, args]:          # un doppio tocco sullo stesso pulsante non ricarica due volte
			_pending = [screen, args]
		return
	_busy = true
	_going = [screen, args]
	# durante la dissolvenza i tocchi non arrivano alle schermate (ne' alla vecchia ne' alla nuova)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	# le dissolvenze ignorano la pausa (time_scale 0): una pausa durante il cambio non deve bloccarle a meta'
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_fade, "color:a", 1.0, 0.25)
	# schermate pesanti (strada e battaglia 3D): nel nero del cambio appare Rio «ricordo» con CARICAMENTO
	var heavy: bool = _carico != null and screen in CARICO_SU
	if heavy:
		_carico.visible = true
		tw.parallel().tween_property(_carico, "modulate:a", 1.0, 0.25)
	await tw.finished
	if current != null:
		current.queue_free()
		current = null
	# due fotogrammi: la scena vecchia esce davvero dall'albero e libera le risorse prima della nuova
	await get_tree().process_frame
	await get_tree().process_frame
	var script: GDScript = load(SCREENS.get(screen, SCREENS["menu"]))
	current = script.new()
	current.name = screen.capitalize()
	if current.has_method("configure"):
		current.call("configure", args)
	add_child(current)
	move_child(current, 0)
	await get_tree().process_frame
	var tw2 := create_tween().set_ignore_time_scale(true)
	if heavy:
		tw2.tween_property(_carico, "modulate:a", 0.0, 0.15)
	tw2.tween_property(_fade, "color:a", 0.0, 0.3)
	await tw2.finished
	if heavy:
		_carico.visible = false
	_busy = false
	_going = []
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _pending.is_empty():
		var p: Array = _pending
		_pending = []
		go(str(p[0]), p[1])


# PRESTAZIONI: il 3D si disegna a risoluzione ridotta (circa 720 righe su telefono, 1080 su PC), l'interfaccia resta nitida.
# Sui telefoni lo schermo e' spesso 2400x1080: disegnare il 3D a piena risoluzione costa piu' del doppio.
# SCHERMATA DI CARICAMENTO (variante "ricordo" di Rio, 3/11/2026): chiaro, biondo, con i riflessi olografici, ha l'aria di
# un ricordo sbiadito. Sta sopra al nero della dissolvenza solo per strada e battaglia 3D, dove il caricamento si sente;
# la texture (768x1024) si carica una volta sola. Senza il disegno la dissolvenza resta nera come prima.
const CARICO_SU: Array = ["area", "battle"]
var _carico: Control


func _build_carico() -> void:
	var t: Texture2D = RitrattoVarianti.tex("zecca", "ricordo")
	if t == null:
		return
	_carico = Control.new()
	Ui.place(_carico, 0, 0, 1, 1)
	_carico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carico.modulate = Color(1, 1, 1, 0)
	_carico.visible = false
	_fade.add_child(_carico)
	var fig := TextureRect.new()
	fig.texture = t
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	fig.self_modulate = Color(1, 1, 1, 0.78)       # sbiadito: il nero dietro traspare un poco
	Ui.place(fig, 1, 0, 1, 1, -560, 30, 20, 40)
	fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carico.add_child(fig)
	var lb := Ui.label("CARICAMENTO", 30, Ui.CREAM, Ui.display(), 8)
	Ui.place(lb, 0, 1, 0, 1, 48, -96, 560, -40)
	_carico.add_child(lb)
	var rec := Ui.label("REPLAY · CAM 00", 18, Ui.CYAN, Ui.display(), 5)
	Ui.place(rec, 0, 1, 0, 1, 50, -132, 560, -98)
	_carico.add_child(rec)


func _fit_3d_resolution() -> void:
	var vp: Viewport = get_viewport()
	var h: float = float(DisplayServer.window_get_size().y)
	var want: float = 720.0 if OS.has_feature("mobile") else 1080.0
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = clampf(want / maxf(1.0, h), 0.5, 1.0)


# Passo corrente dell'atto 1 -> schermata giusta
func next_story() -> void:
	var sc: Array = Story.screen_for_current()
	go(str(sc[0]), sc[1])


func flash(strength: float = 1.0) -> void:
	var k: float = strength * Settings.flash
	if k <= 0.02:
		return
	var f := ColorRect.new()
	f.color = Color(1.0, 0.97, 0.9, 0.85 * k)
	Ui.place(f, 0, 0, 1, 1)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(f)
	var tw := f.create_tween().set_ignore_time_scale(true)
	tw.tween_property(f, "color:a", 0.0, 0.25)
	tw.tween_callback(f.queue_free)


func quit() -> void:
	Breadcrumb.mark("uscita")
	get_tree().quit()
