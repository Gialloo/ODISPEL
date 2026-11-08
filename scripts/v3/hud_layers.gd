class_name HudLayers
extends RefCounted

# GERARCHIA A TRE LIVELLI dell'HUD di battaglia (Review 01 del game director, 4/11/2026; regola scritta in
# docs/STILE_VISIVO.md, «HUD a tre livelli»). In meno di un secondo il giocatore deve sapere: chi agisce, cosa succede,
# qual e' la minaccia, cosa puo' fare. Il livello 3 (lo spettacolo) non deve mai impedire la lettura del livello 1.
#  1 PRIORITA'     vite della squadra e del nemico, chi e' di turno, comandi, prossima mossa del nemico (pericolo)
#  2 CONTESTO      DEBOLE A, equilibrio, ordine dei turni, COMBO, avvisi dell'arena e dei boss, consigli di Echo, reazioni
#  3 ATMOSFERA     REC e cornice della telecamera, cartellino CAM, chat della diretta di Rio, battute a fumetto, timbri,
#                  disturbi, fermo immagine, inquadrature firmate
# Mentre si SCEGLIE il livello 3 si fa da parte (chat e cartellino tacciono, le battute aspettano la mossa); durante le
# mosse, dove non c'e' niente da decidere, torna pieno. Lo spettacolo resta tutto: cambia solo il momento (regola 5 e 11).

const PRIORITA: int = 1
const CONTESTO: int = 2
const ATMOSFERA: int = 3

# Testo piu' piccolo ammesso per le informazioni dei livelli 1 e 2, in pixel della vista di base 1280x720 (su un telefono
# 2400x1080 diventa 24 px veri). Il livello 3 decorativo (orologio del REC, numeri dei tasti sulla tastiera) ne e' fuori.
const MIN_TEXT: int = 16
# La prossima mossa del nemico e' il pericolo immediato: livello 1, un po' piu' grande del minimo.
const THREAT_TEXT: int = 18

# Una battuta arrivata mentre si sceglie aspetta la mossa al massimo questo tempo, poi si lascia cadere (sarebbe vecchia).
const QUIP_WAIT_MAX: float = 6.0

# Ogni elemento dell'HUD di battaglia col suo livello: si legge qui, e il test controlla che il livello 3 taccia mentre si sceglie.
const ELEMENTI: Dictionary = {
	"vite_squadra": PRIORITA, "chi_agisce": PRIORITA, "comandi": PRIORITA, "vita_nemico": PRIORITA, "prossima_mossa": PRIORITA,
	"debole_a": CONTESTO, "equilibrio": CONTESTO, "ordine_turni": CONTESTO, "combo": CONTESTO, "avvisi": CONTESTO,
	"echo": CONTESTO, "reazioni": CONTESTO,
	"rec": ATMOSFERA, "cartellino_cam": ATMOSFERA, "chat_diretta": ATMOSFERA, "battute": ATMOSFERA, "timbri": ATMOSFERA,
	"disturbi": ATMOSFERA, "fermo_immagine": ATMOSFERA, "inquadrature": ATMOSFERA,
}


static func level(id: String) -> int:
	return int(ELEMENTI.get(id, ATMOSFERA))


# =====================================================================================================================
# HUD COMBAT 2.0 · SECONDO ASSE: QUATTRO LIVELLI INFORMATIVI (decisioni dell'autore del 7/11/2026; piano in
# odispel/v3/hud_gerarchia/fase2/PIANO_TECNICO_DEFINITIVO.md). I tre livelli qui sopra dicono QUANDO si vede; questi dicono
# QUANTO PESA. Ogni elemento ha tre proprieta' distinte: INFO (importanza), RUOLO (misura del testo), INTENSITA' (prominenza).
# Importanza e misura non coincidono: la vita del nemico e' L1 ma usa NUMERO_L1, non TITOLO.
#  L1 FONDAMENTALE  si vede subito: vita e nome del nemico, bersaglio, prossima mossa, chi agisce, comandi
#  L2 STRATEGICA    subito dopo: debolezze, equilibrio, vite ed EN della squadra, ordine dei turni
#  L3 SUPPORTO      ritmo, ardore, carica dell'Ultimate, mirini quando il colpo e' su tutti
#  L4 CONTESTO      descrizione, obiettivo, numeri dei tasti, tasti rapidi
# Settings.hud_gerarchia e' un interruttore di sviluppo (non compare nelle Impostazioni, non si salva): spento, ogni
# valore torna quello della 0.63.0.
# =====================================================================================================================
const DECORAZIONE: int = 0
const L1: int = 1
const L2: int = 2
const L3: int = 3
const L4: int = 4

# Cinque ruoli tipografici (vista di base 1280x720). COMANDO a 30 e' un'eccezione ufficiale: le zone di tocco dei comandi
# 0.58 sono calcolate su quella misura. DISEGNO = misura che fa parte del disegno (nome sul ritratto, 40, decisione del
# 7/11/2026). GRAFICO = mirini, barre, cornici: misure in pixel, non testo.
const RUOLO: Dictionary = {"TITOLO": 28, "COMANDO": 30, "NUMERO_L1": 22, "NUMERO_L2": 18, "TESTO": 16, "DISEGNO": 40, "GRAFICO": 0}

# Intensita': quanto il testo si avvicina alla sua lastra (mai trasparenza, mai sulla tinta dei colori semantici).
const PIENA: String = "PIENA"
const STRATEGICA: String = "STRATEGICA"
const QUIETA: String = "QUIETA"
const MISCELA: Dictionary = {"PIENA": 0.0, "STRATEGICA": 0.2, "QUIETA": 0.4}
const CONTRASTO_TESTO: float = 4.5       # minimo dopo l'intensita' (testo sulla lastra o sul suo contorno)
const CONTRASTO_GRAFICO: float = 3.0     # barre e icone

const LASTRA: Color = Color(0.05, 0.03, 0.08)     # fondo delle lastre scure dell'HUD
const INK: Color = Color("#120a1c")               # contorno dei testi (Ui.INK)

# id -> [info, ruolo, intensita', misura della 0.63 (0 = grafico), semantico (colore che significa qualcosa: non si tocca),
#        contorno d'inchiostro (il contrasto si misura sul contorno)]
const ELEMENTI_INFO: Dictionary = {
	# zona A, pannello nemico
	"nome_nemico": [L1, "TITOLO", PIENA, 22, false, false],
	"vita_nemico": [L1, "NUMERO_L1", PIENA, 16, false, true],
	"bersaglio": [L1, "GRAFICO", PIENA, 0, true, false],
	"prossima_mossa": [L1, "TITOLO", PIENA, 24, false, true],
	"prossima_mossa_riga": [L1, "TESTO", PIENA, 16, false, true],
	"debole_a": [L2, "TESTO", STRATEGICA, 16, false, false],
	"debole_a_colore": [L2, "TESTO", PIENA, 16, true, false],
	"equilibrio": [L2, "NUMERO_L2", STRATEGICA, 16, false, true],
	# zona B, pannello del personaggio
	"comandi": [L1, "COMANDO", PIENA, 30, false, true],
	"comandi_non_scelti": [L1, "COMANDO", STRATEGICA, 30, false, true],
	"numero_tasto": [L4, "TESTO", QUIETA, 18, false, false],
	"ultimate": [L3, "TESTO", QUIETA, 16, false, true],
	"chi_agisce": [L1, "DISEGNO", PIENA, 40, true, true],
	"ritratto": [DECORAZIONE, "GRAFICO", PIENA, 0, true, false],
	"descrizione_titolo": [L4, "TESTO", QUIETA, 17, true, false],
	"descrizione": [L4, "TESTO", QUIETA, 16, false, false],
	"obiettivo": [L4, "TESTO", QUIETA, 16, false, false],
	# zona C, squadra (le misure si confermano col mockup della squadra)
	"vite_squadra": [L2, "NUMERO_L2", STRATEGICA, 20, false, true],
	"en_squadra": [L2, "NUMERO_L2", STRATEGICA, 16, true, true],
	"personaggio_attivo": [L1, "GRAFICO", PIENA, 0, true, false],
	"mirini_squadra": [L3, "GRAFICO", QUIETA, 0, true, false],
	"ordine_etichetta": [L2, "NUMERO_L2", STRATEGICA, 24, false, true],
	"ordine_turno": [L2, "TESTO", STRATEGICA, 14, false, true],
	"tasti_rapidi": [L4, "TESTO", QUIETA, 14, false, false],
	"ritmo": [L3, "TESTO", QUIETA, 16, true, true],
	"ardore": [L3, "TESTO", QUIETA, 16, true, true],
}

# Valori non tipografici: [2.0, 0.63]. Si leggono con v(); spento l'interruttore torna la 0.63.
const VAL: Dictionary = {
	# zona A
	"vita_nemico.barra": [30.0, 22.0],
	"vita_nemico.carattere_titoli": [true, false],
	"vita_nemico.contorno": [5, 4],
	"vita_nemico.suffisso": [" HP", ""],
	"equilibrio.colore": [Color("#857a9e"), Color("#f2f0ea")],    # a riposo; vicino alla rottura giallo (stato critico)
	"prossima_mossa.stacco": [6.0, 0.0],
	"prossima_mossa.bordo": [3.5, 2.5],
	"prossima_mossa.fondo": [Color(0.16, 0.02, 0.07, 0.95), Color(0.05, 0.03, 0.08, 0.93)],
	"prossima_mossa.alone": [0.22, 0.0],
	"nemico.compatto_con_tendina": [true, false],   # decisione 1 (7/11/2026): con la tendina il pannello si stringe, non sparisce
	"ordine.margine": [8.0, 0.0],                   # aria fra il pannello del nemico e la colonna ORDINE
	# zona B
	"ritratto.luce": [0.86, 1.0],
	"comandi.lastra_non_scelti": [0.55, 0.0],
	"comandi.numero_a_parte": [true, false],
	"descrizione.bordo": [0.4, 1.0],
	# zona C
	"squadra.barra_vita": [11.0, 7.0],
	"squadra.barre_uguali": [true, false],
	"squadra.mirino_su_tutti": [10.0, 0.0],
	"ordine.etichetta_gialla": [false, true],
	"ordine.volto_nemico": [true, false],
	"echo.sopra_descrizione": [true, false],        # la riga di Echo sale sopra la descrizione del comando invece di coprirla           # decisione 3 (7/11/2026): il volto del nemico al posto del nome rimpicciolito
}


static func info(id: String) -> int:
	return int((ELEMENTI_INFO[id] as Array)[0])


static func ruolo(id: String) -> String:
	return str((ELEMENTI_INFO[id] as Array)[1])


# Misura del testo di un elemento: dal ruolo con la gerarchia accesa, quella della 0.63 con l'interruttore spento.
static func font_size(id: String) -> int:
	var e: Array = ELEMENTI_INFO[id]
	if not Settings.hud_gerarchia:
		return int(e[3])
	return int(RUOLO[str(e[1])])


# Intensita' di un elemento; lo stato critico (vita bassa, rottura vicina, colpo forte) la porta sempre a PIENA.
static func intensity(id: String, critico: bool = false) -> String:
	if critico or not Settings.hud_gerarchia:
		return PIENA
	return str((ELEMENTI_INFO[id] as Array)[2])


# Colore del testo dopo l'intensita': si avvicina alla lastra, ma i colori semantici restano come sono.
static func tone(id: String, base: Color, lastra: Color = LASTRA, critico: bool = false) -> Color:
	var e: Array = ELEMENTI_INFO[id]
	if bool(e[4]):
		return base
	var k: float = float(MISCELA[intensity(id, critico)])
	return Color(base.lerp(lastra, k), base.a)


static func v(key: String) -> Variant:
	var p: Array = VAL[key]
	return p[0] if Settings.hud_gerarchia else p[1]


# Contrasto come nelle linee guida WCAG (1 = nessuno, 21 = bianco su nero).
static func contrasto(a: Color, b: Color) -> float:
	var la: float = _lum(a)
	var lb: float = _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _lum(c: Color) -> float:
	var ch: Array = []
	for x in [c.r, c.g, c.b]:
		ch.append(x / 12.92 if x <= 0.03928 else pow((x + 0.055) / 1.055, 2.4))
	return 0.2126 * float(ch[0]) + 0.7152 * float(ch[1]) + 0.0722 * float(ch[2])


# Spazio che il pannello del nemico lascia alla colonna ORDINE. La 0.63 ne riservava 120, ma la colonna ne occupa 142
# (PortraitParty.order_width): da li' il contatto a 16:10 e 4:3. Spento resta 120, come nella 0.63.
static func riserva_ordine() -> float:
	return PortraitParty.order_width() + float(v("ordine.margine")) if Settings.hud_gerarchia else 120.0
