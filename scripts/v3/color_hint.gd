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


# Secondo punto debole (boss gialli): "" se non c'e' o non vale per questo colore
static func second_line(attacker_color: String, boss: Dictionary) -> String:
	if BattleTypes.hits_weak2({"color": attacker_color}, boss):
		return "Punto debole di %s: +%d%% col %s" % [str(boss.get("name", "")), int(round((BattleTypes.WEAK2_MULT - 1.0) * 100.0)), attacker_color.to_upper()]
	return ""


# Riga per i comandi: vantaggio o svantaggio di chi e' di turno contro il boss ("" se neutro)
static func line(attacker_color: String, boss_color: String, boss_name: String) -> String:
	var h: Dictionary = eval(attacker_color, boss_color)
	match str(h["tipo"]):
		"efficace":
			return "Colore vincente: +%d%% su %s" % [_pct(float(h["mult"])), _nome(boss_name)]
		"debole":
			return "Colore debole: %d%% su %s" % [_pct(float(h["mult"])), _nome(boss_name)]
	return ""


# percentuale leggibile invece del moltiplicatore (x1.5 -> +50, x0.67 -> -33)
static func _pct(m: float) -> int:
	return int(round((m - 1.0) * 100.0))


# "DISTRIBUTORE" -> "Distributore": maiuscola iniziale, non tutto maiuscolo (regola 11)
static func _nome(n: String) -> String:
	var s: String = n.strip_edges().to_lower()
	return s.left(1).to_upper() + s.substr(1)


static func _fmt(m: float) -> String:
	var s: String = "%.2f" % m
	while s.ends_with("0") and s.contains("."):
		s = s.left(s.length() - 1)
	return s.trim_suffix(".")
