class_name PortraitHud
extends CmdWheel

# HUD DI BATTAGLIA COL RITRATTO 2D (riferimento dell'autore, 2/11/2026: lo stile del remake di Persona 1).
# In basso a sinistra il ritratto 2D di chi e' di turno, tagliato dal bordo dello schermo; i comandi gli stanno attorno
# come scritte storte (ULTIMATE, ABILITA', ATTACCO a sinistra, GUARDIA a destra), ognuno col suo tasto (1-4) o la sua
# icona sul telefono; il nome grande in fondo. Stessa interfaccia della ruota (CmdWheel): setup, pick, item, tapped,
# hovered, e le bande nere dell'ULTIMATE. La ruota resta nel codice: Settings.hud_ritratto = false la riporta.
#
# Ritratti: res://assets/portraits/hud/<id>_hud.png (2D fatti a mano, guida Procreate in docs/RITRATTI_HUD_PROCREATE.md).
# Finche' non ci sono si usa il mezzobusto <id>_neutro.png come segnaposto.

# Riquadro del ritratto (unita' 1280x720): 352x470, proporzione 3:4, appoggiato al bordo in basso a sinistra.
# Il disegno di Procreate (1536x2048) ci entra intero. Zone (frazioni del riquadro): volto x 0.48-0.92 y 0.12-0.55,
# colonna dei comandi x 0-0.45 y 0.30-0.70, GUARDIA x 0.52-0.95 y 0.70-0.82, nome x 0-0.65 y 0.88-1.
const PW: float = 352.0
const PH: float = 470.0
# posto di ogni comando: [x, distanza della linea di base dal fondo, grandezza, rotazione]. ATTACCO e' il piu' grande.
const SLOT: Dictionary = {      # (vecchia disposizione a colonna, tenuta come riferimento: non piu' usata)
	"ult": [10.0, 300.0, 32, -0.10],
	"skill": [16.0, 236.0, 32, -0.07],
	"attack": [6.0, 168.0, 38, -0.05],
	"guard": [196.0, 104.0, 30, -0.04],
}
# TASTI A ROMBO come Y/X/B/A del controller (correzione dell'autore, 2/11/2026: «il placing dei tasti e' scorretto»).
# Centro del rombo rispetto all'angolo in basso a sinistra; ogni comando sta accanto al suo tasto:
# a sinistra, a scaletta dall'alto: ATTACCO, ABILITA', GUARDIA; a destra, sotto al personaggio: ULTIMATE (autore, 2/11/2026).
# Il centro vuoto del rombo sta sul cuore del personaggio (autore, 2/11/2026): sul disegno 1536x2048 ~ (820, 1500).
const PAD_C: Vector2 = Vector2(188.0, -126.0)
const PAD: Dictionary = {      # kind -> [posto del tasto dal centro, grandezza della scritta, scritta a destra del tasto?]
	"attack": [Vector2(6, -52), 30, false],
	"skill": [Vector2(-46, -4), 30, false],
	"guard": [Vector2(-2, 46), 30, false],
	"ult": [Vector2(52, 14), 30, true],
}
# Scritte tutte della stessa grandezza, quella del piu' piccolo (autore, 2/11/2026); ABILITA' qui si chiama SKILL.
const LABEL: Dictionary = {"skill": "SKILL"}
const KEYS: Dictionary = {"attack": "1", "skill": "2", "ult": "3", "guard": "4"}
const GREY: Color = Color("#8a8496")

var who_id: String = ""                       # id del personaggio (ferri, zecca, nox, saul...): sceglie il ritratto
var _tex: Texture2D
var _tex_real: bool = false
var _usz: int = 30          # grandezza comune delle scritte dei comandi
var _sil: Texture2D                          # sagoma bianca del disegno (per il bordo chiaro)
var _rects: Dictionary = {}                   # kind -> Rect2 in coordinate del controllo (tocco e mouse)
var _hov: String = ""
var stato: String = ""                        # variante per la vita: "", "ferito", "critico" (RitrattoVarianti)
var _base: String = "hud"                     # "hud" o "ng" (skin della Replica)
# RITRATTO VIVO (autore, 3/11/2026: «non sono vive, non sembra Persona»): respira, entra a scatto con il rimbalzo,
# scatta in avanti quando scegli un comando e cambia faccia con un lampo bianco. Solo trasformazioni del disegno che
# c'e' gia' (nessuna texture in piu'): un _draw al fotogramma mentre l'HUD e' visibile, che sul telefono costa poco.
var _punch: float = 0.0                        # 1 = appena scelto un comando o cambiata variante, poi scende
var _swap: float = 0.0                         # lampo bianco della sagoma quando cambia la variante
var _shown: Texture2D
var _born: float = 0.0                         # tempo dell'ultima entrata (per l'oscillazione che si assesta)
# SCIARPA CHE VIVE (sciarpa di Rio disegnata dall'autore come livello a parte, 4/11/2026): la sciarpa e' un PNG ritagliato
# dallo stesso foglio del ritratto (<id>_sciarpa.png, meta' risoluzione) e si disegna sopra con una griglia di triangoli
# deformata, come un Live2D leggero: vicino al collo resta ferma, la coda e le frange ondeggiano col respiro e frustano
# quando il personaggio scatta (scelta del comando, cambio di faccia, colpo). Il ritratto sotto ha gia' la sciarpa
# disegnata, quindi gli spostamenti restano di pochi pixel: ai bordi si vede la stessa sciarpa, mai un buco.
# PRESTAZIONI: 12x9 quadrati = 216 triangoli in una sola chiamata, ricalcolati al fotogramma (pochi microsecondi).
const SCIARPA: Dictionary = {
	# id -> [rettangolo del ritaglio sul foglio 1536x2048 del ritratto, punto fermo (collo) sullo stesso foglio]
	"zecca": [Rect2(117, 656, 1146, 896), Vector2(790, 960)],
}
# TESTA CHE VIVE (testa di Rio come livello a parte, autore 4/11/2026): stesso sistema. La testa ruota appena attorno al
# collo (inclinazione lenta, scatto all'indietro quando sceglie e si riassesta), i capelli lontani dal volto ondeggiano
# e arrivano in ritardo sullo scatto. Si disegna prima della sciarpa, che copre il mento come nel disegno.
const TESTA: Dictionary = {
	# id -> [ritaglio sul foglio 1536x2048, perno (collo), centro del volto (i capelli oltre ~280 px si muovono)]
	"zecca": [Rect2(289, 0, 1226, 1006), Vector2(800, 930), Vector2(830, 520)],
}
var _head: Texture2D
const SC_NX: int = 12
const SC_NY: int = 9
var _scarf: Texture2D
var _whip_t0: float = -10.0                    # tempo dell'ultimo scatto: la sciarpa frusta e si assesta


func _init() -> void:
	super()
	# la ruota disegna su quattro strati e le scintille: qui non servono (tutto in un _draw solo, una draw call in piu')
	for n in [_paint, _beam, _rays, _flow, _front]:
		(n as CanvasItem).visible = false
	_flow.emitting = false


func set_who(id: String) -> void:
	if id == who_id and _tex != null:
		return
	who_id = id
	_tex = null
	_sil = null
	_scarf = null
	_head = null
	_tex_real = false
	var real: String = "res://assets/portraits/hud/%s_hud.png" % id
	if ResourceLoader.exists(real):
		_tex = load(real)
		_tex_real = true
		_sil = _silhouette(_tex)          # le varianti hanno la stessa sagoma: il bordo e l'ombra valgono per tutte
		_base = RitrattoVarianti.base(id)
		var sp: String = "res://assets/portraits/hud/%s_sciarpa.png" % id
		_scarf = load(sp) if SCIARPA.has(id) and ResourceLoader.exists(sp) else null
		var hp: String = "res://assets/portraits/hud/%s_testa.png" % id
		_head = load(hp) if TESTA.has(id) and ResourceLoader.exists(hp) else null
	else:
		var fp: String = "res://assets/portraits/%s_neutro.png" % id
		if ResourceLoader.exists(fp):
			_tex = load(fp)
	queue_redraw()


# Sagoma bianca piena del disegno, a un quarto della grandezza (basta per un bordo di pochi pixel). La soglia sull'alfa
# toglie i puntini quasi trasparenti rimasti attorno al disegno (altrimenti diventano macchie bianche). Una volta per file.
static var _sil_cache: Dictionary = {}


static func _silhouette(t: Texture2D) -> Texture2D:
	if _sil_cache.has(t.resource_path):
		return _sil_cache[t.resource_path]
	var src: Image = t.get_image()
	if src == null:
		return null
	src = src.duplicate()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	src.resize(maxi(1, src.get_width() / 4), maxi(1, src.get_height() / 4), Image.INTERPOLATE_BILINEAR)
	var d: PackedByteArray = src.get_data()
	for i in range(0, d.size(), 4):
		d[i] = 255
		d[i + 1] = 255
		d[i + 2] = 255
		d[i + 3] = 255 if d[i + 3] >= 140 else 0
	var out := Image.create_from_data(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8, d)
	var tex := ImageTexture.create_from_image(out)
	_sil_cache[t.resource_path] = tex
	return tex


# Vita di chi e' di turno: sotto il 50% e il 25% il ritratto si scurisce (varianti dell'autore, 3/11/2026).
func set_stato(s: String) -> void:
	if s != stato:
		stato = s
		queue_redraw()


# Il disegno da mostrare adesso: ULTIMATE o SKILL scelte = l'ombra con lo sguardo acceso; poi la vita; poi la skin di base.
func _tex_now() -> Texture2D:
	if not _tex_real:
		return _tex
	var t: Texture2D = null
	if picked == "ult" or picked == "skill":
		t = RitrattoVarianti.tex(who_id, "ombra")
	if t == null and stato != "":
		t = RitrattoVarianti.tex(who_id, stato)
	if t == null and _base != "hud":
		t = RitrattoVarianti.tex(who_id, _base)
	return t if t != null else _tex


func setup(p_who: String, p_col: Color, p_items: Array) -> void:
	super(p_who, p_col, p_items)
	queue_redraw()


func pick(kind: String) -> void:
	var nuovo: bool = kind != "" and kind != picked
	if nuovo:
		_punch = 1.0
	super(kind)
	if nuovo:
		_whip_t0 = t          # dopo super: la ruota azzera t quando scegli
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	var was_a: float = appear
	var was_s: float = sel
	appear = move_toward(appear, 1.0, delta / 0.32)
	sel = move_toward(sel, 1.0 if picked != "" else 0.0, delta / (0.4 if picked == "ult" else 0.2))
	var was_f: float = flash
	flash = maxf(0.0, flash - delta * 3.2)
	_punch = maxf(0.0, _punch - delta * 4.0)
	_swap = maxf(0.0, _swap - delta * 5.0)
	if was_a == 0.0 and appear > 0.0:
		_born = t
	# PRESTAZIONI: il disegno a mano respira, quindi si ridisegna a ogni fotogramma; il segnaposto solo quando si muove
	if _tex_real or appear != was_a or sel != was_s or flash != was_f:
		queue_redraw()


func _ease(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


func _draw() -> void:
	super()            # bande nere dell'ULTIMATE e lampo della scelta, come la ruota
	var H: float = size.y
	var e: float = _ease(appear)
	var dx: float = -(1.0 - e) * (PW + 60.0)
	var f: Font = Ui.display()
	_rects.clear()
	# 1) lastra del colore di chi e' di turno, storta, con l'ombra d'inchiostro: il ritratto ci sta sopra
	var sh := PackedVector2Array([Vector2(dx, H - 360), Vector2(dx + 250, H - 430), Vector2(dx + PW + 30, H), Vector2(dx, H)])
	var off := PackedVector2Array()
	for q in sh:
		off.append(q + Vector2(10, 8))
	draw_colored_polygon(off, Color(INK, 0.9 * e))
	draw_colored_polygon(sh, Color(col.darkened(0.38 if _tex_real else 0.55), 0.92 * e))      # disegno a mano: lastra piu' chiara, il nero si stacca
	# SFONDO CHE SCORRE (autore, 3/11/2026, idea 4): strisce storte chiare che scivolano dentro la lastra, come i fondali
	# di Persona 5. Ritagliate sulla lastra con Geometry2D (8-10 poligoni piccoli al fotogramma).
	if _tex_real:
		_draw_stripes(sh, dx, H, e)
	# PASSAGGIO DA UN PERSONAGGIO ALL'ALTRO (autore, 3/11/2026: «non e' bello»): una lama chiara attraversa la lastra mentre
	# arriva, poi il ritratto sale da sotto. Netto e veloce, alla Persona: niente dissolvenze molli.
	if appear < 1.0:
		var wk: float = clampf((appear - 0.1) / 0.6, 0.0, 1.0)
		if wk > 0.0 and wk < 1.0:
			var wx: float = dx - 120.0 + wk * (PW + 260.0)
			var blade := PackedVector2Array([Vector2(wx, H), Vector2(wx + 46.0, H), Vector2(wx + 46.0 + 190.0, H - 460.0), Vector2(wx + 190.0, H - 460.0)])
			for poly in Geometry2D.intersect_polygons(sh, blade):
				draw_colored_polygon(poly, Color(CREAM, 0.85 * (1.0 - wk)))
	draw_colored_polygon(PackedVector2Array([Vector2(dx, H - 330), Vector2(dx + 226, H - 376), Vector2(dx + 240, H - 362), Vector2(dx, H - 314)]), Color(col.lightened(0.15), 0.9 * e))
	draw_colored_polygon(PackedVector2Array([Vector2(dx + 268, H - 408), Vector2(dx + 286, H - 412), Vector2(dx + PW + 46, H), Vector2(dx + PW + 26, H)]), Color(col, 0.85 * e))
	# 2) ritratto: in basso, tagliato dal bordo; il volto sta nella meta' destra della zona, le scritte a sinistra e in fondo
	if _tex != null:
		var now_t: Texture2D = _tex_now()
		if now_t != _shown:
			if _shown != null:
				_swap = 1.0          # cambia faccia (ombra, ferito...): lampo bianco della sagoma e piccolo scatto
				_punch = maxf(_punch, 0.6)
				_whip_t0 = t
			_shown = now_t
		_live_transform(dx, H, e)
		var r := Rect2(Vector2(dx, H - PH), Vector2(PW, PH))
		if not _tex_real:
			# segnaposto (mezzobusto 512x768, volto al centro): spostato e ingrandito per mettere il volto nella sua zona
			r = Rect2(Vector2(dx + 92.0, H - 500.0), Vector2(320.0, 480.0))
		if _tex_real:
			# disegno fatto a mano: niente ombra scura (appesantiva i disegni con tanto nero), ma un bordo chiaro del
			# colore del personaggio attorno alla sagoma, cosi' giacche e capelli scuri si staccano dalla lastra (autore, 2/11/2026)
			if _sil != null:
				# ombra piatta dietro al disegno, come sul segnaposto (autore, 2/11/2026: "metti l'ombra dietro al png")
				draw_texture_rect(_sil, Rect2(r.position + Vector2(-14, 10), r.size), false, Color(INK, 0.7 * e))
				var rc: Color = Color(col.lightened(0.15), 0.85 * e)      # sottile e scuro (autore, 2/11/2026: prima troppo spesso e chiaro)
				for k in 8:
					var o: Vector2 = Vector2.RIGHT.rotated(TAU * float(k) / 8.0) * 1.5
					draw_texture_rect(_sil, Rect2(r.position + o, r.size), false, rc)
		else:
			# ombra piatta del colore (stile cel): lo stesso ritratto spostato e scurito
			draw_texture_rect(_tex, Rect2(r.position + Vector2(-8, 6), r.size), false, Color(INK, 0.55 * e))
		draw_texture_rect(now_t, r, false, Color(1, 1, 1, e))
		if _head != null and now_t == _tex:      # le varianti (ferito, ombra...) hanno colori diversi: li' resta ferma
			_draw_head(r, e)
		if _scarf != null and now_t == _tex:
			_draw_scarf(r, e)
		if _swap > 0.0 and _sil != null and _tex_real:
			draw_texture_rect(_sil, r, false, Color(1, 1, 1, 0.85 * _swap * _swap))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 3) comandi attorno al ritratto
	_usz = 30
	for kind in ["ult", "skill", "attack", "guard"]:
		var it0: Dictionary = item(kind)
		if not it0.is_empty():
			_usz = mini(_usz, _fit_size(kind, it0, dx, H, f))
	for kind in ["ult", "skill", "attack", "guard"]:
		var it: Dictionary = item(kind)
		if it.is_empty():
			continue
		_draw_cmd(kind, it, dx, H, f, e)
	# 4) nome grande in fondo, sopra al ritratto (come il nome in giapponese del riferimento)
	var nm: String = who.split(" · ")[0]
	var nsz: int = 40
	while nsz > 26 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x > PW - 20:
		nsz -= 2
	CmdWheel.skew_text(self, Vector2(dx + 12, H - 22), nm, nsz, col.lightened(0.45), INK, f, 12, -0.25)
	if who.contains("RAPIDO"):
		CmdWheel.skew_text(self, Vector2(dx + 16, H - 66), "RAPIDO", 18, HOT, INK, f, 7, -0.25)
	# 5) cosa fa il comando scelto: una lastra scura sopra il ritratto
	if picked != "":
		_draw_tip(item(picked), dx, H, e)


const STRIPE_GAP: float = 46.0
const STRIPE_W: float = 13.0
const STRIPE_SPEED: float = 38.0          # px al secondo: lento, si sente ma non distrae dai comandi


func _draw_stripes(slab: PackedVector2Array, dx: float, H: float, e: float) -> void:
	var c1: Color = Color(col.lightened(0.35), 0.24 * e)
	var c2: Color = Color(INK, 0.22 * e)
	var sc: float = fmod(t * STRIPE_SPEED, STRIPE_GAP)
	var top: float = H - 440.0
	var lean: float = 150.0                 # inclinazione delle strisce (verso destra salendo)
	var x: float = dx - 200.0 + sc
	while x < dx + PW + 80.0:
		var band := PackedVector2Array([Vector2(x, H), Vector2(x + STRIPE_W, H), Vector2(x + STRIPE_W + lean, top), Vector2(x + lean, top)])
		for poly in Geometry2D.intersect_polygons(slab, band):
			draw_colored_polygon(poly, c1)
		# sottile riga scura subito dopo: le strisce sembrano pieghe di carta, non solo luce
		var dark := PackedVector2Array([Vector2(x + STRIPE_W, H), Vector2(x + STRIPE_W + 4.0, H), Vector2(x + STRIPE_W + 4.0 + lean, top), Vector2(x + STRIPE_W + lean, top)])
		for poly2 in Geometry2D.intersect_polygons(slab, dark):
			draw_colored_polygon(poly2, c2)
		x += STRIPE_GAP


# Il ritratto vive: tutto ruota e si scala attorno al punto in basso al centro del riquadro (dove il busto esce dallo schermo).
# - respiro: 1,2% di altezza e 3 px su e giu', lento (circa 3 s), sfasati tra loro come un respiro vero;
# - entrata: arriva storto e si raddrizza con un rimbalzo smorzato (alla Persona, la posa "scatta" al suo posto);
# - scelta: scatto in avanti verso il nemico (+6% e un poco piegato), poi resta appoggiato in avanti finche' sceglie;
# - ULTIMATE scelta: si avvicina ancora (zoom lento), come la telecamera di Persona prima dell'All-Out.
func _live_transform(dx: float, H: float, e: float) -> void:
	if not _tex_real:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	# Correzione dell'autore (3/11/2026, «respira troppo... si vede la fine del PNG tagliato»): niente rotazioni ne' salti
	# in alto. Solo scala attorno al punto in basso al centro e sempre >= 1, cosi' il bordo in basso resta incollato al
	# fondo dello schermo e i bordi tagliati del disegno non si vedono mai. Entrata: sale da sotto, in ritardo sulla lastra.
	var piv := Vector2(dx + PW * 0.5, H)
	var br: float = 0.5 + 0.5 * sin(t * 1.6)                         # respiro lento (~4 s), appena percettibile
	var e2: float = _ease(clampf((appear - 0.25) / 0.75, 0.0, 1.0))  # il ritratto arriva dopo la lastra
	var sc: float = 1.0 + 0.0035 * br + 0.025 * _punch * _punch + (0.02 * sel if picked == "ult" else 0.0)
	var off := Vector2(0.0, (1.0 - e2) * 120.0)                       # da sotto: il bordo in basso resta fuori schermo
	draw_set_transform_matrix(Transform2D(0.0, Vector2(sc, sc), 0.0, piv + off) * Transform2D(0.0, -piv))


# Colpo da fuori (Rio colpita mentre il ritratto e' a schermo): la sciarpa frusta come allo scatto.
func colpo() -> void:
	_whip_t0 = t
	queue_redraw()


func _draw_scarf(r: Rect2, e: float) -> void:
	var d: Array = SCIARPA[who_id]
	var box: Rect2 = d[0]
	var anchor: Vector2 = d[1]
	var k: float = r.size.x / 1536.0                                   # dal foglio del ritratto ai pixel dello schermo
	var br: float = 0.5 + 0.5 * sin(t * 1.6)                           # stesso respiro del ritratto
	var tw: float = t - _whip_t0
	var whip: float = exp(-4.5 * tw) * sin(15.0 * tw) if tw >= 0.0 and tw < 1.5 else 0.0   # molla smorzata: frusta e si assesta
	var tail_x: float = box.position.x + 60.0                          # la coda che pende a sinistra
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for j in SC_NY + 1:
		var v: float = float(j) / SC_NY
		for i in SC_NX + 1:
			var u: float = float(i) / SC_NX
			var p: Vector2 = box.position + box.size * Vector2(u, v)    # punto sul foglio
			var w: float = pow(clampf(p.distance_to(anchor) / 620.0, 0.0, 1.0), 1.4)
			var tail: float = clampf((anchor.x - p.x) / (anchor.x - tail_x), 0.0, 1.0)
			var off := Vector2(
				1.6 * w * sin(t * 2.1 + v * 3.0 + u * 1.5) + 2.6 * tail * tail * sin(t * 3.1 + v * 5.0) - 9.0 * w * whip,
				-2.4 * w * br + 1.2 * w * sin(t * 1.7 + u * 4.0) - 4.0 * w * whip)
			pts.append(r.position + p * k + off)
			uvs.append(Vector2(u, v))
	_draw_grid(pts, uvs, _scarf, e)


func _draw_head(r: Rect2, e: float) -> void:
	var d: Array = TESTA[who_id]
	var box: Rect2 = d[0]
	var piv: Vector2 = d[1]
	var face: Vector2 = d[2]
	var k: float = r.size.x / 1536.0
	var br: float = 0.5 + 0.5 * sin(t * 1.6)
	var tw: float = t - _whip_t0
	var whip: float = exp(-5.0 * tw) * sin(13.0 * tw) if tw >= 0.0 and tw < 1.5 else 0.0
	var tl: float = tw - 0.07                                          # i capelli arrivano un attimo dopo
	var hair_whip: float = exp(-4.0 * tl) * sin(12.0 * tl) if tl >= 0.0 and tl < 1.6 else 0.0
	var ang: float = 0.006 * sin(t * 0.9) + 0.003 * br - 0.022 * whip  # radianti: meno di 1,5 gradi anche nello scatto
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for j in SC_NY + 1:
		var v: float = float(j) / SC_NY
		for i in SC_NX + 1:
			var u: float = float(i) / SC_NX
			var p: Vector2 = box.position + box.size * Vector2(u, v)
			var q: Vector2 = piv + (p - piv).rotated(ang)               # testa rigida attorno al collo
			var hw: float = clampf((p.distance_to(face) - 280.0) / 260.0, 0.0, 1.0)
			hw *= hw
			var off := Vector2(
				hw * (1.8 * sin(t * 2.0 + v * 2.5 + u * 1.2) - 9.0 * hair_whip),
				hw * (-1.4 * br + 1.0 * sin(t * 1.5 + u * 3.0)) - 1.2 * br)
			pts.append(r.position + q * k + off)
			uvs.append(Vector2(u, v))
	_draw_grid(pts, uvs, _head, e)


# Griglia (SC_NX+1)x(SC_NY+1) di punti gia' deformati -> triangoli con la texture, una sola chiamata
func _draw_grid(pts: PackedVector2Array, uvs: PackedVector2Array, tex: Texture2D, e: float) -> void:
	var idx := PackedInt32Array()
	for j in SC_NY:
		for i in SC_NX:
			var a: int = j * (SC_NX + 1) + i
			idx.append_array([a, a + 1, a + SC_NX + 1, a + 1, a + SC_NX + 2, a + SC_NX + 1])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts,
		PackedColorArray([Color(1, 1, 1, e)]), uvs, PackedInt32Array(), PackedFloat32Array(), tex.get_rid())


# grandezza piu' grande con cui la scritta di questo comando entra nel suo spazio
func _fit_size(kind: String, it: Dictionary, dx: float, H: float, f: Font) -> int:
	var pd: Array = PAD[kind]
	var bc: Vector2 = Vector2(dx, H) + PAD_C + (pd[0] as Vector2)
	var name: String = str(LABEL.get(kind, it.get("name", kind)))
	var maxw: float = (bc.x - 26.0 - dx - 6.0) if not bool(pd[2]) else 160.0
	var sz: int = int(pd[1])
	while sz > 20 and f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > maxw:
		sz -= 2
	return sz


func _draw_cmd(kind: String, it: Dictionary, dx: float, H: float, f: Font, e: float) -> void:
	var pd: Array = PAD[kind]
	var bc: Vector2 = Vector2(dx, H) + PAD_C + (pd[0] as Vector2)      # tasto rotondo (posto nel rombo)
	var right: bool = bool(pd[2])
	var sz: int = _usz
	var name: String = str(LABEL.get(kind, it.get("name", kind)))
	var ok: bool = bool(it.get("ok", false))
	var on: bool = picked == kind
	var tw: float = f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var br: float = 15.0 if not on else 18.0
	# la scritta sta a sinistra del tasto e finisce sul tasto (ULTIMATE, ABILITA', ATTACCO) o parte dal tasto (GUARDIA)
	var p := Vector2(bc.x + br + 8.0, bc.y + sz * 0.36) if right else Vector2(bc.x - br - 8.0 - tw, bc.y + sz * 0.36)
	var rot: float = -0.06
	var fill: Color = Color(CREAM.lerp(col.lightened(0.6), 0.45)) if ok else GREY
	draw_set_transform(p, rot)
	if on:
		var slab := PackedVector2Array([Vector2(-10, -sz * 0.92), Vector2(tw + 14, -sz * 1.02), Vector2(tw + 6, sz * 0.22), Vector2(-16, sz * 0.3)])
		var sdw := PackedVector2Array()
		for q in slab:
			sdw.append(q + Vector2(6, 6))
		draw_colored_polygon(sdw, Color(INK, e))
		draw_colored_polygon(slab, Color(col.lightened(0.1), e))
		fill = HOT
	elif _hov == kind and ok:
		fill = CREAM
	# ombra del colore sfalsata (lettering del riferimento) + contorno d'inchiostro spesso
	draw_set_transform(p + Vector2(4, 4).rotated(rot), rot, Vector2(1, 1))
	draw_string_outline(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 10, Color(col.darkened(0.2), 0.95 * e))
	draw_set_transform(p, rot)
	draw_string_outline(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 9, Color(INK, e))
	draw_string(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(fill, e))
	# ULTIMATE non pronta: la carica in piccolo sotto la scritta
	if kind == "ult" and not ok:
		draw_string(Ui.body(), Vector2(4, 18), str(it.get("cost", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(GREY, e))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# tasto rotondo: numero della tastiera su PC, icona sul telefono
	draw_circle(bc + Vector2(2, 2), br + 3, Color(INK, e))
	draw_circle(bc, br + 2, Color(CREAM if ok else GREY, e))
	draw_circle(bc, br - 1, Color(INK if not on else col.darkened(0.3), e))
	if Ui.is_touch():
		CmdWheel.glyph(self, kind, bc, br * 0.8, Color(CREAM if ok else GREY, e))
	else:
		var k: String = str(KEYS.get(kind, ""))
		var ks: Vector2 = f.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(f, bc + Vector2(-ks.x * 0.5, 7), k, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(CREAM if ok else GREY, e))
	# zona del tocco: scritta + tasto, almeno 48 di altezza (i tasti del rombo sono vicini: le zone non si sovrappongono)
	var x0: float = minf(p.x, bc.x - br) - 6.0
	var x1: float = maxf(p.x + tw, bc.x + br) + 6.0
	var hh: float = 46.0
	_rects[kind] = Rect2(Vector2(x0, bc.y - hh * 0.5), Vector2(x1 - x0, hh))


func _draw_tip(it: Dictionary, dx: float, H: float, e: float) -> void:
	if it.is_empty():
		return
	var bf: Font = Ui.body()
	var lines: Array = CmdWheel.wrap(bf, str(it.get("desc", "")).replace("\n", " · "), 16, 330.0)
	if lines.size() > 3:
		lines = lines.slice(0, 3)
	var top: float = H - 400.0 - 30.0 - 20.0 * lines.size()
	var r := Rect2(Vector2(dx + 6, top), Vector2(360, 34 + 20.0 * lines.size()))
	var poly := CmdWheel.slant(r, 10.0)
	draw_colored_polygon(poly, Color(0.03, 0.02, 0.06, 0.88 * e))
	draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(col.lightened(0.3), e), 2.0)
	draw_string(Ui.display(), r.position + Vector2(16, 24), str(it.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, 330, 17, Color(HOT, e))
	for i in lines.size():
		draw_string(bf, r.position + Vector2(16, 46 + 20 * i), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(CREAM, e))


func _has_point(p: Vector2) -> bool:
	for k in _rects:
		if (_rects[k] as Rect2).has_point(p):
			return true
	return false


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var hk: String = ""
		for k in _rects:
			if (_rects[k] as Rect2).has_point((ev as InputEventMouseMotion).position):
				hk = k
		if hk != _hov:
			_hov = hk
			hovered.emit(hk)
			queue_redraw()
		return
	var pressed: bool = (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	var p: Vector2 = (ev as InputEventScreenTouch).position if ev is InputEventScreenTouch else (ev as InputEventMouseButton).position
	for k in _rects:
		if (_rects[k] as Rect2).has_point(p):
			accept_event()
			tapped.emit(k)
			return
