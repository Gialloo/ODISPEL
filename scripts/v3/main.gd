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
	"controsegnale": "res://scripts/controsegnale/cs_scene.gd",   # combattimento in tempo reale a contrattacchi (modo separato)
	"prova_grezza": "res://scripts/prova_grezza/pg_scene.gd",     # prova grezza del core CONTROSEGNALE v2: Manichino contro un nemico
	"prova_arena": "res://scripts/prova_grezza/pg_arena_scene.gd",   # prova grezza 2: arena circolare, squadra da 4 (12/11 sera)
	"prova_iso": "res://scripts/prova_grezza/pg_iso_scene.gd",       # prova grezza 3: di nuovo a scorrimento, camera isometrica, cambio squadra
}

var current: Node = null
var _overlay: CanvasLayer
var _fade: ColorRect
var _fps: Label
var _busy: bool = false
var _pending: Array = []          # cambio di schermata chiesto durante un altro cambio: [schermata, argomenti]
var _going: Array = []            # cambio in corso: [schermata, argomenti]
signal screen_shown               # la nuova schermata e' nell'albero (prima della dissolvenza di uscita)

# PRE-CARICAMENTO (8/11/2026): la prima volta che si entrava in battaglia il gioco si fermava ~0,9 s (strada ~0,5 s su PC,
# il triplo sul telefono) solo per leggere e compilare il codice della schermata e tutto quello che usa. Ora, appena il menu e'
# a schermo, le schermate pesanti si caricano in un altro thread mentre si gioca: al cambio sono gia' pronte.
const PRELOAD: Array = ["area", "battle"]
var _preloading: Array = []       # percorsi chiesti al caricatore in sottofondo e non ancora ritirati
var _ready_scripts: Dictionary = {}   # percorso -> script gia' pronto (tenuto qui perche' resti in memoria)


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
	screen_shown.connect(_preload_screens, CONNECT_ONE_SHOT)
	if DisplayServer.get_name() != "headless":
		var warm := ShaderWarmup.new()
		warm.extra_2d = [TEAR_SHADER]          # lo strappo del nastro all'ingresso in battaglia (prima si compilava al contatto)
		add_child(warm)


func _preload_screens() -> void:
	for k in PRELOAD:
		var p: String = SCREENS[k]
		if _ready_scripts.has(p) or ResourceLoader.has_cached(p):
			continue
		if ResourceLoader.load_threaded_request(p) == OK:
			_preloading.append(p)


# Ritira gli script finiti di caricare (un controllo leggero, solo finche' ce n'e' qualcuno in corso)
func _collect_preloads() -> void:
	for p in _preloading.duplicate():
		var st: int = ResourceLoader.load_threaded_get_status(p)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			_ready_scripts[p] = ResourceLoader.load_threaded_get(p)
			_preloading.erase(p)
		elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_preloading.erase(p)          # si carichera' come prima, al cambio


func _screen_script(path: String) -> GDScript:
	if _ready_scripts.has(path):
		return _ready_scripts[path]
	if _preloading.has(path):
		# ancora in corso: si aspetta la fine di quel caricamento (mai piu' lento di prima, spesso quasi finito)
		_preloading.erase(path)
		var res: Resource = ResourceLoader.load_threaded_get(path)
		if res is GDScript:
			_ready_scripts[path] = res
			return res
	return load(path)


func _process(_delta: float) -> void:
	if not _preloading.is_empty():
		_collect_preloads()
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
	var script: GDScript = _screen_script(SCREENS.get(screen, SCREENS["menu"]))
	current = script.new()
	current.name = screen.capitalize()
	if current.has_method("configure"):
		current.call("configure", args)
	add_child(current)
	move_child(current, 0)
	await get_tree().process_frame
	screen_shown.emit()
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


# INGRESSO IN BATTAGLIA «NASTRO STRAPPATO» (idea 2, 4/11/2026): l'ultima immagine della strada si disturba come una
# VHS che si inceppa, poi si strappa in diagonale e la battaglia esce dallo strappo. Il mondo di ODISPEL e' ripreso
# da telecamere (Rio, i replay): entrare in scontro e' un nastro che salta. Un solo shader 2D sopra a tutto, una sola
# lettura dello schermo al momento del contatto: nessun costo durante la battaglia.
const TEAR_SHADER: String = """
shader_type canvas_item;
uniform sampler2D src : filter_linear;
uniform float prog = 0.0;
uniform float open = 0.0;
uniform float t = 0.0;
float h(float x) { return fract(sin(x * 127.1) * 43758.5453); }
vec3 vhs(vec2 uv) {
	float band = floor(uv.y * 26.0 + t * 7.0);
	float roll = fract(t * 0.7);
	float bar = smoothstep(0.07, 0.0, abs(uv.y - roll));
	uv.x += (h(band + floor(t * 18.0)) - 0.5) * 0.05 * prog + bar * 0.03 * prog;
	float ca = 0.006 * prog + bar * 0.008;
	vec3 c = vec3(texture(src, uv + vec2(ca, 0.0)).r, texture(src, uv).g, texture(src, uv - vec2(ca, 0.0)).b);
	float n = h(uv.y * 811.0 + uv.x * 1301.0 + floor(t * 30.0));
	c = mix(c, vec3(n), (0.10 + bar * 0.35) * prog);
	c *= 1.0 - 0.16 * prog * step(0.5, fract(uv.y * 170.0));
	return c;
}
float tear_line(float x) {
	return 0.5 + 0.16 * (x - 0.5) + (h(floor(x * 13.0) + 3.0) - 0.5) * 0.05 + (h(floor(x * 61.0) + 7.0) - 0.5) * 0.016;
}
void fragment() {
	vec2 uv = UV;
	float gap = open * open * 0.62;
	float edge = 0.010 + 0.006 * h(floor(uv.x * 140.0));
	vec2 st = uv + vec2(0.05 * open, gap);
	vec2 sb = uv - vec2(0.05 * open, gap);
	float lt = tear_line(st.x);
	float lb = tear_line(sb.x);
	if (st.y < lt) {
		COLOR = vec4(vhs(st), 1.0);
	} else if (st.y < lt + edge && open > 0.0) {
		COLOR = vec4(0.93, 0.89, 0.80, 1.0);
	} else if (sb.y > lb) {
		COLOR = vec4(vhs(sb), 1.0);
	} else if (sb.y > lb - edge && open > 0.0) {
		COLOR = vec4(0.93, 0.89, 0.80, 1.0);
	} else {
		COLOR = vec4(0.0);
	}
}
"""


func go_tear(screen: String, args: Dictionary = {}) -> void:
	var img: Image = null
	if not _busy and DisplayServer.get_name() != "headless" and not Settings.skip_cutin:
		img = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		go(screen, args)            # senza immagine (o durante un altro cambio) resta la dissolvenza di sempre
		return
	var tr: Array = _tear_rect(img)
	var rect: ColorRect = tr[0]
	var mat: ShaderMaterial = tr[1]
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var clock := func(v: float) -> void: mat.set_shader_parameter("t", v)
	var run := create_tween().set_ignore_time_scale(true)
	run.tween_method(clock, 0.0, 4.0, 4.0)
	var noise := create_tween().set_ignore_time_scale(true)
	noise.tween_method(func(v: float) -> void: mat.set_shader_parameter("prog", v), 0.0, 1.0, 0.3)
	go(screen, args)
	await screen_shown
	# la battaglia e' pronta: il nero della dissolvenza non serve, si vede dallo strappo
	_fade.color.a = 0.0
	if _carico != null:
		_carico.modulate.a = 0.0
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("open", v), 0.0, 1.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	run.kill()
	rect.queue_free()


static var _tear_sh: Shader = null


func _tear_rect(img: Image) -> Array:
	if _tear_sh == null:
		_tear_sh = Toon.shared_shader(TEAR_SHADER)      # stesso Shader del riscaldamento (ShaderWarmup): niente compilazione al contatto
	var mat := ShaderMaterial.new()
	mat.shader = _tear_sh
	mat.set_shader_parameter("src", ImageTexture.create_from_image(img))
	var rect := ColorRect.new()
	rect.material = mat
	Ui.place(rect, 0, 0, 1, 1)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(rect)
	return [rect, mat]


# LO SQUARCIO (boss a due fasi, idea 3): l'immagine di adesso si strappa e sotto c'e' gia' l'arena cambiata.
# Chi chiama cambia luce e colori nel fotogramma dopo: lo strappo li rivela. Ritorna false se non si puo' (headless).
func tear_now(secs: float = 0.6) -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	var img: Image = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return false
	var tr: Array = _tear_rect(img)
	var rect: ColorRect = tr[0]
	var mat: ShaderMaterial = tr[1]
	mat.set_shader_parameter("prog", 0.8)
	var tw := create_tween().set_ignore_time_scale(true).set_parallel(true)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("t", v), 0.0, secs * 2.0, secs)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("open", v), 0.0, 1.0, secs) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(rect.queue_free)
	return true


# PRESTAZIONI: il 3D si disegna a risoluzione ridotta (circa 720 righe su telefono, 1080 su PC), l'interfaccia resta nitida.
# Sui telefoni lo schermo e' spesso 2400x1080: disegnare il 3D a piena risoluzione costa piu' del doppio.
# SCHERMATA DI CARICAMENTO (variante "ricordo" di Rio, 3/11/2026): chiaro, biondo, con i riflessi olografici, ha l'aria di
# un ricordo sbiadito. Sta sopra al nero della dissolvenza solo per strada e battaglia 3D, dove il caricamento si sente;
# la texture (768x1024) si carica una volta sola. Senza il disegno la dissolvenza resta nera come prima.
const CARICO_SU: Array = ["area", "battle", "controsegnale", "prova_grezza", "prova_arena", "prova_iso"]
var _carico: Control


func _build_carico() -> void:
	# per ora solo la scritta (autore, 3/11/2026): il disegno «ricordo» torna con RitrattoVarianti.attive
	var t: Texture2D = RitrattoVarianti.tex("rio", "ricordo")
	_carico = Control.new()
	Ui.place(_carico, 0, 0, 1, 1)
	_carico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carico.modulate = Color(1, 1, 1, 0)
	_carico.visible = false
	_fade.add_child(_carico)
	if t != null:
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
