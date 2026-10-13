class_name UiTex
extends RefCounted

# Texture leggere generate da codice (niente file, niente peso nell'APK): righe oblique chiare che
# danno "grana" a pannelli e pulsanti. Si ripetono (texture_repeat) e costano un solo poligono.

const TILE: float = 16.0

static var _hatch: ImageTexture = null
static var _dots: ImageTexture = null


# Righe oblique larghe due pixel, bianche: il colore si decide quando si disegna.
static func hatch() -> ImageTexture:
	if _hatch == null:
		var n: int = int(TILE)
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d: int = (x + y) % n
				var a: float = 1.0 if d < 2 else (0.45 if d == 2 or d == n - 1 else 0.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_hatch = ImageTexture.create_from_image(img)
	return _hatch


# Puntini regolari (retino leggero).
static func dots() -> ImageTexture:
	if _dots == null:
		var n: int = int(TILE)
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var dx: float = float(x) - float(n) * 0.5 + 0.5
				var dy: float = float(y) - float(n) * 0.5 + 0.5
				img.set_pixel(x, y, Color(1, 1, 1, clampf(1.6 - sqrt(dx * dx + dy * dy) * 0.7, 0.0, 1.0)))
		_dots = ImageTexture.create_from_image(img)
	return _dots


# Coordinate texture di un poligono, in modo che le righe non cambino passo con la dimensione.
static func uvs_for(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p / TILE)
	return out
