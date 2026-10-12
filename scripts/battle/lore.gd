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
		"tactic": "CURA chi scende sotto meta' vita; RINASCITA cura e toglie i malus a tutti. L'entrata scudata la rende ottima da far entrare a meta' battaglia.",
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
		"tactic": "PURIFICA solo quando c'e' un malus da togliere. RINASCITA per rimettere in piedi tutti. L'entrata scudata protegge chi la sostituisce.",
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
		"tactic": "BARRIERA sulla squadra, RINASCITA quando serve davvero. CACCIATORE la rende pericolosa contro un boss sotto meta' vita.",
	},
	"tana": {
		"tag": "Baluardo leggendario",
		"lore": "Quando arriva lei, la strada si chiude. Leggenda di quartiere: dicono che nessuna anomalia le abbia mai fatto passare un colpo.",
		"tactic": "PROVOCA per prendere su di se' il colpo, BASTIONE per coprire gli altri. Il suo CACCIATORE trasforma la difesa in danno quando il boss e' sotto meta' vita.",
	},
}

# Termini del gioco: [titolo, spiegazione]. Le cifre arrivano dal codice.
static func glossary() -> Array:
	return [
		["ENERGIA", "Serve per le skill. Massimo %d. Chi e' in campo ne recupera %d a round, chi e' in panchina %d. La GUARDIA ne da' 1." % [BattleTypes.MAX_ENERGY, BattleTypes.REGEN_ACTIVE, BattleTypes.REGEN_BENCH]],
		["ULTIMATE", "La barra si carica colpendo (+%d) e venendo colpiti (+%d). A %d puoi usare l'ultimate, senza costo di energia." % [BattleTypes.GAUGE_ON_HIT, BattleTypes.GAUGE_ON_DAMAGED, BattleTypes.GAUGE_MAX]],
		["COLORI", "Rosso batte verde, verde batte blu, blu batte rosso; giallo e viola si battono a vicenda. Colore giusto: danno x%.1f. Colore sbagliato: x%.2f." % [BattleTypes.COLOR_ADVANTAGE, BattleTypes.COLOR_DISADVANTAGE]],
		["ALLARME", "Il boss annuncia un round prima la mossa e il bersaglio. Leggila sempre prima di scegliere."],
		["CAMBIO", "Scambiare l'operatore in campo e' gratuito e avviene prima di ogni azione. In panchina si recupera piu' energia."],
		["GUARDIA", "Dimezza il danno subito in quel round (x%.1f) e ridona energia." % BattleTypes.GUARD_FACTOR],
		["SCUDO", "Assorbe danno prima dei PV. Lo danno Barriera, Bastione, Provoca e l'entrata scudata."],
		["PROVOCAZIONE", "Il boss, se puo', colpisce chi provoca. Utile per proteggere chi fa danno."],
		["MARCHIO", "Il bersaglio marchiato subisce +%d%% di danno per qualche turno." % int(round((BattleTypes.MARK_BONUS - 1.0) * 100.0))],
		["SANGUINAMENTO", "Danno ogni round pari al %d%% dei PV massimi. Si toglie con Purifica o Rinascita." % int(round(BattleTypes.BLEED_FRACTION * 100.0))],
		["FURIA DEL BOSS", "Sotto meta' PV il boss colpisce piu' forte (+%d%%)." % int(round((BattleTypes.ENRAGE_BONUS - 1.0) * 100.0))],
		["CACCIATORE", "Passiva: +%d%% di danno contro chi e' sotto meta' PV." % int(round((BattleTypes.HUNTER_BONUS - 1.0) * 100.0))],
		["LIVELLO E RANK", "Il livello si compra con monete e nuclei. Il rank sale con le copie: +%d%% di statistiche a rank." % int(round(BattleContent.RANK_BONUS * 100.0))],
		["FAZIONE", "Gruppo a cui appartiene un operatore: LibraCorp, Rondini, Magabondi, Kairos. Da' un'AURA ai compagni della stessa fazione."],
		["AURA", "Bonus passivo a una statistica per i compagni di fazione. Cresce con la rarita' di chi la da', con tetto +%d%%. Sparisce se chi la da' e' a terra." % (Factions.AURA_CAP_PM / 10)],
		["CRITICO", "Probabilita' di colpo che fa x%.1f di danno. Lo aumentano le aure delle Rondini." % (float(Factions.CRIT_DMG_PM) / 1000.0)],
		["STILE", "Ortodosso: segue la dottrina, aura intera. Atipico: aura dimezzata, ma +8% ATK e +5% VEL. Si cambia dalla scheda."],
		["VALUTE", "Monete (reclutare e potenziare), Nuclei (livello degli operatori), Leghe (livello dei pezzi di equipaggiamento)."],
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
