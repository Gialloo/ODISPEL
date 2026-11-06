class_name QteIntro
extends Control

# PRESENTAZIONE DEL QTE (feedback dei tester sulla 0.59, 6/11/2026: «i QTE sono troppo immediati e mi spiazzano»).
# Il combattimento a turni e' calmo, il QTE e' frenetico: prima di ogni guardia a tempo e di ogni reazione c'e' un paio di
# secondi di respiro, come la presentazione del boss. Bande nere da cinema, chi agisce (il boss con la sua mossa, oppure il
# personaggio col suo ritratto e una battuta), COSA premere con un disegnino che lo mostra, e PERCHE' (meno danni, ecc.).
# Perche' due durate: la prima volta di ogni tipo in una battaglia si legge tutto (FULL); dopo basta ricordarlo (SHORT),
# senno' ogni turno del boss si allunga e si perde il ritmo (regola 5: divertirsi). Un tocco la chiude prima (dopo MIN).
# PRESTAZIONI: tre Label e un _draw di poche forme; vive ~1-3 s e si libera da solo. Tempo vero, fermo in pausa.
#   var q := QteIntro.new(); parent.add_child(q); q.setup_guard(...) o q.setup_react(...); await q.done

signal done

const FULL: float = 2.8
const SHORT: float = 1.3
const MIN_FULL: float = 0.7
const MIN_SHORT: float = 0.3
const IN_T: float = 0.22               # entrata (bande e scritte)
const OUT_T: float = 0.16              # uscita
const INK: Color = Color("#120a1c")

# Cosa si fa e perche', per ogni QTE. Il perche' e' la ricompensa: si capisce che conviene farlo bene.
const TITLE: Dictionary = {"guard": "DIFENDITI!", "arrow": "SCHIVA!", "hold": "COPRI!", "mash": "FERMALO!", "beat": "SOCCORRI!"}
const WHY: Dictionary = {
	"guard": "Così prendi meno danni. Proprio all'impatto è una PARATA PERFETTA",
	"arrow": "Se ti butti dalla parte giusta il colpo non ti prende",
	"hold": "Il colpo lo reggi tu e il compagno resta intero",
	"mash": "Più è piena la barra, più il nemico perde il tempo del suo colpo",
	"beat": "A tempo col cuore il compagno si rialza con più vita",
}
# espressione del ritratto per tipo (assets/portraits/<id>_<espressione>.png)
const FACE: Dictionary = {"arrow": "sfotto", "hold": "serio", "mash": "arrabbiato", "beat": "serio"}

var mode: String = "guard"
var col: Color = Color.WHITE
var who: String = ""                   # nome grande (boss o personaggio)
var line: String = ""                  # sotto il nome: la mossa del boss o la battuta del personaggio
var portrait: Texture2D = null
var dur: float = FULL
var min_t: float = MIN_FULL
var t: float = 0.0
var _closing: float = -1.0
var _touch: bool = false
var _title: Label
var _how: Label
var _why: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Ui.place(self, 0, 0, 1, 1)
	_touch = DisplayServer.is_touchscreen_available()


# Guardia a tempo: chi colpisce, con cosa, su chi.
func setup_guard(boss_name: String, move_name: String, target_name: String, c: Color, full: bool) -> void:
	mode = "guard"
	col = c
	who = boss_name
	var su: String = "TUTTA LA SQUADRA" if target_name == "" else target_name
	line = "usa %s su %s" % [move_name, su]
	_set_len(full)
	_build()


# Reazione: chi agisce, la sua battuta (testi in data/dialoghi_atto1.json, battaglia/qte_*), il suo ritratto.
func setup_react(game: String, char_name: String, quote: String, tex: Texture2D, c: Color, full: bool) -> void:
	mode = game
	col = c
	who = char_name
	line = quote
	portrait = tex
	_set_len(full)
	_build()


func _set_len(full: bool) -> void:
	dur = FULL if full else SHORT
	min_t = MIN_FULL if full else MIN_SHORT


static func how_text(m: String, touch: bool) -> String:
	var tap: String = "Tocca lo schermo" if touch else "Clicca o premi SPAZIO"
	match m:
		"guard":
			return "%s quando i due cerchi si toccano" % tap
		"arrow":
			return "Tocca il lato dello schermo indicato dalla freccia" if touch else "Premi la freccia della parte indicata (o clicca quel lato)"
		"hold":
			return ("Tieni premuto" if touch else "Tieni premuto SPAZIO") + " e lascia quando la barra è nella fascia"
		"mash":
			return ("Tocca a raffica" if touch else "Premi SPAZIO a raffica") + " finché la barra si riempie"
		"beat":
			return "%s quando il cuore batte, tre volte" % tap
	return ""


func _build() -> void:
	var has_face: bool = portrait != null
	var x0: float = 0.36 if has_face else 0.1
	_title = Ui.label(str(TITLE.get(mode, "")), 84, col.lightened(0.35), Ui.display(), 14)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_title, x0, 0.42, 0.95, 0.42, 0, -10, 0, 96)
	add_child(_title)
	_how = Ui.label(how_text(mode, _touch), 34, Ui.CREAM, null, 10)
	_how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.place(_how, x0, 0.6, 0.95, 0.6, 0, 0, 0, 90)
	add_child(_how)
	_why = Ui.label(str(WHY.get(mode, "")), 27, Ui.YELLOW, null, 8)
	_why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.place(_why, x0, 0.74, 0.95, 0.74, 0, 0, 0, 70)
	add_child(_why)


func _ready() -> void:
	_title.pivot_offset = Vector2(_title.size.x * 0.5, 48)
	_title.scale = Vector2(1.45, 1.45)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_title, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Settings.buzz(20)


func _process(delta: float) -> void:
	if Engine.time_scale <= 0.0:
		return              # pausa: il tempo della presentazione si ferma
	var rd: float = delta / Engine.time_scale
	t += rd
	if _closing < 0.0 and t >= dur:
		_closing = t
	var a: float = _alpha()
	for n in [_title, _how, _why]:
		(n as CanvasItem).modulate.a = a
	if _closing >= 0.0 and t - _closing >= OUT_T:
		set_process(false)
		done.emit()
		queue_free()
		return
	queue_redraw()


func _alpha() -> float:
	var a: float = clampf(t / IN_T, 0.0, 1.0)
	if _closing >= 0.0:
		a = minf(a, 1.0 - clampf((t - _closing) / OUT_T, 0.0, 1.0))
	return a


func _input(event: InputEvent) -> void:
	_try_skip(event)


# Un tocco (o SPAZIO/INVIO) chiude la presentazione, ma non prima di MIN: un tocco del turno prima non la salta.
func _try_skip(event: InputEvent) -> void:
	var tap: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode in [KEY_SPACE, KEY_ENTER])
	if not tap:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()
	if _closing < 0.0 and t >= min_t:
		_closing = t


func _draw() -> void:
	var sz: Vector2 = size
	var k: float = _alpha()
	var e: float = 1.0 - pow(1.0 - clampf(t / IN_T, 0.0, 1.0), 3.0)      # entrata con frenata
	# velo sulla scena e bande nere da cinema (la scena si ferma: ora conta solo questo)
	draw_rect(Rect2(Vector2.ZERO, sz), Color(INK.r, INK.g, INK.b, 0.55 * k))
	var bar: float = sz.y * 0.1 * e
	draw_rect(Rect2(0, 0, sz.x, bar), INK)
	draw_rect(Rect2(0, sz.y - bar, sz.x, bar), INK)
	draw_rect(Rect2(0, bar - 4.0, sz.x, 4.0), Color(col.r, col.g, col.b, 0.9 * k))
	draw_rect(Rect2(0, sz.y - bar, sz.x, 4.0), Color(col.r, col.g, col.b, 0.9 * k))
	# ritratto a sinistra su una fascia inclinata del suo colore (scivola dentro da sinistra)
	var has_face: bool = portrait != null
	if has_face:
		var ph: float = sz.y * 0.72
		var pw: float = ph * float(portrait.get_width()) / maxf(1.0, float(portrait.get_height()))
		var px: float = lerpf(-pw, sz.x * 0.02, e)
		var band := PackedVector2Array([Vector2(px - 40.0, sz.y * 0.16), Vector2(px + pw * 0.95, sz.y * 0.12),
			Vector2(px + pw * 0.8, sz.y * 0.9), Vector2(px - 40.0, sz.y * 0.9)])
		draw_colored_polygon(band, Color(col.r, col.g, col.b, 0.42 * k))
		draw_texture_rect(portrait, Rect2(px, sz.y * 0.9 - ph, pw, ph), false, Color(1, 1, 1, k))
	# cartellino: nome grande nel colore, sotto la mossa del boss o la battuta (come la presentazione del boss)
	var f: Font = Ui.display()
	var fb: Font = Ui.body()
	var x0: float = sz.x * (0.38 if has_face else 0.5)
	var nm_fs: int = 52
	var ln_fs: int = 34
	var w1: float = f.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, nm_fs).x
	var ln: String = ("«%s»" % line) if mode != "guard" and line != "" else line
	var w2: float = fb.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, ln_fs).x
	var bw_max: float = sz.x * (0.5 if has_face else 0.7)
	while ln_fs > 22 and w2 + 60.0 > bw_max:          # battuta lunga: si rimpicciolisce finche' entra nel cartellino
		ln_fs -= 2
		w2 = fb.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, ln_fs).x
	var bw: float = minf(maxf(w1, w2) + 60.0, bw_max)
	var bh: float = 108.0 if ln != "" else 70.0
	var cx: float = x0 + bw * 0.5 if has_face else sz.x * 0.45
	var c := Vector2(cx + (1.0 - e) * 160.0, sz.y * 0.27)
	draw_set_transform(c, deg_to_rad(-4.0), Vector2.ONE)
	var r := Rect2(-bw * 0.5, -bh * 0.5, bw, bh)
	draw_rect(Rect2(r.position + Vector2(9, 9), r.size), Color(col.r, col.g, col.b, 0.85 * k))
	draw_rect(r, Color(INK.r, INK.g, INK.b, 0.95 * k))
	draw_rect(r, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, 0.9 * k), false, 3.0)
	draw_string(f, Vector2(r.position.x + 28.0, r.position.y + 54.0), who, HORIZONTAL_ALIGNMENT_LEFT, bw - 40.0, nm_fs, Color(col.lightened(0.4), k))
	if ln != "":
		draw_string(fb, Vector2(r.position.x + 30.0, r.position.y + 92.0), ln, HORIZONTAL_ALIGNMENT_LEFT, bw - 40.0, ln_fs, Color(Ui.CREAM, k))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_demo(Vector2(sz.x * (0.9 if not has_face else 0.93), sz.y * 0.27), k)
	# quanto manca: una riga che si accorcia sulla banda di sotto, e l'invito a cominciare
	var left: float = 1.0 - clampf(t / dur, 0.0, 1.0)
	draw_rect(Rect2(0, sz.y - bar + 4.0, sz.x * left, 4.0), Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, 0.5 * k))
	if t >= min_t:
		var go: String = "TOCCA PER INIZIARE" if _touch else "CLICCA O SPAZIO PER INIZIARE"
		var pulse: float = 0.6 + 0.4 * sin(t * 7.0)
		# nella banda di sopra: sotto, a destra, ci sono le card della squadra
		draw_string(fb, Vector2(sz.x * 0.5 - 300.0, bar * 0.62), go, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 24, Color(Ui.CREAM, k * pulse))


# Disegnino in loop di cosa si fa (il "tutorial" in un colpo d'occhio): costa poche forme.
func _draw_demo(at: Vector2, k: float) -> void:
	var cyc: float = fmod(t, 1.1) / 1.1
	var c: Color = Color(col.lightened(0.3), k)
	var cr: Color = Color(Ui.CREAM, k)
	match mode:
		"guard":
			draw_arc(at, 34.0, 0.0, TAU, 40, cr, 5.0)
			draw_arc(at, lerpf(92.0, 34.0, cyc), 0.0, TAU, 40, c, 4.0)
			if cyc > 0.88:
				draw_circle(at, 22.0, Color(Ui.YELLOW, k))
		"arrow":
			var d: float = -1.0 if fmod(t, 2.2) < 1.1 else 1.0
			var tip := at + Vector2(46.0 * d, 0)
			draw_line(at - Vector2(40.0 * d, 0), tip, c, 9.0)
			draw_colored_polygon(PackedVector2Array([tip + Vector2(18.0 * d, 0), tip + Vector2(-14.0 * d, -24), tip + Vector2(-14.0 * d, 24)]), c)
		"hold":
			var h: float = 150.0
			var top: float = at.y - h * 0.5
			draw_rect(Rect2(at.x - 18.0, top, 36.0, h), Color(INK, k))
			draw_rect(Rect2(at.x - 18.0, top + h * (1.0 - 0.86), 36.0, h * (0.86 - 0.62)), Color(Ui.YELLOW, 0.45 * k))
			var fill: float = minf(cyc * 1.15, 1.0) * 0.74
			draw_rect(Rect2(at.x - 14.0, top + h * (1.0 - fill), 28.0, h * fill), c)
			draw_rect(Rect2(at.x - 18.0, top, 36.0, h), cr, false, 3.0)
		"mash":
			var p: float = 1.0 - absf(sin(t * 18.0))
			draw_circle(at, 26.0 + 10.0 * p, c)
			draw_arc(at, 50.0, 0.0, TAU, 32, cr, 3.0)
		"beat":
			var bt: float = fmod(t, 0.62) / 0.62
			var s: float = 1.0 + 0.35 * maxf(0.0, 1.0 - bt * 4.0)
			draw_circle(at + Vector2(-14, -8) * s, 18.0 * s, c)
			draw_circle(at + Vector2(14, -8) * s, 18.0 * s, c)
			draw_colored_polygon(PackedVector2Array([at + Vector2(-31, -2) * s, at + Vector2(31, -2) * s, at + Vector2(0, 34) * s]), c)
