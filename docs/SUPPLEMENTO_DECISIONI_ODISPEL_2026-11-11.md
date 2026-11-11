# ODISPEL — Supplemento di decisioni, sistemi e conversazioni
**Versione:** 1.0  
**Data:** 11 novembre 2026  
**Repository:** `Gialloo/ODISPEL`  
**Branch:** `docs/odispel-master-canon-2026-11-11`  
**Documento principale collegato:** `docs/CANONE_MAESTRO_ODISPEL_2026-11-11.md`

---

## 0. Come leggere questo supplemento

Questo file raccoglie materiale aggiuntivo emerso nelle conversazioni ODISPEL e non sviluppato abbastanza nel documento principale. Non sostituisce il Canone Maestro: lo integra.

Le conversazioni hanno attraversato diverse fasi del progetto. Per evitare di confondere idee storiche con decisioni attuali, ogni blocco è classificato:

- **CONFERMATO:** scelta esplicitamente approvata dall'autore.
- **DIREZIONE / PREFERENZA:** intenzione chiara, ma non necessariamente specifica tecnica definitiva.
- **STORICO / SUPERATO:** idea appartenente a una fase precedente; utile come archivio, non vincolante per la demo attuale.
- **PROPOSTA NON CONFERMATA:** proposta emersa, ma non va trattata come decisione.
- **DA VERIFICARE:** informazione tecnica o narrativa che richiede un nuovo controllo.

Il documento non è una trascrizione parola per parola delle chat. Non inventare i dettagli mancanti. In caso di conflitto, valgono le decisioni più recenti e più esplicitamente approvate dall'autore.

---

# PARTE I — PROGETTAZIONE DEL COMBATTIMENTO: DETTAGLI AGGIUNTIVI

## 1. Risoluzione dei turni individuali

**CONFERMATO in una fase di design del combattimento (20 ottobre 2026):**
- I turni sono individuali.
- Ogni azione viene risolta completamente prima che inizi la successiva.
- Non esiste una coda in cui tutte le azioni dei personaggi vengono scelte e poi risolte simultaneamente.
- Il boss può agire fra i turni dei personaggi.
- Le combo non sono garantite quando vengono pianificate: vengono verificate nel momento in cui dovrebbero attivarsi e soltanto se le condizioni sono ancora valide.

Esempio concettuale discusso:
1. Rio agisce e applica un marchio/condizione.
2. Il boss agisce.
3. Il sistema verifica se marchio, debuff, scudo e condizioni necessarie sono ancora presenti.
4. Saul svolge il proprio turno.
5. Un'eventuale combo può attivarsi solo se i requisiti sono ancora rispettati.

Conseguenze:
- Se il personaggio richiesto è KO/incapacitato, la combo non si attiva.
- Se il marchio o la condizione è scaduta/rimossa, la combo non si attiva.
- Il boss può interrompere il piano della squadra.
- La combo non salta il turno del boss.
- Le animazioni delle azioni e delle combo devono restare leggibili e distinguibili.

Questa struttura rende le combo opportunità tattiche da mantenere, non sequenze automatiche prenotate in anticipo.

## 2. Combo, reazioni e preparazione

**CONFERMATO come direzione di design:**
- Le combo/reazioni equipaggiabili devono essere limitate e preparate prima dello scontro.
- Ogni personaggio può portare **1–2** combo/reazioni equipaggiate.
- La gestione è prevista dal menu **START**.
- La combo è facoltativa e dipende dalle condizioni presenti al momento della verifica.
- Le combo non devono produrre catene infinite o power creep incontrollato.

**Distinzioni emerse:**
- Combo equipaggiate: risposte/azioni preparate dal giocatore, con slot limitati.
- Sinergie automatiche: fenomeni o interazioni del sistema che non sono necessariamente la stessa cosa delle combo equipaggiate.
- Reazioni: risposte a eventi/azioni avversarie, da tenere distinte dalle combo offensive quando la specifica sarà finalizzata.

Una proposta iniziale parlava di massimo due slot per personaggio e di una Riserva di squadra condivisa; il numero di slot 1–2 è stato espresso dall'autore, mentre la Riserva condivisa e la separazione completa delle categorie richiedono conferma prima di essere implementate.

## 3. Principio delle combo emergenti

Modello concettuale proposto:
**Preparare una condizione → trasformarla → convertirla in un risultato.**

Possibili risultati:
- danno;
- protezione;
- generazione/recupero di risorse;
- interruzione;
- controllo del campo.

Per esempio, un personaggio prepara una vulnerabilità o un marchio; un altro può sfruttarlo se la condizione persiste dopo l'azione nemica.

Regole di robustezza suggerite:
- risoluzione deterministica;
- priorità esplicite;
- condizioni consumate in modo esplicito;
- log di combattimento leggibile;
- prevenzione delle catene infinite;
- nessun risultato simultaneo ambiguo.

Questo è un principio di progettazione, non un elenco di combo già approvate.

## 4. Surety e timer: sistema storico del co-op

**STORICO — non assumere che appartenga alla demo attuale.**

In una precedente iterazione del combattimento co-op era stato discusso:
- finestra condivisa di **30 secondi** per decidere le azioni della squadra;
- la conferma anticipata dell'azione aumentava la sua efficacia tramite **Surety**;
- allo scadere del timer, chi non aveva confermato eseguiva un attacco base con penalità Surety del **30%**;
- alcune abilità potevano aggiungere o rimuovere tempo;
- alcune abilità potevano preparare l'azione del turno successivo;
- il sistema puntava a decisioni rapide e comunicazione tra amici.

La Surety è una meccanica appartenente a questa fase precedente. Non inserirla automaticamente nel combattimento della demo attuale.

## 5. Lettura visiva del combattimento

**DIREZIONE / PREFERENZA:**
Il giocatore deve poter leggere:
- vulnerabilità e debolezze;
- prossime mosse nemiche;
- preparazione di attacchi pericolosi;
- stato BREAK;
- disponibilità di Slancio;
- crescita del Ritmo;
- opportunità di Guardia perfetta;
- momenti in cui una Ultimate cambia la situazione.

La leggibilità deve provenire da segnali coerenti: animazione, suono, colore, camera e UI. Non introdurre nuove risorse solo per visualizzare meglio uno stato già esistente.

Un layout HUD proposto in cinque zone:
1. stato nemico;
2. campo di battaglia;
3. party;
4. Ritmo;
5. comandi/azioni.

È una proposta di organizzazione visiva, non una struttura obbligatoria già approvata. Le risorse già nominate nel progetto comprendono HP, EN, Ultimate, HYPE, BREAK, Slancio e Apice; non creare una nuova barra o valuta senza una decisione esplicita.

## 6. Boss e telegraph

**DIREZIONE / PREFERENZA:**
- Gli attacchi boss devono essere leggibili prima di colpire.
- Le finestre di vulnerabilità devono essere riconoscibili.
- Il BREAK deve avere un payoff visivo e tattico chiaro.
- Le fasi boss possono cambiare le priorità e mettere sotto pressione il Ritmo.
- Le reazioni del boss devono far capire che la squadra ha ottenuto un vantaggio o che il boss ha reagito.

La sequenza di test proposta per la presentazione era: **Telegraph → Combo leggibile → Payoff visivo**. Era un test di leggibilità, non una decisione di contenuto o bilanciamento.

---

# PARTE II — PERSONAGGI: ULTERIORI SFUMATURE E SCENE

## 7. Lance: figura da istruttore nel futuro

**DIREZIONE NARRATIVA discussa:**
Lance potrebbe concludere il proprio arco diventando una figura simile a un istruttore/maestro:
- addestrare nuove generazioni di combattenti/reclute;
- trasmettere saggezza ed esperienza sul campo;
- scegliere una vita più tranquilla dopo gli eventi;
- non necessariamente fondare una grande organizzazione o diventare un comandante.

È stata immaginata una possibile scena futura: un cadetto della Libra Corp scopre finalmente la posizione di un combattente leggendario e raggiunge Lance per chiedergli di addestrarlo. Il cadetto potrebbe essere il primo allievo o uno dei pochi, in una dinamica da maestro leggendario alla Rayleigh.

Questa è una possibile direzione di epilogo/futuro, non una scena già fissata nella demo.

## 8. Saul: solitudine, scherzi e possibile destino

Ulteriori precisazioni:
- Saul ama costruire lo scherzo tanto quanto assistere alla reazione.
- Non vuole semplicemente nascondere ogni traccia: vuole che gli altri siano abbastanza attenti da scoprirlo.
- Il suo desiderio di essere scoperto non va dichiarato apertamente; deve emergere dagli indizi e dalla sua reazione quando gli altri arrivano alla soluzione.
- La sua abilità nel leggere le persone non implica che riesca a capire sempre tutti: Echo, per esempio, può risultargli difficile da interpretare.

Sul suo destino è stata discussa una possibilità estrema di sopravvivenza quasi nulla (0,1%), ma non è una percentuale canonica né una morte confermata. Se sopravvive, la direzione ipotizzata è una lunga fase da solitario: non torna semplicemente nel gruppo, non si fa riconoscere e potrebbe aiutarli da lontano come benefattore misterioso, continuando persino a fare scherzi.

## 9. Rio: identità, linguaggio e adattamento

Il contrasto tra Rio prima e dopo la fusione è importante:
- Rio umano era solare, chiacchierone, iperattivo e desideroso di visibilità.
- L'ibrido è più silenzioso e comunica spesso con brevi espressioni/meme.
- Il linguaggio social è un residuo/strumento di espressione, non un obbligo per ogni battuta.
- Non scriverlo come uno streamer che presenta continuamente la propria vita.
- Il suo comportamento deve poter oscillare tra curiosità, gioco, istinto predatorio, cautela, territorialità e affetto non verbale.

L'adattamento biologico non deve farlo diventare una collezione di trasformazioni scollegate: Rio conserva identità e continuità, combina e riorganizza capacità e può svilupparne di nuove attraverso esperienza e apprendimento.

## 10. Echo: comportamento e rapporto con gli altri

Echo non è una guida enciclopedica. La sua presenza iniziale è legata a telecamere, schermi e dispositivi; osserva, registra, interviene quando può, ma non conosce necessariamente tutto.

Sfumature discusse:
- ama provocare Rio e divertirsi a sue spese;
- con Saul può avere una dinamica particolare: Saul è abituato a leggere le persone, ma Echo è difficile da decifrare;
- una battuta di Echo sul fatto che Saul sia un buono a nulla può colpire una sua vulnerabilità; Saul non la rimprovera, ma si ritira e le augura semplicemente la buonanotte;
- Echo può avere paura o diffidenza verso Lance e Saul, anche se resta curiosa e buffa.

Questi dettagli vanno usati per creare persone credibili, non per assegnare a Echo il ruolo di mascotte comica.

## 11. Rifugio: non sono ancora una famiglia

**PREFERENZA ESPRESSA dall'autore (5 novembre 2026):**
Il rifugio non deve sembrare subito una casa condivisa da una famiglia affiatata. Inizialmente sono quattro persone finite nello stesso posto:
- piccoli disaccordi sul divano e sugli spazi;
- turni e compiti pratici;
- abitudini incompatibili;
- silenzi e tentativi di conversazione;
- gesti di cortesia non dichiarati;
- persone che cercano vicinanza senza ammetterlo.

Il senso di famiglia si costruisce col tempo attraverso abitudini, attriti, esclusioni, riconciliazioni e gentilezze non sottolineate.

## 12. Dialoghi e scene di rifugio già approvati

Nelle conversazioni del 5 novembre sono state approvate/revisionate alcune interazioni naturali:
- Lance–Rio sul primo turno di guardia e sulle telecamere.
- Nox–Rio: «Aspetta, stai già dormendo?» / «Se stai zitto riesco».
- Rio–Saul: battuta sulla batteria al 9% e sulla sopravvivenza.
- Echo–Nox: «Funziona?» / «Non so dirtelo con certezza».

Una dinamica Lance–Saul discussa: Saul cerca un contatto senza fidarsi ancora; parte da una stupidaggine e può arrivare a una conversazione più sincera, senza trasformarla in una confessione improvvisa.

**Riferimento storico:** una versione di questi dialoghi è stata riportata come inserita in `data/dialoghi_atto1.json` sul branch `claude/v3-prologo`, commit `e76723d0df5ca90e56ec23f62950738f825f4c18`. Il contenuto è una vecchia iterazione: controllare prima di recuperarlo e riscriverlo in accordo con il canone attuale. Non assumere che quel branch o quei dialoghi siano la versione definitiva.

## 13. Nostalgia e memoria dei personaggi

**CONFERMATO come direzione di design (4 novembre 2026):**
Usare un sistema ibrido di:
- richiami spontanei, attivati dal contesto e dalle situazioni;
- richiami scritti/espliciti, quando un personaggio decide di ricordare o raccontare qualcosa.

La nostalgia condivisa non ha un'unica tonalità. Può essere:
- felice;
- malinconica;
- agrodolce;
- dolorosa.

Due personaggi possono ricordare lo stesso evento in modo diverso. Il ricordo non deve essere sempre un'esposizione del passato: può cambiare il modo in cui reagiscono nel presente.

---

# PARTE III — DIREZIONE DEL GIOCO E CONCETTI STORICI

## 14. Esperienza di gioco immaginata nelle prime fasi

**STORICO / DIREZIONE GENERALE, da non confondere con il perimetro della demo attuale.**

Nelle prime fasi ODISPEL è stato immaginato come un gioco che fondeva:
- struttura/relazioni e presentazione ispirate a Persona;
- fantasia di caccia e preparazione da Monster Hunter;
- progressione e cooperazione da gioco online;
- esplorazione, minacce e ricompense.

Il loop ipotizzato era:
**vivere in un hub/città → esplorare → studiare/prepararsi → affrontare minacce → migliorare → affrontare avversari più forti.**

La città/hub poteva essere viva e affiancata da zone soprannaturali, dungeon, cacce, raid e segreti. La filosofia era poter affrontare minacce sempre più forti da soli o con amici.

Questo descrive una visione di lungo periodo emersa nel brainstorming, non una specifica della demo.

## 15. Tensione tra personaggio personale e roster collezionabile

È stata identificata una contraddizione importante:
- desiderio di giocare il proprio Odispeller, con punti di forza e difetti, e vivere un'esperienza simile a un MMO;
- idea di collezionare/ottenere molti personaggi o unità, in stile gacha;
- combattimento a turni con QTE/azioni reattive;
- ambizione multiplayer.

L'autore ha chiesto di rifinire o ripensare il design prima di fissare queste scelte. Non trattare il gacha o un roster enorme come una decisione definitiva.

## 16. Classi e loot: iterazione precedente

**STORICO / PARZIALMENTE APPROVATO in una fase di ottobre:**
- quattro classi previste;
- le prime classi considerate erano **Ladro, Guerriero, Mago**, con quarta classe ancora da definire;
- ispirazione Borderlands per equipaggiamento, loot e build;
- esplorazione e combattimento con ricompense che possono cambiare la build;
- richiesta dell'autore di mantenere il sistema semplice (“basta”, non gonfiare lo scope);
- personaggi futuri/DLC erano stati proposti, ma non sono un impegno approvato per la nuova direzione.

Una proposta di demo di quella fase prevedeva una classe, tre tipi di nemici più un élite, 20–30 combinazioni di loot, tre leggendari, una piccola regione e un dungeon boss. È un piano storico, non la demo attuale da 30–40 minuti.

## 17. Co-op online: obiettivi storici e limiti tecnici

**STORICO:** in una fase precedente l'autore aveva approvato l'idea di multiplayer online cooperativo per gruppi di 5–6 amici. In altre discussioni era stata indicata una direzione 1–6 giocatori, con slot mancanti gestiti dall'IA, stanza tramite codice e senza account/matchmaking nella prima versione.

Punti discussi:
- ogni giocatore controlla un personaggio;
- party cooperativo, non necessariamente competitivo;
- ruoli complementari e momenti di spotlight;
- server autorevole che valida le azioni e risolve lo stato;
- pianificazione simultanea e combo/reazioni;
- stato KO/downed, votazioni e riconnessione in alcune proposte;
- prima prova con due telefoni/giocatori, poi espansione fino a sei.

L'autore aveva espresso che il co-op poteva essere centrale, ma il multiplayer non doveva necessariamente essere obbligatorio. Il desiderio era giocare in gruppo, non creare una modalità competitiva.

### Stato tecnico storico — da non sovrastimare
- Le classi WebRTC di Godot 4.7.2 erano state verificate a livello API.
- Un server di signaling separato era stato salvato con test; il signaling non equivale a gameplay multiplayer autorevole.
- Un commit storico `e92f3de` includeva server di signaling, test e strumento diagnostico.
- Quattro test di signaling erano passati.
- Il server usava `127.0.0.1:9080`.
- Il signaling locale non era pronto per Internet.
- Il test Godot WebSocket era rimasto irrisolto per un problema relativo alla firma di `SceneTree._process`/terminazione.
- Una connessione WebRTC reale tra client non era stata verificata.
- In una fase di validazione erano stati indicati 12 script di stato da testare: operazioni party, round/boss/combattimento, RNG deterministico, serializzazione e snapshot che preservano i dati del giocatore. Era stato deciso di non aggiungere feature multiplayer prima della validazione.

Questi risultati sono storici e non attestano che il multiplayer sia oggi funzionante. Per la demo attuale non aggiungere lavoro online senza una decisione esplicita e una verifica tecnica separata.

---

# PARTE IV — INTERFACCIA E PRESENTAZIONE: ALTRE DIREZIONI

## 18. Menu principale e menu personaggio

Nelle conversazioni del 7 novembre è stato approvato di procedere con la progettazione del **menu principale** e poi del **menu personaggio**.

Proposta visiva discussa per il menu principale:
- illustrazione dinamica;
- logo ODISPEL;
- menu inclinato/diagonale;
- città notturna e soprannaturale;
- illustrazione che può variare con i progressi narrativi: inizialmente Mada, poi il gruppo completo e successivamente momenti narrativi.

Il concetto di illustrazione variabile è una proposta di presentazione accolta come direzione di lavoro, ma la sua implementazione e i trigger esatti restano da definire.

## 19. Interfaccia dialoghi ed esplorazione

Proposte discusse per l'interfaccia narrativa:
- ritratti e espressioni dei personaggi;
- nome del parlante;
- box dialogo diagonali, con testo leggibile;
- scelte chiaramente distinguibili;
- prompt contestuali come Esamina, Parla, Raccogli, Apri, Interagisci;
- obiettivi di missione e aggiornamenti;
- minimappa con giocatore, obiettivi, personaggi importanti e punti di interesse.

Questi elementi sono una direzione di UI, non tutti requisiti implementativi confermati. Non sacrificare la leggibilità per imitare Persona.

---

# PARTE V — PRODUZIONE, VALIDAZIONE E BUSINESS

## 20. Principio di validazione

Prima di espandere sistemi complessi, verificare il nucleo con test e casi concreti. In particolare, nella fase multiplayer era stato chiesto di validare:
- operazioni party;
- round e turni;
- boss e combattimento;
- determinismo dell'RNG;
- serializzazione;
- snapshot che preservino i dati del giocatore.

La regola generale resta utile anche alla demo: dimostrare che un sistema è affidabile prima di costruirci sopra altri livelli di complessità.

## 21. Strategia di pubblicazione e monetizzazione discussa

La strategia di lungo periodo è stata esplorata in più iterazioni:
- costruire un pubblico prima di avere il prodotto completo;
- usare Instagram/TikTok per mostrare personaggi, ambienti, misteri e worldbuilding;
- rivolgersi a un pubblico internazionale;
- valutare Kickstarter o altre forme di finanziamento quando esiste una community interessata;
- pubblicazione digitale indipendente;
- manga/Webtoon come canale narrativo e promozionale;
- Patreon e Gumroad per contenuti/ricavi diretti;
- stampa premium come prodotto aggiuntivo.

L'autore ha discusso in passato obiettivi economici più elevati (inclusi scenari da milioni di fatturato o centinaia di migliaia di euro personali), ma la direzione economica più recente riportata nel Canone Maestro è l'obiettivo di circa **3.000–3.500 € netti mensili** per il progetto/società, mantenendo capitale e utili nell'azienda per il gioco successivo. Le vecchie cifre sono scenari storici, non target attuali.

## 22. Rischio di scope

Rischi emersi ripetutamente:
- troppi sistemi contemporanei;
- multiplayer, roster, loot, QTE e narrativa episodica che si contendono tempo e risorse;
- costruire cinematiche e asset unici non sostenibili;
- confondere un prototipo tecnico con un prodotto pubblicabile;
- continuare ad aggiungere decisioni senza consolidare le precedenti.

Regola operativa:
**ogni feature deve avere un motivo per esistere nella demo, un costo di produzione stimato e un criterio di verifica.** Se è una feature futura, documentarla ma non inserirla automaticamente nello scope corrente.

---

# PARTE VI — CRONOLOGIA E DISTINZIONE DELLE ITERAZIONI

## 23. Cronologia sintetica dei blocchi di design recuperati

- **Settembre 2026:** visione di gioco con cooperazione, personaggio personale, ruoli complementari e tensione tra MMO/co-op, roster e turni con QTE.
- **Ottobre 2026:** iterazioni su classi, loot, co-op online, timer/Surety, combo e reazioni, server di signaling e validazione tecnica.
- **20 ottobre 2026:** definizione più chiara dei turni individuali, risoluzione sequenziale, boss interposto tra personaggi e combo verificate al momento; 1–2 combo/reazioni equipaggiate per personaggio dal menu START.
- **4 novembre 2026:** direzione per richiami spontanei e scritti, nostalgia con tonalità diverse.
- **5 novembre 2026:** revisione di dialoghi e scene di rifugio; il gruppo non è ancora una famiglia; Echo/Rio come complicità non romantica iniziale.
- **7 novembre 2026:** lavoro su menu principale, menu personaggio e interfaccia.
- **11 novembre 2026:** consolidamento della nuova demo da 30–40 minuti, Lance in ricognizione, incontro equivoco con Rio, percezioni passive per personaggio guida, segreto facoltativo collegato alla Masca di Rio.

Questa cronologia serve a riconoscere l'evoluzione del progetto, non a dare uguale priorità a tutte le iterazioni.

---

# PARTE VII — ELENCO DI QUESTIONI ANCORA DA CHIUDERE

## 24. Combattimento
- La specifica completa di combo/reazioni e Sinergie deve essere consolidata con Slancio, Risonanza, Ritmo e Apice.
- Confermare se il limite definitivo è 1 o 2 slot per personaggio (la direzione approvata è 1–2).
- Definire le condizioni di attivazione e consumo per ogni combo.
- Definire la gestione esatta della Riserva condivisa, se verrà mantenuta.
- Definire il rapporto tra turni individuali e ordine timeline nella versione corrente.
- Verificare che i valori numerici citati nel Canone Maestro siano ancora validi.
- Definire con precisione telegraph, fasi boss e ricompense quando una meccanica è impedita da invulnerabilità.

## 25. Personaggi e narrazione
- Definire gli archi completi di Lance, Nox, Saul e Rio.
- Stabilire se la scena futura di Lance istruttore/maestro è canonica.
- Definire il destino finale di Saul senza assumere la percentuale 0,1% come certezza.
- Chiarire la progressione e i limiti dei poteri di Rio.
- Definire i costi e i limiti di Echo.
- Sviluppare la relazione Rio–Echo nel lungo periodo senza anticipare il romanticismo.
- Sviluppare la possibile relazione Saul–Nox senza forzarla.
- Recuperare e confrontare i dialoghi del 5 novembre con la nuova demo: non copiare scene vecchie se la situazione narrativa è cambiata.

## 26. Prodotto e tecnologia
- Decidere se il co-op online è un obiettivo del gioco completo, una possibilità futura o un sistema da mettere in pausa.
- Non assumere che i test storici di signaling equivalgano a un multiplayer pronto.
- Definire il rapporto tra personaggio personale, roster e party fisso.
- Definire quali elementi del vecchio loot/classi sopravvivono alla nuova visione.
- Verificare i menu e l'interfaccia sul progetto corrente.
- Costruire una roadmap che distingua demo, Capitolo 1 e funzionalità future.

---

## Appendice A — Regola di continuità

Il Canone Maestro contiene le decisioni più importanti e attuali. Questo supplemento preserva dettagli aggiuntivi e soprattutto impedisce che vecchi sistemi o proposte vengano scambiati per il design della demo.

**Non reintrodurre automaticamente Surety, co-op, gacha, classi, roster, loot o vecchie trame nella demo.** Sono idee storiche o sistemi da rivalutare separatamente.

## Appendice B — Completezza

Il documento raccoglie il materiale aggiuntivo recuperato dalle conversazioni e dai riepiloghi disponibili. Non garantisce di contenere ogni singola battuta o ogni messaggio storico. Se emergono ulteriori conversazioni, decisioni o documenti specifici, vanno aggiunti come nuove sezioni con data, stato (confermato/proposta/storico/aperto) e indicazione di cosa sostituiscono.
