# Mappa dei branch

Stato al 19 ottobre 2026: 39 branch. «Contenuto in» vuol dire che ogni commit del branch è già dentro l'altro branch (verificato con `git merge-base --is-ancestor`): cancellarlo non perde niente.

Niente è stato cancellato. La pulizia è una proposta e la decide l'autore (regola L5 della Bibbia di lavoro: «si sperimenta su un branch, si decide, poi si unisce o si archivia»).

## I branch principali

| Branch | Cosa c'è | Ultimo commit |
|---|---|---|
| `claude/v3-prologo` | **V3, la versione ufficiale.** JRPG 3D story-driven, atto 1. Progetto Godot a sé (branch orfano, senza storia comune con gli altri) | 19/10 · 0.33.1 |
| `claude/battaglia-v2` | **V2.** Gacha 2D a turni, battaglia nuova, mappa 2.5D. Contiene tutta la storia della V1 | 18/10 · 0.29.1 |
| `ccr-a679f7a6-usvtop` | **Action RPG 3D**, cartella `odispel_action/`. Fase B: movimento e telecamera | 19/10 |
| `main` | **V1** dell'11 ottobre (co-op online). Già contenuto in `claude/battaglia-v2` | 11/10 |

## Lavoro in corso

| Branch | Cosa c'è | Stato |
|---|---|---|
| `claude/project-thread-nf3fqw` | V3 0.33.x: guardia a tempo, pause brevi, avviso di aggiornamento | PR #4 unita in `claude/v3-prologo`; il branch ha commit nuovi dopo l'unione |
| `claude/project-thread-252zrd` | `docs/SINTESI_ODISPEL.md` | mai unito |
| `claude/project-thread-8wnexq` | questo riordino (README, mappa dei branch, `docs/ip/`) | in revisione |

## Prove mai decise

Non sono contenute in nessun altro branch: cancellarle perde il loro lavoro.

| Branch | Cosa c'è | Proposta |
|---|---|---|
| `claude/battaglia-v2-hud-prova` | HUD variante A (squadra più leggibile), 1 file | da decidere: unire in V2 o archiviare |
| `claude/battaglia-v2-energia-prova` | prova energia sui 4 tasti, scartata | archiviare |
| `claude/battaglia-v2-audit` | audit del combattimento V2, congelato apposta | tenere come riferimento o archiviare |
| `claude/docs-game-director` | `docs/HANDOFF_GAME_DIRECTOR.md` e `docs/PROMPT_CHATGPT_GAME_DIRECTOR.md` | portare i due documenti in V2 o archiviare |
| `claude/handoff-doc` | `docs/HANDOFF.md` del 12 ottobre | archiviare |
| `ccr-407f2fe7-q106uk` | 4 correzioni alla V1 fatte sopra `main` per errore (mai provate) | archiviare |

## Già contenuti in altri (si possono archiviare senza perdere niente)

**In `claude/v3-prologo`**

| Branch | Cosa era |
|---|---|
| `claude/v3-prologo-correzioni` | correzioni 0.31.2 |
| `claude/project-thread-i5p0lt` | PR #1: climax, menu pausa, voci (unita) |
| `claude/project-thread-t0ajvk` | PR #3: guardia a tempo (unita) |

**In `claude/battaglia-v2`**

| Branch | Data | Cosa era |
|---|---|---|
| `claude/android-apk` | 12/10 | esportazione Android |
| `claude/arte-e-dialoghi` | 12/10 | grafiche sostituibili, dialoghi alla Persona |
| `claude/boss-e-difficolta` | 12/10 | boss Semaforo e Tombino, difficoltà |
| `claude/exe-windows` | 12/10 | esportazione Windows |
| `claude/fazioni-assegnate` | 12/10 | fazioni sugli operatori |
| `claude/fazioni-fondamenta` | 12/10 | fondamenta delle fazioni |
| `claude/feedback-e-qol` | 12/10 | feedback, caricamento, comodità |
| `claude/libracorp` | 12/10 | splash, note 0.7.0 |
| `claude/lobby-e-restyle` | 12/10 | lobby condivisa, tema grafico |
| `claude/menu-contenuti-uscita` | 12/10 | guida all'uscita |
| `claude/mondo-e-dottrine` | 12/10 | dottrine |
| `claude/ottimizzazione-completa` | 12/10 | ottimizzazioni |
| `claude/pulizia-ottimizzazione` | 12/10 | pulizia |
| `claude/rifinitura` | 12/10 | versione 0.6.0 |
| `claude/splash-logo` | 12/10 | splash col logo |
| `claude/touch-e-guida` | 12/10 | touch e guida al reclutamento |
| `claude/turn-relay` | 12/10 | server TURN |
| `claude/tutorial-e-audio` | 12/10 | tutorial e audio |
| `claude/battaglia-chiara` | 16/10 | 0.26.2 |
| `claude/ripristino-pre-battaglia-v2` | 16/10 | segnalibro prima della V2 |
| `claude/battaglia-v2-baseline-0.28.1` | 17/10 | segnalibro 0.28.1 |
| `claude/battaglia-v2-squadra` | 17/10 | segnalibro 0.28.1 |
| `claude/battaglia-v2-ulti-nera` | 17/10 | prova ulti |

## Come archiviare senza perdere niente

Il modo proposto: per ogni branch si crea un tag `archivio/<nome>` sullo stesso commit, poi si cancella il branch. Il tag tiene il lavoro per sempre e si può ritrasformare in branch quando serve:

```
git tag archivio/battaglia-v2-energia-prova origin/claude/battaglia-v2-energia-prova
git push origin archivio/battaglia-v2-energia-prova
git push origin --delete claude/battaglia-v2-energia-prova
# per riprenderlo: git checkout -b claude/battaglia-v2-energia-prova archivio/battaglia-v2-energia-prova
```

## Cosa diventa `main`

Oggi `main` è la V1 e non rappresenta niente di attuale. Siccome la V3 è un progetto a sé (branch orfano), non si può unire in `main` con un merge normale. Le strade possibili:

1. **Cambiare il branch predefinito** del repository in `claude/v3-prologo` (Settings → General → Default branch). Non cancella niente e si può tornare indietro.
2. Rinominare `main` in `v1` e `claude/v3-prologo` in `main`. Più pulito, ma tutti i link e i workflow che nominano i branch vanno aggiornati.
3. Lasciare `main` com'è, con il README che spiega dove sta ogni gioco (quello che fa questa PR).
