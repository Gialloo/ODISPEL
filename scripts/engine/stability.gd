class_name Stability
extends RefCounted

# STABILITA' NEMICA E BREAK (Fase 3 del combattimento, 04/11/2026; handoff integrativo sezione 9, piano AUDIT_0.52 «Fase 3»).
# La barra «equilibrio» del 0.52 resta (balance / balance_max, BreakRules dei cinque boss, attacco di squadra): qui si aggiunge
# cosa succede DOPO la rottura. Con BattleTypes.STAB_ON = false il gioco torna identico al 0.54.
#
#  - PRESSIONE != DANNO (9): P_BREAK = P_base × M_ability × M_situation. Un bonus al danno non tocca la pressione (gia' cosi'
#    nel 0.52: _chip_balance calcola i punti da colore, marchio, colpo pesante e BreakRules, mai dal danno).
#  - EFFETTO PER TIPOLOGIA (9.1), categoria in category():
#      comune · perde la prossima azione ordinaria (stun) e diventa vulnerabile (exposed, danno ×1,25)
#      elite  · la prossima azione e' RITARDATA (RITARDO forte in Timeline) e INDEBOLITA (danno × STAB_ELITE_WEAK), vulnerabile
#      boss   · collasso: perde la prossima azione (vantaggio temporale), vulnerabile, finestra di STAB_WINDOW["boss"] azioni
#  - FINESTRA (9.2) misurata in AZIONI ORDINARIE ALLEATE (on_ally_action, chiamata da BattleFlow): l'azione che rompe non la
#    consuma; SLANCIO, Guardia reattiva, reazioni, Ultimate in diretta e attacco di squadra non la consumano; Guardia ordinaria,
#    Attacco, Firma e Ultimate di turno si'. Le azioni del boss non la consumano. Non finisce piu' «a fine round».
#  - RECUPERO (9.3): finita la finestra la stabilita' riparte da 0 e risale a ogni azione ordinaria del nemico
#    (boss 33,3%: tre azioni = piena; elite 50%; comune: subito piena). Finche' non e' piena NON si puo' rompere di nuovo
#    (anti-catena). Il cambio di fase del boss completa il recupero (recupero «legato alle fasi»).
#  - PRESSIONE LATENTE (9.4): la pressione fatta durante il BREAK e il recupero non si perde (nel 0.54 si perdeva): si accumula
#    fino a un limite (STAB_LATENT_CAP × balance_max) e, al ripristino, si toglie dalla barra piena. Se la porterebbe a zero
#    il BREAK NON scatta da solo: la barra resta a 1 e la prossima azione che fa pressione provoca il collasso.
#    Se il limite scende, l'eccedenza gia' accumulata resta (si blocca solo il nuovo accumulo).
#  - SBILANCIAMENTO (audit 6.1, D11 provvisorio): un'Interruzione riuscita lascia il boss sbilanciato per i prossimi
#    SBIL_HITS colpi degli eroi: danno × SBIL_DMG, pressione × SBIL_PRESS.
#
# Stato sul nemico principale (BattleState.boss): stun, exposed (gia' del 0.52), brk_left (azioni alleate rimaste nella finestra),
# stab_rec (in recupero), latent (pressione latente), brk_weak (elite: prossima azione indebolita), sbil (colpi sbilanciati).
# Eventi per la UI (Fase 6): {"t": "break", "src", "cat", "window"} (stessa forma di prima piu' due campi),
#   {"t": "break_window", "left"}, {"t": "break_end", "cat"}, {"t": "stab_recover", "left", "max"},
#   {"t": "stab_full", "left", "latent"}, {"t": "latent", "src", "amount", "total"}, {"t": "sbil", "src", "hits"}.


# Vale solo per gli scontri giocati con BattleFlow (V3): start_round segna il nemico (boss["stab"]). Il motore classico
# (resolve_round, PvP, test del V2) resta identico al 0.54.
static var enabled: bool = BattleTypes.STAB_ON     # come BattleFlow.timeline: i test e il bilancio possono spegnerla


static func on(boss: Dictionary) -> bool:
	return BattleTypes.STAB_ON and bool(boss.get("stab", false))


static func mark(state: Dictionary) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if enabled and not boss.is_empty() and boss.has("balance"):
		boss["stab"] = true


# comune / elite / boss. I frammenti sono comuni; STAB_ELITE elenca gli elite (nell'atto 1 nessuno: D12); il resto e' boss.
static func category(boss: Dictionary) -> String:
	var id: String = str(boss.get("char", ""))
	if BattleTypes.STAB_ELITE.has(id) or bool(boss.get("elite", false)):      # "elite" sull'unita': per la scheda nemico (Fase 5)
		return "elite"
	if id.begins_with("frammento"):
		return "comune"
	return "boss"


static func in_break(boss: Dictionary) -> bool:
	return bool(boss.get("exposed", false))


static func recovering(boss: Dictionary) -> bool:
	return bool(boss.get("stab_rec", false))


static func latent_cap(boss: Dictionary) -> int:
	return int(floor(float(boss.get("balance_max", 0)) * float(BattleTypes.STAB_LATENT_CAP.get(category(boss), 0.0))))


# Toglie punti di pressione (al posto di BattleResolver._drain_balance quando STAB_ON).
static func drain(boss: Dictionary, pts: int, attacker: Dictionary, events: Array) -> void:
	if pts <= 0 or not boss.has("balance"):
		return
	if in_break(boss) or recovering(boss) or (int(boss.get("stun", 0)) > 0):
		_add_latent(boss, pts, attacker, events)
		return
	boss["balance"] = maxi(0, int(boss["balance"]) - pts)
	events.append({"t": "balance", "src": attacker["id"], "amount": pts, "left": int(boss["balance"])})
	if int(boss["balance"]) <= 0:
		_collapse(boss, attacker, events)


static func _add_latent(boss: Dictionary, pts: int, attacker: Dictionary, events: Array) -> void:
	var cap: int = latent_cap(boss)
	var now: int = int(boss.get("latent", 0))
	if now >= cap:
		return                      # limite raggiunto (o sceso sotto quanto gia' accumulato): l'eccedenza resta, non cresce
	var add: int = mini(pts, cap - now)
	boss["latent"] = now + add
	events.append({"t": "latent", "src": attacker["id"], "amount": add, "total": int(boss["latent"])})


static func _collapse(boss: Dictionary, attacker: Dictionary, events: Array) -> void:
	var cat: String = category(boss)
	boss["exposed"] = true
	boss["latent"] = 0
	boss["brk_left"] = int(BattleTypes.STAB_WINDOW.get(cat, 3))
	if cat == "elite":
		boss["brk_weak"] = true      # niente azione persa: la prossima e' ritardata (BattleFlow) e indebolita
		boss["brk_delay"] = true
	else:
		boss["stun"] = 1
	events.append({"t": "break", "src": attacker["id"], "cat": cat, "window": int(boss["brk_left"])})


# Un'azione ordinaria di un eroe e' finita (BattleFlow). ev = eventi di quell'azione: se contiene la rottura, non consuma.
static func on_ally_action(state: Dictionary, ev: Array) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if not on(boss) or not in_break(boss) or not BattleState.is_alive(boss):
		return
	for e in ev:
		var t: String = str(e.get("t", ""))
		if t == "break" or t == "duo_rest":
			return
	boss["brk_left"] = maxi(0, int(boss.get("brk_left", 0)) - 1)
	ev.append({"t": "break_window", "left": int(boss["brk_left"])})
	if int(boss["brk_left"]) <= 0:
		_end_break(boss, ev)


static func _end_break(boss: Dictionary, events: Array) -> void:
	var cat: String = category(boss)
	boss["exposed"] = false
	boss.erase("brk_delay")
	events.append({"t": "break_end", "cat": cat})
	if cat == "comune":
		_restore(boss, events)          # recupero rapido: subito in piedi
		return
	boss["balance"] = 0
	boss["stab_rec"] = true
	events.append({"t": "stab_recover", "left": 0, "max": int(boss["balance_max"])})


# Un'azione ordinaria del nemico principale (non quella persa per lo stordimento). Chiamata da SeqRound.boss_action.
static func on_enemy_action(state: Dictionary, events: Array) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if not on(boss):
		return
	boss.erase("brk_weak")
	if not recovering(boss):
		return
	var pct: float = float(BattleTypes.STAB_RECOVER.get(category(boss), 1.0))
	var step: int = maxi(1, int(ceil(float(boss["balance_max"]) * pct - 0.0001)))
	boss["balance"] = mini(int(boss["balance_max"]), int(boss["balance"]) + step)
	if int(boss["balance"]) >= int(boss["balance_max"]):
		_restore(boss, events)
	else:
		events.append({"t": "stab_recover", "left": int(boss["balance"]), "max": int(boss["balance_max"])})


# Stabilita' di nuovo piena: la pressione latente passa sulla barra, senza far scattare il BREAK da sola.
static func _restore(boss: Dictionary, events: Array) -> void:
	var lat: int = int(boss.get("latent", 0))
	boss["stab_rec"] = false
	boss["latent"] = 0
	boss["balance"] = clampi(int(boss["balance_max"]) - lat, 1, int(boss["balance_max"]))
	events.append({"t": "stab_full", "left": int(boss["balance"]), "latent": lat})
	events.append({"t": "recover", "left": int(boss["balance"])})     # stesso evento del 0.52: la UI che c'e' lo capisce gia'


# Cambio di fase del boss: il recupero si completa (BattleResolver._check_phase). Durante il BREAK la finestra continua.
static func on_phase(boss: Dictionary, events: Array) -> void:
	if recovering(boss):
		_restore(boss, events)


# Fine round: con STAB_ON il BREAK non finisce piu' qui. Ritorna true se ha gestito lui il fine round (niente recupero del 0.52).
static func round_end(state: Dictionary, events: Array) -> bool:
	var boss: Dictionary = BattleState.boss(state)
	if not on(boss):
		return false
	if in_break(boss) or recovering(boss):
		return true
	if int(boss.get("balance", 0)) < int(boss.get("balance_max", 0)) and BattleTypes.BREAK_REGEN > 0:
		boss["balance"] = mini(int(boss["balance_max"]), int(boss["balance"]) + BattleTypes.BREAK_REGEN)
		events.append({"t": "recover", "left": int(boss["balance"]), "soft": true})
	return true


# SBILANCIAMENTO: dopo un'Interruzione riuscita.
static func unbalance(boss: Dictionary, attacker: Dictionary, events: Array) -> void:
	if not on(boss) or BattleTypes.SBIL_HITS <= 0:
		return
	boss["sbil"] = BattleTypes.SBIL_HITS
	events.append({"t": "sbil", "src": attacker["id"], "hits": BattleTypes.SBIL_HITS})


# Moltiplicatore di danno sul nemico principale (sbilanciato) e del danno fatto da un elite indebolito.
static func damage_mult(attacker: Dictionary, defender: Dictionary) -> float:
	if str(defender.get("id", "")) == BattleState.BOSS_ID and str(attacker.get("side", "")) == "player" and int(defender.get("sbil", 0)) > 0 and on(defender):
		return BattleTypes.SBIL_DMG
	if str(attacker.get("id", "")) == BattleState.BOSS_ID and bool(attacker.get("brk_weak", false)) and on(attacker):
		return BattleTypes.STAB_ELITE_WEAK
	return 1.0


# Pressione del colpo con lo sbilanciamento (consuma un colpo). Chiamata da _chip_balance.
static func pressure_mult(boss: Dictionary) -> float:
	if not on(boss) or int(boss.get("sbil", 0)) <= 0:
		return 1.0
	boss["sbil"] = int(boss["sbil"]) - 1
	return BattleTypes.SBIL_PRESS
