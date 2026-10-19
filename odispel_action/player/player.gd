class_name Player
extends CharacterBody3D

# Il personaggio giocante. Applica il PlayerMotor con la fisica e anima il
# corpo provvisorio (capsula, visore e nucleo luminoso: non e' il modello finale).
# Chi lo comanda e' intent_source: un nodo con il metodo get_intent() -> PlayerIntent.
# Senza intent_source il personaggio sta fermo.

const HEIGHT: float = 1.8
const RADIUS: float = 0.4
const FALL_LIMIT: float = -20.0

@export var power_color: String = "viola"

var motor: PlayerMotor = PlayerMotor.new()
var intent_source: Node = null
var spawn_point: Vector3 = Vector3.ZERO

var _visual: Node3D
var _roll: Node3D
var _squash: float = 0.0


func _ready() -> void:
	collision_layer = GameLayers.PLAYER
	collision_mask = GameLayers.WORLD
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.35
	floor_constant_speed = true
	spawn_point = global_position
	motor.facing = -global_basis.z
	motor.jumped.connect(func() -> void: _squash = -0.18)
	motor.landed.connect(func() -> void: _squash = 0.22)
	_build_visual()


func _physics_process(delta: float) -> void:
	var intent: PlayerIntent = intent_source.get_intent() if intent_source != null else PlayerIntent.new()
	velocity = motor.step(intent, is_on_floor(), delta)
	move_and_slide()
	motor.velocity = velocity
	if global_position.y < FALL_LIMIT:
		respawn()
	_animate(delta)


func respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	motor.velocity = Vector3.ZERO
	motor.state = PlayerMotor.State.AIR
	reset_physics_interpolation()


func _animate(delta: float) -> void:
	_visual.rotation.y = atan2(-motor.facing.x, -motor.facing.z)

	# Schivata: una capriola in avanti, raccolti.
	var p: float = motor.dodge_progress()
	_roll.rotation.x = -TAU * ease(p, 0.6) if motor.is_dodging() else 0.0
	var tuck: float = sin(p * PI) * 0.25 if motor.is_dodging() else 0.0

	# Schiacciamento all'atterraggio, allungamento al salto.
	_squash = move_toward(_squash, 0.0, delta * 1.6)
	var s: float = _squash + tuck
	_visual.scale = Vector3(1.0 + s * 0.5, 1.0 - s, 1.0 + s * 0.5)


func _build_visual() -> void:
	var accent: Color = ActionTheme.POWER_COLORS.get(power_color, ActionTheme.CY)
	var body_mat := ActionTheme.flat_material(accent.darkened(0.45), 0.6)

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_roll = Node3D.new()
	_roll.name = "Roll"
	_roll.position.y = HEIGHT * 0.5
	_visual.add_child(_roll)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	body.mesh = capsule
	body.material_override = body_mat
	_roll.add_child(body)

	# Visore: mostra dove guarda il personaggio.
	_add_box(Vector3(0.52, 0.12, 0.14), Vector3(0.0, 0.62, -0.32), ActionTheme.glow_material(accent, 3.0))
	# Nucleo sul petto: il colore del potere.
	_add_box(Vector3(0.18, 0.18, 0.1), Vector3(0.0, 0.2, -0.38), ActionTheme.glow_material(ActionTheme.WH, 2.0))
	# Sciarpa sulla schiena: rende leggibile il retro della sagoma.
	_add_box(Vector3(0.16, 0.6, 0.06), Vector3(0.12, 0.2, 0.42), ActionTheme.glow_material(ActionTheme.RD, 1.5))


func _add_box(size: Vector3, pos: Vector3, material: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = material
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_roll.add_child(mi)
