extends SceneTree

# Limite FPS e V-Sync nelle impostazioni.
#   godot --headless --path . -s res://tests/unit/test_fps.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	Settings.path = "user://test_fps.cfg"
	_check("di base 144 fps", Settings.fps_limit == 144)
	Settings.apply_video()
	_check("il motore usa il limite", Engine.max_fps == 144)
	Settings.fps_limit = Settings.next_fps_limit()
	_check("il limite scorre: 240", Settings.fps_limit == 240)
	Settings.fps_limit = Settings.next_fps_limit()
	_check("poi senza limite", Settings.fps_limit == 0 and Settings.fps_text().contains("SENZA"))
	Settings.fps_limit = Settings.next_fps_limit()
	_check("e riparte da 60", Settings.fps_limit == 60)
	Settings.fps_limit = 120
	Settings.vsync = false
	Settings.save()
	Settings.fps_limit = 144
	Settings.vsync = true
	Settings.load_settings()
	_check("si salva e si ricarica", Settings.fps_limit == 120 and not Settings.vsync)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_fps.cfg"))
	Settings.fps_limit = 144
	Settings.vsync = true
	Settings.apply_video()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
