# QA_HANDOFF — ODISPEL 0.24.34

## Identificazione
- Versione: 0.24.34 (Android versionCode 59)
- Data build: 16 ottobre 2026
- Branch: `claude/battaglia-chiara` (commit: vedi `git log -1`)
- Obiettivi di questa consegna (due richieste unite in una sola build):
  1. Chiudere la verifica dell'anteprima del colpo del boss (coerenza con il danno reale).
  2. HUD polish, iterazione 1: stili dei pannelli, HUD PvP nella palette, comandi condivisi, leggibilita' su telefono.
- Versione precedente recuperabile: 0.24.33 (in `releases/`); la 0.24.32 e la 0.24.31 sono nella storia git.
- 0.24.34 = 0.24.33 + passaggio su accessibilita' (vedi sezione 3), richiesto dal brief 'HUD POLISH PROFESSIONALE'.

## 1. Anteprima del boss (threat_preview)
Misura: `tools/preview_check.gd` (8 boss x 3 squadre x 8 semi, scelte dell'IA con Guardia a caso, 1511 round, circa 2600 colpi del boss). Ogni colpo reale viene confrontato con un modello "anteprima x modificatori noti".

- Bug CONFERMATO e corretto: l'anteprima ignorava il bonus +8% lasciato da una placca rotta nel round precedente (`boss_boost`, gia' noto a inizio round). Ora lo include. Test: `test_threat_preview.gd`.
- Risultato dopo la correzione: i colpi della PRIMA mossa sono tutti spiegati. Differenze residue, sempre da cause che nascono durante il round (non prevedibili a inizio round):
  Guardia scelta nel round (x0,5), furia a meta' round (x1,25: anche a meta' di una mossa su piu' bersagli, dopo i contrattacchi), placca rotta nel round (+8%), comportamento dell'arena (+10..+30% / +15%), provocazione/intercetta (cambia il bersaglio), schivata, tenacia.
- Catena (seconda mossa): il suo danno dipende dal primo colpo (stati applicati, scudi) e NON e' stimato. 75 colpi di catena su circa 2600 non rientrano nel modello esatto. L'anteprima la segnala solo come "+CATENA" nel nome della mossa.
- Critici: il boss non ne fa (0 su 1511 round e 66 colpi in test; non ha la statistica critico).
- Comunicazione del limite: l'etichetta ora dice "STIMA ~N" (non piu' "danno minimo": la Guardia lo abbassa). L'avviso "SE SI INFURIA: LETALE PER ..." compare solo se: il boss non e' ancora infuriato, ha tra 50% e 75% dei PV, il colpo non e' gia' letale e lo diventerebbe con +25%. Identifica solo i bersagli per cui `danno <= PV+scudo < danno x 1,25`.
- Il codice documenta cosa include e cosa no l'anteprima (commento sopra `threat_preview`).

## 2. HUD polish, iterazione 1
### Audit: i tre stili di pannello (tutti `scripts/ui/hud_panel.gd`)
- Principale (predefinito): ombra, linguetta col titolo, filo 2 px. Usato da GUIDA (`battle_coach.gd`), ESITO, REPLAY (`battle_screen.gd`, `pvp_screen.gd`).
- Secondario (`quiet`): velo e filo 1,5 px. Usato da ALLARME, ORDINE DEL TURNO, timer.
- Sovrapposto (`bare`): solo velo scuro. Usato da blocco boss, carte operatore, LOG.
- Fuori da HudPanel c'erano due riquadri con colori vecchi (verde-azzurro) scritti a mano: carta giocatore PvP e medaglia della fase.

### Modifiche
- I tre ruoli sono ora documentati in cima a `hud_panel.gd`; il titolo del ruolo secondario passa da 12 a 14.
- `BattleTheme` (`scripts/ui/battle_theme.gd`): nuove costanti dei comandi (`BTN_*`, `ICON_OFF`) e due funzioni condivise: `style_move_button()` (era duplicata in `battle_screen.gd` e `pvp_screen.gd`) e `plate_box()`.
- PvP (`pvp_screen.gd`): carte giocatore e comandi nella palette; barra PV bianco-ciano (rossa sotto il 30%) invece del verde; barra ultimate rossa come in battaglia.
- Medaglia della fase (PvE) nella palette.
- Telefono: il ventaglio dei comandi si sposta di 44 px a sinistra (prima l'ultimo comando finiva sotto la scheda GUIDA e il costo "0%" restava coperto).
- Annunci (`comic_fx.gd`): descrizioni lunghe (es. "PUNISCE LE CURE") uscivano dallo schermo (difetto confermato con screenshot touch); ora si rimpiccioliscono e vanno a capo.
- Segno "AGISCE" (`battle_stage.gd`): non scompare piu' dietro ORDINE DEL TURNO.
- Testo dei suggerimenti del boss da 12 a 13.

### Decisioni di design / compromessi
- Il verde "OK" resta solo per scritte di effetto e per la scheda GUIDA e il suo bordo di evidenziazione del tutorial (scelta voluta: e' la voce "guida").
- I tre stili restano tre (hanno ruoli diversi); sono stati uniformati nella palette, nei titoli e nei comandi, non fusi in uno.

## 3. Accessibilita': contrasti, vita bassa, KO, numeri lunghi (0.24.34)
- Misura: `tools/contrast_check.gd` (rapporto WCAG 2.x, sfondo peggiore = cielo viola chiaro sotto i pannelli semitrasparenti). Test di regressione: `tests/unit/test_contrast.gd` (22 coppie: testi >= 4,5, barre >= 3).
- Difetto CONFERMATO e corretto: il rosso nemico (#f0453c) come TESTO sul pannello ALLARME/ORDINE DEL TURNO aveva contrasto 3,6 e 2,2. Ora: nuovo `BattleTheme.RD_TEXT` (#ff6a60) per i testi di pericolo, velo piu' scuro sul pannello ALLARME (0,88) e sull'ordine del turno (0,80). Contrasti ora 5,4 e 4,8.
- Difetto CONFERMATO: i suggerimenti del boss (pannello ALLARME) erano a 11 px per un override rimasto dopo la modifica a 13 della 0.24.33. Ora 13.
- I fili (bordi) dei pannelli hanno contrasto basso sul cielo (ciano 2,35; rosso 1,01): sono decorativi, l'informazione e' nel testo, e non sono stati modificati. Non e' una verifica di accessibilita' completa.
- Stati critici (`tools/states_shot.gd`, screenshot PC e touch con vita al 12%, un KO, 987654 PV con scudo 123456, boss al 58%): vita bassa = barra rossa e numero; KO = scheda scurita con la scritta "K.O." (non solo colore); numeri lunghi dentro la scheda; reazione "Soccorso" visibile. Il pericolo e' comunicato con testo ("LETALE PER ...", "STIMA ~N") oltre che col colore.
- Non verificato: contrasto reale su schermo di telefono (luminosita', daltonismo), tastiera/gamepad nelle schermate toccate, risoluzioni diverse da 1280x720.

## Test
- Eseguiti (0.24.34): tutti i 76 file in `tests/unit/` in headless (parallelo): nessun errore. `test_hud_layout` (31 controlli) e `test_input_ui` richiedono uno schermo e sono passati con `xvfb-run`.
- Nuovi: `tests/unit/test_threat_preview.gd` (26 controlli: identita' senza modificatori, Guardia, bonus placca, avviso furia, catena, nessun critico del boss); 5 controlli in `test_hud_layout.gd` (ventaglio a sinistra della GUIDA e dentro lo schermo in PC e touch, annuncio lungo dentro lo schermo, stile condiviso dei comandi); 9 sulla validazione dei salvataggi (0.24.31).
- `tools/ui_audit.gd` in modalita' PC e touch: nessun problema (tasti e testi, anche PvP).
- Screenshot controllati a mano da me (xvfb, 1280x720): battaglia PC, battaglia touch (due stati), PvP 1v1 PC. NON controllati: PvP in modalita' touch, PvP 2v2 / ffa, altre risoluzioni.
- Simulazione di bilanciamento (`tools/battle_sim.gd`): riproducibile (due esecuzioni identiche con lo stesso comando). Risultati sui boss provati (distributore, tombino, cabina; IA vs boss, livelli 1-20): vittoria quasi sempre al 100%; il distributore cade in 1-2 round a tutti i livelli, tombino e cabina tra 2 e 8 round, con un 80% a livello 1 in solitaria contro la cabina (Incubo). Nessun valore e' stato modificato. Limite: l'IA gioca con kit predefiniti; il risultato dice poco sul divertimento.
- NON eseguiti: multiplayer con giocatori reali, rete pubblica, Android su dispositivo, avvio dell'exe su Windows.

## Build e pubblicazione
- `releases/ODISPEL-0.24.34-windows.zip` (exe + dll WebRTC) e `releases/ODISPEL-0.24.34.apk` (firma di debug, 1 firmatario verificato). Percorso nel repo privato: `https://github.com/Gialloo/odispel/tree/claude/battaglia-chiara/releases`
- SHA256 in `releases/SHA256SUMS.txt`. Resta la 0.24.33 come versione precedente.
- itch.io: il workflow `.github/workflows/itch.yml` carica da solo gli ultimi file di `releases/` dopo il push. Dal mio ambiente NON vedo l'esito: controllare la scheda Actions su GitHub o la pagina itch.io.

## Problemi aperti
- Avviso "SE SI INFURIA" e "STIMA": utilita' e chiarezza da valutare in gioco.
- La catena non ha una stima di danno.
- HUD PvP: verificata solo in modalita' 1v1 PC; il layout delle carte per 2v2 / ffa non e' stato rivisto.
- Leggibilita' e prestazioni su telefono reale non verificate.
- Simbolo AUTO: sintomo esatto non ricevuto.
- Multiplayer a 4 giocatori reali e Internet pubblico: non verificati.
- Rischi dell'audit di ChatGPT non riprodotti e quindi NON toccati: scudo/cura su bersaglio a 0 PV nella stessa mossa, etichetta della sinergia decisiva, munizioni condivise torretta/drone, bilanciamento del roster.

## Playtest (per il proprietario)
Su PC e su telefono:
1. All'avvio: finestra NOVITA' 0.24.34 con OK visibile.
2. Battaglia contro un boss: sotto il nome della mossa annunciata deve esserci "BERSAGLIO: ... · STIMA ~numero". Se il boss ha una catena: "+CATENA" accanto al nome.
3. Porta il boss tra 75% e 50% di vita con un compagno ferito: puo' comparire in arancio "SE SI INFURIA: LETALE PER ...". Dopo il colpo, il compagno e' davvero a rischio? L'avviso ti e' utile o ti confonde?
4. Telefono: apri il ventaglio dei comandi con la scheda GUIDA visibile (prime battaglie): "SPEZZATUTO 0%" deve leggersi tutto.
5. All'inizio di un boss con comportamento (es. PUNISCE LE CURE): l'annuncio al centro deve stare dentro lo schermo, anche su telefono.
6. PvP (1v1): barre PV bianco-ciano, ultimate rossa, comandi uguali a quelli del PvE. Prova anche 2v2 e dimmi se le carte si sovrappongono.
7. Telefono, in piena luce: leggi il pannello ALLARME (in alto al centro) e l'ordine del turno. I testi rossi si leggono senza sforzo? Dimmi anche se ti accorgi di KO e vita bassa senza guardare i colori.
8. In caso di errore: schermata, dispositivo (PC o modello del telefono), modalita' e boss.

## Prossimo passo
- In base al playtest: (a) rivedere le carte PvP per 2v2/ffa e il PvP in touch, (b) decidere se mostrare un intervallo di danno (con Guardia) o la stima della catena, (c) iniziare l'audit dei test sul resto delle sinergie (scudi/cure sullo stesso bersaglio) con test che riproducono prima il problema.
- Rischio: toccare il motore deterministico; ogni modifica va coperta da test esatti.
