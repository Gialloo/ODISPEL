# Bibbia del mondo ODISPEL

<!-- tab: Bibbia del mondo ODISPEL -->

# Bibbia del mondo ODISPEL

2026-10-19 · @someone

La storia canonica oggi è quella della V3 0.32.0 (ramo claude/v3-prologo): quattro ricercati, una cupola rosa, un Kairos di nome Echo che li ha incastrati. Questo documento la raccoglie e segnala dove i file non tornano.

## Canone e fonti

Vale l'ultima parola dell'autore: la V3 0.32.0 del 19 ottobre 2026. Le versioni precedenti restano materiale da cui pescare, non canone.

| Livello | Dove sta | Stato |
| --- | --- | --- |
| Canone attuale | ramo `claude/v3-prologo`: `docs/STORIA.md`, `data/atto1.json`, `data/dialoghi_atto1.json` (testi, generati da `tools/gen_dialoghi.py`), `docs/STILE_VISIVO.md` (aggiornamento della sera del 18/10) | Vince su tutto; molte parti marcate PROVVISORIO |
| Regole del mondo e dell'IP | `docs/HANDOFF_PROLOGO_3D.md` (18/10), sezioni 1 e 2 | Valide, tranne dove STORIA.md le ha superate |
| V2 (demo a 24 operatori) | rami `claude/battaglia-v2`, `claude/docs-game-director`: `docs/MONDO.md`, `docs/DOTTRINE.md`, `docs/ART_BIBLE.md`, `scripts/story/*.gd`, `scripts/battle/lore.gd` | Altra continuità: due stagioni, Kira, Dax, Eco, i "sette minuti" |
| main | ramo `main`: 10 operatori (Kira, Dax, Elle…) e il boss Distributore | Solo meccaniche, nessuna storia |

Nel ramo `main` non c'è alcun testo di storia: il prologo e la demo V3 vivono solo su `claude/v3-prologo`, un ramo orfano senza storia comune con la V2.

## L'universo

ODISPEL è un urban fantasy ai giorni nostri, pensato come IP su più media: un manga (protagonista Mada), videogiochi e un gioco di carte. Ogni media mostra una prospettiva diversa dello stesso universo, e nessuno racconta tutto.

- **Il videogioco** è una storia a parte, in un paese lontano dal manga. Mada non compare e non va nominato; della storia principale arrivano solo influenze lontane.
- **Odispeller** sono i maghi. Per esercitare serve una licenza ottenuta con esami, e c'è un albo.
- **Il velo** separa il mondo umano da quello magico: gli umani normali non vedono demoni, maghi e magie.
- **Le brigate** di Odispeller hanno nomi di uccelli. Nella città del gioco la brigata locale sono le Civette; le Rondini sono la brigata della città del manga.
- **Magia senza licenza** è un reato: chi la pratica è un Magabondo.
- **Kairos** sono entità di un altro piano. Echo dice che «Kairos» è la sua specie; da dove viene «non ci sono telecamere, non ci sono nemmeno le forme».
- **Anomalie urbane** sono oggetti della città posseduti (distributore, semaforo, cabina…). Le più grosse hanno un interno, una piccola dimensione in cui si entra come nei Palazzi di Persona; lì dentro le telecamere di Echo non arrivano.
- **Tecnologia magica**: LibraCorp sequestra artefatti magici e li monta ai suoi agenti. Il braccio di Lance è un prototipo di questo tipo.

## Fazioni

Quattro fazioni si odiano e ognuna dà la caccia ai protagonisti; la quinta, i Kairos, è il nemico. Le dottrine vengono dalla V2 e non sono ancora nel motore V3.

| Fazione | Chi sono | Nella città del gioco | Dottrina (V2) | Volti |
| --- | --- | --- | --- | --- |
| **LibraCorp** | Corpo paramilitare fondato e finanziato dal misterioso Leviatano («un Bruce Wayne di questo universo»). Riconosciuto dallo Stato e dalla gente, combatte Anomalie, demoni e maghi con tecnologia mezza scientifica e mezza magica. Pugno di ferro; simbolo: la bilancia. | La polizia che caccia la magia. Ha un caveau sotto la Banca Centrale, paga taglie per ogni Anomalia chiusa (secondo Echo). Di giorno contiene la magia, di notte la monta ai suoi. | Protocollo: difesa, contrattacchi, munizioni, ricarica | Lance, Comandante Astrid, Marino (collega che mangia in servizio) |
| **Civette** | Brigata di Odispeller con licenza, la locale. Turni di notte, registri dei turni, capoturno. | Ricevono chiamate di soccorso notturne. Secondo Echo danno tre settimane di ferie per ogni Anomalia di classe alta chiusa. | Nessuna ancora (in V2 c'era Ronda per le Rondini) | Nox, Strix |
| **Rondini** | Brigata della città del manga. | Non vanno usate nel gioco. | Ronda: critici, danno alto, cannoni di vetro | (V2: Kira, Nova, Rex, Sera) |
| **Magabondi** | Maghi senza licenza: chi ha sbloccato i poteri da solo, chi non l'ha voluta, chi l'ha persa. Buoni, neutrali o cattivi. | Contrabbando, ricettazione, consegne senza domande. | Improvvisazione: economia delle azioni, trovate | Saul |
| **Masca** | Umani che ottengono poteri indossando maschere bizzarre spedite da mittenti misteriosi. | La maschera di Rio è arrivata per posta. In segreto, le spedisce il Committente. | Nessuna | Rio |
| **Kairos / Anomalie** | Entità di un altro piano, i «Sinistri». | Possiedono oggetti urbani e reggono la cupola. | Dissonanza: legare, indebolire, avvelenare | Echo, le Anomalie del bestiario |

## Personaggi

Quattro giovani compromessi, una Kairos che li ha usati, due inseguitori con un passato in comune e un Committente senza volto. Nel codice gli id di Lance e Rio restano `ferri` e `zecca`.

| Personaggio | Fazione | Età, altezza | Colore di battaglia | Classe | Segreto | Cosa vuole (promessa di Echo) | Ferita |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Lance** (prima Ferri) | LibraCorp, agente appena retrocesso a pattuglia | 23, 1,80 m | rosso `#e8343f` | vanguard | Braccio prototipo di tecnologia magica, sotto un guanto lungo | Chiudere il caso, nome pulito e grado | Astrid lo ha usato come cavia e lo chiama «figlio» |
| **Nox** | Civette, Odispeller del turno di notte | 24, 1,70 m, donna | blu `#39b7ff` | warden | Due anni fa, alle 3:12, lasciò squillare una chiamata di soccorso; la mattina dopo «c'era un nome in meno» | Dodici settimane di ferie: sonno | La paura di non rispondere |
| **Rio** (prima Zecca) | Masca | 19, 1,66 m, ragazzo | viola `#8e3df0` | striker | La maschera arrivata per posta | La live dell'anno sotto la cupola | Senza maschera teme di non essere nessuno |
| **Saul** | Magabondi, contrabbandiere | 22, 1,78 m | verde `#2f8f5a` | striker | Ha consegnato lui il pacco che ha acceso il sigillo, senza saperlo | Le quattro taglie LibraCorp | Tre anni di gabbia «per un pacco»; non dice cosa prova, lo fa |
| **Echo** (prima «il Kairos») | Kairos, vive nelle telecamere e nei circuiti | — | ciano `#3fe0ff` (solo dialoghi) | non giocabile | Ha incastrato lei i quattro e cancellato le prove | Tornare a casa attraverso il varco | Guarda tutto e non può fare niente |

**Lance.** Ex soldato modello, rigido perché ha paura. Disprezza la magia ma la porta attaccata alla spalla. Ha fatto 312 multe all'Incrocio Nove e ha scritto il capitolo tre di un manuale. Alla fine dell'atto usa il braccio davanti a tutte le telecamere del paese per salvare Rio e Astrid lo classifica come Anomalia.

**Nox.** Cinica e sfinita, vive di caffè, conta le ore senza dormire (da 28 a 60 nel corso dell'atto). Mangiava su un gradino del Vicolo delle Civette e dava le briciole a un gatto di nome Ricevuta. Strix l'ha cresciuta nel mestiere.

**Rio.** Veloce, sincero, dice sempre quello che sente. 32 follower, quasi tutti parenti; il suo primo video l'ha girato alla Galleria Lumière. Nel capitolo 3 si toglie la maschera davanti agli altri. Echo diventa la sua follower numero 33 e lui la salva tra i contatti col cuore.

**Saul.** Calmo, poche parole, mai un punto esclamativo. Dà un prezzo a tutto e cita nonne inventate («Ne ho tre»). Fascicolo 2219: ricettazione, truffa, un cammello. Nel capitolo 4 tiene aperta una porta blindata con il corpo per Rio e si incrina due costole.

**Echo.** Femminile, precisa (orari, numeri delle telecamere: ne ha 142), curiosa degli umani; impara a scherzare e le battute le vengono male. Era la telecamera del vicolo la notte delle 3:12 di Nox. Dopo la confessione spegne tutte le luci e telecamere della città per farli fuggire, anche se non sa se riuscirà a riaccendersi; torna nel telefono di Rio.

### Comprimari e antagonisti

- **Comandante Astrid** (prima Asta), LibraCorp. Istruttrice di Lance, ha firmato l'assegnazione del suo braccio: «L'ho costruito io». PROVVISORIO.
- **Strix** (prima Allocco), Civette. Capoturno di Nox, a modo suo la protegge. PROVVISORIO.
- Astrid e Strix erano compagni di pattuglia dieci anni fa, poi «qualcosa è andato storto». Si odiano e si rispettano.
- **Il Committente**, voce senza volto. Ha affidato il pacco a Saul, gli offre una via di fuga nel caveau e alla fine ruba il varco a Echo. Spedisce anche le maschere dei Masca (segreto non ancora mostrato).
- **Il Leviatano**, fondatore di LibraCorp. Citato solo nei documenti, non compare nell'atto 1.

## Luoghi

La città non ha ancora un nome (segnaposto \[CITTÀ\]); il paese neppure. È una metropoli a strati con quartieri, metro, tetti e sottosuolo, notturna e pop.

| Luogo | Cosa è | Capitolo | Telecamera di Echo |
| --- | --- | --- | --- |
| Piazza Centrale | Dove i quattro si incontrano alle 2:58 e dove si apre il varco | Prologo, Finale | 7 |
| La strada | Via di fuga dalla piazza, col distributore in fondo | Prologo | — |
| Il rifugio | Deposito della metro abbandonato: topi, muffa, un divano conteso, una macchinetta del caffè | Tutto l'atto | — |
| Incrocio Nove | Vecchio giro di pattuglia di Lance; il semaforo è fermo sul rosso da sei ore | 1 | 26 |
| Vicolo delle Civette | Vecchio posto di guardia di Nox, con le cabine | 2 | 31 |
| Galleria Lumière | Galleria di negozi; chi si fa un selfie resta manichino | 3 | 9, 14 |
| Caveau LibraCorp sotto la Banca Centrale | Lingotti, laser, 18 telecamere spente da Echo | 4 | — |
| Tangenziale sopraelevata | All'alba, auto abbandonate con le chiavi, cartellone dei ricercati, il casello | 5 | ponte |
| Interni delle Anomalie | Dimensioni tinte del colore dell'Anomalia (rosso, blu, verde): auto che galleggiano, mille Rio in posa | 1–3 | nessuna |

## Bestiario

Ogni Anomalia è un oggetto quotidiano posseduto che «cerca di dire una cosa sola» e rispecchia la ferita del protagonista che guida il capitolo. Regola dei colori: rosso batte verde, verde batte blu, blu batte rosso, giallo e viola si battono a vicenda (x1,5 / x0,67). Un indizio trovato nell'area rivela la debolezza.

| Anomalia | Capitolo | Colore | Teme | Indizio | Cosa dice | Specchio di |
| --- | --- | --- | --- | --- | --- | --- |
| Distributore | Prologo | giallo | viola | Scontrino: «Resto: un'anima. Monete VIOLA rifiutate.» | «INSERIRE... ANIMA.» | — (tutorial) |
| Semaforo | 1 · Rosso fisso | rosso | blu | Multa: «Esenti: veicoli di soccorso. Luce BLU.» | «NESSUNO SBAGLIA. NESSUNO SI MUOVE MAI PIÙ.» | Lance e le regole |
| Cabina | 2 · La linea | blu | verde | Adesivo: «Evitare monete VERDI.» | «LINEA OCCUPATA PER SEMPRE.», con la voce della notte delle 3:12 | Nox e la chiamata senza risposta |
| Manichino | 3 · Vetrina | verde | rosso | Cartellino: «Collezione Nessuno. Il ROSSO non è di stagione.» | «Dammi la tua faccia. Tanto non la usi.» | Rio e la maschera |
| Cassaforte | 4 · Il colpo | verde | rosso | Serratura con spia che si sblocca col rosso | «LA COMBINAZIONE È: TUTTO QUELLO CHE HAI.» | Saul e il colpo della vita |
| Autovelox | 5 · La tangenziale | giallo | viola | Verbale: foto sovraesposta da un flash VIOLA | «FUGA RILEVATA: TOTALE. SANZIONE: TUTTO.» | La fuga; è un'Anomalia nuova, nata dal crollo della cupola |
| L'Osservatore | Segreto, strada del prologo | viola | — | — | Telecamera grande quanto un lampione | Boss di prova (PROVVISORIO) |
| Frammenti | Tutte le aree | uno per colore | — | — | Anomalie minori che girano e tendono agguati | — |

In V2 esistono altre 13 Anomalie già scritte e riusabili: Tombino, Ascensore, Orologio, Specchio, Sirena, Lampione, Bancomat, Scala mobile, Radio, Metro, Faro, Registro, Eclissi.

## Cronologia

L'atto 1 dura circa due giorni e mezzo, dalle 2:58 della prima notte all'alba dopo il varco; l'orologio è il conto di Nox, da 28 a 60 ore sveglia. L'atto 1 è metà del gioco.

### Prima dell'atto 1

- **Dieci anni fa**: Astrid e Strix, compagni di pattuglia, si separano dopo un fatto mai raccontato. Saul pensa al caveau «da dieci anni».
- **Anni prima**: Saul passa tre anni in gabbia per un pacco. Lance riceve il braccio «dopo un incidente», in prova, firmato Astrid. Echo vive già nelle telecamere della città e guarda i quattro «da anni».
- **Due anni fa, ore 3:12**: Nox, sola nel Vicolo delle Civette, lascia squillare una chiamata di soccorso. Echo, telecamera 31, vede tutto.
- **Prima della notte**: la maschera arriva per posta a Rio. Il Committente affida a Saul un pacco di «documenti» da consegnare in Piazza Centrale alle tre in punto. Lance viene retrocesso a pattuglia.

### Atto 1

| Capitolo | Momento | Cosa succede | Dove arriva il gruppo |
| --- | --- | --- | --- |
| Prologo · La notte della cupola | Notte 1, 2:58–3:00 | Echo presenta i quattro. Il pacco si apre, la cupola rosa sigilla la città, gli schermi li accusano. Fuga, Distributore, poi l'accordo con Echo e il rifugio. | Diffidenza |
| 1 · Rosso fisso (guida Lance) | Giorno dopo | Semaforo all'Incrocio Nove. Il guanto si strappa: gli altri vedono il braccio e tacciono; Echo «inceppa» la registrazione. Alla radio Astrid lo vuole «vivo e in ordine». | Primo segreto custodito |
| 2 · La linea (guida Nox) | 3:12 | Tutti i telefoni squillano. Il registro rivela la notte di Nox; Strix alla radio. Nox risponde alla Cabina. Prima crepa di luce nella cupola. | Fiducia |
| 3 · Vetrina (guida Rio) | — | La chat chiede la faccia di Rio. Il Manichino gliela vuole prendere; Rio si toglie la maschera e se la tiene. | Collaborazione |
| 4 · Il colpo (guida Saul) | 42 ore | Il Committente telefona a Saul e lo tenta (scelta). L'inventario rivela che Astrid ha montato il braccio. Saul tiene la porta blindata per Rio. Vigilia: Echo quasi confessa. | Rischiare la vita |
| Finale · Il varco | Alba in piazza | Echo confessa: prove cancellate, facce messe da lei, promesse false. Il Committente ruba il varco, la cupola crolla, Lance salva Rio col braccio davanti al paese. Astrid lo classifica Anomalia. | Tradimento |
| 5 · La tangenziale | Alba, 56–60 ore | Fuga verso il casello; Autovelox. Astrid e Strix bloccano l'uscita. Echo spegne la città, i quattro scappano; Saul regala la batteria a Rio, il telefono si riaccende: «Vi vedo.» | Famiglia. «FINE DELL'ATTO 1» |

Scelte ricordate: fiducia o diffidenza verso Echo, Saul leale o tentato, tregua o rancore con Echo all'alba, i legami delle serate (sei coppie, +5% attacco).

### Il seguito (deciso, da scrivere)

1. Con la cupola caduta si apre il paese: seconda parte, la caccia al Committente.
2. LibraCorp e Civette alle calcagna; Astrid e Strix inseguitori ricorrenti, ognuno con un pezzo del passato di Lance e di Nox, a volte alleanza scomoda.
3. Finale già deciso: Echo rinuncia a tornare a casa per restare con loro.
4. Scala prevista: circa 100 ore (40–50 di storia), modello JRPG alla FFX e Dragon Quest VIII.

## Tono e voci

Il tono è Borderlands / Suicide Squad con un cuore: personaggi imperfetti e non proprio buoni, battute taglienti, contrasti netti. Il tema dell'atto 1 è «da sconosciuti a famiglia» e la frase che lo chiude è di Echo: «Le promesse erano false. Quello che è nato dopo la piazza era vero.»

| Chi | Come parla | Tic ricorrenti | Battuta tipo |
| --- | --- | --- | --- |
| Lance | Regolamento, frasi d'ordine | Articoli inventati («Articolo quarantuno»), «lo metto a verbale», chiama Rio «minorenne», conta le pagine del taccuino | «Non sono rotto, Comandante. Sono cambiato.» |
| Nox | Frasi corte, stanca, non cattiva | Le ore senza dormire, il caffè, «Bene. Benissimo.» | «Ho imparato a rispondere, Strix. E stavolta la risposta è no.» |
| Rio | Veloce, sincero | «Raga», titoli di video in MAIUSCOLO, la chat che non c'è, 32 follower, la batteria quasi a zero | «TITOLO: "La mia famiglia è assurda". Questa non la posto.» |
| Saul | Calmo, poche parole, mai un punto esclamativo | Un prezzo per tutto, «capo», «ragazzino», proverbi di nonne inventate | «Famiglia. Mia nonna diceva che costa tantissimo. Aveva ragione. E io pago.» |
| Echo | Precisa, numeri di telecamere e orari | «È l'unica cosa che so fare», battute riuscite male, «per un film» quando mente | «Vi vedo. Male. Sgranati. Siete bellissimi.» |
| Le Anomalie | Maiuscolo, linguaggio burocratico-commerciale | Rumori (*KLANG*), addebiti, sanzioni | «CHIAMATA A CARICO DEL DESTINATARIO.» |

Coppie di contrasto: Lance contro Saul (guardia e ladro), Nox contro Rio (la disillusa e il ragazzino). Lance e Rio condividono la magia addosso; Nox ed Echo l'abitudine di guardare senza poter fare niente.

## Tono visivo

Vale l'aggiornamento della sera del 18 ottobre in `docs/STILE_VISIVO.md`: urbano, ai giorni nostri, personaggi moderni e belli. Il look «classi medievali» è stato bocciato perché «sembrano usciti dal medioevo».

**Cosa vale oggi**

- Anime: occhi grandi, viso a V, capelli a ciocche; cel shading a due toni con contorno scuro (`#120a1c`).
- Vestiti di oggi: divise e streetwear. Niente armature, mantelli, elmi, mazze, cappelli da giullare, cornici gotiche.
- Base spenta + un solo accento saturo per personaggio = il suo colore di battaglia.
- Città notturna pop su viola notte `#120b22`; cielo rosa della cupola.
- Dialoghi con ritratti grandi alla Persona 5 (sette espressioni: neutro, felice, arrabbiato, triste, sorpreso, sfottò, serio).
- Boss = oggetti quotidiani posseduti. La battaglia è vista dalle telecamere: lo sguardo di Echo. Sotto il 50% dei PV la telecamera di un personaggio si incrina, sotto il 25% va in frantumi.
- Riferimenti di spirito: Persona (racconto e interfaccia), The World Ends with You (città e ragazzi osservati), Honkai: Star Rail (3D a turni), Gorillaz.
- Tutti maggiorenni, nessuna sessualizzazione.

**Segnaposto attuali (0.31.1, PROVVISORI)**

| Personaggio | Look |
| --- | --- |
| Lance | Divisa tattica LibraCorp blu notte, berretto con stemma a bilancia, gilet, fascia rossa, guanto lungo, manganello elettrico; capelli neri corti |
| Nox | Cappotto lungo delle Civette blu-viola, sciarpa, profili blu, capelli a ciuffi come orecchie di civetta, occhiaie, caffè da asporto |
| Rio | Felpa oversize viola con lacci gialli, capelli bianco-lilla a punte, sneakers grosse, telefono; maschera bianca con occhi a fessura viola e una fessura gialla al posto della bocca |
| Saul | Bomber verde su felpa grigia, cargo, berretto di lana, tracolla, il pacco avvolto in carta e spago, anelli e amuleti, occhi ambra |

**Direzioni superate** (da non seguire, ma da cui si può pescare): Art Bible V2 del 15 ottobre (shōnen 2D, lightpainting magenta `#E83DCE`, arancio, viola cosmico, avorio, carbone); HUD V2 «telecamera di sorveglianza» ciano `#7cf0ff` e rosso `#ff2d55`; versione del pomeriggio del 18 ottobre alla Kingdom Hearts / primi Final Fantasy con classi RPG.

Pipeline 3D prevista (gratuita): disegno in posa A dell'autore, modello con TRELLIS.2, scheletro e animazioni con Mixamo; massimo 10.000 triangoli, 2 materiali, texture 1024.

## Archivio V2: gli operatori (LORE)

Da `scripts/battle/lore.gd` (ramo `claude/docs-game-director`), marcata dall'autore come BOZZA da riscrivere. Sono i 24 operatori della demo V2: fuori canone V3, ma materiale per carte e comprimari. Fazioni secondo `docs/DOTTRINE.md` (V2).

| Operatore | Fazione (V2) | Chi è |
| --- | --- | --- |
| Kira | Rondini | Ragazza dei vicoli che incanala la magia nei pugni; corre sui tetti da quando aveva undici anni |
| Dax (Orsini) | LibraCorp | Sergente, ex guardia notturna; fa la guardia a Natale perché nessuno lo aspetta; ha perso la collega Marta |
| Elle | Magabondi | Studia le Anomalie con un taccuino e le erbe della nonna; cresciuta nei tunnel, trovata a otto anni |
| Eco | Kairos | Voce nata nei display e nelle linee della città, ripete ciò che sente; si unisce alla squadra |
| Nico | Kairos | Custode del rifugio, tornato da uno specchio con la sciarpa rossa |
| Dafne | LibraCorp | Agent 02, tiratrice scelta; i suoi genitori erano nel Registro |
| Angela | LibraCorp | «Orbital Laser Goddess»: parla con un satellite, i droni le rispondono |
| Bruno | LibraCorp | Metodico, controlla due volte ogni serratura; centrale radio della squadra |
| Mira | LibraCorp | Dice poco e nota tutto, sente chi è maledetto prima di lui |
| Tana | LibraCorp | Leggenda di quartiere: nessuna Anomalia le ha mai fatto passare un colpo |
| Cato | LibraCorp | Uniforme in ordine: non è il migliore, è quello su cui contare |
| Lyra | LibraCorp | Indica chi deve cadere, gli altri eseguono |
| Nova | Rondini | Cacciatrice: segna il bersaglio e lo segue finché cade |
| Rex | Rondini | Combatte come se avesse sempre un tempo da recuperare |
| Sera | Rondini | Veterana delle notti lunghe |
| Rhea | Rondini | Specialista del contenimento, sigilli verdi |
| Flux | Rondini | Accelera, colpisce, poi si ferma a respirare |
| Ivo | Magabondi | Entra, segna, esce prima che il boss reagisca |
| Moro | Magabondi | Combattente dei quartieri bassi con fasce rituali rosse |
| Vesper | Magabondi | Cacciatore di Anomalie dal volto coperto |
| Nami | Magabondi | Giacca troppo grande, amuleti fatti a mano, piccoli riti |
| Oriel | Kairos | Cappotto bianco e blu, aureola spezzata: decide chi passa |
| Silex | Kairos | Il muro viola e grafite che avanza |
| Yuna | Kairos | Arriva sempre prima del colpo |

La storia V2 collegata (due stagioni: i sette minuti del parcheggio Park 3, CAM-00 sotto la torre LibraCorp, il Piano Zero, il Progetto Kairos, il Registro sotto il molo, l'Eclissi) sta in `scripts/story/story_data.gd` e `story_season2.gd`.

## Contraddizioni

Tredici punti in cui i file non tornano, i primi quattro toccano la trama. Ognuno ha una proposta di soluzione, da confermare.

| # | Contraddizione | Dove | Proposta |
| --- | --- | --- | --- |
| 1 | Il finale deciso è «Echo rinuncia a tornare a casa per restare con loro», ma nel varco il Committente le ha già rubato il passaggio ed Echo dice «Non ho più una casa». La rinuncia è già avvenuta per forza, non per scelta. | `STORIA.md` (Il seguito) vs `dialoghi_atto1.json` (varco) | Nella seconda parte deve riaprirsi un varco, così Echo può scegliere davvero |
| 2 | Echo dice «Vedo tutta la città. Anche la cupola» e poi «Le mie telecamere guardano tutte in basso», chiedendo a Rio com'è la crepa. | accordo vs c2\_dopo | Tenere la seconda (è la scena più bella) e cambiare la prima in «vedo tutta la città, sotto la cupola» |
| 3 | Rapporto Echo–Committente: il pacco del Committente accende il sigillo, ma il piano di incastrarli è di Echo, e il varco «non era suo». Non si capisce chi ha progettato cosa né come Echo sapesse del pacco alle tre. | prologo, c4\_committente, varco | Decidere: Echo ha sfruttato un piano del Committente che conosceva dalle telecamere, oppure erano complici |
| 4 | Motivo di Echo: l'handoff del prologo dice che le servivano quattro persone di fazioni diverse; STORIA.md dice che non le servivano quattro fazioni ma quattro compromessi. | `HANDOFF_PROLOGO_3D.md` §3 vs `STORIA.md` | Vale STORIA.md; aggiornare l'handoff |
| 5 | Il velo: gli umani normali non vedono la magia, ma la cupola rosa, le facce sugli schermi e il braccio di Lance li vede «tutto il paese», e LibraCorp è riconosciuta dalla gente. | `HANDOFF_PROLOGO_3D.md` §2 vs varco | Definire cosa copre il velo (forse la magia vera, non la tecnologia e non gli effetti delle Anomalie) |
| 6 | Rio ha 32 follower «prima della maschera», ma anche dopo (vigilia), e nella serata con Nox dice «mi guardano tutti e nessuno sa chi sono». Il suo video migliore ha 20.000 visualizzazioni. | c3\_chat, c4\_vigilia, c1\_sera\_nox\_zecca | Scegliere: la maschera lo ha reso famoso (allora 32 è il prima) oppure no |
| 7 | Echo: nell'handoff è maschio («lui»), in STORIA.md è femminile. | `HANDOFF_PROLOGO_3D.md` vs `STORIA.md` | Vale femminile |
| 8 | Nox nell'handoff è corrotta, accetta mazzette, sogna di fare soldi e mollare; nei dialoghi V3 le mazzette non ci sono e il suo desiderio sono le ferie e il sonno. | handoff §3 vs dialoghi | Vale V3; decidere se la corruzione resta come tratto nascosto |
| 9 | Kairos e Anomalie: in MONDO.md e DOTTRINE.md sono la stessa cosa («Anomalie o Kairos»); in STORIA.md «Kairos» è la specie di Echo e le Anomalie sono oggetti posseduti «della stessa natura». | V2 vs V3 | Proposta: Kairos = la specie, Anomalia = un Kairos che possiede un oggetto |
| 10 | Brigata locale: in V2 sono le Rondini (Kira, Nova, Rex, Sera), in V3 le Civette e le Rondini vanno tenute fuori. | `docs/MONDO.md` V2 vs handoff V3 | Vale V3; i vecchi operatori Rondini vanno spostati o tolti |
| 11 | Il caveau LibraCorp è sotto la Banca Centrale in V3, sotto il porto in V2. La Cassaforte in V3 conserva ancora il titolo «S2 · MINACCIA ASSOLUTA» della seconda stagione V2. | `battle_content.gd` V3 | Correggere il titolo nel codice |
| 12 | Nox ed Echo hanno una serata insieme, ma tra i legami (+5% attacco) non c'è la coppia Nox–Echo. | `atto1.json` legami | Echo non combatte: dichiararlo, o dare un altro premio |
| 13 | Capelli di Lance: verdi nell'illustrazione dell'autore (ma verde è il colore di Saul), neri nel segnaposto 0.31.1. La domanda è ancora aperta in STILE\_VISIVO.md. | `STILE_VISIVO.md` vs `cast_visual.gd` | Confermare neri |

La V2 contiene anche un'intera storia alternativa (Kira, Dax, Elle, l'Anomalia Eco che si unisce alla squadra, i «sette minuti», CAM-00, Marta, Dafne, l'Eclissi). Non è una contraddizione se la V2 è dichiarata fuori canone, ma alcune idee sono doppioni della V3: Eco/Echo, la collega Marta che non rispose al telefono di Dax come la notte delle 3:12 di Nox.

## Lacune

Queste sono le decisioni che spettano all'autore prima di andare oltre l'atto 1; le prime tre bloccano manga, carte e seguito.

- [ ] **Come si lega il gioco al manga**: dove sta la città di Mada rispetto al «paese lontano», e quali «influenze lontane» arrivano. Ora nessun testo V3 le mostra.
- [ ] **Il Committente**: chi è, cosa vuole dal varco, perché spedisce le maschere dei Masca, se c'entra il Leviatano.
- [ ] **Il Leviatano**: ruolo nella trama e quando svelarlo (aperto dalla V2).
- [ ] **Nomi della città e del paese** (ora \[CITTÀ\]).
- [ ] **Cosa è successo tra Astrid e Strix** dieci anni fa («da scrivere» in STORIA.md).
- [ ] **Il mondo di Echo**: com'è casa sua, perché è bloccata qui, quanti Kairos ci sono in città, se le Anomalie la conoscono.
- [ ] **Il pacco**: cosa conteneva davvero («documenti, di un certo tipo») e come ha acceso il sigillo.
- [ ] **L'incidente di Lance** che ha giustificato il braccio, e chi era il «nome in meno» della notte di Nox.
- [ ] **Le regole della licenza**: esami, albo, cosa rischia chi la perde; come si diventa Odispeller.
- [ ] **Identità visiva**: aspetto di Echo, Astrid, Strix e del Committente; simboli e colori delle fazioni (in V2 esistono icone per LibraCorp, Rondini, Magabondi, Kairos ma non per Civette e Masca); font e icone.
- [ ] **Meccaniche di fazione in V3**: Civette e Masca non hanno dottrina; le dottrine V2 non sono nel motore V3.
- [ ] **I 24 operatori V2** (Kira, Dax, Elle…): sostituirli coi nuovi protagonisti o integrarli, e come.
- [ ] **Promesse reali o inventate**: le ferie delle Civette e le taglie LibraCorp esistono davvero o le ha inventate Echo?
- [ ] **Classi e mosse definitive** dei quattro: oggi sono provvisorie e riprese dalla V2 (Rio e Saul hanno entrambi Spezzatutto).

