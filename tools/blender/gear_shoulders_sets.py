"""AR6, batch 2: Shoulders in three designs at each rarity, in grey: a blockout for research's verdict.

One family: a mantle as it sits on a body, from the front and above, its collar leading: a standing collar round the
neck, a plate sloping from it over both shoulders, a shallow cop leant out on each, and the lames hanging straight down
from each cop's outer end as the arms hang. So the whole has the shoulders' own outline: the neck, the slope, the arms.
The lames are what say shoulders, so every design has at least two a side. The pair read as two cups joined while its
cops were deep and their lames leant out with them (research's verdict, 2026-11-16), and one pauldron alone read as a
helmet, a bell or a beetle in every pose tried (2026-11-16). A design is the cops, their lames, and what the cops carry.
A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Pauldrons.

Each Legendary's one new form changes the silhouette: Noroshi carries a beacon's spire on its cops, Yoake's cops grow
a folded wing that rises over two lames, Kaikou's crest rises over each cop like a wave, holding a light under it.

    blender -b --factory-startup --python tools/blender/gear_shoulders_sets.py -- build/handoff/Gear/shoulders_sets

Writes the sheet gear_shoulders_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 30.0, 0.0     # from the front and above, the collar leading
FILL, DROP = 0.8, 0.0
LEAST = 0.86
X0, LEAN, DEEP = 1.1, 34.0, 0.92   # each cop's middle, how far it leans out over the arm, its depth to its width
SIZE, SHALLOW = 0.72, 0.64         # the cop's width beside the mantle, and its height to its width
LAME, STEP = 0.36, 0.3             # each lame's height, and how far each hangs below the last: long, as an arm

COP = [(1.0, 0.0), (0.98, 0.22), (0.9, 0.46), (0.74, 0.68), (0.5, 0.84), (0.22, 0.93), (0.02, 0.96)]
OUTER = (-40.0, 220.0)     # the lames hang over the front, the outside and the back, never on the neck's side

# The Legendaries' forms, drawn for the right cop in its own frame (x out over the arm, z up its axis).
WAVE = [(1.0, 0.3), (1.15, 0.7), (1.15, 1.1), (1.0, 1.45), (0.7, 1.72), (0.35, 1.78), (0.06, 1.62), (-0.08, 1.36),
        (0.16, 1.44), (0.42, 1.52), (0.66, 1.42), (0.82, 1.16), (0.85, 0.8), (0.72, 0.45)]


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(cop="round", lames=3, lame_mat=key, rims=None, studs=None,
                                                         ridge=False, lozenge=None, rivets=False, top=None, strap="leather"),
                                                    **more))


DESIGNS = (
    design("Iron Shoulders", "Common", "Round iron cops, three lames a side, on a plain mantle.", "iron"),
    design("Bronze Shoulders", "Common", "A deep bronze cop a side with a button, three lames with rolled rims.",
           "bronze", cop="deep", rims="bronze", top="button"),
    design("Scrap Shoulders", "Common", "Plates beaten flat and riveted, a strap over each cop.", "scrap", cop="facet",
           rivets=True),

    design("Lanternsteel Shoulders", "Uncommon", "Bright steel, four lames a side, a brass rim on each.", "steel",
           lames=4, rims="brass"),
    design("Rowsmith Shoulders", "Uncommon", "A ridge over each cop and a brass lozenge on its face.", "steel",
           ridge=True, lozenge="brass"),
    design("Stallguard Shoulders", "Uncommon", "Three brass studs down each cop, brass rims.", "steel", studs="brass",
           rims="brass"),

    design("Pauldrons of Embers", "Rare", "A swelling frame round one small stone, a line round the cop.", "blued",
           line="filigree", orn="Embers", stone=("stone", 0.13)),
    design("Pauldrons of Hoarfrost", "Rare", "Cops cut in facets, a square stone in a spade.", "blued", cop="facet",
           line="filigree", orn="Hoarfrost", stone=("stone", 0.13), cut="square"),
    design("Pauldrons of Gales", "Rare", "A vane sweeps up and out from each cop, the stone below it.", "blued",
           line="filigree", orn="Gales", stone=("stone", 0.13)),

    design("Stormcall Pauldrons", "Epic", "Two filigree hooks rise from the crown and curl out. A glowing stone.", "rich",
           trim="filigree", line="filigree", orn="Stormcall", stone=("glow", 0.17)),
    design("Gloamforge Pauldrons", "Epic", "Two filigree prongs stand on the crown, a square glowing stone.", "rich",
           trim="filigree", orn="Gloamforge", stone=("glow", 0.17), cut="square"),
    design("Nightloom Pauldrons", "Epic", "A shuttle lies over the crown, four long lames, a glowing stone.", "rich",
           trim="filigree", lames=4, line="filigree", orn="Nightloom", stone=("glow", 0.17)),

    design("Noroshi, the Beacon", "Legendary", "Its one new form: a beacon's spire on each cop, its light at the point.",
           "gilt", trim="ivory", rims="ivory", orn="spire", stone=("lit", 0.15), edge=True, strap="ivory"),
    design("Yoake, the Daybreak", "Legendary", "Its one new form: a folded wing rises from each cop, two lames under "
           "it.", "gilt", trim="ivory", lames=2, orn="wing", stone=("lit", 0.15), edge=True, strap="ivory"),
    design("Kaikou, the Sea Light", "Legendary", "Its one new form: a crest rises over each cop like a wave, a light "
           "under it.", "gilt", trim="ivory", rims="ivory", orn="wave", stone=("lit", 0.15), edge=True, strap="ivory"),
)


# --- one cop, in its own frame: z up its axis, x out over the arm -------------------------------------------------------

def arc_rim(name, radius, minor, key, z, a0, a1):
    t = bl.torus(name, radius, minor, 48, 8, mat(key), arc=a1 - a0)
    bl.place(t, (0, 0, 0), (0, 0, a0 - 90.0))
    return bl.smooth_by_angle(bl.place(t, (0, 0, z), (0, 0, 0), (1, DEEP, 1)), 40.0)


def cop(d, side):
    """The cop and what it carries, built in its own frame, then made the mantle's size and leant out over the arm."""
    key, trim, parts = d["key"], d["trim"], []
    tall = SHALLOW * (1.35 if d["cop"] == "deep" else 1.0)
    rise = 0.96 * (tall - 1.0)       # what stands on the crown comes down with it
    steps = 9 if d["cop"] == "facet" else 48
    prof = [(r, z * tall) for r, z in COP]
    parts.append(p.lathe("Cop", prof, key, deep=DEEP, steps=steps))
    if d["rims"]:
        parts.append(arc_rim("Rim", 1.0, 0.05, d["rims"], 0.0, 0.0, 360.0))
    if d["line"]:
        parts.append(arc_rim("Line", 0.92, 0.025, d["line"], 0.42 * tall, 0.0, 360.0))
    if d["edge"]:
        parts.append(arc_rim("Edge", 1.02, 0.03, "lit", 0.02, 0.0, 360.0))
    front = lambda z, r: (0.0, -r * DEEP - 0.04, z * tall)  # noqa: E731  a point on the cop's face
    if d["ridge"]:
        crest = [(-DEEP * 1.0, 0.0), (-DEEP * 0.98, 0.34), (-DEEP * 0.8, 0.72), (-DEEP * 0.4, 0.96), (0.0, 1.04),
                 (DEEP * 0.5, 0.94), (DEEP * 0.5, 0.86), (0.0, 0.94), (-DEEP * 0.38, 0.86), (-DEEP * 0.74, 0.62),
                 (-DEEP * 0.9, 0.3), (-DEEP * 0.92, 0.0)]
        parts.append(bl.profile("Ridge", [(y, z * tall) for y, z in crest], 0.1, mat(key)))
    if d["lozenge"]:
        parts.append(bl.place(p.flat("Lozenge", [(0, 0.66 * tall), (0.22, 0.44 * tall), (0, 0.22 * tall),
                                                 (-0.22, 0.44 * tall)], 0.06, d["lozenge"]), (0, -0.84 * DEEP - 0.02, 0)))
    if d["studs"]:
        for z, r in ((0.26, 0.97), (0.5, 0.88), (0.72, 0.72)):
            parts.append(p.ball("Stud", 0.08, d["studs"], front(z, r)))
    if d["rivets"]:
        for a in range(20, 360, 45):
            x, y = 0.98 * math.sin(math.radians(a)), -0.98 * DEEP * math.cos(math.radians(a))
            parts.append(p.ball("Rivet", 0.06, key, (x, y, 0.08), segments=8, rings=5))
        strap = [(0.0, -DEEP * 1.02, 0.1), (0.0, -DEEP * 0.9, 0.5 * tall), (0.0, -DEEP * 0.5, 0.88 * tall),
                 (0.0, 0.0, 1.0 * tall), (0.0, DEEP * 0.5, 0.88 * tall), (0.0, DEEP * 0.9, 0.5 * tall)]
        parts.append(p.tube("Strap", p.curve(strap, 16), 0.07, d["strap"], sides=8))
    if d["top"] == "button":
        parts.append(p.ball("Button", 0.13, key, (0, 0, 0.97 * tall), squash=(1, 1, 0.7)))

    # What the cop carries: the set's ornament round its stone, or a Legendary's new form.
    orn, stone_at = d["orn"], front(0.5, 0.9)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.42, (0, 0.5 * tall)), 0.06, trim, y=stone_at[1] + 0.03))
    elif orn == "Gales":
        parts.append(p.flat("Vane", p.shifted(p.VANE, 0.55, 0.62 + rise, 1.05 * side, 1.05), 0.07, trim, y=-0.1))
        stone_at = front(0.36, 0.95)
    elif orn in ("Stormcall", "Gloamforge"):
        parts.append(p.flat("Crest", p.set_ornament(orn, 0.62, (0, 0.98 * tall + 0.16)), 0.08, trim, y=0.0))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, 1.0 + rise, 1.5, 1.4), 0.4, trim, y=0.0))
    elif orn == "spire":
        path = [(0, 0, 0.9 + rise), (0.06 * side, 0, 1.4 + rise), (0.1 * side, 0, 1.9 + rise),
                (0.12 * side, 0, 2.2 + rise)]
        parts.append(p.tube("Spire", path, [0.16, 0.11, 0.07, 0.04], key, sides=8))
        parts.append(p.lathe("Cup", [(0.05, 2.14 + rise), (0.2, 2.22 + rise), (0.26, 2.34 + rise)], trim, thick=0.04,
                             steps=16))
        parts.append(p.ball("Light", 0.2, "lit", (0.12 * side, 0, 2.42 + rise), squash=(1, 1, 1.2)))
    elif orn == "wing":
        # the wing grows from the cop and rises, so the two lames hang clear under it (research, 2026-11-16)
        for k, (angle, length) in enumerate(((14, 1.65), (-6, 1.55), (-26, 1.42), (-46, 1.26), (-66, 1.08))):
            blade = p.turned(p.leaf(length, 0.36, bend=0.0), angle if side > 0 else -angle, (0, 0))
            blade = p.shifted(blade, 0.78 * side, 0.32 - 0.05 * k)
            parts.append(p.flat("Feather", blade, 0.06, trim if k % 2 else key, y=0.05 + 0.07 * k))
    elif orn == "wave":
        outline = p.shifted(WAVE if side > 0 else p.flipped(WAVE), 0.0, rise)
        parts.append(p.flat("Wave", outline, 0.1, trim, y=0.0))
        parts.append(p.ball("Light", 0.17, "lit", (0.42 * side, -0.08, 1.3 + rise)))
    parts += p.stone_of(d, 0.9, stone_at)
    laid = (Matrix.Translation((side * X0, 0, -0.12)) @ Matrix.Rotation(math.radians(LEAN * side), 4, "Y")
            @ Matrix.Scale(SIZE, 4))
    for obj in parts:
        p.move(obj, laid)
    return parts


def lames(d, side):
    """The lames hang from the cop's outer end round the arm, each leaning a little less than the one above, so the
    last hangs straight as the arm does."""
    parts, n = [], d["lames"]
    a0, a1 = OUTER if side > 0 else (-OUTER[1], -OUTER[0])
    end_x = side * (X0 + SIZE * math.cos(math.radians(LEAN)))
    end_z = -0.12 - SIZE * math.sin(math.radians(LEAN))
    for k in range(n):
        r0, r1 = 0.5 + 0.04 * k, 0.57 + 0.05 * k
        band = [p.lathe("Lame", [(r0, 0.0), (r1, -LAME)], d["lame_mat"], a0, a1, thick=0.05, deep=DEEP, steps=48)]
        if d["rims"]:
            band.append(arc_rim("Rim", r1, 0.03, d["rims"], -LAME, a0, a1))
        lean = side * LEAN * (1.0 - (k + 1) / (n + 1))
        at = Matrix.Translation((end_x - side * 0.5, 0.0, end_z + 0.22 - STEP * k)) @ Matrix.Rotation(
            math.radians(lean), 4, "Y")
        for obj in band:
            parts.append(p.move(obj, at))
    return parts


def build(d):
    def parts():
        out = cop(d, 1) + cop(d, -1) + lames(d, 1) + lames(d, -1)
        # the mantle: one plate sloping from the collar out under both cops
        out.append(p.lathe("Mantle", [(0.44, 0.12), (0.8, 0.0), (1.15, -0.2), (1.35, -0.42)], d["key"], deep=0.62,
                           thick=0.05, steps=48))
        # the collar: a ring standing round the neck, flaring at its top
        out.append(p.lathe("Collar", [(0.42, 0.06), (0.4, 0.22), (0.42, 0.36), (0.5, 0.46)], d["trim"], deep=0.85,
                           thick=0.05, steps=40))
        # the collar's inside is lined dark: an empty garment, never a body
        out.append(p.lathe("Liner", [(0.38, 0.06), (0.36, 0.22), (0.38, 0.36), (0.46, 0.45)], "liner", deep=0.85,
                           thick=0.015, steps=40))
        return out
    return p.scene_of(parts, TILT, SPIN)


WORDS = dict(
    file="gear_shoulders_sets.png",
    title="Grow your Anime: Shoulders in three designs at each rarity, in grey (AR6, batch 2)",
    lead="A mantle as it sits on a body, from the front and above, its collar leading: a plate sloping over both "
         "shoulders, a cop leant out on each, its lames hanging down as the arm does. A design is the cops, their lames "
         "and what they carry.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is Pauldrons.",
        "Each Legendary's one new form: Noroshi (a beacon fire), a spire on the cop with its light at the point; Yoake "
        "(daybreak), a folded wing rising from each cop over its lames; Kaikou (the sea's own light), a wave over a "
        "light.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as shoulders, and apart from its two neighbours, at 38 points? Does each Legendary "
        "outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
