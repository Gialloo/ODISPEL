# HANDOFF PER L'IA: creare personaggi e sinergie di ODISPEL

Sei un'IA incaricata di **ideare e bilanciare nuovi personaggi (operatori) e nuove sinergie** per ODISPEL.
Questo documento contiene tutto quello che serve: il gioco, le regole vere del motore, i numeri, i dati dei
14 personaggi che esistono già, il formato esatto in cui devi consegnare e cosa NON devi inventare.

Chi riceve la tua consegna è un'altra IA/sviluppatore che la trasforma in codice. Se rispetti il formato e il
vocabolario degli effetti (sezione 6 e 9), i tuoi personaggi entrano nel gioco senza che nessuno debba reinterpretarli.

> Regola d'oro: **usa solo gli effetti elencati qui**. Se un'idea richiede un effetto che non c'è, non scartarla:
> segnalala nella sezione "PROPOSTE CHE RICHIEDONO CODICE NUOVO" della consegna, con una descrizione chiara.

---

## 1. Il gioco in breve

ODISPEL è un battler **cooperativo a turni** (e ora anche PvP) in stile fantasy urbano notturno e "strano".
Un gruppo di **operatori** (personaggi) affronta **boss** nati da oggetti quotidiani impazziti (distributore,
semaforo, tombino, cabina telefonica, ascensore, manichino, orologio, specchio). Tono: pop, neon, un po' inquietante
ma giocoso, mai horror crudo. Interfaccia da "sorveglianza/CCTV + fumetto". Si gioca su telefono e PC, orizzontale 1280x720.

- Si combatte a **round**. Ogni round il giocatore sceglie un ordine per ogni suo operatore in campo, poi tutto si risolve
  insieme in ordine di priorità e velocità.
- Il boss **annuncia** la mossa del round prima che si risolva.
- Co-op fino a 6 giocatori contro un boss; PvP 1v1, 2v2 e tutti-contro-tutti (anche con abilità e passive uniche).
- Progressione: si reclutano operatori (gacha a monete), si potenziano (livello con monete+nuclei, **rank** con le copie,
  equipaggiamento con leghe), si sbloccano boss e tre difficoltà (NORMALE, DIFFICILE, INCUBO).

### Il mondo (fatti dell'autore; le parti "bozza" si possono proporre)
- **Odispeller** = i maghi di questo mondo. Esistono un albo e una **licenza magica**.
- **LibraCorp** = gruppo paramilitare finanziato dal misterioso **Leviatano** (una specie di Bruce Wayne di questo universo).
  Poliziotti contro Anomalie e maghi; equipaggiamento che ha poteri (tecnologia). Dottrina: **Protocollo** (risposte,
  contrattacchi, munizioni contate, ricarica, colpi mirati/headshot, reazioni).
- **Rondini** = Odispeller che fanno le ronde di notte in piccoli gruppi per proteggere gli umani. Dottrina: **Ronda**
  (colpi critici, danno alto, area, cannoni di vetro, agire per primi).
- **Magabondi** = maghi rogue senza licenza: buoni, neutrali o cattivi. Dottrina: **Improvvisazione** (economia delle azioni,
  trovate non convenzionali). Non danno aure, ricevono metà della migliore aura in squadra.
- **Kairos / Anomalie ("i Sinistri")** = demoni da un altro piano, i nemici. Dottrina: **Dissonanza** (legare, indebolire,
  avvelenare, spegnere per un po' le aure di una fazione). Due personaggi (Eco, Nico) sono Kairos alleati/storici.
- Il giocatore è un operatore neutrale che coordina squadre di fazioni diverse da una centrale di sorveglianza.

Nomi dei personaggi: brevi (3-6 lettere), italiani/internazionali, facili da leggere su schermo piccolo.
Tutti i testi del gioco sono **in italiano**.

---

## 2. Le regole del combattimento (numeri veri del motore)

### 2.1 Statistiche
Ogni operatore ha **PV, ATK, DIF, VEL** (e CRIT, in per mille: 100 = 10%).
Base per **classe** (livello 1, rank 0, comune):

| Classe | PV | ATK | DIF | VEL | Ruolo |
|---|---|---|---|---|---|
| striker | 900 | 100 | 20 | 110 | fa danno, fragile |
| vanguard | 1300 | 80 | 50 | 90 | regge i colpi, protegge |
| warden | 1000 | 80 | 30 | 100 | cura, scudi, supporto |

Formula: `stat = base_classe × (1 + 0.08×(livello−1)) × (1 + bonus_rank×rank) × mult_rarità × stat_mult_personaggio`
+ equipaggiamento (arma +12 ATK, petto +140 PV e +6 DIF, stivali +8 VEL, scalati per rarità ×1.0/1.3/1.7/2.2 e +10% a livello pezzo).
- `mult_rarità` = 1.00 / 1.08 / 1.18 / 1.32 (comune, rara, epica, leggendaria).
- `bonus_rank` per rank = 4% / 5% / 6% / 8% per rarità. Rank da 0 a 5.
- `stat_mult` (opzionale, per personaggio): es. Angela `{hp:0.75, atk:1.2, def:0.8}`. Serve per i "cannoni di vetro" ecc.
  **Regola**: la somma dei moltiplicatori deve restare vicina a 1 (guadagni in una statistica = perdite in un'altra).

### 2.2 Danno
`danno = ATK × mult_mossa × vantaggio_colore × bonus_marchi × altri_bonus` poi
`× 100 / (100 + DIF_bersaglio × (100−pierce)/100)`; Guardia = ×0.5; scudo assorbe prima dei PV; minimo 1.
Critico: probabilità = CRIT (per mille) + bonus; danno critico ×1.5 (colore verde +0.2).

### 2.3 Colori (le fondamenta di ogni operatore)
Cinque colori, ognuno con un **archetipo** fisso (sempre attivo, non si può cambiare):

| Colore | Archetipo | Effetto |
|---|---|---|
| rosso | STR forza | +10% ATK; SLANCIO: ogni colpo messo a segno +3% danno, fino a 5 |
| giallo | PSY sintonia | cure e scudi +20%; +1 energia a fine round; +6% DIF |
| viola | INT analisi | +6% CRIT; marchio e sanguinamento durano +1 round; +12% danno ai bersagli marchiati |
| verde | DEX precisione | +12% CRIT, +20% danno critico, ogni critico carica +10 ultimate; cure/scudi possono essere critici ×1.5 |
| blu | QCK scatto | +12% VEL; parte con 25 di ultimate; i colpi la caricano +40% |

**Ruota dei colori**: rosso > verde > blu > rosso; giallo ↔ viola. Vantaggio ×1.5, svantaggio ×0.67.

### 2.4 Rarità e reclutamento
comune / rara / epica / leggendaria. Tiro del reclutamento: 55% / 30% / 12% / 3% (garanzia epico+ ogni 30 senza).
Un reclutamento costa 300 monete (10 per 2700). Più è rara, più l'operatore è forte di base e **più potenzia** la sua passiva,
le sue mosse e la sua aura col rank. I personaggi `story_only` non escono dai reclutamenti (arrivano dalla storia).

### 2.5 Energia, munizioni, ultimate
- **Energia**: massimo 6, si parte da 2. +1 a round se in campo, +2 se in panchina. Le abilità costano 0-3.
- **Ultimate**: barra 0-100. +15 per colpo messo a segno, +10 per colpo subito (modificatori di colore). Piena = ultimate usabile; si azzera.
- **Munizioni (solo LibraCorp)**: tetto di default 3 (alcuni più alti: Dafne 6, Angela 12). Le mosse con `ammo` le spendono;
  Guardia e Ricarica ne danno. Un LibraCorp ortodosso con ≥1 munizione **risponde al fuoco** quando il boss lo colpisce (mezzo danno).
- **Marchi sul boss** (fino a 6): ogni marchio +10% danno ricevuto dal boss (+15% per i colpi con munizioni). Alcune mosse li spendono.

### 2.6 Stati
`guard` (danno ×0.5, 1 round), `taunt` (il boss/avversario deve colpire chi provoca), `bleed` (4% PV max a fine round, ignora scudi),
`mark` (bersaglio marchiato: +danno), `hidden` (nascosto: 40% dei colpi nemici mancano), `ronda` (carica delle Rondini).
Debuff/buff alle statistiche: **gradi** (ogni grado = 15% della statistica), durata 2 round. Gli scudi svaniscono a fine round.

### 2.7 Ordine di azione
Priorità della mossa (0 normale, 1 alta, 2 altissima), poi VEL, poi nome. Cambio operatore: prima di tutto.

### 2.8 Front row e back row (co-op)
Fino a 6 operatori nel party: 3 in **front row** (agiscono) e gli altri in **back row** (panchina, recuperano più energia, entrano a metà battaglia
con eventuale "entrata scudata"). In rete ogni giocatore porta 3 operatori e ne ha 1 in campo. In PvP: stessa cosa, 1 in campo + 2 riserve.

### 2.9 Sistema di sinergie GIÀ ESISTENTE (devi progettare sopra a questo)
1. **Aura di fazione**: ogni operatore vivo di una fazione dà ai compagni vivi della stessa fazione (sé compreso) un bonus
   alla statistica d'aura della fazione: **comune +1%, rara +2%, epica +3.5%, leggendaria +5%**, somma con tetto **+25%**.
   Statistica per fazione: LibraCorp = DIF, Rondini = CRIT, Magabondi = nessuna (ricevono metà della migliore), Kairos = nessuna.
2. **Stile ortodosso / atipico**: l'**ortodosso** dà e riceve l'aura intera e ha il tratto di dottrina (LibraCorp: *Protocollo*, colpito e in piedi = +5% DIF e VEL;
   Rondini: *Ronda*, carica che rende potenziato il prossimo attacco ×1.3 con +25% critico). L'**atipico** dà/riceve metà aura ma ha +8% ATK, +5% VEL e un
   **tratto personale** (dipende dalla rarità: comune solo bonus base, raro piccola aggiunta, epico tratto evidente, leggendario tratto che cambia il gioco).
3. **LINK** (catena tra compagni): se due compagni agiscono di fila senza che il boss si intrometta nasce un anello. Ogni anello +15% danno (max 4).
   **UNISONO** = stessa fazione o stesso colore: anello doppio. **CROSS** = fazioni e colori diversi: carica +12 ultimate a entrambi.
4. **Archetipi di colore** (sezione 2.3) e **ruota dei colori**.
5. **Marchi** (viola/gialli/verdi li usano), **munizioni** (LibraCorp), **sanguinamento**, **guardia/provoca**, **evocazioni** (torretta, drone di Angela).
6. **Rank**: ogni rank potenzia statistiche, passiva e mosse (rank 1: abilità 1+; rank 2: abilità 2+; rank 3: ultimate+; rank 4: abilità 1 e 2+; rank 5: ultimate++ e RISVEGLIO, +25 ultimate di partenza).
7. **Boss** a cui contrapporsi: Distributore (colpi pesanti a un bersaglio, scosse/sanguinamento), Semaforo (stop/CC), Tombino (veleno/DoT), Cabina (binding/sigilli), Ascensore, Manichino, Orologio, Specchio.

Sinergie **non ancora implementate** ma desiderate (ottimi punti dove l'IA può proporre): Magabondi *Improvvisazione* (economia delle azioni, copiare/rubare/invertire),
Kairos *Dissonanza* (legature, sigilli, veleno, spegnere aure), riposte LibraCorp più ricche, aure delle Rondini oltre il critico.

---

## 3. Anatomia di un personaggio (tutti i campi che devi fornire)

Per ogni personaggio consegna **tutti** questi campi. Esempi reali dal gioco.

### 3.1 Identità e kit di base (`BattleContent.CHARACTERS`)
```
"kira": {"name": "Kira", "color": "viola", "cls": "striker", "rarity": 1,
         "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk", "faction": "rondini"}
```
- `color`: rosso | giallo | viola | verde | blu.
- `cls`: striker | vanguard | warden.
- `rarity`: 0 comune, 1 rara, 2 epica, 3 leggendaria.
- `faction`: libracorp | rondini | magabondi | kairos.
- `style` (opzionale): `"atipico"` (default ortodosso).
- `skill`: id di una mossa base (famiglia, sezione 5.2) o di una mossa unica; `ult`: id di ultimate (base o unica); `passive`: passiva generica (p_atk, p_hp, p_swap, p_hunter).
- Opzionali: `role` (etichetta es. "Tiratore scelto"), `ammo_max` (solo LibraCorp), `stat_mult` (vedi 2.1), `story_only: true`.

### 3.2 Passiva unica (`Signatures.PASSIVES`)
Una sola per personaggio, scegli una **chiave** dalla sezione 6.1 e un valore base (rank 0). Cresce col rank (+8/10/12/15% per rank in base alla rarità).
```
"kira": {"name": "Scintilla viola", "key": "dmg_vs_mark", "base": 0.15}
```

### 3.3 Abilità uniche (`Signatures.MOVES` + `Signatures.SKILLS`)
1 o 2 (leggendari fino a 3 per Dafne/Angela) abilità **sempre disponibili**. Formato (vedi vocabolario 6.2):
```
"u_kira_a": {"name": "Taglio spettrale", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy",
             "mult": 1.8, "pierce": 60, "status": {"mark": 1},
             "bonus": {"stat": "crit", "pct": 20}, "unique": "kira"}
```
e in `SKILLS`: `"kira": ["u_kira_a"]`. L'id inizia con `u_<personaggio>_<lettera>`.
Un'**ultimate unica** (facoltativa, di solito solo per leggendari) ha `"kind": "ult", "cost": 0`.

### 3.4 Tratto atipico (`Atypical.TRAITS`)
Solo per i personaggi che possono essere scelti come atipici. Dipende dalla rarità (vedi 2.9.2). Usa effetti `fx` dalla sezione 6.3 oppure bonus statistici `mods` o partenza `energy`/`gauge`.
```
"kira": {"name": "Lama in ombra", "text": "+6% critico.", "mods": {"crit": 60}}
```

### 3.5 Testi (`Lore.CHARACTERS`) — in italiano, 3 campi
```
"kira": {"tag": "Colpi pesanti, poca vita",
         "lore": "Ragazza dei vicoli che ha imparato a incanalare la magia nei pugni. Non ama le regole, ama chiudere la partita in fretta.",
         "tactic": "Accumula energia, poi COLPO CARICATO (x2). Lascia che un vanguard attiri il boss e spendi SPEZZATUTTO nel momento giusto."}
```
- `tag`: una riga sotto il nome (max ~40 caratteri).
- `lore`: 1-2 frasi, chi è, legata alla fazione e al mondo. (La lore attuale è una bozza dell'autore: puoi proporre di meglio.)
- `tactic`: come usarlo, **coerente con kit, passiva e sinergie** (nomina le mosse in MAIUSCOLO).

### 3.6 Arte (la produce un'altra pipeline, ma descrivila)
Fornisci per ogni personaggio una **descrizione visiva** di 3-5 righe (capelli, occhi, abiti, colori dominanti coerenti col colore di gioco, accessorio simbolo,
espressione tipica) pronta per il documento `docs/HANDOFF_ARTE_IA.md` (stile anime/visual novel, cel shading, occhi grandi e lucidi, niente sfondo).

---

## 4. Il roster attuale (per non duplicare e per capire il bilanciamento)

Statistiche a **livello 1 rank 0** e a **livello 20 rank 5** (senza equipaggiamento).

| Id | Nome | Col. | Classe | Rar. | Fazione | Stile | PV/ATK/DIF/VEL (L1) | PV/ATK (L20 R5) | Abilità uniche | Ultimate | Passiva unica (chiave) | Tratto atipico |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| kira | Kira | viola | striker | rara | Rondini | ort. | 972/119/22/119 | 3062/374 | u_kira_a | spezzatutto | dmg_vs_mark | Lama in ombra |
| dax | Dax | rosso | vanguard | comune | LibraCorp | ort. | 1430/80/50/90 | 4324/242 | u_dax_a | bastione | thorns | – |
| elle | Elle | verde | warden | comune | Magabondi | ort. | 1000/80/30/100 | 3024/242 | u_elle_a | rinascita | regen | – |
| bruno | Bruno | blu | vanguard | comune | LibraCorp | ort. | 1430/80/50/90 | 4324/242 | u_bruno_a | bastione | round_shield | – |
| nova | Nova | giallo | striker | rara | Rondini | ort. | 972/108/22/119 | 3062/340 | u_nova_a | spezzatutto | crit_marked | Occhio svelto |
| mira | Mira | blu | warden | rara | LibraCorp | ort. | 1080/86/32/108 | 3402/272 | u_mira_a | rinascita | heal_shield | Passo di corsia |
| rex | Rex | rosso | striker | comune | Rondini | ort. | 900/110/20/110 | 2722/333 | u_rex_a | spezzatutto | low_hp_atk | – |
| ivo | Ivo | blu | striker | rara | Magabondi | **atipico** | 972/108/22/119 | 3062/340 | u_ivo_a | spezzatutto | lifesteal | Mano lesta |
| sera | Sera | verde | warden | epica | Rondini | ort. | 1180/94/35/118 | 3866/309 | u_sera_a, u_sera_b | rinascita | link_boost | Volo radente |
| eco | Eco | giallo | striker | epica | Kairos | ort. | 1062/130/24/130 | 3479/425 | u_eco_a, u_eco_b | spezzatutto | gauge_regen | Dissonanza viva |
| tana | Tana | giallo | vanguard | leggendaria | LibraCorp | ort. | 1716/106/66/119 | 6054/373 | u_tana_a, u_tana_b | bastione | guard_shield | Baluardo che risponde |
| nico | Nico | rosso | vanguard | epica | Kairos | ort. | 1534/94/59/106 | 5025/309 | u_nico_a, u_nico_b | bastione | regen | Rabbia lenta |
| dafne | Dafne | verde | striker | leggendaria | LibraCorp | ort. | 1069/160/26/145 | 3772/563 | u_dafne_b, u_dafne_c | coordinated_shot (unica) | crit_per_mark | Tiro di grazia (munizioni 6) |
| angela | Angela | giallo | striker | leggendaria | LibraCorp | ort. | 891/174/21/145 | 3143/615 | u_angela_b, u_angela_c | orbital_strike (unica) | mark_ammo | Surriscaldamento (munizioni 12) |

Nico è `story_only` (non esce dai reclutamenti). Le abilità uniche complete (valori) sono in `scripts/battle/signatures.gd` (`MOVES`): leggile come **modello di bilanciamento**.

Copertura attuale per fazione: LibraCorp 6 (Dax, Bruno, Mira, Tana, Dafne, Angela), Rondini 4 (Kira, Nova, Rex, Sera), Magabondi 2 (Elle, Ivo), Kairos 2 (Eco, Nico).
**Magabondi e Kairos sono sotto-rappresentati**; nessun colore blu/viola tra i leggendari; nessun warden Kairos; nessun vanguard Rondini o Magabondi.

---

## 5. Mosse: modelli e bilanciamento

### 5.1 Mosse base sempre disponibili
`attack` (mult 1.0), `guard` (stato guard, +1 energia, +1 munizione), `ricarica` (LibraCorp: +3 munizioni, +1 energia).

### 5.2 Famiglie di mosse generiche (quattro livelli per rarità: valori nell'array `values`)
colpo_caricato (mult 2.0→3.2, costo 2), marchio (mult 0.5→0.9 + 2 marchi, costo 1), provoca (scudo 0.6→1.4 + taunt, priorità 1), barriera (scudo squadra 1.0→2.2, priorità 1),
cura (cura 1.4→2.8 un alleato), purifica (cura 0.4→0.9 + toglie sanguinamento), frattura (mult 0.9→1.6 + −1 DIF al nemico), intimidisci (mult 0.5→1.0 + −1 ATK),
doppio_colpo (2 colpi), colpo_mirato (1 munizione, pierce 50), colpo_alla_testa (2 munizioni), ultimate: spezzatutto (4.5/5.6 ATK), bastione (scudo squadra 2.0/2.7), rinascita (cura squadra 1.1/1.5 + toglie malus).

### 5.3 Orientamenti di bilanciamento (ricavati dal gioco attuale)
| Tipo di mossa | Costo energia | Valore tipico | Note |
|---|---|---|---|
| Colpo leggero / marchia | 0-1 | mult 0.4-1.2 | spesso con stato (marchio, sanguinamento, malus) |
| Colpo medio | 2 | mult 1.6-2.2 | con `pierce` 40-60 se ignora difesa; sanguinamento 2 se è un colpo "sporco" |
| Colpo pesante | 3 | mult 3.0 | con `pierce` e malus DIF |
| Cura | 2-3 | cura 0.8-1.0 (×ATK) a tutti, 1.0 a uno | `energy` +1 se cura la squadra |
| Scudo | 1-2 | scudo 1.1-1.4 (×ATK) | priorità 1-2 se è una parata |
| Auto-protezione | 0-2 | scudo 0.5-2.0 + guard/taunt/hidden su di sé | i vanguard leggendari arrivano a scudo 2.0 |
| Ultimate | barra | mult 3.2-4.5 oppure scudo 2.0 oppure cura 1.1+; le leggendarie uniche aggiungono marchi, malus, buff di squadra | |

Regola pratica: **un leggendario vale circa 1.3-1.6 volte un comune**, mai di più. I cannoni di vetro (Dafne, Angela) compensano con `stat_mult` bassi su PV/DIF e munizioni limitate.
Ogni mossa può avere `bonus: {stat, pct}`: aggiunge `pct%` di una statistica (atk, def, spd, max_hp, crit) ai suoi valori. Più è rara, più il bonus è alto (def 20-40%, atk 10-30%, crit 18-40%).

---

## 6. Vocabolario degli effetti (usa SOLO questi)

### 6.1 Chiavi delle passive uniche (`key`), valore base a rank 0
| key | Effetto | Valore base (esempi) |
|---|---|---|
| dmg_vs_mark | +% danno ai bersagli marchiati | 0.15 |
| thorns | chi lo colpisce subisce % del suo ATK | 0.25 |
| regen | recupera % PV max a fine round | 0.035-0.04 |
| round_shield | inizia ogni round con scudo % PV max | 0.08 |
| crit_marked | +punti critico vs marchiati | 0.15 |
| heal_shield | le sue cure danno anche scudo pari a % della cura | 0.30 |
| low_hp_atk | +% danno sotto metà PV | 0.25 |
| lifesteal | recupera % del danno inflitto | 0.12 |
| link_boost | i suoi LINK danno +% per anello | 0.10 |
| gauge_regen | +N ultimate a fine round | 8 |
| guard_shield | Guardia dà scudo % PV max | 0.20 |
| mark_ammo | ogni marchio sul nemico ricarica N munizioni ai LibraCorp della squadra | 1 |
| crit_per_mark | +% critico per marchio applicato (tetto 12) | 0.025 |

### 6.2 Campi delle mosse (`Signatures.MOVES`)
- `name`, `kind` (`skill` | `ult`), `cost` (energia 0-3; ult 0), `priority` (0, 1, 2), `target`: `enemy` | `self` | `ally` | `allies`, `unique`: id personaggio.
- Danno: `mult` (× ATK), `hits` (colpi multipli), `pierce` (0-100, ignora % DIF), `crit_pm` (critico extra in per mille: 250-300), `crit_dmg_per_mark` + `crit_dmg_cap`, `consume_marks` (danno extra per marchio consumato).
- Stati al bersaglio: `status` `{"mark": n, "bleed": n}` (n = round / marchi), `debuff` `{"atk"|"def"|"spd": gradi}`.
- Su di sé: `self_status` `{"taunt": 1, "guard": 1, "hidden": 1}`.
- Aiuto: `heal` (× ATK), `shield` (× ATK), `cleanse: true`, `energy` (energia restituita), `ally_buff` `{"atk": 1, "spd": 1}`.
- Munizioni (LibraCorp): `ammo` (costo), `ammo_gain`, `team_ammo`.
- Evocazione: `summon`: `turret` | `drone` (spara da solo a fine round spendendo munizioni; a 0 munizioni esplode / dà scudi).
- `bonus`: `{"stat": "atk|def|spd|max_hp|crit", "pct": n}`.

### 6.3 Effetti dei tratti atipici (`fx`) e bonus (`mods`)
`gauge_share` (dà ultimate all'alleato più scarico), `debuff_dmg` (+% danno ai bersagli indeboliti), `reflect_shield` (% del danno assorbito dallo scudo torna al nemico),
`execute_crit` (critico sicuro sotto una soglia di PV del nemico), `crit_ammo` (critico ridona munizione), `heat` (+% danno per munizione spesa), `rage_hit` (slancio quando colpito).
`mods`: `{"crit": 60, "spd": 60, "def": 60, "atk": ...}` in **per mille** (60 = 6%). Partenza: `"energy": n`, `"gauge": n`.

### 6.4 Cose che NON esistono ancora (vanno in "richiede codice")
Stordimento, legatura/sigillo di mosse, veleno a pile, azioni extra o ritardate, copia di mosse, inversione ordine, immunità temporanee, attacchi ad area su più nemici
(oggi il boss è uno solo; in PvP `bastione` e simili sono a squadra), resurrezione, evocazioni diverse da torretta e drone.

---

## 7. Cosa devi progettare (la tua missione)

### A. Nuovi personaggi
Proponi **da 8 a 12** operatori nuovi. Obiettivi di copertura:
1. Almeno **3 Magabondi** e **3 Kairos** (oggi ce ne sono 2 e 2), almeno 1 warden Kairos e 1 vanguard Magabondi.
2. Almeno **1 leggendario blu e 1 leggendario viola**; almeno 1 leggendario Rondini o Magabondi.
3. Distribuzione rarità: molti comuni/rari (sono quelli che si recluteranno più spesso), pochi epici, 2-3 leggendari.
4. Ogni colore, ogni classe e ogni fazione devono essere rappresentati in modo che ci siano **squadre sensate** (vedi B).
5. Personalità diverse, nomi non troppo simili a quelli esistenti, nessun duplicato di ruolo identico a uno già presente.
6. Segna quali sono `story_only` (compagni da trama, es. alleati dei boss) e quali reclutabili.

### B. Sinergie
Per le **fazioni** e per i **colori** proponi **sinergie nuove** che si basano SOLO sui meccanismi della sezione 2.9 e 6, per esempio:
- *Squadre tipo* (3 operatori) per ogni fazione e per combinazioni miste che attivano LINK Unisono/Cross (spiega perché funzionano e in che ordine agire).
- *Coppie/trii* con effetti che si moltiplicano: marchiatore + chi consuma marchi, scudo + chi converte scudo in danno, cura + passiva `heal_shield`, ecc.
- *Combinazioni di fazioni* (aure + Magabondi che ricevono metà) e quando conviene l'atipico.
- Per le dottrine **non implementate** (Improvvisazione, Dissonanza): descrivi la meccanica desiderata come proposta di **nuova regola** (sezione "richiede codice"), con valori di partenza.
- Indica anche le **controsinergie** (cosa non mettere insieme) e i boss contro cui ogni sinergia è forte o debole.

### C. Bilanciamento
Per ogni personaggio dichiara in una frase **perché non è né troppo forte né troppo debole** rispetto a un personaggio esistente della stessa rarità (usa la tabella della sezione 4).
Controlla anche l'uso in **PvP** (un solo operatore in campo alla volta, 1 contro 1): niente combo che richiedano compagni in campo nello stesso momento a meno che sia una sinergia di squadra/riserva.

---

## 8. Regole e vincoli (da rispettare)

1. **Solo italiano** per testi di gioco. Maiuscolo per i nomi di mosse nelle tattiche.
2. **Numeri**: mult 0.4-4.5 (ult), costi 0-3, scudi/cure in × ATK, passive come in 6.1; niente numeri enormi.
3. **Deterministico**: nessun effetto "casuale" non legato al seme dello scontro (il multiplayer deve dare lo stesso risultato a tutti).
4. **Un solo boss per volta** nelle battaglie co-op: non proporre mosse che dipendano da più nemici in co-op.
5. **Il rank migliora ma non cambia** le mosse: non descrivere versioni diverse della stessa mossa, i potenziamenti sono automatici (+8/10/12/15% abilità, +10/12/15/20% ultimate per rarità).
6. **Niente mosse uniche come premio**: sono del personaggio.
7. **Nessun nome di personaggio/marchio reale** (anime, giochi, film). I riferimenti dichiarati dell'autore sono solo di stile.
8. Contenuti adatti a tutte le età: pop, dark leggero, niente violenza esplicita.
9. Non cambiare i personaggi esistenti. Se noti uno squilibrio, **segnalalo** nella sezione note, non correggerlo da solo.

---

## 9. Formato della consegna

Consegna **un solo documento** con queste sezioni, in questo ordine. I dati in blocchi di codice devono essere **JSON valido**
(l'altra IA li converte in GDScript). Non omettere campi: se non applicabile scrivi `null`.

### 9.1 `personaggi.json`
```json
[
  {
    "id": "nome_minuscolo_senza_spazi",
    "name": "Nome",
    "color": "rosso|giallo|viola|verde|blu",
    "cls": "striker|vanguard|warden",
    "rarity": 0,
    "faction": "libracorp|rondini|magabondi|kairos",
    "style": "ortodosso|atipico",
    "recruitable": true,
    "role": "etichetta breve",
    "ammo_max": null,
    "stat_mult": {"hp": 1.0, "atk": 1.0, "def": 1.0, "spd": 1.0},
    "skill": "id mossa base o unica",
    "ult": "id ultimate",
    "passive": "p_atk|p_hp|p_swap|p_hunter",
    "unique_passive": {"name": "…", "key": "una chiave di 6.1", "base": 0.1, "text": "una riga in italiano"},
    "unique_skills": ["u_<id>_a", "u_<id>_b"],
    "atypical_trait": {"name": "…", "text": "…", "fx": {}, "mods": {}, "energy": null, "gauge": null},
    "lore": {"tag": "…", "lore": "…", "tactic": "…"},
    "visual": "descrizione per le grafiche",
    "balance_note": "perché è bilanciato rispetto a <personaggio esistente>"
  }
]
```

### 9.2 `mosse.json` (tutte le mosse uniche e le ultimate uniche nuove)
```json
{
  "u_<id>_a": {"name": "…", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy",
               "mult": 1.8, "pierce": 0, "status": {}, "debuff": {}, "self_status": {},
               "heal": null, "shield": null, "cleanse": false, "energy": null,
               "ammo": null, "ammo_gain": null, "team_ammo": null, "summon": null,
               "bonus": {"stat": "atk", "pct": 12}, "unique": "<id>", "description_it": "testo per il giocatore"}
}
```
Le chiavi con valore `null` o vuote vanno omesse in codice; tienile qui per completezza.

### 9.3 `sinergie.md`
Per ogni sinergia: **nome**, **ingredienti** (id personaggi o regole fazione/colore), **perché funziona** (meccanica), **come si gioca** (ordine delle azioni), **numeri indicativi**
(es. "+15% per anello × 3 anelli"), **controsinergie**, **boss contro cui brilla / soffre**, **valida in PvP? sì/no**.

### 9.4 `richiede_codice.md`
Elenco di **meccaniche nuove** necessarie, una per voce: nome, descrizione, esempio di uso, valori proposti, quali personaggi la usano, dove si aggancia
(passiva / mossa / tratto atipico / aura di fazione), rischi di bilanciamento.

### 9.5 `riepilogo.md`
Una tabella finale: tutti i 14 personaggi esistenti + i nuovi, con fazione, colore, classe, rarità, ruolo in una riga, e una matrice **fazione × colore × classe** che mostra le caselle ancora vuote.

---

## 10. Checklist di controllo prima di consegnare

- [ ] Ogni `id` è unico, minuscolo, senza spazi, diverso dai 14 esistenti.
- [ ] Ogni `skill`/`ult` esiste (famiglia base o definita in `mosse.json`).
- [ ] Ogni `key` di passiva è tra quelle di 6.1; ogni effetto di mossa è tra quelli di 6.2.
- [ ] Le rarità sono coerenti con costo e potenza (nessun comune più forte di un leggendario).
- [ ] I vanguard hanno ruolo difensivo, gli striker offensivo, i warden di supporto, e le statistiche (con `stat_mult`) rispettano la regola della somma ≈ 1.
- [ ] Il tratto atipico rispetta la rarità (comune: nessun tratto; raro: piccolo; epico: evidente; leggendario: distintivo).
- [ ] Le `tactic` nominano davvero le mosse e le sinergie del personaggio.
- [ ] Le sinergie funzionano anche con le regole reali (aure con tetto 25%, LINK max 4 anelli, energia max 6).
- [ ] Tutte le proposte che richiedono codice nuovo sono in `richiede_codice.md`, non mescolate ai dati pronti.
- [ ] Testi in italiano, nessun riferimento a opere protette, adatti a tutti.

## 11. Dove guardare nel codice (solo lettura, se hai accesso al repository)

`scripts/battle/battle_content.gd` (personaggi, famiglie di mosse, statistiche), `scripts/battle/signatures.gd` (passive e mosse uniche),
`scripts/battle/atypical.gd` (tratti atipici), `scripts/battle/factions.gd` (aure, ronda, protocollo), `scripts/battle/archetypes.gd` (colori),
`scripts/battle/battle_resolver.gd` (come si calcola un round in co-op), `scripts/battle/pvp_engine.gd` (PvP),
`scripts/battle/lore.gd` (testi), `docs/DOTTRINE.md` (dottrine), `docs/MONDO.md` (mondo), `docs/HANDOFF_ARTE_IA.md` (grafiche).
