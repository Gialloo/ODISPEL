class_name Tutorials
extends RefCounted

# TUTORIAL: ogni meccanica del gioco spiegata in poche pagine, sempre consultabile dall'hub.
# Finire un tutorial (arrivare all'ultima pagina) la prima volta da' un premio fisso.
# Stato nel salvataggio: roster["tutorials"] = {"done": {id: true}}
# I testi sulle regole arrivano da Lore.glossary() e dalle costanti: non restano mai indietro.

const REWARD_COINS: int = 300
const REWARD_NUCLEO: int = 2
const REWARD_LEGA: int = 2


static func _l(text: String, color: Color = BattleTheme.WH) -> Dictionary:
	return {"text": text, "color": color}


# Spiegazione di un termine del glossario (dal codice).
static func _g(term: String) -> Dictionary:
	for e in Lore.glossary():
		if str(e[0]) == term:
			return _l("%s: %s" % [term, str(e[1])])
	return _l(term)


static func _h(text: String) -> Dictionary:
	return _l(text, BattleTheme.GOLD)


static func _tip(text: String) -> Dictionary:
	return _l(text, BattleTheme.CY_DIM)


static var _list: Array = []


# [{id, title, icon, pages: [{title, lines}]}]
static func all() -> Array:
	if not _list.is_empty():
		return _list
	_list = [
		{"id": "basi", "title": "LE BASI DEL COMBATTIMENTO", "icon": "sword", "pages": [
			{"title": "TURNI SIMULTANEI", "lines": [
				_h("Tutti scelgono insieme"),
				_l("Ogni round scegli UN ordine per l'operatore in campo: Attacco, Guardia, una skill o l'ultimate. Poi tutti gli ordini vengono eseguiti insieme."),
				_l("In alto c'e' il tempo per scegliere: se scade, il tuo operatore attacca da solo. Non conta essere veloci a decidere, conta decidere bene."),
				_tip("Nessun bonus per chi sceglie prima: leggi con calma l'allarme del boss."),
			]},
			{"title": "CHI AGISCE PER PRIMO", "lines": [
				_l("L'ordine e' fisso e visibile nel pannello ORDINE DEL TURNO: prima la PRIORITA' della mossa (Guardia e protezioni vanno prima), poi la VELOCITA', poi l'ordine dei giocatori."),
				_l("Il boss agisce nel suo turno, col risultato di quello che e' successo prima: se lo hai stordito, salta la mossa."),
				_g("CAMBIO"),
			]},
			{"title": "GUARDIA E ATTACCO", "lines": [
				_l("ATTACCO: colpo base, gratuito."),
				_g("GUARDIA"),
				_g("SCUDO"),
				_g("PROVOCAZIONE"),
			]},
		]},
		{"id": "risorse", "title": "ENERGIA, MUNIZIONI, ULTIMATE", "icon": "bolt", "pages": [
			{"title": "ENERGIA E SKILL", "lines": [_g("ENERGIA"), _l("Le skill costano energia: ogni skill mostra il suo costo. Se non ne hai abbastanza non puoi sceglierla."), _tip("Chi sta in panchina recupera piu' energia: ruotare gli operatori conviene.")]},
			{"title": "ULTIMATE", "lines": [_g("ULTIMATE"), _g("ARDORE"), _g("ULTIMA VOLONTA'")]},
			{"title": "MUNIZIONI", "lines": [_g("MUNIZIONI"), _g("CONTRATTACCO"), _g("PERFORA")]},
		]},
		{"id": "colori", "title": "COLORI E VANTAGGI", "icon": "target", "pages": [
			{"title": "IL TRIANGOLO DEI COLORI", "lines": [_g("VANTAGGIO DI COLORE"), _l("Il colore del boss e' sempre visibile. Scegli chi mandare in campo in base a quel colore.", BattleTheme.WH), _tip("Il colore giusto serve anche per ROTTURA: fa consumare piu' equilibrio al boss.")]},
			{"title": "COLORE = STRATEGIA", "lines": [_g("COLORE = STRATEGIA"), _g("CRITICO")]},
		]},
		{"id": "boss", "title": "IL BOSS: ALLARME E CARICHE", "icon": "taunt", "pages": [
			{"title": "ALLARME", "lines": [_g("ALLARME"), _l("Se la mossa e' LETALE per qualcuno lo vedi in rosso (\"LETALE PER ...\"): proteggilo, scambialo o fermala."), _g("FURIA DEL BOSS")]},
			{"title": "CARICHE", "lines": [_g("CARICA"), _tip("Una CARICA e' una mossa molto pesante o che colpisce tutti: e' il momento di reagire.")]},
			{"title": "FASI", "lines": [_g("FASI DEL BOSS"), _g("ADATTAMENTO"), _g("RITMO")]},
		]},
		{"id": "rottura", "title": "EQUILIBRIO E ROTTURA", "icon": "burst", "pages": [
			{"title": "ROTTURA", "lines": [_g("ROTTURA"), _g("MARCHIO"), _tip("Marcare prepara, colpire rompe: una squadra che si coordina stordisce il boss al momento giusto.")]},
		]},
		{"id": "combo", "title": "COMBO E SINERGIE", "icon": "bullet", "pages": [
			{"title": "COMBO TRA COMPAGNI", "lines": [_g("COMBO"), _tip("Prima di scegliere guarda i suggerimenti sotto l'allarme: ti dicono quali combo sono gia' pronte.")]},
			{"title": "LEGAME", "lines": [_l("Due compagni che agiscono di fila formano un LEGAME: ogni anello da' piu' danno. Se la catena si spezza, riparte da zero."), _g("SACRIFICIO"), _g("SANGUINAMENTO")]},
		]},
		{"id": "reazioni", "title": "RISERVA E REAZIONI", "icon": "shield", "pages": [
			{"title": "RISERVA DI SQUADRA", "lines": [_g("RISERVA E REAZIONI"), _tip("La Riserva e' di TUTTI: mettetevi d'accordo su chi reagisce, o la finite insieme.")]},
			{"title": "QUALE REAZIONE?", "lines": [
				_l("SCHIVATA (1): eviti del tutto la carica. Ottima se il bersaglio sei tu."),
				_l("INTERCETTAZIONE (2): prendi tu la carica al posto di un compagno, con danno ridotto. Non vale se il bersaglio sei tu, ne' contro attacchi su tutti."),
				_l("INTERRUZIONE (2): togli equilibrio al boss; se si rompe la carica salta. Una sola a round."),
				_tip("Se non reagisci entro il tempo, nessuna reazione. Le reazioni compaiono solo contro una CARICA."),
			]},
		]},
		{"id": "operatori", "title": "OPERATORI E CLASSI", "icon": "striker", "pages": [
			{"title": "CLASSI E FAZIONI", "lines": [_l("STRIKER colpisce forte, VANGUARD regge i colpi, WARDEN cura e protegge."), _g("FAZIONE"), _g("AURA"), _g("STILE")]},
			{"title": "PASSIVE E ABILITA' UNICHE", "lines": [_g("PASSIVA E ABILITA' UNICHE"), _g("LIVELLO E RANK")]},
		]},
		{"id": "reclutamento", "title": "RECLUTAMENTO E VALUTE", "icon": "coin", "pages": [
			{"title": "VALUTE", "lines": [_g("VALUTE"), _l("Le ottieni vincendo i boss (di piu' a DIFFICILE e INCUBO), con gli obiettivi di oggi, con le IMPRESE e con questi tutorial.")]},
			{"title": "RECLUTARE", "lines": [
				_l("RECLUTA x1 costa %d CREDITI, x10 costa %d e garantisce almeno un RARO." % [Recruiting.SINGLE_COST, Recruiting.TEN_COST]),
				_l("Se per %d reclutamenti non esce un EPICO o un LEGGENDARIO, il successivo e' almeno EPICO." % Recruiting.PITY_LIMIT),
				_l("Un operatore gia' posseduto diventa una COPIA: servono per il RANK UP."),
				_tip("Le percentuali complete sono nella guida del reclutamento (tasto ? nella schermata Squadra)."),
			]},
		]},
		{"id": "equip", "title": "EQUIPAGGIAMENTO E MOSSE", "icon": "arma", "pages": [
			{"title": "PEZZI DI EQUIPAGGIAMENTO", "lines": [
				_l("Ogni operatore ha 3 slot: ARMA, PETTO, STIVALI. I pezzi cadono dai boss e hanno una rarita'."),
				_l("Si potenziano con CREDITI e LEGHE; un pezzo raro arriva piu' in alto (livello massimo %s per rarita')." % "/".join(PackedStringArray(BattleContent.GEAR_MAX_LEVEL.map(func(v): return str(v))))),
			]},
			{"title": "MOSSE", "lines": [
				_l("Le skill si equipaggiano dalla scheda dell'operatore. Le mosse cadono dai boss, a livelli: base, rara, epica, leggendaria."),
				_l("Una mossa epica o leggendaria ha il bordo VIOLA o GIALLO nei premi: non lasciartela scappare."),
				_tip("Le abilita' UNICHE del personaggio non cadono: sono sue."),
			]},
		]},
		{"id": "modalita", "title": "CO-OP, PVP E CICLO INFINITO", "icon": "vanguard", "pages": [
			{"title": "MULTIPLAYER", "lines": [
				_l("MULTIPLAYER CO-OP: crei una stanza, gli amici entrano con il CODICE. Fino a 6 giocatori contro lo stesso boss."),
				_l("Il boss decide per tutti: ognuno sceglie il suo ordine nello stesso tempo, e il risultato e' uguale per tutti."),
				_l("PVP: duello tra due squadre, con le stesse regole di colore e priorita'."),
			]},
			{"title": "CICLO INFINITO E SFIDA DEL GIORNO", "lines": [
				_l("Il CICLO INFINITO si sblocca battendo alcuni bersagli: affronti boss sempre piu' duri, piano dopo piano."),
				_l("La SFIDA DEL GIORNO cambia ogni giorno: vincila di fila per serie di giorni."),
			]},
		]},
		{"id": "progressi", "title": "MISSIONI, STORIA E OBIETTIVI", "icon": "passive", "pages": [
			{"title": "MISSIONI E DIFFICOLTA'", "lines": [
				_l("Ogni boss ha tre difficolta': NORMALE, DIFFICILE, INCUBO. Piu' sale, piu' premi: l'INCUBO da' mosse leggendarie."),
				_l("La STORIA si racconta tra una missione e l'altra: la Stagione 2 aggiunge Dafne al gruppo."),
			]},
			{"title": "OBIETTIVI E IMPRESE", "lines": [
				_l("Gli OBIETTIVI DI OGGI cambiano ogni giorno. Le IMPRESE (schermata OBIETTIVI) sono permanenti, con premio fisso: niente fortuna."),
				_l("I premi si riscuotono a mano. Alcuni danno icone speciali per il profilo."),
				_tip("Completa tutti i tutorial per l'icona epica STUDIOSO."),
			]},
		]},
	]
	return _list


static func by_id(id: String) -> Dictionary:
	for t in all():
		if str(t["id"]) == id:
			return t
	return {}


static func done_map(roster: Dictionary) -> Dictionary:
	if not roster.has("tutorials") or not (roster["tutorials"] is Dictionary):
		roster["tutorials"] = {"done": {}}
	if not roster["tutorials"].has("done"):
		roster["tutorials"]["done"] = {}
	return roster["tutorials"]["done"]


static func is_done(roster: Dictionary, id: String) -> bool:
	return bool(done_map(roster).get(id, false))


static func done_count(roster: Dictionary) -> int:
	var n: int = 0
	for t in all():
		if is_done(roster, str(t["id"])):
			n += 1
	return n


static func total() -> int:
	return all().size()


# Il premio fisso di un tutorial: crediti, nuclei, leghe e un pezzo base (rarita' 0).
static func reward_text() -> String:
	return "%d CREDITI  +  %d NUCLEI  +  %d LEGHE  +  1 PEZZO BASE" % [REWARD_COINS, REWARD_NUCLEO, REWARD_LEGA]


# Segna il tutorial come finito e da' il premio la PRIMA volta. Ritorna {} se era gia' fatto.
static func complete(roster: Dictionary, id: String) -> Dictionary:
	if by_id(id).is_empty() or is_done(roster, id):
		return {}
	var index: int = 0
	for i in all().size():
		if str(all()[i]["id"]) == id:
			index = i
	done_map(roster)[id] = true
	roster["coins"] = int(roster.get("coins", 0)) + REWARD_COINS
	roster["materials"]["nucleo"] = int(roster["materials"].get("nucleo", 0)) + REWARD_NUCLEO
	roster["materials"]["lega"] = int(roster["materials"].get("lega", 0)) + REWARD_LEGA
	var slot: String = str(BattleTypes.GEAR_SLOTS[index % BattleTypes.GEAR_SLOTS.size()])
	var gid: String = RosterState.new_gear(roster, slot, 0)
	return {"coins": REWARD_COINS, "nucleo": REWARD_NUCLEO, "lega": REWARD_LEGA, "gear": gid, "slot": slot}
