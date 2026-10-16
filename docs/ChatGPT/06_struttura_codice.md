# ODISPEL, parte 6 di 6: com'e' fatto il codice

Dopo questo messaggio scrivo FINE. Se ti serve il codice di un file preciso, dimmi quale e te lo incollo.
Dimensione: circa 49.000 righe di GDScript, 71 file di test automatici. Repository privato su GitHub, un solo ramo di lavoro.

## Principi
1. **Il motore non disegna e l'interfaccia non decide.** Tutto cio' che cambia il risultato di una battaglia sta in `scripts/battle`. La grafica sta in `scenes/` e `scripts/ui`.
2. **Lo stato di battaglia e' un Dictionary** con soli int, String, Array, Dictionary, bool (niente numeri decimali). Deve sopravvivere identico a una conversione in JSON.
3. **Deterministico**: nessun random nel motore; il seed viaggia nello stato. Premi e IA sono deterministici.
4. **Host autoritativo** in rete (WebRTC): l'host risolve i round, i client mandano le scelte e ricevono lo stato e gli eventi. Server di segnalazione in Node.js su Render.
5. **Interfaccia tutta da codice**: nessuna scena disegnata nell'editor; i pannelli sono Control creati e posizionati da script, su una base 1280x720 inquadrata nell'area sicura dello schermo (ScreenFrame) per i telefoni.
6. La schermata di battaglia lavora su una "sorgente" con interfaccia comune: SoloBattleSource (da soli), NetworkManager (rete), PvP a parte.

## Cartelle
- `scripts/battle/`: il motore. `battle_types.gd` (costanti e regole), `battle_content.gd` (dati: mosse, passive, 24 personaggi, equipaggiamento, 18 boss, difficolta'), `battle_state.gd` (stato), `battle_resolver.gd` (risoluzione del round, danno, ordine delle azioni), `battle_ai.gd`, `battle_rewards.gd`, `battle_text.gd`, `signatures.gd` (abilita' uniche), `factions.gd`, `archetypes.gd`, `combos.gd`, `marks.gd`, `arena.gd`, `tactics.gd`, `atypical.gd`, `hints.gd`, `lore.gd`, `banter.gd`.
- `scripts/roster/`: collezione del giocatore, equipaggiamento, reclutamento, missioni giornaliere e settimanali, spedizione, titoli, potere, maestria, obiettivi, tutorial, salvataggio.
- `scripts/network/`: WebRTC, sessione di rete, sincronizzazione della battaglia.
- `scripts/ui/`: pezzi di interfaccia riusabili (BattleTheme con colori e font, HudPanel, SlantBox, LineBar, FanMenu, ScreenFrame, TouchUi, LightPaint per gli effetti di luce, AnimFx, UltFx, ComicFx, Notify, ButtonFx).
- `scripts/config/`: versione del gioco, changelog, impostazioni, profilo.
- `scenes/`: le schermate (hub, missions, roster, lobby, battle, expedition, feats, titles, tutorial, story, results, ui).
- `tests/unit/`: un file di test per area. `tools/`: simulatori, foto delle schermate, benchmark, controllo automatico dei pulsanti.
- `docs/`: documentazione, tra cui la Art Bible. `releases/`: gli APK e gli zip pubblicati.

## File piu' grandi
`scenes/battle/battle_screen.gd` (circa 3.000 righe: costruzione e aggiornamento della HUD di battaglia, eventi e animazioni), `scenes/battle/battle_stage.gd` (circa 1.600: il palco disegnato da codice, personaggi in prospettiva e boss), `scripts/ui/light_paint.gd` (circa 800: gli effetti di luce), `scenes/battle/pvp_screen.gd` (circa 860).

## Come si aggiorna la schermata di battaglia
`_sync()` copia lo stato mostrato; poi `_refresh_boss`, `_refresh_telegraph`, `_refresh_operators`, `_refresh_orders`, `_refresh_turn_panel`. I pannelli si ricostruiscono solo se cambia una "firma" (testo riassuntivo dello stato), per non pesare. Gli eventi del round (danno, cura, scudo, stati, combo, fasi) arrivano in una lista e `_play_events` li anima uno alla volta, con un tetto di 14 secondi a round. Le animazioni non decidono mai il risultato.

## Aspetto tecnico
Godot 4.7.2, renderer Compatibility (anche su telefono), Windows e Android. Tutto il testo e' in italiano. Salvataggi in file JSON nella cartella dati dell'utente. Controlli di qualita': 71 test automatici, un controllo che cerca pulsanti e testi sovrapposti o tagliati su PC e telefono, foto delle schermate generate dal codice.

## Cosa manca o e' aperto
Illustrazioni vere per quasi tutti i personaggi (solo Kira); effetti di luce disegnati a mano al posto di quelli generati; il tasto AUTO segnalato come non funzionante da un giocatore (nei test funziona); verifica su telefono vero della leggibilita' e delle prestazioni; bilanciamento della difficolta' ABISSO e del bonus kit completo da legare alla rarita'.

FINE.
