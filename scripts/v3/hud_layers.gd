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
