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

Boss (`<boss>` = distributore, semaforo, tombino):

| File | Uso | Misura |
|---|---|---|
| `bosses/<boss>/battle.png` | boss in campo | 1000x1000, piedi sul bordo basso |
| `bosses/<boss>/hurt.png` | boss colpito (facoltativo) | come battle |
| `bosses/<boss>/portrait.png` | dialoghi (se manca usa battle) | 1000x1400 |

Sfondi:
- `backgrounds/battle/layer_1.png` ... `layer_4.png`: strati dal piu' lontano (1) al piu' vicino (4), 1400x800. Si muovono con la parallasse. Usane da 1 a 4.
- `backgrounds/<boss>/layer_N.png`: come sopra ma solo per quel boss (ha la precedenza).
- `backgrounds/hub.png`: sfondo dell'hub, 1920x1080.
- `backgrounds/dialogue/<nome>.png`: sfondi dei dialoghi, richiamati con `@bg nome`. 1920x1080.

## Personaggi nuovi
Il nome della cartella e' l'id del personaggio (lo stesso usato nel gioco).

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
