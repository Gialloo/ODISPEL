# ODISPEL, parte 5 di 6: le mosse (dati letti dal codice)

Sono 106 mosse; qui ci sono le 72 di base (le skill hanno 4 versioni I-IV, qui solo la prima: le altre aumentano la potenza).
Formato: id | NOME | tipo, costo in energia, bersaglio, effetti.
Tipi: basic (Attacco/Guardia), skill, ult (ultimate), reaction/rescue (reazioni con la Riserva).
Bersagli: enemy = il boss, self, ally = un alleato (il piu' ferito), allies = tutta la squadra.
Parole degli effetti: mult = moltiplicatore del danno sull'attacco; hits = numero di colpi; pierce = % di difesa ignorata; heal = cura (x attacco); shield = scudo; status = stato sul bersaglio (mark = marchio, bleed = sanguinamento, con durata in round); self_status = stato su chi lancia (guard = guardia, taunt = provocazione); debuff/ally_buff = calo o aumento di una statistica; cleanse = toglie gli stati negativi; energy = energia data; ammo/ammo_gain = munizioni usate/date; self_cost_hp = PV pagati da chi lancia; reserve = costo in Riserva; unique=nome = abilita' unica di quel personaggio; "x..y" = valore dalla versione I alla IV.
Le mosse con "unique" non si possono dare ad altri personaggi. Le ultimate degli ultimi personaggi (u_..._ult) sono uniche e spesso combinano piu' effetti.

attack | ATTACCO | basic costo 0 ->enemy mult=1.0
guard | GUARDIA | basic costo 0 ->self self_status={"guard":1} energy=1 ammo_gain=1
ricarica | RICARICA | skill costo 0 ->self ammo_gain=3 energy=1
schivata | SCHIVATA | reaction costo 0 reserve=1 ->self react=dodge
intercettazione | INTERCETTAZIONE | reaction costo 0 reserve=2 ->self react=intercept
soccorso | SOCCORSO | rescue costo 0 reserve=2 ->self react=rescue
interruzione | INTERRUZIONE | reaction costo 0 reserve=2 ->enemy react=interrupt
colpo_caricato | COLPO CARICATO | skill costo 2 ->enemy mult=2.0
marchio | MARCHIO | skill costo 1 ->enemy status={"mark":2} mult=0.5
provoca | PROVOCA | skill costo 1 ->self self_status={"taunt":1} shield=0.6
barriera | BARRIERA | skill costo 2 ->allies ally_buff={"atk":1} shield=1.0
cura | CURA | skill costo 2 ->ally heal=1.4
sacrificio | SACRIFICIO | skill costo 2 ->self self_status={"taunt":1} self_cost_hp=0.15 shield=1.9
purifica | PURIFICA | skill costo 1 ->ally cleanse=true heal=0.4
frattura | FRATTURA | skill costo 2 ->enemy debuff={"def":1} mult=0.9
intimidisci | INTIMIDISCI | skill costo 1 ->enemy debuff={"atk":1} mult=0.5
doppio_colpo | DOPPIO COLPO | skill costo 2 ->enemy hits=2 mult=0.9
colpo_mirato | COLPO MIRATO | skill costo 1 ->enemy ammo=1 pierce=50 mult=1.7
colpo_alla_testa | COLPO ALLA TESTA | skill costo 2 ->enemy ammo=2 pierce=50 mult=2.4
spezzatutto | SPEZZATUTTO | ult costo 0 ->enemy mult=4.5
bastione | BASTIONE | ult costo 0 ->allies ally_buff={"atk":1} shield=2.0
rinascita | RINASCITA | ult costo 0 ->allies cleanse=true ally_buff={"atk":1} heal=1.1
u_kira_a | TAGLIO SPETTRALE | skill costo 2 ->enemy mult=1.8 pierce=60 status={"mark":1} unique=kira
u_dax_a | ARIETE | skill costo 2 ->enemy mult=1.3 self_status={"taunt":1,"guard":1} unique=dax
u_elle_a | RESPIRO | skill costo 2 ->allies heal=0.9 energy=1 ally_buff={"atk":3} unique=elle
u_bruno_a | PARATA LAMPO | skill costo 1 ->ally shield=1.2 unique=bruno
u_nova_a | RAFFICA MARCHIANTE | skill costo 2 ->enemy mult=1.2 status={"mark":2,"bleed":2} unique=nova
u_mira_a | INIEZIONE | skill costo 2 ->ally heal=1.0 shield=0.6 cleanse=true ally_buff={"atk":3} unique=mira
u_rex_a | CARICA FURIOSA | skill costo 2 ->enemy mult=2.2 status={"bleed":2} unique=rex
u_ivo_a | SGAMBETTO | skill costo 1 ->enemy mult=0.8 status={"mark":1,"bleed":1} energy=1 unique=ivo
u_sera_a | ALA PROTETTIVA | skill costo 2 ->allies shield=1.2 ally_buff={"atk":3} unique=sera
u_sera_b | VENTO DI CODA | skill costo 2 ->allies heal=0.8 cleanse=true energy=1 unique=sera
u_eco_a | ECO RIPETUTO | skill costo 2 ->enemy mult=1.5 status={"mark":2} debuff={"spd":1} unique=eco
u_eco_b | FREQUENZA CRITICA | skill costo 3 ->enemy mult=2.5 pierce=40 debuff={"def":1} unique=eco
u_tana_a | BASTIONE VIVENTE | skill costo 2 ->allies shield=1.4 self_status={"taunt":1} unique=tana
u_dafne_a | MARCHIO | skill costo 1 ->enemy mult=0.4 status={"mark":1} unique=dafne
u_dafne_b | COLPO MIRATO | skill costo 1 ->enemy mult=1.7 ammo=1 crit_pm=200 debuff={"def":1} unique=dafne
u_dafne_c | COPERTURA | skill costo 0 ->self self_status={"hidden":1} shield=0.35 ammo_gain=2 energy=0 unique=dafne
coordinated_shot | COLPO COORDINATO | ult costo 0 ->enemy mult=2.9 ammo=1 status={"mark":3} crit_dmg_per_mark=110 crit_dmg_cap=650 debuff={"spd":1,"atk":1,"def":1} ally_buff={"atk":1,"spd":1} unique=dafne
u_angela_a | TORRETTA FUCILE | skill costo 2 ->enemy mult=0.6 ammo=1 status={"mark":1} summon=turret unique=angela
u_angela_b | DRONE MUNIZIONI | skill costo 3 ->enemy status={"mark":3} team_ammo=3 summon=drone unique=angela
u_angela_c | MITRAGLIATRICE | skill costo 2 ->enemy mult=0.85 ammo=3 hits=3 crit_pm=250 unique=angela
orbital_strike | RAGGIO ORBITALE | ult costo 0 ->enemy mult=3.2 status={"mark":1} consume_marks=0.15 unique=angela
u_nico_a | SEGNALE DI FUMO | skill costo 1 ->enemy mult=0.6 debuff={"atk":1} unique=nico
u_nico_b | PORTA APERTA | skill costo 2 ->allies shield=1.1 energy=1 unique=nico
u_tana_b | MURO TOTALE | skill costo 2 ->self shield=2.0 self_status={"taunt":1,"guard":1} unique=tana
u_kira_b | PUGNO INCANALATO | skill costo 1 ->enemy mult=1.45 unique=kira
u_vesper_b | TAGLIO D'OMBRA | skill costo 2 ->enemy mult=1.3 debuff={"def":1} unique=vesper
u_yuna_b | SCATTO VETTORIALE | skill costo 2 ->enemy mult=0.55 hits=3 unique=yuna
u_oriel_b | INTERDIZIONE | skill costo 1 ->ally shield=1.0 unique=oriel
u_flux_b | SCARICA DIRETTA | skill costo 1 ->enemy mult=1.35 unique=flux
u_lyra_b | ESECUZIONE CALIBRATA | skill costo 2 ->enemy mult=1.7 pierce=25 unique=lyra
u_moro_a | RITORSIONE | skill costo 2 ->enemy mult=1.0 self_status={"guard":1} unique=moro
u_moro_ult | LEGGE DEL CONTRACCOLPO | ult costo 0 ->allies shield=1.6 unique=moro
u_vesper_a | TAGLIO PREDATORIO | skill costo 2 ->enemy mult=1.5 status={"mark":1} unique=vesper
u_vesper_ult | ECLISSI CREMISI | ult costo 0 ->enemy mult=3.4 pierce=30 unique=vesper
u_nami_a | RIPARO IMPROVVISATO | skill costo 1 ->ally shield=0.8 ally_buff={"atk":3} unique=nami
u_nami_ult | CERCHIO SICURO | ult costo 0 ->allies shield=1.4 unique=nami
u_oriel_a | PROTOCOLLO DI SOCCORSO | skill costo 2 ->ally heal=0.9 shield=0.5 cleanse=true ally_buff={"atk":2} unique=oriel
u_oriel_ult | RIFUGIO ASSOLUTO | ult costo 0 ->allies shield=2.0 cleanse=true unique=oriel
u_silex_a | FRATTURA MINERALE | skill costo 2 ->enemy mult=1.2 debuff={"def":1} unique=silex
u_silex_ult | FORTEZZA GEOMETRICA | ult costo 0 ->allies shield=1.8 unique=silex
u_yuna_a | PASSO FULMINEO | skill costo 1 ->enemy mult=1.0 status={"mark":1} unique=yuna
u_yuna_ult | LAMA DEL FUTURO | ult costo 0 ->enemy mult=3.0 pierce=25 unique=yuna
u_rhea_a | RICOMPOSIZIONE | skill costo 2 ->ally heal=1.2 ally_buff={"atk":3} unique=rhea
u_rhea_ult | ALBA CONDIVISA | ult costo 0 ->allies heal=1.1 cleanse=true unique=rhea
u_flux_a | RAFFICA SINCRONIZZATA | skill costo 2 ->enemy mult=0.65 hits=2 status={"mark":1} unique=flux
u_flux_ult | PUNTO DI ROTTURA | ult costo 0 ->enemy mult=3.0 pierce=30 unique=flux
u_cato_a | IMPATTO DI CONTENIMENTO | skill costo 1 ->enemy mult=0.9 self_status={"guard":1} unique=cato
u_cato_ult | LINEA INVALICABILE | ult costo 0 ->allies shield=1.5 unique=cato
u_lyra_a | MARCHIO DI PRIORITA' | skill costo 1 ->enemy mult=0.6 status={"mark":2} unique=lyra
u_lyra_ult | SENTENZA COORDINATA | ult costo 0 ->enemy mult=2.8 status={"mark":1} debuff={"def":1} unique=lyra
