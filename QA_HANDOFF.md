# QA_HANDOFF — ODISPEL 0.25.0

## Identificazione
- Versione: 0.25.0 (Android versionCode 62) = 0.24.36 + COMMISSIONE ICONE (sezione 5). (0.24.36:) 0.24.36 = 0.24.35 + correzione dopo la prova su telefono (SM-A075F, 1446x664): icone fazione e icona equilibrio troppo piccole/poco chiare. Ora: fazione 30 px touch (20 PC), a x=221 sulla carta con le munizioni sotto; equilibrio con icona 20 px + scritta EQUILIBRIO; cuore PV 18 px. Verificato solo con screenshot xvfb touch 1280x720, NON sul telefono.
- (0.24.35) NB: il brief 'MASTER BRIEF HUD & UI/UX' cita la 0.24.33 / commit e5f6f86; lo stato reale del repo era 0.24.34 / c127afc (0.24.33 e' la sua base).
- Data build: 16 ottobre 2026
- Branch: `claude/battaglia-chiara` (commit: vedi `git log -1`)
- Obiettivi di questa consegna (due richieste unite in una sola build):
  1. Chiudere la verifica dell'anteprima del colpo del boss (coerenza con il danno reale).
  2. HUD polish, iterazione 1: stili dei pannelli, HUD PvP nella palette, comandi condivisi, leggibilita' su telefono.
- Versione precedente recuperabile: 0.24.34 (in `releases/`); 0.24.33 e precedenti nella storia git.
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

## 4. MASTER BRIEF HUD — iterazione 1: struttura e riduzione del rumore (0.24.35)
Solo struttura e pulizia (la personalita' grafica viene dopo). Nessun cambiamento a regole, bilanciamento, salvataggi, protocollo multiplayer.

### Stati dell'interfaccia (`hud_mode()` in `battle_screen.gd`, applicato da `_apply_hud_mode()`)
- scelta: turno del giocatore; tutto cio' che serve a decidere (ALLARME, suggerimenti, riserva, ORD/COSTO, ventaglio).
- pericolo: il colpo annunciato e' letale o potrebbe diventarlo se il boss si infuria. UN solo avviso: ALLARME con icona di pericolo + testo esplicito "LETALE PER ..."; i suggerimenti di pianificazione spariscono.
- risoluzione: il round si gioca (locked/animating/autoplay/fine). Spariscono riserva, ORD/COSTO, suggerimenti; ALLARME resta ma attenuato (alfa 0,55).
- Non separati come stati propri: selezione bersaglio (il ventaglio e' unico, nessun pannello bersaglio dedicato in PvE), evento speciale (annunci al centro: gia' un livello temporaneo).

### Livelli: sempre visibile / contestuale / temporaneo
- Sempre: turno, ordine del turno (compatto), blocco boss (nome, PV, equilibrio), carte operatore, ALLARME.
- Contestuale: riserva di squadra, ORD/COSTO, suggerimenti, ventaglio delle mosse, tasti reazione.
- Temporaneo: annunci, numeri di danno, scheda GUIDA, notifiche.

### Duplicazioni tolte
- Numero dei PV sotto lo sprite: ora solo per l'operatore che sceglie o appena colpito (prima: tutti i front mentre si sceglie, in piu' alla carta in basso). File `battle_stage.gd` (`_draw_hp_under`).
- Ordine del turno: la riga del boss non ripete il nome della mossa (e' in ALLARME): ora "ATTACCA".
- Etichetta "PV" del boss: sostituita dall'icona cuore.

### Grammatica visiva (registro `GameIcon.SYMBOLS`, `scripts/ui/game_icon.gd`)
Famiglie: stato (hp), difesa (shield, balance), pericolo (danger, ko), azione (sword, heal, taunt, target, cleanse), risorsa (bullet, burst). Ogni voce: famiglia, nome, descrizione (tooltip). `GameIcon.describe(key)`.
- Riutilizzate (gia' presenti): shield, sword, heal, taunt, bullet, burst, target, cleanse.
- Create: hp (cuore), balance (barra con tacca), danger (triangolo con !), ko (cerchio con X). Disegnate in codice, stesso stile (contorno + riempimento al 35%).
- Applicate: hp e balance nel blocco boss (tooltip), danger nel pannello ALLARME solo con rischio di KO. `ko` e' registrata ma NON ancora applicata (la carta KO usa gia' la scritta "K.O."); resta da fare.
- Regola: icona + numero dove il significato e' noto; testo esplicito per il rischio di KO (accessibilita'); niente significato col solo colore (forma diversa + testo).
- Non fatto in questa iterazione: icone per debolezze/resistenze, combo/reazioni/sinergie, buff/debuff; tutorial graduale dei simboli; PvP (stati e icone non applicati).

### Conteggio elementi visibili contemporaneamente (`tools/hud_count.gd`: testi + pulsanti + pannelli + barre + icone; 1280x720; PC e touch identici)
| stato | prima (0.24.34) | dopo (0.24.35) |
| scelta | 87 | 89 (+2 icone PV/equilibrio al posto di testo) |
| pericolo | 88 | 90 (+ icona; -suggerimenti) |
| risoluzione | 92 | 76 |
Onesto: in SCELTA il numero non scende (tutto serve a decidere) e sale di 2 per le icone. La riduzione e' in risoluzione (-16). Lo strumento NON conta cio' che il palco disegna (numeri PV sotto gli sprite): quelli scendono da 3 a 1 in scelta. NB: la prima misura "risoluzione" prima era in realta' una scelta (ventaglio ancora aperto): il nuovo strumento sceglie fino a far partire il round.
Screenshot: `/tmp/shots/b35` (prima) e `/tmp/shots/a35` (dopo) nel mio ambiente, non nel repo.

#### 10. TEST V2 (prototipo battaglia v2, 0.26.3-v2test)
- Hub: nuovo pulsante "TEST V2" (`SceneRouter` chiave `battle_v2`) -> `scenes/battle_v2/battle_v2.tscn`. Solo battaglia solista in addestramento (nessun premio, nessun salvataggio) contro il Distributore, con la logica reale (`SoloBattleSource`, `BattleResolver`). Nessun PvP, rete o Ciclo Infinito. La scena vecchia non e' toccata.
- HUD: porting del mock v88 (ruota ATTACK/SKILL/ULTIMATE/GUARD, banner boss con PV ed EQUILIBRIO, party, RISERVA, comandi rapidi AUTO/VELOCITA'). Sfondo pre-renderizzato `art/backgrounds/battle_v2.png`, alone corallo del boss con texture unica. La scena si scala per entrare nello schermo (canvas_items/expand).
- Stub / limiti: FORMAZIONE e BERSAGLIO mostrano solo un avviso; DEBOLE assente (il motore non ha dati di debolezze); il boss e' il segnaposto disegnato; arte vera solo per Kira e Dafne, gli altri hanno la testa segnaposto.
- Verificato: `tools/battle_v2_shot.gd` (xvfb, 1280x720) gioca una battaglia intera (vittoria al round 3, 0 errori) e salva 5 foto; test unitari esistenti ok (test_feedback aggiornato a 10 pulsanti hub).
- NON verificato: telefono reale (dimensione testi, bersagli di tocco da 44 px, tagli su schermi 20:9, prestazioni), boss con nome molto lungo, squadre con meno di 3 unita'.
- Animazione (0.26.4-v2test): pennellate che entrano a catena e ondeggiano di continuo, scie di luce e schizzi che scorrono, comandi che entrano a rimbalzo, onda d'urto + scintille al tocco, anelli che pulsano sul comando scelto, oscuramento animato con raggi, bande oblique e energia che converge sull'eroe (ULTIMATE: barre scure oblique, piu' intensa), banner e CONFERMA che scivolano dentro, scossa dello schermo e vibrazione (`Settings.buzz`). Foto: `tools/battle_v2_anim.gd`. NON verificato su telefono: costo per fotogramma (ridisegno a 30 fps delle pennellate, ogni fotogramma dei comandi) e vibrazione.
- Camera (0.26.5-v2test): molla smorzata con ondeggio continuo, urti alla scelta/conferma e spinta in avanti (piu' forte sull'ULTIMATE); mondo, sfondo e lettere hanno parallasse diversa, l'HUD segue in ritardo e di meno. Cerchio giallo pieno (niente tratteggio), bottoni che 'respirano', ULTIMATE pronta con alone e riflesso. NON verificato su telefono.
- Ottimizzazione e light painting (0.26.6-v2test): le pennellate sono disegnate UNA volta in texture (piatta + versione light painting additiva, rifatta solo al cambio personaggio) e si animano con sola trasformazione/opacita'; le scie di luce escono dalla vernice e sono CPUParticles2D (nessun punto bianco); alone del boss = una sola texture additiva invece di 48 copie; rimossi fasci/bande orizzontali, raggi e convergenza; ridisegno per fotogramma solo di anelli e overlay di scelta. Misure di costo NON fatte su telefono.
- Prestazioni alla scelta (0.26.7-v2test): causa dei cali = ridisegno per fotogramma di banner (~330 poligoni) e HUD intero durante la transizione, vignetta a ~70 rettangoli a schermo intero, alone con 10 cerchi grandi, texture delle pennellate a quadrato pieno. Ora: banner e CONFERMA sono nodi disegnati una volta e animati con posizione/opacita', vignetta e alone sono texture, pennellate ritagliate sulla propria zona, gradiente del party in un poligono, impulso al tocco nel nodo leggero `_Ring`. Misura `tools/battle_v2_perf.gd` (render SOFTWARE su PC, solo indicatore relativo): libero 349 -> 96 ms, SKILL scelta 421 -> 140 ms, ULT scelta 428 -> 148 ms per fotogramma. NON misurato su telefono.
- APK: `releases/ODISPEL-0.26.7-v2test.apk` (versionCode 70; le 0.26.3-0.26.6 restano come precedenti), `docs/battaglia_v2_mock/*` escluso dall'export.

## Test
`tests/unit/test_impact_frames.gd` (26 controlli: normale, critico pesante, eccezionale, ult non critica/critica/devastante, KO, multi-bersaglio, due mosse, contrattacco/spine, sequenze, guardia, progressione). Foto: `tools/impact_shot.gd`.

### NON verificato
Telefono (durate hit-stop, leggibilita', prestazioni su Mali-G57 in qualita' BASSA), build esportate installate, multiplayer reale, itch.io (esito non visibile dalla sandbox).
Da provare: critico normale; grosso colpo al boss; ult critica; ult che manda KO il boss (un solo lampo, poi FINISH!).

## Test
- Nuovo `tests/unit/test_hud_states.gd` (28 controlli, xvfb): registro icone, riconoscimento pericolo, visibilita' per stato in PC e touch.
- Tutta la suite in `tests/unit/` (parallelo headless) senza errori; `test_hud_layout` 31/31 e `test_input_ui` con xvfb; `tools/ui_audit.gd` PC e touch: 0 problemi.
- NON eseguiti: PvP 2v2 e touch, PvP con i nuovi stati (non toccato), telefono reale, altre risoluzioni, multiplayer. Nello screenshot touch "scelta" si vede un riquadro scuro a sinistra (probabilmente la scheda GUIDA in animazione): non verificato se e' un difetto.

### Domande di design (default scelti)
- Menu mosse PvE resta piatto. Ordine del turno resta visibile ma compatto. "Toughness" = EQUILIBRIO (e placche). Nessuna stima del proprio danno (sarebbe una stima non affidabile).

## 5. Commissione completa del sistema di icone (0.25.0)
Fonte unica: `tools/icons/` (`lib.py` primitive, `defs_a..m.py` disegni, `build.py` generatore). Dettagli, tabella completa e come rigenerare: `docs/icone/README.md`. Atlante: `docs/icone/atlante.html` / `atlante.png`.
- Consegnate TUTTE le voci: A01-A45, B01-B32, C01-C16, D01-D15, E01-E16, F01-F20, G01-G24, H01-H32, I01-I36, L01-L12 (248 icone) + M01-M04 stemmi (252 voci; 276 SVG con le varianti). Stemmi con 5 versioni ciascuno (chiara, scura, colori, compatta HUD, grande menu) in `assets/ui/icons/factions/`.
- Stile: griglia 24, tratto 2, angoli vivi, bianco su trasparente; il gioco tinge (`GameIcon.color`). Formato SVG, scelto perche' scala senza perdita su PC e telefono. Rasterizzazione a runtime dagli SVG incorporati in `scripts/ui/icon_catalog.gd` (cosi' l'esportazione non dipende dall'importazione degli asset); file singoli in `assets/ui/icons/<famiglia>/`.
- Registro: `IconCatalog.ENTRIES` e' lo stesso dizionario di `GameIcon.SYMBOLS` (nessun registro concorrente). Campi: code, name, desc, family, folder, asset, variants, use, status, fallback, same_as. Vecchi nomi (sword, bolt, burst, target, cleanse, coin, nucleo, lega, book, fazioni) -> `GameIcon.ALIASES`.
- Stesso concetto = stessa immagine: 12 coppie dichiarate `same_as` (es. SCUDO e DIFESA statistica, PERICOLO e AVVISO).
- Stato meccaniche: assegnato da me confrontando con i dati del gioco; nel dubbio "da verificare"/"non implementata". Controlla la colonna Stato in `docs/icone/README.md`: e' una valutazione mia, NON una verifica completa.
- Integrate nel gioco (provvisori sostituiti): icone delle mosse (battaglia e PvP: attacco, guardia=DIFESA, speciale, ultimate, cura, provoca, bersaglio, purifica), PV, equilibrio, pericolo (letale = lama; "si infuria" = punto esclamativo), stemmi delle fazioni (carte operatore, roster, hub), valute (crediti, nuclei, leghe), libro/archivio, comando CAMBIA del PvP. NON mostrate: tutte le icone predisposte (status, combo, multiplayer, mondo, ecc.) perche' le schermate/meccaniche non le usano ancora.
- Restano disegnate in codice (fuori commissione): classi (striker/vanguard/warden), munizioni, passiva, slot equipaggiamento.
- Icone di fazione piu' grandi su telefono (30 px) e ingrandite dopo la prova su SM-A075F (0.24.36).
### Test (0.25.0)
- Nuovo `tests/unit/test_icon_catalog.gd` (35 controlli): 252 voci e conteggi per famiglia, codici unici, campi del registro, ogni SVG si rasterizza, nessun angolo opaco (trasparenza), leggibilita' a 20 px (pixel visibili tra 20 e 330), file singoli presenti, doppioni solo se dichiarati, alias, fallback per ID inesistente.
- Tutta la suite `tests/unit/` (headless) senza errori; `test_hud_layout` 31/31, `test_hud_states` 28/28, `test_input_ui` con xvfb; `tools/ui_audit.gd` PC e touch: 0 problemi.
- Screenshot reali (xvfb 1280x720) in `docs/icone/screens/`: battaglia (scelta, pericolo, risoluzione; PC e touch), roster, hub, PvP, obiettivi, lobby multiplayer. Avviati davvero: battaglia, roster, hub, PvP, obiettivi, lobby. NON testate su schermo: menu fazioni dedicato (non esiste), progressione oltre gli obiettivi, multiplayer con persone reali, telefono reale.
- IMPORTANTE da verificare su telefono/PC: le icone vengono rasterizzate a runtime con `Image.load_svg_from_string` (modulo SVG del motore). Funziona nell'editor/headless (test); NON ho potuto eseguire le build esportate. Se il modulo mancasse nel template di esportazione, il gioco ripiega sui vecchi disegni in codice (nessun crash) ma le icone nuove non si vedrebbero: nel playtest controlla che le mosse mostrino lama/scudo/fulmine nuovi e le fazioni i nuovi stemmi.
- Esportazione: `docs/icone/*` e `assets/ui/icons/*` sono esclusi dal pacchetto (gli SVG sono gia' incorporati nel registro): APK 0.25.0 = 0.24.36 + circa 50 KB.
- Limiti: leggibilita' reale di 248 icone a 20-24 px su telefono NON verificata (il test misura solo i pixel visibili). Alcune icone sono simili a piccole dimensioni (anelli: C04/D04/C16/G07; sagome multiple A19/D09/F17): guardare l'atlante e dirmi quali non si capiscono. Non ho confrontato "prima/dopo" per roster/progressione/multiplayer (prima avevano gli stessi segnaposto in codice).

## 6. Impact frames anime (0.26.0)

Solo presentazione: nessuna modifica a motore, regole, bilanciamento, salvataggi o protocollo multiplayer.

### Come si lega un colpo alla sua mossa (verificato nel codice)
- Gli eventi `damage` NON portano l'id della mossa. Il legame e' il gruppo (indice dell'ultimo `act`/`boss_move`, sorgente del danno): `ImpactFrames.plan()`.
- Contrattacchi (sorgente diversa), spine (`thorns`) e costi (`cost`) non ereditano mai l'ultimate. Ult multi-bersaglio: un solo colpo "decisivo" per gruppo (il piu' grande in rapporto ai PV massimi, a parita' il primo). Colpi simultanei di mosse diverse = gruppi indipendenti.
- PvP: l'evento `act` porta gia' `kind`; stesso piano, soglie "giocatore".

### Livelli e soglie (`ImpactFrames.CFG`, tutte relative ai PV massimi/attuali del bersaglio)
Priorita': ult devastante > ult critica > danno eccezionale > critico pesante > normale.
1 critico (>=3% PV max) · 2 eccezionale (>=18% PV max boss / 35% giocatore, oppure >=60% dei PV attuali con almeno 8% dei max) · 3 ult critica · 4 ult devastante (>=28% / 50%, oppure >=75% dei PV attuali con almeno 12%).
Hit-stop iniziale (ms): 65 / 100 / 125 / 185 (`ImpactFrames.HIT_STOP`); overlay 0,22 / 0,34 / 0,5 / 0,75 s. Sono valori di partenza da regolare provando su telefono.

### Implementazione
- `scripts/ui/impact_overlay.gd` (disegno procedurale, tempo reale, niente shader), `scripts/battle/impact_director.gd` (guardia anti-sovrapposizione: un effetto uguale/piu' debole durante uno attivo viene ignorato, uno piu' forte lo sostituisce; 350 ms minimi tra due lampi), `BattleStage.freeze()` (pausa solo del palco, max 0,3 s). NIENTE `Engine.time_scale`.
- Rispetta `Settings.shake` (via `stage.impact`), `Settings.flash` (lampi a 0 = nessuna luce improvvisa), `Settings.skip_cutin` (livelli 3-4 in versione ridotta), `AnimFx.enabled()` (qualita' BASSA: versione ridotta, hit-stop x0,6).
- KO: se il colpo letale ha mostrato un impact frame, `down` (boss e giocatore) non ripete lampo, scossa, linee e slow-motion; restano FINISH!/K.O.!.
- Debug: IMPOSTAZIONI > PROVA GLI EFFETTI D'IMPATTO (`ImpactLab`), 4 bottoni.

## 7. AUTO e prestazioni (0.26.1)

- Tasto AUTO: non sono riuscito a riprodurre l'accensione+spegnimento in test (un click, un tocco emulato e il tasto A restano accesi per piu' round). Ipotesi piu' probabile: due eventi di pressione ravvicinati sul dispositivo (tasto a scatto alla pressione). Correzione difensiva: `toggle_autoplay()` ignora un secondo cambio entro 350 ms (`AUTO_DEBOUNCE_MS`); stessa funzione per il tasto A. Test: `tests/unit/test_autoplay_toggle.gd`. DA VERIFICARE SUL TELEFONO e su PC: premere AUTO una volta deve lasciarlo acceso (il toast dice AUTO ATTIVO).
- Prestazioni (solo con effetti ridotti = telefoni): palco a riposo, `SelectArrow` e `PortraitView` a 30 disegni/s (`Settings.light_fx`). Il resto (testi in cache, tratti di luce a mesh, limite 60 fps, passaggio automatico a effetti ridotti sotto 40 fps) c'era gia'. Misure headless invariate (nessuna regressione); il guadagno reale sul Mali-G57 NON e' misurato.

## 8. Ottimizzazione generale (0.26.2)

Misure fatte con `tools/perf_scenes.gd` (tutte le schermate: caricamento, nodi, nodi che girano ogni frame) e prove mirate. Il costo a schermata ferma era gia' basso quasi ovunque (sfondo menu = scorrimento di un nodo, testi del palco in cache, tratti di luce a mesh). Trovato e corretto:
- Operatori: `_refresh_list` ricostruiva ~30 schede a ogni tocco (21 ms su PC, headless) e `_refresh_slots` le 6 carte (8,5 ms). Ora le schede si riusano se la firma (selezione, livello, rank, posto, touch) non cambia: 0,4 ms e 0,03 ms. Test: `tests/unit/test_roster_cache.gd`.
- `PortraitView`: niente ridisegno se fuori schermo o scorso via in una lista; testo con `TextLine` in cache. `ArrowScroll`: non sposta i pulsanti se la lista e' ferma.
- Progetto: fisica a 30 tick (nessun oggetto fisico nel gioco).
- Android: export in modalita' RELEASE (stesso keystore di debug, risigna `shrink_apk.py`): APK ~1,8 MB piu' piccolo, senza il sovraccarico del template debug. NON provato su telefono.
- Non toccato (gia' ottimo o rischioso senza dispositivo): palco di battaglia, schermata Equipaggiamento (18 ms per refresh su PC) e Reclutamento (10 ms): candidati per una prossima passata.
- NON misurato: guadagno reale su telefono (la sandbox ha solo rendering software).

## 9. Tuning impact frames dopo test Android (0.26.2)

Feedback: pausa troppo lunga, lampo debole, quattro livelli troppo simili. Nessuna modifica a danno, motore, PvP, rete.
- Audit: nella 0.26.0 la pausa nominale era 65/100/125/185 ms, ma con effetti ridotti (qualita' BASSA, come sul telefono) `ImpactDirector` la moltiplica per 0,6 (e per 0,5 se due lampi sono vicini): sul telefono erano ~39/60/75/111 ms. Lampo: alpha bianco 0,34-0,5 per 2-3 fotogrammi (a 30 fps poco piu' di uno), decadimento rapido.
- Ora (`ImpactFrames.HIT_STOP`) nominale 40/60/80/120 ms; con effetti ridotti restano x0,6 = 24/36/48/72 ms. Overlay (`OVERLAY_LEN`) 0,22/0,30/0,42/0,62 s (prima 0,22/0,34/0,5/0,75). Nessun `Engine.time_scale`.
- Lampo: alpha 0,62 (L1, bianco-corallo, ~70 ms), 0,8 (L2, ~55 ms poi velo corallo), 0,85 (L3, ~60 ms), 1,0 + nero pieno (L4, ~50 ms); tutto moltiplicato per `Settings.flash` (a 0 niente lampi bianchi, restano velo e geometrie). Nessun lampo ripetuto: guardia 350 ms.
- Profili: L1 anello compatto + 10 spilli, senza fratture; L2 raggi larghi (8-22 gradi), 4 crepe lunghe + taglio diagonale; L3 velo magenta, raggi alterni rosa, anello spezzato grande, due tagli incrociati, barre magenta alte e 3 crepe; L4 nero pieno 34% del tempo, raggi bianchi sottili invertiti, 9 fratture lunghe x1,5 (corallo + magenta), tre anelli e bordi ciano.
- Test: `test_impact_frames.gd` (35 controlli: valori nominali, progressione, pausa < meta' overlay, geometria distinta). Foto `tools/impact_shot.gd`.
- NON verificato: resa su Android con la nuova build (installare e provare i 4 casi: critico, grosso colpo al boss, ult critica, ult che abbatte il boss). Se la pausa e' ancora lunga o il lampo ancora debole, i valori sono tutti in `impact_frames.gd` / `impact_overlay.gd`.

## Test
- Eseguiti (0.24.34): tutti i 76 file in `tests/unit/` in headless (parallelo): nessun errore. `test_hud_layout` (31 controlli) e `test_input_ui` richiedono uno schermo e sono passati con `xvfb-run`.
- Nuovi: `tests/unit/test_threat_preview.gd` (26 controlli: identita' senza modificatori, Guardia, bonus placca, avviso furia, catena, nessun critico del boss); 5 controlli in `test_hud_layout.gd` (ventaglio a sinistra della GUIDA e dentro lo schermo in PC e touch, annuncio lungo dentro lo schermo, stile condiviso dei comandi); 9 sulla validazione dei salvataggi (0.24.31).
- `tools/ui_audit.gd` in modalita' PC e touch: nessun problema (tasti e testi, anche PvP).
- Screenshot controllati a mano da me (xvfb, 1280x720): battaglia PC, battaglia touch (due stati), PvP 1v1 PC. NON controllati: PvP in modalita' touch, PvP 2v2 / ffa, altre risoluzioni.
- Simulazione di bilanciamento (`tools/battle_sim.gd`): riproducibile (due esecuzioni identiche con lo stesso comando). Risultati sui boss provati (distributore, tombino, cabina; IA vs boss, livelli 1-20): vittoria quasi sempre al 100%; il distributore cade in 1-2 round a tutti i livelli, tombino e cabina tra 2 e 8 round, con un 80% a livello 1 in solitaria contro la cabina (Incubo). Nessun valore e' stato modificato. Limite: l'IA gioca con kit predefiniti; il risultato dice poco sul divertimento.
- NON eseguiti: multiplayer con giocatori reali, rete pubblica, Android su dispositivo, avvio dell'exe su Windows.

## Build e pubblicazione
- `releases/ODISPEL-0.26.2-windows.zip` (exe + dll WebRTC) e `releases/ODISPEL-0.26.2.apk` (firma di debug, 1 firmatario verificato). Percorso nel repo privato: `https://github.com/Gialloo/odispel/tree/claude/battaglia-chiara/releases`
- SHA256 in `releases/SHA256SUMS.txt`. Restano la 0.26.0 (quella provata su Android) e la 0.26.1 come versioni precedenti.
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
1. All'avvio: finestra NOVITA' 0.25.0 con OK visibile.
2. Battaglia contro un boss: sotto il nome della mossa annunciata deve esserci "BERSAGLIO: ... · STIMA ~numero". Se il boss ha una catena: "+CATENA" accanto al nome.
3. Porta il boss tra 75% e 50% di vita con un compagno ferito: puo' comparire in arancio "SE SI INFURIA: LETALE PER ...". Dopo il colpo, il compagno e' davvero a rischio? L'avviso ti e' utile o ti confonde?
4. Telefono: apri il ventaglio dei comandi con la scheda GUIDA visibile (prime battaglie): "SPEZZATUTO 0%" deve leggersi tutto.
5. All'inizio di un boss con comportamento (es. PUNISCE LE CURE): l'annuncio al centro deve stare dentro lo schermo, anche su telefono.
6. PvP (1v1): barre PV bianco-ciano, ultimate rossa, comandi uguali a quelli del PvE. Prova anche 2v2 e dimmi se le carte si sovrappongono.
7. Telefono, in piena luce: leggi il pannello ALLARME (in alto al centro) e l'ordine del turno. I testi rossi si leggono senza sforzo? Dimmi anche se ti accorgi di KO e vita bassa senza guardare i colori.
8. In caso di errore: schermata, dispositivo (PC o modello del telefono), modalita' e boss.

9. (0.24.35) Durante il round: riserva, ORD/COSTO e suggerimenti spariscono? Con un colpo letale compare l'icona di pericolo e un solo avviso? Il blocco boss mostra cuore e icona equilibrio? Ti manca qualcosa che prima vedevi?

## Prossimo passo
- In base al playtest: (a) rivedere le carte PvP per 2v2/ffa e il PvP in touch, (b) decidere se mostrare un intervallo di danno (con Guardia) o la stima della catena, (c) iniziare l'audit dei test sul resto delle sinergie (scudi/cure sullo stesso bersaglio) con test che riproducono prima il problema.
- Rischio: toccare il motore deterministico; ogni modifica va coperta da test esatti.
