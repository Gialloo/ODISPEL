class_name DialogData
extends RefCounted

# Legge i testi da data/dialoghi.json (i testi stanno fuori dal codice).

static var _data: Dictionary = {}


static func all() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open("res://data/dialoghi.json", FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	return _data


static func lines(key: String) -> Array:
	var v: Variant = all().get(key, [])
	if v is Array:
		return v
	if v is Dictionary:
		return [v]
	return []


static func ult_line(char_id: String) -> String:
	var u: Variant = all().get("ultimate", {})
	return str((u as Dictionary).get(char_id, "")) if u is Dictionary else ""
