class_name UiMotion
extends RefCounted

# Entrate animate dei pannelli, a scatti come nei menu di Persona:
# scivolano da un lato con un piccolo rimbalzo, uno dopo l'altro.


# Fa entrare i controlli (in ordine) dalla direzione indicata. Va chiamata dopo che
# la schermata e' stata costruita; aspetta un frame per conoscere le posizioni finali.
static func slide_in(controls: Array, from: Vector2 = Vector2(-120, 0), step: float = 0.06, seconds: float = 0.28) -> void:
	if controls.is_empty() or DisplayServer.get_name() == "headless":
		return
	var tree: SceneTree = (controls[0] as Node).get_tree()
	if tree == null:
		return
	await tree.process_frame
	var delay: float = 0.0
	for c in controls:
		if not is_instance_valid(c):
			continue
		var node: Control = c
		var target: Vector2 = node.position
		node.position = target + from
		node.modulate.a = 0.0
		var tw: Tween = node.create_tween()
		tw.set_parallel(true)
		tw.tween_property(node, "position", target, seconds).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "modulate:a", 1.0, seconds * 0.6).set_delay(delay)
		delay += step
