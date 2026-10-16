# Battaglia V2 — audit e piano (prima consegna, nessun codice di gioco modificato)

Data: 2026-10-16 · Branch di lavoro: `claude/battaglia-v2` · Base: `claude/battaglia-chiara` @ `32aa105`

## 1. Punto di ripristino (verificato)
- Versione REALE nel repo: **0.26.2** (non 0.26.0): contiene impact frames (0.26.0), AUTO anti-doppio-tocco (0.26.1) e tuning impact frames + ottimizzazioni (0.26.2). Working tree pulito, nessuna modifica non salvata, remoto == locale (`32aa105`).
- Ripristino: il ramo `claude/battaglia-chiara` NON viene toccato; copia di sicurezza remota `claude/ripristino-pre-battaglia-v2` (stesso commit); tag locale `ripristino/pre-battaglia-v2`. Il push dei tag al remoto e' rifiutato (HTTP 403 dal proxy), quindi il tag esiste solo localmente: il punto di ripristino remoto verificabile e' il ramo di copia.
- Build gia' pubblicate in `releases/` (0.26.0, 0.26.1, 0.26.2): non vengono toccate.
- Per tornare indietro: `git checkout claude/battaglia-chiara` (o `claude/ripristino-pre-battaglia-v2`). Nessun file va ricostruito.

## 2. Audit — inventario e classificazione
Legenda: A = logica da preservare · B = presentazione rifacibile · C = misto da separare con cautela · D = da valutare (mai eliminare in automatico).

### Motore e stato (A)
| Componente | File | Note |
|---|---|---|
| Risoluzione round (eventi `act`, `damage`, `down`, `phase`, ...) | `scripts/battle/battle_resolver.gd` (1258 righe) | deterministico, dizionari; la UI non deve cambiarlo |
| Stato, unita', giocatori | `battle_state.gd`, `battle_types.gd`, `battle_content.gd` (mosse, personaggi, boss, passive), `signatures.gd`, `factions.gd`, `atypical.gd`, `archetypes.gd` | dati di gioco |
| Tattiche, segni, combo, reazioni, arena | `tactics.gd`, `marks.gd`, `combos.gd`, `arena.gd`, `strategy_info.gd` | regole |
| IA e autoplay | `battle_ai.gd`, `BattleResolver.autoplay_round` | |
| PvP | `pvp_engine.gd` (813), `pvp_local_source.gd`, `pvp_rewards.gd` | motore separato per PvP a squadre |
| Ricompense/progressione | `battle_rewards.gd`, `roster/*` (`RosterState`, `Endless`, `Expedition`, `Daily`, `Weekly`, `Extras`, `Feats`) | |
| Rete | `network_manager.gd` (1665), `net_session.gd`, `battle_net.gd`, `network_snapshot.gd`, `webrtc_link.gd` | host autoritativo |
| Config di partita | `scripts/battle/mission_config.gd` (statico) | boss, tier, endless, giornaliera, spedizione |

### Interfaccia "sorgente" (A, gia' esistente: e' il contratto da riusare)
`SoloBattleSource` / `PvpLocalSource` / `NetworkManager` espongono lo stesso contratto, che `battle_screen.gd` usa cosi':
`battle` (Dictionary), `local_player_id`, `battle_time_left`, segnali `battle_updated` e `battle_events_received(events)`, `submit_choice(choice)`, `submit_party(choices)`, `my_slots()`, `autoplay_round()`, `finish() -> rewards`, `daily_first`, `send_chat()` (rete). La V2 usera' SOLO questo contratto.

### Schermata attuale `scenes/battle/battle_screen.gd` (3147 righe) — sezioni
| Sezione (righe) | Classe | Note |
|---|---|---|
| Layout, pannelli, ventaglio ordini, log, turno, boss, operatori (380-1560, 1555-1760) | **B** | rifacibile, ma legge molti dati di dominio (Hints, Tactics, Arena...) |
| `_refresh_*` (boss, operatori, ordini, tattiche, reazioni, telegrafo) | **C** | mescolano "cosa mostrare" (calcolo da stato) con "come disegnarlo": va estratto un view-model |
| `_make_choice`, `_most_hurt_ally`, validazione (1747-1770) | **C** | costruzione della scelta (incl. bersaglio automatico dell'alleato piu' ferito) e' regola di gioco finita nella UI |
| `_start_solo` (192-250) | **C** | costruisce `SoloBattleSource` da `MissionConfig` + note introduttive: configurazione, non presentazione |
| `_play_events`, `_event_fx`, `_fx_*`, `_hit_anim`, impact frames, cut-in, slow motion, shake (1862-2565) | **B** (ma da riusare) | gli effetti (`ImpactFrames`, `ImpactDirector`, `ImpactOverlay`, `ComicFx`, `AnimFx`, `CutIn`, `UltFx`, `BattleStage.impact/freeze`) sono sistemi condivisi: la V2 li richiama, non li duplica |
| `_recap_*`, `_open_replay`, `_mvp_line` (2188-2360, 2886) | **C** | resoconto "perche' ho vinto/perso": calcolo + testo |
| `_check_end`, `_show_result`, ricompense, scelta boon, `_on_again` (2862-3147) | **C** | chiama `source.finish()`, scene di storia, avanzamento Ciclo Infinito (`MissionConfig.set_endless`) |
| Tutorial/coach (130-190) | **B** | `BattleCoach`, `TutorialOverlay` |
| AUTO, velocita', pausa, tasti (336-380, 1808-1860) | **B** | usa `source.autoplay_round` |
| Battute (`banter`) | **B** | |
| Rete (chat, ping rapidi in `bind_source`) | **C** | solo con `NetworkManager` |

### Palco `scenes/battle/battle_stage.gd` (1629) + `pvp_stage.gd` (126) — **B riusabile**
Disegno procedurale (sfondo, boss, operatori, barre PV); espone `impact`, `freeze`, `flash`, `anchor_of`, `set_state`. E' il pezzo gia' ottimizzato (testi in cache, sfondo statico): conviene riusarlo nel prototipo e rifarlo solo se serve.

### PvP (`scenes/battle/pvp_screen.gd`, 851) — **B + C**
Schermata separata col proprio motore (`PvpEngine`). Fuori dal primo perimetro della V2 (vedi piano).

### Altri sistemi (nessuno e' D per ora)
Impact frames (0.26.x), icone (`GameIcon`/`IconCatalog`), `BattleTheme`, `HudPanel`, `InfoChip`, `ScreenFrame`, `TouchUi`: condivisi, **non** da duplicare. Nessun componente e' dichiarato obsoleto: l'unico candidato da rivalutare dopo l'approvazione e' il vecchio `battle_screen` stesso, solo a V2 collaudata.

### Dipendenze esterne dalla schermata attuale (da rendere "V2-aware")
- `SceneRouter.SCENES["battle"]` e `is_current("battle")` (usato da `net_session.gd`, righe 37/147/268/290) → serve una chiave `battle_v2`.
- `audio_manager.gd:144` sceglie la musica con `scene_file_path.contains("battle_screen")`.
- `room_bar.gd:133` nasconde la barra stanza in battaglia con lo stesso controllo.
- `net_session.gd:37` imposta `Settings.in_battle` (limite fps) per la scena corrente.
- Chi avvia la battaglia: `story.gd`, `endless.gd`, `daily.gd`, `weekly.gd`, `expedition_screen.gd` con `SceneRouter.go("battle", true)` (invariati: non cambiano finche' non c'e' approvazione).
- Test che toccano `battle_screen` (membri privati inclusi): `test_battle_ui`, `test_hud_layout`, `test_hud_states`, `test_input_ui`, `test_autoplay_toggle`, `test_missions`, `test_audio_tutorial`, `test_room_ui`, `test_cleanup`, `test_art_dialogue`, `test_touch_gacha`; strumenti: `tools/battle_shot`, `hud_count`, `ui_audit`, `perf_battle`, `impact_flow`, ecc. Restano validi sulla vecchia scena; la V2 avra' i suoi.

### Test e strumenti esistenti riusabili
79+ file in `tests/unit/` (suite completa), `tools/ui_audit.gd` (PC e touch), `tools/hud_count.gd`, `tools/perf_battle.gd`, `tools/impact_shot.gd`, `tools/impact_flow.gd`. Esportazione: `docs/HANDOFF_COMPLETO.md` sez. 11 (APK release firmato con chiave di debug, zip Windows).

## 3. Proposta di architettura — Battaglia V2

Principi: nessun secondo motore; la V2 e' una **nuova vista** sullo stesso contratto di sorgente. La vecchia scena resta il percorso predefinito.

```
MissionConfig ──► BattleLauncher (nuovo, logica di avvio)
                         │ crea
                         ▼
      SoloBattleSource / (poi) NetworkManager   ← contratto invariato
        battle, signals, submit_choice/party, finish
                         │
           ┌─────────────┴──────────────┐
           ▼                            ▼
  battle_screen.gd (VECCHIA)     BattleV2Screen (NUOVA)
                                   ├ BattleViewModel  (stato → dati da mostrare, senza Control)
                                   ├ BattleChoiceBuilder (scelta + bersaglio, riuso regole)
                                   ├ componenti UI in scripts/ui/battle_v2/
                                   ├ BattleStage (riuso) + ImpactDirector/ComicFx/AnimFx/CutIn (riuso)
                                   └ BattleResultView (usa source.finish(), non ricalcola premi)
```

1. **Scena nuova e separata**: `scenes/battle_v2/battle_v2_screen.tscn` + `.gd` (controller sottile: collega sorgente, view-model, componenti, effetti).
2. **View-model** (`scripts/battle_v2/battle_view_model.gd`, `RefCounted`, testabile senza UI): da `shown`/eventi produce righe del turno, blocco boss (PV, equilibrio, telegrafo), righe operatori, stato degli ordini (usabile/non usabile + motivo da `BattleResolver.validate_choice`), pericoli. Usa le stesse funzioni esistenti (`BattleText`, `Hints`, `Tactics`, `Arena`): nessuna regola nuova.
3. **Avvio**: `BattleLauncher` (`scripts/battle_v2/battle_launcher.gd`) replica `_start_solo` (crea e configura `SoloBattleSource` da `MissionConfig`, ritorna anche le note introduttive). Nel prototipo la vecchia scena NON viene modificata (duplicazione temporanea di ~25 righe, documentata); dopo l'approvazione la vecchia scena puo' chiamare il launcher e il duplicato sparisce, con test di equivalenza.
4. **Scelta ordini**: `BattleChoiceBuilder` replica `_make_choice`/`_most_hurt_ally` richiamando `BattleResolver.validate_choice`; stesso discorso del punto 3. Se emerge che questa e' regola e non UI, proporro' di spostarla in `BattleResolver` con una modifica minima (da approvare).
5. **Componenti UI** (nuovi, Control disegnati a codice come il resto): barra superiore, pannello boss, pannello squadra, ventaglio ordini, linea del turno, log, riquadro risultato. Riusano `BattleTheme`, `HudPanel`, `GameIcon`, `InfoChip`, `TouchUi`, `ScreenFrame`.
6. **Effetti**: `_event_fx` della V2 richiama gli stessi sistemi condivisi (impact frames inclusi). Stessa regola KO senza doppio effetto.
7. **Ingresso di debug (non predefinito)**: chiave `battle_v2` in `SceneRouter`, pulsante "PROVA BATTAGLIA V2" nelle impostazioni (accanto alla prova impact frames) e `tools/battle_v2_shot.gd`; modalita' dati di prova isolati per la fase 4 (`BattleViewModel` alimentato da uno stato costruito con `RosterState.create_solo_battle`, nessun salvataggio).
8. **Perimetro per fasi**: V2 solo PvE solitario all'inizio (stesso contratto che usa gia' `NetworkManager`, quindi il multiplayer cooperativo si aggiunge dopo, senza toccare rete/host). PvP (`PvpScreen`, `PvpEngine`) fuori dal primo perimetro: decidere dopo.
9. **Regressione**: test di parita' (stesso seme e stesse scelte → stessi eventi/stato finale sulle due viste, perche' il motore e' lo stesso), `ui_audit`/`hud_count` sulla V2, test sul view-model, confronto prestazioni con `perf_battle`.

## 4. File
**Nuovi (previsti)**
- `scenes/battle_v2/battle_v2_screen.tscn`, `scenes/battle_v2/battle_v2_screen.gd`
- `scripts/battle_v2/battle_view_model.gd`, `battle_launcher.gd`, `battle_choice_builder.gd`
- `scripts/ui/battle_v2/*.gd` (componenti: top bar, boss panel, squad panel, order fan, turn line, log, result)
- `tests/unit/test_battle_v2_*.gd` (view-model, launcher, parita' col motore, layout PC/touch)
- `tools/battle_v2_shot.gd`, `tools/battle_v2_audit.gd`
- `docs/BATTAGLIA_V2_PIANO.md` (questo file) e sezione in `QA_HANDOFF.md`

**Da modificare (minime, additive, non cambiano il comportamento attuale)**
- `scripts/ui/scene_router.gd` (+1 chiave `battle_v2`)
- `scripts/audio/audio_manager.gd`, `scripts/ui/room_bar.gd`, `scripts/network/net_session.gd` (riconoscere la V2 come "in battaglia": musica, barra stanza, limite fps)
- `scenes/ui/settings_panel.gd` (pulsante di prova)
- `scripts/config/changelog.gd`, `game_config.gd`, `export_presets.cfg`, `QA_HANDOFF.md` (a ogni consegna)

**Potrebbero dover cambiare solo dopo approvazione**
- `scenes/battle/battle_screen.gd` (usare `BattleLauncher` / `BattleChoiceBuilder` per eliminare i duplicati), `scenes/battle/battle_stage.gd` (eventuali ganci di layout per la V2), `scripts/battle/mission_config.gd` (flag "usa V2" per l'avvio da missioni, SOLO per il collaudo).

**Mai toccati**: `battle_resolver.gd`, `battle_state.gd`, `pvp_engine.gd`, rete (`network_manager.gd`, `webrtc_link.gd`, `network_snapshot.gd`), salvataggi, ricompense, formule.

## 5. Rischi e punti aperti
1. Regole nella UI: bersaglio automatico di cure/purifica (`_most_hurt_ally`) e avanzamento Ciclo Infinito in `_on_again` stanno in `battle_screen.gd`: vanno trattati con cautela (punti 3-4).
2. Molti test leggono membri privati di `battle_screen`: non vanno riscritti, la V2 avra' test propri.
3. `Settings.in_battle`/musica/barra stanza dipendono dal nome del file della scena: senza gli aggiornamenti elencati la V2 userebbe fps e musica da menu.
4. Prestazioni: la V2 deve restare entro il costo attuale (misure con `perf_battle`; ricordare il lavoro di ottimizzazione della 0.26.2).
5. Nessun collaudo su telefono e' possibile da questo ambiente: ogni fase andra' provata da te su Android prima di decidere la sostituzione.

## 6. Prossimi passi (dopo la tua approvazione)
Fase 3: scheletro scena + contenitore UI + chiave `battle_v2` + pulsante di prova → Fase 4: prototipo visivo con dati isolati → 5: stato reale → 6: input → 7: feedback/impact frames → 8: regressione → 9: prova PC/Android → 10: decisione tua sulla sostituzione.

---

## 7. Addendum — direzione artistica (decisioni dell'utente + brief "Metaphor: ReFantazio")

**Stato**: solo documentazione e bozze visive; nessuna implementazione. La V2 resta in attesa di approvazione.

### 7.1 Decisioni gia' prese (bozze `docs/battaglia_v2_mock/`)
- Campo di battaglia 3D (sfondo), personaggi e boss come sprite 2D.
- Ruota di comando attorno al personaggio, in senso orario: **Attack, Skill, Ultimate, Guard** (+ piccolo "Situazionale", visibile solo se disponibile).
- Ogni comando = pennellata di vernice nel colore del personaggio + lettera gigante (A/S/U/G) + cerchio con numero + titolo inclinato con striscia sottotitolo.
- Skill/Ultimate selezionata: **stessa vernice**, con glow e colori accesi (NON light painting); sfondo 3D e figure si oscurano leggermente, vernice e HUD restano luminosi; comparsa del banner dell'abilita'.
- Ordine turni in alto a sinistra (pennellata nera con stelle), nome boss in alto a destra, bersaglio sul boss (cerchio + barra diagonale), squadra 3-2-1 in basso a destra (emblema numerato, PV, seconda barra), barra comandi in basso a sinistra (Formazione, Bersaglio, Auto, Velocita').
- `hud3_*` = versione approvata (palette libera); `hud4_*` = stessa composizione con la palette funzionale del brief. Da confrontare; si usa la migliore, l'altra resta come riferimento.

### 7.2 Palette funzionale ODISPEL (dal brief)
nero/antracite = profondita'; bianco caldo = leggibilita' (testi, PV); **corallo/rosso = pericolo e impatto** (banner boss, nemici, telegrafo attacco); **magenta = energia Odica e ultimate**; **ciano = selezione e info tattiche** (bersaglio, attore attivo, ordine turni alleati); **giallo = opportunita' e conferme** (selezione confermata, debolezza sfruttabile). Il colore di vernice resta quello del personaggio. Un colore = una funzione; mai tutti insieme.

### 7.3 Requisiti aggiunti dal brief (da rispettare nella V2)
1. **Informazioni per priorita'**: mostrare solo cio' che serve nella situazione (es. Situazionale solo se utilizzabile, debolezze solo se pertinenti, telegrafo solo se il boss sta caricando).
2. **Boss dominante**: PV/stato senza pannelli ingombranti; fasi e vulnerabilita' quando pertinenti; attacchi imminenti e finestre di contrattacco/rottura guardia evidenziati.
3. **Grammatica di movimento** (breve, con ease intenzionali, interrompibile, mai bloccante per input e turni): ingresso schermata, introduzione nemici, comparsa comandi, selezione/conferma, cambio bersaglio, esecuzione, danno, cambio turno, vittoria/sconfitta.
4. **Feedback coordinati con gli eventi reali** (impact frames, cut-in ultimate, critici, numeri danno, KO/FINISH, vulnerabilita'/rottura guardia), senza duplicati.
5. **Responsive separato**: PC (1280x720 e oltre) cinematografico e preciso; Android touch con bersagli piu' grandi, densita' ridotta, controlli che non coprono personaggi/boss/indicatori di pericolo; non un semplice ridimensionamento. Aspect ratio diversi.
6. **Vincoli tecnici**: nessun dato fittizio nella versione integrata; registro icone esistente; compatibilita' impact frames; shader compatibili col renderer Compatibility; attenzione a prestazioni/memoria mobile; opzione riduzione effetti e leggibilita'.
7. **Asset**: nelle bozze gli sprite sono **segnaposto disegnati a codice** e il 3D e' fatto di forme semplici; nessun segnaposto deve restare nella versione integrata senza segnalarlo. La vernice reale richiedera' texture/pennelli dipinti o un generatore piu' ricco.
8. **Metodo**: fasi 1-2 (audit, concept) gia' consegnate; fase 3 (prototipo isolato) solo dopo approvazione; non passare alla fase successiva con problemi aperti.

### 7.4 Domande ancora aperte
Cosa fanno esattamente Situazionale / Formazione / Bersaglio; quanto 3D reale sui telefoni; quali dati sempre visibili; partire dal solo PvE solitario?; gestione di piu' operatori attivi.

### 7.5 Palette HUD v5 (proposta, in confronto)
Colori dei personaggi: blu, verde, rosso, giallo, viola. Nessuna tinta libera per le risorse, quindi: barre e risorse **neutre** (vita = avorio a segmenti; energia = bianco-ghiaccio; scudo = argento con tratteggio; riserva = rombi avorio), l'unico colore saturo di una riga e' quello del personaggio; ciano solo per selezione/bersaglio/attivo; pericolo = banner nero con righe bianche, icona gialla, corallo solo sul lato boss. Bozze: `docs/battaglia_v2_mock/hud5_<colore>_libera.png` (+ `mock5.gd.txt`).

### 7.6 Decisioni successive (sessione di bozze)
- **Base scelta: v6 con Kira** (`hud6_kira_*`): ruota attorno al personaggio con lettere giganti dietro lo sprite. Le varianti v6b (lettere piu' piccole), v6c/v6d (ruota ruotata, lettere davanti), v7, v8 e v9 sono scartate o in sospeso, restano nel repo come riferimento.
- **Barre sottili ed eleganti** (`hud10_kira_*`): vita boss ciano 5 px a segmenti fini con punta luminosa; equilibrio boss bianco 3 px; righe squadra con vita 4 px avorio, energia 2 px bianco-ghiaccio, scudo come filo argento tratteggiato; numeri piccoli allineati a destra. Niente piu' barre spesse con riflesso.
- **Ordine turni**: quadrati decrescenti sulla linea bianca, 1-3 numerati; contatore turno sotto "TURNI" ("3" oppure "3/20" nelle battaglie a tempo).
- **Asset di prova**: Kira usa `battle.png` (sprite), `neutral.png` (ritratto nell'ordine turni) e `cutin.png` (ritaglio nella riga squadra). Boss, altri personaggi e tutti i numeri sono segnaposto.
- **Banner dell'abilita' scelta con dissolvenza** (`hud12_kira_*`): opacita' 100% sul bordo sinistro, 50% a circa meta' della prima parola, 0% 40 px oltre la fine del testo (curva ease-out); alone e filetti colorati sfumano con la stessa curva. Contiene qualunque lunghezza di nome (prova: `hud12_kira_prova_nome_lungo.png`). Vale sia per Skill sia per Ultimate.
- **Bordi del banner sfumati** (`hud13_kira_*`): bande continue con colore per vertice (nessuna cucitura); bordi esterni (sopra, sotto, sinistra) sfumati su ~11 px, filetti colorati sottili con alone morbido, che sfumano lungo la lunghezza con la curva a 100/50/0%. In Godot si realizza con `draw_polygon` a colori per vertice e `draw_polyline_colors`, compatibile col renderer Compatibility.
- **Filetti del banner bianchi** (`hud14_*`): i due filetti (sopra e sotto) e il loro alone sono sempre bianchi, indipendentemente dal colore del personaggio; il colore del personaggio resta sull'icona, sulla vernice e sull'alone esterno leggero.
- **Scala tipografica e proporzioni** (`hud15_*`): titoli 28, comandi/nomi 18, sottotitoli ed etichette piccole 14 (minimo assoluto, prima 11-13), icona = 60% del diametro del proprio cerchio ovunque (ruota, comandi rapidi, situazionale); icone e testo delle stesse righe centrati sulla stessa linea (baseline = centro + 0,35 x corpo). Valori squadra (PV + energia) sulla riga del nome, nessun testo fuori riga. Nel gioco integrato: dimensione minima a schermo (es. >= 11 px per il testo, >= 44 px per i bersagli touch) e layout separato per Android, perche' il solo ridimensionamento proporzionale rimpicciolisce il testo piccolo (vedi `hud15_prova_854x480.png`).
- **Ordine turni a rettangoli alti** (`hud17_*`): ritratti verticali (larghezza = 0,74 x altezza; 88/68/56/48/42 px), spaziati di 46 px; la freccia bianca finisce a x=630 (prima 800) per lasciare spazio al nome del boss.
- **Banner del boss adattivo**: ancorato a destra, cresce verso sinistra fino a un limite (638 px totali) in base alla lunghezza del nome; oltre il limite riduce il carattere (da 28 a 22) e poi tronca con "…". Barre ed etichette seguono la larghezza del banner. Prove: `hud17_kira_prova_boss_lungo.png`, `..._lunghissimo.png`.
- **Rimossa la linea nera** sotto i comandi rapidi (Formazione, Bersaglio, Auto, Velocita').
- **Correzione**: i ritratti dell'ordine turni sono rettangoli **larghi** (`hud18_*`), non alti: larghezza = 1,7 x altezza (54/43/37/32/28 px di altezza), spaziati di 30 px, ritaglio del ritratto sugli occhi; freccia che finisce a x=640; limite sinistro del banner boss a 618 px totali. Sostituisce la versione a rettangoli alti (`hud17_*`).
