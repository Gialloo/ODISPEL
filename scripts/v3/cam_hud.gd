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
var show_tag: bool = true             # false: niente REC, CAM e pallino rosso (battaglia, autore 7/11/2026: li' vanno x1, AUTO e pausa)
var tag_y: float = -204.0            # posizione verticale dell'etichetta (dal basso se negativa)
var _cam_no: int = 1
var live: int = -1                   # Hype di Rio (battaglia): da 25 in su la telecamera va «in diretta» e lo scrive
# HUD a tre livelli (HudLayers): mentre il giocatore sceglie la telecamera e' livello 3 e si fa da parte. La chat della diretta
# tace e il cartellino «CAM nn» non copre la squadra; restano cornice, REC e la linea del taglio (game director, 4/11/2026)
var quiet: bool = false
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
	# VIRAGGI delle inquadrature firmate (autore, 8/11/2026): due rettangoli a tutto schermo, uno che MOLTIPLICA (toglie i colori
	# che non c'entrano) e uno che SOMMA (alza i neri nel colore del visore). Nessuna lettura dello schermo: costano due rettangoli.
	for mode in [CanvasItemMaterial.BLEND_MODE_MUL, CanvasItemMaterial.BLEND_MODE_ADD]:
		var tr := ColorRect.new()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.place(tr, 0, 0, 1, 1)
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = mode
		tr.material = cm
		tr.visible = false
		add_child(tr)
		_tints.append(tr)
	if not Settings.light_fx:
		_grain = ColorRect.new()
		_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.place(_grain, 0, 0, 1, 1)
		var mat := ShaderMaterial.new()
		mat.shader = Toon.shared_shader(GRAIN_SHADER)          # condiviso: si compila una volta per partita
		mat.set_shader_parameter("k", 1.6 if anomaly else 1.0)
		_grain.material = mat
		add_child(_grain)
	_tag = Ui.label("", 18, Ui.CREAM, Ui.body(), 6)
	_clock = Ui.label("", 15, Color(1, 1, 1, 0.7), Ui.body(), 5)
	for l in [_tag, _clock]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if tag_right else HORIZONTAL_ALIGNMENT_LEFT
		add_child(l)
		if not show_tag:
			l.modulate.a = 0.0
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
# FEEDBACK DEI TESTER (6/11/2026): «la chat di Rio e' geniale, deve restare un secondo in piu' per leggerla e va fatta meglio».
# Prima un messaggio viveva 3 secondi e spariva di colpo appena si tornava a scegliere: non si leggeva mai per intero.
# Ora: ogni messaggio resta CHAT_LIFE secondi; mentre si sceglie non ne arrivano di nuovi (livello 3, HudLayers) ma quelli
# gia' a schermo finiscono di farsi leggere; il primo arriva subito all'inizio della mossa. Grafica da vera diretta:
# scheda «LIVE @RIO» con gli spettatori, avatar tondo con l'iniziale, nome colorato, testo a capo, cuori che salgono.
const CHAT_LIFE: float = 5.5         # secondi di lettura di un messaggio (prima 3)
const CHAT_GAP: float = 1.6          # un messaggio nuovo ogni tanto: tre insieme al massimo, si leggono tutti
const CHAT_W: float = 360.0          # larghezza della scheda della chat, a destra sopra la squadra
# la chat vive in una fascia a destra tra il contatore COMBO (in alto, a 0.42 dell'altezza) e la squadra (in basso): non
# copre mai i timbri al centro (DEBOLEZZA, SLANCIO), il COMBO ne' i ritratti. I messaggi che non ci stanno aspettano fuori.
const CHAT_TOP: float = 0.445
const CHAT_BOTTOM: float = 0.775
const CHAT_COLS: Array = [Color("#ff6fa8"), Color("#5fd4ff"), Color("#ffd23f"), Color("#7dff9a"), Color("#ff8f4a"), Color("#c99bff")]
var _was_quiet: bool = true


func _chat_col(who: String) -> Color:
	return CHAT_COLS[absi(who.hash()) % CHAT_COLS.size()]


func _chat_tick(delta: float) -> void:
	# anche nelle Anomalie: Rio trasmette lo stesso (3/11/2026, contro i boss deve esserci tutto)
	var now: int = Time.get_ticks_msec()
	while not _chat.is_empty() and now - int(_chat[0][1]) > int(CHAT_LIFE * 1000.0):
		_chat.pop_front()
	if live < 25:
		if not _chat.is_empty():
			_chat.clear()
		_was_quiet = true
		return
	if quiet:
		_was_quiet = true
		return          # si sceglie: niente messaggi nuovi, quelli gia' a schermo restano da leggere
	if _was_quiet:
		_was_quiet = false
		_chat_next = minf(_chat_next, 0.2)      # la mossa comincia: la chat risponde subito
	_chat_next -= delta
	if _chat_next <= 0.0:
		_chat_next = 2.6 if Settings.light_fx else CHAT_GAP
		_chat_i = (_chat_i + 1 + int(_t * 7.0) % 3) % CHAT.size()
		_chat.append([_chat_i, now])
		if _chat.size() > 3:
			_chat.pop_front()


func _chat_box(r: Rect2, bg: Color, edge: Color, rad: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(rad)
	sb.border_color = edge
	sb.set_border_width_all(0)
	sb.border_width_left = 4
	sb.anti_aliasing = true
	draw_style_box(sb, r)


func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, 0), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.5, 0), r * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, r * 0.18), c + Vector2(r * 1.02, r * 0.18), c + Vector2(0, r * 1.25)]), col)


func _draw_chat(sz: Vector2) -> void:
	if _chat.is_empty():
		return
	var fb: Font = Ui.body()
	var fd: Font = Ui.display()
	var fs: int = 21                     # testo del messaggio
	var fn: int = 17                     # nome dell'utente
	var now: int = Time.get_ticks_msec()
	var x0: float = sz.x - 24.0 - CHAT_W
	var y: float = sz.y * CHAT_BOTTOM    # fondo della pila: il messaggio piu' nuovo sta in basso, come nelle dirette vere
	# autore (8/11/2026): la barra RITMO / ARDORE copriva gli ultimi messaggi: la pila finisce sopra le sue scritte
	if bool(HudLayers.v("chat.sopra_ardore")) and Settings.hud_ritratto and Settings.hud_ritmo and not Settings.hud_foto:
		y = minf(y, sz.y - PortraitParty.top() - 42.0 - 30.0 - 14.0)
	var top_a: float = 0.0
	for i in range(_chat.size() - 1, -1, -1):
		var e: Array = _chat[i]
		var age: float = float(now - int(e[1])) / 1000.0
		var inn: float = clampf(age / 0.2, 0.0, 1.0)
		var a: float = inn * clampf((CHAT_LIFE - age) / 0.5, 0.0, 1.0)
		top_a = maxf(top_a, a)
		var who: String = str(CHAT[int(e[0])][0])
		var txt: String = str(CHAT[int(e[0])][1])
		var uc: Color = _chat_col(who)
		var lines: Array = CmdWheel.wrap(fb, txt, fs, CHAT_W - 78.0).slice(0, 2)
		var h: float = 30.0 + float(lines.size()) * (fs + 5.0) + 6.0
		if y - h - 44.0 < sz.y * CHAT_TOP:
			break          # non ci sta sotto il COMBO: il messaggio piu' vecchio lascia il posto ai nuovi
		var x: float = x0 + (1.0 - inn) * 60.0      # entra scivolando da destra
		var r := Rect2(x, y - h, CHAT_W, h)
		_chat_box(r, Color(0.04, 0.02, 0.07, 0.86 * a), Color(uc.r, uc.g, uc.b, a), 10)
		# avatar: cerchio del colore dell'utente con l'iniziale del nickname
		var av := Vector2(x + 30.0, y - h + 26.0)
		draw_circle(av, 16.0, Color(uc.r, uc.g, uc.b, a))
		draw_arc(av, 16.5, 0, TAU, 24, Color(1, 1, 1, 0.5 * a), 1.5, true)
		var ini: String = who.substr(who.length() - 2) if who.begins_with("utente_") else who.substr(0, 1).to_upper()
		var iw: float = fd.get_string_size(ini, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(fd, av + Vector2(-iw * 0.5, 6.0), ini, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, a))
		draw_string(fd, Vector2(x + 58.0, y - h + 24.0), "@" + who, HORIZONTAL_ALIGNMENT_LEFT, CHAT_W - 70.0, fn, Color(uc.lightened(0.25).r, uc.lightened(0.25).g, uc.lightened(0.25).b, a))
		var ly: float = y - h + 30.0 + fs
		for ln in lines:
			draw_string(fb, Vector2(x + 58.0, ly), str(ln), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, a))
			ly += fs + 5.0
		y -= h + 8.0
	# testata della diretta: pillola rossa LIVE, il canale di Rio e gli spettatori (salgono con l'Hype)
	var hy: float = y - 36.0
	var ha: float = top_a
	_chat_box(Rect2(x0, hy, CHAT_W, 32.0), Color(0.04, 0.02, 0.07, 0.86 * ha), Color(RIO_COL.r, RIO_COL.g, RIO_COL.b, ha), 8)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(REC_RED.r, REC_RED.g, REC_RED.b, ha)
	pill.set_corner_radius_all(6)
	draw_style_box(pill, Rect2(x0 + 10.0, hy + 5.0, 64.0, 22.0))
	var blink: float = 1.0 if fmod(_t, 1.0) < 0.6 else 0.35
	draw_circle(Vector2(x0 + 21.0, hy + 16.0), 4.0, Color(1, 1, 1, ha * blink))
	draw_string(fd, Vector2(x0 + 29.0, hy + 23.0), "LIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, ha))
	draw_string(fd, Vector2(x0 + 86.0, hy + 23.0), "@RIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(RIO_COL.lightened(0.5).r, RIO_COL.lightened(0.5).g, RIO_COL.lightened(0.5).b, ha))
	var views: int = 1200 + live * 140 + int(_t * 3.0) % 90
	var vt: String = "%d,%dK spettatori" % [views / 1000, (views % 1000) / 100]
	var vw: float = fb.get_string_size(vt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(fb, Vector2(x0 + CHAT_W - 12.0 - vw, hy + 22.0), vt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, 0.85 * ha))
	# cuori che salgono sul bordo della scheda, come i «mi piace» di una diretta (forme piatte, costano niente)
	if not Settings.light_fx:
		for k in 3:
			var ph: float = fmod(_t * 0.7 + k * 0.33, 1.0)
			var hp := Vector2(x0 - 16.0 + sin(_t * 3.0 + k * 2.0) * 6.0, sz.y * CHAT_BOTTOM - ph * 150.0)
			_heart(hp, 7.0, Color(1.0, 0.35, 0.55, ha * (1.0 - ph) * 0.9))


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


# INQUADRATURE FIRMATE (idea 4, 4/11/2026 · regola U20: gli oggetti raccontano i personaggi). Durante l'abilita' la
# telecamera di Echo prende il «mezzo» di chi agisce: Rio in verticale come una sua diretta, Lance nel mirino
# dell'autovelox, Nox in controluce, Saul dall'alto come un drone. Poche forme piatte per un secondo, niente shader.
var _look: String = ""
var _tints: Array = []               # [moltiplica, somma]
var look_pt: Vector2 = Vector2(-1, -1)   # dove sta il bersaglio sullo schermo (riquadro del riconoscimento di Lance)
const TINT: Dictionary = {
	"notturna": [Color(0.32, 1.0, 0.38), Color(0.02, 0.16, 0.04)],       # visore notturno: tutto verde, i neri non sono mai neri
	"sorveglianza": [Color(0.58, 0.72, 0.86), Color(0.05, 0.07, 0.1)],   # monitor del furgone: freddo e slavato
}
var _look_from: float = 0.0          # in tempo di gioco (_t), non in millisecondi veri: si registra uguale col movie maker
var _look_until: float = 0.0
var _look_col: Color = Ui.CREAM


func look(kind: String, c: Color, secs: float = 1.3) -> void:
	_look = kind
	_look_col = c
	_look_from = _t
	_look_until = _t + secs
	queue_redraw()


func _draw_look(sz: Vector2) -> void:
	var el: float = _t - _look_from
	var tot: float = _look_until - _look_from
	var a: float = clampf(el / 0.12, 0.0, 1.0) * clampf((tot - el) / 0.2, 0.0, 1.0)
	var f: Font = Ui.display()
	var fb: Font = Ui.body()
	var cr: Color = Color(Ui.CREAM.r, Ui.CREAM.g, Ui.CREAM.b, a)
	match _look:
		"diretta":
			# il formato verticale delle dirette di Rio: bande nere ai lati, LIVE, spettatori che salgono, il suo nome
			var w: float = minf(sz.x, sz.y * 9.0 / 16.0)
			var x0: float = (sz.x - w) * 0.5
			var slide: float = (1.0 - clampf(el / 0.12, 0.0, 1.0)) * x0
			draw_rect(Rect2(0, 0, x0 - slide, sz.y), Color(0.02, 0.01, 0.05, 0.92 * a))
			draw_rect(Rect2(sz.x - x0 + slide, 0, x0, sz.y), Color(0.02, 0.01, 0.05, 0.92 * a))
			draw_rect(Rect2(x0, 0, w, sz.y), Color(_look_col.r, _look_col.g, _look_col.b, 0.9 * a), false, 3.0)
			draw_rect(Rect2(x0 + 22, 26, 92, 38), Color(REC_RED.r, REC_RED.g, REC_RED.b, a))
			draw_string(f, Vector2(x0 + 36, 56), "LIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, cr)
			var views: int = 8400 + int(el * 9100.0)
			draw_string(fb, Vector2(x0 + 128, 54), "%d.%dK SPETTATORI" % [views / 1000, (views % 1000) / 100], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, cr)
			draw_string(f, Vector2(x0 + 24, sz.y - 40), "@RIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(_look_col.lightened(0.5).r, _look_col.lightened(0.5).g, _look_col.lightened(0.5).b, a))
			for i in 4:
				var hy: float = sz.y - 110.0 - fmod(el * 260.0 + i * 70.0, 300.0)
				draw_circle(Vector2(x0 + w - 44.0 + sin(el * 6.0 + i) * 10.0, hy), 9.0, Color(1.0, 0.35, 0.55, a * clampf((hy - sz.y * 0.45) / 120.0, 0.0, 1.0)))
		"autovelox":
			# il mirino dell'autovelox di Lance: riquadro rosso al centro, fuori piu' scuro, la velocita' e l'infrazione
			var r := Rect2(sz.x * 0.3, sz.y * 0.17, sz.x * 0.4, sz.y * 0.58)
			var dk := Color(0.0, 0.0, 0.0, 0.42 * a)
			draw_rect(Rect2(0, 0, sz.x, r.position.y), dk)
			draw_rect(Rect2(0, r.end.y, sz.x, sz.y - r.end.y), dk)
			draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), dk)
			draw_rect(Rect2(r.end.x, r.position.y, sz.x - r.end.x, r.size.y), dk)
			var rc := Color(REC_RED.r, REC_RED.g, REC_RED.b, a)
			var L: float = 44.0
			for cn in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
				var dx: float = L if cn.x == r.position.x else -L
				var dy: float = L if cn.y == r.position.y else -L
				draw_line(cn, cn + Vector2(dx, 0), rc, 5.0)
				draw_line(cn, cn + Vector2(0, dy), rc, 5.0)
			var cc: Vector2 = r.get_center()
			draw_line(cc - Vector2(24, 0), cc + Vector2(24, 0), rc, 2.0)
			draw_line(cc - Vector2(0, 24), cc + Vector2(0, 24), rc, 2.0)
			draw_string(fb, Vector2(r.position.x + 16, r.position.y + 34), "AUTOVELOX · RILEVAMENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, cr)
			var kmh: int = mini(50 + int(el * 160.0), 137)
			draw_string(f, Vector2(r.position.x, r.end.y + 50), "%03d km/h" % kmh, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, rc)
			if kmh > 50 and fmod(el, 0.3) < 0.2:
				draw_string(f, Vector2(r.position.x + 250, r.end.y + 50), "INFRAZIONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(Ui.YELLOW.r, Ui.YELLOW.g, Ui.YELLOW.b, a))
		"controluce":
			# Nox in controluce: un sole basso alle spalle (aloni chiari nel suo colore), bordi scuri, una riga di riflesso
			var lc: Color = _look_col.lightened(0.6)
			var ctr := Vector2(sz.x * 0.5, sz.y * 0.36)
			for i in 6:
				var rr: float = 60.0 + i * 70.0
				draw_circle(ctr, rr, Color(lc.r, lc.g, lc.b, 0.07 * a))
			draw_circle(ctr, 34.0, Color(1, 1, 1, 0.5 * a))
			draw_rect(Rect2(0, ctr.y - 2, sz.x, 4), Color(lc.r, lc.g, lc.b, 0.35 * a))
			for i in 5:
				var e: float = 30.0 + i * 26.0
				draw_rect(Rect2(0, 0, sz.x, sz.y), Color(0, 0, 0, 0.07 * a), false, e)
		"notturna":
			# SAUL, ladro (autore, 8/11/2026): il visore notturno. Lente tonda coi bordi neri, righe del fosforo, granelli che
			# frizzano, crocetta e i dati del visore. Il verde viene dai viraggi (_tints).
			var gr := Color(0.55, 1.0, 0.55, a)
			var ctr := Vector2(sz.x * 0.5, sz.y * 0.5)
			var rad: float = sz.y * 0.56
			var thick: float = sz.length()
			draw_arc(ctr, rad + thick * 0.5, 0, TAU, 72, Color(0, 0.02, 0, 0.94 * a), thick)
			for i in 3:
				draw_arc(ctr, rad - 6.0 - i * 10.0, 0, TAU, 72, Color(0, 0, 0, 0.18 * a), 12.0)
			var yy: float = 0.0
			while yy < sz.y:
				draw_line(Vector2(0, yy), Vector2(sz.x, yy), Color(0, 0.1, 0, 0.16 * a), 1.0)
				yy += 4.0
			var fr: float = floor(_t * 24.0)
			for i in 40:
				var px := Vector2(fract_hash(i * 1.7 + fr) * sz.x, fract_hash(i * 2.9 + fr * 0.7) * sz.y)
				draw_rect(Rect2(px, Vector2(2, 2)), Color(0.7, 1.0, 0.7, 0.45 * a))
			draw_line(ctr - Vector2(46, 0), ctr - Vector2(14, 0), gr, 2.0)
			draw_line(ctr + Vector2(14, 0), ctr + Vector2(46, 0), gr, 2.0)
			draw_line(ctr - Vector2(0, 46), ctr - Vector2(0, 14), gr, 2.0)
			draw_line(ctr + Vector2(0, 14), ctr + Vector2(0, 46), gr, 2.0)
			var tl := ctr + Vector2(-rad * 0.62, -rad * 0.62)
			draw_string(f, tl, "NV · IR ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, gr)
			draw_string(fb, tl + Vector2(0, 26), "GEN 3 · x%.1f" % (2.0 + minf(el, 1.0) * 2.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, gr)
			draw_string(fb, tl + Vector2(0, 52), "SAUL · %s" % ("BERSAGLIO AGGANCIATO" if fmod(el, 0.5) < 0.35 else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, gr)
		"sorveglianza":
			# LANCE (autore, 8/11/2026): i monitor degli agenti nel furgone. Muro di quattro schermi, ora e REC, riconoscimento
			# del bersaglio col riquadro che lo segue, e la traccia audio dell'intercettazione.
			var wc := Color(0.85, 0.95, 1.0, a)
			var dim := Color(0.85, 0.95, 1.0, 0.35 * a)
			var gx: float = sz.x * 0.5
			var gy: float = sz.y * 0.5
			draw_line(Vector2(gx, 0), Vector2(gx, sz.y), Color(0, 0, 0, 0.8 * a), 6.0)
			draw_line(Vector2(0, gy), Vector2(sz.x, gy), Color(0, 0, 0, 0.8 * a), 6.0)
			var yy2: float = fmod(el * 120.0, 3.0)
			while yy2 < sz.y:
				draw_line(Vector2(0, yy2), Vector2(sz.x, yy2), Color(0, 0, 0, 0.12 * a), 1.0)
				yy2 += 3.0
			var labels: Array = ["CAM 01 · INGRESSO", "CAM 02 · CORSIA NORD", "CAM 03 · SVINCOLO", "CAM 04 · OBIETTIVO"]
			for i in 4:
				var o := Vector2((i % 2) * gx, (i / 2) * gy + (60.0 if i < 2 else 0.0))      # sotto la barra dei tasti rapidi
				draw_string(fb, o + Vector2(18, 30), str(labels[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, dim if i != 3 else wc)
				var secs2: int = int(_t) % 60
				draw_string(fb, o + Vector2(250, 30), "23:4%d:%02d" % [i, secs2], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, dim)
			if fmod(el, 1.0) < 0.6:
				draw_circle(Vector2(sz.x - 120, sz.y - 34), 7.0, Color(REC_RED.r, REC_RED.g, REC_RED.b, a))
				draw_string(fb, Vector2(sz.x - 106, sz.y - 27), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, wc)
			var tp: Vector2 = look_pt if look_pt.x >= 0.0 else Vector2(sz.x * 0.62, sz.y * 0.42)
			var bw: float = lerpf(260.0, 150.0, clampf(el / 0.35, 0.0, 1.0))
			var br := Rect2(tp - Vector2(bw, bw * 1.2) * 0.5, Vector2(bw, bw * 1.2))
			var L2: float = 22.0
			for cn in [br.position, Vector2(br.end.x, br.position.y), Vector2(br.position.x, br.end.y), br.end]:
				var dx2: float = L2 if cn.x == br.position.x else -L2
				var dy2: float = L2 if cn.y == br.position.y else -L2
				draw_line(cn, cn + Vector2(dx2, 0), wc, 3.0)
				draw_line(cn, cn + Vector2(0, dy2), wc, 3.0)
			var pct: int = mini(41 + int(el * 160.0), 98)
			draw_string(fb, br.position + Vector2(0, -10), "RICONOSCIMENTO %d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, wc)
			if pct >= 98:
				draw_string(f, br.position + Vector2(0, br.size.y + 30), "SOGGETTO IDENTIFICATO", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(Ui.YELLOW.r, Ui.YELLOW.g, Ui.YELLOW.b, a))
			var wy: float = sz.y - 70.0
			draw_string(fb, Vector2(24, wy - 30), "INTERCETTAZIONE · CANALE 3 · LANCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, wc)
			for i in 64:
				var hh: float = 4.0 + 26.0 * absf(sin(i * 0.7 + _t * 9.0) * cos(i * 0.23 + _t * 3.0))
				draw_rect(Rect2(Vector2(24 + i * 7.0, wy - hh * 0.5), Vector2(4, hh)), Color(0.55, 0.85, 1.0, 0.8 * a))
			draw_string(fb, Vector2(sz.x * 0.5 + 18, sz.y * 0.5 - 16), "RISERVATO · NON DIVULGARE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(REC_RED.r, REC_RED.g, REC_RED.b, 0.8 * a))
		"drone":
			# Saul dall'alto: la griglia e i dati di un drone
			var gc := Color(_look_col.lightened(0.5).r, _look_col.lightened(0.5).g, _look_col.lightened(0.5).b, 0.22 * a)
			for i in range(1, 6):
				draw_line(Vector2(sz.x * i / 6.0, 0), Vector2(sz.x * i / 6.0, sz.y), gc, 1.5)
				draw_line(Vector2(0, sz.y * i / 6.0), Vector2(sz.x, sz.y * i / 6.0), gc, 1.5)
			var cc2 := sz * 0.5
			draw_arc(cc2, 70.0, 0, TAU, 40, cr, 3.0)
			draw_line(cc2 - Vector2(100, 0), cc2 - Vector2(76, 0), cr, 3.0)
			draw_line(cc2 + Vector2(76, 0), cc2 + Vector2(100, 0), cr, 3.0)
			draw_string(fb, Vector2(40, sz.y - 120), "DRONE · ALT %d m · N %d°" % [12 + int(el * 3.0), 45 + int(el * 20.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, cr)


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
	var tk: Array = TINT.get(_look, [])
	var tin: bool = not tk.is_empty() and _t < _look_until
	if _tints.size() == 2 and (tin or (_tints[0] as ColorRect).visible):
		var el: float = _t - _look_from
		var a: float = clampf(el / 0.12, 0.0, 1.0) * clampf((_look_until - _look_from - el) / 0.2, 0.0, 1.0) if tin else 0.0
		for i in 2:
			var tr: ColorRect = _tints[i]
			tr.visible = a > 0.0
			if tr.visible:
				var tc: Color = tk[i]
				tr.color = Color.WHITE.lerp(tc, a) if i == 0 else Color(tc.r * a, tc.g * a, tc.b * a, 1.0)
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
	if anom_tick != _anom_was or _cut_t > 0.0 or _dist_t > 0.0 or _drawn_busy or not _chat.is_empty() or Time.get_ticks_msec() < _frz_until or _t < _look_until + 0.05 or blink != _blink_was:
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
	if show_tag and not anomaly and _tag != null and fmod(_t, 1.2) < 0.75:
		var tp: Vector2 = _tag.position
		var x: float = tp.x + _tag.size.x - _tag.get_combined_minimum_size().x - 14.0 if tag_right else tp.x - 14.0
		draw_circle(Vector2(x, tp.y + _tag.size.y * 0.5), 7.0, REC_RED)
		draw_arc(Vector2(x, tp.y + _tag.size.y * 0.5), 7.5, 0, TAU, 16, Ui.INK, 2.0)
	if fractured:
		_draw_crack(sz)
	if _cut_t > 0.0:
		_draw_cut(sz)
	if _t < _look_until:
		_draw_look(sz)
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
		var veil: float = (0.15 if lite else 0.28) * clampf(Settings.flash, 0.0, 1.0) * k
		if veil > 0.01:
			draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.02, 0.07, veil))
		# linea che spazza lo schermo nel verso del cambio, con la scia del colore del personaggio
		var sx: float = lerpf(-0.05, 1.05, el / CUT_TIME)
		if _cut_dir < 0.0:
			sx = 1.0 - sx
		# 3/11/2026 (autore: «troppo bianco, alla lunga disturba»): con la carrellata sotto il taglio non deve piu' coprire
		# un salto, quindi velo, linea e fasce sono a meno di meta' di prima
		draw_rect(Rect2(sz.x * sx - 1.5, 0, 3.0, sz.y), Color(1, 1, 1, 0.5 * k))
		draw_rect(Rect2(sz.x * sx - (90.0 if _cut_dir > 0.0 else -6.0) * 1.0, 0, 84.0, sz.y), Color(_who_col.r, _who_col.g, _who_col.b, 0.16 * k))
		# fasce di disturbo: ognuna e' una coppia rossa/ciano sfasata, che scorre verso la nuova telecamera
		var n: int = 4 if lite else 8
		var slide: float = (1.0 - k) * sz.x * 0.4 * _cut_dir
		var frame: float = floor(_t * 30.0)
		for i in n:
			var h: float = fract_hash(float(i) * 7.13 + frame)
			var y: float = sz.y * fract_hash(float(i) * 3.7 + 0.5 + floor(frame / 3.0) * 0.11)
			var bh: float = 3.0 + 20.0 * h * h
			var x0: float = -sz.x * 0.25 + slide + sz.x * 0.45 * fract_hash(float(i) * 5.1 + frame * 0.3)
			var bw: float = sz.x * (0.25 + 0.55 * h)
			var off: float = 10.0 + 14.0 * h
			draw_rect(Rect2(x0 - off, y, bw, bh), Color(1.0, 0.16, 0.25, 0.22 * k))
			draw_rect(Rect2(x0 + off, y, bw, bh), Color(0.25, 0.9, 1.0, 0.22 * k))
			draw_rect(Rect2(x0, y + bh * 0.3, bw, maxf(1.0, bh * 0.4)), Color(1, 1, 1, 0.26 * k) if i % 3 == 0 else Color(_who_col.r, _who_col.g, _who_col.b, 0.32 * k))
	if el < GLITCH_TIME:
		_draw_glitch(sz, el)
	if not (quiet and _stamp_main == ""):      # il cartellino generico tace mentre si sceglie; presentazione e FASE no
		_draw_cam_stamp(sz, el)


# BLOCCHI DIGITALI del cambio di telecamera (autore, 3/11/2026: «usa l'ottavo fotogramma del break»): per ~0,14 s il segnale
# salta come nel BREAK: fondo bianco, blocchi neri a strisce, barre di colore. Solo draw_rect (~30): costa quasi niente.
# Con i lampi spenti nelle impostazioni il bianco non c'e' (restano i blocchi, piu' trasparenti).
# 3/11/2026 (autore: «andava bene colorato e bianco come prima, solo piu' leggero»): stesso disturbo della 0.47 (fondo
# bianco, blocchi neri, barre di colore) ma piu' trasparente e un poco piu' breve, sopra la carrellata. Il BREAK resta pieno.
const GLITCH_TIME: float = 0.12
const GLITCH_BARS: Array = [Color("#ff7326"), Color("#33bf59"), Color("#3359f2"), Color("#ff6699"), Color("#ffe633"), Color("#141414")]


func _draw_glitch(sz: Vector2, el: float) -> void:
	var fl: float = clampf(Settings.flash, 0.0, 1.0)
	var k: float = 1.0 - el / GLITCH_TIME
	var a: float = (0.38 + 0.27 * fl) * clampf(k * 2.0, 0.0, 1.0)
	var frame: float = floor(el * 40.0)
	if fl > 0.05:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.95, 0.94, 0.92, 0.42 * fl * clampf(k * 2.0, 0.0, 1.0)))     # era 0,9
	var n: int = 8 if Settings.light_fx else 18
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
