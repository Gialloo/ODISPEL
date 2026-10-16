extends SceneTree

# Catalogo icone ODISPEL: registro, asset, rendering, trasparenza, leggibilita' a 20-24 px.
#   godot --headless --path . -s res://tests/unit/test_icon_catalog.gd

var passed: int = 0
var failed: int = 0
const EXPECTED: Dictionary = {"A": 45, "B": 32, "C": 16, "D": 15, "E": 16, "F": 20, "G": 24, "H": 32, "I": 36, "L": 12, "M": 4}
const STATES: Array = ["implementata", "implementata parzialmente", "da verificare", "non implementata"]


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _render(svg: String, px: int) -> Image:
	var img := Image.new()
	if img.load_svg_from_string(svg, float(px) / 24.0) != OK:
		return null
	return img


func _run() -> void:
	var counts: Dictionary = {}
	var codes: Dictionary = {}
	var bad_render: Array = []
	var bad_alpha: Array = []
	var bad_small: Array = []
	var bad_file: Array = []
	var bad_meta: Array = []
	var hashes: Dictionary = {}
	var dup_img: Array = []
	for id in IconCatalog.ENTRIES.keys():
		var e: Dictionary = IconCatalog.ENTRIES[id]
		var letter: String = str(e["code"]).left(1)
		counts[letter] = int(counts.get(letter, 0)) + 1
		codes[str(e["code"])] = true
		for k in ["code", "name", "desc", "family", "folder", "asset", "variants", "use", "status", "fallback", "same_as"]:
			if not e.has(k) or (k != "variants" and k != "same_as" and str(e[k]) == ""):
				bad_meta.append("%s.%s" % [id, k])
		if not STATES.has(str(e["status"])):
			bad_meta.append(id + ".status")
		if not IconCatalog.SVG.has(id):
			bad_render.append(id + " (svg mancante)")
			continue
		var keys: Array = [id]
		for v in e["variants"]:
			keys.append("%s@%s" % [id, v])
			if not IconCatalog.SVG.has("%s@%s" % [id, v]):
				bad_render.append("%s@%s (svg mancante)" % [id, v])
		for kk in keys:
			if not IconCatalog.SVG.has(kk):
				continue
			var svg: String = str(IconCatalog.SVG[kk])
			var big: Image = _render(svg, 96)
			if big == null or big.is_empty():
				bad_render.append(kk)
				continue
			# trasparenza: gli angoli devono essere trasparenti (nessuno sfondo opaco)
			if big.get_pixel(0, 0).a > 0.05 or big.get_pixel(95, 95).a > 0.05 or big.get_pixel(95, 0).a > 0.05 or big.get_pixel(0, 95).a > 0.05:
				bad_alpha.append(kk)
			# leggibilita' a 20 px: abbastanza pixel visibili e non una macchia
			var small: Image = _render(svg, 20)
			var vis: int = 0
			for y in 20:
				for x in 20:
					if small.get_pixel(x, y).a > 0.3:
						vis += 1
			if vis < 20 or vis > 330:
				bad_small.append("%s(%d)" % [kk, vis])
		# stesso disegno per due ID diversi?
		var hsh: int = hash(str(IconCatalog.SVG[id]))
		if hashes.has(hsh):
			if str(e.get("same_as", "")) != str(hashes[hsh]) and str(e.get("same_as", "")) == "":
				dup_img.append("%s=%s" % [id, hashes[hsh]])
		hashes[hsh] = id
		# file individuale
		if str(e["folder"]) != "factions":
			if not FileAccess.file_exists("res://assets/ui/icons/%s/%s.svg" % [e["folder"], id]):
				bad_file.append(id)
		else:
			for v in ["light", "dark", "color", "compact", "large"]:
				if not FileAccess.file_exists("res://assets/ui/icons/factions/%s_%s.svg" % [str(id).replace("faction_", ""), v]):
					bad_file.append("%s_%s" % [id, v])
	for l in EXPECTED.keys():
		_check("famiglia %s: %d icone" % [l, int(EXPECTED[l])], int(counts.get(l, 0)) == int(EXPECTED[l]))
	_check("codici unici (%d)" % codes.size(), codes.size() == IconCatalog.ENTRIES.size())
	_check("campi del registro completi %s" % str(bad_meta.slice(0, 5)), bad_meta.is_empty())
	_check("tutti gli SVG si rasterizzano %s" % str(bad_render.slice(0, 5)), bad_render.is_empty())
	_check("nessun angolo opaco %s" % str(bad_alpha.slice(0, 5)), bad_alpha.is_empty())
	_check("leggibili a 20 px (pixel visibili) %s" % str(bad_small.slice(0, 8)), bad_small.is_empty())
	_check("file SVG presenti %s" % str(bad_file.slice(0, 5)), bad_file.is_empty())
	_check("doppioni solo se dichiarati same_as (stesso concetto) %s" % str(dup_img.slice(0, 5)), dup_img.is_empty())
	# i vecchi nomi si risolvono
	for k in ["sword", "bolt", "burst", "target", "cleanse", "libracorp", "rondini", "magabondi", "kairos", "hp", "shield"]:
		_check("alias %s" % k, GameIcon.resolve(k) != "")
	# componente: rendering e fallback
	var ic := GameIcon.new().setup("hp", Color.WHITE, 24.0)
	_check("texture hp", GameIcon.texture_for("hp", "", 24.0) != null)
	_check("variante hp critico", GameIcon.texture_for("hp", "critico", 24.0) != null)
	_check("stemma compatto e grande", GameIcon.texture_for("faction_libracorp", "", 24.0) != null and GameIcon.texture_for("faction_libracorp", "", 64.0) != null)
	_check("ID inesistente: nessuna texture", GameIcon.texture_for("non_esiste", "", 24.0) == null)
	_check("ID inesistente: nessun alias", GameIcon.resolve("non_esiste") == "")
	ic.free()
	var n_future: int = 0
	for id in IconCatalog.ENTRIES.keys():
		if str(IconCatalog.ENTRIES[id]["status"]) in ["non implementata", "da verificare"]:
			n_future += 1
	_check("icone predisposte (non implementate / da verificare) documentate: %d" % n_future, n_future > 0)
	print("---")
	print("PASS: %d  FAIL: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)
