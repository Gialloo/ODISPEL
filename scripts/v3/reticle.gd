class_name Reticle
extends Control

# MIRINO sul bersaglio: quattro angoli del colore di chi e' di turno attorno al nemico, finche' il giocatore deve scegliere.
# Dice "tocca a te e colpisci QUI" senza coprire nulla (Persona 5: il bersaglio si illumina; Star Rail: il mirino del nemico).
# Costa un solo nodo che si ridisegna se cambia colore o grandezza (niente _draw a ogni fotogramma), e l'animazione e' una scala.

var col: Color = Ui.YELLOW
var half: float = 70.0                 # meta' lato del mirino
var _t: float = 0.0
var _pop: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	custom_minimum_size = Vector2.ZERO
	size = Vector2.ZERO
	z_index = 1


func _ready() -> void:
	set_process(false)
	visibility_changed.connect(func() -> void: set_process(visible))


# Accende il mirino con lo scatto di aggancio (grande che si stringe) nel colore di chi agisce
func lock_on(c: Color, h: float) -> void:
	col = c
	half = h
	visible = true
	queue_redraw()
	if _pop != null and _pop.is_valid():
		_pop.kill()
	scale = Vector2(1.7, 1.7)
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Conferma del comando: il mirino scatta stretto e si spegne (la risposta all'azione arriva entro 100 ms)
func confirm() -> void:
	if not visible:
		return
	if _pop != null and _pop.is_valid():
		_pop.kill()
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2(0.78, 0.78), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pop.tween_callback(func() -> void: visible = false)


func _process(delta: float) -> void:
	_t += delta
	# respira appena (la scala base e' 1: l'animazione di aggancio ha la precedenza mentre gira)
	if _pop == null or not _pop.is_running():
		var k: float = 1.0 + 0.04 * sin(_t * 5.0)
		scale = Vector2(k, k)


func _draw() -> void:
	var arm: float = half * 0.38
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var c := Vector2(half * sx, half * sy)
			var pts := PackedVector2Array([c - Vector2(arm * sx, 0.0), c, c - Vector2(0.0, arm * sy)])
			draw_polyline(pts, Ui.INK, 11.0)        # contorno scuro: si legge su qualsiasi sfondo
			draw_polyline(pts, col, 6.0)
