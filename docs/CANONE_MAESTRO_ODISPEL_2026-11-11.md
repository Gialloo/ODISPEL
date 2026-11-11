# ODISPEL — Canone maestro, decisioni e handoff di progetto
**Versione documento:** 1.0  
**Data di consolidamento:** 11 novembre 2026  
**Repository:** `Gialloo/ODISPEL`  
**Branch di riferimento del codice storico:** `claude/v3-prologo`  
**Branch di questo documento:** `docs/odispel-master-canon-2026-11-11`

---

## 0. Scopo, gerarchia delle fonti e avvertenza

Questo documento consolida le decisioni ODISPEL recuperabili dalle conversazioni e dal contesto di progetto disponibili fino all'11 novembre 2026. È destinato a essere il riferimento di continuità per progettazione narrativa, game design e futura implementazione.

**Non è una trascrizione letterale di ogni chat.** Riordina le decisioni, conserva i vincoli e segnala le questioni aperte. Alcuni dettagli delle conversazioni più vecchie possono non essere recuperabili parola per parola: non vanno inventati per colmare i vuoti.

### Gerarchia da rispettare
1. Le decisioni più recenti confermate dall'autore prevalgono sulle iterazioni precedenti.
2. Il canone narrativo e la demo in progettazione nelle conversazioni attuali sono il riferimento creativo.
3. Il repository Git contiene prototipi e iterazioni tecniche/narrative precedenti: è una **riserva di codice, sistemi, scene e risorse riutilizzabili**, non la fonte autoritativa del canone attuale.
4. Le proposte dell'assistente non approvate non sono decisioni.
5. Gli elementi indicati come provvisori, futuri o aperti non devono essere implementati come se fossero definitivi.

### Regola fondamentale
**Non adattare la nuova storia alla vecchia demo. Riallineare il progetto alla nuova storia.** Conservare ciò che funziona tecnicamente; sostituire o rifare ciò che contraddice il canone attuale.

---

# PARTE I — IDENTITÀ E DIREZIONE DEL PROGETTO

## 1. Visione di ODISPEL

ODISPEL è un IP originale con ambizione internazionale, che può vivere attraverso manga, videogioco e contenuti/community. Il tono e il posizionamento cercano un equilibrio tra:
- energia, mistero e intensità da battle shonen;
- personaggi con difetti, rapporti e crescita emotiva;
- un mondo ricco di fenomeni, folklore, anomalie e segreti;
- una community che possa discutere teorie, reperti, dettagli e interpretazioni.

Riferimenti di sensibilità/mercato citati dall'autore: **Jujutsu Kaisen, Chainsaw Man, One Piece, Persona 5, Homestuck** e, per il formato episodico del gioco, **DELTARUNE**. Sono riferimenti di effetto e struttura, non modelli da copiare.

Formula di posizionamento discussa: identità visiva/branding forte, aura promozionale intensa, UI memorabile, mistero virale e cultura da fandom/community. La formula descrittiva usata dall'autore è: «Bleach branding + Chainsaw Man aura marketing + Persona UI + analog horror virality + streetwear drops + indie animation hype».

**Vincolo visivo:** il manga principale non deve avere un aspetto “AI glossy 3D”. L'autore è forte nel disegno 2D e lavora con iPad, Apple Pencil Pro e Procreate.

## 2. Obiettivi economici e produttivi

- Progetto senza budget significativo e senza studio già costituito.
- L'autore lavora da solo e non è uno sviluppatore professionista: la sostenibilità è un requisito di design, non un dettaglio successivo.
- Obiettivo economico attuale discusso per la società/progetto: circa **3.000–3.500 € netti al mese**, con capitale e utili trattenuti nell'azienda per finanziare il gioco successivo. Questo obiettivo ha sostituito obiettivi economici precedenti più ambiziosi.
- Strategia esplorata: costruire pubblico e interesse prima del lancio; valutare finanziamento e Kickstarter; distribuzione digitale e pubblicazione autonoma; possibili canali manga/Webtoon, Patreon, Gumroad e stampa premium.
- Pubblico internazionale; l'inglese come lingua di accesso al mercato è stato considerato accettabile.
- Marketing social: Instagram/TikTok e worldbuilding prima e durante la pubblicazione.

### Regola di produzione non negoziabile
**Massimo impatto narrativo e ludico con il minimo contenuto proprietario da produrre.**

Conseguenze pratiche:
- niente cinematiche dedicate costose se la stessa informazione può essere comunicata con gameplay, dialoghi, animazioni, camera, effetti e transizioni già disponibili;
- preferire dialoghi contestuali, comportamenti, reazioni e regia in-engine;
- riutilizzare ambienti, sistemi, animazioni e strumenti con variazioni intelligenti;
- eventi unici soltanto quando il loro valore narrativo giustifica il costo;
- evitare di creare due volte lo stesso contenuto tra demo e Capitolo 1;
- non aggiungere sistemi per il solo gusto di aggiungere funzionalità;
- ogni nuova idea va valutata per impatto sul giocatore, costo di sviluppo, manutenzione e compatibilità con un team di una persona.

La limitazione di budget non deve cancellare l'identità di ODISPEL: deve guidare il modo in cui la si realizza.

## 3. Formato narrativo e progressione generale

- Il gioco è pensato in forma **episodica**, con capitoli sviluppati con cura nel tempo, ispirazione strutturale da DELTARUNE.
- Il manga, se sviluppato in parallelo, dovrebbe contenere gli archi dei protagonisti entro un ordine di grandezza di **200–250 capitoli al massimo**.
- Come riferimento di progressione D&D per il party: livello 6 all'inizio della storia e livello 16 alla fine degli archi considerati.
- La demo attuale è una nuova esperienza introduttiva e non va confusa con le vecchie versioni/prologhi presenti nel repository.

---

# PARTE II — MONDO E LORE

## 4. Cosmologia e ambientazione

Il mondo di ODISPEL comprende:
- **Terra contemporanea**;
- **Inferi**, piano inferiore;
- un piano superiore associato a spiriti e angeli.

Il mondo moderno viene attraversato da fenomeni soprannaturali, creature e alterazioni ambientali. Il folklore e la conoscenza del mondo devono emergere attraverso personaggi, testimonianze, contraddizioni, reperti e conseguenze, non tramite spiegoni onniscienti.

Concetto/tema espresso dall'autore: **«Chaos is inevitable; what defines you is how you move through it.»**

Il combattimento e la crescita non sono soltanto strumenti di sopravvivenza: nella cultura degli Odispeller, combattere può essere arte, ricerca e crescita. Alcuni termini e concetti di lore sono stati discussi (Forza Odica, Monadi, Traccia, Odispeller, Magabondo, Physikai, Kairikai, Void), ma il loro grado di definizione varia. Non trattare ogni termine emerso in brainstorming come canonico senza una decisione esplicita.

## 5. Kairos e nidi

I **Kairos** sono creature/entità capaci di alterare l'ambiente e la città in modi bizzarri. Non sono soltanto nemici da combattimento: hanno comportamenti, biologia, tracce, materiali e strutture.

Decisioni di worldbuilding:
- Ogni zona/quartiere può avere un **nido Kairos**.
- Il nido genera/ospita Kairos e modifica la zona in modo caratteristico.
- I nidi sono protetti da mostri élite e da un boss.
- Il dungeon è la tana del boss e del nido.
- Le mutazioni possono essere architettonicamente impossibili o sorprendenti: per esempio, una caverna può comparire all'interno di un edificio che prima non ne aveva una.
- Le indagini sulle anomalie minori possono avere un tono da dossier/caso anomalo, con ispirazione generale SCP, ma senza trasformare ogni incontro in un boss.

Il quartiere trasformato della demo dovrà essere una piccola area esplorabile liberamente, con mutazioni leggibili e qualche segreto, non una città enorme.

## 6. Masca

Le **Masca** sono maschere che possono essere ricevute in circostanze misteriose e conferire poteri attraverso un legame con un Kairos. Gli esiti possibili non sono uniformi:
- il Kairos può prendere il controllo della volontà/del corpo;
- la maschera può diventare impossibile da rimuovere e il portatore può perdere la precedente identità;
- in altri casi il portatore può mantenere il controllo e riuscire a rimuoverla volontariamente.

Non spiegare tutto al giocatore all'inizio. La demo deve lasciare spazio a curiosità e domande prima di fornire definizioni.

---

# PARTE III — PROTAGONISTI

## 7. I quattro protagonisti e la loro convivenza

La demo presenta quattro persone/individui che non si conoscono e che devono imparare a convivere. La direzione confermata è:
**sconosciuti → collaborazione forzata → diffidenza → abitudine → primi legami → appartenenza.**

Non devono diventare immediatamente una famiglia o un gruppo affiatato. La chimica nasce da attriti, comportamenti, piccoli gesti, incomprensioni e rispetto graduale dei confini.

La città e i pericoli li costringono a collaborare, ma le loro obiezioni e differenze non devono impedire arbitrariamente al giocatore di proseguire.

## 8. Lance

Ruolo/identità:
- figura disciplinata, esperta, metodica e con mentalità militare;
- tende a valutare pericoli, coperture, vie di fuga e vantaggi tattici;
- assume spesso la responsabilità della sicurezza del gruppo;
- non deve parlare sempre come un regolamento militare: il controllo è una tendenza, non una battuta ripetuta.

Rapporto con Rio:
- inizialmente considera Rio una creatura imprevedibile e non addestrata, paragonabile a un puma/leone non addestrato;
- inizialmente avrebbe voluto sterminarlo, perché lo considera potenzialmente pericoloso;
- il suo percorso consiste anche nell'imparare a conviverci e a distinguere il comportamento animale/istintivo dalla minaccia deliberata.

Esplorazione: specializzazione militare/ricognitiva. Quando guida il gruppo può notare e commentare:
- posizioni tattiche, coperture e vie di fuga;
- possibili imboscate e pattugliamenti;
- tracce di combattimento;
- depositi militari, munizioni, armi ed equipaggiamento.

## 9. Nox

Ruolo/identità:
- curiosa, competente nello studio e nell'analisi dei fenomeni;
- ha un approccio scientifico/accademico alle anomalie e alla magia;
- può essere trascinata nel caos dagli altri e reagire con temperamento: non deve essere sempre cinica, stanca o sarcastica;
- la sua curiosità non elimina la necessità di rispettare i confini degli altri.

Rapporto con Rio:
- cerca di comprenderne comportamenti e natura;
- anche lei deve imparare a rispettare distanze e comportamenti, soprattutto quando Rio è vulnerabile o sta nidificando;
- Rio può accettarla se rispetta tali regole.

Esplorazione: specializzazione magica. Quando guida il gruppo può notare e commentare:
- oggetti magici e artefatti;
- concentrazioni di Forza Odica;
- anomalie, materiali e fenomeni soprannaturali;
- tracce di rituali o manipolazioni magiche.

## 10. Saul

Ruolo/identità:
- opportunista, indipendente, scaltro e abile nel trasformare equivoci e reputazione in vantaggi;
- esperienza di strada, trucchi, prestidigitazione/illusionismo e capacità di leggere le persone e l'ambiente;
- non deve ridurre ogni conversazione a un affare o ogni comportamento al denaro;
- è il guastafeste che spesso rompe il silenzio e provoca reazioni, ma non è soltanto una macchietta comica.

Relazioni e comportamento:
- Saul può aiutare gli altri in modi differenti, in base alla persona e al rapporto; non è stato fissato un limite morale non negoziabile definitivo.
- Gli piace preparare scherzi elaborati e godersi sia la preparazione sia le reazioni.
- Preferisce non essere riconosciuto subito come autore dello scherzo, ma **vuole essere scoperto**: gli altri devono ricostruire gli indizi e arrivarci autonomamente.
- Inizialmente considera Rio una “bestiaccia” e lo chiama in modo improprio (“mostri”/“demoni”), perché non possiede la conoscenza accademica di Nox né quella militare di Lance: sa soltanto che sono creature che danno fastidio e mordono.
- Saul e Rio devono imparare a convivere. Quando Rio nidifica, Saul può interpretare male un comportamento giocoso, essere attaccato e reagire con rancore.

Esplorazione: specializzazione in ricchezze. Quando guida il gruppo può notare e commentare:
- denaro, bottini, tesori e oggetti di valore;
- nascondigli, contrabbando, cimeli e oggetti curiosi;
- dettagli sospetti e meccanismi che una persona esperta di strada/prestigiatore riconoscerebbe.

Poteri futuri: le mani spirituali/magiche di Saul sono state sviluppate in una discussione successiva. Sono stati accettati tre aspetti: appendici fisiche, manifestazioni autonome capaci di agire/lanciare effetti e strumenti/catalizzatori magici. **Non possiede ancora queste mani nella fase iniziale della demo.** Non attribuirgli tali poteri nella prima ricognizione.

Futuro/fato:
- il destino di Saul con gli altri ha un finale aperto;
- una probabilità di sopravvivenza dello 0,1% è stata citata come ipotesi, non come dato canonico definitivo;
- se sopravvive, rimane rigorosamente solitario per un periodo;
- non li contatta direttamente: potrebbe restare un benefattore misterioso, osservarli da lontano e fare scherzi.

## 11. Rio

Origine:
- Rio era un essere umano, studente all'ultimo anno delle superiori.
- Prima della fusione era solare, chiacchierone e iperattivo; desiderava diventare famoso e provava a riuscirci attraverso editing, doppiaggio, riprese, fotografia e streaming, senza successo.
- Una notte riceve una Masca che contiene/porta un Kairos.
- Il Kairos associato era inizialmente debole; la fusione/assorbimento è avvenuta casualmente e ha creato un ibrido molto potente. Non è una coppia predestinata o scelta.
- La condizione dell'umanità originaria di Rio è simile a un sogno/ coma: non è stabilito se sia cosciente, cosa percepisca o se veda qualcosa. Non inventare una risposta.

Comportamento attuale:
- l'ibrido è più taciturno rispetto al Rio umano;
- comunica spesso con termini e meme del linguaggio social moderno, per esempio “Follow”, “Hype”, “Git Gud”, “Get Rekt”, “K”, “Kappa”, “Rip”, “LOL”, “lmao”;
- ha una componente predatoria/istintiva ma anche spontanea, curiosa e capace di giocare;
- non è sempre un presentatore/streamer: il suo passato spiega alcuni riferimenti, non deve dominare ogni scena;
- usa una mazza da baseball nel concept di combattimento già discusso;
- la sua biologia è adattiva: modello di evoluzione organica tipo Ben 10, ma **rimane Rio**, riconfigura e combina capacità, apprende e può sviluppare nuove abilità autonomamente.

Nidificazione:
- quando costruisce un nido è vulnerabile e lo difende;
- usa muco e tentacoli per proteggere il nido;
- chi si avvicina deve rispettare distanze e comportamenti;
- Nox può imparare a rispettarli e ottenere accettazione;
- fuori dal nido Rio è più spontaneo e curioso.

Rapporti:
- Lance lo vede inizialmente come creatura imprevedibile e potenzialmente da eliminare;
- Saul lo considera una bestiaccia/mostro e può provocare incomprensioni;
- Nox cerca di capirlo, ma deve rispettarne i confini.

Esplorazione: specializzazione Kairos/biologica. Quando guida il gruppo può notare e commentare:
- altri Kairos e loro tracce;
- odori, secrezioni e tracce biologiche;
- passaggi, resti e materiali organici;
- nidi e segni di attività Kairos.

---

# PARTE IV — ECHO E RELAZIONI

## 12. Echo

Echo è una presenza non umana legata ai dispositivi/camere e alla rete. All'inizio è soprattutto una presenza su telecamere e schermi, con possibilità di spostarsi tra telecamere/dispositivi connessi e raggiungibili. Il suo sviluppo previsto può passare da spirito a ibrido e poi a una forma autonoma; sono state discusse proiezioni intangibili e, più avanti, un corpo fisico temporaneo.

La sua origine profonda è collegata a un progetto di laboratorio:
- in realtà è umana e Kairos, legata al Project Indigo;
- il corpo è mancante;
- crede di essere un Kairos a causa di trauma e ricordi confusi;
- era stata usata come risorsa di tecnomanzia/sorveglianza;
- le visioni del laboratorio possono rivelare gradualmente il passato.

Caratterizzazione:
- buffa, frammentaria, curiosa e giocosa;
- capace anche di paura e cautela nei confronti di Lance e Saul;
- non deve essere ridotta a mascotte o gag;
- i suoi poteri hanno un costo/consumo: non sono gratuiti o illimitati;
- all'inizio è osservatrice/registratrice, legata a camere e schermi; non introdurre subito una proiezione umana se non previsto.

Relazione con Rio:
- la direzione è una complicità provocatoria e giocosa che può evolvere gradualmente;
- non iniziare con una relazione romantica già dichiarata;
- l'arco romantico Rio–Echo è previsto nel lungo periodo.

## 13. Altre dinamiche

- Lance tende ad assumersi responsabilità e Nox resiste al controllo: attrito quotidiano, non ostilità permanente.
- Saul rompe spesso il silenzio e ottiene reazioni da Nox e Lance; Rio può seguire la dinamica per riflesso.
- È prevista anche una possibile relazione Saul–Nox, da sviluppare gradualmente, senza forzarla o trasformarla subito in una coppia.
- Le relazioni devono emergere da gesti, battute, distanza, fiducia e conseguenze, non da barre numeriche o dichiarazioni esplicite.

---

# PARTE V — DEMO ATTUALE

## 14. Identità della demo

Questa è la demo che stiamo creando adesso. **Non è la vecchia demo descritta nei documenti Git.**

- Durata obiettivo approvata: **30–40 minuti**.
- Deve essere un'esperienza completa e introduttiva, capace di presentare i quattro protagonisti, il mondo e il tono.
- Il giocatore non deve conoscere già il glossario di ODISPEL, le Masca o la natura dei Kairos.
- L'introduzione deve usare gameplay e scoperta, non una lezione di lore.
- La demo deve poter essere realizzata da una persona senza budget per cinematiche dedicate.

### Distribuzione temporale provvisoria
È stata proposta una distribuzione indicativa (non una scaletta rigida):
- introduzione dei protagonisti: 8–10 minuti;
- cataclisma/incontro forzato: 5–7 minuti;
- collaborazione e pausa narrativa: 4–5 minuti;
- esplorazione del quartiere trasformato: 12–15 minuti;
- segreto finale e chiusura: 2–3 minuti.

Totale indicativo: circa 31–40 minuti. La sequenza precisa va ancora definita.

## 15. Apertura: Lance in ricognizione

Decisioni confermate:
- Il giocatore inizia direttamente con **Lance giocabile**.
- Lance è in ricognizione e sta indagando su un'anomalia.
- Non sta svolgendo un incarico ufficiale per Libra Corp.
- Ha notato personalmente stranezze nella zona e ha deciso di investigare per conto proprio.
- L'apertura deve mostrare le sue competenze militari attraverso azioni, osservazione e gameplay.
- Il giocatore impara movimento, telecamera e interazione mentre Lance osserva accessi, pericoli, coperture e tracce.

### Incontro con Rio
- Durante la ricognizione Lance incontra Rio.
- Rio sta rovistando tra i resti di un edificio, cercando qualcosa.
- Il suo comportamento appare minaccioso o inquietante a distanza, ma non è intenzionalmente aggressivo: è concentrato sulla propria scoperta.
- Rio ignora completamente Lance, troppo assorto in ciò che sta facendo.
- Lance interpreta Rio come la possibile anomalia che stava cercando.
- Il giocatore capisce l'equivoco: Lance sta valutando una minaccia, mentre Rio è semplicemente occupato e curioso.
- Lance non deve apparire stupido: interpreta una situazione ambigua con le informazioni limitate che possiede.

**Ancora aperto:** il modo preciso in cui Lance interrompe Rio (affronto diretto/intimazione oppure tentativo di sorprenderlo e immobilizzarlo) non è stato deciso in modo inequivocabile.

## 16. Incontro forzato e dinamica del party

Direzione confermata per la demo:
- i quattro non sono amici all'inizio;
- devono imparare a convivere e collaborare;
- diffidenza e obiezioni sono reali, ma non devono bloccare arbitrariamente la progressione del giocatore;
- la città trasformata diventa poi esplorabile liberamente in una piccola area;
- i primi semi della chimica del gruppo emergono da interazioni spontanee e situazioni condivise.

Non trasformare l'incontro in una presentazione artificiale di schede personaggio. I personaggi devono rivelarsi attraverso ciò che fanno.

## 17. Esplorazione: personaggio guida e percezioni passive

Decisione approvata: il personaggio in testa al party determina quali specializzazioni di esplorazione sono più efficaci. Ogni protagonista può far emergere scoperte diverse.

| Guida | Specializzazione | Ricompense/scoperte |
|---|---|---|
| Saul | Ricchezze | Denaro, bottini, tesori, oggetti di valore, nascondigli e curiosità |
| Nox | Magia | Oggetti magici, artefatti, materiali, anomalie e reperti soprannaturali |
| Rio | Kairos/biologia | Nidi, tracce, secrezioni, materiali biologici, odori e passaggi Kairos |
| Lance | Ricognizione militare | Munizioni, armi, equipaggiamento, depositi e tracce tattiche |

Regole di presentazione:
- la scoperta è principalmente passiva quando il personaggio è in testa;
- il personaggio **commenta** ciò che nota;
- non deve comparire automaticamente un grande indicatore, una freccia o un radar che rivela tutto;
- il commento suggerisce che c'è qualcosa da osservare; il giocatore cerca il punto e interagisce;
- le specializzazioni possono dare accesso a ricompense esclusive, non raggiungibili o individuabili dagli altri;
- non tutte le ricompense devono essere esclusive: possono esistere anche scoperte comuni;
- le ricompense esclusive possono essere materiali utili alla progressione e anche oggetti curiosi/collezionabili/frammenti di lore.

Questa è una scelta di design per incentivare il cambio del personaggio guida e la rigiocabilità senza costruire quattro campagne separate.

## 18. Archivio delle scoperte

- L'Archivio è approvato come sistema consultabile.
- Verrà introdotto **nel Capitolo 1**, non nella demo.
- Può raccogliere reperti, materiali, Kairos, anomalie e documenti.
- Gli oggetti curiosi non devono essere tutti utili: alcuni esistono per suscitare domande, raccontare il mondo o far reagire i personaggi.
- Le note possono riflettere chi ha trovato/analizzato l'oggetto: Saul più sarcastico/pratico, Nox più scientifica, Lance più operativa, Rio più biologico/istintivo.
- Non è ancora deciso se e come le scoperte della demo vengano trasferite nell'Archivio del Capitolo 1. È una possibilità da verificare tecnicamente, non un requisito già approvato.

## 19. Segreto finale facoltativo della demo

Decisioni confermate:
- Il finale della demo deve anticipare **sia il mistero generale dei Kairos/trasformazione della città, sia un elemento della trama personale di Rio**.
- Il collegamento personale passa dalla **Masca di Rio**.
- Il mezzo narrativo preferito è un oggetto/reperto/documento che sembra riconoscere Rio o avere un collegamento diretto con la sua Masca, non una semplice reazione ambientale.
- Il giocatore non conosce ancora ODISPEL, le Masca o la loro importanza: la scena deve comunicare il collegamento visivamente e attraverso il comportamento, senza presupporre conoscenze pregresse.
- Rio reagisce con **curiosità consapevole**, non con aggressività o paura.
- Il momento è **privato del giocatore**: gli altri tre non notano la curiosità insolita e non commentano.
- Non si spiega il mistero nella demo; la scoperta prepara il Capitolo 1.
- Non rivelare troppo presto Project Indigo o la verità completa sull'origine di Rio.
- La scoperta è facoltativa: non tutti i giocatori devono trovarla.

---

# PARTE VI — GAMEPLAY E SISTEMI

## 20. Filosofia del combattimento

Riferimenti: Persona 5/Metaphor, Expedition 33 (guardia), Honkai: Star Rail (party/energia), SMT III/V (profondità strategica), Pokémon (chiarezza), Final Fantasy (Limit Break). Sono riferimenti di design, non da copiare.

Obiettivo:
- facile da imparare, difficile da padroneggiare;
- leggibilità delle intenzioni e dei risultati;
- poche risorse e azioni comprensibili, senza HUD sovraccarico;
- profondità strategica elevata, con un tetto di abilità alto;
- aggiungere profondità senza rimuovere sistemi approvati;
- spettacolarità e chiarezza devono coesistere.

## 21. Loop V3 di combattimento discusso

La struttura concreta discussa comprende:
- **ATTACCO**
- **ABILITÀ**, con menu FIRMA e Ultimate/cut-in
- **GUARDIA**, con cerchio/timing
- **ULTIMATE**
- energia EN;
- azione nemica e minaccia sul terreno;
- debolezze con moltiplicatori;
- barra BREAK e segnale/camera dedicati;
- Ritmo squadra da Calmo → Acceso → Incandescente → Apice;
- Apice collegato al Limit Break.

Valori discussi:
- colpire una debolezza: danno ×1,5;
- colpire un elemento sfavorevole: danno ×0,67;
- Guardia corretta: danno ricevuto ×0,6 e +8 Ultimate;
- Guardia perfetta: danno ricevuto ×0,25, +18 Ultimate e contrattacco ×0,9 oppure ×1,4 per Lance.
I valori vanno considerati specifiche di design discusse, non prova che la versione attuale del codice li implementi o che non siano più soggetti a bilanciamento.

## 22. BREAK, Ritmo e Apice

- BREAK è una barra/condizione che rende leggibile lo sbilanciamento e crea una finestra di vantaggio.
- Il nemico può recuperare/rigenerare la barra secondo le regole del sistema.
- Il Ritmo della squadra cresce attraverso il combattimento e attraversa stati successivi fino ad Apice.
- Apice è il momento della Limit Break della squadra.
- I boss possono avere fasi che modificano o interrompono il Ritmo; il BREAK del boss è stato discusso con una finestra di opportunità specifica.
- La pressione BREAK sulle debolezze è stata discussa con bonus del 15%.
- Alcuni dettagli della gestione esatta delle fasi boss restano da consolidare nella specifica definitiva.

## 23. Slancio — regola approvata

**Slancio** concede un'azione aggiuntiva immediata dopo una condizione di gioco corretta.

Regole confermate:
- può essere usato soltanto per **ATTACCO o GUARDIA**;
- non consente Ultimate;
- massimo **1 Slancio per round per personaggio**;
- è collegato al personaggio che colpisce correttamente una debolezza/colore;
- la proposta precedente “tutti i comandi normali tranne Ultimate” è stata sostituita esplicitamente dalla regola più restrittiva Attacco/Guardia;
- la risoluzione avviene dopo gli eventi obbligatori e la risoluzione completa dell'azione;
- BREAK si risolve prima;
- attacco di squadra e contrattacco non generano Slancio;
- KO/fine combattimento annulla l'eventuale Slancio;
- il limite si resetta al nuovo round;
- EN ed effetti seguono le regole normali, senza bonus gratuito aggiuntivo.

È stata anche esplorata una possibile ricompensa alternativa quando una fase di invulnerabilità del boss impedisce uno Slancio meritato: resta un'idea da verificare, non una regola definitiva.

## 24. Risonanza — regola provvisoria approvata

- Risonanza si attiva tramite una Sinergia compatibile.
- Non interagisce con Apice nella versione attuale della regola.
- Non consuma e non genera Limit Break.
- Sono state considerate future estensioni: bonus collegato ad Apice e interazioni specifiche con alcune Sinergie. Sono possibilità future, non parte della regola corrente.
- È stato discusso un sistema anti-catena per evitare attivazioni ripetitive.

## 25. Personaggi in combattimento

Ruoli/identità già discussi:
- **Lance:** protettore/frontliner, breaker e difensore.
- **Nox:** supporto/guarigione e controllo/analisi.
- **Rio:** spettacolo/HYPE e potenza adattiva.
- **Saul:** furto, fortuna, opportunismo e trucchi.

La demo ha quattro membri fissi, senza cambio party previsto nel design discusso. I dettagli delle singole abilità, costi e valori devono essere verificati nel documento di combattimento aggiornato prima dell'implementazione.

## 26. UI e identità visiva HUD

Direzione approvata:
- ispirazione Persona-like, ma con identità ODISPEL autonoma;
- palette discussa: `#120B22`, `#F4F0FA`, `#873CFF`, `#E85BFF`, `#BFC3D2`;
- HUD dinamico con pannelli diagonali e bordi spezzati;
- icone angolari/asimmetriche, pochi dettagli, alta leggibilità;
- icone prioritarie: ATTACCO, GUARDIA, HYPE, BREAK;
- dimensioni base discusse: 64×64 px, HUD 32×32 px;
- simboli proposti/accettati includono spada per ATTACCO, scudo per GUARDIA, stella esplosiva per ULTIMATE, freccia spezzata per SLANCIO e diamante fratturato per BREAK;
- icona HYPE di Rio: rombo viola inclinato, punte asimmetriche, curve argentate e scintilla separata, combinando semplicità da HUD e simbolo personale riconoscibile.
- Lo stato del repository verificato in una conversazione precedente indicava che le icone definitive non erano ancora presenti e che quelle in codice erano provvisorie. Verificare prima di considerarle implementate.

---

# PARTE VII — STORIA, SCRITTURA E TONO

## 27. Regole di scrittura

- Dialoghi naturali, umani e caratterizzati; evitare esposizione artificiale.
- Non far dire ai personaggi “io sono questo tipo di persona” o spiegare la propria personalità.
- Non dare per scontata la familiarità del giocatore con il mondo o con Echo.
- Conservare eventi, segreti, tradimenti, momenti importanti e conseguenze del canone, ma riscrivere le scene in modo più naturale quando necessario.
- I personaggi non devono essere ridotti a un singolo tratto: Rio non è sempre presentatore, Saul non è sempre mercantile, Lance non cita sempre regolamenti, Nox non è sempre cinica/stanca.
- La comicità deve nascere da carattere e situazione, non da battute inserite a forza.
- Energia di gruppo di riferimento: dinamiche One Piece (Zoro/Sanji, Chopper/Usopp) e cooperazione inizialmente forzata alla Suicide Squad, che può evolvere in fiducia.
- Le relazioni sono autonome ma limitate: non sono barre numeriche; si manifestano tramite dialoghi, gesti, scelte e comportamenti.
- Il giocatore guida il gruppo, ma non controlla completamente ogni persona. Rari casi giustificati di agency individuale sono possibili; malus minori non devono rendere la run ingiocabile e, salvo casi gravi e motivati, devono essere riparabili.
- L'archivio del mondo non è onnisciente.

## 28. Scena del falò / accampamento

Dinamica confermata:
- Lance organizza i turni di guardia e mantiene la vigilanza.
- Saul rompe il silenzio, finge di dormire mentre in realtà esplora o prepara trucchi.
- Saul vuole essere scoperto, ma non lo dice: gli altri devono ricostruire gli indizi.
- Lance adatta scanner/controlli per distinguere minacce reali dai trucchi di Saul.
- Nox studia, viene trascinata nel caos e può punire Saul quando capisce cosa sta facendo.
- Rio costruisce il proprio nido e usa commenti da linguaggio streamer/social come “Trending”, “Unfollow”, “Log off”.
- Il tono deve combinare comicità, diffidenza e piccoli segnali di convivenza, non una famiglia già affiatata.

## 29. Rio e le regole del nido

- Il nido è un luogo di vulnerabilità e protezione per Rio.
- Rio usa muco e tentacoli per difenderlo.
- Le persone devono imparare distanze e comportamenti appropriati.
- Nox può studiare il fenomeno, ma deve comunque rispettare i confini.
- Saul può fraintendere un comportamento giocoso e ricevere una risposta aggressiva; il rancore conseguente può alimentare scene successive.
- Rio fuori dal nido è più spontaneo e curioso.

---

# PARTE VIII — REPOSITORY, TECNOLOGIA E PROCESSO

## 30. Stato del repository e suo significato

Repository: `Gialloo/ODISPEL`. Il branch predefinito individuato al momento della creazione di questo documento è `claude/v3-prologo`; il repository risulta pubblico. In una conversazione precedente l'autore aveva indicato di volerlo privato: la visibilità va verificata e, se non intenzionale, corretta dal proprietario. Controllare anche la cronologia per credenziali/chiavi eventualmente committate.

Il codice presente è composto da iterazioni precedenti e versioni primitive rispetto alla nuova direzione narrativa e alla demo attuale. I quattro personaggi e la storia presenti nel Git non vanno assunti come rappresentazioni definitive.

### Regola per l'audit
Classificare ogni elemento:
1. **Conservare:** sistema tecnico indipendente dalla vecchia storia, funzionante e utile.
2. **Adattare:** risorsa/sistema recuperabile con modifiche a personaggi, dati, dialoghi o presentazione.
3. **Sostituire:** contenuto che contraddice il canone attuale o non è utile.
4. **Verificare:** stato non accertato, dipendenze o test mancanti.

Non ricostruire il motore da zero senza necessità. Non preservare artificialmente contenuti vecchi solo perché esistono.

## 31. Tecnologia e preferenze di collaborazione

- Sistema operativo: Windows 11.
- Engine: Godot 4.7.2 Standard, renderer `gl_compatibility`.
- Node 24.21.0 e npm 11.19.0.
- Repository locale precedentemente indicato: `C:\Users\gianl\Documents\ODISPEL`.
- L'autore lavora con Claude Code e preferisce istruzioni in italiano, semplici, concrete, con percorsi esatti e indicazioni esplicite su cosa aggiungere/sostituire.
- Non dare per scontati passaggi tecnici o conoscenze da sviluppatore esperto.
- Preferisce audit in sola lettura e proposte prima delle modifiche.
- Non modificare codice, dati, scene o architettura prima di presentare la proposta e ricevere approvazione esplicita.
- Non lavorare mai direttamente su `main`; usare branch separati e mantenere una versione recuperabile.
- Distinguere sempre obiettivo progettuale, implementazione presente, implementazione testata e funzionalità non verificate.

## 32. Architettura e inventario tecnico storico (da riverificare)

In audit precedenti sono stati riportati:
- circa 55.000 righe GDScript e circa 300 file in una certa versione;
- 81+ unit test, circa 149 tool e centinaia di commit;
- risoluzione 1280×720 in una versione;
- UI prevalentemente costruita con Control via codice;
- engine battaglia separato;
- stato JSON-safe con int/string/array/dictionary/bool;
- RNG deterministico con seed, evitando `randf`;
- autoload citati: CampaignState, SaveManager, NetSession, Feedback, Sfx.

Questi numeri sono storici e dipendono dal branch/versione: **non presentarli come stato corrente senza un nuovo audit.**

File citati in un audit precedente come potenzialmente riutilizzabili:
- `scripts/v3/area.gd` — esplorazione/party;
- `scripts/v3/city_builder.gd` — generazione della città;
- `scripts/v3/banter.gd` — dialoghi spontanei;
- `scripts/v3/character_visual.gd` — visual dei personaggi.

L'audit precedente aveva indicato una base di esplorazione 3D, camera terza persona, un personaggio controllato e tre seguaci, dialoghi/banter e costruzione procedurale della città. Queste informazioni sono **indizi da verificare nel branch di base**, non garanzia che ogni funzione sia completa o compatibile con la nuova demo.

## 33. Multiplayer e sistemi precedenti

In una fase precedente è stato esplorato un JRPG/roguelite co-op online 2–6 giocatori con azioni simultanee, timer individuali e reazioni boss. Sono stati discussi:
- pianificazione di 30 secondi;
- attacco automatico allo scadere con penalità Surety del 30%;
- reazione boss di 5 secondi;
- difesa/schivata/parata;
- 5–8 incontri e risorse persistenti.

Questi dettagli appartengono a una fase di design precedente e non vanno considerati automaticamente parte della nuova demo single-player/party senza una decisione esplicita. In quella fase era stato segnalato che il multiplayer completo non era verificato; la presenza di modelli di stato o signaling non prova che il gioco online sia funzionante.

---

# PARTE IX — DECISIONI SUPERATE, APERTE E DA NON INVENTARE

## 34. Contenuti narrativi vecchi da non assumere come canone attuale

Un documento storico `docs/STORIA.md` descriveva:
- i quattro personaggi in Piazza Centrale alle 02:58;
- una cupola che sigilla la città;
- Echo che li presenta/manipola;
- un pacco alle 03:00 che attiva la cupola e rende pubbliche le loro facce;
- un distributore posseduto come primo boss;
- una trama strutturata attorno a quattro Anomalie e alla ricerca di una via d'uscita.

Questa versione è stata riconosciuta dall'autore come non coincidente con la storia e i personaggi attuali. Non trattarla come canone vincolante. Recuperare singoli elementi solo se l'autore li riconferma.

## 35. Decisioni confermate più recenti (11 novembre 2026)

1. Il Git contiene versioni primitive/precedenti; la demo da realizzare è quella nuova, progettata nelle conversazioni attuali.
2. Il nuovo canone prevale sulle iterazioni vecchie; Git è una riserva tecnica.
3. La demo dura 30–40 minuti.
4. Niente cinematiche dedicate a causa del budget; usare gameplay e strumenti già disponibili.
5. Le nuove idee vanno valutate per impatto sul giocatore rispetto al costo di produzione.
6. La narrazione deve privilegiare situazioni e dialoghi riutilizzabili quando opportuno.
7. L'apertura è Lance giocabile in ricognizione.
8. Lance indaga per conto proprio, dopo aver notato stranezze; non è un incarico ufficiale.
9. Lance scambia Rio per l'anomalia cercata.
10. Rio sta rovistando tra i resti di un edificio, è apparentemente inquietante ma non sta cercando di minacciare nessuno.
11. Rio ignora Lance, concentrato sulla scoperta; Lance prepara mentalmente un intervento.
12. Le percezioni passive dipendono dal personaggio guida e sono specializzate.
13. Saul trova ricchezze; Nox oggetti magici; Rio tracce/nidi/materiali Kairos e biologici; Lance munizioni/armi/equipaggiamento.
14. Il personaggio commenta ciò che nota; il giocatore deve cercare il punto.
15. Possono esistere ricompense esclusive per specializzazione e oggetti curiosi.
16. L'Archivio è approvato, ma entra in gioco dal Capitolo 1, non dalla demo.
17. Il segreto facoltativo finale della demo anticipa sia la trama dei Kairos/città sia la storia personale di Rio.
18. Il segreto coinvolge un oggetto/reperto/documento collegato alla Masca di Rio.
19. Rio lo esamina con curiosità consapevole; il momento è privato del giocatore e gli altri non reagiscono.
20. Il segreto non deve spiegare subito le Masca o Project Indigo.

## 36. Questioni ancora aperte

Non inventare risposte per questi punti:
- Come Lance interrompe Rio: confronto diretto oppure tentativo di sorprenderlo/immobilizzarlo.
- Sequenza precisa dei primi 10 minuti e ordine di ingresso degli altri protagonisti.
- Causa/evento esatto che forza i quattro a collaborare e momento preciso del cataclisma.
- Identità precisa dell'anomalia che Lance aveva notato e cosa l'ha attirato nel quartiere.
- Natura, forma e contenuto esatto del reperto collegato alla Masca di Rio.
- Se i progressi/oggetti scoperti nella demo vengono trasferiti all'Archivio del Capitolo 1.
- Implementazione tecnica del cambio personaggio guida e delle percezioni passive.
- Quali ricompense esclusive sono necessarie e quali sono solo contenuti opzionali.
- Dettaglio completo della scaletta della demo e dei suoi dialoghi.
- Quali elementi dei modelli 3D e animazioni attuali corrispondono ai design definitivi.
- Esatta specifica aggiornata di abilità, costi e bilanciamento di ogni personaggio.
- Dettagli definitivi delle fasi boss, Risonanza futura e ricompensa per Slancio negato da invulnerabilità.
- Definizioni canoniche finali di alcuni termini cosmologici e metafisici emersi in brainstorming.
- Esito finale di Saul e molti dettagli ancora da sviluppare degli archi individuali.
- Stato corrente della visibilità GitHub e presenza di eventuali segreti nella cronologia.

## 37. Regole per i prossimi handoff e per Claude Code

Quando si prepara un'attività tecnica:
1. Fornire questo documento come riferimento di canone, insieme agli eventuali documenti specifici di sistema.
2. Specificare che il repository contiene iterazioni precedenti e che non sono la fonte narrativa autoritativa.
3. Chiedere un audit in sola lettura per i file coinvolti.
4. Chiedere una proposta con file esatti, dipendenze, rischi, riuso possibile e test.
5. Non autorizzare modifiche a codice/dati/scene/architettura finché l'autore non approva la proposta.
6. Una volta approvata, lavorare su branch sperimentale separato, senza modificare main o la versione recuperabile.
7. Non confondere “esiste nel codice” con “funziona” o “è stato testato”.
8. Aggiornare questo documento quando una questione aperta viene decisa; conservare lo storico delle decisioni superate indicando cosa le ha sostituite.

---

## Appendice A — Principio guida

**ODISPEL deve diventare il gioco che abbiamo progettato adesso, non una versione aggiornata superficialmente del vecchio prototipo.**

Il lavoro già fatto ha valore se può essere riutilizzato, ma non ha diritto di veto sul nuovo canone. La demo deve essere piccola, riconoscibile, sostenibile e pubblicabile. Ogni sistema deve servire l'esperienza del giocatore e restare realizzabile da uno sviluppatore solista con risorse limitate.

## Appendice B — Nota di completezza

Questo file è il consolidamento più completo possibile sulla base delle conversazioni e dei riepiloghi personali recuperabili al momento della creazione. Non contiene una copia integrale parola per parola di tutte le chat ODISPEL e non pretende di sostituire eventuali documenti canonici più dettagliati non ancora confrontati. Le parti contrassegnate come storiche, provvisorie o aperte devono restare tali fino a verifica/approvazione dell'autore.
