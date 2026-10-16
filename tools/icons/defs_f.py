from lib import *

F_ = []


def add(code, id_, name, visual, fn, variants=None):
    F_.append((code, id_, name, visual, fn, variants or {}))


def n2(b, broken=False):
    b.circle((5, 12), 3, "soft")
    b.circle((19, 12), 3, "soft")
    if broken:
        b.line((8.2, 12), (10.5, 12))
        b.line((13.5, 12), (15.8, 12))
        b.polyline([(11, 8.5), (13, 15.5)], SW_THIN)
    else:
        b.line((8, 12), (16, 12))


# ---------- FAMIGLIA F: multiplayer
def host(b):
    core(b, 0, 0, 1, "solid", 3)
    ring(b, (12, 12), 8.5)
add("F01", "net_host", "Ospitante", "nodo centrale con anello", host)
add("F02", "net_connected", "Giocatore connesso", "due nodi uniti da linea continua", n2)
add("F03", "net_unstable", "Connessione instabile", "linea spezzata tra due nodi", lambda b: n2(b, True))
def sync(b):
    b.circle((8.5, 12), 6.5)
    b.circle((15.5, 12), 6.5)
    b.arc((12, 12), 10.8, 300, 360 + 40, arrow=True, sw=SW_THIN)
add("F04", "net_sync", "Sincronizzazione", "due anelli sovrapposti", sync)
def waiting(b):
    b.arc((12, 12), 10, -60, 230)
    hourglass(b, 6.5, 6.5, 0.45)
add("F05", "net_waiting", "In attesa", "cerchio incompleto con clessidra", waiting)
def sent(b):
    ring(b, (12, 12), 9.5)
    arrow_right(b, 6, 6, 0.5)
add("F06", "net_sent", "Azione inviata", "freccia dentro un nodo", sent)
def confirmed(b):
    ring(b, (12, 12), 9.5)
    check(b, 6.5, 6.5, 0.45)
add("F07", "net_confirmed", "Azione confermata", "spunta dentro un nodo", confirmed)
def ally_off(b):
    b.circle((12, 12), 3.4, "soft")
    b.line((2, 12), (6.5, 12), SW_THIN)
    b.line((17.5, 12), (22, 12), SW_THIN)
    b.polyline([(15, 4), (17, 8)], SW_THIN)
    b.polyline([(7, 20), (9, 16)], SW_THIN)
    b.line((4, 21), (20, 3), SW_THIN)
add("F08", "net_ally_off", "Alleato disconnesso", "nodo isolato con linea spezzata", ally_off)
def rejoin(b):
    b.arc((12, 12), 9.5, 110, 400, arrow=True)
    core(b, 0, 0, 1, "solid", 3)
add("F09", "net_rejoin", "Rientro in partita", "freccia circolare diretta verso un nodo", rejoin)
def ready(b):
    hexagon(b, 0, 0, 1, "soft")
    check(b, 6.5, 6.5, 0.45)
add("F10", "net_ready", "Pronto al combattimento", "spunta dentro una cornice esagonale", ready)
def team_syn(b):
    for p in ((4, 17), (20, 17), (12, 4)):
        b.circle(p, 2.6, "soft")
        b.line(p, (12, 12.5), SW_THIN)
    b.dot((12, 12.5), 1.6)
add("F11", "net_team_synergy", "Sinergia di squadra", "tre nodi convergenti", team_syn)
def quick(b):
    bubble(b, 0, 0, 1)
    arrow_right(b, 5, -4, 0.5)
add("F12", "net_quick_chat", "Comunicazione rapida", "fumetto con freccia", quick)
def ally_turn(b):
    b.polyline([(2, 8), (2, 2), (8, 2)])
    b.polyline([(16, 2), (22, 2), (22, 8)])
    b.polyline([(22, 16), (22, 22), (16, 22)])
    b.polyline([(8, 22), (2, 22), (2, 16)])
    person(b, 3.5, 3, 0.65)
    b.dot((19, 5), 1.3)
add("F13", "net_ally_turn", "Turno dell'alleato", "ritratto con cornice angolare", ally_turn)
def ally_wait(b):
    b.circle((12, 6), 3.4, "soft")
    hourglass(b, 6, 9, 0.5)
add("F14", "net_ally_waiting", "Azione dell'alleato in attesa", "nodo con clessidra", ally_wait)
def sync_err(b):
    b.circle((6.5, 9), 5.5)
    b.circle((17.5, 15), 5.5)
    b.line((12, 8.5), (12, 13), SW_THIN)
    b.dot((12, 16), 0.9)
add("F15", "net_sync_error", "Errore di sincronizzazione", "due anelli disallineati", sync_err)
def over(b):
    ring(b, (12, 12), 9.5)
    seal(b, 5)
add("F16", "net_match_over", "Partita terminata", "anello chiuso con sigillo", over)
def win(b):
    for x in (5, 12, 19):
        person(b, x - 6, 8, 0.5)
    check(b, 6, -2, 0.5)
add("F17", "net_victory", "Vittoria della squadra", "tre sagome con spunta centrale", win)
def lose(b):
    for x in (5, 12, 19):
        person(b, x - 6, 8, 0.5)
    b.polyline([(13, 1), (10.5, 5), (13.5, 8)], SW_THIN)
add("F18", "net_defeat", "Sconfitta della squadra", "tre sagome con frattura centrale", lose)
def invite(b):
    person(b, -1, 3, 0.7)
    person(b, 9, 3, 0.7)
    arrow_down(b, 6, -3, 0.4)
add("F19", "net_invite", "Invito alla squadra", "due sagome con freccia entrante", invite)
def leave(b):
    ring(b, (9, 12), 6)
    core(b, -3, 0, 1, "solid", 2.4)
    arrow_right(b, 9, 0, 0.62)
add("F20", "net_leave", "Abbandono della sessione", "nodo con freccia uscente", leave)

# ---------- FAMIGLIA G: esplorazione, hub, missioni
G_ = []


def addg(code, id_, name, visual, fn, variants=None):
    G_.append((code, id_, name, visual, fn, variants or {}))


def hand(b):
    b.poly([(7, 21), (4, 13), (6, 10), (9, 13), (9, 4), (12, 4), (12, 11), (15, 10), (15, 12), (18, 12), (19, 21)], "soft")
    b.dot((12.5, 16), 1.2)
addg("G01", "w_interact", "Interagisci", "mano geometrica con punto centrale", hand)
def dialog(b):
    person(b, -3, 2, 0.72)
    bubble(b, 9, -3, 0.55)
addg("G02", "w_dialog", "Dialogo", "sagoma con fumetto", dialog)
def portal(b):
    b.polyline([(7, 22), (4, 8), (7, 4), (13, 2)])
    b.polyline([(17, 22), (20, 12), (17, 5)])
    spark(b, 7.5, 7.5, 0.37)
addg("G03", "w_portal", "Portale", "cornice rituale spezzata da scintilla", portal)
def area_explore(b):
    b.poly([(2, 5), (9, 3), (15, 5), (22, 3), (22, 19), (15, 21), (9, 19), (2, 21)], None)
    b.line((9, 3), (9, 19), SW_THIN)
    b.line((15, 5), (15, 21), SW_THIN)
    b.dot((18.5, 9), 1.4)
addg("G04", "w_area_explore", "Area da esplorare", "mappa con punto fuori percorso", area_explore)
def poi(b):
    diamond(b, 0, 0, 1, "soft")
    eye(b, 6, 6, 0.5)
addg("G05", "w_poi", "Punto di interesse", "occhio dentro un rombo", poi)
def path_done(b):
    b.polyline([(3, 18), (9, 10), (14, 14), (19, 5)])
    b.dot((3, 18), 1.6)
    check(b, 11.5, 11, 0.45)
addg("G06", "w_path_done", "Percorso completato", "traccia chiusa con spunta", path_done)
def quest_main(b):
    ring(b, (12, 12), 10)
    ring(b, (12, 12), 6.5, SW_THIN)
    core(b, 0, 0, 1, "solid", 2.4)
addg("G07", "w_quest_main", "Missione principale", "sigillo grande con nucleo", quest_main)
def quest_side(b):
    ring(b, (12, 12), 7.5)
    b.line((12, 2.5), (12, 6.5), 1.6)
addg("G08", "w_quest_side", "Missione secondaria", "sigillo piccolo con una tacca", quest_side)
def daily(b):
    ring(b, (12, 17), 5)
    b.circle((12, 8), 2.4, "solid")
    for a in range(-170, -9, 32):
        r = math.radians(a)
        b.line((12 + 4.6 * math.cos(r), 8 + 4.6 * math.sin(r)), (12 + 7.2 * math.cos(r), 8 + 7.2 * math.sin(r)), SW_THIN)
addg("G09", "w_quest_daily", "Missione giornaliera", "sole geometrico sopra un anello", daily)
def event(b):
    b.polyline([(7, 22), (4, 8), (7, 4), (13, 2)])
    b.polyline([(17, 22), (20, 12), (17, 5)])
    spark(b, 14, -2, 0.4)
addg("G10", "w_event", "Evento", "portale con scintilla esterna", event)
def boss_target(b):
    crosshair(b, 0, 0, 1, False, 9.5)
    b.poly([(8, 8), (16, 8), (16, 13), (14, 16), (10, 16), (8, 13)], "soft")
    b.dot((10.5, 11), 1.1)
    b.dot((13.5, 11), 1.1)
addg("G11", "w_boss_target", "Boss da raggiungere", "teschio geometrico dentro un bersaglio", boss_target)
def extract(b):
    ring(b, (10, 12), 7.5)
    arrow_right(b, 9, 0, 0.62)
addg("G12", "w_extract", "Estrazione / Ritorno", "freccia verso l'esterno di un anello", extract)
def mapg(b):
    b.polyline([(2, 8), (2, 2), (9, 2)])
    b.polyline([(15, 2), (22, 2), (22, 9)])
    b.line((2, 12), (22, 12), SW_THIN)
    b.line((12, 2), (12, 22), SW_THIN)
    b.poly([(12, 14), (16, 18), (12, 22), (8, 18)], "solid")
    b.polyline([(2, 15), (2, 22), (6, 22)])
addg("G13", "w_map", "Mappa", "griglia spezzata con indicatore", mapg)
def checkpoint(b):
    b.line((6, 3), (6, 21))
    b.poly([(6, 4), (19, 7), (6, 12)], "soft")
    b.circle((6, 21), 1.6, "solid")
addg("G14", "w_checkpoint", "Checkpoint", "bandierina geometrica fissata a un nodo", checkpoint)
def hub(b):
    b.poly([(3, 21), (3, 9), (9, 4), (21, 4), (21, 21)], "soft")
    b.poly([(14, 8), (18, 8), (18, 12), (14, 12)], "solid")
    b.line((7, 21), (7, 14), SW_THIN)
addg("G15", "w_hub", "Hub", "edificio stilizzato con una finestra luminosa", hub)
def travel(b):
    b.circle((5, 17), 3, "soft")
    b.circle((19, 7), 3, "soft")
    b.line((7.2, 14.8), (16.8, 9.2))
addg("G16", "w_travel", "Punto di viaggio", "due punti collegati da una linea", travel)
def door_locked(b):
    b.polyline([(4, 22), (4, 3), (20, 3), (20, 22)])
    lock(b, 5, 6, 0.55)
    b.line((2, 22), (22, 22))
addg("G17", "w_door_locked", "Porta bloccata", "porta geometrica con lucchetto", door_locked)
def lens(b):
    b.circle((10, 10), 7)
    b.line((15, 15), (21, 21))
    b.circle((10, 10), 2.2, "solid")
addg("G18", "w_examine", "Oggetto esaminabile", "lente con un piccolo nucleo", lens)
def secret(b):
    diamond(b, 0, 0, 1)
    b.dot((12, 12), 1.5)
addg("G19", "w_secret", "Segreto", "rombo con punto nascosto al centro", secret)
def goal_done(b):
    seal(b, 10)
    check(b, 6, 6, 0.5)
addg("G20", "w_goal_done", "Obiettivo completato", "spunta dentro un sigillo", goal_done)
def goal_open(b):
    b.arc((12, 12), 9, -40, 270)
addg("G21", "w_goal_open", "Obiettivo incompleto", "cerchio aperto", goal_open)
def codex(b):
    b.poly([(2, 5), (11, 7), (11, 21), (2, 19)], "soft")
    b.poly([(22, 5), (13, 7), (13, 21), (22, 19)], "soft")
    b.push(8, -1, 0.5)
    b.poly([(12, 5), (19, 12), (12, 19), (5, 12)], "solid")
    b.pop()
addg("G22", "w_codex", "Registro / Codex", "libro aperto con simbolo centrale", codex)
def tutorial(b):
    b.polyline([(7, 8), (7, 5), (10, 3), (14, 3), (17, 5), (17, 9), (12, 13), (12, 15.5)])
    b.poly([(11, 18), (13, 18), (13, 20), (11, 20)], "solid")
addg("G23", "w_tutorial", "Tutorial", "punto interrogativo geometrico", tutorial)
def new_area(b):
    b.polyline([(14, 3), (3, 3), (3, 21), (14, 21)])
    b.polyline([(20, 3), (22, 3), (22, 6)], SW_THIN)
    b.polyline([(22, 18), (22, 21), (20, 21)], SW_THIN)
    arrow_right(b, 5, 0, 0.62)
addg("G24", "w_new_area", "Nuova area", "cornice aperta con freccia entrante", new_area)
