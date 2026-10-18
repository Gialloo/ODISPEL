extends SceneTree
# Costo di disegno della mappa V2 (renderer software del server: SOLO indicativo): godot -s tools/world_v2_perf.gd
func _init() -> void:
	_run()
func _run() -> void:
	Settings.tutorial_done = true
	WorldV2Ctx.reset(); WorldV2Ctx.active = true; WorldV2Ctx.read["intro"] = true
	var w = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(w)
	await create_timer(0.6).timeout
	for p in [Vector2(0, 6.5), Vector2(15, 2), Vector2(0, -10), Vector2(0, -32), Vector2(33, 1.5), Vector2(-34, 7), Vector2(0, 19), Vector2(45, 21)]:
		w.player = p; w._seed_trail(); w._place_all()
		await create_timer(0.5).timeout
		await process_frame
		var dc: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		var obj: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
		var prim: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		print("pos=", p, " draw=", dc, " obj=", obj, " prim=", prim)
	print("mem statica MB=", OS.get_static_memory_usage() / 1048576, " tex MB=", snappedf(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0, 0.1))
	quit(0)
