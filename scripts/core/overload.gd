extends Node
## OVERLOAD: una sola barra di sinergia tra protagonista e ambiente.
## Sale con azioni DIVERSE concatenate (arma, potere, ambiente, reazioni a catena, schivate perfette),
## rende poco se ripeti la stessa cosa, cala se ti fermi o se vieni colpito. Non conta il danno.
## Tre livelli: 1 = potere stadio 2 (pesanti), 2 = stadio 3 (due bersagli),
## 3 = OVERLOAD pieno: per qualche secondo ricariche del potere rapidissime, poi la barra scende.

signal level_changed(level: int)
signal burst(on: bool)

const LEVELS := [34.0, 67.0, 100.0]

## Valore delle azioni: categoria e punti. Tutto modificabile qui.
var values := {
	# potere
	"power_push": ["power", 7.0], "power_pull": ["power", 7.0], "power_alter": ["power", 6.0],
	"power_throw": ["power", 9.0], "power_poke": ["power", 7.0],
	# ambiente
	"wall_slams": ["env", 12.0], "enemy_collisions": ["env", 12.0], "prop_hits": ["env", 10.0],
	"barrels_exploded": ["env", 14.0], "puddle_shocks": ["env", 16.0], "coil_discharges": ["env", 10.0],
	"structures_broken": ["env", 12.0], "fire_throws": ["env", 14.0], "enemies_burned": ["env", 8.0],
	# reazioni a catena
	"overcharge_blasts": ["chain", 14.0], "fire_spread": ["chain", 10.0], "enemies_shocked": ["chain", 5.0],
	# difesa e controllo
	"perfect_dodges": ["defense", 15.0], "interrupts": ["defense", 6.0], "staggers": ["control", 5.0],
	"launch_follow": ["control", 8.0], "kills": ["control", 5.0],
}
var tune := {
	"gain": 0.6,           # moltiplicatore generale dei punti
	"grace": 2.5,          # secondi senza azioni prima che la barra cali
	"decay": 9.0,          # punti al secondo dopo la tregua
	"repeat_mult": 0.3,    # stessa azione tra le ultime 6: rende meno
	"switch_mult": 1.4,    # categoria diversa dalla precedente: rende di più
	"hurt_loss": 15.0,
	"burst_time": 6.0,
	"burst_cd_mult": 0.35,
}

var meter := 0.0
var level := 0
var bursting := 0.0
var _recent: Array = []
var _last_cat := ""
var _idle := 0.0
var _last_gain := 0.0
var _peak := 0.0

func reset() -> void:
	meter = 0.0
	bursting = 0.0
	_recent.clear()
	_last_cat = ""
	_set_level(0)

## Ogni statistica del gioco passa da qui (FX.stat).
func on_stat(key: String) -> void:
	if values.has(key):
		var v: Array = values[key]
		feed(key, v[0], v[1])

## Un'azione del giocatore: tag = cosa esattamente, cat = famiglia.
func feed(tag: String, cat: String, pts: float) -> void:
	var g: float = pts * tune.gain * (1.3 if Run.has("barra_calda") else 1.0)
	if _recent.has(tag):
		g *= tune.repeat_mult
	elif cat != _last_cat and _last_cat != "":
		g *= tune.switch_mult
	_recent.append(tag)
	if _recent.size() > 6:
		_recent.pop_front()
	_last_cat = cat
	_idle = 0.0
	_last_gain = g
	if bursting > 0.0:
		return
	meter = min(100.0, meter + g)
	_peak = max(_peak, meter)
	FX.stats["overload_points"] = FX.stats.get("overload_points", 0) + int(round(g))
	_refresh()

func hurt() -> void:
	if bursting > 0.0:
		return
	meter = max(0.0, meter - tune.hurt_loss)
	_refresh()

## Stadio di potere sbloccato in questo momento (0 = nessun aiuto).
func stage_bonus() -> int:
	if bursting > 0.0:
		return 3
	return [1, 2, 3, 3][level]

func cooldown_mult() -> float:
	var m: float = tune.burst_cd_mult if bursting > 0.0 else 1.0
	return m * (0.7 if Run.has("ricarica_rapida") else 1.0)

func _refresh() -> void:
	var l := 0
	for i in LEVELS.size():
		if meter >= LEVELS[i] - 0.01:
			l = i + 1
	if l == 3 and bursting <= 0.0:
		bursting = tune.burst_time
		FX.stat("overload_bursts")
		FX.sound("cutin", 0.7)
		FX.shake(0.5)
		FX.speed_lines(600)
		burst.emit(true)
	_set_level(l)

func _set_level(l: int) -> void:
	if l != level:
		if l > level:
			FX.stat("overload_level_%d" % l)
		level = l
		level_changed.emit(l)

func _process(delta: float) -> void:
	if bursting > 0.0:
		bursting -= delta
		meter = 100.0 * clamp(bursting / tune.burst_time, 0.0, 1.0) * 0.5 + 50.0
		if bursting <= 0.0:
			bursting = 0.0
			meter = 20.0
			burst.emit(false)
			_refresh()
		return
	_idle += delta
	if _idle > tune.grace and meter > 0.0:
		meter = max(0.0, meter - tune.decay * delta)
		_refresh()
