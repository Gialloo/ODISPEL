extends SceneTree

# Ottimizzazioni di carico e memoria: fondo non ridisegnato, precaricamento, grafiche ridotte,
# musica a ciclo riusata, shader del velo.
#   godot --headless --path . -s res://tests/unit/test_performance.gd

var passed: int = 0
var failed: int = 0
const TMP_DIR: String = "user://test_perf_art"


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

	# --- fondo pieno: il nero del gioco e' il colore di pulizia dello schermo
	var clear: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
	_check("colore di pulizia = nero del gioco", clear.is_equal_approx(BattleTheme.BK))
	var host := Control.new()
	root.add_child(host)
	var black: ColorRect = ScreenFx.solid(host, BattleTheme.BK)
	var red: ColorRect = ScreenFx.solid(host, Color.RED)
	_check("fondo nero: non disegnato (resta nell'albero)", not black.visible and black.get_parent() == host)
	_check("fondo di altro colore: disegnato", red.visible)

	# --- precaricamento: senza schermo non fa nulla
	_check("precaricamento spento nei test", not Warmup.enabled() and Warmup.scenes() == 0 and Warmup.audio(["res://x.wav"]) == 0)

	# --- grafiche: ridotte oltre il limite, il rapporto non le carica
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP_DIR))
	var big := Image.create(4096, 1024, false, Image.FORMAT_RGBA8)
	big.fill(Color.WHITE)
	big.save_png(ProjectSettings.globalize_path(TMP_DIR + "/big.png"))
	var small := Image.create(800, 400, false, Image.FORMAT_RGBA8)
	small.fill(Color.WHITE)
	small.save_png(ProjectSettings.globalize_path(TMP_DIR + "/small.png"))
	ArtLibrary.extra_roots = [ProjectSettings.globalize_path(TMP_DIR)]
	ArtLibrary.refresh()
	_check("has: vede il file senza caricarlo", ArtLibrary.has("big.png") and not ArtLibrary._cache.has("big.png"))
	_check("has: file assente", not ArtLibrary.has("non_esiste.png"))
	var tb: Texture2D = ArtLibrary.texture("big.png")
	_check("grafica grande ridotta al limite", tb != null and tb.get_width() == ArtLibrary.MAX_SIZE and tb.get_height() == ArtLibrary.MAX_SIZE / 4)
	var ts: Texture2D = ArtLibrary.texture("small.png")
	_check("grafica piccola invariata", ts != null and ts.get_width() == 800 and ts.get_height() == 400)
	ArtLibrary.extra_roots = []
	ArtLibrary.refresh()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_DIR + "/big.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_DIR + "/small.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_DIR))

	# --- musica a ciclo: creata una volta e riusata
	var sfx: Node = root.get_node_or_null("Sfx")
	if sfx != null:
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.data = PackedByteArray([0, 0, 1, 0, 2, 0, 3, 0])
		var a: AudioStream = sfx._looped("prova", wav)
		var b: AudioStream = sfx._looped("prova", wav)
		_check("musica a ciclo: riusata", a == b and a != wav)
		_check("musica a ciclo: in loop", (a as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD and (a as AudioStreamWAV).loop_end == 4)
		_check("musica originale non toccata", wav.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	else:
		_check("audio manager presente", false)

	# --- sfondo della battaglia: senza schermo resta il disegno, la texture e' solo a video
	var stage := BattleStage.new()
	stage.size = Vector2(1280, 720)
	root.add_child(stage)
	await process_frame
	_check("sfondo: senza schermo niente texture", stage._bg_static != null and not stage._bg_static.cached)
	stage.queue_free()

	# --- shader del velo
	var sh: Shader = load("res://shaders/battle_overlay.gdshader")
	_check("velo: shader caricato e senza divisioni nei passaggi", sh != null and sh.code.contains("over_pm") and not sh.code.contains("vec4 over("))

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
