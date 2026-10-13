# ODISPEL - Audit UI/UX e design system

Data: 2026-10-13, versione 0.24.8. Metodo: ho guardato le schermate vere (immagini a 1280x720 generate dagli strumenti in `tools/`) e controllato il layout automatico a 1600x720 (`tools/ui_audit.gd`: 0 problemi). Non ho potuto provare un telefono vero: i voti su tocco e leggibilita' mobile sono **NON VERIFICATI**. Punteggi 1-5 (1 problematico, 3 buono con difetti, 5 eccellente e verificato). Non ho dato 5 a nulla perche' manca la verifica su dispositivi.

Criteri: **G**erarchia, **T**ipografia, **A**llineamenti, **C**oerenza, **An**imazioni, **F**eedback, **Ch**iarezza, **S**tati, **Ac**cessibilita', **St**abilita'.

## 1. Voti per schermata

| Schermata | G | T | A | C | An | F | Ch | S | Ac | St | Note (prova) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hub | 4 | 4 | 4 | 4 | 3 | 4 | 4 | 4 | 3 | 4 | Immagine vista. Dopo la correzione i pulsanti non si sovrappongono piu' al testo in basso |
| Selezione missione | 4 | 3 | 4 | 4 | 3 | 4 | 3 | 4 | 3 | 4 | Immagine vista. Pagina molto piena (boss, livelli, sfide, missioni, record); testi piccoli (12-13 px) |
| Squadra e reclutamento | 4 | 3 | 3 | 4 | 3 | 4 | 3 | 4 | 3 | 4 | Immagine vista. Testo scheda operatore fitto e tagliato in basso; collezione piena di sagome grigie |
| Lobby | 4 | 4 | 4 | 4 | 3 | 4 | 4 | 4 | 3 | 3 | Immagine vista. Il bug del PRONTO e' ancora da riprodurre |
| Battaglia (HUD) | 4 | 3 | 4 | 4 | 4 | 4 | 4 | 4 | 3 | 4 | Immagini viste nelle sessioni precedenti (HUD riordinato in 0.24.4-0.24.6); da provare su telefono |
| PvP | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | Non rivista in questa sessione: voto prudente, da controllare |
| Obiettivi, impostazioni, profilo, risultati | 3 | 3 | 3 | 4 | 3 | 3 | 3 | 3 | 3 | 4 | Non riviste in questa sessione: voto prudente |

## 2. Problemi trovati e stato

| ID | Pr. | Problema | Stato |
|---|---|---|---|
| U-01 | **P0** | Hub a 1280x720: la riga dei tasti rapidi e il "CONSIGLIO" finivano sopra il pulsante IMPOSTAZIONI | **CORRETTO** (verificato con immagine e controllo layout) |
| U-02 | **P0** | Schermata missione: dopo le nuove sfide, AVVIA MISSIONE usciva dal riquadro e copriva la riga dei comandi | **CORRETTO** (immagine + controllo layout) |
| U-03 | P1 | Il consiglio nell'hub era tagliato a meta' frase | **CORRETTO** (ora va a capo) |
| U-04 | P1 | Riga dei comandi nella missione quasi invisibile (colore scuro su fondo scuro) | **CORRETTO** |
| U-05 | P1 | Rosso e ciano non erano esattamente complementari (rosso `#ff2d55`, tinta ~349 contro ciano ~188) | **CORRETTO**: rosso-arancio `#ff4630` (tinta ~8), vedi palette |
| U-06 | P1 | Scheda operatore: testo lungo fitto, tagliato in basso senza indicazione | APERTO: servira' un'area scorrevole piu' alta |
| U-07 | P2 | Testi di 12-13 px nella schermata missione e nelle liste | APERTO: da rialzare dopo prova su telefono |
| U-08 | P2 | Animazioni di ingresso solo su alcune schermate; transizioni tra schermate brusche | APERTO |
| U-09 | P2 | Il colore delle fazioni "Kairos" resta il vecchio rosso (identita' della fazione) | Scelta consapevole, da rivedere con le immagini definitive |
| U-10 | P3 | Nessuna modalita' per daltonici (colori del triangolo cromatico rosso-verde-blu) | APERTO: servono simboli oltre ai colori (le icone di classe aiutano gia') |

## 3. Design system (quello che esiste e cosa si aggiunge)

Esiste gia': `BattleTheme` (colori, etichette, pulsanti: stati `normal`, `primary`), `HudPanel` (pannelli con titolo e angoli), `SlantBox`, `UiTex` (texture leggere a righe/punti), `ButtonFx` (pressione e scala), `SegBar` (barre), `AnimFx`, `UiMotion` (ingressi), `Notify`. Le schermate li usano in modo coerente.

**Palette a colori complementari** (teoria dei colori: due tinte opposte sul cerchio cromatico si valorizzano a vicenda e danno il massimo contrasto):

| Ruolo | Colore | Tinta | Uso |
|---|---|---|---|
| Primario (azione, amico, interfaccia) | ciano `#7cf0ff` | ~188 | bordi, titoli, testi attivi |
| Complementare (pericolo, nemico, selezione) | rosso-arancio `#ff4630` | ~8 | pulsante principale, boss, allarmi |
| Neutro scuro | `#061418`, `#04080a` | ~190 | sfondi (tinta del primario, bassa saturazione) |
| Accento unico | giallo `#fff36b` | ~56 | evidenza, un solo punto focale per schermata |
| Esito positivo | verde `#6bffb0` | ~150 | vittoria, completato |

Regola 60-30-10: 60% neutri scuri, 30% ciano, 10% rosso-arancio; il giallo solo per piccoli punti. I colori degli operatori (viola, rosso, verde, blu, giallo) restano come identita' di fazione e non entrano nelle regole dell'interfaccia.

Scala di movimento esistente: ingressi 0,3 s, pressione del tasto immediata (on-down). Da standardizzare: una sola durata per apertura pannello e una per dissolvenza (P2).

## 4. Piano

1. (fatto) Correzioni P0/P1 U-01..U-05.
2. U-06/U-07: dopo la prova su telefono, rialzare i testi piccoli e dare altezza alla scheda operatore.
3. U-08: transizione unica tra schermate (dissolvenza breve) e ingressi coerenti.
4. U-10: simboli oltre al colore (accessibilita').
5. Rivedere PvP, obiettivi, impostazioni, profilo e risultati con le immagini (non fatto qui).
