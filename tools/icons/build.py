#!/usr/bin/env python3
"""Genera il catalogo icone ODISPEL: SVG singoli, registro GDScript, atlante HTML, documentazione.

Uso (dalla radice del repo):  python3 tools/icons/build.py
Sorgente unica: tools/icons/defs_*.py (+ lib.py). Non modificare a mano i file generati.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

from lib import B  # noqa: E402
import defs_a, defs_b, defs_c, defs_f, defs_h, defs_m  # noqa: E402

FAMILIES = [
    ("A", "combat", "Risorse e stato del combattimento", defs_a.A),
    ("B", "status", "Status, buff e debuff", defs_b.B_),
    ("C", "turns", "Turni, tempo e risoluzione", defs_c.C_),
    ("D", "combos", "Combo, reazioni e sinergie", defs_c.D_),
    ("E", "boss", "Boss e incontri speciali", defs_c.E_),
    ("F", "multiplayer", "Multiplayer e cooperazione", defs_f.F_),
    ("G", "world", "Esplorazione, hub e missioni", defs_f.G_),
    ("H", "progression", "Roster, equipaggiamento e progressione", defs_h.H_),
    ("I", "interface", "Funzioni generali dell'interfaccia", defs_h.I_),
    ("L", "odispel", "Identita' originale ODISPEL", defs_h.L_),
]

# Stato della meccanica (verificato sui dati del gioco; nel dubbio: "da verificare" / "non implementata")
IMPL = set("""hp shield balance danger danger_lethal ko attack defense special ultimate heal taunt target_single
target_all_enemies attack_pierce purify crit dodge reaction_ready reaction_used reaction_reserve boss_phase boss_enrage
attack_announced attack_lethal boss_hit_all timer turn_active turn_wait resolving st_bleed vulnerability_window
weakness_exposed boss_breaking boss_charge target_priority action_confirmed action_auto duration status_duration
ui_settings ui_audio ui_music ui_volume ui_mute ui_fullscreen ui_back ui_close ui_confirm ui_cancel ui_help ui_info
ui_notify ui_warning ui_error ui_success ui_locked ui_chat ui_menu ui_pause ui_play ui_restart ui_exit ui_connection
ui_connection_unstable ui_save ui_download w_codex w_tutorial net_host net_connected net_ready net_victory net_defeat
p_rank p_level p_currency_common p_currency_rare p_materials p_recruit p_inventory p_equipment p_equipped p_registry
p_title_earned p_titles stat_atk stat_def stat_spd stat_crit stat_resource""".split())
PARZ = set("""row_swap resurrect lifesteal reflect absorb attack_chained heal_over_time attack_front attack_rear interrupt
st_slow buff_atk debuff_atk buff_def debuff_def buff_spd debuff_spd buff buff_acc debuff_acc debuff reaction_incoming
combo_ready combo_active synergy synergy_ready team_bonus miss mobility net_waiting net_leave net_invite net_rejoin
net_unstable net_sync_error net_ally_off net_ally_turn net_confirmed net_sent p_new_operator p_duplicate p_item_new
p_reward_ready p_reward_claimed p_milestone p_rarity p_xp p_upgrade skill_locked skill_unlocked stat_acc timer_neutral
od_force od_energy od_energy_empty od_monad od_ignition od_rupture od_seal""".split())
VERIF = set("""target_all_allies target_protected attack_charged reposition dodge_perfect precision weakness
resistance immunity damage_up damage_down st_stun st_mark boss_hit_front boss_hit_back phase_goal environment
reinforcements attack_unavoidable od_trace od_anomaly od_void od_bond od_dimension st_poison st_burn st_frost""".split())

USE = {
    "combat": "Contestuale: durante la scelta (costi, bersagli) e nei riepiloghi; PV/scudo/equilibrio sempre visibili accanto al valore.",
    "status": "Contestuale: sotto la carta dell'operatore o del boss; dettaglio al tocco/puntatore.",
    "turns": "Contestuale: stato del timer e della risoluzione; solo uno alla volta.",
    "combos": "Contestuale: compaiono solo quando la combo/reazione e' possibile, poi scompaiono.",
    "boss": "Temporaneo o nel blocco boss: un'unica indicazione coerente per il pericolo, senza duplicare gli avvisi.",
    "multiplayer": "Collegare solo a informazioni reali del networking (nessuno stato inventato).",
    "world": "Predisposte per hub/esplorazione: non mostrare finche' la schermata non esiste.",
    "progression": "Roster, equipaggiamento, ricompense: solo nelle schermate corrispondenti.",
    "interface": "Funzioni generali: pulsanti e notifiche.",
    "odispel": "Identita' del gioco: Forza Odica, Monade, sigilli. Nessun comportamento meccanico inventato.",
}

LEGACY = {  # id del registro -> chiave del vecchio disegno in codice (fallback)
    "hp": "hp", "shield": "shield", "balance": "balance", "danger": "danger", "ko": "ko", "attack": "sword", "special": "bolt",
    "ultimate": "burst", "heal": "heal", "taunt": "taunt", "target_single": "target", "purify": "cleanse",
}


def status_of(id_):
    if id_ in IMPL:
        return "implementata"
    if id_ in PARZ:
        return "implementata parzialmente"
    if id_ in VERIF:
        return "da verificare"
    return "non implementata"


def svg_of(fn, sw=None):
    b = B()
    fn(b)
    return b.svg()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(text)


def main():
    entries = []   # dict per voce
    svgs = {}      # chiave (id oppure id@variante) -> svg
    seen = set()
    for letter, folder, fname, defs in FAMILIES:
        for code, id_, name, visual, fn, variants in defs:
            assert id_ not in seen, "ID duplicato " + id_
            seen.add(id_)
            svgs[id_] = svg_of(fn)
            vnames = []
            for vn, vf in variants.items():
                svgs["%s@%s" % (id_, vn)] = svg_of(vf)
                vnames.append(vn)
            entries.append(dict(id=id_, code=code, name=name, visual=visual, family=fname, letter=letter, folder=folder,
                                variants=vnames, use=USE[folder], status=status_of(id_),
                                fallback=("codice:" + LEGACY[id_]) if id_ in LEGACY else "cerchio"))
    # stesso concetto = stessa immagine (per regola): i doppioni dichiarati diventano "same_as"
    first = {}
    for e in entries:
        s_ = svgs[e["id"]]
        e["same_as"] = first.get(s_, "")
        first.setdefault(s_, e["id"])
    # stemmi M
    emblem_files = {}
    for code, id_, name, key, fn, visual in defs_m.EMBLEMS:
        assert id_ not in seen
        seen.add(id_)
        col = defs_m.FACTION_COLORS[key]
        for var, detail, sw, colr in (("light", 1, 2.0, "#ffffff"), ("dark", 1, 2.0, "#0b1519"), ("color", 1, 2.0, col),
                                      ("compact", 0, 2.8, "#ffffff"), ("large", 2, 1.8, "#ffffff")):
            b = defs_m.mk(detail, sw)
            fn(b, detail)
            s = b.svg().replace("#fff", colr)
            if var == "large":
                s = s.replace('width="24" height="24"', 'width="96" height="96"')
            emblem_files["%s_%s" % (key, var)] = s
            svgs["%s@%s" % (id_, var)] = b.svg()   # per il gioco: sempre bianco, tinto da GameIcon
        svgs[id_] = svgs["%s@compact" % id_]
        entries.append(dict(id=id_, code=code, name=name, visual=visual, family="Stemmi delle fazioni", letter="M", folder="factions",
                            variants=["light", "dark", "color", "compact", "large"], use="HUD e roster: versione compatta; menu: versione grande.",
                            status="implementata", fallback="codice:" + key, same_as=""))
    # ---- file SVG individuali (bianchi, trasparenti)
    icons_dir = os.path.join(ROOT, "assets", "ui", "icons")
    for e in entries:
        if e["folder"] == "factions":
            continue
        write(os.path.join(icons_dir, e["folder"], e["id"] + ".svg"), svgs[e["id"]])
        for v in e["variants"]:
            write(os.path.join(icons_dir, e["folder"], "%s__%s.svg" % (e["id"], v)), svgs["%s@%s" % (e["id"], v)])
    for k, s in emblem_files.items():
        write(os.path.join(icons_dir, "factions", k + ".svg"), s)
    # ---- registro GDScript
    lines = ["# GENERATO da tools/icons/build.py: non modificare a mano.", "class_name IconCatalog", "extends RefCounted", "",
             "# Registro centrale delle icone ODISPEL (esteso da GameIcon.SYMBOLS). Una voce per ID.",
             "# status: implementata | implementata parzialmente | da verificare | non implementata (asset predisposti, NON da mostrare)", "",
             "const ENTRIES: Dictionary = {"]
    for e in entries:
        asset = "assets/ui/icons/%s/%s.svg" % (e["folder"], e["id"]) if e["folder"] != "factions" else "assets/ui/icons/factions/%s_color.svg" % e["id"].replace("faction_", "")
        lines.append('\t"%s": {"code": "%s", "name": "%s", "desc": "%s", "family": "%s", "folder": "%s", "asset": "%s", "variants": %s, "use": "%s", "status": "%s", "fallback": "%s", "same_as": "%s"},' % (
            e["id"], e["code"], e["name"], e["visual"].replace('"', "'"), e["family"], e["folder"], asset, json.dumps(e["variants"]), e["use"].replace('"', "'"), e["status"], e["fallback"], e.get("same_as", "")))
    lines.append("}")
    lines.append("")
    lines.append("# SVG (bianchi, trasparenti, griglia 24) incorporati: il gioco li rasterizza alla dimensione richiesta e li tinge.")
    lines.append("const SVG: Dictionary = {")
    for k in sorted(svgs):
        lines.append('\t"%s": "%s",' % (k, svgs[k].replace('"', "'")))
    lines.append("}")
    lines.append("")
    write(os.path.join(ROOT, "scripts", "ui", "icon_catalog.gd"), "\n".join(lines))
    write(os.path.join(ROOT, "assets", "ui", "icons", "catalog.json"), json.dumps(entries, indent=1, ensure_ascii=False))
    make_atlas(entries, svgs, emblem_files)
    make_docs(entries)
    print("icone:", len(entries), "svg:", len(svgs))


def sample(svg_text, px, dark_bg):
    s = svg_text.replace('width="24" height="24"', 'width="%d" height="%d"' % (px, px)).replace('width="96" height="96"', 'width="%d" height="%d"' % (px, px))
    return s if dark_bg else s.replace("#fff", "#0b1519")


def make_atlas(entries, svgs, emblem_files):
    css = """body{margin:0;background:#101a20;color:#e8f3f5;font:14px/1.3 system-ui,sans-serif}
h1{margin:0;padding:18px 20px;font-size:22px}h2{margin:26px 20px 8px;font-size:16px;color:#7fdcec;border-bottom:1px solid #2b4650;padding-bottom:4px}
.note{margin:0 20px 8px;color:#9fb6bd;font-size:12px}
.g{display:flex;flex-wrap:wrap;gap:10px;padding:0 20px}.c{width:196px;border:1px solid #2b4650;border-radius:6px;overflow:hidden;background:#162630}
.c.fut{border-style:dashed;border-color:#8a6d2b}.row{display:flex}.l,.d{flex:1;padding:8px 6px;display:flex;gap:6px;align-items:flex-end;justify-content:center}
.l{background:#e9f1f3}.d{background:#0b1519}.m{padding:6px 8px;font-size:11px}.m b{display:block;font-size:12px}.m i{color:#9fb6bd;font-style:normal}
.tag{display:inline-block;margin-top:3px;padding:1px 5px;border-radius:3px;font-size:10px;background:#3a2f12;color:#ffc857}.ok{background:#12301f;color:#68e0a3}.pz{background:#12303a;color:#55d8f5}
.v{display:flex;gap:4px;margin-top:4px;flex-wrap:wrap;align-items:center}.v span{background:#0b1519;border-radius:3px;padding:2px;display:inline-flex}"""
    out = ["<!doctype html><html lang='it'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Atlante icone ODISPEL</title><style>%s</style></head><body>" % css,
           "<h1>ODISPEL — Atlante delle icone (%d voci)</h1>" % len(entries),
           "<p class='note' style='margin:0 20px 12px'>Ogni icona: campione su fondo chiaro e scuro a 48 / 24 / 20 px, ID e codice. Bordo tratteggiato giallo = meccanica NON implementata o da verificare (asset predisposto, non mostrato nel gioco). Varianti mostrate solo dove esistono.</p>"]
    for letter, folder, fname, defs in FAMILIES + [("M", "factions", "Stemmi delle fazioni", None)]:
        out.append("<h2>%s — %s</h2>" % (letter, fname))
        out.append("<div class='g'>")
        for e in [x for x in entries if x["letter"] == letter]:
            fut = e["status"] in ("non implementata", "da verificare")
            tagc = "ok" if e["status"] == "implementata" else ("pz" if "parzial" in e["status"] else "")
            if e["folder"] == "factions":
                key = e["id"].replace("faction_", "")
                light = emblem_files[key + "_light"].replace('stroke="#ffffff"', 'stroke="#0b1519"')
                lightsvg = emblem_files[key + "_dark"]
                darksvg = emblem_files[key + "_light"]
                big = emblem_files[key + "_large"]
                s1 = lightsvg.replace('width="24" height="24"', 'width="48" height="48"')
                s2 = darksvg.replace('width="24" height="24"', 'width="48" height="48"')
                out.append("<div class='c'><div class='row'><div class='l'>%s</div><div class='d'>%s</div></div><div class='m'><b>%s %s</b><i>%s</i><div class='v'>%s</div></div></div>" % (
                    s1, s2, e["code"], e["name"], e["id"],
                    "".join("<span title='%s'%s>%s</span>" % (v, " style='background:#e9f1f3'" if v == "dark" else "", emblem_files[key + "_" + v].replace('width="24" height="24"', 'width="40" height="40"').replace('width="96" height="96"', 'width="40" height="40"')) for v in e["variants"])))
                continue
            sv = svgs[e["id"]]
            l = "".join(sample(sv, p, False) for p in (48, 24, 20))
            d = "".join(sample(sv, p, True) for p in (48, 24, 20))
            vs = "".join("<span title='%s'>%s</span>" % (v, sample(svgs["%s@%s" % (e["id"], v)], 32, True)) for v in e["variants"])
            out.append("<div class='c%s'><div class='row'><div class='l'>%s</div><div class='d'>%s</div></div><div class='m'><b>%s %s</b><i>%s</i><br><span class='tag %s'>%s</span>%s</div></div>" % (
                " fut" if fut else "", l, d, e["code"], e["name"], e["id"], tagc, e["status"], ("<div class='v'>%s</div>" % vs) if vs else ""))
        out.append("</div>")
    out.append("</body></html>")
    write(os.path.join(ROOT, "docs", "icone", "atlante.html"), "\n".join(out))


def make_docs(entries):
    stat = {}
    for e in entries:
        stat[e["status"]] = stat.get(e["status"], 0) + 1
    md = ["# Icone ODISPEL — stile, registro e uso", "",
          "GENERATO in parte da `tools/icons/build.py` (la tabella finale). Sorgente dei disegni: `tools/icons/lib.py` e `defs_*.py`.", "",
          "## Stile", "- Griglia 24x24, margine 2, tratto 2 (1,5 per i dettagli piccoli), angoli vivi, estremita' squadrate.",
          "- Riempimenti: 'morbido' = bianco al 30%, 'pieno' = bianco. Nessun testo, numero, sfondo.",
          "- Gli SVG sono BIANCHI e trasparenti: il gioco li tinge (`GameIcon.color`). Il significato sta nella FORMA, non nel colore.",
          "- Palette di riferimento (tinte applicate dal gioco): corallo #FF667A pericolo, ciano #55D8F5 info/difesa, giallo #FFC857 attenzione, viola #C59AFF energia rituale, verde #68E0A3 recupero.",
          "- Varianti di stato: ottenute con geometria (incrinato, spezzato, critico), non solo col colore. Stati disabilitato/selezionato: tinta e contorno decisi dal componente che usa l'icona.",
          "- Famiglie coerenti: stessa lama per buff/debuff attacco, stesso scudo per buff/debuff difesa, stessi anelli per combo disponibile/attivata, stessi nodi per connessione stabile/instabile, stesso fulmine per speciale/ultimate (+ anello).",
          "", "## Dove sono i file", "- `assets/ui/icons/<famiglia>/<id>.svg` (+ `<id>__<variante>.svg`); stemmi in `assets/ui/icons/factions/<fazione>_{light,dark,color,compact,large}.svg`.",
          "- Registro: `scripts/ui/icon_catalog.gd` (`IconCatalog.ENTRIES`, esposto anche come `GameIcon.SYMBOLS`); SVG incorporati in `IconCatalog.SVG` (cosi' l'esportazione non dipende dall'importazione degli asset).",
          "- Atlante visivo: `docs/icone/atlante.html` (e `atlante.png`). `assets/ui/icons/catalog.json` = stesso registro in JSON.",
          "", "## Rigenerare", "`python3 tools/icons/build.py` riscrive SVG, `scripts/ui/icon_catalog.gd`, `assets/ui/icons/catalog.json`, questo file e `docs/icone/atlante.html` (l'immagine `atlante.png` si ottiene aprendo l'HTML in un browser). Per aggiungere o ritoccare un'icona: modificare `tools/icons/defs_*.py`, rigenerare, eseguire `tests/unit/test_icon_catalog.gd`.",
          "", "## Screenshot (1280x720, xvfb, giochi avviati davvero)", "In `docs/icone/screens/`: battaglia (scelta, pericolo, risoluzione; PC e touch), roster, hub, PvP, obiettivi, lobby multiplayer. Non testate su telefono reale.",
          "", "## Come si usa", "- `GameIcon.new().setup(id, colore, px)`; variante: `setup(id, colore, px, 'incrinato')`. Se l'ID manca o il rendering fallisce, si usa il disegno di riserva in codice o un cerchio.",
          "- Usare l'icona dove il significato e' noto, con il numero accanto; testo esplicito per pericoli critici (rischio KO).",
          "- Le icone con stato 'non implementata' o 'da verificare' NON vanno mostrate in combattimento o nei menu: sono asset predisposti.",
          "", "## Stato delle meccaniche (%s)" % ", ".join("%s: %d" % (k, v) for k, v in sorted(stat.items())), "",
          "Stesso concetto = stessa immagine: le voci con 'Uguale a' condividono il disegno di proposito (es. SCUDO e DIFESA STATISTICA).", "",
          "| Codice | ID | Nome | Famiglia | Varianti | Stato | Fallback | Uguale a |", "|---|---|---|---|---|---|---|---|"]
    for e in entries:
        md.append("| %s | `%s` | %s | %s | %s | %s | %s | %s |" % (e["code"], e["id"], e["name"], e["folder"], ", ".join(e["variants"]) or "-", e["status"], e["fallback"], ("`%s`" % e["same_as"]) if e.get("same_as") else "-"))
    write(os.path.join(ROOT, "docs", "icone", "README.md"), "\n".join(md) + "\n")


if __name__ == "__main__":
    main()
