# Dottrine delle fazioni

Nomi confermati dall'autore: LibraCorp - Protocollo, Rondini - Ronda, Magabondi - Improvvisazione, Kairos - Dissonanza.

Ogni fazione ha un modo di combattere tipico (la **dottrina**). Un personaggio può essere **ortodosso**
(segue la dottrina e prende il bonus di stile) o **atipico** (stessa fazione, quindi dà e riceve l'aura,
ma gioca in altro modo). Le fazioni danno **aure passive** ai compagni schierati della stessa fazione: statistica
fissa per fazione, bonus che cresce con la rarità di chi la dà, con un tetto.

| Fazione | Dottrina | Statistica dell'aura | Stato |
|---|---|---|---|
| LibraCorp | **Protocollo** | Difesa | nome confermato |
| Rondini | Ronda (colpi critici, danno alto, area; cannoni di vetro) | da decidere (critico, velocità o attacco) | parole chiave dell'autore, nome confermato |
| Magabondi | Improvvisazione (economia delle azioni, trovate non convenzionali; nessuna aura, prendono metà del bonus più forte in squadra) | nessuna | parole chiave dell'autore, nome confermato |
| Kairos (nemici, detti anche Anomalie) | Dissonanza (legano, indeboliscono, avvelenano; spengono per un po' le aure di una fazione) | — | parole chiave dell'autore, nome confermato |

## LibraCorp: Protocollo
Parole chiave dell'autore: risposte, counter, riposte, ricarica, munizioni, colpi con munizioni, headshot,
attacco mirato, reazioni sui boss, contrattacco, azioni extra.

Idea generale: resistere, rispondere ai colpi, sparare con munizioni contate e ricaricare al momento giusto.
I poteri vengono dall'equipaggiamento (tecnologia).

Esempio di aura e tratti (valori da provare):
- Vanguard leggendario LibraCorp: +5% difesa a tutti i LibraCorp schierati.
- Quando un LibraCorp viene colpito: +5% difesa e velocità a quel personaggio, al massimo una volta per turno.
- Un personaggio può sommare la difesa ai danni che infligge.
- Un comune o raro LibraCorp con ultimate di squadra (+20% difesa a tutti) si combina con questi: vale quanto
  un personaggio raro.

Regole da fissare: tetto agli effetti sommati (proposta: +25% di aure della stessa fazione), contatore "una volta
per turno", aure valide solo nella squadra del giocatore (per partire).

## Anomalie / Kairos: Dissonanza
Parole chiave dell'autore: binding, debuff, spell binding, veleno, controllo (CC), danni nel tempo (DoT).

Lettura proposta (bozza):
- **Binding (legatura):** un bersaglio non può cambiare operatore o agire con una certa mossa finche' dura.
- **Spell binding (sigillo):** una skill o l'ultimate di un bersaglio e' bloccata per qualche turno.
- **Debuff (maledizione):** riduce attacco, difesa o velocita'; puo' anche spegnere un'aura di fazione.
- **Veleno e DoT:** danno a ogni turno, a pile; il veleno riduce le cure. Il sanguinamento che c'e' gia' resta.
- **CC:** stordimento (perde il turno), provocazione forzata. Con limiti: un bersaglio appena liberato e' immune un turno.
- Sempre annunciati un round prima (come ora) e con una risposta possibile: purificare, intercettare (LibraCorp), agire per primi (Rondini).

Assegnazione ai boss attuali (bozza): Semaforo = CC (stop e via), Tombino = veleno e DoT, Cabina = binding e sigilli
(linea occupata), Distributore = debuff. I Kairos di fine gioco li combinano.

## Rondini: Ronda
Parole chiave dell'autore: colpo critico, danno alto, area (AoE), cannone di vetro.

Lettura proposta (bozza):
- **Cannone di vetro:** molto attacco, pochi punti vita e difesa; vincono se abbattono il boss prima di essere colpiti.
- **Colpo critico:** nel gioco oggi non esiste; sarebbe una statistica nuova (probabilita' e danno critico).
- **Danno alto e area:** mosse che colpiscono tutti i nemici o piu' bersagli (utili nelle battaglie con piu' nemici e nelle fasi con
  scudi da sfondare).
- Resta il tema di lore: piccoli gruppi che agiscono di notte senza dare nell'occhio, quindi agire per primi e non farsi
  notare (velocita', mosse che attirano meno il boss).

## Magabondi: Improvvisazione
Parole chiave dell'autore: economia delle azioni (action economy), trovate (gimmick), tutto cio' che non e' convenzionale.
Sono i piu' atipici: niente stile fisso, ognuno ha la sua regola speciale.

Idee (bozza):
- **Economia delle azioni:** spostare, rimandare o ottenere azioni (ordine ritardato al round dopo con bonus; prendere energia
  in prestito dal round successivo; cambio operatore che non costa; azione dimezzata aggiuntiva).
- **Trovate:** copiare l'ultima mossa di un alleato, rubare un bonus del boss, invertire l'ordine di azione del round,
  trasformare una skill, effetti con esito casuale (sempre deterministici, dal seme dello scontro, per il multiplayer).
- **Rischio:** magia illegale con contraccolpo; nessuna aura da dare, ma prendono meta' del bonus piu' forte presente in squadra.
- Distinzione dai LibraCorp: le azioni extra dei Magabondi sono pianificate (le costruisci tu), quelle di LibraCorp sono
  reazioni (arrivano quando succede qualcosa).


## Come si vince con ogni fazione e cosa fa ogni classe (testi di gioco)

I testi che il giocatore legge (bottone STRATEGIE nell'archivio operatori) stanno in `scripts/battle/strategy_info.gd`:
per ogni classe cosa fa e cosa serve perche' funzioni; per ogni fazione l'idea, la condizione di vittoria, cosa deve fare
il giocatore, cosa c'e' gia' nel gioco e cosa arriva. Quando una meccanica viene implementata, spostarla da "in arrivo" a "gia' nel gioco".
