# Avviso di Windows e DLL WebRTC (A1) - diagnosi

Stato: **causa probabile identificata, NON ancora verificata su un PC Windows. A1 resta APERTO.**

## Cosa e' stato verificato (14 ottobre 2026, versione 0.24.21)
- Il pacchetto Windows contiene due file: `ODISPEL.exe` e `libwebrtc_native.windows.template_release.x86_64.dll`.
- La DLL e' identica (SHA-256 `3a8053d325a874493f596630b0f165f3a83e265c61d9fd87d82da6cb4c2a81fd`) a quella del progetto in `addons/webrtc_native/lib/`.
  E' il plugin ufficiale di Godot "webrtc-native" (libdatachannel, libjuice, libsrtp, mbedtls, usrsctp; licenze nella cartella `addons/webrtc_native/`).
  Serve al multiplayer: senza, la rete non parte.
- **Ne' l'exe ne' la DLL hanno una firma digitale** (controllo del file PE: nessuna firma Authenticode).
- Non e' stato possibile, da questo ambiente, confrontare la DLL con quella pubblicata sul sito ufficiale (accesso a GitHub non abilitato). **L'origine e' quindi plausibile, ma non dimostrata.**

## Causa probabile
Un eseguibile senza firma e senza "reputazione" fa comparire **SmartScreen** ("Windows ha protetto il PC" / "Autore sconosciuto") al primo avvio dello zip scaricato.
Il caricamento della DLL accanto all'exe puo' far comparire una seconda richiesta, perche' anche la DLL non e' firmata. Non e' un segnale di malware: e' l'assenza di firma.
Il **testo esatto** dell'avviso e il **nome del file** indicato da Windows non sono stati raccolti: servono per essere certi (vedi sotto).

## Cosa fare (nessuna richiede di disattivare le protezioni di Windows)
1. **Raccogliere il messaggio**: chiedere a un amico lo screenshot dell'avviso (titolo, nome file, "Editore").
2. **Verificare la DLL**: scaricare dalla pagina ufficiale `godotengine/webrtc-native` (Releases) il pacchetto della stessa versione e confrontare l'hash
   (`Get-FileHash .\libwebrtc_native.windows.template_release.x86_64.dll -Algorithm SHA256`). Se coincide, l'origine e' dimostrata.
3. **Pubblicare gli hash**: `releases/SHA256SUMS.txt` contiene gli hash di APK e zip, cosi' gli amici possono controllare che il file non sia stato alterato.
4. **Firmare il codice** (soluzione vera): certificato di firma (es. servizio di firma gestito, oppure SignPath per progetti open source) e firmare **exe e DLL**.
   Limite: costa, richiede identita' verificata; la reputazione SmartScreen si costruisce comunque col tempo.
5. **Distribuzione affidabile**: l'app itch.io (che scarica da sola) o un caricamento su VirusTotal riducono i falsi allarmi di Defender, ma non sostituiscono la firma.
6. Per gli amici nel frattempo: scaricare solo dal link indicato dallo sviluppatore, controllare l'hash e usare "Maggiori informazioni > Esegui comunque" **solo** se l'hash coincide.

## Non fatto / da verificare
- Test su un'installazione di prova Windows pulita (non disponibile qui).
- Confronto hash con il rilascio ufficiale (punto 2).
- Firma digitale (punto 4): decisione e costi dell'utente.
- Non rimuovere la DLL: il multiplayer dipende da lei.
