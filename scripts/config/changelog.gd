class_name Changelog
extends RefCounted

# Novita' di ogni versione: si mostrano una sola volta, la prima volta che si apre il gioco dopo un aggiornamento.
# Aggiungi una voce IN CIMA a ogni versione nuova (testi brevi, in italiano semplice).

const ENTRIES: Array = [
	{"v": "0.24.15", "items": [
		"Home: il pannello squadra ora si apre col tasto TEAM, e il consiglio in basso cambia da solo.",
		"Collezione: filtri per rarita', fazione, livello e colore.",
		"PvP: la schermata ha lo stesso stile della battaglia contro il boss.",
		"Multiplayer: collegamento piu' affidabile tra reti diverse e meno dati consumati.",
		"Profilo: nuovo pannello STATISTICHE.",
		"Obiettivi giornalieri: nuove sfide (boss diversi, vittoria a INCUBO).",
		"Le monete ora si chiamano GOLD.",
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
