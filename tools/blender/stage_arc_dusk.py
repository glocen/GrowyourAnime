"""TR50's older line (research, 2026-11-20, 00:11; class: every art tile's ground): the Arc panel's lantern stands on a
violet field, and the picker's whole screen on a violet ground with a lavender glow. Both take the festival's dusk, warm
under the lantern. A colour block-in for research's pick: the Arc panel as it stands today, beside three steps of dusk.

    blender -b --factory-startup --python tools/blender/stage_arc_dusk.py -- <abs out> [take]

With a take's name (B, B_KIT), it also writes arc_dusk.json: that take for Faber, each colour under the name Config
keeps it by today, and what has no home there yet.

Writes stage_arc_dusk.png (the four at the smallest phone's own pixels, 1.5 a point), stage_arc_dusk.json (each
direction's colours) and, on research's pick of B (2026-11-23, 00:19), stage_arc_dusk_follow.png: what follows from B,
today's beside it. Hard open on the panel, the results card over the street, the run's line in the HUD. Its third
column is B with Normal's own lights left Seam's (B_KIT): B's cream plates and road ran into Hard's coral and Ready's
gold once Hard was open, on the card and on the line.

The panel is laid from Config.Hud's Stages (Tile, Bed, Arc) and Faber's capture of TR50 (build/captures/tr50/
fix-panel.png): a stand-in for the game's own layout, drawn for its colours only. The lantern is stage_screen.py's, as
stage_cut.py cut it. The steps, each over the one before:
    A  the bed only: the lantern's field is the dusk street, dark over the lantern and warm under it.
    B  and the ground: the screen behind the glass, the light round the panel, and Normal's lit plates in lantern light.
       The glass stays Seam's (the director's scope of 2026-11-19, 14:56: the picker in Seam).
    C  and the glass: the panel, its cards and its words in rosewood. Past the 14:56 scope, shown to be judged.
The lantern's own gold needs a dark field behind it, so the warmth pools under it, where its light would fall, never
behind its paper.

The card and the line have no ground of their own: they stand over the street (the card over it dimmed, the line in the
HUD). So the follow sheet draws them over a stand-in of Lantern Row's dusk in lantern_row_look's colours, with
stage_seam.py's pieces (AR42's, the game's layout since moved a little: drawn for their colours only).
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
import seam_kit as sk  # noqa: E402
import stage_screen as ss  # noqa: E402
import stage_seam as sq  # noqa: E402  (on import: the lantern's Seam colours, as the cut picture has them)

W, H = ss.W, ss.H
SMALL, TITLE = ss.SMALL, ss.TITLE
K = 1.5                                   # the smallest phone's pixels a point
POOL = (1.5, 0.62)                        # the lantern's light pooled low: as wide, as tall as the bloom it replaces
HARD = dict(sq.ACC[True])                 # Hard's ember, unchanged
EMBER = HARD["edge"]

TODAY = dict(
    backing=("#1F1942", "#0D0B1A"), ground_bloom=("#5C48AC", 0.30),
    panel=("#2F2758", "#16122C"), panel_glow="#D4C6FF", panel_edge="#EDE4FF",
    bed=("#0E0B1A", "#08070F"), bed_bloom=("#5C48AC", 0.75), bed_low=0.0, bed_edge="#51477A",
    button=("#3C3268", "#251E46"), shut=("#1C1834", "#110E20"), edge="#51477A", facet="#A89CD8", glint="#F0EAFF",
    well="#262044", channel="#0C0A1A", text="#F1ECFF", soft="#C6BDE4", faint="#8279A6", ink="#0B0913",
    lit=("#FFFFFF", "#D4C6FF"), lit_glow="#D4C6FF", road=("#A89CD8", "#EDE4FF"), accent="#EDE4FF",
    cover="#1F1942")                      # the results card's cover over the street, at Card.Dim (SeamGlass.Backing)
# A: the bed is the dusk street. Dark wine over the lantern, rosewood at its foot, the lantern's light pooled low.
A = dict(TODAY, bed=("#1E0F16", "#4A2324"), bed_bloom=("#FF9A50", 0.62), bed_low=0.36, bed_edge="#7A5048")
# B: the ground behind the glass and every light on it. The glass keeps Seam's violet.
# (The first take's ground, #3E1F26 to #170C0F, read as a dull maroon: the street's dusk is rose, so it leans rose.)
B = dict(A, backing=("#5E2A3A", "#1E0E12"), ground_bloom=("#FF8246", 0.38), panel_glow="#FFCF98",
         panel_edge="#FFEBD2", lit=("#FFFFFF", "#FFE0B4"), lit_glow="#FFCF98", road=("#DCA070", "#FFEBD2"),
         accent="#FFEBD2", cover="#2A1219")
# B, with Normal's own lights left the kit's: its lit plates, its marks, its road, its card's edge. The dusk keeps the
# ground, the bed, the light round the panel and the card's cover.
B_KIT = dict(B, **{k: TODAY[k] for k in ("lit", "lit_glow", "road", "accent")})
# C: the glass in rosewood, its words in ivory.
C = dict(B, panel=("#6A3A44", "#30191F"), button=("#7A4650", "#48282E"), shut=("#38202A", "#201216"),
         edge="#8E6062", facet="#E4B4A0", glint="#FFF0E0", well="#48282E", channel="#180C0E", text="#FFF4E8",
         soft="#E8CEC0", faint="#B09090", ink="#1A0E10")
TAKES = [("Today", TODAY, "Today: Seam's violet under everything"),
         ("A", A, "A. The bed only: the lantern on the dusk street, warm under it"),
         ("B", B, "B. And the ground: the screen behind the glass, the panel's light, Normal's lit plates"),
         ("C", C, "C. And the glass: rosewood, ivory words (past the 14:56 scope)")]


def card(t, x0, y0, x1, y1, p, fill, edge, top):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 5, 5, 5, 5))
    t.paint(d, up.shade(t, fill, y0, y1))
    t.paint(d, p["glint"], 0.10 * np.exp(-np.maximum(t.y - y0, 0) / 16))
    down = np.clip(1 - (t.y - y0) / (y1 - y0), 0, 1)
    t.line(d, 1.0, edge, top * (0.45 + 0.55 * down))


def wear(p):
    """stage_seam's pieces in a take's colours: its glass, and Normal's light."""
    sq.P = dict(sk.LIT, **{k: p[k] for k in ("button", "edge", "facet", "glint", "well", "channel", "text", "soft",
                                             "faint", "ink")})
    sq.TILE = p["panel"]
    sq.ACC = {False: dict(edge=p["accent"], lit=p["lit"], road=p["road"], bloom=p["bed_bloom"][0],
                          glow=p["lit_glow"]), True: HARD}


def choice(t, p, x0, y0, x1, y1, hard, power, at):
    """One difficulty's card on the panel: open at stretch `at` (its marks, where the run starts, the lit way in), or
    shut (None: its lock and why)."""
    shut = at is None
    edge = p["edge"] if shut else (EMBER if hard else p["accent"])
    card(t, x0, y0, x1, y1, p, p["shut"] if shut else p["button"], edge, 0.9 if shut else 1.0)
    words = p["soft"] if shut else p["text"]
    if hard:
        ss.chevrons(t, x0 + 19, y0 + 19, 11, EMBER)
    t.text(x0 + (32 if hard else 12), y0 + 9, TITLE, "Hard" if hard else "Normal", words, bold=0.3)
    t.text(x1 - 12, y0 + 10, SMALL, power, words, "RIGHT", bold=0.3)
    t.text(x1 - 76, y0 + 10, SMALL, "Recommended", p["faint"] if shut else p["soft"], "RIGHT")
    if shut:
        ss.lock(t, x0 + 20, y0 + 59, 13, p["soft"])
        t.text(x0 + 38, y0 + 53, SMALL, "Beat the Lamplighter on Normal", p["soft"])
        return
    rows = ["cleared" if k < at else "next" if k == at else "shut" for k in range(1, 5)]
    sq.marks(t, x0 + 12, x0 + 226, y0 + 60, rows, hard)
    t.text((x0 + 238 + x1 - 12) / 2, y0 + 34, SMALL, f"Stretch {at} of 4", p["text"], "CENTER", bold=0.3)
    sq.press(t, x0 + 238, y0 + 50, x1 - 12, y0 + 78, "Continue" if at > 1 else "Fight", "one", hard)


def arc(t, p, normal=1, hard=None):
    """The Arc panel: Normal at its stretch, Hard at its own or shut (None)."""
    wear(p)
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
        low = cy + (c1 - c0) * p["bed_low"]
        pool = np.exp(-(((t.x - cx) / (wide * POOL[0])) ** 2 + ((t.y - low) / (tall * POOL[1])) ** 2))
    else:
        pool = np.exp(-(((t.x - cx) / wide) ** 2 + ((t.y - cy - 8) / tall) ** 2))
    t.paint(d, p["bed_bloom"][0], p["bed_bloom"][1] * pool)
    t.line(d, 1.0, p["bed_edge"], 0.8)
    ss.picture(t, "lantern", cx, cy, 86 * 0.42 * 1.4)
    t.text(cx, 238, TITLE, "Lantern Row", p["text"], "CENTER", bold=0.3)
    choice(t, p, 171, 79, 553, 163, False, "1,613 CR", normal)
    choice(t, p, 171, 172, 553, 257, True, "4,632 CR", hard)
    # the foot: the player's power
    t.text(10, 297, SMALL, "Your power", p["soft"])
    t.text(92, 297, SMALL, "5,141 CR", p["text"], bold=0.3)


def street(t):
    """Lantern Row at its dusk, behind the HUD: a stand-in in lantern_row_look's colours, laid for the whole phone (a
    strip shows its top). Busy on purpose."""
    w = t.w
    t.px[..., :3], t.px[..., 3] = t.ramp("#E9A0B4", "#F6B098", t.y / (H * 0.66)), 1.0
    t.glow(np.hypot(t.x - w * 0.68, (t.y - H * 0.6) * 1.8) - 24, 70.0, "#FFBE8A", 0.6)
    t.paint(H * 0.66 - t.y, t.ramp("#9A6E66", "#5E3A3C", (t.y - H * 0.66) / (H * 0.34)))
    rng = np.random.default_rng(7)
    x = -20.0
    while x < w:
        sw, sh = rng.uniform(46, 90), rng.uniform(0.3, 0.52) * H
        top = H * 0.66 - sh
        body = ui.c(("#9A6248", "#6E4238", "#4E2E33")[int(rng.integers(3))])
        t.paint(t.poly(ui.cut_box(x, top, x + sw, H * 0.66)), body)
        t.paint(t.poly([(x - 5, top + 8), (x + sw + 5, top + 8), (x + sw, top - 4), (x, top - 4)]),
                body * 0.7 + 0.3 * ui.c("#FFE7B8"))
        lx, ly = x + sw * 0.5, top + 20
        t.glow(np.hypot(t.x - lx, t.y - ly) - 3, 16.0, "#FFD9A0", 0.55)
        t.paint(np.hypot(t.x - lx, t.y - ly) - 3.5, "#FFE7B8")
        x += sw + rng.uniform(4, 16)


def card_over(t, p, st):
    """The results card over the street dimmed under it (Card.Dim: the cover at half)."""
    wear(p)
    street(t)
    t.paint(np.full_like(t.x, -1.0), p["cover"], 0.5)
    sq.stand_in(t)
    sq.results(t, st)


def line_over(t, p, st):
    """The run's line in the HUD, over the street."""
    wear(p)
    street(t)
    sq.stand_in(t)
    sq.stage_line(t, st)


def write(sheet, path):
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, path)


def follow(out):
    """What follows from B: Hard open on the panel, the cards, the line. Today's, B, and B with Seam's lights."""
    gap, head, label = 12.0, 30.0, 22.0
    rows = [("The panel, later: Normal at its third stretch, Hard open", H, lambda t, p: arc(t, p, 3, 1))]
    for k in (0, 1, 2):
        words, st = ss.CARDS[k]
        rows.append((f"The card. {words}", H, lambda t, p, st=st: card_over(t, p, st)))
    for k in (0, 2):
        words, st = ss.LINES[k]
        rows.append((f"The line. {words}", sq.LINE_H, lambda t, p, st=st: line_over(t, p, st)))
    takes = (TODAY, B, B_KIT)
    width = gap + (W + gap) * len(takes)
    height = head + sum(label + tall + gap for _, tall, _ in rows)
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 9, 15, "TR50's older line, B picked: what follows. Left to right: today's, B, and B with Normal's "
           "lights left Seam's", "#EDE6D6", bold=0.2)
    y = head
    for words, tall, draw in rows:
        t.text(gap, y + 3, 13, words, "#B4AC9C")
        for k, p in enumerate(takes):
            draw(sheet.tile(gap + k * (W + gap), y + label, W, tall), p)
        y += label + tall + gap
    write(sheet, out / "stage_arc_dusk_follow.png")


def delivery(name, p):
    """A take for Faber: what changes from today's, by its home in Config, and what stays."""
    bed_tall = 153.0
    wide, tall = 150 * 0.38 * POOL[0], bed_tall * 0.42 * POOL[1]
    low = (bed_tall / 2 + 3 + bed_tall * p["bed_low"]) / bed_tall
    made = {
        "what": "TR50's older line: the Arc panel's ground in the festival's dusk (docs/test-requests.md, TR50). "
                "Colours only, no image changes. Drawn in tools/blender/stage_arc_dusk.py.",
        "take": name,
        "ground": {
            "Backing": {"value": list(p["backing"]), "today": "Glass.Ground's default (Equipment's backing)",
                        "how": "Glass.Ground(body, 1, backing) on the Arc screen only"},
            "Bloom": {"colour": p["ground_bloom"][0], "alpha": p["ground_bloom"][1],
                      "middle": "the bed's middle", "falls to a third at": [150, 120],
                      "today": "none on the Arc screen", "how": "a new Glass.Bloom on the ground, under the tile"},
        },
        "bed": {
            "Hud.stages.Bed.Fill": list(p["bed"]),
            "bloom colour": {"value": p["bed_bloom"][0], "today": "Accent.Normal.Bloom, shared with Normal's lights: "
                             "the bed needs its own"},
            "bloom alpha": {"value": p["bed_bloom"][1], "today": "Accent.Normal.Pictures.Next"},
            "Hud.stages.Bed.Bloom.Middle": [0.5, round(low, 2)],
            "bloom's reach": {"falls to a third at": [round(wide, 1), round(tall, 1)], "in": "points on the 150 x 153 "
                              "bed, clipped by it", "how": "Bed.Bloom.Size matched to the sheet at the phone's pixels: "
                              "about half again as wide and two thirds as tall as today's"},
            "edge": {"value": p["bed_edge"], "today": "SeamGlass.Edge at Bed.EdgeAlpha"},
        },
        "panel": {
            "glow": {"value": p["panel_glow"], "today": "Accent.Normal.Glow at Tile.Next.GlowAlpha"},
            "rim": {"value": p["panel_edge"], "today": "SeamGlass.Facet at Tile.Edge",
                    "also": "Back's underline in the band"},
        },
        "results card": {
            "cover": {"value": p["cover"], "today": "SeamGlass.Backing at Card.Dim (Screen.Full's look.Backing)",
                      "how": "the cover's colour for the results card only; Card.Dim stays 0.5"},
        },
    }
    lights = {k: p[k] for k in ("lit", "lit_glow", "road", "accent") if p[k] != TODAY[k]}
    if lights:
        made["Normal's lights"] = {"Accent.Normal.Lit": list(p["lit"]), "Accent.Normal.Glow": p["lit_glow"],
                                   "Accent.Normal.Road": list(p["road"]), "Accent.Normal.Edge": p["accent"]}
    else:
        made["stays"] = ("Normal's lights (Accent.Normal's Edge, Lit, Road, Glow; Make.Lit.Fill), Hard's ember, "
                         "Seam's glass and its words, the run's line, every image")
    return made


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
    write(sheet, out / "stage_arc_dusk.png")
    follow(out)
    (out / "stage_arc_dusk.json").write_text(json.dumps(dict({name: p for name, p, _ in TAKES}, B_KIT=B_KIT), indent=1))
    print(f"wrote {out / 'stage_arc_dusk.json'}")
    named = dict({name: p for name, p, _ in TAKES}, B_KIT=B_KIT)
    take = next((a for a in sys.argv[sys.argv.index("--") + 2:] if a in named), None)
    if take:
        (out / "arc_dusk.json").write_text(json.dumps(delivery(take, named[take]), indent=1))
        print(f"wrote {out / 'arc_dusk.json'}: {take}")


if __name__ == "__main__":
    main()
