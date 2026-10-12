# Giocare online con i dati mobili (server di inoltro TURN)

Il gioco collega i giocatori direttamente (WebRTC). Con i dati mobili e alcune reti la connessione diretta e' bloccata:
serve un server di **inoltro (TURN)** che fa passare il traffico. Il gioco lo usa se trova le credenziali in `config/turn.cfg`
(il file non e' nel repository, cosi' le credenziali non finiscono su GitHub; viene incluso nell'APK e nell'exe quando si esporta).

## Come ottenere le credenziali gratis (Metered Open Relay, 20 GB/mese)
1. Crea un account gratuito su https://www.metered.ca (sezione Open Relay / TURN) e crea un'app: ti da' una **API key**.
2. Apri nel browser: `https://NOMEAPP.metered.live/api/v1/turn/credentials?apiKey=LA_TUA_API_KEY`
3. Risponde con un elenco di server: copia `username` e `credential` (sono uguali per tutti gli indirizzi) e gli indirizzi `turn:` / `turns:`.
4. Copia `config/turn.cfg.example` in `config/turn.cfg` e scrivi url (indirizzi separati da virgola), user e pass.
5. Esporta di nuovo exe e APK: chi usa la nuova versione puo' collegarsi anche con i dati mobili.

Nota: le credenziali stanno dentro il gioco che mandi agli amici: usa un account gratuito dedicato e, se serve, rigeneralo.
Alternativa senza file: variabili d'ambiente `ODISPEL_TURN_URL`, `ODISPEL_TURN_USER`, `ODISPEL_TURN_PASS` (solo PC).
