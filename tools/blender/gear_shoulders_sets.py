"""AR6, batch 2: Shoulders in three designs at each rarity, in grey: a blockout for research's verdict.

One family: a mantle, as it sits on a body seen from the front and a little above: a cop on each shoulder, its lames
stepping down the arm, a yoke plate over the shoulders between them, a standing collar round the neck. Wide, never
tall, so it never reads as the Helmet. Two cops on a strap read as goggles or worse, one cop alone as a helmet or a
bell (five tries, 2026-11-16): the yoke and the collar are what say shoulders. A design is the cop, its lames, and what
the cop carries. A rarity keeps the ladder's rule, a set
keeps its word (gear_parts.py), and the near word from Rare up is Pauldrons.

Each Legendary's one new form changes the silhouette: Noroshi carries a beacon's spire on its cop, Yoake's lames
sweep out into a folded wing, Isaribi's crest rises over the cop like a wave, holding a light under it.

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
TILT, SPIN = 24.0, 0.0     # from the front and a little above, as a mantle is seen on its wearer
FILL, DROP = 0.8, 0.0
LEAST = 0.86
X0, LEAN, DEEP = 1.36, 40.0, 0.92  # each cop's middle, how far it leans out over the arm, its depth to its width

COP = [(1.0, 0.0), (0.98, 0.22), (0.9, 0.46), (0.74, 0.68), (0.5, 0.84), (0.22, 0.93), (0.02, 0.96)]
OUTER = (-40.0, 220.0)     # the lames hang over the front, the outside and the back, never on the neck's side
SHELL = (-75.0, 255.0)     # the cop's own shell: open on the neck's side, so its hollow shows and it never reads as a dome

# The Legendaries' forms, drawn for the right cop in its own frame (x out over the arm, z up its axis).
WAVE = [(1.0, 0.3), (1.15, 0.7), (1.15, 1.1), (1.0, 1.45), (0.7, 1.72), (0.35, 1.78), (0.06, 1.62), (-0.08, 1.36),
        (0.16, 1.44), (0.42, 1.52), (0.66, 1.42), (0.82, 1.16), (0.85, 0.8), (0.72, 0.45)]


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(cop="round", lames=2, lame_mat=key, rims=None, studs=None,
                                                         ridge=False, lozenge=None, rivets=False, top=None, strap="leather",
                                                         guard=0.0),
                                                    **more))


DESIGNS = (
    design("Iron Shoulders", "Common", "Round iron cops, two lames each, on a plain yoke.", "iron"),
    design("Bronze Shoulders", "Common", "One deep bronze cup a side with a rolled rim and a button.", "bronze", cop="deep",
           lames=0, rims="bronze", top="button"),
    design("Scrap Shoulders", "Common", "Plates beaten flat and riveted, one lame, a strap over each.", "scrap",
           cop="facet", lames=1, rivets=True),

    design("Lanternsteel Shoulders", "Uncommon", "Bright steel, three lames, a brass rim on each.", "steel", lames=3,
           rims="brass"),
    design("Rowsmith Shoulders", "Uncommon", "A ridge over the cop and a brass lozenge on its face.", "steel",
           ridge=True, lozenge="brass"),
    design("Stallguard Shoulders", "Uncommon", "Three brass studs down the cop, a brass rim.", "steel", studs="brass",
           rims="brass", lames=1),

    design("Pauldrons of Embers", "Rare", "Two lames, a swelling frame round one small stone, a line round the cop.",
           "blued", line="filigree", orn="Embers", stone=("stone", 0.13)),
    design("Pauldrons of Hoarfrost", "Rare", "Cops cut in facets, a square stone in a spade.", "blued", cop="facet",
           line="filigree", orn="Hoarfrost", stone=("stone", 0.13), cut="square"),
    design("Pauldrons of Gales", "Rare", "A vane sweeps up and out from the cop, the stone below it.", "blued", lames=1,
           line="filigree", orn="Gales", stone=("stone", 0.13)),

    design("Stormcall Pauldrons", "Epic", "Two filigree hooks rise from the crown and curl out. A glowing stone.", "rich",
           trim="filigree", line="filigree", orn="Stormcall", stone=("glow", 0.17)),
    design("Gloamforge Pauldrons", "Epic", "Two filigree prongs stand on the crown, three lames, a square glowing stone.",
           "rich", trim="filigree", lames=3, orn="Gloamforge", stone=("glow", 0.17), cut="square"),
    design("Nightloom Pauldrons", "Epic", "A shuttle lies over the crown, four long lames, a glowing stone.", "rich",
           trim="filigree", lames=4, line="filigree", orn="Nightloom", stone=("glow", 0.17)),

    design("Noroshi, the Beacon", "Legendary", "Its one new form: a beacon's spire on the cop, its light at the point.",
           "gilt", trim="ivory", rims="ivory", orn="spire", stone=("lit", 0.15), edge=True, strap="ivory"),
    design("Yoake, the Daybreak", "Legendary", "Its one new form: the lames sweep out and down into a folded wing.", "gilt",
           trim="ivory", lames=1, orn="wing", stone=("lit", 0.15), edge=True, strap="ivory"),
    design("Isaribi, the Sea Lights", "Legendary", "Its one new form: a crest rises over the cop like a wave, a light "
           "under it.", "gilt", trim="ivory", rims="ivory", orn="wave", stone=("lit", 0.15), edge=True, strap="ivory"),
)


# --- one cop, in its own frame: z up its axis, x out over the arm -------------------------------------------------------

def arc_rim(name, radius, minor, key, z, a0, a1):
    t = bl.torus(name, radius, minor, 48, 8, mat(key), arc=a1 - a0)
    bl.place(t, (0, 0, 0), (0, 0, a0 - 90.0))
    return bl.smooth_by_angle(bl.place(t, (0, 0, z), (0, 0, 0), (1, DEEP, 1)), 40.0)


def cop(d, side):
    key, trim, parts = d["key"], d["trim"], []
    a0, a1 = OUTER if side > 0 else (-OUTER[1], -OUTER[0])
    s0, s1 = SHELL if side > 0 else (-SHELL[1], -SHELL[0])
    tall = 1.35 if d["cop"] == "deep" else 1.0
    steps = 9 if d["cop"] == "facet" else 48
    prof = [(r, z * tall) for r, z in COP]
    parts.append(p.lathe("Cop", prof, key, s0, s1, deep=DEEP, steps=steps))
    parts.append(p.lathe("Liner", [(r * 0.95, z * 0.95) for r, z in prof], "liner", s0, s1, deep=DEEP, thick=0.02,
                         steps=steps))
    for k in range(1, d["lames"] + 1):
        top, low = 0.08 - 0.22 * (k - 1), -0.2 - 0.22 * (k - 1)
        r0, r1 = 0.96 + 0.09 * k, 1.06 + 0.12 * k
        parts.append(p.lathe("Lame", [(r0, top), (r1, low)], d["lame_mat"], a0, a1, thick=0.05, deep=DEEP, steps=steps))
        if d["rims"]:
            parts.append(arc_rim("Rim", r1, 0.035, d["rims"], low, a0, a1))
    if d["rims"] and not d["lames"]:
        parts.append(arc_rim("Rim", 1.0, 0.06, d["rims"], 0.0, s0, s1))
    if d["line"]:
        parts.append(arc_rim("Line", 0.92, 0.025, d["line"], 0.42 * tall, s0, s1))
    if d["edge"]:
        parts.append(arc_rim("Edge", 1.02, 0.03, "lit", 0.02, s0, s1))
    if d["guard"]:
        h = d["guard"]
        fin = [(-0.66 * DEEP, 0.44), (-0.56 * DEEP, 0.7 + 0.16 * h), (-0.3 * DEEP, 0.88 + 0.3 * h), (0.0, 0.94 + 0.34 * h),
               (0.3 * DEEP, 0.88 + 0.3 * h), (0.56 * DEEP, 0.7 + 0.16 * h), (0.66 * DEEP, 0.44), (0.4 * DEEP, 0.6),
               (0.0, 0.68), (-0.4 * DEEP, 0.6)]
        parts.append(bl.profile("Guard", [(y, z * tall) for y, z in fin], 0.12, mat(d["trim"]), x=-0.5 * side))
    front = lambda z, r: (0.0, -r * DEEP - 0.04, z * tall)  # noqa: E731  a point on the cop's face
    if d["ridge"]:
        crest = [(-DEEP * 1.0, 0.0), (-DEEP * 0.98, 0.34), (-DEEP * 0.8, 0.72), (-DEEP * 0.4, 0.96), (0.0, 1.04),
                 (DEEP * 0.5, 0.94), (DEEP * 0.5, 0.86), (0.0, 0.94), (-DEEP * 0.38, 0.86), (-DEEP * 0.74, 0.62),
                 (-DEEP * 0.9, 0.3), (-DEEP * 0.92, 0.0)]
        parts.append(bl.profile("Ridge", [(y, z * tall) for y, z in crest], 0.1, mat(key)))
    if d["lozenge"]:
        parts.append(p.flat("Lozenge", [(0, 0.24), (0.2, 0), (0, -0.24), (-0.2, 0)], 0.06, d["lozenge"], y=front(0.5, 0.86)[1])
                     if False else bl.place(p.flat("Lozenge", [(0, 0.66), (0.22, 0.44), (0, 0.22), (-0.22, 0.44)], 0.06,
                                                   d["lozenge"]), (0, -0.84 * DEEP - 0.02, 0)))
    if d["studs"]:
        for z, r in ((0.26, 0.97), (0.5, 0.88), (0.72, 0.72)):
            parts.append(p.ball("Stud", 0.08, d["studs"], front(z, r)))
    if d["rivets"]:
        for a in range(int(s0) + 20, int(s1), 45):
            x, y = 0.98 * math.sin(math.radians(a)), -0.98 * DEEP * math.cos(math.radians(a))
            parts.append(p.ball("Rivet", 0.06, key, (x, y, 0.08), segments=8, rings=5))
        strap = [(0.0, -DEEP * 1.02, 0.1), (0.0, -DEEP * 0.9, 0.5), (0.0, -DEEP * 0.5, 0.88), (0.0, 0.0, 1.0),
                 (0.0, DEEP * 0.5, 0.88), (0.0, DEEP * 0.9, 0.5)]
        parts.append(p.tube("Strap", p.curve(strap, 16), 0.07, "leather", sides=8))
    if d["top"] == "button":
        parts.append(p.ball("Button", 0.13, key, (0, 0, 0.97 * tall), squash=(1, 1, 0.7)))

    # What the cop carries: the set's ornament round its stone, or a Legendary's new form.
    orn, stone_at = d["orn"], front(0.5, 0.9)
    size = 0.9
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.42, (0, 0.5 * tall)), 0.06, trim, y=stone_at[1] + 0.03))
    elif orn == "Gales":
        parts.append(p.flat("Vane", p.shifted(p.VANE, 0.55, 0.62, 1.05 * side, 1.05), 0.07, trim, y=-0.1))
        stone_at = front(0.36, 0.95)
    elif orn in ("Stormcall", "Gloamforge"):
        parts.append(p.flat("Crest", p.set_ornament(orn, 0.62, (0, 0.98 * tall + 0.16)), 0.08, trim, y=0.0))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, 1.0, 1.5, 1.4), 0.4, trim, y=0.0))
    elif orn == "spire":
        path = [(0, 0, 0.9), (0.06 * side, 0, 1.4), (0.1 * side, 0, 1.9), (0.12 * side, 0, 2.2)]
        parts.append(p.tube("Spire", path, [0.16, 0.11, 0.07, 0.04], key, sides=8))
        parts.append(p.lathe("Cup", [(0.05, 2.14), (0.2, 2.22), (0.26, 2.34)], trim, thick=0.04, steps=16))
        parts.append(p.move(p.ball("Light", 0.2, "lit", (0, 0, 2.42), squash=(1, 1, 1.2)),
                            Matrix.Translation((0.12 * side, 0, 0))))
    elif orn == "wing":
        for k, (angle, length) in enumerate(((-28, 1.65), (-50, 1.55), (-72, 1.42), (-94, 1.26), (-116, 1.08))):
            blade = p.turned(p.leaf(length, 0.36, bend=0.0), angle * side - 0.0 if side > 0 else -angle, (0, 0))
            blade = p.shifted(blade, 0.78 * side, 0.32 - 0.05 * k)
            parts.append(p.flat("Feather", blade, 0.06, trim if k % 2 else key, y=0.05 + 0.07 * k))
    elif orn == "wave":
        outline = WAVE if side > 0 else p.flipped(WAVE)
        parts.append(p.flat("Wave", outline, 0.1, trim, y=0.0))
        parts.append(p.ball("Light", 0.17, "lit", (0.42 * side, -0.08, 1.3)))
    parts += p.stone_of(d, size, stone_at)
    lean = Matrix.Translation((side * X0, 0, 0)) @ Matrix.Rotation(math.radians(LEAN * side), 4, "Y")
    for obj in parts:
        p.move(obj, lean)
    return parts


def build(d):
    def parts():
        out = cop(d, 1) + cop(d, -1)
        # the yoke: one plate over both shoulders, its front and back draping down
        out.append(p.sheet_surface("Yoke", d["key"], lambda u, v: (u, v, 0.8 - 0.14 * u * u - 0.42 * (v / 0.58) ** 2),
                                   [-1.0 + 2.0 * i / 16 for i in range(17)], [-0.58 + 1.16 * j / 8 for j in range(9)],
                                   thick=0.07))
        # the collar: a ring standing round the neck, flaring at its top
        out.append(p.lathe("Collar", [(0.56, 0.6), (0.48, 0.86), (0.5, 1.12), (0.58, 1.32), (0.68, 1.42)], d["trim"],
                           deep=0.8, thick=0.07, steps=40))
        return out
    return p.scene_of(parts, TILT, SPIN)


WORDS = dict(
    file="gear_shoulders_sets.png",
    title="Grow your Anime: Shoulders in three designs at each rarity, in grey (AR6, batch 2)",
    lead="A mantle as it sits on a body, from the front and a little above: a yoke across the chest and back, a standing "
         "collar, and a cop on each shoulder, its lames stepping down. A design is the cops, their lames and what they carry.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is Pauldrons.",
        "Each Legendary's one new form: Noroshi (a beacon fire), a spire on the cop with its light at the point; Yoake "
        "(daybreak), the lames sweep into a folded wing; Isaribi (fishing fires seen out at sea), a wave over a light.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as shoulders, and apart from its two neighbours, at 38 points? Does each Legendary "
        "outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
