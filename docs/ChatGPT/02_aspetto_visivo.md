# ODISPEL, parte 2 di 6: l'aspetto visivo (non puoi vedere immagini: ecco come e' fatto)

## Direzione artistica (Mini Art Bible ufficiale)
Shonen puro, anime 2D illustrato. Regola madre: i personaggi sono disegnati con precisione (lineart pulita, silhouette forti); i loro poteri sono disegnati con istinto (tratti di luce ruvidi, gestuali). Firma visiva: il **light painting**, cioe' i poteri come tratti di luce disegnati nello spazio, come una foto a lunga esposizione. La luce e' l'evento eccezionale: il mondo e' il foglio, il personaggio e' il pennello, l'abilita' e' il tratto. Leggibilita' prima dello spettacolo.

## Palette
Carbone urbano #171923 (pannelli, fondali), avorio luminoso #F5E9C9 (testi, bordi chiari), arancio impatto #FF7438 (bottoni principali, ultimate pronta, scudi, picchi), magenta rituale #E83DCE (segni importanti, tondo della fase del boss), viola cosmico #7770F7 (profondita', velatura della battaglia).
Colori funzionali: ciano #7FDCEC = alleato/interfaccia, rosso #F0453C = nemico/pericolo. Barre dei PV alleati bianco-ciano (rosso sotto il 30%), barra del boss rossa, scudo arancio, verde solo per scritte di cura.
Colori dei personaggi (regola di gioco): rosso #FF4D6D, verde #6BFFB0, blu #5AA8FF, giallo #FFD25F, viola #B07BFF.

## Caratteri (tutti con licenza libera)
Archivo Black (titoli, nomi, boss, MAIUSCOLO), Roboto Bold (HUD, numeri, timer, MAIUSCOLO), Merriweather Bold ridotto (pulsanti e dialoghi), Libre Caslon Condensed Bold (solo il logo ODISPEL).

## Stile dell'interfaccia
Pannelli con angoli tagliati a 45 gradi, contorni puliti, pulsanti a parallelogramma con ombra netta (alla Persona 5), righe oblique leggere come retino da fumetto, linguette col titolo sui pannelli principali. Sopra la scena c'e' un velo leggero viola con grana. Nessuna decorazione senza funzione. Animazioni dei pulsanti sotto i 100 ms. Su telefono i pulsanti sono alti almeno 64 punti (su base 1280x720) e i testi non scendono sotto 14-16.

## La schermata di battaglia (1280x720)
```
+------------------------------------------------------------------+
|[AUTO][>>]       +-ALLARME-----------+   +-DISTRIBUTORE---------(1)|
|TURNO 01         |   SCARICA         |   | classe · minaccia       |
|+-ORDINE TURNO-+ | bersaglio: KIRA   |   | [=======vita boss=====] |
|| 1 KIRA »Scegli |  (suggerimento)   |   | [==equilibrio=]  PV 1800|
|| 2 BOSS »SCARICA|  Riserva ●●●○○○   |   +-------------------------+
|| 3 ELLE »Scegli |  [ORD: ..][COSTO] |        +---------------+
|+--------------+ |                   |        |  il BOSS (a   |
|  [KIRA]  [DAX]  |   KIRA 1st        |        |  destra, ~340 |
| (sprite)(sprite)|  [/ ATTACCO     ] |        |  px di altezza|
|   [ELLE]        |  [# GUARDIA     ] |        |  e poi l'area |
|  barra vita sotto  [~ COLPO CARICATO 2E]     |  degli effetti)|
|  ogni personaggio  [* SPEZZATUTTO PRONTA]    +---------------+
|+--KIRA LV1 ▲ 1206--+-DAX 1719--+-ELLE 1096--+      [LOG ▲]    |
||  PV barra  EN 2/6  | ...       |   ...      |                 |
||  BRUNO (panchina)  | NOVA      | MIRA       |                 |
|+--------------------+-----------+------------+                 |
+------------------------------------------------------------------+
```
- In alto a sinistra: tasto AUTO (l'IA gioca da sola), velocita' normale/veloce/turbo, numero del turno, pannello ORDINE DEL TURNO (chi agisce in che ordine).
- In alto al centro: l'ALLARME col nome della mossa del boss e il bersaglio. In alto a destra: nome del boss, barra vita rossa grande, barra equilibrio ciano sottile, tondo della fase (1-3).
- Al centro-sinistra: gli operatori in prospettiva, in fila obliqua, con targhetta del nome colorata; sotto ognuno una barra vita. Il boss e' a destra.
- Il menu comandi a ventaglio: un pulsante per mossa, bianco-avorio se usabile; spento e scuro se non usabile, con il motivo in rosso a destra (SERVE 2E, SENZA COLPI); l'ultimate pronta e' arancio con la scritta PRONTA. Icona a sinistra dentro il pulsante, costo a destra.
- In basso a sinistra: una striscia per ogni operatore in campo (ritratto, nome, livello, PV, energia 2/6, barra ultimate, icone di fazione e munizioni) e sotto il compagno in panchina.
- Durante i colpi: numeri di danno in fumetto giallo con stella, parole BAM/POW, scritte di combo, riquadro con ritratto quando si usa un'abilita', animazione a tutto schermo (cut-in) per gli ultimate, battute dei personaggi in un fumetto in basso a destra.

## Altre schermate
- **Hub (menu principale)**: sfondo illustrato di una strada urbana di notte, viola e magenta, un'ombra in lontananza; logo ODISPEL grande in alto a sinistra su una banda arancio inclinata; sotto, una griglia di pulsanti a parallelogramma: CONTINUA (largo, arancio), SCEGLI MISSIONE, SQUADRA, CICLO INFINITO, SPEDIZIONE, CO-OP ONLINE, OBIETTIVI, TUTORIAL, IMPOSTAZIONI. In alto a destra il profilo del giocatore.
- **Selezione missione**: a sinistra elenco dei boss (bloccati = "??? Bloccato"), a destra il dossier del boss con descrizione, scelta della difficolta' (Normale/Difficile/Incubo/Abisso), pulsanti Rivedi scena, Addestramento, Avvia missione.
- **Archivio operatori (squadra)**: titolo grande, 5 schede (Squadra, Equipaggiamento, Reclutamento, Strategie, Archivio), riga dei 3 front e 3 back, collezione filtrabile a sinistra, scheda dell'operatore a destra con illustrazione grande.
- **Fine battaglia**: riepilogo, MVP, premi, pulsanti Rigioca / Scegli missione / Torna all'hub.

## Personaggi e boss
Solo Kira ha oggi un'illustrazione completa (ragazza con capelli viola, giacca bianca, abiti scuri). Gli altri operatori usano segnaposto in stile anime disegnati dal codice (testa grande, corpo semplice del colore del personaggio) in attesa dell'arte vera. I boss sono oggetti urbani stilizzati (per esempio un distributore: sagoma con griglia di caselle rosse e blu).

## Effetti (light painting)
Ogni "mano" (fazione) ha un gesto: LibraCorp circuiti, Rondini archi, Magabondi scarabocchi, Kairos copie sfasate. Il colore del personaggio e' dominante, con nucleo avorio, alone morbido e frammenti arancio. Forme: linea, fendente (pennellata che si comprime con coda di filamenti), anello (scudi), spirale (cure), marchio, frattura, vortice, e una firma a stella diversa per ogni personaggio negli ultimate (24 combinazioni). Un colpo normale dura circa mezzo secondo; le firme degli ultimate fino a 1,8 s. Gli effetti non ritardano mai la logica.
