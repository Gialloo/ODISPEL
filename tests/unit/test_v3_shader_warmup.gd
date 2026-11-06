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
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		check(vertices.size() == 6, "sei vertici per i due triangoli")
		check(normals.size() == 6, "sei normali")
		check(colors.size() == 6, "sei colori")
		check(uvs.size() == 6, "sei coordinate UV")

	if fails == 0:
		print("test_v3_shader_warmup: OK (%d verifiche)" % checks)
	else:
		print("test_v3_shader_warmup: %d/%d FALLITI" % [fails, checks])
	quit(1 if fails > 0 else 0)
