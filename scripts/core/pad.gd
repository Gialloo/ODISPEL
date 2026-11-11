extends Node
## Ingresso unico per touch, tastiera/mouse e test automatici.
## Il giocatore legge solo da qui: così i comandi si cambiano senza toccare il combattimento.

const ACTIONS := ["attack", "jump", "dodge", "lock", "power"]

var move := Vector2.ZERO          # x = destra, y = avanti (lunghezza 0..1)
var look := Vector2.ZERO          # delta accumulato nel frame (pixel)
var _held := {}
var _pressed_at := {}             # msec dell'ultima pressione
var _just := {}
var _released := {}

func _ready() -> void:
	process_physics_priority = 1000   # azzera i "just" dopo che il giocatore li ha letti
	for a in ACTIONS:
		_held[a] = false
		_pressed_at[a] = 0
		_just[a] = false
		_released[a] = false

func press(a: String) -> void:
	if not _held[a]:
		_held[a] = true
		_just[a] = true
		_pressed_at[a] = Time.get_ticks_msec()

func release(a: String) -> void:
	if _held[a]:
		_held[a] = false
		_released[a] = true

func held(a: String) -> bool:
	return _held[a]

func just(a: String) -> bool:
	return _just[a]

func just_released(a: String) -> bool:
	return _released[a]

## Da quanti secondi (reali) il tasto è premuto.
func held_time(a: String) -> float:
	if not _held[a]:
		return 0.0
	return (Time.get_ticks_msec() - _pressed_at[a]) / 1000.0

func take_look() -> Vector2:
	var l := look
	look = Vector2.ZERO
	return l

func _physics_process(_d: float) -> void:
	# i "just" vivono un solo tick di fisica: il giocatore li legge nel suo tick
	for a in ACTIONS:
		_just[a] = false
		_released[a] = false
