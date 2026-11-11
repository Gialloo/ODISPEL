extends Node
## La run: ondate infinite, difficoltà che cresce, scelta di potenziamenti, ripartenza immediata.
## I potenziamenti sono dati in data/upgrades.json (nome, famiglia, descrizione): si cambiano lì.
## Scelta: JSON e non .tres perché si modifica con qualsiasi editor di testo, anche dal telefono.

signal wave_started(n: int, theme: String)
signal choice_open(options: Array)
signal choice_closed
signal run_over(wave: int, kills: int)

const Enemy = preload("res://scripts/enemies/enemy.gd")
const COST := {"scout": 1.0, "conduit": 2.0, "brute": 3.0}

var main: Node
var wave := 0
var owned: Array = []
var defs: Array = []
var alive := 0
var kills := 0
var running := false
var choosing := false
var options: Array = []
var _queue: Array = []
var _spawn_t := 0.0
var _between := 0.0
var _seen := {}
var theme := ""
## 0.7: ondate più brevi e più frequenti; ogni tanto un'ondata a tema (si legge subito cosa arriva).
const THEMES := {4: "SCIAME", 7: "CORAZZATI", 10: "TEMPESTA"}
var choice_every := 2                  # una scelta ogni N ondate (dopo la 1, la 3, la 5...)

func _ready() -> void:
	var f := FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if f:
		defs = JSON.parse_string(f.get_as_text())

func start(m: Node) -> void:
	main = m
	wave = 0
	owned.clear()
	alive = 0
	kills = 0
	_queue.clear()
	_seen.clear()
	choosing = false
	running = true
	_between = 1.2
	El.tune.chain = 4
	El.tune.enemy_hop = 2.6

func has(id: String) -> bool:
	return owned.has(id)

func def(id: String) -> Dictionary:
	for d in defs:
		if d.id == id:
			return d
	return {}

func max_alive() -> int:
	return mini(2 + wave / 2 + (2 if theme == "SCIAME" else 0), 7)

func _process(delta: float) -> void:
	if not running or choosing or main == null:
		return
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

func _next_wave() -> void:
	wave += 1
	theme = ""
	var cyc := wave if wave <= 10 else 4 + (wave - 4) % 7
	if THEMES.has(cyc) or (wave > 10 and wave % 3 == 1):
		theme = THEMES.get(cyc, ["SCIAME", "CORAZZATI", "TEMPESTA"][wave % 3])
	_queue = _compose_theme(wave, theme) if theme != "" else _compose(wave)
	_spawn_t = 0.3
	FX.stat("waves")
	if theme != "":
		FX.stat("theme_waves")
	wave_started.emit(wave, theme)

func _compose_theme(w: int, th: String) -> Array:
	var list: Array = []
	match th:
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
	FX.ring(p, Color(1, 0.3, 0.3, 0.8) if arch == "scout" else (Color(1, 0.6, 0.2, 0.9) if arch == "brute" else Color(0.4, 0.8, 1.0, 0.9)), 2.0, 0.6)
	alive += 1
	get_tree().create_timer(0.6, false).timeout.connect(func():
		if not running or main == null:
			return
		var e := Enemy.new()
		e.setup(arch, wave)
		e.player = main.player
		e.tune = main.enemy_tune
		e.position = p
		main.enemies.add_child(e)
		e.died.connect(func(_x):
			alive -= 1
			kills += 1)
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
	running = false
	FX.stat("runs_over")
	run_over.emit(wave, kills)
