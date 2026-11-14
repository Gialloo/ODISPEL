extends Node
## La run: ondate infinite, difficoltà che cresce, scelta di potenziamenti, ripartenza immediata.
## I potenziamenti sono dati in data/upgrades.json (nome, famiglia, descrizione): si cambiano lì.
## Scelta: JSON e non .tres perché si modifica con qualsiasi editor di testo, anche dal telefono.

signal wave_started(n: int, theme: String)
signal choice_open(options: Array)
signal choice_closed
signal run_over(wave: int, kills: int)
signal score_changed(score: int)
signal combo_banked(hits: int, pts: int)

const Enemy = preload("res://scripts/enemies/enemy.gd")
const COST := {"scout": 1.0, "conduit": 2.0, "brute": 3.0}
## Punteggio (0.9): nemici sconfitti per tipo + combo. Una combo è una serie di colpi a segno
## con meno di COMBO_GAP secondi tra l'uno e l'altro; si incassa quando si chiude, si perde se ti colpiscono.
const KILL_PTS := {"scout": 100, "conduit": 160, "brute": 260, "boss": 1500, "traliccio": 1800}
const COMBO_GAP := 2.5
## Sicurezza (0.9): 5 secondi nel cerchio centrale con nessun nemico vicino = l'ondata riparte comunque.
const CIRCLE_R := 6.0
const CIRCLE_TIME := 5.0
const CFG_PATH := "user://overload.cfg"

var main: Node
var wave := 0
var owned: Array = []
var defs: Array = []
var alive := 0
var kills := 0
var running := false
var training := false                  # 0.19: Allenamento (manichini fermi, niente ondate)
var choosing := false
var options: Array = []
var _queue: Array = []
var _spawn_t := 0.0
var _between := 0.0
var _seen := {}
var theme := ""
var score := 0
var best := 0
var combo := 0                         # colpi della combo in corso
var combos := 0                        # combo incassate (almeno 3 colpi)
var best_combo := 0
var circle_t := 0.0                    # secondi passati nel cerchio centrale (per la HUD)
var opt := {"look": 1.0, "cam_dist": 4.7, "volume": 0.8, "shake": 1.0, "auto_cam": true, "flash": true, "film": true}
var _combo_t := 0.0
var _pending := 0                      # nemici annunciati ma non ancora entrati
var _run_id := 0                       # i timer di una run vecchia non toccano quella nuova
var _stall_t := 0.0
## 0.7: ondate più brevi e più frequenti; ogni tanto un'ondata a tema (si legge subito cosa arriva).
const THEMES := {4: "SCIAME", 7: "CORAZZATI", 10: "TEMPESTA"}
var choice_every := 2                  # una scelta ogni N ondate (dopo la 1, la 3, la 5...)

func _ready() -> void:
	var f := FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if f:
		defs = JSON.parse_string(f.get_as_text())
	_load_cfg()

func _load_cfg() -> void:
	var c := ConfigFile.new()
	if c.load(CFG_PATH) != OK:
		return
	best = int(c.get_value("score", "best", 0))
	for k in opt:
		opt[k] = c.get_value("options", k, opt[k])
	apply_opt()

func apply_opt() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(float(opt.volume), 0.0001)))
	AudioServer.set_bus_mute(0, float(opt.volume) <= 0.001)

func save_cfg() -> void:
	var c := ConfigFile.new()
	c.set_value("score", "best", best)
	for k in opt:
		c.set_value("options", k, opt[k])
	c.save(CFG_PATH)

func stop() -> void:
	running = false
	training = false
	_run_id += 1
	_queue.clear()
	_pending = 0

func start(m: Node) -> void:
	main = m
	training = false
	wave = 0
	owned.clear()
	alive = 0
	kills = 0
	score = 0
	combo = 0
	combos = 0
	best_combo = 0
	_combo_t = 0.0
	_pending = 0
	_run_id += 1
	circle_t = 0.0
	_stall_t = 0.0
	_queue.clear()
	_seen.clear()
	choosing = false
	running = true
	_between = 1.2
	El.tune.chain = 4
	El.tune.enemy_hop = 2.6
	score_changed.emit(0)

## 0.19: ALLENAMENTO. Stessa arena (bobina e pozza, bidoni, casse, muretto, blocco di metallo),
## un manichino per tipo davanti a te: Scout, Bruto e Conduit. Non attaccano (il Conduit spara
## una sfera ogni tanto), quando cadono tornano dopo un attimo, la vita del giocatore si ricarica.
## Serve a imparare le diramazioni delle combo e la usano anche le prove automatiche.
const TRAINING_SPOTS := {"scout": Vector3(0, 0.2, 0), "brute": Vector3(-6, 0.2, -3), "conduit": Vector3(6, 0.2, -3)}

func start_training(m: Node) -> void:
	start(m)
	training = true
	_between = 0.0
	for a in TRAINING_SPOTS:
		_spawn_dummy(a, TRAINING_SPOTS[a])

func _spawn_dummy(arch: String, p: Vector3) -> void:
	if not training or main == null:
		return
	var rid := _run_id
	var e := Enemy.new()
	e.setup(arch, 1)
	e.dummy = true
	e.home = p
	e.player = main.player
	e.tune = main.enemy_tune
	e.position = p
	main.enemies.add_child(e)
	FX.ring(p, Color(1, 1, 1, 0.6), 1.8, 0.3)
	e.died.connect(func(_x):
		if rid != _run_id:
			return
		kills += 1
		get_tree().create_timer(1.2, false).timeout.connect(func():
			if rid == _run_id and training:
				_spawn_dummy(arch, p)))

func _tick_training(delta: float) -> void:
	_tick_combo(delta)
	var pl = main.player
	if pl.hp < pl.max_hp and pl.hp > 0.0:
		pl.hp = min(pl.max_hp, pl.hp + 25.0 * delta)
		pl.hp_changed.emit(pl.hp, pl.max_hp)

func has(id: String) -> bool:
	return owned.has(id)

func def(id: String) -> Dictionary:
	for d in defs:
		if d.id == id:
			return d
	return {}

func max_alive() -> int:
	return mini(2 + wave / 2 + (2 if theme == "SCIAME" else 0), 7)

## Nemici vivi contati dal vero (gruppo "enemies") più quelli annunciati:
## il vecchio contatore poteva restare sporco e bloccare l'ondata (il blocco alla 5).
func _count_alive() -> int:
	var n := _pending
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_dead() and not e.is_queued_for_deletion():
			n += 1
	return n

func _process(delta: float) -> void:
	if not running or choosing or main == null:
		return
	if training:
		_tick_training(delta)
		return
	alive = _count_alive()
	_tick_combo(delta)
	_tick_circle(delta)
	if _between > 0.0:
		_between -= delta
		if _between <= 0.0:
			_next_wave()
		return
	if not _queue.is_empty():
		_spawn_t -= delta
		if _spawn_t <= 0.0 and alive < max_alive():
			_spawn(_queue.pop_front())
			_spawn_t = max(0.5, 1.1 - wave * 0.04)
	elif alive <= 0:
		_wave_cleared()
	else:
		_watchdog(delta)

## Rete di sicurezza: se per 25 s nessun nemico è vicino al giocatore, quelli lontani
## (incastrati o finiti fuori) vengono riportati in campo.
func _watchdog(delta: float) -> void:
	var pl: Node3D = main.player
	var near := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.distance_to(pl.global_position) < 14.0:
			near = true
			break
	_stall_t = 0.0 if near else _stall_t + delta
	if _stall_t > 25.0:
		_stall_t = 0.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.has_method("recall"):
				e.recall(main.arena.spawn_point())
		FX.stat("watchdog_recalls")

func _tick_circle(delta: float) -> void:
	var pl: Node3D = main.player
	var p: Vector3 = pl.global_position
	var inside: bool = Vector2(p.x, p.z).length() < CIRCLE_R and p.y < 1.0 and pl.state != pl.S.DEAD
	if inside and _between <= 0.0:
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.is_dead() and e.global_position.distance_to(p) < 9.0:
				inside = false
				break
	if not inside:
		circle_t = 0.0
		return
	circle_t += delta
	if circle_t >= CIRCLE_TIME:
		circle_t = 0.0
		force_next_wave()

## Il cerchio centrale fa partire l'ondata dopo: i nemici rimasti lontani spariscono, la coda si svuota.
func force_next_wave() -> void:
	FX.stat("circle_starts")
	FX.ring(Vector3(0, 0.1, 0), Color(0.4, 0.9, 1.0, 0.9), CIRCLE_R, 0.5)
	FX.sound("cutin", 1.2, -4.0)
	_queue.clear()
	_pending = 0
	_run_id += 1                            # gli annunci in corso non entrano più
	for e in get_tree().get_nodes_in_group("enemies"):
		e.remove_from_group("enemies")
		FX.sparks(e.global_position + Vector3(0, 1, 0), Vector3.UP, Color(0.4, 0.9, 1.0), 8, 6.0)
		e.queue_free()
	alive = 0
	if _between > 0.0:
		_between = 0.01
	else:
		_wave_cleared()

# ------------------------------------------------------------ punteggio

func combo_hit(n := 1) -> void:
	if not running:
		return
	combo += n
	_combo_t = COMBO_GAP

func combo_break() -> void:
	if combo > 0:
		FX.stat("combos_lost")
	combo = 0
	_combo_t = 0.0

func _tick_combo(delta: float) -> void:
	if combo <= 0:
		return
	_combo_t -= delta * (0.62 if has("combo_lunga") else 1.0)
	if _combo_t <= 0.0:
		_bank_combo()

func _bank_combo() -> void:
	var hits := combo
	combo = 0
	if hits < 3:
		return
	# cresce più che in proporzione: le combo lunghe valgono davvero
	var pts := int(hits * 25 * (1.0 + hits / 10.0) * (1.25 if has("combo_lunga") else 1.0))
	combos += 1
	best_combo = maxi(best_combo, hits)
	FX.stat("combos")
	add_score(pts)
	combo_banked.emit(hits, pts)

func add_score(pts: int) -> void:
	score += pts
	score_changed.emit(score)

func _next_wave() -> void:
	wave += 1
	theme = ""
	var cyc := wave if wave <= 10 else 4 + (wave - 4) % 7
	if THEMES.has(cyc) or (wave > 10 and wave % 3 == 1):
		theme = THEMES.get(cyc, ["SCIAME", "CORAZZATI", "TEMPESTA"][wave % 3])
	if wave % 5 == 0:
		theme = "COLOSSO"   # 0.15: ogni quinta ondata un boss, con una piccola scorta
	if wave % 10 == 0:
		theme = "TRALICCIO" # 0.17: ogni decima il boss è il TRALICCIO (5 COLOSSO, 10 TRALICCIO, 15 COLOSSO...)
	_queue = _compose_theme(wave, theme) if theme != "" else _compose(wave)
	_spawn_t = 0.3
	FX.stat("waves")
	if theme != "":
		FX.stat("theme_waves")
	wave_started.emit(wave, theme)

func _compose_theme(w: int, th: String) -> Array:
	var list: Array = []
	match th:
		"COLOSSO":
			list = ["boss"]
			for i in 1 + w / 5:
				list.append("scout")
			if w >= 10:
				list.append("conduit")
		"TRALICCIO":
			# scorta di corpo a corpo: ti spingono verso le sue scariche
			list = ["traliccio", "scout", "scout"]
			for i in w / 10:
				list.append("scout")
			if w >= 20:
				list.append("brute")
		"SCIAME":
			# tanti Scout, uno dopo l'altro: velocità e spazio
			for i in 4 + w:
				list.append("scout")
		"CORAZZATI":
			list = ["brute", "brute", "scout", "scout"]
			for i in w / 4:
				list.append("brute" if i % 2 == 0 else "scout")
		"TEMPESTA":
			# Conduit in gruppo: le pozze e le bobine diventano il campo di battaglia
			list = ["conduit", "conduit", "conduit", "scout", "scout"]
			for i in w / 4:
				list.append("conduit")
	return list

## Composizione controllata: casuale ma sempre leggibile. Nuovi archetipi entrano uno alla volta.
func _compose(w: int) -> Array:
	var budget := 2.0 + w * 1.2
	var list: Array = []
	var brutes := 0
	if w == 2:
		list.append("conduit")
		budget -= COST.conduit
	elif w == 3:
		list.append("brute")
		budget -= COST.brute
		brutes = 1
	while budget >= 1.0:
		var pool := ["scout", "scout", "scout"]
		if w >= 2:
			pool += ["conduit"] if w < 5 else ["conduit", "conduit"]
		if w >= 3 and brutes < 1 + w / 5 and budget >= COST.brute:
			pool += ["brute"] if w < 6 else ["brute", "brute"]
		var k: String = pool[randi() % pool.size()]
		if COST[k] > budget:
			k = "scout"
		if k == "brute":
			brutes += 1
		list.append(k)
		budget -= COST[k]
	list.shuffle()
	return list

func _spawn(arch: String) -> void:
	var p: Vector3 = main.arena.spawn_point()
	if main.player.global_position.distance_to(p) < 7.0:
		p = Vector3(-p.x, p.y, -p.z)
	FX.ring(p, Color(1, 0.3, 0.3, 0.8) if arch == "scout" else (Color(1, 0.6, 0.2, 0.9) if arch == "brute" or arch == "boss" else Color(0.4, 0.8, 1.0, 0.9)), 3.5 if arch == "boss" or arch == "traliccio" else 2.0, 0.6)
	_pending += 1
	var rid := _run_id
	get_tree().create_timer(0.6, false).timeout.connect(func():
		if rid != _run_id or not running or main == null:
			return
		_pending = max(0, _pending - 1)
		var e := Enemy.new()
		var is_boss := arch == "boss" or arch == "traliccio"
		e.setup("brute" if arch == "boss" else ("conduit" if arch == "traliccio" else arch), wave, is_boss)
		e.player = main.player
		e.tune = main.enemy_tune
		e.position = p
		main.enemies.add_child(e)
		e.died.connect(func(_x):
			if rid != _run_id:
				return
			kills += 1
			if has("rigenerazione") and main and main.player.hp > 0.0:
				main.player.hp = min(main.player.max_hp, main.player.hp + 4.0)
				main.player.hp_changed.emit(main.player.hp, main.player.max_hp)
			if is_boss and main and main.player.hp > 0.0:
				# premio: mezza vita indietro
				main.player.hp = min(main.player.max_hp, main.player.hp + main.player.max_hp * 0.5)
				main.player.hp_changed.emit(main.player.hp, main.player.max_hp)
			add_score(int(KILL_PTS.get(arch, 100) * (1.0 + 0.05 * (wave - 1)))))
		FX.stat("spawn_" + arch))

func _wave_cleared() -> void:
	FX.stat("waves_cleared")
	# piccola cura tra un'ondata e l'altra
	var pl = main.player
	pl.hp = min(pl.max_hp, pl.hp + pl.max_hp * 0.25)
	pl.hp_changed.emit(pl.hp, pl.max_hp)
	if wave % choice_every == 1 or choice_every == 1:
		_open_choice()
	else:
		_between = 1.2

func _open_choice() -> void:
	var free: Array = defs.filter(func(d): return not owned.has(d.id))
	if free.is_empty():
		_between = 2.0
		return
	free.shuffle()
	options = []
	var fams := {}
	for d in free:
		if options.size() < 3 and not fams.has(d.family):
			options.append(d)
			fams[d.family] = true
	for d in free:
		if options.size() < 3 and not options.has(d):
			options.append(d)
	choosing = true
	get_tree().paused = true
	choice_open.emit(options)

func choose(i: int) -> void:
	if not choosing or i < 0 or i >= options.size():
		return
	var d: Dictionary = options[i]
	owned.append(d.id)
	FX.stat("upgrades_taken")
	FX.stat("up_" + d.id)
	if d.id == "vigore" and main:
		main.player.max_hp += 30.0
		main.player.hp = main.player.max_hp
		main.player.hp_changed.emit(main.player.hp, main.player.max_hp)
	if d.id == "propagazione":
		El.tune.chain = 7
		El.tune.enemy_hop = 3.9
	choosing = false
	get_tree().paused = false
	choice_closed.emit()
	_between = 1.0

func game_over() -> void:
	if not running:
		return
	_bank_combo()
	running = false
	if score > best and not main.get_meta("bot", false) and not training:
		best = score
		save_cfg()
	FX.stat("runs_over")
	run_over.emit(wave, kills)
