class_name Moves
## Tabella delle mosse. Ogni forma dell'arma ha un ruolo preciso:
##   BLADE  = velocità e catene, IMPACT = forza e lancio, VECTOR = portata e aggancio.
## La forma non si sceglie: la decide la mossa (contesto). Tempi in secondi.

enum Form { BLADE, IMPACT, VECTOR }

const FORM_NAME := ["BLADE", "IMPACT", "VECTOR"]
## Suono per forma: BLADE acuta, IMPACT grave, VECTOR metallica.
const FORM_PITCH := [1.3, 0.78, 1.05]
const FORM_COLOR := [Color(0.35, 0.95, 1.0), Color(1.0, 0.55, 0.15), Color(0.8, 0.45, 1.0)]

## Campi:
## form, dur, hit_from, hit_to, cancel (da quando si può interrompere con schivata o mossa successiva),
## lunge (velocità in avanti fino al colpo), reach, arc (gradi), dmg, poise, knock, launch,
## stop (hitstop ms), shake, sound, next (mossa successiva della catena), air
const DATA := {
	"blade_1": {"form": Form.BLADE, "dur": 0.26, "hit_from": 0.06, "hit_to": 0.13, "cancel": 0.13,
		"lunge": 7.0, "reach": 2.4, "arc": 130.0, "dmg": 8.0, "poise": 10.0, "knock": 2.5, "launch": 0.0,
		"stop": 32.0, "shake": 0.08, "sound": "colpo", "next": "blade_2", "swing": -1.0},
	"blade_2": {"form": Form.BLADE, "dur": 0.26, "hit_from": 0.06, "hit_to": 0.13, "cancel": 0.13,
		"lunge": 7.0, "reach": 2.4, "arc": 130.0, "dmg": 9.0, "poise": 10.0, "knock": 2.5, "launch": 0.0,
		"stop": 32.0, "shake": 0.08, "sound": "colpo", "next": "blade_3", "swing": 1.0},
	"blade_3": {"form": Form.BLADE, "dur": 0.38, "hit_from": 0.07, "hit_to": 0.24, "cancel": 0.25, "multi": 2,
		"lunge": 8.0, "reach": 2.6, "arc": 150.0, "dmg": 10.0, "poise": 14.0, "knock": 3.0, "launch": 0.0,
		"stop": 40.0, "shake": 0.12, "sound": "colpo", "next": "impact_finisher", "swing": -1.0},
	# quarto colpo della catena: l'arma si trasforma da sola in IMPACT
	"impact_finisher": {"form": Form.IMPACT, "dur": 0.58, "hit_from": 0.20, "hit_to": 0.30, "cancel": 0.36,
		"lunge": 9.0, "reach": 2.9, "arc": 170.0, "dmg": 24.0, "poise": 45.0, "knock": 11.0, "launch": 2.0,
		"stop": 140.0, "shake": 0.65, "sound": "colpo_finale", "next": "", "swing": 1.0, "ring": 3.0},
	# pesante a terra (tenere premuto): lancia in aria
	"impact_launcher": {"form": Form.IMPACT, "dur": 0.55, "hit_from": 0.20, "hit_to": 0.30, "cancel": 0.32,
		"lunge": 4.0, "reach": 2.7, "arc": 140.0, "dmg": 16.0, "poise": 35.0, "knock": 1.0, "launch": 11.5,
		"stop": 110.0, "shake": 0.5, "sound": "colpo_forte", "next": "", "swing": 0.0, "ring": 2.4, "follow": true},
	# pesante in aria: schianto a terra con onda d'urto
	"impact_slam": {"form": Form.IMPACT, "dur": 0.70, "hit_from": 0.0, "hit_to": 0.0, "cancel": 0.40,
		"lunge": 0.0, "reach": 3.4, "arc": 360.0, "dmg": 20.0, "poise": 40.0, "knock": 8.0, "launch": 4.0,
		"stop": 130.0, "shake": 0.70, "sound": "colpo_finale", "next": "", "swing": 0.0, "ring": 3.4, "slam": true},
	# leggero in aria: tiene sospesi te e il nemico
	"blade_air_1": {"form": Form.BLADE, "dur": 0.28, "hit_from": 0.06, "hit_to": 0.14, "cancel": 0.15,
		"lunge": 3.0, "reach": 2.5, "arc": 140.0, "dmg": 7.0, "poise": 8.0, "knock": 1.0, "launch": 4.5,
		"stop": 45.0, "shake": 0.10, "sound": "colpo", "next": "blade_air_2", "swing": -1.0, "air": true},
	"blade_air_2": {"form": Form.BLADE, "dur": 0.28, "hit_from": 0.06, "hit_to": 0.14, "cancel": 0.15,
		"lunge": 3.0, "reach": 2.5, "arc": 140.0, "dmg": 7.0, "poise": 8.0, "knock": 1.0, "launch": 4.5,
		"stop": 45.0, "shake": 0.10, "sound": "colpo", "next": "blade_air_3", "swing": 1.0, "air": true},
	"blade_air_3": {"form": Form.BLADE, "dur": 0.34, "hit_from": 0.08, "hit_to": 0.16, "cancel": 0.18,
		"lunge": 3.0, "reach": 2.6, "arc": 150.0, "dmg": 9.0, "poise": 12.0, "knock": 2.0, "launch": 5.0,
		"stop": 60.0, "shake": 0.16, "sound": "colpo_forte", "next": "", "swing": -1.0, "air": true},
	# bersaglio lontano: VECTOR si allunga, aggancia e trascina il nemico verso di te
	"vector_lash": {"form": Form.VECTOR, "dur": 0.42, "hit_from": 0.12, "hit_to": 0.20, "cancel": 0.24,
		"lunge": 0.0, "reach": 11.0, "arc": 24.0, "dmg": 6.0, "poise": 20.0, "knock": 0.0, "launch": 0.0,
		"stop": 70.0, "shake": 0.20, "sound": "critico", "next": "blade_2", "swing": 0.0, "pull": true, "line": true},
	# stick all'indietro con un nemico a media distanza: VECTOR frusta e tira il nemico oltre la lama
	"vector_reel": {"form": Form.VECTOR, "dur": 0.40, "hit_from": 0.10, "hit_to": 0.18, "cancel": 0.22,
		"lunge": 0.0, "reach": 6.5, "arc": 60.0, "dmg": 8.0, "poise": 22.0, "knock": 0.0, "launch": 2.5,
		"stop": 60.0, "shake": 0.18, "sound": "critico", "next": "blade_2", "swing": 1.0, "pull": true, "line": true},
	# attacco subito dopo una schivata: VECTOR spazza tutto intorno
	"vector_sweep": {"form": Form.VECTOR, "dur": 0.46, "hit_from": 0.10, "hit_to": 0.24, "cancel": 0.28,
		"lunge": 5.0, "reach": 3.9, "arc": 360.0, "dmg": 11.0, "poise": 18.0, "knock": 6.0, "launch": 0.0,
		"stop": 70.0, "shake": 0.25, "sound": "colpo_forte", "next": "vector_whirl", "swing": 2.0},
	# attacco durante il rallentamento della schivata perfetta
	"impact_counter": {"form": Form.IMPACT, "dur": 0.55, "hit_from": 0.12, "hit_to": 0.22, "cancel": 0.30,
		"lunge": 14.0, "reach": 3.0, "arc": 160.0, "dmg": 30.0, "poise": 70.0, "knock": 12.0, "launch": 3.0,
		"stop": 150.0, "shake": 0.75, "sound": "colpo_finale", "next": "", "swing": 1.0, "ring": 3.0},

	# ---- 0.7: mosse nuove. Regola unica e facile: STICK DI LATO durante la combo = variante.
	# BLADE in corsa: affondo lungo che attraversa il nemico
	"blade_dash": {"form": Form.BLADE, "dur": 0.34, "hit_from": 0.05, "hit_to": 0.18, "cancel": 0.2,
		"lunge": 17.0, "reach": 2.5, "arc": 100.0, "dmg": 11.0, "poise": 16.0, "knock": 4.0, "launch": 0.0,
		"stop": 45.0, "shake": 0.14, "sound": "colpo", "next": "blade_2", "swing": 0.0, "through": true},
	# BLADE con stick di lato nella combo: doppia piroetta tutto intorno
	"blade_spin": {"form": Form.BLADE, "dur": 0.40, "hit_from": 0.06, "hit_to": 0.26, "cancel": 0.27, "multi": 2,
		"lunge": 4.0, "reach": 2.8, "arc": 360.0, "dmg": 8.0, "poise": 12.0, "knock": 3.5, "launch": 0.0,
		"stop": 38.0, "shake": 0.12, "sound": "colpo", "next": "blade_3", "swing": 2.0},
	# IMPACT al posto del finale, con stick di lato: martellata a terra che fa saltare tutto intorno
	"impact_breaker": {"form": Form.IMPACT, "dur": 0.62, "hit_from": 0.24, "hit_to": 0.32, "cancel": 0.40,
		"lunge": 3.0, "reach": 3.8, "arc": 360.0, "dmg": 18.0, "poise": 50.0, "knock": 5.0, "launch": 8.0,
		"stop": 130.0, "shake": 0.7, "sound": "colpo_finale", "next": "", "swing": 1.0, "ring": 3.8},
	# IMPACT pesante in corsa: balzo in avanti e martellata all'atterraggio
	"impact_hammer": {"form": Form.IMPACT, "dur": 0.66, "hit_from": 0.0, "hit_to": 0.0, "cancel": 0.38,
		"lunge": 11.0, "reach": 3.2, "arc": 360.0, "dmg": 22.0, "poise": 55.0, "knock": 9.0, "launch": 5.0,
		"stop": 130.0, "shake": 0.7, "sound": "colpo_finale", "next": "", "swing": 0.0, "ring": 3.2, "slam": true, "leap": 7.5},
	# VECTOR in aria verso un nemico lontano: la catena ti porta da lui e continui la combo aerea
	"vector_zip": {"form": Form.VECTOR, "dur": 0.40, "hit_from": 0.16, "hit_to": 0.26, "cancel": 0.27,
		"lunge": 0.0, "reach": 2.6, "arc": 120.0, "dmg": 8.0, "poise": 14.0, "knock": 0.5, "launch": 4.5,
		"stop": 60.0, "shake": 0.16, "sound": "critico", "next": "blade_air_2", "swing": 0.0, "air": true, "zip": true},
	# VECTOR dopo la spazzata (schiva, attacca, attacca): vortice che risucchia tutti verso di te
	"vector_whirl": {"form": Form.VECTOR, "dur": 0.50, "hit_from": 0.10, "hit_to": 0.30, "cancel": 0.32,
		"lunge": 0.0, "reach": 5.5, "arc": 360.0, "dmg": 9.0, "poise": 20.0, "knock": 0.0, "launch": 2.0,
		"stop": 70.0, "shake": 0.25, "sound": "critico", "next": "impact_finisher", "swing": 2.0, "pull": true},
}

static func get_move(id: String) -> Dictionary:
	return DATA[id]
