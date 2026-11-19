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
                        (0.2), Settings closing Equipment's row past a rule, the dock left lit under it. It grows out
                        of the tile the player touched.
    C  the three cards  a card a group, side by side, leaning 0.2 like the dock's tiles, their buttons rows; Settings'
                        card, a group of one, is its button. They deal in, one after another.

In AR40's C (the system panel), as AR45's foe cards; the colours of the Menu's screens are still research's pick (AR43).
The world is Faber's phone capture of a fight (AR44, ~1.11 px a point). The smallest phone (568 x 320) is that
capture's foot centre at the same points, so the dock is where it stands and the corner pieces are cut. Taps 44
points or more, words 14 or more.

    blender -b --factory-startup --python tools/blender/home_panel.py -- <abs out> [motion | movie]

Writes home_panel.png (the three open, in the game's HUD and at the smallest phone). With `motion`, home_motion.png:
each opening in beats with their times, the press, and Reinforce as its own screen. With `movie`, home_motion.mp4:
each opening at real speed, then at a quarter, at 60 frames a second (frames in <out>/_frames, removed after).
"""

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
    if name == "Settings":
        up.mark(t, "Settings", cx, cy, s, P["ink"] if lit else P["light"], tab=True)
    else:
        up.mark(t, name, cx, cy, s, P["ink"] if lit else P["light"])


def row(t, x0, y0, x1, name, lit, lean=0.0):
    """A button as a row: its icon on the left, its word after. `lean` is the row's own, its top that far right."""
    y1 = y0 + ROW
    button(t, leaned(x0, y0, x1, y1, lean), y0, y1, lit)
    mid = lean / 2
    icon(t, name, x0 + mid + 6 + ICON / 2 + 4, y0 + ROW / 2, lit)
    t.text(x0 + mid + 40, y0 + ROW / 2 - 5, SMALL, name, P["ink"] if lit else P["text"], bold=0.3)


def tile(t, x0, y0, w, h, name, lit, lean=0.0):
    """A button as a tile: its icon over its word."""
    button(t, leaned(x0, y0, x0 + w, y0 + h, lean), y0, y0 + h, lit)
    cx = x0 + w / 2 + lean / 2
    icon(t, name, cx, y0 + 16, lit, 20)
    t.text(cx, y0 + h - 21, SMALL, name, P["ink"] if lit else P["text"], "CENTER", bold=0.3)


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


def dock_tray(t, w, h, lit=None, part=None):
    """B: a tray over the dock, a group a row: its heading, then its tiles, leaning as the dock's. Settings, a group
    of one, closes Equipment's row past a rule, its word its heading. A point at its foot meets the Home tile."""
    tw, th, gap, head, apart = 90.0, 52.0, 6.0, 104.0, 14.0
    width = 12 + head + 4 * tw + 3 * gap + apart + LEAN * th + 12
    x0, x1 = w / 2 - width / 2, w / 2 + width / 2
    y1 = h - DOCK_UP - 12
    y0 = y1 - (12 + 2 * th + 10 + 12)
    sheet_plate(t, x0, y0, x1, y1)
    t.paint(t.poly([(w / 2 - 12, y1 - 1), (w / 2 + 12, y1 - 1), (w / 2, y1 + 10)]), up.shade(t, P["panel"], y0, y1))
    t.stroke([(w / 2 - 12, y1), (w / 2, y1 + 10), (w / 2 + 12, y1)], 1.0, P["edge"])
    for g, (name, buttons) in enumerate(GROUPS[:2]):
        y = y0 + 12 + g * (th + 10)
        heading(t, x0 + 12, y + th / 2 - 9, name, 0)
        for k, b in enumerate(buttons):
            tile(t, x0 + 12 + head + k * (tw + gap), y, tw, th, b, lit == b, LEAN * th)
    y = y0 + 12 + th + 10
    sx = x0 + 12 + head + 3 * (tw + gap) + apart
    t.stroke([(sx - apart / 2 - 3 + LEAN * th, y + 6), (sx - apart / 2 - 3, y + th - 6)], 1.0, P["edge"], 0.6)
    tile(t, sx, y, tw, th, "Settings", lit == "Settings", LEAN * th)
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

def worlds():
    """The capture's phone at 2 pixels a point, and the smallest phone, its foot centre."""
    shot = fc.scaled(rs.load(fc.FIGHT), K / fc.STILL_PPT)
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
        "B": "out of the Home tile; a group a row, its buttons tiles leaning as the dock's, Settings past a rule, the "
             "dock lit. It grows from the tile.",
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


if __name__ == "__main__":
    rest = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    mode = rest[1] if len(rest) > 1 else None
    {"motion": motion, "movie": movie}.get(mode, main)(bl.out_dir())
