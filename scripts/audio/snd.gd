class_name Snd
extends RefCounted

# Porta d'ingresso per i suoni. Senza il gestore audio (test) non fa nulla.


static func _mgr() -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("Sfx")
	return null


static func play(sound: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var m: Node = _mgr()
	if m != null:
		m.play(sound, pitch, volume_db)


# Abbassa la musica per un po' (fine battaglia, avvisi importanti).
static func duck(db: float = -10.0) -> void:
	var m: Node = _mgr()
	if m != null:
		m.duck(db)
