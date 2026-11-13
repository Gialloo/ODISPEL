class_name PgEngine
extends RefCounted

# PROVA GREZZA del core CONTROSEGNALE v2: il Manichino da prova contro un nemico, solo logica.
# Progetto: /mnt/project-files/odispel/v3/combat_system/CONTROSEGNALE_CORE_v2.md (sezioni «Prova grezza» e «stampo»).
# Il Manichino non ha regole personali: se la prova non diverte così, nessun personaggio la salverà (Regola zero).
# Mondo a una dimensione (x): il giocatore a sinistra, il nemico a destra, un muro per lato.
# Gesti: tocco, verso, via, su, giu, postura. Tutto a passo fisso, deterministico (stesso seme, stessa partita).

const TICK: float = 1.0 / 60.0
const WALL_L: float = 0.0
const WALL_R: float = 12.0
const BODY: float = 1.0                  # distanza minima tra i due corpi
const REACH: float = 1.8                 # portata dei colpi a mano

# ---------------------------------------------------------------- CONTRO
const WIN: float = 0.32                  # CONTRO buono: negli ultimi 320 ms prima dell'impatto
const PERFECT: float = 0.10              # CONTRO perfetto: negli ultimi 100 ms
const BUFFER: float = 0.10               # un gesto 100 ms prima della finestra conta lo stesso
const WIDE_MULT: float = 1.5             # finestra AMPIA dalle impostazioni
const INPUT_LIFE: float = 0.25           # un gesto che non si può fare subito resta in memoria per 250 ms

# ---------------------------------------------------------------- barre
const HP_MAX: float = 140.0
const FIATO_MAX: float = 100.0
const SEG_MAX: float = 100.0
const ENEMY_HP: float = 2200.0
const CANCEL_COST: float = 12.0          # annullare una mossa nel lampo bianco
const PIANO_COST: float = 30.0
const RESPIRO: float = 15.0              # FIATO a fine catena (almeno 3 colpi a segno)
const SEG_REGEN: float = 12.0            # il SEGNALE torna se non lo metti sotto pressione...
const SEG_REGEN_AFTER: float = 2.0       # ...dopo 2 s
const CROLLO_TIME: float = 4.0
const BLACKOUT_FRAC: float = 0.15
const SCROLLATA_HITS: int = 5            # dopo 5 colpi di fila senza poter agire il nemico si scrolla di dosso

# ---------------------------------------------------------------- mosse del Manichino (posture: rosso pesante, blu rapido)
const MOVES: Dictionary = {
	"colpo": {"dur": 0.36, "hit": 0.10, "cancel": 0.14, "dmg": 10.0, "seg": 1.5, "push": 0.35, "adv": 0.5},
	"affondo": {"dur": 0.50, "hit": 0.16, "cancel": 0.24, "dmg": 12.0, "seg": 5.0, "push": 2.4, "adv": 2.6},
	"lancio": {"dur": 0.55, "hit": 0.16, "cancel": 0.24, "dmg": 10.0, "seg": 4.0, "push": 0.2, "adv": 0.4},
	"aria": {"dur": 0.30, "hit": 0.10, "cancel": 0.14, "dmg": 9.0, "seg": 2.0, "push": 0.25, "adv": 0.3},
	"schiacciata": {"dur": 0.50, "hit": 0.18, "cancel": 0.30, "dmg": 18.0, "seg": 6.0, "push": 0.6, "adv": 0.4},
	"contro": {"dur": 0.38, "hit": 0.0, "cancel": 0.12, "dmg": 15.0, "seg": 0.0, "push": 1.4, "adv": 0.0},
	"blackout": {"dur": 1.00, "hit": 0.45, "cancel": 9.0, "dmg": 0.0, "seg": 0.0, "push": 0.0, "adv": 1.0},
	# aggiunte del 12/11 sera (decisioni dell'autore: carica, montante, cambio personaggio)
	"montante": {"dur": 0.50, "hit": 0.16, "cancel": 0.24, "dmg": 12.0, "seg": 4.0, "push": 0.2, "adv": 0.5},
	"scatto": {"dur": 0.55, "hit": 0.18, "cancel": 0.30, "dmg": 16.0, "seg": 6.0, "push": 2.0, "adv": 3.5},
	"schianto": {"dur": 0.60, "hit": 0.20, "cancel": 0.34, "dmg": 20.0, "seg": 6.0, "push": 1.2, "adv": 0.8},
	"entrata": {"dur": 0.45, "hit": 0.14, "cancel": 0.20, "dmg": 8.0, "seg": 2.0, "push": 0.6, "adv": 2.4},
	# combo d'attacco (13/11, autore: «aggiungi combo attacco»): finali della catena, stessi gesti di sempre
	"sfondamento": {"dur": 0.52, "hit": 0.15, "cancel": 0.26, "dmg": 16.0, "seg": 5.0, "push": 3.2, "adv": 2.8},   # colpo, colpo, colpo, scorri →
	"falciata": {"dur": 0.46, "hit": 0.13, "cancel": 0.22, "dmg": 9.0, "seg": 3.0, "push": 0.3, "adv": 0.6},        # colpo, scorri ↓: a terra
}
# ---------------------------------------------------------------- carica e cambio personaggio (12/11 sera)
const HOLD: float = 0.22                 # oltre 220 ms il tocco diventa carica
const CHARGE_LV: Array = [0.0, 0.40, 0.85]   # livelli contati da quando parte la carica
const HOVER_MAX: float = 1.0             # in aria: sospeso al massimo un secondo mentre carichi la schiacciata
const SWITCH_CD: float = 2.0
const PARTY_ENEMY_MULT: float = 1.5
const PARTY_ENEMY_DMG: float = 1.35
const DEFENSE_COST: float = 15.0        # il CAMBIO IN DIFESA consuma FIATO: non si fa a caso
# squadra a cambio rapido (un solo personaggio in campo, come nei giochi a cambio istantaneo): per la prova, Manichini neutri
const PARTY: Array = [
	{"id": "a", "name": "MANICHINO A", "posture": "rosso"},
	{"id": "b", "name": "MANICHINO B", "posture": "blu"},
	{"id": "c", "name": "MANICHINO C", "posture": "rosso"},
	{"id": "d", "name": "MANICHINO D", "posture": "blu"},
]
const POSTURE: Dictionary = {
	"rosso": {"dmg": 1.4, "seg": 1.5, "speed": 0.8, "push": 1.5},
	"blu": {"dmg": 0.8, "seg": 0.8, "speed": 1.25, "push": 0.7},
}
const DODGE_DUR: float = 0.36
const DODGE_IFRAMES: float = 0.22
const DODGE_DIST: float = 1.6
const DODGE_PERFECT: float = 0.12
const DODGE_COOLDOWN: float = 0.45       # niente passi indietro a raffica: schivare è una scelta
const JUMP_AIR: float = 0.65
const LAUNCH_AIR: float = 1.0
const JUGGLE_MAX: int = 4

# ---------------------------------------------------------------- il nemico della prova (linguaggio comune: AFFONDO e SPAZZATA)
# AFFONDO (freccia, ha un colore): scorri verso = CONTRO. SPAZZATA (onda bassa): scorri su = salto.
const ATTACKS: Dictionary = {
	"affondo": {"windup": 0.95, "reach": 3.4, "dmg": 12.0, "lunge": 1.2},
	"spazzata": {"windup": 1.00, "reach": 3.6, "dmg": 10.0, "lunge": 0.4},
}
const STRINGS: Array = [
	[["affondo", "rosso"]],
	[["affondo", "blu"]],
	[["spazzata", ""]],
	[["affondo", "rosso"], ["spazzata", ""]],
	[["affondo", "blu"], ["affondo", "rosso"]],
	[["spazzata", ""], ["affondo", "blu"]],
	[["affondo", "rosso"], ["affondo", "rosso"], ["spazzata", ""]],
]
const STRING_GAP: float = 0.45
const ENEMY_SPEED: float = 2.2

# ---------------------------------------------------------------- Registro (le scoperte che il gioco non spiega)
const DISCOVERIES: Array = [
	["contro", "CONTRO"], ["contro_perfetto", "CONTRO PERFETTO"], ["frequenza", "CONTRO DI FREQUENZA"],
	["muro", "AL MURO"], ["annullo", "ANNULLAMENTO"], ["salto_castigo", "SALTO E CASTIGO"],
	["giocoliere", "GIOCOLIERE"], ["schiacciata", "SCHIACCIATA"], ["catena_piena", "CATENA PIENA"],
	["cambio_in_catena", "CAMBIO IN CATENA"], ["piano_contro", "PIANO E CONTRO"], ["blackout", "BLACKOUT"],
	["contro_caricato", "CONTRO CARICATO"], ["montante", "MONTANTE"], ["schianto", "SCHIACCIATA CARICATA"],
	["staffetta", "STAFFETTA"], ["cambio_difesa", "CAMBIO IN DIFESA"],
	["sfondamento", "SFONDAMENTO"], ["falciata", "FALCIATA"],
]

var rng := RandomNumberGenerator.new()
var wide: bool = false
var time: float = 0.0
var _acc: float = 0.0
var events: Array = []
var over: String = ""                    # "", "vittoria", "sconfitta"
var found: Dictionary = {}

# giocatore
var px: float = 4.0
var hp: float = HP_MAX
var fiato: float = 50.0
var posture: String = "rosso"
var st: String = "idle"                  # idle, atk, dodge, hurt
var st_t: float = 0.0
var move: Dictionary = {}                # mossa in corso: id, dur, hit, cancel, done, landed
var chain: int = 0
var chain_hits: int = 0
var chain_idle: float = 0.0
var p_air: float = 0.0
var iframes: float = 0.0
var dodge_start: float = -9.0
var dodge_ready: float = 0.0
var esposto_until: float = -1.0
var pending: Dictionary = {}             # gesto in memoria
var plan: Array = []
var plan_active: bool = false
var plan_countered: bool = false

# nemico
var ex: float = 7.0
var ehp: float = ENEMY_HP
var seg: float = SEG_MAX
var est: String = "idle"                 # idle, tele, rec, stun, air, down, crollo, dead
var est_t: float = 0.0
var eatk: Dictionary = {}                # kind, color, impact (secondi dal via del MIRINO), t
var estring: Array = []
var e_air: float = 0.0
var juggle: int = 0
var castigo_until: float = -1.0
var last_seg_loss: float = 0.0
var hits_in_row: int = 0
var walled: bool = false                 # un solo AL MURO finché il nemico non torna ad attaccare
var phase: int = 0
var idle_wait: float = 1.2

# squadra e carica
var party: Array = []                    # {id, name, hp, maxhp, posture, ko}; hp e posture qui sopra sono quelli di chi è in campo
var active: int = 0
var switch_ready: float = 0.0
var holding: bool = false
var hold_t: float = 0.0
var charge_t: float = 0.0


func _init(seed_v: int = 7, party_size: int = 1) -> void:
	rng.seed = seed_v
	for i in clampi(party_size, 1, PARTY.size()):
		party.append({"id": PARTY[i]["id"], "name": PARTY[i]["name"], "hp": HP_MAX, "maxhp": HP_MAX, "posture": PARTY[i]["posture"], "ko": false})
	posture = party[0]["posture"]
	if party.size() > 1:
		ehp = ENEMY_HP * PARTY_ENEMY_MULT      # con la squadra hai più vite: il nemico ne ha di più


# ================================================================ comandi

func input(g: String) -> void:
	if over != "":
		return
	if g == "postura":
		_switch_posture()
		return
	if g == "cambio":
		switch_to(next_alive())
		return
	if plan_active:
		# il CONTRO col pollice sospende il PIANO senza cancellarlo; ogni altro gesto lo cancella
		if g == "verso" and _counter_time() >= 0.0:
			plan_countered = true
		else:
			plan.clear()
			plan_active = false
			_ev({"type": "piano_fine", "why": "mani"})
	if not _try(g, false):
		pending = {"g": g, "t": time}


func press_attack() -> void:
	if over != "":
		return
	holding = true
	hold_t = 0.0


func cancel_press() -> void:
	holding = false


func release_attack() -> void:
	if not holding:
		return
	holding = false
	if st == "charge":
		_release_charge()
	elif st == "hover":
		_release_hover()
	else:
		input("tocco")


func charge_level() -> int:
	var lv: int = 0
	for i in CHARGE_LV.size():
		if charge_t >= float(CHARGE_LV[i]):
			lv = i + 1
	return lv if st in ["charge", "hover"] else 0


func switch_to(i: int, forced: bool = false) -> bool:
	# CAMBIO: esce chi è in campo, entra un altro. Nel lampo bianco = STAFFETTA; sul colpo nemico = CAMBIO IN DIFESA
	if over != "" or i == active or i < 0 or i >= party.size() or party[i]["ko"] or time < switch_ready:
		return false
	var relay: bool = can_cancel_now() and not forced
	var defend: bool = not forced and est == "tele" and float(eatk["impact"]) - float(eatk["t"]) <= win_len() + BUFFER and fiato >= DEFENSE_COST
	if defend:
		fiato -= DEFENSE_COST
	party[active]["hp"] = hp
	party[active]["posture"] = posture
	var old: int = active
	active = i
	hp = float(party[i]["hp"])
	posture = party[i]["posture"]
	switch_ready = time + SWITCH_CD
	holding = false
	charge_t = 0.0
	pending = {}
	st = "idle"
	move = {}
	chain = 0
	p_air = 0.0
	_ev({"type": "cambio", "from": old, "to": i, "staffetta": relay, "difesa": defend})
	if defend:
		# chi entra para il colpo al posto tuo: vale come un CONTRO (sulla SPAZZATA salta e colpisce)
		_found("cambio_difesa")
		_do_counter(0, true)
		return true
	if relay and ex - px <= REACH + 2.6:
		# solo nella STAFFETTA chi entra porta un colpo d'entrata; il cambio normale è un cambio e basta
		_start_move("entrata")
		move["relay"] = relay
	return true


func next_alive() -> int:
	for k in range(1, party.size() + 1):
		var j: int = (active + k) % party.size()
		if not party[j]["ko"]:
			return j
	return -1


func start_plan(actions: Array) -> bool:
	if fiato < PIANO_COST or actions.is_empty() or over != "":
		return false
	fiato -= PIANO_COST
	plan = actions.duplicate()
	plan_active = true
	plan_countered = false
	pending = {}
	_ev({"type": "piano_via", "n": plan.size()})
	return true


func preview() -> Dictionary:
	# cosa vede il giocatore nel PIANO: il prossimo colpo e fra quanto arriva
	var d: Dictionary = {"dist": ex - px, "enemy": est}
	if est == "tele":
		d["kind"] = eatk["kind"]
		d["color"] = eatk["color"]
		d["left"] = float(eatk["impact"]) - float(eatk["t"])
	return d


func step(real_dt: float) -> void:
	_acc += minf(real_dt, 0.1)
	while _acc >= TICK:
		_acc -= TICK
		_tick()


func take_events() -> Array:
	var e: Array = events
	events = []
	return e


func can_cancel_now() -> bool:
	return st == "atk" and bool(move.get("landed", false)) and st_t >= float(move["cancel"]) and st_t < float(move["dur"])


func danger() -> Dictionary:
	# il colpo nemico in arrivo e quanto manca, per il MIRINO a schermo
	if est != "tele":
		return {}
	return {"kind": eatk["kind"], "color": eatk["color"], "left": float(eatk["impact"]) - float(eatk["t"]), "impact": eatk["impact"]}


func win_len() -> float:
	return WIN * (WIDE_MULT if wide else 1.0)


# ================================================================ gesti

func _counter_time() -> float:
	# >= 0: secondi all'impatto di un AFFONDO dentro finestra (+ memoria). -1: nessun CONTRO possibile ora
	if est != "tele" or eatk["kind"] != "affondo":
		return -1.0
	var left: float = float(eatk["impact"]) - float(eatk["t"])
	return left if left <= win_len() + BUFFER else -1.0


func _try(g: String, from_plan: bool) -> bool:
	if st == "hurt" or over != "":
		return false
	# CONTRO e BLACKOUT hanno la precedenza su tutto quando sono possibili
	if g == "verso" and est == "crollo" and _free(from_plan, "blackout"):
		_start_move("blackout")
		_ev({"type": "blackout_via"})
		return true
	if g == "verso" and _counter_time() >= 0.0 and _free(from_plan, "contro"):
		_do_counter()
		return true
	match g:
		"tocco":
			var id: String = "aria" if p_air > 0.0 else "colpo"
			if id == "colpo" and chain == 2 and chain_idle >= 0.25 and chain_idle <= 0.9:
				id = "montante"       # colpo, colpo, PAUSA, colpo
			if not _free(from_plan, id):
				return false
			if id == "colpo":
				chain = chain + 1 if chain_idle < (0.25 if party.size() > 1 else 0.5) and chain < 4 else 1
				if chain == 4:
					_found("catena_piena")
			_start_move(id)
			return true
		"verso":
			if _after_colpo(3) and _free(from_plan, "sfondamento"):
				_found("sfondamento")
				_start_move("sfondamento")
				return true
			if not _free(from_plan, "affondo"):
				return false
			if est == "tele" and eatk["kind"] == "affondo":
				esposto_until = time + float(eatk["impact"]) - float(eatk["t"]) + 0.05
				_ev({"type": "troppo_presto"})
			_start_move("affondo")
			return true
		"su":
			if p_air > 0.0:
				return false
			if (ex - px) <= REACH + 0.3 and est in ["idle", "rec", "stun", "down"]:
				if not _free(from_plan, "lancio"):
					return false
				_start_move("lancio")
				return true
			if not _free(from_plan, "salto"):
				return false
			_end_move()
			p_air = JUMP_AIR
			_ev({"type": "salto"})
			return true
		"giu":
			if p_air <= 0.0:
				# a terra, dopo un colpo: FALCIATA, il nemico va giù (poi ↑ lo lancia)
				if _after_colpo(1) and _free(from_plan, "falciata"):
					_start_move("falciata")
					return true
				return false
			if not _free(from_plan, "schiacciata"):
				return false
			_start_move("schiacciata")
			return true
		"carica":
			# dal PIANO: una carica di secondo livello già pronta
			if p_air > 0.0 or not _free(from_plan, "scatto"):
				return false
			_end_move()
			st = "charge"
			charge_t = float(CHARGE_LV[1])
			_release_charge()
			return true
		"cambio":
			return switch_to(next_alive())
		"via":
			if p_air > 0.0:
				return false
			if st == "charge" and time >= dodge_ready:
				# lo scarto annulla la carica: è la via d'uscita se il nemico ti anticipa
				st = "idle"
				charge_t = 0.0
				holding = false
				_ev({"type": "carica_annullata"})
			if time < dodge_ready or not _free(from_plan, "via"):
				return false
			_end_move()
			st = "dodge"
			st_t = 0.0
			iframes = DODGE_IFRAMES
			dodge_start = time
			px = maxf(WALL_L, px - DODGE_DIST)
			_ev({"type": "passo_indietro"})
			return true
	return false


func _after_colpo(n: int) -> bool:
	# la catena è viva: un colpo in corso o appena finito, con almeno n colpi messi in fila
	if chain < n:
		return false
	if st == "atk":
		return move.get("id", "") == "colpo"
	return st == "idle" and chain_idle < 0.5


func _free(from_plan: bool, next_id: String) -> bool:
	# si può agire ora? da fermo sempre; dentro una mossa solo nel lampo bianco (annullamento)
	if st == "idle":
		return true
	if st in ["dodge", "hurt", "charge", "hover"]:
		return false
	if st != "atk" or not can_cancel_now():
		return false
	var natural: bool = (next_id in ["colpo", "montante", "sfondamento", "falciata"] and move["id"] == "colpo") \
		or (next_id in ["aria", "schiacciata"] and move["id"] in ["aria", "lancio", "montante"]) \
		or move["id"] in ["contro", "entrata"] or next_id == "blackout"
	if natural or from_plan:
		return true
	if fiato < CANCEL_COST:
		return false
	fiato -= CANCEL_COST
	_found("annullo")
	_ev({"type": "annullo", "from": move["id"], "to": next_id})
	return true


func _switch_posture() -> void:
	posture = "blu" if posture == "rosso" else "rosso"
	if st == "atk" and chain > 0:
		_found("cambio_in_catena")
	_ev({"type": "postura", "posture": posture})


func _start_move(id: String, lv: int = 0) -> void:
	var m: Dictionary = MOVES[id].duplicate()
	m["lv"] = lv
	if id == "scatto":
		m["adv"] = 3.0 + lv
		m["dmg"] = [16.0, 16.0, 26.0, 40.0][lv]
		m["seg"] = [6.0, 6.0, 10.0, 16.0][lv]
		m["push"] = [2.0, 2.0, 3.0, 4.0][lv]
	if id == "schianto":
		m["dmg"] = 20.0 + 12.0 * lv
		m["seg"] = 6.0 + 5.0 * lv
	var p: Dictionary = POSTURE[posture]
	var sp: float = float(p["speed"]) if id in ["colpo", "aria", "affondo"] else 1.0
	m["dur"] = float(m["dur"]) / sp
	m["hit"] = float(m["hit"]) / sp
	m["cancel"] = float(m["cancel"]) / sp
	m["id"] = id
	m["done"] = false
	m["landed"] = false
	m["chain"] = chain if id == "colpo" else 0
	move = m
	st = "atk"
	st_t = 0.0
	if id != "colpo":
		chain = 0
	if id == "lancio" or id == "montante":
		p_air = 0.0
	if id == "blackout" or id == "contro":
		iframes = float(m["dur"])
	_ev({"type": "mossa", "id": id, "posture": posture, "chain": m["chain"], "lv": lv})


func _end_move() -> void:
	if st == "atk" and move.get("id", "") == "colpo" and chain_hits >= 3 and chain >= 3:
		_respiro()
	st = "idle"
	st_t = 0.0
	move = {}


func _respiro() -> void:
	fiato = minf(FIATO_MAX, fiato + RESPIRO)
	chain_hits = 0
	_ev({"type": "respiro"})


func _release_charge() -> void:
	var lv: int = maxi(1, charge_level())
	charge_t = 0.0
	st = "idle"
	# rilasciata a tempo su un AFFONDO: CONTRO CARICATO
	if _counter_time() >= 0.0:
		_do_counter(lv)
		return
	if est == "tele" and eatk["kind"] == "affondo":
		esposto_until = time + float(eatk["impact"]) - float(eatk["t"]) + 0.05
		_ev({"type": "troppo_presto"})
	_start_move("scatto", lv)


func _release_hover() -> void:
	var lv: int = maxi(1, charge_level())
	charge_t = 0.0
	st = "idle"
	_start_move("schianto", lv)


func _do_counter(lv: int = 0, by_switch: bool = false) -> void:
	var left: float = float(eatk["impact"]) - float(eatk["t"])
	var perfect: bool = left <= PERFECT * (WIDE_MULT if wide else 1.0)
	var freq: bool = eatk["color"] == posture and not by_switch
	_start_move("contro", lv)
	move["landed"] = true
	move["done"] = true
	var s: float = 20.0 if perfect else 14.0
	if freq:
		s *= 2.5
	if lv > 0:
		s *= 1.4 + 0.3 * lv
		_found("contro_caricato")
	fiato = minf(FIATO_MAX, fiato + (18.0 if perfect else 10.0))
	_found("contro")
	if perfect:
		_found("contro_perfetto")
	if freq:
		_found("frequenza")
	if plan_countered:
		_found("piano_contro")
	estring.clear()
	_ev({"type": "contro", "perfect": perfect, "freq": freq, "color": eatk["color"], "lv": lv, "cambio": by_switch})
	eatk = {}
	_hit_enemy(float(MOVES["contro"]["dmg"]) * (1.0 + 0.8 * lv), s, float(MOVES["contro"]["push"]) * (1.6 if freq else 1.0) * (1.0 + 0.4 * lv), "contro")
	if est not in ["crollo", "dead"]:
		est = "stun"
		est_t = (1.3 if freq else 0.7) + 0.2 * lv
		if freq:
			_ev({"type": "un_altro"})


# ================================================================ tempo

func _tick() -> void:
	if over != "":
		return
	time += TICK
	if holding:
		hold_t += TICK
		if hold_t >= HOLD and st == "idle":
			st = "hover" if p_air > 0.0 else "charge"
			charge_t = 0.0
			_ev({"type": "sospeso" if p_air > 0.0 else "carica"})
	_tick_player()
	_tick_enemy()
	# il gesto in memoria si riprova a ogni passo
	if not pending.is_empty():
		if time - float(pending["t"]) > INPUT_LIFE:
			pending = {}
		elif _try(str(pending["g"]), false):
			pending = {}
	# il PIANO va in onda appena il giocatore può agire
	if plan_active and pending.is_empty() and not plan.is_empty():
		if st == "idle" or (st == "atk" and can_cancel_now()):
			var g: String = str(plan[0])
			if _try(g, true):
				plan.pop_front()
				_ev({"type": "piano_passo", "g": g, "left": plan.size()})
			elif st == "idle" and p_air <= 0.0:
				plan.pop_front()      # un passo impossibile adesso (es. giù da terra) si salta, il PIANO non si blocca
				_ev({"type": "piano_salta", "g": g})
	if plan_active and plan.is_empty() and st == "idle":
		plan_active = false
		plan_countered = false
		_ev({"type": "piano_fine", "why": "finito"})


func _tick_player() -> void:
	iframes = maxf(0.0, iframes - TICK)
	if p_air > 0.0 and not ((st == "atk" and move["id"] in ["aria", "lancio", "montante"] and e_air > 0.0) or st == "hover"):
		p_air = maxf(0.0, p_air - TICK)
	chain_idle += TICK if st != "atk" else 0.0
	if st != "atk" and chain_idle > (0.9 if party.size() > 1 else 0.6):
		if chain_hits >= 3:
			_respiro()
		chain = 0
		chain_hits = 0
	match st:
		"atk":
			st_t += TICK
			chain_idle = 0.0
			var adv: float = float(move["adv"])
			if adv > 0.0 and st_t <= float(move["hit"]) + 0.001:
				var step_x: float = adv * TICK / maxf(0.05, float(move["hit"]))
				px = minf(px + step_x, ex - BODY)
			if not move["done"] and st_t >= float(move["hit"]):
				move["done"] = true
				_resolve_player_hit()
			if st_t >= float(move["dur"]):
				_end_move()
		"charge":
			charge_t += TICK
		"hover":
			charge_t += TICK
			if charge_t >= HOVER_MAX:
				holding = false
				_release_hover()
		"dodge":
			st_t += TICK
			if st_t >= DODGE_DUR:
				st = "idle"
				dodge_ready = time + DODGE_COOLDOWN
		"hurt":
			st_t -= TICK
			if st_t <= 0.0:
				st = "idle"
				st_t = 0.0
	px = clampf(px, WALL_L, ex - BODY)


func _resolve_player_hit() -> void:
	var id: String = move["id"]
	if id == "blackout":
		var team: int = 0
		for m in party:
			if not m["ko"]:
				team += 1
		var dmg: float = ENEMY_HP * BLACKOUT_FRAC * (1.0 + 0.05 * (team - 1))   # tutta la squadra entra nel BLACKOUT
		ehp -= dmg
		_found("blackout")
		_ev({"type": "blackout", "dmg": dmg, "team": team - 1})
		ex = WALL_R - 0.5
		phase += 1
		seg = SEG_MAX
		last_seg_loss = time
		est = "down"
		est_t = 1.4
		move["landed"] = true
		_check_end()
		return
	var d: float = ex - px
	var in_air_target: bool = est == "air"
	var reach_ok: bool = d <= (2.8 if id == "schianto" else REACH + 0.1)
	if id == "aria" and not in_air_target and p_air <= 0.0:
		reach_ok = false
	if id in ["colpo", "affondo", "lancio", "montante", "scatto", "entrata", "sfondamento", "falciata"] and in_air_target:
		reach_ok = false      # da terra non arrivi a chi è in aria (salta per inseguirlo)
	if not reach_ok:
		_ev({"type": "a_vuoto", "id": id})
		return
	move["landed"] = true
	var p: Dictionary = POSTURE[posture]
	var dmg2: float = float(move["dmg"]) * float(p["dmg"])
	var s: float = float(move["seg"]) * float(p["seg"])
	var push: float = float(move["push"]) * float(p["push"])
	if id == "colpo" and int(move["chain"]) == 4:
		dmg2 *= 1.6
		push = 1.4 * float(p["push"])
	if id == "entrata" and move.get("relay", false):
		dmg2 *= 2.0
		s *= 3.0
		push *= 2.0
		_found("staffetta")
	if time <= castigo_until and id in ["aria", "schiacciata", "schianto", "colpo"]:
		s *= 1.8
		dmg2 *= 1.5
		castigo_until = -1.0
		_found("salto_castigo")
		_ev({"type": "castigo"})
	if id == "colpo":
		chain_hits += 1
	var was_air: bool = est == "air"
	_hit_enemy(dmg2, s, push, id)
	if est in ["dead", "crollo"]:
		return
	match id:
		"lancio", "montante":
			if id == "montante":
				_found("montante")
			est = "air"
			e_air = LAUNCH_AIR
			juggle = 0
			p_air = LAUNCH_AIR
			_ev({"type": "lancio"})
		"aria":
			if est == "air":
				juggle += 1
				if juggle < JUGGLE_MAX:
					e_air = minf(e_air + 0.3, 0.9)
					p_air = maxf(p_air, e_air)
				if juggle >= 3:
					_found("giocoliere")
		"falciata":
			if est in ["stun", "idle", "rec"]:
				_found("falciata")
				est = "down"
				est_t = 0.6
				_ev({"type": "falciata"})
		"schiacciata", "schianto":
			if id == "schianto":
				_found("schianto")
			if was_air:
				_found("schiacciata")
				_ev({"type": "schiacciata", "lv": move.get("lv", 0)})
				est = "down"
				est_t = 0.8 + 0.3 * int(move.get("lv", 0))
				e_air = 0.0
			p_air = 0.0


func _hit_enemy(dmg: float, s: float, push: float, src: String) -> void:
	if est == "dead":
		return
	if est == "crollo":
		dmg *= 2.0
		s = 0.0
		push = 0.0
	ehp -= dmg
	var was_tele: bool = est == "tele"
	if s > 0.0:
		seg = maxf(0.0, seg - s)
		last_seg_loss = time
	_ev({"type": "colpito_nemico", "dmg": dmg, "seg": s, "src": src, "armor": was_tele and src != "contro"})
	if _check_end():
		return
	if est == "crollo":
		return
	if seg <= 0.0:
		est = "crollo"
		est_t = CROLLO_TIME
		estring.clear()
		eatk = {}
		e_air = 0.0
		hits_in_row = 0
		_ev({"type": "crollo"})
		return
	if was_tele and src != "contro":
		return     # durante il MIRINO il nemico incassa ma non si ferma: solo il CONTRO lo spezza
	hits_in_row += 1
	if est != "air" and est != "down":
		est = "stun"
		est_t = maxf(est_t, 0.35) if est == "stun" else 0.35
	_push_enemy(push)
	if hits_in_row >= SCROLLATA_HITS and est == "stun":
		# niente catene infinite: il nemico si scrolla di dosso e riparte subito
		hits_in_row = 0
		px = maxf(WALL_L, px - 2.0)
		_ev({"type": "scrollata"})
		_next_attack(true)


func _push_enemy(push: float) -> void:
	if push <= 0.0:
		return
	var nx: float = ex + push
	if nx >= WALL_R - 0.5:
		ex = WALL_R - 0.5
		if push >= (1.0 if party.size() == 1 else 2.0) and est != "air" and not walled:   # con la squadra serve una spinta vera (affondo pesante, scatto)
			walled = true
			est = "stun"
			est_t = 0.9
			seg = maxf(0.0, seg - 6.0)
			ehp -= 8.0
			last_seg_loss = time
			_found("muro")
			_ev({"type": "muro"})
			if _check_end():
				return
			if seg <= 0.0 and est != "crollo":
				est = "crollo"
				est_t = CROLLO_TIME
				_ev({"type": "crollo"})
		return
	ex = nx


func _check_end() -> bool:
	if ehp <= 0.0:
		ehp = 0.0
		est = "dead"
		over = "vittoria"
		_ev({"type": "vittoria", "time": time, "found": found.size()})
		return true
	if hp <= 0.0:
		hp = 0.0
		party[active]["hp"] = 0.0
		party[active]["ko"] = true
		var nxt: int = next_alive()
		if nxt >= 0:
			# KO: entra subito il prossimo della squadra
			_ev({"type": "ko", "who": active})
			switch_ready = 0.0
			switch_to(nxt, true)
			return false
		over = "sconfitta"
		_ev({"type": "sconfitta", "time": time})
		return true
	return false


# ================================================================ nemico

func _tick_enemy() -> void:
	if est != "crollo" and est != "dead" and time - last_seg_loss > SEG_REGEN_AFTER:
		seg = minf(SEG_MAX, seg + SEG_REGEN * TICK)
	match est:
		"idle":
			var d: float = ex - px
			if d > 2.6:
				ex = maxf(px + BODY, ex - ENEMY_SPEED * TICK)
			idle_wait -= TICK
			if idle_wait <= 0.0:
				_next_attack(false)
		"tele":
			eatk["t"] = float(eatk["t"]) + TICK
			if float(eatk["t"]) >= float(eatk["impact"]):
				_impact()
		"rec", "stun", "down":
			est_t -= TICK
			if est_t <= 0.0:
				if est == "rec" and not estring.is_empty():
					_start_tele(estring.pop_front())
				else:
					# dopo aver incassato risponde subito; dopo aver attaccato lascia respirare
					idle_wait = 0.25 if est == "stun" else rng.randf_range(0.6, 1.2) * (0.8 if phase > 0 else 1.0)
					est = "idle"
		"air":
			e_air -= TICK
			if e_air <= 0.0:
				est = "down"
				est_t = 0.5
				juggle = 0
		"crollo":
			est_t -= TICK
			if est_t <= 0.0:
				est = "idle"
				seg = SEG_MAX * 0.6
				last_seg_loss = time
				idle_wait = 0.4
				_ev({"type": "crollo_finito"})


func _next_attack(now: bool) -> void:
	var s: Array = STRINGS[rng.randi_range(0, STRINGS.size() - 1)].duplicate(true)
	if phase > 0 and rng.randf() < 0.5:
		s.append(STRINGS[rng.randi_range(0, 2)][0].duplicate())   # dopo il primo BLACKOUT le stringhe si allungano
	estring = s
	_start_tele(estring.pop_front())
	if now:
		eatk["impact"] = float(eatk["impact"]) + 0.2


func _start_tele(a: Array) -> void:
	var kind: String = a[0]
	var w: float = float(ATTACKS[kind]["windup"]) * (0.85 if phase > 0 else 1.0)
	eatk = {"kind": kind, "color": a[1], "impact": w, "t": 0.0}
	est = "tele"
	hits_in_row = 0
	walled = false
	_ev({"type": "mirino", "kind": kind, "color": a[1], "windup": w})


func _impact() -> void:
	var a: Dictionary = ATTACKS[eatk["kind"]]
	var kind: String = eatk["kind"]
	var d: float = ex - px
	var gap: float = STRING_GAP
	ex = maxf(px + BODY, ex - float(a["lunge"]))
	if iframes > 0.0:
		var perfect: bool = st == "dodge" and time - dodge_start <= DODGE_PERFECT
		if perfect:
			fiato = minf(FIATO_MAX, fiato + 10.0)
		_ev({"type": "schivata", "kind": kind, "perfect": perfect})
	elif kind == "spazzata" and p_air > 0.0:
		gap = 1.0
		castigo_until = time + 1.1
		_ev({"type": "saltata"})
	elif d > float(a["reach"]):
		gap = STRING_GAP + 0.6
		_ev({"type": "nemico_a_vuoto", "kind": kind})
	else:
		var dmg: float = float(a["dmg"]) * (PARTY_ENEMY_DMG if party.size() > 1 else 1.0)
		if kind == "affondo" and time <= esposto_until:
			dmg *= 2.0
		hp -= dmg
		pending = {}
		holding = false
		charge_t = 0.0
		move = {}
		chain = 0
		p_air = 0.0
		st = "hurt"
		st_t = 0.9 if kind == "spazzata" else 0.4
		px = maxf(WALL_L, px - (0.6 if kind == "spazzata" else 1.6))
		if plan_active:
			plan.clear()
			plan_active = false
			_ev({"type": "piano_fine", "why": "colpito"})
		_ev({"type": "colpito", "kind": kind, "dmg": dmg, "doppio": time <= esposto_until and kind == "affondo"})
		_check_end()
	esposto_until = -1.0
	eatk = {}
	if est == "tele":
		est = "rec"
		est_t = gap if not estring.is_empty() else gap + 0.3


# ================================================================ utilità

func _found(id: String) -> void:
	if found.has(id):
		return
	found[id] = time
	var label: String = id
	for d in DISCOVERIES:
		if d[0] == id:
			label = d[1]
	_ev({"type": "scoperta", "id": id, "label": label, "n": found.size(), "of": DISCOVERIES.size()})


func _ev(e: Dictionary) -> void:
	e["at"] = time
	events.append(e)
