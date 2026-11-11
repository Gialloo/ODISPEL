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
