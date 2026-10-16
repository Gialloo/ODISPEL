from lib import *

H_ = []


def addh(code, id_, name, visual, fn, variants=None):
    H_.append((code, id_, name, visual, fn, variants or {}))


# ---------- FAMIGLIA H: roster, equipaggiamento, progressione
def new_op(b):
    person(b, -1, 1, 0.9)
    star4(b, 12, -3, 0.5)
addh("H01", "p_new_operator", "Nuovo operatore", "sagoma con stella nell'angolo", new_op)
def dup(b):
    person(b, -3, 0, 0.85)
    person(b, 5, 3, 0.85)
addh("H02", "p_duplicate", "Duplicato", "due sagome sovrapposte", dup)
def recruit(b):
    b.arc((12, 12), 10, -60, 240)
    b.arc((12, 12), 6.5, 20, 320, sw=SW_THIN)
    core(b, 0, 0, 1, "solid", 2.2)
addh("H03", "p_recruit", "Reclutamento", "due anelli che si aprono verso un nucleo", recruit)
def upgrade(b):
    b.poly([(4, 8), (16, 8), (16, 12), (4, 12)], "soft")
    b.line((10, 12), (10, 22))
    spark(b, 12, -3, 0.5)
addh("H04", "p_upgrade", "Potenziamento", "martello geometrico con scintilla", upgrade)
def rank(b):
    for y in (5, 11, 17):
        b.polyline([(4, y + 5), (12, y - 1), (20, y + 5)])
    spark(b, 8.5, -4, 0.3)
addh("H05", "p_rank", "Ascensione / Rango", "chevron sovrapposti con punta luminosa", rank)
def materials(b):
    b.poly([(3, 11), (9, 5), (13, 12), (7, 17)], "soft")
    b.poly([(12, 4), (20, 6), (18, 13), (13, 11)], "soft")
    b.poly([(11, 15), (19, 15), (16, 21), (10, 21)], "soft")
addh("H06", "p_materials", "Materiali", "tre frammenti geometrici", materials)
def common(b):
    b.circle((12, 12), 9.5, "soft")
    b.circle((12, 12), 6, None, SW_THIN)
    b.line((12, 9), (12, 15), SW_THIN)
addh("H07", "p_currency_common", "Valuta comune", "gettone inciso", common)
def rare(b):
    b.poly([(7, 3), (17, 3), (22, 10), (12, 22), (2, 10)], "soft")
    b.line((2, 10), (22, 10), SW_THIN)
    b.polyline([(7, 3), (9, 10), (12, 22), (15, 10), (17, 3)], SW_THIN)
addh("H08", "p_currency_rare", "Valuta rara", "cristallo sfaccettato", rare)
def reward(b):
    b.poly([(3, 12), (21, 12), (21, 21), (3 , 21)], "soft")
    b.polyline([(3, 12), (4, 6), (20, 6), (21, 12)])
    spark(b, 7, -3, 0.5)
addh("H09", "p_reward_ready", "Ricompensa disponibile", "scrigno aperto con luce", reward)
def reward_done(b):
    b.poly([(3, 8), (21, 8), (21, 21), (3, 21)], "soft")
    b.line((3, 12), (21, 12), SW_THIN)
    check(b, 7.5, 9, 0.4)
addh("H10", "p_reward_claimed", "Ricompensa riscattata", "scrigno con spunta", reward_done)
def new_item(b):
    b.poly([(2, 4), (14, 4), (22, 12), (14, 20), (2, 20)], "soft")
    b.circle((7, 12), 1.5, "solid")
    spark(b, 12, -4, 0.4)
addh("H11", "p_item_new", "Oggetto nuovo", "etichetta geometrica con scintilla", new_item)
def equipped(b):
    hexagon(b, 0, 0, 1, "soft")
    b.polyline([(8, 12), (11, 12), (11, 9), (14, 9), (14, 15), (11, 15), (11, 12)], SW_THIN)
addh("H12", "p_equipped", "Equipaggiato", "esagono con incastro completato", equipped)
def inv_full(b):
    b.polyline([(3, 8), (3, 21), (21, 21), (21, 8)])
    b.polyline([(3, 8), (9, 8)])
    b.polyline([(15, 8), (21, 8)])
    b.polyline([(10, 3), (9, 8), (13, 10), (12, 15)], SW_THIN)
addh("H13", "p_inventory_full", "Inventario pieno", "contenitore con bordo spezzato", inv_full)
def title(b):
    b.poly([(6, 2), (18, 2), (18, 15), (12, 21), (6, 15)], "soft")
    seal(b, 3.4)
addh("H14", "p_title_earned", "Titolo ottenuto", "nastro con sigillo", title)
def milestone(b):
    star4(b, 5, 3, 0.55)
    b.line((3, 19), (9, 13))
    b.line((12, 22), (12, 15))
    b.line((21, 19), (15, 13))
addh("H15", "p_milestone", "Traguardo", "tre tacche che convergono verso una stella", milestone)
def rarity(b):
    diamond(b, 0, 0, 1, "soft")
    b.line((3, 12), (21, 12), SW_THIN)
    b.line((12, 2), (12, 22), SW_THIN)
addh("H16", "p_rarity", "Rarita'", "diamante con tagli crescenti (il numero dei tagli e' dato dall'interfaccia)", rarity)
def level(b):
    b.polyline([(4, 17), (12, 7), (20, 17)], 2.4)
addh("H17", "p_level", "Livello", "chevron ascendente", level)
def xp(b):
    b.poly([(3, 9), (21, 9), (21, 15), (3, 15)], None)
    for x in (5, 9, 13):
        b.poly([(x, 10.5), (x + 3, 10.5), (x + 3, 13.5), (x, 13.5)], "solid")
addh("H18", "p_xp", "Esperienza", "barra segmentata che si riempie", xp)
add_stats = []
addh("H19", "stat_atk", "Attacco (statistica)", "lama verticale", blade_v)
def stat_def(b):
    shield(b)
addh("H20", "stat_def", "Difesa (statistica)", "scudo esagonale", stat_def)
def stat_spd(b):
    arrow_right(b, 5, 0, 0.7)
    b.line((2, 8), (8, 8))
    b.line((2, 16), (8, 16))
addh("H21", "stat_spd", "Velocita' (statistica)", "doppia scia", stat_spd)
addh("H22", "stat_acc", "Precisione (statistica)", "mirino", lambda b: crosshair(b))
addh("H23", "stat_crit", "Critico (statistica)", "stella tagliente", lambda b: star4(b))
def stat_res(b):
    ring(b, (12, 12), 9.5)
    core(b, 0, 0, 1, "solid", 3)
addh("H24", "stat_resource", "Risorsa (statistica)", "nucleo dentro un anello", stat_res)
def skill_on(b):
    star4(b, 0, 0, 1, "soft")
    b.dot((3, 20), 1.2)
    b.dot((21, 20), 1.2)
    b.dot((12, 22), 0.01)
addh("H25", "skill_unlocked", "Abilita' sbloccata", "stella con nodi", skill_on)
def skill_locked(b):
    lock(b)
    b.poly([(12, 12.5), (13.4, 15.5), (12, 18.5), (10.6, 15.5)], "solid")
addh("H26", "skill_locked", "Abilita' bloccata", "lucchetto con simbolo interno", skill_locked)
def skill_avail(b):
    b.arc((12, 12), 9.5, -45, 255)
    spark(b, 7.5, 7.5, 0.37)
addh("H27", "skill_available", "Abilita' disponibile", "anello aperto con scintilla", skill_avail)
def equipment(b):
    b.poly([(2, 7), (11, 7), (11, 11), (8, 11), (8, 17), (2, 17)], "soft")
    b.poly([(22, 7), (13, 7), (13, 12), (15, 12), (15, 17), (22, 17)], "soft")
addh("H28", "p_equipment", "Equipaggiamento", "due forme che si incastrano", equipment)
def inventory(b):
    hexagon(b, 0, 0, 1, "soft")
    hexagon(b, 6, 6, 0.5)
addh("H29", "p_inventory", "Inventario", "contenitore esagonale", inventory)
def recruit_avail(b):
    portal_b(b)
def portal_b(b):
    b.polyline([(6, 22), (3, 8), (6, 4), (12, 2)])
    b.polyline([(18, 22), (21, 12), (18, 5)])
    core(b, 0, 0, 1, "solid", 2.6)
addh("H30", "p_recruit_available", "Reclutamento disponibile", "portale con nucleo luminoso", recruit_avail)
def registry(b):
    b.poly([(2, 5), (11, 7), (11, 21), (2, 19)], "soft")
    b.poly([(22, 5), (13, 7), (13, 21), (22, 19)], "soft")
addh("H31", "p_registry", "Registro", "libro aperto", registry)
addh("H32", "p_titles", "Titoli", "nastro con sigillo", title)

# ---------- FAMIGLIA I: interfaccia
I_ = []


def addi(code, id_, name, visual, fn, variants=None):
    I_.append((code, id_, name, visual, fn, variants or {}))


addi("I01", "ui_settings", "Impostazioni", "ingranaggio essenziale", gear)
def audio(b):
    b.line((4, 12), (4, 12.01))
    for x, h in ((5, 2), (9, 5), (13, 8), (17, 5), (21, 2)):
        b.line((x, 12 - h), (x, 12 + h))
addi("I02", "ui_audio", "Audio", "onda sonora a tre linee", lambda b: [b.line((x, 12 - h), (x, 12 + h)) for x, h in ((6, 3), (12, 8), (18, 3))])
def music(b):
    ring(b, (12, 12), 10)
    b.line((14, 6.5), (14, 15))
    b.polyline([(14, 6.5), (17.5, 8.5)])
    b.circle((11.5, 15.5), 2.6, "solid")
addi("I03", "ui_music", "Musica", "nota geometrica dentro un anello", music)
def speaker(b, off=False):
    b.poly([(2, 9), (7, 9), (13, 4), (13, 20), (7, 15), (2, 15)], "soft")
    if off:
        b.line((16, 9), (22, 15))
        b.line((22, 9), (16, 15))
    else:
        b.arc((13, 12), 5, -50, 50)
        b.arc((13, 12), 9, -50, 50)
addi("I04", "ui_volume", "Volume", "altoparlante con onda", speaker)
addi("I05", "ui_mute", "Muto", "altoparlante barrato", lambda b: speaker(b, True))
def corners(b, k=1.0, inward=False):
    for sx in (-1, 1):
        for sy in (-1, 1):
            d = 4 if inward else 9
            cx, cy = 12 + sx * d, 12 + sy * d
            L = 5 if not inward else -5
            b.polyline([(cx - sx * L, cy), (cx, cy), (cx, cy - sy * L)])
addi("I06", "ui_fullscreen", "Schermo intero", "quattro angoli direzionali attorno a uno schermo", lambda b: (corners(b), b.poly([(9, 9.5), (15, 9.5), (15, 14.5), (9, 14.5)], "soft", True, 1.5)))
def back(b):
    b.polyline([(15, 4), (6, 12), (15, 20)], 2.6)
addi("I07", "ui_back", "Torna indietro", "freccia angolare a sinistra", back)
addi("I08", "ui_close", "Chiudi", "X geometrica", xmark)
def confirm(b):
    check(b, 0, 0, 1)
addi("I09", "ui_confirm", "Conferma", "spunta geometrica", confirm)
def undo(b):
    b.arc((12, 13), 8, 200, 20 + 360 - 40, arrow=False)
    b.poly([(2, 8), (9, 6), (7, 13)], "solid")
addi("I10", "ui_cancel", "Annulla", "freccia circolare di ritorno", lambda b: (b.arc((13, 13), 8, 220, 400), b.poly([(5, 3), (10, 9), (3, 11)], "solid")))
addi("I11", "ui_help", "Aiuto", "punto interrogativo geometrico", lambda b: (b.polyline([(7, 8), (7, 5), (10, 3), (14, 3), (17, 5), (17, 9), (12, 13), (12, 15.5)]), b.poly([(11, 18), (13, 18), (13, 20), (11, 20)], "solid")))
def info(b):
    ring(b, (12, 12), 10)
    b.line((12, 10.5), (12, 17))
    b.poly([(11, 6.5), (13, 6.5), (13, 8.5), (11, 8.5)], "solid")
addi("I12", "ui_info", "Informazioni", "lettera i dentro un cerchio", info)
def search(b):
    b.circle((10, 10), 6.5)
    b.line((15, 15), (21, 21))
    b.dot((10, 10), 1.4)
addi("I13", "ui_search", "Ricerca", "lente con punto centrale", search)
def filt(b):
    b.polyline([(3, 5), (21, 5), (14, 13), (14, 20), (10, 18), (10, 13), (3, 5)])
addi("I14", "ui_filter", "Filtro", "tre linee convergenti", lambda b: (b.line((3, 6), (21, 6)), b.line((6, 12), (18, 12)), b.line((10, 18), (14, 18))))
addi("I15", "ui_sort", "Ordina", "tre linee di lunghezza decrescente", lambda b: (b.line((3, 6), (21, 6)), b.line((3, 12), (15, 12)), b.line((3, 18), (9, 18))))
def open_detail(b):
    b.polyline([(10, 4), (3, 4), (3, 21), (20, 21), (20, 14)])
    b.line((11, 13), (21, 3))
    b.polyline([(14, 3), (21, 3), (21, 10)])
addi("I16", "ui_open_detail", "Apri dettaglio", "cornice con freccia diagonale", open_detail)
addi("I17", "ui_expand", "Espandi", "quattro angoli che si allontanano", lambda b: corners(b))
addi("I18", "ui_collapse", "Comprimi", "quattro angoli convergenti", lambda b: corners(b, 1, True))
def bell(b):
    b.poly([(12, 3), (18, 9), (18, 15), (21, 18), (3, 18), (6, 15), (6, 9)], "soft")
    b.poly([(9.5, 20), (14.5, 20), (12, 22.5)], "solid")
addi("I19", "ui_notify", "Notifica", "campanella geometrica", bell)
def new_content(b):
    diamond(b, 0, 0, 1, None)
    b.dot((12, 12), 2.4)
addi("I20", "ui_new", "Nuovo contenuto", "punto luminoso dentro un rombo", new_content)
addi("I21", "ui_connection", "Connessione", "nodi collegati", lambda b: n2i(b, False))
def n2i(b, broken):
    for p in ((4, 17), (12, 6), (20, 17)):
        b.circle(p, 2.8, "soft")
    if broken:
        b.line((6.5, 14.5), (8.5, 11.5), SW_THIN)
        b.line((15.5, 11.5), (17.5, 14.5), SW_THIN)
        b.line((8, 17), (9.5, 17), SW_THIN)
        b.line((14.5, 17), (16, 17), SW_THIN)
    else:
        b.line((6.5, 14.5), (9.8, 8.5))
        b.line((14.2, 8.5), (17.5, 14.5))
        b.line((7, 17), (17, 17))
addi("I22", "ui_connection_unstable", "Connessione instabile", "nodi con linea spezzata", lambda b: n2i(b, True))
def download(b):
    arrow_down(b, 0, -2, 0.85)
    b.line((3, 21), (21, 21))
addi("I23", "ui_download", "Download / Installazione", "freccia verso una base", download)
def save(b):
    b.poly([(3, 3), (17, 3), (21, 7), (21, 21), (3, 21)], "soft")
    b.poly([(7, 3), (15, 3), (15, 9), (7, 9)], None, True, SW_THIN)
    b.poly([(7, 21), (7, 14), (17, 14), (17, 21)], None, True, SW_THIN)
addi("I24", "ui_save", "Salvataggio", "disco stilizzato", save)
def err(b):
    b.poly([(12, 3), (22, 20.5), (2, 20.5)], "soft")
    b.line((9, 12), (15, 18), SW_THIN)
    b.line((15, 12), (9, 18), SW_THIN)
addi("I25", "ui_error", "Errore", "X dentro un triangolo", err)
def warn(b):
    b.poly([(12, 3), (22, 20.5), (2, 20.5)], "soft")
    b.line((12, 9), (12, 14.5))
    b.dot((12, 17.4), 1.2)
addi("I26", "ui_warning", "Avviso", "punto esclamativo dentro un triangolo", warn)
def success(b):
    ring(b, (12, 12), 10)
    check(b, 6.5, 6.5, 0.45)
addi("I27", "ui_success", "Successo", "spunta dentro un cerchio", success)
addi("I28", "ui_locked", "Bloccato", "lucchetto", lambda b: lock(b))
addi("I29", "ui_visible", "Visibile", "occhio aperto", lambda b: eye(b))
def hidden(b):
    eye(b)
    b.line((4, 21), (20, 3))
addi("I30", "ui_hidden", "Nascosto", "occhio barrato", hidden)
addi("I31", "ui_chat", "Chat", "fumetto", lambda b: bubble(b))
addi("I32", "ui_menu", "Menu", "tre linee geometriche", lambda b: (b.line((3, 6), (21, 6)), b.line((3, 12), (21, 12)), b.line((3, 18), (21, 18))))
addi("I33", "ui_pause", "Pausa", "due barre verticali", lambda b: (b.poly([(6, 4), (10, 4), (10, 20), (6, 20)], "solid"), b.poly([(14, 4), (18, 4), (18, 20), (14, 20)], "solid")))
addi("I34", "ui_play", "Riprendi", "triangolo direzionale", lambda b: b.poly([(6, 3), (20, 12), (6, 21)], "solid"))
def restart(b):
    b.arc((12, 12), 8.5, -60, 250)
    b.poly([(4, 3), (11, 4), (5.5, 10)], "solid")
addi("I35", "ui_restart", "Riavvia", "freccia circolare", restart)
def exit_(b):
    b.polyline([(10, 3), (3, 3), (3, 21), (10, 21)])
    arrow_right(b, 6, 0, 0.7)
addi("I36", "ui_exit", "Esci", "porta geometrica con freccia uscente", exit_)

# ---------- FAMIGLIA L: identita' ODISPEL
L_ = []


def addl(code, id_, name, visual, fn, variants=None):
    L_.append((code, id_, name, visual, fn, variants or {}))


def odic(b):
    b.arc((12, 12), 9.5, -50, 270)
    b.polyline([(15, 2), (9, 10), (14.5, 12), (8.5, 22)], 3.0)
addl("L01", "od_force", "Forza Odica", "anello incompleto attraversato da una fenditura (magenta nel gioco)", odic)
def monad(b):
    core(b, 0, 0, 1, "solid", 3.4)
    b.arc((12, 12), 8.5, -30, 120)
    b.arc((12, 12), 8.5, 150, 330)
    for a in (-30, 150):
        r = math.radians(a)
        b.dot((12 + 8.5 * math.cos(r), 12 + 8.5 * math.sin(r)), 1.4)
addl("L02", "od_monad", "Monade", "nucleo con anello orbitale interrotto", monad)
def trace(b):
    b.arc((12, 12), 9.5, 90, 340)
    b.dot((12, 21.5), 1.4)
    b.poly([(20.5, 6), (17.5, 4), (19, 9)], "solid")
addl("L03", "od_trace", "Traccia", "percorso circolare che si interrompe prima di chiudersi", trace)
def ignition(b):
    b.arc((12, 12), 10, 20, 150)
    b.arc((12, 12), 10, 190, 320)
    b.poly([(15, 1.5), (6, 13), (11.5, 13), (8.5, 22.5), (19, 9), (13, 9)], "solid")
addl("L04", "od_ignition", "Ignition Overdrive", "fulmine angolare che spezza un anello", ignition)
def rupture(b):
    b.poly([(12, 3), (21, 12), (12, 21), (3, 12)], "soft")
    b.line((12, 3), (12, 21))
    b.poly([(11, 6), (13, 6), (13, 18), (11, 18)], "solid")
addl("L05", "od_rupture", "Rottura rituale", "nucleo geometrico aperto da una frattura verticale", rupture)
def energy_full(b):
    ring(b, (12, 12), 9.5)
    for i in range(4):
        a0 = -90 + i * 90 + 8
        b.arc((12, 12), 5.5, a0, a0 + 74, sw=3.4)
addl("L06", "od_energy", "Energia accumulata", "nucleo con segmenti progressivamente riempiti", energy_full)
def energy_empty(b):
    b.arc((12, 12), 9.5, -70, 250)
    b.arc((12, 12), 5, -60, 60, sw=SW_THIN)
addl("L07", "od_energy_empty", "Energia esaurita", "nucleo vuoto con bordo interrotto", energy_empty)
def sigil(b):
    for i in range(4):
        a0 = i * 90 + 12
        b.arc((12, 12), 9.5, a0, a0 + 66)
    b.dot((12, 12), 1.4)
addl("L08", "od_seal", "Sigillo", "anello geometrico con quattro interruzioni regolari", sigil)
def anomaly(b):
    ring(b, (11, 11), 7)
    b.circle((19, 18), 1.8, "solid")
addl("L09", "od_anomaly", "Anomalia", "cerchio centrale con un punto spostato fuori asse", anomaly)
def void(b):
    b.arc((12, 12), 9.5, -70, 250, sw=2.4)
    b.circle((12, 12), 6.5, "soft")
    b.dot((15, 9), 1.0)
addl("L10", "od_void", "Vuoto", "nucleo scuro con contorno spezzato e un piccolo punto pallido", void)
def bond(b):
    b.circle((5, 17), 3.4, "soft")
    b.circle((19, 7), 3.4, "soft")
    b.polyline_arc([(5 + 14 * t, 17 - 10 * t - 7 * math.sin(math.pi * t)) for t in [i / 10 for i in range(11)]])
addl("L11", "od_bond", "Legame rituale", "due nuclei collegati da una linea curva", bond)
def dimension(b):
    b.poly([(2, 4), (10, 2), (10, 14), (2, 16)], "soft")
    b.poly([(14, 10), (22, 8), (22, 22), (14, 22)], "soft")
    b.polyline([(12, 1), (10.5, 8), (13.5, 14), (12, 23)], SW_THIN)
addl("L12", "od_dimension", "Frattura dimensionale", "due piani geometrici separati da una fenditura", dimension)
