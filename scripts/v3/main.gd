extends Node

# Radice del gioco: tiene UNA schermata alla volta (menu, strada, battaglia).
# Prima di caricare la successiva libera del tutto la precedente e aspetta un fotogramma,
# cosi' due scene 3D non stanno mai in memoria insieme (era uno dei sospetti del crash Android della V2).

const SCREENS: Dictionary = {
	"menu": "res://scripts/v3/menu.gd",
	"street": "res://scripts/v3/street.gd",
	"battle": "res://scripts/v3/battle3d.gd",
}

var current: Node = null
var _overlay: CanvasLayer
var _fade: ColorRect
var _fps: Label
var _busy: bool = false


func _ready() -> void:
	Breadcrumb.read_previous()
	Breadcrumb.mark("avvio")
	Settings.ensure_loaded()
	Engine.max_fps = GameConfig.MAX_FPS
	get_tree().set_auto_accept_quit(false)
	_overlay = CanvasLayer.new()
	_overlay.layer = 90
	add_child(_overlay)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.02, 0.06, 1.0)
	Ui.place(_fade, 0, 0, 1, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_fade)
	_fps = Ui.label("", 18, Ui.CREAM, null, 4)
	_fps.position = Vector2(12, 6)
	_overlay.add_child(_fps)
	var screen: String = "menu"
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--screen="):
			screen = str(a).substr(9)
	go(screen)


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
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.25)
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
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.3)
	await tw2.finished
	_busy = false


func flash(strength: float = 1.0) -> void:
	var k: float = strength * Settings.flash
	if k <= 0.02:
		return
	var f := ColorRect.new()
	f.color = Color(1.0, 0.97, 0.9, 0.85 * k)
	Ui.place(f, 0, 0, 1, 1)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.25)
	tw.tween_callback(f.queue_free)


func quit() -> void:
	Breadcrumb.mark("uscita")
	get_tree().quit()
