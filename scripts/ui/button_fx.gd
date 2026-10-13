class_name ButtonFx
extends RefCounted

# Reazione visiva dei pulsanti: ingrandimento al passaggio del mouse, "schiacciamento" quando si preme,
# lampo bianco alla conferma. Si applica a ogni pulsante dall'AudioManager (stesso punto dei suoni).
# Non cambia il layout: usa solo la scala e il colore del pulsante.

const HOVER_SCALE: float = 1.045
const DOWN_SCALE: float = 0.94
const POP_SCALE: float = 1.09
const FLASH: Color = Color(1.9, 1.9, 1.9, 1.0)

# Parole iniziali che cambiano il suono: tornare indietro / confermare un'azione importante.
const BACK_WORDS: Array = ["TORNA", "INDIETRO", "ESCI", "SALTA", "CHIUDI", "ANNULLA"]
const GO_WORDS: Array = ["AVVIA", "RECLUTA", "RIGIOCA", "CONTINUA", "CREA", "ENTRA", "POTENZIA", "PRONTO", "AVANTI"]


static func hook(b: BaseButton) -> void:
	b.mouse_entered.connect(_hover.bind(b, true))
	b.mouse_exited.connect(_hover.bind(b, false))
	b.button_down.connect(_down.bind(b))
	b.button_up.connect(_up.bind(b))
	b.pressed.connect(_confirm.bind(b))
	_tune.call_deferred(b)


# Sul telefono i pulsanti scattano al tocco, non al rilascio (risposta immediata). Restano al rilascio quelli
# dentro una lista che scorre (il dito che scorre non deve premere) e quelli con scheda a pressione lunga.
static func _tune(b: BaseButton) -> void:
	if not is_instance_valid(b) or not TouchUi.active() or b.has_meta("hinted"):
		return
	var n: Node = b.get_parent()
	while n != null:
		if n is ScrollContainer:
			return
		n = n.get_parent()
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS


static func _tween(b: BaseButton, scale: float, time: float, bounce: bool = false) -> void:
	if not b.is_inside_tree():
		return
	b.pivot_offset = b.size * 0.5
	if b.has_meta("fx_tween"):
		var old: Variant = b.get_meta("fx_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var tw: Tween = b.create_tween()
	tw.tween_property(b, "scale", Vector2(scale, scale), time).set_trans(Tween.TRANS_BACK if bounce else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	b.set_meta("fx_tween", tw)


static func _hover(b: BaseButton, inside: bool) -> void:
	if b.disabled:
		return
	_tween(b, HOVER_SCALE if inside else 1.0, 0.09)


static func _down(b: BaseButton) -> void:
	if not b.disabled:
		_tween(b, DOWN_SCALE, 0.05)


static func _up(b: BaseButton) -> void:
	if b.disabled:
		return
	var rest: float = HOVER_SCALE if b.is_hovered() else 1.0
	_tween(b, maxf(rest, POP_SCALE) if b.is_hovered() else 1.0, 0.07, true)
	if b.is_inside_tree() and b.is_hovered():
		b.get_tree().create_timer(0.1).timeout.connect(func() -> void:
			if is_instance_valid(b) and b.is_inside_tree() and b.is_hovered():
				_tween(b, HOVER_SCALE, 0.08))


static func _confirm(b: BaseButton) -> void:
	if b.disabled or not b.is_inside_tree():
		return
	b.modulate = FLASH
	var tw: Tween = b.create_tween()
	tw.tween_property(b, "modulate", Color.WHITE, 0.22)
	Settings.buzz(18)


# Suono giusto per il pulsante: indietro, conferma, oppure il click normale.
static func sound_for(b: BaseButton) -> String:
	var t: String = ""
	if b is Button:
		t = (b as Button).text.strip_edges().replace(" ", "").to_upper()
	for w in BACK_WORDS:
		if t.begins_with(w):
			return "back"
	for w in GO_WORDS:
		if t.begins_with(w):
			return "ready"
	return "click"


# Scossa orizzontale: "no, questo non si puo' fare".
static func shake(b: Control) -> void:
	if not b.is_inside_tree() or b.has_meta("fx_shaking"):
		return
	b.set_meta("fx_shaking", true)
	var home: float = b.position.x
	var tw: Tween = b.create_tween()
	for dx in [-6.0, 6.0, -4.0, 4.0, 0.0]:
		tw.tween_property(b, "position:x", home + dx, 0.04)
	tw.finished.connect(func() -> void:
		if is_instance_valid(b):
			b.remove_meta("fx_shaking"))
