class_name ImpactLab
extends Control

# Prova degli impact frames senza combattere: quattro bottoni, uno per livello (con le impostazioni reali del giocatore).
# Solo presentazione: nessun dato di battaglia viene toccato.

var _fx: Control
var _director: ImpactDirector = ImpactDirector.new()
var _label: Label


static func open(host: Node) -> ImpactLab:
	var lab := ImpactLab.new()
	host.add_child(lab)
	return lab


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#10101c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -190.0
	box.offset_left = 20.0
	box.offset_right = -20.0
	box.offset_bottom = -12.0
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_label = BattleTheme.make_label("PROVA IMPACT FRAMES  -  premi un livello", 18, BattleTheme.CY_DIM)
	box.add_child(_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var names: Array = ["1 CRITICO", "2 DANNO ECCEZIONALE", "3 ULT CRITICA", "4 ULT DEVASTANTE"]
	for i in 4:
		var b := Button.new()
		b.text = str(names[i])
		b.custom_minimum_size = Vector2(0, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		BattleTheme.style_button(b, "normal", 16)
		b.pressed.connect(_fire.bind(i + 1))
		row.add_child(b)
	var close := Button.new()
	close.text = "CHIUDI"
	close.custom_minimum_size = Vector2(0, 44)
	BattleTheme.style_button(close, "normal", 17)
	close.pressed.connect(queue_free)
	box.add_child(close)


func _fire(level: int) -> void:
	var hs: float = _director.play(level, _fx, null, size * Vector2(0.5, 0.35))
	_label.text = "Livello %d  -  hit-stop %d ms  -  %s" % [level, int(hs * 1000.0), "versione ridotta" if not AnimFx.enabled() else "completo"]
