class_name Banter
extends RefCounted

# Battute dei personaggi durante lo scontro: una riga ogni tanto, in alto a destra, col loro volto.
# Il tono dipende dal colore (la strategia) del personaggio; nessuna battuta e' obbligatoria da leggere.

const LINES: Dictionary = {
	"rosso": {
		"start": ["Si va dritti al punto!", "Finiamola in fretta."],
		"crit": ["Preso in pieno!", "Questo e' un colpo vero!"],
		"low_hp": ["Non mi fermo ora...", "Ancora in piedi!"],
		"ult": ["Tutto quello che ho!", "Prendi questo!"],
		"enrage": ["Si arrabbia? Meglio!", "Ora fa sul serio!"],
		"ko": ["Reggete voi...", "Ci penso io, andate!"],
	},
	"giallo": {
		"start": ["Restate vicini, vi copro.", "Respirate. Siamo pronti."],
		"crit": ["Il momento giusto!", "Ha funzionato!"],
		"low_hp": ["Resisto ancora un po'.", "Non perdete la calma."],
		"ult": ["Sentite questa energia!", "Insieme ce la facciamo!"],
		"enrage": ["Attenti, e' cambiato!", "Stringiamoci!"],
		"ko": ["Non e' finita, rialzatevi!", "Ti riporto in piedi!"],
	},
	"viola": {
		"start": ["Ho gia' notato il suo schema.", "Studiamolo, poi colpiamo."],
		"crit": ["Calcolato.", "Esattamente dove previsto."],
		"low_hp": ["Il margine si riduce...", "Devo ricalcolare."],
		"ult": ["Tutto secondo il piano.", "Questo era scritto."],
		"enrage": ["Schema nuovo. Interessante.", "Cambia ritmo, state attenti."],
		"ko": ["Variabile imprevista...", "Rifaccio i conti, tenete duro."],
	},
	"verde": {
		"start": ["Mirate ai punti deboli.", "Occhi aperti, tutti."],
		"crit": ["Centro!", "Un colpo, un bersaglio."],
		"low_hp": ["Ancora un respiro...", "Un colpo mi basta."],
		"ult": ["Fermo li'!", "Questo non lo schivi!"],
		"enrage": ["Si scopre: colpiamolo!", "Ora e' piu' esposto!"],
		"ko": ["Coprite il buco, arrivo!", "Resistete, torno subito."],
	},
	"blu": {
		"start": ["Si parte prima di lui!", "Veloci, non fermatevi."],
		"crit": ["Troppo lento!", "Non mi hai nemmeno visto!"],
		"low_hp": ["Ancora un giro!", "Mi serve solo un attimo."],
		"ult": ["Piu' veloce della luce!", "Non seguirmi, non puoi!"],
		"enrage": ["Ha accelerato, accelero!", "Allora corriamo di piu'!"],
		"ko": ["Torno in un lampo!", "Tenete il ritmo!"],
	},
}

const EXPRESSIONS: Dictionary = {
	"start": "neutral", "crit": "happy", "low_hp": "sad", "ult": "angry", "enrage": "surprised", "ko": "sad",
}


# Una battuta per (tipo, colore): la scelta e' stabile per lo stesso salt (cosi' non cambia a ogni frame).
static func line(kind: String, color: String, salt: int = 0) -> String:
	var table: Dictionary = LINES.get(color, LINES["rosso"])
	var options: Array = table.get(kind, [])
	if options.is_empty():
		return ""
	return str(options[absi(salt) % options.size()])


static func expression_for(kind: String) -> String:
	return str(EXPRESSIONS.get(kind, "neutral"))
