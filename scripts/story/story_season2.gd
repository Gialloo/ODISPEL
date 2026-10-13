class_name StorySeason2
extends RefCounted

# Stagione 2: la squadra CAM con Dafne (Agent 02 di LibraCorp) al seguito.
# Stesso formato di StoryData; StoryData.text() cerca anche qui.

const SCENES: Dictionary = {
	"sirena_pre": """
@bg via_pia
*: STAGIONE 2. Via Pia, tre settimane dopo l'alba dei sette minuti. Una sirena d'allarme urla da sola da tre notti, e solo sopra un palazzo di LibraCorp.
bruno [neutral] L: Squadra, qui Bruno. La centrale ha mandato qualcuno. Dicono sia di supporto. Io direi che e' di controllo.
kira [neutral] L: Chi?
dafne [neutral] R: Agent 02, LibraCorp. Dafne. Il Consiglio vuole un rapporto sulla squadra CAM e sull'anomalia che chiamate Eco.
dax [surprised] L: Agent 02? Pensavo fossero solo voci di corridoio.
dafne [neutral] R: Le voci di corridoio sono la mia specialita'. Soprattutto quelle su di te, sergente.
eco [surprised] R: Ha un fucile enorme. Ed e' gentile come un fucile.
elle [happy] L: Io ho del te'. Anche per i fucili.
dafne [surprised] R: ...Non ho mai accettato un te' da un'ispezionata.
sirena [angry] R: UUUUUUU. TUTTI FUORI. TUTTI FUORI.
dafne [neutral]: Rapporto dopo. Prima la rumorosa.
> Lasciamo che Dafne si unisca a noi -> insieme
> Le diciamo di restare fuori dai piedi -> distanza
:insieme
kira [neutral] L: Se spari bene, resta. Se no, guardi.
@goto fine
:distanza
dafne [neutral] R: Non ho chiesto il permesso. Ma terro' la distanza. Per ora.
:fine
sirena [angry] R: UUUUUUU. AL COPRIFUOCO. AL COPRIFUOCO.
""",
	"sirena_post": """
@bg via_pia
*: La sirena si strozza e si spegne. Nel silenzio, si sente solo il vento tra i palazzi.
dafne [surprised] R: ...Ha smesso. Di solito smettono quando le chiudo io. Non cosi'.
kira [neutral] L: Hai sparato un solo colpo. Uno solo.
dafne [neutral] R: Costa meno. E poi quella del te' mi copriva le spalle.
elle [happy] L: Io? Ho solo fatto bollire l'acqua.
eco [happy] R: Dafne ha detto grazie! Con la faccia, non con la voce.
dafne [sad] R: Non lo faccio mai in squadra. Non ne ho mai avuta una.
elle [happy] L: Allora oggi si comincia. Siediti.
bruno [neutral] R: Dafne, qui Bruno. Il Consiglio chiede il tuo rapporto.
dafne [neutral] R: Dica che la squadra CAM e' idonea. E che io resto in osservazione. A tempo indeterminato.
bruno [happy] R: Ricevuto. Lo scrivo molto lentamente.
*: Dafne si unisce alla squadra. Sulla mappa, una nuova luce: CAM-09, Piazza dei Salici.
""",
	"lampione_pre": """
@bg piazza_salici
*: Piazza dei Salici, notte fonda. Ogni lampione e' acceso. E il buio, intorno, e' piu' fitto di prima.
elle [surprised] L: Le lampadine non fanno luce. La fanno vedere.
dafne [neutral] R: E' un trucco di visibilita'. Chi guarda la luce non vede cosa c'e' attorno.
kira [neutral] L: Parli come se l'avessi gia' visto.
dafne [sad] R: Alla scuola LibraCorp ci insegnavano a stare al buio. Per non farci vedere. Nessuno ci ha mai insegnato a farci trovare.
dax [neutral] L: Dafne. La scuola.
dafne [neutral] R: Non adesso, sergente.
eco [neutral] R: Il lampione guarda. Vedete? Ha un solo occhio e lo punta su di noi.
lampione [angry] R: ABBAGLIO. ABBAGLIO. ABBAGLIO.
kira [angry] L: Non guardarlo! Occhi bassi, e marchiate dove punta.
dafne [angry] R: Per questo sono qui.
""",
	"lampione_post": """
@bg piazza_salici
*: Il lampione si piega su se stesso e si spegne, un vetro alla volta. Per un attimo la piazza e' piena di stelle.
elle [happy] L: Guardate che cielo. Non lo vedevo da anni.
dafne [sad] R: Alla scuola avevamo tre ore di cielo a settimana. Poi hanno tolto anche quelle.
dax [sad] L: Mi dispiace.
dafne [neutral] R: Non serve. Ho scelto io. Ho firmato a dodici anni. Non sapevo cosa firmavo, ma lo sapevo.
kira [neutral] L: Chi te l'ha fatta firmare?
dafne [neutral] R: Un uomo con la voce gentile. Poi ho scoperto che era la voce di tutta la corporazione.
eco [happy] R: Io la voce gentile non la ho. Ma ti presto la mia, se serve.
dafne [surprised] R: ...Grazie, Eco.
*: Dal lampione spento cade una busta sigillata, con un solo timbro. LIBRACORP - RISERVATO.
dafne [neutral] R: Non e' per voi. E' per me. Dopo.
""",
	"bancomat_pre": """
@bg banca
*: Il vestibolo di una banca chiusa. Un bancomat acceso, in mezzo, mostra una cifra che nessuno ha digitato.
dafne [neutral] R: Saldo negativo. Il mio nome. La mia matricola. E una cifra.
kira [surprised] L: Quella e' una cifra da pazzi. Cos'e'?
dafne [sad] R: Il costo della mia formazione. LibraCorp ti mantiene gratis finche' non servi. Poi manda il conto.
dax [angry] L: Non e' vero. Non puo' essere.
dafne [neutral] R: Sergente, tu hai uno stipendio. Io ho un debito. E' questa la differenza tra noi.
elle [sad] L: Dafne...
bancomat [neutral] R: PRELIEVO RICHIESTO. IMPORTO: TUTTO.
eco [surprised] R: Vuole prendere tutto! Anche i miei minuti!
> Pago io la parte di Dafne -> paga
> Distruggiamo il bancomat -> distruggi
:paga
elle [happy] L: Io pago con le erbe. E con l'amicizia. Non sono molto ricca.
@goto fine
:distruggi
kira [angry] L: Un debito non si paga. Si rompe.
:fine
bancomat [angry] R: OPERAZIONE NON CONSENTITA.
""",
	"bancomat_post": """
@bg banca
*: Lo schermo del bancomat si riempie di zeri, uno dopo l'altro. Poi si spegne. Dal cassetto esce una sola monetina.
dafne [surprised] R: Il mio saldo e' a zero.
dax [happy] L: Era un'anomalia. Non vale.
dafne [neutral] R: Per la banca no. Per me si'. E' la prima cosa che qualcuno mi cancella invece di aggiungermi.
bruno [surprised] R: Squadra, qui Bruno. Ho appena visto sul registro: il debito dell'Agent 02 e' stato chiuso. Da chi?
elle [happy] L: Dall'amicizia, direi.
bruno [neutral] R: Dall'archivio. Segnato e firmato. Con la sigla 01.
dafne [surprised] R: Agent 01. Non ha mai scritto niente. Non in nove anni.
dax [sad] L: 01... ma era...
kira [neutral] L: Cosa sai di 01, Dax?
dax [sad] R: Domani. Prima la stazione. L'ultima scala e' li.
""",
	"scala_pre": """
@bg stazione
*: La stazione, notte. Una scala mobile scende e sale contemporaneamente. Ogni gradino porta a un piano diverso.
dax [neutral] L: Agent 01 non era una persona sola. Era una sigla. Il primo operatore LibraCorp di sorveglianza notturna.
dafne [neutral] R: Chi era?
dax [sad] L: Marta. La mia collega. Quella della cabina. Pensavo fosse sparita quella notte.
eco [surprised] R: Marta! Dax dice Marta quando dorme! E' lei!
elle [sad] L: Non e' sparita, Dax. Qualcuno l'ha tenuta. Da qualche parte.
kira [neutral] L: Una scala che porta a piani che non esistono. Come l'ascensore.
dafne [neutral] R: Se Marta e' sotto l'archivio, la scala la porta li. Ma e' una trappola.
scala [angry] R: SALIRE. SCENDERE. SALIRE. SCENDERE.
dax [angry] L: Allora saliamo fino in fondo. Insieme.
nico [neutral] R: Io vi tengo il corrimano. Fidatevi del vecchio custode.
""",
	"scala_post": """
@bg stazione
*: La scala si ferma. Per la prima volta in settimane i gradini non si muovono. In fondo, un neon: LINEA 0 - ULTIMA CORSA.
nico [happy] R: Io non ho mai saputo dove andavano le scale. Ma adesso so dove vanno i miei amici.
kira [happy] L: Nico, si e' commosso.
nico [neutral] R: No. Ho solo un po' di polvere negli occhi.
dafne [neutral] R: Nella linea zero non c'e' un solo treno. C'e' una frequenza. Se la trovo, so dove tengono Marta.
eco [happy] R: Io sento tutte le frequenze! Anche quelle che non esistono!
elle [happy] L: Le radio le portano le nonne. Io so dove ce n'e' una grande.
dax [neutral] L: Il negozio di Sandro. Via dei Fabbri. L'ho vista accesa ieri notte.
*: Sulla mappa, la luce di CAM-12 si accende da sola.
""",
	"radio_pre": """
@bg radio_negozio
*: Il negozio di radio di Sandro, chiuso da anni. Sulle mensole, centinaia di apparecchi. Uno solo e' acceso.
radio [neutral] R: ...pronto... pronto... qui Marta... c'e' qualcuno?
dax [surprised] L: Marta?
eco [surprised] R: Non e' lei. Ha la sua voce ma non il suo respiro.
dafne [neutral] R: E' una registrazione. Una voce presa in prestito dall'archivio.
radio [angry] R: SINTONIA. SINTONIA. SINTONIA. NESSUNO SCAPPA DALLA FREQUENZA.
kira [angry] L: Fate silenzio. Ha uno schema. Ripete tre cose, poi urla.
elle [sad] L: Marta e' ancora li dentro. Se rompiamo la radio la perdiamo?
eco [neutral] R: No. Posso tenere io la voce. Ma devo sentire fino in fondo.
dax [sad] L: Eco...
eco [happy] R: Non ho paura. Ho una squadra.
""",
	"radio_post": """
@bg radio_negozio
*: La radio si spegne a meta' di una parola. Ma nella stanza resta un'eco sottile, come un filo di voce.
eco [neutral] R: Ho sentito tutto. Dice che il suo nome e' sull'ultima riga. Quella dell'archivio.
dax [sad] L: L'ultima riga. Di quale archivio?
dafne [neutral] R: Il Registro. Quello che LibraCorp non chiama per nome. Dove finisce chi serve dopo la fine.
bruno [neutral] R: Squadra, qui Bruno. Il Registro e' sotto il porto. Ma per arrivarci serve un treno.
nico [neutral] R: C'e' un treno. Solo che non passa di giorno.
kira [neutral] L: Ho capito. L'ultima corsa. Quella della linea zero.
elle [happy] L: Ho una sciarpa in piu'. Per chi non ha niente di caldo da portare con se'.
dafne [surprised] R: ...Per me?
elle [happy] L: Per tutti. Anche per chi non l'ha mai chiesta.
""",
	"metro_pre": """
@bg metro
*: La stazione della linea zero. Il treno arriva senza luci e senza rumore. Le porte si aprono da sole.
dax [neutral] L: Ultima corsa. Nessuno scende. Nessuno risale.
dafne [neutral] R: Io salgo. Voi decidete.
kira [neutral] L: Non scherzare. Noi veniamo con te.
dafne [surprised] R: ...Perche'?
kira [happy] L: Perche' abbiamo imparato a non lasciare indietro nessuno. E ora ci sei anche tu.
dafne [sad] R: Alla scuola dicevano che i legami sono una zavorra.
elle [happy] L: Anche le zavorre servono. Alle navi, a volte.
metro [angry] R: BINARIO MORTO. BINARIO MORTO. FERMATA RICHIESTA.
eco [surprised] R: Il treno ci parla! Ha i fari come occhi, e vuole portarci via.
nico [angry] R: Non stanotte, ferraglia.
""",
	"metro_post": """
@bg metro
*: Il treno frena in una pioggia di scintille, e le porte si chiudono per sempre. Il binario riprende a brillare, come se qualcuno avesse acceso la luna sotto la citta'.
dafne [neutral] R: Il Registro e' dietro la prossima galleria.
dax [neutral] L: Prima del Registro c'e' il caveau. Dentro, la chiave.
bruno [neutral] R: Il caveau LibraCorp e' una cassaforte da quaranta tonnellate. Nessuno entra se non con una combinazione.
dafne [neutral] R: La combinazione e' la mia matricola. L'ho letta sul bancomat.
kira [surprised] L: Quel bancomat te l'ha detta apposta?
dafne [neutral] R: O qualcuno l'ha lasciata li per me. Chiunque sia, mi aspetta.
eco [neutral] R: Dafne, non andare da sola.
dafne [happy] R: Non lo faro'. Ho una squadra.
*: Per la prima volta, Dafne sorride.
""",
	"cassaforte_pre": """
@bg caveau
*: Il caveau LibraCorp, sotto il porto. Una cassaforte alta quanto una stanza, con un quadrante grande come una ruota.
dafne [neutral] R: Matricola 0-2. Combinazione accettata.
cassaforte [neutral] R: BENVENUTA, AGENT 02. HAI ESAURITO LE ORE DI LIBERTA'.
dafne [angry] R: Non ho mai avuto ore di liberta'.
cassaforte [angry] R: SERRATURA. COMBINAZIONE. FURTO. NESSUNO ESCE DA QUI CON QUALCOSA CHE NON SIA GIA' SUO.
kira [angry] L: Cosa vuole rubarci?
dafne [sad] R: Quello che mi tiene qui. Il nome vero. Mio. Quello che avevo prima di 02.
elle [sad] L: Dafne.
dafne [neutral] R: Dafne e' il nome che mi hanno dato dopo. Il mio e' scritto li dentro. Non mi serve piu'. Ma voglio sapere.
dax [neutral] L: Allora lo prendiamo. E poi sei libera di tenerlo o buttarlo.
> Rompiamo la cassaforte -> rompi
> Apriamo con la combinazione -> apri
:rompi
nico [angry] R: Questa roba si apre a spallate.
@goto fine
:apri
dafne [neutral] R: Ho la matricola. Mi basta tenerla ferma.
:fine
cassaforte [angry] R: BLINDATURA. BLINDATURA.
""",
	"cassaforte_post": """
@bg caveau
*: La porta della cassaforte cede con un lungo gemito. Dentro, un solo fascicolo, con una sola riga. Dafne lo apre, lo legge in silenzio, lo richiude.
kira [neutral] L: Cosa dice?
dafne [neutral] R: Che mi chiamavo Dafne anche prima.
dax [surprised] L: ...Davvero?
dafne [happy] R: Davvero. Me l'avevano lasciato. Per non farmi dimenticare chi ero.
elle [happy] L: Allora l'uomo con la voce gentile non era del tutto cattivo.
dafne [sad] R: No. Era solo quello che gli serviva. Ma in fondo al fascicolo c'e' un'altra frase. Scritta a mano.
eco [neutral] R: Dice qualcosa?
dafne [neutral] R: 'Cercami al faro. Marta.'
dax [surprised] R: Marta!
*: Sulla mappa, il faro del porto vecchio si accende. Non c'e' nessuno ad accenderlo.
""",
	"faro_pre": """
@bg faro
*: Il faro del porto vecchio. Il fascio gira, ma invece di indicare il mare indica la citta'. Ogni giro, un quartiere si spegne.
dax [sad] L: Sono passati nove anni. Marta mi aspettava qui, nel suo turno di notte. E io non sono mai salito.
dafne [neutral] R: Nove anni di silenzio. E ora una frase scritta a mano.
elle [neutral] R: Se il faro e' un messaggio, e' un messaggio vero.
kira [neutral] L: Oppure e' un'esca. Un faro che attira le navi sugli scogli.
nico [neutral] R: Ho tenuto aperto un rifugio per sette mesi con la porta socchiusa. So come si aspetta qualcuno. E come si smette.
eco [sad] R: Dax. Hai paura?
dax [neutral] L: Si'. Ma salgo. Se Marta e' li in cima, non la faccio aspettare un'altra notte.
faro [angry] R: FASCIO. FASCIO. NESSUNA NAVE ARRIVA IN PORTO.
dafne [angry] R: Per questo ho un fucile. Marchio e colpo. Sergente, vai.
""",
	"faro_post": """
@bg faro
*: Il fascio si spegne. Sul parapetto, nel vento, una sagoma: una donna in divisa LibraCorp, con un telefono in mano. Dax si ferma.
*: MARTA - "Dax. Hai portato la squadra. Sempre il solito."
dax [surprised] L: Marta?
*: Non e' lei. E' un'immagine, una proiezione fatta di luce e voce. Ma e' abbastanza vera da far male.
*: MARTA - "Non ho molto tempo. Sono nel Registro. Mi hanno tenuta come voce. Una voce che risponde ai telefoni che nessuno ricorda."
dax [sad] L: Dov'e' l'ingresso?
*: MARTA - "Sotto il molo. Ma dietro l'ultima porta c'e' qualcosa di piu' grande di me. Qualcosa che ha preso i vostri sette minuti."
dafne [neutral] R: Il Progetto Kairos.
*: MARTA - "Si chiama Eclissi. E il Registro la sta alimentando."
*: La proiezione si sfalda. Resta solo il suono del mare.
""",
	"registro_pre": """
@bg archivio
*: Il Registro. Sotto il molo, corridoi di cassetti metallici, tutti identici, tutti etichettati. Migliaia di nomi. Nessuna luce.
dafne [neutral] R: Qui finisce chi viene cancellato. Non solo nel registro. Nella vita.
elle [sad] L: Tutti questi cassetti... sono persone?
nico [sad] R: Sono ricordi di persone. E i ricordi, quando nessuno li reclama, diventano ruggine.
kira [angry] L: Qualcuno li ha messi qui. Qualcuno ha deciso cosa vale la pena ricordare.
registro [neutral] R: ARCHIVIAZIONE IN CORSO. TUTTI I PRESENTI SARANNO SCHEDATI.
eco [surprised] R: Ha scritto il mio nome! E anche quello di Dax! E quello di Marta!
dax [angry] L: Marta e' qui. In questo cassetto. La sento.
dafne [neutral] R: Allora lo apriamo. Insieme. Squadra CAM, formazione.
registro [angry] R: CANCELLAZIONE. CANCELLAZIONE.
""",
	"registro_post": """
@bg archivio
*: I cassetti si aprono tutti insieme, come un grande respiro. Dalle serrature escono lucciole di luce: ricordi, nomi, voci che tornano nel mondo.
*: MARTA - "Dax. Siete venuti davvero. Ti ho aspettato nove anni."
dax [sad] L: Mi dispiace. Non ho sentito il telefono.
*: MARTA - "Lo so. Non e' mai stata colpa tua. Ho solo voluto che lo sapessi da me."
elle [happy] L: Benvenuta, Marta. Ho del te'. E una sciarpa.
*: MARTA - "...Siete in sei, adesso?"
eco [happy] R: Sette! Con te! E mezza contando me.
dafne [neutral] R: Il Consiglio sa che sono qui. Il Registro e' solo l'anticamera. Oltre c'e' Eclissi.
*: MARTA - "Si'. Il sole nero. Prende ogni minuto dimenticato e lo trasforma in oscurita'."
kira [neutral] L: Allora facciamo l'unica cosa che sappiamo fare. Ricordare, tutti insieme.
*: Sulla mappa, in cima ai tetti, una luce nera. CAM-ZERO.
""",
	"eclissi_pre": """
@bg eclissi
*: CAM-ZERO. La terrazza della torre dell'orologio, ore piccole. Sopra, il cielo e' scuro come l'inchiostro. Al centro, un disco nero con una corona bianca.
dafne [neutral] R: Eclissi. Il sole nero. Il Consiglio lo ha chiamato 'minuto zero'. Ogni ora cancellata, ogni nome perso, finisce qui.
*: MARTA - "E dentro, intrappolati, tutti quelli che LibraCorp non voleva ricordare. Anche i genitori di Dafne."
dafne [surprised] R: ...I miei?
*: MARTA - "Mi dispiace. L'avrei voluto dire in un posto migliore."
dafne [sad] R: Ho passato la vita a pensare di non avere nessuno.
elle [happy] L: Ora hai cinque amici, una collega di Dax e un'anomalia che dice sempre la verita'.
eco [happy] R: Sempre. E ti voglio bene.
dafne [happy] R: ...Anch'io. Non l'ho mai detto a nessuno. Spero di farlo bene.
> Combattiamo per liberarli -> libera
> Chiediamo prima a Eclissi che cosa vuole -> parla
:libera
kira [angry] L: Tutti insieme. Nessuno resta indietro.
@goto fine
:parla
nico [neutral] R: Non c'e' niente da chiedere a un'eclissi. Si aspetta che finisca. O si fa finire.
:fine
eclissi [angry] R: ORA NERA. NESSUNO RICORDERA' NESSUNO.
dafne [angry] R: Io ricordero'. Anche da sola. Ma non sono sola. Fuoco.
""",
	"eclissi_post": """
@bg eclissi
*: Il disco nero si incrina da parte a parte. La corona si spegne. Dal buio escono migliaia di luci, una per ogni nome. Salgono verso il cielo e tornano a essere stelle.
dafne [sad] R: Sono loro. I miei. Li vedo. Mi sorridono.
*: MARTA - "Ti hanno sempre cercata, Dafne."
dax [happy] L: Marta, andiamo a casa. Ti offro il caffe' peggiore di tutta la citta'.
*: MARTA - "Il tuo caffe' e' sempre stato il peggiore. Mi e' mancato."
bruno [happy] R: Squadra, qui Bruno. Il Consiglio LibraCorp ha appena sospeso il Registro. Dicono 'per verifiche'. Io dico 'per vergogna'.
nico [happy] R: Il rifugio e' di nuovo aperto. C'e' posto per tutti. Anche per LibraCorp.
elle [happy] L: Ho preparato il te'. Anche per i fucili.
dafne [happy] R: Rapporto finale. Agent 02 consegna le dimissioni dal Consiglio. E chiede di restare in squadra. Senza un grado, senza un debito.
kira [happy] L: Accettata. Benvenuta, Dafne, della squadra CAM.
eco [happy] R: Sette e mezzo! Per sempre!
*: Sul tetto della torre, all'alba, otto sagome guardano la citta' accendersi. E per la prima volta nessuna luce e' di troppo.
*: FINE DELLA SECONDA STAGIONE.
""",
}
