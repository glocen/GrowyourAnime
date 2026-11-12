"""Lyric's design sheet (AR4, delivery 1): the stage singer, as a blockout on the R6 body.

blender.exe -b --factory-startup --python tools/blender/lyric_sheet.py -- <out_dir> [small]

The idea: she brought the stage with her. A mic stand a head taller than she is, carried as a staff on its round
base; two speakers that hover at her shoulders; and everything she wears cut on one slant: the bob's pale top layer
short at her right ear and long at her left jaw, over a rose layer cut level, the jacket's piping from her right
shoulder to her left hip, its hem from her right hip to her left knee. What's lit is Storm's pink: the speakers'
rings, the mic's ring, the headset's tip, and a level meter on her back, which is what the player's camera sees.

Workbench only, so no GPU turn. Studs, X right, Y forward, Z up, Lyric faces +Y, and every piece hangs from one of
R6's six parts at the engine's own pivots, as rook_sheet.py's do (its shapes and sheet tools are used here). The staff
and the two speakers are their own pieces: the staff wants a joint on the right arm, each speaker floats on its own.
The glow is drawn on the picture, as the Shade's light is.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

PALETTE = {
    "Limelight": "#34A866", "LimelightDeep": "#1F7045", "Backstage": "#1B2A25", "BackstageLift": "#30463D",
    "Ash": "#EAE4D6", "AshShade": "#C9C1AE", "Chalk": "#F1ECDF", "Storm": "#FF6FD8", "Rose": "#D94FB4",
    "Chrome": "#B8C0C4", "ChromeDeep": "#7C858B", "Skin": "#E9B995", "Ink": "#1E1B22",
    "AshCool": "#D4D5E0",  # the model's crown, a step cooler than Ash, so sun doesn't flatten the bob to white
}
CHIPS = (("Limelight", "the jacket"), ("Ash", "hair and boots"), ("Storm", "what's lit"))
NEUTRALS = ("Backstage", "Rose", "Chrome", "Skin")
STAFF = 6.2                      # studs, from the base to the mic's top: a head taller than she is
BASE = 0.52                      # the round base's radius
MIC = Vector((0, -0.55, STAFF - 0.3))  # the mic's head on the staff, from its base: it leans back, toward whoever holds it
HAND = 1.35                      # from a shoulder's pivot down to the middle of the fist
REST = {"dr": ((2.62, -0.55, 5.0), 12), "dl": ((-2.62, -0.55, 5.0), -12)}  # each speaker: its middle, its turn inward
SPEAKER = 0.9                    # a speaker's scale: its cabinet is drawn 1 by 1.3 studs
RAIL = 24                        # degrees: the model's chalk rail across her back, high at her right
LIFT = 0.14                      # studs: how far the model lifts the fringe's edge, for the tips that hang under it
B = rs.B
loft, slab = rs.loft, rs.slab
Z = Vector((0, 0, 1))


def materials():
    made = {}
    for name, code in {**PALETTE, "Glow": PALETTE["Storm"]}.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


def piece(scene, name, parts):
    """A piece of its own: its parts on one empty at the stage's origin, to be put anywhere."""
    empty = bpy.data.objects.new(name, None)
    scene.collection.objects.link(empty)
    empty.rotation_mode = "QUATERNION"
    for o in parts:
        o.parent = empty
    return empty


def staff(scene, m):
    """The mic stand as a staff, from the floor up: a round weighted base, a dark lower tube with her grip taped on
    it, a clutch, a chrome upper tube, and the mic in its clip, leaning back to whoever holds the stand. The mic's
    ring is lit."""
    lean = 55
    mic = [bl.place(bl.cylinder("MicBody", 0.11, 0.6, 10, m["Backstage"]), location=(0, 0, -0.05)),
           bl.place(bl.cylinder("MicRing", 0.17, 0.08, 12, m["Glow"]), location=(0, 0, 0.29)),
           bl.place(bl.sphere("MicHead", 0.27, 12, 8, m["Chrome"]), location=(0, 0, 0.55), scale=(1, 1, 1.1))]
    top = STAFF - 0.7  # the clip
    for o in mic:  # along the stand, then leant back and set in the clip
        bl.place(o, location=(0, -0.1, top + 0.1), rotation=(lean, 0, 0))
    return piece(scene, "staff", [
        bl.place(bl.cylinder("Base", BASE, 0.1, 16, m["Backstage"]), location=(0, 0, 0.05)),
        bl.place(bl.cylinder("BaseRim", BASE + 0.03, 0.04, 16, m["Chrome"]), location=(0, 0, 0.03)),
        bl.place(bl.cylinder("BaseDome", 0.26, 0.16, 12, m["Backstage"], radius_top=0.1), location=(0, 0, 0.18)),
        bl.place(bl.cylinder("Lower", 0.07, 3.3, 10, m["ChromeDeep"]), location=(0, 0, 1.85)),
        bl.place(bl.cylinder("Tape", 0.09, 0.9, 10, m["Backstage"]), location=(0, 0, 2.8)),
        bl.place(bl.cylinder("Clutch", 0.12, 0.24, 10, m["Chalk"]), location=(0, 0, 3.45)),
        bl.place(bl.cylinder("Upper", 0.045, top - 3.5, 8, m["Chrome"]), location=(0, 0, (top + 3.5) / 2)),
        slab("Clip", (0, -0.04, top), (0.14, 0.2, 0.14), m["ChromeDeep"]),
        *mic])


def speaker(scene, m, name, hot, model=False):
    """A speaker that hovers: a dark cabinet, a pale frame round its face, one cone in a lit ring with a slot above
    it, a handle on top, and a lit bar on its back for the player's camera. One cone, never two side by side: two
    would look back at you. Hot, the ring is wider. The model's back has a lit ring instead of the bar, round a flat
    dark port, so it reads as a speaker from behind too (research's fix 2): a port, not a second cone."""
    ring, cone = (0.4, 0.25) if hot else (0.35, 0.27)
    back = [ss.plate("BackRing", ss.disc(0, -0.04, 0.33, 20), -0.44, 0.03, m["Glow"]),
            ss.plate("BackPort", ss.disc(0, -0.04, 0.23, 16), -0.455, 0.03, m["Backstage"])] if model else [
            slab("BackBar", (0, -0.415, 0.3), (0.44, 0.03, 0.08), m["Glow"])]
    return piece(scene, name, [
        loft("Cabinet", [(-0.64, 0, 0, 0.98, 0.76), (0.64, 0, 0, 1.02, 0.8)], m["BackstageLift"], n=B),
        slab("Frame", (0, 0.39, 0), (0.92, 0.05, 1.18), m["Chalk"]),
        slab("Baffle", (0, 0.41, 0), (0.78, 0.05, 1.04), m["Backstage"]),
        ss.plate("ConeRing", ss.disc(0, -0.12, ring, 20), 0.43, 0.03, m["Glow"]),
        ss.plate("Cone", ss.disc(0, -0.12, cone, 20), 0.445, 0.03, m["Backstage"]),
        ss.plate("Cap", ss.disc(0, -0.12, 0.1, 12), 0.46, 0.03, m["Chalk"]),
        slab("Slot", (0, 0.45, 0.37), (0.46, 0.03, 0.09), m["Chrome"]),
        slab("Handle", (0, 0, 0.74), (0.5, 0.12, 0.07), m["Chrome"]),
        *[slab("HandlePost", (e * 0.22, 0, 0.68), (0.07, 0.1, 0.1), m["ChromeDeep"]) for e in (-1, 1)],
        slab("BackPlate", (0, -0.39, 0), (0.8, 0.04, 1.06), m["Backstage"]),
        *back,
        bl.place(bl.cylinder("Foot", 0.3, 0.07, 12, m["Rose"]), location=(0, 0, -0.69))])


def build(scene, hot=False, model=False):
    """Lyric, standing square. Returns the joints: empties at R6's pivots, and the three pieces of their own (staff,
    dr, dl), which the poses place. `hot` is the signature's note: her mouth open, the speakers' rings wide. `model`
    is the build lyric_model.py finishes, with research's fixes on the sheet: the bob's back cut into locks that
    stand off the head, a chalk rail across her back on the slant with the meter standing on it, and the speakers'
    lit rings on their backs too."""
    m = materials()
    joints = {}
    for name, at in rs.PIVOTS.items():
        j = bpy.data.objects.new(name, None)
        scene.collection.objects.link(j)
        j.location = at
        j.rotation_mode = "QUATERNION"
        if name != "root":
            j.parent = joints["root"]
            j.matrix_parent_inverse = Matrix.Translation(-Vector(rs.PIVOTS["root"]))
        joints[name] = j

    def on(part, *objs):
        for o in objs:
            o.parent = joints[part]
            o.matrix_parent_inverse = Matrix.Translation(-Vector(rs.PIVOTS[part]))

    # the jacket: R6's torso, cut on the slant. Its hem runs from her right hip to her left knee, so the long side
    # is a tail over her left leg, and it flares that way. A pale band along the hem, dark under it.
    def hem(t, lift=0.0):
        return 1.86 + 0.66 * math.cos(t) + 0.04 * math.sin(2 * t) + lift

    jacket = loft("Jacket", [(hem, -0.14, 0, 2.5, 1.66), (2.8, 0, 0, 2.16, 1.16), (4.0, 0, 0, 2.08, 1.08)], m["Limelight"], n=B)

    # her back, for the player's camera: a level meter, lit. On the model it stands on a chalk rail that crosses her
    # back on the slant, high at her right (research's fix 1), so the bars' feet climb with it. Both lie on the
    # jacket's back, which flares out toward the hem.
    if model:
        tree = BVHTree.FromPolygons([v.co for v in jacket.data.vertices], [f.vertices for f in jacket.data.polygons])

        def on_back(x, z, proud):
            hit = tree.ray_cast(Vector((x, -3.0, z)), Vector((0, 1, 0)), 4.0)[0]
            return Vector((x, hit.y - proud, z))

        rise = math.tan(math.radians(RAIL))
        rail = [on_back(x, 2.85 + rise * x, 0.02) for x in (-1.0 + 0.25 * i for i in range(9))]
        back = [bl.tube_along("Rail", rail, [0.05] * len(rail), sides=6, material=m["Chalk"])]
        for x, h in zip((-0.6, -0.3, 0.0, 0.3, 0.6), (0.42, 0.8, 0.95, 0.56, 0.68)):
            foot, top = on_back(x, 2.85 + rise * x, 0.03), on_back(x, 2.85 + rise * x + h, 0.03)
            run = top - foot
            back.append(slab("Meter", (foot + top) / 2, (0.17, 0.05, run.length), m["Glow"],
                             rot=(-math.degrees(math.asin(run.y / run.length)), 0, 0)))
    else:
        back = [slab("Meter", (-0.6 + 0.3 * i, -0.585, 2.9 + h / 2), (0.17, 0.05, h), m["Glow"])
                for i, h in enumerate((0.36, 0.74, 1.0, 0.52, 0.82))]

    on("root",
       loft("Body", [(2.0, 0, 0, 2.0, 1.0), (4.0, 0, 0, 2.0, 1.0)], m["Backstage"], n=B),
       loft("Belt", [(2.34, 0, 0, 2.06, 1.06), (2.5, 0, 0, 2.06, 1.06)], m["Chalk"], n=B),
       jacket,
       loft("HemBand", [(lambda t: hem(t, -0.012), -0.14, 0, 2.56, 1.72), (lambda t: hem(t, 0.15), -0.13, 0, 2.52, 1.68)],
            m["Chalk"], n=B, caps=False),
       loft("HemHollow", [(lambda t: hem(t, 0.0), -0.14, 0, 2.44, 1.6), (lambda t: hem(t, 0.02), -0.14, 0, 2.44, 1.6)],
            m["Ink"], n=B),
       # the slant again: piping from her right shoulder to her left hip, and a dark panel under it
       slab("Piping", (0, 0.565, 3.3), (2.36, 0.05, 0.11), m["Chalk"], rot=(0, -31, 0)),
       slab("Panel", (-0.42, 0.56, 2.86), (1.5, 0.04, 0.5), m["LimelightDeep"], rot=(0, -31, 0)),
       loft("Collar", [(3.96, 0, 0, 1.36, 1.1), (4.07, 0, 0, 1.4, 1.14), (4.07, 0, 0, 1.2, 0.94), (3.96, 0, 0, 1.2, 0.94)],
            m["Chalk"], n=3, closed=True),
       # the meter, and the radio pack on her belt
       *back,
       slab("Pack", (0.62, -0.6, 2.18), (0.42, 0.2, 0.46), m["ChromeDeep"]),
       slab("PackAerial", (0.76, -0.62, 2.52), (0.05, 0.05, 0.3), m["Chrome"]))

    # the sleeves: pale cuffs; the hand that holds the stand is gloved, the other is bare
    for part, e, hand in (("rs", 1, "Backstage"), ("ls", -1, "Skin")):
        on(part,
           loft("Sleeve", [(2.3, e * 1.5, 0, 1.08, 1.08), (4.02, e * 1.5, 0, 1.06, 1.06)], m["Limelight"], n=B),
           loft("Cuff", [(2.26, e * 1.5, 0, 1.15, 1.15), (2.5, e * 1.5, 0, 1.13, 1.13)], m["Chalk"], n=B),
           loft("Hand", [(2.0, e * 1.5, 0, 0.9, 0.9), (2.3, e * 1.5, 0, 0.94, 0.94)], m[hand], n=B))

    # R6's round head. The bob is two layers: the pale top one short at her right ear and long at her left jaw, one
    # straight cut, its fringe swept the same way; the rose one under it cut level at her jaw, so it shows as a
    # wedge that widens to her right.
    radius = 0.625

    def face(name, x, z, w, h, material, tilt=0.0, proud=0.0):
        y = math.sqrt(radius * radius - x * x)
        return slab(name, (x, y + proud, z), (w, 0.05, h), material, rot=(0, tilt, -math.degrees(math.asin(x / radius))))

    def away(t):  # 0 over her face, 1 round the sides and the back: the fringe ends at a lock in front of each ear
        if math.sin(t) <= 0:
            return 1.0
        u = min(1.0, max(0.0, (abs(math.cos(t)) - 0.5) / 0.22))
        return u * u * (3 - 2 * u)

    def cut(t, lift=0.0):
        fringe = 4.74 + 0.3 * math.cos(t)
        side = 4.24 + 0.32 * math.cos(t)
        return fringe - (fringe - side) * away(t) + lift

    def under(t):  # the layer beneath, cut level at her jaw: it shows wherever the slant has lifted the top layer
        return 4.8 - (4.8 - 3.96) * away(t)

    def shell(z):  # the top layer's half width and half depth at a height, as its lofts are cut
        if z >= 5.06:
            return 0.71, 0.72
        if z >= 4.86:
            u = (z - 4.86) / 0.2
            return 0.83 - 0.12 * u, 0.78 - 0.06 * u
        u = min(1.0, (4.86 - z) / 0.3)
        return 0.83 + 0.04 * u, 0.78 + 0.03 * u

    def lock(name, t, tip, width=0.36, stand=0.1, top=5.0, thick=0.08, stations=6, end=0.5):
        """A lock of the top layer at the angle t round her head: from under the crown, sunk in the bob, down past
        its edge to a blunt tip that stands `stand` off it. Lens-shaped across, narrowing to `end` at the tip."""
        bm = bmesh.new()
        rings = []
        for k in range(stations):
            u = k / (stations - 1)
            z = top + (tip - top) * u
            a, b = shell(z)
            at = Vector((a * math.cos(t), -0.03 + b * math.sin(t), z))
            out = Vector((b * math.cos(t), a * math.sin(t), 0)).normalized()
            along = Vector((-a * math.sin(t), b * math.cos(t), 0)).normalized()
            centre = at + out * (-thick + (1.5 * thick + stand) * u ** 1.6)
            half = 0.5 * width * (1 - (1 - end) * u)
            rings.append([bm.verts.new(centre + along * (half * math.cos(f)) + out * (0.5 * thick * math.sin(f)))
                          for f in (math.radians(d) for d in range(0, 360, 60))])
        for r0, r1 in zip(rings, rings[1:]):
            for i in range(6):
                bm.faces.new((r0[i], r0[(i + 1) % 6], r1[(i + 1) % 6], r1[i]))
        bm.faces.new(rings[0])
        bm.faces.new(list(reversed(rings[-1])))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return bl.object_from_bmesh(name, bm, m["Ash"])

    # the model's locks: across the back, from behind her right ear to behind her left, each a little past the bob's
    # slanted edge by a length of its own. None over the ear cups or the face.
    locks = [lock("Lock", math.radians(d), cut(math.radians(d)) - drop)
             for d, drop in zip(range(-30, -151, -20), (0.08, 0.18, 0.11, 0.2, 0.1, 0.17, 0.09))] if model else []

    # the model's front (research's model fix 1): across her face the top layer's edge is lifted, and five short
    # blunt locks hang from under it, overlapping to their ends, long and short by turns along the sheet's slanted
    # line: a choppy cut, so the fringe ends in hair, not a rim. No gaps between them: through a gap the shaded
    # forehead shows dark, and white points over dark read as teeth. Only the long one over her right brow passes
    # the line; the two over her left eye end at it or short of it, so none comes nearer her eyes than the fringe did.
    def lifted(t):
        if math.sin(t) <= 0:
            return cut(t)
        u = min(1.0, max(0.0, (abs(math.cos(t)) - 0.5) / 0.1))
        return max(cut(t), min(cut(t) + LIFT * (1 - u * u * (3 - 2 * u)), 4.97))

    def tip(d, drop):
        t = math.radians(d)
        rim = lifted(t)
        end = min(cut(t) - drop, rim - 0.12)
        return lock("Fringe", t, end, width=0.28, stand=0.0, thick=0.07, top=min(rim + (rim - end), 5.05), end=0.85)

    edge = lifted if model else cut
    fringe = [tip(d, drop) for d, drop in zip((63, 76.5, 90, 103.5, 117), (0.01, 0.07, -0.04, 0.0, -0.03))] if model else []

    band = [(0.9, 4.45), (0.9, 4.8), (0.8, 5.06), (0.62, 5.21), (0.3, 5.3), (0, 5.32),
            (-0.3, 5.3), (-0.62, 5.21), (-0.8, 5.06), (-0.9, 4.8), (-0.9, 4.45)]
    mouth = face("Mouth", 0.0, 4.21, 0.2, 0.2, m["Ink"], proud=0.006) if hot else face("Mouth", 0.02, 4.24, 0.22, 0.045, m["Ink"], tilt=-6, proud=0.006)
    on("neck",
       loft("Head", [(3.875, 0, 0, 0.95, 0.95), (3.92, 0, 0, 1.14, 1.14), (4.02, 0, 0, 1.25, 1.25), (4.98, 0, 0, 1.25, 1.25),
                     (5.08, 0, 0, 1.14, 1.14), (5.125, 0, 0, 0.95, 0.95)], m["Skin"], n=2),
       loft("Hair", [(edge, 0, -0.03, 1.74, 1.62), (lambda t: max(edge(t) + 0.05, 4.86), 0, -0.03, 1.66, 1.56),
                     (5.06, 0, -0.02, 1.42, 1.44)], m["Ash"], n=2, caps=False),
       loft("HairTop", [(5.06, 0, -0.02, 1.42, 1.44), (5.2, 0, 0, 1.08, 1.1)], m["Ash"], n=2),
       # on the model the rose layer's front rises with the lifted edge, so it stays hidden between the tips
       loft("HairUnder", [(lambda t: under(t) + edge(t) - cut(t), 0, -0.03, 1.6, 1.48),
                          (lambda t: max(4.84, under(t) + edge(t) - cut(t) + 0.04), 0, -0.03, 1.54, 1.44)],
            m["Rose"], n=2, caps=False),
       *locks,
       *fringe,
       face("BrowR", 0.27, 4.71, 0.24, 0.045, m["Ink"], tilt=-3, proud=0.03),
       face("BrowL", -0.27, 4.71, 0.24, 0.045, m["Ink"], tilt=3, proud=0.03),
       face("EyeR", 0.26, 4.5, 0.2, 0.22, m["Ink"]),
       face("EyeL", -0.26, 4.5, 0.2, 0.22, m["Ink"]),
       face("LightR", 0.3, 4.56, 0.07, 0.07, m["Chalk"], proud=0.012),
       face("LightL", -0.22, 4.56, 0.07, 0.07, m["Chalk"], proud=0.012),
       mouth,
       # the headset: a band over the bob, a cup at each ear, and the boom from her right ear to her mouth, its tip lit
       bl.tube_along("Headband", [Vector((x, -0.05, z)) for x, z in band], [0.055] * len(band), sides=8, material=m["Backstage"]),
       *[bl.place(bl.cylinder("Cup", 0.22, 0.3, 12, m["Backstage"]), location=(e * 0.9, -0.03, 4.5), rotation=(0, 90, 0)) for e in (-1, 1)],
       *[bl.place(bl.cylinder("CupFace", 0.12, 0.03, 10, m["Chrome"]), location=(e * 1.06, -0.03, 4.5), rotation=(0, 90, 0)) for e in (-1, 1)],
       # on the model the boom hugs her cheek, so in sunlight its tip's shadow stays under the tip, not on her face,
       # and ends at the middle of the cheek, a mouth's width clear of its corner (research's model fix 2)
       bl.tube_along("Boom", [Vector(p) for p in (((0.98, 0.05, 4.42), (0.7, 0.38, 4.33), (0.5, 0.5, 4.27)) if model else
                                                  ((0.98, 0.05, 4.42), (0.86, 0.46, 4.3), (0.5, 0.7, 4.24)))],
                     [0.035] * 3, sides=6, material=m["Backstage"]),
       slab("BoomTip", (0.45, 0.536, 4.27), (0.13, 0.1, 0.1), m["Glow"], rot=(0, 0, -40)) if model else
       slab("BoomTip", (0.42, 0.71, 4.24), (0.13, 0.1, 0.1), m["Glow"]))

    # the legs: dark leggings into pale boots on thick soles; the right leg, which the short side bares, has a stripe
    for part, s in (("rh", 1), ("lh", -1)):
        cx = s * 0.5
        on(part,
           loft("Legging", [(1.0, cx, 0, 0.98, 1.0), (2.0, cx, 0, 0.98, 1.0)], m["Backstage"], n=B),
           loft("Sole", [(0.0, cx, 0.07, 1.06, 1.28), (0.22, cx, 0.07, 1.06, 1.28)], m["Backstage"], n=B),
           loft("Boot", [(0.22, cx, 0.06, 1.04, 1.22), (0.5, cx, 0.0, 1.02, 1.04), (1.08, cx, 0, 1.04, 1.06)], m["Ash"], n=B),
           loft("BootTop", [(1.0, cx, 0, 1.1, 1.12), (1.14, cx, 0, 1.1, 1.12)], m["LimelightDeep"], n=B))
    on("rh", slab("Stripe", (1.0, 0, 1.56), (0.03, 0.2, 0.8), m["Chalk"]))

    joints["staff"] = staff(scene, m)
    for name in REST:
        joints[name] = speaker(scene, m, name, hot, model)
    return joints


# --- poses ----------------------------------------------------------------------------------------------------

def hover(joints, name, at=None, turn=None, tilt=0.0):
    """Puts a speaker at a place on the stage, turned about the upright and tipped forward."""
    rest, inward = REST[name]
    j = joints[name]
    j.location = rest if at is None else at
    j.scale = (SPEAKER,) * 3
    j.rotation_quaternion = (Quaternion((0, 0, 1), math.radians(inward if turn is None else turn))
                             @ Quaternion((1, 0, 0), math.radians(-tilt)))


def plant(joints, foot, lean=0.0, turn=0.0):
    """Stands the staff with its base's middle over `foot`, leant back `lean` degrees (toward -Y, the mic's side) and
    then turned about the upright; a leant stand rests on its base's edge. Returns where its base is and the line it
    lies along."""
    j = joints["staff"]
    foot = Vector((foot[0], foot[1], BASE * math.sin(math.radians(abs(lean)))))
    j.location = foot
    j.rotation_quaternion = Quaternion((0, 0, 1), math.radians(turn)) @ Quaternion((1, 0, 0), math.radians(lean))
    return foot, j.rotation_quaternion @ Z


def grip(joints, body, foot, along, high=False):
    """Turns her right arm so its fist closes on the staff: the place on the staff's line that the fist can reach,
    the higher or the lower of the two."""
    bpy.context.view_layer.update()
    pivot = joints["rs"].matrix_world.translation
    fist = Vector((0.5, 0, -HAND))
    w = Vector(foot) - pivot
    b = w.dot(along)
    root = b * b - (w.dot(w) - fist.length_squared)
    s = -b + (math.sqrt(root) if high else -math.sqrt(root)) if root > 0 else -b
    joints["rs"].rotation_quaternion = fist.rotation_difference(body.inverted() @ (Vector(foot) + s * along - pivot))
    return root > 0


def pose_square(joints):
    """Square on, as a model sheet stands a figure: the stand upright in her right hand, the speakers at rest."""
    rs.aim(joints["ls"], Quaternion(), (-0.16, 0.0, -1.0))
    rs.stand_on_floor(joints)
    grip(joints, Quaternion(), *plant(joints, (1.55, 0.95)))
    for name in REST:
        hover(joints, name)


def pose_idle(joints):
    """How she stands: turned a little off the stand, weight on one leg, the stand leaning in to her shoulder, her
    chin up. The speakers hang at two heights."""
    body = Matrix.Rotation(math.radians(9), 3, "Z").to_quaternion()
    joints["root"].rotation_quaternion = body
    rs.aim(joints["ls"], body, (-0.2, -0.12, -1.0), stage=False)
    joints["neck"].rotation_quaternion = Quaternion((0, 0, 1), math.radians(-15)) @ Quaternion((1, 0, 0), math.radians(5))
    rs.aim(joints["rh"], body, (0.1, 0.1, -1.0), twist=-6)
    rs.aim(joints["lh"], body, (-0.04, -0.06, -1.0), twist=8)
    rs.stand_on_floor(joints)
    grip(joints, body, *plant(joints, (1.5, 1.3), lean=7, turn=12))
    hover(joints, "dr", (2.68, -0.5, 5.15))
    hover(joints, "dl", (-2.6, -0.65, 4.8))


def pose_note(joints, turn=-58.0, pull=(0.3, 0.25, -0.15), yaw=14.0):
    """The signature's key pose, the note: she lunges with her right side leading, drags the stand down to her mouth
    and leans her whole weight into it. The stand's base is planted ahead and to her right (`turn`), so the pole
    passes her leading shoulder and her fist closes on it under the mic, below shoulder height: with the base
    straight ahead the fist can't reach the pole at all, and the arm ends up raised. Her free arm is flung low and
    back; the speakers are thrown up and forward to the wave's two edges, tipped down the street, their rings wide.
    Returns the stand's lean, the mic arm's angle from level, and whether the fist is on the pole."""
    body = (Matrix.Rotation(math.radians(-17), 3, "X") @ Matrix.Rotation(math.radians(yaw), 3, "Z")).to_quaternion()
    root = joints["root"]
    root.rotation_quaternion = body
    root.location = (0, 0.4, 3)
    rs.aim(joints["rh"], body, (0.08, 0.78, -1.0))
    rs.aim(joints["lh"], body, (-0.18, -0.8, -1.0), twist=14)
    rs.aim(joints["ls"], body, (-0.6, -0.75, -0.5))
    joints["neck"].rotation_quaternion = Quaternion((0, 0, 1), math.radians(-12)) @ Quaternion((1, 0, 0), math.radians(12))
    rs.stand_on_floor(joints)
    # the mic meets her mouth: the stand's lean is whatever puts its head there with its base's edge on the floor
    mouth = Vector(root.location) + body @ Vector((0.0, 0.62, 1.25))
    meet = mouth + Vector(pull)
    lean = 30.0
    for _ in range(6):
        up = (meet.z - BASE * math.sin(math.radians(lean))) / MIC.length
        lean = math.degrees(math.acos(min(1.0, up)) - math.atan2(-MIC.y, MIC.z))
    q = Quaternion((0, 0, 1), math.radians(turn)) @ Quaternion((1, 0, 0), math.radians(lean))
    held = grip(joints, body, *plant(joints, meet - q @ MIC, lean=lean, turn=turn))
    hover(joints, "dr", (3.6, 4.2, 4.7), turn=-24, tilt=14)
    hover(joints, "dl", (-3.6, 4.2, 4.7), turn=24, tilt=14)
    bpy.context.view_layer.update()
    arm = joints["rs"].matrix_world.to_quaternion() @ Vector((0, 0, -1))
    return lean, math.degrees(math.asin(arm.z)), held


POSES = {"square": pose_square, "idle": pose_idle, "note": pose_note}


# --- pictures -------------------------------------------------------------------------------------------------

def takes(wanted, size=(1000, 1000), span=10.0):
    """{(pose, view): picture}, with the glow drawn on, and what was measured. `wanted`: pose -> {view: (azimuth,
    elevation, centre)}."""
    out = {}
    for pose, views in wanted.items():
        scene = bl.reset_scene()
        joints = build(scene, hot=pose == "note")
        out[pose, "lean"] = POSES[pose](joints)
        bpy.context.view_layer.update()
        for view, (azimuth, elevation, centre) in views.items():
            passes = []
            for flat in (False, True):
                rs.workbench(scene, *size, flat=flat)
                path = OUT / f"_{pose}_{view}_{int(flat)}.png"
                passes.append(rs.shoot(scene, path, azimuth, elevation, centre, span))
                path.unlink()
            out[pose, view] = ss.lit(*passes, rs.rgb(PALETTE["Storm"]), reach=round(size[0] * (0.016 if pose == "note" else 0.01)))
        meshes = [o for o in scene.objects if o.type == "MESH"]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        out[pose, "size"] = tuple(round(max(q[i] for q in pts) - min(q[i] for q in pts), 2) for i in range(3))
        out[pose, "top"] = round(max(q.z for q in pts), 2)
        out["tris"] = sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)
    return out


MID, FAR = (0.0, 0.2, 3.4), (0.0, 2.6, 3.3)
GAME, FRONT = rs.GAME, (150, 8)
MET = (192, 8)  # from the target's side, off her free hand, so the arm on the mic doesn't cover her face
PAPER, NIGHT, DAY = rs.PAPER, rs.NIGHT, rs.DAY
DUSK = rs.rgb("#2F2148")  # Lantern Row's own violet, where players meet her


def sheet(small):
    wanted = {"square": {"front": (180, 0, MID), "back": (0, 0, MID)},
              "idle": {"front": (*FRONT, MID), "game": (*GAME, MID)},
              "note": {"met": (*MET, FAR), "side": (90, 3, FAR), "game": (*GAME, FAR)}}
    s = takes(wanted)
    print(f"square {s['square', 'size']} studs, top {s['square', 'top']}; note {s['note', 'size']}, top {s['note', 'top']}, "
          f"the stand leant {s['note', 'lean'][0]:.0f} degrees, the mic arm {s['note', 'lean'][1]:+.0f} from level, "
          f"{'on' if s['note', 'lean'][2] else 'OFF'} the pole; "
          f"blockout tris {s['tris']}")
    W, H = 1920, 1290
    page = rs.canvas(W, H, PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 64, "LYRIC", ink),
            (270, 36, 24, "Rare / Technique / Healer / Storm. A stage singer.", ink),
            (270, 70, 20, "One idea: she brought the stage with her, and everything she wears is cut on one slant.", soft)]

    # row A: who she is
    k, floor = 0.54, 570
    cols = ((10, 340, "idle", "front", True, "outline"), (350, 340, "square", "front", False, "front, on the R6 body"),
            (690, 340, "square", "back", False, "back"), (1030, 340, "idle", "front", False, "three-quarter, how she stands"),
            (1370, 310, "idle", "game", False, "from the player's camera"))
    for x, width, pose, view, dark, label in cols:
        shot = rs.shrink(s[pose, view], k)
        rs.stand(page, ss.solid(shot) if dark else shot, x, floor, width)
        text.append((x + 14, floor + 14, 19, label, soft))
    rs.fill(page, 30, floor + 2, 1640, 2, rs.rgb("#BDB8AE"))

    # the chips
    x = 1700
    for i, (name, role) in enumerate(CHIPS):
        y = 120 + i * 118
        rs.fill(page, x, y, 96, 96, rs.rgb(PALETTE[name]))
        text += [(x + 108, y + 10, 22, name, ink), (x + 108, y + 40, 16, PALETTE[name], soft), (x + 108, y + 64, 16, role, soft)]
    for i, name in enumerate(NEUTRALS):
        rs.fill(page, x + i * 54, 480, 46, 46, rs.rgb(PALETTE[name]))
        text.append((x + i * 54, 534, 11, name, soft))
    text += [(x, 568, 16, "Reads, in order:", ink), (x, 592, 16, "1 the mic stand, taller than her", soft),
             (x, 614, 16, "2 the two speakers, lit", soft), (x, 636, 16, "3 the slant: bob, piping, hem", soft)]

    # row B: the signature's key pose
    floor, k = 1130, 0.5
    text.append((40, 620, 30, "THE SIGNATURE, the note", ink))
    text.append((40, 662, 18, "She lunges, right side leading, drags the stand down to her mouth and leans her whole weight into one note. The speakers are thrown ahead to the wave's two edges.", soft))
    for x, width, view, dark, label in ((20, 520, "met", False, "three-quarter, from the target's side"), (550, 500, "side", True, "outline, side on"),
                                        (990, 370, "game", False, "from the player's camera")):
        shot = rs.shrink(s["note", view], k)
        rs.stand(page, ss.solid(shot) if dark else shot, x, floor, width)
        text.append((x + 14, floor + 14, 19, label, soft))
    rs.fill(page, 30, floor + 2, 1380, 2, rs.rgb("#BDB8AE"))

    # at 64 px: a 5-stud body 64 px tall, over a dark and a bright ground, and in black
    f64 = 64 / 500
    x0, y0 = 1440, 676
    text.append((x0, y0, 19, "at 64 px: dark, Lantern Row's dusk, bright", soft))
    for r, (ground, sil) in enumerate(((NIGHT, False), (DUSK, False), (DAY, False), (PAPER, True))):
        y = y0 + 30 + r * 98
        rs.fill(page, x0, y, 450, 96, ground)
        for c, key in enumerate((("idle", "game"), ("idle", "front"), ("note", "game"), ("note", "met"))):
            shot = rs.shrink(s[key], f64)
            rs.stand(page, ss.solid(shot) if sil else shot, x0 + 4 + c * 112, y + 94, 108)
    y = y0 + 30 + 4 * 98 + 4
    text.append((x0, y, 19, "values", soft))
    for c, key in enumerate((("idle", "front"), ("idle", "game"), ("note", "met"))):
        rs.stand(page, rs.grey(rs.shrink(s[key], 0.19)), x0 + c * 150, 1252, 150)

    sizes = s["square", "size"]
    text.append((40, 1262, 15, f"Blockout on R6 at the player's height: 5 studs to the crown, {s['square', 'top']} to the mic's top, the stand {STAFF} long on a round base, "
                 f"{sizes[0]} across with the speakers. The stand and each speaker are pieces of their own. Views are orthographic. "
                 f"The glow is drawn on the picture.", soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "lyric_sheet.png")
    if small:
        rs.save(rs.shrink(page, 0.5), OUT / "lyric_sheet_small.png")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    sheet("small" in sys.argv[sys.argv.index("--") + 2:])
