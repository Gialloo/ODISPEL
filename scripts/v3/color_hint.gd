class_name ColorHint
extends RefCounted

# Dice al giocatore se un colpo e' EFFICACE o DEBOLE, dai colori di chi colpisce e di chi subisce.
# Funzione pura (nessun nodo): la battaglia la chiama sul numero del danno e sulla riga dei comandi.
# Ritorna {"mult": float, "testo": String, "tipo": String}; tipo = "efficace" | "debole" | "neutro".

static func eval(attacker_color: String, defender_color: String) -> Dictionary:
	var m: float = BattleTypes.color_multiplier(attacker_color, defender_color)
	if m > 1.0:
		return {"mult": m, "testo": "EFFICACE", "tipo": "efficace"}
	if m < 1.0:
		return {"mult": m, "testo": "DEBOLE", "tipo": "debole"}
	return {"mult": m, "testo": "", "tipo": "neutro"}


# Riga per i comandi: vantaggio o svantaggio di chi e' di turno contro il boss ("" se neutro)
static func line(attacker_color: String, boss_color: String, boss_name: String) -> String:
	var h: Dictionary = eval(attacker_color, boss_color)
	match str(h["tipo"]):
		"efficace":
			return "VANTAGGIO ×%s sul %s" % [_fmt(float(h["mult"])), boss_name]
		"debole":
			return "SVANTAGGIO ×%s sul %s" % [_fmt(float(h["mult"])), boss_name]
	return ""


static func _fmt(m: float) -> String:
	var s: String = "%.2f" % m
	while s.ends_with("0") and s.contains("."):
		s = s.left(s.length() - 1)
	return s.trim_suffix(".")
