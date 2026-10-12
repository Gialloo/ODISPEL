class_name StoryData
extends RefCounted

# Le scene di storia incluse nel gioco. Per cambiarle senza toccare il codice basta
# creare un file `<id>.txt` nella cartella `dialogues` accanto all'eseguibile (o in
# user://dialogues): ha la precedenza su queste. Formato in dialogue_script.gd.

const SCENES: Dictionary = {
	"distributore_pre": """
@bg strada_notte
*: CAM-07, Via S. Giorgio. Notte. Il parcheggio di Park 3 e' deserto. Quasi.
kira [neutral] L: Segnale confermato. Il distributore del piano terra si e' acceso da solo.
dax [angry] R: Un distributore. Mi hai trascinato fin qui per un distributore.
kira [happy]: Mangia la polvere e dimmi che non e' strano che lo faccia anche lui.
elle [surprised] L: Dax... guarda il display. Non dice ESAURITO. Dice il tuo nome.
dax [surprised]: ...
distributore: BZZZ. SCARICA. SCARICA. SCARICA.
kira [angry]: Squadra, formazione. E' una anomalia di classe bassa. Non lasciamolo scaricare niente.
""",
	"distributore_post": """
@bg strada_notte
*: Il distributore si spegne con un ultimo ronzio. Dal vetro cadono monete e qualcosa che somiglia a un nucleo.
elle [happy] L: Abbiamo i nuclei. Ora possiamo potenziare la squadra.
dax [neutral] R: Resta il fatto che mi ha chiamato per nome.
kira [neutral] L: Non e' la prima anomalia che parla. Ma e' la prima che sa chi siamo.
> Indaghiamo subito -> indaga
> Prima riposiamo -> riposa
:indaga
kira [angry]: Allora andiamo a cercarla. C'e' un incrocio, poco lontano, dove i semafori fanno cose strane.
@goto fine
:riposa
elle [happy]: Dieci minuti. Poi si va all'incrocio: i semafori stanno impazzendo.
:fine
dax [neutral] R: Va bene. Ma stavolta guido io.
""",
	"semaforo_pre": """
@bg incrocio
*: L'incrocio di Via S. Giorgio. Il semaforo cambia colore ogni secondo, senza ritmo.
elle [sad] L: Le auto si fermano a caso. Qualcuno si fara' male.
semaforo [angry] R: ROSSO. ROSSO. NESSUNO PASSA.
kira [surprised]: Ha parlato. Bruno, tu che ne dici?
bruno [neutral] L: Che segue uno schema. Rosso e' un colpo solo, verde colpisce tutti, giallo si ricarica.
kira [happy]: Allora lo leggiamo. Segnale e telegrafo: e' esattamente il nostro lavoro.
semaforo [angry] R: GIALLO. ATTENDERE.
""",
	"semaforo_post": """
@bg incrocio
*: Il semaforo si spegne. Per la prima volta in ore, la strada e' silenziosa.
bruno [happy] L: Schema decifrato. E non e' stato nemmeno difficile.
elle [neutral] R: C'e' ancora qualcosa. Sento acqua, sotto di noi.
dax [surprised] L: Il tombino. Si sta muovendo.
""",
	"tombino_pre": """
@bg tombino
*: Sotto il coperchio del tombino, qualcosa respira.
kira [neutral] L: Questa e' la fonte. Tutte le anomalie partivano da qui.
tombino [angry] R: ...HO FAME. ...HO FREDDO.
elle [sad] L: Non e' cattivo. E' solo... dimenticato.
> Lo combattiamo comunque -> combatti
> Proviamo a parlargli -> parla
:parla
elle [sad]: Come ti chiami?
tombino [sad] R: NESSUNO LO RICORDA PIU'.
kira [neutral] L: Allora ti ricorderemo noi. Ma prima devi fermarti.
@goto fine
:combatti
dax [angry] L: Non c'e' tempo. Sta salendo.
:fine
tombino [angry] R: ...AVVICINATI.
""",
	"tombino_post": """
@bg tombino
*: L'acqua si ritira. Il coperchio si richiude piano, senza rumore.
elle [happy] L: Se ne e' andato. Credo che ora dorma.
kira [happy] R: Rapporto finale: tre anomalie neutralizzate, nessuna perdita.
dax [neutral] L: Per stavolta.
bruno [surprised] R: Per stavolta? Dax, hai visto le altre telecamere?
*: Sul monitor, un'altra luce si accende. CAM-08.
""",
}


# Testo di una scena: prima i file dell'utente, poi quelli inclusi.
static func text(scene_id: String) -> String:
	var loop: MainLoop = Engine.get_main_loop()
	var folders: Array = [
		OS.get_executable_path().get_base_dir().path_join("dialogues"),
		ProjectSettings.globalize_path("user://dialogues"),
	]
	for f in folders:
		var path: String = str(f).path_join(scene_id + ".txt")
		if FileAccess.file_exists(path):
			return FileAccess.get_file_as_string(path)
	return str(SCENES.get(scene_id, ""))


static func has_scene(scene_id: String) -> bool:
	return text(scene_id) != ""
