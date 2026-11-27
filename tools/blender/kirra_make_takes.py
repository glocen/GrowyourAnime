"""Kirra, redone in the make (AR60, research, 2026-11-24): three takes drawn with anime_make.py's kit, each a
side-cast type of the genre made our own, inside a Common's limit. Blue, an Assassin, Void: a quick, quiet fighter
whose hair reads first, then a sharp face, then a long scarf, then two short blades crossed on her back. From the
director's word of 01:47 she carries built pieces (`am.Built`): the scarf's turn, its knot and two tails, and the two
blades. Her clothes stay drawn on the blocks. Nothing on her reads as a job.

    A, the night runner: silver hair drawn up into one high tail, a side-swept fringe; cool half-shut blue eyes; a
       deep navy short-sleeved top with a mock neck, dark fingerless guards to the elbow; pale grey trousers bound at the
       shin; a teal scarf; the two blades bare steel.
    B, the transfer student: a deep teal bob with a blunt fringe and one standing lock; gold eyes; a cream cropped
       jacket with a standing collar over a charcoal top; charcoal leggings and tall boots; a cobalt scarf; the
       blades in charcoal scabbards.
    C, the drifter: straw-blonde hair in two tails tied high; wide sky-blue eyes, a small smile; an off-white wrap
       top with elbow sleeves, navy forearm guards, a wide navy sash; navy trousers gathered into wraps at the ankle;
       a sky-blue scarf; the blades in navy scabbards.

Each is drawn as the player meets it, by rook_make_takes.py's pictures and sheet: square on between two Anime
Vanguards units at the same height (internal); from the three-quarter front and the game's camera; the head from six
sides; the bust in the lead card's pose; a fight on the deck at the smallest phone; 64 pixels; and beside the new
Rook (AR59's pick, rook_make_takes.take_a), who stands in the "Rook" place.

    blender.exe -b --factory-startup --python tools/blender/kirra_make_takes.py -- <out_dir> takes [Rook A B C]
    blender.exe -b --factory-startup --python tools/blender/kirra_make_takes.py -- <out_dir> shade|sheet
    blender.exe -b --factory-startup --python tools/blender/kirra_make_takes.py -- <out_dir> proof [A]

One take a run keeps a run under the Studios' memory. `sheet` writes kirra_takes.png, its parts, and
kirra_beside.png (the reference's pictures: kept in build/reference, never in git).
"""
import math
import sys
from pathlib import Path

import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import rook_make_takes as rt  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402
from anime_make import INK, mix, rgb, tone  # noqa: E402
from rook_make_takes import band, blocks_of, creases, dark, grain, light, line, lit, neck, shadow, shoe  # noqa: E402

BESIDE = (("rukio-d3b5f35b53a496ef.webp", 169.5), ("kinnua-e8de7d4129ad5529.webp", 159.5))  # (file, its pixels a stud)
CROWN = am.CHIN + 1.25           # the head's top
# The blades crossed on her back, (the pommel's end, the tip): the right one's grip over her right shoulder, as the
# first Kirra's sheaths (kirra_sheet.SHEATHS), a little longer and higher so the grips show over the shoulders
BACK = {"R": ((0.8, -0.66, 4.62), (-0.56, -0.66, 2.66)), "L": ((-0.8, -0.84, 4.62), (0.56, -0.84, 2.66))}
SAID = {
    "Rook": ("The new Rook", ("AR59's pick, as research passed it,", "for her colours and outline beside his")),
    "A": ("A, the night runner", ("silver hair in one high tail, a side-swept fringe", "cool half-shut blue eyes",
                                  "a navy short-sleeved top, pale trousers bound at the shin", "a teal scarf; the blades bare steel")),
    "B": ("B, the transfer student", ("a deep teal bob, a blunt fringe, one standing lock", "gold eyes",
                                      "a cream cropped jacket over charcoal, tall boots", "a cobalt scarf; charcoal scabbards")),
    "C": ("C, the drifter", ("straw-blonde hair in two tails tied high", "wide sky-blue eyes, a small smile",
                             "an off-white wrap top, a navy sash and trousers", "a sky-blue scarf; navy scabbards")),
}
WORDS = dict(
    stem="kirra",
    beside="AR60: Kirra's three takes square on, between two Anime Vanguards units at the same height. Internal: the two are reference.",
    title="AR60: KIRRA IN THE MAKE, THREE TAKES",
    about="Common / Blue / Assassin / Void: a quick, quiet fighter from an anime's side cast. The make is AR59's: R6's plain blocks "
          "with the clothes drawn on them, a drawn face on the round head, hair as one mass of broad clumps; from the director's "
          "word of 01:47 she carries built pieces, the scarf with its two tails and the two short blades crossed on her back. "
          "Each stands as in the game: from the three-quarter front, then from the game's camera behind her right shoulder, the "
          "new Rook first. Research picks one.",
    row="the new Rook, A, B, C and a Brawler",
)


# --- drawing -----------------------------------------------------------------------------------------------------------

def face(head, look):
    """The kit's face, and what makes it hers: a heavier lash line that sweeps out past each eye's outer corner, and
    a lower lash at it."""
    p = head.paint
    am.draw_face(p, look)
    ew, eh, ex, ey, tilt = look["eye_w"], look["eye_h"], look["eye_x"], look["eye_y"], look.get("tilt", 0.0)
    for s in (-1, 1):
        x, y = s * (ex + ew / 2), ey + 0.16 * eh + tilt
        p.lay(p.stroke([(x - s * 0.05, y + 0.004), (x, y + 0.006), (x + s * 0.045, y + 0.04)], (0.034, 0.03, 0.004)), INK)
        p.lay(p.stroke([(x - s * 0.02, y - 0.02), (x + s * 0.012, y - 0.012), (x + s * 0.03, y + 0.0)], (0.014, 0.008, 0.0)), INK, 0.8)


def strap(p, a, b, colour, wide=0.1):
    """A strap across a picture from `a` to `b`, its two edges drawn."""
    edge = tone(colour, 0.5)
    p.lay(p.stroke([a, b], (wide, wide), n=4), colour)
    d = np.array(b) - np.array(a)
    n = np.array((-d[1], d[0])) / np.hypot(*d) * wide / 2
    for s in (-1, 1):
        line(p, [tuple(np.array(a) + s * n), tuple(np.array(b) + s * n)], 0.012, edge, 0.8)


def guards(block, colour, top, trim):
    """A fingerless guard from the hand to `top`: the knuckles bare under its edge, a band of `trim` at its top."""
    w = block.wrap
    w.lay(w.rect(-9, 0.12, 9, top), colour)
    band(w, top - 0.07, top, trim, tone(trim, 0.5))
    for p in block.sides:
        creases(p, [[(-0.4, top * 0.55), (0.0, top * 0.5), (0.4, top * 0.56)]], 0.3, 0.02)
        dark(p, p.soft(p.rect(-9, 0.12, 9, 0.18), 0.02), 0.3)
    w.lay(w.rect(-9, 0.11, 9, 0.13), tone(colour, 0.6))


def shin_wraps(block, colour, y0, y1, gap=0.1):
    """Cloth wound round a leg from y0 to y1, its turns slanted."""
    rt.wraps(block, y0, y1, colour, gap)


def sheath(built, base, tip, width, colour, cap, grip, guard, thick=0.1):
    """A scabbard over a blade from its guard to its tip, its end capped."""
    a, b = Vector(base), Vector(tip)
    d = (b - a).normalized()
    n = Vector((0, 1, 0))
    n = (n - d * n.dot(d)).normalized()
    s = d.cross(n).normalized()
    long_ = (b - a).length

    def ring(at, w, th):
        q = a + d * at
        return [q + n * th, q + s * w, q - n * th, q - s * w]

    start = grip + guard
    built.tube([ring(start, width * 0.62, thick / 2), ring(long_ - 0.2, width * 0.6, thick / 2), ring(long_ - 0.18, width * 0.64, thick * 0.55),
                ring(long_ + 0.02, width * 0.3, thick * 0.3)],
               lambda i, k: tone(colour if i < 2 else cap, 1.0 if k in (0, 3) else 0.7), caps=(tone(colour, 0.6), tone(cap, 0.7)), smooth=False)


def blades(grip, guard_, scabbard=None, cap=None):
    """The two short blades on her back, bare steel or in their scabbards."""
    b = am.Built("Blades")
    for base, tip in BACK.values():
        b.blade(base, tip, 0.24, (grip, guard_, "#E8ECF2", "#7B8395"), grip=0.46, thick=0.05, guard=0.07)
        if scabbard:
            sheath(b, base, tip, 0.24, scabbard, cap, 0.46, 0.07)
    return b


# Her scarf's long tail, from the knot back past her left shoulder and drifting down behind her: its line, its width
# at each point and its twist (degrees); the finish cuts it into the chain her clips move (kirra_make.py)
TAIL_LONG = [(-0.74, 0.04, 4.1), (-0.88, -0.42, 4.1), (-1.04, -0.86, 3.86), (-1.18, -1.3, 3.4), (-1.32, -1.72, 2.86),
             (-1.5, -2.2, 2.4), (-1.72, -2.72, 2.12), (-1.94, -3.25, 2.04), (-2.1, -3.72, 2.18)]
TAIL_WIDTH = (0.46, 0.36)
TAIL_TURN = [0, 10, 30, 55, 70, 62, 48, 58, 72]
KNOT = (-0.74, 0.05, 3.98)


def tail_shade(colour, ends):
    """The scarf's colour along a tail, `u` from the knot: its own, turning to `ends` over the last fifth."""
    return lambda u: mix(colour, ends, max(0.0, (u - 0.8) / 0.2))


def scarf(colour, ends, long_tail=True):
    """Her scarf: a turn round the neck, low at the front so it never hides the mouth; its knot at her left shoulder;
    and two tails from the knot back past the shoulder, the longer drifting behind her. `ends`: the tails' tips.
    Without `long_tail`, the turn, the knot and the short tail alone, as the finish builds them."""
    b = am.Built("Scarf")
    b.loop((0.0, 0.0, 3.86), 0.74, 0.3, colour, thick=0.17, segments=24, lean=lambda d: 0.11 + 0.26 * (abs(d) / 180) ** 0.8)
    b.loop(KNOT, 0.16, 0.3, tone(colour, 0.94), thick=0.16, segments=12, squash=0.8)
    shade_ = tail_shade(colour, ends)
    if long_tail:
        b.ribbon(TAIL_LONG, list(np.linspace(*TAIL_WIDTH, len(TAIL_LONG))), shade_, side=(1, 0, 0), thick=0.05, turn=TAIL_TURN)
    short = [(-0.7, 0.08, 4.04), (-0.82, -0.32, 3.94), (-0.96, -0.72, 3.6), (-1.1, -1.1, 3.1), (-1.2, -1.48, 2.66), (-1.24, -1.84, 2.38)]
    b.ribbon(short, list(np.linspace(0.38, 0.3, len(short))), shade_, side=(1, 0, 0.3), thick=0.05, turn=[0, 14, 34, 56, 66, 70])
    return b


def figure(joints, folder, b, head, hair, built):
    made = rt.figure(joints, folder, b, head, hair)
    for piece in built:
        made[piece.name] = piece.build(folder)
        wt.on(joints, "neck" if piece.name == "Tie" else "root", made[piece.name])   # the hair's tie rides the head
    return made


def bare_arm(a, skin, guard_colour, top, trim):
    """A bare arm with a guard from the hand to `top`, the hand's end in the guard's colour."""
    w = a.wrap
    w.lay(w.rect(-9, 0.0, 9, 2.0), skin)
    for p in a.sides:
        dark(p, p.soft(p.rect(-9, 1.86, 9, 2.0), 0.04), 0.12)
    guards(a, guard_colour, top, trim)
    shadow(a, 0.26, low=0.0)
    lit(a)
    a.faces["bottom"].px[:] = rgb(tone(guard_colour, 0.9))
    a.faces["top"].px[:] = rgb(skin)


# --- A, the night runner -----------------------------------------------------------------------------------------------

def take_a(joints, folder, pieces=None):
    """`pieces(scarf colour, its ends, the guards' colour)`: the built pieces, in place of the takes' (the finish's)."""
    skin, top_, guard_, trouser, teal = "#F2CDB2", "#26345F", "#1B1F2B", "#8F97AA", "#1FA39A"
    edge, trim = tone(top_, 0.5), mix(top_, "#8E9CC8", 0.4)
    b = blocks_of({"torso": top_, "rs": skin, "ls": skin, "rh": trouser, "lh": trouser})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the mock neck, a band right round its top
    band(w, 1.84, 2.0, trim, edge)
    # the top, fitted: a seam down each side of the front, folds pulled from the shoulders to the waist
    for s in (-1, 1):
        line(f, [(s * 0.42, 1.84), (s * 0.36, 1.2), (s * 0.4, 0.4)], 0.014, edge, 0.6)
        creases(f, [[(s * 0.95, 1.8), (s * 0.8, 1.6), (s * 0.64, 1.52)], [(s * 0.9, 0.8), (s * 0.74, 0.62), (s * 0.66, 0.42)]], 0.4)
    creases(back, [[(-0.9, 1.3), (-0.7, 1.0), (-0.6, 0.6)], [(0.9, 1.3), (0.7, 1.0), (0.6, 0.6)]], 0.4)
    # the sash, dark, its teal edge, and its knot at her left hip
    band(w, 0.0, 0.32, guard_, tone(teal, 0.8))
    f.lay(f.poly([(0.52, 0.3), (0.7, 0.32), (0.72, 0.04), (0.54, 0.02)]), tone(guard_, 1.5))
    # the strap that holds the blades: from her right shoulder across to her left hip, front and back
    strap(f, (-0.78, 1.84), (0.66, 0.32), guard_)
    strap(back, (0.78, 1.84), (-0.66, 0.32), guard_)
    f.lay(f.ellipse(-0.1, 1.06, 0.07, 0.07), "#A9B0BE")
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=21)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        bare_arm(a, skin, guard_, 1.0, teal)
        w = a.wrap   # a short sleeve with a teal edge
        w.lay(w.rect(-9, 1.5, 9, 2.0), top_)
        band(w, 1.5, 1.57, trim, edge)
        for p in a.sides:
            creases(p, [[(-0.42, 1.86), (-0.05, 1.76), (0.36, 1.82)]], 0.36)
            dark(p, p.soft(p.rect(-9, 1.42, 9, 1.5), 0.03), 0.2)
        a.faces["top"].px[:] = rgb(tone(top_, 1.2))

    for i, key in enumerate(("rh", "lh")):
        g = b[key]
        for p in g.sides:
            creases(p, [[(-0.4, 1.66), (-0.05, 1.54), (0.36, 1.6)], [(-0.36, 1.12), (0.0, 1.0), (0.38, 1.06)]], 0.24)
        shin_wraps(g, guard_, 0.28, 0.86, 0.1)
        shoe(g, guard_, "#3A3F4E", tone(guard_, 1.3), tall=0.28)
        band(g.wrap, 1.94, 2.0, guard_, None)
        shadow(g, 0.26, low=0.0)
        lit(g, 0.08)
        grain(g, seed=24 + i)

    head = am.Head(skin)
    face(head, dict(skin=skin, iris="#5BA6D6", eye_w=0.32, eye_h=0.19, eye_x=0.268, eye_y=0.52, tilt=0.03, shut=0.3,
                    brow_y=0.7, brow_tilt=0.03, brow="#7A8092", mouth=[(-0.045, 0.232), (0.0, 0.228), (0.045, 0.232)]))
    # on a scalp fitted to her head: on the kit's wide egg it stood off her head's sides and crown (the director,
    # 2026-11-27, "the hair being detached from the head", "from the sides and even abit top")
    hair = am.Hair("#848CA3", "#EEF1F7", seed=31, band=(0.5, 0.1, 0.3), scalp=am.HEAD_EGG)
    # One solid lit mass combed up to the tie behind the crown, its locks drawn as parted lines on it, never as
    # leaves whose edges and undersides catch the light (research's must-fix 1, then the director's "messy", 11:2x)
    TIE = (180, 24)
    # it lies down on her head's sides and back, down to the nape at the scarf, its edge tucked into the head, and
    # takes its volume over the crown (the director, 2026-11-27: "the hair is still not attached to kira head")
    hair.mass(am.hairline(front=4.98, temple=4.5, nape=4.04), TIE, opening=0.12, seed=31,
              tips=((180, 16, 5), (154, 12, 6), (206, 12, 6), (128, 14, 8), (232, 14, 8), (78, 20, 20), (-78, 20, 20)),
              lift=0.05, off=(0.0, 0.1), ease=2.0, tuck=0.09)
    # the side-swept fringe, from her right parting across to her left, four broad locks lying on her brow; the mass
    # hangs to a point before each ear
    for a, length, width, heading, bend in ((-34, 0.7, 0.46, 30, 10), (-12, 0.78, 0.5, 36, 14), (10, 0.72, 0.46, 40, 14), (30, 0.6, 0.4, 38, 8)):
        hair.clump(a, 30, length, width, heading=heading, bend=bend, off=0.03, flick=0, hold=0.95, k=1.02, thick=width * 0.26)
    # the high tail, one solid lock: from the tie, up, over and down her back, with two locks parting from its end;
    # the crown's own silver, a band of light where it turns over
    tie = hair.at(*TIE)[0] + hair.at(*TIE)[1] * 0.12
    spine = [tie + Vector(q) for q in ((0, 0.0, -0.02), (0.02, -0.3, 0.24), (0.04, -0.7, 0.26), (0.06, -1.0, -0.06), (0.1, -1.08, -0.72), (0.2, -0.98, -1.4))]
    hair.tail(spine, ((0, 0.13), (0.1, 0.2), (0.32, 0.27), (0.6, 0.24), (0.85, 0.13), (1.0, 0.0)), seed=33)
    for s_ in (-1, 1):
        hair.lock([tie + Vector(q) for q in ((0.08 + s_ * 0.06, -1.06, -0.46), (0.1 + s_ * 0.2, -1.04, -0.84), (0.12 + s_ * 0.3, -0.94, -1.2))],
                  0.3, thick=0.08, n=8, k=1.0)
    tail_tie = am.Built("Tie")
    tail_tie.loop(tie + Vector((0, -0.02, -0.02)), 0.15, 0.16, teal, thick=0.09, segments=12, squash=0.9,
                  lean=None)
    built = pieces(teal, "#8FD8CF", guard_) if pieces else [scarf(teal, "#8FD8CF"), blades(guard_, "#6E7686")]
    return figure(joints, folder, b, head, hair, [*built, tail_tie])


# --- B, the transfer student -------------------------------------------------------------------------------------------

def take_b(joints, folder):
    skin, cream, char, cobalt = "#F3D0B6", "#ECE3CE", "#2A2C33", "#2E5FCF"
    edge = tone(cream, 0.55)
    b = blocks_of({"torso": cream, "rs": cream, "ls": cream, "rh": char, "lh": char})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the charcoal top under the cropped jacket: its hem shows below the jacket's, and in the opening
    w.lay(w.rect(-9, 0.0, 9, 0.5), char)
    f.lay(f.poly([(-0.22, 2.0), (0.22, 2.0), (0.18, 0.5), (-0.18, 0.5)]), char)
    creases(f, [[(-0.1, 1.5), (-0.14, 1.1), (-0.1, 0.7)]], 0.3)
    w.lay(w.rect(-9, 0.48, 9, 0.52), tone(cream, 0.6))
    # the jacket: a standing collar, its two front edges, a seam over each shoulder, folds from the arms' pits
    for s in (-1, 1):
        f.lay(f.poly([(s * 0.22, 2.0), (s * 0.3, 2.0), (s * 0.27, 0.5), (s * 0.18, 0.5)]), tone(cream, 0.9))
        line(f, [(s * 0.22, 2.0), (s * 0.18, 0.5)], 0.02, edge)
        creases(f, [[(s * 0.98, 1.7), (s * 0.78, 1.56), (s * 0.5, 1.5)], [(s * 0.96, 1.1), (s * 0.74, 0.92), (s * 0.6, 0.6)]], 0.36)
        f.lay(f.ellipse(s * 0.34, 0.66, 0.035, 0.035), tone(cream, 0.6))
    band(w, 1.82, 2.0, tone(cream, 0.94), edge)
    w.lay(w.rect(-0.22, 1.82, 0.22, 2.0), char)
    line(back, [(0.0, 1.82), (0.01, 1.2), (0.0, 0.52)], 0.016, edge, 0.6)
    creases(back, [[(-0.9, 1.3), (-0.66, 1.06), (-0.5, 0.7)], [(0.9, 1.3), (0.66, 1.06), (0.5, 0.7)]], 0.36)
    strap(back, (0.78, 1.82), (-0.66, 0.52), char, 0.09)
    shadow(t, 0.28)
    lit(t)
    grain(t, seed=41)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        w = a.wrap
        w.lay(w.rect(-9, 0.0, 9, 0.26), skin)
        band(w, 0.26, 0.46, tone(cream, 0.9), edge)   # the cuff, turned back once
        for p in a.sides:
            creases(p, [[(-0.42, 1.56), (-0.05, 1.44), (0.36, 1.5)], [(-0.3, 0.8), (0.1, 0.72), (0.4, 0.78)]], 0.22)
        shadow(a, 0.28, low=0.0)
        lit(a)
        grain(a, seed=42 + i)
        a.faces["top"].px[:] = rgb(tone(cream, 1.02))
        a.faces["bottom"].px[:] = rgb(skin)

    for i, key in enumerate(("rh", "lh")):
        g = b[key]
        w = g.wrap
        for p in g.sides:
            creases(p, [[(-0.4, 1.6), (-0.05, 1.5), (0.36, 1.56)]], 0.3)
            light(p, p.soft(p.rect(-0.2, 1.0, 0.16, 1.8), 0.08), 0.06)
        # tall boots to the knee, a turned top and a pale sole
        boot = "#1C1D23"
        w.lay(w.rect(-9, 0.0, 9, 0.9), boot)
        band(w, 0.84, 0.94, tone(boot, 1.6), tone(boot, 0.5))
        w.lay(w.rect(-9, 0.0, 9, 0.06), cream)
        for p in g.sides:
            creases(p, [[(-0.4, 0.5), (0.0, 0.44), (0.4, 0.5)]], 0.3, 0.02)
        g.faces["bottom"].px[:] = rgb(cream)
        shadow(g, 0.26, low=0.0)
        grain(g, seed=44 + i)

    head = am.Head(skin)
    face(head, dict(skin=skin, iris="#D9A23A", eye_w=0.33, eye_h=0.21, eye_x=0.27, eye_y=0.52, tilt=0.012, shut=0.12,
                    brow_y=0.73, brow_tilt=0.0, brow="#173A42", mouth=[(-0.04, 0.236), (0.0, 0.232), (0.04, 0.236)]))
    hair = am.Hair("#0C252D", "#3F8E98", seed=51, band=(0.5, 0.12, 0.5))
    hair.shell(am.hairline(front=5.0, temple=4.56, nape=4.1))
    # the bob: the back and sides hang straight down the head to the jaw, their ends turned in
    hair.row(8, 96, (110, 250), 0.6, 0.38, off=0.03, flick=-10, hold=0.9, jitter=0.15)
    hair.row(10, 66, (82, 278), 0.86, 0.44, off=0.06, flick=-12, hold=0.9, jitter=0.15)
    hair.row(9, 36, (70, 290), 0.96, 0.48, off=0.1, flick=-8, hold=0.9, jitter=0.15)
    for s in (-1, 1):
        hair.row(3, 46, (s * 52, s * 90), 0.92, 0.44, off=0.08, flick=-10, hold=0.9, jitter=0.12, comb=(0, 0.15, -1))
    hair.row(7, 12, (-180, 180), 0.78, 0.52, off=0.14, flick=10, hold=0.8, jitter=0.15)
    # the fringe, near blunt, to the brows
    for a, length in ((-44, 0.56), (-26, 0.62), (-8, 0.66), (10, 0.64), (28, 0.6), (44, 0.54)):
        hair.clump(a, 34, length, 0.34, heading=0, off=0.08, flick=4, hold=0.88, comb=(0, 0.6, -1), split=0)
    # one lock that stands up from the crown
    hair.lock([(0.02, -0.05, 5.3), (0.04, 0.05, 5.62), (0.12, 0.2, 5.8), (0.26, 0.32, 5.78)], 0.16, n=8)
    return figure(joints, folder, b, head, hair, [scarf(cobalt, "#9BB7F2"), blades(char, "#6E7686", char, cobalt)])


# --- C, the drifter ----------------------------------------------------------------------------------------------------

def take_c(joints, folder):
    skin, white, navy, sky = "#F4D2B8", "#EEE9DD", "#22305A", "#4FA3E8"
    edge = tone(white, 0.55)
    b = blocks_of({"torso": white, "rs": white, "ls": white, "rh": navy, "lh": navy})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the wrap top, her left side over her right, a navy under-collar in the V
    f.lay(f.poly([(-0.26, 2.0), (0.26, 2.0), (0.0, 1.5)]), navy)
    f.lay(f.ellipse(0.0, 2.02, 0.17, 0.14), skin)
    f.lay(f.poly([(0.26, 2.0), (0.44, 2.0), (-0.42, 0.34), (-0.62, 0.34)]), tone(white, 0.93))
    line(f, [(0.26, 2.0), (-0.62, 0.34)], 0.022, edge)
    line(f, [(0.44, 2.0), (-0.42, 0.34)], 0.014, edge, 0.7)
    line(f, [(-0.26, 2.0), (0.0, 1.5)], 0.018, edge, 0.8)
    creases(f, [[(0.95, 1.6), (0.74, 1.44), (0.52, 1.46)], [(-0.95, 1.6), (-0.76, 1.42), (-0.58, 1.36)], [(0.9, 0.9), (0.7, 0.66), (0.5, 0.58)],
                [(-0.2, 1.2), (-0.3, 0.9), (-0.26, 0.6)]], 0.34)
    band(w, 1.86, 2.0, white, edge)
    # the sash, wide and navy, a sky-blue cord round it tied at her right hip
    band(w, 0.0, 0.4, navy, tone(navy, 0.5))
    w.lay(w.rect(-9, 0.18, 9, 0.22), sky)
    f.lay(f.poly([(-0.56, 0.22), (-0.48, 0.24), (-0.4, -0.1), (-0.5, -0.1)]), sky)
    creases(back, [[(-0.9, 1.4), (-0.66, 1.12), (-0.5, 0.74)], [(0.9, 1.4), (0.66, 1.12), (0.5, 0.74)], [(-0.3, 1.0), (0.0, 0.92), (0.3, 1.0)]], 0.34)
    strap(back, (0.78, 1.86), (-0.66, 0.4), navy, 0.09)
    shadow(t, 0.28)
    lit(t)
    grain(t, seed=61)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        w = a.wrap
        # the sleeve to the elbow, wide; the forearm in a navy guard
        w.lay(w.rect(-9, 0.0, 9, 1.0), skin)
        guards(a, navy, 0.96, sky)
        band(w, 1.0, 1.1, tone(white, 0.9), edge)
        for p in a.sides:
            creases(p, [[(-0.42, 1.7), (-0.05, 1.56), (0.36, 1.62)], [(-0.4, 1.32), (0.0, 1.2), (0.38, 1.26)]], 0.34)
            dark(p, p.soft(p.rect(-9, 0.96, 9, 1.0), 0.03), 0.25)
        shadow(a, 0.28, low=0.0)
        lit(a)
        grain(a, seed=62 + i)
        a.faces["bottom"].px[:] = rgb(tone(navy, 0.9))
        a.faces["top"].px[:] = rgb(white)

    for i, key in enumerate(("rh", "lh")):
        g = b[key]
        for p in g.sides:
            creases(p, [[(-0.44, 1.6), (-0.1, 1.44), (0.36, 1.52)], [(-0.4, 1.0), (0.0, 0.86), (0.4, 0.94)], [(-0.3, 0.7), (0.04, 0.6), (0.36, 0.66)]], 0.42)
        band(g.wrap, 1.6, 2.0, navy, None)
        shin_wraps(g, white, 0.24, 0.56, 0.09)
        shoe(g, "#1C1D23", "#3A3F4E", "#2A2C33", tall=0.24)
        shadow(g, 0.28, low=0.0)
        lit(g, 0.08)
        grain(g, seed=64 + i)

    head = am.Head(skin)
    face(head, dict(skin=skin, iris="#4F9BE6", eye_w=0.34, eye_h=0.22, eye_x=0.27, eye_y=0.52, tilt=0.008, shut=0.04,
                    brow_y=0.75, brow_tilt=-0.01, brow="#8A6028", mouth=[(-0.06, 0.244), (0.0, 0.228), (0.06, 0.244)]))
    hair = am.Hair("#B08540", "#F8E3A6", seed=71, band=(0.5, 0.12, 0.4))
    hair.shell(am.hairline(front=4.98, temple=4.58, nape=4.2))
    hair.scalp = hair.colour(0.4) * 0.8
    # parted in the middle, combed down to the ties at each side of the crown
    for s in (-1, 1):
        side = (s * -1.0, -0.3, 0.5)
        hair.row(5, 90, (s * 100, s * 170), 0.56, 0.36, off=0.03, flick=8, hold=0.85, jitter=0.15, comb=side)
        hair.row(5, 58, (s * 60, s * 170), 0.7, 0.42, off=0.07, flick=10, hold=0.8, jitter=0.15, comb=side)
        hair.row(4, 24, (s * 20, s * 175), 0.74, 0.46, off=0.09, flick=14, hold=0.8, jitter=0.15, comb=(s * -1.0, 0, 0.2), thick=0.07)
        # the fringe parted from the middle, and a lock before each ear
        hair.clump(s * 12, 34, 0.62, 0.36, heading=-s * 20, bend=-s * 10, off=0.08, flick=10, hold=0.8, split=1)
        hair.clump(s * 34, 36, 0.64, 0.34, heading=-s * 12, off=0.07, flick=8, hold=0.82)
        hair.clump(s * 74, 56, 0.86, 0.28, heading=-s * 4, off=0.05, flick=6, hold=0.9, comb=(0, 0.2, -1))
    hair.row(5, 8, (-180, 180), 0.6, 0.44, off=0.12, flick=22, hold=0.6, jitter=0.2, thick=0.08)
    # the two tails, tied high at the sides of the crown: up and out, then down behind her shoulders
    ties = am.Built("Ties")
    for s in (-1, 1):
        tie = Vector((s * 0.6, -0.22, 5.12))
        for dy, lift, drop, width, k in ((0.0, 0.0, 0.0, 0.68, 1.0), (-0.14, -0.06, 0.22, 0.52, 0.94), (0.12, -0.03, 0.18, 0.52, 1.04),
                                          (-0.06, 0.04, 0.4, 0.46, 0.9), (0.06, -0.08, 0.5, 0.44, 1.0), (0.0, -0.1, 0.7, 0.38, 1.05),
                                          (-0.16, -0.12, 0.85, 0.32, 0.92)):
            pts = [tie + Vector(q) for q in ((0, 0, 0), (s * 0.24, dy - 0.04, 0.34 + lift), (s * 0.56, dy - 0.14, 0.4 + lift),
                                             (s * 0.82, dy - 0.38, -0.02), (s * 0.86, dy - 0.56, -0.7 + drop * 0.4), (s * 0.74, dy - 0.62, -1.5 + drop))]
            hair.lock(pts, width, n=12, k=k)
        ties.loop(tie + Vector((s * 0.03, 0, -0.08)), 0.12, 0.16, sky, thick=0.09, segments=12)
    return figure(joints, folder, b, head, hair, [scarf(sky, "#C2E2FA"), blades(navy, "#6E7686", navy, sky), ties])


TAKES = {"Rook": rt.take_a, "A": take_a, "B": take_b, "C": take_c}


def measured(key, made):
    """The hair's top over the crown, in heads (AR60: 0.45 to 0.6), and each built piece's triangles."""
    hair = made["hair"]
    top = max(v.co.z for v in hair.data.vertices)
    print(f"{key}: the hair stands {(top - CROWN) / 1.25:.2f} of a head over the crown (top {top:.2f})")
    for name, o in made.items():
        if name not in ("torso", "rs", "ls", "rh", "lh", "head", "hair"):
            print(f"{key}: {name} {sum(len(f.vertices) - 2 for f in o.data.polygons)} triangles")


if __name__ == "__main__":
    rt.TAKES, rt.SAID = TAKES, SAID
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "sheet"
    if mode == "takes":
        rt.takes_run(OUT, rest[1:] or list(TAKES), finish=measured)
    elif mode == "shade":
        rt.shade_run(OUT)
    elif mode == "sheet":
        rt.sheet_run(OUT, WORDS, BESIDE)
    elif mode == "proof":
        key = rest[1] if rest[1:] else "A"
        rt.proof_run(OUT, key, title=f"AR60: KIRRA, THE PICK ({SAID[key][0].upper()})", about="Common / Blue / Assassin / Void.",
                     whose="her", stem="kirra_pick", beside=list(BESIDE), tag="AR60: the pick")
