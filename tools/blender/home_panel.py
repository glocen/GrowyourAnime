"""AR43, Home: the dock's Menu, renamed by the director (2026-11-19, about 12:21), as a panel of grouped buttons, each
opening its own screen. The blockout's three directions, for research's pick: open in the game's HUD and at the
smallest phone, each one's opening in beats and in a movie, a press, and one screen as a button opens it. Drawn in
code: shapes, the game's shipped page icons and Blender's own face. Nothing is exported.

The director's words (docs/ui.md, the dock; docs/decisions.md, 12:21): Home "should be a PANEL HUD basically it show a
list of button that open their respective Hud", the concept from a recording, never its style. The groups keep 03:37's
contents: Inventory (Overview, Kit, Inventory, Stars), Equipment (Reinforce, Jewels, War Emblems) and Settings.

The directions:
    A  the side sheet   a sheet from the right edge: the two groups stacked, their buttons rows in two columns, and
                        Settings, a group of one, a button in the sheet's head beside its close. It slides in.
    B  the dock's tray  a tray rising out of the Home tile, a group a row, its buttons tiles leaning as the dock's do
                        (0.2), the dock left lit under it. It grows out of the tile the player touched. Research's
                        pick (12:56); Settings is now its own tile at the right end, both rows high (its must-fix).
    C  the three cards  a card a group, side by side, leaning 0.2 like the dock's tiles, their buttons rows; Settings'
                        card, a group of one, is its button. They deal in, one after another.

In AR40's C (the system panel), as AR45's foe cards; the colours of the Menu's screens are still research's pick (AR43).
The world is Faber's phone still of a fight (AR44, ~1.11 px a point), a copy in Modulo's scratch, its bezel cut away
(FIGHT, SCREEN). The smallest phone (568 x 320) is that
capture's foot centre at the same points, so the dock is where it stands and the corner pieces are cut. Taps 44
points or more, words 14 or more.

    blender -b --factory-startup --python tools/blender/home_panel.py -- <abs out> [motion | movie | finish | step | cut]

Writes home_panel.png (the three open, in the game's HUD and at the smallest phone). With `motion`, home_motion.png:
each opening in beats with their times, the press, and Reinforce as its own screen. With `movie`, home_motion.mp4:
each opening at real speed, then at a quarter, at 60 frames a second (frames in <out>/_frames, removed after). With
`finish`, home_tray.png: B alone, open in the fight capture and at the smallest phone, and its opening in beats. With
`step`, home_step.png and home_step.mp4: a tray's button into its screen, and Back to the tray. With `cut`, B for
Faber in build/handoff/UI/home: its images, home.json, home_cut.png and home_fit.png (built from the images beside the
drawn, the difference printed and mapped into <out>).
"""

import functools
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import foe_cards as fc  # noqa: E402
import frames_to_movie as fm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_motion as um  # noqa: E402
import upgrade_pages as up  # noqa: E402

K = 2
P = dict(up.C_SYS)
up.P = P                                            # upgrade_pages' kit draws in C here
# B's tray in the dock's own material (research, AR43, "Home's tray takes the dock's graphite", 13:36): the plate the dock
# body's graphite (hud_dock_sheet.py's body, Graphite Dark's button, its edge), its tiles the dock's Home tile, Voidkin's
# lavender block with its marks in ink (hud_dock.json, Home's rest and pressed); its headings lavender on the graphite.
# The screens it opens keep C (P).
TRAY_P = dict(P, panel=("#323845", "#22262F"), edge="#434A57", rule="#8A93A6", text="#F3EFE6",
              button=("#E4D6FF", "#B7A4EB"), facet="#7C66CC", glint="#FAF7FF", lit=("#A28EE0", "#C3B1F2"),
              light="#DCCBFF", ink="#14161B", tileText="#14161B", tileIcon="#14161B")


def in_graphite(fn):
    """Draws `fn` with the tray's colours in P (and so in upgrade_pages' kit), and puts C back after."""
    @functools.wraps(fn)
    def run(*args, **kwargs):
        saved = dict(P)
        P.update(TRAY_P)
        try:
            return fn(*args, **kwargs)
        finally:
            P.clear()
            P.update(saved)
    return run
SMALL, TITLE = up.SMALL, up.TITLE
GROUPS = (("Inventory", ("Overview", "Kit", "Inventory", "Stars")),
          ("Equipment", ("Reinforce", "Jewels", "War Emblems")),
          ("Settings", ("Settings",)))
LEAN = 0.2                                          # the dock's tiles' lean (hud_dock.json)
DOCK_UP, DOCK_HALF = 83.0, 100.0                    # the dock's top over the phone's foot; its half width (the capture)
ROW, ICON = 44.0, 22.0
DIM = {"A": 0.5, "B": 0.36, "C": 0.55}
DIM_TO = "#05090B"
NAMES = {"A": "the side sheet", "B": "the dock's tray", "C": "the three cards"}
SMALLEST = (568.0, 320.0)

# The openings' seeds, seconds (for Config.Hud.Motion when one is built): the dim's fade, each direction's entry.
SEEDS = dict(Dim=0.15, Slide=0.2, SlideFrom=48.0, Grow=0.22, GrowFrom=0.55, GrowBack=1.2, Fade=0.1, Deal=0.2,
             DealFrom=28.0, DealGap=0.045)
BEATS = (0.03, 0.08, 0.13, 0.2, 0.34)


# --- the kit's pieces, in C -----------------------------------------------------------------------------------------

def leaned(x0, y0, x1, y1, lean):
    """A plate whose top sits `lean` points right of its foot: its foot from x0 to x1."""
    return [(x0 + lean, y0), (x1 + lean, y0), (x1, y1), (x0, y1)]


def plate(t, pts, fill, y0, y1, edge=None, shadow=0.55):
    d = t.poly(pts)
    if shadow:
        t.glow(d, 7.0, "#000000", shadow)
    t.paint(d, up.shade(t, fill, y0, y1))
    if edge:
        t.line(d, 1.0, edge)
    return d


def sheet_plate(t, x0, y0, x1, y1):
    """A panel of the kit's: its cut top left and foot right, the panel's teal falling darker, its cream hairline."""
    return plate(t, ui.cut_box(x0, y0, x1, y1, 10, 0, 10, 0), P["panel"], y0, y1, P["edge"])


def button(t, pts, y0, y1, lit):
    """A button's plate: the lighter teal with a glint along its top, or lit cream when pressed."""
    d = t.poly(pts)
    if lit:
        t.glow(d, 5.0, P["light"], 0.4)
        t.paint(d, up.shade(t, P["lit"], y0, y1))
        t.line(d, 1.0, P["light"])
    else:
        t.paint(d, up.shade(t, P["button"], y0, y1))
        t.line(d, 1.0, P["facet"], 0.55)
        top = [p for p in pts if p[1] == y0]
        t.stroke(top, 1.0, P["glint"], 0.35)
    return d


def heading(t, x, y, name, x_end, size=SMALL):
    """A group's heading: its mark, its word, a faint rule to `x_end`."""
    up.mark(t, name, x + 9, y + 8, 17, P["light"], tab=True)
    t.text(x + 23, y + 2, size, name, P["text"], bold=0.3)
    start = x + 23 + up.wide_of(name, size) * 0.84 + 8
    if x_end > start:
        t.stroke([(start, y + 9), (x_end, y + 9)], 1.0, P["edge"], 0.45)


def icon(t, name, cx, cy, lit, s=ICON):
    colour = P["ink"] if lit else P.get("tileIcon", P["light"])
    if name == "Settings":
        up.mark(t, "Settings", cx, cy, s, colour, tab=True)
    else:
        up.mark(t, name, cx, cy, s, colour)


def row(t, x0, y0, x1, name, lit, lean=0.0):
    """A button as a row: its icon on the left, its word after. `lean` is the row's own, its top that far right."""
    y1 = y0 + ROW
    button(t, leaned(x0, y0, x1, y1, lean), y0, y1, lit)
    mid = lean / 2
    icon(t, name, x0 + mid + 6 + ICON / 2 + 4, y0 + ROW / 2, lit)
    t.text(x0 + mid + 40, y0 + ROW / 2 - 5, SMALL, name, P["ink"] if lit else P["text"], bold=0.3)


def close(t, x0, y0, s=44.0):
    """The close: a cross in a quiet square, `s` points for the thumb."""
    box = ui.cut_box(x0 + 6, y0 + 6, x0 + s - 6, y0 + s - 6, 4, 4, 4, 4)
    t.paint(t.poly(box), up.shade(t, P["well"], y0, y0 + s))
    t.line(t.poly(box), 1.0, P["facet"], 0.5)
    c, r = (x0 + s / 2, y0 + s / 2), 7.0
    t.stroke([(c[0] - r, c[1] - r), (c[0] + r, c[1] + r)], 2.0, P["text"])
    t.stroke([(c[0] - r, c[1] + r), (c[0] + r, c[1] - r)], 2.0, P["text"])


# --- the three directions ---------------------------------------------------------------------------------------------

def side_sheet(t, w, h, lit=None, part=None):
    """A: the sheet on the right, its head (Home, Settings, the close), then Inventory and Equipment, rows in two
    columns. Returns its box."""
    x1, x0, y0 = w - 8, w - 300, 8
    y1 = y0 + 52 + 2 * (24 + 2 * ROW + 6) + 8 + 8         # its head, the two groups, the gap between, its foot
    sheet_plate(t, x0, y0, x1, y1)
    t.text(x0 + 16, y0 + 15, TITLE, "Home", P["text"], bold=0.35)
    gx = x1 - 6 - 44 - 6 - 104
    button(t, ui.cut_box(gx, y0 + 6, gx + 104, y0 + 50, 4, 4, 4, 4), y0 + 6, y0 + 50, lit == "Settings")
    icon(t, "Settings", gx + 18, y0 + 28, lit == "Settings", 20)
    t.text(gx + 32, y0 + 23, SMALL, "Settings", P["ink"] if lit == "Settings" else P["text"], bold=0.3)
    close(t, x1 - 50, y0 + 6)
    y = y0 + 52
    col = (x1 - x0 - 24 - 8) / 2
    for name, buttons in GROUPS[:2]:
        heading(t, x0 + 12, y, name, x1 - 12)
        y += 24
        for k, b in enumerate(buttons):
            cx0 = x0 + 12 + (k % 2) * (col + 8)
            row(t, cx0, y + (k // 2) * (ROW + 6), cx0 + col, b, lit == b)
        y += 2 * ROW + 6 + 8
    return x0, y0, x1, y1


# B's tray, points (the finish of research's pick, 12:56): a tile, the rows, the headings' column, the rule's room,
# Settings' column, the tray's pad.
TRAY = dict(Tile=76.0, High=52.0, Gap=6.0, RowGap=10.0, Head=84.0, Apart=12.0, Settings=72.0, Pad=12.0)


def tray_box(w, h):
    """B's tray: its box (the plate, the point under it excluded) and the bottom row's foot, where the lean starts."""
    s = TRAY
    tall = 2 * s["High"] + s["RowGap"]
    width = 2 * s["Pad"] + s["Head"] + 4 * s["Tile"] + 3 * s["Gap"] + s["Apart"] + s["Settings"] + LEAN * tall
    y1 = h - DOCK_UP - 12
    return w / 2 - width / 2, y1 - (2 * s["Pad"] + tall), w / 2 + width / 2, y1


def stacked_heading(t, cx, y0, name, th):
    """A group's heading in its row: its mark over its word, no plate, so it reads as a label beside the buttons."""
    up.mark(t, name, cx, y0 + 17, 18, P["light"], tab=True)
    t.text(cx, y0 + th - 20, SMALL, name, P["text"], "CENTER", bold=0.3)


def tray_layout(w, h):
    """B's tray on a w by h phone: its box, its headings (name, the mark's middle x, the row's top), its tiles (name,
    the foot's left, the top, the foot's width, the height) and its rule's two ends. Inventory and Equipment are rows,
    Equipment's three across Inventory's four; the upper row sits further right, along the lean, so each gap runs as
    one slant. Settings is its own tile at the right end past the rule, both rows high (research's must-fix, 12:56)."""
    s = TRAY
    tw, th, gap, pad = s["Tile"], s["High"], s["Gap"], s["Pad"]
    x0, y0, x1, y1 = tray_box(w, h)
    foot = y1 - pad                                         # the bottom row's foot: the lean is measured from here
    span = 4 * tw + 3 * gap
    heads, tiles = [], []
    for g, (name, buttons) in enumerate(GROUPS[:2]):
        top = y0 + pad + g * (th + s["RowGap"])
        dx = LEAN * (foot - top - th)
        heads.append((name, x0 + pad + dx + s["Head"] / 2 - 1, top))
        bw = (span - (len(buttons) - 1) * gap) / len(buttons)
        tiles += [(b, x0 + pad + s["Head"] + dx + k * (bw + gap), top, bw, th) for k, b in enumerate(buttons)]
    tall = 2 * th + s["RowGap"]
    rx = x0 + pad + s["Head"] + span + s["Apart"] / 2
    rule = [(rx + LEAN * 6, foot - 6), (rx + LEAN * (tall - 6), foot - tall + 6)]
    tiles.append(("Settings", x0 + pad + s["Head"] + span + s["Apart"], foot - tall, s["Settings"], tall))
    return (x0, y0, x1, y1), heads, tiles, rule


def face(t, name, fx, top, fw, high, on):
    """A tile's icon and word: over its middle, the tall tile's larger and nearer its middle."""
    cx = fx + fw / 2 + LEAN * high / 2
    words = P["ink"] if on else P.get("tileText", P["text"])
    if high > TRAY["High"]:
        icon(t, name, cx + 2, top + high / 2 - 10, on, 26)
        t.text(cx - 2, top + high / 2 + 14, SMALL, name, words, "CENTER", bold=0.3)
    else:
        icon(t, name, cx, top + 16, on, 20)
        t.text(cx, top + high - 21, SMALL, name, words, "CENTER", bold=0.3)


@in_graphite
def dock_tray(t, w, h, lit=None, part=None):
    """B: a tray over the dock with its groups apart (tray_layout), every tile leaning as the dock's (0.2). A point
    at its foot meets the Home tile. In the dock's graphite, its tiles the dock's Home tile (TRAY_P)."""
    (x0, y0, x1, y1), heads, tiles, rule = tray_layout(w, h)
    sheet_plate(t, x0, y0, x1, y1)
    t.paint(t.poly([(w / 2 - 12, y1 - 1), (w / 2 + 12, y1 - 1), (w / 2, y1 + 10)]), up.shade(t, P["panel"], y0, y1))
    t.stroke([(w / 2 - 12, y1), (w / 2, y1 + 10), (w / 2 + 12, y1)], 1.0, P["edge"])
    for name, cx, top in heads:
        stacked_heading(t, cx, top, name, TRAY["High"])
    t.stroke(rule, 1.0, P["rule"], 0.6)
    for name, fx, top, fw, high in tiles:
        button(t, leaned(fx, top, fx + fw, top + high, LEAN * high), top, top + high, lit == name)
        face(t, name, fx, top, fw, high, lit == name)
    return x0, y0, x1, y1 + 10


def card_boxes(w, h):
    cw, gap, lift = 140.0, 10.0, 0.0
    tall = [52.0 if len(b) == 1 else 40 + len(b) * ROW + (len(b) - 1) * 6 + 12 for _, b in GROUPS]
    top = (h - tall[0]) / 2 - 8
    slope = LEAN * tall[0]
    left = min(w / 2 - (3 * cw + 2 * gap + slope) / 2,    # in the middle, or clear of the close in the top right
               (w - 62) - (3 * cw + 2 * gap + slope))
    return [(left + k * (cw + gap), top + lift, left + k * (cw + gap) + cw, top + tall[k]) for k in range(3)]


def three_cards(t, w, h, lit=None, part=None):
    """C: a card a group, leaning 0.2 like the dock's tiles, its heading in its head, its buttons rows. `part` draws
    one card alone (the motion deals them one by one); None draws all three and the close."""
    boxes = card_boxes(w, h)
    foot = boxes[0][3]                                           # the tallest card's foot: every side leans from it

    def at(y):
        return LEAN * (foot - y)                                 # how far right a card's side stands at y

    for k, ((name, buttons), (x0, y0, x1, y1)) in enumerate(zip(GROUPS, boxes)):
        if part is not None and k != part:
            continue
        pts = [(x0 + at(y0), y0), (x1 + at(y0), y0), (x1 + at(y1), y1), (x0 + at(y1), y1)]
        if len(buttons) == 1:                                    # a group of one: the card is its button
            on = lit == buttons[0]
            t.glow(t.poly(pts), 7.0, "#000000", 0.55)
            button(t, pts, y0, y1, on)
            mx = x0 + at((y0 + y1) / 2) + 10
            up.mark(t, name, mx + 10, (y0 + y1) / 2, 19, P["ink"] if on else P["light"], tab=True)
            t.text(mx + 26, (y0 + y1) / 2 - 7, TITLE, name, P["ink"] if on else P["text"], bold=0.3)
            continue
        plate(t, pts, P["panel"], y0, y1, P["edge"])
        heading(t, x0 + at(y0 + 14) + 10, y0 + 12, name, x1 + at(y0 + 14) - 12, size=TITLE)
        for j, b in enumerate(buttons):
            ry = y0 + 40 + j * (ROW + 6)
            row(t, x0 + 8 + at(ry + ROW), ry, x1 - 8 + at(ry + ROW), b, lit == b, LEAN * ROW)
    if part is None:
        close(t, w - 54, 8)
    return boxes[0][0], boxes[0][1], boxes[2][2] + LEAN * (boxes[0][3] - boxes[0][1]), boxes[0][3]


DRAW = {"A": side_sheet, "B": dock_tray, "C": three_cards}


# --- the world, the layers, laying them -----------------------------------------------------------------------------

FIGHT = fc.REPO / "build" / "scratch" / "modulo" / "captures" / "fight-phone.png"  # Faber's AR44 still, kept here
SCREEN = (5, 0, 942, 430)                                   # its screen inside the bezel: left, top, right, foot (px)


def worlds():
    """The capture's phone at 2 pixels a point, and the smallest phone, its foot centre."""
    l, tp, r, ft = SCREEN
    shot = fc.scaled(np.ascontiguousarray(rs.load(FIGHT)[tp:ft, l:r]), K / fc.STILL_PPT)
    shot[..., 3] = 1.0
    sw, sh = SMALLEST
    x = round((shot.shape[1] - sw * K) / 2)
    small = shot[shot.shape[0] - round(sh * K):, x:x + round(sw * K)].copy()
    return {"game": shot, "small": small}


def dimmed(world, kind, amount):
    """The world dimmed toward a dark teal-black; B leaves the dock lit, the tray's root."""
    out = world.copy()
    keep = np.zeros(out.shape[:2], dtype=bool)
    if kind == "B":
        h, w = out.shape[0] / K, out.shape[1] / K
        keep[round((h - DOCK_UP) * K):, round((w / 2 - DOCK_HALF) * K):round((w / 2 + DOCK_HALF) * K)] = True
    a = np.where(keep, 0.0, amount)[..., None]
    out[..., :3] = out[..., :3] * (1 - a) + ui.c(DIM_TO) * a
    return out


def layer(w, h, draw):
    """One drawing alone on a clear phone, its words set in, premultiplied: an upgrade_motion Pic."""
    ui.K = K
    sheet = ui.Sheet(w, h, "#000000")
    sheet.px[:] = 0
    draw(sheet.tile(0, 0, w, h))
    if sheet.items:
        for got in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
            ui.over(sheet.px, got[..., :3], got[..., 3])
    sheet.px[..., :3] *= sheet.px[..., 3:]
    return um.Pic(sheet.px)


def size_of(world):
    return world.shape[1] / K, world.shape[0] / K


def opened(world, kind, pic, t=None, parts=None):
    """The phone with direction `kind` open (t None), or t seconds after the touch."""
    w, h = size_of(world)
    s = SEEDS
    if t is None:
        out = dimmed(world, kind, DIM[kind])
        um.put(out, pic)
        return out
    out = dimmed(world, kind, DIM[kind] * um.out3(um.span(t, 0, s["Dim"])))
    if kind == "A":
        u = um.out3(um.span(t, 0, s["Slide"]))
        um.put(out, pic, dx=s["SlideFrom"] * (1 - u), alpha=um.span(t, 0, s["Fade"]))
    elif kind == "B":
        u = um.span(t, 0, s["Grow"])
        scale = s["GrowFrom"] + (1 - s["GrowFrom"]) * um.back_out(u, s["GrowBack"])
        um.put(out, pic, alpha=um.out3(um.span(t, 0, s["Fade"])), scale=scale, about=(w / 2, h - DOCK_UP))
    else:
        for k, part in enumerate(parts):
            tk = t - k * s["DealGap"]
            u = um.out3(um.span(tk, 0, s["Deal"]))
            um.put(out, part, dy=s["DealFrom"] * (1 - u), alpha=um.span(tk, 0, s["Fade"]))
        um.put(out, pic, alpha=um.span(t - 2 * s["DealGap"], 0, s["Fade"]))   # the close, last
    return out


def close_only(w, h):
    return lambda t: close(t, w - 54, 8)


# --- the sheets -----------------------------------------------------------------------------------------------------

def label_sheet(width, height):
    ui.K = K
    return ui.Sheet(width, height, "#101117")


def words_in(sheet):
    for got in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        ui.over(sheet.px, got[..., :3], got[..., 3])


def main(out):
    world = worlds()
    gw, gh = size_of(world["game"])
    sw, sh = SMALLEST
    ink, soft = "#EDE6D6", "#B4AC9C"
    width = 16 + gw + 16 + sw + 16
    row_h = 26 + gh + 18
    height = 92 + 3 * row_h + 40
    sheet = label_sheet(width, height)
    head = sheet.tile(0, 0, width, 88)
    head.text(16, 16, 20, "AR43, Home: the dock's Menu as a panel of grouped buttons, three directions for research's pick",
              ink, bold=0.2)
    head.text(16, 46, 13, "Left, open in Faber's phone capture of a fight (the game's HUD as it is, the world dimmed). Right, the "
                          "smallest phone (568 x 320), Reinforce pressed. In AR40's C, as the foe cards.", soft)
    head.text(16, 66, 13, "Inventory: Overview, Kit, Inventory, Stars. Equipment: Reinforce, Jewels, War Emblems. Settings. Each "
                          "button opens its own screen, whose Back returns here.", soft)
    for r, kind in enumerate("ABC"):
        y = 92 + r * row_h
        sheet.tile(16, y, width, 24).text(0, 2, 15, f"{kind}. {NAMES[kind].capitalize()}: {SAID[kind]}", ink)
        for k, (where, x, lit) in enumerate((("game", 16, None), ("small", 16 + gw + 16, "Reinforce"))):
            w, h = size_of(world[where])
            pic = layer(w, h, lambda t: DRAW[kind](t, w, h, lit))
            rs.paste(sheet.px, opened(world[where], kind, pic), round(x * K), round((y + 26) * K))
            del pic
    sheet.tile(16, height - 34, width, 24).text(0, 0, 13, NOTE, soft)
    words_in(sheet)
    rs.save(sheet.px, out / "home_panel.png")


SAID = {"A": "from the right edge; Inventory and Equipment as rows in two columns, Settings in its head. It slides in.",
        "B": "out of the Home tile; a group a row, its buttons tiles leaning as the dock's, Settings its own tile at the "
             "right end, both rows high; the dock lit. It grows from the tile.",
        "C": "a card a group, leaning as the dock's tiles, the buttons rows; Settings' card is its button. They deal in."}
NOTE = ("The smallest phone is the capture's foot centre at the same points, so the lead's card and the pills are cut. "
        "Taps 44 points or more, words 14 or more. The concept is the director's, from a recording; the look is the game's.")


# --- motion ---------------------------------------------------------------------------------------------------------

def parts_of(kind, w, h, lit=None):
    """The pictures a direction's opening lays: its panel, or C's three cards and its close."""
    if kind == "C":
        return (layer(w, h, close_only(w, h)),
                [layer(w, h, lambda t, k=k: three_cards(t, w, h, lit, part=k)) for k in range(3)])
    return layer(w, h, lambda t: DRAW[kind](t, w, h, lit)), None


def screen(t):
    """Reinforce as its own screen, opened from Home: the band (Back returns to Home), its name, the worn gear and the
    work, without the Menu's tabs and pages."""
    keep_top = up.TOP
    up.TOP = 60
    try:
        up.box(t, 0, 0, up.W, up.H, P["backing"], cut=0)
        up.band(t, "Equipment")
        t.text(232, 20, TITLE, "Reinforce", P["text"], bold=0.35)
        up.gear_list(t, up.READY, 8, 300)
        up.work(t, up.READY, 306, 560)
    finally:
        up.TOP = keep_top


def motion(out):
    world = worlds()["small"]
    w, h = SMALLEST
    ink, soft = "#EDE6D6", "#B4AC9C"
    bw, bh = w / 2, h / 2
    across = len(BEATS) + 1
    width = 16 + across * (bw + 10) + 6
    strip_h = 24 + bh + 26
    height = 76 + 3 * strip_h + 24 + h + 44
    sheet = label_sheet(width, height)
    head = sheet.tile(0, 0, width, 72)
    head.text(16, 16, 20, "AR43, Home: each direction opening, at the smallest phone (1 pixel a point), then a press", ink,
              bold=0.2)
    head.text(16, 46, 13, "Seconds from the touch on the Home tile. The world dims as the panel enters (0.15 s). Last, "
                          "Reinforce pressed. Under them, Reinforce as its own screen: Back returns to Home.", soft)
    for r, kind in enumerate("ABC"):
        y = 76 + r * strip_h
        sheet.tile(16, y, width, 22).text(0, 2, 14, f"{kind}. {NAMES[kind].capitalize()}: {ENTRY[kind]}", ink)
        pic, parts = parts_of(kind, w, h)
        for k, t in enumerate(BEATS):
            got = opened(world, kind, pic, t, parts)
            x = 16 + k * (bw + 10)
            rs.paste(sheet.px, rs.shrink(got, 0.5), round(x * K), round((y + 24) * K))
            sheet.tile(x, y + 24 + bh + 4, bw, 18).text(0, 0, 13, f"{t:.2f} s", soft)
        pressed, pparts = parts_of(kind, w, h, "Reinforce")
        got = opened(world, kind, pressed) if kind != "C" else opened(world, kind, pressed, 1.0, pparts)
        x = 16 + len(BEATS) * (bw + 10)
        rs.paste(sheet.px, rs.shrink(got, 0.5), round(x * K), round((y + 24) * K))
        sheet.tile(x, y + 24 + bh + 4, bw, 18).text(0, 0, 13, "Reinforce pressed", soft)
        del pic, parts, pressed, pparts
    y = 76 + 3 * strip_h
    sheet.tile(16, y, width, 22).text(0, 2, 14, "Reinforce, opened from Home, at 2 pixels a point: its own screen", ink)
    screen(sheet.tile(16, y + 24, w, h))
    for k, words in enumerate(SCREEN_NOTES):
        sheet.tile(16 + w + 16, y + 30 + k * 20, width - w - 40, 20).text(0, 0, 13, words, soft)
    words_in(sheet)
    rs.save(sheet.px, out / "home_motion.png")


ENTRY = {"A": f"slides in {SEEDS['SlideFrom']:.0f} points from the right in {SEEDS['Slide']} s, eased out",
         "B": f"grows from {SEEDS['GrowFrom']} of its size about the Home tile in {SEEDS['Grow']} s, a little past "
              f"its size (back {SEEDS['GrowBack']})",
         "C": f"the cards deal up {SEEDS['DealFrom']:.0f} points, {SEEDS['DealGap']} s apart, {SEEDS['Deal']} s each"}
SCREEN_NOTES = ("The Menu's tabs and pages go. The band keeps Roblox's buttons, Back and the",
                "Credits and kWh, with the screen's name after Back. Back returns to Home's panel.",
                "The page has the phone's whole width: the worn gear on the left, its work on the right.",
                "Each of Home's buttons opens its screen like this one; none keeps its group's others",
                "across the top (the director's word: each its own screen).")


def movie(out):
    """Each opening at real speed, then at a quarter, the panel held, then Reinforce pressed."""
    world = worlds()["small"]
    w, h = SMALLEST
    caption_h = 28
    frames = out / "_frames"
    frames.mkdir(exist_ok=True)
    n = 0
    for kind in "ABC":
        pic, parts = parts_of(kind, w, h)
        pressed, pparts = parts_of(kind, w, h, "Reinforce")
        for speed in (1, um.SLOW):
            cap = layer(w, caption_h, lambda t, s=speed: t.text(12, 7, 14, f"{kind}. {NAMES[kind]}"
                                                                 + ("" if s == 1 else f", at 1/{s} speed"),
                                                                 "#EDE6D6", bold=0.2))
            length = um.LEAD + 0.4 + (0.5 if speed == 1 else 0.0)
            count = round(length * speed * um.FPS)
            for f in range(count):
                t = f / (speed * um.FPS) - um.LEAD
                path = frames / f"{n:04d}.png"
                n += 1
                if path.exists():
                    continue
                frame = np.zeros((round((h + caption_h) * K), round(w * K), 4), dtype=np.float32)
                frame[..., 3] = 1
                if t < 0:
                    frame[:round(h * K)] = world
                elif speed == 1 and t > 0.62:
                    frame[:round(h * K)] = opened(world, kind, pressed, 1.0, pparts) if kind == "C" else \
                        opened(world, kind, pressed)
                else:
                    frame[:round(h * K)] = opened(world, kind, pic, t, parts)
                um.put(frame, um.Pic(cap.px, 0, round(h * K)))
                rs.save(frame, path)
        del pic, parts, pressed, pparts
    fm.assemble(frames, out / "home_motion.mp4", um.FPS)
    shutil.rmtree(frames)


def finish(out):
    """B, research's pick, after its must-fix: open in the fight capture, and at the smallest phone with Settings
    pressed; then its opening in beats at the smallest phone, and Reinforce pressed."""
    world = worlds()
    gw, gh = size_of(world["game"])
    sw, sh = SMALLEST
    ink, soft = "#EDE6D6", "#B4AC9C"
    bw, bh = sw / 2, sh / 2
    width = max(16 + gw + 16 + sw + 16, 16 + (len(BEATS) + 1) * (bw + 10) + 6)
    height = 76 + 26 + gh + 18 + 24 + bh + 26 + 16
    sheet = label_sheet(width, height)
    head = sheet.tile(0, 0, width, 72)
    head.text(16, 16, 20, "AR43, Home in B, research's pick, with its must-fix: Settings its own tile, both rows high", ink,
              bold=0.2)
    head.text(16, 46, 13, "Left, open in Faber's phone capture of a fight. Right, the smallest phone (568 x 320), Settings "
                          "pressed. Under them, the opening in beats at the smallest phone (1 pixel a point).", soft)
    y = 76
    sheet.tile(16, y, width, 24).text(0, 2, 15, "B. The dock's tray: " + SAID["B"], ink)
    for where, x, lit in (("game", 16, None), ("small", 16 + gw + 16, "Settings")):
        w, h = size_of(world[where])
        pic = layer(w, h, lambda t: dock_tray(t, w, h, lit))
        rs.paste(sheet.px, opened(world[where], "B", pic), round(x * K), round((y + 26) * K))
        del pic
    y += 26 + gh + 18
    sheet.tile(16, y, width, 22).text(0, 2, 14, "Its opening: " + ENTRY["B"], ink)
    small = world["small"]
    pic, _ = parts_of("B", sw, sh)
    for k, t in enumerate(BEATS):
        x = 16 + k * (bw + 10)
        rs.paste(sheet.px, rs.shrink(opened(small, "B", pic, t), 0.5), round(x * K), round((y + 24) * K))
        sheet.tile(x, y + 24 + bh + 4, bw, 18).text(0, 0, 13, f"{t:.2f} s", soft)
    pressed, _ = parts_of("B", sw, sh, "Reinforce")
    x = 16 + len(BEATS) * (bw + 10)
    rs.paste(sheet.px, rs.shrink(opened(small, "B", pressed), 0.5), round(x * K), round((y + 24) * K))
    sheet.tile(x, y + 24 + bh + 4, bw, 18).text(0, 0, 13, "Reinforce pressed", soft)
    words_in(sheet)
    rs.save(sheet.px, out / "home_tray.png")


# --- the step from a button to its screen, and Back -------------------------------------------------------------------

# Seeds, seconds and points (for Config.Hud.Motion when built). Opening a screen: the tile lit (its press squeeze is
# Config.Hud.Motion.Press, as every press), then the tray goes back into the Home tile, eased in, while the screen
# rises from below, eased out, a little after. Back: the screen sinks, eased in, and the tray springs out of the Home
# tile again as it opened.
STEP = dict(Lit=0.06, Leave=0.12, LeaveTo=0.55, RiseAt=0.08, Rise=0.22, RiseFrom=24.0, Cover=0.08, Sink=0.14,
            Uncover=0.1, BackAt=0.06)                 # Cover, Uncover: the screen's fade, quick, so two panels never mix
STEP_BEATS = (0.0, 0.06, 0.12, 0.18, 0.26, 0.4)
BACK_BEATS = (0.0, 0.05, 0.1, 0.16, 0.24, 0.4)


def stepped(world, tray, scr, t, back=False):
    """The smallest phone t seconds after a tray's tile is pressed (into its screen), or after Back (out of it)."""
    w, h = size_of(world)
    s, about = STEP, (w / 2, h - DOCK_UP)
    out = dimmed(world, "B", DIM["B"])
    if not back:
        u = um.span(t, s["Lit"], s["Leave"])
        um.put(out, tray, alpha=1 - um.in3(u), scale=1 - (1 - s["LeaveTo"]) * um.in3(u), about=about)
        r = um.out3(um.span(t, s["RiseAt"], s["Rise"]))
        um.put(out, scr, dy=s["RiseFrom"] * (1 - r), alpha=um.span(t, s["RiseAt"], s["Cover"]))
        return out
    g = um.span(t, s["BackAt"], SEEDS["Grow"])
    if g > 0:
        scale = SEEDS["GrowFrom"] + (1 - SEEDS["GrowFrom"]) * um.back_out(g, SEEDS["GrowBack"])
        um.put(out, tray, alpha=um.out3(um.span(t, s["BackAt"], SEEDS["Fade"])), scale=scale, about=about)
    um.put(out, scr, dy=s["RiseFrom"] * um.in3(um.span(t, 0, s["Sink"])), alpha=1 - um.span(t, 0, s["Uncover"]))
    return out


def step_layers(w, h):
    return (layer(w, h, lambda t: dock_tray(t, w, h, "Reinforce")), layer(w, h, lambda t: dock_tray(t, w, h)),
            layer(w, h, screen))


STEP_SAID = (f"Into a screen: the tile lights at once (its squeeze is the game's press); from {STEP['Lit']} s the tray "
             f"goes back into the Home tile in {STEP['Leave']} s, eased in, to {STEP['LeaveTo']} of its size; from "
             f"{STEP['RiseAt']} s the screen rises {STEP['RiseFrom']:.0f} points in {STEP['Rise']} s, eased out, "
             f"covering in {STEP['Cover']} s.",
             f"Back: the screen sinks {STEP['RiseFrom']:.0f} points in {STEP['Sink']} s, eased in, gone in "
             f"{STEP['Uncover']} s; from "
             f"{STEP['BackAt']} s the tray springs out of the Home tile as it opened ({SEEDS['GrowFrom']} to 1 in "
             f"{SEEDS['Grow']} s, back {SEEDS['GrowBack']}).")


def step(out):
    """home_step.png: Reinforce pressed in the tray, into its screen, then Back to the tray, in beats at the smallest
    phone; home_step.mp4: each at real speed, then at a quarter."""
    world = worlds()["small"]
    w, h = SMALLEST
    lit, tray, scr = step_layers(w, h)
    ink, soft = "#EDE6D6", "#B4AC9C"
    bw, bh = w / 2, h / 2
    width = 16 + len(STEP_BEATS) * (bw + 10) + 6
    strip_h = 44 + bh + 26
    height = 76 + 2 * strip_h + 10
    sheet = label_sheet(width, height)
    head = sheet.tile(0, 0, width, 72)
    head.text(16, 16, 20, "AR43, Home in B: from a button to its screen, and Back, at the smallest phone (1 pixel a point)",
              ink, bold=0.2)
    head.text(16, 46, 13, "Seconds from the touch on Reinforce's tile, then from the touch on Back. The world stays dimmed "
                          "under the tray; the screen covers it.", soft)
    for r, (beats, back, said) in enumerate(((STEP_BEATS, False, STEP_SAID[0]), (BACK_BEATS, True, STEP_SAID[1]))):
        y = 76 + r * strip_h
        sheet.tile(16, y, width, 40).text(0, 2, 13, said, ink)
        for k, t in enumerate(beats):
            got = stepped(world, tray if back else lit, scr, t, back)
            x = 16 + k * (bw + 10)
            rs.paste(sheet.px, rs.shrink(got, 0.5), round(x * K), round((y + 44) * K))
            sheet.tile(x, y + 44 + bh + 4, bw, 18).text(0, 0, 13, f"{t:.2f} s", soft)
    words_in(sheet)
    rs.save(sheet.px, out / "home_step.png")
    del sheet

    caption_h = 28
    frames = out / "_frames"
    frames.mkdir(exist_ok=True)
    n = 0
    for back, name in ((False, "Reinforce, into its screen"), (True, "Back, to the tray")):
        for speed in (1, um.SLOW):
            cap = layer(w, caption_h, lambda t, s=speed, nm=name: t.text(12, 7, 14, nm + ("" if s == 1 else
                                                                                           f", at 1/{s} speed"),
                                                                         "#EDE6D6", bold=0.2))
            count = round((um.LEAD + 0.45 + (0.4 if speed == 1 else 0.0)) * speed * um.FPS)
            for f in range(count):
                t = f / (speed * um.FPS) - um.LEAD
                path = frames / f"{n:04d}.png"
                n += 1
                if path.exists():
                    continue
                frame = np.zeros((round((h + caption_h) * K), round(w * K), 4), dtype=np.float32)
                frame[..., 3] = 1
                if t < 0:
                    frame[:round(h * K)] = stepped(world, tray, scr, 0.0, True) if back else opened(world, "B", tray)
                else:
                    frame[:round(h * K)] = stepped(world, tray if back else lit, scr, t, back)
                um.put(frame, um.Pic(cap.px, 0, round(h * K)))
                rs.save(frame, path)
    fm.assemble(frames, out / "home_step.mp4", um.FPS)
    shutil.rmtree(frames)


# --- the cut, for Faber (research passed B finished, about 13:20): B's own images at 4 pixels a point ------------------

HANDOFF = fc.REPO / "build" / "handoff" / "UI" / "home"
TILE_BOX = 52.0                                     # a row tile's image: its foot 41.6 wide and its lean 10.4
GLOW_PAD = 8.0
LINE_PAD = 1.0                                      # the hairline and the glint sit on the outline, half outside
TALL = 2 * TRAY["High"] + TRAY["RowGap"]
KIT_SLICES = {"PanelShadow": ((28.0,) * 4, 16.0), "PanelFill": ((12.0,) * 4, 0.0), "PanelEdge": ((12.0,) * 4, 0.0)}
MARK_FILL = 30 / 32                                 # the two marks fill 30 of their image's 32 points
ICON_BOX = 20.0                                     # a row tile's icon: the shipped page icons fill their box as drawn
TALL_ICON = 26 / MARK_FILL                          # Settings' cog, 26 across
HEAD_BOX = {"Inventory": 18 / MARK_FILL, "Equipment": 18.0}


def laid(page, px, cx, cy, box, tint):
    """An icon image (4 pixels a point) as an ImageLabel `box` points square, its middle at (cx, cy)."""
    fc.put(page, px, cx - box / 2, cy - box / 2, box / (px.shape[0] / 4), tint)


def tile_shape(foot_w, high, pad=0.0):
    """A leaning tile's outline in its image (its foot from pad to pad + foot_w), and the image's width and height."""
    return leaned(pad, pad, pad + foot_w, pad + high, LEAN * high), foot_w + LEAN * high + 2 * pad, high + 2 * pad


@in_graphite
def cut_images():
    """B's own images: each tile's body, hairline, glint and glow (the row tile sliced, Settings' tall one fixed), the
    point toward the Home tile, and the two marks drawn in code until now. White where the game tints them.
    Returns {name: (pixels, entry)}."""
    ui.K = 4
    made = {}
    rest, pressed = "at rest", "pressed"
    for key, foot_w, high in (("Tile", TILE_BOX - LEAN * TRAY["High"], TRAY["High"]), ("Tall", TRAY["Settings"], TALL)):
        lean = LEAN * high
        sliced = key == "Tile"
        if sliced:
            what = "a button tile in Inventory's and Equipment's rows"
            how = ("Sliced at Cut (left, top, right, foot), its slanted ends inside the end slices: drawn at its own "
                   "height (52), it stretches along only. Its box is its foot's width plus 10.4.")
        else:
            what = "Settings' tile, both rows high"
            how = "Never sliced: drawn at its own size, its foot 72 wide and its top 22.8 right of its foot."
        pts, w, h = tile_shape(foot_w, high)
        box = dict(points=[round(w, 2), round(h, 2)])
        if sliced:
            box["cut"] = [round(lean + 2, 2), 0, round(lean + 2, 2), 0]
        t = fc.clear(w, h)
        t.paint(t.poly(pts), "#FFFFFF")
        made[f"Home{key}Fill"] = (t.px.copy(), dict(box, tint=f"{rest}, the dock's Home tile, {P['button'][0]} at its "
                                                              f"top to {P['button'][1]} at its foot (a UIGradient); "
                                                              f"{pressed}, its pressed {P['lit'][0]} to {P['lit'][1]}",
                                                    use=f"{what}: its body. {how}"))
        pts, w, h = tile_shape(foot_w, high, LINE_PAD)
        lined = dict(points=[round(w, 2), round(h, 2)], pad=LINE_PAD)
        if sliced:
            lined["cut"] = [round(lean + 2 + LINE_PAD, 2), 0, round(lean + 2 + LINE_PAD, 2), 0]
        on_line = (f" Its box is the tile's with Pad on every side: the line sits on the tile's outline, half outside. "
                   + ("Sliced as the tile, at its own height (54)." if sliced else "Never sliced."))
        t = fc.clear(w, h)
        t.line(t.poly(pts), 1.0, "#FFFFFF")
        made[f"Home{key}Edge"] = (t.px.copy(), dict(lined, tint=f"{rest}, Voidkin's deep {P['facet']} at "
                                                                f"ImageTransparency 0.45; {pressed}, its lavender "
                                                                f"{P['light']}",
                                                    use=f"{what}: its hairline, over the body." + on_line))
        t = fc.clear(w, h)
        t.stroke(pts[:2], 1.0, "#FFFFFF")
        made[f"Home{key}Glint"] = (t.px.copy(), dict(lined, tint=f"Voidkin's pale {P['glint']} at ImageTransparency "
                                                                 f"0.65; {rest} only",
                                                     use=f"{what}: the light along its top, over the hairline."
                                                         + on_line))
        pts, w, h = tile_shape(foot_w, high)
        pts, w, h = tile_shape(foot_w, high, GLOW_PAD)
        t = fc.clear(w, h)
        t.glow(t.poly(pts), 5.0, "#FFFFFF", 1.0)
        glow = dict(points=[round(w, 2), round(h, 2)], pad=GLOW_PAD)
        if sliced:
            glow["cut"] = [round(lean + 2 + GLOW_PAD, 2), 0, round(lean + 2 + GLOW_PAD, 2), 0]
        made[f"Home{key}Glow"] = (t.px.copy(), dict(glow, tint=f"the lavender {P['light']} at ImageTransparency 0.6; "
                                                                f"{pressed} only, under the body",
                                                    use=f"{what}: the press's glow. Its box is the tile's with Pad on "
                                                        "every side. " + ("Sliced as the tile, at its own height (68)."
                                                                          if sliced else "Never sliced.")))
    t = fc.clear(28, 14)
    cx, y1 = 14.0, 2.0
    t.paint(t.poly([(cx - 12, y1 - 1), (cx + 12, y1 - 1), (cx, y1 + 10)]), P["panel"][1])
    t.stroke([(cx - 12, y1), (cx, y1 + 10), (cx + 12, y1)], 1.0, P["edge"])
    made["HomePoint"] = (t.px.copy(), dict(points=[28, 14], anchor=[14, 2], tint=None,
                                           use=f"the point toward the Home tile, in its own colours (the graphite's foot "
                                               f"{P['panel'][1]}, its edge {P['edge']}), never tinted. Its anchor on the "
                                               "tray's foot at the phone's middle, laid over the plate, so the point "
                                               "opens into it"))
    t = fc.clear(32, 32)
    up.mark(t, "Settings", 16, 16, 30, "#FFFFFF", tab=True)
    made["HomeMarkSettings"] = (t.px.copy(), dict(points=[32, 32], tint=f"the ink {P['ink']}, {rest} and {pressed}",
                                                  use="Settings' cog, drawn 30 high in its 32 point box: on Settings' "
                                                      "tile at 26 high (its box 27.7)"))
    t = fc.clear(32, 32)
    s, cx, cy = 30.0, 16.0, 16.0
    shard_pts = [(cx, cy - s * 0.5), (cx + s * 0.3, cy - s * 0.2), (cx + s * 0.22, cy + s * 0.32), (cx, cy + s * 0.5),
                 (cx - s * 0.22, cy + s * 0.32), (cx - s * 0.3, cy - s * 0.2)]
    crease = [(cx, cy - s * 0.5), (cx + s * 0.05, cy + s * 0.12), (cx, cy + s * 0.5)]
    seam = np.minimum.reduce([ui.sd_segment(t.x, t.y, a, b) for a, b in zip(crease, crease[1:])]) - s * 0.035
    t.px[..., :3] = 1.0
    t.px[..., 3] = np.clip(0.5 - t.poly(shard_pts) * ui.K, 0, 1) * (1 - 0.55 * np.clip(0.5 - seam * ui.K, 0, 1))
    made["HomeMarkInventory"] = (t.px.copy(), dict(points=[32, 32], tint=f"the lavender {P['light']}",
                                                   use="Inventory's mark, a shard with its crease cut through, drawn 30 "
                                                       "high in its 32 point box: in Inventory's heading at 18 high "
                                                       "(its box 19.2)"))
    return made


@in_graphite
def tray_placements(w, h):
    """Where each piece goes, in points from the tray's top left, for a phone w by h."""
    (x0, y0, x1, y1), heads, tiles, rule = tray_layout(w, h)
    rx = lambda v: round(v - x0, 2)  # noqa: E731
    ry = lambda v: round(v - y0, 2)  # noqa: E731
    (a, b) = rule
    return dict(
        tray=dict(size=[round(x1 - x0, 2), round(y1 - y0, 2)],
                  where="centred on the phone's middle; its foot 12 above the dock's top (95 above the phone's foot)",
                  plate=f"the kit's panel (Config.UIKit's slices): PanelShadow under it (pad 16), PanelFill tinted the "
                        f"dock body's graphite {P['panel'][0]} to {P['panel'][1]}, opaque (the world never shows through "
                        f"the tray), PanelEdge tinted its edge {P['edge']}",
                  point="HomePoint, its anchor on the tray's foot at the phone's middle"),
        headings=[dict(group=n, mark=[rx(cx), ry(top + 17)], markBox=round(HEAD_BOX[n], 2),
                       word=[rx(cx), ry(top + TRAY["High"] - 15)]) for n, cx, top in heads],
        headingNote=f"the mark an ImageLabel markBox square, its middle at `mark`: Inventory's HomeMarkInventory, "
                    f"Equipment's Config.Hud PageForge, tinted the lavender {P['light']}; the group's name 14 points, "
                    f"bold, {P['text']}, its capitals' middle at `word`, centred. No plate",
        tiles=[dict(button=n, foot=[rx(fx), ry(top + hi)], footWidth=round(fw, 2), high=hi,
                    image="HomeTall" if hi > TRAY["High"] else "HomeTile",
                    box=[rx(fx), ry(top), round(fw + LEAN * hi, 2), hi],
                    icon=[rx(fx + fw / 2 + LEAN * hi / 2 + (2 if hi > TRAY["High"] else 0)),
                          ry(top + (hi / 2 - 10 if hi > TRAY["High"] else 16))],
                    iconBox=round(TALL_ICON if hi > TRAY["High"] else ICON_BOX, 2),
                    word=[rx(fx + fw / 2 + LEAN * hi / 2 - (2 if hi > TRAY["High"] else 0)),
                          ry(top + (hi / 2 + 19 if hi > TRAY["High"] else hi - 16))])
               for n, fx, top, fw, hi in tiles],
        tileNote="each tile's images laid in its box (left, top, width, height), an image with a Pad in that box grown "
                 "by its Pad on every side, bottom to top: Glow (pressed), Fill, Edge, Glint (at rest). Its icon an "
                 "ImageLabel iconBox square, its middle at `icon`: "
                 "the page's icon, Config.Hud's PageOverview, PageKit, PageItems (Inventory), PageStars, PageForge "
                 f"(Reinforce), PageJewels and PageWarEmblems; Settings' HomeMarkSettings. In the dock marks' ink "
                 f"{P['ink']}, at rest and pressed. Its word 14 points, bold, centred, its capitals' middle at `word`, "
                 f"in the same ink",
        rule=dict(ends=[[rx(a[0]), ry(a[1])], [rx(b[0]), ry(b[1])]],
                  middle=[rx((a[0] + b[0]) / 2), ry((a[1] + b[1]) / 2)],
                  note=f"a 1 point line between the rows and Settings, {P['rule']} at BackgroundTransparency 0.4: "
                       f"a Frame 1 wide and {round(np.hypot(b[0] - a[0], b[1] - a[1]), 1)} high, its middle at "
                       f"`middle`, Rotation {round(np.degrees(np.arctan(LEAN)), 2)} (clockwise, its top to the right)"))


@in_graphite
def built_tray(world, made, lit=None):
    """The phone with B open, laid as the game lays it: the kit's slices, these images, the game's icons and words."""
    ui.K = K
    w, h = size_of(world)
    sheet = ui.Sheet(w, h, "#000000")
    sheet.px = dimmed(world, "B", DIM["B"])
    page = sheet.px
    (x0, y0, x1, y1), heads, tiles, rule = tray_layout(w, h)
    for name, (cut, pad) in KIT_SLICES.items():
        tint = {"PanelFill": P["panel"], "PanelEdge": P["edge"]}.get(name)
        fc.lay_slice(page, rs.load(fc.KIT / f"{name}.png"), cut, x0, y0, x1 - x0, y1 - y0, pad=pad, tint=tint)
    fc.put(page, made["HomePoint"][0], w / 2 - 14, y1 - 2)
    t = sheet.tile(0, 0, w, h)
    for name, fx, top, fw, high in tiles:
        key = "HomeTall" if high > TRAY["High"] else "HomeTile"
        on = lit == name
        layers = ((("Glow", P["light"], 0.4),) if on else ()) + (
            ("Fill", P["lit"] if on else P["button"], 1.0), ("Edge", P["light"] if on else P["facet"],
                                                             1.0 if on else 0.55)) + (
            () if on else (("Glint", P["glint"], 0.35),))
        for part, tint, alpha in layers:
            px, entry = made[key + part]
            fc.lay_slice(page, px, entry.get("cut", (0, 0, 0, 0)), fx, top, fw + LEAN * high, high,
                         pad=entry.get("pad", 0.0), tint=tint, alpha=alpha)
        cx = fx + fw / 2 + LEAN * high / 2
        words = P["ink"] if on else P.get("tileText", P["text"])
        mark = P["ink"] if on else P.get("tileIcon", P["light"])
        if key == "HomeTall":
            laid(page, made["HomeMarkSettings"][0], cx + 2, top + high / 2 - 10, TALL_ICON, mark)
            t.text(cx - 2, top + high / 2 + 14, SMALL, name, words, "CENTER", bold=0.3)
        else:
            shipped = rs.load(up.CHROME / f"VoidkinPage{up.PAGE_ICON.get(name, name)}.png")
            laid(page, shipped, cx, top + 16, ICON_BOX, mark)
            t.text(cx, top + high - 21, SMALL, name, words, "CENTER", bold=0.3)
    for name, cx, top in heads:
        mark = made["HomeMarkInventory"][0] if name == "Inventory" else rs.load(up.CHROME / "VoidkinPageForge.png")
        laid(page, mark, cx, top + 17, HEAD_BOX[name], P["light"])
        t.text(cx, top + TRAY["High"] - 20, SMALL, name, P["text"], "CENTER", bold=0.3)
    t.stroke(rule, 1.0, P["rule"], 0.6)
    words_in(sheet)
    return sheet.px


@in_graphite
def cut(out):
    """Writes build/handoff/UI/home: images/, home.json, home_cut.png (each image alone, then at 64 px) and home_fit.png
    (the tray built from them beside the drawn one, at rest and pressed, at the smallest phone and in the capture)."""
    import json
    made = cut_images()
    folder = HANDOFF / "images"
    folder.mkdir(parents=True, exist_ok=True)
    listing = {}
    for name, (px, entry) in made.items():
        rs.save(rs.bleed(px), folder / f"{name}.png")
        listing[name] = dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]], **entry)
    sw, sh = SMALLEST
    (HANDOFF / "home.json").write_text(json.dumps(dict(
        pixelsPerPoint=4, palette="the dock's own (research, AR43, 13:36): the plate the dock body's graphite, the "
                                  "tiles the dock's Home tile, Voidkin's lavender with marks in ink; the screens it "
                                  "opens keep C",
        layout=tray_placements(sw, sh),
        layoutNote="measured on the smallest phone (568 by 320); the tray keeps its size on every phone, centred",
        states=dict(rest="Fill tinted the Home tile's lavender, Edge Voidkin's deep at 0.45, Glint shown, icon and "
                         "word in ink",
                    pressed="Glow shown under, Fill the Home tile's pressed, Edge the lavender, Glint hidden, icon and "
                            "word in ink; the press's squeeze is Config.Hud.Motion.Press, as every press"),
        dim=dict(colour=DIM_TO, amount=DIM["B"], seconds=SEEDS["Dim"],
                 note="the world dims under the tray, eased out; the dock stays lit above the dim (its rect: 100 points "
                      "each side of the middle, 83 up from the foot)"),
        motion=dict(open={k: SEEDS[k] for k in ("Grow", "GrowFrom", "GrowBack", "Fade")}, step=STEP,
                    note="open: the tray grows from GrowFrom of its size to 1 about the Home tile's top middle (the "
                         "phone's middle, 83 up from the foot) in Grow seconds, a Back ease of GrowBack, and fades in in "
                         "Fade. step: into a screen and Back, as AR43's record says. Seeds for Config.Hud.Motion"),
        images=listing), indent=1), encoding="utf-8")

    ui.K = K
    ink, soft = "#EDE6D6", "#B4AC9C"
    W = 1180
    sheet = label_sheet(W, 1000)
    head = sheet.tile(0, 0, W, 72)
    head.text(16, 16, 20, "AR43, Home's tray in the dock's graphite, recut for Faber: its own images, for the content check",
              ink, bold=0.2)
    head.text(16, 46, 13, "Each white where the game tints it, shown tinted at rest over dark: as it ships (4 px a point, here "
                          "at 1 px a pixel), then at 64 px. The plate is the kit's panel; the icons are shipped.", soft)
    x, y, row = 16.0, 84.0, 0.0
    tints = {"Fill": P["button"][0], "Edge": P["facet"], "Glint": P["glint"], "Glow": P["light"]}
    for name, (px, entry) in made.items():
        shown = px.copy()
        part = next((k for k in tints if name.endswith(k)), None)
        if part or name.startswith("HomeMark"):
            shown[..., :3] *= np.array(rs.rgb(tints.get(part, P["light"])), np.float32)
        if x + max(px.shape[1] / 2, 64, len(name) * 6.6) > W - 16:
            x, y, row = 16.0, y + row, 0.0
        rs.paste(sheet.px, shown, round(x * 2), round(y * 2))
        small = fc.scaled(shown, 64 / max(px.shape[:2]))
        rs.paste(sheet.px, small, round(x * 2), round((y + px.shape[0] / 2 + 6) * 2))
        sheet.tile(x, y + px.shape[0] / 2 + 6 + 36, 160, 14).text(0, 0, 11, name, soft)
        x += max(px.shape[1] / 2, 64, len(name) * 6.6) + 20
        row = max(row, px.shape[0] / 2 + 6 + 36 + 26)
    words_in(sheet)
    rs.save(sheet.px[:round((y + row) * 2)], HANDOFF / "home_cut.png")

    world = worlds()
    gw, gh = size_of(world["game"])
    width = 16 + 2 * (sw + 16)
    height = 76 + 2 * (24 + sh + 14) + 24 + gh + 20
    sheet = label_sheet(max(width, gw + 32), height)
    head = sheet.tile(0, 0, sheet.w, 72)
    head.text(16, 16, 20, "AR43, Home in B: the tray built from the cut beside the one drawn", ink, bold=0.2)
    head.text(16, 46, 13, "Left, laid from the kit's panel, B's images, the shipped icons and the game's words, as Faber lays "
                          "them; right, drawn. At rest, then Settings pressed; then built in the fight capture.", soft)
    y = 76
    for lit in (None, "Settings"):
        sheet.tile(16, y, sheet.w, 22).text(0, 2, 14, "At rest" if lit is None else "Settings pressed", ink)
        built = built_tray(world["small"], made, lit)
        rs.paste(sheet.px, built, 32, round((y + 24) * K))
        pic = layer(sw, sh, lambda t: dock_tray(t, sw, sh, lit))
        drawn = opened(world["small"], "B", pic)
        rs.paste(sheet.px, drawn, round((16 + sw + 16) * K), round((y + 24) * K))
        x0, y0, x1, y1 = (round(v * K) for v in tray_box(sw, sh))
        gap = np.abs(built[y0:y1 + 20, x0:x1, :3] - drawn[y0:y1 + 20, x0:x1, :3]).max(axis=2)
        print(f"fit {lit or 'rest'}: built against drawn over the tray, mean {gap.mean():.4f}, "
              f"99th {np.percentile(gap, 99):.3f}, max {gap.max():.3f}")
        heat = np.ones(gap.shape + (4,), np.float32)
        heat[..., :3] = np.clip(gap * 4, 0, 1)[..., None]
        rs.save(heat, Path(out) / f"fit_gap_{lit or 'rest'}.png")
        y += 24 + sh + 14
    sheet.tile(16, y, sheet.w, 22).text(0, 2, 14, "Built from the cut, in Faber's phone capture of a fight", ink)
    rs.paste(sheet.px, built_tray(world["game"], made), 32, round((y + 24) * K))
    words_in(sheet)
    rs.save(sheet.px, HANDOFF / "home_fit.png")


if __name__ == "__main__":
    rest = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    mode = rest[1] if len(rest) > 1 else None
    {"motion": motion, "movie": movie, "finish": finish, "step": step, "cut": cut}.get(mode, main)(bl.out_dir())
