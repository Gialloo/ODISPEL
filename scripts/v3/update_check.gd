class_name UpdateCheck
extends HTTPRequest

# AGGIORNAMENTI: all'avvio chiede a itch.io qual e' l'ultima versione caricata sul canale di questa piattaforma.
# Se e' piu' nuova di quella in uso, il menu mostra un pulsante che apre la pagina del download.
# Dalla 0.33.0 l'APK ha una chiave di firma stabile: l'aggiornamento si installa sopra, senza disinstallare.
# Senza rete o con una risposta strana non succede niente: il gioco non deve mai bloccarsi per questo.
# Dalla 0.34.1 legge prima la versione dal repository pubblico (branch dei rilasci): la pagina itch e' protetta
# da password e la sua API risponde "invalid game", quindi da sola non trovava mai l'aggiornamento.

signal found(version: String)

const PAGE: String = "https://boomeranza.itch.io/odispel"
const SOURCE: String = "https://raw.githubusercontent.com/gialloo/odispel/claude/v3-prologo/scripts/v3/game_config.gd"
const API: String = "https://itch.io/api/1/x/wharf/latest?target=boomeranza/odispel&channel_name=%s"


static func channel() -> String:
	return "android-v3" if OS.get_name() == "Android" else "windows-v3"


func _ready() -> void:
	timeout = 6.0
	request_completed.connect(_done)
	if request(SOURCE) != OK:
		_itch()


var _asked_itch: bool = false


# riserva: l'API di itch, che funziona solo se la pagina del gioco e' pubblica
func _itch() -> void:
	_asked_itch = true
	if request(API % channel()) != OK:
		queue_free()


func _done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and not _asked_itch:
		var latest_src: String = version_in(body.get_string_from_utf8())
		if latest_src != "":
			if newer(latest_src, GameConfig.VERSION):
				found.emit(latest_src)
			queue_free()
			return
	if not _asked_itch:
		_itch.call_deferred()
		return
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var data: Variant = JSON.parse_string(body.get_string_from_utf8())
		if data is Dictionary and data.has("latest"):
			var latest: String = str(data["latest"]).strip_edges()
			if newer(latest, GameConfig.VERSION):
				found.emit(latest)
	queue_free()


# trova const VERSION: String = "x.y.z" nel sorgente di game_config.gd
static func version_in(src: String) -> String:
	var re := RegEx.new()
	re.compile('const VERSION: String = "([0-9.]+)"')
	var m := re.search(src)
	return m.get_string(1) if m else ""


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
