# ODISPEL - Report di bilanciamento (versione 0.24.0)

Questo documento racconta, in modo semplice, che cosa abbiamo misurato sui 24 operatori, che cosa non andava e che cosa e' stato corretto.
Tutti i numeri vengono da simulazioni: il computer fa giocare le squadre da sole, migliaia di volte, con le stesse condizioni per tutti.

## 1. Come abbiamo testato

- **Contro i boss (PvE):** tutte le 1.771 squadre da 3 operatori possibili (Nico escluso perche' appare solo nella storia), ognuna 16 volte contro i due boss piu' difficili, **Orologio** e **Specchio**, a livello 8, rank 0 e difficolta' massima. E' di proposito un livello basso: a livello alto tutti vincono sempre e non si capisce chi e' forte.
- **Tra giocatori (PvP):** le stesse 1.771 squadre, ognuna contro 16 squadre a caso, in modalita' bilanciata (livello 20, rank 2, niente equipaggiamento).
- Altre prove piu' veloci (5.000-9.000 partite l'una) hanno servito a controllare ogni ritocco prima di tenerlo.
- Il computer usa l'IA di gioco, quindi i risultati misurano quanto un operatore e' forte *giocato in modo ragionevole*, non al massimo di un giocatore esperto.

## 2. I problemi trovati (prima dei ritocchi)

1. **Il PvP "bilanciato" non lo era davvero.** Livello, rank ed equipaggiamento erano uguali per tutti, ma la **rarita'** dava ancora statistiche in piu' (+32% per i leggendari). Dafne vinceva il 74% delle partite, Angela il 71%, mentre Oriel solo il 32%.
2. **Nei duelli PvP un marchio dava sempre +25%**, mentre contro i boss ogni marchio vale +10% e si accumulano. Inoltre "Raggio orbitale" di Angela e i colpi con bonus per marchio contavano sempre 6 (o 3) marchi, anche se il nemico ne aveva uno solo (errore trovato da ChatGPT e confermato nel codice).
3. **Contro i boss duri, le squadre senza attaccanti non potevano vincere.** Tre attaccanti vincevano il 95%, ma tre difensori (guardiani/avanguardie) lo 0%. Una squadra equilibrata (1 attaccante, 1 avanguardia, 1 guardiano) vinceva solo il 13%. I supporti non pagavano.
4. **Pochi operatori molto sopra gli altri:** Dafne (+53 punti sopra la media contro l'Orologio), Flux (+36), Kira (+33), Eco, Lyra e Angela. In fondo: Elle, Sera, Rhea, Nami, Mira, Bruno.
5. **Lyra e Flux**, i due nuovi attaccanti leggendari, erano subito tra i migliori: Lyra era la numero 1 contro i boss, in contrasto con la regola che ChatGPT stesso aveva fissato ("non deve superare Angela e Dafne").

## 3. Che cosa abbiamo corretto

**Regole del motore**
- PvP bilanciato: ora anche la rarita' degli operatori viene livellata (tutti come un comune). Sono rimaste le differenze vere: abilita', classe, passive.
- PvP: i marchi si accumulano come contro i boss (+10% ciascuno, fino a 6). Raggio orbitale e i colpi "per marchio" contano i marchi veri.
- Nuove abilita' di squadra: le ultimate **Bastione** e **Rinascita** e l'abilita' **Barriera** danno +15% di attacco a tutta la squadra per 2 turni. Le abilita' uniche di Elle, Mira, Sera, Nami, Rhea e Oriel danno +30% di attacco alla squadra. Ora i difensori fanno vincere la squadra anche senza colpire.
- L'IA del computer ora rinnova questo bonus quando scade (prima i supporti si limitavano a curare).
- Classi: l'attacco base di Avanguardia (80 -> 90) e Guardiano (80 -> 88) e' piu' alto.

**Operatori**
- **Troppo forti, ridotti:** Dafne (attacco e vita leggermente giu', Colpo mirato e Colpo coordinato piu' deboli, Copertura senza energia gratis), Angela (Mitragliatrice e Raggio orbitale piu' deboli, attacco -7%), Eco (Frequenza critica e Eco ripetuto piu' deboli), Kira (Taglio spettrale piu' debole), Flux (Punto di Rottura e Scarica diretta piu' deboli, meno vita), Lyra (meno attacco/vita e abilita' piu' deboli), Rex (attacco -5%).
- **Troppo deboli, rafforzati:** Oriel, Nami, Cato, Moro, Tana, Mira (piu' attacco e vita secondo il caso).

**Nuovo: Kira leggendaria.** Kira (la nostra mascotte) e' ora leggendaria, a 5 stelle. Per non romperla le sue statistiche sono ridotte, in modo che il suo livello di forza resti simile a prima (cresce piu' veloce con i rank). Ha una seconda abilita' unica (*Pugno incanalato*) e un tratto atipico da leggendaria (colpo critico sicuro quando il boss e' sotto il 30%). Come operatore iniziale non conta per l'obiettivo "Una leggenda in squadra".

**Reclutamento:** nuovo banner **NUOVI OPERATORI** (solo i 10 del secondo roster, stessi costi e stessa garanzia). Nel banner **STANDARD** i 10 nuovi escono con meta' probabilita' rispetto agli altri.

## 4. Risultati: prima e dopo

| Cosa | Prima | Dopo |
|---|---|---|
| PvP 3v3: miglior operatore / peggiore (vittorie delle squadre che lo includono) | 74% / 32% | 65% / 32% |
| PvP: squadra di soli guardiani | 29% | 52% |
| PvP: spread tra la miglior e la peggior composizione di classi | 29%-66% | 44%-66% |
| Orologio: 1 attaccante + 1 avanguardia + 1 guardiano | 13% | 22% |
| Orologio: 1 attaccante + 2 guardiani | 6% | 24% |
| Specchio: 1 attaccante + 1 avanguardia + 1 guardiano | 31% | 38% |
| Specchio: 1 attaccante + 2 guardiani | 39% | 44% |
| Specchio: 2 attaccanti + 1 guardiano | 61% | 66% |

In sintesi: il PvP e' molto piu' pulito (l'effetto della rarita' e' sparito, nessun operatore e' fuori scala), e i supporti ora servono davvero. Restano, pero', differenze che non abbiamo voluto eliminare del tutto (sezione 6).

## Aggiornamento 0.24.1

- **Kira**: ora ha statistiche piene da leggendaria (senza riduzioni), Taglio spettrale a 1,8x con perforazione e Pugno incanalato a 1,45x. Contro i boss duri e' la 2a migliore (con Dafne) e in classifica generale e' in **tier S**. In PvP bilanciato resta come tutti gli altri (la rarita' e' livellata); con la progressione dell'account il suo vantaggio si vede.
- **Rinforzati un po'**: Rhea, Sera, Nami, Mira, Bruno, Cato, Dax, Tana, Oriel (piu' vita e attacco).
- **IA del PvP**: le ultimate di sola cura o scudo non si sprecano piu' a vita piena.
- La classifica completa e' in `docs/TIERLIST.md`.

## 5. Le combinazioni piu' efficaci (test profondo)

### Classi
- **Contro i boss duri comandano gli attaccanti.** 3 attaccanti: 94% (Orologio) e 92% (Specchio). 2 attaccanti + 1 avanguardia: 75% e 72%. Con 1 solo attaccante la vittoria cala molto (22-38% con un'avanguardia e un guardiano).
- **La squadra "da manuale" 1+1+1 non e' la migliore:** vince meno di 2 attaccanti + 1 difensore. I difensori non fanno ancora quanto servirebbe, ma ora hanno un ruolo (bonus di attacco alla squadra).
- **In PvP le classi sono molto piu' vicine:** da 44% a 66%. Le squadre migliori sono 3 avanguardie (66%) e 3 attaccanti (64%); la peggiore e' 1 attaccante + 2 guardiani (44%).

### Fazioni
- **Kairos e' la fazione piu' forte contro i boss.** 2 Kairos + 1 LibraCorp: 75% (Orologio) e 97% (Specchio); 2 Kairos + 1 Rondini: 70% e 86%. Attenzione: Kairos non ha un'aura propria, quindi la forza viene dagli operatori (Eco, Yuna, Oriel, Silex).
- **LibraCorp tutta insieme rende poco** (3 LibraCorp: 50% e 42%): la sua aura aumenta la DIF, non il danno, e contro i boss il danno conta di piu'.
- **Squadre di fazioni diverse**, di per se', non sono ne' meglio ne' peggio: 40-55% a seconda del boss. Le aure di fazione pesano poco rispetto agli operatori scelti.
- **In PvP** (dove le aure non si applicano) la fazione e' solo "chi c'e' dentro": i Magabondi (Elle, Ivo, Vesper, Moro, Nami) sono i piu' forti, con 2 Magabondi + 1 altro tra il 61% e il 64%.

### Colori
- Il triangolo dei colori (rosso > verde > blu > rosso, giallo e viola in coppia) decide molto contro un boss specifico: contro lo **Specchio (rosso)** i blu spiccano (Oriel +47 punti, Flux +44, Yuna +26); contro l'**Orologio (viola)** i gialli (Eco, Angela) vanno bene. E' una scelta di squadra voluta, non un difetto.

### Operatori (scarto in punti rispetto alla media)
| | Orologio | Specchio | PvP |
|---|---|---|---|
| I migliori | Dafne +45, Kira +37, Flux +30, Lyra +21, Oriel +19 | Oriel +47, Flux +44, Angela +41, Yuna +26, Kira +20 | Elle +24, Bruno +18, Eco +17, Ivo +10, Rex +10 |
| I piu' deboli | Elle -34, Rhea -26, Nami -24, Sera -23, Mira -21 | Elle -26, Rhea -22, Nami -21, Sera -20, Bruno -19 | Nami -16, Oriel -14, Mira -10, Flux -10, Kira -9 |

### Coppie con la sinergia piu' alta
- **Contro i boss:** Nova + Oriel (+27), Ivo + Oriel (+26), Vesper + Yuna (+27), Elle + Oriel (+26), Kira + un guardiano (Sera, Rhea, Nami o Mira, circa +22), Angela + Bruno o Dax (+23). Le squadre con Angela + Bruno + qualsiasi attaccante vincono il 100%: lo scudo di Bruno protegge Angela, molto fragile.
- **In PvP:** Elle + Nami (+17), Elle + Oriel (+16), Nova + Oriel (+13), Elle + Flux (+13), Bruno + Oriel (+13), Moro + Nami (+12).
- **Coppie che si ostacolano:** Flux + Oriel (-44 sullo Specchio: sono entrambi blu e fanno lo stesso mestiere), Dafne + Kira (-25), Bruno + Kira (-25), Oriel + Rex (-19 in PvP), Eco + Elle (-19 in PvP).

## 6. Che cosa resta da tenere d'occhio

- **I guardiani (Elle, Rhea, Nami, Sera, Mira) sono ancora i piu' deboli contro i boss duri.** L'IA li usa in modo prudente; un giocatore vero li usa meglio, quindi i numeri sono un limite inferiore. Se si volesse fare di piu': cure che scalano meglio o un'abilita' offensiva a tutti i guardiani.
- **Elle e' la migliore in PvP e la peggiore contro i boss.** Va bene (ruoli diversi), ma se Elle domina i duelli si puo' ridurre il suo ATK o le sue cure in PvP.
- **Dafne contro l'Orologio (+45) e Oriel/Flux contro lo Specchio (+45)** sono contromosse per colore, non errori. Se si preferisce, si possono ridurre i moltiplicatori di colore (oggi 1,5 e 0,67).
- **Kira (leggendaria)** e' stata ridotta all'ultimo. Prima del ritocco era a +37 contro l'Orologio (vittorie); dopo, con la misura "quanto boss abbattuto", e' a +16: in linea con Angela (+14), Flux (+17) e Lyra (+13), sotto Dafne (+22).
- **Poco testato:** livelli alti, rank e equipaggiamento (qui livello 8, rank 0 e niente equipaggiamento nel test sui boss, livello 20 rank 2 nel PvP). Con la progressione, i numeri cambiano.
- **Il PvP non usa aure di fazione ne' LINK** (scelta fatta all'inizio). Se un giorno si aggiungono, le fazioni cambieranno peso.
- **Vittoria al limite dei 40 round:** molte partite PvP si decidono ai punti-vita rimasti; i supporti con cure e scudi vengono premiati poco da questa regola.

## 7. File e strumenti

- `tools/balance_report.gd` - misura rapida per operatore (1v1, 3v3 a caso, boss).
- `tools/team_report.gd` - tutte le squadre da 3 contro un boss o in PvP.
- I tre test nuovi: `tests/unit/test_roster2.gd` (81 controlli sui nuovi operatori e sul banner), piu' gli aggiornamenti ai test esistenti.

---

## Appendice - tabelle complete dell'ultimo test profondo

### PvE - Orologio
Squadre analizzate: 1771  |  vittorie medie: 42.9%

**Composizione di classi**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| striker + striker + striker | 94.2% | 165 |
| striker + striker + vanguard | 75.3% | 330 |
| striker + striker + warden | 53.4% | 330 |
| striker + vanguard + vanguard | 29.8% | 165 |
| striker + warden + warden | 23.9% | 165 |
| striker + vanguard + warden | 21.7% | 396 |
| vanguard + vanguard + warden | 5.6% | 90 |
| vanguard + warden + warden | 0.1% | 90 |
| warden + warden + warden | 0.0% | 20 |
| vanguard + vanguard + vanguard | 0.0% | 20 |

**Schema di fazioni**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| 3 della stessa fazione | 50.2% | 90 |
| 2 + 1 | 44.1% | 969 |
| 3 fazioni diverse | 40.4% | 712 |

**Fazioni (composizione esatta)**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| kairosx2 + libracorp | 74.6% | 48 |
| kairosx2 + rondini | 70.0% | 36 |
| rondinix2 + kairos | 66.0% | 60 |
| rondinix3 | 64.7% | 20 |
| kairosx2 + magabondi | 63.7% | 30 |
| libracorpx2 + kairos | 52.9% | 112 |
| kairos + libracorp + rondini | 51.8% | 192 |
| libracorpx3 | 50.4% | 56 |
| rondinix2 + libracorp | 49.5% | 120 |
| libracorpx2 + rondini | 44.4% | 168 |
| rondinix2 + magabondi | 43.4% | 75 |
| kairos + magabondi + rondini | 42.7% | 120 |
| kairos + libracorp + magabondi | 38.1% | 160 |
| libracorp + magabondi + rondini | 31.7% | 240 |

**Schema di colori**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| 3 dello stesso colore | 50.6% | 45 |
| 2 + 1 | 45.7% | 789 |
| 3 colori diversi | 40.2% | 937 |

**Operatori: vittorie medie delle squadre in cui compaiono** (scarto dalla media)

| Operatore | Classe | Fazione | Vittorie | Scarto |
|---|---|---|---|---|
| dafne | striker | libracorp | 88.0% | +45.1 |
| kira | striker | rondini | 79.8% | +36.9 |
| flux | striker | rondini | 72.9% | +30.0 |
| lyra | striker | libracorp | 63.8% | +20.9 |
| oriel | warden | kairos | 62.3% | +19.3 |
| eco | striker | kairos | 60.0% | +17.1 |
| yuna | striker | kairos | 51.2% | +8.3 |
| angela | striker | libracorp | 49.4% | +6.4 |
| ivo | striker | magabondi | 48.6% | +5.7 |
| rex | striker | rondini | 48.6% | +5.7 |
| vesper | striker | magabondi | 42.6% | -0.3 |
| nova | striker | rondini | 40.1% | -2.8 |
| silex | vanguard | kairos | 39.9% | -3.1 |
| tana | vanguard | libracorp | 39.2% | -3.7 |
| moro | vanguard | magabondi | 35.7% | -7.2 |
| dax | vanguard | libracorp | 28.4% | -14.5 |
| cato | vanguard | libracorp | 25.1% | -17.8 |
| bruno | vanguard | libracorp | 23.6% | -19.3 |
| mira | warden | libracorp | 22.4% | -20.5 |
| sera | warden | rondini | 19.8% | -23.1 |
| nami | warden | magabondi | 19.2% | -23.8 |
| rhea | warden | rondini | 16.9% | -26.0 |
| elle | warden | magabondi | 9.4% | -33.5 |

**Coppie con la sinergia migliore** (oltre quanto spiegano i due operatori da soli)

| Coppia | Vittorie | Sinergia |
|---|---|---|
| nova + oriel | 86.6% | +27.2 |
| ivo + oriel | 93.5% | +25.5 |
| kira + sera | 80.1% | +23.4 |
| kira + rhea | 76.5% | +22.7 |
| kira + nami | 78.3% | +22.2 |
| kira + mira | 80.1% | +20.7 |
| elle + rhea | 1.2% | +17.8 |
| dafne + dax | 91.1% | +17.5 |
| kira + nova | 94.0% | +17.1 |
| vesper + yuna | 67.6% | +16.7 |
| eco + rex | 82.1% | +16.4 |
| angela + lyra | 86.6% | +16.3 |

**Coppie che si ostacolano**

| Coppia | Vittorie | Sinergia |
|---|---|---|
| elle + flux | 13.4% | -26.0 |
| bruno + kira | 35.4% | -25.1 |
| dafne + kira | 100.0% | -24.9 |
| elle + kira | 22.6% | -23.7 |
| dafne + flux | 100.0% | -18.1 |
| lyra + rhea | 19.9% | -17.9 |
| dax + kira | 50.0% | -15.3 |
| flux + oriel | 77.4% | -14.9 |

**Migliori squadre**

| Squadra | Vittorie | Round medi |
|---|---|---|
| angela + bruno + dafne | 100% | 17.1 |
| angela + bruno + eco | 100% | 16.0 |
| angela + bruno + flux | 100% | 16.0 |
| angela + bruno + kira | 100% | 15.6 |
| angela + bruno + lyra | 100% | 18.0 |
| angela + bruno + rex | 100% | 17.1 |
| angela + bruno + yuna | 100% | 22.0 |
| angela + cato + dafne | 100% | 13.9 |
| angela + cato + eco | 100% | 12.0 |
| angela + cato + flux | 100% | 13.8 |
| angela + cato + kira | 100% | 13.1 |
| angela + cato + lyra | 100% | 14.9 |

**Peggiori squadre**

| Squadra | Vittorie | Round medi |
|---|---|---|
| sera + silex + tana | 0% | 34.5 |
| sera + silex + vesper | 0% | 25.4 |
| sera + silex + yuna | 0% | 25.4 |
| sera + tana + vesper | 0% | 25.8 |
| sera + tana + yuna | 0% | 23.4 |
| sera + vesper + yuna | 0% | 18.1 |
| silex + tana + vesper | 0% | 29.0 |
| silex + tana + yuna | 0% | 29.0 |

### PvE - Specchio
Squadre analizzate: 1771  |  vittorie medie: 53.2%

**Composizione di classi**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| striker + striker + striker | 92.3% | 165 |
| striker + striker + vanguard | 72.1% | 330 |
| striker + striker + warden | 66.3% | 330 |
| warden + warden + warden | 50.0% | 20 |
| striker + warden + warden | 44.2% | 165 |
| striker + vanguard + warden | 38.3% | 396 |
| vanguard + warden + warden | 33.3% | 90 |
| striker + vanguard + vanguard | 32.3% | 165 |
| vanguard + vanguard + warden | 16.7% | 90 |
| vanguard + vanguard + vanguard | 0.0% | 20 |

**Schema di fazioni**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| 3 fazioni diverse | 55.4% | 712 |
| 2 + 1 | 52.1% | 969 |
| 3 della stessa fazione | 47.8% | 90 |

**Fazioni (composizione esatta)**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| kairosx2 + libracorp | 96.6% | 48 |
| kairosx2 + rondini | 86.1% | 36 |
| kairosx2 + magabondi | 81.0% | 30 |
| rondinix2 + kairos | 75.3% | 60 |
| rondinix3 | 74.7% | 20 |
| kairos + libracorp + rondini | 68.3% | 192 |
| libracorpx2 + kairos | 64.5% | 112 |
| kairos + magabondi + rondini | 62.3% | 120 |
| kairos + libracorp + magabondi | 60.6% | 160 |
| magabondix2 + kairos | 55.5% | 40 |
| rondinix2 + magabondi | 52.0% | 75 |
| rondinix2 + libracorp | 51.7% | 120 |
| libracorpx2 + rondini | 44.6% | 168 |
| libracorpx3 | 41.5% | 56 |

**Schema di colori**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| 3 dello stesso colore | 56.2% | 45 |
| 2 + 1 | 53.4% | 789 |
| 3 colori diversi | 52.9% | 937 |

**Operatori: vittorie medie delle squadre in cui compaiono** (scarto dalla media)

| Operatore | Classe | Fazione | Vittorie | Scarto |
|---|---|---|---|---|
| oriel | warden | kairos | 100.0% | +46.8 |
| flux | striker | rondini | 97.1% | +43.9 |
| angela | striker | libracorp | 94.5% | +41.3 |
| yuna | striker | kairos | 78.9% | +25.7 |
| kira | striker | rondini | 72.9% | +19.7 |
| ivo | striker | magabondi | 70.9% | +17.7 |
| eco | striker | kairos | 58.8% | +5.6 |
| lyra | striker | libracorp | 57.0% | +3.8 |
| rex | striker | rondini | 52.4% | -0.8 |
| silex | vanguard | kairos | 47.1% | -6.1 |
| mira | warden | libracorp | 46.1% | -7.1 |
| dafne | striker | libracorp | 45.7% | -7.5 |
| tana | vanguard | libracorp | 44.6% | -8.6 |
| moro | vanguard | magabondi | 43.7% | -9.5 |
| vesper | striker | magabondi | 42.9% | -10.3 |
| nova | striker | rondini | 42.6% | -10.6 |
| cato | vanguard | libracorp | 36.0% | -17.2 |
| dax | vanguard | libracorp | 35.5% | -17.7 |
| bruno | vanguard | libracorp | 34.0% | -19.2 |
| sera | warden | rondini | 32.8% | -20.4 |
| nami | warden | magabondi | 32.0% | -21.2 |
| rhea | warden | rondini | 31.0% | -22.2 |
| elle | warden | magabondi | 27.1% | -26.1 |

**Coppie con la sinergia migliore** (oltre quanto spiegano i due operatori da soli)

| Coppia | Vittorie | Sinergia |
|---|---|---|
| vesper + yuna | 95.8% | +27.3 |
| elle + oriel | 100.0% | +26.1 |
| angela + dax | 100.0% | +23.2 |
| cato + ivo | 76.8% | +23.1 |
| angela + bruno | 98.2% | +22.9 |
| oriel + rhea | 100.0% | +22.2 |
| ivo + rex | 91.7% | +21.6 |
| nova + yuna | 89.9% | +21.6 |
| nami + oriel | 100.0% | +21.2 |
| oriel + sera | 100.0% | +20.4 |
| dafne + ivo | 83.0% | +19.7 |
| flux + rhea | 94.3% | +19.5 |

**Coppie che si ostacolano**

| Coppia | Vittorie | Sinergia |
|---|---|---|
| flux + oriel | 100.0% | -43.9 |
| angela + oriel | 100.0% | -41.3 |
| angela + flux | 100.0% | -38.4 |
| oriel + yuna | 100.0% | -25.7 |
| dax + kira | 30.7% | -24.6 |
| elle + kira | 23.2% | -23.7 |
| flux + yuna | 100.0% | -22.7 |
| cato + kira | 33.9% | -21.8 |

**Migliori squadre**

| Squadra | Vittorie | Round medi |
|---|---|---|
| angela + bruno + cato | 100% | 38.0 |
| angela + bruno + dafne | 100% | 24.1 |
| angela + bruno + dax | 100% | 34.0 |
| angela + bruno + eco | 100% | 23.0 |
| angela + bruno + elle | 100% | 34.0 |
| angela + bruno + flux | 100% | 21.5 |
| angela + bruno + ivo | 100% | 23.0 |
| angela + bruno + kira | 100% | 21.8 |
| angela + bruno + lyra | 100% | 25.0 |
| angela + bruno + mira | 100% | 30.0 |
| angela + bruno + moro | 100% | 33.0 |
| angela + bruno + nami | 100% | 34.0 |

**Peggiori squadre**

| Squadra | Vittorie | Round medi |
|---|---|---|
| rhea + tana + vesper | 0% | 23.2 |
| rhea + tana + yuna | 0% | 25.2 |
| sera + silex + tana | 0% | 29.3 |
| sera + silex + vesper | 0% | 21.3 |
| sera + silex + yuna | 0% | 22.2 |
| sera + tana + vesper | 0% | 23.9 |
| sera + tana + yuna | 0% | 25.0 |
| silex + tana + vesper | 0% | 30.6 |

### PvP 3v3 bilanciato
Squadre analizzate: 1771  |  vittorie medie: 54.8%

**Composizione di classi**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| vanguard + vanguard + vanguard | 65.6% | 20 |
| striker + striker + striker | 63.6% | 165 |
| striker + vanguard + vanguard | 60.6% | 165 |
| vanguard + vanguard + warden | 57.7% | 90 |
| striker + striker + vanguard | 57.3% | 330 |
| striker + vanguard + warden | 53.5% | 396 |
| vanguard + warden + warden | 52.1% | 90 |
| warden + warden + warden | 52.0% | 20 |
| striker + striker + warden | 51.0% | 330 |
| striker + warden + warden | 44.4% | 165 |

**Schema di fazioni**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| 3 della stessa fazione | 56.8% | 90 |
| 2 + 1 | 55.1% | 969 |
| 3 fazioni diverse | 54.1% | 712 |

**Fazioni (composizione esatta)**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| magabondix3 | 81.9% | 10 |
| magabondix2 + kairos | 64.5% | 40 |
| magabondix2 + rondini | 64.2% | 60 |
| magabondix2 + libracorp | 61.4% | 80 |
| kairosx2 + magabondi | 57.9% | 30 |
| kairos + libracorp + magabondi | 57.1% | 160 |
| libracorpx2 + magabondi | 56.7% | 140 |
| kairos + magabondi + rondini | 55.7% | 120 |
| rondinix3 | 54.2% | 20 |
| libracorpx2 + kairos | 54.0% | 112 |
| rondinix2 + magabondi | 53.9% | 75 |
| kairosx2 + libracorp | 53.8% | 48 |
| libracorpx3 | 53.7% | 56 |
| libracorp + magabondi + rondini | 53.6% | 240 |

**Schema di colori**

| Combinazione | Vittorie | Squadre |
|---|---|---|
| 3 colori diversi | 55.7% | 937 |
| 2 + 1 | 53.8% | 789 |
| 3 dello stesso colore | 52.5% | 45 |

**Operatori: vittorie medie delle squadre in cui compaiono** (scarto dalla media)

| Operatore | Classe | Fazione | Vittorie | Scarto |
|---|---|---|---|---|
| elle | warden | magabondi | 78.7% | +23.9 |
| bruno | vanguard | libracorp | 72.6% | +17.8 |
| eco | striker | kairos | 72.1% | +17.3 |
| ivo | striker | magabondi | 64.9% | +10.2 |
| rex | striker | rondini | 64.9% | +10.1 |
| nova | striker | rondini | 61.8% | +7.0 |
| dax | vanguard | libracorp | 58.4% | +3.7 |
| cato | vanguard | libracorp | 56.8% | +2.0 |
| moro | vanguard | magabondi | 54.8% | +0.1 |
| vesper | striker | magabondi | 54.8% | -0.0 |
| angela | striker | libracorp | 52.8% | -2.0 |
| yuna | striker | kairos | 52.2% | -2.5 |
| silex | vanguard | kairos | 52.2% | -2.6 |
| rhea | warden | rondini | 52.0% | -2.7 |
| dafne | striker | libracorp | 51.9% | -2.9 |
| sera | warden | rondini | 49.1% | -5.7 |
| tana | vanguard | libracorp | 47.7% | -7.0 |
| lyra | striker | libracorp | 46.4% | -8.3 |
| kira | striker | rondini | 46.0% | -8.8 |
| flux | striker | rondini | 44.9% | -9.9 |
| mira | warden | libracorp | 44.9% | -9.9 |
| oriel | warden | kairos | 40.8% | -14.0 |
| nami | warden | magabondi | 39.1% | -15.7 |

**Coppie con la sinergia migliore** (oltre quanto spiegano i due operatori da soli)

| Coppia | Vittorie | Sinergia |
|---|---|---|
| elle + nami | 79.6% | +16.6 |
| elle + oriel | 80.2% | +15.5 |
| nova + oriel | 61.0% | +13.2 |
| elle + flux | 81.8% | +13.0 |
| bruno + oriel | 71.4% | +12.9 |
| moro + nami | 51.5% | +12.3 |
| elle + mira | 81.0% | +12.2 |
| rex + rhea | 73.5% | +11.3 |
| bruno + dafne | 81.0% | +11.3 |
| nova + vesper | 72.6% | +10.8 |
| bruno + mira | 73.2% | +10.6 |
| dafne + eco | 79.6% | +10.4 |

**Coppie che si ostacolano**

| Coppia | Vittorie | Sinergia |
|---|---|---|
| oriel + rex | 31.5% | -19.4 |
| eco + elle | 77.1% | -18.9 |
| bruno + elle | 77.7% | -18.8 |
| nami + nova | 29.2% | -17.0 |
| nami + rex | 32.4% | -16.8 |
| dafne + elle | 60.1% | -15.7 |
| angela + elle | 61.3% | -15.4 |
| angela + bruno | 57.0% | -13.5 |

**Migliori squadre**

| Squadra | Vittorie | Round medi |
|---|---|---|
| bruno + elle + kira | 100% | 40.0 |
| bruno + elle + vesper | 100% | 40.0 |
| bruno + flux + vesper | 100% | 40.0 |
| bruno + ivo + nami | 100% | 40.0 |
| dafne + eco + nova | 100% | 32.8 |
| eco + nova + rex | 100% | 29.4 |
| eco + nova + vesper | 100% | 32.8 |
| eco + rex + tana | 100% | 33.7 |
| elle + flux + ivo | 100% | 40.0 |
| elle + ivo + moro | 100% | 40.0 |
| elle + ivo + nova | 100% | 40.0 |
| elle + ivo + sera | 100% | 40.0 |

**Peggiori squadre**

| Squadra | Vittorie | Round medi |
|---|---|---|
| oriel + sera + silex | 0% | 40.0 |
| oriel + sera + tana | 0% | 40.0 |
| oriel + sera + vesper | 0% | 40.0 |
| oriel + sera + yuna | 0% | 40.0 |
| oriel + silex + tana | 0% | 40.0 |
| oriel + silex + vesper | 0% | 40.0 |
| oriel + tana + vesper | 0% | 40.0 |
| oriel + tana + yuna | 0% | 40.0 |


## Aggiornamento 0.24.2

- Nuovo moltiplicatore per l'attacco base di classe (solo operatori): guardiano x1.5, avanguardia x1.3, attaccante x1.0. Serve perche' in battaglia combatte un solo operatore per giocatore e i guardiani passavano il tempo senza fare danno.
- Potenziati ancora Mira, Sera, Nami, Rhea, Elle, Oriel, Vesper, Silex, Bruno, Dax, Moro, Cato (statistiche e bonus di squadra delle skill unica dei guardiani).
- Risultato: nessun operatore in tier D (vedi docs/TIERLIST.md). I guardiani restano in fondo alla tier C: il loro valore reale (cure, scudi, buff) dipende dal giocatore.
- **Supporto dalla panchina (solo co-op):** a fine round un guardiano vivo in back row cura del 3% dei PV massimi chi combatte (un solo guardiano per round, non si somma). In PvP l'ho provato e tolto: faceva vincere troppo le squadre di guardiani (80% contro 54%).

## Aggiornamento 0.24.7 - ruolo dei guardiani

- Ogni guardiano ha un **sostegno dalla panchina** (cura, scudo, ultimate o energia a fine round per chi combatte). Vale x1,5 contro i boss e x0,3 in PvP.
- L'attacco semplice di avanguardie e guardiani e' leggermente piu' forte (x1,2 / x1,3); le statistiche base del guardiano sono state abbassate un po' (940 PV, 84 ATT, 28 DIF).
- Misure (4500-9000 partite): in PvP le squadre di guardiani restano forti (3 guardiani ~65%, Elle ~+25 punti). Scelta consapevole: verranno gestiti con pick e ban in PvP e con il blocco temporaneo di alcuni personaggi fino al rework. Contro i boss duri la squadra mista ora e' in linea con le altre.
- Il vecchio testo "3% da un solo guardiano, provato in PvP e tolto" non e' piu' valido.
