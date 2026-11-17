"""AR6, batch 2: Shoulders in three designs at each rarity, in grey: a blockout for research's verdict.

One family: one pauldron as it sits on the right shoulder, from the front and above, turned a little toward its
outside (the director, 2026-11-17, 12:19: the pictures showed "both shoulders when it should once face 1"). The cop
and its lames share the arm's line, ARM degrees out from straight down, so the cup opens down and out over the arm and
the lames fan down it (research's must-fix, 13:15). What the cop carries lies on its face along the rim: the stone on
the rim, the set's ornament round it or running from it. A dome seen crown up read as a helmet, a bell or a beetle in
every pose tried, its stone in the middle as an eye and its standing crests as feelers (2026-11-16 and 17). The lames
are what say shoulders, so every design has at least two. A design is the cop, its lames, and what the cop carries.
A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Pauldrons.

Each Legendary's one new form: Noroshi's beacon rod runs round the rim to the shoulder's point, its light at the end;
Yoake's folded wing lies back along its rim over its two lames; Kaikou's wave curls along the rim, holding a light under it.

    blender -b --factory-startup --python tools/blender/gear_shoulders_sets.py -- build/handoff/Gear/shoulders_sets

Writes the sheet gear_shoulders_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 30.0, -20.0   # from the front and above, turned a little toward the shoulder's outside
FILL, DROP = 0.8, 0.0
LEAST = 0.86
X0, Z0, DEEP = 1.0, -0.1, 0.92     # the cop's middle, and its depth to its width
SIZE, SHALLOW = 0.72, 0.5          # the cop's width beside the plate, and its height to its width: low, a shell
ARM = 35.0     # the arm's line, degrees out from straight down: the cop's axis and every lame's, so the cup opens down
#                and out over the arm (research, 2026-11-17, 13:15)
FAN = 6.0      # each lame turns this much further out than the one above, so the lames fan down the arm
LAME, STEP = 0.5, 0.36             # in the cop's own size: each lame's height, and how far each hangs below the last

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
    design("Iron Shoulders", "Common", "A round iron cop and three lames.", "iron"),
    design("Bronze Shoulders", "Common", "A deep bronze cop with a button, three lames with rolled rims.",
           "bronze", cop="deep", rims="bronze", top="button"),
    design("Scrap Shoulders", "Common", "Plates beaten flat and riveted, a strap over the cop.", "scrap", cop="facet",
           rivets=True),

    design("Lanternsteel Shoulders", "Uncommon", "Bright steel, four lames, a brass rim on each.", "steel",
           lames=4, rims="brass"),
    design("Rowsmith Shoulders", "Uncommon", "A ridge over the cop and a brass lozenge on its face.", "steel",
           ridge=True, lozenge="brass"),
    design("Stallguard Shoulders", "Uncommon", "Three brass studs down the cop, brass rims.", "steel", studs="brass",
           rims="brass"),

    design("Pauldrons of Embers", "Rare", "A swelling frame round one small stone, a line round the cop.", "blued",
           line="filigree", orn="Embers", stone=("stone", 0.13)),
    design("Pauldrons of Hoarfrost", "Rare", "Cops cut in facets, a square stone in a spade.", "blued", cop="facet",
           line="filigree", orn="Hoarfrost", stone=("stone", 0.13), cut="square"),
    design("Pauldrons of Gales", "Rare", "A vane sweeps from the stone along the rim.", "blued",
           line="filigree", orn="Gales", stone=("stone", 0.13)),

    design("Stormcall Pauldrons", "Epic", "Two filigree hooks curl out along the rim from a glowing stone.", "rich",
           trim="filigree", line="filigree", orn="Stormcall", stone=("glow", 0.17)),
    design("Gloamforge Pauldrons", "Epic", "Two filigree prongs lie along the rim, a square glowing stone.", "rich",
           trim="filigree", orn="Gloamforge", stone=("glow", 0.17), cut="square"),
    design("Nightloom Pauldrons", "Epic", "A shuttle lies along the rim, four long lames, a glowing stone.", "rich",
           trim="filigree", lames=4, line="filigree", orn="Nightloom", stone=("glow", 0.17)),

    design("Noroshi, the Beacon", "Legendary", "Its one new form: a beacon's rod round the rim, its light at the shoulder's point.",
           "gilt", trim="ivory", rims="ivory", orn="spire", stone=("lit", 0.15), edge=True, strap="ivory"),
    design("Yoake, the Daybreak", "Legendary", "Its one new form: a folded wing laid back along the "
           "rim, over its two lames.", "gilt", trim="ivory", lames=2, orn="wing", stone=("lit", 0.15), edge=True, strap="ivory"),
    design("Kaikou, the Sea Light", "Legendary", "Its one new form: a crest curls along the rim like a "
           "wave, a light under it.", "gilt", trim="ivory", rims="ivory", orn="wave", stone=("lit", 0.15), edge=True, strap="ivory"),
)


# --- one cop, in its own frame: z up its axis, x out over the arm -------------------------------------------------------

def arc_rim(name, radius, minor, key, z, a0, a1):
    t = bl.torus(name, radius, minor, 48, 8, mat(key), arc=a1 - a0)
    bl.place(t, (0, 0, 0), (0, 0, a0 - 90.0))
    return bl.smooth_by_angle(bl.place(t, (0, 0, z), (0, 0, 0), (1, DEEP, 1)), 40.0)


def lay(objs, base, at, turn=0.0, scale=(1.0, 1.0)):
    """What stood on the crown, laid on the cop's face at its rim: `base` (x, z), where it stood, comes to `at`, turned
    `turn` degrees in the face's plane and scaled across and up."""
    m = (Matrix.Translation(at) @ Matrix.Rotation(math.radians(turn), 4, "Y")
         @ Matrix.Diagonal((scale[0], scale[0], scale[1], 1.0)) @ Matrix.Translation((-base[0], 0.0, -base[1])))
    for obj in objs:
        p.move(obj, m)
    return objs


def cop(d, side=1):
    """The cop and what it carries, in the piece's own frame: z up the cop's axis, x out toward the arm, its front -y."""
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

    # What the cop carries lies on its face at the rim's front: the stone on the rim, the set's ornament round it or
    # running from it along the rim. On the crown, the crests and the Beacon's rod read as feelers, and a stone in the
    # dome's middle as an eye (research, 2026-11-17, 13:15).
    orn, rim = d["orn"], 0.2
    stone_at = front(rim, 0.98)
    face = stone_at[1] + 0.02
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.42, (0, rim * tall)), 0.06, trim, y=face + 0.01))
    elif orn == "Gales":
        vane = [p.flat("Vane", p.shifted(p.VANE, 0.55, 0.62 + rise, 1.05, 1.05), 0.07, trim, y=0.0)]
        parts += lay(vane, (0.55, 0.62 + rise), (0.12, face, rim * tall), -70.0, (0.55, 0.55))
    elif orn in ("Stormcall", "Gloamforge"):
        crest = [p.flat("Crest", p.set_ornament(orn, 0.62, (0, 0.98 * tall + 0.16)), 0.08, trim, y=0.0)]
        parts += lay(crest, (0.0, 0.98 * tall), (0.0, face, rim * tall + 0.06), 0.0, (0.95, 0.42))
    elif orn == "Nightloom":
        shuttle = [p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, 1.0 + rise, 1.5, 1.4), 0.2, trim, y=0.0)]
        parts += lay(shuttle, (0.0, 1.0 + rise), (0.0, face, rim * tall + 0.1), 0.0, (0.62, 0.5))
    elif orn == "spire":
        # the beacon's rod runs round the rim from the front to the shoulder's point, its cup and light at its end
        path = [(1.05 * math.sin(math.radians(a)), -1.05 * DEEP * math.cos(math.radians(a)) - 0.04, (rim + 0.04 * a / 90)
                 * tall) for a in range(-10, 91, 20)]
        end = Vector(path[-1]) + Vector((0.18, 0.0, 0.0))
        rod = p.curve(path + [tuple(end)], 20)
        parts.append(p.tube("Spire", rod, [0.1 - 0.05 * i / (len(rod) - 1) for i in range(len(rod))], key, sides=8))
        parts.append(bl.place(p.lathe("Cup", [(0.05, 0.0), (0.18, 0.08), (0.24, 0.2)], trim, thick=0.04, steps=16),
                              tuple(end), (0, 90, 0)))
        parts.append(p.ball("Light", 0.17, "lit", tuple(end + Vector((0.24, 0.0, 0.0))), squash=(1.2, 1, 1)))
    elif orn == "wing":
        # the folded wing laid back from the stone along the rim, over the lames toward the arm
        wing = []
        for k, (angle, length) in enumerate(((14, 1.65), (-6, 1.55), (-26, 1.42), (-46, 1.26), (-66, 1.08))):
            blade = p.shifted(p.turned(p.leaf(length, 0.36, bend=0.0), angle, (0, 0)), 0.0, -0.05 * k)
            wing.append(p.flat("Feather", blade, 0.06, trim if k % 2 else key, y=-0.07 * k))
        parts += lay(wing, (0.0, 0.0), (0.22, face - 0.12, rim * tall + 0.05), 100.0, (0.95, 0.95))
    elif orn == "wave":
        # the wave curls along the rim from the stone toward the arm, its light under the curl
        wave = [p.flat("Wave", WAVE, 0.1, trim, y=0.0), p.ball("Light", 0.17, "lit", (0.42, -0.08, 1.3))]
        parts += lay(wave, (0.3, 0.3), (0.1, face - 0.06, rim * tall - 0.04), 0.0, (0.95, 0.6))
    parts += p.stone_of(d, 0.9, stone_at)
    return parts


def lames(d):
    """The lames round the arm under the cop, on its axis, each a little wider than the one above and turned FAN
    further out, so they fan down the arm. They wrap the front, the outside and the back, never the neck's side."""
    parts = []
    for k in range(d["lames"]):
        r0 = 0.97 + 0.05 * k
        r1 = r0 + 0.12
        band = [p.lathe("Lame", [(r0, 0.0), (r1, -LAME)], d["lame_mat"], *OUTER, thick=0.06, deep=DEEP, steps=48)]
        if d["rims"]:
            band.append(arc_rim("Rim", r1, 0.04, d["rims"], -LAME, *OUTER))
        at = (Matrix.Rotation(math.radians(-FAN * (k + 1)), 4, "Y")
              @ Matrix.Translation((0.0, 0.0, -0.08 - STEP * k)))
        for obj in band:
            parts.append(p.move(obj, at))
    return parts


def build(d):
    def parts():
        # the cop and its lames on the arm's line, the cup opening down and out over the arm
        laid = (Matrix.Translation((X0, 0.0, Z0)) @ Matrix.Rotation(math.radians(-ARM), 4, "Y")
                @ Matrix.Scale(SIZE, 4))
        return [p.move(obj, laid) for obj in cop(d) + lames(d)]
    return p.scene_of(parts, TILT, SPIN)


WORDS = dict(
    file="gear_shoulders_sets.png",
    title="Grow your Anime: Shoulders in three designs at each rarity, in grey (AR6, batch 2)",
    lead="One pauldron as it sits on the right shoulder, from the front and above: the cop and its lames on the arm's "
         "line, the cup opening down and out, the lames fanning down the arm. A design is the cop, its lames and what it "
         "carries, laid along its rim.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is Pauldrons.",
        "Each Legendary's one new form: Noroshi (a beacon fire), a rod round the rim with its light at the shoulder's "
        "point; Yoake (daybreak), a folded wing laid back along the rim over its lames; Kaikou (the sea's own light), a wave along the rim over "
        "a light.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as shoulders, and apart from its two neighbours, at 38 points? Does each Legendary "
        "outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
