"""TR50's older line (research, 2026-11-20, 00:11; class: every art tile's ground): the Arc panel's lantern stands on a
violet field, and the picker's whole screen on a violet ground with a lavender glow. Both take the festival's dusk, warm
under the lantern. A colour block-in for research's pick: the Arc panel as it stands today, beside three steps of dusk.

    blender -b --factory-startup --python tools/blender/stage_arc_dusk.py -- <abs out>

Writes stage_arc_dusk.png (the four at the smallest phone's own pixels, 1.5 a point) and stage_arc_dusk.json (each
direction's colours under the names Config.Hud's Stages and UIKit.Palettes.SeamGlass keep them by).

The panel is laid from Config.Hud's Stages (Tile, Bed, Arc) and Faber's capture of TR50 (build/captures/tr50/
fix-panel.png): a stand-in for the game's own layout, drawn for its colours only. The lantern is stage_screen.py's, as
stage_cut.py cut it. The steps, each over the one before:
    A  the bed only: the lantern's field is the dusk street, dark over the lantern and warm under it.
    B  and the ground: the screen behind the glass, the light round the panel, and Normal's lit plates in lantern light.
       The glass stays Seam's (the director's scope of 2026-11-19, 14:56: the picker in Seam).
    C  and the glass: the panel, its cards and its words in rosewood. Past the 14:56 scope, shown to be judged.
The lantern's own gold needs a dark field behind it, so the warmth pools under it, where its light would fall, never
behind its paper.
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import stage_screen as ss  # noqa: E402
import stage_seam as sq  # noqa: E402,F401  (on import: the lantern's Seam colours, as the cut picture has them)

W, H = ss.W, ss.H
SMALL, TITLE = ss.SMALL, ss.TITLE
K = 1.5                                   # the smallest phone's pixels a point
EMBER = "#FF9A80"                         # Hard's accent, unchanged

TODAY = dict(
    backing=("#1F1942", "#0D0B1A"), ground_bloom=("#5C48AC", 0.30),
    panel=("#2F2758", "#16122C"), panel_glow="#D4C6FF", panel_edge="#EDE4FF",
    bed=("#0E0B1A", "#08070F"), bed_bloom=("#5C48AC", 0.75), bed_low=0.0, bed_edge="#51477A",
    button=("#3C3268", "#251E46"), shut=("#1C1834", "#110E20"), edge="#51477A", facet="#A89CD8", glint="#F0EAFF",
    well="#262044", channel="#0C0A1A", text="#F1ECFF", soft="#C6BDE4", faint="#8279A6", ink="#0B0913",
    lit=("#FFFFFF", "#D4C6FF"), lit_glow="#D4C6FF")
# A: the bed is the dusk street. Dark wine over the lantern, rosewood at its foot, the lantern's light pooled low.
A = dict(TODAY, bed=("#1E0F16", "#4A2324"), bed_bloom=("#FF9A50", 0.62), bed_low=0.36, bed_edge="#7A5048")
# B: the ground behind the glass and every light on it. The glass keeps Seam's violet.
# (The first take's ground, #3E1F26 to #170C0F, read as a dull maroon: the street's dusk is rose, so it leans rose.)
B = dict(A, backing=("#5E2A3A", "#1E0E12"), ground_bloom=("#FF8246", 0.38), panel_glow="#FFCF98",
         panel_edge="#FFEBD2", lit=("#FFFFFF", "#FFE0B4"), lit_glow="#FFCF98")
# C: the glass in rosewood, its words in ivory.
C = dict(B, panel=("#6A3A44", "#30191F"), button=("#7A4650", "#48282E"), shut=("#38202A", "#201216"),
         edge="#8E6062", facet="#E4B4A0", glint="#FFF0E0", well="#48282E", channel="#180C0E", text="#FFF4E8",
         soft="#E8CEC0", faint="#B09090", ink="#1A0E10")
TAKES = [("Today", TODAY, "Today: Seam's violet under everything"),
         ("A", A, "A. The bed only: the lantern on the dusk street, warm under it"),
         ("B", B, "B. And the ground: the screen behind the glass, the panel's light, Normal's lit plates"),
         ("C", C, "C. And the glass: rosewood, ivory words (past the 14:56 scope)")]


def lit_plate(t, x0, y0, x1, y1, p, cut=5.0, glow=0.45):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut, cut, cut))
    t.glow(d, 7.0, p["lit_glow"], glow)
    t.paint(d, up.shade(t, p["lit"], y0, y1))
    t.paint(d, p["lit"][1], 0.35 * np.clip((t.y - y0) / (y1 - y0) - 0.4, 0, 1))
    t.line(d, 1.0, "#FFFFFF", 0.9)


def card(t, x0, y0, x1, y1, p, fill, edge, top):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 5, 5, 5, 5))
    t.paint(d, up.shade(t, fill, y0, y1))
    t.paint(d, p["glint"], 0.10 * np.exp(-np.maximum(t.y - y0, 0) / 16))
    down = np.clip(1 - (t.y - y0) / (y1 - y0), 0, 1)
    t.line(d, 1.0, edge, top * (0.45 + 0.55 * down))


def arc(t, p):
    """The Arc panel on Normal's first stretch, Hard shut."""
    whole = t.poly([(0, 0), (W, 0), (W, H), (0, H)])
    t.paint(whole, t.ramp(p["backing"][0], p["backing"][1], t.y / H))
    bx, by = 89.0, 153.0                                             # the bed's middle
    t.paint(whole, p["ground_bloom"][0], p["ground_bloom"][1] * np.exp(-(((t.x - bx) / 150) ** 2 + ((t.y - by) / 120) ** 2)))
    t.paint(whole, p["glint"], 0.06 * np.exp(-t.y / 40))
    # the band: Roblox's buttons (a stand-in), Back, the Arc's title
    up.box(t, 6, 8, 163, 50, p["channel"], p["edge"], 1.0, 6)
    t.text(84, 15, SMALL, "Roblox's", p["faint"], "CENTER")
    t.text(84, 31, SMALL, "buttons", p["faint"], "CENTER")
    up.box(t, 170, 7, 227, 50, p["channel"], p["edge"], 1.0, 5)
    t.text(198.5, 22, SMALL, "Back", p["text"], "CENTER", bold=0.3)
    t.stroke([(186, 46), (211, 46)], 1.4, p["panel_edge"], 0.7)
    t.text(236, 21, SMALL, "Festival of Battles", p["text"], bold=0.3)
    # the tile: the panel's glass, lit as the next one
    x0, y0, x1, y1 = 8, 71, 560, 266
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 6, 6, 6, 6))
    t.glow(d, 8.0, p["panel_glow"], 0.38)
    t.paint(d, up.shade(t, p["panel"], y0, y1))
    down = np.clip(1 - (t.y - y0) / ((y1 - y0) * 0.85), 0, 1)
    t.paint(d, p["glint"], 0.11 * np.exp(-np.maximum(t.y - y0, 0) / 24))
    t.paint(d, p["panel_edge"], 0.12 * down)
    t.line(d, 2.0, p["panel_edge"], 0.55 + 0.45 * down)
    # the bed, the keeper's picture on it, the ground's name under it
    b0, c0, b1, c1 = 14, 77, 164, 230
    d = t.poly(ui.cut_box(b0, c0, b1, c1, 4, 4, 4, 4))
    t.paint(d, up.shade(t, p["bed"], c0, c1))
    cx, cy = (b0 + b1) / 2, (c0 + c1) / 2 + 3
    wide, tall = (b1 - b0) * 0.38, (c1 - c0) * 0.42
    if p["bed_low"]:                       # its light pooled under it: wider, flatter, low on the bed
        pool = np.exp(-(((t.x - cx) / (wide * 1.5)) ** 2 + ((t.y - cy - (c1 - c0) * p["bed_low"]) / (tall * 0.62)) ** 2))
    else:
        pool = np.exp(-(((t.x - cx) / wide) ** 2 + ((t.y - cy - 8) / tall) ** 2))
    t.paint(d, p["bed_bloom"][0], p["bed_bloom"][1] * pool)
    t.line(d, 1.0, p["bed_edge"], 0.8)
    ss.picture(t, "lantern", cx, cy, 86 * 0.42 * 1.4)
    t.text(cx, 238, TITLE, "Lantern Row", p["text"], "CENTER", bold=0.3)
    # Normal: its name, what it recommends, the run's marks on their track, the lit way in
    n0, m0, n1, m1 = 171, 79, 553, 163
    card(t, n0, m0, n1, m1, p, p["button"], p["panel_edge"], 1.0)
    t.text(n0 + 12, m0 + 9, TITLE, "Normal", p["text"], bold=0.3)
    t.text(n1 - 12, m0 + 10, SMALL, "1,613 CR", p["text"], "RIGHT", bold=0.3)
    t.text(n1 - 76, m0 + 10, SMALL, "Recommended", p["soft"], "RIGHT")
    nodes = [202.0, 259.0, 318.0, 377.0]
    y = m0 + 60
    t.stroke([(nodes[0], y), (nodes[-1], y)], 5.0, p["channel"])
    for k, x in enumerate(nodes):
        if k == 0:
            lit_plate(t, x - 13, y - 13, x + 13, y + 13, p, glow=0.3)
        else:
            up.box(t, x - 13, y - 13, x + 13, y + 13, p["well"], p["edge"], 1.0, 5)
        t.text(x, y - 6.5, TITLE, str(k + 1), p["ink"] if k == 0 else p["soft"], "CENTER", bold=0.3)
    t.text(476, m0 + 34, SMALL, "Stretch 1 of 4", p["text"], "CENTER", bold=0.3)
    lit_plate(t, 409, m0 + 50, 543, m0 + 78, p)
    t.text(476, m0 + 58, SMALL, "Fight", p["ink"], "CENTER", bold=0.35)
    # Hard, shut: its chevrons, what it recommends, what opens it
    h0, k0, h1, k1 = 171, 172, 553, 257
    card(t, h0, k0, h1, k1, p, p["shut"], p["edge"], 0.9)
    ss.chevrons(t, h0 + 19, k0 + 19, 11, EMBER)
    t.text(h0 + 32, k0 + 10, TITLE, "Hard", p["soft"], bold=0.3)
    t.text(h1 - 12, k0 + 11, SMALL, "4,632 CR", p["soft"], "RIGHT", bold=0.3)
    t.text(h1 - 76, k0 + 11, SMALL, "Recommended", p["faint"], "RIGHT")
    ss.lock(t, h0 + 20, k0 + 59, 13, p["soft"])
    t.text(h0 + 38, k0 + 53, SMALL, "Beat the Lamplighter on Normal", p["soft"])
    # the foot: the player's power
    t.text(10, 297, SMALL, "Your power", p["soft"])
    t.text(92, 297, SMALL, "5,141 CR", p["text"], bold=0.3)


def main():
    out = bl.out_dir()
    ui.K = K
    gap, head, label = 12.0, 30.0, 22.0
    width = gap * 3 + W * 2
    height = head + 2 * (label + H + gap)
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 9, 15, "TR50's older line: the Arc panel's ground in the festival's dusk, at the smallest phone's pixels",
           "#EDE6D6", bold=0.2)
    for k, (_, p, words) in enumerate(TAKES):
        x = gap + (k % 2) * (W + gap)
        y = head + (k // 2) * (label + H + gap)
        t.text(x, y + 3, 13, words, "#B4AC9C")
        arc(sheet.tile(x, y + label, W, H), p)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "stage_arc_dusk.png")
    (out / "stage_arc_dusk.json").write_text(json.dumps({name: p for name, p, _ in TAKES}, indent=1))
    print(f"wrote {out / 'stage_arc_dusk.json'}")


if __name__ == "__main__":
    main()
