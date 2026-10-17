# ODISPEL — Handoff completo per analisi da Game Director

Versione del documento: 17 ottobre 2026 · Stato del gioco: **0.28.3** (ramo `claude/battaglia-v2`) · Autore del progetto: un solo sviluppatore non tecnico, che lavora con un'IA di programmazione (Claude Code).

> **Come usarlo.** Questo file descrive il gioco com'è *adesso*, con onestà su cosa è finito, cosa è un prototipo e cosa non è mai stato verificato.
> Dove i numeri vengono dal codice è scritto "dal codice"; dove sono stime o giudizi miei è scritto "stima" o "giudizio".
> Esistono altri documenti più vecchi nel repository (`docs/HANDOFF_COMPLETO.md` è fermo alla 0.24.21 e parla di un ramo che non è più quello di lavoro): per lo stato attuale **vince questo file**, e dove il codice contraddice qualcosa vince il codice.
> Il repository è **privato**: l'analista non ha accesso al codice se non quello che gli viene incollato o allegato.

---

## 1. Il gioco in breve

**ODISPEL** è un battler a turni con boss, cooperativo online e PvP, ambientato in un **urban fantasy notturno**, con stile anime 2D illustrato e interfaccia da "centrale di sorveglianza" (telecamere, MISSION CONTROL, REC).
Esce per **Windows** e **Android**, distribuito su **itch.io** (pagina privata con password) per gli amici dell'autore che fanno da tester.

- **Fantasia del giocatore**: sei un operatore neutrale che coordina squadre di maghi di fazioni diverse contro le Anomalie, creature nate dagli oggetti di città (distributore, semaforo, tombino, cabina…).
- **Loop base**: scegli squadra → affronti un boss annunciato → leggi la sua prossima mossa e reagisci → vinci crediti/materiali → potenzi, equipaggi, recluti → boss più duri.
- **Motore**: Godot 4.7.2, GDScript, renderer `gl_compatibility` (anche su telefono), risoluzione base 1280×720. Tutta l'interfaccia è costruita da codice.
- **Dimensioni** (dal codice): ~55.000 righe di GDScript in ~300 file; 81+ test automatici; 149 strumenti/script di prova in `tools/`; ~300 commit in circa una settimana di lavoro intenso (dal 11 ottobre 2026).
- **Monetizzazione**: nessuna. Il reclutamento è "gacha" ma con valuta di gioco (crediti), niente denaro vero.

### Due combattimenti in parallelo (importante per l'analisi)
1. **Combattimento classico** (`scenes/battle/`, ~3.100 righe): quello completo, con tutte le regole, la rete, i premi, tutte le modalità. Interfaccia a "ventaglio" di comandi, stile JRPG pulito.
2. **Test V2 / "schizzi di pittura"** (`scenes/battle_v2/`, ~2.000 righe): un **prototipo nuovo**, solo contro un boss (il Distributore), in allenamento (nessun premio, nessuna rete). È l'esperimento sul *feeling*: la ruota dei comandi con lettere giganti (A-S-U-G), pennellate di vernice, camera che reagisce, ultimate "light painting". È dove sta andando la direzione visiva e di sensazione. **Non è ancora collegato al resto del gioco** (nessun premio, nessuna progressione scritta dal V2).

Dall'hub il pulsante **TEST V2** apre la nuova schermata **Squadra** (stile Ashen Vow) e poi il combattimento V2.

---

## 2. Mondo, tono, fazioni

- Gli **Odispeller** sono i maghi; esistono un albo e una licenza magica. Tono: urban fantasy, notturno, leggero ma con rischio.
- **LibraCorp**: gruppo paramilitare finanziato dal misterioso **Leviatano** (una specie di Bruce Wayne del mondo). Poliziotti anti-Anomalie; i loro poteri vengono dall'**equipaggiamento** (armi con **munizioni**). Dottrina: *Protocollo* (risposte, contrattacchi, ricarica).
- **Rondini**: Odispeller che fanno le ronde di notte per proteggere gli umani, in piccoli gruppi. Dottrina: *Ronda* (critici, danno alto, "cannoni di vetro").
- **Magabondi**: maghi senza licenza, buoni/neutrali/cattivi. Dottrina: *Improvvisazione*.
- **Kairos / Anomalie ("i Sinistri")**: demoni da un altro piano; i boss attuali sono Anomalie urbane. Dottrina: *Dissonanza* (legano, indeboliscono, avvelenano).
- **Storia**: scene a copione in due stagioni (la seconda introduce **Dafne**, "Agent 02" di LibraCorp). Il ruolo del Leviatano e la trama lunga sono ancora **da decidere** (dall'autore: "bozza").
- **Fedeltà al mondo**: 24 operatori, ciascuno con nome, colore, classe, rarità, fazione, ritratto/segnaposto, una passiva e 1-2 abilità uniche; ci sono scritti di lore (`Lore`) e battute (`Banter`).

---

## 3. Il combattimento: regole del motore (valide per classico e per V2)

Il motore (`scripts/battle/`) **non conosce la grafica**: stato = dizionari di soli interi/stringhe, **deterministico** (nessun random non seedato), uguale su host e client.

### 3.1 Struttura del round
- Squadra fino a **6 operatori**: **3 in campo** (front row) e **3 in panchina** (back row, scambio gratuito). In rete ciascun giocatore porta 3 operatori con 1 in campo.
- Ogni round: il boss **annuncia** la sua prossima mossa (le pesanti sono "cariche annunciate"); ogni operatore in campo sceglie una mossa; poi si risolve tutto **in ordine di velocità** con le **priorità**.
- Si vince portando a zero i PV del boss; si perde se cade tutta la squadra.

### 3.2 Risorse
- **Energia** per operatore: parte da 2, max 6, +1 se attivo, +2 in panchina (le mosse costano energia).
- **Barra ultimate (gauge)** 0–100: +15 colpendo, +10 subendo; a 100 si usa l'ultimate.
- **Munizioni** (solo LibraCorp): max 3, alcune mosse le consumano, "Ricarica" le rimette.
- **Riserva di squadra**: parte da 3, max 6, +1 a round e +1 con una combo; si spende per le **reazioni**.
- **Kit**: 4 slot di mosse + ultimate. Negli slot stanno Attacco, Guardia (mosse base), skill possedute e le **abilità uniche** del personaggio. **Bonus kit completo**: +3% PV/ATK/DEF se i 4 slot sono pieni (provvisorio, uguale per tutti; l'autore vuole legarlo alla rarità).

### 3.3 Tattica e "strati" sopra al danno
- **Colori** (rosso, verde, blu, giallo, viola): vantaggio ×1,5 / svantaggio ×0,67 (dal codice: `BEATS`). **Classi**: striker, vanguard, warden. **Rarità**: comune, rara, epica, leggendaria.
- **Equilibrio** del boss (barra blu): a zero il boss è **stordito** e salta la mossa; vantaggio di colore e marchi rompono di più (è la nostra versione del "break/stagger").
- **Fasi** del boss a metà e a un quarto dei PV (nuove mosse, scudo, +25 ultimate alla squadra, prosciuga la Riserva).
- **Combo modulari** tra mosse con tag: COPERTURA, TRACCIA, DETONAZIONE, FRATTURA, ASSEDIO, RAFFICA, VINCOLO+SCARICA, GUARDIA SPEZZATA, CONDANNA, CASCATA (una volta per causa per round).
- **Reazioni** (spendono Riserva) contro le cariche: SCHIVATA, INTERCETTAZIONE, INTERRUZIONE, SOCCORSO.
- **Sinergie** passive: RITMO (cambiare mossa +10%), ADATTAMENTO (3ª volta uguale −15%), ARDORE (<30% PV +15%), ULTIMA VOLONTÀ, SACRIFICIO.
- **Marchi**: pile di debuff sul nemico, usate in modo diverso dai personaggi (+10% ciascuno contro i boss, fino a 6).
- **Aure di fazione** tra compagni della stessa fazione (cap +25%) e stile **ortodosso/atipico**.
- **Arena**: ogni boss "punisce" qualcosa (cure, marchi, guardia di gruppo); eventi dell'arena ogni 3 round (ZONA CONTAMINATA, SIGILLO).
- **Tattiche avanzate**: ordini di squadra, PREZZO (potere in cambio di PV), PING per la cooperativa, scudi del boss, attacchi a catena.
- **Il boss impara** (solo solitaria): dopo averlo battuto, la volta dopo ha imparato dal tuo stile.
- **Boss**: 18 in ordine di sblocco (distributore, semaforo, tombino, cabina, ascensore, manichino, orologio, specchio, sirena, lampione, bancomat, scala, radio, metro, cassaforte, faro, registro, eclissi); dal 10° in poi "Stagione 2".
- **Difficoltà**: NORMALE, DIFFICILE (HP ×1,5, ATK ×1,25), INCUBO (HP ×2,1, ATK ×1,55), ABISSO (pensato per squadre al massimo, premi ×5).

Impressione generale (giudizio): il motore è **molto più profondo di quanto il combattimento V2 mostri**. Il rischio per un game director è una complessità invisibile al giocatore (molti sistemi, poca leggibilità).

---

## 4. Il Test V2 — il nuovo combattimento ("schizzi di pittura")

### 4.1 Idea
Spingere il **feeling** verso i riferimenti moderni (Metaphor: ReFantazio, Persona 5): una HUD fortemente stilizzata e animata, comandi grandi, camera viva, ogni gesto con impatto. Il giocatore **vede solo ciò che serve** nel momento in cui sceglie.

### 4.2 Come appare
- **Ruota dei 4 comandi**, a croce, attorno all'operatore: **ATTACK** (su), **SKILL** (destra), **ULTIMATE** (giù), **GUARD** (sinistra). Ogni comando ha un'enorme **lettera** dietro (A, S, U, G) in bianco con bordo colorato, una **pennellata** di vernice e scie di luce nel colore del personaggio.
- Selezionare un comando oscura il resto, fa partire alone, onde e un banner col nome della mossa e il moltiplicatore danno; **CONFERMA/ANNULLA** a destra.
- In alto: ordine del turno con ritratti, nome del boss con barra, **EQUILIBRIO**; in basso: pannelli squadra (PV, EN, ritratto), riserva, scorciatoie AUTO e VELOCITÀ.
- Camera con molla (urti, ondeggio, zoom), HUD con parallasse minima.
- **Ultimate "lanciata"** (novità 0.28.2/0.28.3): alla conferma dell'ultimate, per **4 fotogrammi** tutto va a **nero** e restano solo scie di luce **del colore di chi la lancia**, che esplodono dal centro con un nucleo sfocato e luminoso; i comandi diventano **punti bianchi**. Poi si torna al combattimento.
- **Interruttore di test "ULTI"**: pulsante in alto (o tasto **U**) che mantiene la ultimate sempre carica, per poterla provare a ogni round.
- **Schermata Squadra V2** (stile Ashen Vow, 1.000 righe): scegli la squadra di 6, potenzia, equipaggia mosse e pezzi, kanji di ogni operatore, poi COMBATTI con scena di caricamento.

### 4.3 Stato tecnico/qualitativo del V2 (da un audit interno del 17/10)
Il V2 è **un prototipo giocabile ma incompleto**. Problemi verificati nel codice (priorità P0/P1):
- **Annuncio del boss** mostrato solo per le mosse pesanti; le altre non sono annunciate.
- **Quasi nessun feedback di combattimento**: oggi hanno feedback solo i danni; mancano critico, cura, scudo, schivata, KO, rottura equilibrio, stati.
- **Impostazioni di accessibilità ignorate** (lampo bianco, scuotimento, effetti ridotti) — rilevante per fotosensibilità.
- **Debolezze di colore non mostrate** (il giocatore non vede cosa è efficace).
- **Solo 3 operatori su 6 combattono e la scena non lo spiega**; niente scambio in battaglia.
- **Bersaglio non scelto dal giocatore** (contro un boss è uno solo, per le mosse alleate il gioco sceglie da solo l'alleato con meno PV).
- **Ritmo del round fisso** (0,9 s / velocità), non guidato dagli eventi: con molti eventi non è garantito che si legga cosa è successo.
- **Nessun test automatico** per la scena V2; architettura in un solo file grande.
- **Nessuna prova su telefono reale** (touch, leggibilità fisica, FPS, calore): tutte le verifiche sono simulazioni a 2400×1080.
- Una sola **variante di HUD** (A) è stata mostrata e non è stata approvata; le varianti B e C non sono mai state prodotte.

---

## 5. Meta-gioco, economia e progressione

- **Collezione di 24 operatori** (dal codice: 6 comuni, 6 rari, 5 epici, 7 leggendari; 3 classi e 5 colori). Reclutamento con **crediti** (gacha con "pity"), nessun denaro vero.
- Ogni operatore: **livello**, **rank**, **equipaggiamento** (arma, petto, stivali), mosse (148 definite in totale) e passive; **maestria** delle mosse (25 usi per livello, max 3, +4%/livello).
- **Valute**: CREDITI, NUCLEI, LEGHE (materiali di potenziamento). Nel V2 c'è un pulsante "solo test" che regala +5.000 crediti, +20 nuclei e leghe.
- **Titoli** (riconoscimenti dell'account, epici/leggendari) con bonus **permanenti**; **Potere** come punteggio sintetico (`hp/10 + atk×2 + def×1,5 + spd`).
- **Obiettivi/Imprese** giornalieri (3 al giorno) e permanenti, **tutorial** (12+ lezioni con premi), **archivio delle scoperte**.
- **Sfida facoltativa** a ogni battaglia (+120 crediti), **Rientro** (dopo 3 sconfitte parte con riserva +2 e scudo), **sala di addestramento**, **codice squadra** condivisibile.

## 6. Modalità

| Modalità | Descrizione |
|---|---|
| Storia (2 stagioni) | Scene a copione, boss in ordine di sblocco |
| Missioni | Boss per sblocco, 4 difficoltà, addestramento |
| Sfida del giorno / Evento settimanale | Boss e modificatore dalla data, serie di premi |
| Ciclo infinito | Piani sempre più duri con potenziamenti ("boon") da scegliere |
| Spedizione | Roguelite a tappe, da soli o co-op: breve 6 tappe, lunga 10 (rifugio, guardiano, reliquia maledetta, modificatori volontari); PV che si portano dietro, veterani, feriti |
| Co-op online | Stanze con codice, chat, host autoritativo (WebRTC) |
| PvP | Motore a parte; modalità bilanciata (livello 20, rank 2, niente equipaggiamento) e allenamento vs IA |
| Test V2 | Nuovo combattimento, solo allenamento |

---

## 7. Architettura del codice (per chi analizza la struttura)

- **Separazione netta motore/grafica**: `scripts/battle/` (motore puro, ~20 file) vs `scenes/*` e `scripts/ui/` (presentazione). Principi: stato JSON-safe di soli interi, nessun float, deterministico, host autoritativo, "sorgenti di battaglia" con la stessa interfaccia (solitaria, rete, PvP locale).
- **Interfaccia tutta da codice** (nessun editor visuale), temi condivisi (`BattleTheme`, `HudPanel`, `ScreenFrame`, `TouchUi`).
- **Porte d'ingresso che non fanno nulla senza gestore** (`Notify`, `Snd`, `SceneRouter`) → i test girano senza interfaccia.
- **Rete**: WebRTC (con estensione nativa), server di segnalazione Node.js su Render (può "svegliarsi" in ~1 minuto), STUN/TURN per i dati mobili.
- **Salvataggi**: JSON versionato in `user://` con migrazioni (`RosterState.from_json`).
- **Prestazioni**: nodi statici invece di `_draw` per frame, tween per i colori, `CPUParticles2D`, shader additivi, pennellate "fotografate" una volta in `SubViewport` e poi ridimensionate/tinteggiate; effetti ridotti (`Settings.light_fx`); sui telefoni nessun limite a 60 FPS (segue il refresh dello schermo).
- **Test**: 81 file in `tests/unit` (uno per area), audit automatici dei pulsanti (`ui_audit`), foto delle schermate con Xvfb, strumenti di bilanciamento (non da lanciare senza richiesta).
- **Punti deboli noti** (giudizio):
  - File molto grandi con classi interne (`battle_screen.gd` ~3.100 righe, `battle_v2.gd` ~2.000, `squad_v2.gd` ~1.000, `battle_resolver.gd` ~1.250, `pvp_engine.gd` ~800).
  - **Doppio combattimento** (classico + V2) e **doppio PvP** (motore separato): rischio di divergenza.
  - Stato condiviso in variabili statiche nel V2 (`_G`) che sopravvive al "rigioca".
  - Grafiche in gran parte **segnaposto disegnati da codice** (boss, molti operatori); ritratti veri solo per alcuni (Kira, Dafne).
  - Nessuna prova su dispositivi reali; APK firmato con chiave di debug (i telefoni con una versione firmata diversamente richiedono la disinstallazione).

## 8. Build, distribuzione, versioni

- Windows: `ODISPEL.exe` + DLL WebRTC nello zip. Android: APK firmato (riscritto da uno script per ridurlo a ~36 MB). Nomi file: `ODISPEL mobile v.X.Y.Z.apk` e `ODISPEL pc vX.Y.Z.zip`.
- **itch.io**: un workflow GitHub automatico carica sui canali `android-mobile` e `windows-pc` quando si pubblicano i file nuovi in `releases/` sul ramo `claude/battaglia-v2`. Le versioni precedenti sono state rinominate (ODISPEL-test-…, ODISPEL-old-…).
- **Versioni recenti**: 0.28.1 (squadra V2, FPS > 60 su telefono, testi più leggibili), 0.28.2 (esplosione dell'ultimate, interruttore ULTI), 0.28.3 (esplosione di 4 fotogrammi).
- Regola: ogni versione alza `GameConfig.VERSION` e il numero interno dell'APK; host e client multiplayer devono avere la stessa versione.

---

## 9. Dati di bilanciamento (vecchi: versione 0.24.0, indicativi)

Dal report interno (simulazioni su 1.771 squadre da 3): erano emersi PvP "bilanciato" che non lo era (la rarità dava ancora +32%), operatori molto sopra la media (Dafne, Flux, Kira, Eco, Lyra, Angela) e in fondo i supporti (Elle, Sera, Rhea, Nami, Mira, Bruno); contro i boss duri le squadre senza attaccanti non potevano vincere. Sono stati fatti ritocchi (rarità livellata in PvP, marchi cumulabili, bonus di squadra per i supporti). **Da allora molte cose sono cambiate**: i numeri vanno considerati storici, e l'autore ha detto che i test di bilanciamento li fa lui.

## 10. Cosa NON è stato verificato (onestà)

- Nessuna prova su telefono reale (FPS, calore, tocco, leggibilità); gli FPS misurati sono di un renderer software.
- Nessun test con persone esterne all'autore e agli amici; nessuna misura di divertimento percepito o di tempo di apprendimento.
- L'esito dell'ultimo upload su itch e l'aggiornamento dell'APK sul telefono sopra versioni precedenti non sono confermati.
- Non è mai stato giocato un intero percorso (storia → spedizione) come lo farebbe un giocatore nuovo.

## 11. Decisioni aperte dell'autore

1. Bonus del kit completo: oggi +3% uguale per tutti, da legare alla rarità.
2. Le abilità uniche contano dentro i 4 slot (stato attuale) o in aggiunta?
3. Direzione della HUD V2: variante A (ramo `claude/battaglia-v2-hud-prova`) approvata o rifatta? Varianti B/C da produrre?
4. Quali problemi dell'audit V2 correggere per primi (annuncio boss, feedback, accessibilità, debolezze, 3 vs 6, ritmo, test).
5. Ruolo del Leviatano e trama lunga; nome definitivo delle Anomalie/Kairos.
6. Funzioni richieste ma non fatte: modalità osservatore, battaglie asimmetriche, trasferimento di risorse tra giocatori, ruoli temporanei, boss che impara anche in multiplayer.
7. Quanto il V2 deve sostituire il combattimento classico e quando.

## 12. Vincoli e preferenze dell'autore

- Sviluppatore singolo, non tecnico esperto; risposte e proposte semplici, in italiano, passo passo.
- Gioco per amici/tester, distribuzione privata su itch.io; **nessun denaro vero** nel gioco.
- Preferenza forte per il **feeling**, l'impatto, l'identità visiva (riferimenti citati: Metaphor: ReFantazio, Persona, Ashen Vow per la schermata squadra).
- Ogni proposta deve poter girare bene su telefono di fascia media (Godot, GL compatibility).
- Il repository resta privato; nessun segreto (chiavi TURN, itch) nei documenti.

## 13. Come provare il gioco

- Scarica da itch.io `ODISPEL mobile v.0.28.3.apk` (Android) o `ODISPEL pc v0.28.3.zip` (Windows: estrai e avvia, l'avviso SmartScreen si supera con "Maggiori informazioni → Esegui comunque").
- Dall'hub: **TEST V2** → schermata Squadra → COMBATTI.
- Comandi nel V2: **1–4** o tocco per i comandi, **Invio/Spazio** conferma, **Esc** annulla/esci, **U** interruttore ULTI, frecce/A/D nella Squadra.
- Per il confronto: dall'hub, le missioni normali usano il combattimento **classico**.

## 14. File utili del repository (se l'analista ne riceve estratti)

`scripts/battle/battle_content.gd` (mosse, personaggi, boss) · `battle_resolver.gd` (risoluzione round) · `battle_state.gd` · `signatures.gd` (passive/abilità uniche) · `combos.gd`, `marks.gd`, `arena.gd`, `tactics.gd` · `scenes/battle_v2/battle_v2.gd` · `scenes/squad_v2/squad_v2.gd` · `scenes/hub/hub_demo.gd` · `docs/MONDO.md`, `docs/DOTTRINE.md`, `docs/ARCHITETTURA.md`, `docs/REPORT_BILANCIAMENTO.md`, `docs/ART_BIBLE.md`, audit V2 (`docs/AUDIT_BATTAGLIA_V2.md` sul ramo `claude/battaglia-v2-audit`).
