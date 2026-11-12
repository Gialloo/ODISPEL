class_name CsBattle
extends RefCounted

# CONTROSEGNALE · motore del combattimento in tempo reale a contrattacchi.
# Logica pura, senza nodi: la scena chiama step(dt reale) e gli input, e legge lo stato e gli eventi.
# Il tempo del gioco avanza a tick fissi (CsContent.TICK), così la stessa sequenza dà sempre lo stesso risultato.
# Ogni contromisura ai difetti del modello è segnata con il suo codice (D2, D3, D10, D11, D12): vedi CONTROSEGNALE_PROGETTO.md.

const C = preload("res://scripts/controsegnale/cs_content.gd")

var t: float = 0.0                 # tempo di gioco
var real_idle: float = 0.0         # secondi reali senza tocchi (per il RALLENTY)
var paused: bool = false
var auto_slow: bool = true
var wide: bool = false             # finestra AMPIA
var heroes: Array = []
var active: int = 0
var enemies: Array = []
var target: int = 0
var diretta: float = 0.0
var last_action_t: float = 0.0
var combo: int = 0
var last_hit_t: float = -99.0
var last_press_t: float = -99.0
var buffered: Dictionary = {}      # {"color", "enemy"}: tocco ricordato prima della finestra (D12)
var miss_streak: int = 0
var hint_given: bool = false
var over: bool = false
var won: bool = false
var events: Array = []
var stats: Dictionary = {}
var encounter: String = ""
var _acc: float = 0.0


func _init(hero_ids: Array = ["lance", "rio"], enemy_ids: Array = ["frammento"]) -> void:
	for id in hero_ids:
		var d: Dictionary = C.HEROES[id]
		heroes.append({"id": id, "name": d["name"], "hp": int(d["hp"]), "max": int(d["hp"]), "set": 1, "ready": {},
			"queue": [], "busy_until": 0.0, "ko": false, "revive_at": -1.0, "guard": false})
	for i in range(enemy_ids.size()):
		var id: String = enemy_ids[i]
		var e: Dictionary = C.ENEMIES[id]
		enemies.append({"id": id, "name": e["name"], "hp": int(e["hp"]), "max": int(e["hp"]), "segnale": float(e["segnale"]),
			"segnale_max": float(e["segnale"]), "dmg": int(e["dmg"]), "pattern": e["pattern"], "pi": 0, "attack": {},
			"next_at": 1.5 + 0.7 * i, "furia": 0.0, "furia_left": 0, "blackout_until": -1.0, "specchio": str(e.get("specchio", "")),
			"tag": "", "tag_until": -1.0, "last_hit_t": 0.0, "phase": 1, "phase2": e.get("phase2", {}), "boss": bool(e.get("boss", false)),
			"finale_used": false})
	encounter = enemy_ids[0] if enemy_ids.size() == 1 else "+".join(enemy_ids)
	stats = {"contro": 0, "perfetti": 0, "mancati": 0, "colpi_colorati": 0, "danni_presi": 0, "mosse": {},
		"diretta_sum": 0.0, "diretta_n": 0, "scarti": 0, "blackout": 0, "durata": 0.0}


# ================================================================ input

# Tocco di un tasto colore: CONTRO se c'è un colpo in arrivo, altrimenti mossa in coda.
func press(color: String) -> void:
	if over or paused:
		return
	real_idle = 0.0
	if t - last_press_t < C.SIMUL:          # D12: due tocchi quasi insieme valgono uno
		return
	last_press_t = t
	var ei: int = _incoming()
	if ei >= 0:                              # D2: con un colpo in arrivo il colore è sempre un CONTRO, mai una mossa
		_try_counter(ei, color)
		return
	_enqueue(active, color)


# SCARTO: evita il colpo (unico modo per i colpi SFONDA). Non toglie segnale: è la risposta sicura, non la migliore (D10).
func dodge() -> void:
	if over or paused:
		return
	real_idle = 0.0
	var ei: int = _incoming()
	if ei < 0:
		_ev({"t": "scarto_a_vuoto"})
		return
	var e: Dictionary = enemies[ei]
	var d: float = t - float(e["attack"]["impact"])
	if d < -_w(C.WIN_GOOD_BEFORE) or d > _w(C.WIN_GOOD_AFTER):
		_ev({"t": "presto", "enemy": ei})
		return
	e["attack"]["resolved"] = true
	stats["scarti"] += 1
	var perfect: bool = absf(d) <= _w(C.WIN_PERFECT)
	if str(e["attack"]["color"]) == C.BIANCO:
		_gain_diretta(C.DIRETTA_CONTRO if perfect else C.DIRETTA_HIT)
	_ev({"t": "scarto", "enemy": ei, "perfect": perfect, "color": e["attack"]["color"]})
	_after_attack(ei)


func swap() -> void:
	if over:
		return
	real_idle = 0.0
	var other: int = 1 - active
	if other < heroes.size() and not heroes[other]["ko"]:
		active = other
		_ev({"t": "cambio", "hero": heroes[active]["id"]})


func toggle_set() -> void:
	real_idle = 0.0
	var h: Dictionary = heroes[active]
	h["set"] = 2 if int(h["set"]) == 1 else 1
	_ev({"t": "set", "hero": h["id"], "set": h["set"]})


# Mossa in coda al compagno (sempre dal set 1).
func partner_press(color: String) -> void:
	if over or paused:
		return
	real_idle = 0.0
	var other: int = 1 - active
	if other < heroes.size() and _incoming() < 0:
		_enqueue(other, color, 1)


# Colpo finale di coppia sul nemico in BLACKOUT; poi RIAVVIO: cooldown azzerati.
func finale() -> void:
	if over or paused:
		return
	real_idle = 0.0
	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		if _in_blackout(e) and not e["finale_used"]:
			e["finale_used"] = true
			_damage_enemy(i, int(float(e["max"]) * C.FINALE_FRAC * _diretta_mult()), "finale")
			for h in heroes:
				h["ready"] = {}
			_ev({"t": "finale", "enemy": i})
			_ev({"t": "riavvio"})
			return


func set_target(i: int) -> void:
	if i >= 0 and i < enemies.size() and int(enemies[i]["hp"]) > 0:
		target = i


func set_paused(p: bool) -> void:
	paused = p
	real_idle = 0.0


# ================================================================ tempo

func step(real_dt: float) -> void:
	if paused or over:
		return
	real_idle += real_dt
	var scale: float = C.SLOW_SCALE if auto_slow and real_idle > C.IDLE_SLOW_AFTER else 1.0
	_acc += real_dt * scale
	while _acc >= C.TICK and not over:
		_acc -= C.TICK
		_tick(C.TICK)


func is_slow() -> bool:
	return auto_slow and real_idle > C.IDLE_SLOW_AFTER and not paused


func _tick(dt: float) -> void:
	t += dt
	stats["durata"] = t
	stats["diretta_sum"] += float(C.step_of(diretta))
	stats["diretta_n"] += 1
	if t - last_action_t > C.DIRETTA_IDLE_AFTER:   # D3 e D11: cala solo se stai fermo, e mai sotto il gradino
		var floor_v: float = float(C.DIRETTA_STEPS[C.step_of(diretta)])
		diretta = maxf(floor_v, diretta - C.DIRETTA_IDLE_RATE * dt)
	for i in range(heroes.size()):
		var h: Dictionary = heroes[i]
		if h["ko"] and float(h["revive_at"]) >= 0.0 and t >= float(h["revive_at"]):
			h["ko"] = false
			h["hp"] = int(h["max"] * C.PARTNER_REVIVE_HP)
			h["revive_at"] = -1.0
			_ev({"t": "rialzato", "hero": h["id"]})
	var frozen: bool = _incoming() >= 0           # D2: la coda si congela, non si perde
	if not frozen:
		for i in range(heroes.size()):
			_run_queue(i)
	for i in range(enemies.size()):
		_enemy_tick(i, dt)


func _enemy_tick(i: int, dt: float) -> void:
	var e: Dictionary = enemies[i]
	if int(e["hp"]) <= 0:
		return
	if _in_blackout(e):
		return
	if float(e["blackout_until"]) >= 0.0 and t >= float(e["blackout_until"]):
		e["blackout_until"] = -1.0
		e["segnale"] = e["segnale_max"]
		e["finale_used"] = false
		e["next_at"] = t + 1.0
		_ev({"t": "segnale_torna", "enemy": i})
	if t - float(e["last_hit_t"]) > 2.0:            # D3: se lo lasci stare monta la FURIA
		e["furia"] = minf(C.FURIA_MAX, float(e["furia"]) + C.FURIA_RATE * dt)
		if float(e["furia"]) >= C.FURIA_MAX and int(e["furia_left"]) == 0:
			e["furia_left"] = C.FURIA_ATTACKS
			e["furia"] = 0.0
			_ev({"t": "furia", "enemy": i})
	var a: Dictionary = e["attack"]
	if a.is_empty():
		if t >= float(e["next_at"]):
			var p: Dictionary = e["pattern"][int(e["pi"]) % e["pattern"].size()]
			e["attack"] = {"color": p["color"], "impact": t + float(p["windup"]), "windup": float(p["windup"]),
				"gap": float(p["gap"]), "resolved": false, "early": -99.0}
			if str(p["color"]) != C.BIANCO:
				stats["colpi_colorati"] += 1
			_ev({"t": "mirino", "enemy": i, "color": p["color"], "impact": e["attack"]["impact"]})
		return
	var d: float = t - float(a["impact"])
	if not buffered.is_empty() and int(buffered["enemy"]) == i and d >= -_w(C.WIN_GOOD_BEFORE):
		var col: String = buffered["color"]
		buffered = {}
		_resolve_counter(i, col, false)
		return
	if d > _w(C.WIN_GOOD_AFTER):
		_hit_hero(i, 1.0, "colpito")


# ================================================================ CONTRO

func _try_counter(i: int, color: String) -> void:
	var e: Dictionary = enemies[i]
	var a: Dictionary = e["attack"]
	var d: float = t - float(a["impact"])
	var gb: float = _w(C.WIN_GOOD_BEFORE)
	if d < -gb:
		if d >= -gb - _w(C.BUFFER) and t - float(a["early"]) > 0.2:   # D12: il tocco viene ricordato
			buffered = {"color": color, "enemy": i}
			return
		a["early"] = t                                  # troppo presto: niente danno, ma un attimo di blocco contro chi martella
		_ev({"t": "presto", "enemy": i})
		return
	if t - float(a["early"]) < 0.2:
		return
	_resolve_counter(i, color, absf(d) <= _w(C.WIN_PERFECT))


func _resolve_counter(i: int, color: String, perfect: bool) -> void:
	var e: Dictionary = enemies[i]
	var a: Dictionary = e["attack"]
	var ac: String = a["color"]
	if ac == C.BIANCO:                                  # SFONDA: col colore non si para
		_hit_hero(i, 1.0, "sfonda")
		return
	if color != ac:                                     # colore sbagliato: para a metà, niente contro
		_hit_hero(i, C.WRONG_COLOR_DMG, "colore_sbagliato")
		return
	a["resolved"] = true
	stats["contro"] += 1
	miss_streak = 0
	if perfect:
		stats["perfetti"] += 1
	if e["specchio"] == color:                          # D10: lo SPECCHIO restituisce il segnale
		e["segnale"] = minf(float(e["segnale_max"]), float(e["segnale"]) + C.SEGNALE_SPECCHIO_HEAL)
		_ev({"t": "specchio", "enemy": i, "color": color})
		_after_attack(i)
		return
	var s: float = C.SEGNALE_CONTRO_PERFECT if perfect else C.SEGNALE_CONTRO
	if _tag_on(e, color):
		s *= C.TAG_SEGNALE_MULT
	e["segnale"] = maxf(0.0, float(e["segnale"]) - s)
	_gain_diretta(C.DIRETTA_CONTRO_PERFECT if perfect else C.DIRETTA_CONTRO)
	_ev({"t": "contro", "enemy": i, "color": color, "perfect": perfect, "segnale": e["segnale"]})
	_damage_enemy(i, int(C.COUNTER_HIT_DMG * _diretta_mult()), "contro")
	if float(e["segnale"]) <= 0.0 and int(e["hp"]) > 0:
		e["blackout_until"] = t + C.BLACKOUT_TIME
		e["attack"] = {}
		stats["blackout"] += 1
		_ev({"t": "blackout", "enemy": i})
		return
	_after_attack(i)


func _hit_hero(i: int, mult: float, why: String) -> void:
	var e: Dictionary = enemies[i]
	e["attack"]["resolved"] = true
	stats["mancati"] += 1
	miss_streak += 1
	var h: Dictionary = heroes[active]
	var dmg: float = float(e["dmg"]) * mult
	if h["guard"]:
		dmg *= 0.5
		h["guard"] = false
	var n: int = int(round(dmg))
	h["hp"] = maxi(0, int(h["hp"]) - n)
	stats["danni_presi"] += n
	_drop_diretta()                                     # D11: un gradino, mai tutto
	_ev({"t": why, "enemy": i, "hero": h["id"], "dmg": n})
	if miss_streak >= C.MISS_STREAK_HINT and not wide and not hint_given:
		hint_given = true
		_ev({"t": "proponi_ampia"})
	if int(h["hp"]) <= 0:
		_ko(active)
	_after_attack(i)


func _after_attack(i: int) -> void:
	var e: Dictionary = enemies[i]
	if e["attack"].is_empty():
		return
	var gap: float = float(e["attack"]["gap"])
	if int(e["furia_left"]) > 0:
		gap *= C.FURIA_INTERVAL_MULT
		e["furia_left"] = int(e["furia_left"]) - 1
	e["next_at"] = t + gap
	e["pi"] = int(e["pi"]) + 1
	e["attack"] = {}
	if buffered.has("enemy") and int(buffered["enemy"]) == i:
		buffered = {}


func _ko(hi: int) -> void:
	var h: Dictionary = heroes[hi]
	h["ko"] = true
	h["queue"] = []
	_ev({"t": "ko", "hero": h["id"]})
	var other: int = 1 - hi
	if other < heroes.size() and not heroes[other]["ko"]:
		h["revive_at"] = t + C.PARTNER_REVIVE
		active = other
		_ev({"t": "cambio", "hero": heroes[active]["id"]})
	else:
		over = true
		won = false
		_ev({"t": "sconfitta"})


# ================================================================ mosse

func _enqueue(hi: int, color: String, force_set: int = 0) -> void:
	var h: Dictionary = heroes[hi]
	if h["ko"]:
		return
	var set_n: int = force_set if force_set > 0 else int(h["set"])
	var m: Dictionary = C.HEROES[h["id"]]["set%d" % set_n][color]
	if set_n == 2 and t < float(h["ready"].get(m["id"], 0.0)):
		_ev({"t": "in_ricarica", "hero": h["id"], "move": m["id"]})
		return
	if h["queue"].size() >= C.QUEUE_MAX:
		_ev({"t": "coda_piena", "hero": h["id"]})
		return
	h["queue"].append({"move": m, "color": color})
	_ev({"t": "in_coda", "hero": h["id"], "move": m["id"], "n": h["queue"].size()})


func _run_queue(hi: int) -> void:
	var h: Dictionary = heroes[hi]
	if h["ko"] or h["queue"].is_empty() or t < float(h["busy_until"]):
		return
	var q: Dictionary = h["queue"].pop_front()
	var m: Dictionary = q["move"]
	var color: String = q["color"]
	var id: String = m["id"]
	h["busy_until"] = t + float(m["dur"])
	last_action_t = t
	stats["mosse"][id] = int(stats["mosse"].get(id, 0)) + 1
	var kind: String = str(m.get("kind", "hit"))
	var ready_at: float = float(h["ready"].get(id, 0.0))
	h["ready"][id] = t + float(m["cd"])
	match kind:
		"guard":
			h["guard"] = true
			_ev({"t": "guardia", "hero": h["id"]})
		"heal":
			h["hp"] = mini(int(h["max"]), int(h["hp"]) + int(m["amount"]))
			_ev({"t": "cura", "hero": h["id"], "amount": m["amount"]})
		"tag":
			var e: Dictionary = enemies[_live_target()]
			e["tag"] = m["tag"]
			e["tag_until"] = t + C.TAG_TIME
			_ev({"t": "tag", "enemy": _live_target(), "color": m["tag"]})
		"diretta":
			_gain_diretta(float(m["amount"]))
		_:
			var ti: int = _live_target()
			if ti < 0:
				return
			var e2: Dictionary = enemies[ti]
			var dmg: float = float(m["dmg"]) * _diretta_mult()
			if t < ready_at:
				dmg *= C.COOLDOWN_WEAK_MULT
			if _tag_on(e2, color):
				dmg *= C.TAG_DMG_MULT
			combo = combo + 1 if t - last_hit_t <= C.COMBO_GAP else 1
			last_hit_t = t
			_gain_diretta(C.DIRETTA_HIT)
			_damage_enemy(ti, int(round(dmg)), id)


func _damage_enemy(i: int, amount: int, src: String) -> void:
	var e: Dictionary = enemies[i]
	if int(e["hp"]) <= 0:
		return
	if _in_blackout(e) and src != "finale":
		amount = int(amount * C.BLACKOUT_DMG_MULT)
	e["hp"] = maxi(0, int(e["hp"]) - amount)
	e["last_hit_t"] = t
	e["furia"] = 0.0
	_ev({"t": "danno", "enemy": i, "amount": amount, "src": src, "combo": combo})
	if not e["phase2"].is_empty() and int(e["phase"]) == 1 and int(e["hp"]) * 2 <= int(e["max"]):
		e["phase"] = 2
		if e["phase2"].has("specchio"):
			e["specchio"] = str(e["phase2"]["specchio"])
		_ev({"t": "fase2", "enemy": i, "specchio": e["specchio"]})
	if int(e["hp"]) <= 0:
		e["attack"] = {}
		_ev({"t": "nemico_giu", "enemy": i})
		if _live_target() < 0:
			over = true
			won = true
			_ev({"t": "vittoria", "voto": vote()})


# ================================================================ VOTO DELLA DIRETTA

# Media, non record: tempo, danni presi, CONTRO, varietà, DIRETTA media (D6, D7, D11).
func vote() -> Dictionary:
	var par: float = float(C.PAR_TIME.get(encounter, 60.0))
	var dur: float = maxf(1.0, float(stats["durata"]))
	var v_time: float = clampf(par / dur, 0.0, 1.0) * 100.0
	var max_hp: int = 0
	for h in heroes:
		max_hp += int(h["max"])
	var v_dmg: float = clampf(1.0 - float(stats["danni_presi"]) / float(max_hp), 0.0, 1.0) * 100.0
	var faced: int = maxi(1, int(stats["colpi_colorati"]))
	var v_contro: float = clampf((float(stats["contro"]) + 0.5 * float(stats["perfetti"])) / float(faced), 0.0, 1.0) * 100.0
	var v_var: float = clampf(float(stats["mosse"].size()) / 8.0, 0.0, 1.0) * 100.0
	var v_dir: float = (float(stats["diretta_sum"]) / maxf(1.0, float(stats["diretta_n"]))) / 3.0 * 100.0
	var total: float = v_time * 0.2 + v_dmg * 0.25 + v_contro * 0.25 + v_var * 0.15 + v_dir * 0.15
	var grade: String = "C"
	if total >= 90.0:
		grade = "S"
	elif total >= 70.0:
		grade = "A"
	elif total >= 50.0:
		grade = "B"
	return {"voto": grade, "punti": int(round(total)), "tempo": int(v_time), "danni": int(v_dmg), "contro": int(v_contro),
		"varieta": int(v_var), "diretta": int(v_dir)}


# ================================================================ aiuti

func _incoming() -> int:
	var best: int = -1
	var best_t: float = INF
	for i in range(enemies.size()):
		var a: Dictionary = enemies[i]["attack"]
		if a.is_empty() or a["resolved"]:
			continue
		var imp: float = float(a["impact"])
		if t >= imp - C.DANGER_LEAD and imp < best_t:
			best = i
			best_t = imp
	return best


func _live_target() -> int:
	if target < enemies.size() and int(enemies[target]["hp"]) > 0:
		return target
	for i in range(enemies.size()):
		if int(enemies[i]["hp"]) > 0:
			target = i
			return i
	return -1


func _w(v: float) -> float:
	return v * (C.WIDE_MULT if wide else 1.0)


func _in_blackout(e: Dictionary) -> bool:
	return float(e["blackout_until"]) >= 0.0 and t < float(e["blackout_until"])


func _tag_on(e: Dictionary, color: String) -> bool:
	return str(e["tag"]) == color and t < float(e["tag_until"])


func _gain_diretta(v: float) -> void:
	last_action_t = t
	diretta = minf(C.DIRETTA_MAX, diretta + v)


func _drop_diretta() -> void:
	var s: int = C.step_of(diretta)
	diretta = 0.0 if s == 0 else float(C.DIRETTA_STEPS[s - 1])


func _diretta_mult() -> float:
	return float(C.DIRETTA_MULT[C.step_of(diretta)])


func _ev(e: Dictionary) -> void:
	e["at"] = t
	events.append(e)


func take_events() -> Array:
	var out: Array = events
	events = []
	return out
