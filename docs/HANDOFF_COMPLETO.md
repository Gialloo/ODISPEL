# ODISPEL - HANDOFF COMPLETO PER UNA IA

Questo documento istruisce un'IA (o una persona) che prende in mano ODISPEL. Descrive lo stato **reale** del progetto alla
versione **0.24.21** (14 ottobre 2026): cosa e' stato fatto, come e' fatto, come si lavora, cosa manca.
Leggilo tutto prima di toccare codice. Quando qualcosa qui dentro e' in contrasto con il codice, **vince il codice**: verificalo.

---

## 0. In breve

- **Cos'e'**: battler cooperativo a turni contro boss (con PvP), fantasy urbano notturno, stile anime/visual novel. Nome: ODISPEL.
- **Motore**: Godot **4.7.2**, renderer `gl_compatibility` (anche su mobile), GDScript. Risoluzione base **1280x720**.
- **Interfaccia**: tutta costruita **da codice** (Control), nessun editor visuale richiesto. Le `.tscn` sono quasi vuote.
- **Piattaforme**: Windows (exe) e Android (APK). Multiplayer con **WebRTC** (host autoritativo) e server di segnalazione Node.js su Render.
- **Repository**: `Gialloo/odispel` (privato). Il lavoro attuale sta **solo** sul ramo `claude/battaglia-chiara`.
- **Lingua del gioco e dei messaggi all'utente**: italiano, semplice (gli amici che giocano non sono tecnici).
- **Autore/utente**: un solo sviluppatore non tecnico-esperto, che prova le versioni con amici. Vuole risposte semplici, passo passo.

---

## 1. Regole di lavoro (OBBLIGATORIE)

Queste regole vengono dall'utente e dalle sessioni precedenti. Rispettale.

1. **Rispondi sempre in italiano**, semplice, passo passo, senza gergo (se usi un termine tecnico, spiegalo).
2. **Ramo**: lavora e fai push **solo** su `claude/battaglia-chiara`. **Mai** push su `main`. Non creare pull request se non richiesto.
3. **Il repository resta privato.** Mai pubblicarlo, mai renderlo pubblico.
4. **Mai condividere password, token o chiavi.** Le credenziali TURN stanno **solo** in `config/turn.cfg` (ignorato da git, vedi `docs/TURN.md`).
   Non incollare in chat ne' scrivere nel repository password di itch.io, chiavi `butler`, ecc.
5. **Messaggi di commit**: chiudili con queste due righe esatte (separate da una riga vuota dal corpo):
   ```
   Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
   Claude-Session: https://claude.ai/code/session_017MDq3tJoDSmxmKKpEz1CJ9
   ```
   (Se la sessione cambia, usa quella corrente; per le PR vale l'attribuzione che il sistema indica.)
6. **Quando l'utente chiede "mandami lo screenshot e aspetta la mia conferma"**, **non fare push** fino alla conferma. Si possono fare commit locali.
7. **Non lanciare test di bilanciamento** (simulazioni di vittorie/sconfitte) a meno che l'utente non lo chieda: ha detto "li faro' io".
8. **Limite upload in chat: 30 MiB.** I file piu' grandi (APK, zip Windows) vanno pubblicati su GitHub (cartella `releases/`) e/o itch.io.
9. **Hook "stop" del repository** (`~/.claude/stop-hook-git-check.sh`): se dice "unpushed commits / no remote branch" ma il ramo remoto esiste ed e' allineato
   (`git ls-remote origin claude/battaglia-chiara` uguale a `git rev-parse HEAD`), e' un **falso allarme**: rispondi brevemente "falso allarme". Se invece i commit locali sono davvero avanti e l'utente
   ha detto di pubblicare, fai push.
10. **Verifica prima di dichiarare "fatto"**: test, audit dei pulsanti (`tools/ui_audit.gd`), e per le modifiche visive uno screenshot guardato davvero.
11. Aggiorna `Changelog` (`scripts/config/changelog.gd`) e `GameConfig.VERSION` a ogni versione rilasciata (e `export_presets.cfg`: `version/code` +1, `version/name`).
    Host e client multiplayer devono avere **la stessa versione**.

---

## 2. Struttura del repository

| Percorso | Contenuto |
|---|---|
| `scripts/battle/` | **Motore di combattimento** (stato, risoluzione, IA, premi, contenuti, testi). Non conosce la grafica. |
| `scripts/roster/` | Collezione del giocatore, equipaggiamento, reclutamento, missioni giornaliere/settimanali, spedizione, titoli, potere, maestria, obiettivi, tutorial, salvataggio. |
| `scripts/network/` | WebRTC, sessione di rete (`NetSession`, autoload), sincronizzazione battaglia (`BattleNet`, `NetworkManager`). |
| `scripts/ui/` | Pezzi di interfaccia riusabili: `BattleTheme`, `HudPanel`, `LineBar`, `SegBar`, `GameIcon`, `SlantBox`, `FanMenu`, `ScreenFrame`, `Notify`, `Snd`, `SceneRouter`, `TouchUi`, `ComicFx`, `CutIn`, `UiMotion`... |
| `scripts/config/` | `GameConfig` (versione, URL server), `Changelog`, `Settings`, `Profile`, `Diagnostics`. |
| `scripts/art/` | `ArtLibrary` (cerca le grafiche per nome), `PortraitView` (ritratto o segnaposto), `AnimeFace`. |
| `scripts/story/` | Dialoghi e scene di storia (stagione 1 e stagione 2). |
| `scripts/audio/` | `Sfx` (autoload) e `Snd` (porta d'ingresso). |
| `scripts/combat`, `party`, `run`, `session`, `main`, `data`, `save` | Primo prototipo del combattimento + stato campagna/salvataggio storico. Mantenuto com'e'. |
| `scenes/` | Le schermate: `hub`, `missions`, `roster`, `lobby`, `battle` (battaglia PvE e PvP), `expedition`, `feats`, `titles`, `tutorial`, `story`, `results`, `ui` (pannelli profilo/impostazioni), `combat` (prototipo). |
| `tests/unit/` | **71 file di test**, uno per area. |
| `tools/` | Strumenti: simulatori, foto delle schermate, benchmark, `ui_audit.gd`, `shrink_apk.py`, `esporta.ps1`, ecc. |
| `docs/` | Documentazione (vedi sezione 14). |
| `config/` | `turn.cfg.example` (il vero `turn.cfg` e' ignorato da git). |
| `odispel-signaling/` | Server Node.js di segnalazione (Render) con test. |
| `releases/` | **APK e zip Windows pubblicati** (ramo `claude/battaglia-chiara`). |
| `addons/` | Estensione `webrtc_native` (necessaria per WebRTC; la `.dll` per Windows va accanto all'exe). |
| `art/`, `assets/` | Grafiche, audio, font. |
| `build/` | Esportazioni locali (**ignorata da git**). |

Autoload (project.godot): `CampaignState`, `SaveManager`, `NetSession`, `Feedback`, `Sfx`.
**Attenzione**: nei test lanciati con `-s` (SceneTree) gli identificatori degli autoload **non** sono utilizzabili direttamente; usa `get_node_or_null("/root/NetSession")`.

---

## 3. Principi architetturali

1. **Il motore non disegna e l'interfaccia non decide.** Tutto cio' che cambia il risultato di una battaglia sta in `scripts/battle`.
2. **Stato = Dictionary di soli `int`, `String`, `Array`, `Dictionary`, `bool`.** Niente float: tutto in interi (percentuali in punti per cento o per mille, punti base).
   Lo stato deve **sopravvivere identico a un round trip JSON** (test: `test_battle`, `test_archetypes`, `test_libra_marks`...). Un float nello stato rompe l'uguaglianza
   (errore gia' successo con `boss_boost`: ora e' un intero in %). `BattleState.normalize` converte i float interi in int.
3. **Deterministico**: nessun `randf()` nel motore. Il seed viaggia nello stato; premi e IA sono deterministici. Servono a far girare **la stessa battaglia sull'host e (via snapshot) sui client**.
4. **Host autoritativo** in rete: l'host risolve i round; i client inviano scelte e ricevono snapshot/eventi (`BattleNet`, `NetworkManager`). `BattleNet.clean_choice` filtra le scelte
   (tiene `swap`, `move`, `target`, `order`, `push`).
5. **Porte d'ingresso che non fanno nulla senza gestore** (`Notify`, `Snd`, `SceneRouter`): il codice di gioco le chiama sempre, i test girano senza.
   `Notify` ha `success`, `warning`, `toast`; **non** ha `info`.
6. **Interfaccia tutta da codice**; `HudPanel` ha le opzioni `bare`, `quiet`, `backdrop`, `margins`, `cut`. Le schermate si "inquadrano" in un riquadro 1280x720 dentro l'area sicura (`ScreenFrame`).
7. **Prestazioni**: ricostruire i nodi solo se cambia una "firma" dello stato mostrato (`_orders_sig`, `_ops_sig` in battaglia); sfondo statico "fotografato" in texture; cache di `Titles`/`Power`.
8. **Sorgenti di battaglia con la stessa interfaccia**: `SoloBattleSource` (da soli), `NetworkManager` (rete), `PvpLocalSource`/PvP (`PvpEngine`, motore a parte). La schermata di battaglia lavora su "una sorgente".

---

## 4. Il motore di combattimento (scripts/battle)

File principali: `battle_types.gd` (costanti), `battle_content.gd` (dati: mosse, passive, personaggi, equipaggiamento, boss), `battle_state.gd`, `battle_resolver.gd`,
`battle_ai.gd`, `battle_rewards.gd`, `battle_text.gd`, `signatures.gd`, `factions.gd`, `archetypes.gd`, `combos.gd`, `marks.gd`, `arena.gd`, `tactics.gd`, `atypical.gd`, `hints.gd`, `lore.gd`.

### 4.1 Round e risorse
- Ogni giocatore ha **front row** (max 3 in solitaria; in rete ciascuno porta 3 operatori, 1 in campo) e **back row** (panchina). Si puo' fare **swap** con un compagno in panchina.
- **Energia** per operatore: `START_ENERGY 2`, `MAX_ENERGY 6`, rigenera +1 se attivo, +2 in panchina.
- **Barra ultimate (gauge)**: 0-100; +15 colpendo, +10 subendo danno; a 100 si usa l'ultimate.
- **Munizioni** (LibraCorp): `AMMO_MAX 3`, alcune mosse ne consumano/ne ricaricano (`Ricarica`).
- **Riserva di squadra**: `RESERVE_START 3`, max 6, +1 a round, +1 con una combo; si spende per le **reazioni**. Dalla fase 2 il boss la prosciuga.
- **Colori** (rosso, verde, blu, giallo, viola) con vantaggio x1.5 / svantaggio x0.67 (`BEATS`). **Classi**: striker, vanguard, warden. **Rarita'**: comune, rara, epica, leggendaria.
- Statistiche: `BattleContent.compute_stats(entry)` = classe x livello x rank x rarita' x stat_mult del personaggio x veterano/ferito (Expedition) x **titoli** x **bonus kit completo** + equipaggiamento.

### 4.2 Il kit (NOVITA' 0.24.21 - importante)
- Ogni operatore ha **4 slot di mosse + ultimate** (`BattleTypes.SKILL_SLOTS = 4`).
- Negli slot possono stare: **Attacco**, **Guardia** (`BASIC_MOVES`, mosse base, non servono copie), **skill** possedute (inventario `roster["moves"]`),
  e le **abilita' uniche** del personaggio (`Signatures`, campo `unique` della mossa = id del personaggio; non servono copie).
- Il kit e' `entry["skills"]` (lista ordinata). `BattleState.kit_of(equipped, sigs)` lo normalizza: tolti i doppioni, max 4, **resta sempre almeno una mossa base** (se manca viene reinserito "attack"),
  le mosse base compaiono prima nel menu.
- **Vecchi kit** (senza Attacco ne' Guardia = salvataggi precedenti): `kit_of` e `RosterState.migrate_kits` li convertono in `[attack, guard, skill..., uniche...]` tagliato a 4.
  In `from_json` l'ordine e': `sync_faction_moves` poi `migrate_kits`.
- **Kit di base** (`BattleContent._default_skills`): `attack, guard, <skill del personaggio>, [ricarica se LibraCorp]`, poi gli slot rimasti vanno alle abilita' uniche (`Signatures.skills_for(char,0)`), max 4.
  Le uniche **non** entrano nell'inventario `roster["moves"]` (altrimenti falsano gli obiettivi "possiedi un'abilita' epica/leggendaria").
- **Bonus kit completo**: se `kit_of(...).size() >= 4` e c'e' l'ultimate, **+3% PV, attacco, difesa** (`BattleTypes.KIT_BONUS_PCT`, `BattleContent.full_kit`). Non vale nel PvP bilanciato (`flat_rarity`).
  E' pensato come bonus provvisorio uguale per tutti: **da legare alla rarita'** (decisione futura dell'utente).
- Validazione: `BattleResolver.validate_choice` richiede che la mossa (anche base) sia nel kit (`u["skills"]`). Le uniche non sono equipaggiabili da altri personaggi (`RosterState.equip_skill` e `validate_entry`).
- IA: `BattleAI._basic_for(u)` sceglie un ripiego valido (Attacco, altrimenti Guardia, altrimenti la prima mossa) -> l'IA non resta mai senza mossa valida.
- **Domanda aperta all'utente**: le uniche si **aggiungono** ai 4 slot? No: **contano dentro i 4 slot** (stato attuale). Per personaggi con 2 uniche restano 2 slot liberi. Il kit di base e' costruito per non togliere
  ruolo ai personaggi, ma e' un punto da rivedere con l'utente.

### 4.3 Boss
- 18 boss in ordine di sblocco (`BOSS_ORDER`): distributore, semaforo, tombino, cabina, ascensore, manichino, orologio, specchio, sirena, lampione, bancomat, scala, radio, metro, cassaforte, faro, registro, eclissi.
  (Dal 10 in poi = **Stagione 2**, con Dafne.)
- Quattro **difficolta'** (`TIERS`): NORMALE, DIFFICILE (hp x1.5, atk x1.25, def 8, premi x2), INCUBO (hp x2.1, atk x1.55, def 15, premi x3.2), **ABISSO** (0.24.23: hp x36, atk x23, def +70, premi x5, `flatten` 1.0 = tutti i boss partono dagli stessi PV/attacco medi `FLAT_BOSS_HP/ATK`; pensato per squadre liv. 50 + rank 5 + pezzi leggendari; si apre battendo INCUBO; Ciclo Infinito e Spedizione si fermano a INCUBO). Simulatore: `tools/maxed_sim.gd`; test: `test_abisso`.
- **Fasi**: a meta' e a un quarto dei PV (nuove mosse, scudo, +25 ultimate alla squadra).
- **Equilibrio** (barra blu): a zero il boss e' **stordito** e salta la mossa; colpi con vantaggio di colore e marchi rompono di piu'.
- **Cariche annunciate**: le mosse pesanti sono annunciate (telegrafo); se letali per qualcuno lo si vede.
- **Comportamento** (`Arena`): ogni boss punisce qualcosa (cure, marchi, guardia di gruppo). **Eventi dell'arena** ogni 3 round (ZONA CONTAMINATA, SIGILLO).
- **Il boss impara** (`Extras.apply_learned`): se hai gia' battuto un boss, la volta dopo ha imparato dal tuo stile (solo in solitaria).

### 4.4 Meccaniche tattiche
- **Combo modulari** (`Combos`): le mosse hanno tag; COPERTURA, TRACCIA, DETONAZIONE, FRATTURA, ASSEDIO, RAFFICA, VINCOLO+SCARICA, GUARDIA SPEZZATA, CONDANNA, CASCATA. Una combo scatta una volta per causa e round.
- **Reazioni** (con la Riserva) contro le cariche: SCHIVATA, INTERCETTAZIONE, INTERRUZIONE, SOCCORSO.
- **Sinergie**: RITMO (cambia mossa +10%), ADATTAMENTO (3a volta uguale -15%), ARDORE (<30% PV +15%), ULTIMA VOLONTA' (1 PV), SACRIFICIO.
- **Marchi** (`Marks`): risorsa a pile sul nemico, usata diversamente dai personaggi.
- **Fazioni** (`Factions`, `docs/DOTTRINE.md`): LibraCorp (Protocollo, Difesa), Rondini (Ronda), Magabondi (Improvvisazione), Kairos (Dissonanza). Aure passive tra compagni della stessa fazione (cap +25%);
  stile **ortodosso** o **atipico** (`Atypical`).
- **Tattiche avanzate** (`Tactics`): ORDINI di squadra, PREZZO (potere in cambio di PV), PING per la cooperativa, scudi del boss, attacchi a catena, ECO.
- **Archetipi** per colore (`Archetypes`).

### 4.5 Funzioni che si ricordano tra le partite (`Extras`, `Titles`, `Power`)
- **Maestria** persistente: ogni mossa usata tanto sale (25 usi/livello, max 3, +4%/livello).
- **Sfida facoltativa** a ogni battaglia: se superata +120 crediti (`challenge` nei premi).
- **Rientro**: dopo 3 sconfitte di fila la battaglia dopo parte con Riserva +2 e scudo.
- **Sala di addestramento**: boss senza premi/progressi (`MissionConfig.training`).
- **Codice squadra** (`BuildCode`): configurazione in una riga, importabile nella Spedizione per confrontare.
- **Titoli** (`Titles`): riconoscimenti dell'account, epici e leggendari, con bonus **permanenti** (in punti base, max 1500). Linee (conta il piu' alto per linea): scope tutti/colore/fazione/classe.
  Gli entry vengono "decorati" con `entry["acc"]={hp,atk,def}`, `entry["mastery"]`, `entry["vet"]/["wound"]`.
- **Potere** (`Power`): `hp/10 + atk*2 + def*1.5 + spd`, con dettaglio (base/livello/rank/equip/titoli). Visibile nella scheda operatore e nella schermata **TITOLI E POTERE**.

---

## 5. Modalita' di gioco

| Modalita' | Dove | Note |
|---|---|---|
| **Storia** (stagione 1 + 2) | `scripts/story`, `scenes/story` | Scene a copione; la stagione 2 introduce Dafne (Agent 02 di LibraCorp). |
| **Missioni** | `scenes/missions` | Boss per sblocco; difficolta'; toggle ADDESTRAMENTO. |
| **Sfida del giorno / Evento settimanale** | `Daily`, `Weekly` | Boss e modificatore dalla data; serie con premi. |
| **Ciclo infinito** | `Endless` | Piani sempre piu' duri, potenziamenti (boon) da scegliere. |
| **Spedizione** | `Expedition`, `scenes/expedition` | Roguelite da soli o co-op. **BREVE** (6 tappe) e **LUNGA** (10 tappe: rifugio, guardiano, reliquia maledetta, terzo scontro, 3 modificatori volontari). PV che si portano dietro, veterani (bonus permanenti), feriti (6 ore o 300 crediti). In co-op si vota. |
| **Co-op online** | `scenes/lobby`, `scripts/network` | Stanze con codice, host autoritativo. |
| **PvP** | `PvpEngine`, `scenes/battle/pvp_screen.gd` | Motore a parte; modalita' bilanciata (livello 20, rank 2, niente equipaggiamento); allenamento contro IA (`PvpLocalSource`). |
| **Tutorial** | `Tutorials`, `scenes/tutorial` | 12+ lezioni; ogni tutorial letto la prima volta da' premi. |
| **Obiettivi / Imprese** | `Feats`, `Objectives` | Giornalieri (3 al giorno) e permanenti; schermata OBIETTIVI. |
| **Collezione** | `RosterState`, `scenes/roster` | Reclutamento (gacha con crediti, niente denaro vero), equipaggiamento (arma/petto/stivali), mosse e passive, filtri. |
| **Archivio delle scoperte** | `Discoveries` | Combo/eventi/comportamenti visti davvero. |

Valute: **CREDITI**, **NUCLEI**, **LEGHE** (materiali). I premi epici/leggendari hanno bordo viola/giallo.

---

## 6. La schermata di battaglia (rifatta in 0.24.21)

File: `scenes/battle/battle_screen.gd` (grande, ~2800 righe) e `scenes/battle/battle_stage.gd` (palco disegnato da codice).
Riferimento voluto dall'utente: stile JRPG pulito (ppochi elementi, tutto cio' che non serve a scomparsa). Screenshot di controllo: `tools/battle_shot.gd`.

Layout attuale:
- **In alto a sinistra** (nell'angolo vero dello schermo): icona AUTO (fulmine) e velocita' (freccette 1-3, la dimensione del glifo si riduce), `TURNO NN`, pannello **ORDINE DEL TURNO** compatto.
- **In alto al centro**: nome del boss, classe/minaccia/difficolta'; sotto, riquadro **PROSSIMA MOSSA** con bersaglio, suggerimento (vedi sotto), Riserva di squadra e due pulsanti **ORD** e **COSTO** (tattiche).
- **In alto a destra**: barra **vita** del boss (rossa) con sotto la barra **equilibrio** (blu) larga uguale, poi `PV x/y`, e il pallino della **fase**. Il timer di scelta compare solo se c'e' un limite.
- **Palco**: personaggi in **prospettiva** (`party_pose(i,n)` -> `Vector3(x, y_piedi, scala)`: `x = 105 + t*185`, `y = 462 + t*20 - lift`, scala `0.92 + t*0.05`); boss a destra (`BOSS_X = 1030`).
  Sotto ogni personaggio una **barra vita** (`_draw_hp_under`) con la parte persa in rosso: visibile solo quando tocca al giocatore (`hp_visible = picking`) o dopo un colpo/cura (`_hp_recent`).
- **Menu comandi a ventaglio** (`FanMenu`, `_refresh_orders`): un pulsante per mossa del kit (max 4) + ultimate; il suo spazio verticale e' limitato a `236..578` (touch `214..578`) per non coprire la fila operatori.
- **In basso a sinistra**: striscia operatori (un'unita' per slot di front row con sotto il compagno in panchina, frecce ▲▼ per lo swap); `_fit_ops_panel` ne calcola la dimensione.
- **In basso a destra**: fumetto delle **battute** dei personaggi (`banter`, ritratto + riga) e bottone **LOG** (tendina del registro eventi, `toggle_log`).
- **Riquadro abilita'** (`_skill_plate`): quando un operatore usa un'abilita' (non ultimate, non base) compare a destra il suo ritratto con il nome della mossa (testo a sinistra, ritratto a destra). L'ultimate usa la sua animazione (`CutIn`).
- **Suggerimento del boss**: nelle prime 4 partite il testo giallo spiega la reazione; poi diventa "???" (`_hint_full = plays < 4`, `_refresh_plan_hint`).
- **Fine partita** (`_show_result`): titolo fisso in alto; **riepilogo e premi dentro aree scorrevoli** (`ScrollContainer`), pulsanti (Rigioca / Continua la spedizione / Scegli missione / Torna all'hub) **sempre visibili**.
  (Bug risolto in 0.24.21: i pulsanti uscivano dal riquadro quando il resoconto era lungo.)

### Angoli dello schermo e telefoni
- `ScreenFrame` inquadra ogni schermata in un riquadro 1280x720 centrato nell'area sicura. Sugli schermi piu' larghi i comandi "d'angolo" sarebbero dentro il riquadro, lontani dal bordo.
- Per questo `battle_screen._pin_corners()` calcola `_edge_l` / `_edge_r` (spazio fra riquadro e bordi sicuri) e **sposta** gli elementi d'angolo (auto, velocita', turno, ordine del turno a sinistra; barra boss, fase, log a destra).
  Fumetti e riquadri dinamici usano `_edge_r`.
- Su touch (`TouchUi`) pulsanti piu' grandi; `ui_audit` verifica anche con margini finti (`40,20,40,20`).

---

## 7. Contenuti (stato attuale)

**24 operatori** (`BattleContent.CHARACTERS`), nome | colore | classe | rarita'(0-3) | fazione | skill base | ultimate:

| id | Nome | Col. | Classe | R | Fazione | Skill | Ultimate |
|---|---|---|---|---|---|---|---|
| kira | Kira | viola | striker | 3 | rondini | colpo_caricato | spezzatutto |
| dax | Dax | rosso | vanguard | 0 | libracorp | provoca | bastione |
| elle | Elle | verde | warden | 0 | magabondi | cura | rinascita |
| bruno | Bruno | blu | vanguard | 0 | libracorp | barriera | bastione |
| nova | Nova | giallo | striker | 1 | rondini | marchio | spezzatutto |
| mira | Mira | blu | warden | 1 | libracorp | purifica | rinascita |
| rex | Rex | rosso | striker | 0 | rondini | colpo_caricato | spezzatutto |
| ivo | Ivo | blu | striker | 1 | magabondi | marchio | spezzatutto |
| sera | Sera | verde | warden | 2 | rondini | barriera | rinascita |
| eco | Eco | giallo | striker | 2 | kairos | marchio | spezzatutto |
| tana | Tana | giallo | vanguard | 3 | libracorp | provoca | bastione |
| nico | Nico | rosso | vanguard | 2 | kairos | intimidisci | bastione |
| dafne | Dafne | giallo | striker | 3 | libracorp | u_dafne_a | coordinated_shot |
| angela | Angela | giallo | striker | 3 | libracorp | u_angela_a | orbital_strike |
| moro | Moro | rosso | vanguard | 1 | magabondi | provoca | u_moro_ult |
| vesper | Vesper | viola | striker | 2 | magabondi | marchio | u_vesper_ult |
| nami | Nami | verde | warden | 0 | magabondi | barriera | u_nami_ult |
| oriel | Oriel | blu | warden | 3 | kairos | cura | u_oriel_ult |
| silex | Silex | viola | vanguard | 1 | kairos | provoca | u_silex_ult |
| yuna | Yuna | blu | striker | 2 | kairos | colpo_caricato | u_yuna_ult |
| rhea | Rhea | verde | warden | 1 | rondini | purifica | u_rhea_ult |
| flux | Flux | blu | striker | 3 | rondini | colpo_caricato | u_flux_ult |
| cato | Cato | viola | vanguard | 0 | libracorp | barriera | u_cato_ult |
| lyra | Lyra | viola | striker | 3 | libracorp | marchio | u_lyra_ult |

(Dati letti dal codice a 0.24.21: se ne aggiungi, aggiorna anche `Signatures`, `Lore`, `Banter`, e le grafiche.)
Nico appare solo nella storia. 106 mosse, 4 passive (`BattleContent.MOVES`, `PASSIVES`). Ogni operatore ha una **passiva unica** e 1-2 **abilita' uniche** (`signatures.gd`).
Mondo, fazioni e personaggi: `docs/MONDO.md`.

---

## 8. Rete e multiplayer

- **WebRTC** con server STUN pubblici; per i dati mobili serve un server **TURN** (`docs/TURN.md`). Credenziali in `config/turn.cfg` (gitignored, incluse nell'export).
- **Segnalazione**: `odispel-signaling/server.js` (Node, WebSocket) su Render: `wss://odispel-signaling.onrender.com` (`GameConfig.DEFAULT_SERVER_URL`). Il primo avvio puo' impiegare fino a 1 minuto (server che si sveglia).
- `NetSession` (autoload) mantiene la connessione mentre si cambiano schermata; lobby con chat; codice stanza.
- In battaglia: l'**host** esegue `BattleResolver`; i client ricevono snapshot/eventi. Le scelte dei client passano da `BattleNet.clean_choice`.
- Spedizione co-op: voto a maggioranza, pareggio all'host. Le funzioni "il boss impara", maestria e sfida facoltativa funzionano **solo in solitaria**.
- Guida per gli amici: `docs/PROVA_ONLINE.md`. Strumenti di prova rete: `tools/check_webrtc*.gd`, `tools/network_harness/`, `tools/check_two_clients.gd`.

---

## 9. Salvataggi e compatibilita'

- Collezione: `user://odispel_roster.json` (`RosterStore`, `RosterState.VERSION = 1`, `validate(roster)` rifiuta salvataggi incoerenti; `from_json` fa le migrazioni).
- Impostazioni: `user://settings.cfg`; profilo: `user://profile.cfg` ("Nuovo gioco" cancella i progressi ma **non** il profilo).
- Migrazioni gia' presenti in `RosterState.from_json`: campi aggiunti (materials, gear, next_gear, pulls, pity, cleared), `sync_faction_moves` (Ricarica ai LibraCorp, una volta), `migrate_kits` (Attacco/Guardia/uniche negli slot), `grant_story_allies`.
- Modificare i dati di un operatore => ricordati di pensare ai salvataggi esistenti e a `validate_entry`.
- Salvataggi su Windows: nella cartella dati dell'utente di Godot (`%APPDATA%\Godot\app_userdata\...`), non dentro la cartella del gioco: cancellare vecchie cartelle del gioco non tocca i progressi.

---

## 10. Test e strumenti

### Test (70 file)
```
godot --headless --path . -s res://tests/unit/<file>.gd
```
- Ogni test stampa `PASS:` / `FAIL:` e un riepilogo; cerca `FAIL` (la riga `FAIL: 0` e' il riepilogo senza errori) e `SCRIPT ERROR`.
- Suite completa (usa `xvfb-run`; con troppi processi in parallelo la macchina va lenta, usa `-P 3`):
  ```
  ls tests/unit/*.gd | xargs -P 3 -I{} sh -c 'n=$(basename {} .gd); timeout 280 xvfb-run -a godot --headless --path . -s res://{} > /tmp/res/$n.log 2>&1'
  grep -aH "FAIL\|SCRIPT ERROR" /tmp/res/*.log | grep -v "FAIL: 0"
  ```
- Prima di lanciarli dopo aver aggiunto file/script: `godot --headless --path . --import`.
- Lo stato Godot `ERR_CANT_OPEN status < 0` durante l'esportazione/import e' innocuo.

### Audit dei pulsanti
```
xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/ui_audit.gd -- 0 ""              # PC
xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/ui_audit.gd -- 1 "40,20,40,20"   # touch + notch
```
Deve finire con `TOTALE PROBLEMI: 0` (controlla: pulsanti fuori dall'area sicura, testo piu' largo del tasto, tasti piccoli su touch, tasti sovrapposti >25%; dalla 0.24.29 anche **etichette sovrapposte o tagliate e avvisi** in battaglia: `_audit_text`).
Disposizione della HUD di battaglia (0.24.29): `tests/unit/test_hud_layout.gd` (PC e touch, serve `xvfb-run` non headless).

**Regole della HUD di battaglia** (verificate con foto PC e touch):
- I tasti AUTO/velocita' in touch sono alti 64 (TouchUi.MIN_HEIGHT), non quanto dicono gli ancoraggi: `_top_row()` da' la riga sotto cui parte il resto.
- Avvisi (`Feedback.set_toast_corner`): in battaglia in alto a destra sotto il blocco boss; tornano al centro all'uscita.
- Il blocco boss (nome, classe, barra vita, equilibrio, PV) e' un solo `HudPanel` a destra; l'allarme sta in alto al centro.
- Colori barre: alleati `BattleTheme.HP` (bianco-ciano), sotto il 30% rosso, scudo `GOLD`; `OK` (verde) solo per scritte d'effetto.
- Pulsanti abilita': icona dentro, costo/motivo a destra (`_order_note`), ultimate pronta gialla.
- Il pannello turno si adatta a righe e testo (`_fit_turn_panel`, max 384 di larghezza); la freccia di chi sceglie scende sulla testa se finirebbe nel pannello.
Ultima verifica: 0 problemi in entrambe le modalita'.

### Foto delle schermate (per rivedere la grafica)
- `tools/battle_shot.gd` (battaglia): `xvfb-run -a godot --path . --resolution 1600x720 -s res://tools/battle_shot.gd -- <cartella>` -> `bs.png`. (Risoluzione 1600 larga per vedere il comportamento degli angoli.)
- `tools/result_shot.gd` (fine partita, con premi lunghi): `-- <cartella> [touch 0/1] [spedizione 0/1]` -> `res.png`.
- Altre: `hub_shot`, `roster_shot`, `pvp_shot`, `tutorial_shot`, `cutin_shot`, `ult_shot`, ecc.

### Altro
`tools/battle_sim.gd` (simulatore di bilanciamento, **non lanciarlo senza richiesta**), `tools/bench*.gd` (prestazioni), `tools/team_report.gd`, `tools/endless_sim.gd`, `tools/check_art.py` (controllo grafiche), `tools/esporta.ps1` (export Windows da PowerShell).

---

## 11. Build e distribuzione

Export Godot (modelli 4.7.2 installati). Dalla radice del progetto:

**APK Android** (firma di debug, chiave in `/root/debug.keystore`; la modalita' release non ha keystore):
```
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/root/debug.keystore GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android   # chiave di debug standard (non e' un segreto)
godot --headless --path . --export-release "Android" build/raw.apk     # dalla 0.26.2: template RELEASE (piu' veloce del debug); shrink_apk ri-firma comunque
python3 tools/shrink_apk.py build/raw.apk build/ODISPEL-<versione>.apk      # ricomprime e ri-firma (richiede apksigner nel PATH: /root/android-sdk/build-tools/*)
```
**Windows**:
```
godot --headless --path . --export-release "Windows Desktop" build/win/ODISPEL.exe
(cd build/win && zip -9 -q ../ODISPEL-<versione>-windows.zip ODISPEL.exe libwebrtc_native.windows.template_release.x86_64.dll)
```
L'exe contiene tutto il gioco; la `.dll` deve stare **nella stessa cartella** dell'exe. Senza firma di codice Windows mostra l'avviso SmartScreen ("Maggiori informazioni" > "Esegui comunque").

**Pubblicazione**: copia i file in `releases/` (rimuovi i vecchi), commit e push su `claude/battaglia-chiara`. Le Release di GitHub **non** sono creabili da questo ambiente (403).
Link di download (repository privato: serve il login):
- `https://github.com/Gialloo/odispel/tree/claude/battaglia-chiara/releases`

**itch.io** (pagina privata con password, del proprietario): guida in `docs/GUIDA_ITCH.md` (caricamento a mano o con `butler`). La password e la chiave `butler` sono dell'utente: non scriverle da nessuna parte.
Dettagli di export vecchi in `docs/GUIDA_USCITA.md`.

Esistono APK/zip pubblicati: **0.24.21** (`releases/ODISPEL-0.24.21.apk`, `releases/ODISPEL-0.24.21-windows.zip`).

---

## 12. Cronologia delle versioni recenti (dal Changelog)

- **0.24.21** - Battaglia rifatta (prospettiva, HUD pulita, barre vita sotto i personaggi, log a tendina, icone AUTO e velocita'); riquadro ritratto+nome per le abilita'; **kit a 4 mosse + ultimate** con Attacco/Guardia/uniche negli slot; bonus kit completo +3%; fix tasti di fine partita.
- **0.24.20** - Maestria persistente, sfida facoltativa, rientro dopo 3 sconfitte, boss che impara, sala di addestramento, codice squadra importabile in Spedizione, resoconto con momenti e cause.
- **0.24.19** - Titoli epici/leggendari con bonus permanenti, **Potere**, schermata TITOLI E POTERE, Spedizione lunga (10 tappe), ordini/prezzo/ping in battaglia.
- **0.24.18** - Eventi dell'arena, comportamenti dei boss, reazione SOCCORSO, replay tattico, archivio delle scoperte, **Spedizione** (solo e co-op), veterani e feriti, codice squadra, titoli di squadra.
- **0.24.17** - Riserva di squadra e reazioni (schivata, intercettazione, interruzione), nuove combo, sezione Tutorial con premi, imprese STUDIOSO, fix PvP.
- **0.24.16** - Fasi dei boss, barra equilibrio, cariche annunciate, sinergie, **Stagione 2 con Dafne** (10 capitoli, 10 boss), combo modulari.
- **0.24.15** - Pannello squadra TEAM, filtri collezione, PvP con lo stile della battaglia, statistiche profilo, crediti (ex monete), Dafne.
(Versioni precedenti nel codice: `scripts/config/changelog.gd`.)

Ottimizzazioni recenti (commit `6801f65`): `Titles`/`Power` calcolati una volta, 7 funzioni morte rimosse, build vecchie cancellate. Il peso dell'APK e' dominato dal motore Godot (circa 37 MB); le immagini sono gia' ottimizzate.

---

## 13. Stato, decisioni aperte e cose NON fatte

**Fatto e verificato** (alla 0.24.21): test completi verdi (70 file), audit pulsanti a 0 problemi in entrambe le modalita'.

**Decisioni aperte con l'utente (da chiedere/proporre):**
1. **Bonus del kit completo**: ora +3% PV/ATK/DEF uguale per tutti; l'utente vuole decidere in base alla rarita' del personaggio.
2. **Uniche dentro i 4 slot**: stato attuale = contano nei 4. Se ne trova troppo restrittivo, si puo' tornare a "uniche in aggiunta" (il codice e' in `BattleState.kit_of` + default in `BattleContent._default_skills`).
3. Layout HUD: l'utente ha approvato la disposizione (5 iterazioni di screenshot). Restano idee non fatte: barra inferiore con **ritratti** degli operatori come nel riferimento JRPG, ordine del turno richiudibile.
4. Itch.io: pagina creata dall'utente; non e' ancora verificato che i file siano stati caricati.

**Non ancora implementato** (richieste passate dell'utente):
- Modalita' **osservatore** (spettatore in battaglia).
- **Battaglie asimmetriche**.
- **Trasferimento di risorse** tra giocatori.
- **Ruoli temporanei**.
- **Boss che impara** anche in multiplayer (oggi solo in solitaria).
- Equilibrio per **rarita'** dei bonus del kit (vedi sopra).

**Limitazioni note:**
- Le grafiche sono in gran parte segnaposto disegnati da codice (boss, molti operatori); i ritratti veri esistono per alcuni (es. Kira, Dafne). Vedi `docs/HANDOFF_ARTE_IA.md`, `docs/GUIDA_ARTE.md`.
- Il debug-keystore firma gli APK: se l'utente ha installata una versione con firma diversa deve prima disinstallarla.
- `tools/ui_audit.gd` non controlla la schermata di fine partita con resoconto molto lungo: fai anche `tools/result_shot.gd` quando la modifichi.

---

## 14. Trucchi e insidie (cose che hanno gia' fatto perdere tempo)

- **JSON identity**: nello stato mai float (`boss_boost` e' un intero in %). I test di round trip lo scoprono.
- **Test e premi**: ci sono premi extra (sfida facoltativa `challenge`): i test che confrontano i crediti esatti devono sottrarre `r.get("challenge", 0)`.
- **Test `-s`**: autoload non referenziabili direttamente; script con errore in `_init` fanno "appendere" il test (mancava `battle["stats"]` una volta).
- **Lambda e nodi liberati**: non catturare in una lambda un nodo che puo' essere `queue_free()`; usa `tween_callback(node.queue_free)`.
- **Layout con ancore**: nei nodi con ancore, non assegnare `position`; anima `offset_left/right`.
- **Sovrapposizioni**: il menu a ventaglio non deve toccare la striscia operatori; `ui_audit` lo segnala come "tasti sovrapposti".
- **Kit**: ogni punto che usa `u["skills"]` deve ricordare che adesso contiene **anche** Attacco e Guardia (e puo' non contenerne una). Il PvP (`PvpEngine.skills_of`) aggiunge sempre le uniche.
- **Inventario mosse**: non inserire in `roster["moves"]` le mosse base ne' le uniche del personaggio (falserebbe `Feats` "move_rarity" e il controllo `validate`).
- **Rete**: aggiornare `GameConfig.VERSION` altrimenti host e client non si collegano; il protocollo di battaglia ha una versione (`test_battle_flow`).
- **`ArtLibrary.refresh()`** (non `reload()`: e' una funzione interna di Godot e azzera le variabili statiche).
- **Screenshot**: le foto sono prese con `xvfb-run` a 1600x720 per vedere i margini; il riquadro di gioco e' 1280x720 centrato (con test_insets nell'audit).

---

## 15. Mappa della documentazione esistente (`docs/`)

| File | Contenuto |
|---|---|
| `ARCHITETTURA.md` | Mappa del codice, regole per tenerlo leggero, misure di prestazioni, fondamenta delle fazioni. |
| `MONDO.md` | Ambientazione, fazioni, personaggi (riferimento per dialoghi e nomi). |
| `DOTTRINE.md` | Dottrine delle fazioni, aure, atipico. |
| `TURN.md` | Come configurare il server TURN per i dati mobili. |
| `PROVA_ONLINE.md` | Come giocare online con gli amici (per chi riceve il gioco). |
| `GUIDA_USCITA.md` | Creare la versione Windows, avvisi SmartScreen. |
| `GUIDA_ITCH.md` | Pubblicare su itch.io (pagina privata, butler). |
| `GUIDA_ARTE.md`, `HANDOFF_ARTE_IA.md`, `HANDOFF_GEMINI.md`, `HANDOFF_COPILOT_KIRA.md` | Produzione delle grafiche (nomi file, misure, regole, controllo con `tools/check_art.py`). |
| `HANDOFF_PERSONAGGI_SINERGIE.md` | Handoff su personaggi e sinergie. |
| `REPORT_BILANCIAMENTO.md`, `TIERLIST.md` | Misure di bilanciamento (versione 0.24.0) e classifica. |
| `AUDIT_TECNICO.md`, `AUDIT_UI_UX.md` | Audit tecnico e UI/UX. |
| `HANDOFF_COMPLETO.md` | **Questo documento.** |

---

## 16. Cosa fare per iniziare (checklist per la nuova IA)

1. `git status` e `git log --oneline -5` sul ramo `claude/battaglia-chiara`; verifica che `GameConfig.VERSION` sia `0.24.21`.
2. `godot --headless --path . --import`, poi lancia i test (sezione 10): devono essere tutti verdi.
3. Leggi `docs/ARCHITETTURA.md` e le sezioni 3, 4.2 e 6 di questo documento.
4. Chiedi all'utente cosa vuole fare per prima cosa (vedi sezione 13): bonus per rarita', osservatore, asimmetriche, trasferimento risorse, ruoli temporanei, boss che impara in rete, barra con ritratti.
5. Lavora a piccoli passi, mostra uno screenshot per ogni cambiamento grafico, **aspetta la conferma** prima del push, e a fine lavoro: test, audit, changelog, versione, build (se richiesta) e push.
6. Rispondi **sempre in italiano semplice**.

## Light painting (0.24.24)
- `scripts/ui/light_paint.gd` (`LightPaint`): tratti di luce a lunga esposizione, solo grafica (nessun effetto sulla logica). Gerarchia: **fazione = mano** (libracorp circuito+mirino, rondini arco, magabondi scarabocchio+gocce, kairos copie sfasate+rune), **colore = particelle** (rosso scintille, giallo pulviscolo, viola fumo, verde puntini, blu filamenti), **mossa = solo la forma** (`line` colpo, `ring` scudo, `spiral` cura).
- Collegato in `battle_screen.gd`: `_hit_anim` (colpi), eventi `heal` e `shield` via `_light_paint`. Senza fazione (boss, evocazioni) resta il vecchio effetto. Spento con qualita' grafica BASSA (`AnimFx.enabled`); `LightPaint.max_live` (14) e particelle limitate.
- Test: `test_light_paint`; foto: `tools/lightpaint_shot.gd`, `tools/battle_lp_shot.gd`, `tools/battle_fx_shot.gd`.
- Fase 2 (fatta): forme `mark` (Marchio), `crack` (Frattura), `swirl` (Intimidisci) agganciate in `_skill_light`; `sigil` = firma di ogni personaggio negli ultimate (`_ult_signature`, `LightPaint.sigil_spec`: 10 stelle x 4 varianti = 24 firme uniche, deciso dalla posizione in `CHARACTERS`); velo scuro `LightPaint.dim` (un solo ColorRect nel layer `_fx`, 0.12 / 0.26); pennellate disegnate a mano facoltative `art/fx/stroke_<fazione>.png` (1024x128, bianco su trasparente, vedi `docs/GUIDA_PROCREATE.md` sez. 11; non entrano nei 300 slot di `ArtLibrary`).
- Da fare: firme disegnate a mano per personaggio (`characters/<id>/sigil.png`), tratti per i boss, eventuale texture per i debuff.

- **Art bible (0.24.26):** `docs/ART_BIBLE.md` contiene la direzione artistica ufficiale e lo stato di implementazione (palette `PAL_*`, forma `slash` = VFX-001, grammatica dei poteri -> mosse, criteri di accettazione con cio' che e' verificato e cio' che no, Android compreso).

- **Importante (0.24.27):** `LightPaint` NON dipende da `AnimFx.enabled()` / "effetti ridotti". Sui telefoni `Settings.light_fx` e' true di default (e si accende da solo sotto i 40 fps) e fino alla 0.24.26 faceva sparire i tratti di luce. Ora con `light_fx` restano tratto + alone leggero (`_lite`: niente particelle, copie, velo). Per provare in xvfb senza forzare impostazioni, `light_fx` e' gia' true: la prova "reale" con `tools/battle_fx_shot.gd` mostra la versione ridotta.
- **Prestazioni dei tratti di luce (0.24.28):** il tratto e' fatto di 3 `ArrayMesh` (alone a picco, corpo con bordo sfumato, nucleo avorio) con colore per vertice, disegnati con `draw_mesh`: ~0 draw call in piu' contro ~27 prima. La mesh si ricostruisce solo mentre il tratto si traccia; poi la dissolvenza e' `self_modulate.a` (nessun ridisegno). Lampo, filamenti, rune, mirino e particelle stanno nel figlio `_Fx` (`_overlay`), che si ridisegna solo se qualcosa si muove. `LightPaint.prewarm` (chiamato in `battle_screen` all'ingresso) prepara le varianti di shader. Misure: `tools/perf_battle.gd` (headless = lavoro del codice, xvfb = disegno software; contatori `LightPaint.profile_*` e `BattleStage.profile_*`) e `tools/perf_hunt.gd`. Misura 0.24.27: `TIME_PROCESS` medio 21,6 ms contro 21,7 della 0.24.22 (nessuna regressione di CPU). Il peso residuo e' nel disegno della schermata (~395 draw call, velo shader a tutto schermo) e non e' misurabile senza un dispositivo vero.
