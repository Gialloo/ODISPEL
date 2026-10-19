class_name DebugHud
extends Label

# Riquadro in alto a sinistra: FPS, stato del personaggio, velocita' e comandi.
# Serve a riportare i numeri quando si prova su un telefono. F3 lo nasconde.

var player: Player = null


func _ready() -> void:
	position = Vector2(16.0, 12.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_override("font", ActionTheme.mono())
	add_theme_font_size_override("font_size", 15)
	add_theme_color_override("font_color", ActionTheme.CY)
	add_theme_color_override("font_outline_color", ActionTheme.BK)
	add_theme_constant_override("outline_size", 4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible


func _process(_delta: float) -> void:
	if not visible or player == null:
		return
	var state_names: Array = ["A TERRA", "IN ARIA", "SCHIVATA"]
	var lines: Array = [
		"ODISPEL ACTION  prototipo fase B",
		"FPS %d   stato %s   vel %.1f m/s   alt %.2f m" % [
			Engine.get_frames_per_second(),
			state_names[player.motor.state],
			player.motor.horizontal_speed(),
			player.global_position.y,
		],
	]
	if not OS.has_feature("mobile"):
		lines.append("WASD muovi  SPAZIO salta  SHIFT schiva  clic = mouse telecamera  ESC libera  F1 touch  F3 info")
	text = "\n".join(lines)
