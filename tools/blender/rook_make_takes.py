"""Rook, redone in the make (AR59's redo, research, 2026-11-23): three takes drawn with anime_make.py's kit, each a
side-cast type of the genre made our own, inside a Common's limit: three or four elements, a plain palette, red the
one accent. Nothing is built on the body: his fists are cloth wraps drawn on the arms.

    A, the school tough: black hair combed back to points behind the crown, one stray lock, narrow grey eyes, a low
       brow and a flat mouth, a white plaster over the nose; a long black school jacket worn open over a red T-shirt,
       its tails down over the legs, the right sleeve rolled to the elbow; white wraps, white trainers.
    B, the dojo trainee: cropped chestnut hair lying forward, big amber eyes, a wide grin, a nick through one brow; an
       off-white training top with a crossed collar and short rolled sleeves, a red sash with its two ends hanging,
       loose navy trousers gathered at the ankle; red wraps, the right arm's to the elbow.
    C, the gym kid: messy dark brown hair with a heavy fringe to the brows, half-shut green eyes, a small smirk, a
       plaster on the cheek; a red zip track jacket with one white stripe down each sleeve and a flat hood on its
       back, the right sleeve pushed up, black joggers with a white side stripe; white wraps, red and white trainers.

Each is drawn as the player meets it: square on beside Anime Vanguards units at the same height (the reference's
pictures stay in build/reference, internal); three-quarter front and the game's camera in the game's day light; the
head from six sides; the bust in the lead card's pose; and in a fight on the deck from the player's camera at the
smallest phone's size, beside today's Rook and a Shade. The deck is a stand-in (its pale plates and a day sky): no
capture of a fight there has a solved camera, so the camera, the sun and the fill are hard_ember.py's, the game's own.

    blender.exe -b --factory-startup --python tools/blender/rook_make_takes.py -- <out_dir> takes [A B C]
    blender.exe -b --factory-startup --python tools/blender/rook_make_takes.py -- <out_dir> rook|shade|sheet
    blender.exe -b --factory-startup --python tools/blender/rook_make_takes.py -- <out_dir> proof [A]

`takes`, `rook` and `shade` each draw their own pictures into <out_dir>/tex, <out_dir>/shots and <out_dir>/layers
(Eevee, no GPU turn); `sheet` lays them into rook_takes.png and its parts, and the takes beside the reference's units
into rook_beside.png, which holds the reference's pictures and so is kept with them in build/reference, never in git.
`proof` lays the picked take alone into rook_pick.png, as its finish is judged, and rook_pick_beside.png the same way:
the three-take sheet no longer fits in memory beside the Studios.
"""
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402
from anime_make import INK, mix, rgb, tone  # noqa: E402

RED, CLOTH = "#C5303A", "#EAE4D6"   # his one accent, and the wraps' white
REPO = Path(__file__).resolve().parents[2]
BESIDE = ("gaari-1329f7fc3818e125.webp", "kinnua-e8de7d4129ad5529.webp")   # the reference's units the takes stand beside
BESIDE_PX = 159.5                                  # their pixels a stud, measured feet to shoulders
VIEWS = {"front": (146, 8), "game": rs.GAME}
SHOT, SPAN, MID = 820, 7.9, (0.0, 0.0, 3.1)        # a full figure: pixels square, studs across, the crop's middle
SQUARE = (380, 700, 7.95, 2.95)                    # square on, arms down, as the reference shows a unit: pixels, studs up the picture, the middle's height
BUST = dict(side=1, body=34, turn=22, tilt=-3, nod=5, elevation=3, centre=(-0.1, 0, 4.72), span=2.9)  # hud_art's Rook, wider
BUST_PX = (624, 752)
CARD = 0.853 * 1.12 / 8.0             # the bust's render to the lead card's portrait on the smallest phone
LEAD, FOE = (-2.5, -7.0), (2.2, -11.5)            # a fight: the lead a few studs in front of the avatar, and its foe
ROW_Z, ROW_X = -6.0, (-9.0, -4.5, 0.0, 4.5, 9.0)  # a line-up at the lead's distance, turned to the player
WHO = ("Rook", "A", "B", "C")
TALL = 7.2
SAID = {
    "Rook": ("Today's Rook", ("the model in the game now: built clothes,", "a cube head, the oversized gauntlet")),
    "A": ("A, the school tough", ("black hair combed back to points, one stray lock", "narrow grey eyes, a low brow, a small plaster on the nose",
                                  "a blue-grey school jacket open over a red T-shirt", "wrapped fists, the right sleeve rolled to the elbow")),
    "B": ("B, the dojo trainee", ("cropped chestnut hair, big amber eyes, a wide grin", "an off-white training top, short sleeves rolled",
                                  "a red sash with its ends hanging, navy trousers", "red wraps, the right arm's to the elbow")),
    "C": ("C, the gym kid", ("messy brown hair, a heavy fringe to the brows", "half-shut green eyes, a smirk, a plaster on the cheek",
                             "a red zip track jacket, one white stripe a sleeve", "white wraps, black joggers, red trainers")),
}


# --- drawing on the blocks ---------------------------------------------------------------------------------------------

def line(p, pts, wide=0.022, colour=INK, alpha=0.9):
    p.lay(p.stroke(pts, (wide * 0.5, wide, wide, wide * 0.5)), colour, alpha)


def band(w, y0, y1, colour, edge=None, wide=0.011):
    """A band right round a block, with a drawn line on its two edges."""
    w.lay(w.rect(-9, y0, 9, y1), colour)
    if edge is not None:
        for y in (y0, y1):
            w.lay(w.rect(-9, y - wide, 9, y + wide), edge)


dark, light, shadow, creases, lit, grain = am.dark, am.light, am.shadow, am.creases, am.lit, am.grain   # the kit's cloth


def wraps(block, y0, y1, colour, gap=0.15):
    """Cloth wound round an arm from y0 to y1: its turns as one slanted line right round, an edge line at each end."""
    w = block.wrap
    area = w.rect(-9, y0, 9, y1)
    w.lay(area, colour)
    lean = gap / w.w
    y = y0 - gap
    while y < y1:
        turn = w.stroke([(w.x0, y), (w.x0 + w.w, y + lean * w.w)], (0.02, 0.02), n=4)
        w.lay(np.minimum(turn, area), tone(colour, 0.55), 0.9)
        y += gap
    for y in (y0, y1):
        if y > 0.01:
            w.lay(w.rect(-9, y - 0.012, 9, y + 0.012), tone(colour, 0.4))


def fist(block, colour):
    """The fingers' lines on a wrapped hand, and the knuckles' band."""
    for p in block.sides:
        for x in (-0.25, 0.0, 0.25):
            line(p, [(x, 0.2), (x, 0.03)], 0.014, tone(colour, 0.45), 0.7)
    block.faces["bottom"].px[:] = tone(colour, 0.9)


def wrapped_fist(block, colour, wrist=0.62, hand=0.4):
    """A fist that reads as one from behind: the hand wrapped over its end, the knuckles' turn and the fingers'
    lines on every side, a firm line and a shade at the wrist, and the wrist's own turns above it."""
    w = block.wrap
    wraps(block, hand, wrist, colour, gap=0.11)
    w.lay(w.rect(-9, 0.0, 9, hand), colour)
    for p in block.sides:
        for x in (-0.25, 0.0, 0.25):
            line(p, [(x, 0.21), (x, 0.02)], 0.018, tone(colour, 0.4), 0.85)
        dark(p, p.soft(p.rect(-9, hand - 0.1, 9, hand), 0.03), 0.3)
    w.lay(w.rect(-9, 0.215, 9, 0.24), tone(colour, 0.5), 0.8)
    w.lay(w.rect(-9, hand - 0.016, 9, hand + 0.016), tone(colour, 0.3))
    block.faces["bottom"].px[:] = tone(colour, 0.86)


def shoe(block, upper, sole, cap, tall=0.3):
    w, f = block.wrap, block.faces["front"]
    band(w, 0.0, tall, upper, tone(upper, 0.45))
    w.lay(w.rect(-9, 0.0, 9, 0.075), sole)
    f.lay(f.poly([(-0.5, 0.075), (0.5, 0.075), (0.5, 0.17), (0.3, 0.215), (-0.3, 0.215), (-0.5, 0.17)]), cap)
    for y in (0.245, 0.275):
        line(f, [(-0.14, y), (0.14, y)], 0.014, tone(cap, 0.7), 0.9)
    block.faces["bottom"].px[:] = rgb(sole)


def neck(block, skin):
    top = block.faces["top"]
    top.lay(top.ellipse(0, 0.5, 0.36, 0.36), skin)


def blocks_of(colours):
    return {key: am.Block(key, centre, size, colours[key]) for key, (centre, size) in am.BODY.items()}


def figure(joints, folder, blocks, head, hair):
    made = {}
    for key, block in blocks.items():
        made[key] = block.build(folder)
        wt.on(joints, am.JOINT[key], made[key])
    made["head"], made["hair"] = head.build(folder), hair.build(folder)
    wt.on(joints, "neck", made["head"], made["hair"])
    print(f"hair: {hair.locks} locks")
    return made


def strip(p, x, y, long_, tall, turn, colour, pad=None):
    """A plaster: a small strip with round ends, turned `turn` degrees, a square pad at its middle."""
    c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))
    box = lambda hw, hh: [(x + u * c - v * s, y + u * s + v * c) for u, v in ((-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh))]  # noqa: E731
    shape = np.maximum(p.poly(box(long_ / 2 - tall / 2, tall / 2)),
                       np.maximum(p.ellipse(x - (long_ / 2 - tall / 2) * c, y - (long_ / 2 - tall / 2) * s, tall / 2, tall / 2),
                                  p.ellipse(x + (long_ / 2 - tall / 2) * c, y + (long_ / 2 - tall / 2) * s, tall / 2, tall / 2)))
    dark(p, p.soft(shape, 0.012) * 1.6, 0.3)
    p.lay(shape, colour)
    if pad is not None:
        p.lay(p.poly(box(tall * 0.5, tall * 0.5)), pad)


# --- A, the school tough -----------------------------------------------------------------------------------------------

def take_a(joints, folder):
    skin, coat, tee, trouser = "#EFC3A2", "#3D4764", RED, "#202229"
    edge, trim = tone(coat, 0.45), mix(coat, "#A9B1CC", 0.45)
    hem, tail = 1.74, 1.5   # on the legs: where the jacket ends, and where the T-shirt under it does
    b = blocks_of({"torso": coat, "rs": coat, "ls": coat, "rh": trouser, "lh": trouser})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the T-shirt in the jacket's opening, hanging loose: its folds fall from the collar and gather at the waist
    f.lay(f.poly([(-0.3, 2.0), (0.3, 2.0), (0.46, 0.0), (-0.46, 0.0)]), tee)
    f.lay(f.ellipse(0.0, 2.02, 0.21, 0.17), skin)
    line(f, [(-0.21, 2.0), (-0.13, 1.89), (0.0, 1.85), (0.13, 1.89), (0.21, 2.0)], 0.03, tone(tee, 0.62))
    creases(f, [[(-0.1, 1.72), (-0.17, 1.46), (-0.13, 1.18)], [(0.15, 1.62), (0.22, 1.3), (0.17, 1.02)],
                [(-0.3, 0.64), (-0.06, 0.52), (0.2, 0.6)], [(0.34, 0.4), (0.1, 0.3), (-0.16, 0.36)]], 0.34)
    # the jacket's two front edges, their facing a tone lighter, and its buttons
    for s in (-1, 1):
        f.lay(f.poly([(s * 0.3, 2.0), (s * 0.4, 2.0), (s * 0.56, 0.0), (s * 0.46, 0.0)]), trim)
        line(f, [(s * 0.3, 2.0), (s * 0.46, 0.0)], 0.022, edge)
        line(f, [(s * 0.4, 2.0), (s * 0.56, 0.0)], 0.016, edge, 0.8)
        # pulled from the shoulder to the opening, from the arm's pit, and hanging at the waist
        creases(f, [[(s * 0.98, 1.84), (s * 0.82, 1.66), (s * 0.62, 1.56)], [(s * 1.0, 1.26), (s * 0.84, 1.16), (s * 0.7, 1.2)],
                    [(s * 0.98, 0.72), (s * 0.84, 0.52), (s * 0.74, 0.28)], [(s * 0.66, 0.34), (s * 0.64, 0.16), (s * 0.66, 0.0)]], 0.46)
    for y in (1.58, 1.2, 0.82, 0.44):
        x = 0.35 + (2.0 - y) * 0.08 + 0.1
        f.lay(f.ellipse(x, y, 0.045, 0.045), tone(coat, 0.5))
        f.lay(f.ellipse(x, y, 0.03, 0.03), mix(coat, "#8E93AB", 0.3))
    # a standing collar, open at the throat
    w.lay(w.rect(0.3, 1.86, 9, 2.0), trim)
    w.lay(w.rect(-9, 1.86, -0.3, 2.0), trim)
    w.lay(w.rect(0.3, 1.85, 9, 1.872), edge)
    w.lay(w.rect(-9, 1.85, -0.3, 1.872), edge)
    # the back, plain: its middle seam, its yoke, and the cloth pulled from each arm's pit down to the waist
    line(back, [(0.0, 1.62), (0.008, 0.9), (0.0, 0.0)], 0.016, edge, 0.7)
    line(back, [(-1.0, 1.6), (0.0, 1.64), (1.0, 1.6)], 0.014, edge, 0.6)
    creases(back, [[(-0.98, 1.24), (-0.74, 0.98), (-0.58, 0.6)], [(0.98, 1.24), (0.74, 0.98), (0.58, 0.6)],
                   [(-0.9, 0.5), (-0.7, 0.32), (-0.62, 0.08)], [(0.9, 0.5), (0.7, 0.32), (0.62, 0.08)],
                   [(-0.3, 0.44), (-0.05, 0.36), (0.24, 0.42)]], 0.46)
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=1)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        w = a.wrap
        if key == "rs":   # the sleeve rolled to the elbow, the forearm bare, the wrist and the fist wrapped
            w.lay(w.rect(-9, 0.0, 9, 1.0), skin)
            wrapped_fist(a, CLOTH)
            band(w, 1.0, 1.22, trim, edge)
            w.lay(w.rect(-9, 1.1, 9, 1.116), edge, 0.7)
            folds = [[(-0.42, 1.62), (-0.05, 1.5), (0.34, 1.58)], [(-0.3, 1.4), (0.08, 1.32), (0.42, 1.4)]]
        else:
            w.lay(w.rect(-9, 0.0, 9, 0.46), skin)
            wrapped_fist(a, CLOTH, wrist=0.46)
            band(w, 0.46, 0.6, trim, edge)
            folds = [[(-0.42, 1.5), (-0.05, 1.38), (0.34, 1.46)], [(-0.3, 1.1), (0.08, 1.0), (0.42, 1.08)],
                     [(-0.4, 0.84), (0.0, 0.76), (0.3, 0.8)]]
        for p in a.sides:
            creases(p, folds, 0.46)
        shadow(a, 0.3, low=0.0)
        lit(a)
        grain(a, seed=2 + i)
        a.faces["top"].px[:] = rgb(tone(coat, 1.2))
        if key == "rs":   # what Haymaker heats: the right fist's wraps, hottest over the knuckles and the fist's end
            a.light_up(np.clip((0.44 - w.Y) / 0.2, 0, 1) * 0.6, end=0.6)

    for i, (key, s) in enumerate((("rh", -1), ("lh", 1))):   # s: the outer side on the leg's front picture
        g = b[key]
        w, f = g.wrap, g.faces["front"]
        for p in g.sides:
            creases(p, [[(-0.4, 1.2), (-0.05, 1.08), (0.36, 1.16)], [(-0.3, 0.66), (0.0, 0.52), (0.34, 0.56)]], 0.45)
        line(f, [(0.0, tail), (0.012, 1.0), (0.0, 0.34)], 0.014, tone(trouser, 0.5), 0.5)
        # the T-shirt's hem below the jacket's, right round: his red from every side
        w.lay(w.rect(-9, tail, 9, 2.0), tee)
        w.lay(w.rect(-9, tail - 0.012, 9, tail + 0.012), tone(tee, 0.5))
        for p in g.sides:
            creases(p, [[(-0.4, 1.66), (-0.1, 1.59), (0.3, 1.63)]], 0.3, 0.022)
        # the jacket over it to its own hem, open at the front
        w.lay(w.rect(-9, hem, 9, 2.0), coat)
        w.lay(w.rect(-9, hem - 0.012, 9, hem + 0.012), edge)
        f.lay(f.poly([(s * 0.04, 2.0), (-s * 0.5, 2.0), (-s * 0.5, hem - 0.014), (s * 0.07, hem - 0.014)]), tee)
        f.lay(f.poly([(s * 0.04, 2.0), (s * 0.14, 2.0), (s * 0.17, hem), (s * 0.07, hem)]), trim)
        line(f, [(s * 0.04, 2.0), (s * 0.07, hem)], 0.02, edge)
        line(f, [(s * 0.14, 2.0), (s * 0.17, hem)], 0.016, edge, 0.8)
        shoe(g, "#E9E6DF", "#C9C5BC", "#F7F5F0")
        band(w, 0.3, 0.36, tone(trouser, 0.8), tone(trouser, 0.45))
        shadow(g, 0.3, low=0.0)
        grain(g, seed=4 + i)

    head = am.Head(skin)
    am.draw_face(head.paint, dict(skin=skin, iris="#8B95A8", eye_w=0.3, eye_h=0.13, eye_x=0.265, eye_y=0.53, tilt=0.034,
                                  shut=0.3, brow_y=0.645, brow_tilt=0.045, brow="#15151B",
                                  mouth=[(-0.07, 0.222), (0.0, 0.232), (0.075, 0.22)]))
    strip(head.paint, 0.0, 0.478, 0.15, 0.056, 8, "#F4F1EA", "#DDD8CC")   # small, on the bridge: it never bars the face
    hair = am.Hair("#07070B", "#23263A", seed=3, band=(0.5, 0.14, 0.6))
    hair.shell(am.hairline(front=5.0, temple=4.6, nape=4.2))
    # the back first, down to a short nape; then the sides, swept back past the ears; then the top, combed back from
    # the forehead over the crown, its points standing clear behind it
    hair.row(6, 94, (110, 250), 0.34, 0.32, off=0.03, flick=12, hold=0.5, jitter=0.2)
    hair.row(8, 68, (100, 260), 0.6, 0.4, heading=6, off=0.06, flick=24, hold=0.45)
    hair.row(7, 40, (108, 252), 0.74, 0.44, heading=8, off=0.1, flick=32, hold=0.4)
    hair.row(6, 15, (100, 260), 0.8, 0.44, heading=6, off=0.12, flick=32, hold=0.4)
    for s in (-1, 1):
        hair.row(3, 72, (s * 56, s * 100), 0.62, 0.36, off=0.05, flick=18, hold=0.6, jitter=0.16, comb=(0, -1, -0.2), split=0.3)
    back_ = (0, -1, 0.3)
    hair.row(6, 54, (-64, 64), 0.98, 0.46, off=0.1, flick=30, hold=0.62, jitter=0.2, comb=back_, thick=0.1)
    hair.row(5, 28, (-82, 82), 0.92, 0.48, off=0.15, flick=38, hold=0.55, jitter=0.2, comb=back_, thick=0.1)
    # one lock that won't stay back, to the brow
    hair.clump(10, 50, 0.46, 0.15, heading=4, bend=12, off=0.05, flick=18, hold=0.6)
    return figure(joints, folder, b, head, hair)


# --- B, the dojo trainee -----------------------------------------------------------------------------------------------

def take_b(joints, folder):
    skin, gi, navy = "#E4AC80", "#EEE8DA", "#283350"
    edge, lapel = tone(gi, 0.5), "#D6CCB6"
    b = blocks_of({"torso": gi, "rs": gi, "ls": gi, "rh": navy, "lh": navy})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    f.lay(f.poly([(-0.3, 2.0), (0.3, 2.0), (0.03, 1.22)]), skin)
    dark(f, f.soft(f.poly([(-0.3, 2.0), (0.3, 2.0), (0.2, 1.84), (-0.2, 1.84)]), 0.04), 0.18)
    # the collar's two bands crossed on the chest, his left over his right, the upper one running on to the sash
    f.lay(f.poly([(-0.48, 2.0), (-0.28, 2.0), (0.2, 1.02), (0.06, 0.92)]), lapel)
    line(f, [(-0.28, 2.0), (0.2, 1.02)], 0.02, edge)
    line(f, [(-0.48, 2.0), (0.06, 0.92)], 0.016, edge, 0.8)
    f.lay(f.poly([(0.48, 2.0), (0.28, 2.0), (-0.5, 0.36), (-0.3, 0.36)]), lapel)
    line(f, [(0.28, 2.0), (-0.5, 0.36)], 0.022, edge)
    line(f, [(0.48, 2.0), (-0.3, 0.36)], 0.018, edge, 0.85)
    creases(f, [[(0.95, 1.5), (0.75, 1.36), (0.56, 1.4)], [(0.9, 0.98), (0.66, 0.8), (0.4, 0.74)], [(-0.95, 1.5), (-0.74, 1.34), (-0.56, 1.36)],
                [(-0.9, 0.9), (-0.74, 0.72), (-0.62, 0.52)], [(0.3, 1.2), (0.42, 0.9), (0.36, 0.6)]], 0.3)
    creases(back, [[(0.0, 1.9), (0.012, 1.2), (0.0, 0.4)], [(-0.9, 1.56), (-0.5, 1.42), (-0.2, 1.48)],
                   [(0.9, 1.56), (0.5, 1.42), (0.2, 1.48)], [(-0.8, 0.9), (-0.5, 0.72), (-0.3, 0.5)],
                   [(0.8, 0.9), (0.5, 0.72), (0.3, 0.5)]], 0.3)
    w.lay(w.rect(0.48, 1.88, 9, 2.0), lapel)
    w.lay(w.rect(-9, 1.88, -0.48, 2.0), lapel)
    w.lay(w.rect(0.48, 1.87, 9, 1.89), edge)
    w.lay(w.rect(-9, 1.87, -0.48, 1.89), edge)
    # the sash, wound twice, and its knot on his left hip
    band(w, 0.04, 0.36, RED, tone(RED, 0.5), 0.012)
    w.lay(w.rect(-9, 0.19, 9, 0.206), tone(RED, 0.62))
    w.lay(w.rect(-9, 0.0, 9, 0.04), gi)
    f.lay(f.poly([(0.5, 0.34), (0.66, 0.36), (0.68, 0.06), (0.52, 0.04)]), tone(RED, 0.5))
    f.lay(f.poly([(0.515, 0.325), (0.645, 0.342), (0.665, 0.076), (0.535, 0.058)]), tone(RED, 0.84))
    shadow(t, 0.26)
    neck(t, skin)

    for key in ("rs", "ls"):
        a = b[key]
        w = a.wrap
        w.lay(w.rect(-9, 0.0, 9, 1.2), skin)
        wraps(a, 0.0, 0.94 if key == "rs" else 0.4, RED)
        band(w, 1.2, 1.36, lapel, edge)
        for p in a.sides:
            creases(p, [[(-0.42, 1.72), (-0.05, 1.6), (0.34, 1.66)], [(-0.3, 1.52), (0.08, 1.46), (0.42, 1.52)]], 0.3)
            dark(p, p.soft(p.rect(-9, 1.08, 9, 1.2), 0.03), 0.22)
        fist(a, RED)
        shadow(a, 0.28, low=0.0)
        a.faces["top"].px[:] = rgb(gi)

    for key, s in (("rh", -1), ("lh", 1)):
        g = b[key]
        w, f = g.wrap, g.faces["front"]
        for p in g.sides:
            creases(p, [[(-0.44, 1.2), (-0.1, 1.02), (0.36, 1.1)], [(-0.36, 0.8), (0.0, 0.62), (0.4, 0.7)],
                        [(-0.3, 0.52), (-0.24, 0.42)], [(0.0, 0.54), (0.02, 0.42)], [(0.3, 0.52), (0.24, 0.42)]], 0.5)
            light(p, p.soft(p.rect(-0.26, 1.2, 0.2, 1.6), 0.09), 0.08)
        # the top's skirt under the sash, split at the side
        band(w, 1.7, 2.0, gi, None)
        w.lay(w.rect(-9, 1.69, 9, 1.712), edge)
        x = -1.0 if key == "rh" else 1.0
        w.lay(w.poly([(x - 0.07, 1.7), (x + 0.07, 1.7), (x, 1.96)]), navy)
        if key == "lh":   # the sash's two ends
            for x0, x1, low in ((-0.04, 0.1, 1.3), (0.1, 0.22, 1.46)):
                f.lay(f.poly([(x0, 2.0), (x1, 2.0), (x1 + 0.03, low), (x0 - 0.02, low + 0.03)]), RED)
                line(f, [(x0, 2.0), (x0 - 0.02, low + 0.03), (x1 + 0.03, low), (x1, 2.0)], 0.016, tone(RED, 0.5))
        band(w, 0.3, 0.4, tone(navy, 0.7), tone(navy, 0.4))
        shoe(g, "#24242C", "#E6E2D8", "#34343E")
        shadow(g, 0.3, low=0.0)

    head = am.Head(skin)
    p = head.paint
    am.draw_face(p, dict(skin=skin, iris="#E39A2C", eye_w=0.33, eye_h=0.21, eye_x=0.272, eye_y=0.54, tilt=0.012, shut=0.04,
                         brow_y=0.765, brow_tilt=-0.012, brow="#4A2415", mouth=[(-0.1, 0.262), (0.0, 0.256), (0.1, 0.262)]))
    # the grin: his teeth showing
    grin = [(-0.115, 0.264), (0.115, 0.264), (0.09, 0.2), (0.0, 0.176), (-0.09, 0.2)]
    p.lay(p.poly(grin), "#FBFAF6")
    line(p, grin + [grin[0]], 0.014, tone(skin, 0.36), 1.0)
    line(p, [(-0.1, 0.226), (0.1, 0.226)], 0.008, "#C9C4BC", 0.8)
    # a nick through his left brow
    x = 0.272 + 0.33 * 0.3
    p.lay(p.stroke([(x - 0.02, 0.83), (x + 0.02, 0.72)], (0.026, 0.026), n=4), mix(skin, "#FFFFFF", 0.12))
    hair = am.Hair("#3A1C0E", "#9E5A2C", seed=5)
    hair.shell(am.hairline(front=5.02, temple=4.62, nape=4.26))
    # cropped: short clumps, the back and sides first, then the top lying forward from the crown to a short fringe
    hair.row(8, 94, (108, 252), 0.3, 0.24, off=0.03, flick=16, hold=0.5, jitter=0.2)
    hair.row(12, 72, (76, 284), 0.46, 0.28, heading=8, off=0.05, flick=28, hold=0.45)
    hair.row(12, 48, (68, 292), 0.56, 0.3, heading=12, off=0.08, flick=34, hold=0.45)
    hair.row(7, 20, (95, 265), 0.6, 0.32, heading=10, off=0.11, flick=34, hold=0.45)
    for s in (-1, 1):  # the temples, so no bare scalp shows beside the fringe
        hair.row(3, 58, (s * 50, s * 86), 0.4, 0.28, off=0.05, flick=20, hold=0.55, jitter=0.2, comb=(0, 0.5, -1))
    hair.row(8, 38, (-78, 78), 0.52, 0.3, off=0.08, flick=24, hold=0.6, comb=(0, 1, -0.3))
    hair.row(7, 12, (-180, 180), 0.74, 0.34, off=0.12, flick=24, hold=0.6, comb=(0, 1, 0.0))
    return figure(joints, folder, b, head, hair)


# --- C, the gym kid ----------------------------------------------------------------------------------------------------

def take_c(joints, folder):
    skin, jacket, white, jogger = "#F0C6A6", RED, "#F2EFE8", "#24252E"
    edge, rib = tone(jacket, 0.5), tone(jacket, 0.74)
    b = blocks_of({"torso": jacket, "rs": jacket, "ls": jacket, "rh": jogger, "lh": jogger})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the T-shirt at the open collar, the collar's two points, the zip
    f.lay(f.poly([(-0.26, 2.0), (0.26, 2.0), (0.0, 1.52)]), white)
    f.lay(f.ellipse(0.0, 2.02, 0.18, 0.15), skin)
    line(f, [(-0.18, 2.0), (-0.1, 1.9), (0.0, 1.87), (0.1, 1.9), (0.18, 2.0)], 0.024, tone(white, 0.7))
    for s in (-1, 1):
        f.lay(f.poly([(s * 0.26, 2.0), (s * 0.52, 2.0), (s * 0.3, 1.6), (s * 0.0, 1.52)]), rib)
        line(f, [(s * 0.52, 2.0), (s * 0.3, 1.6), (0.0, 1.52), (s * 0.26, 2.0)], 0.018, edge)
        creases(f, [[(s * 0.96, 1.5), (s * 0.74, 1.36), (s * 0.5, 1.4)], [(s * 0.92, 0.96), (s * 0.66, 0.78), (s * 0.42, 0.74)],
                    [(s * 0.3, 1.16), (s * 0.4, 0.88), (s * 0.34, 0.6)]], 0.42)
        light(f, f.soft(f.poly([(s * 0.4, 1.5), (s * 0.82, 1.56), (s * 0.78, 1.2), (s * 0.4, 1.16)]), 0.08), 0.12)
    line(f, [(0.0, 1.52), (0.0, 0.16)], 0.026, edge)
    line(f, [(0.0, 1.52), (0.0, 0.16)], 0.008, "#D9D5CC", 0.9)
    f.lay(f.rect(-0.03, 1.38, 0.03, 1.52), "#D9D5CC")
    # the hem's ribbed band
    band(w, 0.0, 0.17, rib, edge)
    for x in np.arange(-1.96, 4.0, 0.08):
        w.lay(w.rect(x - 0.006, 0.02, x + 0.006, 0.15), edge, 0.55)
    # the hood, flat on his back
    hood = [(-0.62, 2.0), (-0.66, 1.5), (-0.4, 1.14), (0.0, 1.02), (0.4, 1.14), (0.66, 1.5), (0.62, 2.0)]
    dark(back, back.soft(back.poly([(x, y - 0.07) for x, y in hood]), 0.05), 0.3)
    back.lay(back.poly(hood), mix(jacket, "#FFFFFF", 0.07))
    line(back, hood, 0.022, edge)
    line(back, [(-0.36, 2.0), (-0.3, 1.62), (0.0, 1.46), (0.3, 1.62), (0.36, 2.0)], 0.016, edge, 0.7)
    creases(back, [[(-0.8, 0.9), (-0.5, 0.72), (-0.3, 0.46)], [(0.8, 0.9), (0.5, 0.72), (0.3, 0.46)], [(-0.2, 0.8), (0.0, 0.7), (0.2, 0.78)]], 0.42)
    w.lay(w.rect(0.52, 1.88, 2.0, 2.0), rib)
    w.lay(w.rect(-2.0, 1.88, -0.52, 2.0), rib)
    shadow(t, 0.3)
    neck(t, skin)

    for key in ("rs", "ls"):
        a = b[key]
        w = a.wrap
        outer = a.faces["right" if key == "rs" else "left"]
        if key == "rs":   # the sleeve pushed up to the elbow, the wraps up the forearm
            w.lay(w.rect(-9, 0.0, 9, 1.0), skin)
            wraps(a, 0.0, 0.92, CLOTH)
            low = 1.0
            folds = [[(-0.44, 1.3), (-0.05, 1.2), (0.4, 1.28)], [(-0.4, 1.16), (0.05, 1.1), (0.44, 1.14)], [(-0.4, 1.6), (0.0, 1.5), (0.34, 1.56)]]
        else:
            w.lay(w.rect(-9, 0.0, 9, 0.44), skin)
            wraps(a, 0.0, 0.4, CLOTH)
            low = 0.44
            folds = [[(-0.42, 1.5), (-0.05, 1.38), (0.34, 1.46)], [(-0.3, 1.1), (0.08, 1.0), (0.42, 1.08)], [(-0.4, 0.84), (0.0, 0.76), (0.3, 0.8)]]
        outer.lay(outer.rect(-0.09, low, 0.09, 2.0), white)
        for x in (-0.09, 0.09):
            line(outer, [(x, low), (x, 2.0)], 0.012, edge, 0.7)
        for p in a.sides:
            creases(p, folds, 0.42)
        band(w, low, low + 0.13, rib, edge)
        fist(a, CLOTH)
        shadow(a, 0.32, low=0.0)
        a.faces["top"].px[:] = rgb(jacket)

    for key in ("rh", "lh"):
        g = b[key]
        w, f = g.wrap, g.faces["front"]
        outer = g.faces["right" if key == "rh" else "left"]
        outer.lay(outer.rect(-0.07, 0.4, 0.07, 2.0), white)
        for p in g.sides:
            creases(p, [[(-0.4, 1.2), (-0.05, 1.06), (0.36, 1.14)], [(-0.34, 0.74), (0.0, 0.6), (0.36, 0.66)]], 0.45)
            light(p, p.soft(p.rect(-0.24, 1.3, 0.2, 1.7), 0.09), 0.07)
        band(w, 0.3, 0.42, tone(jogger, 0.72), tone(jogger, 0.4))
        shoe(g, RED, "#F2EFE8", "#F2EFE8")
        shadow(g, 0.32, low=0.0)

    head = am.Head(skin)
    p = head.paint
    am.draw_face(p, dict(skin=skin, iris="#4FA56C", eye_w=0.31, eye_h=0.17, eye_x=0.268, eye_y=0.535, tilt=0.026, shut=0.46,
                         brow_y=0.672, brow_tilt=0.012, brow="#241512", mouth=[(-0.075, 0.226), (0.0, 0.222), (0.07, 0.24), (0.09, 0.258)]))
    strip(p, 0.34, 0.33, 0.19, 0.07, -14, "#F4F1EA", "#DDD8CC")
    hair = am.Hair("#2A1812", "#8E5E40", seed=11)
    hair.shell(am.hairline())
    # messy: long clumps turned one way round the crown, their tips well out, and a heavy fringe to the brows
    hair.row(7, 92, (105, 255), 0.5, 0.34, heading=6, off=0.03, flick=18, hold=0.5)
    hair.row(9, 60, (70, 290), 0.8, 0.44, heading=14, off=0.07, flick=30, hold=0.4, jitter=0.38)
    hair.row(8, 34, (50, 310), 0.9, 0.48, heading=22, off=0.11, flick=34, hold=0.4, jitter=0.38)
    hair.row(6, 10, (-180, 180), 0.85, 0.48, heading=30, off=0.14, flick=34, hold=0.45)
    hair.row(3, 7, (-180, 180), 0.6, 0.32, heading=55, off=0.12, flick=55, hold=0.2, split=1.0)
    for a, length, width, heading, bend, split in ((-50, 0.58, 0.38, -14, -12, 1), (-30, 0.68, 0.42, -8, 10, 1), (-10, 0.74, 0.4, 4, -10, 1),
                                                   (8, 0.64, 0.38, 8, 10, 0), (26, 0.7, 0.42, 12, -8, 1), (46, 0.58, 0.38, 18, 12, 1)):
        hair.clump(a, 40, length, width, heading=heading, bend=bend, off=0.07, flick=16, hold=0.7, split=split)
    for s in (-1, 1):
        hair.clump(s * 72, 52, 0.7, 0.3, heading=s * -6, bend=s * 8, off=0.05, flick=14, hold=0.75, split=1)
    return figure(joints, folder, b, head, hair)


TAKES = {"A": take_a, "B": take_b, "C": take_c}


# --- the pictures ------------------------------------------------------------------------------------------------------

def full_views(scene, shots, key):
    rm.eevee(scene, SHOT, SHOT)
    for view, (azimuth, elevation) in VIEWS.items():
        rm.sun_for(scene, azimuth)
        am.fill_for(scene, azimuth)
        rs.shoot(scene, shots / f"{key}_{view}.png", azimuth, elevation, MID, SPAN)


def bust_view(scene, shots, key):
    rm.eevee(scene, *BUST_PX)
    azimuth = 180.0 - BUST["side"] * BUST["body"]
    rm.sun_for(scene, azimuth)
    am.fill_for(scene, azimuth)
    rs.shoot(scene, shots / f"{key}_bust.png", azimuth, BUST["elevation"], BUST["centre"], BUST["span"])


def spots(key):
    """Where a figure stands in the capture's frame: (stem, x, z, faces toward)."""
    import shade_elites as el
    x = ROW_X[(WHO + ("Shade",)).index(key)]
    fight = ("foe", *FOE, LEAD) if key == "Shade" else ("fight", *LEAD, FOE)
    return [fight, ("row", x, ROW_Z, el.toward((x, ROW_Z), 26.0))]


def keep(he, scene, layers, stem, x, z):
    """One figure's layer, cut to its own pixels."""
    he.border(scene, x, z, 1.25, TALL / 1.25)
    path = layers / f"{stem}.npy"
    he.render(scene, path)
    full = np.load(path)
    rows, cols = np.nonzero(full[..., 3] > 0)
    y0, y1, x0, x1 = rows.min(), rows.max() + 1, cols.min(), cols.max() + 1
    np.savez_compressed(path.with_suffix(".npz"), px=full[y0:y1, x0:x1], at=np.array([x0, y0]))
    path.unlink()


def takes_run(out, keys, finish=None):
    """`finish(key, made)`, if given, is run on each figure once it is built and before it is drawn."""
    import hard_ember as he
    import r6anim as r6
    shots, layers = out / "shots", out / "layers"
    shots.mkdir(parents=True, exist_ok=True)
    layers.mkdir(parents=True, exist_ok=True)
    for key in keys:
        folder = out / "tex" / key
        folder.mkdir(parents=True, exist_ok=True)
        scene = bl.reset_scene()
        scene.world = bpy.data.worlds.new("Takes")
        j = wt.rig(scene)
        am.PICTURES.clear()
        am.GLOWS.clear()
        made = TAKES[key](j, folder)
        if finish:
            finish(key, made)
        rs.POSES["idle"](j)
        bpy.context.view_layer.update()
        tris = sum(len(f.vertices) - 2 for o in made.values() for f in o.data.polygons)
        print(f"{key}: {tris} triangles, hair {sum(len(f.vertices) - 2 for f in made['hair'].data.polygons)}")
        full_views(scene, shots, key)
        idle = {name: (joint.location.copy(), joint.rotation_quaternion.copy()) for name, joint in j.items()}
        for joint in j.values():
            joint.rotation_quaternion = (1, 0, 0, 0)
        j["root"].location = wt.PIVOTS["root"]
        rm.eevee(scene, *SQUARE[:2])
        rm.sun_for(scene, 180)
        am.fill_for(scene, 180)
        rs.shoot(scene, shots / f"{key}_square.png", 180, 2, (0.0, 0.0, SQUARE[3]), SQUARE[2])
        rs.POSES["square"](j)
        # the lead card's pose: the right shoulder forward, the head turned back to the player
        yaw = -math.radians(BUST["side"] * BUST["turn"])
        j["neck"].rotation_quaternion = (Matrix.Rotation(yaw, 3, "Z") @ Matrix.Rotation(math.radians(BUST["nod"]), 3, "X")
                                         @ Matrix.Rotation(math.radians(BUST["tilt"]), 3, "Y")).to_quaternion()
        bust_view(scene, shots, key)
        am.turnaround(scene, j, shots, key)
        for name, joint in j.items():
            joint.location, joint.rotation_quaternion = idle[name]
        bpy.context.view_layer.update()
        base = j["root"].matrix_world.copy()
        he.setup(scene)
        for stem, x, z, faces in spots(key):
            at = Vector((x, he.ROOT, z))
            m = r6.to_blender(r6.look_at(at, at + he.facing((x, z), faces)))
            j["root"].matrix_world = m @ Matrix.Translation((0, 0, -he.ROOT)) @ base
            keep(he, scene, layers, f"{key}_{stem}", x, z)


def rook_run(out):
    """Today's Rook, the model in the game, in the same pictures."""
    import hard_ember as he
    import hud_art as ha
    import rook_clips as rc
    shots, layers = out / "shots", out / "layers"
    shots.mkdir(parents=True, exist_ok=True)
    layers.mkdir(parents=True, exist_ok=True)
    scene, rig_, _, undress, _ = rc.build()
    undress(False)
    last = he.key(rig_, he.REPO / "build" / "handoff" / "Rook" / "clips" / "Rook_Idle.json")
    for o in [o for o in scene.objects if o.type in ("LIGHT", "CAMERA")]:
        bpy.data.objects.remove(o)
    if "Floor" in bpy.data.objects:
        bpy.data.objects["Floor"].hide_render = True
    scene.frame_set(0)
    full_views(scene, shots, "Rook")
    he.setup(scene)
    for stem, x, z, faces in spots("Rook"):
        he.stand(rig_, x, z, faces, 1.0)
        scene.frame_set(7 % last)
        keep(he, scene, layers, f"Rook_{stem}", x, z)
    ha.PORTRAITS["Rook"].update(centre=BUST["centre"], span=BUST["span"])
    rs.save(ha.shoot_portrait("Rook", shots, BUST_PX), shots / "Rook_bust.png")


def shade_run(out):
    """A Brawler in the game's Idle, as the foe and at the row's end."""
    import hard_cut as hc
    import shade_kinds as sk
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    he, scene, rig_, last, _, wear, wear_mask = sk.staged()
    wear("Normal", dict(he.SHADE, body="#" + hc.type_tints()["Red"]))
    wear_mask("Brawler")
    for stem, x, z, faces in spots("Shade"):
        he.stand(rig_, x, z, faces, 1.0)
        scene.frame_set(11 % last)
        keep(he, scene, layers, f"Shade_{stem}", x, z)


# --- the sheet ---------------------------------------------------------------------------------------------------------

def deck(he):
    """The base's deck by day, a stand-in in the capture's frame: pale plates with their seams, a day sky. Linear."""
    gx, gz = he.ground_points()
    horizon = int(round(he.project((0.0, he.EYE.y, -4000.0))[1]))
    lin = lambda code: he.to_linear(np.array(rs.rgb(code), np.float32)[:3])  # noqa: E731
    out = np.ones((he.H, he.W, 4), np.float32)
    rise = np.linspace(0.0, 1.0, horizon)[:, None, None]
    out[:horizon, :, :3] = lin("#4C93DE") * (1 - rise) + lin("#CFE4F4") * rise
    x, z = np.nan_to_num(gx[horizon:]), np.nan_to_num(gz[horizon:])
    far = np.hypot(x - he.EYE.x, z - he.EYE.z)
    seam = np.minimum(4 - np.abs((x / 8) % 1 - 0.5) * 8, 4 - np.abs((z / 8) % 1 - 0.5) * 8)
    line_ = np.clip(1 - seam / (0.05 + far * 0.0022), 0, 1) * np.clip(60 / np.maximum(far, 1), 0, 1)
    ground = lin("#CCD2D9") * (1 - line_[..., None]) + lin("#A4ACB7") * line_[..., None]
    haze = np.exp(-far / 260.0)[..., None]
    out[horizon:, :, :3] = ground * haze + lin("#CFE4F4") * (1 - haze)
    return out, gx, gz


def reference(name, to):
    """One of the reference's pictures at `to` pixels a stud. Internal: it is laid on the sheet, never kept apart."""
    image = bpy.data.images.load(str(REPO / "build" / "reference" / "anime-vanguards" / name))
    w, h = image.size
    px = np.empty(w * h * 4, np.float32)
    image.pixels.foreach_get(px)
    return rs.shrink(px.reshape(h, w, 4)[::-1].copy(), to / BESIDE_PX)


def stage(out):
    """The capture's frame on the deck, and what lays the figures' layers in it: shared by the sheet and the proof."""
    import brawler_mask_look as bm
    import hard_cut as hc
    import hard_ember as he
    import shade_elites as el
    layers = out / "layers"
    backdrop, gx, gz = deck(he)
    phone = el.PHONE_H / he.H

    def layer(stem):
        got = np.load(layers / f"{stem}.npz")
        px, (x0, y0) = got["px"].astype(np.float32), got["at"]
        full = np.zeros((he.H, he.W, 4), np.float32)
        full[y0:y0 + px.shape[0], x0:x0 + px.shape[1]] = px
        return full

    def laid(stems_at):
        got = [(he.project((x, 0, z))[2], layer(stem)) for stem, x, z in stems_at]
        return he.lay(backdrop, got, [(x, z, 1.0) for _, x, z in stems_at], "Normal", gx, gz)

    def box(places, half, pad):
        x0, y0, w, h = bm.box(places, half, TALL - 0.6, pad)
        x0, y0 = max(x0, 0), max(y0, 0)
        return x0, y0, min(w, he.W - x0), min(h, he.H - y0)

    def over(stem, at, colour, dark_=False):
        """A figure's own pixels at 64 to a 5-stud body, over a flat ground."""
        got = np.load(layers / f"{stem}.npz")["px"].astype(np.float32)
        base = he.to_linear(np.array(rs.rgb(colour), np.float32)[:3])
        comp = np.empty(got.shape[:2] + (4,), np.float32)
        comp[..., :3] = he.to_srgb(got[..., :3] + base * (1 - got[..., 3:]))
        if dark_:
            comp[..., :3] = he.to_srgb(base * (1 - got[..., 3:]) + he.to_linear(np.array((0.04, 0.04, 0.05), np.float32)) * got[..., 3:])
        comp[..., 3] = 1.0
        return rs.shrink(comp, 64 / 5.0 / (he.F / he.project((at[0], 0, at[1]))[2]))

    return bm, hc, he, el, phone, laid, box, over


def sheet_run(out):
    bm, hc, he, el, phone, laid, box, over = stage(out)
    shots = out / "shots"
    gap, W = 24, 1900
    ink, soft, paper, plate, pale = "#EDE6D6", "#B4AC9C", "#101117", "#1A1B24", "#DFE1E6"
    parts, text_of = [], []
    takes = WHO[1:]

    def part(height, name):
        page = rs.canvas(W, height, rs.rgb(paper))
        parts.append((name, page))
        text_of.append([])
        return page, text_of[-1]

    # the takes square on, between the reference's units at the same height: a picture of its own, kept internal
    sw, sh, span, mid = SQUARE
    per = sh / span
    feet = int(round(sh / 2 + mid * per))
    page, text = part(56 + sh + 44, "beside")
    text.append((gap, 16, 20, "AR59's redo: Rook's three takes square on, between two Anime Vanguards units at the same height. "
                              "Internal: the two are reference.", ink))
    rs.fill(page, 0, 56, W, sh + 10, rs.rgb(pale))
    col5 = W // 5
    for i, who in enumerate((BESIDE[0], "A", "B", "C", BESIDE[1])):
        x0 = i * col5
        if who in TAKES:
            shot = rs.load(shots / f"{who}_square.png")
            rs.paste(page, shot, x0 + (col5 - sw) // 2, 56)
            text.append((x0 + 16, 56 + sh + 18, 16, SAID[who][0], ink))
        else:
            shot = reference(who, per)
            rs.paste(page, shot, x0 + (col5 - shot.shape[1]) // 2, 56 + feet - int(shot.shape[0] * 0.994))
            text.append((x0 + 16, 56 + sh + 18, 14, "an Anime Vanguards unit (reference)", soft))

    # 1. each from the front and from the game's camera, beside today's
    col = (W - 2 * gap) // 4
    page, text = part(1150, "full")
    text.append((gap, 20, 30, "AR59'S REDO: ROOK IN THE MAKE, THREE TAKES", ink))
    text += hc.wrapped(gap, 60, 16, "Common / Red / Warrior, no element: the lead every new player holds. The make is the genre's: R6's plain "
                                   "blocks with the clothes drawn on them, a drawn anime face on the round head, hair as one mass of broad sharp "
                                   "clumps, nothing built on the body. His fists are cloth wraps drawn on the arms; the gauntlet is gone. "
                                   "Each stands as in the game: from the three-quarter front, then from the game's camera behind his right "
                                   "shoulder, today's Rook first. Research picks one.", soft, W - 2 * gap)
    for i, key in enumerate(WHO):
        x0 = gap + i * col
        title, lines = SAID[key]
        text.append((x0, 150, 24, title, ink))
        text += [(x0, 184 + k * 20, 14, line_, soft) for k, line_ in enumerate(lines)]
        front = rs.shrink(rs.trim(rs.load(shots / f"{key}_front.png")), 0.7)
        game = rs.shrink(rs.trim(rs.load(shots / f"{key}_game.png")), 0.48)
        rs.stand(page, front, x0, 800, col - gap)
        rs.stand(page, game, x0, 1136, col - gap)

    # 2. the head from six sides
    turn = {key: rs.shrink(rs.load(shots / f"{key}_turn.png"), (W - 4 * gap) / 3 / 1260) for key in takes}
    th = turn["A"].shape[0]
    page, text = part(46 + th + 40, "heads")
    text.append((gap, 14, 18, "The head from six sides: face on, each three-quarter, a side, the back, and the game's camera.", ink))
    for i, key in enumerate(takes):
        x0 = gap + i * (turn[key].shape[1] + gap)
        rs.paste(page, turn[key], x0, 46)
        text.append((x0, 46 + th + 10, 14, SAID[key][0], soft))

    # 3. the bust in the lead card's pose
    page, text = part(470, "bust")
    text.append((gap, 14, 18, "The bust in the lead card's pose, then at the card's size on the smallest phone (and twice that).", ink))
    for i, key in enumerate(WHO):
        x0 = gap + i * col
        shot = rs.load(shots / f"{key}_bust.png")
        big, small = rs.shrink(shot, 0.5), rs.shrink(shot, CARD)
        rs.fill(page, x0, 46, big.shape[1], big.shape[0], rs.rgb(plate))
        rs.paste(page, big, x0, 46)
        sx = x0 + big.shape[1] + 12
        rs.fill(page, sx, 46, small.shape[1], small.shape[0], rs.rgb(plate))
        rs.paste(page, small, sx, 46)
        twice = rs.shrink(shot, CARD * 2)
        rs.fill(page, sx, 60 + small.shape[0], twice.shape[1], twice.shape[0], rs.rgb(plate))
        rs.paste(page, twice, sx, 60 + small.shape[0])
        text.append((x0, 46 + big.shape[0] + 10, 14, SAID[key][0], soft))

    # 4. in a fight on the deck, from the player's camera
    fight_box = box([LEAD, FOE], 3.2, 10)
    fights = {key: rs.shrink(he.crop(laid([(f"{key}_fight", *LEAD), ("Shade_foe", *FOE)]), *fight_box), phone) for key in WHO}
    fw, fh = fights["A"].shape[1], fights["A"].shape[0]
    k = max(1, min(3, (col - gap) // fw))
    page, text = part(60 + fh + 16 + fh * k + 40, "fight")
    text.append((gap, 14, 18, f"In a fight on the deck from the player's camera, at the smallest phone ({el.PHONE_H} pixels high): at its "
                              f"own size, then {k} times. The deck is a stand-in; the camera and the light are the game's.", ink))
    for i, key in enumerate(WHO):
        x0 = gap + i * col
        rs.paste(page, fights[key], x0, 46)
        rs.paste(page, bm.zoomed(fights[key], k), x0, 46 + fh + 16)
        text.append((x0, 46 + fh + 16 + fh * k + 8, 14, SAID[key][0], soft))

    # 5. the line-up at the lead's distance
    row_box = box([(ROW_X[0], ROW_Z), (ROW_X[-1], ROW_Z)], 3.0, 10)
    row = rs.shrink(he.crop(laid([(f"{key}_row", x, ROW_Z) for key, x in zip(WHO + ("Shade",), ROW_X)]), *row_box), phone)
    rw, rh = row.shape[1], row.shape[0]
    kr = max(1, min(4, (W - 3 * gap - rw) // rw))
    page, text = part(60 + rh * kr + 20, "row")
    text.append((gap, 14, 18, f"At the lead's distance, turned to the player: today's Rook, A, B, C and a Brawler. At the smallest phone, "
                              f"then {kr} times.", ink))
    rs.paste(page, row, gap, 46)
    rs.paste(page, bm.zoomed(row, kr), gap + rw + gap, 46)

    # 6. at 64 pixels
    page, text = part(400, "small")
    text.append((gap, 14, 18, "At 64 pixels to a 5-stud body: turned to the player and fighting, from behind. Over night, over the deck, "
                              "and the outline.", ink))
    x = gap
    for key in WHO + ("Shade",):
        pair = [(f"{key}_row", (ROW_X[(WHO + ("Shade",)).index(key)], ROW_Z)), (f"{key}_foe" if key == "Shade" else f"{key}_fight",
                                                                              FOE if key == "Shade" else LEAD)]
        text.append((x, 46, 14, SAID[key][0] if key in SAID else "A Brawler", soft))
        widest = 0
        for stem, at in pair:
            for r, (ground, dark_) in enumerate((("#101117", False), ("#CCD2D9", False), ("#E9E4D8", True))):
                tile = over(stem, at, ground, dark_)
                rs.paste(page, tile, x + widest, 72 + r * 106 + (100 - tile.shape[0]))
            widest += tile.shape[1] + 8
        x += widest + 40

    height = sum(page.shape[0] for name, page in parts if name != "beside")
    whole = rs.canvas(W, height, rs.rgb(paper))
    y = 0
    for (name, page), text in zip(parts, text_of):
        rs.paste(page, rs.text_layer(W, page.shape[0], text), 0, 0)
        if name == "beside":
            rs.save(page, out / "rook_beside.png")
            continue
        rs.save(page, out / f"rook_takes_{name}.png")
        whole[y:y + page.shape[0]] = page
        y += page.shape[0]
    rs.save(whole, out / "rook_takes.png")


def proof_run(out, key, title=None):
    """The picked take alone, as the finish is judged: the figure from the front and from the game's camera, the bust
    at the card's size, the head from six sides, a fight at the smallest phone, and 64 pixels. A second picture, kept
    internal, stands it between the reference's units."""
    bm, hc, he, el, phone, laid, box, over = stage(out)
    shots = out / "shots"
    gap, W = 24, 1900
    ink, soft, paper, plate, pale = "#EDE6D6", "#B4AC9C", "#101117", "#1A1B24", "#DFE1E6"
    heading, (title, lines) = title, SAID[key]

    # the figure, and the bust in the lead card's pose
    top = rs.canvas(W, 800, rs.rgb(paper))
    text = [(gap, 20, 30, heading or f"AR59: ROOK, THE PICK ({title.upper()})", ink)]
    text += hc.wrapped(gap, 60, 16, "Common / Red / Warrior / Fire. " + "; ".join(lines) + ". From the three-quarter front, from the "
                                   "game's camera behind his right shoulder, and the bust in the lead card's pose with the card's size on "
                                   "the smallest phone (and twice that).", soft, W - 2 * gap)
    rs.stand(top, rs.shrink(rs.trim(rs.load(shots / f"{key}_front.png")), 0.8), gap, 786, 600)
    rs.stand(top, rs.shrink(rs.trim(rs.load(shots / f"{key}_game.png")), 0.8), gap + 600, 786, 600)
    shot = rs.load(shots / f"{key}_bust.png")
    big, small, twice = rs.shrink(shot, 0.8), rs.shrink(shot, CARD), rs.shrink(shot, CARD * 2)
    x0 = W - gap - big.shape[1] - 12 - twice.shape[1]
    for tile, x, y in ((big, x0, 130), (small, x0 + big.shape[1] + 12, 130), (twice, x0 + big.shape[1] + 12, 144 + small.shape[0])):
        rs.fill(top, x, y, tile.shape[1], tile.shape[0], rs.rgb(plate))
        rs.paste(top, tile, x, y)
    rs.paste(top, rs.text_layer(W, top.shape[0], text), 0, 0)

    # the head from six sides, a fight, and 64 pixels
    turn = rs.shrink(rs.load(shots / f"{key}_turn.png"), 1000 / 1260)
    low = rs.canvas(W, 46 + turn.shape[0] + 24, rs.rgb(paper))
    text = [(gap, 14, 18, "The head from six sides. A fight on the deck from the player's camera at the smallest phone "
                          f"({el.PHONE_H} pixels high), at its own size and 3 times. At 64 pixels to a 5-stud body.", ink)]
    rs.paste(low, turn, gap, 46)
    fight = rs.shrink(he.crop(laid([(f"{key}_fight", *LEAD), ("Shade_foe", *FOE)]), *box([LEAD, FOE], 3.2, 10)), phone)
    fx = gap + turn.shape[1] + gap
    rs.paste(low, fight, fx, 46)
    rs.paste(low, bm.zoomed(fight, 3), fx, 46 + fight.shape[0] + 16)
    x = fx + fight.shape[1] * 3 + gap
    for stem, at in ((f"{key}_row", (ROW_X[WHO.index(key)], ROW_Z)), (f"{key}_fight", LEAD)):
        for r, (ground, dark_) in enumerate((("#101117", False), ("#CCD2D9", False), ("#E9E4D8", True))):
            tile = over(stem, at, ground, dark_)
            rs.paste(low, tile, x, 46 + r * 106 + (100 - tile.shape[0]))
        x += tile.shape[1] + 8
    rs.paste(low, rs.text_layer(W, low.shape[0], text), 0, 0)
    whole = rs.canvas(W, top.shape[0] + low.shape[0], rs.rgb(paper))
    whole[:top.shape[0]], whole[top.shape[0]:] = top, low
    rs.save(whole, out / "rook_pick.png")

    # square on, between the reference's units at the same height: internal
    sw, sh, span, mid = SQUARE
    per = sh / span
    feet = int(round(sh / 2 + mid * per))
    page = rs.canvas(1200, 56 + sh + 20, rs.rgb(paper))
    rs.fill(page, 0, 56, 1200, sh + 10, rs.rgb(pale))
    for i, who in enumerate((BESIDE[0], key, BESIDE[1])):
        if who == key:
            rs.paste(page, rs.load(shots / f"{key}_square.png"), i * 400 + (400 - sw) // 2, 56)
        else:
            shot = reference(who, per)
            rs.paste(page, shot, i * 400 + (400 - shot.shape[1]) // 2, 56 + feet - int(shot.shape[0] * 0.994))
    rs.paste(page, rs.text_layer(1200, page.shape[0], [(gap, 16, 18, "AR59: the pick square on, between two Anime Vanguards units at the "
                                                                    "same height. Internal: the two are reference.", ink)]), 0, 0)
    rs.save(page, out / "rook_pick_beside.png")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "sheet"
    if mode == "takes":
        takes_run(OUT, rest[1:] or list(TAKES))
    elif mode == "proof":
        proof_run(OUT, rest[1] if rest[1:] else "A")
    else:
        {"rook": rook_run, "shade": shade_run, "sheet": sheet_run}[mode](OUT)
