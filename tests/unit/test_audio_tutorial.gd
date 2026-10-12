extends SceneTree

# Impostazioni, audio, finestra impostazioni e tutorial del primo combattimento.
#   godot --headless --path . -s res://tests/unit/test_audio_tutorial.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_settings_tmp.cfg"

const SFX: Array = ["click", "hover", "back", "toast", "success", "ready", "error", "save", "hit", "player_hit", "guard", "heal", "down", "boss_charge", "boss_attack", "swap", "victory", "defeat", "wipe", "cutin", "talk"]


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	Settings.path = TMP
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))

	# --- impostazioni
	Settings.music = 0.6
	Settings.sfx = 0.8
	Settings.muted = false
	Settings.tutorial_done = false
	_check("senza schermo il tutorial non parte da solo", not Settings.should_show_tutorial())
	Settings.music = 0.3
	Settings.muted = true
	Settings.tutorial_done = true
	_check("si salvano", Settings.save())
	Settings.music = 1.0
	Settings.muted = false
	Settings.tutorial_done = false
	Settings.load_settings()
	_check("si rileggono: musica", is_equal_approx(Settings.music, 0.3))
	_check("si rileggono: muto", Settings.muted)
	_check("si rileggono: tutorial visto", Settings.tutorial_done)
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 9.0)
	cfg.save(TMP)
	Settings.load_settings()
	_check("un volume assurdo viene limitato", Settings.music == 1.0)
	Settings.muted = false
	Settings.tutorial_done = false
	Settings.music = 0.6

	# --- audio
	var mgr: Node = root.get_node("Sfx")
	_check("bus musica", AudioServer.get_bus_index("Music") >= 0)
	_check("bus effetti", AudioServer.get_bus_index("SFX") >= 0)
	var all_ok: bool = true
	for s in SFX:
		var st: Variant = load("res://assets/audio/sfx/%s.wav" % s)
		if not (st is AudioStreamWAV) or (st as AudioStreamWAV).data.size() < 100:
			all_ok = false
			print("manca/vuoto: ", s)
	_check("tutti i 21 effetti esistono", all_ok)
	_check("musica del menu", load("res://assets/audio/music/menu.wav") is AudioStreamWAV)
	_check("musica della battaglia", load("res://assets/audio/music/battle.wav") is AudioStreamWAV)
	Snd.play("click")
	Snd.play("inesistente")
	_check("suoni sconosciuti non rompono nulla", true)
	mgr.play_music("battle")
	_check("la musica cambia", mgr.current_music == "battle")
	Settings.music = 0.5
	Settings.muted = true
	mgr.apply_settings()
	_check("il muto silenzia il master", AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")))
	_check("il volume musica segue l'impostazione", absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.5)) < 0.01)
	Settings.muted = false
	mgr.apply_settings()
	_check("tolto il muto torna il suono", not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")))
	var b := Button.new()
	root.add_child(b)
	_check("i pulsanti nuovi hanno il suono", b.pressed.get_connections().size() >= 1)
	b.queue_free()

	# --- finestra impostazioni
	var host := Control.new()
	root.add_child(host)
	var panel: SettingsPanel = SettingsPanel.open(host)
	await process_frame
	_check("la finestra si apre", panel.is_inside_tree())
	panel.music_slider.value = 0.25
	_check("lo slider cambia la musica", is_equal_approx(Settings.music, 0.25))
	panel.sfx_slider.value = 0.4
	_check("lo slider cambia gli effetti", is_equal_approx(Settings.sfx, 0.4))
	panel.mute_box.button_pressed = true
	_check("la spunta attiva il muto", Settings.muted)
	panel.mute_box.button_pressed = false
	Settings.tutorial_done = true
	panel.tutorial_button.pressed.emit()
	_check("RIVEDI TUTORIAL lo riarma", not Settings.tutorial_done)
	var closed: Array = []
	panel.closed.connect(func() -> void: closed.append(1))
	panel.close_panel()
	await process_frame
	_check("si chiude e lo dice", closed.size() == 1 and not is_instance_valid(panel))
	Settings.load_settings()
	_check("la chiusura salva", is_equal_approx(Settings.music, 0.25))
	host.queue_free()

	# --- tutorial
	MissionConfig.set_mission("distributore", 0)
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_check("in test il tutorial non parte da solo", scene._tutorial == null)
	scene._start_tutorial()
	await process_frame
	await process_frame
	var t: TutorialOverlay = scene._tutorial
	_check("il tutorial parte", t != null and t.is_inside_tree())
	_check("nove passi", t.steps.size() == 9)
	var targets_ok: bool = true
	for i in range(1, 5):
		t.index = i
		if t.target_rect().size.x < 50.0 or t.target_rect().size.y < 20.0:
			targets_ok = false
			print("riquadro non valido al passo ", i, ": ", t.target_rect())
	_check("i passi 2-5 illuminano un pannello vero", targets_ok)
	t.index = 0
	t._show_step()
	_check("il primo passo non ha riquadro", t.target_rect().size == Vector2.ZERO)
	var inside: bool = true
	for i in t.steps.size():
		t.index = i
		t._show_step()
		var pr: Rect2 = Rect2(t.panel.position, t.panel.size)
		var vs: Vector2 = t.get_viewport_rect().size
		if pr.position.x < 0 or pr.position.y < 0 or pr.end.x > vs.x + 1 or pr.end.y > vs.y + 1:
			inside = false
			print("riquadro fuori schermo al passo ", i, ": ", pr)
	_check("la finestra del tutorial resta nello schermo", inside)
	t.index = 0
	t._show_step()
	t.next()
	_check("AVANTI passa al passo dopo", t.index == 1)
	_check("il testo cambia", t.title_label.text == "IL BERSAGLIO")
	var done: Array = []
	t.finished.connect(func(skipped: bool) -> void: done.append(skipped))
	for i in 8:
		t.next()
	await process_frame
	_check("l'ultimo passo finisce", done.size() == 1 and done[0] == false)
	_check("il tutorial risulta visto", Settings.tutorial_done)
	_check("e l'overlay sparisce", scene._tutorial == null)

	Settings.tutorial_done = false
	scene._start_tutorial()
	await process_frame
	await process_frame
	scene._tutorial.skip_tutorial()
	await process_frame
	_check("saltarlo conta come visto", Settings.tutorial_done)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
