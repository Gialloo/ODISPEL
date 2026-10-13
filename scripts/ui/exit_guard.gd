class_name ExitGuard
extends RefCounted

# "Vuoi uscire?" con SI' / NO. Si apre quando si preme indietro nell'hub, o quando si chiude la finestra
# del gioco sul PC. Con la domanda aperta, "indietro" vale NO.

const GROUP: String = "exit_confirm"
static var quit_function: Callable = Callable()   # i test lo sostituiscono: niente chiusura vera


static func is_open(tree: SceneTree) -> bool:
	return tree != null and not tree.get_nodes_in_group(GROUP).is_empty()


# host = dove mettere la finestra (di solito la schermata); null = sopra a tutto.
static func ask(host: Node) -> ConfirmBox:
	var tree: SceneTree = host.get_tree() if host != null else Engine.get_main_loop() as SceneTree
	if tree == null or is_open(tree):
		return null
	var parent: Node = host
	if parent == null:
		var fb: Node = tree.root.get_node_or_null("Feedback")
		parent = fb.safe_layer() if fb != null else null
	if parent == null:
		return null
	var box := ConfirmBox.ask(parent, "VUOI USCIRE?", func() -> void: quit(tree), "SI", "NO")
	box.add_to_group(GROUP)
	return box


static func quit(tree: SceneTree) -> void:
	if quit_function.is_valid():
		quit_function.call()
	else:
		tree.quit()
