# ODISPEL — Handoff: i 4 protagonisti in 3D

> **SUPERATO IN PARTE (18 ottobre 2026):** lo stile e la pipeline definitivi sono in `docs/STILE_VISIVO.md`, che vince su questo file.
> Cambiano: l'aspetto dei personaggi (classi RPG: Ferri cavaliere dal disegno dell'autore, gli altri PROVVISORI), la pipeline
> (TRELLIS.2 + Mixamo, gratuita), le animazioni minime (7 invece di 11) e i nomi delle ossa (quelli di Mixamo, vedi in fondo).
> Restano validi: scala e orientamento, limiti di peso (10.000 triangoli, 2 materiali, texture 1024), colori piatti, mesh chiusa.

Destinatario: un'IA (o un artista) che deve disegnare e modellare i quattro protagonisti del videogioco ODISPEL.
Scritto il 18 ottobre 2026 per Gianluca (l'autore). Lingua: italiano.
Nel gioco oggi ci sono **segnaposto** fatti di forme semplici: le foto sono in `docs/ref_personaggi/` (fronte, tre quarti, lato, retro).
Servono come riferimento di **colori, proporzioni e silhouette**, non di qualità: il tuo lavoro deve sostituirli.

Il lavoro si fa in **due fasi**. Non passare alla fase 2 senza il via di Gianluca.
1. **Fase 1 · Concept (immagini 2D):** fogli di presentazione e ritratti. Gianluca li approva o chiede modifiche.
2. **Fase 2 · Modelli 3D:** un file `.glb` per personaggio, con scheletro e animazioni, secondo le specifiche tecniche sotto.

Se puoi produrre solo immagini, fai la fase 1 seguendo alla lettera le regole dei fogli di presentazione: verranno usati
per ricavare i modelli 3D (anche con strumenti immagine→3D), quindi luce piatta e pose pulite contano più dello spettacolo.

---

## 1. Il gioco in breve

- **Genere:** gioco di ruolo a turni, story driven, in 3D (modello Honkai: Star Rail e Dragon Quest VIII).
  Esplorazione in terza persona con la camera alle spalle, combattimenti a turni con inquadrature dinamiche e ultimate cinematiche.
- **Dove gira:** telefoni Android di fascia media e PC. Il 3D è leggero: questo pesa sulle specifiche tecniche.
- **Ambientazione:** una metropoli moderna di notte, chiusa da una cupola. Neon, vetrine, lampioni, asfalto bagnato di luce.
- **Il mondo:** esiste un velo che nasconde la magia agli umani normali. Ci sono maghi con licenza (**Odispeller**, divisi in brigate
  con nomi di uccelli: in questa città le **Civette**), maghi abusivi (**Magabondi**), un corpo paramilitare temuto
  (**LibraCorp**, tecnologia mezza scienza e mezza magia) e i **Masca**, ragazzi che ottengono poteri da maschere spedite da mittenti misteriosi.
- **Tono:** stile Borderlands / Suicide Squad. Quattro giovani imperfetti e non proprio buoni, battute taglienti, ma con un cuore.

## 2. Lo stile visivo

- **Look:** anime / cel shading 3D pulito, di qualità vicina a Honkai: Star Rail o Zenless Zone Zero, con l'attitudine grafica pop
  di Gorillaz e The World Ends With You: colori forti, forme decise, un po' di street.
- **Ispirazione, non copia:** nessun costume, acconciatura, logo o arma presi da personaggi esistenti. Niente marchi reali.
  Scritte e simboli solo inventati.
- **Proporzioni:** giovani adulti, **6,5–7 teste** di altezza (testa leggermente grande, si deve leggere su un telefono).
  Gambe lunghe, mani e piedi un po' più grandi del realistico.
- **Età:** tutti **maggiorenni**, tra 19 e 24 anni (età provvisorie sotto). Nessuna sessualizzazione.
- **Silhouette:** i quattro devono essere riconoscibili **anche in nero pieno, alti 100 pixel**. Ognuno ha una forma dominante (vedi schede).
- **Colore di battaglia:** ognuno ha un colore che nel gioco conta (le debolezze in combattimento dipendono dal colore).
  Deve essere l'**accento dominante** e visibile da lontano: Ferri **rosso**, Nox **blu**, Zecca **viola**, Saul **verde**.
- **Nel gioco** il modello viene ombreggiato a due toni piatti con un contorno scuro (inchiostro `#120a1c`) disegnato dal motore:
  **non disegnare contorni nella texture** e **non dipingere luci o ombre** nella texture (solo colori piatti, al massimo leggere sfumature sui capelli).
- **Sfondo di riferimento** del gioco: notte viola `#120b22`, neon rosa `#ff3d8b`, ciano `#3fe0ff`, giallo `#ffd23f`. I personaggi devono staccarsi da lì.

## 3. I quattro protagonisti

Nomi, età e dettagli sono **provvisori**. Le parti marcate SEGRETO non vanno mostrate nei concept pubblici
né devono intuirsi dal modello di base: servono solo per preparare il file.

### Ferri — LibraCorp — colore ROSSO — 1,80 m — 23 anni
- **Chi è:** ex soldato modello della LibraCorp, retrocesso. Parla per regolamenti e disprezza la magia. Ipocrita e autoritario.
- **Forma dominante:** **quadrata**. Spalle larghe, postura rigida, tutto in ordine.
- **Indosso:** uniforme tattica blu notte (`#25324f`, `#1b2236`) con dettagli **rossi** (`#e8343f`): fascia al braccio, profili, gradi strappati.
  Berretto con visiera, anfibi, cintura con porta caricatori, una placca sul petto. Un'arma della LibraCorp di forma inventata (fucile o pistola tecnologica).
- **Mano destra:** sempre **guantata**, guanto lungo fino al gomito.
- **SEGRETO:** sotto il guanto e la manica ha un **braccio impiantato con tecnologia magica di contrabbando**. Prepararlo come mesh separata nascosta (vedi 6).
- **Espressione tipo:** mascella serrata, sguardo che giudica.

### Nox — Civette (Odispeller) — colore BLU — 1,70 m — 24 anni
- **Chi è:** Odispeller del turno di notte, cinica, sfinita, vive di caffè. Accetta mazzette e chiude un occhio.
- **Forma dominante:** **verticale e lunga**. Cappotto lungo fino alle ginocchia che si apre quando si muove.
- **Indosso:** cappotto delle Civette blu-viola (`#3a3770`, `#24224a`) con dettagli **blu elettrico** (`#39b7ff`), distintivo da Odispeller
  con un simbolo di civetta inventato. Capelli scuri (`#2a2c56`) con **due ciuffi in alto che ricordano le orecchie di una civetta**. Occhiaie.
- **Oggetto:** un **bicchiere di caffè da asporto** sempre in mano (mesh separata).
- **Magia:** quando combatte usa sigilli di luce blu (effetti, non parte del modello).
- **Espressione tipo:** palpebre a metà, sopracciglio alzato, aria da "di nuovo?".

### Zecca — Masca — colore VIOLA — 1,66 m — 19 anni
- **Chi è:** ragazzo che ha ricevuto una maschera per posta e la usa per fare dirette e visualizzazioni. Vanitoso, impulsivo, linguaccia.
- **Forma dominante:** **appuntita e asimmetrica**. Capelli bianchi-lilla a punte (`#f0e6ff`), corporatura sottile, sempre in posa.
- **Indosso:** felpa con cappuccio **viola** (`#8e3df0`) piena di toppe e adesivi inventati, pantaloni scuri (`#2a2140`), sneakers bianche enormi,
  accenti **gialli** (`#ffd23f`). Telefono in mano o su un'asta da selfie (mesh separata).
- **La maschera:** bianca, inquietante e "bizzarra" (non un oggetto da festa): occhi viola luminosi, una fessura gialla al posto della bocca.
  Deve essere **una mesh separata e rimovibile**: sotto c'è il suo **viso vero modellato** (la paura del personaggio è tornare a essere nessuno senza maschera).
- **Espressione tipo:** sorriso sfacciato (senza maschera), posa da selfie.

### Saul — Magabondo — colore VERDE — 1,78 m — 22 anni
- **Chi è:** giovane contrabbandiere di artefatti, truffatore affascinante e bugiardo. È già stato rinchiuso dalla LibraCorp e odia Ferri.
- **Forma dominante:** **allungata e disordinata**. Strati larghi, si muove sciolto.
- **Indosso:** giubbotto bomber **verde** (`#2f8f5a`) sopra strati di vestiti, pantaloni cargo (`#3d3a33`), dettagli **arancio** (`#ff8a2b`).
  Capelli castani (`#4a2b1c`) lunghi raccolti in una coda, berretto di lana. Anelli e amuleti appesi (gli artefatti che vende).
- **Oggetto:** una **borsa a tracolla** e un **pacco** avvolto in carta e spago (è il pacco che sigilla la città): mesh separate.
- **Espressione tipo:** mezzo sorriso da venditore, un occhio sempre all'uscita.

**Contrasti da far vedere quando sono insieme:** Ferri (ordine, squadrato) contro Saul (caos, allungato); Nox (spenta, verticale) contro Zecca (elettrico, a punte).

## 4. FASE 1 · Cosa mandare (immagini)

Per ognuno dei quattro:

| File | Contenuto | Misure | Formato |
|---|---|---|---|
| `<id>_foglio.png` | Turnaround: **fronte, tre quarti, lato, retro**, a figura intera, in **A-pose** (braccia a 45°), stessa scala, piedi sulla stessa linea. Sotto: primo piano del viso, gli oggetti separati, le **campioni di colore con il codice esadecimale** | **4096 × 2048** px | PNG |
| `<id>_busto.png` | Ritratto a mezzo busto per i dialoghi, sguardo verso sinistra, **4 espressioni**: neutra, arrabbiata, sorriso/sfottò, sorpresa (4 file: `_busto_neutro`, `_busto_arrabbiato`, `_busto_sorriso`, `_busto_sorpreso`) | **1024 × 1024** px | PNG con **sfondo trasparente** |
| `<id>_ultimate.png` | Posa dinamica a figura intera per la sequenza dell'ultimate (vedi 7) | **2048 × 1024** px | PNG con sfondo trasparente |

Regole per i fogli di presentazione (servono per ricavare il 3D):
- **luce piatta e frontale**, niente ombre portate, niente controluce, niente effetti, niente sfondo scenografico: **grigio neutro `#808080`**;
- **stesso personaggio, stessi dettagli** in tutte le viste (contare tasche, cinghie, ciocche);
- l'oggetto separato (maschera, caffè, pacco, telefono, arma) disegnato anche **da solo** accanto;
- niente testo dentro il disegno a parte i codici colore e il nome del file.

Nomi: `id` = `ferri`, `nox`, `zecca`, `saul`. Esempio: `zecca_foglio.png`, `zecca_busto_sorriso.png`.

## 5. FASE 2 · Specifiche dei modelli 3D

Un file per personaggio: **`<id>.glb`** (glTF 2.0 binario, texture **incorporate**). Niente .fbx, .blend, .obj come consegna principale
(un `.blend` sorgente in più è benvenuto).

**Scala e orientamento**
- 1 unità = **1 metro**, altezze esatte della scheda (Ferri 1,80 · Nox 1,70 · Zecca 1,66 · Saul 1,78; misura fino alla cima della testa, senza capelli a punta).
- **Y in alto**, il personaggio **guarda verso +Z** (convenzione glTF).
- **Origine a terra, in mezzo ai piedi.** Trasformazioni applicate (scala 1, rotazione 0) su mesh e scheletro.

**Peso (il gioco deve girare su telefoni medi con 5 personaggi a schermo)**
- **massimo 10.000 triangoli** per personaggio compresi capelli e oggetti; obiettivo 7.000–9.000;
- **massimo 2 materiali** (es. corpo + capelli/viso);
- **una texture di colore 1024 × 1024** per materiale (PNG, sRGB); al massimo una texture **emissiva 512 × 512** per le parti che si illuminano
  (occhi della maschera di Zecca, distintivo di Nox, dettagli tecnologici). Niente normal map, roughness, metallic: il gioco non li usa;
- colori **piatti**, senza luci o ombre dipinte, senza contorni dipinti;
- mesh **chiusa**, normali coerenti verso l'esterno, niente facce doppie o sovrapposte (il contorno del gioco gonfia la mesh: i buchi si vedono).

**Scheletro**
- un solo scheletro umanoide, **massimo 64 ossa**, **massimo 4 influenze per vertice**;
- nomi delle ossa **standard Mixamo** (`mixamorig:Hips`, `mixamorig:Spine`, …) oppure quelli del profilo umanoide di Godot: va bene uno dei due, **sempre lo stesso** per tutti e quattro;
- posa di riposo in **T-pose o A-pose**;
- ossa extra ammesse per cappotto (Nox), coda di capelli (Saul), cappuccio (Zecca), massimo 8 per personaggio.

**Viso**
- occhi e bocca nella texture; in più queste **shape key** (blend shape) con questi nomi esatti:
  `blink` (occhi chiusi), `smile`, `angry`, `surprised`, `mouth_open`.

**Oggetti separati** (nodi distinti nel file, con questi nomi esatti, agganciati all'osso indicato)
| Personaggio | Nodo | Osso | Note |
|---|---|---|---|
| Ferri | `arma` | mano destra | arma LibraCorp inventata |
| Ferri | `braccio_segreto` | braccio destro | SEGRETO: il braccio impiantato, **nascosto** di base (visibilità spenta). Il braccio normale col guanto resta visibile |
| Nox | `tazza` | mano destra | bicchiere di caffè |
| Zecca | `maschera` | testa | **rimovibile**, sotto il viso vero è modellato |
| Zecca | `telefono` | mano destra | telefono o asta da selfie |
| Saul | `pacco` | mano sinistra | pacco in carta e spago |
| Saul | `borsa` | bacino | borsa a tracolla (può stare nella mesh del corpo se più comodo) |

**Animazioni** (nello stesso `.glb`, **30 fotogrammi al secondo**, **sul posto**: nessuno spostamento della radice, lo muove il gioco)
| Nome esatto | Durata | Ciclo | Note |
|---|---|---|---|
| `idle` | 2–3 s | sì | fermo in esplorazione, con la personalità (Nox sorseggia, Zecca guarda il telefono) |
| `walk` | 1 s | sì | camminata, deve combaciare con 1,5 m/s |
| `run` | 0,7 s | sì | corsa, 4,6 m/s |
| `battle_idle` | 1,5–2 s | sì | in guardia |
| `attack` | 0,8–1 s | no | attacco base; il colpo arriva intorno al **40%** |
| `skill` | 1–1,4 s | no | abilità; colpo o lancio intorno al **50%** |
| `ultimate` | 2–3 s | no | posa d'effetto per la sequenza dell'ultimate (vedi 7) |
| `hit` | 0,4 s | no | colpito, torna in `battle_idle` |
| `ko` | 1 s | no | cade e resta a terra (l'ultimo fotogramma resta) |
| `victory` | 2 s | no | esultanza con la personalità del personaggio |
| `talk` | 2 s | sì | gesticola mentre parla nei dialoghi |

## 6. Il segreto di Ferri (solo per il file)
Il braccio destro impiantato è tecnologia magica di contrabbando: metallo scuro, cuciture luminose (emissive) **non rosse**
(per non confonderle col suo colore di battaglia: un verde acido o un bianco freddo), parti che sembrano organiche e meccaniche insieme.
Nel modello di base **non deve vedersi né intuirsi**: guanto e manica lo coprono del tutto. Il nodo `braccio_segreto` resta nascosto
e sostituirà il braccio quando la storia lo rivelerà.

## 7. Le ultimate (pose per `_ultimate.png` e per l'animazione `ultimate`)
Provvisorie, servono a dare carattere. Battuta che il personaggio dice nella sequenza:
- **Ferri** · "Articolo dodici: chi colpisce per primo ha ragione." — posa d'assalto militare, arma puntata, ordine perfetto.
- **Nox** · "Straordinario non pagato. Di nuovo." — sigillo blu enorme alle spalle, caffè ancora in mano, faccia annoiata.
- **Zecca** · "Chat, clippate TUTTO!" — salto con selfie, maschera in primo piano, cuoricini e notifiche viola intorno.
- **Saul** · "Questo te lo metto in conto." — lancia un artefatto con un inchino da imbroglione, mantello di carte e amuleti.

## 8. Come mandare i file

1. **Fase 1:** manda a Gianluca i PNG dei quattro personaggi (6 file per personaggio: foglio, 4 busti, ultimate, più eventuali varianti),
   meglio uno **zip per personaggio**: `ferri_fase1.zip`, `nox_fase1.zip`, `zecca_fase1.zip`, `saul_fase1.zip`. Aspetta l'approvazione.
2. **Fase 2:** uno zip per personaggio, `<id>_v1.zip` (poi `_v2`, `_v3` per le correzioni), con dentro:
   - `<id>.glb` — il modello completo;
   - `<id>_render.png` — 4096 × 2048, il modello in A-pose renderizzato fronte, tre quarti, lato, retro su grigio `#808080`;
   - `<id>_note.txt` — numero di triangoli, numero di ossa, nomi delle animazioni con la durata, nomi delle shape key, cosa manca o è diverso dalle specifiche;
   - facoltativo: `<id>.blend` sorgente.
3. Gianluca allega gli zip nella chat con Claude, che li mette nel gioco (`assets/characters/<id>/`) al posto dei segnaposto e manda le foto di come rendono.

## 9. Controllo prima della consegna
- [ ] altezza giusta, origine fra i piedi, guarda verso +Z, scala 1
- [ ] ≤ 10.000 triangoli, ≤ 2 materiali, texture 1024 (+ emissiva 512)
- [ ] colori piatti, nessuna luce, ombra o contorno dipinti
- [ ] scheletro ≤ 64 ossa, nomi Mixamo o Godot, 4 influenze per vertice
- [ ] tutte e 11 le animazioni con i nomi esatti, a 30 fps, sul posto
- [ ] shape key `blink`, `smile`, `angry`, `surprised`, `mouth_open`
- [ ] oggetti separati coi nomi esatti; `maschera` di Zecca rimovibile con viso sotto; `braccio_segreto` di Ferri nascosto
- [ ] il colore di battaglia si riconosce subito; la silhouette si riconosce in nero
- [ ] nessun elemento copiato da personaggi o marchi esistenti; tutti chiaramente maggiorenni


## 10. Sezione Mixamo (pipeline definitiva, vedi docs/STILE_VISIVO.md)

Mixamo assegna lo scheletro da solo: le ossa si chiamano `mixamorig:Hips`, `mixamorig:Spine`, `mixamorig:Spine1`, `mixamorig:Spine2`,
`mixamorig:Neck`, `mixamorig:Head`, `mixamorig:LeftShoulder`, `mixamorig:LeftArm`, `mixamorig:LeftForeArm`, `mixamorig:LeftHand`,
`mixamorig:LeftUpLeg`, `mixamorig:LeftLeg`, `mixamorig:LeftFoot`, `mixamorig:LeftToeBase` (e le `Right…`). Il gioco li mappa sul profilo
umanoide di Godot all'importazione: non serve rinominarli.

**Animazioni minime (7), scaricate da Mixamo in FBX, una per file, «In Place» attivo:**

| File | Animazione nel gioco | Al posto di |
|---|---|---|
| `<id>_fermo.fbx` | idle | `idle`, `battle_idle`, `talk` |
| `<id>_camminata.fbx` | walk | `walk` |
| `<id>_corsa.fbx` | run | `run` |
| `<id>_attacco.fbx` | attack | `attack`, `skill`, `ultimate` |
| `<id>_colpito.fbx` | hit | `hit` |
| `<id>_ko.fbx` | ko | `ko` |
| `<id>_vittoria.fbx` | victory | `victory` |

Il primo file (`<id>_fermo.fbx`) va scaricato **With Skin**; gli altri possono essere **Without Skin**.
Shape key del viso, oggetti separati con nomi esatti e braccio segreto di Ferri: non servono più nel primo giro (si aggiungono dopo).
Consegna: `ferri_fase1.zip` con il modello e i 7 FBX. Il supporto ai modelli con scheletro nel gioco si fa quando arriva il primo file
(oggi il gioco usa i segnaposto fatti da codice e, se c'è, un `.glb` **senza** scheletro).
