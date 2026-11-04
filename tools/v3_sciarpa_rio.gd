extends SceneTree

# Prova della SCIARPA DI RIO che vive (autore, 4/11/2026): il ritratto dell'HUD di Rio su fondo scuro, respira per 2 s,
# poi sceglie ATTACCO (la sciarpa frusta), poi un colpo da fuori. Da girare come filmato a tempo fisso:
# xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie /tmp/sc/f.png -s tools/v3_sciarpa_rio.gd

var hud: PortraitHud
var n: int = 0


func _init() -> void:
	Settings.ensure_loaded()
	var bg := ColorRect.new()
	bg.color = Color("#1c1626")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	hud = PortraitHud.new()
	root.add_child(hud)
	hud.set_who("zecca")
	hud.setup("RIO", Color("#3fd6c4"), [
		{"kind": "attack", "name": "ATTACCO", "ok": true, "desc": ""},
		{"kind": "skill", "name": "ABILITA'", "ok": true, "desc": ""},
		{"kind": "guard", "name": "GUARDIA", "ok": true, "desc": ""},
		{"kind": "ult", "name": "ULTIMATE", "ok": false, "desc": ""}])
	process_frame.connect(_tick)


func _tick() -> void:
	n += 1
	if n == 75:
		hud.pick("attack")
	if n == 120:
		hud.pick("")
	if n == 140:
		hud.colpo()
	if n >= 190:
		quit()
