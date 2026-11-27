"""The Shade's design sheet (AR2, delivery 1): one body, four masks, five colours, as a blockout on the R6 body.

blender.exe -b --factory-startup --python tools/blender/shade_sheet.py -- <out_dir> [small]

The idea: a festival coat with nobody in it, lit from inside like a paper lantern. The collar, the cuffs and the hems
are open and the light shows in them, in the colour of the Shade's type. The mask hangs where a face should be, tied
round nothing. Workbench only, so no GPU turn. Studs, X right, Y forward, Z up, the Shade faces +Y, and every piece
hangs from one of R6's six parts at the engine's own pivots, as rook_sheet.py's do (its shapes and sheet tools are
used here). The glow is drawn on the picture: the lit pieces are found in a flat pass and given a halo.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402

PALETTE = {"Void": "#1B1728", "VoidLift": "#2C2542", "Paper": "#EFE6D2", "PaperShade": "#C9BA9C", "Ink": "#100D17"}
# The five types, as the director's package names them (blue, red, orange, purple, green). The exact colours are a
# proposal: AR3's gems fix them, and the Shade takes whatever they become.
TYPES = {"Strength": "#EA4B4F", "Endurance": "#F4902A", "Agility": "#3F9DF2", "Intelligence": "#A470F2", "Technique": "#42CC7E"}
MASKS = {"Brawler": ("Strength", "round, grinning"), "Guard": ("Endurance", "square, with a brow"),
         "Dasher": ("Agility", "long, pointed"), "Support": ("Intelligence", "a half-mask, veiled")}
MASK_Y = 0.76  # the mask's back face: it hangs just clear of the collar
# Set by shade_model.py: the Brawler's cuts and teeth, and the Guard's, the Dasher's (AR52) and the Support's (AR58)
# pieces, are built in their
# shapes as first shipped (AR2), each carrying its move to today's shape, so the atlas packs as it shipped and only
# the masks' own texels change (pinned, settle).
SHIPPED_PACK = False
PIVOTS = rs.PIVOTS
B = rs.B


def materials(kind):
    made = {}
    for name, code in {**PALETTE, "Glow": TYPES[kind]}.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


# --- shapes ---------------------------------------------------------------------------------------------------

def plate(name, outline, y0, thick, material):
    """A flat piece cut to an outline (x, z), `thick` deep from y0 forward."""
    bm = bmesh.new()
    back = [bm.verts.new((x, y0, z)) for x, z in outline]
    front = [bm.verts.new((x, y0 + thick, z)) for x, z in outline]
    n = len(outline)
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    for i in range(n):
        bm.faces.new((back[i], back[(i + 1) % n], front[(i + 1) % n], front[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    return bl.object_from_bmesh(name, bm, material)


def arc(cx, cz, r, a0, a1, n):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cz + r * math.sin(math.radians(a0 + (a1 - a0) * i / n)))
            for i in range(n + 1)]


def almond(cx, cz, a, b, n=8):
    """An almond hole: a lens of two arcs, `a` half wide and `b` half tall, its corners level at cz."""
    rr = (a * a + b * b) / (2 * b)
    t = math.degrees(math.asin(a / rr))
    return arc(cx, cz - (rr - b), rr, 90 - t, 90 + t, n)[:-1] + arc(cx, cz + (rr - b), rr, 270 - t, 270 + t, n)[:-1]


def pinned(now, then):
    """`then`, a piece in its shape as first shipped, carrying in the point attribute `move` the way to `now`, its
    shape today, which is removed. The unwrap packs the shipped shapes and settle() then moves the points, so a new
    cut keeps its old cut's place on the atlas and no other island moves. Both have the same points in the same order
    round the same way, so the shipped triangles stay whole on today's shape."""
    a, b = then.data.vertices, now.data.vertices
    if len(a) != len(b):
        raise ValueError(f"{then.name}: {len(a)} points as shipped, {len(b)} today")
    move = then.data.attributes.new("move", "FLOAT_VECTOR", "POINT")
    for i, (p, q) in enumerate(zip(a, b)):
        move.data[i].vector = q.co - p.co
    mesh = now.data
    bpy.data.objects.remove(now)
    bpy.data.meshes.remove(mesh)
    return then


def settle(obj):
    """Moves each point by its `move`, then drops the attribute. Returns how many points moved."""
    mesh = obj.data
    move = mesh.attributes.get("move")
    if move is None:
        return 0
    d = np.empty(len(mesh.vertices) * 3, np.float32)
    move.data.foreach_get("vector", d)
    co = np.empty_like(d)
    mesh.vertices.foreach_get("co", co)
    mesh.vertices.foreach_set("co", co + d)
    mesh.attributes.remove(move)
    mesh.update()
    return int(np.count_nonzero(np.abs(d.reshape(-1, 3)).max(1) > 1e-7))


def disc(cx, cz, r, n=16):
    return arc(cx, cz, r, 0, 360, n)[:-1]


def cut(name, outline, m):
    """A hole in the mask, as the light behind it: a thin lit piece on its face."""
    return plate(name, outline, MASK_Y + 0.14, 0.016, m["Glow"])


def ties(m, z, half):
    """What holds the mask: two strings from its edges to a knot behind the collar, tied round nothing, and the
    knot's two short tails, which end at the collar."""
    made = [rs.slab("Knot", (0, -0.74, z), (0.36, 0.16, 0.22), m["Paper"])]
    for e in (-1, 1):
        ax, ay, bx, by, t = e * half, MASK_Y + 0.05, e * 0.16, -0.7, e * 0.05
        made.append(rs.hexa("String", [(ax - t, ay, z - 0.035), (ax, ay, z - 0.035), (bx, by, z - 0.035), (bx - t, by, z - 0.035),
                                       (ax - t, ay, z + 0.035), (ax, ay, z + 0.035), (bx, by, z + 0.035), (bx - t, by, z + 0.035)],
                            m["PaperShade"]))
        made.append(rs.slab("Tail", (e * 0.16, -0.79, z - 0.4), (0.17, 0.04, 0.66), m["Paper"], rot=(0, e * 7, 0)))
    return made


def rim(outline, m, by=1.08):
    """The mask's backing: its own outline a little larger, in the darker paper, so its edge is drawn on any ground."""
    cx, cz = sum(x for x, _ in outline) / len(outline), sum(z for _, z in outline) / len(outline)
    return plate("Rim", [(cx + (x - cx) * by, cz + (z - cz) * by) for x, z in outline], MASK_Y - 0.03, 0.05, m["PaperShade"])


def raised(name, outline, y0, thick, material, inset=0.8, edge=0.05):
    """A mask's face as pressed paper: cut to an outline (x, z), its edge `edge` deep, then folded in to a flat
    front `thick` forward of y0, the outline drawn in by `inset`."""
    cx, cz = sum(x for x, _ in outline) / len(outline), sum(z for _, z in outline) / len(outline)
    bm = bmesh.new()
    back = [bm.verts.new((x, y0, z)) for x, z in outline]
    side = [bm.verts.new((x, y0 + edge, z)) for x, z in outline]
    front = [bm.verts.new((cx + (x - cx) * inset, y0 + thick, cz + (z - cz) * inset)) for x, z in outline]
    n = len(outline)
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((back[i], back[j], side[j], side[i]))
        bm.faces.new((side[i], side[j], front[j], front[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    return bl.object_from_bmesh(name, bm, material)


def kite(z):
    """Half the Dasher's width at a height: a kite, widest at 5.48, its points at 3.2 and 6.6."""
    return 0.64 * ((6.6 - z) / 1.12 if z >= 5.48 else (z - 3.2) / 2.28)


def creased(z, x, y0, rise):
    """Where the Dasher's folded face is, forward of y0: a crease down its middle, `rise` proud, flat to each edge."""
    half = max(kite(z), 1e-6)
    return y0 + 0.05 + (rise - 0.05) * max(0.0, 1 - abs(x) / half)


def folded(name, y0, rise, material):
    """The Dasher's face: a kite of paper folded once, down its middle."""
    bm = bmesh.new()
    rim_pts = [(-0.64, 5.48), (0.0, 3.2), (0.64, 5.48), (0.0, 6.6)]
    back = [bm.verts.new((x, y0, z)) for x, z in rim_pts]
    front = [bm.verts.new((x, y0 + 0.05, z)) for x, z in rim_pts]
    low, high = bm.verts.new((0, y0 + rise, 3.75)), bm.verts.new((0, y0 + rise, 6.2))
    left, bottom, right, top = front
    for face in ((left, bottom, low, high), (bottom, right, high, low), (right, top, high), (top, left, high)):
        bm.faces.new(face)
    bm.faces.new(list(reversed(back)))
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((back[i], back[j], front[j], front[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def laid(name, outline, y0, rise, material, lift=0.014):
    """A cut or a painted mark laid on the Dasher's folded face: one face, following the fold."""
    bm = bmesh.new()
    bm.faces.new([bm.verts.new((x, creased(z, x, y0, rise) + lift, z)) for x, z in outline])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = bl.object_from_bmesh(name, bm, material)
    if obj.data.polygons[0].normal.y < 0:
        obj.data.flip_normals()
    return obj


def turned(points, degrees, about):
    c, s_ = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return [(about[0] + (x - about[0]) * c - (z - about[1]) * s_, about[1] + (x - about[0]) * s_ + (z - about[1]) * c) for x, z in points]


def mask(kind, m):
    """The four masks, each about two studs across: larger than a head, as a festival mask is. Each has its own
    outline, so a behaviour is told by a shape before a colour. All four are pressed or folded paper, with the eyes
    and the mouth cut through to the light. None carries ink (AR47, AR52, AR58)."""
    paper, y = m["Paper"], MASK_Y
    if kind == "Brawler":
        # Cut by hand from one sheet: not quite round, a tab each side for the strings. Two level almond holes, one
        # wider than the other, and a lopsided grin behind four paper teeth no two alike, as the stage tile draws it
        # (stage_screen.py, mask). No ink: the content check's block (AR42, 02:31) found the brows low at the middle
        # nearing a known meme face, so AR47 took them off, and research matched the model to the tile (18:32): the
        # arched eyes became the almond holes, the grin narrowed from 0.64 to 0.5, and the nose's stroke went.
        c = 4.85
        grin_r = 0.5
        radii = (1.0, 0.96, 1.03, 0.98, 1.02, 0.95, 1.0, 1.04, 0.97, 1.01, 0.96, 1.02)
        face = []
        for i, r in enumerate(radii):
            a = math.radians(15 + 30 * i)
            face.append((r * math.cos(a), c + r * math.sin(a)))
            if i == 5:
                face += [(-1.26, c + 0.17), (-1.26, c - 0.15)]
            if i == 11:
                face += [(1.26, c - 0.17), (1.26, c + 0.15)]
        def grin(r, at):
            low = arc(0.02, at, r, 200, 340, 12)
            return cut("Grin", turned(low + [(x, low[0][1] + (z - low[0][1]) * 0.3) for x, z in reversed(low[1:-1])],
                                      6, (0, c)), m)

        def eye(e, now):  # today's almond, or as shipped: an arc over a half-size arc, 18 points either way
            if now:
                a, b = {-1: (0.2, 0.125), 1: (0.17, 0.105)}[e]
                return cut("Eye", almond(e * 0.38, c + 0.22, a, b, n=9), m)
            r = {-1: 0.25, 1: 0.19}[e]
            return cut("Eye", arc(e * 0.38, c + 0.2, r, 15, 165, 8) + arc(e * 0.38, c + 0.2, r * 0.5, 165, 15, 8), m)

        def tooth(x, w, dz, tilt, spread):
            return rs.slab("Tooth", (x * spread, y + 0.16, c - 0.36 + dz), (w, 0.02, 0.5), paper, rot=(0, tilt, 0))

        teeth_at = ((-0.4, 0.09, 0.0, 4), (-0.14, 0.06, -0.02, -3), (0.14, 0.1, 0.02, 2), (0.4, 0.06, 0.05, 7))
        if SHIPPED_PACK:
            cuts = [pinned(grin(grin_r, c), grin(0.64, c + 0.1)), *(pinned(eye(e, True), eye(e, False)) for e in (-1, 1)),
                    *(pinned(tooth(*t, grin_r / 0.64), tooth(*t, 1.0)) for t in teeth_at)]
        else:
            cuts = [grin(grin_r, c), eye(-1, True), eye(1, True), *(tooth(*t, grin_r / 0.64) for t in teeth_at)]
        return [raised("Mask", face, y, 0.14, paper, inset=0.84), rim(face, m, 1.07), *cuts, *ties(m, c, 1.22)]
    if kind == "Guard":
        # A square of paper, a little wider at its top, a tab each side for the strings. Its brow is cut, not drawn
        # (AR52): two long holes that nearly meet, each one's top edge falling to the middle, so the paper left above
        # them is the brow, and a shut slot under them. No ink and no added brow: AR2's two brow blocks and the ink
        # bars under its eyes are gone. Packed as shipped, each new piece is an old one moved (pinned): the brow
        # blocks became the tabs, and the ink bars are tucked inside the pressed paper, where nothing sees them.
        face = [(-0.9, 4.2), (-0.66, 3.95), (0.66, 3.95), (0.9, 4.2), (1.0, 5.75), (-1.0, 5.75)]

        def eye(e):
            hole = rs.slab("Eye", (e * 0.41, y + 0.148, 5.02), (0.66, 0.016, 0.3), m["Glow"])
            for v in hole.data.vertices:  # the top edge falls 0.19 from the outer end to the inner
                if v.co.z > 5.02:
                    v.co.z -= 0.19 * (0.74 - abs(v.co.x)) / 0.66
            return hole

        tabs = [rs.slab("Tab", (e * 1.0, y + 0.03, 5.0), (0.24, 0.05, 0.3), m["PaperShade"]) for e in (-1, 1)]
        eyes = [eye(e) for e in (-1, 1)]
        mouth = rs.slab("Mouth", (0, y + 0.148, 4.33), (0.62, 0.016, 0.1), m["Glow"])
        if not SHIPPED_PACK:
            return [raised("Mask", face, y, 0.14, paper, inset=0.88), rim(face, m, 1.06), *tabs, *eyes, mouth, *ties(m, 5.0, 0.92)]
        was = [(-0.95, 4.2), (-0.7, 3.95), (0.7, 3.95), (0.95, 4.2), (0.95, 5.75), (-0.95, 5.75)]
        brows = [rs.slab("Brow", (e * 0.6, y + 0.22, 5.3), (1.3, 0.44, 0.34), m["PaperShade"], rot=(0, -13 * e, 0)) for e in (-1, 1)]
        bars = [rs.slab("InkBar", (e * 0.46, y + 0.148, 4.66), (0.4, 0.016, 0.06), m["Ink"]) for e in (-1, 1)]
        tucked = [rs.slab("Tucked", (e * 0.3, y + 0.07, 4.6), (0.2, 0.02, 0.04), m["Ink"]) for e in (-1, 1)]
        slots = [rs.slab("Eye", (e * 0.46, y + 0.148, 4.9), (0.5, 0.016, 0.13), m["Glow"]) for e in (-1, 1)]
        return [pinned(raised("Mask", face, y, 0.14, paper, inset=0.88), raised("Mask", was, y, 0.14, paper, inset=0.88)),
                pinned(rim(face, m, 1.06), rim(was, m, 1.06)),
                *(pinned(now, then) for now, then in zip(tabs, brows)), *(pinned(now, then) for now, then in zip(tucked, bars)),
                *(pinned(now, then) for now, then in zip(eyes, slots)),
                pinned(mouth, rs.slab("Mouth", (0, y + 0.148, 4.36), (0.95, 0.016, 0.11), m["Glow"])), *ties(m, 5.0, 0.92)]
    if kind == "Dasher":
        # A long kite of paper folded once down its middle: one point over the chest, one above the collar. Two
        # slanted blades are cut through it and nothing else is on it (AR52): AR2's four ink marks are gone. Packed as
        # shipped, the marks are tucked inside the fold and the eyes are the old eyes moved.
        face = [(-0.64, 5.48), (0, 3.2), (0.64, 5.48), (0, 6.6)]
        rise = 0.24

        def eye(e, now):
            blade = [(e * 0.08, 5.1), (e * 0.5, 5.36), (e * 0.52, 5.6), (e * 0.08, 5.3)]
            return laid("Eye", blade if now else [(e * 0.1, 5.16), (e * 0.48, 5.38), (e * 0.48, 5.52), (e * 0.1, 5.3)], y, rise, m["Glow"])

        if not SHIPPED_PACK:
            return [folded("Mask", y, rise, paper), rim(face, m, 1.07), eye(-1, True), eye(1, True), *ties(m, 5.5, 0.6)]
        marks = []
        for e in (-1, 1):
            for j in range(2):
                then = laid("InkMark", [(e * 0.08, 4.5 - j * 0.34), (e * 0.3 - j * e * 0.05, 4.64 - j * 0.34),
                                        (e * 0.3 - j * e * 0.05, 4.72 - j * 0.34), (e * 0.08, 4.58 - j * 0.34)], y, rise, m["Ink"])
                z = 4.5 - j * 0.12
                bm = bmesh.new()
                bm.faces.new([bm.verts.new((x, y + 0.025, zz)) for x, zz in ((e * 0.06, z), (e * 0.2, z), (e * 0.2, z + 0.06), (e * 0.06, z + 0.06))])
                marks.append(pinned(bl.object_from_bmesh("Tucked", bm, m["Ink"]), then))
        return [folded("Mask", y, rise, paper), rim(face, m, 1.07), *(pinned(eye(e, True), eye(e, False)) for e in (-1, 1)),
                *marks, *ties(m, 5.5, 0.6)]
    # Support: a half-mask, a wide low band across the eyes that narrows to a point each side, and a veil hung under
    # it: a fringe of eight narrow strips of paper cut square, side by side in the band's plane and a hair apart, none quite
    # the length of the next. Two thin holes are cut through the band, each falling toward its outer end, and nothing
    # else is on it (AR58). AR2's band swept up at its ends and its slips met edge to edge: at 64 pixels they read as
    # horns over a beard (the content check's read), so the ends came down. Four long pointed slips read as fangs
    # under a brow (research's read), so the veil is many, narrow and square; and four in front of four shaded ones
    # still read as four, so all eight are one paper. Its round eyes are the thin holes now. Packed as shipped, each
    # piece is an old one moved: AR2's four slips are every other strip, their points flattened into the cut, and the
    # ink line on each is the strip beside it, in paper. No ink is left.
    band = [(-0.8, 4.55), (0.8, 4.55), (1.36, 4.9), (0.7, 5.12), (0, 5.17), (-0.7, 5.12), (-1.36, 4.9)]
    was = [(-0.8, 4.55), (0.8, 4.55), (1.4, 5.22), (0.7, 5.08), (0, 5.14), (-0.7, 5.08), (-1.4, 5.22)]
    edges = (-0.9, -0.45, 0.0, 0.45, 0.9)
    # The strips hang from the band's lower edge in its own front plane, as if slit from the one sheet: a strip laid
    # over the band's face left a crack a hundredth deep between them, which the bake lit and Hard painted ember.
    half, top, cuts = 0.085, 4.55, (3.52, 3.47, 3.55, 3.5, 3.46, 3.54, 3.49, 3.53)
    hung = []  # in the shipped order: a slip, its line, the next slip
    for j in range(4):
        x0, x1 = -0.7 + 0.4 * j, -0.5 + 0.4 * j  # 0.17 wide, 0.03 apart, under the whole of the band
        c0, c1 = cuts[2 * j], cuts[2 * j + 1]
        cut_flat = plate("Strip", [(x0 - half, top), (x0 + half, top), (x0 + half, c0), (x0, c0), (x0 - half, c0)], y + 0.11, 0.03, paper)
        boxed = rs.slab("Strip", (x1, y + 0.125, (top + c1) / 2), (top - c1, 0.03, 2 * half), paper, rot=(0, 90, 0))
        if not SHIPPED_PACK:
            hung += [cut_flat, boxed]
            continue
        a, b, low = edges[j], edges[j + 1], 3.5 if j % 2 else 3.3
        c = (a + b) / 2
        hung.append(pinned(cut_flat, plate("Slip", [(a * 0.86, 4.62), (b * 0.86, 4.62), (b, low + 0.22), (c, low), (a, low + 0.22)],
                                           y + (0.19 if j % 2 else 0.15), 0.03, paper)))
        hung.append(pinned(boxed, rs.slab("InkLine", (c, y + (0.225 if j % 2 else 0.185), low + 0.42), (0.26, 0.012, 0.045), paper)))

    def eye(e, now):  # today's thin hole, or as shipped: a round one, 12 points either way, round the same way
        if now:
            return cut("Eye", turned(almond(e * 0.46, 4.85, 0.3, 0.1, n=6), -e * 13, (e * 0.46, 4.85)), m)
        return cut("Eye", disc(e * 0.44, 4.86, 0.14, 12), m)

    if not SHIPPED_PACK:
        return [plate("Mask", band, y, 0.14, paper), rim(band, m, 1.06), *hung, eye(-1, True), eye(1, True), *ties(m, 4.9, 0.9)]
    return [pinned(plate("Mask", band, y, 0.14, paper), plate("Mask", was, y, 0.14, paper)), pinned(rim(band, m, 1.06), rim(was, m, 1.06)),
            *hung, *(pinned(eye(e, True), eye(e, False)) for e in (-1, 1)), *ties(m, 4.9, 0.9)]


# The Guard's turned corner (AR72, research's pick of B, 2026-11-27, 20:03): its top corner on the Guard's right (+x)
# folded over onto the face, the plainest of the masks given one more paper detail. It's made on the baked mask
# (shade_model.py, after the bake), since the flap takes the tabs' paper, already in the atlas: no map changes.
GUARD_FRONT = 0.9   # the Guard's face, in the model's y (its front is +y); the cuts' glowing slabs sit on it, to 0.92
GUARD_BODY_Y = 0.5  # the mask's paper, rim, tabs and cuts are in front of this; its ties are behind
GUARD_CORNER = ((0.52, 5.75), (1.0, 5.42), 172)  # the crease, from the top edge to the side (x, z), and the turn


def fold(me, a, b, degrees, over=False):
    """Folds a mask's paper along the line from a to b (x, z on the Guard's face), hinged on its front face: the part
    on the side away from the mask's middle turns `degrees` about the line, toward us when positive. `over`: it's
    turned right over and lies on the face. It's pressed paper-thin first (only its faces toward us kept, flattened
    onto the face's plane), or its rim turns forward as a little pyramid and shades the face; once over, its faces are
    turned to us again (a game mesh shows one side only) and take the tabs' paper."""
    bm = bmesh.new()
    bm.from_mesh(me)
    pa, pb = Vector((a[0], GUARD_FRONT, a[1])), Vector((b[0], GUARD_FRONT, b[1]))
    d = (pb - pa).normalized()
    n = d.cross(Vector((0, 1, 0))).normalized()          # across the line, in the face's plane
    if (Vector((0, GUARD_FRONT, 4.85)) - pa).dot(n) > 0:
        n = -n                                           # pointing away from the middle
    body = [f for f in bm.faces if f.calc_center_median().y > GUARD_BODY_Y]
    geom = list({v for f in body for v in f.verts}) + list({e for f in body for e in f.edges}) + body
    cut_ = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=pa, plane_no=n)["geom_cut"]
    bmesh.ops.split_edges(bm, edges=[e for e in cut_ if isinstance(e, bmesh.types.BMEdge)])
    flap = [f for f in bm.faces if f.calc_center_median().y > GUARD_BODY_Y and (f.calc_center_median() - pa).dot(n) > 1e-4]
    if over:
        bmesh.ops.delete(bm, geom=[f for f in flap if f.normal.y < 0.2], context="FACES")
        flap = [f for f in flap if f.is_valid]
        for v in {v for f in flap for v in f.verts}:
            v.co.y = GUARD_FRONT
    far = {v for f in flap for v in f.verts}

    def turn(deg):
        return Matrix.Translation(pa) @ Matrix.Rotation(math.radians(deg), 4, d) @ Matrix.Translation(-pa)

    sign = 1 if (turn(90) @ (pa + n)).y > GUARD_FRONT else -1   # positive turns toward us (+y)
    m = turn(sign * degrees)
    for v in far:
        v.co = m @ v.co
    bm.normal_update()
    if over:
        for v in far:
            v.co.y += 0.03                               # clear of the face and the cuts' slabs (to 0.92)
        bmesh.ops.reverse_faces(bm, faces=[f for f in flap if f.normal.y < 0])
        bm.normal_update()
        uv = bm.loops.layers.uv.active
        tab = next(f for f in bm.faces if f.normal.y > 0.9 and (c := f.calc_center_median()).y > 0.8
                   and abs(abs(c.x) - 1.0) < 0.05)
        paper = sum((loop[uv].uv for loop in tab.loops), Vector((0, 0))) / len(tab.loops)
        for f in flap:
            for loop in f.loops:
                loop[uv].uv = paper
    bm.to_mesh(me)
    bm.free()


def turn_corner(me):
    """The Guard's baked mask, its corner turned over (AR72). Once only: the mesh is marked."""
    if me.get("turned_corner"):
        raise SystemExit("turn_corner: this Guard mask's corner is already turned")
    a, b, degrees = GUARD_CORNER
    fold(me, a, b, degrees, over=True)
    me["turned_corner"] = True


def build(scene, kind, m):
    """The Shade, standing square, in one mask. Returns the joints: empties at R6's pivots, each piece on its part."""
    joints = {}
    for name, at in PIVOTS.items():
        j = bpy.data.objects.new(name, None)
        scene.collection.objects.link(j)
        j.location = at
        j.rotation_mode = "QUATERNION"
        if name != "root":
            j.parent = joints["root"]
            j.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS["root"]))
        joints[name] = j

    def on(part, *objs):
        for o in objs:
            o.parent = joints[part]
            o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[part]))

    # the coat: a bell from the shoulders to just over the legs, its hem lit, a lit seam down the front where it
    # doesn't quite close, and a round lit mark on its back, like a lantern's
    on("root",
       rs.loft("Coat", [(1.72, 0, 0, 2.3, 1.42), (2.6, 0, 0, 2.12, 1.16), (4.0, 0, 0, 2.06, 1.06)], m["Void"], n=B),
       rs.loft("Hem", [(1.7, 0, 0, 2.36, 1.48), (1.93, 0, 0, 2.3, 1.41)], m["Glow"], n=B),
       rs.loft("HemHollow", [(1.682, 0, 0, 2.2, 1.32), (1.71, 0, 0, 2.2, 1.32)], m["Ink"], n=B),
       rs.hexa("Seam", [(-0.07, 0.7, 1.86), (0.07, 0.7, 1.86), (0.07, 0.74, 1.86), (-0.07, 0.74, 1.86),
                        (-0.07, 0.575, 2.6), (0.07, 0.575, 2.6), (0.07, 0.615, 2.6), (-0.07, 0.615, 2.6)], m["Glow"]),
       rs.hexa("Seam", [(-0.07, 0.575, 2.6), (0.07, 0.575, 2.6), (0.07, 0.615, 2.6), (-0.07, 0.615, 2.6),
                        (-0.07, 0.525, 3.97), (0.07, 0.525, 3.97), (0.07, 0.565, 3.97), (-0.07, 0.565, 3.97)], m["Glow"]),
       plate("Crest", disc(0, 3.0, 0.3, 20), -0.62, 0.05, m["Glow"]))
    # the collar: it stands open, its rim lit, dark inside like the cuffs
    on("root",
       rs.loft("Collar", [(3.96, 0, 0, 1.5, 1.14), (4.5, 0, -0.02, 1.6, 1.2), (4.5, 0, -0.02, 1.44, 1.04), (3.96, 0, 0, 1.36, 1.0)],
               m["VoidLift"], closed=True),
       rs.loft("CollarRim", [(4.5, 0, -0.02, 1.62, 1.22), (4.64, 0, -0.02, 1.62, 1.22), (4.64, 0, -0.02, 1.44, 1.04), (4.5, 0, -0.02, 1.44, 1.04)],
               m["Glow"], closed=True),
       rs.loft("CollarHollow", [(4.28, 0, 0, 1.38, 1.0), (4.3, 0, 0, 1.38, 1.0)], m["Ink"], n=B))
    on("neck", *mask(kind, m))
    # the sleeves: bells with nothing in them, the cuffs lit, a dark hollow where a hand should be
    for part, e in (("rs", 1), ("ls", -1)):
        on(part,
           rs.loft("Sleeve", [(1.9, e * 1.8, 0, 1.3, 1.3), (3.0, e * 1.5, 0, 1.04, 1.04), (4.0, e * 1.5, 0, 1.0, 1.0)], m["VoidLift"], n=B),
           rs.loft("Cuff", [(1.88, e * 1.8, 0, 1.35, 1.35), (2.12, e * 1.74, 0, 1.28, 1.28)], m["Glow"], n=B),
           rs.loft("Hollow", [(1.855, e * 1.8, 0, 1.12, 1.12), (1.882, e * 1.8, 0, 1.12, 1.12)], m["Ink"], n=B))
    # the legs: two straight tubes to the floor, their hems lit, no feet. Under a leg, as under the coat's hem and
    # in a cuff, there's a dark hollow inside a thin lit rim: never a filled lit face where a foot would be.
    for part, e in (("rh", 1), ("lh", -1)):
        on(part,
           rs.loft("Leg", [(0.02, e * 0.5, 0, 0.98, 0.98), (2.0, e * 0.5, 0, 0.98, 0.98)], m["VoidLift"], n=B),
           rs.loft("LegHem", [(0.012, e * 0.5, 0, 1.03, 1.03), (0.21, e * 0.5, 0, 1.03, 1.03)], m["Glow"], n=B),
           rs.loft("LegHollow", [(0.0, e * 0.5, 0, 0.95, 0.95), (0.03, e * 0.5, 0, 0.95, 0.95)], m["Ink"], n=B))
    return joints


# --- poses ----------------------------------------------------------------------------------------------------

def pose_square(joints):
    rs.aim(joints["rs"], Quaternion(), (0.1, 0.0, -1.0))
    rs.aim(joints["ls"], Quaternion(), (-0.1, 0.0, -1.0))
    rs.stand_on_floor(joints)


def pose_hung(joints):
    """How it stands: like a coat on a hook. The body tips forward, the sleeves and legs hang plumb whatever the body
    does, the feet are together, and the mask sits crooked."""
    body = (Matrix.Rotation(math.radians(-8), 3, "X") @ Matrix.Rotation(math.radians(-10), 3, "Z")).to_quaternion()
    joints["root"].rotation_quaternion = body
    for part in ("rs", "ls", "rh", "lh"):
        rs.aim(joints[part], body, (0.0, 0.0, -1.0))
    joints["neck"].rotation_quaternion = body.inverted() @ Quaternion((0, 1, 0), math.radians(11)) @ Quaternion((0, 0, 1), math.radians(8))
    rs.stand_on_floor(joints)


POSES = {"square": pose_square, "hung": pose_hung}


# --- pictures -------------------------------------------------------------------------------------------------

def blur(a, r):
    """A box blur, twice, `r` pixels each way."""
    for _ in range(2):
        for axis in (0, 1):
            a = np.moveaxis(a, axis, 0)
            padded = np.concatenate([np.repeat(a[:1], r + 1, axis=0), a, np.repeat(a[-1:], r, axis=0)])
            total = np.cumsum(padded, axis=0, dtype=np.float64)
            a = np.moveaxis(((total[2 * r + 1:] - total[:-2 * r - 1]) / (2 * r + 1)).astype(np.float32), 0, axis)
    return a


def lit(shaded, flat, colour, reach):
    """The shaded picture with its lit pieces glowing: found in the flat pass by their colour, drawn hot, and given a
    halo `reach` pixels wide that also falls outside the figure."""
    colour = np.array(colour, dtype=np.float32)
    piece = (np.abs(flat[..., :3] - colour).max(axis=-1) < 0.09) * flat[..., 3]
    out = shaded.copy()
    out[..., :3] = out[..., :3] * 0.5 + flat[..., :3] * 0.5
    hot = colour + (1 - colour) * 0.16
    out[..., :3] = out[..., :3] * (1 - piece[..., None]) + hot * piece[..., None]
    halo = np.clip(blur(piece, reach) * 1.7, 0, 0.7)[..., None]
    inside = out[..., 3:] > 0.01
    out[..., :3] = np.where(inside, out[..., :3] + colour * halo * (1 - out[..., :3]), colour)
    out[..., 3:] = np.maximum(out[..., 3:], halo * 0.85)
    return out


def take(kind, colour, pose, views, size=(1000, 1000), span=10.0, centre=(0, 0, 3.0)):
    """One Shade, posed: {view: picture}, and its size and triangle count."""
    scene = bl.reset_scene()
    joints = build(scene, kind, materials(colour))
    POSES[pose](joints)
    out = {}
    for view, (azimuth, elevation) in views.items():
        passes = []
        for flat in (False, True):
            rs.workbench(scene, *size, flat=flat)
            path = OUT / f"_{view}_{int(flat)}.png"
            passes.append(rs.shoot(scene, path, azimuth, elevation, centre, span))
            path.unlink()
        out[view] = lit(*passes, rs.rgb(TYPES[colour]), reach=round(size[0] * 0.012))
    meshes = [o for o in scene.objects if o.type == "MESH"]
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    out["size"] = tuple(round(max(q[i] for q in pts) - min(q[i] for q in pts), 2) for i in range(3))
    out["tris"] = sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)
    return out


FRONT, BACK, QUARTER, SIDE = (180, 0), (0, 0), (140, 6), (90, 3)
PLAYER = (156, 18)  # a Shade faces the lead, so the player's camera, behind the lead and above, sees its front
BUST = (180, 4)
ABOVE = (25, 45)  # from behind and above: what a turned Shade shows of its collar
NIGHT, DAY, PAPER = rs.NIGHT, rs.DAY, rs.PAPER


def solid(shot):
    """The figure alone in black, without the halo: the halo never passes 0.6 of cover, the body is 1."""
    out = shot.copy()
    out[..., 3] = np.clip((out[..., 3] - 0.62) / 0.3, 0, 1)
    return rs.black(out)


def bust(shot):
    """The mask and the collar, cut from a front view at 100 px a stud."""
    return shot[180:500, 340:660]


def sheet(small):
    first = "Brawler"
    square = take(first, "Strength", "square", {"front": FRONT, "back": BACK})
    hung = {kind: take(kind, colour, "hung", {"front": BUST, "player": PLAYER, **({"quarter": QUARTER, "side": SIDE, "above": ABOVE} if kind == first else {})})
            for kind, (colour, _) in MASKS.items()}
    colours = {colour: hung[first] if colour == "Strength" else take(first, colour, "hung", {"front": BUST}) for colour in TYPES}
    print(f"square {square['size']} studs, blockout tris {square['tris']}; " + ", ".join(f"{k} {v['size'][2]} tall" for k, v in hung.items()))
    W, H = 1920, 1200
    page = rs.canvas(W, H, PAPER)
    ink, soft, pale = "#1E1B22", "#6A655E", "#B9B4C6"
    text = [(40, 30, 64, "SHADE", ink),
            (300, 36, 24, "The festival's enemies: one body, four masks, five colours.", ink),
            (300, 70, 20, "One idea: a festival coat with nobody in it, lit from inside like a paper lantern. The mask hangs where a face should be.", soft)]

    # row A: what it is, on the dusk it's met in
    top, floor, k = 112, 478, 0.52
    rs.fill(page, 20, top, 1650, 400, NIGHT)
    rs.fill(page, 20, top, 272, 400, PAPER)
    cols = (("outline", solid(hung[first]["quarter"])), ("front, on the R6 body", square["front"]), ("back", square["back"]),
            ("three-quarter, how it stands", hung[first]["quarter"]), ("side: nothing behind the mask", hung[first]["side"]),
            ("as the player sees it", hung[first]["player"]))
    for i, (label, shot) in enumerate(cols):
        x = 24 + i * 274
        rs.stand(page, rs.shrink(shot, k), x, floor, 264)
        text.append((x + 12, floor + 10, 17, label, soft if i == 0 else pale))

    # the chips
    x = 1694
    for i, (name, role) in enumerate((("Void", "the coat"), ("Paper", "the mask"))):
        y = 116 + i * 70
        rs.fill(page, x, y, 60, 60, rs.rgb(PALETTE[name]))
        text += [(x + 72, y + 4, 19, name, ink), (x + 72, y + 28, 13, PALETTE[name], soft), (x + 72, y + 44, 13, role, soft)]
    text.append((x, 262, 16, "The light is its type:", ink))
    for i, (name, code) in enumerate(TYPES.items()):
        y = 286 + i * 34
        rs.fill(page, x, y, 28, 28, rs.rgb(code))
        text += [(x + 38, y + 1, 15, name, ink), (x + 38, y + 17, 11, code, soft)]
    text += [(x, 462, 15, "Reads, in order:", ink), (x, 482, 14, "1 the mask's outline", soft),
             (x, 500, 14, "2 the lit edges, by colour", soft), (x, 518, 14, "3 the hollow collar, cuffs", soft)]

    # row B: the four masks
    text.append((40, 528, 28, "THE FOUR MASKS", ink))
    text.append((300, 536, 18, "Each behaviour has its own outline, so it's told by a shape before a colour.", soft))
    y = 572
    for i, (kind, (colour, words)) in enumerate(MASKS.items()):
        x = 30 + i * 470
        rs.fill(page, x, y, 290, 290, NIGHT)
        rs.paste(page, rs.shrink(bust(hung[kind]["front"]), 290 / 320), x, y)
        rs.paste(page, rs.shrink(solid(bust(hung[kind]["front"])), 150 / 320), x + 298, y + 140)
        text += [(x + 300, y + 6, 22, kind, ink), (x + 300, y + 36, 15, words, soft), (x + 300, y + 58, 14, f"here {colour}", soft)]

    # row C: the five colours, the read at 64 px, the values
    y, floor = 916, 1112
    rs.fill(page, 30, y, 760, 200, NIGHT)
    for i, colour in enumerate(TYPES):
        rs.stand(page, rs.shrink(colours[colour]["front"], 0.27), 34 + i * 150, floor, 150)
        text.append((42 + i * 150, y + 6, 14, colour, pale))
    f64 = 64 / 500
    x0 = 820
    text.append((x0, y - 24, 17, "at 64 px, from the player's camera", soft))
    for r, (ground, dark) in enumerate(((NIGHT, False), (DAY, False), (PAPER, True))):
        rs.fill(page, x0, y + r * 68, 420, 66, ground)
        for c, kind in enumerate(MASKS):
            shot = rs.shrink(hung[kind]["player"], f64)
            rs.stand(page, solid(shot) if dark else shot, x0 + 6 + c * 104, y + r * 68 + 68, 100)
    x1 = 1270
    text.append((x1, y - 24, 17, "values", soft))
    rs.fill(page, x1, y, 200, 200, NIGHT)
    rs.fill(page, x1 + 200, y, 200, 200, DAY)
    for c, kind in enumerate(("Brawler", "Dasher", "Guard", "Support")):
        rs.stand(page, rs.grey(rs.shrink(hung[kind]["player"], 0.24)), x1 + c * 100, floor, 100)
    x2 = 1690
    text.append((x2, y - 24, 17, "from behind and above", soft))
    rs.fill(page, x2, y, 200, 200, NIGHT)
    rs.stand(page, rs.shrink(hung[first]["above"], 0.3), x2, floor, 140)
    rs.stand(page, rs.shrink(hung[first]["above"], f64), x2 + 136, floor, 64)
    size = square["size"]
    text.append((40, 1150, 15, f"Blockout on R6: 4 studs to the shoulders, {size[2]} to the mask's top, {size[0]} wide at the cuffs. The mask hangs on the neck's joint, "
                 f"so a clip can tip it. Views are orthographic. The glow is drawn on the picture, not rendered.", soft))
    text.append((40, 1172, 15, "An elite is larger, with a second mask on its shoulder. A keeper is its own sheet.", soft))
    rs.save(hung[first]["above"], OUT / "shade_above.png")
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "shade_sheet.png")
    if small:
        rs.save(rs.shrink(page, 0.5), OUT / "shade_sheet_small.png")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    sheet("small" in sys.argv[sys.argv.index("--") + 2:])
