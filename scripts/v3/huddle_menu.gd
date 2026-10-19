class_name HuddleMenu
extends ColorRect

# Menu di pausa: la "riunione d'emergenza". I quattro fuggitivi si stringono in cerchio e sussurrano, il mondo resta fermo.
# Ogni voce del menu ha il suo padrone: quando la scegli, e' lui a parlare (Lance riparte, Nox abbassa il volume, Saul
# conosce un'uscita). Rio non ha una voce: si mette al centro. In battaglia Engine.time_scale = 0, quindi le animazioni
# ignorano il tempo del gioco. Ritratti PROVVISORI: in attesa dei disegni dei quattro accovacciati.

const PORTRAIT_DIR: String = "res://assets/portraits/"

# chi, espressione, specchiato, posizione rispetto al centro, rotazione (gradi), scala. Dal fondo al davanti.
const RING: Array = [
	{"id": "nox", "espr": "neutro", "flip": false, "pos": Vector2(-95, -150), "rot": 5.0, "scale": 0.82},
	{"id": "ferri", "espr": "serio", "flip": false, "pos": Vector2(-235, -60), "rot": 9.0, "scale": 1.0},
	{"id": "saul", "espr": "sfotto", "flip": true, "pos": Vector2(235, -60), "rot": -9.0, "scale": 1.0},
	{"id": "zecca", "espr": "maschera", "flip": true, "pos": Vector2(45, -25), "rot": -4.0, "scale": 1.08},
]

const WHISPERS: Dictionary = {
	"ferri": ["Bene. Nessuno si muova. Valutiamo le opzioni.", "Sottovoce. Ho detto sottovoce.", "Siamo in ritardo di quattro secondi."],
	"saul": ["Io un'opzione ce l'ho. Ma costa.", "Conosco un tizio. Non chiedete quale.", "Tecnicamente non è un furto se nessuno se ne accorge."],
	"zecca": ["Aspettate. Questa luce mi fa sembrare stanco.", "Raga, se la riunione la filmo viene benissimo.", "TITOLO: «Riunione segretissima». Non la posto. Forse."],
	"nox": ["Possiamo essere morti quando riprendiamo?", "E se ce ne andassimo e basta?", "Svegliatemi quando avete deciso."],
}

const QUIPS: Array = [
	["zecca", "Aspettate. Quindi chi fa cosa?"],
	["ferri", "Saul. L'uscita è dall'altra parte."],
	["nox", "Bene. Benissimo. Nessuno ha capito il piano."],
	["saul", "Sapevo che sarebbe andata così."],
]

var _bubbles: Dictionary = {}       # id -> Label del sussurro
var _talk: Dictionary = {}          # id -> Tween del sussurro in corso (una battuta nuova copre la vecchia)
var _busy: bool = false


# exit_text: la terza voce (in esplorazione si torna al menu, in battaglia si esce); exit_hint la riga sotto.
func _init(exit_text: String, on_resume: Callable, on_exit: Callable, exit_hint: String = "Saul conosce un'uscita") -> void:
	color = Color(0.02, 0.01, 0.05, 0.82)
	Ui.place(self, 0, 0, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build(exit_text, on_resume, on_exit, exit_hint)


func _build(exit_text: String, on_resume: Callable, on_exit: Callable, exit_hint: String) -> void:
	# l'inquadratura e' una telecamera di Echo
	var cam := Ui.label("CAM 07 · RIUNIONE D'EMERGENZA", 22, Ui.CYAN, Ui.display(), 6)
	Ui.place(cam, 0, 0, 0, 0, 132, 20, 800, 60)
	add_child(cam)
	var rec := Ui.label("● REC", 20, Color("#ff4630"), Ui.display(), 5)
	Ui.place(rec, 0, 0, 0, 0, 28, 22, 130, 60)
	add_child(rec)
	var blink := rec.create_tween().set_loops().set_ignore_time_scale(true)
	blink.tween_property(rec, "modulate:a", 0.2, 0.5)
	blink.tween_property(rec, "modulate:a", 1.0, 0.5)

	# il cerchio
	var stage := Control.new()
	Ui.place(stage, 0.5, 0.47, 0.5, 0.47)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	var floor_ring := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	fs.set_corner_radius_all(200)
	floor_ring.add_theme_stylebox_override("panel", fs)
	floor_ring.position = Vector2(-330, 110)
	floor_ring.size = Vector2(660, 90)
	floor_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(floor_ring)
	for spec in RING:
		_add_member(stage, spec)

	# i foglietti: ogni voce ha il suo padrone
	var notes := HBoxContainer.new()
	notes.add_theme_constant_override("separation", 26)
	notes.alignment = BoxContainer.ALIGNMENT_CENTER
	Ui.place(notes, 0.5, 1, 0.5, 1, -520, -122, 520, -30)
	add_child(notes)
	notes.add_child(_note("RIPRENDI", "Lance ha la mappa", -3.0, func() -> void:
		_say_then("ferri", "Piano deciso. Si va.", on_resume)))
	notes.add_child(_note("IMPOSTAZIONI", "Nox abbassa il volume", 2.0, func() -> void:
		_say("nox", "Abbassate. Qualcuno sta cercando di dormire.")
		add_child(SettingsPanel.new())))
	notes.add_child(_note(exit_text, exit_hint, -2.0, func() -> void:
		_say_then("saul", "Conosco un'uscita. Per voi, gratis. Stavolta.", on_exit)))

	# i sussurri partono uno dopo l'altro
	var order: Array = ["ferri", "saul", "zecca", "nox"]
	for i in order.size():
		var id: String = order[i]
		var lines: Array = WHISPERS[id]
		_say(id, str(lines[randi() % lines.size()]), 0.35 + 0.9 * float(i))


func _add_member(stage: Control, spec: Dictionary) -> void:
	var id: String = str(spec["id"])
	var path: String = PORTRAIT_DIR + "%s_%s.png" % [id, str(spec["espr"])]
	if not ResourceLoader.exists(path):
		path = PORTRAIT_DIR + "%s_neutro.png" % id
	var s: float = float(spec["scale"])
	var size := Vector2(220, 330) * s
	var pos: Vector2 = spec["pos"]
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	tr.flip_h = bool(spec["flip"])
	tr.size = size
	tr.position = pos - size * 0.5
	tr.pivot_offset = size * 0.5
	tr.rotation_degrees = float(spec["rot"])
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tr)
	# si chinano verso il centro, piano, come chi bisbiglia
	var lean := tr.create_tween().set_loops().set_ignore_time_scale(true).set_trans(Tween.TRANS_SINE)
	lean.tween_property(tr, "rotation_degrees", float(spec["rot"]) * 1.5, 1.4 + randf() * 0.5)
	lean.tween_property(tr, "rotation_degrees", float(spec["rot"]), 1.4 + randf() * 0.5)
	# fumetto del sussurro sopra la testa
	var b := Ui.label("", 18, Ui.CREAM, null, 5)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.size = Vector2(240, 60)
	b.position = pos + Vector2(-120, -size.y * 0.5 - 30)
	b.modulate.a = 0.0
	stage.add_child(b)
	_bubbles[id] = b


func _note(text: String, owner_text: String, rot: float, action: Callable) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	var b := Ui.button(text, Ui.CREAM, 22, 230)
	b.pressed.connect(func() -> void:
		if not _busy:
			action.call())
	vb.add_child(b)
	var o := Ui.label(owner_text, 16, Color(1, 1, 1, 0.7))
	o.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(o)
	vb.pivot_offset = Vector2(115, 30)
	vb.rotation_degrees = rot
	return vb


func _say(id: String, text: String, delay: float = 0.0) -> void:
	var b: Label = _bubbles.get(id)
	if b == null:
		return
	if _talk.has(id) and (_talk[id] as Tween).is_valid():
		(_talk[id] as Tween).kill()
		if delay == 0.0:
			b.modulate.a = 0.0
	var tw := b.create_tween().set_ignore_time_scale(true)
	_talk[id] = tw
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_callback(func() -> void: b.text = "«" + text + "»")
	tw.tween_property(b, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.6)
	tw.tween_property(b, "modulate:a", 0.0, 0.4)


# Il padrone della voce parla, poi si esegue (mezzo secondo, abbastanza per leggere senza far aspettare).
func _say_then(id: String, text: String, then: Callable) -> void:
	_busy = true
	_say(id, text)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.55)
	tw.tween_callback(then)


# Alla ripresa si rialzano convinti di avere un piano. Mezzo secondo dopo, qualcuno rovina tutto.
static func quip(parent: Control) -> void:
	var q: Array = QUIPS[randi() % QUIPS.size()]
	var who: String = str(CastVisual.spec(str(q[0]))["name"]).to_upper()
	var l := Ui.label("%s: «%s»" % [who, str(q[1])], 22, Ui.CREAM, null, 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(l, 0, 1, 1, 1, 0, -170, 0, -130)
	l.modulate.a = 0.0
	parent.add_child(l)
	var tw := l.create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.5)
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
