extends SceneTree

# Cache geometrie ripetute: controlla riuso e separazione delle varianti.

var fails: int = 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + what)


func _init() -> void:
	var first: ArrayMesh = MeshBatch.disc(0.42, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	var repeated: ArrayMesh = MeshBatch.disc(0.42, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	check(first.get_instance_id() == repeated.get_instance_id(), "parametri identici riutilizzano la stessa ArrayMesh")
	check(first.get_surface_count() == 1, "la mesh in cache conserva la superficie")
	var other_radius: ArrayMesh = MeshBatch.disc(0.43, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	var other_color: ArrayMesh = MeshBatch.disc(0.42, Color(0.03, 0.0, 0.06, 0.55), 14, 0.015)
	check(first.get_instance_id() != other_radius.get_instance_id(), "raggio diverso non collide nella cache")
	check(first.get_instance_id() != other_color.get_instance_id(), "colore diverso non collide nella cache")
	if fails == 0:
		print("test_v3_mesh_batch: OK")
	else:
		print("test_v3_mesh_batch: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
