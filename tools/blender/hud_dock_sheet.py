"""AR12, the dock as three icons (the director, 2026-11-15: "we could make a icon of it no need to name it inventory and
make a ui around it, it need to be a very cool ui well composed", then "All three icons"; docs/ui.md, the HUD).

One piece, not three buttons: a graphite body cut as the kit's buttons are, three tiles set in it, each a block of its
system's colour with its mark in ink, as V2, Block's pills carry theirs. Everything leans as a bar's front does. Home
(Inventory until the director's Home, 2026-11-19; AR43) stands in the middle, taller, since the dock is built round it;
Base and Map are its wings. Under each tile runs its light. No word: a long press shows it (the build's).

    blender -b --factory-startup --python tools/blender/hud_dock_sheet.py -- build/handoff/UI/hud/dock
    blender -b --factory-startup --python tools/blender/hud_dock_sheet.py -- build/handoff/UI/hud/dock images
    (add `nosheet` for a light run: the images, the manifest and the parity only)

The first writes the sheet hud_dock.png, its two screens stacked from the images. The second writes the build's
images: images/, hud_dock.json (each button's places, colours and states) and their own sheet hud_dock_images.png,
and prints how far the stack of images stands from the drawing, state by state.
"""
import json
import math
import os
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
SINK, FRONT, FRONT_SUNK = 1.6, 3.2, 1.4  # how far a pressed tile sinks; its front face's height, at rest and pressed


# --- the marks: distances, negative inside, what's inside cut clean through ------------------------------------------

def plant(t, cx, cy, r):
    """The Base: the plant, a bolt cut through it."""
    return np.maximum(h.g_plant(t, cx, cy, r), -h.g_bolt(t, cx, cy + r * 0.22, r * 0.6))


WAY = (((-0.72, 0.42), (-0.48, 0.22)), ((-0.3, 0.12), (-0.02, 0.16)), ((0.14, 0.14), (0.34, -0.04)))


def route(t, cx, cy, r):
    """The Map: the folded sheet, a way cut across it in dashes, ending in a ring (research's fix: a whole line read
    as a chart going up)."""
    dashes = [h.seg(t, (cx + a[0] * r, cy + a[1] * r), (cx + b[0] * r, cy + b[1] * r), 0.15 * r) for a, b in WAY]
    ring = np.abs(np.hypot(t.x - cx - 0.56 * r, t.y - cy + 0.26 * r) - 0.19 * r) - 0.055 * r
    return np.maximum(h.g_map(t, cx, cy, r), -np.minimum.reduce(dashes + [ring]))


def _pts(t, cx, cy, r, pts):
    return t.poly([(cx + r * u, cy + r * v) for u, v in pts])


FLAP = ((-0.7, -0.86), (0.7, -0.86), (1.0, -0.56), (1.0, -0.2), (0.2, -0.2), (0.2, 0.06), (-0.2, 0.06), (-0.2, -0.2),
        (-1.0, -0.2), (-1.0, -0.56))  # folded across the top third, wider than the body, its strap down the face
PACK = ((-0.86, -0.3), (0.86, -0.3), (0.86, 0.78), (0.64, 1.0), (-0.64, 1.0), (-0.86, 0.78))


def inventory(t, cx, cy, r):
    """Your Voidkin and your whole bag: a satchel, its flap folded across its top third with a short strap down its
    face, a shard cut clean through the face under the strap (research's fix: a grip on top read as a weight). Ink
    stands between the strap and the shard: joined, the two read as a necktie."""
    flap = _pts(t, cx, cy, r, FLAP)
    body = np.maximum(_pts(t, cx, cy, r, PACK), -(flap - 0.1 * r))
    return np.minimum(flap, np.maximum(body, -h.g_shard(t, cx, cy + 0.57 * r, 0.3 * r)))


def _screen(t, cx, cy, r, x0, y0, x1, y1):
    """A screen: a box with the kit's cut on its top left and foot right."""
    return t.poly(ui.cut_box(cx + x0 * r, cy + y0 * r, cx + x1 * r, cy + y1 * r, 0.3 * r, 0, 0.3 * r, 0))


def home(t, cx, cy, r):
    """Home, the panel of every screen (the director, 2026-11-19, 12:21; AR43): three screens stacked, each a step up and
    right, the front one with a shard cut through its face: the screens Home opens, and your Voidkin's. Research's pick
    for the Menu at 03:40, kept for Home at 12:56: a house would be Base's."""
    front = _screen(t, cx, cy, r, -0.92, -0.52, 0.5, 0.98)
    mid = _screen(t, cx, cy, r, -0.7, -0.75, 0.72, 0.75)
    back = _screen(t, cx, cy, r, -0.48, -0.98, 0.94, 0.52)
    gap = 0.13 * r
    back = np.maximum(back, -(np.minimum(front, mid) - gap))
    mid = np.maximum(mid, -(front - gap))
    face = np.maximum(front, -h.g_shard(t, cx - 0.21 * r, cy + 0.24 * r, 0.5 * r))
    return np.minimum.reduce([face, mid, back])


# Left to right. The dock is built round Home (Inventory's place until the director's Home, 2026-11-19), the middle.
BUTTONS = (("Base", plant, h.POWER), ("Home", home, h.VOIDKIN), ("Map", route, h.MAP))
VARIANTS = (("Inventory's satchel, replaced by Home", inventory),)


# --- the dock --------------------------------------------------------------------------------------------------------

def tiles():
    """Each tile's left along the body's foot, its width and its height, left to right."""
    out, x0 = [], M
    for i in range(len(BUTTONS)):
        w, tall = MID if i == 1 else WING
        out.append((x0, w, tall))
        x0 += w + G
    return out


def body_on(t, X, Y, lean, s=1.0):
    """The body: its shadow, the graphite stepping up round the middle tile, its glint and edge, the three wells."""
    yw = YB - WING[1] - M  # the wings' top
    a, b = M + WING[0] + G - M, M + WING[0] + G + MID[0] + M  # where the body steps up, and down again
    xs = X(a, yw) - 4 * s
    body = t.poly([(X(0, yw + CUT), Y(yw + CUT)), (X(0, yw) + CUT * s, Y(yw)), (xs, Y(yw)), (xs + yw * s, Y(0)),
                   (X(b, 0), Y(0)), (X(b, yw), Y(yw)), (X(SPAN, yw), Y(yw)), (X(SPAN, DH - CUT), Y(DH - CUT)),
                   (X(SPAN, DH) - CUT * s, Y(DH)), (X(0, DH), Y(DH))])
    t.glow(body, 5 * s, ui.BLACK, 0.42)
    t.paint(body, t.ramp(GR["button"][0], GR["button"][1], (t.y - Y(0)) / (DH * s)), 0.97)
    t.paint(np.maximum(np.abs(body + 2.1 * s) - 0.35 * s, t.y - Y(yw + 2.5)), c(GR["glint"]), 0.5)
    t.line(body, 1.2 * s, c(GR["edge"]))
    for x0, w, tall in tiles():
        t.paint(lean(x0 - 1.6, x0 + w + 1.6, YB - tall - 1.6, YB + 1.6), c(GR["channel"]))


def dock(st, x, y, states=("rest",) * 3, dots=(), s=1.0, marks=None):
    """The dock with its top left at x, y, `s` times its size. A state: rest, pressed, open. `dots`: which tiles carry
    the mark for something new. Drawn in the order the build stacks it: shadow, body, wells, lights, tiles, marks."""
    g = GLOW * s
    t = kit.blank(DW * s + 2 * g, DH * s + 2 * g)

    def X(xb, yy):
        return g + (OX + xb + LEAN * (YB - yy)) * s

    def Y(yy):
        return g + yy * s

    def lean(x0, x1, y0, y1):
        return t.poly([(X(x0, y0), Y(y0)), (X(x1, y0), Y(y0)), (X(x1, y1), Y(y1)), (X(x0, y1), Y(y1))])

    body_on(t, X, Y, lean, s)
    places = tiles()
    for (name, mark, accent), state, (x0, w, tall) in zip(BUTTONS, states, places):
        y0 = YB - tall
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
    for i, ((name, mark, accent), state, (x0, w, tall)) in enumerate(zip(BUTTONS, states, places)):
        sink = SINK if state == "pressed" else 0.0
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
        t.paint(np.maximum(d, Y(YB - (FRONT_SUNK if sink else FRONT)) - t.y), c(h.DEEP[accent]),
                0.62 if state != "open" else 0.4)
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


# --- the dock in images, for the build --------------------------------------------------------------------------------

ORIGIN = {}  # an image's top left in the dock's points, from the body's top left, at its first place
PARTS = []  # the images' names, in the order they're made
SYSTEM = {h.POWER: "Base", h.VOIDKIN: "Voidkin", h.MAP: "Map"}  # hud_colour.json's row for each tile's colour
MARK_BOX, MARK_R = 64.0, 24.0  # a mark's image and the half size it's drawn at: large, since Home's shows at 51
HALO, STEP = 22.0, 0.004  # how far an open tile's light reaches; half the width of a hard step in a tile's gradient


def _q(v, up=False):
    """To a whole pixel, in points."""
    return (math.ceil(v * K4 - 1e-6) if up else math.floor(v * K4 + 1e-6)) / K4


class Part:
    """A clear canvas over a box of the dock, drawn on in the dock's own points."""

    def __init__(self, x0, y0, x1, y1):
        self.ox, self.oy = _q(x0), _q(y0)
        self.t = kit.blank(_q(x1, True) - self.ox, _q(y1, True) - self.oy)

    def X(self, xb, yy):
        return OX + xb + LEAN * (YB - yy) - self.ox

    def Y(self, yy):
        return yy - self.oy

    def lean(self, x0, x1, y0, y1):
        X, Y = self.X, self.Y
        return self.t.poly([(X(x0, y0), Y(y0)), (X(x1, y0), Y(y0)), (X(x1, y1), Y(y1)), (X(x0, y1), Y(y1))])

    def keep(self, name, tint=None, cut=None, use=""):
        kit.keep(name, self.t, tint, cut, use=use)
        ORIGIN[name] = (self.ox, self.oy)
        PARTS.append(name)


def parts():
    """The dock's images. The body is in its graphite, as the readout's plate is. A tile's layers are white: the engine
    gives each its system's colours, so one wing serves Base and the Map. The marks and the pip are in their own colours."""
    ORIGIN.clear()
    PARTS.clear()
    g = GLOW
    p = Part(-g, -g, DW + g, DH + g)
    body_on(p.t, p.X, p.Y, p.lean)
    p.keep("DockBody", use="the whole body: shadow, graphite, glint, edge and the three wells. Under everything")
    spots = tiles()
    for key, (x0, w, tall) in (("Wing", spots[0]), ("Mid", spots[1])):
        y0 = YB - tall
        box = (OX + x0 - 0.25, y0, OX + x0 + w + LEAN * tall + 0.25, YB)
        whose = "Base's and the Map's" if key == "Wing" else "Home's"
        p = Part(*box)
        p.t.paint(p.lean(x0, x0 + w, y0, YB), c(WHITE))
        p.keep(f"DockTile{key}", "the state's gradient, top to foot (buttons.<state>.tile)",
               use=f"{whose} tile, at rest and open")
        p = Part(box[0], y0 + SINK, box[2], box[3])
        p.t.paint(p.lean(x0, x0 + w, y0 + SINK, YB), c(WHITE))
        p.keep(f"DockTile{key}Pressed", "pressed's gradient, top to foot (buttons.pressed.tile)",
               use=f"{whose} tile, pressed: {SINK:g} shorter, its foot where it was")
        p = Part(*box)
        t = p.t
        d = p.lean(x0, x0 + w, y0, YB)
        u = (t.x - p.X(x0, t.y + p.oy)) / w  # across the tile, along its lean
        for u0, u1, alpha in ((0.1, 0.27, 0.24), (0.32, 0.37, 0.16)):
            t.paint(np.maximum(d, (np.abs(u - (u0 + u1) / 2) - (u1 - u0) / 2) * w), c(WHITE), alpha)
        t.px[..., 3] *= np.where(t.y > p.Y(YB - FRONT), 0.38, 1.0)  # the front face lies over the sheen and dims it
        t.paint(np.maximum(d, t.y - p.Y(y0 + 2.0)), c(WHITE), 0.6)
        p.keep(f"DockSheen{key}", "the system's pale", use="at rest only, over the tile: its sheen and its lit top")
        p = Part(*box)
        p.t.line(p.lean(x0, x0 + w, y0, YB), 1.1, c(WHITE), 0.95)
        p.keep(f"DockEdge{key}", use="open only, over the tile: its white rim")
        p = Part(box[0] - HALO, box[1] - HALO, box[2] + HALO, YB + 5.8 + HALO)
        t = p.t
        t.glow(p.lean(x0, x0 + w, y0, YB), 8.0, c(WHITE), 0.8)
        t.glow(p.lean(x0 + 5, x0 + w - 5, YB + 3.4, YB + 5.8), 5.0, c(WHITE), 0.9)
        rim = np.minimum(np.minimum(t.x, t.w - t.x), np.minimum(t.y, t.h - t.y))
        t.px[..., 3] *= np.clip(rim / 5.0, 0, 1)  # it ends on nothing, never on its image's side
        p.keep(f"DockHalo{key}", "the system's colour",
               use="open only, under the light and the tile: the tile's and the light's glow")
    x0, w, tall = spots[0]
    for name, pad in (("DockLight", 0.0), ("DockLightGlow", 9.0)):
        p = Part(OX + x0 + 5 - LEAN * 5.8 - 0.25 - pad, YB + 3.4 - pad,
                 OX + x0 + w - 5 - LEAN * 3.4 + 0.25 + pad, YB + 5.8 + pad)
        d = p.lean(x0 + 5, x0 + w - 5, YB + 3.4, YB + 5.8)
        if pad:
            p.t.glow(d, 3.0, c(WHITE), 0.4)
            p.keep(name, "the system's colour", (pad + 4.0, 0.0, pad + 4.0, 0.0), "at rest only, under the light")
        else:
            p.t.paint(d, c(WHITE))
            p.keep(name, "rest: the system's colour; pressed: its deep; open: white", (4.0, 0.0, 4.0, 0.0),
                   "the light under a tile; it stretches between its cut ends, 8 longer under Home")
    for name, fn, _ in BUTTONS:
        t = kit.blank(MARK_BOX, MARK_BOX)
        t.paint(fn(t, MARK_BOX / 2, MARK_BOX / 2, MARK_R), c(h.INK))
        kit.keep(f"DockMark{name}", t, use=f"{name}'s mark, in ink, on its tile")
        PARTS.append(f"DockMark{name}")
    px, py = OX + x0 + w + LEAN * tall - 1.0, YB - tall + 1.0  # on a tile's far corner
    p = Part(px - 13.0, py - 14.0, px + 13.0, py + 14.0)
    pip = h.g_diamond(p.t, px - p.ox, py - p.oy, 5.0, 6.0)
    p.t.glow(pip, 3.5, c(WHITE), 0.55)
    p.t.px[..., 3] *= np.clip(np.minimum(np.minimum(p.t.x, p.t.w - p.t.x), np.minimum(p.t.y, p.t.h - p.t.y)) / 3.0, 0, 1)
    p.t.paint(pip - 2.0, c(h.INK))
    p.t.paint(pip, c(WHITE))
    p.keep("DockPip", use="something new: over a tile's far corner, over its mark")


def stops(accent, state, tall):
    """A tile's colours top to foot, as a gradient's stops: its ramp, then a hard step into its front face."""
    pale, deep = h.PALE[accent], h.DEEP[accent]
    if state == "pressed":
        tall, front, alpha = tall - SINK, FRONT_SUNK, 0.62
        ramp = [(0.0, h.mix(accent, deep, 0.6)), (1.0, h.mix(accent, deep, 0.25))]
    elif state == "open":
        front, alpha = FRONT, 0.4
        ramp = [(0.0, WHITE), (0.5, pale), (1.0, h.mix(pale, accent, 0.7))]
    else:
        front, alpha = FRONT, 0.62
        ramp = [(0.0, h.mix(accent, pale, 0.25)), (1.0, h.mix(accent, deep, 0.42))]
    v = 1.0 - front / tall
    (a0, c0), (a1, c1) = ramp[-2], ramp[-1]
    at = h.mix(c0, c1, (v - a0) / (a1 - a0))
    return [[round(a, 4), col] for a, col in ramp[:-1] + [(v - STEP, at), (v + STEP, h.mix(at, deep, alpha)),
                                                           (1.0, h.mix(c1, deep, alpha))]]


def layout():
    """Each button's places, colours and states, in the dock's points from the body's top left: what the build reads."""
    out = []
    light, glow = kit.IMAGES["DockLight"], kit.IMAGES["DockLightGlow"]
    home = tiles()
    for i, ((name, _, accent), (x0, w, tall)) in enumerate(zip(BUTTONS, home)):
        key = "Mid" if i == 1 else "Wing"
        y0, first = YB - tall, home[1 if i == 1 else 0][0]

        def at(image, dx=x0 - first, dy=0.0):
            return dict(image=image, at=[round(ORIGIN[image][0] + dx, 3), round(ORIGIN[image][1] + dy, 3)])

        cy = (y0 + YB) / 2 - 1.2
        longer = w - WING[0]
        out.append(dict(
            name=name, system=SYSTEM[accent], colour=accent, pale=h.PALE[accent], deep=h.DEEP[accent],
            box=[round(OX + x0, 3), y0, round(w + LEAN * tall, 3), tall],
            tile=at(f"DockTile{key}"), tilePressed=at(f"DockTile{key}Pressed"), sheen=at(f"DockSheen{key}"),
            edge=at(f"DockEdge{key}"), halo=at(f"DockHalo{key}"),
            light=dict(at("DockLight", x0 - M), size=[light["w"] + longer, light["h"]]),
            lightGlow=dict(at("DockLightGlow", x0 - M), size=[glow["w"] + longer, glow["h"]]),
            mark=dict(image=f"DockMark{name}", middle=[round(OX + x0 + w / 2 + LEAN * (YB - cy), 3), round(cy, 3)],
                      size=round(MARK_BOX * MARK[i == 1] / MARK_R, 3)),
            pip=at("DockPip", (x0 + w + LEAN * tall) - (M + WING[0] + LEAN * WING[1]), y0 - (YB - WING[1])),
            rest=dict(tile=stops(accent, "rest", tall), light=accent, lightGlow=accent, sheen=h.PALE[accent]),
            pressed=dict(tile=stops(accent, "pressed", tall), light=h.DEEP[accent]),
            open=dict(tile=stops(accent, "open", tall), light=WHITE, halo=accent)))
    return out


def tinted(st, name, x, y, ramp):
    """A white tile under its gradient, as the engine tints it."""
    px = kit.IMAGES[name]["px"].copy()
    v = (np.arange(px.shape[0]) + 0.5) / px.shape[0]
    px[..., :3] *= np.stack([np.interp(v, [a for a, _ in ramp], [c(col)[i] for _, col in ramp]) for i in range(3)],
                            -1).astype(np.float32)[:, None, :]
    rs.paste(st.px, px, round(x * K4), round(y * K4))


def stack(st, x, y, states=("rest",) * 3, dots=()):
    """The dock from its images, laid as the engine lays them: the body; each tile's halo or light's glow, then its
    light; each tile under its gradient, its sheen or its rim, its mark, its pip."""
    rows = layout()

    def lay(part, **kw):
        st.lay(part["image"], x + part["at"][0], y + part["at"][1], *part.get("size", ()), **kw)

    lay(dict(image="DockBody", at=ORIGIN["DockBody"]))
    for b, state in zip(rows, states):
        if state == "open":
            lay(b["halo"], tint=b["colour"])
        elif state == "rest":
            lay(b["lightGlow"], tint=b["colour"])
        lay(b["light"], tint=b[state]["light"])
    for i, (b, state) in enumerate(zip(rows, states)):
        sink = SINK if state == "pressed" else 0.0
        tile = b["tilePressed" if sink else "tile"]
        tinted(st, tile["image"], x + tile["at"][0], y + tile["at"][1], b[state]["tile"])
        if state == "rest":
            lay(b["sheen"], tint=b["pale"])
        elif state == "open":
            lay(b["edge"])
        st.icon(b["mark"]["image"], x + b["mark"]["middle"][0] - LEAN * sink, y + b["mark"]["middle"][1] + sink,
                b["mark"]["size"])
        if i in dots:
            lay(b["pip"])


CASES = ((("rest",) * 3, ()), (("pressed", "open", "rest"), (2,)), (("open", "rest", "pressed"), (1,)),
         (("rest", "pressed", "open"), (0,)))


def parity():
    """How far the stack of images stands from the drawing, on a mid grey, in 8 bit steps: the most on any pixel and
    where, and the share of pixels more than two steps off. Then the same outside the marks' boxes: a mark is its
    image brought down to its size, so its edge sits a part of a pixel from the drawing's."""
    g = GLOW + 4
    rows = layout()
    for states, dots in CASES:
        pair = []
        for draw in (dock, stack):
            st = kit.Stage(DW + 2 * g, DH + 2 * g, "#6E7078")
            draw(st, g, g, states, dots)
            pair.append(st.px[..., :3] * 255)
        off = np.abs(pair[0] - pair[1]).max(axis=-1)
        y, x = np.unravel_index(off.argmax(), off.shape)
        clear = np.ones(off.shape, bool)
        for b, state in zip(rows, states):
            sink = SINK if state == "pressed" else 0.0
            half = b["mark"]["size"] / 2
            x0, x1 = (round((g + b["mark"]["middle"][0] - LEAN * sink + k * half) * K4) for k in (-1, 1))
            y0, y1 = (round((g + b["mark"]["middle"][1] + sink + k * half) * K4) for k in (-1, 1))
            clear[y0:y1, x0:x1] = False
        rest = np.where(clear, off, 0)
        ry, rx = np.unravel_index(rest.argmax(), rest.shape)
        print(f"parity {'/'.join(states)}, pips {dots}: most {off.max():.1f} at {x / K4 - g:.2f}, {y / K4 - g:.2f}, "
              f"mean {off.mean():.3f}, over two steps {100 * (off > 2).mean():.2f}%; outside the marks: most "
              f"{rest.max():.1f} at {rx / K4 - g:.2f}, {ry / K4 - g:.2f}, over two steps "
              f"{100 * (rest[clear] > 2).mean():.2f}%, over eight {100 * (rest[clear] > 8).mean():.2f}%", flush=True)
        if os.environ.get("DOCK_PARITY_MAP"):  # the difference as a picture, white where it's 32 steps or more
            m = np.ones(off.shape + (4,), np.float32)
            m[..., :3] = np.clip(off / 32, 0, 1)[..., None]
            rs.save(m, Path(os.environ["DOCK_PARITY_MAP"]) / f"parity_{'_'.join(states)}.png")


def manifest(out):
    data = dict(
        pixelsPerPoint=K4, size=[DW, DH], lean=LEAN,
        note="The dock as three icons (AR12). One piece of a fixed size, bottom centre. Every place is in points from "
             "the body's top left; an image's `at` is its own top left, and it's shown at its `points` (or the `size` "
             "given, for the light, which stretches between its `cut` ends). A white image takes its tint; the body, "
             "the marks and the pip are in colour. A tile leans: its `box` is the box round it, the tap. It replaces "
             "the dock of buttons with words (hud_colour.json, pieces.dock, BlockDock).",
        stack=["DockBody at its `at`",
               "each button: open, its halo in its colour; at rest, its light's glow in its colour; then its light",
               "each button: its tile under its state's gradient, top to foot; at rest its sheen in its pale; open, "
               "its rim; its mark, its middle at `mark.middle`, `mark.size` across; its pip when it has something new"],
        states=dict(
            rest="the tile's gradient, the sheen, the light and its glow in the system's colour",
            pressed=f"the tile's pressed image at `tilePressed` ({SINK:g} shorter, its foot where it was) under "
                    f"pressed's gradient, no sheen; the mark {SINK:g} lower and {LEAN * SINK:g} to the left; the light "
                    "in the system's deep, no glow",
            open="the tile white-hot under its gradient, its rim over it, its halo under it, the light white; the "
                 "mark stays in ink",
            new="DockPip over the tile's far corner, in any state"),
        gradient=f"a tile's stops are [share of its height from the top, colour]; the two stops {2 * STEP:g} apart "
                 "are the hard step into its front face",
        buttons=layout(),
        images={n: dict(file=f"images/{n}.png", pixels=[im["px"].shape[1], im["px"].shape[0]], points=[im["w"], im["h"]],
                        **({"at": list(ORIGIN[n])} if n in ORIGIN else {}), **({"tint": im["tint"]} if im["tint"] else {}),
                        **({"cut": list(im["cut"])} if im["cut"] else {}), use=im["use"])
                for n, im in ((n, kit.IMAGES[n]) for n in PARTS)})
    (out / "hud_dock.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print(f"wrote {out / 'hud_dock.json'}: {len(PARTS)} images")


def images_shot():
    """The delivered images on one picture, the marks small for research's read, then the dock stacked from them."""
    st = kit.Stage(880.0, 504.0, h.PARTS_GROUND)
    st.text(12, 8, 11, "The images as delivered. White ones take their tint in the engine; the body, the marks and the "
            "pip are in colour.", h.HEAD)
    st.lay("DockBody", 12, 28)
    st.text(124, 128, 9, "DockBody", h.NOTE, "CENTER")
    x = 250.0
    for name, y in (("DockTileWing", 40), ("DockTileMid", 30), ("DockSheenWing", 40), ("DockSheenMid", 30),
                    ("DockEdgeWing", 40), ("DockEdgeMid", 30)):
        st.lay(name, x, y)
        st.text(x + kit.IMAGES[name]["w"] / 2, 92, 9, name[4:], h.NOTE, "CENTER")
        x += kit.IMAGES[name]["w"] + 12
    st.lay("DockLight", x, 44, kit.IMAGES["DockLight"]["w"], kit.IMAGES["DockLight"]["h"])
    st.text(x + 22, 54, 9, "Light", h.NOTE, "CENTER")
    st.lay("DockLightGlow", x - 9, 66, kit.IMAGES["DockLightGlow"]["w"], kit.IMAGES["DockLightGlow"]["h"], tint=h.POWER)
    st.text(x + 22, 92, 9, "LightGlow", h.NOTE, "CENTER")
    st.lay("DockPip", x + 64, 36)
    st.text(x + 77, 92, 9, "Pip", h.NOTE, "CENTER")
    st.text(250, 108, 9, "A wing's layers serve Base and the Map; Mid is Home's. Each tile has a pressed twin, "
            "1.6 points shorter.", h.NOTE)
    st.text(250, 121, 9, "LightGlow is shown in Power's colour, the halos below in the Map's and the Voidkin's.", h.NOTE)
    st.lay("DockHaloWing", 12, 146, tint=h.MAP)
    st.lay("DockHaloMid", 124, 140, tint=h.VOIDKIN)
    st.text(64, 252, 9, "HaloWing", h.NOTE, "CENTER")
    st.text(182, 252, 9, "HaloMid", h.NOTE, "CENTER")
    for i, (name, _, accent) in enumerate(BUTTONS):  # each mark from its image: whole, then at 64 and at 32 pixels
        x = 262 + i * 206
        for bx, by, size, ground in ((x, 150, 72.0, h.block_tint(accent)), (x + 80, 150, 36.0, h.block_tint(accent)),
                                     (x + 124, 158, 20.0, h.block_tint(accent)), (x + 80, 192, 36.0, h.PALE_GROUND),
                                     (x + 124, 200, 20.0, h.PALE_GROUND)):
            x0, x1, y0, y1 = (round(v * K4) for v in (bx, bx + size, by, by + size))
            st.px[y0:y1, x0:x1, :3] = kit.shade(ground, y1 - y0) if isinstance(ground, tuple) else c(ground)[:3]
            st.icon(f"DockMark{name}", bx + size / 2, by + size / 2, size * 8 / 9)
        st.text(x, 232, 10, f"DockMark{name}", h.HEAD)
        st.text(x, 247, 9, "its image; then at 64 and at 32 pixels", h.NOTE)
    st.text(12, 276, 11, "Stacked from the images, as the engine stacks them, two pixels a point here: at rest; pressed, "
            "open and a pip in turn. On a dark ground, then a pale one.", h.HEAD)
    st.px[round(396 * K4):, :, :3] = c(h.PALE_GROUND)[:3]
    for y in (308, 416):
        for i, (states, dots) in enumerate(CASES):
            stack(st, 15 + i * 218, y, states, dots)
    return h.bytes8(h.halve(st.px)), st.items


def images_close():
    """Two docks from the images at this sheet's largest: four pixels a point."""
    st = kit.Stage(440.0, 104.0, h.PARTS_GROUND)
    st.px[:, round(220 * K4):, :3] = c(h.PALE_GROUND)[:3]
    stack(st, 12, 18, ("rest",) * 3, (1,))
    stack(st, 232, 18, ("pressed", "open", "rest"), (2,))
    return h.bytes8(st.px)


def images_main(out, sheet=True):
    """The dock's images for the build: images/, hud_dock.json and a sheet of them, in the handoff folder. Without the
    sheet it's a light run: the images, the manifest and the parity's numbers."""
    parts()
    (out / "images").mkdir(exist_ok=True)
    for name in PARTS:
        px = kit.IMAGES[name]["px"].copy()
        kit.bleed(px)
        rs.save(px, out / "images" / f"{name}.png")
    manifest(out)
    parity()
    if not sheet:
        return
    shot, close = images_shot(), images_close()
    kit.IMAGES.clear()
    h.stage("the images saved, the sheet's pictures drawn")
    ui.K = 2
    m = 20.0
    page = ui.Sheet(880 + 2 * m, 44 + 504 + 26 + 208 + 16, h.GROUND)
    t = page.tile(0, 0, page.w, page.h)
    t.text(m, 14, 17, "Grow your Anime: the dock's images, as delivered (AR12)", h.HEAD)
    h.add(page, *shot, m, 44)
    t.text(m, 44 + 504 + 8, 10, "The same stack, four pixels a point: at rest with a pip on Home; Base pressed, "
           "Home open, a pip on the Map.", h.NOTE)
    h.add(page, close, [], m, 44 + 504 + 26)
    kit.finish(page, out / "hud_dock_images.png")
    h.stage("the images' sheet")


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
    stack(st, mid - DW / 2, y, dots=dots)  # from the images, as the build lays it
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
            "Right: Inventory's satchel, which Home replaces.", h.HEAD)
    every = [(n, f, a, True) for n, f, a in BUTTONS] + [(n, f, h.VOIDKIN, False) for n, f in VARIANTS]
    for i, (name, fn, accent, picked) in enumerate(every):
        x = 16 + i * 160 + (24 if not picked else 0)
        chip(st, x, 30, 56.0, fn, 21.0, h.INK, h.block_tint(accent))
        chip(st, x + 64, 30, 36.0, fn, 16.0, WHITE)
        chip(st, x + 104, 38, 20.0, fn, 8.0, WHITE)
        chip(st, x + 64, 72, 36.0, fn, 16.0, h.INK, h.PALE_GROUND)
        chip(st, x + 104, 80, 20.0, fn, 8.0, h.INK, h.PALE_GROUND)
        st.text(x, 116, 11 if picked else 9, name if picked else name.capitalize(), h.HEAD if picked else h.NOTE)
    st.text(16, 138, 10, "Home: three screens stacked, a shard cut through the front one: the screens it opens, your "
            "Voidkin's first. Base keeps the plant and its bolt, the Map its folded sheet and its way.", h.NOTE)
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
           "system's colour with its mark in ink, as the pills carry theirs. Home stands taller in the middle;", h.NOTE)
    t.text(m, 54, 10, f"Base and Map are its wings. {DW:g} by {DH:g} points, bottom centre; a wing's tile is "
           f"{WING[0]:g} by {WING[1]:g}, Home's {MID[0]:g} by {MID[1]:g}. No word: a long press shows it (the build's).",
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
    mode = sys.argv[sys.argv.index("--") + 2:]
    if mode[:1] == ["images"]:
        return images_main(out, sheet="nosheet" not in mode)
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    h.icons()
    h.card_images()
    parts()
    noon, dusk = h.SCENES[2], h.SCENES[0]
    shots = [(screen(noon, dots=(1,)), "Noon, a pale street: the dock at rest, a pip on Home for something new. "
              "It stands clear of the thumbstick and the jump button."),
             (screen(dusk), "Dusk, in a fight: the dock at rest, beside the lead's card and the pills.")]
    h.stage("the screens")
    rows = [
        (row("Up close, at rest: on a dark ground and on a pale one.", (("rest",) * 3, ()), (("rest",) * 3, ()),
             ("rest", "rest")), ROW_H),
        (row("Its states. Pressed sinks and darkens; open turns white-hot; a pip for something new.",
             (("pressed", "open", "rest"), (2,)), (("open", "rest", "pressed"), (1,)),
             ("Base pressed · Home open · a pip on the Map", "Base open · a pip on Home · the Map pressed")), ROW_H),
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
