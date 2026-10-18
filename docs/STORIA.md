# ODISPEL V3 — la storia

Documento di lavoro. Le parti segnate **PROVVISORIO** sono da confermare.
I testi stanno in `data/dialoghi_atto1.json`, generato da `tools/gen_dialoghi.py` (si corregge lo script, poi
`python3 tools/gen_dialoghi.py data/dialoghi_atto1.json`). La struttura dei capitoli è in `data/atto1.json`.

## Nomi (aggiornati il 19 ottobre 2026)

| Personaggio | Prima | Note |
|---|---|---|
| **Lance** | Ferri | id interno resta `ferri` (file, ritratti, modelli) |
| **Nox** | — | |
| **Rio** | Zecca | id interno resta `zecca` |
| **Saul** | — | |
| **Echo** | «il Kairos» | Echo è il suo nome; «Kairos» è la sua specie. Femminile. |
| **Comandante Astrid** | Asta | LibraCorp, istruttrice di Lance |
| **Strix** | Allocco | capoturno di Nox nelle Civette |

## Premessa (quello che il giocatore capisce nella prima scena)

Piazza Centrale, ore 2:58. Echo, un Kairos che vive nelle telecamere della città, ci presenta quattro sconosciuti di
quattro fazioni che si odiano, ognuno lì per un motivo suo:

- **Nox**, Odispeller delle Civette (maghi con licenza), a due minuti dalla fine del turno di notte;
- **Lance**, agente LibraCorp (la polizia che caccia la magia), appena retrocesso a pattuglia;
- **Rio**, 19 anni, Masca: una maschera arrivata per posta gli dà poteri e lui la usa per fare dirette;
- **Saul**, Magabondo contrabbandiere, che deve consegnare un pacco alle tre in punto senza sapere cosa contiene.

Alle tre il pacco si apre: una **cupola rosa** sigilla la città. Su ogni schermo compaiono le loro quattro facce:
«RESPONSABILI DEL SIGILLO. RICERCATI». LibraCorp e Civette arrivano da due lati. Scappano nella stessa direzione.
Dopo il primo mostro (un distributore posseduto) Echo si presenta: la cupola è retta da quattro **Anomalie**; se loro
le chiudono, lei consegnerà le registrazioni della piazza che li scagionano. E a ognuno promette quello che vuole di più:

- **Lance**: chiudere il caso della cupola, tornare in servizio col nome pulito e col grado;
- **Nox**: le ferie che le Civette danno per ogni Anomalia chiusa (dodici settimane: sonno);
- **Rio**: la live dell'anno, una città sotto una cupola con i mostri, in diretta;
- **Saul**: le taglie che LibraCorp paga per ogni Anomalia chiusa.

Ognuno ci guadagna e la cosa è plausibile: per questo si alleano tra loro e si fidano di lei.
**La verità (finale):** Echo non aveva bisogno di quattro fazioni. Le Anomalie tenevano chiuso il varco verso casa sua
e le serviva qualcuno che le chiudesse senza poter andare né da LibraCorp né dalle Civette: quattro persone
**compromesse** (un braccio illegale, una chiamata senza risposta, una maschera, un pacco), che nessuno avrebbe creduto.
Le registrazioni non sono mai esistite e le promesse erano false. Quello che è nato dopo la piazza, invece, era vero.

## Le voci

- **Lance**: articoli del regolamento (anche inventati), «lo metto a verbale», chiama Rio «minorenne». Rigido perché ha paura.
- **Nox**: frasi corte, conta le ore senza dormire (salgono capitolo dopo capitolo), il caffè. Stanca, non cattiva.
- **Rio**: veloce, «raga», titoli di video in MAIUSCOLO, la chat che non c'è più, 32 follower. Dice sempre quello che sente.
- **Saul**: calmo, poche parole, mai un punto esclamativo. Dà un prezzo a tutto; proverbi di nonne inventate («Quale nonna?» «Ne ho tre»). Non dice cosa prova: lo fa.
- **Echo**: precisa (orari, numeri delle telecamere), curiosa degli umani, impara a scherzare e le battute le vengono male.
  Parla durante le esplorazioni (fumetti) tranne dentro le Anomalie, dove le sue telecamere non arrivano.

## L'arco: da sconosciuti a famiglia

| Momento | Dove sono | Cosa cambia |
|---|---|---|
| Prologo | Diffidenza | Lance vuole arrestarli tutti, Saul dorme col pacco sotto la testa, Rio filma tutto, Nox vuole solo il caffè. Echo: «Dormite con un occhio aperto. Lo riconosco.» |
| Cap. 1 · Rosso fisso (Lance) | Primo segreto custodito | Gli altri vedono il braccio magico di Lance e tacciono. Echo «inceppa» la sua telecamera. |
| Cap. 2 · La linea (Nox) | Fiducia | La coprono mentre affronta la notte delle 3:12. Lance rinuncia a un articolo. Serata Nox-Echo: Echo era la telecamera del vicolo, quella notte. |
| Cap. 3 · Vetrina (Rio) | Collaborazione | Rio si toglie la maschera; Saul gli parla sul serio per la prima volta. Echo diventa la sua follower numero 33. |
| Cap. 4 · Il colpo (Saul) | Rischiare la vita | Il Committente tenta Saul. La porta blindata si chiude su Rio: Saul la tiene aperta col proprio corpo. Vigilia: ognuno racconta cosa farà con la promessa di Echo; lei chiede di stare nei contatti di Rio e quasi confessa. |
| Finale · Il varco | Il tradimento | Echo confessa: li ha incastrati lei perché erano compromessi, e ogni promessa era falsa. Ognuno è ferito dove si era legato a lei. Il Committente ruba il varco, la cupola crolla, Lance usa il braccio davanti a tutte le telecamere del paese per salvare Rio: Astrid lo classifica come Anomalia. |
| Cap. 5 · La tangenziale | Famiglia | All'alba scappano insieme. Astrid e Strix al casello. Echo spegne ogni luce e telecamera della città per farli fuggire, anche se per lei è come chiudere gli occhi. Saul regala (non vende) la batteria a Rio; il telefono si riaccende: «Vi vedo.» |

Scelte che il gioco ricorda: fiducia in Echo all'inizio (`echo_fiducia` / `echo_diffidenza`), la telefonata di Saul
(`saul_leale` / `saul_tentato`), tregua o rancore con Echo all'alba (`echo_tregua` / `echo_rancore`), i legami delle serate.

## Capitolo 5 · La tangenziale (nuovo)

Subito dopo la caduta della cupola. Area: tangenziale sopraelevata all'alba, auto abbandonate, il cartellone dei
ricercati, il casello in fondo. Indizi: il cartellone (le descrizioni dei ricercati), il verbale dell'autovelox
(debolezza VIOLA: il flash del telefono di Rio), la radio di un'auto (Astrid e Strix litigano: erano compagni di pattuglia).
Boss: **Autovelox**, un'Anomalia nuova nata dal crollo. Finale al casello e cartello «FINE DELL'ATTO 1».

## Inseguitori ricorrenti

- **Comandante Astrid** — LibraCorp, ha addestrato Lance e gli ha fatto montare il braccio («L'ho costruito io»). PROVVISORIO.
- **Strix** — Civette, capoturno di Nox; l'ha cresciuta nel mestiere e, a modo suo, la protegge. PROVVISORIO.

Si odiano e si rispettano: dieci anni fa erano compagni di pattuglia, poi qualcosa è andato storto (da scrivere).

## Il seguito (piano deciso, da scrivere)

1. **Metà gioco = fine dell'atto 1.** Echo ha confessato, il Committente ha preso il varco, il sigillo è caduto: **si apre il paese**.
2. **Seconda parte — la caccia al Committente**, con LibraCorp e le Civette alle calcagna.
3. **Astrid e Strix** inseguitori ricorrenti, ognuno con un pezzo del passato di Lance e di Nox; a volte un'alleanza scomoda.
4. **Il finale resta quello deciso:** Echo rinuncia a tornare a casa per restare con loro.
