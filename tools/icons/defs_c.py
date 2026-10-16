from lib import *

C_ = []


def add(code, id_, name, visual, fn, variants=None):
    C_.append((code, id_, name, visual, fn, variants or {}))


# ---------- FAMIGLIA C: turni, tempo, risoluzione
def frame(b):
    b.polyline([(2, 8), (2, 2), (8, 2)])
    b.polyline([(16, 2), (22, 2), (22, 8)])
    b.polyline([(22, 16), (22, 22), (16, 22)])
    b.polyline([(8, 22), (2, 22), (2, 16)])
    person(b, 5, 4, 0.58)
add("C01", "turn_active", "Turno attivo", "cornice angolare per il ritratto dell'operatore", frame)
def wait(b):
    b.arc((12, 12), 9, -60, 230)
add("C02", "turn_wait", "Turno in attesa", "cerchio incompleto", wait)
def timer(b):
    b.arc((12, 12), 9.5, -90, 200)
    b.dot((12, 12), 2.2)
add("C03", "timer", "Timer di scelta", "anello temporale che si consuma attorno a un numero", timer)
def t_max(b):
    ring(b, (10, 14), 8)
    spark(b, 13, -1, 0.42)
add("C04", "timer_bonus_max", "Bonus temporale massimo", "anello completo con scintilla", t_max)
def t_min(b):
    ring(b, (12, 12), 9.5)
    b.poly([(10, 1), (14, 1), (14, 5.5), (10, 5.5)], "solid")
add("C05", "timer_bonus_min", "Bonus temporale minore", "anello con una tacca luminosa", t_min)
add("C06", "timer_neutral", "Timer neutro", "anello senza accenti", lambda b: ring(b, (12, 12), 9.5))
def t_pen_min(b):
    ring(b, (12, 12), 9.5)
    b.polyline([(18.5, 4.5), (15.5, 8), (17.5, 10), (14.5, 13)], SW_THIN)
add("C07", "timer_penalty_min", "Penalita' temporale minore", "anello con una crepa", t_pen_min)
def t_pen_max(b):
    b.arc((12, 12), 9.5, 20, 150)
    b.arc((12, 12), 9.5, 170, 320)
    b.poly([(12, 8), (17, 17), (7, 17)], "soft")
    b.line((12, 10.8), (12, 13.5), SW_THIN)
add("C08", "timer_penalty_max", "Penalita' temporale massima", "anello spezzato con segnale di pericolo", t_pen_max)
add("C09", "time_up", "Tempo scaduto", "clessidra vuota", lambda b: hourglass(b, 0, 0, 1, True))
def auto(b):
    b.push(-2, 1, 0.9)
    sword(b)
    b.pop()
    b.arc((18, 6), 4, 30, 330, arrow=True, sw=SW_THIN)
add("C10", "action_auto", "Azione automatica", "lama semplice con piccola freccia circolare", auto)
def confirmed(b):
    seal(b, 10)
    check(b, 6, 6, 0.5)
add("C11", "action_confirmed", "Azione confermata", "spunta dentro un piccolo sigillo", confirmed)
def resolving(b):
    b.poly([(5, 10), (19, 10), (19, 14), (5, 14)], None)
    b.poly([(5, 10), (13, 10), (13, 14), (5, 14)], "solid")
    b.line((5, 5), (5, 7), SW_THIN)
    b.line((19, 5), (19, 7), SW_THIN)
add("C12", "resolving", "Risoluzione in corso", "linea di avanzamento", resolving)
def cancel(b):
    b.polyline([(18, 18), (6, 18), (6, 8)])
    b.poly([(6, 4), (2.5, 9.5), (9.5, 9.5)], "solid")
    b.line((10, 14), (13, 14), SW_THIN)
    b.line((16, 14), (19, 14), SW_THIN)
add("C13", "action_cancel", "Azione annullata", "ritorno con una linea interrotta", cancel)
def unavailable(b):
    ring(b, (12, 12), 8.5, SW_THIN)
    b.line((6, 18), (18, 6), SW_THIN)
add("C14", "action_unavailable", "Azione non disponibile", "simbolo neutro barrato (senza rosso obbligatorio)", unavailable)
def sequence(b):
    b.line((6, 17), (12, 7))
    b.line((12, 7), (18, 17))
    for p in ((6, 17), (12, 7), (18, 17)):
        b.circle(p, 3, "soft")
add("C15", "sequence", "Sequenza in corso", "tre nodi collegati", sequence)
def final(b):
    seal(b, 10)
    b.circle((12, 12), 10, None)
    check(b, 6.5, 6.5, 0.45)
add("C16", "result_final", "Risultato finale", "sigillo chiuso con spunta", final)

# ---------- FAMIGLIA D: combo, reazioni, sinergie
D_ = []


def addd(code, id_, name, visual, fn, variants=None):
    D_.append((code, id_, name, visual, fn, variants or {}))


def rings2(b, off=0.0):
    b.circle((8.5 - off, 12), 6.5)
    b.circle((15.5 + off, 12), 6.5)


addd("D01", "combo_ready", "Combo disponibile", "due anelli che si intersecano", rings2)
def combo_on(b):
    rings2(b)
    spark(b, 8.5, 8.5, 0.28)
addd("D02", "combo_active", "Combo attivata", "gli stessi anelli con scintilla centrale", combo_on)
def chain(b):
    b.line((4, 16), (12, 8))
    b.line((12, 8), (20, 16))
    for p in ((4, 16), (12, 8), (20, 16)):
        b.circle(p, 2.6, "soft")
    b.line((4, 21), (20, 21), SW_THIN)
addd("D03", "combo_chain", "Catena di combo", "tre nodi collegati da una linea continua", chain)
def react_on(b):
    ring(b, (12, 12), 9.5)
    spark(b, 6, 6, 0.5)
addd("D04", "reaction_ready", "Reazione disponibile", "cerchio con scintilla", react_on)
def react_used(b):
    ring(b, (12, 12), 9.5)
    b.line((4, 20), (20, 4))
addd("D05", "reaction_used", "Reazione consumata", "cerchio vuoto con taglio", react_used)
def reserve(b):
    for x in (5, 12, 19):
        b.circle((x, 12), 3.2, "soft")
        b.dot((x, 12), 1.0)
addd("D06", "reaction_reserve", "Riserva reazioni", "tre nuclei separati e contabili", reserve)
def synergy(b):
    person(b, -3, 4, 0.62)
    person(b, 11, 4, 0.62)
    b.line((9.5, 14), (14.5, 14))
addd("D07", "synergy", "Sinergia tra operatori", "due sagome collegate", synergy)
def combined(b):
    sword(b, False, -3)
    sword(b, True, -3)
    star4(b, 7, 0, 0.4)
addd("D08", "attack_combined", "Attacco combinato", "due lame convergenti in un unico impatto", combined)
def team_bonus(b):
    core(b, 0, 1, 1, "solid", 2.2)
    for cx, cy in ((12, 5.5), (5, 17.5), (19, 17.5)):
        person(b, cx - 6, cy - 6, 0.5)
addd("D09", "team_bonus", "Bonus di squadra", "tre figure attorno a un nucleo", team_bonus)
def boss_opening(b):
    b.poly([(5, 3), (19, 3), (19, 14), (12, 21), (5, 14)], "soft")
    b.polyline([(14, 3), (10, 10), (14, 14), (10, 21)], 1.5)
    spark(b, 15, 0, 0.35)
addd("D10", "boss_opening", "Opportunita' sul boss", "crepa luminosa sul bersaglio", boss_opening)
def interplay(b):
    b.poly([(2, 7), (12, 7), (12, 11), (9, 11), (9, 17), (2, 17)], "soft")
    b.poly([(22, 7), (14, 7), (14, 12), (16, 12), (16, 17), (22, 17)], "soft")
addd("D11", "interaction", "Interazione speciale", "due simboli che si incastrano", interplay)
def combo_fail(b):
    b.circle((6.5, 9), 5.5)
    b.circle((17.5, 15), 5.5)
addd("D12", "combo_fail", "Combo fallita", "due anelli disallineati", combo_fail)
def combo_perfect(b):
    b.circle((12, 12), 9)
    b.circle((12, 12), 6.5)
    star4(b, 7.5, 7.5, 0.37)
addd("D13", "combo_perfect", "Combo perfetta", "due anelli sovrapposti con stella centrale", combo_perfect)
def react_incoming(b):
    ring(b, (12, 12), 8.5)
    arrow_right(b, 0, 7, 0.5)
    b.dot((12, 12), 1.4)
addd("D14", "reaction_incoming", "Reazione in arrivo", "cerchio con freccia entrante", react_incoming)
def syn_ready(b):
    for p in ((4, 17), (20, 17), (12, 3.5)):
        b.circle(p, 2.4, "soft")
        b.line(p, (12, 13), SW_THIN)
    spark(b, 7.5, 8, 0.35)
addd("D15", "synergy_ready", "Sinergia pronta", "tre nodi che convergono su una scintilla", syn_ready)

# ---------- FAMIGLIA E: boss e incontri speciali
E_ = []


def adde(code, id_, name, visual, fn, variants=None):
    E_.append((code, id_, name, visual, fn, variants or {}))


def phase(b):
    for i in range(4):
        a0 = -90 + i * 90 + 6
        b.arc((12, 12), 9, a0, a0 + 78, sw=(3.2 if i == 1 else SW_THIN))
    b.dot((12, 12), 2.2)
adde("E01", "boss_phase", "Fase del boss", "emblema segmentato con una parte evidenziata", phase)
def enrage(b):
    core(b, 0, 0, 1, "solid", 3.6)
    for a in range(0, 360, 45):
        r = math.radians(a)
        b.poly([(12 + 6.5 * math.cos(r - .22), 12 + 6.5 * math.sin(r - .22)), (12 + 11 * math.cos(r), 12 + 11 * math.sin(r)), (12 + 6.5 * math.cos(r + .22), 12 + 6.5 * math.sin(r + .22))], "solid")
adde("E02", "boss_enrage", "Furia / Enrage", "nucleo circondato da punte verso l'esterno", enrage)
def charging(b):
    b.arc((12, 12), 9.5, -90, 150)
    core(b, 0, 0, 1, "solid", 3)
adde("E03", "boss_charge", "Caricamento del boss", "anello che si riempie attorno a un nucleo", charging)
def hit_all(b):
    for x in (5, 12, 19):
        b.circle((x, 19), 2.6, "soft")
    b.arc((12, 27), 13, 225, 315)
    b.arc((12, 27), 16, 228, 312)
adde("E04", "boss_hit_all", "Attacco a tutta la squadra", "piu' bersagli sotto un'onda comune", hit_all)
def two_rows(front_on):
    def draw(b):
        for i, y in enumerate((6, 16)):
            hl = (i == 1) == front_on
            for x in (5, 12, 19):
                b.circle((x, y + 1), 2.6, "solid" if hl else None, SW_THIN)
        b.line((2, 12), (22, 12), 1.0)
    return draw
adde("E05", "boss_hit_front", "Attacco alla prima fila", "due linee, quella anteriore evidenziata", two_rows(True))
adde("E06", "boss_hit_back", "Attacco alla retroguardia", "due linee, quella posteriore evidenziata", two_rows(False))
def unavoidable(b):
    ring(b, (12, 12), 8, None)
    b.circle((12, 12), 8, "soft")
    b.line((8.5, 8.5), (15.5, 15.5))
    b.line((15.5, 8.5), (8.5, 15.5))
    for a, c in (((12, 1.5), (12, 4)), ((12, 20), (12, 22.5)), ((1.5, 12), (4, 12)), ((20, 12), (22.5, 12))):
        b.line(a, c)
adde("E07", "attack_unavoidable", "Attacco inevitabile", "mirino pieno con X centrale", unavoidable)
def vuln(b):
    b.poly([(12, 2), (20, 5.5), (20, 14), (12, 22), (4, 14), (4, 5.5)], None)
    b.line((12, 2), (12, 5))
    b.polyline([(12, 6), (9.5, 11), (14.5, 14), (12, 19)], SW)
    spark(b, 12, 5, 0.32)
adde("E08", "vulnerability_window", "Finestra di vulnerabilita'", "scudo aperto con frattura luminosa", vuln)
def boss_breaking(b):
    b.poly([(12, 2), (20, 6), (20, 14), (16, 22), (8, 22), (4, 14), (4, 6)], "soft")
    b.polyline([(15, 2), (10, 9), (14, 13), (9, 22)])
adde("E09", "boss_breaking", "Boss in rottura", "sagoma del boss attraversata da una crepa", boss_breaking)
def environment(b):
    b.poly([(2, 2), (22, 2), (22, 22), (2, 22)], None)
    eye(b, 3, 3, 0.75)
adde("E10", "environment", "Meccanica ambientale", "occhio geometrico dentro una cornice quadrata", environment)
def phase_goal(b):
    for i in range(6):
        a0 = -90 + i * 60 + 5
        b.arc((12, 12), 9, a0, a0 + 50, sw=(3.4 if i == 0 else SW_THIN))
adde("E11", "phase_goal", "Obiettivo di fase", "anello segmentato con una tacca evidenziata", phase_goal)
def reinforce(b):
    person(b, -1, 3, 0.78)
    person(b, 8, 3, 0.55)
    person(b, 14, 3, 0.55)
adde("E12", "reinforcements", "Rinforzi nemici", "sagome aggiuntive dietro il bersaglio principale", reinforce)
def announced(b):
    ring(b, (15, 12), 6.5)
    b.dot((15, 12), 1.6)
    arrow_right(b, -6, 7, 0.45)
adde("E13", "attack_announced", "Attacco annunciato", "bersaglio con freccia entrante", announced)
def pot_lethal(b):
    b.poly([(12, 2.5), (22.5, 21), (1.5, 21)], "soft")
    b.poly([(12, 8), (14.2, 14), (12, 19), (9.8, 14)], "solid")
adde("E14", "attack_lethal", "Attacco potenzialmente letale", "triangolo di pericolo con lama centrale", pot_lethal)
def priority(b):
    ring(b, (12, 12), 9.5)
    ring(b, (12, 12), 6, SW_THIN)
    b.dot((12, 12), 1.6)
adde("E15", "target_priority", "Bersaglio prioritario", "mirino con doppio bordo", priority)
def exposed(b):
    b.circle((12, 12), 9, None)
    b.polyline([(12, 3), (9.5, 9), (14.5, 12.5), (12, 21)], 2.4)
adde("E16", "weakness_exposed", "Debolezza esposta", "frattura aperta nel simbolo del bersaglio", exposed)
