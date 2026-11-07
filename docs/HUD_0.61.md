# HUD di battaglia 0.61 · P0

Branch sperimentale `experiment/hud-0.61.0`, partito da `claude/v3-prologo` al commit 0fd255d.
I mockup della Fase B sono stati approvati dall'autore il 7/11/2026 («Ok va bene implementa»).
Mockup e audit stanno in `/mnt/project-files/odispel/v3/hud_audit/`.

Regola seguita: aggiungi, non togliere. Ogni parte nuova ha un interruttore in `Settings`. Spento, il gioco torna esattamente com'era prima.

## P0-A · Ritmo di squadra (`scripts/v3/ritmo_bar.gd`, `Settings.hud_ritmo`)

- È una barra a quattro tratti sopra la fila della squadra, solo nell'HUD col ritratto. Le soglie sono 25, 50 e 75 (`BattleTypes.RITMO_THRESHOLDS`).
- Non si confonde con l'ULTIMATE: è larga quanto tutta la squadra, storta e con le tacche. L'ULTIMATE resta la barretta sottile dentro ogni card.
- Ogni livello ha il suo aspetto:
  - CALMO: grigio acciaio, senza alone.
  - ACCESO: arancio con un alone leggero.
  - INCANDESCENTE: rosso fuoco con frecce di calore che scorrono.
  - APICE: oro con una riga bianca e una stella che pulsa piano, una volta al secondo e senza lampeggi.
- Al cambio di livello la barra fa un lampo breve.
- Quando la soglia è raggiunta ma manca la condizione (`ready` del motore), il tratto successivo diventa tratteggiato. Sopra compare la condizione vera presa da `Ritmo.CONDS`, ad esempio «> per INCANDESCENTE: manda il nemico in BREAK».
- La barra legge solo lo stato del motore (`Ritmo.level/ardore/st/next_conds/cond_ok`) e non decide niente.
- Prestazioni: si ridisegna solo quando i dati cambiano. Ridisegna ogni fotogramma solo a INCANDESCENTE e APICE, o durante il lampo.

## P0-B · Prossima mossa (`scripts/v3/threat_plate.gd`, `Settings.hud_minaccia`)

- Una lastra prende il posto della riga «Prossima mossa: …» sotto l'EQUILIBRIO. La riga resta, spenta, e continua a ricevere lo stesso testo.
- Un'icona dice il tipo di colpo: mirino per il colpo singolo, tre teste per «su tutti», due anelli per la catena. Con la catena il testo aggiunge «· POI <mossa>».
- Un colpo FORTE (`CombatHud.is_strong`) ha la lastra rossa piena, il bordo giallo, le strisce di pericolo e il bollino FORTE.
- Se la mossa lascia uno stato, compare un bollino chiaro con l'occhio: MARCHIO o SANGUINA, letti da `BOSS_MOVES[...].status`.
- Col nemico stordito la lastra è scura col bordo giallo e dice «STORDITO · il nemico salta il turno».
- Sui ritratti della squadra, solo per chi è davvero nel bersaglio:
  - un mirino rosso;
  - un «!» rosso e giallo se il colpo è FORTE o se lo manderebbe KO.
- I bersagli vengono solo da `telegraph.target`, dal «su tutti» della mossa, da `BattleResolver.camera_targets` e da `threat_preview.lethal`. Nessuna previsione inventata.
- Le icone sono segnaposto disegnati in codice (`ThreatPlate.draw_icon`): l'autore disegnerà le sue (P1-C).

## P0-C · Avvisi (`battle3d.gd: _notice/_stack_notices`, `Settings.hud_avvisi`)

- Gli avvisi hanno tre categorie:
  - **pericolo**: rosso col triangolo;
  - **tattica**: giallo col lampo;
  - **ambiente**: azzurro con le onde.
- Gli avvisi senza categoria restano come prima, col colore di chi li manda (ad esempio quelli verdi di Saul).
- I pericoli stanno in cima alla pila e non vengono scacciati dagli altri.
- A inizio battaglia c'erano due avvisi che dicevano la stessa cosa: la regola del BREAK e la lettura di Echo. Ora diventano uno solo con `CombatHud.merge_rule_reading`, ad esempio «IL VERBALE · para perfetto, poi punisci: x2».
- Se il testo unito non sta in una riga (più di 48 lettere), restano i due avvisi di prima: non si taglia niente.
- Nuovo pericolo immediato, detto una volta per ogni mossa annunciata: «LANCE A UN COLPO DAL KO · basta il prossimo VERBALE». Viene da `threat_preview.lethal`.
- ATTACCO A SORPRESA è un avviso di ambiente; AGGUATO e i colpi del nemico sono pericoli.
- Con un comando acceso l'avviso mostra solo il titolo e sale in alto a sinistra, sotto REC, così non copre il riquadro del comando. Quando la scelta si chiude torna intero.

## Prove

- Schermate: `tools/v3_hud_061.gd`. Fa i quattro livelli del Ritmo, FORTE con pericolo, stordito e gli avvisi compatti, sia in turno libero sia con comando acceso.
  ```
  xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_hud_061.gd -- /tmp/hud tel touch
  xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --resolution 1920x1080 -s tools/v3_hud_061.gd -- /tmp/hud pc pc
  ```
- Test di unità: `tests/unit/test_v3_hud_061.gd` (unione degli avvisi).

## Restano da fare (approvati, dopo P0)

- P1-A: Echo in tre modi.
- P1-B: ritratti, cornice del personaggio attivo, percentuale dell'ULTIMATE.
- P1-C: icone dell'autore, con la guida per Procreate.
- P2: accenti per personaggio.
- Avviso compatto «tocca per aprirlo»: oggi mostra solo il titolo e non si apre col tocco.
