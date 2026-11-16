"""AR21: the four chests' pictures, in grey first (research's ask, 2026-11-16, 20:46).

Research's feel line: the player opens the bag and knows each chest by its shape before reading a word, the four rising
in worth from the Shade's to the Tower's, and none looking like a rarity.

Each chest is a different keepsake of the festival, sealed by the Void, so its silhouette alone names it:
  - the Shade's: a cloth bundle tied at the top, its knot's two ears up; soft, small, no metal; one thread of light
    where the knot binds.
  - the Elite's: a lacquer trunk, wider than tall, iron at its corners, a seam of light under its lid, an iron drop
    ring at each end to carry it by.
  - the Keeper's: three lacquer tiers stacked tall, brass at their corners, a seam of light under each, a cord bound
    over them and tied in a bow at the front with two tassels, and a ring crest on its lid.
  - the Tower's: a round drum, staved, banded at its foot and top like the Tower's platforms' rims, and from its lid a
    column of light with three rings on it, smaller as they rise: the Tower's own column of rings.
Worth rises in size, in height, in finish (cloth, then iron, brass and a pale steel), and in the light's lines (a thread,
a seam, three seams, a column). No rarity's colour or frame, no padlock, no flame and no cloud: a light is a line.

Built in code on gear_parts.py's shapes and rendered in Workbench, as AR6's gear is. The sheet shows each in the bag's
plain cell (AR18's A, the edge an empty cell has; TR29, "The chest's frame") seen close, at 38 points, and alone at
32 pixels over dark, then a row of the bag with AR6's gear among them.

Run: blender --background --factory-startup --python tools/blender/chest_icons.py -- build/handoff/UI/chests
"""
import math
import sys
import textwrap
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
GEAR = ROOT / "build" / "handoff" / "UI" / "gear" / "images"
mat = p.mat
TILT, SPIN = 24.0, -32.0  # the lid seen from a little above, the front and the right side toward the camera
for key, value in (("wrap", 0.52), ("lacquer", 0.2), ("cord", 0.7)):
    g.GREY.setdefault(key, value)
# How much of its square each fills: the worth climbs in size too, the Shade's still whole at 32 pixels.
FILL = dict(Shade=0.68, Elite=0.78, Keeper=0.85, Tower=0.9)


def rounded(name, size, key, at, r=0.06, segments=2):
    return bl.bevel(bl.place(bl.box(name, size, mat(key)), at), r, segments=segments)


def standing(name, radius, minor, key, at, squash=(1.0, 1.0, 1.0), arc=360.0, turn=0.0):
    """A ring standing in the chest's front plane at `at`, squashed in its own plane first."""
    t = bl.torus(name, radius, minor, 32, 8, mat(key), arc=arc)
    bl.place(t, (0, 0, 0), (0, 0, turn), squash)
    return bl.smooth_by_angle(bl.place(t, at, (90, 0, 0)), 40.0)


# --- the four -----------------------------------------------------------------------------------------------------------

def shade():
    """A cloth bundle: a box wrapped soft, the cloth gathered in folds to a knot on top, its two ears up."""
    h = 1.15

    def corners(a, z):  # a soft square: the wrapped box's four corners pushing the cloth out
        return 1.0 + 0.11 * math.cos(math.radians(4.0 * (a - 45.0)))

    parts = [p.lathe("Bundle", [(0.0, 0.0), (0.8, 0.0), (0.98, 0.12), (1.04, 0.4), (0.98, 0.72), (0.8, 0.95),
                                (0.52, 1.1), (0.3, h + 0.02), (0.0, h + 0.04)], "wrap", thick=0.0, deep=0.8,
                     wave=corners)]
    parts.append(p.lathe("Gather", [(0.0, h - 0.02), (0.46, h - 0.02), (0.3, h + 0.2), (0.0, h + 0.24)], "wrap",
                         thick=0.0, steps=16))
    parts.append(p.ball("Knot", 0.26, "wrap", (0, 0, h + 0.3), squash=(1.25, 0.9, 0.85)))
    for side in (-1, 1):
        # the knot's ears: flat cloth tabs rising up and out of the knot, broad at the root, narrowing to a soft tip
        ear = p.tube("Ear", p.curve([(side * 0.1, 0, h + 0.34), (side * 0.36, 0, h + 0.66), (side * 0.56, 0, h + 0.9),
                                     (side * 0.66, 0, h + 0.98)], 12), [0.2] * 3 + [0.21] * 3 + [0.17] * 3 + [0.1, 0.07, 0.04],
                     "wrap")
        parts.append(bl.place(ear, (0, 0, 0), (0, 0, 0), (1, 0.32, 1)))
        # the cloth's creases, from the knot down toward the bundle's corners
        for back in (-1, 1):
            parts.append(p.tube("Crease", p.curve([(side * 0.18, back * 0.12, h + 0.1), (side * 0.42, back * 0.3, h - 0.02),
                                                   (side * 0.66, back * 0.48, h - 0.26)], 10), 0.05, "wrap"))
    # the thread of light round the gather's neck, standing clear of the knot
    parts.append(p.hoop("Thread", 0.41, 0.04, "lit", h + 0.15, deep=0.92))
    return parts


def elite():
    """A lacquer trunk wider than tall, iron at its corners, a seam of light under its lid, a drop ring at each end."""
    w, d, h, lid, gap = 2.7, 1.7, 1.1, 0.42, 0.11
    top = h + gap + lid
    parts = [rounded("Body", (w, d, h), "lacquer", (0, 0, h / 2), 0.07),
             # the seam of light fills the gap under the lid and stands a little proud, so no shadow swallows it
             rounded("Seam", (w + 0.02, d + 0.02, gap), "lit", (0, 0, h + gap / 2), 0.02, 1),
             rounded("Lid", (w + 0.06, d + 0.06, lid), "lacquer", (0, 0, h + gap + lid / 2), 0.08),
             rounded("Panel", (w - 0.5, d - 0.5, 0.08), "lacquer", (0, 0, top + 0.03), 0.03)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(rounded("Corner", (0.2, 0.2, h - 0.12), "iron", (sx * (w / 2 - 0.06), sy * (d / 2 - 0.06), h / 2),
                                 0.03, 1))
            parts.append(rounded("Cap", (0.24, 0.24, lid - 0.04), "iron", (sx * w / 2, sy * d / 2, h + gap + lid / 2),
                                 0.03, 1))
    # an iron drop ring at each end, on a plate, to carry it by: a trunk carried, never a padlock. (A Shade's mask on it
    # was tried twice in grey and dropped: low on the front it read as a smiley, then a hasp; on its shoulder, a skull.)
    for sx in (-1, 1):
        parts.append(rounded("Plate", (0.06, 0.42, 0.3), "iron", (sx * (w / 2 + 0.02), 0, h * 0.68), 0.02, 1))
        ring = bl.torus("Handle", 0.2, 0.04, 32, 8, mat("iron"))
        bl.place(ring, (0, 0, 0), (0, 90, 0), (1, 1.25, 1))
        parts.append(bl.smooth_by_angle(bl.place(ring, (sx * (w / 2 + 0.09), 0, h * 0.68 - 0.18), (0, sx * 18.0, 0)),
                                        40.0))
    return parts


def keeper():
    """Three lacquer tiers stacked tall, brass at their corners, seams of light, a cord with a bow and tassels, a crest."""
    w, d, tier, gap = 2.2, 1.75, 0.66, 0.09
    parts = []
    for i in range(3):
        z0 = i * (tier + gap)
        parts.append(rounded("Tier", (w, d, tier), "lacquer", (0, 0, z0 + tier / 2), 0.06))
        # each seam a little proud of the tiers, so no shadow swallows it
        parts.append(rounded("Seam", (w + 0.03, d + 0.03, gap), "lit", (0, 0, z0 + tier + gap / 2), 0.02, 1))
        for sx in (-1, 1):
            for sy in (-1, 1):  # one brass strip down each corner of each tier
                parts.append(rounded("Corner", (0.2, 0.2, tier - 0.14), "brass",
                                     (sx * (w / 2 - 0.05), sy * (d / 2 - 0.05), z0 + tier / 2), 0.03, 1))
    top = 3 * tier + 3 * gap
    parts.append(rounded("Lid", (w + 0.14, d + 0.14, 0.3), "lacquer", (0, 0, top + 0.15), 0.08))
    lid_top = top + 0.3
    # the cord: over the lid and down the front to a bow on the middle tier, two tassels hanging from its knot
    front, bow = -d / 2 - 0.05, tier + gap + tier / 2 + 0.08
    parts.append(p.tube("Cord", p.curve([(0, 0.3, lid_top + 0.02), (0, -d / 2 - 0.02, lid_top - 0.04),
                                         (0, front, top - 0.2), (0, front, bow + 0.1)], 12), 0.05, "cord"))
    for side in (-1, 1):
        parts.append(standing("Loop", 0.2, 0.055, "cord", (side * 0.25, front - 0.05, bow + 0.02), (1.4, 0.8, 1.0)))
        parts.append(p.tube("Tail", p.curve([(side * 0.05, front - 0.08, bow), (side * 0.12, front - 0.1, bow - 0.35),
                                             (side * 0.16, front - 0.1, bow - 0.62)], 8), 0.035, "cord"))
        parts.append(bl.smooth_by_angle(bl.place(bl.cylinder("Tassel", 0.11, 0.36, 12, mat("cord"), radius_top=0.035),
                                                 (side * 0.16, front - 0.1, bow - 0.8)), 40.0))
    parts.append(p.ball("Knot", 0.12, "cord", (0, front - 0.08, bow), squash=(1.2, 0.8, 1.0)))
    # the crest: a brass ring standing on a short post, a stone in it
    parts.append(bl.place(bl.cylinder("Post", 0.07, 0.16, 12, mat("brass")), (0, 0, lid_top + 0.08)))
    parts.append(standing("Crest", 0.3, 0.05, "brass", (0, 0, lid_top + 0.48)))
    parts.append(p.ball("Stone", 0.13, "stone", (0, -0.02, lid_top + 0.48), segments=6, rings=4))
    return parts


def tower():
    """A round drum banded like the Tower's platforms, and from its lid a column of light with three rings on it."""
    r, h = 1.15, 1.25
    parts = [p.lathe("Drum", [(0.0, 0.0), (r + 0.06, 0.0), (r + 0.06, 0.12), (r, 0.16), (r, h), (0.0, h)], "lacquer",
                     thick=0.0),
             # the seam of light in the gap under the lid, a little proud of it
             p.hoop("Seam", r + 0.05, 0.05, "lit", h + 0.06, high=1.2)]
    # two bands, a platform's rim at the foot and the top, and staves between them, so it reads as a drum, not a stack
    for z in (0.26, h - 0.08):
        parts.append(p.hoop("Band", r + 0.02, 0.055, "steel", z))
    for k in range(10):
        a = math.radians(k * 36.0 + 18.0)
        parts.append(rounded("Stave", (0.09, 0.06, h - 0.46), "steel", (0, 0, 0), 0.02, 1))
        bl.place(parts[-1], (r * math.sin(a), -r * math.cos(a), 0.26 + (h - 0.34) / 2), (0, 0, k * 36.0 + 18.0))
    lid = h + 0.12
    parts.append(p.lathe("Lid", [(0.0, lid), (r + 0.04, lid), (r + 0.04, lid + 0.1), (r * 0.72, lid + 0.34),
                                 (0.34, lid + 0.46), (0.0, lid + 0.48)], "lacquer", thick=0.0))
    foot = lid + 0.46
    rings = ((0.62, 0.45), (0.46, 0.95), (0.32, 1.4))
    height = rings[-1][1] + 0.12
    parts.append(bl.place(bl.cylinder("Column", 0.045, height, 12, mat("lit")), (0, 0, foot + height / 2)))
    for radius, z in rings:
        parts.append(p.hoop("Ring", radius, 0.045, "steel", foot + z))
    return parts


CHESTS = (
    ("Shade", "the Shade Chest", shade, "A cloth bundle tied at the top, its knot's two ears up. Soft and small, no "
     "metal; one thread of light where the knot binds."),
    ("Elite", "the Elite Chest", elite, "A lacquer trunk wider than tall, iron at its corners, a seam of light under "
     "its lid, an iron drop ring at each end to carry it by."),
    ("Keeper", "the Keeper's Chest", keeper, "Three lacquer tiers stacked tall, brass at their corners and a seam of "
     "light under each, bound with a cord in a bow and two tassels; a ring crest on its lid."),
    ("Tower", "the Tower Chest", tower, "A staved drum, banded like the Tower's platforms. From its lid rises a column "
     "of light with three rings on it, smaller as they rise: the Tower's column."),
)


def renders(out):
    shots = {}
    for key, _, build, _ in CHESTS:
        scene, parts = p.scene_of(build, TILT, SPIN)
        x0, x1, z0, z1 = g.bounds(parts)
        size = max(x1 - x0, z1 - z0)
        shots[key] = g.shoot(scene, out, ((x0 + x1) / 2, (z0 + z1) / 2), size / FILL[key])
        print(f"{key}: {x1 - x0:.2f} wide, {z1 - z0:.2f} tall")
    return shots


# --- the sheet ----------------------------------------------------------------------------------------------------------

# AR18's A, the bag the director picked: a lacquer well; a chest's cell has the plain edge an empty cell has.
WELL, UMBER, BRASS_DIM = ("#110E0B", "#070605"), ("#2E1E0E", "#140C05"), "#5E4C34"
RIM = dict(Common="#8A909C", Uncommon="#7CF0A0", Rare="#6FB6FF", Epic="#D29CFF", Legendary="#FFD777")
# AR6's gear beside them in the bag's row, by rarity
BESIDE = (("GearMeigetsu", "Legendary"), ("Tower", None), ("GearStormcallSceptre", "Epic"), ("Keeper", None),
          ("GearBulwarkOfEmbers", "Rare"), ("Elite", None), ("GearLanternsteelShield", "Uncommon"), ("Shade", None),
          ("GearIronGreataxe", "Common"), ("Shade", None), ("GearRowsmithBlades", "Uncommon"), ("Elite", None))


def cell(sh, x, y, s, picture, rarity=None):
    """A bag cell in A's look: gear with its rarity's bar along the foot, a fine rim and its light; a chest with the
    plain edge only."""
    z = s / 38.0
    t = sh.tile(x, y, s, s)
    box = t.poly(ui.cut_box(0, 0, s, s, 2.0 * z, 2.0 * z, 2.0 * z, 2.0 * z))
    t.paint(box, t.ramp(*(UMBER if rarity == "Legendary" else WELL), t.y / s))
    if rarity:
        t.glow(np.hypot((t.x - s / 2) * 0.75, t.y - s) - s * 0.1, s * 0.32, c(RIM[rarity]), 0.34)
        t.line(box, 1.0 * z, c(RIM[rarity]), 0.55)
        t.paint(np.maximum(box, -(t.y - (s - 3.0 * z))), c(RIM[rarity]), 0.95)
    else:
        t.line(box, 1.0 * z, c(BRASS_DIM), 0.7)
    inner = s - 3.0 * z
    rs.paste(sh.px, rs.shrink(picture, inner * ui.K / picture.shape[0]), round((x + 1.5 * z) * ui.K),
             round((y + 1.0 * z) * ui.K))


def sheet(out, shots):
    ui.K = K = 2
    sh = ui.Sheet(1200, 560, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: the four chests, in grey (AR21, the block)", g.INK)
    t.text(20, 36, 9.5, "Each kind is a different thing, so its shape names it before a word is read; the four rise in "
           "worth by size, height, finish and the light's lines, never by a rarity's colour or frame. A light is a line.",
           g.SOFT_INK)
    t.text(20, 50, 9.5, "Each in the bag's plain cell (AR18's A: a chest takes the edge an empty cell has, TR29), seen "
           "close; beside it at 38 points; under that, alone at 32 pixels over dark.", g.SOFT_INK)
    top, pitch = 80.0, 292.0
    for i, (key, title, _, words) in enumerate(CHESTS):
        x = 30 + i * pitch
        cell(sh, x, top, 160.0, shots[key])
        cell(sh, x + 172, top, 38.0, shots[key])
        tile = sh.tile(x + 172, top + 50, 24, 24)
        tile.paint(tile.poly(ui.cut_box(0, 0, 24, 24)), c(g.DARK))
        rs.paste(sh.px, rs.shrink(shots[key], 32 / shots[key].shape[1]), round((x + 176) * K), round((top + 54) * K))
        t.text(x, top + 170, 11, title[0].upper() + title[1:], g.INK)
        for j, line in enumerate(textwrap.wrap(words, 54)):
            t.text(x, top + 188 + j * 13, 8.5, line, g.SOFT_INK)
    y = top + 262
    t.text(20, y, 11, "In the bag at 38 points, among AR6's gear (the All tab)", g.INK)
    for i, (name, rarity) in enumerate(BESIDE):
        picture = rs.load(GEAR / f"{name}.png") if rarity else shots[name]
        cell(sh, 30 + i * 44, y + 20, 38.0, picture, rarity)
    t.text(20, y + 72, 11, "The same row, twice the size", g.INK)
    for i, (name, rarity) in enumerate(BESIDE):
        picture = rs.load(GEAR / f"{name}.png") if rarity else shots[name]
        cell(sh, 30 + i * 88, y + 92, 76.0, picture, rarity)
    notes = ("Grey: lacquer dark, cloth mid, iron, brass and steel by value, a lit part white. The colour pass comes after "
             "research's verdict on these shapes.",
             "Not here: one picture per ground, the opening's moment, a chest in the world, the stack's count (the bag's).")
    for i, line in enumerate(notes):
        t.text(20, sh.h - 34 + i * 14, 9, line, g.SOFT_INK)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, out / "chests_grey.png")
    print("wrote", out / "chests_grey.png")


def main():
    out = bl.out_dir()
    sheet(out, renders(out))


if __name__ == "__main__":
    main()
