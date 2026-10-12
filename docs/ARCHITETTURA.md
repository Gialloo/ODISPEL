# ODISPEL - mappa del codice

## Cartelle
| Cartella | Cosa contiene |
|---|---|
| `scripts/battle/` | Il motore del combattimento (stato, risoluzione, IA, premi, contenuti, testi). Non conosce la grafica: gira anche nei test e nel simulatore. |
| `scripts/roster/` | Collezione dell'operatore: squadra, equipaggiamento, reclutamento, progressi, obiettivi giornalieri, salvataggio. |
| `scripts/network/` | Rete: connessione WebRTC, server di segnalazione, sessione condivisa (`NetSession`), sincronizzazione della battaglia. |
| `scripts/art/` | `ArtLibrary` (cerca le grafiche per nome) e `PortraitView` (ritratto o segnaposto). |
| `scripts/story/` | Dialoghi: lettore dei copioni, scene incluse, avvio delle scene. |
| `scripts/ui/` | Pezzi di interfaccia riusabili: tema, pannelli, barre, effetti fumetto, transizioni, avvisi (`Notify`), sovrapposizioni (`ScreenFx`). |
| `scripts/audio/` | Gestore audio (`Sfx`) e porta d'ingresso `Snd`. |
| `scenes/` | Le schermate (hub, missioni, squadra, lobby, battaglia, dialoghi). Ognuna costruisce la propria interfaccia da codice. |
| `shaders/` | `cctv_overlay` e `halftone` (usati da soli), `battle_overlay` (i due insieme, in un passaggio), `ui_*`. |
| `tests/unit/` | Un file per area: `godot --headless --path . -s res://tests/unit/<file>.gd`. |
| `tools/` | Simulatore di bilanciamento, immagini di controllo delle schermate, misure di velocita', export. |
| `odispel-signaling/` | Server Node.js di segnalazione (Render) con i suoi test. |
| `scripts/combat`, `scripts/party`, `scripts/run`, `scripts/session`, `scenes/combat` | Il primo prototipo del combattimento, mantenuto com'e'. |

## Regole che tengono il codice leggero
- **Il motore non disegna e l'interfaccia non decide**: tutto cio' che cambia il risultato di una battaglia sta in `scripts/battle`.
- **Porte d'ingresso che non fanno nulla senza il gestore** (`Notify`, `Snd`, `SceneRouter`): il codice di gioco le chiama sempre, i test girano senza.
- **Disegnare poco a ogni frame**: lo sfondo della battaglia e' un livello che si disegna una volta sola; i testi fissi sono `TextLine` gia' calcolati; i colori sono costanti; i pannelli si ridisegnano solo quando cambiano.
- **Ricostruire i nodi solo se cambia qualcosa**: la battaglia confronta una "firma" di cio' che mostra (vita, energia, pulsanti attivi) prima di rifare la lista degli operatori e degli ordini.
- **Risorse condivise**: stili dei pulsanti (`BattleTheme.style_button`) e materiali degli shader (`ScreenFx`) si creano una volta sola.
- **Un solo passaggio a tutto schermo** per velo, telecamera e retino (`ScreenFx.battle` / `ScreenFx.menu_overlays`).
- **Grafiche**: `ArtLibrary` tiene in memoria quelle gia' lette (anche l'assenza); `ArtLibrary.refresh()` le rilegge.

## Misurare
- `xvfb-run -a godot --path . --resolution 1280x720 --disable-vsync -s res://tools/bench.gd` - millisecondi per frame di ogni schermata.
- `godot --headless --path . -s res://tools/bench_stage.gd` - costo del disegno della battaglia (sfondo statico contro ridisegnato).
- `godot --headless --path . -s res://tools/battle_sim.gd -- 40` - bilanciamento (percentuali di vittoria per boss, difficolta' e livello).

Nota: `ArtLibrary.refresh()` si chiama cosi' perche' `reload()` e' una funzione interna di Godot sulle classi: usarla azzera le variabili statiche.

## Telefono, guida al reclutamento, forza per rarità

- `TouchUi` (scripts/ui/touch_ui.gd): attiva su Android/iOS (o con `TouchUi.force` per provare su PC). `BattleTheme.style_button` porta ogni bottone ad altezza minima 64 e testo minimo 20; la battaglia usa 88/80 per gli ordini, la schermata squadra scorre con il dito. Sul PC non cambia nulla. Controllo visivo: `xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/touch_shots.gd -- cartella 1`.
- `GachaGuide` (scenes/roster/gacha_guide.gd): quattro pagine (valute, rarità, copie e garanzie, operatori). Le cifre vengono da `BattleContent` e `Recruiting`; si apre da sola la prima volta (`Settings.gacha_guide_seen`) e dal bottone COME FUNZIONA.
- Rarità: `BattleContent.RARITY_STAT_MULT` (1.00 / 1.08 / 1.18 / 1.32) moltiplica le statistiche degli operatori; l'equipaggiamento usa `GEAR_RARITY_MULT`. Le quote di estrazione si leggono con `BattleContent.rarity_odds()` (55/30/12/3).

## Prestazioni e caricamenti (0.5.1)

- Fondo nero non ridisegnato: il colore di pulizia dello schermo (project.godot) e' il nero del gioco; `ScreenFx.solid` lascia il nodo ma non lo disegna.
- `BattleStage.StaticLayer`: lo sfondo disegnato dal codice viene "fotografato" in una texture (SubViewport, una volta) e ridisegnato solo se cambia la dimensione o l'app riparte; senza schermo (test) resta il disegno a comandi.
- `battle_overlay.gdshader`: stessa immagine (verificata pixel per pixel con tools/shader_diff.gd) con colori premoltiplicati e senza radici.
- `Warmup`: dall'hub si caricano in secondo piano le schermate, la musica e gli effetti; due shader poco usati si scaldano in un angolo.
- `ArtLibrary`: grafiche oltre 2048 punti ridotte in memoria; il rapporto delle grafiche mancanti non le carica piu' (`has`).
- Splash di Godot disattivato (boot_splash/show_image=false).
- Strumenti: `tools/bench.gd` (ms per schermata), `bench_ab.gd` (sfondo a comandi o a texture), `bench_parts.gd` (dove va il tempo), `bench_load.gd` (caricamenti), `shader_diff.gd`.

## Fazioni: fondamenta (scripts/battle/factions.gd)

- Ogni unita' ha `faction`, `style` (ortodosso/atipico), `rarity`, `crit`, `crit_dmg`, `base` (statistiche pulite), `aura`, `mods`.
- `Factions.refresh(state)` ricalcola atk/def/spd/crit = base + aure + mods. Chiamarlo dopo ogni cambiamento
  (e' gia' chiamato in `BattleState.create` e a fine round).
- Aura: ogni operatore vivo da' ai compagni vivi della stessa fazione un bonus (comune 1%, rara 2%, epica 3.5%,
  leggendaria 5%), sommato e limitato a +25% (`AURA_CAP_PM`). Valori in per mille, tutto intero.
- Magabondi: niente aura, ricevono meta' della piu' forte in squadra. Statistica delle Rondini (crit) provvisoria.
- `Factions.add_mod(u, id, stat, pm, turns)`: bonus/malus temporanei (stessa id = si rinnova). `Factions.suppress(state, fazione, turni)`:
  spegne le aure (per la Dissonanza dei Kairos). `Factions.tick` li fa scadere a fine round.
- Critico: `Factions.rolls_crit` e' deterministico (seme + round + attaccante + bersaglio + indice evento), non consuma l'RNG;
  chi ha crit 0 non cambia nulla. Danno critico x1.5; il colpo emette l'evento `crit`.
- Le aure agiscono solo nella squadra del giocatore (in multigiocatore non attraversano i giocatori).

### Stile ortodosso / atipico

Scelta di strategia per gli operatori con fazione (bottone STILE nella scheda del roster, gratuito):
- ortodosso: da' e riceve l'aura intera;
- atipico: da' e riceve meta' aura, ma ha +8% ATK e +5% VEL personali (i Magabondi, atipici per natura, non dimezzano due volte).
`RosterState.validate_entry` rifiuta fazione/rarita'/stile truccati nelle squadre ricevute dalla rete.
`BattleState._blank_unit` e' la base comune di giocatori e boss. `tools/bench_sim.gd` misura la logica di battaglia (~0,2 ms a round).

## Guide di gioco: STRATEGIE, ARCHIVIO, LEGENDA

- `scripts/battle/strategy_info.gd`: cosa fa ogni classe e fazione, come si vince, cosa serve, cosa c'e' gia' e cosa arriva.
- `scripts/battle/lore.gd`: legenda di ogni operatore (chi e', come si usa, classe, fazione), glossario dei termini (cifre lette dal codice)
  e archivio. La lore dei personaggi e' una BOZZA da riscrivere. Un nuovo operatore in `BattleContent.CHARACTERS` deve avere la sua voce
  in `Lore.CHARACTERS` (lo controlla `test_factions.gd`).
- Le tre guide usano la finestra `GachaGuide` (`open_pages`) e si aprono dall'archivio operatori (bottoni STRATEGIE, ARCHIVIO, LEGENDA).
- Il tutorial del primo combattimento ha un passo su classi e fazioni.

## Leggibilita' di battaglia e menu

- Battaglia: `BattleResolver.begin_round` calcola subito le scelte dei compagni IA (visibili anche ai client: `BattleNet.snapshot_for`);
  `BattleResolver.action_order(state)` da' l'ordine in cui agiranno (priorita', velocita'). Il pannello ORDINE DEL TURNO
  (`BattleScreen.turn_rows`) lo mostra. Ogni compagno IA sceglie da solo: non copia il giocatore.
- `BattleStage`: la panchina e' disegnata scura/trasparente dietro i combattenti; etichette TU / IA<n> / nome; segnalino rosso
  su chi agisce e cerchio su chi subisce (`acting`, `acting_target`).
- Archivio operatori: in alto la squadra (3 carte, `OperatorCards.slot_card`), sotto la griglia della collezione
  (`OperatorCards.tile`) e la scheda. Nell'equipaggiamento il ritratto e le icone dell'operatore che si sta modificando.
- `scripts/ui/game_icon.gd` (`GameIcon`): icone vettoriali segnaposto per classi, fazioni, tipi di mossa, equipaggiamento e valute.
  `GameIcon.move_key(id)` ricava l'icona dalla mossa; `GameIcon.attach(button, chiave, colore)` la mette in un pulsante.
  Per grafica vera basta sostituire il disegno in `_draw`.
