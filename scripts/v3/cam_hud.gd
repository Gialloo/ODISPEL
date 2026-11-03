class_name CamHud
extends Control

# LO SGUARDO E' UNA TELECAMERA (SINTESI §5): l'interfaccia e' l'occhio di Echo, che vive nelle telecamere.
# Angoli del mirino, REC che lampeggia, numero della telecamera e ora della notte (l'atto va dalle tre all'alba).
# Dentro le Anomalie le telecamere non arrivano: niente REC, «NESSUN SEGNALE» in magenta che sfarfalla.
# Grana e righe di scansione leggerissime (spente con «effetti ridotti»), sotto ai comandi: i testi restano leggibili.
#
# Uso: var h := CamHud.new(); h.anomaly = ...; h.tag_right = ...; parent.add_child(h); h.watch("nox", Color, 2)

const MAGIC: Color = Color("#E83DCE")
const REC_RED: Color = Color("#ff4630")

var anomaly: bool = false            # dentro un'Anomalia: nessun segnale
var tag_right: bool = false          # etichetta a destra (esplorazione, sotto la pausa) o a sinistra (battaglia)
var tag_y: float = -204.0            # posizione verticale dell'etichetta (dal basso se negativa)
var _cam_no: int = 1
var live: int = -1                   # Hype di Rio (battaglia): da 25 in su la telecamera va «in diretta» e lo scrive
var _who: String = ""
var _who_col: Color = Ui.CREAM
var _t: float = 0.0
var _tag: Label
var _clock: Label
var _grain: ColorRect
# LA CITTA' CHE REAGISCE (Fase 4): la telecamera di Echo subisce la battaglia.
var fractured: bool = false          # nemico in BREAK: la lente resta incrinata in un angolo finche' non si rialza
var _dist_t: float = 0.0             # disturbo in corso (Ultimate o BREAK): secondi rimasti
var _dist_len: float = 1.0
var _dist_txt: String = ""
var _dist_col: Color = Ui.CREAM
# CAMBIO DI TELECAMERA (PIANO fase 2, lo scorrimento alla Metaphor della V2 detto con lo sguardo di Echo): quando il turno passa
# a un altro personaggio il segnale salta per un attimo, fasce di disturbo che scorrono di lato e il numero della nuova CAM.
const CUT_TIME: float = 0.22         # il segnale salta (velo e disturbo)
const STAMP_TIME: float = 0.75       # il cartellino della nuova CAM resta il tempo di leggerlo, poi esce
var _cut_t: float = 0.0
var _stamp_len: float = STAMP_TIME   # durata del cartellino (piu' lunga per la presentazione del nemico)
var _stamp_main: String = ""         # testo grande del cartellino ("" = CAM nn)
var _stamp_sub: String = ""          # riga sotto ("" = nome di chi si guarda)
var _cut_dir: float = 1.0            # verso dello scorrimento: +1 la nuova telecamera sta a destra, -1 a sinistra

const GRAIN_SHADER: String = """
shader_type canvas_item;
render_mode unshaded;
uniform float k = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float scan = step(0.5, fract(FRAGCOORD.y * 0.5)) * 0.035;
	float n = h(floor(FRAGCOORD.xy * 0.5) + floor(TIME * 18.0)) * 0.05;
	COLOR = vec4(vec3(n), (scan + n * 0.6) * k);
}
"""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(self, 0, 0, 1, 1)
	if not Settings.light_fx:
		_grain = ColorRect.new()
		_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.place(_grain, 0, 0, 1, 1)
		var mat := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = GRAIN_SHADER
		mat.shader = sh
		mat.set_shader_parameter("k", 1.6 if anomaly else 1.0)
		_grain.material = mat
		add_child(_grain)
	_tag = Ui.label("", 18, Ui.CREAM, Ui.body(), 6)
	_clock = Ui.label("", 15, Color(1, 1, 1, 0.7), Ui.body(), 5)
	for l in [_tag, _clock]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if tag_right else HORIZONTAL_ALIGNMENT_LEFT
		add_child(l)
	var top: float = tag_y
	var anchor_y: float = 1.0 if tag_y < 0.0 else 0.0
	if tag_right:
		Ui.place(_tag, 1, anchor_y, 1, anchor_y, -460, top, -24, top + 24)
		Ui.place(_clock, 1, anchor_y, 1, anchor_y, -460, top + 23, -24, top + 44)
	else:
		Ui.place(_tag, 0, anchor_y, 0, anchor_y, 44, top, 520, top + 24)
		Ui.place(_clock, 0, anchor_y, 0, anchor_y, 44, top + 23, 520, top + 44)
	_refresh()


# Chi stiamo guardando: id del personaggio (vuoto = inquadratura generale), colore, numero della telecamera.
func watch(who: String, c: Color, cam_no: int) -> void:
	_who = who
	_who_col = c
	_cam_no = cam_no
	_refresh()


func _refresh() -> void:
	queue_redraw()          # il pallino del REC segue la lunghezza della scritta
	if _tag == null:
		return
	if _dist_t > 0.0:
		_tag.text = _dist_txt
		_tag.add_theme_color_override("font_color", _dist_col)
		return
	if anomaly:
		_tag.text = "NESSUN SEGNALE"
		_tag.add_theme_color_override("font_color", MAGIC.lightened(0.25))
		return
	var name_txt: String = ""
	if _who != "":
		name_txt = "  ·  " + _who.to_upper()
	_tag.text = "REC   CAM %02d%s%s" % [_cam_no, name_txt, ("  ·  IN DIRETTA %d" % live) if live >= 25 else ""]
	_tag.add_theme_color_override("font_color", Ui.CREAM.lerp(_who_col, 0.35) if _who != "" else Ui.CREAM)


# Disturbo del segnale: l'etichetta del REC lo dice, mirino e scritta tremano, poi tutto torna come prima.
# Vale anche dentro le Anomalie (autore, 3/11/2026: contro i boss deve esserci tutto): il disturbo copre «NESSUN SEGNALE»
# e, finito, la scritta torna quella.
func disturb(txt: String, c: Color, secs: float = 1.4) -> void:
	_dist_txt = txt
	_dist_col = c
	_dist_t = secs
	_dist_len = maxf(0.1, secs)
	_refresh()


# Taglio tra due telecamere: dir = verso in cui sta la nuova (come lo scorrimento della V2: da F1 a F3 si va a destra).
# Con effetti ridotti resta solo il velo, piu' leggero; con i lampi a zero niente velo scuro.
# main/sub: testi del cartellino al posto di CAM nn e del nome; secs: quanto resta (presentazione del nemico).
# Anche dentro le Anomalie: i boss si combattono li' e prima perdevano cambio di telecamera e presentazione (3/11/2026).
func cut(dir: float = 1.0, main: String = "", sub: String = "", secs: float = STAMP_TIME) -> void:
	_cut_dir = 1.0 if dir >= 0.0 else -1.0
	_stamp_main = main
	_stamp_sub = sub
	_stamp_len = maxf(CUT_TIME + 0.3, secs)
	_cut_t = _stamp_len


# RIO IN DIRETTA: con l'Hype da 25 in su, sul bordo destro (sopra la squadra, lontano dai comandi a sinistra) scorrono i
# commenti dei suoi pochi follower (canone: 32 follower). Massimo tre righe, ognuna resta 3 s. Testi PROVVISORI, da rivedere
# con l'autore. Disegnati con draw_string: niente nodi nuovi.
const CHAT: Array = [
	["utente_07", "RAGA È VERO??"],
	["utente_19", "rio la batteria è al 2%"],
	["utente_32", "CLIP CLIP CLIP"],
	["utente_11", "che è quella cupola rosa"],
	["utente_04", "il Re del Circo è tornato"],
	["utente_32", "titolo in MAIUSCOLO o non vale"],
	["utente_13", "questa va in tendenza"],
	["utente_19", "ma è un AUTOVELOX che si muove?"],
	["utente_07", "signore e signori..."],
	["utente_22", "seguo da 3 minuti e già lo amo"],
]
const RIO_COL: Color = Color("#8e3df0")
var _chat: Array = []                # [indice in CHAT, millisecondi di nascita]
var _chat_next: float = 0.6
var _chat_i: int = 0


func _chat_tick(delta: float) -> void:
	# anche nelle Anomalie: Rio trasmette lo stesso (3/11/2026, contro i boss deve esserci tutto)
	if live < 25:
		if not _chat.is_empty():
			_chat.clear()
		return
	_chat_next -= delta
	if _chat_next <= 0.0:
		_chat_next = 2.6 if Settings.light_fx else 1.4
		_chat_i = (_chat_i + 1 + int(_t * 7.0) % 3) % CHAT.size()
		_chat.append([_chat_i, Time.get_ticks_msec()])
		if _chat.size() > 3:
			_chat.pop_front()
	var now: int = Time.get_ticks_msec()
	while not _chat.is_empty() and now - int(_chat[0][1]) > 3000:
		_chat.pop_front()


func _draw_chat(sz: Vector2) -> void:
	if _chat.is_empty():
		return
	var fb: Font = Ui.body()
	var fs: int = 22
	var now: int = Time.get_ticks_msec()
	var y: float = sz.y * 0.74
	for i in range(_chat.size() - 1, -1, -1):
		var e: Array = _chat[i]
		var age: float = float(now - int(e[1])) / 1000.0
		var a: float = clampf(age / 0.15, 0.0, 1.0) * clampf((3.0 - age) / 0.4, 0.0, 1.0)
		var who: String = str(CHAT[int(e[0])][0]) + "  "
		var txt: String = str(CHAT[int(e[0])][1])
		var ww: float = fb.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tw: float = fb.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x: float = sz.x - 28.0 - ww - tw + (1.0 - clampf(age / 0.15, 0.0, 1.0)) * 40.0
		draw_rect(Rect2(x - 12.0, y - fs - 6.0, ww + tw + 24.0, fs + 16.0), Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, 0.72 * a))
		draw_rect(Rect2(x - 12.0, y - fs - 6.0, 4.0, fs + 16.0), Color(RIO_COL.r, RIO_COL.g, RIO_COL.b, a))
		var wc: Color = RIO_COL.lightened(0.45)
		draw_string(fb, Vector2(x, y), who, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(wc.r, wc.g, wc.b, a))
		draw_string(fb, Vector2(x + ww, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, a))
		y -= fs + 22.0


# FERMO IMMAGINE del colpo finale: va a tempo reale (durante il fermo il gioco e' a tempo zero).
var _frz_until: int = 0
var _frz_from: int = 0
var _frz_title: String = ""
var _frz_who: String = ""
var _frz_col: Color = Ui.CREAM


func freeze(title: String, who: String, c: Color, secs: float) -> void:
	_frz_from = Time.get_ticks_msec()
	_frz_until = _frz_from + int(secs * 1000.0)
	_frz_title = title
	_frz_who = who
	_frz_col = c
	_cut_t = 0.0          # il fermo prende tutto lo schermo: niente cartellino della CAM sotto
	queue_redraw()


func cutting() -> bool:
	return _cut_t > 0.0


func set_fractured(on: bool) -> void:
	if on != fractured:
		fractured = on
		queue_redraw()


# Hype di Rio: la diretta si vede nella telecamera di Echo
func set_live(hype: int) -> void:
	if hype != live:
		live = hype
		_refresh()


# Ora della notte: il prologo comincia alle tre, ogni capitolo porta la citta' piu' vicina all'alba.
func _time_text() -> String:
	if anomaly:
		return "--:--:--"
	var ch: int = int(Story.chapter) if Story.chapter >= 0 else 0
	var secs: int = 3 * 3600 + 12 * 60 + ch * 23 * 60 + int(_t)
	return "%02d:%02d:%02d" % [(secs / 3600) % 24, (secs / 60) % 60, secs % 60]


func _process(delta: float) -> void:
	_t += delta
	if _clock != null:
		_clock.text = _time_text()
	if anomaly and _tag != null:
		_tag.modulate.a = 0.55 + 0.45 * float(sin(_t * 23.0) > -0.6)
	_chat_tick(delta)
	if _cut_t > 0.0:
		# tetto al passo: il primo fotogramma dopo il taglio puo' essere lento (scena nuova da disegnare) e si mangerebbe tutto
		_cut_t = maxf(0.0, _cut_t - minf(delta, 0.034))
	if _dist_t > 0.0:
		_dist_t -= delta
		if _tag != null:
			_tag.modulate.a = 0.45 + 0.55 * float(sin(_t * 41.0) > -0.3)
		if _dist_t <= 0.0:
			if _tag != null:
				_tag.modulate.a = 1.0
			_refresh()
	# PRESTAZIONI: si ridisegna solo quando qualcosa si muove (taglio, disturbo, chat, fermo, anomalia) o quando il pallino del REC
	# cambia stato; prima si ridisegnava tutto lo schermo a ogni fotogramma anche da fermo.
	var blink: bool = fmod(_t, 1.2) < 0.75
	# nelle Anomalie il mirino trema: prima si ridisegnava tutto lo schermo a ogni fotogramma, ora 15 volte al secondo
	# (il tremolio si legge uguale e sul telefono si risparmia il disegno a schermo intero contro i boss)
	var anom_tick: int = int(_t * 15.0) if anomaly else 0
	if anom_tick != _anom_was or _cut_t > 0.0 or _dist_t > 0.0 or _drawn_busy or not _chat.is_empty() or Time.get_ticks_msec() < _frz_until or blink != _blink_was:
		queue_redraw()
	_anom_was = anom_tick
	_drawn_busy = _cut_t > 0.0 or _dist_t > 0.0 or not _chat.is_empty() or Time.get_ticks_msec() < _frz_until
	_blink_was = blink


var _blink_was: bool = false
var _anom_was: int = 0
var _drawn_busy: bool = false      # l'ultimo disegno aveva qualcosa in movimento: un altro giro per pulirlo


var _fonts_warm: bool = false


func _draw() -> void:
	var sz: Vector2 = size
	if not _fonts_warm:
		# PRESTAZIONI: le lettere grandi del cartellino (66 e 26) si preparano qui, invisibili, al primo disegno; prima si
		# preparavano sulla presentazione del nemico, ed era uno degli scatti dell'ingresso (3/11/2026)
		_fonts_warm = true
		var abc: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÈÉÌÒÙ0123456789·' "
		draw_string(Ui.display(), Vector2(-4000, -4000), abc, HORIZONTAL_ALIGNMENT_LEFT, -1, 66, Color(1, 1, 1, 0))
		draw_string(Ui.body(), Vector2(-4000, -4000), abc, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0))
	var c: Color = Color(MAGIC.r, MAGIC.g, MAGIC.b, 0.5) if anomaly else Color(1, 0.96, 0.86, 0.4)
	var m: float = 12.0
	var l: float = 36.0
	var w: float = 3.0
	var j := Vector2.ZERO
	if anomaly:
		var tq: float = floorf(_t * 15.0) / 15.0          # stesso passo del ridisegno: il tremolio non dipende dai fotogrammi
		j = Vector2(sin(tq * 31.0), cos(tq * 27.0)) * 1.5
	if _dist_t > 0.0:
		var k: float = _dist_t / _dist_len
		j = Vector2(sin(_t * 47.0), cos(_t * 39.0)) * 5.0 * k
		c = c.lerp(Color(_dist_col.r, _dist_col.g, _dist_col.b, 0.75), k)
	for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var p := Vector2(m if corner.x == 0 else sz.x - m, m if corner.y == 0 else sz.y - m) + j
		var dx: float = l if corner.x == 0 else -l
		var dy: float = l if corner.y == 0 else -l
		draw_line(p, p + Vector2(dx, 0), c, w)
		draw_line(p, p + Vector2(0, dy), c, w)
	# pallino del REC accanto all'etichetta: lampeggia come una telecamera vera
	if not anomaly and _tag != null and fmod(_t, 1.2) < 0.75:
		var tp: Vector2 = _tag.position
		var x: float = tp.x + _tag.size.x - _tag.get_combined_minimum_size().x - 14.0 if tag_right else tp.x - 14.0
		draw_circle(Vector2(x, tp.y + _tag.size.y * 0.5), 7.0, REC_RED)
		draw_arc(Vector2(x, tp.y + _tag.size.y * 0.5), 7.5, 0, TAU, 16, Ui.INK, 2.0)
	if fractured:
		_draw_crack(sz)
	if _cut_t > 0.0:
		_draw_cut(sz)
	_draw_chat(sz)
	if Time.get_ticks_msec() < _frz_until:
		_draw_freeze(sz)


# Fermo immagine: velo freddo, cornice del fotogramma, ■ STOP rosso e la lastra col nome della mossa che entra di scatto.
func _draw_freeze(sz: Vector2) -> void:
	var el: float = float(Time.get_ticks_msec() - _frz_from) / 1000.0
	var tot: float = float(_frz_until - _frz_from) / 1000.0
	var a: float = clampf((tot - el) / 0.18, 0.0, 1.0)          # svanisce negli ultimi 0,18 s
	var pop: float = clampf(el / 0.08, 0.0, 1.0)                 # la lastra entra in 0,08 s
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.03, 0.12, 0.35 * a))
	# lampo bianco brevissimo all'attimo del fermo (solo coi lampi accesi)
	if el < 0.07:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, 0.45 * clampf(Settings.flash, 0.0, 1.0) * (1.0 - el / 0.07)))
	var m: float = 26.0
	draw_rect(Rect2(m, m, sz.x - m * 2.0, sz.y - m * 2.0), Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, 0.55 * a), false, 3.0)
	var f: Font = Ui.display()
	var fb: Font = Ui.body()
	draw_rect(Rect2(m + 22.0, m + 70.0, 26.0, 26.0), Color(REC_RED.r, REC_RED.g, REC_RED.b, a))
	draw_string(f, Vector2(m + 60.0, m + 96.0), "STOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(REC_RED.r, REC_RED.g, REC_RED.b, a))
	# lastra al centro: nome della mossa grande, sotto chi l'ha fatta nel suo colore
	var fs: int = 76
	var w1: float = f.get_string_size(_frz_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var sub: String = "COLPO FINALE" + (("  ·  " + _frz_who) if _frz_who != "" else "")
	var w2: float = fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var bw: float = maxf(w1, w2) + 90.0
	var bh: float = 150.0
	var sc: float = lerpf(1.35, 1.0, pop)
	draw_set_transform(Vector2(sz.x * 0.5, sz.y * 0.6), deg_to_rad(-5.0), Vector2(sc, sc))      # sotto il cartellino del nemico
	var r := Rect2(-bw * 0.5, -bh * 0.5, bw, bh)
	draw_rect(Rect2(r.position + Vector2(14, 14), r.size), Color(_frz_col.r, _frz_col.g, _frz_col.b, 0.9 * a))
	draw_rect(r, Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, 0.95 * a))
	draw_rect(r, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, 0.9 * a), false, 4.0)
	draw_string(f, Vector2(r.position.x + 45.0, r.position.y + 86.0), _frz_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, a))
	var lc: Color = _frz_col.lightened(0.4)
	draw_string(fb, Vector2(r.position.x + 47.0, r.position.y + 126.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(lc.r, lc.g, lc.b, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Il segnale salta (primi 0,22 s): velo scuro che si apre, la linea bianca che spazza verso la nuova telecamera, fasce di
# disturbo coi colori separati (rosso e ciano, come l'aberrazione dei glitch) e l'immagine che sobbalza.
# Poi resta il CARTELLINO della CAM (alla Persona 5: lastra nera inclinata, bordo nel colore del personaggio, numero grande e
# nome), che entra dal lato del nuovo personaggio, si ferma e scivola via. Poche forme piatte per pochi fotogrammi, niente shader.
func _draw_cut(sz: Vector2) -> void:
	var el: float = _stamp_len - _cut_t            # tempo dal taglio
	var lite: bool = Settings.light_fx
	if el < CUT_TIME:
		var k: float = 1.0 - el / CUT_TIME          # 1 = appena tagliato, 0 = finito
		var veil: float = (0.1 if lite else 0.18) * clampf(Settings.flash, 0.0, 1.0) * k
		if veil > 0.01:
			draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.02, 0.07, veil))
		# linea che spazza lo schermo nel verso del cambio, con la scia del colore del personaggio
		var sx: float = lerpf(-0.05, 1.05, el / CUT_TIME)
		if _cut_dir < 0.0:
			sx = 1.0 - sx
		# 3/11/2026 (autore: «troppo bianco, alla lunga disturba»): con la carrellata sotto il taglio non deve piu' coprire
		# un salto, quindi velo, linea e fasce sono a meno di meta' di prima
		draw_rect(Rect2(sz.x * sx - 1.5, 0, 3.0, sz.y), Color(1, 1, 1, 0.3 * k))
		draw_rect(Rect2(sz.x * sx - (90.0 if _cut_dir > 0.0 else -6.0) * 1.0, 0, 84.0, sz.y), Color(_who_col.r, _who_col.g, _who_col.b, 0.12 * k))
		# fasce di disturbo: ognuna e' una coppia rossa/ciano sfasata, che scorre verso la nuova telecamera
		var n: int = 3 if lite else 6
		var slide: float = (1.0 - k) * sz.x * 0.4 * _cut_dir
		var frame: float = floor(_t * 30.0)
		for i in n:
			var h: float = fract_hash(float(i) * 7.13 + frame)
			var y: float = sz.y * fract_hash(float(i) * 3.7 + 0.5 + floor(frame / 3.0) * 0.11)
			var bh: float = 3.0 + 20.0 * h * h
			var x0: float = -sz.x * 0.25 + slide + sz.x * 0.45 * fract_hash(float(i) * 5.1 + frame * 0.3)
			var bw: float = sz.x * (0.25 + 0.55 * h)
			var off: float = 10.0 + 14.0 * h
			draw_rect(Rect2(x0 - off, y, bw, bh), Color(1.0, 0.16, 0.25, 0.16 * k))
			draw_rect(Rect2(x0 + off, y, bw, bh), Color(0.25, 0.9, 1.0, 0.16 * k))
			draw_rect(Rect2(x0, y + bh * 0.3, bw, maxf(1.0, bh * 0.4)), Color(1, 1, 1, 0.14 * k) if i % 3 == 0 else Color(_who_col.r, _who_col.g, _who_col.b, 0.25 * k))
	if el < GLITCH_TIME:
		_draw_glitch(sz, el)
	_draw_cam_stamp(sz, el)


# BLOCCHI DIGITALI del cambio di telecamera (autore, 3/11/2026: «usa l'ottavo fotogramma del break»): per ~0,14 s il segnale
# salta come nel BREAK: fondo bianco, blocchi neri a strisce, barre di colore. Solo draw_rect (~30): costa quasi niente.
# Con i lampi spenti nelle impostazioni il bianco non c'e' (restano i blocchi, piu' trasparenti).
# 3/11/2026: piu' breve (0,1 s), SENZA fondo bianco e coi blocchi a meta' opacita': lo stesso disturbo 8-bit del BREAK,
# ma solo accennato, perche' a ogni turno alla lunga stancava. Il BREAK vero resta pieno.
const GLITCH_TIME: float = 0.1
const GLITCH_BARS: Array = [Color("#ff7326"), Color("#33bf59"), Color("#3359f2"), Color("#ff6699"), Color("#ffe633"), Color("#141414")]


func _draw_glitch(sz: Vector2, el: float) -> void:
	var fl: float = clampf(Settings.flash, 0.0, 1.0)
	var k: float = 1.0 - el / GLITCH_TIME
	var a: float = (0.3 + 0.2 * fl) * clampf(k * 2.0, 0.0, 1.0)
	var frame: float = floor(el * 40.0)
	var n: int = 6 if Settings.light_fx else 12
	for i in n:
		var fi: float = float(i)
		var h: float = fract_hash(fi * 7.31 + frame * 1.7)
		var bw: float = sz.x * (0.04 + 0.16 * fract_hash(fi * 2.9 + frame))
		var bh: float = sz.y * (0.03 + 0.14 * h)
		var x: float = sz.x * fract_hash(fi * 5.7 + frame * 0.37) - bw * 0.3
		var y: float = sz.y * fract_hash(fi * 3.3 + 0.5 + frame * 0.21)
		if i % 4 == 0:
			# barra di colore: sei pezzi uguali uno accanto all'altro
			var pw: float = bw * 1.6 / 6.0
			for j in 6:
				var c: Color = GLITCH_BARS[(j + i) % 6]
				draw_rect(Rect2(x + pw * j, y, pw, maxf(6.0, bh * 0.25)), Color(c.r, c.g, c.b, a))
		else:
			draw_rect(Rect2(x, y, bw, bh), Color(0.04, 0.04, 0.05, a))
			if h > 0.45:
				# strisce verticali grigie dentro al blocco nero
				var st: float = 10.0
				var xx: float = x + 3.0
				while xx < x + bw - st:
					draw_rect(Rect2(xx, y + 3.0, st * 0.5, bh - 6.0), Color(0.55, 0.55, 0.58, a))
					xx += st


# Cartellino della CAM: entra veloce dal lato del nuovo personaggio (0,12 s), sta fermo, esce dal lato opposto negli ultimi 0,15 s.
func _draw_cam_stamp(sz: Vector2, el: float) -> void:
	var t_in: float = 0.12
	var t_out: float = 0.15
	var a: float = 1.0
	var dx: float = 0.0
	if el < t_in:
		var q: float = 1.0 - el / t_in
		dx = q * q * 180.0 * _cut_dir           # arriva dal lato della nuova telecamera
		a = 1.0 - q * 0.6
	elif el > _stamp_len - t_out:
		var q2: float = (el - (_stamp_len - t_out)) / t_out
		dx = -q2 * q2 * 140.0 * _cut_dir        # esce dalla parte opposta, come se la camera continuasse a scorrere
		a = 1.0 - q2
	if a <= 0.01:
		return
	var f: Font = Ui.display()
	var fb: Font = Ui.body()
	var num: String = _stamp_main if _stamp_main != "" else "CAM %02d" % _cam_no
	var who: String = _stamp_sub if _stamp_sub != "" else (_who.to_upper() if _who != "" else "VISTA GENERALE")
	var fs: int = 66
	var fs2: int = 26
	var w1: float = f.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w2: float = fb.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
	var bw: float = maxf(w1, w2) + 70.0
	var bh: float = 116.0
	var c := Vector2(sz.x * 0.64 + dx, sz.y * 0.72)      # a destra di chi e' di turno (che sta a sinistra del centro), sotto il nemico
	draw_set_transform(c, deg_to_rad(-6.0), Vector2.ONE)
	var r := Rect2(-bw * 0.5, -bh * 0.5, bw, bh)
	draw_rect(Rect2(r.position + Vector2(10, 10), r.size), Color(_who_col.r, _who_col.g, _who_col.b, 0.85 * a))   # ombra piena nel colore
	draw_rect(r, Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, 0.94 * a))
	draw_rect(r, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, 0.9 * a), false, 3.0)
	# pallino del REC e numero grande, nome sotto nel colore del personaggio
	draw_circle(Vector2(r.position.x + 24.0, r.position.y + 34.0), 8.0, Color(REC_RED.r, REC_RED.g, REC_RED.b, a))
	draw_string(f, Vector2(r.position.x + 42.0, r.position.y + 66.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, a))
	draw_string(fb, Vector2(r.position.x + 44.0, r.position.y + 100.0), who, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(_who_col.lightened(0.4).r, _who_col.lightened(0.4).g, _who_col.lightened(0.4).b, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func fract_hash(x: float) -> float:
	var v: float = sin(x * 91.345) * 47453.5453
	return v - floor(v)


# Lente incrinata (nemico in BREAK): poche linee spezzate dal bordo sinistro, nel buio tra REC e comandi, lontano dai testi.
# Disegno fisso (niente casuale a ogni frame): costa una decina di linee.
const _CRACK: Array = [
	[Vector2(0.0, 0.0), Vector2(-60, -22), Vector2(-118, -30), Vector2(-190, -70)],
	[Vector2(0.0, 0.0), Vector2(-24, -64), Vector2(-30, -120), Vector2(-72, -176)],
	[Vector2(-60, -22), Vector2(-84, -78), Vector2(-30, -120)],
	[Vector2(-118, -30), Vector2(-150, -10)],
	[Vector2(0.0, 0.0), Vector2(-96, -110), Vector2(-150, -150)],
]


func _draw_crack(sz: Vector2) -> void:
	var o := Vector2(10.0, sz.y * 0.36)
	for i in _CRACK.size():
		var pts := PackedVector2Array()
		var fy: float = 1.0 if i % 2 == 0 else -0.8      # meta' delle crepe sale, meta' scende
		for q in _CRACK[i]:
			pts.append(o + Vector2(-(q as Vector2).x * 1.2, (q as Vector2).y * fy * 0.9))
		draw_polyline(pts, Color(0, 0, 0, 0.5), 4.5)
		draw_polyline(pts, Color(1, 1, 1, 0.75), 2.2)
