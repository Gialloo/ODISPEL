class_name Story
extends RefCounted

# Quando mostrare le scene di storia. Le scene si vedono una volta sola (si salva
# quali) e solo nelle partite in solitaria; si possono rivedere dalla schermata missioni.


static func enabled() -> bool:
	return DisplayServer.get_name() != "headless"


static func scene_id(boss_id: String, phase: String) -> String:
	return "%s_%s" % [boss_id, phase]


static func is_new(id: String) -> bool:
	Settings.ensure_loaded()
	return StoryData.has_scene(id) and not Settings.seen_scenes.has(id)


# Avvia una missione in solitaria: prima la scena iniziale (se e' nuova), poi la battaglia.
static func start_mission(host: Node, boss_id: String, tier: int) -> void:
	MissionConfig.set_mission(boss_id, tier)
	var id: String = scene_id(boss_id, "pre")
	if enabled() and is_new(id):
		var view: DialogueView = play(host, id)
		if view != null:
			await view.finished
	SceneRouter.go("battle", true)


# Mostra la scena sopra `host`. Ritorna la vista (o null) e segna la scena come vista.
static func play(host: Node, id: String, mark_seen: bool = true) -> DialogueView:
	if not StoryData.has_scene(id):
		return null
	var view: DialogueView = DialogueView.play(host, StoryData.text(id))
	if mark_seen:
		Settings.mark_scene_seen(id)
	return view
