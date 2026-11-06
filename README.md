# OFFICIAL DEMO ODISPEL · V3, atto 1 (standalone)

Progetto Godot 4.7.2 separato dalla V2 (`Gialloo/ODISPEL`), renderer **gl_compatibility**, landscape 1280×720.
Commissione: `docs/HANDOFF_PROLOGO_3D.md`. Storia e piano del seguito: `docs/STORIA.md`. **Stile visivo: `docs/STILE_VISIVO.md`** — conta l'aggiornamento in cima: urbano di oggi, niente look medievale. Stato di riferimento del branch di release: **0.58.0**. L'audit e gli interventi sperimentali successivi sono registrati nel branch `experiment/0.58.0-audit-ottimizzazione` e nel documento `docs/AUDIT_OTTIMIZZAZIONE_0.58.0.md`; non considerarli parte della release finché non vengono integrati e testati. Regole: `BIBBIA_DI_LAVORO.md` nella cartella del progetto.

## Struttura
- `scripts/engine/` — motore di combattimento **copiato** dalla V2 (BattleState, SeqRound, BattleResolver e dipendenze).
  Modifiche rispetto alla V2: niente Spedizione/Titoli in `compute_stats`, `FRONT_SIZE = 4`, cast V3 in `BattleContent.V3_CAST` (provvisorio).
- `scripts/v3/` — gioco: `main.gd` (una schermata alla volta), `menu.gd`, `area.gd` (esplorazione di un'area qualsiasi), `scene_screen.gd` / `card_screen.gd` / `ending_screen.gd` (scene, cartelli, fine),
  `story.gd` (passi dell'atto e salvataggio), `banter.gd` (chiacchiere), `dialog_box.gd` (dialoghi stile Persona), `layout_builder.gd` (le aree), `battle3d.gd` (combattimento 3D),
  `character_visual.gd` / `vending_visual.gd` (segnaposto 3D, interfaccia sostituibile coi glTF), `toon.gd` + `mesh_batch.gd` + `city_builder.gd` (grafica),
  `light_fx.gd` (la magia disegnata con la luce), `sky_dome.gd` (la cupola nel cielo), `cam_hud.gd` (il mirino di Echo): vedi `docs/STILE_VISIVO.md`, ultima sezione.
  Suono: `sfx.gd` (effetti e musica a strati che cresce col COMBO), file in `assets/audio/` generati da `tools/gen_suoni.py` (si corregge lo script e si rigenera; `tests/unit/test_v3_suoni.gd`, registrazione con l'audio: `tools/v3_suono_battaglia.gd` col `--write-movie`).
  Dalla 0.35: `progress.gd` (livelli, esperienza, sblocchi, sinergie, mosse rubate da Saul; si salva in "squadra"), `squad_menu.gd` (menu SQUADRA della pausa), `react_game.gd` (i quattro minigiochi delle reazioni).
- `data/` — `atto1.json` (capitoli, passi, aree, nemici, boss), `dialoghi_atto1.json` (testi, generati da `tools/gen_dialoghi.py`: si corregge lo script e si rigenera) + `dialoghi.json`, `cast_visual.gd` (colori e proporzioni dei segnaposto).
- `tests/unit/` — `test_v3_engine.gd` + test del motore portati dalla V2.  `tools/v3_atto1.gd` — gioca da solo l'atto 1 (battaglie in AUTO) e fa gli screenshot.
  `test_v3_progressione.gd` (livelli, kit di Saul e Nox, esiti dei minigiochi). `tools/v3_novita.gd` — schermate delle novità 0.35 senza giocare. `tools/v3_stress_battaglia.gd` — boss in AUTO con i tempi dei fotogrammi (sotto xvfb i numeri valgono solo come confronto).

## Rendering (per cercare eventuali crash)
Shader spatial **unshaded** fatti a mano (toon a due toni e nebbia dentro lo shader), contorni a guscio rovesciato come
seconda superficie della mesh (non `next_pass`), bagliori trasparenti additivi, sfondo a colore pieno (niente cielo),
nessuna luce, nessuna ombra in tempo reale, nessun Label3D/Sprite3D (tutto il testo è UI 2D), MSAA spento su mobile, 60 fps max.
`Breadcrumb` scrive su disco il punto raggiunto: dopo un crash il menu dice dove si era fermato.

## Comandi
```
export PATH=/root/bin:$PATH
godot --headless --path . --import
godot --headless --path . -s tests/unit/test_v3_engine.gd
godot --headless --path . -s tests/unit/test_v3_touch_controls.gd  # stick, camera e multitouch
godot --headless --path . -s tests/unit/test_v3_mesh_batch.gd             # cache delle mesh piatte riutilizzate
godot --headless --path . -s tests/unit/test_v3_city_builder.gd          # cache dei colori della scenografia
godot --headless --path . -s tests/unit/test_v3_shader_warmup.gd        # geometria condivisa per il warm-up shader
godot --headless --path . -s tests/unit/test_v3_integrita_salvataggio.gd  # validazione area, checkpoint finale e recupero backup
godot --headless --path . -s tests/unit/test_v3_dialoghi.gd
godot --headless --path . -s tests/unit/test_v3_timeline.gd       # Timeline del combattimento (Fase 1): ordine per VEL, round, pareggi
godot --headless --path . -s tests/unit/test_v3_slancio.gd        # SLANCIO per personaggio (Fase 2): uno a round per eroe, debolezze, KO, SLANCIO protetto
godot --headless --path . -s tests/unit/test_v3_ritmo.gd          # RITMO di squadra (R1-R2-R4): Ardore, livelli, condizioni, perdite, salvataggio con la parata, bonus dei livelli e di APICE, tecnica APICE per personaggio
godot --headless --path . -s tests/unit/test_v3_break.gd           # BREAK (Fase 3): regole dei boss, finestra di azioni alleate, recupero, pressione latente, comuni/elite/boss
godot --headless --path . -s tests/unit/test_v3_resource_telemetry.gd  # telemetria delle risorse
godot --headless --path . -s tools/v3_bilancio.gd -- vel           # VEL e azioni per livello; senza "vel": bilancio dell'atto (con "giro": senza Timeline; con "nostab": BREAK del 0.54)
xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_atto1.gd -- /tmp/atto1 [tutte] [capitolo=N]
xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_atto1.gd -- /tmp/atto1_t touch
xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_vetrina.gd -- /tmp/vetrina      # personaggi, nemici ed effetti senza giocare
```

## Rilascio
1. Versione in `scripts/v3/game_config.gd`, `project.godot`, `export_presets.cfg` (code = X.YY.Z → 2900 per 0.29.0), `docs/CHANGELOG.md`.
2. `godot --headless --path . --export-release "Android" build/raw.apk` (preset non firmato; serve un SDK anche finto con `platform-tools/adb` e `build-tools/*/apksigner`).
3. `python3 tools/sign_apk.py build/raw.apk "releases/OFFICIAL DEMO ODISPEL mobile v.X.Y.Z.apk" /mnt/project-files/odispel/chiavi/odispel_v3_release.pem` (firma v2; la chiave NON va nel repo, che è pubblico: sta nella cartella del progetto,
   con una chiave diversa l'aggiornamento non si installa sopra, bisogna disinstallare).
4. `godot --headless --path . --export-release "Windows Desktop" build/win/OFFICIAL_DEMO_ODISPEL.exe` e zip in `releases/OFFICIAL DEMO ODISPEL pc vX.Y.Z.zip`.
5. `releases/SHA256SUMS.txt`, commit, push sul branch `claude/v3-prologo` del repo `Gialloo/ODISPEL` (branch orfano, niente storia in comune con la V2):
   il workflow `itch.yml` verifica la firma con apksigner e carica sulla pagina della V2 `boomeranza/odispel`, canali `android-v3` e `windows-v3`.

Pacchetto Android: `com.gialloo.odispel.v3` (convive con la V2 sul telefono).
