"""AR12, the dock as three icons (the director, 2026-11-15: "we could make a icon of it no need to name it inventory and
make a ui around it, it need to be a very cool ui well composed", then "All three icons"; docs/ui.md, the HUD).

One piece, not three buttons: a graphite body cut as the kit's buttons are, three tiles set in it, each a block of its
system's colour with its mark in ink, as V2, Block's pills carry theirs. Everything leans as a bar's front does. Inventory
stands in the middle, taller, since the dock is built round it; Base and Map are its wings. Under each tile runs its
light. No word: a long press shows it (the build's).

    blender -b --factory-startup --python tools/blender/hud_dock_sheet.py -- build/handoff/UI/hud/dock

Writes the sheet hud_dock.png.
"""
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402

kit, ui, rs, c = h.kit, h.ui, h.rs, h.c
K4 = h.K4
GR = h.GRAPHITE
WHITE = "#FFFFFF"

LEAN = 0.2  # how far a side goes right for each point it rises
WING, MID = (52.0, 44.0), (60.0, 54.0)  # a tile's width and height: every tap is over 44 points
M, G, FOOT, CUT = 5.0, 4.0, 9.0, 7.0  # the body round the tiles, the seam between two, the body under them, its cut
YB = M + MID[1]  # the line the tiles stand on
DH = YB + FOOT
SPAN = 2 * M + 2 * WING[0] + MID[0] + 2 * G  # the body's foot
OX = LEAN * FOOT
DW = float(math.ceil(OX + SPAN + LEAN * YB))
GLOW = 14.0  # the room round the dock for its shadow and an open tile's light
MARK = (15.0, 19.0)  # a mark's half size: on a wing, in the middle


# --- the marks: distances, negative inside, what's inside cut clean through ------------------------------------------

def plant(t, cx, cy, r):
    """The Base: the plant, a bolt cut through it."""
    return np.maximum(h.g_plant(t, cx, cy, r), -h.g_bolt(t, cx, cy + r * 0.22, r * 0.6))


def route(t, cx, cy, r):
    """The Map: the folded sheet, a way cut across it."""
    return np.maximum(h.g_map(t, cx, cy, r), -h.map_route(t, cx, cy, r, 0.16 * r))


def _ridge(t, cx, cy, r, w):
    return np.minimum(h.seg(t, (cx + 0.12 * r, cy - 0.66 * r), (cx, cy + 0.12 * r), w),
                      h.seg(t, (cx, cy + 0.12 * r), (cx - 0.14 * r, cy + 0.66 * r), w))


def _pts(t, cx, cy, r, pts):
    return t.poly([(cx + r * u, cy + r * v) for u, v in pts])


SATCHEL = ((-1.0, 0.04), (1.0, 0.04), (0.88, 0.76), (0.62, 1.0), (-0.62, 1.0), (-0.88, 0.76))


PACK = ((-0.36, -0.74), (0.36, -0.74), (0.9, -0.2), (0.9, 0.78), (0.66, 1.0), (-0.66, 1.0), (-0.9, 0.78), (-0.9, -0.2))


def inventory(t, cx, cy, r):
    """Your Voidkin and your whole bag: a pack by its outline, sloped at the shoulders, its low grip on top, a shard
    cut clean through its face over its pocket's flap."""
    body = _pts(t, cx, cy, r, PACK)
    grip = np.maximum(np.abs(np.hypot((t.x - cx) / 1.5, t.y - cy + 0.74 * r) - 0.2 * r) - 0.07 * r, t.y - cy + 0.74 * r)
    shard = h.g_shard(t, cx, cy - 0.06 * r, 0.5 * r)
    flap = h.seg(t, (cx - 0.44 * r, cy + 0.66 * r), (cx + 0.44 * r, cy + 0.66 * r), 0.11 * r)
    return np.minimum(np.maximum(body, -np.minimum(shard, flap)), grip)


def inventory_standing(t, cx, cy, r):
    """A shard standing in a satchel, the satchel cut clear of it."""
    body = _pts(t, cx, cy, r, SATCHEL)
    sy, sr = cy - 0.22 * r, 0.8 * r
    shard = h.g_shard(t, cx, sy, sr)
    return np.minimum(np.maximum(body, -(shard - 0.13 * r)), np.maximum(shard, -_ridge(t, cx, sy, sr, 0.12 * r)))


def inventory_face(t, cx, cy, r):
    """A carry bag, its handle over it, a shard cut clean through its face."""
    body = _pts(t, cx, cy, r, ((-0.95, -0.42), (0.95, -0.42), (0.84, 0.74), (0.58, 1.0), (-0.58, 1.0), (-0.84, 0.74)))
    handle = np.maximum(np.abs(np.hypot(t.x - cx, t.y - cy + 0.42 * r) - 0.46 * r) - 0.12 * r, t.y - cy + 0.42 * r)
    return np.minimum(np.maximum(body, -h.g_shard(t, cx, cy + 0.26 * r, 0.56 * r)), handle)


# Left to right. The dock is built round Inventory, so it takes the middle.
BUTTONS = (("Base", plant, h.POWER), ("Inventory", inventory, h.VOIDKIN), ("Map", route, h.MAP))
VARIANTS = (("a shard standing in a satchel", inventory_standing), ("a carry bag, a shard in its face", inventory_face))


# --- the dock --------------------------------------------------------------------------------------------------------

def dock(st, x, y, states=("rest",) * 3, dots=(), s=1.0, marks=None):
    """The dock with its top left at x, y, `s` times its size. A state: rest, pressed, open. `dots`: which tiles carry
    the mark for something new. Drawn in the order the build would stack it: shadow, body, wells, lights, tiles, marks."""
    g = GLOW * s
    t = kit.blank(DW * s + 2 * g, DH * s + 2 * g)

    def X(xb, yy):
        return g + (OX + xb + LEAN * (YB - yy)) * s

    def Y(yy):
        return g + yy * s

    def lean(x0, x1, y0, y1):
        return t.poly([(X(x0, y0), Y(y0)), (X(x1, y0), Y(y0)), (X(x1, y1), Y(y1)), (X(x0, y1), Y(y1))])

    yw = YB - WING[1] - M  # the wings' top
    a, b = M + WING[0] + G - M, M + WING[0] + G + MID[0] + M  # where the body steps up, and down again
    xs = X(a, yw) - 4 * s
    body = t.poly([(X(0, yw + CUT), Y(yw + CUT)), (X(0, yw) + CUT * s, Y(yw)), (xs, Y(yw)), (xs + yw * s, Y(0)),
                   (X(b, 0), Y(0)), (X(b, yw), Y(yw)), (X(SPAN, yw), Y(yw)), (X(SPAN, DH - CUT), Y(DH - CUT)),
                   (X(SPAN, DH) - CUT * s, Y(DH)), (X(0, DH), Y(DH))])
    t.glow(body, 5 * s, ui.BLACK, 0.42)
    t.paint(body, t.ramp(GR["button"][0], GR["button"][1], (t.y - g) / (DH * s)), 0.97)
    t.paint(np.maximum(np.abs(body + 2.1 * s) - 0.35 * s, t.y - Y(yw + 2.5)), c(GR["glint"]), 0.5)
    t.line(body, 1.2 * s, c(GR["edge"]))

    places = []
    x0 = M
    for i, ((name, mark, accent), state) in enumerate(zip(BUTTONS, states)):
        w, tall = MID if i == 1 else WING
        places.append((x0, w, tall))
        y0 = YB - tall
        t.paint(lean(x0 - 1.6, x0 + w + 1.6, y0 - 1.6, YB + 1.6), c(GR["channel"]))
        light = lean(x0 + 5, x0 + w - 5, YB + 3.4, YB + 5.8)
        if state == "open":
            t.glow(lean(x0, x0 + w, y0, YB), 8 * s, c(accent), 0.8)
            t.glow(light, 5 * s, c(accent), 0.9)
            t.paint(light, c(WHITE))
        elif state == "pressed":
            t.paint(light, c(h.DEEP[accent]))
        else:
            t.glow(light, 3 * s, c(accent), 0.4)
            t.paint(light, c(accent))
        x0 += w + G
    for i, ((name, mark, accent), state, (x0, w, tall)) in enumerate(zip(BUTTONS, states, places)):
        sink = 1.6 if state == "pressed" else 0.0
        y0 = YB - tall + sink
        d = lean(x0, x0 + w, y0, YB)
        v = (t.y - Y(y0)) / ((YB - y0) * s)
        top, foot = h.mix(accent, h.PALE[accent], 0.25), h.mix(accent, h.DEEP[accent], 0.42)  # deeper than a pill's block
        u = (t.x - X(x0, (t.y - g) / s)) / (w * s)  # across the tile, along its lean
        if state == "open":
            t.paint(d, h.ramp3(t, WHITE, h.PALE[accent], h.mix(h.PALE[accent], accent, 0.7), v))
        elif state == "pressed":
            t.paint(d, t.ramp(h.mix(accent, h.DEEP[accent], 0.6), h.mix(accent, h.DEEP[accent], 0.25), v))
        else:
            t.paint(d, t.ramp(top, foot, v))
            for u0, u1, alpha in ((0.1, 0.27, 0.24), (0.32, 0.37, 0.16)):  # a sheen across it, leaning as it does
                t.paint(np.maximum(d, (np.abs(u - (u0 + u1) / 2) - (u1 - u0) / 2) * w * s), c(h.PALE[accent]), alpha)
            t.paint(np.maximum(d, t.y - Y(y0 + 2.0)), c(h.PALE[accent]), 0.6)
        # its front face: the tile is a key with a thickness, thinner once pressed
        t.paint(np.maximum(d, Y(YB - (1.4 if sink else 3.2)) - t.y), c(h.DEEP[accent]), 0.62 if state != "open" else 0.4)
        if state == "open":
            t.line(d, 1.1 * s, c(WHITE), 0.95)
        r = MARK[i == 1] * s
        cy = (y0 + YB) / 2 - (0.4 if sink else 1.2)
        fn = (marks or {}).get(name, mark)
        t.paint(fn(t, X(x0 + w / 2, cy), Y(cy), r), c(h.INK))
        if i in dots:  # something new: a pip on the tile's far corner, white as the readout is when it's ready
            px, py = X(x0 + w, y0) - 1.0 * s, Y(y0) + 1.0 * s
            pip = h.g_diamond(t, px, py, 5.0 * s, 6.0 * s)
            t.glow(pip, 3.5 * s, c(WHITE), 0.55)
            t.paint(pip - 2.0 * s, c(h.INK))
            t.paint(pip, c(WHITE))
    h.place(st, t, x - g, y - g)


# --- the pictures ----------------------------------------------------------------------------------------------------

def screen(sc, dots=(), hint=False):
    """The HUD as V2, Block lays it out, the new dock in the old one's place."""
    st = kit.Stage.__new__(kit.Stage)  # its ground is the street, not a fill
    st.w, st.h, st.items = h.W, h.H, []
    st.px = h.backdrop(sc["kind"])
    l, tp, r, b = h.SAFE
    h.phone(st)
    h.target(st, (l + r) / 2 - 108, tp + h.TOP + 18, 0.56)
    h.lead(st, l + h.PAD, tp + h.TOP, sc)
    foot = tp + h.TOP + 89
    h.readout(st, l + h.PAD + 2, foot + 10, 58.0, sc["share"], sc["signature"])
    h.spectate(st, l + h.PAD + 2 + 58 + 10, foot + 10 + 7, 44.0, sc["eye"])
    px = r - h.PAD
    h.pill(st, px - 120, tp + h.TOP, 120, h.CREDITS, h.BLOCK, "CoinMint", "35,170")
    h.pill(st, px - 200, tp + h.TOP + h.PILL + h.GAP, 200, h.POWER, h.BLOCK, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
    mid, y = (l + r) / 2, b - h.PAD - DH
    if hint:
        h.hint(st, mid - 144, y - h.GAP - h.PILL, 288, "65 shards: into the Breaker", h.BLOCK)
    dock(st, mid - DW / 2, y, dots=dots)
    return h.bytes8(h.halve(st.px)), st.items


ROW_W, ROW_H, BIG = 812.0, 186.0, 1.9


def row(title, left, right, notes):
    """The dock up close on a dark ground and on a pale one: each side its states and which tiles carry the pip."""
    st = kit.Stage(ROW_W, ROW_H, h.PARTS_GROUND)
    st.px[:, round(ROW_W / 2 * K4):, :3] = c(h.PALE_GROUND)
    st.text(12, 8, 10, title, h.HEAD)
    for x0, (states, dots), note, ink in ((0.0, left, notes[0], h.NOTE), (ROW_W / 2, right, notes[1], h.INK)):
        dock(st, x0 + (ROW_W / 2 - DW * BIG) / 2, 30, states, dots, BIG)
        st.text(x0 + ROW_W / 4, 30 + DH * BIG + 10, 10, note, ink, "CENTER")
    return h.bytes8(h.halve(st.px)), st.items


def chip(st, x, y, size, fn, r, ink, ground=None):
    t = kit.blank(size, size)
    if ground:
        fill = t.ramp(*ground, t.y / size) if isinstance(ground, tuple) else c(ground)
        t.paint(np.maximum(np.abs(t.x - size / 2), np.abs(t.y - size / 2)) - size / 2, fill)
    t.paint(fn(t, size / 2, size / 2, r), c(ink))
    h.place(st, t, x, y)


MARKS_H = 160.0


def marks_row():
    """Each mark alone: large on its colour, then in one flat colour at 64 and 32 pixels, white on dark and ink on pale.
    This row is halved onto the sheet, so 32 points here are 64 pixels there."""
    st = kit.Stage(ROW_W, MARKS_H, h.PARTS_GROUND)
    st.text(12, 8, 11, "Each mark alone: on its colour; then flat, at 64 and at 32 pixels, white on dark and ink on pale. "
            "Right: Inventory's two other tries, not picked.", h.HEAD)
    every = [(n, f, a, True) for n, f, a in BUTTONS] + [(n, f, h.VOIDKIN, False) for n, f in VARIANTS]
    for i, (name, fn, accent, picked) in enumerate(every):
        x = 16 + i * 160 + (24 if not picked else 0)
        chip(st, x, 30, 56.0, fn, 21.0, h.INK, h.block_tint(accent))
        chip(st, x + 64, 30, 36.0, fn, 16.0, WHITE)
        chip(st, x + 104, 38, 20.0, fn, 8.0, WHITE)
        chip(st, x + 64, 72, 36.0, fn, 16.0, h.INK, h.PALE_GROUND)
        chip(st, x + 104, 80, 20.0, fn, 8.0, h.INK, h.PALE_GROUND)
        st.text(x, 116, 11 if picked else 9, name if picked else name.capitalize(), h.HEAD if picked else h.NOTE)
    st.text(16, 138, 10, "Inventory: a pack by its outline, a shard cut through its face: your whole bag and your Voidkin "
            "in one shape. Base keeps the plant and its bolt, the Map its folded sheet and its way.", h.NOTE)
    return h.bytes8(h.halve(st.px)), st.items


def small(items):
    """A picture's words, for the picture at half its size."""
    return [dict(i, x=i["x"] / 2, y=i["y"] / 2, size=i["size"] / 2) for i in items]


def sheet(out, shots, rows):
    ui.K = 2
    m, cap, head = 20.0, 28.0, 78.0
    tall = head + sum(h.H + cap for _ in shots) + sum(rh + 6 for _, rh in rows) + 22 + h.H / 2 + 14
    sh = ui.Sheet(h.W + 2 * m, tall, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: the dock as three icons (AR12)", h.HEAD)
    t.text(m, 40, 10, "One piece: a graphite body cut as the kit's buttons are, three tiles set in it, each a block of its "
           "system's colour with its mark in ink, as the pills carry theirs. Inventory stands taller in the middle;", h.NOTE)
    t.text(m, 54, 10, f"Base and Map are its wings. {DW:g} by {DH:g} points, bottom centre; a wing's tile is "
           f"{WING[0]:g} by {WING[1]:g}, Inventory's {MID[0]:g} by {MID[1]:g}. No word: a long press shows it (the build's).",
           h.NOTE)
    y = head
    for (px, items), caption in shots:
        h.add(sh, px, items, m, y)
        sh.tile(m, y + h.H + 8, h.W, 16).text(0, 0, 10, caption, h.NOTE)
        y += h.H + cap
    for (px, items), rh in rows:
        h.add(sh, px, items, m, y)
        y += rh + 6
    sh.tile(m, y, h.W, 18).text(0, 4, 10, "The same two screens at a phone's size on a monitor, one pixel a point.", h.NOTE)
    y += 22
    for i, ((px, items), _) in enumerate(shots):
        h.add(sh, h.halve(h.floats(px)), small(items), m + i * (h.W / 2), y)
    kit.finish(sh, out / "hud_dock.png")


def main():
    out = bl.out_dir()
    ui.K = K4
    h.stage("started")
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    h.icons()
    h.card_images()
    noon, dusk = h.SCENES[2], h.SCENES[0]
    shots = [(screen(noon, dots=(1,)), "Noon, a pale street: the dock at rest, a pip on Inventory for something new. "
              "It stands clear of the thumbstick and the jump button."),
             (screen(dusk), "Dusk, in a fight: the dock at rest, beside the lead's card and the pills.")]
    h.stage("the screens")
    rows = [
        (row("Up close, at rest: on a dark ground and on a pale one.", (("rest",) * 3, ()), (("rest",) * 3, ()),
             ("rest", "rest")), ROW_H),
        (row("Its states. Pressed sinks and darkens; open turns white-hot; a pip for something new.",
             (("pressed", "open", "rest"), (2,)), (("open", "rest", "pressed"), (1,)),
             ("Base pressed · Inventory open · a pip on the Map", "Base open · a pip on Inventory · the Map pressed")), ROW_H),
        (marks_row(), MARKS_H),
    ]
    h.stage("the rows")
    h.BACKDROPS.clear()
    kit.IMAGES.clear()
    h.IMG.clear()
    sheet(out, shots, rows)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
