# HANDOFF PER GEMINI: continuare le grafiche di ODISPEL

Ciao Gemini. Stiamo producendo le **grafiche di un videogioco** (ODISPEL: battler cooperativo a turni, fantasy urbano notturno, stile anime/visual novel).
Un'altra IA ha gia' cominciato con il personaggio **Kira** e ha finito i crediti: **continua tu mantenendo identico lo stile.**
Ogni immagine che produci diventa un file del gioco: le regole qui sotto sono tecniche e vanno rispettate alla lettera.

Insieme a questo documento ti vengono dati come **riferimento di stile e di personaggio**:
- la tavola riassuntiva di Kira (tutti i formati + model sheet),
- `neutral.png` e `happy.png` di Kira.
Guardale prima di tutto: stesso tratto pulito con contorni a inchiostro, ombre a colore piatto (cel shading), occhi grandi e luminosi con riflessi,
palette del personaggio. **Tutti i personaggi devono sembrare dello stesso gioco.**

## 0. Regole generali (valgono per ogni immagine)
1. **Una immagine per messaggio.** Niente tavole con piu' immagini.
2. **Sfondo a tinta unita (chroma key).** Non sai produrre trasparenza vera, quindi usa uno **sfondo piatto di un solo colore, senza sfumature, senza
   ombre, senza pavimento, senza luci sullo sfondo**:
   - sfondo **verde acceso #00FF00** per tutti i personaggi **tranne** quelli verdi;
   - sfondo **magenta acceso #FF00FF** per i personaggi **verdi** (Elle, Sera, Dafne) e per Kira se il verde dovesse comparire nel suo design;
   - il colore dello sfondo **non deve comparire sul personaggio** (nemmeno nei riflessi). Bordi netti, niente alone, niente sfocature attorno ai capelli.
   Un programma poi togliera' lo sfondo: tu non devi farlo.
3. **Nessun testo**, nessun logo scritto, nessuna cornice, nessuna etichetta, nessuna firma, **nessun watermark o simbolo nell'angolo**.
4. **Stesso identico personaggio** (volto, capelli, fermagli, vestiti, colori) in tutti i file dello stesso personaggio.
5. **Proporzioni (aspect ratio)** indicate per ogni file: usa il formato piu' vicino che sai produrre. Le misure in pixel esatte le sistema poi uno script, ma la
   **proporzione e la posizione del soggetto** devono essere giuste.
6. **Niente ombre a terra** disegnate.
7. Personaggi e boss sono **originali**: non copiare personaggi o opere esistenti.

## 1. I file di ogni personaggio (10) e come chiederli

Per ogni personaggio le richieste sono sempre le stesse, nell'ordine. Sostituisci `[NOME]`, `[COLORE SFONDO]` e le note del personaggio (vedi tabella al paragrafo 3).

| # | File | Proporzione | Cosa deve mostrare |
|---|---|---|---|
| 1 | `neutral.png` | **5:7 verticale** (se non c'e': 3:4) | busto/mezza figura, **il corpo tocca il bordo inferiore**, testa nel terzo superiore, centrata, circa 8% di aria sopra i capelli. Posa frontale, volto calmo, sguardo verso il centro |
| 2-6 | `happy`, `angry`, `sad`, `surprised`, `hurt` | **identica a neutral** | **modifica di neutral.png**: cambia SOLO occhi, sopracciglia e bocca. Tutto il resto (capelli, fermagli, vestiti, pieghe, posa, posizione, tela, sfondo) IDENTICO |
| 7 | `icon.png` | **1:1** | solo il volto (testa e un po' di collo), centrato, occupa circa l'80% del quadrato, silhouette e occhi leggibili anche piccolissimi |
| 8 | `battle.png` | **3:4 verticale** | figura **intera in piedi**, posa da combattimento con l'arma pronta, **rivolta verso DESTRA**, **piedi sul bordo inferiore**, riempie quasi tutta l'altezza (testa vicina al bordo superiore), contorni piu' spessi e forme semplici (verra' mostrata piccola) |
| 9 | `splash.png` | **3:4 verticale** | illustrazione di presentazione a figura intera o tre quarti, posa scenografica, molto dettaglio, tocca il bordo inferiore, riempie quasi tutta l'altezza, centrata |
| 10 | `cutin.png` | **16:9 orizzontale** | primo piano dinamico: volto e spalle, sguardo deciso, linee di velocita' ed energia nella tinta del personaggio. Sfondo comunque a tinta unita |

Espressioni (solo il volto cambia):
- `happy`: sorriso aperto e allegro
- `angry`: sopracciglia basse, bocca dura con denti stretti
- `sad`: occhi lucidi, sguardo in basso, bocca piccola e triste
- `surprised`: occhi molto grandi, bocca aperta
- `hurt`: occhi socchiusi, smorfia di dolore

### Modello di richiesta (copia e adatta)
```
Genera neutral.png di [NOME] per il videogioco ODISPEL, nello stesso identico stile di Kira (immagini di riferimento).
Proporzione 5:7 verticale. Sfondo piatto di un solo colore [COLORE SFONDO], senza sfumature, ombre o pavimento; quel colore non deve comparire sul personaggio.
Busto/mezza figura, il corpo tocca il bordo inferiore, testa nel terzo superiore, centrata, circa 8% di spazio libero sopra i capelli.
Posa frontale, volto calmo, sguardo verso il centro. Nessun testo, logo scritto, cornice o watermark.
Personaggio: [DESCRIZIONE dalla tabella].
```
E per le espressioni (nella stessa chat, allegando neutral.png appena creata):
```
Modifica questa immagine (neutral.png di [NOME]) e produci happy.png: cambia SOLO occhi, sopracciglia e bocca (sorriso aperto e allegro).
Tutto il resto deve restare IDENTICO: capelli, fermagli, vestiti, pieghe, posa, posizione, proporzione e sfondo [COLORE SFONDO].
```

## 2. Stato del lavoro

| Personaggio | Fatto | Da fare |
|---|---|---|
| Kira | tavola di riferimento, `neutral`, `happy` | `angry`, `sad`, `surprised`, `hurt`, `icon`, `battle`, `splash`, `cutin` |
| tutti gli altri 13 | niente | tutti i 10 file |

Ordine consigliato per gli altri: dax, elle, bruno, nova, mira, rex, ivo, sera, eco, nico, tana, dafne, angela.
**Prima di ogni nuovo personaggio**: fai una **tavola modello** (vista frontale, tre quarti, retro, dettagli del volto, palette) e fermati a farla approvare. Poi i 10 file.
Dopo i personaggi: boss (paragrafo 4), sfondi (paragrafo 5).

## 3. I personaggi

Il **colore** guida la palette (capelli, accessori, iride nella tinta). Tinta UI di riferimento:

| Colore | Tinta | Carattere (sguardo/posa) |
|---|---|---|
| rosso | `#ff4d6d` | STR: diretto, energico, sguardo deciso |
| giallo | `#ffd25f` | PSY: premuroso, di sostegno, sguardo gentile |
| viola | `#b07bff` | INT: analitico, sguardo acuto e calmo |
| verde | `#6bffb0` | DEX: preciso, vigile, sguardo concentrato |
| blu | `#5aa8ff` | QCK: rapido, brillante, sguardo vivace |

Fazioni: **LibraCorp** = divise operative sobrie, dettagli tecnici; **Rondini** = giovani e agili, giacca/divisa **bianca**, look sportivo; **Magabondi** = vagabondi, abiti sciolti e colorati e spaiati; **Kairos** = enigmatici, **dettagli dissonanti** (asimmetrie, glitch).
Classi: **striker** = attaccante, posa offensiva, arma; **vanguard** = tank, corporatura larga, protezioni; **warden** = supporto, silhouette morbida, strumenti di aiuto.
Rarita': piu' alta = piu' dettaglio e accessori (comune < rara < epica < leggendaria), senza cambiare stile.

| id | Nome | Colore | Classe | Fazione | Rarita' | Descrizione |
|---|---|---|---|---|---|---|
| kira | Kira | viola | striker | Rondini | rara | giovane scattante, giacca Rondini bianca, capelli viola con ciocche magenta, fermagli geometrici, imbracatura nera, nastri viola. **Riferimento: gia' fatta** |
| dax | Dax | rosso | vanguard | LibraCorp | comune | robusto, divisa LibraCorp, sguardo fermo |
| elle | Elle | verde | warden | Magabondi | comune | abiti sciolti e colorati, aria libera |
| bruno | Bruno | blu | vanguard | LibraCorp | comune | solido e affidabile, divisa LibraCorp |
| nova | Nova | giallo | striker | Rondini | rara | vivace, accessori dorati |
| mira | Mira | blu | warden | LibraCorp | rara | calma e attenta, divisa LibraCorp |
| rex | Rex | rosso | striker | Rondini | comune | grintoso, giacca Rondini |
| ivo | Ivo | blu | striker | Magabondi | rara | agile, look da strada |
| sera | Sera | verde | warden | Rondini | epica | elegante e serena, tratti delicati |
| eco | Eco | giallo | striker | Kairos | epica | enigmatico, dettagli dissonanti |
| tana | Tana | giallo | vanguard | LibraCorp | leggendaria | presenza imponente, protettiva |
| nico | Nico | rosso | vanguard | Kairos | epica | amico di Kira, custode del rifugio, **sciarpa rossa sempre al collo** |
| dafne | Dafne | giallo | striker | LibraCorp | leggendaria | tiratrice scelta, sguardo da cecchina, divisa operativa |
| angela | Angela | giallo | striker | LibraCorp | leggendaria | "Dea del laser orbitale": mecamante, elementi tecnologici luminosi |

## 4. I boss (8) — 3 file ciascuno, sfondo a tinta unita

Sono **oggetti reali impazziti**, riconoscibili ma con elementi "vivi" (occhi, bocche, cavi come tentacoli, schermi rotti). Ambiente notturno, neon, un che di inquietante ma giocoso, non horror crudo.

| File | Proporzione | Cosa |
|---|---|---|
| `battle.png` | **1:1** | boss intero, **base sul bordo inferiore**, centrato, rivolto verso **SINISTRA**, grande e minaccioso |
| `hurt.png` | **1:1** | **modifica di battle.png**: stessa posa e posizione, ma colpito (deformato, scintille, luci spente, crepe) |
| `portrait.png` | **5:7 verticale** | busto/primo piano del boss (il suo "volto": lo schermo, il riflettore...), ancorato in basso |

| id | Nome | Colore | Aspetto |
|---|---|---|---|
| distributore | Distributore | giallo | distributore automatico impazzito: vetro crepato, spirali come denti, braccio che sbuca dallo sportello, luce gialla malata. Il **primo boss**, chiaro e iconico |
| semaforo | Semaforo | rosso | semaforo bloccato sul rosso, luci come occhi, palo piegato, aria da predatore veloce |
| tombino | Tombino | viola | qualcosa che esce da un tombino: coperchio come bocca, vapore viola, tentacoli di tubi, massiccio e lento |
| cabina | Cabina | blu | cabina telefonica che squilla da sola: vetri come occhi, cavo del telefono come lingua, luce blu |
| ascensore | Ascensore | blu | ascensore della torre LibraCorp: porte come mascelle, piani impossibili sul display, luce fredda |
| manichino | Manichino | verde | manichino da vetrina che copia chi lo guarda: posa teatrale, giunture, vetro attorno, verde menta |
| orologio | Orologio | viola | grande orologio della torre: lancette come lame, quadrante come volto, ingranaggi, tempo fermo |
| specchio | Specchio | rosso | specchio crepato che mostra un "doppio", frantumi, riflessi rossi |

Per i boss lo sfondo a tinta unita **non deve avere il colore del boss**: usa il verde #00FF00, tranne per i boss verdi (manichino) → magenta #FF00FF.

## 5. Sfondi (questi NON hanno sfondo a tinta unita: sono l'immagine intera)

- **Battaglia: 4 strati** `layer_1..4`, proporzione **16:9**, dal piu' lontano al piu' vicino. `layer_1` e' un'immagine **piena** (cielo notturno, luna, skyline lontano). Gli strati 2, 3, 4
  (edifici medi, insegne neon, pali/fili/elementi in primo piano ai lati) vanno su **sfondo verde #00FF00 a tinta unita** (verranno resi trasparenti). L'orizzonte e' a circa un terzo dall'alto;
  la **zona centrale-bassa e a destra deve restare pulita e a basso contrasto** (li' stanno personaggi e boss). Palette: viola notte → magenta sull'orizzonte, ciano e rosa neon come accenti.
- **Hub** `hub.png`, **16:9**, immagine piena: scena notturna di citta', "quartier generale" (MISSION CONTROL). A sinistra zona calma/scura (menu e logo), interesse visivo a destra.
- **Logo** `logo.png`, proporzione **7:2 (o il piu' largo possibile)**, solo la parola **ODISPEL** in stile pop/CCTV: taglio rosso diagonale, contorno nero spesso, lettere bianche, un puntino REC rosso.
  Sfondo verde #00FF00 a tinta unita. Leggibile anche alto 100 px: niente dettagli sottili.
- **Dialoghi** (facoltativi), 16:9, immagini piene, centro basso libero: `strada_notte`, `incrocio`, `tombino`, `cabina`, `vetrina`, `torre`, `torre_orologio`.

## 6. Come si consegna e cosa succede dopo
- Mi mandi (all'umano che lavora con te) i file **uno per uno con il nome esatto** (`neutral.png`, `happy.png`, ...), organizzati per personaggio.
- Poi uno script (`tools/prepare_art.py`) toglie lo sfondo a tinta unita, porta alla misura giusta (1000x1400, 1200x1600, 480x640, 256x256, 1600x900), alleggerisce e rende
  identico il corpo delle espressioni; e `tools/check_art.py` verifica tutto.
- Se un'immagine ha un problema, l'umano ti dira' cosa correggere: **correggi solo quello** e mantieni il resto identico.

## 7. Cose da NON fare
- Non cambiare nomi, colori dello sfondo concordati, proporzioni o orientamento (verso destra per i personaggi in battaglia, verso sinistra per i boss).
- Non aggiungere testo, simboli, firme, watermark.
- Non cambiare il design di un personaggio gia' approvato.
- Non mettere piu' immagini in un unico file.
- Non usare ombre o pavimento disegnati sotto i personaggi.

## Checklist rapida per ogni immagine (controllala prima di inviarla)
- [ ] sfondo a tinta unita senza sfumature (dove richiesto), colore diverso da quello del personaggio
- [ ] nessun testo/logo/watermark/cornice
- [ ] proporzione giusta, soggetto ancorato in basso (dove richiesto)
- [ ] stesso personaggio e stesso stile di Kira
- [ ] per le espressioni: solo il volto cambia
