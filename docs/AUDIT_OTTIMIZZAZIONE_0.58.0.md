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


### 2026-11-06 — Timeline: slot non giocabili nella previsione

- **File modificati:** `scripts/engine/battle_flow.gd`, `tests/unit/test_v3_timeline.gd`.
- **Criticità trovata:** nella simulazione di `BattleFlow.preview()`, uno slot eroe non giocabile veniva marcato come completato ma non riprogrammato. `_pick()` continua a considerare tutti gli slot, quindi il medesimo slot restava il più vicino e veniva selezionato ripetutamente fino al limite di sicurezza del ciclo: la previsione poteva fermarsi e nascondere gli altri turni. La stessa simulazione non cancellava lo slot del gregario sconfitto, a differenza di `_tl_next()`.
- **Correzione:** la previsione riprogramma lo slot non giocabile con il costo Attacco e la velocità correnti, azzerando modificatori temporanei e priorità come `_schedule_from()`; rimuove gli slot di gregari sconfitti. Anche la simulazione degli slot giocati ora azzera i modificatori `a/r` e la priorità dopo la riprogrammazione.
- **Test aggiunto:** con tutti i membri di uno slot KO e il suo turno in testa, la previsione deve comunque proseguire e mostrare un altro giocatore vivo.
- **Verifiche:** confronto statico fra `preview()` e `_tl_next()`; test aggiunto ma non eseguito con Godot.
- **Impatto:** accuratezza della previsione Timeline; nessuna modifica alle azioni realmente eseguite, al bilanciamento o alle risorse.


### 2026-11-06 — Transizioni multiple delle fasi boss nello stesso round

- **File modificati:** `scripts/engine/battle_resolver.gd`, `tests/unit/test_v3_break.gd`.
- **Criticità trovata:** `_phase_of()` calcola correttamente la fase finale in base ai PV, ma `_check_phase()` applicava gli effetti una sola volta. Un singolo attacco che portava il boss sotto il 25% dei PV poteva passare direttamente dalla fase 1 alla 3, saltando gli effetti della fase 2.
- **Correzione:** il cambio fase ora attraversa in ordine tutte le fasi mancanti. Per ogni transizione applica incremento della barra BREAK, evento fase, scudo, consumo Riserva se previsto dalla configurazione e variazioni EN/Ultimate alla squadra viva. La gestione di BREAK/recupero viene eseguita una sola volta dopo l'aggiornamento del massimo della barra, evitando di completare più volte il recupero.
- **Test aggiunto:** boss portato direttamente al 20% dei PV; verifica fase finale 3, eventi fase 2 e 3 in ordine, doppio incremento BREAK, doppio scudo, doppio premio Ultimate e doppio costo EN.
- **Verifiche:** ispezione statica delle soglie (`50%` e `25%`), delle costanti di fase e di `Stability.on_phase()`; test aggiunto ma non eseguito con Godot.
- **Impatto:** ripristina gli effetti delle soglie effettivamente attraversate; non cambia le soglie, i valori per singola fase o il bilanciamento.


### 2026-11-06 — Audit Interruzione e SBILANCIAMENTO

- **File di test aggiornato:** `tests/unit/test_v3_break.gd`.
- **Verifiche statiche:** la reazione `interruzione` è valida solo contro una carica pesante, non è disponibile se il boss è stordito, spende la Riserva, applica pressione alla barra e assegna SBILANCIAMENTO solo se il QTE non fallisce. Il limite di una Interruzione per round è applicato alla lista delle reazioni.
- **Timeline:** la finestra BREAK viene consumata dalle azioni ordinarie alleate, non dalle azioni rapide SLANCIO; la mossa del boss viene saltata tramite lo stordimento prodotto dal BREAK. La funzione `BattleFlow.interrupt()` è un'operazione distinta di riprogrammazione slot, già coperta dai test Timeline; non va invocata automaticamente dalla reazione `interruzione`, perché il suo effetto di perdita/ritardo della mossa è condizionato al BREAK.
- **Test aggiunti:** QTE riuscito, QTE fallito, guadagno Ultimate, costo Riserva, blocco della seconda Interruzione nello stesso round e pressione ridotta in caso di fallimento.
- **Esito:** nessuna modifica alle regole di combattimento; aumentata la copertura di regressione. Test scritto ma non eseguito con Godot.


### 2026-11-06 — Previsione Timeline duplicava il turno corrente

- **File modificati:** `scripts/engine/battle_flow.gd`, `tests/unit/test_v3_timeline.gd`.
- **Criticità:** `preview()` aggiungeva il turno corrente all'anteprima, ma lasciava invariato lo slot nella simulazione. Il successivo `_pick()` poteva quindi selezionare nuovamente lo stesso slot come prossimo turno, prima che il personaggio avesse completato il turno corrente.
- **Correzione:** la simulazione consuma il turno corrente ordinario e ne riprogramma lo slot usando il costo ATTACCO di riferimento, senza modificare la Timeline reale. Se il turno corrente è un'azione rapida già separata dallo slot ordinario, la simulazione non lo riprogramma una seconda volta. Per boss e gregario usa il costo nemico.
- **Test aggiunto:** con velocità uniformi verifica che il turno corrente resti in testa, che il prossimo slot non duplichi il personaggio corrente e che la chiamata non modifichi lo stato reale.
- **Verifiche:** controllo statico di `_tl_next()`, `_schedule_from()` e `_tl_player()`; test aggiunto ma non eseguito con Godot.
- **Impatto:** solo visualizzazione/anteprima della Timeline; nessuna modifica all'ordine reale, al bilanciamento o alle azioni di combattimento.

- **Controllo aggiuntivo della correzione:** la riprogrammazione della copia simulata usa un contatore `stamp` locale; non richiama il mutatore `_schedule_from()` sulla Timeline reale. Il test ora controlla anche che `tl.stamp` e il tempo dello slot corrente restino invariati dopo `preview()`. Setup del test reso deterministico (eroi VEL 120, boss VEL 60).


### 2026-11-06 — Anteprima recupero dopo SLANCIO

- **File:** `scripts/engine/battle_flow.gd`, `tests/unit/test_v3_timeline.gd`.
- **Criticità:** quando la Timeline aveva già selezionato l'azione rapida dello SLANCIO, `preview()` mostrava correttamente l'azione corrente ma non anticipava nella copia simulata il +15 al recupero applicato da `_tl_player()` dopo la risoluzione. La previsione poteva quindi indicare un ordine successivo diverso da quello reale.
- **Correzione:** per la voce corrente `cur_quick`, la simulazione aggiunge il costo solo se è uno SLANCIO e `waive` è falso. Gli SLANCI protetti con esenzione non ricevono il costo. La modifica avviene esclusivamente sulla copia degli slot.
- **Test aggiunti:** ordine previsto con slot concorrente tra recupero base e recupero maggiorato; invarianza dello slot reale; rispetto dell'esenzione `waive`.
- **Test Godot:** non eseguiti in questa sessione.


## Fase 3 — Controlli touch (audit statico iniziale)

### 2026-11-06 — Recupero input dopo perdita di focus

- **File:** `scripts/v3/touch_controls.gd`; esteso il test esistente `tests/unit/test_v3_touch_controls.gd`.
- **Criticità:** i controlli memorizzano l'indice del dito che controlla stick e camera. Se Android/iOS interrompe la scena o la finestra perde focus mentre il dito è premuto, il relativo evento di rilascio potrebbe non arrivare; gli indici resterebbero attivi e lo stick/camera potrebbero rimanere bloccati.
- **Correzione:** `_notification()` intercetta la perdita di focus applicativa e della finestra e richiama `release_all()`, azzerando stick, delta camera e indici touch.
- **Test aggiunto:** esteso il test touch già presente con una simulazione di perdita di focus e verifica del reset completo. La copertura preesistente di stick, multitouch e trascinamento camera è stata mantenuta.
- **Non verificato:** comportamento su dispositivo Android/iOS reale, rotazione, notch/aree sicure, risoluzioni e frame-time. I test Godot non sono stati eseguiti in questa sessione.
- **Prossimi controlli touch:** scaling coordinate/viewport, input cancellato durante pause e transizioni, hitbox e aree sicure.


### 2026-11-06 — Controlli touch: reset anche alla pausa applicativa

- **File modificati:** `scripts/v3/touch_controls.gd`, `tests/unit/test_v3_touch_controls.gd`.
- **Ulteriore criticità considerata:** sui dispositivi mobili la sospensione dell'applicazione (per esempio passaggio in background, schermata di blocco o apertura di un'interfaccia di sistema) può essere notificata come pausa applicativa e non necessariamente come semplice perdita di focus. Affidarsi soltanto a `APPLICATION_FOCUS_OUT` lascia una dipendenza non necessaria dall'ordine/tipo di notifiche emesse dal sistema operativo.
- **Correzione:** il reset dei controlli viene eseguito anche su `NOTIFICATION_APPLICATION_PAUSED`, oltre che su perdita di focus applicativa e della finestra. La routine resta centralizzata in `release_all()`: non introduce logica duplicata e non altera il comportamento durante il normale gioco.
- **Perché questa correzione:** impedire che, tornando da una pausa di sistema, un dito precedentemente registrato continui a generare movimento o trascinamento camera senza un nuovo tocco.
- **Test implementati e funzionamento:**
  1. **Focus applicativo perso:** prepara indici touch e vettori non nulli, invoca la notifica e controlla che entrambi gli indici tornino a `-1`, stick e delta camera a `Vector2.ZERO`, manopola al centro.
  2. **Applicazione messa in pausa:** ripete la stessa preparazione con valori diversi, invoca `NOTIFICATION_APPLICATION_PAUSED` e controlla gli stessi invarianti. Serve a verificare il percorso specifico di sospensione mobile.
  3. **Finestra senza focus:** simula `NOTIFICATION_WM_WINDOW_FOCUS_OUT` e verifica che anche su desktop il reset sia completo.
  4. **Regressione dei gesti:** i test già presenti continuano a simulare pressione/trascinamento simultaneo a sinistra e destra, controllo dello stick, delta camera e rilascio generale; non vengono sostituiti.
- **Risultato atteso:** dopo ognuna delle tre notifiche nessun dito resta acquisito, nessun input residuo viene consumato e il successivo gesto parte da uno stato neutro. Il test segnala ogni singola condizione fallita, così è possibile identificare quale stato non è stato ripristinato.
- **Verifica effettiva in questa sessione:** ispezione statica della gestione input e aggiornamento del test. Il test GDScript non è stato eseguito con Godot; i risultati sopra sono criteri attesi, non un esito dichiarato.
- **Limiti ancora aperti:** coordinate e scaling sono coerenti solo se gli eventi e il Control condividono il medesimo spazio viewport; il controllo statico ha rilevato che il Control è ancorato a tutto il viewport tramite `Ui.place(self, 0, 0, 1, 1)`, ma non sostituisce una prova su dispositivi con aspect ratio, notch e safe area differenti. Non è stato possibile individuare un collegamento diretto a `TouchControls.handle()` nei file esaminati di `battle3d.gd`; il punto d'ingresso effettivo va tracciato prima di modificare coordinate o hitbox.


## Fase 4 — Struttura progetto e protezione della pubblicazione

### 2026-11-06 — Blocco del workflow itch.io sui branch non di release

- **File modificato:** `.github/workflows/itch.yml`.
- **Criticità trovata:** il trigger automatico `push` era già limitato a `claude/v3-prologo`, ma `workflow_dispatch` è disponibile anche quando si apre il workflow da un altro branch. Il job di pubblicazione non controllava il branch di esecuzione: un avvio manuale accidentale dalla branch sperimentale avrebbe potuto caricare su itch.io gli artefatti presenti in quel branch.
- **Correzione:** aggiunta una condizione al job `itch` che lo esegue soltanto se `github.ref` è esattamente `refs/heads/claude/v3-prologo`. I trigger e i controlli di firma/versione già esistenti restano invariati.
- **Perché:** separare in modo esplicito audit e sperimentazione dalla pubblicazione, riducendo il rischio di distribuire una build non approvata. La modifica non avvia workflow, non carica file e non pubblica nulla.
- **Test/controlli implementati e funzionamento:** non è stato aggiunto un test applicativo. La verifica è una condizione di sicurezza CI: GitHub valuta il riferimento del branch prima di avviare il job. Sul branch autorizzato la condizione è vera; su qualsiasi altro branch, incluso `experiment/0.58.0-audit-ottimizzazione`, il job viene saltato.
- **Risultato atteso:** un push o un dispatch eseguito dal branch sperimentale non può eseguire il job di upload itch.io; il branch di release conserva il comportamento previsto.
- **Verifica effettiva:** controllo statico del trigger, del nome del branch configurato e della condizione inserita. Non è stato avviato un workflow GitHub Actions e non è stata effettuata alcuna pubblicazione.
- **Rischio residuo:** la condizione protegge il job, ma non sostituisce le protezioni GitHub sul branch di release né una revisione umana degli artefatti. Prima di una release reale va verificato il comportamento con un dispatch autorizzato sul branch corretto, senza usare pacchetti non approvati.


### 2026-11-06 — Controlli touch: rilascio forzato entrando in dialogo o pausa

- **File modificati:** `scripts/v3/touch_controls.gd`, `scripts/v3/area.gd`, `tests/unit/test_v3_touch_controls.gd`.
- **Criticità riprodotta tramite lettura del flusso:** `Area._input()` inoltra gli eventi a `TouchControls.handle()` soltanto quando `mode == "walk"` e la pausa non è aperta. In dialogo/pausa ritorna prima. Se un dito è stato acquisito dallo stick o dalla camera e il dialogo/la pausa si apre prima del rilascio, l'evento di rilascio può non raggiungere il controller. `Area._process()` smette correttamente di muovere il personaggio, ma senza pulizia lo stato touch può sopravvivere e bloccare l'acquisizione del gesto successivo o riattivare un input residuo al ritorno all'esplorazione.
- **Correzione:** aggiunto `TouchControls.has_active_input()`, che rileva indici dito acquisiti e vettori/manopola non neutri. Nel ramo non esplorabile di `Area._process()`, se esiste input residuo viene chiamato `release_all()`. La pulizia avviene solo quando serve, non ogni frame, e riutilizza la stessa routine già usata per la perdita di focus/pausa del sistema.
- **Perché:** i dialoghi e la pausa devono sospendere davvero i comandi di movimento e camera; alla chiusura il giocatore deve ripartire da input neutri e poter iniziare un nuovo gesto senza dover ripetere o sbloccare il precedente.
- **Test implementati e funzionamento:**
  1. Dopo la pressione dello stick il test verifica che `has_active_input()` riconosca lo stato acquisito.
  2. Dopo `release_all()` verifica che lo stesso metodo ritorni falso, insieme agli indici a `-1` e ai vettori/manopola azzerati.
  3. I test precedenti continuano a coprire stick, camera, multitouch e reset su pausa/focus. La logica di `Area._process()` è verificata staticamente: quando `exploring` è falso e lo stato è attivo deve eseguire il reset; quando è già neutro non richiama inutilmente la pulizia.
- **Risultato atteso:** entrando in dialogo o pausa, qualsiasi input touch acquisito viene cancellato entro il successivo aggiornamento del frame; uscendo, il primo nuovo tocco viene riconosciuto normalmente e non produce movimento/camera fantasma.
- **Verifica effettiva:** lettura incrociata di `Area._input()`, `Area._process()`, `Area._walk()` e del ciclo di vita di `TouchControls`; aggiornati codice e test. Nessun test Godot è stato eseguito in questa sessione.
- **Rischi residui:** resta da provare su Android la sequenza fisica pressione-stick → apertura dialogo/pausa → rilascio durante overlay → chiusura → nuovo tocco, oltre alla stessa sequenza iniziata con il trascinamento camera.


### 2026-11-06 — Mappa delle responsabilità del controller battaglia monolitico

- **File analizzato:** `scripts/v3/battle3d.gd` (4.915 righe, circa 217 KB nel branch esaminato).
- **Criticità strutturale:** lo stesso Node3D contiene costruzione arena/unità, gestione camera, avanzamento round e azioni, tutorial/QTE, risoluzione e presentazione eventi, effetti/cutin/animazioni, dialoghi rapidi, HUD/menu comandi, pausa e schermata vittoria. La quantità di responsabilità nello stesso file aumenta il costo di ogni modifica e rende più difficile isolare regressioni tra logica di combattimento, presentazione e input.
- **Verifica eseguita:** inventario statico di classi, segnali e funzioni con numeri di riga; confronto con la struttura descritta nel README. Non è stato modificato il file monolitico e non è stata spostata logica.
- **Perché non è stata eseguita una divisione automatica:** questo file coordina molte sequenze asincrone e dipendenze tramite stato condiviso. Spostare metodi senza prima mappare le variabili lette/scritte, i segnali e l'ordine delle coroutine potrebbe cambiare tempi di animazione, ordine degli eventi o comportamento dei comandi. Una riduzione delle righe senza test d'integrazione non sarebbe una miglioria dimostrabile.
- **Piano di miglioramento proposto per fasi, senza cambiare il comportamento:**
  1. estrarre prima il solo rendering degli effetti numerici/eventi in un componente dedicato, mantenendo un'interfaccia stretta e gli stessi parametri;
  2. estrarre successivamente HUD e costruzione dei menu, senza trasferire la proprietà dello stato battaglia;
  3. valutare camera/cutin solo dopo aver tracciato tutte le chiamate e le animazioni asincrone;
  4. lasciare in `battle3d.gd` il coordinamento della scena e le chiamate al motore, evitando un refactor simultaneo del motore.
- **Test necessari prima/dopo ogni estrazione:** test unitari del motore già presenti; esecuzione completa dell'Atto 1 in AUTO; confronto degli eventi di battaglia e degli stati finali; verifica manuale di comandi touch/PC, QTE, cutin, BREAK, SLANCIO, vittoria e ritorno alla storia. I report/screenshot devono essere confrontati con la release 0.58.0.
- **Risultato atteso del piano:** ridurre l'accoppiamento e rendere più sicuri gli interventi futuri, mantenendo invariati gameplay, tempi, UI e presentazione. Nessun risultato di refactor viene dichiarato perché in questa fase è stata prodotta soltanto la mappa delle responsabilità.

## Fase 5 — Salvataggi e regressione

### 2026-11-06 — Validazione dello stato dell'area e test di recupero backup

- **File modificati:** scripts/v3/story.gd; nuovo test tests/unit/test_v3_integrita_salvataggio.gd.
- **Criticità trovata:** Story._read_valid_save() controllava che storia.area fosse un Dictionary, ma non verificava i tipi dei suoi campi. L'area usa pos come Vector3, yaw come numero, clues e defeated come Array e banter_used come Dictionary. Un file leggibile ma con campi corrotti poteva superare il controllo iniziale e fallire più avanti durante la costruzione dell'area o ripristinare dati incoerenti.
- **Correzione:** introdotta Story.validate_area_state(). Controlla il tipo della posizione e la finitezza delle coordinate, il tipo numerico e la finitezza di yaw, le liste di identificativi testuali per indizi/nemici e il dizionario booleano delle chiacchiere già usate. I campi restano opzionali per compatibilità con salvataggi precedenti; vengono controllati soltanto quando presenti. _read_valid_save() ora rifiuta un file con stato area malformato, così load_game() può tentare il backup.
- **Perché:** intercettare la corruzione al confine di caricamento invece di lasciarla emergere più tardi in un punto del gioco difficile da diagnosticare. La validazione è strutturale e non impone limiti arbitrari alle coordinate o agli ID futuri.
- **Test implementati e funzionamento:**
  1. **Schema valido:** passa un dizionario con Vector3, yaw, indizi, nemici e chiacchiere nei tipi previsti; deve essere accettato.
  2. **Campi malformati:** sostituisce un campo alla volta con tipo errato (posizione testuale, yaw testuale, lista non-array, ID numerico, registro non-dizionario e valore non booleano); ogni caso deve essere rifiutato.
  3. **Recupero backup su file di test:** imposta Story.save_path su un file dedicato in user://, scrive due salvataggi validi e verifica che il secondo conservi il primo come .bak. Poi sovrascrive il principale con testo corrotto e invoca Story.load_game(): deve caricare il backup, ripristinare flag e posizione precedenti e non caricare il checkpoint successivo. I file di prova vengono rimossi al termine.
  4. **Rifiuto prima dell'uso:** costruisce un ConfigFile con progressione valida ma area.pos testuale e verifica che _read_valid_save() lo rifiuti prima che l'area tenti di usarlo.
- **Risultato atteso:** un salvataggio con dati area malformati non raggiunge il codice di gioco; se il principale è corrotto ma il backup è valido, la partita precedente resta recuperabile. I test usano un percorso dedicato e non devono sovrascrivere il salvataggio del giocatore.
- **Verifica effettiva:** ispezionati Story.save/load_game, il ripristino in Area._build_party e Area._build_ui e la struttura effettiva di Banter._used; aggiunti validatore e test. I test non sono stati eseguiti con Godot in questa sessione.
- **Limiti residui:** la validazione verifica struttura e tipi, non che ogni ID appartenga all'area corrente: tale controllo richiede di caricare i dati dell'area associata al passo corrente e va trattato separatamente per non rifiutare salvataggi di versioni precedenti o contenuti futuri.


### 2026-11-06 — Coerenza del checkpoint conclusivo

- **File modificati:** scripts/v3/story.gd; tests/unit/test_v3_integrita_salvataggio.gd.
- **Criticità trovata:** il validatore accettava qualsiasi valore non negativo di passo quando capitolo era uguale al numero dei capitoli. Il flusso normale di Story.advance() produce invece un solo stato terminale canonico: capitolo == numero capitoli e passo == 0. Valori diversi non corrispondono ad alcun checkpoint realmente raggiungibile.
- **Correzione:** _read_valid_save() rifiuta il salvataggio terminale se passo non è zero; non cambia la gestione dei capitoli intermedi.
- **Perché:** impedire che dati incoerenti vengano trattati come una partita conclusa valida e rendere esplicita la forma dello stato finale.
- **Test implementati e funzionamento:** la fixture ConfigFile viene salvata prima con capitolo conclusivo e passo 1 (deve essere rifiutata), poi con lo stesso capitolo e passo 0 (deve essere accettata). Il test usa il numero di capitoli caricato dai dati reali, quindi non codifica a mano il numero dell'Atto.
- **Risultato atteso:** gli stati terminali prodotti dal gioco restano caricabili; checkpoint terminali inventati/corrotti non superano la validazione.
- **Verifica effettiva:** controllo statico di Story.advance() e aggiornamento del test. Nessuna esecuzione Godot effettuata.


### 2026-11-06 — Comandi di regressione aggiornati nel README

- **File modificato:** README.md.
- **Miglioria:** aggiunto il comando headless per eseguire test_v3_integrita_salvataggio.gd accanto ai comandi unitari già documentati.
- **Perché:** un test nuovo ma non facilmente individuabile rischia di non entrare nella routine di verifica locale. Il comando rende esplicito come lanciarlo con la stessa modalità usata dagli altri test SceneTree.
- **Cosa esegue:** controlli dei tipi dello stato area, rifiuto dei dati malformati, coerenza del checkpoint conclusivo e recupero del backup dopo corruzione del file principale. Usa un file user:// dedicato.
- **Risultato atteso:** uscita con codice 0 e messaggio test_v3_integrita_salvataggio: OK se tutti gli assert passano; codice 1 e messaggi FAIL in caso contrario.
- **Verifica effettiva:** verificata la coerenza del comando con la convenzione degli altri test nel README. Non eseguito perché questa sessione non dispone del runtime Godot del progetto.


### 2026-11-06 — Validazione stretta dei numeri di capitolo e passo

- **File modificati:** scripts/v3/story.gd; tests/unit/test_v3_integrita_salvataggio.gd.
- **Criticità trovata:** _read_valid_save() convertiva direttamente capitolo e passo con int(...). Una stringa numerica o un float frazionario potevano essere convertiti/troncati prima del controllo dei limiti, nascondendo un dato salvato con tipo o valore non valido.
- **Correzione:** aggiunto _is_valid_save_integer(): accetta soltanto int o float finiti, non negativi e senza parte frazionaria. La conversione a int avviene soltanto dopo la validazione.
- **Perché:** il checkpoint deve essere un indice intero reale; una conversione permissiva può trasformare dati corrotti in un checkpoint diverso da quello scritto.
- **Test implementati e funzionamento:** esteso il test di integrità con tre fixture ConfigFile: capitolo memorizzato come stringa, passo frazionario 0.5 e passo NaN. Ogni fixture viene caricata tramite _read_valid_save() e deve essere rifiutata. Le fixture sono scritte nel percorso temporaneo dedicato del test.
- **Risultato atteso:** nessun valore testuale, frazionario o non finito viene silenziosamente convertito in indice di progressione; i valori interi validi continuano a essere accettati.
- **Verifica effettiva:** controllo statico del formato scritto da Story.save() e aggiornamento di validatore e regressione. Test non eseguiti con Godot in questa sessione.


### 2026-11-06 — Estensione regressione per coordinate e rotazioni non finite

- **File modificato:** tests/unit/test_v3_integrita_salvataggio.gd.
- **Perché:** il validatore di area rifiuta già NaN e infinito per posizione e yaw; i test precedenti coprivano i tipi errati ma non i valori numerici non finiti. Questi valori possono propagarsi in trasformazioni 3D e produrre posizioni/camera non valide.
- **Test implementati e funzionamento:** aggiunti casi con Vector3(NAN, 0, 0), Vector3(0, INF, 0) e yaw INF. Ogni caso passa da Story.validate_area_state() e deve essere rifiutato. Non si modifica il validatore né il comportamento di gioco.
- **Risultato atteso:** nessuna coordinata o rotazione non finita può superare il controllo del salvataggio.
- **Verifica effettiva:** test aggiunti e confronto statico con i controlli is_finite già presenti; esecuzione Godot non effettuata.


### 2026-11-06 — Validazione del temporaneo prima di sostituire il salvataggio principale

- **File modificati:** scripts/v3/story.gd; tests/unit/test_v3_integrita_salvataggio.gd.
- **Criticità trovata:** Story.save() scriveva il temporaneo e poi lo promuoveva a file principale senza verificare che il nuovo contenuto superasse _read_valid_save(). Il backup precedente restava disponibile, ma un errore nello stato in memoria poteva comunque sostituire il salvataggio principale con un file che il caricatore avrebbe subito rifiutato.
- **Correzione:** dopo la scrittura del .tmp, Story.save() lo rilegge con lo stesso validatore del caricamento. Se non è valido, elimina il temporaneo e ritorna false prima di rinominare il file principale o il backup.
- **Perché:** applicare la stessa regola in scrittura e lettura; non promuovere mai dati che il gioco non sarebbe in grado di caricare. Il controllo è prima della rotazione dei file, così il checkpoint valido resta intatto.
- **Test implementati e funzionamento:** il test crea un salvataggio valido, modifica lo stato area in memoria inserendo una posizione testuale, tenta un secondo salvataggio e verifica: ritorno false, file principale ancora valido, temporaneo rimosso e checkpoint precedente ancora caricabile.
- **Risultato atteso:** un errore nei dati in memoria non può rimpiazzare il salvataggio principale con un file non caricabile; il giocatore conserva il checkpoint precedente.
- **Verifica effettiva:** confronto statico dell'ordine delle operazioni di scrittura/rinomina e aggiunta della regressione. Test non eseguito con Godot in questa sessione.


### 2026-11-06 — Regressione per progressione corrotta durante il salvataggio

- **File modificato:** tests/unit/test_v3_integrita_salvataggio.gd.
- **Audit:** il validatore del file completo delega la sezione squadra a Progress.validate_save(). Dopo aver aggiunto la validazione del temporaneo prima della rotazione, è importante coprire anche un errore nella progressione in memoria, non soltanto un'area malformata.
- **Test implementato:** crea un checkpoint valido, imposta temporaneamente il livello di Lance oltre Progress.MAX_LEVEL, tenta il salvataggio e verifica che venga rifiutato. Poi verifica che il file principale resti valido, che il checkpoint precedente sia caricabile e che il livello precedente venga ripristinato. Infine ripristina Progress per isolare il resto del test.
- **Perché:** verifica l'integrazione fra Story.save(), _read_valid_save() e Progress.validate_save(), non solo il validatore dell'area.
- **Risultato atteso:** qualsiasi progressione che non supera la validazione impedisce la promozione del temporaneo e non distrugge il checkpoint valido.
- **Verifica effettiva:** controllo statico del percorso di validazione e aggiunta del test. Nessuna esecuzione Godot effettuata.


### 2026-11-06 — Cache limitata delle geometrie piatte ricorrenti

- **File modificati:** scripts/v3/mesh_batch.gd; tests/unit/test_v3_mesh_batch.gd; README.md.
- **Area audit:** prestazioni 3D e allocazioni durante la costruzione delle scene.
- **Criticità trovata:** MeshBatch.disc() generava una nuova ArrayMesh a ogni chiamata, anche quando raggio, colore, numero di segmenti e altezza erano identici. La funzione viene usata per ombre dei personaggi, ombre e indicatori dei nemici, indizi e uscite. La geometria è immutabile dopo la costruzione e può essere condivisa fra più MeshInstance3D.
- **Correzione:** introdotta una cache statica con chiave composta da tutti i parametri geometrici/visivi. Le chiamate con parametri identici riutilizzano la stessa ArrayMesh; le varianti diverse generano risorse separate. La cache ha un limite di 128 chiavi e viene svuotata prima di inserire una nuova variante quando raggiunge il limite.
- **Perché:** ridurre costruzioni duplicate di mesh, allocazioni e memoria durante caricamento e creazione delle aree/combattimenti, senza modificare forma, materiali, draw call o logica di gioco. Il limite evita crescita illimitata in caso di strumenti che richiedano parametri sempre diversi.
- **Test implementato e funzionamento:** test_v3_mesh_batch.gd chiama MeshBatch.disc() due volte con gli stessi parametri e confronta gli instance ID; verifica inoltre che una variazione di raggio o colore produca una risorsa distinta e che la mesh abbia la superficie attesa. Il test è standalone e non carica una scena completa.
- **Risultato atteso:** geometrie ricorrenti condivise fra istanze, varianti visive non mischiate, cache limitata.
- **Verifica effettiva:** lettura statica di tutti gli usi di MeshBatch.disc() e implementazione della cache/test. Non sono stati misurati FPS, memoria o tempi di caricamento; il test non è stato eseguito con Godot in questa sessione. Il beneficio quantitativo va misurato con tools/v3_prestazioni.gd su PC e Android prima di considerarlo confermato.


### 2026-11-06 — Guardie anticipate per HUD nascosto in battle3d.gd

- **Modifica:** `_update_wheel()` termina subito quando sia la ruota sia il riflettore sono nascosti. `_place_greg_tag()` termina subito quando sia il cartellino del Gregario sia il pulsante MIRA sono nulli o nascosti.
- **Motivazione:** entrambe le funzioni sono richiamate dal loop `_process()`. Nei frame in cui i rispettivi elementi UI non sono visibili, prima venivano comunque eseguiti controlli e recuperi di stato non necessari.
- **Sicurezza funzionale:** il controllo della ruota considera anche `_spot.visible`, così non interrompe l'aggiornamento di un eventuale riflettore ancora in dissolvenza. Il controllo Gregario considera separatamente cartellino e pulsante MIRA: basta che uno sia visibile perché il posizionamento continui.
- **Impatto atteso:** riduzione minima ma certa del lavoro CPU/GDScript nei frame con questi elementi nascosti. Non modifica formule di proiezione, coordinate, interpolazione, animazioni, input o regole di combattimento.
- **Test:** nessun test automatizzato specifico aggiunto; la modifica consiste in guardie di uscita anticipata. Verifica statica dei due percorsi e dei casi limite descritti sopra. Test runtime Godot non eseguito in questa sessione.
- **Verifiche manuali richieste:** ruota nascosta/visibile durante apertura e chiusura; riflettore durante la dissolvenza; cartellino Gregario nascosto/visibile; pulsante MIRA visibile con cartellino nascosto; cambio bersaglio e movimento camera.
- **Limite:** beneficio quantitativo non misurato; non attribuire guadagni FPS senza benchmark.


### 2026-11-06 — Analisi profonda di battle3d.gd e dei visual collegati

- **File analizzati:** `scripts/v3/battle3d.gd` (circa 4.915 righe); `character_visual.gd`; `vending_visual.gd`; `cmd_wheel.gd`; `reticle.gd`; `broken_cam.gd`.
- **Metodo:** lettura statica di `_process()`, funzioni di proiezione HUD, costruzione unità, animazioni e componenti grafici. Nessun benchmark runtime.
- **Rilievo 1 — proiezioni HUD:** `_process()` richiama ogni frame `_update_wheel()`, `_place_boss_tag()` e `_place_greg_tag()`. Le funzioni proiettano punti 3D in coordinate UI, interrogano dimensioni dei controlli e applicano layout. Le proiezioni sono necessarie quando camera/personaggio si muovono; non è sicuro ridurle con un timer fisso. La prima ottimizzazione sicura è evitare il percorso quando i controlli interessati sono tutti nascosti.
- **Rilievo 2 — animazione personaggi:** `CharacterVisual._process()` aggiorna gambe, braccia, busto, testa, respiro, posizione corpo, accessori e ombra. Parte del lavoro è idle intenzionale. Una modalità sospendibile richiede prima di mappare ogni proprietà scritta da Tween, hit, stance, hop, fall, props e movimento.
- **Rilievo 3 — animazione nemici:** `VendingVisual._process()` aggiorna posizione/rotazione/scala e, quando presenti, cubi orbitanti; idle, awake, stunned e down hanno semantiche visive diverse. Non sospendere genericamente senza mappare i tipi e le transizioni.
- **Rilievo 4 — componenti già efficienti:** `Reticle` disabilita il process quando nascosto; `CmdWheel` esce quando invisibile e limita il redraw; `BrokenCam` condivide lo shader e non aggiorna i parametri quando il rettangolo è invisibile. `_refresh_hud()` riusa le righe ordine e limita alcuni redraw tramite firme.
- **Rilievo 5 — HUD aggiornato:** `_refresh_hud()` esegue molte assegnazioni di valori e testo; per priorità, prima conviene misurare il costo delle proiezioni e delle animazioni continue, evitando una riscrittura del refresh che potrebbe introdurre stati UI non aggiornati.
- **Decisione:** nessun throttling arbitrario, nessuna sospensione generale di animazioni e nessun cambiamento alle formule di proiezione. Sono state aggiunte solo guardie di uscita anticipata quando ruota/riflettore e cartellino/pulsante MIRA sono entrambi nascosti.
- **Test:** controllo statico dei percorsi nascosti e visibili; nessun test Godot eseguito. Verifiche manuali richieste: apertura/chiusura ruota, dissolvenza riflettore, cartellino Gregario, pulsante MIRA indipendente, cambio bersaglio, movimento camera e resize viewport.
- **Risultato atteso:** evitare lavoro GDScript non necessario nei frame senza UI pertinente, mantenendo aggiornamento completo quando un elemento è visibile. Il guadagno quantitativo non è misurato.
- **Passi successivi:** mappare tutte le scritture a proprietà animate di CharacterVisual/VendingVisual; aggiungere benchmark ripetibili con battaglia standard, gregario, QTE, cut-in e BREAK; misurare frame time medio/p95/max, CPU, memoria e draw calls su PC e Android.



### 2026-11-06 — Evizione LRU della cache MeshBatch.disc()

- **File modificati:** `scripts/v3/mesh_batch.gd`; `tests/unit/test_v3_mesh_batch.gd`.
- **Criticità trovata:** la cache precedente eliminava tutte le 128 voci al raggiungimento del limite. Con un insieme di geometrie ricorrenti appena superiore a 128, questo comportamento poteva causare ricostruzioni a gruppi e perdere anche le varianti usate continuamente.
- **Correzione:** introdotto un ordine LRU (Least Recently Used). Ogni cache hit sposta la chiave in fondo alla lista; quando la cache è piena viene rimossa soltanto la chiave meno recentemente usata. Il limite resta 128. Se la lista d'ordine risultasse vuota mentre il dizionario è pieno, un percorso difensivo riallinea lo stato svuotando il dizionario.
- **Perché:** mantenere in cache le geometrie più richieste e ridurre il rischio di thrashing quando il numero di varianti supera il limite, senza permettere crescita illimitata.
- **Sicurezza delle risorse:** l'espulsione rimuove il riferimento dal dizionario, ma non invalida le `ArrayMesh` già assegnate a `MeshInstance3D` o conservate da altri riferimenti. Una variante espulsa viene ricostruita soltanto se richiesta di nuovo.
- **Test implementato e funzionamento:** esteso `tests/unit/test_v3_mesh_batch.gd`. Dopo aver creato e riutilizzato una variante, il test riempie la cache con 125 chiavi aggiuntive, inserisce un'ulteriore variante oltre il limite, verifica che la chiave recentemente usata restituisca la stessa istanza e che la chiave meno recente espulsa venga ricostruita con un nuovo instance ID. Restano anche i controlli di riuso, superficie e separazione di raggio/colore.
- **Risultato atteso:** dimensione massima invariata (128); le voci calde sopravvivono all'inserimento di nuove varianti; viene espulsa una sola voce per inserimento oltre il limite.
- **Verifica effettiva:** confronto statico del percorso hit/miss e dell'ordine di eviction; aggiornato il test per coprire il limite. **Il test Godot non è stato eseguito in questa sessione**, quindi la correttezza runtime e il beneficio prestazionale restano da confermare.
- **Misure ancora necessarie:** eseguire `godot --headless --path . -s tests/unit/test_v3_mesh_batch.gd`; confrontare tempi di costruzione e numero di mesh ricostruite con una sequenza ripetuta di oltre 128 varianti; verificare memoria e tempi di caricamento su PC e Android.
- **Nessuna modifica:** geometria del disco, parametri visivi, materiali, draw call, gameplay e dati narrativi.
