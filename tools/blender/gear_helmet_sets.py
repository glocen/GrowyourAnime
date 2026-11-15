"""AR6, batch 1: the Helmet in three designs at each rarity, in grey: a blockout for research's verdict.

The large piece of the batch. One family: a round skull with a brow band, seen three-quarter from the front and a little
from above, its face turned to the right as the swords point. A design is what the skull wears: a nasal, cheek plates, a
visor or a brim, a neck guard, and what stands on it. A rarity keeps the ladder's rule (dark iron; bright steel and one
brass fitting; blued, a small stone, a line; a darker metal with filigree and a glowing stone; gilt and ivory with one
new form), and a set keeps its word.

Each Legendary's one new form changes the silhouette: Tomoshibi wears a lamp on its crown, Zansho a mane of ivory blades
swept back, Hakumei a pair of tall forked horns at the brow. No flame, no cloud: the light is a stone and a line.

    blender -b --factory-startup --python tools/blender/gear_helmet_sets.py -- build/handoff/Gear/helmet_sets

Writes the sheet gear_helmet_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import gear_sword_sets as s  # noqa: E402

mat = g.material
DEEP = 1.12                # the skull is a little deeper, front to back, than it's wide
TILT, SPIN = 14.0, 38.0    # seen a little from above, the face turned to the right
FILL, DROP = 0.78, 0.025   # its share of the square, and how far under the middle it sits: a tall crest clears the name
LEAST = 0.82               # a plain helmet is drawn no smaller than this share of the largest
FRONT = -(DEEP * 1.03 + 0.14)  # where a brow's crest stands, in front of the band

# The skull's profile from the brow up: (radius, height). The crown's small hole sits under whatever stands on it.
DOME = [(1.0, 0.0), (0.99, 0.2), (0.93, 0.45), (0.8, 0.68), (0.6, 0.86), (0.34, 0.97), (0.03, 1.02)]

# Crests that stand at the brow, drawn from the front from the right half, top middle round to foot middle.
CURL = [(x * 0.75, z * 0.75 + 0.2) for x, z in s.CURLED]
PRONGS = [(0.0, 0.5), (0.14, 0.5), (0.24, 0.9), (0.32, 1.5), (0.44, 0.9), (0.5, 0.4), (0.3, 0.12), (0.0, 0.06)]
HORNS = [(0.0, 0.5), (0.2, 0.55), (0.36, 0.9), (0.5, 1.5), (0.58, 1.95), (0.68, 1.5), (0.72, 1.25), (0.9, 1.7), (1.02, 2.35),
         (1.2, 1.8), (1.14, 1.2), (0.9, 0.6), (0.55, 0.22), (0.2, 0.08), (0.0, 0.05)]
BOSS = [(0.0, 0.42), (0.2, 0.3), (0.2, 0.06), (0.0, -0.04)]  # a small plate for a stone alone
FIN = [(-0.1, 0.1), (0.9, 0.75), (0.5, 0.1), (0.75, -0.15), (-0.1, -0.2)]  # a side's vane, drawn from the side: (back, up)


def design(name, rarity, note, key, **more):
    return dict(dict(name=name, rarity=rarity, note=note, key=key, trim=key, tall=1.0, brow=key, nasal=False, cheeks=False,
                     neck="short", visor=False, brim=False, ribs=False, comb=None, crest=None, fins=False, stone=None,
                     line=None, top="knob", top_mat=key, mane=False, edge=False), **more)


DESIGNS = (
    design("Iron Helmet", "Common", "A round skull, a plain brow band, a nasal, a short neck guard.", "iron", nasal=True),
    design("Bronze Helmet", "Common", "A taller skull with cheek plates and a button on its crown.", "bronze", tall=1.14,
           cheeks=True, neck=None),
    design("Scrap Helmet", "Common", "Four plates under riveted straps, a flat nasal.", "scrap", ribs=True, nasal=True,
           neck=None),

    design("Lanternsteel Helmet", "Uncommon", "Bright steel with a brass brow band, a nasal, a long neck guard.", "steel",
           brow="brass", nasal=True, neck="long"),
    design("Rowsmith Helmet", "Uncommon", "Cheek plates, and a low brass comb from brow to nape.", "steel", cheeks=True,
           comb=("low", "brass")),
    design("Stallguard Helmet", "Uncommon", "A brim all round, a brass acorn on the crown.", "steel", brim=True, neck=None,
           top="acorn", top_mat="brass"),

    design("Helm of Embers", "Rare", "A nasal and cheek plates, one small stone on the brow, a line round the skull.", "blued",
           nasal=True, cheeks=True, crest=BOSS, stone=("stone", 0.15), line="filigree"),
    design("Helm of Hoarfrost", "Rare", "A closed face with one eye slit, the stone over it, a long neck guard.", "blued",
           visor=True, neck="long", crest=BOSS, stone=("stone", 0.15), line="filigree"),
    design("Helm of Gales", "Rare", "A vane swept back from each side, the stone on the brow, a nasal.", "blued", nasal=True,
           fins=True, crest=BOSS, stone=("stone", 0.15), line="filigree"),

    design("Stormcall Helm", "Epic", "Two filigree horns curl up from the brow round a glowing stone. A nasal, cheek "
           "plates.", "rich", trim="filigree", nasal=True, cheeks=True, crest=CURL, stone=("glow", 0.2), line="filigree"),
    design("Gloamforge Helm", "Epic", "A closed face, two filigree prongs standing at the brow, a glowing stone between "
           "them.", "rich", trim="filigree", visor=True, neck="long", crest=PRONGS, stone=("glow", 0.2), line="filigree"),
    design("Nightloom Helm", "Epic", "A tall filigree comb from brow to nape, cheek plates, a glowing stone.", "rich",
           trim="filigree", cheeks=True, comb=("tall", "filigree"), crest=BOSS, stone=("glow", 0.2), line="filigree"),

    design("Tomoshibi, the Vigil", "Legendary", "Its one new form: a lamp stands on the crown, its light held in three "
           "prongs.", "gilt", trim="ivory", brow="ivory", nasal=True, cheeks=True, crest=BOSS, stone=("lit", 0.2), top="lamp",
           edge=True),
    design("Zansho, the Afterglow", "Legendary", "Its one new form: a mane of ivory blades sweeps back from the crown.",
           "gilt", trim="ivory", brow="ivory", visor=True, crest=BOSS, stone=("lit", 0.2), mane=True, edge=True),
    design("Hakumei, the Twilight", "Legendary", "Its one new form: a pair of tall forked horns at the brow.", "gilt",
           trim="ivory", brow="ivory", nasal=True, cheeks=True, neck="long", crest=HORNS, stone=("lit", 0.2), edge=True),
)
assert all(len(d["name"]) <= 24 for d in DESIGNS), "a name is over 24 characters"


# --- the parts ---------------------------------------------------------------------------------------------------------

def shell(name, profile, key, a0=0.0, a1=360.0, thick=0.07, grow=1.0):
    """A profile turned about the skull's own height, from angle a0 to a1 (0 is the face, 90 the right of the picture),
    then given a thickness."""
    closed = a1 - a0 >= 359.9
    steps = 48 if closed else max(3, int(48 * (a1 - a0) / 360) + 1)
    bm, cols = bmesh.new(), []
    for i in range(steps):
        a = math.radians(a0 + (a1 - a0) * i / (steps if closed else steps - 1))
        cols.append([bm.verts.new((r * grow * math.sin(a), -r * grow * DEEP * math.cos(a), z)) for r, z in profile])
    for i in range(len(cols) if closed else len(cols) - 1):
        p, q = cols[i], cols[(i + 1) % len(cols)]
        for j in range(len(profile) - 1):
            bm.faces.new((p[j], p[j + 1], q[j + 1], q[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = bl.object_from_bmesh(name, bm, mat(key))
    mod = obj.modifiers.new("Solid", "SOLIDIFY")
    mod.thickness, mod.offset = thick, 0.0
    return bl.smooth_by_angle(bl.apply_modifiers(obj), 40.0)


def hoop(name, radius, minor, key, z, high=1.0):
    """A band round the skull at height z."""
    return bl.smooth_by_angle(bl.place(bl.torus(name, radius, minor, 48, 10, mat(key)), (0, 0, z), (0, 0, 0), (1, DEEP, high)), 40.0)


def on_dome(angle, reach=1.0, tall=1.0):
    """A point in the helmet's middle plane (back, up): `angle` from the crown, toward the nape; `reach` times the skull."""
    a = math.radians(angle)
    return DEEP * reach * math.sin(a), tall * reach * math.cos(a)


def skull(d):
    key, tall = d["key"], d["tall"]
    # The dark lining ends just under the brow, so an open helmet is hollow and never a hat on a head (the content check,
    # 2026-11-15). Behind a closed face it runs down inside the plates, so the eye slit stays dark and empty.
    low = [(0.88, -0.95), (0.93, -0.4)] if d["visor"] else [(0.92, -0.14)]
    parts = [shell("Skull", [(r, z * tall) for r, z in DOME], key),
             shell("Liner", low + [(0.93, 0.2), (0.8, 0.6), (0.4, 0.88), (0.03, 0.94)], "leather", thick=0.02)]
    if d["brow"]:
        parts.append(hoop("Brow", 1.03, 0.1, d["brow"], 0.08, high=1.4))
    if d["ribs"]:  # straps over the plates' joins, and their rivets on the brow
        for a in (0, 90, 180, 270):
            parts.append(shell("Strap", [(r, z * tall) for r, z in DOME], key, a - 9, a + 9, thick=0.06, grow=1.04))
        for i in range(8):
            a = math.radians(45 * i + 22.5)
            parts.append(bl.place(bl.sphere("Rivet", 0.07, 8, 5, mat(key)), (1.14 * math.sin(a), -1.14 * DEEP * math.cos(a), 0.08)))
    if d["line"]:
        parts.append(hoop("Line", 0.94, 0.028, d["line"], 0.45 * tall))
    if d["edge"]:  # the light on the edge: a line along the brow band
        parts.append(hoop("Edge", 1.1, 0.03, "lit", 0.2))
    return parts


def face(d):
    key, parts = d["key"], []
    if d["nasal"]:
        parts.append(g.plate("Nasal", [(-0.11, 0.1), (0.11, 0.1), (0.15, -0.75), (0.0, -0.86), (-0.15, -0.75)], 0.1, key,
                             y=-(DEEP * 1.03 + 0.04), bevel=0.03))
    if d["cheeks"]:
        for a0, a1 in ((34, 78), (-78, -34)):
            parts.append(shell("Cheek", [(1.0, 0.0), (1.02, -0.45), (0.92, -0.9)], key, a0, a1))
    if d["visor"]:  # the brow let down, and a plate over the mouth: the eye slit is the gap between them
        parts.append(shell("Visor", [(1.04, 0.0), (1.06, -0.13)], key, -64, 64))
        parts.append(shell("Bevor", [(1.04, -0.29), (1.07, -0.5), (0.98, -0.85), (0.8, -1.0)], key, -64, 64))
    if d["neck"]:
        fall = dict(short=[(1.0, 0.0), (1.03, -0.35), (1.16, -0.6)], long=[(1.0, 0.0), (1.03, -0.45), (1.14, -0.8), (1.34, -1.0)])
        parts.append(shell("Neck", fall[d["neck"]], key, 78, 282))
    if d["brim"]:
        parts.append(shell("Brim", [(1.0, 0.06), (1.24, 0.0), (1.46, -0.12)], key))
    return parts


def crown(d):
    key, trim, tall, parts = d["key"], d["trim"], d["tall"], []
    z = 1.02 * tall
    if d["comb"]:  # a fin over the skull from the brow to the nape
        kind, comb_mat = d["comb"]
        reach = dict(low=1.2, tall=1.5)[kind]
        angles = [-58 + 166 * i / 16 for i in range(17)]
        rise = [math.sin(math.pi * i / 16) ** 0.6 for i in range(17)]
        outer = [on_dome(a, 0.98 + (reach - 0.98) * k, tall) for a, k in zip(angles, rise)]
        inner = [on_dome(a, 0.96, tall) for a in reversed(angles)]
        parts.append(bl.bevel(bl.profile("Comb", outer + inner, 0.12, mat(comb_mat)), 0.03, segments=1))
    if d["mane"]:  # five blades from the crown, each longer and lower than the last
        for k in range(5):
            a = 6 + 21 * k
            long = 1.75 + 0.1 * k
            blade = [on_dome(a - 9, 0.97, tall), on_dome(a + 2, 1.3, tall), on_dome(a + 16, long, tall), on_dome(a + 9, 0.97, tall)]
            parts.append(bl.bevel(bl.profile("Mane", blade, 0.1, mat(trim)), 0.03, segments=1))
    if d["top"] == "knob" and not d["comb"] and not d["mane"]:
        parts.append(bl.place(bl.sphere("Knob", 0.11, 10, 6, mat(d["top_mat"])), (0, 0, z), (0, 0, 0), (1, 1, 0.7)))
    elif d["top"] == "acorn":
        parts.append(bl.place(bl.cylinder("Cup", 0.2, 0.1, segments=12, material=mat(d["top_mat"])), (0, 0, z + 0.03)))
        parts.append(bl.place(bl.sphere("Acorn", 0.17, 10, 6, mat(d["top_mat"])), (0, 0, z + 0.2), (0, 0, 0), (1, 1, 1.35)))
    elif d["top"] == "lamp":  # a collar, a stem, a cup, the light and three prongs round it
        parts += [bl.place(bl.cylinder("Collar", 0.24, 0.14, segments=8, material=mat(key)), (0, 0, z + 0.04)),
                  bl.place(bl.cylinder("Stem", 0.075, 0.36, segments=8, material=mat(key)), (0, 0, z + 0.28)),
                  bl.place(bl.cylinder("Cup", 0.1, 0.2, segments=8, material=mat(key), radius_top=0.32), (0, 0, z + 0.54)),
                  bl.place(bl.sphere("Light", 0.28, 12, 8, mat("lit")), (0, 0, z + 0.94), (0, 0, 0), (1, 1, 1.4))]
        for i in range(3):
            a = math.radians(120 * i + 90)
            x, y = math.cos(a), math.sin(a)
            path = [Vector((0.3 * x, 0.3 * y, z + 0.62)), Vector((0.4 * x, 0.4 * y, z + 0.95)), Vector((0.2 * x, 0.2 * y, z + 1.32))]
            parts.append(bl.tube_along("Prong", path, [0.05, 0.045, 0.03], sides=6, material=mat(trim)))
    if d["fins"]:
        for side in (-1, 1):
            parts.append(bl.bevel(bl.profile("Fin", FIN, 0.08, mat(key), x=side * 1.04), 0.02, segments=1))
    if d["crest"]:
        parts.append(g.plate("Crest", g.mirrored(d["crest"]), 0.1, trim, y=FRONT, bevel=0.03))
    if d["stone"]:
        kind, radius = d["stone"]
        gem = bl.sphere("Stone", radius, segments=6, rings=3, material=mat(kind))
        parts.append(bl.place(gem, (0, FRONT - 0.06, 0.2), (0, 0, 30), (1, 0.5, 1.2)))
        parts.append(bl.place(bl.torus("Bezel", radius * 1.2, 0.04, 20, 8, mat(trim)), (0, FRONT - 0.05, 0.2), (90, 0, 0)))
    return parts


def helmet(d):
    """The helmet in a scene of its own, turned and seen a little from above."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Room")
    parts = skull(d) + face(d) + crown(d)
    lay = Matrix.Rotation(math.radians(TILT), 4, "X") @ Matrix.Rotation(math.radians(SPIN), 4, "Z")
    for obj in parts:
        obj.data.transform(lay)
    return scene, parts


def renders(out):
    """Each centred in its square. The largest sets the scale; a plain helmet is drawn up to LEAST of the largest."""
    sizes = []
    for d in DESIGNS:
        x0, x1, z0, z1 = g.bounds(helmet(d)[1])
        sizes.append(max(x1 - x0, z1 - z0))
    shots = {}
    for d, size in zip(DESIGNS, sizes):
        scene, parts = helmet(d)
        x0, x1, z0, z1 = g.bounds(parts)
        span = max(size, LEAST * max(sizes)) / FILL
        shots[d["name"]] = g.shoot(scene, out, ((x0 + x1) / 2, (z0 + z1) / 2 + DROP * span), span)
        print(f"{d['name']}: fills {size / span:.2f} of the square")
    return shots


WORDS = dict(
    file="gear_helmet_sets.png",
    title="Grow your Anime: the Helmet in three designs at each rarity, in grey (AR6, batch 1)",
    lead="The batch's large piece: one round skull with a brow band, three-quarter from the front, its face to the right as "
         "the swords point. A design is what the skull wears. A plain helmet is drawn a little larger, to fill its square.",
    notes=(
        "A set keeps its word (the spec's examples \"Paper-Lantern Helmet\" and \"Nightcurrent Helm\" give way to the sets; \"Helm of "
        "Hoarfrost\" already fits). A helmet's near word is Helm from Rare up.",
        "Each Legendary's one new form: Tomoshibi (a lamp's flame), a lamp on the crown; Zansho (the afterglow), a mane of ivory "
        "blades swept back; Hakumei (twilight), a pair of tall forked horns at the brow.",
        "Zansho and Hakumei are new names, for research's check. No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a helmet, and apart from its two neighbours, at 38 points? Does each Legendary outrank "
        "every Epic by shape? Not here yet: colour, frames.",
    ),
)


def main():
    out = bl.out_dir()
    s.sheet(out, renders(out), DESIGNS, WORDS)


if __name__ == "__main__":
    main()
