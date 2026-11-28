"""Pip's make, redone from targets (docs/requests/AR63.md, research's verdict at the director's bar, 2026-11-28, 00:49):
the finished Pip read as a storybook child beside Anime Vanguards' units (the cone hat, the freckles, the open grin),
his cream, green and brown flat with pale folds, his hair not sculpted. Three takes, each a young mage as stylish as
Rook: deep darks held beside lights, folds shaped from the shoulders and the waist, hair in sculpted locks that cast
on his head. His role stays (Common, a Mage, Fire: the Apprentice, sleeves past his hands) and so does his lantern,
the finished one (pip_make.lamp), lit through its panes; the hat, the palette, the hair and the age are open.

    A, the ember scholar: no hat; copper hair swept from a part at his right across his brow, its points turned out;
       a long charcoal high-collared coat closed off the middle with ember frogs, its tails to the knee, open over
       warm dark trousers; ember lining at its edges and cuffs; tall boots.
    B, the wide brim: the hat too big, made a wanderer's: a wide flat brim and a low crown, charcoal, a gold band,
       tilted; dark hair with ember ends spilling under it, a short tail at the nape; a cream capelet with a gold edge
       over a wine tunic; wine sleeves past his hands, cream cuffs.
    C, the high collar: pale gold hair, a long fringe over one eye; a cropped brick-ember jacket with a tall collar
       standing round his jaw, ivory inside, open over a black fitted top; brick sleeves past his hands, black cuffs;
       black trousers, ivory shin wraps, brown boots.

Each is drawn by rook_make_takes.py's pictures and sheet, today's Pip (pip_make.py's finish) in the first place, square
on between the same two Anime Vanguards units (internal: build/reference/takes/pip_redo_beside.png).

    blender.exe -b --factory-startup --python tools/blender/pip_redo_takes.py -- <out_dir> takes [Pip A B C]
    blender.exe -b --factory-startup --python tools/blender/pip_redo_takes.py -- <out_dir> shade|sheet|proof
    blender.exe -b --factory-startup --python tools/blender/pip_redo_takes.py -- <out_dir> model|modelsheet

`F` is C's finish (finish_c), with research's must-fixes; `proof` lays it alone as a finish is judged. `model` writes
its install's files to <out_dir>/handoff (pip_make.finish: no hat, the collar welded to the torso), and the model
pip_clips.py reads (PIP_MODEL=<out_dir>/handoff/model); `modelsheet` lays pip_make_sheet.png from them.
"""
import math
import sys
from pathlib import Path

import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import pip_make as pm  # noqa: E402
import pip_make_takes as pt  # noqa: E402
import rook_make_takes as rt  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402
from anime_make import cel, mix, rgb, tone  # noqa: E402
from rook_make_takes import band, blocks_of, creases, dark, grain, line, lit, neck, shadow, shoe  # noqa: E402

BESIDE = kt.BESIDE
SAID = {
    "Pip": ("Today's Pip", ("AR63's finish, in the game now:", "the storybook first-year research failed")),
    "A": ("A, the ember scholar", ("no hat: copper hair swept across from a part", "a long charcoal coat, ember frogs and lining",
                                   "its tails to the knee, warm dark trousers", "sleeves past his hands, tall boots")),
    "B": ("B, the wide brim", ("a wanderer's hat, wide and flat, tilted", "dark hair with ember ends, a short tail",
                               "a cream capelet over a wine tunic", "wine sleeves past his hands")),
    "C": ("C, the high collar", ("pale gold hair, a long fringe over one eye", "a cropped brick jacket, its collar standing",
                                 "round his jaw, over a black fitted top", "black trousers, ivory shin wraps")),
    "F": ("C, the finish", ("a deeper gold, dark at the roots; a warmer skin", "the fringe cast on his face, the collar dark inside",
                            "more locks, narrower and sharper, parted", "folds painted per garment, a wider range")),
}
WORDS = dict(
    stem="pip_redo",
    beside="AR63's redo: Pip's three takes square on, between the same two Anime Vanguards units at the same height. Internal: "
           "the two are reference.",
    title="AR63: PIP REDONE, THREE TAKES",
    about="Common / Purple / Mage / Fire: the Apprentice, a young mage, sleeves past his hands, his fire in the lantern that floats "
          "beside him. Redone from research's verdict of 00:49 (a storybook child beside AV's units; flat values; hair not sculpted): "
          "each take a young adult, deep darks beside lights, folds pulled from the shoulders and the waist, hair in sculpted locks "
          "that cast on his head. The make is AR59's; the lantern is the finished one, lit through its panes. Each stands as in the "
          "game: from the three-quarter front, then from the game's camera behind his right shoulder, today's Pip first. "
          "Research picks one.",
    row="today's Pip, A, B, C and a Brawler",
)


# --- the finish every take shares --------------------------------------------------------------------------------------

def figure(joints, folder, b, head, hair, built, skin, extra_hair=(), cast=None, drop=0.045, cast_alpha=0.8):
    """The blocks, head and hair (rook_make_takes.figure), the built pieces on their joints (a hat, a tie or a
    collar's part that turns with the head on the neck), the hair cast on his head (`cast`, `drop` under it), and
    the lantern lit."""
    made = rt.figure(joints, folder, b, head, hair)
    for h in extra_hair:
        obj = h.build(folder, name="Hair2")
        made["Hair2"] = obj
        wt.on(joints, "neck", obj)
    for piece in built:
        made[piece.name] = piece.build(folder)
        wt.on(joints, "neck" if piece.name in ("Hat", "Tie") else "root", made[piece.name])
    pt.outward(made.get("Hat"))
    pm.hair_shadow(made, mix(skin, "#8C4A3C", 0.45) if cast is None else cast, drop=drop, alpha=cast_alpha)
    obj = made["Lamp"]
    path = folder / "Lamp_glow.png"
    mask = am.GLOWS[obj.name]
    rs.save(np.dstack([mask, mask, mask, np.ones_like(mask)]), path)
    pm.emit(obj.active_material, path, pm.COLD)
    return made


def face(head, skin, iris, brow):
    """His own face (pip_make's `face_set`: a level lid low over a round iris, a heavy lash with a flick, thick
    straight brows, a pressed mouth): a young man's, never the storybook grin."""
    pm.face_set(head.paint, skin, iris=iris, brow=brow)


def tops(b, torso, arm=None):
    """The blocks' tops as the game's camera sees them from behind and above: the clothes' own colour."""
    b["torso"].faces["top"].px[:] = rgb(tone(torso, 1.08))
    for key in ("rs", "ls"):
        b[key].faces["top"].px[:] = rgb(tone(arm or torso, 1.08))


def sleeves(a, cloth, cuff, piping=None, seed=1):
    """A sleeve past the hand, its cuff turned back, a piping line over the cuff and a seam at the shoulder. Its folds
    are shaped, as AV's are: one pulled down from the shoulder, one bunched at the elbow the other way, one where the
    cuff gathers; never pip_make_takes.long_sleeves' three level folds, which read as a ripple pattern."""
    w = a.wrap
    w.lay(w.rect(-9, 0.0, 9, 2.0), cloth)
    band(w, 0.0, 0.26, cuff, tone(cuff, 0.5))
    for p in a.sides:
        creases(p, [[(-0.44, 1.66), (-0.18, 1.44), (0.1, 1.4)], [(0.42, 1.06), (0.16, 0.9), (-0.16, 0.94)],
                    [(-0.4, 0.5), (-0.12, 0.4), (0.14, 0.44)]], 0.42)
        dark(p, p.soft(p.rect(-9, 0.26, 9, 0.3), 0.02), 0.25)
    if piping is not None:
        w.lay(w.rect(-9, 0.26, 9, 0.3), piping)
    w.lay(w.rect(-9, 1.8, 9, 1.815), tone(cloth, 0.5), 0.8)
    shadow(a, 0.28, low=0.0)
    lit(a)
    a.faces["bottom"].px[:] = rgb(tone(cloth, 0.25))
    a.faces["top"].px[:] = rgb(cloth)
    grain(a, seed=seed)


def boots(g, colour, top, strap=None):
    """A tall boot to `top`, its sole, a turned top and a strap under it."""
    shoe(g, colour, "#1E1916", tone(colour, 1.3), tall=top)
    band(g.wrap, top - 0.06, top, tone(colour, 1.2), tone(colour, 0.5))
    if strap is not None:
        band(g.wrap, top - 0.24, top - 0.17, strap, tone(strap, 0.5))
        f = g.faces["front"]
        f.lay(f.rect(-0.07, top - 0.25, 0.07, top - 0.16), "#C9A15A")


# --- the hats and the collar ---------------------------------------------------------------------------------------

def wide_hat(base, r_in, brim, crown, height, colour, band_, pitch=-5.0, roll=7.0, n=32):
    """A wanderer's hat: a wide flat brim with a slight droop and a soft wave at its edge, a low crown narrowing a
    little to its top, a dent pinched into the top, a band round its foot. Tilted `pitch` (below zero, the front down)
    and `roll` about its opening's middle."""
    b = am.Built("Hat")
    c = Vector(base)
    shade = pt.lit_round(colour, n, low=0.62, high=1.18)
    wave = lambda a: 0.025 * math.sin(2 * a + 0.4)  # noqa: E731
    rings = [pt.ring(c, r_in, c.z - 0.02, n),                         # under the brim, at the head
             pt.ring(c, brim, c.z - 0.09, n, wave),                   # the brim's edge, drooping
             pt.ring(c, brim, c.z - 0.05, n, wave),                   # its top edge
             pt.ring(c, crown + 0.03, c.z + 0.02, n),                 # the brim's top at the crown
             pt.ring(c, crown, c.z + 0.03, n),
             pt.ring(c, crown, c.z + 0.17, n),                        # the band
             pt.ring(c, crown * 0.97, c.z + 0.19, n)]
    for f in (0.45, 0.8, 1.0):
        rings.append(pt.ring(c, crown * (0.97 - 0.08 * f), c.z + 0.19 + (height - 0.19) * f, n))
    rings.append(pt.ring(c, crown * 0.62, c.z + height - 0.02, n, lambda a: 0.12 * math.cos(a)))   # the dent's rim, pinched
    rings.append(pt.ring(c, crown * 0.2, c.z + height - 0.09, n))
    rings.append(pt.ring(c, 0.0, c.z + height - 0.1, n))

    def colours(i, k):
        if i == 0:
            return tone(colour, 0.4)
        if i == 1:
            return tone(colour, 0.55)
        if i == 2:
            return shade(k)
        if i == 3:
            return tone(colour, 0.7)
        if i in (4, 5):
            return pt.lit_round(band_, n)(k)
        if i >= 9:
            return tone(shade(k), 0.8)
        return shade(k)

    b.tube(rings, colours, caps=(tone(colour, 0.3), None), smooth=True)
    turn = Matrix.Rotation(math.radians(roll), 3, "Y") @ Matrix.Rotation(math.radians(pitch), 3, "X")
    for v in b.bm.verts:
        v.co = c + turn @ (v.co - c)
    return b


def standing_collar(colour, inside, edge):
    """A tall collar standing round his jaw from the jacket's neck, open at the front: low there, highest at the back.
    On the torso: it does not turn with his head.
    - It is round and clears the head all the way round, so the head turns inside it. Squashed front to back (0.86),
      its front wall stood on the head's own surface (0.625), and the head showed through it under his mouth (the
      director, 2026-11-28). Its inside is 0.69 from his middle, the head 0.625. Its front is low (0.06), so his
      mouth stays clear.
    - It is cloth, not a drum (research, 2026-11-28: from behind, "a hard drum with straight sides, plastic"):
      - its top is a round roll turned out past the wall, with a shadow line under it;
      - its wall bows in under the roll and flares at its foot;
      - one crease, at his back on his right where the game's camera sees it under his hair, from the roll to the
        foot, deepest at the top: shaded by its own shape, as painted tones stepped into stairs up close (its rows
        are closer there: 2.5 degrees, 7.5 elsewhere);
      - where it stands out past his back, its foot settles down onto the back and never floats over it.
    Its inside is `inside`, its outside `colour`: six tones, painted as the light falls."""
    b = am.Built("Collar")
    z0, r0 = 3.98, 0.69
    fold = 157.5   # degrees round from his front, on his right
    angles = sorted({i * 7.5 for i in range(48)} | {135 + j * 2.5 for j in range(18)})
    segments = len(angles)

    def height(deg):
        return 0.06 + 0.52 * min(1.0, abs(deg) / 130) ** 1.2

    def crease(deg):   # 1 on the fold, 0 from 12 degrees either side
        off = abs(deg - fold)
        return 0.5 + 0.5 * math.cos(math.pi * off / 12) if off < 12 else 0.0

    def section(deg):
        """The profile at `deg`, as (out from r0, up from z0): from the inside's foot up the inside, round the roll, down
        the outside to its foot."""
        h = height(deg)
        roll = min(0.055, 0.3 * h)
        cx, cz = 0.01 + roll, h - roll
        arc = [(cx + roll * math.cos(math.radians(t)), cz + roll * math.sin(math.radians(t)))
               for t in (135, 90, 45, 0, -45, -85)]
        wall = cx + 0.4 * roll   # under the roll: it stands 0.6 of the roll's size out past this
        return [(0.0, 0.0), (0.004, 0.55 * cz), (0.01, cz), *arc, (wall, 0.75 * cz), (wall + 0.014, 0.42 * cz),
                (wall + 0.07, 0.0)]

    rings = []
    for i in range(segments):
        ang = math.radians(angles[i])
        deg = math.degrees(ang) if ang <= math.pi else math.degrees(ang) - 360
        h, w = height(deg), crease(deg)
        out = Vector((math.sin(ang), math.cos(ang), 0.0))
        ring = []
        for k, (dr, up) in enumerate(section(deg)):
            t = min(1.0, max(0.0, (up / h - 0.15) / 0.65))
            pull = w * (0.03 + 0.05 * t * t * (3 - 2 * t)) * (0.6 if k < 3 else 1.0)
            ring.append(Vector((0, 0, z0 + up * (1 - 0.05 * w))) + out * (r0 + dr - pull))
        # the foot's last point: tucked into the jacket, or, where the foot stands out past his back, settled down onto it
        foot = ring[-1]
        excess = max(0.0, -foot.y - 0.5)
        inward = 0.06 + (excess / max(0.2, -out.y) if excess else 0.0)
        ring.append(Vector((0, 0, z0 - min(0.3, 0.85 * excess))) + out * (foot.xy.length - inward))
        rings.append([b.bm.verts.new(tuple(v)) for v in ring])
    t_in, t_top, t_out, t_under, t_wall, t_close = (
        tone(inside, 0.9), tone(colour, 1.24), tone(colour, 1.08), tone(colour, 0.66), tone(colour, 0.95),
        tone(colour, 0.55))
    parts = [t_in, t_in, t_in, t_top, t_top, t_out, t_out, t_under, t_wall, t_wall, t_wall]
    for i in range(segments):
        a_, b_ = rings[i], rings[(i + 1) % segments]
        for k, c in enumerate(parts):
            b.face((a_[k], b_[k], b_[k + 1], a_[k + 1]), c)
        settled = a_[-1].co.z < z0 - 0.01 or b_[-1].co.z < z0 - 0.01
        b.face((a_[-2], b_[-2], b_[-1], a_[-1]), t_under if settled else t_close)
        b.face((a_[-1], b_[-1], b_[0], a_[0]), t_close)
    return b


# --- A, the ember scholar ----------------------------------------------------------------------------------------------

def take_a(joints, folder):
    skin, coat, shirt, ember, trouser, boot, gold = "#F2CFB4", "#24252D", "#EFE8DA", "#E2622B", "#3A3532", "#2E2420", "#D9A441"
    edge, lining = tone(coat, 0.45), tone(ember, 0.86)
    hem = 0.92            # on the legs: the coat's tails to the knee
    b = blocks_of({"torso": coat, "rs": coat, "ls": coat, "rh": trouser, "lh": trouser})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the ivory shirt's collar at the throat, in the coat's V
    f.lay(f.poly([(-0.2, 2.0), (0.2, 2.0), (0.0, 1.7)]), shirt)
    line(f, [(-0.2, 2.0), (0.0, 1.7), (0.2, 2.0)], 0.02, tone(shirt, 0.6))
    # the stand collar, charcoal, an ember line inside its top
    for s in (-1, 1):
        f.lay(f.poly([(s * 0.2, 2.0), (s * 0.46, 2.0), (s * 0.3, 1.78), (s * 0.08, 1.8)]), tone(coat, 1.25))
        line(f, [(s * 0.2, 2.0), (s * 0.04, 1.76)], 0.02, ember, 1.0)
    band(w, 1.9, 2.0, tone(coat, 1.25), None)
    w.lay(w.rect(0.46, 1.985, 9, 2.0), ember)
    w.lay(w.rect(-9, 1.985, -0.46, 2.0), ember)
    # closed off the middle toward his left: the front's edge from the V down to his left hip, piped in ember, the
    # overlap a tone lit, three frogs across it
    close = [(0.04, 1.74), (0.22, 1.2), (0.3, 0.6), (0.32, 0.0)]
    f.lay(f.poly([(0.04, 1.74), (0.22, 1.2), (0.3, 0.6), (0.32, 0.0), (-0.2, 0.0), (-0.2, 1.74)]), tone(coat, 1.1))
    line(f, close, 0.04, ember, 1.0)
    line(f, [(x + 0.03, y) for x, y in close], 0.016, edge, 0.9)
    for y in (1.46, 1.04, 0.66):
        x = float(np.interp(-y, [-1.74, -1.2, -0.6, 0.0], [0.04, 0.22, 0.3, 0.32]))
        line(f, [(x - 0.14, y), (x + 0.14, y)], 0.05, gold, 1.0)
        f.lay(f.ellipse(x + 0.16, y, 0.035, 0.035), gold)
        line(f, [(x - 0.14, y - 0.02), (x + 0.14, y - 0.02)], 0.012, tone(gold, 0.45), 0.9)
    # pulled from each shoulder to the closure, from the arms' pits, and gathered over the belt
    creases(f, [[(-0.98, 1.84), (-0.8, 1.62), (-0.5, 1.5)], [(0.98, 1.84), (0.82, 1.62), (0.5, 1.46)],
                [(-0.98, 1.2), (-0.84, 1.04), (-0.62, 1.0)], [(0.6, 0.56), (0.76, 0.48), (0.94, 0.54)]], 0.38)
    # the belt, dark leather, its buckle; the coat flares below it
    band(w, 0.2, 0.36, "#3A2A22", "#1C1512")
    f.lay(f.rect(-0.44, 0.21, -0.26, 0.35), gold)
    f.lay(f.rect(-0.4, 0.245, -0.3, 0.315), "#3A2A22")
    # the back: its seam, a yoke, a vent's top under the belt, the cloth pulled from the arms' pits
    line(back, [(0.0, 1.64), (0.01, 0.9), (0.0, 0.36)], 0.016, edge, 0.7)
    line(back, [(-1.0, 1.56), (-0.4, 1.62), (0.4, 1.62), (1.0, 1.56)], 0.014, edge, 0.7)
    creases(back, [[(-0.98, 1.24), (-0.72, 1.0), (-0.56, 0.6)], [(0.98, 1.24), (0.72, 1.0), (0.56, 0.6)],
                   [(-0.4, 0.56), (-0.1, 0.46), (0.2, 0.52)]], 0.5)
    back.lay(back.rect(-0.04, 0.0, 0.04, 0.2), lining)
    shadow(t, 0.32)
    lit(t)
    grain(t, seed=81)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        sleeves(b[key], coat, lining, piping=gold, seed=82 + i)
    tops(b, coat)

    for i, (key, s) in enumerate((("rh", -1), ("lh", 1))):   # s: the outer side on the leg's front picture
        g = b[key]
        w, f, bk = g.wrap, g.faces["front"], g.faces["back"]
        for p in g.sides:
            creases(p, [[(-0.4, 0.86), (-0.06, 0.76), (0.34, 0.82)]], 0.34)
        boots(g, boot, 0.62, strap="#4A3A30")
        # the coat's tails to the knee, round the leg's outer side and back; open at the front, where only its edge
        # shows at the leg's outer side, ember-lined, the trousers between
        w.lay(w.rect(-9, hem, 9, 2.0), coat)
        w.lay(w.rect(-9, hem - 0.03, 9, hem), lining)
        w.lay(w.rect(-9, hem, 9, hem + 0.014), edge)
        f.lay(f.poly([(-s * 0.5, 2.0), (s * 0.3, 2.0), (s * 0.22, hem), (-s * 0.5, hem)]), trouser)
        f.lay(f.poly([(s * 0.3, 2.0), (s * 0.38, 2.0), (s * 0.3, hem), (s * 0.22, hem)]), lining)
        line(f, [(s * 0.38, 2.0), (s * 0.3, hem)], 0.018, edge, 0.9)
        creases(f, [[(-0.3, 1.62), (0.0, 1.52), (0.24, 1.58)], [(-0.26, 1.16), (0.02, 1.06), (0.2, 1.12)]], 0.3)
        for p in (g.faces["right"], g.faces["left"], bk):
            creases(p, [[(-0.4, 1.74), (-0.1, 1.64), (0.3, 1.7)]], 0.36)
        creases(bk, [[(s * 0.4, 1.9), (s * 0.3, 1.5), (s * 0.36, 1.06)]], 0.4)
        if i == 0:   # the vent: the back's middle seam opens below the belt
            bk.lay(bk.rect(0.44, hem, 0.5, 1.6), tone(coat, 0.5))
        shadow(g, 0.3, low=0.0)
        lit(g, 0.08)
        grain(g, seed=84 + i)

    head = am.Head(skin)
    face(head, skin, "#E58A2C", "#6E2A14")
    hair = am.Hair("#6A2410", "#F39A58", seed=87, band=(0.5, 0.12, 0.5), scalp=am.HEAD_EGG)
    # one mass lying on his head from its edge up to a whorl behind the crown, its rim tucked in (AR60's fit), points
    # at the nape and before the ears; on it a few broad sculpted locks, each lying on the one below
    hair.mass(am.hairline(front=4.98, temple=4.5, nape=4.04), (190, 16), opening=0.1, seed=87,
              tips=((180, 16, 8), (150, 12, 8), (210, 12, 8), (124, 12, 10), (236, 12, 10), (80, 18, 16), (-80, 18, 16)),
              lift=0.05, off=(0.0, 0.1), ease=2.0, tuck=0.09)
    # the crown's locks, combed back from the front over the top, their points turned up off the back of the crown
    for a, ph, length, width, heading in ((-60, 16, 0.92, 0.52, 10), (-24, 12, 1.0, 0.56, 4), (14, 12, 0.98, 0.56, -4),
                                          (50, 16, 0.9, 0.5, -10)):
        hair.clump(a, ph, length, width, heading=heading, off=0.1, flick=34, hold=0.62, comb=(0, -1, 0.15), thick=width * 0.3)
    # over each ear, two locks down and back
    for s in (-1, 1):
        for a, length in ((s * 78, 0.62), (s * 104, 0.56)):
            hair.clump(a, 54, length, 0.4, heading=-s * 8, off=0.06, flick=18, hold=0.7, comb=(0, -0.4, -1), thick=0.11)
    # the nape, three short points out
    for a in (156, 180, 204):
        hair.clump(a, 66, 0.44, 0.38, heading=0, off=0.06, flick=22, hold=0.62, comb=(0, -0.3, -1), thick=0.1)
    # the fringe swept from a part at his right across his brow toward his left, four broad locks lying on each
    # other, the last over his left temple; one short lock falls by his right temple
    for a, ph, length, width in ((-40, 30, 0.86, 0.5), (-16, 28, 0.9, 0.52), (10, 30, 0.82, 0.48), (34, 36, 0.66, 0.42)):
        hair.clump(a, ph, length, width, heading=0, off=0.05, flick=14, hold=0.76, comb=(-0.85, 1.0, -0.9), thick=width * 0.28)
    hair.clump(-58, 40, 0.6, 0.36, heading=0, off=0.06, flick=20, hold=0.66, comb=(0.15, 0.25, -1), thick=0.1)
    return figure(joints, folder, b, head, hair, pm.lamp(), skin)


# --- B, the wide brim --------------------------------------------------------------------------------------------------

def take_b(joints, folder):
    skin, wine, cream, gold, dark_, boot, hat_ = "#F1CDB0", "#5A2027", "#EFE4CF", "#D6A24A", "#2A2226", "#4A3027", "#2A262C"
    edge, cream_edge = tone(wine, 0.45), tone(cream, 0.55)
    b = blocks_of({"torso": wine, "rs": wine, "ls": wine, "rh": dark_, "lh": dark_})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the wine tunic: a gold-edged closure down the middle, the folds pulled to the waist
    line(f, [(0.0, 1.4), (0.02, 0.8), (0.0, 0.38)], 0.03, gold, 1.0)
    line(f, [(0.03, 1.4), (0.05, 0.8), (0.03, 0.38)], 0.012, edge, 0.9)
    creases(f, [[(-0.9, 1.2), (-0.7, 0.96), (-0.44, 0.9)], [(0.9, 1.2), (0.7, 0.96), (0.44, 0.9)],
                [(-0.6, 0.62), (-0.36, 0.5), (-0.12, 0.56)], [(0.6, 0.62), (0.36, 0.5), (0.12, 0.56)]], 0.5)
    # the cream capelet over the shoulders: to a point at the chest's middle in front, longer behind, a gold edge
    cape_f = [(-1, 1.5), (-0.5, 1.4), (0.0, 1.22), (0.5, 1.4), (1, 1.5)]
    cape_b = [(-1, 1.3), (-0.5, 1.06), (0.0, 0.92), (0.5, 1.06), (1, 1.3)]
    for p, pts in ((f, cape_f), (back, cape_b)):
        p.lay(p.poly(pts + [(1, 2.0), (-1, 2.0)]), cream)
        line(p, pts, 0.034, gold, 1.0)
        line(p, [(x, y + 0.03) for x, y in pts], 0.012, cream_edge, 0.8)
        creases(p, [[(-0.8, 1.94), (-0.7, 1.74), (-0.72, 1.56)], [(0.8, 1.94), (0.7, 1.74), (0.72, 1.56)],
                    [(-0.3, 1.9), (-0.24, 1.66), (-0.16, 1.46)], [(0.3, 1.9), (0.24, 1.66), (0.16, 1.46)]], 0.36)
    w.lay(w.rect(1.0, 1.5, 1.5, 2.0), cream)      # its sides, round the arms' tops
    w.lay(w.rect(-1.5, 1.5, -1.0, 2.0), cream)
    # its clasp at the throat, gold, and a high neck band
    band(w, 1.9, 2.0, tone(cream, 0.92), cream_edge)
    f.lay(f.ellipse(0.0, 1.86, 0.09, 0.07), gold)
    f.lay(f.ellipse(0.0, 1.86, 0.045, 0.034), tone(gold, 0.55))
    # a wide dark sash, its knot and two ends at his left hip
    band(w, 0.16, 0.38, dark_, tone(gold, 0.7))
    f.lay(f.poly([(0.5, 0.4), (0.7, 0.42), (0.74, 0.12), (0.52, 0.12)]), tone(dark_, 1.6))
    for x0 in (0.56, 0.68):
        f.lay(f.poly([(x0, 0.16), (x0 + 0.1, 0.16), (x0 + 0.12, 0.0), (x0 + 0.02, 0.0)]), tone(dark_, 1.3))
    creases(back, [[(-0.9, 0.86), (-0.7, 0.66), (-0.56, 0.42)], [(0.9, 0.86), (0.7, 0.66), (0.56, 0.42)]], 0.45)
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=91)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        sleeves(a, wine, cream, piping=gold, seed=92 + i)
        w = a.wrap   # the capelet over the shoulder's top
        w.lay(w.rect(-9, 1.62, 9, 2.0), cream)
        w.lay(w.rect(-9, 1.6, 9, 1.64), gold)
        for p in a.sides:
            creases(p, [[(-0.4, 1.92), (-0.1, 1.8), (0.3, 1.86)]], 0.3)
    tops(b, wine, cream)
    b["torso"].faces["top"].px[:] = rgb(tone(cream, 1.0))

    for i, (key, s) in enumerate((("rh", -1), ("lh", 1))):
        g = b[key]
        for p in g.sides:
            creases(p, [[(-0.4, 1.66), (-0.05, 1.54), (0.36, 1.6)], [(-0.36, 1.14), (0.0, 1.02), (0.38, 1.08)]], 0.4)
        boots(g, boot, 0.56, strap=tone(boot, 0.6))
        band(g.wrap, 1.94, 2.0, tone(dark_, 0.8), None)
        shadow(g, 0.28, low=0.0)
        lit(g, 0.08)
        grain(g, seed=94 + i)

    head = am.Head(skin)
    face(head, skin, "#D99A3A", "#2A1A16")
    hair = am.Hair("#1C1413", "#B4542E", seed=97, band=(0.42, 0.1, 0.25), scalp=am.HEAD_EGG)
    # the mass under the hat, lying on his head down to the nape, its points before the ears
    hair.mass(am.hairline(front=4.94, temple=4.5, nape=4.02), (180, 30), opening=0.1, seed=97,
              tips=((180, 14, 4), (150, 12, 6), (210, 12, 6), (80, 18, 18), (-80, 18, 18)),
              lift=0.04, off=(0.0, 0.08), ease=2.0, tuck=0.09)
    # spilling under the brim: a fringe of broad locks parted off the middle, and locks over each ear, ember at the ends
    # (rooted under the brim: rooted higher, they ran up inside the crown and out through the band)
    for a, length, width, comb in ((-44, 0.52, 0.38, (0.35, 0.5, -1)), (-20, 0.6, 0.42, (0.15, 0.5, -1)), (4, 0.62, 0.44, (-0.05, 0.5, -1)),
                                   (28, 0.56, 0.4, (-0.25, 0.5, -1)), (50, 0.46, 0.34, (-0.4, 0.4, -1))):
        hair.clump(a, 50, length, width, heading=0, off=0.04, flick=8, hold=0.86, comb=comb, k=1.02, thick=width * 0.28)
    for s in (-1, 1):
        for a, length in ((s * 72, 0.66), (s * 92, 0.6), (s * 112, 0.5)):
            hair.clump(a, 56, length, 0.34, heading=-s * 6, off=0.06, flick=20, hold=0.66, comb=(0, -0.3, -1), thick=0.1)
    for a in (150, 180, 210):
        hair.clump(a, 62, 0.46, 0.34, heading=0, off=0.06, flick=16, hold=0.7, comb=(0, -0.4, -1), thick=0.1)
    # a short tail at the nape, tied: one solid lock, its end parting
    tie_at = hair.at(180, 100)[0] + hair.at(180, 100)[1] * 0.06
    spine = [tie_at + Vector(q) for q in ((0, 0.0, 0.0), (0.0, -0.12, -0.14), (0.02, -0.16, -0.38), (0.04, -0.12, -0.6))]
    hair.tail(spine, ((0, 0.09), (0.2, 0.13), (0.6, 0.11), (1.0, 0.0)), seed=98, n=12, around=8)
    tie = am.Built("Tie")
    tie.loop(tie_at + Vector((0, -0.02, -0.06)), 0.1, 0.08, gold, thick=0.05, segments=12, squash=0.9)
    top = wide_hat((0.0, -0.02, 5.05), 0.88, 1.44, 0.78, 0.56, hat_, gold, pitch=-5.0, roll=-7.0)
    return figure(joints, folder, b, head, hair, [top, tie, *pm.lamp()], skin)


# --- C, the high collar ------------------------------------------------------------------------------------------------

def take_c(joints, folder):
    skin, brick, black, ivory, ember, boot = "#F3D2BA", "#A8381F", "#1E1F25", "#EFE9DE", "#F07A34", "#4A3328"
    edge, facing = tone(brick, 0.45), mix(brick, "#F2B08A", 0.35)
    crop = 0.82   # on the torso: where the jacket ends
    b = blocks_of({"torso": black, "rs": brick, "ls": brick, "rh": black, "lh": black})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the black top, fitted: a seam either side of the front, the folds to the waist
    for s in (-1, 1):
        line(f, [(s * 0.3, 1.8), (s * 0.26, 1.1), (s * 0.3, 0.2)], 0.012, tone(black, 2.2), 0.6)
    creases(f, [[(-0.3, 0.66), (-0.05, 0.56), (0.22, 0.62)], [(0.36, 0.4), (0.1, 0.3), (-0.16, 0.36)]], 0.3)
    # the cropped jacket over it, open at the front, its facing lit, its hem a band at the ribs
    w.lay(w.rect(-9, crop, 9, 2.0), brick)
    f.lay(f.poly([(-0.28, 2.0), (0.28, 2.0), (0.36, crop), (-0.36, crop)]), black)
    for s in (-1, 1):
        f.lay(f.poly([(s * 0.28, 2.0), (s * 0.4, 2.0), (s * 0.48, crop), (s * 0.36, crop)]), facing)
        line(f, [(s * 0.28, 2.0), (s * 0.36, crop)], 0.024, edge)
        line(f, [(s * 0.4, 2.0), (s * 0.48, crop)], 0.016, edge, 0.8)
        creases(f, [[(s * 0.98, 1.84), (s * 0.82, 1.64), (s * 0.6, 1.56)], [(s * 1.0, 1.24), (s * 0.84, 1.12), (s * 0.66, 1.16)]], 0.5)
    band(w, crop, crop + 0.12, tone(brick, 0.82), edge)
    f.lay(f.poly([(-0.36, crop), (0.36, crop), (0.36, crop + 0.12), (-0.36, crop + 0.12)]), black)
    # an ember line round the hem's top, and one small ember mark on his left breast
    w.lay(w.rect(-9, crop + 0.12, 9, crop + 0.14), ember)
    f.lay(f.rect(-0.36, crop + 0.12, 0.36, crop + 0.14), black)
    f.lay(f.poly([(0.66, 1.56), (0.72, 1.44), (0.7, 1.36), (0.62, 1.38), (0.6, 1.48)]), ember)
    # the back of the jacket: its yoke, its seam, its folds
    line(back, [(-1.0, 1.6), (0.0, 1.66), (1.0, 1.6)], 0.014, edge, 0.7)
    line(back, [(0.0, 1.62), (0.0, crop + 0.12)], 0.014, edge, 0.6)
    creases(back, [[(-0.98, 1.3), (-0.74, 1.08), (-0.58, 0.98)], [(0.98, 1.3), (0.74, 1.08), (0.58, 0.98)]], 0.5)
    # a belt, ivory webbing with a dark buckle
    band(w, 0.12, 0.26, ivory, tone(ivory, 0.6))
    f.lay(f.rect(-0.1, 0.12, 0.1, 0.26), "#3A3B44")
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=101)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        sleeves(a, brick, black, piping=ember, seed=102 + i)
        band(a.wrap, 1.02, 1.08, tone(brick, 0.7), None)   # a seam at the elbow
    tops(b, brick)

    for i, (key, s) in enumerate((("rh", -1), ("lh", 1))):
        g = b[key]
        for p in g.sides:
            creases(p, [[(-0.4, 1.66), (-0.05, 1.54), (0.36, 1.6)], [(-0.36, 1.14), (0.0, 1.02), (0.38, 1.08)]], 0.22)
        kt.shin_wraps(g, ivory, 0.44, 0.92, 0.1)
        boots(g, boot, 0.44)
        shadow(g, 0.26, low=0.0)
        lit(g, 0.1)
        grain(g, seed=104 + i)

    head = am.Head(skin)
    face(head, skin, "#E5542A", "#8C7A5A")
    hair = am.Hair("#9A7E58", "#FFEBC0", seed=107, band=(0.5, 0.12, 0.4), scalp=am.HEAD_EGG)
    # one mass on his head to a whorl at the crown, its rim tucked in, points to the collar behind and before the ears
    hair.mass(am.hairline(front=4.98, temple=4.5, nape=4.0), (180, 10), opening=0.1, seed=107,
              tips=((180, 18, 12), (148, 12, 12), (212, 12, 12), (120, 12, 10), (240, 12, 10), (82, 18, 18), (-82, 18, 18)),
              lift=0.06, off=(0.0, 0.11), ease=2.0, tuck=0.09)
    # full and messy: big locks off the crown, flicked up and back; over each ear, flicked out; the nape's points
    for a, ph, length, width, heading in ((-70, 14, 0.84, 0.5, 20), (-34, 8, 0.94, 0.54, 8), (2, 6, 0.98, 0.56, 0),
                                          (38, 8, 0.92, 0.54, -8), (72, 14, 0.82, 0.5, -20)):
        hair.clump(a, ph, length, width, heading=heading, off=0.1, flick=42, hold=0.5, comb=(0, -1, 0.3), thick=width * 0.3)
    for a, length in ((140, 0.72), (180, 0.78), (220, 0.72)):
        hair.clump(a, 30, length, 0.52, heading=0, off=0.08, flick=36, hold=0.55, comb=(0, -0.5, -1), thick=0.14)
    for s in (-1, 1):
        for a, length in ((s * 76, 0.64), (s * 102, 0.6)):
            hair.clump(a, 52, length, 0.42, heading=-s * 10, off=0.06, flick=30, hold=0.6, comb=(0, -0.2, -1), thick=0.12)
    for a in (158, 180, 202):
        hair.clump(a, 72, 0.5, 0.4, heading=0, off=0.06, flick=26, hold=0.6, comb=(0, -0.3, -1), thick=0.11)
    # the long fringe, falling over his right eye: three broad locks, the longest down past the eye
    for a, ph, length, width, comb in ((-30, 28, 1.02, 0.5, (0.25, 0.7, -1.2)), (-6, 26, 0.92, 0.5, (0.1, 0.7, -1.1)),
                                       (20, 30, 0.74, 0.44, (-0.2, 0.7, -1.0)), (42, 38, 0.58, 0.38, (-0.45, 0.5, -1.0))):
        hair.clump(a, ph, length, width, heading=0, off=0.05, flick=10, hold=0.8, comb=comb, thick=width * 0.28)
    collar = standing_collar(brick, ivory, edge)
    return figure(joints, folder, b, head, hair, [collar, *pm.lamp()], skin)


# --- C, the finish: research's pick and its four must-fixes ------------------------------------------------------------

def cel_sleeve(a, cloth, cuff, piping=None, seed=1, depth=0.72, edge=0.4, folds=None, rim=0.16, pulled=False):
    """`sleeves` with its folds painted per side (am.cel_sides; `folds` the kit's sleeve when None), never one curve
    on all four. `pulled`: the folds are `pull`s, `folds` then mapping a side to [(points, width)]."""
    w = a.wrap
    w.lay(w.rect(-9, 0.0, 9, 2.0), cloth)
    band(w, 0.0, 0.26, cuff, tone(cuff, 0.5))
    if pulled:
        pull_sides(a, folds, cloth)
    else:
        am.cel_sides(a, folds or am.SLEEVE_CEL, cloth, depth, edge, rim=rim)
    for q in a.sides:
        dark(q, q.soft(q.rect(-9, 0.26, 9, 0.3), 0.02), 0.3)
    if piping is not None:
        w.lay(w.rect(-9, 0.26, 9, 0.3), piping)
    w.lay(w.rect(-9, 1.8, 9, 1.815), tone(cloth, 0.45), 0.85)
    shadow(a, 0.38, low=0.0)
    lit(a, 0.24, 0.1)
    a.faces["bottom"].px[:] = rgb(tone(cloth, 0.25))
    a.faces["top"].px[:] = rgb(cloth)
    grain(a, seed=seed)


# On the black, a fold is its lit ridge, long and thin, as AV's black cloth has them (the first finish's short leaves
# read as grey commas, 2026-11-28): the top's in its opening and under the jacket, the trousers' from the hip to the knee.
# On the brick, fewer folds and larger (research's checkpoint, 2026-11-28: "faint on one bright red"), each a `pull`:
# a closed crescent, pointed at both ends and set in pairs, read at the phone's size as a slash, a stain or a claw
# mark, filled dark or not (research and the content check, in the game, 2026-11-28). One pull per seam, no two alike:
# the sleeve's from the shoulder outside and from the elbow in front; the jacket's from each armpit in front, at its
# own angle, and behind, one long from the hem's side and one short and steep from the yoke.
BRICK_SLEEVE = {"out": [([(-0.36, 2.08), (-0.12, 1.66), (0.06, 1.36)], 0.32)],
                "front": [([(0.56, 0.98), (0.24, 0.84), (-0.06, 0.8)], 0.26)]}
BRICK_FRONT = {1: ([(1.08, 1.62), (0.84, 1.36), (0.6, 1.18)], 0.34), -1: ([(-1.08, 1.4), (-0.82, 1.2), (-0.62, 1.1)], 0.28)}
BRICK_BACK = [([(1.08, 1.02), (0.7, 1.18), (0.36, 1.3)], 0.32), ([(-1.08, 1.56), (-0.88, 1.32), (-0.76, 1.12)], 0.22)]


pull, pull_sides = am.pull, am.pull_sides   # the kit's own since Rook and Kirra take it (2026-11-28)
BLACK_TOP = [([(-0.12, 1.72), (-0.08, 1.3), (-0.12, 0.98)], 0.035), ([(-0.24, 0.8), (-0.1, 0.5), (0.0, 0.3)], 0.04),
             ([(0.26, 0.78), (0.2, 0.5), (0.24, 0.3)], 0.035)]
BLACK_LEG = {"front": [([(-0.3, 1.96), (-0.12, 1.4), (-0.04, 0.96)], 0.05), ([(0.32, 1.3), (0.24, 1.08), (0.26, 0.94)], 0.035)],
             "out": [([(0.3, 1.9), (0.2, 1.3), (0.18, 0.94)], 0.05)],
             "back": [([(0.3, 1.9), (0.16, 1.4), (0.1, 0.96)], 0.045)]}


def finish_c(joints, folder):
    """C as research picked it (AR63, "the redo's pick", 2026-11-28), with its must-fixes:
    1. the head: a deeper gold, dark at the roots; a warmer skin; the fringe cast on his face; the collar dark inside,
       so at 64 px the head reads gold over skin over a dark ring, never one light blob;
    2. more locks, narrower and sharper, parted from each other;
    3. folds painted per garment (am.cel): hard-edged, in each cloth's own shade with a dark crease edge, as lit ridges
       on the black; deeper shade at the edges and more light at the top.
    The fourth, the Shades off red and black, is AR75's (shade_redo_takes.py)."""
    skin, brick, black, ivory, ember, boot = "#EFC09E", "#A8381F", "#1E1F25", "#EFE9DE", "#F07A34", "#4A3328"
    edge, facing, lining = tone(brick, 0.42), mix(brick, "#F2B08A", 0.35), "#2A2026"
    crop = 0.82
    b = blocks_of({"torso": black, "rs": brick, "ls": brick, "rh": black, "lh": black})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the black top: its seams, its folds as lit ridges pulled to the waist
    for s in (-1, 1):
        line(f, [(s * 0.3, 1.8), (s * 0.26, 1.1), (s * 0.3, 0.2)], 0.012, tone(black, 2.2), 0.6)
    for pts, wide in BLACK_TOP:
        cel(f, pts, wide, black, 2.6, 0.5)
    # the cropped jacket, open at the front, its facing lit, its hem a band at the ribs
    w.lay(w.rect(-9, crop, 9, 2.0), brick)
    f.lay(f.poly([(-0.28, 2.0), (0.28, 2.0), (0.36, crop), (-0.36, crop)]), black)
    for s in (-1, 1):
        pull(f, *BRICK_FRONT[s], brick)   # pulled from the armpit
        f.lay(f.poly([(s * 0.28, 2.0), (s * 0.4, 2.0), (s * 0.48, crop), (s * 0.36, crop)]), facing)
        line(f, [(s * 0.28, 2.0), (s * 0.36, crop)], 0.026, edge)
        line(f, [(s * 0.4, 2.0), (s * 0.48, crop)], 0.018, edge, 0.85)
    band(w, crop, crop + 0.12, tone(brick, 0.8), edge)
    f.lay(f.poly([(-0.36, crop), (0.36, crop), (0.36, crop + 0.12), (-0.36, crop + 0.12)]), black)
    w.lay(w.rect(-9, crop + 0.12, 9, crop + 0.14), ember)
    f.lay(f.rect(-0.36, crop + 0.12, 0.36, crop + 0.14), black)
    f.lay(f.poly([(0.66, 1.56), (0.72, 1.44), (0.7, 1.36), (0.62, 1.38), (0.6, 1.48)]), ember)
    # the back: its yoke, its seam, its folds from the shoulder blades to the hem, unlike the front's
    line(back, [(-1.0, 1.6), (0.0, 1.66), (1.0, 1.6)], 0.016, edge, 0.75)
    line(back, [(0.0, 1.62), (0.0, crop + 0.12)], 0.016, edge, 0.65)
    for pts, wide in BRICK_BACK:
        pull(back, pts, wide, brick)
    band(w, 0.12, 0.26, ivory, tone(ivory, 0.6))
    f.lay(f.rect(-0.1, 0.12, 0.1, 0.26), "#3A3B44")
    shadow(t, 0.4)
    lit(t, 0.24, 0.1)
    grain(t, seed=101)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        cel_sleeve(a, brick, black, piping=ember, seed=102 + i, folds=BRICK_SLEEVE, pulled=True)
        band(a.wrap, 1.02, 1.08, tone(brick, 0.66), None)
    tops(b, brick)

    for i, (key, s) in enumerate((("rh", -1), ("lh", 1))):
        g = b[key]
        am.cel_sides(g, BLACK_LEG, black, 2.6, 0.5)
        kt.shin_wraps(g, ivory, 0.44, 0.92, 0.1)
        boots(g, boot, 0.44)
        shadow(g, 0.34, low=0.0)
        lit(g, 0.14)
        grain(g, seed=104 + i)

    head = am.Head(skin)
    face(head, skin, "#E5542A", "#6A4A26")
    # dark between the locks (research's checkpoint, 2026-11-28): each lock's edges in shade beside its lit ridge, the
    # mass under them darker
    hair = am.Hair("#4E3216", "#F0BE56", seed=107, band=(0.52, 0.1, 0.42), scalp=am.HEAD_EGG, gap=0.12)
    hair.mass(am.hairline(front=4.98, temple=4.5, nape=4.0), (180, 10), opening=0.1, seed=107, k=0.5,
              tips=((180, 18, 2), (148, 12, 4), (212, 12, 4), (120, 12, 10), (240, 12, 10), (82, 18, 18), (-82, 18, 18)),
              # the three at his back end inside the collar: at 12 degrees down they hung below his torso's top, behind
              # his back, under it
              lift=0.06, off=(0.0, 0.11), ease=2.0, tuck=0.09)
    # the crown: seven locks, narrower than the take's five, flicked up and back, each lying a little over the next
    for i, (a, ph, length, width, heading) in enumerate(((-84, 16, 0.8, 0.38, 22), (-56, 11, 0.9, 0.4, 14), (-28, 8, 0.96, 0.42, 6),
                                                         (0, 6, 1.0, 0.44, 0), (28, 8, 0.94, 0.42, -6), (56, 11, 0.88, 0.4, -14),
                                                         (84, 16, 0.78, 0.38, -22))):
        hair.clump(a, ph, length, width, heading=heading, off=0.1 + 0.03 * (i % 2), flick=44, hold=0.5, comb=(0, -1, 0.3),
                   thick=width * 0.3, taper=2.2, split=1 if i in (2, 4) else 0)
    # the back in two tiers, never rows of short points (the first finish's read as scales): four long locks from the crown
    # down past the nape, of unlike lengths, and under them three at the nape turned down and out
    for a, length, width in ((138, 1.02, 0.5), (164, 1.16, 0.54), (194, 1.1, 0.54), (222, 0.96, 0.5)):
        hair.clump(a, 26, length, width, heading=0, off=0.08, flick=22, hold=0.66, comb=(0, -0.3, -1), thick=0.13, taper=2.2)
    for s in (-1, 1):
        for a, length in ((s * 72, 0.62), (s * 92, 0.66), (s * 112, 0.58)):
            hair.clump(a, 52, length, 0.34, heading=-s * 10, off=0.06, flick=32, hold=0.6, comb=(0, -0.2, -1), thick=0.1, taper=2.2)
    for a, length in ((156, 0.5), (180, 0.54), (204, 0.5)):   # their ends inside the collar (the middle one hung
        # below his torso's top, behind his back: 0.6, 0.7, 0.6 before)
        hair.clump(a, 76, length, 0.42, heading=0, off=0.05, flick=14, hold=0.7, comb=(0, -0.2, -1), thick=0.1, taper=2.2)
    # the fringe over his right eye: five locks, parted, the longest down past the eye
    for a, ph, length, width, comb in ((-36, 28, 1.04, 0.4, (0.25, 0.7, -1.2)), (-18, 26, 0.96, 0.4, (0.15, 0.7, -1.1)),
                                       (0, 27, 0.84, 0.38, (0.0, 0.7, -1.05)), (20, 30, 0.7, 0.36, (-0.2, 0.7, -1.0)),
                                       (42, 38, 0.56, 0.32, (-0.45, 0.5, -1.0))):
        hair.clump(a, ph, length, width, heading=0, off=0.05, flick=12, hold=0.8, comb=comb, thick=width * 0.28, taper=2.0)
    collar = standing_collar(brick, lining, edge)
    return figure(joints, folder, b, head, hair, [collar, *pm.lamp()], skin, cast=mix(skin, "#5A1E18", 0.7), drop=0.11,
                  cast_alpha=1.0)


def today(joints, folder):
    """Today's Pip, as pip_make.py's finish makes him."""
    return pm.take(pm.FACES[pm.PICK["face"]][1])(joints, folder)


TAKES = {"Pip": today, "A": take_a, "B": take_b, "C": take_c, "F": finish_c}

# C's finish for the install (pip_make.finish): no hat; the collar welded to the torso, the lantern on its own joint
C_PIECES = {"Collar": ("Collar", "Torso"), "Lamp": ("Lamp", "Torso")}
C_MAKE = ("tools/blender/anime_make.py, pip_make.py and pip_redo_takes.py (finish_c): R6's own blocks and round head with "
          "the clothes and the face drawn on them, the hair one mesh; built pieces: the standing collar, welded to the "
          "torso, and the lantern on a joint of its own (the first Pip's).")


if __name__ == "__main__":
    rt.TAKES, rt.SAID, rt.WHO = TAKES, SAID, tuple(TAKES)
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "sheet"
    if mode == "takes":
        rt.takes_run(OUT, rest[1:] or list(TAKES), finish=pt.measured)
    elif mode == "shade":
        rt.shade_run(OUT)
    elif mode == "sheet":
        rt.sheet_run(OUT, WORDS, BESIDE)
    elif mode == "model":   # C's finish drawn again, and the install's files in <out>/handoff
        rt.takes_run(OUT, ["F"], finish=lambda key, made: pm.finish(key, made, OUT, extra=C_PIECES, make=C_MAKE, hat=False))
    elif mode == "modelsheet":
        pm.sheet_run(OUT, key="F", title="PIP, C'S FINISH: THE MODEL FOR THE INSTALL", tag="AR63: C's finish",
                     joints="Lamp (on the Torso), the first Pip's; the collar welded to the Torso")
    elif mode == "proof":   # C's finish alone, as a finish is judged (rook_make_takes.proof_run)
        rt.proof_run(OUT, "F", title="AR63: PIP, C'S FINISH", about="Common / Purple / Mage / Fire.", whose="his",
                     stem="pip_finish", beside=list(BESIDE), tag="AR63: C's finish")
