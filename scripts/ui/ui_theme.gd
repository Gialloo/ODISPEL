class_name UiTheme
extends RefCounted

# Tema grafico di tutto il gioco (telecamera di sorveglianza + HUD arcade).
# Si applica una volta alla finestra principale: bottoni, testi, campi, menu a
# tendina, finestre di dialogo e barre di scorrimento lo ereditano.


static func _box(bg: Color, border: Color, width: int = 2, margin: float = 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(0)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	return s


static func build() -> Theme:
	var t := Theme.new()
	var mono: Font = BattleTheme.mono()
	var display: Font = BattleTheme.display()
	t.default_font = mono
	t.default_font_size = 18 if TouchUi.active() else 16

	# Testi
	t.set_color("font_color", "Label", BattleTheme.CY)
	t.set_font("font", "Label", mono)

	# Bottoni (ciano; "primary" e' un'eccezione dei singoli schermi)
	for cls in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", cls, SlantBox.make(BattleTheme.BK, BattleTheme.CY, 14.0, BattleTheme.CY_DARK, 2.0))
		t.set_stylebox("hover", cls, SlantBox.make(BattleTheme.CY, BattleTheme.BK, 14.0, BattleTheme.CY_DIM, 2.0))
		t.set_stylebox("pressed", cls, SlantBox.make(BattleTheme.CY, BattleTheme.WH, 14.0, BattleTheme.CY_DIM, 2.0))
		t.set_stylebox("disabled", cls, SlantBox.make(Color(0.02, 0.06, 0.07), BattleTheme.CY_DARK, 14.0, Color(0, 0, 0, 0), 2.0))
		t.set_stylebox("focus", cls, StyleBoxEmpty.new())
		t.set_color("font_color", cls, BattleTheme.WH)
		t.set_color("font_hover_color", cls, BattleTheme.BK)
		t.set_color("font_pressed_color", cls, BattleTheme.BK)
		t.set_color("font_disabled_color", cls, Color("#8196a0"))
		t.set_font("font", cls, BattleTheme.menu())
		t.set_font_size("font_size", cls, 20)

	# Caselle di spunta
	t.set_color("font_color", "CheckBox", BattleTheme.CY)
	t.set_color("font_hover_color", "CheckBox", BattleTheme.WH)
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())

	# Campi di testo
	t.set_stylebox("normal", "LineEdit", _box(BattleTheme.PANEL, BattleTheme.CY_DIM, 2))
	t.set_stylebox("focus", "LineEdit", _box(BattleTheme.PANEL, BattleTheme.CY, 2))
	t.set_stylebox("read_only", "LineEdit", _box(BattleTheme.BK, BattleTheme.CY_DARK, 2))
	t.set_color("font_color", "LineEdit", BattleTheme.WH)
	t.set_color("caret_color", "LineEdit", BattleTheme.RD)
	t.set_color("selection_color", "LineEdit", BattleTheme.CY_DIM)
	t.set_color("font_placeholder_color", "LineEdit", BattleTheme.CY_DARK)
	t.set_font("font", "LineEdit", mono)

	# Menu a tendina e popup
	t.set_stylebox("panel", "PopupMenu", _box(BattleTheme.PANEL, BattleTheme.CY, 2))
	t.set_stylebox("hover", "PopupMenu", _box(BattleTheme.CY, BattleTheme.CY, 0, 6.0))
	t.set_color("font_color", "PopupMenu", BattleTheme.CY)
	t.set_color("font_hover_color", "PopupMenu", BattleTheme.BK)
	t.set_color("font_disabled_color", "PopupMenu", BattleTheme.CY_DARK)
	t.set_color("font_separator_color", "PopupMenu", BattleTheme.CY_DIM)
	t.set_font("font", "PopupMenu", mono)
	t.set_font_size("font_size", "PopupMenu", 18)
	t.set_stylebox("separator", "PopupMenu", _box(BattleTheme.CY_DIM, BattleTheme.CY_DIM, 0))

	# Finestre di dialogo
	t.set_stylebox("panel", "AcceptDialog", _box(BattleTheme.PANEL, BattleTheme.RD, 2, 16.0))
	t.set_stylebox("embedded_border", "Window", _box(BattleTheme.PANEL, BattleTheme.RD, 2, 12.0))
	t.set_color("title_color", "Window", BattleTheme.WH)
	t.set_font("title_font", "Window", display)
	t.set_font_size("title_font_size", "Window", 20)

	# Pannelli
	t.set_stylebox("panel", "PanelContainer", _box(BattleTheme.PANEL, BattleTheme.CY_DIM, 2, 12.0))
	t.set_stylebox("panel", "Panel", _box(BattleTheme.PANEL, BattleTheme.CY_DIM, 2, 12.0))

	# Separatori
	var line := StyleBoxLine.new()
	line.color = BattleTheme.CY_DARK
	line.thickness = 2
	t.set_stylebox("separator", "HSeparator", line)
	var vline := StyleBoxLine.new()
	vline.color = BattleTheme.CY_DARK
	vline.thickness = 2
	vline.vertical = true
	t.set_stylebox("separator", "VSeparator", vline)

	# Barre di scorrimento
	for cls in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", cls, _box(BattleTheme.BK, BattleTheme.CY_DARK, 1, 2.0))
		t.set_stylebox("grabber", cls, _box(BattleTheme.CY_DIM, BattleTheme.CY_DIM, 0, 2.0))
		t.set_stylebox("grabber_highlight", cls, _box(BattleTheme.CY, BattleTheme.CY, 0, 2.0))
		t.set_stylebox("grabber_pressed", cls, _box(BattleTheme.WH, BattleTheme.WH, 0, 2.0))

	# Barre di avanzamento
	t.set_stylebox("background", "ProgressBar", _box(BattleTheme.BK, BattleTheme.CY_DARK, 2, 2.0))
	t.set_stylebox("fill", "ProgressBar", _box(BattleTheme.CY, BattleTheme.CY, 0, 2.0))
	t.set_color("font_color", "ProgressBar", BattleTheme.WH)

	# Suggerimenti al passaggio del mouse
	t.set_stylebox("panel", "TooltipPanel", _box(BattleTheme.PANEL, BattleTheme.RD, 2, 8.0))
	t.set_color("font_color", "TooltipLabel", BattleTheme.WH)

	# Testo ricco
	t.set_color("default_color", "RichTextLabel", BattleTheme.CY)
	t.set_font("normal_font", "RichTextLabel", mono)
	return t
