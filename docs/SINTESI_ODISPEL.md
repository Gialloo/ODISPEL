# ODISPEL · Sintesi: la forma del primo gioco

Stato al 19 ottobre 2026, seconda versione (con tutte le conversazioni). Documento nuovo: non sostituisce né modifica nessun file o branch esistente.

## 0. Su cosa si basa

**Le conversazioni** (estratte in testo in `odispel/export/conversazioni/`, indice in `odispel/export/LEGGIMI.md`):

| File | Chat | Cosa ci ho trovato |
|---|---|---|
| `00_devlog_partenza.md` | ODISPEL DEVLOG, 10-18 ott, 1486 messaggi | la nascita di tutto: co-op online, telecamere di sorveglianza, fazioni, colori, font, HUD alla Metaphor, lightpainting, mappa, feedback degli amici |
| `01_v3_story_driven.md` | Gioco 3D story-driven V3 | la V3: Persona, banter, telecamera che si rompe, Echo, le promesse false, i nomi definitivi |
| `02_ip_history_stile.md` | ODISPEL L ip history | lo stile KH + primi FF dalle illustrazioni dell'autore, i modelli 3D (poi bocciato) |
| `03_stile_visivo.md` | Odispel visual style | l'avvio della ricerca sullo stile |
| `04_arco_di_mada.md` | Mada's character arc | il racconto della lore e di Mada (da cui LORE MONDO 2) e le decisioni sul gioco |
| `05_ui_anime.md` | Anime UI for Godot game | Ashen Vow: l'interfaccia anime editoriale poi usata per la schermata squadra |
| `06_gioco_di_carte.md` | ODISPEL card game | il VTCG: Leader che evolve e Pila del Destino |

**I documenti** (in `odispel/export/documenti/`): LORE MONDO 2 — Odispel e Mada, Bibbia del mondo, i due handoff di stile visivo.

**Il repository**: V3 (`claude/v3-prologo`), V2 (`claude/battaglia-v2`), action RPG (`ccr-a679f7a6-usvtop`), più `PANORAMICA.md`.

---

## 1. In breve

1. **ODISPEL ha già una spina dorsale, e l'ha trovata l'autore il primo giorno: lo sguardo.** L'11 ottobre, prima di qualsiasi storia, la telecamera del gioco era «il footage di una telecamera di sorveglianza». Da lì sono nati Echo che vive nelle telecamere, il velo che decide chi vede la magia, Malocchio e l'Eye of the Beast, e Mada che alla fine «protegge la Terra da osservatore». Lo sguardo è il linguaggio dell'intero universo.
2. **Il tema che unisce manga e gioco è l'appartenenza.** Mada vuole una vita normale e finisce dio; il Moontaker vuole un posto sulla Luna; i quattro del gioco diventano famiglia; Echo resta perché «casa è dove sono le persone a cui tieni». Il proverbio da cui nasce Mada lo dice: *«Priva un giovane del calore del villaggio e lui lo brucerà per sentirne il calore.»*
3. **Il primo gioco è la V3, ma con la presentazione della battaglia della V2.** La storia, i personaggi, il modo di raccontare e il motore a turni sono già nella V3. L'interfaccia di battaglia che l'autore ha curato di più (ruota A-S-U-G a pennellate, lightpainting, camera alla Metaphor) sta nella V2 e va portata dentro.
4. **Il primo gioco è un atto, e quello che esiste è la sua demo** (deciso dall'autore il 19/10). Il lavoro adesso è rifinirla, non allargarla. Gli archi successivi verranno dopo.
5. **Molte contraddizioni si sciolgono con la lore del manga.** Il velo che si assottiglia spiega perché tutti vedono la cupola; la LibraCorp «riconosciuta dallo Stato» suggerisce di collocare il gioco dopo l'arco 6 del manga (proposta, non confermata). Il Committente (nome provvisorio) è l'antagonista di questo gioco e **non è Malocchio**: è troppo presto per mostrarlo.

---

## 2. Cosa accomuna tutto

Queste idee tornano in ogni chat, in ogni versione e in ogni media. Sono il DNA di ODISPEL.

| Invariante | Dove nasce | Dove torna |
|---|---|---|
| **Lo sguardo / la sorveglianza** | devlog, 11/10: «le camere bloccate sono videocamere di sorveglianza, l'HUD come il Pip-Boy ma con l'aggressività di Persona» | HUD CAM-07 (V2); Echo nelle telecamere, telecamere che si incrinano (V3); il velo; Malocchio ed Eye of the Beast; Mada osservatore (manga) |
| **Urban fantasy di oggi, notturno** | devlog | tutte le versioni; la direzione medievale è stata bocciata proprio per questo |
| **Fazioni con nomi forti**: LibraCorp e Leviatano, Odispeller in brigate di uccelli, Magabondi, Masca, Kairos | devlog 12/10 | manga, gioco, carte |
| **Oggetti quotidiani posseduti come mostri** | V1 (Distributore) | V2, V3, action |
| **Il colore è identità** | devlog 12/10: cinque colori alla OPTC (rosso, giallo, viola, verde, blu) | ruota delle debolezze, colori di battaglia, aura a pennellate, carte mono e bicolore |
| **Personaggi anime con occhi espressivi** | devlog 12/10: «pochi dettagli ma buoni, attenzione sugli occhi, stile KH, Persona, FF» | ritratti alla Persona, cel shading V3 |
| **Racconto alla Persona** | devlog 12/10 | ritratti grandi, cutscene brevi, banter |
| **Personaggi imperfetti, tono con battute e cuore** | operatori V2 | Borderlands / Suicide Squad (V3) |
| **La ferita diventa un mostro** | Dax e Marta (V2) | Nox e la chiamata delle 3:12, il Semaforo di Lance (V3); le Anomalie che rispecchiano le paure dei quattro (chat 04) |
| **Telefono e PC, un autore solo** | devlog | ogni decisione tecnica |

**L'osservazione più importante:** lo sguardo non è un'idea della V3. È l'idea originale dell'autore, nata come trovata per la telecamera fissa e diventata, senza che nessuno lo dicesse, il centro di tutto l'universo: chi vede la magia, chi guarda, chi viene guardato, chi diventa l'osservatore.

---

## 3. Cosa non torna (e come si scioglie)

### Le divergenze tra versioni

| Tema | Divergenza | Proposta |
|---|---|---|
| **Genere** | V1 co-op online e PvP, V2 gacha a turni con mappa, V3 JRPG story-driven, Action alla Kingdom Hearts, Ashen Vow Wilds open world d'azione | Primo gioco = V3. Il resto diventa seguito o spin-off (sez. 7) |
| **Cast** | 24 operatori V2 contro i quattro V3 + Echo | Canone = V3. Gli operatori vanno nel gioco di carte |
| **Ruolo del giocatore** | V2: operatore della Centrale. V3: il party, con Echo che guarda | V3, deciso dall'autore nella chat 04: l'osservatore è un personaggio (Echo), non il giocatore |
| **Combattimento** | V2: ruota A-S-U-G a pennellate, camera alla Metaphor, lightpainting, turni uno alla volta. V3: motore V2 copiato con presentazione 3D nuova, telecamere che si rompono | Unire: presentazione V2 + telecamera rotta V3 (sez. 6) |
| **Stile visivo** | sei direzioni in otto giorni (sez. 5) | Una regola che le tiene tutte (sez. 5) |
| **Rondini / Civette** | V2 Rondini, V3 Civette | Civette nel gioco, Rondini nel manga (deciso) |
| **Kairos e Anomalie** | sinonimi in V2; specie e oggetti posseduti in V3 | Kairos = la specie, con stadi di crescita (Echo è piccola e può retrocedere); Anomalia = un Kairos dentro un oggetto |

### Le contraddizioni di trama che la lore del manga risolve

| Contraddizione (Bibbia del mondo) | Cosa dice la lore | Soluzione |
|---|---|---|
| **5 · Il velo**: tutti vedono la cupola, il braccio di Lance, LibraCorp | Nel manga «il velo si assottiglia sempre di più»; dopo l'arco 6 LibraCorp è riconosciuta dallo Stato e dalla gente | Proposta (non ancora confermata): il gioco si colloca **dopo l'arco 6**: il velo è già sottile, la gente comune intravede l'impossibile. Spiegherebbe anche perché LibraCorp è «la polizia della magia» e non un segreto |
| **3 · Echo e il Committente**: chi ha pianificato cosa | Chat 04: il Committente ha commissionato il pacco e spedisce le maschere; **vuole aprire del tutto il varco per fondere i due piani**; «il Kairos ha solo sfruttato la situazione». Autore, 19/10: il Committente è l'antagonista del gioco, figura ancora da decidere, **non Malocchio** | Echo è un parassita del piano del Committente, non una complice. Deciso dall'autore, va solo scritto in STORIA.md |
| **1 · La rinuncia di Echo** già forzata nel varco | Finale originale (chat 04): il varco si chiude solo usando l'energia che avrebbe riportato a casa il Kairos; lui la usa e resta | Autore, 19/10: Echo fa un **piccolo sacrificio** ma non è persa per sempre. Vedi sez. 4, «Il finale dell'atto» |
| **Committente / maschere dei Masca** | Arco 3 del manga: «chi c'è dietro le maschere?» resta aperto | Lo stesso mittente agisce nel manga e nel gioco. Il gioco mostra un pezzo della risposta senza darla tutta: è l'esempio perfetto di regola dell'IP |
| **4 · Perché proprio quei quattro** | Chat 04: «gli servivano quattro fazioni»; chat 01 (22:40): «li ha usati perché erano compromessi» | Vale la seconda, l'ultima parola dell'autore |
| **8 · Nox corrotta** | Chat 04: mazzette; chat 01: ferie e sonno | Vale la V3; la corruzione può restare come passato |

---

## 4. La vera essenza della storia

### L'universo: lo sguardo e l'appartenenza

| | Manga (Mada) | Primo gioco (i quattro) |
|---|---|---|
| **Chi guarda** | le 72 legioni che guidano Mada quando non guarda; Malocchio, l'«occhio cattivo»; gli investigatori che non chiudono mai il caso | Echo e le sue 142 telecamere; gli schermi che li accusano; la chat di Rio |
| **Chi non vuole essere visto** | Mada che usa la magia di nascosto; l'incendio rimosso | Lance e il braccio; Nox e la notte delle 3:12; Rio dietro la maschera; Saul che non guarda dentro il pacco |
| **Il velo** | si assottiglia arco dopo arco | è già sottile: la città vede la cupola |
| **Cosa cercano** | una vita normale, un posto (Mada, il Moontaker) | un nome pulito, ferie, una live, un colpo; trovano una famiglia |
| **Dove finiscono** | Mada diventa l'osservatore che protegge la Terra | Echo veglia sul gruppo dalle telecamere: «Vi vedo» |

**Frase-guida proposta per l'IP:** *«Tutti guardano. Pochi vedono.»* Il manga racconta chi impara a guardarsi dentro senza paura; il gioco racconta chi viene visto male e si fa vedere per quello che è.

**Il tema del primo gioco**, preso dalla V3 e dall'autore (chat 01, 22:25): da sconosciuti che non si fidano, a fiducia, a collaborazione, ad alleati, ad amici che rischiano la vita l'uno per l'altro, a famiglia. Le promesse di Echo erano false; quello che è nato dopo la piazza era vero.

### La struttura che funziona (da tenere)

Ogni capitolo:
1. un protagonista guida;
2. un oggetto della città si risveglia e **dice una cosa sola** che è la sua ferita;
3. gli indizi nell'area rivelano la debolezza (gioco e storia sono la stessa cosa);
4. il gruppo fa un passo verso la fiducia;
5. una serata nel rifugio lega due personaggi.

**I mostri parlano in burocratese e dicono la verità sulle persone.** È la firma narrativa di ODISPEL e funziona in ogni media.

### Raccontare senza spiegare (la regola dell'autore)

Due cose dette dall'autore vanno insieme:
- **«Servono per far vivere e sperimentare l'universo, senza spiegare tutto»** (thread, 19/10).
- **Gli amici che hanno provato il gioco «skippano sempre la storia»** e chiedono «qualcosa che mi faccia appassionare» (chat 01 e devlog, 18/10).

Quindi nel primo gioco la storia passa soprattutto da:
- **banter mentre si cammina** (fumetti alla Persona che non fermano il gioco, idea dell'autore del 18/10);
- **indizi negli oggetti** (la multa, il registro dei turni, il verbale dell'autovelox);
- **le Anomalie** che con una frase dicono la ferita di qualcuno;
- **cutscene brevi** con ritratti grandi, mai lunghe (il varco oggi supera le 40 battute: va tagliato);
- **le serate** facoltative tra due personaggi.

### Il finale dell'atto (deciso dall'autore il 19/10, dettagli da scrivere)

- **Echo fa un piccolo sacrificio, ma non è persa per sempre.** Echo è un Kairos di piccola entità, non una predatrice da agguato come i soliti Kairos. La mossa con cui salva il gruppo e lo fa scappare (oggi nella V3: spegne la città) la fa **retrocedere a uno stadio precedente** (autore, 19/10). Non muore e non sparisce.
- **L'aggancio per l'arco successivo**: i quattro dovranno fare missioni per recuperare **pezzi di artefatti e telecamere** e riportarla tra loro. È un obiettivo concreto per il seguito, e rovescia l'atto: prima era Echo a guardare loro, poi saranno loro a cercare lei.
- Questo scioglie la contraddizione 1: la scelta di Echo resta sua, e il finale «Echo rinuncia a tornare a casa per restare con loro» può arrivare più avanti, quando l'avranno riportata indietro.
- Proposta di lettura con lo sguardo: Echo si sacrifica spegnendo le telecamere, cioè i suoi occhi; ogni pezzo recuperato le restituisce un pezzo di vista. «Vi vedo. Male. Sgranati.» diventa l'inizio di un recupero, non una chiusura.
- **I momenti decisivi dei quattro** pensati il 18/10 (Lance che rifiuta l'offerta di LibraCorp e mostra il braccio da sé, Nox che potrebbe mollare e resta nelle Civette, la maschera di Rio che impara la sua faccia, Saul che lascia andare il colpo della vita ma si intasca qualcosa) vanno **al climax dell'arco di ciascun personaggio**: non dove li mostra oggi la V3 (troppo presto) né alla fine del gioco (troppo tardi) (autore, 19/10). Nella demo dell'atto restano quindi davanti, come promessa.
- **Il Committente** resta l'antagonista: una **figura nascosta con piani nascosti**, che in passato ha avuto a che fare con ognuno dei quattro e con Echo, senza che nessuno di loro lo sappia ancora (autore, 19/10). Nell'atto il suo volto non si vede. Oggi la V3 mostra già due di questi legami (il pacco di Saul, la maschera di Rio); gli altri tre (Lance, Nox, Echo) sono da scrivere e possono uscire uno per arco.

### Cosa resta aperto nella storia del gioco

- Il Committente (nome provvisorio): figura nascosta, non Malocchio. Da decidere: chi è, cosa vuole davvero, e qual era il suo legame passato con Lance, Nox ed Echo (proposte possibili: il «prototipo» del braccio di Lance; la chiamata delle 3:12 a cui Nox non rispose; il varco verso casa di Echo).
- Cosa è successo tra Astrid e Strix dieci anni fa.
- Il mondo di Echo: casa sua, perché è bloccata qui.
- Com'è Echo allo stadio precedente (cosa ricorda, come parla, cosa sa ancora fare) e quali pezzi (artefatti, telecamere) servono a riportarla.
- Il nome della città e del paese.

---

## 5. Il vero linguaggio visivo

### Le sei direzioni provate, in ordine

| Data | Direzione | Cosa resta |
|---|---|---|
| 11/10 | **Telecamera di sorveglianza**: ciano dominante, accenti aggressivi alla Persona in rosso, bianco, nero; HUD tipo Pip-Boy | lo sguardo come cornice; il ciano |
| 12/10 | **Pop, Jet Set Radio, neon**; personaggi anime con occhi espressivi alla KH, Persona, FF; ritratti grandi senza sfondo | i personaggi e i ritratti |
| 15/10 | **Art Bible: shōnen 2D e lightpainting** («il mondo è il foglio, il personaggio è il pennello, l'abilità è il tratto») | la magia |
| 16-17/10 | **Battaglia alla Metaphor e Star Rail**: ruota A-S-U-G con pennellate del colore del personaggio, oscuramento e lightpainting su skill e ultimate, frame nero con sola luce sull'ultimate; schermata squadra Ashen Vow con kanji | il combattimento |
| 18/10 pomeriggio | **KH + primi FF**: armature e classi medievali sui vestiti moderni, dalle 12 illustrazioni dell'autore | le silhouette forti, l'oggetto-simbolo per personaggio |
| 18/10 sera | **Urbano di oggi, moderni e belli**: «sembrano usciti dal medioevo» | vince su tutto |

Il filo che non si è mai spezzato: **anime espressivo, cel shading, città notturna pop, il colore come identità, la telecamera come occhio**. Le direzioni scartate hanno cambiato i costumi, mai questo.

### La regola madre

> **La città è di oggi. La magia si disegna con la luce. Lo sguardo è una telecamera.**

| Strato | Regola | Da dove |
|---|---|---|
| **Persone e città** | anime moderno, occhi grandi ed espressivi, capelli a ciocche; cel shading a due toni con contorno scuro `#120a1c`; divise e streetwear; base spenta + un solo accento saturo = colore di battaglia; un oggetto-simbolo per personaggio (guanto, caffè, maschera e telefono, pacco) | STILE_VISIVO V3 + devlog 12/10 + KH/FF |
| **Magia** | «I personaggi sono disegnati con precisione. I loro poteri sono disegnati con istinto.» La luce è l'evento eccezionale, non tutto al neon. Le pennellate escono dal personaggio, nel suo colore, e diventano lightpainting quando il potere cresce | Art Bible V2 + battaglia V2 |
| **Sguardo** | l'interfaccia è l'occhio di Echo: inquadrature CAM numerate, grana, la telecamera di un personaggio si incrina sotto il 50% e va in frantumi sotto il 25%; dentro le Anomalie le telecamere non arrivano e l'interfaccia cambia | idea dell'autore dell'11/10 + V3 |

### Palette

| Ruolo | Colore | Origine |
|---|---|---|
| Notte della città | viola notte `#120b22`, contorno `#120a1c` | V3 |
| Pannelli | carbone `#171923` | Art Bible |
| **Magia e Anomalie** | magenta rituale `#E83DCE`: **la cupola rosa è magenta** | Art Bible |
| Profondità, interni delle Anomalie | viola cosmico `#7770F7` | Art Bible |
| Impatto | arancio `#FF7438` | Art Bible |
| Nucleo della luce, testi chiari | avorio `#F5E9C9` | Art Bible |
| **Echo e l'interfaccia** | ciano `#3fe0ff` / `#7cf0ff`: il ciano «dominante» scelto dall'autore l'11/10 è diventato il colore di Echo | devlog + V3 |
| Pericolo | rosso-arancio `#ff4630` | HUD V2 |
| I cinque colori di battaglia | rosso, giallo, viola, verde, blu (OPTC); i quattro: Lance `#e8343f`, Nox `#39b7ff`, Rio `#8e3df0`, Saul `#2f8f5a` | devlog + V3 |

### Tipografia (scelta dall'autore il 13/10)

| Uso | Font |
|---|---|
| Titolo ODISPEL, nomi dei personaggi | Libre Caslon, maiuscolo grassetto |
| Titoli, boss, sezioni | Archivo Black, maiuscolo |
| HUD, statistiche, timer | Roboto, maiuscolo |
| Dialoghi e descrizioni | Merriweather |

Ashen Vow (chat 05) aggiunge il registro «editoriale»: pannelli angolari sovrapposti, asimmetria controllata, kanji di fondo, grana. Va usato per menu e schede, non per la battaglia.

### Cosa è superato

La direzione KH + primi FF con classi medievali. Restano valide le silhouette forti e la pipeline 3D gratuita (TRELLIS.2 → Mixamo → Godot, ≤10.000 triangoli). Meshy è stato scartato perché a pagamento.

---

## 6. La forma del primo gioco

### Cosa è

**ODISPEL: [titolo dell'atto]**, JRPG a turni story-driven per telefono e PC: **un atto**, una città sotto una cupola rosa, quattro ricercati, una Kairos nelle telecamere. Si chiude all'alba sulla tangenziale, con il sacrificio di Echo.

Quello che esiste oggi (V3 0.32.0) è **la demo di questo atto, da rifinire** (autore, 19/10). Rifinire significa, in ordine: dialoghi e ritmo (il varco troppo lungo, le battute ancora poco umane), battaglia (sotto), prova su un telefono vero, le correzioni aperte in `PANORAMICA.md` (ripresa a metà area, avviso dell'Osservatore, chiave di firma).

### Il ciclo di gioco

1. **Esplorazione** di un'area della città, con il banter del party e i commenti di Echo; gli inseguitori (Astrid, Strix) da evitare. Il sogno dell'autore: «che il giocatore si diverta a passeggiare in giro per la mappa, anche senza uno scopo».
2. **Attacco in mappa** per entrare in battaglia con un piccolo vantaggio (chiesto dagli amici, alla Star Rail).
3. **Indizi** che rivelano la debolezza dell'Anomalia e la ferita del protagonista.
4. **Dentro l'Anomalia**: piccolo dungeon tinto del suo colore, senza Echo.
5. **Battaglia** a turni (sotto).
6. **Rifugio**: serata tra due personaggi, legame che cresce.

### La battaglia: unire V2 e V3

L'autore l'ha chiamata «il punto più importante del gioco su cui investire tutto il budget» (devlog, 17/10). La versione più curata è nella V2; la V3 ha aggiunto la telecamera che si rompe. Proposta:

| Elemento | Da |
|---|---|
| Turni uno alla volta per velocità, l'azione si risolve appena confermata | V2 (17/10), già nella V3 (motore `SeqRound` copiato) |
| Camera che passa al personaggio attivo con disposizione spaziale alla Metaphor | V2 (17/10) |
| Ruota A-S-U-G (Attacco, Skill, Ultimate, Guardia) attorno al personaggio, pennellate animate del suo colore, al posto dei pulsanti attuali della V3 | V2 (16-17/10) |
| Skill e Ultimate: oscuramento e lightpainting; Ultimate lanciata = due frame neri con sola luce del colore del personaggio | V2 (17/10) |
| Ordine dei turni con ritratti decrescenti, numero del turno, limite di turni | V2 (16/10) |
| Ruota dei colori e debolezze rivelate dagli indizi | V2 + V3 |
| Telecamera del personaggio incrinata sotto il 50% e in frantumi sotto il 25%; break del boss come lampo di rottura che non resta | V3 (18/10) |
| Dottrine di fazione come passive | V2 (Protocollo, Improvvisazione) + nuove per Civette e Masca |

**Dottrine nuove (proposta):**
- **Civette, Veglia** (Nox): proteggere e rispondere; intercettare un colpo diretto a un alleato; bonus quando si agisce per ultimi nel turno.
- **Masca, Maschera** (Rio): due forme. Con la maschera più danno e meno controllo; senza, meno danno e più supporto. Il capitolo 3 la insegna; il finale la trasforma (la maschera che ha imparato la sua faccia).

### Cosa prendere da ogni versione

| Da | Prendere |
|---|---|
| V3 | storia, cast, capitoli, dialoghi alla Persona, banter, rendering prudente, salvataggio |
| V2 | presentazione della battaglia, dottrine, lightpainting, mappa 2.5D esplorabile, schermata squadra Ashen Vow, 13 Anomalie già scritte, font |
| Action | separazione intento/motore, comandi touch testati (per un seguito d'azione o co-op) |
| V1 | niente per il primo gioco: co-op online e PvP sono per un titolo futuro |

### Cosa resta fuori dal primo gioco

Gacha, collezione e reclutamento, 24 operatori, online, PvP, modalità roguelike, atto 2. E, per scelta dell'autore (chat 04): frammenti di profezia da collezionare e un gioco di carte interno.

---

## 7. Come si tiene insieme l'IP

**Regola dell'autore (19/10):** le storie sono separate ma nello stesso universo; ogni medium fa vivere e sperimentare il mondo in una forma diversa, senza spiegarlo. Ogni media è completo da solo; chi ne conosce più di uno vede più facce dello stesso mondo e si fa le sue teorie.

| Media | Cosa fa provare | Elementi del mondo che mostra |
|---|---|---|
| **Manga** (Mada, città delle Rondini) | crescere con un potere che fa paura; la scuola di magia, le brigate, la profezia | Odispeller dall'interno, Leviatano e LibraCorp prima e dopo la redenzione, Bestie, Masca, Moontakers, Shadow Workers, Neden, Malocchio |
| **Primo gioco** (i quattro, paese lontano; momento della cronologia da confermare) | essere braccati e osservati ai margini; diventare famiglia | Civette, Magabondi, Masca e le maschere, LibraCorp riconosciuta, Kairos e Anomalie, il Committente |
| **Gioco di carte** (VTCG) | **il destino che si può cambiare** | tutte le fazioni e i colori; i 24 operatori V2 e le Anomalie non usate; la profezia frammentata |
| **Action RPG** | da decidere | proposta: un altro punto di vista, per esempio un'Odispeller delle Civette o un agente di Astrid |

### Il gioco di carte e il tema del destino

Il VTCG (chat 06) ha già due idee che parlano col manga:
- **il Leader che evolve** per livelli e percorsi alternativi: come Mada, cresce in consapevolezza più che in potenza;
- **la Pila del Destino**, dieci carte che il giocatore può manipolare: è la profezia di Mada («tutto sembra già scritto, ma con impegno si può cambiare il destino») trasformata in regola.

La proposta di Claude in quella chat (ogni carta Destino ha un effetto e un Presagio; se il Presagio si avvera la carta si compie e porta il Leader verso una forma diversa) rende giocabile proprio questo. **La profezia frammentata, esclusa dal videogioco, ha la sua casa naturale nelle carte**: ogni carta Destino può portare un frammento.

Colori: i cinque colori OPTC del gioco possono essere i colori delle carte, con le fazioni come identità dei mazzi. Resta aperta la prima domanda posta da Claude: il Leader attacca (Vanguard) o è un avatar con punti vita (Shadowverse)?

### La cronologia (proposta, non confermata dall'autore)

| Momento | Manga | Gioco |
|---|---|---|
| Anni prima | incendio, rapimento del futuro Leviatano | Astrid e Strix si separano; Saul in gabbia; Lance riceve il braccio |
| Archi 1-5 | Bestie, scuola, Masca, LibraCorp, Moontakers | — |
| Arco 6 | LibraCorp spazza via i Moontakers ed è riconosciuta dallo Stato; il velo sparisce sempre più | — |
| **Dopo l'arco 6** | Shadow Workers, Neden, finale | **il primo gioco** nel paese lontano |

Le maschere dei Masca arrivano nella città di Mada (arco 3) e in quella del gioco: lo stesso mittente, mai svelato del tutto.

---

## 8. Decisioni che spettano all'autore

In ordine di quanto bloccano.

Già deciso il 19/10: il primo gioco è un atto e la demo va rifinita; Echo, Kairos di piccola entità, retrocede a uno stadio precedente per salvarli e verrà recuperata nell'arco successivo; il Committente è l'antagonista, figura nascosta che ha già incrociato tutti, e non è Malocchio; i momenti decisivi dei quattro vanno al climax dei loro archi.

1. **Chi è il Committente**: identità, nome e il legame passato con ciascuno dei quattro e con Echo.
2. **Echo retrocessa**: com'è allo stadio precedente e quali pezzi servono a riportarla.
3. **Collocare il gioco dopo l'arco 6 del manga** (proposta, non confermata): spiega velo e LibraCorp.
4. **Battaglia V2 dentro la V3** (sez. 6).
5. **Nome della città e del paese** (oggi `[CITTÀ]`).
6. **Dottrine di Civette e Masca** (sez. 6).
7. **Gioco di carte**: Leader che attacca o avatar; profezia frammentata nelle carte Destino.
8. **Destino degli operatori V2**: nel gioco di carte (proposta).
10. Le contraddizioni minori rimaste nella Bibbia (follower di Rio, capelli di Lance, titolo della Cassaforte, legame Nox-Echo, caveau).

---

## 9. Dove trovare le cose

- Conversazioni in testo: `odispel/export/conversazioni/` (indice in `odispel/export/LEGGIMI.md`).
- Lore del manga completa: `odispel/export/documenti/LORE_MONDO_2_Odispel_e_Mada.md`.
- Storia del gioco V3: `docs/STORIA.md` sul branch `claude/v3-prologo`.
- Battaglia V2: `scenes/battle_v2/` sul branch `claude/battaglia-v2`.
- Gioco di carte: `odispel/export/conversazioni/06_gioco_di_carte.md`.
