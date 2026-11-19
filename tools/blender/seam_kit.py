"""AR43: Seam's lit glass, the kit every screen Home opens wears (the director, 2026-11-19, 14:56 and 14:59; research's
verdict B, 15:04). Seam, the screen's own palette (Config.UIKit's Palettes.Seam), lifted: every panel lighter at its
top, its hairline lit from above, a bloom in the item's rarity behind the work, the lit press white falling to
lavender, and an idle loop (a comet round the ring and the chosen rail button, a sheen across the press, a glint down
the chosen row, a light down the rail). Equipment's rail of its three screens down the left (14:59).

`wear(key, phase)` puts a direction's drawing onto upgrade_pages' kit: "B" is the game's; "A" (Seam today, flat) and
"C" (bright dusk) are the blockout's (seam_rich.py). Drawn in code; nothing here is exported.
"""

import math

import numpy as np

import ui_sheet as ui
import upgrade_pages as up

W, H, SMALL = up.W, up.H, up.SMALL

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
SOCKET_DARK = ("#0E0B1A", "#08070F")          # a socket's well and an item cell's: violet-black, never teal
LOOP = 2.4                                    # the idle loop, seconds
BLOOM_AT, BLOOM_SIZE = (433, 150), (150, 120)  # the work's bloom: its middle and its two radii, in points
NOW = dict(style=STYLES["B"], phase=0.0, rarity="Rare")
ORIG = dict(panel=up.panel, tab_glass=up.tab_glass, ring=up.ring, press=up.press, work=up.work)


def rich():
    return NOW["style"]["rich"]


def backdrop(t, bloom_at=BLOOM_AT):
    """The screen's ground under its band: Seam's backing falling from a lifted top, a bloom behind the work, a faint
    light along the top edge; C's drift."""
    P, s = up.P, NOW["style"]
    if not rich():
        return up.box(t, 0, 0, W, H, P["backing"], cut=0)
    whole = t.poly([(0, 0), (W, 0), (W, H), (0, H)])
    t.paint(whole, t.ramp(P["backing"][0], P["backing"][1], t.y / H))
    if s["drift"]:
        t.paint(whole, s["drift"][0], 0.26 * np.clip(1 - t.x / W, 0, 1) ** 1.5)
        t.paint(whole, s["drift"][1], 0.24 * np.clip(t.x / W, 0, 1) ** 1.5)
    colour, strength = s["bloom"]
    (bx, by), (rx, ry) = bloom_at, BLOOM_SIZE
    t.paint(whole, colour, strength * np.exp(-(((t.x - bx) / rx) ** 2 + ((t.y - by) / ry) ** 2)))
    t.paint(whole, P["glint"], 0.06 * np.exp(-t.y / 40))


def panel(t, x0, y0, x1, y1, cuts=(8, 0, 8, 0)):
    """`cuts`: the sheets' corners; the cut's fit draws it on the kit's PanelFill corners (seam_cut.KIT_CUTS)."""
    if not rich():
        return ORIG["panel"](t, x0, y0, x1, y1)
    P = up.P
    d = t.poly(ui.cut_box(x0, y0, x1, y1, *cuts))
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
    at = x0 - 40 + (x1 - x0 + 80) * NOW["phase"]      # the idle glint, down the glass's length once a loop
    t.paint(d, P["glint"], 0.20 * np.exp(-(((t.x - at) - (t.y - y0) * 0.6) / 9) ** 2))
    t.line(d, 1.0, P["facet"], 0.9)
    t.glow(t.poly([(x1 - 1.5, y0), (x1 + 1.5, y0), (x1 + 1.5, y1), (x1 - 1.5, y1)]), 3.5, P["light"], 0.6)
    t.stroke([(x1, y0), (x1, y1)], 2.4, P["light"])


def comet(t, d, ang, width, alpha=1.0):
    """The idle comet on a ring: its head at the loop's phase, clockwise from the top, its tail fading behind it."""
    head = -math.pi / 2 + 2 * math.pi * NOW["phase"]
    behind = np.mod(head - ang, 2 * math.pi)
    t.line(d, width, up.P["glint"], 0.95 * alpha * np.where(behind < 1.4, np.exp(-behind * 2.6), 0.0))
    return head


def ring(t, cx, cy, r, lit):
    if not rich():
        return ORIG["ring"](t, cx, cy, r, lit)
    P = up.P
    dist = np.hypot(t.x - cx, t.y - cy)
    d = dist - r
    whole = t.poly([(cx - r - 20, cy - r - 20), (cx + r + 20, cy - r - 20), (cx + r + 20, cy + r + 20),
                    (cx - r - 20, cy + r + 20)])
    t.paint(whole, lit or up.RIM[NOW["rarity"]], 0.34 * np.exp(-(dist / (r * 0.85)) ** 2))
    ang = np.arctan2(t.y - cy, t.x - cx)
    top = (1 - np.sin(ang)) / 2                       # 1 at the top, 0 at the foot
    t.line(d, 1.8, lit or P["light"], 0.35 + 0.6 * top)
    t.line(d - 4, 1.0, P["facet"], 0.25 + 0.4 * top)
    head = comet(t, d + 0.2, ang, 2.6)
    hx, hy = cx + r * math.cos(head), cy + r * math.sin(head)
    t.glow(t.poly([(hx - 1, hy - 1), (hx + 1, hy - 1), (hx + 1, hy + 1), (hx - 1, hy + 1)]), 3.5, P["glint"], 0.75)


def press(t, x0, y0, x1, y1, words, kind="one"):
    if not rich() or kind != "one":
        return ORIG["press"](t, x0, y0, x1, y1, words, kind)
    P = up.P
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 5, 5, 5, 5))
    t.glow(d, 7.0, P["lit"][1], 0.45)
    t.paint(d, up.shade(t, P["lit"], y0, y1))
    at = x0 - 30 + (x1 - x0 + 60) * NOW["phase"]      # the sheen, across once a loop
    t.paint(d, "#FFFFFF", 0.75 * np.exp(-(((t.x - at) + (t.y - y0) * 0.5) / 6) ** 2))
    t.paint(d, P["lit"][1], 0.35 * np.clip((t.y - y0) / (y1 - y0) - 0.4, 0, 1))
    t.line(d, 1.0, "#FFFFFF", 0.9)
    t.text((x0 + x1) / 2, (y0 + y1) / 2 - 5, SMALL, words, P["ink"], "CENTER", bold=0.3)


def work(t, st, x0, x1):
    NOW["rarity"] = next(w for w in up.WORN if w[0] == st["slot"])[2]
    return ORIG["work"](t, st, x0, x1)


KNOB_R, KNOB_R_HELD = 10.0, 12.5               # a slider's knob at rest and held


def slider(t, x0, x1, cy, value, held=False):
    """A conduit filling with light to the value (the kit's bars: docs/ui.md, rule 3), its knob a disc of the lit
    press's white falling to lavender; held, the knob grows, its ring lights and the fill brightens."""
    P = up.P
    at = x0 + (x1 - x0) * value
    track = t.poly(ui.cut_box(x0, cy - 4, x1, cy + 4, 3, 3, 3, 3))
    t.paint(track, P["channel"])
    t.line(track, 1.0, P["edge"], 0.9)
    if at > x0 + 2:
        fill = t.poly(ui.cut_box(x0 + 1, cy - 3, at, cy + 3, 2, 0, 2, 0))
        t.paint(fill, t.ramp(P["facet"], P["light"], np.clip((t.x - x0) / max(at - x0, 1), 0, 1)))
        t.paint(fill, "#FFFFFF", (0.45 if held else 0.25) * np.exp(-np.maximum(t.y - cy + 3, 0) / 1.5))
        t.glow(fill, 4.0, P["light"], 0.30 if held else 0.14)
    r = KNOB_R_HELD if held else KNOB_R
    knob = np.hypot(t.x - at, t.y - cy) - r
    t.glow(knob, 6.0, P["lit"][1], 0.65 if held else 0.35)
    t.paint(knob, up.shade(t, P["lit"], cy - r, cy + r))
    t.paint(knob, "#FFFFFF", 0.6 * np.exp(-np.maximum(t.y - cy + r, 0) / (r * 0.35)))
    t.line(knob, 1.0, P["facet"], 0.9)
    if held:
        t.line(knob - 4.5, 1.4, P["light"], 0.85)


# --- Equipment's rail (the director, 14:59) -------------------------------------------------------------------------

RAIL_X, RAIL_TOP, RAIL_FOOT = 48, 66, 306
RAIL = [("Reinforce", 104), ("Jewels", 186), ("War Emblems", 262)]
RAIL_R, RAIL_R_CHOSEN, RAIL_WORD, RAIL_WORD_CHOSEN = 20.0, 27.0, SMALL, 15
LIST = (98, 300)              # the list, right of the rail: "War Emblems" lit at 15 bold spans ~86 of its 96 points


def rail_spans(chosen, size):
    """The rail's line, (top, foot) pieces between the buttons: it never runs through a button or a word."""
    spans, y = [], RAIL_TOP
    for name, cy in RAIL:
        spans.append((y, cy - size[name]))
        y = cy + size[name] + 7 + (RAIL_WORD_CHOSEN if name == chosen else RAIL_WORD) + 4
    return [(a, b) for a, b in spans if b > a]


def rail(t, chosen):
    """Equipment's screens down the left on one line: each a round button, its outer ring broken where the kit cuts its
    corners (top left, foot right); the chosen one larger, its glass lit, its word bright, the comet on its ring."""
    P = up.P
    size = NOW.get("sizes") or {name: (RAIL_R_CHOSEN if name == chosen else RAIL_R) for name, _ in RAIL}
    line = np.minimum.reduce([ui.sd_segment(t.x, t.y, (RAIL_X, a), (RAIL_X, b))
                              for a, b in rail_spans(chosen, size)]) - 0.6
    t.paint(line, P["facet"], 0.45)
    if rich():
        at = RAIL_TOP + (RAIL_FOOT - RAIL_TOP) * NOW["phase"]   # a light down the line once a loop
        t.paint(line - 0.4, P["glint"], 0.85 * np.exp(-((t.y - at) / 16) ** 2))
    for name, cy in RAIL:
        big = name == chosen
        r = size[name]
        d = np.hypot(t.x - RAIL_X, t.y - cy) - r
        if big:
            t.glow(d, 8.0, P["light"], 0.22 if rich() else 0.14)
        fill = P["card"] if big else P["button"]
        t.paint(d, t.ramp(fill[0], fill[1], (t.y - cy + r) / (2 * r)))
        if rich():
            t.paint(d, P["glint"], (0.22 if big else 0.12) * np.exp(-np.maximum(t.y - cy + r, 0) / (r * 0.45)))
            if big:
                t.paint(d, P["light"], 0.18 * np.clip((t.x - RAIL_X + r) / (2 * r), 0, 1) ** 2)
        ang = np.arctan2(t.y - cy, t.x - RAIL_X)
        wrap = lambda a: np.abs(np.mod(a + np.pi, 2 * np.pi) - np.pi)  # noqa: E731
        whole = np.where((wrap(ang + 3 * np.pi / 4) < 0.3) | (wrap(ang - np.pi / 4) < 0.3), 0.0, 1.0)
        top = (1 - np.sin(ang)) / 2
        rim_alpha = (0.45 + 0.5 * top) if rich() else 0.9
        t.line(d - 3.5, 1.6 if big else 1.0, P["light"] if big else P["facet"], whole * rim_alpha)
        t.line(d, 1.0, P["facet"] if big else P["edge"], 0.8)
        up.mark(t, name, RAIL_X, cy, r * 1.05, P["glint"] if big else P["soft"])
        t.text(RAIL_X, cy + r + 7, RAIL_WORD_CHOSEN if big else RAIL_WORD, name, P["light"] if big else P["soft"],
               "CENTER", bold=0.35 if big else 0.15)
        if big and rich():
            comet(t, d - 3.3, ang, 2.2, whole * 0.95)


def wear(key="B", phase=0.0):
    """Puts a direction's drawing and palette onto upgrade_pages' kit, in place (up.P stays the same dict)."""
    NOW.update(style=STYLES[key], phase=phase)
    up.P.clear()
    up.P.update(STYLES[key]["palette"])
    up.panel, up.tab_glass, up.ring, up.press, up.work = panel, tab_glass, ring, press, work
    up._pics.clear()
