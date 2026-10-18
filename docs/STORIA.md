# ODISPEL V3 — la storia

Documento di lavoro. Le parti segnate **PROVVISORIO** sono nomi o scelte da confermare.

## Premessa

Una notte una cupola rosa chiude la città. Dentro restano quattro sconosciuti — **Ferri** (ex LibraCorp, vanguard),
**Nox** (centralinista delle Civette, warden), **Zecca** (ragazzo di 19 anni, Masca, striker) e **Saul** (truffatore, striker) — e una voce che
parla da una telecamera di sorveglianza: il **Kairos**. Il Kairos dice di essere bloccato qui come loro e propone un
accordo: lui li guida verso le Anomalie che tengono su la cupola, loro le spengono. Ogni Anomalia è un oggetto
quotidiano diventato un mostro (un distributore, un semaforo, una cabina telefonica, un manichino, una cassaforte).

## Come si racconta (senza bombardare di filmati)

- **Scene corte** in stile Persona 5: ritratti e fumetti, un riassunto in una riga se le salti.
- **Chiacchiere in esplorazione**: fumetti con faccina che non fermano il gioco (commenti sui posti, battute fra loro, frasi tipiche).
- **Indizi** sparsi nelle aree: leggerli è facoltativo, ma rivelano la debolezza del boss.
- **Serate al rifugio** a fine capitolo: scegli con chi passare la sera → nasce un **legame** (+5% attacco alla coppia, PROVVISORIO).
- **Scelte** con conseguenze piccole ma ricordate (fiducia nel Kairos, Saul e la telefonata del Committente).

## Atto 1 (in gioco dalla 0.30.0)

| Capitolo | Luogo | Boss | Cosa succede |
|---|---|---|---|
| Prologo · La notte della cupola | strada | Distributore | La cupola cade, i quattro si incontrano, l'accordo col Kairos, il rifugio nella metro. |
| 1 · Rosso fisso | Incrocio Nove → dentro l'Anomalia | Semaforo | Auto congelate, la barriera LibraCorp; Ferri riconosce le procedure dei suoi ex colleghi. |
| 2 · La linea | Vicolo delle Civette → dentro la linea | Cabina | Tutti i telefoni squillano alle 3:12; la linea porta la voce del capoturno di Nox. |
| 3 · Vetrina | Galleria Lumière → dietro il vetro | Manichino | Chi entra esce senza faccia; Zecca vede una copia di sé. |
| 4 · Il colpo | Caveau LibraCorp | Cassaforte | Il Committente chiama Saul e offre una via d'uscita solo per lui (scelta: dirlo agli altri o no). |
| Finale · Il varco | la piazza | — | Il varco si apre. Prime crepe nel Kairos; si sentono per radio **Asta** e **Allocco**. |

Ogni area ha frammenti d'Anomalia minori (si possono colpire prima che ti tocchino = vantaggio; se ti toccano = agguato).

### Inseguitori introdotti nell'atto 1 (solo voci alla radio)

- **Comandante Asta** — LibraCorp, ex istruttore di Ferri. Nome PROVVISORIO.
- **Allocco** — Civette, ex capoturno di Nox. Nome PROVVISORIO.

Si odiano e si rispettano: lavorano per fazioni rivali ma si riconoscono come gli unici professionisti in campo.

## Il seguito (piano deciso, da scrivere)

1. **Metà gioco = fine dell'atto 1 — il tradimento del Kairos.** Nel finale dell'atto 1 (scena `varco`) il Kairos confessa di averli incastrati, il Committente gli ruba il varco, il sigillo cade e
   **si apre il paese** (mappa più grande, più città). Nel seguito si scopre fin dove il Kairos lavorava (senza saperlo)
   per il Committente: le Anomalie spente non servivano a liberare la città, ma a raccogliere qualcosa (PROVVISORIO).
2. **Seconda parte — la caccia al Committente.** La squadra insegue il Committente fuori dalla città, con
   **LibraCorp** e **le Civette** alle calcagna.
3. **Inseguitori ricorrenti con un volto:** Asta (contro Ferri) e Allocco (contro Nox). Battaglie ripetute,
   ognuna con un pezzo del loro passato; fra loro due rivalità e rispetto, a volte un'alleanza scomoda.
4. **Il finale resta quello deciso:** il Kairos, che ha tradito, alla fine **rinuncia a tornare a casa per restare con loro**.

Semi già piantati nell'atto 1 per il tradimento: la scelta di fiducia/diffidenza verso il Kairos (flag
`kairos_fiducia` / `kairos_diffidenza`), le sue risposte evasive nelle serate al rifugio, il varco finale.

## Dove sta cosa

- Struttura e aree: `data/atto1.json` (capitoli → passi; aree con indizi, nemici, boss, chiacchiere).
- Testi: `data/dialoghi_atto1.json` (scene, scelte, chiacchiere) e `data/dialoghi.json` (testi comuni).
- Salvataggio: `user://salvataggio.cfg` (capitolo, passo, scelte).
