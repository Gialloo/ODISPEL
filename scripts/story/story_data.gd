class_name StoryData
extends RefCounted

# Le scene di storia incluse nel gioco. Per cambiarle senza toccare il codice basta
# creare un file `<id>.txt` nella cartella `dialogues` accanto all'eseguibile (o in
# user://dialogues): ha la precedenza su queste. Formato in dialogue_script.gd.

const SCENES: Dictionary = {
	"distributore_pre": """
@bg strada_notte
*: CAM-07, Via S. Giorgio. Notte. Il parcheggio di Park 3 e' deserto. Quasi.
*: Tre persone che non dovrebbero trovarsi nello stesso posto, arrivate per tre ragioni diverse, nello stesso minuto.
kira [neutral] L: Rondini non fanno rapporto a nessuno. Ma il segnale su questo distributore l'ho letto io per prima.
dax [angry] R: Sergente Dax, LibraCorp, turno notte. Quel segnale era un mio affare. E tu hai una rondine tatuata sul polso.
kira [angry]: E tu hai un badge con la bilancia. Ottimo. Non vedevo l'ora di incontrare la corporazione.
elle [happy] L: Io sono solo di passaggio. I Magabondi non hanno bandiere. Piacere, Elle. Ho delle erbe e un taccuino.
dax [surprised] R: Un magabondo. Con del tè.
*: Un tonfo. Le serrande del parcheggio calano da sole, tutte e tre. Sul muro, un contatore rosso parte da 7:00.
elle [surprised] L: Sette minuti. Qualcuno ci ha chiusi dentro. E non siamo noi.
dax [neutral]: Allora il lavoro e' uno solo. Ed e' li, nell'angolo.
distributore [angry] R: BZZZ. SCARICA. SCARICA. SCARICA.
elle [sad] L: Dax... guarda il display. Non dice ESAURITO. Dice il tuo nome.
dax [surprised]: ...
kira [angry]: Squadra, formazione. Litigate dopo. Adesso ci serve ognuno di voi.
""",
	"distributore_post": """
@bg strada_notte
*: Il distributore si spegne con un ultimo ronzio. Dal vetro cadono monete e qualcosa che somiglia a un nucleo.
elle [happy] L: Abbiamo i nuclei. Ora possiamo potenziare la squadra.
dax [neutral] R: Resta il fatto che mi ha chiamato per nome. E il contatore non si e' fermato.
*: Sul contatore la cifra salta: 6:59... 6:59... 6:59. Il tempo ha smesso di scorrere. Dal display morto esce una voce sottile, che ripete.
eco [sad] R: Dax. Dax. Kira. Elle. Dax.
kira [surprised] L: Si e' attaccata alle nostre voci. Come un'eco.
eco [neutral] R: Non voglio scaricare. Voglio uscire. Voi uscite. Io... vengo?
dax [angry]: Protocollo LibraCorp: ogni anomalia viene contenuta e consegnata. Fine della discussione.
kira [angry] L: Consegnata a chi? A voi? Per farne cosa?
> Portiamola con noi -> insieme
> Seguiamo il protocollo -> protocollo
:insieme
elle [happy] L: Ha il tuo nome in bocca, Dax. Non scappera' mai lontano da noi. Prendiamola con noi.
@goto fine
:protocollo
dax [neutral] R: La contengo io, in squadra, sotto i miei occhi. E' contenere, no?
elle [happy] L: E' esattamente quello che stavamo dicendo, con un'altra parola.
:fine
eco [happy] R: Eco. Mi chiamo Eco. L'ho appena deciso.
*: Eco si unisce alla squadra. Una guardia LibraCorp, una Rondine, una Magabondo e un'anomalia. Nessuno l'avrebbe scommesso.
kira [neutral] L: Ci serve un'uscita. Ho visto un incrocio, poco lontano, dove i semafori impazziscono. Se c'e' un percorso, parte da li.
""",
	"semaforo_pre": """
@bg incrocio
*: L'incrocio di Via S. Giorgio. Il semaforo cambia colore ogni secondo, senza ritmo.
bruno [neutral] L: Qui Bruno, centrale LibraCorp. Sergente Dax, il tuo segnale e' tornato. State bene?
dax [neutral] R: Quattro presenti. Nessun ferito. Bruno, ti spiego dopo.
bruno [surprised] L: Quattro? Il rapporto dice tre operatori.
eco [neutral] R: Quattro. Io sono Eco. Sono il quattro.
bruno [surprised] L: ...Dax, di' alla tua amica che questa linea e' registrata.
semaforo [angry] R: ROSSO. ROSSO. NESSUNO PASSA.
elle [sad] L: Le auto si fermano a caso. Qualcuno si fara' male.
kira [neutral]: Ha uno schema. Rosso e' un colpo solo, verde colpisce tutti, giallo si ricarica. Lo leggiamo.
dax [neutral]: Lo hai letto in tre secondi. Rondine, come fai?
kira [happy]: Corro sui tetti da quando avevo undici anni. Il mondo si legge meglio dall'alto. Voi del piano terra guardate solo i semafori.
eco [happy] R: Rosso e' arrabbiato. Giallo ha paura. Verde e' contento. E io... che colore sono?
semaforo [angry] R: GIALLO. ATTENDERE.
""",
	"semaforo_post": """
@bg incrocio
*: Il semaforo si spegne. Per la prima volta in ore, la strada e' silenziosa.
dax [neutral] R: Kira. Prima. Tu sapevi il mio cognome. Orsini.
kira [neutral] L: LibraCorp ha un fascicolo su ogni Rondine. Noi abbiamo imparato a leggere i vostri turni. So che a Natale fai sempre la guardia agli altri.
dax [sad]: ...Lavoro il Natale perche' non ho nessuno che mi aspetti.
elle [happy] L: Adesso ne hai tre. E mezzo. Eco conta mezzo.
eco [happy] R: Mezzo e' piu' di zero!
bruno [neutral] L: Dax, ordine dalla centrale. Devi consegnare l'anomalia alla torre. Subito.
dax [angry] R: ...Ricevuto. Fine trasmissione.
kira [angry] L: Hai un ordine su Eco e non ce l'hai detto.
dax [sad]: Lo so. Ma ho anche un orecchio che sente Eco ridere. Non so cosa fare.
elle [surprised]: Sento acqua, sotto di noi. Il tombino. Si sta muovendo.
""",
	"tombino_pre": """
@bg tombino
*: Sotto il coperchio del tombino, qualcosa respira. Elle si ferma, e per un attimo sembra molto piu' giovane.
elle [sad] L: Io ci sono cresciuta, nei tunnel. I Magabondi mi hanno trovata la' sotto, a otto anni, con una coperta che non era mia.
kira [surprised] R: Elle... non lo sapevo.
elle [neutral] L: Non l'ho mai detto a nessuno. Regola nostra: nessuno resta indietro. L'ho imparata quella notte.
tombino [angry] R: ...HO FAME. ...HO FREDDO.
eco [sad] R: Ho fame. Ho freddo. Lo dice come lo direi io, quando non avevo parole.
dax [neutral] L: E' il motivo per cui sono tutte qui. Ogni anomalia cerca di dire una cosa sola.
> Lo combattiamo comunque -> combatti
> Proviamo a parlargli -> parla
:parla
elle [sad]: Come ti chiami?
tombino [sad] R: NESSUNO LO RICORDA PIU'.
kira [neutral] L: Allora ti ricorderemo noi. Ma prima devi fermarti.
@goto fine
:combatti
dax [angry] L: Non c'e' tempo. Sta salendo.
:fine
tombino [angry] R: ...AVVICINATI.
""",
	"tombino_post": """
@bg tombino
*: L'acqua si ritira. Il coperchio si richiude piano, senza rumore.
elle [happy] L: Se ne e' andato. Credo che ora dorma. Nessuno resta indietro, no?
dax [neutral] R: Tieni. E' la mia sciarpa. Fa freddo, qui sotto, e tu non hai detto niente.
elle [surprised]: Dax... hai un cuore sotto il badge.
dax [angry]: Nessuno deve saperlo. Ordine del sergente.
kira [happy] L: Tutta la squadra lo sapra' entro sera. Incluso Bruno.
bruno [surprised] R: Ho sentito tutto. Linea registrata, ricordi? Stasera ne parlo con il cuoco della mensa.
*: Sul monitor, un'altra luce si accende. CAM-08.
""",
	"cabina_pre": """
@bg cabina
*: CAM-08. Un angolo dimenticato, dietro la stazione. Una cabina telefonica, senza apparecchio. Eppure squilla.
elle [surprised] L: Non c'e' nessun filo. Non puo' squillare.
kira [neutral] R: Le altre erano mostri. Questa ci sta chiamando.
dax [sad] L: ...Quel suono. E' lo stesso del telefono di servizio. Quello della notte in cui Marta non mi ha risposto. O io non ho risposto a lei.
eco [neutral] R: Marta. Marta. Dax dice sempre Marta quando dorme.
dax [angry]: Eco. Basta.
cabina [neutral] R: PRONTO? PRONTO? CHI PARLA?
> Rispondiamo -> risposta
> Riagganciamo -> aggancia
:risposta
kira [neutral] L: Siamo la squadra di sorveglianza. Chi sei?
cabina [sad] R: LA VOCE DI CHI NON HA PIU' RISPOSTO.
@goto fine
:aggancia
dax [angry] L: Non si risponde a un mostro. Si spegne.
cabina [angry] R: NON RIAGGANCIARE. NON RIAGGANCIARE.
:fine
dax [sad] R: Squadra. Se vado in difficolta' voi coprite. Questa e' la mia.
kira [happy] L: Non sei piu' da solo, sergente. Formazione.
""",
	"cabina_post": """
@bg cabina
*: La cornetta ricade. Il telefono tace. Nella cabina resta solo un gettone, ancora caldo.
dax [sad] R: Marta era la mia collega. Una notte e' rimasta in linea e io ero al piano di sotto, a controllare una serranda. Non ho sentito il telefono.
elle [sad] L: Non e' colpa tua.
dax [neutral]: Lo so. Adesso lo so. Prima no. Grazie.
kira [neutral] L: Guardate il monitor. Le quattro telecamere formano un cerchio sulla mappa.
*: Al centro del cerchio, una quinta luce. Nessun nome. Solo un numero: CAM-00.
eco [surprised] R: Io... conosco quel posto. Lo conosco da prima di avere un nome.
bruno [surprised] L: Squadra, qui Bruno. CAM-00 e' dentro la torre LibraCorp. L'ascensore E' l'unico accesso. E c'e' un piano che non appare in nessun registro.
dax [angry] R: La mia torre. Allora ci vado io. Per prima.
""",
	"ascensore_pre": """
@bg torre
*: La torre LibraCorp, ore piccole. Nell'atrio, solo le luci di emergenza. L'ascensore e' aperto. Dentro, un pulsante in piu': -1.
bruno [neutral] L: Dax, ho il badge che ti serve. Ma ti avviso: il piano -1 non e' mai esistito. Non su carta.
dax [neutral] R: Esiste eccome. L'hanno chiamato Piano Zero. Lo sapevo. Tutti nel turno di notte lo sapevamo.
kira [angry] L: Lo sapevate? Una corporazione che tiene anomalie sotto una torre e dice di proteggere la citta'?
dax [sad]: Dicevano: contenere. Non e' molto lontano da quello che fate voi Rondini. Voi la chiamate sorveglianza.
elle [neutral] R: Chi ha ragione e' una domanda per dopo. Il piano e' da qualche parte sotto di noi.
ascensore [angry] R: SERGENTE ORSINI. RIENTRI NEI RANGHI. CONSEGNI L'ANOMALIA.
eco [sad] R: E' la voce del tuo capo, Dax. Non e' lui. Ma ha la sua voce. Fa male.
dax [angry]: Lo so.
> Seguo il protocollo -> protocollo
> Rispondo a loro, non a lui -> squadra
:protocollo
dax [neutral]: Ho giurato. Ma sono stato io a scegliere chi proteggere stanotte.
@goto fine
:squadra
dax [angry]: Il mio turno e' finito. Adesso rispondo alla mia squadra.
:fine
ascensore [angry] R: PORTE IN CHIUSURA. NESSUNO ESCE.
""",
	"ascensore_post": """
@bg torre
*: Le porte si bloccano, a meta'. Dal fondo del pozzo sale una luce fredda. Il pulsante -1 si spegne.
bruno [happy] L: Ce l'avete fatta. E' la seconda cosa che non ho previsto, stasera.
dax [neutral] R: La prima?
bruno [neutral] L: Il tuo ordine di consegna. L'ho cancellato io, dieci minuti fa. Eco resta con voi.
dax [surprised] R: Bruno. Rischi il posto.
bruno [happy] L: Ho una scrivania. Voi avete un pianeta. Scelgo la scrivania ma da un altro posto.
*: Dall'ascensore cade una cartellina. Dentro, un solo foglio. PROGETTO KAIROS - SETTE MINUTI.
elle [surprised] L: 'Un giorno sottratto al tempo. Un'eco rimasta in ogni macchina.' Eco...
eco [sad] R: E' di me, quel foglio. Lo sento.
kira [neutral] L: Non adesso. Prima gli ultimi due: il negozio qui accanto e la torre dell'orologio. Ma il negozio...
kira [sad] L: ...il negozio e' casa mia.
""",
	"manichino_pre": """
@bg vetrina
*: Una vetrina chiusa in Via dei Sarti. Dietro il vetro, manichini immobili. Uno ha la sciarpa rossa dei Rondini.
kira [sad] L: Questo era il nostro rifugio. Nico lo teneva aperto per tutti. Fino a sette mesi fa.
elle [neutral] R: Nico era il tuo...
kira [neutral] L: Il mio capo. Il mio maestro. Mi ha insegnato a correre sui tetti. Poi un giorno non e' tornato.
eco [surprised] R: Il manichino. Ha la sua faccia. Ha la sciarpa di Nico.
dax [neutral] L: E' una copia. Le anomalie copiano cio' che manca di piu'. Kira, non guardarlo.
kira [angry]: Non scappo piu'. Ho scappato per sette mesi. Adesso lo guardo.
manichino [neutral] R: KIRA. PERCHE' NON SEI VENUTA A CERCARMI?
kira [sad]: Perche' avevo paura, Nico. Ma ora non sono sola.
dax [happy] L: Non lo sei. Forma la fila, rondine.
manichino [angry] R: ALLORA POSA PER ME.
""",
	"manichino_post": """
@bg vetrina
*: Il vetro si incrina e cade a pezzi, senza rumore. Il manichino resta a terra, immobile, con la sciarpa rossa al collo.
kira [sad] L: Non era lui. Ma mi ha ascoltata. E io ho detto quello che non avevo mai detto.
dax [neutral] R: Tieni. E' tutto quello che posso darti oggi.
*: Dax allunga una piuma d'argento, la spilla della sua unita'. Per la prima volta, un LibraCorp offre qualcosa a una Rondine.
kira [surprised] L: La tua spilla di servizio? Dax...
dax [happy]: Non e' un regalo. E' una promessa: la prossima volta ti vengo a cercare io.
elle [happy] R: Sono commossa e ho pianto nel taccuino.
eco [happy] R: Kira. Viola. Come il cielo prima della pioggia. Adesso lo so cos'e' un colore.
kira [happy] L: Ultimo bersaglio. La torre dell'orologio. CAM-00.
bruno [neutral] R: Squadra, la torre e' sigillata. Ma Eco sa dove entrare. Vero?
eco [neutral] R: ...Si. E ho paura.
""",
	"orologio_pre": """
@bg torre_orologio
*: CAM-00. La piazza sotto la torre dell'orologio. Le lancette segnano le 6:59 e non si muovono.
eco [sad] R: Ricordo. Ero l'ultimo minuto. Quando l'orologio si e' rotto, i sette minuti sono rimasti vuoti, e io sono nato dentro il vuoto.
elle [sad] L: Sei nata dentro una mancanza. Come tutti noi.
eco [neutral] R: Le altre anomalie erano pezzi dell'orologio. Distributore, semaforo, tombino, cabina... quello che manca a una citta' quando il tempo si ferma.
dax [neutral] R: Se fermiamo l'orologio, la bolla si chiude. E tu?
eco [sad]: Forse sparisco. Forse resto. Non lo so.
kira [angry] L: Non ti lasciamo indietro. Nessuno resta indietro. Elle lo ha detto per prima.
> Fermiamo l'orologio -> ferma
> Troviamo un altro modo -> altro
:ferma
dax [neutral] R: Allora lo fermiamo insieme. Tutti e quattro, nessuno da solo.
@goto fine
:altro
elle [happy] L: Un altro modo c'e' sempre. Io conosco tre scorciatoie.
@goto fine
:fine
orologio [angry] R: DONG. DONG. DONG. L'ORA E' FINITA. TUTTI FERMI.
eco [happy] R: Io non sono ferma. Io sono Eco. Questo e' il mio nome, e questa e' la mia squadra!
""",
	"orologio_post": """
@bg torre_orologio
*: L'orologio si ferma. Le lancette cadono, e per un istante tutto tace. Poi, una campana. Una sola. L'alba.
eco [surprised] R: Sono ancora qui. Non sono sparita.
elle [happy] L: Eco. Hai un nome. Hai un gruppo. Non puoi sparire.
dax [happy] R: Rapporto finale: quattro operatori e zero perdite. E un'anomalia, ufficialmente, diventata... collega.
kira [happy] L: Il comune di questa citta' ha una Rondine, un LibraCorp, una Magabondo e una cosa del tutto nuova nella stessa squadra.
bruno [happy] R: Sul registro scrivo 'squadra speciale CAM'. Che nome vi do?
dax [neutral] R: ...Lasciali scegliere.
eco [happy] R: Voi quattro. Tutti e quattro. Per sempre.
*: Sulla mappa, il cerchio si chiude. E fuori dal cerchio, lontano, una nuova luce si accende. Ma questa e' un'altra storia.
*: FINE DELLA PRIMA STAGIONE.
""",
	"specchio_pre": """
@bg torre_orologio
*: Dietro il quadrante rotto dell'orologio, c'e' una stanza che nessuna mappa segnava. Al centro, uno specchio alto fino al soffitto.
eco [surprised] R: Questo non c'era. Non l'ho mai sentito.
kira [neutral] L: Ci siamo tutti. Ma... guardate. Sul vetro la sciarpa di Nico e' ancora al suo posto.
dax [neutral] R: Un riflesso che non sa che il tempo si e' fermato. O che ha ricominciato.
elle [sad] L: Siamo noi, se non ci fossimo mai incontrati. Ognuno nel suo pezzo di citta'.
specchio [angry] R: PERCHE' VOI E NON NOI? NOI ERAVAMO PRIMA.
bruno [neutral] R: Squadra, e' un'anomalia fuori dalla classificazione. Il registro non ha una riga per questo.
kira [angry] L: Allora gliela scriviamo noi.
""",
	"specchio_post": """
@bg torre_orologio
*: Lo specchio si incrina da un angolo all'altro. Ogni scheggia mostra la squadra da un'altra parte, a fare altre cose, in una citta' diversa.
elle [happy] L: Guardate. In alcune siamo comunque insieme.
dax [happy] R: Statisticamente trascurabile. Ma lo ammetto: mi piace.
eco [happy] R: Ogni scheggia e' un'ora in piu'. Non una in meno.
kira [happy] L: Allora teniamone una. Per ricordarci che questa e' quella vera.
*: Una scheggia piu' piccola delle altre cade nella mano di Kira. Dentro, per un istante, una luce che non e' il suo riflesso.
*: Fine dell'extra della prima stagione.
""",
}


# Testo di una scena: prima i file dell'utente, poi quelli inclusi.
static func text(scene_id: String) -> String:
	var loop: MainLoop = Engine.get_main_loop()
	var folders: Array = [
		OS.get_executable_path().get_base_dir().path_join("dialogues"),
		ProjectSettings.globalize_path("user://dialogues"),
	]
	for f in folders:
		var path: String = str(f).path_join(scene_id + ".txt")
		if FileAccess.file_exists(path):
			return FileAccess.get_file_as_string(path)
	return str(SCENES.get(scene_id, ""))


static func has_scene(scene_id: String) -> bool:
	return text(scene_id) != ""
