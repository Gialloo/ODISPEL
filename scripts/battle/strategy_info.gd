class_name StrategyInfo
extends RefCounted

# Testi di gioco: cosa fa ogni classe e ogni fazione, e cosa serve per farla funzionare.
# Per le fazioni c'e' anche lo stato: cosa esiste gia' nel gioco ("now") e cosa arriva ("soon"),
# cosi' la guida non promette cose che non ci sono. Le cifre delle aure arrivano da Factions.

# role: in una frase. does: cosa fa in battaglia. needs: cosa deve fare il giocatore perche' funzioni.
const CLASSES: Dictionary = {
	"striker": {
		"label": "STRIKER",
		"role": "Fa il danno. Poca vita e poca difesa, molta forza e velocita'.",
		"does": "Colpisce forte (Colpo caricato, Spezzatutto) e agisce prima degli altri.",
		"needs": ["Tienilo vivo: protetto da barriere e da un VANGUARD che attira i colpi.", "Scegli il colore che batte quello del boss (x1,5).", "Usa MARCHIO prima dei colpi grossi (+25% di danno sul bersaglio).", "Carica l'ultimate e spendila quando il boss e' sotto la meta' dei PV."],
	},
	"vanguard": {
		"label": "VANGUARD",
		"role": "Regge i colpi. Tanta vita e difesa, poca velocita'.",
		"does": "Attira il boss (Provoca), si dà uno scudo e con Bastione protegge tutta la squadra.",
		"needs": ["Usa PROVOCA nel round in cui il boss ha annunciato la mossa forte: il colpo va su di lui.", "Tieni GUARDIA contro i colpi che non puoi evitare (dimezza il danno).", "Spendi BASTIONE prima di un colpo a tutta la squadra."],
	},
	"warden": {
		"label": "WARDEN",
		"role": "Tiene in piedi la squadra. Cura, scudi e rimozione degli effetti.",
		"does": "Cura (Cura, Rinascita), protegge (Barriera) e toglie i malus (Purifica).",
		"needs": ["Guarda i PV degli alleati prima di scegliere: cura chi e' sotto la meta'.", "PURIFICA solo quando c'e' un malus da togliere (sanguinamento, e in futuro veleno e sigilli).", "Cambia operatore gratis per far entrare lo scudo dell'entrata al momento giusto."],
	},
}

# idea: come gioca la fazione. win: come si vince con lei. needs: cosa devi fare tu.
# now / soon: cosa c'e' gia' e cosa manca.
const FACTIONS: Dictionary = {
	"libracorp": {
		"idea": "Resiste, risponde ai colpi e spara con munizioni contate. I poteri vengono dall'equipaggiamento.",
		"win": "Vinci a lungo termine: il boss si spreca sui tuoi bersagli resistenti e tu rispondi a ogni suo colpo.",
		"needs": ["Schiera piu' operatori LibraCorp: ogni aura si somma (tetto +25% difesa).", "Metti in squadra un leggendario o epico: da' l'aura piu' grande.", "Anche i comuni contano: ognuno aggiunge la sua parte.", "Gestisci le MUNIZIONI: ogni contrattacco ne costa una. Ricarica (o Guardia) prima di restare a secco.", "Colpo mirato e Colpo alla testa fanno molto danno e perforano la difesa, ma consumano munizioni."],
		"now": "Aura DIFESA (cresce con la rarita', tetto +25%). PROTOCOLLO (solo ortodossi): chi viene colpito e resta in piedi prende +5% DIF e VEL per il round dopo e CONTRATTACCA il boss (x0,5) spendendo una munizione. Munizioni (max 3), Ricarica, Colpo mirato, Colpo alla testa.",
		"soon": "Azioni extra, reazioni su mosse specifiche dei boss, moduli di equipaggiamento.",
	},
	"rondini": {
		"idea": "Pattuglie di notte, colpi rapidi e precisi. Cannoni di vetro: fanno tanto danno ma reggono poco.",
		"win": "Vinci presto: abbatti il boss prima che le sue mosse forti ti raggiungano.",
		"needs": ["Schiera piu' Rondini: l'aura aumenta la probabilita' di colpo critico (x1,5 di danno).", "Agisci per primo: velocita' alta e mosse che anticipano il boss.", "Non farti colpire: tieni dietro un vanguard o un warden."],
		"now": "Aura CRITICO (cresce con la rarita', tetto +25%). Colpo critico nel gioco, deterministico anche online.",
		"soon": "Mosse ad area, danni alti, ronda (azioni di gruppo), tratti da cannone di vetro.",
	},
	"magabondi": {
		"idea": "Maghi senza licenza: niente schemi, ognuno ha la sua trovata. Tutto cio' che non e' convenzionale.",
		"win": "Vinci con il tempismo: guadagni azioni, ordine e risorse dove gli altri non possono.",
		"needs": ["Non danno aure ma ne ricevono meta' dalla piu' forte in squadra: affianca una fazione con aura.", "Costruisci il turno: le azioni extra le pianifichi tu."],
		"now": "Ricevono meta' dell'aura piu' forte della squadra.",
		"soon": "Economia delle azioni, trovate uniche per ogni operatore, magia illegale con contraccolpo.",
	},
	"kairos": {
		"idea": "Demoni da un altro piano. Legano, indeboliscono, avvelenano: non uccidono in fretta, ti consumano.",
		"win": "Vinci per logoramento: la squadra avversaria perde forza ogni turno.",
		"needs": ["Spegni le aure avversarie con la Dissonanza.", "Accumula veleno e danni nel tempo, poi proteggiti mentre agiscono.", "Controlla chi puo' agire: legature, sigilli, stordimenti."],
		"now": "Spegnimento delle aure di una fazione (pronto nel motore), sanguinamento e marchio.",
		"soon": "Legature, sigilli sulle skill, veleno, stordimenti e debuff completi.",
	},
}

const STYLES: Dictionary = {
	"ortodosso": "Segue la dottrina della fazione: da' e riceve l'aura per intero.",
	"atipico": "Gioca a modo suo: aura data e ricevuta dimezzata, ma +8% ATK e +5% VEL.",
}


static func class_text(cls: String) -> Dictionary:
	return CLASSES.get(cls, {})


static func faction_text(faction: String) -> Dictionary:
	return FACTIONS.get(faction, {})


# Pagine per la guida: [{title, lines: [{text, color}]}]
static func pages() -> Array:
	var out: Array = []
	for cls in BattleTypes.CLASSES:
		var c: Dictionary = CLASSES[cls]
		var lines: Array = [
			_line(str(c["role"]), BattleTheme.CY),
			_line("COSA FA: " + str(c["does"])),
			_line("PER FARLO FUNZIONARE:", BattleTheme.GOLD),
		]
		for n in c["needs"]:
			lines.append(_line("- " + str(n)))
		out.append({"title": "CLASSE " + str(c["label"]), "lines": lines})
	for f in Factions.ORDER:
		var d: Dictionary = FACTIONS[f]
		var info: Dictionary = Factions.FACTIONS[f]
		var lines: Array = [
			_line("%s - %s" % [str(info["name"]).to_upper(), str(info["doctrine"]).to_upper()], BattleTheme.RD),
			_line(str(d["idea"])),
			_line("COME SI VINCE: " + str(d["win"]), BattleTheme.GOLD),
		]
		for n in d["needs"]:
			lines.append(_line("- " + str(n)))
		lines.append(_line("GIA' NEL GIOCO: " + str(d["now"]), BattleTheme.CY))
		lines.append(_line("IN ARRIVO: " + str(d["soon"]), BattleTheme.CY_DIM))
		out.append({"title": str(info["name"]).to_upper(), "lines": lines})
	var style_lines: Array = []
	for s in Factions.STYLES:
		style_lines.append(_line(str(s).to_upper(), BattleTheme.CY))
		style_lines.append(_line(str(STYLES[s])))
	style_lines.append(_line("Cambi lo stile dalla scheda dell'operatore (bottone STILE), gratis, quando vuoi.", BattleTheme.CY_DIM))
	out.append({"title": "ORTODOSSO O ATIPICO", "lines": style_lines})
	return out


static func _line(text: String, color: Color = BattleTheme.WH) -> Dictionary:
	return {"text": text, "color": color}
