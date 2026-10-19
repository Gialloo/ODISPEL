# ODISPEL · Sintesi: la forma del primo gioco

Stato al 19 ottobre 2026. Documento nuovo: non sostituisce né modifica nessun file o branch esistente.

## 0. Su cosa si basa (e cosa manca)

**Letto e incrociato**
- Branch `claude/v3-prologo` (V3 0.32.0): `docs/STORIA.md`, `docs/STILE_VISIVO.md`, `docs/HANDOFF_PROLOGO_3D.md`, `README.md`.
- Branch `claude/battaglia-v2` (V2 0.29.1): `docs/ART_BIBLE.md`, `docs/DOTTRINE.md`, `docs/AUDIT_UI_UX.md`, `docs/HANDOFF_CLAUDE_0.28.11.md`, `docs/MONDO.md`.
- Branch `ccr-a679f7a6-usvtop`: `odispel_action/README.md` (action RPG, fase B).
- `PANORAMICA.md` (cartella del progetto) e la [Bibbia del mondo ODISPEL](https://claude.ai/code/artifact/6c36aab8-a29c-4fee-8249-411db351d8d7) con le sue 13 contraddizioni e le lacune.

**Non letto: le 7 conversazioni condivise.** Da questo ambiente i link `claude.ai/share/...` non si aprono (controllo anti-bot e rete bloccata). Ogni punto che dipende da loro è segnato **[DA INTEGRARE]**. La sezione 9 dice, per ognuna, cosa dovrebbe confermare o cambiare.

| # | Conversazione | Cosa aggiungerà |
|---|---|---|
| 1 | Gioco 3D story-driven simil Persona (V3) | le ragioni delle scelte V3; il codice è già nel branch e qui è coperto |
| 2 | Lore del manga dal punto di vista di Mada | il pezzo più grande che manca: la storia principale dell'universo |
| 3 | Stile visivo di partenza | la direzione originale, prima di Art Bible V2 e STILE_VISIVO V3 |
| 4 | Arco di Mada | il protagonista dell'IP, da cui dipende il legame gioco-manga |
| 5 | UI commissionate per sperimentare | le alternative di interfaccia, da confrontare con HUD V2 e V3 |
| 6 | Bozza del gioco di carte | regole e carte, da allineare con fazioni e dottrine |
| 7 | Conversazione di partenza sui videogiochi | l'intenzione originale, utile per capire cosa non si è mai perso |

---

## 1. In breve

1. **Il primo gioco di ODISPEL è la V3**: un JRPG a turni, story-driven, alla Persona, in una città notturna di oggi sigillata da una cupola rosa. È l'unica versione con una storia completa (atto 1), un tema e personaggi con un arco. V2 e Action restano miniere da cui pescare.
2. **Va ristretto**: l'atto 1 (prologo + 5 capitoli, circa 8-12 ore) diventa *il gioco intero*, un episodio che si chiude. Le 100 ore alla FFX restano il sogno per il seguito, non per il primo titolo.
3. **L'essenza della storia è lo sguardo**: chi guarda, chi viene visto, chi si nasconde. Telecamere, velo, maschere, follower, la chiamata senza risposta: tutto il materiale scritto finora parla di questo, anche quando non lo dice.
4. **Il linguaggio visivo esiste già, sparso in tre documenti**: città notturna pop di oggi (V3), poteri disegnati come luce (V2), interfaccia come occhio di sorveglianza (V2 e V3). Unito, regge da solo; manca solo di essere scritto in un posto.
5. **Tre decisioni bloccano tutto il resto**: il legame col manga di Mada, chi è il Committente, il nome della città. Le prime due dipendono dalle conversazioni che non ho potuto leggere.

---

## 2. Cosa accomuna tutto

Queste idee compaiono in ogni versione, con nomi diversi. Sono il DNA di ODISPEL e non vanno toccate.

| Invariante | V1/V2 | V3 | Action |
|---|---|---|---|
| **Urban fantasy di oggi**, città notturna | mappa 2.5D alla Gorillaz/TWEWY, 8 zone | metropoli a strati sotto la cupola | parcheggio notturno |
| **Anomalie = oggetti quotidiani posseduti** come boss | Distributore, Semaforo, Tombino, Cabina + 13 scritte | Distributore, Semaforo, Cabina, Manichino, Cassaforte, Autovelox | il Distributore spento nell'arena |
| **Lo sguardo delle telecamere** come cornice | HUD «telecamera di sorveglianza», CAM-07, il giocatore come operatore della Centrale | Echo vive nelle telecamere; la battaglia è il suo sguardo; le telecamere si incrinano coi PV | — |
| **Fazioni che si odiano** | LibraCorp, Rondini, Magabondi, Kairos | LibraCorp, Civette, Magabondi, Masca, Kairos | — |
| **Odispeller con licenza**, Magabondi fuori legge, LibraCorp paramilitare del Leviatano | `MONDO.md` | `HANDOFF_PROLOGO_3D.md` §2 | — |
| **Il colore è identità** | triangolo rosso-verde-blu + colori di fazione | colore di battaglia per personaggio, stessa ruota delle debolezze | ciano e rosso |
| **Telefono prima di tutto** | Godot gl_compatibility, Android | stesso, 60 fps, niente ombre | renderer Mobile |
| **Tono**: personaggi imperfetti, battute, cuore | operatori con ferite (Dax e Marta) | Borderlands / Suicide Squad con un cuore | — |
| **IP multi-prospettiva**: manga di Mada + giochi + carte | handoff 0.28.11 | handoff prologo §1 | — |

Una cosa che nessun documento dice ma tutti fanno: **la ferita di un personaggio diventa un mostro**. Marta che non risponde al telefono di Dax (V2) e la chiamata delle 3:12 di Nox (V3) sono la stessa idea scritta due volte. È la regola narrativa più forte che avete.

---

## 3. Cosa non torna

| Tema | Divergenza | Proposta |
|---|---|---|
| **Genere** | V1 boss co-op online, V2 turni 2D con mappa, V3 JRPG 3D a turni, Action alla Kingdom Hearts | Primo gioco = V3. Action = secondo gioco o spin-off, una volta che il mondo è fissato |
| **Cast** | 24 operatori V2 (Kira, Dax, Elle…) contro 4 protagonisti V3 + Echo | Canone = i quattro V3. Gli operatori V2 diventano comprimari, nemici o carte (sez. 7) |
| **Ruolo del giocatore** | V2: operatore neutrale della Centrale. V3: controlli il party, Echo guarda | V3. L'idea dell'operatore non va persa: è Echo (sez. 4) |
| **Brigata locale** | Rondini (V2) contro Civette (V3) | Civette nel gioco, Rondini nel manga (già deciso in V3) |
| **Kairos e Anomalie** | V2: sinonimi. V3: Kairos è la specie, le Anomalie oggetti posseduti | Kairos = la specie; Anomalia = un Kairos dentro un oggetto (proposta della Bibbia) |
| **Eco / Echo** | entrambi Kairos nati dalle linee della città | Stesso concetto: tenere Echo, archiviare Eco |
| **Direzione artistica** | quattro in una settimana: shōnen 2D lightpainting (15/10), KH + primi FF medievale (18/10 pom.), urbano moderno (18/10 sera), action «ciano e rosso» | Urbano moderno vince, ma con il lightpainting dentro (sez. 5) |
| **Palette** | V2: carbone, magenta, arancio, viola cosmico, avorio. HUD V2: ciano/rosso-arancio. V3: viola notte, cupola rosa, colori dei quattro | Unificata in sez. 5: si scopre che si incastrano |
| **Scala** | «circa 100 ore» contro un autore solo con Claude | Primo gioco = atto 1 chiuso (sez. 6) |
| **Motore** | V2/V3 gl_compatibility, Action renderer Mobile + Jolt | Restare su gl_compatibility per il primo gioco: è quello provato |

Le 13 contraddizioni di dettaglio (Echo vede la cupola o no, i follower di Rio, Nox corrotta o no, il caveau, i capelli di Lance…) sono nella Bibbia del mondo con una proposta ciascuna. Qui non le ripeto.

---

## 4. La vera essenza della storia

### Il tema: essere visti

Tutto il materiale converge su una domanda: **cosa succede quando qualcuno ti guarda davvero?**

- Il **velo** decide chi vede la magia e chi no.
- **Echo** vede tutto (142 telecamere) e non può fare niente.
- **Nox** non ha risposto alla chiamata: non si è fatta vedere quando serviva.
- **Rio** vuole essere visto (32 follower) ma solo con la maschera.
- **Lance** nasconde il braccio sotto il guanto: teme di essere visto per quello che è.
- **Saul** non sa cosa ha consegnato: non ha guardato dentro il pacco.
- La cupola li mostra su ogni schermo come colpevoli: **visti, ma sbagliati**.
- Il finale dell'atto: Lance usa il braccio davanti a tutte le telecamere del paese. Echo spegne tutte le telecamere per salvarli: **chiude gli occhi per loro**. E poi «Vi vedo. Male. Sgranati. Siete bellissimi.»

L'arco «da sconosciuti a famiglia» della V3 è la superficie; sotto, è «da sorvegliati a visti». Proposta di frase-guida per tutto l'IP: **«Il velo nasconde la magia. Le persone si nascondono da sole.»** [DA INTEGRARE: va verificato con la lore di Mada; se il manga ha un tema diverso, il gioco deve esserne un riflesso, non un doppione.]

### La struttura che funziona (da tenere)

Ogni capitolo ha lo stesso motore, e funziona:
1. un protagonista guida;
2. un oggetto della città si risveglia e **dice una cosa sola** che è la sua ferita («NESSUNO SBAGLIA. NESSUNO SI MUOVE MAI PIÙ.»);
3. gli indizi nell'area rivelano la debolezza (gioco e storia sono la stessa cosa);
4. il gruppo fa un passo verso la fiducia;
5. una serata nel rifugio lega due personaggi.

Questa è la firma narrativa di ODISPEL: **i mostri parlano in burocratese e dicono la verità sulle persone**. Va tenuta per ogni media: un capitolo di manga, una missione di un altro gioco, una carta.

### Cosa va migliorato

1. **Il patto con Echo e il Committente** (contraddizione 3 della Bibbia): oggi non si capisce chi ha pianificato cosa. Proposta: il Committente aveva il suo piano (il pacco, il sigillo); Echo l'ha visto dalle telecamere settimane prima e ci si è infilata scegliendo *chi* sarebbe stato in piazza. È un parassita del piano, non un complice. Così il tradimento finale del Committente ha senso e la colpa di Echo resta sua.
2. **La rinuncia di Echo** (contraddizione 1): nel varco il Committente le ruba già la casa, quindi la scelta finale «rinuncia per restare» è svuotata. Nel primo gioco, a scala ridotta, si può chiudere così: all'alba (cap. 5) Echo ha l'occasione di seguire il Committente nel varco, e sceglie di spegnere la città per loro. La rinuncia diventa una scelta dentro l'atto 1.
3. **Il velo** (contraddizione 5): tutti vedono la cupola e il braccio di Lance. Proposta: il velo copre la magia *degli Odispeller*; la tecnologia LibraCorp e le Anomalie lo bucano. Per questo LibraCorp è riconosciuta dalla gente e gli Odispeller no. È anche una regola utile per il manga e per le carte.
4. **Il capitolo 5** dentro l'atto 1 va tenuto, ma come epilogo del primo gioco, non come ponte verso 100 ore.
5. **Il cattivo**: oggi il Committente è una voce. Il primo gioco può chiudersi senza svelarlo, ma deve lasciare **un oggetto** che il giocatore porta via (la maschera di Rio arrivata da lui? un pezzo del pacco?) per agganciare il seguito e il manga.

### Il legame con il manga di Mada

Deciso finora: il gioco è in un **paese lontano**, Mada non compare, arrivano solo «influenze lontane»; le Rondini sono la brigata della città del manga.

Proposta di ponti possibili, tutti senza nominare Mada:
- **Il Leviatano**: fondatore di LibraCorp, citato e mai visto. Se è un personaggio del manga, il gioco ne mostra solo l'ombra.
- **Il Committente e le maschere**: se le maschere dei Masca arrivano «per posta» anche nella città del manga, il gioco mostra la stessa mano da un'altra parte del mondo.
- **Le notizie**: un TG, una radio, un cartellone che parla di «fatti in un'altra città» con le Rondini.

**[DA INTEGRARE]** Le conversazioni 2 e 4 (lore di Mada e suo arco) decidono quale di questi ponti è vero. Senza di loro, il legame gioco-manga resta la lacuna più grande.

---

## 5. Il vero linguaggio visivo

### La regola madre (unita)

> **La città è di oggi. La magia si disegna. Lo sguardo è una telecamera.**

Tre strati, ognuno preso dalla versione che l'ha fatto meglio:

| Strato | Regola | Da dove viene |
|---|---|---|
| **Persone e città** | anime moderno, occhi grandi, capelli a ciocche; cel shading a due toni con contorno scuro `#120a1c`; divise e streetwear, niente armature né mantelli; base spenta + un solo accento saturo = colore di battaglia | STILE_VISIVO V3 (aggiornamento del 18/10 sera) |
| **Magia** | «I personaggi sono disegnati con precisione. I loro poteri sono disegnati con istinto.» I poteri sono pennellate di luce nello spazio, con nucleo avorio; ogni personaggio ha una calligrafia riconoscibile anche senza colore | Art Bible V2 (15/10), già in codice in `LightPaint` |
| **Sguardo** | l'interfaccia è l'occhio di Echo: inquadrature CAM numerate, grana, telecamere che si incrinano sotto il 50% e vanno in frantumi sotto il 25%; dentro le Anomalie le telecamere non arrivano e l'interfaccia cambia | HUD V2 «sorveglianza» + V3 |

Dai riferimenti: Persona per racconto e interfaccia, TWEWY per la città e i ragazzi osservati, Star Rail per il 3D a turni, Gorillaz per il pop. Lo spirito, mai i costumi.

### La palette unificata

Messe una accanto all'altra, le palette delle tre versioni non si scontrano: ognuna ha un ruolo.

| Ruolo | Colore | Origine | Nota |
|---|---|---|---|
| Notte della città | viola notte `#120b22`, contorno `#120a1c` | V3 | il fondo di tutto |
| Superfici scure, pannelli | carbone `#171923` | Art Bible V2 | |
| **Magia e Anomalie** | magenta rituale `#E83DCE` | Art Bible V2 | **la cupola rosa è magenta**: il sigillo è la magia più grande della città |
| Profondità, sovrannaturale | viola cosmico `#7770F7` | Art Bible V2 | interni delle Anomalie |
| Impatto | arancio `#FF7438` | Art Bible V2 | frammenti dei colpi pesanti |
| Nucleo della luce | avorio `#F5E9C9` | Art Bible V2 | cuore di ogni potere e testi chiari |
| **Echo e l'interfaccia** | ciano `#3fe0ff` / `#7cf0ff` | V3 / HUD V2 | il ciano dell'HUD V2 *è* il colore di Echo: l'interfaccia era già lei |
| Pericolo, LibraCorp che caccia | rosso-arancio `#ff4630` | HUD V2 | complementare del ciano |
| I quattro | Lance `#e8343f`, Nox `#39b7ff`, Rio `#8e3df0`, Saul `#2f8f5a` | V3 | identità e ruota delle debolezze |

Due cose da sistemare: il rosso di Lance e il rosso «pericolo» sono vicini (tenere il pericolo più arancio); l'Action usa «ciano e rosso» come identità, che con questa tabella diventa «Echo contro LibraCorp» e regge.

### Cosa è superato

La direzione KH + primi FF con classi medievali (bocciata il 18/10 sera). Ne resta valida l'idea di **un oggetto riconoscibile per personaggio** (il guanto di Lance, il caffè di Nox, il telefono e la maschera di Rio, il pacco di Saul) e la pipeline 3D gratuita (TRELLIS.2 → Mixamo → Godot, ≤10.000 triangoli).

**[DA INTEGRARE]** La conversazione 3 (stile visivo di partenza) può spostare questa sezione: se lo stile originale era diverso da tutti e tre, conviene capire perché è stato abbandonato prima di fissare il canone. La 5 (UI) va confrontata con lo strato «sguardo».

---

## 6. La forma del primo gioco

### Cosa è

**ODISPEL: [titolo dell'atto]**, JRPG a turni story-driven per telefono e PC, 8-12 ore, una città, quattro ricercati, una Kairos nelle telecamere. Si chiude all'alba sulla tangenziale.

### Il ciclo di gioco (già quasi tutto nella V3)

1. **Giorno: esplorazione** di un'area della città sotto la cupola, con i commenti di Echo e gli inseguitori (Astrid, Strix) da evitare.
2. **Indizi**: oggetti dell'area che rivelano la debolezza dell'Anomalia e un pezzo della ferita del protagonista del capitolo.
3. **Dentro l'Anomalia**: un piccolo dungeon tinto del suo colore, senza telecamere: niente Echo, il gruppo è solo.
4. **Battaglia** a turni con la ruota dei colori e la telecamera che si incrina.
5. **Notte: il rifugio**, una serata tra due personaggi, un legame che cresce.

### Cosa prendere da ogni versione

| Da | Prendere | Perché |
|---|---|---|
| V3 | storia, cast, struttura dei capitoli, dialoghi alla Persona, rendering prudente, salvataggio | è il gioco |
| V2 | **dottrine di fazione** come passive dei quattro (Lance = Protocollo, Saul = Improvvisazione; Civette e Masca ne hanno bisogno di nuove); lightpainting dei poteri; 13 Anomalie già scritte per aree secondarie; audit UI (testi piccoli, daltonismo) | danno profondità al combattimento senza nuova storia |
| V2 | attacco in mappa con vantaggio a inizio battaglia (domanda rimasta aperta) | si sposa con «evitare gli inseguitori» |
| Action | separazione intento/motore, comandi touch testati | utile se un giorno il primo gioco avrà fasi d'azione o co-op |
| V1 | niente per il primo gioco | il co-op online è per un titolo futuro |

### Le dottrine mancanti (proposta)

- **Civette, Veglia** (Nox): proteggere e rispondere. Scudi, intercettare il colpo diretto a un alleato, bonus quando si agisce per ultimi nel turno. Nasce dalla ferita di Nox: questa volta risponde.
- **Masca, Maschera** (Rio): due forme, con e senza maschera. Con la maschera più danno e meno controllo; senza, meno danno e più supporto. Il capitolo 3 lo insegna.

### Cosa resta fuori dal primo gioco

Online, PvP, 24 operatori, collezione e reclutamento, atto 2. Tutto conservato nei branch.

---

## 7. Come si tiene insieme l'IP

| Media | Prospettiva | Cosa mostra dell'universo |
|---|---|---|
| **Manga** | Mada, città delle Rondini | la storia principale, gli Odispeller dall'interno [DA INTEGRARE: conv. 2 e 4] |
| **Primo gioco** | quattro ricercati in un paese lontano, con l'occhio di Echo | cosa succede ai margini: chi ha poteri senza licenza, LibraCorp vista da sotto, i Kairos |
| **Gioco di carte** | tutte le fazioni | il posto naturale per i 24 operatori V2 e le 13 Anomalie inutilizzate; fazioni = colori/mazzi, dottrine = meccaniche [DA INTEGRARE: conv. 6] |
| **Action RPG** | da decidere | un altro punto di vista (un Odispeller delle Civette? Astrid?) |

Regola dell'IP già scritta e da mantenere: **nessun media racconta tutto**. Aggiunta proposta: ogni media deve lasciare **una domanda** che un altro media risponde.

---

## 8. Decisioni che spettano all'autore

In ordine di quanto bloccano.

1. **Legame gioco-manga**: quale ponte (Leviatano, maschere, notizie). [DA INTEGRARE]
2. **Chi è il Committente** e cosa vuole dal varco.
3. **Nome della città e del paese** (oggi `[CITTÀ]`).
4. **Scala del primo gioco**: atto 1 chiuso (proposta) o tutte le 100 ore.
5. **Echo parassita del piano del Committente** o complice (proposta: parassita).
6. **Regola del velo** (proposta in sez. 4).
7. **Dottrine di Civette e Masca** (proposta in sez. 6).
8. **Palette unificata** (sez. 5): confermare o correggere.
9. **Destino degli operatori V2**: carte e comprimari (proposta) o scartati.
10. Le 13 contraddizioni di dettaglio della Bibbia, una per una.

---

## 9. Cosa cercherò nelle conversazioni quando saranno leggibili

| Conversazione | Domande precise |
|---|---|
| 1 · V3 | perché la V3 ha superato la V2; scelte rimaste a metà; idee scartate da riprendere |
| 2 · Lore di Mada | la città di Mada, cosa sa Mada di Kairos, LibraCorp, Leviatano; il ruolo delle Rondini; esiste un Committente nel manga? |
| 3 · Stile visivo | il primo look di ODISPEL; se il lightpainting nasce lì; riferimenti originali |
| 4 · Arco di Mada | tema del manga, per allineare «essere visti» o sostituirlo |
| 5 · UI | quali interfacce hanno funzionato; se confermano lo sguardo-telecamera |
| 6 · Gioco di carte | fazioni come mazzi, risorse, rapporto col combattimento a turni |
| 7 · Partenza | l'intenzione iniziale: cosa voleva essere il primo gioco prima di tutte le versioni |

Per passarle: copiare il testo di ciascuna in un file e caricarlo nel progetto, oppure caricare l'esportazione dei dati di claude.ai (contiene `conversations.json`).
