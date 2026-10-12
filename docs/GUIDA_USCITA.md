# ODISPEL - guida all'uscita (per te)

## 1. Creare la versione per Windows
1. Apri Godot > **Editor > Gestisci modelli di esportazione** > **Scarica e installa** (versione 4.7.2). Si fa una volta sola.
2. In PowerShell, nella cartella del progetto: `.\tools\esporta.ps1`
   (se Godot non e' nel PATH: `.\tools\esporta.ps1 -Godot "C:\percorso\Godot.exe"`)
3. Trovi `build\ODISPEL-<versione>.zip`: dentro ci sono `ODISPEL.exe` (con tutto il gioco), la cartella `art\` (per le tue grafiche), `dialogues\` e `LEGGIMI.md`.
4. Prova lo zip su un altro PC (o su un altro utente Windows): decomprimi, apri l'exe, gioca una missione da solo e apri Impostazioni > APRI CARTELLA GRAFICHE.

Icona: e' `icon.ico` nella cartella del progetto (gia' collegata all'esportazione). Per cambiarla, sostituisci `icon.ico` (e `icon.png`) con il tuo disegno tenendo i nomi.

Avviso "file dannoso" / SmartScreen: compare per tutti gli exe non firmati. Si evita solo con la firma di codice (certificato a pagamento) o distribuendo da una piattaforma (itch.io, Steam). Con gli amici: "Ulteriori informazioni" > "Esegui comunque".



## 2. Test multiplayer tra reti diverse (la prova che manca)
Serve un amico (o il tuo telefono come seconda rete: hotspot).
1. Tu fai l'host, l'amico entra con lo stesso codice (vedi `docs/PROVA_ONLINE.md`).
2. Controlla questi punti e annotali:
   - [ ] l'amico entra nella stanza entro 20 secondi
   - [ ] vedete entrambi la squadra dell'altro nella lobby
   - [ ] PRONTO / cambio boss si aggiorna per tutti
   - [ ] la battaglia parte per entrambi, i danni coincidono
   - [ ] a fine battaglia entrambi ricevono i premi e gli obiettivi giornalieri avanzano
   - [ ] se l'amico chiude il gioco in battaglia, l'host riceve l'avviso e non si blocca
3. Se "connessione con l'host non riuscita" compare solo con certe reti, serve un server **TURN** (relay):
   imposta queste variabili d'ambiente PRIMA di aprire il gioco (su tutti i PC coinvolti):
   `ODISPEL_TURN_URL` (es. `turn:turn.esempio.com:3478`), `ODISPEL_TURN_USER`, `ODISPEL_TURN_PASS`.
   Ti consiglio di rimandare questa parte finche' non vedi il problema davvero.

## 3. Server di segnalazione (Render)
Il server ora ha: limite di 500 stanze e 2000 connessioni, ping ogni 25 s (non viene piu' chiuso dalla piattaforma per inattivita'), blocco di chi manda troppi messaggi, chiusura di chi non entra in una stanza, e la pagina `/stats` (stanze e connessioni attuali).
- Provato in locale con 300 stanze x 6 giocatori insieme (1800 connessioni): tutte entrate in meno di 1 secondo.
- Dopo il merge, Render aggiorna il server da solo (se e' collegato al repository). Controlla aprendo `https://odispel-signaling.onrender.com/stats` nel browser.
- Il piano gratuito si "addormenta" dopo 15 minuti senza richieste: la prima connessione puo' impiegare fino a 1 minuto.
- Prova di carico contro il server vero (dalla cartella `odispel-signaling`, serve `npm install` una volta):
  `node loadtest.js wss://odispel-signaling.onrender.com 20 3`
