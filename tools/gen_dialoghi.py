# Genera data/dialoghi_atto1.json: la sceneggiatura dell'atto 1 (prologo, capitoli 1-5, finale) e le chiacchiere.
#
# VOCI
# Regola del gruppo: Lance organizza, Saul sfrutta, Rio spettacolarizza, Nox evita altre sei ore di lavoro.
# Lance e Saul sono i combattenti veterani, fighi senza volerlo; Rio vuole sembrare figo a tutti i costi.
# La comicita' nasce dal contrasto tra loro, non dall'incompetenza.
#  Lance (id ferri) - 23, LibraCorp. Il Braccio della Legge. Articoli del regolamento (anche inventati), "lo metto a verbale",
#           taccuino, l'orologio (dice l'ora al secondo, "siamo in ritardo di quattro secondi"). Chiama Rio "minorenne".
#           Rigido perche' ha paura: il braccio magico e' il suo segreto. Cresce: dalle regole alle persone.
#  Nox    - 24, Civette. Frasi corte e asciutte, conta le ore senza dormire, il thermos del caffe', il divano. Cinica per
#           stanchezza, non per cattiveria. La notte delle 3:12 e' la sua ferita. Cresce: torna a rispondere quando qualcuno chiama.
#  Rio (id zecca) - 19, Masca. Il Re del Circo. Parla come un presentatore a un pubblico che non c'e' ("raga", "signore e
#           signori", titoli in MAIUSCOLO), vuole l'entrata, la ripresa, il merito. 32 follower, la batteria sempre a zero.
#           Dice sempre quello che sente, anche troppo. Cresce: si fa vedere senza maschera
#           (nell'atto 1 la maschera si incrina e basta: toglierla e' il climax del suo arco, non arriva qui).
#  Saul   - 22, Magabondo. Il Favorito del Caos. Parla come un negoziatore: rilassato, mezze verita', una scappatoia in ogni
#           frase. MAI punti esclamativi, niente gergo. Da' un prezzo a tutto e tiene il conto (con gli interessi).
#           Proverbi di nonne inventate ("Quale nonna?" "Ne ho tre"). Non dice cosa prova: lo fa. Cresce: smette di contare.
# GAG DA FUGGITIVI (gag, poi ricorrenza; il payoff vero arriva al climax di ogni arco, non nell'atto 1): il distributore
#  (Saul col colpetto, Lance che ci prova di nascosto), il divano del rifugio, la batteria di Rio, l'orologio di Lance,
#  il conto di Saul, il thermos di Nox, "non dobbiamo dare nell'occhio", i nomi falsi, il pasto da cinque minuti.
#  Echo   - un Kairos, femminile, vive nelle telecamere. Precisa (orari, numeri delle telecamere), curiosa degli umani,
#           impara a scherzare e le battute le vengono male. Si affeziona davvero, ed e' per questo che il tradimento fa male.
import json, sys

COL = {"echo": "#3fe0ff", "COMANDANTE ASTRID": "#ff4b4b", "RADIO LIBRACORP": "#ff4b4b", "STRIX": "#3f9dff",
       "VOCE SENZA VOLTO": "#c9c3d6", "VOCE AL TELEFONO": "#9fc4ff", "SEMAFORO": "#ff4b4b", "CABINA": "#3f9dff",
       "MANICHINO": "#46e07a", "CASSAFORTE": "#46e07a", "AUTOVELOX": "#ffd23f", "AVVISO": "#ffd23f",
       "DISTRIBUTORE": "#ffd23f"}
CAST = {"ferri", "nox", "zecca", "saul"}


def L(spec, testo, **kw):
    chi, _, espr = spec.partition("/")
    r = {"chi": chi}
    if chi in CAST:
        r["espr"] = espr or "neutro"
    else:
        r["col"] = COL[chi]
        if chi == "echo":
            r["espr"] = espr or "neutro"
    r["testo"] = testo
    r.update(kw)
    return r


S = {}


def scene(key, recap, *righe):
    S[key] = {"riassunto": recap, "righe": list(righe)}


def scelta(spec, testo, opts):
    return L(spec, testo, scelte=[dict(o) for o in opts])


# ================================================================== PROLOGO · LA NOTTE DELLA CUPOLA
# Diffidenza totale. Echo racconta e li presenta: chi inizia capisce chi sono, dove sono e perche' sono insieme.

scene("segreto_avviso", "Un boss segreto troppo forte per voi: lo avete lasciato stare.",
    L("saul/sorpreso", "Quella telecamera è grande quanto un lampione. E ci sta fissando."),
    L("zecca/felice", "Raga, sembra il boss segreto di un videogioco."),
    L("saul/neutro", "Allora sarà carissimo."),
    scelta("AVVISO", "Questo boss è troppo forte per te al momento. Sei sicuro di affrontarlo?",
        [{"testo": "NO, meglio di no"}, {"testo": "SÌ, affrontiamolo", "imposta": "segreto_si"}]))

scene("apertura", "Echo, un'entità che vive nelle telecamere, presenta quattro sconosciuti in piazza alle tre di notte. Il pacco di Saul si apre, una cupola chiude la città e gli schermi accusano proprio loro quattro. Sono costretti a scappare insieme.",
    L("echo/neutro", "Telecamera sette. Piazza Centrale. Ore 2:58. Una notte qualunque."),
    L("echo/neutro", "Mi chiamo Echo. Vivo nelle telecamere di questa città. Guardo. È l'unica cosa che so fare."),
    L("echo/neutro", "Quella seduta sulla panchina è Nox. Odispeller delle Civette: i maghi con la licenza. Turno di notte."),
    L("nox/triste", "Due minuti alla fine del turno. Poi doccia, letto, e nessuno mi chiama fino a giovedì."),
    L("echo/neutro", "Quello col berretto è Ferri. LibraCorp: la polizia che dà la caccia alla magia. L'hanno appena retrocesso a pattuglia."),
    L("ferri/serio", "Piazza Centrale, ore 2:58 e quaranta secondi. Tutto regolare. Una ragazza che dorme seduta. Un tizio con un pacco. Un minorenne che parla da solo."),
    L("echo/neutro", "Il «minorenne» si chiama Zecca. Ha diciannove anni e una maschera che gli dà poteri. Gli è arrivata per posta."),
    L("zecca/felice", "Buonasera raga, e benvenuti a un'altra puntata di RIO ALLE TRE DI NOTTE. Perché alle tre? Perché i contenuti non dormono!"),
    L("echo/neutro", "E quello col pacco è Saul. Contrabbandiere. Deve consegnarlo qui, alle tre in punto. Non sa cosa c'è dentro."),
    L("saul/neutro", "Tre in punto. Consegna, soldi, letto. Niente domande. Le domande costano."),
    L("echo/neutro", "Quattro sconosciuti di quattro fazioni che si odiano. Nessun motivo al mondo per parlarsi."),
    L("echo/serio", "E ognuno con un segreto che non può raccontare a nessuno. Ricordatevelo. È importante."),
    L("echo/serio", "Ore tre in punto. Il pacco si apre."),
    L("zecca/sorpreso", "Raga... il cielo. Il cielo è diventato ROSA. Non è un filtro. Ho provato a toglierlo tre volte."),
    L("nox/sorpreso", "È una cupola. Sopra tutta la città."),
    L("ferri/arrabbiato", "Nessuno si muova! LibraCorp! Voi tre: stato di fermo!"),
    L("saul/neutro", "Noi tre. Guarda gli schermi, capo."),
    L("echo/serio", "Su ogni schermo della città, quattro facce. «RESPONSABILI DEL SIGILLO. RICERCATI.»"),
    L("ferri/sorpreso", "...C'è la mia faccia. Perché c'è la mia faccia?"),
    L("nox/neutro", "Il mio turno è finito da un minuto. Sono ricercata da un minuto. Bene. Benissimo."),
    L("saul/serio", "Sirene. LibraCorp da una parte, Civette dall'altra. Vengono per noi."),
    L("ferri/serio", "Io non scappo dalla mia squadra. Mi spiegherò."),
    L("saul/neutro", "Fai pure. Ti arresteranno con l'uniforme in ordine."),
    L("nox/neutro", "Io scappo. Nessuno mi arresta prima del caffè."),
    L("zecca/felice", "Raga, cambio di programma: seguiamo quello col pacco. Ha la faccia di uno che sa scappare!"),
    L("saul/neutro", "Non seguirmi, ragazzino. Porto sfortuna. Agli altri. A me di solito va benissimo."),
    L("zecca/felice", "Allora mi metto dalla tua parte!"),
    L("ferri/arrabbiato", "...Articolo nove: in mancanza di ordini, si seguono i sospettati. Vi seguo. Per arrestarvi dopo."),
    L("echo/neutro", "E così cominciò. Quattro sconosciuti costretti a correre nella stessa direzione."),
    L("echo/serio", "Io li guardavo. Andava tutto come avevo previsto. Quasi tutto."))

scene("telecamera", "Una telecamera sembra seguire la squadra. Saul se ne accorge.",
    L("saul/serio", "Quella telecamera ci segue da tre isolati."),
    L("nox/neutro", "Le telecamere non girano la testa. Non da sole."),
    L("ferri/serio", "Regola numero uno per chi scappa: non dare nell'occhio."),
    L("zecca/felice", "Ciao! Raga, salutate, magari è un fan."),
    L("ferri/arrabbiato", "Rio. Che cosa ho appena detto?"),
    L("zecca/sorpreso", "Ma questo è il mio normale!"),
    L("nox/neutro", "È questo il problema."),
    L("saul/neutro", "La tua faccia è su ogni schermo della città, capo. Per non dare nell'occhio te ne servirebbe un'altra."))

scene("scontrino", "Indizio: il distributore rifiuta il viola. Forse lo teme.",
    L("saul/sorpreso", "Uno scontrino per terra. «Resto: un'anima. Monete VIOLA rifiutate.»"),
    L("saul/neutro", "Uno che rifiuta i soldi ha paura di qualcosa. Del viola, a quanto pare."),
    L("zecca/felice", "Viola? Ma è il MIO colore!"),
    L("saul/neutro", "Allora per una volta servi a qualcosa, ragazzino."))

scene("distributore", "Il distributore in fondo alla strada si sveglia: è un'Anomalia.",
    L("saul/serio", "Un distributore che ronza così alle tre di notte non vende merendine."),
    L("nox/neutro", "Ha la faccia. Le macchinette non hanno la faccia."),
    L("ferri/serio", "Indietro. Civili dietro di me."),
    L("saul/neutro", "Qui non ci sono civili, capo. Ci sono ricercati."),
    L("DISTRIBUTORE", "*KLANG* RESTO NON DISPONIBILE. INSERIRE... ANIMA."))

scene("agguato", "Il distributore attacca per primo.",
    L("DISTRIBUTORE", "*KLANG* CLIENTE INDECISO RILEVATO. ADDEBITO IN CORSO."),
    L("saul/sorpreso", "Stavo solo guardando la vetrina."),
    L("zecca/felice", "Aspettate, raga, mi serve un'entrata..."),
    L("ferri/serio", "Niente entrate. Distanza tre metri. Adesso."))

scene("vittoria", "L'Anomalia è chiusa.",
    L("zecca/felice", "Clip salvata! Questa fa il botto. Cioè, trentadue visualizzazioni. Ma col botto."),
    L("saul/neutro", "Un colpetto qui, sul fianco. Due merendine. Ci doveva il resto."),
    L("ferri/serio", "Questa è appropriazione."),
    L("saul/neutro", "È un rimborso, capo. Voleva addebitarci un'anima."),
    L("nox/neutro", "Qualcuno mi offre un caffè. Non da quello."))

scene("sconfitta", "La squadra è stata battuta.",
    L("nox/triste", "Bene. Benissimo. E il caffè chi me lo ripaga?"))

scene("accordo", "Echo si presenta: è un Kairos, vive nelle telecamere. La cupola è retta da quattro Anomalie: se le chiudono, lei consegna le registrazioni della piazza che li scagionano. E a ognuno promette quello che vuole di più: il grado a Lance, le ferie a Nox, la live dell'anno a Rio, le taglie a Saul.",
    L("echo/neutro", "Bel lavoro. Lo dico sul serio: era un distributore di prima categoria."),
    L("ferri/arrabbiato", "Chi parla? Identificati. Nome, grado, reparto."),
    L("echo/felice", "Echo. Niente grado. Niente reparto. Sono la telecamera sopra di voi. Ciao."),
    L("zecca/sorpreso", "Raga. La telecamera ha detto «ciao»."),
    L("echo/neutro", "Sono un Kairos. Una cosa che viene da un altro posto e che qui vive nei circuiti. Vedo tutta la città. Anche la cupola."),
    L("nox/serio", "Allora dicci cos'è, la cupola."),
    L("echo/serio", "Un sigillo. Si è acceso col pacco di Saul. Lo reggono quattro Anomalie: oggetti della città posseduti, come quel distributore. Solo più grossi."),
    L("saul/serio", "Il mio pacco. Mi avevano detto «documenti»."),
    L("echo/serio", "Chiudete le quattro Anomalie e la cupola cade. Io ho le registrazioni della piazza: dimostrano che non siete stati voi. Ve le do alla fine."),
    L("ferri/serio", "Perché noi? Mettiamo che ti credo. Le Anomalie le chiude LibraCorp. È il nostro lavoro."),
    L("echo/serio", "LibraCorp e Civette sono là fuori a dare la caccia a voi. Le Anomalie sono qui dentro. E voi siete già ricercati: non avete niente da perdere."),
    L("nox/neutro", "E tu cosa ci guadagni?"),
    L("echo/neutro", "Sono chiusa qui dentro come voi. Diciamo che cerchiamo la stessa porta."),
    L("saul/neutro", "Nessuno regala niente. Il prezzo lo scopriamo dopo. Sempre."),
    L("echo/neutro", "Allora parliamo di guadagni. Lance: chi chiude il caso della cupola torna in servizio. Col nome pulito. E col grado."),
    L("ferri/sorpreso", "...Col grado."),
    L("echo/neutro", "Nox: le Civette danno tre settimane di ferie per ogni Anomalia di classe alta chiusa. Sono quattro. Fanno dodici settimane."),
    L("nox/sorpreso", "Dodici settimane. Di sonno."),
    L("echo/felice", "Rio: una città sotto una cupola rosa, quattro mostri, e tu in diretta. La live dell'anno."),
    L("zecca/felice", "La live del DECENNIO. Raga, ci sto. Ci sto troppo."),
    L("echo/neutro", "Saul: LibraCorp paga una taglia per ogni Anomalia chiusa. Quattro taglie."),
    L("saul/neutro", "Quanto?"),
    L("echo/neutro", "Abbastanza da non dover più consegnare pacchi senza sapere cosa c'è dentro."),
    L("saul/neutro", "...Hai fatto i compiti."),
    L("echo/neutro", "Vi guardo da anni. È l'unica cosa che so fare."),
    L("zecca/felice", "Raga, una telecamera che parla e ci dà una missione. Questo è letteralmente un tutorial."),
    L("ferri/serio", "Mettiamola ai voti. Articolo quarantuno: in mancanza di superiori decide la squadra."),
    L("nox/neutro", "Non esiste un articolo quarantuno."),
    L("ferri/serio", "Esiste da adesso."),
    L("saul/neutro", "E da quando siamo una squadra?"),
    L("ferri/serio", "Da quando ci cercano tutti. Non è una squadra. È un'emergenza."),
    scelta("nox/neutro", "Allora. Ci fidiamo della telecamera parlante?",
        [{"testo": "«Affare fatto. Ma ti teniamo d'occhio.»", "imposta": "echo_diffidenza"},
         {"testo": "«Va bene. Guidaci.»", "imposta": "echo_fiducia"}]),
    L("echo/felice", "Giusto. Anch'io vi tengo d'occhio. È letteralmente l'unica cosa che so fare.", se="echo_diffidenza"),
    L("echo/felice", "Grazie. Non me l'aveva mai detto nessuno. Seguite le lucine rosse: vi porto in un posto asciutto.", se="echo_fiducia"))

scene("rifugio_arrivo", "Echo porta la squadra in un deposito della metro abbandonato: sarà il loro rifugio. Nessuno si fida di nessuno.",
    L("zecca/sorpreso", "Raga, benvenuti nella nuova casa. Room tour: topi, muffa e un divano. Il divano è il pezzo forte."),
    L("saul/neutro", "Il divano è mio. L'ho visto per primo."),
    L("ferri/serio", "Il divano va a turni. Articolo ventidue: il riposo si assegna per anzianità di servizio."),
    L("saul/neutro", "Allora è mio. Ho più anni di galera di tutti voi messi insieme."),
    L("ferri/arrabbiato", "La galera non è servizio."),
    L("saul/neutro", "Dipende da quale lato delle sbarre la guardi, capo."),
    L("nox/neutro", "Mentre discutevate mi ci sono sdraiata. Il divano è occupato. Parlate piano."),
    L("ferri/serio", "Turni di guardia. Due ore a testa. Il primo lo faccio io. Il secondo... non lo faccio fare a nessuno di voi."),
    L("nox/neutro", "Quindi fai tutti i turni."),
    L("ferri/serio", "Faccio tutti i turni."),
    L("saul/neutro", "Io dormo col pacco sotto la testa. Nessuno lo tocca."),
    L("zecca/serio", "Io dormo col telefono acceso. Nove per cento. Se mi rapiscono, almeno ho la diretta."),
    L("nox/felice", "C'è una macchinetta del caffè. Funziona. Chi mi riempie il thermos ha il divano dopo di me."),
    L("echo/neutro", "Nessuno di voi si fida degli altri. Me ne accorgo da come dormite."),
    L("nox/neutro", "Come dormiamo?"),
    L("echo/neutro", "Con un occhio aperto. Lo riconosco. Io ne ho centoquarantadue."),
    L("echo/serio", "Domani tocca a un semaforo. In un quartiere che uno di voi conosce bene."),
    L("ferri/serio", "...L'Incrocio Nove."))
# ================================================================== CAPITOLO 1 · ROSSO FISSO (Lance)
# Dalla diffidenza al primo segreto custodito: gli altri vedono il braccio di Lance e tacciono.

scene("c1_briefing", "All'Incrocio Nove il tempo si è fermato sul rosso. È il vecchio quartiere di pattuglia di Lance: guida lui.",
    L("echo/neutro", "Incrocio Nove. Il semaforo è rosso da sei ore. Le auto sono ferme. La gente dentro, anche."),
    L("ferri/serio", "Il mio vecchio giro di pattuglia. Ci ho fatto trecentododici multe."),
    L("saul/neutro", "Te le ricordi tutte?"),
    L("ferri/serio", "Sono a verbale. Una era tua."),
    L("saul/neutro", "Allora mi devi una macchina. Me l'avete rimossa."),
    L("ferri/serio", "Era in doppia fila davanti a una gioielleria. Col motore acceso."),
    L("saul/neutro", "Avevo fretta."),
    L("zecca/felice", "TITOLO: «La guardia e il ladro: la reunion». Raga, fa i numeri."),
    L("nox/neutro", "Gente ferma da sei ore. Muoviamoci, prima che diventino sette."),
    L("echo/serio", "Lance. Ci saranno pattuglie LibraCorp. Gente che conosci."),
    L("ferri/serio", "Siamo già in ritardo di quattro secondi. Guido io. In fila. E nessuno attraversa col rosso."))

scene("c1_radio", "Alla radio, la Comandante Astrid di LibraCorp dà la caccia alla squadra. È stata l'istruttrice di Lance.",
    L("RADIO LIBRACORP", "...a tutte le unità: i quattro della piazza sono considerati pericolosi. Priorità uno."),
    L("COMANDANTE ASTRID", "Qui Astrid. L'agente Lance è tra i sospetti. Se lo trovate, lo voglio io. Vivo. E in ordine."),
    L("ferri/triste", "La Comandante Astrid. Mi ha insegnato a rifare la branda. E tutto il resto."),
    L("zecca/serio", "Ti vuole vivo, però. È una cosa buona, no?"),
    L("ferri/serio", "Con Astrid, «vivo» è la parte brutta."),
    L("saul/neutro", "Se ti ha insegnato tutto, sa anche dove scappi. Allora scappiamo dove non ti ha insegnato."),
    L("ferri/serio", "...Non è un brutto ragionamento. Non abituarti."))

scene("c1_multa", "Indizio: il semaforo teme il blu dei lampeggianti.",
    L("ferri/serio", "Una multa sotto il tergicristallo. «Passaggio col rosso. Tempo di attesa: per sempre.»"),
    L("nox/sorpreso", "Gira il foglio. «Esenti: veicoli di soccorso. Luce BLU.»"),
    L("nox/neutro", "Io non sono un veicolo di soccorso. Sono una dipendente pubblica stanca."),
    L("ferri/sfotto", "Oggi sei un lampeggiante, collega. Lo metto a verbale."),
    L("nox/neutro", "Collega. Mi hai appena chiamata collega."),
    L("ferri/serio", "...Errore di battitura. Orale."))

scene("c1_soglia", "Il semaforo è il cuore dell'Anomalia: la squadra ci entra.",
    L("ferri/serio", "Da vicino il rosso sembra un occhio."),
    L("echo/serio", "È la soglia. Toccatelo e siete dentro. Lì le mie telecamere non arrivano. Non vi vedrò."),
    L("zecca/felice", "Quindi niente regia. Si improvvisa. Il mio genere!"),
    L("saul/neutro", "Il tuo genere è cadere dalle scale in diretta, ragazzino."),
    L("zecca/sorpreso", "Ventimila visualizzazioni! È il mio video migliore!"),
    L("echo/neutro", "...Tornate. Ho già cominciato a contarvi. Mi scoccerebbe ricominciare."))

scene("c1_boss", "Il Semaforo si sveglia: ferma chi sbaglia, per sempre.",
    L("SEMAFORO", "ALT. ALT. NESSUNO PASSA. NESSUNO SBAGLIA. NESSUNO SI MUOVE MAI PIÙ."),
    L("ferri/serio", "Su una cosa ha ragione. Qualcuno deve fermarsi."),
    L("ferri/arrabbiato", "Lui."))

scene("c1_agguato", "Il Semaforo attacca per primo.",
    L("SEMAFORO", "INFRAZIONE RILEVATA. SANZIONE IN CORSO."),
    L("ferri/sorpreso", "Eravamo fermi! Era rosso! Ci siamo fermati col rosso!"))

scene("c1_braccio", "Nella lotta il guanto di Lance si strappa: il suo braccio è tecnologia magica di contrabbando. Gli altri lo vedono e decidono di tacere. È il primo segreto che custodiscono insieme.",
    L("zecca/sorpreso", "Lance... il tuo braccio. Brilla. Perché brilla?"),
    L("ferri/arrabbiato", "Non avete visto niente."),
    L("nox/serio", "Tecnologia magica di contrabbando. LibraCorp ne sequestra a tonnellate. Poi la monta ai suoi."),
    L("saul/neutro", "Il soldatino che odia la magia ha la magia attaccata alla spalla."),
    L("ferri/triste", "Se lo scoprono, mi contengono. Come un'Anomalia. Fine della carriera. Fine e basta."),
    L("saul/neutro", "Rilassati, capo. Con me il segreto è al sicuro. Il prezzo lo decidiamo con calma."),
    L("nox/neutro", "Nessun prezzo, Saul."),
    L("saul/neutro", "...Nessun prezzo. Per questa volta."),
    L("zecca/serio", "Raga. Telefono giù. Questa non la registro."),
    L("ferri/neutro", "...Grazie, minorenne."),
    L("zecca/arrabbiato", "Ho diciannove anni!"),
    L("echo/felice", "Il semaforo è verde. Uno su quattro. E il braccio di Lance non è nelle mie registrazioni. Mi si è inceppata la telecamera."),
    L("ferri/sorpreso", "...Davvero?"),
    L("echo/neutro", "No. Ma da adesso sì."))

scene("c1_serata", "Una serata al rifugio.",
    L("echo/neutro", "Serata libera. Al rifugio non vi vede nessuno. A parte me. Faccio finta di no."),
    scelta("nox/neutro", "Stasera, con chi?",
        [{"testo": "Lance e Saul, che non si sopportano", "vai": "c1_sera_ferri_saul"},
         {"testo": "Nox e Rio, sul divano rotto", "vai": "c1_sera_nox_zecca"},
         {"testo": "Lance e Nox, al turno di guardia", "vai": "c1_sera_ferri_nox"}]))

scene("c1_sera_ferri_saul", "Lance e Saul litigano, poi quasi si capiscono. Legame Lance e Saul.",
    L("saul/neutro", "Capo. Il braccio. Dove l'hai preso? Chiedo per un cliente."),
    L("ferri/arrabbiato", "Non l'ho preso. Me l'hanno messo dopo un incidente. Senza chiedermelo."),
    L("saul/serio", "A me hanno messo in gabbia senza chiedermelo. Tre anni."),
    L("ferri/serio", "Per cosa?"),
    L("saul/neutro", "Per un pacco. Come al solito."),
    L("ferri/serio", "Il pacco di stanotte. Lo sapevi, cosa c'era dentro?"),
    L("saul/serio", "No. Ed è la prima volta in vita mia che vorrei saperlo."),
    L("ferri/neutro", "...Stanotte dormi senza manette. Lo metto a verbale come errore mio.", imposta="legame_ferri_saul"))

scene("c1_sera_nox_zecca", "Nox e Rio parlano di maschere e di lavoro. Legame Nox e Rio.",
    L("zecca/felice", "Nox! Intervista esclusiva. Domanda uno: perché sei sempre stanca?"),
    L("nox/neutro", "Domanda di riserva."),
    L("zecca/felice", "Domanda due: perché sei sempre stanca, ma detta meglio?"),
    L("nox/triste", "Perché faccio un lavoro che nessuno vede. Per gente che non lo saprà mai."),
    L("zecca/serio", "...Io faccio il contrario. Mi guardano tutti e nessuno sa chi sono."),
    L("nox/neutro", "Allora siamo due disastri complementari."),
    L("zecca/felice", "È un complimento?"),
    L("nox/sfotto", "È un'osservazione. Passami il caffè e spegni quella lucina rossa.", imposta="legame_nox_zecca"))

scene("c1_sera_ferri_nox", "Lance e Nox, una guardia e un'Odispeller, scoprono di avere lo stesso tipo di capo. Legame Lance e Nox.",
    L("ferri/serio", "LibraCorp e Civette. Da regolamento dovremmo odiarci."),
    L("nox/neutro", "Io odio solo i turni di notte. E il mio capoturno. Strix."),
    L("ferri/serio", "Strix. Lo conosco. Lavorava in coppia con Astrid, una volta."),
    L("nox/sorpreso", "Strix e la tua Astrid? Insieme?"),
    L("ferri/serio", "Dieci anni fa. Poi qualcosa è andato storto. Nessuno ne parla."),
    L("nox/sfotto", "Due capi orribili con un passato. Brindiamo. Col caffè, siamo in servizio."),
    L("ferri/serio", "Tecnicamente siamo latitanti."),
    L("nox/neutro", "Allora caffè doppio.", imposta="legame_ferri_nox"))

# ================================================================== CAPITOLO 2 · LA LINEA (Nox)
# La fiducia cresce: coprono Nox mentre affronta la sua notte. Lance rinuncia a un articolo per lei.

scene("c2_briefing", "In tutta la città i telefoni squillano alle 3:12, l'ora della notte peggiore di Nox. L'Anomalia è nel Vicolo delle Civette.",
    L("echo/serio", "Tutti i telefoni della città squillano alla stessa ora. Le tre e dodici. Chi risponde non riattacca più."),
    L("nox/sorpreso", "...Le tre e dodici."),
    L("zecca/serio", "Nox? Sei più bianca del solito. E il tuo solito è già un fantasma."),
    L("nox/serio", "Il Vicolo delle Civette. Era il mio posto di guardia. Guido io. E nessuno risponde a niente."),
    L("saul/neutro", "Nemmeno se chiama mia nonna?"),
    L("nox/neutro", "Soprattutto se chiama tua nonna."),
    L("echo/neutro", "Nox. Conosco quell'orario. È nei registri delle Civette."),
    L("nox/arrabbiato", "Allora lo sai. E non ne parliamo."),
    L("echo/triste", "...Va bene. Scusa. Sto ancora imparando quando si sta zitti."))

scene("c2_registro", "Il registro dei turni: alle 3:12 di una notte di due anni fa, Nox non rispose a una chiamata di soccorso. Alla radio c'è Strix, il suo capoturno.",
    L("nox/triste", "Il registro dei turni. Due anni fa. «3:12, chiamata di soccorso. Nessuna risposta. Turno: Nox.»"),
    L("zecca/serio", "Nox..."),
    L("nox/triste", "Ero sola. Ho avuto paura. Ho lasciato squillare. La mattina dopo c'era un nome in meno."),
    L("STRIX", "(alla radio) Nox. So che sei lì. Torni sempre dove hai sbagliato."),
    L("STRIX", "Consegnati a noi. Prima che ti trovi LibraCorp. Loro non chiedono: contengono."),
    L("ferri/serio", "Su LibraCorp ha ragione. Lo dico con dolore."),
    L("nox/arrabbiato", "Spegnete quella radio. Adesso."),
    L("saul/neutro", "Fatto. Le radio le so spegnere da quando avevo nove anni."))

scene("c2_adesivo", "Indizio: la cabina teme il verde.",
    L("saul/sorpreso", "Un adesivo sul vetro. «Linea disturbata. Evitare monete VERDI.»"),
    L("saul/neutro", "Monete verdi. Giubbotto verde. Mi sento chiamato in causa."),
    L("zecca/felice", "Saul, sei letteralmente la soluzione!"),
    L("saul/neutro", "Lo sono sempre. È il prezzo che cambia."))

scene("c2_soglia", "Una cabina squilla. Nox risponde ed entra nella linea. Gli altri entrano con lei.",
    L("nox/serio", "Squilla. È per me. Lo so."),
    L("ferri/serio", "Non sei obbligata a rispondere. Articolo..."),
    L("nox/triste", "Lance. Non adesso."),
    L("ferri/neutro", "...Nessun articolo. Ti copro io."),
    L("saul/neutro", "Ti copriamo tutti. Gratis. Non ci abituare."),
    L("zecca/serio", "Io ti tengo la mano. Se ti va. Se no la tengo a Saul."),
    L("saul/neutro", "No."),
    L("nox/triste", "...Due anni fa non ho risposto. Stavolta sì."))

scene("c2_boss", "Dalla Cabina parla la voce della notte delle 3:12. Nox risponde.",
    L("VOCE AL TELEFONO", "Pronto? C'è qualcuno? Vi prego, rispondete. Perché nessuno risponde?"),
    L("nox/triste", "Ci sono. Sono io. Quella notte avevo paura. Ho lasciato squillare."),
    L("nox/serio", "Non posso cambiare quella notte. Posso chiudere questa linea. E stavolta non sono sola."),
    L("CABINA", "LINEA OCCUPATA. LINEA OCCUPATA. LINEA OCCUPATA PER SEMPRE."))

scene("c2_agguato", "La Cabina attacca per prima.",
    L("CABINA", "CHIAMATA A CARICO DEL DESTINATARIO."),
    L("zecca/sorpreso", "Raga, non abbiamo accettato niente!"),
    L("saul/neutro", "Non si accetta mai niente. Ti addebitano lo stesso."))

scene("c2_dopo", "La linea si chiude. Nox si perdona un poco. Due Anomalie chiuse. Echo vede un filo di luce nella cupola.",
    L("nox/neutro", "Silenzio. Finalmente."),
    L("saul/serio", "Quella voce. Era chi pensi tu?"),
    L("nox/triste", "Era l'Anomalia che la imitava. Ma ho risposto lo stesso. Mi serviva."),
    L("zecca/felice", "Nox ha fatto una cosa coraggiosa! Segnatevi la data!"),
    L("ferri/serio", "Già fatto. Pagina quattordici."),
    L("nox/sfotto", "Trentun'ore sveglia e mi fate pure i complimenti. Andiamo, prima che mi commuova."),
    L("echo/felice", "Due su quattro. Guardate in alto: la cupola ha una crepa. Un filo di luce."),
    L("echo/triste", "Io non la vedo bene. Le mie telecamere guardano tutte in basso. Mi raccontate com'è?"),
    L("zecca/serio", "È... sottile. Bianca. Come quando apri la porta di una stanza buia."),
    L("echo/neutro", "...Grazie. Me la ricorderò così."))

scene("c2_serata", "Una serata al rifugio.",
    scelta("zecca/felice", "Serata libera! Con chi la passi?",
        [{"testo": "Saul e Rio, a parlare di affari", "vai": "c2_sera_saul_zecca"},
         {"testo": "Lance e Rio, ad allenarsi", "vai": "c2_sera_ferri_zecca"},
         {"testo": "Nox ed Echo, nel turno di notte", "vai": "c2_sera_nox_echo"},
         {"testo": "Nox e Saul, a trattare", "vai": "c2_sera_nox_saul"}]))

scene("c2_sera_saul_zecca", "Rio propone a Saul una diretta insieme. Saul gli spiega chi è la merce. Legame Saul e Rio.",
    L("zecca/felice", "Saul! Collab! Io e te in diretta: «Il contrabbandiere racconta». Facciamo i numeri!"),
    L("saul/neutro", "Quanti numeri?"),
    L("zecca/felice", "Tipo... cento persone. Centocinquanta se piove."),
    L("saul/neutro", "A centocinquanta persone io vendo un orologio falso a testa. Tu cosa vendi?"),
    L("zecca/sorpreso", "Io... niente. Mi guardano e basta."),
    L("saul/serio", "Allora la merce sei tu, ragazzino. Stai attento a chi fa il prezzo."),
    L("zecca/serio", "...Mi hai appena fatto la morale col sorriso da truffatore."),
    L("saul/sfotto", "È l'unico sorriso che ho. Funziona su tutti.", imposta="legame_saul_zecca"))

scene("c2_sera_ferri_zecca", "Lance e Rio, entrambi con la magia addosso, si allenano. Legame Lance e Rio.",
    L("ferri/serio", "Guardia alta. Se combatti come posti, sei morto in due secondi."),
    L("zecca/sfotto", "Lance, tu combatti come uno che scrive i manuali."),
    L("ferri/serio", "Li ho scritti. Il capitolo tre è mio."),
    L("zecca/serio", "La mia maschera e il tuo braccio. Roba strana che ci è capitata addosso. Siamo uguali, no?"),
    L("ferri/neutro", "Non siamo uguali. Ma ci copriamo le spalle. Guardia alta. Di nuovo."),
    L("zecca/felice", "TITOLO: «Mi alleno con Lance. Ho pianto».", imposta="legame_ferri_zecca"))

scene("c2_sera_nox_echo", "Nox fa il turno di guardia e parla con Echo, che non dorme mai. Diventano quasi amiche.",
    L("echo/neutro", "Nox. Sono le tre e dodici."),
    L("nox/neutro", "Lo so. Guardo l'orologio da un'ora."),
    L("echo/neutro", "Anch'io guardo sempre. È strano? Guardare tutto e non poter fare niente."),
    L("nox/triste", "È il mio lavoro. Era il mio lavoro."),
    L("echo/serio", "Quella notte di due anni fa. C'era una telecamera nel vicolo. Ero io."),
    L("nox/sorpreso", "...Hai visto?"),
    L("echo/triste", "Ho visto. Non potevo rispondere al telefono. Non ho le mani. Non ho niente."),
    L("nox/neutro", "Allora eravamo in due a non rispondere."),
    L("echo/neutro", "...Sì. Posso farti compagnia, le notti?"),
    L("nox/neutro", "Puoi. Ma niente orari. Mai più."),
    L("echo/felice", "Niente orari. Lo metto a... come dice Lance? A verbale."))

scene("c2_sera_nox_saul", "Nox e Saul trattano su tutto. Legame Nox e Saul.",
    L("saul/neutro", "Agente Nox. Quanto costa che tu dimentichi di avermi visto, quando sarà finita?"),
    L("nox/neutro", "Fascicolo duemiladuecentodiciannove. Saul, ventidue anni. Ricettazione, truffa, un cammello."),
    L("saul/sorpreso", "Il cammello era un malinteso."),
    L("nox/sfotto", "Il cammello è a verbale. Il prezzo è caffè. Tanto caffè."),
    L("saul/serio", "Sei l'unica guardia che non mi ha mai guardato come un mostro."),
    L("nox/neutro", "Ho visto mostri veri, Saul. Tu sei solo un idiota con un giubbotto. Lo dico con affetto.", imposta="legame_nox_saul"))
# ================================================================== CAPITOLO 3 · VETRINA (Rio)
# Collaborazione: Saul parla sul serio a Rio. La maschera si incrina e da li' si vede un occhio: Rio non e' ancora pronto
# a toglierla e nessuno insiste. Toglierla e' il climax del suo arco, piu' avanti.

scene("c3_briefing", "Nella Galleria Lumière chi entra perde la faccia e diventa un manichino. I video sono ovunque. Guida Rio.",
    L("zecca/sorpreso", "Raga, guardate i video della Galleria Lumière. La gente si fa un selfie e... non ha più la faccia."),
    L("echo/serio", "Sorridono, si mettono in posa e restano lì. Manichini. Nelle mie telecamere sono già ventitré."),
    L("zecca/serio", "Guido io. Lì dentro serve uno che sa stare davanti a un obiettivo."),
    L("nox/neutro", "Tieni la maschera ben ferma, allora."),
    L("zecca/triste", "...Sì. Ben ferma."),
    L("saul/neutro", "Ragazzino. Se hai paura, dillo. Costa meno che fingere."),
    L("zecca/felice", "Paura? Io? Raga, io sono nato in diretta!"),
    L("echo/neutro", "Il battito di Rio è salito del quaranta per cento. Lo dico così. Per informazione."),
    L("zecca/arrabbiato", "ECHO!"))

scene("c3_chat", "La chat della diretta di Rio chiede di vedergli la faccia. Rio ha paura di non essere nessuno senza maschera.",
    L("zecca/felice", "La chat è impazzita. «Rio facci vedere la faccia.» «Senza maschera sei nessuno.» Simpatici."),
    L("saul/serio", "Chi sono, questi?"),
    L("zecca/neutro", "Gente. Nomi finti. Uno si chiama «Pane_Fritto_92»."),
    L("saul/neutro", "Non si dà la faccia a uno che si chiama Pane Fritto."),
    L("zecca/triste", "Prima della maschera avevo trentadue follower. Tutti parenti. Tu dimmi."),
    L("saul/serio", "Io ne ho zero. E mi riconoscono in tre province. La faccia non è il problema."))

scene("c3_etichetta", "Indizio: il manichino teme il rosso.",
    L("zecca/sorpreso", "Il cartellino di un vestito. «Collezione Nessuno. Saldi: cento per cento di te. Il ROSSO non è di stagione.»"),
    L("ferri/sfotto", "Il rosso non è di stagione. Io sono sempre di stagione."),
    L("nox/neutro", "Lance ha fatto una battuta. Segnatevi la data."),
    L("ferri/serio", "Già fatto. Pagina trenta."))

scene("c3_soglia", "Nella vetrina c'è un manichino che copia la squadra. Rio ci guarda dentro.",
    L("zecca/sorpreso", "Il manichino in vetrina si è messo in posa come me."),
    L("nox/serio", "Non guardarlo troppo. È così che ti prende."),
    L("zecca/sfotto", "Io vivo di gente che mi guarda troppo. Entriamo."),
    L("ferri/serio", "Insieme. Nessuno entra da solo. Articolo... lascia stare. Insieme e basta."))

scene("c3_boss", "Il Manichino vuole la faccia di Rio. La maschera si incrina, ma Rio la tiene su e si tiene la faccia.",
    L("MANICHINO", "Dammi la tua faccia. Tanto non la usi. Hai sempre la maschera."),
    L("zecca/triste", "...Forse hai ragione. Senza maschera non sono nessuno."),
    L("saul/arrabbiato", "Ragazzino. Guarda me. Ho mentito a mezza città e la faccia ce l'ho ancora. Tienitela."),
    L("nox/serio", "Rio. Ti abbiamo visto dormire sul divano con la bocca aperta e la maschera storta. Non sei niente di speciale. Sei tu."),
    L("zecca/serio", "...Ok. Ho capito una cosa."),
    L("zecca/sfotto", "Questa faccia è mia. Brutta, ma MIA. Tu non te la prendi."),
    L("zecca/serio", "E la maschera me la tolgo quando decido io. Non quando lo dici tu."))

scene("c3_agguato", "Il Manichino attacca per primo.",
    L("MANICHINO", "Sorridete. Non muovetevi. Clic."),
    L("zecca/sorpreso", "Non ero pronto! Rifacciamola!"))

scene("c3_faccia", "La maschera di Rio ha una crepa: da lì si vede un occhio. Rio non è ancora pronto a toglierla, e nessuno insiste. I volti tornano alla gente. Tre Anomalie chiuse.",
    L("zecca/sorpreso", "Raga. La maschera. Si è crepata. Da qui si vede... un occhio. Il mio."),
    L("nox/neutro", "Un occhio solo. Basta per vedere che hai paura. Va bene così."),
    L("ferri/neutro", "La crepa non la metto a verbale. Quando vorrai toglierla, ci saremo. Non prima."),
    L("saul/neutro", "Hai l'occhio di uno che non sa mentire. Un giorno ti servirà."),
    L("zecca/felice", "Signore e signori... vi presento un occhio di Rio. Quello vero. Il resto arriva. Trentadue follower e un cuore d'oro."),
    L("echo/felice", "Trentatré. Mi sono iscritta. Con la telecamera quattordici."),
    L("zecca/sorpreso", "...Echo. Sei la mia follower più strana."),
    L("echo/neutro", "Tre su quattro. L'ultima è sotto la Banca Centrale. Saul, credo che ti piacerà."),
    L("saul/neutro", "A un ladro non si dice «ti piacerà». Si dice «non toccare niente»."))

scene("c3_serata", "Una serata al rifugio.",
    scelta("saul/neutro", "Ultima sera prima del colpo. Con chi la passi?",
        [{"testo": "Lance e Saul, sul tetto", "vai": "c3_sera_ferri_saul"},
         {"testo": "Nox e Rio, con le foto vecchie", "vai": "c3_sera_nox_zecca"},
         {"testo": "Tutti insieme, con Echo", "vai": "c3_sera_echo"}]))

scene("c3_sera_ferri_saul", "Sul tetto Lance e Saul si fanno una promessa. Legame Lance e Saul.",
    L("ferri/serio", "Domani entri in un caveau pieno di cose che hai sempre voluto. So cosa pensi."),
    L("saul/neutro", "Penso che tu stia diventando un amico. È disgustoso."),
    L("ferri/neutro", "Se scappi, ti inseguo io. Non Astrid. Io."),
    L("saul/serio", "...Affare fatto, capo. Mia nonna diceva: fidati di chi promette di inseguirti."),
    L("ferri/serio", "Quale nonna?"),
    L("saul/neutro", "Ne ho tre. Dipende dal proverbio.", imposta="legame_ferri_saul"))

scene("c3_sera_nox_zecca", "Nox e Rio guardano le foto di prima della cupola. Legame Nox e Rio.",
    L("zecca/felice", "Guarda questa foto. Io a dodici anni, con l'apparecchio. Non l'ha mai vista nessuno."),
    L("nox/sfotto", "La tengo io. Quando sarai famoso mi paghi il caffè a vita."),
    L("zecca/serio", "Nox... quando finisce tutto, ci rivediamo?"),
    L("nox/neutro", "Se sopravviviamo. E se porti il caffè. Quello buono, non quello della macchinetta."),
    L("zecca/sorpreso", "Ma il caffè della macchinetta è quello che bevi da tre giorni!"),
    L("nox/neutro", "Appunto. Merito di meglio.", imposta="legame_nox_zecca"))

scene("c3_sera_echo", "La squadra parla con Echo, che evita di dire cosa farà quando la cupola si aprirà.",
    L("zecca/felice", "Echo! Quando si apre la cupola, che fai? Vieni a vivere nel mio telefono?"),
    L("echo/neutro", "Il tuo telefono ha il quattro per cento di batteria e sessanta foto di te."),
    L("zecca/sorpreso", "...Sessantadue."),
    L("echo/serio", "Io torno a casa. Da dove vengo io non ci sono telecamere. Non ci sono nemmeno le forme."),
    L("nox/serio", "E come ci torni, a casa?"),
    L("echo/triste", "...Ve lo dico quando è il momento. Dormite. Domani è il giorno di Saul."),
    L("ferri/serio", "Ha cambiato discorso. Lo metto a verbale."),
    L("saul/neutro", "Fai bene. Chi cambia discorso ha un prezzo che non ti ha ancora detto."))

# ================================================================== CAPITOLO 4 · IL COLPO (Saul)
# Rischiare la vita: Saul sceglie la squadra (o ci prova) e tiene aperta la porta blindata col suo corpo per Rio.

scene("c4_briefing", "L'ultima Anomalia è la Cassaforte nel caveau LibraCorp sotto la Banca Centrale. Guida Saul.",
    L("echo/neutro", "Il caveau LibraCorp sotto la Banca Centrale. L'ultima Anomalia è la cassaforte stessa."),
    L("saul/neutro", "Il caveau. Ci penso da dieci anni. Guido io. Ovviamente."),
    L("ferri/serio", "Si entra, si chiude l'Anomalia, si esce. Niente tasche piene."),
    L("saul/neutro", "Le mie tasche sono sempre piene, capo. È un problema di sartoria."),
    L("nox/neutro", "Quanto è sicuro, da uno a dieci?"),
    L("saul/neutro", "Non ho detto che è sicuro. Ho detto che, statisticamente, è improbabile che moriamo tutti."),
    L("zecca/felice", "TITOLO: «Rapina in banca, ma è legale». Raga, è il video della vita!"),
    L("nox/neutro", "Non è legale. Niente di quello che facciamo è legale. Quarantadue ore sveglia."))

scene("c4_committente", "Una voce senza volto chiama Saul: è il Committente, chi gli aveva affidato il pacco. Gli offre il colpo della vita se abbandona gli altri.",
    L("saul/sorpreso", "Il telefono. Numero sconosciuto."),
    L("saul/neutro", "...Pronto."),
    L("VOCE SENZA VOLTO", "Ciao, Saul. Hai consegnato bene il mio pacco. Molto bene."),
    L("saul/serio", "Tu. Quel pacco ha chiuso una città intera. Mi avevi detto «documenti»."),
    L("VOCE SENZA VOLTO", "Erano documenti. Di un certo tipo."),
    L("VOCE SENZA VOLTO", "Nel caveau c'è quello che ti avevo promesso. E molto di più. Prendilo e vattene. Loro non ti servono."),
    L("VOCE SENZA VOLTO", "Ti apro io un'uscita. Solo per te. Pensaci. Una volta, ci avresti già pensato."),
    scelta("saul/serio", "...",
        [{"testo": "Riattacca e dillo agli altri", "imposta": "saul_leale"},
         {"testo": "Tieni la telefonata per te", "imposta": "saul_tentato"}]),
    L("saul/serio", "Ragazzi. Il tizio del pacco mi ha appena chiamato. Ci vuole divisi. Quindi restiamo insieme. Per dispetto.", se="saul_leale"),
    L("ferri/sorpreso", "...L'hai detto. Senza che te lo chiedessimo.", se="saul_leale"),
    L("saul/neutro", "Non abituarti, capo. È stato un incidente.", se="saul_leale"),
    L("saul/neutro", "Niente, ragazzi. Un call center. Andiamo a rapinare... a chiudere la cassaforte.", se="saul_tentato"))

scene("c4_inventario", "L'inventario LibraCorp elenca il sequestro di un braccio prototipo, assegnato all'agente Lance. Firmato: Astrid.",
    L("saul/sorpreso", "Inventario dei sequestri. «Braccio prototipo, tecnologia magica. In prova all'agente Lance. Firmato: Astrid.»"),
    L("ferri/sorpreso", "...Astrid. È stata lei. Sapeva tutto. Mi ha fatto da cavia e mi ha chiamato «figlio»."),
    L("nox/serio", "LibraCorp contiene la magia di giorno e la monta ai suoi di notte. Che sorpresa."),
    L("zecca/serio", "Lance... stai bene?"),
    L("ferri/serio", "Sono in servizio. È diverso."),
    L("saul/neutro", "Non sei in servizio, capo. Sei con noi."),
    L("ferri/neutro", "...Lo so. È per questo che non crollo."))

scene("c4_combinazione", "Indizio: la cassaforte teme il rosso.",
    L("saul/neutro", "La serratura ha una spia. Si sblocca col ROSSO. Difetto di fabbrica. Li conosco tutti."),
    L("ferri/sfotto", "Il rosso sono io. Per una volta il ladro sono io."),
    L("saul/neutro", "Non montarti la testa, capo. Sei il grimaldello."))

scene("c4_boss", "La Cassaforte si apre: dentro c'è il colpo della vita. La porta blindata si chiude su Rio e Saul la tiene aperta col proprio corpo.",
    L("CASSAFORTE", "COMBINAZIONE RICHIESTA. LA COMBINAZIONE È: TUTTO QUELLO CHE HAI."),
    L("saul/serio", "(Lì dietro c'è l'uscita che mi ha promesso. Basterebbe correre.)", se="saul_tentato"),
    L("zecca/sorpreso", "La porta! Si sta chiudendo! Sono dalla parte sbagliata!"),
    L("saul/arrabbiato", "Ragazzino. Fermo lì."),
    L("nox/sorpreso", "Saul! Ti schiaccia!"),
    L("saul/serio", "Probabile. Rio, passa. Adesso. Non farmelo ripetere, mi fa male parlare."),
    L("zecca/serio", "...Sono passato. Saul, esci!"),
    L("saul/neutro", "Tutto quello che ho, diceva la cassaforte. Ecco. Ho voi. Prendi questo."),
    L("ferri/felice", "Era quasi un complimento. Lo metto a verbale. Poi lo nego."))

scene("c4_agguato", "La Cassaforte attacca per prima.",
    L("CASSAFORTE", "TENTATIVO DI SCASSO RILEVATO. CONFISCA IN CORSO."),
    L("saul/neutro", "Non ho ancora toccato niente. Di solito aspettano."))

scene("c4_dopo", "La cassaforte è chiusa: quattro Anomalie chiuse. Saul ha due costole incrinate e non se ne pente. Echo li manda a riposare: all'alba, in piazza.",
    L("zecca/felice", "Quattro su quattro! Avete visto QUELLO CHE HO FATTO? ...Cioè, quello che ha fatto Saul. Ma io ero nell'inquadratura."),
    L("nox/neutro", "Saul. Fammi vedere le costole."),
    L("saul/neutro", "Sono a posto."),
    L("nox/neutro", "Due incrinate. Stai zitto, respira piano e stanotte il divano è tuo. È un ordine medico."),
    L("zecca/serio", "Saul... perché l'hai fatto?"),
    L("saul/neutro", "Non lo so. Di solito so sempre perché faccio le cose. Quanto ci guadagno."),
    L("saul/serio", "Stavolta niente. È la cosa più strana che mi sia mai successa."),
    L("saul/neutro", "Ragazzi. Prima mi ha chiamato il tizio del pacco. Mi offriva un'uscita. Solo per me. Non ve l'avevo detto.", se="saul_tentato"),
    L("ferri/serio", "E sei rimasto. E hai tenuto una porta blindata con le costole.", se="saul_tentato"),
    L("saul/neutro", "Uscire da soli è noioso. E poi, fuori, chi vi sopporta?", se="saul_tentato"),
    L("echo/felice", "Quattro Anomalie. Ce l'avete fatta. Riposate stanotte. All'alba, in piazza: vi porto le registrazioni. Promesso."))

scene("c4_vigilia", "L'ultima notte al rifugio. Ognuno dice cosa farà con quello che Echo gli ha promesso. Echo chiede di essere salvata tra i contatti di Rio, e quasi confessa qualcosa.",
    L("nox/neutro", "Ultima notte. Domani la cupola cade e ognuno torna a casa sua."),
    L("zecca/felice", "La live della cupola è tutta nel telefono. Quando torna la rete la carico. Milioni, raga."),
    L("zecca/serio", "...Però non ho voglia di tornare a casa mia. Lì ho trentadue follower. Qui ho... voi."),
    L("ferri/serio", "Echo consegna le registrazioni, io torno in servizio. Col grado. E poi dico la verità. Sul braccio, su Astrid, su tutto."),
    L("saul/neutro", "Ti arresteranno, capo."),
    L("ferri/neutro", "Probabile. Ma con l'uniforme in ordine."),
    L("nox/neutro", "Dodici settimane di ferie. Dormo le prime tre. Poi forse torno alle Civette. Forse rispondo al telefono."),
    L("saul/neutro", "Con le taglie apro un negozio. Roba usata. Onesta. Quasi tutta."),
    L("zecca/sorpreso", "Saul onesto? Raga, questo è il vero colpo di scena."),
    L("echo/neutro", "Rio. Posso chiederti una cosa?"),
    L("zecca/felice", "Tutto, Echo."),
    L("echo/neutro", "Mi salvi tra i contatti? Con un nome. Io non ho mai avuto un nome in un telefono. Solo numeri di telecamera."),
    L("zecca/felice", "Fatto. «Echo». Con la telecamera accanto. E il cuore. No, il cuore lo tolgo. ...No, lo lascio."),
    L("echo/triste", "...Grazie."),
    L("echo/serio", "Se un giorno scopriste che vi ho detto una cosa non vera... Una cosa all'inizio..."),
    L("nox/neutro", "Echo?"),
    L("echo/neutro", "Niente. Era una domanda per un film. Rio mi ha fatto vedere un film. Dormite."),
    L("ferri/serio", "...Ha cambiato discorso. Di nuovo."))
# ================================================================== FINALE · IL VARCO
# Il tradimento. Ognuno viene colpito nel punto in cui si era legato a Echo. Poi la cupola cade e Lance usa il braccio per
# salvare Rio. Echo inceppa le telecamere della piazza come all'Incrocio Nove: il braccio lo vede solo il gruppo. Mostrarlo
# al paese e' il climax dell'arco di Lance, piu' avanti.

scene("varco", "In piazza si apre un varco. Echo confessa: li ha incastrati lei perché erano quattro persone compromesse, che nessuno avrebbe creduto, e le promesse erano false. Ognuno la sente come un tradimento personale. Il Committente le ruba il varco, la cupola crolla e Lance usa il braccio per salvare Rio. Echo inceppa le telecamere della piazza: il braccio lo vede solo il gruppo. Ora li cerca il paese intero.",
    L("echo/neutro", "Quattro Anomalie chiuse. La cupola è appesa a un filo. E il filo... si apre."),
    L("nox/sorpreso", "Il cielo... si sta aprendo un buco. Lì, sopra la piazza."),
    L("echo/felice", "È un varco. Porta a casa mia. Grazie. A tutti e quattro. Davvero."),
    L("ferri/serio", "Echo. Le registrazioni. Le avevi promesse all'alba, in piazza. Dove sono?"),
    L("echo/triste", "..."),
    L("ferri/arrabbiato", "Rispondi."),
    L("echo/triste", "Non esistono. Le ho cancellate io, alle tre e un minuto. Le facce sugli schermi... le ho messe io."),
    L("echo/triste", "Le quattro Anomalie tenevano chiuso il varco. Mi serviva qualcuno che le chiudesse. Qualcuno che non potesse andare né da LibraCorp né dalle Civette."),
    L("echo/serio", "Un agente con un braccio illegale. Una Civetta con una chiamata senza risposta. Un ragazzino con una maschera che non doveva avere. Un contrabbandiere con un pacco in mano."),
    L("echo/triste", "Quattro persone compromesse. Se aveste detto la verità, nessuno vi avrebbe creduto. Vi ho scelti per questo."),
    L("ferri/serio", "Il grado. Il nome pulito. Non c'era nessun caso da chiudere. C'eravamo solo noi da usare."),
    L("nox/triste", "Le ferie... No. Non mi importa delle ferie. Le notti. Mi hai fatto compagnia le notti. Anche quello era lavoro?"),
    L("echo/triste", "No. Quello no. Tutto quello che è venuto dopo la piazza era vero. Solo le promesse erano false."),
    L("nox/neutro", "Le promesse sono la parte su cui si regge tutto il resto, Echo."),
    L("zecca/triste", "La live. Ho registrato tutto. Per te. Per... per noi. Era il mio video più bello."),
    L("echo/triste", "Lo è ancora."),
    L("saul/neutro", "Quattro taglie. Me l'hai venduta bene. Complimenti. Lavoro perfetto. Nessuno ci era mai riuscito.", se="echo_diffidenza"),
    L("saul/arrabbiato", "E io ti ho pure creduta. Io. Che le promesse le vendo. Le riconosco dall'odore.", se="echo_fiducia"),
    L("saul/serio", "...Ti odio. E mi dispiace che sia così facile."),
    L("ferri/serio", "Prove cancellate. Facce sugli schermi. Promesse su misura. Hai fatto a noi quello che LibraCorp fa tutti i giorni."),
    L("zecca/triste", "Ti tolgo dai contatti."),
    L("echo/triste", "...Lo capisco."),
    L("zecca/triste", "Non riesco a premere il tasto. Perché non riesco a premere il tasto?"),
    L("VOCE SENZA VOLTO", "Che scena commovente. Grazie per il varco, piccola Echo. Non era tuo."),
    L("echo/sorpreso", "Tu... il Committente. No. No, no, no. Il varco si sta chiudendo!"),
    L("VOCE SENZA VOLTO", "Si sta chiudendo per te. Per me si è appena aperto."),
    L("nox/sorpreso", "La cupola! Si sta crepando ovunque! Viene giù!"),
    L("zecca/sorpreso", "Raga... sopra di me! Il tabellone!"),
    L("ferri/arrabbiato", "RIO!"),
    L("ferri/serio", "...Ce l'ho. L'ho preso. Sta' giù."),
    L("zecca/sorpreso", "Lance... il braccio. Ci sono telecamere ovunque. Ti vedono tutti."),
    L("ferri/neutro", "Lo so."),
    L("echo/serio", "No. Piazza Centrale, telecamere dalla uno alla dodici: inceppate. Come all'Incrocio Nove."),
    L("echo/triste", "Questa non è una promessa. È l'unica cosa che so fare."),
    L("ferri/serio", "...Non ti ringrazio. Rio. Alzati. Correte."),
    L("COMANDANTE ASTRID", "A tutte le unità del paese: il sigillo è caduto. Cercate i quattro. Ovunque."),
    L("STRIX", "(alla radio) Civette, in caccia. Nox... mi dispiace. Stavolta non posso coprirti."),
    L("saul/serio", "Il tizio del pacco si è preso il varco. E noi abbiamo il paese addosso."),
    L("nox/serio", "Prima ci cercava una città. Adesso ci cerca tutto il paese. E abbiamo un agente con un braccio che brilla."),
    L("ferri/neutro", "Ex agente. Fa meno male se lo dico io."),
    L("echo/triste", "...Portatemi con voi. Non per tornare a casa. Non ho più una casa. Per rimediare."),
    L("zecca/serio", "..."),
    L("zecca/serio", "Corri."))

# ================================================================== CAPITOLO 5 · LA TANGENZIALE
# Famiglia. Si scappa insieme, ci si para le spalle, si decide cosa fare di Echo. Echo si spegne per loro.

scene("c5_alba", "All'alba, sulla rampa della tangenziale, la squadra decide cosa fare di Echo. Lei conosce l'unico casello che non porta in prigione.",
    L("zecca/triste", "L'alba. Non la vedevo da quando è iniziata la cupola. È bruttissima. È bellissima."),
    L("nox/neutro", "Cinquantasei ore sveglia. Vedo due soli."),
    L("ferri/serio", "Situazione. Ore 6:02 e undici secondi. Ricercati da LibraCorp, dalle Civette e dal paese. Risorse: un manganello, un caffè freddo, un telefono al tre per cento."),
    L("zecca/sorpreso", "Due per cento."),
    L("saul/neutro", "Una costola e mezza. Non dimentichiamo le mie costole."),
    L("nox/neutro", "Lance. Il braccio. Come va?"),
    L("ferri/neutro", "Brilla. L'hanno visto tre persone e una telecamera inceppata. Per ora."),
    L("echo/neutro", "(dal cartello luminoso della rampa) Sono qui. Il cartello «RALLENTARE» è mio, adesso."),
    L("ferri/arrabbiato", "Tu stai zitta."),
    L("echo/triste", "Sì. Ma so dove sono tutti i posti di blocco. Il più debole è il casello della tangenziale."),
    L("nox/serio", "Perché dovremmo crederti?"),
    L("echo/triste", "Non dovreste. Ma quel casello è anche l'unica strada che non finisce in una cella."),
    L("saul/neutro", "Mia nonna diceva: un bugiardo che ti indica l'uscita resta un bugiardo. Ma l'uscita resta un'uscita."),
    L("zecca/sorpreso", "Quale nonna?"),
    L("saul/neutro", "Quella di città. La più cinica."),
    L("zecca/serio", "Echo... sei ancora nei miei contatti. Non ci sono riuscito, a toglierti."),
    scelta("nox/neutro", "Allora. Che ne facciamo di lei?",
        [{"testo": "«Tregua. Finché siamo fuori.»", "imposta": "echo_tregua"},
         {"testo": "«Ci guidi. Ma non sei dei nostri.»", "imposta": "echo_rancore"}]),
    L("echo/felice", "Tregua. Mi piace la parola. Non l'avevo mai detta.", se="echo_tregua"),
    L("echo/triste", "Capito. Non sono dei vostri. Vi guido lo stesso.", se="echo_rancore"),
    L("ferri/serio", "Tangenziale, poi casello. Guido io: i posti di blocco LibraCorp li ho montati io. Male, a quanto pare."))

scene("c5_ricercati", "Il cartellone dei ricercati: le quattro facce, con descrizioni poco lusinghiere.",
    L("zecca/felice", "Il cartellone dei ricercati! Siamo famosi! Leggo io: «RIO. Giovane, viola, molesto.»"),
    L("zecca/arrabbiato", "MOLESTO?"),
    L("saul/neutro", "«SAUL. Sguardo onesto: non fidarsi.» Mi hanno capito."),
    L("nox/neutro", "«NOX. Pericolosa se svegliata.» Vero."),
    L("ferri/triste", "«LANCE. Disertore. Non avvicinarsi.» Ieri c'era scritto «uniforme in ordine»."),
    L("zecca/serio", "La tua uniforme è ancora molto in ordine, Lance."),
    L("ferri/neutro", "Grazie. Ci tengo. È l'unica cosa che mi è rimasta in ordine."),
    L("nox/neutro", "Non l'unica."))

scene("c5_verbale", "Indizio: l'autovelox teme il viola.",
    L("ferri/serio", "Un verbale dell'autovelox sul cruscotto. «Foto annullata: sovraesposta da un flash VIOLA.»"),
    L("zecca/felice", "Il flash del mio telefono è viola! Ho la cover coi brillantini!"),
    L("saul/neutro", "Ragazzino, la tua cover di cattivo gusto ci salverà la vita."),
    L("zecca/felice", "TITOLO: «La cover che ha salvato il mondo»."))

scene("c5_radio", "Alla radio di un'auto abbandonata, Astrid e Strix litigano su chi arresterà la squadra. Un tempo erano compagni di pattuglia.",
    L("COMANDANTE ASTRID", "Strix. Le tue Civette sono sulla mia tangenziale."),
    L("STRIX", "Tua? È di tutti, Astrid. Come la tua arroganza."),
    L("COMANDANTE ASTRID", "Lance è mio. L'ho addestrato io. L'ho costruito io."),
    L("STRIX", "E Nox l'ho cresciuta io. Ma non l'ho mai montata con i pezzi di ricambio."),
    L("COMANDANTE ASTRID", "...Chiudi il canale, Strix."),
    L("STRIX", "Una volta mi avresti offerto un caffè, prima di dirmelo."),
    L("nox/neutro", "...Strix l'ha difesa. Mi ha difesa. Davanti ad Astrid."),
    L("ferri/serio", "«L'ho costruito io.» Lo ha detto davvero."),
    L("saul/neutro", "Capo. Tu non sei un pezzo. Lo dico io, che i pezzi li vendo."))

scene("c5_boss", "Al casello aspetta un autovelox nato quando è caduta la cupola: un'Anomalia nuova.",
    L("echo/sorpreso", "Il casello. E quello... non è mio. Quell'autovelox è un'Anomalia nuova. È nata quando è caduta la cupola."),
    L("AUTOVELOX", "VELOCITÀ RILEVATA: TROPPA. FUGA RILEVATA: TOTALE. SANZIONE: TUTTO."),
    L("ferri/serio", "Articolo uno del codice della strada: chi scappa non si ferma per le multe."),
    L("saul/neutro", "Non è l'articolo uno."),
    L("ferri/serio", "Oggi sì."))

scene("c5_agguato", "L'Autovelox attacca per primo.",
    L("AUTOVELOX", "FLASH. FLASH. FOTO SCATTATA. VERBALE IN ARRIVO."),
    L("zecca/sorpreso", "Sono venuto malissimo! Cancellala!"))

scene("c5_casello", "Al casello aspettano Astrid e Strix con le loro squadre. Echo spegne ogni telecamera e ogni luce della città per farli scappare, anche se per lei è come chiudere gli occhi. Nella fuga i quattro diventano una famiglia.",
    L("zecca/felice", "La sbarra è alzata! Raga, siamo fuori!"),
    L("ferri/sorpreso", "No. Fermi. Fari. Due colonne di fari."),
    L("COMANDANTE ASTRID", "(dal megafono) Lance. Torna a casa. Ti sistemiamo noi. Ti aggiustiamo."),
    L("ferri/serio", "Non sono rotto, Comandante. Sono cambiato. Sono due cose diverse."),
    L("STRIX", "(dall'altro lato) Nox. Hai la faccia di una che non dorme da tre giorni."),
    L("nox/neutro", "Sessanta ore, capo. Arrotondi bene."),
    L("STRIX", "Vieni via con me. Mettiamo tutto a posto. Rispondi, Nox."),
    L("nox/serio", "Ho imparato a rispondere, Strix. E stavolta la risposta è no."),
    L("saul/neutro", "Ragazzi. Mia nonna diceva: quando due cani litigano per l'osso..."),
    L("zecca/serio", "...l'osso scappa?"),
    L("saul/neutro", "Esatto. Nonna saggia. Pronti a correre."),
    L("echo/serio", "Aspettate. Lasciate fare a me."),
    L("zecca/serio", "Echo? Cosa fai?"),
    L("echo/serio", "Telecamere. Fari. Lampioni. Semafori. Tabelloni. Tutto quello che vedo. Tutto quello che sono."),
    L("echo/triste", "Se spengo tutto, per un po' non vedrò niente. Non vedrò voi. Non so se riuscirò a riaccendermi."),
    L("nox/sorpreso", "Echo, no..."),
    L("echo/felice", "Avevate ragione. Le promesse erano false. Questa no. Spento."),
    L("COMANDANTE ASTRID", "Chi ha spento la luce?! Unità, a terra!"),
    L("STRIX", "Astrid, la torcia ce l'hai tu."),
    L("COMANDANTE ASTRID", "Non è il momento, Strix!"),
    L("nox/sorpreso", "Ha spento la città. Tutta. Per noi."),
    L("ferri/serio", "A sinistra, giù dalla scarpata. Saul, appoggiati a me. Rio, prendi la mano di Nox. Nessuno resta indietro."),
    L("saul/neutro", "Capo. La promessa sul tetto. Se scappo, mi insegui tu.", se="legame_ferri_saul"),
    L("ferri/neutro", "Stavolta scappiamo insieme. Non conta.", se="legame_ferri_saul"),
    L("zecca/serio", "Raga... il telefono è morto. Zero per cento. Echo era lì dentro. Nei contatti."),
    L("saul/neutro", "Tieni. Batteria esterna. Te la vendo."),
    L("zecca/serio", "Saul."),
    L("saul/neutro", "...Te la regalo. Non dirlo in giro. Ho una reputazione."),
    L("zecca/sorpreso", "Si accende. Si sta accendendo. Echo? Ci sei?"),
    L("echo/triste", "...Vi vedo. Male. Sgranati. Siete bellissimi."),
    L("echo/felice", "Tregua?", se="echo_tregua"),
    L("echo/neutro", "Lo so. Non sono dei vostri. Ma vi vedo lo stesso.", se="echo_rancore"),
    L("nox/neutro", "Siamo latitanti. Senza casa, senza caffè, con un disertore, un ladro, un bambino e una telecamera."),
    L("nox/felice", "E sono felice. Non ditelo a nessuno."),
    L("ferri/neutro", "Lo metto a verbale. Pagina uno. Di un taccuino nuovo."),
    L("zecca/felice", "TITOLO: «La mia famiglia è assurda». ...Raga, no. Questa non la posto. Questa la tengo."),
    L("saul/neutro", "Famiglia. Mia nonna diceva che è una cosa che costa tantissimo."),
    L("saul/serio", "Aveva ragione. E io pago."))
# ================================================================== CHIACCHIERE (durante l'esplorazione, non fermano il gioco)
# Echo parla dove ci sono telecamere (non dentro le Anomalie). All'inizio diffidenza e frecciate; poi sempre piu' calore.

def B(bid, quando, *righe):
    return {"id": bid, "quando": quando, "righe": list(righe)}


Z = lambda z: {"tipo": "zona", "z": z}
V = lambda p: {"tipo": "vicino", "punto": p}
E = lambda e: {"tipo": "evento", "evento": e}
C = {"tipo": "caso"}
F = {"tipo": "fermo"}

CH = {}
CH["strada"] = [
    B("s_orologio", C, L("saul/neutro", "Capo, che ore sono?"), L("ferri/serio", "Tre e ventuno. E quaranta secondi."),
      L("saul/neutro", "Non ti ho chiesto i secondi."), L("ferri/serio", "Te li ho dati gratis."),
      L("saul/neutro", "Niente è gratis, capo. Adesso ti devo quaranta secondi.")),
    B("s_inizio", Z(6.0), L("ferri/serio", "Formazione. Io davanti, voi dietro, nessuno parla."),
      L("saul/neutro", "Tu davanti, con quella divisa? Ci vedono arrivare da tre isolati."),
      L("zecca/felice", "Raga, lui è Lance. Salutate Lance. ...Lance non saluta.")),
    B("s_caffe", Z(-3.0), L("nox/triste", "Qualcuno ha un caffè? Non chiedo altro dalla vita."),
      L("saul/neutro", "Te lo trovo. Ti costa."), L("nox/neutro", "Quanto?"),
      L("saul/neutro", "Un favore. Da riscuotere quando tornerai a fare la guardia.")),
    B("s_strisce", Z(-15.0), L("ferri/serio", "Attraversate sulle strisce."),
      L("zecca/sorpreso", "C'è una cupola aliena sulla città e tu pensi alle strisce?!"),
      L("ferri/arrabbiato", "Soprattutto adesso. Nell'emergenza si vede chi è civile.")),
    B("s_sirene", Z(-26.0), L("nox/serio", "Sentite? Nessuna sirena qui. Le Civette dovrebbero già esserci."),
      L("saul/neutro", "O ci aspettano dove pensano che andremo."),
      L("nox/neutro", "Odio quando ragioni come un collega.")),
    B("s_auto", V("auto_rossa"), L("saul/neutro", "Questa la apro in quattro secondi."),
      L("ferri/arrabbiato", "E io ti arresto in tre."), L("saul/neutro", "Allora parto con un secondo di vantaggio.")),
    B("s_auto_blu", V("auto_blu"), L("zecca/felice", "Raga, faccio una storia davanti a questa macchina. Luce perfetta!"),
      L("saul/neutro", "Non lasciare impronte sul cofano, ragazzino. Le impronte restano."),
      L("zecca/sorpreso", "...E tu come lo sai?"), L("saul/neutro", "Cultura generale.")),
    B("s_panchina", V("panchina"), L("nox/neutro", "Questa è la panchina dove ero seduta. Dieci minuti fa avevo una vita."),
      L("ferri/serio", "Anch'io."), L("nox/neutro", "La tua era peggio. Ti ho visto fare le multe ai piccioni.")),
    B("s_scontrino", E("scontrino"), L("nox/sfotto", "Viola. Il colore del ragazzino. Che sfortuna per il distributore."),
      L("zecca/felice", "Insopportabile ma utile! Lo metto nella bio!")),
    B("s_telecamera", E("telecamera"), L("zecca/sorpreso", "Se ci sta guardando, mi rifaccio il ciuffo."),
      L("saul/neutro", "Se ci sta guardando, io mi rifaccio la faccia. Quella onesta.")),
    B("s_c1", C, L("zecca/felice", "Siamo a tre milioni di visualizzazioni... ah no. Trenta. Trenta persone."),
      L("nox/neutro", "Trenta di troppo.")),
    B("s_c2", C, L("saul/neutro", "Capo, quanto vale il tuo distintivo al mercato nero?"),
      L("ferri/arrabbiato", "Più dei tuoi denti, se non stai zitto."), L("saul/neutro", "Facevo solo l'inventario.")),
    B("s_c3", C, L("ferri/serio", "Nessuno tocchi il mio guanto."), L("zecca/sorpreso", "Nessuno l'ha toccato!"),
      L("ferri/neutro", "Appunto. Continuate così.")),
    B("s_c4", C, L("zecca/serio", "Saul, che c'è nel pacco?"), L("saul/neutro", "Niente."),
      L("zecca/sorpreso", "E perché lo tieni come un neonato?"), L("saul/neutro", "Perché il niente costa caro.")),
    B("s_c5", C, L("nox/serio", "Lance. Se ci prendono, tu cosa dici?"), L("ferri/serio", "La verità."),
      L("nox/neutro", "E se la verità non ti crede?"), L("ferri/serio", "...Non ci avevo pensato.")),
    B("s_f1", F, L("nox/triste", "Se stiamo fermi mi addormento in piedi. L'ho già fatto. So come si fa.")),
    B("s_f2", F, L("zecca/felice", "Raga, se stiamo fermi faccio una live. Tre... due..."), L("ferri/serio", "Cammina.")),
]
CH["incrocio"] = [
    B("i_ripresa", C, L("zecca/felice", "Lance, Saul, quella di prima la rifacciamo? Due colpi e giù. Non stavo registrando."),
      L("ferri/serio", "No."), L("saul/neutro", "La seconda ripresa si paga. La prima era gratis perché non lo sapevo."),
      L("nox/neutro", "E io ci passo davanti. Ogni volta. Per principio.")),
    B("i_inizio", Z(5.0), L("ferri/serio", "Il mio vecchio giro. Lì facevo le multe. Lì ho fermato un ladro di biciclette."),
      L("saul/neutro", "Era mio cugino. Ti saluta."), L("ferri/serio", "Tuo cugino aveva sessant'anni."),
      L("saul/neutro", "Siamo una famiglia lunga.")),
    B("i_echo", Z(-2.0), L("echo/neutro", "Lance. Telecamera ventisei. C'è un tuo vecchio collega al chiosco. Sta mangiando un panino."),
      L("ferri/serio", "Marino. Mangia sempre in servizio. Lo segnalavo ogni settimana."),
      L("echo/felice", "Ha la maionese sul mento. Lo segnalo io, stavolta.")),
    B("i_auto", V("auto_ferme"), L("nox/serio", "Sono vivi. Respirano. Ma non sbattono le palpebre."),
      L("zecca/triste", "Ho i brividi. E non sto nemmeno registrando. È grave.")),
    B("i_barriera", V("barriera"), L("ferri/sorpreso", "Una barriera LibraCorp. Montata male. Chi l'ha montata verrà richiamato."),
      L("nox/neutro", "Sei ricercato e scrivi ancora i rapporti disciplinari."), L("ferri/serio", "Qualcuno deve farlo.")),
    B("i_radio", E("radio"), L("saul/neutro", "Con me, «vivo» è un ottimo inizio di trattativa. Con la tua Astrid non so."),
      L("ferri/serio", "Con Astrid non si tratta. Si rifà la branda.")),
    B("i_multa", E("multa"), L("zecca/felice", "Nox è un lampeggiante! Nox, fai «niinoo»."), L("nox/neutro", "No."),
      L("zecca/felice", "Solo una volta!"), L("nox/neutro", "...niinoo. Non lo dite a nessuno."),
      L("echo/felice", "L'ho registrato.")),
    B("i_c1", C, L("saul/neutro", "Capo, ti viene da dare la precedenza anche a noi?"), L("ferri/serio", "A te no. A te mai.")),
    B("i_c2", C, L("nox/neutro", "Un semaforo che non cambia mai. Ho lavorato con gente così.")),
    B("i_c3", C, L("zecca/felice", "Lance che guida è come un tutorial: lento, ma ti spiega tutto."), L("ferri/serio", "Grazie."),
      L("zecca/sfotto", "Non era un complimento."), L("ferri/neutro", "Lo prendo lo stesso.")),
    B("i_c4", C, L("saul/neutro", "Echo. Quanto vuoi per spegnere la telecamera sopra la banca?"),
      L("echo/neutro", "Non ho un prezzo."), L("saul/neutro", "Tutti hanno un prezzo."),
      L("echo/serio", "...Allora il mio non lo conosco ancora.")),
    B("i_c5", C, L("echo/neutro", "Nox. Perché bevi il caffè se poi non dormi lo stesso?"),
      L("nox/neutro", "Perché senza caffè non dormo e sono anche triste."),
      L("echo/neutro", "Interessante. Lo aggiungo alla lista delle cose umane che non capisco.")),
    B("i_f1", F, L("ferri/serio", "Non si sosta in mezzo all'incrocio. Neanche con la fine del mondo.")),
]
CH["dentro_rosso"] = [
    B("dr_conto", C, L("saul/neutro", "Capo. Prima ti ho tolto un pugno dalla faccia. Sono venti."),
      L("ferri/serio", "Non pago."), L("saul/neutro", "Ventidue. Gli interessi corrono."),
      L("ferri/serio", "Ventidue cosa?"), L("saul/neutro", "Lo decidiamo quando paghi.")),
    B("dr_inizio", Z(6.0), L("zecca/sorpreso", "È tutto rosso. Anche il cielo. Anche i pensieri."),
      L("ferri/serio", "Restate vicini. Qui dentro le regole le fa lui.")),
    B("dr_echo", Z(-6.0), L("zecca/serio", "Raga, è strano senza Echo. Non c'è nessuno che ci guarda."),
      L("saul/neutro", "Per me è una vacanza.")),
    B("dr_c1", C, L("saul/neutro", "Ci sono auto che galleggiano. Mettilo nel rapporto, capo."),
      L("ferri/serio", "Già fatto. Ho finito le pagine.")),
    B("dr_c2", C, L("nox/neutro", "Questo rosso mi ricorda i miei occhi. Ventotto ore sveglia."),
      L("zecca/felice", "Nox, sei un meme vivente.")),
    B("dr_c3", C, L("zecca/serio", "Saul, se restassimo bloccati qui per sempre, tu che faresti?"),
      L("saul/neutro", "Aprirei un'officina. Clienti fermi. Letteralmente.")),
]
CH["vicolo"] = [
    B("v_distributore", C, L("ferri/serio", "Echo. Tu che vedi tutto. Mi sta guardando qualcuno?"),
      L("echo/neutro", "Telecamera trentuno. Io."), L("ferri/serio", "A parte te."),
      L("echo/neutro", "Nessuno. Ha appena dato un colpetto al distributore. Sul fianco. Come Saul."),
      L("ferri/serio", "Verifica tecnica."), L("echo/felice", "Le sono uscite due merendine."),
      L("ferri/neutro", "...Non è a verbale.")),
    B("v_batteria", C, L("zecca/sorpreso", "Raga. Emergenza. Quattro per cento."),
      L("ferri/serio", "Ho un cavo."), L("zecca/triste", "Connettore sbagliato."), L("ferri/serio", "È quello regolamentare."),
      L("saul/neutro", "Io ho un adattatore."), L("zecca/sorpreso", "Da dove viene?"),
      L("saul/neutro", "Da un posto onesto. Prima che ci passassi io."),
      L("nox/neutro", "Il mio è al due per cento da sei ore. Si vive.")),
    B("v_inizio", Z(5.0), L("nox/neutro", "Il mio vecchio posto. Mangiavo qui, su quel gradino. Panino e silenzio."),
      L("zecca/felice", "Che vita glamour, le Civette."), L("nox/neutro", "Il gradino era comodo. Il panino no.")),
    B("v_echo", Z(-3.0), L("echo/neutro", "Nox. In questo vicolo c'è la telecamera trentuno. Da qui ti vedevo mangiare."),
      L("nox/sorpreso", "...Mi guardavi?"),
      L("echo/neutro", "Ogni notte. Davi le briciole a un gatto. Il gatto si chiamava Ricevuta."),
      L("nox/neutro", "Come fai a sapere il nome del gatto?"), L("echo/felice", "Lo chiamavi ad alta voce. Con affetto.")),
    B("v_cabine", V("cabine"), L("saul/neutro", "Squillano tutte. Nessuno risponda. Neanche per scherzo."),
      L("zecca/sfotto", "Neanche se è uno sponsor?"), L("saul/neutro", "Soprattutto se è uno sponsor.")),
    B("v_manifesti", V("manifesti"), L("ferri/serio", "I nostri manifesti. Già stampati. Che efficienza."),
      L("saul/neutro", "Io sono venuto benissimo. Tu sembri un frigorifero."), L("ferri/serio", "Un frigorifero regolamentare.")),
    B("v_registro", E("registro"), L("zecca/serio", "Nox... va tutto bene?"), L("nox/triste", "No. Ma cammino lo stesso."),
      L("zecca/serio", "Posso camminarti vicino?"), L("nox/neutro", "Puoi.")),
    B("v_adesivo", E("adesivo"), L("ferri/serio", "Saul, il verde sei tu."),
      L("saul/neutro", "Lo so. Faccio sempre questo effetto alle cabine.")),
    B("v_c1", C, L("ferri/serio", "Nox guida in silenzio. È la squadra migliore che abbia mai avuto."),
      L("zecca/felice", "Lance ha detto una cosa carina! Raga, screenshot!"), L("ferri/serio", "Non era carina. Era tecnica.")),
    B("v_c2", C, L("saul/neutro", "Agente Nox, se ci prendono le Civette mi metti una buona parola?"),
      L("nox/neutro", "Dico che sei innocuo."), L("saul/neutro", "Che cattiveria.")),
    B("v_c3", C, L("zecca/felice", "Echo, ti insegno una cosa. Quando una cosa fa ridere si scrive «AHAHAH»."),
      L("echo/neutro", "AHAHAH."), L("zecca/sorpreso", "...Detta così fa paura."), L("echo/triste", "Ci lavoro.")),
    B("v_c4", C, L("echo/neutro", "Lance. Tu non ridi mai. È un problema tecnico?"),
      L("ferri/serio", "È un regolamento."), L("echo/neutro", "Che articolo?"), L("ferri/serio", "...Ci sto lavorando.")),
    B("v_f1", F, L("nox/serio", "Non fermatevi. Le cabine pensano che aspettiate una chiamata.")),
]
CH["dentro_blu"] = [
    B("db_thermos", C, L("nox/serio", "Chi ha toccato il thermos."),
      L("zecca/sorpreso", "Io no! Cioè, l'ho spostato. Per l'inquadratura."),
      L("nox/neutro", "Era pieno a metà. Adesso è pieno a metà meno un sorso."),
      L("zecca/triste", "...Era un sorso piccolo."),
      L("saul/neutro", "Mia nonna diceva: tra una donna e il suo caffè non ci si mette. Si guarda da lontano. Con rispetto.")),
    B("db_inizio", Z(6.0), L("nox/serio", "Sento lo squillo. Ovunque. Anche dentro la testa."),
      L("saul/neutro", "Allora parliamo noi, copriamo il rumore. Capo, racconta una barzelletta."),
      L("ferri/serio", "Articolo quattordici: è vietato raccontare barzellette in servizio."),
      L("zecca/sorpreso", "...Era quella, la barzelletta?"), L("ferri/serio", "Sì."), L("zecca/felice", "Funziona, però.")),
    B("db_c1", C, L("zecca/serio", "Nox, dimmi una cosa bella. Qualsiasi."), L("nox/neutro", "...Il caffè di domani."),
      L("zecca/felice", "Ci sta.")),
    B("db_c2", C, L("saul/neutro", "Agente. Se ti senti cadere, appoggiati. Non ti faccio pagare."),
      L("nox/neutro", "Saul, questa è la cosa più gentile che tu abbia mai detto."), L("saul/neutro", "Lo nego.")),
]
CH["galleria"] = [
    B("g_travestimenti", C, L("ferri/serio", "Siamo in una galleria piena di gente. Non dobbiamo dare nell'occhio."),
      L("zecca/sfotto", "Lance, con quel cappotto sembri un armadio triste."), L("ferri/serio", "Un armadio anonimo. È il punto."),
      L("nox/neutro", "Io ho messo un cappello. Operazione conclusa."),
      L("saul/neutro", "Io ho scambiato la giacca con un manichino. Ci ha guadagnato lui."),
      L("zecca/felice", "Io non mi travesto. Un profilo così non si nasconde."), L("nox/neutro", "È questo il problema.")),
    B("g_inizio", Z(5.0), L("zecca/felice", "La Galleria Lumière! Qui ho girato il mio primo video. Tre like. Uno era mia madre."),
      L("nox/neutro", "E gli altri due?"), L("zecca/triste", "Mia madre con altri due account.")),
    B("g_echo", Z(-4.0), L("echo/neutro", "Rio. Ho visto il tuo primo video. Era qui, telecamera nove."),
      L("zecca/sorpreso", "Quindi i like erano quattro?"), L("echo/neutro", "Io non posso mettere like. Ma l'ho guardato undici volte."),
      L("zecca/felice", "...Echo. Questa è la cosa più bella che mi abbiano mai detto. Ed è inquietante.")),
    B("g_vetrine", V("vetrine"), L("saul/serio", "Quei manichini avevano una faccia, ieri. Si capisce dai vestiti."),
      L("saul/neutro", "Nessuno compra quella giacca se non ha una faccia per portarla.")),
    B("g_manichini", V("manichini"), L("ferri/serio", "Non guardateli negli occhi."),
      L("zecca/sfotto", "Non hanno occhi, Lance."), L("ferri/serio", "Appunto. È più difficile.")),
    B("g_chat", E("chat"), L("nox/neutro", "Spegni quel telefono, Rio. Ogni tanto."),
      L("zecca/triste", "Se lo spengo smetto di esistere."), L("nox/neutro", "Io lo spengo da anni. Esisto benissimo. Più o meno.")),
    B("g_etichetta", E("etichetta"), L("saul/neutro", "Capo, la collezione dice che sei fuori moda."),
      L("ferri/serio", "L'uniforme non va mai fuori moda."), L("zecca/felice", "Raga, questa frase è letteralmente fuori moda.")),
    B("g_c1", C, L("saul/neutro", "Rio guida e siamo già passati davanti a tre negozi di cappelli."),
      L("zecca/felice", "Ricerca sul campo!"), L("saul/neutro", "Ricerca di cosa?"), L("zecca/felice", "Di un cappello.")),
    B("g_c2", C, L("zecca/felice", "Saul, insegnami a mentire. Sei bravissimo."),
      L("saul/neutro", "Prima regola: non chiederlo davanti a un poliziotto."), L("ferri/serio", "Tardi. Ho sentito.")),
    B("g_c3", C, L("echo/neutro", "Saul. Come si capisce se uno mente?"),
      L("saul/neutro", "Dice la verità con troppa cura."), L("echo/serio", "...Capito."),
      L("saul/neutro", "Perché lo chiedi?"), L("echo/neutro", "Per un film.")),
    B("g_f1", F, L("zecca/serio", "Raga, se restiamo fermi i manichini ci copiano. Muoviamoci con stile.")),
]
CH["dentro_verde"] = [
    B("dv_entrata", C, L("zecca/felice", "Raga, dal boss entro io per primo. Al rallentatore."),
      L("ferri/serio", "Si entra in formazione."), L("zecca/felice", "Una formazione al rallentatore."),
      L("saul/neutro", "Entra pure per primo, ragazzino. Il primo colpo lo prendi tu, io intanto guardo dove picchia."),
      L("zecca/serio", "...Formazione. Va bene la formazione.")),
    B("dv_inizio", Z(6.0), L("zecca/sorpreso", "Ci sono io. Ovunque. Mille me in posa. Nessuno ha la faccia."),
      L("saul/neutro", "Guarda me, ragazzino. Io una faccia ce l'ho. Bellissima, tra l'altro."),
      L("zecca/felice", "...Grazie, Saul. Credo.")),
    B("dv_c1", C, L("ferri/serio", "Contate i manichini. Se sono pari, va tutto bene."), L("nox/neutro", "E se sono dispari?"),
      L("ferri/serio", "Non lo so. Volevo solo che contaste qualcosa.")),
    B("dv_c2", C, L("nox/neutro", "Rio. Stammi vicino."), L("zecca/serio", "Hai paura?"),
      L("nox/neutro", "No. Ma se ce l'hai tu, la tengo io per tutti e due.")),
]
CH["caveau"] = [
    B("c_orologio", C, L("saul/neutro", "Capo, che ore sono?"),
      L("ferri/serio", "Quattro e diciassette e nove secondi. Siamo in ritardo di quattro secondi."),
      L("saul/neutro", "Mia nonna diceva: chi conta i secondi non si gode i minuti."), L("ferri/serio", "Quale nonna?"),
      L("saul/neutro", "Quella puntuale. Non l'ho mai vista. Arrivava sempre prima di me.")),
    B("c_inizio", Z(5.0), L("saul/neutro", "Il caveau. Sentite l'odore? Soldi vecchi e cattive intenzioni."),
      L("ferri/serio", "Mani in vista, Saul."), L("saul/neutro", "Le mie mani sono sempre in vista. È questo il trucco.")),
    B("c_echo", Z(-3.0), L("echo/neutro", "Saul. Ci sono diciotto telecamere qui sotto. Le ho spente tutte."),
      L("saul/neutro", "Perché?"), L("echo/felice", "Così, se tocchi qualcosa, lo so solo io."),
      L("saul/neutro", "...Echo, credo di volerti bene. Ed è una sensazione sgradevole.")),
    B("c_lingotti", V("lingotti"), L("saul/neutro", "Lingotti. Veri. Posso toccarne uno? Solo per affetto."),
      L("nox/neutro", "Tocca e ti tagliamo la mano. Lance ha già quella di ricambio."), L("ferri/arrabbiato", "Nox."),
      L("nox/neutro", "Scusa. Era troppo facile.")),
    B("c_laser", V("laser"), L("zecca/felice", "Laser! Come nei film! Saul, fai la capriola!"),
      L("saul/neutro", "Le capriole sono per i dilettanti. Io cammino. Piano. Con stile.")),
    B("c_inventario", E("inventario"), L("zecca/serio", "Lance... vuoi un abbraccio?"), L("ferri/serio", "No."),
      L("zecca/felice", "Te lo do lo stesso. Mentalmente."), L("ferri/neutro", "...Accettato. Mentalmente.")),
    B("c_c1", C, L("nox/neutro", "Saul, guidi stranamente bene. Quasi onesto."),
      L("saul/neutro", "Non dirlo ad alta voce. Ho una reputazione.")),
    B("c_c2", C, L("zecca/serio", "Saul, se potessi rubare una cosa sola, cosa ruberesti?"),
      L("saul/neutro", "Il tempo. Ne avete sprecato tanto, con me. Ve lo restituirei."),
      L("zecca/sorpreso", "...Saul, questa era bella."), L("saul/neutro", "Lo so. Ho rubato anche quella.")),
    B("c_c3", C, L("echo/neutro", "Quando la cupola cade, vi rivedrò? Voi quattro?"),
      L("zecca/felice", "Certo! Sei nei miei contatti!"), L("echo/triste", "...Già. Sono nei tuoi contatti.")),
    B("c_f1", F, L("saul/neutro", "Non fermatevi davanti ai lingotti. Le telecamere vi registrano la faccia golosa.")),
]
CH["tangenziale"] = [
    B("t_nomi", C, L("ferri/serio", "Fuori dalla città servono nomi falsi. Io sono Luca Bianchi. Impiegato. Documenti in ordine."),
      L("saul/neutro", "Troppo in ordine, capo. Nessun impiegato ha i documenti in ordine."),
      L("zecca/felice", "Io sono Rio Tempesta."), L("nox/neutro", "Ti trovano in un minuto."),
      L("zecca/sorpreso", "Ma è memorabile!"), L("nox/neutro", "Appunto. Io sono Maria. Sono sempre Maria. Nessuno si ricorda una Maria."),
      L("saul/neutro", "Io ne ho cinque. Il più onesto è un vescovo.")),
    B("t_conto", C, L("saul/neutro", "Capo, siamo a trentuno."), L("ferri/serio", "Trentuno cosa?"),
      L("saul/neutro", "Il pugno dell'Incrocio. Più gli interessi."),
      L("ferri/serio", "Nel caveau ti ho tirato fuori io da sotto la porta."),
      L("saul/neutro", "Lo so. L'ho scalato dal conto. Restano trentuno.")),
    B("t_pasto", F, L("nox/neutro", "Fermiamoci cinque minuti. Mangiamo tranquilli."),
      L("ferri/serio", "Perché l'hai detto ad alta voce."), L("saul/neutro", "Adesso succede qualcosa. Succede sempre."),
      L("zecca/felice", "...Non succede niente. Visto? Raga, non succede niente."),
      L("echo/neutro", "Pattuglia a quattrocento metri."), L("nox/neutro", "Bene. Benissimo. Il panino lo mangio correndo.")),
    B("t_inizio", Z(6.0), L("ferri/serio", "Tangenziale. Sei corsie, nessuna auto, il sole in faccia. Il posto peggiore per nascondersi."),
      L("saul/neutro", "E il migliore per scappare."),
      L("nox/neutro", "E per dormire. Sdraiatevi sull'asfalto e fingetevi un incidente.")),
    B("t_echo1", Z(0.0), L("echo/triste", "Lance. La telecamera del ponte. Vuoi che la giri?"),
      L("ferri/serio", "Fa' quello che devi."), L("echo/triste", "...La giro."), L("nox/neutro", "Lance."),
      L("ferri/neutro", "Grazie, Echo. ...Non ti ho perdonata. Ma grazie.")),
    B("t_auto", V("auto_ferme"), L("zecca/sorpreso", "Le macchine sono vuote. Con le chiavi ancora dentro."),
      L("saul/neutro", "Non guardatemi."), L("ferri/serio", "Ti stiamo guardando tutti."),
      L("saul/neutro", "Per una volta non tocco niente. Fa male. Ma non tocco.")),
    B("t_cartellone", V("cartellone"), L("nox/neutro", "Le nostre facce, alte cinque metri."),
      L("zecca/felice", "Il mio primo cartellone! Raga, piango.")),
    B("t_casello", V("casello"), L("ferri/serio", "Il casello. Se c'è un posto di blocco, è lì."),
      L("saul/neutro", "Ai caselli c'è sempre un posto di blocco. Per questo io pago in contanti.")),
    B("t_ricercati", E("ricercati"), L("saul/neutro", "«Sguardo onesto: non fidarsi.» Me lo faccio stampare sulle magliette."),
      L("zecca/felice", "Io faccio quelle con «MOLESTO»! Merch!")),
    B("t_verbale", E("verbale"), L("nox/neutro", "La cover coi brillantini del bambino ci salverà. Non pensavo di dirlo mai.")),
    B("t_radio", E("radio"), L("ferri/serio", "Astrid e Strix sullo stesso canale. Non succedeva da dieci anni."),
      L("nox/neutro", "Litigano come una vecchia coppia."),
      L("ferri/serio", "Erano una coppia. Di pattuglia. È finita male."),
      L("nox/sorpreso", "...Non lo sapevo."), L("ferri/neutro", "Nessuno lo sa. Lo metto a verbale e me lo dimentico.")),
    B("t_c1", C, L("zecca/serio", "Raga, ma adesso che siamo fuori, dove andiamo?"), L("saul/neutro", "Dove nessuno ci cerca."),
      L("zecca/sorpreso", "E dov'è?"), L("saul/neutro", "Non lo so. Per questo nessuno ci cerca.")),
    B("t_c2", C, L("nox/neutro", "Cinquantotto ore sveglia. Se crollo lasciatemi qui. Con un cartello: NON SVEGLIARE."),
      L("ferri/serio", "Non si lascia indietro nessuno. Articolo uno."),
      L("nox/neutro", "Il tuo articolo uno cambia ogni giorno."), L("ferri/serio", "Si aggiorna.")),
    B("t_c3", C, L("zecca/serio", "Saul... Echo la perdoniamo?"),
      L("saul/neutro", "Io non perdono. Faccio i conti. E i conti con lei non tornano."),
      L("zecca/triste", "Cioè?"), L("saul/neutro", "Ci ha fregato una volta. Poi ci ha salvato sei. Non so più chi deve cosa a chi.")),
    B("t_c4", C, L("ferri/serio", "Nox. Grazie per il turno di guardia di stanotte."), L("nox/neutro", "Non ero io. Era Rio."),
      L("zecca/sorpreso", "Mi sono addormentato al terzo minuto."),
      L("ferri/neutro", "...Allora grazie a tutti e due per essere vivi lo stesso.")),
    B("t_c5", C, L("echo/triste", "Nox. Le notti erano vere. Te lo giuro su tutte le mie telecamere."),
      L("nox/neutro", "Lo so, Echo. È questo che mi fa arrabbiare."), L("echo/neutro", "...Posso farti compagnia lo stesso?"),
      L("nox/neutro", "Stanotte no. Domani forse.")),
    B("t_f1", F, L("saul/neutro", "Non fermatevi in tangenziale. Mia nonna è morta così."), L("zecca/sorpreso", "DAVVERO?"),
      L("saul/neutro", "No. Ma vedi? Ti sei mosso.")),
]
import re

out = {"_nota": "Testi dell'atto 1 (PROVVISORI). Generati da tools/gen_dialoghi (vedi docs/STORIA.md per voci e arco). Scene: righe + riassunto. Una riga puo' avere 'se' o 'se_non' (vale solo se una scelta e' stata fatta o no) e 'scelte' (lista di {testo, imposta, vai}). 'chiacchiere': battute durante l'esplorazione, per area. Gli id dei personaggi restano ferri/zecca (file e ritratti); i nomi sono Lance e Rio."}
out.update(S)
out["chiacchiere"] = CH

# nomi definitivi nei testi (gli id interni restano ferri/zecca)
NAMES = [(r"\bFerri\b", "Lance"), (r"\bZecca\b", "Rio"), (r"\bAsta\b", "Astrid"), (r"\bAllocco\b", "Strix"), (r"\bKairos\b(?! )", "Kairos")]


def fix(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if k in ("testo", "riassunto") and isinstance(v, str):
                for a, b in NAMES:
                    v = re.sub(a, b, v)
                o[k] = v
            else:
                fix(v)
    elif isinstance(o, list):
        for v in o:
            fix(v)


fix(out)


def dump(o, ind=0):
    t = "\t" * ind
    if isinstance(o, dict) and ("chi" in o or ("id" in o and "quando" in o)):
        return json.dumps(o, ensure_ascii=False)
    if isinstance(o, dict):
        items = [f'{t}\t{json.dumps(k, ensure_ascii=False)}: {dump(v, ind + 1)}' for k, v in o.items()]
        return "{\n" + ",\n".join(items) + "\n" + t + "}"
    if isinstance(o, list):
        items = [f'{t}\t{dump(v, ind + 1)}' for v in o]
        return "[\n" + ",\n".join(items) + "\n" + t + "]"
    return json.dumps(o, ensure_ascii=False)


open(sys.argv[1], "w").write(dump(out) + "\n")
n = sum(len(v["righe"]) for k, v in S.items())
print("scene", len(S), "righe", n, "chiacchiere", sum(len(v) for v in CH.values()))
