class_name BattleV2
extends Control

# BATTAGLIA V2 (prova, pulsante TEST V2 nell'hub): la HUD v88 sopra il motore vero (SoloBattleSource).
# Parte in modalita' ADDESTRAMENTO: nessun premio, nessun salvataggio. La scena vecchia non viene toccata.
# Contratto usato dal motore: source.battle, my_slots(), submit_party(), autoplay_round(), battle_events_received.

const W: float = 1280.0
const H: float = 720.0
const WHEEL_C: Vector2 = Vector2(365, 405)
const WHEEL_R: float = 160.0
const NAMES: Array = ["ATTACK", "SKILL", "ULTIMATE", "GUARD"]
const ANG: Array = [-98.0, -8.0, 82.0, 172.0]
const BOSS_POS: Vector2 = Vector2(663, 172)
const BOSS_ORIGIN: Vector2 = Vector2(40, 30)       # origine del disegno del boss dentro la sua texture
const CONFIRM_RECT: Rect2 = Rect2(650, 586, 156, 40)
const CANCEL_RECT: Rect2 = Rect2(650, 632, 156, 30)
const CUT_FRAMES: int = 4     # durata dell'esplosione nera dell'ultimate, in fotogrammi
var ult_cut: int = 0          # fotogrammi restanti dell'esplosione nera dell'ultimate
var ult_hold: bool = false    # solo per gli screenshot di prova
var cut_root: Control         # velo nero + esplosione, sopra a tutto (visibile solo i 2 fotogrammi dell'ultimate)
var cut_stage: Control
var cut_fx: TextureRect
var cut_glow: TextureRect
var cut_core: TextureRect
var cut_black: ColorRect
var ult_col: Color = Color.WHITE   # colore di chi ha lanciato l'ultimate (dopo la conferma l'HUD passa gia' al personaggio successivo)
const ICON_OF: Dictionary = {"ATTACK": "sword", "SKILL": "bolt", "ULTIMATE": "burst", "GUARD": "defense"}


# Stato condiviso con le classi di disegno (riempito da _refresh).
class _G:
	static var col: Color = Color("#9a4dff")
	static var spr: Texture2D
	static var picked: String = ""
	static var turn_txt: String = "ROUND 1"
	static var boss: Dictionary = {"name": "", "hp": 1, "max": 1, "bal": 1, "bal_max": 1, "heavy": false, "move": "", "target": "", "show": false}
	static var party: Array = []
	static var order: Array = []
	static var cur: int = 0
	static var reserve: int = 0
	static var reserve_max: int = 6
	static var cmds: Array = []
	static var banner_title: String = ""
	static var banner_tag: String = ""       # esito del colore per la mossa scelta (vuoto se la mossa non colpisce il boss)
	static var banner_tag_mult: float = 1.0
	static var matchup: Dictionary = {"show": false, "mult": 1.0, "att": "", "def": ""}
	static var sel_p: float = 0.0
	static var banner_sub: String = ""
	static var auto_on: bool = false
	static var speed: int = 1
	static var bench: Array = []

	# Riporta tutto ai valori iniziali: AUTO e velocita' non passano da una battaglia all'altra.
	static func reset() -> void:
		col = Color("#9a4dff")
		spr = null
		picked = ""
		turn_txt = "ROUND 1"
		boss = {"name": "", "hp": 1, "max": 1, "bal": 1, "bal_max": 1, "heavy": false, "move": "", "target": "", "show": false}
		party = []
		order = []
		cur = 0
		reserve = 0
		reserve_max = 6
		cmds = []
		banner_title = ""
		banner_tag = ""
		banner_tag_mult = 1.0
		matchup = {"show": false, "mult": 1.0, "att": "", "def": ""}
		sel_p = 0.0
		banner_sub = ""
		auto_on = false
		speed = 1
		bench = []


var src: SoloBattleSource
var stage: Control
var hero: _Hero
var boss_rect: TextureRect
var paint_flat: Array = []     # TextureRect per direzione (pennellata, bake una tantum)
var paint_light: Array = []    # TextureRect additive: versione light painting
var paint_bakes: Array = []    # _PaintBake (uno per texture)
var paint_svps: Array = []
var streaks: Array = []        # CPUParticles2D: scie di luce che escono dalla vernice
var glow_rect: TextureRect
var glow_svp: SubViewport
var ring_fx: _Ring
var halo: TextureRect
var _fx_e: float = -1.0
var sel_banner: _Hud
var sel_confirm: _Hud
var _baked_col: Color = Color(0, 0, 0, 0)
var wheel_letters: _Wheel
var fx: _Fx
var world: Control
var bg_node: TextureRect
var cam: Vector2 = Vector2.ZERO
var cam_v: Vector2 = Vector2.ZERO
var zoom: float = 0.0
var zoom_v: float = 0.0
var ui_off: Vector2 = Vector2.ZERO
var fx_t: float = 0.0
var appear: float = 0.0
var sel: float = 0.0
var flash: float = 0.0
var _redraw_acc: float = 0.0
var _last_cur: int = -99
var intro_t: float = 0.0
var _last_e: float = 0.0
var wheel_front: _Wheel
var hud: _Hud
var dim: ColorRect
var slots: Array = []
var cur: int = 0
var choices: Dictionary = {}
var picked: String = ""
var skill_opts: Array = []
var skill_idx: int = 0
var locked: bool = false
var ended: bool = false
var _result: Control


func _ready() -> void:
	_G.reset()
	_U.boost = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bgt: Texture2D = ArtLibrary.texture("backgrounds/battle_v2.png")
	if bgt != null:
		var bg := TextureRect.new()
		bg.texture = bgt
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_node = bg
		add_child(bg)
	else:
		var flat := ColorRect.new()
		flat.color = Color("#0a1c20")
		flat.set_anchors_preset(Control.PRESET_FULL_RECT)
		flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(flat)
	dim = ColorRect.new()
	dim.color = Color(0.01, 0.0, 0.05, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.visible = false
	add_child(dim)
	stage = Control.new()
	stage.size = Vector2(W, H)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	world = Control.new()
	world.size = Vector2(W, H)
	world.pivot_offset = Vector2(520, 330)
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(world)
	resized.connect(_center)
	_center()
	var sh := _Shadow.new()
	sh.size = Vector2(W, H)
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(sh)
	_build_paint()
	wheel_letters = _Wheel.new()
	wheel_letters.size = Vector2(W, H)
	wheel_letters.part = "back"
	wheel_letters.layer = "letters"
	wheel_letters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(wheel_letters)
	fx = _Fx.new()
	fx.size = Vector2(W, H)
	fx.center = WHEEL_C
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(fx)
	world.move_child(fx, 0)
	halo = TextureRect.new()
	halo.texture = fx.halo_tex
	halo.size = Vector2(560, 560)
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.position = WHEEL_C + Vector2(10, -15) - Vector2(280, 280)
	halo.pivot_offset = Vector2(280, 280)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.visible = false
	var hm := CanvasItemMaterial.new()
	hm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = hm
	world.add_child(halo)
	_bake_boss()
	hero = _Hero.new()
	hero.position = Vector2(179, 180)
	hero.scale = Vector2(1.08, 1.08)
	hero.size = Vector2(420, 450)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(hero)
	var vig := _Vignette.new()
	vig.size = Vector2(W, H)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(vig)
	wheel_front = _Wheel.new()
	wheel_front.size = Vector2(W, H)
	wheel_front.part = "front"
	wheel_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(wheel_front)
	ring_fx = _Ring.new()
	ring_fx.size = Vector2(W, H)
	ring_fx.center = WHEEL_C
	ring_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(ring_fx)
	hud = _Hud.new()
	hud.size = Vector2(W, H)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# PRESTAZIONI: la HUD (centinaia di comandi di disegno: testi, barre, poligoni) cambia solo quando cambia lo stato.
	# Si disegna una volta in una texture (SubViewport) ogni volta che serve e si mostra con UN solo disegno al fotogramma.
	hud_vp = SubViewport.new()
	hud_vp.transparent_bg = true
	hud_vp.disable_3d = true
	hud_vp.gui_disable_input = true
	hud_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	hud_vp.add_child(hud)
	hud_view = TextureRect.new()
	hud_view.texture = hud_vp.get_texture()
	hud_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_view.stretch_mode = TextureRect.STRETCH_SCALE
	hud_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hud_view.size = Vector2(W, H)
	hud_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_view.add_child(hud_vp)
	stage.add_child(hud_view)
	_hud_resize()
	sel_banner = _Hud.new()
	sel_banner.mode = "banner"
	sel_confirm = _Hud.new()
	sel_confirm.mode = "confirm"
	for sh_ in [sel_banner, sel_confirm]:
		sh_.size = Vector2(W, H)
		sh_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sh_.visible = false
		stage.add_child(sh_)
	_add_exit()
	_build_cut()
	_U.boost = 1.14 if TouchUi.active() else 1.0
	src = SoloBattleSource.new()
	src.training = true
	src.battle_events_received.connect(_on_events)
	src.start(RosterStore.load_or_new(), "distributore", int(randi()) | 1, 0)
	slots = src.my_slots()
	_start_round()


var hud_vp: SubViewport
var hud_view: TextureRect


# La texture della HUD ha la risoluzione reale dello schermo (testi nitidi anche su telefono)
func _hud_resize() -> void:
	if hud_vp == null:
		return
	var k: float = clampf(stage.scale.x, 1.0, 2.5)
	var sz := Vector2i(int(round(float(W) * k)), int(round(float(H) * k)))
	if hud_vp.size != sz:
		hud_vp.size = sz
	hud_vp.canvas_transform = Transform2D().scaled(Vector2(k, k))
	_hud_dirty()


func _hud_dirty() -> void:
	hud.queue_redraw()
	if hud_vp != null:
		hud_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _center() -> void:
	if stage != null:
		var k: float = minf(size.x / float(W), size.y / float(H))
		stage.scale = Vector2(k, k)
		stage.position = ((size - Vector2(W, H) * k) * 0.5).floor()
		if cut_stage != null:
			cut_stage.scale = stage.scale
			cut_stage.position = stage.position
		_hud_resize()


# Il boss (segnaposto disegnato) viene fotografato una volta in una texture: l'alone corallo del bersaglio
# usa copie leggere di quella texture invece di ridisegnare decine di volte il boss.
func _bake_boss() -> void:
	var svp := SubViewport.new()
	svp.size = Vector2i(640, 560)
	svp.transparent_bg = true
	svp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(svp)
	var b := _Boss.new()
	b.position = BOSS_ORIGIN
	b.size = Vector2(560, 500)
	svp.add_child(b)
	# alone corallo del bersaglio: 48 copie disegnate UNA volta in una texture, poi una sola immagine additiva
	var tex: Texture2D = svp.get_texture()
	glow_svp = SubViewport.new()
	glow_svp.size = Vector2i(490, 432)
	glow_svp.transparent_bg = true
	glow_svp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(glow_svp)
	var gsh := Shader.new()
	gsh.code = "shader_type canvas_item;\nuniform vec4 tint : source_color;\nvoid fragment(){ COLOR = vec4(tint.rgb, COLOR.a * tint.a); }"
	var rings: Array = [[1.0, 0.7], [2.2, 0.55], [3.6, 0.4], [5.2, 0.22]]
	for rg in rings:
		for ak in 12:
			var ang: float = TAU * float(ak) / 12.0
			var gr := TextureRect.new()
			gr.texture = tex
			gr.size = Vector2(640, 560)
			gr.scale = Vector2(0.73, 0.73)
			gr.position = Vector2(10, 10) + Vector2(cos(ang), sin(ang)) * float(rg[0])
			var gm := ShaderMaterial.new()
			gm.shader = gsh
			gm.set_shader_parameter("tint", Color("#ff5a47", float(rg[1]) * 0.45))
			gr.material = gm
			glow_svp.add_child(gr)
	var ash := Shader.new()
	ash.code = "shader_type canvas_item;\nrender_mode blend_add;\nuniform float k = 1.0;\nvoid fragment(){ vec4 c = texture(TEXTURE, UV); COLOR = vec4(c.rgb * k, c.a); }"
	glow_rect = TextureRect.new()
	glow_rect.texture = glow_svp.get_texture()
	glow_rect.size = Vector2(490, 432)
	glow_rect.position = BOSS_POS - BOSS_ORIGIN * 0.73 - Vector2(10, 10)
	glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gmat := ShaderMaterial.new()
	gmat.shader = ash
	glow_rect.material = gmat
	world.add_child(glow_rect)
	_bake_glow_later()
	boss_rect = TextureRect.new()
	boss_rect.texture = tex
	boss_rect.size = Vector2(640, 560)
	boss_rect.scale = Vector2(0.73, 0.73)
	boss_rect.position = BOSS_POS - BOSS_ORIGIN * 0.73
	boss_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(boss_rect)


func _bake_glow_later() -> void:
	# prima il boss, poi (due fotogrammi dopo) l'alone che lo usa
	await get_tree().process_frame
	await get_tree().process_frame
	glow_svp.render_target_update_mode = SubViewport.UPDATE_ONCE


# Pennellate: ogni direzione e' disegnata una sola volta in una texture (piatta + light painting).
# Dopo si animano solo trasformazione e opacita' (nessun ridisegno per fotogramma); le scie sono particelle del motore.
func _build_paint() -> void:
	var streak_tex: Texture2D = _streak_texture()
	var add_sh := Shader.new()
	add_sh.code = "shader_type canvas_item;\nrender_mode blend_add;\nuniform float k = 1.0;\nvoid fragment(){ vec4 c = texture(TEXTURE, UV); COLOR = vec4(c.rgb * k, c.a); }"
	for i in 4:
		var dd: Vector2 = Vector2(cos(deg_to_rad(float(ANG[i]))), sin(deg_to_rad(float(ANG[i]))))
		# zona ritagliata attorno alla sola pennellata (area di riempimento molto minore di un quadrato intero)
		var org: Vector2
		var sz: Vector2
		if absf(dd.x) > absf(dd.y):
			sz = Vector2(485.0, 500.0)
			org = Vector2(WHEEL_C.x - (70.0 if dd.x > 0.0 else 415.0), WHEEL_C.y - 250.0)
		else:
			sz = Vector2(500.0, 485.0)
			org = Vector2(WHEEL_C.x - 250.0, WHEEL_C.y - (70.0 if dd.y > 0.0 else 415.0))
		for lt in [false, true]:
			var svp := SubViewport.new()
			svp.size = Vector2i(int(sz.x), int(sz.y))
			svp.transparent_bg = true
			svp.render_target_update_mode = SubViewport.UPDATE_ONCE
			add_child(svp)
			var bk := _PaintBake.new()
			bk.size = sz
			bk.origin = org
			bk.dir_i = i
			bk.light = lt
			bk.aura = _G.col
			svp.add_child(bk)
			var tr := TextureRect.new()
			tr.texture = svp.get_texture()
			tr.size = sz
			tr.position = org
			tr.pivot_offset = WHEEL_C - org
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if lt:
				var m := ShaderMaterial.new()
				m.shader = add_sh
				tr.material = m
				paint_light.append(tr)
			else:
				paint_flat.append(tr)
			paint_bakes.append(bk)
			paint_svps.append(svp)
			world.add_child(tr)
	for i in 4:
		var d: Vector2 = Vector2(cos(deg_to_rad(float(ANG[i]))), sin(deg_to_rad(float(ANG[i]))))
		var rs: float = 0.8 if d.y < -0.5 else 1.0
		var pts := PackedVector2Array()
		for k in 18:
			pts.append(WHEEL_C + d * lerpf(40.0, WHEEL_R + 150.0 * rs, float(k) / 17.0))
		var ps := CPUParticles2D.new()
		ps.texture = streak_tex
		ps.amount = 10
		ps.lifetime = 1.15
		ps.preprocess = 1.15
		ps.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
		ps.emission_points = pts
		ps.direction = d
		ps.spread = 8.0
		ps.gravity = Vector2.ZERO
		ps.initial_velocity_min = 170.0
		ps.initial_velocity_max = 340.0
		ps.damping_min = 40.0
		ps.damping_max = 110.0
		ps.scale_amount_min = 0.9
		ps.scale_amount_max = 2.1
		ps.particle_flag_align_y = true
		var gr := Gradient.new()
		gr.offsets = PackedFloat32Array([0.0, 0.18, 0.7, 1.0])
		gr.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		ps.color_ramp = gr
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		ps.material = cm
		world.add_child(ps)
		streaks.append(ps)


func _streak_texture() -> Texture2D:
	# striscia di luce affusolata: testa luminosa in basso, coda che sfuma
	var img := Image.create(8, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var a: float = pow(float(y) / 63.0, 1.8)
		for x in 8:
			var cx: float = 1.0 - absf((float(x) - 3.5) / 3.5)
			img.set_pixel(x, y, Color(1, 1, 1, a * pow(cx, 0.7)))
	return ImageTexture.create_from_image(img)


func _recolor() -> void:
	if _G.col == _baked_col:
		return
	_baked_col = _G.col
	for k in paint_bakes.size():
		paint_bakes[k].aura = _G.col
		paint_bakes[k].queue_redraw()
		paint_svps[k].render_target_update_mode = SubViewport.UPDATE_ONCE
	for ps in streaks:
		ps.color = _G.col.lightened(0.45)


# ---------- Dati dal motore ----------

func _battle() -> Dictionary:
	return src.battle


func _slot_unit(slot_i: int) -> Dictionary:
	var p: Dictionary = BattleState.player(_battle(), str(slots[slot_i]))
	return BattleState.unit(_battle(), str(p["active"]))


func _slot_alive(slot_i: int) -> bool:
	var u: Dictionary = _slot_unit(slot_i)
	return BattleState.is_alive(u)


func _choice_for(move_id: String) -> Dictionary:
	var move: Dictionary = BattleContent.MOVES[move_id]
	var choice: Dictionary = {"swap": "", "move": move_id, "target": "", "order": "", "push": ""}
	if str(move["target"]) == "ally":
		var best: String = str(src.local_player_id)
		var worst: float = 2.0
		for p in _battle()["players"]:
			var a: Dictionary = BattleState.unit(_battle(), str(p["active"]))
			if BattleState.is_alive(a):
				var r: float = float(a["hp"]) / float(maxi(1, int(a["max_hp"])))
				if r < worst:
					worst = r
					best = str(p["id"])
		choice["target"] = best
	return choice


func _usable(move_id: String) -> String:
	if cur < 0:
		return "nessuno slot"
	return BattleResolver.validate_choice(_battle(), str(slots[cur]), _choice_for(move_id))


func _build_cmds() -> void:
	var cmds: Array = []
	var u: Dictionary = _slot_unit(maxi(cur, 0))
	var skills: Array = u.get("skills", [])
	# ATTACK
	var atk_ok: bool = cur >= 0 and skills.has("attack") and _usable("attack") == ""
	cmds.append({"ok": atk_ok, "move": "attack", "sub": "ATTACCO BASE", "cost": "", "title": "ATTACCO", "desc": "Danno x1.0 al bersaglio"})
	# SKILL: la prima mossa utilizzabile (tocca ancora SKILL per cambiare)
	skill_opts = []
	for m in skills:
		if str(BattleContent.MOVES[str(m)]["kind"]) == "skill" and cur >= 0 and _usable(str(m)) == "":
			skill_opts.append(str(m))
	var sk: Dictionary = {"ok": false, "move": "", "sub": "NON DISPONIBILE", "cost": "", "title": "", "desc": ""}
	if not skill_opts.is_empty():
		skill_idx = skill_idx % skill_opts.size()
		var sm: String = str(skill_opts[skill_idx])
		var md: Dictionary = BattleContent.MOVES[sm]
		sk = {"ok": true, "move": sm, "sub": "ABILITA'", "cost": "%d" % int(md["cost"]), "title": BattleText.move_name(sm).to_upper(), "desc": _desc(md, u) + ("   (tocca SKILL per cambiare: %d/%d)" % [skill_idx + 1, skill_opts.size()] if skill_opts.size() > 1 else "")}
	cmds.append(sk)
	# ULTIMATE
	var ult: String = str(u.get("ult", ""))
	var gauge: int = int(u.get("gauge", 0))
	var ult_ok: bool = ult != "" and cur >= 0 and _usable(ult) == ""
	var ud: Dictionary = BattleContent.MOVES.get(ult, {})
	cmds.append({"ok": ult_ok, "move": ult, "sub": "COLPO FINALE", "cost": ("PRONTA" if gauge >= BattleTypes.GAUGE_MAX else "%d%%" % gauge), "title": ("ULTIMATE · " + BattleText.move_name(ult).to_upper()) if ult != "" else "", "desc": _desc(ud, u)})
	# GUARD
	var gd_ok: bool = cur >= 0 and skills.has("guard") and _usable("guard") == ""
	cmds.append({"ok": gd_ok, "move": "guard", "sub": "DIFESA", "cost": "", "title": "GUARDIA", "desc": "Dimezza il danno subito"})
	_G.cmds = cmds


func _desc(md: Dictionary, u: Dictionary) -> String:
	if md.is_empty():
		return ""
	var lines: Array = Hints.effect_lines(md, u)
	return str(lines[0]).trim_suffix(".") if not lines.is_empty() else ""


# Testo del vantaggio di colore (parole + numero del motore: non dipende solo dal colore)
static func _match_text(m: float) -> String:
	if m > 1.0:
		return "EFFICACE x%s" % str(snappedf(m, 0.01))
	if m < 1.0:
		return "SFAVOREVOLE x%s" % str(snappedf(m, 0.01))
	return "NEUTRO x1"


# Annuncio della mossa del boss: solo dati che il motore ha gia' deciso (begin_round).
# Visibile mentre il giocatore sceglie; nascosto a fine battaglia, durante la risoluzione del round e se il boss e' stordito (salta la mossa).
func _tele_visible(b: Dictionary, mdef: Dictionary) -> bool:
	if mdef.is_empty() or ended or boss_done or (locked and not boss_turn) or str(b.get("winner", "")) != "":
		return false
	return int(BattleState.boss(b).get("stun", 0)) <= 0


func _tele_target(b: Dictionary, mdef: Dictionary, target_id: String) -> String:
	if mdef.is_empty():
		return ""
	if str(mdef.get("target", "")) == "all":
		return "TUTTI"
	var p: Dictionary = BattleState.player(b, target_id)
	if p.is_empty():
		return ""
	return str(BattleState.unit(b, str(p["active"])).get("name", "")).to_upper()


# Disposizione spaziale virtuale (come in Metaphor): i personaggi stanno uno accanto all'altro, F1 a sinistra, F3 a destra.
# Cambiare personaggio sposta la camera di quanti posti separano i due (F1->F3 e' il doppio di F1->F2, F3->F1 va a ritroso),
# poi il nuovo operatore entra dal lato giusto e si ferma sempre nella stessa posizione di scena.
const SLOT_STEP_CAM: float = 64.0      # pixel di camera per ogni posto di distanza
const SLOT_STEP_HERO: float = 55.0
const SLOT_PAN_MAX: float = 140.0
var hero_off: float = 0.0
var hero_in: float = 1.0
var ui_dim: float = 1.0          # ruota attenuata quando non e' il turno del giocatore
var _last_slot: int = -1


func _switch_feedback(from_slot: int) -> void:
	var delta: int = cur - from_slot if from_slot >= 0 else -1      # senza precedente (inizio) un cenno da sinistra
	var d: float = float(delta)
	var k: float = _shk()
	var pan: float = clampf(d * SLOT_STEP_CAM, -SLOT_PAN_MAX, SLOT_PAN_MAX)
	cam.x += -pan * k
	cam_v.x += -signf(d) * 120.0 * k
	hero_off = clampf(d * SLOT_STEP_HERO, -SLOT_PAN_MAX, SLOT_PAN_MAX) * minf(1.0, k * 2.0)
	hero_in = 0.0
	Settings.buzz(12)


func _refresh() -> void:
	if cur != _last_cur:
		var prev_cur: int = _last_cur
		_last_cur = cur
		if prev_cur != -99 and cur >= 0 and not ended:
			_switch_feedback(_last_slot)
		if cur >= 0:
			_last_slot = cur
		appear = 0.0
		intro_t = 0.0
		if wheel_front != null:
			wheel_front.pop = [0.0, 0.0, 0.0, 0.0]
	var b: Dictionary = _battle()
	_build_cmds()
	var boss: Dictionary = BattleState.boss(b)
	var tele: Dictionary = b.get("telegraph", {})
	var tmove: String = str(tele.get("move", ""))
	var mdef: Dictionary = BattleContent.BOSS_MOVES.get(tmove, {})
	_G.boss = {"name": MissionConfig.boss_title(str(boss["char"])), "hp": int(boss["hp"]), "max": int(boss["max_hp"]), "bal": int(boss.get("balance", 0)), "bal_max": int(boss.get("balance_max", 1)), "heavy": not mdef.is_empty() and BattleResolver.is_heavy_boss_move(mdef), "move": str(mdef.get("name", tmove)), "target": _tele_target(b, mdef, str(tele.get("target", ""))), "show": _tele_visible(b, mdef)}
	# vantaggio di colore dell'operatore attivo contro il boss: lo calcola il motore (BattleTypes.color_multiplier), qui si mostra soltanto
	var mu: Dictionary = _slot_unit(maxi(cur, 0))
	var uc: String = str(mu.get("color", ""))
	_G.matchup = {"show": cur >= 0 and not locked and not ended and str(b.get("winner", "")) == "" and uc != "" and BattleState.is_alive(boss), "mult": BattleTypes.color_multiplier(uc, str(boss["color"])), "att": uc, "def": str(boss["color"])}
		# squadra
	var party: Array = []
	for i in slots.size():
		var u: Dictionary = _slot_unit(i)
		var cid: String = str(u.get("char", ""))
		var chosen: String = ""
		if choices.has(str(slots[i])):
			chosen = BattleText.move_name(str(choices[str(slots[i])]["move"])).to_upper()
		party.append({"name": str(u["name"]).to_upper(), "color": BattleTheme.unit_color(str(u["color"])), "hp": int(u["hp"]), "max_hp": int(u["max_hp"]), "en": int(u.get("energy", 0)), "faction": str(u.get("faction", "")), "alive": BattleState.is_alive(u), "ult": int(u.get("gauge", 0)) >= BattleTypes.GAUGE_MAX, "cut": ArtLibrary.cutin(cid), "chosen": chosen})
	_G.party = party
	# panchina: gli operatori del party che non sono in campo (dati del motore; scambi non ancora nel Test V2)
	var bench: Array = []
	var lead: Dictionary = BattleState.player(b, str(slots[0]))
	for uid in BattleState.party_of(b, lead):
		if BattleState.is_front(b, str(uid)):
			continue
		var bu: Dictionary = BattleState.unit(b, str(uid))
		var bcid: String = str(bu.get("char", ""))
		bench.append({"color": BattleTheme.unit_color(str(bu.get("color", ""))), "por": ArtLibrary.portrait(bcid, "neutral"), "alive": BattleState.is_alive(bu), "hp": float(bu["hp"]) / float(maxi(1, int(bu["max_hp"]))), "support": Signatures.has_bench(bcid)})
	_G.bench = bench
	_G.cur = cur if cur >= 0 else 0
	# ordine del round (portrait in alto)
	var order: Array = []
	for ti in range(maxi(turn_i, 0), turn_list.size()):
		var e: Dictionary = turn_list[ti]
		if not bool(e["boss"]) and not BattleState.is_alive(BattleState.unit(b, str(e["unit"]))):
			continue
		var isb: bool = bool(e["boss"])
		var uu: Dictionary = BattleState.unit(b, str(e["unit"]))
		order.append({"boss": isb, "color": Color("#ff5a4a") if isb else BattleTheme.unit_color(str(uu["color"])), "por": null if isb else ArtLibrary.portrait(str(uu.get("char", "")), "neutral")})
	_G.order = order
	_G.reserve = int(b.get("reserve", 0))
	_G.reserve_max = BattleTypes.RESERVE_MAX
	_G.turn_txt = "%d" % int(b.get("round", 1))
	# personaggio attivo (sprite e colore dell'aura)
	if cur >= 0:
		var au: Dictionary = _slot_unit(cur)
		_G.spr = ArtLibrary.battle_sprite(str(au.get("char", "")))
		_G.col = BattleTheme.unit_color(str(au["color"]))
	_apply_pick()


func _apply_pick() -> void:
	_G.picked = picked
	var i: int = NAMES.find(picked)
	if i >= 0:
		_G.banner_title = str(_G.cmds[i]["title"])
		_G.banner_sub = str(_G.cmds[i]["desc"])
		var mv: Dictionary = BattleContent.MOVES.get(str(_G.cmds[i]["move"]), {})
		var hits_boss: bool = str(mv.get("target", "")) == "enemy"
		_G.banner_tag_mult = float(_G.matchup["mult"])
		_G.banner_tag = _match_text(_G.banner_tag_mult) if hits_boss else ""
	wheel_letters.glow = picked != ""
	wheel_letters.picked = picked
	wheel_letters.aura = _G.col
	ring_fx.aura = _G.col
	ring_fx.picked = picked
	ring_fx.ult_ok = _G.cmds.size() > 2 and bool(_G.cmds[2]["ok"])
	ring_fx.queue_redraw()
	_recolor()
	wheel_front.picked = picked
	wheel_front.aura = _G.col
	fx.col = _G.col
	fx.ult = picked == "ULTIMATE"
	if picked != "":
		flash = _flash_k()
	hero.queue_redraw()
	wheel_letters.queue_redraw()
	wheel_front.queue_redraw()
	_hud_dirty()
	sel_banner.queue_redraw()
	sel_confirm.queue_redraw()


# Animazione continua: ingresso delle pennellate, flusso, oscuramento della scelta
func _process(delta: float) -> void:
	fx_t += delta
	appear = move_toward(appear, 1.0, delta / 0.9)
	var tgt: float = 1.0 if picked != "" else 0.0
	sel = move_toward(sel, tgt, delta / (0.5 if picked == "ULTIMATE" else (0.3 if tgt > 0.0 else 0.22)))
	flash = maxf(0.0, flash - delta * 3.2)
	var e: float = smoothstep(0.0, 1.0, sel)
	var ult: bool = picked == "ULTIMATE"
	dim.visible = e > 0.01
	dim.color = Color(0.01, 0.0, 0.05, (0.84 if ult else 0.6) * e)
	if boss_rect != null:
		boss_rect.modulate = Color.WHITE.lerp(Color(0.42, 0.42, 0.55), e)
	hero_off = lerpf(hero_off, 0.0, 1.0 - exp(-delta * 6.5))
	hero_in = move_toward(hero_in, 1.0, delta / 0.28)
	hero.position = Vector2(179.0 + hero_off, 180.0)
	hero.modulate = Color.WHITE.lerp(Color(0.92, 0.92, 1.0) if ult else Color(0.5, 0.5, 0.62), e)
	hero.modulate.a = 0.25 + 0.75 * hero_in
	if glow_rect != null:
		glow_rect.modulate = boss_rect.modulate
		(glow_rect.material as ShaderMaterial).set_shader_parameter("k", 1.0 + 0.6 * e)
	ui_dim = move_toward(ui_dim, 0.35 if (locked and not ended) else 1.0, delta / 0.2)
	wheel_letters.modulate.a = _ease3(appear * 1.4 - 0.15) * ui_dim
	wheel_front.modulate.a = ui_dim
	wheel_front.t = fx_t
	ring_fx.t = fx_t
	# pennellate: entrano a catena, respirano e ondeggiano (solo trasformazioni: costo quasi nullo)
	for i in 4:
		var pr: float = _ease3(appear * 1.7 - float(i) * 0.22)
		var on: bool = picked == NAMES[i]
		var si: float = e if on else 0.0
		var sc: float = (0.25 + 0.75 * pr) * (1.0 + 0.012 * sin(fx_t * 1.8 + float(i)) + 0.03 * si)
		var rot: float = sin(fx_t * 1.5 + float(i) * 1.3) * 0.022
		var fl: TextureRect = paint_flat[i]
		var lg: TextureRect = paint_light[i]
		fl.scale = Vector2(sc, sc)
		fl.rotation = rot
		fl.modulate = Color(1.0 - 0.3 * e * (0.0 if on else 1.0), 1.0 - 0.3 * e * (0.0 if on else 1.0), 1.0 - 0.3 * e * (0.0 if on else 1.0), pr)
		lg.scale = Vector2(sc, sc)
		lg.rotation = rot
		var kk: float = e * (1.0 + ((1.5 if ult else 0.9) if on else 0.0)) * pr
		if ult and not on:
			kk = 0.0
		lg.visible = kk > 0.01
		(lg.material as ShaderMaterial).set_shader_parameter("k", kk)
		var ps: CPUParticles2D = streaks[i]
		ps.modulate.a = pr * (0.7 + 0.3 * e + 0.3 * si)
		ps.emitting = ((not ult) or on or e < 0.5) and not Settings.light_fx    # effetti ridotti: niente scie di particelle
		ps.speed_scale = 1.0 + 1.3 * si + 0.4 * e
	fx.t = fx_t
	fx.sel = e
	fx.flash = flash
	if absf(e - _fx_e) > 0.0005 or flash > 0.01:
		_fx_e = e
		fx.queue_redraw()
	halo.visible = e > 0.01
	if halo.visible:
		# con lampi/effetti ridotti l'alone resta fermo (niente pulsazione)
		var hp: float = (0.5 + 0.5 * sin(fx_t * (8.0 if ult else 5.0))) if _flash_k() >= 0.05 else 0.5
		halo.modulate = Color(_G.col, (0.8 + 0.2 * hp) * e * (1.0 if ult else 0.7))
		halo.scale = Vector2(1.0, 1.0) * (0.85 + 0.05 * hp)
	# comandi: ingresso a rimbalzo a catena quando cambia il personaggio, impulso al tocco
	var moving: bool = false
	var pressing: bool = false
	for i in 4:
		var pv: float = float(wheel_front.pop[i])
		if pv < 1.0:
			var delay: float = float(i) * 0.09
			wheel_front.pop[i] = minf(1.0, maxf(0.0, pv + (delta if pv > 0.0 or intro_t >= delay else 0.0) / 0.55))
			moving = true
		var prs: float = float(ring_fx.press[i])
		if prs > 0.0:
			ring_fx.press[i] = maxf(0.0, prs - delta / 0.55)
			pressing = true
	intro_t += delta
	# banner e CONFERMA: scivolano dentro con sola posizione/opacita' (nessun ridisegno)
	var epb: float = 1.0 - pow(1.0 - clampf(e * 1.5, 0.0, 1.0), 3.0)
	var epc: float = 1.0 - pow(1.0 - clampf(e * 1.3 - 0.15, 0.0, 1.0), 3.0)
	sel_banner.visible = e > 0.01
	sel_banner.modulate.a = clampf(e * 1.6, 0.0, 1.0)
	sel_banner.position = ui_off * 0.7 + Vector2(-(1.0 - epb) * 170.0, 0.0)
	sel_confirm.visible = e > 0.01
	sel_confirm.modulate.a = clampf(e * 1.4, 0.0, 1.0)
	sel_confirm.position = ui_off * 0.7 + Vector2((1.0 - epc) * 110.0, 0.0)
	if moving:
		wheel_front.queue_redraw()
	if picked != "" or ring_fx.ult_ok or pressing:
		ring_fx.queue_redraw()
	# scossa dello schermo che si smorza
	# camera: molla smorzata (urti, ondeggio) + spinta in avanti; l'HUD segue in ritardo e di meno
	var dt: float = minf(delta, 0.05)
	cam_v += (-170.0 * cam - 14.0 * cam_v) * dt
	cam += cam_v * dt
	zoom_v += (-210.0 * zoom - 12.0 * zoom_v) * dt
	zoom += zoom_v * dt
	var sway: Vector2 = Vector2(sin(fx_t * 0.6) * 3.2, cos(fx_t * 0.83) * 2.2) * _shk()
	var cp: Vector2 = cam + sway
	world.position = cp
	var push: float = (0.05 if ult else 0.022) * e * _shk()
	var zs: float = 1.0 + zoom + push
	world.scale = Vector2(zs, zs)
	ui_off = ui_off.lerp(cp * 0.55, 1.0 - exp(-dt * 7.0))
	wheel_front.position = ui_off
	ring_fx.position = ui_off
	hud_view.position = ui_off * 0.7
	fx.position = -cp * 0.6
	wheel_letters.position = cp * 0.5 + Vector2(0.0, (1.0 - wheel_letters.modulate.a) * 36.0)
	_cut_step()
	if bg_node != null:
		bg_node.pivot_offset = bg_node.size * 0.5
		bg_node.scale = Vector2(1.05, 1.05)
		bg_node.position = -cp * 0.45


func _ease3(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


# ---------- Input ----------

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_tap((ev.position - stage.position) / stage.scale.x)


func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo or locked or ended:
		return
	match ev.keycode:
		KEY_1: _select(0)
		KEY_2: _select(1)
		KEY_3: _select(2)
		KEY_4: _select(3)
		KEY_U: _toggle_ult()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: _confirm()
		KEY_ESCAPE:
			if picked != "":
				_cancel()
			else:
				_exit()


func _tap(p: Vector2) -> void:
	if ended:
		return
	if locked:
		# durante le azioni (o AUTO) restano attivi solo AUTO e VELOCITA'
		var qh0: Array = hud.qhits
		for i in qh0.size():
			if (qh0[i] as Rect2).has_point(p) and (i == 2 or i == 3):
				_quick(i)
		return
	if picked != "":
		if CONFIRM_RECT.has_point(p):
			_confirm()
			return
		if CANCEL_RECT.has_point(p):
			_cancel()
			return
	for i in 4:
		var r: Rect2 = wheel_front.hits[i] if i < wheel_front.hits.size() else Rect2()
		if r.has_point(p):
			_select(i)
			return
	var qh: Array = hud.qhits
	for i in qh.size():
		if (qh[i] as Rect2).has_point(p):
			_quick(i)
			return
	if picked != "":
		_cancel()


func _quick(i: int) -> void:
	match i:
		0: Notify.toast("PANCHINA: %d operatori di riserva, gli scambi non sono ancora nel Test V2" % _G.bench.size())
		1: Notify.toast("BERSAGLIO: in questo test il bersaglio e' sempre il boss")
		2:
			_G.auto_on = not _G.auto_on
			Notify.toast("AUTO " + ("ATTIVO" if _G.auto_on else "SPENTO"))
			_hud_dirty()
			if _G.auto_on and not locked:
				_auto_turn()
		3:
			_G.speed = 2 if _G.speed == 1 else 1
			Notify.toast("VELOCITA' x%d" % _G.speed)
			_hud_dirty()


# Accessibilita': le impostazioni scelte dal giocatore (scosse, lampi, effetti ridotti, salto ultimate) valgono anche nel V2.
func _shk() -> float:
	return clampf(Settings.shake, 0.0, 1.0)


func _flash_k() -> float:
	return clampf(Settings.flash, 0.0, 1.0)


func _select(i: int) -> void:
	if locked or ended or cur < 0:
		return
	var c: Dictionary = _G.cmds[i]
	if not bool(c["ok"]):
		Notify.toast("%s non disponibile ora" % NAMES[i])
		ring_fx.press[i] = 0.6
		cam_v += Vector2(-30, 10) * _shk()
		Settings.buzz(12)
		return
	ring_fx.press[i] = 1.0
	var ult_sel: bool = NAMES[i] == "ULTIMATE"
	cam_v += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * (210.0 if ult_sel else 85.0) * _shk()
	zoom_v += (0.95 if ult_sel else 0.4) * _shk()
	Settings.buzz(45 if NAMES[i] == "ULTIMATE" else 18)
	if NAMES[i] == "SKILL" and picked == "SKILL" and skill_opts.size() > 1:
		skill_idx += 1
		_build_cmds()
	picked = NAMES[i]
	_apply_pick()


func _cancel() -> void:
	picked = ""
	_apply_pick()


func _confirm() -> void:
	if picked == "" or locked or ended or cur < 0:
		return
	var i: int = NAMES.find(picked)
	var move_id: String = str(_G.cmds[i]["move"])
	var choice: Dictionary = _choice_for(move_id)
	var pid: String = str(slots[cur])
	_act_fx(picked == "ULTIMATE", _G.col)
	picked = ""
	skill_idx = 0
	_resolve_action(pid, choice)


# Effetti della conferma (colpo di camera, lampo, esplosione dell'ultimate): uguali per scelta manuale e AUTO
func _act_fx(is_ult: bool, col: Color) -> void:
	cam_v += Vector2(150, -25) * _shk()
	zoom_v += 0.65 * _shk()
	flash = _flash_k()
	if is_ult and not Settings.skip_cutin and _flash_k() >= 0.05:
		ult_cut = CUT_FRAMES
		ult_col = col
	elif is_ult:
		# senza esplosione (lampi/cut-in disattivati) un segnale morbido: solo scritta, nessun lampo
		_float_text("ULTIMATE!", Vector2(560, 300), col, 52, 1.2)
	Settings.buzz(70 if is_ult else 30)


# ---------- Round a turni: ognuno sceglie e agisce nel proprio turno, in ordine di velocita' ----------
# L'azione si risolve subito dopo la conferma (SeqRound), poi tocca al successivo; vale anche per AUTO.

var turn_list: Array = []       # ordine del round (SeqRound.order): operatori e boss per velocita'
var turn_i: int = -1
var boss_turn: bool = false     # il boss sta per agire (l'annuncio della sua mossa resta visibile)
var boss_done: bool = false     # il boss ha gia' agito in questo round


func _start_round() -> void:
	choices = {}
	boss_turn = false
	boss_done = false
	picked = ""
	_charge_ult()
	SeqRound.begin(_battle())
	turn_list = SeqRound.order(_battle())
	turn_i = -1
	_advance()


# Passa al turno successivo: salta chi e' a terra, fa agire il boss, ferma il gioco sul prossimo operatore (o lo gioca l'IA con AUTO)
func _advance() -> void:
	while is_inside_tree():
		turn_i += 1
		var b: Dictionary = _battle()
		if str(b["winner"]) != "":
			await _end_battle()
			return
		if turn_i >= turn_list.size():
			locked = true
			cur = -1
			_refresh()
			var ev: Array = SeqRound.finish(b)
			_on_events(ev)
			await _fb_settle()
			if not is_inside_tree():
				return
			if str(b["winner"]) != "":
				await _end_battle()
			else:
				_start_round()
			return
		var e: Dictionary = turn_list[turn_i]
		if bool(e["boss"]):
			await _boss_turn()
			continue
		var pid: String = str(e["player"])
		var pl: Dictionary = BattleState.player(b, pid)
		if pl.is_empty() or not BattleState.player_alive(b, pl):
			continue
		cur = slots.find(pid)
		picked = ""
		skill_idx = 0
		locked = _G.auto_on
		_refresh()
		if _G.auto_on:
			await _auto_act(pid)
			continue
		return          # tocca al giocatore: si riprende da _confirm


# Turno del boss: la camera va verso di lui, la sua mossa resta annunciata un attimo, poi agisce
func _boss_turn() -> void:
	locked = true
	boss_turn = true
	cur = -1
	cam.x += -90.0 * _shk()
	cam_v.x += -100.0 * _shk()
	hero_in = minf(hero_in, 0.45)
	_refresh()
	await get_tree().create_timer(0.8 / float(_G.speed)).timeout
	if not is_inside_tree():
		return
	var ev: Array = SeqRound.boss_action(_battle())
	boss_turn = false
	boss_done = true
	_on_events(ev)
	_refresh()
	await _fb_settle()


# Con AUTO: l'IA sceglie per l'operatore di turno (camera gia' su di lui) e agisce
func _auto_act(pid: String) -> void:
	await get_tree().create_timer(0.55 / float(_G.speed)).timeout
	if not is_inside_tree() or ended:
		return
	var choice: Dictionary = BattleAI.choose(_battle(), pid)
	var mv: String = str(choice.get("move", ""))
	var is_ult: bool = BattleContent.MOVES.has(mv) and str(BattleContent.MOVES[mv]["kind"]) == "ult"
	_act_fx(is_ult, _G.col)
	await _resolve_action_async(pid, choice)


func _resolve_action(pid: String, choice: Dictionary) -> void:
	await _resolve_action_async(pid, choice)
	if is_inside_tree() and not ended:
		await _advance()


func _resolve_action_async(pid: String, choice: Dictionary) -> void:
	locked = true
	var ev: Array = SeqRound.player_action(_battle(), pid, choice)
	choices[pid] = {"move": str(choice.get("move", "attack"))}
	_on_events(ev)
	_refresh()
	await _fb_settle()


# Dopo ogni azione: attende la fine delle scritte (con tetto) e una pausa breve, cosi' si legge cosa e' successo
func _fb_settle() -> void:
	await get_tree().create_timer(0.35 / float(_G.speed)).timeout
	await _fb_drain()


# Per test e strumenti: attiva AUTO e fa giocare il turno corrente
func _auto_round() -> void:
	_G.auto_on = true
	_hud_dirty()
	_auto_turn()


func _auto_turn() -> void:
	if ended or cur < 0 or locked:
		return
	var pid: String = str(slots[cur])
	locked = true
	await _auto_act(pid)
	if is_inside_tree() and not ended:
		await _advance()


func _end_battle() -> void:
	await get_tree().create_timer(0.9 / float(_G.speed)).timeout
	await _fb_drain()
	if not is_inside_tree():
		return
	var w: String = str(_battle().get("winner", ""))
	ended = true
	hud.ended_ui = true
	locked = false
	boss_turn = false
	cur = -1
	_refresh()
	_show_result(w == "players")


# SOLO PER I TEST: tutti i personaggi hanno sempre la ultimate carica (a inizio battaglia e a ogni round)
var ult_sempre: bool = true     # interruttore del test: tasto ULTI in alto o tasto U
var ult_btn: Button


func _charge_ult() -> void:
	if not ult_sempre:
		return
	var units: Dictionary = _battle().get("units", {})
	for uid in units:
		if str(uid) != BattleState.BOSS_ID:
			units[uid]["gauge"] = BattleTypes.GAUGE_MAX


func _ult_btn_text() -> void:
	ult_btn.text = "ULTI: ON" if ult_sempre else "ULTI: OFF"


func _toggle_ult() -> void:
	ult_sempre = not ult_sempre
	_ult_btn_text()
	if ult_sempre:
		_charge_ult()
		if cur >= 0 and not locked:
			_refresh()
	Notify.toast("Ultimate sempre carica: " + ("ON" if ult_sempre else "OFF"))


# Il round resta "in corso" finche' le scritte non sono finite (con un tetto), cosi' non si legge sopra il turno dopo.
# Se c'e' ancora una scritta importante a schermo si lascia il tempo di leggerla.
func _fb_drain() -> void:
	var cap: float = FB_WAIT_MAX / float(maxi(1, _G.speed))
	var t0: int = Time.get_ticks_msec()
	while (_fb_busy or not _fb_queue.is_empty()) and float(Time.get_ticks_msec() - t0) / 1000.0 < cap and is_inside_tree():
		await get_tree().create_timer(0.05).timeout
	if is_inside_tree() and not get_tree().get_nodes_in_group("v2_fb").is_empty():
		await get_tree().create_timer(minf(0.5, cap * 0.25)).timeout


# ---------- Feedback degli eventi del motore ----------
# Ogni evento importante diventa una scritta breve vicino a chi lo subisce (parole, non solo colori), in sequenza leggibile.
# Il motore decide tutto: qui si legge soltanto l'evento e lo si mostra.

const FB_MAX: int = 14                 # al massimo tante scritte per round: le meno importanti cadono per prime
const FB_HOLD: float = 0.9                # secondi a schermo (x1) delle scritte normali
const FB_HOLD_BIG: float = 1.6            # K.O., rottura, fase, critico
const FB_WAIT_MAX: float = 2.5            # tetto di attesa a fine round (x1)
var _fb_queue: Array = []
var _fb_busy: bool = false


func _fb_anchor(uid: String) -> Variant:
	if uid == BattleState.BOSS_ID:
		return BOSS_POS + Vector2(150, 140)
	for i in slots.size():
		if str(_slot_unit(i).get("id", "")) == uid:
			# a sinistra del pannello squadra (x 860): le scritte non coprono nomi e barre delle righe
			return Vector2(760, 575.0 + float(slots.size() - 1 - i + (3 - slots.size())) * 50.0)
	return null


# Nome e colore di un'unita' dal motore (solo lettura)
func _fb_who(uid: String) -> Dictionary:
	var u: Dictionary = BattleState.unit(_battle(), uid)
	if u.is_empty() or uid == BattleState.BOSS_ID:
		return {}
	return {"name": str(u.get("name", "")).to_upper(), "col": BattleTheme.unit_color(str(u.get("color", "")))}


# " · NOME" quando cura/scudo arrivano da un altro personaggio (aiuto dalla panchina)
func _fb_from(e: Dictionary) -> String:
	var src_id: String = str(e.get("src", ""))
	if src_id == "" or src_id == str(e.get("dst", "")):
		return ""
	var w: Dictionary = _fb_who(src_id)
	return "" if w.is_empty() else " · " + str(w["name"])


func _fb_item(e: Dictionary) -> Dictionary:
	var t: String = str(e.get("t", ""))
	var uid: String = str(e.get("unit", e.get("dst", "")))
	var item: Dictionary = {"text": "", "col": Color.WHITE, "size": 32, "w": 1, "kick": 0.0, "boss_hit": false, "at": null}
	match t:
		"act":
			# chi agisce e con quale mossa (didascalia piccola, peso basso)
			var who: Dictionary = _fb_who(str(e.get("unit", "")))
			var mv: String = BattleText.move_name(str(e.get("move", "")))
			if who.is_empty() or mv == "":
				return {}
			item["text"] = "%s · %s" % [who["name"], mv]
			item["col"] = Color(who["col"]).lightened(0.35)
			item["size"] = 22
			item["w"] = 2
			item["at"] = Vector2(400, 125)      # didascalia in alto, lontano dalla squadra e dai numeri
		"boss_move":
			var bm: String = BattleText.move_name(str(e.get("move", "")))
			if bm == "":
				return {}
			uid = BattleState.BOSS_ID
			item["text"] = bm
			item["col"] = Color("#ff9a6a")
			item["size"] = 28
			item["w"] = 3
			item["at"] = Vector2(930, 120)
		"tenacity":
			item["text"] = "TENACIA!"
			item["col"] = Color("#ffd23a")
			item["size"] = 40
			item["w"] = 8
			item["kick"] = 60.0
		"link":
			item["text"] = "COMBO"
			item["col"] = Color("#fff36b")
			item["size"] = 34
			item["w"] = 5
		"damage":
			var amount: int = int(e.get("amount", 0))
			var absorbed: int = int(e.get("absorbed", 0))
			uid = str(e.get("dst", ""))
			if amount <= 0 and absorbed <= 0:
				return {}
			var boss_side: bool = uid == BattleState.BOSS_ID
			item["col"] = Color("#fff36b") if boss_side else Color("#ff7a6a")
			if boss_side:
				var dw: Dictionary = _fb_who(str(e.get("src", "")))
				if not dw.is_empty():
					item["col"] = Color(dw["col"]).lightened(0.45)     # il colore dice chi ha colpito
			if amount <= 0:
				item["text"] = "ASSORBITO"
				item["col"] = Color("#7fdcec")
				item["w"] = 2
			elif bool(e.get("crit", false)):
				item["text"] = "CRITICO -%d" % amount
				item["col"] = Color("#ffd23a")
				item["size"] = 44
				item["w"] = 8
				item["kick"] = 90.0
			else:
				item["text"] = "-%d" % amount
				item["w"] = 1 if (bool(e.get("thorns", false)) or bool(e.get("cost", false))) else 4
				if bool(e.get("thorns", false)) or bool(e.get("cost", false)):
					item["size"] = 26
			item["boss_hit"] = boss_side and amount > 0
		"heal":
			if int(e.get("amount", 0)) <= 0:
				return {}
			uid = str(e.get("dst", ""))
			item["text"] = "+%d" % int(e["amount"]) + _fb_from(e)
			item["col"] = Color("#7dffb0")
			item["w"] = 4
		"shield":
			if int(e.get("amount", 0)) <= 0:
				return {}
			uid = str(e.get("dst", ""))
			item["text"] = "SCUDO +%d" % int(e["amount"]) + _fb_from(e)
			item["col"] = Color("#7fdcec")
			item["w"] = 3
		"dodge":
			item["text"] = "SCHIVATA"
			item["w"] = 6
		"down":
			item["text"] = "K.O."
			item["col"] = Color("#ff4a4a")
			item["size"] = 46
			item["w"] = 10
			item["kick"] = 120.0
		"break":
			uid = BattleState.BOSS_ID
			item["text"] = "ROTTURA!"
			item["col"] = Color("#7fdcec")
			item["size"] = 50
			item["w"] = 9
			item["kick"] = 140.0
		"boss_stunned":
			uid = BattleState.BOSS_ID
			item["text"] = "STORDITO"
			item["col"] = Color("#c8f4ff")
			item["w"] = 7
		"phase":
			item["text"] = "FASE %d" % int(e.get("phase", 2))
			item["col"] = Color("#fff36b")
			item["size"] = 54
			item["w"] = 10
			item["kick"] = 150.0
			item["at"] = Vector2(560, 250)
		"status":
			item["text"] = BattleText.status_name(str(e.get("status", ""))).to_upper()
			item["col"] = Color("#ff9a6a")
			item["w"] = 3
		"debuff":
			item["text"] = "INDEBOLITO"
			item["col"] = Color("#ff9a6a")
			item["w"] = 3
		"buff":
			item["text"] = "POTENZIATO"
			item["col"] = Color("#9dffb0")
			item["w"] = 3
		"counter":
			item["text"] = "CONTRATTACCO"
			item["w"] = 5
		"react":
			item["text"] = "REAZIONE: " + str(e.get("kind", "")).to_upper()
			item["w"] = 5
		"cleanse":
			item["text"] = "PURIFICATO"
			item["col"] = Color("#9dffb0")
			item["w"] = 3
		"rescue":
			uid = str(e.get("who", uid))
			item["text"] = "SOCCORSO"
			item["col"] = Color("#7dffb0")
			item["w"] = 6
		"marks":
			if int(e.get("added", 0)) <= 0:
				return {}
			item["text"] = "MARCHIO x%d" % int(e.get("n", 1))
			item["col"] = Color("#ffd23a")
			item["w"] = 3
		_:
			return {}
	if item["at"] == null:
		item["at"] = _fb_anchor(uid)
	if item["at"] == null:
		return {}
	# gerarchia: PRINCIPALE (peso >= 8: grande, a lungo), SECONDARIO (cura, scudo, stati: piu' piccolo), DETTAGLIO (didascalie e valori minori: piccolo)
	var wgt: int = int(item["w"])
	if wgt < 8:
		item["size"] = mini(int(item["size"]), 34 if wgt >= 5 else (28 if wgt >= 3 else 24))
	return item


func _on_events(events: Array) -> void:
	var items: Array = []
	for e in events:
		var it: Dictionary = _fb_item(e)
		if not it.is_empty():
			items.append(it)
	# stessa scritta ripetuta nello stesso punto (es. PURIFICATO su piu' bersagli, SCUDO identici): una sola con "xN"
	var merged: Array = []
	for it in items:
		var m: Dictionary = {}
		for q in merged:
			if str(q["base"]) == str(it["text"]) and Vector2(q["at"]) == Vector2(it["at"]) and int(it["w"]) < 8:
				m = q
				break
		if m.is_empty():
			it["base"] = str(it["text"])
			it["n"] = 1
			merged.append(it)
		else:
			m["n"] = int(m["n"]) + 1
			m["text"] = "%s x%d" % [m["base"], int(m["n"])]
			m["w"] = maxi(int(m["w"]), int(it["w"]))
	items = merged
	# troppi eventi: si tolgono prima i meno importanti (peso piu' basso), mantenendo l'ordine
	while items.size() > FB_MAX:
		var lowest: int = 0
		for i in items.size():
			if int(items[i]["w"]) <= int(items[lowest]["w"]):
				lowest = i
		items.remove_at(lowest)
	_fb_queue.append_array(items)
	_fb_run()


func _fb_run() -> void:
	if _fb_busy:
		return
	_fb_busy = true
	while not _fb_queue.is_empty():
		if not is_inside_tree():
			break
		var it: Dictionary = _fb_queue.pop_front()
		_fb_show(it)
		var w: int = int(it["w"])
		var step: float = 0.32 if w >= 8 else (0.2 if w >= 5 else 0.12)
		await get_tree().create_timer(step / float(maxi(1, _G.speed))).timeout
	_fb_busy = false


func _fb_show(it: Dictionary) -> void:
	var at: Vector2 = it["at"]
	var ally: bool = at.x < 800.0 and at.y > 540.0       # righe della squadra: scritte a sinistra del pannello
	# scritte vicine ancora in volo: impilale verso l'alto per non coprirsi
	var near: int = 0
	for n in get_tree().get_nodes_in_group("v2_fb"):
		if n is Control and absf((n as Control).position.x - at.x) < 260.0 and absf((n as Control).position.y - at.y) < 120.0:
			near += 1
	at.y -= float(mini(near, 2)) * 40.0
	# eventi importanti (K.O., rottura, fase, critico) restano in vista piu' a lungo
	_float_text(str(it["text"]), at, Color(it["col"]), int(it["size"]), FB_HOLD_BIG if int(it["w"]) >= 8 else FB_HOLD, 850.0 if ally else 1260.0)
	var kick: float = float(it["kick"]) * _shk()
	if kick > 0.0:
		cam_v += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * kick
		zoom_v += kick * 0.002
	if bool(it["boss_hit"]) and boss_rect != null and _shk() > 0.05:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(boss_rect, "position:x", boss_rect.position.x + 8.0, 0.05)
		tw.tween_property(glow_rect, "position:x", glow_rect.position.x + 8.0, 0.05)
		tw.chain().tween_property(boss_rect, "position:x", boss_rect.position.x, 0.08)
		tw.tween_property(glow_rect, "position:x", glow_rect.position.x, 0.08)


func _float_text(t: String, at: Vector2, col: Color, size: int = 34, hold: float = 0.9, max_right: float = 1260.0) -> void:
	var l := BattleTheme.make_label(t, size, col, true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_to_group("v2_fb")
	l.modulate.a = 0.0
	stage.add_child(l)
	# la larghezza vera si conosce solo dopo un fotogramma: si posiziona allora (resta invisibile nel frattempo)
	await get_tree().process_frame
	if not is_instance_valid(l):
		return
	var w: float = maxf(l.size.x, l.get_minimum_size().x)
	l.position = Vector2(clampf(at.x - w * 0.5 + randf_range(-12.0, 12.0), 20.0, maxf(20.0, max_right - w)), clampf(at.y, 60.0, 660.0))
	l.modulate.a = 1.0
	var tw := create_tween()
	tw.set_parallel(true)
	var d: float = hold / float(maxi(1, _G.speed))
	tw.tween_property(l, "position:y", l.position.y - 60.0, d)
	tw.tween_property(l, "modulate:a", 0.0, d * 0.65).set_delay(d * 0.35)
	tw.chain().tween_callback(l.queue_free)


# ---------- Fine ----------

func _show_result(won: bool) -> void:
	src.finish()
	_result = Control.new()
	_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-170, -90)
	box.custom_minimum_size = Vector2(340, 0)
	box.add_theme_constant_override("separation", 14)
	_result.add_child(box)
	var l := BattleTheme.make_label("VITTORIA" if won else "SCONFITTA", 54, Color("#fff36b") if won else Color("#ff7a6a"), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	var sub := BattleTheme.make_label("Test V2 · addestramento (nessun premio)", 16, BattleTheme.CY_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var again := Button.new()
	again.text = "RIGIOCA"
	again.custom_minimum_size = Vector2(0, 54)
	BattleTheme.style_button(again, "primary", 22)
	again.pressed.connect(func() -> void: get_tree().reload_current_scene())
	box.add_child(again)
	var back := Button.new()
	back.text = "TORNA ALL'HUB"
	back.custom_minimum_size = Vector2(0, 54)
	BattleTheme.style_button(back, "normal", 22)
	back.pressed.connect(_exit)
	box.add_child(back)
	add_child(_result)


func _exit() -> void:
	SceneRouter.go("squad_v2")


func _add_exit() -> void:
	var eb := Button.new()
	eb.text = "ESCI"
	eb.position = Vector2(1170, 10)
	eb.size = Vector2(96, 40)
	BattleTheme.style_button(eb, "normal", 16)
	eb.pressed.connect(_exit)
	stage.add_child(eb)
	ult_btn = Button.new()
	ult_btn.position = Vector2(1040, 10)
	ult_btn.size = Vector2(120, 40)
	BattleTheme.style_button(ult_btn, "normal", 16)
	ult_btn.pressed.connect(_toggle_ult)
	stage.add_child(ult_btn)
	_ult_btn_text()



class _Shadow extends Control:
	# ombra morbida: strati concentrici sfumati, colore teal scuro in tinta con lo sfondo
	func _soft(c: Vector2, r: float, flat: float, a_total: float) -> void:
		draw_set_transform(c, 0.0, Vector2(1.0, flat))
		var n: int = 18
		var a: float = 1.0 - pow(1.0 - a_total, 1.0 / float(n))
		for k in n:
			var rr: float = r * (1.25 - 0.95 * float(k) / float(n))
			draw_circle(Vector2.ZERO, rr, Color(0.01, 0.06, 0.07, a))

	func _draw() -> void:
		_soft(Vector2(384, 650), 140.0, 0.17, 0.78)
		_soft(Vector2(870, 520), 200.0, 0.15, 0.8)


class _Hero extends Control:
	var hair: Color = _G.col.darkened(0.1)

	func _limb(a: Vector2, b: Vector2, w0: float, w1: float, col: Color) -> void:
		var d: Vector2 = (b - a).normalized()
		var n: Vector2 = Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([a + n * w0 * 0.5, b + n * w1 * 0.5, b - n * w1 * 0.5, a - n * w0 * 0.5]), col)

	func _draw() -> void:
		if _G.spr != null:
			draw_texture_rect(_G.spr, Rect2(25, 0, 330, 440), false)
			return
		var dark := Color("#150e16")
		var lava := Color("#ff7a2a")
		var cream := Color("#ece4d4")
		var shade := Color("#b8aea0")
		# gambe in affondo con venature incandescenti
		_limb(Vector2(150, 262), Vector2(104, 424), 40, 28, dark)
		_limb(Vector2(176, 262), Vector2(238, 410), 40, 28, dark)
		for k in 5:
			var t: float = 0.15 + float(k) * 0.17
			draw_line(Vector2(150, 262).lerp(Vector2(104, 424), t) + Vector2(-5, 0), Vector2(150, 262).lerp(Vector2(104, 424), t + 0.07) + Vector2(6, 0), lava, 2.5)
			draw_line(Vector2(176, 262).lerp(Vector2(238, 410), t) + Vector2(-4, 0), Vector2(176, 262).lerp(Vector2(238, 410), t + 0.08) + Vector2(5, 0), lava, 2.5)
		draw_colored_polygon(PackedVector2Array([Vector2(78, 424), Vector2(124, 418), Vector2(130, 438), Vector2(70, 440)]), shade)
		draw_colored_polygon(PackedVector2Array([Vector2(214, 408), Vector2(262, 404), Vector2(272, 426), Vector2(208, 428)]), shade)
		# giacca
		draw_colored_polygon(PackedVector2Array([Vector2(112, 160), Vector2(206, 150), Vector2(214, 262), Vector2(196, 300), Vector2(120, 296), Vector2(100, 240)]), cream)
		draw_colored_polygon(PackedVector2Array([Vector2(166, 156), Vector2(206, 150), Vector2(214, 262), Vector2(196, 300), Vector2(168, 298)]), shade)
		draw_colored_polygon(PackedVector2Array([Vector2(120, 296), Vector2(196, 300), Vector2(206, 336), Vector2(130, 340)]), cream.darkened(0.12))
		draw_line(Vector2(114, 190), Vector2(124, 292), Color(0, 0, 0, 0.35), 2.0)
		# braccio che regge la spada
		_limb(Vector2(200, 168), Vector2(262, 262), 26, 20, cream)
		_limb(Vector2(262, 262), Vector2(280, 276), 22, 18, dark)
		# spada puntata in avanti-basso
		var hand: Vector2 = Vector2(276, 272)
		var tip: Vector2 = Vector2(410, 372)
		var dd: Vector2 = (tip - hand).normalized()
		var nn: Vector2 = Vector2(-dd.y, dd.x)
		draw_colored_polygon(PackedVector2Array([hand + nn * 7.0, tip, hand - nn * 7.0]), Color("#cfd8e6"))
		draw_line(hand, tip, Color(1, 1, 1, 0.8), 1.5)
		draw_line(hand - nn * 14.0, hand + nn * 14.0, Color("#222233"), 5.0)
		# testa di tre quarti dal retro: capelli, profilo, ciuffo
		var hc := Vector2(150, 112)
		draw_circle(hc, 38.0, hair.darkened(0.15))
		draw_colored_polygon(PackedVector2Array([hc + Vector2(14, -6), hc + Vector2(36, 8), hc + Vector2(30, 34), hc + Vector2(10, 38)]), Color("#f2c8b2"))
		draw_circle(hc + Vector2(26, 8), 2.6, dark)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-40, -6), hc + Vector2(-8, -46), hc + Vector2(36, -24), hc + Vector2(8, -10), hc + Vector2(-6, 12), hc + Vector2(-36, 40)]), hair)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(6, -44), hc + Vector2(20, -76), hc + Vector2(24, -42)]), hair)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-30, 26), hc + Vector2(-50, 70), hc + Vector2(-14, 48)]), hair.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(138, 148), Vector2(172, 148), Vector2(170, 166), Vector2(140, 166)]), Color("#e0b49e"))
		# luce di taglio fredda sul lato verso il boss
		var rim := Color("#9fe8f4", 0.9)
		draw_polyline(PackedVector2Array([Vector2(206, 152), Vector2(214, 262), Vector2(198, 300)]), rim, 2.5)
		draw_polyline(PackedVector2Array([hc + Vector2(36, 8), hc + Vector2(30, 34)]), rim, 2.5)
		draw_polyline(PackedVector2Array([Vector2(240, 400), Vector2(238, 410)]), rim, 2.0)


class _Boss extends Control:
	func _limb(pts: PackedVector2Array, w: float, col: Color) -> void:
		draw_polyline(pts, col, w, true)

	func _draw() -> void:
		var body := Color("#5c2331")
		var edge := Color("#241019")
		var warm := Color("#ffb060")
		# braccia meccaniche
		var arm_c := Color("#3b1a26")
		_limb(PackedVector2Array([Vector2(112, 200), Vector2(46, 270), Vector2(40, 340), Vector2(84, 420)]), 28, arm_c)
		_limb(PackedVector2Array([Vector2(438, 200), Vector2(520, 262), Vector2(526, 340), Vector2(476, 410)]), 28, arm_c)
		_limb(PackedVector2Array([Vector2(112, 200), Vector2(46, 270), Vector2(40, 340), Vector2(84, 420)]), 4, Color(warm, 0.7))
		for c in [Vector2(84, 420), Vector2(476, 410)]:
			for k in 3:
				draw_line(c, c + Vector2(-16.0 + float(k) * 16.0, 30), Color("#2a1220"), 7.0)
		# corpo-distributore: fronte, fianco e tetto
		draw_colored_polygon(PackedVector2Array([Vector2(98, 72), Vector2(140, 48), Vector2(130, 470), Vector2(90, 458)]), body.darkened(0.5))
		draw_colored_polygon(PackedVector2Array([Vector2(140, 48), Vector2(430, 38), Vector2(442, 462), Vector2(130, 472)]), body)
		draw_polyline(PackedVector2Array([Vector2(140, 48), Vector2(430, 38), Vector2(442, 462), Vector2(130, 472), Vector2(140, 48)]), edge, 4.0)
		draw_line(Vector2(140, 48), Vector2(130, 472), warm, 3.0)
		# insegna con occhi feroci
		draw_colored_polygon(PackedVector2Array([Vector2(160, 66), Vector2(414, 58), Vector2(416, 116), Vector2(160, 122)]), Color("#1a0b14"))
		for s in [-1.0, 1.0]:
			var ex: float = 287.0 + s * 62.0
			draw_colored_polygon(PackedVector2Array([Vector2(ex - 34.0 * s, 78), Vector2(ex + 34.0 * s, 96), Vector2(ex + 30.0 * s, 104), Vector2(ex - 30.0 * s, 98)]), Color("#ffe14a"))
			draw_circle(Vector2(ex, 96), 6.0, Color("#0a0b14"))
		# vetrina illuminata con "denti"
		var win := PackedVector2Array([Vector2(170, 140), Vector2(398, 134), Vector2(402, 330), Vector2(168, 336)])
		draw_colored_polygon(win, Color("#14394a"))
		var cols: Array = [Color("#e8503c"), Color("#f2c14a"), Color("#4ab4d8"), Color("#e83dce")]
		for r in 3:
			for q in 4:
				var p := Vector2(190.0 + float(q) * 52.0, 160.0 + float(r) * 56.0)
				draw_rect(Rect2(p, Vector2(34, 42)), Color(cols[(r + q) % 4], 0.88))
				draw_rect(Rect2(p, Vector2(34, 8)), Color(1, 1, 1, 0.28))
		for k in 12:
			var x: float = 172.0 + float(k) * 19.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, 138.0 - float(k) * 0.5), Vector2(x + 18.0, 137.0 - float(k) * 0.5), Vector2(x + 9.0, 160.0)]), Color("#f4efe6"))
			draw_colored_polygon(PackedVector2Array([Vector2(x, 334.0 - float(k) * 0.5), Vector2(x + 18.0, 333.0 - float(k) * 0.5), Vector2(x + 9.0, 312.0)]), Color("#f4efe6"))
		draw_polyline(PackedVector2Array(win) + PackedVector2Array([win[0]]), Color("#7fdcec"), 3.0)
		# pulsantiera e bocca-erogatore
		draw_rect(Rect2(172, 350, 226, 56), Color("#2a1018"))
		for k in 8:
			draw_rect(Rect2(184.0 + float(k) * 26.0, 362, 18, 14), Color("#ff6a60") if k % 3 == 0 else Color("#d8d2c4"))
		draw_rect(Rect2(184, 384, 198, 12), Color("#0a0b14"))
		draw_colored_polygon(PackedVector2Array([Vector2(200, 420), Vector2(372, 418), Vector2(380, 460), Vector2(194, 462)]), Color("#0a0508"))
		draw_colored_polygon(PackedVector2Array([Vector2(214, 432), Vector2(358, 430), Vector2(364, 452), Vector2(208, 454)]), Color("#ff7438", 0.55))
		# cavi penzolanti
		for k in 4:
			var x2: float = 160.0 + float(k) * 80.0
			draw_polyline(PackedVector2Array([Vector2(x2, 30), Vector2(x2 + 10, 8), Vector2(x2 + 30, -4)]), Color("#1a0b14"), 6.0)
		draw_line(Vector2(430, 38), Vector2(442, 462), Color("#9fb8ff", 0.65), 2.5)


class _U:
	# Scala unica (px alla risoluzione di progetto 1152x648; la UI scala in proporzione):
	const T_TITLE: int = 28      # titoli grandi (banner, boss)
	const T_CMD: int = 18        # comandi e nomi
	const T_QUICK: int = 16      # comandi rapidi (compatti)
	const T_SUB: int = 16        # sottotitoli / etichette piccole (minimo assoluto)
	const ICON_K: float = 0.6    # icona = 60% del diametro del suo cerchio, ovunque

	# Leggibilita' su schermi piccoli: le etichette piccole (carattere "mono", tondo con grazie) diventano Roboto
	# Bold piu' grande di `boost` con contorno piu' spesso, dallo stesso punto di partenza, senza spostare nulla.
	# I testi in Archivo Black (titoli, comandi) sono gia' grandi e restano com'erano, cosi' le posizioni calcolate
	# dalla loro larghezza non cambiano. Su PC boost = 1.0.
	static var boost: float = 1.0

	static func _small(f: Font) -> bool:
		return boost > 1.0 and f == BattleTheme.mono()

	static func skew_text(c: CanvasItem, p: Vector2, t: String, sz: int, col: Color, outline: Color = Color(0, 0, 0, 0.9), f: Font = null, ow: int = 8, sk: float = -0.22) -> void:
		var ff: Font = f if f != null else BattleTheme.display()
		if _small(ff):
			ff = BattleTheme.hud()
			sz = int(round(float(sz) * boost))
			if ow > 0:
				ow = maxi(ow, 5)
				outline = Color(outline.r, outline.g, outline.b, maxf(outline.a, 0.9))
		c.draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(sk, 1), p))
		if ow > 0:
			c.draw_string_outline(ff, Vector2.ZERO, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ow, outline)
		c.draw_string(ff, Vector2.ZERO, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
		c.draw_set_transform_matrix(Transform2D.IDENTITY)

	static func text_w(t: String, sz: int, f: Font = null) -> float:
		var ff: Font = f if f != null else BattleTheme.display()
		if _small(ff):
			return BattleTheme.hud().get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(float(sz) * boost))).x
		return ff.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x

	static func icon(c: CanvasItem, key: String, center: Vector2, px: float, col: Color) -> void:
		var tex: Texture2D = GameIcon.texture_for(GameIcon.resolve(key), "", px)
		if tex != null:
			c.draw_texture_rect(tex, Rect2(center - Vector2(px, px) * 0.5, Vector2(px, px)), false, col)

	static func slant(r: Rect2, sl: float) -> PackedVector2Array:
		return PackedVector2Array([Vector2(r.position.x + sl, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - sl, r.end.y), Vector2(r.position.x, r.end.y)])

	# Pennellata: striscia a larghezza variabile con bordi irregolari
	static func brush(c: CanvasItem, a: Vector2, b: Vector2, w0: float, w1: float, col: Color, sd: int, bend: float = 0.0, jag: float = 0.22, n: int = 16) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		var d: Vector2 = b - a
		var nrm: Vector2 = Vector2(-d.y, d.x).normalized()
		var L := PackedVector2Array()
		var Rr := PackedVector2Array()
		for i in n + 1:
			var t: float = float(i) / float(n)
			var p: Vector2 = a + d * t + nrm * sin(t * PI) * bend
			var w: float = maxf(1.5, lerpf(w0, w1, t) * 0.5)
			L.append(p + nrm * w * (1.0 + rng.randf_range(-jag, jag)))
			Rr.append(p - nrm * w * (1.0 + rng.randf_range(-jag, jag)))
		for i in n:
			c.draw_colored_polygon(PackedVector2Array([L[i], L[i + 1], Rr[i + 1], Rr[i]]), col)
		# setole a secco oltre la fine
		for k in 4:
			var o: Vector2 = nrm * (float(k) - 1.5) * w1 * 0.3
			c.draw_line(b + o, b + o + d.normalized() * rng.randf_range(14.0, 44.0), col, 2.0)

	static func star(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 16:
			var a: float = -PI / 2.0 + TAU * float(k) / 16.0
			pts.append(p + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.58))
		c.draw_colored_polygon(pts, col)
		pts.append(pts[0])
		c.draw_polyline(pts, Color(0.02, 0.03, 0.06, 0.9), 2.0)

	static func head(c: CanvasItem, p: Vector2, rad: float, hair: Color) -> void:
		c.draw_circle(p, rad, Color("#0a0b14"))
		c.draw_circle(p + Vector2(0, rad * 0.12), rad * 0.5, Color("#f4cdb8"))
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-rad * 0.62, rad * 0.05), p + Vector2(-rad * 0.3, -rad * 0.66), p + Vector2(rad * 0.34, -rad * 0.62), p + Vector2(rad * 0.64, rad * 0.02), p + Vector2(rad * 0.3, -rad * 0.18), p + Vector2(-rad * 0.3, -rad * 0.16)]), hair)


class _Wheel extends Control:
	var center: Vector2 = Vector2(365, 405)
	var aura: Color = _G.col
	var picked: String = ""
	var light_mode: bool = false
	var glow: bool = false
	var part: String = "all"        # back (dietro i personaggi) | front | all
	var hits: Array = [Rect2(), Rect2(), Rect2(), Rect2()]
	const NAMES: Array = ["ATTACK", "SKILL", "ULTIMATE", "GUARD"]
	const SUBS: Array = ["ATTACCO BASE", "ABILITA'", "COLPO FINALE", "DIFESA"]
	const LET: Array = ["A", "S", "U", "G"]
	const KEYS: Array = ["sword", "bolt", "burst", "defense"]
	const ANG: Array = [-98.0, -8.0, 82.0, 172.0]
	const R: float = 160.0

	func dir_of(i: int) -> Vector2:
		var a: float = deg_to_rad(float(ANG[i]))
		return Vector2(cos(a), sin(a))

	func pos_of(i: int) -> Vector2:
		return center + dir_of(i) * R

	func _draw() -> void:
		if part != "front":
			_back()
		if part != "back":
			_front()

	var t: float = 0.0              # tempo (s) per il flusso continuo
	var appear: float = 1.0         # 0..1: le pennellate entrano con l'animazione
	var sel: float = 0.0            # 0..1: intensita' della scelta (skill/ultimate)
	var pop: Array = [0.0, 0.0, 0.0, 0.0]     # ingresso a rimbalzo dei comandi
	var press: Array = [0.0, 0.0, 0.0, 0.0]   # impulso al tocco (1 -> 0)
	var layer: String = "both"      # paint (animato) | letters (ridisegnato solo al cambio scelta) | both

	func _ease(x: float) -> float:
		return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)

	func _back() -> void:
		var ap: float = _ease(appear)
		if layer != "letters":
			# cerchio sottile: in composizione dietro al personaggio e alle lettere
			draw_arc(center, R + 52.0, 0.0, TAU, 80, Color("#fffaf0", 0.2 * ap), 1.2, true)
		for i in 4:
			var d: Vector2 = dir_of(i)
			var on: bool = picked == NAMES[i]
			var rs: float = 0.8 if d.y < -0.5 else 1.0
			if layer != "paint":
				_letter(i, d, on)

	func _ep(d: Vector2, from: float, to: float, pr: float) -> Vector2:
		return center + d * lerpf(from, to, pr)

	func _letter(i: int, d: Vector2, on: bool) -> void:
		var lp: Vector2 = center + d * (R + 78.0) + Vector2(-44, 62)
		_U.skew_text(self, lp + Vector2(5, 5), LET[i], 168, Color(aura.darkened(0.35), 0.9), Color(0, 0, 0, 0), BattleTheme.display(), 0)
		if glow:
			_U.skew_text(self, lp, LET[i], 168, Color(aura, 0.35), Color(aura, 0.3), BattleTheme.display(), 34)
			_U.skew_text(self, lp, LET[i], 168, Color(1, 1, 1, 0.9), Color(aura.lightened(0.2), 0.8), BattleTheme.display(), 20)
		_U.skew_text(self, lp, LET[i], 168, Color("#ffffff") if glow else Color("#fffaf0"), Color(0.05, 0.02, 0.06, 0.95), BattleTheme.display(), 10)

	func _front() -> void:
		var cream := Color("#fffaf0")
		# archi sottili e linea di mira (come i cerchi sottili e la linea rossa di Metaphor)
		var hand: Vector2 = Vector2(372, 352) if _G.spr != null else Vector2(452, 452)
		draw_line(hand, Vector2(744, 349), Color(aura, 0.9), 2.0, true)
		draw_circle(hand, 5.0, Color(aura, 0.95))
		for i in 4:
			var p_rest: Vector2 = pos_of(i)
			var on: bool = picked == NAMES[i]
			var ult: bool = NAMES[i] == "ULTIMATE"
			var pe: float = clampf(float(pop[i]), 0.0, 1.0)
			var back: float = 1.0 + 2.2 * pow(pe - 1.0, 3.0) + 1.2 * pow(pe - 1.0, 2.0)    # easeOutBack: sorpassa e rimbalza
			var pr_: float = 0.0     # l'impulso al tocco e' disegnato dal nodo leggero _Ring
			var bounce: float = 1.0 + 0.32 * pr_ * cos((1.0 - pr_) * 9.0)
			var bob: Vector2 = Vector2.ZERO
			var p: Vector2 = (center.lerp(p_rest, clampf(back, 0.0, 1.25)) if pe < 1.0 else p_rest) + bob
			var rad: float = (27.0 if not on else 35.0) * clampf(0.35 + 0.65 * back, 0.0, 1.2) * bounce
			var fa: float = clampf(pe * 1.6, 0.0, 1.0)      # dissolvenza in ingresso
			var ring: Color = cream if not ult else aura.lightened(0.3)
			var ok: bool = bool(_G.cmds[i]["ok"]) if _G.cmds.size() > i else true
			var dimmed: bool = (picked != "" and not on) or not ok
			if on:
				ring = Color("#fff36b")
				draw_circle(p, rad + 20.0, Color(aura, 0.2))
				draw_circle(p, rad + 10.0, Color(aura, 0.34))
			elif ult:
				draw_circle(p, rad + 9.0, Color(aura, 0.4))
			draw_circle(p + Vector2(3, 4), rad, Color(0, 0, 0, 0.55))
			draw_circle(p, rad, Color(cream) if on else Color("#0a0b14"))
			draw_arc(p, rad, 0.0, TAU, 44, Color(ring, 0.5) if dimmed else ring, 4.0, true)
			_U.icon(self, KEYS[i], p, rad * 2.0 * _U.ICON_K, Color("#0a0b14") if on else ring)
			# feedback al tocco: onda d'urto, scintille e lampo
			if pr_ > 0.01:
				var grow: float = 1.0 - pr_
				draw_arc(p, rad + 6.0 + grow * 120.0, 0.0, TAU, 56, Color("#fff36b", pr_ * 0.9), 2.0 + 7.0 * pr_, true)
				draw_arc(p, rad + 4.0 + grow * 70.0, 0.0, TAU, 48, Color(aura.lightened(0.6), pr_ * 0.8), 2.0 + 4.0 * pr_, true)
				for k in 12:
					var ang: float = TAU * float(k) / 12.0 + float(i)
					var dv: Vector2 = Vector2(cos(ang), sin(ang))
					draw_line(p + dv * (rad + 8.0 + grow * 40.0), p + dv * (rad + 22.0 + grow * 110.0 * (0.6 + 0.4 * float(k % 3))), Color(1, 0.98, 0.8, pr_), 2.5 * pr_ + 1.0, true)
				draw_circle(p, rad * (1.0 + 0.4 * pr_), Color(1, 1, 0.9, pr_ * 0.55))
			# tasto numerato
			var kp: Vector2 = p + Vector2(rad * 0.72, -rad * 0.72)
			draw_circle(kp, 9.0, aura)
			draw_arc(kp, 9.0, 0.0, TAU, 20, Color("#0a0b14"), 2.0, true)
			_U.skew_text(self, kp + Vector2(-3.5, 5), str(i + 1), 13, Color("#0a0b14") if aura.get_luminance() > 0.55 else cream, Color(0, 0, 0, 0), BattleTheme.mono(), 0, 0.0)
			# etichetta: titolo inclinato + striscia bianca con sottotitolo
			var sz: int = 30 if on else 26
			var tw: float = _U.text_w(NAMES[i], sz)
			var left: bool = i == 3
			var rad_r: float = 27.0 if not on else 35.0
			var slide: float = (1.0 - clampf(pe * 1.4, 0.0, 1.0)) * (46.0 if left else -46.0)
			var x0: float = (p_rest.x - rad_r - 12.0 - tw if left else p_rest.x + rad_r + 12.0) + slide
			var y0: float = p_rest.y + 8.0 + bob.y
			var subt: String = str(_G.cmds[i]["sub"]) if _G.cmds.size() > i else SUBS[i]
			var sw: float = _U.text_w(subt, _U.T_SUB, BattleTheme.mono()) + 20.0
			var sx: float = x0 + (tw - sw if left else 0.0)
			draw_colored_polygon(_U.slant(Rect2(sx, y0 + 5.0, sw, 23.0), 6.0), Color(cream, 0.95 * fa))
			_U.skew_text(self, Vector2(sx + 10.0, y0 + 5.0 + 11.5 + 0.35 * float(_U.T_SUB)), subt, _U.T_SUB, Color("#14101c", fa), Color(0, 0, 0, 0), BattleTheme.mono(), 0)
			_U.skew_text(self, Vector2(x0, y0), NAMES[i], sz, Color("#fff36b", fa) if on else Color(cream, ((0.62 if ok else 0.4) if dimmed else 1.0) * fa))
			# costo accanto al sottotitolo: SKILL = riserva, ULTIMATE = carica
			var hit_r := Rect2(p_rest - Vector2(46, 46), Vector2(92, 92)).merge(Rect2(minf(x0, sx) - 6.0, y0 - 30.0, maxf(tw, sw) + 90.0, 66.0))
			hits[i] = hit_r
			var ctxt: String = str(_G.cmds[i]["cost"]) if _G.cmds.size() > i else ""
			if (i == 1 or i == 2) and ctxt != "":
				var cw: float = 28.0 + _U.text_w(ctxt, 14, BattleTheme.mono())
				var cr := Rect2(sx + sw + 6.0, y0 + 5.0, cw, 23.0)
				draw_colored_polygon(_U.slant(cr, 5.0), Color(0.04, 0.05, 0.1, 0.92))
				draw_polyline(PackedVector2Array([cr.position + Vector2(5, 0), cr.position + Vector2(cr.size.x, 0), cr.end, cr.position + Vector2(0, cr.size.y), cr.position + Vector2(5, 0)]), Color(cream, 0.5), 1.1)
				if i == 1:
					var dd := Vector2(cr.position.x + 13.0, cr.position.y + 11.5)
					draw_colored_polygon(PackedVector2Array([dd + Vector2(0, -6), dd + Vector2(5, 0), dd + Vector2(0, 6), dd + Vector2(-5, 0)]), Color("#7fdcec"))
				else:
					_U.icon(self, "burst", Vector2(cr.position.x + 13.0, cr.position.y + 11.5), 13.0, aura.lightened(0.4))
				_U.skew_text(self, Vector2(cr.position.x + 23.0, cr.position.y + 11.5 + 0.35 * 15.0), ctxt, 15, cream, Color(0, 0, 0, 0), BattleTheme.mono(), 0, 0.0)
		if picked != "":
			return
		# situazionale: cerchio piccolo
		var sp: Vector2 = center + Vector2(-142, -98)
		draw_circle(sp, 15.0, Color("#0a0b14"))
		draw_arc(sp, 15.0, 0.0, TAU, 28, cream, 2.0, true)
		_U.icon(self, "target", sp, 15.0 * 2.0 * _U.ICON_K, cream)
		var stw: float = _U.text_w("SITUAZIONALE", _U.T_SUB, BattleTheme.mono())
		_U.skew_text(self, Vector2(sp.x - 15.0 - 10.0 - stw, sp.y + 0.35 * float(_U.T_SUB)), "SITUAZIONALE", _U.T_SUB, cream, Color(0, 0, 0, 0.9), BattleTheme.mono(), 5)


class _Hud extends Control:
	var mode: String = "main"     # main | banner | confirm (banner e conferma sono nodi a parte: animati con posizione/opacita', disegnati una volta)
	var qhits: Array = []
	var ended_ui: bool = false
	var selected: bool:
		get:
			return _G.picked != ""
	const PINK: Color = Color("#ff5a4a")
	const TEAL: Color = Color("#7fdcec")
	const BLUE: Color = Color("#d8ecff")

	func _poly_line(pts: PackedVector2Array, col: Color, w: float) -> void:
		var p2 := PackedVector2Array(pts)
		p2.append(pts[0])
		draw_polyline(p2, col, w)

	# Barra sottile: binario scuro con filo chiaro, riempimento con luce in alto, punta luminosa e segmenti a taglio fine.
	func _thin(p: Vector2, w: float, frac: float, col: Color, h: float, segs: int = 0, tip: bool = true) -> void:
		draw_rect(Rect2(p + Vector2(-1, -1), Vector2(w + 2, h + 2)), Color(0, 0, 0, 0.62))
		draw_rect(Rect2(p, Vector2(w, h)), Color(col, 0.16))
		var fw: float = w * clampf(frac, 0.0, 1.0)
		draw_rect(Rect2(p, Vector2(fw, h)), col)
		draw_rect(Rect2(p, Vector2(fw, maxf(1.0, h * 0.4))), Color(1, 1, 1, 0.35))
		for t in segs:
			var x: float = p.x + w * float(t + 1) / float(segs + 1)
			draw_line(Vector2(x, p.y - 1), Vector2(x, p.y + h + 1), Color(0.02, 0.03, 0.07, 0.9), 1.5)
		if tip and fw > 2.0:
			draw_rect(Rect2(Vector2(p.x + fw - 1.5, p.y - 2.0), Vector2(2.0, h + 4.0)), Color(1, 1, 1, 0.95))
		draw_line(p + Vector2(0, h + 1.5), p + Vector2(w, h + 1.5), Color(1, 1, 1, 0.22), 1.0)

	func _bar(r: Rect2, frac: float, col: Color, ticks: int = 0) -> void:
		draw_colored_polygon(_U.slant(r, 4.0), Color(0, 0, 0, 0.78))
		var fr := Rect2(r.position, Vector2(r.size.x * frac, r.size.y))
		draw_colored_polygon(_U.slant(fr, 4.0), col)
		draw_rect(Rect2(r.position + Vector2(2, 1), Vector2(maxf(0.0, r.size.x * frac - 4.0), r.size.y * 0.32)), Color(1, 1, 1, 0.3))
		for t in ticks:
			var x: float = r.position.x + r.size.x * float(t + 1) / float(ticks + 1)
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0, 0, 0, 0.75), 2.0)

	# Curva di opacita': 100% all'inizio, 50% a x1, poi discesa dolce (ease-out) fino a 0% in x2.
	func _fade_a(x: float, x0: float, x1: float, x2: float) -> float:
		if x <= x0:
			return 1.0
		if x <= x1:
			return lerpf(1.0, 0.5, (x - x0) / maxf(1.0, x1 - x0))
		if x >= x2:
			return 0.0
		return 0.5 * pow(1.0 - (x - x1) / maxf(1.0, x2 - x1), 1.7)

	# Banner a bande continue con colore per vertice (nessuna cucitura): bordi esterni sfumati sopra, sotto e a sinistra,
	# alone e filetti colorati che sfumano lungo la lunghezza con la stessa curva di opacita'.
	func _band(xs: PackedFloat32Array, y0: float, y1: float, sl: float, col: Color, base_a: float) -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in xs.size():
			pts.append(Vector2(xs[i] + sl, y0))
			cols.append(Color(col, base_a * _bw[i]))
		for i in range(xs.size() - 1, -1, -1):
			pts.append(Vector2(xs[i], y1))
			cols.append(Color(col, base_a * _bw[i]))
		draw_polygon(pts, cols)

	var _bw := PackedFloat32Array()

	# simbolo dell'esito: triangolo in su (efficace), in giu' (sfavorevole), barretta (neutro)
	func _match_arrow(c: Vector2, m: float, col: Color) -> void:
		if m > 1.0:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(8, 6), c + Vector2(-8, 6)]), col)
		elif m < 1.0:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, 8), c + Vector2(8, -6), c + Vector2(-8, -6)]), col)
		else:
			draw_rect(Rect2(c + Vector2(-8, -2.5), Vector2(16, 5)), col)

	func _draw_banner(cream: Color) -> void:
		var title: String = _G.banner_title
		var sub: String = _G.banner_sub
		var bx: float = 450.0
		var by: float = 100.0
		var bh: float = 46.0
		var sl: float = 14.0
		var tx0: float = bx + 66.0
		var first_w: float = _U.text_w(title.split(" ")[0], 28)
		var x1: float = tx0 + first_w * 0.55
		var x2: float = tx0 + _U.text_w(title, 28) + 40.0
		_fade_banner(bx, x1, x2, by, bh, sl)
		_U.icon(self, BattleV2.ICON_OF.get(_G.picked, "bolt"), Vector2(bx + 36, by + 23), 28.0, _G.col)
		_U.skew_text(self, Vector2(tx0, by + 33), title, 28, cream, Color(0, 0, 0, 0.9), BattleTheme.display(), 6)
		_U.skew_text(self, Vector2(tx0, by + bh + 22), sub, 14, cream, Color(0, 0, 0, 0.9), BattleTheme.mono(), 5)
		if str(_G.banner_tag) != "":
			var bm: float = float(_G.banner_tag_mult)
			var bcol: Color = Color("#9dffb0") if bm > 1.0 else (Color("#ff8a78") if bm < 1.0 else cream)
			var ty: float = by + bh + 22.0 + 24.0
			_match_arrow(Vector2(tx0 + 8.0, ty - 5.0), bm, bcol)
			_U.skew_text(self, Vector2(tx0 + 24.0, ty), str(_G.banner_tag) + " SUL BOSS", 15, cream, Color(0, 0, 0, 0.9), BattleTheme.mono(), 5)


	func _draw_confirm(cream: Color) -> void:
		var cr := BattleV2.CONFIRM_RECT
		draw_colored_polygon(_U.slant(Rect2(cr.position + Vector2(3, 3), cr.size), 9.0), Color(0, 0, 0, 0.5))
		draw_colored_polygon(_U.slant(cr, 9.0), Color("#fff36b"))
		var cw0: float = _U.text_w("CONFERMA", 20, BattleTheme.display())
		_U.skew_text(self, Vector2(cr.position.x + (cr.size.x - cw0) * 0.5, cr.position.y + 27.0), "CONFERMA", 20, Color("#14101c"), Color(1, 1, 1, 0.4), BattleTheme.display(), 3)
		var ar := BattleV2.CANCEL_RECT
		draw_colored_polygon(_U.slant(ar, 7.0), Color(0.04, 0.05, 0.1, 0.85))
		var aw0: float = _U.text_w("ANNULLA", 15, BattleTheme.display())
		_U.skew_text(self, Vector2(ar.position.x + (ar.size.x - aw0) * 0.5, ar.position.y + 21.0), "ANNULLA", 15, cream, Color(0, 0, 0, 0.9), BattleTheme.display(), 4)

	func _fade_banner(x0: float, x1: float, x2: float, y: float, h: float, sl: float) -> void:
		var xs := PackedFloat32Array()
		_bw = PackedFloat32Array()
		var xl: float = x0 - 12.0
		var x: float = xl
		while x < x2 + 8.0:
			xs.append(x)
			_bw.append(_fade_a(maxf(x, x0), x0, x1, x2) * clampf((x - xl) / 12.0, 0.0, 1.0))
			x += 8.0
		var dark := Color(0.04, 0.05, 0.1)
		_band(xs, y - 12.0, y + h + 12.0, sl, _G.col, 0.14)
		for k in range(6, -1, -1):
			var e: float = float(k) * 1.8
			_band(xs, y - e, y + h + e, sl, dark, 0.20 if k > 0 else 0.55)
		var top_p := PackedVector2Array()
		var bot_p := PackedVector2Array()
		var tc := PackedColorArray()
		var tg := PackedColorArray()
		for i in xs.size():
			top_p.append(Vector2(xs[i] + sl, y))
			bot_p.append(Vector2(xs[i], y + h))
			tc.append(Color(1, 1, 1, _bw[i]))
			tg.append(Color(1, 1, 1, 0.22 * _bw[i]))
		draw_polyline_colors(top_p, tg, 6.0)
		draw_polyline_colors(bot_p, tg, 6.0)
		draw_polyline_colors(top_p, tc, 2.0)
		draw_polyline_colors(bot_p, tc, 2.0)

	func _draw() -> void:
		var cream := Color("#fffaf0")
		if mode == "banner":
			if selected:
				_draw_banner(cream)
			return
		if mode == "confirm":
			if selected:
				_draw_confirm(cream)
			return
		# --- ordine dei turni: linea bianca sottile che finisce presto, ritratti in rettangoli alti di dimensione decrescente ---
		var ly: float = 44.0
		# freccia: linea che sfuma in entrata, alone luminoso sfocato, punta stilizzata a freccia con tacca (opacita' 98%)
		var lp := PackedVector2Array()
		var lc := PackedColorArray()
		var lg := PackedColorArray()
		for i in 41:
			var t: float = float(i) / 40.0
			var xx: float = 124.0 + t * 386.0
			lp.append(Vector2(xx, ly))
			var al: float = 0.98 * clampf(t / 0.18, 0.0, 1.0)
			lc.append(Color(1.0, 0.985, 0.94, al))
			lg.append(Color(0.80, 0.95, 1.0, al))
		var warm := Color(1.0, 0.985, 0.94)
		for gk in 6:
			var gw: float = 2.0 + float(gk) * 2.6
			var ga: float = 0.07 * pow(1.0 - float(gk) / 6.0, 1.2)
			var gcol := PackedColorArray()
			for i in 41:
				gcol.append(Color(0.80, 0.95, 1.0, ga * lc[i].a))
			draw_polyline_colors(lp, gcol, gw, true)
		draw_polyline_colors(lp, lc, 1.8, true)
		var tip := Vector2(532.0, ly)
		var head := PackedVector2Array([Vector2(498, ly - 9.5), tip, Vector2(498, ly + 9.5), Vector2(506, ly)])
		for gk in 5:
			var grow: float = 1.0 + float(gk) * 0.22
			var hp := PackedVector2Array()
			for p in head:
				hp.append(tip + (p - tip) * grow + Vector2(float(gk) * 0.6, 0.0))
			draw_colored_polygon(hp, Color(0.80, 0.95, 1.0, 0.07 * pow(1.0 - float(gk) / 5.0, 1.1)))
		draw_colored_polygon(head, Color(warm, 0.98))
		_U.skew_text(self, Vector2(22, 30), "TURNI", 16, cream, Color(0, 0, 0, 0.9), BattleTheme.mono(), 5)
		_U.skew_text(self, Vector2(22, 68), _G.turn_txt, 30, cream, Color(0, 0, 0, 0.9), BattleTheme.display(), 7)
		var ord: Array = _G.order
		var tx: float = 140.0
		for i in mini(4, ord.size()):
			var o: Dictionary = ord[i]
			var rh: float = 40.0
			var rw: float = rh * 1.7
			var enemy: bool = bool(o["boss"])
			var rc := Rect2(tx, ly - rh * 0.5, rw, rh)
			var edge: Color = Color("#ff5a4a") if enemy else Color(o["color"])
			var gl: Color = edge.lightened(0.35)
			for gk in 7:
				var ga: float = (0.30 if i == 0 else 0.20) * pow(1.0 - float(gk) / 7.0, 1.3)
				draw_rect(Rect2(rc.position - Vector2(1.0 + float(gk) * 1.5, 1.0 + float(gk) * 1.5), rc.size + Vector2(2.0 + float(gk) * 3.0, 2.0 + float(gk) * 3.0)), Color(gl, ga), false, 2.6)
			draw_rect(rc, Color(0.04, 0.05, 0.1, 0.95))
			var ptex: Texture2D = o["por"]
			if ptex != null:
				var ts: Vector2 = ptex.get_size()
				draw_texture_rect_region(ptex, rc, Rect2(ts.x * 0.11, ts.y * 0.1536, ts.x * 0.78, ts.y * 0.328))
			else:
				_U.head(self, rc.get_center() + Vector2(0, 2), rh * 0.42, edge)
			draw_rect(rc, Color(edge.lightened(0.15), 0.98), false, 2.6 if i == 0 else 1.8)
			var cl: float = 9.0
			var cc := Color(1, 1, 1, 0.98)
			draw_line(rc.position + Vector2(-1, -1), rc.position + Vector2(cl, -1), cc, 2.2)
			draw_line(rc.position + Vector2(-1, -1), rc.position + Vector2(-1, cl), cc, 2.2)
			draw_line(rc.end + Vector2(1, 1), rc.end + Vector2(-cl, 1), cc, 2.2)
			draw_line(rc.end + Vector2(1, 1), rc.end + Vector2(1, -cl), cc, 2.2)
			if enemy and bool(_G.boss["show"]) and bool(_G.boss["heavy"]):
				_U.icon(self, "danger", rc.position + Vector2(rw - 8.0, 8.0), 13.0, Color("#fff36b"))
			if not enemy:
				var bp: Vector2 = rc.position + Vector2(0, rh)
				var np: Vector2 = bp + Vector2(5.0, -4.0)
				var ns: String = str(i + 1)
				_U.skew_text(self, np, ns, 15, Color(1, 1, 1, 0), Color(0.80, 0.95, 1.0, 0.10), BattleTheme.display(), 12, 0.0)
				_U.skew_text(self, np, ns, 15, Color(1, 1, 1, 0), Color(0.80, 0.95, 1.0, 0.18), BattleTheme.display(), 8, 0.0)
				_U.skew_text(self, np, ns, 15, Color(1, 1, 1, 1.0), Color(0, 0, 0, 0.75), BattleTheme.display(), 3, 0.0)
			tx += rw + 18.0
		# --- nome del boss stile Metaphor: sbarra di mira + targhetta piccola sul boss, barre sottili sotto, debolezze a destra ---
		var sc := Vector2(770.0, 340.0)
		var hp_f: float = float(_G.boss["hp"]) / maxf(1.0, float(_G.boss["max"]))
		var bal_f: float = float(_G.boss["bal"]) / maxf(1.0, float(_G.boss["bal_max"]))
		var ring_p := sc + Vector2(-26.0, 9.0)
		draw_circle(ring_p, 7.0, Color(0, 0, 0, 0.75))
		draw_arc(ring_p, 7.0, 0.0, TAU, 20, cream, 1.8, true)
		# due sbarre diagonali identiche affiancate: bianca = salute, celeste = equilibrio (parte vuota in trasparenza)
		for bk in 2:
			var off := Vector2(-11.0, 0.0) if bk == 0 else Vector2.ZERO
			var bcol: Color = Color("#fffaf0") if bk == 0 else Color("#7fdcec")
			var bf: float = hp_f if bk == 0 else bal_f
			var p0: Vector2 = sc + off + Vector2(-9, 26)
			var p1: Vector2 = sc + off + Vector2(6, -26)
			var p2: Vector2 = sc + off + Vector2(15, -26)
			var p3: Vector2 = sc + off + Vector2(0, 26)
			draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(bcol, 0.28))
			draw_colored_polygon(PackedVector2Array([p0, p0.lerp(p1, bf), p3.lerp(p2, bf), p3]), bcol)
			draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), Color(0, 0, 0, 0.8), 1.6)
		var shown: String = str(_G.boss["name"]).to_upper()
		var nsz: int = 26
		var bw: float = 380.0
		var ntw: float = _U.text_w(shown, nsz, BattleTheme.mono())
		if ntw > bw - 70.0:
			nsz = maxi(14, int(26.0 * (bw - 70.0) / ntw))
			ntw = _U.text_w(shown, nsz, BattleTheme.mono())
		var bx0: float = sc.x + 16.0
		var ytop: float = sc.y - 26.0
		var kk: float = 0.3                       # stessa pendenza di F1 / RISERVA (9 px su 30)
		var xr0: float = bx0 + bw                   # bordo destro in alto (y = 24)
		var xl0: float = bx0 + kk * 38.0  # bordo sinistro in alto
		var pl := Rect2(bx0, ytop, bw, 38.0)
		draw_colored_polygon(_U.slant(Rect2(pl.position + Vector2(3, 3), pl.size), kk * 38.0), Color(0, 0, 0, 0.35))
		draw_colored_polygon(_U.slant(pl, kk * 38.0), Color("#ffe01a", 0.93))
		draw_line(Vector2(pl.position.x, pl.end.y), Vector2(pl.end.x - kk * 38.0, pl.end.y), Color("#ff5a4a"), 2.0)
		_U.skew_text(self, Vector2(pl.position.x + 24.0, pl.position.y + 19.0 + 0.35 * float(nsz)), shown, nsz, Color("#ffffff"), Color(0, 0, 0, 1.0), BattleTheme.mono(), 7, 0.0)
		_U.skew_text(self, Vector2(pl.position.x + 24.8, pl.position.y + 19.0 + 0.35 * float(nsz)), shown, nsz, Color("#ffffff"), Color(0, 0, 0, 1.0), BattleTheme.mono(), 7, 0.0)
		_U.icon(self, "danger", Vector2(pl.position.x + 24.0 + ntw + 20.0, pl.position.y + 19.0), 22.0, Color("#c8281c"))
		# barre sottili inclinate (vita bianca, equilibrio celeste) attaccate al nome; sotto, senza stacco, la targhetta corallo
		for bk in 2:
			var by0: float = pl.end.y + 3.0 + float(bk) * 8.0
			var bh0: float = 4.0
			var bcol2: Color = Color("#fffaf0") if bk == 0 else Color("#7fdcec")
			var bfr: float = hp_f if bk == 0 else bal_f
			var lt: float = xl0 - kk * (by0 - ytop)
			var rt: float = xr0 - kk * (by0 - ytop)
			var lb: float = lt - kk * bh0
			if bk == 1:
				rt = lt + (rt - lt) * 0.5   # barra equilibrio piu' corta, l'etichetta sta alla sua destra
			var rb: float = rt - kk * bh0
			draw_colored_polygon(PackedVector2Array([Vector2(lt, by0), Vector2(rt, by0), Vector2(rb, by0 + bh0), Vector2(lb, by0 + bh0)]), Color(0.0, 0.0, 0.0, 0.62))
			draw_colored_polygon(PackedVector2Array([Vector2(lt, by0), Vector2(rt, by0), Vector2(rb, by0 + bh0), Vector2(lb, by0 + bh0)]), Color(bcol2, 0.16))
			var ft: float = lt + (rt - lt) * bfr
			var fb: float = lb + (rb - lb) * bfr
			draw_colored_polygon(PackedVector2Array([Vector2(lt, by0), Vector2(ft, by0), Vector2(fb, by0 + bh0), Vector2(lb, by0 + bh0)]), bcol2)
			if bk == 1:
				_U.skew_text(self, Vector2(rt + 10.0, by0 + bh0 * 0.5 + 0.35 * 13.0), "EQUILIBRIO", 15, Color("#c8f4ff"), Color(0, 0, 0, 1.0), BattleTheme.mono(), 6, 0.0)
		if bool(_G.boss["show"]):
			var heavy: bool = bool(_G.boss["heavy"])
			var ty0: float = pl.end.y + 20.0
			var th: float = 30.0
			var lt2: float = xl0 - kk * (ty0 - ytop)
			var rt2: float = xr0 - kk * (ty0 - ytop)
			var tcol: Color = Color("#ff5a47") if heavy else Color("#7fdcec")
			if heavy:
				# leggero glow corallo attorno alla targhetta (strati sfumati), poi targhetta al 98%
				for gk in 6:
					var ge: float = 1.0 + float(gk) * 1.4
					var gp := PackedVector2Array([Vector2(lt2 - ge, ty0 - ge), Vector2(rt2 + ge, ty0 - ge), Vector2(rt2 - kk * th + ge, ty0 + th + ge), Vector2(lt2 - kk * th - ge, ty0 + th + ge)])
					draw_colored_polygon(gp, Color(tcol.lightened(0.2), 0.16 * pow(1.0 - float(gk) / 6.0, 1.2)))
			draw_colored_polygon(PackedVector2Array([Vector2(lt2, ty0), Vector2(rt2, ty0), Vector2(rt2 - kk * th, ty0 + th), Vector2(lt2 - kk * th, ty0 + th)]), Color(tcol if heavy else Color(0.03, 0.10, 0.14), 0.62 if heavy else 0.82))
			var tcp := PackedVector2Array([Vector2(lt2, ty0), Vector2(rt2, ty0), Vector2(rt2 - kk * th, ty0 + th), Vector2(lt2 - kk * th, ty0 + th), Vector2(lt2, ty0)])
			draw_polyline(tcp, tcol.lightened(0.25) if heavy else tcol, 2.4 if heavy else 1.8, true)
			if heavy:
				_U.icon(self, "danger", Vector2(lt2 + 26.0, ty0 + 15.0), 20.0, Color("#ffffff"))
			# il tipo si legge dalla parola (CARICA / MOSSA), non solo dal colore o dall'icona
			var label: String = ("CARICA · " if heavy else "MOSSA · ") + str(_G.boss["move"]).to_upper()
			if str(_G.boss["target"]) != "":
				label += " > " + str(_G.boss["target"])
			var lsz: int = 19
			var tx_start: float = lt2 + (44.0 if heavy else 20.0)
			var avail: float = (rt2 - kk * th) - tx_start - 8.0
			var lw: float = _U.text_w(label, lsz, BattleTheme.mono())
			if lw > avail:
				lsz = maxi(13, int(float(lsz) * avail / lw))
			_U.skew_text(self, Vector2(tx_start, ty0 + 15.0 + 0.35 * float(lsz)), label, lsz, Color("#ffffff"), Color(0.25, 0.02, 0.0, 0.85) if heavy else Color(0.0, 0.05, 0.08, 0.9), BattleTheme.mono(), 6)
		if bool(_G.matchup["show"]):
			var mm: float = float(_G.matchup["mult"])
			var my0: float = pl.end.y + 56.0
			var mh: float = 26.0
			var lt3: float = xl0 - kk * (my0 - ytop)
			var rt3: float = xr0 - kk * (my0 - ytop)
			var ccol: Color = Color("#9dffb0") if mm > 1.0 else (Color("#ff8a78") if mm < 1.0 else Color("#fffaf0"))
			draw_colored_polygon(PackedVector2Array([Vector2(lt3, my0), Vector2(rt3, my0), Vector2(rt3 - kk * mh, my0 + mh), Vector2(lt3 - kk * mh, my0 + mh)]), Color(0.03, 0.08, 0.12, 0.82))
			draw_polyline(PackedVector2Array([Vector2(lt3, my0), Vector2(rt3, my0), Vector2(rt3 - kk * mh, my0 + mh), Vector2(lt3 - kk * mh, my0 + mh), Vector2(lt3, my0)]), ccol, 1.6, true)
			_match_arrow(Vector2(lt3 + 18.0, my0 + mh * 0.5), mm, ccol)
			var mtxt: String = "%s SU %s · %s" % [str(_G.matchup["att"]).to_upper(), str(_G.matchup["def"]).to_upper(), BattleV2._match_text(mm)]
			var msz: int = 15
			var mavail: float = (rt3 - kk * mh) - (lt3 + 36.0) - 8.0
			var mw: float = _U.text_w(mtxt, msz, BattleTheme.mono())
			if mw > mavail:
				msz = maxi(12, int(float(msz) * mavail / mw))
			_U.skew_text(self, Vector2(lt3 + 34.0, my0 + mh * 0.5 + 0.35 * float(msz)), mtxt, msz, Color("#ffffff"), Color(0, 0, 0, 0.9), BattleTheme.mono(), 5)
		# --- panchina: operatori di riserva (solo lettura) sopra la squadra ---
		var bn: Array = _G.bench
		if bn.size() > 0:
			var bx: float = 1030.0
			var by: float = 526.0
			_U.skew_text(self, Vector2(bx, by + 17.0), "PANCHINA", 13, Color(cream, 0.9), Color(0, 0, 0, 0.85), BattleTheme.mono(), 4, 0.0)
			for k in bn.size():
				var bi: Dictionary = bn[k]
				var bc: Color = Color(bi["color"])
				var br := Rect2(bx + 78.0 + float(k) * 50.0, by - 1.0, 46.0, 28.0)
				var ba: float = 1.0 if bool(bi["alive"]) else 0.4
				draw_rect(br, Color(0.04, 0.05, 0.1, 0.92 * ba))
				var bt: Texture2D = bi["por"]
				if bt != null:
					var bts: Vector2 = bt.get_size()
					draw_texture_rect_region(bt, br, Rect2(bts.x * 0.11, bts.y * 0.1536, bts.x * 0.78, bts.y * 0.328), Color(1, 1, 1, ba))
				else:
					_U.head(self, br.get_center() + Vector2(0, 2), 11.0, bc)
				draw_rect(br, Color(bc.lightened(0.15), 0.95 * ba), false, 1.8)
				draw_rect(Rect2(br.position + Vector2(0, br.size.y), Vector2(br.size.x * clampf(float(bi["hp"]), 0.0, 1.0), 3.0)), Color(cream, 0.95 * ba))
				if bool(bi["support"]) and bool(bi["alive"]):
					draw_colored_polygon(PackedVector2Array([br.position + Vector2(br.size.x - 11.0, 0), br.position + Vector2(br.size.x, 0), br.position + Vector2(br.size.x, 11.0)]), Color("#fff36b"))
		# --- squadra: righe fisse (in basso F1), la riga attiva ha ritratto largo, etichetta F e linea ciano ---
		var party: Array = _G.party
		var n: int = party.size()
		for r in n:
			var s: int = n - 1 - r
			var pr: Dictionary = party[s]
			var y: float = 560.0 + float(r + (3 - n)) * 50.0
			var rh: float = 46.0
			var active: bool = s == _G.cur and not ended_ui
			var alive: bool = bool(pr["alive"])
			var rx0: float = 860.0
			draw_polygon(PackedVector2Array([Vector2(rx0 + 24.0, y), Vector2(rx0 + 24.0 + 420.0, y), Vector2(rx0 + 24.0 + 420.0, y + rh), Vector2(rx0 + 24.0, y + rh)]), PackedColorArray([Color(0.02, 0.03, 0.07, 0.88), Color(0.02, 0.03, 0.07, 0.15), Color(0.02, 0.03, 0.07, 0.15), Color(0.02, 0.03, 0.07, 0.88)]))
			draw_line(Vector2(rx0 + 24.0, y), Vector2(1280, y), Color(cream, 0.9 if active else 0.45), 2.0)
			if active:
				draw_line(Vector2(818, y + rh + 1.5), Vector2(1280, y + rh + 1.5), Color("#7fdcec"), 3.0)
			else:
				draw_line(Vector2(rx0 + 24.0, y + rh), Vector2(1280, y + rh), Color(cream, 0.45), 2.0)
			var pc: Color = Color(pr["color"])
			var px0: float = 1062.0
			var bgc: Color = Color(pc.darkened(0.55), 0.95) if active else Color(0.09, 0.11, 0.17, 0.95).lerp(Color(pc.darkened(0.5), 0.95), 0.28)
			draw_colored_polygon(PackedVector2Array([Vector2(px0, y + 1), Vector2(1280, y + 1), Vector2(1280, y + rh - 1), Vector2(px0, y + rh - 1)]), bgc)
			var ct: Texture2D = pr["cut"]
			if active and ct != null:
				var cs: Vector2 = ct.get_size()
				draw_texture_rect_region(ct, Rect2(px0 + 3.0, y + 1, 215.0, rh - 2.0), Rect2(cs.x * 0.206, cs.y * 0.428, cs.x * 0.5, cs.y * 0.161))
			else:
				_U.head(self, Vector2(px0 + 120.0, y + 26), 21.0, pc)
			draw_colored_polygon(PackedVector2Array([Vector2(px0 - 2.0, y + 1), Vector2(px0 + 1.0, y + 1), Vector2(px0 + 1.0, y + rh - 1), Vector2(px0 - 2.0, y + rh - 1)]), Color(pc, 0.95))
			if not alive:
				draw_rect(Rect2(rx0 + 24.0, y, 1280.0 - rx0 - 24.0, rh), Color(0, 0, 0, 0.55))
			if active:
				draw_colored_polygon(_U.slant(Rect2(818, y + 16, 62, 30), 9.0), Color("#7fdcec"))
				_U.skew_text(self, Vector2(828, y + 31 + 0.36 * 20.0), "F%d" % (s + 1), 20, Color("#0a1a22"), Color(1, 1, 1, 0.5), BattleTheme.display(), 4)
			var ec := Vector2(rx0 + 24.0, y + rh * 0.5)
			var charged: bool = bool(pr["ult"]) and alive
			var er: float = 21.0
			if charged:
				for gk in 16:
					var gr: float = er + 0.5 + float(gk) * 0.16
					draw_arc(ec, gr, 0.0, TAU, 48, Color(pc.lightened(0.35), 0.6 * pow(1.0 - float(gk) / 16.0, 1.4)), 2.4, true)
				draw_circle(ec, er, Color(pc.lightened(0.2), 0.35))
			draw_circle(ec, er, Color("#0a0b14", 0.82) if charged else Color("#0a0b14"))
			draw_arc(ec, er, 0.0, TAU, 40, Color(1, 1, 1, 1) if charged else cream, 3.0, true)
			draw_arc(ec, er - 5.0, 0.0, TAU, 40, Color(cream, 0.35), 1.2, true)
			if charged:
				draw_arc(ec, er + 1.6, 0.0, TAU, 48, Color(pc.lightened(0.5), 0.5), 1.2, true)
			var fk: String = str(pr["faction"])
			_U.icon(self, fk if GameIcon.resolve(fk) != "" else "libracorp", ec, er * 2.0 * _U.ICON_K, cream)
			var tx1: float = rx0 + 56.0
			var pname: String = str(pr["name"])
			_U.skew_text(self, Vector2(tx1, y + 16), pname, 17, cream, Color(0, 0, 0, 0.9), BattleTheme.display(), 5)
			var colw: float = 62.0
			var cx2: float = tx1 + 74.0
			if str(pr["chosen"]) != "":
				var chs: String = str(pr["chosen"])
				var chw: float = _U.text_w(chs, 12, BattleTheme.mono())
				_U.skew_text(self, Vector2(tx1 + 136.0 - chw, y + 14), chs, 12, Color("#7fdcec"), Color(0, 0, 0, 0.85), BattleTheme.mono(), 3, 0.0)
			var hps: String = "%d" % int(pr["hp"])
			var ens: String = "%d" % int(pr["en"])
			var dfont = BattleTheme.display()
			var hsz: int = 20 if hps.length() <= 3 else 17
			var hfrac: float = float(pr["hp"]) / maxf(1.0, float(pr["max_hp"]))
			var hcol: Color = Color("#ff6a5a") if (alive and hfrac < 0.3) else cream
			_U.skew_text(self, Vector2(tx1, y + 33), "PV", 14, Color(cream, 0.8), Color(0, 0, 0, 0.8), BattleTheme.mono(), 3, 0.0)
			_U.skew_text(self, Vector2(tx1 + colw - _U.text_w(hps, hsz, dfont), y + 33), hps, hsz, hcol, Color(0, 0, 0, 0.9), dfont, 5)
			_U.skew_text(self, Vector2(cx2, y + 33), "EN", 14, Color("#d8ecff", 0.8), Color(0, 0, 0, 0.8), BattleTheme.mono(), 3, 0.0)
			_U.skew_text(self, Vector2(cx2 + colw - _U.text_w(ens, 18, dfont), y + 33), ens, 18, Color("#d8ecff"), Color(0, 0, 0, 0.9), dfont, 5)
			_thin(Vector2(tx1, y + 37), colw, hfrac, Color("#ff8a7a") if (alive and hfrac < 0.3) else Color("#f3ece0"), 6.0, 0)
			_thin(Vector2(cx2, y + 37), colw, float(pr["en"]) / float(BattleTypes.MAX_ENERGY), Color("#d8ecff"), 4.0, 0, false)
			if charged and str(pr["chosen"]) == "":
				var chip := Rect2(tx1 + 66.0, y + 6.0, 36.0, 15.0)
				draw_colored_polygon(_U.slant(chip, 4.0), Color(pc.lightened(0.55), 0.97))
				_U.skew_text(self, Vector2(chip.position.x + 6.0, chip.position.y + 7.5 + 0.35 * 12.0), "ULT", 12, Color("#0a0b14"), Color(0, 0, 0, 0), BattleTheme.display(), 0)
			if not alive:
				_U.skew_text(self, Vector2(tx1 + 66.0, y + 16), "K.O.", 18, Color("#ff6a5a"), Color(0, 0, 0, 0.95), BattleTheme.display(), 6)
		# --- comandi rapidi compatti + riserva sulla stessa linea (centro y = 676) ---
		var items: Array = [["FORMAZIONE", "taunt"], ["BERSAGLIO", "target"], ["AUTO", "bolt"], ["VELOCITA'", "bolt"]]
		var qr: float = 12.0
		var qgap: float = 8.0
		var qsp: float = 16.0
		var cmd_end: float = 22.0 + 16.0
		for it0 in items:
			cmd_end += qr * 2.0 + qgap + _U.text_w(it0[0], _U.T_QUICK) + qsp
		var rcy: float = 691.0
		var rx: float = 633.0
		draw_colored_polygon(_U.slant(Rect2(rx - 12.0, rcy - 15.0, 206.0, 30.0), 9.0), Color(0.03, 0.05, 0.09, 0.62))
		draw_polyline(PackedVector2Array([Vector2(rx - 3.0, rcy - 15.0), Vector2(rx + 194.0, rcy - 15.0), Vector2(rx + 185.0, rcy + 15.0), Vector2(rx - 12.0, rcy + 15.0), Vector2(rx - 3.0, rcy - 15.0)]), Color("#7fdcec", 0.6), 1.3)
		_U.skew_text(self, Vector2(rx, rcy + 0.35 * float(_U.T_SUB)), "RISERVA", 15, Color("#ffffff"), Color(0, 0, 0, 0.9), BattleTheme.mono(), 5)
		_U.skew_text(self, Vector2(rx + 73.0, rcy + 0.36 * 26.0), str(_G.reserve), 26, cream, Color(0, 0, 0, 0.9), BattleTheme.display(), 6)
		for k in _G.reserve_max:
			var d := Vector2(rx + 104.0 + float(k) * 14.5, rcy)
			var dp := PackedVector2Array([d + Vector2(2.4, -8.0), d + Vector2(6.0, 0.0), d + Vector2(-2.4, 8.0), d + Vector2(-6.0, 0.0)])
			var dcol: Color = Color("#ffffff") if k < _G.reserve else Color(0.2, 0.22, 0.3, 0.9)
			draw_colored_polygon(dp, dcol)
			draw_polyline(PackedVector2Array([dp[0], dp[1], dp[2], dp[3], dp[0]]), dcol if k < _G.reserve else Color(cream, 0.35), 1.2, true)
		var cx: float = 22.0
		var cyc: float = 692.0
		qhits = []
		for idx in items.size():
			var it = items[idx]
			var on_q: bool = (idx == 2 and _G.auto_on) or (idx == 3 and _G.speed > 1)
			qhits.append(Rect2(cx - 8.0, cyc - 24.0, qr * 2.0 + qgap + _U.text_w(it[0], _U.T_QUICK) + 14.0, 48.0))
			draw_circle(Vector2(cx + qr, cyc), qr, Color("#7fdcec") if on_q else Color("#0a0b14"))
			draw_arc(Vector2(cx + qr, cyc), qr, 0.0, TAU, 24, cream, 2.0, true)
			_U.icon(self, it[1], Vector2(cx + qr, cyc), qr * 2.0 * _U.ICON_K, Color("#0a0b14") if on_q else cream)
			_U.skew_text(self, Vector2(cx + qr * 2.0 + qgap, cyc + 0.35 * float(_U.T_QUICK)), it[0], _U.T_QUICK, cream, Color(0, 0, 0, 0.9), BattleTheme.display(), 4)
			cx += qr * 2.0 + qgap + _U.text_w(it[0], _U.T_QUICK) + qsp
			if idx == 1:
				draw_line(Vector2(cx - qsp * 0.5 + 2.0, cyc - 11.0), Vector2(cx - qsp * 0.5 + 2.0, cyc + 11.0), Color(cream, 0.4), 1.5)
				cx += 16.0


class _PaintBake extends Control:
	# Una pennellata (direzione i) disegnata una volta sola: piatta oppure "light painting" (scie luminose dello stesso disegno)
	var origin: Vector2 = Vector2.ZERO    # angolo in alto a sinistra della zona ritagliata
	var dir_i: int = 0
	var aura: Color = Color.WHITE
	var light: bool = false

	func _ribbon(pts: PackedVector2Array, w0: float, w1: float, col: Color) -> void:
		var n: int = pts.size()
		var L := PackedVector2Array()
		var Rr := PackedVector2Array()
		for k in n:
			var a: Vector2 = pts[maxi(k - 1, 0)]
			var b: Vector2 = pts[mini(k + 1, n - 1)]
			var nr: Vector2 = (b - a).orthogonal().normalized()
			var w: float = lerpf(w0, w1, float(k) / float(n - 1)) * 0.5
			L.append(pts[k] + nr * w)
			Rr.append(pts[k] - nr * w)
		for k in n - 1:
			draw_colored_polygon(PackedVector2Array([L[k], L[k + 1], Rr[k + 1], Rr[k]]), col)

	func _spine(a: Vector2, b: Vector2, bend: float, off: float, perp: Vector2) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var d: Vector2 = b - a
		var nrm: Vector2 = Vector2(-d.y, d.x).normalized()
		for k in 22:
			var t: float = float(k) / 21.0
			pts.append(a + d * t + nrm * sin(t * PI) * bend + perp * off * (1.0 - 0.6 * t))
		return pts

	func _draw() -> void:
		var c: Vector2 = BattleV2.WHEEL_C
		var R: float = BattleV2.WHEEL_R
		draw_set_transform(-origin)
		var i: int = dir_i
		var ang: float = deg_to_rad(float(BattleV2.ANG[i]))
		var d: Vector2 = Vector2(cos(ang), sin(ang))
		var perp: Vector2 = Vector2(-d.y, d.x)
		var rs: float = 0.8 if d.y < -0.5 else 1.0
		var bend: float = 38.0 * (1.0 if i % 2 == 0 else -1.0)
		if not light:
			var c0: Color = aura
			_U.brush(self, c + d * 40.0, c + d * (R + 170.0 * rs), 118.0, 20.0, Color(c0, 1.0), 40 + i, bend)
			_U.brush(self, c + d * 80.0 + perp * 18.0, c + d * (R + 110.0 * rs) + perp * 30.0, 40.0, 8.0, Color(aura.lightened(0.55), 0.92), 60 + i, -20.0)
			_U.brush(self, c + d * (R + 10.0) - perp * 26.0, c + d * (R + 100.0 * rs) - perp * 44.0, 14.0, 3.0, Color("#d8f4ff", 0.95), 80 + i, 8.0, 0.2, 8)
			var rng := RandomNumberGenerator.new()
			rng.seed = 21 + i * 7
			for k in 14:
				var q: Vector2 = c + d * rng.randf_range(80.0, R + 190.0) + perp * rng.randf_range(-70.0, 70.0)
				draw_circle(q, rng.randf_range(1.8, 6.5), aura if k % 4 else aura.lightened(0.6))
		else:
			# light painting: stessa forma, resa come scie di luce (alone morbido + fasci sottili + nucleo quasi bianco)
			for g in 5:
				var gw: float = 118.0 + float(5 - g) * 30.0
				_U.brush(self, c + d * 30.0, c + d * (R + 190.0 * rs), gw, 30.0 + float(4 - g) * 10.0, Color(aura, 0.045 + float(g) * 0.03), 40 + i, bend, 0.1)
			var a0: Vector2 = c + d * 36.0
			var spines: Array = [[-30.0, 1.0], [0.0, 1.06], [28.0, 0.88], [-12.0, 0.72], [14.0, 0.62]]
			for sp in spines:
				var b0: Vector2 = c + d * (36.0 + (R + 150.0 * rs) * float(sp[1]))
				var pts: PackedVector2Array = _spine(a0, b0, bend, float(sp[0]), perp)
				_ribbon(pts, 40.0, 4.0, Color(aura, 0.12))
				_ribbon(pts, 22.0, 3.0, Color(aura.lightened(0.15), 0.26))
				_ribbon(pts, 10.0, 2.0, Color(aura.lightened(0.5), 0.6))
				_ribbon(pts, 3.6, 1.2, Color(aura.lightened(0.88), 0.95))
		draw_set_transform_matrix(Transform2D.IDENTITY)


class _Ring extends Control:
	# Anelli di energia sul comando: leggeri, ridisegnati ogni fotogramma (pochi archi)
	var center: Vector2 = Vector2(365, 405)
	var aura: Color = Color.WHITE
	var picked: String = ""
	var ult_ok: bool = false
	var t: float = 0.0
	var press: Array = [0.0, 0.0, 0.0, 0.0]

	func _draw() -> void:
		for i in 4:
			var a: float = deg_to_rad(float(BattleV2.ANG[i]))
			var p: Vector2 = center + Vector2(cos(a), sin(a)) * BattleV2.WHEEL_R
			var pr_: float = float(press[i])
			if pr_ > 0.01:
				# impulso al tocco: disco luminoso, onde d'urto e scintille a raggiera
				var grow: float = 1.0 - pr_
				draw_circle(p, 30.0 * (1.0 + 0.5 * pr_), Color(1, 1, 0.9, pr_ * 0.5))
				draw_arc(p, 40.0 + grow * 120.0, 0.0, TAU, 56, Color("#fff36b", pr_ * 0.9), 2.0 + 7.0 * pr_, true)
				draw_arc(p, 38.0 + grow * 70.0, 0.0, TAU, 48, Color(aura.lightened(0.6), pr_ * 0.8), 2.0 + 4.0 * pr_, true)
				for k in 12:
					var ang: float = TAU * float(k) / 12.0 + float(i)
					var dv: Vector2 = Vector2(cos(ang), sin(ang))
					draw_line(p + dv * (42.0 + grow * 40.0), p + dv * (56.0 + grow * 110.0 * (0.6 + 0.4 * float(k % 3))), Color(1, 0.98, 0.8, pr_), 2.5 * pr_ + 1.0, true)
			if picked == BattleV2.NAMES[i]:
				var pulse: float = 0.5 + 0.5 * sin(t * 7.0)
				draw_arc(p, 47.0 + 5.0 * pulse, 0.0, TAU, 40, Color(aura.lightened(0.5), 0.35 + 0.4 * pulse), 3.0, true)
				# onde di energia che si allargano dal comando
				for k in 3:
					var u: float = fposmod(t * 0.8 + float(k) / 3.0, 1.0)
					draw_arc(p, 38.0 + u * 70.0, 0.0, TAU, 36, Color("#fff36b", (1.0 - u) * 0.65), 3.0 * (1.0 - u) + 1.0, true)
			elif i == 2 and ult_ok and picked == "":
				var up: float = 0.5 + 0.5 * sin(t * 4.0)
				draw_arc(p, 38.0 + 3.0 * up, 0.0, TAU, 56, Color(aura.lightened(0.45), 0.25 + 0.45 * up), 3.0, true)
				var sh0: float = t * 3.0
				draw_arc(p, 30.0, sh0, sh0 + 0.9, 14, Color(1, 1, 1, 0.95), 5.0, true)


class _Fx extends Control:
	var halo_tex: Texture2D

	func _ready() -> void:
		var gt := GradientTexture2D.new()
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		halo_tex = gt

	# Sfondo animato della scelta: oscuramento con barre oblique, raggi e scie che scorrono (ultimate piu' intensa)
	var t: float = 0.0
	var sel: float = 0.0
	var flash: float = 0.0
	var ult: bool = false
	var col: Color = Color.WHITE
	var center: Vector2 = Vector2(365, 405)

	func _draw() -> void:
		if sel <= 0.01 and flash <= 0.01:
			return
		var e: float = smoothstep(0.0, 1.0, sel)
		var hi: Color = col.lightened(0.7)
		# ultimate: barre scure oblique che entrano dall'alto e dal basso, con filo luminoso
		if ult:
			var bt: float = size.y * 0.17 * e
			var bb: float = size.y * 0.17 * e
			draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, bt * 0.6), Vector2(0, bt * 1.4)]), Color(0, 0, 0.03, 0.88))
			draw_colored_polygon(PackedVector2Array([Vector2(0, size.y), Vector2(size.x, size.y), Vector2(size.x, size.y - bb * 1.4), Vector2(0, size.y - bb * 0.6)]), Color(0, 0, 0.03, 0.88))
			draw_line(Vector2(0, bt * 1.4), Vector2(size.x, bt * 0.6), Color(hi, 0.9 * e), 3.0, true)
			draw_line(Vector2(0, size.y - bb * 0.6), Vector2(size.x, size.y - bb * 1.4), Color(hi, 0.9 * e), 3.0, true)
		if flash > 0.01:
			draw_rect(Rect2(Vector2.ZERO, size), Color(hi, flash * (0.55 if ult else 0.3)))


class _Vignette extends Control:
	# Bordi scuri morbidi: gradiente calcolato una volta in una piccola texture, poi un solo disegno
	var tex: Texture2D

	func _ready() -> void:
		var w: int = 128
		var h: int = 72
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var dy: float = minf(float(y), float(h - 1 - y)) / float(h)
				var dx: float = minf(float(x), float(w - 1 - x)) / float(w)
				var ay: float = pow(1.0 - clampf(dy / 0.28, 0.0, 1.0), 2.0) * 0.42
				var ax: float = pow(1.0 - clampf(dx / 0.16, 0.0, 1.0), 2.0) * 0.26
				img.set_pixel(x, y, Color(0, 0, 0.04, clampf(ay + ax, 0.0, 0.7)))
		tex = ImageTexture.create_from_image(img)

	func _draw() -> void:
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)


class _CutBake extends Control:
	# Esplosione dell'ultimate disegnata UNA volta (mezza risoluzione): scie curve con bordi sfumati a strati.
	# Il colore del personaggio si applica poi con lo shader, quindi non serve ridisegnarla.
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		var c: Vector2 = BattleV2.WHEEL_C * 0.5
		for i in 4:
			var base: float = deg_to_rad(float(BattleV2.ANG[i]))
			for k in 15:
				var a0: float = base + rng.randf_range(-0.34, 0.34)
				var len_: float = rng.randf_range(110.0, 235.0) * (1.0 if k % 5 else 1.2)
				var bend: float = rng.randf_range(-0.5, 0.5)
				var w: float = rng.randf_range(1.2, 4.2)
				var r0: float = rng.randf_range(6.0, 26.0)
				var pts := PackedVector2Array()
				for j in 16:
					var t: float = float(j) / 15.0
					var ang: float = a0 + bend * t * t
					pts.append(c + Vector2(cos(ang), sin(ang)) * (r0 + (len_ - r0) * t))
				var al: float = rng.randf_range(0.5, 1.0)
				# strati dal piu' largo e tenue al sottile e vivo (bordo morbido); la coda sfuma con i colori per punto
				var cols := PackedColorArray()
				for j in 16:
					var f: float = 1.0 - float(j) / 15.0
					cols.append(Color(1, 1, 1, f * f))
				for L in 4:
					var ww: float = w * [5.0, 2.8, 1.5, 0.7][L]
					var aa: float = al * [0.07, 0.13, 0.3, 0.85][L]
					var cl := PackedColorArray()
					for q in cols:
						cl.append(Color(1, 1, 1, q.a * aa))
					draw_polyline_colors(pts, cl, ww, true)

func _build_cut() -> void:
	cut_root = Control.new()
	cut_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	cut_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_root.visible = false
	var black := ColorRect.new()
	cut_black = black
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_root.add_child(black)
	cut_stage = Control.new()
	cut_stage.size = Vector2(W, H)
	cut_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_root.add_child(cut_stage)
	add_child(cut_root)
	_center()
	var add_m := CanvasItemMaterial.new()
	add_m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# scie: bake a mezza risoluzione, colorate dallo shader
	var svp := SubViewport.new()
	svp.size = Vector2i(W / 2, H / 2)
	svp.transparent_bg = true
	svp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(svp)
	var bk := _CutBake.new()
	bk.size = Vector2(W / 2, H / 2)
	svp.add_child(bk)
	cut_fx = TextureRect.new()
	cut_fx.texture = svp.get_texture()
	cut_fx.size = Vector2(W, H)
	cut_fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cut_fx.pivot_offset = WHEEL_C
	cut_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nrender_mode blend_add;\nuniform vec4 tint : source_color = vec4(1.0);\nuniform float gain = 1.6;\nvoid fragment(){ float a = texture(TEXTURE, UV).a; vec3 c = mix(tint.rgb, vec3(1.0), a * a * 0.45); COLOR = vec4(c * a * gain, 1.0); }"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	cut_fx.material = sm
	# alone e nucleo: un solo gradiente radiale morbido, due dimensioni (sfocato e luminoso)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.45, 0.75, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.22), Color(1, 1, 1, 0.05), Color(1, 1, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	cut_glow = _cut_blob(gt, 640.0, add_m)
	cut_core = _cut_blob(gt, 230.0, add_m)
	cut_stage.add_child(cut_glow)
	cut_stage.add_child(cut_fx)
	cut_stage.add_child(cut_core)
	# comandi: punti bianchi dove stavano i tasti
	var dots := _UltDots.new()
	dots.size = Vector2(W, H)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_stage.add_child(dots)


func _cut_blob(tex: Texture2D, d: float, mat: Material) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.size = Vector2(d, d)
	t.pivot_offset = Vector2(d, d) * 0.5
	t.position = WHEEL_C - Vector2(d, d) * 0.5
	t.material = mat
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


# 4 fotogrammi: tutto nero, scie e nucleo nel colore del personaggio che esplodono; poi si torna al combattimento
func _cut_step() -> void:
	if ult_cut <= 0:
		if cut_root.visible:
			cut_root.visible = false
		return
	var u: float = 0.5 + 0.5 * float(CUT_FRAMES - ult_cut) / float(CUT_FRAMES - 1)   # 0.5 al primo fotogramma, 1 all'ultimo
	if not cut_root.visible:
		(cut_fx.material as ShaderMaterial).set_shader_parameter("tint", ult_col.lightened(0.12))
		var fk: float = _flash_k()          # intensita' dei lampi scelta dal giocatore: velo nero e luci in proporzione
		cut_black.color = Color(0, 0, 0, fk)
		cut_fx.modulate = Color(1, 1, 1, fk)
		cut_glow.modulate = Color(ult_col.lightened(0.05), 0.85 * fk)
		cut_core.modulate = Color(ult_col.lerp(Color.WHITE, 0.55), fk)
		cut_root.visible = true
	var sc: float = 0.9 + 0.35 * u if not ult_hold else 1.15
	cut_fx.scale = Vector2(sc, sc)
	cut_glow.scale = Vector2(1.0, 1.0) * (0.9 + 0.5 * u)
	cut_core.scale = Vector2(1.0, 1.0) * (0.85 + 0.3 * u)
	if not ult_hold:
		ult_cut -= 1


class _UltDots extends Control:
	# i comandi durante l'esplosione dell'ultimate: punti bianchi nella loro posizione (disegnati una volta)
	func _draw() -> void:
		for i in 4:
			var a: float = deg_to_rad(float(BattleV2.ANG[i]))
			var p: Vector2 = BattleV2.WHEEL_C + Vector2(cos(a), sin(a)) * BattleV2.WHEEL_R
			draw_circle(p, 17.0, Color(1, 1, 1, 0.18))
			draw_circle(p, 8.0, Color.WHITE)
