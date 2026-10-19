extends Node3D

# Scena di prova della fase B: arena, personaggio, telecamera e comandi.
# Qui si collegano i pezzi; ognuno resta indipendente dagli altri.

@onready var arena: TestArena = $Arena
@onready var player: Player = $Player
@onready var follow_camera: FollowCamera = $FollowCamera
@onready var input_source: LocalInputSource = $LocalInputSource
@onready var touch_controls: TouchControls = $HUD/TouchControls
@onready var debug_hud: DebugHud = $HUD/DebugHud


func _ready() -> void:
	player.global_position = TestArena.PLAYER_SPAWN
	player.spawn_point = TestArena.PLAYER_SPAWN
	input_source.setup(follow_camera, touch_controls)
	player.intent_source = input_source
	follow_camera.target = player
	follow_camera.snap_to_target()
	debug_hud.player = player
