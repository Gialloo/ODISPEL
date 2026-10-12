extends SceneTree

# Reazioni dei pulsanti (scala, suono giusto) senza audio ne' schermo.
#   godot --headless --path . -s res://tests/unit/test_button_fx.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	return b


func _run() -> void:
	_check("indietro: suono 'back'", ButtonFx.sound_for(_btn("TORNA ALL'HUB")) == "back")
	_check("conferma: suono 'ready'", ButtonFx.sound_for(_btn("AVVIA MISSIONE")) == "ready")
	_check("normale: 'click'", ButtonFx.sound_for(_btn("EQUIPAGGIO")) == "click")
	_check("l'icona (spazi larghi) non cambia il suono", ButtonFx.sound_for(_btn("  RECLUTA x1")) == "ready")

	await process_frame        # gli autoload (e il loro aggancio ai pulsanti) partono dopo _init
	await process_frame
	var holder := Control.new()
	root.add_child(holder)
	var b := _btn("PROVA")
	b.size = Vector2(200, 50)
	holder.add_child(b)
	await process_frame
	b.mouse_entered.emit()
	await create_timer(0.25).timeout
	_check("hover: il pulsante si ingrandisce", b.scale.x > 1.01)
	b.mouse_exited.emit()
	await create_timer(0.25).timeout
	_check("uscita: torna normale", absf(b.scale.x - 1.0) < 0.01)
	b.button_down.emit()
	await create_timer(0.15).timeout
	_check("pressione: si schiaccia", b.scale.x < 0.99)
	b.button_up.emit()
	b.pressed.emit()
	_check("conferma: lampo bianco", b.modulate.r > 1.2)
	await create_timer(0.4).timeout
	_check("il lampo svanisce", b.modulate.r < 1.05)
	var off := _btn("SPENTO")
	off.disabled = true
	holder.add_child(off)
	await process_frame
	var x0: float = off.position.x
	ButtonFx.shake(off)
	await create_timer(0.35).timeout
	_check("pulsante spento: scossa e ritorno al posto", absf(off.position.x - x0) < 0.01)
	holder.queue_free()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
