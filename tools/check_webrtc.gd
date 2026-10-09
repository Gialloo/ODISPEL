extends SceneTree

func _initialize() -> void:
    print("=== ODISPEL WEBRTC API CHECK ===")

    var peer = ClassDB.instantiate("WebRTCMultiplayerPeer")
    print("Istanza creata: ", peer != null)

    if peer != null:
        print("create_mesh: ", peer.has_method("create_mesh"))
        print("create_client: ", peer.has_method("create_client"))
        print("create_server: ", peer.has_method("create_server"))
        print("add_peer: ", peer.has_method("add_peer"))
        print("remove_peer: ", peer.has_method("remove_peer"))
        print("get_peer: ", peer.has_method("get_peer"))
        print("get_peers: ", peer.has_method("get_peers"))

    peer = null
    print("Controllo API completato.")
    quit()
