# GUIDA ALLE GRAFICHE DI ODISPEL

Il gioco usa dei segnaposto disegnati dal codice. Per sostituirne uno basta mettere un
**PNG con trasparenza e il nome giusto** in una cartella `art`. Niente codice da toccare.
Dove manca un file resta il segnaposto, quindi puoi aggiungere le immagini una alla volta.

## Dove mettere i file
Il gioco cerca in quest'ordine (vince la prima cartella che ha il file):
1. `art/` accanto all'eseguibile del gioco
2. la cartella dati del gioco (da Impostazioni > APRI CARTELLA GRAFICHE: la crea con le sottocartelle giuste)
3. `art/` nella cartella del progetto (durante lo sviluppo)

Dopo aver cambiato un file: Impostazioni > RICARICA GRAFICHE (oppure riavvia).
Impostazioni mostra anche "GRAFICHE TROVATE x / y".

## Nomi e misure consigliate
Le misure sono solo indicative: il gioco adatta l'immagine mantenendo le proporzioni.
Personaggi (`<id>` = kira, dax, elle, bruno, ...):

| File | Uso | Misura consigliata |
|---|---|---|
| `characters/<id>/neutral.png` | ritratto nei dialoghi (obbligatorio per avere i ritratti) | 1000x1400, busto/figura, ancorato in basso |
| `characters/<id>/happy.png` `angry.png` `sad.png` `surprised.png` `hurt.png` | altre espressioni (se manca, usa neutral) | come neutral |
| `characters/<id>/splash.png` | scheda operatore, reclutamento | 1200x1600 |
| `characters/<id>/cutin.png` | sequenza dell'ultimate | 1600x900, volto/mezzo busto |
| `characters/<id>/icon.png` | liste e lobby | 256x256 |
| `characters/<id>/battle.png` | figura in battaglia (alta ~230 px nel gioco) | 480x640, piedi sul bordo basso |

Boss (`<boss>` = distributore, semaforo, tombino, cabina):

| File | Uso | Misura |
|---|---|---|
| `bosses/<boss>/battle.png` | boss in campo | 1000x1000, piedi sul bordo basso |
| `bosses/<boss>/hurt.png` | boss colpito (facoltativo) | come battle |
| `bosses/<boss>/portrait.png` | dialoghi (se manca usa battle) | 1000x1400 |

Sfondi:
- `backgrounds/battle/layer_1.png` ... `layer_4.png`: strati dal piu' lontano (1) al piu' vicino (4), 1400x800. Si muovono con la parallasse. Usane da 1 a 4.
- `backgrounds/<boss>/layer_N.png`: come sopra ma solo per quel boss (ha la precedenza).
- `backgrounds/hub.png`: sfondo dell'hub, 1920x1080.
- `logo.png`: logo dell'hub (se manca c'e' quello disegnato dal codice), ~1000x280, sfondo trasparente.
- `backgrounds/dialogue/<nome>.png`: sfondi dei dialoghi, richiamati con `@bg nome`. 1920x1080.

## Personaggi nuovi
Il nome della cartella e' l'id del personaggio (lo stesso usato nel gioco).

## Stile e scheda dei personaggi (per chi disegna)
**Stile voluto**: anime / visual novel giapponese a colori. Tratto pulito con contorni a inchiostro, ombre a colore piatto
(cel shading), pochi dettagli ma significativi, luce da sinistra. **L'attenzione e' sugli occhi**: grandi, lucidi, con riflessi,
molto espressivi. Riferimenti: Persona, Kingdom Hearts, i personaggi di Final Fantasy disegnati da Amano. Personaggio in grande,
**senza sfondo** (PNG trasparente).

Il colore del personaggio (la sua "strategia") guida la tavolozza: capelli, accessori e iride nella tinta del colore.

| Colore | Tinta guida | Strategia (carattere da trasmettere) |
|---|---|---|
| rosso | caldo, vivo | STR: diretto, energico, sguardo deciso |
| giallo | oro, luminoso | PSY: premuroso, sostegno, sguardo gentile |
| viola | viola/lilla | INT: analitico, sguardo acuto e calmo |
| verde | verde menta | DEX: preciso, vigile, sguardo concentrato |
| blu | azzurro | QCK: rapido, brillante, sguardo vivace |

Espressioni da disegnare per ogni personaggio: `neutral`, `happy`, `angry`, `sad`, `surprised`, `hurt` (lo stesso volto, cambiano occhi,
sopracciglia e bocca; il resto dell'immagine resta uguale cosi' si sovrappongono perfettamente).

| id | Nome | Colore | Classe | Fazione | Note per il disegno |
|---|---|---|---|---|---|
| kira | Kira | viola | striker | Rondini | giovane scattante, divisa Rondini bianca, capelli viola |
| dax | Dax | rosso | vanguard | LibraCorp | robusto, divisa LibraCorp, sguardo fermo |
| elle | Elle | verde | warden | Magabondi | abiti sciolti e colorati, aria libera |
| bruno | Bruno | blu | vanguard | LibraCorp | solido e affidabile, divisa LibraCorp |
| nova | Nova | giallo | striker | Rondini | vivace, accessori dorati |
| mira | Mira | blu | warden | LibraCorp | calma e attenta, divisa LibraCorp |
| rex | Rex | rosso | striker | Rondini | grintoso, giacca Rondini |
| ivo | Ivo | blu | striker | Magabondi | agile, look da strada |
| sera | Sera | verde | warden | Rondini | elegante e serena, tratti delicati |
| eco | Eco | giallo | striker | Kairos | enigmatico, dettagli dissonanti (Kairos) |
| tana | Tana | giallo | vanguard | LibraCorp | leggendaria: presenza imponente, protettiva |
| nico | Nico | rosso | vanguard | Kairos | storia (sbloccato con lo Specchio): amico di Kira, custode del rifugio, sciarpa rossa sempre al collo |
| dafne | Dafne | verde | striker | LibraCorp | leggendaria, tiratrice scelta: sguardo da cecchina, divisa operativa |
| angela | Angela | giallo | striker | LibraCorp | leggendaria, "Dea del laser orbitale": mecamante, elementi tecnologici luminosi |

Per la **rarita'** si puo' curare di piu' il dettaglio: comuni semplici, leggendari con accessori e illustrazione piu' ricca.
Mentre le grafiche vere non ci sono, il gioco disegna da solo un volto anime segnaposto con questi stessi colori (`scripts/art/anime_face.gd`).

## Dialoghi
Le scene incluse sono in `scripts/story/story_data.gd`. Per riscriverne una senza toccare il
codice crea un file `dialogues/<id>.txt` accanto all'eseguibile (o nella cartella dati) con
`<id>` = `distributore_pre`, `distributore_post`, `semaforo_pre`, ... Il file sostituisce la scena inclusa.

Formato (una cosa per riga, `#` = commento):
```
@bg strada_notte            sfondo
kira [angry] L: Testo.      personaggio, espressione, lato (L o R)
dax: Testo.                 lato ed espressione si ricordano
*: Narrazione.              senza ritratto
> Scelta uno -> a           scelta multipla (righe di fila)
> Scelta due -> b
:a                          punto di arrivo
@goto fine                  salto
@end                        fine
```
Espressioni: neutral, happy, angry, sad, surprised, hurt.
Comandi nel dialogo: click / INVIO / SPAZIO = avanti, tasti 1-3 = scelta, ESC = salta.

## Modelli pronti
`python tools/make_art_templates.py` crea in `art_templates/` un PNG segnaposto per ogni
file, gia' con il nome e la misura giusti, da usare come traccia per disegnare.
