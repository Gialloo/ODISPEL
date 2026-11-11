extends Node
## Servizi di "game feel" condivisi: hitstop, rallentamento dei nemici,
## scosse della telecamera, suoni e scintille. Tempo reale = Time.get_ticks_msec,
## così hitstop e rallentamento non si mangiano a vicenda.

signal shake_requested(strength: float, duration: float)

## Moltiplicatore del tempo dei nemici (schivata perfetta = rallentano solo loro).
var enemy_time := 1.0

var _hitstop_until := 0
var _slow_until := 0
var _slow_factor := 1.0
var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _world: Node3D

## Parametri regolabili dal pannello (laboratorio).
var tune := {
	"hitstop_scale": 1.0,   # moltiplica la durata degli arresti all'impatto
	"shake_scale": 1.0,
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in ["colpo", "colpo_forte", "colpo_finale", "critico", "ferita", "break", "combo", "cutin", "schivata", "ko", "scudo", "ui_ok"]:
		var p := "res://assets/audio/%s.ogg" % n
		if ResourceLoader.exists(p):
			_sounds[n] = load(p)
	for i in 8:
		var a := AudioStreamPlayer.new()
		a.bus = "Master"
		add_child(a)
		_players.append(a)

## Contatori per i test e il laboratorio.
var stats := {}

func stat(key: String, n := 1) -> void:
	stats[key] = stats.get(key, 0) + n

func set_world(w: Node3D) -> void:
	_world = w

func now() -> int:
	return Time.get_ticks_msec()

## Arresto all'impatto: congela tutto per qualche frame.
func hitstop(ms: float) -> void:
	ms *= tune.hitstop_scale
	if ms <= 0.0:
		return
	_hitstop_until = max(_hitstop_until, now() + int(ms))
	Engine.time_scale = 0.03

## Rallenta solo i nemici (tempo reale in secondi).
func slow_enemies(factor: float, seconds: float) -> void:
	_slow_factor = factor
	_slow_until = now() + int(seconds * 1000.0)
	enemy_time = factor

func is_slowed() -> bool:
	return now() < _slow_until

func shake(strength: float, duration := 0.18) -> void:
	shake_requested.emit(strength * tune.shake_scale, duration)

func sound(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not _sounds.has(name):
		return
	var a := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	a.stream = _sounds[name]
	a.pitch_scale = pitch * randf_range(0.95, 1.05)
	a.volume_db = volume_db
	a.play()

## Scintille: piccoli cubi che schizzano via (pool semplice, niente particelle GPU).
func sparks(pos: Vector3, dir: Vector3, color: Color, count := 8, speed := 7.0) -> void:
	if _world == null:
		return
	for i in count:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3.ONE * randf_range(0.05, 0.12)
		m.mesh = b
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		m.material_override = mat
		_world.add_child(m)
		m.global_position = pos
		var v := (dir.normalized() + Vector3(randf_range(-0.8, 0.8), randf_range(0.0, 1.0), randf_range(-0.8, 0.8))).normalized() * speed * randf_range(0.5, 1.2)
		var t := m.create_tween()
		t.set_parallel(true)
		t.tween_property(m, "global_position", pos + v * 0.25, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property(m, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(m.queue_free)

## Anello a terra (onde d'urto, atterraggi, schivate perfette).
func ring(pos: Vector3, color: Color, radius := 2.0, time := 0.3) -> void:
	if _world == null:
		return
	var m := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.85
	t.outer_radius = 1.0
	t.rings = 24
	t.ring_segments = 4
	m.mesh = t
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	m.material_override = mat
	_world.add_child(m)
	m.global_position = pos + Vector3(0, 0.05, 0)
	m.scale = Vector3(0.2, 0.2, 0.2)
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(radius, 0.4, radius), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, time)
	tw.chain().tween_callback(m.queue_free)

func _process(_d: float) -> void:
	var t := now()
	if Engine.time_scale < 1.0 and t >= _hitstop_until:
		Engine.time_scale = 1.0
	if enemy_time < 1.0 and t >= _slow_until:
		# rientro morbido dal rallentamento
		enemy_time = min(1.0, enemy_time + 0.08)
	elif t < _slow_until:
		enemy_time = _slow_factor

## SOVRACCARICA: esplosione che sbilancia e lancia tutto ciò che è vicino.
func overcharge_blast(pos: Vector3, source: Node) -> void:
	ring(pos, Color(1, 0.85, 0.2, 0.9), 4.0, 0.35)
	sparks(pos, Vector3.UP, Color(1, 0.85, 0.2), 18, 10.0)
	sound("break", 0.8)
	shake(0.7)
	hitstop(110)
	stat("overcharge_blasts")
	var tree := get_tree()
	for e in tree.get_nodes_in_group("enemies"):
		if e == source or e.is_dead():
			continue
		var to: Vector3 = e.global_position - pos
		to.y = 0
		if to.length() < 4.0:
			e.receive_hit({"dmg": 22.0, "poise": 60.0, "dir": to.normalized() if to.length() > 0.1 else Vector3.FORWARD,
				"knock": 9.0, "launch": 7.0, "form": -1, "move": "blast", "env": true})
	for p in tree.get_nodes_in_group("props"):
		if p == source:
			continue
		var to2: Vector3 = p.center() - pos
		if to2.length() < 4.0 and p.has_method("structure_damage"):
			p.structure_damage(30.0)
		if to2.length() < 4.0 and p.has_method("launch") and not p.is_dead():
			p.launch((to2.normalized() + Vector3(0, 0.6, 0)) * 14.0, null)
