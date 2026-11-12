class_name PgArena
extends RefCounted

# PROVA GREZZA 2 · core CONTROSEGNALE v2 in ARENA CIRCOLARE (decisioni dell'autore del 12/11 sera, dopo la prima prova).
# Progetto: /mnt/project-files/odispel/v3/combat_system/CONTROSEGNALE_CORE_v2.md, sezione «Dopo la prima prova grezza».
# Squadra da 4: due davanti (ne controlli uno, l'altro combatte da solo, passi all'altro quando vuoi), due dietro
# (passivi e interventi: COPERTURA a vita bassa, dentro al BLACKOUT, entrano se cade uno davanti).
# Il piano è (x, z) in metri; il nemico sta al centro e si muove. Tutto a passo fisso, deterministico.
# Comandi del controllato: set_move(dir) col pollice o WASD (y = verso il nemico, x = a destra),
# press_attack/release_attack (tocco o carica), input(g) con g in: verso, via, sx, dx, salto, postura, cambio.

const TICK: float = 1.0 / 60.0
const R: float = 9.0                      # raggio dell'arena: il bordo è il muro
const BODY: float = 1.1
const REACH: float = 1.9
const SPEED: float = 4.6
const CHARGE_SPEED: float = 1.8           # mentre carichi ti puoi ancora piazzare, piano

const WIN: float = 0.32
const PERFECT: float = 0.10
const BUFFER: float = 0.10
const WIDE_MULT: float = 1.5
const INPUT_LIFE: float = 0.25
const HOLD: float = 0.22                  # oltre 220 ms il tocco diventa carica
const CHARGE_LV: Array = [0.0, 0.40, 0.85]   # livelli contati da quando parte la carica
const HOVER_MAX: float = 1.0

const FIATO_MAX: float = 100.0
const SEG_MAX: float = 100.0
const ENEMY_HP: float = 3000.0
const CANCEL_COST: float = 12.0
const PIANO_COST: float = 30.0
const RESPIRO: float = 15.0
const SEG_REGEN: float = 15.0
const SEG_REGEN_AFTER: float = 1.6
const CROLLO_TIME: float = 4.5
const BLACKOUT_FRAC: float = 0.10
const SCROLLATA_HITS: int = 6
const BACK_MULT: float = 1.8              # alle spalle il SEGNALE scende di più
const PARTNER_MULT: float = 0.5           # il compagno aiuta, non vince da solo
const PARTNER_SEG_MULT: float = 0.3
const SWAP_CD: float = 2.5
const COVER_CD: float = 25.0

const MOVES: Dictionary = {
	"colpo": {"dur": 0.36, "hit": 0.10, "cancel": 0.14, "dmg": 10.0, "seg": 1.5, "push": 0.35, "adv": 0.5},
	"montante": {"dur": 0.50, "hit": 0.16, "cancel": 0.24, "dmg": 12.0, "seg": 4.0, "push": 0.2, "adv": 0.5},
	"affondo": {"dur": 0.50, "hit": 0.16, "cancel": 0.24, "dmg": 12.0, "seg": 3.0, "push": 2.4, "adv": 3.0},
	"fianco": {"dur": 0.40, "hit": 0.12, "cancel": 0.18, "dmg": 14.0, "seg": 3.0, "push": 0.8, "adv": 0.8},
	"scatto": {"dur": 0.55, "hit": 0.18, "cancel": 0.30, "dmg": 16.0, "seg": 6.0, "push": 2.0, "adv": 3.5},
	"aria": {"dur": 0.30, "hit": 0.10, "cancel": 0.14, "dmg": 9.0, "seg": 2.0, "push": 0.25, "adv": 0.3},
	"schiacciata": {"dur": 0.50, "hit": 0.18, "cancel": 0.30, "dmg": 18.0, "seg": 4.0, "push": 0.6, "adv": 0.4},
	"schianto": {"dur": 0.60, "hit": 0.20, "cancel": 0.34, "dmg": 20.0, "seg": 6.0, "push": 1.2, "adv": 0.8},
	"entrata": {"dur": 0.45, "hit": 0.14, "cancel": 0.20, "dmg": 10.0, "seg": 3.0, "push": 1.0, "adv": 3.0},
	"contro": {"dur": 0.38, "hit": 0.0, "cancel": 0.12, "dmg": 15.0, "seg": 0.0, "push": 1.4, "adv": 0.0},
	"blackout": {"dur": 1.00, "hit": 0.45, "cancel": 9.0, "dmg": 0.0, "seg": 0.0, "push": 0.0, "adv": 1.0},
}
const POSTURE: Dictionary = {
	"rosso": {"dmg": 1.4, "seg": 1.5, "speed": 0.8, "push": 1.5},
	"blu": {"dmg": 0.8, "seg": 0.8, "speed": 1.25, "push": 0.7},
}
const DODGE_DUR: float = 0.36
const DODGE_IFRAMES: float = 0.22
const DODGE_PERFECT: float = 0.12
const DODGE_COOLDOWN: float = 0.40
const DODGE_BACK: float = 2.0
const DODGE_SIDE: float = 2.6
const JUMP_AIR: float = 0.65
const LAUNCH_AIR: float = 1.1
const JUGGLE_MAX: int = 4

# il linguaggio del nemico: AFFONDO = carica in linea (colore), SPAZZATA = onda ad anello attorno a lui
const ATTACKS: Dictionary = {
	"affondo": {"windup": 0.95, "len": 6.5, "width": 1.2, "dmg": 14.0},
	"spazzata": {"windup": 1.00, "radius": 4.2, "dmg": 12.0},
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
const ENEMY_SPEED: float = 2.6
const ENEMY_TURN: float = 2.6             # rad/s: girargli attorno serve davvero

const PARTY: Array = [
	{"id": "a", "name": "MANICHINO A", "passive": "fiato"},
	{"id": "b", "name": "MANICHINO B", "passive": "occhio"},
	{"id": "c", "name": "MANICHINO C", "passive": "guardia"},
	{"id": "d", "name": "MANICHINO D", "passive": "spinta"},
]
const PASSIVE_TEXT: Dictionary = {
	"fiato": "dietro: +FIATO col tempo", "occhio": "dietro: finestra del CONTRO più larga",
	"guardia": "dietro: COPERTURA più spesso", "spinta": "dietro: BLACKOUT più forte",
}

const DISCOVERIES: Array = [
	["contro", "CONTRO"], ["contro_perfetto", "CONTRO PERFETTO"], ["frequenza", "CONTRO DI FREQUENZA"],
	["contro_caricato", "CONTRO CARICATO"], ["muro", "AL MURO"], ["alle_spalle", "ALLE SPALLE"],
	["annullo", "ANNULLAMENTO"], ["montante", "MONTANTE"], ["giocoliere", "GIOCOLIERE"],
	["schiacciata", "SCHIACCIATA"], ["schianto", "SCHIACCIATA CARICATA"], ["salto_castigo", "SALTO E CASTIGO"],
	["fianco", "COLPO DI FIANCO"], ["staffetta", "STAFFETTA"], ["catena_piena", "CATENA PIENA"],
	["piano_contro", "PIANO E CONTRO"], ["blackout", "BLACKOUT"],
]


class Fighter:
	var idx: int = 0
	var id: String = ""
	var name: String = ""
	var passive: String = ""
	var front: bool = true
	var hp: float = 120.0
	var maxhp: float = 120.0
	var pos: Vector2 = Vector2.ZERO
	var st: String = "idle"               # idle, atk, dodge, hurt, charge, hover, ko
	var st_t: float = 0.0
	var move: Dictionary = {}
	var chain: int = 0
	var chain_idle: float = 9.0
	var chain_hits: int = 0
	var p_air: float = 0.0
	var iframes: float = 0.0
	var dodge_ready: float = 0.0
	var dodge_start: float = -9.0
	var side_until: float = -1.0          # dopo uno scarto laterale il tocco è un colpo di fianco
	var posture: String = "rosso"
	var charge_t: float = 0.0
	var ai_cool: float = 0.0
	var ai_seen: int = -1
	var esposto_until: float = -1.0
	var mv: Vector2 = Vector2.ZERO


var rng := RandomNumberGenerator.new()
var wide: bool = false
var time: float = 0.0
var _acc: float = 0.0
var events: Array = []
var over: String = ""
var found: Dictionary = {}

var fighters: Array = []
var active: int = 0
var fiato: float = 50.0
var swap_ready: float = 0.0
var cover_ready: float = 6.0
var pending: Dictionary = {}
var holding: bool = false
var hold_t: float = 0.0
var plan: Array = []
var plan_active: bool = false
var plan_countered: bool = false

# nemico
var epos: Vector2 = Vector2.ZERO
var efacing: Vector2 = Vector2(0, 1)
var ehp: float = ENEMY_HP
var seg: float = SEG_MAX
var est: String = "idle"
var est_t: float = 0.0
var eatk: Dictionary = {}
var estring: Array = []
var etarget: int = 0
var e_air: float = 0.0
var juggle: int = 0
var castigo_until: float = -1.0
var last_seg_loss: float = 0.0
var hits_in_row: int = 0
var walled: bool = false
var phase: int = 0
var idle_wait: float = 1.4
var attack_id: int = 0


func _init(seed_v: int = 7) -> void:
	rng.seed = seed_v
	for i in PARTY.size():
		var f := Fighter.new()
		f.idx = i
		f.id = PARTY[i]["id"]
		f.name = PARTY[i]["name"]
		f.passive = PARTY[i]["passive"]
		f.front = i < 2
		f.posture = "rosso" if i % 2 == 0 else "blu"
		f.pos = Vector2(-1.4 + 2.8 * i, 5.0) if i < 2 else Vector2(-2.0 + 4.0 * (i - 2), R + 1.5)
		fighters.append(f)
	etarget = 0


# ================================================================ comandi

func me() -> Fighter:
	return fighters[active]


func partner() -> Fighter:
	for f in fighters:
		if f.front and f.idx != active and f.st != "ko":
			return f
	return null


func set_move(v: Vector2) -> void:
	me().mv = v.limit_length(1.0)


func press_attack() -> void:
	if over != "":
		return
	holding = true
	hold_t = 0.0


func cancel_press() -> void:
	# il dito che doveva toccare è diventato uno scorrimento
	holding = false


func release_attack() -> void:
	if not holding:
		return
	holding = false
	var f: Fighter = me()
	if f.st == "charge":
		_release_charge(f)
	elif f.st == "hover":
		_release_hover(f)
	else:
		input("tocco")       # rilascio breve, o lungo mentre la mossa non era finita: è un tocco


func input(g: String) -> void:
	if over != "":
		return
	if g == "postura":
		_switch_posture(me())
		return
	if g == "cambio":
		_swap(false)
		return
	if plan_active:
		if g == "verso" and _counter_left(me()) >= 0.0:
			plan_countered = true
		else:
			plan.clear()
			plan_active = false
			_ev({"type": "piano_fine", "why": "mani"})
	if not _try(me(), g, false):
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


func step(real_dt: float) -> void:
	_acc += minf(real_dt, 0.1)
	while _acc >= TICK:
		_acc -= TICK
		_tick()


func take_events() -> Array:
	var e: Array = events
	events = []
	return e


func danger() -> Dictionary:
	if est != "tele":
		return {}
	var d: Dictionary = eatk.duplicate()
	d["left"] = float(eatk["impact"]) - float(eatk["t"])
	return d


func can_cancel_now(f: Fighter = null) -> bool:
	if f == null:
		f = me()
	return f.st == "atk" and bool(f.move.get("landed", false)) and f.st_t >= float(f.move["cancel"]) and f.st_t < float(f.move["dur"])


func win_len() -> float:
	var w: float = WIN * (WIDE_MULT if wide else 1.0)
	if _back_has("occhio"):
		w *= 1.15
	return w


func charge_level(f: Fighter = null) -> int:
	if f == null:
		f = me()
	var lv: int = 0
	for i in CHARGE_LV.size():
		if f.charge_t >= float(CHARGE_LV[i]):
			lv = i + 1
	return lv


func forward(f: Fighter) -> Vector2:
	var d: Vector2 = epos - f.pos
	return d.normalized() if d.length() > 0.01 else Vector2(0, -1)


func right_of(f: Fighter) -> Vector2:
	var fw: Vector2 = forward(f)
	return Vector2(-fw.y, fw.x)


func preview() -> Dictionary:
	var d: Dictionary = {"dist": epos.distance_to(me().pos), "enemy": est, "behind": _behind(me())}
	if est == "tele":
		d["kind"] = eatk["kind"]
		d["color"] = eatk["color"]
		d["left"] = float(eatk["impact"]) - float(eatk["t"])
		d["target"] = fighters[etarget].name
	return d


# ================================================================ gesti del controllato

func _counter_left(f: Fighter) -> float:
	# >= 0: secondi all'impatto di un AFFONDO su di te dentro finestra (+ memoria); -1 altrimenti
	if est != "tele" or eatk["kind"] != "affondo" or etarget != f.idx:
		return -1.0
	var left: float = float(eatk["impact"]) - float(eatk["t"])
	return left if left <= win_len() + BUFFER else -1.0


func _try(f: Fighter, g: String, from_plan: bool) -> bool:
	if f.st in ["hurt", "ko"] or over != "":
		return false
	if g == "verso" and est == "crollo" and f.p_air <= 0.0 and _free(f, from_plan, "blackout"):
		_start_move(f, "blackout")
		_ev({"type": "blackout_via"})
		return true
	if g == "verso" and _counter_left(f) >= 0.0 and _free(f, from_plan, "contro"):
		_do_counter(f, 0)
		return true
	match g:
		"tocco":
			var id: String = "colpo"
			if f.p_air > 0.0:
				id = "aria"
			elif time <= f.side_until:
				id = "fianco"
			elif f.chain == 2 and f.chain_idle >= 0.30 and f.chain_idle <= 0.9:
				id = "montante"       # colpo, colpo, PAUSA, colpo
			if not _free(f, from_plan, id):
				return false
			if id == "colpo":
				f.chain = f.chain + 1 if f.chain_idle < 0.5 and f.chain < 4 else 1
				if f.chain == 4:
					_found("catena_piena")
			_start_move(f, id)
			return true
		"verso":
			if f.p_air > 0.0 or not _free(f, from_plan, "affondo"):
				return false
			if est == "tele" and eatk["kind"] == "affondo" and etarget == f.idx:
				f.esposto_until = time + float(eatk["impact"]) - float(eatk["t"]) + 0.05
				_ev({"type": "troppo_presto"})
			_start_move(f, "affondo")
			return true
		"giu":
			if f.p_air <= 0.0 or not _free(f, from_plan, "schiacciata"):
				return false
			_start_move(f, "schiacciata")
			return true
		"salto":
			if f.p_air > 0.0 or not _free(f, from_plan, "salto"):
				return false
			_end_move(f)
			f.p_air = JUMP_AIR
			if est == "air" and epos.distance_to(f.pos) <= REACH + 1.5:
				f.p_air = maxf(JUMP_AIR, e_air)       # lo insegui in aria
			_ev({"type": "salto", "who": f.idx})
			return true
		"via", "sx", "dx":
			if f.p_air > 0.0 or time < f.dodge_ready:
				return false
			if f.st == "charge" or f.st == "hover":
				_ev({"type": "carica_annullata", "who": f.idx})
				f.st = "idle"
				f.charge_t = 0.0
				holding = false
			elif not _free(f, from_plan, "via"):
				return false
			_end_move(f)
			f.st = "dodge"
			f.st_t = 0.0
			f.iframes = DODGE_IFRAMES
			f.dodge_start = time
			var dv: Vector2 = -forward(f) * DODGE_BACK
			if g == "sx":
				dv = -right_of(f) * DODGE_SIDE
			elif g == "dx":
				dv = right_of(f) * DODGE_SIDE
			f.pos += dv
			if g != "via":
				f.side_until = time + DODGE_DUR + 0.4
			_keep_apart(f)
			_ev({"type": "scarto", "who": f.idx, "dir": g})
			return true
		"carica":
			# dal PIANO: una carica di secondo livello già pronta
			if f.p_air > 0.0 or not _free(f, from_plan, "scatto"):
				return false
			f.charge_t = float(CHARGE_LV[1])
			_release_charge(f)
			return true
		"fila":
			return _swap_rows()
	return false


func _free(f: Fighter, from_plan: bool, next_id: String) -> bool:
	if f.st == "idle":
		return true
	if f.st != "atk" or not can_cancel_now(f):
		return false
	var cur: String = f.move["id"]
	var natural: bool = (next_id == "colpo" and cur == "colpo") or (next_id == "montante" and cur == "colpo") \
		or (next_id in ["aria", "schiacciata"] and cur in ["aria", "montante"]) or cur in ["contro", "entrata"] \
		or next_id == "blackout"
	if natural or from_plan:
		return true
	if fiato < CANCEL_COST:
		return false
	fiato -= CANCEL_COST
	_found("annullo")
	_ev({"type": "annullo", "from": cur, "to": next_id})
	return true


func _switch_posture(f: Fighter) -> void:
	f.posture = "blu" if f.posture == "rosso" else "rosso"
	_ev({"type": "postura", "posture": f.posture, "who": f.idx})


func _start_move(f: Fighter, id: String, lv: int = 0) -> void:
	var m: Dictionary = MOVES[id].duplicate()
	var p: Dictionary = POSTURE[f.posture]
	var sp: float = float(p["speed"]) if id in ["colpo", "aria", "affondo", "fianco"] else 1.0
	m["dur"] = float(m["dur"]) / sp
	m["hit"] = float(m["hit"]) / sp
	m["cancel"] = float(m["cancel"]) / sp
	m["id"] = id
	m["done"] = false
	m["landed"] = false
	m["chain"] = f.chain if id == "colpo" else 0
	m["lv"] = lv
	if id == "scatto":
		m["adv"] = 3.0 + lv
		m["dmg"] = [16.0, 16.0, 26.0, 40.0][lv]
		m["seg"] = [6.0, 6.0, 10.0, 16.0][lv]
		m["push"] = [2.0, 2.0, 3.0, 4.0][lv]
	if id == "schianto":
		m["dmg"] = 20.0 + 12.0 * lv
		m["seg"] = 6.0 + 5.0 * lv
	f.move = m
	f.st = "atk"
	f.st_t = 0.0
	if id != "colpo":
		f.chain = 0
	if id == "blackout" or id == "contro":
		f.iframes = float(m["dur"])
	_ev({"type": "mossa", "id": id, "who": f.idx, "posture": f.posture, "chain": m["chain"], "lv": lv})


func _end_move(f: Fighter) -> void:
	if f.st == "atk" and f.move.get("id", "") == "colpo" and f.chain_hits >= 3 and f.chain >= 3:
		_respiro(f)
	f.st = "idle"
	f.st_t = 0.0
	f.move = {}


func _respiro(f: Fighter) -> void:
	fiato = minf(FIATO_MAX, fiato + RESPIRO)
	f.chain_hits = 0
	_ev({"type": "respiro"})


func _release_charge(f: Fighter) -> void:
	var lv: int = maxi(1, charge_level(f))
	f.charge_t = 0.0
	f.st = "idle"
	# rilasciata a tempo su un AFFONDO: CONTRO CARICATO
	if _counter_left(f) >= 0.0:
		_do_counter(f, lv)
		return
	if est == "tele" and eatk["kind"] == "affondo" and etarget == f.idx:
		f.esposto_until = time + float(eatk["impact"]) - float(eatk["t"]) + 0.05
		_ev({"type": "troppo_presto"})
	_start_move(f, "scatto", lv)


func _release_hover(f: Fighter) -> void:
	var lv: int = maxi(1, charge_level(f))
	f.charge_t = 0.0
	f.st = "idle"
	_start_move(f, "schianto", lv)


func _do_counter(f: Fighter, lv: int) -> void:
	var left: float = float(eatk["impact"]) - float(eatk["t"])
	var perfect: bool = left <= PERFECT * (WIDE_MULT if wide else 1.0)
	var freq: bool = eatk["color"] == f.posture
	_start_move(f, "contro", lv)
	f.move["landed"] = true
	f.move["done"] = true
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
	_ev({"type": "contro", "perfect": perfect, "freq": freq, "color": eatk["color"], "lv": lv, "who": f.idx})
	eatk = {}
	var dmg: float = float(MOVES["contro"]["dmg"]) * (1.0 + 0.8 * lv)
	_hit_enemy(f, dmg, s, float(MOVES["contro"]["push"]) * (1.6 if freq else 1.0) * (1.0 + 0.4 * lv), "contro")
	if est not in ["crollo", "dead"]:
		est = "stun"
		est_t = (1.3 if freq else 0.7) + 0.2 * lv
		if freq:
			_ev({"type": "un_altro"})


func _swap(from_plan: bool) -> bool:
	var p: Fighter = partner()
	var f: Fighter = me()
	if p == null or time < swap_ready or p.st == "hurt":
		return false
	# STAFFETTA: il cambio dentro il lampo bianco fa entrare il compagno con un colpo che vale doppio
	var relay: bool = can_cancel_now(f) and f.move.get("landed", false)
	active = p.idx
	swap_ready = time + SWAP_CD
	f.mv = Vector2.ZERO
	pending = {}
	_ev({"type": "cambio", "from": f.idx, "to": p.idx, "staffetta": relay})
	if p.st in ["idle", "atk"] and p.p_air <= 0.0 and epos.distance_to(p.pos) <= REACH + 3.2:
		_start_move(p, "entrata")      # chi entra lascia quello che stava facendo e fa il suo colpo d'entrata
		p.move["relay"] = relay
	return true


func _swap_rows() -> bool:
	# dal PIANO: il compagno in campo esce e entra il primo dietro
	var p: Fighter = partner()
	if p == null:
		return false
	for b in fighters:
		if not b.front and b.st != "ko":
			b.front = true
			p.front = false
			b.pos = p.pos
			b.st = "idle"
			p.pos = Vector2(p.pos.x, R + 1.5)
			p.st = "idle"
			_ev({"type": "fila", "in": b.idx, "out": p.idx})
			return true
	return false


# ================================================================ tempo

func _tick() -> void:
	if over != "":
		return
	time += TICK
	if _back_has("fiato"):
		fiato = minf(FIATO_MAX, fiato + 1.5 * TICK)
	if holding:
		hold_t += TICK
		var f: Fighter = me()
		if hold_t >= HOLD:
			if f.st == "idle" and f.p_air <= 0.0:
				f.st = "charge"
				f.charge_t = 0.0
				_ev({"type": "carica", "who": f.idx})
			elif f.st == "idle" and f.p_air > 0.0:
				f.st = "hover"
				f.charge_t = 0.0
				_ev({"type": "sospeso", "who": f.idx})
	for f in fighters:
		if f.front:
			_tick_fighter(f)
	_tick_enemy()
	_tick_partner()
	if not pending.is_empty():
		if time - float(pending["t"]) > INPUT_LIFE:
			pending = {}
		elif _try(me(), str(pending["g"]), false):
			pending = {}
	if plan_active and pending.is_empty() and not plan.is_empty():
		var f2: Fighter = me()
		if f2.st == "idle" or can_cancel_now(f2):
			var g: String = str(plan[0])
			var ok: bool = _swap(true) if g == "cambio" else (_switch_posture_ok(f2) if g == "postura" else _try(f2, g, true))
			if ok:
				plan.pop_front()
				_ev({"type": "piano_passo", "g": g, "left": plan.size()})
			elif f2.st == "idle" and f2.p_air <= 0.0:
				plan.pop_front()
				_ev({"type": "piano_salta", "g": g})
	if plan_active and plan.is_empty() and me().st == "idle":
		plan_active = false
		plan_countered = false
		_ev({"type": "piano_fine", "why": "finito"})


func _switch_posture_ok(f: Fighter) -> bool:
	_switch_posture(f)
	return true


func _tick_fighter(f: Fighter) -> void:
	f.iframes = maxf(0.0, f.iframes - TICK)
	var hang: bool = (f.st == "atk" and f.move.get("id", "") in ["aria", "montante"] and e_air > 0.0) or f.st == "hover"
	if f.p_air > 0.0 and not hang:
		f.p_air = maxf(0.0, f.p_air - TICK)
	if f.st != "atk":
		f.chain_idle += TICK
	if f.st != "atk" and f.chain_idle > 0.9:
		if f.chain_hits >= 3:
			_respiro(f)
		f.chain = 0
		f.chain_hits = 0
	match f.st:
		"idle":
			if f.mv.length() > 0.05:
				var fw: Vector2 = forward(f)
				var rt: Vector2 = Vector2(-fw.y, fw.x)
				f.pos += (rt * f.mv.x + fw * f.mv.y) * SPEED * TICK
		"charge":
			f.charge_t += TICK
			if f.mv.length() > 0.05:
				var fw2: Vector2 = forward(f)
				f.pos += (Vector2(-fw2.y, fw2.x) * f.mv.x + fw2 * f.mv.y) * CHARGE_SPEED * TICK
		"hover":
			f.charge_t += TICK
			if f.charge_t >= HOVER_MAX:
				_release_hover(f)
				holding = false
		"atk":
			f.st_t += TICK
			f.chain_idle = 0.0
			var adv: float = float(f.move["adv"])
			if adv > 0.0 and f.st_t <= float(f.move["hit"]) + 0.001:
				f.pos += forward(f) * adv * TICK / maxf(0.05, float(f.move["hit"]))
			if not f.move["done"] and f.st_t >= float(f.move["hit"]):
				f.move["done"] = true
				_resolve_hit(f)
			if f.st_t >= float(f.move["dur"]):
				_end_move(f)
		"dodge":
			f.st_t += TICK
			if f.st_t >= DODGE_DUR:
				f.st = "idle"
				f.dodge_ready = time + DODGE_COOLDOWN
		"hurt":
			f.st_t -= TICK
			if f.st_t <= 0.0:
				f.st = "idle"
	_keep_apart(f)


func _keep_apart(f: Fighter) -> void:
	var d: Vector2 = f.pos - epos
	if d.length() < BODY:
		f.pos = epos + (d.normalized() if d.length() > 0.01 else Vector2(0, 1)) * BODY
	if f.pos.length() > R - 0.4:
		f.pos = f.pos.normalized() * (R - 0.4)


func _behind(f: Fighter) -> bool:
	var to_f: Vector2 = (f.pos - epos).normalized()
	return to_f.dot(efacing) < -0.35


func _resolve_hit(f: Fighter) -> void:
	var id: String = f.move["id"]
	if id == "blackout":
		var dmg: float = ENEMY_HP * BLACKOUT_FRAC * (1.2 if _back_has("spinta") else 1.0)
		var team: int = 0
		for b in fighters:
			if not b.front and b.st != "ko":
				team += 1
		dmg *= 1.0 + 0.1 * team
		ehp -= dmg
		_found("blackout")
		_ev({"type": "blackout", "dmg": dmg, "team": team})
		epos = epos + forward(f) * 3.0
		if epos.length() > R - 1.0:
			epos = epos.normalized() * (R - 1.0)
		phase += 1
		seg = SEG_MAX
		last_seg_loss = time
		est = "down"
		est_t = 1.4
		f.move["landed"] = true
		_check_end()
		return
	var d: float = epos.distance_to(f.pos)
	var reach: float = REACH + 0.1
	if id == "schianto":
		reach = 2.8
	var ok: bool = d <= reach
	if id == "aria" and est != "air" and f.p_air <= 0.0:
		ok = false
	if id in ["colpo", "affondo", "fianco", "scatto", "entrata", "montante"] and est == "air":
		ok = false
	if not ok:
		_ev({"type": "a_vuoto", "id": id, "who": f.idx})
		return
	f.move["landed"] = true
	var p: Dictionary = POSTURE[f.posture]
	var dmg2: float = float(f.move["dmg"]) * float(p["dmg"])
	var s: float = float(f.move["seg"]) * float(p["seg"])
	var push: float = float(f.move["push"]) * float(p["push"])
	if id == "colpo" and int(f.move["chain"]) == 4:
		dmg2 *= 1.6
		push = 1.4 * float(p["push"])
	if id == "fianco":
		_found("fianco")
	if id == "entrata" and f.move.get("relay", false):
		dmg2 *= 2.0
		s *= 2.0
		_found("staffetta")
	if _behind(f) and est != "air":
		s *= BACK_MULT
		_found("alle_spalle")
		_ev({"type": "alle_spalle", "who": f.idx})
	if time <= castigo_until and id in ["aria", "schiacciata", "schianto", "colpo"]:
		s *= 1.8
		dmg2 *= 1.5
		castigo_until = -1.0
		_found("salto_castigo")
		_ev({"type": "castigo"})
	if f.idx != active:
		dmg2 *= PARTNER_MULT
		s *= PARTNER_SEG_MULT
	if id == "colpo":
		f.chain_hits += 1
	var was_air: bool = est == "air"
	_hit_enemy(f, dmg2, s, push, id)
	if est in ["dead", "crollo"]:
		return
	match id:
		"montante":
			_found("montante")
			est = "air"
			e_air = LAUNCH_AIR
			juggle = 0
			f.p_air = LAUNCH_AIR
			_ev({"type": "lancio"})
		"aria":
			if est == "air":
				juggle += 1
				if juggle < JUGGLE_MAX:
					e_air = minf(e_air + 0.3, 0.9)
					f.p_air = maxf(f.p_air, e_air)
				if juggle >= 3:
					_found("giocoliere")
		"schiacciata", "schianto":
			if id == "schianto":
				_found("schianto")
			if was_air:
				_found("schiacciata")
				_ev({"type": "schiacciata", "lv": f.move.get("lv", 0)})
				est = "down"
				est_t = 0.8 + 0.3 * int(f.move.get("lv", 0))
				e_air = 0.0
			f.p_air = 0.0


func _hit_enemy(f: Fighter, dmg: float, s: float, push: float, src: String) -> void:
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
	_ev({"type": "colpito_nemico", "dmg": dmg, "seg": s, "src": src, "who": f.idx, "armor": was_tele and src != "contro"})
	if _check_end():
		return
	if est == "crollo":
		return
	if seg <= 0.0:
		_crollo()
		return
	if was_tele and src != "contro":
		return
	if f.idx != active and src != "entrata":
		return     # i colpi del compagno fanno danno ma non fermano il nemico: lo scontro lo guidi tu
	hits_in_row += 1
	if est != "air" and est != "down":
		est = "stun"
		est_t = maxf(est_t, 0.35) if est == "stun" else 0.35
	_push_enemy((epos - f.pos).normalized(), push)
	if hits_in_row >= SCROLLATA_HITS and est == "stun":
		hits_in_row = 0
		for g in fighters:
			if g.front and epos.distance_to(g.pos) < 3.0:
				g.pos = epos + (g.pos - epos).normalized() * 3.0
		_ev({"type": "scrollata"})
		_next_attack(true)


func _crollo() -> void:
	est = "crollo"
	est_t = CROLLO_TIME
	estring.clear()
	eatk = {}
	e_air = 0.0
	hits_in_row = 0
	_ev({"type": "crollo"})


func _push_enemy(dir: Vector2, push: float) -> void:
	if push <= 0.0:
		return
	var np: Vector2 = epos + dir * push
	if np.length() >= R - 1.0:
		epos = np.normalized() * (R - 1.0)
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
			if seg <= 0.0:
				_crollo()
		return
	epos = np


func _check_end() -> bool:
	if ehp <= 0.0:
		ehp = 0.0
		est = "dead"
		over = "vittoria"
		_ev({"type": "vittoria", "time": time, "found": found.size()})
		return true
	var alive: int = 0
	for f in fighters:
		if f.st != "ko":
			alive += 1
	if alive == 0:
		over = "sconfitta"
		_ev({"type": "sconfitta", "time": time})
		return true
	return false


func _back_has(passive: String) -> bool:
	for f in fighters:
		if not f.front and f.st != "ko" and f.passive == passive:
			return true
	return false


# ================================================================ il compagno in campo (combatte da solo)

func _tick_partner() -> void:
	var p: Fighter = partner()
	if p == null:
		return
	p.mv = Vector2.ZERO
	p.ai_cool -= TICK
	if p.st != "idle":
		return
	if est == "tele" and etarget == p.idx and p.ai_seen != attack_id:
		var left: float = float(eatk["impact"]) - float(eatk["t"])
		if left <= 0.22:
			p.ai_seen = attack_id
			if rng.randf() < 0.75:
				_try(p, "dx" if eatk["kind"] == "affondo" else "salto", true)
		return
	var d: float = epos.distance_to(p.pos)
	var open: bool = est in ["stun", "rec", "crollo", "down", "idle"]
	if open and d <= REACH and p.ai_cool <= 0.0 and p.p_air <= 0.0:
		_try(p, "tocco", true)
		p.ai_cool = 0.45
		return
	# si piazza di fianco al nemico, a 90 gradi dal controllato
	var side: Vector2 = (me().pos - epos).normalized().rotated(PI * 0.5) * 1.7
	var goal: Vector2 = epos + side
	var to_goal: Vector2 = goal - p.pos
	if to_goal.length() > 0.2:
		var fw: Vector2 = forward(p)
		var v: Vector2 = to_goal.normalized()
		p.mv = Vector2(v.dot(Vector2(-fw.y, fw.x)), v.dot(fw)) * 0.8


# ================================================================ nemico

func _tick_enemy() -> void:
	if est != "crollo" and est != "dead" and time - last_seg_loss > SEG_REGEN_AFTER:
		seg = minf(SEG_MAX, seg + SEG_REGEN * TICK)
	var tgt: Fighter = fighters[etarget]
	if tgt.st == "ko" or not tgt.front:
		_pick_target()
		tgt = fighters[etarget]
	if est in ["idle", "rec"]:
		var want: Vector2 = (tgt.pos - epos).normalized()
		var ang: float = efacing.angle_to(want)
		efacing = efacing.rotated(clampf(ang, -ENEMY_TURN * TICK, ENEMY_TURN * TICK))
	match est:
		"idle":
			var d: float = epos.distance_to(tgt.pos)
			if d > 3.0:
				epos += (tgt.pos - epos).normalized() * ENEMY_SPEED * TICK
			idle_wait -= TICK
			if idle_wait <= 0.0:
				_next_attack(false)
		"tele":
			eatk["t"] = float(eatk["t"]) + TICK
			if eatk["kind"] == "affondo" and float(eatk["t"]) < float(eatk["impact"]) * 0.5:
				# la mira segue il bersaglio solo nella prima metà: poi la linea è fissa e si può scartare
				var want2: Vector2 = (tgt.pos - epos).normalized()
				efacing = efacing.rotated(clampf(efacing.angle_to(want2), -ENEMY_TURN * 1.5 * TICK, ENEMY_TURN * 1.5 * TICK))
				eatk["dir"] = efacing
			if float(eatk["t"]) >= float(eatk["impact"]):
				_impact()
		"rec", "stun", "down":
			est_t -= TICK
			if est_t <= 0.0:
				if est == "rec" and not estring.is_empty():
					_start_tele(estring.pop_front())
				else:
					idle_wait = 0.25 if est == "stun" else rng.randf_range(0.5, 1.0) * (0.8 if phase > 0 else 1.0)
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


func _pick_target() -> void:
	var opts: Array = []
	for f in fighters:
		if f.front and f.st != "ko":
			opts.append(f.idx)
	if opts.is_empty():
		return
	etarget = active if opts.has(active) and (opts.size() == 1 or rng.randf() < 0.65) else int(opts[rng.randi_range(0, opts.size() - 1)])


func _next_attack(now: bool) -> void:
	_pick_target()
	var s: Array = STRINGS[rng.randi_range(0, STRINGS.size() - 1)].duplicate(true)
	if phase > 0 and rng.randf() < 0.5:
		s.append(STRINGS[rng.randi_range(0, 2)][0].duplicate())
	estring = s
	_start_tele(estring.pop_front())
	if now:
		eatk["impact"] = float(eatk["impact"]) + 0.2


func _start_tele(a: Array) -> void:
	var kind: String = a[0]
	var w: float = float(ATTACKS[kind]["windup"]) * (0.85 if phase > 0 else 1.0)
	attack_id += 1
	efacing = (fighters[etarget].pos - epos).normalized()
	eatk = {"kind": kind, "color": a[1], "impact": w, "t": 0.0, "dir": efacing, "target": etarget, "id": attack_id}
	est = "tele"
	hits_in_row = 0
	walled = false
	_ev({"type": "mirino", "kind": kind, "color": a[1], "windup": w, "target": etarget})


func _in_danger(f: Fighter) -> bool:
	var a: Dictionary = ATTACKS[eatk["kind"]]
	var rel: Vector2 = f.pos - epos
	if eatk["kind"] == "spazzata":
		return rel.length() <= float(a["radius"]) and f.p_air <= 0.0
	var dir: Vector2 = eatk["dir"]
	var along: float = rel.dot(dir)
	var side: float = absf(rel.dot(Vector2(-dir.y, dir.x)))
	return along >= -0.3 and along <= float(a["len"]) + BODY and side <= float(a["width"])


func _impact() -> void:
	var kind: String = eatk["kind"]
	var a: Dictionary = ATTACKS[kind]
	var gap: float = STRING_GAP
	var hit_any: bool = false
	for f in fighters:
		if not f.front or f.st == "ko":
			continue
		if not _in_danger(f):
			if kind == "spazzata" and f.p_air > 0.0 and epos.distance_to(f.pos) <= float(a["radius"]):
				gap = 1.0
				castigo_until = time + 1.1
				_ev({"type": "saltata", "who": f.idx})
			continue
		hit_any = true
		if f.iframes > 0.0:
			var perfect: bool = f.st == "dodge" and time - f.dodge_start <= DODGE_PERFECT
			if perfect and f.idx == active:
				fiato = minf(FIATO_MAX, fiato + 10.0)
			_ev({"type": "schivata", "who": f.idx, "kind": kind, "perfect": perfect})
			continue
		var dmg: float = float(a["dmg"])
		if kind == "affondo" and time <= f.esposto_until:
			dmg *= 2.0
		# COPERTURA: uno dei due dietro si mette in mezzo se il colpo ti lascerebbe a terra o quasi
		if f.hp - dmg <= f.maxhp * 0.25 and time >= cover_ready:
			for b in fighters:
				if not b.front and b.st != "ko":
					cover_ready = time + COVER_CD * (0.6 if _back_has("guardia") else 1.0)
					_ev({"type": "copertura", "who": b.idx, "for": f.idx})
					dmg = 0.0
					break
		if dmg <= 0.0:
			continue
		f.hp -= dmg
		f.move = {}
		f.chain = 0
		f.p_air = 0.0
		f.st = "hurt"
		f.st_t = 0.9 if kind == "spazzata" else 0.4
		f.pos = epos + (f.pos - epos).normalized() * (epos.distance_to(f.pos) + (0.8 if kind == "spazzata" else 1.6))
		_keep_apart(f)
		if f.idx == active:
			pending = {}
			holding = false
			if plan_active:
				plan.clear()
				plan_active = false
				_ev({"type": "piano_fine", "why": "colpito"})
		_ev({"type": "colpito", "who": f.idx, "kind": kind, "dmg": dmg, "doppio": dmg > float(a["dmg"])})
		if f.hp <= 0.0:
			_ko(f)
	if kind == "affondo":
		var dir: Vector2 = eatk["dir"]
		var np: Vector2 = epos + dir * minf(3.0, float(a["len"]) * 0.5)
		epos = np.normalized() * minf(np.length(), R - 1.0)
		for f in fighters:
			if f.front:
				_keep_apart(f)
	if not hit_any:
		gap = maxf(gap, STRING_GAP + 0.6)
		_ev({"type": "nemico_a_vuoto", "kind": kind})
	for f in fighters:
		f.esposto_until = -1.0
	eatk = {}
	if est == "tele":
		est = "rec"
		est_t = gap if not estring.is_empty() else gap + 0.3
	_check_end()


func _ko(f: Fighter) -> void:
	f.hp = 0.0
	f.st = "ko"
	_ev({"type": "ko", "who": f.idx})
	# entra il primo dietro ancora in piedi
	for b in fighters:
		if not b.front and b.st != "ko":
			b.front = true
			f.front = false
			b.pos = f.pos
			b.st = "idle"
			_ev({"type": "entra", "who": b.idx, "for": f.idx})
			if f.idx == active:
				active = b.idx
			return
	if f.idx == active:
		var p: Fighter = partner()
		if p != null:
			active = p.idx


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
