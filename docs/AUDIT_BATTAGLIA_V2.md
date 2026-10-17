# ODISPEL — Audit del combattimento Test V2 (COMBAT & HUD QUALITY GATE, fase 1-4)

Data: 17/10/2026. Solo lettura: nessun codice di gameplay modificato. Questo file e' l'unica aggiunta del ramo.

## 0. Stato di partenza (verificato)
- Ramo di lavoro: `claude/battaglia-v2-audit`, derivato da `claude/battaglia-v2` (commit `7dce870`, versione 0.28.1, cartella pulita). Riferimento congelato: tag `v2-baseline-0.28.1` su quel commit; le build 0.28.1 restano in `releases/` e le precedenti non sono toccate.
- Nota sul prompt originale: chiedeva di derivare da `claude/battaglia-chiara`. Quel ramo e' il combattimento classico (0.26.2) e non contiene la scena V2, quindi per il Test V2 si parte da `claude/battaglia-v2`. La scena classica `scenes/battle/` non e' stata toccata.
- Scena: `scenes/battle_v2/battle_v2.gd`, 1778 righe, un solo file con classi interne (`_G`, `_Hero`, `_Boss`, `_Wheel`, `_Hud`, `_PaintBake`, `_Ring`, `_Fx`, `_Vignette`, `_U`). Motore: `SoloBattleSource` (allenamento, nessun premio) su `BattleResolver`, non modificato.

## 1. Cosa e' stato davvero eseguito
- Suite unitaria completa: 81 test, tutti passati. Due (`test_hud_layout`, `test_input_ui`) sono falliti una volta solo mentre la macchina era sotto carico e passano da soli.
- `tools/battle_v2_shot.gd` (partita completa in autoplay con tocchi simulati): fine in 3 round, vittoria dei giocatori, 0 errori. Eseguito a 1280x720 (PC) e a 2400x1080 con modalita' touch forzata.
- Simulazione motore (script temporaneo, non committato): squadra di 6, in campo 3 (`p1`, `p1_f2`, `p1_f3`); in 3 round gli eventi sono stati: act 8, damage 13, balance 6, ronda 3, boss_move 2, link 3, heal 4, shield 10, reserve 3, rhythm 2, trait 1, ammo 1, counter 1, break 1, arena 1, phase 1, buff 1, synergy 1, down 1, end 1.
- Misure di prestazione: solo con render software (indicatore relativo, ULT scelta 428 -> 78 ms, riposo 349 -> ~52-96 ms).

## 2. Cosa NON e' stato verificato
- Nessuna prova su un telefono reale (touch, leggibilita' fisica, fotogrammi, calore). Gli screenshot a 2400x1080 sono una simulazione.
- Aggiornamento dell'APK sopra versioni precedenti: non confermato sul dispositivo.
- Nessun test di accessibilita' con persone, nessuna misura reale della latenza di tocco.
- Comportamento di tutti i boss e di tutte le mosse: l'audit usa solo il Distributore a difficolta' 0.

## 3. Problemi verificati (evidenza nel codice o nell'esecuzione)

### P0 — impediscono di giocare/leggere correttamente
- **P0-1 Attacchi del boss annunciati solo se "pesanti".** `_Hud` mostra "CARICA · MOSSA" solo con `not selected and heavy`; le altre mosse del boss non sono mai annunciate, e l'annuncio sparisce quando si seleziona un comando. Il motore annuncia ogni round (`telegraph`). Evidenza: `battle_v2.gd` (condizione `bool(_G.boss["heavy"])`), `_refresh()` che costruisce `_G.boss`. Correzione: mostrare sempre l'annuncio (nome, bersaglio, tipo) in una zona fissa. Rischio: medio (HUD). Test: screenshot con mossa normale e pesante, con e senza comando scelto.
- **P0-2 Nessuna verifica su dispositivo reale** del criterio "touch, leggibilita' e prestazioni su Android". Non e' un difetto di codice ma blocca la dichiarazione "vertical slice pronta". Test: checklist su telefono (sezione 7).

### P1 — riducono qualita', chiarezza, soddisfazione
- **P1-1 Quasi nessun feedback di combattimento.** `_on_events()` gestisce solo `damage` (numero fluttuante + piccolo scossone del boss). Non c'e' nulla per: critico (l'evento ha `crit: true`), cura (`heal`), scudo (`shield`, 10 eventi in 3 round), schivata (`dodge`), KO (`down`), rottura equilibrio (`break`), stati (`buff`, `status`), contrattacco. L'eroe non ha reazione ai colpi. Correzione: livello feedback in scena (numeri colorati per tipo, marcatore critico, KO, rottura), senza toccare il motore. Rischio: basso/medio. Test: mappa eventi -> feedback con partita registrata.
- **P1-2 Impostazioni di accessibilita' ignorate.** La scena V2 usa solo `Settings.buzz`. Non rispetta `flash` (lampo bianco a ogni conferma: `flash = 1.0`, ULT fino a 0.55 di opacita'), `shake` (spinte di camera fino a 210 su ULT scelta), `light_fx` (la scena classica passa da sola a effetti ridotti se lenta), `skip_cutin`, `fast_battle`/`turbo`. Evidenza: ricerca di `Settings.` in `battle_v2.gd` (solo `buzz`) contro 16 usi in `battle_screen.gd`. Correzione: leggere le impostazioni in `_select`, `_confirm`, `_Fx`, particelle e velocita'. Rischio: basso. Test: con `flash=0` nessun lampo, con `shake=0` camera ferma, con `light_fx` meno particelle.
- **P1-3 Debolezze non mostrate.** Il commento in `_Hud` parla di "debolezze a destra" ma non e' disegnato nulla; la scena mostra solo salute ed "EQUILIBRIO". Il giocatore non vede cosa e' efficace. Correzione: indicatore di colore debole/resistente sul boss e sui comandi (da verificare nei dati cosa il motore espone). Rischio: medio. Test: screenshot per boss con debolezza.
- **P1-4 Solo 3 operatori su 6 combattono, e la scena non lo dice.** Con squadra di 6 sono in campo 3 slot (`p1_f2`, `p1_f3`); gli altri 3 non compaiono mai nella HUD e non si possono usare (`choice["swap"] = ""`). "FORMAZIONE" e "BERSAGLIO" mostrano solo un avviso ("non ancora nel Test V2"). La schermata Squadra permette di scegliere 6, il che fa pensare che tutti entrino. Correzione: decidere se il Test V2 e' 3 contro 1 (e dirlo nella schermata Squadra) o se implementare cambio/formazione. Rischio: alto se si implementa lo scambio (motore), basso se si chiarisce.
- **P1-5 Il bersaglio non si sceglie.** Contro il boss e' sempre uno; per le mosse "ally" `_choice_for` sceglie da solo l'alleato col rapporto PV piu' basso, senza che il giocatore lo sappia. Correzione: mostrare chi viene bersagliato o lasciare la scelta. Rischio: medio.
- **P1-6 Ritmo del round.** `_after_round` aspetta un tempo fisso (0.9 s / velocita') qualunque sia il numero di eventi; con 13 danni, 10 scudi e 4 cure in 3 round non e' garantito che si legga cosa e' successo. Non misurato su persone. Correzione: ritmo guidato dagli eventi (una breve sequenza per colpo). Rischio: medio.
- **P1-7 Variante di HUD non decisa.** Esiste solo la variante A (ramo `claude/battaglia-v2-hud-prova`, mai approvata, screenshot inviato); B e C non sono mai state prodotte. La base di leggibilita' per telefono e' stata alzata (etichette piccole x1.14, Roboto, contorno piu' spesso) ma senza confronto fra composizioni. Correzione: produrre B e C sulla stessa scena e scegliere. Rischio: basso (solo visivo).
- **P1-8 Nessun test automatico per la scena V2.** In `tests/unit` non c'e' nessun file che la riguardi (solo il conteggio dei pulsanti dell'hub). La copertura e' affidata a `tools/battle_v2_shot.gd`, non eseguito dalla suite. Correzione: `tests/unit/test_battle_v2.gd` (partita completa, aree di tocco a piu' risoluzioni, impostazioni rispettate, eventi -> feedback). Rischio: nullo.

### P2 — rifiniture
- **P2-1** Schermata di fine (VITTORIA/SCONFITTA) in stile ODISPEL classico (pulsanti `BattleTheme`) non coerente con la HUD V2; nessun riepilogo (colpi, danni, round).
- **P2-2** ESC o "ESCI" durante la battaglia esce senza conferma.
- **P2-3** Architettura: 1778 righe in un file; stato condiviso in variabili statiche (`_G`) che sopravvive al "RIGIOCA" (es. AUTO e velocita'). Separare in HUD/pittura/feedback aiuterebbe, ma e' un rischio da affrontare solo dopo i test.
- **P2-4** Il tocco e' letto solo come evento mouse (`InputEventMouseButton`): funziona perche' Godot converte il tocco in mouse, ma non gestisce il multi-tocco ne' l'annullamento di un trascinamento. Da verificare su telefono.
- **P2-5** Per i testi in Archivo Black piccoli (comandi rapidi, nomi) non c'e' ingrandimento su telefono (scelta voluta, per non spostare gli elementi); da rivalutare dopo la prova su dispositivo.

## 4. Differenze Windows / Android (verificate nel codice)
- Android: `Settings.light_fx` parte attivo, ma la scena V2 lo ignora; vibrazione solo su telefono; testi piccoli ingranditi con `TouchUi` (x1.14); limite fotogrammi a "senza limite" (segue lo schermo).
- Windows: solo mouse e tastiera (1-4, Invio/Spazio, Esc); `light_fx` spento; limite 60 di base.
- Stesso codice di disegno; la differenza di prestazioni reale (GPU del telefono) non e' misurata.

## 5. Piano di intervento nell'ordine piu' sicuro
1. Congelare: tag `v2-baseline-0.28.1` (fatto) e non toccare `claude/battaglia-v2` finche' un gruppo non e' approvato.
2. Test prima delle modifiche (P1-8): file di test della scena V2, per avere una rete di sicurezza.
3. Accessibilita' (P1-2): leggere `flash`, `shake`, `light_fx`, velocita'. Basso rischio.
4. Annuncio del boss (P0-1) e debolezze (P1-3): lavoro di HUD, con varianti A/B/C confrontate (P1-7).
5. Livello di feedback (P1-1) e ritmo del round (P1-6): solo in scena, a partire dagli eventi del motore.
6. Decisione su squadra (P1-4, P1-5): prima chiarire il 3 contro 1 nella schermata Squadra; lo scambio in battaglia solo se lo vuoi (tocca il motore).
7. Prova su telefono reale con la checklist; correzioni.
8. Rifiniture P2 e congelamento della versione di riferimento.

## 6. File che probabilmente dovranno cambiare
`scenes/battle_v2/battle_v2.gd` (quasi tutto), nuovo `tests/unit/test_battle_v2.gd`, `tools/battle_v2_shot.gd` e `tools/battle_v2_anim.gd` (nuovi scenari), `scenes/squad_v2/squad_v2.gd` (avviso 3 contro 1), `QA_HANDOFF.md`, `docs/BATTAGLIA_V2_PIANO.md`. Il motore (`scripts/battle/*`) non dovrebbe cambiare, salvo la decisione sullo scambio (punto 6).

## 7. Vertical slice proposta (una battaglia di riferimento)
Boss: Distributore, difficolta' 0; squadra fissa Kira, Dax, Elle; seme casuale fisso per poter ripetere la stessa partita. Round previsti:
1. Attacco base su un bersaglio; difesa con Dax. Si valuta selezione, conferma, impatto.
2. Skill con Kira (se serve piu' di un'opzione, ciclo con il secondo tocco); cura o scudo con Elle.
3. Annuncio di una mossa pesante del boss: lettura dell'annuncio e risposta con difesa.
4. Rottura dell'equilibrio / debolezza (da verificare nei dati del boss quale mossa la provoca), critico.
5. Ultimate di Kira (serve la barra piena: in allenamento va caricata con un'impostazione di prova della slice, non cambiando il motore), danno alto e KO del boss, oppure KO di un alleato per vedere anche la sconfitta.
Cosi' si coprono: azioni, bersaglio, normale, skill, difesa, debolezza/equilibrio, critico, ultimate, KO, turno nemico con annuncio, vittoria o sconfitta.

## 8. Test e screenshot per dichiarare la slice pronta
- Test automatici: partita completa senza errori; ogni area di tocco dentro lo schermo e senza sovrapposizioni a 1280x720, 1920x1080, 2400x1080, 2560x1080 e 1600x720; impostazioni (`flash=0`, `shake=0`, `light_fx`) rispettate; ogni tipo di evento produce il suo feedback; 81 test esistenti verdi.
- Screenshot (stessa scena e risoluzione per ogni variante A/B/C): scelta comandi, skill, ultimate scelta, annuncio normale e pesante, colpo critico, KO, rottura, vittoria, sconfitta; PC e touch.
- Prova su telefono reale (fuori dalla mia portata): fotogrammi per secondo stabili in scelta/skill/ultimate, leggibilita' a distanza normale, tocco affidabile su tutti i comandi, nessun flash fastidioso con effetti ridotti, aggiornamento APK riuscito.

## 9. Criteri (dal documento) e stato attuale
| Area | Stato |
|---|---|
| HUD | Parziale: leggibile a risoluzione simulata, variante non decisa |
| Comandi | Selezionato/conferma chiari; "non disponibile" solo con avviso |
| Combattimento | Insufficiente: solo il danno ha feedback (P1-1) |
| Boss | Insufficiente: annuncio solo per mosse pesanti, nessuna debolezza (P0-1, P1-3) |
| Impatto | Non valutabile senza ritmo e feedback (P1-1, P1-6) |
| PC | Layout e input funzionano nella simulazione; nessun test automatico dedicato (P1-8) |
| Android | Non verificato su dispositivo (P0-2) |
| Stabilita' | 81 test verdi, nessuno sulla scena V2 |
