class_name ScreenFx
extends RefCounted

# Sovrapposizioni a tutto schermo (telecamera di sorveglianza, retino da fumetto).
# I materiali sono condivisi da tutte le schermate: un solo shader compilato e un solo
# oggetto, invece di uno nuovo ogni volta che si apre un menu.

static var _cctv_material: ShaderMaterial = null
static var _halftone_material: ShaderMaterial = null
static var _battle_material: ShaderMaterial = null
static var _menu_material: ShaderMaterial = null


static func _full_rect(parent: Control, material: Material) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = material
	parent.add_child(r)
	return r


# Linee di scansione, vignettatura e disturbo.
static func cctv(parent: Control) -> ColorRect:
	if _cctv_material == null:
		_cctv_material = ShaderMaterial.new()
		_cctv_material.shader = load("res://shaders/cctv_overlay.gdshader")
	return _full_rect(parent, _cctv_material)


# Puntini che si ingrossano verso i bordi e il basso.
static func halftone(parent: Control) -> ColorRect:
	if _halftone_material == null:
		_halftone_material = ShaderMaterial.new()
		_halftone_material.shader = load("res://shaders/halftone.gdshader")
	return _full_rect(parent, _halftone_material)


# Fondo pieno a tutto schermo (non cattura il mouse). Il nero del gioco e' gia' il colore con cui
# lo schermo viene pulito a ogni frame (project.godot): disegnarlo ancora sarebbe un passaggio a
# tutto schermo sprecato, quindi quel rettangolo resta nell'albero ma non viene disegnato.
static func solid(parent: Control, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.visible = not color.is_equal_approx(BattleTheme.BK)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


# Strisce di sfondo + telecamera: lo strato comune a tutti i menu.
static func menu_overlays(parent: Control, accent: Color = BattleTheme.RD) -> void:
	MenuBackdrop.add_to(parent, accent, -1, false)
	if _menu_material == null:
		_menu_material = ShaderMaterial.new()
		_menu_material.shader = load("res://shaders/battle_overlay.gdshader")
		_menu_material.set_shader_parameter("tint", Color(0, 0, 0, 0))
		_menu_material.set_shader_parameter("dots_on_top", false)
		# nei menu il velo e' solo una leggera vignettatura: niente retino, righe o rumore sopra le scritte
		_menu_material.set_shader_parameter("halftone_strength", 0.0)
		_menu_material.set_shader_parameter("scan_strength", 0.0)
		_menu_material.set_shader_parameter("noise_strength", 0.0)
		_menu_material.set_shader_parameter("vignette_strength", 0.35)
	_full_rect(parent, _menu_material)


# Velo della battaglia: velatura + telecamera + retino in un solo passaggio.
static func battle(parent: Control) -> ColorRect:
	if Settings.light_fx:
		# effetti ridotti: niente passaggio a tutto schermo (un rettangolo trasparente, per non cambiare la struttura)
		var empty := ColorRect.new()
		empty.color = Color(0, 0, 0, 0)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.set_anchors_preset(Control.PRESET_FULL_RECT)
		parent.add_child(empty)
		return empty
	if _battle_material == null:
		_battle_material = ShaderMaterial.new()
		_battle_material.shader = load("res://shaders/battle_overlay.gdshader")
	return _full_rect(parent, _battle_material)
