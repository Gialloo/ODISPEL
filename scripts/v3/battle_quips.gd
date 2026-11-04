class_name BattleQuips
extends RefCounted

# Battute a fumetto della squadra in battaglia (alla Persona 5): critici, nemico K.O., compagno a terra, chi copre, chi si
# rialza. Qui si sceglie COSA dire e QUANDO (frequenza, pause, niente ripetizioni); battle3d.gd le mostra nel fumetto.
# Testi in data/dialoghi_atto1.json, sezione "battaglia" (si generano da tools/gen_dialoghi.py: non si toccano a mano).
# Perche' poche: se parlano a ogni colpo diventano rumore e coprono la scena (regola 11, leggibilita').

const CHANCE: Dictionary = {"critico": 0.45, "ko_nemico": 0.7, "compagno_ko": 1.0, "copre": 0.55, "rialzato": 1.0}
const GAP_MSEC: int = 5000          # pausa minima tra due battute (chi cade e chi si rialza la saltano: contano di piu')
const URGENT: Array = ["compagno_ko", "rialzato"]

var _data: Dictionary = {}
var _used: Dictionary = {}          # voce gia' detta in questa battaglia -> true
var _next_ok: int = 0
var rng := RandomNumberGenerator.new()
var now_msec: int = -1              # per le prove: se >= 0 si usa questo al posto dell'orologio


func _init(data: Dictionary = {}) -> void:
	_data = data if not data.is_empty() else (DialogData.all().get("battaglia", {}) as Dictionary)
	rng.randomize()


func _now() -> int:
	return now_msec if now_msec >= 0 else Time.get_ticks_msec()


# kind: "critico" | "ko_nemico" | "copre" | "rialzato" -> chi = chi agisce; other = l'altro coinvolto (chi viene coperto)
# kind: "compagno_ko" -> chi = chi e' caduto; parla uno a caso tra 'alive'
# alive: id dei personaggi della squadra in piedi (per le risposte). Torna le righe [{chi, testo}] o [] se si tace.
func pick(kind: String, chi: String, alive: Array, other: String = "") -> Array:
	var urgent: bool = URGENT.has(kind)
	if not urgent and _now() < _next_ok:
		return []
	if rng.randf() > float(CHANCE.get(kind, 0.0)):
		return []
	var pool: Array = []
	var group: Dictionary = _data.get(kind, {})
	if kind == "compagno_ko":
		for sp in alive:
			if str(sp) == chi:
				continue
			for entry in (group.get(str(sp), {}) as Dictionary).get(chi, []):
				pool.append([kind + ":" + str(sp) + ">" + chi, entry])
	else:
		var lst: Array = group.get(chi, [])
		for i in lst.size():
			pool.append([kind + ":" + chi + ":" + str(i), lst[i]])
	var fresh: Array = []
	for p in pool:
		if _used.has(p[0]):
			continue
		var righe: Array = _righe(p[1], other)
		if righe.is_empty():
			continue
		# risposta solo se chi risponde e' in piedi (la prima riga e' di chi agisce, o di chi reagisce subito a lui)
		var ok: bool = true
		for r in righe:
			var c: String = str(r.get("chi", ""))
			if c != chi and not alive.has(c):
				ok = false
		if ok:
			fresh.append([p[0], righe])
	if fresh.is_empty():
		return []
	var got: Array = fresh[rng.randi_range(0, fresh.size() - 1)]
	_used[got[0]] = true
	_next_ok = _now() + GAP_MSEC
	return got[1]


static func _righe(entry: Variant, other: String) -> Array:
	if entry is Array:
		return entry
	if entry is Dictionary:
		var d: Dictionary = entry
		if d.has("se") and str(d["se"]) != other:
			return []
		return d.get("righe", [])
	return []


# Quanto resta a schermo una riga: si legge con calma anche sul telefono
static func hold(text: String) -> float:
	return clampf(1.1 + text.length() * 0.045, 1.4, 3.2)
