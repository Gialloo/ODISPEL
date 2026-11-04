extends SceneTree

# IL SUONO DEL COMBATTIMENTO: ogni effetto e ogni strato di musica esiste e si carica, gli strati sono lunghi uguale
# (se no la musica a strati va fuori tempo), il volume a zero spegne davvero e il COMBO alza gli strati giusti.
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	Settings.path = "user://settings_prova_suoni.cfg"
	Settings.ensure_loaded()
	_run()


func _run() -> void:
	await process_frame          # dentro _init la SceneTree non e' ancora il ciclo principale
	for w in Sfx.WORDS:
		_chk(Sfx.GAIN.has(str(Sfx.WORDS[w])), "volume per l'effetto di " + str(w))
	for n in Sfx.GAIN:
		var st: AudioStream = load(Sfx.DIR + str(n) + ".ogg") as AudioStream
		_chk(st != null and st.get_length() > 0.02, "effetto " + str(n))
		if st != null:
			_chk(st.get_length() < 4.0, "effetto corto " + str(n))
	for track in ["battaglia", "boss"]:
		var lens: Array = []
		for stem in Sfx.STEMS:
			var st: AudioStream = load("%smusica/%s_%s.ogg" % [Sfx.DIR, track, stem]) as AudioStream
			_chk(st != null, "strato %s %s" % [track, stem])
			if st != null:
				lens.append(st.get_length())
		if lens.size() == Sfx.STEMS.size():
			_chk(absf(float(lens.max()) - float(lens.min())) < 0.03, "strati di %s lunghi uguale %s" % [track, str(lens)])
	Sfx.music_start("boss")
	for i in 5:
		await process_frame
	var s: Sfx = Sfx._me
	_chk(s != null and s.is_inside_tree(), "il nodo dei suoni si crea da solo")
	if s != null:
		_chk(s._track == "boss" and s._sync != null and s._sync.stream_count == 4, "musica del boss a 4 strati")
		Sfx.combo(1)
		_chk(float(s._want[2]) == 0.0 and float(s._want[3]) == 0.0, "senza COMBO niente arpeggio e melodia")
		Sfx.combo(3)
		_chk(float(s._want[1]) == 1.0 and float(s._want[2]) == 1.0 and float(s._want[3]) == 0.0, "3 COMBO: ritmo e arpeggio")
		Sfx.combo(6)
		_chk(float(s._want[3]) == 1.0, "6 COMBO: anche la melodia")
		Sfx.combo(0)
		_chk(float(s._want[2]) == 0.0, "COMBO a zero: gli strati scendono")
		Sfx.surge(5.0)
		Sfx.combo(0)
		_chk(float(s._want[3]) == 1.0, "dopo il BREAK la musica resta piena anche se il COMBO si azzera")
		Settings.sfx_volume = 0.0
		var before: int = s._next
		Sfx.play("colpo")
		await process_frame
		_chk(s._next == before, "effetti a volume zero: non suona niente")
		Settings.sfx_volume = 1.0
		Sfx.play("colpo")
		await process_frame
		_chk(s._next != before, "effetto suonato")
		Sfx.music_stop(0.1)
		for i in 30:
			await process_frame
		_chk(s._track == "", "la musica si ferma")
	print("test_v3_suoni: " + ("OK" if fails == 0 else "%d FALLITI" % fails))
	quit(1 if fails > 0 else 0)
