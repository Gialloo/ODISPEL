# ODISPEL: tutto il lavoro fatto finora con Claude

Stato al 19 ottobre 2026, seconda versione. Fonti: tutti i branch di `github.com/Gialloo/ODISPEL`, le quattro sessioni di Claude Code, le otto chat claude.ai dell'esportazione ([LEGGIMI](/mnt/project-files/odispel/export/LEGGIMI.md)) e gli artifact del tuo account. Nessun file del repository è stato modificato per scrivere questo documento.

Questo file è la **mappa del lavoro** (dove sta cosa, in che stato, cosa manca). L'universo, il manga e il gioco di carte sono raccontati in [ODISPEL_TUTTO.md](/mnt/project-files/odispel/ODISPEL_TUTTO.md).

## In breve

- **Le linee di lavoro sono sette:** quattro giochi in Godot (V1, V2, V3, Action RPG), il manga di Mada (LORE MONDO 2), il gioco di carte (VTCG, solo concept) e Ashen Vow (un'interfaccia e un mini gioco web, usati come riferimento di stile).
- **Nessun gioco è mai stato unito a `main`**, che è fermo all'11 ottobre (V1). Ogni gioco vive sul suo branch.
- **La versione ufficiale è la V3** (`claude/v3-prologo`, 0.32.0, "OFFICIAL DEMO ODISPEL"). La V1 e la V2 sono esperimenti da cui prendere le meccaniche.
- **La chiave che firma gli APK della V3** (`/root/odispel_v3_key.pem`) esisteva solo nel container della chat V3, che è temporaneo. Senza quella chiave, il prossimo APK V3 non si installerà sopra quello vecchio: i tester dovranno disinstallare una volta.
- **Sicurezza:** nella chat DEVLOG hai incollato in chiaro la password della pagina itch e le credenziali TURN di Metered. Conviene cambiarle entrambe.
- **LORE MONDO 2 c'è**, ma non nel repository: è un documento Claude Docs ([LORE MONDO 2 · Odispel e Mada](https://claude.ai/artifact/CagAtLDP7jBZqTnfQ4e2f7), copia in testo in [export/documenti](/mnt/project-files/odispel/export/documenti/LORE_MONDO_2_Odispel_e_Mada.md)). È rimasto indietro rispetto alla V3: usa ancora Ferri, Zecca e un Kairos senza nome.
- L'APK dell'action RPG, che prima esisteva solo in chat, ora è salvato in [apk/](/mnt/project-files/odispel/apk/ODISPEL_Action_faseB_debug.apk).

## 1. V3 · OFFICIAL DEMO ODISPEL (la versione ufficiale)

| | |
|---|---|
| Dove | branch `claude/v3-prologo`, **orfano** (non ha storia in comune con la V2, è un progetto Godot a sé) |
| Cos'è | JRPG a turni in 3D, racconto alla Persona, atto 1 completo (prologo, 4 capitoli, finale "Il varco", capitolo 5 "La tangenziale") |
| Versione | **0.32.0** (19 ottobre), pubblicata su itch `boomeranza/odispel`, canali `android-v3` e `windows-v3` |
| Personaggi | Lance (ex Ferri), Nox, Rio (ex Zecca), Saul, Echo (il Kairos). Inseguitori: Astrid (LibraCorp), Strix (Civette) |
| Documenti | `README.md`, `docs/STORIA.md` (storia e seguito), `docs/STILE_VISIVO.md` (vince su tutto: urbano di oggi, niente look medievale), `docs/CHANGELOG.md`, `docs/HANDOFF_PERSONAGGI_3D.md`, `docs/HANDOFF_PORTRAIT.md`, `docs/HANDOFF_PROLOGO_3D.md`, `docs/concept/`, `docs/ref_personaggi/` |
| Testi | `data/dialoghi_atto1.json`, generato da `tools/gen_dialoghi.py` (si corregge lo script, poi si rigenera); struttura in `data/atto1.json` |
| Pubblicazione | `.github/workflows/itch.yml`: parte **solo** se nel push cambiano l'APK o lo zip in `releases/`. Un push di solo codice non pubblica niente. Serve il segreto GitHub `ITCH_API_KEY` |
| Artifact | [Handoff stile visivo](https://claude.ai/code/artifact/2402836b-1f57-4916-b5b7-e4be7141aea1) |

`claude/v3-prologo-correzioni` è già contenuto in `claude/v3-prologo` (le correzioni della 0.31.2): si può cancellare.

**Da fare / aperto**
- Le "rifiniture" che avevi detto di voler mandare dopo la 0.32.0 non sono mai arrivate.
- Mai provata su un telefono vero: prestazioni, telecamera rotta, ritmo delle scene lunghe (il varco supera le 40 battute).
- Ritratti e modelli sono tutti provvisori. Pipeline prevista: TRELLIS.2 → FBX → Mixamo → Godot, a partire da Lance in posa A.
- Riprendendo a metà di un'area si riparte dall'inizio dell'area e si perdono gli indizi trovati.
- L'avviso del boss segreto (L'Osservatore) può nominare un bersaglio diverso da quello colpito.
- Il capitolo 5 è dentro l'atto 1; Claude aveva proposto di spostarlo.
- L'atto 2 (caccia al Committente) è solo pianificato in `docs/STORIA.md`.
- **Chiave di firma**: va rigenerata e conservata (consiglio: come segreto GitHub o in un posto tuo), accettando che i tester disinstallino una volta.

## 2. V2 · "Test V2" (battaglia nuova e mappa esplorabile)

| | |
|---|---|
| Dove | branch `claude/battaglia-v2` (contiene tutta la storia V1 e V2) |
| Cos'è | un gacha a turni 2D completo, più il "Test V2": battaglia nuova (HUD a pennellate, ruota A-S-U-G, turni per velocità, ultimate) e mappa 2.5D in stile Gorillaz / TWEWY con 8 zone, 47 scoperte e sorveglianti col "!" alla Pokémon |
| Modalità | storia (seconda stagione con Dafne, 10 capitoli fino a "Incubo"), reclutamento e rank, PvP con pick & ban, Ciclo infinito, Spedizione (roguelike co-op alla Chaos Zero Nightmare), difficoltà ABISSO, titoli dell'account, tutorial, profilo, lobby e chat |
| Versione | **0.29.1** (18 ottobre), itch canali `android-mobile` e `windows-pc` (workflow `.github/workflows/itch_v2test.yml`) |
| Personaggi | 24 operatori e 18 boss. Kira è la mascotte (leggendaria); 10 operatori (Moro, Vesper, Nami, Oriel, Silex, Yuna, Rhea, Flux, Cato, Lyra) sono stati disegnati da ChatGPT. Arte vera solo per Kira e Dafne; la prossima era Angela. Testi in `scripts/battle/lore.gd` (bozza) |
| Documenti | `docs/HANDOFF_CLAUDE_0.28.11.md` (il più completo), `docs/MONDO.md`, `docs/DOTTRINE.md`, `docs/ART_BIBLE.md`, `docs/BATTAGLIA_V2_PIANO.md`, `docs/GUIDA_ITCH.md`, `docs/TURN.md`, `docs/ChatGPT/` (codice spezzato per ChatGPT), handoff per Gemini, Copilot e arte IA |
| Server | signaling Node su Render (`wss://odispel-signaling.onrender.com`), TURN Metered con credenziali in `config/turn.cfg` (fuori da git) |

**Branch di prova della V2**
- `battaglia-v2-hud-prova`: variante A dell'HUD (squadra più leggibile), **mai confermata né scartata**.
- `battaglia-v2-energia-prova`: prova scartata, da cancellare.
- `battaglia-v2-audit`: audit in sola lettura del combattimento, congelato.
- `docs-game-director`: handoff per il "Game Director" e prompt per ChatGPT (solo documenti).
- `battaglia-v2-baseline-0.28.1`, `battaglia-v2-squadra`, `battaglia-v2-ulti-nera`, `battaglia-chiara`, `ripristino-pre-battaglia-v2`: già contenuti in `battaglia-v2`, sono solo segnalibri.

**Da fare / aperto**
- Crash segnalato sul telefono all'incontro col "!" (Nesso): mai riprodotto, le correzioni 0.28.9 e 0.28.10 sono ipotesi non confermate.
- Ultima domanda rimasta senza risposta: fare l'attacco in mappa alla Star Rail con un piccolo vantaggio a inizio battaglia?
- Altre decisioni in sospeso: dove mettere la panchina, se AUTO e velocità si ricordano, le due regole dei turni (priorità ignorata, effetti dopo il boss), unire o no battaglia classica e V2, la telecamera della mappa.
- Tutti gli incontri usano il Distributore, unico boss disegnato; niente audio né salvataggio sulla mappa; V2 non collegata alla progressione.
- APK firmati con la chiave di debug. Il 17 ottobre volevi che i file non sembrassero pericolosi ai tuoi amici: la chiave di rilascio non toglie quegli avvisi. Su Android servirebbe il Play Store (test chiuso), su Windows un certificato di firma del codice a pagamento. Spiegazione per gli amici in `docs/WINDOWS_AVVISO.md` su `claude/battaglia-v2`.
- Ancora da portare dallo stile Ashen Vow: i font (Big Shoulders, Cormorant, IBM Plex Mono) e il kanji.
- Telefono di prova: Samsung SM-A075F. Il server su Render (piano gratuito) si addormenta e impiega fino a un minuto a ripartire.

## 3. V1 · co-op online (le origini)

| | |
|---|---|
| Dove | `main` (11 ottobre) e i branch del 12 ottobre: `lobby-e-restyle`, `boss-e-difficolta`, `feedback-e-qol`, `tutorial-e-audio`, `arte-e-dialoghi`, `menu-contenuti-uscita`, `exe-windows`, `android-apk`, `touch-e-guida`, `pulizia-ottimizzazione`, `ottimizzazione-completa`, `splash-logo`, `rifinitura`, `fazioni-fondamenta`, `fazioni-assegnate`, `mondo-e-dottrine`, `libracorp`, `turn-relay` |
| Cos'è | battaglia a turni contro un boss in co-op e PvP via WebRTC |
| Stato | tutti questi branch sono già dentro `claude/battaglia-v2`: nessun lavoro rischia di perdersi. Fanno eccezione `handoff-doc` (un solo documento, `docs/HANDOFF.md`) e `ccr-407f2fe7-q106uk` qui sotto |

`ccr-407f2fe7-q106uk` (18 ottobre): 4 correzioni fatte **sopra `main`** da una chat che aveva scambiato il codice V1 per la V3. Non sono mai state provate in Godot. Correggono la battaglia classica (blocco a squadra KO, disconnessioni), il salvataggio della collezione e il server di signaling (heartbeat). Valgono solo se un giorno riprendi la V1/V2; altrimenti si può archiviare.

## 4. ODISPEL Action (action RPG 3D, nuovo)

| | |
|---|---|
| Dove | branch `ccr-a679f7a6-usvtop`, cartella `odispel_action/` (progetto Godot separato; il gioco originale lo ignora) |
| Cos'è | action RPG in terza persona con le sensazioni di Kingdom Hearts 1, pensato per telefono e PC, pronto per il co-op online in futuro |
| Stato | **fase B fatta**: corsa, salto, schivata, telecamera, comandi touch, arena di prova nel parcheggio col Distributore spento. 79 test automatici passano. Personaggio = capsula provvisoria |
| Documenti | `odispel_action/README.md`. L'audit iniziale (fase A) esiste solo come risposta in chat |
| APK | [ODISPEL_Action_faseB_debug.apk](/mnt/project-files/odispel/apk/ODISPEL_Action_faseB_debug.apk) (28 MB), mai provato su un telefono |

**Piano a fasi:** A audit ✓ · B movimento e telecamera ✓ · C combattimento e aggancio del bersaglio · D nemico e piccolo boss · E esperienza mobile su telefono vero · F co-op online a due · G vertical slice. La fase B aspetta il tuo parere (FPS, joystick, telecamera, comodità dei tasti) prima della C.

## 5. Manga di Mada e IP (LORE MONDO 2)

| | |
|---|---|
| Dove | [LORE MONDO 2](https://claude.ai/artifact/CagAtLDP7jBZqTnfQ4e2f7) (Claude Docs), nato nella chat "Mada's character arc" del 18 ottobre. Non è nel repository |
| Cos'è | la lore del manga: Mada, 16-17 anni, "Black Child" che porta le 72 legioni infernali; uno shonen al contrario in 10 archi. Il racconto completo è in [ODISPEL_TUTTO.md](/mnt/project-files/odispel/ODISPEL_TUTTO.md) |
| Altri documenti | [Bibbia del mondo](https://claude.ai/artifact/EN32BhnXRwNPuGbzbcRVx2) (basata sulla V3), `docs/MONDO.md` e `docs/DOTTRINE.md` su `claude/battaglia-v2` (lore della V2), `docs/STORIA.md` su `claude/v3-prologo` |

**Decisioni già prese (chat 04)**
- Ogni media racconta un punto di vista diverso e nessuno racconta tutto.
- Il gioco è una storia a parte, in un "paese lontano": Mada non compare.
- Rondini (la città di Mada, nel manga) e Civette (la città del gioco) esistono entrambe; gli operatori V2 come Kira vanno spostati nelle Civette.
- La LibraCorp del gioco è quella dopo la redenzione.
- L'operatore della Centrale (V2) è stato sostituito apposta da un Kairos personaggio, Echo.
- Niente gacha che riracconta il manga, niente frammenti di profezia da collezionare, niente gioco di carte dentro il gioco.

**Da fare / aperto**
- LORE MONDO 2 va allineato alla V3 0.32.0 (Lance, Rio, Echo, Astrid, Strix, il tradimento a fine atto 1). "Rio" e "Strix" li ha scelti Claude: non li hai mai confermati esplicitamente.
- Domande rimaste senza risposta: cosa sia l'"altro" del Black Child; chi ha detto a Mada che è "la chiave"; il nome definitivo di Neden (proposti Odis, Primordo, Velàr); come l'anno di prova si incastra nei 3 anni di scuola; nomi della città e del paese del gioco; dove stanno giochi e carte sulla linea del tempo; se il manga è la fonte principale o una storia parallela.

## 6. Gioco di carte · ODISPEL VTCG

| | |
|---|---|
| Dove | solo nella chat "ODISPEL card game optimization" del 14 ottobre ([testo](/mnt/project-files/odispel/export/conversazioni/06_gioco_di_carte.md)) |
| Cos'è | un TCG virtuale tipo Shadowverse, con un Leader che evolve (alla Vanguard) e la Pila del Destino (10 carte). Fase di pesca: 2 Mana, 2 carte oppure 1 + 1 |
| Stato | concept 0.1. Claude ha analizzato il documento e proposto le carte Destino con un "Presagio" |

**Da fare / aperto:** la prima decisione che Claude ti ha chiesto non ha ancora risposta: il Leader è un avatar con punti vita (Shadowverse) o un combattente che attacca e subisce (Vanguard)? Manca anche la condizione di vittoria. La versione 0.2 del documento non è mai stata scritta.

## 7. Ashen Vow (riferimento di stile)

Due artifact del 17 ottobre: [Ashen Vow Interface](https://claude.ai/artifact/LA6d8Pj4fjRiSi92kaZsYF), una schermata di selezione in stile anime, e [Ashen Vow Wilds](https://claude.ai/artifact/C8dWgUKy9GQDdgHtrVXnNG), un piccolo open world web giocabile. I personaggi (Renka, Shion, Oboro, Tsubaki) non sono di ODISPEL. Lo stile è stato portato nella schermata Squadra della V2.

## 8. Stile visivo

- [Handoff stile visivo dei personaggi](https://claude.ai/artifact/R22DKVGaeRN9PqzVyYBRTb): stile Kingdom Hearts + primi Final Fantasy con classi medievali. **Superato** la sera del 18 («sembrano usciti dal medioevo»), ma è l'unico posto con le tue 12 illustrazioni di riferimento.
- [V3 · Handoff stile visivo](https://claude.ai/artifact/5SuWxcmyLJuA57m1yRwPMJ) e `docs/STILE_VISIVO.md` su `claude/v3-prologo`: la direzione valida, urbana di oggi.
- Modelli 3D: TRELLIS.2 + Mixamo. Meshy è stato scartato perché a pagamento (un modello di prova è nel tuo account Meshy), Hunyuan3D per la licenza europea.

## 9. Lavoro in corso oggi in questo progetto

- `claude/project-thread-i5p0lt` (pull request #1): rifiniture della V3 sopra la 0.32.0 (climax, menu pausa, voci di Saul e Rio).
- `claude/project-thread-252zrd`: `docs/SINTESI_ODISPEL.md`.
- Nella cartella del progetto: [ODISPEL_TUTTO.md](/mnt/project-files/odispel/ODISPEL_TUTTO.md), [SINTESI_ODISPEL.md](/mnt/project-files/odispel/SINTESI_ODISPEL.md), [BIBBIA_DI_LAVORO.md](/mnt/project-files/odispel/BIBBIA_DI_LAVORO.md), [PERSONAGGI_E_UMORISMO.md](/mnt/project-files/odispel/PERSONAGGI_E_UMORISMO.md).

## 10. Cose che esistono solo nelle chat

| Cosa | Chat | Recuperabile? |
|---|---|---|
| Chiave di firma V3 `odispel_v3_key.pem` | V3 | no, va rifatta |
| Gioco di carte VTCG (concept 0.1 e analisi) | Gioco di carte | sì, è nell'esportazione |
| Screenshot di riferimento e silhouette dello stile | IP history stile | no |
| `ODISPEL_HANDOFF.md` del 12 ottobre, file per Copilot (`00_contesto.txt`…), `prepare_art.py`, `ODISPEL-INSTALLA.bat`, confronto Godot/Unity/Unreal | DEVLOG | solo rileggendo la chat |
| Audit fase A dell'action RPG | Action RPG | solo rileggendo la chat |
| APK e zip di ogni versione V3 | V3 | sì, l'ultima è in `releases/` |
| Screenshot di prova (V2 e V3) | V2, V3 | no, erano in cartelle temporanee |
| `HANDOVER_0.28.4_PER_CHATGPT.md`, `REPORT_AUDIT_0.28.4_ANDROID_E_G.md` | V2 | solo rileggendo la chat |
| Risposta di ChatGPT al feedback degli amici (`attachment.txt`) | V2 | solo rileggendo la chat |

## 11. Pulizia possibile (non fatta, decidi tu)

- Cancellare i branch già contenuti in altri: `v3-prologo-correzioni`, `battaglia-v2-energia-prova` (scartato), e i segnalibri V1/V2 del punto 3.
- Decidere cosa diventa `main`: oggi è la V1 dell'11 ottobre e non rappresenta niente di attuale. Un'opzione è tenere V3 come principale e conservare V2 e Action come branch.
- I file APK e zip committati in `releases/` (circa 36-48 MB l'uno, decine di versioni nella storia V2) appesantiscono molto il repository.

## Le fonti

**Sessioni di Claude Code**

| Sessione | Date | Cosa |
|---|---|---|
| `session_017MDq3tJoDSmxmKKpEz1CJ9` (= chat "ODISPEL DEVLOG") | 10-18 ottobre | V1, fazioni, V2, mappa, itch, handoff per altre IA (301 commit) |
| `session_013pxjV93SZPgdmJUFeR14DV` (= chat "Gioco 3D story-driven V3") | 18-19 ottobre | V3 dalla 0.29.0 alla 0.32.0 |
| "ODISPEL v3 analysis and optimization" (`session_01ML6rrcFYfJzKjsPw179YQe`) | 18 ottobre | correzioni su `main` e su V3 |
| "ODISPEL action RPG" (`session_01ER5grcesKXMffpE5R7Zg4w`) | 19 ottobre | action RPG fasi A e B |

**Chat claude.ai** (testo in [export/conversazioni](/mnt/project-files/odispel/export/LEGGIMI.md)): DEVLOG, V3 story-driven, IP history e stile, Odispel visual style, Mada's character arc, Anime UI (Ashen Vow), card game, Unire chat.
