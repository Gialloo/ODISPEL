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
