"""Pip, redone in the make (the director's order of 2026-11-23: Rook, Kirra, Pip, Lyric): three takes drawn with
anime_make.py's kit, as Kirra's were (AR60). Common, Purple, a Mage, Fire: a young apprentice of a mages' school, too
small for his clothes, his fire held in a lantern that floats beside him. The lantern is a young mage's: dark metal
and glass with a living flame inside, never a paper festival lantern; his Fire reads in the flame, not in its shell
(research's steer, 2026-11-24). It is a built piece of its own, the same in every take; the clothes stay drawn on the
blocks.

    A, the first-year: an oversized soft pointed hat that slouches back, forest green with an ochre band; copper hair
       spilling under it; amber eyes; a cream tunic under a green mantle, sleeves past his hands; brown trousers, boots.
    B, the prodigy: no hat, black hair swept up like a flame in a few solid spikes; orange eyes; an ivory high-collared
       jacket with charcoal trim and gold buttons, sleeves past his hands; charcoal trousers.
    C, the hearth kid: a huge soft cap, ochre, slipping over one brow; sandy hair; green eyes; a brick-brown short
       coat over a white shirt, wide sleeves; sage trousers.

Each is drawn as the player meets it, by rook_make_takes.py's pictures and sheet, with the new Kirra (AR60's take A)
in the first place.

    blender.exe -b --factory-startup --python tools/blender/pip_make_takes.py -- <out_dir> takes [Kirra A B C]
    blender.exe -b --factory-startup --python tools/blender/pip_make_takes.py -- <out_dir> shade|sheet
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
import rook_make_takes as rt  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402
from anime_make import INK, mix, rgb, tone  # noqa: E402
from rook_make_takes import band, blocks_of, creases, dark, grain, line, lit, neck, shadow, shoe  # noqa: E402

BESIDE = kt.BESIDE
SAID = {
    "Kirra": ("The new Kirra", ("AR60's take A, as research passed it,", "for his colours and outline beside hers")),
    "A": ("A, the first-year", ("an oversized pointed hat, slouched, green", "copper hair, amber eyes",
                                "a cream tunic under a green mantle", "sleeves past his hands")),
    "B": ("B, the prodigy", ("no hat: black hair swept up in solid spikes", "orange eyes",
                             "an ivory high-collared jacket, gold buttons", "sleeves past his hands")),
    "C": ("C, the hearth kid", ("a huge soft ochre cap over one brow", "sandy hair, green eyes",
                                "a brick-brown short coat, a white shirt", "sage trousers")),
}
WORDS = dict(
    stem="pip",
    beside="Pip's three takes square on, between two Anime Vanguards units at the same height. Internal: the two are reference.",
    title="PIP IN THE MAKE, THREE TAKES",
    about="Common / Purple / Mage / Fire: a young apprentice of a mages' school, too small for his clothes. The make is AR59's: "
          "R6's plain blocks with the clothes drawn on them, a drawn face on the round head, hair as one solid mass. He carries "
          "built pieces: his hat, and the lantern that floats beside his right shoulder, dark metal and glass with a living "
          "flame inside. Each stands as in the game: from the three-quarter front, then from the game's camera behind his right "
          "shoulder, the new Kirra first. Research picks one.",
    row="the new Kirra, A, B, C and a Brawler",
)

IRON, IRON_LIT = "#2B2A30", "#5C5966"
FLAME = ("#FFF4C4", "#FFC94A", "#FF8A2A", "#E8501C")   # its heart, its body, its edge, its tip


# --- drawing -----------------------------------------------------------------------------------------------------------

def face(head, look):
    """The kit's face, a boy's: round open eyes, a short lash, the brows a little raised."""
    am.draw_face(head.paint, look)


def ring(c, r, z, n, wob=None):
    """A ring of `n` places round the upright axis through `c`, `r` out, at height `z`."""
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n
        k = 1 + (wob(a) if wob else 0.0)
        out.append(Vector((c[0] + math.sin(a) * r * k, c[1] + math.cos(a) * r * k, z)))
    return out


def lit_round(colour, n, toward=30.0, low=0.72, high=1.12):
    """A side's colour by where it faces round, lit from `toward` degrees (from the front toward his right)."""
    return lambda k: tone(colour, low + (high - low) * (0.5 + 0.5 * math.cos(2 * math.pi * (k + 0.5) / n - math.radians(toward))))


def bar(b, a, z0, z1, colour, w=0.028):
    """A thin upright bar of the lantern's cage."""
    sq = [Vector((-w, -w, 0)), Vector((w, -w, 0)), Vector((w, w, 0)), Vector((-w, w, 0))]
    b.tube([[Vector(a) + q + Vector((0, 0, z0)) for q in sq], [Vector(a) + q + Vector((0, 0, z1)) for q in sq]],
           lambda i, k: tone(colour, 1.2 if k in (1, 2) else 0.8), caps=None, smooth=False)


def torus(b, centre, R, r, colour, segments=14, around=6, axis="Y"):
    """A small ring, upright, round `axis`."""
    c = Vector(centre)
    rings = []
    for i in range(segments + 1):
        a = 2 * math.pi * i / segments
        out = Vector((math.cos(a), 0, math.sin(a))) if axis == "Y" else Vector((0, math.cos(a), math.sin(a)))
        t = Vector((0, 1, 0)) if axis == "Y" else Vector((1, 0, 0))
        rings.append([c + out * (R + r * math.cos(2 * math.pi * j / around)) + t * r * math.sin(2 * math.pi * j / around)
                      for j in range(around)])
    b.tube(rings, lambda i, k: tone(colour, 1.15 if k in (0, 1) else 0.75), caps=None, smooth=True)


def lantern(at=(2.35, 0.35, 4.3), size=1.35):
    """His lantern, floating: a dark iron cage of six bars between a footed base and a peaked cap with a ring to
    hold it by; six glass panes; a living flame inside. Three pieces, so the glass can be seen through and the flame
    can glow: the cage, the glass, the flame."""
    c = Vector(at)
    S = size
    cage, glass, flame = am.Built("Lantern"), am.Built("LanternGlass"), am.Built("LanternFlame")
    n = 6
    shade = lit_round(IRON, n, low=0.8, high=1.6)
    # the base: a foot, a flared plate, a lip
    base = [ring(c, 0.1 * S, c.z - 0.36 * S, n), ring(c, 0.2 * S, c.z - 0.32 * S, n), ring(c, 0.25 * S, c.z - 0.27 * S, n),
            ring(c, 0.25 * S, c.z - 0.22 * S, n), ring(c, 0.2 * S, c.z - 0.2 * S, n)]
    cage.tube(base, lambda i, k: shade(k) if i != 2 else tone(IRON_LIT, 1.1), caps=(tone(IRON, 0.6), tone(IRON, 0.9)), smooth=False)
    # the bars at the panes' corners
    for p in ring(c, 0.205 * S, 0.0, n):
        bar(cage, (p.x, p.y, c.z), -0.2 * S, 0.22 * S, IRON_LIT, 0.024 * S)
    # a band round the middle of the cage
    mid = [ring(c, 0.215 * S, c.z - 0.01 * S, n), ring(c, 0.215 * S, c.z + 0.02 * S, n)]
    cage.tube(mid, lambda i, k: shade(k), caps=None, smooth=False)
    # the cap: a lip, a peak and a finial
    cap = [ring(c, 0.2 * S, c.z + 0.22 * S, n), ring(c, 0.27 * S, c.z + 0.25 * S, n), ring(c, 0.26 * S, c.z + 0.29 * S, n),
           ring(c, 0.12 * S, c.z + 0.42 * S, n), ring(c, 0.05 * S, c.z + 0.47 * S, n), ring(c, 0.06 * S, c.z + 0.5 * S, n),
           ring(c, 0.0, c.z + 0.53 * S, n)]
    cage.tube(cap, lambda i, k: tone(IRON_LIT, 1.05) if i == 1 else shade(k), caps=(tone(IRON, 0.6), None), smooth=False)
    torus(cage, (c.x, c.y, c.z + 0.6 * S), 0.07 * S, 0.016 * S, IRON_LIT)
    # the glass, its panes inside the bars, faintly warm from the flame
    panes = [ring(c, 0.195 * S, c.z - 0.2 * S, n), ring(c, 0.195 * S, c.z + 0.22 * S, n)]
    glass.tube(panes, lambda i, k: mix("#FFF1DA", "#FFD08A", 0.3 + 0.2 * math.cos(k)), caps=None, smooth=False)
    # the flame: a teardrop leaning a little, its heart pale, its tip deep
    lean = Vector((-0.02, -0.01, 0))
    tear = [(0.0, -0.15), (0.06, -0.13), (0.085, -0.06), (0.075, 0.02), (0.05, 0.09), (0.025, 0.14), (0.0, 0.19)]
    rings = [ring(c + lean * (z / 0.19), r * S, c.z + z * S, 8) for r, z in tear]
    flame.tube(rings, lambda i, k: FLAME[0] if i < 2 else FLAME[1] if i < 4 else FLAME[2] if i < 5 else FLAME[3],
               caps=(FLAME[0], None), smooth=True)
    return [cage, glass, flame]


def hat(base, r_in, brim, height, colour, band_, tip_back=0.55, droop=0.12, pitch=-8.0, roll=5.0, n=28):
    """An oversized soft pointed hat: a wide brim that droops at its edge, a band, and a crown that rises and slouches
    back. `base` is the middle of its opening; `pitch` tips it back (above zero), `roll` to his left."""
    b = am.Built("Hat")
    c = Vector(base)
    shade = lit_round(colour, n, low=0.66, high=1.14)
    wave = lambda a: 0.04 * math.sin(3 * a + 0.6)  # noqa: E731   the brim's soft wave
    rings = [ring(c, r_in, c.z - 0.02, n), ring(c, brim, c.z - droop, n, wave), ring(c, brim, c.z - droop + 0.05, n, wave),
             ring(c, r_in + 0.02, c.z + 0.06, n), ring(c, r_in, c.z + 0.2, n)]
    steps = 7
    for s in range(1, steps + 1):
        f = s / steps
        r = r_in * (1 - f) ** 0.9 + 0.012
        back = tip_back * f ** 2.4
        fall = 0.5 * tip_back * max(0.0, f - 0.75) ** 1.4    # a little: more, and the tip caves into the crown
        z = c.z + 0.2 + height * (f - 0.3 * f ** 3)
        rings.append(ring((c.x, c.y - back, 0), r, z - fall, n))

    def colours(i, k):
        if i == 0:
            return tone(colour, 0.42)        # under the brim
        if i == 1:
            return tone(colour, 0.6)         # its edge
        if i == 2:
            return shade(k)                  # its top
        if i == 3:
            return lit_round(band_, n)(k)    # the band
        return shade(k)

    b.tube(rings, colours, caps=(tone(colour, 0.3), tone(colour, 0.5)), smooth=True)
    # tip it back and to his left about its opening's middle
    turn = Matrix.Rotation(math.radians(roll), 3, "Y") @ Matrix.Rotation(math.radians(pitch), 3, "X")
    for v in b.bm.verts:
        v.co = c + turn @ (v.co - c)
    return b


def cap(base, r_in, puff, colour, band_, slip=10.0, n=28):
    """A huge soft cap: a band round the head, and over it a wide puffed crown, slipped over one brow."""
    b = am.Built("Hat")
    c = Vector(base)
    shade = lit_round(colour, n, low=0.66, high=1.14)
    rings = [ring(c, r_in, c.z - 0.02, n), ring(c, r_in + 0.03, c.z + 0.0, n), ring(c, r_in + 0.03, c.z + 0.14, n),
             ring(c, r_in + 0.01, c.z + 0.16, n)]
    for r, z in ((puff * 0.92, 0.26), (puff, 0.4), (puff * 0.96, 0.52), (puff * 0.8, 0.62), (puff * 0.5, 0.69), (0.0, 0.71)):
        rings.append(ring((c.x, c.y - 0.12, 0), r, c.z + z, n, lambda a: 0.03 * math.sin(5 * a)))

    def colours(i, k):
        if i < 3:
            return lit_round(band_, n)(k)
        if i == 3:
            return tone(colour, 0.5)
        if i == 4:
            return tone(colour, 0.62)        # the puff's underside
        return shade(k)

    b.tube(rings, colours, caps=(tone(colour, 0.3), None), smooth=True)
    turn = Matrix.Rotation(math.radians(-slip), 3, "Y") @ Matrix.Rotation(math.radians(-6), 3, "X")
    for v in b.bm.verts:
        v.co = c + turn @ (v.co - c)
    # a small stem at its top
    return b


def long_sleeves(block, cloth, cuff, inside=None):
    """A sleeve past the hand: the whole arm in cloth, a cuff turned back at its end, its opening dark."""
    w = block.wrap
    w.lay(w.rect(-9, 0.0, 9, 2.0), cloth)
    band(w, 0.0, 0.26, cuff, tone(cuff, 0.5))
    for p in block.sides:
        creases(p, [[(-0.4, 1.0), (0.0, 0.88), (0.38, 0.94)], [(-0.36, 0.56), (0.02, 0.46), (0.4, 0.52)],
                    [(-0.42, 1.6), (-0.05, 1.5), (0.36, 1.56)]], 0.36)
        dark(p, p.soft(p.rect(-9, 0.26, 9, 0.3), 0.02), 0.25)
    shadow(block, 0.26, low=0.0)
    lit(block)
    block.faces["bottom"].px[:] = rgb(tone(cloth, 0.3) if inside is None else inside)
    block.faces["top"].px[:] = rgb(cloth)


def legs(b, trouser, boot, seed, wraps=None):
    for i, key in enumerate(("rh", "lh")):
        g = b[key]
        for p in g.sides:
            creases(p, [[(-0.4, 1.66), (-0.05, 1.54), (0.36, 1.6)], [(-0.36, 1.12), (0.0, 1.0), (0.38, 1.06)]], 0.26)
        shoe(g, boot, "#2A211C", tone(boot, 1.25), tall=0.42)
        band(g.wrap, 0.38, 0.44, tone(boot, 0.8), tone(boot, 0.5))
        shadow(g, 0.26, low=0.0)
        lit(g, 0.08)
        grain(g, seed=seed + i)


def figure(joints, folder, b, head, hair, built):
    made = rt.figure(joints, folder, b, head, hair)
    for piece in built:
        made[piece.name] = piece.build(folder)
        wt.on(joints, "neck" if piece.name == "Hat" else "root", made[piece.name])
    outward(made.get("Hat"))
    see_through(made.get("LanternGlass"), 0.28)
    glowing(made.get("LanternFlame"), 2.5)
    return made


def outward(obj):
    """A closed piece the right way out: the kit's normals guess turns a thin, drooping brim inside out, and the
    game draws only the faces' fronts. Its volume is below zero when it's inside out."""
    if obj is None:
        return
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    volume = sum(f.verts[0].co.dot(f.verts[i].co.cross(f.verts[i + 1].co)) for f in bm.faces for i in range(1, len(f.verts) - 1))
    if volume < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:], flip_multires=False)
        bm.to_mesh(obj.data)
    bm.free()


def see_through(obj, alpha):
    """The glass, faint enough to see the flame through."""
    if obj is None:
        return
    m = obj.active_material
    for node in m.node_tree.nodes:
        if node.type == "BSDF_PRINCIPLED":
            node.inputs["Alpha"].default_value = alpha
    for attr, value in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
        if hasattr(m, attr):
            try:
                setattr(m, attr, value)
            except TypeError:
                pass
    m.use_backface_culling = False


def glowing(obj, strength):
    """The flame lights itself: its picture as its emission."""
    if obj is None:
        return
    m = obj.active_material
    tree = m.node_tree
    tex = next((n for n in tree.nodes if n.type == "TEX_IMAGE"), None)
    bsdf = next((n for n in tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if tex is None or bsdf is None:
        return
    key = "Emission Color" if "Emission Color" in bsdf.inputs else "Emission"
    tree.links.new(tex.outputs["Color"], bsdf.inputs[key])
    bsdf.inputs["Emission Strength"].default_value = strength


# --- A, the first-year -------------------------------------------------------------------------------------------------

def take_a(joints, folder, face_draw=None, fitted=False, lamp=None):
    """`face_draw(paint, skin)`: his own face, in place of the kit's; `fitted`: the hair laid on a scalp fitted to his
    head (Kirra's, AR60), its rim tucked in; `lamp()`: the lantern's pieces, in place of the takes' (pip_make.py)."""
    skin, cream, green, ochre, brown, boot = "#F3D2B8", "#EEE4CD", "#2F5D49", "#D69A3C", "#4A3428", "#5A3E2E"
    edge = tone(cream, 0.55)
    b = blocks_of({"torso": cream, "rs": cream, "ls": cream, "rh": brown, "lh": brown})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the tunic, closed down the middle, a soft fold either side
    line(f, [(0.0, 1.5), (0.02, 0.9), (0.0, 0.42)], 0.016, edge, 0.7)
    creases(f, [[(-0.6, 1.2), (-0.5, 0.9), (-0.56, 0.5)], [(0.6, 1.2), (0.5, 0.9), (0.56, 0.5)]], 0.36)
    creases(back, [[(-0.6, 1.2), (-0.5, 0.9), (-0.56, 0.5)], [(0.6, 1.2), (0.5, 0.9), (0.56, 0.5)]], 0.36)
    # the green mantle over the shoulders, its hem in points, an ochre edge, a clasp at the throat
    w.lay(w.rect(-9, 1.42, 9, 2.0), green)
    for p, pts in ((f, [(-1, 1.44), (-0.6, 1.3), (-0.3, 1.42), (0.0, 1.26), (0.3, 1.42), (0.6, 1.3), (1, 1.44)]),
                   (back, [(-1, 1.44), (-0.5, 1.18), (0.0, 1.3), (0.5, 1.18), (1, 1.44)])):
        p.lay(p.poly(pts + [(1, 1.46), (-1, 1.46)]), green)
        line(p, pts, 0.028, ochre, 1.0)
        creases(p, [[(-0.7, 1.9), (-0.6, 1.7), (-0.62, 1.5)], [(0.7, 1.9), (0.6, 1.7), (0.62, 1.5)]], 0.4)
    band(w, 1.92, 2.0, tone(green, 0.8), tone(green, 0.5))
    f.lay(f.ellipse(0.0, 1.82, 0.09, 0.08), ochre)
    f.lay(f.ellipse(0.0, 1.82, 0.04, 0.035), tone(ochre, 0.6))
    # a wide brown belt, its buckle
    band(w, 0.28, 0.44, brown, tone(brown, 0.5))
    f.lay(f.rect(-0.1, 0.29, 0.1, 0.43), ochre)
    f.lay(f.rect(-0.06, 0.32, 0.06, 0.4), brown)
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=41)
    if fitted:   # the finish: the mantle over his shoulders, so the game's camera sees green there, never a cream square
        t.faces["top"].px[:] = rgb(green)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        long_sleeves(a, cream, green)
        w = a.wrap   # the mantle over the shoulder's top
        w.lay(w.rect(-9, 1.72, 9, 2.0), green)
        band(w, 1.7, 1.74, ochre, None)
        grain(a, seed=42 + i)
        a.faces["top"].px[:] = rgb(green)

    legs(b, brown, boot, 44)

    head = am.Head(skin)
    if face_draw:
        face_draw(head.paint, skin)
    else:
        face(head, dict(skin=skin, iris="#E08A2A", eye_w=0.34, eye_h=0.25, eye_x=0.27, eye_y=0.5, tilt=-0.01, shut=0.0,
                        brow_y=0.74, brow_tilt=-0.02, brow="#8A3E1C", mouth=[(-0.04, 0.236), (0.0, 0.226), (0.045, 0.24)]))
    hair = am.Hair("#8E3A1B", "#F2A260", seed=47, band=(0.42, 0.1, 0.25), **({"scalp": am.HEAD_EGG} if fitted else {}))
    # the mass under the hat, its own points spilling below the brim: a fringe across the brow, locks at the temples
    # fitted: the rim on the head, not 0.04 off it, and the back down to the nape, as Kirra's round 2 (AR60)
    tips = ((180, 20, 12), (152, 14, 14), (208, 14, 14), (124, 14, 12), (236, 14, 12), (84, 18, 18), (-84, 18, 18),
            (0, 13, 19), (-26, 12, 17), (24, 12, 18), (-50, 11, 13), (48, 11, 13))
    if fitted:   # the back's points short, so its rim lies even down to the collar with no skin between them
        tips = tuple((a, w, round(l * 0.4)) if 100 < a < 260 else (a, w, l) for a, w, l in tips)
    hair.mass(am.hairline(front=4.92, temple=4.5 if fitted else 4.56, nape=3.98 if fitted else 4.28), (0, 4), opening=0.1, seed=47,
              tips=tips,
              lift=0.05, off=(0.0 if fitted else 0.04, 0.1), **(dict(ease=2.0, tuck=0.09) if fitted else {}))
    top = hat((0.0, -0.06, 5.0), 0.8, 1.22, 1.3, green, ochre, tip_back=0.95, pitch=9.0)
    return figure(joints, folder, b, head, hair, [top, *(lamp() if lamp else lantern())])


# --- B, the prodigy ----------------------------------------------------------------------------------------------------

def take_b(joints, folder):
    skin, ivory, char, gold = "#F2CFB4", "#F1ECDF", "#2C2E36", "#D9A441"
    edge = tone(ivory, 0.55)
    b = blocks_of({"torso": ivory, "rs": ivory, "ls": ivory, "rh": char, "lh": char})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the jacket, double-breasted: its front edge from his left collar down to his right hip, two rows of gold buttons
    f.lay(f.poly([(-0.2, 2.0), (0.2, 2.0), (0.34, 0.3), (0.2, 0.0), (-0.12, 0.0)]), tone(ivory, 0.95))
    line(f, [(0.2, 2.0), (0.34, 1.0), (0.3, 0.0)], 0.03, char, 1.0)
    for y in (1.5, 1.1, 0.7):
        for x in (-0.12, 0.52):
            f.lay(f.ellipse(x, y, 0.055, 0.05), gold)
            f.lay(f.ellipse(x - 0.012, y + 0.014, 0.02, 0.018), mix(gold, "#FFFFFF", 0.5))
    creases(f, [[(-0.9, 1.6), (-0.7, 1.4), (-0.5, 1.4)], [(0.9, 0.9), (0.7, 0.66), (0.6, 0.5)]], 0.34)
    creases(back, [[(-0.9, 1.4), (-0.7, 1.1), (-0.6, 0.7)], [(0.9, 1.4), (0.7, 1.1), (0.6, 0.7)]], 0.34)
    # the high collar, charcoal lined in gold, and a charcoal hem
    band(w, 1.78, 2.0, char, gold, wide=0.016)
    band(w, 0.0, 0.14, char, gold, wide=0.012)
    # a short cape from the shoulders behind, charcoal
    back.lay(back.poly([(-1, 2.0), (1, 2.0), (1, 0.9), (0.5, 0.74), (0.0, 0.86), (-0.5, 0.74), (-1, 0.9)]), char)
    line(back, [(-1, 0.9), (-0.5, 0.74), (0.0, 0.86), (0.5, 0.74), (1, 0.9)], 0.024, gold, 1.0)
    creases(back, [[(-0.5, 1.8), (-0.4, 1.3), (-0.5, 0.9)], [(0.5, 1.8), (0.4, 1.3), (0.5, 0.9)]], 0.5)
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=51)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        long_sleeves(a, ivory, char)
        band(a.wrap, 0.26, 0.3, gold, None)
        grain(a, seed=52 + i)

    legs(b, char, "#3A2C26", 54)

    head = am.Head(skin)
    face(head, dict(skin=skin, iris="#F07A2A", eye_w=0.33, eye_h=0.22, eye_x=0.27, eye_y=0.51, tilt=0.02, shut=0.12,
                    brow_y=0.73, brow_tilt=0.02, brow="#1E1512", mouth=[(-0.04, 0.232), (0.0, 0.228), (0.05, 0.236)]))
    hair = am.Hair("#121012", "#4A4542", seed=57, band=(0.5, 0.1, 0.32))
    hair.mass(am.hairline(front=4.96, temple=4.6, nape=4.3), (0, 10), opening=0.16, seed=57,
              tips=((180, 18, 10), (150, 14, 12), (210, 14, 12), (82, 18, 16), (-82, 18, 16), (-16, 12, 16), (14, 10, 12)),
              lift=0.08, off=(0.04, 0.14))
    # swept up and back like a flame: a few solid locks rising off the crown, each one smooth tapered piece
    for a, ph, length, up, back, side, r in ((0, 14, 0.8, 1.0, 0.9, 0.0, 0.2), (-34, 22, 0.68, 0.8, 0.9, -0.35, 0.18),
                                             (34, 22, 0.68, 0.8, 0.9, 0.35, 0.18), (-70, 42, 0.54, 0.4, 0.8, -0.7, 0.15),
                                             (70, 42, 0.54, 0.4, 0.8, 0.7, 0.15)):
        p0, nrm, _ = hair.at(a, ph)
        d = (nrm * 0.6 + Vector((side, -back, up))).normalized()
        bend = Vector((0, -0.3, -0.25))
        pts = [p0 - nrm * 0.06, p0 + d * length * 0.33 + nrm * 0.04, p0 + d * length * 0.66 + bend * 0.12 * length, p0 + d * length + bend * 0.35 * length]
        hair.tail(pts, ((0, r * 0.9), (0.25, r), (1.0, 0.0)), n=10, around=8, seed=57 + abs(a))
    return figure(joints, folder, b, head, hair, lantern())


# --- C, the hearth kid -------------------------------------------------------------------------------------------------

def take_c(joints, folder):
    skin, white, brick, sage, ochre = "#F4D4BC", "#F2EEE6", "#8A4A2E", "#7D8F6A", "#D49A3A"
    edge = tone(brick, 0.5)
    b = blocks_of({"torso": brick, "rs": brick, "ls": brick, "rh": sage, "lh": sage})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the coat open over the white shirt, its lapels, toggles across
    f.lay(f.poly([(-0.36, 2.0), (0.36, 2.0), (0.3, 0.0), (-0.3, 0.0)]), white)
    for s in (-1, 1):
        f.lay(f.poly([(s * 0.36, 2.0), (s * 0.62, 2.0), (s * 0.42, 1.4), (s * 0.3, 1.36)]), tone(brick, 1.15))
        line(f, [(s * 0.36, 2.0), (s * 0.3, 1.36), (s * 0.3, 0.0)], 0.022, edge, 0.9)
        creases(f, [[(s * 0.9, 1.6), (s * 0.74, 1.4), (s * 0.66, 1.0)]], 0.4)
    for y in (1.3, 0.9):
        line(f, [(-0.42, y), (0.42, y)], 0.03, ochre, 1.0)
    f.lay(f.ellipse(0.0, 1.88, 0.12, 0.08), tone(white, 0.85))
    creases(back, [[(-0.9, 1.4), (-0.7, 1.1), (-0.6, 0.7)], [(0.9, 1.4), (0.7, 1.1), (0.6, 0.7)], [(-0.3, 0.6), (0.0, 0.5), (0.3, 0.6)]], 0.36)
    band(w, 0.0, 0.12, tone(brick, 0.8), edge)
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=61)
    neck(t, skin)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        long_sleeves(a, brick, white, inside=tone(brick, 0.3))
        grain(a, seed=62 + i)

    legs(b, sage, "#5A3E2E", 64)

    head = am.Head(skin)
    face(head, dict(skin=skin, iris="#4FA05A", eye_w=0.35, eye_h=0.26, eye_x=0.27, eye_y=0.5, tilt=-0.015, shut=0.0,
                    brow_y=0.75, brow_tilt=-0.02, brow="#8A6430", mouth=[(-0.05, 0.24), (0.0, 0.228), (0.05, 0.24)]))
    hair = am.Hair("#9A6E34", "#F3D490", seed=67, band=(0.42, 0.1, 0.3))
    hair.mass(am.hairline(front=4.92, temple=4.56, nape=4.24), (0, 4), opening=0.1, seed=67,
              tips=((180, 22, 14), (140, 16, 16), (220, 16, 16), (84, 20, 18), (-84, 20, 18), (100, 12, 10), (-100, 12, 10),
                    (-30, 16, 20), (6, 14, 17), (34, 12, 14)),
              lift=0.05, off=(0.04, 0.1))
    top = cap((0.0, -0.04, 4.96), 0.8, 1.08, ochre, tone(brick, 0.9), slip=16.0)
    return figure(joints, folder, b, head, hair, [top, *lantern()])


TAKES = {"Kirra": kt.take_a, "A": take_a, "B": take_b, "C": take_c}


def measured(key, made):
    """The hair's (or the hat's) top over the crown, in heads, and each built piece's triangles."""
    for name in ("hair", "Hat"):
        if name in made:
            top = max(v.co.z for v in made[name].data.vertices)
            print(f"{key}: the {name} stands {(top - kt.CROWN) / 1.25:.2f} of a head over the crown (top {top:.2f})")
    for name, o in made.items():
        if name not in ("torso", "rs", "ls", "rh", "lh", "head", "hair"):
            print(f"{key}: {name} {sum(len(f.vertices) - 2 for f in o.data.polygons)} triangles")


if __name__ == "__main__":
    rt.TAKES, rt.SAID, rt.WHO = TAKES, SAID, tuple(TAKES)
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "sheet"
    if mode == "takes":
        rt.takes_run(OUT, rest[1:] or list(TAKES), finish=measured)
    elif mode == "shade":
        rt.shade_run(OUT)
    elif mode == "sheet":
        rt.sheet_run(OUT, WORDS, BESIDE)
