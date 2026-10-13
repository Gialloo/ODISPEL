class_name Lore
extends RefCounted

# Testi di consultazione: legenda dell'operatore, glossario dei termini, archivio degli operatori.
# La lore dei personaggi e' una BOZZA da riscrivere: i fatti di gioco (kit, classi, regole) arrivano dal codice.

# tag: una riga sotto il nome. lore: chi e'. tactic: come usarlo (coerente con skill, ultimate e passiva).
const CHARACTERS: Dictionary = {
	"kira": {
		"tag": "Colpi pesanti, poca vita",
		"lore": "Ragazza dei vicoli che ha imparato a incanalare la magia nei pugni. Non ama le regole, ama chiudere la partita in fretta.",
		"tactic": "Accumula energia, poi COLPO CARICATO (x2). Lascia che un vanguard attiri il boss e spendi SPEZZATUTTO nel momento giusto.",
	},
	"dax": {
		"tag": "Muro che attira i colpi",
		"lore": "Ex guardia notturna: non e' il piu' veloce, ma nessuno e' mai passato oltre di lui. Si mette in mezzo per istinto.",
		"tactic": "Usa PROVOCA quando il boss annuncia la mossa forte, poi BASTIONE per coprire tutta la squadra. TEMPRA gli da' piu' vita.",
	},
	"elle": {
		"tag": "Cura e rimette in piedi",
		"lore": "Studia le anomalie per capirle prima di combatterle. Porta sempre con se' un taccuino e le erbe di sua nonna.",
		"tactic": "VERDE = DEX: le sue cure e i suoi scudi possono essere CRITICI (x1,5). RESPIRO cura tutti e restituisce 1 energia (Magabondi: si arrangia). RINASCITA toglie i malus. L'entrata scudata la rende ottima da far entrare a meta' battaglia.",
	},
	"eco": {
		"tag": "L'anomalia che si e' unita a noi",
		"lore": "Una voce nata nei display e nelle linee della citta', che ripete cio' che sente e sta imparando cosa significa. E' dalla parte della squadra, anche se nessuno sa ancora perche'.",
		"tactic": "Kairos = logoramento: ECO RIPETUTO marchia e rallenta il boss, FREQUENZA CRITICA gli abbassa la difesa. Marchia e indebolisci, poi lascia agire la squadra. Atipico: +15% di danno ai bersagli indeboliti. Non da' aure.",
	},
	"nico": {
		"tag": "Custode del rifugio · Intimidisce",
		"lore": "Teneva aperto il rifugio per tutti, finche' il tempo non si e' fermato. La sciarpa rossa e' tornata con lui: dice di averla ritrovata in uno specchio.",
		"tactic": "INTIMIDISCI abbassa l'attacco del boss e costa solo 1 energia: usalo prima delle mosse forti. BASTIONE protegge tutti. Rosso = STR: prende slancio dai colpi e, se atipico (RABBIA LENTA), anche da quelli che subisce. Fazione Kairos, come Eco.",
	},
	"dafne": {
		"tag": "Agent 02 · Tiratore scelto",
		"lore": "La seconda agente LibraCorp a uscire dai registri. Non parla molto: marchia, aspetta, spara una volta sola. Ogni marchio che mette sul bersaglio le fa vedere meglio il punto debole.",
		"tactic": "MARCHIO prima di tutto: i colpi con munizioni fanno +15% a marchio. COLPO MIRATO abbassa la difesa e punta al critico. COPERTURA ti nasconde (schivata) e ricarica 2 munizioni. COLPO COORDINATO mette 3 marchi e potenzia tutta la squadra. Atipica (TIRO DI GRAZIA): critico sicuro sul boss sotto il 30% dei PV, e ogni critico ridona una munizione.",
	},
	"angela": {
		"tag": "Orbital Laser Goddess",
		"lore": "Dice di parlare con un satellite. I droni le rispondono. Fragile come il vetro, ma quando il cielo si apre non resta nulla da raccogliere.",
		"tactic": "12 munizioni: TORRETTA e DRONE sparano da soli ogni round (1 munizione a colpo) e a zero esplodono o danno scudi. MITRAGLIATRICE per i critici. RAGGIO ORBITALE consuma tutti i marchi: falli accumulare prima. I suoi marchi ricaricano le munizioni di tutti i LibraCorp. Atipica (SURRISCALDAMENTO): ogni munizione spesa da' +3% di danno fino a fine battaglia (max 12 cariche).",
	},
	"moro": {
		"tag": "Non arretra, non urla",
		"lore": "Combattente dei quartieri bassi con le fasce rituali rosse. Fa muro con il corpo e restituisce i colpi.",
		"tactic": "RITORSIONE colpisce e ti mette in guardia: lo vedi come primo della fila. LEGGE DEL CONTRACCOLPO copre tutta la squadra con uno scudo. CONTRACCOLPO fa male a chi lo colpisce.",
	},
	"vesper": {
		"tag": "Caccia l'anomalia marchiata",
		"lore": "Cacciatore di anomalie dal volto coperto. Parla poco, segue il bersaglio fino a quando cade.",
		"tactic": "TAGLIO PREDATORIO marchia mentre colpisce. ECLISSI CREMISI e' il colpo che chiude. PREDAZIONE: piu' danno ai bersagli marchiati, quindi marca prima o fatti aiutare da Nova ed Eco.",
	},
	"nami": {
		"tag": "Piccoli rituali, grandi scudi",
		"lore": "Giacca troppo grande, amuleti fatti a mano. Crede che un buon rito basti a tenere in piedi chi ami.",
		"tactic": "RIPARO IMPROVVISATO da' uno scudo a un alleato e costa 1 sola energia. CERCHIO SICURO protegge tutti. GUARDIA PREPARATA: la sua Guardia da' uno scudo extra.",
	},
	"oriel": {
		"tag": "Custode della soglia",
		"lore": "Cappotto bianco e blu, aureola spezzata. Decide chi puo' passare e chi no.",
		"tactic": "PROTOCOLLO DI SOCCORSO cura, scherma e toglie i malus a un alleato. RIFUGIO ASSOLUTO da' scudi a tutti. CURA SCHERMATA: ogni cura diventa anche scudo. Blu: agisce presto e carica l'ultimate in fretta.",
	},
	"silex": {
		"tag": "Il muro che avanza",
		"lore": "Protezioni angolari viola e grigio grafite. Lento ma regolare: avanza e non si ferma.",
		"tactic": "FRATTURA MINERALE colpisce e abbassa la DIF del boss. FORTEZZA GEOMETRICA protegge tutti. ARMATURA CICLICA: uno scudo gratis a ogni inizio round.",
	},
	"yuna": {
		"tag": "Prima ad agire",
		"lore": "Abiti tecnici blu elettrico, tagli asimmetrici. Arriva sempre prima del colpo.",
		"tactic": "PASSO FULMINEO costa 1 sola energia e marchia. LAMA DEL FUTURO e' un colpo che perfora la difesa. FIATO RUBATO: recupera un poco di vita dal danno. Fragile: non farla restare sola.",
	},
	"rhea": {
		"tag": "Specialista del contenimento",
		"lore": "Equipaggiamento da campo, tasche piene, simboli di soccorso trasformati in sigilli verdi.",
		"tactic": "RICOMPOSIZIONE cura molto un alleato. ALBA CONDIVISA cura e purifica tutti. RECUPERO COSTANTE: un poco di vita a fine round. Verde: le sue cure possono essere critiche.",
	},
	"flux": {
		"tag": "Il picco in una finestra breve",
		"lore": "Cappotto nero e blu, linee luminose spezzate. Accelera, colpisce, poi si ferma a respirare.",
		"tactic": "RAFFICA SINCRONIZZATA: due colpi e un marchio. PUNTO DI ROTTURA e' il colpo grosso. PRECISIONE OPPORTUNISTICA: piu' critico sui marchiati, quindi falli marchiare prima.",
	},
	"cato": {
		"tag": "Funziona sempre",
		"lore": "Uniforme tattica LibraCorp, viola freddo, tutto in ordine. Non e' il migliore: e' quello su cui contare.",
		"tactic": "IMPATTO DI CONTENIMENTO colpisce e ti mette in guardia. LINEA INVALICABILE copre tutta la squadra. CORAZZA A SPILLI: chi lo colpisce si fa male. Ottimo per iniziare.",
	},
	"lyra": {
		"tag": "Sceglie il bersaglio decisivo",
		"lore": "Taglio elegante ma militare, viola profondo. Indica chi deve cadere, gli altri eseguono.",
		"tactic": "MARCHIO DI PRIORITA' mette due marchi con un colpo leggero. SENTENZA COORDINATA marchia e abbassa la difesa. PRIORITA' ASSOLUTA: piu' danno ai marchiati. Con Angela e Dafne il fuoco si concentra.",
	},
	"bruno": {
		"tag": "Scudi per tutti",
		"lore": "Tranquillo, metodico, controlla due volte ogni serratura. La sua magia costruisce barriere dove servono.",
		"tactic": "BARRIERA prima del colpo grosso del boss, BASTIONE quando il colpo e' a tutta la squadra. TEMPRA lo rende molto resistente.",
	},
	"nova": {
		"tag": "Marchia e finisce",
		"lore": "Cacciatrice di anomalie: segna il bersaglio e lo segue finche' non cade. Lavora meglio quando il nemico e' gia' in difficolta'.",
		"tactic": "MARCHIO (+25% di danno al bersaglio), poi colpisci con la squadra. CACCIATORE aumenta il danno contro chi e' sotto meta' vita.",
	},
	"mira": {
		"tag": "Toglie i malus",
		"lore": "Dice poco e nota tutto. Quando qualcuno e' maledetto o ferito, lei lo sa prima che se ne accorga lui.",
		"tactic": "BLU = QCK: INIEZIONE ha priorita' e agisce prima del boss (cura + scudo + toglie il sanguinamento), ideale per coprire il colpo annunciato. LibraCorp: il suo scudo cresce con le cure. Atipica: +6% VEL e DIF.",
	},
	"rex": {
		"tag": "Furia rossa",
		"lore": "Non e' mai stato bravo a fermarsi. Combatte come se avesse sempre un tempo da recuperare.",
		"tactic": "Gioca d'attacco: COLPO CARICATO ogni volta che hai energia, SPEZZATUTTO appena la barra e' piena. FURIA aumenta l'attacco. Se puo', scegli il colore che batte il boss.",
	},
	"ivo": {
		"tag": "Marchio e cambi rapidi",
		"lore": "Fa tutto di corsa e in silenzio. Entra, segna il bersaglio, esce prima che il boss reagisca.",
		"tactic": "MARCHIO per aprire il turno e farlo entrare con scudo grazie all'ENTRATA SCUDATA; poi cambia con un compagno e fai colpire gli altri.",
	},
	"sera": {
		"tag": "Barriere e caccia",
		"lore": "Veterana delle notti lunghe. Protegge la squadra con calma e non perde l'occasione di infierire su un nemico ferito.",
		"tactic": "VERDE = DEX, Rondini: VENTO DI CODA e ALA PROTETTIVA possono essere critici (x1,5). Schiera piu' Rondini per l'aura critico. Atipica (VOLO RADENTE): a fine round passa +8 di ultimate all'alleato piu' scarico.",
	},
	"tana": {
		"tag": "Baluardo leggendario",
		"lore": "Quando arriva lei, la strada si chiude. Leggenda di quartiere: dicono che nessuna anomalia le abbia mai fatto passare un colpo.",
		"tactic": "GIALLO = PSY, LibraCorp: BASTIONE VIVENTE e MURO TOTALE sono scudi piu' forti del 20%. PROVOCA per prendere su di se' il colpo. Atipica (BALUARDO CHE RISPONDE): il 40% del danno assorbito dal suo scudo torna al boss; perde pero' il contrattacco ortodosso.",
	},
}

# Termini del gioco: [titolo, spiegazione]. Le cifre arrivano dal codice.
static func glossary() -> Array:
	return [
		["ENERGIA", "Serve per le skill. Massimo %d. Chi e' in campo ne recupera %d a round, chi e' in panchina %d. La GUARDIA ne da' 1." % [BattleTypes.MAX_ENERGY, BattleTypes.REGEN_ACTIVE, BattleTypes.REGEN_BENCH]],
		["ULTIMATE", "La barra si carica colpendo (+%d) e venendo colpiti (+%d). A %d puoi usare l'ultimate, senza costo di energia." % [BattleTypes.GAUGE_ON_HIT, BattleTypes.GAUGE_ON_DAMAGED, BattleTypes.GAUGE_MAX]],
		["VANTAGGIO DI COLORE", "Rosso batte verde, verde batte blu, blu batte rosso; giallo e viola si battono a vicenda. Colore giusto: danno x%.1f. Colore sbagliato: x%.2f." % [BattleTypes.COLOR_ADVANTAGE, BattleTypes.COLOR_DISADVANTAGE]],
		["ALLARME", "Il boss annuncia un round prima la mossa e il bersaglio. Leggila sempre prima di scegliere."],
		["CAMBIO", "Scambiare l'operatore in campo e' gratuito e avviene prima di ogni azione. In BACK ROW si recupera piu' energia. Puoi scambiare i front con la back row a piacere."],
		["GUARDIA", "Dimezza il danno subito in quel round (x%.1f) e ridona energia." % BattleTypes.GUARD_FACTOR],
		["SCUDO", "Assorbe danno prima dei PV. Lo danno Barriera, Bastione, Provoca e l'entrata scudata."],
		["PROVOCAZIONE", "Il boss, se puo', colpisce chi provoca. Utile per proteggere chi fa danno."],
		["MARCHIO", "Pila di marchi sul nemico (max %d): ogni marchio da' +%d%% di danno, +%d%% ai colpi che usano munizioni. Restano finche' qualcuno non li consuma." % [Marks.MAX, int(round(Marks.PCT * 100.0)), int(round(Marks.AMMO_PCT * 100.0))]],
		["SANGUINAMENTO", "Danno ogni round pari al %d%% dei PV massimi. Si toglie con Purifica o Rinascita." % int(round(BattleTypes.BLEED_FRACTION * 100.0))],
		["FURIA DEL BOSS", "Sotto meta' PV il boss colpisce piu' forte (+%d%%)." % int(round((BattleTypes.ENRAGE_BONUS - 1.0) * 100.0))],
		["CACCIATORE", "Passiva: +%d%% di danno contro chi e' sotto meta' PV." % int(round((BattleTypes.HUNTER_BONUS - 1.0) * 100.0))],
		["COLORE = STRATEGIA", "Ogni colore e' la base di un operatore. ROSSO=STR: colpi che crescono. GIALLO=PSY: energia, cure e scudi piu' forti. VIOLA=INT: marchi, sanguinamento e critici. VERDE=DEX: critici potenti che caricano l'ultimate. BLU=QCK: velocita' e ultimate sempre pronta. Classe, fazione e abilita' uniche completano la strategia."],
		["PASSIVA E ABILITA' UNICHE", "Ogni operatore ha una passiva unica (★) e 1 o 2 abilita' uniche: 1 per comuni e rari, 2 per epici e leggendari (la seconda si sblocca a rank 3). Non cadono come premio: sono del personaggio."],
		["LIVELLO E RANK", "Il livello si compra con CREDITI e nuclei. Le copie di un operatore che hai gia' non fanno salire il rank da sole: si conservano e le spendi tu col bottone RANK UP (costo in copie: %s per i rank 1-%d). Ogni rank da' statistiche (comune +4%%, raro +5%%, epico +6%%, leggendario +8%%) e potenzia la passiva. Rank 1: SKILL 1 potenziata. Rank 2: SKILL 2. Rank 3: ULTIMATE. Rank 4: SKILL 1 e 2 ancora. Rank 5: ULTIMATE ancora e RISVEGLIO (parte con +%d di carica). Piu' e' raro l'operatore, piu' i potenziamenti sono grandi." % [", ".join(RosterState.RANK_COPY_COST.map(func(c: int) -> String: return str(c))), RosterState.MAX_RANK, Signatures.AWAKEN_GAUGE]],
		["MUNIZIONI", "Solo LibraCorp: massimo %d. Servono ai colpi mirati e ai contrattacchi. Si recuperano con RICARICA (+3) e con GUARDIA (+1)." % BattleTypes.AMMO_MAX],
		["CONTRATTACCO", "Un LibraCorp ortodosso colpito dal boss che resta in piedi risponde al fuoco (danno x%.1f) spendendo una munizione." % BattleTypes.COUNTER_MULT],
		["PERFORA", "Il colpo ignora meta' della difesa del bersaglio (Colpo mirato, Colpo alla testa)."],
		["FAZIONE", "Gruppo a cui appartiene un operatore: LibraCorp, Rondini, Magabondi, Kairos. Da' un'AURA ai compagni della stessa fazione."],
		["AURA", "Bonus passivo a una statistica per i compagni di fazione. Cresce con la rarita' di chi la da', con tetto +%d%%. Sparisce se chi la da' e' a terra." % (Factions.AURA_CAP_PM / 10)],
		["CRITICO", "Probabilita' di colpo che fa x%.1f di danno. Lo aumentano le aure delle Rondini." % (float(Factions.CRIT_DMG_PM) / 1000.0)],
		["STILE", "Ortodosso: segue la dottrina, aura intera. Atipico: aura dimezzata, ma +8% ATK e +5% VEL, piu' un TRATTO proprio dell'operatore: nessuno per i comuni, piccolo per i rari, evidente per gli epici, unico per i leggendari. Si cambia dalla scheda."],
		["VALUTE", "CREDITI (reclutare e potenziare), Nuclei (livello degli operatori), Leghe (livello dei pezzi di equipaggiamento)."],
	]


static func character_text(char_id: String) -> Dictionary:
	return CHARACTERS.get(char_id, {})


# Pagina "legenda" di un operatore: lui, la sua classe, la sua fazione.
static func legend_page(char_id: String, style: String = "", faction_override: String = "") -> Dictionary:
	var def: Dictionary = BattleContent.CHARACTERS.get(char_id, {})
	var lines: Array = []
	if def.is_empty():
		return {"title": "LEGENDA", "lines": lines}
	var t: Dictionary = character_text(char_id)
	var cls: String = str(def["cls"])
	var ct: Dictionary = StrategyInfo.class_text(cls)
	lines.append(_line("%s  |  %s  |  %s" % [str(def["color"]).to_upper(), cls.to_upper(), str(BattleTypes.RARITIES[int(def["rarity"])]).to_upper()], BattleTheme.rarity_color(int(def["rarity"]))))
	lines.append(_line("CHI E': " + str(t.get("lore", ""))))
	lines.append(_line("COME SI USA: " + str(t.get("tactic", "")), BattleTheme.GOLD))
	lines.append(_line("CLASSE %s: %s %s" % [cls.to_upper(), str(ct.get("role", "")), str(ct.get("does", ""))], BattleTheme.CY))
	var faction: String = faction_override if faction_override != "" else BattleContent.faction_of(char_id)
	if faction != "":
		var ft: Dictionary = StrategyInfo.faction_text(faction)
		var info: Dictionary = Factions.FACTIONS[faction]
		var st: String = style if style != "" else BattleContent.style_of(char_id)
		lines.append(_line("FAZIONE %s (%s): %s Come si vince: %s Stile %s: %s" % [str(info["name"]).to_upper(), str(info["doctrine"]), str(ft.get("idea", "")), str(ft.get("win", "")), st.to_upper(), str(StrategyInfo.STYLES.get(st, ""))], BattleTheme.CY_DIM))
	else:
		lines.append(_line("FAZIONE: nessuna, per ora. Senza fazione non da' ne' riceve aure.", BattleTheme.CY_DIM))
	return {"title": str(def["name"]).to_upper(), "lines": lines}


# Una mossa spiegata in parole semplici: costo, tipo e cosa fa.
static func move_line(move_id: String, label: String = "") -> Dictionary:
	var m: Dictionary = BattleContent.MOVES.get(move_id, {})
	if m.is_empty():
		return _line("-")
	var kind: String = str(m.get("kind", "basic"))
	var cost: String = ""
	if kind == "skill":
		cost = " (%dE)" % int(m.get("cost", 0))
	elif kind == "ult":
		cost = " (ULTIMATE, a barra piena)"
	var tag: String = label if label != "" else {"basic": "BASE", "skill": "SKILL", "ult": "ULT"}.get(kind, "")
	var tgt: String = {"enemy": "sul boss", "ally": "su un alleato", "allies": "su tutta la squadra", "self": "su di te"}.get(str(m.get("target", "enemy")), "")
	var hint: String = BattleText.move_hint(move_id)
	var col: Color = BattleTheme.GOLD if kind == "ult" else (BattleTheme.CY if kind == "skill" else BattleTheme.WH)
	return _line("%s - %s%s: %s %s" % [tag, BattleText.move_name(move_id), cost, hint.to_lower() if hint != "" else "effetto speciale", tgt], col)


# Pagine "?" di un operatore: abilita' e cosa da' ogni rank.
static func ability_pages(char_id: String, rank: int = 0) -> Array:
	var def: Dictionary = BattleContent.CHARACTERS.get(char_id, {})
	var out: Array = []
	if def.is_empty():
		return out
	var ab: Array = []
	ab.append(move_line("attack"))
	ab.append(move_line("guard"))
	var base: String = str(def.get("skill", ""))
	if base != "":
		ab.append(move_line(base, "SKILL BASE"))
	for sk in Signatures.all_skills(char_id):
		var l: Dictionary = move_line(str(sk["id"]), "SKILL UNICA")
		if int(sk["rank"]) > 0:
			l["text"] = str(l["text"]) + "  [si sblocca a RANK %d]" % int(sk["rank"])
		ab.append(l)
	ab.append(move_line(str(def.get("ult", "")), "ULTIMATE"))
	for pid in def.get("passives", [str(def.get("passive", ""))]):
		if BattleContent.PASSIVES.has(str(pid)):
			ab.append(_line("PASSIVA - %s" % str(BattleContent.PASSIVES[str(pid)]["name"]), BattleTheme.CY_DIM))
	if Signatures.has_passive(char_id):
		ab.append(_line("PASSIVA UNICA - %s: %s" % [Signatures.passive_name(char_id), Signatures.passive_text(char_id, rank)], BattleTheme.CY_DIM))
	if Signatures.has_bench(char_id):
		ab.append(_line("SOSTEGNO - " + Signatures.bench_text(char_id, rank) + " (in PvP vale la meta').", BattleTheme.OK))
	if BattleContent.faction_of(char_id) != "":
		ab.append(_line(Atypical.describe(char_id), BattleTheme.CY_DIM))
	out.append({"title": "%s - ABILITA'" % str(def["name"]).to_upper(), "lines": ab})
	var rk: Array = [_line("Ogni rank si compra con le COPIE (max rank %d). Cosa ottieni:" % RosterState.MAX_RANK)]
	var stat: int = int(round(BattleContent.rank_bonus(int(def["rarity"])) * 100.0))
	for r in range(1, RosterState.MAX_RANK + 1):
		rk.append(_line("RANK %d: +%d%% statistiche (in totale +%d%%) · %s" % [r, stat, stat * r, Signatures.rank_upgrade_text(char_id, r)], BattleTheme.GOLD if r <= rank else BattleTheme.WH))
	if Signatures.has_passive(char_id):
		rk.append(_line("La passiva unica cresce di +%d%% del suo valore a ogni rank." % int(round(Signatures.passive_scale(char_id) * 100.0)), BattleTheme.CY_DIM))
	rk.append(_line("In giallo i rank gia' raggiunti (ora RANK %d)." % rank, BattleTheme.CY_DIM))
	out.append({"title": "%s - RANK" % str(def["name"]).to_upper(), "lines": rk})
	return out


# Archivio: glossario (a pagine) e poi una pagina per ogni operatore.
static func archive_pages() -> Array:
	var out: Array = []
	var terms: Array = glossary()
	var per_page: int = 4
	var i: int = 0
	while i < terms.size():
		var lines: Array = []
		for j in range(i, mini(i + per_page, terms.size())):
			lines.append(_line(str(terms[j][0]), BattleTheme.CY))
			lines.append(_line(str(terms[j][1])))
		out.append({"title": "GLOSSARIO %d" % (i / per_page + 1), "lines": lines})
		i += per_page
	for id in BattleContent.CHARACTERS:
		out.append(legend_page(str(id)))
	return out


static func _line(text: String, color: Color = BattleTheme.WH) -> Dictionary:
	return {"text": text, "color": color}
