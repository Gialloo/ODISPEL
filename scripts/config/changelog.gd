class_name Changelog
extends RefCounted

# Novita' di ogni versione: si mostrano una sola volta, la prima volta che si apre il gioco dopo un aggiornamento.
# Aggiungi una voce IN CIMA a ogni versione nuova (testi brevi, in italiano semplice).

const ENTRIES: Array = [
	{"v": "0.24.16", "items": [
		"Boss: ora hanno FASI (a meta' e a un quarto dei PV) e una barra EQUILIBRIO: a zero il boss e' stordito e salta la mossa.",
		"Le mosse pesanti sono CARICHE annunciate; se la mossa e' letale per qualcuno lo vedi subito.",
		"Sinergie (COPERTURA, TRACCIA), RITMO, ADATTAMENTO, ARDORE, ULTIMA VOLONTA' e la nuova mossa SACRIFICIO.",
		"Suggerimenti prima di scegliere, resoconto a fine battaglia, rallentatore sui momenti decisivi.",
		"STAGIONE 2 con Dafne: 10 nuovi capitoli e 10 nuovi boss fino a INCUBO.",
		"Combo modulari: ogni mossa ha dei tag e le combo (COPERTURA, TRACCIA, DETONAZIONE, FRATTURA, ASSEDIO, RAFFICA) si attivano tra compagni, con effetti piu' spettacolari a ogni combo in piu'.",
		"Nuovi obiettivi: rotture, sinergie, vittoria senza K.O.",
	]},
	{"v": "0.24.15", "items": [
		"Home: il pannello squadra ora si apre col tasto TEAM, e il consiglio in basso cambia da solo.",
		"Collezione: filtri per rarita', fazione, livello e colore.",
		"PvP: la schermata ha lo stesso stile della battaglia contro il boss.",
		"Multiplayer: collegamento piu' affidabile tra reti diverse e meno dati consumati.",
		"Profilo: nuovo pannello STATISTICHE.",
		"Obiettivi giornalieri: nuove sfide (boss diversi, vittoria a INCUBO).",
		"Dafne ha finalmente il suo aspetto: ritratti, figura in battaglia, illustrazione e ultimate.",
		"Le monete ora si chiamano CREDITI.",
		"STAGIONE 2: Dafne si unisce alla squadra CAM. 10 nuovi capitoli, 10 nuovi bersagli (Sirena, Lampione, Bancomat, Scala mobile, Radio, Metro, Cassaforte, Faro, Registro, Eclissi), tutti fino a INCUBO.",
		"Battaglia: il boss cambia schema a meta' e a un quarto dei PV (nuove mosse, scudo, e la tua squadra riceve ULTIMATE).",
		"Nuova barra EQUILIBRIO sotto i PV del boss: a zero il boss e' STORDITO e salta la mossa annunciata. Marcare prepara, colpire col colore giusto rompe.",
		"Sinergie tra compagni (COPERTURA e TRACCIA), RITMO per chi cambia mossa, ULTIMA VOLONTA' a 1 PV, rallentatore sui momenti decisivi, resoconto a fine battaglia.",
		"Costi con le icone di crediti, nuclei e leghe sui pulsanti. Premi epici e leggendari con bordo viola o giallo.",
	]},
]


static func latest() -> Dictionary:
	return ENTRIES[0] if not ENTRIES.is_empty() else {}


# La voce da mostrare per questa versione, o {} se non c'e' niente di nuovo da dire.
static func entry_for(version: String) -> Dictionary:
	for e in ENTRIES:
		if str(e["v"]) == version:
			return e
	return {}
