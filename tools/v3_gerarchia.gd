extends SceneTree

# HUD COMBAT 2.0 (7/11/2026): prova delle SOVRAPPOSIZIONI e schermate degli stati, con la gerarchia accesa o spenta.
# Per ogni stato raccoglie lo spazio vero dei pezzi dell'HUD (pannello nemico, ORDINE, tasti rapidi, comandi, descrizione,
# Ritmo, squadra, tendina delle abilita') e segnala ogni coppia che si tocca (margine 8 px). Esce con 1 se ne trova.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 --fixed-fps 60 -s tools/v3_gerarchia.gd -- \
#        <cartella> [touch|pc] [boss] [on|off]
#   (--fixed-fps 60: il pannello del nemico finisce di scivolare anche dove la macchina disegna a 10 fps)
# Formati da provare: 1280x720 (16:9), 2400x1080 (20:9 telefono), 1280x800 (16:10), 1600x1200 (4:3 tablet).
var out: String = "/tmp/v3gerarchia"
var boss: String = "autovelox"
var problemi: int = 0
const MARGINE: float = 4.0       # ogni rettangolo cresce di 4 per lato: 8 px fra due pezzi


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	if a.size() > 2:
		boss = a[2]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	Settings.hud_gerarchia = not (a.size() > 3 and a[3] == "off")      # off = come la 0.63.0
	_run()


func _shot(n: String) -> void:
	for i in 4:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _g(c: Control, r: Rect2) -> Rect2:
	# da coordinate del controllo a coordinate dello schermo (la vista di base, come i Control)
	return Rect2(c.get_global_rect().position + r.position, r.size)


func _pezzi(bt: Node) -> Dictionary:
	var p: Dictionary = {}
	var bp: Control = bt.get("_boss_panel")
	if bp != null and bp.visible and bp.modulate.a > 0.5:
		p["nemico"] = bp.get_global_rect()
	var tb: Control = bt.get("_top_bar")
	if tb != null and tb.visible:
		var u: Rect2 = Rect2()
		for c in tb.get_children():
			if c is Control and (c as Control).visible:
				var cr: Rect2 = (c as Control).get_global_rect()
				u = u.merge(cr) if u.has_area() else cr
		if u.has_area():
			p["tasti_rapidi"] = u
	# squadra, ORDINE, Ritmo e descrizione sono disegnati: lo spazio si ricava dalle stesse formule dei loro _draw (0.63.0),
	# cosi' la misura non tocca il codice del gioco
	var vs0: Vector2 = root.get_viewport().get_visible_rect().size
	var p1: PortraitParty = bt.get("_p1")
	if p1 != null and p1.visible:
		var n: int = p1.party.size()
		var cww: float = PortraitParty.cw()
		if n > 0:
			var x0: float = vs0.x - 22.0 - cww * n - 14.0 * (n - 1)
			p["squadra"] = Rect2(Vector2(x0 - 4.0, vs0.y - PortraitParty.top() - 30.0), Vector2(vs0.x - 22.0 - x0 + 10.0, PortraitParty.top() + 30.0))
		if p1.order_on and not p1.order.is_empty():
			var oy: float = 6.0 if Settings.hud_alto else 76.0
			var y2: float = oy + 54.0
			for e in p1.order:
				y2 += (46.0 if bool(e.get("now", false)) else 38.0) + 6.0
			var ow: float = PortraitParty.order_width()
			p["ordine"] = Rect2(Vector2(vs0.x - ow, oy), Vector2(ow, y2 - oy))
	var rb: Control = bt.get("_ritmo_bar")
	if rb != null and rb.visible:
		var yb: float = vs0.y - PortraitParty.top() - 42.0
		p["ritmo"] = Rect2(Vector2(vs0.x - 22.0 - 410.0, yb - 26.0), Vector2(410.0, 13.0 + 30.0))
	var w: Control = bt.get("_wheel")
	if w is PortraitHud and w.visible:
		var rr: Dictionary = w.get("_rects")
		var left: float = PortraitHud.PW * PortraitHud.CORNICE_SCALA + 14.0
		for k in rr:
			p["comando_" + str(k)] = _g(w, rr[k])
			left = maxf(left, (rr[k] as Rect2).end.x + 44.0)
		if str(w.get("picked")) != "":
			var right: float = w.size.x - 22.0 - PortraitParty.cw() * 4.0 - 42.0 - 16.0
			var bw: float = clampf(right - left, 280.0, 440.0)
			var bh: float = 34.0 + 20.0 * 2.0
			p["descrizione"] = _g(w, Rect2(Vector2((left + right) * 0.5 - bw * 0.5, w.size.y - 18.0 - bh), Vector2(bw, bh)))
	var sm: Control = bt.get("_skill_menu")
	if sm != null and sm.visible:
		# vietato toccare le righe vere della tendina (_list_rect); la riserva piu' larga di area() serve solo a spostare il nemico
		p["tendina_abilita"] = _g(sm, sm.call("_list_rect"))
	return p


# CLASSI DELLE SOVRAPPOSIZIONI (correzione 4 dell'autore, 7/11/2026)
# - VIETATE: le coppie qui sotto, con 8 px di aria, e ogni pezzo fuori dallo schermo.
# - CONSENTITE: testi e barre dentro il proprio pannello (non sono pezzi separati qui), la riserva larga della tendina
#   (area(): serve solo a spostare il nemico; si controllano le righe vere, _list_rect).
# - INTENZIONALI: ritratto e cornice sotto i comandi, nome sul ritratto, scena 3D sotto tutto (non misurati).
# - DI STATO: nemico e tendina. Con la tendina aperta il nemico puo' anche non esserci (regola di _place_boss_tag); se c'e',
#   non deve toccare le righe. Durante le mosse lo spettacolo torna pieno e non si controlla niente.
# I comandi fra loro hanno gia' il loro test di tocco (zone separate dello stile 0.58).
const COPPIE: Array = [
	["nemico", "ordine"], ["nemico", "tasti_rapidi"], ["nemico", "tendina_abilita"], ["nemico", "ritmo"], ["nemico", "squadra"],
	["descrizione", "squadra"], ["descrizione", "ritmo"], ["ritmo", "ordine"], ["squadra", "ordine"], ["tasti_rapidi", "ordine"],
]


func _controlla(stato: String, bt: Node) -> void:
	var p: Dictionary = _pezzi(bt)
	var vs: Vector2 = root.get_viewport().get_visible_rect().size
	var righe: Array = []
	for c in COPPIE:
		_coppia(stato, p, str(c[0]), str(c[1]), righe)
	for k in p:
		if str(k).begins_with("comando_"):
			for o in ["descrizione", "squadra", "ritmo", "nemico"]:
				_coppia(stato, p, str(k), o, righe)
		var r: Rect2 = p[k]
		if r.position.x < -1.0 or r.position.y < -1.0 or r.end.x > vs.x + 1.0 or r.end.y > vs.y + 1.0:
			if not str(k).begins_with("tendina"):
				righe.append("FUORI SCHERMO %s %s (vista %s)" % [k, r, vs])
				problemi += 1
	print("[%s] vista %s · pezzi: %s" % [stato, vs, ", ".join(p.keys())])
	if p.has("nemico") and p.has("ordine"):
		print("  nemico largo %d, da x %d a %d; ORDINE da x %d: spazio libero %d px" % [int(p["nemico"].size.x), int(p["nemico"].position.x), int(p["nemico"].end.x), int(p["ordine"].position.x), int(p["ordine"].position.x - p["nemico"].end.x)])
	for r in righe:
		print("  " + str(r))


func _coppia(stato: String, p: Dictionary, a: String, b: String, righe: Array) -> void:
	if not p.has(a) or not p.has(b):
		return
	var ra: Rect2 = (p[a] as Rect2).grow(MARGINE)
	var rb: Rect2 = (p[b] as Rect2).grow(MARGINE)
	if ra.intersects(rb):
		righe.append("SOVRAPPOSTI %s e %s: %s / %s" % [a, b, p[a], p[b]])
		problemi += 1


func _run() -> void:
	await process_frame
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": boss, "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 600:
		guard += 1
		await process_frame
	await create_timer(4.5).timeout          # gli avvisi d'inizio se ne vanno
	var w: PortraitHud = bt.get("_wheel")
	var tag: String = "on" if Settings.hud_gerarchia else "off"
	await create_timer(0.4).timeout
	_controlla("libero", bt)
	await _shot("%s_%s_1_libero" % [boss, tag])
	w.pick("attack")
	await create_timer(0.5).timeout
	_controlla("attacco_scelto", bt)
	await _shot("%s_%s_2_attacco_scelto" % [boss, tag])
	w.pick("")
	bt.call("_open_skills")
	await create_timer(1.5).timeout          # il pannello del nemico scivola al suo posto (lerp)
	_controlla("tendina_abilita", bt)
	await _shot("%s_%s_3_tendina_abilita" % [boss, tag])
	print("SOVRAPPOSIZIONI: %d" % problemi)
	quit(1 if problemi > 0 else 0)
