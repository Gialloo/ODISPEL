class_name ImpactDirector
extends RefCounted

# Regia locale degli impact frames: sceglie overlay, hit-stop e scossa per un livello, con guardia anti-sovrapposizione.
# Non tocca motore di combattimento, rete, timer di gioco ne' Engine.time_scale: il "hit-stop" e' una pausa
# della sola presentazione (secondi restituiti a chi riproduce gli eventi + congelamento locale del palco).

const SHAKE: Array = [0.0, 0.0, 14.0, 18.0, 26.0]     # ampiezza minima (moltiplicata da Settings.shake dentro stage.impact)
const ZOOM: Array = [0.0, 0.0, 0.04, 0.05, 0.08]
const MIN_GAP_MS: int = 350                           # tra due lampi: niente sfarfallio rapido

var _active_level: int = 0
var _active_until_ms: int = 0
var _last_flash_ms: int = -100000
var _overlay: ImpactOverlay = null
var last_played: int = 0          # per i test: livello realmente mostrato dall'ultima chiamata
var last_hit_stop: float = 0.0
var count: int = 0
var _seed: int = 1


# Ritorna i secondi di hit-stop da aggiungere alla pausa tra eventi (0 se niente).
func play(level: int, fx_parent: Control, stage: Node, at: Vector2) -> float:
	last_played = 0
	last_hit_stop = 0.0
	if level <= 0:
		return 0.0
	var now: int = Time.get_ticks_msec()
	if now < _active_until_ms and level <= _active_level:
		return 0.0                                     # un effetto uguale o piu' forte e' ancora in corso
	var lite: bool = not AnimFx.enabled()
	if Settings.skip_cutin and level >= 3:
		lite = true                                    # chi salta le sequenze ultimate vede solo la versione breve
	var too_soon: bool = now - _last_flash_ms < MIN_GAP_MS
	if too_soon and level <= 2:
		lite = true
	var hs: float = float(ImpactFrames.HIT_STOP[level])
	if lite:
		hs *= 0.6
	if too_soon:
		hs *= 0.5
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null
	if fx_parent != null and is_instance_valid(fx_parent):
		_seed += 7
		_overlay = ImpactOverlay.new().setup(level, at, _seed, lite)
		fx_parent.add_child(_overlay)
		_active_until_ms = now + int(_overlay.len_s * 1000.0)
	else:
		_active_until_ms = now + int(float(ImpactFrames.OVERLAY_LEN[level]) * 1000.0)
	_active_level = level
	_last_flash_ms = now
	if stage != null and is_instance_valid(stage):
		if stage.has_method("impact") and SHAKE[level] > 0.0:
			stage.impact(float(SHAKE[level]), float(ZOOM[level]))
		if stage.has_method("freeze"):
			stage.freeze(hs)
	count += 1
	last_played = level
	last_hit_stop = hs
	return hs
