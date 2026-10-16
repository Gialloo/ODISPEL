# ODISPEL, parte 4 di 6: operatori e boss (dati letti dal codice del gioco)

## Operatori (24)
Colonne: id | nome | colore | classe | rarita' | fazione | stile | skill base | ultimate | passiva | abilita' uniche.
Regola dei colori: rosso batte verde, verde batte blu, blu batte rosso, giallo e viola si battono a vicenda (x1.5 / x0.67). Nico appare solo nella storia. Passive: Furia (+10% attacco), Tempra (+10% PV), Entrata scudata (scudo quando entra dalla panchina), Cacciatore (+20% danno contro bersagli sotto meta' PV).
kira | Kira | viola | striker | leggendaria | rondini | ortodosso | COLPO CARICATO | SPEZZATUTTO | Furia | uniche: TAGLIO SPETTRALE, PUGNO INCANALATO
dax | Dax | rosso | vanguard | comune | libracorp | ortodosso | PROVOCA | BASTIONE | Tempra | uniche: ARIETE
elle | Elle | verde | warden | comune | magabondi | ortodosso | CURA | RINASCITA | Entrata scudata | uniche: RESPIRO
bruno | Bruno | blu | vanguard | comune | libracorp | ortodosso | BARRIERA | BASTIONE | Tempra | uniche: PARATA LAMPO
nova | Nova | giallo | striker | rara | rondini | ortodosso | MARCHIO | SPEZZATUTTO | Cacciatore | uniche: RAFFICA MARCHIANTE
mira | Mira | blu | warden | rara | libracorp | ortodosso | PURIFICA | RINASCITA | Entrata scudata | uniche: INIEZIONE
rex | Rex | rosso | striker | comune | rondini | ortodosso | COLPO CARICATO | SPEZZATUTTO | Furia | uniche: CARICA FURIOSA
ivo | Ivo | blu | striker | rara | magabondi | atipico | MARCHIO | SPEZZATUTTO | Entrata scudata | uniche: SGAMBETTO
sera | Sera | verde | warden | epica | rondini | ortodosso | BARRIERA | RINASCITA | Cacciatore | uniche: ALA PROTETTIVA, VENTO DI CODA
eco | Eco | giallo | striker | epica | kairos | ortodosso | MARCHIO | SPEZZATUTTO | Furia | uniche: ECO RIPETUTO, FREQUENZA CRITICA
tana | Tana | giallo | vanguard | leggendaria | libracorp | ortodosso | PROVOCA | BASTIONE | Cacciatore | uniche: BASTIONE VIVENTE, MURO TOTALE
nico | Nico | rosso | vanguard | epica | kairos | ortodosso | INTIMIDISCI | BASTIONE | Entrata scudata | uniche: SEGNALE DI FUMO, PORTA APERTA
dafne | Dafne | giallo | striker | leggendaria | libracorp | ortodosso | MARCHIO | COLPO COORDINATO | Furia | uniche: COLPO MIRATO, COPERTURA
angela | Angela | giallo | striker | leggendaria | libracorp | ortodosso | TORRETTA FUCILE | RAGGIO ORBITALE | Furia | uniche: DRONE MUNIZIONI, MITRAGLIATRICE
moro | Moro | rosso | vanguard | rara | magabondi | ortodosso | PROVOCA | LEGGE DEL CONTRACCOLPO | Tempra | uniche: RITORSIONE
vesper | Vesper | viola | striker | epica | magabondi | ortodosso | MARCHIO | ECLISSI CREMISI | Furia | uniche: TAGLIO PREDATORIO, TAGLIO D'OMBRA
nami | Nami | verde | warden | comune | magabondi | ortodosso | BARRIERA | CERCHIO SICURO | Tempra | uniche: RIPARO IMPROVVISATO
oriel | Oriel | blu | warden | leggendaria | kairos | ortodosso | CURA | RIFUGIO ASSOLUTO | Entrata scudata | uniche: PROTOCOLLO DI SOCCORSO, INTERDIZIONE
silex | Silex | viola | vanguard | rara | kairos | ortodosso | PROVOCA | FORTEZZA GEOMETRICA | Tempra | uniche: FRATTURA MINERALE
yuna | Yuna | blu | striker | epica | kairos | ortodosso | COLPO CARICATO | LAMA DEL FUTURO | Furia | uniche: PASSO FULMINEO, SCATTO VETTORIALE
rhea | Rhea | verde | warden | rara | rondini | ortodosso | PURIFICA | ALBA CONDIVISA | Entrata scudata | uniche: RICOMPOSIZIONE
flux | Flux | blu | striker | leggendaria | rondini | ortodosso | COLPO CARICATO | PUNTO DI ROTTURA | Furia | uniche: RAFFICA SINCRONIZZATA, SCARICA DIRETTA
cato | Cato | viola | vanguard | comune | libracorp | ortodosso | BARRIERA | LINEA INVALICABILE | Tempra | uniche: IMPATTO DI CONTENIMENTO
lyra | Lyra | viola | striker | leggendaria | libracorp | ortodosso | MARCHIO | SENTENZA COORDINATA | Furia | uniche: MARCHIO DI PRIORITA', ESECUZIONE CALIBRATA

## Boss (18, in ordine di sblocco)
Colonne: n | nome | colore | classe e minaccia | PV per giocatore | attacco | difesa | mosse del ciclo | alleato che si sblocca | descrizione.
1 | Distributore | giallo | CLASSE ANOMALIA · MINACCIA BASSA | 900 | 390 | 25 | SCARICA, RAFFICA, SCOSSA, SOVRACCARICO | eco | Un distributore automatico impazzito. Colpi pesanti a un solo bersaglio e scosse che fanno sanguinare.
2 | Semaforo | rosso | CLASSE ANOMALIA · MINACCIA MEDIA | 850 | 380 | 20 | LAMPEGGIO, ROSSO, GIALLO, VERDE |  | Un semaforo che non cambia piu' colore. Veloce: agisce prima di quasi tutti. Marchia la squadra e punta chi e' piu' ferito.
3 | Tombino | viola | CLASSE ANOMALIA · MINACCIA ALTA | 1000 | 340 | 35 | GORGO, RISUCCHIO, ALLUVIONE, CHIUSURA |  | Qualcosa vive sotto il tombino. Lento ma resistente: si cura risucchiando i feriti e si chiude sotto uno scudo.
4 | Cabina | blu | CLASSE ANOMALIA · MINACCIA CRITICA | 1100 | 360 | 30 | SQUILLO, CHIAMATA, INTERFERENZA, LINEA OCCUPATA |  | Una cabina telefonica che squilla da sola. Marchia la squadra, chiama un bersaglio con un colpo pesante e si nutre di chi e' gia' ferito.
5 | Ascensore | blu | CLASSE ANOMALIA · MINACCIA ESTREMA | 1200 | 380 | 40 | PORTE CHE SI CHIUDONO, CADUTA LIBERA, PIANO ZERO, MANUTENZIONE |  | L'ascensore della torre LibraCorp: sale a piani che non esistono. Porte che si chiudono su un solo bersaglio, cadute su tutta la squadra, e una manutenzione che lo protegge.
6 | Manichino | verde | CLASSE ANOMALIA · MINACCIA ESTREMA | 1150 | 400 | 28 | POSA, VETRINA, COPIA, SFILATA |  | Un manichino in vetrina che copia chi lo guarda. Veloce: marchia tutti dietro il vetro, posa su un bersaglio e si nutre dei feriti.
7 | Orologio | viola | CLASSE ANOMALIA · MINACCIA ASSOLUTA | 1500 | 420 | 45 | RINTOCCO, LANCETTE, ORA ZERO, TEMPO PERSO |  | L'orologio della torre, al centro di CAM-00. Ferma il tempo per chi lo guarda: colpi pesanti, lancette che feriscono tutti e un'ora zero che marchia la squadra.
8 | Specchio | rosso | CLASSE ANOMALIA · OLTRE LA SCALA | 1700 | 440 | 50 | RIFLESSO, FRANTUMI, DOPPIO, SIMMETRIA | nico | Lo specchio che c'era dietro l'orologio: mostra la squadra come sarebbe stata se il tempo non si fosse fermato. Un riflesso colpisce un solo bersaglio, i frantumi feriscono tutti e il doppio si nutre dei piu' deboli.
9 | Sirena | rosso | S2 · MINACCIA ALTA | 1250 | 430 | 42 | ULULATO, ALLARME ROSSO, STRIDIO, COPRIFUOCO | dafne | La sirena d'allarme di Via Pia: urla da sola da tre notti. Marchia tutta la squadra, chiama un solo bersaglio con l'allarme rosso e si ripara dietro il coprifuoco.
10 | Lampione | giallo | S2 · MINACCIA ALTA | 1300 | 440 | 44 | ABBAGLIO, BUIO IMPROVVISO, FALENA, CONO DI LUCE |  | Un lampione di Piazza dei Salici che accende il buio invece di spegnerlo. Abbaglia un bersaglio, marchia tutti nel buio e attira le falene sui piu' feriti.
11 | Bancomat | verde | S2 · MINACCIA ESTREMA | 1350 | 450 | 46 | PRELIEVO, COMMISSIONE, SALDO NEGATIVO, BLOCCO CARTA |  | Un bancomat che non restituisce niente. Preleva vita ai piu' deboli, addebita commissioni a tutti e chiude la carta sotto uno scudo.
12 | Scala mobile | blu | S2 · MINACCIA ESTREMA | 1400 | 455 | 48 | GRADINO MANCANTE, RISALITA, SENSO INVERSO, ARRESTO DI EMERGENZA |  | La scala mobile della stazione, che scende anche quando sale. Un gradino mancante colpisce uno solo, la risalita ferisce tutti.
13 | Radio | viola | S2 · MINACCIA ESTREMA | 1450 | 465 | 50 | FRUSCIO, SINTONIA FORZATA, DISTURBO, ONDA LUNGA |  | Una radio che trasmette voci di chi non c'e' piu'. Veloce: marchia tutti col fruscio, forza la sintonia su un bersaglio e succhia chi e' gia' a terra.
14 | Metro | rosso | S2 · MINACCIA ASSOLUTA | 1550 | 480 | 52 | BINARIO MORTO, ULTIMA CORSA, FERMATA RICHIESTA, CAPOLINEA |  | Il treno fantasma dell'ultima corsa. Veloce e pesante: binario morto su un bersaglio, ultima corsa su tutti, capolinea sui piu' deboli.
15 | Cassaforte | verde | S2 · MINACCIA ASSOLUTA | 1650 | 470 | 66 | SERRATURA, COMBINAZIONE, BLINDATURA, FURTO |  | La cassaforte del caveau LibraCorp. Lenta ma blindata: la combinazione marchia la squadra, la blindatura la protegge e il furto svuota i feriti.
16 | Faro | blu | S2 · MINACCIA ASSOLUTA | 1700 | 490 | 58 | FASCIO, NEBBIA, NAUFRAGIO, MAREA NERA |  | Il faro del porto vecchio, che guida le navi verso gli scogli. Il fascio colpisce un solo bersaglio, la nebbia marchia tutti, il naufragio ferisce l'intera squadra.
17 | Registro | giallo | S2 · OLTRE LA SCALA | 1850 | 510 | 62 | CANCELLAZIONE, PROTOCOLLO NERO, FASCICOLO, ARCHIVIAZIONE |  | L'archivio nero di LibraCorp: dove finisce chi viene cancellato. Cancella un bersaglio, schedatura marchia tutti, l'archiviazione si nutre dei piu' deboli.
18 | Eclissi | viola | S2 · IL FINALE | 2100 | 540 | 70 | OSCURAMENTO, CORONA, PENOMBRA, ORA NERA |  | Il sole nero sopra i sette minuti perduti. Oscura e marchia tutti, la corona schiaccia un solo bersaglio, la penombra beve i piu' deboli e l'ora nera ferisce tutta la squadra.
