extends SceneTree

var checks: int = 0
var fails: int = 0


func check(condition: bool, what: String) -> void:
	checks += 1
	if not condition:
		fails += 1
		push_error("FAIL: " + what)


func _init() -> void:
	var builder := CityBuilder.new(29)
	var first: Color = builder._c("#141b24")
	var size_after_first: int = builder._color_cache.size()
	var repeated: Color = builder._c("#141b24")
	check(first == repeated, "lo stesso HEX restituisce lo stesso colore")
	check(builder._color_cache.size() == size_after_first, "un cache hit non aggiunge una voce")

	var other: Color = builder._c("#e8343f")
	check(other != first, "HEX differenti conservano colori differenti")
	check(builder._color_cache.size() == size_after_first + 1, "un nuovo HEX viene memorizzato una sola volta")

	if fails == 0:
		print("test_v3_city_builder: OK (%d verifiche)" % checks)
	else:
		print("test_v3_city_builder: %d/%d FALLITI" % [fails, checks])
	quit(1 if fails > 0 else 0)
