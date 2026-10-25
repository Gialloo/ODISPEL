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
const PARTY_Z: float = 4.3                 # fila della squadra: piu' indietro (prima 3.0) per dare respiro tra squadra e nemico

# GUARDIA A TEMPO: quando parte il colpo annunciato un cerchio si chiude sul bersaglio; toccare quando si chiude
# riduce il danno e carica l'ultimate, toccare proprio all'impatto e' una parata perfetta con contrattacco.
# Tempi in secondi REALI (non cambiano con x2): la finestra deve restare leggibile anche accelerando.
# Spiegazioni della storia a gruppi, nell'ordine: un gruppo si apre quando i precedenti sono visti.
# Dieci spiegazioni nel primo scontro erano troppe (analisi del 24/10): cosi' arrivano due alla volta, quando servono.
const LEZIONI: Array = [["tut_intro", "tut_attacco"], ["tut_guardia", "tut_abilita"], ["tut_telegrafo", "tut_qte"],
	["tut_reazioni", "tut_rottura"], ["tut_ultimate", "tut_extra"]]
const LEZIONI_MAX: int = 2
const FEINT_AFTER: int = 2            # parate perfette di fila prima della FINTA del nemico
const FEINT_LEAD: float = 1.5         # con la FINTA l'impatto arriva dopo il 50% di tempo in piu'
const STAMP_AY: float = 0.58          # UN posto per i timbri grandi (DEBOLEZZA, SLANCIO, IN DIRETTA...): sotto il cerchio della parata, lontano dalla ruota
const TOAST_MAX: int = 2              # avvisi sulla lastra scura visibili insieme
const NOTICE_Y: float = 64.0          # avvisi in alto a sinistra (Persona 5: nome della mossa e "Attacco su!"), sotto l'etichetta REC
const QTE_LEAD: float = 0.9          # dall'apparire del cerchio all'impatto
const QTE_GOOD: float = 0.3          # quanto prima dell'impatto vale gia' come guardia
const QTE_LATE: float = 0.12         # tolleranza dopo l'impatto
const QTE_PERFECT: float = 0.08      # +- attorno all'impatto per la parata perfetta

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
const FOV_BASE: float = 58.0
var _pinched: bool = false                # il FOV e' stretto dalla scossa: va riportato a FOV_BASE
var _boss_known: bool = false             # il giocatore conosce il colore del boss (indizio o primo colpo)
var ritorno: Dictionary = {}             # dove tornare: area (nemico minore), storia (boss), niente = demo dal menu
var minore: bool = false
var tutorial: bool = false            # TUTORIAL dal menu: Echo e la squadra spiegano ogni meccanica in un solo scontro
var primo: bool = false               # primo scontro della storia: nemico che picchia piano
var lezioni: bool = false             # storia: le stesse spiegazioni a rate, al massimo LEZIONI_MAX per scontro
var _lez_ora: int = 0                 # spiegazioni date in questo scontro
var _tut_done: Dictionary = {}        # spiegazioni gia' date
var _tut_dlg: DialogBox = null        # spiegazione aperta (le prove automatiche la saltano)
var _tut_turns: int = 0               # turni del giocatore visti nel tutorial
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
var first_qte: bool = true
var _duo_pick: String = ""           # tecnica combinata scelta nel menu ABILITA' (vale per un'azione)
var _perfect_streak: int = 0         # parate perfette di fila: a 2 il nemico prova una FINTA (contromossa, non un taglio alla parata)
var _qte_on: bool = false
var _qte_t: float = 0.0
var _qte_lead: float = QTE_LEAD      # la prima volta il cerchio e' piu' lento, per leggere l'indicazione
var _qte_good: float = QTE_GOOD      # Al secondo (Lance): finestre piu' larghe sui colpi che prende lui
var _qte_perfect: float = QTE_PERFECT
var _qte_late: float = QTE_LATE
var _stamp_free_ms: int = 0          # i timbri si mettono in coda: uno alla volta, mai uno sopra l'altro
var _stamps: Array = []              # timbri a schermo (si nascondono mentre c'e' il cerchio della parata)
var _qte_start_us: int = 0           # orologio vero della guardia (Time.get_ticks_usec)
var _qte_paused_us: int = 0
var _qte_pause_at: int = 0
var _qte_grade: String = ""          # "" = nessun tocco | early | good | perfect
var _qte_ring: QteRing

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
var _glitch: GlitchFx
var _order_box: BoxContainer
var _boss_name: Label
var _boss_hp: ProgressBar
var _boss_hp_txt: Label
var _boss_brk: ProgressBar
var _brk_lbl: Label
var _brk_near: bool = false           # equilibrio quasi a zero: la barra si accende e pulsa (il Break e' vicino)
var _brk_tw: Tween
var _tele: Label
var _tele_state: String = ""           # come e' vestita la minaccia ora: normale | forte | stordito (la lastra si cambia solo se cambia)
var _weak_row: HBoxContainer           # DEBOLE A: sotto le barre del nemico, come l'analisi di Persona (??? finche' non si sa)
var _weak_k: Label
var _weak_v: Label
var _weak_sig: String = ""
var _boss_ghost: ProgressBar           # scia chiara dietro la barra PV: si vede quanto ha tolto il colpo, poi si svuota
var _statics: Dictionary = {}          # unit id -> StaticFx: disturbo a scatti su chi e' rotto (BREAK del nemico, compagno KO)
var _order_chips: Dictionary = {}      # lastre dell'ordine dei turni gia' costruite (colore|di turno -> StyleBox)
var _cards: Array = []
var _turn_lbl: Label
var _cmd_box: VBoxContainer
var _btn_atk: Button
var _btn_skill: Button
var _btn_ult: Button
var _btn_guard: Button
var _react_box: VBoxContainer        # REAZIONE: compare solo quando il boss carica un colpo (o c'e' un caduto da soccorrere)
var _react_lbl: Label
var _react_btns: Dictionary = {}      # id reazione -> pulsante
var _react_hint_seen: bool = false
var _live_btns: Array = []            # ULTIMATE IN DIRETTA: un pulsante per compagno con la barra piena (fuori turno, durante una carica)
var _freeze_on: bool = false            # fermo immagine di Echo in corso (si salta con un tocco)
var _freeze_skip: bool = false
var _team_on: bool = false              # sequenza dell'attacco di squadra in corso (un tocco la accorcia)
var _team_follow: bool = false          # gli eventi mostrati ora sono seguiti dall'attacco di squadra
var _team_hold: int = 0                  # danni di squadra non ancora mostrati: la barra del nemico scende colpo per colpo
var _live_back: String = ""             # chi stava scegliendo quando e' partita un'Ultimate in diretta
var _quick: bool = false              # turno rapido (SLANCIO): solo ATTACCO o GUARDIA
const REACT_SHORT: Dictionary = {"schivata": "SCHIVA", "intercettazione": "COPRI", "interruzione": "FERMA", "soccorso": "SOCCORRI"}
var _btn_auto: Button
var _skill_menu: SkillMenu = null     # menu ABILITA' aperto (Persona 5)
var _skill_pick: Dictionary = {}       # id unita' -> abilita' scelta nel menu (resta per la battaglia, come il cursore di Persona)
var _order_panel: Control              # ordine dei turni (si vede solo mentre si sceglie)
var _boss_panel: Control               # nome e barre del nemico (in alto a sinistra)
var _choice_hud: bool = false          # true: HUD della scelta; false: durante le mosse resta solo il necessario
var _top_bar: Control                   # x1 / AUTO / pausa: si nasconde mentre parla Echo (il SALTA del dialogo sta li')
var _legend: Control                    # ruota dei colori spiegata: si apre col tasto COLORI
var _btn_fast: Button
var _hint: Label
var _say_lbl: Label                   # battute dei personaggi in battaglia
var _say_balloon: EchoBalloon
var _say_seq: int = 0
var _order_title: Label               # «TURNO n»: il giocatore tiene il conto dei round
var _party_back: Control
var _party_mesh: ArrayMesh      # va tenuta viva finche' si vede
var _reticle: Reticle                    # mirino sul nemico quando tocca al giocatore
var _pop_key: String = ""               # ultimo turno annunciato con lo scatto (evita di rifarlo a ogni aggiornamento)
var _pop_tw: Tween
var _kit_lbl: Label                   # cosa fa l'Abilita' di chi e' di turno e il suo tratto
var _wheel: CmdWheel                  # ruota dei comandi attorno a chi e' di turno (HUD della V2)
var _spot: ColorRect                  # riflettore: la scena si scurisce attorno a chi sceglie
var _picked: String = ""              # comando scelto e non ancora confermato
var _cutin: Control
var _cutin_on: bool = false               # cut-in dell'ultimate in corso (si salta con un tocco)
var _cutin_tw: Tween
var _cutin_seen: Dictionary = {}          # personaggi di cui hai gia' visto il cut-in: dalla seconda volta e' piu' breve
signal _cutin_end
var _pause: Control
var _pause_hid: Array = []             # cio' che la pausa ha nascosto
var _cam_hud: CamHud                  # lo sguardo di Echo: mirino, REC, numero della telecamera
var _glyph: LightFx                   # cerchio di luce sotto chi e' di turno
var _mark: LightFx                    # segnalino ai piedi del bersaglio annunciato dal boss
var _mark_uid: String = ""
var _boss_acting: bool = false        # il boss sta agendo: il segnalino resta spento
var _seal: LightFx                    # sigillo magenta sotto l'Anomalia
var _syn_msgs: Array = []             # sinergie attive (menu SQUADRA), annunciate all'inizio
var _exp_report: Array = []           # esperienza e livelli guadagnati (fine scontro)
var _cam_lim: float = 99.0            # quanto la telecamera puo' allontanarsi di lato (vicoli e caveau: i muri sono vicini)
var _row_k: float = 1.0               # la fila della squadra si stringe nelle arene strette


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
	# REPLICA DELLA DIRETTA (nuovo giro): i nemici sono piu' duri a ogni giro, PV e attacco x(1 + REPLICA_K * giro) fino al giro REPLICA_K_GIRI
	var replica_k: float = BattleTypes.replica_hard(int(args.get("replica", 0)))
	pv_k *= replica_k
	atk_k *= replica_k
	arena = str(args.get("arena", "strada"))
	weak = args.get("debolezze", [])
	if indizi.has("scontrino") and not weak.has("VIOLA"):
		weak = weak + ["VIOLA"]
	ritorno = args.get("ritorno", {})
	minore = bool(args.get("minore", false))
	# la storia chiede "tutorial" per il primo scontro; il tutorial completo e' solo quello del menu
	primo = bool(args.get("tutorial", false)) and str(args.get("from", "")) != "menu"
	tutorial = bool(args.get("tutorial", false)) and not primo
	lezioni = not tutorial and not ritorno.is_empty() and _lezioni_attive()
	if tutorial:
		# TUTORIAL: nemico che picchia piano e dura abbastanza da mostrare tutto (le spiegazioni arrivano quando serve)
		atk_k *= 0.5
		pv_k *= 2.2
	elif primo:
		atk_k *= 0.5       # primo scontro della storia: piano, ma corto (spiega solo schermo e ATTACCO)


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
	cam.fov = FOV_BASE
	cam.near = 0.1
	cam.far = 120.0
	add_child(cam)
	cam.current = true
	_cam_overview(true)
	_build_ui()
	_warm_fonts()
	_refresh_hud()
	Breadcrumb.mark("battaglia")
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	if not Settings.skip_cutin:
		var chs: Array = []
		for i in 4:
			var wu: Dictionary = _slot_unit(i)
			if not wu.is_empty() and not chs.has(str(wu["char"])):
				chs.append(str(wu["char"]))
		EdgeCutin.warm(_root, chs)          # riscalda shader e mesh del cut-in senza bloccare l'ingresso (scatto sul telefono)
	# la strada di questo nemico verso il BREAK, detta una volta all'inizio (poi resta tra i suggerimenti)
	var brk_rule: Dictionary = BreakRules.of(BattleState.boss(b))
	if not brk_rule.is_empty():
		_notice("%s · %s" % [str(brk_rule["name"]), str(brk_rule["short"])], Ui.YELLOW, 4.0, "fx")      # corto: l'avviso taglia oltre 34 lettere
	match ingresso:
		"vantaggio":
			_toast("ATTACCO A SORPRESA! %s è già %s al BREAK e agite per primi" % [_cap(_bn()), _g("vicino", "vicina")], Ui.YELLOW, 3.0)
		"agguato":
			_toast("AGGUATO! %s attacca per %s" % [_cap(_bn()), _g("primo", "prima")], Color("#ff7a9c"), 3.0)
	await get_tree().create_timer(0.4).timeout
	var bonds: Array = Story.active_bonds() if not ritorno.is_empty() else []
	var msgs: Array = []
	if not weak.is_empty():
		msgs.append(["INDIZIO: %s teme il %s. Fai colpire %s." % [_bn(), str(weak[0]), _who_is(str(weak[0]))], Ui.CYAN])
	for bd in bonds:
		msgs.append(["LEGAME · %s: +5%% attacco a entrambi" % str(bd.get("nome", "")), Ui.PINK])
	for sm in _syn_msgs:
		msgs.append([str(sm), Ui.YELLOW])
	var delay: float = 3.4 if ingresso != "normale" else 0.0
	for m in msgs:
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_inside_tree():
				_toast(str(m[0]), m[1], 2.8))
		delay += 3.0
	if tutorial or lezioni:
		await _tut("tut_intro")
		await _tut("tut_telegrafo")
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
		add_child(SkyDome.make("strada"))
		_cam_lim = 7.2
		_night_dress("strada", {"wall_x": 7.0, "z0": 10.0, "z1": -22.0, "seed": 41, "count": 3, "road_half": 4.0, "side_y": 0.16})
		return
	# arene delle altre aree: stessa scenografia dell'esplorazione (interno Anomalia, vicolo, galleria, caveau)
	var layout: String = "anomalia" if arena.begins_with("anomalia") or arena in ["rosso", "blu", "verde"] else arena
	var tema: String = arena.replace("anomalia_", "")
	var lay: Dictionary = LayoutBuilder.build(layout, 5, tema, self)
	# arene coi muri vicini (vicolo, caveau, galleria): la telecamera resta dentro e la fila si stringe,
	# altrimenti le inquadrature di lato finivano dietro i muri e non si vedeva chi attaccava
	if layout in ["vicolo", "caveau", "galleria"]:
		var half: float = (lay["bounds"] as Rect2).size.x * 0.5
		_cam_lim = half - 0.15
		_row_k = clampf((_cam_lim - 0.7) / 3.3, 0.5, 1.0)
	else:
		_cam_lim = 6.6
	if SkyDome.outdoor(layout):
		add_child(SkyDome.make(layout))
	var env: WorldEnvironment = null
	for c in get_children():
		if c is WorldEnvironment:
			env = c
	if env != null:
		env.environment.background_color = lay["bg"]
	var fog: Array = lay["fog"]
	Toon.set_fog(fog[0], fog[1] * 0.8, fog[2] * 0.8)
	var half: float = (lay["bounds"] as Rect2).size.x * 0.5
	match layout:
		"vicolo":
			_night_dress(layout, {"wall_x": 3.4, "z0": 7.0, "z1": -16.0, "seed": 5, "count": 3, "road_half": 2.0, "side_y": 0.16}, env)
		"galleria", "caveau":
			_night_dress(layout, {"wall_x": half + 0.3, "z0": 7.0, "z1": -14.0, "seed": 9, "count": 3, "road_half": 99.0, "side_y": 0.03, "rain": false}, env)
		"tangenziale":
			_night_dress(layout, {"wall_x": half + 1.2, "z0": 7.0, "z1": -18.0, "seed": 13, "count": 3, "road_half": 99.0, "side_y": 0.03}, env)


# Notte «Ghost Stride»: buio, nebbia verde-acqua, 2-4 neon con riflessi a terra e pioggia fine (night_fx.gd)
func _night_dress(_layout: String, o: Dictionary, env: WorldEnvironment = null) -> void:
	if env == null:
		for c in get_children():
			if c is WorldEnvironment:
				env = c
	NightFx.darken_env(env.environment if env != null else null, 9.0, 42.0)
	NightFx.apply(self, o)


func _setup_battle() -> void:
	var team: Array = []
	for id in PARTY:
		# nella storia ognuno ha il suo livello e cio' che ha equipaggiato nel menu SQUADRA; la demo dal menu resta com'era
		team.append(Progress.entry_for(id) if not ritorno.is_empty() else BattleContent.default_entry(id, level))
	b = BattleState.create_solo("IO", team, [], boss_id, int(Time.get_ticks_msec()) % 100000 + 7)
	var bu: Dictionary = BattleState.boss(b)
	# nella storia la squadra sale di livello e il nemico no: lo si fa crescere insieme (PROVVISORIO, bilanciamento dell'atto 1)
	# obiettivo: boss in 4-6 round, frammenti in 1-2
	if not ritorno.is_empty():
		# fino al livello 12 e' la retta di sempre (atto 1); oltre, per il New Game+, la curva di BattleTypes.story_*_grow
		var grow: float = BattleTypes.story_hp_grow(level)
		pv_k *= (BattleTypes.STORY_HP_MINOR if minore else BattleTypes.STORY_HP_BOSS) * grow
		atk_k *= BattleTypes.STORY_ATK_K * BattleTypes.story_atk_grow(level)
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
	if not ritorno.is_empty():
		_syn_msgs = Progress.apply_to_battle(b)
	for p in b["players"]:
		slots.append(str(p["id"]))
	for uid in b["units"]:
		if str(uid) != BattleState.BOSS_ID:
			# le sinergie piu' forti (terzetti, tutti e quattro) fanno partire l'Ultimate un po' piu' carica
			b["units"][uid]["gauge"] = mini(BattleTypes.GAUGE_MAX, START_GAUGE + int(b["units"][uid].get("syn_gauge", 0)))
	if ingresso == "vantaggio":
		# PROVVISORIO: l'attacco a sorpresa toglie due terzi dell'equilibrio (rottura vicina)
		var boss: Dictionary = BattleState.boss(b)
		boss["balance"] = maxi(1, int(ceil(float(boss["balance"]) * 0.35)))


func _build_units() -> void:
	# squadra larga e lontana dal nemico (Persona 5: tra i compagni c'e' aria, il nemico e' "di fronte", non addosso)
	var xs: Array = [-3.3 * _row_k, -1.1 * _row_k, 1.1 * _row_k, 3.3 * _row_k]
	for i in slots.size():
		var u: Dictionary = _slot_unit(i)
		var cv := CharacterVisual.new()
		cv.setup(str(u["char"]))
		add_child(cv)
		var pos := Vector3(xs[i], 0.14, PARTY_Z + absf(xs[i]) * 0.12)
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
	_seal = LightFx.seal(self, ENEMY_POS + Vector3(0, -0.1, 0), 2.0 if not minore else 1.4)


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
	pos = _cam_fit(pos, look)
	_cam_want_pos = pos
	_cam_want_look = look
	_cam_rate = rate
	if snap:
		_cam_pos = pos
		_cam_look = look


# Tiene la telecamera dentro l'arena: se un'inquadratura di lato uscirebbe oltre i muri, la si riporta dentro e si
# recupera la distanza persa arretrando e alzandosi (il soggetto resta in quadro, ripreso un po' piu' dall'alto).
func _cam_fit(pos: Vector3, look: Vector3) -> Vector3:
	if absf(pos.x) <= _cam_lim:
		return pos
	var lost: float = absf(pos.x) - _cam_lim
	pos.x = signf(pos.x) * _cam_lim
	var away: float = signf(pos.z - look.z) if absf(pos.z - look.z) > 0.01 else 1.0
	pos.z += away * lost * 0.8
	pos.y += lost * 0.35
	return pos


func _cam_overview(snap: bool = false) -> void:
	_cam_set(Vector3(0.6, 3.5, 11.4), Vector3(0, 1.2, -1.2), 2.5, snap)


func _cam_actor(uid: String) -> void:
	# alle spalle, un po' alto e spostato verso il centro: i compagni restano ai lati senza coprire la vista
	var p: Vector3 = home[uid]
	var side: float = -signf(p.x) if absf(p.x) > 0.1 else 1.0
	_cam_set(p + Vector3(side * 0.55, 2.05, 3.2), ENEMY_POS + Vector3(-side * 0.3, 1.25, 0), 3.2)


# Mentre si sceglie: tre quarti alle spalle, chi e' di turno grande a sinistra e il nemico a destra, spazio attorno per la ruota.
# close = ULTIMATE scelta: la telecamera si stringe sul personaggio.
func _cam_choose(uid: String, close: bool = false) -> void:
	var p: Vector3 = home[uid]
	var k: float = 0.85 if close else 1.0
	# alla Persona 5: alle spalle e un po' a destra di chi sceglie, lui a sinistra del centro e il nemico libero a destra
	# (i comandi stanno alla SUA sinistra, non tra lui e il nemico). Stessa inquadratura per ogni posto della fila: la si
	# calcola lungo la linea personaggio-nemico (d avanti, l a sinistra), numeri cercati sulle proiezioni dei quattro posti.
	var d: Vector3 = Vector3(ENEMY_POS.x - p.x, 0.0, ENEMY_POS.z - p.z).normalized()
	var l: Vector3 = Vector3(d.z, 0.0, -d.x)
	var cp: Vector3 = p - d * 2.8 * k - l * 2.4 * k + Vector3(0, 1.3 + 0.1 * (1.0 - k), 0)
	var look: Vector3 = p + d * 1.5 + l * 0.8 + Vector3(0, 1.0 if not close else 1.15, 0)
	_cam_set(cp, look, 5.0 if not close else 2.6)
	# i compagni tra la telecamera e la scena escono di quadro mentre si sceglie (come in Persona 5)
	var dme: float = cp.distance_to(p)
	for id in home:
		if id == uid or id == BattleState.BOSS_ID or not vis.has(id):
			continue
		(vis[id] as Node3D).visible = cp.distance_to(home[id]) > dme + 1.0
	if vis.has(uid) and vis[uid].has_method("highlight"):
		vis[uid].call("highlight", _col(_unit_of(cur_pid)), true)


func _cam_choose_end() -> void:
	for id in vis:
		(vis[id] as Node3D).visible = true
		if vis[id].has_method("highlight"):
			vis[id].call("highlight", Color.BLACK, false)


func _cam_side(a: Vector3, bpos: Vector3) -> void:
	var mid: Vector3 = (a + bpos) * 0.5
	var side: float = 1.0 if a.x >= 0.0 else -1.0
	if _cam_lim < 5.0:
		# vicolo stretto: di lato si finirebbe nel muro, quindi tre quarti alle spalle di chi attacca, verso il centro
		_cam_set(a + Vector3(-side * 0.9, 2.1, 3.0), mid + Vector3(0, 1.15, 0), 4.0)
		return
	_cam_set(mid + Vector3(side * 5.2, 2.0, 0.8), mid + Vector3(0, 1.1, 0), 4.0)


func _cam_boss() -> void:
	_cam_set(ENEMY_POS + Vector3(1.8, 3.3, -4.2), Vector3(0, 1.0, 3.0), 3.0)


func _cam_front(uid: String) -> void:
	var p: Vector3 = (vis[uid] as Node3D).position
	_cam_set(p + Vector3(0.35, 1.55, -2.0), p + Vector3(0, 1.45, 0), 6.0, true)


func _process(delta: float) -> void:
	var rd: float = minf(delta, 0.05)
	if _reticle != null and _reticle.visible and vis.has(BattleState.BOSS_ID):
		# il mirino segue il petto del nemico (la telecamera si muove: si riposiziona, costa una proiezione)
		var bp: Vector3 = (vis[BattleState.BOSS_ID] as Node).call("chest_point")
		if not cam.is_position_behind(bp):
			_reticle.position = cam.unproject_position(bp)
	_update_wheel()
	_place_boss_tag()
	_cam_pos = _cam_pos.lerp(_cam_want_pos, minf(1.0, rd * _cam_rate))
	_cam_look = _cam_look.lerp(_cam_want_look, minf(1.0, rd * _cam_rate))
	var sh := Vector3.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - rd * 3.0)
		var k: float = _shake * Settings.shake * 0.22
		sh = Vector3(randf_range(-k, k), randf_range(-k, k), randf_range(-k, k) * 0.5)
		# colpo forte: il campo visivo si stringe appena e poi si riapre, insieme alla scossa
		cam.fov = FOV_BASE - _shake * Settings.shake * 3.5
		_pinched = true
	elif _pinched:
		cam.fov = FOV_BASE
		_pinched = false
	cam.position = _cam_pos + sh
	if cam.position.distance_to(_cam_look) > 0.01:
		cam.look_at(_cam_look, Vector3.UP)


# La ruota segue il petto di chi e' di turno (la telecamera si muove); il riflettore lo tiene in luce mentre sceglie
func _update_wheel() -> void:
	if _wheel == null or _spot == null:
		return
	var e: float = smoothstep(0.0, 1.0, _wheel.sel) if _wheel.visible else 0.0
	var uid: String = str(_unit_of(cur_pid).get("id", "")) if cur_pid != "" else ""
	if _wheel.visible and vis.has(uid):
		var cv: Node3D = vis[uid]
		var head: Vector3 = cv.call("head_point")
		var feet: Vector3 = cv.global_position
		if not cam.is_position_behind(head):
			var ph: Vector2 = cam.unproject_position(head + Vector3(0, 0.25, 0))
			var pf: Vector2 = cam.unproject_position(feet)
			var hgt: float = maxf(120.0, pf.y - ph.y)
			var vs: Vector2 = _wheel.size if _wheel.size.x > 1.0 else get_viewport().get_visible_rect().size
			_wheel.ry = clampf(hgt * 0.5, 150.0, 230.0)
			_wheel.rx = _wheel.ry * 0.55
			var c: Vector2 = Vector2(ph.x, lerpf(ph.y, pf.y, 0.42))
			# il grappolo dei comandi (a destra del personaggio) resta dentro lo schermo e sopra la squadra
			var sk: float = _wheel.s()
			c.x = clampf(c.x, 500.0 * sk, vs.x - 420.0)      # i comandi stanno a sinistra del personaggio
			c.y = clampf(c.y, 170.0 + 250.0 * sk, vs.y - 175.0 * sk)      # ULTIMATE non sale sui TURNI
			_wheel.center = _wheel.center.lerp(c, 0.35) if _wheel.appear > 0.05 else c
			var m: ShaderMaterial = _spot.material
			m.set_shader_parameter("c", Vector2(ph.x, lerpf(ph.y, pf.y, 0.5)) / vs)
			m.set_shader_parameter("r", Vector2(hgt * 0.42, hgt * 0.62) / vs)
	# di chi e' il turno si vede subito: mentre la ruota e' aperta la scena e' appena piu' scura attorno a lui e lui ha un alone
	# del suo colore (anche prima di scegliere); scegliendo, lo scuro cresce come prima
	var base: float = clampf(_wheel.appear * 1.5, 0.0, 1.0) if _wheel.visible and waiting else 0.0
	_spot.visible = e > 0.01 or base > 0.01
	if _spot.visible:
		var ult: bool = _picked == "ult"
		var m2: ShaderMaterial = _spot.material
		_spot_boss(m2, e, ult, base)
		var pulse: float = 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.008)
		m2.set_shader_parameter("k", maxf((0.86 if ult else 0.55) * e, 0.32 * base))
		m2.set_shader_parameter("aura", maxf((0.9 if ult else 0.35) * e, 0.3 * base) * pulse)
		m2.set_shader_parameter("tint", _col(_unit_of(cur_pid)))


# Il nemico preso di mira dall'attacco scelto brilla piano (alone caldo che pulsa) e resta in luce anche con lo schermo scuro dell'ULTIMATE
# Cartellino del nemico (Persona 5 / Metaphor: il nome sta SUL nemico): sopra la sua testa, segue la telecamera, resta nello
# schermo. Si vede solo mentre si sceglie (_hud_focus).
func _place_boss_tag() -> void:
	if _boss_panel == null or not _boss_panel.visible or not vis.has(BattleState.BOSS_ID):
		return
	var bv: Node3D = vis[BattleState.BOSS_ID]
	var h3: Vector3 = bv.call("head_point") if bv.has_method("head_point") else bv.global_position + Vector3(0, 2.2, 0)
	if cam.is_position_behind(h3):
		return
	var hp: Vector2 = cam.unproject_position(h3 + Vector3(0, 0.35, 0))
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var sz: Vector2 = _boss_panel.get_combined_minimum_size()
	sz.x = maxf(sz.x, 300.0)
	var want := Vector2(hp.x - sz.x * 0.5, hp.y - sz.y - 18.0)
	if want.y < 64.0:
		# boss alto: sopra la testa non c'e' posto e il cartellino gli finirebbe addosso. Va di fianco alla figura,
		# dal lato con piu' spazio (decisione dell'autore, 24/10/2026: le barre non devono coprire il boss)
		var fp: Vector2 = cam.unproject_position(bv.global_position)
		var half: float = maxf(60.0, absf(fp.y - hp.y) * 0.4)
		var cx: float = (hp.x + fp.x) * 0.5
		want.y = maxf(64.0, hp.y)
		want.x = cx + half + 24.0 if cx + half + 24.0 + sz.x <= vs.x - 16.0 else cx - half - 24.0 - sz.x
	want.x = clampf(want.x, 16.0, vs.x - sz.x - 16.0)
	want.y = clampf(want.y, 64.0, vs.y * 0.5)
	_boss_panel.position = _boss_panel.position.lerp(want, 0.3) if _boss_panel.position.y > 1.0 else want
	_boss_panel.size = sz


func _spot_boss(m: ShaderMaterial, e: float, ult: bool, base: float = 0.0) -> void:
	# il bersaglio resta in risalto anche prima di scegliere (Persona 5: il nemico si stacca dalla scena scura)
	e = maxf(e, 0.7 * base) if _picked in ["", "attack", "skill", "ult"] else e
	var on: bool = (_picked in ["attack", "skill", "ult"] or (_picked == "" and base > 0.0)) and vis.has(BattleState.BOSS_ID) and BattleState.is_alive(BattleState.boss(b))
	var k2: float = 0.0
	if on:
		var bv: Node3D = vis[BattleState.BOSS_ID]
		var hp3: Vector3 = bv.call("head_point") if bv.has_method("head_point") else bv.global_position + Vector3(0, 2, 0)
		var f3: Vector3 = bv.global_position
		if not cam.is_position_behind(hp3):
			var vs: Vector2 = _wheel.size if _wheel.size.x > 1.0 else get_viewport().get_visible_rect().size
			var a: Vector2 = cam.unproject_position(hp3)
			var z: Vector2 = cam.unproject_position(f3)
			var hh: float = maxf(120.0, absf(z.y - a.y))
			m.set_shader_parameter("c2", Vector2(a.x, (a.y + z.y) * 0.5) / vs)
			m.set_shader_parameter("r2", Vector2(hh * 0.5, hh * 0.62) / vs)
			var pulse: float = 0.78 + 0.22 * sin(Time.get_ticks_msec() * 0.006)
			k2 = e * pulse * (1.0 if ult else 0.55)
	m.set_shader_parameter("k2", k2)
	if k2 > 0.0 and not _spot.visible:
		_spot.visible = true


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
	if tutorial:
		_tut_round()
	_refresh_hud()
	_round_hint()
	await _advance()


# INDIZIO DI INIZIO ROUND: una riga breve su cio' che cambia questo round (evento dell'arena, catena del boss). Va nella fascia del
# suggerimento (al centro), sparisce da sola e non scavalca altri suggerimenti.
func _round_hint() -> void:
	if _hint == null or _hint.text != "" or ended:
		return
	var line: String = ""
	var al: Array = Arena.hint_lines(b)
	if not al.is_empty():
		line = str(al[0])
	var chain: String = str(b.get("telegraph", {}).get("chain", ""))
	if chain != "":
		line = "CATENA: se nessuno reagisce, subito dopo segue %s" % BattleText.move_name(chain).to_upper()
	if line == "":
		return
	_hint.text = line
	var tw := create_tween()
	tw.tween_interval(3.2)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_hint) and _hint.text == line:
			_hint.text = "")


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
		if not bool(e.get("quick", false)) and DuoTechs.spent(b, str(_unit_of(pid).get("id", ""))):
			continue          # ha dato il suo turno alla tecnica combinata di un compagno
		cur_pid = pid
		_quick = bool(e.get("quick", false))
		var uid: String = str(_unit_of(pid)["id"])
		_cam_actor(uid)
		_fx_turn(uid)
		_refresh_hud()
		if auto_on:
			await _wait(0.45 if not _quick else 0.3)       # in AUTO si vede chi tocca prima che agisca
			if not is_inside_tree() or ended:
				return
			await _do_action(pid, (BattleAI.choose_quick(b, pid) if _quick else BattleAI.choose(b, pid)), _quick)
			continue
		if tutorial or lezioni:
			await _tut_turn(uid)
			if not is_inside_tree() or ended:
				return
			if auto_on:
				# AUTO acceso mentre parlava Echo: il turno lo gioca l'IA, come sopra
				await _do_action(pid, (BattleAI.choose_quick(b, pid) if _quick else BattleAI.choose(b, pid)), _quick)
				continue
		waiting = true
		_cam_choose(uid)
		_show_commands(true)
		if first_turn:
			first_turn = false
			if not (tutorial or lezioni):       # con le spiegazioni lo dice gia' Echo: una cosa per volta
				_hint.text = "GUARDIA ricarica energia (+1 a ogni round) · ABILITÀ la spende · ULTIMATE a barra piena"
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
	var sp: String = str(_skill_pick.get(str(u.get("id", "")), ""))
	if sp != "" and _skill_ids(u).has(sp):
		return sp                 # scelta nel menu ABILITA' di questa battaglia
	var eq: String = str(u.get("equip_skill", ""))
	if eq != "" and (u.get("skills", []) as Array).has(eq):
		return eq                 # scelta nel menu SQUADRA
	var def: Dictionary = BattleContent.CHARACTERS.get(str(u["char"]), {})
	return str(def.get("skill", "attack"))


# Le abilita' che il personaggio ha: quella di base e quelle sbloccate (menu ABILITA')
func _skill_ids(u: Dictionary) -> Array:
	var out: Array = []
	var def: Dictionary = BattleContent.CHARACTERS.get(str(u.get("char", "")), {})
	var base: String = str(def.get("skill", ""))
	if base != "" and BattleContent.MOVES.has(base):
		out.append(base)
	for m in (u.get("skills", []) as Array):
		var ms: String = str(m)
		if not out.has(ms) and BattleContent.MOVES.has(ms) and str(BattleContent.MOVES[ms].get("kind", "")) == "skill":
			out.append(ms)
	return out


func _usable(move_id: String) -> bool:
	if cur_pid == "" or move_id == "" or not BattleContent.MOVES.has(move_id):
		return false
	if _quick and str(BattleContent.MOVES[move_id].get("kind", "")) != "basic":
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
			mv = _duo_pick if _duo_pick != "" else _skill_of(u)
			_duo_pick = ""
		"ult":
			mv = str(u["ult"])
		"guard":
			mv = "guard"
	if not _usable(mv):
		Settings.buzz(10)
		return
	waiting = false
	_confirming = true
	_confirm_button(kind)
	_reticle.confirm()
	Settings.buzz(40 if kind == "ult" else 18)
	# 0.1 s di tempo reale perche' lo scatto del bottone si veda prima che la colonna si chiuda
	await get_tree().create_timer(0.1, true, false, true).timeout
	_confirming = false
	if not is_inside_tree():
		return
	_show_commands(false)
	_hint.text = ""
	await _do_action(cur_pid, _choice_for(mv), _quick)
	if is_inside_tree() and not ended:
		await _advance()


func _do_action(pid: String, choice: Dictionary, quick: bool = false) -> void:
	var u: Dictionary = _unit_of(pid)
	var uid: String = str(u["id"])
	var mv: String = str(choice.get("move", "attack"))
	var move: Dictionary = BattleContent.MOVES.get(mv, {})
	var kind: String = str(move.get("kind", "basic"))
	var tgt: String = str(move.get("target", "enemy"))
	var ev: Array = SeqRound.player_action(b, pid, choice, quick)
	# RITMO (decisione dell'autore, 25/10/2026): i momenti giusti si fermano e si leggono. Colpo alla debolezza = fermo
	# del colpo + timbro DEBOLEZZA; SLANCIO = una pausa sua, con il timbro e chi agisce ancora.
	var weak_hit: bool = false
	var got_slancio: bool = false
	var boss_u: Dictionary = BattleState.boss(b)
	for x in ev:
		if str(x.get("t", "")) == "damage" and str(x.get("src", "")) == uid and str(x.get("dst", "")) == BattleState.BOSS_ID \
			and int(x.get("amount", 0)) > 0 and BattleTypes.color_multiplier(str(u.get("color", "")), str(boss_u.get("color", ""))) > 1.0:
			weak_hit = true
		if str(x.get("t", "")) == "slancio":
			got_slancio = true
	for x in ev:
		if str(x.get("t", "")) == "slancio":
			# SLANCIO: subito dopo agisce ancora lo stesso eroe, ma solo con Attacco o Guardia
			turn_list.insert(turn_i + 1, {"unit": str(x["unit"]), "player": str(x["player"]), "boss": false, "spd": -1, "extra": true, "quick": true})
	var cv: CharacterVisual = vis[uid]
	var col: Color = _col(u)
	if kind == "ult":
		await LightFx.blackout(_root, col)
		await _play_cutin(u, str(move.get("name", "ULTIMATE")))
	_banner(str(u["name"]).to_upper() + " · " + str(move.get("name", mv)).to_upper(), col)
	if kind == "duo":
		# il nome della tecnica combinata arriva prima dei colpi (dopo, la ruota del turno dopo lo avrebbe scacciato)
		for x in ev:
			if str(x.get("t", "")) == "duo":
				_stamp(str(x.get("name", "")).to_upper(), "%s + %s · TECNICA COMBINATA" % [str(u.get("name", "")).to_upper(), _uname(str(x.get("with", ""))).to_upper()], col.lightened(0.2))
	if tgt == "enemy":
		var boss_v: Node3D = vis[BattleState.BOSS_ID]
		var strike: Vector3 = ENEMY_POS + (home[uid] - ENEMY_POS).normalized() * 1.7
		strike.y = 0.14
		if kind != "ult":
			_cam_side(home[uid], ENEMY_POS)
		cv.move_speed = 1.0
		# TECNICA COMBINATA: il compagno scatta insieme, dall'altro lato del nemico
		var mate_cv: CharacterVisual = null
		var mate_id: String = ""
		if kind == "duo":
			for x in ev:
				if str(x.get("t", "")) == "duo" and vis.has(str(x.get("with", ""))):
					mate_id = str(x["with"])
					mate_cv = vis[mate_id]
		if mate_cv != null:
			var strike2: Vector3 = ENEMY_POS + (home[mate_id] - ENEMY_POS).normalized() * 1.7
			strike2.y = 0.14
			mate_cv.move_speed = 1.0
			var tw2 := create_tween()
			tw2.tween_property(mate_cv, "position", strike2, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		var tw := create_tween()
		tw.tween_property(cv, "position", strike, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tw.finished
		cv.move_speed = 0.0
		if mate_cv != null:
			mate_cv.move_speed = 0.0
			mate_cv.cast()
		var a: Tween = cv.cast() if kind != "basic" else cv.attack()
		await _wait(0.16)
		if kind != "basic":
			# la magia si disegna con la luce: una pennellata del suo colore dal personaggio al nemico
			LightFx.stroke(self, cv.chest_point(), (boss_v as Node).call("chest_point"), col, 0.6 if kind == "ult" else 0.42)
		_ring(boss_v.position + Vector3(0, 0.05, 0), col, 2.8 if kind == "ult" else 1.8)
		if kind == "ult":
			_flash(0.9)
			_kick(1.0)
		else:
			_kick(0.45 if kind == "basic" else 0.7)
		if weak_hit:
			await _hit_stop(0.2)
			_kick(0.9)
			_stamp("DEBOLEZZA!", "%s colpisce il punto debole" % str(u["name"]).to_upper(), Ui.YELLOW, 0.7)   # va nel posto fisso dei timbri (STAMP_AY), in coda: in alto e sul nemico ci sono i numeri del colpo
		await _show_events_freeze(ev)
		await _tw_done(a)
		cv.move_speed = 1.0
		var back := create_tween()
		back.tween_property(cv, "position", home[uid], 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if mate_cv != null:
			mate_cv.move_speed = 1.0
			back.parallel().tween_property(mate_cv, "position", home[mate_id], 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await back.finished
		cv.move_speed = 0.0
		_face(cv, ENEMY_POS)
		if mate_cv != null:
			mate_cv.move_speed = 0.0
			_face(mate_cv, ENEMY_POS)
	else:
		_cam_front(uid)
		_cam_set(home[uid] + Vector3(0.3, 1.6, -3.0), home[uid] + Vector3(0, 1.2, 0), 4.0)
		var a2: Tween = cv.cast()
		await _wait(0.16)
		LightFx.rise(self, home[uid], col)
		_ring(home[uid], col, 2.2)
		if kind == "ult":
			_flash(0.6)
		await _show_events_freeze(ev)
		await _tw_done(a2)
	_refresh_hud()
	await _wait(0.12)
	# respiro dopo l'azione: piu' lungo per le mosse che contano, cosi' non tutto dura uguale
	await _wait({"basic": 0.15, "skill": 0.3, "ult": 0.45}.get(kind, 0.2) + (0.35 if weak_hit else 0.0))
	if got_slancio and is_inside_tree() and not ended:
		await _slancio_moment(u)
	# dopo l'inquadratura frontale si stacca di netto (cambio di telecamera): niente viaggio attraverso i compagni
	_cam_overview(tgt != "enemy")


func _boss_turn() -> void:
	cur_pid = ""
	_quick = false
	_boss_acting = true
	_fx_turn("")
	_refresh_hud()
	var tele: Dictionary = b["telegraph"]
	var mv: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	var boss_u: Dictionary = BattleState.boss(b)
	var stunned: bool = int(boss_u.get("stun", 0)) > 0
	_cam_boss()
	var m: VendingVisual = vis[BattleState.BOSS_ID]
	if stunned:
		await _wait(0.3)
		var evs: Array = SeqRound.boss_action(b)
		_banner(_bname() + " · STORDITO, SALTA IL TURNO", Ui.CREAM)
		await _show_events(evs, true)
		await _wait(0.25)
	else:
		_banner(_bname() + " · " + str(mv.get("name", "?")).to_upper(), Ui.YELLOW)
		await _wait(0.25)
		var all: bool = str(mv.get("target", "one")) == "all"
		if _guardable(mv):
			# chi ha scelto SCHIVA o COPRI gioca il suo minigioco; senza reazioni resta la guardia a tempo (il cerchio)
			var played: bool = false
			for r in (b.get("reactions", []) as Array):
				var game: String = {"dodge": "arrow", "intercept": "hold"}.get(str(r["react"]), "")
				var ru: Dictionary = b["units"].get(str(r["unit"]), {})
				if game == "" or ru.is_empty() or not BattleState.is_alive(ru):
					continue
				if game == "arrow" and not Kits.targeted(b, ru):
					continue           # schiva solo chi e' nel mirino
				played = true
				var g: String = await _react_game(game, ru)
				if not is_inside_tree() or ended:
					return
				if not b.has("react_grade"):
					b["react_grade"] = {}
				(b["react_grade"] as Dictionary)[str(ru["id"])] = g
			if not played:
				if tutorial or lezioni:
					await _tut("tut_qte")
				var grade: String = await _timed_guard()
				if not is_inside_tree() or ended:
					return
				if grade == "good" or grade == "perfect":
					b["timed_guard"] = grade
		var ev: Array = SeqRound.boss_action(b)
		var tw: Tween = m.slam() if all else m.attack()
		await _wait(0.3 if all else 0.2)
		if all:
			_ring(ENEMY_POS, Ui.YELLOW, 6.5)
			_flash(0.35)
			_kick(0.9)
		else:
			_kick(0.6)
		await _show_events(ev, true)
		await _tw_done(tw)
	m.stunned = int(BattleState.boss(b).get("stun", 0)) > 0
	_boss_acting = false
	_refresh_hud()
	await _wait(0.15)
	_cam_overview()


# ---------------------------------------------------------------- tutorial

# Una spiegazione (scena di data/dialoghi_atto1.json, chiavi tut_*), una volta sola, a battaglia ferma.
# Ritorna true se e' partita.
func _tut(key: String) -> bool:
	if auto_on or ended or not is_inside_tree():
		return false
	if tutorial:
		if _tut_done.has(key):
			return false
		_tut_done[key] = true
	elif lezioni:
		if not _lezione_ok(key):
			return false
		Story.set_flag("lez_" + key)
		Story.set_flag("lezioni_iniziate")
		if key != "tut_fine":
			_lez_ora += 1        # tut_fine arriva a scontro finito: non conta
		if _lezioni_viste():
			Story.set_flag("lezioni_fatte")
	else:
		return false
	var lines: Array = DialogData.lines(key)
	if lines.is_empty():
		return false
	var was: bool = waiting
	waiting = false
	_show_commands(false)
	if _top_bar != null:
		_top_bar.visible = false
	var dlg := DialogBox.new()
	_tut_dlg = dlg
	_root.add_child(dlg)
	await get_tree().process_frame
	dlg.play(lines, DialogData.recap(key))
	await dlg.finished
	if is_instance_valid(dlg):
		dlg.queue_free()
	_tut_dlg = null
	if _top_bar != null:
		_top_bar.visible = true
	waiting = was
	return true


# Le spiegazioni a rate valgono nella prima partita della storia finche' non sono state viste tutte.
# Un salvataggio che aveva gia' fatto il vecchio tutorial (tutto nel primo scontro) non le rivede.
func _lezioni_attive() -> bool:
	if Story.has_flag("lezioni_fatte") or Story.replica() > 0:   # nella Replica le regole si conoscono gia'
		return false
	if Story.has_flag("lezioni_fatte"):
		return false
	return not (Story.has_flag("tutorial_fatto") and not Story.has_flag("lezioni_iniziate"))


func _lezioni_viste() -> bool:
	for g in LEZIONI:
		for k in g:
			if not Story.has_flag("lez_" + str(k)):
				return false
	return true


# Una spiegazione parte se non e' gia' vista, se in questo scontro ce ne sono state meno di LEZIONI_MAX
# e se i gruppi prima del suo sono gia' visti. tut_fine (esperienza e SQUADRA) dopo il secondo gruppo.
func _lezione_ok(key: String) -> bool:
	if Story.has_flag("lez_" + key):
		return false
	var gi: int = 2 if key == "tut_fine" else -1
	if gi < 0:
		if _lez_ora >= LEZIONI_MAX:
			return false
		for i in LEZIONI.size():
			if (LEZIONI[i] as Array).has(key):
				gi = i
		if gi < 0:
			return false
	for i in mini(gi, LEZIONI.size()):
		for k in LEZIONI[i]:
			if not Story.has_flag("lez_" + str(k)):
				return false
	if key == "tut_extra" and not Story.has_flag("lez_tut_ultimate"):
		return false
	return true


# Prima del turno del giocatore: la spiegazione giusta per quello che si puo' fare adesso
func _tut_turn(uid: String) -> void:
	_tut_turns += 1
	var u: Dictionary = b["units"].get(uid, {})
	var reacts: bool = false
	for r in BattleResolver.reactions_for(b, cur_pid):
		reacts = reacts or str(r["err"]) == ""
	if lezioni:
		# a rate: la prima spiegazione utile adesso tra quelle aperte (al massimo una per turno)
		var cand: Array = []
		if reacts:
			cand.append("tut_reazioni")
		if int(u.get("gauge", 0)) >= BattleTypes.GAUGE_MAX:
			cand.append("tut_ultimate")
		cand.append_array(["tut_attacco", "tut_guardia", "tut_abilita", "tut_extra"])
		for k in cand:
			if await _tut(str(k)):
				return
		return
	if reacts and not _tut_done.has("tut_reazioni"):
		await _tut("tut_reazioni")
	elif _tut_done.has("tut_reazioni") and int(u.get("gauge", 0)) >= BattleTypes.GAUGE_MAX and not _tut_done.has("tut_ultimate"):
		await _tut("tut_ultimate")
	elif not _tut_done.has("tut_attacco"):
		await _tut("tut_attacco")
	elif not _tut_done.has("tut_guardia"):
		await _tut("tut_guardia")
	elif not _tut_done.has("tut_abilita"):
		await _tut("tut_abilita")
	elif _tut_done.has("tut_ultimate") and not _tut_done.has("tut_extra"):
		await _tut("tut_extra")


# A inizio round il tutorial prepara la scena per la prossima spiegazione: una carica (reazioni), la rottura vicina,
# la barra dell'Ultimate piena. Finche' resta qualcosa da spiegare il nemico non scende sotto un terzo dei PV.
func _tut_round() -> void:
	var r: int = int(b.get("round", 1))
	var boss: Dictionary = BattleState.boss(b)
	var all_said: bool = _tut_done.has("tut_extra")
	if not all_said:
		boss["hp"] = maxi(int(boss["hp"]), int(float(boss["max_hp"]) * 0.34))
	if r >= 2 and not _tut_done.has("tut_reazioni"):
		for mid in BattleContent.BOSSES.get(boss_id, {}).get("cycle", []):
			if BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES.get(str(mid), {})):
				b["telegraph"]["move"] = str(mid)
				break
		b["reserve"] = maxi(int(b.get("reserve", 0)), 4)
	elif _tut_done.has("tut_reazioni") and not _tut_done.has("tut_rottura"):
		boss["balance"] = mini(int(boss["balance"]), 1)
	elif _tut_done.has("tut_rottura") and not _tut_done.has("tut_ultimate"):
		for uid in b["units"]:
			var u: Dictionary = b["units"][uid]
			if str(u.get("side", "")) == "player" and BattleState.is_alive(u):
				u["gauge"] = BattleTypes.GAUGE_MAX


# ---------------------------------------------------------------- guardia a tempo

# Si para solo un colpo vero (niente "Obiettivo rotto", che non fa danno) e solo giocando a mano (con AUTO no).
func _guardable(mv: Dictionary) -> bool:
	return not auto_on and not mv.is_empty() and float(mv.get("mult", 0.0)) > 0.0 and not bool(mv.get("camera", false)) \
		and not bool(b.get("nullify", false))


# Il cerchio sta sempre al centro dello schermo: dalla camera del boss il bersaglio puo' essere coperto dal nemico.
# Ritorna "", early, good o perfect.
func _timed_guard() -> String:
	_qte_ring = QteRing.new()
	_fx_layer.add_child(_qte_ring)
	_hide_stamps(true)
	_qte_ring.place(_root.size)
	# tempo in millisecondi veri (Parry): uguale a ogni fps, la pausa ferma l'orologio
	var w: Dictionary = Parry.windows(Settings.parry_wide, _hits_lance())
	_qte_good = float(w["good"]) / 1000.0
	_qte_perfect = float(w["perfect"]) / 1000.0
	_qte_late = float(w["late"]) / 1000.0
	_qte_lead = Parry.LEAD_MS / 1000.0
	# CONTROMOSSA: dopo due parate perfette di fila il nemico finta. Il colpo arriva piu' tardi (il cerchio si chiude
	# piu' piano): chi tocca a memoria e' in anticipo, chi guarda il cerchio para lo stesso.
	var feint: bool = _perfect_streak >= FEINT_AFTER and not first_qte
	if feint:
		_perfect_streak = 0
		_qte_lead *= FEINT_LEAD
		_qte_ring._label.text = "FINTA"
		_toast("FINTA! %s ha letto le tue parate: aspetta che il cerchio si chiuda" % _cap(_bn()), Color("#ff7a9c"), 1.6)
	if first_qte:
		first_qte = false
		_qte_lead *= 2.0
		_hint.text = "GUARDIA A TEMPO: tocca lo schermo quando il cerchio si chiude. Proprio all'impatto è una parata perfetta"
	_qte_t = 0.0
	_qte_grade = ""
	_qte_start_us = Time.get_ticks_usec()
	_qte_paused_us = 0
	_qte_pause_at = 0
	_qte_on = true
	while _qte_t < _qte_lead + _qte_late and _qte_grade == "":
		await get_tree().process_frame
		if not is_inside_tree() or ended:
			_qte_on = false
			return ""
		_qte_t = _qte_clock()
		_qte_ring.progress = _qte_t / _qte_lead
		_qte_ring.in_window = _qte_t >= _qte_lead - _qte_good
		_qte_ring.queue_redraw()
	_qte_on = false
	_hide_stamps(false)
	_hint.text = ""
	_qte_ring.finish(_qte_grade)
	_qte_ring = null
	_perfect_streak = _perfect_streak + 1 if _qte_grade == "perfect" else 0
	match _qte_grade:
		"perfect":
			Settings.buzz(45)
			_flash(0.35)
		"good":
			Settings.buzz(25)
		"early":
			_toast("TROPPO PRESTO", Color("#ff7a9c"), 0.7)
	return _qte_grade


var _games_seen: Dictionary = {}


# Minigioco di una reazione (ReactGame). La prima volta di ogni tipo c'e' piu' tempo per leggere.
func _react_game(game: String, u: Dictionary) -> String:
	var g := ReactGame.new(game, str(u.get("name", "")).to_upper(), _col(u), not _games_seen.has(game))
	_games_seen[game] = true
	# sotto il minigioco niente comandi ne' suggerimenti: si legge solo lui
	var hide: Array = []
	for n in [_cmd_box, _kit_lbl, _react_box, _turn_lbl, _hint]:
		if n != null and (n as CanvasItem).visible:
			(n as CanvasItem).visible = false
			hide.append(n)
	_fx_layer.add_child(g)
	var grade: String = await g.done
	for n in hide:
		if is_instance_valid(n):
			(n as CanvasItem).visible = true
	return grade


# Il colpo annunciato finira' su Lance? (bersaglio lui, oppure copre il bersaglio)
func _hits_lance() -> bool:
	var tele: Dictionary = b.get("telegraph", {})
	var mv: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	if str(mv.get("target", "one")) == "all":
		return false
	var tu: Dictionary = BattleState.active_unit(b, str(tele.get("target", "")))
	if tu.is_empty():
		return false
	if Kits.is_char(tu, Kits.LANCE):
		return true
	return not Kits.coverer(b, tu).is_empty() and Kits.is_char(Kits.coverer(b, tu), Kits.LANCE)


func _qte_tap() -> void:
	if not _qte_on or _qte_grade != "" or _pause != null:
		return
	# misurato all'istante del tocco, non all'ultimo fotogramma
	var d: float = _qte_clock() - _qte_lead
	_qte_grade = Parry.grade(d * 1000.0, {"good": _qte_good * 1000.0, "perfect": _qte_perfect * 1000.0, "late": _qte_late * 1000.0})


# Secondi veri dall'apparire del cerchio, senza il tempo passato in pausa.
func _qte_clock() -> float:
	var now: int = Time.get_ticks_usec()
	if _pause != null and _qte_pause_at == 0:
		_qte_pause_at = now
	elif _pause == null and _qte_pause_at != 0:
		_qte_paused_us += now - _qte_pause_at
		_qte_pause_at = 0
	var stop: int = _qte_pause_at if _qte_pause_at != 0 else now
	return float(stop - _qte_start_us - _qte_paused_us) / 1000000.0


# Cerchio della guardia a tempo: un anello fisso (il bersaglio) e uno che si stringe fino a toccarlo.
class EchoBalloon extends Control:
	# Fumetto di Echo dietro i consigli: lastra scura inclinata con bordo ciano e il suo ritratto, segue il testo
	# Generalizzato: lo stesso fumetto serve a chiunque parli in battaglia (speaker(): ritratto, nome e colore del personaggio)
	var lbl: Label
	var face: Texture2D
	var who: String = "ECHO"
	var col: Color = Color("#3fe0ff")
	var fit: bool = false          # true: il fumetto si stringe al testo invece di seguire tutta la larghezza dell'etichetta
	var _r: Rect2 = Rect2()

	func speaker(id: String, nm: String, c: Color) -> void:
		who = nm
		col = c
		var fp: String = "res://assets/portraits/%s_neutro.png" % id
		face = load(fp) if ResourceLoader.exists(fp) else null
		_r = Rect2()
		queue_redraw()

	func _init(p_lbl: Label) -> void:
		lbl = p_lbl
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		if ResourceLoader.exists("res://assets/portraits/echo_neutro.png"):
			face = load("res://assets/portraits/echo_neutro.png")

	func _process(_d: float) -> void:
		var on: bool = is_instance_valid(lbl) and lbl.visible and lbl.text != ""
		visible = on
		if not on:
			return
		modulate.a = lbl.modulate.a
		var r := Rect2(lbl.position, lbl.size)
		if fit:
			var f: Font = lbl.get_theme_font("font")
			r.size.x = minf(r.size.x, f.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, lbl.get_theme_font_size("font_size")).x + 4.0)
		if r != _r:
			_r = r
			queue_redraw()

	func _draw() -> void:
		var r: Rect2 = _r.grow_individual(18, 10, 22, 12)
		var sk: float = 14.0
		var cy: Color = col
		var pts := PackedVector2Array([r.position + Vector2(sk, 0), Vector2(r.end.x + sk, r.position.y - 4),
			Vector2(r.end.x - sk * 0.4, r.end.y), Vector2(r.position.x + 30, r.end.y + 2),
			Vector2(r.position.x + 6, r.end.y + 18), Vector2(r.position.x + 10, r.end.y), Vector2(r.position.x - sk * 0.4, r.end.y)])
		var sh := PackedVector2Array()
		for q in pts:
			sh.append(q + Vector2(6, 6))
		draw_colored_polygon(sh, Color(cy, 0.35))
		draw_colored_polygon(pts, Color(0.04, 0.03, 0.09, 0.92))
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, cy, 3.0, true)
		# ritratto di Echo nel tondo a sinistra
		var c: Vector2 = Vector2(r.position.x - 28, r.position.y + 24)
		draw_circle(c, 32.0, cy)
		draw_circle(c, 28.0, Color(0.04, 0.03, 0.09))
		if face != null:
			var fs: float = 44.0
			draw_texture_rect(face, Rect2(c - Vector2(fs, fs) * 0.5, Vector2(fs, fs)), false)
		draw_string(Ui.display(), Vector2(r.position.x + sk + 6, r.position.y - 6), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cy)


class QteRing extends Control:
	const R: float = 54.0
	var progress: float = 0.0
	var in_window: bool = false
	var _label: Label

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(R * 6.0, R * 6.0)
		pivot_offset = size * 0.5
		_label = Ui.label("TOCCA", 26, Ui.CREAM, Ui.display(), 8)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.size = size
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)

	func place(screen: Vector2) -> void:
		position = screen * Vector2(0.5, 0.45) - size * 0.5

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		var col: Color = Ui.CYAN if in_window else Ui.YELLOW
		draw_arc(center, R, 0.0, TAU, 48, Color(0, 0, 0, 0.55), 12.0, true)
		draw_arc(center, R, 0.0, TAU, 48, Ui.CREAM, 5.0, true)
		var r2: float = R * (1.0 + 1.7 * clampf(1.0 - progress, 0.0, 1.0))
		draw_arc(center, r2, 0.0, TAU, 48, Color(0, 0, 0, 0.5), 11.0, true)
		draw_arc(center, r2, 0.0, TAU, 48, col, 6.0, true)

	# esito: il cerchio diventa la parola e svanisce
	func finish(grade: String) -> void:
		progress = 1.0
		# guardia a tempo: onomatopea sopra l'anello (CLANG la perfetta, TAP la buona)
		if grade == "perfect" or grade == "good":
			Onomato.pop(get_parent() as Control, position + size * 0.5 + Vector2(0, -get_viewport_rect().size.y * 0.12), "CLANG" if grade == "perfect" else "TAP", Ui.CYAN, grade == "perfect")
		match grade:
			"perfect":
				_label.text = "PERFETTA!"
				_label.add_theme_color_override("font_color", Color.WHITE)
				in_window = true
			"good":
				_label.text = "GUARDIA!"
				_label.add_theme_color_override("font_color", Ui.CYAN)
				in_window = true
			_:
				_label.text = ""
		queue_redraw()
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.35)
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(queue_free)


# ---------------------------------------------------------------- eventi del motore -> effetti

func _show_events(ev: Array, hit_anims: bool) -> void:
	var delay: float = 0.0
	var duo_hits: int = 0
	var gap: float = 0.12        # tra un colpo e l'altro; nelle tecniche combinate di piu', se no i numeri dei due si sovrappongono
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
				# il peso del colpo si legge dalla grandezza del numero (danno / PV massimi del bersaglio); rosso-arancio se tocca uno dei tuoi
				var dmax: float = maxf(1.0, float(b["units"].get(dst, {}).get("max_hp", 1)))
				var sz: int = clampi(int(round(lerpf(30.0, 64.0, clampf(float(amt) / dmax / 0.25, 0.0, 1.0)))), 30, 64)
				var ncol: Color = Ui.YELLOW if crit else Ui.CREAM
				if dst != BattleState.BOSS_ID:
					ncol = Color("#ff6a5a")
				# tecnica combinata: il colpo del secondo personaggio sale piu' in alto, cosi' i due numeri non si coprono
				var lift: float = 0.0
				if gap > 0.2 and dst == BattleState.BOSS_ID:
					lift = -125.0 * float(duo_hits % 2)
					duo_hits += 1
				_number(dst, ("%d" % amt) + ("!" if crit else ""), ncol, sz, delay, lift)
				_color_tag(e, dst, delay, lift)
				# onomatopea sul bersaglio: scudo = CLANG, critico = BAM (+ glitch), colpo grosso = ZAP, normale = TAP, ai tuoi = THUD
				var ow: String = "TAP"
				var ocol: Color = Ui.CYAN
				if int(e.get("absorbed", 0)) > 0:
					ow = "CLANG"
				elif crit:
					ow = "BAM"
					ocol = Ui.YELLOW
				elif dst != BattleState.BOSS_ID:
					ow = "THUD"
					ocol = Color("#ff6a5a")
				elif sz >= 46:
					ow = "ZAP"
					ocol = Color("#3dff8a")
				_ono(dst, ow, ocol, delay + 0.03, crit or sz >= 52)
				if crit:
					_glitch_later(0.7, delay)
				if int(e.get("absorbed", 0)) > 0:
					_number(dst, "SCUDO -%d" % int(e["absorbed"]), Ui.CYAN, 24, delay + 0.1)
				if hit_anims and vis.has(dst):
					var v: Node3D = vis[dst]
					if v.has_method("hit"):
						v.call("hit")
					_sparks_later(dst, delay, crit)
				if run_hp.has(dst):
					# telecamera che si rompe nel momento del colpo, se scende di livello (50% / 25%)
					var u2: Dictionary = b["units"][dst]
					var mx: float = maxf(1.0, float(u2["max_hp"]))
					var before: int = int(run_hp[dst])
					var after: int = maxi(0, before - amt)
					run_hp[dst] = after
					if after > 0 and BrokenCam.tier(float(after) / mx) > BrokenCam.tier(float(before) / mx):
						_shatter_later(str(u2.get("char", dst)), delay, 0.7 if BrokenCam.tier(float(after) / mx) == 1 else 1.0)
				delay += gap
			"heal":
				_number(str(e.get("dst", "")), "+%d" % int(e.get("amount", 0)), Color("#62f08c"), 40, delay)
				_ono(str(e.get("dst", "")), "PLING", Color("#62f08c"), delay + 0.05, false)
				# la cura si vede: anello e spirale verdi sul curato (prima c'era solo il numero)
				var hd: String = str(e.get("dst", ""))
				if hit_anims and home.has(hd):
					_ring(home[hd], Color("#62f08c"), 1.6)
					LightFx.rise(self, home[hd], Color("#62f08c"))
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
			"balance":
				# quanto equilibrio toglie questo colpo (lo stesso numero che scende nella barra bianca)
				if int(e.get("amount", 0)) > 0:
					_number(BattleState.BOSS_ID, "Equilibrio -%d" % int(e.get("amount", 0)), Color("#f2f0ea"), 20, delay + 0.2, 76.0)
			"break":
				(vis[BattleState.BOSS_ID] as VendingVisual).stunned = true
				if _team_follow:
					continue              # la annuncia la sequenza di squadra
				_break_moment(delay)
			"tenacity":
				# il colpo era mortale: resta in piedi con 1 PV e l'ultimate piena
				var tn: String = str(e.get("unit", ""))
				_number(tn, "TENACIA", Ui.CYAN, 30, delay + 0.3, -26.0)
				_banner("TENACIA · %s RESISTE CON 1 PV" % _uname(tn), Ui.CYAN, 0.25, 24)
			"resolve":
				_number(str(e.get("unit", "")), "DETERMINAZIONE", Color("#ffb04a"), 26, delay + 0.3, -26.0)
			"counter":
				_number(str(e.get("unit", "")), "CONTRATTACCO", Ui.YELLOW, 26, delay + 0.2, -26.0)
			"act":
				if str(e.get("unit", "")) == BattleState.BOSS_ID and BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES.get(str(e.get("move", "")), {})):
					_glitch_later(0.8, delay)
				# ARDORE: sotto il 30% dei PV chi attacca colpisce piu' forte (il motore non emette un evento: si legge dallo stato)
				var au: Dictionary = b["units"].get(str(e.get("unit", "")), {})
				var amv: Dictionary = BattleContent.MOVES.get(str(e.get("move", "")), {})
				if not au.is_empty() and str(au.get("side", "")) == "player" and BattleState.is_alive(au) and amv.has("mult") \
						and str(amv.get("target", "")) == "enemy" and float(au["hp"]) < float(au["max_hp"]) * BattleTypes.ARDOR_BELOW:
					_number(str(au["id"]), "ARDORE", Color("#ff6a5a"), 26, delay + 0.05, -26.0)
			"cover":
				_number(str(e.get("unit", "")), "COPRE " + _uname(str(e.get("who", ""))), _col_of(str(e.get("unit", ""))), 24, delay + 0.1)
			"cover_hit":
				_toast("%s si mette davanti a %s" % [_uname(str(e.get("unit", ""))), _uname(str(e.get("who", "")))], Ui.CREAM, 1.4)
			"coin":
				var testa: bool = str(e.get("side", "")) == "testa"
				_toast("TESTA! Critico sicuro" if testa else "CROCE! Saul passa energia a un compagno", Ui.YELLOW if testa else Color("#62f08c"), 1.4)
			"energy_gift":
				_number(str(e.get("dst", "")), "+%d ENERGIA" % int(e.get("amount", 0)), Ui.CYAN, 24, delay + 0.2)
			"heist":
				if int(e.get("amount", 0)) > 0:
					_toast("IL COLPO GROSSO: scudo rubato e diviso con la squadra", Color("#62f08c"), 1.6)
				else:
					_toast("IL COLPO GROSSO: niente scudi da rubare, si prende tutto in danno", Color("#62f08c"), 1.6)
			"pickpocket":
				if int(e.get("amount", 0)) > 0:
					_toast("MANO LESTA · Saul si intasca lo scudo (%d)" % int(e["amount"]), Color("#62f08c"), 1.6)
				else:
					_toast("MANO LESTA · niente scudo: Saul sfila equilibrio e si riprende l'energia", Color("#62f08c"), 1.6)
			"loot_exp":
				_toast("TASCHE PIENE · +%d%% esperienza a fine scontro" % int(e.get("total", 0)), Color("#62f08c"), 1.6)
			"steal_move":
				var smv: String = str(e.get("move", ""))
				if smv == "":
					_toast("IL TRUCCO DEL MAGO · niente di nuovo da rubare: Saul prende gli spiccioli (+1 energia)", Color("#62f08c"), 1.8)
				else:
					var fresh: bool = Progress.add_stolen(smv, _bn())
					_live_banner("MOSSA RUBATA", "%s · %s" % [BattleText.move_name(smv).to_upper(), "ora si equipaggia in pausa > SQUADRA" if fresh else "Saul ce l'aveva già"], Color("#62f08c"), 2.2)
			"finale":
				_toast("GRAN FINALE · HYPE %d%%" % int(e.get("hype", 0)), Ui.VIOLET.lightened(0.3), 1.4)
			"finale_early":
				_toast("ANTEPRIMA · il pubblico carica la squadra: +%d EN e +%d%% Ultimate" % [int(e.get("energy", 0)), int(e.get("gauge", 0))], Ui.VIOLET.lightened(0.3), 1.8)
			"break_rule":
				var rm: float = float(e.get("mult", 1.0))
				if rm > 1.0:
					_toast("%s · equilibrio x%s" % [str(e.get("name", "")), str(rm).replace(".", ",").trim_suffix(",0")], Ui.YELLOW, 1.2)
				else:
					_toast("%s · equilibrio a metà" % str(e.get("name", "")), Color("#ff7a9c"), 1.2)
			"duo":
				gap = 0.55
				_flash(0.3)
				_kick(0.6)
				Settings.buzz(40)        # il timbro col nome lo mette _do_action, prima dei colpi
			"slancio_guard":
				_toast("GUARDIA DI SLANCIO · scudo a tutta la squadra", Ui.CYAN, 1.6)
			"hype":
				if int(e.get("amount", 0)) >= 10:
					# il contatore sta su Rio, al suo posto (decisione dell'autore, 25/10/2026: sul nemico c'era gia' troppo)
					_number(str(e.get("unit", "")), "+%d HYPE" % int(e.get("amount", 0)), Ui.VIOLET.lightened(0.35), 22, delay + 0.5, 30.0, true)
			"kit_trait":
				var tr_name: String = "FUORI DALLA LUCE" if str(e.get("trait", "")) == "luce" else "VEGLIA"
				_number(str(e.get("unit", "")), tr_name, _col_of(str(e.get("unit", ""))).lightened(0.3), 22, delay)
			"rest":
				_toast("IMPULSO · CAFFÈ DI NOX · scudo e +1 energia a tutti", Color("#39b7ff"), 1.8)
			"revive":
				var rw: String = str(e.get("who", ""))
				if vis.has(rw) and vis[rw] is CharacterVisual:
					(vis[rw] as CharacterVisual).revive()
				_toast("RISPONDO IO · %s torna in piedi" % _uname(rw), Ui.CYAN, 1.8)
			"answer":
				_toast("RISPONDO IO · il prossimo colpo del nemico non passa", Ui.CYAN, 1.8)
			"nullified":
				_toast("COLPO ANNULLATO · Nox ha risposto", Ui.CYAN, 1.6)
			"dodge_half":
				_number(str(e.get("unit", "")), "DI STRISCIO", Color("#c4c2cf"), 24, delay + 0.1, -26.0)
			"dodge":
				_number(str(e.get("unit", "")), "SCHIVATO!", Ui.CYAN, 30, delay + 0.05, -26.0)
				_ono(str(e.get("unit", "")), "SWISH", Ui.CYAN, delay + 0.05, false)
			"react_mod":
				var rm: Dictionary = Progress.REACT_MODS.get(str(e.get("mod", "")), {})
				_number(str(e.get("unit", "")), str(rm.get("name", "")).to_upper(), _col_of(str(e.get("unit", ""))).lightened(0.3), 24, delay + 0.3, -52.0)
			"parry":
				var pu: String = str(e.get("unit", ""))
				if vis.has(pu) and vis[pu] is CharacterVisual:
					(vis[pu] as CharacterVisual).attack()
				_kick(0.5)
				_ono(pu, "CLANG", Ui.CYAN, delay + 0.05, true)
				delay += 0.15
			"arena", "behavior", "chain":
				var dsc: Dictionary = BattleText.describe(b, e)
				if str(dsc.get("text", "")) != "":
					_toast(str(dsc["text"]), Ui.PINK if str(dsc.get("kind", "")) == "boss" else (Ui.YELLOW if str(dsc.get("kind", "")) == "link" else Ui.CREAM), 1.6)
			"slancio":
				pass      # lo racconta _slancio_moment, a fine azione, in grande (prima era un avviso piccolo che passava inosservato)
			"phase":
				# Fase 3 del piano: la fase cambia la domanda (rompilo mentre carica) invece di togliere la Riserva
				_live_banner("FASE %d" % int(e.get("phase", 2)), "%s passa al piano B · quando carica rompilo: equilibrio x1,5" % _cap(_bn()), Ui.PINK, 2.2)
				_kick(0.8)
				_flash(0.3)
			"down":
				var du: String = str(e.get("unit", ""))
				if du != BattleState.BOSS_ID:
					_number(du, "K.O.", Color("#ff4a5a"), 64, delay + 0.1, -10.0)       # chi cade si legge subito, non solo dalla card
					_kick(0.5)
				if vis.has(du):
					var dv: Node3D = vis[du]
					if dv.has_method("ko"):
						dv.call("ko")
				if du == BattleState.BOSS_ID and _seal != null and is_instance_valid(_seal):
					_seal.stop()              # la magia lascia l'oggetto: torna un oggetto qualsiasi
					LightFx.rise(self, ENEMY_POS, LightFx.MAGIC, 1.1, 1.3)
	# legami e combo muti prima: UN solo banner per azione, il piu' forte, sotto quello della mossa
	var lb: Dictionary = CombatHud.link_banner(ev)
	if not lb.is_empty():
		_notice(str(lb.get("short", lb["text"])), lb["col"], 1.6, "chain")      # catena + poche parole
	_refresh_hud()
	await _wait(0.22 + delay)


# Quando manca poco al BREAK la barra diventa gialla e pulsa piano: il giocatore sa che il prossimo colpo puo' rompere (Star Rail: la barra della
# tenacia e' il centro del combattimento). Cambia solo quando entra o esce dalla soglia; un solo tween ripetuto e leggero.
func _brk_pulse(near: bool) -> void:
	if near == _brk_near:
		return
	_brk_near = near
	if _brk_tw != null and _brk_tw.is_valid():
		_brk_tw.kill()
	var fill := StyleBoxFlat.new()
	fill.bg_color = Ui.YELLOW if near else Color("#f2f0ea")
	fill.set_corner_radius_all(2)
	_boss_brk.add_theme_stylebox_override("fill", fill)
	_boss_brk.modulate = Color.WHITE
	if near:
		_brk_tw = _boss_brk.create_tween().set_loops()
		_brk_tw.tween_property(_boss_brk, "modulate", Color(1.35, 1.25, 0.9), 0.35)
		_brk_tw.tween_property(_boss_brk, "modulate", Color.WHITE, 0.35)


# Onomatopea a fumetto vicino al bersaglio (onomato.gd): al petto, spostata di lato cosi' non copre il numero del danno
func _ono(uid: String, word: String, col: Color, delay: float, big: bool) -> void:
	if not vis.has(uid) or _fx_layer == null:
		return
	if delay > 0.01:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or not vis.has(uid) or cam == null:
		return
	var v: Node3D = vis[uid]
	var p3: Vector3 = v.call("chest_point") if v.has_method("chest_point") else v.global_position + Vector3(0, 1, 0)
	if cam.is_position_behind(p3):
		return
	var sz: Vector2 = get_viewport().get_visible_rect().size
	# vicino al punto d'impatto, in misure dello schermo (le parole sono piccole: non coprono personaggi ne' interfaccia)
	var u: float = sz.y * 0.01
	var at: Vector2 = cam.unproject_position(p3) + Vector2(randf_range(5.0, 9.0) * u * (1.0 if randi() % 2 == 0 else -1.0), randf_range(-6.0, -1.0) * u)
	at = Vector2(clampf(at.x, sz.y * 0.2, sz.x - sz.y * 0.35), clampf(at.y, sz.y * 0.2, sz.y * 0.75))
	Onomato.pop(_fx_layer, at, word, col, big)


func _glitch_later(k: float, delay: float) -> void:
	if delay > 0.01:
		await get_tree().create_timer(delay).timeout
	if is_inside_tree() and _glitch != null:
		_glitch.pulse(k)


func _flash_later(k: float, delay: float) -> void:
	if delay > 0.01:
		await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		_flash(k)


func _uname(uid: String) -> String:
	return str(b["units"].get(uid, {}).get("name", "?")).to_upper()


func _col_of(uid: String) -> Color:
	return _col(b["units"].get(uid, {}))


# EFFICACE (giallo, grande) o DEBOLE (grigio) sotto il numero del colpo, in entrambe le direzioni.
# Il primo colpo che il giocatore mette a segno sul boss ne rivela il colore anche per la riga dei comandi.
func _color_tag(e: Dictionary, dst: String, delay: float, lift: float = 0.0) -> void:
	var src: String = str(e.get("src", ""))
	if src == "" or src == dst or not b["units"].has(src) or not b["units"].has(dst):
		return
	if dst == BattleState.BOSS_ID and str(b["units"][src].get("side", "")) != "boss":
		_boss_known = true
	var h: Dictionary = ColorHint.eval(str(b["units"][src].get("color", "")), str(b["units"][dst].get("color", "")))
	if dst == BattleState.BOSS_ID and BattleTypes.hits_weak2(b["units"][src], b["units"][dst]):
		_number(dst, "PUNTO DEBOLE", Ui.YELLOW, 30, delay + 0.06, 40.0 + lift)
	match str(h["tipo"]):
		"efficace":
			# EFFICACE: freccia in su, piu' grande e un lampo leggero (Star Rail: la debolezza colpita si sente); prima era solo una parola gialla
			_number(dst, "▲ " + str(h["testo"]) + "!", Ui.YELLOW, 40, delay + 0.06, 44.0 + lift)
			_flash_later(0.14, delay)
		"debole":
			_number(dst, "▼ " + str(h["testo"]), Color("#c4c2cf"), 26, delay + 0.06, 34.0 + lift)


# PRESTAZIONI: ogni grandezza nuova di carattere col contorno va disegnata da zero (sul telefono uno scatto nel momento del
# colpo): le grandezze si arrotondano a pochi gradini, gia' preparati a inizio battaglia (_warm_fonts).
const NUM_SIZES: Array = [20, 24, 30, 40, 52, 64]


static func _snap_size(size: int) -> int:
	for s in NUM_SIZES:
		if size <= int(s):
			return int(s)
	return int(NUM_SIZES[-1])


func _number(uid: String, text: String, col: Color, size: int, delay: float, yoff: float = 0.0, at_home: bool = false) -> void:
	if not vis.has(uid):
		return
	size = _snap_size(maxi(18, int(round(float(size) * 0.85))) if size < 60 else size)      # numeri piu' piccoli: la scena resta libera
	var v: Node3D = vis[uid]
	var p3: Vector3 = v.call("head_point") if v.has_method("head_point") else v.global_position
	if at_home and home.has(uid):
		# sopra il personaggio al suo posto, non dove si trova mentre colpisce (accanto al nemico)
		p3 = home[uid] + (p3 - v.global_position)
	var l := Ui.label(text, size, col, Ui.display(), 10)
	l.modulate.a = 0.0
	_fx_layer.add_child(l)
	var jitter := Vector2(randf_range(-30, 30), randf_range(-10, 10))
	if yoff != 0.0:
		jitter = Vector2(randf_range(-8, 8), yoff)
	var tw := l.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		if cam.is_position_behind(p3):
			l.queue_free()
			return
		l.position = cam.unproject_position(p3) - l.get_combined_minimum_size() * 0.5 + jitter
		var vsz: Vector2 = get_viewport().get_visible_rect().size     # sempre dentro lo schermo (prima finiva tagliato sul bordo)
		l.position.x = clampf(l.position.x, 8.0, vsz.x - l.get_combined_minimum_size().x - 8.0)
		l.position.y = clampf(l.position.y, 60.0, vsz.y - l.get_combined_minimum_size().y - 8.0)
		l.modulate.a = 1.0
		l.scale = Vector2(1.3, 1.3)
		l.pivot_offset = l.get_combined_minimum_size() * 0.5)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15)
	tw.parallel().tween_property(l, "position:y", -70.0, 0.9).as_relative()
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)


var _ring_meshes: Dictionary = {}           # colore -> disco gia' costruito (prima se ne costruiva uno a ogni colpo)


func _ring(at: Vector3, col: Color, radius: float) -> void:
	var key: String = col.to_html() + ("r" if Settings.light_fx else "")
	if not _ring_meshes.has(key):
		_ring_meshes[key] = MeshBatch.disc(1.0, Color(col.r, col.g, col.b, 0.7 if not Settings.light_fx else 0.4), 20, 0.05)
	var mi := MeshInstance3D.new()
	mi.mesh = _ring_meshes[key]
	mi.material_override = Toon.glow()
	mi.position = at
	mi.scale = Vector3(0.2, 1, 0.2)
	add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius), 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "transparency", 1.0, 0.3)
	tw.tween_callback(mi.queue_free)


# Scintille d'impatto nel momento del colpo (arancio; avorio e piu' grandi sul critico)
func _sparks_later(uid: String, delay: float, crit: bool) -> void:
	if delay > 0.01:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or not vis.has(uid):
		return
	var v: Node3D = vis[uid]
	var at: Vector3 = v.call("chest_point") if v.has_method("chest_point") else v.global_position + Vector3(0, 1, 0)
	LightFx.sparks(self, at, LightFx.IVORY if crit else LightFx.IMPACT, 16 if crit else 10)


# Chi e' di turno: cerchio di luce del suo colore ai piedi e la telecamera che lo inquadra (vuoto = turno del nemico)
func _fx_turn(uid: String) -> void:
	if uid == "" or not b["units"].has(uid) or not home.has(uid):
		if _glyph != null and is_instance_valid(_glyph):
			_glyph.stop()
		if _cam_hud != null:
			_cam_hud.watch("", Ui.CREAM, 1)
		return
	var u: Dictionary = b["units"][uid]
	var col: Color = _col(u)
	if _glyph == null or not is_instance_valid(_glyph):
		_glyph = LightFx.glyph(self, home[uid], col)
	else:
		_glyph.move_to(home[uid], col)
	if _cam_hud != null:
		_cam_hud.watch(str(u.get("name", "")), col, 2 + maxi(0, slots.find(cur_pid)))


# Battuta di un personaggio in battaglia: stesso fumetto di Echo (lastra storta, bordo e ritratto del personaggio).
# Il testo non si modifica: arriva dai dialoghi. sec <= 0: resta finche' non si chiama _say_off().
func _say(u: Dictionary, text: String, sec: float = 0.0) -> void:
	if _say_lbl == null or _say_balloon == null:
		return
	var col: Color = _col(u)
	_say_balloon.speaker(str(u.get("char", "")), str(u.get("name", "")).to_upper(), col)
	_say_lbl.text = text
	_say_lbl.add_theme_color_override("font_color", Ui.CREAM)
	_say_lbl.modulate.a = 1.0
	_say_lbl.visible = true
	_say_seq += 1
	if sec > 0.0:
		var mine: int = _say_seq
		get_tree().create_timer(sec).timeout.connect(func() -> void:
			if mine == _say_seq:
				_say_off())


func _say_off() -> void:
	if _say_lbl != null:
		_say_lbl.text = ""
		_say_lbl.visible = false


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
	line_l.text = ""
	_say(u, "«" + DialogData.ult_line(str(u["char"])) + "»")      # la battuta sta nel fumetto del personaggio
	_cutin.modulate.a = 0.0
	band.position.x = -_root.size.x
	var ch: String = str(u["char"])
	var seen: bool = _cutin_seen.has(ch)
	var hold: float = 0.45 if seen else 1.1
	_cutin_seen[ch] = true
	# I quattro della squadra: scena "alla Edgerunners" (EdgeCutin), ognuno col suo colore; un poco piu' lunga per far leggere i livelli (max ~1,6 s con le dissolvenze)
	var edge: EdgeCutin = null
	var dark: Node = _cutin.get_node("Dark")
	if EdgeCutin.PALETTES.has(ch):
		edge = EdgeCutin.new()
		_cutin.add_child(edge)
		_cutin.move_child(edge, 0)
		edge.start(ch, EdgeCutin.pal_for(ch))
		dark.visible = false
		hold = 0.8 if seen else 1.2
	_cutin_on = true
	var tw := create_tween()
	_cutin_tw = tw
	tw.tween_property(_cutin, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(band, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(_cutin, "modulate:a", 0.0, 0.18)
	tw.tween_callback(_cutin_finish)
	await _cutin_end
	if edge != null:
		edge.queue_free()                # le viewport a bassa risoluzione si liberano subito
		dark.visible = true
	_say_off()
	_cutin.visible = false
	Breadcrumb.mark("battaglia")


# Chiude il cut-in (a fine animazione o saltato al tocco): il colpo parte subito
func _cutin_finish() -> void:
	if not _cutin_on:
		return
	_cutin_on = false
	if _cutin_tw != null and _cutin_tw.is_valid():
		_cutin_tw.kill()
	_cutin_tw = null
	_cutin.modulate.a = 0.0
	_say_off()
	_cutin_end.emit()


# ---------------------------------------------------------------- fine

func _shatter_later(key: String, delay: float, strength: float, big: bool = false) -> void:
	if _broken == null:
		return
	if delay > 0.01:
		await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		var imp := Vector2(-1, -1)
		if big and vis.has(BattleState.BOSS_ID) and cam != null:
			# le crepe partono dal petto del nemico (dove e' arrivato il colpo), non da un punto a caso
			var p3: Vector3 = (vis[BattleState.BOSS_ID] as Node).call("chest_point")
			if not cam.is_position_behind(p3):
				var sz: Vector2 = get_viewport().get_visible_rect().size
				var u: Vector2 = cam.unproject_position(p3)
				imp = Vector2(clampf(u.x / maxf(1.0, sz.x), 0.15, 0.85), clampf(u.y / maxf(1.0, sz.y), 0.15, 0.8))
		_broken.shatter(key, strength, imp, big)


# IL MOMENTO DEL BREAK (Star Rail / Persona): fermo immagine breve + lampo + vetro che esplode dal nemico + scritta BREAK + scossa.
# Si usa sia per il colpo che rompe sia, in versione piu' corta, dall'attacco di squadra.
func _break_moment(delay: float, short: bool = false) -> void:
	_ono(BattleState.BOSS_ID, "KRAK", Color("#ff2340"), delay + 0.02, true)
	_glitch_later(1.0, delay)
	_shatter_later("boss", delay, 0.8 if short else 1.0, true)
	_sparks_later(BattleState.BOSS_ID, delay, true)
	# la riga sotto la scritta sostituisce il toast di prima, che finiva proprio sopra al BREAK
	_break_stamp(delay, "%s è %s" % [_cap(_bn()), _g("a terra", "a terra") if short else _g("stordito", "stordita")], 0.45 if short else 0.85)
	_flash(0.4 if short else 0.6)
	_kick(0.6 if short else 0.9)


const BREAK_SIZE: int = 104


# Scritta BREAK: lastra bianca storta con ombra rossa e testo scuro (alto contrasto alla Persona), entra con uno scatto grande
# e si ferma al centro-alto, lontana da comandi e descrizioni. Costa 4 nodi e un tween breve.
func _break_stamp(delay: float, sub: String = "", hold: float = 0.85) -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(root, 0.5, 0.28, 0.5, 0.28, -290, -70, 290, 110)
	root.pivot_offset = Vector2(290, 70)
	root.modulate.a = 0.0
	var red := ColorRect.new()
	red.color = Color("#ff3d5a")
	red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(red, 0, 0, 1, 0, 16, 12, 16, 152)
	root.add_child(red)
	var slab := ColorRect.new()
	slab.color = Color("#fff8ee")
	slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(slab, 0, 0, 1, 0, 0, 0, 0, 140)
	root.add_child(slab)
	var txt := Ui.label("BREAK!", BREAK_SIZE, Ui.INK, Ui.display(), 0)
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Ui.place(txt, 0, 0, 1, 0, 0, 0, 0, 140)
	root.add_child(txt)
	if sub != "":
		var sl := Ui.label(sub, 30, Ui.CREAM, Ui.display(), 10)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ui.place(sl, 0, 0, 1, 0, 0, 150, 0, 190)
		root.add_child(sl)
	_fx_layer.add_child(root)
	root.scale = Vector2(2.4, 2.4)
	root.rotation_degrees = -16.0
	var tw := root.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(root, "modulate:a", 1.0, 0.04)
	tw.parallel().tween_property(root, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root, "rotation_degrees", -5.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)          # nella sequenza di squadra resta meno: poi arriva la cornice REC
	tw.tween_property(root, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(root, "scale", Vector2(1.08, 1.08), 0.25)
	tw.tween_callback(root.queue_free)


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
	if tutorial and win:
		await _tut("tut_fine")
		Story.set_flag("tutorial_fatto")
		if not is_inside_tree():
			return
	elif lezioni and win:
		await _tut("tut_fine")
		if not is_inside_tree():
			return
	if primo and win:
		Story.set_flag("tutorial_fatto")
	# nella demo dal menu: due battute in stile Persona; nella storia ci pensa la scena dopo
	if ritorno.is_empty() and not tutorial:
		var dlg := DialogBox.new()
		_root.add_child(dlg)
		await get_tree().process_frame
		var key: String = "vittoria" if win else "sconfitta"
		dlg.play(DialogData.lines(key), DialogData.recap(key))
		await dlg.finished
		if not is_inside_tree():
			return
	var ln: Array = []
	# ESPERIENZA (stile Persona 5): a fine scontro vinto nella storia tutti salgono; si salva subito con la vittoria
	if win and not ritorno.is_empty() and _exp_report.is_empty():
		var gain: int = Progress.battle_exp(level, not minore, int(b.get("exp_bonus", 0)), int(_args.get("replica", 0)))
		_exp_report = Progress.grant(gain)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.box(Color(0.07, 0.04, 0.12, 0.95), Ui.CREAM, 4, 6, 8))
	if _exp_report.is_empty():
		Ui.place(panel, 0.5, 0.5, 0.5, 0.5, -340, -170, 340, 170)
	else:
		Ui.place(panel, 0.5, 0.5, 0.5, 0.5, -470, -300, 470, 300)
	_root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)
	_hint.visible = false
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
	if not _exp_report.is_empty():
		_exp_rows(vb)
	if not ritorno.is_empty():
		if win:
			_save_win()
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


# Righe dell'esperienza: nome, livello, barra che si riempie; LIVELLO SU! e gli sblocchi nuovi sotto
func _exp_rows(vb: VBoxContainer) -> void:
	var head := Ui.label("+%d ESPERIENZA%s" % [int(_exp_report[0]["gain"]), ("  (Saul: +%d%%)" % int(b.get("exp_bonus", 0))) if int(b.get("exp_bonus", 0)) > 0 else ""], 24, Ui.CYAN, Ui.display(), 6)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(head)
	var news: Array = []
	for i in _exp_report.size():
		var r: Dictionary = _exp_report[i]
		var c: String = str(r["char"])
		var col: Color = Ui.BATTLE_COLORS.get(str(BattleContent.CHARACTERS[c].get("color", "")), Ui.CREAM)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vb.add_child(row)
		var nm := Ui.label(str(BattleContent.CHARACTERS[c]["name"]).to_upper(), 24, col.lightened(0.3), Ui.display(), 6)
		nm.custom_minimum_size.x = 120
		row.add_child(nm)
		var lv := Ui.label("LV %d" % int(r["lv0"]), 24, Ui.CREAM, Ui.display(), 6)
		lv.custom_minimum_size.x = 90
		row.add_child(lv)
		var bar := _bar(col, 22)
		bar.custom_minimum_size.x = 400
		bar.max_value = 1000
		bar.value = float(r["r0"]) * 1000.0
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		var up := Ui.label("", 24, Ui.YELLOW, Ui.display(), 8)
		row.add_child(up)
		var ups: int = int(r["lv"]) - int(r["lv0"])
		var tw := bar.create_tween()
		tw.tween_interval(0.3 + 0.15 * i)
		for k in ups:
			tw.tween_property(bar, "value", 1000.0, 0.35)
			tw.tween_callback(func() -> void:
				bar.value = 0.0
				lv.text = "LV %d" % (int(lv.text.substr(3)) + 1)
				up.text = "LIVELLO SU!"
				Settings.buzz(30))
		tw.tween_property(bar, "value", float(r["r"]) * 1000.0, 0.35)
		var left: int = int(ceil(float(Progress.exp_need(int(r["lv"]))) * (1.0 - float(r["r"]))))
		tw.tween_callback(func() -> void:
			if up.text == "":
				up.add_theme_color_override("font_color", Ui.CREAM)
				up.text = "LIVELLO MASSIMO" if int(r["lv"]) >= Progress.MAX_LEVEL else "mancano %d" % left)
		for nw in r["news"]:
			news.append("%s · %s %s: %s" % [str(BattleContent.CHARACTERS[c]["name"]).to_upper(), "NUOVO" if str(nw["kind"]) == "trait" else "NUOVA", str(SquadMenu.KIND_NAMES.get(str(nw["kind"]), "")).to_upper(), str(nw["name"])])
	if not news.is_empty():
		var nl := Ui.label("\n".join(news.slice(0, 6)) + ("\n…e altro: pausa > SQUADRA" if news.size() > 6 else "\nSi equipaggiano in pausa > SQUADRA"), 20, Ui.YELLOW, null, 6)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(nl)


# La vittoria si salva subito, non al tocco su CONTINUA: chi chiude l'app sul pannello non deve rifare la battaglia
var _win_saved: bool = false


func _save_win() -> void:
	if _win_saved:
		return
	_win_saved = true
	if str(ritorno.get("tipo", "")) == "area":
		Story.area_state = (ritorno.get("vinto", {}) as Dictionary).duplicate(true)
		Story.save()
	else:
		Story.flags.erase("debolezza_nota")
		Story.advance()


func _continue_story() -> void:
	_save_win()
	if str(ritorno.get("tipo", "")) == "area":
		_main().go("area", {"area": str(ritorno.get("area", "")), "resume": ritorno.get("vinto", {})})
	else:
		_main().next_story()


# ---------------------------------------------------------------- interfaccia

func _build_ui() -> void:
	_broken = BrokenCam.new()
	add_child(_broken)
	_glitch = GlitchFx.new()
	add_child(_glitch)
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	_root = Control.new()
	Ui.place(_root, 0, 0, 1, 1)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	# lo sguardo di Echo sotto a tutto; dentro le Anomalie le telecamere non arrivano
	_cam_hud = CamHud.new()
	_cam_hud.anomaly = arena.begins_with("anomalia") or arena in ["rosso", "blu", "verde"]
	_cam_hud.tag_y = 70.0 if Settings.show_fps else 14.0      # REC CAM in alto a sinistra, SOPRA il riquadro dei turni
	_root.add_child(_cam_hud)
	_fx_layer = Control.new()
	Ui.place(_fx_layer, 0, 0, 1, 1)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fx_layer)
	_spot = CmdWheel.make_spot()
	_fx_layer.add_child(_spot)
	_reticle = Reticle.new()
	_fx_layer.add_child(_reticle)
	_wheel = CmdWheel.new()
	_wheel.visible = false
	_wheel.tapped.connect(_wheel_tap)
	_wheel.hovered.connect(_wheel_hover)
	_fx_layer.add_child(_wheel)

	# ordine dei turni: una riga di lastrine in alto, accanto al nemico (Metaphor: i turni in alto al centro). Si vede solo
	# mentre si sceglie: durante le mosse l'HUD si svuota (Persona 5)
	var ob := PanelContainer.new()
	ob.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	Ui.place(ob, 0.5, 0.0, 0.5, 0.0, 0, 12, 0, 12)      # al centro in alto: l'etichetta REC a sinistra cambia lunghezza
	ob.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(ob)
	_order_panel = ob
	var ov := HBoxContainer.new()
	ov.add_theme_constant_override("separation", 6)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ob.add_child(ov)
	_order_title = Ui.label("TURNO 1", 16, Ui.YELLOW, Ui.display(), 6)
	ov.add_child(_order_title)
	_order_box = HBoxContainer.new()
	_order_box.add_theme_constant_override("separation", 4)
	_order_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(_order_box)

	# nemico: lastra nera storta in alto a sinistra (Persona 5: il nome del nemico in alto a sinistra), vita ed equilibrio
	# come due barre sottili sotto il nome; DEBOLE A e la prossima mossa solo mentre si sceglie
	var bp := VBoxContainer.new()
	Ui.place(bp, 0, 0, 0, 0, 24, 60, 324, 60)      # la posizione vera la decide _place_boss_tag (sopra il nemico)
	_boss_panel = bp
	bp.add_theme_constant_override("separation", 4)
	bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bp)
	_boss_name = Ui.label(_bname(), 22, Ui.CREAM, Ui.display(), 0)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_boss_name.add_theme_stylebox_override("normal", Ui.plate(Color(0.02, 0.01, 0.03, 0.92), Color("#ff2340"), -0.18, 5))
	bp.add_child(_boss_name)
	_boss_hp = _bar(Color("#ff4b6e"), 16)
	bp.add_child(_boss_hp)
	_boss_ghost = _ghost_bar(_boss_hp)
	_boss_hp_txt = Ui.label("", 14, Ui.CREAM, null, 4)
	_boss_hp_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hp.add_child(_boss_hp_txt)
	Ui.place(_boss_hp_txt, 0, 0, 1, 1)
	_boss_hp_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_brk = _bar(Color("#f2f0ea"), 14)
	bp.add_child(_boss_brk)
	# il nome della barra bianca dentro la barra, crema col contorno scuro, si legge su barra piena e vuota (prima grigio chiaro da 12: non si leggeva): quando arriva a zero il boss si rompe
	_brk_lbl = Ui.label("EQUILIBRIO", 12, Ui.CREAM, Ui.display(), 4)
	var brk_t := _brk_lbl
	brk_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_brk.add_child(brk_t)
	Ui.place(brk_t, 0, 0, 1, 1)
	brk_t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# DEBOLE A ... : chi deve colpire si legge sotto il nemico, non solo nella legenda in alto a destra (Persona 5: l'analisi del nemico)
	_weak_row = HBoxContainer.new()
	_weak_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_weak_row.add_theme_constant_override("separation", 2)
	_weak_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bp.add_child(_weak_row)
	_weak_k = Ui.plate_label("DEBOLE A", 15, Ui.CREAM, Color(0.05, 0.03, 0.08, 0.9), Ui.CREAM)
	_weak_row.add_child(_weak_k)
	_weak_v = Ui.plate_label("???", 15, Ui.INK, Color("#9a94a8"), Ui.INK)
	_weak_row.add_child(_weak_v)
	# la minaccia su una lastra scura col bordo rosso: si legge su cielo chiaro e su insegne (prima testo bianco nudo da 20)
	_tele = Ui.label("", 15, Ui.CREAM, Ui.display(), 0)
	_tele.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tele.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bp.add_child(_tele)

	_party_back = Control.new()
	Ui.place(_party_back, 0, 0, 1, 1)
	_party_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_back.draw.connect(_draw_party_back)
	_root.add_child(_party_back)
	# squadra (basso a destra, righe compatte come nella V2): il centro e il lato sinistro restano alla scena e alla ruota
	var party := VBoxContainer.new()
	Ui.place(party, 1.0, 1.0, 1.0, 1.0, -340, -300, -24, -16)
	party.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	party.grow_vertical = Control.GROW_DIRECTION_BEGIN
	party.alignment = BoxContainer.ALIGNMENT_END
	party.add_theme_constant_override("separation", 4)
	party.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(party)
	for i in slots.size():
		var card := _make_card()
		party.add_child(card["panel"])
		_cards.append(card)
	party.sort_children.connect(_party_back.queue_redraw)
	_intro_panels(ob, bp, party)

	# comandi (basso a destra)
	_cmd_box = VBoxContainer.new()
	# REAZIONE in alto a destra, sotto la barra rapida: lontana dalla squadra e da CONFERMA (in basso a sinistra), cosi' un clic
	# sbagliato non fa partire una reazione. La colonna non prende clic: solo i suoi tasti.
	Ui.place(_cmd_box, 1.0, 1.0, 1.0, 1.0, -480, -262, -16, -262)      # sopra la squadra; compare solo quando si puo' reagire
	_cmd_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cmd_box.alignment = BoxContainer.ALIGNMENT_END
	# se un testo e' piu' largo della colonna, la colonna cresce verso sinistra e non esce dallo schermo
	_cmd_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_cmd_box.grow_vertical = Control.GROW_DIRECTION_BEGIN       # con REAZIONE e Ultimate in diretta la colonna cresce verso l'alto
	_cmd_box.add_theme_constant_override("separation", 8)
	_root.add_child(_cmd_box)
	# REAZIONE (contestuale): sta in cima alla colonna, che cresce verso l'alto; nascosta quando non c'e' una finestra
	_react_box = VBoxContainer.new()
	_react_box.add_theme_constant_override("separation", 4)
	_react_box.visible = false
	_react_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cmd_box.add_child(_react_box)
	_react_lbl = Ui.label("", 16, Ui.CREAM, null, 5)
	_react_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_react_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # resta nella colonna, non sconfina sulla barra del nemico
	_react_box.add_child(_react_lbl)
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 6)
	rrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_react_box.add_child(rrow)
	# una riga sola: la scritta piccola a sinistra dei tasti (prima una riga sopra: la colonna saliva fin sul nemico)
	_react_box.remove_child(_react_lbl)
	_react_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_react_lbl.add_theme_font_size_override("font_size", 13)
	_react_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rrow.add_child(_react_lbl)
	var rcols: Dictionary = {"schivata": Ui.CYAN, "intercettazione": Color("#62f08c"), "interruzione": Ui.PINK, "soccorso": Ui.YELLOW}
	for rid in ["schivata", "intercettazione", "interruzione", "soccorso"]:
		var rb: Button = Ui.button(str(REACT_SHORT[rid]), rcols[rid], 15)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.custom_minimum_size.y = 52.0 if Ui.is_touch() else 40.0
		rb.pressed.connect(_react_cmd.bind(rid))
		rb.visible = false
		rrow.add_child(rb)
		_react_btns[rid] = rb
	var lrow2 := HBoxContainer.new()
	lrow2.add_theme_constant_override("separation", 6)
	lrow2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_react_box.add_child(lrow2)
	for k in 3:
		var lb: Button = Ui.button("", Ui.PINK, 17)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.clip_text = true
		lb.visible = false
		lb.pressed.connect(_live_ult.bind(k))
		lrow2.add_child(lb)
		_live_btns.append(lb)
	_btn_ult = Ui.button("ULTIMATE", Ui.PINK, 26)
	_btn_ult.pressed.connect(_command.bind("ult"))
	_cmd_box.add_child(_btn_ult)
	_btn_skill = Ui.button("ABILITÀ", Ui.CYAN, 24)
	_btn_skill.pressed.connect(_command.bind("skill"))
	_cmd_box.add_child(_btn_skill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# i quattro comandi ora stanno sulla ruota attorno al personaggio: i bottoni restano (stato, tastiera) ma non si vedono
	for bt in [_btn_ult, _btn_skill, _btn_guard, _btn_atk]:
		(bt as Control).visible = false
	_show_commands(false)

	_turn_lbl = Ui.label("", 30, Ui.CREAM, Ui.display(), 10)
	Ui.place(_turn_lbl, 1.0, 1.0, 1.0, 1.0, -600, -385, -16, -340)
	_turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_turn_lbl)
	_kit_lbl = Ui.label("", 20, Ui.CREAM, null, 6)
	Ui.place(_kit_lbl, 1.0, 1.0, 1.0, 1.0, -620, -392, -16, -392)
	_kit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kit_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kit_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_kit_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_kit_lbl)
	_hint = Ui.label("", 18, Ui.CREAM, null, 5)
	# a sinistra sotto i TURNI, dentro il fumetto di Echo (come l'alleata che parla in Persona): il centro resta alla scena
	# in basso a sinistra, nello stesso angolo della didascalia della scelta (che lo sostituisce quando scegli): la ruota attorno al
	# personaggio resta libera (prima il fumetto le stava sopra quando il personaggio era a sinistra)
	Ui.place(_hint, 0.0, 1.0, 0.0, 1.0, 96, -40, 520, -40)
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(EchoBalloon.new(_hint))
	_root.add_child(_hint)

	# in alto a destra: pausa, AUTO, velocita'
	var tr := HBoxContainer.new()
	_top_bar = tr
	Ui.place(tr, 1.0, 0, 1.0, 0, -480, 12, -16, 56)      # una sola riga di lastre scure e piccole (Metaphor: i tasti rapidi non rubano la scena)
	tr.alignment = BoxContainer.ALIGNMENT_END
	tr.add_theme_constant_override("separation", 8)
	_root.add_child(tr)
	_btn_fast = _quick_btn("x1", 58)
	_btn_fast.pressed.connect(_toggle_fast)
	tr.add_child(_btn_fast)
	_btn_auto = _quick_btn("AUTO", 92)
	_btn_auto.pressed.connect(_toggle_auto)
	tr.add_child(_btn_auto)
	var pb := _quick_btn("II", 58)
	pb.pressed.connect(_open_pause)

	# legenda dei colori: chiusa, un tasto COLORI sotto i pulsanti in alto a destra (chi colpire lo dice gia' DEBOLE A sotto
	# il nemico: una cosa per volta). Aperta: le due catene con le parole, A > B = A batte B (+50% danno)
	var lbtn := _quick_btn("COLORI", 100)
	lbtn.pressed.connect(func() -> void:
		_legend.visible = not _legend.visible)
	tr.add_child(lbtn)
	tr.add_child(pb)
	var leg := PanelContainer.new()
	_legend = leg
	leg.add_theme_stylebox_override("panel", Ui.box(Color(0.06, 0.03, 0.1, 0.9), Ui.INK, 3, 6, 0))
	Ui.place(leg, 1.0, 0, 1.0, 0, -16, 66, -16, 66)
	leg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	leg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leg.visible = false
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 6)
	leg.add_child(lcol)
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 5)
	lcol.add_child(lrow)
	_legend_row(lrow, ["rosso", "verde", "blu", "rosso"], ">")
	lcol.add_child(Ui.label("ROSSO batte VERDE, VERDE batte BLU, BLU batte ROSSO", 16, Ui.CREAM))
	var lchain2 := HBoxContainer.new()
	lchain2.add_theme_constant_override("separation", 5)
	lcol.add_child(lchain2)
	_legend_row(lchain2, ["giallo", "viola"], "<>")
	lcol.add_child(Ui.label("GIALLO e VIOLA si battono a vicenda · +50% col colore vincente", 16, Ui.CREAM))
	_root.add_child(leg)

	# sequenza dell'ultimate
	_cutin = Control.new()
	Ui.place(_cutin, 0, 0, 1, 1)
	_cutin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cutin.visible = false
	_root.add_child(_cutin)
	var dark := ColorRect.new()
	dark.name = "Dark"
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
	# fumetto della battuta (sopra la fascia, a sinistra): il ritratto sporge a sinistra del testo
	_say_lbl = Ui.label("", 26, Ui.CREAM, null, 7)
	_say_lbl.name = "Say"
	Ui.place(_say_lbl, 0.0, 0.66, 0.0, 0.66, 190, -118, 1010, -118)
	_say_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_say_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_say_lbl.visible = false
	_say_balloon = EchoBalloon.new(_say_lbl)
	_say_balloon.fit = true
	_cutin.add_child(_say_balloon)
	_cutin.add_child(_say_lbl)


# Persona 5: mentre qualcuno fa la mossa l'HUD si svuota. Restano le vite (squadra e nemico) e il nome della mossa;
# turni, DEBOLE A, prossima mossa, consigli di Echo e tasti rapidi tornano quando tocca di nuovo scegliere.
# (Con AUTO acceso i tasti rapidi restano: servono per spegnerlo.)
func _hud_focus(choice: bool) -> void:
	_choice_hud = choice
	# durante la mossa restano: nome della mossa, effetti (gli avvisi) e vite della squadra. Il nemico torna quando si sceglie.
	for c in [_order_panel, _boss_panel, _weak_row, _tele, _hint]:
		if c != null:
			(c as Control).visible = choice
	if _top_bar != null:
		_top_bar.visible = choice or auto_on
	if _legend != null and not choice:
		_legend.visible = false
	_stack_notices()


# Tasto della barra rapida in alto a destra: lastra scura, scritta crema, piccolo (resta grande abbastanza per il dito)
func _quick_btn(text: String, w: float) -> Button:
	var b: Button = Ui.button(text, Color(0.05, 0.03, 0.08, 0.78), 14, w * 0.8)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Ui.CREAM)
	b.add_theme_stylebox_override("normal", Ui.box(Color(0.05, 0.03, 0.08, 0.72), Color(Ui.CREAM, 0.55), 2, 4, 0))
	b.add_theme_stylebox_override("hover", Ui.box(Color(0.12, 0.08, 0.18, 0.85), Ui.CREAM, 2, 4, 0))
	b.add_theme_stylebox_override("pressed", Ui.box(Color(0.2, 0.14, 0.28, 0.9), Ui.CREAM, 2, 4, 0))
	b.custom_minimum_size.y = 48.0 if Ui.is_touch() else 34.0
	return b


# Disegna una volta, quasi trasparenti, cifre e lettere in tutte le grandezze dei numeri dei colpi: il telefono prepara
# subito i caratteri col contorno invece di farlo nel mezzo dell'attacco di squadra.
func _warm_fonts() -> void:
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.01
	_fx_layer.add_child(box)
	for sz in NUM_SIZES:
		var l := Ui.label("0123456789!+-% ABCDEFGHIJKLMNOPQRSTUVWXYZÀÈ·", int(sz), Ui.CREAM, Ui.display(), 10)
		l.position = Vector2(0, 0)
		box.add_child(l)
	Onomato.warm(_fx_layer)
	var lb := Ui.label("BREAK!", BREAK_SIZE, Ui.INK, Ui.display(), 0)       # la scritta del BREAK compare nel momento piu' forte: niente scatto
	box.add_child(lb)
	for i in 3:
		await get_tree().process_frame
	if is_instance_valid(box):
		box.queue_free()


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


# Scia della barra PV (picchiaduro, Persona): una barra chiara dietro, che resta dov'era e scende poco dopo il colpo.
# Il fondo passa alla scia, la barra vera disegna solo il pieno sopra.
func _ghost_bar(pb: ProgressBar) -> ProgressBar:
	var g := _bar(Ui.CREAM, pb.custom_minimum_size.y)
	g.show_behind_parent = true
	pb.add_child(g)
	pb.move_child(g, 0)
	Ui.place(g, 0, 0, 1, 1)
	pb.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	return g


func _ghost_to(g: ProgressBar, v: float, mx: float) -> void:
	if g == null:
		return
	g.max_value = mx
	if v >= g.value:
		if g.has_meta("tw"):
			(g.get_meta("tw") as Tween).kill()
			g.remove_meta("tw")
		g.value = v
		g.set_meta("to", v)
		return
	if float(g.get_meta("to", -1.0)) == v:
		return
	g.set_meta("to", v)
	if g.has_meta("tw"):
		(g.get_meta("tw") as Tween).kill()
	var tw := g.create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(g, "value", v, 0.45).set_ease(Tween.EASE_IN)
	g.set_meta("tw", tw)


func _static_set(uid: String, on: bool, tint: Color) -> void:
	if not _statics.has(uid):
		if not on or not vis.has(uid):
			return
		var fx := StaticFx.new(tint)
		(vis[uid] as Node).add_child(fx)
		_statics[uid] = fx
	var f: StaticFx = _statics[uid]
	if is_instance_valid(f):
		f.set_on(on)


# Il colore di chi colpisce batte quello del nemico, e il giocatore lo sa gia' (indizio o primo colpo)
func _beats_boss(col: String, boss: Dictionary) -> bool:
	if not (_boss_known or not weak.is_empty()):
		return false
	return col != "" and BattleTypes.color_multiplier(col, str(boss.get("color", ""))) > 1.0


func _order_chip(col: Color, now: bool) -> StyleBoxFlat:
	var key: String = col.to_html() + ("|1" if now else "|0")
	if not _order_chips.has(key):
		_order_chips[key] = Ui.plate(col, Ui.INK, -0.18, 6) if now else Ui.plate(Color(0.05, 0.03, 0.08, 0.82), col, -0.18, 5)
	return _order_chips[key]


# Minaccia: lastra scura col bordo rosso; colpo FORTE su lastra rossa piena; nemico stordito in giallo
func _tele_dress(state: String) -> void:
	if state == _tele_state:
		return
	_tele_state = state
	match state:
		"forte":
			_tele.add_theme_stylebox_override("normal", Ui.plate(Color("#d0122f"), Ui.INK))
			_tele.add_theme_color_override("font_color", Ui.CREAM)
		"stordito":
			_tele.add_theme_stylebox_override("normal", Ui.plate(Color(0.05, 0.03, 0.08, 0.9), Ui.YELLOW))
			_tele.add_theme_color_override("font_color", Ui.YELLOW)
		_:
			_tele.add_theme_stylebox_override("normal", Ui.plate(Color(0.05, 0.03, 0.08, 0.9), Color("#ff3b4e")))
			_tele.add_theme_color_override("font_color", Ui.CREAM)


# DEBOLE A: ??? finche' il giocatore non conosce il colore del nemico, poi il colore che lo batte e chi ce l'ha
func _weak_refresh(boss: Dictionary) -> void:
	var bc: String = str(boss.get("color", ""))
	var beater: String = ""
	for k in BattleTypes.BEATS:
		if str(BattleTypes.BEATS[k]) == bc:
			beater = str(k)
	if not weak.is_empty():
		beater = str(weak[0]).to_lower()
	var known: bool = _boss_known or not weak.is_empty()
	var sig: String = "%s|%s|%s" % [beater, known, ended]
	if sig == _weak_sig:
		return
	_weak_sig = sig
	_weak_row.visible = beater != "" and not ended
	if not known:
		_weak_v.text = "???"
		_weak_v.add_theme_stylebox_override("normal", Ui.plate(Color("#9a94a8"), Ui.INK))
		return
	var who: String = _who_is(beater.to_upper())
	_weak_v.text = beater.to_upper() + (" · " + who.to_upper() if who != "chi ha quel colore" else "")
	_weak_v.add_theme_stylebox_override("normal", Ui.plate(Ui.BATTLE_COLORS.get(beater, Ui.CREAM), Ui.INK))
	_weak_v.pivot_offset = _weak_v.size * 0.5
	var tw := _weak_v.create_tween()
	_weak_v.scale = Vector2(1.35, 1.35)
	tw.tween_property(_weak_v, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_card() -> Dictionary:
	# P5/JSR: niente pannello. Volto in cornice storta + numero PV grande + EN piccola + barretta sottile; chi e' di turno ha una lastra di colore piena
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(300, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(48, 42)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(face)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(vb)
	var name_l := Ui.label("", 16, Ui.CREAM, Ui.display(), 5)
	name_l.clip_text = true
	vb.add_child(name_l)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(line)
	var hp_t := Ui.label("", 24, Ui.CREAM, Ui.display(), 7)      # squadra piu' compatta (Metaphor): la scena resta libera
	line.add_child(hp_t)
	var en := Ui.label("", 18, Ui.CYAN, Ui.display(), 5)
	en.size_flags_vertical = Control.SIZE_SHRINK_END
	line.add_child(en)
	var hp := _bar(Color("#62f08c"), 6)
	vb.add_child(hp)
	var ghost := _ghost_bar(hp)
	var ult := _bar(Ui.PINK, 5)
	vb.add_child(ult)
	var cracks := Control.new()
	cracks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cracks.set_meta("tier", 0)
	cracks.draw.connect(func() -> void: _draw_cracks(cracks))
	p.add_child(cracks)
	return {"panel": p, "face": face, "name": name_l, "hp": hp, "ghost": ghost, "hp_t": hp_t, "en": en, "ult": ult, "cracks": cracks, "tier": 0}


func _draw_party_back() -> void:
	# lastre e cornici dei volti di TUTTA la squadra in una sola maglia: una draw call (prima una per card)
	var m := CmdWheel._Mesh.new()
	var o: Vector2 = _party_back.get_global_rect().position
	for c in _cards:
		var pn: Control = c["panel"]
		var r: Rect2 = pn.get_global_rect()
		r.position -= o
		var col: Color = c.get("col", Color.WHITE)
		var on: bool = bool(c.get("active", false))
		var mk: bool = bool(c.get("marked", false))
		var al: float = float(c.get("alpha", 1.0))
		var x: float = r.position.x
		var y: float = r.position.y
		# contenitore scuro dietro la card (nero a opacita' leggera): la squadra spicca sul combattimento, stessa maglia
		m.draw_colored_polygon(PackedVector2Array([Vector2(x - 16, y - 4), Vector2(x + r.size.x + 10, y - 10), Vector2(x + r.size.x + 4, y + r.size.y + 8), Vector2(x - 20, y + r.size.y + 6)]), Color(0.0, 0.0, 0.02, 0.46 * al))
		var fr := PackedVector2Array([Vector2(x - 4, y + 4), Vector2(x + 72, y - 2), Vector2(x + 66, y + r.size.y + 2), Vector2(x - 8, y + r.size.y - 2)])
		if on:
			var slab := PackedVector2Array([Vector2(x - 10, y + 6), Vector2(x + r.size.x + 6, y - 4), Vector2(x + r.size.x - 8, y + r.size.y + 4), Vector2(x - 14, y + r.size.y - 2)])
			var sh := PackedVector2Array()
			for q in slab:
				sh.append(q + Vector2(6, 6))
			m.draw_colored_polygon(sh, Color(Ui.INK, al))
			m.draw_colored_polygon(slab, Color(col.darkened(0.15), al))
		var cen: Vector2 = (fr[0] + fr[1] + fr[2] + fr[3]) * 0.25
		var fo := PackedVector2Array()       # contorno nero spesso = la cornice ingrandita di 3 px, con ombra sfalsata
		var fs := PackedVector2Array()
		for q in fr:
			var big: Vector2 = q + (q - cen).normalized() * 4.0
			fo.append(big)
			fs.append(big + Vector2(5, 5))
		m.draw_colored_polygon(fs, Color(Ui.INK, al))
		m.draw_colored_polygon(fo, Color(Ui.INK, al))
		m.draw_colored_polygon(fr, Color(Color("#ff5a6e") if mk else (Color.WHITE if on else Ui.CREAM), al))
		if not on:
			m.draw_line(Vector2(x - 6, y + r.size.y + 6), Vector2(x + 66, y + r.size.y + 4), Color(col, al), 5.0)
	_party_mesh = m.commit(_party_back)


const CRACKS_1: Array = [[Vector2(0.78, 0.0), Vector2(0.72, 0.18), Vector2(0.80, 0.34), Vector2(0.74, 0.5)],
	[Vector2(0.72, 0.18), Vector2(0.6, 0.26)]]
const CRACKS_2: Array = [[Vector2(0.2, 1.0), Vector2(0.28, 0.82), Vector2(0.22, 0.66), Vector2(0.32, 0.5)],
	[Vector2(0.28, 0.82), Vector2(0.42, 0.78)], [Vector2(1.0, 0.7), Vector2(0.86, 0.62), Vector2(0.9, 0.46)],
	[Vector2(0.5, 0.0), Vector2(0.46, 0.14)]]


const CRACKS_KO: Array = [[Vector2(0.0, 0.3), Vector2(0.14, 0.4), Vector2(0.1, 0.55)], [Vector2(0.62, 1.0), Vector2(0.58, 0.8), Vector2(0.7, 0.66)]]


func _draw_cracks(c: Control) -> void:
	# VETRO ROTTO sulla card: crepe nette con bordo luminoso del colore del personaggio, schegge chiare, leggero spostamento RGB;
	# a KO anche righe di scansione e velo scuro. Tutto in questa card, niente a schermo intero.
	var tr: int = int(c.get_meta("tier", 0))
	if tr <= 0:
		return
	var ko: bool = bool(c.get_meta("ko", false))
	var cc: Color = c.get_meta("col", Color.WHITE)
	var sz: Vector2 = c.size
	var lines: Array = CRACKS_1 if tr == 1 else CRACKS_1 + CRACKS_2
	if ko:
		lines = lines + CRACKS_KO
		c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.03, 0.3))
		var yy: float = 2.0
		while yy < sz.y:
			c.draw_line(Vector2(0, yy), Vector2(sz.x, yy), Color(1, 1, 1, 0.06), 1.0)
			yy += 5.0
	var sh: float = 2.5 if tr >= 2 else 1.2
	for ln in lines:
		var pts := PackedVector2Array()
		var pr := PackedVector2Array()
		var pb := PackedVector2Array()
		for q in ln:
			var v: Vector2 = (q as Vector2) * sz
			pts.append(v)
			pr.append(v + Vector2(-sh, 0))
			pb.append(v + Vector2(sh, 0))
		if tr >= 2:
			c.draw_polyline(pts, Color(cc.r, cc.g, cc.b, 0.28), 7.0)       # alone
			c.draw_polyline(pr, Color(1.0, 0.2, 0.35, 0.55), 2.0)         # RGB: rosso a sinistra, ciano a destra
			c.draw_polyline(pb, Color(0.2, 0.9, 1.0, 0.55), 2.0)
		else:
			c.draw_polyline(pts, Color(cc.r, cc.g, cc.b, 0.22), 5.0)
		c.draw_polyline(pts, Color(1, 1, 1, 0.92 if tr >= 2 else 0.6), 2.0 if tr >= 2 else 1.5)
	if tr >= 2:
		# schegge: piccoli triangoli chiari sui nodi delle crepe, un po' staccati dal vetro
		for ln in lines:
			var q0: Vector2 = (ln[1] as Vector2) * sz
			c.draw_colored_polygon(PackedVector2Array([q0 + Vector2(3, -4), q0 + Vector2(15, 2), q0 + Vector2(5, 9)]), Color(1, 1, 1, 0.3))
			c.draw_polyline(PackedVector2Array([q0 + Vector2(3, -4), q0 + Vector2(15, 2), q0 + Vector2(5, 9), q0 + Vector2(3, -4)]), Color(cc.r, cc.g, cc.b, 0.8), 1.2)


# Barra PV della card: verde sopra il 50%, gialla sotto, rossa sotto il 25%; le crepe seguono lo stesso livello
func _card_tier(c: Dictionary, ratio: float, ko: bool = false, col: Color = Color.WHITE) -> void:
	var tr: int = BrokenCam.tier(ratio)
	var kk: bool = ko and tr > 0
	var key: String = "%d|%s|%s" % [tr, kk, col.to_html()]
	if key == str(c.get("tier_key", "")):
		return
	c["tier_key"] = key
	var rose: bool = tr > int(c["tier"])
	c["tier"] = tr
	(c["cracks"] as Control).set_meta("ko", kk)
	(c["cracks"] as Control).set_meta("col", col)
	if rose and tr > 0:
		var cr: Control = c["cracks"]
		cr.modulate = Color(2.2, 2.2, 2.2, 1.0)       # lampo del vetro che si rompe
		create_tween().tween_property(cr, "modulate", Color.WHITE, 0.35)
	var fill: StyleBoxFlat = (c["hp"] as ProgressBar).get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = [Color("#62f08c"), Color("#ffd23f"), Color("#ff4a5a")][tr]
	(c["cracks"] as Control).set_meta("tier", tr)
	(c["cracks"] as Control).queue_redraw()


var _confirming: bool = false


# Entrata dei pannelli a inizio battaglia (Persona 5: l'interfaccia non compare, entra): ordine dei turni, nemico e squadra
# arrivano con dissolvenza e un piccolo scatto, uno dopo l'altro. Solo opacita' e scala (i contenitori non si spostano), 0.3 s ciascuno.
func _intro_panels(ob: Control, bp: Control, party: Control) -> void:
	var items: Array = [[bp, Vector2(300, 0)], [ob, Vector2(0, 0)], [party, Vector2(0, 134)]]
	var tw := create_tween().set_parallel(true)
	for i in items.size():
		var c: Control = items[i][0]
		c.pivot_offset = items[i][1]
		c.modulate.a = 0.0
		c.scale = Vector2(0.92, 0.92)
		tw.tween_property(c, "modulate:a", 1.0, 0.22).set_delay(0.08 * i)
		tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_delay(0.08 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# TOCCA A TE: appena un eroe diventa di turno la sua card salta (scatto in scala), "TURNO DI ..." entra grande nel suo colore,
# la colonna dei comandi si apre e il mirino si aggancia al nemico. Una volta sola per turno, tween brevi (Persona 5: ogni cambio ha uno scatto).
func _announce_turn() -> void:
	var key: String = "%s|%d|%d" % [cur_pid, turn_i, int(b.get("round", 1))]
	if key == _pop_key or cur_pid == "" or ended:
		return
	_pop_key = key
	var col: Color = _col(_unit_of(cur_pid))
	if _pop_tw != null and _pop_tw.is_valid():
		_pop_tw.kill()
	_pop_tw = create_tween()
	_pop_tw.set_parallel(true)
	for i in _cards.size():
		if str(slots[i]) == cur_pid:
			var pn: Control = _cards[i]["panel"]
			pn.pivot_offset = pn.size * 0.5
			pn.scale = Vector2(0.94, 0.94)
			_pop_tw.tween_property(pn, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			(_cards[i]["panel"] as Control).scale = Vector2.ONE
	_turn_lbl.pivot_offset = Vector2(_turn_lbl.size.x, _turn_lbl.size.y * 0.5)
	_turn_lbl.scale = Vector2(1.35, 1.35)
	_turn_lbl.add_theme_color_override("font_color", col.lightened(0.35))
	_pop_tw.tween_property(_turn_lbl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_cmd_box.pivot_offset = _cmd_box.size
	_cmd_box.scale = Vector2(0.9, 0.9)
	_cmd_box.modulate.a = 0.0
	_pop_tw.tween_property(_cmd_box, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tw.tween_property(_cmd_box, "modulate:a", 1.0, 0.1)
	_reticle.lock_on(col.lightened(0.15), 84.0 if Ui.is_touch() else 70.0)
	Settings.buzz(12)


# Il bottone scelto scatta (si ingrandisce e si schiarisce) prima che la colonna si chiuda: conferma entro 100 ms
func _confirm_button(kind: String) -> void:
	var btn: Button = {"attack": _btn_atk, "skill": _btn_skill, "ult": _btn_ult, "guard": _btn_guard}.get(kind, _btn_atk)
	btn.pivot_offset = btn.size * 0.5
	btn.modulate = Color(1.35, 1.35, 1.35)
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		btn.scale = Vector2.ONE
		btn.modulate = Color.WHITE)


func _show_commands(on: bool) -> void:
	if _cmd_box == null:
		return
	_hud_focus(on)
	_cmd_box.visible = on
	if _kit_lbl != null:
		_kit_lbl.visible = false     # cosa fa ogni comando ora sta nel riquadro della scelta, sulla ruota
	if _wheel != null:
		_wheel.visible = on
	if on:
		_clear_stamps()
	if _turn_lbl != null:
		_turn_lbl.visible = false          # chi e' di turno lo dicono la luce, la ruota e la lastra della squadra (Persona 5: niente scritte in piu')
	if not on:
		_close_skills()
		_pick("")
		_cam_choose_end()
		if _reticle != null and not _confirming:
			_reticle.visible = false
		_pop_key = ""
		return
	_announce_turn()
	var u: Dictionary = _unit_of(cur_pid)
	var sk: String = _skill_of(u)
	var skm: Dictionary = BattleContent.MOVES.get(sk, {})
	_btn_atk.disabled = not _usable("attack")
	_btn_guard.disabled = not _usable("guard")
	_btn_skill.text = "%s  ·  %d ENERGIA" % [str(skm.get("name", "ABILITÀ")).to_upper(), BattleContent.move_cost(u, sk)]
	_fit_btn(_btn_skill, 24)
	_btn_skill.disabled = not _usable(sk)
	var ult_ok: bool = _usable(str(u.get("ult", "")))
	_btn_ult.disabled = not ult_ok
	_update_react()
	var um: Dictionary = BattleContent.MOVES.get(str(u.get("ult", "")), {})
	_btn_ult.text = ("ULTIMATE · " + str(um.get("name", "")).to_upper()) if ult_ok else "ULTIMATE  %d%%" % int(u.get("gauge", 0))
	_fit_btn(_btn_ult, 26)
	# cosa fa l'abilita' e il tratto di chi e' di turno (si gioca capendo, non a memoria)
	var tr: Dictionary = Kits.TRAITS.get(str(u.get("char", "")), {})
	var lines: Array = []
	if skm.has("desc"):
		lines.append("%s: %s" % [str(skm.get("name", "")), str(skm["desc"])])
	if ult_ok and um.has("desc"):
		lines.append("%s: %s" % [str(um.get("name", "")), str(um["desc"])])
	if not tr.is_empty():
		lines.append("%s: %s" % [str(tr["name"]), str(tr["desc"])])
	# vantaggio o svantaggio di colore contro il boss (solo se il giocatore sa gia' di che colore e')
	if _boss_known or not weak.is_empty():
		var hl: String = ColorHint.line(str(u.get("color", "")), str(BattleState.boss(b).get("color", "")), _bname())
		if hl == "":
			hl = ColorHint.second_line(str(u.get("color", "")), BattleState.boss(b))
		if hl != "":
			lines.insert(0, hl)
	_kit_lbl.text = "\n".join(lines)
	_fill_wheel(u, sk, skm, um, ult_ok, lines)


# Dati della ruota: nome, sottotitolo, costo e descrizione di ogni comando, nel colore di chi e' di turno
func _fill_wheel(u: Dictionary, sk: String, skm: Dictionary, um: Dictionary, ult_ok: bool, kit_lines: Array) -> void:
	if _wheel == null:
		return
	var sk_name: String = str(skm.get("name", "Abilità")).to_upper()
	var letter: String = sk_name.substr(0, 1)
	if letter in ["A", "U", "G", ""]:
		letter = "S"
	var tip: String = ""
	if not kit_lines.is_empty() and (_boss_known or not weak.is_empty()):
		tip = "\n" + str(kit_lines[0])
	var en: int = int(u.get("energy", 0))
	var items: Array = [
		# sotto ogni comando UNA parola breve che dice cosa fa (Persona 5: "Use a Skill"); i nomi delle mosse stanno nel menu ABILITA'
		{"kind": "attack", "name": "ATTACCO", "sub": "COLPISCI", "cost": "", "ok": _usable("attack"), "letter": "A",
			"title": "ATTACCO", "desc": "Colpo al nemico · non costa energia" + tip},
		{"kind": "skill", "name": "ABILITÀ", "sub": "MOSSE", "cost": "",   # niente EN: non si sa ancora quale mossa (decisione dell autore, 24/10/2026)
			 "ok": true, "letter": letter,
			"title": "ABILITÀ", "desc": "Apre le mosse speciali: ognuna costa energia" + tip},
		{"kind": "ult", "name": "ULTIMATE", "sub": "SCATENA", "cost": "PRONTA" if ult_ok else "%d%%" % int(u.get("gauge", 0)),
			"ok": ult_ok, "charge": float(u.get("gauge", 0)) / float(BattleTypes.GAUGE_MAX), "letter": "U", "title": "ULTIMATE · " + str(um.get("name", "")).to_upper(), "desc": str(um.get("desc", "")) + tip},
		{"kind": "guard", "name": "GUARDIA", "sub": "DIFENDITI", "cost": "+1 EN", "ok": _usable("guard"), "letter": "G",
			"title": "GUARDIA", "desc": "Dimezza il danno e ricarica energia"},
	]
	# RITMO per categoria: i comandi che cambiano tipo di mossa lo dicono sulla ruota (+10% al colpo)
	var lc: String = str(u.get("last_cat", ""))
	if lc != "":
		for it in items:
			var cat: String = {"attack": "attacco", "skill": "abilita", "ult": "ultimate"}.get(str(it["kind"]), "")
			if cat != "" and cat != lc:
				if str(it["cost"]) == "":
					it["cost"] = "RITMO"          # corto: sotto ABILITA' "RITMO +10%" toccava l'icona; il +10% e' nella descrizione
				it["desc"] = str(it["desc"]) + "\nRITMO: dopo %s cambi tipo di mossa, +%d%% al colpo" % [BattleContent.category_name(lc), int(round((BattleTypes.RHYTHM_BONUS - 1.0) * 100.0))]
	# SLANCIO: nell'azione rapida la Guardia protegge tutta la squadra (la scelta non e' solo "un altro colpo")
	if _quick:
		for it in items:
			if str(it["kind"]) == "guard":
				it["sub"] = "PROTEGGI TUTTI"
				it["cost"] = "+%d EN" % (1 + BattleTypes.SLANCIO_GUARD_EN)
				it["desc"] = "GUARDIA DI SLANCIO: dimezza il danno, +%d EN e uno scudo a tutta la squadra" % (1 + BattleTypes.SLANCIO_GUARD_EN)
	_wheel.setup(str(u.get("name", "")).to_upper() + (" · RAPIDO" if _quick else ""), _col(u), items)


# Scegliere un comando non lo lancia: si accende (pennellata in luce, scena scura attorno al personaggio) e mostra cosa fa.
# Toccarlo di nuovo o CONFERMA lo lancia. "" = nessuna scelta.
func _pick(kind: String) -> void:
	if kind != "" and (not waiting or ended or _pause != null):
		return
	if kind != "" and _wheel != null:
		var it: Dictionary = _wheel.item(kind)
		if not bool(it.get("ok", false)):
			Settings.buzz(10)
			return
	var was: String = _picked
	_picked = kind
	if _hint != null:
		_hint.modulate.a = 0.0 if kind != "" else 1.0      # sotto la scelta si legge solo il suo riquadro
	if _wheel != null:
		_wheel.pick(kind)
	if kind != "" and kind != was:
		Settings.buzz(30 if kind == "ult" else 12)
	# ULTIMATE: la telecamera stringe sul personaggio, che resta in luce
	if cur_pid != "" and waiting:
		var uid: String = str(_unit_of(cur_pid).get("id", ""))
		if kind == "ult" and was != "ult":
			_cam_choose(uid, true)
		elif kind != "ult" and was == "ult":
			_cam_choose(uid)


# Un tocco sul comando lo LANCIA (Persona 5; niente CONFERMA, decisione dell'autore 24/10/2026). ABILITA' apre il suo menu.
func _wheel_tap(kind: String) -> void:
	if not waiting or ended or _pause != null or _skill_menu != null:
		return
	match kind:
		"skill":
			_open_skills()
		"attack", "guard", "ult":
			if _wheel != null and not bool(_wheel.item(kind).get("ok", false)):
				Settings.buzz(10)
				return
			_command(kind)


# PC: il mouse sopra un comando lo accende e mostra cosa fa (senza muovere la telecamera)
func _wheel_hover(kind: String) -> void:
	if not waiting or ended or _skill_menu != null:
		return
	if kind != "" and _wheel != null and not bool(_wheel.item(kind).get("ok", false)):
		kind = ""                 # un comando spento non si accende (l'ULTIMATE non carica non fa partire le bande nere)
	_picked = kind
	if _hint != null:
		_hint.modulate.a = 0.0 if kind != "" else 1.0
	if _wheel != null:
		_wheel.pick(kind)


func _open_skills() -> void:
	var u: Dictionary = _unit_of(cur_pid)
	var en: int = int(u.get("energy", 0))
	var items: Array = []
	var start: int = 0
	var cur: String = _skill_of(u)
	for id in _skill_ids(u):
		var mv: Dictionary = BattleContent.MOVES[id]
		var ok: bool = _usable(id)
		var why: String = ""
		if not ok:
			why = "Energia insufficiente" if BattleContent.move_cost(u, id) > en else ("Non in un turno RAPIDO" if _quick else "Non si può usare adesso")
		if id == cur:
			start = items.size()
		var sig: bool = BattleContent.is_signature(u, id)
		items.append({"id": id, "name": str(mv.get("name", id)).to_upper(), "cost": "%d EN" % BattleContent.move_cost(u, id), "sig": sig,
			"desc": (BattleContent.signature_text(id) + " · " if sig else "") + BattleContent.move_desc(id), "ok": ok, "why": why, "icon": SkillMenu.icon_for(mv)})
	# TECNICHE COMBINATE (DuoTechs): in fondo alla lista, con chi la fa insieme e perche' non si puo' adesso
	if not _quick:
		for did in DuoTechs.of_char(str(u.get("char", ""))):
			var dmv: Dictionary = BattleContent.MOVES[did]
			var dwhy: String = DuoTechs.error(b, u, str(did))
			var mate: String = DuoTechs._who(DuoTechs.partner_char(str(did), str(u.get("char", "")))).to_upper()
			items.append({"id": did, "name": "%s + %s" % [str(dmv["name"]).to_upper(), mate], "cost": "%d+%d EN" % [DuoTechs.COST, DuoTechs.COST], "sig": false,
				"desc": "TECNICA COMBINATA con %s, che salta il suo turno · %s" % [mate, str(DuoTechs.DUOS[did]["desc"])], "ok": dwhy == "", "why": dwhy,
				"icon": str(DuoTechs.DUOS[did]["icon"])})
	_wheel_hover("")
	_wheel.visible = false
	if _hint != null:
		_hint.visible = false     # nel menu si legge solo il menu
	_skill_menu = SkillMenu.new()
	_skill_menu.open(items, str(u.get("name", "")).to_upper(), _col(u), start)
	_skill_menu.chosen.connect(func(id: String) -> void:
		if id.begins_with("duo_"):
			_duo_pick = id          # una volta sola: non diventa l'abilita' scelta del personaggio
			_close_skills()
			_command("skill")
			return
		_skill_pick[str(u.get("id", ""))] = id
		_close_skills()
		_command("skill"))
	_skill_menu.closed.connect(_close_skills)
	_fx_layer.add_child(_skill_menu)
	Settings.buzz(12)


func _close_skills() -> void:
	if _skill_menu != null:
		_skill_menu.queue_free()
		_skill_menu = null
	if _wheel != null and waiting and not ended:
		_wheel.visible = true
		if _hint != null:
			_hint.visible = true


# Una catena della ruota dei colori: quadratini del colore e il segno tra l'uno e l'altro (">" batte, "<>" si battono a vicenda)
func _legend_row(row: HBoxContainer, colors: Array, sign: String) -> void:
	for i in colors.size():
		if i > 0:
			row.add_child(Ui.label(sign, 18, Color(1, 1, 1, 0.8)))
		var sq := ColorRect.new()
		sq.color = Ui.BATTLE_COLORS.get(str(colors[i]), Color.WHITE)
		sq.custom_minimum_size = Vector2(22, 22)
		sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(sq)


# REAZIONE: una finestra c'e' solo se il boss carica un colpo pesante non ancora fermato (o c'e' un caduto da soccorrere) e la
# Riserva basta. Mostra solo le reazioni che si possono fare adesso, ognuna col suo costo in Riserva. Reagire costa il turno.
func _update_react() -> void:
	if _react_box == null:
		return
	var usable: Array = []
	for r in ([] if _quick else BattleResolver.reactions_for(b, cur_pid)):
		if str(r["err"]) == "":
			usable.append(str(r["id"]))
	var lives: Array = [] if _quick else SeqRound.live_ults(b, cur_pid)
	_react_box.visible = not usable.is_empty() or not lives.is_empty()
	for k in _live_btns.size():
		var lb: Button = _live_btns[k]
		lb.visible = k < lives.size()
		if lb.visible:
			lb.text = "ULT\n%s" % str(_unit_of(str(lives[k])).get("name", "")).to_upper()
			lb.set_meta("pid", str(lives[k]))
			lb.add_theme_font_size_override("font_size", 15)
			lb.custom_minimum_size.y = 56.0 if Ui.is_touch() else 48.0
	for rid in _react_btns:
		var rb: Button = _react_btns[rid]
		rb.visible = usable.has(rid)
		if rb.visible:
			rb.text = "%s · %d" % [str(REACT_SHORT[rid]), BattleResolver.reaction_cost(b, str(rid))]      # il numero e' la Riserva che costa
			rb.add_theme_font_size_override("font_size", 15)
			rb.custom_minimum_size.y = 56.0 if Ui.is_touch() else 48.0
	# la colonna e' piu' alta con la riga delle Ultimate in diretta: titolo e descrizioni salgono per non essere coperti
	var up: float = 40.0 if not lives.is_empty() else 0.0
	Ui.place(_turn_lbl, 1.0, 1.0, 1.0, 1.0, -600, -385 - up, -16, -340 - up)
	Ui.place(_kit_lbl, 1.0, 1.0, 1.0, 1.0, -620, -392 - up, -16, -392 - up)
	if _react_box.visible:
		_react_lbl.text = ("REAZIONE\nRISERVA %d · USA IL TURNO" % int(b.get("reserve", 0))) if not usable.is_empty() else "ULTIMATE IN DIRETTA\nSENZA RISERVA"
		if not _react_hint_seen and not first_turn and _hint != null and not usable.is_empty():
			_react_hint_seen = true
			_hint.text = "CARICA IN ARRIVO · REAZIONI con la Riserva: SCHIVA (freccia) · COPRI (tieni e lascia) · FERMA (a raffica) · SOCCORRI (battito)"


# ULTIMATE IN DIRETTA: un compagno con la barra piena lancia l'Ultimate fuori turno durante una carica. Non costa Riserva ne' il
# turno di chi sta scegliendo: finita l'Ultimate si torna alla sua scelta.
func _live_ult(k: int) -> void:
	if not waiting or ended or _pause != null or k >= _live_btns.size():
		return
	var lb: Button = _live_btns[k]
	if not lb.visible or not lb.has_meta("pid"):
		return
	var pid: String = str(lb.get_meta("pid"))
	_live_back = cur_pid
	if not SeqRound.live_ults(b, cur_pid).has(pid):
		Settings.buzz(10)
		return
	waiting = false
	_show_commands(false)
	_hint.text = ""
	Settings.buzz(40)
	var u: Dictionary = _unit_of(pid)
	await _do_action(pid, {"swap": "", "move": str(u["ult"]), "target": "", "order": "", "push": ""})
	if not is_inside_tree() or ended:
		return
	# l'Ultimate fuori turno puo' chiudere lo scontro: prima qui si tornava alla scelta di chi era di turno e il gioco
	# restava fermo (nessun comando valido a battaglia finita, niente schermata di vittoria)
	if str(b["winner"]) != "":
		await _end_battle()
		return
	cur_pid = _live_back
	_refresh_hud()
	_cam_actor(str(_unit_of(cur_pid)["id"]))
	waiting = true
	_show_commands(true)


func _react_cmd(rid: String) -> void:
	if not waiting or ended or _pause != null or not _usable(rid):
		Settings.buzz(10)
		return
	waiting = false
	_show_commands(false)
	_hint.text = ""
	Settings.buzz(30)
	# FERMA e SOCCORRI si giocano subito (a raffica / col battito); SCHIVA e COPRI quando il nemico colpisce
	var game: String = {"interruzione": "mash", "soccorso": "beat"}.get(rid, "")
	if game != "" and not auto_on:
		var ru: Dictionary = _unit_of(cur_pid)
		var grade: String = await _react_game(game, ru)
		if not is_inside_tree() or ended:
			return
		(b["react_grade"] as Dictionary)[str(ru["id"])] = grade
	elif rid in ["schivata", "intercettazione"]:
		_toast("%s si gioca quando %s colpisce" % [str(REACT_SHORT[rid]), _bn()], Ui.CYAN, 1.6)
	await _do_action(cur_pid, _choice_for(rid))
	if is_inside_tree() and not ended:
		await _advance()


# Rimpicciolisce il testo del pulsante finche' entra nella colonna dei comandi: la colonna resta larga 314 px
# e non copre le card della squadra (prima un nome lungo la allargava sopra la card di Saul)
func _fit_btn(btn: Button, base: int) -> void:
	var f: Font = btn.get_theme_font("font")
	var size: int = base
	while size > 16 and f.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 280.0:
		size -= 1
	btn.add_theme_font_size_override("font_size", size)


func _refresh_hud() -> void:
	if _boss_hp == null:
		return
	_update_broken_cam()
	if _cam_hud != null:
		_cam_hud.set_live(int(Kits.unit_of_char(b, Kits.RIO).get("hype", -1)))      # la diretta di Rio e' la telecamera di Echo
	var boss: Dictionary = BattleState.boss(b)
	_boss_hp.max_value = int(boss["max_hp"])
	var shown_hp: int = mini(int(boss["max_hp"]), int(boss["hp"]) + _team_hold)
	_boss_hp.value = shown_hp
	_boss_hp_txt.text = "%d / %d" % [shown_hp, int(boss["max_hp"])]
	_boss_brk.max_value = maxi(1, int(boss.get("balance_max", 1)))
	_boss_brk.value = int(boss.get("balance", 0))
	_brk_lbl.text = "EQUILIBRIO  %d" % int(boss.get("balance", 0))
	_brk_pulse(float(_boss_brk.value) / float(_boss_brk.max_value) <= 0.34 and int(boss.get("balance", 0)) > 0 and not ended)
	var tele: Dictionary = b.get("telegraph", {})
	var mv: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	var who: String = "TUTTI"
	if bool(mv.get("camera", false)):
		# la telecamera non segue il bersaglio annunciato: colpisce in base ai PV del momento
		var names: Array = []
		for pk in BattleResolver.camera_targets(b):
			names.append(str((pk["unit"] as Dictionary).get("name", "?")).to_upper())
		who = " e ".join(PackedStringArray(names)) if not names.is_empty() else "NESSUNO"
	elif str(mv.get("target", "one")) != "all":
		var tu: Dictionary = BattleState.active_unit(b, str(tele.get("target", "")))
		who = str(tu.get("name", "?")).to_upper()
	var tstate: String = "normale"
	if ended or not BattleState.is_alive(boss):
		_tele.text = ""
	elif int(boss.get("stun", 0)) > 0:
		_tele.text = "STORDITO: salterà il prossimo turno"
		tstate = "stordito"
	else:
		var thr: Dictionary = BattleResolver.threat_preview(b)
		var strong: bool = CombatHud.is_strong(float(mv.get("mult", 0.0)), thr.get("lethal", []))
		_tele.text = CombatHud.tele_line(str(mv.get("name", "?")), who, str(mv.get("target", "one")) == "all", strong, str(thr.get("chain", "")) != "") if not mv.is_empty() else ""
		tstate = "forte" if strong else "normale"
	_tele.visible = _tele.text != ""
	_tele_dress(tstate)
	_weak_refresh(boss)
	_ghost_to(_boss_ghost, float(shown_hp), float(boss["max_hp"]))
	_static_set(BattleState.BOSS_ID, not ended and BattleState.is_alive(boss) and int(boss.get("stun", 0)) > 0, Color(1.0, 0.85, 0.45))
	var marked: String = _update_mark(tele, mv, boss)
	for i in _cards.size():
		var c: Dictionary = _cards[i]
		var u: Dictionary = _slot_unit(i)
		var active: bool = str(slots[i]) == cur_pid
		var is_marked: bool = marked != "" and str(u.get("id", "")) == marked
		var alive: bool = BattleState.is_alive(u)
		var col: Color = _col(u)
		var look: String = "%s|%s|%s" % [active, is_marked, col.to_html()]
		if str(c.get("look", "")) != look:
			c["look"] = look          # PRESTAZIONI: la lastra si rifa' solo quando cambia
			c["col"] = col
			c["active"] = active
			c["marked"] = is_marked
			_party_back.queue_redraw()
		(c["panel"] as Control).modulate.a = 1.0 if alive else 0.45
		if float(c.get("alpha", 1.0)) != (1.0 if alive else 0.45):
			c["alpha"] = 1.0 if alive else 0.45
			_party_back.queue_redraw()
		# il colore anche scritto: chi non distingue i colori sa lo stesso chi colpisce le debolezze
		# ▶ davanti al nome di chi e' di turno: si legge anche senza distinguere i colori
		(c["name"] as Label).text = ("▶ " if active and alive else "") + str(u["name"]).to_upper() + (" · " + str(u.get("color", "")).to_upper() if str(u.get("color", "")) != "" else "") + ("  KO" if not alive else "") \
				+ (" ▲" if alive and _beats_boss(str(u.get("color", "")), boss) else "")      # ▲ = colpisce la debolezza, lo stesso segno di "▲ EFFICACE!"
		(c["name"] as Label).add_theme_color_override("font_color", Color.WHITE if active else col.lightened(0.3))
		(c["hp"] as ProgressBar).max_value = int(u["max_hp"])
		(c["hp"] as ProgressBar).value = int(u["hp"])
		_ghost_to(c["ghost"], float(u["hp"]), float(u["max_hp"]))
		_static_set(str(u.get("id", "")), not ended and not alive, col.lightened(0.35))
		_card_tier(c, float(u["hp"]) / maxf(1.0, float(u["max_hp"])), not alive, col)
		(c["hp_t"] as Label).text = "%d" % int(u["hp"])
		var face: TextureRect = c["face"]
		if face.texture == null:
			var fp: String = "res://assets/portraits/%s_neutro.png" % str(u.get("char", ""))
			if ResourceLoader.exists(fp):
				face.texture = load(fp)
		face.modulate = Color.WHITE if alive else Color(0.4, 0.4, 0.45)
		var en: int = int(u.get("energy", 0))
		(c["en"] as Label).text = "EN %d" % en
		if Kits.is_char(u, Kits.RIO) and int(u.get("hype", 0)) > 0:      # HYPE a zero non dice niente: compare quando sale
			(c["en"] as Label).text += " · HYPE %d" % int(u.get("hype", 0))
		(c["ult"] as ProgressBar).max_value = BattleTypes.GAUGE_MAX
		(c["ult"] as ProgressBar).value = int(u.get("gauge", 0))
		# ULTIMATE pronta: la barretta diventa gialla (prima restava rosa uguale a quando era a meta')
		var full: bool = int(u.get("gauge", 0)) >= BattleTypes.GAUGE_MAX
		if bool(c.get("ult_full", false)) != full:
			c["ult_full"] = full
			var fs := StyleBoxFlat.new()
			fs.bg_color = Ui.YELLOW if full else Ui.PINK
			fs.set_corner_radius_all(2)
			(c["ult"] as ProgressBar).add_theme_stylebox_override("fill", fs)
	# ordine dei turni rimasti in questo round. PRESTAZIONI: le righe si riusano (prima si buttavano e ricreavano tutte
	# a ogni aggiornamento, piu' volte per azione) e si toccano solo se cambiano.
	var rows: Array = []
	var start: int = maxi(0, turn_i)
	for k in range(start, turn_list.size()):
		var e: Dictionary = turn_list[k]
		var uu: Dictionary = BattleState.unit(b, str(e["unit"]))
		if not BattleState.is_alive(uu):
			continue
		var is_boss: bool = bool(e["boss"])
		var nm: String = _bname() if is_boss else str(uu.get("name", "?")).to_upper()
		if nm.length() > 10:
			nm = nm.substr(0, 9) + "."      # una riga sola in alto: i nomi lunghi (DISTRIBUTORE) si accorciano
		rows.append([("▶ " if k == turn_i else "") + nm, 17 if k == turn_i else 14, Ui.YELLOW if is_boss else _col(uu).lightened(0.25), k == turn_i])
		if rows.size() >= 4:
			break
	if _order_title != null:
		_order_title.text = "TURNO %d" % int(b.get("round", 1))
	var sig: String = str(rows)
	if sig != _order_sig:
		_order_sig = sig
		while _order_box.get_child_count() < rows.size():
			_order_box.add_child(Ui.label("", 15, Ui.CREAM, null, 5))
		for i in _order_box.get_child_count():
			var l: Label = _order_box.get_child(i)
			l.visible = i < rows.size()
			if not l.visible:
				continue
			var r: Array = rows[i]
			l.text = str(r[0])
			l.add_theme_font_size_override("font_size", int(r[1]))
			# ogni turno e' una lastra storta (Persona 5 / Star Rail): chi agisce ora e' piena del suo colore con la scritta scura,
			# gli altri scuri col bordo del loro colore. Prima erano righe di testo piccole, chi era di turno si capiva dal ">"
			var now: bool = bool(r[3])
			l.add_theme_stylebox_override("normal", _order_chip(r[2], now))
			l.add_theme_color_override("font_color", Ui.INK if now else r[2])
			l.add_theme_constant_override("outline_size", 0 if now else 5)
			l.add_theme_font_override("font", Ui.display())
	_turn_lbl.text = ("TURNO DI " + str(_unit_of(cur_pid).get("name", "")).to_upper() + (" · RAPIDO" if _quick else "")) if cur_pid != "" and not ended else ""
	if waiting:
		_show_commands(true)


# Segnalino del bersaglio annunciato: acceso a inizio round, spento quando il boss agisce, per mosse su tutti, da stordito e a fine battaglia.
# Ritorna l'id dell'unita' segnata ("" = nessuna).
func _update_mark(tele: Dictionary, mv: Dictionary, boss: Dictionary) -> String:
	var want: String = ""
	if not ended and not _boss_acting and BattleState.is_alive(boss) and int(boss.get("stun", 0)) <= 0 \
			and not mv.is_empty() and not bool(mv.get("camera", false)) and str(mv.get("target", "one")) != "all" \
			and not bool((b.get("seq", {}) as Dictionary).get("boss_acted", false)):
		var tu: Dictionary = BattleState.active_unit(b, str(tele.get("target", "")))
		if not tu.is_empty() and BattleState.is_alive(tu) and home.has(str(tu["id"])):
			want = str(tu["id"])
	if want == "":
		_clear_mark()
	elif want != _mark_uid or _mark == null or not is_instance_valid(_mark):
		_clear_mark()
		_mark = LightFx.mark(self, home[want], Color("#ff5a6e"))
		_mark_uid = want
	_update_threat(tele, mv, boss, want)
	return want


# Minaccia a terra: cerchio sotto il nemico che dichiara, semicerchio sotto tutti o cono fino al bersaglio (la scritta da sola non bastava)
var _threat: LightFx = null
var _threat_key: String = ""


func _update_threat(tele: Dictionary, mv: Dictionary, boss: Dictionary, one: String) -> void:
	var tgts: Array = []
	var all: bool = false
	var show: bool = not ended and not _boss_acting and BattleState.is_alive(boss) and int(boss.get("stun", 0)) <= 0 and not mv.is_empty() \
			and not bool((b.get("seq", {}) as Dictionary).get("boss_acted", false))
	if show:
		if one != "":
			tgts.append(home[one])
		elif bool(mv.get("camera", false)):
			# la telecamera colpisce chi ha meno PV in quel momento: i suoi bersagli di ora
			for pk in BattleResolver.camera_targets(b):
				var cu: String = str((pk["unit"] as Dictionary).get("id", ""))
				if home.has(cu):
					tgts.append(home[cu])
			all = tgts.size() > 1
		else:
			all = true
			for p in BattleState.alive_players(b):
				var u: Dictionary = BattleState.active_unit(b, str(p["id"]))
				if BattleState.is_alive(u) and home.has(str(u["id"])):
					tgts.append(home[str(u["id"])])
	if tgts.is_empty():
		if _threat != null and is_instance_valid(_threat):
			_threat.stop()
		_threat = null
		_threat_key = ""
		return
	var key: String = "%s|%s" % [str(all), str(tgts)]
	if _threat == null or not is_instance_valid(_threat):
		_threat = LightFx.threat(self, ENEMY_POS, tgts, all, Color("#ff3b4e"))
	elif key != _threat_key:
		_threat.retarget(tgts, all)
	_threat_key = key


func _clear_mark() -> void:
	if _mark != null and is_instance_valid(_mark):
		_mark.stop()
	_mark = null
	_mark_uid = ""


# Nome della mossa e annunci brevi: ora vanno nella stessa pila degli avvisi (un posto solo, niente scritte sovrapposte)
func _banner(text: String, col: Color, _ay: float = 0.2, _size: int = 30) -> void:
	_notice(text, col, 1.3, "move")


var _toasts: Array = []
var _order_sig: String = ""


# Mostra gli eventi; se c'e' un ATTACCO DI SQUADRA (rottura del boss) prima mostra il colpo che rompe, poi la sequenza di squadra.
func _show_events_freeze(ev: Array) -> void:
	var idx: int = -1
	for i in ev.size():
		if str(ev[i].get("t", "")) == "team_strike":
			idx = i
			break
	if idx < 0:
		await _show_events(ev, true)
		return
	_team_follow = true             # la rottura la annuncia la sequenza di squadra: niente vetro rotto ne' scritte doppie
	# i danni di squadra si vedono sulla barra solo quando arrivano i colpi
	_team_hold = 0
	for e in ev.slice(idx + 1):
		if str(e.get("t", "")) == "damage" and str(e.get("dst", "")) == BattleState.BOSS_ID and str(e.get("src", "")) != BattleState.BOSS_ID:
			_team_hold += int(e.get("amount", 0))
	_refresh_hud()
	await _show_events(ev.slice(0, idx), true)
	_team_follow = false
	if not is_inside_tree() or ended:
		return
	if tutorial or lezioni:
		await _tut("tut_rottura")
	await _team_sequence(ev.slice(idx))


# ATTACCO DI SQUADRA (prima era un fermo immagine con tutti che colpivano nello stesso istante: non si capiva niente).
# Ora si legge in tre tempi, come una ripresa di Echo:
#  1. ROTTURA: timbro grande al centro, il nemico barcolla;
#  2. FERMO IMMAGINE: cornice REC e la striscia con i volti di chi sta per colpire;
#  3. i compagni colpiscono UNO ALLA VOLTA (scatto, colpo, numero col suo nome e colore) e alla fine il totale.
# Un tocco accelera tutto. Costa poco: niente velo a schermo intero, niente vetro rotto, niente rallentatore globale.
func _team_sequence(rest: Array) -> void:
	_team_on = true
	_freeze_skip = false
	var breaker: String = str(rest[0].get("unit", ""))
	var boss_v: Node3D = vis[BattleState.BOSS_ID]
	var hits: Array = []                     # [chi, danno, critico]
	var others: Array = []
	for e in rest.slice(1):
		if str(e.get("t", "")) == "damage" and str(e.get("dst", "")) == BattleState.BOSS_ID and str(e.get("src", "")) != BattleState.BOSS_ID:
			hits.append([str(e["src"]), int(e.get("amount", 0)), bool(e.get("crit", false))])
		else:
			others.append(e)
	# la barra del nemico torna ai PV di prima dell'assalto e scende a ogni colpo (prima calava tutta subito: sembrava che non facesse niente)
	_team_hold = 0
	for h in hits:
		_team_hold += int(h[1])
	_refresh_hud()
	(boss_v as VendingVisual).stunned = true
	_cam_set(Vector3(0.0, 2.6, 7.6), ENEMY_POS + Vector3(0, 1.0, 0), 5.0)
	# 1. ROTTURA
	# versione corta del BREAK (vetro + scritta, senza il fermo immagine lungo): la sequenza di squadra ha gia' il suo ritmo
	_break_moment(0.0, true)
	await _team_wait(0.95)
	# 2. FERMO IMMAGINE
	var box := _rec_frame()
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 10)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# i nomi stanno in basso, sopra le schede: in alto restano liberi i numeri dei colpi
	Ui.place(strip, 0.1, 0.66, 0.9, 0.66, 0, 0, 0, 60)
	box.add_child(strip)
	var hint_was: bool = _hint != null and _hint.visible
	if _hint != null:
		_hint.visible = false
	var tags: Dictionary = {}
	for h in hits:
		var u: Dictionary = b["units"].get(str(h[0]), {})
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", Ui.box(_col(u), Ui.INK, 4, 4, 4))
		tag.add_child(Ui.label(str(u.get("name", "?")).to_upper(), 26, Ui.INK, Ui.display()))
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.rotation_degrees = -4.0
		tag.modulate.a = 0.55
		strip.add_child(tag)
		tags[str(h[0])] = tag
	await _team_wait(0.6)
	# 3. un colpo alla volta
	var total: int = 0
	for h in hits:
		var uid: String = str(h[0])
		if not vis.has(uid) or not (vis[uid] is CharacterVisual):
			continue
		var cv: CharacterVisual = vis[uid]
		var col: Color = _col_of(uid)
		# il nome di chi colpisce si accende, quelli gia' passati restano accesi
		if tags.has(uid):
			var tg: Control = tags[uid]
			tg.modulate.a = 1.0
			tg.pivot_offset = tg.size * 0.5
			tg.scale = Vector2(1.25, 1.25)
			create_tween().tween_property(tg, "scale", Vector2.ONE, 0.2)
		var strike: Vector3 = ENEMY_POS + (home[uid] - ENEMY_POS).normalized() * 1.6
		strike.y = 0.14
		cv.move_speed = 1.0
		var tw := create_tween()
		tw.tween_property(cv, "position", strike, 0.14 if not _freeze_skip else 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await _tw_done(tw)
		cv.move_speed = 0.0
		cv.attack()
		boss_v.call("hit")
		LightFx.sparks(self, (boss_v as Node).call("chest_point"), col if not bool(h[2]) else LightFx.IVORY, 8)
		_kick(0.35)
		total += int(h[1])
		_team_hold = maxi(0, _team_hold - int(h[1]))
		_refresh_hud()
		_number(BattleState.BOSS_ID, "%s  %d%s" % [str(b["units"][uid].get("name", "")).to_upper(), int(h[1]), "!" if bool(h[2]) else ""], col.lightened(0.35), 56, 0.0)
		var back := create_tween()
		back.tween_interval(0.12)
		back.tween_property(cv, "position", home[uid], 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		back.tween_callback(func() -> void:
			if is_instance_valid(cv):
				cv.move_speed = 0.0
				_face(cv, ENEMY_POS))
		await _team_wait(0.32)
	_team_hold = 0
	_refresh_hud()
	box.queue_free()
	if _hint != null and hint_was:
		_hint.visible = true
	if total > 0:
		_stamp("ATTACCO DI SQUADRA", "%d danni in tutto" % total, Ui.YELLOW)
	if breaker != "" and vis.has(breaker):
		_face(vis[breaker], ENEMY_POS)
	# il totale resta a schermo da solo prima che tornino i comandi (prima la ruota ci finiva sopra)
	await _team_wait(1.1)
	await _show_events(others, true)
	await _team_wait(0.3)
	_team_on = false


# Attesa della sequenza di squadra: un tocco la accorcia
func _team_wait(sec: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while is_inside_tree() and not ended and not _freeze_skip and float(Time.get_ticks_msec() - t0) / 1000.0 < sec / maxf(0.1, Engine.time_scale):
		await get_tree().process_frame


# Cornice REC della telecamera di Echo con la scritta FERMO IMMAGINE (si toglie chi la crea)
func _rec_frame() -> Control:
	var box := Control.new()
	Ui.place(box, 0, 0, 1, 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(box)
	var rec: Color = Color("#ff4630")
	for side in 4:
		var bar := ColorRect.new()
		bar.color = rec
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match side:
			0: Ui.place(bar, 0, 0, 1, 0, 0, 0, 0, 8)
			1: Ui.place(bar, 0, 1, 1, 1, 0, -8, 0, 0)
			2: Ui.place(bar, 0, 0, 0, 1, 0, 0, 8, 0)
			3: Ui.place(bar, 1, 0, 1, 1, -8, 0, 0, 0)
		box.add_child(bar)
	var lbl := Ui.label("●  REC  ·  FERMO IMMAGINE · TUTTI ADDOSSO", 30, rec, Ui.display(), 8)
	Ui.place(lbl, 0.1, 0.22, 0.9, 0.22, 0, 0, 0, 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)
	return box


# Timbro grande al centro (parola + riga sotto) che entra di scatto e svanisce
# Fermo del colpo: il tempo quasi si ferma per un istante (i colpi giusti si sentono). Non tocca la pausa.
func _hit_stop(sec: float) -> void:
	if _pause != null or Engine.time_scale <= 0.0:
		return
	Engine.time_scale = 0.06
	await get_tree().create_timer(sec, true, false, true).timeout
	if _pause == null and absf(Engine.time_scale - 0.06) < 0.001:
		Engine.time_scale = 1.8 if fast else 1.0


# SLANCIO alla Persona 5 ("1 MORE"): la scena si ferma, timbro grande, chi agisce ancora e cosa puo' fare.
# Prima era un avviso di un secondo in mezzo agli altri: il giocatore non capiva cosa aveva fatto di giusto.
func _slancio_moment(u: Dictionary) -> void:
	# se c'e' ancora un timbro (es. DEBOLEZZA!) lo slancio aspetta il suo turno: camera e scritta arrivano insieme
	var lag: int = _stamp_free_ms - Time.get_ticks_msec()
	if lag > 0:
		await get_tree().create_timer(float(lag) / 1000.0, true, false, true).timeout
	var col: Color = _col(u)
	var uid: String = str(u.get("id", ""))
	if vis.has(uid):
		_cam_choose(uid)          # alle spalle di chi agisce ancora, col nemico davanti
	_flash(0.35)
	_kick(0.5)
	Settings.buzz(30)
	_stamp("SLANCIO!", "%s AGISCE ANCORA · COLPISCI O PROTEGGI TUTTI" % str(u["name"]).to_upper(), col.lightened(0.25), 0.58)
	await _wait(1.25)


# ay resta per chi la chiama, ma il posto e' sempre STAMP_AY: il giocatore guarda sempre li'.
func _stamp(title: String, sub: String, col: Color, ay: float = 0.3) -> void:
	ay = STAMP_AY
	await _stamp_turn(1.45)
	if not is_inside_tree() or _cmds_open():
		return          # e' gia' il turno di scegliere: il colpo e' passato, la scritta non copre la ruota
	var box := VBoxContainer.new()
	Ui.place(box, 0.15, ay, 0.85, ay, 0, 0, 0, 140)
	_stamps.append(box)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	var big := Ui.label(title, 72, col, Ui.display(), 12)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(big)
	var sm := Ui.label(sub, 26, Ui.CREAM, Ui.display(), 8)
	sm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sm)
	_fx_layer.add_child(box)
	box.pivot_offset = Vector2(box.size.x * 0.5, 70)
	box.scale = Vector2(1.6, 1.6)
	box.modulate.a = 0.0
	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(box, "modulate:a", 1.0, 0.1)
	tw.tween_interval(0.9)
	tw.tween_property(box, "modulate:a", 0.0, 0.25)
	tw.tween_callback(box.queue_free)


# Titolo grande "in diretta" (stile di Rio): pallino rosso REC che lampeggia + parola grande + una riga sotto. Non copre le descrizioni:
# sta nella fascia centrale alta, come i toast.
func _live_banner(title: String, sub: String, col: Color, sec: float) -> void:
	await _stamp_turn(sec + 0.45)
	if not is_inside_tree():
		return
	if _cmds_open():
		# con la ruota aperta la notizia va tra gli avvisi a sinistra: si legge lo stesso e non copre i comandi
		_notice("%s · %s" % [title, sub], col, sec, "boss" if col == Ui.PINK else "fx")
		return
	var box := VBoxContainer.new()
	Ui.place(box, 0.2, STAMP_AY, 0.8, STAMP_AY, 0, 0, 0, 130)       # nello stesso posto dei timbri, in coda con loro
	_stamps.append(box)
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var live := Ui.label("●  IN DIRETTA", 20, Color("#ff4630"), Ui.display(), 6)
	live.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(live)
	var big := Ui.label(title, 48, col, Ui.display(), 10)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(big)
	var sm := Ui.label(sub, 20, Ui.CREAM, null, 6)
	sm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sm)
	_fx_layer.add_child(box)
	box.modulate.a = 0.0
	var tw := box.create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.12)
	tw.tween_interval(sec)
	tw.tween_property(box, "modulate:a", 0.0, 0.3)
	tw.tween_callback(box.queue_free)


# Coda dei timbri: aspetta che il precedente sia finito e che non ci sia il cerchio della parata, poi prenota il posto per sec secondi veri.
func _stamp_turn(sec: float) -> void:
	var now: int = Time.get_ticks_msec()
	var wait_ms: int = maxi(0, _stamp_free_ms - now)
	_stamp_free_ms = now + wait_ms + int(sec * 1000.0)
	if wait_ms > 0:
		await get_tree().create_timer(float(wait_ms) / 1000.0, true, false, true).timeout
	while _qte_on and is_inside_tree():
		await get_tree().process_frame
		_stamp_free_ms = maxi(_stamp_free_ms, Time.get_ticks_msec() + int(sec * 1000.0))
	_stamps = _stamps.filter(func(t) -> bool: return is_instance_valid(t))


func _cmds_open() -> bool:
	return (_wheel != null and _wheel.visible) or _skill_menu != null


# Mentre c'e' il cerchio della parata niente timbri sopra: si nascondono e tornano dopo.
func _hide_stamps(hide: bool) -> void:
	_stamps = _stamps.filter(func(t) -> bool: return is_instance_valid(t))
	for st in _stamps:
		(st as CanvasItem).visible = not hide


# Si apre la ruota: i timbri ancora a schermo spariscono in fretta e la coda riparte da zero.
func _clear_stamps() -> void:
	_stamps = _stamps.filter(func(t) -> bool: return is_instance_valid(t))
	for st in _stamps:
		var tw := (st as CanvasItem).create_tween()
		tw.tween_property(st, "modulate:a", 0.0, 0.12)
		tw.tween_callback((st as Node).queue_free)
	_stamps.clear()
	_stamp_free_ms = 0


func _toast(text: String, col: Color, sec: float) -> void:
	_notice(text, col, sec, "boss" if col == Ui.PINK or col == Color("#ff7a9c") else "fx")


# UN posto per tutti gli avvisi: a sinistra, sotto l'ordine dei turni (in alto al centro si scontravano coi numeri dei colpi). Lastre piccole con un'icona e poche
# parole (titolo grande, il resto piccolo solo se e' corto); al massimo due insieme, il nuovo scaccia il piu' vecchio.
func _notice(text: String, col: Color, sec: float, icon: String) -> void:
	_toasts = _toasts.filter(func(t) -> bool: return is_instance_valid(t))
	while _toasts.size() >= TOAST_MAX:
		var old: Control = _toasts.pop_front()
		old.queue_free()
	var parts: Array = CombatHud.notice_parts(text)
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mv: bool = icon == "move"
	# il nome della mossa come in Persona 5: lastra nera storta, scritta bianca, bordo rosso
	pc.add_theme_stylebox_override("panel", Ui.plate(Color(0.02, 0.01, 0.03, 0.94), Color("#ff2340") if mv else col, -0.18, 6 if mv else 5))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(hb)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(26, 26)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.draw.connect(func() -> void: _notice_icon(ic, icon, col))
	hb.add_child(ic)
	# mossa: grande il NOME della mossa, piccolo chi la fa ("RIO · ATTACCO" -> ATTACCO grande, RIO piccolo)
	var head: String = str(parts[1]) if mv and str(parts[1]) != "" else str(parts[0])
	var tail: String = str(parts[0]) if mv and str(parts[1]) != "" else str(parts[1])
	var big := Ui.label(head, 24 if mv else 20, Ui.CREAM if mv else col, Ui.display(), 6)
	hb.add_child(big)
	if tail != "":
		var sm := Ui.label(tail, 16, Color(Ui.CREAM, 0.9) if not mv else col.lightened(0.2), null, 4)
		hb.add_child(sm)
	_fx_layer.add_child(pc)
	_toasts.append(pc)
	_stack_notices()
	pc.modulate.a = 0.0
	var tw := pc.create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.08)
	tw.tween_interval(sec)
	tw.tween_property(pc, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		pc.queue_free()
		_toasts.erase(pc))


func _stack_notices() -> void:
	for i in _toasts.size():
		var c: Control = _toasts[i]
		Ui.place(c, 0.0, 0.0, 0.0, 0.0, 24, 0, 24, 0)
		c.grow_horizontal = Control.GROW_DIRECTION_END
		var y0: float = NOTICE_Y
		if _boss_panel != null and _boss_panel.visible and _boss_panel.size.y > 1.0:
			y0 = _boss_panel.position.y + _boss_panel.get_combined_minimum_size().y + 12.0      # subito sotto il nemico
		c.offset_top = y0 + 46.0 * float(_toasts.size() - 1 - i)


# Icone degli avvisi, disegnate a mano: catena (legami e impulsi), triangolo (il nemico), lampo (effetti), freccia (mossa)
func _notice_icon(c: Control, icon: String, col: Color) -> void:
	var p: Vector2 = c.size * 0.5
	match icon:
		"chain":
			for k in 2:
				var o: Vector2 = Vector2(-5.0 + 10.0 * k, 3.0 - 6.0 * k)
				c.draw_set_transform(p + o, -0.6, Vector2(1.0, 0.6))
				c.draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, col, 3.0, true)
				c.draw_set_transform(Vector2.ZERO)
		"boss":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -10), p + Vector2(10, 9), p + Vector2(-10, 9)]), col)
			c.draw_line(p + Vector2(0, -3), p + Vector2(0, 3), Ui.INK, 2.5)
			c.draw_circle(p + Vector2(0, 6), 1.5, Ui.INK)
		"move":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -9), p + Vector2(9, 0), p + Vector2(-8, 9), p + Vector2(-3, 0)]), col)
		_:
			CmdWheel.glyph(c, "skill", p, 12.0, col)


func _toggle_auto() -> void:
	if _pause != null:
		return
	auto_on = not auto_on
	_btn_auto.text = "AUTO ON" if auto_on else "AUTO"
	if auto_on and waiting:
		waiting = false
		_show_commands(false)
		await _do_action(cur_pid, (BattleAI.choose_quick(b, cur_pid) if _quick else BattleAI.choose(b, cur_pid)), _quick)
		if is_inside_tree() and not ended:
			await _advance()


func _toggle_fast() -> void:
	if _pause != null:
		return
	fast = not fast
	Engine.time_scale = 1.8 if fast else 1.0
	_btn_fast.text = "x2" if fast else "x1"


func _unhandled_input(event: InputEvent) -> void:
	if (_freeze_on or _team_on) and ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and not event.echo)):
		_freeze_skip = true
		get_viewport().set_input_as_handled()
		return
	if _cutin_on and _pause == null and not ended:
		var skip: bool = (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode in [KEY_SPACE, KEY_ENTER])
		if skip:
			_cutin_finish()
			get_viewport().set_input_as_handled()
			return
	if _qte_on:
		var tap: bool = (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_1, KEY_4])
		if tap:
			_qte_tap()
			get_viewport().set_input_as_handled()
			return
	if _skill_menu != null and event is InputEventKey and event.pressed:
		match (event as InputEventKey).physical_keycode:
			KEY_UP, KEY_W:
				_skill_menu.move(-1)
			KEY_DOWN, KEY_S:
				_skill_menu.move(1)
			KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
				_skill_menu.accept()
			KEY_ESCAPE, KEY_BACKSPACE:
				_close_skills()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		match k:
			KEY_ESCAPE:
				if _pause != null:
					_close_pause()
				else:
					_open_pause()
			KEY_SPACE, KEY_ENTER:
				_wheel_tap(_picked if _picked != "" else "attack")
			KEY_1:
				_wheel_tap("attack")
			KEY_2:
				_wheel_tap("skill")
			KEY_3:
				_wheel_tap("ult")
			KEY_R:
				for rid in ["interruzione", "schivata", "intercettazione", "soccorso"]:
					if _usable(rid) and (_react_btns[rid] as Button).visible:
						_react_cmd(rid)
						break
			KEY_4:
				_wheel_tap("guard")


func back() -> void:
	if _pause != null:
		_close_pause()
	else:
		_open_pause()


func _open_pause() -> void:
	if _pause != null:
		return
	Engine.time_scale = 0.0          # ferma animazioni e timer della battaglia
	_pause = HuddleMenu.new("ESCI", _close_pause, func() -> void:
		Engine.time_scale = 1.0
		_main().go("menu"), "Saul conosce un'uscita", not ritorno.is_empty())
	_root.add_child(_pause)
	# in pausa non si vedono mirino, comandi e menu ABILITA' (decisione dell'autore, 24/10/2026): si rimettono alla chiusura
	_pause_hid.clear()
	for n in [_wheel, _reticle, _skill_menu, _hint]:
		if n != null and is_instance_valid(n) and (n as CanvasItem).visible:
			(n as CanvasItem).visible = false
			_pause_hid.append(n)


func _close_pause() -> void:
	if _pause != null:
		_pause.queue_free()
		_pause = null
		HuddleMenu.quip(_root)
		for n in _pause_hid:
			if is_instance_valid(n):
				(n as CanvasItem).visible = true
		_pause_hid.clear()
	Engine.time_scale = 1.8 if fast else 1.0
