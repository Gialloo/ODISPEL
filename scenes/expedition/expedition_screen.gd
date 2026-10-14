class_name ExpeditionScreen
extends Control

# Schermata SPEDIZIONE: la mappa a 6 tappe, le scelte (da soli o votando in cooperativa), il resoconto e le cure.
# In solitaria la run vive in MissionConfig.expedition (e nel salvataggio); in cooperativa la possiede l'host (NetworkManager).

static var use_net: bool = false        # impostata dalla lobby prima di aprire la schermata

const NODE_NAMES: Array = ["PERCORSO", "SCONTRO", "EVENTO", "SCONTRO", "BIVIO", "BOSS"]

var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var net: NetworkManager = null
var _body: Control = null
var _side: VBoxContainer = null
var _strip: HBoxContainer = null
var _bottom: HBoxContainer = null
var _title: Label = null
var _sub: Label = null
var _setup_boss: String = "distributore"
var _setup_tier: int = 0
var _finish_lines: Array = []
var _chat: ChatPanel = null


func _ready() -> void:
	ScreenFrame.setup(self)
	if roster.is_empty():
		roster = RosterStore.load_or_new(save_path)
	var session: Node = get_node_or_null("/root/NetSession")
	if use_net and session != null and session.get("manager") != null:
		net = session.get("manager")
		net.lobby_updated.connect(_render)
	elif MissionConfig.expedition.is_empty():
		var saved: Variant = roster.get("expedition", {}).get("run", {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			MissionConfig.expedition = BattleState.normalize(saved)
	var sg: Dictionary = MissionConfig.suggest(roster)
	_setup_boss = str(sg["boss"])
	_setup_tier = clampi(int(sg["tier"]), 0, BattleContent.TIERS.size() - 1)
	_build()
	_render()


func _run() -> Dictionary:
	if net != null:
		return net.exp_run()
	return MissionConfig.expedition


func _is_host() -> bool:
	return net == null or net.is_host


func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	_title = BattleTheme.make_label("SPEDIZIONE", 40, BattleTheme.WH, true)
	_title.position = Vector2(24, 8)
	add_child(_title)
	_sub = BattleTheme.make_label("", 15, BattleTheme.CY_DIM)
	_sub.position = Vector2(28, 58)
	_sub.size = Vector2(1220, 22)
	add_child(_sub)
	_strip = HBoxContainer.new()
	_strip.position = Vector2(24, 86)
	_strip.size = Vector2(1232, 40)
	_strip.add_theme_constant_override("separation", 6)
	add_child(_strip)
	var left := HudPanel.new().setup("TAPPA", BattleTheme.CY)
	left.position = Vector2(20, 134)
	left.size = Vector2(800, 480 if not TouchUi.active() else 456)
	add_child(left)
	var lscroll := ScrollContainer.new()
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	lscroll.add_child(_body)
	left.set_content(lscroll)
	var right := HudPanel.new().setup("SPEDIZIONE IN CORSO", BattleTheme.GOLD)
	right.position = Vector2(836, 134)
	right.size = Vector2(424, 300 if net != null else (480 if not TouchUi.active() else 456))
	add_child(right)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side = VBoxContainer.new()
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.add_theme_constant_override("separation", 3)
	sc.add_child(_side)
	right.set_content(sc)
	if net != null:
		_chat = ChatPanel.new().setup(net, true, Vector2(424, 170))
		_chat.position = Vector2(836, 444)
		add_child(_chat)
	_bottom = HBoxContainer.new()
	_bottom.position = Vector2(20, 626 if not TouchUi.active() else 600)
	_bottom.size = Vector2(1240, 52)
	_bottom.add_theme_constant_override("separation", 10)
	add_child(_bottom)
	ScreenFx.menu_overlays(self, BattleTheme.RD)


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _btn(text: String, kind: String, size: int, on: Callable, width: float = 250.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 48)
	BattleTheme.style_button(b, kind, size)
	b.pressed.connect(on)
	return b


func _line(text: String, size: int = 16, color: Color = BattleTheme.WH, wrap: bool = true) -> Label:
	var l := BattleTheme.make_label(text, size, color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


# ---------- Disegno ----------

func _render() -> void:
	if _body == null or not is_inside_tree():
		return
	var run: Dictionary = _run()
	if not run.is_empty() and str(run.get("phase", "")) == "done":
		_settle(run)
	_clear(_body)
	_clear(_side)
	_clear(_strip)
	_clear(_bottom)
	_draw_strip(run)
	if run.is_empty():
		_draw_setup()
	else:
		_draw_run(run)
	_draw_side(run)


# Spedizione finita: premi, veterani e ferite (una volta sola per spedizione, sul salvataggio di chi gioca qui).
func _settle(run: Dictionary) -> void:
	var lines: Array = Expedition.finish(roster, run)
	if lines.is_empty():
		return
	_finish_lines = lines
	if net == null:
		var d: Dictionary = Expedition.data(roster)
		d["run"] = run
	RosterStore.save(roster, save_path)
	Snd.play("success" if str(run.get("result", "")) == "win" else "error")
	for l in lines:
		Notify.success(str(l))


func _draw_strip(run: Dictionary) -> void:
	var stage: int = int(run.get("stage", -1)) if not run.is_empty() else -1
	var done: bool = not run.is_empty() and str(run.get("phase", "")) == "done"
	var won: bool = done and str(run.get("result", "")) == "win"
	for i in NODE_NAMES.size():
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := StyleBoxFlat.new()
		var past: bool = won or (not run.is_empty() and i < stage)
		var cur: bool = not done and i == stage
		sb.bg_color = Color(0.1, 0.1, 0.03) if cur else (Color(0.03, 0.09, 0.11) if past else Color(0.03, 0.04, 0.05))
		sb.border_color = BattleTheme.GOLD if cur else (BattleTheme.CY_DARK if past else Color(0.2, 0.25, 0.28))
		sb.set_border_width_all(2)
		p.add_theme_stylebox_override("panel", sb)
		var text: String = "%d  %s" % [i + 1, NODE_NAMES[i]]
		if i == 4 and not run.is_empty() and int(run.get("stage", 0)) == 4 and Expedition.kind(run) == "fight":
			text = "%d  ELITE" % (i + 1)
		var l := BattleTheme.make_label(text, 15, BattleTheme.GOLD if cur else (BattleTheme.CY if past else BattleTheme.CY_DIM))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		_strip.add_child(p)


func _draw_setup() -> void:
	_title.text = "SPEDIZIONE"
	_sub.text = "// 6 TAPPE · SCELTE CHE RESTANO · DA SOLI O IN COOPERATIVA" if net == null else "// SPEDIZIONE COOPERATIVA · L'HOST AVVIA, TUTTI VOTANO"
	_body.add_child(_line("Percorso, due scontri, un evento, un bivio e il boss finale. I PV si portano da una tappa all'altra, ogni vittoria dà un potenziamento.", 17))
	_body.add_child(_line("Se la squadra cade, chi è caduto resta FERITO (PV massimi -10% finché non passano 6 ore o paghi la cura). Se arrivi in fondo, o almeno al checkpoint, i tuoi operatori diventano VETERANI: bonus permanenti.", 15, BattleTheme.CY_DIM))
	if not Expedition.available(roster) and net == null:
		_body.add_child(_line("Per aprirla servono %d bersagli battuti almeno a NORMALE (ne hai %d)." % [Expedition.UNLOCK_BOSSES, Expedition.cleared_count(roster)], 18, BattleTheme.POP))
	elif _is_host():
		var boss_row := HBoxContainer.new()
		boss_row.add_theme_constant_override("separation", 10)
		_body.add_child(boss_row)
		boss_row.add_child(BattleTheme.make_label("BOSS FINALE", 18, BattleTheme.CY_DIM))
		boss_row.add_child(_btn("<", "normal", 22, _cycle_boss.bind(-1), 56.0))
		boss_row.add_child(BattleTheme.make_label(MissionConfig.boss_title(_setup_boss), 24, BattleTheme.WH, true))
		boss_row.add_child(_btn(">", "normal", 22, _cycle_boss.bind(1), 56.0))
		var tier_row := HBoxContainer.new()
		tier_row.add_theme_constant_override("separation", 10)
		_body.add_child(tier_row)
		tier_row.add_child(BattleTheme.make_label("DIFFICOLTA'", 18, BattleTheme.CY_DIM))
		tier_row.add_child(_btn("<", "normal", 22, _cycle_tier.bind(-1), 56.0))
		tier_row.add_child(BattleTheme.make_label(str(BattleContent.tier_of(_setup_tier)["name"]), 24, BattleTheme.WH, true))
		tier_row.add_child(_btn(">", "normal", 22, _cycle_tier.bind(1), 56.0))
		_bottom.add_child(_btn("INIZIA LA SPEDIZIONE", "primary", 22, _start_run, 330.0))
	else:
		_body.add_child(_line("In attesa che l'host avvii la spedizione...", 20, BattleTheme.POP))
	var hurt: Array = Expedition.wounded(roster)
	if not hurt.is_empty():
		_body.add_child(_line("FERITI: " + ", ".join(PackedStringArray(hurt.map(func(c: Variant) -> String: return str(BattleContent.CHARACTERS.get(str(c), {}).get("name", c)).to_upper()))), 16, BattleTheme.RD))
	_bottom.add_child(_btn("COPIA CODICE SQUADRA", "normal", 18, _copy_code, 290.0))
	_bottom.add_child(_btn("TORNA ALLA LOBBY" if net != null else "TORNA ALL'HUB", "normal", 20, _leave))


func _copy_code() -> void:
	DisplayServer.clipboard_set(BuildCode.encode(RosterState.team_entries(roster)))
	Snd.play("click")
	Notify.toast("CODICE SQUADRA COPIATO: incollalo a un amico", Notify.Kind.SUCCESS)


func _draw_run(run: Dictionary) -> void:
	var k: String = Expedition.kind(run)
	_title.text = "SPEDIZIONE  ·  %s" % MissionConfig.boss_title(str(run["boss"]))
	_sub.text = "// %s%s" % [Expedition.stage_title(run), "  ·  COOPERATIVA" if bool(run.get("coop", false)) else ""]
	match k:
		"fight":
			_draw_fight(run)
		"done":
			_draw_done(run)
		_:
			_draw_choices(run, k)
	if k != "done":
		_bottom.add_child(_btn("ABBANDONA" if _is_host() else "TORNA ALLA LOBBY", "normal", 18, _abandon if _is_host() else _leave, 200.0))


func _draw_choices(run: Dictionary, k: String) -> void:
	var intro: String = {"path": "Tre strade verso il boss. Scegliete quale rischio affrontare.", "event": "Un'entità offre qualcosa in cambio di qualcosa.", "cross": "Prima del boss: un'ultima decisione.", "boon": "Il gruppo sceglie un potenziamento che dura fino a fine spedizione."}[k]
	_body.add_child(_line(intro, 17, BattleTheme.CY_DIM))
	var votes: Dictionary = run.get("votes", {})
	var mine: String = str(votes.get(_me(), ""))
	for o in Expedition.options(run):
		var oid: String = str(o["id"])
		var n: int = 0
		for pid in votes:
			if str(votes[pid]) == oid:
				n += 1
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 92)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var vote_text: String = ""
		if net != null:
			vote_text = "   ·   VOTI %d%s" % [n, "  (IL TUO)" if mine == oid else ""]
		b.text = "[%s]  %s%s\n%s" % [str(o["tag"]), str(o["name"]), vote_text, str(o["desc"])]
		BattleTheme.style_button(b, "primary" if mine == oid else "normal", 17)
		b.pressed.connect(_pick.bind(oid))
		_body.add_child(b)
	if net != null:
		if _is_host():
			_bottom.add_child(_btn("CONFERMA (MAGGIORANZA)", "primary", 20, func() -> void: net.host_exp_confirm(), 330.0))
		else:
			_bottom.add_child(_line("Vota: decide la maggioranza, in pareggio l'host.", 16, BattleTheme.POP))


func _draw_fight(run: Dictionary) -> void:
	var bp: Dictionary = Expedition.battle_params(run)
	_body.add_child(_line("%s  ·  %s" % [Expedition.stage_title(run), MissionConfig.boss_title(str(bp["boss"]))], 26, BattleTheme.WH))
	if str(bp["mod"]) != "":
		var desc: String = ""
		for m in Endless.MODS:
			if str(m["id"]) == str(bp["mod"]):
				desc = str(m["desc"])
		_body.add_child(_line("DISTORSIONE: %s — %s" % [Expedition.mod_name(str(bp["mod"])), desc], 18, BattleTheme.POP))
	if str(bp["role"]) == "boss":
		_body.add_child(_line("Livello: %s" % str(BattleContent.tier_of(int(bp["tier"]))["name"]), 18, BattleTheme.CY))
		if int(run["clue"]) > 0:
			_body.add_child(_line("INDIZI: il boss parte con meno equilibrio e il suo comportamento è noto.", 17, BattleTheme.CY))
		_body.add_child(_line("Prima del boss finale puoi ancora cambiare le abilità dalla schermata SQUADRA.", 15, BattleTheme.CY_DIM))
	else:
		_body.add_child(_line("Un nemico più debole del boss finale, ma i PV non si recuperano da soli.", 16, BattleTheme.CY_DIM))
	if bool(run.get("elite", false)) and str(bp["role"]) == "combat1":
		_body.add_child(_line("ZONA INFESTATA: nemico potenziato, ma vincendo scegli DUE potenziamenti.", 16, BattleTheme.POP))
	if str(run.get("pact_unit", "")) != "":
		_body.add_child(_line("PATTO: %s è indebolito (PV massimi -15%%)." % str(BattleContent.CHARACTERS.get(str(run["pact_unit"]), {}).get("name", run["pact_unit"])).to_upper(), 16, BattleTheme.RD))
	if _is_host():
		_bottom.add_child(_btn("COMBATTI", "primary", 26, _fight, 300.0))
		if net != null and net.get_connected_human_count() < 2:
			_bottom.add_child(_line("Servono almeno 2 giocatori collegati.", 16, BattleTheme.POP))
	else:
		_bottom.add_child(_line("L'host avvierà il combattimento.", 18, BattleTheme.POP))


func _draw_done(run: Dictionary) -> void:
	var won: bool = str(run.get("result", "")) == "win"
	_body.add_child(_line("SPEDIZIONE COMPLETATA" if won else "SPEDIZIONE FALLITA", 34, BattleTheme.GOLD if won else BattleTheme.RD))
	for l in Expedition.summary(run):
		_body.add_child(_line(str(l), 16, BattleTheme.WH))
	_body.add_child(_line("Premi: +%d crediti%s" % [int(Expedition.reward(run)["coins"]), "  ·  nuclei e leghe" if not (Expedition.reward(run)["materials"] as Dictionary).is_empty() else ""], 17, BattleTheme.CY))
	for l in _finish_lines:
		_body.add_child(_line(str(l), 16, BattleTheme.POP))
	if not won:
		_body.add_child(_line("Perdere insegna: leggi il resoconto e cambia strategia alla prossima.", 15, BattleTheme.CY_DIM))
	if _is_host():
		_bottom.add_child(_btn("NUOVA SPEDIZIONE", "primary", 22, _close_run, 300.0))
	_bottom.add_child(_btn("TORNA ALLA LOBBY" if net != null else "TORNA ALL'HUB", "normal", 20, _leave))


func _draw_side(run: Dictionary) -> void:
	if run.is_empty():
		var d: Dictionary = Expedition.data(roster)
		_side.add_child(_line("SPEDIZIONI %d  ·  VINTE %d  ·  RECORD TAPPA %d" % [int(d["runs"]), int(d["wins"]), int(d["best"])], 15, BattleTheme.CY))
		_side.add_child(_line("OPERATORI", 15, BattleTheme.GOLD))
		for id in roster.get("team", []):
			var nm: String = str(BattleContent.CHARACTERS.get(str(id), {}).get("name", id)).to_upper()
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var info: String = "%s   VETERANO %d" % [nm, Expedition.vet_level(roster, str(id))]
			var hurt: bool = Expedition.is_wounded(roster, str(id))
			var l := _line(info + ("   FERITO" if hurt else ""), 14, BattleTheme.RD if hurt else BattleTheme.WH)
			row.add_child(l)
			if hurt:
				var cb := Button.new()
				cb.text = "CURA %d" % Expedition.HEAL_COST
				cb.custom_minimum_size = Vector2(110, 32)
				BattleTheme.style_button(cb, "normal", 14)
				cb.pressed.connect(_heal.bind(str(id)))
				row.add_child(cb)
			_side.add_child(row)
		return
	_side.add_child(_line("Provviste %d  ·  Indizi %d  ·  Vittorie %d" % [int(run["supplies"]), int(run["clue"]), int(run["wins"])], 16, BattleTheme.CY))
	var counts: Dictionary = {}
	for b in run["boons"]:
		counts[str(b)] = int(counts.get(str(b), 0)) + 1
	_side.add_child(_line("POTENZIAMENTI", 15, BattleTheme.GOLD))
	if counts.is_empty():
		_side.add_child(_line("nessuno ancora", 14, BattleTheme.CY_DIM))
	for b in counts:
		_side.add_child(_line("%s%s  %s" % [str(Endless.BOONS[b]["name"]), (" x%d" % int(counts[b])) if int(counts[b]) > 1 else "", str(Endless.BOONS[b]["desc"])], 14, BattleTheme.WH))
	if not (run["fell"] as Dictionary).is_empty():
		_side.add_child(_line("CADUTI (rischio ferita)", 15, BattleTheme.RD))
		for c in run["fell"]:
			_side.add_child(_line(str(BattleContent.CHARACTERS.get(str(c), {}).get("name", c)).to_upper(), 14, BattleTheme.RD))
	_side.add_child(_line("DIARIO", 15, BattleTheme.GOLD))
	for l in run["log"]:
		_side.add_child(_line(str(l), 13, BattleTheme.CY_DIM))


# ---------- Azioni ----------

func _me() -> String:
	return net.local_player_id if net != null else "solo"


func _cycle_boss(dir: int) -> void:
	var ids: Array = []
	for id in BattleContent.BOSS_ORDER:
		if net != null or RosterState.is_boss_unlocked(roster, str(id)):
			ids.append(str(id))
	if ids.is_empty():
		return
	var i: int = (ids.find(_setup_boss) + dir + ids.size()) % ids.size()
	_setup_boss = str(ids[i])
	_setup_tier = mini(_setup_tier, _max_tier())
	_render()


func _max_tier() -> int:
	if net != null:
		return BattleContent.TIERS.size() - 1
	var t: int = 0
	for i in BattleContent.TIERS.size():
		if RosterState.is_tier_unlocked(roster, _setup_boss, i):
			t = i
	return t


func _cycle_tier(dir: int) -> void:
	_setup_tier = clampi(_setup_tier + dir, 0, _max_tier())
	_render()


func _start_run() -> void:
	if net != null:
		if not net.host_exp_new(_setup_boss, _setup_tier):
			Notify.warning("Non si può iniziare adesso.")
		return
	if not Expedition.available(roster):
		return
	MissionConfig.expedition = Expedition.new_run(int(randi()) | 1, _setup_boss, _setup_tier, false)
	_save_solo()
	_render()


func _pick(option_id: String) -> void:
	if net != null:
		net.exp_vote(option_id)
		return
	var run: Dictionary = MissionConfig.expedition
	if Expedition.choose(run, option_id) == "":
		_save_solo()
		Snd.play("click")
	_render()


func _fight() -> void:
	if net != null:
		if not net.host_exp_fight():
			Notify.warning("Non si può iniziare il combattimento adesso.")
		return
	_save_solo()
	SceneRouter.go("battle", true)


func _save_solo() -> void:
	var d: Dictionary = Expedition.data(roster)
	d["run"] = MissionConfig.expedition
	RosterStore.save(roster, save_path)


func _heal(char_id: String) -> void:
	var err: String = Expedition.heal(roster, char_id)
	if err != "":
		Notify.warning(err.capitalize())
		return
	RosterStore.save(roster, save_path)
	Snd.play("success")
	_render()


func _abandon() -> void:
	ConfirmBox.ask(self, "Abbandonare la spedizione? Si perdono i progressi della run.", _close_run)


func _close_run() -> void:
	_finish_lines = []
	if net != null:
		net.host_exp_close()
	else:
		MissionConfig.expedition = {}
		Expedition.data(roster).erase("run")
		RosterStore.save(roster, save_path)
	_render()


func _leave() -> void:
	if net != null:
		SceneRouter.go("lobby")
		return
	if not MissionConfig.expedition.is_empty() and str(MissionConfig.expedition.get("phase", "")) == "done":
		MissionConfig.expedition = {}
		Expedition.data(roster).erase("run")
		RosterStore.save(roster, save_path)
	use_net = false
	SceneRouter.go("hub")
