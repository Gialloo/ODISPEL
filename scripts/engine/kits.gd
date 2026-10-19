class_name Kits
extends RefCounted

# KIT DEI QUATTRO (V3). Ogni protagonista ha un'Abilita', una Ultimate e un tratto suoi, presi dal suo archetipo,
# dal suo oggetto e dalla sua fazione (odispel/v3/KIT_PERSONAGGI.md). Le mosse stanno in Signatures.MOVES con il campo
# "kit"; qui ci sono solo gli effetti che il motore generico non sa fare. Il resolver chiama:
#   before_act  prima del colpo (moltiplicatori, critico sicuro, riposo di Nox)
#   after_act   dopo l'azione (copertura, moneta, energia, rianimazione...)
#   coverer / boss_resolved / nullify  nel turno del boss
#   after_events  alla fine di ogni passo (Hype di Rio)
#
# Regola del gruppo: Lance organizza, Saul sfrutta, Rio spettacolarizza, Nox evita il lavoro inutile.

const LANCE: String = "ferri"
const SAUL: String = "saul"
const RIO: String = "zecca"
const NOX: String = "nox"

const COVER_GUARD_TURNS: int = 1        # Copertura senza nessuno da coprire: Lance si mette in guardia
const ARM_BALANCE: int = 8              # Braccio della Legge: equilibrio tolto (la barra e' ~20 con quattro in squadra)
const PARRY_ARM_MULT: float = 1.4       # Al secondo: contrattacco della parata perfetta di Lance (invece di 0.9)
const PARRY_ARM_BALANCE: int = 3
const SHADOW_MULT: float = 1.25         # Fuori dalla luce: Saul colpisce di piu' se il boss guarda un altro
const COIN_HEADS_MULT: float = 1.2      # Testa: critico sicuro e un po' di danno in piu'
const COIN_TAILS_ENERGY: int = 2        # Croce: energia passata al compagno che ne ha meno
const HEIST_NO_SHIELD_MULT: float = 1.4 # Il colpo grosso senza scudi da rubare: si prende tutto in danno
const HYPE_MAX: int = 100
const FINALE_BASE: float = 0.5          # Gran finale: fattore per colpo a Hype 0 ...
const FINALE_PER_HYPE: float = 1.5      # ... e quanto aggiunge l'Hype pieno
const MASK_AGGRO_PM: int = 350          # con la maschera Rio attira i colpi singoli del boss (35%)
const VIGIL_MULT: float = 1.35          # Veglia: Nox agisce per ultima nel round
const COFFEE_REST_ABOVE: float = 0.7    # Pausa caffe': se tutti stanno sopra il 70% Nox si riposa
const ANSWER_HP: float = 0.4            # Rispondo io: un compagno KO torna con il 40% dei PV

const HYPE_GAIN: Dictionary = {
	"perfect": 15, "good": 8, "break": 20, "rhythm": 4, "synergy": 5, "crit": 4, "rio_hit": 10, "frame": 10,
}

const TRAITS: Dictionary = {
	LANCE: {"name": "Al secondo", "desc": "Sui colpi diretti a lui la Guardia a tempo è più larga; la sua parata perfetta toglie equilibrio."},
	SAUL: {"name": "Fuori dalla luce", "desc": "Colpisce più forte quando il nemico ha di mira qualcun altro."},
	RIO: {"name": "In diretta", "desc": "Tutto ciò che è spettacolare riempie l'Hype. Con la maschera il nemico lo prende di mira più spesso."},
	NOX: {"name": "Veglia", "desc": "Se agisce per ultima nel round fa di più e spende meno."},
}


static func trait_of(u: Dictionary) -> String:
	return str(TRAITS.get(str(u.get("char", "")), {}).get("name", ""))


static func is_char(u: Dictionary, char_id: String) -> bool:
	return str(u.get("char", "")) == char_id


static func unit_of_char(state: Dictionary, char_id: String) -> Dictionary:
	for p in state["players"]:
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if is_char(u, char_id) and BattleState.is_alive(u):
			return u
	return {}


# Il bersaglio annunciato del boss e' questa unita'? (i colpi a tutti contano per tutti)
static func targeted(state: Dictionary, u: Dictionary) -> bool:
	var tele: Dictionary = state.get("telegraph", {})
	var mv: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	if str(mv.get("target", "one")) == "all":
		return true
	var tu: Dictionary = BattleState.active_unit(state, str(tele.get("target", "")))
	return not tu.is_empty() and str(tu["id"]) == str(u["id"])


static func _single_target_ally(state: Dictionary, actor: Dictionary) -> Dictionary:
	var tele: Dictionary = state.get("telegraph", {})
	var mv: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	if mv.is_empty() or str(mv.get("target", "one")) == "all" or float(mv.get("mult", 0.0)) <= 0.0:
		return {}
	var tu: Dictionary = BattleState.active_unit(state, str(tele.get("target", "")))
	if tu.is_empty() or str(tu["id"]) == str(actor["id"]) or not BattleState.is_alive(tu):
		return {}
	return tu


# Nox e' l'ultima del round: tutti gli altri compagni vivi hanno gia' agito.
static func acts_last(state: Dictionary, actor: Dictionary) -> bool:
	var acts: Dictionary = state.get("acts", {})
	for p in BattleState.alive_players(state):
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if str(u["id"]) != str(actor["id"]) and BattleState.is_alive(u) and not acts.has(str(u["id"])):
			return false
	return true


static func add_hype(u: Dictionary, n: int, events: Array, why: String) -> void:
	if n <= 0 or u.is_empty():
		return
	var before: int = int(u.get("hype", 0))
	u["hype"] = mini(HYPE_MAX, before + n)
	if int(u["hype"]) != before:
		events.append({"t": "hype", "unit": u["id"], "amount": int(u["hype"]) - before, "hype": int(u["hype"]), "why": why})


# ---------------------------------------------------------------- azione di un compagno

# Ritorna {"mult": moltiplicatore, "crit_pm": critico in piu', "skip": l'azione non colpisce (riposo)}.
static func before_act(state: Dictionary, actor: Dictionary, move_id: String, move: Dictionary, events: Array) -> Dictionary:
	var out: Dictionary = {"mult": 1.0, "crit_pm": 0, "skip": false}
	var kit: String = str(move.get("kit", ""))
	var hits_enemy: bool = move.has("mult") and str(move.get("target", "")) == "enemy"
	# Fuori dalla luce: Saul colpisce meglio quando il boss guarda un altro
	if is_char(actor, SAUL) and hits_enemy and not targeted(state, actor):
		out["mult"] = float(out["mult"]) * SHADOW_MULT
		events.append({"t": "kit_trait", "unit": actor["id"], "trait": "luce"})
	match kit:
		"coin":
			var rng: RNGState = BattleResolver._load_rng(state)
			var heads: bool = rng.random_int(0, 1) == 1
			BattleResolver._save_rng(state, rng)
			actor["coin"] = "testa" if heads else "croce"
			if heads:
				out["mult"] = float(out["mult"]) * COIN_HEADS_MULT
				out["crit_pm"] = 1000
			events.append({"t": "coin", "unit": actor["id"], "side": actor["coin"]})
		"heist":
			var boss: Dictionary = BattleState.boss(state)
			var loot: int = int(boss.get("shield", 0))
			if loot > 0:
				boss["shield"] = 0
				var mates: Array = []
				for p in BattleState.alive_players(state):
					mates.append(BattleState.active_unit(state, str(p["id"])))
				var share: int = maxi(1, int(ceil(float(loot) / float(maxi(1, mates.size())))))
				events.append({"t": "heist", "unit": actor["id"], "amount": loot})
				for m in mates:
					m["shield"] = int(m["shield"]) + share
					events.append({"t": "shield", "src": actor["id"], "dst": m["id"], "amount": share})
			else:
				out["mult"] = float(out["mult"]) * HEIST_NO_SHIELD_MULT
				events.append({"t": "heist", "unit": actor["id"], "amount": 0})
		"finale":
			var hype: int = int(actor.get("hype", 0))
			out["mult"] = float(out["mult"]) * (FINALE_BASE + FINALE_PER_HYPE * float(hype) / float(HYPE_MAX))
			events.append({"t": "finale", "unit": actor["id"], "hype": hype})
			actor["hype"] = 0
		"coffee":
			var worst: float = 2.0
			for p in BattleState.alive_players(state):
				var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
				worst = minf(worst, float(u["hp"]) / maxf(1.0, float(u["max_hp"])))
			if worst > COFFEE_REST_ABOVE:
				# nessuno ne ha bisogno: Nox si riposa (energia restituita) e il prossimo round agisce due volte
				out["skip"] = true
				actor["energy"] = mini(BattleTypes.MAX_ENERGY, int(actor["energy"]) + int(move.get("cost", 0)))
				actor["rested"] = true
				events.append({"t": "rest", "unit": actor["id"]})
	# Veglia: Nox per ultima nel round (non quando si riposa: non sta facendo niente)
	if is_char(actor, NOX) and move_id != BattleTypes.ACTION_GUARD and not bool(out["skip"]) and acts_last(state, actor):
		out["mult"] = float(out["mult"]) * VIGIL_MULT
		if str(move.get("kind", "")) == "skill" and int(move.get("cost", 0)) > 0:
			actor["energy"] = mini(BattleTypes.MAX_ENERGY, int(actor["energy"]) + 1)     # costa un'energia in meno
		events.append({"t": "kit_trait", "unit": actor["id"], "trait": "veglia"})
	return out


static func after_act(state: Dictionary, actor: Dictionary, move_id: String, move: Dictionary, target_pid: String, events: Array) -> void:
	match str(move.get("kit", "")):
		"cover":
			var ally: Dictionary = _single_target_ally(state, actor)
			if ally.is_empty():
				BattleResolver._add_status(actor, "guard", COVER_GUARD_TURNS, events)
			else:
				actor["cover"] = str(ally["id"])
				events.append({"t": "cover", "unit": actor["id"], "who": ally["id"]})
		"arm":
			var boss: Dictionary = BattleState.boss(state)
			if BattleState.is_alive(boss):
				BattleResolver._drain_balance(boss, ARM_BALANCE, actor, events)
		"coin":
			if str(actor.get("coin", "")) == "croce":
				var best: Dictionary = {}
				for p in BattleState.alive_players(state):
					var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
					if str(u["id"]) != str(actor["id"]) and (best.is_empty() or int(u["energy"]) < int(best["energy"])):
						best = u
				if not best.is_empty():
					best["energy"] = mini(BattleTypes.MAX_ENERGY, int(best["energy"]) + COIN_TAILS_ENERGY)
					events.append({"t": "energy_gift", "unit": actor["id"], "dst": best["id"], "amount": COIN_TAILS_ENERGY})
			actor.erase("coin")
		"frame":
			add_hype(actor, int(HYPE_GAIN["frame"]), events, "frame")
		"coffee":
			# (col riposo l'azione si ferma prima e after_act non arriva qui)
			var t: Dictionary = BattleState.active_unit(state, target_pid)
			if t.is_empty() or not BattleState.is_alive(t):
				t = actor
			t["energy"] = mini(BattleTypes.MAX_ENERGY, int(t["energy"]) + 1)
			events.append({"t": "energy_gift", "unit": actor["id"], "dst": t["id"], "amount": 1})
		"answer":
			var fallen: Dictionary = {}
			for p in state["players"]:
				var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
				if not u.is_empty() and not BattleState.is_alive(u):
					fallen = u
					break
			if not fallen.is_empty():
				fallen["hp"] = maxi(1, int(round(float(fallen["max_hp"]) * ANSWER_HP)))
				fallen["statuses"] = {}
				events.append({"t": "revive", "unit": actor["id"], "who": fallen["id"], "hp": int(fallen["hp"])})
			else:
				state["nullify"] = true
				events.append({"t": "answer", "unit": actor["id"]})


# ---------------------------------------------------------------- turno del boss

# Chi copre il bersaglio del colpo singolo (Copertura di Lance), o {}.
static func coverer(state: Dictionary, target: Dictionary) -> Dictionary:
	for p in BattleState.alive_players(state):
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if BattleState.is_alive(u) and str(u.get("cover", "")) == str(target.get("id", "")) and str(u["id"]) != str(target.get("id", "")):
			return u
	return {}


# Rispondo io: il prossimo colpo del boss non fa niente. Ritorna vero se l'ha annullato.
static func nullify(state: Dictionary, events: Array) -> bool:
	if not bool(state.get("nullify", false)):
		return false
	state.erase("nullify")
	events.append({"t": "nullified"})
	return true


# Dopo il colpo annunciato: la copertura vale per un solo colpo.
static func boss_resolved(state: Dictionary) -> void:
	for p in state["players"]:
		for uid in p["team"]:
			BattleState.unit(state, uid).erase("cover")


# Con la maschera Rio attira i colpi singoli: il bersaglio annunciato a volte diventa lui.
static func mask_target(state: Dictionary, target: String, rng: RNGState) -> String:
	var rio: Dictionary = unit_of_char(state, RIO)
	if rio.is_empty() or str(rio.get("form", "maschera")) != "maschera":
		return target
	if rng.random_int(1, 1000) <= MASK_AGGRO_PM:
		var slot: String = BattleState.slot_of(state, str(rio["id"]))
		return slot if slot != "" else target
	return target


# Il riposo di Nox: chi ha riposato agisce due volte nel round dopo (il secondo turno e' l'ultimo del round).
static func extra_turns(state: Dictionary) -> Array:
	var out: Array = []
	for p in BattleState.alive_players(state):
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if bool(u.get("rested", false)) and BattleState.is_alive(u):
			u.erase("rested")
			out.append({"unit": str(u["id"]), "player": str(p["id"]), "boss": false, "spd": -1, "extra": true})
	return out


# ---------------------------------------------------------------- Hype di Rio

static func after_events(state: Dictionary, events: Array) -> void:
	var rio: Dictionary = unit_of_char(state, RIO)
	if rio.is_empty():
		return
	var gain: int = 0
	for e in events:
		match str(e.get("t", "")):
			"timed_guard":
				gain += int(HYPE_GAIN["perfect"] if str(e.get("grade", "")) == "perfect" else HYPE_GAIN["good"])
			"break":
				gain += int(HYPE_GAIN["break"])
			"rhythm":
				gain += int(HYPE_GAIN["rhythm"])
			"synergy":
				gain += int(HYPE_GAIN["synergy"])
			"damage":
				if bool(e.get("crit", false)):
					gain += int(HYPE_GAIN["crit"])
				if str(e.get("dst", "")) == str(rio["id"]) and str(e.get("src", "")) == BattleState.BOSS_ID:
					gain += int(HYPE_GAIN["rio_hit"])
	add_hype(rio, gain, events, "pubblico")


# ---------------------------------------------------------------- IA (AUTO e prove)

# Vero se l'IA deve usare questa mossa di kit adesso. Le mosse senza regola qui seguono le regole generiche.
static func ai_wants(state: Dictionary, u: Dictionary, move_id: String, move: Dictionary) -> int:
	# 1 = si', 0 = no, -1 = decidi con le regole generiche
	match str(move.get("kit", "")):
		"cover":
			var ally: Dictionary = _single_target_ally(state, u)
			if ally.is_empty():
				return 0
			var heavy: bool = float(BattleContent.BOSS_MOVES.get(str(state["telegraph"].get("move", "")), {}).get("mult", 0.0)) >= 1.2
			return 1 if heavy or float(ally["hp"]) / float(ally["max_hp"]) < 0.6 else 0
		"coin":
			return 1
		"answer":
			for p in state["players"]:
				var q: Dictionary = BattleState.active_unit(state, str(p["id"]))
				if not q.is_empty() and not BattleState.is_alive(q):
					return 1
			var tm: Dictionary = BattleContent.BOSS_MOVES.get(str(state["telegraph"].get("move", "")), {})
			return 1 if str(tm.get("target", "")) == "all" and float(tm.get("mult", 0.0)) >= 0.9 else 0
		"finale":
			return 1 if int(u.get("hype", 0)) >= 50 else 0
	return -1
