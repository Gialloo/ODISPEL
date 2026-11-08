extends SceneTree

# PRESTAZIONI dei cambi di scena (8/11/2026): le ottimizzazioni non devono cambiare l'aspetto.
# - le sagome pronte dei ritratti sono identiche, pixel per pixel, a quelle calcolate dal gioco
# - lo stesso testo di shader da' lo stesso Shader (si compila una volta per partita)
# - due copie dello stesso personaggio condividono le forme, con la stessa geometria di una costruzione da zero

var fails: int = 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + what)


func _init() -> void:
	# sagome
	var n: int = 0
	for f in DirAccess.get_files_at("res://assets/portraits/hud/"):
		if not (f.ends_with("_hud.png") or f.ends_with("_busto.png")):
			continue
		var src: Texture2D = load("res://assets/portraits/hud/" + f)
		var pre_path: String = PortraitHud.sil_path(src.resource_path)
		check(ResourceLoader.exists(pre_path), "manca la sagoma pronta di %s (lancia tools/v3_sagome.gd)" % f)
		if not ResourceLoader.exists(pre_path):
			continue
		var want: Image = PortraitHud.silhouette_image(src)
		var got: Image = (load(pre_path) as Texture2D).get_image()
		got.convert(Image.FORMAT_RGBA8)
		check(want.get_size() == got.get_size(), "sagoma di %s: stessa misura" % f)
		check(want.get_data() == got.get_data(), "sagoma di %s: stessi pixel del calcolo del gioco" % f)
		n += 1
	check(n >= 4, "almeno le sagome dei quattro protagonisti")

	# shader condivisi
	var code: String = "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(1.0); }\n"
	check(Toon.shared_shader(code) == Toon.shared_shader(code), "stesso testo, stesso Shader")
	check(Toon.shared_shader(code) != Toon.shared_shader(code + "// altro\n"), "testi diversi, Shader diversi")
	check(Toon.shared_shader(CmdWheel.SPOT_SHADER).code == CmdWheel.SPOT_SHADER, "lo Shader condiviso ha il codice giusto")

	# forme dei personaggi riusate
	var a := CharacterVisual.new()
	a.setup("rio")
	var b := CharacterVisual.new()
	b.setup("rio")
	var ma: MeshInstance3D = a.find_child("HeadMesh", true, false)
	var mb: MeshInstance3D = b.find_child("HeadMesh", true, false)
	check(ma != null and mb != null, "la testa c'e'")
	if ma != null and mb != null:
		check(ma.mesh == mb.mesh, "due Rio condividono la stessa mesh della testa")
		var fresh: ArrayMesh = AnimeBuilder.head(CastVisual.spec("rio").duplicate().merged({"mask_crack": true}, true) if CharacterVisual.mask_cracked() else CastVisual.spec("rio").duplicate()).build()
		check(fresh.get_surface_count() == ma.mesh.get_surface_count(), "stesse superfici di una testa costruita da zero")
		for si in fresh.get_surface_count():
			var fa: Array = fresh.surface_get_arrays(si)
			var ca: Array = ma.mesh.surface_get_arrays(si)
			check(fa[Mesh.ARRAY_VERTEX] == ca[Mesh.ARRAY_VERTEX] and fa[Mesh.ARRAY_COLOR] == ca[Mesh.ARRAY_COLOR], "superficie %d identica a una costruita da zero" % si)
	var l := CharacterVisual.new()
	l.setup("lance")
	var ml: MeshInstance3D = l.find_child("HeadMesh", true, false)
	check(ml != null and ma != null and ml.mesh != ma.mesh, "personaggi diversi, forme diverse")
	a.free()
	b.free()
	l.free()

	if fails == 0:
		print("test_v3_prestazioni_cambi: OK")
	else:
		print("test_v3_prestazioni_cambi: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
