# ODISPEL V3 — Handoff stile visivo

<!-- tab: ODISPEL V3 — Handoff stile visivo -->

# ODISPEL V3 — Handoff stile visivo

2026-10-18 · @someone

## Il gioco e il tuo compito

ODISPEL V3 è un JRPG a turni in 3D, guidato dalla storia, in italiano: riferimenti di gioco Honkai Star Rail e Dragon Quest 8, riferimento di presentazione Persona 5. La versione giocabile è la 0.30.0 («OFFICIAL DEMO ODISPEL», pagina itch boomeranza/odispel), con tutto l'atto 1: prologo, quattro capitoli e finale.

Tu definisci lo **stile visivo**: personaggi, luoghi, nemici, interfaccia. Non scrivi codice. Un'altra istanza (Claude Code, sul repo del gioco) trasforma le tue scelte in grafica dentro il motore, quindi tutto quello che proponi deve stare nei vincoli tecnici della sezione dopo.

Cosa ti serve sapere in breve:

- **Direzione già decisa dal proprietario:** anime/manga semplificato, non low-poly. Personaggi leggibili da telefono, silhouette forti, un colore per personaggio.
- **Tono:** città notturna pop, colori saturi su fondo scuro, ironia. Oggetti quotidiani diventati mostri (distributore, semaforo, cabina, manichino, cassaforte).
- **Racconto:** scene di dialogo con ritratti grandi alla Persona 5, non filmati 3D. I ritratti contano quanto i modelli.
- **Il proprietario** (Gianluca) sceglie; tu proponi 2-3 direzioni chiare quando qualcosa è aperto, con il motivo, e marchi come PROVVISORIO quello che non è deciso.

## Vincoli tecnici: cosa il motore sa disegnare

Il gioco gira su telefoni Android di fascia media e su PC con Godot 4.7.2 in modalità «compatibility» (OpenGL ES 3), 1280×720 in orizzontale, 60 fps al massimo. Ogni proposta deve funzionare con queste regole; se ne serve una diversa, chiedila esplicitamente come eccezione.

| Elemento | Come funziona oggi | Cosa vuol dire per te |
| --- | --- | --- |
| Luce | Nessuna luce né ombra in tempo reale; shader «toon» fatto a mano, due toni piatti | Disegna colori piatti; l'ombra la fa il motore. Niente luci o ombre dipinte nelle texture |
| Contorno | Contorno scuro a guscio rovesciato, colore inchiostro `#120a1c` | Niente contorni dipinti; la mesh deve essere chiusa (il guscio mostra i buchi) |
| Pelle | Ombra calda dedicata alla pelle, viso senza ombre dure | Il viso resta pulito e luminoso, come negli anime |
| Bagliori | Dischi additivi trasparenti, parti «emissive» che non si ombreggiano | Luci al neon, occhi della maschera, sigilli: indica cosa brilla e di che colore |
| Sfondo | Colore pieno + nebbia nello shader, niente cielo | Il cielo è una tinta; profondità con nebbia colorata e sagome |
| Testo | Solo interfaccia 2D, nessuna scritta nel 3D | Insegne e scritte nel mondo = forme o texture, non testo vivo |
| Antialiasing | Spento su telefono | Forme grandi e decise; i dettagli sottili sfarfallano |
| Peso personaggio | Massimo 10.000 triangoli, 2 materiali, texture 1024×1024 (+ emissiva 512) | Dettaglio nel colore e nella silhouette, non nella geometria |

I personaggi a schermo sono fino a 5 (quattro eroi + nemico) in battaglia e 4 in esplorazione, con la camera alle spalle a circa 5 m: un personaggio occupa spesso 150-250 pixel di altezza. Per questo valgono le regole già date per i modelli: testa leggermente grande, silhouette riconoscibile in nero a 100 pixel, colore di battaglia dominante.

Le specifiche complete dei modelli 3D (scheletro, animazioni, shape key, nomi dei nodi) sono già scritte in `docs/HANDOFF_PERSONAGGI_3D.md` nel repo: non cambiarle senza dirlo.

## Com'è oggi la grafica

Tutto quello che si vede nel gioco è un **segnaposto fatto da codice**: forme semplici generate dal motore, colori dalle schede dei personaggi. Funziona come base di colori, proporzioni e inquadrature; la qualità la devi alzare tu.

![L'atto 1 in gioco: esplorazione, chiacchiere, battaglia, interni delle Anomalie, caveau, fine](attachment)

| Parte | Oggi | Cosa non va |
| --- | --- | --- |
| Personaggi 3D | Corpi a blocchi con testa anime (occhi grandi, viso a V, capelli a ciocche), contorno scuro | Busto e arti squadrati, mani e vestiti senza dettaglio, poca personalità nelle pose |
| Ritratti dei dialoghi | Render dei modelli 3D, 7 espressioni a testa | Sono foto dei segnaposto: vanno sostituiti da ritratti disegnati |
| Città | Strade notturne con palazzi a blocchi colorati, vetrine accese, lampioni, auto ferme | Ogni quartiere somiglia all'altro; manca un'identità del luogo |
| Interni delle Anomalie | Pavimento a griglia luminosa, detriti che galleggiano, una tinta per capitolo (rosso, blu, verde) | Vuoti e ripetitivi; non raccontano l'oggetto posseduto |
| Nemici | Oggetti quotidiani con occhi luminosi; frammenti = cubi che orbitano | Il boss in arena è piccolo; i frammenti sono generici |
| Interfaccia | Persona 5: box inclinati, contorno inchiostro, giallo/ciano/rosa su viola notte, fumetti con faccina | Funziona; da rifinire con un font e icone propri |

Modelli attuali dei quattro (fronte, tre quarti, lato, retro):

![Segnaposto 3D attuali di Ferri, Nox, Zecca, Saul](attachment)

Ritratti provvisori (neutro, felice, arrabbiato, triste, sorpreso, sfottò, serio):

![Ritratti provvisori ricavati dai modelli 3D](attachment)

Gianluca aveva già fatto un foglio di Ferri con un'altra IA. Il prototipo 3D che ne è uscito era troppo low-poly: la richiesta esplicita è stata «più anime/manga e meno low-poly».

![Il foglio di Ferri v1 mandato da Gianluca](attachment)

## I personaggi

I quattro protagonisti hanno già colori, forme e oggetti decisi; il tuo lavoro è dare loro un design vero restando dentro queste schede. Nomi, età e dettagli sono **provvisori**; il colore di battaglia no, perché nel gioco decide le debolezze. Tutti maggiorenni, nessuna sessualizzazione.

| Personaggio | Fazione · ruolo in battaglia | Colore di battaglia | Forma dominante | Indosso e oggetti | Carattere da far vedere |
| --- | --- | --- | --- | --- | --- |
| **Ferri** (uomo, 23, 1,80 m) | LibraCorp · vanguard (prima linea) | rosso `#e8343f` | quadrata, spalle larghe, rigido | Uniforme tattica blu notte `#25324f` / `#1b2236`, profili rossi, berretto con visiera e stemma a bilancia, guanto nero lungo a destra, arma LibraCorp inventata | Mascella serrata, sguardo che giudica. Segreto: braccio destro impiantato con tecnologia magica, coperto dal guanto (luci non rosse) |
| **Nox** (donna, 24, 1,70 m) | Civette (Odispeller) · warden (protegge e cura) | blu `#39b7ff` | verticale e lunga, cappotto fino alle ginocchia | Cappotto blu-viola `#3a3770` con profilo blu elettrico, distintivo con civetta, capelli blu notte `#2a2c56` con due ciuffi a orecchie di civetta, caffè da asporto | Palpebre a metà, occhiaie, «di nuovo?»; si sveglia solo quando la sorprendi |
| **Zecca** (ragazzo, 19, 1,66 m) | Masca · striker (danni) | viola `#8e3df0` | appuntita e asimmetrica | Felpa viola larga con toppe e adesivi inventati, accenti gialli `#ffd23f`, capelli bianco-lilla `#f0e6ff` a punte, sneakers bianche enormi, telefono. Maschera bianca inquietante, occhi viola luminosi, fessura gialla per bocca, **rimovibile** | Sempre in posa da diretta; senza maschera ha paura di essere nessuno |
| **Saul** (uomo, 22, 1,78 m) | Magabondi · striker (danni) | verde `#2f8f5a` | allungata e disordinata, strati larghi | Bomber verde su strati, cargo `#3d3a33`, dettagli arancio `#ff8a2b`, capelli castani `#4a2b1c` in coda, berretto di lana, anelli e amuleti, tracolla, il pacco in carta e spago | Mezzo sorriso da venditore, un occhio sempre all'uscita |

Contrasti da mostrare quando sono insieme: Ferri (ordine) contro Saul (caos); Nox (spenta) contro Zecca (elettrico).

**Personaggi senza aspetto (da proporre):**

| Personaggio | Oggi nel gioco | Cosa serve da te |
| --- | --- | --- |
| **Kairos** | Voce dalle telecamere, nome in ciano `#3fe0ff`, nessun ritratto; l'occhio della telecamera di sorveglianza in strada | Come si mostra un'entità che vive nelle telecamere: un'icona/ritratto per i dialoghi, l'aspetto dell'occhio-telecamera, eventuale forma «vera» (decisione aperta). Deve restare ambiguo: a metà gioco tradisce, alla fine resta con loro |
| **Comandante Asta** (PROVVISORIO) | Solo voce alla radio, rosso `#ff4b4b` | LibraCorp, ex istruttore di Ferri: inseguitore ricorrente nella seconda parte. Serve un design «nemico con un volto» |
| **Allocco** (PROVVISORIO) | Solo voce alla radio, blu `#3f9dff` | Civette, ex capoturno di Nox; rivale e rispettoso con Asta |
| **Il Committente** | «Voce senza volto» al telefono, grigio `#c9c3d6` | Nessun volto per ora: al massimo un simbolo o una silhouette |

Il mondo: gli **Odispeller** sono maghi con licenza, in brigate con nomi di uccelli (qui le Civette); i **Magabondi** usano magia senza licenza; la **LibraCorp** è un corpo paramilitare legale con tecnologia mezza scienza e mezza magia; i **Masca** ricevono poteri da maschere spedite per posta. Non usare le Rondini (sono di un altro media) e non far comparire Mada.

## Luoghi e nemici dell'atto 1

L'atto 1 si svolge di notte in una metropoli chiusa da una cupola rosa (nome della città ancora aperto). Ogni capitolo ha un'area esterna e, quasi sempre, l'interno dell'Anomalia: una piccola dimensione in cui si entra, come i Palazzi di Persona. Ogni luogo deve essere riconoscibile in un colpo d'occhio.

| Capitolo | Luogo | Cosa c'è oggi | Boss (colore) |
| --- | --- | --- | --- |
| Prologo · La notte della cupola | Strada del centro, poi il rifugio in un deposito della metro | Palazzi, vetrine, telecamera di sorveglianza; rifugio con archi e luce calda | Distributore automatico (giallo) |
| 1 · Rosso fisso | Incrocio Nove: auto congelate, barriera LibraCorp; dentro: Anomalia rossa | Incrocio a croce, semaforo fermo sul rosso | Semaforo (rosso) |
| 2 · La linea | Vicolo delle Civette: stretto, cabine telefoniche, manifesti da ricercati; dentro: la linea (blu) | Tutti i telefoni squillano alle 3:12 | Cabina telefonica (blu) |
| 3 · Vetrina | Galleria Lumière: negozi illuminati, manichini senza faccia; dentro: dietro il vetro (verde) | Chi entra esce senza faccia | Manichino (verde) |
| 4 · Il colpo | Caveau LibraCorp sotto la Banca Centrale: oro, laser, porta blindata | Interno con soffitto basso | Cassaforte (verde) |
| Finale · Il varco | La piazza, il varco che si apre nel cielo | Solo scena di dialogo con sfondo 2D | — |

**Nemici minori:** i «frammenti d'Anomalia», uno per colore (giallo, rosso, blu, verde), oggi cubi che orbitano attorno a un nucleo. Servono un design comune (una famiglia) che cambia col colore e con l'oggetto del capitolo.

**Regole per i boss:** sono oggetti quotidiani posseduti, non mostri organici. Devono restare riconoscibili come l'oggetto (silhouette del distributore, del semaforo…), con un «volto» fatto di luci o display, e crescere in una forma da battaglia. In arena il boss deve essere grande (oggi è troppo piccolo rispetto alla squadra).

**Sfondi delle scene di dialogo:** oggi sono illustrazioni 2D semplici fatte da codice (città, archi del rifugio, vetri, sbarre, varco). Possono diventare illustrazioni vere, una per luogo, 1920×1080, senza personaggi.

## Cosa consegnare e in che formato

Si lavora in quest'ordine, e si passa al punto dopo solo con il via di Gianluca:

1. **Guida di stile** (una pagina): 2-3 direzioni visive alternative con immagini di esempio, poi quella scelta descritta con palette in esadecimale, regole di forma, linea, ombra, proporzioni, come si leggono i colori di battaglia.
2. **Fogli dei personaggi**: i quattro protagonisti, poi Kairos, Asta, Allocco.
3. **Ritratti dei dialoghi**: 29 immagini dei protagonisti, poi gli altri.
4. **Luoghi e nemici**: un concept per area e per boss, la famiglia dei frammenti, gli sfondi delle scene.
5. **Modelli 3D** (se chi lavora può farli): secondo `docs/HANDOFF_PERSONAGGI_3D.md`.

| File | Contenuto | Misure | Formato |
| --- | --- | --- | --- |
| `stile_guida.pdf` o `.png` | La direzione scelta: palette, forme, esempi, cosa evitare | libera | PDF o PNG |
| `<id>_foglio.png` | Fronte, tre quarti, lato, retro in A-pose, stessa scala; sotto viso, oggetti separati, campioni colore con esadecimale. Luce piatta, sfondo grigio `#808080` | 4096×2048 | PNG |
| `<id>_<espressione>.png` | Ritratto da testa a fianchi, tre quarti rivolto a destra, occhi al 22-25% dall'alto, 7 espressioni: `neutro`, `felice`, `arrabbiato`, `triste`, `sorpreso`, `sfotto`, `serio` (+ `zecca_maschera`) | 1024×1536 | PNG trasparente (o verde pieno `#00FF00`) |
| `luogo_<nome>.png` | Concept di un'area o sfondo di scena, senza personaggi | 1920×1080 | PNG |
| `boss_<nome>.png` | Boss a riposo e in forma da battaglia, fronte e tre quarti | 2048×1024 | PNG su `#808080` |
| `<id>.glb` | Modello 3D completo | ≤10.000 triangoli | glTF 2.0 binario |

`<id>` = `ferri`, `nox`, `zecca`, `saul`, `kairos`, `asta`, `allocco`; tutto minuscolo, senza accenti. I ritratti devono essere **la stessa immagine con un'altra faccia**: stessa posa e inquadratura, cambia solo il viso (si fa prima `neutro`, poi si modifica quello). Le specifiche complete dei ritratti sono in `docs/HANDOFF_PORTRAIT.md`.

**Come arrivano nel gioco:** Gianluca allega uno zip per gruppo (`ferri_fase1.zip`, `portrait_demo.zip`, `luoghi_v1.zip`…) nella chat con Claude Code, che li mette in `assets/portraits/`, `assets/characters/<id>/` e simili con gli stessi nomi, e manda le schermate di come rendono sul telefono.

## Decisioni prese e domande aperte

**Già deciso, non riaprire:**

- Anime/manga semplificato con cel shading a due toni e contorno scuro; non low-poly, non realistico.
- Colori di battaglia: Ferri rosso, Nox blu, Zecca viola, Saul verde (le debolezze in battaglia ne dipendono).
- Dialoghi con ritratti alla Persona 5, non scene 3D animate; ritratti 1024×1536 con 7 espressioni.
- Città notturna pop: fondo viola notte `#120b22`, neon rosa `#ff3d8b`, ciano `#3fe0ff`, giallo `#ffd23f`, inchiostro `#120a1c`.
- Boss = oggetti quotidiani posseduti, riconoscibili come l'oggetto.
- Ispirazione, mai copia: niente costumi, loghi, marchi o personaggi esistenti; scritte solo inventate. Tutti maggiorenni.
- I vincoli tecnici della seconda sezione.

**Da proporre a Gianluca (2-3 opzioni ciascuna):**

- La direzione d'insieme: più vicina a Persona 5 (grafica, contrasti netti) o a Honkai Star Rail / Zenless Zone Zero (più pulita e morbida)?
- L'aspetto del Kairos: occhio-telecamera, figura fatta di schermi, forma umana glitchata?
- Il design di Asta e Allocco (nomi provvisori).
- Un'identità visiva per ogni fazione: LibraCorp (bilancia), Civette (civetta), Masca (maschere), Magabondi.
- Font e icone dell'interfaccia.
- Nome della città e del paese (influenza insegne e cartelli).

**Come lavorare con Gianluca:** scrivi in italiano, frasi brevi, mostra le immagini invece di descriverle. Quando scegli qualcosa per andare avanti, segnalalo come PROVVISORIO. I file del repo citati qui (`docs/HANDOFF_PERSONAGGI_3D.md`, `docs/HANDOFF_PORTRAIT.md`, `docs/STORIA.md`) non li vedi: se ti servono, chiedi a Gianluca di incollarli.

