extends SceneTree

# Misura il ritmo degli scontri senza grafica: un giocatore finto gioca col motore vero (pg_engine.gd)
# contro ogni nemico del Capitolo 1 e conta durata, attacchi, CROLLI, KO e tempi morti.
# Uso: godot --headless --path . -s tools/ritmo.gd [-- semi=20]
# Profili: «bravo» (riflessi 0.12 s, sbaglia poco) e «medio» (riflessi 0.25 s, sbaglia un CONTRO su tre).

const E = preload("res://scripts/scontro/pg_engine.gd")
const ORDINE: Array = ["varco", "sciame", "covata", "ingordo", "eco", "guardiano", "cuore"]   # scene con lo scontro, in data/capitolo1.json
const PROFILI: Dictionary = {
	"bravo": {"riflessi": 0.12, "manca_contro": 0.10, "manca_salto": 0.05, "postura": 0.8},
	"medio": {"riflessi": 0.25, "manca_contro": 0.35, "manca_salto": 0.25, "postura": 0.3},
}


func _init() -> void:
	var semi: int = 20
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semi="):
			semi = int(a.substr(5))
	for prof in PROFILI:
		print("== profilo ", prof)
		print("nemico               | durata s | attacchi | colpito | CROLLI | KO | vinte | max s senza pericolo | % a terra (CROLLO) | % nemico fermo")
		for n in _nemici():
			var tot: Dictionary = {"t": 0.0, "atk": 0, "hit": 0, "crollo": 0, "ko": 0, "win": 0, "gap": 0.0, "crollo_t": 0.0, "idle_t": 0.0}
			for s in semi:
				var r: Dictionary = _partita(PROFILI[prof], float(n[1]), n[2], 100 + s)
				for k in tot:
					tot[k] += r[k]
			print("%-20s | %8.1f | %8.1f | %7.1f | %6.1f | %2.1f | %3d/%d | %5.1f | %3d%% | %3d%%" % [n[0], tot["t"] / semi, float(tot["atk"]) / semi, float(tot["hit"]) / semi, float(tot["crollo"]) / semi, float(tot["ko"]) / semi, tot["win"], semi, tot["gap"] / semi, int(100.0 * tot["crollo_t"] / tot["t"]), int(100.0 * tot["idle_t"] / tot["t"])])
	quit()


func _nemici() -> Array:
	# legge nemico, forza e ritmo dal file della storia: la misura segue sempre i dati veri
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/capitolo1.json"))
	var out: Array = []
	for k in ORDINE:
		for r in d["scene"][k]:
			if r.get("regia", "") == "scontro":
				out.append([str(r.get("nemico", "ANOMALIA")).substr(0, 20), float(r.get("forza", 1.0)), r.get("ritmo", {})])
	return out


func _partita(p: Dictionary, forza: float, ritmo: Dictionary, seme: int) -> Dictionary:
	var eng = E.new(seme, 4)
	eng.ehp *= forza
	eng.set_ritmo(ritmo)
	var rng := RandomNumberGenerator.new()
	rng.seed = seme * 31
	var r: Dictionary = {"t": 0.0, "atk": 0, "hit": 0, "crollo": 0, "ko": 0, "win": 0, "gap": 0.0, "crollo_t": 0.0, "idle_t": 0.0}
	var deciso: Dictionary = {}      # per ogni attacco nemico: cosa farà il giocatore
	var ultimo_pericolo: float = 0.0
	var crollo_da: float = -1.0
	var passo: float = 1.0 / 60.0
	var prossimo_gesto: float = 0.0
	while eng.over == "" and eng.time < 600.0:
		eng.step(passo)
		if eng.est == "crollo":
			r["crollo_t"] += passo
		elif eng.est in ["idle", "rec", "stun", "down", "air"]:
			r["idle_t"] += passo
		for ev in eng.take_events():
			match str(ev["type"]):
				"mirino":
					r["atk"] += 1
					r["gap"] = maxf(r["gap"], eng.time - ultimo_pericolo)
					deciso = {"manca": rng.randf() < (p["manca_contro"] if ev["kind"] == "affondo" else p["manca_salto"]), "fatto": false, "postura": rng.randf() < p["postura"]}
				"colpito":
					r["hit"] += 1
				"crollo":
					r["crollo"] += 1
					crollo_da = eng.time
				"ko":
					r["ko"] += 1
			if str(ev["type"]) in ["mirino", "colpito", "contro", "schivata", "saltata", "crollo_finito"]:
				ultimo_pericolo = eng.time
		var d: Dictionary = eng.danger()
		if not d.is_empty():
			var left: float = float(d["left"])
			if not deciso.get("fatto", true) and not deciso.get("manca", false):
				if d["kind"] == "affondo":
					if deciso["postura"] and d["color"] != "" and eng.posture != d["color"] and left > 0.5:
						eng.input("postura")
						deciso["postura"] = false
					if left <= 0.30 - p["riflessi"] + 0.12 and left > 0.02:
						eng.input("verso")
						deciso["fatto"] = true
				elif left <= 0.35:
					eng.input("su")
					deciso["fatto"] = true
			continue
		if eng.time < prossimo_gesto:
			continue
		prossimo_gesto = eng.time + p["riflessi"] * 0.6
		if eng.est == "crollo":
			if eng.time - crollo_da > 2.4:
				eng.input("verso")      # BLACKOUT
			else:
				eng.input("tocco")
			continue
		if eng.ex - eng.px > E.REACH:
			eng.input("verso")        # affondo per avvicinarsi
		elif eng.chain >= 3:
			eng.input("verso")        # sfondamento
		else:
			eng.input("tocco")
	r["t"] = eng.time
	r["win"] = 1 if eng.over == "vittoria" else 0
	return r
