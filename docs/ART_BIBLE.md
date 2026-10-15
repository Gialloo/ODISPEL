ODISPEL — Mini Art Bible v1.0

Direzione artistica ufficiale · 15 ottobre 2026 · Documento di riferimento per gioco, personaggi ed effetti

La direzione è decisa: shōnen puro, anime 2D illustrato, personaggi dalla lineart pulita ed effetti di potere ruvidi e gestuali. Il lightpainting diventa la firma visiva di ODISPEL.

Non vogliamo un gioco che sembri un collage di anime famosi. Vogliamo un’identità capace di sostenere combattimenti, boss, personaggi, manga e futuri prodotti dell’IP.

La regola madre

I personaggi sono disegnati con precisione. I loro poteri sono disegnati con istinto.

La forma del personaggio deve essere immediatamente leggibile. La luce che produce può invece essere irregolare, violenta, calligrafica e imprevedibile. È il contrasto tra ordine e caos a rendere riconoscibile ODISPEL.

1. I pilastri dell’identità visiva

01 — Shōnen emotivo

Ogni attacco deve comunicare carattere. La rabbia, la sicurezza, la paura e la determinazione si leggono nella posa, nel ritmo e nella forma dell’effetto, non soltanto nella quantità di danno.

02 — Personaggi illustrati

Contorni chiari, silhouette forti, ombre selettive, anatomia stilizzata coerente e dettagli concentrati nei punti importanti. Niente texture casuali che rendano difficile leggere il personaggio.

03 — Lightpainting gestuale

I poteri sono tratti disegnati nello spazio: pennellate, filamenti, archi, frammenti, segni rituali e distorsioni. Il glow serve a intensificarli, non a sostituirne il disegno.

04 — Leggibilità prima dello spettacolo

Anche su uno schermo piccolo, il giocatore deve capire chi sta attaccando, dove avviene l’impatto e quale effetto è importante. Lo spettacolo deve chiarire l’azione, non coprirla.

05 — Ogni potere ha una calligrafia

Colore, spessore, velocità, curvatura, densità e dissolvenza sono parametri di identità. Due poteri dello stesso colore devono comunque essere distinguibili.

2. Palette ufficiale

La palette deve essere coerente a livello di universo, ma non imporre lo stesso colore a tutti i personaggi.

Carbone urbano

Costumi, fondali, ombre e contrasto.

#171923

Magenta rituale

Energia caratteristica, anomalie e segni principali.

#E83DCE

Arancio impatto

Accelerazioni, colpi pesanti e picchi energetici.

#FF7438

Viola cosmico

Profondità, distorsioni e fenomeni sovrannaturali.

#7770F7

Avorio luminoso

Nuclei incandescenti, accenti e dettagli rituali.

#F5E9C9

Questi valori sono il punto di partenza della palette, da verificare su fondali chiari e scuri e sui display dei telefoni.

Regola del colore: ogni effetto usa un colore dominante, uno di supporto e, quando serve, un accento molto luminoso. Evitiamo di usare tutti i colori al massimo della saturazione contemporaneamente.

Per Mada manterrei magenta/fucsia, arancio-rosso e viola cosmico, con occhi ambrati: una combinazione personale, non il codice cromatico universale di tutti gli Odispeller.

3. Il sistema lightpainting

Questa è la parte più importante dell’art bible. Non creiamo una collezione di effetti scollegati: creiamo un sistema visivo con regole riutilizzabili.

I sei elementi che compongono un effetto

A. Tratto principale

La forma che racconta l’azione. Deve essere riconoscibile anche senza bagliore.

B. Scia

Linee sottili che raccontano direzione, velocità e traiettoria.

C. Alone

Una luce morbida e contenuta che stacca il tratto dallo sfondo.

D. Frammenti

Schegge, gocce e particelle che accentuano l’impatto. Poche, con una direzione precisa.

E. Segno rituale

Simboli e geometrie riservati alle tecniche che richiedono preparazione, controllo o significato narrativo.

F. Accento d’impatto

Un lampo breve nel momento del contatto, distinto dall’esplosione o dal danno vero e proprio.

Non ogni abilità deve usare tutti e sei gli elementi. Un attacco veloce potrebbe avere soltanto tratto, scia e accento d’impatto. Un’ultimate può combinarli tutti.

La grammatica dei poteri

Famiglia	Forma dominante	Movimento	Sensazione
Rapido	Tratto sottile	Scatto	Precisione
Pesante	Pennellata spessa	Compressione ed esplosione	Peso
Mobilità	Scia allungata	Curva o zigzag	Velocità
Difesa	Arco o linea chiusa	Espansione o chiusura	Protezione
Controllo	Nodi e geometrie	Costruzione progressiva	Strategia
Anomalia	Tratti spezzati e deformati	Movimento irregolare	Instabilità
Ultimate	Composizione di più segni	Crescita e risoluzione	Catarsi

Questa tabella deve diventare il riferimento per chi disegna gli asset e per chi implementa le animazioni in Godot.

4. Animazione: il ritmo fa parte del disegno

Un buon effetto non è una bella immagine ferma: è una forma che nasce, agisce e scompare con il ritmo giusto.

Come valori iniziali da testare, userei questa struttura:

1. Preparazione

0–100 ms · Un piccolo anticipo visivo, se il colpo lo richiede.

2. Tracciamento

50–180 ms · Il tratto attraversa lo spazio seguendo il movimento.

3. Impatto

30–80 ms · Accento luminoso breve e leggibile.

4. Dissolvenza

100–250 ms · Il tratto si assottiglia e perde luminosità.

Intervalli indicativi: possono sovrapporsi e vanno adattati alla velocità del combattimento.

La durata totale di un attacco normale dovrebbe spesso restare nell’ordine di poche centinaia di millisecondi. Le tecniche preparate e le ultimate possono durare molto di più, ma devono guadagnarsi quel tempo con una vera escalation visiva.

Nota di gameplay: l’effetto visivo non deve ritardare artificialmente la risoluzione del combattimento. L’animazione comunica l’evento; non lo decide.

5. Come tradurlo in Godot 4.7.2

Per il progetto ODISPEL partirei da una soluzione 2D leggera, con il renderer Compatibility e i dispositivi Android in mente.

Texture PNG con vera trasparenza

Pennellate, frammenti e simboli dipinti a mano. Nessuno sfondo nero incorporato nell’immagine, nessuna scacchiera disegnata.

Scene VFX riutilizzabili

Una scena può combinare tratto, scia, alone e frammenti. Le abilità passano parametri come colore, scala, rotazione e durata, quando supportati dall’implementazione.

Animazione 2D

AnimationPlayer o AnimatedSprite2D per controllare comparsa, deformazione, dissolvenza e sequenza dei fotogrammi. GPUParticles2D solo quando le particelle aggiungono davvero qualcosa.

Glow controllato

Prima proviamo un alone già dipinto nella texture. Solo se serve più luminosità aggiungiamo un metodo di glow compatibile con il renderer, evitando di dipendere da effetti costosi.

Struttura delle cartelle consigliata

Non creare ancora queste cartelle se non abbiamo verificato la struttura effettiva del progetto. Questa è la destinazione proposta:

art/
  vfx/
    strokes/
    trails/
    impacts/
    fragments/
    sigils/
    ultimate/
scenes/
  vfx/
    lightstroke.tscn
    lightimpact.tscn
    ritualsigil.tscn
scripts/
  vfx/
    vfx_library.gd

I nomi sono provvisori e potranno essere adattati alle convenzioni già presenti nel repository.

6. Standard di produzione degli asset

Ogni asset deve rispettare alcune regole, così da evitare di dover ridisegnare tutto quando il gioco cresce.

* Formato: PNG RGBA con alpha reale.
* Contorni: tratto leggibile, estremità intenzionali e bordi puliti dove il segno incontra la trasparenza.
* Glow: preferibilmente separabile dal tratto principale, così possiamo regolarlo in gioco.
* Inquadratura: il segno deve avere spazio per animarsi senza essere tagliato ai bordi.
* Dimensioni: scegliere la risoluzione in base alla dimensione effettiva a schermo, non produrre ogni effetto a una risoluzione arbitrariamente enorme.
* Nomi: descrivere forma, famiglia e variante, non soltanto il personaggio.

Esempi:

vfx_stroke_slash_magenta_01.png
vfx_impact_heavy_orange_01.png
vfx_trail_dash_violet_01.png
vfx_sigil_ritual_magenta_01.png
vfx_fragment_ink_01.png

Per gli asset che richiedono più fasi, manteniamo una numerazione ordinata oppure usiamo sprite sheet se questo semplifica l’animazione.

7. Il brief artistico da riutilizzare

Questo è il testo di riferimento da passare a un artista o utilizzare per pianificare la creazione degli asset.

ODISPEL — Visual Effects Art Direction

Direzione: shōnen urban fantasy, anime 2D illustrato.

Firma visiva: lightpainting gestuale, come inchiostro luminoso disegnato nello spazio.

Contrasto fondamentale: personaggi con lineart pulita e silhouette precise; poteri con tratti ruvidi, dinamici, asimmetrici e intensamente espressivi.

Palette di riferimento: carbone urbano, magenta rituale, arancio impatto, viola cosmico e avorio luminoso.

Forma degli effetti: pennellate affilate, estremità rastremate, filamenti sottili, frammenti direzionali, segni rituali incompleti e accenti luminosi brevi.

Animazione: ogni effetto deve avere un’intenzione leggibile, una direzione, un momento d’impatto e una dissolvenza coerente.

Personalità: ogni personaggio possiede una calligrafia visiva riconoscibile anche quando il colore viene rimosso.

Leggibilità: la silhouette del personaggio, il bersaglio e il risultato dell’azione devono restare comprensibili anche su schermi piccoli.

Implementazione: asset 2D con trasparenza reale, animazioni brevi e componenti riutilizzabili; evitare dipendenze da shader costosi o da un renderer specifico non verificato.

Da evitare: sfere neon generiche, particelle casuali in eccesso, glow che cancella il disegno, effetti indistinguibili tra personaggi e composizioni così luminose da nascondere l’azione.

8. Il primo test ufficiale

Non realizzerei subito cinquanta effetti. Ne produrrei uno soltanto, lo porterei in Godot e lo userei come riferimento per tutto il resto.

VFX-001 — Lightstroke

Un fendente diagonale magenta-viola con nucleo avorio, coda filamentosa e pochi frammenti arancio.

Obiettivo: validare forma, trasparenza, animazione, luminosità e leggibilità.

Criteri di accettazione

Il tratto è riconoscibile anche senza glow.

La direzione dell’attacco si capisce immediatamente.

L’effetto non copre completamente il personaggio o il bersaglio.

La trasparenza non crea aloni indesiderati.

La scena si riproduce senza errori in Godot.

La resa rimane leggibile alla risoluzione di gioco e su Android.

0 di 6 criteri verificati

La lista sopra è una checklist di verifica, non un’affermazione che il prototipo sia già stato realizzato o testato.

Il passo successivo concreto: riprendiamo il controllo della struttura Git e delle cartelle del progetto che avevamo iniziato. Poi creiamo VFX-001 in una scena di prova separata, validiamo il risultato e solo dopo costruiamo la libreria completa.

È così che trasformiamo il lightpainting da bella idea estetica in un sistema visivo ripetibile, riconoscibile e sostenibile per ODISPEL.

---

# STATO DI IMPLEMENTAZIONE IN ODISPEL (aggiornato alla 0.24.26)

Il testo sopra e' la direzione artistica ufficiale (copia del documento del 15 ottobre 2026). Questa sezione dice cosa del documento e' gia' nel gioco.

## Struttura del progetto (verificata)
Il progetto non usa scene `.tscn` per gli effetti: sono Controls disegnati dal codice. Quindi il VFX vive in `scripts/ui/light_paint.gd` (classe `LightPaint`), accanto a `lightning_fx.gd`, `ult_fx.gd`, `anim_fx.gd`. Le cartelle `art/vfx/...`, `scenes/vfx/...` e `scripts/vfx/...` proposte dal documento **non sono state create**: si creano quando la libreria di texture dipinte esistera' davvero. Oggi le pennellate dipinte a mano si mettono in `art/fx/stroke_<fazione>.png` (vedi `docs/GUIDA_PROCREATE.md`, sezione 11).

## Palette (sezione 2)
Costanti `PAL_*` in `LightPaint`: carbone `#171923`, magenta `#E83DCE`, arancio `#FF7438`, viola cosmico `#7770F7`, avorio `#F5E9C9`.
- Il **colore del personaggio** resta il dominante (non si impone un colore universale).
- Ogni mano ha un colore di **supporto** della palette: LibraCorp viola cosmico, Rondini avorio, Magabondi arancio, Kairos magenta (usato per l'alone).
- Il **nucleo** del tratto e l'accento d'impatto sono sempre **avorio**; i frammenti dei colpi pesanti sono **arancio**.
- Non verificato: resa su fondali chiari e sul display di un telefono (provato solo sul fondale scuro del gioco).

## Gli elementi dell'effetto (sezione 3)
| Elemento | Nel codice |
|---|---|
| A. Tratto principale | `_draw_trail` (forma per mano e per mossa) |
| B. Scia | coda che sfuma + filamenti del fendente (`_draw_filaments`) |
| C. Alone | cerchi sfumati col colore di supporto (`halo_enabled`, spegnibile per le prove) |
| D. Frammenti | particelle per colore; frammenti arancio direzionali del fendente |
| E. Segno rituale | forme `mark` (Marchio) e `sigil` (firma degli ultimate) |
| F. Accento d'impatto | lampo avorio di ~70 ms al contatto |

## Grammatica dei poteri (sezione 3) -> mosse del gioco
| Famiglia | Forma | Mosse del gioco |
|---|---|---|
| Rapido | tratto sottile | Colpo mirato (1 tratto), Doppio colpo (2 tratti) |
| Pesante | pennellata spessa `slash` | Colpo caricato, Colpo alla testa, Spezzatutto; qualsiasi colpo pesante o critico |
| Mobilita' | scia allungata | non ancora usata (nessuna mossa di spostamento nel gioco) |
| Difesa | arco o linea chiusa `ring` | Barriera, Bastione, scudi |
| Controllo | nodi e geometrie | Marchio (`mark`), Intimidisci (`swirl`) |
| Anomalia | tratti spezzati `crack` | Frattura |
| Ultimate | composizione di piu' segni | firma `sigil` + fendente + effetto dell'ultimate |
La **fazione** decide il gesto (circuito, arco, scarabocchio, copie sfasate) e il **colore** le particelle: la mossa e' solo l'ultimo livello (scelta di progetto, vedi sezione "Gerarchia").

## Gerarchia (decisione presa con il direttore)
1. Fazione = la "mano" che dipinge. 2. Colore = tinta e particelle. 3. Mossa = forma e variazioni. Il documento chiede che "ogni potere abbia una calligrafia" e che due poteri dello stesso colore siano distinguibili: lo sono per mano e per forma. Una calligrafia **per singolo personaggio** esiste solo negli ultimate (la firma).

## Tempi (sezione 4)
Tracciamento 140-180 ms, impatto ~70 ms, dissolvenza ~200 ms: un colpo normale dura circa 450 ms in tutto. Fendente 160 ms + 340 ms. Scudi/cure 300-360 ms di tracciamento. Segni (Marchio) ~1,3 s, ultimate fino a 1,8 s. Gli effetti **non** ritardano la risoluzione: sono solo grafica e la logica di battaglia non li aspetta. Manca la fase di "preparazione" (0-100 ms), non necessaria finora.

## VFX-001 - Lightstroke (sezione 8)
Implementato come forma `slash` ("fendente diagonale con nucleo avorio, coda filamentosa e pochi frammenti arancio"): pennellata che si comprime e si assottiglia, coda di tre filamenti, 2-5 frammenti arancio nella direzione del colpo. Si vede in battaglia sui colpi pesanti e critici e su Colpo caricato / Spezzatutto. Prove: `tools/slash_shot.gd` (un fendente in grande, con o senza alone) e `tools/battle_lp_shot.gd heavy`.

Criteri di accettazione:
1. Riconoscibile anche senza glow: **verificato** (foto senza alone, `slash_shot.gd ... nohalo`).
2. La direzione si capisce: **verificato in immagine** (coda dietro, impatto davanti, arriva dal lato di chi attacca).
3. Non copre il bersaglio: **verificato in immagine** sul boss; non verificato con piu' fendenti contemporanei su schermi piccoli.
4. Trasparenza senza aloni: **non applicabile** al tratto generato dal codice (non ha PNG); vale per le pennellate che disegnerai tu.
5. Si riproduce senza errori: **verificato** (`test_light_paint`, suite completa, audit UI).
6. Leggibile alla risoluzione di gioco e su Android: **PC verificato; Android NON verificato** (nessun test sul telefono).
