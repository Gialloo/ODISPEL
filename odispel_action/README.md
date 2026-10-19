# ODISPEL Action — prototipo 3D

È il prototipo dell'action RPG 3D di ODISPEL, che prende come riferimento le sensazioni di gioco di
Kingdom Hearts 1 (PS2) ma ha un'identità propria: fantasy urbano notturno, ciano e rosso,
oggetti di città posseduti dal soprannaturale.

È un **progetto Godot separato**, contenuto in questa cartella. Il gioco a turni originale (la
cartella sopra) non viene toccato: Godot lo conferma all'avvio con *"Detected another
project.godot at res://odispel_action. The folder will be ignored."*

- Motore: Godot **4.7.2 Standard** (non .NET)
- Renderer: **Mobile**. Se il telefono non supporta Vulkan, Godot passa da solo a Compatibility.
- Fisica: Jolt

## Stato: fase B (movimento e telecamera)

| Cosa | Stato |
|---|---|
| Corsa con accelerazione e frenata rapide, velocità analogica col joystick | fatto, testato |
| Salto con altezza variabile (tieni premuto = più alto), "coyote time" e salto prenotato | fatto, testato |
| Schivata a capriola (~3,9 m, 0,34 s) con breve ricarica, solo a terra | fatto, testato |
| Telecamera in terza persona con braccio a molla (non entra nei muri) e riallineamento leggero | fatto, testato |
| Comandi touch: joystick mobile, trascinamento telecamera, SALTO, SCHIVA, più dita insieme | fatto, testato in automatico, **da provare su un telefono vero** |
| Tastiera + mouse, controller | fatto (associazioni nel codice, modificabili da Mappa input) |
| Arena di prova: parcheggio notturno, auto, banchina, rampa, piloni, Distributore spento | fatto |
| Combattimento, aggancio del bersaglio, nemici | **non ancora**: fasi C e D |

Il personaggio è una capsula provvisoria, non il modello finale. Il visore indica dove guarda e
la sciarpa rossa mostra la schiena. Non ci sono ancora animazioni vere: la schivata è una
capriola dell'intera capsula, e salto e atterraggio sono resi con un leggero schiacciamento.

## Comandi

**PC:** WASD o frecce per muoversi, mouse per la telecamera (il primo clic cattura il mouse, Esc
lo libera), Spazio per saltare, Shift per schivare. F1 mostra i comandi touch, che puoi provare
col mouse; F3 nasconde le informazioni.

**Controller:** levetta sinistra per muoversi, levetta destra per la telecamera, A per saltare,
B per schivare.

**Telefono:** con il pollice sinistro, in qualsiasi punto della metà sinistra, comandi il joystick.
Trascinando con il pollice destro sulla metà destra ruoti la telecamera. In basso a destra ci
sono i pulsanti SALTO e SCHIVA. L'angolo in basso a destra resta libero per il futuro pulsante
ATTACCO.

## Struttura

```
core/       livelli di collisione, associazioni dei tasti
player/     player_intent.gd  (cosa vuole fare il giocatore: solo dati)
            player_motor.gd   (regole di corsa/salto/schivata: solo numeri, testabile)
            player.gd/.tscn   (nodo fisico + corpo provvisorio)
input/      local_input_source.gd (tastiera/mouse/controller/touch -> intento)
            touch_controls.gd     (comandi touch a più dita)
camera/     follow_camera.gd/.tscn
arena/      test_arena.gd     (arena costruita col codice)
ui/         action_theme.gd (palette di ODISPEL), debug_hud.gd
scenes/     main.tscn         (collega tutto)
tests/      test_motor.gd, test_touch.gd, test_scene.gd
tools/      screenshot.gd
```

La separazione serve alla futura cooperativa. Il personaggio non legge mai la tastiera o il
touch: riceve un `PlayerIntent`. Un giocatore in rete manderà il suo intento all'host, e le
regole di movimento (`PlayerMotor`) sono semplici calcoli che anche l'host può eseguire.

## Test

```
GODOT=/percorso/Godot_v4.7.2-stable_linux.x86_64 ./run_tests.sh
```

- `test_motor.gd`: le regole di movimento senza fisica (26 controlli)
- `test_touch.gd`: zone, joystick, pulsanti, più dita insieme e disposizione su 4 formati di
  schermo (40 controlli)
- `test_scene.gd`: la scena vera con la fisica. Corsa, salto, schivata, salto sul tetto di
  un'auto, salita della rampa, confini, telecamera contro un pilone (13 controlli). Con una
  finestra vera fa anche 3 prove con tocchi reali, che passano da tutto il sistema di input di
  Godot. In `--headless` queste 3 prove risultano "SALTATO". Su Linux, senza schermo:
  `xvfb-run -s "-screen 0 1280x720x24" godot --path . --rendering-method gl_compatibility -s res://tests/test_scene.gd`

I test automatici verificano i numeri, ma **non dicono se il controllo è piacevole**: questo si
giudica solo provandolo con le mani.

## Provarlo su Android

1. Apri questa cartella (`odispel_action`) con Godot 4.7.2, non la cartella principale.
2. Segui la guida ufficiale per configurare l'export Android (template di export, JDK, Android
   SDK): https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
3. Progetto > Esporta > Aggiungi > Android, poi attiva il debug USB sul telefono e usa il
   pulsante di avvio remoto (icona Android in alto a destra) per installarlo.

Per l'iPhone servono un Mac con Xcode e un account sviluppatore Apple.

## Cosa annotare durante la prova sul telefono

- Gli FPS mostrati in alto a sinistra.
- Se il joystick risponde subito e se il personaggio va dove ti aspetti.
- Se i pulsanti sono comodi, troppo piccoli o troppo vicini.
- Se la telecamera gira troppo veloce o troppo piano trascinando il dito.
- Se capita di premere qualcosa per sbaglio.
