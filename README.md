# ODISPEL

ODISPEL è un universo narrativo di Gianluca: videogiochi, un manga, un gioco di carte. È ambientato in una città di oggi, dove la magia si disegna come luce e la ferita di una persona può diventare un mostro.

> **Se non coinvolge, non c'è. Se c'è, è fatto con cura, con stile e con intenzione.**

## Dove sta cosa

Ogni gioco vive sul suo branch. Questo branch, `main`, contiene la **V1** dell'11 ottobre 2026 (le origini) ed è tenuto come archivio.

| Cosa | Branch | Stato |
|---|---|---|
| **V3 · OFFICIAL DEMO ODISPEL**, la versione ufficiale: JRPG 3D story-driven, atto 1 | [`claude/v3-prologo`](https://github.com/Gialloo/ODISPEL/tree/claude/v3-prologo) | 0.33.1, su itch |
| V2: gacha 2D a turni, battaglia nuova, mappa esplorabile | [`claude/battaglia-v2`](https://github.com/Gialloo/ODISPEL/tree/claude/battaglia-v2) | 0.29.1, archivio di meccaniche |
| Action RPG 3D (cartella `odispel_action/`) | [`ccr-a679f7a6-usvtop`](https://github.com/Gialloo/ODISPEL/tree/ccr-a679f7a6-usvtop) | fase B, in sviluppo |
| V1: battaglia co-op online contro un boss | `main` (questo) | archivio |

La mappa completa dei 39 branch, con quali si possono archiviare, è in [docs/MAPPA_BRANCH.md](docs/MAPPA_BRANCH.md).

## L'universo

I documenti dell'IP (canone, regole di lavoro, lore del manga, stile visivo) sono copiati in [docs/ip/](docs/ip/LEGGIMI.md). Da dove partire:

1. [ODISPEL_TUTTO.md](docs/ip/ODISPEL_TUTTO.md): l'universo e il canone in un file solo.
2. [BIBBIA_DI_LAVORO.md](docs/ip/BIBBIA_DI_LAVORO.md): le regole dell'autore. Chiunque lavori su ODISPEL, persona o IA, le legge prima di aggiungere qualcosa.
3. [PANORAMICA.md](docs/ip/PANORAMICA.md): versioni, branch, cosa è aperto.

## Documenti di ogni gioco

| Gioco | Documenti principali |
|---|---|
| V3 | `README.md`, `docs/STORIA.md`, `docs/STILE_VISIVO.md` (vince su tutto lo stile), `docs/CHANGELOG.md`, `docs/HANDOFF_*.md` |
| V2 | `docs/HANDOFF_CLAUDE_0.28.11.md` (il più completo), `docs/MONDO.md`, `docs/DOTTRINE.md`, `docs/ART_BIBLE.md`, `docs/BATTAGLIA_V2_PIANO.md`, `docs/GUIDA_ITCH.md` |
| Action RPG | `odispel_action/README.md` |

## La V1 su questo branch

Progetto Godot 4.7: battaglia a turni contro un boss in co-op e PvP via WebRTC, con un server di signaling in `odispel-signaling/`.

| Cartella | Cosa c'è |
|---|---|
| `scenes/`, `scripts/`, `shaders/` | il gioco |
| `data/` | dati degli incontri |
| `addons/` | plugin WebRTC |
| `odispel-signaling/` | server Node per mettere in contatto i giocatori |
| `tests/` | test automatici |
| `tools/` | script di prova (simulazione della battaglia, schermate, controlli di rete) |

Per aprirlo: Godot 4.7, «Importa», scegliere `project.godot`.
