extends SceneTree

# BILANCIO DELLA BATTAGLIA: simula gli scontri dell'atto 1 con l'IA automatica (BattleAI) e stampa le metriche del piano combat.
# Serve a tarare le costanti del motore (equilibrio, Riserva, ...) senza giocare: ripetibile, deterministica (semi fissi).
# Uso: godot --headless --path . --script tools/v3_bilancio.gd -- [semi=40] [minori] [dettaglio] [replica=N] [solo=distributore]
#   semi=N      quanti semi per scontro (default 40)
#   replica=N   Replica della diretta: nemici +15% PV e attacco per giro
#   dettaglio   sotto ogni scontro la quota di danno di tutti e quattro
#   minori      include anche i frammenti (nemici minori)
#   solo=ID     un solo scontro
#   ng=N        New Game+ N: nemici al livello di BattleTypes.replica_level, squadra da Progress (sblocchi migliori equipaggiati)
#   scarto=K    con ng: la squadra ha K livelli in meno del nemico (default 0; negativo = piu' alta)
#   kit         anche senza ng, la squadra usa Progress (sblocchi del livello) invece del kit base
# Gli scontri e le scale PV/attacco replicano battle3d.gd (pv_k, atk_k, livello); la squadra e' quella dell'atto 1 con ultimate al 60%.
# Metriche: vittorie, KO, round, turni del boss giocati/persi, quota di danno di Saul e di Nox, uso di cure/scudi/Veglia di Nox,
# occasioni di reazione (carica annunciata + Riserva disponibile) e reazioni fatte.

const PARTY: Array = ["ferri", "nox", "zecca", "saul"]
# (boss, livello, pv, atk, minore)
const ENC: Array = [
	["frammento_giallo", 1, 1.0, 1.0, true], ["frammento_rosso", 3, 1.0, 1.0, true], ["frammento_blu", 5, 1.0, 1.0, true], ["frammento_verde", 7, 1.0, 1.0, true],
	["distributore", 1, 1.0, 0.8, false], ["semaforo", 3, 0.9, 0.9, false], ["cabina", 5, 0.8, 0.9, false],
	["manichino", 7, 0.8, 0.85, false], ["cassaforte", 9, 0.6, 0.75, false], ["autovelox", 11, 0.65, 0.8, false]]


var replica: int = 0
var ng: int = -1
var scarto: int = 0
var use_kit: bool = false


# Squadra di Progress al livello dato, con l'ultimo sblocco di ogni tipo equipaggiato
func _kit_team(lvl: int) -> Array:
	Progress.reset()
	var team: Array = []
	for c in PARTY:
		Progress.data["lv"][c] = clampi(lvl, 1, Progress.MAX_LEVEL)
		for u in Progress.UNLOCKS[c]:
			if int(u[0]) <= int(Progress.data["lv"][c]):
				Progress.equip(c, str(u[1]), str(u[2]))
		team.append(Progress.entry_for(c))
	return team


func _setup(boss: String, lvl: int, pv: float, atk: float, minore: bool, seed_value: int) -> Dictionary:
	var team: Array = []
	if ng >= 0:
		lvl = BattleTypes.replica_level(lvl, ng)
	if ng >= 0 or use_kit:
		team = _kit_team(lvl - scarto)
	else:
		for id in PARTY:
			team.append(BattleContent.default_entry(id, lvl))
	var b: Dictionary = BattleState.create_solo("IO", team, [], boss, seed_value)
	var bu: Dictionary = BattleState.boss(b)
	var grow: float = BattleTypes.story_hp_grow(lvl)
	var rk: float = BattleTypes.replica_hard(replica)
	pv *= rk
	atk *= rk
	var pk: float = pv * (BattleTypes.STORY_HP_MINOR if minore else BattleTypes.STORY_HP_BOSS) * grow
	var ak: float = atk * BattleTypes.STORY_ATK_K * BattleTypes.story_atk_grow(lvl)
	bu["max_hp"] = maxi(1, int(round(float(bu["max_hp"]) * pk)))
	bu["hp"] = bu["max_hp"]
	bu["atk"] = maxi(1, int(round(float(bu["atk"]) * ak)))
	if ng >= 0 or use_kit:
		Progress.apply_to_battle(b)
	for uid in b["units"]:
		if str(uid) != "boss":
			b["units"][uid]["gauge"] = mini(BattleTypes.GAUGE_MAX, 60 + int(b["units"][uid].get("syn_gauge", 0)))
	return b


func _char_of(uid: String) -> String:
	var parts: PackedStringArray = uid.split(":")
	return parts[parts.size() - 1]


func _scan(ev: Array, st: Dictionary) -> void:
	for e in ev:
		var t: String = str(e.get("t", ""))
		match t:
			"damage":
				if str(e.get("dst", "")) == "boss" and str(e.get("src", "")) != "boss":
					var c: String = _char_of(str(e.get("src", "")))
					st["dmg_" + c] = float(st.get("dmg_" + c, 0.0)) + float(e.get("amount", 0))
					st["dmg_tot"] = float(st.get("dmg_tot", 0.0)) + float(e.get("amount", 0))
			"heal":
				if str(e.get("src", "")) != "boss":
					var c2: String = _char_of(str(e.get("src", "")))
					st["heal_" + c2] = float(st.get("heal_" + c2, 0.0)) + 1.0
			"rest":
				# Pausa caffe' a riposo (scudo a tutti): un'azione utile di Nox, conta come una cura
				st["heal_nox"] = float(st.get("heal_nox", 0.0)) + 1.0
			"kit_trait":
				if str(e.get("trait", "")) == "veglia":
					st["veglia"] = float(st.get("veglia", 0.0)) + 1.0
			"react":
				st["react"] = float(st.get("react", 0.0)) + 1.0
			"break":
				st["break"] = float(st.get("break", 0.0)) + 1.0


func _run(boss: String, lvl: int, pv: float, atk: float, minore: bool, seeds: int) -> Dictionary:
	var st: Dictionary = {}
	for sd in range(1, seeds + 1):
		var b: Dictionary = _setup(boss, lvl, pv, atk, minore, sd)
		var guard: int = 0
		var minhp: float = 1.0
		st["runs"] = float(st.get("runs", 0.0)) + 1.0
		while str(b["winner"]) == "" and guard < 80:
			guard += 1
			SeqRound.begin(b)
			# occasione di reazione: carica annunciata (non stordito) e almeno 1 di Riserva
			var tele: Dictionary = b["telegraph"]
			var bm: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
			if not bm.is_empty() and int(BattleState.boss(b).get("stun", 0)) == 0 and BattleResolver.is_heavy_boss_move(bm) and int(b.get("reserve", 0)) >= 1:
				st["occasioni"] = float(st.get("occasioni", 0.0)) + 1.0
			var order: Array = SeqRound.order(b)
			var oi: int = 0
			while oi < order.size():
				var e: Dictionary = order[oi]
				oi += 1
				if str(b["winner"]) != "":
					break
				if bool(e["boss"]):
					if int(BattleState.boss(b).get("stun", 0)) > 0:
						st["boss_persi"] = float(st.get("boss_persi", 0.0)) + 1.0
					else:
						st["boss_giocati"] = float(st.get("boss_giocati", 0.0)) + 1.0
					_scan(SeqRound.boss_action(b), st)
				else:
					var pid: String = str(e["player"])
					var evp: Array = SeqRound.player_action(b, pid, BattleAI.choose(b, pid), bool(e.get("quick", false)))
					_scan(evp, st)
					for x in evp:
						if str(x.get("t", "")) == "slancio":
							st["slancio"] = float(st.get("slancio", 0.0)) + 1.0
							order.insert(oi, {"unit": x["unit"], "player": x["player"], "boss": false, "spd": -1, "extra": true, "quick": true})
			_scan(SeqRound.finish(b), st)
			for uid in b["units"]:
				if str(uid) != "boss":
					minhp = minf(minhp, float(b["units"][uid]["hp"]) / float(maxi(1, int(b["units"][uid]["max_hp"]))))
		st["rounds"] = float(st.get("rounds", 0.0)) + float(guard)
		st["minhp"] = float(st.get("minhp", 0.0)) + minhp
		if str(b["winner"]) == "players":
			st["wins"] = float(st.get("wins", 0.0)) + 1.0
		for uid in b["units"]:
			if str(uid) != "boss" and int(b["units"][uid]["hp"]) <= 0:
				st["ko"] = float(st.get("ko", 0.0)) + 1.0
	return st


func _init() -> void:
	var seeds: int = 40
	var minori: bool = false
	var solo: String = ""
	var dettaglio: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semi="):
			seeds = int(a.substr(5))
		elif a.begins_with("replica="):
			replica = int(a.substr(8))
		elif a.begins_with("ng="):
			ng = int(a.substr(3))
			replica = ng
		elif a.begins_with("scarto="):
			scarto = int(a.substr(7))
		elif a == "kit":
			use_kit = true
		elif a == "dettaglio":
			dettaglio = true
		elif a == "minori":
			minori = true
		elif a.begins_with("solo="):
			solo = a.substr(5)
	print("%-18s %3s %5s %5s %5s %6s %6s %5s %5s %6s %6s %6s %5s %6s %5s" % ["scontro", "liv", "vitt%", "KO", "round", "bossG", "bossP", "ross", "slan", "Saul%", "Nox%", "NoxCP", "vegl", "occas", "reaz"])
	var tot: Dictionary = {}
	var n_boss: int = 0
	for enc in ENC:
		if bool(enc[4]) and not minori and solo == "":
			continue
		if solo != "" and str(enc[0]) != solo:
			continue
		var st: Dictionary = _run(str(enc[0]), int(enc[1]), float(enc[2]), float(enc[3]), bool(enc[4]), seeds)
		var r: float = float(st["runs"])
		var tot_dmg: float = maxf(1.0, float(st.get("dmg_tot", 0.0)))
		print("%-18s %3d %5.0f %5.2f %5.1f %6.2f %6.2f %5.2f %5.2f %6.0f %6.0f %6.2f %5.2f %6.2f %5.2f" % [
			enc[0], BattleTypes.replica_level(int(enc[1]), ng) if ng >= 0 else int(enc[1]), 100.0 * float(st.get("wins", 0.0)) / r, float(st.get("ko", 0.0)) / r, float(st.get("rounds", 0.0)) / r,
			float(st.get("boss_giocati", 0.0)) / r, float(st.get("boss_persi", 0.0)) / r, float(st.get("break", 0.0)) / r, float(st.get("slancio", 0.0)) / r,
			100.0 * float(st.get("dmg_saul", 0.0)) / tot_dmg, 100.0 * float(st.get("dmg_nox", 0.0)) / tot_dmg,
			float(st.get("heal_nox", 0.0)) / r, float(st.get("veglia", 0.0)) / r,
			float(st.get("occasioni", 0.0)) / r, float(st.get("react", 0.0)) / r])
		if dettaglio:
			var parts: String = "     quota danno sul boss:"
			for c in PARTY:
				parts += "  %s %.0f%%" % [c, 100.0 * float(st.get("dmg_" + c, 0.0)) / tot_dmg]
			parts += "   | PV minimo raggiunto (media) %.0f%%" % (100.0 * float(st.get("minhp", 0.0)) / r)
			print(parts)
		if not bool(enc[4]):
			n_boss += 1
			for k in st:
				tot[k] = float(tot.get(k, 0.0)) + float(st[k])
	if n_boss > 0:
		var r2: float = float(tot["runs"])
		var d2: float = maxf(1.0, float(tot.get("dmg_tot", 0.0)))
		print("%-18s %3s %5.0f %5.2f %5.1f %6.2f %6.2f %5.2f %5.2f %6.0f %6.0f %6.2f %5.2f %6.2f %5.2f" % [
			"MEDIA BOSS", "", 100.0 * float(tot.get("wins", 0.0)) / r2, float(tot.get("ko", 0.0)) / r2, float(tot.get("rounds", 0.0)) / r2,
			float(tot.get("boss_giocati", 0.0)) / r2, float(tot.get("boss_persi", 0.0)) / r2, float(tot.get("break", 0.0)) / r2, float(tot.get("slancio", 0.0)) / r2,
			100.0 * float(tot.get("dmg_saul", 0.0)) / d2, 100.0 * float(tot.get("dmg_nox", 0.0)) / d2,
			float(tot.get("heal_nox", 0.0)) / r2, float(tot.get("veglia", 0.0)) / r2,
			float(tot.get("occasioni", 0.0)) / r2, float(tot.get("react", 0.0)) / r2])
	quit()
