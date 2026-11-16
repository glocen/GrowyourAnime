"""AR6, batch 3: the Staff in three designs at each rarity, in grey: a blockout for research's verdict.

The Mage's main hand. One family: a long slim shaft laid on the diagonal, its head up and to the right, and the head
an open ring round a core held at its middle. Never a crystal: the crystal in prongs is the Healer's Baton, short and
stout, so the two never meet at 38 points; never a blade, so it's never the Great Axe. A design is the ring (round,
doubled, cut square), what holds the core (a stem, spokes, a cradle), what the ring carries, and the shaft's fittings.
A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Stave.

Each Legendary's one new form changes the silhouette: Kontengi's ring is an armillary, a second ring crossed through it
and an orbit tilted round both; Niji carries three arcs fanned over its ring; Yuuhi's shaft rises past its head into
a crook, and the ring hangs from the crook's tip, a sun going down.

    blender -b --factory-startup --python tools/blender/gear_staff_sets.py -- build/handoff/Gear/staff_sets

Writes the sheet gear_staff_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402
from mathutils import Euler, Vector  # noqa: E402

mat = p.mat
FILL, DROP, LEAST = 0.86, 0.0, 0.9
R, FOOT, NECK = 0.1, -1.9, 1.95     # the shaft's radius, its foot, where it meets the head
RING, MINOR = 1.15, 0.09            # the ring's radius and thickness
CORE = 2.0 + RING                    # the ring's middle, where the core sits


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(ring="round", hold="stem", core=0.26, shaft="wood",
                                                         shaft_bands=(), grip="leather", turns=0, collar=None,
                                                         butt="cap", knobs=False, fins=False, form=None), **more))


DESIGNS = (
    design("Iron Staff", "Common", "A plain iron ring on an ash shaft, an iron ball on a stem.", "iron",
           shaft_bands=(-1.0, 0.8)),
    design("Bronze Staff", "Common", "Three knobs round a bronze ring, the ball in a cradle.", "bronze",
           knobs=True, hold="cradle", butt="pear"),
    design("Scrap Staff", "Common", "A strap bent into a ring and wired to the shaft, a nut for a core.", "scrap",
           ring="strap", grip="cord", turns=5, shaft_bands=(1.3, 1.55)),

    design("Lanternsteel Staff", "Uncommon", "A steel ring doubled by a brass one inside, a brass collar.", "steel",
           trim="brass", ring="double", collar="brass", turns=6, butt="pear"),
    design("Rowsmith Staff", "Uncommon", "Three spokes hold the ball, brass bands down the shaft.", "steel",
           trim="brass", hold="spokes", shaft_bands=(-1.2, 1.2), turns=6),
    design("Stallguard Staff", "Uncommon", "Two short fins on the ring's sides, a brass collar and foot.", "steel",
           trim="brass", fins=True, collar="brass", butt="brass", turns=6),

    design("Stave of Embers", "Rare", "A swelling frame round the stone, a filigree line round the ring.", "blued",
           trim="filigree", orn="Embers", stone=("stone", 0.27), line="filigree", collar="filigree", turns=7,
           butt="facet"),
    design("Stave of Hoarfrost", "Rare", "The ring cut square on its corner, a square stone in a spade.", "blued",
           trim="filigree", ring="square", orn="Hoarfrost", stone=("stone", 0.27), cut="square", line="filigree",
           collar="filigree", turns=7, butt="facet"),
    design("Stave of Gales", "Rare", "A vane sweeping back off the ring, the stone on spokes.", "blued",
           trim="filigree", orn="Gales", hold="spokes", stone=("stone", 0.27), line="filigree", collar="filigree",
           turns=7, butt="facet"),

    design("Stormcall Stave", "Epic", "Filigree curls roll out from the ring's sides and its collar, a glowing stone.",
           "rich", trim="filigree", orn="Stormcall", stone=("glow", 0.3), line="filigree", shaft="rich",
           shaft_bands=(-1.2, 1.2), collar="filigree", turns=7, butt="spike"),
    design("Gloamforge Stave", "Epic", "Filigree prongs standing on the ring's crown, a square stone.", "rich",
           trim="filigree", orn="Gloamforge", stone=("glow", 0.3), cut="square", line="filigree", shaft="rich",
           hold="spokes", collar="filigree", turns=7, butt="spike"),
    design("Nightloom Stave", "Epic", "A shuttle laid through the ring, the stone on its middle.", "rich",
           trim="filigree", orn="Nightloom", stone=("glow", 0.3), line="filigree", shaft="rich", hold="none",
           collar="filigree", turns=7, butt="spike"),

    design("Kontengi, the Sky Sphere", "Legendary", "Its one new form: a second ring crossed through the first, an "
           "orbit tilted round both.", "gilt", trim="ivory", stone=("lit", 0.3), shaft="ivory", collar="ivory",
           turns=7, butt="facet", form="sphere", edge=True),
    design("Niji, the Rainbow Arch", "Legendary", "Its one new form: three arcs fanned over the ring.", "gilt",
           trim="ivory", stone=("lit", 0.3), shaft="ivory", collar="ivory", turns=7, butt="facet", form="arch",
           edge=True),
    design("Yuuhi, the Setting Sun", "Legendary", "Its one new form: the shaft rises into a crook, the ring hung "
           "from its tip.", "gilt", trim="ivory", stone=("lit", 0.3), shaft="ivory", collar="ivory", turns=7,
           butt="facet", form="crook", edge=True),
)


def ring_parts(d, centre):
    """The ring, open at its foot where the neck comes in, and what it carries."""
    key, trim, parts = d["key"], d["trim"], []
    cx, cz = centre
    kind = d["ring"]
    if kind == "square":
        pts = [(cx, 0, cz - RING * 1.12), (cx + RING * 1.12, 0, cz), (cx, 0, cz + RING * 1.12), (cx - RING * 1.12, 0, cz)]
        pts = pts + pts[:2]
        parts.append(p.tube("Ring", pts, MINOR * 1.2, key, sides=6))
    elif kind == "strap":
        parts.append(p.facing("Ring", RING, MINOR * 1.3, key, (cx, 0, cz), arc=330.0, turn=285.0))
        for a in (40.0, 140.0):
            x, z = cx + RING * math.cos(math.radians(a)), cz + RING * math.sin(math.radians(a))
            parts.append(p.ball("Wire", 0.1, "iron", (x, 0, z), squash=(1, 1.4, 1), segments=8, rings=6))
    else:
        parts.append(p.facing("Ring", RING, MINOR, key, (cx, 0, cz), arc=330.0, turn=285.0))
    if kind == "double":
        parts.append(p.facing("Inner", RING * 0.8, MINOR * 0.6, trim, (cx, 0, cz), arc=320.0, turn=290.0))
    if d["line"] and kind != "square":
        parts.append(p.facing("Line", RING + 0.11, 0.022, d["line"], (cx, -0.02, cz), arc=300.0, turn=300.0))
    if d["edge"]:
        parts.append(p.facing("Edge", RING - 0.09, 0.024, "lit", (cx, -0.04, cz), arc=320.0, turn=290.0))
    if d["knobs"]:
        for a in (0.0, 90.0, 180.0):
            x, z = cx + RING * math.cos(math.radians(a)), cz + RING * math.sin(math.radians(a))
            parts.append(p.ball("Knob", 0.13, key, (x, 0, z), segments=10, rings=6))
    if d["fins"]:
        for side in (-1, 1):
            fin = [(0.0, 0.18), (0.38, 0.05), (0.42, -0.28), (0.0, -0.14)]
            parts.append(p.flat("Fin", [(cx + side * (RING + x), cz + z) for x, z in fin], 0.06, trim))
    return parts


def core_parts(d, centre):
    key, trim, parts = d["key"], d["trim"], []
    cx, cz = centre
    hold = d["hold"]
    if hold == "stem":
        parts.append(p.rod("Stem", cz - RING, cz, 0.05, key, at=(cx, 0.0)))
    elif hold == "spokes":
        for a in (-90.0, 30.0, 150.0):
            x, z = math.cos(math.radians(a)), math.sin(math.radians(a))
            parts.append(p.tube("Spoke", [(cx + x * RING, 0, cz + z * RING), (cx, 0, cz)], 0.035, trim, sides=6))
    elif hold == "cradle":
        for side in (-1, 1):
            pts = [(cx, 0, cz - RING), (cx + side * 0.22, 0, cz - 0.42), (cx + side * 0.3, 0, cz - 0.08),
                   (cx + side * 0.2, 0, cz + 0.2)]
            parts.append(p.tube("Cradle", p.curve(pts, 12), 0.04, key, sides=6))
    if d["stone"]:
        parts += p.stone_of(d, 1.0, (cx, -0.02, cz))
    elif d["key"] == "scrap":
        nut = bl.cylinder("Nut", 0.24, 0.16, segments=6, material=mat("iron"))
        parts.append(bl.place(nut, (cx, 0, cz), (90, 0, 0)))
        parts.append(bl.place(bl.cylinder("Hole", 0.1, 0.18, segments=12, material=mat("liner")), (cx, 0, cz), (90, 0, 0)))
    else:
        parts.append(p.ball("Core", d["core"], key, (cx, 0, cz), segments=20, rings=12))

    orn = d["orn"]
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.62, (cx, cz)), 0.05, trim, y=0.02))
    elif orn == "Gales":
        vane = p.turned(p.shifted(p.VANE, 0, 0, 1.0, 1.0), -45.0)
        parts.append(p.flat("Vane", p.shifted(vane, cx + RING * 0.7, cz - RING * 0.55), 0.07, trim))
    elif orn == "Stormcall":
        for side in (-1, 1):
            parts.append(p.curl((cx + side * RING, cz - 0.12), side, 0.95, trim, turn=-10.0))
            parts.append(p.curl((cx + side * 0.1, NECK + 0.02), side, 0.5, trim, turn=-20.0))
    elif orn == "Gloamforge":
        parts.append(p.flat("Crest", p.set_ornament(orn, 0.85, (cx, cz + RING + 0.25)), 0.08, trim))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, cx, cz, 3.0, 2.0), 0.1, trim, y=0.04))
    return parts


def form_parts(d):
    """The Legendaries' new forms."""
    trim, parts, form = d["trim"], [], d["form"]
    if form == "sphere":
        cross = bl.torus("Cross", RING, MINOR * 0.8, 40, 8, mat(d["key"]))
        parts.append(bl.smooth_by_angle(bl.place(cross, (0, 0, CORE), (0, 90, 0)), 40.0))
        orbit = bl.torus("Orbit", RING * 1.32, 0.05, 48, 8, mat(trim))
        parts.append(bl.smooth_by_angle(bl.place(orbit, (0, 0, CORE), (68, 0, -22)), 40.0))
        turn = Euler((math.radians(68), 0, math.radians(-22)), "XYZ").to_matrix()
        for a in (30.0, 160.0, 250.0):
            at = turn @ Vector((RING * 1.32 * math.cos(math.radians(a)), RING * 1.32 * math.sin(math.radians(a)), 0))
            parts.append(p.ball("Bead", 0.09, "lit", (at.x, at.y, CORE + at.z), segments=8, rings=6))
    elif form == "arch":
        for k, (r, key) in enumerate(((RING + 0.28, trim), (RING + 0.5, d["key"]), (RING + 0.72, trim))):
            parts.append(p.facing("Arc", r, 0.065, key, (0, 0.04 * k, CORE), arc=200.0, turn=-10.0))
        parts.append(p.facing("Arc", RING + 0.39, 0.025, "lit", (0, -0.06, CORE), arc=196.0, turn=-8.0))
    return parts


def staff(d):
    key, trim, parts = d["key"], d["trim"], []
    if d["form"] == "crook":
        top = NECK + 2 * RING + 0.6
        pts = [(0, 0, NECK), (0, 0, top), (-0.12, 0, top + 0.45), (-0.55, 0, top + 0.72), (-1.05, 0, top + 0.6),
               (-1.3, 0, top + 0.2), (-1.28, 0, top - 0.12)]
        parts.append(p.tube("Crook", p.curve(pts, 30), [0.11] * 30, d["shaft"], sides=12))
        parts.append(p.ball("Tip", 0.14, trim, (-1.28, 0, top - 0.14)))
        centre = (-1.28, top - 0.42 - RING - 0.2)
        for k in range(2):
            parts.append(p.facing("Link", 0.08, 0.025, trim, (-1.28, 0, top - 0.28 - 0.14 * k), turn=90.0 * k))
        parts.append(p.facing("Ring", RING, MINOR, key, (centre[0], 0, centre[1])))
        parts.append(p.facing("Edge", RING - 0.09, 0.024, "lit", (centre[0], -0.04, centre[1])))
        for a in (-90.0, 30.0, 150.0):
            x, z = math.cos(math.radians(a)), math.sin(math.radians(a))
            parts.append(p.tube("Spoke", [(centre[0] + x * RING, 0, centre[1] + z * RING), (centre[0], 0, centre[1])],
                                0.03, trim, sides=6))
        parts += p.stone_of(d, 1.0, (centre[0], -0.02, centre[1]))
    else:
        parts += ring_parts(d, (0.0, CORE))
        parts += core_parts(d, (0.0, CORE))
        parts += form_parts(d)
    parts.append(p.rod("Neck", NECK - 0.1, CORE - RING + 0.05, R * 0.9, key, top=R * 0.7))
    parts.append(p.rod("Shaft", FOOT, NECK, R, d["shaft"]))
    if d["collar"]:
        parts.append(p.rod("Collar", NECK - 0.2, NECK + 0.08, R * 1.7, d["collar"], top=R * 1.25, sides=10))
    band_key = trim if d["shaft"] != "wood" else "iron" if key == "scrap" else key
    parts += p.bands(d["shaft_bands"], R, band_key)
    if d["turns"]:
        parts += p.grip_wrap(-0.75, 0.45, R + 0.012, d["grip"], d["turns"])
    butt = d["butt"]
    parts += p.butt("cap" if butt == "brass" else butt, FOOT, R,
                    "brass" if butt == "brass" else trim if d["rarity"] != "Common" else key)
    return p.laid(parts, spin=12.0)


def build(d):
    return p.scene_of(lambda: staff(d), 0.0, 0.0)


WORDS = dict(
    file="gear_staff_sets.png",
    title="Grow your Anime: the Staff in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Mage's main hand: a long slim shaft on the diagonal, its head an open ring round a core. Never a crystal "
         "(the Healer's Baton) and never a blade. A design is the ring, what holds the core, what the ring carries and the shaft.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Stave.",
        "Each Legendary's one new form: Kontengi (an armillary sphere), an armillary of crossed rings; Niji (a rainbow), "
        "three arcs over the ring; Yuuhi (the setting sun), a crook with the ring hung from it.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a staff, and apart from its two neighbours, at 38 points? Does each "
        "Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
