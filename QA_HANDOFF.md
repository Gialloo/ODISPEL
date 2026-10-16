# QA_HANDOFF — ODISPEL 0.24.31

## Identificazione
- Versione: 0.24.31 (Android versionCode 56)
- Data build: 16 ottobre 2026
- Branch: `claude/battaglia-chiara` (commit: vedi `git log -1`; il commit di questa iterazione contiene questo file)
- Obiettivo: verificare l'audit tecnico di ChatGPT sul codice, correggere solo quello dimostrato e decidere i punti di design.

## Modifiche
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
- Eseguiti: tutti i 74 file in `tests/unit/` in headless (parallelo). Due (`test_hud_layout` 23/23, `test_input_ui`) richiedono uno schermo e sono passati con `xvfb-run`.
- Nuovi: 9 controlli di validazione in `test_battle.gd` (ora 101 passati, 0 falliti).
- Esito: nessun test fallito.
- NON eseguiti: multiplayer con giocatori reali, rete pubblica, Android su dispositivo, bilanciamento con simulazioni (`tools/battle_sim.gd` non lanciato).
- Limite: la validazione Godot e' quella dei test; non ho un controllo di performance su telefono.

## Build e pubblicazione
- `releases/ODISPEL-0.24.31-windows.zip` (exe + dll WebRTC) e `releases/ODISPEL-0.24.31.apk` (firma di debug, 1 firmatario verificato con apksigner). Percorso nel repo privato: `https://github.com/Gialloo/odispel/tree/claude/battaglia-chiara/releases`
- SHA256 in `releases/SHA256SUMS.txt`. Resta la 0.24.30 come ultima versione precedente recuperabile.
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
2. Battaglia contro un boss: quando annuncia un colpo su un bersaglio, deve comparire "DANNO MIN. ~numero"; se e' mortale, "LETALE PER ...".
3. Gioca un round completo e una partita online (se possibile): nessun messaggio di "stato non valido" in condizioni normali.
4. Se compare "Stato della sfida non valido" o un crash: segna schermata, modalita' (solo/online), boss e dispositivo.

## Prossimo passo
- Fase 2: scegliere UN incontro rappresentativo e rendere leggibile la minaccia (danni, reazioni) in modo coerente tra anteprima e colpo reale; dopo il playtest. Dipende dal tuo feedback sul "danno minimo"; rischio: toccare il motore deterministico, da coprire con test esatti.
