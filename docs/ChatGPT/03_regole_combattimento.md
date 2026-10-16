# ODISPEL, parte 3 di 6: regole del combattimento

Tutto il combattimento e' deterministico: nessun numero casuale, lo stesso stato da' sempre lo stesso risultato (serve per il multiplayer). Tutti i valori sono interi.

## Squadra e risorse
- Fino a 6 operatori: 3 in campo (front row) e 3 in panchina (back row). Lo scambio con un compagno in panchina e' gratis e si sceglie prima della mossa. In rete ogni giocatore porta al massimo 3 operatori e ne ha 1 in campo.
- **Energia** per operatore: parte da 2, massimo 6; +1 a round se e' in campo, +2 se e' in panchina. Le skill costano energia (Attacco e Guardia no).
- **Barra ultimate** (0-100): +15 quando colpisci, +10 quando subisci danno; a 100 si puo' usare l'ultimate.
- **Munizioni** (soprattutto LibraCorp): massimo 3; i colpi speciali ne consumano, Ricarica e Guardia le recuperano.
- **Riserva di squadra** (condivisa): parte da 3, massimo 6, +1 a round e +1 con una combo; si spende per le reazioni. Dalla fase 2 il boss la prosciuga.
- Kit: ogni operatore ha 4 slot di mosse piu' l'ultimate. Negli slot stanno Attacco, Guardia, le skill possedute e le abilita' uniche del personaggio. Con il kit completo (4 mosse piu' ultimate): +3% a PV, attacco e difesa.

## Statistiche
Classi (valori base PV / attacco / difesa / velocita'):
- **Striker** 900 / 100 / 20 / 110: colpisce forte, e' fragile.
- **Vanguard** 1300 / 90 / 50 / 90: tank, resistente, provoca.
- **Warden** 940 / 84 / 28 / 100: supporto, cura e protegge.
Formula: base della classe x (1 + 0.08 per livello oltre il 1) x bonus rank x moltiplicatore di rarita' (comune 1.0, rara 1.08, epica 1.18, leggendaria 1.32) x moltiplicatore del personaggio, piu' equipaggiamento, titoli e bonus kit.
Attacco base: Striker x1.0, Vanguard x1.2, Warden x1.3 (i supporti colpiscono un po' di piu' con l'attacco semplice).
Le mosse hanno 4 versioni (I, II, III, IV) legate alla rarita': piu' alta, piu' forte.

## Il round
1. **Annuncio**: il boss mostra la sua prossima mossa e il bersaglio (l'ALLARME). Nelle prime 4 partite c'e' un suggerimento su come reagire; poi diventa "???".
2. **Scelta**: ogni giocatore sceglie, per ciascun operatore in campo, scambio (opzionale) + mossa + bersaglio. Opzioni di squadra: un ORDINE comune e un COSTO (potere in cambio di PV). Puo' esserci un limite di tempo.
3. **Risoluzione**: si ordina per priorita' della mossa, poi per velocita' (a parita', per nome). Il boss agisce nel suo posto per velocita'.
4. **Eventi dell'arena** ogni 3 round (per esempio ZONA CONTAMINATA, SIGILLO). Ogni boss ha un "comportamento" che punisce qualcosa (cure, marchi, guardia di gruppo).

## Danno
danno = attacco x moltiplicatore della mossa, poi moltiplicato per:
- **colore**: x1.5 se vince (rosso batte verde, verde batte blu, blu batte rosso; giallo e viola si battono a vicenda), x0.67 se perde;
- marchi sul bersaglio, archetipi, firme dei personaggi, ordini di squadra;
- boss infuriato (sotto meta' PV) x1.25; boss stordito/esposto x1.25;
- operatore sotto il 30% PV (ARDORE) x1.15; Cacciatore (passiva) x1.2 contro bersagli sotto meta' PV;
poi ridotto dalla difesa: danno x 100 / (100 + difesa x (100 - perforazione)/100). Se il bersaglio e' in Guardia il danno si dimezza. Minimo 1.

## Boss
- 18 boss in ordine di sblocco, dal distributore all'eclissi (dal 10 in poi = Stagione 2). PV = PV per giocatore x numero di giocatori.
- Difficolta': NORMALE; DIFFICILE (PV x1.5, attacco x1.25, difesa +8, premi x2); INCUBO (x2.1, x1.55, +15, premi x3.2); ABISSO (PV x36, attacco x23, difesa +70, premi x5; tutti i boss partono dagli stessi valori medi; pensato per squadre livello 50 al massimo).
- **Fasi**: a meta' e a un quarto dei PV: nuove mosse, scudo del 5% dei PV massimi, +25 ultimate a tutta la squadra.
- **Equilibrio** (barra ciano): i colpi la consumano (di piu' con vantaggio di colore, marchi, colpi pesanti); a zero il boss e' STORDITO: salta la mossa annunciata e prende piu' danno.
- **Cariche annunciate**: se una mossa del boss e' letale per qualcuno, lo si vede.
- Il boss, se l'hai gia' battuto, impara dal tuo stile (solo in solitaria).

## Combo, reazioni, sinergie
- **LEGAMI**: due compagni che agiscono di fila nello stesso round formano una catena: +15% danno per anello (massimo 4). Fazioni diverse (CROSS): +12 ultimate a entrambi; stessa fazione o colore (UNISONO): colpo ancora piu' forte.
- **Combo** con etichette sulle mosse: COPERTURA (+12% se un compagno ha scudato/curato prima), TRACCIA (colpisci un boss marchiato da un altro: ultimate +10 a te, +5 a chi ha marchiato), DETONAZIONE, FRATTURA, ASSEDIO, RAFFICA, VINCOLO+SCARICA, GUARDIA SPEZZATA, CONDANNA, CASCATA. Una combo scatta una volta per causa e per round.
- **Reazioni** (costano Riserva) contro le cariche: SCHIVATA (1), INTERCETTAZIONE (2), INTERRUZIONE (2), SOCCORSO (2).
- **Sinergie**: RITMO (cambi mossa rispetto al round prima: +10%), ADATTAMENTO (3a volta di fila la stessa mossa: -15%), ARDORE, ULTIMA VOLONTA' (resti a 1 PV), SACRIFICIO.
- **Marchi**: risorsa a pile sul nemico, usata in modo diverso dai personaggi.
- **Stati**: sanguinamento (4% dei PV a round), provocazione, guardia, marchio, debuff/buff a attacco-difesa-velocita'.

## Fazioni
Aure passive tra compagni della stessa fazione schierati (tetto +25%): LibraCorp danno difesa; Rondini colpi critici e danno; Magabondi nessuna aura (prendono meta' del bonus piu' forte in squadra); Kairos legano e indeboliscono e possono spegnere per un po' le aure di una fazione. Ogni personaggio puo' essere **ortodosso** (segue la dottrina e prende il bonus di stile) o **atipico** (stessa fazione, gioca in altro modo).

## Premi
Crediti, nuclei, leghe e pezzi di equipaggiamento (probabilita' per boss). Sfida facoltativa a ogni battaglia: +120 crediti. Dopo 3 sconfitte di fila la battaglia dopo parte con Riserva +2 e uno scudo.
