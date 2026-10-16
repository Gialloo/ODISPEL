# ODISPEL, parte 1 di 6: il gioco in breve

ISTRUZIONI PER CHATGPT: ti mando la descrizione completa di un videogioco in 6 messaggi (parti 1-6). Non rispondere fino a quando non scrivo "FINE". Poi leggi tutto insieme e rispondi alle mie domande. Non puoi vedere il gioco: la parte 2 descrive l'aspetto con testo e schemi.

## Cos'e'
ODISPEL e' un videogioco a turni in cui una squadra di maghi combatte contro boss (mostri). Si gioca da soli, in cooperativa online con gli amici e anche uno contro uno (PvP). Stile: anime 2D illustrato, ambientazione fantasy urbana di notte. Esce per Windows e Android. E' fatto con il motore Godot 4.7.2 e il linguaggio GDScript; tutta l'interfaccia e' disegnata dal codice. Il gioco e' in italiano.

## Il mondo
Gli **Odispeller** sono i maghi di questo mondo. Esiste un albo e una licenza magica. Le fazioni:
- **LibraCorp**: gruppo paramilitare finanziato dal misterioso Leviatano. Sono i "poliziotti" contro le Anomalie e i maghi. I loro poteri vengono dall'equipaggiamento (armi con munizioni). Dottrina: Protocollo (risposte, contrattacchi, ricarica).
- **Rondini**: Odispeller che fanno le ronde di notte per proteggere gli umani. Dottrina: Ronda (colpi critici, danno alto, cannoni di vetro).
- **Magabondi**: maghi senza licenza, che praticano magia illegalmente. Possono essere buoni, neutrali o cattivi. Dottrina: Improvvisazione (trovate non convenzionali).
- **Kairos o Anomalie**: demoni venuti da un altro piano. Dottrina: Dissonanza (legano, indeboliscono, avvelenano). I boss attuali sono Anomalie urbane: oggetti di citta' impazziti (distributore, semaforo, tombino...).
Il giocatore e' un operatore neutrale che coordina le squadre da una centrale di sorveglianza: per questo l'interfaccia ricorda telecamere (scritte tipo MISSION CONTROL, REC).
La storia e' in scene a copione, in due stagioni; la seconda introduce Dafne (Agent 02 di LibraCorp).

## Come si gioca un combattimento (in breve)
1. Hai una squadra fino a 6 operatori: 3 "front row" (in campo) e 3 "back row" (panchina, si possono scambiare gratis).
2. Il boss annuncia la sua prossima mossa ("ALLARME": nome della mossa e bersaglio). Le mosse pesanti sono annunciate prima.
3. Ogni round scegli la mossa di ogni operatore in campo da un menu a ventaglio: Attacco, Guardia, fino a 4 mosse nel kit piu' l'ultimate quando la barra e' piena.
4. Quando tutti hanno scelto, le azioni si risolvono in ordine di velocita' (le priorita' contano). Si vedono animazioni e numeri.
5. Si vince portando a zero la vita del boss, si perde se cade tutta la squadra.
6. In piu': la barra EQUILIBRIO del boss (a zero e' stordito e salta la mossa), vantaggi di colore, combo tra compagni, reazioni difensive alle cariche del boss.

## Modalita'
- **Storia** e **Missioni**: 18 boss in ordine di sblocco, con 4 difficolta' (Normale, Difficile, Incubo, Abisso).
- **Sfida del giorno** e **Evento della settimana**: boss e modificatore dalla data, con serie di premi.
- **Ciclo infinito**: piani sempre piu' duri con potenziamenti da scegliere.
- **Spedizione**: avventura a tappe stile roguelite, da soli o in co-op (breve 6 tappe, lunga 10).
- **Co-op online**: stanze con codice, chat di squadra; il computer dell'host decide il risultato (host autoritativo).
- **PvP**: motore a parte, modalita' bilanciata (livello 20, niente equipaggiamento) e allenamento contro il computer.
- **Tutorial**, **Obiettivi** giornalieri e permanenti, **Archivio delle scoperte** (combo e comportamenti visti).

## Progressione
- Collezione di 24 operatori. Si reclutano con i crediti (gacha senza denaro vero). Rarita': comune, rara, epica, leggendaria.
- Ogni operatore ha livello, rank, equipaggiamento (arma, petto, stivali), mosse e una passiva unica.
- Valute: CREDITI, NUCLEI, LEGHE. Titoli con bonus permanenti, maestria delle mosse (25 usi per livello, max 3), "potere" come punteggio.
- Il boss che hai gia' battuto la volta dopo ha imparato dal tuo stile (solo in solitaria).
- Una sfida facoltativa a ogni battaglia (+120 crediti se superata).

## Stato del progetto
Versione 0.24.30 (16 ottobre 2026). Un solo sviluppatore, con l'aiuto di un'IA. Il gioco funziona; il lavoro attuale riguarda la qualita' visiva (HUD, effetti di luce) e il bilanciamento.
