extends SceneTree

func _initialize() -> void:
	print("=== ODISPEL NATIVE WEBRTC API ===")

	var peer = ClassDB.instantiate("WebRTCLibPeerConnection")
	print("Peer creato: ", peer != null)

	if peer != null:
		print("Segnali disponibili:")
		for signal_info in peer.get_signal_list():
			print(" - ", signal_info.name)

		print("Metodi rilevanti:")
		for method_info in peer.get_method_list():
			var method_name: String = method_info.name
			if (
				"data_channel" in method_name
				or "remote_description" in method_name
				or "ice_candidate" in method_name
				or "create_answer" in method_name
			):
				print(" - ", method_name)

	peer = null
	quit()
