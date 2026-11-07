# Icone dell'HUD · guida per Procreate

Questa guida è per le icone dell'HUD che l'autore disegna a mano (HUD 0.61, P1-C, 7/11/2026).

Il gioco legge da solo i PNG che trova in `assets/hud_icons/`. Finché un file manca, resta l'icona disegnata in codice: si può consegnare un'icona alla volta.

Nella cartella del progetto, `odispel/v3/hud_icone/`, ci sono due guide da importare come livello di riferimento:

- `guida_256.png` per la tela da 256 px;
- `guida_1024.png` per la tela da 1024 px.

## 1 · Tela

| | Tela finale | Tela per disegnare comodi (×4) |
|---|---|---|
| Dimensione | **256 × 256 px** | 1024 × 1024 px |
| DPI | 132 (non conta) | 132 |
| Profilo colore | sRGB | sRGB |
| Sfondo | **spento** (trasparente) | spento |

Se disegni a 1024, prima di esportare usa *Azioni › Tela › Ritaglia e ridimensiona › 256 × 256* con *Ricampiona* acceso. In alternativa lascia il file a 1024: il gioco lo rimpicciolisce da solo, ma il file pesa 16 volte di più.

## 2 · Area utile e margini

Le misure sono sulla tela da 256 px; tra parentesi ci sono quelle sulla tela da 1024.

- **Margine di sicurezza: 24 px per lato (96).** Il bordo rosso della guida è la tela; dentro il quadrato giallo non deve uscire niente. Le punte e le ombre comprese.
- **Area utile: 208 × 208 px (832), centrata.** Il gioco fa coincidere quest'area con lo spazio dove oggi c'è l'icona disegnata in codice.
- **Il cerchio azzurro** è l'area utile vista come tondo. Molte icone stanno dentro un bollino rotondo, come i tasti dei comandi e i mirini sui ritratti, quindi tieni la forma importante dentro il cerchio. Gli angoli del quadrato giallo vanno bene solo per dettagli che si possono perdere.
- **Centro ottico:** la croce al centro. Un'icona pesante in basso, come un triangolo, va alzata di 4–6 px (16–24) perché sembri centrata.

## 3 · Spessori e dettagli

Nel gioco le icone diventano piccole. Le dimensioni di riferimento sono quelle di uno schermo a 720 righe; un telefono a 1080 righe le mostra 1,5 volte più grandi.

| Dove compare | Lato dell'icona in gioco |
|---|---|
| Mirino sui ritratti della squadra | ~17 px |
| Avvisi | ~27 px |
| Tasti ATTACCO, ABILITÀ, GUARDIA, ULTIMATE | 30–35 px |
| Lastra della prossima mossa | ~37 px |
| Ruota dei comandi | 40–50 px |

Quindi una linea da 256 px diventa da 8 a 15 volte più sottile. Le regole:

- **Spessore della linea: minimo 20 px (80), consigliato 24–32 px (96–128).** Sotto i 20 px la linea sparisce nel mirino e negli avvisi.
- **Dettaglio più piccolo** (un punto, un foro, una tacca): **almeno 28 px (112).**
- **Spazio tra due forme: almeno 20 px (80).** Se è più stretto, le due forme si fondono in una macchia.
- **Al massimo 3 elementi per icona.** Un'icona si legge dalla sagoma, non dai dettagli.
- **Prova di lettura:** zoom out finché la tela è grande come l'unghia del mignolo. Se non capisci cos'è, è troppo complessa.
- Pennello consigliato: *Inchiostrazione › Penna tecnica* o *Monolinea*, con l'opacità al 100%. Niente pennelli a grana o a spruzzo: le sfumature diventano grigio sporco.

## 4 · Convenzioni grafiche

- **Solo bianco puro (#FFFFFF) su trasparente.** Il gioco colora l'icona moltiplicando il bianco per il colore dell'HUD: il bianco diventa quel colore, la trasparenza resta trasparente.
- **Niente grigi né colori.** Un grigio al 50% diventa il colore al 50%, quindi più scuro e sporco. Per un «buco» dentro una forma usa la gomma, non il nero: il nero resta nero e non si colora.
- **Niente contorno né ombra nel PNG:** il contorno d'inchiostro e l'ombra li aggiunge l'HUD. Se li disegni tu, compaiono due volte.
- **Il bordo della forma è netto,** cioè antialiasing normale di Procreate, senza sfocature.
- **Lo stile ODISPEL** è fatto di tagli storti (come le lastre dell'HUD), linee spesse e punte vive. Meglio angoli tagliati che arrotondati: un'inclinazione di 6–10° dà subito il «nostro» tratto.
- **Stessa famiglia per tutte:** stesso spessore di linea, stessa inclinazione e stesso peso visivo. Disegnale una accanto all'altra sulla stessa tela, se puoi.

## 5 · Come il gioco colora l'icona

- Il colore dipende da dove compare l'icona:
  - i tasti dei comandi la colorano color crema, giallo quando sono scelti e grigio quando non si possono usare;
  - la lastra della minaccia la colora inchiostro scuro su fondo rosso, oppure su fondo giallo quando il colpo è FORTE;
  - gli avvisi la colorano rosso per i pericoli, giallo per la tattica e azzurro per l'ambiente;
  - il mirino sui ritratti è rosso.
- Lo stesso PNG va bene ovunque: il colore lo decide il gioco. Per questo l'icona deve funzionare sia chiara su fondo scuro sia scura su fondo chiaro: niente dettagli che reggono solo in uno dei due casi.
- Anche la trasparenza viene moltiplicata: un tasto spento rende l'icona più trasparente da solo.

## 6 · Nomi dei file

Esporta come *PNG* (Azioni › Condividi › PNG) e metti i file in `assets/hud_icons/`. Puoi anche lasciarli nella cartella del progetto e me li sposto io.

| File | Dove compare | Cosa deve dire |
|---|---|---|
| `attacco.png` | tasto ATTACCO, ruota, abilità che colpiscono | colpire |
| `abilita.png` | tasto ABILITÀ, abilità di supporto | tecnica / energia |
| `ultimate.png` | tasto ULTIMATE | il colpo finale |
| `guardia.png` | tasto GUARDIA, abilità sui compagni | difesa |
| `minaccia_singolo.png` | lastra: colpo su uno, mirino sui ritratti | bersaglio unico |
| `minaccia_tutti.png` | lastra: colpo su tutti | tutta la squadra |
| `minaccia_catena.png` | lastra: colpo con catena | un colpo che ne porta un altro |
| `stato.png` | bollino dello stato (MARCHIO, SANGUINA) | effetto che resta |
| `stordito.png` | lastra: nemico stordito | fuori gioco per un turno |
| `avviso_pericolo.png` | avvisi rossi | attenzione, pericolo |
| `avviso_tattica.png` | avvisi gialli | consiglio, occasione |
| `avviso_ambiente.png` | avvisi azzurri | situazione intorno |
| `avviso_catena.png` | avvisi di legame e catena | legame |
| `avviso_mossa.png` | nome della mossa | azione in corso |

I nomi sono in `scripts/v3/hud_icons.gd` (`HudIcons.NAMES`). Per un'icona nuova basta aggiungere una riga lì.

## 7 · Prova veloce

Dopo aver messo i PNG lancia `tools/v3_hud_061.gd`, che rifà le schermate dell'HUD su telefono e PC. Si vede subito se un'icona è troppo sottile o troppo piena.
