# ODISPEL · istruzioni per Claude

Questo file lo leggono da sole tutte le sessioni di Claude che aprono il repository. Rispondi **in italiano**.

## Prima di lavorare

1. Leggi, nella cartella del progetto: `/mnt/project-files/LEGGIMI.md` (indice), `/mnt/project-files/odispel/ODISPEL_TUTTO.md` (universo e canone), `/mnt/project-files/odispel/BIBBIA_DI_LAVORO.md` (regole dell'autore). Il piano di produzione è in `/mnt/project-files/odispel/produzione/PIANO_DI_PRODUZIONE.md`.
2. **Regola dell'autore: aggiungi, non togliere; ottimizza, non sostituire.**
3. L'ultima parola è sempre dell'autore, Gianluca (regola L2): le IA propongono, l'autore decide.
4. Se la cartella del progetto non c'è (sessione senza progetto), le stesse regole stanno in breve qui sotto e, per la storia, in `docs/STORIA.md`.

## Le regole in una riga

> Se non coinvolge, non c'è. Se c'è, è fatto con cura, con stile e con intenzione.

Quando due regole si scontrano: **5 Divertirsi** batte tutto, poi 1 Fun e 7 Sentimento, poi 11 Leggibilità. Prima di aggiungere qualsiasi cosa fai la prova rapida (Bibbia, Parte 4): diverte? so dire perché c'è? smuove? è riconoscibile come ODISPEL? è curato? si capisce? ha qualcosa di nostro? lascia voglia di altro?

Regole dell'universo confermate: storie separate, stesso universo, nessun media spiega tutto (U1-U3); niente medioevo, divise e streetwear (U10); influenze lontane tra media, mai incroci di trama, Malocchio non compare (U14, U17); ogni climax al culmine del suo arco (U18); la comicità nasce dal contrasto, mai dall'incompetenza (U19); gli oggetti raccontano i personaggi (U20).

## Il progetto in questo branch

- **V3, OFFICIAL DEMO ODISPEL**: JRPG 3D a turni alla Persona, atto 1. Godot 4.7.2, renderer `gl_compatibility`, telefono prima di tutto (60 fps, testi grandi). Struttura e comandi in `README.md`.
- Canone del gioco: `docs/STORIA.md`, `data/atto1.json`, `data/dialoghi_atto1.json`. Stile: `docs/STILE_VISIVO.md` (vince l'aggiornamento in cima: urbano di oggi).
- **Nomi**: nel codice gli id `ferri` e `zecca` sono **Lance** e **Rio**. Nei testi si usano sempre i nomi canonici.
- I dialoghi **non si modificano a mano**: si corregge `tools/gen_dialoghi.py` e si rigenera `data/dialoghi_atto1.json`.
- Le battaglie e l'atto si provano da soli: `tests/unit/`, `tools/v3_atto1.gd`, `tools/v3_vetrina.gd`, `tools/v3_prestazioni.gd`.

## Agenti del progetto

In `.claude/agents/` ci sono agenti con istruzioni già scritte: `guardiano-bibbia`, `qa-godot`, `prestazioni-telefono`, `voce-dei-personaggi`, `regista-battaglia`, `marketing-odispel`. Usali per il loro compito invece di rispiegare tutto da capo. Se un agente sbaglia, migliora il suo file (aggiungi, non togliere).

## Cose da non fare mai

- Mettere nel repository chiavi, password, `.pem`, credenziali (il repo è pubblico). La chiave di firma sta solo in `/mnt/project-files/odispel/chiavi/`.
- Pubblicare (itch, store, social), inviare messaggi o spendere soldi senza il via dell'autore. Attenzione: un push che cambia i file in `releases/` fa partire la pubblicazione su itch.
- Unire branch a `main` o a `claude/v3-prologo` senza il via dell'autore.
- Inventare risultati: se un test non si può lanciare (es. Godot non scaricabile), dillo.

## Dove mettere le cose nuove

Canone dell'universo: si aggiorna `ODISPEL_TUTTO.md` nella cartella del progetto. Materiale di lavoro: sottocartelle per gioco in `/mnt/project-files/odispel/`. Ogni file nuovo va aggiunto a `/mnt/project-files/LEGGIMI.md`. Il perché delle scelte importanti si scrive in una riga accanto alla scelta (L7).

## Lavorare in modo economico

L'autore vuole il massimo risultato con il minimo consumo. Quindi:

- **Leggi solo quello che serve**: cerca con grep e leggi le righe utili, non i file interi. Il DEVLOG da 2,5 MB non si apre mai per intero.
- **Output corti**: lancia test e prove salvando il log su file e mostra solo l'esito (`tail`, `grep`).
- **Il modello giusto per ogni agente**: `qa-godot` e `prestazioni-telefono` girano su Haiku (comandi e numeri); `guardiano-bibbia`, `voce-dei-personaggi`, `regista-battaglia` e `marketing-odispel` su Sonnet (giudizio e scrittura). Il modello principale coordina e decide.
- **Sotto-agenti solo quando conviene**: un compito piccolo si fa direttamente. Per una funzione con più passi usa `superpowers:writing-plans` e poi `superpowers:subagent-driven-development`; `agent-army` solo per lavori con 6 o più parti indipendenti (es. rivedere tutti i dialoghi capitolo per capitolo). Per decisioni importanti, `devil-advocate` o `agentic-council` prima di chiedere all'autore.
- **Niente crediti senza il via**: i generatori di immagini, video e musica collegati (abracadabrax, ManyMotions, lurkapi) spendono i crediti dell'autore: si preparano, ma si genera solo quando lui dice «genera».
- Cosa non funziona e cosa serve per sbloccarlo: `/mnt/project-files/odispel/produzione/STRUMENTI_DA_SBLOCCARE.txt`.
