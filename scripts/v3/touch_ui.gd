class_name TouchUi
extends RefCounted

# Modalita' touch: sul telefono sempre; sul PC solo se forzata (prove e screenshot).
static var force: bool = false


static func active() -> bool:
	return force or OS.has_feature("mobile")
