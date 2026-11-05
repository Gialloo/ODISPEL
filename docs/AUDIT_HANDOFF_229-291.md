# ODISPEL — Audit integrativo delle decisioni 229–291

- Branch: `experiment/c2.6-strategy-lab`
- Base: `d7a08f7af98a3c67769dfd03ce32bbd4d145c3a9` (`claude/v3-prologo`)
- Tipo: audit statico preliminare, non implementazione
- Stato: nessuna modifica a codice, dati, scene o architettura
- Limite: non è stato possibile consultare Godot runtime, il progetto locale completo, `BIBBIA_DI_LAVORO.md` e `ODISPEL_TUTTO.md` (non presenti nel repository GitHub esaminato).

## 1. Esito sintetico

Il progetto contiene già una base concreta per molte decisioni di combattimento e per alcune forme di autonomia/relazione narrativa: progressione ed equipaggiamento, SINERGIE, reazioni, Timeline, BREAK, due nemici, arena, indizi, chiacchiere contestuali, dialoghi e flag persistenti.

Non risulta invece dimostrato, nel codice esaminato, un sistema generale di:
- stato relazionale persistente e autonomo tra coppie/personaggi;
- archivio investigativo progressivo con collegamento manuale di prove e teorie;
- conoscenza del mondo strutturata per fonte, affidabilità e contraddizioni;
- conseguenze relazionali persistenti che influenzino dialoghi, azioni individuali e combattimento;
- specializzazioni/build con reversibilità regolata;
- trasformazione persistente e sistematica delle aree a seguito degli eventi.

Questi punti non vanno implementati come una rete di sistemi indipendenti. La direzione raccomandata è un nucleo dati narrativo leggero (flag/eventi/relazioni scoperte) e integrazioni mirate ai sistemi già presenti, riservando sistemi autonomi a funzionalità identitarie comprovate.

## 2. Limiti documentali e decisioni mancanti

L'handoff fornito contiene regole testuali per 229–232, 261–291 e parti di 60–62, 105–109, 128–131, 148–150. Per 181–185 è disponibile solo l'approvazione C. Mancano i testi delle decisioni 63–104, 110–127, 132–147, 151–180, 186–228 e 233–260.

Di conseguenza:
- questo audit non certifica la copertura delle circa 260 decisioni precedenti;
- non ricostruisce decisioni mancanti per inferenza;
- la mappatura delle regole di combattimento precedenti usa solo i dettagli effettivamente presenti negli handoff e nel codice ispezionato;
- la decisione 292 resta esclusa: non approvata.

## 3. Stato del progetto osservato

Fonti lette sul branch:
- `README.md`, `docs/STORIA.md`, `docs/HANDOFF_PROLOGO_3D.md`;
- `scripts/engine/battle_flow.gd`, `battle_resolver.gd`, `battle_ai.gd`, `combos.gd`, `duo_techs.gd`, `stability.gd`, `arena.gd`, `gregario.gd`, `resource_telemetry.gd`;
- `scripts/v3/story.gd`, `dialog_data.gd`, `banter.gd`, `area.gd`, `progress.gd`, `squad_menu.gd`, `skill_menu.gd`;
- `data/atto1.json`, `data/dialoghi.json`;
- elenco dei test in `tests/unit/`.

Il README descrive il progetto come demo V3, con esplorazione ad aree, storia a passi, salvataggio, chiacchiere, progressione, abilità equipaggiabili, SINERGIE, reazioni, Timeline, SLANCIO, RITMO e BREAK. Il repository non contiene la Bibbia di lavoro citata nel README: il suo contenuto va acquisito prima del controllo canonico completo.

## 4. Mappatura per decisione

Legenda:
- **Supportato**: una struttura concreta è presente nel codice osservato; non significa che ogni requisito sia già soddisfatto.
- **Parziale**: esistono componenti riutilizzabili, ma manca parte del comportamento approvato.
- **Narrativo/dati**: è principalmente contenuto, flag, dialogo o presentazione.
- **Non dimostrato**: non è stato trovato un sistema sufficiente nel codice letto.
- **Futuro**: non proporre per la demo senza ulteriore priorità e approvazione.

### Relazioni e autonomia — 105–109, 128–131, 148–150, 229–231, 261, 285, 288–291

| Decisione | Stato osservato | Valutazione / direzione |
|---|---|---|
| 105 | Parziale | `Story.active_bonds()` espone legami narrativi attivi con bonus in battaglia; non dimostra coordinamento dinamico generale basato su stati relazionali. |
| 106 | Parziale | Dialoghi, banter, flag e legami danno una rappresentazione ibrida di base. |
| 107 | Non dimostrato | Non è stata verificata una pipeline di stati relazionali che modifichi le azioni individuali con bonus/malus contestuali. Non aggiungerla prima di definire limiti e leggibilità. |
| 108–109 | Non dimostrato | Non è stato trovato un archivio relazionale investigativo con collegamento manuale di prove/teorie. |
| 128–131 | Parziale | Flag, dialoghi e chiacchiere possono rappresentare segnali e reazioni; mancano evidenze di una macchina relazionale persistente con dissenso, recupero, assenze e reazioni collettive. |
| 148–150 | Parziale | I flag e i legami possono sostenere relazioni segrete/pubbliche e rapporti con NPC, ma non è emerso un modello esplicito di riservatezza e scoperta. |
| 229 | Principio architetturale | Applicare come criterio di valutazione a ogni proposta; non richiede un sistema runtime. |
| 230–231 | Parziale | Banter contestuale e dialoghi sono già presenti. Autonomia limitata e leggibilità dei cambiamenti richiedono prima una struttura dati minima, non simulazione continua. |
| 261 | Narrativo/dati | Ricordi e nostalgia sono contenuto caratteriale: possono emergere in scene, banter e rifugi senza una simulazione autonoma. |
| 285, 288–291 | Parziale | La storia a passi, i dialoghi, i flag e i legami sono una base per contenuti facoltativi e conseguenze. Non è provata una propagazione sistematica e di lungo periodo delle scelte fra tutti i sistemi. |

**Proposta:** introdurre solo dopo approvazione un registro leggero di eventi/relazioni (chi, con chi, evento condiviso, visibilità, stato narrativo, conseguenze autorizzate). Nessun tick autonomo in background; evoluzioni solo su eventi significativi o soglie esplicite. Le conseguenze maggiori restano guidate dalla storia. Gli effetti in combattimento vanno limitati a coppie e situazioni motivate, senza moltiplicare combinazioni.

### Archivio e conoscenza — 232, 264, 280, 286–287

| Decisione | Stato osservato | Valutazione / direzione |
|---|---|---|
| 232 | Parziale | Indizi di area e flag di debolezza già esistono; non è stato trovato un archivio generale consultabile che rispetti conoscenza progressiva e non onniscienza. |
| 264 | Parziale | Gli indizi possono rivelare debolezze e i test `test_v3_registro` / `test_v3_lezioni` esistono; verificare esattamente il loro ambito prima di estenderli. |
| 280 | Parziale | Descrizioni/indizi e sistema di registro possono supportare interazioni scoperte; non è dimostrato un catalogo di interazioni fra abilità. |
| 286–287 | Non dimostrato | Nessun modello trovato per provenienza, affidabilità, contraddizione e manipolazione delle fonti. |

**Proposta:** un solo Archivio/Registro progressivo con categorie (indizi, nemici, abilità/interazioni, persone/relazioni, fonti). Ogni voce si sblocca da un evento osservato. Le fonti conservano autore/provenienza e stato (confermato, incompleto, contraddetto, sospetto) solo se il contenuto narrativo lo giustifica. Le teorie manuali sono fase futura, non prerequisito per la demo.

### Combattimento — 60–62, 262–280

| Decisioni | Stato osservato | Valutazione / direzione |
|---|---|---|
| 60–62 | Parziale / da verificare | Il motore contiene DUO, SINERGIE, Timeline e sistemi anti-catena in più componenti; non è stata verificata un'implementazione completa di RISONANZA multipla con ordine ibrido. Non dichiararla implementata senza audit mirato. |
| 262 | Supportato come direzione, da validare con playtest | Il motore ha combo, LINK/DUO, BREAK, RITMO, parate, reazioni, Timeline e telegraph. La promessa strategia-spettacolo è una qualità esperienziale: richiede playtest umano, non si dimostra con test unitari. |
| 263 | Parziale | Equipaggiamento e progressione in `Progress` / `SquadMenu`; non è stata verificata una distinzione esplicita fra preparazione ordinaria stabile e preparazione contestuale dei boss. |
| 264–265 | Parziale | Archetipi, telegraph, debolezze e boss con regole sono presenti. Verificare leggibilità delle informazioni e coerenza delle famiglie con test e playtest. |
| 266 | Parziale | Progressione fino al livello 100 e boss/fasi esistono; manca audit completo della curva di complessità e dei momenti di consolidamento. |
| 267–268 | Parziale | Kit, abilità equipaggiabili, SINERGIE e DUO sostengono stili e collaborazione; occorre misurare che nessuna coppia/composizione sia obbligatoria. |
| 269 | Parziale | EN, Gauge, HYPE, Reserve, Ardore e telemetria sono presenti. La telemetria misura variazioni, ma non dimostra da sola che le decisioni siano significative o che il giocatore non accumuli per paura. |
| 270–271 | Supportato come base | Guardia, parata, schivata, reazioni e minigiochi temporizzati sono presenti; occorre verificare accessibilità e validità degli approcci non perfetti. |
| 272–273 | Parziale | Rischio, telegraph, fasi, interruzioni, BREAK e cambi di ciclo esistono; la varietà reattiva del nemico va validata. |
| 274 | Parziale | `Arena` fornisce eventi/condizioni ambientali; verificare quanti incontri li usino in modo leggibile e non ridondante. |
| 275–280 | Parziale | Progressione e kit offrono personalizzazione; non è stata verificata una vera specializzazione con respec/reversibilità, né un archivio delle interazioni scoperte. |

**Proposta:** non creare un nuovo motore di combattimento. Completare prima l'audit d'integrazione dei sistemi già presenti (Timeline, BREAK, RITMO/APICE, DUO, SLANCIO, combo, LINK, Arena, risorse, Progress/Kits). Per 60–62 serve una verifica puntuale del percorso RISONANZA prima di qualunque codice. Per 262, 267–280 servono metriche e playtest, non soltanto nuove meccaniche.

### Progressione, esplorazione e mondo — 276–284

| Decisioni | Stato osservato | Valutazione / direzione |
|---|---|---|
| 276–279 | Parziale | `Progress` e `SquadMenu` implementano livelli, sblocchi, slot e abilità equipaggiabili. Non è stata verificata la specializzazione modulare né il cambio build con costi/condizioni. |
| 281 | Non dimostrato | Le abilità fuori dal combattimento non risultano un sistema generale; le aree hanno interazioni e indizi specifici. Preferire interazioni contestuali di personaggio quando narrativamente naturali. |
| 282–283 | Supportato come struttura | Aree delimitate con layout, percorsi, indizi, nemici, uscita e progressione guidata sono già presenti in `atto1.json` e `Area`. |
| 284 | Parziale | `Story.area_state` e flag consentono persistenza locale; non è dimostrata una trasformazione sistematica delle aree tra visite. |

**Proposta:** mantenere la struttura a zone. Implementare trasformazioni solo per eventi narrativi importanti e solo nelle aree che il giocatore rivisita; aggiornare dati/flag e interazioni esistenti anziché creare un sistema di mondo dinamico generale.

### Principi e decisioni trasversali — 229, 230–232, 285–291

Queste decisioni vanno trattate come vincoli di qualità e contenuto, non come richieste automatiche di sistemi:
- 229: profondità narrativa massima con costo tecnico proporzionato.
- 230–231: autonomia limitata e cambiamenti relazionali leggibili.
- 232: archivio non onnisciente.
- 285–287: contenuti facoltativi e lore a strati con fonti prospettiche.
- 288–291: conseguenze, recuperabilità, autonomia e influenza reciproca del gruppo.

## 5. Dipendenze principali

1. **Eventi e flag narrativi** sono prerequisito per relazioni persistenti, conseguenze, archivio e trasformazioni delle aree.
2. **Relazioni** devono essere definite prima di collegarle a SINERGIE o azioni individuali.
3. **Registro/Archivio** deve ricevere dati dagli eventi, dagli indizi e dalle scoperte; non deve diventare una fonte autonoma di verità.
4. **RISONANZA multipla** dipende da SINERGIA, DUO/tecniche collettive, Timeline e anti-catena.
5. **Specializzazioni** dipendono da Progress, Kits, SquadMenu, salvataggi e bilanciamento.
6. **Abilità esplorative** dipendono dal design delle aree e dalla navigazione; non devono creare soft-lock o personaggi obbligatori.
7. **Trasformazione delle aree** dipende da Story flags e stato persistente dell'area.

## 6. Priorità raccomandate

### P0 — Verifica e consolidamento (prima di aggiungere sistemi)
- Ottenere Bibbia di lavoro e handoff precedente.
- Recuperare le decisioni mancanti 1–228 e 233–260, specialmente le decisioni 181–185.
- Verificare il comportamento reale dei test esistenti.
- Audit mirato di RISONANZA, Timeline, BREAK, APICE, DUO, SLANCIO e relazioni già esistenti.
- Eseguire test Godot locali sul branch sperimentale; il connettore GitHub non esegue Godot.

### P1 — Integrazioni leggere, solo dopo approvazione della proposta
- Migliorare l'uso coerente di flag/eventi già presenti.
- Rendere consultabili indizi e conoscenze già scoperte, senza rivelare contenuti non acquisiti.
- Dare conseguenze narrative visibili alle relazioni già stabilite.
- Migliorare segnali e descrizioni delle meccaniche nemiche già presenti.

### P2 — Sistemi identitari da progettare separatamente
- Archivio investigativo con fonti, contraddizioni e teorie manuali.
- Stati relazionali persistenti e dinamiche autonome limitate.
- Specializzazioni con reversibilità.
- Interazioni esplorative distintive dei personaggi.
- Trasformazioni persistenti di aree selezionate.

### P3 — Futuro / opzionale
- Evoluzione relazionale autonoma estesa.
- Reti complesse di segreti e relazioni fra molti NPC.
- Simulazione sistemica di alleanze/conflitti del gruppo.
- Teorie investigative che richiedano combinazione libera di prove, se non necessarie all'arco attuale.

## 7. Rischi di scope e manutenzione

- **Combinatoria relazionale:** effetti per ogni coppia e ogni situazione crescono rapidamente; limitare gli effetti sistemici a coppie narrative giustificate.
- **Doppia fonte di verità:** non duplicare i flag di Story in un nuovo sistema indipendente senza migrazione e regole chiare.
- **Archivio onnisciente:** il registro deve essere alimentato da scoperte effettive, non da tutti i dati statici.
- **Build instabili:** il respec richiede compatibilità con salvataggi esistenti e test di regressione.
- **Sovraccarico UI:** Archivio, relazioni e segnali devono essere leggibili su telefono, non introdurre HUD permanente.
- **Falsi indicatori di qualità:** win-rate e telemetria AI non provano divertimento, libertà o soddisfazione.
- **Regressioni del motore:** evitare modifiche simultanee a Timeline, resolver, risorse e sistemi di presentazione.

## 8. Contraddizioni e punti da chiarire

Non è emersa una contraddizione certa tra le decisioni fornite e il codice esaminato. Sono però presenti punti da verificare:
- La storia in `data/atto1.json` e `docs/STORIA.md` include un atto con capitolo 5 e un finale d'arco; non trattare il finale dell'atto come finale dell'intero gioco.
- Gli ID interni `ferri` e `zecca` sono ancora usati nel codice e nei dati, mentre i nomi canonici sono Lance e Rio: è una distinzione deliberata documentata in `docs/STORIA.md`, non necessariamente un errore.
- Il README cita `BIBBIA_DI_LAVORO.md` e il guardiano della Bibbia cita `ODISPEL_TUTTO.md`, ma questi documenti non sono presenti nel tree GitHub esaminato. Il controllo canonico resta incompleto.
- L'ordine 229–291 non coincide con una richiesta di implementare tutto: l'handoff stesso impone audit, proposta e approvazione.
- Decisione 292 non approvata: nessuna implementazione o assunzione.

## 9. Proposta incrementale

**Passo 1 — Completamento documentale:** aggiungere la Bibbia e l'handoff precedente; recuperare le decisioni mancanti. Nessuna modifica gameplay.

**Passo 2 — Audit tecnico puntuale:** per ciascun sistema già presente, tracciare il percorso dati completo (input → regola → evento → UI → salvataggio → test). In particolare RISONANZA e relazioni.

**Passo 3 — Matrice decisione/codice/test:** aggiornare questa analisi con riferimenti a file, funzioni e test precisi, assegnando a ogni decisione uno stato definitivo.

**Passo 4 — Proposta di patch piccole:** presentare modifiche atomiche, dipendenze e criteri di accettazione; attendere l'approvazione dell'autore.

**Passo 5 — Implementazione sul solo branch sperimentale:** una famiglia di modifiche alla volta, test locali, commit separati e report delle limitazioni. Nessun merge automatico.

## 10. Verifiche non eseguite

Questo documento deriva da lettura statica del repository GitHub. Non sono stati eseguiti:
- Godot headless o test unitari;
- simulazioni di combattimento;
- build PC/Android;
- playtest umano;
- verifica su telefono o risoluzioni reali;
- controllo completo della Bibbia e del canone.

**Conclusione:** la base V3 contiene già molti dei pilastri del combattimento e dell'esplorazione. Il maggiore divario non è la mancanza di decine di nuove meccaniche, ma la mancanza di alcune connessioni persistenti e leggibili fra eventi, conoscenza, relazioni e conseguenze. Prima di scrivere altro codice occorre completare il quadro documentale e chiudere l'audit tecnico mirato.
