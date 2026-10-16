from lib import *

B_ = []


def add(code, id_, name, visual, fn, variants=None):
    B_.append((code, id_, name, visual, fn, variants or {}))


# ---------- FAMIGLIA B: status, buff, debuff
def burn(b):
    flame(b)
    b.polyline([(12, 20), (10, 16), (13, 13)], SW_THIN)
    b.dot((18.5, 4.5), 1.1)
add("B01", "st_burn", "Bruciatura", "fiamma spezzata con scintilla", burn)
def poison(b):
    drop(b)
    for x in (8.5, 12, 15.5):
        b.line((x, 15), (x, 18), SW_THIN)
    b.poly([(7.2, 18), (9.8, 18), (8.5, 20.5)], "solid")
    b.poly([(10.7, 18), (13.3, 18), (12, 20.5)], "solid")
    b.poly([(14.2, 18), (16.8, 18), (15.5, 20.5)], "solid")
add("B02", "st_poison", "Veleno", "goccia con tre punte verso il basso", poison)
def bleed(b):
    drop(b)
    b.line((6, 18), (18, 8))
add("B03", "st_bleed", "Sanguinamento", "goccia attraversata da una diagonale", bleed)
add("B04", "st_frost", "Gelo", "cristallo geometrico a sei punte", crystal6)
def slow(b):
    b.push(0, -2, 0.8)
    crystal6(b)
    b.pop()
    arrow_down(b, 12.5, 12, 0.5)
add("B05", "st_slow", "Rallentamento", "fiocco semplificato con freccia discendente", slow)
def root(b):
    b.line((3, 8), (10, 8))
    b.line((14, 8), (21, 8))
    b.line((3, 16), (10, 16))
    b.line((14, 16), (21, 16))
    b.poly([(10, 5), (14, 5), (14, 19), (10, 19)], "soft")
add("B06", "st_root", "Immobilizzazione", "due segmenti uniti da un fermo", root)
def stun(b):
    b.poly([(12, 3), (14, 9), (20, 8), (16, 13), (19, 19), (12, 16), (6, 20), (8, 13), (3, 9), (10, 9)], "soft")
add("B07", "st_stun", "Stordimento", "stella irregolare con archi interrotti", stun)
def silence(b):
    bubble(b)
    b.line((3, 21), (21, 3))
add("B08", "st_silence", "Silenzio", "fumetto barrato", silence)
def blind(b):
    eye(b, 0, 0, 1, True)
    b.polyline([(14, 4), (11, 10), (14, 14), (10, 20)], SW_THIN)
add("B09", "st_blind", "Cecita'", "occhio chiuso attraversato da una frattura", blind)
def confusion(b):
    b.polyline([(3, 20), (12, 12), (18, 4)])
    b.polyline([(21, 20), (12, 12), (6, 4)])
    b.dot((12, 12), 1.5)
    b.poly([(18, 2), (21, 6.5), (15, 6)], "solid")
    b.poly([(6, 2), (9, 6), (3, 6.5)], "solid")
add("B10", "st_confusion", "Confusione", "due traiettorie che si incrociano senza raggiungere il bersaglio", confusion)
def fear(b):
    person(b, 4, 4, 0.8)
    for a in (150, 180, 210):
        r = math.radians(a)
        b.line((12 + 5 * math.cos(r), 12 + 5 * math.sin(r)), (12 + 10.5 * math.cos(r), 12 + 10.5 * math.sin(r)), SW_THIN)
    for a in (-30, 0, 30):
        r = math.radians(a)
        b.line((12 + 5 * math.cos(r), 12 + 5 * math.sin(r)), (12 + 10.5 * math.cos(r), 12 + 10.5 * math.sin(r)), SW_THIN)
add("B11", "st_fear", "Paura", "sagoma con linee divergenti", fear)
def corruption(b):
    core(b, 0, 0, 1, "soft", 8)
    b.polyline([(12, 4), (10, 9), (14, 12), (11, 16), (13, 20)])
add("B12", "st_corruption", "Corruzione", "nucleo centrale incrinato", corruption)
def drain(b):
    b.push(-2, 0, 0.9)
    drop(b)
    b.pop()
    arrow_down(b, 12, 2, 0.5)
    b.line((15, 20), (22, 20))
add("B13", "st_drain", "Drenaggio", "goccia con freccia di sottrazione", drain)
def skill_lock(b):
    lock(b)
    b.poly([(12, 12.5), (13.4, 15.5), (12, 18.5), (10.6, 15.5)], "solid")
add("B14", "st_skill_lock", "Blocco abilita'", "lucchetto con simbolo interno", skill_lock)
add("B15", "buff", "Potenziamento", "freccia ascendente", arrow_up)
add("B16", "debuff", "Penalita'", "freccia discendente", arrow_down)
def buff_atk(b):
    b.push(-2, 3, 0.8)
    sword(b)
    b.pop()
    arrow_up(b, 12, -1, 0.5)
add("B17", "buff_atk", "Potenziamento attacco", "freccia ascendente con lama", buff_atk)
def debuff_atk(b):
    b.push(-2, -3, 0.8)
    sword(b)
    b.pop()
    arrow_down(b, 12, 11, 0.5)
add("B18", "debuff_atk", "Penalita' attacco", "freccia discendente con lama", debuff_atk)
def buff_def(b):
    b.push(-1, 3, 0.8)
    shield(b)
    b.pop()
    arrow_up(b, 12, -1, 0.5)
add("B19", "buff_def", "Potenziamento difesa", "freccia ascendente con scudo", buff_def)
def debuff_def(b):
    b.push(-1, -2, 0.8)
    shield(b)
    b.pop()
    arrow_down(b, 12, 11, 0.5)
add("B20", "debuff_def", "Penalita' difesa", "freccia discendente con scudo", debuff_def)
def buff_spd(b):
    arrow_right(b, 5, 0, 0.6)
    b.line((2, 8), (9, 8))
    b.line((1, 12), (8, 12))
    b.line((2, 16), (9, 16))
    b.line((14, 20), (14, 20.01))
    arrow_up(b, 13, -1, 0.4)
add("B21", "buff_spd", "Potenziamento velocita'", "doppia scia ascendente", buff_spd)
def debuff_spd(b):
    arrow_right(b, 5, 0, 0.6)
    b.line((2, 8), (5, 8))
    b.line((7, 8), (9, 8))
    b.line((1, 12), (3, 12))
    b.line((5, 12), (8, 12))
    b.line((2, 16), (5, 16))
    arrow_down(b, 13, 12, 0.4)
add("B22", "debuff_spd", "Penalita' velocita'", "doppia scia interrotta", debuff_spd)
def buff_acc(b):
    crosshair(b, 0, 0, 0.9)
    spark(b, 12, -3, 0.45)
add("B23", "buff_acc", "Potenziamento precisione", "mirino con scintilla", buff_acc)
def debuff_acc(b):
    crosshair(b, 0, 0, 1.0)
    b.polyline([(14, 5), (11, 11), (14, 14), (11, 19)], SW_THIN)
add("B24", "debuff_acc", "Penalita' precisione", "mirino attraversato da una frattura", debuff_acc)
def temp_shield(b):
    shield(b)
    hourglass(b, 6, 6, 0.5)
add("B25", "temp_shield", "Scudo temporaneo", "scudo con clessidra interna", temp_shield)
def regen(b):
    b.push(2.5, 2.5, 0.72)
    heart(b)
    b.pop()
    b.arc((12, 12), 10, 100, 350, arrow=True, sw=SW_THIN)
add("B26", "regen", "Rigenerazione", "cuore con freccia circolare", regen)
def temp_immunity(b):
    ring(b, (12, 12), 9.5)
    b.push(6.5, 6.5, 0.45)
    shield(b)
    b.pop()
add("B27", "temp_immunity", "Immunita' temporanea", "cerchio protetto da un piccolo scudo", temp_immunity)
def cleanse_status(b):
    b.line((5, 12), (13, 12))
    for i, (x, y) in enumerate(((16, 12), (19.5, 12), (22.5, 12))):
        b.dot((x, y), 1.4 - i * 0.35)
    b.line((4, 7), (9, 7), SW_THIN)
    b.line((4, 17), (9, 17), SW_THIN)
add("B28", "status_clear", "Rimozione di status", "simbolo negativo che si dissolve", cleanse_status)
def spec_resist(b):
    shield(b)
    b.push(7, 7, 0.4)
    drop(b, "solid")
    b.pop()
add("B29", "status_resist", "Resistenza specifica", "scudo con simbolo dello status al centro", spec_resist)
def stack(b):
    b.dot((12, 14), 3.4)
    for x in (4, 12, 20):
        b.line((x, 3), (12 + (x - 12) * .35, 9), SW_THIN)
add("B30", "status_stack", "Accumulo di status", "tre segmenti che convergono nel simbolo principale", stack)
def consume(b):
    b.poly([(12, 4), (19, 12), (12, 20), (5, 12)], "soft")
    b.line((12, 4), (12, 11))
    b.poly([(14, 14), (19, 12), (17, 17)], "solid")
add("B31", "status_consume", "Consumo di status", "simbolo con una tacca che scompare", consume)
add("B32", "status_duration", "Durata residua", "clessidra (il numero e' gestito dall'interfaccia)", hourglass)
