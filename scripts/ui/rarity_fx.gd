class_name RarityFx
extends RefCounted

# Animazione di ottenimento, diversa per ogni rarita' (comune, rara, epica, leggendaria):
#   0 comune        - ingresso semplice, nessun effetto
#   1 rara          - anello che si allarga e piccoli scintillii
#   2 epica         - doppio anello, raggi e lampo colorato
#   3 leggendaria   - raggi dorati rotanti, lampo bianco, didascalia e vibrazione
# Tutto si disegna da codice e si elimina da solo.

const COLORS: Array = [Color("#7cf0ff"), Color("#6bffb0"), Color("#b07bff"), Color("#ffd25f")]
const SOUNDS: Array = ["swap", "success", "cutin", "victory"]
const DURATION: Array = [0.0, 0.7, 1.0, 1.7]
const STAGGER: Array = [0.07, 0.12, 0.2, 0.34]     # pausa tra un oggetto e il successivo (elenchi lunghi)


static func color_of(rarity: int) -> Color:
	return COLORS[clampi(rarity, 0, COLORS.size() - 1)]


# Suona e mostra l'effetto della rarita' attorno a `center` (coordinate di `host`).
static func play(host: Control, center: Vector2, rarity: int) -> void:
	var tier: int = clampi(rarity, 0, 3)
	Snd.play(str(SOUNDS[tier]))
	if tier == 3:
		Snd.play("crit", 0.9)
	if tier == 0 or not host.is_inside_tree():
		return
	var col: Color = color_of(tier)
	match tier:
		1:
			ComicFx.flash(host, Color(col, 0.22), 0.18)
		2:
			ComicFx.flash(host, Color(col, 0.4), 0.22)
			ComicFx.speed_lines(host, center, Color(col, 0.9), 0.35)
		3:
			ComicFx.flash(host, Color(1, 1, 1, 0.85), 0.35)
			ComicFx.speed_lines(host, center, Color(col, 0.95), 0.5)
			ComicFx.caption(host, "LEGGENDARIA!", Vector2(380, 40), col, 0.9)
			shake(host, 10.0, 0.45)
	var b := Burst.new()
	b.tier = tier
	b.center = center
	host.add_child(b)


# Vibrazione dello schermo (spostamento rapido e ritorno).
static func shake(host: Control, strength: float, seconds: float) -> void:
	if not host.is_inside_tree():
		return
	var home: Vector2 = host.position
	var tw: Tween = host.create_tween()
	var steps: int = int(seconds / 0.04)
	for i in steps:
		var k: float = 1.0 - float(i) / float(steps)
		tw.tween_property(host, "position", home + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * k, 0.04)
	tw.tween_property(host, "position", home, 0.04)


# Entrata di una riga/oggetto in un elenco: piu' e' raro, piu' fa scena. Va chiamata subito dopo aver aggiunto il nodo.
static func reveal_row(host: Control, row: Control, rarity: int, delay: float) -> void:
	var tier: int = clampi(rarity, 0, 3)
	row.modulate.a = 0.0
	row.pivot_offset = Vector2(40.0, row.size.y * 0.5)
	if tier >= 2:
		row.scale = Vector2(1.18, 1.18)
	var tw: Tween = row.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		if not is_instance_valid(row) or not row.is_inside_tree():
			return
		if rarity >= 0:
			play(host, row.global_position - host.global_position + Vector2(60.0, row.size.y * 0.5), tier)
		var t2: Tween = row.create_tween()
		t2.set_parallel(true)
		t2.tween_property(row, "modulate:a", 1.0, 0.12 + 0.05 * float(tier))
		t2.tween_property(row, "scale", Vector2.ONE, 0.18 + 0.06 * float(tier)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if tier == 3:
			var pulse: Tween = row.create_tween()
			for i in 3:
				pulse.tween_property(row, "modulate", Color(1.7, 1.5, 0.9), 0.1)
				pulse.tween_property(row, "modulate", Color.WHITE, 0.14))


# Disegno dell'effetto: anelli, scintille, raggi.
class Burst extends Control:
	var tier: int = 1
	var center: Vector2 = Vector2(640, 360)
	var t: float = 0.0:
		set(v):
			t = v
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var tw: Tween = create_tween()
		tw.tween_property(self, "t", 1.0, float(RarityFx.DURATION[clampi(tier, 0, 3)]))
		tw.tween_callback(queue_free)

	func _draw() -> void:
		var col: Color = RarityFx.color_of(tier)
		var fade: float = 1.0 - t
		match tier:
			1:
				var r: float = 24.0 + t * 120.0
				draw_arc(center, r, 0.0, TAU, 40, Color(col, fade), 4.0, true)
				for i in 6:
					var a: float = TAU * float(i) / 6.0 + t * 2.0
					draw_circle(center + Vector2(cos(a), sin(a)) * r * 1.15, 4.0 * fade + 1.0, Color(col, fade))
			2:
				draw_arc(center, 30.0 + t * 200.0, 0.0, TAU, 48, Color(col, fade), 7.0, true)
				draw_arc(center, 20.0 + t * 130.0, 0.0, TAU, 48, Color(1, 1, 1, fade * 0.8), 3.0, true)
				for i in 16:
					var a2: float = TAU * float(i) / 16.0
					var d: Vector2 = Vector2(cos(a2), sin(a2))
					draw_line(center + d * (40.0 + t * 90.0), center + d * (70.0 + t * 220.0), Color(col, fade), 4.0, true)
			3:
				var alpha: float = sin(t * PI)
				var reach: float = 900.0
				for i in 14:
					var a3: float = TAU * float(i) / 14.0 + t * 1.4
					var p1: Vector2 = center + Vector2(cos(a3), sin(a3)) * reach
					var p2: Vector2 = center + Vector2(cos(a3 + 0.13), sin(a3 + 0.13)) * reach
					draw_colored_polygon(PackedVector2Array([center, p1, p2]), Color(col, 0.38 * alpha))
				draw_arc(center, 40.0 + t * 320.0, 0.0, TAU, 56, Color(col, fade), 10.0, true)
				draw_arc(center, 26.0 + t * 200.0, 0.0, TAU, 56, Color(1, 1, 1, fade), 4.0, true)
				for i in 10:
					var a4: float = TAU * float(i) / 10.0 + t * 0.7
					var rr: float = 60.0 + t * 380.0
					draw_circle(center + Vector2(cos(a4), sin(a4)) * rr, 7.0 * fade + 1.0, Color(1.0, 0.95, 0.6, fade))
