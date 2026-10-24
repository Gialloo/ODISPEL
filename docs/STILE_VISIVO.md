# ODISPEL — Stile visivo

> **STILE DEL GIOCO: «NOTTE URBANA E NEON» (decisione dell'autore, 24 ottobre 2026) — VINCE SU TUTTO IL RESTO DI QUESTO FILE.**
> Approvato da Gianluca dopo la prova: «è fantastico come lo volevo io, tieni in memoria questo stile per il gioco».
> Riferimenti: 16 foto in `/mnt/project-files/odispel/v3/stile_ghost_stride/riferimento/`, analisi in `ANALISI_STILE.md` (stessa cartella),
> schermate approvate in `prova2/`. Tutto il lavoro grafico futuro (aree, nemici, interfaccia, effetti) segue queste regole:
> - **Notte urbana stretta**: vicoli, ballatoi, palazzoni, cavi, insegne, graffiti; prospettive lunghe. Scenografia quasi al buio
>   (`Toon.body_world()`), poche finestre accese, fondo e nebbia verde-nero / blu notte.
> - **Luce = pochi neon fortissimi** (2-4 per scena, `night_fx.gd`): verde `#3dff8a`, ciano `#2ef2ff`, blu `#2a5cff`, accento rosso `#ff2340`,
>   lime `#d8ff3a`; riflessi verticali finti sul pavimento bagnato, pioggia fine. Niente luci dinamiche: emissivi e trucchi economici (telefono, 60 fps).
> - **Personaggi**: controluce forte ciano/verde (`toon.gd`), ombre scure; restano anime a due toni con contorno e i colori di battaglia.
> - **Onomatopee a fumetto** (`onomato.gd`): parole corte internazionali (TAP, ZAP, BAM, CLANG, THUD, KRAK, SWISH, PLING), lettere sottili e storte
>   bianco-azzurre con contorno ciano/magenta sfasato, piccole (circa 4% dello schermo, 7% sul critico), vicino all'impatto, mai sopra comandi o personaggi.
>   Niente stelle o balloon pieni. Rosso solo per i colpi forti.
> - **Glitch cromatico** rosso-ciano breve (`glitch_fx.gd`) solo nei momenti forti; spento con gli effetti ridotti.
> - La **Cupola magenta** resta come accento lontano; le **Anomalie** (altro mondo) possono avere colori loro.
> - L'**Ultimate** usa il cut-in «alla Edgerunners» (`edge_cutin.gd`): ogni personaggio col suo colore, raggi/fiamme gialli uguali, particelle uguali per tutti.
> - Resta valido l'aggiornamento del 18 ottobre qui sotto (urbano di oggi, niente medioevo, streetwear e divise).

> **AGGIORNAMENTO DELL'AUTORE (18 ottobre 2026, sera) — VINCE SU TUTTO IL RESTO DI QUESTO FILE.**
> Provata nel gioco (0.31.0), la direzione «classi medievali» è stata **bocciata**: «sembrano usciti dal medioevo».
> L'ambientazione è **urbana, ai giorni nostri**: i personaggi devono essere **moderni e belli**.
> - Niente armature, mantelli, elmi, mazze, cappelli da giullare, cornici gotiche in filigrana.
> - Vestiti di oggi: divise e streetwear (giacche tattiche, cappotti, felpe oversize, bomber, cargo, sneakers).
> - Resta valido: anime con occhi grandi e capelli a ciocche, cel shading a due toni con contorno scuro, colori di battaglia
>   fissi, dialoghi con ritratti alla Persona 5, boss = oggetti quotidiani posseduti, città notturna pop su viola notte.
> - Nel gioco (0.31.1): Ferri divisa tattica LibraCorp (berretto, gilet, fascia rossa, guanto lungo, manganello elettrico),
>   Nox cappotto lungo delle Civette (sciarpa, profili blu, caffè), Zecca felpa oversize viola (maschera, telefono, sneakers grosse),
>   Saul bomber verde su felpa grigia (cargo, berretto di lana, tracolla, pacco, carte). Segnaposto PROVVISORI.
> - Restano utili di sotto: la pipeline gratuita (TRELLIS.2 + Mixamo), i vincoli del motore, il modo di lavorare con l'autore.
>   Le regole «Silhouette», «Vocabolario degli oggetti», «Armi» e i design dei quattro qui sotto sono **superati**.

## (Superato) La versione del pomeriggio del 18 ottobre

Fonte: «ODISPEL — Handoff stile visivo dei personaggi», Gianluca, 18 ottobre 2026 (PDF di 8 pagine).
**Questo documento vince su tutti gli altri** (HANDOFF_PERSONAGGI_3D, HANDOFF_PORTRAIT, primo handoff dello stile).
Tutto lo sviluppo futuro (personaggi, nemici, luoghi, interfaccia) deve seguirlo.
Riferimenti visivi: `docs/concept/riferimenti_stile.jpg` (12 illustrazioni dell'autore, sono sue: si possono usare come base diretta)
e `docs/concept/ferri_cavaliere_riferimento.jpg` (il design di Ferri, da riprodurre «uguale e identico»).

## La direzione (decisa, non si riapre)

**Silhouette esagerate alla Kingdom Hearts + resa delle illustrazioni dei primi Final Fantasy.**

- Design moderno unito ad armature, abiti e stile delle classi medievali degli RPG: mago, cavaliere, giullare, drago…
- I personaggi restano moderni sotto: vestiti degli anni 2000 e di oggi.
- A colpo d'occhio: IP riconoscibile, un altro mondo / un'altra dimensione, prodotto di fantasia; mood **a metà fra urbano e sogno**; pubblico young adult.
- Riferimenti: Kingdom Hearts (silhouette e proporzioni), primi Final Fantasy (resa), Persona (racconto e interfaccia),
  The World Ends with You (città e ragazzi osservati). Si prende lo spirito, **mai** costumi, loghi o personaggi riconoscibili.
- Resta valido: cel shading a due toni con contorno scuro, colori di battaglia fissi, dialoghi con ritratti alla Persona 5,
  boss = oggetti quotidiani posseduti, città notturna pop su viola notte `#120b22`.

## Regole dello stile (il metro di giudizio: se non somiglia alle illustrazioni, è sbagliato)

**Silhouette e proporzioni**
- Estremità enormi: stivali e scarpe con la punta tonda e gonfia, grandi quanto la testa o più; guanti e pugni grossi.
- Gambe e busto sottili in mezzo, così piedi e mani risaltano ancora di più.
- Testa da anime, occhi grandi, capelli a ciocche nette, spesso coperta da un copricapo forte: elmo, cappuccio, berretto a punta, cappello da giullare con corna o sonagli.
- Pose diagonali e dinamiche: accovacciati, in volo, seduti nel vuoto, piegati in avanti. **Mai in piedi rigidi di fronte.**
- Un'arma o un oggetto grande che attraversa il corpo in diagonale e allunga la silhouette.

**Vocabolario degli oggetti**
- Cinghie e fibbie, borchie e spuntoni, catene, bende, toppe cucite, anelli alle dita, tatuaggi tribali sul dorso della mano.
- Motivi a righe e a scacchi da arlecchino.
- Ali: bianche d'angelo o nere stracciate, spesso piccole; alette anche su scarpe, armi e amuleti.
- Gemme tonde incastonate (rosse, gialle, blu) su armi, guanti e spalle.
- Mascotte e piccoli oggetti vivi: lo scrigno con i denti, la mazza con gli occhi e le ali.

**Armi**
- Argento lavorato, filigrana a volute e spine, una gemma o una sfera al centro.
- Più grandi del personaggio: spadoni coi fori, falci, mazze ferrate su catena, scettri, spade a chiave con catena e ciondolo.

**Colore e resa**
- Base spenta (nero, argento, grigio, viola, oliva, marrone) + **un solo accento saturo** per personaggio = il suo colore di battaglia.
- Metallo lucido con riflessi forti (firma dei primi FF). **Eccezione approvata:** nel motore il metallo può avere 2-3 bande chiare fisse
  (dipinte nella texture o fatte dallo shader). Tutto il resto resta a colori piatti.
- Cornici gotiche in filigrana attorno alle illustrazioni: nei ritratti, nei menu e nei momenti forti.

**Identità moderna**
- Sotto l'armatura vestiti di oggi: felpe, maglioni a coste, jeans strappati, bomber, sneakers. È il ponte fra urbano e sogno.
- Ogni personaggio = **una classe RPG + un capo moderno riconoscibile**.

## I quattro protagonisti

| Personaggio | Fazione · ruolo | Colore di battaglia | Classe RPG | Stato |
|---|---|---|---|---|
| Ferri (uomo, 23) | LibraCorp · vanguard | rosso `#e8343f` | cavaliere | design dell'autore |
| Nox (donna, 24) | Civette · warden | blu `#39b7ff` | guardiana notturna, maga bianca | PROVVISORIO |
| Zecca (ragazzo, 19) | Masca · striker | viola `#8e3df0` | giullare | PROVVISORIO |
| Saul (uomo, 22) | Magabondi · striker | verde `#2f8f5a` | ladro e giocatore d'azzardo | PROVVISORIO |

**Ferri, dall'illustrazione dell'autore** (`docs/concept/ferri_cavaliere_riferimento.jpg`):
- elmo argento a cupola con alette e una grata che copre bocca e mento; capelli verdi, occhi grandi;
- gambe interamente in armatura d'argento, lunghe e sottili, con schinieri a punta sulle ginocchia;
- stivaloni d'armatura enormi con la punta tonda e spuntoni dorati sul bordo;
- pettorale e spallacci d'argento, uno con spuntoni dorati; maglione blu a coste sotto il pettorale;
- braccia fasciate di bende, bracciali d'argento svasati, un pugno chiuso sul manico;
- mantello rosso che si gonfia dietro, sul lato sinistro;
- arma: mazza ferrata enorme con spuntoni dorati, legata al manico da una lunga catena;
- mascotte: una piccola mazza nera con occhi bianchi, alette d'argento e spuntoni.

**Proposte per gli altri (PROVVISORIO):**
- **Nox:** cappotto lungo che diventa tunica, cappuccio con orecchie da civetta, una lanterna, il caffè da asporto sempre in mano.
- **Zecca:** maschera bianca, cappello da giullare, scacchi asimmetrici, sneakers enormi, il telefono come strumento di scena.
- **Saul:** carte da gioco che volano, amuleti, bomber, tracolla e il pacco come reliquia.

Tutti maggiorenni, nessuna sessualizzazione. Contrasti: Ferri (ordine) contro Saul (caos), Nox (spenta) contro Zecca (elettrico).

## Pipeline 3D (tutta gratuita)

1. **Disegno di partenza (autore):** personaggio da solo, in piedi, **posa A**, figura intera, sfondo grigio `#808080`, luce piatta,
   senza armi, mascotte, catene né cornice. Meglio fronte e retro.
2. **Modello: TRELLIS.2 (Microsoft, licenza MIT)** da uno Space gratuito su Hugging Face. GLB con texture; semplificazione verso **10.000 triangoli**.
3. **Armi e mascotte a parte:** oggetti separati, il gioco li attacca alla mano.
4. **Conversione:** Mixamo non legge il GLB → FBX o OBJ con texture (Blender, oppure Claude).
5. **Scheletro e animazioni: Mixamo** (account Adobe gratuito, uso commerciale permesso, solo umanoidi bipedi).
   Animazioni minime: fermo, camminata, corsa, attacco, colpito, KO, vittoria. Si scaricano in FBX.
6. **Nel gioco (Claude Code):** toon a due toni, contorno a guscio, bande del metallo, mantello e catena mossi dal motore.
   I nomi delle ossa di Mixamo vanno mappati (vedi `docs/HANDOFF_PERSONAGGI_3D.md`, sezione Mixamo).

Da evitare: Hunyuan3D (licenza esclude l'UE), Meshy (a pagamento; il gratuito dà CC BY 4.0 e niente multi-vista). Niente strumenti a pagamento.

**Vincoli del motore:** ≤ 10.000 triangoli, 2 materiali, texture 1024×1024 (+ emissiva 512); niente luci né ombre dipinte tranne
le bande del metallo; contorno fatto dal motore (`#120a1c`), mesh chiusa; antialiasing spento su telefono (catene, piume e borchie
fini sfarfallano: vanno ingrandite e semplificate); un personaggio occupa 150-250 px di altezza e deve leggersi in nero a 100 px.
Consegna: `<id>.glb` (o FBX da Mixamo) in uno zip per gruppo (`ferri_fase1.zip`).

## Prossimi passi (dall'handoff)

1. L'autore disegna Ferri in posa A (fronte, e retro se possibile) dall'illustrazione del cavaliere.
2. Controllo del disegno prima di generare (posa, sfondo, niente oggetti staccati).
3. Modello con TRELLIS.2, screenshot fronte/lato/retro da confrontare con l'illustrazione.
4. Mazza ferrata con catena e mascotte generate a parte.
5. Conversione per Mixamo, scheletro e le sette animazioni.
6. `ferri_fase1.zip` a Claude Code e prova sul telefono.
7. Poi Nox, Zecca e Saul con lo stesso giro.

## Decisioni aperte (da chiedere all'autore)

- Ferri ha i capelli verdi nell'illustrazione, ma il verde è il colore di battaglia di Saul: si tiene o si cambia?
  (Nel segnaposto per ora sono verdi come nell'illustrazione.)
- Dove sta il braccio segreto di Ferri? Proposta PROVVISORIA: sotto le bende di un braccio, con luci verdi che filtrano.
- Le ali: tutti i protagonisti o solo alcuni? Sempre visibili o solo nella forma da ultimate?
- Le classi RPG di Nox, Zecca e Saul.
- Aspetto del Kairos, Asta e Allocco, identità visiva delle fazioni, font e icone, nome della città.

## Come lavorare con l'autore

Italiano, frasi brevi, immagini invece di descrizioni. Un personaggio alla volta, con conferma prima del successivo.
Confrontare sempre il risultato con la sua illustrazione e dire subito cosa non torna. Onestà sui limiti (Claude non produce
illustrazioni dipinte né modelli 3D). Niente strumenti a pagamento. Segnare PROVVISORIO ogni scelta non confermata.

## Stato nel gioco (0.31.0)

I segnaposto fatti da codice seguono già queste regole (estremità grandi, busto e gambe sottili, copricapi, armi grandi,
base spenta + accento, metallo a bande, pose diagonali in battaglia, cornici in filigrana nei dialoghi e nel menu).
Restano segnaposto: verranno sostituiti dai modelli della pipeline.

## Asset visivi nel gioco (19 ottobre 2026, ramo `claude/v3-asset-visivi-pow9x4`)

Aggiunte, niente tolto. Seguono la regola madre della SINTESI: **la città è di oggi, la magia si disegna con la luce, lo sguardo è una telecamera.**

| Cosa | Dove | Perché |
|---|---|---|
| **Pennellate di luce** nel colore del personaggio con nucleo avorio `#F5E9C9`, dal personaggio al nemico, su Abilità e Ultimate; spirale di luce sulle abilità di supporto | `scripts/v3/light_fx.gd`, `battle3d.gd` | «I poteri sono disegnati con istinto»: la luce è l'evento, poi sparisce |
| **Due fotogrammi neri** con una sola pennellata del colore del personaggio prima della sequenza dell'Ultimate (spenti se i lampi sono a zero) | `LightFx.blackout` | battaglia V2 del 17/10 |
| **Scintille d'impatto** arancio `#FF7438` su ogni colpo, avorio e più grandi su critico e rottura | `LightFx.sparks` | il colpo si sente anche senza suono |
| **Cerchio di luce** del suo colore sotto chi è di turno | `LightFx.glyph` | si capisce subito chi agisce (regola 11) |
| **Sigillo magenta** `#E83DCE` sotto le Anomalie, con tacche da timbro e scintille che salgono; alla sconfitta la magia lascia l'oggetto in una spirale | `LightFx.seal` | la ferita diventa mostro grazie alla magia (U5); le Anomalie parlano in burocratese (U6) |
| **La cupola nel cielo per tutto l'atto**, non solo nell'apertura: bagliore magenta all'orizzonte e cuciture di meridiani e paralleli che pulsano piano. Solo all'aperto (strada, incrocio, vicolo, tangenziale), mai nelle Anomalie né al chiuso | `scripts/v3/sky_dome.gd` | «una città sotto una cupola rosa», e tutti la vedono |
| **Mirino di Echo**: angoli dell'inquadratura, REC che lampeggia, numero della telecamera (in battaglia segue chi è di turno, col suo colore), ora della notte dalle 3:12 verso l'alba, grana leggerissima. Dentro le Anomalie: «NESSUN SEGNALE» in magenta | `scripts/v3/cam_hud.gd`, `area.gd`, `battle3d.gd` | lo sguardo come linguaggio dell'universo (U12); «dentro le Anomalie le telecamere non arrivano e l'interfaccia cambia» |
| **La maschera di Rio incrinata** dal capitolo 3 (dopo il Manichino) alla fine dell'atto: una crepa dalla fronte e, dentro, il suo occhio viola | `anime_builder.gd` (`_mask_crack`), `character_visual.gd` | «Da qui si vede... un occhio. Il mio.» La maschera si incrina e non cade: toglierla resta il climax del suo arco (U18) |

Con «effetti ridotti» le pennellate hanno meno segmenti, le scintille sono la metà e la grana è spenta.
Volutamente **non** fatto: il braccio di Lance che si accende nell'Ultimate (il braccio si vede solo al climax del suo arco, U18).

Per guardare tutto senza giocare: `xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_vetrina.gd -- /tmp/vetrina`
(protagonisti di fronte, di schiena e in posa, primi piani, Rio con la maschera incrinata, i nemici, gli effetti e la cupola).
