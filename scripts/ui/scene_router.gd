class_name SceneRouter
extends RefCounted

# Elenco unico delle schermate e modo unico di passare dall'una all'altra.
# Le schermate pesanti (battaglia) passano dalla schermata di caricamento.

const SCENES: Dictionary = {
	"hub": "res://scenes/hub/hub_demo.tscn",
	"roster": "res://scenes/roster/roster_screen.tscn",
	"lobby": "res://scenes/lobby/lobby_demo.tscn",
	"missions": "res://scenes/missions/mission_screen.tscn",
	"feats": "res://scenes/feats/feats_screen.tscn",
	"tutorial": "res://scenes/tutorial/tutorial_screen.tscn",
	"battle": "res://scenes/battle/battle_screen.tscn",
	"pvp": "res://scenes/battle/pvp_screen.tscn",
}

const LOADING_TITLES: Dictionary = {
	"battle": "PREPARAZIONE OPERAZIONE",
}


static func path_of(key: String) -> String:
	return str(SCENES.get(key, ""))


# Cambia schermata. `loading` = mostra la schermata di caricamento.
static func go(key: String, loading: bool = false) -> void:
	var path: String = path_of(key)
	var loop: MainLoop = Engine.get_main_loop()

	if path.is_empty() or not (loop is SceneTree):
		push_error("Schermata sconosciuta: " + key)
		return

	var tree: SceneTree = loop as SceneTree
	var change: Callable = func() -> void: tree.change_scene_to_file(path)

	if loading:
		Notify.transition(change, str(LOADING_TITLES.get(key, "CARICAMENTO")))
	else:
		change.call()


# Vero se la scena corrente e' la schermata indicata.
static func is_current(key: String) -> bool:
	var loop: MainLoop = Engine.get_main_loop()
	if not (loop is SceneTree):
		return false
	var scene: Node = (loop as SceneTree).current_scene
	return scene != null and str(scene.scene_file_path) == path_of(key)
