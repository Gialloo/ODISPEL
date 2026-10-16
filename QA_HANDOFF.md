# QA_HANDOFF — ODISPEL 0.24.32

## Identificazione
- Versione: 0.24.32 (Android versionCode 57)
- Data build: 16 ottobre 2026
- Branch: `claude/battaglia-chiara` (commit: vedi `git log -1`; il commit di questa iterazione contiene questo file)
- Obiettivo: Fase 2, leggibilita' della minaccia del boss (anteprima vs colpo reale), partendo dai dati.
- Iterazione precedente (0.24.31): validazione dei salvataggi + etichetta 'danno minimo' dopo l'audit di ChatGPT.

## Misura (0.24.32)
- Nuovo `tools/preview_check.gd`: confronta l'anteprima con il colpo reale (3 boss x 3 squadre x 20 semi, 488 confronti, scelte dell'IA).
- Risultato: 326 uguali; 162 con colpo reale piu' forte (sempre x1.24-1.26, causa: il boss scende sotto meta' PV durante il round e si infuria, +25%); 0 con colpo reale piu' debole. Non coperti dal campione: Guardia, critico, rabbia contro le cure, placche, catene.
- Correzione: `threat_preview()` ora restituisce anche `enrage_lethal` (chi morirebbe solo se il boss si infuria). La schermata mostra "SE SI INFURIA: LETALE PER ..." quando il boss e' tra 50% e 75% PV. 3 nuovi controlli in `test_battle.gd` (105 passati).

## Modifiche (0.24.31, gia' consegnate)
- Salvataggi/stato di battaglia: nuovo controllo `BattleState.validate()` (+ `check_json()`); `from_json()` rifiuta stati incompleti o rovinati e dice perche'. Il client multiplayer ignora uno snapshot non valido con un avviso. Il PvP (senza boss) e' gestito.
- HUD: l'attacco annunciato del boss mostra "DANNO MIN. ~N" (l'anteprima non include rabbia, placche, catene, che nascono durante il round).
- Documentato in codice che lo scudo da cura in eccesso (`heal_shield`) e' VOLUTO (decisione del proprietario).
- File principali: `scripts/battle/battle_state.gd`, `scripts/network/network_manager.gd`, `scenes/battle/battle_screen.gd`, `scripts/battle/battle_resolver.gd` (solo commento), `tests/unit/test_battle.gd`.
- Nessun cambio ai dati persistenti ne' al protocollo multiplayer (solo rifiuto di dati non validi).

## Esito dell'audit ChatGPT (verificato sul codice)
- FALSO: "test 1644 vs 1645" (`test_battle` passa 101/101).
- FALSO: "gauge int/2 produce float" (in GDScript int/int e' int).
- PARZIALE: "test su motore sbagliato": `CombatResolver` (vecchio) e' ancora usato da `network_manager.gd` e dalla scena demo; `BattleResolver` e' il motore nuovo, coperto da `test_battle*`.
- CONFERMATO e gestito: anteprima boss = danno minimo; stato malformato accettato.
- CONFERMATO ma voluto: scudo da cura teorica.
- NON verificati (rischi ipotetici, nessuna prova): scudo/cura su bersaglio a 0 PV nella stessa mossa, etichetta sinergia decisiva, munizioni condivise tra torretta e drone, velocita' boss in anteprima vs reale, bilanciamento roster.

## Test
- Eseguiti (0.24.32): tutti i 74 file in `tests/unit/` in headless (parallelo). Due (`test_hud_layout` 23/23, `test_input_ui`) richiedono uno schermo e sono passati con `xvfb-run`.
- Nuovi: 9 controlli di validazione in `test_battle.gd` (ora 101 passati, 0 falliti).
- Esito: nessun test fallito.
- NON eseguiti: multiplayer con giocatori reali, rete pubblica, Android su dispositivo, bilanciamento con simulazioni (`tools/battle_sim.gd` non lanciato).
- Limite: la validazione Godot e' quella dei test; non ho un controllo di performance su telefono.

## Build e pubblicazione
- `releases/ODISPEL-0.24.32-windows.zip` (exe + dll WebRTC) e `releases/ODISPEL-0.24.32.apk` (firma di debug, 1 firmatario verificato con apksigner). Percorso nel repo privato: `https://github.com/Gialloo/odispel/tree/claude/battaglia-chiara/releases`
- SHA256 in `releases/SHA256SUMS.txt`. Resta la 0.24.31 come ultima versione precedente recuperabile.
- itch.io: il workflow `.github/workflows/itch.yml` carica da solo gli ultimi file di `releases/` dopo il push. Dal mio ambiente NON vedo l'esito: controllare la scheda Actions su GitHub o la pagina itch.io.
- Non verificato: avvio dell'exe su Windows e installazione dell'APK su telefono.

## Problemi aperti
- Anteprima boss ancora senza bonus di round (ora dichiarata "minimo").
- Tre stili di pannello nella HUD; HUD PvP non allineata alla palette.
- Leggibilita' e prestazioni su telefono reale non verificate.
- Simbolo AUTO: sintomo esatto non ricevuto.
- Multiplayer a 4 giocatori reali e Internet pubblico: non verificati.

## Playtest (per il proprietario)
1. Avvia il gioco: deve comparire la finestra NOVITA' 0.24.31 con tasto OK visibile.
2. Battaglia contro un boss: l'attacco annunciato mostra "DANNO MIN. ~numero"; se e' mortale, "LETALE PER ..."; se il boss e' tra 50% e 75% di vita e potrebbe uccidere solo infuriandosi, "SE SI INFURIA: LETALE PER ..." (arancio). Dimmi se l'avviso ti aiuta o ti confonde.
3. Gioca un round completo e una partita online (se possibile): nessun messaggio di "stato non valido" in condizioni normali.
4. Se compare "Stato della sfida non valido" o un crash: segna schermata, modalita' (solo/online), boss e dispositivo.

## Prossimo passo
- Misurare anche Guardia, critici e catene con lo stesso strumento e decidere, dopo il tuo playtest, se mostrare un intervallo di danno. Il campione attuale copre solo l'IA. Dipende dal tuo feedback sul "danno minimo"; rischio: toccare il motore deterministico, da coprire con test esatti.
