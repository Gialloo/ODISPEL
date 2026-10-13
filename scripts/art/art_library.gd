class_name ArtLibrary
extends RefCounted

# Archivio delle grafiche. Il gioco non conosce i file: chiede "il ritratto
# arrabbiato di Kira" e ArtLibrary lo cerca per nome nelle cartelle `art/`.
# Se il file non c'e' si usa il segnaposto disegnato dal codice. Per cambiare una
# grafica basta quindi mettere un PNG con il nome giusto: niente codice.
#
# Cartelle esaminate, in quest'ordine (la prima che ha il file vince):
#   1. `art/` accanto all'eseguibile            (per chi gioca/prova il gioco esportato)
#   2. `user://art/`                            (cartella dati del gioco, aprila dalle Impostazioni)
#   3. `art/` nella cartella del progetto       (durante lo sviluppo)
#   4. `res://art/`                             (dentro il pacchetto esportato)
# Tutte le immagini sono PNG con trasparenza. Vedi docs/GUIDA_ARTE.md.

const EXPRESSIONS: Array = ["neutral", "happy", "angry", "sad", "surprised", "hurt"]
const BG_LAYERS: int = 4

# Lato massimo di una grafica in memoria. Il gioco e' 1280x720: oltre i 2048 punti non si vede
# nulla di piu', ma una PNG molto grande occuperebbe decine di MB di memoria video su un telefono.
const MAX_SIZE: int = 2048

static var extra_roots: Array = []       # cartelle in piu' (usate dai test), cercate per prime
static var _asked: Dictionary = {}       # percorsi gia' richiesti in secondo piano
static var _cache: Dictionary = {}       # percorso relativo -> Texture2D oppure null


# ---------- Cartelle ----------

static func roots() -> Array:
	var out: Array = extra_roots.duplicate()
	out.append(OS.get_executable_path().get_base_dir().path_join("art"))
	out.append(ProjectSettings.globalize_path("user://art"))
	out.append(ProjectSettings.globalize_path("res://art"))
	return out


static func user_folder() -> String:
	return ProjectSettings.globalize_path("user://art")


# ---------- Ricerca ----------

# Texture per percorso relativo ("characters/kira/neutral.png"), o null.
static func texture(rel: String) -> Texture2D:
	if _cache.has(rel):
		return _cache[rel]
	var found: Texture2D = null
	for root in roots():
		var path: String = str(root).path_join(rel)
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null and not img.is_empty():
				found = ImageTexture.create_from_image(_fit(img))
				break
	if found == null and ResourceLoader.exists("res://art/" + rel):
		found = load("res://art/" + rel) as Texture2D
	_cache[rel] = found
	return found


# Comincia a caricare in secondo piano le grafiche che serviranno tra poco (squadra, boss): quando poi
# il gioco le chiede, sono gia' pronte. Non cambia nulla se manca il file o se c'e' una versione esterna.
static func prefetch(rels: Array) -> void:
	for rel in rels:
		var r: String = str(rel)
		if _cache.has(r) or _asked.has(r):
			continue
		_asked[r] = true
		var res: String = "res://art/" + r
		if ResourceLoader.exists(res):
			ResourceLoader.load_threaded_request(res)


static func prefetch_team(char_ids: Array) -> void:
	var rels: Array = []
	for id in char_ids:
		for f in ["icon", "neutral", "battle", "cutin", "splash"]:
			rels.append("characters/%s/%s.png" % [id, f])
	prefetch(rels)


static func prefetch_boss(boss_id: String) -> void:
	prefetch(["bosses/%s/battle.png" % boss_id, "bosses/%s/hurt.png" % boss_id, "bosses/%s/portrait.png" % boss_id])


# Riduce (mantenendo le proporzioni) un'immagine piu' grande di MAX_SIZE.
static func _fit(img: Image) -> Image:
	var longest: int = maxi(img.get_width(), img.get_height())
	if longest > MAX_SIZE:
		var k: float = float(MAX_SIZE) / float(longest)
		img.resize(maxi(1, int(round(img.get_width() * k))), maxi(1, int(round(img.get_height() * k))), Image.INTERPOLATE_LANCZOS)
	return img


# Il file c'e'? (senza caricarlo in memoria: serve al rapporto delle grafiche mancanti)
static func has(rel: String) -> bool:
	if _cache.has(rel):
		return _cache[rel] != null
	for root in roots():
		if FileAccess.file_exists(str(root).path_join(rel)):
			return true
	return ResourceLoader.exists("res://art/" + rel)


# La prima che esiste tra piu' percorsi.
static func first(rels: Array) -> Texture2D:
	for rel in rels:
		var t: Texture2D = texture(str(rel))
		if t != null:
			return t
	return null


# Svuota la memoria: le immagini si rileggono dal disco (utile mentre si disegna).
static func refresh() -> void:
	_cache.clear()


# ---------- Richieste per tipo ----------

# Ritratto con espressione (dialoghi). Se manca, prova "neutral".
static func portrait(char_id: String, expression: String = "neutral") -> Texture2D:
	return first(["characters/%s/%s.png" % [char_id, expression], "characters/%s/neutral.png" % char_id])


# Illustrazione grande (scheda operatore, reclutamento).
static func splash(char_id: String) -> Texture2D:
	return first(["characters/%s/splash.png" % char_id, "characters/%s/neutral.png" % char_id])


# Immagine per la sequenza dell'ultimate.
static func cutin(char_id: String) -> Texture2D:
	return first(["characters/%s/cutin.png" % char_id, "characters/%s/splash.png" % char_id, "characters/%s/neutral.png" % char_id])


# Icona quadrata (liste, lobby).
static func icon(char_id: String) -> Texture2D:
	return first(["characters/%s/icon.png" % char_id])


# Figura intera nel combattimento.
static func battle_sprite(char_id: String) -> Texture2D:
	return first(["characters/%s/battle.png" % char_id])


# Boss: "battle" (in campo), "hurt" (quando e' colpito), "portrait" (dialoghi).
static func boss_image(boss_id: String, kind: String) -> Texture2D:
	if kind == "portrait":
		return first(["bosses/%s/portrait.png" % boss_id, "bosses/%s/battle.png" % boss_id])
	return first(["bosses/%s/%s.png" % [boss_id, kind]])


# Strati dello sfondo di battaglia, dal piu' lontano. Quello del boss ha la precedenza.
static func background_layers(boss_id: String) -> Array:
	var out: Array = []
	for i in range(1, BG_LAYERS + 1):
		var t: Texture2D = first(["backgrounds/%s/layer_%d.png" % [boss_id, i], "backgrounds/battle/layer_%d.png" % i])
		if t != null:
			out.append(t)
	return out


# Sfondo di una scena di dialogo (@bg nome) o del hub ("hub").
static func background(bg_name: String) -> Texture2D:
	return first(["backgrounds/%s.png" % bg_name, "backgrounds/dialogue/%s.png" % bg_name])


# ---------- Catalogo e rapporto ----------

# Tutti i file che il gioco sa usare: {path, group, note}.
static func slots() -> Array:
	var out: Array = []
	for id in BattleContent.CHARACTERS:
		var def: Dictionary = BattleContent.CHARACTERS[id]
		for e in EXPRESSIONS:
			out.append({"path": "characters/%s/%s.png" % [id, e], "group": str(def["name"]), "note": "ritratto " + e})
		out.append({"path": "characters/%s/splash.png" % id, "group": str(def["name"]), "note": "illustrazione grande"})
		out.append({"path": "characters/%s/cutin.png" % id, "group": str(def["name"]), "note": "sequenza ultimate"})
		out.append({"path": "characters/%s/icon.png" % id, "group": str(def["name"]), "note": "icona quadrata"})
		out.append({"path": "characters/%s/battle.png" % id, "group": str(def["name"]), "note": "figura in battaglia"})
	for id in BattleContent.BOSS_ORDER:
		var bname: String = str(BattleContent.BOSSES[id]["name"])
		out.append({"path": "bosses/%s/battle.png" % id, "group": bname, "note": "boss in battaglia"})
		out.append({"path": "bosses/%s/hurt.png" % id, "group": bname, "note": "boss colpito (facoltativa)"})
		out.append({"path": "bosses/%s/portrait.png" % id, "group": bname, "note": "ritratto nei dialoghi"})
	for i in range(1, BG_LAYERS + 1):
		out.append({"path": "backgrounds/battle/layer_%d.png" % i, "group": "Sfondo battaglia", "note": "strato %d (1 = piu' lontano)" % i})
	out.append({"path": "backgrounds/hub.png", "group": "Sfondi", "note": "sfondo dell'hub"})
	out.append({"path": "logo.png", "group": "Sfondi", "note": "logo del gioco (hub)"})
	return out


# {found: [path], missing: [path], total: n}
static func report() -> Dictionary:
	var found: Array = []
	var missing: Array = []
	for s in slots():
		if has(str(s["path"])):
			found.append(str(s["path"]))
		else:
			missing.append(str(s["path"]))
	return {"found": found, "missing": missing, "total": found.size() + missing.size()}


# Crea in user://art le cartelle vuote con i nomi giusti, cosi' si sa dove mettere i file.
static func ensure_folders() -> String:
	var base: String = user_folder()
	for id in BattleContent.CHARACTERS:
		DirAccess.make_dir_recursive_absolute(base.path_join("characters/%s" % id))
	for id in BattleContent.BOSS_ORDER:
		DirAccess.make_dir_recursive_absolute(base.path_join("bosses/%s" % id))
	DirAccess.make_dir_recursive_absolute(base.path_join("backgrounds/battle"))
	DirAccess.make_dir_recursive_absolute(base.path_join("backgrounds/dialogue"))
	var guide: String = "res://docs/GUIDA_ARTE.md"
	if FileAccess.file_exists(guide):
		var f := FileAccess.open(base.path_join("LEGGIMI.md"), FileAccess.WRITE)
		if f != null:
			f.store_string(FileAccess.get_file_as_string(guide))
	return base


static func open_folder() -> void:
	OS.shell_open(ensure_folders())
