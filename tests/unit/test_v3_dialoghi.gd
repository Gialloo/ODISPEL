extends SceneTree

# I dialoghi si leggono, ogni scena ha il riassunto, ogni personaggio ha un ritratto per ogni espressione usata.

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var data: Dictionary = DialogData.all()
	check(not data.is_empty(), "dialoghi.json si legge")
	for key in ["apertura", "telecamera", "scontrino", "distributore", "agguato", "finale", "vittoria", "sconfitta"]:
		check(not DialogData.lines(key).is_empty(), "scena %s con righe" % key)
		check(DialogData.recap(key) != "", "scena %s con riassunto" % key)
		for ln in DialogData.lines(key):
			var who: String = str(ln.get("chi", ""))
			if CastVisual.CAST.has(who):
				var expr: String = str(ln.get("espr", "neutro"))
				check(CastVisual.EXPRESSIONS.has(expr) or expr == "maschera", "espressione nota: %s/%s" % [who, expr])
				check(ResourceLoader.exists("res://assets/portraits/%s_%s.png" % [who, expr]), "ritratto %s_%s" % [who, expr])
			else:
				check(ln.has("col"), "nome libero %s con colore" % who)
	for id in CastVisual.ORDER:
		for expr in CastVisual.EXPR_ORDER:
			check(ResourceLoader.exists("res://assets/portraits/%s_%s.png" % [id, expr]), "ritratto %s_%s" % [id, expr])
	check(ResourceLoader.exists("res://assets/portraits/zecca_maschera.png"), "ritratto zecca_maschera")
	print("test_v3_dialoghi: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)
