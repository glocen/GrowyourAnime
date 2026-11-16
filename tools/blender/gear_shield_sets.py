"""AR6, batch 3: the Shield in three designs at each rarity, in grey: a blockout for research's verdict.

The Tank's off hand. One family: a heater shield, flat-topped and drawn to a point at its foot, its face bowed toward
the viewer and turned a little so its rim shows. No other class holds a broad face, so it's never the Tome or the
Codex at 38 points. A design is the top's line (flat, arched, raised at the shoulders, cut square), the rim, the boss
and the bands, and what the face carries. A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py), and
the near word from Rare up is Bulwark. No band crosses another on the face.

Each Legendary's one new form changes the silhouette: Hakuchuu carries a sun's rays fanned behind its top; Kousai's
face holds a round mirror whose ring stands out past the shield's sides and top; Fuyuboshi stands before an
eight-pointed star whose points show past its corners.

    blender -b --factory-startup --python tools/blender/gear_shield_sets.py -- build/handoff/Gear/shield_sets

Writes the sheet gear_shield_sets.png. Workbench only: no GPU turn.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = -6.0, -24.0
FILL, DROP, LEAST = 0.86, 0.0, 0.88
HALF, BOW, THICK = 1.3, 0.26, 0.12      # the face's half width for its bow, how far it bows, its thickness

# Right halves, each as spans from the top's middle round to the foot's point. The corners between spans stay sharp.
SIDE = [(1.24, 0.66), (1.12, -0.06), (0.85, -0.76), (0.45, -1.28), (0.0, -1.62)]
HEATER = ([(0.0, 1.5), (1.24, 1.5)], [(1.24, 1.5)] + SIDE)
ARCHED = ([(0.0, 1.78), (0.62, 1.7), (1.05, 1.5), (1.24, 1.22)], [(1.24, 1.22)] + SIDE)
RAISED = ([(0.0, 1.34), (0.55, 1.42), (1.0, 1.64), (1.32, 1.8)], [(1.32, 1.8), (1.24, 1.2)] + SIDE)
SQUARE = ([(0.0, 1.5), (0.92, 1.5)], [(0.92, 1.5), (1.24, 1.18)], [(1.24, 1.18), (1.24, 0.35)], [(1.24, 0.35), (0.0, -1.62)])
SLANT_R = ([(0.0, 1.45), (1.24, 1.28)], [(1.24, 1.28)] + SIDE)        # Scrap's: cut on a slant
SLANT_L = ([(0.0, 1.45), (1.24, 1.62)], [(1.24, 1.62)] + SIDE)
SWEPT_R = ([(0.0, 1.5), (0.7, 1.6), (1.15, 1.88), (1.44, 2.18)], [(1.44, 2.18), (1.26, 1.4)] + SIDE)  # Gales: one wing


def whole(right, left=None):
    """The whole outline, clockwise from the top's middle: the right half, then the left (the right's mirror unless
    given)."""
    r = p.outline_of(right)
    l = p.outline_of(left if left else right)
    return r + [(-x, z) for x, z in reversed(l) if x > 1e-6]


def inside(outline, x, z, margin=0.0):
    """Whether (x, z) lies inside the outline, at least `margin` from its edge (checked at four neighbours)."""
    def within(px, pz):
        hit = False
        for (x0, z0), (x1, z1) in zip(outline, outline[1:] + outline[:1]):
            if (z0 > pz) != (z1 > pz) and px < x0 + (x1 - x0) * (pz - z0) / (z1 - z0):
                hit = not hit
        return hit
    return all(within(x + dx, z + dz) for dx, dz in ((0, 0), (margin, 0), (-margin, 0), (0, margin), (0, -margin)))


def inset(outline, k=0.86, c=0.08):
    return [(x * k, c + (z - c) * k) for x, z in outline]


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(shape=(HEATER,), face=key, rim=None, boss=None, rivets=0,
                                                         bands=(), chevron=False, planks=False, behind=None,
                                                         mirror=False), **more))


DESIGNS = (
    design("Iron Shield", "Common", "A plain heater of iron, a round boss, a ring of rivets.", "iron",
           rim="iron", boss=0.34, rivets=14),
    design("Bronze Shield", "Common", "An arched top, two raised bands across, a small boss.", "bronze",
           shape=(ARCHED,), rim="bronze", boss=0.26, bands=(0.85, -0.45)),
    design("Scrap Shield", "Common", "Planks cut on a slant, two iron straps bolted across.", "scrap",
           shape=(SLANT_R, SLANT_L), face="wood", rim="scrap", planks=True, bands=(0.8, -0.35), rivets=0),

    design("Lanternsteel Shield", "Uncommon", "A bright steel heater, a brass rim, a brass boss in its ring.", "steel",
           trim="brass", rim="brass", boss=0.36, rivets=14),
    design("Rowsmith Shield", "Uncommon", "An arched top, a brass chevron pointing down the face.", "steel",
           trim="brass", shape=(ARCHED,), rim="brass", chevron=True, rivets=10),
    design("Stallguard Shield", "Uncommon", "Shoulders raised, one brass band across, a boss over it.", "steel",
           trim="brass", shape=(RAISED,), rim="brass", bands=(0.2,), boss=0.3),

    design("Bulwark of Embers", "Rare", "A swelling frame round one stone, a filigree line inside the rim.", "blued",
           trim="filigree", rim="filigree", line="filigree", orn="Embers", stone=("stone", 0.26)),
    design("Bulwark of Hoarfrost", "Rare", "Cut square at its corners, a square stone in a spade.", "blued",
           trim="filigree", shape=(SQUARE,), rim="filigree", line="filigree", orn="Hoarfrost", stone=("stone", 0.26),
           cut="square"),
    design("Bulwark of Gales", "Rare", "One shoulder swept up like a wing, a vane from the stone.", "blued",
           trim="filigree", shape=(SWEPT_R, HEATER), rim="filigree", line="filigree", orn="Gales",
           stone=("stone", 0.26)),

    design("Stormcall Bulwark", "Epic", "Filigree curls roll out from its two top corners, a glowing stone.", "rich",
           trim="filigree", rim="filigree", line="filigree", orn="Stormcall", stone=("glow", 0.3), rivets=10),
    design("Gloamforge Bulwark", "Epic", "Shoulders raised, filigree prongs standing over the top, a square stone.",
           "rich", trim="filigree", shape=(RAISED,), rim="filigree", line="filigree", orn="Gloamforge",
           stone=("glow", 0.3), cut="square"),
    design("Nightloom Bulwark", "Epic", "An arched top, a long shuttle laid across the face past both sides.", "rich",
           trim="filigree", shape=(ARCHED,), rim="filigree", line="filigree", orn="Nightloom", stone=("glow", 0.3)),

    design("Hakuchuu, the High Noon", "Legendary", "Its one new form: a sun's rays fanned behind its top.", "gilt",
           trim="ivory", rim="ivory", stone=("lit", 0.32), behind="rays", edge=True),
    design("Kousai, the Clear Mirror", "Legendary", "Its one new form: a round mirror in its face, the ring past "
           "its sides.", "gilt", trim="ivory", rim="ivory", stone=("lit", 0.3), mirror=True, edge=True),
    design("Fuyuboshi, the Cold Star", "Legendary", "Its one new form: an eight-pointed star behind it, its points "
           "past the corners.", "gilt", trim="ivory", rim="ivory", shape=(SQUARE,), stone=("lit", 0.32),
           behind="star", edge=True),
)

FRONT = -THICK / 2      # the face's front, before it bows


def strip(z_top, z_low, outline, key, name="Band", thick=0.06):
    """A band across the face between two heights, its ends on the rim."""
    right = [(x, z) for x, z in outline if x >= 0]
    a, b = p.half_width(right, z_top) - 0.04, p.half_width(right, z_low) - 0.04
    return p.flat(name, [(-a, z_top), (a, z_top), (b, z_low), (-b, z_low)], thick, key, y=FRONT - thick / 2 + 0.01,
                  bevel=0.015)


def shield(d):
    key, trim, outline = d["key"], d["trim"], whole(*d["shape"])
    front = []                                      # everything on the face, bowed with it
    front.append(p.flat("Face", outline, THICK, d["face"], bevel=0.03))
    if d["rim"]:
        front.append(p.tube("Rim", [(x, 0.0, z) for x, z in outline + outline[:2]], 0.085, d["rim"], sides=8))
    if d["edge"]:
        front.append(p.tube("Edge", [(x, FRONT - 0.03, z) for x, z in inset(outline, 0.93) + inset(outline, 0.93)[:2]],
                            0.032, "lit"))
    if d["line"]:
        ring = inset(outline, 0.84)
        front.append(p.tube("Line", [(x, FRONT - 0.02, z) for x, z in ring + ring[:2]], 0.024, d["line"]))
    if d["planks"]:
        for x in (-0.62, 0.0, 0.62):
            zs = [k / 50 for k in range(-90, 110) if inside(outline, x, k / 50, 0.12)]
            front.append(p.tube("Seam", [(x, FRONT, max(zs)), (x, FRONT, min(zs))], 0.022, "liner", sides=6))
    for z in d["bands"]:
        front.append(strip(z + 0.11, z - 0.11, outline, d["rim"] or trim))
        if d["key"] == "scrap":
            right = [(x, z2) for x, z2 in outline if x >= 0]
            w = p.half_width(right, z) - 0.2
            for x in (-w, -w / 3, w / 3, w):
                front.append(p.ball("Bolt", 0.06, "iron", (x, FRONT - 0.05, z), squash=(1, 0.6, 1), segments=6, rings=4))
    if d["chevron"]:
        v = [(-1.1, 1.0), (0.0, -0.1), (1.1, 1.0), (1.12, 0.66), (0.0, -0.46), (-1.12, 0.66)]
        front.append(p.flat("Chevron", v, 0.06, trim, y=FRONT - 0.02, bevel=0.015))
    if d["rivets"]:
        ring = inset(outline, 0.88)
        step = max(1, len(ring) // d["rivets"])
        for x, z in ring[::step][:d["rivets"]]:
            front.append(p.ball("Rivet", 0.055, d["rim"] or key, (x, FRONT - 0.02, z), squash=(1, 0.6, 1), segments=8,
                                rings=4))
    if d["boss"]:
        r = d["boss"]
        front.append(p.ball("Boss", r, d["rim"] or key, (0, FRONT, 0.15), squash=(1, 0.55, 1), segments=20, rings=10))
        if d["rarity"] == "Uncommon":
            front.append(p.facing("Ring", r + 0.1, 0.035, trim, (0, FRONT - 0.02, 0.15)))

    orn, at = d["orn"], (0.0, FRONT - 0.04, 0.2)
    if orn in ("Embers", "Hoarfrost"):
        front.append(p.flat("Frame", p.set_ornament(orn, 1.3, (at[0], at[2])), 0.05, trim, y=FRONT - 0.03))
    elif orn == "Gales":
        vane = p.shifted(p.VANE, 0.15, 0.3, 1.25, 1.25)
        front.append(p.flat("Vane", vane, 0.05, trim, y=FRONT - 0.03))
    elif orn == "Stormcall":
        for side in (-1, 1):
            front.append(p.curl((side * 1.1, 1.46), side, 1.05, trim, y=0.0, turn=10.0, r=0.085))
    elif orn == "Gloamforge":
        front.append(p.flat("Crest", p.set_ornament(orn, 1.35, (0.0, 1.0)), 0.1, trim, y=0.0))
    elif orn == "Nightloom":
        front.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, 0.95, 3.5, 2.2), 0.1, trim, y=FRONT - 0.05))
        front.append(strip(0.62, 0.5, outline, trim, "Thread", 0.04))
        front.append(strip(-0.2, -0.32, outline, trim, "Thread", 0.04))
    if d["mirror"]:
        front.append(p.facing("Mirror ring", 1.66, 0.13, trim, (0, FRONT - 0.06, 0.3)))
        front.append(p.flat("Mirror", p.ellipse(1.56, 1.56, 48, 0.0, 0.3), 0.04, "steel", y=FRONT - 0.05, bevel=0.0))
    front += p.stone_of(d, 1.0, at)
    p.bowed(front, HALF, BOW)

    behind = []
    if d["behind"] == "rays":
        rays = [(x, z) for x, z in p.star(18, 2.3, 1.6, turn=90.0) if z > -1e-6]
        behind.append(p.flat("Rays", p.shifted(rays, 0.0, 0.4), 0.08, trim, y=0.16))
    elif d["behind"] == "star":
        behind.append(p.flat("Star", p.shifted(p.star(8, 2.2, 0.95, turn=22.5), 0.0, 0.05), 0.08, trim, y=0.16))
    return front + behind


def build(d):
    return p.scene_of(lambda: shield(d), TILT, SPIN)


WORDS = dict(
    file="gear_shield_sets.png",
    title="Grow your Anime: the Shield in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Tank's off hand: a heater shield, its face bowed toward the viewer and turned a little so the rim shows. "
         "A design is the top's line, the rim, the boss and bands, and what the face carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Bulwark. No band crosses another on a face.",
        "Each Legendary's one new form: Hakuchuu (broad noon), a sun's rays behind its top; Kousai (lustre), a round "
        "mirror whose ring stands past its sides; Fuyuboshi (a winter star), an eight-pointed star behind it.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a shield, and apart from its two neighbours, at 38 points? Does each "
        "Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
