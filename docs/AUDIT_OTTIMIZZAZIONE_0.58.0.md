# Registro audit e ottimizzazione — ODISPEL 0.58.0

> Branch di lavoro: `experiment/0.58.0-audit-ottimizzazione`  
> Baseline: `release/0.58.0` — commit iniziale `3e785d96c824f31a6a948225439998927946cae5`  
> Stato: audit statico GitHub; nessuna esportazione o esecuzione Godot effettuata da questo ambiente.  
> Regola: annotare qui ogni verifica, criticità, proposta, modifica, test e possibile espansione. Non modificare `main` né `release/0.58.0`.

## 1. Scopo e metodo

Questo documento è il registro permanente del lavoro di verifica e ottimizzazione. Deve essere aggiornato a ogni sessione, mantenendo distinti:

- **Confermato**: verificato direttamente nel codice o nei file.
- **Da misurare**: rischio plausibile, non dimostrato come problema reale.
- **Proposta**: intervento suggerito, non ancora approvato o applicato.
- **Effettuato**: modifica realmente presente nel branch.
- **Testato**: test realmente eseguito, con esito e ambiente.
- **Non testato**: controllo non eseguito; non deve essere presentato come superato.

Ordine di lavoro concordato:
1. Prestazioni 3D.
2. Motore di combattimento.
3. Controlli touch.
4. Struttura del progetto.
5. Salvataggi e regressione.
6. Documentazione.
7. Pubblicazione.

Nessuna modifica a regole di gioco, dialoghi, bilanciamento o contenuti narrativi senza approvazione esplicita.

---

## 2. Baseline e stato del branch

- Branch di partenza: `release/0.58.0`.
- Commit di partenza verificato: `3e785d96c824f31a6a948225439998927946cae5`.
- Branch sperimentale creato: `experiment/0.58.0-audit-ottimizzazione`.
- Il branch sperimentale nasce dalla baseline indicata; non è stato effettuato alcun merge sulla release.
- La documentazione di questo registro è la prima modifica del branch sperimentale.
- Nessun file di gioco, scena, dato narrativo, asset, preset di esportazione o workflow di pubblicazione è stato modificato in questa prima fase.

## 3. Fase 1 — Prestazioni 3D

### 3.1 Componenti ispezionati

- `scripts/v3/light_fx.gd`
- `scripts/v3/character_visual.gd`
- `scripts/v3/night_fx.gd`
- `scripts/v3/static_fx.gd`
- `scripts/v3/mesh_batch.gd`
- `scripts/v3/city_builder.gd`
- `scripts/v3/shader_warmup.gd`
- `tools/v3_prestazioni.gd`
- `tools/v3_stress_battaglia.gd`
- `main.gd` / transizione VHS (ispezione precedente)

### 3.2 Elementi positivi verificati

- La città usa geometrie accorpate tramite il sistema MeshBatch; non costruisce ogni dettaglio come nodo indipendente.
- Le comparse immobili possono usare mesh aggregate e MultiMesh: il codice di CharacterVisual documenta il vantaggio di ridurre le chiamate di disegno.
- Pioggia ed effetti ambientali sono costruiti con mesh aggregate, non con un nodo separato per ogni goccia.
- Le mesh degli effetti luminosi disattivano il casting delle ombre.
- Sono già presenti strumenti di misurazione: `tools/v3_prestazioni.gd` e `tools/v3_stress_battaglia.gd`.
- Il test prestazioni misura caricamento, draw call, primitive, oggetti, nodi, tempo medio del frame e memoria statica.
- Lo stress test battaglia registra tempo di processo, tempi totali dei frame, picchi e categorie di sequenza (attacco di squadra, Ultimate, turno normale).

### 3.3 Criticità e rischi

| ID | Osservazione | Stato | Impatto potenziale | Verifica necessaria |
|---|---|---|---|---|
| 3D-01 | `LightFx._process()` ricostruisce la ImmediateMesh a ogni frame per gli effetti attivi. | Confermato nel codice; costo non misurato | CPU e upload geometria quando molti effetti si sovrappongono | Profilare scena con massimo numero realistico di effetti e confrontare preset effetti ridotti/normali |
| 3D-02 | `CharacterVisual._process()` aggiorna continuamente pose, respiro e oggetti accessori. | Confermato nel codice; costo non misurato | CPU per personaggi visibili o non in animazione significativa | Misurare aree e battaglie con numero massimo di personaggi; verificare quali istanze restano attive fuori vista |
| 3D-03 | La transizione VHS acquisisce una texture e ne legge l'immagine tramite GPU→CPU. | Osservazione da verifica nel percorso di transizione | Picco isolato durante cambio schermata | Misurare durata e hitch su dispositivo Android reale |
| 3D-04 | Gli strumenti attuali danno medie, ma non un profilo GPU Android completo né una distribuzione dettagliata dei frame. | Confermato per gli script ispezionati | Le medie possono nascondere stutter e picchi | Aggiungere report p50/p95/max e registrare modello dispositivo, risoluzione e renderer; distinguere CPU/GPU dove possibile |
| 3D-05 | Il riscaldamento shader è presente. | Confermato | Non è noto se copra tutti gli shader delle scene più pesanti | Controllare compilazione a freddo e stutter al primo utilizzo di effetti/aree |

### 3.4 Migliorie proposte

1. Eseguire una baseline ripetibile prima di modificare il rendering.
2. Registrare per ogni scena: device, versione Android, renderer, risoluzione, FPS target, frame medio, p95, massimo, memoria, draw call, primitive, nodi e tempo di caricamento.
3. Profilare effetti luminosi sovrapposti, personaggi, città, pioggia e transizioni separatamente.
4. Se 3D-01 è un collo di bottiglia reale, valutare riuso delle superfici/mesh o riduzione degli aggiornamenti geometrici non necessari, preservando la resa artistica.
5. Se 3D-02 pesa in modo significativo, valutare sospensione selettiva degli aggiornamenti solo per personaggi non visibili o realmente inattivi. Non eliminare il respiro/idle senza decisione artistica.
6. Se 3D-03 produce un hitch misurabile, valutare un percorso alternativo di cattura/transizione senza perdere l'effetto VHS.
7. Evitare riduzioni preventive di qualità, luci, pioggia o dettagli prima di avere dati.

### 3.5 Test eseguiti

| Test/controllo | Esito | Ambiente |
|---|---|---|
| Ispezione statica degli script e dei tool elencati | Completata; nessun runtime test | GitHub branch `release/0.58.0` |
| `tools/v3_prestazioni.gd` | Non eseguito | Godot non disponibile in questo ambiente |
| `tools/v3_stress_battaglia.gd` | Non eseguito | Godot non disponibile in questo ambiente |
| Profilazione Android reale | Non eseguita | Richiede dispositivo e build installata |
| Confronto prima/dopo ottimizzazione | Non eseguito | Nessuna ottimizzazione runtime applicata |

**Risultato della fase 1:** nessun collo di bottiglia prestazionale è ancora dimostrato. Le osservazioni 3D-01, 3D-02 e 3D-03 sono rischi da misurare, non bug confermati.

### 3.6 Migliorie effettuate al momento

- Creato il branch sperimentale dedicato.
- Creato questo registro per conservare audit, proposte, test e decisioni.
- Nessuna modifica al codice runtime: senza baseline e senza esecuzione Godot, cambiare il rendering sarebbe un intervento non verificabile e potrebbe peggiorare prestazioni o resa visiva.

### 3.7 Espansioni future possibili

- Profilo prestazioni automatico per ogni area e arena.
- Confronto CSV/JSON fra build e dispositivi.
- Modalità benchmark ripetibile con semi e condizioni identiche.
- Report di frame pacing, p95/p99 e picchi durante transizioni.
- Preset qualità adattivi solo se supportati da misure e approvati.

---

## 4. Fase 2 — Motore di combattimento

### Elementi verificati

- Separazione fra `BattleFlow`, `BattleResolver` e `BattleState`.
- Presenza di percorso Timeline e percorso a round.
- Presenza di test dedicati a Timeline, SLANCIO, BREAK, RITMO e flusso.
- I test della Timeline includono casi con boss e semi deterministici.
- I test di flusso confrontano il motore nuovo con il percorso precedente.

### Rischi e verifiche proposte

| ID | Osservazione | Stato | Prossimo controllo |
|---|---|---|---|
| COM-01 | Due percorsi di esecuzione (Timeline e round) devono restare coerenti. | Rischio architetturale | Confronto eventi e stato finale con stessi semi |
| COM-02 | Le interazioni SLANCIO protetto, cambio fase, KO, interruzioni e BREAK vanno testate in sequenze miste. | Copertura da ampliare | Test combinatori e simulazioni multi-seme |
| COM-03 | Risorse, scudi, stati e HUD devono ricevere gli eventi una sola volta. | Da verificare | Test di idempotenza e confronto stato motore/HUD |
| COM-04 | Le modifiche condivise possono introdurre regressioni in modalità non attiva. | Rischio | Eseguire suite completa per entrambi i percorsi |

### Migliorie proposte

- Aggiungere test per combinazioni di meccaniche e transizioni di fase.
- Aggiungere controlli su risorse e stati dopo ogni evento.
- Ampliare simulazioni multi-seme e conservare i casi che falliscono come regressioni permanenti.
- Non cambiare bilanciamento o regole senza richiesta specifica.

### Test eseguiti

- Ispezione statica dei moduli principali e dei test: completata.
- Esecuzione della suite Godot: non eseguita in questo ambiente.
- Nessuna regressione può quindi essere dichiarata esclusa.

### Migliorie effettuate

- Nessuna modifica al motore in questa fase.

### Espansioni future possibili

- Test property-based su sequenze di azioni valide.
- Riproduzione deterministica di una battaglia da seed e log eventi.
- Report automatico delle divergenze tra Timeline e round.

---

## 5. Fase 3 — Controlli touch

### Elementi verificati

- `touch_controls.gd` gestisce stick virtuale e trascinamento telecamera con multi-touch.
- `touch_ui.gd` attiva i controlli in ambiente mobile o quando forzati.
- I pulsanti touch hanno aree sensibili maggiorate.
- I comandi principali di battaglia usano controlli UI dedicati.

### Criticità

| ID | Osservazione | Stato | Impatto potenziale |
|---|---|---|---|
| TOUCH-01 | `release_all()` azzera gli indici touch e lo stick, ma non azzera esplicitamente `cam_drag`. | Confermato nel codice | Possibile residuo di trascinamento dopo pausa/dialogo |
| TOUCH-02 | `_process()` richiede ridisegno continuo anche quando i controlli non cambiano. | Confermato nel codice | Lavoro CPU/GPU evitabile |
| TOUCH-03 | Alcuni pulsanti contestuali hanno altezza minima 52, inferiore ai 64 dei pulsanti standard touch. | Confermato nel codice | Bersagli touch meno uniformi |
| TOUCH-04 | Non è stato individuato un test unitario dedicato a TouchControls. | Riscontro nella lista test ispezionata | Regressioni multi-dito non coperte |

### Migliorie proposte

- Azzerare anche lo stato di trascinamento telecamera al rilascio globale, dopo aver verificato tutti i chiamanti.
- Ridisegnare solo quando lo stato cambia o quando un'animazione visibile lo richiede.
- Uniformare le aree touch contestuali, se non causa sovrapposizioni o problemi di layout.
- Aggiungere test per due dita, rilascio indipendente, pausa/ripresa, dialoghi e interazioni.

### Test eseguiti

- Ispezione statica: completata.
- Test su dispositivo Android: non eseguiti.
- Test automatici touch: non eseguiti.

### Migliorie effettuate

- Nessuna modifica al codice touch in questa fase.

### Espansioni future possibili

- Calibrazione delle dimensioni touch e delle zone sicure per differenti rapporti schermo.
- Test automatici degli input simultanei e dei cambi di focus.
- Opzioni di riposizionamento o scala controlli, se richieste dai test utenti.

---

## 6. Fase 4 — Struttura del progetto

### Elementi verificati

- Separazione fra `scripts/engine/`, `scripts/v3/`, `data/`, `assets/`, `tests/unit/`, `tools/` e `docs/`.
- La scena principale è `scenes/main.tscn`; una parte dell'interfaccia viene costruita via codice.
- `battle3d.gd` è un file molto grande (circa 4.9k righe nell'ispezione precedente).

### Criticità e proposte

| ID | Osservazione | Stato | Proposta |
|---|---|---|---|
| ARCH-01 | `battle3d.gd` concentra molte responsabilità di presentazione e orchestrazione. | Confermato per dimensione; rischio manutenzione | Estrarre moduli solo dopo test di caratterizzazione |
| ARCH-02 | L'estrazione può alterare ordine eventi, segnali, riferimenti e timing. | Rischio | Conservare interfacce pubbliche e fare estrazioni piccole |
| ARCH-03 | Molti sistemi sono creati via codice. | Scelta architetturale, non bug | Documentare responsabilità e punti d'ingresso |

### Migliorie effettuate

- Nessuna ristrutturazione del codice.

### Espansioni future possibili

- Mappa delle dipendenze e degli autoload.
- Diagramma dei flussi di scena e combattimento.
- Estrazione graduale di componenti da `battle3d.gd` con test di equivalenza.

---

## 7. Fase 5 — Salvataggi e regressione

### Elementi verificati

- Il sistema di progressione conserva capitolo, passo, flag, stato area, posizione e informazioni di squadra.
- È presente una compatibilità per dati di squadra mancanti nei vecchi salvataggi.
- Il punto di ritorno pre-battaglia viene salvato.
- Esistono test di progressione e altri test di sistema.

### Criticità

| ID | Osservazione | Stato | Impatto potenziale |
|---|---|---|---|
| SAVE-01 | `Story.save()` chiama `ConfigFile.save()` senza verificare il risultato. | Confermato nel codice ispezionato | Scrittura fallita non segnalata |
| SAVE-02 | Il percorso CONTINUA non verifica adeguatamente l'esito del caricamento prima di proseguire. | Confermato nel flusso ispezionato | Ripresa incoerente con file danneggiato/non leggibile |
| SAVE-03 | Non è stata verificata una strategia completa di backup e recupero. | Da verificare | Possibile perdita del salvataggio precedente |
| SAVE-04 | Test di corruzione e recupero non individuati nell'ispezione. | Copertura da verificare | Errori non intercettati |

### Migliorie proposte

- Controllare ogni risultato di scrittura e caricamento.
- Creare backup atomico o copia precedente verificata, senza sovrascrivere il file valido in caso di errore.
- Validare schema, versione, capitolo, passo, posizione, livelli, equipaggiamento e mosse rubate.
- Aggiungere test per file mancanti, incompleti, corrotti, vecchi e scritture fallite.
- Definire migrazioni esplicite per non perdere compatibilità.

### Migliorie effettuate

- Nessuna modifica al sistema di salvataggio.

### Espansioni future possibili

- Versionamento dello schema salvataggi.
- Backup rotanti con verifica integrità.
- Test di migrazione automatica fra versioni.

---

## 8. Fase 6 — Documentazione

### Criticità verificate

- `README.md` contiene riferimenti a versioni e istruzioni di rilascio non allineati alla 0.58.0.
- `docs/ISTRUZIONI_INSTALLAZIONE.md` contiene indicazioni Android riferite a versioni/firme precedenti.
- `docs/CHANGELOG.md` contiene già una voce 0.58.0.

### Migliorie proposte

- Aggiornare README con versione, struttura e procedure effettive.
- Separare istruzioni per sviluppatori, test e utenti finali.
- Aggiornare installazione Android soltanto dopo aver verificato la continuità della chiave di firma.
- Mantenere questo registro come documento vivo, con date, commit, test ed esiti.

### Migliorie effettuate

- Creato questo registro audit/ottimizzazione.

---

## 9. Fase 7 — Pubblicazione

### Elementi verificati

- Workflow: `.github/workflows/itch.yml`.
- Destinazioni: `boomeranza/odispel:android-v3` e `boomeranza/odispel:windows-v3`.
- Il workflow carica artefatti già presenti in `releases/`; non li compila.
- È disponibile `workflow_dispatch`; il branch predefinito è `claude/v3-prologo`.
- Il workflow verifica la firma APK e controlla la presenza del segreto Itch.
- I pacchetti presenti in `release/0.58.0` durante l'audit sono ancora 0.57.0.
- Il preset Android abilita ARM64 e disabilita ARMv7.
- Lo script `tools/sign_apk.py` genera una chiave se il percorso PEM non esiste.

### Criticità

| ID | Osservazione | Stato | Impatto |
|---|---|---|---|
| PUB-01 | Il workflow non compila i pacchetti: carica i file già presenti. | Confermato | Rischio di pubblicare una build vecchia |
| PUB-02 | Il workflow seleziona l'APK e lo ZIP più recenti separatamente e ricava la versione dall'APK. | Confermato | Rischio di versioni non corrispondenti |
| PUB-03 | Lo script firma genera una nuova chiave se il PEM non esiste. | Confermato | Nuova firma incompatibile con installazioni firmate dalla vecchia chiave |
| PUB-04 | Il preset Android è ARM64-only. | Confermato; scelta da validare | Alcuni dispositivi ARMv7 non sono supportati |
| PUB-05 | README e istruzioni pubblicazione/installazione non sono pienamente aggiornati. | Confermato | Errore operativo o istruzioni fuorvianti |
| PUB-06 | Il segreto Itch non è verificabile tramite l'ispezione del repository. | Non verificabile qui | Workflow potrebbe non autenticarsi |

### Migliorie proposte

- Confrontare versione progetto, nome APK e nome ZIP e bloccare mismatch.
- Bloccare upload se manca un artefatto o se la firma non è quella attesa.
- Rendere esplicita la scelta della chiave: mai generare una nuova chiave di release senza conferma intenzionale.
- Produrre checksum degli artefatti e conservarli nel registro release.
- Valutare ARMv7 in base ai dispositivi target e alle dimensioni/prestazioni.
- Eseguire pubblicazione solo dopo verifica manuale degli artefatti e del canale.

### Migliorie effettuate

- Nessuna modifica al workflow, ai preset o allo script di firma.

### Espansioni future possibili

- Pipeline separata di build, test, firma e pubblicazione.
- Artefatti con versioni abbinate e checksum automatici.
- Workflow di test automatici prima della pubblicazione.
- Checklist release con conferma della chiave e dei canali.

---

## 10. Registro cronologico delle sessioni

### 2026-11-06 — Avvio audit 0.58.0

- Eseguita ispezione statica del branch `release/0.58.0`.
- Creato branch `experiment/0.58.0-audit-ottimizzazione` dalla baseline verificata.
- Creato questo documento.
- Nessun test Godot eseguito.
- Nessuna modifica runtime effettuata.
- Fase corrente: **1 — Prestazioni 3D**.
- Prossima azione: eseguire il benchmark aggiornato con Godot su PC e Android, conservando l'output grezzo prima di intervenire sul rendering.

### 2026-11-06 — Strumentazione benchmark 3D

- **Branch:** `experiment/0.58.0-audit-ottimizzazione`.
- **File modificato:** `tools/v3_prestazioni.gd`.
- **Criticità affrontata:** il benchmark originale raccoglieva solo 30 frame e stampava tempi medi; i picchi e gli stutter potevano restare nascosti.
- **Modifica effettuata:** warmup portato a 30 frame e campionamento a 180 frame per scenario; aggiunti FPS medi, frame time media/p50/p95/max, tempo di processo media/p95/max, versione Godot, sistema operativo, viewport e FPS target. Il limite FPS precedente viene ripristinato al termine di ogni scenario.
- **Test eseguiti:** revisione statica del file aggiornato e verifica del commit GitHub.
- **Esito:** modifica salvata nel branch; non è stata eseguita da Godot e non è ancora validata dal parser/runtime.
- **Test non eseguiti / limiti:** nessun benchmark, nessuna misura GPU e nessun test su dispositivo Android; i dati saranno significativi solo eseguendo lo stesso scenario, con stesso device, renderer e impostazioni.
- **Rischi residui:** un campione di 180 frame migliora la lettura dei picchi ma resta breve per sessioni lunghe; il tempo totale del frame è una misura osservata dal loop, non una misura isolata della GPU.
- **Espansioni future:** esportazione CSV/JSON, più ripetizioni per scenario e confronto automatico tra baseline e build ottimizzata.

### 2026-11-06 — Copertura shader warmup: disturbo StaticFx

- **Branch:** `experiment/0.58.0-audit-ottimizzazione`.
- **File coinvolti:** `scripts/v3/static_fx.gd`, `scripts/v3/shader_warmup.gd`.
- **Criticità osservata:** il warmup includeva i materiali Toon, pioggia, telecamera rotta e glitch, ma non lo shader spaziale personalizzato di `StaticFx`, usato per il disturbo visivo durante BREAK/KO.
- **Evidenza:** nell'elenco `mats` di `ShaderWarmup._ready()` non era presente alcun materiale costruito con `StaticFx.SHADER`; `StaticFx` creava lo shader solo quando veniva istanziato per la prima volta.
- **Modifica effettuata:** aggiunto `StaticFx.shader()` come accessor statico con inizializzazione lazy condivisa; il warmup crea un `ShaderMaterial` con quello shader e lo inserisce nella lista dei materiali da disegnare.
- **Obiettivo:** anticipare la compilazione del disturbo al warmup, evitando che il primo BREAK/KO paghi il costo della prima compilazione.
- **Test eseguiti:** controllo statico delle due modifiche e verifica della presenza dello shader nel materiale del warmup.
- **Esito:** modifica salvata nel branch sperimentale.
- **Test non eseguiti / limiti:** non è stato possibile eseguire Godot, verificare la compilazione GDScript/shader o misurare lo stutter prima/dopo; l'efficacia effettiva va confermata su PC e Android.
- **Rischi residui:** il warmup deve effettivamente renderizzare il quad con il materiale nel SubViewport; la verifica runtime resta necessaria. Il nuovo materiale aggiunge un solo shader al breve warmup.
- **Espansioni future:** inventario automatico degli shader usati dalle scene e test a freddo che verifichi che ogni shader critico sia compilato prima del primo utilizzo.

## 11. Modello per gli aggiornamenti futuri

Per ogni intervento aggiungere una voce con questo schema:

### [DATA] — [ID / area / descrizione breve]

- **Branch e commit di partenza:**
- **File coinvolti:**
- **Criticità osservata:**
- **Evidenza:**
- **Modifica proposta:**
- **Modifica effettuata:**
- **Test eseguiti:**
- **Esito:**
- **Test non eseguiti / limiti:**
- **Rischi residui:**
- **Espansioni future:**

Non segnare mai come effettuato o testato un intervento che non è stato realmente applicato o eseguito.


### 2026-11-06 — Verifica copertura shader del warmup

- **Branch:** `experiment/0.58.0-audit-ottimizzazione`.
- **File ispezionati:** `scripts/v3/shader_warmup.gd`, `scripts/v3/toon.gd`, `scripts/v3/night_fx.gd`, `scripts/v3/static_fx.gd`, `scripts/v3/broken_cam.gd`, `scripts/v3/glitch_fx.gd`.
- **Verifica effettuata:** confrontati i materiali personalizzati dichiarati nei moduli esaminati con quelli costruiti nel warmup.
- **Copertura riscontrata:** Toon body/ink/ink_grow/body_tex/glow/shadow; materiale pioggia NightFx; StaticFx; shader 2D BrokenCam e GlitchFx. Il materiale hit_flash è uno StandardMaterial3D, non uno shader personalizzato dichiarato dal progetto.
- **Esito statico:** tutti gli shader personalizzati individuati in questi moduli hanno un corrispondente materiale nel warmup. Per body_tex viene usata l'icona come texture campione: il codice shader è condiviso, mentre le texture reali possono variare.
- **Limite della verifica:** questo è un confronto statico dei moduli elencati, non una scansione runtime esaustiva di ogni materiale caricato dinamicamente; non dimostra che la compilazione avvenga correttamente su ogni GPU/driver.
- **Test eseguiti:** lettura dei sorgenti e confronto degli elenchi; nessuna esecuzione Godot.
- **Prossimo test necessario:** avvio a freddo, primo utilizzo di ogni effetto e registrazione dei frame time su PC e Android, confrontando warmup attivo/disattivo.
- **Modifiche runtime:** nessuna in questa verifica.


### 2026-11-06 — Verifica statica motore di combattimento

- **File esaminati:** `scripts/engine/battle_flow.gd`, `scripts/engine/battle_resolver.gd`, `scripts/engine/battle_state.gd`, `tests/unit/test_v3_flusso.gd`, `tests/unit/test_v3_timeline.gd`, `tests/unit/test_v3_slancio.gd`, `tests/unit/test_v3_engine.gd`.
- **Architettura:** il flusso dei turni, la risoluzione delle azioni e lo stato serializzabile sono separati. La Timeline ha un percorso dedicato; il giro a round conserva test di equivalenza con il flusso precedente.
- **Copertura test presente nel repository:** equivalenza su 180 scontri nel test del flusso; test dedicati a Timeline, Slancio (incluso Slancio protetto), combattimento completo e varie interazioni. Questi sono test definiti nel codice, non eseguiti durante questa verifica.
- **Criticità confermate:** nessun errore logico dimostrabile dalla sola lettura dei file esaminati. Non applicate modifiche speculative al resolver o alle regole di combattimento.
- **Miglioria proposta:** eseguire la suite su Godot e aggiungere casi combinati mirati per cambio fase + BREAK + interruzione + Slancio protetto + KO, controllando risorse, ordine eventi e telegraph.
- **Test eseguiti:** ispezione statica dei sorgenti e dei test; nessuna esecuzione Godot.

### 2026-11-06 — Correzione input touch al rilascio globale

- **File modificato:** `scripts/v3/touch_controls.gd`.
- **Criticità:** `release_all()` liberava gli indici delle dita e azzerava lo stick, ma lasciava intatto `cam_drag` e la posizione del pomello. Dopo pausa, cambio schermata o perdita del focus, il trascinamento residuo poteva essere consumato successivamente dalla camera.
- **Correzione:** `release_all()` ora azzera anche `cam_drag` e `_knob`, quindi richiede un ridisegno immediato.
- **Test eseguiti:** confronto statico prima/dopo e verifica del commit su GitHub. Non eseguiti test touch su dispositivo né test Godot.
- **Rischio residuo:** verificare su Android la ripresa dopo pausa, cambio schermata e multitouch; assicurarsi che il chiamante invochi `release_all()` in tutti i passaggi che devono annullare gli input.


### 2026-11-06 — Struttura progetto e persistenza: approfondimento statico

- **Struttura:** cartelle distinte per motore (`scripts/engine`), presentazione V3 (`scripts/v3`), dati, test e strumenti. La separazione tra BattleFlow/BattleResolver/BattleState e scena 3D è un punto positivo.
- **Debito tecnico individuato:** `scripts/v3/battle3d.gd` conta 4.915 righe. È un coordinatore molto grande; estrazioni future possibili: presentazione HUD, animazioni/effetti, gestione input e sequenza delle scene. Non spezzarlo in questa fase senza test d'integrazione: molti riferimenti condivisi rendono rischiosa una divisione meccanica.
- **Salvataggi:** `Story.load_game()` controlla il risultato di `ConfigFile.load`, ma assegna i dati senza validare gli indici capitolo/passo contro la struttura narrativa corrente. `Story.save()` ignora il valore di ritorno di `ConfigFile.save`. Il pulsante CONTINUA nel menu non controlla il booleano restituito da `Story.load_game()` prima di proseguire.
- **Test già presenti:** `test_v3_engine.gd` copre il salvataggio e ripristino dello stato area; è un test presente nel repository, non eseguito in questa sessione.
- **Interventi runtime in questa sottosezione:** nessuno. La correzione richiede una politica esplicita per salvataggi corrotti/vecchi e un messaggio UI di errore; non applicata alla cieca per non rischiare progressi dell'utente.
- **Test eseguiti:** ispezione statica dei file e dei call site; nessuna esecuzione Godot.

### Prossime migliorie pianificate (senza modifiche premature)

1. Salvataggi: validazione capitolo/passo, risultato di scrittura propagato, backup recuperabile e test di file assente/corrotto/vecchio.
2. Touch: test multi-dito, pausa/ripresa, perdita focus e cambi schermata; rivedere il ridisegno continuo solo dopo aver verificato aggiornamenti visuali e animazioni.
3. Struttura: estrazione graduale di responsabilità da `battle3d.gd`, una per volta, con test di regressione.
4. Pubblicazione: controllo coerenza versione/nome artefatto, firma Android e corrispondenza pacchetto prima di avviare Butler.


### 2026-11-06 — Protezione e validazione dei salvataggi

- **File modificati:** `scripts/v3/story.gd`, `scripts/v3/menu.gd`.
- **Problema riscontrato:** la scrittura ignorava il codice di errore di `ConfigFile.save`; il menu CONTINUA e il salto ai capitoli ignoravano il valore booleano di `Story.load_game()`. Un file danneggiato o un errore di scrittura potevano quindi produrre una prosecuzione non affidabile.
- **Caricamento:** ora capitolo e passo vengono controllati rispetto alla struttura narrativa prima di applicare i dati; flag e stato area devono essere dizionari. Se la validazione fallisce, il metodo restituisce `false` senza applicare parzialmente i dati narrativi.
- **Scrittura:** ora salva prima su un file temporaneo, sposta il salvataggio precedente in backup durante la sostituzione e ripristina il backup se la sostituzione fallisce. Il metodo restituisce `bool` per rendere visibile l'esito ai chiamanti futuri.
- **Menu:** CONTINUA e salto ai capitoli non proseguono se il salvataggio presente non è leggibile; il pulsante mostra un messaggio e si disabilita.
- **Compatibilità:** mantenuta la gestione dei salvataggi legacy senza sezione squadra.
- **Test eseguiti:** revisione statica dei call site e verifica dei commit su GitHub. Non eseguiti test Godot, test su file corrotti, test di interruzione durante la scrittura o test di recupero backup.
- **Rischio residuo:** la robustezza della sostituzione temporaneo/backup va verificata su Windows e Android; va aggiunta una suite che simuli errori di accesso e file malformati. I dati interni della squadra vengono ancora delegati a `Progress.from_save`, la cui validazione approfondita resta un'attività separata.

### 2026-11-06 — Documentazione installazione e versione

- **File modificati:** `docs/ISTRUZIONI_INSTALLAZIONE.md`, `README.md`.
- **Correzioni:** rimosse istruzioni obsolete sulle vecchie versioni; chiarito che gli aggiornamenti Android richiedono la stessa chiave di firma e che disinstallare può cancellare i salvataggi; aggiornati i riferimenti alla versione di riferimento 0.58.0 e al branch sperimentale.
- **Test eseguiti:** controllo statico dei testi e verifica dei file nel branch. Nessuna pubblicazione o prova di installazione eseguita.


### 2026-11-06 — Validazione approfondita della progressione e recupero backup

- **File modificati:** `scripts/v3/progress.gd`, `scripts/v3/story.gd`, `tests/unit/test_v3_engine.gd`.
- **Progressione:** aggiunta `Progress.validate_save`. Controlla la presenza e il tipo delle sezioni, i quattro personaggi, livelli 1–100, esperienza coerente con il livello, struttura degli slot, ID delle abilità/Ultimate/reazioni/tratti/sinergie e mosse rubate esistenti e non duplicate.
- **Caricamento:** `Story._read_valid_save` valida prima i dati narrativi e la progressione; se il file principale non è leggibile o non supera la validazione, prova `salvataggio.cfg.bak`. La progressione viene applicata soltanto dopo che il file scelto è stato validato.
- **Test aggiunti:** progressione valida; livello oltre il massimo; esperienza oltre la soglia; abilità equipaggiata inesistente; copia di backup; file principale corrotto; recupero degli indizi dal backup; caricamento dopo avanzamento.
- **Pubblicazione itch:** il workflow ora seleziona i pacchetti e richiede che APK e ZIP Windows abbiano la stessa versione numerica; verifica inoltre che lo ZIP contenga almeno un `.exe` e un `.pck`. Gli stessi percorsi/versione selezionati vengono usati per firma e upload, evitando che l'APK più recente venga abbinato a uno ZIP di versione diversa.
- **Test eseguiti:** controllo statico dei sorgenti e dei diff GitHub. I test GDScript sono stati aggiunti ma **non eseguiti**; workflow YAML/GitHub Actions non è stato lanciato. Nessun pacchetto è stato caricato su itch.
- **Rischi residui:** la validazione deve essere provata con salvataggi reali di tutte le versioni legacy. Il recupero dal backup non riscrive automaticamente il file principale: il gioco può continuare dal backup, ma la riparazione persistente avviene al successivo salvataggio. Verificare il comportamento di sostituzione file su Android e Windows. Il workflow continua a usare il primo APK/ZIP più recente per ciascun tipo, ma ora blocca il caricamento se le versioni non corrispondono.


### 2026-11-06 — Ridisegno touch su richiesta e test multitouch

- **File modificati:** `scripts/v3/touch_controls.gd`, nuovo `tests/unit/test_v3_touch_controls.gd`, `README.md`.
- **Ottimizzazione:** rimosso il `queue_redraw()` incondizionato a ogni frame quando i controlli touch sono fermi. Il ridisegno continuo resta attivo solo per pulsanti animati o stick trascinato; modifiche alle etichette e agli stati dei pulsanti, inizio/fine/trascinamento dello stick e reset richiedono il disegno esplicitamente.
- **Correzione inclusa:** al rilascio del dito dello stick viene centrata anche la manopola grafica, non solo azzerato il vettore.
- **Test aggiunto:** due dita contemporanee, movimento stick, delta camera, rilascio generale e azzeramento degli indici. Comando documentato nel README: `godot --headless --path . -s tests/unit/test_v3_touch_controls.gd`.
- **Test eseguiti:** revisione statica e verifica commit. Test GDScript non eseguito; nessuna prova su touchscreen reale.
- **Rischio residuo:** verificare che gli aggiornamenti visivi restino immediati su dispositivi Android e che il comportamento del setter GDScript sia compatibile con Godot 4.7.2. Il risparmio effettivo di CPU/GPU/batteria va misurato sul telefono.


### 2026-11-06 — Mappatura strutturale di battle3d.gd

- **File esaminato:** `scripts/v3/battle3d.gd` (4.915 righe, circa 130 funzioni).
- **Aree individuate nella lettura statica:**
  - bootstrap e arena: `configure`, `_ready`, `_build_arena`, `_setup_battle`, `_build_units`;
  - camera e inquadrature: `_cam_*`, `_cam_fit`, `_cam_glide`, `_damp`;
  - ciclo combattimento e input: `_start_round`, `_advance`, `_command`, `_do_action`, `_boss_turn`, tutorial e guardia a tempo;
  - presentazione degli eventi: `_show_events`, numeri, anelli, scintille, combo, cut-in e animazioni di BREAK;
  - regia narrativa e boss: intro, fasi, battute, telecamera rotta, vittoria e ricompense;
  - HUD e comandi: `_build_ui`, ruota comandi, abilità, HUD, indicatori di minaccia, banner e notifiche;
  - pausa e input globale: `_unhandled_input`, `back`, pausa.
- **Decisione tecnica:** nessuna estrazione automatica in questa fase. Le funzioni condividono molte variabili di scena e riferimenti UI; spostarle in Node/RefCounted separati senza una mappa delle dipendenze rischia regressioni di ordine, tween, segnali e stato.
- **Piano di refactoring sicuro (futuro):** prima inventario delle variabili condivise e dei segnali; poi test di caratterizzazione su una battaglia completa; estrarre prima componenti con confini chiari (HUD/notifiche e camera), lasciando in `battle3d.gd` il coordinamento del turno; un gruppo alla volta, con test prima/dopo e confronto visivo.
- **Miglioria attuale:** mappatura documentata, nessuna modifica architetturale rischiosa.
- **Test eseguiti:** conteggio statico righe/funzioni e lettura delle intestazioni. Nessun refactoring o test runtime.


### 2026-11-06 — Ulteriore hardening progressione e recupero salvataggi

- **File modificati:** `scripts/v3/progress.gd`, `scripts/v3/story.gd`, `tests/unit/test_v3_engine.gd`.
- **Progressione:** la validazione ora confronta ogni equipaggiamento con gli sblocchi effettivamente raggiunti dal personaggio; verifica anche che uno slot abilità contenga una mossa di tipo `skill` e lo slot Ultimate una mossa di tipo `ult`. Le mosse rubate sono ammesse nello slot abilità solo se presenti nell'elenco dei furti.
- **Menu Continua:** `Story.has_save()` riconosce anche il solo backup `.bak`, quindi un'interruzione dopo lo spostamento del file principale non nasconde più la possibilità di recuperare la partita.
- **Scrittura dopo recupero:** se il file principale è invalido, la nuova scrittura lo mette da parte come `.bad` senza sovrascrivere il backup recuperabile prima che il nuovo file sia stato scritto. Se la sostituzione fallisce, il backup valido resta disponibile.
- **Test aggiunti:** equipaggiamento non ancora sbloccato; Ultimate collocata nello slot abilità; recupero quando il file principale manca; rilevamento del solo backup nel menu; conservazione separata del file corrotto durante il successivo salvataggio.
- **Test eseguiti:** lettura statica delle funzioni e confronto dei file su GitHub. I test GDScript non sono stati eseguiti in Godot.
- **Rischi residui:** la validazione degli equipaggiamenti deve essere verificata con salvataggi reali di tutte le build storiche; l'uso di `.bad` conserva il file danneggiato ma non lo ripara. Verificare errori di permessi e interruzioni reali su Windows e Android.


### 2026-11-06 — Audit interazioni combattimento: selettore runtime Stabilità/BREAK

- **File modificati:** `scripts/engine/stability.gd`, `tests/unit/test_v3_break.gd`.
- **Criticità concreta trovata:** `Stability.mark()` rispettava la variabile statica `Stability.enabled`, descritta nel commento del modulo come selettore runtime per test e bilanciamento; `Stability.on()` invece controllava soltanto la costante di build `BattleTypes.STAB_ON` e il flag sul boss. Disattivando il selettore runtime dopo che uno stato era già stato marcato, il sistema continuava quindi a considerare attiva la nuova Stabilità.
- **Correzione:** `Stability.on()` ora richiede sia `enabled` sia `BattleTypes.STAB_ON` e il flag `boss.stab`. La costante continua a decidere se la funzione è inclusa nella build; la variabile statica consente di disattivarla temporaneamente durante test e bilanciamento.
- **Test aggiunto:** stato marcato → selettore runtime OFF → Stabilità inattiva; riattivazione → Stabilità nuovamente attiva.
- **Verifiche eseguite:** ispezione statica delle chiamate a `Stability.mark/on` e della gestione BREAK; aggiunta del test automatico. Nessun test GDScript è stato lanciato con Godot in questa sessione.
- **Copertura già presente rilevata:** test esistenti coprono finestra BREAK in azioni alleate, pressione latente, recupero, cambio fase durante recupero, elite ritardato/indebolito, SBILANCIAMENTO, Slancio protetto e determinismo Timeline. Non sono stati cambiati i valori di bilanciamento o le regole del combattimento.
- **Da verificare a runtime:** esecuzione di `test_v3_break.gd`, `test_v3_timeline.gd`, `test_v3_slancio.gd`, `test_v3_ritmo.gd`; poi stress integrato con cambi fase, KO, scudi e reazioni persistenti tra round.


### 2026-11-06 — Audit telemetria risorse: attribuzione per unità

- **File modificati:** `scripts/engine/resource_telemetry.gd`, `tests/unit/test_v3_resource_telemetry.gd`, `README.md`.
- **Criticità concreta trovata:** `ResourceTelemetry.record()` determinava una sola fonte per l'intera lista eventi, sovrascrivendola ogni volta che incontrava un evento `act` o `duo`. In un'azione che coinvolge più personaggi, il delta di energia/gauge/HYPE di un'unità poteva quindi essere etichettato con l'ultima azione di un altro personaggio. I dati restavano numericamente corretti, ma l'attribuzione per il bilanciamento era fuorviante.
- **Correzione:** la fonte viene ora associata all'unità indicata dall'evento. Se la stessa unità ha più azioni differenti nella medesima lista, la fonte viene indicata come `mista` anziché attribuita arbitrariamente. Le tecniche a due emettono sia `act` sia `duo`: la loro etichetta specifica `duo:<id>` prevale sull'evento generico `act`.
- **Test aggiunti:** attribuzione indipendente a due unità nella stessa lista; priorità dell'etichetta tecnica a due; fonte `mista` quando la stessa unità ha più azioni diverse.
- **Documentazione:** aggiunto in README il comando headless per `test_v3_resource_telemetry.gd`.
- **Verifiche eseguite:** ispezione statica di `ResourceTelemetry.record()` e del formato effettivo degli eventi prodotti da `DuoTechs.run()`; test aggiornati. Non è stato possibile eseguire Godot/headless in questa sessione.
- **Impatto sulle regole:** nessuno. La correzione riguarda esclusivamente i metadati diagnostici `resource_delta.source`; quantità e mutazioni delle risorse non cambiano.
- **Prossimo controllo:** verificare a runtime la suite telemetria e confrontare eventi grezzi e delta snapshot durante tecniche a due, reazioni e transizioni di fase.


### 2026-11-06 — Secondo controllo telemetria: fonte diretta per singola risorsa

- **File modificati:** `scripts/engine/resource_telemetry.gd`, `tests/unit/test_v3_resource_telemetry.gd`.
- **Criticità concreta trovata:** la prima correzione attribuiva la fonte degli eventi `act`/`duo` per unità. Restava un caso: un personaggio che riceve energia come effetto di squadra di una tecnica a due non emette necessariamente un proprio evento `act`; il delta netto snapshot poteva quindi ereditare la fase generica `player_action`, non la fonte effettiva `duo_team`.
- **Correzione:** `ResourceTelemetry.record()` ora considera anche gli eventi diretti `resource_change`, indicizzati per unità e risorsa. La fonte diretta della singola risorsa prevale sull'etichetta generica dell'azione; fonti dirette discordanti per la stessa risorsa vengono marcate `mista`. Rimane il fallback per azioni senza evento diretto.
- **Test aggiunto:** il guadagno effettivo tramite `ResourceTelemetry.gain_unit()` con fonte `duo_team` deve produrre un delta snapshot con la stessa fonte.
- **Verifiche eseguite:** lettura del formato eventi di `DuoTechs.run()` e degli helper `gain_unit/spend_unit`; aggiunta del test. Non eseguito Godot/headless.
- **Impatto:** sola qualità dei dati diagnostici, nessuna modifica a risorse, costi, regole o bilanciamento.
- **Prossimo passo:** controllo della telemetria in caso di più fonti che modificano la stessa risorsa nello stesso passo e verifica integrata delle transizioni Timeline.


### 2026-11-06 — Copertura regressione Timeline: difese e reazioni a cavallo del round

- **File modificato:** `tests/unit/test_v3_timeline.gd`.
- **Verifica statica:** `BattleFlow.finish()` conserva le reazioni selezionate se il round termina prima che il boss agisca; `SeqRound.finish()` usa uno snapshot vuoto quando la Timeline non ha ancora registrato un'azione del boss, così scudi e stati ottenuti nel frattempo vengono inclusi nel carry; `BattleFlow._tl_round()` ripristina reazioni e grado del minigioco dopo `SeqRound.begin()`.
- **Copertura mancante individuata:** la suite Timeline esercitava già le azioni del boss e il normale ciclo dei turni, ma non verificava direttamente il caso in cui un round termina prima della prossima azione del boss e le difese devono restare disponibili.
- **Test aggiunto:** avvio Timeline, assegnazione di uno stato difensivo e scudo, scelta di una reazione con grado `perfect`, fine round senza azione del boss e avvio del round successivo. Le asserzioni verificano durata dello stato, persistenza dello scudo, reazione e grado.
- **Esito:** test scritto, non eseguito con Godot in questa sessione. Non si dichiara quindi verificato il comportamento runtime.
- **Impatto sul gioco:** nessuna modifica alle regole; è stata aggiunta soltanto copertura di regressione.


### 2026-11-06 — Pulizia comandi di regressione nel README

- **File modificato:** `README.md`.
- **Problema documentale trovato durante la verifica:** il comando per la suite BREAK era rimasto attaccato alla riga del nuovo comando telemetria; dopo la separazione era inoltre presente un comando BREAK duplicato.
- **Correzione:** ripristinata una riga autonoma per BREAK con la sua descrizione e una riga autonoma per `test_v3_resource_telemetry.gd`; rimosso il duplicato.
- **Verifica:** rilettura delle righe di comando nel README. Nessun test eseguito.


### 2026-11-06 — Bug Timeline: interruzione del boss a cavallo del round

- **File modificati:** `scripts/engine/battle_flow.gd`, `tests/unit/test_v3_timeline.gd`.
- **Criticità riprodotta tramite lettura del flusso:** `BattleFlow.interrupt()` marca `tl.tele_used = true` per indicare che la mossa annunciata è stata annullata. Se il boss non rientra prima della fine del round, `BattleFlow.finish()` azzerava incondizionatamente quel flag. Nel round seguente `boss_action()` non poteva quindi riconoscere la mossa persa e non avanzava il ciclo prima dell'azione.
- **Correzione:** `finish()` non azzera più `tele_used`. Il flag viene consumato dal percorso `boss_action()`, che annuncia la mossa successiva quando il boss rientra. Il normale percorso dopo un'azione del boss resta invariato perché `_announce_next()` azzera già il flag dopo aver avanzato il ciclo.
- **Test di regressione:** esteso `_interruzione()` per spostare il rientro del boss oltre il confine del round, terminare e riaprire il round, quindi verificare l'avanzamento del ciclo: una mossa annullata viene saltata e viene annunciata quella successiva dopo l'azione eseguita.
- **Verifiche eseguite:** ispezione dei percorsi `interrupt → finish → start_round → boss_action`; test aggiunto. Non eseguito Godot/headless, quindi il test resta da eseguire localmente.
- **Impatto:** corregge la sequenza delle mosse dei boss nella sola condizione di interruzione che attraversa un confine round. Nessuna variazione a costi, danni o bilanciamento.


### 2026-11-06 — Estensione del fix Timeline: interruzione seguita da cambio fase

- **File modificati:** `scripts/engine/battle_flow.gd`, `tests/unit/test_v3_timeline.gd`.
- **Secondo caso limite:** se un'interruzione della mossa del boss attraversa il confine del round e il boss cambia fase nella risoluzione di fine round, `_check_phase()` azzera `cycle_index` a zero, ma il flag di interruzione della fase precedente potrebbe restare attivo. Al rientro, il motore avanzerebbe subito il nuovo ciclo e salterebbe la prima mossa della fase.
- **Correzione:** nel ramo di cambio fase di `BattleFlow.finish()` viene azzerato `tele_used`: l'interruzione apparteneva al ciclo precedente e non deve contaminare quello nuovo. Il flag continua invece a sopravvivere ai normali confini round quando la fase non cambia.
- **Test aggiunto:** caso interruzione oltre round, boss portato sotto la soglia della fase 2, verifica del reset del flag e controllo che la prima azione del nuovo ciclo porti l'indice a 1 (non 2).
- **Verifiche eseguite:** ispezione di `BattleResolver._check_phase()` e della sequenza `finish → start_round → boss_action`; test aggiunto. Nessuna esecuzione Godot/headless.
- **Impatto:** evita che un'interruzione del vecchio ciclo alteri il primo attacco della fase successiva. Nessuna variazione a danni o parametri di fase.

### 2026-11-06 — Salvataggi: mantenimento del checkpoint di recupero

- **File modificati:** `scripts/v3/story.gd`, `tests/unit/test_v3_engine.gd`.
- **Criticità concreta trovata nel secondo audit:** la routine `Story.save()` ruotava correttamente il salvataggio valido precedente in `.bak`, ma subito dopo eliminava il backup appena creato. Il recupero funzionava solo se l'app si interrompeva durante la sostituzione del file; non restava invece un checkpoint valido dopo un salvataggio completato, quindi una corruzione successiva del file principale non avrebbe avuto un backup aggiornato.
- **Correzione applicata:** il backup precedente viene conservato dopo il completamento della scrittura. Al salvataggio successivo, se il file principale è valido, il backup più vecchio viene sostituito dal precedente principale valido. Se il principale è invalido, viene isolato in `.bad` e l'eventuale backup valido non viene sovrascritto.
- **Test di regressione aggiunti:** dopo un avanzamento, verificare che `.bak` esista ancora, sia leggibile e contenga il passo precedente al nuovo salvataggio.
- **Verifiche eseguite:** confronto statico del percorso `save → backup → rename` e aggiornamento del test automatico. Il test non è stato eseguito con Godot; non si dichiara superato.
- **Rischi residui:** il backup è un singolo checkpoint, non una cronologia; non sostituisce backup esterni. Le operazioni di rinomina e rimozione dipendono dal filesystem della piattaforma e devono essere collaudate su Android e Windows.
- **Prossimo test locale:** eseguire `godot --headless --path . -s tests/unit/test_v3_engine.gd`; poi simulare una chiusura forzata tra la rotazione del file e il rename finale, su una copia del salvataggio di test.

### 2026-11-06 — Benchmark 3D: identificazione dell'hardware

- **File modificato:** `tools/v3_prestazioni.gd`.
- **Miglioria:** l'intestazione del report ora registra anche modello del dispositivo e nome della GPU, oltre a versione Godot, sistema operativo, viewport, limite FPS configurato, warm-up e numero di campioni.
- **Motivo:** i risultati di frame time e draw call non sono confrontabili in modo affidabile se manca l'identificazione del dispositivo/driver. Il report specifica inoltre che il campionamento avviene senza cap FPS, per distinguere il limite di progetto dalla misurazione del margine prestazionale.
- **Verifica:** modifica statica controllata sul formato della stringa e sugli argomenti. Benchmark non eseguito; i valori reali restano da raccogliere su PC e Android.

### 2026-11-06 — Validazione progressione: valori interi e metadati delle mosse rubate

- **File modificati:** `scripts/v3/progress.gd`, `tests/unit/test_v3_engine.gd`.
- **Criticità trovata:** la validazione accettava livelli ed esperienza di tipo float e li convertiva a intero con `int()`. Un valore corrotto come livello `1.5` poteva quindi essere accettato come livello 1. Inoltre `stolen_from` veniva controllato solo come tipo Dictionary: poteva contenere riferimenti a mosse inesistenti/non possedute o fonti con tipo errato.
- **Correzione:** rifiutati valori NaN/Inf e valori frazionari per livello/esperienza; i numeri interi restano accettati anche se serializzati come float integrale. I metadati `stolen_from` vengono verificati: ogni chiave deve essere una mossa effettivamente presente in `stolen` e ogni fonte deve essere una stringa. Non viene imposto che ogni mossa abbia una fonte, per mantenere compatibilità con eventuali salvataggi storici incompleti.
- **Test aggiunti:** livello frazionario, esperienza frazionaria e fonte orfana/non valida.
- **Verifica:** controllo statico del flusso di validazione e aggiornamento dei test. Godot non è stato eseguito; non si dichiara superamento.
- **Rischio residuo:** verificare la disponibilità di `is_finite()` nella versione Godot 4.7.2 e l'esecuzione del test engine sul progetto completo. I salvataggi legacy con metadati di fonte non stringa o riferimenti orfani verranno rifiutati e tentato il recupero dal backup.


### 2026-11-06 — Coerenza della previsione Timeline con i turni bonus

- **File modificati:** `scripts/engine/battle_flow.gd`, `tests/unit/test_v3_timeline.gd`.
- **Criticità trovata:** `BattleFlow.preview()` non rispecchiava completamente `BattleFlow.next()`. Non mostrava gli SLANCI protetti già pronti, benché `next()` li esegua prima del prossimo slot ordinario. Inoltre aggiungeva alla previsione tutti i turni extra di `tl.extra` senza verificare se il personaggio potesse ancora giocare: un personaggio KO poteva quindi comparire nella Timeline mostrata pur venendo correttamente saltato dall'esecuzione.
- **Correzione:** la previsione include gli SLANCI protetti pronti, ordinandoli in base al prossimo istante dello slot; controlla l'idoneità dei turni extra con la stessa `_can_play()` usata dal motore. La lettura degli SLANCI protetti è volutamente non mutante: non usa `Slancio.ready_kept()`, che elimina dal dizionario i bersagli sconfitti.
- **Test aggiunti:** SLANCIO protetto presente in prima posizione della previsione; previsione senza consumo/modifica dello stato salvato; turno extra di un personaggio KO escluso.
- **Verifiche:** confronto statico dei percorsi `preview → _pick` e `next → ready_kept/_can_play`; test aggiunti ma non eseguiti con Godot.
- **Impatto:** solo accuratezza della Timeline mostrata; nessuna modifica a costi, danni, risorse o regole di combattimento.


- **Ulteriore discrepanza rilevata nello stesso controllo:** quando tutti gli slot ordinari erano già completati e non restavano turni extra validi, `preview()` continuava a simulare gli slot riprogrammati del round successivo. `next()`, invece, termina il round. La previsione ora si ferma quando `_all_done()` è vero e non esiste un bonus giocabile; se i bonus presenti sono invalidi, li scarta e termina senza mostrare turni ordinari fuori dal round.
- **Test esteso:** dopo aver marcato completati tutti gli slot, la previsione contiene soltanto lo SLANCIO protetto già pronto e non inventa turni ordinari oltre la fine del round.


### 2026-11-06 — Telemetria delle risorse nel cambio fase

- **File modificati:** `scripts/engine/resource_telemetry.gd`, `tests/unit/test_v3_resource_telemetry.gd`.
- **Criticità trovata:** durante il cambio fase, `BattleResolver._check_phase()` registra direttamente spese EN e guadagni barra con fonte `phase_change`; tuttavia `ResourceTelemetry.record(..., "phase_transition")` saltava interamente l'analisi degli eventi diretti e attribuiva i delta alla fase generica. La lista eventi contiene anche eventi del round precedente, quindi non era corretto riutilizzare indiscriminatamente le fonti delle azioni precedenti.
- **Correzione:** nel solo percorso `phase_transition`, la telemetria considera esclusivamente gli eventi `resource_change` la cui fonte è esattamente `phase_change`. Le altre fonti già presenti nella lista vengono ignorate per questa attribuzione.
- **Test aggiunto:** la spesa EN e il guadagno gauge del cambio fase mantengono la fonte `phase_change`, anche quando la stessa lista contiene un evento risorsa precedente con fonte diversa.
- **Verifiche:** lettura statica di `BattleResolver._check_phase()`, `SeqRound.finish()` e `ResourceTelemetry.record()`; test aggiunto ma non eseguito con Godot.
- **Impatto:** solo qualità della telemetria; nessuna modifica ai valori o all'applicazione delle risorse.
