# ODISPEL — Handoff stile visivo dei personaggi

<!-- tab: ODISPEL — Handoff stile visivo dei personaggi -->

# ODISPEL — Handoff stile visivo dei personaggi

2026-10-18 · @someone

## Scopo

Questo documento aggiorna il primo handoff «ODISPEL V3 — Handoff stile visivo» con la direzione visiva che l'autore, Gianluca, ha fissato il 18 ottobre 2026 mostrando 13 illustrazioni fatte da lui. Dove i due documenti si contraddicono, vale questo.

Sei un'istanza di Claude che definisce lo stile visivo di ODISPEL V3: personaggi, luoghi, nemici, interfaccia. Non scrivi il codice del gioco: lo fa Claude Code sul repo. Le tue proposte devono quindi rispettare i vincoli tecnici del motore (sezione «Pipeline 3D e vincoli»).

Come usarlo:

- Leggi prima «Regole dello stile»: è la parte che conta di più.
- Quello che è segnato **PROVVISORIO** è una proposta, non una decisione dell'autore.
- Le immagini di riferimento sono di Gianluca, non di altri artisti. Puoi usarle come base diretta. Chiedile di nuovo se non le hai.
- Il repo è privato: `Gialloo/ODISPEL`, ramo più recente `claude/v3-prologo`. I documenti di storia e tecnica sono in `docs/` e `data/`.

## Il gioco e il tono

ODISPEL V3 è un JRPG a turni in 3D, in italiano, su Godot 4.7.2 per telefoni Android e PC. La demo 0.30.0 contiene tutto l'atto 1: prologo, quattro capitoli e finale.

**Premessa.** Una notte una cupola rosa chiude la città. Dentro restano quattro sconosciuti di quattro fazioni: Ferri (LibraCorp), Nox (Civette), Zecca (Masca) e Saul (Magabondi). Il Kairos, una voce che vive nelle telecamere, li guida a spegnere le Anomalie: oggetti quotidiani diventati mostri. Nel finale dell'atto 1 confessa di averli incastrati, la cupola cade e li cerca tutto il paese.

**Il tono, letto dai dialoghi in `data/dialoghi_atto1.json`:**

- Commedia secca a battute corte, poi una frase sincera a capitolo. Ferri cita il regolamento, Nox vuole solo caffè, Saul vende tutto, Zecca parla alla sua chat.
- Ogni capitolo è la ferita di un personaggio: il braccio di Ferri, le 3:12 di Nox, la faccia di Zecca, l'avidità di Saul. Il boss è quella ferita fatta oggetto.
- I mostri parlano come burocrazia impazzita: «SANZIONE IN CORSO», «CHIAMATA A CARICO DEL DESTINATARIO», «LA COMBINAZIONE È: TUTTO QUELLO CHE HAI».
- Il filo di tutto è l'essere guardati: telecamere, la chat di Zecca, i manifesti da ricercati.
- Il sapore è quotidiano e italiano: strisce pedonali, multe sotto il tergicristallo, la macchinetta del caffè.

Fonti nel repo: `docs/STORIA.md`, `data/dialoghi_atto1.json`, `data/atto1.json`.

## La direzione visiva

La direzione è decisa dall'autore e non va riaperta: silhouette esagerate alla Kingdom Hearts, unite allo stile delle illustrazioni dei primi Final Fantasy. Sostituisce la domanda aperta del primo handoff («più Persona 5 o più Star Rail?»).

Le parole dell'autore, il 18 ottobre 2026:

- Design moderno unito ad armature, abiti e stile delle classi medievali degli RPG: mago, cavaliere, giullare, drago e così via.
- I personaggi mantengono un'identità moderna, con vestiti degli anni 2000 e di oggi.
- A colpo d'occhio si deve capire che: lo stile dell'IP è riconoscibile; è un altro mondo, un'altra dimensione, un videogioco, un prodotto di fantasia; il mood sta a metà fra urbano e sogno; il pubblico è young adult.

Riferimenti citati: Kingdom Hearts (silhouette e proporzioni), primi Final Fantasy (resa delle illustrazioni), Persona (racconto e interfaccia), The World Ends with You (città e ragazzi osservati). Si prende lo spirito, mai costumi, loghi o personaggi riconoscibili.

Resta valido dal primo handoff: cel shading a due toni con contorno scuro, colori di battaglia fissi, dialoghi con ritratti alla Persona 5, boss come oggetti quotidiani posseduti, città notturna pop su viola notte `#120b22`.

## Regole dello stile

Queste regole vengono dalle 12 illustrazioni dell'autore qui sotto. Sono il metro con cui giudicare ogni proposta: se un disegno non somiglia a queste immagini, è sbagliato.

![Le 12 illustrazioni di riferimento dell'autore](attachment)

**Silhouette e proporzioni**

- Estremità enormi: stivali e scarpe con la punta tonda e gonfia, grandi quanto la testa o più; guanti e pugni grossi.
- Gambe e busto sottili in mezzo, così piedi e mani risaltano ancora di più.
- Testa da anime con occhi grandi e capelli a ciocche nette, spesso coperta da un copricapo forte: elmo, cappuccio, berretto a punta, cappello da giullare con corna o sonagli.
- Pose diagonali e dinamiche: accovacciati, in volo, seduti nel vuoto, piegati in avanti. Mai in piedi rigidi di fronte.
- Un'arma o un oggetto grande che attraversa il corpo in diagonale e allunga la silhouette.

**Vocabolario degli oggetti**

- Cinghie e fibbie, borchie e spuntoni, catene, bende, toppe cucite, anelli alle dita, tatuaggi tribali sul dorso della mano.
- Motivi a righe e a scacchi da arlecchino.
- Ali: bianche d'angelo o nere stracciate, spesso piccole. Anche alette su scarpe, armi e amuleti.
- Gemme tonde incastonate (rosse, gialle, blu) su armi, guanti e spalle.
- Mascotte e piccoli oggetti vivi: lo scrigno con i denti, la mazza con gli occhi e le ali.

**Armi**

- Argento lavorato, filigrana a volute e spine, una gemma o una sfera al centro.
- Più grandi del personaggio: spadoni con i fori, falci, mazze ferrate su catena, scettri, spade a chiave con catena e ciondolo.

**Colore e resa**

- Base spenta (nero, argento, grigio, viola, oliva, marrone) e un solo accento saturo per personaggio. Da noi l'accento è il colore di battaglia.
- Metallo lucido con riflessi forti: è la firma dei primi Final Fantasy. Eccezione approvata dall'autore: nel motore il metallo può avere due o tre bande chiare fisse dipinte nella texture. Tutto il resto resta a colori piatti.
- Cornici gotiche in filigrana attorno alle illustrazioni: da usare nei ritratti, nei menu e nei momenti forti.

**L'identità moderna**

- Sotto l'armatura ci sono vestiti di oggi: felpe, maglioni a coste, jeans strappati, bomber, sneakers. Questo è il ponte fra urbano e sogno.
- Ogni personaggio = una classe RPG + un capo moderno riconoscibile.

## I quattro protagonisti

Ferri ha già un design dell'autore: è il cavaliere della terza illustrazione in alto, da riprodurre «uguale e identico» nel gioco. Gli altri tre hanno solo una classe proposta, da confermare uno alla volta con l'autore.

| Personaggio | Fazione · ruolo | Colore di battaglia | Classe RPG | Stato |
| --- | --- | --- | --- | --- |
| Ferri (uomo, 23) | LibraCorp · vanguard | rosso `#e8343f` | cavaliere | design dell'autore |
| Nox (donna, 24) | Civette · warden | blu `#39b7ff` | guardiana notturna, maga bianca | PROVVISORIO |
| Zecca (ragazzo, 19) | Masca · striker | viola `#8e3df0` | giullare | PROVVISORIO |
| Saul (uomo, 22) | Magabondi · striker | verde `#2f8f5a` | ladro e giocatore d'azzardo | PROVVISORIO |

**Ferri, dall'illustrazione dell'autore:**

- Elmo argento a cupola con alette e una grata che copre bocca e mento; capelli verdi, occhi grandi.
- Gambe interamente in armatura d'argento, lunghe e sottili, con schinieri a punta sulle ginocchia.
- Stivaloni d'armatura enormi con la punta tonda e spuntoni dorati sul bordo.
- Pettorale e spallacci d'argento, uno con spuntoni dorati; maglione blu a coste sotto il pettorale.
- Braccia fasciate di bende, bracciali d'argento svasati, un pugno chiuso sul manico.
- Mantello rosso che si gonfia dietro, sul lato sinistro.
- Arma: mazza ferrata enorme con spuntoni dorati, legata al manico da una lunga catena.
- Mascotte: una piccola mazza nera con occhi bianchi, alette d'argento e spuntoni.

**Proposte per gli altri, PROVVISORIO:**

- **Nox:** cappotto lungo che diventa tunica, cappuccio con orecchie da civetta, una lanterna come nella prima illustrazione, il caffè da asporto sempre in mano.
- **Zecca:** maschera bianca, cappello da giullare, scacchi asimmetrici, sneakers enormi, il telefono come strumento di scena.
- **Saul:** carte da gioco che volano, amuleti, bomber, tracolla e il pacco come reliquia.

Tutti maggiorenni, nessuna sessualizzazione. I contrasti da mostrare quando sono insieme restano: Ferri (ordine) contro Saul (caos), Nox (spenta) contro Zecca (elettrico).

## Cosa è stato provato

Il disegno vettoriale fatto da Claude non arriva alla resa delle illustrazioni: l'autore l'ha bocciato tre volte. Il test con un generatore 3D da immagine, invece, ha riprodotto bene lo stile davanti.

| Tentativo | Esito | Lezione |
| --- | --- | --- |
| Tre direzioni astratte (inchiostro pop, neon morbido, ibrido) | Superate: l'autore ha portato le sue immagini | Chiedere riferimenti visivi prima di proporre |
| Silhouette v1: quattro figure dritte di fronte | Bocciate: «manichini» | Le pose devono essere diagonali e dinamiche |
| Silhouette v2: pose dinamiche, ali, estremità grandi | Bocciate: «non somigliano alle immagini» | Le forme geometriche in SVG non danno questa resa |
| Ferri v3 in SVG copiato dall'illustrazione | Interrotto: l'autore vuole il modello 3D identico | Il vettoriale serve solo per schemi e palette |
| Meshy, da una sola illustrazione (ragazzo con la lanterna) | Forma fedele davanti, 10.555 facce; retro liscio e inventato; lo scheletro automatico ha messo ossa sul bastone, sullo scrigno e sulla bacchetta | Serve il personaggio da solo, dritto, in posa A, e servono le viste del retro |
| Meshy, piano a pagamento | Rifiutato dall'autore | La pipeline deve essere gratuita |

## Pipeline 3D e vincoli

La pipeline scelta è tutta gratuita: TRELLIS.2 per il modello, Mixamo per scheletro e animazioni, Godot per il resto. Claude Code la porta nel gioco; tu controlli che ogni passaggio resti fedele alle illustrazioni.

1. **Disegno di partenza (autore).** Il personaggio da solo, in piedi, in posa A (braccia staccate dal corpo, gambe un po' aperte), a figura intera, su sfondo grigio `#808080`, luce piatta. Senza armi, mascotte, catene né cornice. Meglio fronte e retro.
2. **Modello: [TRELLIS.2](https://www.3daistudio.com/blog/is-trellis-2-free-pricing-how-to-get-started) di Microsoft.** Licenza MIT, quindi uso commerciale libero. Si usa gratis da uno Space su Hugging Face, con un limite giornaliero di GPU. Esce un GLB con texture; il cursore di semplificazione va tenuto alto, verso i 10.000 triangoli.
3. **Armi e mascotte a parte.** Si generano come oggetti separati e il gioco li attacca alla mano.
4. **Conversione.** Mixamo non legge il GLB: va convertito in FBX o in OBJ con texture (Blender, oppure Claude).
5. **Scheletro e animazioni: [Mixamo](https://app.cinevva.com/guides/free-character-animations-rigging).** Gratis con un account Adobe gratuito, uso commerciale permesso. Funziona solo con umanoidi bipedi. Animazioni minime: fermo, camminata, corsa, attacco, colpito, KO, vittoria. Si scarica in FBX.
6. **Nel gioco (Claude Code).** Toon a due toni, contorno a guscio, bande del metallo, mantello e catena mossi dal motore. I nomi delle ossa di Mixamo non coincidono con quelli di `docs/HANDOFF_PERSONAGGI_3D.md`: vanno mappati.

Da evitare: Hunyuan3D di Tencent. La sua [licenza](https://huggingface.co/tencent/Hunyuan3D-2/blob/main/LICENSE) esclude l'Unione Europea, e l'autore è in Italia. Meshy funziona, ma l'autore non vuole pagare e il piano gratuito dà licenza CC BY 4.0 e niente multi-vista.

**Vincoli del motore** (Godot 4.7.2, modalità compatibility, telefoni Android di fascia media):

| Elemento | Regola |
| --- | --- |
| Peso personaggio | massimo 10.000 triangoli, 2 materiali, texture 1024×1024 (+ emissiva 512) |
| Luce | niente luci né ombre dipinte nelle texture, tranne le bande fisse del metallo |
| Contorno | fatto dal motore, colore `#120a1c`; la mesh deve essere chiusa |
| Antialiasing | spento su telefono: catene, piume e borchie fini sfarfallano, quindi vanno ingrandite e semplificate |
| Inquadratura | un personaggio occupa 150-250 px di altezza; deve leggersi in nero a 100 px |
| Consegna | `<id>.glb` in uno zip per gruppo (`ferri_fase1.zip`), dato a Claude Code |

## Aperto e prossimi passi

Il prossimo passo è Ferri: l'autore lo disegna in posa A, lo si passa da TRELLIS.2 e Mixamo e lo si prova nel gioco. Gli altri tre vengono dopo, uno alla volta.

**Prossimi passi**

- [ ] L'autore disegna Ferri in posa A (fronte, e retro se possibile) dall'illustrazione del cavaliere
- [ ] Controllo del disegno prima di generare: posa, sfondo, niente oggetti staccati
- [ ] Modello con TRELLIS.2, poi screenshot di fronte, lato e retro da confrontare con l'illustrazione
- [ ] Mazza ferrata con catena e mascotte generate a parte
- [ ] Conversione per Mixamo, scheletro e le sette animazioni
- [ ] `ferri_fase1.zip` a Claude Code e prova sul telefono
- [ ] Poi Nox, Zecca e Saul con lo stesso giro

**Decisioni aperte, da chiedere all'autore**

- Ferri ha i capelli verdi nell'illustrazione, ma il verde è il colore di battaglia di Saul. Si tiene o si cambia?
- Dove sta il braccio segreto di Ferri (tecnologia magica di contrabbando)? Proposta, PROVVISORIO: sotto le bende di un braccio, con luci verdi che filtrano.
- Le ali: tutti i protagonisti o solo alcuni? Sempre visibili o solo nella forma da ultimate?
- Le classi RPG di Nox, Zecca e Saul.
- Restano aperte dal primo handoff: aspetto del Kairos, Asta e Allocco, identità visiva delle fazioni, font e icone, nome della città.

**Incoerenze nei documenti del repo**

- `docs/STORIA.md` chiama Zecca «ladra»; dialoghi e handoff ne fanno un ragazzo di 19 anni. Finora si è seguito il ragazzo.
- `docs/STORIA.md` mette il tradimento del Kairos a metà gioco, ma nei dialoghi lui confessa già nel finale dell'atto 1.
- `docs/MONDO.md` (ramo `claude/battaglia-v2`) è vecchio e cita le Rondini, che non vanno usate.

## Come lavorare con l'autore

Gianluca decide e vuole risultati che somiglino alle sue immagini, non spiegazioni. Lavora spesso dal telefono.

- Scrivi in italiano, a frasi brevi. Mostra immagini invece di descriverle.
- Un personaggio alla volta, e chiedi conferma prima di passare al successivo.
- Confronta sempre il risultato con la sua illustrazione e di' subito cosa non torna.
- Sii onesto sui limiti: Claude non produce illustrazioni dipinte né modelli 3D. Può fare schemi, palette, controlli e istruzioni passo passo.
- Quando lo guidi in uno strumento, vai un passo alla volta. Basati sui suoi screenshot e chiedigli lo screenshot del passo successivo prima che spenda crediti o confermi.
- Niente strumenti a pagamento. Se un'opzione ha la coroncina o il bollino PRO, dillo prima.
- Prima di copiare un'immagine «uguale e identica», verifica che sia sua. Fra i riferimenti era finito anche un repost dal profilo di un altro artista, poi escluso.
- Ispirazione, mai copia da opere esistenti: niente costumi, loghi o personaggi riconoscibili di Kingdom Hearts, Final Fantasy o Persona.
- Segna come PROVVISORIO ogni scelta che lui non ha confermato.

