"""AR6, batch 1: Ring I in three designs at each rarity, in grey: a blockout for research's verdict.

The small piece of the batch (AR6, "Batch 1, research's spec": "The ring is widened by its own ornament"). One family:
a band seen three-quarter, leaning back so its head faces the eye. A design is its band, its shoulders and its head;
the ornament stands in the ring's own plane, as a sword's guard does, so it shows at the slot's size. A rarity keeps the
ladder's rule (dark iron; bright steel and one brass fitting; blued, a small stone, a line; a darker metal with
filigree and a glowing stone; gilt and ivory with one new form), and a set keeps its word.

Each Legendary's one new form changes the silhouette: Kagaribi's head is a watchfire's basket, Yoiboshi's stone sits
on a four-point star, Ariake's in a crescent. The content check's condition holds: a Legendary is a metal ring, never
a red braided cord.

    blender -b --factory-startup --python tools/blender/gear_ring_sets.py -- build/handoff/Gear/ring_sets

Writes the sheet gear_ring_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import gear_sword_sets as s  # noqa: E402

mat = g.material
R = 1.0                    # the band's radius: every ring shares it
TILT, SPIN = 40.0, 28.0    # the ring leant back toward the eye, then turned a little
FILL, DROP = 0.78, 0.025   # its share of the square, and how far under the middle it sits: a tall head clears the name
LEAST = 0.86               # a plain ring is drawn no smaller than this share of the largest, so it still fills its square

# The shoulders and ornaments, drawn in the ring's plane from the right half, top middle round to foot middle. The band's
# top is at z = 1.
SWELL = [(0.0, 1.22), (0.34, 1.2), (0.62, 1.0), (0.8, 0.72), (0.66, 0.62), (0.45, 0.86), (0.0, 0.98)]
SPADES = [(0.0, 1.24), (0.3, 1.22), (0.62, 1.06), (0.86, 1.12), (1.0, 0.86), (0.8, 0.66), (0.64, 0.66), (0.45, 0.88), (0.0, 0.98)]
HOOKS = [(0.0, 1.24), (0.34, 1.24), (0.5, 1.35), (0.56, 1.56), (0.46, 1.7), (0.6, 1.79), (0.84, 1.63), (0.9, 1.39), (0.8, 1.05),
         (0.84, 0.7), (0.68, 0.62), (0.45, 0.86), (0.0, 0.98)]
TINES = [(0.0, 1.22), (0.36, 1.22), (0.44, 1.42), (0.52, 1.76), (0.64, 1.42), (0.7, 1.2), (0.84, 0.74), (0.68, 0.62), (0.45, 0.86),
         (0.0, 0.98)]
STAR = [(0.0, 2.3), (0.18, 1.64), (0.92, 1.42), (0.3, 1.2), (0.62, 1.0), (0.8, 0.72), (0.66, 0.62), (0.45, 0.86),
        (0.0, 0.98)]
SHUTTLE = [(0.6, 0.92), (1.04, 1.2), (1.52, 1.24), (1.1, 0.86)]  # the right one: a pointed oval lying out along the shoulder


def crescent():
    """Horns up, to hold the stone: the inner arc from its foot to the right horn, then the outer arc back down."""
    c1, r1, c2, r2 = 1.62, 0.8, 1.9, 0.66
    tip = math.atan2(2.125 - c2, 0.62), math.atan2(2.125 - c1, 0.62)
    inner = [(r2 * math.cos(a), c2 + r2 * math.sin(a)) for a in (-math.pi / 2 + (tip[0] + math.pi / 2) * i / 9 for i in range(10))]
    outer = [(r1 * math.cos(a), c1 + r1 * math.sin(a)) for a in (tip[1] - (tip[1] + math.pi / 2) * i / 11 for i in range(1, 12))]
    return [(0.0, inner[0][1])] + inner[1:] + outer[:-1] + [(0.0, outer[-1][1])]


CRESCENT = crescent()


def design(name, rarity, note, band_mat, **more):
    return dict(dict(name=name, rarity=rarity, note=note, band_mat=band_mat, band="round", minor=0.11, wide=1.0, rims=None,
                     line=None, shoulders=None, trim=band_mat, shuttles=False, head=None, head_mat=band_mat, stone=None,
                     studs=None), **more)


DESIGNS = (
    design("Iron Ring", "Common", "A flat band of dark iron with one raised line round it.", "iron", wide=2.6, line="iron"),
    design("Bronze Ring", "Common", "A round bronze band with a plain signet top.", "bronze", minor=0.13, head="signet"),
    design("Scrap Ring", "Common", "Two turns of wire through a nut.", "scrap", band="wire", head="nut"),

    design("Lanternsteel Ring", "Uncommon", "A flat steel band with a brass rim on each edge, a low signet.", "steel",
           wide=2.4, rims="brass", head="signet"),
    design("Rowsmith Ring", "Uncommon", "A round steel band with a brass lozenge plate.", "steel", minor=0.12,
           shoulders=SWELL, head="plate", head_mat="brass"),
    design("Stallguard Ring", "Uncommon", "A flat steel band with three brass studs across its top.", "steel", wide=2.4,
           studs="brass"),

    design("Band of Embers", "Rare", "Shoulders that swell to one small stone in a round bezel, a line round the band.",
           "blued", wide=1.6, line="filigree", shoulders=SWELL, head="bezel", stone=("stone", 0.24)),
    design("Band of Hoarfrost", "Rare", "Spade shoulders, a square stone set on its corner.", "blued", wide=1.6,
           shoulders=SPADES, head="square", stone=("stone", 0.24)),
    design("Band of Gales", "Rare", "The band parts in two, like two streams, with one stone between them.", "blued",
           band="twin", head="bezel", stone=("stone", 0.24)),

    design("Stormcall Loop", "Epic", "Two filigree hooks rise from the shoulders and curl in over a glowing stone.", "rich",
           wide=1.6, line="filigree", shoulders=HOOKS, trim="filigree", head="bezel", stone=("glow", 0.3)),
    design("Gloamforge Loop", "Epic", "Two filigree tines stand beside a square stone set on its corner.", "rich", wide=1.6,
           shoulders=TINES, trim="filigree", head="square", stone=("glow", 0.3)),
    design("Nightloom Loop", "Epic", "A shuttle lies out along each shoulder, the stone in a bezel between them.", "rich",
           wide=1.6, line="filigree", shoulders=SWELL, trim="filigree", shuttles=True, head="bezel", stone=("glow", 0.3)),

    design("Kagaribi, the Watchfire", "Legendary", "Its one new form: the head is a watchfire's basket, and the stone "
           "burns in it.", "gilt", wide=1.6, rims="ivory", line="lit", shoulders=SWELL, trim="ivory", head="basket",
           stone=("lit", 0.38)),
    design("Yoiboshi, the Dusk Star", "Legendary", "Its one new form: a star of four points stands on the band, the stone at its heart.", "gilt",
           wide=1.6, rims="ivory", line="lit", shoulders=STAR, trim="ivory", head="star", stone=("lit", 0.34)),
    design("Ariake, the Pale Moon", "Legendary", "Its one new form: a crescent, horns up, holds the stone.", "gilt",
           wide=1.6, rims="ivory", line="lit", shoulders=CRESCENT, trim="ivory", head="held", stone=("lit", 0.32)),
)
assert all(len(d["name"]) <= 24 for d in DESIGNS), "a name is over 24 characters"


# --- the parts ---------------------------------------------------------------------------------------------------------

def hoop(name, major, minor, key, y=0.0, wide=1.0):
    """A torus standing in the ring's plane, `wide` times as broad along the finger as it's thick."""
    t = bl.place(bl.torus(name, major, minor, 56, 12, mat(key)), (0, 0, 0), (0, 0, 0), (1, 1, wide))
    return bl.smooth_by_angle(bl.place(t, (0, y, 0), (90, 0, 0)), 40.0)


def band(d):
    key, m, w = d["band_mat"], d["minor"], d["wide"]
    if d["band"] == "wire":
        return [hoop("Band", R, 0.075, key, y=-0.09), hoop("Band", R * 0.985, 0.075, key, y=0.09)]
    if d["band"] == "twin":
        return [hoop("Band", R, 0.08, key, y=-0.17), hoop("Band", R, 0.08, key, y=0.17)]
    parts = [hoop("Band", R, m, key, wide=w)]
    if d["rims"]:
        for side in (-1, 1):
            parts.append(hoop("Rim", R + m * 0.5, 0.04, d["rims"], y=side * m * w * 0.82))
    if d["line"]:
        parts.append(hoop("Line", R + m * 0.86, 0.03, d["line"]))
    return parts


def shoulders(d):
    parts, half = [], d["shoulders"]
    if half:
        parts.append(g.plate("Shoulders", g.mirrored(half), 0.26, d["trim"], bevel=0.05))
    if d["shuttles"]:
        for side in (-1, 1):
            parts.append(g.plate("Shuttle", [(side * x, z) for x, z in (SHUTTLE if side > 0 else SHUTTLE[::-1])], 0.3,
                                 d["trim"], bevel=0.05))
    if d["studs"]:
        for a in (-24, 0, 24):
            x, z = (R + 0.1) * math.sin(math.radians(a)), (R + 0.1) * math.cos(math.radians(a))
            parts.append(bl.place(bl.sphere("Stud", 0.13, 10, 6, mat(d["studs"])), (x, 0, z)))
    return parts


def gem(key, radius, z, sides=6):
    """A cut stone, its table up."""
    if sides == 4:  # a square stone on its corner: a low pyramid with its point cut off
        return bl.place(bl.cylinder("Stone", radius * 1.25, 0.26, segments=4, material=mat(key), radius_top=radius * 0.6),
                        (0, 0, z))
    return bl.place(bl.sphere("Stone", radius, segments=6, rings=3, material=mat(key)), (0, 0, z), (0, 0, 30), (1, 1, 0.7))


def head(d):
    kind, key, trim, parts = d["head"], d["head_mat"], d["trim"], []
    stone = d["stone"]
    if kind == "signet":
        parts.append(bl.bevel(bl.place(bl.cylinder("Head", 0.4, 0.2, segments=20, material=mat(key)), (0, 0, R + 0.12),
                                       (0, 0, 0), (1, 0.8, 1)), 0.04, segments=1))
    elif kind == "nut":
        parts.append(bl.bevel(bl.place(bl.cylinder("Head", 0.44, 0.34, segments=6, material=mat(key)), (0, 0, R + 0.02),
                                       (90, 0, 0)), 0.04, segments=1))
        parts.append(bl.place(bl.cylinder("Hole", 0.2, 0.36, segments=12, material=mat("leather")), (0, 0, R + 0.02), (90, 0, 0)))
    elif kind == "plate":
        parts.append(bl.bevel(bl.place(bl.cylinder("Head", 0.5, 0.16, segments=4, material=mat(key)), (0, 0, R + 0.2)), 0.04,
                              segments=1))
    elif kind == "bezel":
        parts.append(bl.place(bl.cylinder("Bezel", stone[1] * 1.3, 0.24, segments=16, material=mat(trim)), (0, 0, R + 0.22)))
        parts.append(gem(stone[0], stone[1], R + 0.38))
    elif kind == "square":
        parts.append(bl.place(bl.cylinder("Bezel", stone[1] * 1.7, 0.2, segments=4, material=mat(trim)), (0, 0, R + 0.2)))
        parts.append(gem(stone[0], stone[1], R + 0.4, sides=4))
    elif kind == "star":  # the stone at the star's heart, on each of its faces: a filled stone, no ring round it
        for side in (-1, 1):
            face = bl.sphere("Stone", stone[1], segments=6, rings=3, material=mat(stone[0]))
            parts.append(bl.place(face, (0, side * 0.1, 1.5), (0, 0, 30), (1, 0.5, 1)))
    elif kind == "held":  # in the crescent's lap
        parts.append(bl.place(bl.sphere("Stone", stone[1], 12, 8, mat(stone[0])), (0, 0, R + 0.58)))
    elif kind == "basket":  # a stem, a basket of eight sides that opens upward, a rim, three prongs, the stone in it
        parts.append(bl.place(bl.cylinder("Stem", 0.16, 0.2, segments=8, material=mat(key)), (0, 0, R + 0.16)))
        parts.append(bl.place(bl.cylinder("Basket", 0.24, 0.56, segments=8, material=mat(key), radius_top=0.58), (0, 0, R + 0.5)))
        parts.append(bl.place(bl.torus("Rim", 0.58, 0.05, 24, 8, mat(trim)), (0, 0, R + 0.78)))
        parts.append(bl.place(bl.sphere("Stone", stone[1], 12, 8, mat(stone[0])), (0, 0, R + 0.98), (0, 0, 0), (1, 1, 1.12)))
        for i in range(3):
            a = math.radians(120 * i + 90)
            x, y = math.cos(a), math.sin(a)
            path = [Vector((0.5 * x, 0.5 * y, R + 0.7)), Vector((0.56 * x, 0.56 * y, R + 1.05)), Vector((0.36 * x, 0.36 * y, R + 1.4))]
            parts.append(bl.tube_along("Prong", path, [0.05, 0.045, 0.03], sides=6, material=mat(trim)))
    return parts


def ring(d):
    """The ring in a scene of its own, leant back and turned."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Room")
    parts = band(d) + shoulders(d) + head(d)
    lay = Matrix.Rotation(math.radians(TILT), 4, "X") @ Matrix.Rotation(math.radians(SPIN), 4, "Z")
    for obj in parts:
        obj.data.transform(lay)
    return scene, parts


def renders(out):
    """Each centred in its square. The largest sets the scale; a plain ring is drawn up to it, to LEAST of the largest."""
    sizes = []
    for d in DESIGNS:
        x0, x1, z0, z1 = g.bounds(ring(d)[1])
        sizes.append(max(x1 - x0, z1 - z0))
    shots = {}
    for d, size in zip(DESIGNS, sizes):
        scene, parts = ring(d)
        x0, x1, z0, z1 = g.bounds(parts)
        span = max(size, LEAST * max(sizes)) / FILL
        shots[d["name"]] = g.shoot(scene, out, ((x0 + x1) / 2, (z0 + z1) / 2 + DROP * span), span)
        print(f"{d['name']}: fills {size / span:.2f} of the square")
    return shots


WORDS = dict(
    file="gear_ring_sets.png",
    title="Grow your Anime: Ring I in three designs at each rarity, in grey (AR6, batch 1)",
    lead="The batch's small piece: one band, leant back so its head faces the eye, widened by its own ornament. A design is "
         "its band, its shoulders and its head. A plain ring is drawn a little larger, so it still fills its square.",
    notes=(
        "A set keeps its word (the spec's examples \"Copper Ring\", \"Band of Static\" and \"Voidglint Loop\" give way to the sets). "
        "A ring's near word is Band at Rare and Loop at Epic.",
        "Each Legendary's one new form: Kagaribi (a watchfire), a basket for a head; Yoiboshi (the evening star), a star of four "
        "points under the stone; Ariake (the moon still up at daybreak), a crescent that holds it.",
        "\"Kagaribi, the Watchfire Ring\" is 28 characters, over the 24 a name may take: shown as \"Kagaribi, the Watchfire\", for "
        "research's call. Yoiboshi and Ariake are new names, for its check.",
        "For the verdict: does each read as a ring, and apart from its two neighbours, at 38 points? Does each Legendary outrank "
        "every Epic by shape? Not here yet: colour, frames.",
    ),
)


def main():
    out = bl.out_dir()
    s.sheet(out, renders(out), DESIGNS, WORDS)


if __name__ == "__main__":
    main()
