"""AR51, the blockout (docs/asset-requests.md, AR51): the Stone Condenser's convert panel, three directions on the Comb
at Stage I, each in its four states (ready, running, can't start, asleep), through the game's camera behind a player
at the prompt's reach, at the smallest phone's pixels. A block-in: boxes in the base kit's swatches and flat cards,
nothing exported.

  A, the Slate      a six-sided slate on the cradle, its face a SurfaceGui: the stones' pictures, a bar, one big word
  B, the Tag        the cradle as it stands, the stones lying on it; the words on a card at fixed pixels over it, the
                    machines' plates' kin
  C, the Sixth Cup  five cups round one large cup on a slate of the Comb's make, lit by the state; the words a second
                    line on the Comb's own plate

    blender -b --factory-startup --python-exit-code 1 --python tools/blender/condenser_panel.py -- <abs out dir> [fast]

Writes condenser_panel_A.png, _B.png, _C.png and condenser_panel_glance.png into the out dir. The plates, the tag and
the slate's face are drawn here in Blender's face, standing in for the game's; the prompt's own button isn't drawn.

The finish (AR51, "Research's pick": B), with `finish` in place of `fast`: B's card at the game's own sizes (text at
Theme.Text's 14 or more, where the blockout's stood at 10.5) and with the pick's first must-fix (asleep, the card keeps
its cost line dimmed and says nothing the plate says), beside the Comb's plate as the build draws it. Writes
condenser_card.json, the card's spec for the build, from the numbers below, and condenser_card.png.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_levels_block as lv  # noqa: E402
import base_forge as bf  # noqa: E402
import ui_kit as uk  # noqa: E402
import ui_sheet as ui  # noqa: E402
from base_mill import FACING, Mesh, at, put, turned  # noqa: E402

plan, base, look, kit, bl, day, rs = lv.plan, lv.base, lv.look, lv.kit, lv.bl, lv.day, lv.plan.rs
Piece, c = kit.Piece, ui.c
REPO = Path(__file__).resolve().parents[2]
STONES = REPO / "build" / "handoff" / "UI" / "upgrades" / "images"

SIZE = (852, 480)
LEVEL = 2                                  # the base's level the Condenser wakes at (Config.Condenser.Wakes)
HOME = plan.SLEEPING["condenser"]          # across, in from the front edge
CRADLE = (-3.0, 3.2)                       # AR28's cradle on the Comb's front corner, in the Condenser's frame
TILT = 28.0                                # a slate's lean back, degrees: toward the camera over a player's head
STAND = ((1.0, 8.6), (1.5, 12.0))          # where the player stands, in the Condenser's frame: at it (6.7 from the
# cradle), and at the edge of the prompt's reach (9.9); on the cradle's other side, or the avatar hides it
TRAY = 6                                   # cups lit on the Comb in every awake frame (a tray of 2 over a cap of 12)
# The four states, as BaseController reads them: what the bag holds of the 5, the share of the 30 minutes done
STATES = (("ready", "Ready: 12 Low in the bag", dict(have=12, done=None, awake=True)),
          ("running", "Running: 18 of 30 minutes left", dict(have=7, done=0.4, awake=True)),
          ("short", "Can't start: 3 of 5 Low in the bag", dict(have=3, done=None, awake=True)),
          ("asleep", "Asleep, below base level 2", dict(have=12, done=None, awake=False)))
SLAB, EDGE, TEXT, SOFT, FAINT = ("#34606C", "#2A4E5A"), "#E2CFA4", "#FFF6E2", "#D9E8E2", "#A9C0BC"   # Config.UIKit's System
BED, SEAM = "#0D1418", "#FFB878"           # a face's dark bed; the stones' own seam
GROUND, HEAD, NOTE = "#14161B", "#F3EFE6", "#C9CDD6"


# --- the flat parts: cards drawn at 4 pixels a point --------------------------------------------------------------------

def card(w, h, draw):
    """A transparent card w by h points, drawn by `draw(tile)`, its text set."""
    ui.K = 4
    sheet = ui.Sheet(w, h, "#000000")
    sheet.px[:] = 0
    draw(sheet.tile(0, 0, w, h))
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        ui.over(sheet.px, layer[..., :3], layer[..., 3].copy())
    return sheet.px.copy()


def stone(t, grade, x, y, size, dim=1.0):
    px = rs.shrink(rs.load(STONES / f"Stone{grade}.png"), size * ui.K / 256)
    px[..., 3] *= dim
    t.image(px, x, y)


def slab(t, x0, y0, x1, y1, cut=7.0, dim=1.0, edge=EDGE):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut * 0.3, cut, cut * 0.3))
    t.glow(d, 3.0, ui.BLACK, 0.3)
    t.paint(d, t.ramp(SLAB[0], SLAB[1], (t.y - y0) / (y1 - y0)), 0.95)
    t.line(d, 1.2, c(edge), 0.95 * dim)
    return d


def gauge(t, x, y, w, h, share, colour=SEAM):
    d = t.poly(ui.cut_box(x, y, x + w, y + h, h * 0.4, 0, h * 0.4, 0))
    t.paint(d, c("#070A0C"))
    if share > 0:
        t.paint(np.maximum(d + 1.0, t.x - (x + 1.0 + (w - 2.0) * share)), c(colour))


def arrow(t, x, cy, size, colour, alpha=1.0):
    t.paint(t.poly([(x, cy - size / 2), (x + size * 0.7, cy), (x, cy + size / 2)]), c(colour), alpha)


def minutes(done):
    return f"{round(30 * (1 - done))} min left"


def plate(lines):
    """A machine's plate (World.Plate): its lines in the caption's size, a stand-in for the build's."""
    w, h = 150.0, len(lines) * 16.0 + 10.0

    def draw(t):
        slab(t, 4, 4, w + 4, h + 4, cut=6.0)
        for k, (text, colour) in enumerate(lines):
            t.text(4 + w / 2, 4 + 9 + k * 16.0, 10.5, text, colour, "CENTER")
    return card(w + 8, h + 8, draw)


def tag(state):
    """B's card, over the cradle at fixed pixels: the cost in the stones' own pictures, then how it stands."""
    w, h = 148.0, 58.0
    awake, done, have = state["awake"], state["done"], state["have"]
    dim = 1.0 if awake and (done is not None or have >= 5) else 0.55

    def draw(t):
        slab(t, 4, 4, w + 4, h + 4, dim=dim, edge=EDGE if dim == 1.0 else FAINT)
        t.text(14, 16, 15, "5", TEXT if dim == 1.0 else FAINT)
        stone(t, "Low", 24, 6, 30, dim)
        arrow(t, 62, 22, 10, EDGE, dim)
        t.text(78, 16, 15, "1", TEXT if dim == 1.0 else FAINT)
        stone(t, "Mid", 88, 6, 30, dim)
        if not awake:
            t.text(14, 43, 10.5, "Wakes at base level 2", SOFT)
        elif done is not None:
            gauge(t, 14, 41, 60, 8, done)
            t.text(80, 41, 10.5, minutes(done), TEXT)
        elif have >= 5:
            gauge(t, 14, 41, 60, 8, 1.0, "#F6FCFF")
            t.text(80, 41, 10.5, "Ready", TEXT)
        else:
            gauge(t, 14, 41, 60, 8, have / 5, FAINT)
            t.text(80, 41, 10.5, f"{have} of 5 Low", SOFT)
    return card(w + 8, h + 8, draw)


# --- the finish: B's card at the game's sizes ---------------------------------------------------------------------------
# Points at Theme.Author (812 by 375), from the card's top-left corner. One home for the numbers: condenser_card.json
# is written from this table.
CARD = dict(
    size=(172.0, 70.0), asleep=(172.0, 44.0), corners=(7.0, 2.1, 7.0, 2.1), fill=SLAB, fillAlpha=0.95, edgeWidth=1.2,
    digits=20.0, word=14.0,                       # Theme.Text.Title and Theme.Text.Caption
    take=dict(digit=(12.0, 15.0), stone=(26.0, 4.0, 36.0)),      # a digit's left and cap top; a stone's left, top, size
    arrow=dict(left=69.0, middle=22.0, size=(8.0, 12.0)),        # ArrowRight (condenser_power.py), tinted Edge
    give=dict(digit=(85.0, 15.0), stone=(98.0, 4.0, 36.0)),
    bar=dict(box=(12.0, 50.0, 64.0, 10.0), bed="#070A0C", inset=1.0),
    line=(84.0, 50.0),                            # the second line's word: its left and cap top
    place=(22.0, -50.0),                          # the card's left and top from the cradle's point on the screen
)
CARD_STATES = dict(
    ready=dict(edge=EDGE, cost=1.0, digits=TEXT, bar=(1.0, "#F6FCFF"), word=("Ready", TEXT)),
    running=dict(edge=EDGE, cost=1.0, digits=TEXT, bar=("the share of the convert's time done", SEAM), word=("<time> left", TEXT)),
    short=dict(edge=FAINT, cost=0.55, digits=FAINT, bar=("the bag's count over the take", FAINT), word=("<n> of <take> <From>", SOFT)),
    asleep=dict(edge=FAINT, cost=0.55, digits=FAINT, bar=None, word=None),
)
PLATE = dict(width=204.0, line=20.0, pad=8.0, text=14.0)      # BaseController: CONDENSER_WIDTH, PLATE_LINE, Theme's


def card_final(state):
    """B's card as the build draws it: the cost in the stones' pictures, then how it stands; asleep, the cost alone."""
    k = CARD
    awake, done, have = state["awake"], state["done"], state["have"]
    name = "asleep" if not awake else "running" if done is not None else "ready" if have >= 5 else "short"
    st = CARD_STATES[name]
    (w, h), o = (k["asleep"] if name == "asleep" else k["size"]), 4.0

    def draw(t):
        d = t.poly(ui.cut_box(o, o, o + w, o + h, *k["corners"]))
        t.glow(d, 3.0, ui.BLACK, 0.3)
        t.paint(d, t.ramp(SLAB[0], SLAB[1], (t.y - o) / h), k["fillAlpha"])
        t.line(d, k["edgeWidth"], c(st["edge"]), 0.95 * (1.0 if st["cost"] == 1.0 else 0.55))
        for part, grade, digit in ((k["take"], "Low", "5"), (k["give"], "Mid", "1")):
            t.text(o + part["digit"][0], o + part["digit"][1], k["digits"], digit, st["digits"])
            stone(t, grade, o + part["stone"][0], o + part["stone"][1], part["stone"][2], st["cost"])
        a = k["arrow"]
        t.paint(t.poly([(o + a["left"], o + a["middle"] - a["size"][1] / 2), (o + a["left"] + a["size"][0], o + a["middle"]),
                        (o + a["left"], o + a["middle"] + a["size"][1] / 2)]), c(EDGE), st["cost"])
        if st["bar"] is None:
            return
        share = 1.0 if name == "ready" else done if name == "running" else have / 5
        bx, by, bw, bh = k["bar"]["box"]
        gauge(t, o + bx, o + by, bw, bh, share, st["bar"][1])
        word = "Ready" if name == "ready" else minutes(done) if name == "running" else f"{have} of 5 Low"
        t.text(o + k["line"][0], o + k["line"][1], k["word"], word, st["word"][1])
    return card(w + 2 * o, h + 2 * o, draw)


def plate_final(state):
    """The Comb's plate as BaseController draws it: its name, then its tray or the level that wakes it."""
    k = PLATE
    lines = [("Stone Condenser", TEXT), ("Tray 2 of 12 Low", TEXT) if state["awake"] else ("Wakes at base level 2", SOFT)]
    w, h = k["width"], len(lines) * k["line"] + k["pad"]

    def draw(t):
        slab(t, 4, 4, w + 4, h + 4, cut=6.0)
        for i, (text, colour) in enumerate(lines):
            t.text(4 + w / 2, 4 + k["pad"] / 2 + 5 + i * k["line"], k["text"], text, colour, "CENTER")
    return card(w + 8, h + 8, draw)


def spec(out):
    k = CARD
    data = dict(
        piece="AR51, B: the Stone Condenser's convert card (docs/asset-requests.md, AR51, 'The finish')",
        units="points at Theme.Author (812 by 375), from the card's top-left corner; a text's y is its cap's top",
        note="A screen card at fixed points beside the cradle, the machines' plates' kin (World.Plate): the cost in the "
             "stones' pictures, then how the convert stands. Its numbers and stones come from Config.Condenser.Convert "
             "(Take, From, Give, To), never from this file's example. Shown as the Comb's plate is shown. Asleep, the "
             "card keeps the cost line dimmed at the shorter size and has no second line: the plate alone says what "
             "wakes it (research's must-fix 1). DESIGN: drawn in Blender, untried in Studio.",
        card=dict(size=list(k["size"]), sizeAsleep=list(k["asleep"]),
                  corners=dict(cut=list(k["corners"]), order="top-left, top-right, bottom-right, bottom-left"),
                  fill=dict(top=SLAB[0], bottom=SLAB[1], alpha=k["fillAlpha"], home="Config.UIKit, System: Panel"),
                  edge=dict(width=k["edgeWidth"], alpha=0.95), shadow=dict(reach=3.0, colour="#000000", alpha=0.3)),
        place=dict(anchor="the cradle's top (the Condenser's convert prompt's part)",
                   leftAndTop=list(k["place"]),
                   note="the card's left edge 22 right of the anchor's point on the screen and its top 50 above it, so it "
                        "stands beside the cradle and clear of the Comb's tray; the plates' own rules (under the top "
                        "band, apart from other plates, off the avatar) are the build's"),
        cost=dict(
            take=dict(digit=dict(leftAndCapTop=list(k["take"]["digit"]), size=k["digits"], text="Convert.Take"),
                      stone=dict(leftTopSize=list(k["take"]["stone"]), image="StoneLow (Config.UIKit; the stone Convert.From names)")),
            arrow=dict(left=k["arrow"]["left"], middle=k["arrow"]["middle"], size=list(k["arrow"]["size"]),
                       colour=EDGE, image="ArrowRight (images/ArrowRight.png, new: white, tinted; its box is this "
                                           "size, its tile 2 more on every side)"),
            give=dict(digit=dict(leftAndCapTop=list(k["give"]["digit"]), size=k["digits"], text="Convert.Give"),
                      stone=dict(leftTopSize=list(k["give"]["stone"]), image="StoneMid (Config.UIKit; the stone Convert.To names)"))),
        second=dict(bar=dict(leftTopWidthHeight=list(k["bar"]["box"]), bed=k["bar"]["bed"], inset=k["bar"]["inset"],
                             corners="cut 4 at the top-left and bottom-right; plain frames serve at this size"),
                    word=dict(leftAndCapTop=list(k["line"]), size=k["word"])),
        states={name: dict(edge=st["edge"], costAlpha=st["cost"], digits=st["digits"],
                           **({"bar": dict(share=st["bar"][0], colour=st["bar"][1]),
                               "word": dict(text=st["word"][0], colour=st["word"][1])} if st["bar"] else
                              {"size": "sizeAsleep", "bar": None, "word": None}))
                for name, st in CARD_STATES.items()},
        when=dict(ready="awake, none running, the bag holds the take", running="a convert runs",
                  short="awake, none running, the bag holds less than the take", asleep="below Config.Condenser.Wakes"),
        colours=dict(text=TEXT, soft=SOFT, faint=FAINT, edge=EDGE, seam=SEAM, home="Config.UIKit, System; seam is the stones' own (AR31)"),
        text=dict(digits="Theme.Text.Title (20), the number face", word="Theme.Text.Caption (14)"))
    (out / "condenser_card.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print("AR51: wrote", out / "condenser_card.json")


def finish(out):
    """B alone, as picked and fixed: the four states at the stand, the reach's edge, the cuts, the cards whole."""
    flats = {name: (plate_final(s), card_final(s)) for name, _, s in STATES}
    made, boxes = {}, {}
    for asleep in (False, True):
        yard = Yard(out, False, asleep)
        for k in range(len(STAND)):
            cx, cy = yard.seen(k, (CRADLE[0], CRADLE[1], 2.9))
            boxes[k] = (round(cx), round(cy))
        for name, _, s in STATES:
            if s["awake"] == asleep:
                continue
            yard.stand(f"BStones_{name}")
            for k in range(len(STAND)):
                if k == 1 and name != "ready":
                    continue
                px = yard.shot(k, f"card_{name}_{k}")
                px_, py_ = yard.seen(k, (0.0, -0.4, 11.3))
                lay(px, flats[name][0], px_, py_ - 30)
                tx, ty = yard.seen(k, (CRADLE[0], CRADLE[1], 2.2))
                lay(px, flats[name][1], tx + CARD["place"][0] + CARD["size"][0] / 2, ty + CARD["place"][1] - 4)
                made[name, k] = px
            yard.clear()
    ui.K = 1
    m, gap = 20, 14
    whole = max(f[1].shape[0] for f in flats.values())
    sheet = ui.Sheet(2 * m + 2 * SIZE[0] + gap, 70 + 2 * (SIZE[1] + 22) + 22 + 2 * 342 + 22 + SIZE[1] + 22 + 2 * (whole + 12) + 40, GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(m, 16, 19, "Grow your Anime, AR51's finish: the Stone Condenser's convert card (B), at the game's sizes", HEAD)
    t.text(m, 44, 11, "The game's camera behind a player 6.7 studs from the cradle, by day, at 852 by 480, a point drawn as a pixel. "
                      "The plate and the card are stand-ins in Blender's face, at the build's sizes (text 14 and 20).", NOTE)
    for i, (name, label, _) in enumerate(STATES):
        x, y = m + (i % 2) * (SIZE[0] + gap), 70 + (i // 2) * (SIZE[1] + 22)
        t.text(x, y, 11, label, NOTE)
        rs.paste(sheet.px, made[name, 0], x, y + 16)
    y = 70 + 2 * (SIZE[1] + 22)
    t.text(m, y, 11, "The card cut from each frame and drawn 3 times its size, pixel for pixel: ready, running, can't start, asleep", NOTE)
    for i, (name, _, _) in enumerate(STATES):
        rs.paste(sheet.px, cut(made[name, 0], boxes[0], right=80), m + (i % 2) * (SIZE[0] + gap), y + 16 + (i // 2) * 342)
    y += 16 + 2 * 342
    t.text(m, y, 11, "Ready, from the edge of the prompt's reach, 9.9 studs off; and its card 3 times its size", NOTE)
    rs.paste(sheet.px, made["ready", 1], m, y + 16)
    rs.paste(sheet.px, cut(made["ready", 1], boxes[1], right=80), m + SIZE[0] + gap, y + 16)
    y += 16 + SIZE[1] + 8
    t.text(m, y, 11, "The four cards whole, at 4 pixels a point, as condenser_card.json measures them", NOTE)
    for i, (name, _, _) in enumerate(STATES):
        rs.paste(sheet.px, flats[name][1], m + (i % 2) * (SIZE[0] + gap), y + 16 + (i // 2) * (whole + 12))
    uk.finish(sheet, out / "condenser_card.png")
    spec(out)


FACE_PTS = (112.0, 80.0)      # A's face: a SurfaceGui 2.8 by 2.0 studs at 40 pixels a stud


def face(state):
    """A's face on the slate: read at about half this size on the smallest phone, so two pictures, a bar, one word."""
    w, h = FACE_PTS
    awake, done, have = state["awake"], state["done"], state["have"]
    lit = awake and (done is not None or have >= 5)
    dim = 1.0 if lit else 0.5

    def draw(t):
        t.paint(t.poly(ui.cut_box(0, 0, w, h)), c(BED))
        t.text(6, 14, 26, "5", TEXT if lit else FAINT)
        stone(t, "Low", 20, 0, 42, dim)
        arrow(t, 62, 22, 14, EDGE, dim)
        stone(t, "Mid", 70, 0, 42, dim)
        if not awake:
            t.text(w / 2, 52, 19, "LEVEL 2", FAINT, "CENTER")
        elif done is not None:
            gauge(t, 8, 44, w - 16, 9, done)
            t.text(w / 2, 58, 19, f"{round(30 * (1 - done))} MIN", TEXT, "CENTER")
        elif have >= 5:
            gauge(t, 8, 44, w - 16, 9, 1.0, "#F6FCFF")
            t.text(w / 2, 58, 19, "READY", TEXT, "CENTER")
        else:
            gauge(t, 8, 44, w - 16, 9, have / 5, FAINT)
            t.text(w / 2, 58, 19, f"{have} OF 5", SOFT, "CENTER")
    return card(w, h, draw)


def plate_lines(key, state):
    """The Comb's own plate: the tray's line as the build says it; under C, the convert's line too."""
    if not state["awake"]:
        return [("Wakes at base level 2", SOFT)]
    lines = [("Tray 2 of 12 Low", TEXT)]
    if key == "C":
        done, have = state["done"], state["have"]
        lines.append((f"Convert: {minutes(done)}", TEXT) if done is not None
                     else ("Convert: ready", TEXT) if have >= 5 else (f"Convert: {have} of 5 Low", SOFT))
    return lines


# --- the pieces, in the Condenser's own frame (front toward +Y, the gate) -----------------------------------------------

def lean(x, y, z):
    return at(x, y, z) @ Matrix.Rotation(math.radians(TILT), 4, "X")


def comb(fill):
    def make():
        m = bf.condenser()
        put(m, bf.condenser_core(), at(*bf.CORE))
        for x, z in bf.cups()[:fill]:
            put(m, bf.condenser_stone(), at(x, bf.FACE, z))
        return Piece(f"Comb{fill}", m)
    return make


def a_slate():
    m = Mesh()
    x, y = CRADLE
    m.box((0.6, 0.6, 1.4), (x, y - 0.5, 1.7), "girder", ink=True)
    put(m, turned([(2.0, 0.4), (2.0, 0.0)], 6, "abyss"), lean(x, y - 0.3, 3.1) @ at(0, -0.3, 0) @ FACING)
    return Piece("ASlate", m)


def b_stones(name, state):
    def make():
        m = Mesh()
        x, y = CRADLE
        if not state["awake"]:
            m.box((0.1, 0.1, 0.1), (x, y, 0.6), "abyss")
        elif state["done"] is not None:
            bf.bm.shard(m, (x, y, 1.75), 0.3, 0.95, "void")          # the one being made, stood on the tray
        else:
            for k in range(min(state["have"], 5)):
                bf.stone(m, (x - 0.52 + 0.26 * k, y, 1.35), 0.16)
        return Piece(f"BStones_{name}", m)
    return make


BIG = (0.0, 0.55, 1.7)        # C's large cup: across and up on the slate, and its size against a comb's cup
SMALL = [(1.75 * math.cos(math.radians(a)), 0.55 + 1.75 * math.sin(math.radians(a))) for a in (200, 235, 270, 305, 340)]


def c_slate(name, state):
    """Five cups round one: a stone stands in a small cup for each the bag holds of the five; while a convert runs
    they're empty, the large cup holds the stone being made and the six lengths round it light with the time done
    (five minutes a length, from the top, clockwise)."""
    def make():
        awake, done, have = state["awake"], state["done"], state["have"]
        sub = Mesh()
        put(sub, turned([(2.3, 0.5), (2.3, 0.0)], 6, "abyss"), at(0, bf.FACE - 0.5, 0) @ FACING)
        for k, (x, z) in enumerate(SMALL):
            bf.cup(sub, x, z)
            if awake and done is None and k < have:
                put(sub, bf.condenser_stone(), at(x, bf.FACE, z))
        bx, bz, big = BIG
        cup = Mesh()
        bf.cup(cup, 0.0, 0.0)
        grow = Matrix.Scale(big, 4)
        put(sub, cup, at(bx, bf.FACE * (1 - big), bz) @ grow)
        if awake and done is not None:
            put(sub, bf.condenser_stone(), at(bx, bf.FACE * (1 - big), bz) @ grow @ at(0, bf.FACE, 0))
        lit = round(6 * done) if awake and done is not None else 0
        for k in range(6):
            a = math.radians(90 - 60 * k - 30)                       # from the top, clockwise as the player sees it
            r = 0.5 * big * math.cos(math.radians(30)) + 0.3
            sub.box((0.78, 0.05, 0.24), (bx - r * math.cos(a), bf.FACE + 0.03, bz + r * math.sin(a)),
                    "void" if k < lit else "ink", rot=Matrix.Rotation(math.pi / 2 - a, 3, "Y"))
        m = Mesh()
        x, y = CRADLE
        m.box((0.6, 0.6, 1.4), (x, y - 0.6, 1.7), "girder", ink=True)
        put(m, sub, lean(x, y - 0.3, 3.3))
        return Piece(f"CSlate_{name}", m)
    return make


# --- the yard and the shots ----------------------------------------------------------------------------------------------

def with_comb(whole, fill, asleep):
    """The plan's machines with the Comb stood on the Condenser's sleeping place; the stone under it shows while it sleeps."""
    def machines(at_level=1):
        made = whole(at_level)
        if at_level != LEVEL:
            return made
        made = [row for row in made if asleep or not (row[0] == "SleepingStone" and (row[1], row[2]) == HOME)]
        return made + [(f"Comb{fill}", *HOME, 0.0, 0.0, "")]
    return machines


class Yard:
    def __init__(self, out, fast, asleep):
        base.BAYS_AT.update(lv.BAYS_AT)
        base.PIECES.update(lv.PIECES)
        base.PIECES.update({"Comb0": comb(0), f"Comb{TRAY}": comb(TRAY), "ASlate": a_slate})
        for name, _, s in STATES:
            base.PIECES.update({f"BStones_{name}": b_stones(name, s), f"CSlate_{name}": c_slate(name, s)})
        look.SIZE = SIZE
        self.d = d = day.light("day")
        look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                        away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
        self.scene = scene = bl.reset_scene()
        base.write_pictures(out / "maps")
        self.yard = yard = plan.Yard(scene, LEVEL, out / "maps")
        whole = plan.machines
        plan.machines = with_comb(lv.staged(LEVEL), 0 if asleep else TRAY, asleep)
        yard.plot(0.0, 1)
        plan.machines = whole
        for i, row in enumerate(lv.grown("F", LEVEL)):
            obj = yard.stock.stand(row[0], f"G{i}", yard.at(0.0, 1, row[1], row[2], row[3]), row[4] if len(row) > 4 else 0.0)
            if len(row) > 5 and row[5] is not None:
                obj.rotation_euler = row[5].to_euler()
        yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
        yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
        for obj in yard.kit.pieces:
            if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings") + base.levels.FLAT):
                obj.visible_shadow = False
        self.views = []
        for k, (dx, dy) in enumerate(STAND):
            where = (HOME[0] + dx, -HOME[1] + dy)
            yard.person(where, f"Stand{k}")
            eye, target = lv.behind(where, (HOME[0], -HOME[1]))
            self.views.append(plan.camera(scene, f"Cam{k}", eye, target))
        look.sky(scene, d)
        look.sun(scene, d)
        r = scene.render
        for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
            try:
                r.engine = engine
                break
            except TypeError:
                continue
        r.resolution_x, r.resolution_y, r.resolution_percentage = *SIZE, 100
        scene.view_settings.view_transform = "Standard"
        scene.eevee.taa_render_samples = 8 if fast else 32
        for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
            try:
                setattr(scene.eevee, attr, val)
            except AttributeError:
                pass
        self.out, self.made = out, []

    def here(self, x, y, z):
        """A point of the Condenser's frame, in the scene's."""
        return Vector((HOME[0] + x, -HOME[1] + y, z))

    def stand(self, name):
        obj = self.yard.stock.stand(name, f"P{len(self.made)}{name}", self.yard.at(0.0, 1, *HOME, 0.0), 0.0)
        self.made.append(obj)
        return obj

    def face_plane(self, picture, name):
        """A's SurfaceGui: the picture unlit on the slate's face, its left at the player's left."""
        path = self.out / f"_face_{name}.png"
        rs.save(picture, path)
        w, h = FACE_PTS[0] / 40.0, FACE_PTS[1] / 40.0
        M = Matrix.Translation(self.here(0, 0, 0)) @ lean(CRADLE[0], CRADLE[1] - 0.3, 3.1)
        corners = [M @ Vector((sx * w / 2, 0.13, sz * h / 2)) for sx, sz in ((1, -1), (-1, -1), (-1, 1), (1, 1))]
        mesh = bpy.data.meshes.new(f"Face{name}")
        mesh.from_pydata(corners, [], [(0, 1, 2, 3)])
        uv = mesh.uv_layers.new(name="UV")
        for loop, st in zip(mesh.polygons[0].loop_indices, ((0, 0), (1, 0), (1, 1), (0, 1))):
            uv.data[loop].uv = st
        mat = bpy.data.materials.new(f"Face{name}")
        mat.use_nodes = True
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        nodes.clear()
        tex, glow, end = nodes.new("ShaderNodeTexImage"), nodes.new("ShaderNodeEmission"), nodes.new("ShaderNodeOutputMaterial")
        tex.image = bpy.data.images.load(str(path))
        links.new(tex.outputs["Color"], glow.inputs["Color"])
        links.new(glow.outputs["Emission"], end.inputs["Surface"])
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(f"Face{name}", mesh)
        self.scene.collection.objects.link(obj)
        self.made.append(obj)
        return obj

    def clear(self):
        for obj in self.made:
            if obj in self.yard.kit.pieces:
                self.yard.kit.pieces.remove(obj)
            bpy.data.objects.remove(obj, do_unlink=True)
        self.made = []

    def seen(self, k, point):
        """A point of the Condenser's frame in view k's pixels."""
        bpy.context.view_layer.update()
        p = world_to_camera_view(self.scene, self.views[k], self.here(*point))
        return p.x * SIZE[0], (1 - p.y) * SIZE[1]

    def shot(self, k, name):
        self.scene.camera = self.views[k]
        for obj in bpy.data.objects:
            if obj.name.startswith("Stand"):
                obj.hide_render = not obj.name.startswith(f"Stand{k}")
        path = self.out / f"_{name}.exr"
        px = look.finish(look.render_linear(self.scene, path), self.d)
        path.unlink(missing_ok=True)
        return np.ascontiguousarray(px[..., :4] if px.shape[2] >= 4 else np.dstack([px, np.ones(px.shape[:2], np.float32)]))


def lay(frame, picture, cx, top):
    """A card on a frame at the phone's pixels, its middle at cx and its top at `top`."""
    small = rs.shrink(picture, 1 / 4)
    x = min(max(round(cx - small.shape[1] / 2), 0), SIZE[0] - small.shape[1])
    rs.paste(frame, small, x, max(round(top), 30))


def frames(out, fast):
    """Every frame: direction, state, view; and where the panel sits in each view, for the cuts."""
    flats = {}
    for key in "ABC":
        for name, _, s in STATES:
            flats[key, name] = (plate(plate_lines(key, s)), tag(s) if key == "B" else None, face(s) if key == "A" else None)
    made, boxes = {}, {}
    for asleep in (False, True):
        yard = Yard(out, fast, asleep)
        for k in range(len(STAND)):
            cx, cy = yard.seen(k, (CRADLE[0], CRADLE[1], 2.9))
            boxes[k] = (round(cx), round(cy))
        for key in "ABC":
            for name, _, s in STATES:
                if s["awake"] == asleep:
                    continue
                if key == "A":
                    yard.stand("ASlate")
                    yard.face_plane(flats[key, name][2], name)
                else:
                    yard.stand(f"BStones_{name}" if key == "B" else f"CSlate_{name}")
                for k in range(len(STAND)):
                    if k == 1 and name != "ready":
                        continue
                    px = yard.shot(k, f"{key}_{name}_{k}")
                    px_, py_ = yard.seen(k, (0.0, -0.4, 11.3))
                    lay(px, flats[key, name][0], px_, py_ - 20)
                    if key == "B":
                        tx, ty = yard.seen(k, (CRADLE[0], CRADLE[1], 2.2))
                        lay(px, flats[key, name][1], tx + 96, ty - 44)        # beside the cradle, off the Comb's tray
                    made[key, name, k] = px
                    rs.save(px, out / f"panel_{key}_{name}_{k}.png")
                yard.clear()
        print("AR51: the yard", "asleep" if asleep else "awake", "done")
    return made, boxes


def cut(px, centre, w=270, h=110, k=3, right=0):
    x = min(max(centre[0] - w // 2 + right, 0), SIZE[0] - w)
    y = min(max(centre[1] - h // 2 - 12, 0), SIZE[1] - h)
    return np.repeat(np.repeat(px[y:y + h, x:x + w], k, axis=0), k, axis=1)


RIGHT = {"A": 0, "B": 70, "C": 0}       # B's cut moved right, to hold its card

NAMES = {"A": "A. The Slate: a six-sided slate on the cradle, its face the stones' pictures, a bar and one word",
         "B": "B. The Tag: the stones lie on the cradle; the words on a card over it, the machines' plates' kin",
         "C": "C. The Sixth Cup: five cups round one, lit by the state; the words a second line on the Comb's plate"}


def sheets(out, made, boxes):
    ui.K = 1
    m, gap = 20, 14
    for key in "ABC":
        sheet = ui.Sheet(2 * m + 2 * SIZE[0] + gap, 70 + 2 * (SIZE[1] + 22) + 22 + 2 * 342 + 22 + SIZE[1] + 60, GROUND)
        t = sheet.tile(0, 0, sheet.w, sheet.h)
        t.text(m, 16, 19, "Grow your Anime, AR51: the Stone Condenser's convert panel. " + NAMES[key], HEAD)
        t.text(m, 44, 11, "The game's camera behind a player standing at the Comb, 6 studs from the cradle, by day, at "
                          "the smallest phone's 852 by 480. The Comb's plate and the cards are stand-ins in Blender's face.", NOTE)
        for i, (name, label, _) in enumerate(STATES):
            x, y = m + (i % 2) * (SIZE[0] + gap), 70 + (i // 2) * (SIZE[1] + 22)
            t.text(x, y, 11, label, NOTE)
            rs.paste(sheet.px, made[key, name, 0], x, y + 16)
        y = 70 + 2 * (SIZE[1] + 22)
        t.text(m, y, 11, "The panel cut from each frame and drawn 3 times its size, pixel for pixel: ready, running, can't start, asleep", NOTE)
        for i, (name, _, _) in enumerate(STATES):
            rs.paste(sheet.px, cut(made[key, name, 0], boxes[0], right=RIGHT[key]), m + (i % 2) * (SIZE[0] + gap), y + 16 + (i // 2) * 342)
        y += 16 + 2 * 342
        t.text(m, y, 11, "Ready, from the edge of the prompt's reach, 10 studs off; and its panel 3 times its size", NOTE)
        rs.paste(sheet.px, made[key, "ready", 1], m, y + 16)
        rs.paste(sheet.px, cut(made[key, "ready", 1], boxes[1], right=RIGHT[key]), m + SIZE[0] + gap, y + 16)
        uk.finish(sheet, out / f"condenser_panel_{key}.png")
    sheet = ui.Sheet(2 * m + 4 * 492, 60 + 3 * (220 + 34), GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(m, 16, 19, "AR51 at a glance: each direction's panel as the smallest phone shows it, twice its size: ready, running, can't start, asleep", HEAD)
    for r, key in enumerate("ABC"):
        y = 50 + r * (220 + 34)
        t.text(m, y, 11, NAMES[key], NOTE)
        for i, (name, _, _) in enumerate(STATES):
            rs.paste(sheet.px, cut(made[key, name, 0], boxes[0], w=240, k=2, right=RIGHT[key]), m + i * 492, y + 16)
    uk.finish(sheet, out / "condenser_panel_glance.png")


def main():
    out = bl.out_dir()
    if "finish" in sys.argv:
        finish(out)
        return
    fast = "fast" in sys.argv
    made, boxes = frames(out, fast)
    sheets(out, made, boxes)
    for path in list(out.glob("_face_*.png")):
        path.unlink()
    print("AR51: the panel's sheets written to", out)


if __name__ == "__main__":
    main()
