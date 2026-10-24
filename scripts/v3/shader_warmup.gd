class_name ShaderWarmup
extends SubViewport

# FLUIDITA': sul telefono (GLES3) uno shader si compila la prima volta che compare a schermo, e quel fotogramma scatta.
# Senza riscaldamento gli scatti cadevano sul primo colpo (lampo bianco), sul primo bagliore e sulla prima telecamera incrinata.
# Qui si disegnano una volta tutti i materiali del gioco in una vista minuscola e invisibile, mentre si e' nel menu.

const FRAMES: int = 3


func _ready() -> void:
	size = Vector2i(64, 64)
	own_world_3d = true
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 3)
	add_child(cam)
	cam.current = true
	var mats: Array = [Toon.body(), Toon.ink(), Toon.ink_grow(), Toon.glow(), Toon.shadow(), Toon.hit_flash(),
		Toon.body_tex(load("res://icon.png") as Texture2D), Toon.body_world(), NightFx.rain_material()]
	var x: float = -1.2
	for m in mats:
		var mi := MeshInstance3D.new()
		mi.mesh = _quad()
		mi.material_override = m
		mi.position = Vector3(x, 0, 0)
		x += 0.4
		add_child(mi)
	# lo shader della telecamera rotta e' 2D: un rettangolo nella stessa vista
	var cr := ColorRect.new()
	var cm := ShaderMaterial.new()
	cm.shader = BrokenCam.shader()
	cr.material = cm
	cr.size = Vector2(32, 32)
	add_child(cr)
	# glitch cromatico (legge lo schermo: la prima volta compila uno shader, meglio qui che sul primo critico)
	var gr := ColorRect.new()
	var gm := ShaderMaterial.new()
	gm.shader = GlitchFx.shader()
	gr.material = gm
	gr.size = Vector2(16, 16)
	add_child(gr)
	for i in FRAMES:
		await RenderingServer.frame_post_draw
	queue_free()


# Un quadrato con vertici, normali, colori e UV, come le mesh vere del gioco
static func _quad() -> ArrayMesh:
	var v := PackedVector3Array([Vector3(-0.15, -0.15, 0), Vector3(0.15, -0.15, 0), Vector3(0.15, 0.15, 0),
		Vector3(-0.15, -0.15, 0), Vector3(0.15, 0.15, 0), Vector3(-0.15, 0.15, 0)])
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(0, 0)])
	for i in 6:
		n.append(Vector3.BACK)
		c.append(Color(1, 1, 1, 0.5))
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_TEX_UV] = uv
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
