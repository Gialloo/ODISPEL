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

	# Riempie la cache oltre il limite: una chiave usata di recente deve sopravvivere,
	# mentre la variante meno recente deve essere ricostruita al successivo accesso.
	var recent: ArrayMesh = MeshBatch.disc(0.42, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	for i in 125:
		MeshBatch.disc(1.0 + float(i) * 0.01, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	MeshBatch.disc(3.0, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	var recent_again: ArrayMesh = MeshBatch.disc(0.42, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	check(recent.get_instance_id() == recent_again.get_instance_id(), "la cache LRU conserva una geometria usata di recente")
	var evicted_again: ArrayMesh = MeshBatch.disc(0.43, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	check(other_radius.get_instance_id() != evicted_again.get_instance_id(), "la cache LRU ricrea la variante meno recente espulsa")
	if fails == 0:
		print("test_v3_mesh_batch: OK")
	else:
		print("test_v3_mesh_batch: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
