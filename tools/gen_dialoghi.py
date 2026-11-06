# Genera data/dialoghi_atto1.json: la sceneggiatura dell'atto 1 (prologo, capitoli 1-5, finale) e le chiacchiere.
#
# VOCI
# Regola del gruppo: Lance organizza, Saul sfrutta, Rio spettacolarizza, Nox evita altre sei ore di lavoro.
# Lance e Saul sono i combattenti veterani, fighi senza volerlo; Rio vuole sembrare figo a tutti i costi.
# La comicita' nasce dal contrasto tra loro, non dall'incompetenza.
#  Lance (id lance) - 23, LibraCorp. Il Braccio della Legge. Articoli del regolamento (anche inventati), "lo metto a verbale",
#           taccuino, l'orologio (dice l'ora al secondo, "siamo in ritardo di quattro secondi"). Chiama Rio "minorenne".
#           Rigido perche' ha paura: il braccio magico e' il suo segreto. Cresce: dalle regole alle persone.
#  Nox    - 24, Civette. Frasi corte e asciutte, conta le ore senza dormire, il thermos del caffe', il divano. Cinica per
#           stanchezza, non per cattiveria. La notte delle 3:12 e' la sua ferita. Cresce: torna a rispondere quando qualcuno chiama.
#  Rio (id rio) - 19, Masca. Il Re del Circo. Parla come un presentatore a un pubblico che non c'e' ("raga", "signore e
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
CAST = {"lance", "nox", "rio", "saul"}


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
    L("rio/felice", "Raga, è il boss segreto. Si vede."),
    L("saul/neutro", "Allora costa il triplo."),
    scelta("AVVISO", "Questo boss è troppo forte per te al momento. Sei sicuro di affrontarlo?",
        [{"testo": "NO, meglio di no"}, {"testo": "SÌ, affrontiamolo", "imposta": "segreto_si"}]))

# Primi 10 minuti (02/11, scelta dell'autore): si apre sul botto. Il gancio mostra la cupola e le facce sugli schermi,
# poi il cartello DUE MINUTI PRIMA e l'apertura dalle 2:58: chi non sa niente di ODISPEL ha subito una domanda.
scene("apertura_gancio", "Alle tre di notte una cupola rosa chiude la città. Su ogni schermo, quattro facce: ricercati.",
    L("echo/serio", "Telecamera sette. Piazza Centrale. Ore tre."),
    L("rio/sorpreso", "Raga... il cielo è ROSA. Non è un filtro. Ho riavviato due volte."),
    L("nox/sorpreso", "È una cupola. Su tutta la città."),
    L("echo/serio", "Su ogni schermo della città, quattro facce. «RESPONSABILI DEL SIGILLO. RICERCATI.»"),
    L("lance/sorpreso", "...Hanno messo la foto del tesserino."))

scene("apertura", "Echo, un'entità che vive nelle telecamere, presenta quattro sconosciuti in piazza alle tre di notte. Il pacco di Saul si apre, una cupola chiude la città e gli schermi accusano proprio loro quattro. Sono costretti a scappare insieme.",
    L("echo/neutro", "Telecamera sette. Piazza Centrale. Ore 2:58."),
    L("echo/neutro", "Mi chiamo Echo. Vivo nelle telecamere di questa città. Guardo."),
    L("echo/serio", "Fra due minuti, questi quattro saranno i più ricercati della città."),
    L("echo/neutro", "Sulla panchina: Nox. Civette, i maghi con la licenza. In servizio. Tecnicamente."),
    L("nox/triste", "Due minuti alla fine del turno. Se squilla il telefono, lo lancio nella fontana."),
    L("echo/neutro", "Col berretto: Lance. LibraCorp, la polizia che dà la caccia alla magia. Retrocesso martedì."),
    L("lance/serio", "Ore 2:58 e quaranta. Una che dorme in servizio. Uno con un pacco. Un minorenne che parla da solo."),
    L("echo/neutro", "Il minorenne è Rio. Diciannove anni. La maschera gli dà poteri. Gli è arrivata per posta."),
    L("rio/felice", "Buonasera raga, e benvenuti a RIO ALLE TRE DI NOTTE!"),
    L("echo/neutro", "Col pacco: Saul. Contrabbandiere. Consegna alle tre in punto. Non sa cosa c'è dentro."),
    L("saul/neutro", "Non chiedo. Le domande costano."),
    L("echo/serio", "Quattro sconosciuti. Ognuno con un segreto. Ricordatevelo."),
    L("echo/serio", "Ore tre. Il pacco si apre."),
    L("lance/arrabbiato", "LibraCorp! Nessuno si muova! Voi tre, in stato di fermo!"),
    L("saul/neutro", "Noi tre. Guarda gli schermi, capo."),
    L("nox/neutro", "Il turno è finito da un minuto. Ricercata da un minuto."),
    L("saul/serio", "Sirene. LibraCorp da una parte, Civette dall'altra."),
    # (la discussione su chi scappa con chi e' nelle chiacchiere dei primi metri di strada: CH["strada"], "s_fuga_*")
    L("echo/serio", "Andava tutto come avevo previsto. Quasi tutto."))

scene("telecamera", "Una telecamera sembra seguire la squadra. Saul se ne accorge.",
    L("saul/serio", "Quella telecamera ci segue da tre isolati."),
    L("nox/neutro", "Le telecamere non girano la testa."),
    L("lance/serio", "Regola uno per chi scappa: non dare nell'occhio."),
    L("rio/felice", "CIAO! Salutate, raga, magari è un fan."),
    L("lance/arrabbiato", "Rio."),
    L("rio/sorpreso", "Che c'è? È il mio normale!"),
    L("nox/neutro", "È questo il problema."))

scene("scontrino", "Indizio: il distributore rifiuta il viola. Forse lo teme.",
    L("saul/sorpreso", "Uno scontrino per terra. Prezzo: un'anima. Non dà resto VIOLA."),
    L("rio/felice", "Viola? È il MIO colore!"),
    L("saul/neutro", "Finalmente servi a qualcosa."))

scene("distributore", "Il distributore in fondo alla strada si sveglia: è un'Anomalia.",
    L("saul/serio", "Un distributore che ronza così alle tre di notte non vende merendine."),
    L("nox/neutro", "Ha la faccia."),
    L("lance/serio", "Indietro. Civili dietro di me."),
    L("saul/neutro", "Qui non ci sono civili, capo. Siamo tutti ricercati."),
    L("DISTRIBUTORE", "*KLANG* RESTO NON DISPONIBILE. INSERIRE... ANIMA."))

scene("agguato", "Il distributore attacca per primo.",
    L("DISTRIBUTORE", "*KLANG* CLIENTE INDECISO RILEVATO. ADDEBITO IN CORSO."),
    L("saul/sorpreso", "Stavo solo guardando la vetrina."),
    L("rio/felice", "Aspettate, mi serve un'entrata..."),
    L("lance/serio", "No."))

scene("vittoria", "L'Anomalia è chiusa.",
    L("rio/felice", "CLIP SALVATA. Trentadue visualizzazioni. Ma col botto."),
    L("saul/neutro", "Un colpetto sul fianco. Due merendine."),
    L("lance/serio", "Appropriazione."),
    L("saul/neutro", "Resto."),
    L("nox/neutro", "Qualcuno mi trovi un caffè. Non da quello."))

scene("sconfitta", "La squadra è stata battuta.",
    L("nox/triste", "Battuti da un distributore. Scrivetelo sulla lapide. In piccolo."))

# ===== TUTORIAL DI COMBATTIMENTO
# Guida il primo scontro (in strada, contro un Frammento giallo, un pezzetto d'Anomalia). Echo spiega con precisione,
# i quattro commentano. Le parole dei comandi sono scritte come sullo schermo, in MAIUSCOLO.
scene("tut_intro", "Echo, istruttrice dal cuore delle telecamere, spiega lo schermo del primo scontro.",
    L("echo/felice", "Istruttrice Echo, telecamera 07. Scontro vero ma piccolo: un Frammento, un pezzetto d'Anomalia."),
    L("rio/sfotto", "Raga, io non leggo le istruzioni. Io ho il feeling."),
    L("saul/neutro", "Io le leggo solo se in fondo c'è il prezzo."),
    L("echo/serio", "In alto il nemico: i suoi PV e la barra bianca EQUILIBRIO. A sinistra, l'ordine dei turni."),
    L("echo/serio", "In basso le vostre schede: PV, ENERGIA e la barra dell'ULTIMATE. Sono le 21:04, domande?"),
    L("nox/neutro", "Una. Posso saltare la lezione?"))

scene("tut_attacco", "Si tocca ATTACCO per colpire; il colore di ognuno conta contro il colore del nemico.",
    L("echo/neutro", "Primo comando: ATTACCO. Tocchi e colpisci. Semplice."),
    L("echo/serio", "Ma il colore conta. Lance è ROSSO, Nox BLU, Rio VIOLA, Saul VERDE."),
    L("echo/serio", "Sul colore giusto esce EFFICACE: più 50 per cento. Su quello sbagliato, DEBOLE."),
    L("echo/serio", "Il Frammento è GIALLO e teme il ROSSO. Quindi colpisce Lance. Cioè: colpisce lui."),
    L("lance/serio", "Lo metto a verbale: sono il rosso utile. Articolo 3."),
    L("rio/sfotto", "Io sono viola. Il colore dei grandi artisti incompresi."))

scene("tut_guardia", "GUARDIA riduce i danni e dà +1 ENERGIA, che serve per l'ABILITÀ.",
    L("echo/neutro", "Secondo comando: GUARDIA. Subisci meno danni e guadagni 1 ENERGIA."),
    L("echo/serio", "L'ENERGIA serve per l'ABILITÀ, che vediamo adesso. Quindi la GUARDIA non è tempo perso."),
    L("nox/felice", "La GUARDIA è la mia mossa preferita. Non fare niente, ma con stile."),
    L("lance/arrabbiato", "Non è «niente». È una difesa attiva. C'è un articolo."),
    L("nox/neutro", "Sì. Ed è un articolo che amo."))

scene("tut_abilita", "ABILITÀ costa ENERGIA ed è diversa per ognuno; alternare le mosse dà un piccolo bonus.",
    L("echo/serio", "Terzo comando: ABILITÀ. Costa ENERGIA, e ognuno ha la sua."),
    L("echo/serio", "Lance protegge: con Copertura prende lui il colpo al posto di un compagno."),
    L("nox/neutro", "Io curo. Pausa caffè. Il mio ruolo preferito dopo la GUARDIA."),
    L("rio/felice", "Io Inquadratura: marco il nemico e faccio salire l'HYPE. Pubblico, svegliati."),
    L("saul/neutro", "Mano lesta. Rubo lo scudo del nemico. Se non ce l'ha, gli rubo EQUILIBRIO e mi riprendo energia."),
    L("echo/felice", "Ultimo trucco: cambiare mossa da un turno all'altro dà un piccolo bonus. Variate, non siate banali."))

scene("tut_telegrafo", "Il nemico annuncia la mossa e il bersaglio: cerchio rosso e bordo rosso sulla scheda.",
    L("echo/serio", "Il Frammento è onesto: annuncia la prossima mossa nella riga in alto."),
    L("echo/serio", "E dice su chi cade: cerchio rosso ai piedi del bersaglio, bordo rosso sulla sua scheda."),
    L("echo/serio", "FORTE significa colpo pesante. SU TUTTI significa che colpisce tutti."),
    L("saul/neutro", "Un nemico che avvisa. Mia nonna Ines diceva che i migliori affari sono quelli senza sorprese."),
    L("rio/sorpreso", "Raga, quindi la riga rossa in alto non era pubblicità?"))

scene("tut_qte", "GUARDIA A TEMPO: si tocca quando il cerchio che si stringe tocca quello fermo.",
    L("echo/serio", "Quando il nemico colpisce, parte la GUARDIA A TEMPO. C'è un cerchio fermo e uno che si stringe."),
    L("echo/serio", "Tocca lo schermo quando si toccano. Preciso al millisecondo: parata PERFETTA e contrattacco."),
    L("lance/serio", "Il cronometro lo porto io. Tolleranza: zero virgola zero."),
    L("rio/sfotto", "Raga, la parata perfetta in clip fa numeri. Fatemi prendere il colpo."),
    L("echo/neutro", "Non è questo il senso. Ma ha un suo fascino."))

scene("tut_reazioni", "Davanti a un colpo pesante in carica compaiono le REAZIONI, che costano RISERVA e il turno.",
    L("echo/serio", "Se il nemico CARICA un colpo pesante, compaiono le REAZIONI. Costano RISERVA e il turno di chi le usa."),
    L("echo/serio", "La RISERVA è di squadra: ne ricaricate un po' a ogni round. Ognuna si gioca diversa."),
    L("echo/serio", "SCHIVA: compare una freccia, tocca quel lato. COPRI: tieni premuto, lascia quando la barra è nella fascia."),
    L("echo/serio", "FERMA: tocca a raffica finché la barra si riempie. Toglie subito EQUILIBRIO al nemico."),
    L("echo/serio", "SOCCORRI: tocca a tempo col battito, tre volte. Rialza un compagno KO."),
    L("echo/felice", "Se sbagli, la reazione funziona lo stesso. Vale meno. Dopotutto siete umani."))

scene("tut_rottura", "A EQUILIBRIO zero il nemico va in BREAK e parte l'ATTACCO DI SQUADRA.",
    L("echo/serio", "Quando la barra bianca EQUILIBRIO arriva a zero, il nemico va in BREAK: stordito."),
    L("echo/felice", "Allora parte l'ATTACCO DI SQUADRA. Io faccio un FERMO IMMAGINE e colpite uno dopo l'altro."),
    L("rio/felice", "FERMO IMMAGINE. Ditemi che l'avete registrato. Voglio la clip."),
    L("echo/neutro", "Telecamera 07 registra tutto. Il mio archivio è già pieno di voi."),
    L("saul/neutro", "Una clip in cambio di una percentuale. Dico solo questo."))

scene("tut_ultimate", "La barra dell'ULTIMATE si riempie colpendo e prendendo colpi; si può lanciare anche in diretta.",
    L("echo/serio", "La barra dell'ULTIMATE si riempie colpendo e prendendo colpi. Piena: ULTIMATE, il colpo più forte."),
    L("lance/serio", "Quindi anche incassare serve. Lo trovo coerente col regolamento."),
    L("echo/serio", "Altra cosa: mentre il nemico carica, chi ha la barra piena può lanciarla fuori turno."),
    L("echo/serio", "Si chiama ULTIMATE IN DIRETTA. Compaiono i pulsanti ULT con il suo nome."),
    L("rio/sorpreso", "In diretta. IN. DIRETTA. Echo, adesso ti adoro."))

scene("tut_extra", "SLANCIO, AUTO e x2, più la pausa.",
    L("echo/neutro", "Tre extra. SLANCIO: colpire col colore vincente a volte regala un mezzo turno in più."),
    L("echo/serio", "Vale solo con ATTACCO o GUARDIA. Con le altre mosse, niente."),
    L("echo/neutro", "AUTO combatte da solo. x2 va più veloce. Per i turni noiosi."),
    L("nox/felice", "AUTO. Qualcuno ha inventato la mia vita ideale."),
    L("echo/serio", "Pausa: il tasto in alto, oppure Esc. Il tempo si ferma. Io, invece, no."))

scene("tut_fine", "Dopo la vittoria: ESPERIENZA, LIVELLO e SQUADRA.",
    L("echo/felice", "Vinto. Ogni scontro dà ESPERIENZA a tutti, anche a chi era in panchina."),
    L("echo/serio", "Con un nuovo LIVELLO si sbloccano mosse, ULTIMATE, reazioni personali, tratti e sinergie tra compagni."),
    L("echo/serio", "Si equipaggiano nel menu di pausa, alla voce SQUADRA. Provateci con calma."),
    L("saul/neutro", "Una domanda. Chi paga il tutorial."),
    L("echo/felice", "Nessuno. È stato un vero... punto di esperienza. Capito? Esperienza."),
    L("nox/neutro", "Non l'abbiamo capito. Ed è meglio così."))

# Storia che non si salta (02/11): l'accordo e' in due tempi, il patto e poi i prezzi; chi salta ha il riassunto di ognuno.
scene("accordo", "Echo si presenta: è un Kairos, vive nelle telecamere. La cupola è retta da quattro Anomalie: se le chiudono, lei consegna le registrazioni della piazza che li scagionano. Saul avverte: niente è gratis.",
    L("echo/neutro", "Bel lavoro. Quel distributore mi doveva dei soldi."),
    L("lance/arrabbiato", "Chi parla? Nome, grado, reparto."),
    L("echo/felice", "Echo. Niente grado. Sono la telecamera sopra di te. Ciao."),
    L("rio/sorpreso", "Raga. La telecamera ha detto «ciao»."),
    L("echo/neutro", "Sono un Kairos. Vengo da un altro posto, qui vivo nei circuiti. Vedo tutta la città."),
    L("nox/serio", "Allora cos'è la cupola?"),
    L("echo/serio", "Un sigillo. L'ha acceso il pacco di Saul."),
    L("echo/serio", "Lo reggono quattro Anomalie, come quel distributore. Più grosse."),
    L("saul/serio", "Sul pacco c'era scritto «Documenti». Con il punto esclamativo. Mi sono fidato."),
    L("rio/sorpreso", "Ma che razza di documenti porti in giro?!"),
    L("echo/serio", "Chiudete le quattro Anomalie e la cupola cade."),
    L("nox/neutro", "Solo quattro."),
    L("echo/serio", "Io ho le registrazioni della piazza: vi scagionano."),
    L("echo/serio", "Ve le do alla fine."),
    L("lance/serio", "Le Anomalie le chiude LibraCorp."),
    L("echo/serio", "LibraCorp e Odispeller sono là fuori a darvi la caccia."),
    L("echo/serio", "Le Anomalie sono qua dentro e voi siete ricercati: non mi pare abbiate molto da perdere."),
    L("nox/neutro", "E tu che ci guadagni?"),
    L("echo/neutro", "Sono chiusa qui dentro come voi. Cerchiamo la stessa porta."),
    L("saul/neutro", "Ragazzi, se c'è qualcosa che ho imparato nella vita è che niente è gratis."),
    L("saul/neutro", "Quindi occhio. Anche a una telecamera gentile."))

scene("accordo_prezzi", "Echo promette a ognuno quello che vuole di più: il grado a Lance, le ferie a Nox, la live dell'anno a Rio, le taglie a Saul. Lance fa votare la squadra.",
    L("echo/neutro", "Allora parliamo di prezzi. Lance: chi chiude il caso torna in servizio. Nome pulito. E il grado."),
    L("lance/sorpreso", "...Il grado."),
    L("nox/neutro", "Gli si è inceppata la faccia."),
    L("echo/neutro", "Nox: tre settimane di ferie per ogni Anomalia di classe alta. Dodici settimane."),
    L("nox/sorpreso", "Chi devo ammazzare."),
    L("echo/felice", "Rio: una città sotto una cupola rosa, quattro mostri, e tu in diretta."),
    L("rio/felice", "La live del DECENNIO. Ci sto."),
    L("echo/neutro", "Saul: LibraCorp paga una taglia per ogni Anomalia chiusa."),
    L("saul/neutro", "Quanto?"),
    L("echo/neutro", "Abbastanza da non consegnare più pacchi senza sapere cosa c'è dentro."),
    L("saul/neutro", "...Hai fatto i compiti."),
    L("rio/felice", "Raga, una telecamera che ci dà una missione. È letteralmente un tutorial."),
    L("lance/serio", "Votiamo. Articolo quarantuno: senza superiori decide la squadra."),
    L("nox/sorpreso", "...Esiste un articolo quarantuno?"),
    L("lance/serio", "No. Ma adesso sì."),
    L("saul/neutro", "E da quando siamo una squadra?"),
    L("lance/serio", "Non è una squadra. È un'emergenza."),
    scelta("nox/neutro", "Allora. Ci fidiamo della telecamera parlante?",
        [{"testo": "«Affare fatto. Ma ti teniamo d'occhio.»", "imposta": "echo_diffidenza"},
         {"testo": "«Va bene. Guidaci.»", "imposta": "echo_fiducia"}]),
    L("echo/felice", "Anch'io vi tengo d'occhio. Letteralmente.", se="echo_diffidenza"),
    L("echo/felice", "Grazie. Seguite le lucine rosse: vi porto in un posto asciutto.", se="echo_fiducia"))

scene("rifugio_arrivo", "Echo porta la squadra in un deposito della metro abbandonato: sarà il loro rifugio. Nessuno si fida di nessuno.",
    L("rio/sorpreso", "Raga, room tour: topi, muffa e... un divano!"),
    L("saul/neutro", "Il divano è mio. L'ho visto per primo."),
    L("lance/serio", "Il divano va a turni. Articolo ventidue: per anzianità di servizio."),
    L("saul/neutro", "Allora è mio. Ho più anni di galera io di tutti voi."),
    L("lance/arrabbiato", "La galera non è servizio."),
    L("saul/neutro", "Dipende dal lato delle sbarre."),
    L("nox/neutro", "Mentre discutevate mi ci sono sdraiata. Parlate piano."),
    L("lance/serio", "Turni di guardia. Due ore a testa. Il primo lo faccio io. Il secondo pure."),
    L("rio/neutro", "Posso fare il primo turno?"),
    L("lance/serio", "No."),
    L("rio/neutro", "Perché?"),
    L("lance/serio", "Perché poco fa hai salutato le telecamere mentre stavamo scappando."),
    L("rio/neutro", "È successo solo una volta."),
    L("lance/serio", "Ed è troppo."),
    L("nox/neutro", "Quindi fai tutti i turni."),
    L("lance/serio", "Sì."),
    L("saul/neutro", "Io dormo col pacco sotto la testa. Chi lo tocca, lo compra."),
    L("rio/neutro", "Nove per cento."),
    L("saul/neutro", "Che è comunque più alta della tua probabilità di sopravvivere là fuori."),
    L("rio/neutro", "Grazie Saul, sei il massimo..."),
    L("saul/neutro", "Grazie coso, lo so bene."),
    L("nox/felice", "C'è una macchinetta del caffè."),
    L("nox/felice", "Chi mi riempie il thermos ha il divano dopo di me."),
    L("saul/neutro", "Affare."),
    L("rio/neutro", "Aspetta, stai già dormendo?"),
    L("nox/neutro", "Se stai zitto riesco."),
    L("echo/neutro", "Dormite tutti con un occhio aperto."),
    L("nox/neutro", "Ci guardi anche mentre dormiamo?"),
    L("echo/neutro", "Io ne tengo aperti centoquarantadue."),
    L("nox/neutro", "Funziona?"),
    L("echo/neutro", "Non so dirtelo con certezza."),
    L("nox/neutro", "A cosa servi esattamente?"),
    L("echo/neutro", "Non so dirtelo con certezza."),
    L("echo/serio", "Domani tocca a un semaforo. In un quartiere che uno di voi conosce bene."),
    L("lance/serio", "...L'Incrocio Nove."),
    L("lance/serio", "Siamo già in ritardo, seguitemi. E niente colpi di testa."))
# ================================================================== CAPITOLO 1 · ROSSO FISSO (Lance)
# Dalla diffidenza al primo segreto custodito: gli altri vedono il braccio di Lance e tacciono.

scene("c1_briefing", "All'Incrocio Nove il tempo si è fermato sul rosso. È il vecchio quartiere di pattuglia di Lance: guida lui.",
    L("echo/neutro", "Incrocio Nove. Rosso da sei ore. Le auto ferme. La gente dentro, anche."),
    L("lance/serio", "Il mio vecchio giro. Trecentododici multe."),
    L("saul/neutro", "Te le ricordi tutte?"),
    L("lance/serio", "Una era tua."),
    L("saul/neutro", "Mi avete portato via la macchina."),
    L("lance/serio", "Doppia fila davanti a una gioielleria. Motore acceso. Bagagliaio aperto."),
    L("saul/neutro", "Faceva caldo."),
    L("rio/felice", "TITOLO: «La guardia e il ladro: la reunion». Abbracciatevi!"),
    L("lance/serio", "No."),
    L("saul/neutro", "Costa."),
    L("echo/serio", "Lance. Ci saranno pattuglie LibraCorp. Gente che conosci."),
    L("lance/serio", "Siamo in ritardo di quattro secondi. In fila. E nessuno attraversa col rosso."))

scene("c1_radio", "Alla radio, la Comandante Astrid di LibraCorp dà la caccia alla squadra. È stata l'istruttrice di Lance.",
    L("RADIO LIBRACORP", "...a tutte le unità: i quattro della piazza sono pericolosi. Priorità uno."),
    L("COMANDANTE ASTRID", "Qui Astrid. L'agente Lance lo voglio io. Vivo. E in ordine."),
    L("lance/triste", "La Comandante Astrid. Mi ha insegnato a rifare la branda. E tutto il resto."),
    L("rio/serio", "Però ti vuole vivo. È buono, no?"),
    L("lance/serio", "Con Astrid «vivo» è la parte brutta."),
    L("saul/neutro", "Ti ha insegnato tutto, quindi sa anche dove scappi. Ci penso io per stavolta, poi ricambi il favore."),
    L("lance/serio", "...Non è un brutto ragionamento."))

scene("c1_multa", "Indizio: il semaforo teme il blu dei lampeggianti.",
    L("lance/serio", "Una multa: passaggio col rosso. Attesa: per sempre."),
    L("nox/sorpreso", "Dietro: esenti i soccorsi. Luce BLU."),
    L("nox/neutro", "Io non sono un soccorso. Sono una dipendente pubblica che non dorme."),
    L("lance/sfotto", "Oggi sei un lampeggiante, collega."),
    L("nox/neutro", "Collega."),
    L("lance/serio", "...Errore di battitura."))

scene("c1_soglia", "Il semaforo è il cuore dell'Anomalia: la squadra ci entra.",
    L("lance/serio", "Da vicino il rosso sembra un occhio."),
    L("echo/serio", "È la soglia. Lì dentro le mie telecamere non arrivano. Non vi vedrò."),
    L("rio/felice", "Niente regia, si improvvisa. Il mio genere!"),
    L("saul/neutro", "Il tuo genere è cadere dalle scale in diretta."),
    L("rio/sorpreso", "Ventimila visualizzazioni!"),
    L("nox/neutro", "Tre sono mie."),
    L("echo/neutro", "...Tornate. Ho già cominciato a contarvi."))

scene("c1_boss", "Il Semaforo si sveglia: ferma chi sbaglia, per sempre.",
    L("SEMAFORO", "ALT. ALT. NESSUNO PASSA. NESSUNO SBAGLIA. NESSUNO SI MUOVE MAI PIÙ."),
    L("saul/neutro", "Capo, parla come te."),
    L("lance/serio", "Lo so."))

scene("c1_agguato", "Il Semaforo attacca per primo.",
    L("SEMAFORO", "INFRAZIONE RILEVATA. SANZIONE IN CORSO."),
    L("lance/sorpreso", "Eravamo fermi! Col rosso!"),
    L("nox/neutro", "Fai ricorso."))

scene("c1_braccio", "Nella lotta il guanto di Lance si strappa: il suo braccio è tecnologia magica di contrabbando. Gli altri lo vedono e decidono di tacere. È il primo segreto che custodiscono insieme.",
    L("rio/sorpreso", "Lance... il tuo braccio. Brilla. Perché brilla?"),
    L("lance/arrabbiato", "Non avete visto niente."),
    L("nox/serio", "Magia sequestrata. LibraCorp la confisca, poi la monta ai suoi."),
    L("saul/neutro", "Wow, quindi questo fa di te... uno sbirro magico?"),
    L("rio/felice", "SBIRRO MAGICO. Raga, no. AHAHAH."),
    L("nox/felice", "Pff..."),
    L("lance/arrabbiato", "Smettetela."),
    L("lance/triste", "Se lo scoprono mi contengono. Come un'Anomalia. Fine."),
    L("saul/neutro", "Rilassati, capo. Con me il segreto è al sicuro. Il prezzo lo decidiamo con calma."),
    L("nox/neutro", "Saul."),
    L("saul/neutro", "...Gratis. Che schifo."),
    L("rio/serio", "Raga. Telefono giù. Questa non la registro."),
    L("lance/neutro", "...Grazie, minorenne."),
    L("rio/arrabbiato", "HO DICIANNOVE ANNI."),
    L("echo/felice", "Il semaforo è verde. Uno su quattro. E il braccio di Lance non è nelle mie registrazioni. Telecamera inceppata."),
    L("lance/sorpreso", "...Davvero?"),
    L("echo/neutro", "Da adesso sì."))

scene("c1_serata", "Una serata al rifugio.",
    L("echo/neutro", "Serata libera. Al rifugio non vi vede nessuno. A parte me."),
    scelta("nox/neutro", "Stasera, con chi?",
        [{"testo": "Lance e Saul, che non si sopportano", "vai": "c1_sera_lance_saul"},
         {"testo": "Nox e Rio, sul divano rotto", "vai": "c1_sera_nox_rio"},
         {"testo": "Lance e Nox, al turno di guardia", "vai": "c1_sera_lance_nox"}]))

scene("c1_sera_lance_saul", "Lance e Saul litigano, poi quasi si capiscono. Legame Lance e Saul.",
    L("saul/neutro", "Capo. Il braccio. Dove l'hai preso? Chiedo per un cliente."),
    L("lance/arrabbiato", "Me l'hanno messo dopo un incidente. Senza chiedermelo."),
    L("saul/serio", "A me hanno messo in gabbia senza chiedermelo. Tre anni."),
    L("lance/serio", "Per cosa?"),
    L("saul/neutro", "Un pacco."),
    L("lance/serio", "Quello di stanotte. Sapevi cosa c'era dentro?"),
    L("saul/serio", "No. Ed è la prima volta che vorrei saperlo."),
    L("lance/neutro", "...Stanotte dormi senza manette. Svista mia.", imposta="legame_lance_saul"))

scene("c1_sera_nox_rio", "Nox e Rio parlano di maschere e di lavoro. Legame Nox e Rio.",
    L("rio/felice", "Nox! Intervista esclusiva. Domanda uno: perché sei sempre stanca?"),
    L("nox/neutro", "Passo."),
    L("rio/felice", "Domanda due: perché sei sempre stanca, ma detta meglio?"),
    L("nox/triste", "Faccio un lavoro che nessuno vede. Per gente che non lo saprà mai."),
    L("rio/serio", "...Io il contrario. Mi guardano tutti e nessuno sa chi sono."),
    L("nox/neutro", "Due disastri."),
    L("rio/felice", "È un complimento?"),
    L("nox/sfotto", "È una diagnosi. Spegni quella lucina rossa.", imposta="legame_nox_rio"))

scene("c1_sera_lance_nox", "Lance e Nox, una guardia e un'Odispeller, scoprono di avere lo stesso tipo di capo. Legame Lance e Nox.",
    L("lance/serio", "LibraCorp e Civette. Da regolamento dovremmo odiarci."),
    L("nox/neutro", "Io odio i turni di notte e il mio capoturno, Strix. Tu sei terzo."),
    L("lance/serio", "Strix. Lavorava in coppia con Astrid, dieci anni fa. Poi è andata male. Nessuno ne parla."),
    L("nox/sfotto", "Due capi orribili con un passato. Brindiamo. Col caffè, siamo in servizio."),
    L("lance/serio", "Siamo latitanti."),
    L("nox/neutro", "Allora doppio.", imposta="legame_lance_nox"))

# ================================================================== CAPITOLO 2 · LA LINEA (Nox)
# La fiducia cresce: coprono Nox mentre affronta la sua notte. Lance rinuncia a un articolo per lei.

scene("c2_briefing", "In tutta la città i telefoni squillano alle 3:12, l'ora della notte peggiore di Nox. L'Anomalia è nel Vicolo delle Civette.",
    L("echo/serio", "Tutti i telefoni della città squillano alle tre e dodici. Chi risponde non riattacca più."),
    L("nox/sorpreso", "...Le tre e dodici."),
    L("rio/serio", "Nox? Sei più bianca del solito. E il tuo solito è già un fantasma."),
    L("nox/serio", "Vicolo delle Civette. Il mio vecchio posto. Guido io. Nessuno risponde a niente."),
    L("saul/neutro", "Nemmeno se chiama mia nonna?"),
    L("nox/neutro", "Soprattutto."),
    L("echo/neutro", "Nox. Quell'orario è nei registri delle Civette."),
    L("nox/arrabbiato", "Allora lo sai. Non ne parliamo."),
    L("echo/triste", "...Scusa. Sto ancora imparando quando si sta zitti."),
    L("saul/neutro", "Adesso."))

scene("c2_registro", "Il registro dei turni: alle 3:12 di una notte di due anni fa, Nox non rispose a una chiamata di soccorso. Alla radio c'è Strix, il suo capoturno.",
    L("nox/triste", "Il registro dei turni. Due anni fa. «3:12, chiamata di soccorso. Nessuna risposta. Turno: Nox.»"),
    L("rio/serio", "Nox..."),
    L("nox/triste", "Ero sola. Avevo paura. L'ho lasciato squillare. La mattina dopo c'era un nome in meno."),
    L("STRIX", "(alla radio) Nox. Torni sempre dove hai sbagliato."),
    L("STRIX", "Consegnati a noi prima che ti trovi LibraCorp. Loro non chiedono: contengono."),
    L("lance/serio", "Su LibraCorp ha ragione. Mi costa dirlo."),
    L("nox/arrabbiato", "Spegnete quella radio."),
    L("saul/neutro", "Fatto. Non era nemmeno mia."))

scene("c2_adesivo", "Indizio: la cabina teme il verde.",
    L("saul/sorpreso", "Un adesivo sul vetro. Linea disturbata. Niente monete VERDI."),
    L("saul/neutro", "Giubbotto verde. Mi sento chiamato in causa."),
    L("rio/felice", "Saul, sei la soluzione!"),
    L("saul/neutro", "Sempre. Cambia il prezzo."))

scene("c2_soglia", "Una cabina squilla. Nox risponde ed entra nella linea. Gli altri entrano con lei.",
    L("nox/serio", "Squilla. È per me."),
    L("lance/serio", "Non sei obbligata a rispondere. Articolo..."),
    L("nox/triste", "Lance. Non adesso."),
    L("lance/neutro", "...Nessun articolo. Ti copro."),
    L("saul/neutro", "Ti copriamo. Gratis. Non abituarti."),
    L("rio/serio", "Io ti tengo la mano. Se ti va. Se no la tengo a Saul."),
    L("saul/neutro", "No."),
    L("nox/triste", "...Due anni fa non ho risposto. Stavolta sì."))

scene("c2_boss", "Dalla Cabina parla la voce della notte delle 3:12. Nox risponde.",
    L("VOCE AL TELEFONO", "Pronto? C'è qualcuno? Vi prego, rispondete. Perché nessuno risponde?"),
    L("nox/triste", "Ci sono. Sono io. Quella notte avevo paura."),
    L("nox/serio", "Quella notte non la cambio. Questa linea la chiudo. E stavolta non sono sola."),
    L("CABINA", "LINEA OCCUPATA. LINEA OCCUPATA. LINEA OCCUPATA PER SEMPRE."))

scene("c2_agguato", "La Cabina attacca per prima.",
    L("CABINA", "CHIAMATA A CARICO DEL DESTINATARIO."),
    L("rio/sorpreso", "Raga, non abbiamo accettato niente!"),
    L("saul/neutro", "Non si accetta mai. Ti addebitano lo stesso."))

scene("c2_dopo", "La linea si chiude. Nox si perdona un poco. Due Anomalie chiuse. Echo vede un filo di luce nella cupola.",
    L("nox/neutro", "Silenzio. Finalmente."),
    L("saul/serio", "Quella voce. Era chi pensi tu?"),
    L("nox/triste", "Era l'Anomalia che la imitava. Ho risposto lo stesso. Mi serviva."),
    L("rio/felice", "Nox ha fatto una cosa coraggiosa! Segnatevi la data!"),
    L("lance/serio", "Pagina quattordici."),
    L("nox/sfotto", "Trentun'ore sveglia e pure i complimenti. Andiamo, prima che mi commuova."),
    L("echo/felice", "Due su quattro. Guardate in alto: la cupola ha una crepa. Un filo di luce."),
    L("echo/triste", "Le mie telecamere guardano tutte in basso. Me la raccontate?"),
    L("rio/serio", "È... sottile. Bianca. Come una porta che si apre in una stanza buia."),
    L("echo/neutro", "...Me la ricorderò così."))

scene("c2_serata", "Una serata al rifugio.",
    scelta("rio/felice", "Serata libera! Con chi la passi?",
        [{"testo": "Saul e Rio, a parlare di affari", "vai": "c2_sera_saul_rio"},
         {"testo": "Lance e Rio, ad allenarsi", "vai": "c2_sera_lance_rio"},
         {"testo": "Nox ed Echo, nel turno di notte", "vai": "c2_sera_nox_echo"},
         {"testo": "Nox e Saul, a trattare", "vai": "c2_sera_nox_saul"}]))

scene("c2_sera_saul_rio", "Rio propone a Saul una diretta insieme. Saul gli spiega chi è la merce. Legame Saul e Rio.",
    L("rio/felice", "Saul! Collab! «Il contrabbandiere racconta». Facciamo i numeri!"),
    L("saul/neutro", "Quanti?"),
    L("rio/felice", "Tipo... cento. Centocinquanta se piove."),
    L("saul/neutro", "A centocinquanta persone vendo centocinquanta orologi falsi. Tu cosa vendi?"),
    L("rio/sorpreso", "Io... niente. Mi guardano."),
    L("saul/serio", "Allora la merce sei tu."),
    L("rio/serio", "...Mi hai fatto la morale col sorriso da truffatore."),
    L("saul/sfotto", "Ne ho uno solo.", imposta="legame_saul_rio"))

scene("c2_sera_lance_rio", "Lance e Rio, entrambi con la magia addosso, si allenano. Legame Lance e Rio.",
    L("lance/serio", "Guardia alta. Se combatti come posti, sei morto in due secondi."),
    L("rio/sfotto", "Tu combatti come uno che scrive i manuali."),
    L("lance/serio", "Li ho scritti."),
    L("rio/sorpreso", "...Davvero?"),
    L("lance/serio", "«Postura e dignità». Quaranta pagine."),
    L("rio/serio", "La mia maschera, il tuo braccio."),
    L("rio/serio", "Roba strana che ci è capitata. Siamo uguali, no?"),
    L("lance/neutro", "No. Ma ci copriamo le spalle. Guardia alta."),
    L("rio/triste", "Sniff, Sniff. Si..."),
    L("lance/sorpreso", "Stai.. piangendo?"),
    L("rio/triste", "Sniff, Sniff. Si..."),
    L("lance/neutro", "Per oggi chiudiamola qui.."),
    L("rio/triste", "Sniff, Sniff, si...", imposta="legame_lance_rio"))

scene("c2_sera_nox_echo", "Durante il turno di guardia, Nox ed Echo parlano della notte nel vicolo e della possibilità di farsi compagnia.",
    L("echo/neutro", "Nox. Sono le tre e dodici."),
    L("nox/neutro", "Lo so, Echo, ho un orologio."),
    L("echo/neutro", "Anch'io guardo sempre l'orologio. Guardo tutto, ma non riesco a fare niente.."),
    L("nox/triste", "Era il mio lavoro."),
    L("nox/sorpreso", "Quella notte di due anni fa, nel vicolo, c'era una telecamera. Eri tu?"),
    L("echo/triste", "Sì, ero io. Non ho potuto fare niente, come sempre.."),
    L("echo/neutro", "...Posso farti compagnia, le notti?"),
    L("nox/neutro", "Puoi. Ma non dirmi che ore sono."),
    L("echo/felice", "Niente orari. A verbale. Come dice Lance."),
    L("nox/neutro", "Per favore non iniziare anche tu."))

scene("c2_sera_nox_saul", "Nox e Saul parlano del fascicolo di Saul e del cammello. Il loro rapporto si approfondisce.",
    L("saul/neutro", "Agente Nox. Quanto costa che ti scordi di avermi visto, quando sarà finita?"),
    L("nox/neutro", "Ho qui il tuo fascicolo guardacaso: fascicolo diciannove."),
    L("nox/neutro", "Saul, ventidue anni. Ricettazione, truffa, appropriazione indebita, violazione di proprietà privata, sequestro di persona, furto d'identità, contrabbando e traffico illegale di oggetti magici.. e di un cammello..?"),
    L("saul/sorpreso", "I cammello è innocente maledizione, è un cammello!"),
    L("nox/neutro", "Qui dice che hai provato a farlo passare in un portale con un impermeabile spacciandolo per un tuo parente, e il cammello aveva i documenti falsi."),
    L("saul/neutro", "Degli ottimi documenti. E un ottimo cammello.. Mi manca a volte, sai?"),
    L("nox/sfotto", "Inizia a mettere da parte del caffè e ne riparleremo."),
    L("saul/serio", "Sei l'unica guardia che non mi ha mai guardato come un mostro."),
    L("nox/neutro", "Ho visto mostri veri. Tu sei un idiota con la giacca."),
    L("saul/neutro", "Non so se prenderlo come un insulto o un complimento, sai?"),
    L("nox/neutro", "Prendila come ti pare."),
    L("saul/neutro", "Se Toe fosse stato qui l'avrei presa bene."),
    L("nox/neutro", "Chi è Toe?"),
    L("saul/neutro", "Il cammello."),
    L("nox/neutro", "Sei senza speranza, Saul.", imposta="legame_nox_saul"))
# ================================================================== CAPITOLO 3 · VETRINA (Rio)
# Collaborazione: Saul parla sul serio a Rio. La maschera si incrina e da li' si vede un occhio: Rio non e' ancora pronto
# a toglierla e nessuno insiste. Toglierla e' il climax del suo arco, piu' avanti.

scene("c3_briefing", "Nella Galleria Lumière chi entra perde la faccia e diventa un manichino. I video sono ovunque. Rio si offre di guidare la squadra.",
    L("rio/sorpreso", "Raga, i video della Galleria Lumière. La gente si fa un selfie e... non ha più la faccia. Guardateli, sono immobili!"),
    L("echo/serio", "Restano in posa. Manichini. Nelle mie telecamere ne ho già individuati dieci."),
    L("rio/serio", "Guido io. Lì dentro serve uno che sa stare davanti a un obiettivo."),
    L("nox/neutro", "Cerca di non fare gaffe allora."),
    L("rio/neutro", "Ci provo.."),
    L("saul/neutro", "Ragazzino. Se hai paura, dillo. Costa meno che fingere."),
    L("rio/felice", "Paura? Io? Raga, io sono nato in diretta!"),
    L("echo/neutro", "I battiti al minuto di Rio sono aumentati di 40."),
    L("rio/arrabbiato", "ECHO!"),
    L("echo/neutro", "Hai ragione, 27."))

scene("c3_chat", "Durante la diretta, alcuni utenti insistono perché Rio mostri il volto.",
    L("rio/felice", "La chat è impazzita. «Facci vedere la faccia.»"),
    L("rio/felice", "E poi: «Senza maschera sei nessuno». Simpatici."),
    L("saul/serio", "Chi l'ha scritto?"),
    L("rio/neutro", "Gente. Uno si chiama «Persona97»."),
    L("saul/neutro", "Non mi farei dare consigli da uno che si chiama Persona97."),
    L("rio/triste", "Prima della maschera non mi conosceva nessuno, avevo trentadue follower. Tutti parenti."),
    L("saul/serio", "Io ne ho zero e mi riconoscono in tre stati."))

scene("c3_etichetta", "Un cartellino rivela un dettaglio curioso sulla Collezione Nessuno.",
    L("rio/sorpreso", "Guardate il cartellino. «Collezione *******». E qui dice: «Il ROSSO non è di stagione»."),
    L("lance/sfotto", "Fortunatamente non seguo la moda."),
    L("nox/neutro", "Lance ha appena fatto una battuta, mi sento male."),
    L("lance/serio", "Zitto ragazzino."))

scene("c3_soglia", "Un manichino in vetrina assume la stessa posa di Rio.",
    L("rio/sorpreso", "Ehi. Quel manichino mi copia."),
    L("nox/serio", "Non fissarlo troppo, potrebbe attaccarci di sorpresa."),
    L("rio/serio", "...Lo so. Ma non riesco a smettere di guardarlo."),
    L("lance/serio", "Restiamo vicini. Articolo... lascia stare. Restiamo vicini."))

scene("c3_boss", "Il Manichino vuole la faccia di Rio. La maschera si incrina, ma Rio la tiene su.",
    L("MANICHINO", "Dammi la tua faccia. Tanto non la usi. Hai sempre la maschera."),
    L("rio/triste", "...Forse hai ragione. Senza maschera non sono nessuno."),
    L("saul/serio", "Coso. Guardami. Io ho passato anni a fingere di essere qualcuno che non ero. Non per questo ho lasciato che fossero gli altri a scegliere chi dovevo essere."),
    L("nox/serio", "Rio, ti abbiamo visto anche quando non c'era nessuno a guardarti. Sei sempre tu. Con o senza quella maschera."),
    L("lance/serio", "E russi. Non credo che una maschera possa nasconderlo."),
    L("rio/serio", "La maschera me la tolgo quando decido io. Non quando lo dici tu. Lance che dicevi sul fatto che russo?"))

scene("c3_agguato", "Il Manichino attacca per primo.",
    L("MANICHINO", "Sorridete. Non muovetevi. Clic."),
    L("rio/sorpreso", "Non ero pronto! Rifacciamola!"))

scene("c3_faccia", "La maschera di Rio ha una crepa: da lì si vede un occhio. Rio non è ancora pronto a toglierla. I passanti tornano alla normalità e ad avere un volto. Tre Anomalie chiuse.",
    L("nox/sorpreso", "Rio! Ti sei fatto male?"),
    L("rio/sorpreso", "No. Cioè... non credo, ma la maschera.. Si è crepata.."),
    L("lance/neutro", "Non toccarla. Potresti peggiorare la crepa."),
    L("saul/neutro", "Per una volta, ascolta il capo moccioso"),
    L("rio/arrabbiato", "Moccioso a chi?"),
    L("saul/neutro", "Vedi? Sei ancora capace di rispondere. Buon segno."),
    L("rio/serio", "...Non posso toglierla. Non ancora."),
    L("lance/neutro", "Nessuno te l'ha chiesto."),
    L("echo/felice", "Sei stato bravo Rio! hai guadagnato una nuova follower! Echo!"),
    L("rio/sorpreso", "...La mia follower più strana."),
    L("echo/neutro", "Tre su quattro. L'ultima è sotto la Banca Centrale. Saul, ti piacerà."),
    L("saul/neutro", "Non si dice «ti piacerà». Si dice «non toccare niente»."))

scene("c3_serata", "Una serata al rifugio.",
    scelta("saul/neutro", "Ultima sera prima del colpo. Con chi la passi?",
        [{"testo": "Lance e Saul, sul tetto", "vai": "c3_sera_lance_saul"},
         {"testo": "Nox e Rio, con le foto vecchie", "vai": "c3_sera_nox_rio"},
         {"testo": "Tutti insieme, con Echo", "vai": "c3_sera_echo"}]))

scene("c3_sera_lance_saul", "La sera prima del colpo, Lance e Saul restano sul tetto del rifugio. Domani dovranno fidarsi l'uno dell'altro.",
    L("lance/serio", "Domani entriamo in un caveau pieno di cose che hai sempre desiderato. Non ti chiederò di fingere che non ti interessi."),
    L("saul/neutro", "Finalmente qualcuno che mi capisce. Cominciavo a preoccuparmi."),
    L("lance/neutro", "Ma se domani ti viene voglia di scappare con il bottino, dovrai passare su di me."),
    L("saul/neutro", "È una minaccia o una promessa?"),
    L("lance/serio", "Una promessa. Se scappi, ti vengo a riprendere io. Non Astrid. Io."),
    L("saul/neutro", "...Ti stai preoccupando per me? Lance, che schifo, non me lo aspettavo da uno come te."),
    L("lance/neutro", "Non abituarti."),
    L("saul/neutro", "Tranquillo. Come disse il saggio, \"diffida degli amici troppo affettuosi.\""),
    L("lance/neutro", "Non siamo amici Saul."),
    L("saul/neutro", "Complici?"),
    L("lance/neutro", "Non ho commesso nessun crimine, quindi no."),
    L("saul/neutro", "Conoscenti."),
    L("lance/neutro", "Si, purtroppo."),
    L("saul/neutro", "Quando tutto questo sarà finito ci faremo una bevuta insieme."),
    L("lance/neutro", "Quando tutto questo sarà finito sarò in servizio."),
    L("saul/neutro", "Anche io."),
    L("lance/neutro", "Non bevo in servizio."),
    L("saul/neutro", "Ecco qui si vedea differenza tra le nostre carriere."),
    L("lance/neutro", "Non hai una carriera Saul, hai un record criminale."),
    L("saul/felice", "Puoi dirlo forte capo, un record! Che nessuno ha ancora superato tra l'altro."),
    L("lance/neutro", "Sei senza speranza Saul."),
    L("saul/neutro", "Hai parlato con Nox recentemente?"),
    L("lance/neutro", "No, perché?"),
    L("saul/neutro", "Niente, curiosità.", imposta="legame_lance_saul"))

scene("c3_sera_nox_rio", "Nox e Rio guardano vecchie fotografie. Tra le prese in giro e la promessa di rivedersi, Rio comincia a mostrare un interesse diverso per Nox.",
    L("rio/felice", "Guarda questa! Io a dodici anni, con l'apparecchio. Questa non deve uscire da qui."),
    L("nox/neutro", "Aspetta... posso vederla meglio?"),
    L("rio/arrabbiato", "Assolutamente no!"),
    L("nox/sfotto", "Peccato. Avevo già pensato a dove appenderla."),
    L("rio/neutro", "Nox, sei una strega."),
    L("nox/sfotto", "Lo so. So fare incantesimi spaventosi."),
    L("rio/serio", "...Ti capita mai di guardare queste foto e pensare a com'era tutto prima?"),
    L("nox/neutro", "A volte. Ma non sempre mi manca quello che c'era."),
    L("rio/serio", "Già... Quando finisce tutto, ci rivediamo?"),
    L("nox/neutro", "Certo. Ma stavolta scegli tu il posto."),
    L("rio/sorpreso", "O-Okay allora! E ti porterò a cena fuori e andremo in giro e..."),
    L("nox/sfotto", "Rio, mi basta un caffè."),
    L("rio/sorpreso", "Nox, non penso che un caffè solo basti."),
    L("nox/neutro", "Hai ragione, ma è un inizio.", imposta="legame_nox_rio"))
scene("c3_sera_echo", "La squadra scherza con Echo sul futuro dopo l'apertura della Cupola. Quando le chiedono come tornerà a casa, evita di rispondere.",
    L("rio/felice", "Echo! Quando si apre la Cupola, vieni a vivere nel mio telefono?"),
    L("echo/neutro", "Il tuo telefono ha il quattro per cento di batteria e sessanta foto di te."),
    L("rio/sorpreso", "...Sessantadue."),
    L("echo/neutro", "Peggio."),
    L("rio/felice", "Ehi! Sono ricordi importanti!"),
    L("echo/neutro", "Sono sessantadue fotografie dello stesso viso."),
    L("rio/felice", "Un viso molto fotogenico."),
    L("nox/neutro", "Su questo non mi esprimo."),
    L("rio/sorpreso", "Tradimento. Da te non me l'aspettavo."),
    L("echo/neutro", "Io invece torno a casa."),
    L("rio/sorpreso", "Hai una casa?"),
    L("echo/serio", "Certo. Da dove vengo io non ci sono telecamere. Non ci sono nemmeno le forme."),
    L("nox/serio", "E come ci torni?"),
    L("echo/neutro", "..."),
    L("saul/neutro", "Domanda interessante. Soprattutto perché non sembra che tu abbia un piano."),
    L("echo/felice", "Ce l'ho!"),
    L("saul/neutro", "Ah, bene. Qual è?"),
    L("echo/neutro", "Non te lo dico."),
    L("saul/neutro", "Piano impeccabile."),
    L("rio/neutro", "Comunque... se non trovi la strada, puoi sempre restare con noi."),
    L("echo/neutro", "Lo so, Rio."),
    L("rio/sorpreso", "Davvero?"),
    L("echo/felice", "Certo. Ho già scelto dove mettere le tue sessantadue fotografie."),
    L("rio/arrabbiato", "NON LE METTERAI NEL MIO TELEFONO!"),
    L("echo/felice", "Allora buonanotte, umani. Domani è il giorno di Saul."),
    L("saul/sorpreso", "Perché ho la sensazione che non sarà una giornata rilassante?"),
    L("lance/serio", "Perché non lo sarà."),
    L("saul/neutro", "Ottimo. Adoro quando c'è entusiasmo."))
scene("c4_briefing", "L'ultima Anomalia si trova nel caveau LibraCorp, sotto la Banca Centrale. Per Saul è un posto fin troppo familiare.",
    L("echo/neutro", "Il caveau LibraCorp. Sotto la Banca Centrale. L'ultima Anomalia è la cassaforte."),
    L("saul/neutro", "Dieci anni. Ci ho messo dieci anni ad arrivare fin qui. Direi che è il momento di godermi la visita. Guido io, ovviamente."),
    L("lance/serio", "Si entra, si neutralizza l'Anomalia e si esce. Niente deviazioni. Niente bottino."),
    L("saul/neutro", "Capo, mi ferisci. Davvero pensi che confonderei una missione così importante con una gita al centro commerciale?"),
    L("lance/neutro", "Sì."),
    L("saul/neutro", "Almeno potevi fingere di pensarci."),
    L("nox/neutro", "Domanda pratica: quanto è sicuro?"),
    L("saul/neutro", "Da uno a dieci?"),
    L("nox/neutro", "Esatto."),
    L("saul/neutro", "Diciamo che è improbabile che moriamo tutti."),
    L("nox/neutro", "Tutti?"),
    L("rio/felice", "Titolo della diretta: «Rapina in banca, ma legale»!"),
    L("nox/neutro", "Non è legale. E sono quarantadue ore che non dormo."),
    L("saul/felice", "Allora direi che siamo tutti prontissimi. Si va in scena!"),
    L("rio/sorpreso", "Ehi! Dovevo dirla io questa!"),
    L("saul/neutro", "Troppo tardi ragazzino, conduco io qui."))
scene("c4_committente", "Durante una pausa, il Committente contatta Saul e gli offre una via d'uscita. Saul deve decidere se dirlo agli altri o tenere la proposta per sé.",
    L("saul/sorpreso", "Numero sconosciuto... Che giornata fortunata."),
    L("saul/neutro", "...Pronto?"),
    L("VOCE SENZA VOLTO", "Ciao, Saul. Hai fatto un bel lavoro stavolta."),
    L("saul/serio", "Tu.. Quel pacco ha chiuso una città. Mi avevi detto che era un lavoro pulito, documenti e basta!"),
    L("VOCE SENZA VOLTO", "Erano documenti. Di un certo tipo."),
    L("saul/neutro", "Sai, di solito quando qualcuno mi mente cerco almeno di farmi pagare di più."),
    L("VOCE SENZA VOLTO", "Nel caveau c'è quello che ti avevo promesso. Anzi, molto di più."),
    L("VOCE SENZA VOLTO", "Prendilo e vattene. Loro non ti servono."),
    L("saul/serio", "E dovrei fidarmi di te?"),
    L("VOCE SENZA VOLTO", "Non devi fidarti. Devi solo ricordare quanto hai desiderato arrivare fin qui."),
    L("VOCE SENZA VOLTO", "Ti apro un'uscita. Solo per te. Vediamo se sei ancora come ti ricordavo."),
    scelta("saul/serio", "...",
        [{"testo": "Riattacca e dillo agli altri", "imposta": "saul_leale"},
         {"testo": "Tieni la telefonata per te", "imposta": "saul_tentato"}]),
    L("saul/serio", "Era Il Committente, il tizio del pacco. Ci vuole divisi. Quindi restiamo insieme. Finito qui, andrò a fare due chiacchiere con lui in privato, ho degli interessi da riscattare.", se="saul_leale"),
    L("lance/sorpreso", "Il committente, nei file ne ho sentito parlare. Hai lavorato per lui e sei ancora vivo? Mi sorprendi.", se="saul_leale"),
    L("saul/neutro", "Te l'ho detto che sono il migliore.", se="saul_leale"),
    L("saul/neutro", "Niente. Un call center.", se="saul_tentato"),
    L("nox/neutro", "Alle quattro del mattino?", se="saul_tentato"),
    L("saul/neutro", "Ehi! Là fuori c'è gente che lavora sodo, Nox.", se="saul_tentato"),
    L("nox/neutro", "Lo so bene, tu non ne fai parte.", se="saul_tentato"))

scene("c4_inventario", "Un inventario dei sequestri LibraCorp rivela il nome di Lance accanto a un prototipo magico.",
    L("saul/sorpreso", "Inventario dei sequestri. Braccio Magico. Prototipo in fase sperimentale."),
    L("saul/sorpreso", "Assegnato all'agente Lance. Test sul campo. Firma: Astrid."),
    L("lance/sorpreso", "...Astrid. Sapeva del prototipo. Sapeva cosa mi stavano facendo."),
    L("nox/serio", "E ti ha lasciato credere che fosse un normale incarico?"),
    L("lance/serio", "Non era un incarico. Ero il test."),
    L("rio/serio", "Lance...?"),
    L("lance/serio", "Sto bene."),
    L("saul/neutro", "Non te l'ha chiesto nessuno."),
    L("lance/serio", "Sono in servizio."),
    L("saul/neutro", "Non sei in servizio, capo. Sei con noi."),
    L("lance/neutro", "...Lo so."),
    L("saul/neutro", "Dici è peggio visto che ci siamo noi?"),
    L("lance/serio", "Sta' zitto Saul."),
    L("saul/neutro", "Okay, okay, ricevuto capo."))

scene("c4_combinazione", "Indizio: la cassaforte reagisce al rosso.",
    L("saul/neutro", "Aspettate... La serratura reagisce al rosso."),
    L("lance/sfotto", "Incredibile."),
    L("saul/neutro", "Guarda un po'. Per una volta sei tu ad aprire una porta per me."),
    L("saul/neutro", "Tranquillo, capo. Non capita spesso che un poliziotto mi sia così utile."))

scene("c4_boss", "La cassaforte si apre. Quando Rio resta intrappolato dalla porta blindata, Saul rinuncia alla via d'uscita promessa dal Committente e lo salva.",
    L("CASSAFORTE", "COMBINAZIONE RICHIESTA. LA COMBINAZIONE È: TUTTO QUELLO CHE HAI."),
    L("saul/serio", "(Lì dietro c'è l'uscita che mi ha promesso il Committente. Basterebbe correre e sono fuori.)", se="saul_tentato"),
    L("rio/sorpreso", "La porta! Sono rimasto fuori!"),
    L("saul/arrabbiato", "Rio! Fermo lì!"),
    L("nox/sorpreso", "Saul! Ti schiaccia!"),
    L("saul/serio", "Lo so! Rio, passa!"),
    L("rio/serio", "...Sono passato. Saul, esci!"),
    L("saul/neutro", "Perso un'uscita pulita e ho guadagnato voi, pessimo affare."),
    L("rio/felice", "Saul mi ha salvato la vita, e mi ha chiamato per nome!"),
    L("saul/serio", "Pessimo. Forse il Committente ha ragione dicendo che non sono più quello di una volta?"))

scene("c4_agguato", "La Cassaforte attacca per prima. Lance difende Saul e Saul chiede a Echo di registrare il momento.",
    L("CASSAFORTE", "TENTATIVO DI SCASSO RILEVATO. CONFISCA IN CORSO."),
    L("saul/neutro", "Non ho ancora toccato niente."),
    L("lance/serio", "Per una volta, è innocente."),
    L("saul/neutro", "Echo sei ci sei per favore registra questo momento. Non ricapiterà."))

scene("c4_dopo", "Dopo aver chiuso la cassaforte, Nox si occupa delle costole di Saul. Tra battute e una domanda di Rio, Saul lascia intravedere perché è rimasto con la squadra.",
    L("rio/felice", "Quattro su quattro! Avete visto QUELLO CHE HO FATTO?"),
    L("rio/felice", "...Cioè, Saul. Ma io ero nell'inquadratura."),
    L("nox/neutro", "Saul. Le costole."),
    L("saul/neutro", "Sono a posto."),
    L("nox/neutro", "Due incrinate. Zitto, respira piano. Stanotte il divano è tuo."),
    L("saul/sorpreso", "Puoi farmi da infermiera e rimboccarmi le coperte?"),
    L("nox/neutro", "Ritiro tutto quello che ho detto. Può morire qui per me ragazzi."),
    L("rio/serio", "Saul... perché l'hai fatto?"),
    L("saul/neutro", "Non lo so. Di solito ho sempre un tornaconto preciso."),
    L("saul/serio", "Stavolta niente. Credo di essere malato."),
    L("saul/neutro", "Prima mi ha chiamato il Committente: è il tizio del pacco che sta dietro tutta questa faccenda. Mi ha offerto un'uscita, non ve l'avevo detto.", se="saul_tentato"),
    L("lance/serio", "E sei rimasto. A tenere una porta blindata con le costole.", se="saul_tentato"),
    L("saul/neutro", "Non è stato il massimo ma è servito a qualcosa.", se="saul_tentato"),
    L("echo/felice", "Quattro Anomalie. Riposate."),
    L("echo/felice", "All'alba, in piazza: vi porto le registrazioni. Promesso."))

scene("c4_vigilia", "È l'ultima notte al rifugio. Il gruppo parla del futuro dopo la caduta della cupola. Rio salva Echo tra i contatti e lei quasi confessa qualcosa.",
    L("nox/neutro", "Ultima notte. Domani la cupola cade e ognuno torna a casa sua."),
    L("rio/felice", "La live della cupola è tutta nel telefono. Quando torna la rete la carico. Milioni, raga."),
    L("rio/serio", "...Però a casa ho trentadue follower.. Qui ho voi."),
    L("saul/neutro", "Noi non ti seguiamo. Ti sopportiamo."),
    L("lance/serio", "Io torno in servizio. Col grado. E poi dico la verità. Sul braccio, su Astrid, su tutto."),
    L("saul/neutro", "Ti arresteranno."),
    L("lance/neutro", "Non importa."),
    L("nox/neutro", "Dodici settimane di ferie. Le prime tre dormo. Poi forse torno alle Civette. Forse rispondo al telefono."),
    L("saul/neutro", "Io apro un negozio. Roba usata. Onesta. Quasi tutta."),
    L("echo/neutro", "Rio. Mi salvi tra i contatti? Con un nome."),
    L("echo/neutro", "Ho sempre avuto solo numeri di telecamera."),
    L("rio/felice", "Fatto. «Echo». Con la telecamera accanto. ( E il cuore. No, forse il cuore lo tolgo, no lo lascio..)"),
    L("echo/triste", "...Grazie."),
    L("echo/serio", "Se un giorno scopriste che vi ho detto una cosa non vera... all'inizio..."),
    L("nox/neutro", "Echo?"),
    L("echo/neutro", "Niente. Una domanda per un film. Dormite."),
    L("lance/serio", "...Ha cambiato discorso. Di nuovo."))

# ================================================================== FINALE · IL VARCO
# Il tradimento. Ognuno viene colpito nel punto in cui si era legato a Echo. Poi la cupola cade e Lance usa il braccio per
# salvare Rio. Echo inceppa le telecamere della piazza come all'Incrocio Nove: il braccio lo vede solo il gruppo. Mostrarlo
# al paese e' il climax dell'arco di Lance, piu' avanti.

# Storia che non si salta (02/11): due tempi, la confessione e il crollo. E' un climax: si stringe, non si sposta nulla.
scene("varco", "In piazza si apre un varco. Echo rivela di aver manipolato il gruppo per chiudere le Anomalie. Le promesse erano false, ma il legame nato durante il viaggio era autentico.",
    L("echo/felice", "Quattro Anomalie chiuse. Lassù, sopra la piazza: un varco."),
    L("echo/felice", "Porta a casa mia. Grazie. Davvero."),
    L("lance/serio", "Echo. Le registrazioni. Dove sono?"),
    L("echo/triste", "...Non esistono. Le ho cancellate io.."),
    L("echo/triste", "Le facce sugli schermi... le ho messe io."),
    L("echo/triste", "Mi serviva qualcuno che chiudesse le Anomalie."),
    L("echo/triste", "Qualcuno che non potesse andare né da LibraCorp né dalle Civette."),
    L("echo/serio", "Un agente con un braccio illegale. Una Civetta con una chiamata senza risposta."),
    L("echo/serio", "Un ragazzino con una maschera. Un contrabbandiere con un pacco."),
    L("echo/triste", "Se aveste detto la verità, nessuno vi avrebbe creduto. Vi ho scelti per questo."),
    L("lance/serio", "Il grado. Il nome pulito. Non c'era nessun caso. C'eravamo noi da usare."),
    L("nox/triste", "Le ferie non m'importano. Le notti."),
    L("nox/triste", "Mi hai fatto compagnia le notti. Anche quello era lavoro?"),
    L("echo/triste", "No. Tutto quello dopo la piazza era vero. Solo le promesse erano false."),
    L("nox/neutro", "Su quelle si reggeva il resto."),
    L("rio/triste", "La live. L'ho registrata per te. Per noi. Era il mio video più bello."),
    L("echo/triste", "Lo è ancora."),
    L("saul/neutro", "Quattro taglie. Me l'hai venduta bene. Nessuno ci era mai riuscito.", se="echo_diffidenza"),
    L("saul/arrabbiato", "E io ti ho pure creduta. Io. Che le promesse le vendo.", se="echo_fiducia"),
    L("saul/serio", "...Ti odio. E mi dispiace che sia così facile."),
    L("lance/serio", "Prove cancellate, facce sugli schermi, promesse su misura."),
    L("lance/serio", "Hai fatto quello che LibraCorp fa tutti i giorni."),
    L("rio/triste", "Ti tolgo dai contatti."),
    L("echo/triste", "...Lo capisco."),
    L("rio/triste", "Non riesco a premere il tasto. Perché non riesco?"))

scene("varco_crollo", "Il Committente ruba il varco a Echo, la cupola crolla e Lance salva Rio mostrando il braccio. Echo blocca le telecamere della piazza. Le Civette danno la caccia al gruppo in tutto il paese; Rio sceglie di portare Echo con sé.",
    L("VOCE SENZA VOLTO", "Che scena commovente. Grazie per il varco, piccola Echo. Non era tuo."),
    L("echo/sorpreso", "Tu... il Committente. No. No, no. Il varco si chiude!"),
    L("VOCE SENZA VOLTO", "Per te. Per me si è appena aperto."),
    L("rio/sorpreso", "Raga... la cupola viene giù! Il tabellone! Sopra di me!"),
    L("lance/arrabbiato", "RIO!"),
    L("lance/serio", "...Preso. Sta' giù."),
    L("rio/sorpreso", "Lance... il braccio. Ci sono telecamere ovunque."),
    L("lance/neutro", "Lo so."),
    L("echo/serio", "Piazza Centrale, telecamere dalla uno alla dodici: inceppate."),
    L("echo/serio", "Come all'Incrocio Nove."),
    L("lance/serio", "...Non ti ringrazio. Rio, alzati. Correte."),
    L("STRIX", "(alla radio) Civette, in caccia in tutto il paese."),
    L("STRIX", "Nox... mi dispiace. Stavolta non posso coprirti."),
    L("nox/serio", "Prima ci cercava una città. Adesso il paese."),
    L("nox/serio", "E abbiamo un agente col braccio che brilla."),
    L("lance/neutro", "Ex agente. Fa meno male se lo dico io."),
    L("echo/triste", "...Portatemi con voi. Non ho più una casa. Per rimediare."),
    L("rio/serio", "..."),
    L("rio/serio", "Corri."))

# ================================================================== CAPITOLO 5 · LA TANGENZIALE
# Famiglia. Si scappa insieme, ci si para le spalle, si decide cosa fare di Echo. Echo si spegne per loro e torna nucleo
# (autore, 19/10: piccolo sacrificio, non persa per sempre). Aggancio del seguito: recuperare pezzi e frammenti per riaverla.

scene("c5_alba", "All'alba, sulla rampa della tangenziale, la squadra decide cosa fare di Echo. Lei conosce l'unico casello che non porta in prigione.",
    L("rio/triste", "L'alba. È bruttissima. È bellissima."),
    L("nox/neutro", "Cinquantasei ore sveglia. Vedo due soli."),
    L("lance/serio", "Situazione. Ore 6:02 e undici. Ricercati da tutti. Risorse: un manganello, un caffè freddo, un telefono al tre per cento."),
    L("rio/sorpreso", "Due."),
    L("saul/neutro", "E una costola e mezza."),
    L("nox/neutro", "Lance. Il braccio?"),
    L("lance/neutro", "Brilla. L'hanno visto tre persone e una telecamera inceppata. Per ora."),
    L("echo/neutro", "(dal cartello luminoso della rampa) Sono qui. Il cartello «RALLENTARE» è mio, adesso."),
    L("lance/arrabbiato", "Zitta."),
    L("echo/triste", "Sì. Ma so dove sono i posti di blocco. Il più debole è il casello della tangenziale."),
    L("nox/serio", "Perché dovremmo crederti?"),
    L("echo/triste", "Non dovreste. Ma è l'unica strada che non finisce in una cella."),
    L("saul/neutro", "Mia nonna diceva: un bugiardo che ti indica l'uscita resta un bugiardo. Ma l'uscita è un'uscita."),
    L("rio/sorpreso", "Quale nonna?"),
    L("saul/neutro", "Quella cinica."),
    L("rio/serio", "Echo... sei ancora nei miei contatti. Non ci sono riuscito."),
    scelta("nox/neutro", "Allora. Che ne facciamo di lei?",
        [{"testo": "«Tregua. Finché siamo fuori.»", "imposta": "echo_tregua"},
         {"testo": "«Ci guidi. Ma non sei dei nostri.»", "imposta": "echo_rancore"}]),
    L("echo/felice", "Tregua. Mi piace la parola. Non l'avevo mai detta.", se="echo_tregua"),
    L("echo/triste", "Capito. Vi guido lo stesso.", se="echo_rancore"),
    L("lance/serio", "Tangenziale, poi casello. Guido io: i posti di blocco LibraCorp li ho montati io. Male, a quanto pare."))

scene("c5_ricercati", "Il cartellone dei ricercati: le quattro facce, con descrizioni poco lusinghiere.",
    L("rio/felice", "Il cartellone dei ricercati! Siamo famosi! «RIO. Giovane, viola, molesto.»"),
    L("rio/arrabbiato", "MOLESTO?"),
    L("saul/neutro", "«SAUL. Sguardo onesto: non fidarsi.» Mi hanno capito."),
    L("nox/neutro", "«NOX. Pericolosa se svegliata.» Giusto."),
    L("lance/triste", "«LANCE. Disertore.» Ieri c'era scritto «uniforme in ordine»."),
    L("rio/serio", "La tua uniforme è ancora molto in ordine, Lance."),
    L("lance/neutro", "È l'unica cosa in ordine che mi resta."),
    L("nox/neutro", "Non l'unica."))

scene("c5_verbale", "Indizio: l'autovelox teme il viola.",
    L("lance/serio", "Un verbale sul cruscotto. Foto annullata: flash VIOLA."),
    L("rio/felice", "Il flash del mio telefono è viola! Cover coi brillantini!"),
    L("saul/neutro", "Ci salverà la vita una cover di cattivo gusto."),
    L("rio/felice", "TITOLO: «La cover che ha salvato il mondo»."))

scene("c5_radio", "Alla radio di un'auto abbandonata, Astrid e Strix litigano su chi arresterà la squadra. Un tempo erano compagni di pattuglia.",
    L("COMANDANTE ASTRID", "Strix. Le tue Civette sono sulla mia tangenziale."),
    L("STRIX", "Tua? È di tutti, Astrid. Come la tua arroganza."),
    L("COMANDANTE ASTRID", "Lance è mio. L'ho addestrato io. L'ho costruito io."),
    L("STRIX", "E Nox l'ho cresciuta io. Ma non l'ho mai montata coi pezzi di ricambio."),
    L("COMANDANTE ASTRID", "...Chiudi il canale, Strix."),
    L("STRIX", "Una volta mi offrivi un caffè, prima di dirmelo."),
    L("nox/neutro", "...Strix mi ha difesa. Davanti ad Astrid."),
    L("lance/serio", "«L'ho costruito io.» L'ha detto davvero."),
    L("saul/neutro", "Tu non sei un pezzo, capo. Lo dico io, che i pezzi li vendo."))

scene("c5_boss", "Al casello aspetta un autovelox nato quando è caduta la cupola: un'Anomalia nuova.",
    L("echo/sorpreso", "Il casello. Quell'autovelox non è mio. È un'Anomalia nuova. È nata quando è caduta la cupola."),
    L("AUTOVELOX", "VELOCITÀ RILEVATA: TROPPA. FUGA RILEVATA: TOTALE. SANZIONE: TUTTO."),
    L("lance/serio", "Articolo uno del codice della strada: chi scappa non si ferma per le multe."),
    L("saul/neutro", "Non è l'articolo uno."),
    L("lance/serio", "Oggi sì."))

scene("c5_agguato", "L'Autovelox attacca per primo.",
    L("AUTOVELOX", "FLASH. FLASH. FOTO SCATTATA. VERBALE IN ARRIVO."),
    L("rio/sorpreso", "Sono venuto malissimo! Cancellala!"))

# Storia che non si salta (02/11): tre tempi, il blocco, il buio (la citta' spenta) e la famiglia.
scene("c5_casello", "Al casello aspettano Astrid e Strix con le loro squadre. Echo spegne ogni telecamera e ogni luce della città per farli scappare, anche se per lei è come chiudere gli occhi.",
    L("rio/felice", "La sbarra è alzata! Raga, siamo fuori!"),
    L("lance/sorpreso", "No. Fermi. Fari. Due colonne di fari."),
    L("COMANDANTE ASTRID", "(dal megafono) Lance. Torna a casa. Ti sistemiamo noi. Ti aggiustiamo."),
    L("lance/serio", "Non sono rotto, Comandante. Sono cambiato."),
    L("STRIX", "(dall'altro lato) Nox. Hai la faccia di una che non dorme da tre giorni."),
    L("nox/neutro", "Sessanta ore. Arrotondi bene."),
    L("STRIX", "Vieni via con me. Mettiamo tutto a posto. Rispondi, Nox."),
    L("nox/serio", "Ho imparato a rispondere, Strix. È no."),
    L("saul/neutro", "Ragazzi. Mia nonna diceva: quando due cani litigano per l'osso..."),
    L("rio/serio", "...l'osso scappa?"),
    L("saul/neutro", "Nonna saggia."),
    L("echo/serio", "Aspettate. Lasciate fare a me."),
    L("rio/serio", "Echo? Cosa fai?"),
    L("echo/serio", "Telecamere. Fari. Lampioni. Semafori. Tabelloni. Tutto quello che vedo. Tutto quello che sono."),
    L("echo/triste", "Se spengo tutto, per un po' non vedrò niente. Non vedrò voi. Non so se mi riaccendo."),
    L("nox/sorpreso", "Echo, no..."),
    L("echo/felice", "Le promesse erano false. Questa no. Spento."))

scene("c5_buio", "Al buio la squadra scappa giù dalla scarpata. Echo si riaccende nel telefono di Rio, ma di lei resta solo il nucleo: per riaverla servono pezzi e frammenti.",
    L("COMANDANTE ASTRID", "Chi ha spento la luce?! Unità, a terra!"),
    L("STRIX", "Astrid, la torcia ce l'hai tu."),
    L("COMANDANTE ASTRID", "Non è il momento, Strix!"),
    L("nox/sorpreso", "Ha spento la città. Tutta. Per noi."),
    L("saul/neutro", "Avrà un conto da saldare, adesso."),
    L("nox/serio", "Saul."),
    L("saul/neutro", "...Niente. Sbagliato io."),
    L("lance/serio", "Giù dalla scarpata. Saul, appoggiati a me. Rio, la mano di Nox. Nessuno resta indietro."),
    L("saul/neutro", "Capo. La promessa sul tetto. Se scappo, mi insegui tu.", se="legame_lance_saul"),
    L("lance/neutro", "Stavolta scappiamo insieme. Non conta.", se="legame_lance_saul"),
    L("rio/serio", "Raga... il telefono è morto. Zero. Echo era lì dentro."),
    L("saul/neutro", "Tieni. Batteria esterna. Te la vendo."),
    L("rio/serio", "Saul."),
    L("saul/neutro", "...Te la regalo. Non dirlo in giro."),
    L("rio/sorpreso", "Si accende. Echo? Ci sei?"),
    L("echo/triste", "...Vi vedo. Male. Sgranati. Siete bellissimi."),
    L("rio/sorpreso", "Echo... sul display c'è solo un puntino di luce. Trema."),
    L("echo/triste", "Mi sono spenta tutta. È rimasto il nucleo. Il resto l'ho lasciato sulla tangenziale."),
    L("nox/serio", "Come ti rimettiamo in piedi?"),
    L("echo/neutro", "Pezzi. Telecamere rotte, circuiti. E i frammenti delle Anomalie, quelli che vagano per strada."),
    L("saul/neutro", "Rottami e roba che non dovrebbe esistere. Finalmente un lavoro che so fare."),
    L("echo/felice", "Tregua?", se="echo_tregua"),
    L("echo/neutro", "Non sono dei vostri. Ma vi vedo lo stesso. Un pochino.", se="echo_rancore"))

scene("c5_famiglia", "Nella fuga i quattro diventano una famiglia.",
    L("nox/neutro", "Latitanti. Senza casa, senza caffè, con un disertore, un ladro, un bambino e una telecamera rotta."),
    L("nox/felice", "E sono felice. Non ditelo a nessuno."),
    L("lance/neutro", "Pagina uno di un taccuino nuovo: riportare Echo intera."),
    L("rio/felice", "TITOLO: «La mia famiglia è assurda». ...No. Questa non la posto. La tengo."),
    L("saul/neutro", "Famiglia. Mia nonna diceva che costa tantissimo."),
    L("rio/sorpreso", "Quale nonna?"),
    L("saul/neutro", "Quella con le gambe."),
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
    # ANGOLI (02/11, richiesta dell'autore): chi esplora fuori dalla strada principale viene premiato con una chiacchiera
    # che altrimenti non sente. Punti "angolo_*" in data/atto1.json (lontani dal percorso, raggiungibili: provati sui muri).
    B("s_angolo_fontana", V("angolo_fontana"), L("nox/neutro", "La fontana. Il telefono doveva finire lì dentro."),
      L("rio/felice", "Lancialo! Faccio lo slow motion!"), L("nox/neutro", "Lancio il tuo.")),
    B("s_angolo_gioielleria", V("angolo_gioielleria"), L("saul/neutro", "Una gioielleria con la saracinesca alzata. Alle tre di notte."),
      L("lance/serio", "Non ci pensare."), L("saul/neutro", "Ci pensavi tu. Io guardavo.")),
    B("s_angolo_fondo", V("angolo_fondo"), L("lance/serio", "Un'altra foto mia. Di profilo, stavolta."),
      L("saul/neutro", "Il profilo buono?"), L("lance/serio", "Non ne ho uno buono.")),
    # Dall'apertura (storia che non si salta, 02/11): si discute su chi scappa con chi mentre si e' gia' in fuga.
    # Z alta = partono una dopo l'altra appena si prende il controllo, in quest'ordine.
    B("s_fuga_lance", Z(99.0), L("lance/serio", "Io non scappo dalla mia squadra. Vado e spiego."),
      L("saul/neutro", "Ti arresteranno con l'uniforme in ordine.")),
    B("s_fuga_nox", Z(99.0), L("nox/neutro", "Io scappo. Nessuno mi interroga prima del caffè.")),
    B("s_fuga_rio", Z(99.0), L("rio/felice", "Raga, seguiamo quello col pacco. Ha la faccia di uno che sa scappare!"),
      L("saul/neutro", "Non seguirmi. Porto sfortuna."), L("rio/felice", "Allora siamo in due!")),
    B("s_fuga_articolo", Z(99.0), L("lance/arrabbiato", "...Articolo nove: in mancanza di ordini si seguono i sospettati."),
      L("nox/neutro", "Se l'è appena inventato.")),
    B("s_orologio", C, L("saul/neutro", "Capo, che ore sono?"), L("lance/serio", "Tre e ventuno. E quaranta secondi."),
      L("saul/neutro", "Non ti ho chiesto i secondi."), L("lance/serio", "Omaggio.")),
    B("s_inizio", Z(6.0), L("lance/serio", "Formazione. Io davanti, voi dietro, nessuno parla."),
      L("saul/neutro", "Tu davanti, con quella divisa? Ci vedono da tre isolati."),
      L("rio/felice", "Raga, lui è Lance. Salutate Lance. ...Lance non saluta.")),
    B("s_caffe", Z(-3.0), L("nox/triste", "Qualcuno ha un caffè? Non chiedo altro dalla vita."),
      L("saul/neutro", "Te lo trovo. Ti costa."), L("nox/neutro", "Tutto quello che vuoi.")),
    B("s_strisce", Z(-15.0), L("lance/serio", "Attraversate sulle strisce."),
      L("rio/sorpreso", "C'è una cupola sopra la città e tu pensi ancora alle strisce pedonali?"),
      L("lance/serio", "Sì.")),
    B("s_sirene", Z(-26.0), L("nox/serio", "Sentite? Nessuna sirena qui. Le Civette non sembra ci stiano seguendo."),
      L("saul/neutro", "Perché forse stanno aspettando.")),
    B("s_auto", V("auto_rossa"), L("saul/neutro", "Questa la apro in quattro secondi."),
      L("lance/arrabbiato", "E io ti arresto in tre.")),
    B("s_auto_blu", V("auto_blu"), L("rio/felice", "Raga, storia davanti a questa macchina. Luce perfetta!"),
      L("saul/neutro", "Niente impronte sul cofano."),
      L("rio/sorpreso", "...E tu come lo sai?"), L("saul/neutro", "Cultura generale.")),
    B("s_panchina", V("panchina"), L("nox/neutro", "La mia panchina. Dieci minuti fa avevo una vita."),
      L("lance/serio", "Anch'io."), L("nox/neutro", "Ti ho visto multare un piccione.")),
    B("s_scontrino", E("scontrino"), L("nox/sfotto", "Viola. Il colore del ragazzino. Povero distributore."),
      L("rio/felice", "Lo metto nella bio!")),
    B("s_telecamera", E("telecamera"), L("rio/sorpreso", "Se ci sta guardando, mi rifaccio il ciuffo."),
      L("saul/neutro", "Io la faccia. Quella onesta.")),
    B("s_c1", C, L("rio/felice", "Siamo a tre milioni di visualizzazioni... ah no. Trenta."),
      L("nox/neutro", "Trenta di troppo.")),
    B("s_c2", C, L("saul/neutro", "Capo, quanto vale il tuo distintivo al mercato nero?"),
      L("lance/arrabbiato", "Più dei tuoi denti."), L("saul/neutro", "Facevo l'inventario.")),
    B("s_c3", C, L("lance/serio", "Nessuno tocchi il mio guanto."), L("rio/sorpreso", "Nessuno l'ha toccato!")),
    B("s_c4", C, L("rio/serio", "Saul, che c'è nel pacco?"), L("saul/neutro", "Niente."),
      L("rio/sorpreso", "E perché lo tieni come un neonato?"), L("saul/neutro", "Il niente costa caro.")),
    B("s_c5", C, L("nox/serio", "Lance. Se ci prendono, tu cosa dici?"), L("lance/serio", "La verità."),
      L("nox/neutro", "E se la verità non ti crede?"), L("lance/serio", "...")),
    B("s_f1", F, L("nox/triste", "Se stiamo fermi mi addormento in piedi. So come si fa.")),
    B("s_f2", F, L("rio/felice", "Raga, se stiamo fermi faccio una live. Tre... due..."), L("lance/serio", "Cammina.")),
]
CH["incrocio"] = [
    # ANGOLI (02/11, richiesta dell'autore): chi esplora fuori dalla strada principale viene premiato con una chiacchiera
    # che altrimenti non sente. Punti "angolo_*" in data/atto1.json (lontani dal percorso, raggiungibili: provati sui muri).
    B("i_angolo_edicola", V("angolo_edicola"), L("lance/neutro", "L'edicola di Gino. Mi teneva il giornale ogni mattina."),
      L("rio/sorpreso", "E tu che gli davi?"), L("lance/serio", "Una multa al mese. Per affetto.")),
    B("i_angolo_bar", V("angolo_bar"), L("nox/sorpreso", "Un caffè fermo nella tazza da sei ore."),
      L("saul/neutro", "È di quel tizio congelato."), L("nox/neutro", "Lo era.")),
    B("i_angolo_cane", V("angolo_cane"), L("rio/felice", "Raga, un cane fermo a metà salto. È il mio nuovo sfondo."),
      L("lance/serio", "Briciola. L'ho multato due volte."), L("rio/sorpreso", "...Un CANE?"),
      L("lance/serio", "Senza guinzaglio.")),
    B("i_ripresa", C, L("rio/felice", "Lance, Saul, quella di prima la rifacciamo? Non stavo registrando."),
      L("lance/serio", "No."), L("saul/neutro", "La seconda si paga."),
      L("nox/neutro", "E io ci passo davanti.")),
    B("i_inizio", Z(5.0), L("lance/serio", "Qui ho fermato un ladro di biciclette."),
      L("saul/neutro", "Mio cugino. Ti saluta."), L("lance/serio", "Tuo cugino aveva sessant'anni."),
      L("saul/neutro", "E ne dimostra almeno trenta.")),
    B("i_echo", Z(-2.0), L("echo/neutro", "Lance. Telecamera ventisei. Un tuo collega al chiosco. Sta mangiando un panino."),
      L("lance/serio", "Marino. Mangia in servizio. Lo segnalavo ogni settimana."),
      L("echo/felice", "Ha la maionese sul mento. Stavolta lo segnalo io.")),
    B("i_auto", V("auto_ferme"), L("nox/serio", "Respirano. Ma non sbattono le palpebre."),
      L("rio/triste", "Ho i brividi. E non sto nemmeno registrando.")),
    B("i_barriera", V("barriera"), L("lance/sorpreso", "Una barriera LibraCorp. Montata male. Chi l'ha montata verrà richiamato."),
      L("nox/neutro", "Sei ricercato."), L("lance/serio", "Lui di più.")),
    B("i_radio", E("radio"), L("saul/neutro", "Con me «vivo» è un buon inizio di trattativa."),
      L("lance/serio", "Con Astrid non si tratta.")),
    B("i_multa", E("multa"), L("rio/felice", "Nox è un lampeggiante! Nox, fai «niinoo»."), L("nox/neutro", "No."),
      L("rio/felice", "Una volta!"), L("nox/neutro", "...niinoo."),
      L("echo/felice", "Registrato.")),
    B("i_c1", C, L("saul/neutro", "Capo, la precedenza la dai anche a noi?"), L("lance/serio", "A te mai.")),
    B("i_c2", C, L("nox/neutro", "Un semaforo che non cambia mai. Ho avuto capi così.")),
    B("i_c3", C, L("rio/felice", "Lance che guida è come un tutorial: lento, ma ti spiega tutto."), L("lance/serio", "Grazie.")),
    B("i_c4", C, L("saul/neutro", "Echo. Quanto vuoi per spegnere la telecamera sopra la banca?"),
      L("echo/neutro", "Non ho un prezzo."), L("saul/neutro", "Tutti hanno un prezzo."),
      L("echo/serio", "Il mio non lo so ancora.")),
    B("i_c5", C, L("echo/neutro", "Nox. Perché bevi caffè se tanto non dormi?"),
      L("nox/neutro", "Senza caffè non dormo e sono pure triste.")),
    B("i_f1", F, L("lance/serio", "Non si sosta in mezzo all'incrocio. Neanche con la fine del mondo.")),
]
CH["dentro_rosso"] = [
    B("dr_conto", C, L("saul/neutro", "Capo. Ti ho tolto un pugno dalla faccia. Sono venti."),
      L("lance/serio", "Non pago."), L("saul/neutro", "Ventidue.")),
    B("dr_inizio", Z(6.0), L("rio/sorpreso", "È tutto rosso. Anche il cielo. Anche i pensieri."),
      L("lance/serio", "Vicini. Qui le regole le fa lui.")),
    B("dr_echo", Z(-6.0), L("rio/serio", "Raga, è strano senza Echo. Non ci guarda nessuno."),
      L("saul/neutro", "Vacanza.")),
    B("dr_c1", C, L("saul/neutro", "Auto che galleggiano. Mettilo nel rapporto, capo."),
      L("lance/serio", "Ho finito le pagine.")),
    B("dr_c2", C, L("nox/neutro", "Questo rosso mi ricorda i miei occhi. Ventotto ore sveglia."),
      L("rio/felice", "Sei un meme vivente.")),
    B("dr_c3", C, L("rio/serio", "Saul, se restassimo bloccati qui per sempre?"),
      L("saul/neutro", "Aprirei un'officina. Clienti fermi.")),
    # nuove (02/11)
    B("dr_orologio", C, L("lance/serio", "Sei e zero zero. E zero secondi. Ancora."),
      L("saul/neutro", "Finalmente sei puntuale.")),
    B("dr_f1", F, L("lance/serio", "Fermi al rosso. Bravi."), L("nox/neutro", "Ci siamo solo stancati.")),
]
CH["vicolo"] = [
    # ANGOLI (02/11, richiesta dell'autore): chi esplora fuori dalla strada principale viene premiato con una chiacchiera
    # che altrimenti non sente. Punti "angolo_*" in data/atto1.json (lontani dal percorso, raggiungibili: provati sui muri).
    B("v_angolo_gatto", V("angolo_gatto"), L("saul/sorpreso", "Un gatto mi fissa da quando siamo entrati."),
      L("nox/neutro", "Si fa offrire la cena da tutto il quartiere."), L("saul/neutro", "Un collega.")),
    B("v_angolo_scritta", V("angolo_scritta"), L("rio/sorpreso", "Raga, su questo muro c'è scritto «NOX TORNA»."),
      L("nox/neutro", "Vecchia."), L("rio/serio", "La vernice è fresca."), L("nox/triste", "...")),
    B("v_angolo_fondo", V("angolo_fondo"), L("lance/serio", "Vicolo cieco. Articolo diciotto: mai entrare in un vicolo cieco."),
      L("saul/neutro", "E allora perché ci siamo?"), L("lance/serio", "Per controllare che fosse cieco.")),
    B("v_distributore", C, L("lance/serio", "Echo. Mi sta guardando qualcuno?"),
      L("echo/neutro", "Io."), L("lance/serio", "A parte te."), L("echo/neutro", "Nessuno."),
      L("echo/felice", "...Colpetto sul fianco. Due merendine. Come Saul."),
      L("lance/neutro", "Non è a verbale.")),
    B("v_batteria", C, L("rio/sorpreso", "Raga. Emergenza. Quattro per cento."),
      L("lance/serio", "Ho un cavo."), L("rio/triste", "Connettore sbagliato."), L("lance/serio", "Regolamentare."),
      L("saul/neutro", "Io ho un adattatore."), L("rio/sorpreso", "Da dove viene?"),
      L("saul/neutro", "Da un posto onesto. Prima di me.")),
    B("v_inizio", Z(5.0), L("nox/neutro", "Il mio vecchio posto. Mangiavo su quel gradino. Panino e silenzio."),
      L("rio/felice", "Che vita glamour, le Civette."), L("nox/neutro", "Il panino no.")),
    B("v_echo", Z(-3.0), L("echo/neutro", "Nox. Da questa telecamera ti vedevo mangiare. Davi le briciole a un gatto."),
      L("nox/sorpreso", "...Mi guardavi?"),
      L("echo/neutro", "Il gatto si chiamava Ricevuta."), L("nox/neutro", "Non dirlo a nessuno.")),
    B("v_cabine", V("cabine"), L("saul/neutro", "Squillano tutte. Nessuno risponda."),
      L("rio/sfotto", "Neanche se è uno sponsor?"), L("saul/neutro", "Soprattutto.")),
    B("v_manifesti", V("manifesti"), L("lance/serio", "I nostri manifesti. Già stampati. Che efficienza."),
      L("saul/neutro", "Io sono venuto benissimo. Tu sembri un frigorifero."), L("lance/serio", "Regolamentare.")),
    B("v_registro", E("registro"), L("rio/serio", "Nox... va tutto bene?"), L("nox/triste", "No. Ma cammino."),
      L("rio/serio", "Posso camminarti vicino?"), L("nox/neutro", "Puoi.")),
    B("v_adesivo", E("adesivo"), L("lance/serio", "Saul, il verde sei tu."),
      L("saul/neutro", "Faccio quest'effetto alle cabine.")),
    B("v_c1", C, L("lance/serio", "Nox guida in silenzio. La migliore squadra che abbia mai avuto."),
      L("rio/felice", "Lance ha detto una cosa carina! Screenshot!"), L("lance/serio", "Tecnica.")),
    B("v_c2", C, L("saul/neutro", "Agente Nox, se ci prendono le Civette, una buona parola?"),
      L("nox/neutro", "Dico che sei innocuo."), L("saul/neutro", "Che cattiveria.")),
    B("v_c3", C, L("rio/felice", "Echo, quando una cosa fa ridere si scrive «AHAHAH»."),
      L("echo/neutro", "AHAHAH."), L("rio/sorpreso", "...Detta così fa paura.")),
    B("v_c4", C, L("echo/neutro", "Lance. Tu non ridi mai. È un guasto?"),
      L("lance/serio", "È un regolamento."), L("echo/neutro", "Che articolo?"), L("lance/serio", "...")),
    B("v_f1", F, L("nox/serio", "Non fermatevi. Le cabine pensano che aspettiate una chiamata.")),
]
CH["dentro_blu"] = [
    B("db_thermos", C, L("nox/serio", "Chi ha toccato il thermos."),
      L("rio/sorpreso", "Io no! Cioè, l'ho spostato. Per l'inquadratura."),
      L("nox/neutro", "Manca un sorso."), L("rio/triste", "...Piccolo."),
      L("saul/neutro", "Mia nonna diceva: tra una donna e il suo caffè non ci si mette.")),
    B("db_inizio", Z(6.0), L("nox/serio", "Sento lo squillo. Anche dentro la testa."),
      L("saul/neutro", "Copriamolo. Capo, una barzelletta."),
      L("lance/serio", "Articolo quattordici: vietato raccontare barzellette in servizio."),
      L("rio/sorpreso", "...Era quella, la barzelletta?"), L("lance/serio", "Sì.")),
    B("db_c1", C, L("rio/serio", "Nox, dimmi una cosa bella."), L("nox/neutro", "Il caffè di domani.")),
    B("db_c2", C, L("saul/neutro", "Agente. Se ti senti cadere, appoggiati. Non ti faccio pagare."),
      L("nox/neutro", "La cosa più gentile che tu abbia mai detto."), L("saul/neutro", "Lo nego.")),
    # nuove (02/11)
    B("db_gettoni", C, L("rio/sorpreso", "Un telefono coi gettoni. Dove si mette il caricatore?"),
      L("nox/neutro", "Al museo.")),
    B("db_ora", C, L("lance/serio", "Ore tre e dodici. Di nuovo."), L("nox/serio", "Non dirmi l'ora qui dentro."),
      L("lance/neutro", "...Ricevuto.")),
    B("db_f1", F, L("nox/serio", "Non state fermi. Qui il silenzio squilla.")),
]
CH["galleria"] = [
    # ANGOLI (02/11, richiesta dell'autore): chi esplora fuori dalla strada principale viene premiato con una chiacchiera
    # che altrimenti non sente. Punti "angolo_*" in data/atto1.json (lontani dal percorso, raggiungibili: provati sui muri).
    B("g_angolo_cabina", V("angolo_cabina_foto"), L("rio/felice", "Una cabina per le fototessere! Raga, tutti dentro!"),
      L("lance/serio", "Siamo ricercati."), L("rio/felice", "Appunto. Ci servono foto nuove.")),
    B("g_angolo_fontana", V("angolo_fontana"), L("echo/neutro", "Quella fontana. Ogni giorno ci buttano quaranta monete."),
      L("echo/neutro", "Desiderano quasi tutti la stessa cosa."), L("rio/felice", "Soldi?"),
      L("echo/neutro", "Che qualcuno li guardi."), L("rio/serio", "...Ah.")),
    B("g_angolo_maschere", V("angolo_maschere"), L("nox/neutro", "Un negozio di maschere. Rio, vuoi un ricambio?"),
      L("rio/serio", "La mia non si cambia."), L("nox/neutro", "Lo so.")),
    B("g_travestimenti", C, L("lance/serio", "Galleria piena di gente. Non dobbiamo dare nell'occhio."),
      L("rio/sfotto", "Lance, con quel cappotto sembri un armadio triste."), L("lance/serio", "Anonimo."),
      L("nox/neutro", "Io ho un cappello. Fine."),
      L("saul/neutro", "Io ho scambiato la giacca con un manichino. Ci ha guadagnato lui."),
      L("rio/felice", "Io non mi travesto. Un profilo così non si nasconde."), L("nox/neutro", "È questo il problema.")),
    B("g_inizio", Z(5.0), L("rio/felice", "La Galleria Lumière! Qui ho girato il mio primo video. Tre like. Uno era mia madre."),
      L("nox/neutro", "E gli altri due?"), L("rio/triste", "Mia madre.")),
    B("g_echo", Z(-4.0), L("echo/neutro", "Rio. Il tuo primo video l'ho visto. Telecamera nove. Undici volte."),
      L("rio/felice", "...Bellissimo. E inquietante.")),
    B("g_vetrine", V("vetrine"), L("saul/serio", "Quei manichini ieri avevano una faccia. Nessuno compra quella giacca senza.")),
    B("g_manichini", V("manichini"), L("lance/serio", "Non guardateli negli occhi."),
      L("rio/sfotto", "Non hanno occhi, Lance."), L("lance/serio", "Appunto.")),
    B("g_chat", E("chat"), L("nox/neutro", "Spegni quel telefono, Rio. Ogni tanto."),
      L("rio/triste", "Se lo spengo smetto di esistere."), L("nox/neutro", "Io lo spengo da anni. Esisto. Più o meno.")),
    B("g_etichetta", E("etichetta"), L("saul/neutro", "Capo, la collezione dice che sei fuori moda."),
      L("lance/serio", "L'uniforme non va mai fuori moda."), L("rio/felice", "Questa frase sì.")),
    B("g_c1", C, L("saul/neutro", "Guida Rio e siamo passati davanti a tre negozi di cappelli."),
      L("rio/felice", "Ricerca sul campo!")),
    B("g_c2", C, L("rio/felice", "Saul, insegnami a mentire."),
      L("saul/neutro", "Prima regola: non chiederlo davanti a un poliziotto."), L("lance/serio", "Ho sentito.")),
    B("g_c3", C, L("echo/neutro", "Saul. Come si capisce se uno mente?"),
      L("saul/neutro", "Dice la verità con troppa cura."), L("echo/serio", "...Capito."),
      L("saul/neutro", "Perché?"), L("echo/neutro", "Per un film.")),
    B("g_f1", F, L("rio/serio", "Raga, se restiamo fermi i manichini ci copiano.")),
]
CH["dentro_verde"] = [
    B("dv_entrata", C, L("rio/felice", "Raga, dal boss entro io per primo. Al rallentatore."),
      L("lance/serio", "In formazione."),
      L("saul/neutro", "Lascialo entrare. Il primo colpo lo prende lui."),
      L("rio/serio", "...In formazione.")),
    B("dv_inizio", Z(6.0), L("rio/sorpreso", "Mille me in posa. Nessuno ha la faccia."),
      L("saul/neutro", "Io una faccia ce l'ho. Bellissima, tra l'altro.")),
    B("dv_c1", C, L("lance/serio", "Contate i manichini. Se sono pari, va tutto bene."), L("nox/neutro", "E se sono dispari?"),
      L("lance/serio", "Volevo solo che contaste qualcosa.")),
    B("dv_c2", C, L("nox/neutro", "Rio. Stammi vicino."), L("rio/serio", "Hai paura?"),
      L("nox/neutro", "Tu sì. La tengo io per tutti e due.")),
    # nuove (02/11)
    B("dv_somiglia", C, L("saul/neutro", "Rio, questi manichini ti somigliano."), L("rio/felice", "Perché sono belli?"),
      L("saul/neutro", "Perché posano anche quando nessuno guarda.")),
    B("dv_specchio", C, L("lance/serio", "Articolo trenta: vietato specchiarsi in servizio."),
      L("rio/serio", "Non mi specchio. Controllo che ci sono.")),
    B("dv_f1", F, L("nox/neutro", "Fermi qui no. Si mettono in posa anche loro.")),
]
CH["caveau"] = [
    # ANGOLI (02/11, richiesta dell'autore): chi esplora fuori dalla strada principale viene premiato con una chiacchiera
    # che altrimenti non sente. Punti "angolo_*" in data/atto1.json (lontani dal percorso, raggiungibili: provati sui muri).
    B("c_angolo_cassette", V("angolo_cassette"), L("saul/neutro", "Cassette di sicurezza. Ognuna è il segreto di qualcuno."),
      L("rio/sorpreso", "E la tua qual è?"), L("saul/neutro", "La numero zero. Non esiste.")),
    B("c_angolo_quadro", V("angolo_quadro"), L("lance/serio", "Un quadro rubato. È nel registro dal 2019."),
      L("saul/neutro", "Dal 2018."), L("lance/sorpreso", "...Come lo sai?"), L("saul/neutro", "Mia nonna.")),
    B("c_angolo_brandina", V("angolo_brandina"), L("nox/felice", "Una brandina nell'ufficio del direttore. Svegliatemi fra cinque minuti."),
      L("lance/serio", "Siamo in mezzo a un colpo."), L("nox/neutro", "Quattro.")),
    B("c_orologio", C, L("saul/neutro", "Capo, che ore sono?"),
      L("lance/serio", "Quattro e diciassette. Siamo in ritardo di quattro secondi."),
      L("saul/neutro", "Mia nonna diceva: chi conta i secondi non si gode i minuti."), L("lance/serio", "Quale nonna?"),
      L("saul/neutro", "Quella puntuale.")),
    B("c_inizio", Z(5.0), L("saul/neutro", "Il caveau. Sentite l'odore? Soldi vecchi e cattive intenzioni."),
      L("lance/serio", "Mani in vista, Saul."), L("saul/neutro", "Sempre. È questo il trucco.")),
    B("c_echo", Z(-3.0), L("echo/neutro", "Saul. Diciotto telecamere qui sotto. Le ho spente tutte."),
      L("saul/neutro", "Perché?"), L("echo/felice", "Così, se tocchi qualcosa, lo so solo io."),
      L("saul/neutro", "...Credo di volerti bene. È sgradevole.")),
    B("c_lingotti", V("lingotti"), L("saul/neutro", "Lingotti. Veri. Posso toccarne uno? Per affetto."),
      L("nox/neutro", "Tocca e ti tagliamo la mano. Lance ha già quella di ricambio."), L("lance/arrabbiato", "Nox.")),
    B("c_laser", V("laser"), L("rio/felice", "Laser! Come nei film! Saul, fai la capriola!"),
      L("saul/neutro", "Io cammino.")),
    B("c_inventario", E("inventario"), L("rio/serio", "Lance... vuoi un abbraccio?"), L("lance/serio", "No."),
      L("rio/felice", "Te lo do lo stesso. Mentalmente.")),
    B("c_c1", C, L("nox/neutro", "Saul, guidi stranamente bene. Quasi onesto."),
      L("saul/neutro", "Abbassa la voce.")),
    B("c_c2", C, L("rio/serio", "Saul, se potessi rubare una cosa sola?"),
      L("saul/neutro", "Il tempo. Ne avete sprecato tanto, con me. Ve lo restituirei."),
      L("rio/sorpreso", "...Questa era bella."), L("saul/neutro", "Rubata.")),
    B("c_c3", C, L("echo/neutro", "Quando la cupola cade, vi rivedrò?"),
      L("rio/felice", "Certo! Sei nei miei contatti!"), L("echo/triste", "...Già.")),
    B("c_f1", F, L("saul/neutro", "Non fermatevi davanti ai lingotti. Le telecamere registrano la faccia golosa.")),
]
CH["tangenziale"] = [
    # ANGOLI (02/11, richiesta dell'autore): chi esplora fuori dalla strada principale viene premiato con una chiacchiera
    # che altrimenti non sente. Punti "angolo_*" in data/atto1.json (lontani dal percorso, raggiungibili: provati sui muri).
    B("t_angolo_panorama", V("angolo_panorama"), L("rio/serio", "Da qui si vede tutta la città."),
      L("lance/neutro", "Trecentododici multe. Da quassù sembrano poche.")),
    B("t_angolo_piazzola", V("angolo_piazzola"), L("saul/neutro", "Piazzola. Un distributore."), L("lance/serio", "Faccio io."),
      L("lance/serio", "..."), L("saul/neutro", "Il colpetto è sul fianco, capo. Ci vogliono anni.")),
    B("t_angolo_pannello", V("angolo_pannello"), L("echo/neutro", "(dal pannello luminoso) «GUIDATE CON PRUDENZA». Era per voi."),
      L("nox/neutro", "Non guidiamo. Scappiamo."), L("echo/felice", "«SCAPPATE CON PRUDENZA», allora.")),
    B("t_nomi", C, L("lance/serio", "Fuori città servono nomi falsi. Io sono Luca Bianchi. Impiegato. Documenti in ordine."),
      L("saul/neutro", "Troppo in ordine. Nessun impiegato ha i documenti in ordine."),
      L("rio/felice", "Io sono Rio Tempesta!"), L("nox/neutro", "Ti trovano in un minuto."),
      L("nox/neutro", "Io sono Maria. Nessuno si ricorda una Maria."),
      L("saul/neutro", "Io ne ho cinque. Il più onesto è un vescovo.")),
    B("t_conto", C, L("saul/neutro", "Capo, siamo a trentuno."), L("lance/serio", "Nel caveau ti ho tirato fuori io da sotto la porta."),
      L("saul/neutro", "Scalato. Restano trentuno.")),
    B("t_pasto", F, L("nox/neutro", "Cinque minuti. Mangiamo tranquilli."),
      L("lance/serio", "Perché l'hai detto."),
      L("echo/neutro", "Pattuglia a quattrocento metri."), L("nox/neutro", "Il panino lo mangio correndo.")),
    B("t_inizio", Z(6.0), L("lance/serio", "Sei corsie, nessuna auto, il sole in faccia. Il posto peggiore per nascondersi."),
      L("saul/neutro", "Il migliore per scappare."),
      L("nox/neutro", "Io mi sdraio sull'asfalto e faccio l'incidente.")),
    B("t_echo1", Z(0.0), L("echo/triste", "Lance. La telecamera del ponte. La giro?"),
      L("lance/serio", "Fa' quello che devi."), L("echo/triste", "...La giro."),
      L("lance/neutro", "Grazie. Non ti ho perdonata. Grazie.")),
    B("t_auto", V("auto_ferme"), L("rio/sorpreso", "Le macchine sono vuote. Con le chiavi dentro."),
      L("saul/neutro", "Non guardatemi."), L("lance/serio", "Ti guardiamo tutti."),
      L("saul/neutro", "Non tocco niente. Fa male.")),
    B("t_cartellone", V("cartellone"), L("nox/neutro", "Le nostre facce, alte cinque metri."),
      L("rio/felice", "Il mio primo cartellone! Piango.")),
    B("t_casello", V("casello"), L("lance/serio", "Il casello. Se c'è un posto di blocco, è lì."),
      L("saul/neutro", "Per questo pago in contanti.")),
    B("t_ricercati", E("ricercati"), L("saul/neutro", "«Sguardo onesto: non fidarsi.» Me lo faccio stampare sulle magliette."),
      L("rio/felice", "Io su quelle «MOLESTO»! Merch!")),
    B("t_verbale", E("verbale"), L("nox/neutro", "Ci salva la cover coi brillantini. Non pensavo di dirlo mai.")),
    B("t_radio", E("radio"), L("lance/serio", "Astrid e Strix sullo stesso canale. Non succedeva da dieci anni."),
      L("nox/neutro", "Litigano come una vecchia coppia."),
      L("lance/serio", "Lo erano. Di pattuglia."), L("nox/sorpreso", "...Non lo sapevo."), L("lance/neutro", "Nessuno.")),
    B("t_c1", C, L("rio/serio", "Raga, adesso che siamo fuori, dove andiamo?"), L("saul/neutro", "Dove nessuno ci cerca."),
      L("rio/sorpreso", "E dov'è?"), L("saul/neutro", "Non lo so. Per questo nessuno ci cerca.")),
    B("t_c2", C, L("nox/neutro", "Cinquantotto ore sveglia. Se crollo, lasciatemi qui. Col cartello NON SVEGLIARE."),
      L("lance/serio", "Non si lascia indietro nessuno. Articolo uno."),
      L("nox/neutro", "Il tuo articolo uno cambia ogni giorno.")),
    B("t_c3", C, L("rio/serio", "Saul... Echo la perdoniamo?"),
      L("saul/neutro", "Io non perdono. Faccio i conti."),
      L("rio/triste", "E?"), L("saul/neutro", "Ci ha fregato una volta. Ci ha salvato sei. Non tornano.")),
    B("t_c4", C, L("lance/serio", "Nox. Grazie per il turno di guardia di stanotte."), L("nox/neutro", "Era di Rio."),
      L("rio/sorpreso", "Mi sono addormentato al terzo minuto.")),
    B("t_c5", C, L("echo/triste", "Nox. Le notti erano vere. Su tutte le mie telecamere."),
      L("nox/neutro", "Lo so. È questo che mi fa arrabbiare."), L("echo/neutro", "...Posso farti compagnia lo stesso?"),
      L("nox/neutro", "Stanotte no. Domani forse.")),
    B("t_f1", F, L("saul/neutro", "Non fermatevi in tangenziale. Mia nonna è morta così."), L("rio/sorpreso", "DAVVERO?"),
      L("saul/neutro", "No. Ma ti sei mosso.")),
]
import re

# Storia che non si salta (02/11): una battuta oltre MAX_CAR diventa due (o piu') fumetti dello stesso personaggio,
# spezzata dove c'e' gia' una fine di frase, mai dentro le «virgolette». Le parole restano quelle.
# "se"/"se_non" valgono per tutti i pezzi; "imposta" e "scelte" restano sull'ultimo.
MAX_CAR = 80
_FINE = re.compile(r"(?<=[.!?»…])\s+")


def _spezza_testo(s):
    if len(s) <= MAX_CAR:
        return [s]
    best = None
    for m in _FINE.finditer(s):
        a, b = s[:m.start()], s[m.end():]
        if a.count("«") > a.count("»") or len(a) < 12 or len(b) < 8:
            continue
        if a.startswith("(") and ")" not in a:
            continue
        peso = max(len(a), len(b))
        if best is None or peso < best[0]:
            best = (peso, a, b)
    if best is None:
        return [s]
    return _spezza_testo(best[1]) + _spezza_testo(best[2])


def spezza(righe):
    out = []
    for r in righe:
        pezzi = [r["testo"]] if "scelte" in r else _spezza_testo(r["testo"])
        for i, p in enumerate(pezzi):
            n = {k: v for k, v in r.items() if i == len(pezzi) - 1 or k not in ("imposta", "scelte")}
            n["testo"] = p
            out.append(n)
    return out


for _v in S.values():
    _v["righe"] = spezza(_v["righe"])
for _v in CH.values():
    for _b in _v:
        _b["righe"] = spezza(_b["righe"])

# ---------------------------------------------------------------- battute di squadra in battaglia (04/11/2026)
# Fumetti brevi dei compagni durante il combattimento (alla Persona 5): non fermano il gioco, escono ogni tanto.
# Ogni voce e' una lista di righe {chi, testo}: la prima e' di chi agisce, le altre (botta e risposta) escono solo se
# chi risponde e' in squadra e in piedi. {"se": id, "righe": [...]} vale solo quando l'altro coinvolto e' quel personaggio.
# Regole: corte, niente spiegazioni, ogni battuta la puo' dire solo lui (skill dialoghi-odispel, PERSONAGGI_E_UMORISMO).
def R(chi, testo):
    return {"chi": chi, "testo": testo}


BAT = {
    # colpo critico: parla chi l'ha messo a segno
    "critico": {
        "lance": [[R("lance", "Colpo regolamentare.")],
                  [R("lance", "Articolo tre: si mira al centro.")],
                  [R("lance", "Zero virgola sei secondi."), R("saul", "Non te l'ha chiesto nessuno.")]],
        "nox": [[R("nox", "Fatto. Posso sedermi?")],
                [R("nox", "Meno fatica del previsto.")],
                [R("rio", "Rifallo! Non stavo registrando!"), R("nox", "No.")]],
        "rio": [[R("rio", "Raga, CLIP DELL'ANNO!")],
                  [R("rio", "Ditemi che qualcuno l'ha vista.")],
                  [R("rio", "Avete visto QUELLO CHE HO FATTO?"), R("lance", "Sì. Torna in formazione.")]],
        "saul": [[R("saul", "Fortuna. Ma la chiamo esperienza.")],
                 [R("saul", "Questo lo metto in conto.")],
                 [R("saul", "Mia nonna diceva: dove non arriva la mano, arriva il caso."), R("nox", "Tua nonna non esiste.")]],
    },
    # nemico messo K.O.: parla chi ha dato l'ultimo colpo
    "ko_nemico": {
        "lance": [[R("lance", "Neutralizzato.")],
                  [R("lance", "Uno in meno. In orario.")],
                  [R("lance", "Resta a terra. È un ordine.")]],
        "nox": [[R("nox", "Spento. Beato lui.")],
                [R("nox", "Uno. Il caffè è ancora caldo.")]],
        "rio": [[R("rio", "E con questo... SIPARIO!")],
                  [R("rio", "Saluta il pubblico! ...Non saluta.")]],
        "saul": [[R("saul", "Niente di personale. Quasi niente.")],
                 [R("saul", "Ha lasciato qualcosa? Monete, chiavi, rimpianti?"), R("lance", "Saul.")]],
    },
    # un compagno va K.O.: reagisce un altro in piedi (chi parla -> chi e' caduto)
    "compagno_ko": {
        "lance": {"nox": [[R("lance", "Nox! ...Coprite il lato sinistro.")]],
                  "rio": [[R("lance", "Rio, resta giù. Ci penso io.")]],
                  "saul": [[R("lance", "Saul, in piedi. Non ti ho dato il permesso.")]]},
        "nox": {"lance": [[R("nox", "Lance è giù. Addio pausa.")]],
                "rio": [[R("nox", "Rio. Non è il momento di fare scena.")]],
                "saul": [[R("nox", "Saul. Alzati, mi devi un caffè.")]]},
        "rio": {"lance": [[R("rio", "LANCE! No no no, questa non va in onda!")]],
                  "nox": [[R("rio", "Nox?! Chi mi dice adesso se vado bene?")]],
                  "saul": [[R("rio", "Saul! Sveglia, ti stavo riprendendo!")]]},
        "saul": {"lance": [[R("saul", "Il capo a terra. Brutto affare.")]],
                 "nox": [[R("saul", "Nox. ...Questo non era nel prezzo.")]],
                 "rio": [[R("saul", "Ragazzo. I riflettori non valgono tanto.")]]},
    },
    # si mette davanti a un compagno e prende il colpo al suo posto: parla chi copre
    "copre": {
        "lance": [[R("lance", "Dietro di me.")],
                  [R("lance", "Il colpo lo prendo io. Procedura.")]],
        "nox": [[R("nox", "Va bene. Questo lo prendo io.")],
                [R("nox", "Non abituarti.")]],
        "rio": [[R("rio", "Inquadrate qui: IL SALVATAGGIO!")]],
        "saul": [[R("saul", "Questo te lo segno.")],
                 {"se": "lance", "righe": [R("saul", "Ti ho salvato. Il conto arriva domani."), R("lance", "Rifiuto.")]}],
    },
    # torna in piedi (RISPONDO IO di Nox): parla chi si rialza
    "rialzato": {
        "lance": [[R("lance", "Ero in pausa tattica.")]],
        "rio": [[R("rio", "Il protagonista torna sempre!")]],
        "saul": [[R("saul", "Non ero a terra. Trattavo.")]],
        "nox": [[R("nox", "Cinque minuti in più non li avevo chiesti.")]],
    },
}

out = {"_nota": "Testi dell'atto 1 (PROVVISORI). Generati da tools/gen_dialoghi (vedi docs/STORIA.md per voci e arco). Scene: righe + riassunto. Una riga puo' avere 'se' o 'se_non' (vale solo se una scelta e' stata fatta o no) e 'scelte' (lista di {testo, imposta, vai}). 'chiacchiere': battute durante l'esplorazione, per area. 'battaglia': fumetti brevi della squadra in combattimento (critico, ko_nemico, compagno_ko, copre, rialzato). Gli id dei personaggi restano lance/rio (file e ritratti); i nomi sono Lance e Rio."}
out.update(S)
out["chiacchiere"] = CH
out["battaglia"] = BAT

# nomi definitivi nei testi (gli id interni restano lance/rio)
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
# Storia che non si salta (feedback amici 18/10): una battuta oltre MAX_CAR va spezzata in due fumetti, una scena oltre
# MAX_RIGHE va spezzata o spostata in parte nelle chiacchiere. Qui si avvisa e basta: decide chi scrive.
MAX_RIGHE = 24
lunghe = [(k, r["testo"]) for k, v in S.items() for r in v["righe"] if len(r["testo"]) > MAX_CAR]
lunghe += [(k, r["testo"]) for k, v in CH.items() for b in v for r in b["righe"] if len(r["testo"]) > MAX_CAR]
fiumi = [(k, len(v["righe"])) for k, v in S.items() if len(v["righe"]) > MAX_RIGHE]
print("battute oltre", MAX_CAR, "caratteri:", len(lunghe), "| scene oltre", MAX_RIGHE, "battute:", fiumi)
