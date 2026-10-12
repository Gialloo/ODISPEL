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
