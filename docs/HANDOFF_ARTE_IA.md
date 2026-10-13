# HANDOFF PER L'IA: creare le grafiche di ODISPEL

Sei un'IA (o un artista) incaricata di produrre **le immagini vere** che sostituiranno i segnaposto che oggi il gioco disegna con il codice.
Questo documento ti dice **esattamente** cosa consegnare, con quali nomi, misure e regole, in modo che i file funzionino nel gioco
**senza toccare una riga di codice**: si copiano in una cartella e il gioco li usa.

> Leggi tutto prima di cominciare. Alla fine c'e' la checklist e uno script di controllo automatico (`tools/check_art.py`)
> che devi far passare senza errori prima di consegnare.

---

## 1. Il gioco in due righe

ODISPEL e' un battler cooperativo a turni, ambientato in un fantasy urbano notturno e "strano": un gruppo di operatori affronta boss nati
da oggetti quotidiani impazziti (un distributore automatico, un semaforo, un tombino, una cabina telefonica...). Interfaccia in stile
**sorveglianza/CCTV + fumetto pop** (ciano, rosso, nero, giallo "fumetto"). Si gioca in orizzontale, 1280x720, su telefono e PC.

**Stile voluto per i personaggi**: anime / visual novel giapponese a colori. Tratto pulito con contorni a inchiostro, ombre a colore piatto
(cel shading), pochi dettagli ma significativi, luce da sinistra. **Gli occhi sono il cuore**: grandi, lucidi, con riflessi, molto
espressivi (riferimenti: Persona, Kingdom Hearts, i personaggi di Final Fantasy disegnati da Amano). Personaggio in grande,
**senza sfondo**.

Atmosfera dei boss e degli sfondi: notte di citta', luci al neon (ciano/magenta), asfalto bagnato, un che di inquietante ma giocoso,
non horror crudo.

## 2. Cosa succede oggi (i segnaposto)

Il gioco mostra i personaggi in 7 punti. Dove manca un file, disegna un volto anime generico dal codice (`scripts/art/anime_face.gd`).
Le tue immagini **hanno sempre la precedenza**: puoi consegnare un file alla volta e il resto resta com'e'.

| Dove si vede | File usato | Come viene mostrato |
|---|---|---|
| Elenco operatori, carte squadra, hub, righe della battaglia, lobby | `icon.png` | quadrato, **ritagliato al centro** (cover): il volto deve riempire bene il quadrato |
| Dialoghi (a sinistra e a destra, 560x690 px a schermo) | `neutral/happy/angry/sad/surprised/hurt.png` | contenuto per intero, **ancorato in basso**, centrato |
| Scheda operatore, schermata di reclutamento (gacha) | `splash.png` | contenuto per intero, ancorato in basso (area alta e stretta, circa 164x280 nella scheda, grande nel reclutamento) |
| Sequenza dell'ultimate (cut-in a tutto schermo) | `cutin.png` | 16:9, volto/mezzo busto con energia |
| Combattimento (figura in campo + riserve in back row) | `battle.png` | figura intera, alta ~230 px nel gioco, ridotta in prospettiva (0.88 -> 0.70), **volta verso destra** (il boss e' a destra) |
| Boss in combattimento | `bosses/<id>/battle.png` (+ `hurt.png`) | volta **verso sinistra** (la squadra e' a sinistra), piedi sul suolo, max ~460 px di altezza |
| Dialoghi dei boss | `bosses/<id>/portrait.png` | come i ritratti dei personaggi |
| Sfondo della battaglia | `backgrounds/battle/layer_1..4.png` | 4 strati a parallasse, stirati a tutto schermo |
| Hub (menu principale) | `backgrounds/hub.png`, `logo.png` | sfondo a copertura, logo in alto a sinistra |
| Scene di storia | `backgrounds/dialogue/<nome>.png` | sfondo a tutto schermo (scurito del 35% dal gioco) |

Totale file obbligatori per il gioco completo: **170** (14 personaggi x 10 file + 8 boss x 3 file + 4 strati + hub + logo).
Facoltativi: 7 sfondi dei dialoghi e `hurt.png` dei boss (il gioco ha un'alternativa).

## 3. Come consegnare

Consegna **un'unica cartella `art/`** (anche in .zip) con questa struttura esatta. Nomi **tutti minuscoli**, senza spazi, estensione `.png`.

```
art/
  logo.png
  characters/
    kira/   neutral.png happy.png angry.png sad.png surprised.png hurt.png splash.png cutin.png icon.png battle.png
    dax/    ...stessi 10 file
    ... (uno per personaggio, vedi tabella nel paragrafo 5)
  bosses/
    distributore/  battle.png hurt.png portrait.png
    ... (uno per boss, vedi paragrafo 6)
  backgrounds/
    hub.png
    battle/    layer_1.png layer_2.png layer_3.png layer_4.png
    dialogue/  cabina.png incrocio.png strada_notte.png tombino.png torre.png torre_orologio.png vetrina.png
```

L'installazione, per chi riceve i file: copiare la cartella `art/` **accanto al gioco** (PC) oppure nella cartella dati del gioco
(Impostazioni > APRI CARTELLA GRAFICHE). Per l'APK le immagini vanno messe nel progetto in `art/` prima dell'esportazione.
In gioco: Impostazioni > RICARICA GRAFICHE, e deve comparire "GRAFICHE TROVATE 170 / 170".

### Formato dei file (valido per tutto)
- **PNG a 32 bit con trasparenza (RGBA)**. Niente JPG, niente WebP, niente PNG a palette.
- Sfondo **trasparente** per personaggi e boss (non un colore, non una scacchiera disegnata).
- Spazio colore sRGB. Niente profili ICC esotici.
- **Lato massimo 2048 px** (il gioco riduce comunque tutto a 2048). Usa le misure della tabella: sono tarate per telefoni con poca memoria.
- **Peso**: obiettivo sotto **1,5 MB** per immagine (massimo assoluto 2,5 MB). Ottimizza i PNG (es. `pngquant --quality 85-100` o `oxipng -o4`)
  senza perdere la trasparenza morbida dei bordi. Tutto il pacchetto dovrebbe stare sotto ~120 MB.
- Niente testo scritto dentro le immagini (nomi, didascalie, firme): il gioco scrive i nomi da solo.
- Niente cornici, ombre portate su sfondo, watermark.

## 4. Misure e regole per tipo di file

Tutte le misure sono **la dimensione della tela**. Mantieni **sempre la stessa tela** per tutti i file dello stesso tipo e dello stesso personaggio.
Il controllo automatico accetta proporzioni entro il 3% dalle misure indicate.

### 4.1 Ritratti: `neutral.png`, `happy.png`, `angry.png`, `sad.png`, `surprised.png`, `hurt.png`
- **Tela 1000 x 1400** (verticale). Busto / mezza figura, il personaggio **tocca il bordo inferiore** della tela (il busto e' tagliato dal bordo).
- Testa nel terzo superiore, centrata, con un po' d'aria sopra la testa (circa 6-10% dell'altezza) e ai lati.
- **Le 6 espressioni sono la stessa identica immagine** (stesso corpo, vestiti, capelli, posa, posizione, tela): cambiano **solo occhi,
  sopracciglia, bocca** (e al massimo gocce, rossore, linee d'effetto sul volto). Cosi' nel gioco si sovrappongono senza "saltare".
  Pratica: dipingi `neutral` e poi ripartendo da quello produci le altre 5 modificando solo il volto.
- Espressioni: `neutral` (calmo), `happy` (sorriso aperto), `angry` (sopracciglia basse, denti/bocca dura), `sad` (occhi lucidi, sguardo in basso),
  `surprised` (occhi molto grandi, bocca aperta), `hurt` (occhi stretti, smorfia di dolore; **viene mostrata anche in battaglia quando prende un colpo**).
- Il personaggio guarda **verso il centro dello schermo**: nei dialoghi quello a sinistra e' disegnato guardando a destra; quello di destra e' lo
  stesso file **specchiato dal gioco**. Disegna quindi il personaggio in posizione **frontale / tre quarti verso destra** e non mettere elementi
  asimmetrici dove il testo verrebbe letto al contrario (nessuna scritta addosso).

### 4.2 `splash.png` (scheda operatore e reclutamento)
- **Tela 1200 x 1600** (verticale). Illustrazione di presentazione: figura **intera o a tre quarti**, posa piu' scenografica, dettagli ricchi.
- Il personaggio tocca il bordo inferiore e **riempie quasi tutta l'altezza**; resta centrato (nella scheda l'area e' alta e stretta e il gioco
  adatta l'immagine mantenendo le proporzioni).
- Qui si vede la **rarita'**: comuni semplici, rari con un accessorio in piu', epici con effetti e dettagli, **leggendari** con illustrazione
  piu' ricca (aura, elementi luminosi, vestiti elaborati). Nessuno sfondo.

### 4.3 `cutin.png` (ultimate)
- **Tela 1600 x 900** (16:9). Primo piano dinamico: volto e spalle, sguardo deciso, linee di velocita', luci nella tinta del personaggio.
- Qui lo sfondo trasparente puo' avere lampi/linee d'azione colorate **semitrasparenti**, ma il soggetto deve restare leggibile su scuro.
- Non deve toccare il bordo inferiore (e' l'unico file dove non serve).

### 4.4 `icon.png`
- **Tela 256 x 256 esatta, quadrata.** Solo il **volto** (testa e un po' di collo), **centrato**, che occupa circa il 75-85% della tela.
- Il gioco la mostra a 38-56 px: occhi grandi e capelli riconoscibili, **silhouette e colore** devono leggersi anche piccolissimi.
- Sfondo: puo' essere trasparente (il gioco mette una tinta scura sotto).
- Il gioco la **ritaglia al centro** per riempire il quadrato: niente elementi importanti ai bordi.

### 4.5 `battle.png` (figura in combattimento)
- **Tela 480 x 640** (verticale), figura **intera in piedi**, **piedi sul bordo inferiore** della tela, centrata orizzontalmente.
- Posa da combattimento (peso sul davanti, guardia o arma pronta), **volta verso DESTRA** (il boss e' a destra della squadra).
- Il gioco la usa **piccola** (circa 230 px di altezza): semplifica i dettagli, contorni piu' spessi, forme leggibili, colori del personaggio
  ben distinti dal fondale scuro viola/ciano. Silhouette chiara.
- Le riserve (back row) sono mostrate con la stessa immagine ma in trasparenza e scurite: nessun file in piu'.
- Il personaggio **non deve avere ombre a terra disegnate**: il gioco aggiunge la sua ombra.

### 4.6 Boss: `battle.png`, `hurt.png`, `portrait.png`
- `battle.png`: **tela 1000 x 1000**, il boss intero, **piedi/base sul bordo inferiore**, centrato, volto/fronte **verso SINISTRA**.
  Nel gioco sta a destra, altezza massima circa 460 px, un po' piu' lontano della squadra. Deve essere grande, minaccioso e leggibile.
- `hurt.png` (facoltativo ma consigliato): **stessa tela e stessa identica posa** di `battle.png`, ma colpito (deformato, scintille, occhi/luci
  spenti, crepe). Il gioco la mostra per un istante quando il boss subisce un colpo, quindi deve sovrapporsi perfettamente a `battle.png`.
- `portrait.png`: **tela 1000 x 1400**, busto/primo piano del boss per i dialoghi, ancorato in basso (puo' essere un dettaglio del "volto"
  dell'oggetto: lo schermo del distributore, il riflettore del semaforo...). Se manca il gioco usa `battle.png`.
- I boss sono **oggetti reali impazziti**, non mostri generici: l'oggetto deve restare riconoscibile, con elementi "vivi" (occhi, bocche, cavi
  come tentacoli, schermi rotti). Colore dominante = il colore del boss (vedi paragrafo 6).

### 4.7 Sfondi di battaglia: `backgrounds/battle/layer_1.png` ... `layer_4.png`
- **Tela 1600 x 900** (16:9, il gioco li stira a tutto schermo piu' un margine di 90 px).
- **4 strati dal piu' lontano (1) al piu' vicino (4)**, che scorrono con parallasse (i lontani poco, i vicini di piu'). Si disegnano uno sopra l'altro:
  - `layer_1`: **opaco** (cielo notturno, luna, skyline lontano, nebbia luminosa).
  - `layer_2`, `layer_3`, `layer_4`: **con trasparenza** (edifici medi, insegne al neon, pali/fili/vegetazione in primo piano ai lati).
- **Composizione**: l'orizzonte e' a circa un terzo dall'alto (y ~ 250 su 720); il **suolo** (asfalto bagnato, riflessi) occupa la parte bassa.
  La **zona centrale-bassa e a destra** (dove stanno squadra e boss: da x=10% a x=90%, y=40% a 85%) deve restare **pulita e a basso contrasto**,
  senza elementi chiari o rumorosi, altrimenti i personaggi non si leggono. I dettagli forti vanno ai bordi e in alto.
- Palette: viola notte -> magenta caldo sull'orizzonte, ciano e rosa neon come accenti (coerente con l'interfaccia ciano/rosso).
- Uno sfondo comune `backgrounds/battle/` vale per tutti i boss. **Facoltativo**: un set dedicato per un boss in
  `backgrounds/<boss>/layer_1..4.png` (stesse regole) ha la precedenza su quello comune.

### 4.8 Hub e logo
- `backgrounds/hub.png`: **1920 x 1080**, opaco. Scena notturna di citta', il "quartier generale" dell'operazione ("MISSION CONTROL").
  Il gioco la scurisce leggermente e **il menu sta a sinistra** (pulsanti) e il logo in alto a sinistra: tieni quella zona piu' calma/scura,
  con l'interesse visivo a destra.
- `logo.png`: **1000 x 280**, **trasparente**, la scritta **ODISPEL** in stile pop/CCTV (taglio rosso diagonale, contorno nero spesso, bianco, un
  puntino REC rosso). Nel gioco e' mostrato alto circa 100 px: leggibile, niente dettagli sottili. Solo la parola ODISPEL, nessun sottotitolo.

### 4.9 Sfondi dei dialoghi (facoltativi): `backgrounds/dialogue/<nome>.png`
- **1920 x 1080**, opachi, il gioco li scurisce del 35% e ci sovrappone i ritratti. Lascia il centro basso libero (casella di testo).
- Nomi esatti (quelli usati dalle scene): `strada_notte` (strada di notte), `incrocio` (incrocio con il semaforo), `tombino` (strada, tombino aperto),
  `cabina` (cabina telefonica isolata), `vetrina` (vetrina di negozio con manichini), `torre` (esterno/atrio della torre LibraCorp),
  `torre_orologio` (la torre con il grande orologio, CAM-00).

## 5. I personaggi (14)

`<id>` e' il nome cartella **esatto**. Il **colore** guida la palette (capelli, accessori, iride nella tinta). Tinta di riferimento dell'interfaccia
(usala per accessori e riflessi, non per tutta la figura):

| Colore | Tinta UI | Carattere da trasmettere (sguardo/posa) |
|---|---|---|
| rosso | `#ff4d6d` | STR: diretto, energico, sguardo deciso |
| giallo | `#ffd25f` | PSY: premuroso, di sostegno, sguardo gentile |
| viola | `#b07bff` | INT: analitico, sguardo acuto e calmo |
| verde | `#6bffb0` | DEX: preciso, vigile, sguardo concentrato |
| blu | `#5aa8ff` | QCK: rapido, brillante, sguardo vivace |

Fazioni (riconoscibili da divisa e accessori):
- **LibraCorp**: azienda/torre, divise operative sobrie, dettagli tecnici, munizioni/ricarica.
- **Rondini**: gruppo giovane e agile, divisa/giacca **bianca**, look sportivo, spirito di squadra.
- **Magabondi**: vagabondi liberi, abiti sciolti, colorati e spaiati, aria di strada.
- **Kairos**: enigmatici, **dettagli dissonanti** (asimmetrie, glitch, elementi fuori posto).

| id | Nome | Colore | Classe | Fazione | Rarita' | Note per il disegno |
|---|---|---|---|---|---|---|
| kira | Kira | viola | striker | Rondini | rara | giovane scattante, divisa Rondini bianca, capelli viola. **Protagonista**: il design di riferimento |
| dax | Dax | rosso | vanguard | LibraCorp | comune | robusto, divisa LibraCorp, sguardo fermo |
| elle | Elle | verde | warden | Magabondi | comune | abiti sciolti e colorati, aria libera |
| bruno | Bruno | blu | vanguard | LibraCorp | comune | solido e affidabile, divisa LibraCorp |
| nova | Nova | giallo | striker | Rondini | rara | vivace, accessori dorati |
| mira | Mira | blu | warden | LibraCorp | rara | calma e attenta, divisa LibraCorp |
| rex | Rex | rosso | striker | Rondini | comune | grintoso, giacca Rondini |
| ivo | Ivo | blu | striker | Magabondi | rara | agile, look da strada |
| sera | Sera | verde | warden | Rondini | epica | elegante e serena, tratti delicati |
| eco | Eco | giallo | striker | Kairos | epica | enigmatico, dettagli dissonanti (Kairos) |
| tana | Tana | giallo | vanguard | LibraCorp | leggendaria | presenza imponente, protettiva |
| nico | Nico | rosso | vanguard | Kairos | epica | storia: amico di Kira, custode del rifugio, **sciarpa rossa sempre al collo** |
| dafne | Dafne | giallo | striker | LibraCorp | leggendaria | tiratrice scelta: sguardo da cecchina, divisa operativa |
| angela | Angela | giallo | striker | LibraCorp | leggendaria | "Dea del laser orbitale": mecamante, elementi tecnologici luminosi |

Classi (per la silhouette): **striker** = attaccante, posa offensiva, arma in mano; **vanguard** = tank, corporatura piu' larga, protezioni;
**warden** = supporto/cura, silhouette piu' morbida, strumenti di aiuto.

Regole di coerenza per ogni personaggio (fondamentale):
1. **Prima la scheda modello** (model sheet): vista frontale, tre quarti, dettagli del volto, palette. Tutti i 10 file derivano da quella.
2. Stessi colori, stessi vestiti, stessa pettinatura in **tutti** i file dello stesso personaggio (ritratti, splash, cut-in, icona, battle).
3. Lo stile e il livello di dettaglio sono omogenei **tra personaggi diversi**: devono sembrare dello stesso gioco.
4. Aumenta il dettaglio con la rarita' (comune < rara < epica < leggendaria) senza cambiare lo stile.

## 6. I boss (8)

| id | Nome | Colore | Aspetto / spunti |
|---|---|---|---|
| distributore | Distributore | giallo | distributore automatico impazzito: vetro crepato, spirali come denti, braccio che sbuca dallo sportello, luce gialla malata. Il **primo boss**, deve essere chiaro e iconico |
| semaforo | Semaforo | rosso | semaforo bloccato sul rosso, luci come occhi, palo piegato, aria da predatore veloce |
| tombino | Tombino | viola | qualcosa che esce da sotto un tombino: coperchio come bocca, vapore viola, tentacoli di tubi, massiccio e lento |
| cabina | Cabina | blu | cabina telefonica che squilla da sola: vetri come occhi, cavo del telefono che penzola come lingua, luce blu |
| ascensore | Ascensore | blu | ascensore della torre LibraCorp: porte come mascelle, numeri dei piani impossibili sul display, luce fredda |
| manichino | Manichino | verde | manichino da vetrina che copia chi lo guarda: posa teatrale, giunture, vetro attorno, verde menta |
| orologio | Orologio | viola | grande orologio della torre (CAM-00): lancette come lame, quadrante come volto, ingranaggi, tempo fermo |
| specchio | Specchio | rosso | lo specchio dietro l'orologio: superficie crepata che mostra un "doppio", frantumi, riflessi rossi |

Ogni boss va in **3 file** (`battle`, `hurt`, `portrait`), stesso design. Il colore dominante e' quello indicato.

## 7. Flusso di lavoro consigliato (in quest'ordine)

1. **Bibbia di stile**: 1 immagine di riferimento per lo stile (volto, occhi, contorno, ombreggiatura) e la palette. Mostrala prima di procedere.
2. **Kira completa** (10 file): e' il banco di prova. Controlla con lo script e fai verificare dall'umano prima di fare gli altri.
3. Gli altri 13 personaggi, **nell'ordine**: dax, elle, bruno, nova, mira, rex, ivo, sera, eco, nico, tana, dafne, angela. Per ognuno: scheda modello,
   `neutral`, le altre 5 espressioni, `icon`, `battle`, `splash`, `cutin`.
4. Boss, nell'ordine del gioco: distributore, semaforo, tombino, cabina, ascensore, manichino, orologio, specchio.
5. Sfondi di battaglia (4 strati), poi hub, poi logo.
6. Sfondi dei dialoghi (facoltativi).
7. **Controllo automatico** (paragrafo 8) e ottimizzazione dei pesi.

Puoi consegnare **a lotti**: ogni lotto e' una cartella `art/` con solo i file nuovi (stessa struttura). Il gioco usa i file presenti e i segnaposto per gli altri.

## 8. Controllo prima di consegnare

Nel repository c'e' `tools/check_art.py` (serve Python e Pillow: `pip install pillow`):

```
python3 tools/check_art.py art
python3 tools/check_art.py art --strict      # anche gli avvisi bloccano
```

Verifica: tutti i 170 file presenti con il nome giusto, PNG RGBA, proporzioni, sfondo trasparente (angoli), figura appoggiata al bordo inferiore,
6 espressioni della stessa misura per ogni personaggio, icone quadrate, peso. **Deve chiudersi senza ERRORI.** (Per un lotto parziale i file
non ancora consegnati risultano "MANCA": ignorali, ma tutti i file presenti devono essere senza errori.)

Poi guarda tu stesso le immagini **sul fondo scuro del gioco** (non su bianco): bordi sporchi/aloni chiari attorno ai capelli (effetto "alone") sono il
difetto piu' comune dei ritagli senza sfondo. Rimuovili.

### Checklist finale
- [ ] Struttura cartelle e nomi identici a questo documento (minuscoli, `.png`)
- [ ] Tutti PNG RGBA, sfondo trasparente dove richiesto, nessun alone
- [ ] Misure/proporzioni rispettate; lato massimo 2048; peso < 1,5 MB (max 2,5)
- [ ] 6 espressioni per personaggio identiche tranne il volto
- [ ] `battle.png` verso destra, boss verso sinistra, piedi sul bordo inferiore
- [ ] Sfondi di battaglia: `layer_1` opaco, 2-4 trasparenti, zona centrale-bassa pulita
- [ ] Nessun testo, cornice o watermark nelle immagini
- [ ] `check_art.py` senza errori

## 9. Cose da NON fare
- Non cambiare nomi, id, cartelle: il gioco cerca i file **per nome esatto**.
- Non consegnare formati diversi dal PNG, ne' immagini enormi "per sicurezza": su telefono occupano memoria video.
- Non riprodurre personaggi, mascotte o opere protette esistenti: tutti i personaggi e i boss sono **originali**; gli stili citati sono solo
  riferimenti di atmosfera.
- Non toccare il codice del gioco: se qualcosa non funziona con un file, segnalalo invece di aggirarlo.

## 10. Riferimenti tecnici (per chi vuole controllare)
- Elenco completo dei file attesi: `ArtLibrary.slots()` in `scripts/art/art_library.gd` (170 voci).
- Come ogni immagine viene disegnata: `scripts/art/portrait_view.gd` (ritratti/icone/splash/cut-in), `scenes/battle/battle_stage.gd`
  (figure di battaglia, boss, sfondi a parallasse), `scenes/hub/hub_demo.gd` (sfondo hub), `scripts/ui/logo.gd` (logo).
- Guida originale piu' breve: `docs/GUIDA_ARTE.md`. Modelli segnaposto con nomi e misure giusti: `python3 tools/make_art_templates.py`.
