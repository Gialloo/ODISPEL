# ODISPEL — Handoff: portrait dei dialoghi (stile Persona)

Destinatario: un'IA che genera immagini. Servono i **portrait a mezzo busto** dei 4 protagonisti, con più espressioni,
da mostrare accanto al box di testo durante i dialoghi, come in Persona 5: il personaggio entra di lato, cambia faccia
a seconda della battuta. Per ora sono una **demo** per provare l'effetto nel gioco.

## 1. Formato (uguale per tutti i file)
- **PNG con sfondo trasparente**, **1024 × 1536 px** (verticale 2:3).
  Se non puoi fare la trasparenza: sfondo **verde pieno `#00FF00`** uniforme, senza ombre né sfumature sul fondo (lo scontorno io).
- **Inquadratura:** dalla cima della testa (con capelli e cappello) fino ai **fianchi**; il corpo è tagliato netto dal bordo in basso.
  - spazio vuoto sopra la testa: circa **5%** dell'altezza;
  - **occhi a circa il 22-25% dall'alto**;
  - il personaggio occupa circa **l'80% della larghezza**, centrato.
- **Posa:** tre quarti, **corpo e sguardo rivolti verso destra dell'immagine** (nel gioco lo specchio io quando parla dall'altro lato).
- Niente testo, niente cornici, niente fumetti, niente ombra sotto, niente effetti sul fondo.

## 2. Coerenza (la regola più importante)
Le espressioni dello stesso personaggio devono essere **la stessa immagine con un'altra faccia**:
stessa posa, stessa inquadratura, stessa luce, stessi vestiti, stessa dimensione. Cambiano **solo viso** e, al massimo, mani o spalle.
Se il personaggio "salta" fra un'espressione e l'altra, nel gioco l'effetto si rompe.
Metodo consigliato: fai prima `neutro`, poi genera le altre **modificando quella** ("identica, cambia solo l'espressione in …").

## 3. Stile
- Anime con **cel shading pulito**: linea di contorno scura e netta (quasi nero violaceo `#120a1c`), ombre a **due toni piatti**, niente pittura morbida o realistica.
- Colori saturi; luce dall'alto a sinistra; **un filo di luce di contorno (rim light) del colore di battaglia** del personaggio sul lato destro.
- Personaggi **giovani adulti**, tutti maggiorenni, proporzioni anime (occhi grandi, viso a V).
- Ispirazione Persona 5 / Honkai: Star Rail per la qualità, **senza copiare** personaggi, costumi o loghi esistenti.

## 4. Espressioni (7 per personaggio)
| Nome file | Espressione |
|---|---|
| `neutro` | il suo modo normale di stare (vedi le schede: per Nox è già "stanca") |
| `felice` | contento davvero, sorriso aperto |
| `arrabbiato` | sopracciglia giù, denti o labbra serrate |
| `triste` | sguardo basso, bocca piegata in giù |
| `sorpreso` | occhi spalancati, bocca aperta |
| `sfotto` | mezzo sorriso di sfida, un sopracciglio alzato |
| `serio` | determinato, mascella dura, sguardo dritto |

Nomi: `<personaggio>_<espressione>.png`, tutto minuscolo e senza accenti. Esempio: `nox_sfotto.png`.
In più per Zecca: `zecca_maschera.png` (stessa posa, con la maschera indossata). Totale: **29 immagini**.

## 5. I personaggi (nomi provvisori)
- **Ferri** — LibraCorp, colore **ROSSO** (`#e8343f`), 23 anni. Ex soldato rigido e autoritario. Uniforme tattica blu notte (`#25324f`, `#1b2236`)
  con spalline e profili rossi, collo alto, berretto con visiera e stemma a bilancia stilizzata. Guanti neri. Capelli neri corti, occhi castano scuro,
  sguardo che giudica. **Niente fascia rossa al braccio.**
- **Nox** — Odispeller delle Civette, colore **BLU** (`#39b7ff`), 24 anni, donna. Cinica, sfinita, vive di caffè. Cappotto lungo blu-viola (`#3a3770`)
  con collo alto e profilo blu elettrico, distintivo con una civetta. Capelli lunghi blu notte (`#2a2c56`) con frangia asimmetrica e **due ciuffi in alto
  come orecchie di civetta**, occhi blu, occhiaie, palpebre a metà. Bicchiere di caffè da asporto in mano.
- **Zecca** — Masca, colore **VIOLA** (`#8e3df0`), 19 anni, ragazzo. Vanitoso, impulsivo, fa dirette col telefono. Felpa viola larga con cappuccio,
  lacci e dettagli gialli (`#ffd23f`). Capelli bianco-lilla (`#f0e6ff`) a punte in tutte le direzioni, occhi viola, sorriso sfacciato.
  Telefono in mano. Maschera (solo in `zecca_maschera`): bianca, inquietante, occhi a fessura viola luminosi, fessura gialla al posto della bocca.
- **Saul** — Magabondo, colore **VERDE** (`#2f8f5a`), 22 anni. Contrabbandiere, truffatore affascinante. Bomber verde su strati di vestiti,
  tracolla di cuoio, dettagli arancio (`#ff8a2b`). Capelli castani (`#4a2b1c`) lunghi raccolti in coda con frangia divisa, berretto di lana verde scuro,
  occhi ambra, mezzo sorriso da venditore, anelli e amuleti.

## 6. Consegna
Uno zip con tutte le immagini: `portrait_demo.zip`, oppure uno per personaggio (`ferri_portrait.zip`, …).
Gianluca lo allega nella chat con Claude, che li mette in `assets/portraits/` al posto dei ritratti provvisori (stessi nomi) e li prova nei dialoghi.
