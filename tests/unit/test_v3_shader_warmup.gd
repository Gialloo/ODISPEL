extends SceneTree

var checks: int = 0
var fails: int = 0


func check(condition: bool, what: String) -> void:
	checks += 1
	if not condition:
		fails += 1
		push_error("FAIL: " + what)


func _init() -> void:
	var mesh: ArrayMesh = ShaderWarmup._quad()
	check(mesh != null, "la geometria del warm-up viene creata")
	check(mesh.get_surface_count() == 1, "la mesh contiene una superficie")
	if mesh.get_surface_count() == 1:
		var arrays: Array = mesh.surface_get_arrays(0)
		check((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() == 6, "sei vertici per i due triangoli")
		check((arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array).size() == 6, "sei normali")
		check((arrays[Mesh.ARRAY_COLOR] as PackedColorArray).size() == 6, "sei colori")
		check((arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size() == 6, "sei coordinate UV")

	if fails == 0:
		print("test_v3_shader_warmup: OK (%d verifiche)" % checks)
	else:
		print("test_v3_shader_warmup: %d/%d FALLITI" % [fails, checks])
	quit(1 if fails > 0 else 0)
