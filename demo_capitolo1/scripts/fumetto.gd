class_name Fumetto
## Pezzi grafici dello stile delle tavole dell'autore (12/11/2026), «stile Persona 5»:
## rosso, nero e bianco, retino, cornici bianche a fulmine, nomi a lettere ritagliate,
## ritratti con contorno da adesivo. Tutto in codice, niente immagini nuove.

const ROSSO := Color("#ff1e3c")
const NERO := Color("#08060a")
const BIANCO := Color("#f4f1ea")

static var _sh_retino: Shader = preload("res://shaders/retino.gdshader")
static var _sh_ritratto: Shader = preload("res://shaders/ritratto.gdshader")
static var font_ritagli_a: Font = preload("res://assets/fonts/SairaStencilOne-Regular.ttf")
static var font_ritagli_b: Font = preload("res://assets/fonts/ArchivoBlack-Regular.ttf")

## Contorno a fulmine attorno a un rettangolo: punte irregolari ma fisse (stesso seme, stessa forma).
static func fulmine(r: Rect2, passo: float, amp: float, seme: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var angoli := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var c := r.get_center()
	var pts := PackedVector2Array()
	for i in 4:
		var a: Vector2 = angoli[i]
		var b: Vector2 = angoli[(i + 1) % 4]
		var n := maxi(2, int(a.distance_to(b) / passo))
		for k in n:
			var p := a.lerp(b, float(k) / n)
			var fuori := (p - c).normalized()
			var spinta := rng.randf_range(0.0, amp) if k % 2 == 0 else rng.randf_range(-amp * 0.25, amp * 0.2)
			pts.append(p + fuori * spinta)
	return pts

## Sposta tutti i punti (per le ombre piene).
static func sposta(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var o := PackedVector2Array()
	for p in pts:
		o.append(p + d)
	return o

## Nome a lettere ritagliate, come un biglietto fatto coi giornali.
static func ritagli(testo: String, col: Color, alt: float, seme := 0) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(testo) + seme
	var x := 0.0
	for i in testo.length():
		var ch := testo[i]
		if ch == " ":
			x += alt * 0.35
			continue
		var font: Font = font_ritagli_a if rng.randf() < 0.5 else font_ritagli_b
		var size := int(alt * rng.randf_range(0.82, 1.12))
		var stile := (i + rng.randi_range(0, 1)) % 3
		var fondo: Color = [NERO, col, BIANCO][stile]
		var inchiostro: Color = [BIANCO, NERO, NERO][stile]
		if stile == 1 and col.get_luminance() < 0.42:
			inchiostro = BIANCO
		var misura := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var pad := Vector2(size * 0.14, size * 0.02)
		var r := ColorRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.color = fondo
		r.size = misura + pad * 2.0
		r.position = Vector2(x, rng.randf_range(-alt * 0.1, alt * 0.1))
		r.pivot_offset = r.size * 0.5
		r.rotation = deg_to_rad(rng.randf_range(-10.0, 10.0))
		if stile != 0:
			var ombra := ColorRect.new()
			ombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ombra.color = NERO
			ombra.size = r.size
			ombra.position = r.position + Vector2(4, 4)
			ombra.pivot_offset = r.pivot_offset
			ombra.rotation = r.rotation
			c.add_child(ombra)
		var l := Label.new()
		l.text = ch
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", inchiostro)
		l.position = pad
		r.add_child(l)
		c.add_child(r)
		x += r.size.x - size * 0.05
	c.size = Vector2(x, alt * 1.25)
	return c

static func retino(colore: Color, fondo: Color, cella: float, inizio: Vector2, fine: Vector2, r_max := 0.48, r_min := 0.04) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _sh_retino
	m.set_shader_parameter("colore", colore)
	m.set_shader_parameter("fondo", fondo)
	m.set_shader_parameter("cella", cella)
	m.set_shader_parameter("inizio", inizio)
	m.set_shader_parameter("fine", fine)
	m.set_shader_parameter("r_max", r_max)
	m.set_shader_parameter("r_min", r_min)
	return m

static func ritratto(contorno: Color, spessore := 9.0, duotono := false, scuro := NERO, chiaro := ROSSO) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _sh_ritratto
	m.set_shader_parameter("contorno", contorno)
	m.set_shader_parameter("spessore", spessore)
	m.set_shader_parameter("duotono", 1.0 if duotono else 0.0)
	m.set_shader_parameter("scuro", scuro)
	m.set_shader_parameter("chiaro", chiaro)
	return m

## Poligono col ritratto «ritagliato» dentro: la texture è disegnata come se occupasse
## il rettangolo dove (in coordinate dello schermo), ma si vede solo dentro forma.
static func ritaglio(forma: PackedVector2Array, tex: Texture2D, dove: Rect2, flip := false) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = forma
	p.texture = tex
	var ts := Vector2(tex.get_width(), tex.get_height())
	var uv := PackedVector2Array()
	for q in forma:
		var u := (q - dove.position) / dove.size
		if flip:
			u.x = 1.0 - u.x
		uv.append(u * ts)
	p.uv = uv
	return p
