# Report build sperimentale, test e dati per l'audit del combattimento

Data: 05/11/2026 · Branch: `experiment/c2.6-strategy-lab` · Commit verificato: `4ea37bc` (base `d7a08f7`)
Ambiente: container Linux nel cloud, Godot **4.7.2.stable.official.ed1daf0bf** (scaricato da GitHub releases), template di export 4.7.2 ufficiali, xvfb + llvmpipe (niente GPU), nessun dispositivo o emulatore Android.

## 0. In breve

1. **Il motore di battaglia non compila.** `scripts/engine/battle_resolver.gd:911` usa la variabile `events` dentro `react_bonus()`, che non la riceve come parametro. La riga è arrivata con il commit `76f1c55` «Instrument battle resolver resource gains and spending» (05/11/2026, dopo la release 0.56.0). Con questo errore non si caricano `battle_resolver.gd` e, a catena, `tactics.gd`, `battle_state.gd`, `battle_content.gd`, `atypical.gd`, `signatures.gd`, `progress.gd`, `story.gd`, `ritratto_varianti.gd`, `main.gd`.
2. **Suite sul branch così com'è: 12 file su 26 passano, 14 falliscono o si bloccano.** Diversi «OK» dei 12 sono comunque accompagnati da errori di script (vedi tabella): non vanno letti come verde pieno.
3. **Prova diagnostica** (copia separata in una cartella temporanea, branch non toccato): cambiando solo quella riga passano **23 file su 26**. Restano 3 file con fallimenti veri: serializzazione JSON dello stato (`strategy_hits` mette numeri decimali nello stato) e telemetria delle risorse.
4. **Build prodotte e firmate**, ma **non adatte alla pubblicazione**: il menu parte, le battaglie no (`tools/v3_atto1.gd` si ferma alla prima battaglia, `c0_p2`).
5. **Nessuna pubblicazione su itch.** Il motivo è il punto 4, e in più manca un canale sicuro: il workflow attuale pubblica solo da `claude/v3-prologo` sui canali stabili. Proposta al punto 7.
6. `claude/v3-prologo` ha lo stesso codice (il branch sperimentale aggiunge solo `docs/AUDIT_HANDOFF_229-291.md`), quindi ha lo stesso errore di compilazione.

## 1. Verifica del branch

| Controllo | Esito |
|---|---|
| Branch remoto | `origin/experiment/c2.6-strategy-lab` esiste |
| Ultimo commit | `4ea37bc docs: add preliminary audit for approved design decisions 229-291` (atteso) |
| Differenza con la base `d7a08f7` | 1 file, `docs/AUDIT_HANDOFF_229-291.md`, +198 righe. Codice, scene e dati identici a `claude/v3-prologo` |
| Working tree | pulito all'inizio; dopo l'import Godot compaiono due `.uid` non tracciati (`resource_telemetry.gd.uid`, `test_v3_resource_telemetry.gd.uid`), non aggiunti |
| main / claude/v3-prologo | non toccati, nessun merge o cherry-pick |

Il report sta su `claude/project-thread-6le35n`, creato da `4ea37bc`. Per portarlo sul branch sperimentale basta un fast-forward, quando l'autore vuole.

## 2. Runner dei test

Nel repository non c'è un framework (GUT o simili). Ogni file `tests/unit/*.gd` è un `extends SceneTree` che stampa `FAIL: ...` e chiude con `quit(1)` se qualcosa fallisce. Comandi presi dal README:

```
export PATH=/root/bin:$PATH
godot --headless --path . --import
godot --headless --path . -s tests/unit/<file>.gd
```

Li ho lanciati tutti e 26, quattro alla volta, con un limite di 180 s a file (`timeout 180`). Un file che va in errore di script dentro `_init()` non arriva a `quit()` e resta appeso: per quello serve il limite. Codice 124 = fermato dal limite.

**Import** (`godot --headless --path . --import`, 18 s): 11 errori, tutti in cascata dalla riga 911:
```
SCRIPT ERROR: Parse Error: Identifier "events" not declared in the current scope.
          at: GDScript::reload (res://scripts/engine/battle_resolver.gd:911)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.  (tactics, battle_state, atypical, signatures, ...)
ERROR: Failed to load script "res://scripts/v3/main.gd" with error "Parse error".
```
Nessun problema di importazione di immagini, audio o modelli.

## 3. Risultati dei test

Il numero di singoli controlli lo stampano solo alcuni file. Dove c'è, è riportato; altrimenti il file vale come un'unità. «Errori script» = righe `SCRIPT ERROR` nel log. Nessun test è stato saltato e nessuno modificato.

| File | Branch: uscita | s | FAIL | errori script | Prova diagnostica (riga 911 corretta) |
|---|---|---|---|---|---|
| test_archetypes | 124 bloccato | 180 | 0 | 10 | **1 FAIL**: «JSON identico dopo 3 round» (23 ok, 1 fallito) |
| test_atypical | 0 | 0,8 | 0 | 8 | ok (67 ok, 0 falliti); sul branch «0 passati, 0 falliti» = non ha girato |
| test_battle | 1 | 0,9 | 3 | 137 | **2 FAIL**: «JSON conserva lo stato», «ripresa dal JSON: stessa conclusione» (92 ok) |
| test_v3_archetipi | 124 bloccato | 180 | 0 | 16 | ok |
| test_v3_battute | 0 | 0,3 | 0 | 0 | ok |
| test_v3_break | 124 bloccato | 180 | 0 | 16 | ok |
| test_v3_dialoghi | 0 | 1,0 | 0 | 9 | ok |
| test_v3_diretta | 124 bloccato | 180 | 0 | 15 | ok |
| test_v3_due_nemici | 124 bloccato | 180 | 1 | 28 | ok |
| test_v3_duo | 124 bloccato | 180 | 6 | 22 | ok |
| test_v3_engine | 124 bloccato | 180 | 5 | 14 | ok |
| test_v3_flusso | 0 «OK» | 0,8 | 0 | 44 | ok (6,1 s: sul branch non gira davvero) |
| test_v3_hud | 0 | 0,5 | 0 | 10 | ok |
| test_v3_lezioni | 0 | 1,8 | 0 | 9 | ok |
| test_v3_livelli | 0 | 0,7 | 0 | 10 | ok |
| test_v3_parata | 0 | 0,2 | 0 | 0 | ok |
| test_v3_progressione | 124 bloccato | 180 | 43 | 28 | ok |
| test_v3_registro | 0 | 2,2 | 0 | 8 | ok |
| test_v3_replica | 0 | 0,7 | 0 | 9 | ok |
| test_v3_resource_telemetry | 1 | 0,5 | 3 | 29 | **3 FAIL** (sotto) |
| test_v3_ritmo | 1 | 0,6 | 10 | 238 | ok |
| test_v3_ritratto_varianti | 0 | 0,8 | 0 | 10 | ok (37 ok) |
| test_v3_sblocchi_100 | 124 bloccato | 180 | 104 | 14 | ok |
| test_v3_slancio | 1 | 0,8 | 1 | 84 | ok |
| test_v3_suoni | 0 | 0,6 | 0 | 0 | ok |
| test_v3_timeline | 1 | 0,7 | 8 | 215 | ok |

Totale sul branch: 12 file con uscita 0 (di cui 9 con errori di script nel log), 5 con uscita 1, 9 bloccati. **La suite non è superata.**
Totale nella prova diagnostica: 23 file con uscita 0 e log pulito, 3 con uscita 1.

### Fallimenti che restano anche con la riga 911 corretta

1. **Serializzazione JSON** (`test_battle.gd:378` e `:382`, `test_archetypes.gd:89`). `BattleState.to_json` / `from_json` + `normalize()` partono dal presupposto che nello stato non ci siano numeri decimali («Nello stato non ci sono float veri, quindi la conversione e' sicura», `battle_state.gd`). `battle_resolver.gd:1116-1118` (commit `b264a64`, telemetria B3.2) scrive in `state["strategy_hits"]` campi decimali: `pressure`, `link_mult`, `combo_mult`, `other_mult`, `effective_mult`. Dopo il giro in JSON diventano interi troncati, per esempio `other_mult 2.691 -> 2` e `effective_mult 0.845 -> 0`. Ho verificato con uno script di confronto campo per campo nella copia diagnostica. Il motore non legge `strategy_hits`, quindi l'esito della battaglia non cambia, ma il salvataggio e la ripresa non sono più identici.
2. **Telemetria delle risorse** (`test_v3_resource_telemetry.gd`, `_net_snapshot`, righe 48-58): «lo snapshot genera un delta netto», «il delta netto coincide con la variazione effettiva», «il delta conserva la fase quando manca un evento azione». `ResourceTelemetry.record()` non produce nessun evento `resource_delta` per un guadagno di `gauge` fatto con `gain_unit()` su uno stato solo (`create_solo`). In questa sessione non ho trovato la causa esatta: va guardato insieme a `snapshot()` e `gain_unit()` (`scripts/engine/resource_telemetry.gd`).

### Altri controlli del progetto

| Comando | Esito |
|---|---|
| `godot --headless --path . -s tools/v3_bilancio.gd -- vel` | non compila: `tools/v3_bilancio.gd:789` usa `signal` come nome di variabile (parola riservata). Commit `5182cba` |
| `xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_atto1.gd -- <dir>` | si ferma alla prima battaglia (`PASSO c0_p2 battle3d.gd`), 43 errori di script, fermato a 400 s |
| `xvfb-run -a godot ... -s tools/v3_prestazioni.gd -- <dir>` | finisce (uscita 0) con 213 errori di script. Misure sotto llvmpipe, utili solo per confronto: battaglie 80-130 ms a fotogramma, 76 MB, 28-33 draw call |
| `tools/v3_vetrina.gd` | non lanciato: fa solo schermate, non controlla nulla |

Validazione dei dati: `test_v3_dialoghi`, `test_v3_battute`, `test_v3_lezioni` e `test_v3_registro` leggono `data/*.json` e passano nella prova diagnostica. Non esiste un controllo separato per lo schema di `data/atto1.json`.

## 4. Build

| | Android | PC (Windows) |
|---|---|---|
| Comando | `godot --headless --path . --export-release "Android" build/raw.apk` | `godot --headless --path . --export-release "Windows Desktop" build/win/OFFICIAL_DEMO_ODISPEL.exe` |
| Esportazione | completata (uscita 0) con l'errore di compilazione nel log | completata (uscita 0), stesso errore |
| Firma | `python3 tools/sign_apk.py build/raw.apk <out> /mnt/project-files/odispel/chiavi/odispel_v3_release.pem` → «firma v2 verificata» (verifica dello script stesso; apksigner non è installato qui, lo usa il workflow) | non firmato (come la 0.56.0) |
| File | `ODISPEL_V3_sperimentale_c2.6_4ea37bc_android.apk`, 38.268.454 byte | `ODISPEL_V3_sperimentale_c2.6_4ea37bc_pc.zip`, 49.634.986 byte (exe 109 MB + pck 12 MB, nient'altro) |
| SHA-256 | `225891cb…109fdf` | `6c3787b0…20f08` |
| Dove | `/mnt/project-files/odispel/v3/build_sperimentale_c2.6/` (con `SHA256SUMS.txt`). **Non** in `releases/`: lì un push fa partire la pubblicazione | stesso posto |
| Versione | 0.56.0 (code 5600), come nel progetto: non l'ho cambiata. Il nome dei file la segna come sperimentale | 0.56.0 |
| Arch / pacchetto | arm64-v8a, `com.gialloo.odispel.v3`, stesso pacchetto e stessa chiave della 0.56.0: si installa sopra la versione stabile | - |
| Percorsi locali | nessun `/home/user` o `/root` dentro il pck | idem |
| Installazione | **non verificata**: niente dispositivo o emulatore Android qui | - |
| Avvio | - | Il pck parte con il binario Linux 4.7.2 (`--main-pack`, xvfb): il menu principale si vede (0.56.0, NUOVA PARTITA, CAPITOLI, BATTAGLIA…). Al caricamento escono gli stessi errori di compilazione, quindi le battaglie non funzionano (confermato da `v3_atto1`). L'`.exe` Windows non l'ho potuto avviare (qui non c'è Wine né Windows) |

Per l'export Android in questo container ho creato un SDK finto (`platform-tools/adb` e `build-tools/35.0.0/apksigner` vuoti), come dice il README. Il preset non usa il build Gradle.

## 5. Sistemi del combattimento: dove stanno e cosa fanno

Tutti i valori sono quelli del codice al commit `4ea37bc`. Molti sono marcati nel codice come provvisori o «di prova». Dove dico «osservato» intendo un test che passa nella prova diagnostica. Sul branch così com'è nessuno di questi test gira.

### 5.1 Flusso di una battaglia V3 (ordine di risoluzione)

Chi guida: `scripts/v3/battle3d.gd`. Righe 844, 877, 886, 1024, 1169, 1204, 4906.

1. `BattleFlow.start_round(b, ingresso)` → `SeqRound.begin` (azzera link, combo, reazioni e `state["seq"]`) → con la Timeline `_tl_round` / `_tl_init`.
2. Ciclo: `BattleFlow.next(b)` → voce di un eroe oppure `"boss"` / `"greg"`. Priorità dentro `_tl_next` (battle_flow.gd:347): azioni rapide in coda (SLANCIO), poi SLANCIO protetti pronti (`Slancio.ready_kept`), poi lo slot con l'istante più basso (`_pick`), poi i turni extra di fine round (riposo di Nox).
3. Eroe: `BattleFlow.player_action` → `_tl_player` → `SeqRound.player_action`: cambio → `BattleResolver._player_act` (danno, pressione, risorse) → `_summon_upkeep` → `Gregario.after_events` → `_check_winner` → `Kits.after_events` → `_team_strike` (attacco di squadra alla rottura) → `_check_slancio` → `_log`.
   `_log` (seq_round.gd:250) chiama **`Ritmo.after_events`** (il RITMO legge gli eventi già prodotti e accoda i suoi), poi `ResourceTelemetry.record`.
   Tornati in `_tl_player`: si riprogramma lo slot (`_schedule` con `time_cost`), poi **`Stability.on_ally_action`** (consumo della finestra BREAK, solo per il turno ordinario), poi `_elite_delay`, poi il +15 dello SLANCIO e l'accodamento delle azioni rapide.
4. Boss: `SeqRound.boss_action` → se stordito, `stun-1` ed evento `boss_stunned`; altrimenti `_boss_act` (lì si risolve la parata a tempo, battle_resolver.gd:1275-1357) → **`Stability.on_enemy_action`** (recupero della stabilità) → `_check_winner` → `Kits.after_events` → `_log` (RITMO: prima `_boss_threat`, cioè la minaccia all'Ardore decisa dalla parata, poi le altre fonti).
5. Fine round: `BattleFlow.finish` → `SeqRound.finish`: `Arena.resolve` → `_end_of_round` (dove `Stability.round_end` sostituisce il recupero del 0.52) → `Tactics.track/end_round` → `_tally` → round+1 → `_recover_balance` → `_check_phase` (`Stability.on_phase`) → `begin_round` → `_apply_carry`.

**Stato logico e presentazione.** Il motore produce solo eventi e la UI li anima. Ma per molti eventi nuovi la UI non ha ancora niente: in `scripts/v3/` **nessun file** legge `ritmo_gain`, `ritmo_loss`, `ritmo_level`, `ritmo_ready`, `ritmo_cond`, `ritmo_save`, `apice_on`, `apice_saul`, `slancio_kept`, `break_window`, `break_end`, `stab_recover`, `stab_full`, `latent`, `sbil`, `rescue`, `resource_delta`, `resource_change`. E nessun file chiama `Ritmo.*` o `Stability.*`. Sono gestiti solo `apice_tech`, `slancio`, `break`, `duo`, `team_strike`, `timed_guard`. Quindi oggi il RITMO, la finestra BREAK, il recupero e la pressione latente esistono solo nella logica: il giocatore non li vede (il commento di `ritmo.gd` lo dice per la fase R1: «niente UI»).

### 5.2 RITMO e Ardore — `scripts/engine/ritmo.gd`, valori in `battle_types.gd:216-247`

- **Stato**: `state["ritmo"] = {ardore, cap(100), level(0-3), ready, done{}, helpers{}, round, gen{}, hold, saves{}, apice_tech{}}`, creato al primo uso da `Ritmo.st()`. I salvataggi vecchi restano validi.
- **Livelli**: CALMO 0, ACCESO 1, INCANDESCENTE 2, APICE 3. Soglie 25 / 50 / 75 (`RITMO_THRESHOLDS`), tetto 100 (`RITMO_CAP`), margine 15 (`RITMO_MARGIN`): con la soglia raggiunta e la condizione ancora da fare si accumula fino a soglia+15 (`room()`).
- **Generazione** (`after_events` → `_source` → `gain`): debolezza 6, BREAK 15, parata 5, parata perfetta 10, contrattacco 4, soccorso 8, cura 5 (solo se chi la riceve era sotto il 40% dei PV), SLANCIO 4, tecnica a due 6. Ogni fonte conta al massimo 2 volte per round (`RITMO_PER_ROUND`, contatore `gen` azzerato al cambio di round). Il +10% al cambio di categoria (`rhythm`) non dà Ardore.
- **Perdite**: KO di un eroe -10 (`RITMO_LOSS_KO`). Colpo annunciato del boss -6 (normale) o -12 (pesante, `RITMO_HIT_LOSS`), ridotto dalla parata: normale 50% / 0%, pesante 75% / 50% (`RITMO_SAVE_KEEP`). Ogni eroe salva una volta per round (`saves`). Una mossa `devastante` non si salva (nessuna mossa ce l'ha). Le API `drain(keep_level)`, `drop_level`, `reset` e `set_cap("taglia"/"blocca")` esistono, ma nel motore non le usa nessuno oltre a KO e colpo.
- **Decadimento nel tempo**: non c'è. L'Ardore scende solo per eventi (KO, colpo del boss, tetto).
- **Avanzamento** (`_settle_up`): soglia raggiunta più una condizione della transizione; un livello alla volta; poi le condizioni ripartono da zero (`_clear_progress`). Condizioni (`CONDS`): verso ACCESO debolezza o parata; verso INCANDESCENTE tre compagni diversi, BREAK, o boss marchiato (questa vale solo finché il marchio resta); verso APICE colpo durante il BREAK o parata perfetta. Le condizioni contano solo se fatte dal livello di partenza (`_mark`).
- **Discesa** (`_settle_down`): il livello scende finché l'Ardore non regge la soglia; si possono attraversare più soglie in una volta.
- **Test**: `test_v3_ritmo.gd` (fonti, limite per round, soglie, condizioni, perdite, salvataggio, bonus, tecnica APICE). Sul branch: 10 FAIL dovuti alla compilazione. Nella prova diagnostica: OK.

### 5.3 APICE — `ritmo.gd:396-497`, `kits.gd:248`, `battle_resolver.gd:686, 801, 1123`

- **Al raggiungimento** (`_on_reach`): ACCESO dà +1 Riserva. APICE dà +1 EN a ogni eroe in piedi, rimette a disposizione tutte le tecniche APICE (`apice_tech = {}`) ed emette l'evento `apice_on`.
- **Bonus passivi**, letti dal livello attuale e quindi persi appena APICE cade: +10% danno della squadra (`dmg_mult`, letto in `battle_resolver.gd:686`); INCANDESCENTE e oltre +1 pressione per colpo, APICE di Lance +1 ancora (`pressure_bonus`, letto in `_chip_balance`, :801); cure di Nox +25% (`heal_mult`, :1123); Hype di Rio +50% (`_rio_apice`); Saul +1 EN sulla debolezza, una volta per round (`_saul_apice`).
- **Tecniche individuali** (`apice_tech`, chiamata da `Kits` a ogni azione): la prima azione di ognuno in APICE, esclusa la Guardia, ha il suo effetto. Lance: -10 equilibrio. Saul: ×1,3 e critico sicuro. Rio: +100 Hype. Nox: cura il 15% a tutta la squadra. Tornano disponibili solo riconquistando APICE. Restano anche se APICE si perde dopo l'uso (gli effetti già applicati non si annullano).
- **Nota**: il commento in `ritmo.gd:395` dice ancora «Nessuna tecnica APICE ancora (servono i costi, R3)», ma la tecnica esiste. Il commento è rimasto indietro.

### 5.4 Timeline — `scripts/engine/battle_flow.gd`, valori in `battle_types.gd:93-102`

- `TIMELINE_ON = true`. Stato in `state["tl"] = {now, stamp, n, slots{chiave: {key, player, boss, greg, at, stamp, a, r, spd0}}, done{}, quick[], extra[], cur, cur_quick, tele_used, greg_used, keep}`. Il tempo è in centesimi interi.
- **Formula** (`delta_t`, :187): ΔT = C × 100 / max(10, 100 + 0,3 × (VEL − 100)). Costi `TL_COST`: attacco 100, rapida 100, standard 110, pesante 120, ultimate 130. Le firme senza `tempo` contano come standard. I nemici costano 100 (`TL_ENEMY_COST`), qualunque sia la mossa.
- **Primo round** (`_tl_init`): tutti partono dal ΔT di un attacco, quindi l'ordine è per VEL. Con «vantaggio» i nemici giocano dopo l'ultimo eroe, con «agguato» a 0.
- **Pareggi** (`_first`): priorità, poi chi era programmato prima (stamp), poi la VEL iniziale, poi l'id. Mai il caso.
- **Round**: si chiude quando i quattro eroi hanno fatto il turno ordinario (`_all_done`). I nemici possono agire più volte o nessuna. Il KO consuma il turno quando arriva la sua posizione.
- **ANTICIPO / RITARDO** (`shift`, ±15% o ±25% del tempo che manca) e **INTERRUZIONE** (`interrupt`, recupero = 50% del costo): sono funzioni del motore. L'unico che le usa è il RITARDO forte dell'elite rotto (`_elite_delay`); nessuna mossa le chiama.
- **Azioni concatenate**: le azioni rapide dello SLANCIO entrano in `tl["quick"]` e non sono turni ordinari. `preview(state, n)` calcola i prossimi turni per la UI (`battle3d.gd:77-80`).
- **Reset del round**: `_tl_round` tiene le posizioni raggiunte (non le azzera), azzera `done` e `quick`, ricalcola gli `extra` e aggiunge o toglie la Scheggia.
- **Test**: `test_v3_timeline.gd` (8 FAIL sul branch, OK in diagnostica), `test_v3_flusso.gd`.

### 5.5 SLANCIO — `scripts/engine/slancio.gd`, `battle_flow.gd:408-433`, `seq_round.gd:162-182`

- **Chi lo ottiene**: chi fa danno a una debolezza compatibile (colore vincente o `weak2`) sul boss o sulla Scheggia (`SLANCIO_GREG`). Una volta per round per eroe: `state["seq"]["slancio_by"][uid]`, che si azzera con `SeqRound.begin`.
- **Cosa si può fare**: solo ATTACCO o GUARDIA (`SeqRound.player_action` con `quick`). La Guardia rapida dà uno scudo dell'8% dei PV massimi alla squadra e +1 EN (`_slancio_guard`). Costo: +15 sul recupero già fissato (`TL_SLANCIO_EXTRA`).
- **Invulnerabilità e SLANCIO protetto**: se il bersaglio è `blocked` (`invuln` o `phase_shift`), lo SLANCIO si conserva in `state["slancio_kept"]`, al massimo uno per eroe, anche attraverso KO e round. Si usa appena il bersaglio torna colpibile, nell'ordine della Timeline. La prima volta non paga il +15 (`waive`). Se il bersaglio è sconfitto, lo SLANCIO decade. Oggi **nessun boss ha `invuln` o `phase_shift`**: il codice c'è, nel gioco non scatta mai.
- **KO**: lo stato è per unità e il KO non lo azzera. Chi è KO aspetta (`ready_kept` lo salta).
- **RISONANZA**: vedi 5.6, nel codice non esiste. Lo SLANCIO dà Ardore (fonte `slancio`, 4) e non consuma la finestra BREAK.
- **Test**: `test_v3_slancio.gd` (1 FAIL sul branch, OK in diagnostica).

### 5.6 RISONANZA e SINERGIE

- **RISONANZA come meccanica non esiste nel codice.** L'unica «Risonanza» è il nome della passiva `eco` in `signatures.gd:117` (rigenerazione della barra Ultimate). Non ci sono requisiti, costi, catene, azioni sospese o protezioni contro la ricorsione da verificare.
- La cosa più vicina sono le **TECNICHE A DUE** (`scripts/engine/duo_techs.gd`): 6 coppie, costo 2 EN a ciascuno dei due (`COST`). Il compagno deve essere in campo e non aver ancora agito nel round; poi salta il suo turno (`duo_rest`, che non consuma la finestra BREAK). Gli effetti sono fissi (colpi, -5/-10 equilibrio, scudo, cure, Hype, furto di scudo). Danno Ardore (`duo`, 6). Non si concatenano. Test: `test_v3_duo.gd`.
- **SINERGIE nello stesso round** (`battle_types.gd:117-124`, `combos.gd`, `tactics.gd`): COPERTURA ×1,12; TRACCIA +10 Ultimate a chi colpisce e +5 a chi ha marchiato; ADATTAMENTO ×0,85 alla terza mossa uguale di fila; GRINTA ×1,15 sotto il 30% dei PV. **Attacco di squadra** alla rottura (`_team_strike`, ×1,3, non consuma la finestra).

### 5.7 BREAK e stabilità — `scripts/engine/stability.gd`, `break_rules.gd`, `battle_resolver.gd:777-830`

- **Stato sul nemico** (`BattleState.boss`): `balance`, `balance_max`, `stun`, `exposed`, `brk_left`, `stab_rec`, `latent`, `brk_weak`, `brk_delay`, `sbil`, `stab`.
- **Pressione distinta dal danno** (`_chip_balance`): i punti vengono dal colore (3 / 2 / 1), +1 se il nemico è marchiato, +1 per un colpo pesante (moltiplicatore ≥ 2), × la regola del boss (`BreakRules.balance_mult`: carica, chiamata, specchio, scudo, parata), × sbilanciamento (1,2), + bonus del RITMO. Il danno non entra mai nel calcolo.
- **Rottura** (`_collapse`): comune e boss perdono la prossima azione (`stun=1`) e diventano vulnerabili (danno ×1,25). L'elite diventa vulnerabile, la prossima azione è ritardata e fa il 70% del danno. Nell'atto 1 non ci sono elite (`STAB_ELITE = []`).
- **Finestra**: si misura in azioni ordinarie alleate (`STAB_WINDOW`: boss 3, elite 2, comune 2), consumate in `on_ally_action`. Non la consumano l'azione che rompe, la tecnica a due (`duo_rest`), lo SLANCIO, le reazioni, l'Ultimate in diretta, l'attacco di squadra e le azioni del boss.
- **Recupero** (`on_enemy_action`): a ogni azione ordinaria del nemico la stabilità risale (boss 33,4%, elite 50%, comune subito piena). Finché non è piena non si rompe di nuovo. Il cambio di fase completa il recupero.
- **Pressione latente**: quella fatta durante il BREAK o il recupero si accumula fino a 50% / 35% / 25% della barra e al ripristino si toglie. La barra non scende mai sotto 1 da sola: serve il colpo successivo per la rottura.
- **Test**: `test_v3_break.gd` (bloccato sul branch, OK in diagnostica).

### 5.8 Risorse, KO e reazioni

- **EN**: per eroe, `unit["energy"]`, massimo 6 (`MAX_ENERGY`). Guadagni e spese passano da `ResourceTelemetry.gain_unit/spend_unit`, che registrano richiesto, effettivo e sprecato. Fonti: APICE, Saul in APICE, SLANCIO con Guardia, Fuori onda, reazioni personali.
- **Ultimate / «Limit Break»**: nel codice non c'è un sistema chiamato Limit Break. L'equivalente è la barra `gauge` (0-100, `GAUGE_MAX`): +15 colpendo, +10 subendo, +8 / +18 con la parata buona / perfetta, +25 alla squadra a ogni fase del boss, TRACCIA +10 / +5. Si usa a 100 (`validate_choice`). Si può lanciare anche fuori turno durante la carica pesante del boss (`SeqRound.live_ults`, senza Riserva).
- **Riserva di squadra**: `state["reserve"]`, si parte da 3, massimo 6, +1 a round, +1 con la combo (una volta a round). Si spende per le reazioni (`reaction_cost` = `move.reserve` − `react_discount`).
- **KO e soccorso** (`battle_resolver.gd:870-895`): un caduto si soccorre una sola volta (`rescued`). Torna con il 25% dei PV, più il minigioco (+15% / -10%) e i bonus di Nox. Gli stati vengono azzerati. Il KO fa perdere 10 Ardore. **Qui c'è l'errore della riga 911**: è il bonus «reperibile» del soccorso di Nox.
- **GUARDIA e parata a tempo** (`_boss_act`): Guardia ×0,5 danno; parata a tempo ×0,6; perfetta ×0,25 più contrattacco ×0,9. La stessa parata decide il salvataggio del RITMO (decisione K4: un solo QTE).
- **Test**: `test_v3_parata.gd` (OK sul branch e in diagnostica), `test_v3_diretta.gd`, `test_v3_resource_telemetry.gd` (3 FAIL veri).

### 5.9 Serializzazione e ripresa

- In battaglia: `BattleState.to_json(state)` / `from_json` + `normalize()` (tutti i float diventano int). L'RNG è salvato nello stato (`_save_rng` / `_load_rng`), quindi la battaglia è deterministica a parità di seme.
- Tutti i sottosistemi nuovi tengono lo stato dentro il dizionario della battaglia (`ritmo`, `tl`, `seq`, `slancio_kept`, campi sul boss) e quindi passano dal JSON.
- **Difetto attuale**: `strategy_hits` contiene float (vedi 3), quindi il giro in JSON non è più identico. Anche `BattleFlow.timeline` e `Stability.enabled` sono `static var` e non fanno parte dello stato.
- Fuori dalla battaglia: `story.gd:120` salva capitolo, passo, flag, area e `Progress.data` in un `ConfigFile`. Lo stato della battaglia **non** si salva a metà scontro.

## 6. Cosa propongo di correggere (decide l'autore)

1. `battle_resolver.gd:911`: passare `events` a `react_bonus` (o togliere la telemetria da lì). È una riga: rimette in verde 11 dei 14 file che falliscono, toglie gli errori di script dai 9 «OK» sporchi e fa ripartire le battaglie.
2. `battle_resolver.gd:1116`: tenere `strategy_hits` fuori dallo stato, oppure salvarlo in interi (per esempio millesimi), come il resto dello stato.
3. `tools/v3_bilancio.gd:789`: rinominare la variabile `signal`.
4. Guardare `ResourceTelemetry.record/snapshot` per i 3 controlli di `test_v3_resource_telemetry`.

Non ho applicato nessuna correzione al branch, come chiede l'handoff.

## 7. Pubblicazione su itch.io: stato e proposta

**Non ho pubblicato nulla.** I motivi:
- le build hanno il motore di battaglia rotto (punto 4);
- in questo container non ci sono butler né la chiave: `ITCH_API_KEY` esiste solo come segreto di GitHub;
- `.github/workflows/itch.yml` parte solo con un push a `claude/v3-prologo` (file in `releases/`) o a mano, e carica sempre sui canali stabili `android-v3` / `windows-v3` di `boomeranza/odispel`. Usarlo così sostituirebbe la versione stabile;
- su itch un canale nuovo caricato con butler sulla stessa pagina compare tra i download pubblici della pagina. Butler non ha un «caricamento nascosto»: l'upload si può nascondere solo dopo, dalla dashboard.

**Proposta**, da fare solo con il via dell'autore:
1. correggere la riga 911 sul branch sperimentale e rifare test e build;
2. aggiungere un workflow separato, per esempio `.github/workflows/itch-sperimentale.yml`, che parte **solo a mano** (`workflow_dispatch`), prende APK e ZIP da un artifact o da una release GitHub (non da `releases/`), controlla la firma con apksigner e fa `butler push` sui canali `experimental-android` / `experimental-pc` con `--userversion 0.56.0-exp.c2.6+<commit>`;
3. come destinazione, meglio una **pagina itch separata in bozza o con accesso ristretto** (per esempio `boomeranza/odispel-lab`) che i canali sperimentali sulla pagina pubblica. Va creata dall'autore su itch;
4. poiché l'APK ha lo stesso pacchetto e la stessa chiave della stabile, installarlo sostituisce la 0.56.0 sul telefono. Se si vogliono tenere le due versioni insieme, serve un `package/unique_name` diverso (per esempio `com.gialloo.odispel.v3.lab`), ma è una modifica al progetto.

## 8. Aggiornamento: correzione della riga 911 (via dell'autore, 05/11/2026)

L'autore ha scelto «Correggo la riga 911 e rifaccio». Commit `e36c5a9`:
- `battle_resolver.gd`: `react_bonus(state, actor, kind, events: Array = [])` e il soccorso le passa la sua lista di eventi (`react_bonus(state, actor, "rescue", events)`). La telemetria del bonus «reperibile» di Nox resta, ora con la lista giusta. Nessun altro cambiamento di codice.
- `.github/workflows/itch-sperimentale.yml` (nuovo, vedi sotto).

**Import**: 0 errori. **Suite** (stesso runner, 180 s a file): **23 file su 26 passano**, log senza errori di script. Restano solo i tre già descritti al punto 3: `test_archetypes` (1, JSON), `test_battle` (2, JSON), `test_v3_resource_telemetry` (3). Risultato identico alla prova diagnostica.

**Atto 1 in automatico** (`xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_atto1.gd -- <dir>`): uscita 0, 0 errori di script, fino all'ultimo passo `c6_p8`, 108 schermate. Battaglie, tutte vinte in AUTO: frammento_giallo lv1 (1 round), distributore lv1 (4), semaforo lv3 (5), cabina lv5 (5), manichino lv7 (7), cassaforte lv9 (8), autovelox lv11 (5).

**Nuove build** da `e36c5a9`, export senza errori:

| | Android | PC |
|---|---|---|
| File | `ODISPEL_V3_sperimentale_c2.6_e36c5a9_android.apk`, 38.268.440 byte, firma v2 verificata da `sign_apk.py` | `ODISPEL_V3_sperimentale_c2.6_e36c5a9_pc.zip`, 49.634.957 byte |
| SHA-256 | `ee720f23…6f5e55` | `16a406a4…15f0fd` |
| Avvio | non provato: niente dispositivo o emulatore | il pck parte col binario Linux 4.7.2 senza errori di script; l'.exe non è provato (niente Windows o Wine) |

Si trovano in `/mnt/project-files/odispel/v3/build_sperimentale_c2.6/`. Le build rotte di `4ea37bc` sono in `rotte_4ea37bc/`.

**Workflow itch sperimentale** (`.github/workflows/itch-sperimentale.yml`), non ancora usato:
- parte solo con un push su `experiment/**` che cambia `releases_sperimentali/*.apk|*.zip`. Mettere lì le build vuol dire pubblicare, quindi serve un altro sì dell'autore;
- carica sui canali `experimental-android` e `experimental-pc`, con versione `0.56.0-exp.<branch>+<commit>`;
- la pagina di destinazione viene dalla variabile del repository `ITCH_LAB_TARGET`. Se manca, o se vale `boomeranza/odispel` (la pagina stabile), il workflow si ferma senza caricare;
- controlla la firma dell'APK con apksigner come `itch.yml`. `itch.yml` non è stato toccato.

Restano aperti, come al punto 6: `strategy_hits` nel JSON, `tools/v3_bilancio.gd:789` (`signal`), i 3 controlli della telemetria e il nome del pacchetto Android (se l'APK sperimentale deve stare sul telefono accanto alla 0.56.0).

## 9. Aggiornamento: correzione dei tre difetti rimasti (via dell'autore, 05/11/2026)

Commit `b667a09`:
- **Salvataggio JSON** (`battle_resolver.gd`): `strategy_hits` ora salva la pressione come intero e i moltiplicatori in millesimi interi (`link_mult_pm`, `combo_mult_pm`, `other_mult_pm`, `effective_mult_pm`, funzione `_pm`). Lo stato torna senza decimali e il giro in JSON è identico. `tools/v3_bilancio.gd` li rilegge dividendo per 1000.
- **`tools/v3_bilancio.gd:789`**: la variabile `signal` (parola riservata) diventa `concentrated_tag`.
- **Telemetria delle risorse**: il codice era giusto, l'errore era nel test. `test_v3_resource_telemetry.gd` cercava lo slot `"IO"`, ma `create_solo` chiama sempre lo slot `"p1"` (`"IO"` è solo il nome mostrato). Il personaggio risultava vuoto e non c'era niente da misurare. Ho cambiato lo slot in `"p1"` nelle due righe: è una correzione del test, non un modo per farlo passare a forza, e i controlli sono rimasti gli stessi.

**Import**: 0 errori. **Suite**: **26 file su 26 passano**, log senza errori di script.
**`tools/v3_bilancio.gd -- vel`** e **`tools/v3_bilancio.gd`** (bilancio dell'atto, legge `strategy_hits`): uscita 0, 0 errori di script.
**Atto 1 in automatico**: uscita 0, 0 errori di script, completo fino a `c6_p8`. Sei battaglie vinte. La Cabina (lv5) stavolta è persa al round 4, mentre nel giro dopo la correzione di `e36c5a9` era vinta al round 5. Anche round e tempi delle altre battaglie cambiano da un giro all'altro: la battaglia guarda l'orologio vero (`Time.get_ticks_usec`, parata a tempo) e questo giro girava insieme agli export, sotto llvmpipe. Le modifiche di `b667a09` toccano solo la telemetria, che sta fuori dagli eventi e dall'RNG, e i test deterministici del motore passano tutti. Non ho dimostrato che la sconfitta dipenda dal carico: un secondo giro del solo capitolo 2 è finito oltre il limite di tempo senza un esito.

**Build da `b667a09`**, export senza errori, pck avviato senza errori di script:
- `ODISPEL_V3_sperimentale_c2.6_b667a09_android.apk` (firma v2 verificata da `sign_apk.py`)
- `ODISPEL_V3_sperimentale_c2.6_b667a09_pc.zip`

Si trovano in `/mnt/project-files/odispel/v3/build_sperimentale_c2.6/`. Quelle di `e36c5a9` sono in `superate_e36c5a9/`. La pubblicazione su itch aspetta ancora la pagina di prova (`ITCH_LAB_TARGET`) e il via dell'autore (punto 8).

