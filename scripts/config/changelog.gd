class_name Changelog
extends RefCounted

# Novita' di ogni versione: si mostrano una sola volta, la prima volta che si apre il gioco dopo un aggiornamento.
# Aggiungi una voce IN CIMA a ogni versione nuova (testi brevi, in italiano semplice).

const ENTRIES: Array = [
	{"v": "0.25.0", "items": [
		"ICONE: nuovo linguaggio visivo ODISPEL con 248 icone (combattimento, status, turni, combo, boss, multiplayer, esplorazione, progressione, interfaccia, identita' Odica) e 4 stemmi di fazione (la Bilancia-L di LibraCorp, Rondini, Magabondi, Kairos).",
		"Le icone gia' nel gioco (mosse, PV, equilibrio, pericolo, fazioni, valute) ora usano i nuovi disegni; le altre sono pronte per le prossime schermate ma non vengono mostrate finche' la funzione non esiste.",
		"Atlante completo in docs/icone/atlante.html.",
	]},
	{"v": "0.24.36", "items": [
		"TELEFONO: le icone delle fazioni sulle carte degli operatori sono piu' grandi (30 px) e l'equilibrio del boss ha la sua icona piu' grande con la scritta EQUILIBRIO.",
	]},
	{"v": "0.24.35", "items": [
		"HUD PIU' PULITA: mentre il round si gioca spariscono riserva, ORD/COSTO e suggerimenti; con un colpo letale resta un solo avviso (con l'icona di pericolo) e niente suggerimenti.",
		"MENO RIPETIZIONI: il numero dei PV sotto i personaggi appare solo per chi sceglie o e' appena stato colpito; l'ordine del turno non ripete piu' il nome della mossa del boss.",
		"ICONE: nuove icone PV, equilibrio, pericolo e K.O. nel linguaggio visivo di ODISPEL (blocco boss e pannello ALLARME). Il testo esplicito del pericolo resta.",
	]},
	{"v": "0.24.34", "items": [
		"LEGGIBILITA': il testo di pericolo (LETALE, ordine del turno del boss) usa un rosso piu' chiaro e il pannello ALLARME ha lo sfondo piu' scuro: contrasto misurato sopra 4,5. I suggerimenti del boss passano da 11 a 13.",
	]},
	{"v": "0.24.33", "items": [
		"PVP: stesso aspetto della battaglia contro il boss: barre PV bianco-ciano (rosse sotto il 30%), barra ultimate rossa, carte e medaglie nei colori ufficiali.",
		"COMANDI: PvE e PvP usano lo stesso stile (usabile, spento, ultimate pronta). Su telefono il ventaglio delle mosse non finisce piu' sotto la scheda GUIDA.",
		"ANNUNCI: le descrizioni lunghe dei comportamenti del boss vanno a capo e non escono piu' dallo schermo. Il segno AGISCE non sparisce dietro l'ordine del turno.",
		"BOSS: il colpo annunciato mostra una STIMA e include il bonus della placca rotta nel round prima; se segue una CATENA lo dice (+CATENA).",
	]},
	{"v": "0.24.32", "items": [
		"BOSS: se un colpo annunciato non ti uccide ora ma ti ucciderebbe quando il boss si infuria (sotto meta' vita, +25% di danno), la schermata avvisa: SE SI INFURIA: LETALE PER ...",
	]},
	{"v": "0.24.31", "items": [
		"SALVATAGGI: una partita rovinata o incompleta viene rifiutata con un messaggio chiaro, invece di dare un errore strano. Vale anche online se l'host manda uno stato sbagliato.",
		"BOSS: l'attacco annunciato mostra il DANNO MINIMO previsto. Il colpo reale puo' essere piu' forte se si attivano rabbia, placche o catene.",
	]},
	{"v": "0.24.30", "items": [
		"ART BIBLE: tutta l'interfaccia usa la palette ufficiale: carbone per i pannelli, avorio per i testi, arancio per i bottoni principali, l'ultimate pronta e gli scudi, magenta per il tondo della fase. Ciano e rosso restano solo per alleato e nemico, piu' morbidi.",
		"La velatura della battaglia diventa viola cosmico.",
		"La finestra delle NOVITA' scorre: con molte voci il tasto OK resta sempre visibile.",
	]},
	{"v": "0.24.29", "items": [
		"BATTAGLIA, NIENTE PIU' SOVRAPPOSIZIONI: avvisi in alto a destra, scheda guida sopra il LOG, TURNO e ORDINE DEL TURNO sotto AUTO e velocita', freccia fuori dal pannello, nomi interi.",
		"BOSS: nome, vita ed equilibrio in un solo blocco. PV degli alleati bianco-ciano, scudi evidenziati.",
		"ABILITA': icona dentro il pulsante, costo a destra e motivo se la mossa e' spenta (SERVE 2E, SENZA COLPI); l'ultimate pronta si evidenzia (PRONTA).",
		"Pannelli piu' puliti, PV in colonna, menu a ventaglio piu' rapido.",
	]},
	{"v": "0.24.28", "items": [
		"PRESTAZIONI: i tratti di luce sono disegnati con 3 sole forme sfumate invece di decine di cerchi e linee trasparenti: stesso aspetto (anzi, alone piu' morbido) con molto meno lavoro per la scheda video.",
		"A tratto finito non si ridisegna piu' niente: la dissolvenza e' solo trasparenza.",
		"Niente piu' scatto al primo colpo: la grafica degli effetti viene preparata all'ingresso in battaglia.",
		"Le frecce delle liste non lavorano piu' quando il menu e' chiuso.",
	]},
	{"v": "0.24.27", "items": [
		"CORREZIONE: i tratti di luce (fendenti, scudi, cure, firme degli ultimate) ora si vedono sempre, anche con gli EFFETTI RIDOTTI (che sui telefoni sono accesi di default).",
		"Con gli effetti ridotti restano tratto e alone leggero; per avere anche particelle, copie sfasate e velo scuro: Impostazioni > EFFETTI RIDOTTI: NO.",
	]},
	{"v": "0.24.26", "items": [
		"ART BIBLE: palette ufficiale (magenta, arancio, viola cosmico, avorio) e nuovo FENDENTE pesante con coda di filamenti e frammenti arancio.",
		"I colpi pesanti, i critici, Colpo caricato e Spezzatutto usano il fendente. Doppio colpo disegna due tratti, Colpo mirato uno sottile.",
		"Effetti piu' rapidi: un colpo normale dura circa mezzo secondo e non fa aspettare il turno.",
	]},
	{"v": "0.24.25", "items": [
		"LIGHT PAINTING, FASE 2: Marchio, Frattura e Intimidisci lasciano un segno sul bersaglio.",
		"ULTIMATE: ogni personaggio ha la sua firma luminosa (24 stelle diverse) che si disegna e poi si disperde.",
		"Quando corre la luce, il mondo si scurisce un attimo: i tratti si leggono meglio.",
		"Pronto per le tue pennellate: art/fx/stroke_<fazione>.png sostituisce il tratto generato.",
	]},
	{"v": "0.24.24", "items": [
		"LIGHT PAINTING: i colpi, gli scudi e le cure sono tracciati di luce, come una foto a lunga esposizione.",
		"La FAZIONE decide il gesto: LibraCorp a circuito con mirino, Rondini ad arco morbido, Magabondi a scarabocchio con gocce, Kairos con copie sfasate e rune.",
		"Il COLORE decide le particelle: rosso scintille, giallo pulviscolo, viola fumo d'inchiostro, verde puntini, blu filamenti.",
		"Scudi e protezioni disegnano un anello, le cure una spirale che sale. Si spegne con la qualita' grafica BASSA.",
	]},
	{"v": "0.24.23", "items": [
		"NUOVA DIFFICOLTA' ABISSO: pensata per squadre al massimo (livello 50, rank 5, pezzi leggendari). Si apre battendo un boss a INCUBO.",
		"Boss con tanti PV e colpi pesantissimi: anche una squadra al massimo deve giocare bene (reazioni, ordini, combo) per vincere. Premi x5.",
		"Il Ciclo Infinito e la Spedizione restano fino a INCUBO.",
		"LISTE E MENU: frecce SU e GIU' per scorrere equipaggiamento, mosse, potenziamenti e tutti i menu lunghi (tieni premuto per scorrere veloce).",
		"HOME su telefono: pulsanti in due colonne, senza sovrapposizioni.",
		"Tasto AUTO piu' grande e con messaggio di conferma quando si accende o si spegne.",
	]},
	{"v": "0.24.22", "items": [
		"REPLAY TATTICO: ora si apre sopra la schermata dei risultati (prima restava nascosto dietro) e si chiude col tasto CHIUDI.",
		"REGISTRO EVENTI: ora scorre, tiene piu' righe, separa i turni e si legge meglio sopra il boss.",
		"IMPOSTAZIONI: slider piu' grandi e facili da usare col dito; la rotella non cambia piu' il volume per sbaglio.",
		"Il suggerimento del boss non copre piu' Riserva di squadra e tasti.",
	]},
	{"v": "0.24.21", "items": [
		"BATTAGLIA RIFATTA: personaggi e boss in prospettiva, HUD piu' pulita, barre vita sotto i personaggi quando serve, log a tendina, icone per AUTO e velocita'.",
		"ABILITA': quando un operatore lancia un'abilita' compare il suo ritratto con il nome della mossa.",
		"KIT A 4 MOSSE + ULTIMATE: Attacco, Guardia, skill e abilita' uniche stanno tutte negli stessi 4 slot e si possono togliere e mettere.",
		"BONUS KIT COMPLETO: con 4 mosse equipaggiate e l'ultimate l'operatore ha +3% PV, attacco e difesa.",
		"Sistemato il tasto di fine partita che usciva dallo schermo: riepilogo e premi ora scorrono e i pulsanti restano sempre visibili.",
	]},
	{"v": "0.24.20", "items": [
		"MAESTRIA CHE SI SALVA: ogni mossa che usi tanto sale di livello (25 usi per livello, fino a 3) e fa +4% per livello. Te lo dice a fine battaglia.",
		"SFIDA FACOLTATIVA: ogni battaglia ne propone una (nessun caduto, rottura veloce...). Se la superi vinci 120 crediti in piu'. La vedi all'inizio e nel resoconto.",
		"RIENTRO: dopo 3 sconfitte di fila la battaglia dopo parte con Riserva +2 e un po' di scudo. Non regala la vittoria.",
		"IL BOSS IMPARA: se hai gia' battuto un boss, la volta dopo ha imparato dal tuo stile (pazienza, sinergie o guardie) e te lo dice chiaramente.",
		"SALA DI ADDESTRAMENTO: nelle Missioni attiva ADDESTRAMENTO per provare un boss senza premi, progressi o conseguenze.",
		"Nella Spedizione puoi incollare il CODICE SQUADRA di un amico e confrontarlo con la tua. Il resoconto ora racconta i momenti (Ultimo istante, Vittoria disperata...) e le cause.",
	]},
	{"v": "0.24.19", "items": [
		"TITOLI EPICI E LEGGENDARI con bonus PERMANENTI per tutti i personaggi: le icone epiche e leggendarie del profilo (es. Leggenda: Baluardo = +0,5% difesa a tutti) e nuove maestrie.",
		"Nuove maestrie: dei COLORI (2 operatori = epico +0,5% danni, 4 = leggendario +1%), delle FAZIONI, delle CLASSI, Collezionista, Veterano, Esploratore, Conquistatore. Vale solo il titolo piu' alto di ogni linea.",
		"POTERE dei personaggi: un numero solo che cresce con livello, rank, equipaggiamento e titoli. Lo vedi nella scheda operatore e nella nuova schermata TITOLI E POTERE (dagli Obiettivi), con il dettaglio e quanto sei cresciuto dall'ultima visita.",
		"SPEDIZIONE LUNGA: 10 tappe con rifugio, guardiano, reliquia maledetta e un terzo scontro. Premi e veterani maggiori, piu' tre modificatori volontari per aumentare la sfida.",
		"Battaglia: ORDINI di squadra, PREZZO (potere in cambio di PV) e PING rapidi per la cooperativa. Nuovi eventi: scudi del boss, attacchi a catena, ECO.",
	]},
	{"v": "0.24.18", "items": [
		"EVENTI DELL'ARENA: ogni 3 round l'arena cambia (ZONA CONTAMINATA o SIGILLO). Leggi l'annuncio e decidi: mettersi in guardia, scambiare, attaccare in due.",
		"Ogni boss ha un COMPORTAMENTO da imparare: punisce le cure, reagisce ai marchi oppure punisce la guardia di gruppo.",
		"Nuova reazione SOCCORSO: spendi Riserva per rialzare un compagno caduto.",
		"Nuovi potenziamenti del Ciclo infinito (Riflessi, Riserva) e nuovo mutatore Vampirico.",
		"REPLAY TATTICO nel resoconto: i momenti decisivi in ordine, turno per turno.",
		"ARCHIVIO DELLE SCOPERTE: combo, eventi dell'arena e comportamenti dei boss che vedi davvero vengono registrati. Un boss di cui hai capito il comportamento te lo ricorda mentre pianifichi.",
		"NUOVA MODALITA' SPEDIZIONE (da soli o in cooperativa dalla lobby): percorso, scontri, evento con patto, bivio e boss finale. I PV si portano dietro, ogni vittoria da' un potenziamento, le scelte contano.",
		"In cooperativa si vota ogni scelta: decide la maggioranza, in pareggio l'host. Non si resta mai bloccati.",
		"Conseguenze che restano: i VETERANI ottengono bonus permanenti, chi cade in una spedizione fallita resta FERITO (guarisce in 6 ore o con 300 crediti).",
		"Nuove combo CONDANNA e CASCATA, CODICE SQUADRA da copiare e condividere, due nuovi tutorial (Arena e archivio, Spedizione).",
		"TITOLI DI SQUADRA nel resoconto (Nessuno e' caduto, Muro di reazioni, Spezzaguardie...) e STILE della squadra. Il profilo mostra quante scoperte hai fatto.",
	]},
	{"v": "0.24.17", "items": [
		"RISERVA DI SQUADRA: una scorta condivisa (+1 a round, +1 con una combo) che si spende per le REAZIONI.",
		"Contro una CARICA del boss compaiono 3 reazioni: SCHIVATA (eviti il colpo), INTERCETTAZIONE (lo prendi tu al posto di un compagno), INTERRUZIONE (togli equilibrio e la carica salta).",
		"Nuove combo: VINCOLO + SCARICA e GUARDIA SPEZZATA. Ogni combo scatta una sola volta per causa e round: niente catene infinite.",
		"Dalla fase 2 il boss divora la Riserva: non basta piu' accumulare.",
		"Resoconto: cariche non gestite, Riserva sprecata e combo decisiva.",
		"Nuova sezione TUTORIAL nell'hub: 12 lezioni su tutte le meccaniche, sempre consultabili. Ogni tutorial letto la prima volta regala 300 crediti, nuclei, leghe e un pezzo di equipaggiamento base.",
		"Nuove imprese STUDIOSO negli obiettivi: supera 1, 3, 5, 7, 10 tutorial e completali tutti per l'icona epica Studioso.",
		"I ritratti di Dafne nei dialoghi non sono piu' tagliati.",
		"PvP e allenamento contro l'IA: i comandi ora rispondono (un riquadro invisibile li copriva) e la schermata ha lo stesso palco della storia, con personaggi in campo, targhette, ventaglio e scatti d'attacco. Il bersaglio si sceglie anche toccando il personaggio.",
	]},
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
