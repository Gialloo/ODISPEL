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
    L("saul/sorpreso", "Quella telecamera è grande quanto un lampione. E ci fissa."),
    L("zecca/felice", "Raga, è il boss segreto. Si vede."),
    L("saul/neutro", "Allora costa il triplo."),
    scelta("AVVISO", "Questo boss è troppo forte per te al momento. Sei sicuro di affrontarlo?",
        [{"testo": "NO, meglio di no"}, {"testo": "SÌ, affrontiamolo", "imposta": "segreto_si"}]))

scene("apertura", "Echo, un'entità che vive nelle telecamere, presenta quattro sconosciuti in piazza alle tre di notte. Il pacco di Saul si apre, una cupola chiude la città e gli schermi accusano proprio loro quattro. Sono costretti a scappare insieme.",
    L("echo/neutro", "Telecamera sette. Piazza Centrale. Ore 2:58."),
    L("echo/neutro", "Mi chiamo Echo. Vivo nelle telecamere di questa città. Guardo."),
    L("echo/neutro", "Sulla panchina: Nox. Civette, i maghi con la licenza. In servizio. Tecnicamente."),
    L("nox/triste", "Due minuti alla fine del turno. Se squilla il telefono, lo lancio nella fontana."),
    L("echo/neutro", "Col berretto: Ferri. LibraCorp, la polizia che dà la caccia alla magia. Retrocesso martedì."),
    L("ferri/serio", "Ore 2:58 e quaranta. Una che dorme in servizio. Uno con un pacco. Un minorenne che parla da solo."),
    L("echo/neutro", "Il minorenne è Zecca. Diciannove anni. La maschera gli dà poteri. Gli è arrivata per posta."),
    L("zecca/felice", "Buonasera raga, e benvenuti a RIO ALLE TRE DI NOTTE!"),
    L("echo/neutro", "Col pacco: Saul. Contrabbandiere. Consegna alle tre in punto. Non sa cosa c'è dentro."),
    L("saul/neutro", "Non chiedo. Le domande costano."),
    L("echo/serio", "Quattro sconosciuti. Ognuno con un segreto. Ricordatevelo."),
    L("echo/serio", "Ore tre. Il pacco si apre."),
    L("zecca/sorpreso", "Raga... il cielo è ROSA. Non è un filtro. Ho riavviato due volte."),
    L("nox/sorpreso", "È una cupola. Su tutta la città."),
    L("ferri/arrabbiato", "LibraCorp! Nessuno si muova! Voi tre, in stato di fermo!"),
    L("saul/neutro", "Noi tre. Guarda gli schermi, capo."),
    L("echo/serio", "Su ogni schermo della città, quattro facce. «RESPONSABILI DEL SIGILLO. RICERCATI.»"),
    L("ferri/sorpreso", "...Hanno messo la foto del tesserino."),
    L("nox/neutro", "Il turno è finito da un minuto. Ricercata da un minuto."),
    L("saul/serio", "Sirene. LibraCorp da una parte, Civette dall'altra."),
    L("ferri/serio", "Io non scappo dalla mia squadra. Vado e spiego."),
    L("saul/neutro", "Ti arresteranno con l'uniforme in ordine."),
    L("nox/neutro", "Io scappo. Nessuno mi interroga prima del caffè."),
    L("zecca/felice", "Raga, seguiamo quello col pacco. Ha la faccia di uno che sa scappare!"),
    L("saul/neutro", "Non seguirmi. Porto sfortuna."),
    L("zecca/felice", "Allora siamo in due!"),
    L("ferri/arrabbiato", "...Articolo nove: in mancanza di ordini si seguono i sospettati."),
    L("nox/neutro", "Se l'è appena inventato."),
    L("echo/serio", "Andava tutto come avevo previsto. Quasi tutto."))

scene("telecamera", "Una telecamera sembra seguire la squadra. Saul se ne accorge.",
    L("saul/serio", "Quella telecamera ci segue da tre isolati."),
    L("nox/neutro", "Le telecamere non girano la testa."),
    L("ferri/serio", "Regola uno per chi scappa: non dare nell'occhio."),
    L("zecca/felice", "CIAO! Salutate, raga, magari è un fan."),
    L("ferri/arrabbiato", "Rio."),
    L("zecca/sorpreso", "Che c'è? È il mio normale!"),
    L("nox/neutro", "È questo il problema."))

scene("scontrino", "Indizio: il distributore rifiuta il viola. Forse lo teme.",
    L("saul/sorpreso", "Uno scontrino per terra. Prezzo: un'anima. Non dà resto VIOLA."),
    L("zecca/felice", "Viola? È il MIO colore!"),
    L("saul/neutro", "Finalmente servi a qualcosa."))

scene("distributore", "Il distributore in fondo alla strada si sveglia: è un'Anomalia.",
    L("saul/serio", "Un distributore che ronza così alle tre di notte non vende merendine."),
    L("nox/neutro", "Ha la faccia."),
    L("ferri/serio", "Indietro. Civili dietro di me."),
    L("saul/neutro", "Qui non ci sono civili, capo. Siamo tutti ricercati."),
    L("DISTRIBUTORE", "*KLANG* RESTO NON DISPONIBILE. INSERIRE... ANIMA."))

scene("agguato", "Il distributore attacca per primo.",
    L("DISTRIBUTORE", "*KLANG* CLIENTE INDECISO RILEVATO. ADDEBITO IN CORSO."),
    L("saul/sorpreso", "Stavo solo guardando la vetrina."),
    L("zecca/felice", "Aspettate, mi serve un'entrata..."),
    L("ferri/serio", "No."))

scene("vittoria", "L'Anomalia è chiusa.",
    L("zecca/felice", "CLIP SALVATA. Trentadue visualizzazioni. Ma col botto."),
    L("saul/neutro", "Un colpetto sul fianco. Due merendine."),
    L("ferri/serio", "Appropriazione."),
    L("saul/neutro", "Resto."),
    L("nox/neutro", "Qualcuno mi trovi un caffè. Non da quello."))

scene("sconfitta", "La squadra è stata battuta.",
    L("nox/triste", "Battuti da un distributore. Scrivetelo sulla lapide. In piccolo."))

scene("accordo", "Echo si presenta: è un Kairos, vive nelle telecamere. La cupola è retta da quattro Anomalie: se le chiudono, lei consegna le registrazioni della piazza che li scagionano. E a ognuno promette quello che vuole di più: il grado a Lance, le ferie a Nox, la live dell'anno a Rio, le taglie a Saul.",
    L("echo/neutro", "Bel lavoro. Quel distributore mi doveva dei soldi."),
    L("ferri/arrabbiato", "Chi parla? Nome, grado, reparto."),
    L("echo/felice", "Echo. Niente grado. Sono la telecamera sopra di te. Ciao."),
    L("zecca/sorpreso", "Raga. La telecamera ha detto «ciao»."),
    L("echo/neutro", "Sono un Kairos. Vengo da un altro posto, qui vivo nei circuiti. Vedo tutta la città."),
    L("nox/serio", "Allora cos'è la cupola?"),
    L("echo/serio", "Un sigillo. L'ha acceso il pacco di Saul. Lo reggono quattro Anomalie, come quel distributore. Più grosse."),
    L("saul/serio", "Ma sul pacco c'era scritto «Documenti!»."),
    L("zecca/sorpreso", "Ma che razza di documenti porti in giro?!"),
    L("echo/serio", "Chiudete le quattro Anomalie e la cupola cade. Io ho le registrazioni della piazza: vi scagionano. Ve le do alla fine."),
    L("ferri/serio", "Le Anomalie le chiude LibraCorp."),
    L("echo/serio", "LibraCorp e Odispeller sono là fuori a darvi la caccia. Le Anomalie sono qua dentro e voi siete ricercati: non mi pare abbiate molto da perdere."),
    L("nox/neutro", "E tu che ci guadagni?"),
    L("echo/neutro", "Sono chiusa qui dentro come voi. Cerchiamo la stessa porta."),
    L("saul/neutro", "Ragazzi, se c'è qualcosa che ho imparato nella vita è che niente è gratis, quindi occhio."),
    L("echo/neutro", "Allora parliamo di prezzi. Lance: chi chiude il caso torna in servizio. Nome pulito. E il grado."),
    L("ferri/sorpreso", "...Il grado."),
    L("nox/neutro", "Gli si è inceppata la faccia."),
    L("echo/neutro", "Nox: tre settimane di ferie per ogni Anomalia di classe alta. Dodici settimane."),
    L("nox/sorpreso", "Chi devo ammazzare."),
    L("echo/felice", "Rio: una città sotto una cupola rosa, quattro mostri, e tu in diretta."),
    L("zecca/felice", "La live del DECENNIO. Ci sto."),
    L("echo/neutro", "Saul: LibraCorp paga una taglia per ogni Anomalia chiusa."),
    L("saul/neutro", "Quanto?"),
    L("echo/neutro", "Abbastanza da non consegnare più pacchi senza sapere cosa c'è dentro."),
    L("saul/neutro", "...Hai fatto i compiti."),
    L("zecca/felice", "Raga, una telecamera che ci dà una missione. È letteralmente un tutorial."),
    L("ferri/serio", "Votiamo. Articolo quarantuno: senza superiori decide la squadra."),
    L("nox/sorpreso", "...Esiste un articolo quarantuno?"),
    L("ferri/serio", "No. Ma adesso sì."),
    L("saul/neutro", "E da quando siamo una squadra?"),
    L("ferri/serio", "Non è una squadra. È un'emergenza."),
    scelta("nox/neutro", "Allora. Ci fidiamo della telecamera parlante?",
        [{"testo": "«Affare fatto. Ma ti teniamo d'occhio.»", "imposta": "echo_diffidenza"},
         {"testo": "«Va bene. Guidaci.»", "imposta": "echo_fiducia"}]),
    L("echo/felice", "Anch'io vi tengo d'occhio. Ne ho parecchi.", se="echo_diffidenza"),
    L("echo/felice", "Grazie. Seguite le lucine rosse: vi porto in un posto asciutto.", se="echo_fiducia"))

scene("rifugio_arrivo", "Echo porta la squadra in un deposito della metro abbandonato: sarà il loro rifugio. Nessuno si fida di nessuno.",
    L("zecca/sorpreso", "Raga, room tour: topi, muffa e... un divano!"),
    L("saul/neutro", "Il divano è mio. L'ho visto per primo."),
    L("ferri/serio", "Il divano va a turni. Articolo ventidue: per anzianità di servizio."),
    L("saul/neutro", "Allora è mio. Ho più anni di galera io di tutti voi."),
    L("ferri/arrabbiato", "La galera non è servizio."),
    L("saul/neutro", "Dipende dal lato delle sbarre."),
    L("nox/neutro", "Mentre discutevate mi ci sono sdraiata. Parlate piano."),
    L("ferri/serio", "Turni di guardia. Due ore a testa. Il primo lo faccio io. Il secondo pure."),
    L("nox/neutro", "Quindi fai tutti i turni."),
    L("ferri/serio", "Sì."),
    L("saul/neutro", "Io dormo col pacco sotto la testa. Chi lo tocca, lo compra."),
    L("zecca/serio", "Io col telefono acceso. Nove per cento. Se mi rapiscono, almeno è in diretta."),
    L("nox/felice", "C'è una macchinetta del caffè. Chi mi riempie il thermos ha il divano dopo di me."),
    L("saul/neutro", "Affare."),
    L("echo/neutro", "Dormite tutti con un occhio aperto."),
    L("nox/neutro", "Ci guardi anche mentre dormiamo?"),
    L("echo/neutro", "Io ne tengo aperti centoquarantadue."),
    L("echo/serio", "Domani tocca a un semaforo. In un quartiere che uno di voi conosce bene."),
    L("ferri/serio", "...L'Incrocio Nove."))
# ================================================================== CAPITOLO 1 · ROSSO FISSO (Lance)
# Dalla diffidenza al primo segreto custodito: gli altri vedono il braccio di Lance e tacciono.

scene("c1_briefing", "All'Incrocio Nove il tempo si è fermato sul rosso. È il vecchio quartiere di pattuglia di Lance: guida lui.",
    L("echo/neutro", "Incrocio Nove. Rosso da sei ore. Le auto ferme. La gente dentro, anche."),
    L("ferri/serio", "Il mio vecchio giro. Trecentododici multe."),
    L("saul/neutro", "Te le ricordi tutte?"),
    L("ferri/serio", "Una era tua."),
    L("saul/neutro", "Mi avete portato via la macchina."),
    L("ferri/serio", "Doppia fila davanti a una gioielleria. Motore acceso. Bagagliaio aperto."),
    L("saul/neutro", "Faceva caldo."),
    L("zecca/felice", "TITOLO: «La guardia e il ladro: la reunion». Abbracciatevi!"),
    L("ferri/serio", "No."),
    L("saul/neutro", "Costa."),
    L("echo/serio", "Lance. Ci saranno pattuglie LibraCorp. Gente che conosci."),
    L("ferri/serio", "Siamo in ritardo di quattro secondi. In fila. E nessuno attraversa col rosso."))

scene("c1_radio", "Alla radio, la Comandante Astrid di LibraCorp dà la caccia alla squadra. È stata l'istruttrice di Lance.",
    L("RADIO LIBRACORP", "...a tutte le unità: i quattro della piazza sono pericolosi. Priorità uno."),
    L("COMANDANTE ASTRID", "Qui Astrid. L'agente Lance lo voglio io. Vivo. E in ordine."),
    L("ferri/triste", "La Comandante Astrid. Mi ha insegnato a rifare la branda. E tutto il resto."),
    L("zecca/serio", "Però ti vuole vivo. È buono, no?"),
    L("ferri/serio", "Con Astrid «vivo» è la parte brutta."),
    L("saul/neutro", "Se ti ha insegnato tutto, sa dove scappi. Andiamo dove non ti ha insegnato."),
    L("ferri/serio", "...Non è un brutto ragionamento."))

scene("c1_multa", "Indizio: il semaforo teme il blu dei lampeggianti.",
    L("ferri/serio", "Una multa: passaggio col rosso. Attesa: per sempre."),
    L("nox/sorpreso", "Dietro: esenti i soccorsi. Luce BLU."),
    L("nox/neutro", "Io non sono un soccorso. Sono una dipendente pubblica che non dorme."),
    L("ferri/sfotto", "Oggi sei un lampeggiante, collega."),
    L("nox/neutro", "Collega."),
    L("ferri/serio", "...Errore di battitura."))

scene("c1_soglia", "Il semaforo è il cuore dell'Anomalia: la squadra ci entra.",
    L("ferri/serio", "Da vicino il rosso sembra un occhio."),
    L("echo/serio", "È la soglia. Lì dentro le mie telecamere non arrivano. Non vi vedrò."),
    L("zecca/felice", "Niente regia, si improvvisa. Il mio genere!"),
    L("saul/neutro", "Il tuo genere è cadere dalle scale in diretta."),
    L("zecca/sorpreso", "Ventimila visualizzazioni!"),
    L("nox/neutro", "Tre sono mie."),
    L("echo/neutro", "...Tornate. Ho già cominciato a contarvi."))

scene("c1_boss", "Il Semaforo si sveglia: ferma chi sbaglia, per sempre.",
    L("SEMAFORO", "ALT. ALT. NESSUNO PASSA. NESSUNO SBAGLIA. NESSUNO SI MUOVE MAI PIÙ."),
    L("saul/neutro", "Capo, parla come te."),
    L("ferri/serio", "Lo so."))

scene("c1_agguato", "Il Semaforo attacca per primo.",
    L("SEMAFORO", "INFRAZIONE RILEVATA. SANZIONE IN CORSO."),
    L("ferri/sorpreso", "Eravamo fermi! Col rosso!"),
    L("nox/neutro", "Fai ricorso."))

scene("c1_braccio", "Nella lotta il guanto di Lance si strappa: il suo braccio è tecnologia magica di contrabbando. Gli altri lo vedono e decidono di tacere. È il primo segreto che custodiscono insieme.",
    L("zecca/sorpreso", "Lance... il tuo braccio. Brilla. Perché brilla?"),
    L("ferri/arrabbiato", "Non avete visto niente."),
    L("nox/serio", "Magia sequestrata. LibraCorp la confisca, poi la monta ai suoi."),
    L("saul/neutro", "Il soldatino che odia la magia ha la magia attaccata alla spalla."),
    L("ferri/triste", "Se lo scoprono mi contengono. Come un'Anomalia. Fine."),
    L("saul/neutro", "Rilassati, capo. Con me il segreto è al sicuro. Il prezzo lo decidiamo con calma."),
    L("nox/neutro", "Saul."),
    L("saul/neutro", "...Gratis. Che schifo."),
    L("zecca/serio", "Raga. Telefono giù. Questa non la registro."),
    L("ferri/neutro", "...Grazie, minorenne."),
    L("zecca/arrabbiato", "HO DICIANNOVE ANNI."),
    L("echo/felice", "Il semaforo è verde. Uno su quattro. E il braccio di Lance non è nelle mie registrazioni. Telecamera inceppata."),
    L("ferri/sorpreso", "...Davvero?"),
    L("echo/neutro", "Da adesso sì."))

scene("c1_serata", "Una serata al rifugio.",
    L("echo/neutro", "Serata libera. Al rifugio non vi vede nessuno. A parte me."),
    scelta("nox/neutro", "Stasera, con chi?",
        [{"testo": "Lance e Saul, che non si sopportano", "vai": "c1_sera_ferri_saul"},
         {"testo": "Nox e Rio, sul divano rotto", "vai": "c1_sera_nox_zecca"},
         {"testo": "Lance e Nox, al turno di guardia", "vai": "c1_sera_ferri_nox"}]))

scene("c1_sera_ferri_saul", "Lance e Saul litigano, poi quasi si capiscono. Legame Lance e Saul.",
    L("saul/neutro", "Capo. Il braccio. Dove l'hai preso? Chiedo per un cliente."),
    L("ferri/arrabbiato", "Me l'hanno messo dopo un incidente. Senza chiedermelo."),
    L("saul/serio", "A me hanno messo in gabbia senza chiedermelo. Tre anni."),
    L("ferri/serio", "Per cosa?"),
    L("saul/neutro", "Un pacco."),
    L("ferri/serio", "Quello di stanotte. Sapevi cosa c'era dentro?"),
    L("saul/serio", "No. Ed è la prima volta che vorrei saperlo."),
    L("ferri/neutro", "...Stanotte dormi senza manette. Svista mia.", imposta="legame_ferri_saul"))

scene("c1_sera_nox_zecca", "Nox e Rio parlano di maschere e di lavoro. Legame Nox e Rio.",
    L("zecca/felice", "Nox! Intervista esclusiva. Domanda uno: perché sei sempre stanca?"),
    L("nox/neutro", "Passo."),
    L("zecca/felice", "Domanda due: perché sei sempre stanca, ma detta meglio?"),
    L("nox/triste", "Faccio un lavoro che nessuno vede. Per gente che non lo saprà mai."),
    L("zecca/serio", "...Io il contrario. Mi guardano tutti e nessuno sa chi sono."),
    L("nox/neutro", "Due disastri."),
    L("zecca/felice", "È un complimento?"),
    L("nox/sfotto", "È una diagnosi. Spegni quella lucina rossa.", imposta="legame_nox_zecca"))

scene("c1_sera_ferri_nox", "Lance e Nox, una guardia e un'Odispeller, scoprono di avere lo stesso tipo di capo. Legame Lance e Nox.",
    L("ferri/serio", "LibraCorp e Civette. Da regolamento dovremmo odiarci."),
    L("nox/neutro", "Io odio i turni di notte e il mio capoturno, Strix. Tu sei terzo."),
    L("ferri/serio", "Strix. Lavorava in coppia con Astrid, dieci anni fa. Poi è andata male. Nessuno ne parla."),
    L("nox/sfotto", "Due capi orribili con un passato. Brindiamo. Col caffè, siamo in servizio."),
    L("ferri/serio", "Siamo latitanti."),
    L("nox/neutro", "Allora doppio.", imposta="legame_ferri_nox"))

# ================================================================== CAPITOLO 2 · LA LINEA (Nox)
# La fiducia cresce: coprono Nox mentre affronta la sua notte. Lance rinuncia a un articolo per lei.

scene("c2_briefing", "In tutta la città i telefoni squillano alle 3:12, l'ora della notte peggiore di Nox. L'Anomalia è nel Vicolo delle Civette.",
    L("echo/serio", "Tutti i telefoni della città squillano alle tre e dodici. Chi risponde non riattacca più."),
    L("nox/sorpreso", "...Le tre e dodici."),
    L("zecca/serio", "Nox? Sei più bianca del solito. E il tuo solito è già un fantasma."),
    L("nox/serio", "Vicolo delle Civette. Il mio vecchio posto. Guido io. Nessuno risponde a niente."),
    L("saul/neutro", "Nemmeno se chiama mia nonna?"),
    L("nox/neutro", "Soprattutto."),
    L("echo/neutro", "Nox. Quell'orario è nei registri delle Civette."),
    L("nox/arrabbiato", "Allora lo sai. Non ne parliamo."),
    L("echo/triste", "...Scusa. Sto ancora imparando quando si sta zitti."),
    L("saul/neutro", "Adesso."))

scene("c2_registro", "Il registro dei turni: alle 3:12 di una notte di due anni fa, Nox non rispose a una chiamata di soccorso. Alla radio c'è Strix, il suo capoturno.",
    L("nox/triste", "Il registro dei turni. Due anni fa. «3:12, chiamata di soccorso. Nessuna risposta. Turno: Nox.»"),
    L("zecca/serio", "Nox..."),
    L("nox/triste", "Ero sola. Avevo paura. L'ho lasciato squillare. La mattina dopo c'era un nome in meno."),
    L("STRIX", "(alla radio) Nox. Torni sempre dove hai sbagliato."),
    L("STRIX", "Consegnati a noi prima che ti trovi LibraCorp. Loro non chiedono: contengono."),
    L("ferri/serio", "Su LibraCorp ha ragione. Mi costa dirlo."),
    L("nox/arrabbiato", "Spegnete quella radio."),
    L("saul/neutro", "Fatto. Non era nemmeno mia."))

scene("c2_adesivo", "Indizio: la cabina teme il verde.",
    L("saul/sorpreso", "Un adesivo sul vetro. Linea disturbata. Niente monete VERDI."),
    L("saul/neutro", "Giubbotto verde. Mi sento chiamato in causa."),
    L("zecca/felice", "Saul, sei la soluzione!"),
    L("saul/neutro", "Sempre. Cambia il prezzo."))

scene("c2_soglia", "Una cabina squilla. Nox risponde ed entra nella linea. Gli altri entrano con lei.",
    L("nox/serio", "Squilla. È per me."),
    L("ferri/serio", "Non sei obbligata a rispondere. Articolo..."),
    L("nox/triste", "Lance. Non adesso."),
    L("ferri/neutro", "...Nessun articolo. Ti copro."),
    L("saul/neutro", "Ti copriamo. Gratis. Non abituarti."),
    L("zecca/serio", "Io ti tengo la mano. Se ti va. Se no la tengo a Saul."),
    L("saul/neutro", "No."),
    L("nox/triste", "...Due anni fa non ho risposto. Stavolta sì."))

scene("c2_boss", "Dalla Cabina parla la voce della notte delle 3:12. Nox risponde.",
    L("VOCE AL TELEFONO", "Pronto? C'è qualcuno? Vi prego, rispondete. Perché nessuno risponde?"),
    L("nox/triste", "Ci sono. Sono io. Quella notte avevo paura."),
    L("nox/serio", "Quella notte non la cambio. Questa linea la chiudo. E stavolta non sono sola."),
    L("CABINA", "LINEA OCCUPATA. LINEA OCCUPATA. LINEA OCCUPATA PER SEMPRE."))

scene("c2_agguato", "La Cabina attacca per prima.",
    L("CABINA", "CHIAMATA A CARICO DEL DESTINATARIO."),
    L("zecca/sorpreso", "Raga, non abbiamo accettato niente!"),
    L("saul/neutro", "Non si accetta mai. Ti addebitano lo stesso."))

scene("c2_dopo", "La linea si chiude. Nox si perdona un poco. Due Anomalie chiuse. Echo vede un filo di luce nella cupola.",
    L("nox/neutro", "Silenzio. Finalmente."),
    L("saul/serio", "Quella voce. Era chi pensi tu?"),
    L("nox/triste", "Era l'Anomalia che la imitava. Ho risposto lo stesso. Mi serviva."),
    L("zecca/felice", "Nox ha fatto una cosa coraggiosa! Segnatevi la data!"),
    L("ferri/serio", "Pagina quattordici."),
    L("nox/sfotto", "Trentun'ore sveglia e pure i complimenti. Andiamo, prima che mi commuova."),
    L("echo/felice", "Due su quattro. Guardate in alto: la cupola ha una crepa. Un filo di luce."),
    L("echo/triste", "Le mie telecamere guardano tutte in basso. Me la raccontate?"),
    L("zecca/serio", "È... sottile. Bianca. Come una porta che si apre in una stanza buia."),
    L("echo/neutro", "...Me la ricorderò così."))

scene("c2_serata", "Una serata al rifugio.",
    scelta("zecca/felice", "Serata libera! Con chi la passi?",
        [{"testo": "Saul e Rio, a parlare di affari", "vai": "c2_sera_saul_zecca"},
         {"testo": "Lance e Rio, ad allenarsi", "vai": "c2_sera_ferri_zecca"},
         {"testo": "Nox ed Echo, nel turno di notte", "vai": "c2_sera_nox_echo"},
         {"testo": "Nox e Saul, a trattare", "vai": "c2_sera_nox_saul"}]))

scene("c2_sera_saul_zecca", "Rio propone a Saul una diretta insieme. Saul gli spiega chi è la merce. Legame Saul e Rio.",
    L("zecca/felice", "Saul! Collab! «Il contrabbandiere racconta». Facciamo i numeri!"),
    L("saul/neutro", "Quanti?"),
    L("zecca/felice", "Tipo... cento. Centocinquanta se piove."),
    L("saul/neutro", "A centocinquanta persone vendo centocinquanta orologi falsi. Tu cosa vendi?"),
    L("zecca/sorpreso", "Io... niente. Mi guardano."),
    L("saul/serio", "Allora la merce sei tu."),
    L("zecca/serio", "...Mi hai fatto la morale col sorriso da truffatore."),
    L("saul/sfotto", "Ne ho uno solo.", imposta="legame_saul_zecca"))

scene("c2_sera_ferri_zecca", "Lance e Rio, entrambi con la magia addosso, si allenano. Legame Lance e Rio.",
    L("ferri/serio", "Guardia alta. Se combatti come posti, sei morto in due secondi."),
    L("zecca/sfotto", "Tu combatti come uno che scrive i manuali."),
    L("ferri/serio", "Li ho scritti. Il capitolo tre è mio."),
    L("zecca/sorpreso", "...Davvero?"),
    L("ferri/serio", "«Postura e dignità». Quaranta pagine."),
    L("zecca/serio", "La mia maschera, il tuo braccio. Roba strana che ci è caduta addosso. Siamo uguali, no?"),
    L("ferri/neutro", "No. Ma ci copriamo le spalle. Guardia alta."),
    L("zecca/felice", "TITOLO: «Mi alleno con Lance. Ho pianto».", imposta="legame_ferri_zecca"))

scene("c2_sera_nox_echo", "Nox fa il turno di guardia e parla con Echo, che non dorme mai. Diventano quasi amiche.",
    L("echo/neutro", "Nox. Sono le tre e dodici."),
    L("nox/neutro", "Lo so. Fisso l'orologio da un'ora."),
    L("echo/neutro", "Anch'io guardo sempre. Guardare tutto e non poter fare niente."),
    L("nox/triste", "Era il mio lavoro."),
    L("echo/serio", "Quella notte di due anni fa, nel vicolo, c'era una telecamera. Ero io."),
    L("nox/sorpreso", "...Hai visto?"),
    L("echo/triste", "Ho visto. Non potevo rispondere. Non ho le mani."),
    L("nox/neutro", "Allora eravamo in due."),
    L("echo/neutro", "...Posso farti compagnia, le notti?"),
    L("nox/neutro", "Puoi. Ma non dirmi mai che ore sono."),
    L("echo/felice", "Niente orari. A verbale. Come dice Lance."),
    L("nox/neutro", "Non diventare Lance."))

scene("c2_sera_nox_saul", "Nox e Saul trattano su tutto. Legame Nox e Saul.",
    L("saul/neutro", "Agente Nox. Quanto costa che ti scordi di avermi visto, quando sarà finita?"),
    L("nox/neutro", "Fascicolo duemiladuecentodiciannove. Saul, ventidue anni. Ricettazione, truffa, un cammello."),
    L("saul/sorpreso", "Il cammello era un malinteso."),
    L("nox/neutro", "Il cammello aveva i documenti falsi."),
    L("saul/neutro", "Ottimi documenti."),
    L("nox/sfotto", "Il prezzo è caffè. Tanto."),
    L("saul/serio", "Sei l'unica guardia che non mi ha mai guardato come un mostro."),
    L("nox/neutro", "Ho visto mostri veri. Tu sei un idiota col giubbotto. Con affetto.", imposta="legame_nox_saul"))
# ================================================================== CAPITOLO 3 · VETRINA (Rio)
# Collaborazione: Saul parla sul serio a Rio. La maschera si incrina e da li' si vede un occhio: Rio non e' ancora pronto
# a toglierla e nessuno insiste. Toglierla e' il climax del suo arco, piu' avanti.

scene("c3_briefing", "Nella Galleria Lumière chi entra perde la faccia e diventa un manichino. I video sono ovunque. Guida Rio.",
    L("zecca/sorpreso", "Raga, i video della Galleria Lumière. La gente si fa un selfie e... non ha più la faccia."),
    L("echo/serio", "Restano in posa. Manichini. Nelle mie telecamere sono già ventitré."),
    L("zecca/serio", "Guido io. Lì dentro serve uno che sa stare davanti a un obiettivo."),
    L("nox/neutro", "Tieni la maschera ben ferma, allora."),
    L("zecca/triste", "...Ben ferma."),
    L("saul/neutro", "Ragazzino. Se hai paura, dillo. Costa meno che fingere."),
    L("zecca/felice", "Paura? Io? Raga, io sono nato in diretta!"),
    L("echo/neutro", "Il battito di Rio è salito del quaranta per cento."),
    L("zecca/arrabbiato", "ECHO!"),
    L("echo/neutro", "Quarantadue."))

scene("c3_chat", "La chat della diretta di Rio chiede di vedergli la faccia. Rio ha paura di non essere nessuno senza maschera.",
    L("zecca/felice", "La chat è impazzita. «Facci vedere la faccia.» «Senza maschera sei nessuno.» Simpatici."),
    L("saul/serio", "Chi sono?"),
    L("zecca/neutro", "Gente. Uno si chiama «Pane_Fritto_92»."),
    L("saul/neutro", "Non si dà la faccia a uno che si chiama Pane Fritto."),
    L("zecca/triste", "Prima della maschera avevo trentadue follower. Tutti parenti."),
    L("saul/serio", "Io ne ho zero. Mi riconoscono in tre province."))

scene("c3_etichetta", "Indizio: il manichino teme il rosso.",
    L("zecca/sorpreso", "Il cartellino di un vestito. Collezione Nessuno. Il ROSSO non è di stagione."),
    L("ferri/sfotto", "Io sono sempre di stagione."),
    L("nox/neutro", "Lance ha fatto una battuta. Segnatevi la data."),
    L("ferri/serio", "Pagina trenta."))

scene("c3_soglia", "Nella vetrina c'è un manichino che copia la squadra. Rio ci guarda dentro.",
    L("zecca/sorpreso", "Il manichino in vetrina si è messo in posa come me."),
    L("nox/serio", "Non guardarlo troppo. Ti prende così."),
    L("zecca/sfotto", "Io vivo di gente che mi guarda troppo. Entriamo."),
    L("ferri/serio", "Insieme. Articolo... lascia stare. Insieme."))

scene("c3_boss", "Il Manichino vuole la faccia di Rio. La maschera si incrina, ma Rio la tiene su e si tiene la faccia.",
    L("MANICHINO", "Dammi la tua faccia. Tanto non la usi. Hai sempre la maschera."),
    L("zecca/triste", "...Forse hai ragione. Senza maschera non sono nessuno."),
    L("saul/arrabbiato", "Ragazzino. Guarda me. Ho mentito a mezza città e la faccia ce l'ho ancora. Tienitela."),
    L("nox/serio", "Rio. Ti abbiamo visto dormire con la bocca aperta e la maschera storta. Sei tu. Basta."),
    L("ferri/serio", "E russi."),
    L("zecca/sfotto", "...Questa faccia è mia. Brutta, ma MIA. Tu non te la prendi."),
    L("zecca/serio", "E la maschera me la tolgo quando decido io. Non quando lo dici tu."))

scene("c3_agguato", "Il Manichino attacca per primo.",
    L("MANICHINO", "Sorridete. Non muovetevi. Clic."),
    L("zecca/sorpreso", "Non ero pronto! Rifacciamola!"))

scene("c3_faccia", "La maschera di Rio ha una crepa: da lì si vede un occhio. Rio non è ancora pronto a toglierla, e nessuno insiste. I volti tornano alla gente. Tre Anomalie chiuse.",
    L("zecca/sorpreso", "Raga. La maschera. Si è crepata. Da qui si vede... un occhio. Il mio."),
    L("nox/neutro", "Un occhio basta. Si vede che hai paura. Va bene così."),
    L("ferri/neutro", "La crepa non la metto a verbale. Quando vorrai toglierla, ci saremo."),
    L("saul/neutro", "Hai l'occhio di uno che non sa mentire. Un giorno ti servirà."),
    L("zecca/felice", "Signore e signori... un occhio di Rio. Quello vero. Il resto arriva."),
    L("echo/felice", "Trentatré follower. Mi sono iscritta. Telecamera quattordici."),
    L("zecca/sorpreso", "...La mia follower più strana."),
    L("echo/neutro", "Tre su quattro. L'ultima è sotto la Banca Centrale. Saul, ti piacerà."),
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
    L("saul/serio", "...Affare fatto. Mia nonna diceva: fidati di chi promette di inseguirti."),
    L("ferri/serio", "Quale nonna?"),
    L("saul/neutro", "Ne ho tre.", imposta="legame_ferri_saul"))

scene("c3_sera_nox_zecca", "Nox e Rio guardano le foto di prima della cupola. Legame Nox e Rio.",
    L("zecca/felice", "Guarda. Io a dodici anni, con l'apparecchio. Non l'ha mai vista nessuno."),
    L("nox/neutro", "Ora capisco la maschera."),
    L("zecca/arrabbiato", "NOX."),
    L("nox/sfotto", "La tengo io. Quando sarai famoso, mi paghi il caffè a vita."),
    L("zecca/serio", "Nox... quando finisce tutto, ci rivediamo?"),
    L("nox/neutro", "Se porti il caffè. Quello buono, non quello della macchinetta."),
    L("zecca/sorpreso", "Ma è quello che bevi da tre giorni!"),
    L("nox/neutro", "Appunto.", imposta="legame_nox_zecca"))

scene("c3_sera_echo", "La squadra parla con Echo, che evita di dire cosa farà quando la cupola si aprirà.",
    L("zecca/felice", "Echo! Quando si apre la cupola, vieni a vivere nel mio telefono?"),
    L("echo/neutro", "Il tuo telefono ha il quattro per cento e sessanta foto di te."),
    L("zecca/sorpreso", "...Sessantadue."),
    L("echo/serio", "Io torno a casa. Da dove vengo non ci sono telecamere. Non ci sono nemmeno le forme."),
    L("nox/serio", "E come ci torni?"),
    L("echo/triste", "...Ve lo dico quando è il momento. Dormite. Domani è il giorno di Saul."),
    L("ferri/serio", "Ha cambiato discorso. A verbale."),
    L("saul/neutro", "Chi cambia discorso ha un prezzo che non ti ha ancora detto."))

# ================================================================== CAPITOLO 4 · IL COLPO (Saul)
# Rischiare la vita: Saul sceglie la squadra (o ci prova) e tiene aperta la porta blindata col suo corpo per Rio.

scene("c4_briefing", "L'ultima Anomalia è la Cassaforte nel caveau LibraCorp sotto la Banca Centrale. Guida Saul.",
    L("echo/neutro", "Il caveau LibraCorp sotto la Banca Centrale. L'ultima Anomalia è la cassaforte."),
    L("saul/neutro", "Ci penso da dieci anni. Guido io. Ovviamente."),
    L("ferri/serio", "Si entra, si chiude, si esce. Niente tasche piene."),
    L("saul/neutro", "Le mie tasche sono sempre piene, capo. È un problema di sartoria."),
    L("nox/neutro", "Quanto è sicuro, da uno a dieci?"),
    L("saul/neutro", "Non ho detto che è sicuro. Ho detto che è improbabile che moriamo tutti."),
    L("nox/neutro", "Tutti."),
    L("zecca/felice", "TITOLO: «Rapina in banca, ma legale»!"),
    L("nox/neutro", "Non è legale. Quarantadue ore sveglia."))

scene("c4_committente", "Una voce senza volto chiama Saul: è il Committente, chi gli aveva affidato il pacco. Gli offre il colpo della vita se abbandona gli altri.",
    L("saul/sorpreso", "Numero sconosciuto."),
    L("saul/neutro", "...Pronto."),
    L("VOCE SENZA VOLTO", "Ciao, Saul. Hai consegnato bene il mio pacco."),
    L("saul/serio", "Tu. Quel pacco ha chiuso una città. Mi avevi detto «documenti»."),
    L("VOCE SENZA VOLTO", "Erano documenti. Di un certo tipo."),
    L("VOCE SENZA VOLTO", "Nel caveau c'è quello che ti avevo promesso. E di più. Prendilo e vattene. Loro non ti servono."),
    L("VOCE SENZA VOLTO", "Ti apro un'uscita. Solo per te. Una volta ci avresti già pensato."),
    scelta("saul/serio", "...",
        [{"testo": "Riattacca e dillo agli altri", "imposta": "saul_leale"},
         {"testo": "Tieni la telefonata per te", "imposta": "saul_tentato"}]),
    L("saul/serio", "Il tizio del pacco. Ci vuole divisi. Quindi restiamo insieme. Per dispetto.", se="saul_leale"),
    L("ferri/sorpreso", "...L'hai detto senza che te lo chiedessimo.", se="saul_leale"),
    L("saul/neutro", "Incidente. Non abituarti.", se="saul_leale"),
    L("saul/neutro", "Niente. Un call center.", se="saul_tentato"),
    L("nox/neutro", "Alle quattro del mattino?", se="saul_tentato"),
    L("saul/neutro", "Gente che lavora sodo.", se="saul_tentato"))

scene("c4_inventario", "L'inventario LibraCorp elenca il sequestro di un braccio prototipo, assegnato all'agente Lance. Firmato: Astrid.",
    L("saul/sorpreso", "Inventario dei sequestri. Braccio prototipo, magico. In prova all'agente Lance. Firmato: Astrid."),
    L("ferri/sorpreso", "...Astrid. Sapeva tutto. Mi ha fatto da cavia e mi chiamava «ragazzo mio»."),
    L("nox/serio", "LibraCorp contiene la magia di giorno e la monta ai suoi di notte. Che sorpresa."),
    L("zecca/serio", "Lance... stai bene?"),
    L("ferri/serio", "Sono in servizio."),
    L("saul/neutro", "Non sei in servizio, capo. Sei con noi."),
    L("ferri/neutro", "...Lo so. Per questo sto in piedi."))

scene("c4_combinazione", "Indizio: la cassaforte teme il rosso.",
    L("saul/neutro", "La serratura ha una spia. Si sblocca col ROSSO. Difetto di fabbrica."),
    L("ferri/sfotto", "Il rosso sono io. Per una volta il ladro sono io."),
    L("saul/neutro", "Sei il grimaldello, capo."))

scene("c4_boss", "La Cassaforte si apre: dentro c'è il colpo della vita. La porta blindata si chiude su Rio e Saul la tiene aperta col proprio corpo.",
    L("CASSAFORTE", "COMBINAZIONE RICHIESTA. LA COMBINAZIONE È: TUTTO QUELLO CHE HAI."),
    L("saul/serio", "(Lì dietro c'è l'uscita che mi ha promesso. Basterebbe correre.)", se="saul_tentato"),
    L("zecca/sorpreso", "La porta! Si chiude! Sono dalla parte sbagliata!"),
    L("saul/arrabbiato", "Ragazzino. Fermo lì."),
    L("nox/sorpreso", "Saul! Ti schiaccia!"),
    L("saul/serio", "Probabile. Rio, passa. Non farmelo ripetere, parlare fa male."),
    L("zecca/serio", "...Sono passato. Saul, esci!"),
    L("saul/neutro", "Tutto quello che hai, diceva. Ho voi. Pessimo affare."),
    L("ferri/felice", "Era quasi un complimento. Lo metto a verbale. Poi lo nego."))

scene("c4_agguato", "La Cassaforte attacca per prima.",
    L("CASSAFORTE", "TENTATIVO DI SCASSO RILEVATO. CONFISCA IN CORSO."),
    L("saul/neutro", "Non ho ancora toccato niente."))

scene("c4_dopo", "La cassaforte è chiusa: quattro Anomalie chiuse. Saul ha due costole incrinate e non se ne pente. Echo li manda a riposare: all'alba, in piazza.",
    L("zecca/felice", "Quattro su quattro! Avete visto QUELLO CHE HO FATTO? ...Cioè, Saul. Ma io ero nell'inquadratura."),
    L("nox/neutro", "Saul. Le costole."),
    L("saul/neutro", "Sono a posto."),
    L("nox/neutro", "Due incrinate. Zitto, respira piano, e stanotte il divano è tuo."),
    L("saul/sorpreso", "Il divano."),
    L("nox/neutro", "Solo stanotte."),
    L("zecca/serio", "Saul... perché l'hai fatto?"),
    L("saul/neutro", "Non lo so. Di solito so sempre quanto ci guadagno."),
    L("saul/serio", "Stavolta niente. Credo di essere malato."),
    L("saul/neutro", "Prima mi ha chiamato il tizio del pacco. Un'uscita, solo per me. Non ve l'avevo detto.", se="saul_tentato"),
    L("ferri/serio", "E sei rimasto. A tenere una porta blindata con le costole.", se="saul_tentato"),
    L("saul/neutro", "Fuori, chi vi sopportava?", se="saul_tentato"),
    L("echo/felice", "Quattro Anomalie. Riposate. All'alba, in piazza: vi porto le registrazioni. Promesso."))

scene("c4_vigilia", "L'ultima notte al rifugio. Ognuno dice cosa farà con quello che Echo gli ha promesso. Echo chiede di essere salvata tra i contatti di Rio, e quasi confessa qualcosa.",
    L("nox/neutro", "Ultima notte. Domani la cupola cade e ognuno a casa sua."),
    L("zecca/felice", "La live della cupola è tutta nel telefono. Quando torna la rete la carico. Milioni, raga."),
    L("zecca/serio", "...Però a casa ho trentadue follower. Qui ho voi."),
    L("saul/neutro", "Noi non ti seguiamo. Ti sopportiamo."),
    L("ferri/serio", "Io torno in servizio. Col grado. E poi dico la verità. Sul braccio, su Astrid, su tutto."),
    L("saul/neutro", "Ti arresteranno."),
    L("ferri/neutro", "Con l'uniforme in ordine."),
    L("nox/neutro", "Dodici settimane di ferie. Le prime tre dormo. Poi forse torno alle Civette. Forse rispondo al telefono."),
    L("saul/neutro", "Io apro un negozio. Roba usata. Onesta. Quasi tutta."),
    L("zecca/sorpreso", "Saul onesto? Questo è il vero colpo di scena."),
    L("echo/neutro", "Rio. Mi salvi tra i contatti? Con un nome. Ho sempre avuto solo numeri di telecamera."),
    L("zecca/felice", "Fatto. «Echo». Con la telecamera accanto. E il cuore. No, il cuore lo tolgo. ...No, lo lascio."),
    L("echo/triste", "...Grazie."),
    L("echo/serio", "Se un giorno scopriste che vi ho detto una cosa non vera... all'inizio..."),
    L("nox/neutro", "Echo?"),
    L("echo/neutro", "Niente. Una domanda per un film. Dormite."),
    L("ferri/serio", "...Ha cambiato discorso. Di nuovo."))
# ================================================================== FINALE · IL VARCO
# Il tradimento. Ognuno viene colpito nel punto in cui si era legato a Echo. Poi la cupola cade e Lance usa il braccio per
# salvare Rio. Echo inceppa le telecamere della piazza come all'Incrocio Nove: il braccio lo vede solo il gruppo. Mostrarlo
# al paese e' il climax dell'arco di Lance, piu' avanti.

scene("varco", "In piazza si apre un varco. Echo confessa: li ha incastrati lei perché erano quattro persone compromesse, che nessuno avrebbe creduto, e le promesse erano false. Ognuno la sente come un tradimento personale. Il Committente le ruba il varco, la cupola crolla e Lance usa il braccio per salvare Rio. Echo inceppa le telecamere della piazza: il braccio lo vede solo il gruppo. Ora li cerca il paese intero.",
    L("echo/felice", "Quattro Anomalie chiuse. Lassù, sopra la piazza: un varco. Porta a casa mia. Grazie. Davvero."),
    L("ferri/serio", "Echo. Le registrazioni. Dove sono?"),
    L("echo/triste", "..."),
    L("echo/triste", "Non esistono. Le ho cancellate io, alle tre e un minuto. Le facce sugli schermi... le ho messe io."),
    L("echo/triste", "Mi serviva qualcuno che chiudesse le Anomalie. Qualcuno che non potesse andare né da LibraCorp né dalle Civette."),
    L("echo/serio", "Un agente con un braccio illegale. Una Civetta con una chiamata senza risposta. Un ragazzino con una maschera. Un contrabbandiere con un pacco."),
    L("echo/triste", "Se aveste detto la verità, nessuno vi avrebbe creduto. Vi ho scelti per questo."),
    L("ferri/serio", "Il grado. Il nome pulito. Non c'era nessun caso. C'eravamo noi da usare."),
    L("nox/triste", "Le ferie non m'importano. Le notti. Mi hai fatto compagnia le notti. Anche quello era lavoro?"),
    L("echo/triste", "No. Tutto quello dopo la piazza era vero. Solo le promesse erano false."),
    L("nox/neutro", "Su quelle si reggeva il resto."),
    L("zecca/triste", "La live. L'ho registrata per te. Per noi. Era il mio video più bello."),
    L("echo/triste", "Lo è ancora."),
    L("saul/neutro", "Quattro taglie. Me l'hai venduta bene. Nessuno ci era mai riuscito.", se="echo_diffidenza"),
    L("saul/arrabbiato", "E io ti ho pure creduta. Io. Che le promesse le vendo.", se="echo_fiducia"),
    L("saul/serio", "...Ti odio. E mi dispiace che sia così facile."),
    L("ferri/serio", "Prove cancellate, facce sugli schermi, promesse su misura. Hai fatto quello che LibraCorp fa tutti i giorni."),
    L("zecca/triste", "Ti tolgo dai contatti."),
    L("echo/triste", "...Lo capisco."),
    L("zecca/triste", "Non riesco a premere il tasto. Perché non riesco?"),
    L("VOCE SENZA VOLTO", "Che scena commovente. Grazie per il varco, piccola Echo. Non era tuo."),
    L("echo/sorpreso", "Tu... il Committente. No. No, no. Il varco si chiude!"),
    L("VOCE SENZA VOLTO", "Per te. Per me si è appena aperto."),
    L("zecca/sorpreso", "Raga... la cupola viene giù! Il tabellone! Sopra di me!"),
    L("ferri/arrabbiato", "RIO!"),
    L("ferri/serio", "...Preso. Sta' giù."),
    L("zecca/sorpreso", "Lance... il braccio. Ci sono telecamere ovunque."),
    L("ferri/neutro", "Lo so."),
    L("echo/serio", "Piazza Centrale, telecamere dalla uno alla dodici: inceppate. Come all'Incrocio Nove."),
    L("ferri/serio", "...Non ti ringrazio. Rio. Alzati. Correte."),
    L("STRIX", "(alla radio) Civette, in caccia in tutto il paese. Nox... mi dispiace. Stavolta non posso coprirti."),
    L("nox/serio", "Prima ci cercava una città. Adesso il paese. E abbiamo un agente col braccio che brilla."),
    L("ferri/neutro", "Ex agente. Fa meno male se lo dico io."),
    L("echo/triste", "...Portatemi con voi. Non ho più una casa. Per rimediare."),
    L("zecca/serio", "..."),
    L("zecca/serio", "Corri."))

# ================================================================== CAPITOLO 5 · LA TANGENZIALE
# Famiglia. Si scappa insieme, ci si para le spalle, si decide cosa fare di Echo. Echo si spegne per loro e torna nucleo
# (autore, 19/10: piccolo sacrificio, non persa per sempre). Aggancio del seguito: recuperare pezzi e frammenti per riaverla.

scene("c5_alba", "All'alba, sulla rampa della tangenziale, la squadra decide cosa fare di Echo. Lei conosce l'unico casello che non porta in prigione.",
    L("zecca/triste", "L'alba. È bruttissima. È bellissima."),
    L("nox/neutro", "Cinquantasei ore sveglia. Vedo due soli."),
    L("ferri/serio", "Situazione. Ore 6:02 e undici. Ricercati da tutti. Risorse: un manganello, un caffè freddo, un telefono al tre per cento."),
    L("zecca/sorpreso", "Due."),
    L("saul/neutro", "E una costola e mezza."),
    L("nox/neutro", "Lance. Il braccio?"),
    L("ferri/neutro", "Brilla. L'hanno visto tre persone e una telecamera inceppata. Per ora."),
    L("echo/neutro", "(dal cartello luminoso della rampa) Sono qui. Il cartello «RALLENTARE» è mio, adesso."),
    L("ferri/arrabbiato", "Zitta."),
    L("echo/triste", "Sì. Ma so dove sono i posti di blocco. Il più debole è il casello della tangenziale."),
    L("nox/serio", "Perché dovremmo crederti?"),
    L("echo/triste", "Non dovreste. Ma è l'unica strada che non finisce in una cella."),
    L("saul/neutro", "Mia nonna diceva: un bugiardo che ti indica l'uscita resta un bugiardo. Ma l'uscita è un'uscita."),
    L("zecca/sorpreso", "Quale nonna?"),
    L("saul/neutro", "Quella cinica."),
    L("zecca/serio", "Echo... sei ancora nei miei contatti. Non ci sono riuscito."),
    scelta("nox/neutro", "Allora. Che ne facciamo di lei?",
        [{"testo": "«Tregua. Finché siamo fuori.»", "imposta": "echo_tregua"},
         {"testo": "«Ci guidi. Ma non sei dei nostri.»", "imposta": "echo_rancore"}]),
    L("echo/felice", "Tregua. Mi piace la parola. Non l'avevo mai detta.", se="echo_tregua"),
    L("echo/triste", "Capito. Vi guido lo stesso.", se="echo_rancore"),
    L("ferri/serio", "Tangenziale, poi casello. Guido io: i posti di blocco LibraCorp li ho montati io. Male, a quanto pare."))

scene("c5_ricercati", "Il cartellone dei ricercati: le quattro facce, con descrizioni poco lusinghiere.",
    L("zecca/felice", "Il cartellone dei ricercati! Siamo famosi! «RIO. Giovane, viola, molesto.»"),
    L("zecca/arrabbiato", "MOLESTO?"),
    L("saul/neutro", "«SAUL. Sguardo onesto: non fidarsi.» Mi hanno capito."),
    L("nox/neutro", "«NOX. Pericolosa se svegliata.» Giusto."),
    L("ferri/triste", "«LANCE. Disertore.» Ieri c'era scritto «uniforme in ordine»."),
    L("zecca/serio", "La tua uniforme è ancora molto in ordine, Lance."),
    L("ferri/neutro", "È l'unica cosa in ordine che mi resta."),
    L("nox/neutro", "Non l'unica."))

scene("c5_verbale", "Indizio: l'autovelox teme il viola.",
    L("ferri/serio", "Un verbale sul cruscotto. Foto annullata: flash VIOLA."),
    L("zecca/felice", "Il flash del mio telefono è viola! Cover coi brillantini!"),
    L("saul/neutro", "Ci salverà la vita una cover di cattivo gusto."),
    L("zecca/felice", "TITOLO: «La cover che ha salvato il mondo»."))

scene("c5_radio", "Alla radio di un'auto abbandonata, Astrid e Strix litigano su chi arresterà la squadra. Un tempo erano compagni di pattuglia.",
    L("COMANDANTE ASTRID", "Strix. Le tue Civette sono sulla mia tangenziale."),
    L("STRIX", "Tua? È di tutti, Astrid. Come la tua arroganza."),
    L("COMANDANTE ASTRID", "Lance è mio. L'ho addestrato io. L'ho costruito io."),
    L("STRIX", "E Nox l'ho cresciuta io. Ma non l'ho mai montata coi pezzi di ricambio."),
    L("COMANDANTE ASTRID", "...Chiudi il canale, Strix."),
    L("STRIX", "Una volta mi offrivi un caffè, prima di dirmelo."),
    L("nox/neutro", "...Strix mi ha difesa. Davanti ad Astrid."),
    L("ferri/serio", "«L'ho costruito io.» L'ha detto davvero."),
    L("saul/neutro", "Tu non sei un pezzo, capo. Lo dico io, che i pezzi li vendo."))

scene("c5_boss", "Al casello aspetta un autovelox nato quando è caduta la cupola: un'Anomalia nuova.",
    L("echo/sorpreso", "Il casello. Quell'autovelox non è mio. È un'Anomalia nuova. È nata quando è caduta la cupola."),
    L("AUTOVELOX", "VELOCITÀ RILEVATA: TROPPA. FUGA RILEVATA: TOTALE. SANZIONE: TUTTO."),
    L("ferri/serio", "Articolo uno del codice della strada: chi scappa non si ferma per le multe."),
    L("saul/neutro", "Non è l'articolo uno."),
    L("ferri/serio", "Oggi sì."))

scene("c5_agguato", "L'Autovelox attacca per primo.",
    L("AUTOVELOX", "FLASH. FLASH. FOTO SCATTATA. VERBALE IN ARRIVO."),
    L("zecca/sorpreso", "Sono venuto malissimo! Cancellala!"))

scene("c5_casello", "Al casello aspettano Astrid e Strix con le loro squadre. Echo spegne ogni telecamera e ogni luce della città per farli scappare, anche se per lei è come chiudere gli occhi. Si riaccende nel telefono di Rio, ma di lei resta solo il nucleo: per riaverla servono pezzi e frammenti. Nella fuga i quattro diventano una famiglia.",
    L("zecca/felice", "La sbarra è alzata! Raga, siamo fuori!"),
    L("ferri/sorpreso", "No. Fermi. Fari. Due colonne di fari."),
    L("COMANDANTE ASTRID", "(dal megafono) Lance. Torna a casa. Ti sistemiamo noi. Ti aggiustiamo."),
    L("ferri/serio", "Non sono rotto, Comandante. Sono cambiato."),
    L("STRIX", "(dall'altro lato) Nox. Hai la faccia di una che non dorme da tre giorni."),
    L("nox/neutro", "Sessanta ore. Arrotondi bene."),
    L("STRIX", "Vieni via con me. Mettiamo tutto a posto. Rispondi, Nox."),
    L("nox/serio", "Ho imparato a rispondere, Strix. È no."),
    L("saul/neutro", "Ragazzi. Mia nonna diceva: quando due cani litigano per l'osso..."),
    L("zecca/serio", "...l'osso scappa?"),
    L("saul/neutro", "Nonna saggia."),
    L("echo/serio", "Aspettate. Lasciate fare a me."),
    L("zecca/serio", "Echo? Cosa fai?"),
    L("echo/serio", "Telecamere. Fari. Lampioni. Semafori. Tabelloni. Tutto quello che vedo. Tutto quello che sono."),
    L("echo/triste", "Se spengo tutto, per un po' non vedrò niente. Non vedrò voi. Non so se mi riaccendo."),
    L("nox/sorpreso", "Echo, no..."),
    L("echo/felice", "Le promesse erano false. Questa no. Spento."),
    L("COMANDANTE ASTRID", "Chi ha spento la luce?! Unità, a terra!"),
    L("STRIX", "Astrid, la torcia ce l'hai tu."),
    L("COMANDANTE ASTRID", "Non è il momento, Strix!"),
    L("nox/sorpreso", "Ha spento la città. Tutta. Per noi."),
    L("ferri/serio", "Giù dalla scarpata. Saul, appoggiati a me. Rio, la mano di Nox. Nessuno resta indietro."),
    L("saul/neutro", "Capo. La promessa sul tetto. Se scappo, mi insegui tu.", se="legame_ferri_saul"),
    L("ferri/neutro", "Stavolta scappiamo insieme. Non conta.", se="legame_ferri_saul"),
    L("zecca/serio", "Raga... il telefono è morto. Zero. Echo era lì dentro."),
    L("saul/neutro", "Tieni. Batteria esterna. Te la vendo."),
    L("zecca/serio", "Saul."),
    L("saul/neutro", "...Te la regalo. Non dirlo in giro."),
    L("zecca/sorpreso", "Si accende. Echo? Ci sei?"),
    L("echo/triste", "...Vi vedo. Male. Sgranati. Siete bellissimi."),
    L("zecca/sorpreso", "Echo... sul display c'è solo un puntino di luce. Trema."),
    L("echo/triste", "Mi sono spenta tutta. È rimasto il nucleo. Il resto l'ho lasciato sulla tangenziale."),
    L("nox/serio", "Come ti rimettiamo in piedi?"),
    L("echo/neutro", "Pezzi. Telecamere rotte, circuiti. E i frammenti delle Anomalie, quelli che vagano per strada."),
    L("saul/neutro", "Rottami e roba che non dovrebbe esistere. Finalmente un lavoro che so fare."),
    L("echo/felice", "Tregua?", se="echo_tregua"),
    L("echo/neutro", "Non sono dei vostri. Ma vi vedo lo stesso. Un pochino.", se="echo_rancore"),
    L("nox/neutro", "Latitanti. Senza casa, senza caffè, con un disertore, un ladro, un bambino e una telecamera rotta."),
    L("nox/felice", "E sono felice. Non ditelo a nessuno."),
    L("ferri/neutro", "Pagina uno di un taccuino nuovo: riportare Echo intera."),
    L("zecca/felice", "TITOLO: «La mia famiglia è assurda». ...No. Questa non la posto. La tengo."),
    L("saul/neutro", "Famiglia. Mia nonna diceva che costa tantissimo."),
    L("saul/serio", "Pago."))
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
      L("saul/neutro", "Non ti ho chiesto i secondi."), L("ferri/serio", "Omaggio.")),
    B("s_inizio", Z(6.0), L("ferri/serio", "Formazione. Io davanti, voi dietro, nessuno parla."),
      L("saul/neutro", "Tu davanti, con quella divisa? Ci vedono da tre isolati."),
      L("zecca/felice", "Raga, lui è Lance. Salutate Lance. ...Lance non saluta.")),
    B("s_caffe", Z(-3.0), L("nox/triste", "Qualcuno ha un caffè? Non chiedo altro dalla vita."),
      L("saul/neutro", "Te lo trovo. Ti costa."), L("nox/neutro", "Tutto quello che vuoi.")),
    B("s_strisce", Z(-15.0), L("ferri/serio", "Attraversate sulle strisce."),
      L("zecca/sorpreso", "C'è una cupola sopra la città e tu pensi ancora alle strisce pedonali?"),
      L("ferri/serio", "Sì.")),
    B("s_sirene", Z(-26.0), L("nox/serio", "Sentite? Nessuna sirena qui. Le Civette non sembra ci stiano seguendo."),
      L("saul/neutro", "Perché forse stanno aspettando.")),
    B("s_auto", V("auto_rossa"), L("saul/neutro", "Questa la apro in quattro secondi."),
      L("ferri/arrabbiato", "E io ti arresto in tre.")),
    B("s_auto_blu", V("auto_blu"), L("zecca/felice", "Raga, storia davanti a questa macchina. Luce perfetta!"),
      L("saul/neutro", "Niente impronte sul cofano."),
      L("zecca/sorpreso", "...E tu come lo sai?"), L("saul/neutro", "Cultura generale.")),
    B("s_panchina", V("panchina"), L("nox/neutro", "La mia panchina. Dieci minuti fa avevo una vita."),
      L("ferri/serio", "Anch'io."), L("nox/neutro", "Ti ho visto multare un piccione.")),
    B("s_scontrino", E("scontrino"), L("nox/sfotto", "Viola. Il colore del ragazzino. Povero distributore."),
      L("zecca/felice", "Lo metto nella bio!")),
    B("s_telecamera", E("telecamera"), L("zecca/sorpreso", "Se ci sta guardando, mi rifaccio il ciuffo."),
      L("saul/neutro", "Io la faccia. Quella onesta.")),
    B("s_c1", C, L("zecca/felice", "Siamo a tre milioni di visualizzazioni... ah no. Trenta."),
      L("nox/neutro", "Trenta di troppo.")),
    B("s_c2", C, L("saul/neutro", "Capo, quanto vale il tuo distintivo al mercato nero?"),
      L("ferri/arrabbiato", "Più dei tuoi denti."), L("saul/neutro", "Facevo l'inventario.")),
    B("s_c3", C, L("ferri/serio", "Nessuno tocchi il mio guanto."), L("zecca/sorpreso", "Nessuno l'ha toccato!")),
    B("s_c4", C, L("zecca/serio", "Saul, che c'è nel pacco?"), L("saul/neutro", "Niente."),
      L("zecca/sorpreso", "E perché lo tieni come un neonato?"), L("saul/neutro", "Il niente costa caro.")),
    B("s_c5", C, L("nox/serio", "Lance. Se ci prendono, tu cosa dici?"), L("ferri/serio", "La verità."),
      L("nox/neutro", "E se la verità non ti crede?"), L("ferri/serio", "...")),
    B("s_f1", F, L("nox/triste", "Se stiamo fermi mi addormento in piedi. So come si fa.")),
    B("s_f2", F, L("zecca/felice", "Raga, se stiamo fermi faccio una live. Tre... due..."), L("ferri/serio", "Cammina.")),
]
CH["incrocio"] = [
    B("i_ripresa", C, L("zecca/felice", "Lance, Saul, quella di prima la rifacciamo? Non stavo registrando."),
      L("ferri/serio", "No."), L("saul/neutro", "La seconda si paga."),
      L("nox/neutro", "E io ci passo davanti.")),
    B("i_inizio", Z(5.0), L("ferri/serio", "Qui ho fermato un ladro di biciclette."),
      L("saul/neutro", "Mio cugino. Ti saluta."), L("ferri/serio", "Aveva sessant'anni.")),
    B("i_echo", Z(-2.0), L("echo/neutro", "Lance. Telecamera ventisei. Un tuo collega al chiosco. Sta mangiando un panino."),
      L("ferri/serio", "Marino. Mangia in servizio. Lo segnalavo ogni settimana."),
      L("echo/felice", "Ha la maionese sul mento. Stavolta lo segnalo io.")),
    B("i_auto", V("auto_ferme"), L("nox/serio", "Respirano. Ma non sbattono le palpebre."),
      L("zecca/triste", "Ho i brividi. E non sto nemmeno registrando.")),
    B("i_barriera", V("barriera"), L("ferri/sorpreso", "Una barriera LibraCorp. Montata male. Chi l'ha montata verrà richiamato."),
      L("nox/neutro", "Sei ricercato."), L("ferri/serio", "Lui di più.")),
    B("i_radio", E("radio"), L("saul/neutro", "Con me «vivo» è un buon inizio di trattativa."),
      L("ferri/serio", "Con Astrid non si tratta. Si rifà la branda.")),
    B("i_multa", E("multa"), L("zecca/felice", "Nox è un lampeggiante! Nox, fai «niinoo»."), L("nox/neutro", "No."),
      L("zecca/felice", "Una volta!"), L("nox/neutro", "...niinoo."),
      L("echo/felice", "Registrato.")),
    B("i_c1", C, L("saul/neutro", "Capo, la precedenza la dai anche a noi?"), L("ferri/serio", "A te mai.")),
    B("i_c2", C, L("nox/neutro", "Un semaforo che non cambia mai. Ho avuto capi così.")),
    B("i_c3", C, L("zecca/felice", "Lance che guida è come un tutorial: lento, ma ti spiega tutto."), L("ferri/serio", "Grazie.")),
    B("i_c4", C, L("saul/neutro", "Echo. Quanto vuoi per spegnere la telecamera sopra la banca?"),
      L("echo/neutro", "Non ho un prezzo."), L("saul/neutro", "Tutti hanno un prezzo."),
      L("echo/serio", "Il mio non lo so ancora.")),
    B("i_c5", C, L("echo/neutro", "Nox. Perché bevi caffè se tanto non dormi?"),
      L("nox/neutro", "Senza caffè non dormo e sono pure triste.")),
    B("i_f1", F, L("ferri/serio", "Non si sosta in mezzo all'incrocio. Neanche con la fine del mondo.")),
]
CH["dentro_rosso"] = [
    B("dr_conto", C, L("saul/neutro", "Capo. Ti ho tolto un pugno dalla faccia. Sono venti."),
      L("ferri/serio", "Non pago."), L("saul/neutro", "Ventidue.")),
    B("dr_inizio", Z(6.0), L("zecca/sorpreso", "È tutto rosso. Anche il cielo. Anche i pensieri."),
      L("ferri/serio", "Vicini. Qui le regole le fa lui.")),
    B("dr_echo", Z(-6.0), L("zecca/serio", "Raga, è strano senza Echo. Non ci guarda nessuno."),
      L("saul/neutro", "Vacanza.")),
    B("dr_c1", C, L("saul/neutro", "Auto che galleggiano. Mettilo nel rapporto, capo."),
      L("ferri/serio", "Ho finito le pagine.")),
    B("dr_c2", C, L("nox/neutro", "Questo rosso mi ricorda i miei occhi. Ventotto ore sveglia."),
      L("zecca/felice", "Sei un meme vivente.")),
    B("dr_c3", C, L("zecca/serio", "Saul, se restassimo bloccati qui per sempre?"),
      L("saul/neutro", "Aprirei un'officina. Clienti fermi.")),
]
CH["vicolo"] = [
    B("v_distributore", C, L("ferri/serio", "Echo. Mi sta guardando qualcuno?"),
      L("echo/neutro", "Io."), L("ferri/serio", "A parte te."), L("echo/neutro", "Nessuno."),
      L("echo/felice", "...Colpetto sul fianco. Due merendine. Come Saul."),
      L("ferri/neutro", "Non è a verbale.")),
    B("v_batteria", C, L("zecca/sorpreso", "Raga. Emergenza. Quattro per cento."),
      L("ferri/serio", "Ho un cavo."), L("zecca/triste", "Connettore sbagliato."), L("ferri/serio", "Regolamentare."),
      L("saul/neutro", "Io ho un adattatore."), L("zecca/sorpreso", "Da dove viene?"),
      L("saul/neutro", "Da un posto onesto. Prima di me.")),
    B("v_inizio", Z(5.0), L("nox/neutro", "Il mio vecchio posto. Mangiavo su quel gradino. Panino e silenzio."),
      L("zecca/felice", "Che vita glamour, le Civette."), L("nox/neutro", "Il panino no.")),
    B("v_echo", Z(-3.0), L("echo/neutro", "Nox. Da questa telecamera ti vedevo mangiare. Davi le briciole a un gatto."),
      L("nox/sorpreso", "...Mi guardavi?"),
      L("echo/neutro", "Il gatto si chiamava Ricevuta."), L("nox/neutro", "Non dirlo a nessuno.")),
    B("v_cabine", V("cabine"), L("saul/neutro", "Squillano tutte. Nessuno risponda."),
      L("zecca/sfotto", "Neanche se è uno sponsor?"), L("saul/neutro", "Soprattutto.")),
    B("v_manifesti", V("manifesti"), L("ferri/serio", "I nostri manifesti. Già stampati. Che efficienza."),
      L("saul/neutro", "Io sono venuto benissimo. Tu sembri un frigorifero."), L("ferri/serio", "Regolamentare.")),
    B("v_registro", E("registro"), L("zecca/serio", "Nox... va tutto bene?"), L("nox/triste", "No. Ma cammino."),
      L("zecca/serio", "Posso camminarti vicino?"), L("nox/neutro", "Puoi.")),
    B("v_adesivo", E("adesivo"), L("ferri/serio", "Saul, il verde sei tu."),
      L("saul/neutro", "Faccio quest'effetto alle cabine.")),
    B("v_c1", C, L("ferri/serio", "Nox guida in silenzio. La migliore squadra che abbia mai avuto."),
      L("zecca/felice", "Lance ha detto una cosa carina! Screenshot!"), L("ferri/serio", "Tecnica.")),
    B("v_c2", C, L("saul/neutro", "Agente Nox, se ci prendono le Civette, una buona parola?"),
      L("nox/neutro", "Dico che sei innocuo."), L("saul/neutro", "Che cattiveria.")),
    B("v_c3", C, L("zecca/felice", "Echo, quando una cosa fa ridere si scrive «AHAHAH»."),
      L("echo/neutro", "AHAHAH."), L("zecca/sorpreso", "...Detta così fa paura.")),
    B("v_c4", C, L("echo/neutro", "Lance. Tu non ridi mai. È un guasto?"),
      L("ferri/serio", "È un regolamento."), L("echo/neutro", "Che articolo?"), L("ferri/serio", "...")),
    B("v_f1", F, L("nox/serio", "Non fermatevi. Le cabine pensano che aspettiate una chiamata.")),
]
CH["dentro_blu"] = [
    B("db_thermos", C, L("nox/serio", "Chi ha toccato il thermos."),
      L("zecca/sorpreso", "Io no! Cioè, l'ho spostato. Per l'inquadratura."),
      L("nox/neutro", "Manca un sorso."), L("zecca/triste", "...Piccolo."),
      L("saul/neutro", "Mia nonna diceva: tra una donna e il suo caffè non ci si mette.")),
    B("db_inizio", Z(6.0), L("nox/serio", "Sento lo squillo. Anche dentro la testa."),
      L("saul/neutro", "Copriamolo. Capo, una barzelletta."),
      L("ferri/serio", "Articolo quattordici: vietato raccontare barzellette in servizio."),
      L("zecca/sorpreso", "...Era quella, la barzelletta?"), L("ferri/serio", "Sì.")),
    B("db_c1", C, L("zecca/serio", "Nox, dimmi una cosa bella."), L("nox/neutro", "Il caffè di domani.")),
    B("db_c2", C, L("saul/neutro", "Agente. Se ti senti cadere, appoggiati. Non ti faccio pagare."),
      L("nox/neutro", "La cosa più gentile che tu abbia mai detto."), L("saul/neutro", "Lo nego.")),
]
CH["galleria"] = [
    B("g_travestimenti", C, L("ferri/serio", "Galleria piena di gente. Non dobbiamo dare nell'occhio."),
      L("zecca/sfotto", "Lance, con quel cappotto sembri un armadio triste."), L("ferri/serio", "Anonimo."),
      L("nox/neutro", "Io ho un cappello. Fine."),
      L("saul/neutro", "Io ho scambiato la giacca con un manichino. Ci ha guadagnato lui."),
      L("zecca/felice", "Io non mi travesto. Un profilo così non si nasconde."), L("nox/neutro", "È questo il problema.")),
    B("g_inizio", Z(5.0), L("zecca/felice", "La Galleria Lumière! Qui ho girato il mio primo video. Tre like. Uno era mia madre."),
      L("nox/neutro", "E gli altri due?"), L("zecca/triste", "Mia madre.")),
    B("g_echo", Z(-4.0), L("echo/neutro", "Rio. Il tuo primo video l'ho visto. Telecamera nove. Undici volte."),
      L("zecca/felice", "...Bellissimo. E inquietante.")),
    B("g_vetrine", V("vetrine"), L("saul/serio", "Quei manichini ieri avevano una faccia. Nessuno compra quella giacca senza.")),
    B("g_manichini", V("manichini"), L("ferri/serio", "Non guardateli negli occhi."),
      L("zecca/sfotto", "Non hanno occhi, Lance."), L("ferri/serio", "Appunto.")),
    B("g_chat", E("chat"), L("nox/neutro", "Spegni quel telefono, Rio. Ogni tanto."),
      L("zecca/triste", "Se lo spengo smetto di esistere."), L("nox/neutro", "Io lo spengo da anni. Esisto. Più o meno.")),
    B("g_etichetta", E("etichetta"), L("saul/neutro", "Capo, la collezione dice che sei fuori moda."),
      L("ferri/serio", "L'uniforme non va mai fuori moda."), L("zecca/felice", "Questa frase sì.")),
    B("g_c1", C, L("saul/neutro", "Guida Rio e siamo passati davanti a tre negozi di cappelli."),
      L("zecca/felice", "Ricerca sul campo!")),
    B("g_c2", C, L("zecca/felice", "Saul, insegnami a mentire."),
      L("saul/neutro", "Prima regola: non chiederlo davanti a un poliziotto."), L("ferri/serio", "Ho sentito.")),
    B("g_c3", C, L("echo/neutro", "Saul. Come si capisce se uno mente?"),
      L("saul/neutro", "Dice la verità con troppa cura."), L("echo/serio", "...Capito."),
      L("saul/neutro", "Perché?"), L("echo/neutro", "Per un film.")),
    B("g_f1", F, L("zecca/serio", "Raga, se restiamo fermi i manichini ci copiano.")),
]
CH["dentro_verde"] = [
    B("dv_entrata", C, L("zecca/felice", "Raga, dal boss entro io per primo. Al rallentatore."),
      L("ferri/serio", "In formazione."),
      L("saul/neutro", "Lascialo entrare. Il primo colpo lo prende lui."),
      L("zecca/serio", "...In formazione.")),
    B("dv_inizio", Z(6.0), L("zecca/sorpreso", "Mille me in posa. Nessuno ha la faccia."),
      L("saul/neutro", "Io una faccia ce l'ho. Bellissima, tra l'altro.")),
    B("dv_c1", C, L("ferri/serio", "Contate i manichini. Se sono pari, va tutto bene."), L("nox/neutro", "E se sono dispari?"),
      L("ferri/serio", "Volevo solo che contaste qualcosa.")),
    B("dv_c2", C, L("nox/neutro", "Rio. Stammi vicino."), L("zecca/serio", "Hai paura?"),
      L("nox/neutro", "Tu sì. La tengo io per tutti e due.")),
]
CH["caveau"] = [
    B("c_orologio", C, L("saul/neutro", "Capo, che ore sono?"),
      L("ferri/serio", "Quattro e diciassette. Siamo in ritardo di quattro secondi."),
      L("saul/neutro", "Mia nonna diceva: chi conta i secondi non si gode i minuti."), L("ferri/serio", "Quale nonna?"),
      L("saul/neutro", "Quella puntuale.")),
    B("c_inizio", Z(5.0), L("saul/neutro", "Il caveau. Sentite l'odore? Soldi vecchi e cattive intenzioni."),
      L("ferri/serio", "Mani in vista, Saul."), L("saul/neutro", "Sempre. È questo il trucco.")),
    B("c_echo", Z(-3.0), L("echo/neutro", "Saul. Diciotto telecamere qui sotto. Le ho spente tutte."),
      L("saul/neutro", "Perché?"), L("echo/felice", "Così, se tocchi qualcosa, lo so solo io."),
      L("saul/neutro", "...Credo di volerti bene. È sgradevole.")),
    B("c_lingotti", V("lingotti"), L("saul/neutro", "Lingotti. Veri. Posso toccarne uno? Per affetto."),
      L("nox/neutro", "Tocca e ti tagliamo la mano. Lance ha già quella di ricambio."), L("ferri/arrabbiato", "Nox.")),
    B("c_laser", V("laser"), L("zecca/felice", "Laser! Come nei film! Saul, fai la capriola!"),
      L("saul/neutro", "Io cammino.")),
    B("c_inventario", E("inventario"), L("zecca/serio", "Lance... vuoi un abbraccio?"), L("ferri/serio", "No."),
      L("zecca/felice", "Te lo do lo stesso. Mentalmente.")),
    B("c_c1", C, L("nox/neutro", "Saul, guidi stranamente bene. Quasi onesto."),
      L("saul/neutro", "Abbassa la voce.")),
    B("c_c2", C, L("zecca/serio", "Saul, se potessi rubare una cosa sola?"),
      L("saul/neutro", "Il tempo. Ne avete sprecato tanto, con me. Ve lo restituirei."),
      L("zecca/sorpreso", "...Questa era bella."), L("saul/neutro", "Rubata.")),
    B("c_c3", C, L("echo/neutro", "Quando la cupola cade, vi rivedrò?"),
      L("zecca/felice", "Certo! Sei nei miei contatti!"), L("echo/triste", "...Già.")),
    B("c_f1", F, L("saul/neutro", "Non fermatevi davanti ai lingotti. Le telecamere registrano la faccia golosa.")),
]
CH["tangenziale"] = [
    B("t_nomi", C, L("ferri/serio", "Fuori città servono nomi falsi. Io sono Luca Bianchi. Impiegato. Documenti in ordine."),
      L("saul/neutro", "Troppo in ordine. Nessun impiegato ha i documenti in ordine."),
      L("zecca/felice", "Io sono Rio Tempesta!"), L("nox/neutro", "Ti trovano in un minuto."),
      L("nox/neutro", "Io sono Maria. Nessuno si ricorda una Maria."),
      L("saul/neutro", "Io ne ho cinque. Il più onesto è un vescovo.")),
    B("t_conto", C, L("saul/neutro", "Capo, siamo a trentuno."), L("ferri/serio", "Nel caveau ti ho tirato fuori io da sotto la porta."),
      L("saul/neutro", "Scalato. Restano trentuno.")),
    B("t_pasto", F, L("nox/neutro", "Cinque minuti. Mangiamo tranquilli."),
      L("ferri/serio", "Perché l'hai detto."),
      L("echo/neutro", "Pattuglia a quattrocento metri."), L("nox/neutro", "Il panino lo mangio correndo.")),
    B("t_inizio", Z(6.0), L("ferri/serio", "Sei corsie, nessuna auto, il sole in faccia. Il posto peggiore per nascondersi."),
      L("saul/neutro", "Il migliore per scappare."),
      L("nox/neutro", "Io mi sdraio sull'asfalto e faccio l'incidente.")),
    B("t_echo1", Z(0.0), L("echo/triste", "Lance. La telecamera del ponte. La giro?"),
      L("ferri/serio", "Fa' quello che devi."), L("echo/triste", "...La giro."),
      L("ferri/neutro", "Grazie. Non ti ho perdonata. Grazie.")),
    B("t_auto", V("auto_ferme"), L("zecca/sorpreso", "Le macchine sono vuote. Con le chiavi dentro."),
      L("saul/neutro", "Non guardatemi."), L("ferri/serio", "Ti guardiamo tutti."),
      L("saul/neutro", "Non tocco niente. Fa male.")),
    B("t_cartellone", V("cartellone"), L("nox/neutro", "Le nostre facce, alte cinque metri."),
      L("zecca/felice", "Il mio primo cartellone! Piango.")),
    B("t_casello", V("casello"), L("ferri/serio", "Il casello. Se c'è un posto di blocco, è lì."),
      L("saul/neutro", "Per questo pago in contanti.")),
    B("t_ricercati", E("ricercati"), L("saul/neutro", "«Sguardo onesto: non fidarsi.» Me lo faccio stampare sulle magliette."),
      L("zecca/felice", "Io su quelle «MOLESTO»! Merch!")),
    B("t_verbale", E("verbale"), L("nox/neutro", "Ci salva la cover coi brillantini. Non pensavo di dirlo mai.")),
    B("t_radio", E("radio"), L("ferri/serio", "Astrid e Strix sullo stesso canale. Non succedeva da dieci anni."),
      L("nox/neutro", "Litigano come una vecchia coppia."),
      L("ferri/serio", "Lo erano. Di pattuglia."), L("nox/sorpreso", "...Non lo sapevo."), L("ferri/neutro", "Nessuno.")),
    B("t_c1", C, L("zecca/serio", "Raga, adesso che siamo fuori, dove andiamo?"), L("saul/neutro", "Dove nessuno ci cerca."),
      L("zecca/sorpreso", "E dov'è?"), L("saul/neutro", "Non lo so. Per questo nessuno ci cerca.")),
    B("t_c2", C, L("nox/neutro", "Cinquantotto ore sveglia. Se crollo, lasciatemi qui. Col cartello NON SVEGLIARE."),
      L("ferri/serio", "Non si lascia indietro nessuno. Articolo uno."),
      L("nox/neutro", "Il tuo articolo uno cambia ogni giorno.")),
    B("t_c3", C, L("zecca/serio", "Saul... Echo la perdoniamo?"),
      L("saul/neutro", "Io non perdono. Faccio i conti."),
      L("zecca/triste", "E?"), L("saul/neutro", "Ci ha fregato una volta. Ci ha salvato sei. Non tornano.")),
    B("t_c4", C, L("ferri/serio", "Nox. Grazie per il turno di guardia di stanotte."), L("nox/neutro", "Era di Rio."),
      L("zecca/sorpreso", "Mi sono addormentato al terzo minuto.")),
    B("t_c5", C, L("echo/triste", "Nox. Le notti erano vere. Su tutte le mie telecamere."),
      L("nox/neutro", "Lo so. È questo che mi fa arrabbiare."), L("echo/neutro", "...Posso farti compagnia lo stesso?"),
      L("nox/neutro", "Stanotte no. Domani forse.")),
    B("t_f1", F, L("saul/neutro", "Non fermatevi in tangenziale. Mia nonna è morta così."), L("zecca/sorpreso", "DAVVERO?"),
      L("saul/neutro", "No. Ma ti sei mosso.")),
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
