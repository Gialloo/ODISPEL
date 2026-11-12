# ODISPEL · Capitolo 1 · prova di esplorazione (stile Persona)

Progetto Godot 4.7.2 separato dalla V3 (si apre da questa cartella). Niente combattimenti, per scelta dell'autore (11/11/2026): prima si sistemano esplorazione, città, dialoghi e personaggi, poi si aggiungono le meccaniche.

## Cosa c'è (versione 0.2, 11/11/2026)
- **Vicolo, Lance da solo** (canone di novembre, punto 7): via lunga con un cortile laterale. Quattro cose da notare (bossoli, zaino, pozzanghera, distributore). Lance le dice ad alta voce in un balloon; il giocatore trova il punto e preme ESAMINA.
- **Incontro con Rio**: Rio porta la maschera e non parla mai. Dice solo «...», «Sniff», «Trending», «Hype», «Unfollow» e «Follow!». Le due possibilità aperte nel canone (punto 10.1) restano una scelta del giocatore: intimargli di fermarsi o sorprenderlo.
- **Lavanderia a gettoni** (PROPOSTA, non canone): il rifugio dopo il boato. Si parla con Nox, Saul e Rio uno alla volta (PARLA), poi si esce dalla porta.
- **Il quartiere, dopo** (PROPOSTA di ponte verso il Capitolo 1, non canone): piazza chiusa da muri di carne. CAMBIA (o Q) cambia chi guida. Ognuno nota cose sue (Saul soldi, Nox magia, Rio tracce biologiche, Lance armi e attrezzatura). Il manifesto ha una scena diversa per ogni guida. Il varco nel muro chiude la demo.
- **Movimento e camera**: accelerazione e frenata, corsa e passo (stick poco inclinato o Shift), braccia e gambe che oscillano. Camera alle spalle che si gira trascinando la metà destra dello schermo (Z/C sul PC). Contro un muro la camera sale e guarda dall'alto. I compagni che coprirebbero la guida si nascondono.
- Interfaccia nostra «alla Persona»: riquadro storto, ritratti grandi che entrano di lato, cartellino del nome inclinato, scelte a lamelle, cartelli di data e luogo, barre da film solo nelle scene.

## Dove si cambia cosa
- Tutti i testi, le scene, i punti e le chiacchiere: `data/capitolo1.json` (si modifica senza toccare il codice).
- Città e modelli segnaposto: `scripts/mondo.gd`. Interfaccia: `scripts/persona_ui.gd`. Flusso: `scripts/main.gd`.

## Comandi
```
godot --headless --path . --import
xvfb-run -a godot --path . --resolution 1280x720 -s tools/prova.gd -- prova /tmp/prova scelta=0   # gioca da sola e salva le schermate
```
Controlli PC: WASD/frecce, Shift per camminare piano, Z/C o trascinare col mouse per girare la camera, E/Invio/Spazio per esaminare e far avanzare i dialoghi, Q per cambiare guida.

`tools/inquadra.gd` fotografa la camera in punti fissi, senza giocare.
