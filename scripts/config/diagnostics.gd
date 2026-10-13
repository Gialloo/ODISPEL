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
	lines.append("Rete: componente WebRTC %s  ·  TURN %s" % ["presente" if ClassDB.class_exists("WebRTCPeerConnection") else "MANCANTE", "configurato" if not (WebRTCLink.turn_settings()["urls"] as Array).is_empty() else "non configurato"])
	var net: Array = net_log_lines(12)
	if not net.is_empty():
		lines.append("Ultime righe di rete:")
		lines.append_array(net)
	return "\n".join(lines)


# Ultime righe "[NET" del log del gioco: dicono cosa e' successo in una stanza.
static func net_log_lines(count: int) -> Array:
	var out: Array = []
	var path: String = "user://logs/godot.log"
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var text: String = f.get_as_text()
	for line in text.split("\n"):
		if line.contains("[NET"):
			out.append(line.strip_edges().left(200))
	return out.slice(maxi(0, out.size() - count))


# Messaggio semplice per un errore di rete tecnico (per chi non e' del mestiere).
static func friendly_network_error(reason: String) -> String:
	if reason.contains("setup WebRTC"):
		return "Manca un file del gioco per la rete. Estrai di nuovo TUTTO lo zip (non solo ODISPEL.exe) e riprova."
	if reason.contains("nessun host"):
		return "La stanza non esiste o l'host non e' ancora entrato. Controlla il codice."
	return reason


static func copy_to_clipboard() -> String:
	var text: String = report()
	DisplayServer.clipboard_set(text)
	return text
