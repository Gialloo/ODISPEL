# ODISPEL - Audit tecnico comune (sicurezza, rilascio, prestazioni)

Data: 2026-10-13 - versione 0.24.7. Fonte di verita': il repository. Ogni voce dice se e' **VERIFICATO** (provato con un test o un comando), **LETTO** (visto nel codice ma non provato) o **NON VERIFICABILE** (servono dispositivi o servizi veri).

## 1. Architettura reale

| Parte | Cosa fa davvero | Chi decide |
|---|---|---|
| Client Godot 4.7 (PC, Android) | Tutto il gioco: collezione, combattimento, ricompense, salvataggio | Il client |
| Server di signaling (Render, Node + `ws`) | Mette in contatto i giocatori: smista offerte WebRTC, nient'altro. Non conosce partite, account, ricompense | Nessuna autorita' di gioco |
| WebRTC (libreria nativa `webrtc_native`) | Canale diretto host - giocatori; TURN opzionale per le reti difficili | - |
| Host di una partita | Calcola il combattimento PvP/co-op e manda lo stato agli altri | L'host e' l'autorita' della partita |
| Salvataggio | File JSON locale `user://` (collezione, monete, progressi) | Il giocatore (il file e' suo) |

Non esistono account, database, API di progressione ne' classifiche online. L'identita' di un giocatore e' un token casuale generato dal client (serve solo a rientrare in una partita).

## 2. Mappa di fiducia dei dati

- **Affidabile solo in parte:** lo stato della battaglia di rete (lo decide l'host: gli altri si fidano dell'host).
- **Controllato dal giocatore:** salvataggio, monete, personaggi, progressi, equipaggiamento. Chi modifica il file, o il client, ottiene quello che vuole in modalita' solitaria. **Non si puo' impedire** senza un server che conservi la progressione: e' un limite dell'architettura, non un bug.
- **Cosmetico:** impostazioni, volume, tutorial.
- **Vantaggio competitivo:** squadra e livelli in PvP (vedi 4: la squadra ricevuta e' controllata dall'host).

## 3. Cosa gia' c'e' (LETTO + test esistenti)

- Il server limita: messaggi 64 KB, 120 messaggi/10 s per connessione, 500 stanze, 2000 connessioni, timeout di ingresso, ping/pong, nome stanza solo `[a-zA-Z0-9_-]{1,48}`, i giocatori parlano solo con l'host, errori generici. Ha test (`server.test.js`, `server.limits.test.js`).
- L'host controlla ogni squadra ricevuta (`RosterState.validate_team`: personaggio esistente, livello/rank entro i limiti, fazione e rarita' coerenti con la definizione, mosse valide e non duplicate, niente doppioni), taglia il nome a 24 caratteri, ripulisce profilo e progressi dichiarati, pulisce la chat, accetta solo i comandi di battaglia validi per quel giocatore e ignora messaggi di chi non e' in partita.
- Le credenziali TURN stanno in `config/turn.cfg`, **ignorato da Git**; nella cronologia Git non risultano segreti (cercati: `turn.cfg`, password/chiavi in chiaro: nessuna corrispondenza).
- Nessun `OS.execute` (solo `OS.shell_open` per aprire la cartella delle immagini, percorso fisso), nessun caricamento di codice da rete, nessun file ricevuto dalla rete salvato su disco (LETTO: ricerca nel codice).
- Salvataggio: scrittura su file temporaneo e poi rinomina; il caricamento rifiuta dati non validi.

## 4. Registro delle vulnerabilita' e dei rischi

Gravita' secondo il documento di sicurezza (P0 critico ... P3 miglioramento). "Confermato" = riprodotto con un test.

| ID | Gravita' | Stato | Descrizione | Azione |
|---|---|---|---|---|
| S-01 | P1 | **CORRETTO** (confermato con test) | Un salvataggio rovinato veniva sostituito da una collezione nuova al salvataggio successivo: perdita totale dei progressi. Inoltre nessuna copia di sicurezza | `RosterStore`: copia `.bak` a ogni salvataggio, ripristino automatico, il file rovinato resta in `.corrotto`. Test `test_security.gd` |
| S-02 | P2 | **CORRETTO** (confermato con test) | Un giocatore collegato poteva inondare l'host di messaggi o mandare pacchetti enormi | `WebRTCLink`: pacchetti oltre 256 KB scartati, oltre 120 messaggi/s scartati, 5 secondi di fila di eccesso chiudono il collegamento. Test `test_security.gd` |
| S-03 | P1 | **APERTO, limite architetturale** | Monete, personaggi e progressi sono nel file locale: modificabili. Nessuna classifica o vantaggio permanente online dipende da questi dati, quindi l'impatto oggi e' solo sul proprio gioco | Documentato. Se in futuro ci saranno classifiche o scambi: serve un backend autorevole (vedi decisioni) |
| S-04 | P1 | **APERTO** | Le credenziali TURN sono nel pacchetto del gioco (`config/turn.cfg` e' incluso nell'export): chiunque scarichi il gioco puo' estrarle e usare il relay a nostre spese | Appena ci sono i dati di metered.ca: usare credenziali a scadenza richieste al momento (API del provider), o limitare l'uso dal pannello del provider. Intanto: non distribuire pubblicamente il gioco con credenziali permanenti |
| S-05 | P2 | APERTO | In PvP l'host e' l'autorita': un host modificato puo' falsare la partita (non puo' toccare i salvataggi degli altri) | Limite del modello host-authoritative, documentato. Per partite competitive serie serve un server |
| S-06 | P2 | APERTO | Il server non limita i tentativi per indirizzo IP (solo per connessione) e `/stats` e' pubblico (mostra solo conteggi) | Limitare per IP sul proxy di Render o con un controllo aggiuntivo; non urgente a basso traffico |
| S-07 | P2 | NON VERIFICATO | `npm audit` non eseguibile qui (nessun accesso al registro). Unica dipendenza: `ws ^8.22` con file di blocco | Eseguire `npm audit --omit=dev` sul PC e prima di ogni deploy |
| S-08 | P2 | APERTO | Libreria nativa `webrtc_native` (con licenze incluse): versione e provenienza non registrate nel repository | Annotare versione e origine; aggiornare quando esce una correzione |
| S-09 | P2 | APERTO | Nessun controllo di integrita' sugli aggiornamenti: si distribuisce a mano un APK/ZIP | Pubblicare l'hash SHA-256 insieme a ogni build (procedura in 6) |
| S-10 | P3 | APERTO | Nessuna firma di rilascio Android dedicata verificata, nessun log di abusi lato server (solo console Render) | Valutare quando si pubblica su uno store |

Non trovati: segreti nel repository, iniezioni (nessun database o SQL; JSON analizzato in modo sicuro), esecuzione di comandi, percorsi file controllati da rete.

## 5. Prestazioni (misure reali, ma in ambiente senza scheda grafica)

`tools/perf_probe.gd`, 1280x720, rendering software (xvfb): quindi **i millisecondi non sono quelli di un PC o telefono reale** e non li uso come prova. Contano le misure strutturali:

| Schermata | Chiamate di disegno | Nodi |
|---|---|---|
| Hub | 242 | 150 |
| Squadra | 553 | 393 |
| Lobby | 100 | 163 |
| Battaglia | 419 | 243 |
| PvP | 161 | 180 |

Valutazione: numeri accettabili per Compatibility su PC; **Squadra e Battaglia sono le piu' pesanti** e vanno controllate su un telefono vero. Esiste gia' un livello di qualita' alto/basso, un limite FPS e V-Sync nelle impostazioni (testati). **Non ho ottimizzato nulla di cui non ho misure su hardware vero**: sarebbe inventare un miglioramento. Prossimo passo: sul telefono, con FPS e monitor visibile, annotare i frame in battaglia e in Squadra.

## 6. Rilascio

| Requisito | Stato |
|---|---|
| Il progetto si importa e si avvia | PASS (importazione e avvio headless ogni giorno) |
| Test automatici | PASS: tutta la suite (54 file) verde, ultima esecuzione 0.24.7 |
| Controllo interfaccia a 1600x720 | PASS (0 problemi) |
| Esportazione Android | PASS (APK 0.24.7 generato) |
| Esportazione Windows | PARTIAL: il PC dell'utente la produce con `tools/esporta.ps1`; qui non e' eseguita |
| Build senza test e strumenti | PASS (filtri di esclusione nel preset) |
| Account e progressione online | FAIL / non previsto: oggi non esistono |
| Multiplayer su reti diverse (TURN) | UNVERIFIED: mancano credenziali e test sul campo |
| Log degli errori in rete | PARTIAL: tracce `[NET` nel log; aspetto il log dell'utente per il bug del PRONTO |
| Immagini finali | FAIL: 10/270 presenti |

**Procedura hash:** dopo ogni build, `sha256sum file` (Linux/macOS) o `Get-FileHash file` (PowerShell) e pubblicare il valore accanto al file.
**Rollback server:** Render conserva i deploy precedenti: dal pannello "Rollback" sul deploy buono. Rotazione credenziali TURN: generare nuove credenziali nel pannello metered.ca, aggiornare `config/turn.cfg`, ricostruire il gioco.

## 7. Decisioni di architettura da prendere (non prese ora)

1. **Progressione online autorevole?** Oggi tutto e' locale. Se si vogliono classifiche reali o scambi, serve un servizio con account e salvataggi sul server. Costo alto. Finche' il gioco e' tra amici, non serve.
2. **PvP competitivo:** host-authoritative va bene tra amici; per il pubblico servirebbe un server che esegue le partite (`PvpEngine` e' gia' solo dati, quindi si potrebbe portare su un server).
3. **TURN:** credenziali a scadenza invece che permanenti nel pacchetto.

## 8. Roadmap consigliata

1. (fatto) Copia di sicurezza dei salvataggi e difese del canale.
2. Ottenere credenziali TURN e provare PC-telefono su reti diverse.
3. Misure di FPS sul telefono; ottimizzare Squadra/Battaglia solo dopo.
4. Hash di ogni build, annotare versione di `webrtc_native`, `npm audit` sul PC.
5. Decidere (1) e (2) solo se si vuole aprire il gioco al pubblico.

## 9. Test di sicurezza

Eseguiti ora: `tests/unit/test_security.gd` (salvataggio rovinato, copia di sicurezza, file rovinato messo da parte, pacchetti enormi, inondazione di messaggi): 11 passati. Esistenti: validazione squadre, protocollo PvP, abbandono, server (limiti, stanze, errori). Mancano: prove con due reti diverse, carico reale sul server (c'e' `loadtest.js`, non rieseguito qui).
