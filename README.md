# OVERLOAD · laboratorio di combattimento

Progetto separato da ODISPEL (branch orfano `OVERLOAD`). Action roguelite in terza persona: un'arena,
un protagonista, arma che cambia forma da sola (BLADE, IMPACT, VECTOR), poi manipolazione, ambiente,
indicatore OVERLOAD e ondate infinite. Il gameplay viene prima di tutto.

Godot 4.7.2, renderer `gl_compatibility`, telefono prima di tutto (la versione PC arriva dopo).

## Struttura
- `scripts/core/` — `fx.gd` (hitstop, rallentamenti, scosse, suoni, scintille, contatori), `pad.gd` (ingresso unico: touch, tastiera, pad, bot)
- `scripts/player/` — `player.gd` (movimento, salto, schivata, combo, aiuto alla mira), `moves.gd` (tabella delle mosse), `weapon_view.gd`, `cam_rig.gd`
- `scripts/enemies/enemy.gd` — Scout (Fase 1)
- `scripts/world/arena.gd` — l'arena
- `scripts/ui/` — `hud.gd` (HUD minimo + pannello LAB), `touch.gd`
- `tests/bot.gd` — gioca da solo, controlla che tutte le mosse funzionino, misura gli fps, salva schermate

## Comandi
```
export PATH=/root/bin:$PATH
godot --headless --path . --import
xvfb-run -a godot --path . --rendering-driver opengl3 -s tests/bot.gd -- 60 /tmp/schermate [--touch]
godot --headless --path . --export-release "Android" build/raw.apk
python3 tools/sign_apk.py build/raw.apk "releases/OVERLOAD mobile vX.Y.Z.apk" /mnt/project-files/odispel/chiavi/odispel_v3_release.pem
```
Un push che cambia `releases/` pubblica su itch (`boomeranza/odispel`, canale `android-overload`).

## Comandi di gioco
Telefono: stick a sinistra, trascina a destra per guardare, ATTACCO (tieni = pesante), SCHIVA, SALTO, LOCK, LAB.
PC: WASD, mouse, clic (tieni = pesante), SPAZIO, SHIFT o tasto destro, Q, TAB.

## Ambiente (Fase 3)
- Casse di legno (fascia azzurra): bruciano; lanciate accese incendiano i nemici.
- Blocchi di metallo (fascia viola) e bobine (sfera ciano): conducono la scossa.
- Bidoni rossi: esplodono con fuoco, scossa o un urto forte.
- Pozze d'acqua: la scossa prende chiunque ci stia dentro; il fuoco si spegne.
- Muretti marroni: si sfondano con colpi IMPACT, oggetti e nemici lanciati.
- Il potere su una bobina la fa scaricare a distanza.

## OVERLOAD (Fase 4)
Barra sottile sotto la vita. Sale con azioni diverse concatenate (forme dell'arma, potere, ambiente,
reazioni a catena, schivate perfette); la stessa azione ripetuta rende poco; cala se ti fermi o vieni colpito.
Livello 1 = potere stadio 2 (pesanti), livello 2 = stadio 3 (due bersagli), pieno = OVERLOAD per 6 s
con ricariche del potere rapidissime. Valori in `scripts/core/overload.gd` e nel LAB.

## Run (Fase 5)
Ondate infinite: Scout (rosso, affondo), Conduit (blu, da lontano lancia sfere elettriche, spesso su pozze,
bidoni e bobine vicino a te: SPINGI le rimanda indietro), Brute (arancione, non si ferma ai colpi finché non
perde l'equilibrio, schianto ad area, si sposta col potere dallo stadio 2). Dopo le ondate 1, 3, 5... scegli
uno di tre potenziamenti (dati in `data/upgrades.json`, tasti 1-2-3). Tra un'ondata e l'altra recuperi un po'
di vita. Sconfitto: RICOMINCIA (o Invio) riparte subito.

## Mosse 0.7
- Triplo salto: il secondo e il terzo cambiano direzione, il terzo è più alto con piroetta. Si salta anche per interrompere un attacco.
- BLADE: affondo in corsa (attacca mentre corri), piroetta (stick di lato durante la combo).
- IMPACT: martellata a terra (stick di lato al posto del finale), martello in corsa (tieni premuto mentre corri).
- VECTOR: catena in aria verso un nemico lontano (attacca in salto), vortice che risucchia (schiva, attacca, attacca).
- Ondate più brevi e frequenti; ondate a tema SCIAME, CORAZZATI, TEMPESTA.
- Prova delle mosse: `godot --path . -s tests/moves_07.gd`

## 0.8
- PARRY: un colpo BLADE che parte poco prima dell'impatto (0,2 s) ferma l'attacco: lo Scout e il Brute si prendono il loro colpo e perdono l'equilibrio, la sfera del Conduit torna a chi l'ha lanciata. Con una sfera vicina l'attacco diventa sempre BLADE. Prova: `tests/parry_08.gd`.
- Movimento: scatto dopo 0,6 s di corsa piena, accelerazione e frenata più rapide, più controllo in aria.
- Nemici: rotolano quando volano, rimbalzano a terra se cadono forte, i colpi forti li mandano contro muri e altri nemici, non ti entrano più dentro.

## 0.9
- Ondate che non si bloccano più (nemici fuori mappa recuperati, conteggio reale) e cerchio centrale: 5 s dentro senza nemici vicini fanno partire l'ondata.
- Punteggio: abbattimenti per tipo + combo; record salvato in `user://overload.cfg`.
- Menu principale (Nuova partita, Opzioni) e schermata finale con Ricomincia / Menu.
- Telecamera: inseguimento più stretto, scorrimento liscio, rientro automatico alle spalle, LOCK più grande, doppio tocco = lock, colpo di dito in lock = cambio bersaglio.
- Prova: `tests/waves_09.gd`.

## 0.10
- 24 potenziamenti (nuova famiglia Corpo), schermata di scelta che si chiude sempre (`tests/choice_10.gd`).
- IMPACT +20% di danno; passaggi tra i colpi più rapidi, coda dei tasti più lunga, ripartenza in corsa a fine colpo.
- Versione PC: preset "Windows", `releases/OVERLOAD pc vX.Y.Z.zip` -> canale itch `windows-overload`.

## 0.11
- Look da fumetto al tramonto: ombre a blocchi e contorni neri automatici (`FX._style_mesh`, si spegne con `FX.style_on`), cielo e nebbia caldi, città di sfondo in MultiMesh (`arena._skyline`).

## 0.12
- Effetti da anime: impact frame, linee di velocità, grana e bordi scuri (`scripts/ui/anime_fx.gd`, `FX.impact_frame`, `FX.speed_lines`), spegnibili dalle Opzioni. Pali e fili della luce sopra la città.

## 0.13
- Animazioni dei colpi a pose (`weapon_view.play`): corpo che si torce/piega/accovaccia, fendenti diagonali, martellata pesante, catena VECTOR che si allunga davvero.

## 0.14
- Impact frame solo su counter, colpo dall'alto potente e colpo finale della combo (`player.IMPACT_FRAME_MOVES`). Città spostata lontano (palazzine a 140-175 m, grattacieli anni 2000 a 230-360 m nella foschia), linee elettriche in diagonale verso l'orizzonte. Prestazioni: niente contorni né emissione sulla città, riflessi spenti, pellicola a texture.

## 0.15
- Boss COLOSSO ogni quinta ondata (`enemy.boss`, tema "COLOSSO" in `run._next_wave`): Bruto 1,6 volte più grande, vita ×5,5, botta più larga e onda d'urto a tre anelli da saltare; barra in alto nella HUD; abbatterlo vale 1500 punti e mezza vita. Prova: `tests/boss_15.gd`.

## 0.16
Barre di vita dei nemici disegnate dalla HUD (`scripts/ui/enemy_bars.gd`): bordo nero, rosso = vita, bianco = vita appena tolta
(resta finché i colpi continuano), targhetta "LV n". Prova: `godot --path . -s tests/bars_16.gd -- /tmp/schermate`.

## 0.17
Secondo boss, il TRALICCIO (ogni decima ondata; il COLOSSO resta sulla 5, 15, 25...): sfere a ventaglio da rimandare, scariche a terra annunciate, impulso se gli stai addosso. Prove: `tests/boss_17.gd`, `tests/traliccio_17.gd`.

## 0.18
Numeri dei danni (bianchi, oro per i colpi forti) e "N HITS" sopra la barra. Prova: `tests/pops_18.gd`.
