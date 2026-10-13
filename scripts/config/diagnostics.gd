class_name Diagnostics
extends RefCounted

# Rapporto tecnico copiabile (versione, dispositivo, prestazioni, grafiche mancanti, cartella dei log).
# Si manda a chi sviluppa quando qualcosa non va: un solo tocco da IMPOSTAZIONI.


static func report() -> String:
	var lines: Array = []
	lines.append("ODISPEL v%s" % GameConfig.VERSION)
	lines.append("Sistema: %s %s  ·  %s" % [OS.get_name(), OS.get_version(), OS.get_model_name()])
	lines.append("Schermo: %s  ·  scala %.2f  ·  touch: %s" % [str(DisplayServer.window_get_size()), DisplayServer.screen_get_scale(), str(TouchUi.active())])
	lines.append("Grafica: %s  ·  %s" % [RenderingServer.get_video_adapter_name(), str(RenderingServer.get_video_adapter_type())])
	lines.append("FPS ora: %d (limite %s, qualita' %s)" % [Engine.get_frames_per_second(), str(Settings.fps_limit), Settings.quality_name()])
	lines.append("Memoria: %.0f MB (picco %.0f MB)" % [float(OS.get_static_memory_usage()) / 1048576.0, float(OS.get_static_memory_peak_usage()) / 1048576.0])
	var rep: Dictionary = ArtLibrary.report()
	lines.append("Grafiche: %d / %d trovate" % [rep["found"].size(), int(rep["total"])])
	lines.append("Contenuti: %s" % ("OK" if BattleContent.validate().is_empty() else "ERRORI: " + str(BattleContent.validate())))
	lines.append("Profilo: %s  ·  icona %s  ·  banner %d  ·  icone sbloccate %d" % [Profile.player_name, Profile.icon, Profile.banner, Profile.unlocked.size()])
	lines.append("Log: %s" % ProjectSettings.globalize_path("user://logs"))
	return "\n".join(lines)


static func copy_to_clipboard() -> String:
	var text: String = report()
	DisplayServer.clipboard_set(text)
	return text
