extends Node3D
## OVERLOAD 0.1 · Fase 1: arena, protagonista, un nemico alla volta, comandi touch e tastiera.

const Arena = preload("res://scripts/world/arena.gd")
const Player = preload("res://scripts/player/player.gd")
const CamRig = preload("res://scripts/player/cam_rig.gd")
const Enemy = preload("res://scripts/enemies/enemy.gd")
const Hud = preload("res://scripts/ui/hud.gd")
const Touch = preload("res://scripts/ui/touch.gd")

var arena: Node3D
var player: CharacterBody3D
var cam: Node3D
var enemies: Node3D
var hud: CanvasLayer
var touch: Control
var enemy_tune := {
	"speed": 6.5, "attack_range": 2.3, "windup": 0.55, "lunge_speed": 13.0, "active": 0.16,
	"recover": 0.65, "damage": 12.0, "cooldown_min": 1.2, "cooldown_max": 2.4,
}
var max_enemies := 1
var _mouse_captured := false
var _is_touch := false

func _ready() -> void:
	randomize()
	FX.set_world(self)
	_is_touch = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")
	arena = Arena.new()
	add_child(arena)
	enemies = Node3D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	player = Player.new()
	player.position = Vector3(0, 0.2, 6)
	player.enemies_root = enemies
	add_child(player)
	cam = CamRig.new()
	cam.target = player
	add_child(cam)
	player.cam = cam
	player.died.connect(_on_player_died)
	hud = Hud.new()
	hud.player = player
	hud.cam = cam
	hud.enemy_tune = enemy_tune
	add_child(hud)
	touch = Touch.new()
	touch.visible = _is_touch
	hud.add_child(touch)
	hud.touch = touch
	hud.bind()
	for i in max_enemies:
		spawn_enemy()
	if not _is_touch:
		hud.message("WASD muovi · mouse guarda · clic attacca (tieni = pesante)\nSPAZIO salto · SHIFT schivata · Q aggancio · TAB laboratorio", 4.0)

func spawn_enemy() -> void:
	var e := Enemy.new()
	e.player = player
	e.tune = enemy_tune
	var p: Vector3 = arena.spawn_point()
	if player.global_position.distance_to(p) < 7.0:
		p = -p
	e.position = p
	enemies.add_child(e)
	e.died.connect(func(_x): get_tree().create_timer(1.2).timeout.connect(spawn_enemy))
	FX.ring(p, Color(1, 0.3, 0.3, 0.8), 2.0, 0.4)

func _on_player_died() -> void:
	hud.message("A TERRA", 1.2)
	get_tree().create_timer(1.6).timeout.connect(func():
		player.revive()
		player.global_position = Vector3(0, 0.5, 0))

# ------------------------------------------------------------ tastiera e mouse

func _unhandled_input(event: InputEvent) -> void:
	if _is_touch:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _mouse_captured and event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				_mouse_captured = true
				return
			if event.pressed:
				Pad.press("attack")
			else:
				Pad.release("attack")
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			Pad.press("lock")
			Pad.release("lock")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				Pad.press("dodge")
			else:
				Pad.release("dodge")
	elif event is InputEventMouseMotion and _mouse_captured:
		Pad.look += event.relative
	elif event is InputEventKey and not event.echo:
		var map := {KEY_SPACE: "jump", KEY_SHIFT: "dodge", KEY_Q: "lock", KEY_J: "attack", KEY_K: "dodge"}
		if map.has(event.keycode):
			if event.pressed:
				Pad.press(map[event.keycode])
			else:
				Pad.release(map[event.keycode])
		elif event.keycode == KEY_ESCAPE and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
		elif event.keycode == KEY_TAB and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
			hud.toggle_panel()

func _process(_d: float) -> void:
	if _is_touch:
		return
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D): v.x += 1
	if Input.is_physical_key_pressed(KEY_A): v.x -= 1
	if Input.is_physical_key_pressed(KEY_W): v.y += 1
	if Input.is_physical_key_pressed(KEY_S): v.y -= 1
	var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy.length() > 0.2:
		v = joy
	if not get_meta("bot", false):
		Pad.move = v.limit_length(1.0)
	var rs := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if rs.length() > 0.2:
		Pad.look += rs * 14.0
