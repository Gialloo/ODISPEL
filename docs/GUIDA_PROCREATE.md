# GUIDA PROCREATE: tutte le risorse grafiche di ODISPEL

Guida pensata per chi disegna con **Procreate su tablet**. Per ogni risorsa trovi: misura della tela, trasparenza, nome del file, come
disegnarla e come esportarla. Si basa sulle regole del gioco (versione 0.24.23). Le specifiche di stile piu' lunghe sono in
`docs/HANDOFF_ARTE_IA.md` (leggile per lo stile anime e i boss).

> **Regola d'oro:** il gioco cerca i file **per nome esatto**. Un file col nome giusto, nella cartella giusta, sostituisce il segnaposto
> automaticamente. Puoi consegnare **un file alla volta**: dove manca resta il segnaposto disegnato dal codice.

---

## 0. COSA SI PUO' SOSTITUIRE OGGI (e cosa no)

| Parte del gioco | Si puo' sostituire con le tue immagini oggi? |
|---|---|
| Personaggi (ritratti, scheda, cut-in ultimate, icona, figura in battaglia) | **SI** (10 file per personaggio) |
| Boss (in battaglia, colpito, ritratto) | **SI** (3 file per boss) |
| Sfondi di battaglia (4 strati) | **SI** |
| Sfondo del menu principale (hub) e logo | **SI** |
| Sfondi delle scene di storia | **SI** (facoltativi) |
| **HUD, pulsanti, pannelli, barre vita, icone dei comandi** | **NO, non ancora.** Oggi li disegna il codice (stile CCTV/fumetto ciano-rosso). Posso aggiungere il supporto alle tue immagini: vedi la sezione 6. **Non disegnarli finche' non te lo dico.** |

---

## 1. IMPOSTAZIONI DI PROCREATE (valgono per TUTTO)

1. **Nuova tela personalizzata** (icona + in alto a destra > icona "nuova tela" > **Personalizzata**).
   - Unita': **Pixel**. Larghezza e altezza: quelle della tabella della sezione 2.
   - **DPI: 72** (per il gioco conta solo il numero di pixel; 72 DPI ti lascia piu' livelli disponibili).
   - Profilo colore: **RGB, sRGB** (Procreate: nella nuova tela > "Profilo colore" > **sRGB IEC61966-2.1**). Evita Display P3: i colori
     nel gioco risulterebbero diversi.
   - Time-lapse: lascialo attivo se vuoi, non influisce.
2. **Sfondo trasparente**: nella tela, apri **Livelli** e **spegni il livello "Colore sfondo"** (la spunta a destra). Se la scacchiera e'
   visibile, la trasparenza c'e'. Per personaggi e boss **non dipingere mai uno sfondo colorato**.
3. **Salva sempre il file di lavoro .procreate** (e' il tuo originale, con tutti i livelli). Non esportare mai il .procreate al gioco.
4. **Esportare per il gioco**: **Azioni (chiave inglese) > Condividi > PNG**. Il PNG mantiene la trasparenza. **Non usare JPEG** (niente
   trasparenza), **non usare PSD/TIFF**. Se compare "Colore sfondo" acceso, il PNG avra' lo sfondo pieno: spegnilo prima.
5. **Nome del file**: tutto **minuscolo**, **senza spazi**, estensione `.png`. Procreate esporta con il nome della tela: rinomina il file
   nell'app **File** (tieni premuto sul file > Rinomina). Esempi corretti: `neutral.png`, `layer_2.png`. Sbagliato: `Neutral 1.png`, `kira neutral.PNG`.
6. **Niente testo dentro le immagini** (nomi, didascalie, firme): il gioco scrive i testi da solo. Niente cornici, ombre portate sullo sfondo, filigrane.
7. **Peso**: ogni PNG sotto **1,5 MB** (massimo 2,5 MB). Se e' piu' pesante: riduci i dettagli inutili o abbassa i colori sfumati superflui; evita
   texture rumorose a tutto schermo.
8. **Lato massimo 2048 px**: non andare oltre le misure della tabella ("per sicurezza" occupa memoria sul telefono).
9. **Guide utili**: Azioni > Tela > **Guida di disegno** (attivala, griglia 2D con 100 px, **Assistenza al disegno** se vuoi tracciare dritto). Nei personaggi
   attiva la guida e segna la **linea del bordo inferiore** (il personaggio deve toccarlo) e il centro verticale.
10. **Aloni chiari attorno ai capelli**: l'errore piu' comune. Dipingi il contorno **dentro** la figura (niente anti-aliasing su fondo chiaro),
    e controlla il risultato **su uno sfondo scuro** (Livelli > Colore sfondo scuro, poi spegnilo prima di esportare).
11. **Come tenere tutto uguale**: crea **una tela modello per tipo** (es. "ritratto 1000x1400") e **duplicala** (nella galleria, scorri sul file > Duplica)
    per ogni nuovo file. Cosi' misure e profilo sono sempre identici.

---

## 2. TABELLA DI TUTTE LE RISORSE (misure della tela)

| Risorsa | Nome file | Tela (px) | Sfondo | Quanti | Note rapide |
|---|---|---|---|---|---|
| Ritratto neutro | `neutral.png` | **1000 x 1400** | trasparente | 24 | busto, tocca il bordo basso |
| Altre espressioni | `happy.png` `angry.png` `sad.png` `surprised.png` `hurt.png` | **1000 x 1400** | trasparente | 24 x 5 | uguali a neutral, cambia solo il volto |
| Illustrazione scheda | `splash.png` | **1200 x 1600** | trasparente | 24 | figura intera/tre quarti, piu' ricca |
| Cut-in ultimate | `cutin.png` | **1600 x 900** | trasparente | 24 | primo piano dinamico |
| Icona | `icon.png` | **256 x 256** | trasparente | 24 | solo il volto, centrato |
| Figura in battaglia | `battle.png` | **480 x 640** | trasparente | 24 | intera, piedi sul bordo, guarda a DESTRA |
| Boss in campo | `battle.png` | **1000 x 1000** | trasparente | 18 | piedi sul bordo, guarda a SINISTRA |
| Boss colpito | `hurt.png` | **1000 x 1000** | trasparente | 18 | stessa posa di battle |
| Ritratto boss | `portrait.png` | **1000 x 1400** | trasparente | 18 | busto/dettaglio, ancorato in basso |
| Sfondo battaglia, strato 1 | `layer_1.png` | **1600 x 900** | **OPACO** | 1 (comune) | cielo e skyline lontano |
| Sfondo battaglia, strati 2-4 | `layer_2.png` `layer_3.png` `layer_4.png` | **1600 x 900** | trasparente | 3 (comuni) | edifici, neon, primo piano ai bordi |
| Sfondo del menu (hub) | `backgrounds/hub.png` | **1920 x 1080** | opaco | 1 | menu a sinistra: lato sinistro calmo/scuro |
| Logo | `logo.png` | **1000 x 280** | trasparente | 1 | solo "ODISPEL" |
| Sfondi storia (facoltativi) | `backgrounds/dialogue/<nome>.png` | **1920 x 1080** | opaco | 7 | centro in basso libero |

**Totale file attesi dal gioco: 300** (24 personaggi x 10 + 18 boss x 3 + 4 strati + hub + logo). Non servono tutti insieme.

### Struttura delle cartelle (identica a questa, nomi minuscoli)
```
art/
  logo.png
  characters/
    kira/   neutral.png happy.png angry.png sad.png surprised.png hurt.png splash.png cutin.png icon.png battle.png
    dax/    (stessi 10 file)   ...uno per personaggio
  bosses/
    distributore/   battle.png hurt.png portrait.png
    semaforo/       ...uno per boss
  backgrounds/
    hub.png
    battle/    layer_1.png layer_2.png layer_3.png layer_4.png
    dialogue/  cabina.png incrocio.png strada_notte.png tombino.png torre.png torre_orologio.png vetrina.png
```

---

## 3. PERSONAGGI: come disegnarli in Procreate

### 3.1 Prima la "scheda modello" (una per personaggio)
Una tela a parte (consigliata **2000 x 1400**, orizzontale): vista frontale, tre quarti, dettaglio del volto, **palette colori** (usa "Palette" di Procreate e
salvala col nome del personaggio). Da qui derivano **tutti** i 10 file: stessi colori, vestiti e pettinatura.

### 3.2 `neutral.png` e le altre 5 espressioni (tela 1000 x 1400)
- Dipingi **`neutral`** con questi **gruppi di livelli**: `corpo`, `capelli`, `volto` (occhi, sopracciglia, bocca), `contorni`.
- Per le altre espressioni **duplica la tela** e cambia **solo il gruppo `volto`** (occhi, sopracciglia, bocca, al massimo gocce/rossore).
  Il resto deve restare **identico al pixel**: nel gioco le espressioni si sovrappongono e non devono "saltare".
  Trucco: tieni nello stesso .procreate **un gruppo `volto` per espressione** e accendine uno alla volta, esportando ogni volta con il nome giusto.
- Espressioni: `neutral` (calmo), `happy` (sorriso), `angry` (sopracciglia basse), `sad` (occhi lucidi, sguardo in basso),
  `surprised` (occhi grandi, bocca aperta), `hurt` (smorfia; **si vede anche in battaglia quando il personaggio viene colpito**).
- Il personaggio **tocca il bordo inferiore** della tela; testa nel terzo superiore, centrata, con un po' d'aria sopra (6-10% dell'altezza).
- Posa **frontale o tre quarti verso destra**. Niente scritte addosso (a destra lo schermo lo specchia).

### 3.3 `splash.png` (tela 1200 x 1600)
Illustrazione di presentazione (scheda operatore e reclutamento): figura **intera o a tre quarti**, posa scenografica, piu' dettagli. Tocca il bordo
inferiore e riempie quasi tutta l'altezza. **Qui si vede la rarita'**: comuni semplici, rari con un accessorio in piu', epici con effetti, **leggendari** con
aura ed elementi luminosi.

### 3.4 `cutin.png` (tela 1600 x 900)
Primo piano dinamico per l'ultimate: volto e spalle, sguardo deciso, linee di velocita' e luci nella tinta del personaggio (semitrasparenti). Deve
leggersi su sfondo scuro. **Non** serve che tocchi il bordo basso.

### 3.5 `icon.png` (tela 256 x 256)
Solo il **volto**, centrato, 75-85% della tela. Il gioco la mostra a 38-56 px: contano **silhouette, colore dei capelli, occhi grandi**. Niente dettagli ai
bordi (viene ritagliata al centro). In Procreate **zooma al 25%** per controllare che si legga piccola.

### 3.6 `battle.png` (tela 480 x 640)
Figura **intera in piedi**, **piedi sul bordo inferiore**, centrata, in **posa da combattimento volta verso DESTRA** (il boss e' a destra). Il gioco la usa
piccola (~230 px di altezza): **contorni piu' spessi, forme semplici, colori ben distinti dal fondale viola scuro**. **Niente ombra a terra** (la mette il gioco).

### 3.7 Stile
Anime / visual novel a colori: tratto pulito con contorno a inchiostro, ombre a colore piatto (cel shading), luce da sinistra, **occhi grandi, lucidi, con riflessi**.
Il colore del personaggio guida la palette (capelli, accessori, iride):

| Colore | Tinta (esadecimale) | Carattere da trasmettere |
|---|---|---|
| rosso | `#ff4d6d` | diretto, energico, sguardo deciso |
| giallo | `#ffd25f` | premuroso, di sostegno, sguardo gentile |
| viola | `#b07bff` | analitico, sguardo acuto e calmo |
| verde | `#6bffb0` | preciso, vigile, sguardo concentrato |
| blu | `#5aa8ff` | rapido, brillante, sguardo vivace |

Fazioni: **LibraCorp** = divise operative sobrie, dettagli tecnici. **Rondini** = giacca/divisa **bianca**, look sportivo. **Magabondi** = abiti sciolti,
colorati e spaiati, aria di strada. **Kairos** = enigmatici, **dettagli dissonanti** (asimmetrie, glitch). Classi: **striker** = posa offensiva, arma in mano;
**vanguard** = corporatura larga, protezioni; **warden** = silhouette morbida, strumenti di aiuto.

### 3.8 I 24 personaggi
| id (nome cartella) | Nome | Colore | Classe | Fazione | Rarita' | Note per il disegno |
|---|---|---|---|---|---|---|
| `kira` | Kira | viola | striker | rondini | leggendaria | Ragazza dei vicoli che ha imparato a incanalare la magia nei pugni. Non ama le regole, ama chiudere la partita in fretta. |
| `dax` | Dax | rosso | vanguard | libracorp | comune | Ex guardia notturna: non e' il piu' veloce, ma nessuno e' mai passato oltre di lui. Si mette in mezzo per istinto. |
| `elle` | Elle | verde | warden | magabondi | comune | Studia le anomalie per capirle prima di combatterle. Porta sempre con se' un taccuino e le erbe di sua nonna. |
| `bruno` | Bruno | blu | vanguard | libracorp | comune | Tranquillo, metodico, controlla due volte ogni serratura. La sua magia costruisce barriere dove servono. |
| `nova` | Nova | giallo | striker | rondini | rara | Cacciatrice di anomalie: segna il bersaglio e lo segue finche' non cade. Lavora meglio quando il nemico e' gia' in difficolta'. |
| `mira` | Mira | blu | warden | libracorp | rara | Dice poco e nota tutto. Quando qualcuno e' maledetto o ferito, lei lo sa prima che se ne accorga lui. |
| `rex` | Rex | rosso | striker | rondini | comune | Non e' mai stato bravo a fermarsi. Combatte come se avesse sempre un tempo da recuperare. |
| `ivo` | Ivo | blu | striker | magabondi | rara | Fa tutto di corsa e in silenzio. Entra, segna il bersaglio, esce prima che il boss reagisca. |
| `sera` | Sera | verde | warden | rondini | epica | Veterana delle notti lunghe. Protegge la squadra con calma e non perde l'occasione di infierire su un nemico ferito. |
| `eco` | Eco | giallo | striker | kairos | epica | Una voce nata nei display e nelle linee della citta', che ripete cio' che sente e sta imparando cosa significa. E' dalla parte della squadra, anche se nessuno sa ancora perche'. |
| `tana` | Tana | giallo | vanguard | libracorp | leggendaria | Quando arriva lei, la strada si chiude. Leggenda di quartiere: dicono che nessuna anomalia le abbia mai fatto passare un colpo. |
| `nico` | Nico | rosso | vanguard | kairos | epica | Teneva aperto il rifugio per tutti, finche' il tempo non si e' fermato. La sciarpa rossa e' tornata con lui: dice di averla ritrovata in uno specchio. |
| `dafne` | Dafne | giallo | striker | libracorp | leggendaria | La seconda agente LibraCorp a uscire dai registri. Non parla molto: marchia, aspetta, spara una volta sola. Ogni marchio che mette sul bersaglio le fa vedere meglio il punto debole. |
| `angela` | Angela | giallo | striker | libracorp | leggendaria | Dice di parlare con un satellite. I droni le rispondono. Fragile come il vetro, ma quando il cielo si apre non resta nulla da raccogliere. |
| `moro` | Moro | rosso | vanguard | magabondi | rara | Combattente dei quartieri bassi con le fasce rituali rosse. Fa muro con il corpo e restituisce i colpi. |
| `vesper` | Vesper | viola | striker | magabondi | epica | Cacciatore di anomalie dal volto coperto. Parla poco, segue il bersaglio fino a quando cade. |
| `nami` | Nami | verde | warden | magabondi | comune | Giacca troppo grande, amuleti fatti a mano. Crede che un buon rito basti a tenere in piedi chi ami. |
| `oriel` | Oriel | blu | warden | kairos | leggendaria | Cappotto bianco e blu, aureola spezzata. Decide chi puo' passare e chi no. |
| `silex` | Silex | viola | vanguard | kairos | rara | Protezioni angolari viola e grigio grafite. Lento ma regolare: avanza e non si ferma. |
| `yuna` | Yuna | blu | striker | kairos | epica | Abiti tecnici blu elettrico, tagli asimmetrici. Arriva sempre prima del colpo. |
| `rhea` | Rhea | verde | warden | rondini | rara | Equipaggiamento da campo, tasche piene, simboli di soccorso trasformati in sigilli verdi. |
| `flux` | Flux | blu | striker | rondini | leggendaria | Cappotto nero e blu, linee luminose spezzate. Accelera, colpisce, poi si ferma a respirare. |
| `cato` | Cato | viola | vanguard | libracorp | comune | Uniforme tattica LibraCorp, viola freddo, tutto in ordine. Non e' il migliore: e' quello su cui contare. |
| `lyra` | Lyra | viola | striker | libracorp | leggendaria | Taglio elegante ma militare, viola profondo. Indica chi deve cadere, gli altri eseguono. |

(Le note vengono dalle schede del gioco. Dove e' vuoto sei libero, restando coerente con colore, fazione, classe e rarita'.)

---

## 4. BOSS (tela 1000 x 1000, ritratto 1000 x 1400)

- `battle.png` (**1000 x 1000**): il boss intero, **base sul bordo inferiore**, centrato, rivolto **a SINISTRA** (la squadra e' a sinistra). Nel gioco sta a destra,
  alto circa 460 px: grande, minaccioso, leggibile. Sono **oggetti reali impazziti**: l'oggetto deve restare riconoscibile, con elementi "vivi" (occhi, bocche, cavi come tentacoli).
- `hurt.png` (facoltativo, consigliato): **stessa tela e stessa posa** di battle, ma colpito (crepe, scintille, luci spente). In Procreate: **duplica la tela di battle** e modifica sopra.
- `portrait.png` (**1000 x 1400**): busto o dettaglio del "volto" dell'oggetto, ancorato in basso (se manca il gioco usa battle).
- Il colore dominante e' quello del boss.

| id (nome cartella) | Nome | Colore | Aspetto / spunti |
|---|---|---|---|
| `distributore` | Distributore | giallo | Un distributore automatico impazzito. Colpi pesanti a un solo bersaglio e scosse che fanno sanguinare. |
| `semaforo` | Semaforo | rosso | Un semaforo che non cambia piu' colore. Veloce: agisce prima di quasi tutti. Marchia la squadra e punta chi e' piu' ferito. |
| `tombino` | Tombino | viola | Qualcosa vive sotto il tombino. Lento ma resistente: si cura risucchiando i feriti e si chiude sotto uno scudo. |
| `cabina` | Cabina | blu | Una cabina telefonica che squilla da sola. Marchia la squadra, chiama un bersaglio con un colpo pesante e si nutre di chi e' gia' ferito. |
| `ascensore` | Ascensore | blu | L'ascensore della torre LibraCorp: sale a piani che non esistono. Porte che si chiudono su un solo bersaglio, cadute su tutta la squadra, e una manutenzione che lo protegge. |
| `manichino` | Manichino | verde | Un manichino in vetrina che copia chi lo guarda. Veloce: marchia tutti dietro il vetro, posa su un bersaglio e si nutre dei feriti. |
| `orologio` | Orologio | viola | L'orologio della torre, al centro di CAM-00. Ferma il tempo per chi lo guarda: colpi pesanti, lancette che feriscono tutti e un'ora zero che marchia la squadra. |
| `specchio` | Specchio | rosso | Lo specchio che c'era dietro l'orologio: mostra la squadra come sarebbe stata se il tempo non si fosse fermato. Un riflesso colpisce un solo bersaglio, i frantumi feriscono tutti e il doppio si nutre dei piu' deboli. |
| `sirena` | Sirena | rosso | La sirena d'allarme di Via Pia: urla da sola da tre notti. Marchia tutta la squadra, chiama un solo bersaglio con l'allarme rosso e si ripara dietro il coprifuoco. |
| `lampione` | Lampione | giallo | Un lampione di Piazza dei Salici che accende il buio invece di spegnerlo. Abbaglia un bersaglio, marchia tutti nel buio e attira le falene sui piu' feriti. |
| `bancomat` | Bancomat | verde | Un bancomat che non restituisce niente. Preleva vita ai piu' deboli, addebita commissioni a tutti e chiude la carta sotto uno scudo. |
| `scala` | Scala mobile | blu | La scala mobile della stazione, che scende anche quando sale. Un gradino mancante colpisce uno solo, la risalita ferisce tutti. |
| `radio` | Radio | viola | Una radio che trasmette voci di chi non c'e' piu'. Veloce: marchia tutti col fruscio, forza la sintonia su un bersaglio e succhia chi e' gia' a terra. |
| `metro` | Metro | rosso | Il treno fantasma dell'ultima corsa. Veloce e pesante: binario morto su un bersaglio, ultima corsa su tutti, capolinea sui piu' deboli. |
| `cassaforte` | Cassaforte | verde | La cassaforte del caveau LibraCorp. Lenta ma blindata: la combinazione marchia la squadra, la blindatura la protegge e il furto svuota i feriti. |
| `faro` | Faro | blu | Il faro del porto vecchio, che guida le navi verso gli scogli. Il fascio colpisce un solo bersaglio, la nebbia marchia tutti, il naufragio ferisce l'intera squadra. |
| `registro` | Registro | giallo | L'archivio nero di LibraCorp: dove finisce chi viene cancellato. Cancella un bersaglio, schedatura marchia tutti, l'archiviazione si nutre dei piu' deboli. |
| `eclissi` | Eclissi | viola | Il sole nero sopra i sette minuti perduti. Oscura e marchia tutti, la corona schiaccia un solo bersaglio, la penombra beve i piu' deboli e l'ora nera ferisce tutta la squadra. |


---

## 5. SFONDI

### 5.1 Battaglia: `backgrounds/battle/layer_1.png` ... `layer_4.png` (tela 1600 x 900)
4 strati che scorrono con parallasse: **1 = piu' lontano, 4 = piu' vicino**.
- `layer_1`: **opaco** (cielo notturno, luna, skyline lontano, nebbia luminosa).
- `layer_2`, `layer_3`, `layer_4`: **trasparenti** (edifici medi, insegne al neon, pali/fili in primo piano **ai lati**).
- **Composizione**: orizzonte a circa un terzo dall'alto; il suolo (asfalto bagnato) in basso. La **zona centrale-bassa e a destra** (da x = 10% a 90%, y = 40% a 85%)
  resta **pulita e a basso contrasto** (li' stanno squadra e boss). I dettagli forti vanno in alto e ai bordi.
- Palette: viola notte -> magenta sull'orizzonte, ciano e rosa neon come accenti.
- In Procreate: **un solo file .procreate con 4 gruppi** (`layer_1` ... `layer_4`); per esportare accendi un gruppo alla volta (layer_1 con un livello di sfondo opaco, gli altri
  con tutto il resto spento).
- Facoltativo: un set dedicato per un boss in `backgrounds/<id del boss>/layer_1..4.png` (ha la precedenza).

### 5.2 Hub: `backgrounds/hub.png` (1920 x 1080, opaco)
Scena notturna di citta', il "quartier generale" (MISSION CONTROL). **Il menu sta a sinistra e il logo in alto a sinistra**: tieni quella zona calma e scura; l'interesse visivo a destra.

### 5.3 Logo: `logo.png` (1000 x 280, trasparente)
La scritta **ODISPEL** in stile pop/CCTV (taglio rosso diagonale, contorno nero spesso, lettere bianche, puntino REC rosso). Alta circa 100 px nel gioco: niente dettagli sottili.

### 5.4 Scene di storia (facoltativi): `backgrounds/dialogue/<nome>.png` (1920 x 1080, opachi)
Il gioco li scurisce del 35% e ci mette sopra i ritratti. **Centro in basso libero** (casella di testo). Nomi esatti:
`strada_notte` (strada di notte), `incrocio` (incrocio col semaforo), `tombino` (strada, tombino aperto), `cabina` (cabina telefonica isolata),
`vetrina` (vetrina con manichini), `torre` (atrio/esterno della torre LibraCorp), `torre_orologio` (torre con il grande orologio).

---

## 6. HUD, PULSANTI, PANNELLI, ICONE (NON ANCORA SUPPORTATI)

Oggi tutta l'interfaccia e' disegnata dal codice: pulsanti inclinati con bordo ciano, pannelli con angoli tagliati, barre colorate, icone vettoriali
(arma, scudo, fulmine...). **Se vuoi sostituirla con i tuoi disegni, devo prima aggiungere nel gioco il caricamento delle immagini** (un lavoro dedicato:
dimmi "fai il sistema skin"). Quando sara' pronto, ti servono questi file. **Non disegnarli ora**: le misure possono cambiare in base a come lo costruiamo.

Bozza di cio' che servira' (tutto **PNG trasparente, sRGB**):

| Elemento | Misura prevista | Note |
|---|---|---|
| Pulsante (normale / premuto / disattivato) | 3 file da **384 x 96** | disegno "a 9 pezzi": i bordi restano fissi, il centro si allunga; margini 40 px |
| Pannello | **512 x 512** | angoli tagliati, margini 48 px, centro semplice (ci scrivo sopra) |
| Barra vita: cornice + riempimento | **512 x 40** (due file) | riempimento in scala di grigi (il gioco lo colora) |
| Badge rarita' (4) | **128 x 128** | comune/rara/epica/leggendaria |
| Cornice ritratto | **256 x 256** | quadrata, centro trasparente |
| Icone (arma, scudo, fulmine, ecc. ~25) | **128 x 128** | **bianche** su trasparente: il gioco le colora |
| Tasto AUTO e velocita' | **128 x 128** | stati acceso/spento |

Prima di cominciare ti mando un elenco preciso e una tavola di prova: cosi' non rifai nulla.

---

## 7. COME PROVARE LE TUE IMMAGINI NEL GIOCO

**PC (Windows)**: copia la cartella `art` **accanto a `ODISPEL.exe`**. Apri il gioco > **Impostazioni > RICARICA GRAFICHE**: in basso vedrai "GRAFICHE TROVATE x / 300".
**Telefono Android**: le immagini devono essere dentro il gioco: mandamele (zip) e le inserisco io nel progetto, poi ti preparo l'APK (arriva anche su itch.io).
**Come mandarmele**: zip della cartella `art` **sotto 30 MB** per volta (a lotti), oppure caricale su GitHub dal sito (repository > ramo `claude/battaglia-chiara` > Add file > Upload files, dentro `art/`).
**Controllo automatico**: `python3 tools/check_art.py art` (verifica nomi, misure, trasparenza, peso). Posso lanciarlo io sul tuo zip.

---

## 8. ORDINE DI LAVORO CONSIGLIATO (parti dal piu' visibile)

1. **Logo** e **sfondo hub** (si vedono subito, solo 2 file).
2. **Kira completa** (10 file): e' il banco di prova di tutto il metodo. La guardiamo insieme prima di fare gli altri.
3. **Sfondo di battaglia** (4 strati): cambia l'aspetto di ogni partita.
4. **Boss `distributore`** (3 file): il primo che si incontra.
5. Gli altri personaggi, a gruppi (prima i leggendari: tana, dafne, angela, oriel, flux, lyra), poi gli altri boss nell'ordine di gioco.
6. Sfondi di storia (facoltativi).
7. Solo alla fine, se vuoi: HUD e pulsanti (sezione 6).

Consiglio: **un personaggio alla volta, finito e provato**, meglio che 24 mezzi finiti.

---

## 9. CHECKLIST PRIMA DI ESPORTARE OGNI FILE

- [ ] Tela con la misura **esatta** della tabella, 72 DPI, profilo **sRGB**
- [ ] "Colore sfondo" **spento** (dove serve la trasparenza); nessuno sfondo dipinto su personaggi e boss
- [ ] Esportato come **PNG** (Azioni > Condividi > PNG), mai JPEG
- [ ] Nome **minuscolo, senza spazi**, nella cartella giusta
- [ ] Il personaggio **tocca il bordo basso** (ritratti, splash, battle, boss)
- [ ] `battle.png` del personaggio guarda a **destra**; il boss a **sinistra**
- [ ] Le 6 espressioni sono identiche tranne il volto
- [ ] Controllato **su fondo scuro**: niente alone chiaro attorno ai capelli
- [ ] Nessun testo, cornice, ombra a terra o firma nell'immagine
- [ ] Peso sotto 1,5 MB

## 10. DOMANDE FREQUENTI

- **Posso lavorare a risoluzione piu' alta e ridurre dopo?** Si', ma esporta alla misura esatta (Azioni > Tela > Ritaglia e ridimensiona > Ridimensiona tela, o ridimensiona prima di esportare). Il gioco riduce comunque a 2048.
- **Posso usare un altro stile?** Per i personaggi il riferimento e' lo stile anime del paragrafo 3.7: tienilo coerente tra tutti, e' piu' importante della perfezione del singolo file.
- **E se un file e' sbagliato?** Non succede nulla di grave: il gioco usa il segnaposto o mostra l'immagine adattata. Mandamelo e controllo io.
- **Le tue immagini sovrascrivono sempre i segnaposto?** Si': dove il file esiste vince il tuo.
