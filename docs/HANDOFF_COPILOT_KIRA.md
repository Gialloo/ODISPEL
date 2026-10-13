# HANDOFF PER COPILOT: i file che mancano a KIRA

Stiamo producendo le grafiche di un videogioco anime (ODISPEL). Di **Kira** (protagonista, fazione Rondini, classe striker, colore viola) esistono gia' i ritratti
`neutral`, `happy`, `angry`, `sad`, `hurt` e l'icona. **Mancano 4 immagini**: `surprised`, `battle`, `splash`, `cutin`.
Allega sempre come riferimento una tua immagine di Kira gia' approvata (la migliore e' `sad` o `angry`, con sfondo verde) e la tavola modello (se ce l'hai).

## Regole per TUTTE le immagini
- **Una immagine per messaggio.** Mai tavole o piu' immagini insieme.
- **Sfondo verde acceso #00FF00 piatto**, senza sfumature, ombre, pavimento, luci. Il verde non deve comparire su Kira (nemmeno come riflesso sui capelli: se serve, i riflessi sono magenta/viola).
- **Nessun testo**, logo scritto, cornice, firma, watermark.
- **Stesso identico personaggio, stesso stile** delle immagini di riferimento (tratto pulito con contorni, ombre piatte cel-shading, occhi grandi e luminosi).
- Nessuna ombra a terra disegnata.

## Come e' fatta Kira (non cambiare niente)
- Capelli **viola scuro** spettinati, con ciuffo ribelle in alto (ahoge) e **coda laterale** alta sulla destra; ciocche **magenta** nelle punte. Frangia che copre un po' l'occhio sinistro.
- **3 fermagli** sul lato sinistro dei capelli: un triangolo bianco (solo contorno), una doppia sbarretta bianca (simbolo "=") e un triangolo **rosa**. Un elastico bianco/nero sulla coda.
- Occhi **viola** grandi e luminosi, carnagione chiara/pesca.
- **Giacca bianca** oversize con cappuccio, aperta, con toppe **triangolari viola** sulle maniche. Sotto: tuta **nera** a collo alto con zip viola e tasca bianca sul petto con il **simbolo Rondini** (un'aquila/rondine stilizzata nera).
- **Imbracatura nera** con fibbie e cinghie, nastri/cinghie **viola** che pendono dal petto.
- Corpo intero (per `battle` e `splash`): crop top nero, **guanti senza dita**, **pantaloncini neri** con cintura e fondina/tasche, **calze nere lunghe** con uno strappo al ginocchio, **scarpe bianche e nere** con dettagli viola.
- Arma: un **pugnale/lama viola luminosa** (la "lama in ombra" di Kira), tenuto con la mano destra.
- Carattere: giovane, scattante, sguardo deciso e un po' serio.

## 1. `surprised.png` (ritratto sorpreso)
Allega **sad.png** (o angry.png) e scrivi:
```
Modifica questa immagine, NON rigenerarla da zero. Produci surprised.png.
Cambia SOLO occhi, sopracciglia e bocca: occhi molto grandi e rotondi con pupille piccole, sopracciglia alzate, bocca aperta per la sorpresa.
Tutto il resto deve restare IDENTICO: capelli (nessuna ciocca di altro colore), fermagli, giacca, imbracatura, posa, dimensione e posizione di testa e corpo,
proporzione e sfondo verde #00FF00 piatto. Non ingrandire, non rimpicciolire, non spostare nulla. Nessun testo o watermark.
```

## 2. `battle.png` (come si vede Kira nel combattimento)
Nel gioco e' mostrata **piccola** (circa 230 px di altezza su schermo da 720), vista di lato/tre quarti, **rivolta verso DESTRA** (il boss e' a destra). Deve leggersi bene anche piccola.
Allega la tavola modello e un ritratto, poi scrivi:
```
Genera battle.png: Kira (come nelle immagini di riferimento) a FIGURA INTERA in piedi, in posa da combattimento: peso sulla gamba anteriore, corpo di tre quarti RIVOLTO VERSO DESTRA,
pugnale viola luminoso in mano pronto all'attacco, sguardo deciso verso destra.
Proporzione verticale 3:4. I PIEDI toccano il bordo inferiore dell'immagine e la testa e' vicina al bordo superiore: la figura riempie quasi tutta l'altezza, centrata.
Contorni un po' piu' spessi e forme semplici (verra' mostrata piccola), silhouette chiara.
Sfondo verde #00FF00 piatto, senza pavimento ne' ombra a terra. Nessun testo o watermark.
```

## 3. `splash.png` (illustrazione grande: scheda operatore e reclutamento)
```
Genera splash.png: illustrazione di presentazione di Kira, figura intera o tre quarti, posa scenografica e sicura di se' (una mano sul fianco o il pugnale in mano), vista leggermente dal basso,
molto dettaglio su capelli, giacca bianca e imbracatura. Eventuali piccole scintille viola attorno sono ammesse, ma poche e vicine a lei.
Proporzione verticale 3:4. Il personaggio tocca il bordo inferiore, riempie quasi tutta l'altezza, centrato.
Sfondo verde #00FF00 piatto, senza pavimento. Nessun testo o watermark.
```

## 4. `cutin.png` (primo piano per l'ULTIMATE)
Compare a tutto schermo quando Kira usa la mossa speciale: deve essere **potente e dinamico**.
```
Genera cutin.png: primo piano molto dinamico di Kira per la mossa speciale. Volto e spalle, leggermente inclinato in diagonale, sguardo feroce e concentrato verso di noi,
occhi viola luminosi, capelli mossi dal vento, pugnale/lama viola che attraversa l'inquadratura, linee di velocita' ed energia viola e magenta (poche, attorno al volto).
Proporzione orizzontale 16:9. Sfondo verde #00FF00 piatto (le linee d'azione sono solo viola/magenta, mai verdi). Nessun testo o watermark.
```

## Se qualcosa non va
- Misura/proporzione sbagliata: "La proporzione deve essere 3:4 verticale. Rigenera mantenendo tutto il resto."
- Il verde compare su Kira: "Il verde dello sfondo compare sui capelli/vestiti. Rigenera senza alcun verde su Kira."
- Cambia il design: "Hai cambiato [capelli/giacca/fermagli]. Rifai uguale al riferimento."
- Piedi non sul bordo basso (`battle`/`splash`): "I piedi devono toccare il bordo inferiore dell'immagine."

## Consegna
Salva ogni immagine con il nome esatto: `surprised.png`, `battle.png`, `splash.png`, `cutin.png` e mandale a chi lavora al gioco (sfondo verde incluso: lo toglie uno script).
Non servono altre misure: le adatta lo script.
