# ODISPEL · Capitolo 1 · prova di esplorazione (stile Persona)

Progetto Godot 4.7.2 separato dalla V3 (si apre da questa cartella). Fino alla 0.3 niente combattimenti, per scelta dell'autore (11/11/2026): prima esplorazione, città, dialoghi e personaggi. Dalla 0.4 (13/11/2026) c'è il combat scelto dall'autore dopo le prove grezze.

## Cosa c'è (versione 0.2, 11/11/2026)
- **Vicolo, Lance da solo** (canone di novembre, punto 7): via lunga con un cortile laterale. Quattro cose da notare (bossoli, zaino, pozzanghera, distributore). Lance le dice ad alta voce in un balloon; il giocatore trova il punto e preme ESAMINA.
- **Incontro con Rio**: Rio porta la maschera e non parla mai. Dice solo «...», «Sniff», «Trending», «Hype», «Unfollow» e «Follow!». Le due possibilità aperte nel canone (punto 10.1) restano una scelta del giocatore: intimargli di fermarsi o sorprenderlo.
- **Lavanderia a gettoni** (PROPOSTA, non canone): il rifugio dopo il boato. Si parla con Nox, Saul e Rio uno alla volta (PARLA), poi si esce dalla porta.
- **Il quartiere, dopo** (PROPOSTA di ponte verso il Capitolo 1, non canone): piazza chiusa da muri di carne. CAMBIA (o Q) cambia chi guida. Ognuno nota cose sue (Saul soldi, Nox magia, Rio tracce biologiche, Lance armi e attrezzatura). Il manifesto ha una scena diversa per ogni guida. Il varco nel muro chiude la demo.
- **Movimento e camera**: accelerazione e frenata, corsa e passo (stick poco inclinato o Shift), braccia e gambe che oscillano. Camera alle spalle che si gira trascinando la metà destra dello schermo (Z/C sul PC). Contro un muro la camera sale e guarda dall'alto. I compagni che coprirebbero la guida si nascondono.
- **Stile grafico (0.3, 12/11/2026)**: preso dalle tavole dell'autore, «stile Persona 5». Rosso, nero e bianco più il colore di ogni personaggio; retino da fumetto; cornici bianche a fulmine; nomi a lettere ritagliate; ritratti con contorno da adesivo. Banda dei dialoghi storta e nera con la striscia e l'ombra del colore di chi parla, testo condensato e grande. Vignette a tutto schermo a due colori quando entra un personaggio (Lance, Rio, Nox, Saul) e il trittico del gruppo all'arrivo nel quartiere. Cartelli rossi, scelte a lamelle, titolo a lettere ritagliate.
- Pezzi grafici: `scripts/fumetto.gd` e `shaders/` (retino, ritratto). Nei dati si usano le regie `vignetta` e `trittico`. `tools/vetrina_ui.gd` fotografa tutti i pezzi dell'interfaccia.
- Font nuovi (licenza OFL, in `assets/fonts/`): Anton per i dialoghi, Saira Stencil One per le lettere ritagliate.

## Combattimento (0.4, 13/11/2026)
- Al **varco** del quartiere un'anomalia si stacca dal muro e parte lo SCONTRO (regia `scontro` in `data/capitolo1.json`; il punto della storia è una PROPOSTA). Si va avanti solo vincendo; se perdi, RIPROVA.
- È il combat della prova grezza 3 (repo, `scripts/prova_grezza/`): vista di lato, uno in campo e la squadra (Lance, Nox, Rio, Saul) a cambio rapido coi ritratti in basso, STAFFETTA e CAMBIO IN DIFESA, colpo caricato, sospensione e schianto, combo (montante, sfondamento, falciata), CONTRO, CROLLO e BLACKOUT, PIANO.
- File: `scripts/scontro/` (motore `pg_engine.gd`, scena `scontro.gd`, `ui_pop.gd` e `sfx.gd` presi dalla V3), suoni in `assets/audio/`. Schermate: `tools/vetrina_scontro.gd`.
- I corpi nello scontro sono ancora forme semplici, come i modelli segnaposto della demo.

## Dentro il varco: il nido (0.5, 13/11/2026) · PROPOSTA
- Dopo lo scontro al varco si entra nel **nido** (zona `nido` in `scripts/mondo.gd`, `_costruisci_nido`): corridoio di carne, caverna con colonne e sacche viola, vene ciano che guidano alla camera del cuore che pulsa. Tutto il luogo è una PROPOSTA, da approvare.
- Sei punti, uno per personaggio più due di gruppo: radio di servizio (Lance la spegne), vene (Nox), bozzolo (tutti), orologio d'oro (Saul, gioco di mano), reperto (Rio, scena privata: nessuno commenta; segue il canone §10.3, i dettagli sono proposta), cuore (tutti).
- Il **Cuore del Nido** è il boss: regia `scontro` con `"forza": 1.6` (più vita, più grande, viola). Dopo la vittoria il finale del capitolo; alcune righe compaiono solo se hai visto il reperto (campo `"se"` nelle righe di `data/capitolo1.json`).
- Le chiacchiere a camminare ora valgono in ogni zona che le ha nei dati.

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
