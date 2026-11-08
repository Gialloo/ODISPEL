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
	"attack": [Vector2(6, -58), 30, false],     # 54 px fra un comando e l'altro: zone di tocco alte 52 che non si toccano (7/11/2026)
	"skill": [Vector2(-46, -4), 30, false],
	"guard": [Vector2(6, 58), 30, false],      # croce precisa (autore, 8/11/2026): GUARDIA speculare ad ATTACCO
	"ult": [Vector2(58, -4), 30, true],        # e ULTIMATE speculare a SKILL (prima erano sfalsate)
}
# Scritte tutte della stessa grandezza, quella del piu' piccolo (autore, 2/11/2026); ABILITA' qui si chiama SKILL.
const LABEL: Dictionary = {"skill": "SKILL"}
const KEYS: Dictionary = {"attack": "1", "skill": "2", "ult": "3", "guard": "4"}
const GREY: Color = Color("#8a8496")

var who_id: String = ""                       # id del personaggio (lance, rio, nox, saul...): sceglie il ritratto
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
	"rio": [Rect2(117, 656, 1146, 896), Vector2(790, 960)],
	# Lance: le falde del colletto rosso (bozza approvata dall'autore, 4/11/2026): vicine al collo, quasi ferme e precise
	"lance": [Rect2(766, 1046, 510, 278), Vector2(1015, 1060)],
}
# TESTA CHE VIVE (testa di Rio come livello a parte, autore 4/11/2026): stesso sistema. La testa ruota appena attorno al
# collo (inclinazione lenta, scatto all'indietro quando sceglie e si riassesta), i capelli lontani dal volto ondeggiano
# e arrivano in ritardo sullo scatto. Si disegna prima della sciarpa, che copre il mento come nel disegno.
const TESTA: Dictionary = {
	# id -> [ritaglio sul foglio 1536x2048, perno (collo), centro del volto (i capelli oltre ~280 px si muovono)]
	"rio": [Rect2(258, 0, 1278, 1004), Vector2(800, 930), Vector2(830, 520)],
	# bozze vettoriali approvate dall'autore (4/11/2026, «vanno bene, usa questi»). Il cappuccio di Nox e il berretto di
	# Saul stanno nella testa, cosi' la seguono: le orecchie da civetta e la punta del berretto, lontane dal volto, ondeggiano
	"lance": [Rect2(844, 264, 582, 702), Vector2(1015, 960), Vector2(1130, 640)],
	"nox": [Rect2(816, 92, 668, 1020), Vector2(1015, 960), Vector2(1150, 650)],
	"saul": [Rect2(862, 210, 644, 760), Vector2(1015, 960), Vector2(1150, 660)],
}
var _head: Texture2D
# RITRATTI FERMI (autore, 5/11/2026: Lance e Saul disegnati a mano, «come Rio ma senza animazioni»): per questi niente
# testa, sciarpa e busto a livelli, niente respiro ne' scatti; il ritratto entra con la lastra e poi resta immobile.
# Le bozze vettoriali di prima sono nella cartella del progetto, odispel/v3/ritratti_bozze_lance_saul/.
# Nox disegnata a mano dall'autore (6/11/2026): entra tra i fermi come Lance e Saul; la bozza vettoriale e' nella stessa cartella.
# Rio, design ufficiale dell'autore (6/11/2026): fermo anche lui; testa, busto e sciarpa a livelli erano del disegno di prima
# e sono conservati con il vecchio ritratto in odispel/v3/ritratti_bozze_lance_saul/rio_prima_del_design_ufficiale/.
const FERMI: Array = ["lance", "saul", "nox", "rio"]
# RITRATTO A LIVELLI (busto dell'autore, 4/11/2026): se c'e' <id>_busto.png (il ritratto senza la testa) e c'e' la testa,
# il ritratto normale si compone busto + testa + sciarpa invece del PNG intero, cosi' la testa si muove di piu' senza
# lasciare la vecchia testa sotto. La testa porta con se' il suo alone (ritagliato dal ritratto intero). Le varianti
# (ferito, ombra...) restano PNG interi e fermi.
var _busto: Texture2D
# CORNICE DEL PERSONAGGIO (autore, 7/11/2026, prova): due livelli disegnati a mano dietro al ritratto, stessa tela 1536x2048.
# <id>_dietro.png (il glitch) e <id>_avanti.png (le lame del colore), separati per muoverli da soli. Con la cornice i
# comandi diventano quattro lastre bianche storte sopra la testa (mockup dell'autore). Settings.hud_cornice = false o file
# mancanti: tutto come prima.
var _dietro: Texture2D
var _avanti: Texture2D
var _polys: Dictionary = {}
# HUD come la foto dell'autore (Settings.hud_foto): sinergia in cima alla cornice e obiettivo in fondo (li passa battle3d)
var banner_title: String = ""
var banner_sub: String = ""
var banner_t: float = 0.0          # SINERGIA (autore, 8/11/2026): non resta fissa, compare all'inizio del turno e sparisce
const BANNER_SEC: float = 2.6
var objective: String = ""                     # kind -> lastra del comando (tocco preciso: le lastre si incastrano)
const CORNICE_SCALA: float = 1.05               # la cornice e' un po' piu' grande del riquadro del ritratto: le lastre si leggono
const CORNICE_RITRATTO: float = 0.72            # il ritratto rimpicciolito e appoggiato in basso, come nel mockup (stile "lastre")
# Disposizione dei comandi sulla cornice. "lista" (autore, 7/11/2026, riferimento): ritratto grande, comandi in colonna
# a nastri storti sotto il volto, ognuno col suo tasto tondo; "lastre": le quattro lastre sopra la testa del primo mockup.
const CORNICE_STILE: String = "testo"      # "testo" = comandi come nella 0.58 (scritte e tasti tondi) sopra la cornice (autore, 7/11/2026); "lista" = nastri; altro = lastre
const LISTA_ORDINE: Array = ["attack", "skill", "guard", "ult"]
const LISTA_NOME: Dictionary = {"attack": "ATTACCO", "skill": "ABILITÀ", "guard": "GUARDIA", "ult": "ULTIMATE"}
const LISTA_X: float = 0.40          # inizio della prima riga (frazione della cornice); ogni riga scende e rientra un poco
const LISTA_Y: float = 0.56
const LISTA_PASSO: float = 0.074     # (vecchio passo in frazione, non piu' usato dai nastri)
const LISTA_ALTO: float = 46.0        # nastri piu' alti e staccati: si leggono e non si sbaglia tocco (autore, 7/11/2026)
const LISTA_STACCO: float = 54.0      # passo fra i nastri in pixel: 8 px di vuoto fra uno e l'altro
const LISTA_FONDO: float = 46.0       # l'ultimo nastro finisce qui sopra il fondo (sopra la striscia dell'obiettivo)
const RITRATTO_SCALA: Dictionary = {"nox": 1.12}   # Nox nel suo png e' disegnata piu' piccola degli altri (autore, 7/11/2026)
const LISTA_ANGOLO: float = -0.35       # pendenza del lato a punta di saul_avanti; provata su nastri e SINERGIA il 7/11/2026 e scartata dall'autore, tenuta per riprovarla
const LISTA_RITRATTO: float = 0.96      # il ritratto riempie quasi tutta la cornice
# lastre dei comandi in frazioni della cornice (dal mockup di Saul): [alto-sx, alto-dx, basso-dx, basso-sx]
const LASTRE: Dictionary = {
	"attack": [Vector2(0.067, 0.160), Vector2(0.450, 0.108), Vector2(0.447, 0.205), Vector2(0.063, 0.262)],
	"ult": [Vector2(0.467, 0.125), Vector2(0.910, 0.050), Vector2(0.860, 0.150), Vector2(0.460, 0.210)],
	"guard": [Vector2(0.037, 0.290), Vector2(0.433, 0.226), Vector2(0.427, 0.325), Vector2(0.027, 0.388)],
	"skill": [Vector2(0.460, 0.222), Vector2(0.830, 0.160), Vector2(0.777, 0.260), Vector2(0.440, 0.313)],
}
const LASTRE_NOME: Dictionary = {"attack": "ATTACCO", "ult": "ULTIMATE", "guard": "GUARDIA", "skill": "SKILL"}
var _sil_busto: Texture2D
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
	_busto = null
	_sil_busto = null
	_tex_real = false
	_dietro = null
	_avanti = null
	if Settings.hud_cornice:
		var dp: String = "res://assets/portraits/hud/%s_dietro.png" % id
		var ap: String = "res://assets/portraits/hud/%s_avanti.png" % id
		if ResourceLoader.exists(dp) and ResourceLoader.exists(ap):
			_dietro = load(dp)
			_avanti = load(ap)
	var real: String = "res://assets/portraits/hud/%s_hud.png" % id
	if ResourceLoader.exists(real):
		_tex = load(real)
		_tex_real = true
		_sil = _silhouette(_tex)          # le varianti hanno la stessa sagoma: il bordo e l'ombra valgono per tutte
		_base = RitrattoVarianti.base(id)
		if FERMI.has(id):
			queue_redraw()
			return
		var sp: String = "res://assets/portraits/hud/%s_sciarpa.png" % id
		_scarf = load(sp) if SCIARPA.has(id) and ResourceLoader.exists(sp) else null
		var hp: String = "res://assets/portraits/hud/%s_testa.png" % id
		_head = load(hp) if TESTA.has(id) and ResourceLoader.exists(hp) else null
		var bp: String = "res://assets/portraits/hud/%s_busto.png" % id
		if _head != null and ResourceLoader.exists(bp):
			_busto = load(bp)
			_sil_busto = _silhouette(_busto)
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
	if kind != "" and kind != picked:
		_punch = 1.0
	super(kind)
	# niente frustata di testa, capelli e sciarpa quando cambi mossa (autore, 4/11/2026: «il movimento forte di
	# assestamento quando cambi mossa eliminalo»): restano solo il respiro e l'ondeggiare lento
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	if banner_t > 0.0:
		banner_t = maxf(0.0, banner_t - delta)
		queue_redraw()
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


# Zona sicura (8/11/2026): l'HUD sta a qualche px dai bordi, ma il ritratto e la sua cornice sono disegno e devono uscire dallo
# schermo come prima. battle3d dice quanto manca al bordo (bleed): il disegno si allarga in proporzione verso sinistra e in basso,
# con l'angolo in alto a destra fermo; scritte e comandi restano dove sono.
var bleed: Vector2 = Vector2.ZERO
func _bleed(r: Rect2) -> Rect2:
	if bleed == Vector2.ZERO or r.size.x < 1.0:
		return r
	var k: float = maxf(bleed.x / r.size.x, bleed.y / r.size.y)
	var ns: Vector2 = r.size * (1.0 + k)
	return Rect2(Vector2(r.end.x - ns.x, r.position.y), ns)


func _draw() -> void:
	super()            # bande nere dell'ULTIMATE e lampo della scelta, come la ruota
	var H: float = size.y
	if Settings.hud_accenti and flash > 0.01:
		# P2: nel lampo della scelta il segno del personaggio (tagli di Lance, anelli di Nox, pezzi storti di Saul)
		CharAccent.draw(self, who_id, Rect2(Vector2(0, H - PH - 40.0), Vector2(PW + 160.0, PH)), col.lightened(0.3), minf(1.0, flash * 1.6))
	var e: float = _ease(appear)
	var dx: float = -(1.0 - e) * (PW + 60.0)
	var f: Font = Ui.display()
	_rects.clear()
	var cornice: bool = _dietro != null and _avanti != null
	_polys.clear()
	if cornice:
		_draw_cornice(dx, H, e)
	else:
		_draw_lastra(dx, H, e)
	# 2) ritratto: in basso, tagliato dal bordo; il volto sta nella meta' destra della zona, le scritte a sinistra e in fondo
	if _tex != null:
		var now_t: Texture2D = _tex_now()
		if now_t != _shown:
			if _shown != null:
				_swap = 1.0          # cambia faccia (ombra, ferito...): lampo bianco della sagoma e piccolo scatto
				_punch = maxf(_punch, 0.6)
			_shown = now_t
		_live_transform(dx, H, e)
		var r := Rect2(Vector2(dx, H - PH), Vector2(PW, PH))
		if cornice and _tex_real:
			r = _cornice_rect(dx, H)
		r = _bleed(r)
		if not _tex_real:
			# segnaposto (mezzobusto 512x768, volto al centro): spostato e ingrandito per mettere il volto nella sua zona
			r = Rect2(Vector2(dx + 92.0, H - 500.0), Vector2(320.0, 480.0))
		if _tex_real:
			# disegno fatto a mano: niente ombra scura (appesantiva i disegni con tanto nero), ma un bordo chiaro del
			# colore del personaggio attorno alla sagoma, cosi' giacche e capelli scuri si staccano dalla lastra (autore, 2/11/2026)
			var lay: bool = _busto != null and now_t == _tex        # ritratto a livelli: la sagoma e' quella del busto
			var sl: Texture2D = _sil_busto if lay else _sil
			if sl != null:
				# ombra piatta dietro al disegno, come sul segnaposto (autore, 2/11/2026: "metti l'ombra dietro al png")
				draw_texture_rect(sl, Rect2(r.position + Vector2(-14, 10), r.size), false, Color(INK, 0.7 * e))
				if lay:
					_draw_head(r, e, Vector2(-14, 10), Color(INK, 0.7 * e))   # ombra della testa, che si muove con lei
				var rc: Color = Color(col.lightened(0.15), 0.85 * e)      # sottile e scuro (autore, 2/11/2026: prima troppo spesso e chiaro)
				# il bordo sottile usa la sagoma intera anche a livelli: quella del busto avrebbe una riga sul taglio del
				# mento; attorno ai capelli resta sotto l'alone della testa, che si sposta di pochi pixel
				for k in 8:
					var o: Vector2 = Vector2.RIGHT.rotated(TAU * float(k) / 8.0) * 1.5
					draw_texture_rect(_sil, Rect2(r.position + o, r.size), false, rc)
		else:
			# ombra piatta del colore (stile cel): lo stesso ritratto spostato e scurito
			draw_texture_rect(_tex, Rect2(r.position + Vector2(-8, 6), r.size), false, Color(INK, 0.55 * e))
		var layered: bool = _tex_real and _busto != null and now_t == _tex
		# HUD Combat 2.0: il ritratto e' decorazione, un filo meno luminoso (0,86) perche' comandi e nome gli stiano davanti
		var lu: float = float(HudLayers.v("ritratto.luce"))
		draw_texture_rect(_busto if layered else now_t, r, false, Color(lu, lu, lu, e))
		if _head != null and now_t == _tex:      # le varianti (ferito, ombra...) hanno colori diversi: li' resta ferma
			_draw_head(r, e, Vector2.ZERO, Color(lu, lu, lu, e), layered)
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
			_usz = mini(_usz, (28 if CORNICE_STILE == "lista" else _lastra_fit(kind, f)) if cornice and CORNICE_STILE != "testo" else _fit_size(kind, it0, dx, H - _cmd_up(cornice), f))
	if cornice and Settings.hud_foto and CORNICE_STILE == "lista":
		# banda scura strappata sotto la lista dei comandi (foto: i nastri stanno su uno strappo nero)
		var cr := Rect2(Vector2(dx, H - PH * CORNICE_SCALA), Vector2(PW, PH) * CORNICE_SCALA)
		_shard(cr, [Vector2(0.33, 0.55), Vector2(1.02, 0.49), Vector2(0.95, 0.86), Vector2(0.30, 0.90)], Color(INK, 0.55 * e), 7.0, 4)
	for kind in ["ult", "skill", "attack", "guard"]:
		var it: Dictionary = item(kind)
		if it.is_empty():
			continue
		if cornice and CORNICE_STILE != "testo":
			if CORNICE_STILE == "lista":
				_draw_riga_cmd(kind, it, dx, H, f, e)
			else:
				_draw_lastra_cmd(kind, it, dx, H, f, e)
		else:
			_draw_cmd(kind, it, dx, H - _cmd_up(cornice), f, e)
	# 4) nome grande in fondo, sopra al ritratto (come il nome in giapponese del riferimento)
	var nm: String = who.split(" · ")[0]
	if cornice and Settings.hud_foto:
		_draw_foto_bottom(nm, dx, H, f, e)
	else:
		_draw_name(nm, dx, H, f)
		if cornice and Settings.hud_obiettivo:
			_draw_extra(Rect2(Vector2(dx, H - PH * CORNICE_SCALA), Vector2(PW, PH) * CORNICE_SCALA), dx, H, f, e)
	# 5) cosa fa il comando scelto: una lastra scura sopra il ritratto
	tip_rect = Rect2()
	if picked != "":
		_draw_tip(item(picked), dx, H, e)


# con la cornice e l'obiettivo in fondo il nome sale di 34: i comandi salgono con lui per non coprirlo
func _cmd_up(cornice: bool) -> float:
	return 34.0 if cornice and Settings.hud_obiettivo and objective != "" else 0.0


func _draw_name(nm: String, dx: float, H: float, f: Font) -> void:
	var nsz: int = 40
	while nsz > 26 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x > PW - 20:
		nsz -= 2
	var up: float = 34.0 if Settings.hud_obiettivo and objective != "" and _dietro != null else 0.0     # lascia posto all'obiettivo
	CmdWheel.skew_text(self, Vector2(dx + 12, H - 22 - up), nm, nsz, col.lightened(0.45), INK, f, 12, -0.25)
	if who.contains("RAPIDO"):
		# a destra del nome, sulla stessa riga (autore, 8/11/2026; prima stava sopra il nome e finiva tra i comandi)
		var nw: float = f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x
		CmdWheel.skew_text(self, Vector2(dx + 12 + nw + 18, H - 22 - up), "RAPIDO", 20, HOT, INK, f, 7, -0.25)


# Fondo della cornice come la foto: strappo del colore, nome enorme bianco, sinergia in cima e obiettivo in fondo.
func _draw_foto_bottom(nm: String, dx: float, H: float, f: Font, e: float) -> void:
	var cr := Rect2(Vector2(dx, H - PH * CORNICE_SCALA), Vector2(PW, PH) * CORNICE_SCALA)
	_shard(cr, [Vector2(0.0, 0.84), Vector2(0.66, 0.79), Vector2(0.74, 0.90), Vector2(0.0, 0.95)], Color(col, 0.95 * e), 6.0, 5)
	var nsz: int = 62
	while nsz > 30 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x > PW - 30:
		nsz -= 2
	CmdWheel.skew_text(self, Vector2(dx + 18, H - 44), nm, nsz, CREAM, INK, f, 12, -0.3)
	if who.contains("RAPIDO"):
		CmdWheel.skew_text(self, Vector2(dx + 22, H - 44 - nsz), "RAPIDO", 18, HOT, INK, f, 7, -0.25)
	_draw_extra(cr, dx, H, f, e)


# Obiettivo in fondo e SINERGIA in cima alla cornice (tenuti dall'autore, 7/11/2026: Settings.hud_obiettivo).
func _draw_extra(cr: Rect2, dx: float, H: float, f: Font, e: float) -> void:
	if objective != "":
		var bf: Font = Ui.body()
		var ow: float = bf.get_string_size(objective, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x + 62.0
		var ob := PackedVector2Array([Vector2(dx + 12, H - 34), Vector2(dx + 12 + ow, H - 38), Vector2(dx + ow, H - 6), Vector2(dx, H - 4)])
		draw_colored_polygon(torn(ob, 2.0, 6), Color(0.02, 0.01, 0.04, 0.9 * e))
		draw_circle(Vector2(dx + 26, H - 20), 10.0, Color(HOT, e))
		var xw: float = f.get_string_size("!", HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(f, Vector2(dx + 26 - xw * 0.5, H - 13), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(INK, e))
		draw_string(bf, Vector2(dx + 46, H - 14), objective, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.font_size("obiettivo"), Color(HudLayers.tone("obiettivo", CREAM), e))      # L4 quieto
	if banner_title != "" and banner_t > 0.0:
		var e2: float = e * clampf(banner_t / 0.4, 0.0, 1.0)      # sparisce in 0,4 s
		# SINERGIA: lastra nera inclinata come la scritta (autore, 7/11/2026), tutto nello stesso giro
		var tf: int = 20
		var sf: int = HudLayers.MIN_TEXT
		var tw: float = f.get_string_size(banner_title, HORIZONTAL_ALIGNMENT_LEFT, -1, tf).x
		var sw: float = Ui.body().get_string_size(banner_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sf).x
		var bw: float = 46.0 + tw + 12.0 + sw + 18.0
		# orizzontale come la scena e un po' piu' piccola (autore, 7/11/2026: la versione inclinata sul lato a punta non piaceva)
		draw_set_transform(Vector2(dx + 16.0, cr.position.y + 30.0), 0.0)
		var pl := PackedVector2Array([Vector2(8, -18), Vector2(bw + 8, -18), Vector2(bw, 18), Vector2(0, 18)])
		var sh := PackedVector2Array()
		for q in pl:
			sh.append(q + Vector2(5, 5))
		draw_colored_polygon(sh, Color(INK, 0.85 * e2))
		draw_colored_polygon(pl, Color(0.02, 0.01, 0.04, 0.94 * e2))
		draw_polyline(pl + PackedVector2Array([pl[0]]), Color(CREAM, 0.9 * e2), 2.0, true)
		CmdWheel.glyph(self, "skill", Vector2(24, 0), 13.0, Color(HOT, e2))
		draw_string_outline(f, Vector2(46, 8), banner_title, HORIZONTAL_ALIGNMENT_LEFT, -1, tf, 6, Color(INK, e2))
		draw_string(f, Vector2(46, 8), banner_title, HORIZONTAL_ALIGNMENT_LEFT, -1, tf, Color(HOT, e2))
		draw_string(Ui.body(), Vector2(46 + tw + 12, 6), banner_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sf, Color(CREAM, e2))
		draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_lastra(dx: float, H: float, e: float) -> void:
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


# Cornice a due livelli: DIETRO entra piu' lento e ogni tanto scatta di lato (il glitch), AVANTI entra deciso col ritratto.
func _draw_cornice(dx: float, H: float, e: float) -> void:
	var cs := Vector2(PW, PH) * CORNICE_SCALA
	var r := _bleed(Rect2(Vector2(dx, H - cs.y), cs))
	var eb: float = _ease(clampf(appear * 0.8, 0.0, 1.0))
	var gl: Vector2 = Vector2.ZERO
	var ph: float = fmod(t, 2.6)
	if ph < 0.12:          # scatto del glitch: due frame di lato, poi fermo (niente tremolio continuo)
		gl = Vector2(6.0 if ph < 0.06 else -4.0, 0.0)
	draw_texture_rect(_dietro, Rect2(r.position + Vector2(-(1.0 - eb) * 80.0, 0.0) + gl, r.size), false, Color(1, 1, 1, e))
	draw_texture_rect(_avanti, Rect2(r.position + Vector2(-(1.0 - e) * 40.0, (1.0 - e) * 30.0), r.size), false, Color(1, 1, 1, e))
	if Settings.hud_foto:
		# grafica "a strappi" della foto: lame bianche e del colore coi bordi strappati attorno al ritratto
		_shard(r, [Vector2(0.0, 0.11), Vector2(0.24, 0.02), Vector2(0.29, 0.05), Vector2(0.03, 0.20)], Color(CREAM, 0.92 * e), 5.0, 1)
		_shard(r, [Vector2(0.0, 0.24), Vector2(0.13, 0.15), Vector2(0.15, 0.40), Vector2(0.0, 0.50)], Color(col, 0.95 * e), 6.0, 2)
		_shard(r, [Vector2(0.86, 0.30), Vector2(1.0, 0.18), Vector2(0.97, 0.26), Vector2(0.84, 0.36)], Color(CREAM, 0.8 * e), 4.0, 3)


# Bordo strappato: ogni lato del poligono diventa una fila di denti irregolari (sempre gli stessi: niente tremolio).
static func torn(pts: PackedVector2Array, amp: float, seed_n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n * 7919 + 17
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var n: int = maxi(1, int(a.distance_to(b) / 9.0))
		var nr: Vector2 = (b - a).orthogonal().normalized()
		for k in n:
			var p: Vector2 = a.lerp(b, float(k) / float(n))
			out.append(p + nr * (rng.randf_range(-1.0, 1.0) * amp if k > 0 else 0.0))
	return out


func _shard(r: Rect2, fr: Array, c: Color, amp: float, seed_n: int) -> void:
	var pts := PackedVector2Array()
	for v in fr:
		pts.append(r.position + (v as Vector2) * r.size)
	var tp := torn(pts, amp, seed_n)
	var sh := PackedVector2Array()
	for q in tp:
		sh.append(q + Vector2(5, 5))
	draw_colored_polygon(sh, Color(INK, c.a * 0.8))
	draw_colored_polygon(tp, c)


func _cornice_rect(dx: float, H: float) -> Rect2:
	var cs := Vector2(PW, PH) * CORNICE_SCALA * (LISTA_RITRATTO if CORNICE_STILE in ["lista", "testo"] else CORNICE_RITRATTO)
	var k: float = float(RITRATTO_SCALA.get(who_id, 1.0))
	var big := cs * k
	return Rect2(Vector2(dx - (big.x - cs.x) * 0.3, H - big.y), big)      # cresce verso l'alto, poco verso sinistra


# Comando sulla cornice: lastra bianca storta, icona e scritta d'inchiostro (mockup dell'autore). ULTIMATE pronta: lastra
# scura del colore e scritta gialla. Scelto: stessa lastra scura col bordo giallo. Non usabile: lastra velata, scritta grigia.
func _draw_lastra_cmd(kind: String, it: Dictionary, dx: float, H: float, f: Font, e: float) -> void:
	var q := PackedVector2Array()
	for v in LASTRE[kind]:
		q.append(Vector2(dx, H - PH * CORNICE_SCALA) + (v as Vector2) * Vector2(PW, PH) * CORNICE_SCALA)
	_polys[kind] = q
	var ok: bool = bool(it.get("ok", false))
	var on: bool = picked == kind
	var dark: bool = on or (kind == "ult" and ok)
	var sdw := PackedVector2Array()
	for v in q:
		sdw.append(v + Vector2(4, 4))
	draw_colored_polygon(sdw, Color(INK, 0.85 * e))
	var plate: Color = Color(col.darkened(0.62), 0.97) if dark else (Color(1, 1, 0.92, 0.97) if _hov == kind and ok else (Color(0.97, 0.98, 0.97, 0.95) if ok else Color(0.66, 0.66, 0.7, 0.92)))
	draw_colored_polygon(q, Color(plate, plate.a * e))
	if on:
		draw_polyline(q + PackedVector2Array([q[0]]), Color(HOT, e), 3.0, true)
	var ink: Color = HOT if dark else (INK if ok else Color(INK, 0.62))
	# asse della lastra: la scritta segue il bordo alto, centrata in altezza
	var left: Vector2 = (q[0] + q[3]) * 0.5
	var right: Vector2 = (q[1] + q[2]) * 0.5
	var rot: float = (right - left).angle()
	var hgt: float = (q[3] - q[0]).length()
	var name: String = str(LASTRE_NOME[kind])
	var k: String = "" if Ui.is_touch() else str(KEYS.get(kind, ""))
	var kw: float = Ui.body().get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x + 6.0 if k != "" else 0.0
	var tx: float = hgt * 0.82
	var room: float = (right - left).length() - tx - 10.0 - kw
	var sz: int = _usz          # stessa grandezza per le quattro lastre (la piu' stretta decide)
	if kind == "ult" and not ok:
		# ULTIMATE in carica: una striscia rosa lungo il bordo alto si allunga con la carica, e al posto del tasto la percentuale
		var pc: float = clampf(str(it.get("cost", "0")).to_float() / 100.0, 0.0, 1.0)
		var dn: Vector2 = (q[3] - q[0]) * 0.2
		var a0: Vector2 = q[0]
		var a1: Vector2 = q[0].lerp(q[1], pc)
		draw_colored_polygon(PackedVector2Array([a0, a1, a1 + dn, a0 + dn]), Color(Ui.PINK, e))
		k = str(it.get("cost", ""))
	var ic: Vector2 = left + Vector2(hgt * 0.42 + 2.0, 0).rotated(rot)
	CmdWheel.glyph(self, kind, ic, hgt * 0.3, Color(ink, e))
	draw_set_transform(left + Vector2(tx, sz * 0.36).rotated(rot), rot)
	draw_string(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(ink, e))
	if k != "":
		# tasto della tastiera in piccolo, dentro la lastra dopo la scritta
		draw_string(Ui.body(), Vector2(f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + 6.0, -sz * 0.3), k, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, Color(ink, 0.65 * e))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var bb := Rect2(q[0], Vector2.ZERO)
	for v in q:
		bb = bb.expand(v)
	_rects[kind] = bb


# Grandezza della scritta che entra nella lastra (calcolata come in _draw_lastra_cmd, a dx = 0).
func _lastra_fit(kind: String, f: Font) -> int:
	var q: Array = LASTRE[kind]
	var cs := Vector2(PW, PH) * CORNICE_SCALA
	var left: Vector2 = ((q[0] as Vector2) + (q[3] as Vector2)) * 0.5 * cs
	var right: Vector2 = ((q[1] as Vector2) + (q[2] as Vector2)) * 0.5 * cs
	var hgt: float = (((q[3] as Vector2) - (q[0] as Vector2)) * cs).length()
	var kw: float = 0.0 if Ui.is_touch() else Ui.body().get_string_size("4", HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x + 6.0
	if kind == "ult":
		kw = maxf(kw, Ui.body().get_string_size("100%", HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x + 6.0)
	var room: float = (right - left).length() - hgt * 0.82 - 10.0 - kw
	var sz: int = int(hgt * 0.6)
	while sz > HudLayers.MIN_TEXT and f.get_string_size(str(LASTRE_NOME[kind]), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > room:
		sz -= 1
	return sz


# Comando in lista (riferimento dell'autore): nastro storto scuro con icona, nome e tasto tondo a destra. Scelto: nastro
# del colore del personaggio, piu' alto e spostato in avanti, bordo bianco. ULTIMATE pronta: scritta gialla; in carica:
# barretta rosa sotto il nome e la percentuale nel tondo.
func _draw_riga_cmd(kind: String, it: Dictionary, dx: float, H: float, f: Font, e: float) -> void:
	var cs := Vector2(PW, PH) * CORNICE_SCALA
	var i: int = LISTA_ORDINE.find(kind)
	var ok: bool = bool(it.get("ok", false))
	var on: bool = picked == kind
	var hov: bool = _hov == kind and ok
	var hgt: float = LISTA_ALTO      # stessa altezza anche se scelto: non deve invadere i vicini
	var x0: float = dx + cs.x * (LISTA_X + 0.02 * i) - (14.0 if on else 0.0)
	var yc: float = H - LISTA_FONDO - hgt * 0.5 - LISTA_STACCO * float(LISTA_ORDINE.size() - 1 - i)
	var w: float = cs.x * 0.52 + (22.0 if on else 0.0)
	var sk: float = hgt * 0.42
	var q := PackedVector2Array([Vector2(x0 + sk, yc - hgt * 0.5 - 2.0), Vector2(x0 + w + sk, yc - hgt * 0.5 - 6.0), Vector2(x0 + w, yc + hgt * 0.5 - 4.0), Vector2(x0, yc + hgt * 0.5)])
	# zona di tocco: tutta la fascia del nastro fino a meta' del vuoto coi vicini, e fino al tasto tondo; mai sovrapposta
	var hz: float = LISTA_STACCO * 0.5
	_polys[kind] = PackedVector2Array([Vector2(x0 + sk - 6.0, yc - hz), Vector2(x0 + w + sk + 40.0, yc - hz), Vector2(x0 + w + 40.0, yc + hz), Vector2(x0 - 6.0, yc + hz)])
	var sdw := PackedVector2Array()
	for v in q:
		sdw.append(v + Vector2(5, 5))
	draw_colored_polygon(sdw, Color(INK, 0.8 * e))
	var fill: Color = Color(col, 0.97) if on else (Color(col.darkened(0.55), 0.9) if hov else Color(0.04, 0.02, 0.07, 0.92))
	draw_colored_polygon(q, Color(fill, fill.a * e))
	if on:
		draw_polyline(q + PackedVector2Array([q[0]]), Color(CREAM, e), 3.0, true)
	else:
		draw_line(q[3], q[2], Color(col.lightened(0.2), 0.9 * e), 2.0, true)       # filo del colore sotto il nastro
	var txt: Color = CREAM if ok else Color(GREY, 1.0)
	if kind == "ult" and ok and not on:
		txt = Color("#d58bff") if Settings.hud_foto else HOT        # foto: ULTIMATE viola
	var sz: int = _usz + (4 if on else 0)
	var rot: float = -0.06
	var ic: Vector2 = Vector2(x0 + sk * 0.5 + hgt * 0.5, yc - 1.0)
	CmdWheel.glyph(self, kind, ic + Vector2(2, 2), hgt * 0.34, Color(INK, e))
	CmdWheel.glyph(self, kind, ic, hgt * 0.34, Color(txt, e))
	var name: String = str(LISTA_NOME[kind])
	var room: float = w - hgt - 10.0
	while sz > HudLayers.MIN_TEXT and f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > room:
		sz -= 1
	var tp := Vector2(x0 + sk * 0.5 + hgt + 2.0, yc + sz * 0.34)
	draw_set_transform(tp, rot)
	draw_string_outline(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 7, Color(INK, e))
	draw_string(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(txt, e))
	if kind == "ult" and not ok:
		var pc: float = clampf(str(it.get("cost", "0")).to_float() / 100.0, 0.0, 1.0)
		var bw: float = f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		draw_rect(Rect2(0, 5, bw, 6), Color(INK, e))
		draw_rect(Rect2(1, 6, (bw - 2.0) * pc, 4), Color(Ui.PINK, e))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# tasto tondo a destra del nastro: numero su PC, percentuale dell'ULTIMATE in carica; sul telefono solo se c'e' la carica
	var k: String = "" if Ui.is_touch() else str(KEYS.get(kind, ""))
	if kind == "ult" and not ok:
		k = str(it.get("cost", ""))
	if k != "":
		var bc := Vector2(x0 + w + sk + 18.0, yc - 4.0)
		var br: float = 15.0 if k.length() <= 1 else 19.0
		draw_circle(bc + Vector2(2, 2), br + 2, Color(INK, e))
		draw_circle(bc, br + 1, Color(CREAM if ok else GREY, e))
		draw_circle(bc, br - 2, Color(INK, e))
		var fk: Font = f if k.length() <= 1 else Ui.body()
		var ksz: int = 18 if k.length() <= 1 else HudLayers.MIN_TEXT
		var ks: Vector2 = fk.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, ksz)
		draw_string(fk, bc + Vector2(-ks.x * 0.5, ksz * 0.36), k, HORIZONTAL_ALIGNMENT_LEFT, -1, ksz, Color(CREAM if ok else GREY, e))
	var bb := Rect2(q[0], Vector2.ZERO)
	for v in q:
		bb = bb.expand(v)
	_rects[kind] = bb


func _hit(p: Vector2) -> String:
	for k in _polys:
		if Geometry2D.is_point_in_polygon(p, _polys[k]):
			return k
	if not _polys.is_empty():
		return ""
	for k in _rects:
		if (_rects[k] as Rect2).has_point(p):
			return k
	return ""


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
	if FERMI.has(who_id):
		# fermo: solo l'entrata da sotto insieme alla lastra, poi immobile
		var e3: float = _ease(clampf((appear - 0.25) / 0.75, 0.0, 1.0))
		draw_set_transform(Vector2(0.0, (1.0 - e3) * 120.0), 0.0, Vector2.ONE)
		return
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
	var whip: float = exp(-5.5 * tw) * sin(9.0 * tw) if tw >= 0.0 and tw < 1.5 else 0.0    # molla smorzata, morbida: un'onda e si assesta
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
				0.8 * w * sin(t * 1.6 + v * 3.0 + u * 1.5) + 1.3 * tail * tail * sin(t * 2.2 + v * 5.0) - 4.0 * w * whip,
				-1.4 * w * br + 0.6 * w * sin(t * 1.3 + u * 4.0) - 1.8 * w * whip)
			pts.append(r.position + p * k + off)
			uvs.append(Vector2(u, v))
	_draw_grid(pts, uvs, _scarf, Color(1, 1, 1, e))


func _draw_head(r: Rect2, e: float, shift: Vector2 = Vector2.ZERO, mod: Color = Color.WHITE, big: bool = true) -> void:
	var d: Array = TESTA[who_id]
	var box: Rect2 = d[0]
	var piv: Vector2 = d[1]
	var face: Vector2 = d[2]
	var k: float = r.size.x / 1536.0
	var br: float = 0.5 + 0.5 * sin(t * 1.6)
	var tw: float = t - _whip_t0
	var whip: float = exp(-6.0 * tw) * sin(8.0 * tw) if tw >= 0.0 and tw < 1.5 else 0.0
	var tl: float = tw - 0.07                                          # i capelli arrivano un attimo dopo
	var hair_whip: float = exp(-5.0 * tl) * sin(8.0 * tl) if tl >= 0.0 and tl < 1.6 else 0.0
	# radianti. Correzione dell'autore (4/11/2026, «rendi il movimento piu' leggero»): meno di 1 grado anche nello scatto,
	# onde lente e senza rimbalzi
	var amp: float = 0.8 if big else 0.6
	var ang: float = amp * (0.006 * sin(t * 0.9) + 0.003 * br - 0.022 * whip)
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
				hw * amp * (1.2 * sin(t * 1.5 + v * 2.5 + u * 1.2) - 5.0 * hair_whip),
				hw * amp * (-1.2 * br + 0.8 * sin(t * 1.2 + u * 3.0)) - 0.8 * br)
			pts.append(r.position + q * k + off + shift)
			uvs.append(Vector2(u, v))
	_draw_grid(pts, uvs, _head, mod)


# Griglia (SC_NX+1)x(SC_NY+1) di punti gia' deformati -> triangoli con la texture, una sola chiamata
func _draw_grid(pts: PackedVector2Array, uvs: PackedVector2Array, tex: Texture2D, mod: Color) -> void:
	var idx := PackedInt32Array()
	for j in SC_NY:
		for i in SC_NX:
			var a: int = j * (SC_NX + 1) + i
			idx.append_array([a, a + 1, a + SC_NX + 1, a + 1, a + SC_NX + 2, a + SC_NX + 1])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts,
		PackedColorArray([mod]), uvs, PackedInt32Array(), PackedFloat32Array(), tex.get_rid())


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
	var br: float = (18.0 if Ui.is_touch() else 15.0) + (3.0 if on else 0.0)     # sul telefono il tasto tondo e' piu' grande
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
	var lnc: float = float(HudLayers.v("comandi.lastra_non_scelti"))
	if not on and lnc > 0.0:
		# HUD Combat 2.0: i comandi non scelti su una lastra d'inchiostro leggera, si leggono anche sopra il ritratto chiaro
		var sl2 := PackedVector2Array([Vector2(-10, -sz * 0.92), Vector2(tw + 14, -sz * 1.02), Vector2(tw + 6, sz * 0.22), Vector2(-16, sz * 0.3)])
		draw_colored_polygon(sl2, Color(INK, lnc * e))
	# ombra del colore sfalsata (lettering del riferimento) + contorno d'inchiostro spesso
	draw_set_transform(p + Vector2(4, 4).rotated(rot), rot, Vector2(1, 1))
	draw_string_outline(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 10, Color(col.darkened(0.2), 0.95 * e))
	draw_set_transform(p, rot)
	draw_string_outline(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 9, Color(INK, e))
	draw_string(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(fill, e))
	# ULTIMATE non pronta: la carica in piccolo sotto la scritta
	if kind == "ult" and not ok:
		if Settings.hud_party:
			# P1-B: la carica si legge (prima grigio su viola): barretta rosa e percentuale crema col contorno
			var pc: float = clampf(str(it.get("cost", "0")).to_float() / 100.0, 0.0, 1.0)
			draw_rect(Rect2(4, 8, 74, 9), Color(INK, e))
			draw_rect(Rect2(5, 9, 72 * pc, 7), Color(Ui.PINK, e))
			var usz: int = HudLayers.font_size("ultimate")      # L3: quieta finche' carica, piena quando e' pronta (la scritta grande)
			draw_string_outline(Ui.body(), Vector2(84, 19), str(it.get("cost", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, usz, 5, Color(INK, e))
			draw_string(Ui.body(), Vector2(84, 19), str(it.get("cost", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, usz, Color(HudLayers.tone("ultimate", CREAM, INK), e))
		else:
			draw_string(Ui.body(), Vector2(4, 18), str(it.get("cost", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, Color(GREY, e))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# tasto rotondo: numero della tastiera su PC, icona sul telefono
	draw_circle(bc + Vector2(2, 2), br + 3, Color(INK, e))
	draw_circle(bc, br + 2, Color(CREAM if ok else GREY, e))
	draw_circle(bc, br - 1, Color(INK if not on else col.darkened(0.3), e))
	if Ui.is_touch():
		CmdWheel.glyph(self, kind, bc, br * 0.8, Color(CREAM if ok else GREY, e))
	elif bool(HudLayers.v("comandi.numero_a_parte")):
		# HUD Combat 2.0: su pc l'icona come sul telefono (stesso significato) e il numero del tasto in un bollino accanto (L4)
		CmdWheel.glyph(self, kind, bc, br * 0.8, Color(CREAM if ok else GREY, e))
		var k2: String = str(KEYS.get(kind, ""))
		var ksz: int = HudLayers.font_size("numero_tasto")
		var bb: Vector2 = bc + Vector2(br * 0.78, br * 0.78)
		draw_circle(bb, 10.0, Color(INK, e))
		draw_arc(bb, 10.0, 0.0, TAU, 20, Color(GREY, e), 1.5, true)
		var kw: Vector2 = f.get_string_size(k2, HORIZONTAL_ALIGNMENT_LEFT, -1, ksz)
		draw_string(f, bb + Vector2(-kw.x * 0.5, ksz * 0.36), k2, HORIZONTAL_ALIGNMENT_LEFT, -1, ksz, Color(HudLayers.tone("numero_tasto", CREAM, INK), e))
	else:
		var k: String = str(KEYS.get(kind, ""))
		var ks: Vector2 = f.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(f, bc + Vector2(-ks.x * 0.5, 7), k, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(CREAM if ok else GREY, e))
	# zona del tocco: scritta + tasto, almeno 48 di altezza (i tasti del rombo sono vicini: le zone non si sovrappongono)
	var x0: float = minf(p.x, bc.x - br) - (12.0 if not right else 4.0)       # piu' largo dal lato della scritta, stretto verso il vicino
	var x1: float = maxf(p.x + tw, bc.x + br) + (12.0 if right else 4.0)
	var hh: float = 52.0
	_rects[kind] = Rect2(Vector2(x0, bc.y - hh * 0.5), Vector2(x1 - x0, hh))


var tip_rect: Rect2 = Rect2()      # dove sta la descrizione del comando scelto (battle3d ci fa salire sopra la riga di Echo)


func _draw_tip(it: Dictionary, dx: float, H: float, e: float) -> void:
	if it.is_empty():
		return
	var bf: Font = Ui.body()
	# IN BASSO AL CENTRO (autore, 7/11/2026): tra il ritratto di chi e' di turno e le card della squadra
	var left: float = dx + (PW * CORNICE_SCALA if _dietro != null else PW + 30.0) + 14.0
	for rk in _rects:      # mai sotto i nastri o il loro tasto tondo
		left = maxf(left, (_rects[rk] as Rect2).end.x + 44.0)
	var right: float = size.x - 22.0 - PortraitParty.cw() * 4.0 - 42.0 - 16.0
	var bw: float = clampf(right - left, 280.0, 440.0)
	var lines: Array = CmdWheel.wrap(bf, str(it.get("desc", "")).replace("\n", " · "), 16, bw - 30.0)
	if lines.size() > 3:
		lines = lines.slice(0, 3)
	var bh: float = 34.0 + 20.0 * lines.size()
	var r := Rect2(Vector2((left + right) * 0.5 - bw * 0.5, H - 18.0 - bh), Vector2(bw, bh))
	tip_rect = r
	var poly := CmdWheel.slant(r, 10.0)
	draw_colored_polygon(poly, Color(0.03, 0.02, 0.06, 0.88 * e))
	# L4 (HUD Combat 2.0): bordo quieto, titolo e righe a 16; il giallo del titolo e' semantico e resta
	draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(col.lightened(0.3), float(HudLayers.v("descrizione.bordo")) * e), 2.0)
	draw_string(Ui.display(), r.position + Vector2(16, 24), str(it.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 30.0, HudLayers.font_size("descrizione_titolo"), Color(HOT, e))
	var dcol: Color = HudLayers.tone("descrizione", CREAM)
	for i in lines.size():
		draw_string(bf, r.position + Vector2(16, 46 + 20 * i), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.font_size("descrizione"), Color(dcol, e))


func _has_point(p: Vector2) -> bool:
	return _hit(p) != ""


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var hk: String = _hit((ev as InputEventMouseMotion).position)
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
	var hit: String = _hit(p)
	if hit != "":
		accept_event()
		tapped.emit(hit)
