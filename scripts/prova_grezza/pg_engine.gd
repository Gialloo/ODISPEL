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
}
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


func _init(seed_v: int = 7) -> void:
	rng.seed = seed_v


# ================================================================ comandi

func input(g: String) -> void:
	if over != "":
		return
	if g == "postura":
		_switch_posture()
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
			if not _free(from_plan, id):
				return false
			if id == "colpo":
				chain = chain + 1 if chain_idle < 0.5 and chain < 4 else 1
				if chain == 4:
					_found("catena_piena")
			_start_move(id)
			return true
		"verso":
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
				return false
			if not _free(from_plan, "schiacciata"):
				return false
			_start_move("schiacciata")
			return true
		"via":
			if p_air > 0.0:
				return false
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


func _free(from_plan: bool, next_id: String) -> bool:
	# si può agire ora? da fermo sempre; dentro una mossa solo nel lampo bianco (annullamento)
	if st == "idle":
		return true
	if st == "dodge" or st == "hurt":
		return false
	if st != "atk" or not can_cancel_now():
		return false
	var natural: bool = (next_id == "colpo" and move["id"] == "colpo") or (next_id in ["aria", "schiacciata"] and move["id"] in ["aria", "lancio"]) \
		or move["id"] == "contro" or next_id == "blackout"
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


func _start_move(id: String) -> void:
	var m: Dictionary = MOVES[id].duplicate()
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
	if id == "lancio":
		p_air = 0.0
	if id == "blackout" or id == "contro":
		iframes = float(m["dur"])
	_ev({"type": "mossa", "id": id, "posture": posture, "chain": m["chain"]})


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


func _do_counter() -> void:
	var left: float = float(eatk["impact"]) - float(eatk["t"])
	var perfect: bool = left <= PERFECT * (WIDE_MULT if wide else 1.0)
	var freq: bool = eatk["color"] == posture
	_start_move("contro")
	move["landed"] = true
	move["done"] = true
	var s: float = 20.0 if perfect else 14.0
	if freq:
		s *= 2.5
	fiato = minf(FIATO_MAX, fiato + (18.0 if perfect else 10.0))
	_found("contro")
	if perfect:
		_found("contro_perfetto")
	if freq:
		_found("frequenza")
	if plan_countered:
		_found("piano_contro")
	estring.clear()
	_ev({"type": "contro", "perfect": perfect, "freq": freq, "color": eatk["color"]})
	eatk = {}
	_hit_enemy(MOVES["contro"]["dmg"], s, MOVES["contro"]["push"] * (1.6 if freq else 1.0), "contro")
	if est not in ["crollo", "dead"]:
		est = "stun"
		est_t = 1.3 if freq else 0.7
		if freq:
			_ev({"type": "un_altro"})


# ================================================================ tempo

func _tick() -> void:
	if over != "":
		return
	time += TICK
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
	if p_air > 0.0 and not (st == "atk" and move["id"] in ["aria", "lancio"] and e_air > 0.0):
		p_air = maxf(0.0, p_air - TICK)
	chain_idle += TICK if st != "atk" else 0.0
	if st != "atk" and chain_idle > 0.6:
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
		var dmg: float = ENEMY_HP * BLACKOUT_FRAC
		ehp -= dmg
		_found("blackout")
		_ev({"type": "blackout", "dmg": dmg})
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
	var reach_ok: bool = d <= REACH + 0.1
	if id == "aria" and not in_air_target and p_air <= 0.0:
		reach_ok = false
	if id in ["colpo", "affondo", "lancio"] and in_air_target:
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
	if time <= castigo_until and id in ["aria", "schiacciata", "colpo"]:
		s *= 1.8
		dmg2 *= 1.5
		castigo_until = -1.0
		_found("salto_castigo")
		_ev({"type": "castigo"})
	if id == "colpo":
		chain_hits += 1
	_hit_enemy(dmg2, s, push, id)
	if est in ["dead", "crollo"]:
		return
	match id:
		"lancio":
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
		"schiacciata":
			if est == "air":
				_found("schiacciata")
				_ev({"type": "schiacciata"})
				est = "down"
				est_t = 0.8
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
		if push >= 1.0 and est != "air" and not walled:
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
		var dmg: float = float(a["dmg"])
		if kind == "affondo" and time <= esposto_until:
			dmg *= 2.0
		hp -= dmg
		pending = {}
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
		_ev({"type": "colpito", "kind": kind, "dmg": dmg, "doppio": dmg > float(a["dmg"])})
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
