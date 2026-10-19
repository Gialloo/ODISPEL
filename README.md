# OFFICIAL DEMO ODISPEL · V3, atto 1 (standalone)

Progetto Godot 4.7.2 separato dalla V2 (`Gialloo/ODISPEL`), renderer **gl_compatibility**, landscape 1280×720.
Commissione: `docs/HANDOFF_PROLOGO_3D.md`. Storia e piano del seguito: `docs/STORIA.md`. **Stile visivo: `docs/STILE_VISIVO.md`** — conta l'aggiornamento in cima: urbano di oggi, niente look medievale. Stato attuale: **0.33.0 = atto 1 rivisto con la bibbia di lavoro** (climax al loro posto, finale con Echo ridotta a nucleo, ripresa a metà area). Regole: `BIBBIA_DI_LAVORO.md` nella cartella del progetto.

## Struttura
- `scripts/engine/` — motore di combattimento **copiato** dalla V2 (BattleState, SeqRound, BattleResolver e dipendenze).
  Modifiche rispetto alla V2: niente Spedizione/Titoli in `compute_stats`, `FRONT_SIZE = 4`, cast V3 in `BattleContent.V3_CAST` (provvisorio).
- `scripts/v3/` — gioco: `main.gd` (una schermata alla volta), `menu.gd`, `area.gd` (esplorazione di un'area qualsiasi), `scene_screen.gd` / `card_screen.gd` / `ending_screen.gd` (scene, cartelli, fine),
  `story.gd` (passi dell'atto e salvataggio), `banter.gd` (chiacchiere), `dialog_box.gd` (dialoghi stile Persona), `layout_builder.gd` (le aree), `battle3d.gd` (combattimento 3D),
  `character_visual.gd` / `vending_visual.gd` (segnaposto 3D, interfaccia sostituibile coi glTF), `toon.gd` + `mesh_batch.gd` + `city_builder.gd` (grafica).
- `data/` — `atto1.json` (capitoli, passi, aree, nemici, boss), `dialoghi_atto1.json` (testi, generati da `tools/gen_dialoghi.py`: si corregge lo script e si rigenera) + `dialoghi.json`, `cast_visual.gd` (colori e proporzioni dei segnaposto).
- `tests/unit/` — `test_v3_engine.gd` + test del motore portati dalla V2.  `tools/v3_atto1.gd` — gioca da solo l'atto 1 (battaglie in AUTO) e fa gli screenshot.

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
godot --headless --path . -s tests/unit/test_v3_dialoghi.gd
xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_atto1.gd -- /tmp/atto1 [tutte] [capitolo=N]
xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_atto1.gd -- /tmp/atto1_t touch
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
