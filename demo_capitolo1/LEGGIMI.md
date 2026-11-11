# ODISPEL · Capitolo 1 · prova di esplorazione (stile Persona)

Progetto Godot 4.7.2 separato dalla V3 (si apre da questa cartella). Niente combattimenti, per scelta dell'autore (11/11/2026): prima si sistemano esplorazione, città, dialoghi e personaggi, poi si aggiungono le meccaniche.

## Cosa c'è
- **Vicolo, Lance da solo**: ricognizione autonoma (canone di novembre, punto 7). Percezioni passive: Lance dice ad alta voce cosa nota, in un balloon; il punto lo trova il giocatore e preme ESAMINA.
- **Incontro con Rio**: sagoma in controluce, l'equivoco si capisce guardando. Le due possibilità ancora aperte nel canone (punto 10.1) sono una scelta del giocatore: intimargli di fermarsi o sorprenderlo.
- **Quartiere col gruppo al completo** (prova): CAMBIA (o Q) cambia chi guida; ognuno nota cose sue (Saul soldi, Nox magia, Rio tracce biologiche, Lance armi e attrezzatura). Due punti comuni con commenti diversi per ogni guida. Chiacchiere del gruppo nei balloon mentre si cammina.
- Interfaccia nostra «alla Persona»: riquadro storto, ritratti grandi che entrano di lato, cartellino del nome inclinato, scelte a lamelle, cartelli di data e luogo, barre da film.

## Dove si cambia cosa
- Tutti i testi, le scene, i punti e le chiacchiere: `data/capitolo1.json` (si modifica senza toccare il codice).
- Città e modelli segnaposto: `scripts/mondo.gd`. Interfaccia: `scripts/persona_ui.gd`. Flusso: `scripts/main.gd`.

## Comandi
```
godot --headless --path . --import
xvfb-run -a godot --path . --resolution 1280x720 -s tools/prova.gd -- prova /tmp/prova scelta=0   # gioca da sola e salva le schermate
```
Controlli PC: WASD/frecce, E/Invio/Spazio per esaminare e far avanzare i dialoghi, Q per cambiare guida.
