# Ritratti 2D dell'HUD di battaglia · guida Procreate

HUD col ritratto (riferimento dell'autore, 2/11/2026, stile remake di Persona 1). Il gioco oggi usa come **segnaposto** i
mezzobusti 3D `assets/portraits/<id>_neutro.png`; appena metti i file qui sotto, il gioco li usa da solo (nessun codice da toccare).

Personaggi e nomi dei file (gli id del codice: `ferri` = **Lance**, `zecca` = **Rio**):

| Personaggio | Ritratto grande | Volto piccolo |
|---|---|---|
| Lance | `ferri_hud.png` | `ferri_volto.png` |
| Rio | `zecca_hud.png` | `zecca_volto.png` |
| Nox | `nox_hud.png` | `nox_volto.png` |
| Saul | `saul_hud.png` | `saul_volto.png` |

Cartella: `assets/portraits/hud/` (oppure mandali nel thread e li metto io).

## 1. Ritratto grande (in basso a sinistra, con i comandi attorno)

**Impostazioni della tela** (Procreate: Galleria → `+` → icona tela personalizzata):

- Dimensioni: **1536 × 2048 px** (3:4, verticale). Sul telefono il ritratto è grande circa 530 × 705 px: la tela ha più del doppio, resta nitido anche su schermi 2K.
- DPI: **300** (al gioco contano solo i pixel; 300 dà pennelli più fini).
- Profilo colore: **RGB · sRGB IEC61966-2.1**, 8 bit (Display P3 sbiadisce i colori nel gioco).
- Sfondo: **trasparente**, esportato in **PNG**.

**Inquadratura: mezzobusto** (dalla testa a metà petto / vita), niente figura intera e niente solo faccia.

**Posa**: di tre quarti, girato verso **destra** (verso il nemico), **spostato nella metà destra** della tela. Le scritte dei
comandi stanno a sinistra e in basso, quindi:

| Zona (px sulla tela 1536×2048) | Cosa ci va |
|---|---|
| x 860–1460, y 250–1125 | **Volto**: testa e occhi tutti qui dentro |
| x 0–840, y 615–1435 | Colonna dei comandi (ULTIMATE, ABILITÀ, ATTACCO): spalla e braccio vanno bene, **niente volto né mani importanti** |
| x 800–1500, y 1435–1700 | GUARDIA: petto/giacca, niente dettagli che devono leggersi |
| x 0–1000, y 1780–2048 | Nome grande del personaggio |
| y 0–40 | Margine: i capelli possono arrivarci, non oltre |

Una mano o un oggetto che racconta il personaggio (regola U20) va a destra, sotto il volto (x > 860).
Stile: contorno d'inchiostro spesso (10–14 px, `#120a1c`), colori piatti con 1–2 toni d'ombra, come i personaggi del gioco.
**Niente sfondo, niente ombra portata, niente bagliore attorno**: lastra colorata, ombra e animazione le fa il gioco.

**Modello**: `GUIDA_ritratto_hud_1536x2048.png` (nella cartella del progetto, `odispel/v3/hud_ritratti/`). In Procreate:
Azioni (chiave inglese) → Aggiungi → Inserisci un file → scegli il modello, livello in cima, opacità 30%. Lo nascondi prima di esportare.

## 2. Volto piccolo (fila della squadra e colonna ORDINE)

- **512 × 512 px**, 300 DPI, sRGB, sfondo trasparente, PNG.
- Inquadratura: **primo piano** (testa e collo), viso al centro, guardando in camera o appena a destra.
- **Occhi all'altezza y ≈ 200 px**: la colonna ORDINE ritaglia la striscia y 90–305 (gli occhi).
- Modello: `GUIDA_volto_512.png`.

Se non lo fai, il gioco ritaglia il volto dal ritratto segnaposto: va bene per provare.

## 3. Perché trasparente e non bianco, nero o verde

- **Trasparente (PNG)**: il personaggio si appoggia sulla lastra colorata del gioco senza bordi. È la scelta giusta.
- Bianco o nero: resta un alone attorno ai capelli e alle linee sottili; andrebbe scontornato a mano.
- Verde (chroma key): serve per i video, non per le immagini; lascia riflessi verdi sui bordi.

## 4. Come esportare in PNG trasparente da Procreate

1. Pannello **Livelli** → in fondo, livello **Colore di sfondo** → togli la spunta (diventa a scacchi).
2. Nascondi il livello del modello guida.
3. **Azioni** (chiave inglese) → **Condividi** → sotto "Condividi immagine" scegli **PNG** (non JPEG: il JPEG non ha la trasparenza).
4. Salva in File o mandalo nel thread col nome della tabella (es. `zecca_hud.png`).

Controllo veloce: aperto sul telefono, attorno al personaggio deve vedersi lo sfondo dell'app (o la scacchiera), non il bianco.
