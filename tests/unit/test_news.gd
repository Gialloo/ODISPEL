extends SceneTree

# Novita' di versione: la voce della versione corrente esiste e la finestra si mostra una sola volta.
#   godot --headless --path . -s res://tests/unit/test_news.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	var e: Dictionary = Changelog.entry_for(GameConfig.VERSION)
	_check("c'e' una voce per la versione corrente (aggiungila a changelog.gd)", not e.is_empty())
	_check("la voce ha almeno una riga", (e.get("items", []) as Array).size() >= 1)
	_check("la piu' recente e' la versione corrente", str(Changelog.latest().get("v", "")) == GameConfig.VERSION)
	Settings.path = "user://test_news.cfg"
	Settings.tutorial_done = true
	Settings.last_seen_version = ""
	_check("senza schermo non si mostra nulla", Settings.news_to_show().is_empty())
	_check("ma la versione risulta vista", Settings.last_seen_version == GameConfig.VERSION)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_news.cfg"))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
