# Icone ODISPEL — stile, registro e uso

GENERATO in parte da `tools/icons/build.py` (la tabella finale). Sorgente dei disegni: `tools/icons/lib.py` e `defs_*.py`.

## Stile
- Griglia 24x24, margine 2, tratto 2 (1,5 per i dettagli piccoli), angoli vivi, estremita' squadrate.
- Riempimenti: 'morbido' = bianco al 30%, 'pieno' = bianco. Nessun testo, numero, sfondo.
- Gli SVG sono BIANCHI e trasparenti: il gioco li tinge (`GameIcon.color`). Il significato sta nella FORMA, non nel colore.
- Palette di riferimento (tinte applicate dal gioco): corallo #FF667A pericolo, ciano #55D8F5 info/difesa, giallo #FFC857 attenzione, viola #C59AFF energia rituale, verde #68E0A3 recupero.
- Varianti di stato: ottenute con geometria (incrinato, spezzato, critico), non solo col colore. Stati disabilitato/selezionato: tinta e contorno decisi dal componente che usa l'icona.
- Famiglie coerenti: stessa lama per buff/debuff attacco, stesso scudo per buff/debuff difesa, stessi anelli per combo disponibile/attivata, stessi nodi per connessione stabile/instabile, stesso fulmine per speciale/ultimate (+ anello).

## Dove sono i file
- `assets/ui/icons/<famiglia>/<id>.svg` (+ `<id>__<variante>.svg`); stemmi in `assets/ui/icons/factions/<fazione>_{light,dark,color,compact,large}.svg`.
- Registro: `scripts/ui/icon_catalog.gd` (`IconCatalog.ENTRIES`, esposto anche come `GameIcon.SYMBOLS`); SVG incorporati in `IconCatalog.SVG` (cosi' l'esportazione non dipende dall'importazione degli asset).
- Atlante visivo: `docs/icone/atlante.html` (e `atlante.png`). `assets/ui/icons/catalog.json` = stesso registro in JSON.

## Rigenerare
`python3 tools/icons/build.py` riscrive SVG, `scripts/ui/icon_catalog.gd`, `assets/ui/icons/catalog.json`, questo file e `docs/icone/atlante.html` (l'immagine `atlante.png` si ottiene aprendo l'HTML in un browser). Per aggiungere o ritoccare un'icona: modificare `tools/icons/defs_*.py`, rigenerare, eseguire `tests/unit/test_icon_catalog.gd`.

## Screenshot (1280x720, xvfb, giochi avviati davvero)
In `docs/icone/screens/`: battaglia (scelta, pericolo, risoluzione; PC e touch), roster, hub, PvP, obiettivi, lobby multiplayer. Non testate su telefono reale.

## Come si usa
- `GameIcon.new().setup(id, colore, px)`; variante: `setup(id, colore, px, 'incrinato')`. Se l'ID manca o il rendering fallisce, si usa il disegno di riserva in codice o un cerchio.
- Usare l'icona dove il significato e' noto, con il numero accanto; testo esplicito per pericoli critici (rischio KO).
- Le icone con stato 'non implementata' o 'da verificare' NON vanno mostrate in combattimento o nei menu: sono asset predisposti.

## Stato delle meccaniche (da verificare: 26, implementata: 95, implementata parzialmente: 58, non implementata: 73)

Stesso concetto = stessa immagine: le voci con 'Uguale a' condividono il disegno di proposito (es. SCUDO e DIFESA STATISTICA).

| Codice | ID | Nome | Famiglia | Varianti | Stato | Fallback | Uguale a |
|---|---|---|---|---|---|---|---|
| A01 | `hp` | Punti vita | combat | critico | implementata | codice:hp | - |
| A02 | `shield` | Scudo | combat | incrinato, spezzato | implementata | codice:shield | - |
| A03 | `balance` | Equilibrio / Tenacia | combat | - | implementata | codice:balance | - |
| A04 | `danger` | Pericolo | combat | - | implementata | codice:danger | - |
| A05 | `danger_lethal` | Pericolo letale | combat | - | implementata | cerchio | - |
| A06 | `ko` | KO | combat | - | implementata | codice:ko | - |
| A07 | `attack` | Attacco | combat | semplice | implementata | codice:sword | - |
| A08 | `defense` | Difesa | combat | - | implementata | cerchio | - |
| A09 | `special` | Mossa speciale | combat | - | implementata | codice:bolt | - |
| A10 | `ultimate` | Ultimate | combat | - | implementata | codice:burst | - |
| A11 | `heal` | Cura | combat | - | implementata | codice:heal | - |
| A12 | `heal_over_time` | Recupero nel tempo | combat | - | implementata parzialmente | cerchio | - |
| A13 | `mobility` | Mobilita' | combat | - | implementata parzialmente | cerchio | - |
| A14 | `dodge` | Schivata | combat | - | implementata | cerchio | - |
| A15 | `dodge_perfect` | Schivata perfetta | combat | - | da verificare | cerchio | - |
| A16 | `duration` | Durata | combat | - | implementata | cerchio | - |
| A17 | `target_single` | Bersaglio singolo | combat | - | implementata | codice:target | - |
| A18 | `target_all_enemies` | Tutti i nemici | combat | - | implementata | cerchio | - |
| A19 | `target_all_allies` | Tutti gli alleati | combat | - | da verificare | cerchio | - |
| A20 | `area` | Area d'effetto | combat | - | non implementata | cerchio | - |
| A21 | `attack_front` | Attacco frontale | combat | - | implementata parzialmente | cerchio | - |
| A22 | `attack_rear` | Attacco posteriore | combat | - | implementata parzialmente | cerchio | - |
| A23 | `interrupt` | Interruzione | combat | - | implementata parzialmente | cerchio | - |
| A24 | `weakness` | Debolezza | combat | - | da verificare | cerchio | - |
| A25 | `resistance` | Resistenza | combat | - | da verificare | cerchio | - |
| A26 | `immunity` | Immunita' | combat | - | da verificare | cerchio | - |
| A27 | `damage_up` | Danno aumentato | combat | - | da verificare | cerchio | - |
| A28 | `damage_down` | Danno ridotto | combat | - | da verificare | cerchio | - |
| A29 | `precision` | Precisione | combat | - | da verificare | cerchio | - |
| A30 | `crit` | Critico | combat | - | implementata | cerchio | - |
| A31 | `miss` | Colpo mancato | combat | - | implementata parzialmente | cerchio | - |
| A32 | `taunt` | Provocazione | combat | - | implementata | codice:taunt | - |
| A33 | `lifesteal` | Furto di vita | combat | - | implementata parzialmente | cerchio | - |
| A34 | `purify` | Purificazione | combat | - | implementata | codice:cleanse | - |
| A35 | `resurrect` | Resurrezione | combat | - | implementata parzialmente | cerchio | - |
| A36 | `target_protected` | Bersaglio protetto | combat | - | da verificare | cerchio | - |
| A37 | `attack_charged` | Attacco caricato | combat | - | da verificare | cerchio | - |
| A38 | `attack_pierce` | Attacco perforante | combat | - | implementata | cerchio | - |
| A39 | `attack_ricochet` | Attacco rimbalzante | combat | - | non implementata | cerchio | - |
| A40 | `reflect` | Danno riflesso | combat | - | implementata parzialmente | cerchio | - |
| A41 | `absorb` | Assorbimento | combat | - | implementata parzialmente | cerchio | - |
| A42 | `steal_resource` | Furto di risorsa | combat | - | non implementata | cerchio | - |
| A43 | `finisher` | Colpo di grazia | combat | - | non implementata | cerchio | - |
| A44 | `row_swap` | Cambio di fila | combat | - | implementata parzialmente | cerchio | - |
| A45 | `reposition` | Riposizionamento | combat | - | da verificare | cerchio | - |
| B01 | `st_burn` | Bruciatura | status | - | da verificare | cerchio | - |
| B02 | `st_poison` | Veleno | status | - | da verificare | cerchio | - |
| B03 | `st_bleed` | Sanguinamento | status | - | implementata | cerchio | - |
| B04 | `st_frost` | Gelo | status | - | da verificare | cerchio | - |
| B05 | `st_slow` | Rallentamento | status | - | implementata parzialmente | cerchio | - |
| B06 | `st_root` | Immobilizzazione | status | - | non implementata | cerchio | - |
| B07 | `st_stun` | Stordimento | status | - | da verificare | cerchio | - |
| B08 | `st_silence` | Silenzio | status | - | non implementata | cerchio | - |
| B09 | `st_blind` | Cecita' | status | - | non implementata | cerchio | - |
| B10 | `st_confusion` | Confusione | status | - | non implementata | cerchio | - |
| B11 | `st_fear` | Paura | status | - | non implementata | cerchio | - |
| B12 | `st_corruption` | Corruzione | status | - | non implementata | cerchio | - |
| B13 | `st_drain` | Drenaggio | status | - | non implementata | cerchio | - |
| B14 | `st_skill_lock` | Blocco abilita' | status | - | non implementata | cerchio | - |
| B15 | `buff` | Potenziamento | status | - | implementata parzialmente | cerchio | - |
| B16 | `debuff` | Penalita' | status | - | implementata parzialmente | cerchio | - |
| B17 | `buff_atk` | Potenziamento attacco | status | - | implementata parzialmente | cerchio | - |
| B18 | `debuff_atk` | Penalita' attacco | status | - | implementata parzialmente | cerchio | - |
| B19 | `buff_def` | Potenziamento difesa | status | - | implementata parzialmente | cerchio | - |
| B20 | `debuff_def` | Penalita' difesa | status | - | implementata parzialmente | cerchio | - |
| B21 | `buff_spd` | Potenziamento velocita' | status | - | implementata parzialmente | cerchio | - |
| B22 | `debuff_spd` | Penalita' velocita' | status | - | implementata parzialmente | cerchio | - |
| B23 | `buff_acc` | Potenziamento precisione | status | - | implementata parzialmente | cerchio | - |
| B24 | `debuff_acc` | Penalita' precisione | status | - | implementata parzialmente | cerchio | - |
| B25 | `temp_shield` | Scudo temporaneo | status | - | non implementata | cerchio | - |
| B26 | `regen` | Rigenerazione | status | - | non implementata | cerchio | `heal_over_time` |
| B27 | `temp_immunity` | Immunita' temporanea | status | - | non implementata | cerchio | - |
| B28 | `status_clear` | Rimozione di status | status | - | non implementata | cerchio | - |
| B29 | `status_resist` | Resistenza specifica | status | - | non implementata | cerchio | - |
| B30 | `status_stack` | Accumulo di status | status | - | non implementata | cerchio | - |
| B31 | `status_consume` | Consumo di status | status | - | non implementata | cerchio | - |
| B32 | `status_duration` | Durata residua | status | - | implementata | cerchio | `duration` |
| C01 | `turn_active` | Turno attivo | turns | - | implementata | cerchio | - |
| C02 | `turn_wait` | Turno in attesa | turns | - | implementata | cerchio | - |
| C03 | `timer` | Timer di scelta | turns | - | implementata | cerchio | - |
| C04 | `timer_bonus_max` | Bonus temporale massimo | turns | - | non implementata | cerchio | - |
| C05 | `timer_bonus_min` | Bonus temporale minore | turns | - | non implementata | cerchio | - |
| C06 | `timer_neutral` | Timer neutro | turns | - | implementata parzialmente | cerchio | - |
| C07 | `timer_penalty_min` | Penalita' temporale minore | turns | - | non implementata | cerchio | - |
| C08 | `timer_penalty_max` | Penalita' temporale massima | turns | - | non implementata | cerchio | - |
| C09 | `time_up` | Tempo scaduto | turns | - | non implementata | cerchio | - |
| C10 | `action_auto` | Azione automatica | turns | - | implementata | cerchio | - |
| C11 | `action_confirmed` | Azione confermata | turns | - | implementata | cerchio | - |
| C12 | `resolving` | Risoluzione in corso | turns | - | implementata | cerchio | - |
| C13 | `action_cancel` | Azione annullata | turns | - | non implementata | cerchio | - |
| C14 | `action_unavailable` | Azione non disponibile | turns | - | non implementata | cerchio | - |
| C15 | `sequence` | Sequenza in corso | turns | - | non implementata | cerchio | - |
| C16 | `result_final` | Risultato finale | turns | - | non implementata | cerchio | - |
| D01 | `combo_ready` | Combo disponibile | combos | - | implementata parzialmente | cerchio | - |
| D02 | `combo_active` | Combo attivata | combos | - | implementata parzialmente | cerchio | - |
| D03 | `combo_chain` | Catena di combo | combos | - | non implementata | cerchio | - |
| D04 | `reaction_ready` | Reazione disponibile | combos | - | implementata | cerchio | - |
| D05 | `reaction_used` | Reazione consumata | combos | - | implementata | cerchio | - |
| D06 | `reaction_reserve` | Riserva reazioni | combos | - | implementata | cerchio | - |
| D07 | `synergy` | Sinergia tra operatori | combos | - | implementata parzialmente | cerchio | - |
| D08 | `attack_combined` | Attacco combinato | combos | - | non implementata | cerchio | - |
| D09 | `team_bonus` | Bonus di squadra | combos | - | implementata parzialmente | cerchio | - |
| D10 | `boss_opening` | Opportunita' sul boss | combos | - | non implementata | cerchio | - |
| D11 | `interaction` | Interazione speciale | combos | - | non implementata | cerchio | - |
| D12 | `combo_fail` | Combo fallita | combos | - | non implementata | cerchio | - |
| D13 | `combo_perfect` | Combo perfetta | combos | - | non implementata | cerchio | - |
| D14 | `reaction_incoming` | Reazione in arrivo | combos | - | implementata parzialmente | cerchio | - |
| D15 | `synergy_ready` | Sinergia pronta | combos | - | implementata parzialmente | cerchio | - |
| E01 | `boss_phase` | Fase del boss | boss | - | implementata | cerchio | - |
| E02 | `boss_enrage` | Furia / Enrage | boss | - | implementata | cerchio | - |
| E03 | `boss_charge` | Caricamento del boss | boss | - | implementata | cerchio | - |
| E04 | `boss_hit_all` | Attacco a tutta la squadra | boss | - | implementata | cerchio | - |
| E05 | `boss_hit_front` | Attacco alla prima fila | boss | - | da verificare | cerchio | - |
| E06 | `boss_hit_back` | Attacco alla retroguardia | boss | - | da verificare | cerchio | - |
| E07 | `attack_unavoidable` | Attacco inevitabile | boss | - | da verificare | cerchio | - |
| E08 | `vulnerability_window` | Finestra di vulnerabilita' | boss | - | implementata | cerchio | - |
| E09 | `boss_breaking` | Boss in rottura | boss | - | implementata | cerchio | - |
| E10 | `environment` | Meccanica ambientale | boss | - | da verificare | cerchio | - |
| E11 | `phase_goal` | Obiettivo di fase | boss | - | da verificare | cerchio | - |
| E12 | `reinforcements` | Rinforzi nemici | boss | - | da verificare | cerchio | - |
| E13 | `attack_announced` | Attacco annunciato | boss | - | implementata | cerchio | - |
| E14 | `attack_lethal` | Attacco potenzialmente letale | boss | - | implementata | cerchio | `danger_lethal` |
| E15 | `target_priority` | Bersaglio prioritario | boss | - | implementata | cerchio | - |
| E16 | `weakness_exposed` | Debolezza esposta | boss | - | implementata | cerchio | - |
| F01 | `net_host` | Ospitante | multiplayer | - | implementata | cerchio | - |
| F02 | `net_connected` | Giocatore connesso | multiplayer | - | implementata | cerchio | - |
| F03 | `net_unstable` | Connessione instabile | multiplayer | - | implementata parzialmente | cerchio | - |
| F04 | `net_sync` | Sincronizzazione | multiplayer | - | non implementata | cerchio | - |
| F05 | `net_waiting` | In attesa | multiplayer | - | implementata parzialmente | cerchio | - |
| F06 | `net_sent` | Azione inviata | multiplayer | - | implementata parzialmente | cerchio | - |
| F07 | `net_confirmed` | Azione confermata | multiplayer | - | implementata parzialmente | cerchio | - |
| F08 | `net_ally_off` | Alleato disconnesso | multiplayer | - | implementata parzialmente | cerchio | - |
| F09 | `net_rejoin` | Rientro in partita | multiplayer | - | implementata parzialmente | cerchio | - |
| F10 | `net_ready` | Pronto al combattimento | multiplayer | - | implementata | cerchio | - |
| F11 | `net_team_synergy` | Sinergia di squadra | multiplayer | - | non implementata | cerchio | - |
| F12 | `net_quick_chat` | Comunicazione rapida | multiplayer | - | non implementata | cerchio | - |
| F13 | `net_ally_turn` | Turno dell'alleato | multiplayer | - | implementata parzialmente | cerchio | - |
| F14 | `net_ally_waiting` | Azione dell'alleato in attesa | multiplayer | - | non implementata | cerchio | - |
| F15 | `net_sync_error` | Errore di sincronizzazione | multiplayer | - | implementata parzialmente | cerchio | - |
| F16 | `net_match_over` | Partita terminata | multiplayer | - | non implementata | cerchio | - |
| F17 | `net_victory` | Vittoria della squadra | multiplayer | - | implementata | cerchio | - |
| F18 | `net_defeat` | Sconfitta della squadra | multiplayer | - | implementata | cerchio | - |
| F19 | `net_invite` | Invito alla squadra | multiplayer | - | implementata parzialmente | cerchio | - |
| F20 | `net_leave` | Abbandono della sessione | multiplayer | - | implementata parzialmente | cerchio | - |
| G01 | `w_interact` | Interagisci | world | - | non implementata | cerchio | - |
| G02 | `w_dialog` | Dialogo | world | - | non implementata | cerchio | - |
| G03 | `w_portal` | Portale | world | - | non implementata | cerchio | - |
| G04 | `w_area_explore` | Area da esplorare | world | - | non implementata | cerchio | - |
| G05 | `w_poi` | Punto di interesse | world | - | non implementata | cerchio | - |
| G06 | `w_path_done` | Percorso completato | world | - | non implementata | cerchio | - |
| G07 | `w_quest_main` | Missione principale | world | - | non implementata | cerchio | - |
| G08 | `w_quest_side` | Missione secondaria | world | - | non implementata | cerchio | - |
| G09 | `w_quest_daily` | Missione giornaliera | world | - | non implementata | cerchio | - |
| G10 | `w_event` | Evento | world | - | non implementata | cerchio | - |
| G11 | `w_boss_target` | Boss da raggiungere | world | - | non implementata | cerchio | - |
| G12 | `w_extract` | Estrazione / Ritorno | world | - | non implementata | cerchio | - |
| G13 | `w_map` | Mappa | world | - | non implementata | cerchio | - |
| G14 | `w_checkpoint` | Checkpoint | world | - | non implementata | cerchio | - |
| G15 | `w_hub` | Hub | world | - | non implementata | cerchio | - |
| G16 | `w_travel` | Punto di viaggio | world | - | non implementata | cerchio | - |
| G17 | `w_door_locked` | Porta bloccata | world | - | non implementata | cerchio | - |
| G18 | `w_examine` | Oggetto esaminabile | world | - | non implementata | cerchio | - |
| G19 | `w_secret` | Segreto | world | - | non implementata | cerchio | - |
| G20 | `w_goal_done` | Obiettivo completato | world | - | non implementata | cerchio | `action_confirmed` |
| G21 | `w_goal_open` | Obiettivo incompleto | world | - | non implementata | cerchio | - |
| G22 | `w_codex` | Registro / Codex | world | - | implementata | cerchio | - |
| G23 | `w_tutorial` | Tutorial | world | - | implementata | cerchio | - |
| G24 | `w_new_area` | Nuova area | world | - | non implementata | cerchio | - |
| H01 | `p_new_operator` | Nuovo operatore | progression | - | implementata parzialmente | cerchio | - |
| H02 | `p_duplicate` | Duplicato | progression | - | implementata parzialmente | cerchio | - |
| H03 | `p_recruit` | Reclutamento | progression | - | implementata | cerchio | - |
| H04 | `p_upgrade` | Potenziamento | progression | - | implementata parzialmente | cerchio | - |
| H05 | `p_rank` | Ascensione / Rango | progression | - | implementata | cerchio | - |
| H06 | `p_materials` | Materiali | progression | - | implementata | cerchio | - |
| H07 | `p_currency_common` | Valuta comune | progression | - | implementata | cerchio | - |
| H08 | `p_currency_rare` | Valuta rara | progression | - | implementata | cerchio | - |
| H09 | `p_reward_ready` | Ricompensa disponibile | progression | - | implementata parzialmente | cerchio | - |
| H10 | `p_reward_claimed` | Ricompensa riscattata | progression | - | implementata parzialmente | cerchio | - |
| H11 | `p_item_new` | Oggetto nuovo | progression | - | implementata parzialmente | cerchio | - |
| H12 | `p_equipped` | Equipaggiato | progression | - | implementata | cerchio | - |
| H13 | `p_inventory_full` | Inventario pieno | progression | - | non implementata | cerchio | - |
| H14 | `p_title_earned` | Titolo ottenuto | progression | - | implementata | cerchio | - |
| H15 | `p_milestone` | Traguardo | progression | - | implementata parzialmente | cerchio | - |
| H16 | `p_rarity` | Rarita' | progression | - | implementata parzialmente | cerchio | - |
| H17 | `p_level` | Livello | progression | - | implementata | cerchio | - |
| H18 | `p_xp` | Esperienza | progression | - | implementata parzialmente | cerchio | - |
| H19 | `stat_atk` | Attacco (statistica) | progression | - | implementata | cerchio | - |
| H20 | `stat_def` | Difesa (statistica) | progression | - | implementata | cerchio | `shield` |
| H21 | `stat_spd` | Velocita' (statistica) | progression | - | implementata | cerchio | - |
| H22 | `stat_acc` | Precisione (statistica) | progression | - | implementata parzialmente | cerchio | `target_single` |
| H23 | `stat_crit` | Critico (statistica) | progression | - | implementata | cerchio | `crit` |
| H24 | `stat_resource` | Risorsa (statistica) | progression | - | implementata | cerchio | - |
| H25 | `skill_unlocked` | Abilita' sbloccata | progression | - | implementata parzialmente | cerchio | - |
| H26 | `skill_locked` | Abilita' bloccata | progression | - | implementata parzialmente | cerchio | `st_skill_lock` |
| H27 | `skill_available` | Abilita' disponibile | progression | - | non implementata | cerchio | - |
| H28 | `p_equipment` | Equipaggiamento | progression | - | implementata | cerchio | - |
| H29 | `p_inventory` | Inventario | progression | - | implementata | cerchio | - |
| H30 | `p_recruit_available` | Reclutamento disponibile | progression | - | non implementata | cerchio | - |
| H31 | `p_registry` | Registro | progression | - | implementata | cerchio | - |
| H32 | `p_titles` | Titoli | progression | - | implementata | cerchio | `p_title_earned` |
| I01 | `ui_settings` | Impostazioni | interface | - | implementata | cerchio | - |
| I02 | `ui_audio` | Audio | interface | - | implementata | cerchio | - |
| I03 | `ui_music` | Musica | interface | - | implementata | cerchio | - |
| I04 | `ui_volume` | Volume | interface | - | implementata | cerchio | - |
| I05 | `ui_mute` | Muto | interface | - | implementata | cerchio | - |
| I06 | `ui_fullscreen` | Schermo intero | interface | - | implementata | cerchio | - |
| I07 | `ui_back` | Torna indietro | interface | - | implementata | cerchio | - |
| I08 | `ui_close` | Chiudi | interface | - | implementata | cerchio | - |
| I09 | `ui_confirm` | Conferma | interface | - | implementata | cerchio | - |
| I10 | `ui_cancel` | Annulla | interface | - | implementata | cerchio | - |
| I11 | `ui_help` | Aiuto | interface | - | implementata | cerchio | `w_tutorial` |
| I12 | `ui_info` | Informazioni | interface | - | implementata | cerchio | - |
| I13 | `ui_search` | Ricerca | interface | - | non implementata | cerchio | - |
| I14 | `ui_filter` | Filtro | interface | - | non implementata | cerchio | - |
| I15 | `ui_sort` | Ordina | interface | - | non implementata | cerchio | - |
| I16 | `ui_open_detail` | Apri dettaglio | interface | - | non implementata | cerchio | - |
| I17 | `ui_expand` | Espandi | interface | - | non implementata | cerchio | - |
| I18 | `ui_collapse` | Comprimi | interface | - | non implementata | cerchio | - |
| I19 | `ui_notify` | Notifica | interface | - | implementata | cerchio | - |
| I20 | `ui_new` | Nuovo contenuto | interface | - | non implementata | cerchio | - |
| I21 | `ui_connection` | Connessione | interface | - | implementata | cerchio | - |
| I22 | `ui_connection_unstable` | Connessione instabile | interface | - | implementata | cerchio | - |
| I23 | `ui_download` | Download / Installazione | interface | - | implementata | cerchio | - |
| I24 | `ui_save` | Salvataggio | interface | - | implementata | cerchio | - |
| I25 | `ui_error` | Errore | interface | - | implementata | cerchio | - |
| I26 | `ui_warning` | Avviso | interface | - | implementata | cerchio | `danger` |
| I27 | `ui_success` | Successo | interface | - | implementata | cerchio | - |
| I28 | `ui_locked` | Bloccato | interface | - | implementata | cerchio | - |
| I29 | `ui_visible` | Visibile | interface | - | non implementata | cerchio | - |
| I30 | `ui_hidden` | Nascosto | interface | - | non implementata | cerchio | - |
| I31 | `ui_chat` | Chat | interface | - | implementata | cerchio | - |
| I32 | `ui_menu` | Menu | interface | - | implementata | cerchio | - |
| I33 | `ui_pause` | Pausa | interface | - | implementata | cerchio | - |
| I34 | `ui_play` | Riprendi | interface | - | implementata | cerchio | - |
| I35 | `ui_restart` | Riavvia | interface | - | implementata | cerchio | - |
| I36 | `ui_exit` | Esci | interface | - | implementata | cerchio | - |
| L01 | `od_force` | Forza Odica | odispel | - | implementata parzialmente | cerchio | - |
| L02 | `od_monad` | Monade | odispel | - | implementata parzialmente | cerchio | - |
| L03 | `od_trace` | Traccia | odispel | - | da verificare | cerchio | - |
| L04 | `od_ignition` | Ignition Overdrive | odispel | - | implementata parzialmente | cerchio | - |
| L05 | `od_rupture` | Rottura rituale | odispel | - | implementata parzialmente | cerchio | - |
| L06 | `od_energy` | Energia accumulata | odispel | - | implementata parzialmente | cerchio | - |
| L07 | `od_energy_empty` | Energia esaurita | odispel | - | implementata parzialmente | cerchio | - |
| L08 | `od_seal` | Sigillo | odispel | - | implementata parzialmente | cerchio | - |
| L09 | `od_anomaly` | Anomalia | odispel | - | da verificare | cerchio | - |
| L10 | `od_void` | Vuoto | odispel | - | da verificare | cerchio | - |
| L11 | `od_bond` | Legame rituale | odispel | - | da verificare | cerchio | - |
| L12 | `od_dimension` | Frattura dimensionale | odispel | - | da verificare | cerchio | - |
| M01 | `faction_libracorp` | LIBRACORP — Bilancia-L | factions | light, dark, color, compact, large | implementata | codice:libracorp | - |
| M02 | `faction_rondini` | RONDINI | factions | light, dark, color, compact, large | implementata | codice:rondini | - |
| M03 | `faction_magabondi` | MAGABONDI | factions | light, dark, color, compact, large | implementata | codice:magabondi | - |
| M04 | `faction_kairos` | KAIROS | factions | light, dark, color, compact, large | implementata | codice:kairos | - |
