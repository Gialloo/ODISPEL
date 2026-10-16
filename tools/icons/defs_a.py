from lib import *

# (codice, id, nome, descrizione visiva, funzione di disegno, varianti{nome: funzione})
A = []


def add(code, id_, name, visual, fn, variants=None):
    A.append((code, id_, name, visual, fn, variants or {}))


# ---------- FAMIGLIA A: risorse e stato del combattimento
add("A01", "hp", "Punti vita", "cuore angolare pieno", heart, {"critico": heart_crack})
add("A02", "shield", "Scudo", "scudo esagonale a punta", shield, {"incrinato": shield_crack, "spezzato": shield_broken})
def balance(b):
    b.poly([(2, 8.5), (22, 8.5), (22, 15.5), (2, 15.5)], None)
    b.poly([(2, 8.5), (12, 8.5), (12, 15.5), (2, 15.5)], "soft")
    b.line((12, 4), (12, 20))
add("A03", "balance", "Equilibrio / Tenacia", "barra orizzontale con tacca centrale", balance)
def danger(b):
    b.poly([(12, 3), (22, 20.5), (2, 20.5)], "soft")
    b.line((12, 9), (12, 14.5))
    b.dot((12, 17.4), 1.2)
add("A04", "danger", "Pericolo", "triangolo angolare con punto esclamativo", danger)
def danger_lethal(b):
    b.poly([(12, 2.5), (22.5, 21), (1.5, 21)], "soft")
    b.poly([(12, 8), (14.2, 14), (12, 19), (9.8, 14)], "solid")
add("A05", "danger_lethal", "Pericolo letale", "triangolo con lama centrale", danger_lethal)
def ko(b):
    b.arc((12, 12), 9.5, -70, 110)
    b.arc((12, 12), 9.5, 125, 245)
    b.line((8, 8), (16, 16))
    b.line((16, 8), (8, 16))
add("A06", "ko", "KO", "cerchio spezzato con X", ko)
def attack(b):
    sword(b, False, 0, False)
    sword(b, True, 0, False)
add("A07", "attack", "Attacco", "due lame incrociate", attack, {"semplice": sword})
def defense(b):
    b.poly([(12, 3), (19, 6), (19, 13), (12, 21), (5, 13), (5, 6)], "soft")
    b.line((12, 7), (12, 16))
add("A08", "defense", "Difesa", "scudo compatto con asta centrale (azione GUARDIA, diversa dal valore SCUDO)", defense)
def special(b):
    b.poly([(14, 2), (5, 12.5), (10.5, 12.5), (13, 8)], "soft")
    b.poly([(13.5, 11), (19, 11), (9, 22), (10.8, 14.4)], "soft")
add("A09", "special", "Mossa speciale", "fulmine con frattura centrale", special)
def ultimate(b):
    ring(b, (12, 12), 10.2)
    b.push(5.2, 5.4, 0.57)
    special(b)
    b.pop()
add("A10", "ultimate", "Ultimate", "fulmine dentro un anello rituale", ultimate)
def healg(b):
    heart(b)
    b.line((12, 8.5), (12, 16))
    b.line((8.3, 12.2), (15.7, 12.2))
add("A11", "heal", "Cura", "cuore con croce centrale", healg)
def hot(b):
    b.push(2.5, 2.5, 0.72)
    heart(b)
    b.pop()
    b.arc((12, 12), 10, 100, 360 - 10, arrow=True, sw=SW_THIN)
add("A12", "heal_over_time", "Recupero nel tempo", "cuore con freccia circolare", hot)
def mobility(b):
    footprint(b, 0, 10, 0.6)
    footprint(b, 8, 1, 0.6)
    arrow_right(b, 11, 13, 0.5)
add("A13", "mobility", "Mobilita'", "due impronte con freccia direzionale", mobility)
def dodge(b):
    person(b, 4, 0, 0.9)
    for y, x in ((7, 2), (12, 1), (17, 2)):
        b.line((x, y), (x + 4, y), SW_THIN)
add("A14", "dodge", "Schivata", "sagoma con scia laterale", dodge)
def dodge_perfect(b):
    person(b, 5, 2.5, 0.75)
    ring(b, (12.5, 12.5), 10.2, SW_THIN)
    for y in (8, 12, 16):
        b.line((1.5, y), (6, y), SW_THIN)
    b.line((1.5, 10), (4.5, 10), SW_THIN)
add("A15", "dodge_perfect", "Schivata perfetta", "sagoma con doppia scia e anello completo", dodge_perfect)
add("A16", "duration", "Durata", "clessidra geometrica", hourglass)
add("A17", "target_single", "Bersaglio singolo", "mirino circolare con punto centrale", crosshair)
def all_enemies(b):
    b.arc((12, 18), 11, 200, 340)
    for x in (6, 12, 18):
        b.dot((x, 14 if x == 12 else 15.5), 2.2)
    b.dot((12, 20.5), 0.01)
add("A18", "target_all_enemies", "Tutti i nemici", "tre punti dentro un arco comune", all_enemies)
def all_allies(b):
    for x in (-1, 6, 13):
        person(b, x, 10, 0.5)
    b.polyline([(3, 3), (6, 6), (3, 9)], SW_THIN)
    b.polyline([(21, 3), (18, 6), (21, 9)], SW_THIN)
    b.dot((12, 5.5), 1.2)
add("A19", "target_all_allies", "Tutti gli alleati", "tre sagome rivolte verso il centro", all_allies)
def aoe(b):
    b.dot((12, 12), 2.4)
    b.arc((12, 12), 6.5, -50, 50)
    b.arc((12, 12), 6.5, 130, 230)
    b.arc((12, 12), 10.5, -50, 50)
    b.arc((12, 12), 10.5, 130, 230)
add("A20", "area", "Area d'effetto", "punto centrale con onde concentriche", aoe)
def front(b):
    b.line((2, 12), (14, 12))
    b.poly([(14, 7), (22, 12), (14, 17)], "solid")
    b.line((3, 7), (9, 7), SW_THIN)
    b.line((3, 17), (9, 17), SW_THIN)
add("A21", "attack_front", "Attacco frontale", "lama orizzontale che avanza", front)
def rear(b):
    b.circle((12, 16), 4.5, "soft")
    b.polyline([(2, 19), (3, 9), (10, 3), (19, 6), (20.5, 11)], None)
    b.poly([(20.5, 15), (18, 10.5), (23, 10.5)], "solid")
add("A22", "attack_rear", "Attacco posteriore", "traiettoria curva che raggiunge il retro del bersaglio", rear)
def interrupt(b):
    b.line((2, 12), (8, 12))
    b.line((16, 12), (22, 12))
    b.push(5.5, 3, 0.6)
    bolt(b, "solid")
    b.pop()
add("A23", "interrupt", "Interruzione", "fulmine che spezza una linea orizzontale", interrupt)
def weakness(b):
    b.circle((12, 12), 3, None)
    for dx, dy in ((1, -1), (1, 1), (-1, 1), (-1, -1)):
        b.polyline([(12 + dx * 4.5, 12 + dy * 4.5), (12 + dx * 6.5, 12 + dy * 9), (12 + dx * 10, 12 + dy * 10)])
    b.dot((12, 12), 1.2)
add("A24", "weakness", "Debolezza", "punto vulnerabile con frattura a quattro punte", weakness)
def resistance(b):
    shield(b)
    b.line((9.5, 8), (9.5, 16), SW_THIN)
    b.line((14.5, 8), (14.5, 16), SW_THIN)
add("A25", "resistance", "Resistenza", "scudo con due barre verticali", resistance)
def immunity(b):
    ring(b, (12, 12), 9.5)
    b.line((5.3, 18.7), (18.7, 5.3))
add("A26", "immunity", "Immunita'", "cerchio con barra diagonale", immunity)
def dmg_up(b):
    b.push(-1, 1, 0.85)
    sword(b)
    b.pop()
    arrow_up(b, 12.5, -1, 0.55)
add("A27", "damage_up", "Danno aumentato", "lama con freccia ascendente", dmg_up)
def dmg_down(b):
    b.push(-1, -1, 0.85)
    sword(b)
    b.pop()
    arrow_down(b, 12.5, 11, 0.55)
add("A28", "damage_down", "Danno ridotto", "lama con freccia discendente", dmg_down)
def precision(b):
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = 12 + sx * 9, 12 + sy * 9
            b.polyline([(cx - sx * 5, cy), (cx, cy), (cx, cy - sy * 5)])
    b.dot((12, 12), 1.8)
    b.line((12, 8), (12, 10.2), SW_THIN)
    b.line((12, 13.8), (12, 16), SW_THIN)
    b.line((8, 12), (10.2, 12), SW_THIN)
    b.line((13.8, 12), (16, 12), SW_THIN)
add("A29", "precision", "Precisione", "mirino a quattro angoli con punto centrale (diverso dal bersaglio singolo, circolare)", precision)
def crit(b):
    star4(b)
add("A30", "crit", "Critico", "stella tagliente a quattro punte", crit)
def miss(b):
    ring(b, (15, 12), 6.5)
    b.line((15, 3.5), (15, 6.5))
    b.line((15, 17.5), (15, 20.5))
    b.line((6.5, 12), (8.5, 12))
    b.line((21.5, 12), (23, 12))
    b.line((1, 17), (4, 17), SW_THIN)
    b.line((6, 14.5), (9, 12.8), SW_THIN)
add("A31", "miss", "Colpo mancato", "mirino vuoto con traiettoria interrotta", miss)
def taunt(b):
    b.poly([(5, 3), (19, 3), (19, 12), (12, 20), (5, 12)], "soft")
    b.line((7.5, 8), (10.5, 9.5))
    b.line((16.5, 8), (13.5, 9.5))
    b.poly([(2, 19), (6, 21.5), (2, 22.5)], "solid")
    b.poly([(22, 19), (18, 21.5), (22, 22.5)], "solid")
add("A32", "taunt", "Provocazione", "maschera geometrica con frecce convergenti", taunt)
def lifesteal(b):
    b.push(-3.5, 6, 0.6)
    heart(b)
    b.pop()
    b.push(10.5, -1, 0.7)
    sword(b)
    b.pop()
    b.polyline([(11, 18), (14, 18), (14, 13)], SW_THIN)
add("A33", "lifesteal", "Furto di vita", "cuore collegato a una lama da una linea di trasferimento", lifesteal)
def purify(b):
    ring(b, (12, 12), 8)
    spark(b, 6, 0, 0.9)
add("A34", "purify", "Purificazione", "anello attraversato da una scintilla", purify)
def resurrect(b):
    b.arc((12, 12), 9.5, -60, 240)
    arrow_up(b, 6.5, 5.5, 0.5)
add("A35", "resurrect", "Resurrezione", "anello aperto con freccia ascendente", resurrect)
def protected(b):
    person(b, -2, 5, 0.6)
    person(b, 11, 2, 0.7)
    b.push(9.5, 10, 0.55)
    b.poly([(12, 2), (20, 5.5), (20, 14), (12, 22), (4, 14), (4, 5.5)], "soft")
    b.pop()
add("A36", "target_protected", "Bersaglio protetto", "due sagome con scudo davanti alla posteriore", protected)
def charged(b):
    b.push(-3, 1, 0.9)
    sword(b)
    b.pop()
    bars(b, 15, 3, 21)
add("A37", "attack_charged", "Attacco caricato", "lama con tre tacche di energia crescente", charged)
def pierce(b):
    b.arc((8, 12), 7, -60, 60)
    b.arc((14, 12), 7, -60, 60)
    b.line((1, 12), (18, 12))
    b.poly([(22, 12), (16, 8), (16, 16)], "solid")
add("A38", "attack_pierce", "Attacco perforante", "punta che attraversa due scudi", pierce)
def ricochet(b):
    b.polyline([(3, 19), (9.5, 7), (14.5, 16), (20, 6)])
    b.poly([(21.5, 4), (15.5, 5), (20, 10)], "solid")
    b.circle((3.5, 19.5), 1.8, "solid")
add("A39", "attack_ricochet", "Attacco rimbalzante", "proiettile con traiettoria angolare che cambia direzione", ricochet)
def reflect(b):
    shield(b)
    b.polyline([(15, 8), (15, 15), (9, 15)], 1.5)
    b.poly([(9, 12.5), (9, 17.5), (6, 15)], "solid")
add("A40", "reflect", "Danno riflesso", "scudo con freccia di ritorno", reflect)
def absorb(b):
    core(b, 0, 0, 1, "solid", 2.6)
    arrow_right(b, -3, 0, 0.55)
    arrow_left(b, 8, 0, 0.55)
add("A41", "absorb", "Assorbimento", "due frecce convergenti verso un nucleo", absorb)
def steal_res(b):
    core(b, -3, 3, 1, "soft", 4.5)
    core(b, -3, 3, 1, "solid", 1.6)
    b.line((13, 11), (20, 4))
    b.poly([(21, 3), (21, 9), (15, 3)], "solid")
add("A42", "steal_resource", "Furto di risorsa", "nucleo con freccia di trasferimento uscente", steal_res)
def finisher(b):
    ring(b, (12, 12), 8)
    b.polyline([(12, 6), (10, 11), (14, 13), (12, 18)])
    for a, c in (((12, 1.5), (12, 4)), ((12, 20), (12, 22.5)), ((1.5, 12), (4, 12)), ((20, 12), (22.5, 12))):
        b.line(a, c)
add("A43", "finisher", "Colpo di grazia", "mirino concentrato su una frattura", finisher)
def row_swap(b):
    b.line((2, 4), (22, 4), SW_THIN)
    b.line((2, 20), (22, 20), SW_THIN)
    b.poly([(21, 9.5), (14, 6.5), (14, 12.5)], "solid")
    b.line((4, 9.5), (15, 9.5))
    b.poly([(3, 14.5), (10, 11.5), (10, 17.5)], "solid")
    b.line((9, 14.5), (20, 14.5))
add("A44", "row_swap", "Cambio di fila", "due frecce opposte tra due linee orizzontali", row_swap)
def reposition(b):
    footprint(b, 0, 9, 0.55)
    footprint(b, 12, 9, 0.55)
    b.arc((12, 12), 7, 195, 345, arrow=True, sw=SW_THIN)
add("A45", "reposition", "Riposizionamento", "due impronte unite da una traiettoria curva", reposition)
