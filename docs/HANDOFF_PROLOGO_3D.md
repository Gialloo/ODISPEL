# ODISPEL — Handoff: commissione del PROLOGO in 3D (stile Honkai: Star Rail)

Destinatario: una nuova istanza di Claude che lavora sulla repo `Gialloo/ODISPEL` (Godot 4.7.2).
Scritto il 18 ottobre 2026. Lingua dell'utente (Gianluca): **italiano**. Tono diretto, riepiloghi brevi.

Questo documento fa due cose:
1. ti spiega la **nuova direzione narrativa** del gioco, decisa con l'utente il 18/10/2026;
2. ti **commissiona il prologo** del gioco, in 3D, come prima prova. L'utente vuole vedere come lo realizzi: per ora **solo il prologo**.

Leggi anche l'handoff tecnico precedente (stato 0.28.11, regole di release, test, problemi aperti), che resta valido per tutto ciò che qui non è detto. Se non lo trovi in `docs/`, chiedilo all'utente.

---

## 0. Come lavorare con questo utente (obbligatorio)

- Prima di scrivere codice: **una frase** su cosa stai per fare. A fine lavoro: poche righe su cosa è uscito, cosa **non** è stato provato, un passo successivo reale. Niente recap dei passaggi.
- **Non dichiarare mai test non eseguiti.** Scrivi sempre cosa non hai potuto provare: telefono Android vero, Windows vero, fps, batteria e calore reali. Le misure sul server usano il renderer software: valgono solo come confronto prima/dopo.
- Rispetta le impostazioni di accessibilità esistenti (`Settings`: scosse, lampi, effetti ridotti/`light_fx`, salto cut-in, vibrazione). Deve essere leggibile su PC e su schermi piccoli Android.
- **NON toccare**: battaglia classica (`scenes/battle/`), PvP, multiplayer (`NetSession`), salvataggi, progressione, bilanciamento dei personaggi esistenti. Il Test V2 (`scenes/squad_v2/`, `scenes/world_v2/`, `scenes/battle_v2/`) deve continuare a funzionare. Il prologo è **codice nuovo e additivo**.
- Nessun segreto nel repo (la repo è privata). `ITCH_API_KEY` sta nei secrets di GitHub.
- Se l'utente dà un ordine diretto di implementazione, procedi senza chiedere permesso. Fai domande solo su decisioni che sono davvero sue.
- Gli hook "N commit non pushati" sono spesso falsi allarmi: verifica `git rev-parse --short HEAD` contro `git ls-remote origin <branch>`.

---

## 1. La visione: Odispel è un IP

Odispel è un universo narrativo che vivrà su più media: un **manga** (protagonista Mada), **videogiochi** e un **gioco di carte**.

**Regola dell'IP:** ogni media mostra una **prospettiva diversa** dello stesso universo. Nessuno racconta tutto. Il quadro completo nasce unendo i pezzi.

**Il videogioco NON racconta la storia di Mada.** È una storia a parte, ambientata in un **paese lontano**: della storia principale arrivano solo **influenze lontane**. Mada non compare e non va nominato nel prologo.

Lo scopo del gioco è far nascere fan dell'universo, che poi seguiranno i progetti successivi.

---

## 2. Regole del mondo (quello che serve al gioco)

- **Odispeller**: i maghi. Per esercitare serve una **licenza**, ottenuta con esami.
- **Il velo** separa il mondo umano da quello magico. Gli umani normali non vedono demoni, maghi e magie.
- Gli Odispeller sono organizzati in **brigate con nomi di uccelli**. Nella città del gioco la brigata locale sono le **Civette**. Le **Rondini** appartengono a un'altra città, quella del manga, e **non vanno usate** come fazione del gioco.
- **Magabondi**: chi usa la magia senza licenza. È un reato.
- **LibraCorp**: organismo paramilitare fondato dal misterioso **Leviatano**. All'epoca del gioco è **riconosciuta dallo Stato e dalla gente** e combatte Anomalie e demoni. Usa tecnologie bizzarre, in parte scienza e in parte ricavate dalla magia. È temuta e ha il pugno di ferro.
- **Masca**: umani che ottengono poteri indossando **maschere bizzarre** spedite da mittenti misteriosi.
- **Anomalie / Kairos**: entità di un altro piano, di cui si sa poco. Nel gioco le **Anomalie urbane** possiedono oggetti della città (distributore, semaforo, tombino, cabina telefonica) e sono i boss.

---

## 3. La storia del gioco (decisa con l'utente)

### Premessa
Una **città viene sigillata** da una cupola: nessuno entra e nessuno esce. Le Anomalie si risvegliano ovunque. L'unico modo per uscire è **chiudere le Anomalie una a una**.

Quattro sconosciuti di fazioni diverse vengono **incastrati** per il disastro: le telecamere li hanno ripresi tutti e quattro vicino all'oggetto che ha attivato il sigillo. Ora sono **ricercati da tutte le fazioni, comprese le loro**. Per uscire e riabilitarsi devono collaborare.

### La guida: il Kairos
- È un **Kairos** che vive nelle **telecamere e nei circuiti** della città, alla Rotom. È della stessa natura delle Anomalie urbane.
- È l'unico che vede tutta la città sigillata. L'interfaccia a telecamere del gioco (stile "CAM-07") è **il suo sguardo**.
- Non comanda il gruppo: gli offre un **accordo**. Nessuno si fida di lui.
- È un **personaggio**, non il giocatore. Il giocatore controlla il party.
- **Segreto (NON rivelarlo nel prologo):** è stato lui a incastrare i quattro. Gli servono quattro persone di fazioni diverse per aprire un varco e tornare a casa. Il gruppo lo scoprirà a metà storia. Alla fine rinuncerà a tornare per restare con loro.

### Il vero colpevole (NON rivelarlo nel prologo)
Il **Committente** ha commissionato il trasporto dell'oggetto e spedisce le maschere dei Masca. Nel prologo può esistere al massimo come **voce al telefono** o mittente senza volto.

### Il tono
Personaggi **imperfetti e non proprio buoni**, personalità forti, stile **Borderlands / Suicide Squad**. Battute taglienti, contrasti, comicità, ma con un cuore. Tutti e quattro sono **giovani**.

### I quattro protagonisti (nomi provvisori)
| Nome | Fazione | In breve | Difetto | Paura | Sogno |
|---|---|---|---|---|---|
| **Ferri** | LibraCorp | Ex soldato modello, retrocesso. Parla per regolamenti e disprezza la magia, ma ha un **braccio impiantato con tecnologia magica di contrabbando** (segreto). | Ipocrita, autoritario | Essere scoperto "contaminato" e contenuto | Riavere grado e fedina pulita |
| **Nox** | Civette (Odispeller) | Odispeller del turno di notte, cinica e sfinita, vive di caffè. Accetta mazzette e chiude un occhio. | Corrotta, apatica | Rivivere la notte in cui qualcuno è morto durante il suo turno | Fare soldi e mollare il lavoro (non è vecchia) |
| **Zecca** | Masca | Ragazzo che ha ricevuto una maschera per posta e la usa per fare visualizzazioni in diretta. Vanitoso, impulsivo, linguaccia. | Vanità, impulsività | Senza maschera tornare a essere nessuno; che la maschera gli mangi la faccia | Diventare famoso |
| **Saul** | Magabondo | Giovane contrabbandiere di artefatti, truffatore affascinante e bugiardo. È già stato contenuto da LibraCorp, quindi **odia Ferri**. | Mente e tradisce per guadagno | Tornare in gabbia | L'ultimo grande colpo |

Contrasti principali: **Ferri contro Saul** (guardia e ladro), **Nox contro Zecca** (la disillusa e il ragazzino che vuole tutto subito). Ferri e Zecca hanno lo stesso segreto: la magia addosso.

**Saul, senza saperlo, ha consegnato l'oggetto che sigilla la città.** Questo è il motivo per cui la colpa ricade sul gruppo.

### Struttura completa (solo per contesto; ora si fa SOLO il prologo)
Gioco da ~100 ore: 40-50 di storia + extra, modello JRPG come FFX e Dragon Quest VIII. L'atto 1 si svolge nella città sigillata, una metropoli a strati con quartieri, metro, tetti e sottosuolo; ogni Anomalia chiusa apre una zona. A metà storia c'è il tradimento del Kairos e il sigillo cade: si apre tutto il paese. Le Anomalie sono **dungeon**, piccole dimensioni in cui si entra, come i Palazzi di Persona.

---

## 4. LA COMMISSIONE: il prologo in 3D

### 4.0 Organizzazione: è la V3 (deciso con l'utente)
Il prologo in 3D è un salto di direzione, non un ritocco della V2. Trattalo come una **V3** separata, così la V2 resta intatta come riferimento e si può tornare indietro.
- **Branch nuovo:** `claude/v3-prologo`, creato partendo da `claude/battaglia-v2`. Lavora e fai i push solo lì. Non fare merge su `claude/battaglia-v2` senza il via dell'utente.
- **Cartelle nuove:** tutto il codice e i dati della V3 stanno in `scenes/v3/`, `scripts/v3/` e `data/v3/`, più i test `tests/unit/test_v3_*.gd` e i tool `tools/v3_*.gd`. Lo stesso repo, così si riusa la logica di combattimento già fatta (`BattleState`, `SeqRound`).
- **Hub:** aggiungi un pulsante **V3** accanto a TEST V2, che resta dov'è.
- **Canali itch separati:** la V3 va su canali propri, ad esempio `android-v3` e `windows-v3` su `boomeranza/odispel`, così l'utente può confrontare V2 e V3 sul telefono. I canali `android-mobile` e `windows-pc` restano alla V2.
  - Usa nomi di file distinti, ad esempio `releases/v3/ODISPEL v3 mobile v.X.Y.Z.apk` e `releases/v3/ODISPEL v3 pc vX.Y.Z.zip`, che non devono finire nei pattern del workflow V2.
  - Crea un **workflow nuovo** (es. `.github/workflows/itch_v3.yml`) sul modello di `itch_v2test.yml`, che parte solo per i file `releases/v3/…` e carica sui canali V3. Non modificare il workflow V2.
  - Se la creazione dei canali o del workflow fallisce attraverso il proxy, dillo all'utente e proponi un'alternativa. Non toccare i canali V2.

### 4.0b Primo rilascio = test sul telefono (OBBLIGATORIO prima del resto)
Il crash Android della mappa V2 è ancora aperto e il 3D in terza persona su telefono è la parte più rischiosa. Quindi **prima di costruire il prologo** fai un rilascio minuscolo e fermati:
1. **Contenuto della 0.29.0 (V3):** una strada 3D, un personaggio segnaposto che cammina con la camera alle spalle e si ruota, un dialogo di due righe e un mini combattimento 3D contro un nemico, con controlli touch e PC. Nient'altro.
2. Pubblicala sui canali V3 e chiedi all'utente di provarla sul **suo telefono**: se si apre, se gira fluida, se crasha e dove.
3. **Fermati e aspetta la risposta.** Se gira bene, procedi con il prologo completo (0.29.1 e successive). Se crasha, chiedi modello del telefono, punto esatto e, se possibile, il log (`adb logcat`). Avere un caso così semplice aiuta anche a capire il crash della V2.
4. Nel report della 0.29.0 indica esplicitamente quali funzioni di rendering hai usato (tipo di camera, shader, contorni, cielo, testo 3D o UI 2D), così se crasha si sa dove cercare.

### 4.1 Obiettivo
Realizzare il **prologo giocabile** (durata indicativa 20-40 minuti) in **3D, nello stile di Honkai: Star Rail**:
- **esplorazione in terza persona** con personaggi 3D, camera che segue alle spalle e si può ruotare;
- **combattimento a turni in 3D**: il party da un lato, i nemici dall'altro, inquadrature dinamiche per ogni azione, barra dell'ordine dei turni, abilità e ultimate con una piccola sequenza cinematica;
- **scene di dialogo** con i personaggi in 3D e box di testo;
- look **cel-shading / anime**: toni piatti, contorni, colori forti. Riprendi lo stile pop "Gorillaz / The World Ends With You" già usato nella mappa V2, alzandolo verso un toon 3D più pulito.

L'utente vuole vedere **come lo realizzi**: è una prova di direzione e di qualità, non un prodotto finito.

### 4.2 Contenuto del prologo (proposta; nomi di città e paese provvisori)
Nome provvisorio della città: **[CITTÀ]**. Usa un segnaposto chiaramente marcato, perché l'utente non l'ha ancora deciso.

1. **Apertura: una notte in città.** Quattro brevi vignette, giocabili o semi-giocabili, una per protagonista, per presentarli:
   - Ferri di pattuglia LibraCorp, che recita il regolamento a un collega (o a sé stesso);
   - Nox di turno con le Civette, il caffè e una mazzetta accettata;
   - Zecca in diretta con la maschera, che fa lo sbruffone con i follower;
   - Saul che consegna un pacco in un luogo appartato e riceve la telefonata di una voce senza volto (il Committente).
2. **Il sigillo.** Il pacco si attiva in una piazza: una cupola cala sulla città, salta la corrente e le Anomalie si risvegliano. Per motivi diversi, i quattro si ritrovano nella **stessa piazza**.
3. **Primo combattimento (tutorial).** Un'Anomalia urbana li attacca e sono costretti a combattere insieme. Puoi usare il **Distributore**, l'unica Anomalia già disegnata in V2, rifatto in 3D. Il tutorial spiega i turni, le abilità e l'ultimate.
4. **Incastrati.** Radio, maxischermi o telefoni mostrano le immagini delle telecamere: i quattro sono indicati come responsabili. Litigio tra loro: Ferri vuole arrestare Saul, Saul vuole scappare, Zecca vuole filmare, Nox vuole solo andarsene.
5. **Il Kairos.** Una telecamera si gira verso di loro. Il Kairos parla attraverso schermi e altoparlanti, si presenta e propone l'accordo. Interfaccia "CAM" come suo sguardo.
6. **Fine prologo.** Il gruppo accetta controvoglia. Titolo del gioco e schermata "Fine del prologo".

Puoi aggiustare l'ordine e il ritmo, ma rispetta i punti fissi: **niente rivelazione dei segreti** (il tradimento del Kairos, il Committente, il braccio di Ferri), Saul è chi ha portato il pacco, i quattro vengono incastrati dalle telecamere, il tono è alla Borderlands.

Scrivi i dialoghi in **italiano**, brevi, con personalità forte e battute. Tienili in file di dati separati dal codice (es. `data/prologo/dialoghi.json` o `.gd` di sole costanti), così l'utente può correggerli senza toccare la logica.

### 4.3 Requisiti tecnici
- **Motore:** Godot 4.7.2, GDScript. Il progetto usa il renderer **gl_compatibility**: **tienilo**, salvo motivo forte da discutere prima con l'utente, perché il gioco deve girare su **Android di fascia media** e su PC. Orientamento landscape, base 1280×720 con `canvas_items` expand.
- **Prestazioni mobile:** low-poly, materiali toon unshaded o semplici, pochi draw call (raggruppa la scenografia in mesh unici come in `world_v2`: `_batch_box`/`_batch_flush`), niente ombre in tempo reale costose, 60 fps massimi in esplorazione (`Engine.max_fps`, da ripristinare in `_exit_tree`).
- **Attenzione crash Android aperto** (vedi handoff 0.28.11): sul telefono dell'utente la mappa V2 crashava prima della battaglia. Non è mai stato riprodotto. Evita o isola le funzioni sospette: Sprite3D/Label3D con `no_depth_test` + `render_priority`, sky con shader, `next_pass` di outline su molti materiali, scale a zero esatto nelle matrici, `Image.blend_rect` su immagini grandi. Libera la scena 3D prima di caricarne un'altra pesante (come `_handoff` in `world_v2`).
- **Personaggi 3D:** non esistono modelli. Crea **segnaposto 3D curati**, low-poly con proporzioni anime, silhouette e colori ben distinti per ognuno dei quattro e per il Kairos, costruiti da codice o come scene semplici. Mettili dietro un'interfaccia sostituibile (es. una scena `CharacterVisual` per personaggio con animazioni idle, cammino, attacco, colpito, ko), così i modelli veri (glTF) si potranno inserire dopo senza toccare la logica. Le animazioni possono essere tween e procedurali.
- **Combattimento:** riusa la **logica** esistente (`BattleState`, `SeqRound` in `scripts/battle/seq_round.gd`: turni sequenziali per velocità, ULT, rottura, debolezze di colore) e costruiscine una **presentazione 3D nuova**. Non modificare `battle_v2.gd` né `BattleResolver`. I dati dei quattro nuovi personaggi vanno in un **file di contenuti nuovo** (non modificare i personaggi esistenti). I valori numerici sono **provvisori**: segnalo nel report.
- **Controlli:** PC con WASD/frecce, mouse o Q/E per ruotare la camera, E/Invio/Spazio per interagire, Esc per il menu. Touch con stick fluttuante a sinistra, trascinamento a destra per la camera, tasto azione e menu. Riusa gli approcci di `world_v2` (`Pad`, `ActBtn`, eventi raw multi-touch, `TouchUi.force` per i test).
- **Accesso:** pulsante **V3** nell'Hub (vedi 4.0); TEST V2 resta dov'è. Nessun salvataggio e nessun premio per ora.
- **Accessibilità:** scosse e lampi regolabili (usa gli helper esistenti o equivalenti), possibilità di saltare cutscene e dialoghi, testo leggibile su telefono.
- **Audio:** facoltativo. Se non c'è, dillo nel report.

### 4.4 Modo di procedere suggerito
1. Leggi la struttura della repo e l'handoff tecnico. Crea il branch `claude/v3-prologo`. Una frase all'utente su cosa stai per fare.
2. **Rilascio di prova 0.29.0** (vedi 4.0b): fetta minima, test automatici e screenshot su PC e touch, workflow e canali V3, pubblicazione. Poi **fermati e aspetta** l'esito sul telefono dell'utente.
3. Solo con il via dell'utente: completa il prologo scena per scena (0.29.1 e successive). Manda anteprime presto, così l'utente può correggere la direzione.
4. Test automatici nuovi (`tests/unit/test_v3_*.gd`) e script di screenshot e prestazioni sul modello di `tools/world_v2_shot.gd` e `tools/world_v2_perf.gd`. Rilancia anche i test V2 esistenti per verificare di non averli rotti.
5. Release su itch con la procedura dell'handoff 0.28.11, ma con file in `releases/v3/` e workflow V3 (voce nel changelog in italiano), poi controlla i check-run. Se butler fallisce al primo colpo, rilancia lo stesso run.
6. Report breve a ogni rilascio: cosa è uscito, screenshot, cosa **non** è stato provato, prossimo passo.

### 4.5 Comandi utili (dall'handoff precedente)
- `export PATH=/root/bin:$PATH` prima di ogni comando (godot sta lì).
- Test: `xvfb-run -a godot --path . --resolution 1280x720 -s tests/unit/<test>.gd`
- Screenshot touch: `xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s <tool>.gd -- <dir> touch`
- Dopo nuovi asset o classi: `godot --headless --path . --import` e committa i `.uid` generati.
- Release: aggiorna `VERSION` in `scripts/config/game_config.gd`, `export_presets.cfg` (codice e nome versione) e `scripts/config/changelog.gd`, poi esporta APK (`tools/shrink_apk.py`) e zip Windows in `releases/`, aggiorna `SHA256SUMS.txt` e fai il push. Il workflow `itch_v2test.yml` carica la V2 su `boomeranza/odispel`; per la V3 usa i file in `releases/v3/` e il workflow V3 (vedi 4.0).
- Trailer dei commit: usa quello indicato dal tuo ambiente.

---

## 5. Decisioni ancora aperte (non inventarle come definitive)
- Nome della città e del paese; nomi definitivi dei quattro (Ferri, Nox, Zecca, Saul sono provvisori).
- Aspetto e nome del Kairos.
- Classi e mosse definitive dei quattro.
- Se sostituire in futuro i 10 operatori attuali (Kira, Dax, Elle…) con i nuovi protagonisti, e come spostare dalle Rondini alle Civette quelli che restano.

Se devi scegliere qualcosa per andare avanti, scegli, marcalo come **provvisorio** nel codice e nel report.
