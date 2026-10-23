# Novità

## 0.33.2 · kit dei personaggi, battute più secche, aggiornare è più semplice
- **Ogni personaggio combatte a modo suo** (kit presi da archetipo, oggetto e fazione). Lance protegge: Copertura prende il colpo diretto a un compagno, il Braccio della Legge spezza l'equilibrio. Saul sfrutta l'occasione: Testa o croce (testa critico, croce energia a un compagno) e Il colpo grosso, che ruba lo scudo del nemico. Rio fa spettacolo: Inquadratura e Gran finale crescono con l'Hype. Nox evita la fatica inutile: Pausa caffè cura chi serve o la fa riposare, Rispondo io rialza un compagno KO. Ognuno ha anche un tratto passivo, scritto in battaglia.
- **Effetti visivi nuovi**: pennellate di luce del colore di chi colpisce su Abilità e Ultimate, scintille d'impatto, un cerchio di luce sotto chi è di turno e due fotogrammi al buio prima dell'Ultimate. La cupola magenta resta in cielo per tutto l'atto, le esplorazioni si vedono dal mirino delle telecamere di Echo (dentro le Anomalie «NESSUN SEGNALE») e la maschera di Rio resta incrinata dal capitolo 3 in poi.
- Battute delle Ultimate di Saul e Nox scelte dall'autore, e nuove battute dell'autore nei dialoghi (lo «sbirro magico», Saul e la radio di Astrid, il rifugio).
- Tutti i dialoghi e le chiacchiere riscritti con le regole dell'autore: niente spiegazioni, botta e risposta secchi, ogni battuta fedele al personaggio. Esempi: «C'è una cupola sopra la città e tu pensi ancora alle strisce pedonali?» «Sì.»; «Ma sul pacco c'era scritto "Documenti!".» «Ma che razza di documenti porti in giro?!»
- Indizi più asciutti («Uno scontrino per terra. Prezzo: un'anima. Non dà resto VIOLA.»).
- **Avviso di aggiornamento**: all'avvio il menu controlla su itch.io se c'è una versione nuova. Se c'è, compare il pulsante verde «AGGIORNA ALLA …» che apre la pagina del gioco. Su Android la nuova versione si installa sopra la vecchia, senza disinstallare.
- Le scelte nei dialoghi non si sommano più rigiocando una scena (prima, alla seconda volta, partivano entrambi i rami).
- La vittoria si salva appena compare il pannello: chiudere il gioco lì non fa più rigiocare la battaglia.
- Il tasto indietro chiude prima Capitoli e Impostazioni, poi esce.
- Dissolvenze e lampi non rallentano più quando la battaglia è a velocità diversa.
- Esplorazione: la pausa si apre anche con un dito già sul joystick, e la telecamera non resta «agganciata» dopo un dialogo.
- Leggibilità sul telefono: testi di battaglia, pausa, riassunti e titoli più grandi; pulsanti spenti leggibili; sulle carte c'è scritto il colore di ognuno (RIO · VIOLA); i compagni troppo vicini alla telecamera si nascondono invece di coprire la scena; schermata finale centrata.

## 0.33.1 · Guardia a tempo e battaglie più veloci
- **Guardia a tempo** (idea approvata dall'autore, da Expedition 33): quando parte il colpo annunciato del nemico compare un cerchio. Tocca lo schermo al momento giusto per incassare meno danno e caricare l'Ultimate; con il tocco perfetto contrattacchi.
- Pause più brevi tra un'azione e l'altra: si guarda meno e si agisce di più.

## 0.33.0 · revisione con la bibbia di lavoro, climax al loro posto
Revisione di tutto il gioco con la bibbia di lavoro (`BIBBIA_DI_LAVORO.md`) e le decisioni dell'autore del 19/10.
- Finale: quando Echo spegne la città per farli scappare non torna come prima. Si riaccende nel telefono di Rio ma di lei resta solo il nucleo, un puntino di luce: per riaverla servono pezzi (telecamere rotte, circuiti) e i frammenti delle Anomalie. È il piccolo sacrificio deciso dall'autore e l'aggancio per il seguito.
- Varco più corto (da 49 a 36 battute): via le ripetizioni, restano il tradimento di ognuno e il salvataggio di Rio. «Le promesse erano false. Questa no.» ora arriva solo al casello, dove pesa di più.
- Riprendendo una partita a metà area si torna dove si era, con gli indizi trovati e i nemici battuti (prima si ripartiva dall'inizio dell'area e gli indizi andavano persi). Il salvataggio scatta su ogni indizio, prima di ogni battaglia, uscendo dal menu e quando il telefono mette l'app in pausa.
- L'avviso del boss segreto (l'Osservatore) nomina chi verrà colpito davvero: la telecamera colpisce in base alla vita del momento, non il bersaglio estratto a inizio turno.
- Tipografia scelta dall'autore: dialoghi e chiacchiere in Merriweather, nomi e titolo in Libre Caslon. Testi più leggibili sul telefono.
- La cupola è magenta (#E83DCE), il colore della magia nella palette dell'IP.
- Fluidità: gli shader del gioco si preparano nel menu. Prima il telefono li compilava al primo colpo, al primo bagliore e alla prima telecamera incrinata, con uno scatto proprio nei momenti forti. Lo shader della telecamera rotta non si ricompila più a ogni battaglia.
- Tolti i pezzi rimasti della direzione medievale scartata (elmo, grata, mantello) dal costruttore dei personaggi.
- Nuovo `tools/v3_prestazioni.gd`: misura chiamate di disegno, primitive, nodi e caricamento di ogni area e arena.
- Chiave di firma Android nuova (la vecchia è andata persa): chi ha la 0.32.0 deve disinstallarla una volta prima di installare questa.
- Capitolo 3: la maschera di Rio si incrina invece di cadere. Da lì si vede un occhio; Rio non è ancora pronto a toglierla e nessuno insiste. Toglierla sarà il climax del suo arco.
- Varco: Lance usa il braccio per salvare Rio, ma Echo inceppa le telecamere della piazza e il braccio lo vede solo il gruppo. Astrid non lo classifica come Anomalia davanti al paese. Mostrarlo a tutti sarà il climax dell'arco di Lance.
- Capitolo 5 allineato: sul cartellone dei ricercati Lance è «Disertore», non «Anomalia».
- Menu pausa nuovo: la riunione d'emergenza. I quattro si stringono in cerchio e sussurrano mentre il mondo resta fermo, ripresi da una telecamera di Echo. Ogni voce ha il suo padrone (Lance riparte, Nox abbassa il volume, Saul conosce un'uscita) e alla ripresa qualcuno rovina il piano.
- Saul e Rio combattono in modo diverso. Saul, veterano: Colpo basso (sfonda la difesa) e Colpo di fortuna (critico quasi sicuro). Rio, showman: In diretta (marca il nemico e carica i compagni) e Gran finale (tre colpi e tutta la squadra più forte).
- Voci rifinite: Saul parla come un negoziatore (mezze verità, il conto con gli interessi), Rio come un presentatore davanti a un pubblico che non c'è. Lance e Saul sono i veterani che chiudono i combattimenti senza sforzo.
- Gag da fuggitivi che tornano lungo l'atto: il distributore, il divano del rifugio, la batteria di Rio, l'orologio di Lance, il thermos di Nox, i travestimenti, i nomi falsi e il pasto da cinque minuti. Dodici chiacchiere nuove.

## 0.32.0 · la storia riscritta e il capitolo 5
- Nomi nuovi: Ferri ora è **Lance**, Zecca ora è **Rio**. Il Kairos si chiama **Echo**. La comandante di LibraCorp è **Astrid**, il capoturno di Nox è **Strix**.
- Apertura nuova: la racconta Echo dalle telecamere. Presenta i quattro, spiega perché ognuno è in piazza alle tre di notte, poi cala la cupola e gli schermi li accusano. Si capisce subito cosa succede e perché scappano insieme.
- Echo è un personaggio vero: ha un ritratto e parla durante le esplorazioni. Fa a ognuno una promessa su misura (il grado a Lance, le ferie a Nox, la live dell'anno a Rio, le taglie a Saul), ed è per questo che si fidano di lei.
- Il tradimento nel varco: non le servivano quattro fazioni, le servivano quattro persone compromesse che nessuno avrebbe creduto. Ogni promessa crolla davanti a chi l'aveva ricevuta. Poi la cupola viene giù e Lance usa il braccio davanti a tutte le telecamere del paese per salvare Rio.
- Tutti i dialoghi riscritti, circa 500 battute e 80 chiacchiere. Voci più distinte: Saul calmo, mai un punto esclamativo, dà un prezzo a tutto e cita nonne inventate; Rio veloce, sincero, con i titoli dei video e i suoi 32 follower. Il gruppo passa dalla diffidenza alla fiducia, poi rischia la vita l'uno per l'altro (Saul tiene aperta la porta blindata per Rio) e diventa una famiglia.
- Nuova vigilia prima del varco e una serata nuova Nox-Echo.
- **Capitolo 5 · La tangenziale**, subito dopo la caduta della cupola: la tangenziale all'alba, il cartellone dei ricercati, Astrid e Strix al casello e un boss nuovo, l'**Autovelox** (teme il viola). Echo spegne la città per farli scappare.
- Durante i dialoghi le chiacchiere non si sovrappongono più ai ritratti.

## 0.31.2 · correzioni
- Niente più blocchi sul cartello dei capitoli: toccandolo mentre lo schermo schiariva la storia andava avanti ma la schermata restava ferma. E ora il tocco sul cartello funziona davvero (prima si andava avanti solo aspettando).
- La pausa ferma tutto: in esplorazione i frammenti stanno fermi e non possono farti un agguato col menu aperto; E/F non agiscono dietro il menu. In battaglia con la pausa aperta i tasti 1-4, Spazio, AUTO e x2 non fanno partire niente.
- Tornando in un'area dopo una battaglia ci sono 2,5 secondi senza agguati.
- Articoli giusti nei nomi dei nemici («l'Osservatore», «la Cabina è stordita», «attacca per prima»).
- Un dialogo senza testo non blocca più il gioco. Salvataggio letto in modo sicuro anche se rovinato.
- CAPITOLI chiede conferma (secondo tocco) se c'è una partita avviata, perché il salto sovrascrive i progressi.
- I test e il giro automatico di prova usano un salvataggio a parte: non toccano più quello vero.

## 0.31.1 · personaggi moderni, telecamera rotta leggibile, prestazioni
- Personaggi di nuovo urbani e di oggi (il look medievale è bocciato): Ferri in divisa tattica LibraCorp col manganello elettrico, Nox col cappotto lungo delle Civette e il caffè, Zecca con la felpa oversize viola, maschera e sneakers, Saul col bomber verde, cargo, tracolla e il pacco. Ritratti rifatti.
- Tolte le cornici gotiche da menu, dialoghi, cartelli e ultimate.
- Telecamera rotta rifatta:
  - si rompe nel momento esatto del colpo, quando un nemico fa scendere un personaggio sotto il 50% o sotto il 25%;
  - anche quando la squadra manda il nemico in ROTTURA (barra bianca a 0) c'è l'animazione, poi lo schermo torna pulito;
  - sul turno di un personaggio ferito restano crepe sottili, con il centro dello schermo quasi pulito: si legge tutto.
- Prestazioni:
  - il 3D si disegna a risoluzione ridotta (circa 720 righe su telefono, 1080 su PC), l'interfaccia resta nitida;
  - i manichini della galleria si disegnano tutti insieme (da 187 a 113 chiamate di disegno);
  - via la mazza con la catena (11 pezzi mossi a ogni fotogramma), meno carte attorno a Saul.

## 0.31.0 · nuovo stile visivo
- Il gioco segue lo stile deciso dall'autore (docs/STILE_VISIVO.md): silhouette esagerate alla Kingdom Hearts con la resa dei primi Final Fantasy, classi RPG sopra vestiti di oggi.
- Ferri è il cavaliere del disegno dell'autore: elmo d'argento con alette e grata, capelli verdi, armatura a bande, stivaloni con spuntoni dorati, mantello rosso, mazza ferrata enorme su catena e la mascotte con gli occhi.
- Zecca giullare (cappello coi sonagli, scacchi, maschera, sneakers enormi), Saul ladro e giocatore d'azzardo (carte che volano, amuleti), Nox guardiana notturna. Questi tre sono PROVVISORI.
- Per tutti: mani e piedi enormi, busto e gambe sottili, metallo lucido a bande, una sola tinta forte (il colore di battaglia) su base spenta.
- Pose diagonali in battaglia, mai rigidi di fronte.
- Cornici gotiche in filigrana d'argento: menu, dialoghi, cartelli, fine dell'atto e sequenza dell'ultimate.
- Ritratti dei dialoghi rifatti dai nuovi segnaposto. Restano provvisori, in attesa dei modelli della pipeline (TRELLIS.2 + Mixamo).

## 0.30.1 · telecamera rotta
- La battaglia è vista dalle telecamere: quando tocca a un personaggio con pochi PV la sua telecamera si rompe. Sotto il 50% è incrinata, sotto il 25% è in frantumi, con schegge spostate e il nemico che si vede doppio. Quando tocca a chi sta bene, la telecamera torna pulita.
- Ogni personaggio ha la sua telecamera, quindi il suo disegno di crepe. Comandi e barre restano sempre integri.
- Nelle impostazioni: «Telecamera rotta (PV bassi)» per spegnerla. Con effetti ridotti è più leggera, con i lampi spenti non tremola.
- Boss segreto di prova in fondo alla strada del prologo, oltre il distributore: L'Osservatore. Prima chiede se sei sicuro. Porta i personaggi esattamente al 50% e al 25% ignorando scudi e difesa e non uccide mai. Si può rifare quante volte si vuole.

## 0.30.0 · atto 1 completo
- Tutto l'atto 1 giocabile: prologo, quattro capitoli e il finale (Il varco). Circa un'ora di gioco.
- Sei aree da esplorare: la strada, l'Incrocio Nove, il Vicolo delle Civette, la Galleria Lumière, il caveau LibraCorp e tre «interni» delle Anomalie (rosso, blu, verde).
- Cinque boss (Distributore, Semaforo, Cabina, Manichino, Cassaforte) e frammenti d'Anomalia minori che girano per le aree: colpiscili prima che ti tocchino.
- Gli indizi trovati rivelano la debolezza del boss.
- La squadra chiacchiera mentre cammini: fumetti con la faccina, non fermano il gioco.
- Serate al rifugio: scegli chi passa la sera insieme, nasce un legame (+5% attacco alla coppia in battaglia).
- Scelte nei dialoghi (fidarsi del Kairos, la telefonata a Saul) ricordate fino alla fine.
- Salvataggio automatico a ogni passo: CONTINUA dal menu. CAPITOLI per saltare a un capitolo.
- Le voci di due inseguitori (LibraCorp e Civette) preparano il seguito.

## 0.29.2 · cutscene stile Persona
- Dialoghi alla Persona 5: ritratti grandi che entrano di lato, chi ascolta si scurisce, l'espressione cambia a ogni battuta.
- Si parte col botto: la cupola cala sulla città e i quattro si ritrovano in piazza. Poi «Tre ore prima».
- Saul commenta mentre cammini. Due cose da scoprire in strada: una telecamera e un indizio sul distributore.
- Attacco a sorpresa: colpisci il distributore prima che si svegli e parti in vantaggio. Se resti fermo davanti a lui, attacca per primo.
- Se salti un dialogo compare un riassunto. Nelle impostazioni si può spegnere l'attacco a sorpresa per confrontare.
- I ritratti sono provvisori, fatti dai personaggi 3D: verranno sostituiti da quelli disegnati.

## 0.29.1 · personaggi in stile anime
- I quattro protagonisti rifatti in stile anime semplificato: forme morbide, viso a V con occhi anime, capelli a ciocche, contorno pulito.
- Ombre calde sulla pelle, viso senza ombre dure. Ancora segnaposto fatti da codice, in attesa dei modelli veri.

## 0.29.0 · test sul telefono
- Prima prova della V3 in 3D: una strada notturna, Saul in terza persona con la camera alle spalle, un dialogo e un mini combattimento a turni contro il Distributore con i quattro protagonisti.
- Comandi touch (stick, trascina per la camera, tasto azione) e PC (WASD, mouse o Q/R, E).
- Impostazioni: scosse, lampi, sequenza ultimate, effetti ridotti, vibrazione, contatore FPS.
- Se il gioco si chiude da solo, al riavvio il menu dice in che punto era.
