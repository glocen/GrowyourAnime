"""AR43, the director's word of 14:56: "i do not look like this green ui makeover i liked the old one before but maybe we
can use a bit more gradiant and animation and make it much better". The screens Home opens go back from AR40's C to
Seam, the screen's own palette (Config.UIKit's Palettes.Seam, the Voidkin screen's and the bag's). "Maybe" makes the
gradients and motion a blockout direction (research, 14:56), with research's measure: the gradients lift Seam (lighter
tops, lit edges, never a deeper fall to black), and one direction is clearly brighter than today's.

The blockout, on Reinforce's ready state at the smallest phone, drawn in code over equipment_pages' frame:
    A  Seam today, flat as the game's Voidkin screen.
    B  Lit glass: Seam's violet lifted at every top, hairlines lit from above, a bloom where the gear sits in its
       rarity's colour, the press a white-to-lavender gradient.
    C  Bright dusk: B's light on mid-violets, clearly brighter than today, a slow drift from magenta at the left to
       blue at the right, never teal.
Under them, the idle motion in four beats of its 2.4 s loop (B and C share it): a comet circling the ring, a sheen
crossing the lit press, a glint running down the chosen row's glass.

The director's word of 14:59, with a screenshot of another game's Equipment screen (kept out of the repo, for the
function only): "it would be cool for the left ui button to return to equipement be like this". Equipment's three
screens get a rail down the left again: Reinforce, Jewels and War Emblems as round buttons on one line, the chosen one
larger and lit with its word, switching between them. Back stays at the top left, to Home, and the band's title reads
Equipment. Drawn in every direction, in its palette; the marks are the shipped page icons.

    blender -b --factory-startup --python tools/blender/seam_rich.py -- <abs out>

Writes seam_rich.png. A blockout: nothing here is cut.
"""

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import equipment_pages as ep  # noqa: E402

W, H, SMALL, TITLE = up.W, up.H, up.SMALL, up.TITLE

SEAM = dict(up.SEAM)
LIT = dict(SEAM, backing=("#1F1942", "#0D0B1A"), panel=("#2F2758", "#16122C"), edge="#51477A", facet="#A89CD8",
           glint="#F0EAFF", soft="#C6BDE4", faint="#8279A6", channel="#0C0A1A", well=("#262044", "#17132E"),
           button=("#3C3268", "#251E46"), lit=("#FFFFFF", "#D4C6FF"), card=("#4C3E92", "#251D4C"))
DUSK = dict(SEAM, backing=("#3D3376", "#231D4C"), panel=("#4D4192", "#2F2764"), edge="#8D80CE", facet="#C4B8F4",
            glint="#FFFFFF", text="#FFFFFF", soft="#DDD5F8", faint="#AAA0D2", channel="#18133C",
            well=("#3B3176", "#2B245A"), button=("#5D4FA2", "#443980"), light="#F7F3FF", ink="#1A1433",
            lit=("#FFFFFF", "#DCD0FF"), card=("#7565C6", "#44388C"))
STYLES = {
    "A": dict(palette=SEAM, rich=False, words="A. Seam today, as the Voidkin screen"),
    "B": dict(palette=LIT, rich=True, bloom=("#5C48AC", 0.30), sheen=0.11, drift=None,
              words="B. Lit glass: Seam lifted at every top, lit edges, the rarity's bloom"),
    "C": dict(palette=DUSK, rich=True, bloom=("#8C6CE2", 0.22), sheen=0.15, drift=("#8A3FB8", "#3E62D0"),
              words="C. Bright dusk: B's light on mid-violets, magenta drifting to blue"),
}
NOW = dict(style=STYLES["A"], phase=0.0, rarity="Rare")
ORIG = dict(panel=up.panel, tab_glass=up.tab_glass, ring=up.ring, press=up.press, work=up.work, frame=ep.frame)
LOOP = 2.4                                    # the idle loop, seconds


def rich():
    return NOW["style"]["rich"]


def frame(t, name):
    if not rich():
        return ORIG["frame"](t, name)
    P, s = up.P, NOW["style"]
    whole = t.poly([(0, 0), (W, 0), (W, H), (0, H)])
    t.paint(whole, t.ramp(P["backing"][0], P["backing"][1], t.y / H))
    if s["drift"]:
        t.paint(whole, s["drift"][0], 0.26 * np.clip(1 - t.x / W, 0, 1) ** 1.5)
        t.paint(whole, s["drift"][1], 0.24 * np.clip(t.x / W, 0, 1) ** 1.5)
    colour, strength = s["bloom"]
    t.paint(whole, colour, strength * np.exp(-(((t.x - 433) / 150) ** 2 + ((t.y - 150) / 120) ** 2)))
    t.paint(whole, P["glint"], 0.06 * np.exp(-t.y / 40))
    up.band(t, "Equipment")
    t.text(232, 20, TITLE, name, P["text"], bold=0.35)


def panel(t, x0, y0, x1, y1):
    if not rich():
        return ORIG["panel"](t, x0, y0, x1, y1)
    P = up.P
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 8, 0, 8, 0))
    t.paint(d, up.shade(t, P["panel"], y0, y1))
    t.paint(d, P["glint"], NOW["style"]["sheen"] * np.exp(-np.maximum(t.y - y0, 0) / 24))
    down = np.clip(1 - (t.y - y0) / ((y1 - y0) * 0.85), 0, 1)
    t.line(d, 1.0, P["facet"], 0.3 + 0.6 * down)
    t.line(d, 1.3, P["glint"], 0.85 * np.exp(-np.hypot(t.x - x0 - 24, t.y - y0) / 46))
    return d


def tab_glass(t, x0, y0, x1, y1):
    if not rich():
        return ORIG["tab_glass"](t, x0, y0, x1, y1)
    P = up.P
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 6, 0, 0, 0))
    t.glow(d, 7.0, P["light"], 0.10)
    t.paint(d, up.shade(t, P["card"], y0, y1))
    t.paint(d, P["light"], np.clip((t.x - x0) / (x1 - x0), 0, 1) ** 1.6 * 0.30)
    t.paint(d, P["glint"], 0.16 * np.exp(-np.maximum(t.y - y0, 0) / 9))
    # the idle glint, running down the glass's length once a loop
    at = x0 - 40 + (x1 - x0 + 80) * NOW["phase"]
    t.paint(d, P["glint"], 0.20 * np.exp(-(((t.x - at) - (t.y - y0) * 0.6) / 9) ** 2))
    t.line(d, 1.0, P["facet"], 0.9)
    t.glow(t.poly([(x1 - 1.5, y0), (x1 + 1.5, y0), (x1 + 1.5, y1), (x1 - 1.5, y1)]), 3.5, P["light"], 0.6)
    t.stroke([(x1, y0), (x1, y1)], 2.4, P["light"])


def ring(t, cx, cy, r, lit):
    if not rich():
        return ORIG["ring"](t, cx, cy, r, lit)
    P = up.P
    rim = up.RIM[NOW["rarity"]]
    dist = np.hypot(t.x - cx, t.y - cy)
    d = dist - r
    whole = t.poly([(cx - r - 20, cy - r - 20), (cx + r + 20, cy - r - 20), (cx + r + 20, cy + r + 20),
                    (cx - r - 20, cy + r + 20)])
    t.paint(whole, lit or rim, 0.34 * np.exp(-(dist / (r * 0.85)) ** 2))
    ang = np.arctan2(t.y - cy, t.x - cx)
    top = (1 - np.sin(ang)) / 2                       # 1 at the top, 0 at the foot
    t.line(d, 1.8, lit or P["light"], 0.35 + 0.6 * top)
    t.line(d - 4, 1.0, P["facet"], 0.25 + 0.4 * top)
    head = -math.pi / 2 + 2 * math.pi * NOW["phase"]  # the comet, clockwise from the top
    behind = np.mod(head - ang, 2 * math.pi)          # 0 at the head, growing along its tail
    tail = np.where(behind < 1.4, np.exp(-behind * 2.6), 0.0)
    t.line(d + 0.2, 2.6, P["glint"], 0.95 * tail)
    hx, hy = cx + r * math.cos(head), cy + r * math.sin(head)
    t.glow(t.poly([(hx - 1, hy - 1), (hx + 1, hy - 1), (hx + 1, hy + 1), (hx - 1, hy + 1)]), 3.5, P["glint"], 0.75)


def press(t, x0, y0, x1, y1, words, kind="one"):
    if not rich() or kind != "one":
        return ORIG["press"](t, x0, y0, x1, y1, words, kind)
    P = up.P
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 5, 5, 5, 5))
    t.glow(d, 7.0, P["lit"][1], 0.45)
    t.paint(d, up.shade(t, P["lit"], y0, y1))
    at = x0 - 30 + (x1 - x0 + 60) * NOW["phase"]      # the sheen, crossing once a loop
    t.paint(d, "#FFFFFF", 0.75 * np.exp(-(((t.x - at) + (t.y - y0) * 0.5) / 6) ** 2))
    t.paint(d, P["lit"][1], 0.35 * np.clip((t.y - y0) / (y1 - y0) - 0.4, 0, 1))
    t.line(d, 1.0, "#FFFFFF", 0.9)
    t.text((x0 + x1) / 2, (y0 + y1) / 2 - 5, SMALL, words, P["ink"], "CENTER", bold=0.3)


RAIL_X, RAIL_TOP, RAIL_FOOT = 44, 66, 306
RAIL = [("Reinforce", 104), ("Jewels", 186), ("War Emblems", 262)]
LIST, WORK = (88, 300), (306, 560)


def rail(t, chosen):
    """Equipment's screens down the left on one line: each a round button, its outer ring broken where the kit cuts its
    corners (top left, foot right); the chosen one larger, its glass lit, its word bright, the comet on its ring."""
    P = up.P
    size = {name: (27.0 if name == chosen else 20.0) for name, _ in RAIL}
    spans, y = [], RAIL_TOP                          # the line runs between the buttons, never through a word
    for name, cy in RAIL:
        spans.append(((RAIL_X, y), (RAIL_X, cy - size[name])))
        y = cy + size[name] + 7 + (16 if name == chosen else SMALL) + 4
    line = np.minimum.reduce([ui.sd_segment(t.x, t.y, a, b) for a, b in spans if b[1] > a[1]]) - 0.6
    t.paint(line, P["facet"], 0.45)
    if rich():
        at = RAIL_TOP + (RAIL_FOOT - RAIL_TOP) * NOW["phase"]   # a light running down the line once a loop
        t.paint(line - 0.4, P["glint"], 0.85 * np.exp(-((t.y - at) / 16) ** 2))
    for name, cy in RAIL:
        big = name == chosen
        r = size[name]
        dist = np.hypot(t.x - RAIL_X, t.y - cy)
        d = dist - r
        if big:
            t.glow(d, 8.0, P["light"], 0.22 if rich() else 0.14)
        fill = P["card"] if big else P["button"]
        t.paint(d, t.ramp(fill[0], fill[1], (t.y - cy + r) / (2 * r)))
        if rich():
            t.paint(d, P["glint"], (0.22 if big else 0.12) * np.exp(-np.maximum(t.y - cy + r, 0) / (r * 0.45)))
            if big:
                t.paint(d, P["light"], 0.18 * np.clip((t.x - RAIL_X + r) / (2 * r), 0, 1) ** 2)
        ang = np.arctan2(t.y - cy, t.x - RAIL_X)
        wrap = lambda a: np.abs(np.mod(a + np.pi, 2 * np.pi) - np.pi)
        whole = np.where((wrap(ang + 3 * np.pi / 4) < 0.3) | (wrap(ang - np.pi / 4) < 0.3), 0.0, 1.0)
        top = (1 - np.sin(ang)) / 2
        rim_alpha = (0.45 + 0.5 * top) if rich() else 0.9
        t.line(d - 3.5, 1.6 if big else 1.0, P["light"] if big else P["facet"], whole * rim_alpha)
        t.line(d, 1.0, P["facet"] if big else P["edge"], 0.8)
        up.mark(t, name, RAIL_X, cy, r * 1.05, P["glint"] if big else P["soft"])
        t.text(RAIL_X, cy + r + 7, 16 if big else SMALL, name, P["light"] if big else P["soft"], "CENTER",
               bold=0.35 if big else 0.15)
        if big and rich():
            head = -np.pi / 2 + 2 * np.pi * NOW["phase"]
            behind = np.mod(head - ang, 2 * np.pi)
            t.line(d - 3.3, 2.2, P["glint"], 0.9 * np.where(behind < 1.4, np.exp(-behind * 2.6), 0.0) * whole)


def phone(sheet, ox, oy, st, page="Reinforce"):
    t = sheet.tile(ox, oy, W, H)
    ep.frame(t, "Equipment")
    rail(t, page)
    up.gear_list(t, st, *LIST)
    up.work(t, st, *WORK)


def work(t, st, x0, x1):
    NOW["rarity"] = next(w for w in up.WORN if w[0] == st["slot"])[2]
    return ORIG["work"](t, st, x0, x1)


up.panel, up.tab_glass, up.ring, up.press, up.work, ep.frame = panel, tab_glass, ring, press, work, frame


def use(key, phase=0.0):
    NOW.update(style=STYLES[key], phase=phase)
    up.P.clear()
    up.P.update(STYLES[key]["palette"])
    up._pics.clear()


def render(key, phase=0.0):
    """One phone at the sheet's pixels, its words drawn in."""
    use(key, phase)
    sheet = ui.Sheet(W, H, "#000000")
    phone(sheet, 0, 0, dict(ep.REINFORCE_STATES[0][1]))
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


def main():
    out = bl.out_dir()
    ui.K = K = 2
    gap, head = 24, 64
    crop = (0, 56, 568, 316)                         # the rail, the chosen row and the work, for the idle beats
    cw, ch = crop[2] - crop[0], crop[3] - crop[1]
    width = gap + 3 * (W + gap)
    across = 3                                       # the idle's beats, three a row
    strips_y = head + H + 56
    height = strips_y + 2 * (ch + 48) + 150
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, "AR43, Equipment back in Seam, richer, with its rail down the left: three directions at the "
                        "smallest phone (568 x 320), on the director's words of 14:56 and 14:59", "#EDE6D6", bold=0.2)
    for n, key in enumerate("ABC"):
        x = gap + n * (W + gap)
        t.text(x, head - 4, SMALL, STYLES[key]["words"], "#B4AC9C")
        rs.paste(sheet.px, render(key), round(x * K), round((head + 16) * K))
    for row, key in enumerate("BC"):
        for k, phase in enumerate((0.1, 0.43, 0.76)):
            y = strips_y + row * (ch + 48)
            if k == 0:
                t.text(gap, y - 4, SMALL, f"{key}'s idle, a {LOOP:g} s loop: the comet circles the ring and the chosen "
                                          "button, the sheen crosses the press, a glint runs down the chosen row, a "
                                          "light runs down the rail", "#B4AC9C")
            px = render(key, phase)
            x = gap + (k % across) * (W + gap)
            part = px[crop[1] * K:crop[3] * K, crop[0] * K:crop[2] * K]
            rs.paste(sheet.px, part, round(x * K), round((y + 16) * K))
            t.text(x + 4, y + 20 + ch, SMALL, f"{phase * LOOP:.2f} s", "#8E8676")
    notes = [
        "The motion beyond the idle, for the picked direction's strips: the screen rises 12 points as it fades in over "
        "0.22 s (out3); the rows cascade",
        "in from 24 points left, 0.035 s apart; the work's ring draws round once (0.3 s) as the gear pops in (Pop); "
        "a row tapped slides the glass to it. A rail button tapped grows to its size (0.18 s, Back 1.2) as the last "
        "one shrinks, and the work crossfades.",
        "Every colour stays violet: no teal or green but the rise's own green. The press, the levels and the item's "
        "rarity carry the light; the panels",
        "lift toward their tops so nothing reads as a black fall. Rates are research's seeds; every other number is a "
        "stand-in.",
    ]
    for n, words in enumerate(notes):
        t.text(gap + 8, height - 130 + n * 24, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "seam_rich.png")


if __name__ == "__main__":
    main()
