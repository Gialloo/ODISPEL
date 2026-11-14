# ODISPEL · Capitolo 1 · prova di esplorazione (stile Persona)

Progetto Godot 4.7.2 separato dalla V3 (si apre da questa cartella). Fino alla 0.3 niente combattimenti, per scelta dell'autore (11/11/2026): prima esplorazione, città, dialoghi e personaggi. Dalla 0.4 (13/11/2026) c'è il combat scelto dall'autore dopo le prove grezze.

## Cosa c'è (versione 0.2, 11/11/2026)
- **Vicolo, Lance da solo** (canone di novembre, punto 7): via lunga con un cortile laterale. Quattro cose da notare (bossoli, zaino, pozzanghera, distributore). Lance le dice ad alta voce in un balloon; il giocatore trova il punto e preme ESAMINA.
- **Incontro con Rio**: Rio porta la maschera e non parla mai. Dice solo «...», «Sniff», «Trending», «Hype», «Unfollow» e «Follow!». Le due possibilità aperte nel canone (punto 10.1) restano una scelta del giocatore: intimargli di fermarsi o sorprenderlo.
- **Lavanderia a gettoni** (PROPOSTA, approvato dall'autore il 14/11/2026): il rifugio dopo il boato. Si parla con Nox, Saul e Rio uno alla volta (PARLA), poi si esce dalla porta.
- **Il quartiere, dopo** (PROPOSTA di ponte verso il Capitolo 1, approvato dall'autore il 14/11/2026): piazza chiusa da muri di carne. CAMBIA (o Q) cambia chi guida. Ognuno nota cose sue (Saul soldi, Nox magia, Rio tracce biologiche, Lance armi e attrezzatura). Il manifesto ha una scena diversa per ogni guida. Il varco nel muro chiude la demo.
- **Movimento e camera**: accelerazione e frenata, corsa e passo (stick poco inclinato o Shift), braccia e gambe che oscillano. Camera alle spalle che si gira trascinando la metà destra dello schermo (Z/C sul PC). Contro un muro la camera sale e guarda dall'alto. I compagni che coprirebbero la guida si nascondono.
- **Stile grafico (0.3, 12/11/2026)**: preso dalle tavole dell'autore, «stile Persona 5». Rosso, nero e bianco più il colore di ogni personaggio; retino da fumetto; cornici bianche a fulmine; nomi a lettere ritagliate; ritratti con contorno da adesivo. Banda dei dialoghi storta e nera con la striscia e l'ombra del colore di chi parla, testo condensato e grande. Vignette a tutto schermo a due colori quando entra un personaggio (Lance, Rio, Nox, Saul) e il trittico del gruppo all'arrivo nel quartiere. Cartelli rossi, scelte a lamelle, titolo a lettere ritagliate.
- Pezzi grafici: `scripts/fumetto.gd` e `shaders/` (retino, ritratto). Nei dati si usano le regie `vignetta` e `trittico`. `tools/vetrina_ui.gd` fotografa tutti i pezzi dell'interfaccia.
- Font nuovi (licenza OFL, in `assets/fonts/`): Anton per i dialoghi, Saira Stencil One per le lettere ritagliate.

## Combattimento (0.4, 13/11/2026)
- Al **varco** del quartiere un'anomalia si stacca dal muro e parte lo SCONTRO (regia `scontro` in `data/capitolo1.json`; il punto della storia è una PROPOSTA, approvato dall'autore il 14/11/2026). Si va avanti solo vincendo; se perdi, RIPROVA.
- È il combat della prova grezza 3 (repo, `scripts/prova_grezza/`): vista di lato, uno in campo e la squadra (Lance, Nox, Rio, Saul) a cambio rapido coi ritratti in basso, STAFFETTA e CAMBIO IN DIFESA, colpo caricato, sospensione e schianto, combo (montante, sfondamento, falciata), CONTRO, CROLLO e BLACKOUT, PIANO.
- File: `scripts/scontro/` (motore `pg_engine.gd`, scena `scontro.gd`, `ui_pop.gd` e `sfx.gd` presi dalla V3), suoni in `assets/audio/`. Schermate: `tools/vetrina_scontro.gd`.
- I corpi nello scontro sono ancora forme semplici, come i modelli segnaposto della demo.

## Dentro il varco: il nido (0.5, 13/11/2026) · PROPOSTA approvato dall'autore il 14/11/2026
- Dopo lo scontro al varco si entra nel **nido** (zona `nido` in `scripts/mondo.gd`, `_costruisci_nido`): corridoio di carne, caverna con colonne e sacche viola, vene ciano che guidano alla camera del cuore che pulsa. Tutto il luogo era una PROPOSTA: approvato dall'autore il 14/11/2026.
- Sei punti, uno per personaggio più due di gruppo: radio di servizio (Lance la spegne), vene (Nox), bozzolo (tutti), orologio d'oro (Saul, gioco di mano), reperto (Rio, scena privata: nessuno commenta; segue il canone §10.3, i dettagli erano proposta, approvato dall'autore il 14/11/2026), cuore (tutti).
- Il **Cuore del Nido** è il boss: regia `scontro` con `"forza": 1.6` (più vita, più grande, viola). Dopo la vittoria il finale del capitolo; alcune righe compaiono solo se hai visto il reperto (campo `"se"` nelle righe di `data/capitolo1.json`).
- Le chiacchiere a camminare ora valgono in ogni zona che le ha nei dati.

## Tracce, sciame e leggerezza (0.6, 13/11/2026)
- **Tracce**: otto oggetti nascosti, due per zona, segnati da un piccolo brillio (punti con `"tipo": "traccia"` in `data/capitolo1.json`). Ognuno racconta qualcosa di chi lo trova (regola U20): accendino e scarpa nel vicolo, calzino e bacheca in lavanderia, scooter e stencil nel quartiere, telefono e cuffie nel nido. Contatore in alto quando ne trovi una, conto finale prima della fine. Oggetti e righe: PROPOSTA approvato dall'autore il 14/11/2026.
- **Sciame del nido**: prima della camera del cuore le sacche si aprono e c'è uno scontro più leggero (`forza` 0.8), così il boss non arriva a freddo. PROPOSTA approvato dall'autore il 14/11/2026.
- **Ottimizzazione per il telefono**: i pezzi fermi di ogni zona e i pezzi dei personaggi si fondono in poche mesh a colori per vertice (`_unisci_statici`, `_fondi_parte` in `scripts/mondo.gd`). Draw call per zona: vicolo 204 → 40, lavanderia 89 → 30, quartiere 232 → 53, nido 89 → 18. Misura: `tools/misura.gd`.

## Il nido più grande (0.7, 14/11/2026) · PROPOSTA approvato dall'autore il 14/11/2026
- Nessuna meccanica nuova: più mappa, più posti, più scontri, più dialoghi.
- La caverna del nido si apre su due **ali** (`_costruisci_dispensa`, `_costruisci_culle` in `scripts/mondo.gd`):
  - **Dispensa** (ovest): il mucchio di cose che il nido ha ingoiato (Saul trova lo zaino di un altro rider), la fermata dell'autobus (Saul), la vetrina di una gelateria (Lance), la traccia «Fototessera». All'ingresso, scontro con l'**Ingordo**.
  - **Culle** (est): le uova delle anomalie (Nox), le tacche graffiate sul muro (Lance), la culla più piccola (Rio), la traccia «Fischietto». All'ingresso, scontro con la **Covata**.
- Tracce ora 10. Chiacchiere nuove nel nido (3) e nel quartiere (2). Il finale ha righe in più se hai visto il mucchio o le culle.
- Gli inneschi a terra accettano anche `x_min`/`x_max` (servono per le ali).

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

> 14/11/2026: Gianluca ha approvato tutte le proposte delle versioni 0.2-0.7 (lavanderia, quartiere, scontro al varco, nido con ali, boss, tracce, scene e chiacchiere).
