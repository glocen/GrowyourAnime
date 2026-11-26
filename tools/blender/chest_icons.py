"""AR21: the four chests' pictures, in grey first (research's ask, 2026-11-16, 20:46).

Research's feel line: the player opens the bag and knows each chest by its shape before reading a word, the four rising
in worth from the Shade's to the Tower's, and none looking like a rarity.

Each chest is a different keepsake of the festival, sealed by the Void, so its silhouette alone names it:
  - the Shade's: a cloth bundle tied at the top, one of its knot's ears up and the other fallen over its shoulder;
    soft, small, no metal; one thread of light where the knot binds.
  - the Elite's: the treasure chest's own shape, a domed lid on a lacquer body, iron at its corners and in two straps
    over the dome, a wide seam of light under the lid, an iron drop ring at each end; never a padlock.
  - the Keeper's: three lacquer tiers stacked tall, brass at their corners, a seam of light under each, a cord bound
    over them and tied in a bow at the front with two tassels, and a ring crest on its lid.
  - the Tower's: a round drum, staved, banded at its foot and top like the Tower's platforms' rims, and from its lid a
    column of light with three rings on it, smaller as they rise: the Tower's own column of rings.
Worth rises in size, in height, in finish (cloth, then iron, brass and a pale steel), and in the light's lines (a thread,
a seam, three seams, a column). No rarity's colour or frame, no padlock, no flame and no cloud: a light is a line.

The three that hold one kind of thing (Definitions/Chests: ChestCase, ChestPouch, ChestCrate; Faber's ask, 2026-11-26),
each shaped by what it holds, in the same make:
  - the Emblem Case: a slim case lying low, brass at its corners, a seam of light under its lid, an arched brass
    handle on top, and for its clasp a six-sided plate over the seam, the War Emblem's own badge;
  - the Jewel Pouch: a leather pouch drawn shut at its neck, gathered in folds, a thong bound round it with two
    beaded ends; its light a ring inside its frilled mouth, where a cut stone shows;
  - the Forge Crate: a crate of planks with the forge's light in the gaps between them, dark posts at its corners, a
    brace across its front, rope handles at its ends, and forge stones heaped over its rim.

Built in code on gear_parts.py's shapes and rendered in Workbench, as AR6's gear is. The sheet shows each in the bag's
plain cell (AR18's A, the edge an empty cell has; TR29, "The chest's frame") seen close, at 38 points, and alone at
32 pixels over dark, then a row of the bag with AR6's gear among them.

Run: blender --background --factory-startup --python tools/blender/chest_icons.py -- build/handoff/UI/chests
"""
import json
import math
import sys
import textwrap
from pathlib import Path

import bmesh
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_icons as gi  # noqa: E402
import gear_parts as p  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
GEAR = ROOT / "build" / "handoff" / "UI" / "gear" / "images"
mat = p.mat
TILT, SPIN = 24.0, -32.0  # the lid seen from a little above, the front and the right side toward the camera
# Each chest's lacquer its own key. The Elite's and the Keeper's stand a value above the cell's dark ground, the same
# rule as AR6's Common iron (research's verdict on the grey, fix 2); the Tower's stays dark under its pale steel.
for key, value in (("wrap", 0.52), ("lacquer_red", 0.36), ("lacquer_black", 0.34), ("lacquer_slate", 0.22),
                   ("cord", 0.7), ("fringe", 0.86), ("lacquer_umber", 0.34), ("enamel", 0.16), ("leather", 0.44),
                   ("thong", 0.26), ("wood", 0.56), ("post", 0.32), ("rope", 0.68), ("rock", 0.42)):
    g.GREY.setdefault(key, value)
# In colour: a key's colour, how metal it is, how rough. No finish or light takes a rarity's colour (the content check):
# the Shade's plain hemp; the Elite's vermilion lacquer under black iron; the Keeper's black lacquer, held a value above
# the cell, under brass, with a vermilion silk cord whose ends are cream tassels, never a red end; the Tower's graphite
# lacquer under pale steel, neutral, since a slate turned navy under the finish's cool foot. A lit part is warm white
# and its light a small warm white, never the gear's gold.
PAINT = dict(
    wrap=("#A08E72", 0.0, 0.85), lacquer_red=("#943525", 0.0, 0.3), lacquer_black=("#574B45", 0.0, 0.28),
    lacquer_slate=("#48464A", 0.0, 0.3), iron=("#4E525C", 0.35, 0.45), brass=("#D49A4E", 0.35, 0.32),
    steel=("#D8DFE9", 0.3, 0.42), cord=("#B8432F", 0.0, 0.8), fringe=("#E6DAC2", 0.0, 0.85),
    stone=("#ECE6D8", 0.1, 0.15),
    # the three that hold one kind of thing: the Case's umber lacquer under brass, its badge's face a dark enamel, never
    # the emblems' violet; the Pouch's saddle leather and dark thong; the Crate's pale planks, dark posts, hemp rope and
    # warm grey stones
    lacquer_umber=("#6E4A33", 0.0, 0.28), enamel=("#2E2622", 0.0, 0.3), leather=("#94603A", 0.0, 0.62),
    thong=("#4B3222", 0.0, 0.7), wood=("#B48A56", 0.0, 0.75), post=("#5F4532", 0.0, 0.7), rope=("#CDB78C", 0.0, 0.85),
    rock=("#857C73", 0.0, 0.8))
LIT, LIGHT = "#FFF6DC", ("#FFF1D6", (4, 0.7), (10, 0.2))
# How much of its square each fills: the worth climbs in size too, the Shade's still whole at 32 pixels.
FILL = dict(Shade=0.68, Elite=0.78, Keeper=0.85, Tower=0.9, Case=0.8, Pouch=0.72, Crate=0.84)


def rounded(name, size, key, at, r=0.06, segments=2):
    return bl.bevel(bl.place(bl.box(name, size, mat(key)), at), r, segments=segments)


def standing(name, radius, minor, key, at, squash=(1.0, 1.0, 1.0), arc=360.0, turn=0.0):
    """A ring standing in the chest's front plane at `at`, squashed in its own plane first."""
    t = bl.torus(name, radius, minor, 32, 8, mat(key), arc=arc)
    bl.place(t, (0, 0, 0), (0, 0, turn), squash)
    return bl.smooth_by_angle(bl.place(t, at, (90, 0, 0)), 40.0)


# --- the four -----------------------------------------------------------------------------------------------------------

def shade():
    """A cloth bundle: a box wrapped soft, its top broad, the cloth knotted right on it, one ear up, one fallen."""
    h = 1.08

    def corners(a, z):  # a soft square: the wrapped box's four corners pushing the cloth out
        return 1.0 + 0.11 * math.cos(math.radians(4.0 * (a - 45.0)))

    # no neck: a narrow neck under a rim read as a teapot's
    parts = [p.lathe("Bundle", [(0.0, 0.0), (0.8, 0.0), (0.98, 0.12), (1.04, 0.42), (1.0, 0.72), (0.88, 0.92),
                                (0.6, 1.03), (0.0, h)], "wrap", thick=0.0, deep=0.8, wave=corners)]
    parts.append(p.ball("Knot", 0.3, "wrap", (0, -0.04, h + 0.1), squash=(1.3, 1.0, 0.75)))
    # the knot's ears, flat cloth tabs tied unevenly, so the knot reads as a knot and never as a head's two ears
    # (research's verdict on the grey, fix 3): one short and up, behind the knot; the other a broad flap falling off
    # the bundle's right shoulder, past its outline, to a soft square end
    parts.append(bl.place(p.tube("Ear", p.curve([(-0.08, 0.06, h + 0.2), (-0.2, 0.14, h + 0.46), (-0.26, 0.2, h + 0.6)],
                                                12), [0.22] * 4 + [0.2] * 4 + [0.15, 0.11, 0.08, 0.05], "wrap"),
                          (0, 0, 0), (0, 0, 0), (1, 0.4, 1)))
    parts.append(bl.place(p.tube("Fall", p.curve([(0.16, -0.06, h + 0.14), (0.5, -0.1, h + 0.1), (0.82, -0.12, h - 0.1),
                                                  (0.98, -0.12, h - 0.42)], 12), [0.21] * 4 + [0.23] * 4 + [0.21] * 4,
                                 "wrap"), (0, 0, 0), (0, 0, 0), (1, 0.4, 1)))
    for side in (-1, 1):
        # the cloth's creases, from the knot down toward the bundle's corners
        for back in (-1, 1):
            parts.append(p.tube("Crease", p.curve([(side * 0.24, back * 0.16, h), (side * 0.48, back * 0.32, h - 0.08),
                                                   (side * 0.7, back * 0.5, h - 0.3)], 10), 0.05, "wrap"))
    # the thread of light: a binding round the knot itself, across it, so it reads as a tie and never as a lid's rim
    band = bl.torus("Thread", 0.27, 0.035, 32, 8, mat("lit"))
    bl.place(band, (0, 0, 0), (0, 90, 0), (1, 1.2, 0.85))
    parts.append(bl.smooth_by_angle(bl.place(band, (0.02, -0.04, h + 0.1), (0, 0, -20)), 40.0))
    return parts


def vault(name, length, depth, rise, key, z0, x=0.0, steps=18):
    """A barrel vault along X: a half ellipse `depth` wide and `rise` high, `length` long, on z0, closed at its ends."""
    bm = bmesh.new()
    rings = []
    for side in (-1, 1):
        rings.append([bm.verts.new((x + side * length / 2, depth / 2 * math.cos(math.pi * i / steps),
                                    z0 + rise * math.sin(math.pi * i / steps))) for i in range(steps + 1)])
    a, b = rings
    for i in range(steps):
        bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
    bm.faces.new((a[0], b[0], b[-1], a[-1]))  # its floor
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.smooth_by_angle(bl.bevel(bl.object_from_bmesh(name, bm, mat(key)), 0.025, segments=2), 40.0)


def elite():
    """A chest with a domed lid, iron at its corners and over its dome, a wide seam of light, a drop ring at each end."""
    # the treasure chest's own shape, a step taller than the trunk it was (research's verdict on the grey, fix 1)
    w, d, h, gap, band, rise = 2.6, 1.6, 1.15, 0.16, 0.16, 0.5
    z0 = h + gap + band  # the dome's foot
    parts = [rounded("Body", (w, d, h), "lacquer_red", (0, 0, h / 2), 0.07),
             # the seam of light, wide, filling the gap under the lid and standing a little proud
             rounded("Seam", (w + 0.02, d + 0.02, gap), "lit", (0, 0, h + gap / 2), 0.02, 1),
             rounded("Rim", (w + 0.06, d + 0.06, band), "lacquer_red", (0, 0, h + gap + band / 2), 0.04),
             vault("Dome", w + 0.06, d + 0.06, rise, "lacquer_red", z0)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(rounded("Corner", (0.2, 0.2, h - 0.12), "iron", (sx * (w / 2 - 0.06), sy * (d / 2 - 0.06), h / 2),
                                 0.03, 1))
            parts.append(rounded("Cap", (0.22, 0.22, band + 0.02), "iron", (sx * w / 2, sy * d / 2, h + gap + band / 2),
                                 0.03, 1))
        # an iron strap over the dome, down its rim
        parts.append(vault("Strap", 0.16, d + 0.12, rise + 0.04, "iron", z0, x=sx * (w / 2 - 0.42)))
        parts.append(rounded("Strap", (0.16, d + 0.12, band + 0.02), "iron", (sx * (w / 2 - 0.42), 0, h + gap + band / 2),
                             0.02, 1))
    # an iron drop ring at each end, on a plate, to carry it by, and never a padlock. (A Shade's mask on it was tried
    # twice in grey and dropped: low on the front it read as a smiley, then a hasp; on its shoulder, a skull.)
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
        parts.append(rounded("Tier", (w, d, tier), "lacquer_black", (0, 0, z0 + tier / 2), 0.06))
        # each seam a little proud of the tiers, so no shadow swallows it
        parts.append(rounded("Seam", (w + 0.03, d + 0.03, gap), "lit", (0, 0, z0 + tier + gap / 2), 0.02, 1))
        for sx in (-1, 1):
            for sy in (-1, 1):  # one brass strip down each corner of each tier
                parts.append(rounded("Corner", (0.2, 0.2, tier - 0.14), "brass",
                                     (sx * (w / 2 - 0.05), sy * (d / 2 - 0.05), z0 + tier / 2), 0.03, 1))
    top = 3 * tier + 3 * gap
    parts.append(rounded("Lid", (w + 0.14, d + 0.14, 0.3), "lacquer_black", (0, 0, top + 0.15), 0.08))
    lid_top = top + 0.3
    # the cord: over the lid and down the front to a bow on the middle tier, two tassels hanging from its knot
    front, bow = -d / 2 - 0.05, tier + gap + tier / 2 + 0.08
    parts.append(p.tube("Cord", p.curve([(0, 0.3, lid_top + 0.02), (0, -d / 2 - 0.02, lid_top - 0.04),
                                         (0, front, top - 0.2), (0, front, bow + 0.1)], 12), 0.05, "cord"))
    for side in (-1, 1):
        parts.append(standing("Loop", 0.2, 0.055, "cord", (side * 0.25, front - 0.05, bow + 0.02), (1.4, 0.8, 1.0)))
        parts.append(p.tube("Tail", p.curve([(side * 0.05, front - 0.08, bow), (side * 0.12, front - 0.1, bow - 0.35),
                                             (side * 0.16, front - 0.1, bow - 0.62)], 8), 0.035, "cord"))
        parts.append(bl.smooth_by_angle(bl.place(bl.cylinder("Tassel", 0.11, 0.36, 12, mat("fringe"), radius_top=0.035),
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
    parts = [p.lathe("Drum", [(0.0, 0.0), (r + 0.06, 0.0), (r + 0.06, 0.12), (r, 0.16), (r, h), (0.0, h)], "lacquer_slate",
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
                                 (0.34, lid + 0.46), (0.0, lid + 0.48)], "lacquer_slate", thick=0.0))
    foot = lid + 0.46
    rings = ((0.62, 0.45), (0.46, 0.95), (0.32, 1.4))
    height = rings[-1][1] + 0.12
    parts.append(bl.place(bl.cylinder("Column", 0.045, height, 12, mat("lit")), (0, 0, foot + height / 2)))
    for radius, z in rings:
        parts.append(p.hoop("Ring", radius, 0.045, "steel", foot + z))
    return parts


# --- the three that hold one kind of thing ------------------------------------------------------------------------------

def case():
    """A slim case lying low, brass at its corners, a seam of light under its lid, an arched handle, a badge clasp."""
    w, d, h, gap, lid = 2.5, 1.5, 0.5, 0.1, 0.36
    top = h + gap + lid
    parts = [rounded("Body", (w, d, h), "lacquer_umber", (0, 0, h / 2), 0.06),
             rounded("Seam", (w + 0.02, d + 0.02, gap), "lit", (0, 0, h + gap / 2), 0.02, 1),
             rounded("Lid", (w + 0.06, d + 0.06, lid), "lacquer_umber", (0, 0, h + gap + lid / 2), 0.1)]
    for sx in (-1, 1):
        for sy in (-1, 1):  # a brass corner on the body and one on the lid, the seam left whole between them
            parts.append(rounded("Corner", (0.24, 0.24, h - 0.04), "brass", (sx * (w / 2 - 0.05), sy * (d / 2 - 0.05),
                                                                             h / 2), 0.03, 1))
            parts.append(rounded("Corner", (0.26, 0.26, lid - 0.02), "brass", (sx * (w / 2 - 0.04), sy * (d / 2 - 0.04),
                                                                              h + gap + lid / 2), 0.04, 1))
        # the handle's feet on the lid
        parts.append(rounded("Foot", (0.2, 0.26, 0.08), "brass", (sx * 0.5, 0, top + 0.03), 0.02, 1))
    # the handle: a brass arch across the lid, to carry it by
    parts.append(standing("Handle", 0.5, 0.065, "brass", (0, 0, top + 0.06), (1.0, 0.72, 1.0), arc=180.0))
    # the clasp: a six-sided plate over the seam at the front, the War Emblem's own badge, a dark face in a brass rim
    front = -d / 2 - 0.06
    face = bl.cylinder("Face", 0.27, 0.08, 6, mat("enamel"))
    parts.append(bl.place(face, (0, front, h + gap / 2), (90, 0, 0)))
    rim = bl.torus("Badge", 0.29, 0.055, 6, 8, mat("brass"))
    parts.append(bl.place(rim, (0, front - 0.03, h + gap / 2), (90, 0, 0)))
    parts.append(p.ball("Mark", 0.08, "stone", (0, front - 0.06, h + gap / 2), squash=(1.0, 0.5, 1.0), segments=6,
                        rings=4))
    return parts


def pouch():
    """A leather pouch drawn shut, gathered at its neck, a thong with beaded ends, a ring of light in its mouth."""
    neck = 1.22

    def gathers(a, z):  # folds round it, deepening toward the neck and out into the frill
        k = min(1.0, max(0.0, (z - 0.5) / 0.7))
        return 1.0 + (0.025 + 0.075 * k) * math.cos(math.radians(9.0 * a))

    parts = [p.lathe("Pouch", [(0.0, 0.0), (0.5, 0.02), (0.84, 0.18), (0.98, 0.46), (0.93, 0.76), (0.68, 1.02),
                               (0.36, neck - 0.04), (0.3, neck), (0.38, neck + 0.12), (0.54, neck + 0.28),
                               (0.6, neck + 0.36), (0.48, neck + 0.3), (0.0, neck + 0.2)], "leather", thick=0.0,
                     wave=gathers)]
    # the light: a ring just inside the frilled mouth, and a cut stone showing in it
    parts.append(p.hoop("Mouth", 0.47, 0.04, "lit", neck + 0.31))
    parts.append(p.ball("Jewel", 0.2, "stone", (0.04, 0.02, neck + 0.33), squash=(1.0, 1.0, 0.8), segments=6, rings=4))
    # the thong bound twice round the neck, its two ends down the front, a bead on each
    for z in (neck - 0.02, neck + 0.07):
        parts.append(p.hoop("Thong", 0.33, 0.05, "thong", z))
    ends = (((0.18, -0.28, neck), (0.34, -0.42, neck - 0.3), (0.38, -0.5, neck - 0.55)),
            ((0.05, -0.31, neck), (0.1, -0.5, neck - 0.36), (0.06, -0.58, neck - 0.7)))
    for points in ends:
        parts.append(p.tube("End", p.curve(points, 10), 0.04, "thong"))
        parts.append(p.ball("Bead", 0.08, "fringe", (points[-1][0], points[-1][1], points[-1][2] - 0.06)))
    return parts


def crate():
    """A crate of planks, the forge's light in the gaps, dark posts, a brace, rope handles, stones over its rim."""
    w, d, h, plank, gap = 2.4, 1.7, 1.24, 0.34, 0.09
    parts = [rounded("Glow", (w - 0.12, d - 0.12, h - 0.06), "lit", (0, 0, h / 2), 0.02, 1)]
    for i in range(3):  # three planks a side, the light showing in the two gaps between them
        parts.append(rounded("Plank", (w, d, plank), "wood", (0, 0, 0.04 + i * (plank + gap) + plank / 2), 0.03, 1))
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(rounded("Post", (0.2, 0.2, h + 0.06), "post", (sx * (w / 2 - 0.02), sy * (d / 2 - 0.02),
                                                                          (h + 0.06) / 2), 0.03, 1))
        # a rope handle at each end
        parts.append(p.tube("Rope", p.curve([(sx * (w / 2 + 0.02), -0.32, 0.86), (sx * (w / 2 + 0.2), 0.0, 0.66),
                                             (sx * (w / 2 + 0.02), 0.32, 0.86)], 12), 0.055, "rope"))
    # one brace across the front, low left to high right, over the gaps
    span = math.hypot(w - 0.3, h - 0.2)
    parts.append(rounded("Brace", (span, 0.08, 0.2), "post", (0, 0, 0), 0.02, 1))
    bl.place(parts[-1], (0, -d / 2 - 0.04, h / 2), (0, -math.degrees(math.atan2(h - 0.2, w - 0.3)), 0))
    # the forge stones heaped over the rim, rough, the biggest at the back
    for at, r, squash in (((0.35, 0.25, h + 0.14), 0.5, (1.1, 0.95, 0.72)), ((-0.6, 0.1, h + 0.1), 0.42, (1.15, 0.9, 0.7)),
                          ((0.8, -0.38, h + 0.06), 0.3, (1.0, 0.9, 0.8)), ((-0.12, -0.42, h + 0.06), 0.33, (1.2, 0.9, 0.7))):
        parts.append(p.ball("Stone", r, "rock", at, squash=squash, segments=7, rings=5))
    return parts


CHESTS = (
    ("Shade", "the Shade Chest", shade, "A cloth bundle tied at the top, one ear of its knot up and one fallen. Soft "
     "and small, no metal; one thread of light where the knot binds."),
    ("Elite", "the Elite Chest", elite, "A domed chest, iron at its corners and in two straps over its dome, a wide "
     "seam of light under the lid, an iron drop ring at each end."),
    ("Keeper", "the Keeper's Chest", keeper, "Three lacquer tiers stacked tall, brass at their corners and a seam of "
     "light under each, bound with a cord in a bow and two tassels; a ring crest on its lid."),
    ("Tower", "the Tower Chest", tower, "A staved drum, banded like the Tower's platforms. From its lid rises a column "
     "of light with three rings on it, smaller as they rise: the Tower's column."),
    ("Case", "the Emblem Case", case, "A slim case lying low, brass at its corners, a seam of light under its lid, an "
     "arched handle; its clasp the War Emblem's six-sided badge."),
    ("Pouch", "the Jewel Pouch", pouch, "A leather pouch drawn shut and gathered at its neck, a thong with two beaded "
     "ends; a ring of light in its mouth, where a cut stone shows."),
    ("Crate", "the Forge Crate", crate, "A crate of planks, the forge's light in the gaps between them, dark posts, a "
     "brace and rope handles, forge stones heaped over its rim."),
)


def paint(key):
    return (LIT, 0.0, 0.3) if key == "lit" else PAINT[key]


def coloured(scene, out, centre, span):
    """As AR6's gear is shot in colour (gear_icons.py): lit, then flat as a mask of what's lit, then finished, its
    light the chests' own."""
    import bpy
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera, cam.data.type, cam.data.ortho_scale, cam.data.clip_end = cam, "ORTHO", span, 200
    cam.location, cam.rotation_euler = (centre[0], -40, centre[1]), (math.radians(90), 0, 0)
    rs.workbench(scene, g.SIZE, g.SIZE)
    shading = scene.display.shading
    shading.show_specular_highlight = True
    shading.cavity_ridge_factor, shading.cavity_valley_factor = 1.8, 1.3
    shading.curvature_ridge_factor, shading.curvature_valley_factor = 1.5, 1.2
    lit = gi.render(scene, out)
    for m in bpy.data.materials:
        m.diffuse_color = (1, 0, 0, 1) if m.name[5:] == "lit" else (0, 0, 0, 1)
    rs.workbench(scene, g.SIZE, g.SIZE, flat=True)
    mask = gi.render(scene, out)
    return gi.finish(lit, mask[..., 0] * mask[..., 3], np.zeros(mask.shape[:2], np.float32), LIT, LIGHT)


def renders(out, colour=False):
    shots = {}
    g.PAINT = paint if colour else None
    for key, _, build, _ in CHESTS:
        scene, parts = p.scene_of(build, TILT, SPIN)
        x0, x1, z0, z1 = g.bounds(parts)
        size = max(x1 - x0, z1 - z0)
        shoot = coloured if colour else g.shoot
        shots[key] = shoot(scene, out, ((x0 + x1) / 2, (z0 + z1) / 2), size / FILL[key])
        print(f"{key}: {x1 - x0:.2f} wide, {z1 - z0:.2f} tall")
    return shots


# --- the sheet ----------------------------------------------------------------------------------------------------------

# AR18's A, the bag the director picked: a lacquer well; a chest's cell has the plain edge an empty cell has.
WELL, UMBER, BRASS_DIM = ("#110E0B", "#070605"), ("#2E1E0E", "#140C05"), "#5E4C34"
RIM = dict(Common="#8A909C", Uncommon="#7CF0A0", Rare="#6FB6FF", Epic="#D29CFF", Legendary="#FFD777")
# AR6's gear beside them in the bag's row, by rarity
BESIDE = (("GearMeigetsu", "Legendary"), ("Tower", None), ("GearStormcallSceptre", "Epic"), ("Keeper", None),
          ("GearBulwarkOfEmbers", "Rare"), ("Elite", None), ("GearLanternsteelShield", "Uncommon"), ("Shade", None),
          ("GearIronGreataxe", "Common"), ("Case", None), ("GearRowsmithBlades", "Uncommon"), ("Pouch", None),
          ("Crate", None))


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


def sheet(out, shots, colour=False):
    ui.K = K = 2
    sh = ui.Sheet(60 + len(CHESTS) * 292, 560, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: the chests, " + ("in colour (AR21, the finish)" if colour else
                                                          "in grey (AR21, the block)"), g.INK)
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
    notes = (("Colour: the Shade's plain hemp; the Elite's vermilion lacquer under black iron; the Keeper's black "
              "lacquer under brass, its cord vermilion silk, its tassels cream; the Tower's graphite under pale steel. A light is warm white, "
              "small." if colour else "Grey: the Elite's and the Keeper's lacquer a value above the cell, the Tower's "
              "dark under its pale steel; cloth mid; a lit part white. The colour pass follows research's verdict."),
             "Not here: one picture per ground, the opening's moment, a chest in the world, the stack's count (the bag's).")
    for i, line in enumerate(notes):
        t.text(20, sh.h - 34 + i * 14, 9, line, g.SOFT_INK)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    name = "chests_colour.png" if colour else "chests_grey.png"
    rs.save(sh.px, out / name)


IMAGES = dict(Shade="Shade Chest", Elite="Elite Chest", Keeper="Keeper's Chest", Tower="Tower Chest",
              Case="Emblem Case", Pouch="Jewel Pouch", Crate="Forge Crate")


def deliver(out, shots, redo=False):
    """The pictures at 256 pixels, as AR6's gear, and their json: by the chest's kind in Definitions/Chests.luau. A
    picture already delivered (and uploaded) is kept as it is unless `redo`."""
    (out / "images").mkdir(exist_ok=True)
    for key, shot in shots.items():
        path = out / "images" / f"Chest{key}.png"
        if redo or not path.exists():
            gi.keep(rs.shrink(shot, gi.ICON / shot.shape[0]), path)
            print("wrote", path)
    data = dict(note="The chests' pictures for the bag's cell and its card (AR21). A chest's cell keeps the plain "
                     "edge an empty cell has, with no rarity's bar, rim or light (TR29). Each picture is laid as a gear "
                     "picture is: its square 0.94 of the cell, centred; the object sits in it with its own margin.",
                pixels=[gi.ICON, gi.ICON], chests={name: f"images/Chest{key}.png" for key, name in IMAGES.items()})
    (out / "chest_icons.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("wrote", out / "chest_icons.json")


def main():
    out = bl.out_dir()
    colour = "colour" in sys.argv[sys.argv.index("--") + 1:]
    shots = renders(out, colour)
    sheet(out, shots, colour)
    if colour:
        deliver(out, shots, "redo" in sys.argv[sys.argv.index("--") + 1:])


if __name__ == "__main__":
    main()
