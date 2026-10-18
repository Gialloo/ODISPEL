class_name DialogData
extends RefCounted

# Legge i testi da data/dialoghi.json (i testi stanno fuori dal codice).
# Una scena e' {"riassunto": "...", "righe": [...]}, oppure direttamente la lista di righe.

static var _data: Dictionary = {}


static func all() -> Dictionary:
	if _data.is_empty():
		# testi comuni + testi dell'atto 1 (questi ultimi hanno la precedenza)
		for path in ["res://data/dialoghi.json", "res://data/dialoghi_atto1.json"]:
			var f := FileAccess.open(path, FileAccess.READ)
			if f != null:
				var parsed: Variant = JSON.parse_string(f.get_as_text())
				if parsed is Dictionary:
					_data.merge(parsed, true)
	return _data


# Battute della squadra in esplorazione per un'area
static func banter(area_key: String) -> Array:
	var c: Variant = all().get("chiacchiere", {})
	if c is Dictionary:
		var v: Variant = (c as Dictionary).get(area_key, [])
		return v if v is Array else []
	return []


static func lines(key: String) -> Array:
	var v: Variant = all().get(key, [])
	if v is Dictionary and (v as Dictionary).has("righe"):
		return (v as Dictionary)["righe"]
	if v is Array:
		return v
	if v is Dictionary:
		return [v]
	return []


static func recap(key: String) -> String:
	var v: Variant = all().get(key, {})
	return str((v as Dictionary).get("riassunto", "")) if v is Dictionary else ""


static func ult_line(char_id: String) -> String:
	var u: Variant = all().get("ultimate", {})
	return str((u as Dictionary).get(char_id, "")) if u is Dictionary else ""
