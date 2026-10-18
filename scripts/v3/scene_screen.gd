extends Control

# SCENA DI STORIA (stile Persona): sfondo illustrato 2D + dialogo con ritratti. Alla fine si passa al passo successivo.
# Usata per i passi "scena" e "rifugio" di data/atto1.json.

const BACKS: Dictionary = {
	"strada": {"top": "#1a0f30", "bot": "#3a1840", "luogo": "VIA DALLA PIAZZA" , "forme": "citta"},
	"rifugio": {"top": "#1e140c", "bot": "#3a2614", "luogo": "RIFUGIO · DEPOSITO DELLA METRO", "forme": "archi"},
	"anomalia_rossa": {"top": "#2a0710", "bot": "#5a0f22", "luogo": "DENTRO L'ANOMALIA", "forme": "vetri"},
	"anomalia_blu": {"top": "#060c2a", "bot": "#0f2050", "luogo": "DENTRO LA LINEA", "forme": "vetri"},
	"anomalia_verde": {"top": "#061f14", "bot": "#0f4028", "luogo": "DIETRO IL VETRO", "forme": "vetri"},
	"notte": {"top": "#0a0814", "bot": "#1a1430", "luogo": "NOTTE", "forme": "citta"},
	"caveau": {"top": "#0c0e14", "bot": "#2a3040", "luogo": "CAVEAU LIBRACORP", "forme": "sbarre"},
	"varco": {"top": "#12062a", "bot": "#4a1050", "luogo": "LA PIAZZA", "forme": "varco"},
	"alba": {"top": "#3a1a4a", "bot": "#ff9a6a", "luogo": "LA TANGENZIALE · ALBA", "forme": "citta"},
}

var passo: Dictionary = {}
var _t: float = 0.0
var _bg: Control
var _dialog: DialogBox
var _style: Dictionary = {}


func configure(args: Dictionary) -> void:
	passo = args.get("passo", {})


func crumb() -> String:
	return "dialogo"


func _ready() -> void:
	_fit()
	get_viewport().size_changed.connect(_fit)
	_style = BACKS.get(str(passo.get("sfondo", "rifugio")), BACKS["rifugio"])
	if str(passo.get("tipo", "")) == "rifugio":
		_style = BACKS["rifugio"]
	_bg = Control.new()
	Ui.place(_bg, 0, 0, 1, 1)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.draw.connect(_draw_bg)
	add_child(_bg)
	var place := Ui.label(str(_style["luogo"]).replace("%s", GameConfig.CITY), 22, Color(1, 1, 1, 0.75), Ui.display(), 6)
	place.position = Vector2(28, 22)
	add_child(place)
	var chap := Ui.label(Story.chapter_title(), 18, Ui.YELLOW, null, 5)
	chap.position = Vector2(28, 54)
	add_child(chap)
	_dialog = DialogBox.new()
	add_child(_dialog)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var key: String = str(passo.get("dialogo", ""))
	_dialog.play(DialogData.lines(key), DialogData.recap(key))
	await _dialog.finished
	await get_tree().create_timer(0.3 if _dialog.get("_recap_lbl").visible == false else 2.6).timeout
	if is_inside_tree():
		Story.advance()
		get_parent().next_story()


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func back() -> void:
	_dialog.skip()


func _process(delta: float) -> void:
	_t += delta
	_bg.queue_redraw()


func _draw_bg() -> void:
	var s: Vector2 = _bg.size
	var top: Color = Color(str(_style["top"]))
	var bot: Color = Color(str(_style["bot"]))
	var steps: int = 12
	for i in steps:
		var y0: float = s.y * float(i) / float(steps)
		_bg.draw_rect(Rect2(0, y0, s.x, s.y / float(steps) + 1.0), top.lerp(bot, float(i) / float(steps - 1)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	match str(_style["forme"]):
		"citta":
			var x: float = 0.0
			while x < s.x:
				var w: float = rng.randf_range(60, 150)
				var h: float = rng.randf_range(s.y * 0.25, s.y * 0.6)
				_bg.draw_rect(Rect2(x, s.y - h, w - 6, h), Color(0.04, 0.02, 0.08, 0.85))
				for k in int(h / 40.0):
					if rng.randf() < 0.35:
						_bg.draw_rect(Rect2(x + 12 + rng.randf_range(0, w - 40), s.y - h + 16 + 40 * k, 14, 18), Color(1.0, 0.8, 0.45, 0.6))
				x += w
		"archi":
			for k in 5:
				var cx: float = s.x * (0.1 + 0.2 * k)
				var r: float = s.y * 0.38
				_bg.draw_arc(Vector2(cx, s.y * 0.72), r, PI, TAU, 32, Color(0.6, 0.4, 0.2, 0.35), 22.0, true)
			_bg.draw_circle(Vector2(s.x * 0.5, s.y * 0.18), 30.0 + 3.0 * sin(_t * 2.0), Color(1.0, 0.8, 0.4, 0.5))
			_bg.draw_rect(Rect2(0, s.y * 0.72, s.x, s.y * 0.28), Color(0.08, 0.05, 0.03, 0.8))
		"vetri":
			for k in 9:
				var a: float = _t * 0.15 + k
				var c := Vector2(s.x * (0.1 + 0.1 * k), s.y * (0.3 + 0.2 * sin(a)))
				var pts := PackedVector2Array([c + Vector2(-40, -60), c + Vector2(50, -30), c + Vector2(20, 70), c + Vector2(-50, 40)])
				_bg.draw_colored_polygon(pts, Color(1, 1, 1, 0.06))
		"sbarre":
			for k in 14:
				var x2: float = s.x * float(k) / 13.0
				_bg.draw_rect(Rect2(x2, 0, 10, s.y), Color(0.6, 0.65, 0.75, 0.12))
			_bg.draw_circle(Vector2(s.x * 0.75, s.y * 0.4), s.y * 0.28, Color(0.5, 0.55, 0.65, 0.18))
		"varco":
			var c2 := Vector2(s.x * 0.5, s.y * 0.3)
			for k in 6:
				_bg.draw_circle(c2, 40.0 + 30.0 * k + 6.0 * sin(_t * 3.0 + k), Color(0.8, 0.5, 1.0, 0.07))
			_bg.draw_circle(c2, 34.0, Color(1.0, 0.95, 1.0, 0.8))
			for k in 8:
				var ang: float = TAU * float(k) / 8.0 + _t * 0.2
				_bg.draw_line(c2, c2 + Vector2(cos(ang), sin(ang)) * s.x, Color(1.0, 0.6, 1.0, 0.08), 6.0)
	# fasce oblique pop
	var off: float = fmod(_t * 40.0, 120.0)
	for k in range(-2, int(s.x / 120.0) + 4):
		var x0: float = k * 120.0 + off
		_bg.draw_line(Vector2(x0, s.y), Vector2(x0 + 260, s.y - 260), Color(1, 1, 1, 0.025), 22.0)
