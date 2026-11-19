"""AR43: the Voidkin screen's pages (Overview, Kit, Stars) and the bag (its Inventory page) in Seam's lit glass, cut
for Faber (research, 2026-11-19, 21:00, on the director's "sure" of 20:57: the Voidkin screen, every page, and the
bag, in B's lit glass, built from the kit as Equipment's is; not the other screens).

Drawn as equipment_pages.py draws Equipment: the kit's pieces from seam_kit.py (B) at the smallest phone, 568 by 320
points. What B leaves as it is comes from Faber's stills of today's screens (build/scratch/faber/ar43/stills, 1.5
pixels a point), laid where it stands: the stage with Rook, his name and Combat Power; the roster's strip; the bag's
cells and the doll's slots. The rest is drawn: the ground with no bloom (the stage carries the light: research's
"watch the violet"), the band's channel, Leading and the pages' presses, the panel and its words, and the bag's room,
kinds and Sort.

The Overview shows all five Basic Attributes (TR49; the director, 13:53): three a row, then two, at 14 points, under a
heading pulled up to the experience bar. Agility's, Intelligence's and Spirit's totals are stand-ins beside the still's
Strength and Endurance.

    blender -b --factory-startup --python tools/blender/voidkin_b_cut.py -- <abs out>
Writes build/handoff/UI/voidkin_b/: voidkin_b_cut.png (the pages, today's beside them), voidkin_b_close.png (the
Overview's panel at three pixels a point, today's beside it) and voidkin_b.json (every piece's place and look, and the
violet measure). <out> takes the measure's working pictures.
"""

import colorsys
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import equipment_pages as ep  # noqa: E402  (wears B on import)
import rook_sheet as rs  # noqa: E402
import seam_kit as sk  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402

P = up.P
W, H, SMALL = up.W, up.H, up.SMALL
STILLS = up.REPO / "build" / "scratch" / "faber" / "ar43" / "stills"
HANDOFF = up.UI / "voidkin_b"
PX = 1.5                                   # the stills' pixels a point
FLOOR = 0.85                               # Theme.Scale.Floor: an authored number is the point over this
NO_BLOOM = (-4000.0, -4000.0)
BACKING_TODAY = "#07060C"                  # Seam's backing, keyed out of the strip

# Today's places, in points on the smallest phone, read off the stills.
STAGE = (7.3, 64.7, 300.7, 264.0)
STRIP = (7.3, 268.7, 298.0, 312.7)
ACTIONS = (305.3, 65.3, 560.0, 108.7)
PANEL = (305.3, 114.7, 560.0, 313.3)
INSIDE = (312.1, 121.5, 553.2, 306.5)      # the panel less its pad (8 authored)
ROW = (312.1, 546.4)                       # a line of the page: the inside less 8 authored at its right
L = 313.0                                  # where words start
THIRD = (ROW[1] - ROW[0]) / 3              # a Basic Attribute's cell
CELL_PAD = 8 * FLOOR                       # its words' room: the cell less this

# The Overview's lines, their capitals' tops.
LINES = dict(kind=123.0, level=148.0, xp=166.0, bar=(182.0, 188.8), heading=198.0,
             names=(224.6, 269.6), totals=(241.2, 286.2), cells=(217.7, 262.7), cell=40.0)
ATTRIBUTES = [("Strength", "337", True), ("Agility", "148", False), ("Intelligence", "96", False),
              ("Endurance", "201", False), ("Spirit", "122", False)]

KIT = [("Signature · Haymaker", ["a long wind-up, one straight punch, a", "shockwave along the ground"]),
       ("Combo", ["3 hits in a string, again and again"]),
       ("Passive · Second Wind", ["takes less damage below 30% health"])]

TRIM = {"Common": "#666C78"}               # Config.Hud.Card.Trim
STAR = dict(cy=129.4, first=L + 10, pitch=24.0, half=10.0)

# The bag, today's places (bag-phone, 1.5 pixels a point).
ROOM = (8.0, 58.0, 561.3, 318.7)
DOLL = dict(size=40.0, cols=(12.0, 175.3), rows=[60.0 + 43.33 * k for k in range(6)], hands=[(70.0, 277.3),
                                                                                             (118.7, 277.3)])
BAG_STAGE = (53.3, 60.7, 174.7, 274.7)
GRID = dict(size=54.4, xs=(235.3, 294.7, 354.0, 413.3, 473.3), ys=(116.0, 175.3, 234.7, 294.0), clip=300.0)
KINDS = dict(box=(228.0, 61.3, 433.3, 104.7), all=(230.5, 64.0, 272.0, 102.0), gear=298.7, jewelry=360.0,
             third=406.7, rules=(324.7, 393.3), fade=(415.0, 432.5))
SORT = (439.3, 61.3, 557.3, 104.7)
DIVIDER = 224.0

_cache = {}


# --- the stills -----------------------------------------------------------------------------------------------------

def still(name):
    if name not in _cache:
        _cache[name] = rs.load(STILLS / f"{name}.png")
    return _cache[name]


def crop(name, x0, y0, x1, y1, key=None):
    """A box of a still, in points, at the sheet's pixels; `key`, a ground colour keyed out of it."""
    ck = (name, x0, y0, x1, y1, key, ui.K)
    if ck not in _cache:
        px = still(name)[round(y0 * PX):round(y1 * PX), round(x0 * PX):round(x1 * PX)].copy()
        px[..., 3] = 1.0
        if key:
            d = np.abs(px[..., :3] - np.array(rs.rgb(key), dtype=np.float32)).sum(-1) * 255
            px[..., 3] = np.clip((d - 12) / 18, 0, 1)
        _cache[ck] = ep.stretch(px, round((x1 - x0) * ui.K), round((y1 - y0) * ui.K))
    return _cache[ck]


def lay(t, name, box, key=None, cut=None):
    """A still's box laid where it stands; `cut`, the bag's corners (a cell's or a slot's) masking it."""
    x0, y0, x1, y1 = box
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, 0, cut, 0)) if cut else None
    t.image(crop(name, x0, y0, x1, y1, key), x0, y0, d)


# --- the frame ------------------------------------------------------------------------------------------------------

def band(t, name):
    """The band as the game has it on a phone: Roblox's buttons, Back, the Voidkin's three marks, the page's name, the
    battery (Credits step out where the band is narrow)."""
    up.box(t, 6, 8, 160, 50, P["channel"], P["edge"], 1.0, 6)
    t.text(83, 15, SMALL, "Roblox's", P["faint"], "CENTER")
    t.text(83, 31, SMALL, "buttons", P["faint"], "CENTER")
    t.text(196, 22, SMALL, "<  BACK", P["text"], "CENTER", bold=0.3)
    t.stroke([(178, 44), (214, 44)], 1.4, P["light"], 0.8)
    up.voidkin_marks(t)
    t.text(372, 22, SMALL, name, P["text"], bold=0.3)
    up.box(t, 484, 14, 560, 44, P["channel"], P["edge"], 1.0, 4)
    ui.bolt(t, 499, 29, 7)
    t.text(552, 23, SMALL, "0.00", P["text"], "RIGHT", bold=0.3)


def lit_words(t, box, words, mark=False):
    """The lit press with its words (and Leading's diamond) in the ink, centred together."""
    x0, y0, x1, y1 = box
    sk.press(t, x0, y0, x1, y1, "")
    t.sheet.items.pop()                    # the press's own empty words
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    wide = up.wide_of(words, SMALL) * 0.84 + (12 if mark else 0)
    left = cx - wide / 2
    if mark:
        s = 4.2
        t.paint(t.poly([(left + 4, cy - s), (left + 4 + s, cy), (left + 4, cy + s), (left + 4 - s, cy)]), P["ink"])
        left += 12
    t.text(left, cy - 5, SMALL, words, P["ink"], bold=0.3)


def off_press(t, box, words, why):
    """A press the Voidkin can't take yet: the well's, its words faint, why under them (docs/ui.md, rule 4)."""
    x0, y0, x1, y1 = box
    up.box(t, x0, y0, x1, y1, P["well"], P["edge"], 1.0, 5)
    cx = (x0 + x1) / 2
    t.text(cx, y0 + 8, SMALL, words, P["faint"], "CENTER", bold=0.3)
    t.text(cx, y0 + 25, SMALL, why, P["soft"], "CENTER")


def stage_page(t, name):
    sk.backdrop(t, NO_BLOOM)
    band(t, name)
    lay(t, "voidkin-phone", STAGE)
    lay(t, "voidkin-phone", STRIP, key=BACKING_TODAY)
    lit_words(t, ACTIONS, "Leading", mark=True)
    sk.panel(t, *PANEL)
    t.stroke([(INSIDE[2] - 1.2, INSIDE[1] + 2), (INSIDE[2] - 1.2, INSIDE[1] + 30)], 2.4, P["soft"], 0.6)   # the scroll


# --- the pages ------------------------------------------------------------------------------------------------------

def overview(t, st):
    stage_page(t, "Overview")
    t.text(L, LINES["kind"], SMALL, "Common · Red · Warrior", P["text"], bold=0.3)
    t.text(L, LINES["level"], SMALL, "Level 17", P["text"], bold=0.3)
    t.text(L, LINES["xp"], SMALL, "5 of 5,265 experience to the next", P["soft"])
    b0, b1 = LINES["bar"]
    up.box(t, ROW[0], b0, ROW[1], b1, P["channel"], P["edge"], 0.8, 0)
    up.box(t, ROW[0] + 0.8, b0 + 0.8, ROW[0] + 2.4, b1 - 0.8, "#4E9BFF", cut=0)
    t.text(L, LINES["heading"], SMALL, "BASIC ATTRIBUTES", P["text"], bold=0.35)
    if st.get("guides"):
        for k in range(5):
            x, y = ROW[0] + (k % 3) * THIRD, LINES["cells"][k // 3]
            t.line(t.poly(ui.cut_box(x, y, x + THIRD - CELL_PAD, y + LINES["cell"])), 0.6, "#FF6A6A")
    for k, (name, total, main) in enumerate(ATTRIBUTES):
        x, row = L + (k % 3) * THIRD, k // 3
        t.text(x, LINES["names"][row], SMALL, name, P["soft"])
        t.text(x, LINES["totals"][row], SMALL, total, P["text"], bold=0.3)
        if main:
            t.text(x + up.wide_of(total, SMALL) * 0.84 + 6, LINES["totals"][row], SMALL, "Main", P["light"], bold=0.3)


def kit(t, st):
    stage_page(t, "Kit")
    y = 124.0
    for title, said in KIT:
        t.text(L, y, SMALL, title, P["text"], bold=0.3)
        for n, words in enumerate(said):
            t.text(L, y + 18.7 + n * 17, SMALL, words, P["soft"])
        y += 18.7 + 17 * len(said) + 5.1


def star(t, k, full):
    cx, cy, s = STAR["first"] + k * STAR["pitch"], STAR["cy"], STAR["half"]
    d = t.poly([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)])
    if full:
        t.glow(d, 3.0, TRIM["Common"], 0.5)
        t.paint(d, t.ramp("#9AA0AC", TRIM["Common"], (t.y - cy + s) / (2 * s)))
        t.line(d, 1.0, P["glint"], 0.8)
    else:
        t.paint(d, up.shade(t, P["well"], cy - s, cy + s))
        t.line(d, 1.0, P["facet"], 0.55)


def stars(t, st):
    stage_page(t, "Stars")
    for k in range(7):
        star(t, k, k < 1)
    t.text(L, 147, SMALL, "1 of 7 stars", P["text"], bold=0.3)
    t.text(L, 165.7, SMALL, f"{2 if st['can'] else 1} of 2 copies for the next", P["soft"])
    t.text(L, 190, SMALL, "The next star", P["text"], bold=0.3)
    t.text(ROW[1], 190, SMALL, "+415", P["text"], "RIGHT", bold=0.3)
    t.text(L, 208.7, SMALL, "+18 Health · +5 Attack · +2 Defense,", P["soft"])
    t.text(L, 225.7, SMALL, "Combat Power on the right", P["soft"])
    box = (ROW[0], 246.0, ROW[1], 290.2)
    if st["can"]:
        lit_words(t, box, "Take the star")
    else:
        off_press(t, box, "Take the star", "1 more copy")


def bag(t, st):
    sk.backdrop(t, NO_BLOOM)
    band(t, "Inventory")
    sk.panel(t, *ROOM)
    s = DOLL["size"]
    for x in DOLL["cols"]:
        for y in DOLL["rows"]:
            lay(t, "bag-phone", (x, y, x + s, y + s), cut=s * 0.14)
    for x, y in DOLL["hands"]:
        lay(t, "bag-phone", (x, y, x + s, y + s), cut=s * 0.14)
    lay(t, "bag-phone", BAG_STAGE)
    t.stroke([(DIVIDER, ROOM[1] + 6), (DIVIDER, ROOM[3] - 6)], 1.0, P["facet"], 0.35)
    x0, y0, x1, y1 = KINDS["box"]
    up.box(t, x0, y0, x1, y1, P["well"], P["edge"], 1.0, cuts=(6, 0, 6, 0))
    lit_words(t, KINDS["all"], "All")
    for word, cx in (("Gear", KINDS["gear"]), ("Jewelry", KINDS["jewelry"])):
        t.text(cx, 78, SMALL, word, P["soft"], "CENTER", bold=0.15)
    t.text(KINDS["third"], 78, SMALL, "Ches", P["soft"], bold=0.15)   # Chests, cut where the channel ends
    for x in KINDS["rules"]:
        t.stroke([(x, 72), (x, 94)], 1.0, P["edge"])
    t.sheet.fades.append((t.ox + KINDS["fade"][0], t.oy + y0 + 1.5, t.ox + KINDS["fade"][1], t.oy + y1 - 1.5,
                          P["well"]))
    x0, y0, x1, y1 = SORT
    up.box(t, x0, y0, x1, y1, P["button"], P["facet"], 1.0, cuts=(6, 0, 6, 0))
    t.text(x0 + 13, 78, SMALL, "Sort:", P["soft"])
    t.text(x0 + 60, 78, SMALL, "Rarity", P["text"], bold=0.3)
    t.stroke([(x1 - 19, 81), (x1 - 14, 86), (x1 - 9, 81)], 1.4, P["text"])
    grid = t.sheet.tile(t.ox, t.oy, W, GRID["clip"])
    g = GRID["size"]
    for y in GRID["ys"]:
        for x in GRID["xs"]:
            lay(grid, "bag-phone", (x, y, x + g, y + g), cut=g * 0.14)
    t.stroke([(554.7, 112), (554.7, 133)], 2.4, P["soft"], 0.6)
    t.text(228, 304.5, SMALL, "100 / 300 in the bag", P["soft"])


def today(t, st):
    """Today's screen as Faber's still has it, at the same size."""
    t.image(crop(st["still"], 0, 0, W, H), 0, 0)


PAGES = dict(Overview=overview, Kit=kit, Stars=stars, Bag=bag, Today=today)
# Take 2: B's lights (the lit press, the sheen, the edges lit from above, the corner glint) on Seam's own grounds, its
# backing and its panel, where take 1 lifts them to SeamGlass's (research's "watch the violet", 21:00).
SEAM_GROUNDS = dict(backing=(up.SEAM["backing"], up.SEAM["backing"]), panel=up.SEAM["panel"], well=up.SEAM["well"],
                    button=up.SEAM["button"])


def phone(sheet, ox, oy, st):
    keep = {k: P[k] for k in SEAM_GROUNDS}
    if st.get("take") == 2:
        P.update(SEAM_GROUNDS)
    try:
        PAGES[st["page"]](sheet.tile(ox, oy, W, H), st)
    finally:
        P.update(keep)


def fade(sheet):
    """A channel's end over the words in it: the well fading in across its last points (the kinds scroll on)."""
    for x0, y0, x1, y1, fill in sheet.fades:
        a, b = (round(v * ui.K) for v in (x0, x1))
        top, foot = round(y0 * ui.K), round(y1 * ui.K)
        region = sheet.px[top:foot, a:b]
        ramp = np.linspace(0, 1, region.shape[1], dtype=np.float32)[None, :] ** 1.2
        colour = (np.array(rs.rgb(fill[0])) + np.array(rs.rgb(fill[1]))) / 2
        ui.over(region, colour, np.broadcast_to(ramp, region.shape[:2]))


def sheet_of(path, head, cells, notes, across=2, k=2):
    ui.K = k
    up._pics.clear()
    gap, head_h = 24, 64
    rows = (len(cells) + across - 1) // across
    width = gap + across * (W + gap)
    height = head_h + rows * (H + 40) + len(notes) * 23 + 20
    sheet = ui.Sheet(width, height, "#101117")
    sheet.fades = []
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, head, "#EDE6D6", bold=0.2)
    at = []
    for n, (words, st) in enumerate(cells):
        x, y = gap + (n % across) * (W + gap), head_h + (n // across) * (H + 40)
        t.text(x, y - 4, SMALL, f"{n + 1}. {words}", "#B4AC9C")
        phone(sheet, x, y + 16, st)
        at.append((x, y + 16))
    for n, words in enumerate(notes):
        t.text(gap + 8, head_h + rows * (H + 40) + n * 23, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    fade(sheet)
    rs.save(sheet.px, path)
    return sheet, at


# --- the violet ----------------------------------------------------------------------------------------------------

def violet(rgb):
    """How much of a picture is visible violet: hue 245 to 300, saturation 0.3 or more, value 0.15 or more. Returns its
    share of the pixels and its mean strength (saturation x value) over the whole picture."""
    flat = np.clip(rgb.reshape(-1, 3), 0, 1)
    mx, mn = flat.max(1), flat.min(1)
    d = mx - mn
    sat = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0)
    r, g, b = flat[:, 0], flat[:, 1], flat[:, 2]
    safe = np.maximum(d, 1e-6)
    hue = np.where(mx == r, ((g - b) / safe) % 6, np.where(mx == g, (b - r) / safe + 2, (r - g) / safe + 4)) * 60
    sel = (d > 1e-6) & (hue >= 245) & (hue <= 300) & (sat >= 0.3) & (mx >= 0.15)
    return round(float(sel.mean()), 3), round(float((sat * mx * sel).mean()), 4)


def below_band(px, k):
    return px[round(56 * k):, :, :3]


def measure(out):
    """Today's still against B's page, below the band, as the sheet draws them."""
    ui.K = 2
    up._pics.clear()
    found = {}
    for label, st in (("Overview, take 1", dict(page="Overview")), ("Overview, take 2", dict(page="Overview", take=2)),
                      ("the bag, take 1", dict(page="Bag")), ("the bag, take 2", dict(page="Bag", take=2))):
        sheet = ui.Sheet(W, H, "#101117")
        sheet.fades = []
        phone(sheet, 0, 0, st)
        for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
            rs.paste(sheet.px, layer, 0, 0)
        fade(sheet)
        rs.save(sheet.px, out / f"measure_{st['page']}_{st.get('take', 1)}.png")
        found[label] = violet(below_band(sheet.px, 2))
    for label, name in (("Overview today", "voidkin-phone"), ("the bag today", "bag-phone")):
        found[label] = violet(below_band(still(name), PX))
    for label, (share, strength) in found.items():
        print(f"violet: {label}: share {share}, strength {strength}")
    return found


# --- the cut --------------------------------------------------------------------------------------------------------

def placements(found):
    """Every piece's place and look, in points on the smallest phone (568 by 320) from the screen's top left; an
    authored number is the point over Theme.Scale.Floor (0.85)."""
    p = {k: (v if isinstance(v, str) else list(v)) for k, v in P.items()}
    return dict(
        what=("AR43, the Voidkin screen's pages (Overview, Kit, Stars) and the bag (its Inventory page) in Seam's lit "
              "glass, for Faber (research, 2026-11-19, 21:00, on the director's 'sure' of 20:57; not the other "
              "screens). From tools/blender/voidkin_b_cut.py. No new images: every piece is the kit's "
              "(../seam/seam.json, the client's Kit/Glass) or the game's own as it stands"),
        pointsOnTheSmallestPhone=dict(size=[W, H], floor=FLOOR,
                                      note="the screen is authored at Theme.Author and drawn at 0.85 here; every "
                                           "word is 14 points or more rendered (the Text kit's floor)"),
        takes={
            "1": "B as Equipment wears it: SeamGlass's Backing and Panel under the kit's lights",
            "2": "B's lights on Seam's grounds: the ground's Backing, every panel's fill (PanelFill's gradient, the "
                 "bag's room), the wells (the kinds' channel, an Off press, an empty star) and the quiet glass "
                 "(Sort) in Seam's own (Backing #07060C; Panel #1A1430 to #0C0A16; Well #1B1728 to #110E1B; Button "
                 "#2A2244 to #1A1530), with SeamGlass's Edge, Facet and Glint on them; the lights as take 1: the "
                 "sheen, the edges lit from above, the corner glint, the lit press, the top light",
            "switch": "the two takes differ in those four grounds alone; research picks one at its pass, and the "
                      "cut's places hold for both",
            "why": "research's 'watch the violet' (21:00): take 1's lifted panels nearly double the violet below "
                   "the band; take 2 stays at or under today's on the Overview (see violet)"},
        palette=dict(
            wear="SeamGlass (Config.UIKit, seam.json's palette) where the screen and the bag wear Seam today: "
                 "VoidkinScreen/Seam.luau's palette, the band, the panel, the bag's room, its kinds and Sort, the "
                 "pages' presses; in take 2 with Seam's Backing and Panel (takes)",
            keep=["the stage's ground and its rarity's light: SeamGlass's Ground is Seam's #1E1A2C, and the stage "
                  "is drawn as it is",
                  "the roster's strip: its cells keep Seam's Button plate (pass 'Seam' there), so the portraits "
                  "bring no more violet",
                  "the bag's cells and the doll's slots: Bag.Art as it stands",
                  "the Void Shop: it stands on Seam.Case too, and stays Seam's (the director's scope: not the other "
                  "screens), so Case takes its palette from its caller"],
            colours=p),
        ground=dict(look="Glass.Ground: the Backing top to foot and the top light (seam.json, ground)",
                    bloom="none on these pages: no ScreenBloom. The stage's rarity light is the screen's light; "
                          "research's 'watch the violet' (21:00)"),
        band=dict(back="as it is (B's Back)",
                  marks="the three marks' channel in SeamGlass's Channel with its Edge, its hairlines the Edge",
                  name="the page's name as it is, in the Text",
                  wallet="the chips in the Channel with the Edge, their words in the Text"),
        stage=dict(box=list(STAGE), note="as it is: its ground, its light, Rook, the name's line and Combat Power"),
        strip=dict(box=list(STRIP), note="as it is (see palette.keep)"),
        actions=dict(
            box=list(ACTIONS),
            leading="on the lead: Leading alone across the line, Glass.Lit (the lit press, its glow and its sheen "
                    "once a loop), the diamond and the word in the Ink, 14 bold, centred together",
            other="another Voidkin: Lead as Glass.Lit, Send to work (or Bring home) as Glass.Quiet in the Text; a "
                  "passing block is the Off press (the Well, the Edge, its name in the Faint) with why under it in "
                  "the Soft, as today"),
        panel=dict(box=list(PANEL), look="the kit's panel: PanelFill in SeamGlass's Panel, PanelSheen, PanelEdge "
                                         "lit from above, PanelCornerGlint (seam.json, panel)",
                   inside=list(INSIDE), row=list(ROW),
                   scroll="the ScrollingFrame's bar in the Soft at 0.4 transparency, 2.4 wide"),
        overview=dict(
            lines=dict(kind=dict(capitals=LINES["kind"], words="Common · Red · Warrior", colour="Text", bold=True),
                       level=dict(capitals=LINES["level"], words="Level 17", colour="Text", bold=True),
                       xp=dict(capitals=LINES["xp"], colour="Soft"),
                       bar=dict(box=[ROW[0], LINES["bar"][0], ROW[1], LINES["bar"][1]],
                                look="Bar in SeamGlass: its channel the Channel with the Edge, its fill "
                                     "Config.Hud.Card.Xp")),
            heading=dict(capitals=LINES["heading"], words="BASIC ATTRIBUTES", colour="Text", bold=True,
                         was=226.0,
                         how="pulled up 28 points: the experience line ends at its bar's foot (no padding under "
                             "it) and the first heading has no space above its words (its Line the words' own "
                             "22 authored), so the list's gap (6 authored) is all that stands between"),
            attributes=dict(
                order=[a[0] for a in ATTRIBUTES],
                across=3,
                note="the five Basic Attributes three a row, then two, each cell a third of the row (THIRD, %.1f "
                     "points; its words in %.1f, the cell less SHEET.Pad). The Battle Attributes stay two a row"
                     % (THIRD, THIRD - CELL_PAD),
                cells=[[round(ROW[0] + (k % 3) * THIRD, 1), LINES["cells"][k // 3]] for k in range(5)],
                cell=dict(wide=round(THIRD, 1), tall=LINES["cell"],
                          note="the words' own height (Top, Name and Value: 47 authored), not the touch's 52: "
                               "nothing on the sheet opens (the director, 2026-11-15: 'Plain list, no taps'). The "
                               "Battle Attributes keep theirs"),
                name=dict(capitals=list(LINES["names"]), size=14, colour="Soft"),
                total=dict(capitals=list(LINES["totals"]), size=14, colour="Text", font="Theme.Font.Number"),
                main=dict(words="Main", colour="Light", bold=True, gap=6, note="right after its own total"),
                widest=dict(name="Intelligence, about 63 points at 14", total="12,345 Main, about 67",
                            room=round(THIRD - CELL_PAD, 1)),
                foot="row two's cells end at 302.7, inside the scroll's foot (306.5): all five show on the "
                     "smallest phone with nothing scrolled; the Battle Attributes start under the fold"),
            rest="the Battle Attributes' blocks, Now, Gear and its own name: as today, in SeamGlass's Text and "
                 "Soft"),
        kit=dict(lines="each line: its name 14 bold in the Text, its words 14 in the Soft under it, as today",
                 first=124.0, pitch="the name 18.7, a wrapped line 17, the gap 5.1"),
        stars=dict(
            pips=dict(centre=[STAR["first"], STAR["cy"]], pitch=STAR["pitch"], half=STAR["half"],
                      full="the rarity's trim (Config.Hud.Card.Trim) lit from above, a 1-point hairline of the "
                           "Glint at 0.2 transparency, a glow of the trim",
                      empty="the Well (top to WellFoot) with a 1-point hairline of the Facet at 0.45 transparency: "
                            "seven to win, each seen (polish-later's empty stars)",
                      note="a diamond 20 points tall, a 14-point square turned 45 degrees; 24 apart"),
            words="the stars, the copies, the next star and its gains as today, 14, the Text and the Soft",
            press=dict(box=[ROW[0], 246.0, ROW[1], 290.2],
                       can="Take the star as Glass.Lit, its words in the Ink",
                       cant="the Off press: the Well, the Edge, 'Take the star' in the Faint, why under it in the "
                            "Soft ('1 more copy')")),
        bag=dict(
            room=dict(box=list(ROOM), look="the kit's panel, as the Overview's (Seam.Case in SeamGlass)"),
            divider=dict(x=DIVIDER, colour="Facet", transparency=0.65),
            doll="the slots and the stage as they are; the name's line over the stage as it is",
            kinds=dict(box=list(KINDS["box"]), look="the Well with its Edge, its corners cut as the panel's",
                       chosen=dict(box=list(KINDS["all"]), look="Glass.Lit, its word in the Ink"),
                       rest="their words 14 in the Soft, hairlines of the Edge between",
                       end="the kinds scroll: the Well fades in over the channel's last 14 points, over the next "
                           "word"),
            sort=dict(box=list(SORT), look="Glass.Quiet (SeamGlass's Button, the Facet's hairline)",
                      words="'Sort:' in the Soft, the sort in the Text bold, the chevron in the Text"),
            cells="Bag.Art as it stands, on the room",
            count=dict(capitals=304.5, words="100 / 300 in the bag", colour="Soft")),
        violet=dict(
            how="the share of pixels below the band that are visible violet (hue 245 to 300, saturation 0.3 or "
                "more, value 0.15 or more), and their mean strength (saturation x value over the picture)",
            found={label: dict(share=v[0], strength=v[1]) for label, v in found.items()}),
        motion="seam.json's idle and motion: the lit press's sheen once a loop; a page's open and switch as "
               "Equipment's")


def close(found_overview_path):
    """The Overview's panel at three pixels a point, today's beside it (the still at 1.5, doubled)."""
    ui.K = 3
    up._pics.clear()
    x0, y0, x1, y1 = 300, 56, 566, 318
    shots = []
    for take in (1, 2):
        sheet = ui.Sheet(W, H, "#101117")
        sheet.fades = []
        phone(sheet, 0, 0, dict(page="Overview", guides=True, take=take))
        for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
            rs.paste(sheet.px, layer, 0, 0)
        shots.append(sheet.px[y0 * 3:y1 * 3, x0 * 3:x1 * 3].copy())
    b = shots[0]
    a = ep.stretch(still("voidkin-phone")[round(y0 * PX):round(y1 * PX), round(x0 * PX):round(x1 * PX)],
                   b.shape[1], b.shape[0])
    a[..., 3] = 1.0
    gap, head = 24, 40
    page = rs.canvas(b.shape[1] * 3 + gap * 4, b.shape[0] + head + gap, tuple(np.array(rs.rgb("#101117"))))
    words = []
    for n, (img, said) in enumerate(((a, "Today (the still, doubled)"),
                                     (shots[0], "Take 1, three pixels a point; red: the cells' words' room"),
                                     (shots[1], "Take 2, the same on Seam's grounds"))):
        rs.paste(page, img, gap + n * (b.shape[1] + gap), head)
        words.append((gap + n * (b.shape[1] + gap), 12, 16, said, "#EDE6D6"))
    rs.paste(page, rs.text_layer(page.shape[1], page.shape[0], words), 0, 0)
    rs.save(page, found_overview_path)


CELLS = [("Overview, take 1 (B as Equipment's): all five Basic Attributes", dict(page="Overview")),
         ("Overview, take 2: B's lights on Seam's grounds", dict(page="Overview", take=2)),
         ("Inventory, the bag, take 1", dict(page="Bag")),
         ("Inventory, the bag, take 2", dict(page="Bag", take=2)),
         ("Kit, take 1", dict(page="Kit")),
         ("Kit, take 2", dict(page="Kit", take=2)),
         ("Stars, take 1: a star to take", dict(page="Stars", can=True)),
         ("Stars, take 2: a copy short, the press says why", dict(page="Stars", can=False, take=2)),
         ("Today's Overview, Faber's still", dict(page="Today", still="voidkin-phone")),
         ("Today's bag, Faber's still", dict(page="Today", still="bag-phone"))]


def main():
    out = bl.out_dir()
    rs.OUT = out
    HANDOFF.mkdir(parents=True, exist_ok=True)
    found = measure(out)
    v = {k: f"{s:.3f}" for k, (s, _) in found.items()}
    notes = [
        "The kit's pieces (seam_kit.py, B) on the ground with no bloom; the stage, the strip, the bag's cells and "
        "the doll's slots are Faber's still as it stands. Every word is 14 points.",
        f"Violet below the band, share of pixels: the Overview today {v['Overview today']}, take 1 "
        f"{v['Overview, take 1']}, take 2 {v['Overview, take 2']}; the bag today {v['the bag today']}, take 1 "
        f"{v['the bag, take 1']}, take 2 {v['the bag, take 2']}. The panels make the difference.",
        "Agility's, Intelligence's and Spirit's totals are stand-ins; Rook's star and copies are a state for the "
        "page, not his.",
    ]
    sheet_of(HANDOFF / "voidkin_b_cut.png",
             "AR43: the Voidkin screen and the bag in Seam's lit glass, at the smallest phone (568 x 320 points)",
             CELLS, notes)
    close(HANDOFF / "voidkin_b_close.png")
    (HANDOFF / "voidkin_b.json").write_text(json.dumps(placements(found), indent=1, ensure_ascii=False) + "\n",
                                            encoding="utf-8")
    print("wrote", HANDOFF)


if __name__ == "__main__":
    main()
