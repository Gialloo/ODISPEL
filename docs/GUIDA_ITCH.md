# Pubblicare ODISPEL su itch.io (solo per gli amici)

Serve per far scaricare APK e zip Windows da qualsiasi posto, senza GitHub.
I file da caricare stanno nella cartella `releases` del ramo `claude/battaglia-chiara`.

## 1. Creare la pagina (una volta sola)

1. Crea un account su https://itch.io e apri **Dashboard > Create new project**.
2. **Title**: ODISPEL. **Kind of project**: Downloadable.
3. In **Visibility & access** scegli **Restricted** e metti una **password**: la dai solo agli amici. In alternativa **Draft** (solo tu la vedi).
4. Salva. Il progetto ha un nome nell'indirizzo, per esempio `tuonome.itch.io/odispel`.

## 2. Caricare i file a mano (la via piu' semplice)

1. Nella pagina del progetto vai su **Edit game > Uploads > Upload files**.
2. Carica `ODISPEL-<versione>-windows.zip` e spunta **Windows**.
3. Carica `ODISPEL-<versione>.apk` e spunta **Android**.
4. Salva. Ad ogni versione nuova: togli i file vecchi e carica quelli nuovi.

## 3. Caricare con butler (piu' veloce, facoltativo)

`butler` e' il programma di itch.io per caricare le versioni da PowerShell.

1. Scaricalo da https://itch.io/docs/butler/ e scompattalo (per esempio in `C:\butler`).
2. Accedi una volta sola: `C:\butler\butler.exe login` (si apre il browser).
   La chiave resta solo sul tuo PC: non incollarla mai in chat e non metterla nel progetto.
3. Carica le versioni (cambia `tuonome` e il numero di versione):

```
C:\butler\butler.exe push ODISPEL-0.24.21-windows.zip tuonome/odispel:windows --userversion 0.24.21
C:\butler\butler.exe push ODISPEL-0.24.21.apk tuonome/odispel:android --userversion 0.24.21
```

Il nome dopo i due punti (`windows`, `android`) e' il "canale": itch.io capisce da solo il sistema.
Con lo stesso comando, a ogni nuova versione, il vecchio file viene sostituito.

## 4. Per gli amici

- Mandagli il link della pagina e la password.
- Windows: scaricare lo zip, tasto destro > Estrai tutto, avviare `ODISPEL.exe` (il file `.dll` resta nella stessa cartella).
- Android: scaricare l'APK, aprirlo e consentire l'installazione da questa fonte. Se c'e' gia' una versione con firma diversa, prima disinstallarla.

## 4. Caricamento automatico (GitHub -> itch.io)
Il file `.github/workflows/itch.yml` carica da solo su itch.io l'APK e lo zip piu' recenti di `releases/` ogni volta che vengono pubblicati sul ramo `claude/battaglia-chiara`.
Una volta sola, tu devi:
1. Su itch.io: **Impostazioni > API keys > Generate new API key** e copia la chiave (non scriverla in chat ne' nel repository).
2. Su GitHub, nel repository: **Settings > Secrets and variables > Actions > New repository secret**. Nome: `ITCH_API_KEY`, valore: la chiave.
3. Per provare subito: scheda **Actions > Pubblica su itch.io > Run workflow**.
Se cambi il nome della pagina itch.io, modifica `ITCH_TARGET` nel file.
