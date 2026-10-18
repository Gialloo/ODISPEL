extends Node3D

# COMBATTIMENTO 3D (test 0.29.0): i quattro protagonisti contro l'Anomalia "Distributore".
# Logica: il motore della V2 copiato in scripts/engine (BattleState + SeqRound: turni per velocita', energia,
# ultimate, rottura, colori). Qui c'e' SOLO la presentazione: camera, animazioni, numeri, interfaccia.
#
# Rendering usato: come la strada (unshaded + toon nello shader, contorni a guscio, bagliori additivi, sfondo a colore,
# niente luci/ombre/cielo/Label3D). I numeri del danno sono Label 2D proiettati dalla camera.

const PARTY: Array = ["ferri", "nox", "zecca", "saul"]
const START_GAUGE: int = 60          # PROVVISORIO (test): ultimate gia' a buon punto, cosi' si vede nel mini combattimento
const ENEMY_POS := Vector3(0, 0.14, -3.4)

const STATUS_NAMES: Dictionary = {
	"guard": "GUARDIA", "taunt": "PROVOCA", "mark": "MARCHIO", "bleed": "SANGUINA", "stun": "STORDITO",
	"shield": "SCUDO", "ronda": "RONDA",
}

var from: String = "menu"
var ingresso: String = "normale"      # normale | vantaggio (attacco a sorpresa) | agguato (attacca prima il nemico)
var indizi: Array = []
var boss_id: String = "distributore"     # quale nemico (BattleContent.BOSSES)
var visual: String = "distributore"      # aspetto 3D (VendingVisual.kind)
var level: int = 1                       # livello della squadra (PROVVISORIO: cresce coi capitoli)
var pv_k: float = 1.0                    # scala PV e attacco del nemico (PROVVISORIO, bilanciamento dell'atto 1)
var atk_k: float = 1.0
var arena: String = "strada"
var weak: Array = []                     # debolezze scoperte con gli indizi
var ritorno: Dictionary = {}             # dove tornare: area (nemico minore), storia (boss), niente = demo dal menu
var minore: bool = false
var _args: Dictionary = {}
var _round1: bool = true
var b: Dictionary = {}
var slots: Array = []                 # id degli slot (p1, p1_f2, ...)
var vis: Dictionary = {}              # unit id -> CharacterVisual / VendingVisual
var home: Dictionary = {}             # unit id -> posizione di riposo
var turn_list: Array = []
var turn_i: int = -1
var cur_pid: String = ""
var waiting: bool = false             # in attesa della scelta del giocatore
var ended: bool = false
var auto_on: bool = false
var fast: bool = false
var first_turn: bool = true

var cam: Camera3D
var _cam_pos: Vector3
var _cam_look: Vector3
var _cam_want_pos: Vector3
var _cam_want_look: Vector3
var _cam_rate: float = 3.0
var _shake: float = 0.0

# interfaccia
var _ui: CanvasLayer
var _root: Control
var _fx_layer: Control
var _broken: BrokenCam
var _order_box: VBoxContainer
var _boss_name: Label
var _boss_hp: ProgressBar
var _boss_hp_txt: Label
var _boss_brk: ProgressBar
var _tele: Label
var _cards: Array = []
var _turn_lbl: Label
var _cmd_box: VBoxContainer
var _btn_atk: Button
var _btn_skill: Button
var _btn_ult: Button
var _btn_guard: Button
var _btn_auto: Button
var _btn_fast: Button
var _hint: Label
var _cutin: Control
var _pause: Control


func configure(args: Dictionary) -> void:
	from = str(args.get("from", "menu"))
	ingresso = str(args.get("ingresso", "normale"))
	indizi = args.get("indizi", [])
	_args = args.duplicate(true)
	boss_id = str(args.get("boss", "distributore"))
	visual = str(args.get("visual", boss_id))
	level = int(args.get("livello", 1))
	pv_k = float(args.get("pv", 1.0))
	atk_k = float(args.get("atk", 1.0))
	arena = str(args.get("arena", "strada"))
	weak = args.get("debolezze", [])
	if indizi.has("scontrino") and not weak.has("VIOLA"):
		weak = weak + ["VIOLA"]
	ritorno = args.get("ritorno", {})
	minore = bool(args.get("minore", false))


func crumb() -> String:
	return "battaglia"


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _ready() -> void:
	Breadcrumb.mark("battaglia_carico")
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#120b22")
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	add_child(env)
	Toon.set_fog(Color("#1a1030"), 12.0, 46.0)
	_build_arena()
	_setup_battle()
	_build_units()
	cam = Camera3D.new()
	cam.fov = 58.0
	cam.near = 0.1
	cam.far = 120.0
	add_child(cam)
	cam.current = true
	_cam_overview(true)
	_build_ui()
	_refresh_hud()
	Breadcrumb.mark("battaglia")
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	match ingresso:
		"vantaggio":
			_toast("ATTACCO A SORPRESA! %s è già %s alla rottura e agite per primi" % [_cap(_bn()), _g("vicino", "vicina")], Ui.YELLOW, 3.0)
		"agguato":
			_toast("AGGUATO! %s attacca per %s" % [_cap(_bn()), _g("primo", "prima")], Color("#ff7a9c"), 3.0)
	await get_tree().create_timer(0.4).timeout
	var bonds: Array = Story.active_bonds() if not ritorno.is_empty() else []
	var msgs: Array = []
	if not weak.is_empty():
		msgs.append(["INDIZIO: %s teme il %s. Fai colpire %s." % [_bn(), str(weak[0]), _who_is(str(weak[0]))], Ui.CYAN])
	for bd in bonds:
		msgs.append(["LEGAME · %s: +5%% attacco a entrambi" % str(bd.get("nome", "")), Ui.PINK])
	var delay: float = 3.4 if ingresso != "normale" else 0.0
	for m in msgs:
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_inside_tree():
				_toast(str(m[0]), m[1], 2.8))
		delay += 3.0
	_start_round()


func _main() -> Node:
	return get_parent()


# Nemici femminili (per l'articolo); gli altri sono maschili
const FEMININE: Array = ["Cabina", "Cassaforte", "Sirena", "Scala mobile", "Radio", "Metro", "Anomalia", "Eclissi"]


# Nome del nemico con l'articolo ("il Semaforo", "la Cabina", "lo Specchio", "l'Orologio").
# Un nome che ha gia' l'articolo ("L'Osservatore") resta com'e', con la minuscola.
func _bn() -> String:
	var n: String = str(BattleContent.BOSSES.get(boss_id, {}).get("name", "Anomalia"))
	return article(n)


static func article(n: String) -> String:
	if n.begins_with("L'"):
		return "l'" + n.substr(2)
	if n.length() > 0 and n[0].to_lower() in "aeiou":
		return "l'" + n
	if n in FEMININE:
		return "la " + n
	var lo: bool = n.begins_with("Z") or n.begins_with("Gn") or (n.begins_with("S") and n.length() > 1 and not n[1] in "aeiou")
	return ("lo " if lo else "il ") + n


# Parola accordata al genere del nemico
func _g(masc: String, fem: String) -> String:
	return fem if str(BattleContent.BOSSES.get(boss_id, {}).get("name", "Anomalia")) in FEMININE else masc


# Prima lettera maiuscola, il resto come sta ("l'Osservatore" -> "L'Osservatore")
static func _cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


func _bname() -> String:
	return str(BattleContent.BOSSES.get(boss_id, {}).get("name", "Anomalia")).to_upper()


func _who_is(col: String) -> String:
	match col:
		"ROSSO":
			return "Lance"
		"BLU":
			return "Nox"
		"VIOLA":
			return "Rio"
		"VERDE":
			return "Saul"
	return "chi ha quel colore"


# ---------------------------------------------------------------- scena

func _build_arena() -> void:
	if arena in ["strada", "incrocio", ""]:
		var cb := CityBuilder.new(41)
		cb.street(16.0, -22.0)
		for side in [-1.0, 1.0]:
			var z: float = 16.0
			while z > -20.0:
				var l: float = cb.rng.randf_range(6.0, 9.0)
				cb.building(side, z, l - 0.3, 8.0, cb.rng.randf_range(8.0, 17.0))
				z -= l
		cb.backdrop(-22.0)
		cb.lamp(4.45, 4.0)
		cb.lamp(-4.45, -5.0)
		cb.car(-6.0 + 3.3, -12.0, Color("#6b3fa0"))
		cb.moon(Vector3(24, 40, -110), 8.0)
		cb.build(self)
		return
	# arene delle altre aree: stessa scenografia dell'esplorazione (interno Anomalia, vicolo, galleria, caveau)
	var layout: String = "anomalia" if arena.begins_with("anomalia") or arena in ["rosso", "blu", "verde"] else arena
	var tema: String = arena.replace("anomalia_", "")
	var lay: Dictionary = LayoutBuilder.build(layout, 5, tema, self)
	var env: WorldEnvironment = null
	for c in get_children():
		if c is WorldEnvironment:
			env = c
	if env != null:
		env.environment.background_color = lay["bg"]
	var fog: Array = lay["fog"]
	Toon.set_fog(fog[0], fog[1] * 0.8, fog[2] * 0.8)


func _setup_battle() -> void:
	var team: Array = []
	for id in PARTY:
		team.append(BattleContent.default_entry(id, level))
	b = BattleState.create_solo("IO", team, [], boss_id, int(Time.get_ticks_msec()) % 100000 + 7)
	var bu: Dictionary = BattleState.boss(b)
	# nella storia la squadra sale di livello e il nemico no: lo si fa crescere insieme (PROVVISORIO, bilanciamento dell'atto 1)
	# obiettivo: boss in 4-6 round, frammenti in 1-2
	if not ritorno.is_empty():
		var grow: float = 1.0 + 0.14 * float(level - 1)
		pv_k *= (1.5 if minore else 2.3) * grow
		atk_k *= 1.0 + 0.09 * float(level - 1)
	if pv_k != 1.0:
		bu["max_hp"] = maxi(1, int(round(float(bu["max_hp"]) * pv_k)))
		bu["hp"] = bu["max_hp"]
	if atk_k != 1.0:
		bu["atk"] = maxi(1, int(round(float(bu["atk"]) * atk_k)))
	# legami del rifugio: +5% attacco alle coppie che hanno passato una serata insieme (PROVVISORIO)
	if not ritorno.is_empty():
		for bd in Story.active_bonds():
			for who in bd.get("chi", []):
				for uid in b["units"]:
					var u: Dictionary = b["units"][uid]
					if str(u.get("char", "")) == str(who):
						Factions.add_mod(u, "legame", "atk", 50, 999)
		Factions.refresh(b)
	for p in b["players"]:
		slots.append(str(p["id"]))
	for uid in b["units"]:
		if str(uid) != BattleState.BOSS_ID:
			b["units"][uid]["gauge"] = START_GAUGE
	if ingresso == "vantaggio":
		# PROVVISORIO: l'attacco a sorpresa toglie due terzi dell'equilibrio (rottura vicina)
		var boss: Dictionary = BattleState.boss(b)
		boss["balance"] = maxi(1, int(ceil(float(boss["balance"]) * 0.35)))


func _build_units() -> void:
	var xs: Array = [-2.55, -0.85, 0.85, 2.55]
	for i in slots.size():
		var u: Dictionary = _slot_unit(i)
		var cv := CharacterVisual.new()
		cv.setup(str(u["char"]))
		add_child(cv)
		var pos := Vector3(xs[i], 0.14, 3.0 + absf(xs[i]) * 0.18)
		cv.position = pos
		cv.stance = true
		_face(cv, ENEMY_POS)
		vis[str(u["id"])] = cv
		home[str(u["id"])] = pos
	var m := VendingVisual.new()
	m.kind = visual
	m.position = ENEMY_POS
	m.rotation.y = PI
	m.awake = true
	add_child(m)
	vis[BattleState.BOSS_ID] = m
	home[BattleState.BOSS_ID] = ENEMY_POS


func _face(n: Node3D, at: Vector3) -> void:
	var d: Vector3 = at - n.position
	n.rotation.y = atan2(-d.x, -d.z)


func _slot_unit(i: int) -> Dictionary:
	var p: Dictionary = BattleState.player(b, str(slots[i]))
	return BattleState.unit(b, str(p["active"]))


func _unit_of(pid: String) -> Dictionary:
	return BattleState.active_unit(b, pid)


func _col(u: Dictionary) -> Color:
	return Ui.BATTLE_COLORS.get(str(u.get("color", "")), Ui.CREAM)


# ---------------------------------------------------------------- camera

func _cam_set(pos: Vector3, look: Vector3, rate: float = 3.0, snap: bool = false) -> void:
	_cam_want_pos = pos
	_cam_want_look = look
	_cam_rate = rate
	if snap:
		_cam_pos = pos
		_cam_look = look


func _cam_overview(snap: bool = false) -> void:
	_cam_set(Vector3(0.6, 3.3, 9.8), Vector3(0, 1.2, -1.6), 2.5, snap)


func _cam_actor(uid: String) -> void:
	# alle spalle, un po' alto e spostato verso il centro: i compagni restano ai lati senza coprire la vista
	var p: Vector3 = home[uid]
	var side: float = -signf(p.x) if absf(p.x) > 0.1 else 1.0
	_cam_set(p + Vector3(side * 0.55, 2.05, 3.2), ENEMY_POS + Vector3(-side * 0.3, 1.25, 0), 3.2)


func _cam_side(a: Vector3, bpos: Vector3) -> void:
	var mid: Vector3 = (a + bpos) * 0.5
	var side: float = 1.0 if a.x >= 0.0 else -1.0
	_cam_set(mid + Vector3(side * 5.2, 2.0, 0.8), mid + Vector3(0, 1.1, 0), 4.0)


func _cam_boss() -> void:
	_cam_set(ENEMY_POS + Vector3(1.8, 3.3, -4.2), Vector3(0, 1.0, 3.0), 3.0)


func _cam_front(uid: String) -> void:
	var p: Vector3 = (vis[uid] as Node3D).position
	_cam_set(p + Vector3(0.35, 1.55, -2.0), p + Vector3(0, 1.45, 0), 6.0, true)


func _process(delta: float) -> void:
	var rd: float = minf(delta, 0.05)
	_cam_pos = _cam_pos.lerp(_cam_want_pos, minf(1.0, rd * _cam_rate))
	_cam_look = _cam_look.lerp(_cam_want_look, minf(1.0, rd * _cam_rate))
	var sh := Vector3.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - rd * 3.0)
		var k: float = _shake * Settings.shake * 0.22
		sh = Vector3(randf_range(-k, k), randf_range(-k, k), randf_range(-k, k) * 0.5)
	cam.position = _cam_pos + sh
	if cam.position.distance_to(_cam_look) > 0.01:
		cam.look_at(_cam_look, Vector3.UP)


func _kick(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _flash(k: float) -> void:
	if _main().has_method("flash"):
		_main().flash(k)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


# Attende un tween solo se sta ancora andando (un tween gia' finito non manda piu' "finished": si resterebbe bloccati)
func _tw_done(tw: Tween) -> void:
	if tw != null and tw.is_valid() and tw.is_running():
		await tw.finished


# ---------------------------------------------------------------- flusso dei turni

func _start_round() -> void:
	if ended or not is_inside_tree():
		return
	SeqRound.begin(b)
	turn_list = SeqRound.order(b)
	if _round1:
		# ingresso: col vantaggio il boss agisce per ultimo nel primo round, con l'agguato per primo
		_round1 = false
		var boss_e: Array = turn_list.filter(func(e: Dictionary) -> bool: return bool(e["boss"]))
		var rest: Array = turn_list.filter(func(e: Dictionary) -> bool: return not bool(e["boss"]))
		if ingresso == "vantaggio":
			turn_list = rest + boss_e
		elif ingresso == "agguato":
			turn_list = boss_e + rest
	turn_i = -1
	_refresh_hud()
	await _advance()


func _advance() -> void:
	while is_inside_tree() and not ended:
		turn_i += 1
		if str(b["winner"]) != "":
			await _end_battle()
			return
		if turn_i >= turn_list.size():
			var ev: Array = SeqRound.finish(b)
			await _show_events(ev, false)
			if str(b["winner"]) != "":
				await _end_battle()
				return
			await _start_round()
			return
		var e: Dictionary = turn_list[turn_i]
		if bool(e["boss"]):
			await _boss_turn()
			continue
		var pid: String = str(e["player"])
		var pl: Dictionary = BattleState.player(b, pid)
		if pl.is_empty() or not BattleState.player_alive(b, pl):
			continue
		cur_pid = pid
		var uid: String = str(_unit_of(pid)["id"])
		_cam_actor(uid)
		_refresh_hud()
		if auto_on:
			await _wait(0.35)
			if not is_inside_tree() or ended:
				return
			await _do_action(pid, BattleAI.choose(b, pid))
			continue
		waiting = true
		_show_commands(true)
		if first_turn:
			first_turn = false
			_hint.text = "ATTACCO ricarica energia · ABILITÀ la spende · ULTIMATE quando la barra è piena"
		return


func _choice_for(move_id: String) -> Dictionary:
	var move: Dictionary = BattleContent.MOVES[move_id]
	var choice: Dictionary = {"swap": "", "move": move_id, "target": "", "order": "", "push": ""}
	if str(move["target"]) == "ally":
		var best: String = cur_pid
		var worst: float = 2.0
		for p in b["players"]:
			var a: Dictionary = BattleState.unit(b, str(p["active"]))
			if BattleState.is_alive(a):
				var r: float = float(a["hp"]) / float(maxi(1, int(a["max_hp"])))
				if r < worst:
					worst = r
					best = str(p["id"])
		choice["target"] = best
	return choice


func _skill_of(u: Dictionary) -> String:
	var def: Dictionary = BattleContent.CHARACTERS.get(str(u["char"]), {})
	return str(def.get("skill", "attack"))


func _usable(move_id: String) -> bool:
	if cur_pid == "" or move_id == "" or not BattleContent.MOVES.has(move_id):
		return false
	return BattleResolver.validate_choice(b, cur_pid, _choice_for(move_id)) == ""


func _command(kind: String) -> void:
	# in pausa (Engine.time_scale = 0) i tasti 1-4 / Spazio non devono far partire l'azione
	if not waiting or ended or _pause != null:
		return
	var u: Dictionary = _unit_of(cur_pid)
	var mv: String = "attack"
	match kind:
		"skill":
			mv = _skill_of(u)
		"ult":
			mv = str(u["ult"])
		"guard":
			mv = "guard"
	if not _usable(mv):
		Settings.buzz(10)
		return
	waiting = false
	_show_commands(false)
	_hint.text = ""
	Settings.buzz(40 if kind == "ult" else 18)
	await _do_action(cur_pid, _choice_for(mv))
	if is_inside_tree() and not ended:
		await _advance()


func _do_action(pid: String, choice: Dictionary) -> void:
	var u: Dictionary = _unit_of(pid)
	var uid: String = str(u["id"])
	var mv: String = str(choice.get("move", "attack"))
	var move: Dictionary = BattleContent.MOVES.get(mv, {})
	var kind: String = str(move.get("kind", "basic"))
	var tgt: String = str(move.get("target", "enemy"))
	var ev: Array = SeqRound.player_action(b, pid, choice)
	var cv: CharacterVisual = vis[uid]
	var col: Color = _col(u)
	if kind == "ult":
		await _play_cutin(u, str(move.get("name", "ULTIMATE")))
	_banner(str(u["name"]).to_upper() + " · " + str(move.get("name", mv)).to_upper(), col)
	if tgt == "enemy":
		var boss_v: Node3D = vis[BattleState.BOSS_ID]
		var strike: Vector3 = ENEMY_POS + (home[uid] - ENEMY_POS).normalized() * 1.7
		strike.y = 0.14
		if kind != "ult":
			_cam_side(home[uid], ENEMY_POS)
		cv.move_speed = 1.0
		var tw := create_tween()
		tw.tween_property(cv, "position", strike, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tw.finished
		cv.move_speed = 0.0
		var a: Tween = cv.cast() if kind != "basic" else cv.attack()
		await _wait(0.22)
		_ring(boss_v.position + Vector3(0, 0.05, 0), col, 2.8 if kind == "ult" else 1.8)
		if kind == "ult":
			_flash(0.9)
			_kick(1.0)
		else:
			_kick(0.45 if kind == "basic" else 0.7)
		await _show_events(ev, true)
		await _tw_done(a)
		cv.move_speed = 1.0
		var back := create_tween()
		back.tween_property(cv, "position", home[uid], 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await back.finished
		cv.move_speed = 0.0
		_face(cv, ENEMY_POS)
	else:
		_cam_front(uid)
		_cam_set(home[uid] + Vector3(0.3, 1.6, -3.0), home[uid] + Vector3(0, 1.2, 0), 4.0)
		var a2: Tween = cv.cast()
		await _wait(0.25)
		_ring(home[uid], col, 2.2)
		if kind == "ult":
			_flash(0.6)
		await _show_events(ev, true)
		await _tw_done(a2)
	_refresh_hud()
	await _wait(0.25)
	# dopo l'inquadratura frontale si stacca di netto (cambio di telecamera): niente viaggio attraverso i compagni
	_cam_overview(tgt != "enemy")


func _boss_turn() -> void:
	cur_pid = ""
	_refresh_hud()
	var tele: Dictionary = b["telegraph"]
	var mv: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	var boss_u: Dictionary = BattleState.boss(b)
	var stunned: bool = int(boss_u.get("stun", 0)) > 0
	_cam_boss()
	await _wait(0.5)
	var ev: Array = SeqRound.boss_action(b)
	var m: VendingVisual = vis[BattleState.BOSS_ID]
	if stunned:
		_banner(_bname() + " · STORDITO, SALTA IL TURNO", Ui.CREAM)
		await _show_events(ev, true)
		await _wait(0.4)
	else:
		_banner(_bname() + " · " + str(mv.get("name", "?")).to_upper(), Ui.YELLOW)
		var all: bool = str(mv.get("target", "one")) == "all"
		var tw: Tween = m.slam() if all else m.attack()
		await _wait(0.42 if all else 0.3)
		if all:
			_ring(ENEMY_POS, Ui.YELLOW, 6.5)
			_flash(0.35)
			_kick(0.9)
		else:
			_kick(0.6)
		await _show_events(ev, true)
		await _tw_done(tw)
	m.stunned = int(BattleState.boss(b).get("stun", 0)) > 0
	_refresh_hud()
	await _wait(0.3)
	_cam_overview()


# ---------------------------------------------------------------- eventi del motore -> effetti

func _show_events(ev: Array, hit_anims: bool) -> void:
	var delay: float = 0.0
	# PV prima di ogni colpo (il motore ha gia' applicato tutto): per sapere chi scende sotto il 50% o il 25% e quando
	var run_hp: Dictionary = {}
	for e in ev:
		if str(e.get("t", "")) == "damage" and not bool(e.get("cost", false)):
			var d0: String = str(e.get("dst", ""))
			if d0 != BattleState.BOSS_ID and b["units"].has(d0):
				run_hp[d0] = int(run_hp.get(d0, int(b["units"][d0]["hp"]))) + int(e.get("amount", 0))
	for e in ev:
		var t: String = str(e.get("t", ""))
		match t:
			"damage":
				var dst: String = str(e.get("dst", ""))
				if bool(e.get("cost", false)):
					continue
				var amt: int = int(e.get("amount", 0))
				var crit: bool = bool(e.get("crit", false))
				_number(dst, ("%d" % amt) + ("!" if crit else ""), Ui.YELLOW if crit else Ui.CREAM, 46 if crit else 38, delay)
				if int(e.get("absorbed", 0)) > 0:
					_number(dst, "SCUDO -%d" % int(e["absorbed"]), Ui.CYAN, 24, delay + 0.1)
				if hit_anims and vis.has(dst):
					var v: Node3D = vis[dst]
					if v.has_method("hit"):
						v.call("hit")
				if run_hp.has(dst):
					# telecamera che si rompe nel momento del colpo, se scende di livello (50% / 25%)
					var u2: Dictionary = b["units"][dst]
					var mx: float = maxf(1.0, float(u2["max_hp"]))
					var before: int = int(run_hp[dst])
					var after: int = maxi(0, before - amt)
					run_hp[dst] = after
					if after > 0 and BrokenCam.tier(float(after) / mx) > BrokenCam.tier(float(before) / mx):
						_shatter_later(str(u2.get("char", dst)), delay, 0.7 if BrokenCam.tier(float(after) / mx) == 1 else 1.0)
				delay += 0.12
			"heal":
				_number(str(e.get("dst", "")), "+%d" % int(e.get("amount", 0)), Color("#62f08c"), 36, delay)
				delay += 0.1
			"shield":
				_number(str(e.get("dst", "")), "SCUDO +%d" % int(e.get("amount", 0)), Ui.CYAN, 28, delay)
				delay += 0.1
			"bleed":
				_number(str(e.get("unit", "")), "-%d" % int(e.get("amount", 0)), Color("#ff5a6e"), 30, delay)
				delay += 0.1
			"status":
				var st: String = str(e.get("status", ""))
				_number(str(e.get("unit", "")), str(STATUS_NAMES.get(st, st.to_upper())), Ui.VIOLET.lightened(0.3), 24, delay + 0.15)
			"buff":
				_number(str(e.get("unit", "")), "POTENZIATO", Color("#ffb04a"), 24, delay + 0.15)
			"debuff":
				_number(BattleState.BOSS_ID, "INDEBOLITO", Color("#b0a0ff"), 24, delay + 0.15)
			"break":
				_shatter_later("boss", delay, 1.0)        # solo l'animazione: lo schermo poi torna pulito
				_toast("ROTTURA! %s è %s" % [_cap(_bn()), _g("stordito", "stordita")], Color.WHITE, 1.6)
				(vis[BattleState.BOSS_ID] as VendingVisual).stunned = true
				_flash(0.5)
				_kick(0.8)
			"phase":
				_toast("FASE %d · %s si arrabbia" % [int(e.get("phase", 2)), _bn()], Ui.PINK, 1.8)
			"down":
				var du: String = str(e.get("unit", ""))
				if vis.has(du):
					var dv: Node3D = vis[du]
					if dv.has_method("ko"):
						dv.call("ko")
	_refresh_hud()
	await _wait(0.35 + delay)


func _number(uid: String, text: String, col: Color, size: int, delay: float) -> void:
	if not vis.has(uid):
		return
	var v: Node3D = vis[uid]
	var p3: Vector3 = v.call("head_point") if v.has_method("head_point") else v.global_position
	var l := Ui.label(text, size, col, Ui.display(), 10)
	l.modulate.a = 0.0
	_fx_layer.add_child(l)
	var jitter := Vector2(randf_range(-30, 30), randf_range(-10, 10))
	var tw := l.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		if cam.is_position_behind(p3):
			l.queue_free()
			return
		l.position = cam.unproject_position(p3) - l.get_combined_minimum_size() * 0.5 + jitter
		l.modulate.a = 1.0
		l.scale = Vector2(1.3, 1.3)
		l.pivot_offset = l.get_combined_minimum_size() * 0.5)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15)
	tw.parallel().tween_property(l, "position:y", -70.0, 0.9).as_relative()
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)


func _ring(at: Vector3, col: Color, radius: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = MeshBatch.disc(1.0, Color(col.r, col.g, col.b, 0.7 if not Settings.light_fx else 0.4), 20, 0.05)
	mi.material_override = Toon.glow()
	mi.position = at
	mi.scale = Vector3(0.2, 1, 0.2)
	add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius), 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "transparency", 1.0, 0.3)
	tw.tween_callback(mi.queue_free)


# Sequenza dell'ultimate: primo piano, fascia colorata, nome e battuta. Si salta con l'impostazione.
func _play_cutin(u: Dictionary, ult_name: String) -> void:
	Breadcrumb.mark("ultimate")
	var uid: String = str(u["id"])
	var col: Color = _col(u)
	if Settings.skip_cutin:
		_toast("ULTIMATE · " + ult_name.to_upper(), col, 1.0)
		return
	_cam_front(uid)
	var cv: CharacterVisual = vis[uid]
	cv.cheer()
	_cutin.visible = true
	var band: ColorRect = _cutin.get_node("Band")
	var name_l: Label = _cutin.get_node("Name")
	var line_l: Label = _cutin.get_node("Line")
	band.color = Color(col.r, col.g, col.b, 0.85)
	name_l.text = str(u["name"]).to_upper() + " · " + ult_name.to_upper()
	line_l.text = "«" + DialogData.ult_line(str(u["char"])) + "»"
	_cutin.modulate.a = 0.0
	band.position.x = -_root.size.x
	var tw := create_tween()
	tw.tween_property(_cutin, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(band, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(_cutin, "modulate:a", 0.0, 0.18)
	await tw.finished
	_cutin.visible = false
	Breadcrumb.mark("battaglia")


# ---------------------------------------------------------------- fine

func _shatter_later(key: String, delay: float, strength: float) -> void:
	if _broken == null:
		return
	if delay > 0.01:
		await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		_broken.shatter(key, strength)


# Telecamera rotta: conta solo chi e' di turno (turno del nemico e fine battaglia = telecamera pulita)
func _update_broken_cam() -> void:
	if _broken == null:
		return
	if cur_pid == "" or ended:
		_broken.show_for("", 1.0)
		return
	var u: Dictionary = _unit_of(cur_pid)
	if u.is_empty():
		_broken.show_for("", 1.0)
		return
	_broken.show_for(str(u.get("char", cur_pid)), float(u["hp"]) / maxf(1.0, float(u["max_hp"])))


func _end_battle() -> void:
	if ended:
		return
	ended = true
	waiting = false
	cur_pid = ""
	_show_commands(false)
	_refresh_hud()
	Breadcrumb.mark("risultato")
	var win: bool = str(b["winner"]) == "players"
	await _wait(0.6)
	if not is_inside_tree():
		return
	Engine.time_scale = 1.0
	_cam_set(Vector3(0, 2.2, 7.2), Vector3(0, 1.2, 3.0), 2.0)
	if win:
		for uid in vis:
			if uid != BattleState.BOSS_ID and not (vis[uid] as CharacterVisual).down:
				(vis[uid] as CharacterVisual).cheer()
	# nella demo dal menu: due battute in stile Persona; nella storia ci pensa la scena dopo
	if ritorno.is_empty():
		var dlg := DialogBox.new()
		_root.add_child(dlg)
		await get_tree().process_frame
		var key: String = "vittoria" if win else "sconfitta"
		dlg.play(DialogData.lines(key), DialogData.recap(key))
		await dlg.finished
		if not is_inside_tree():
			return
	var ln: Array = []
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.box(Color(0.07, 0.04, 0.12, 0.95), Ui.CREAM, 4, 6, 8))
	Ui.place(panel, 0.5, 0.5, 0.5, 0.5, -340, -170, 340, 170)
	_root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var t := Ui.label("VITTORIA" if win else "SCONFITTA", 54, Ui.YELLOW if win else Color("#ff7a9c"), Ui.display(), 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	if not ln.is_empty():
		var d: Dictionary = ln[0]
		var q := Ui.label("%s: «%s»" % [str(d.get("chi", "")), str(d.get("testo", ""))], 22, Ui.CREAM)
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(q)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 16)
	vb.add_child(hb)
	if not ritorno.is_empty():
		if win:
			var c := Ui.button("CONTINUA", Ui.YELLOW, 26, 240)
			c.pressed.connect(_continue_story)
			hb.add_child(c)
		else:
			var r2 := Ui.button("RIPROVA", Ui.YELLOW, 24, 220)
			r2.pressed.connect(func() -> void: _main().go("battle", _args))
			hb.add_child(r2)
			var back := Ui.button("TORNA ALL'AREA", Ui.CREAM, 22, 260)
			back.pressed.connect(func() -> void: _main().go("area", {"area": str(ritorno.get("area", "")), "resume": ritorno.get("perso", {})}))
			hb.add_child(back)
	else:
		var r := Ui.button("RIPROVA", Ui.YELLOW, 24, 220)
		r.pressed.connect(func() -> void: _main().go("battle", {"from": from}))
		hb.add_child(r)
		var m := Ui.button("MENU", Ui.CREAM, 24, 220)
		m.pressed.connect(func() -> void: _main().go("menu"))
		hb.add_child(m)


func _continue_story() -> void:
	if str(ritorno.get("tipo", "")) == "area":
		_main().go("area", {"area": str(ritorno.get("area", "")), "resume": ritorno.get("vinto", {})})
	else:
		Story.flags.erase("debolezza_nota")
		Story.advance()
		_main().next_story()


# ---------------------------------------------------------------- interfaccia

func _build_ui() -> void:
	_broken = BrokenCam.new()
	add_child(_broken)
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	_root = Control.new()
	Ui.place(_root, 0, 0, 1, 1)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	_fx_layer = Control.new()
	Ui.place(_fx_layer, 0, 0, 1, 1)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fx_layer)

	# ordine dei turni (sinistra)
	var ob := PanelContainer.new()
	ob.add_theme_stylebox_override("panel", Ui.box(Color(0.06, 0.03, 0.1, 0.72), Ui.INK, 3, 6, 0))
	ob.position = Vector2(16, 70 if Settings.show_fps else 16)
	_root.add_child(ob)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 4)
	ob.add_child(ov)
	var ot := Ui.label("TURNI", 16, Color(1, 1, 1, 0.6), Ui.display())
	ov.add_child(ot)
	_order_box = VBoxContainer.new()
	_order_box.add_theme_constant_override("separation", 4)
	ov.add_child(_order_box)

	# nemico (alto al centro)
	var bp := VBoxContainer.new()
	Ui.place(bp, 0.5, 0, 0.5, 0, -300, 14, 300, 140)
	bp.add_theme_constant_override("separation", 4)
	bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bp)
	_boss_name = Ui.label(_bname(), 28, Ui.YELLOW, Ui.display(), 8)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bp.add_child(_boss_name)
	_boss_hp = _bar(Color("#ff4b6e"), 22)
	bp.add_child(_boss_hp)
	_boss_hp_txt = Ui.label("", 18, Ui.CREAM, null, 5)
	_boss_hp_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hp.add_child(_boss_hp_txt)
	Ui.place(_boss_hp_txt, 0, 0, 1, 1)
	_boss_hp_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_brk = _bar(Color("#f2f0ea"), 10)
	bp.add_child(_boss_brk)
	_tele = Ui.label("", 20, Ui.CREAM, null, 6)
	_tele.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bp.add_child(_tele)

	# squadra (basso a sinistra)
	var party := HBoxContainer.new()
	Ui.place(party, 0, 1.0, 0, 1.0, 16, -150, 760, -14)
	party.add_theme_constant_override("separation", 8)
	party.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(party)
	for i in slots.size():
		var card := _make_card()
		party.add_child(card["panel"])
		_cards.append(card)

	# comandi (basso a destra)
	_cmd_box = VBoxContainer.new()
	Ui.place(_cmd_box, 1.0, 1.0, 1.0, 1.0, -330, -330, -16, -14)
	_cmd_box.alignment = BoxContainer.ALIGNMENT_END
	_cmd_box.add_theme_constant_override("separation", 8)
	_root.add_child(_cmd_box)
	_btn_ult = Ui.button("ULTIMATE", Ui.PINK, 26)
	_btn_ult.pressed.connect(_command.bind("ult"))
	_cmd_box.add_child(_btn_ult)
	_btn_skill = Ui.button("ABILITÀ", Ui.CYAN, 24)
	_btn_skill.pressed.connect(_command.bind("skill"))
	_cmd_box.add_child(_btn_skill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_cmd_box.add_child(row)
	_btn_guard = Ui.button("GUARDIA", Ui.CREAM, 20)
	_btn_guard.pressed.connect(_command.bind("guard"))
	_btn_guard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_btn_guard)
	_btn_atk = Ui.button("ATTACCO", Ui.YELLOW, 28)
	_btn_atk.pressed.connect(_command.bind("attack"))
	_btn_atk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_atk.size_flags_stretch_ratio = 1.6
	row.add_child(_btn_atk)
	_show_commands(false)

	_turn_lbl = Ui.label("", 30, Ui.CREAM, Ui.display(), 10)
	Ui.place(_turn_lbl, 1.0, 1.0, 1.0, 1.0, -600, -385, -16, -340)
	_turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_turn_lbl)
	_hint = Ui.label("", 20, Color(1, 1, 1, 0.85), null, 6)
	Ui.place(_hint, 0.5, 0.62, 0.5, 0.62, -420, 0, 420, 60)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_hint)

	# in alto a destra: pausa, AUTO, velocita'
	var tr := HBoxContainer.new()
	Ui.place(tr, 1.0, 0, 1.0, 0, -400, 14, -16, 80)
	tr.alignment = BoxContainer.ALIGNMENT_END
	tr.add_theme_constant_override("separation", 8)
	_root.add_child(tr)
	_btn_fast = Ui.button("x1", Ui.CREAM, 20, 70)
	_btn_fast.pressed.connect(_toggle_fast)
	tr.add_child(_btn_fast)
	_btn_auto = Ui.button("AUTO", Ui.CREAM, 20, 100)
	_btn_auto.pressed.connect(_toggle_auto)
	tr.add_child(_btn_auto)
	var pb := Ui.button("II", Ui.CREAM, 24, 70)
	pb.pressed.connect(_open_pause)
	tr.add_child(pb)

	# sequenza dell'ultimate
	_cutin = Control.new()
	Ui.place(_cutin, 0, 0, 1, 1)
	_cutin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin.visible = false
	_root.add_child(_cutin)
	var dark := ColorRect.new()
	dark.color = Color(0.02, 0.0, 0.05, 0.35)
	Ui.place(dark, 0, 0, 1, 1)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin.add_child(dark)
	var band := ColorRect.new()
	band.name = "Band"
	Ui.place(band, 0, 0.66, 1.0, 0.84, 0, 0, 0, 0)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin.add_child(band)
	var nl := Ui.label("", 44, Ui.CREAM, Ui.display(), 12)
	nl.name = "Name"
	Ui.place(nl, 0.05, 0.66, 0.95, 0.66, 0, 8, 0, 64)
	_cutin.add_child(nl)
	var ll := Ui.label("", 26, Ui.CREAM, null, 8)
	ll.name = "Line"
	Ui.place(ll, 0.05, 0.66, 0.95, 0.66, 0, 70, 0, 110)
	_cutin.add_child(ll)


func _bar(col: Color, h: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, h)
	pb.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.03, 0.08, 0.85)
	bg.border_color = Ui.INK
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


func _make_card() -> Dictionary:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(176, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(vb)
	var name_l := Ui.label("", 22, Ui.CREAM, Ui.display(), 6)
	vb.add_child(name_l)
	var hp := _bar(Color("#62f08c"), 16)
	vb.add_child(hp)
	var hp_t := Ui.label("", 16, Ui.CREAM, null, 4)
	vb.add_child(hp_t)
	var en := Ui.label("", 18, Ui.CYAN, null, 4)
	vb.add_child(en)
	var ult := _bar(Ui.PINK, 10)
	vb.add_child(ult)
	return {"panel": p, "name": name_l, "hp": hp, "hp_t": hp_t, "en": en, "ult": ult}


func _show_commands(on: bool) -> void:
	if _cmd_box == null:
		return
	_cmd_box.visible = on
	if not on:
		return
	var u: Dictionary = _unit_of(cur_pid)
	var sk: String = _skill_of(u)
	var skm: Dictionary = BattleContent.MOVES.get(sk, {})
	_btn_atk.disabled = not _usable("attack")
	_btn_guard.disabled = not _usable("guard")
	_btn_skill.text = "%s  ·  %d EN" % [str(skm.get("name", "ABILITÀ")).to_upper(), int(skm.get("cost", 0))]
	_btn_skill.disabled = not _usable(sk)
	var ult_ok: bool = _usable(str(u.get("ult", "")))
	_btn_ult.disabled = not ult_ok
	var um: Dictionary = BattleContent.MOVES.get(str(u.get("ult", "")), {})
	_btn_ult.text = ("ULTIMATE · " + str(um.get("name", "")).to_upper()) if ult_ok else "ULTIMATE  %d%%" % int(u.get("gauge", 0))


func _refresh_hud() -> void:
	if _boss_hp == null:
		return
	_update_broken_cam()
	var boss: Dictionary = BattleState.boss(b)
	_boss_hp.max_value = int(boss["max_hp"])
	_boss_hp.value = int(boss["hp"])
	_boss_hp_txt.text = "%d / %d" % [int(boss["hp"]), int(boss["max_hp"])]
	_boss_brk.max_value = maxi(1, int(boss.get("balance_max", 1)))
	_boss_brk.value = int(boss.get("balance", 0))
	var tele: Dictionary = b.get("telegraph", {})
	var mv: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	var who: String = "TUTTI"
	if str(mv.get("target", "one")) != "all":
		var tu: Dictionary = BattleState.active_unit(b, str(tele.get("target", "")))
		who = str(tu.get("name", "?")).to_upper()
	if ended or not BattleState.is_alive(boss):
		_tele.text = ""
	elif int(boss.get("stun", 0)) > 0:
		_tele.text = "STORDITO: salterà il prossimo turno"
	else:
		_tele.text = "Prossima mossa: %s su %s" % [str(mv.get("name", "?")).to_upper(), who] if not mv.is_empty() else ""
	for i in _cards.size():
		var c: Dictionary = _cards[i]
		var u: Dictionary = _slot_unit(i)
		var active: bool = str(slots[i]) == cur_pid
		var alive: bool = BattleState.is_alive(u)
		var col: Color = _col(u)
		(c["panel"] as PanelContainer).add_theme_stylebox_override("panel",
			Ui.box(Color(0.08, 0.05, 0.14, 0.9) if not active else col.darkened(0.55), col if active else Ui.INK, 4 if active else 3, 6, 5))
		(c["panel"] as Control).modulate.a = 1.0 if alive else 0.45
		(c["name"] as Label).text = str(u["name"]).to_upper() + ("  KO" if not alive else "")
		(c["name"] as Label).add_theme_color_override("font_color", col.lightened(0.3))
		(c["hp"] as ProgressBar).max_value = int(u["max_hp"])
		(c["hp"] as ProgressBar).value = int(u["hp"])
		(c["hp_t"] as Label).text = "PV %d/%d" % [int(u["hp"]), int(u["max_hp"])]
		var en: int = int(u.get("energy", 0))
		(c["en"] as Label).text = "ENERGIA %d/%d" % [en, BattleTypes.MAX_ENERGY]
		(c["ult"] as ProgressBar).max_value = BattleTypes.GAUGE_MAX
		(c["ult"] as ProgressBar).value = int(u.get("gauge", 0))
	# ordine dei turni rimasti in questo round
	for ch in _order_box.get_children():
		ch.queue_free()
	var start: int = maxi(0, turn_i)
	for k in range(start, turn_list.size()):
		var e: Dictionary = turn_list[k]
		var uu: Dictionary = BattleState.unit(b, str(e["unit"]))
		if not BattleState.is_alive(uu):
			continue
		var is_boss: bool = bool(e["boss"])
		var nm: String = _bname() if is_boss else str(uu.get("name", "?")).to_upper()
		var l := Ui.label(("> " if k == turn_i else "   ") + nm, 20 if k == turn_i else 17, Ui.YELLOW if is_boss else _col(uu).lightened(0.25), Ui.display() if k == turn_i else null, 4)
		_order_box.add_child(l)
	var nxt := Ui.label("   — round %d —" % int(b.get("round", 1)), 14, Color(1, 1, 1, 0.5))
	_order_box.add_child(nxt)
	_turn_lbl.text = ("TURNO DI " + str(_unit_of(cur_pid).get("name", "")).to_upper()) if cur_pid != "" and not ended else ""
	if waiting:
		_show_commands(true)


func _banner(text: String, col: Color) -> void:
	var l := Ui.label(text, 30, col, Ui.display(), 10)
	Ui.place(l, 0.5, 0.2, 0.5, 0.2, -500, 0, 500, 50)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fx_layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


func _toast(text: String, col: Color, sec: float) -> void:
	var l := Ui.label(text, 26, col, Ui.display(), 10)
	Ui.place(l, 0.5, 0.3, 0.5, 0.3, -560, 0, 560, 80)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fx_layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(sec)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


func _toggle_auto() -> void:
	if _pause != null:
		return
	auto_on = not auto_on
	_btn_auto.text = "AUTO ON" if auto_on else "AUTO"
	if auto_on and waiting:
		waiting = false
		_show_commands(false)
		await _do_action(cur_pid, BattleAI.choose(b, cur_pid))
		if is_inside_tree() and not ended:
			await _advance()


func _toggle_fast() -> void:
	if _pause != null:
		return
	fast = not fast
	Engine.time_scale = 1.8 if fast else 1.0
	_btn_fast.text = "x2" if fast else "x1"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		match k:
			KEY_ESCAPE:
				if _pause != null:
					_close_pause()
				else:
					_open_pause()
			KEY_1, KEY_SPACE, KEY_ENTER:
				_command("attack")
			KEY_2:
				_command("skill")
			KEY_3:
				_command("ult")
			KEY_4:
				_command("guard")


func back() -> void:
	if _pause != null:
		_close_pause()
	else:
		_open_pause()


func _open_pause() -> void:
	if _pause != null:
		return
	Engine.time_scale = 0.0          # ferma animazioni e timer della battaglia
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.05, 0.7)
	Ui.place(shade, 0, 0, 1, 1)
	_root.add_child(shade)
	_pause = shade
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	Ui.place(vb, 0.5, 0.5, 0.5, 0.5, -200, -150, 200, 150)
	shade.add_child(vb)
	var t := Ui.label("PAUSA", 40, Ui.YELLOW, Ui.display(), 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var b1 := Ui.button("RIPRENDI", Ui.YELLOW, 26)
	b1.pressed.connect(_close_pause)
	vb.add_child(b1)
	var b2 := Ui.button("IMPOSTAZIONI", Ui.CREAM, 22)
	b2.pressed.connect(func() -> void: shade.add_child(SettingsPanel.new()))
	vb.add_child(b2)
	var b3 := Ui.button("ESCI DAL COMBATTIMENTO", Color("#ff7a9c"), 20)
	b3.pressed.connect(func() -> void:
		Engine.time_scale = 1.0
		_main().go("menu"))
	vb.add_child(b3)


func _close_pause() -> void:
	if _pause != null:
		_pause.queue_free()
		_pause = null
	Engine.time_scale = 1.8 if fast else 1.0
