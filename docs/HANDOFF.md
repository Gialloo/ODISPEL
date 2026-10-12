# ODISPEL — documento di passaggio (handoff)

Aggiornato al 12/10/2026. Da incollare/allegare all'inizio di una nuova chat con Claude per continuare il lavoro su altre parti del progetto.

---

## 0. Come usare questo file

**Prompt di avvio suggerito** (da incollare insieme a questo file):

> Stiamo lavorando al progetto ODISPEL (gioco co-op in Godot 4.7.2). Ti allego il documento di passaggio con stato, architettura e convenzioni. Leggilo tutto prima di rispondere. Io lavoro su Windows con PowerShell, cartella progetto `C:\Users\gianl\Documents\odispel`. Voglio fare: **[descrivi qui il compito]**. Rispondi in italiano, con istruzioni passo passo.

Se la nuova chat ha accesso al codice (repo `https://github.com/Gialloo/ODISPEL`, ramo `main`), leggi i file indicati nella mappa (sezione 5) prima di modificare qualcosa.

---

## 1. Il progetto

**ODISPEL**: gioco di battaglie co-op contro boss, in **Godot 4.7.2** (GDScript, renderer GL Compatibility). Multiplayer **host-autoritativo** con **WebRTC** (estensione GDExtension `webrtc_native`) e un server di **signaling** Node.js (WebSocket) su Render (`wss://odispel-signaling.onrender.com`, può metterci fino a 1 minuto a svegliarsi).

**Obiettivo a lungo termine**: versione stabile da far giocare ad amici (export Windows), direzione artistica "urban fantasy", HUD in stile **telecamera di sorveglianza + arcade/System** (dominante ciano, rosso aggressivo, bianco, nero), sistema di combattimento e progressione ibrido gacha (ispirazioni: Wizardry Variant Daphne, Naruto Blazing, OPTC, Epic Seven):
- squadre da 3 con cambio libero;
- scelte simultanee risolte per velocità (SPD);
- mosse del boss annunciate (telegraph);
- barra ultimate;
- drop di mosse/passive/pezzi di equipaggiamento;
- rank per duplicati;
- reclutamento con valuta morbida.

**Versione attuale del gioco: `0.2.0`** (`scripts/config/game_config.gd`, `GameConfig.VERSION`). Host e client devono avere la stessa versione, altrimenti la stanza rifiuta il client. **Va aumentata a ogni release che cambia regole o rete.**

---

## 2. Stato attuale (cosa funziona, verificato dall'utente)

- Motore di battaglia deterministico (nuovo), con IA, premi, boss "Distributore".
- Collezione/roster con squadra, equipaggiamento (mosse, ultimate, passive, pezzi unici), potenziamenti con materiali, reclutamento (singolo/x10 con pity).
- **Battaglia in solitaria** con interfaccia a tema telecamera di sorveglianza (hub → "NUOVO COMBATTIMENTO (SOLO)"): tu + 1 compagno IA.
- **Schermata Squadra e reclutamento** con 3 schede: SQUADRA, EQUIPAGGIO, RECLUTAMENTO.
- **Multiplayer in rete con il nuovo motore**: lobby → host avvia → tutti entrano nella schermata di battaglia, premi assegnati a ciascuno a fine battaglia. **Testato dall'utente con due finestre sullo stesso PC: funziona.**
- **Export Windows** creato (`ODISPEL.exe`, `ODISPEL.pck`, `libwebrtc_native.windows.template_release.x86_64.dll`, `ODISPEL.console.exe`), zip `ODISPEL_v0.2.0_windows.zip` (~40 MB).
- Tutte le suite di test verdi (vedi sezione 7).

**In sospeso lato utente**: condividere lo zip con gli amici (Discord non regge 40 MB → Google Drive o GitHub Release) e fare la **prova su due reti diverse** (probabilmente funziona con STUN; se non si collegano serve un server TURN).

---

## 3. Regole di gioco del nuovo motore

**Stato di battaglia** (`Dictionary`, serializzabile JSON): `round, winner, cycle_index, players[{id,name,ai,team[],active,choice}], units{}, telegraph{move,target}, events[], rng_seed, rng_state`. `winner` = `""`, `"players"` o `"boss"`.

- Deterministico via `RNGState` (seed e stato come **stringhe** int64). Stesso seed + stesse scelte = stessa battaglia.
- Scelta di un giocatore: `{swap, move, target}`. Round: tutti scelgono (simultaneo), poi si risolve in ordine di **SPD** (con priorità per guardia/provoca/barriera).
- **Colori**: rosso > verde > blu > rosso; giallo ⇄ viola. Moltiplicatori 1.5 / 0.67.
- **Danno** = `ATK × mult_mossa × colore × marchio(+25%) × enrage(×1.25 sotto il 50% di vita del boss) × cacciatore × 100/(100+DEF) × guardia(dimezza)`.
- **Energia** per unità: max 6, parte da 2, +1 se attiva, +2 se in panchina. **Barra ultimate**: +15 quando colpisce, +10 quando subisce, 100 per usarla.
- **Stati**: guard, taunt, bleed (4%), mark. Lo scudo si azzera a ogni round.
- **Cambio**: libero, chi entra agisce nello stesso round, chi esce no.
- **Telegraph**: all'inizio del round il boss sceglie il bersaglio e lo annuncia; `taunt` lo devia. Ciclo mosse del Distributore: scarica → raffica → scossa → sovraccarico.
- **Boss scaling**: `effective_players` (giocatore umano o IA che gioca = 1, compagno IA "ally" = 0.5). HP = `hp_per_player (900) × effettivi`; ATK = 390 × `atk_scale [0.62, 0.8, 1.0]` interpolato per numero di giocatori.
- **Premi**: `BattleRewards`, deterministici dal seed (monete 300 base, nuclei 2–4, leghe 1–3, 40% pezzo di equipaggiamento, drop di mosse/passive). Sconfitta = 1/4 delle monete.
- **Progressione**: livello max 50, rank max 5 (duplicati). Costi livello: `character_upgrade_cost` (monete + nuclei), pezzi: `gear_upgrade_cost` (monete + leghe). Pezzi: slot arma/petto/stivali, rarità 0–3, livello max `[10,15,20,30]`.
- **Reclutamento**: singolo 300, x10 2700 (almeno un raro garantito), pity 30 → epico garantito, copie a rank massimo → rimborso `(rarità+1)×100` monete.
- **Rarità**: comune, rara, epica, leggendaria. Colori: rosso, verde, blu, giallo, viola. Classi: striker, vanguard, warden.
- **Contenuti**: 10 personaggi (kira, dax, elle, bruno, nova, mira, rex, ivo, sera, tana), 11 mosse (attack, guard, colpo_caricato, marchio, provoca, barriera, cura, purifica, spezzatutto, bastione, rinascita), 4 passive (p_atk, p_hp, p_swap, p_hunter). Starter: kira, dax, elle, bruno; squadra iniziale kira/dax/elle.
- **Bilanciamento (provvisorio)**: livello 1: 3 giocatori ~97% vittorie, 2 giocatori ~85%, 13–19 round. A livelli alti il boss è facile → servono livelli/tier di boss. Simulatore: `tools/battle_sim.gd`.

---

## 4. Rete (multiplayer)

- **Host-autoritativo**: l'host tiene lo stato e risolve i round; i client inviano solo `choice` e ricevono `battle_snapshot` / `battle_events`.
- **Messaggi**: `hello` (nome, token, versione, **team**), `welcome`, `choice`, `battle_snapshot` (con `rewards` a fine battaglia), `battle_events`, `error` (codici: `version_mismatch`, `invalid_team`, `game_in_progress`, `room_full`, `invalid_token`, `join_failed`).
- Lo snapshot per un giocatore **nasconde seed e RNG** e le scelte altrui (restano `{"locked": true}`). Perciò **i premi li calcola l'host** e li spedisce a ciascuno dentro lo snapshot finale; il client li applica con `NetworkManager.finish()` una sola volta.
- **Timer** pianificazione 30 s: l'host forza la risoluzione (chi non ha scelto attacca).
- **Disconnessione** in battaglia → il giocatore passa all'IA; **rientro** con lo stesso token → torna umano. Dopo l'inizio non entrano nuovi giocatori.
- La squadra del client arriva dal client e l'host valida solo la **forma** (`RosterState.validate_team`), **non il possesso** → limite noto (un client modificato può dichiarare una squadra non sua). Accettabile tra amici; da sistemare se il gioco diventa pubblico.
- Fine battaglia in rete: solo "TORNA ALL'HUB" (chiude la stanza); non c'è "rigioca".
- Server signaling: `odispel-signaling/server.js` (+ `server.test.js`). URL personalizzabile con `server.txt` accanto all'exe.
- Hub e lobby usano l'autoload `NetSession` (`scripts/network/net_session.gd`); la schermata di battaglia no (cerca `/root/NetSession` per nome).

---

## 5. Mappa dei file

```
project.godot                      autoload: CampaignState, SaveManager, NetSession (nel progetto dell'utente)
scripts/config/game_config.gd      VERSION, URL server, normalizzazione URL
scripts/battle/
  battle_types.gd                  costanti (COLORS, CLASSES, RARITIES, GEAR_SLOTS, BEATS, TEAM_SIZE=3, SKILL_SLOTS=2, PASSIVE_SLOTS=2...)
  battle_content.gd                MOVES, PASSIVES, CLASS_STATS, CHARACTERS, GEAR_*, MATERIALS, BOSS_MOVES, BOSSES, compute_stats, costi, drop
  battle_state.gd                  create/create_solo, make_unit/make_boss, effective_players, normalize/to_json/from_json
  battle_resolver.gd               begin_round, validate_choice, submit_choice, can_resolve, resolve_round(state, force)
  battle_ai.gd                     BattleAI.choose(state, pid)
  battle_rewards.gd                for_player / for_battle
  battle_text.gd                   nomi italiani, righe di log, move_hint, apply_to_display
  solo_battle_source.gd            sorgente di battaglia in solitaria (finish() applica premi e salva)
scripts/roster/
  roster_state.gd                  collezione: squadra, equip mosse/ult/passive/pezzi, level up, apply_rewards, validate, JSON
  roster_store.gd                  salvataggio atomico (user://odispel_roster.json)
  recruiting.gd                    Recruiting.pull(roster, count, seed)
scripts/network/
  network_manager.gd               host/client WebRTC + battaglia (set_local_team, host_start_battle, submit_choice, finish)
  battle_net.gd                    snapshot_for, read_team, clean_choice, set_player_ai
  net_session.gd                   autoload, tiene la sessione tra scene
  webrtc_link.gd, network_identity.gd, network_snapshot.gd
scripts/ui/                        battle_theme.gd (colori/font/stili), hud_panel.gd, seg_bar.gd
shaders/cctv_overlay.gdshader      scanlines, vignettatura, rumore
scenes/battle/                     battle_screen.gd/.tscn (HUD+logica), battle_stage.gd (disegno scena, sagome segnaposto)
scenes/roster/                     roster_screen.gd/.tscn (squadra, equipaggio, reclutamento)
scenes/hub/hub_demo.gd             menu principale (scrollabile)
scenes/lobby/lobby_demo.gd         lobby multiplayer (host/client)
scenes/combat/, scripts/combat/    VECCHIO sistema di combattimento (campagna a missioni): ancora nel progetto ma non raggiunto dal multiplayer
tests/unit/                        suite di test (sezione 7)
tools/                             battle_sim.gd (bilanciamento), battle_shot.gd e roster_shot.gd (screenshot), harness di rete
odispel-signaling/                 server Node.js di signaling
```

Convenzioni dell'interfaccia: tutte le schermate sono costruite **in codice** (niente scene complesse), progettate a **1280×720** (`content_scale_size`), font di sistema con fallback (Consolas/Courier New; Impact/Arial Black inclinato), nessun asset esterno. Le schermate di battaglia leggono una "sorgente" con interfaccia duck-typed: `battle, local_player_id, battle_time_left, battle_updated, battle_events_received, submit_choice(), finish()` → la implementano `SoloBattleSource` e `NetworkManager`.

---

## 6. Dati e salvataggi

- Roster del giocatore: `user://odispel_roster.json` (`RosterStore.DEFAULT_PATH`), con `version, coins, characters{}, team[], moves{}, passives{}, materials{}, gear{}, next_gear, pulls, pity`. `from_json` riempie i campi mancanti; il JSON rovinato produce una collezione nuova.
- I numeri dopo il JSON tornano `float`: usare `BattleState.normalize(...)` / `int(...)` quando si leggono messaggi di rete.
- Le due istanze sullo stesso PC condividono lo stesso salvataggio (solo per i test).

---

## 7. Test (tutti verdi)

Si eseguono dalla cartella del progetto, con l'editor **chiuso**:

```powershell
cd "C:\Users\gianl\Documents\odispel"
godot --headless --path . --import          # SEMPRE dopo aver aggiunto/spostato script con class_name
godot --headless --path . -s res://tests/unit/test_battle.gd
```

| Suite | Passati attesi |
|---|---|
| test_battle | 76 |
| test_roster | 74 |
| test_progression | 64 |
| test_recruiting | 47 |
| test_battle_net | 72 |
| test_battle_flow | 23 |
| test_battle_ui | 67 |
| test_roster_ui | 39 |
| test_equip_ui | 37 |
| test_combat_resolver | 41 (vecchio sistema) |
| test_models | 47 (vecchio sistema) |
| test_network_host | 117 |

Trappole note:
- **Falso verde**: se uno script ha un errore di parsing (es. `class_name` non registrato) alcune suite stampano comunque PASS. Fix: `godot --headless --path . --import`. Guardare sempre l'ultima riga ("N passati, 0 falliti").
- **Errore DLL WebRTC** (`~libwebrtc_native...dll`): l'editor è aperto o c'è un Godot rimasto in background. Chiudere tutto, `Get-Process | Where-Object { $_.ProcessName -like "Godot*" } | Stop-Process -Force`, poi `Remove-Item "addons\webrtc_native\lib\~*" -Force -ErrorAction SilentlyContinue`.
- Negli script lanciati con `-s` le autoload non esistono dentro `_init()`: usare `_initialize()`.
- Il sandbox di Claude non ha l'autoload `NetSession` nel suo `project.godot`: le scene hub/lobby non compilano lì senza aggiungerlo.

---

## 8. Come lavorare con l'utente (importante)

- **Lingua: italiano.** L'utente non è uno sviluppatore esperto: vuole **istruzioni passo passo per Windows/PowerShell**, con i comandi pronti da incollare, e i risultati attesi ("deve finire con 67 passati, 0 falliti").
- Cartella progetto sul suo PC: `C:\Users\gianl\Documents\odispel`. `godot` è un alias PowerShell verso `Godot_v4.7.2-stable_win64_console.exe`. Ricordare di fare `cd` nella cartella prima dei comandi.
- **Modalità di consegna**: Claude lavora in un sandbox cloud (non vede i file dell'utente) e consegna **zip con solo i file nuovi/modificati**, nello stesso percorso relativo del progetto. L'utente li estrae con `Expand-Archive -Path ".\nome.zip" -DestinationPath . -Force` nella cartella del progetto. Dire sempre **quali file esistenti vengono sostituiti**.
- Dopo ogni consegna: `godot --headless --path . --import`, poi i test, poi prova a mano con F5, poi `git add -A; git commit -m "..."; git push`.
- Verificare sempre il lavoro **prima** di consegnare: eseguire tutte le suite nel sandbox e, per le schermate, generare uno screenshot (`xvfb-run`) e guardarlo.
- Attenzione a non lasciare controlli segnaposto nei test (`or true`) e a non dare per buono un test che stampa PASS con errori di parsing.
- Quando un problema è ambiguo, fare **domande mirate** (quale pulsante, cosa scrive la riga di stato) invece di indovinare.

---

## 9. Prossimi passi consigliati

1. **Condividere la build** agli amici (Google Drive o GitHub Release; il repo non deve contenere lo zip) e fare la **prova su reti diverse**. Se non si collegano → configurare un server TURN (ICE servers in `webrtc_link.gd`/`NetworkManager`).
2. **Contenuti e bilanciamento**: più boss/tier di difficoltà (oggi a livelli alti il Distributore è facile), nuovi personaggi, mosse e passive, nuovi pezzi; rivedere premi e costi con `tools/battle_sim.gd`.
3. **Grafica**: sostituire le sagome segnaposto (boss e combattenti in `battle_stage.gd`) con arte "urban fantasy"; scegliere un **font con licenza libera** e includerlo nel progetto; effetti sonori e musica.
4. **Rete**: validare il possesso della squadra lato host (oggi solo la forma); rematch/"rigioca" in stanza; schermata di attesa/pronto prima dell'avvio; gestione migliore di disconnessione dell'host.
5. **Modalità**: scelta del boss e della difficoltà dalla lobby (oggi fisso "distributore"); progressione della campagna (il vecchio sistema a missioni `CampaignState` non è collegato al nuovo motore: decidere se rimuoverlo o integrarlo).
6. **Release**: automatizzare export e zip, aumentare `GameConfig.VERSION` a ogni release, eventuale icona/nome eseguibile.
7. **Pulizia**: eliminare il vecchio combattimento (`scenes/combat`, `scripts/combat`, relativi test) quando non serve più.

---

## 10. Export Windows (promemoria)

1. Verifica la libreria release: `dir addons\webrtc_native\lib\*windows*release*x86_64*`.
2. Editor → Progetto → Esporta… → **Windows Desktop** (installa i modelli di export per 4.7.2 se richiesto).
3. Percorso: `export\ODISPEL.exe`, **senza** "Esporta con debug". **Non** usare "Esporta PCK/ZIP" (non è giocabile da solo).
4. Controlla che in `export` ci siano `.exe`, `.pck` e la `.dll` di WebRTC; prova l'exe; poi `Compress-Archive -Path "export\*" -DestinationPath "ODISPEL_v0.2.0_windows.zip" -Force`.
5. Gli amici: estrarre prima di avviare; avviso SmartScreen → "Ulteriori informazioni → Esegui comunque".
