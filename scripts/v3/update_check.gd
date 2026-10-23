class_name UpdateCheck
extends HTTPRequest

# AGGIORNAMENTI: all'avvio chiede a itch.io qual e' l'ultima versione caricata sul canale di questa piattaforma.
# Se e' piu' nuova di quella in uso, il menu mostra un pulsante che apre la pagina del download.
# Dalla 0.33.0 l'APK ha una chiave di firma stabile: l'aggiornamento si installa sopra, senza disinstallare.
# Senza rete o con una risposta strana non succede niente: il gioco non deve mai bloccarsi per questo.

signal found(version: String)

const PAGE: String = "https://boomeranza.itch.io/odispel"
const API: String = "https://itch.io/api/1/x/wharf/latest?target=boomeranza/odispel&channel_name=%s"


static func channel() -> String:
	return "android-v3" if OS.get_name() == "Android" else "windows-v3"


func _ready() -> void:
	timeout = 6.0
	request_completed.connect(_done)
	if request(API % channel()) != OK:
		queue_free()


func _done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var data: Variant = JSON.parse_string(body.get_string_from_utf8())
		if data is Dictionary and data.has("latest"):
			var latest: String = str(data["latest"]).strip_edges()
			if newer(latest, GameConfig.VERSION):
				found.emit(latest)
	queue_free()


# "0.33.2" e' piu' nuova di "0.33.1"; confronta numero per numero
static func newer(a: String, b: String) -> bool:
	var pa: PackedStringArray = a.split(".")
	var pb: PackedStringArray = b.split(".")
	for i in maxi(pa.size(), pb.size()):
		var x: int = int(pa[i]) if i < pa.size() else 0
		var y: int = int(pb[i]) if i < pb.size() else 0
		if x != y:
			return x > y
	return false
