extends SceneTree

# Prepara le SAGOME dei ritratti dell'HUD (bordo e ombra del ritratto di chi ha il turno) in assets/portraits/hud/sagome/.
# Stesso calcolo del gioco (PortraitHud.silhouette_image): il gioco le carica invece di calcolarle al primo turno di ognuno
# (era uno scatto di ~35 ms per disegno su PC, il triplo sul telefono). Da rilanciare quando cambia un *_hud.png o *_busto.png.
# Uso: godot --headless --path . -s tools/v3_sagome.gd   poi   godot --headless --path . --import

const SRC_DIR: String = "res://assets/portraits/hud/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PortraitHud.SIL_DIR))
	var made: int = 0
	for f in DirAccess.get_files_at(SRC_DIR):
		if not f.ends_with(".png"):
			continue
		if not (f.ends_with("_hud.png") or f.ends_with("_busto.png")):
			continue
		var t: Texture2D = load(SRC_DIR + f)
		var img: Image = PortraitHud.silhouette_image(t)
		if img == null:
			print("SAGOMA saltata (immagine non leggibile): ", f)
			continue
		var out: String = PortraitHud.sil_path(SRC_DIR + f)
		img.save_png(ProjectSettings.globalize_path(out))
		print("SAGOMA %s -> %s (%dx%d)" % [f, out, img.get_width(), img.get_height()])
		made += 1
	print("SAGOME FATTE: ", made)
	quit()
