FILE battle_content.gd - PARTE 3 DI 5
Percorso: scripts/battle/battle_content.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
# Boss. Il ciclo di mosse e' annunciato un round prima.
# target "one": un giocatore scelto a caso e annunciato; "weakest": il piu' ferito
# (annunciato); "all": tutti i giocatori.
# Opzioni: "status" (sui bersagli), "self_shield" (scudo al boss, frazione dei PV
# massimi), "drain" (il boss recupera questa frazione del danno inflitto).
const BOSS_MOVES: Dictionary = {
	"scarica": {"name": "Scarica", "target": "one", "mult": 1.6},
	"raffica": {"name": "Raffica", "target": "all", "mult": 0.7},
	"scossa": {"name": "Scossa", "target": "one", "mult": 0.9, "status": {"bleed": 3}},
	"sovraccarico": {"name": "Sovraccarico", "target": "all", "mult": 1.2},
	"lampeggio": {"name": "Lampeggio", "target": "all", "mult": 0.55, "status": {"mark": 2}},
	"rosso": {"name": "Rosso", "target": "one", "mult": 1.9},
	"giallo": {"name": "Giallo", "target": "weakest", "mult": 0.7, "self_shield": 0.06},
	"verde": {"name": "Verde", "target": "all", "mult": 0.95},
	"gorgo": {"name": "Gorgo", "target": "one", "mult": 1.7},
	"risucchio": {"name": "Risucchio", "target": "weakest", "mult": 0.9, "drain": 0.6},
	"alluvione": {"name": "Alluvione", "target": "all", "mult": 0.6, "status": {"bleed": 3}},
	"chiusura": {"name": "Chiusura", "target": "all", "mult": 0.45, "self_shield": 0.05},
	"squillo": {"name": "Squillo", "target": "all", "mult": 0.5, "status": {"mark": 2}},
	"chiamata": {"name": "Chiamata", "target": "one", "mult": 1.8},
	"interferenza": {"name": "Interferenza", "target": "all", "mult": 0.85, "status": {"bleed": 3}, "self_shield": 0.04},
	"linea_occupata": {"name": "Linea occupata", "target": "weakest", "mult": 0.8, "drain": 0.5},
	"porte": {"name": "Porte che si chiudono", "target": "one", "mult": 1.9},
	"caduta_libera": {"name": "Caduta libera", "target": "all", "mult": 0.8, "status": {"bleed": 3}},
	"piano_zero": {"name": "Piano zero", "target": "weakest", "mult": 0.9, "drain": 0.5},
	"manutenzione": {"name": "Manutenzione", "target": "all", "mult": 0.5, "status": {"mark": 2}, "self_shield": 0.08},
	"posa": {"name": "Posa", "target": "one", "mult": 1.7},
	"vetrina": {"name": "Vetrina", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"copia": {"name": "Copia", "target": "weakest", "mult": 0.9, "drain": 0.6},
	"sfilata": {"name": "Sfilata", "target": "all", "mult": 1.0},
	"rintocco": {"name": "Rintocco", "target": "one", "mult": 2.0},
	"lancette": {"name": "Lancette", "target": "all", "mult": 0.9, "status": {"bleed": 3}},
	"ora_zero": {"name": "Ora zero", "target": "all", "mult": 0.65, "status": {"mark": 2}, "self_shield": 0.06},
	"tempo_perso": {"name": "Tempo perso", "target": "weakest", "mult": 1.0, "drain": 0.7},
	"riflesso": {"name": "Riflesso", "target": "one", "mult": 2.1},
	"frantumi": {"name": "Frantumi", "target": "all", "mult": 0.95, "status": {"bleed": 3}},
	"doppio": {"name": "Doppio", "target": "weakest", "mult": 0.85, "drain": 0.5, "self_shield": 0.05},
	"furia": {"name": "Furia", "target": "all", "mult": 0.7, "status": {"bleed": 2}},
	"ultimo_respiro": {"name": "Ultimo respiro", "target": "all", "mult": 0.9, "status": {"mark": 3}, "self_shield": 0.04},
	"simmetria": {"name": "Simmetria", "target": "all", "mult": 0.7, "status": {"mark": 3}, "self_shield": 0.06},
	"ululato": {"name": "Ululato", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"allarme": {"name": "Allarme rosso", "target": "one", "mult": 1.9},
	"stridio": {"name": "Stridio", "target": "weakest", "mult": 0.9, "drain": 0.5},
	"coprifuoco": {"name": "Coprifuoco", "target": "all", "mult": 0.5, "status": {"bleed": 2}, "self_shield": 0.06},
	"abbaglio": {"name": "Abbaglio", "target": "one", "mult": 1.9},
	"buio": {"name": "Buio improvviso", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"falena": {"name": "Falena", "target": "weakest", "mult": 0.9, "drain": 0.6},
	"cono_di_luce": {"name": "Cono di luce", "target": "all", "mult": 0.8, "status": {"bleed": 3}},
	"prelievo": {"name": "Prelievo", "target": "weakest", "mult": 1.0, "drain": 0.7},
	"commissione": {"name": "Commissione", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"saldo_negativo": {"name": "Saldo negativo", "target": "one", "mult": 2.0},
	"blocco_carta": {"name": "Blocco carta", "target": "all", "mult": 0.5, "status": {"bleed": 2}, "self_shield": 0.08},
	"gradino": {"name": "Gradino mancante", "target": "one", "mult": 2.0},
	"risalita": {"name": "Risalita", "target": "all", "mult": 0.75, "status": {"bleed": 3}},
	"senso_inverso": {"name": "Senso inverso", "target": "weakest", "mult": 0.9, "drain": 0.5},
	"arresto": {"name": "Arresto di emergenza", "target": "all", "mult": 0.5, "status": {"mark": 2}, "self_shield": 0.06},
	"fruscio": {"name": "Fruscio", "target": "all", "mult": 0.55, "status": {"mark": 2}},
	"sintonia": {"name": "Sintonia forzata", "target": "one", "mult": 2.0},
	"disturbo": {"name": "Disturbo", "target": "all", "mult": 0.85, "status": {"bleed": 3}, "self_shield": 0.04},
	"onda_lunga": {"name": "Onda lunga", "target": "weakest", "mult": 1.0, "drain": 0.6},
	"binario": {"name": "Binario morto", "target": "one", "mult": 2.1},
	"ultima_corsa": {"name": "Ultima corsa", "target": "all", "mult": 0.9, "status": {"bleed": 3}},
	"fermata": {"name": "Fermata richiesta", "target": "all", "mult": 0.6, "status": {"mark": 2}, "self_shield": 0.06},
	"capolinea": {"name": "Capolinea", "target": "weakest", "mult": 1.0, "drain": 0.6},
	"serratura": {"name": "Serratura", "target": "one", "mult": 2.1},
	"combinazione": {"name": "Combinazione", "target": "all", "mult": 0.65, "status": {"mark": 3}},
	"blindatura": {"name": "Blindatura", "target": "all", "mult": 0.45, "self_shield": 0.1},
	"furto": {"name": "Furto", "target": "weakest", "mult": 0.95, "drain": 0.7},
	"fascio": {"name": "Fascio", "target": "one", "mult": 2.2},
	"nebbia": {"name": "Nebbia", "target": "all", "mult": 0.7, "status": {"mark": 3}},
	"naufragio": {"name": "Naufragio", "target": "all", "mult": 1.0, "status": {"bleed": 3}},
	"marea_nera": {"name": "Marea nera", "target": "weakest", "mult": 1.0, "drain": 0.6, "self_shield": 0.05},
	"cancellazione": {"name": "Cancellazione", "target": "one", "mult": 2.3},
	"protocollo_nero": {"name": "Protocollo nero", "target": "all", "mult": 0.75, "status": {"mark": 3}},
	"fascicolo": {"name": "Fascicolo", "target": "all", "mult": 1.0, "status": {"bleed": 3}},
	"archiviazione": {"name": "Archiviazione", "target": "weakest", "mult": 1.05, "drain": 0.7, "self_shield": 0.06},
	"oscuramento": {"name": "Oscuramento", "target": "all", "mult": 0.7, "status": {"mark": 3}, "self_shield": 0.06},
	"corona": {"name": "Corona", "target": "one", "mult": 2.4},
	"penombra": {"name": "Penombra", "target": "weakest", "mult": 1.05, "drain": 0.7},
	"ora_nera": {"name": "Ora nera", "target": "all", "mult": 1.1, "status": {"bleed": 3}},
}

# Livelli di difficolta': moltiplicano PV e ATK del boss, aggiungono difesa e premi.
const TIERS: Array = [
	{"id": "normale", "name": "NORMALE", "hp": 1.0, "atk": 1.0, "def": 0, "reward": 1.0},
	{"id": "difficile", "name": "DIFFICILE", "hp": 1.5, "atk": 1.25, "def": 8, "reward": 2.0},
	{"id": "incubo", "name": "INCUBO", "hp": 2.1, "atk": 1.55, "def": 15, "reward": 3.2},
	# ABISSO: pensato per squadre al massimo (livello 50, rank 5, pezzi leggendari al massimo).
	{"id": "abisso", "name": "ABISSO", "hp": 36.0, "atk": 23.0, "def": 70, "reward": 5.0, "rec_level": 50, "flatten": 1.0},
]

# Ordine di sblocco: si apre il boss successivo battendo il precedente (almeno a NORMALE).
const BOSS_ORDER: Array = ["distributore", "semaforo", "tombino", "cabina", "ascensore", "manichino", "orologio", "specchio",
	"sirena", "lampione", "bancomat", "scala", "radio", "metro", "cassaforte", "faro", "registro", "eclissi"]
```
