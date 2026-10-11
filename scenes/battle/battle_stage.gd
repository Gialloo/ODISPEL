class_name BattleStage
extends Control

# L'inquadratura della telecamera: parcheggio notturno, boss e combattenti.
# Tutto disegnato col codice (segnaposto): le figure vere sostituiranno le sagome.
# Coordinate di disegno 1280x720, scalate alle dimensioni reali del controllo.

const DW: float = 1280.0
const DH: float = 720.0
const HORIZON: float = 250.0
const BOSS_X: float = 780.0
const FLOOR_Y: float = 470.0        # dove i piedi toccano il suolo sullo schermo
const GEO_FLOOR: float = 600.0      # il suolo nelle coordinate con cui sono disegnate le figure
const ENTITY_SCALE: float = 0.76    # le figure sono disegnate in grande e ridotte qui

var state: Dictionary = {}
var boss_hit: float = 0.0           # 1 = appena colpito, scende a 0
var hit_flash: Dictionary = {}      # unit_id -> intensita'
var _t: float = 0.0
var _positions: Dictionary = {}


func _process(delta: float) -> void:
	_t += delta
	boss_hit = maxf(0.0, boss_hit - delta * 3.0)
	for uid in hit_flash.keys():
		hit_flash[uid] = maxf(0.0, float(hit_flash[uid]) - delta * 3.0)
	queue_redraw()


func set_state(new_state: Dictionary) -> void:
	state = new_state
	_layout()


func flash(uid: String) -> void:
	if uid == BattleState.BOSS_ID:
		boss_hit = 1.0
	else:
		hit_flash[uid] = 1.0


# Posizione sullo schermo (nelle coordinate di questo controllo) del petto di un'unita'.
func anchor_of(uid: String) -> Vector2:
	var p: Vector2 = _positions.get(uid, Vector2(DW * 0.5, DH * 0.5))
	return Vector2(p.x * size.x / DW, p.y * size.y / DH)


# Da coordinate "figura" a coordinate dell'inquadratura, per un'entita' ancorata in gx.
func _map(p: Vector2, gx: float) -> Vector2:
	return Vector2(gx + (p.x - gx) * ENTITY_SCALE, FLOOR_Y + (p.y - GEO_FLOOR) * ENTITY_SCALE)


func fighter_x(index: int, count: int) -> float:
	var step: float = 200.0 if count <= 1 else minf(200.0, 430.0 / float(count - 1))
	return 150.0 + float(index) * step


func _layout() -> void:
	_positions.clear()
	_positions[BattleState.BOSS_ID] = _map(Vector2(BOSS_X, 360.0), BOSS_X)
	if state.is_empty():
		return
	var players: Array = state["players"]
	var n: int = players.size()
	for i in n:
		var gx: float = fighter_x(i, n)
		_positions[str(players[i]["active"])] = _map(Vector2(gx, GEO_FLOOR - 120.0), gx)


# Imposta la trasformazione per disegnare una figura ancorata in gx.
func _entity_transform(gx: float) -> void:
	var base := Vector2(size.x / DW, size.y / DH)
	var t := Vector2(gx * (1.0 - ENTITY_SCALE), FLOOR_Y - GEO_FLOOR * ENTITY_SCALE)
	draw_set_transform(Vector2(t.x * base.x, t.y * base.y), 0.0, base * ENTITY_SCALE)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / DW, size.y / DH))
	_draw_background()
	_entity_transform(BOSS_X)
	_draw_boss()
	_draw_fighters()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------- Sfondo ----------

func _draw_background() -> void:
	# cielo a strisce
	var top: Color = Color("#041015")
	var bottom: Color = Color("#0c3038")
	var strips: int = 22
	for i in strips:
		var f: float = float(i) / float(strips - 1)
		draw_rect(Rect2(0.0, HORIZON * float(i) / float(strips), DW, HORIZON / float(strips) + 1.0), top.lerp(bottom, f))

	# palazzi lontani
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var x: float = -20.0
	while x < DW:
		var w: float = rng.randf_range(60.0, 150.0)
		var h: float = rng.randf_range(70.0, 190.0)
		draw_rect(Rect2(x, HORIZON - h, w, h), Color("#08242c"))
		draw_rect(Rect2(x, HORIZON - h, w, 3.0), Color("#12505e"))
		var wy: float = HORIZON - h + 14.0
		while wy < HORIZON - 12.0:
			var wx: float = x + 8.0
			while wx < x + w - 12.0:
				if rng.randf() < 0.28:
					draw_rect(Rect2(wx, wy, 7.0, 9.0), Color(CY_WINDOW, rng.randf_range(0.25, 0.8)))
				wx += 16.0
			wy += 20.0
		x += w + rng.randf_range(2.0, 14.0)

	# asfalto
	draw_rect(Rect2(0.0, HORIZON, DW, DH - HORIZON), Color("#071a20"))
	var vp := Vector2(DW * 0.5, HORIZON)
	var lx: float = -900.0
	while lx < DW + 900.0:
		draw_line(vp, Vector2(lx, DH), Color("#103c46", 0.75), 1.5)
		lx += 150.0
	for row in 9:
		var y: float = HORIZON + pow(float(row + 1), 2.0) * 4.6
		draw_line(Vector2(0.0, y), Vector2(DW, y), Color("#0f3640", 0.6), 1.0)

	# strisce dei parcheggi
	for side in [-1.0, 1.0]:
		for j in 4:
			var base_x: float = DW * 0.5 + side * (190.0 + float(j) * 210.0)
			draw_line(vp + Vector2(side * 18.0 * float(j + 1), 0.0), Vector2(base_x + side * 120.0, DH), Color("#9ceaf5", 0.28), 3.0)

	# lampioni
	for lamp_x in [70.0, 1210.0]:
		draw_line(Vector2(lamp_x, FLOOR_Y + 30.0), Vector2(lamp_x, 110.0), Color("#1a5a68"), 6.0)
		draw_line(Vector2(lamp_x, 110.0), Vector2(lamp_x + (46.0 if lamp_x < 640.0 else -46.0), 98.0), Color("#1a5a68"), 5.0)
		var lh: float = lamp_x + (46.0 if lamp_x < 640.0 else -46.0)
		draw_circle(Vector2(lh, 100.0), 9.0, Color("#d6ffff"))
		var cone: PackedVector2Array = PackedVector2Array([Vector2(lh, 104.0), Vector2(lh - 120.0, FLOOR_Y + 30.0), Vector2(lh + 120.0, FLOOR_Y + 30.0)])
		draw_colored_polygon(cone, Color("#7cf0ff", 0.06))


const CY_WINDOW: Color = Color("#8ff6ff")


# ---------- Boss: il distributore ----------

func _draw_boss() -> void:
	if state.is_empty():
		return
	var boss: Dictionary = BattleState.boss(state)
	var alive: bool = BattleState.is_alive(boss)
	var ratio: float = float(boss["hp"]) / float(boss["max_hp"])
	var enraged: bool = alive and ratio < BattleTypes.ENRAGE_BELOW
	var shake: Vector2 = Vector2(sin(_t * 90.0), cos(_t * 70.0)) * 5.0 * boss_hit
	var o: Vector2 = shake + Vector2(0.0, sin(_t * 1.3) * 1.5)

	# ombra
	var shadow: PackedVector2Array = PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		shadow.append(Vector2(BOSS_X + cos(a) * 210.0, GEO_FLOOR + 18.0 + sin(a) * 26.0))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.5))

	var body := Rect2(BOSS_X - 170.0 + o.x, 170.0 + o.y, 340.0, 430.0)
	var base_col: Color = Color("#0c222a") if alive else Color("#071218")
	draw_rect(body, base_col)
	draw_rect(body, BattleTheme.CY if alive else BattleTheme.CY_DARK, false, 3.0)

	# insegna in alto
	var sign_rect := Rect2(body.position.x + 12.0, body.position.y + 12.0, body.size.x - 24.0, 54.0)
	draw_rect(sign_rect, Color("#050d10"))
	draw_rect(sign_rect, BattleTheme.RD if enraged else BattleTheme.CY_DIM, false, 2.0)
	var blink: float = 1.0 if (int(_t * 2.0) % 2 == 0 or not enraged) else 0.35
	var eye_col: Color = Color(BattleTheme.RD, blink) if alive else Color("#2a1018")
	draw_rect(Rect2(sign_rect.position.x + 24.0, sign_rect.position.y + 16.0, 56.0, 22.0), eye_col)
	draw_rect(Rect2(sign_rect.end.x - 80.0, sign_rect.position.y + 16.0, 56.0, 22.0), eye_col)
	draw_string(BattleTheme.display(), Vector2(sign_rect.position.x + 96.0, sign_rect.position.y + 36.0), "ESAURITO", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, BattleTheme.WH if alive else BattleTheme.CY_DARK)

	# vetrina con i prodotti
	var glass := Rect2(body.position.x + 16.0, body.position.y + 82.0, 210.0, 250.0)
	draw_rect(glass, Color("#0f3844"))
	for shelf in 4:
		var sy: float = glass.position.y + 12.0 + float(shelf) * 60.0
		draw_line(Vector2(glass.position.x, sy + 52.0), Vector2(glass.end.x, sy + 52.0), Color("#27808f"), 2.0)
		for col in 4:
			var px: float = glass.position.x + 14.0 + float(col) * 49.0
			var hot: bool = (shelf * 4 + col) % 5 == 0
			draw_rect(Rect2(px, sy + 14.0, 34.0, 36.0), Color(BattleTheme.RD, 0.8) if hot else Color(BattleTheme.CY, 0.34))
	draw_rect(glass, BattleTheme.CY_DIM, false, 2.0)

	# tastierino e fessura
	var pad := Rect2(body.position.x + 244.0, body.position.y + 90.0, 80.0, 150.0)
	draw_rect(pad, Color("#06141a"))
	for r in 4:
		for c in 3:
			draw_rect(Rect2(pad.position.x + 8.0 + float(c) * 24.0, pad.position.y + 10.0 + float(r) * 34.0, 18.0, 24.0), Color(BattleTheme.CY, 0.55))
	draw_rect(Rect2(body.position.x + 250.0, body.position.y + 262.0, 68.0, 10.0), BattleTheme.CY_DARK)
	draw_rect(Rect2(body.position.x + 60.0, body.position.y + 350.0, 220.0, 56.0), Color("#03090c"))
	draw_rect(Rect2(body.position.x + 60.0, body.position.y + 350.0, 220.0, 56.0), BattleTheme.CY_DIM, false, 2.0)

	if boss_hit > 0.0:
		draw_rect(body, Color(1, 1, 1, 0.55 * boss_hit))

	# riquadro di tracciamento
	var br := Rect2(body.position - Vector2(26.0, 26.0), body.size + Vector2(52.0, 52.0))
	_brackets(br, BattleTheme.RD if alive else BattleTheme.CY_DARK, 5.0, 40.0)
	if alive:
		draw_line(Vector2(br.position.x + br.size.x * 0.5, br.position.y), Vector2(br.position.x + br.size.x * 0.5, br.position.y - 22.0), BattleTheme.RD, 3.0)


# ---------- Combattenti ----------

func _draw_fighters() -> void:
	if state.is_empty():
		return
	var players: Array = state["players"]
	for i in players.size():
		var p: Dictionary = players[i]
		var u: Dictionary = BattleState.unit(state, str(p["active"]))
		if u.is_empty():
			continue
		var gx: float = fighter_x(i, players.size())
		_entity_transform(gx)
		_draw_fighter(u, Vector2(gx, GEO_FLOOR - 120.0), i, i == 0)


func _draw_fighter(u: Dictionary, chest: Vector2, index: int, is_lead: bool) -> void:
	var alive: bool = BattleState.is_alive(u)
	var col: Color = BattleTheme.unit_color(str(u["color"]))
	var bob: float = sin(_t * 2.0 + float(index)) * 2.5 if alive else 0.0
	var flash_v: float = float(hit_flash.get(u["id"], 0.0))
	var foot_y: float = GEO_FLOOR + 8.0
	var cx: float = chest.x
	var body_col: Color = col.darkened(0.55) if alive else Color("#0c1a1f")
	if alive and flash_v > 0.0:
		body_col = body_col.lerp(BattleTheme.WH, flash_v)

	# ombra
	var sh: PackedVector2Array = PackedVector2Array()
	for k in 16:
		var a: float = TAU * float(k) / 16.0
		sh.append(Vector2(cx + cos(a) * 54.0, foot_y + 8.0 + sin(a) * 11.0))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.5))

	if not alive:
		# a terra
		draw_rect(Rect2(cx - 62.0, foot_y - 26.0, 124.0, 24.0), body_col)
		draw_circle(Vector2(cx + 70.0, foot_y - 16.0), 15.0, body_col)
		draw_line(Vector2(cx - 12.0, foot_y - 40.0), Vector2(cx + 12.0, foot_y - 60.0), BattleTheme.RD, 4.0)
		draw_line(Vector2(cx + 12.0, foot_y - 40.0), Vector2(cx - 12.0, foot_y - 60.0), BattleTheme.RD, 4.0)
		return

	var top: float = foot_y - 210.0 + bob
	# gambe
	draw_rect(Rect2(cx - 24.0, foot_y - 90.0, 20.0, 90.0), body_col)
	draw_rect(Rect2(cx + 4.0, foot_y - 90.0, 20.0, 90.0), body_col)
	# busto
	var torso: PackedVector2Array = PackedVector2Array([
		Vector2(cx - 40.0, top + 46.0), Vector2(cx + 40.0, top + 46.0), Vector2(cx + 30.0, foot_y - 86.0), Vector2(cx - 30.0, foot_y - 86.0)])
	draw_colored_polygon(torso, body_col)
	draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[0]]), col, 2.0)
	# braccia
	draw_line(Vector2(cx - 40.0, top + 52.0), Vector2(cx - 58.0, top + 118.0), body_col, 14.0)
	draw_line(Vector2(cx + 40.0, top + 52.0), Vector2(cx + 62.0, top + 112.0), body_col, 14.0)
	# testa
	draw_circle(Vector2(cx, top + 24.0), 24.0, body_col)
	draw_arc(Vector2(cx, top + 24.0), 24.0, 0.0, TAU, 28, col, 2.0)
	# visore
	draw_rect(Rect2(cx - 14.0, top + 18.0, 28.0, 8.0), col)

	# riquadro e targhetta
	var rect := Rect2(cx - 82.0, top - 12.0, 164.0, 236.0)
	_brackets(rect, BattleTheme.RD if is_lead else col, 5.0 if is_lead else 3.0, 24.0)
	var tag: String = "ID-%02d %s" % [index + 1, str(u["name"]).to_upper()]
	var tw: float = BattleTheme.display().get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var tab: PackedVector2Array = PackedVector2Array([
		Vector2(rect.position.x, rect.position.y - 28.0), Vector2(rect.position.x + tw + 26.0, rect.position.y - 28.0),
		Vector2(rect.position.x + tw + 14.0, rect.position.y - 2.0), Vector2(rect.position.x - 8.0, rect.position.y - 2.0)])
	draw_colored_polygon(tab, BattleTheme.RD if is_lead else col)
	draw_string(BattleTheme.display(), Vector2(rect.position.x + 6.0, rect.position.y - 10.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BattleTheme.BK)

	# stati
	var sx: float = rect.position.x
	var statuses: Dictionary = u["statuses"]
	for s in statuses:
		draw_string(BattleTheme.mono(), Vector2(sx, rect.end.y + 22.0), "[%s]" % BattleText.status_name(str(s)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BattleTheme.CY)
		sx += 92.0
	if int(u["shield"]) > 0:
		draw_arc(Vector2(cx, top + 100.0), 100.0, PI * 1.15, PI * 1.85, 24, Color(BattleTheme.WH, 0.65), 4.0)


func _brackets(r: Rect2, col: Color, width: float, l: float) -> void:
	var p: Vector2 = r.position
	var e: Vector2 = r.end
	draw_polyline(PackedVector2Array([Vector2(p.x, p.y + l), p, Vector2(p.x + l, p.y)]), col, width)
	draw_polyline(PackedVector2Array([Vector2(e.x - l, p.y), Vector2(e.x, p.y), Vector2(e.x, p.y + l)]), col, width)
	draw_polyline(PackedVector2Array([Vector2(e.x, e.y - l), e, Vector2(e.x - l, e.y)]), col, width)
	draw_polyline(PackedVector2Array([Vector2(p.x + l, e.y), Vector2(p.x, e.y), Vector2(p.x, e.y - l)]), col, width)
