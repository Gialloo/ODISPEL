extends SceneTree

# HUD COMBAT 2.0 · REGRESSIONE CONGELATA (correzione 5 dell'autore, 7/11/2026). Cattura solo l'HUD, sempre uguale:
# - risoluzione fissa (--resolution) e frame contati con --fixed-fps 60, mai a tempo;
# - seme fisso per il caso globale e per quello della presentazione della battaglia;
# - stesso nemico, livello, arena e stato (preparato qui, non giocato), tocco fissato dagli argomenti;
# - prima della cattura: scena 3D nascosta (fondo piatto), animazioni e tween dell'HUD fermi. Particelle, glitch e
#   telecamera non entrano mai nell'immagine.
# Vale solo se due catture identiche di fila danno zero differenze (tools/confronta_png.py).
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 --fixed-fps 60 \
#        -s tools/v3_regressione_hud.gd -- <cartella> [touch|pc] [on|off]
var out: String = "/tmp/v3regressione"
const SEME: int = 20261107
const BOSS: String = "autovelox"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	TouchUi.force = a.size() > 1 and a[1] == "touch"
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	Settings.hud_gerarchia = not (a.size() > 2 and a[2] == "off")      # REGRESSIONE_063: riga tolta per girare sulla 0.63
	seed(SEME)
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _ferma(n: Node) -> void:
	n.set_process(false)
	n.set_physics_process(false)
	if n is Node3D:
		(n as Node3D).visible = false
	if n is GPUParticles2D or n is CPUParticles2D:
		(n as CanvasItem).visible = false
	for c in n.get_children():
		_ferma(c)


func _nascondi(bt: Node, campo: String) -> void:
	var n: Variant = bt.get(campo)
	if n is CanvasItem:
		(n as CanvasItem).visible = false


func _cattura(bt: Node, nome: String) -> void:
	_ferma(bt)
	# fuori dall'immagine: il riflettore e l'alone del bersaglio (pulsano col tempo vero), lo sguardo della telecamera di
	# Echo (REC, mirino), i fumetti di Echo e le battute della squadra (escono a caso)
	for campo in ["_spot", "_cam_hud", "_echo_bal", "_say_balloon", "_quip_layer"]:
		_nascondi(bt, campo)
	# il cartellino del nemico arriva al suo posto con un lerp: lo si porta a destinazione (telecamera ormai ferma)
	if bt.has_method("_place_boss_tag"):
		for i in 60:
			bt.call("_place_boss_tag")
	for t in get_processed_tweens():
		t.kill()
	for c in bt.get_children():
		if c is CanvasItem:
			(c as CanvasItem).queue_redraw()
	await _frames(3)
	root.get_viewport().get_texture().get_image().save_png(out.path_join(nome + ".png"))


func _run() -> void:
	await process_frame
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": BOSS, "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	var rng: Variant = bt.get("_presentation_rng")
	if rng is RandomNumberGenerator:
		(rng as RandomNumberGenerator).seed = SEME
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 900:
		guard += 1
		await process_frame
	await _frames(300)                      # 5 secondi a 60 fps: gli avvisi d'inizio se ne vanno
	var w: Node = bt.get("_wheel")
	w.call("pick", "attack")
	await _frames(40)
	await _cattura(bt, "hud_attacco_scelto")
	quit()
