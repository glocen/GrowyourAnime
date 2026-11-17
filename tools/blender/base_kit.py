"""AR14: the base's own kit (docs/asset-requests.md). The base is a power plant (docs/design.md, "The base"), so its
pieces are a power yard's and none of Lantern Row's: a deck of steel plates with the current running through it in
lit conduits, a panel wall with a line of light along its top, a gate on the Strip that carries the base's level,
lattice pylons with their lines, flood masts and transformers.

Made as Lantern Row's kit is (lantern_row_kit.py: its mesh builder, its swatch atlas, its ink hull, its manifest), on
pictures of its own, so the builder's Kit.Place and its upload take it unchanged. A piece's front faces +Y, toward the
Strip; its origin is on the floor; one unit is one stud.

The court's floor is one piece a level, with its own pair of pictures: the plates, the bays' frames, the lanes, and
the conduits from each bay to the battery, on to the Breaker and along its rail, glowing in the picture so they cost
no Light. It is drawn for half the court and laid mirrored about the plot's middle line.

Run (no GPU turn), each `blender.exe -b --factory-startup --python tools/blender/base_kit.py -- <out> <mode>`:
  pictures   the maps alone, into <out>
  export     <out> is the handoff folder: meshes, maps and manifest.json
"""

import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_ink as ink  # noqa: E402
import base_machines as machines  # noqa: E402
import base_mill as mill  # noqa: E402
import base_show as show  # noqa: E402
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import rook_sheet as rs  # noqa: E402

Mesh, Piece, code, grey = ink.Mesh, kit.Piece, kit.code, kit.grey   # the kit's mesh, with the base's thinner hull
A, CELL = kit.A, kit.CELL

# --- the plot, as the builder lays it (WorldService.plot, Config.World): copies, read again when the layout moves ------
# Studs. `in` is from the plot's front edge, the one on the Strip, into the plot.

PLOT, STRIP = 200.0, 48.0
# The spread (AR16; the director, 2026-11-15: "just make it less clustered make it accross the base"). Each place is
# across and in. The placement is a star round the generator (the director, the same night, of one straight row:
# "i dont like the placement of the building it a bit to simplish"). The generator stands at the plot's heart, 72 in,
# at the end of the way in, inside a ring of current open toward the gate. The ring's two ends run out on the slant
# to the Breaker and the Door, nearer the gate; the bus runs out each side to level 1's bays; two more slants run
# back to the battery and the Training machine; the main line goes on to the back wall, dormant. Every neighbour is
# 48 studs from the next. Modulo's proposal, until the builder's Config.World takes it.
AVENUE = 20.0                      # the way in, clear from the gate to the generator
SPAWN = (0.0, 10.0)                # facing into the plot, the generator ahead
ROW = 72.0                         # the heart's line: the generator's, and the bus's out to the bays
GENERATOR = (0.0, ROW)
RING = 18.0                        # the ring of current round the well, open toward the gate: its radius
ARM = 26.0                         # a slant's reach from the heart, the same across and in
BREAKER, DOOR = (ARM, ROW - ARM), (-ARM, ROW - ARM)
BATTERY, TRAINING = (ARM, ROW + ARM), (-ARM, ROW + ARM)
OUTER = 50.0                       # the bus's ends: level 1's bays
FAR, BACK = 82.0, 108.0            # the later bays: the bus's line on outward, then back along the side wall
BAYS = ([(side * OUTER, ROW) for side in (-1, 1)] + [(side * FAR, ROW) for side in (-1, 1)]
        + [(side * FAR, BACK) for side in (-1, 1)])   # in the order they open: level 1's, level 2's, level 3's
# What the base will wake, asleep in the back half (research, 2026-11-16): the Lab on the main line, the Forge and
# the Condenser on a spoke each from the main line's node, the Condenser on the bays' feeding side
NODE = ROW + 40.0
LAB, CONDENSER, FORGE = (0.0, 136.0), (36.0, 132.0), (-36.0, 132.0)
SLEEPS = 6.2                       # a sleeping place's ground: its frame's half side
BAYS_AT = {1: 2, 2: 4, 3: 6}       # bays by the base's level (docs/design.md, research's seeds)
WELL = 9.0                         # the generator's ground: a well of void under the plant's heart, its radius
PAD = (9.5, 5.2)                   # a machine's ground: half across, half deep

# --- the yard ------------------------------------------------------------------------------------------------------------

COURT = (44.0, 48.0)   # the lit court at the front: half across, and how far in from the front edge
HALF = PLOT / 2        # the wall, across: the base is the whole plot (the director, 2026-11-15: "the base must be that 200x200")
YARD = PLOT            # how far in the wall runs (the director, the same day: "much much longer")
BLOCK = 48.0           # a floor block behind the court, one picture laid again toward the back wall
PYLON = (HALF - 7.0, 4.0)   # the pylons' line inside the side walls, and the first one's place in from the front
LANE = 12.5            # a lane's middle, between the Breaker's line and the bays
GATE = 22.0            # a gate tower's place, across
WING = 28.0            # where a front wall ends and the gate's shoulder begins
SPAN = 48.0            # from pylon to pylon
ARMS = ((16.5, 5.2), (20.0, 3.8))   # a pylon's arms: how high, and how far each reaches
HANG = 1.9             # an insulator's drop under its arm
FLOOD = (ROW - 19.0, 3.0, 12.0)   # a flood mast, one each side of the way in before the ring: in from the front; its head's reach toward the front, and its height.
# 7 studs behind the Door's and the Breaker's line (46 in), so from the way in and on the way to either machine from the gate
# neither mast crosses it; its middle 3.8 studs off the slant conduit's line (research, 2026-11-17, AR15's finish: it stood at 50,
# across the Door's left edge from the way in; at 39 it crossed it on the way from the spawn)
COURT_GLOW = 1.0       # the court's glow picture's white, as emission strength (EmissiveStrength)
MAPS = {"Kit": ("#FFFFFF", kit.GLOW), "Court1": ("#FFFFFF", COURT_GLOW), "Yard": ("#FFFFFF", COURT_GLOW),
        "YardLive": ("#FFFFFF", COURT_GLOW), "YardBack": ("#FFFFFF", COURT_GLOW), "WingsLive": ("#FFFFFF", COURT_GLOW),
        "WingsBack": ("#FFFFFF", COURT_GLOW),
        "Wings": ("#FFFFFF", COURT_GLOW)}   # each pair's tint and strength

# Swatches: the colour at the head, at the foot, and how much it glows. Light steel, pale concrete and bone, the
# current in Power's yellow (the HUD's own), the Breaker's light in cyan. The steel, the girders and the concrete left
# the grey-violet for AR20's C (research's pick, 2026-11-16, 17:23, on the director's "need to be less somber"), so the
# void's violet is the only violet in the yard.
SWATCHES = {
    "steel": ("#8290B0", "#46506E", 0.0), "girder": ("#4C5878", "#242C42", 0.0), "bone": ("#E9E2D2", "#9C95A6", 0.0),
    "concrete": ("#C8CAD2", "#82858F", 0.0), "yellow": ("#FFD23E", "#B07A28", 0.05), "rubber": ("#1F2233", "#0E101A", 0.0),
    "ceramic": ("#F4F0E8", "#A8A2B6", 0.0), "copper": ("#DE8E54", "#7C4630", 0.0), "power": ("#FFF6C4", "#FFD94A", 1.0),
    "cyan": ("#8CF6FF", "#3CC8E8", 1.0), "lamp": ("#F6FCFF", "#CDEEFF", 1.0), "beacon": ("#FF9A7A", "#FF6A52", 1.0),
    "dark": ("#1E1426", "#0C0A12", 0.0), "ink": ("#0C0A16", "#0C0A16", 0.0),
    "void": ("#E9DBFF", "#A97CFF", 1.0), "abyss": ("#4B3A7E", "#171030", 0.0),   # the void machines': its light, its stone
    "paper": ("#FFF6E0", "#FFC27A", 1.0),      # the second row: a festival lantern's paper, lit from inside
    "dawn": ("#FF9AD2", "#FF4FA6", 0.55),      # the Tower's own light, faint
    # The distance, painted in (AR20): with no haze to pale them, the far shards, the Tower asleep and the shards
    # breaking out beside the crossing stood as black cut-outs against the day sky. Each wears a lighter void stone:
    # the farthest palest.
    "far": ("#9284C8", "#5E5298", 0.0),        # the great shards past the map's edge (the Strip's FarShard pieces)
    "tower": ("#7C76AE", "#46427A", 0.0),      # the Tower asleep, a violet slate
    "outcrop": ("#8474BC", "#4A3E86", 0.0),    # the Strip's ShardOutcrop, nearer, a little deeper
}
SWATCH_AT = {name: ((i % 16) * CELL[0], (i // 16) * CELL[1]) for i, name in enumerate(SWATCHES)}
# Prints: where each sits (x, y, width, height), each with a 4 pixel bleed round it.
PRINTS = {"panel": (8, 268, 512, 160), "hazard": (536, 268, 256, 48), "plate": (536, 332, 256, 112)}
PRINTS["half"] = (8, 268, 256, 160)   # the panel's first 8 studs, for the half panel: the same pixels, not drawn again
PRINTS["way"] = (8, 464, 240, 448)    # the Festival Door's way: the festival seen through it, 6 studs by 11.1
DECK = (512, 8.0)      # the deck's own tile: pixels, and the studs it covers (four plates)
PLATE = 4.0            # a deck plate, studs
DECK_TONES = ("#9EA7BC", "#8790A8", "#3A4154", "#BEC6D6")   # a plate's two colours, its seam, its lit edge (AR20's C)


def wear():
    """The mesh builder reads its atlas from the kit's module: the base's pieces wear the base's."""
    kit.SWATCHES, kit.SWATCH_AT, kit.PRINTS = SWATCHES, SWATCH_AT, PRINTS


# --- the pictures ----------------------------------------------------------------------------------------------------

def _mix(page, colour, amount):
    page[..., :3] = page[..., :3] * (1 - amount[..., None]) + code(colour) * amount[..., None]


def atlas():
    """The kit's colour picture and its glow picture, as sRGB-coded arrays."""
    page = np.zeros((A, A, 4), np.float32)
    page[..., :3], page[..., 3] = code("#181D32"), 1.0
    glow = np.zeros((A, A), np.float32)
    t = np.linspace(0, 1, CELL[1], dtype=np.float32)[:, None, None] ** 0.85   # down the cell: head to foot
    shade = 1.0 - 0.5 * np.clip((np.arange(CELL[0], dtype=np.float32) - 8) / 48, 0, 1)[None, :, None]
    for name, (top, bottom, lit) in SWATCHES.items():
        x, y = SWATCH_AT[name]
        cell = code(top) * (1 - t) + code(bottom) * t
        page[y:y + CELL[1], x:x + CELL[0], :3] = cell * (shade if lit < 0.5 else 1.0)
        glow[y:y + CELL[1], x:x + CELL[0]] = lit
    # a wall's panel, 16 studs by 5: ribbed steel, lighter at its head, a dark kick band, rivets on each rib
    x, y, w, h = PRINTS["panel"]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    rgb = np.empty((h, w, 4), np.float32)
    down = (yy / h)[..., None]
    rgb[..., :3] = code("#6A78A2") * (1 - down) + code("#3A4468") * down
    _mix(rgb, "#2A3252", (yy > h - 40).astype(np.float32) * 0.8)
    rib = xx % 64
    _mix(rgb, "#20263E", ((rib < 3) | (rib >= 61)).astype(np.float32))
    _mix(rgb, "#93A0C8", ((rib >= 3) & (rib < 5)).astype(np.float32) * 0.7)
    _mix(rgb, "#93A0C8", ((yy >= 10) & (yy < 12)).astype(np.float32) * 0.6)
    for ry in (24.0, h - 20.0):
        dot = np.clip(2.6 - np.hypot(np.abs(rib - 32.0) - 22.0, yy - ry), 0, 1)
        _mix(rgb, "#20263E", dot)
    kit._put(page, glow, rgb[..., :3], x, y)
    # hazard: yellow and black on the slant, for a tower's foot and a threshold
    x, y, w, h = PRINTS["hazard"]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    band = (((xx + yy) // 16) % 2)[..., None]
    kit._put(page, glow, code("#FFD23E") * (1 - band) + code("#1F2233") * band, x, y, 0.05)
    # the gate's plate: a dark field in a yellow line, bolts at its corners; the level is the builder's text on it
    x, y, w, h = PRINTS["plate"]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    edge = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
    line = ((edge >= 8) & (edge < 13)).astype(np.float32)
    rgb = np.empty((h, w, 4), np.float32)
    rgb[..., :3] = code("#141826")
    _mix(rgb, "#FFD23E", line)
    for cx in (22.0, w - 22.0):
        for cy in (22.0, h - 22.0):
            _mix(rgb, "#8A94B6", np.clip(3.0 - np.hypot(xx - cx, yy - cy), 0, 1))
    kit._put(page, glow, rgb[..., :3], x, y, (0.55 * line).astype(np.float32))
    rgb, lit = way()
    kit._put(page, glow, rgb, *PRINTS["way"][:2], lit)
    return page, glow


def way():
    """The Festival Door's way, its colour and its glow: the festival seen through the door. A street's warm white
    light at its foot rising into cyan dusk, and two strings of paper lanterns running away down the street to one
    point. Research's call, 2026-11-16: the Door says where it leads by the festival's own warm white and cyan."""
    _, _, w, h = PRINTS["way"]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    up = 1.0 - yy / h                                             # 0 the foot, 1 the arch's point
    rgb = np.empty((h, w, 4), np.float32)
    high = np.clip((up - 0.3) / 0.7, 0, 1)[..., None]
    rgb[..., :3] = code("#7FEAF4") * (1 - high) + code("#1C9CCB") * high
    warm = np.clip((0.44 - up) / 0.36, 0, 1) ** 1.2
    _mix(rgb, "#FFF3D2", warm)
    lit = 0.5 + 0.2 * (1 - high[..., 0]) + 0.3 * warm
    cx, far = w / 2, 0.36                                         # the street's far end, where the strings meet
    for k in range(7):
        near = 0.66 ** k
        r = 19.0 * near
        for side in (-1, 1):
            lx, ly = cx + side * 0.41 * w * near, h * (1 - (far + 0.40 * near))
            d = np.hypot((xx - lx) / 0.82, yy - ly) / r
            _mix(rgb, "#FFBE6A", np.clip(1.0 - (d - 1.0) / 1.5, 0, 1) ** 2 * 0.75)    # its halo
            _mix(rgb, "#FFF9EA", np.clip((1.12 - d) / 0.24, 0, 1))                    # its paper
            lit = np.maximum(lit, np.clip(1.0 - (d - 1.0) / 1.5, 0, 1))
    return rgb[..., :3], lit.astype(np.float32)


def plates(x, y, seed, px):
    """Deck plates over a field of studs (`x`, `y`): each its own tone, a dark seam, a lit edge, a bolt at each corner."""
    rng = np.random.default_rng(seed)
    a, b, seam, lit = (code(c) for c in DECK_TONES)
    cols, rows = int(np.ceil(x.max() / PLATE)) + 1, int(np.ceil(y.max() / PLATE)) + 1
    k = rng.uniform(0.0, 1.0, (rows, cols)).astype(np.float32)[(y // PLATE).astype(int), (x // PLATE).astype(int)][..., None]
    page = np.ones((*x.shape, 4), np.float32)
    page[..., :3] = a * (1 - k) + b * k
    fx, fy = x % PLATE, y % PLATE
    near = np.minimum(np.minimum(fx, PLATE - fx), np.minimum(fy, PLATE - fy))
    _mix(page, DECK_TONES[3], ((np.minimum(fx, fy) < 3.2 * px) & (near >= 1.2 * px)).astype(np.float32) * 0.45)
    _mix(page, DECK_TONES[2], np.clip(1.7 - near / px, 0, 1))
    bolt = np.hypot(np.minimum(fx, PLATE - fx) - 0.42, np.minimum(fy, PLATE - fy) - 0.42)
    _mix(page, DECK_TONES[2], np.clip((0.12 - bolt) / px + 0.5, 0, 1) * 0.8)
    return page


def deck_tile():
    n = DECK[0]
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    px = DECK[1] / n
    return plates((xx + 0.5) * px, (yy + 0.5) * px, 5, px)


def _band(px):
    return lambda dist, reach: np.clip((reach - np.abs(dist)) / px + 0.5, 0, 1)


def conduits(page, glow, x, y, px, live=(), dead=(), arcs=()):
    """The conduits in a floor's picture: a dark casing with a clamp every plate, and in a live one the current, a
    bright core with its halo. A run is two ends, at any slant. An arc is live: its middle, its radius, and the two
    turns it runs between, in degrees from the way toward the gate round by the right. A junction sits on each live
    end."""
    band = _band(px)
    laid = dict(casing=np.zeros_like(glow), core=np.zeros_like(glow), halo=np.zeros_like(glow))

    def lay(d, along, lit):
        clamp = ((along % PLATE) < 0.4).astype(np.float32)
        laid["casing"] = np.maximum(laid["casing"], np.maximum(band(d, 0.8), band(d, 1.05) * clamp))
        if lit:
            laid["core"] = np.maximum(laid["core"], band(d, 0.32) * (1 - clamp))
            laid["halo"] = np.maximum(laid["halo"], np.exp(-(d / 2.4) ** 2))

    def junction(ex, ey):
        e = np.hypot(x - ex, y - ey)
        laid["casing"] = np.maximum(laid["casing"], band(e, 1.3))
        laid["core"] = np.maximum(laid["core"], band(e - 0.75, 0.16))

    for lit, runs in ((True, live), (False, dead)):
        for (x0, y0), (x1, y1) in runs:
            length = math.hypot(x1 - x0, y1 - y0)
            ux, uy = (x1 - x0) / length, (y1 - y0) / length
            along, off = (x - x0) * ux + (y - y0) * uy, (y - y0) * ux - (x - x0) * uy
            lay(np.hypot(off, along - np.clip(along, 0.0, length)), along, lit)
            if lit:
                junction(x0, y0)
                junction(x1, y1)
    for (cx, cy), radius, start, end in arcs:
        turn = np.degrees(np.arctan2(x - cx, cy - y))
        held = np.radians(np.clip(turn, start, end))
        lay(np.hypot(x - (cx + radius * np.sin(held)), y - (cy - radius * np.cos(held))), np.radians(turn) * radius, True)
        for at in (start, end):
            junction(cx + radius * math.sin(math.radians(at)), cy - radius * math.cos(math.radians(at)))
    _mix(page, "#141724", laid["casing"])
    _mix(page, "#FFF1A8", laid["core"])
    return np.maximum(glow + 0.3 * laid["halo"] * (1 - laid["casing"]), laid["core"])


def ring_arc():
    """The ring of current round the well, on the plot's right half: from its open end, on the Breaker's slant, round
    to the main line at its back. The left half is the same, mirrored: the ring stays open toward the gate, the way
    in running into it."""
    return (GENERATOR, RING, 45.0, 180.0)


def live_runs():
    """The live conduits on the plot's right half and its middle line, each from the heart's end outward, across and
    in: from the well's rim to the ring and on along the bus to the bay's frame; from the ring's open end out on the
    slant to the Breaker's ground; from the ring back on the slant to the battery's; and from the well's back to the
    ring. The left half is the same, mirrored."""
    s = RING * math.sqrt(0.5)
    near, far = BREAKER[1] + PAD[1], BATTERY[1] - PAD[1]
    return [((WELL + 0.6, ROW), (RING, ROW)), ((RING, ROW), (OUTER - 6.2, ROW)),
            ((s, ROW - s), (ROW - near, near)), ((s, ROW + s), (far - ROW, far)),
            ((0.0, ROW + WELL + 0.6), (0.0, ROW + RING))]


def dead_runs():
    """The lines with no current in them yet, as their casings alone, on the plot's right half and its middle line:
    the main line on from the ring's back to the Lab's place and from it to the back wall; a spoke from the main
    line's node to the Condenser's place (the Forge's, mirrored); and the bus on from the open bay to the next, then
    back along the wall to the last. Each lights out to its place when the place wakes."""
    reach = math.hypot(CONDENSER[0], CONDENSER[1] - NODE)
    held = (reach - SLEEPS - 1.6) / reach
    return [((0.0, ROW + RING), (0.0, LAB[1] - SLEEPS)), ((0.0, LAB[1] + SLEEPS), (0.0, YARD + 2.0)),
            ((0.0, NODE), (CONDENSER[0] * held, NODE + (CONDENSER[1] - NODE) * held)),
            ((OUTER + 6.2, ROW), (FAR - SLEEPS, ROW)), ((FAR, ROW + SLEEPS), (FAR, BACK - SLEEPS))]


def sleeping():
    """The places asleep on the plot's right half and its middle line, at level 1."""
    return [(FAR, ROW), (FAR, BACK), CONDENSER, LAB]


def asleep(page, x, y, px, at):
    """A sleeping place's ground: a darker square inside a grey frame, heavy at its corners. Nothing in it is lit."""
    band = _band(px)
    dx, dy = np.abs(x - at[0]), np.abs(y - at[1])
    box = np.maximum(dx, dy)
    corner = (np.minimum(dx, dy) > SLEEPS - 2.6).astype(np.float32)
    page[..., :3] *= (1.0 - 0.22 * np.clip((SLEEPS - box) / px + 0.5, 0, 1))[..., None]
    _mix(page, "#7A84A6", np.maximum(band(box - SLEEPS, 0.1), band(box - SLEEPS, 0.28) * corner) * 0.6)


def pools(x, y):
    """The court's soft light on the deck, which runs on past the court's back edge into the yard's first block: the
    well's, the Breaker's ground's, and the floods'. `y` is studs in from the plot's front edge."""
    return (0.22 * np.exp(-(np.hypot(x, y - ROW) / 14.0) ** 2)
            + 0.3 * np.exp(-((x - BREAKER[0]) ** 2 + (y - BREAKER[1]) ** 2) / 11.0 ** 2)
            + 0.3 * np.exp(-((x - flood_across()) ** 2 + (y - (FLOOD[0] - FLOOD[1])) ** 2) / 9.0 ** 2))


def well(page, glow, x, y, px):
    """The generator's ground: a well, the void under the plant's heart. Dark, a few far lights in it, a rim of the
    void's own violet inside Power's yellow: the one place the yard shows what its power is drawn from. `y` is studs in
    from the plot's front edge, so the yard's first block draws whatever of it passes the court's back edge."""
    band = _band(px)
    r = np.hypot(x, y - ROW)
    inside = np.clip((WELL - r) / px + 0.5, 0, 1)
    page[..., :3] = page[..., :3] * (1 - inside[..., None]) + code("#0A0816") * inside[..., None]
    glow = glow * (1 - inside)
    rng = np.random.default_rng(72)
    for _ in range(int(0.46 * WELL ** 2)):
        a, q = rng.uniform(0, np.pi), (WELL - 1.2) * np.sqrt(rng.uniform(0.15, 1.0))
        star = band(np.hypot(x - q * np.sin(a), y - (ROW + q * np.cos(a))), float(rng.choice((0.07, 0.07, 0.11))))
        _mix(page, "#E8DCFF", star)
        glow += 0.7 * star
    _mix(page, "#B98CFF", band(r - (WELL - 0.5), 0.16))
    _mix(page, "#FFD23E", band(r - WELL, 0.14))
    return glow + 0.6 * band(r - (WELL - 0.5), 0.16) + 0.5 * band(r - WELL, 0.14), inside


def flood_across():
    """A flood mast's place across: just outside the way in's line, clear of the way and of the ring's slants."""
    return LANE + 1.1


def pad(page, glow, x, y, px, at, line, lit=0.45):
    """A machine's ground: a darker dais inside a line of its own colour."""
    band = _band(px)
    box = np.maximum(np.abs(x - at[0]) - PAD[0], np.abs(y - at[1]) - PAD[1])
    page[..., :3] *= (1.0 - 0.3 * np.clip(-box / px + 0.5, 0, 1))[..., None]
    _mix(page, line, band(box, 0.12))
    return glow + lit * band(box, 0.12)


def bay_frame(page, glow, x, y, px, at):
    """An open bay's ground: a frame of Power's yellow round its pad, heavy at its corners, lit."""
    band = _band(px)
    dx, dy = np.abs(x - at[0]), np.abs(y - at[1])
    box = np.maximum(dx, dy)
    corner = (np.minimum(dx, dy) > 3.6).astype(np.float32)
    frame = np.maximum(band(box - 6.2, 0.12), band(box - 6.2, 0.3) * corner)
    page[..., :3] *= (1.0 - 0.3 * np.clip((6.2 - box) / px + 0.5, 0, 1))[..., None]
    _mix(page, "#FFD23E", frame)
    return glow + 0.4 * frame + 0.16 * np.exp(-((x - at[0]) ** 2 + (y - at[1]) ** 2) / 8.0 ** 2)


def way_in(page, x, y, px):
    """The way in: a pale dashed line down each of its edges, from the gate to the ring's open ends."""
    reach = ROW - RING * math.sqrt(0.5) - 2.0
    _mix(page, "#D4DCEE", _band(px)(x - LANE, 0.11) * ((y % 4.0) < 2.0) * (y > 3.0) * (y < reach) * 0.45)


def marks(page, glow, x, y, px):
    """Everything the layout draws on the deck, in the plot's own studs: `x` across from the middle line, `y` in from
    the front edge. A floor's picture shows whatever of it falls on that floor, so a place that moves takes its marks
    with it: the Breaker's ground (the Door's, mirrored), the battery's (the Training machine's), the open bay's
    frame, the conduits and the ring, the box where the dormant main line leaves the ring, the well and the pools."""
    band = _band(px)
    glow = pad(page, glow, x, y, px, BREAKER, "#BFEFF5")
    glow = pad(page, glow, x, y, px, BATTERY, "#D4DCEE", 0.3)
    glow = bay_frame(page, glow, x, y, px, (OUTER, ROW))
    for at in sleeping():
        asleep(page, x, y, px, at)
    glow = conduits(page, glow, x, y, px, live=live_runs(), dead=dead_runs(), arcs=[ring_arc()])
    node = np.maximum(np.abs(x), np.abs(y - NODE))                 # the main line's node, dark: the spokes leave it
    _mix(page, "#141724", band(node, 1.3))
    _mix(page, "#3A4266", band(node, 1.3) * (1 - band(node, 1.0)))
    e = np.maximum(np.abs(x), np.abs(y - (ROW + RING)))
    rim = band(e, 1.5) * (1 - band(e, 1.15))
    lamp = band(np.hypot(x, y - (ROW + RING)), 0.5)
    _mix(page, "#141724", band(e, 1.5))
    _mix(page, "#FFD23E", rim)
    _mix(page, "#FFF1A8", lamp)
    glow, inside = well(page, glow + lamp + 0.3 * rim, x, y, px)
    return glow + pools(x, y) * (1 - inside)


def court_pictures(level=1):
    """A level's court, half of it: across from the plot's middle line out to its edge (the picture's left to its
    right), in from the front edge (its head to its foot). The way in runs down its middle toward the heart, in the
    yard's first block; the ring's end comes out on the slant to the Breaker's ground (the Door's, mirrored). The
    colour, and the glow: the current, the grounds' lines, and the soft pools."""
    n = 1024
    half, deep = COURT
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    x, y = (xx + 0.5) / n * half, (yy + 0.5) / n * deep
    px = (half + deep) / 2 / n
    band = _band(px)
    page = plates(x, y, 14 + level, px)
    glow = np.zeros((n, n), np.float32)
    # the court's own line down its side: the deck runs on past it into the wings, and into the yard at its back
    _mix(page, "#C9D2E6", band(x - (half - 0.4), 0.09) * 0.6)
    # the threshold under the gate, between its towers' feet: hazard on the slant
    sill = (band(y - 0.9, 0.7) * (x < GATE - 2.6)).astype(np.float32)
    stripe = (((x + y) // 0.9) % 2).astype(np.float32)
    _mix(page, "#FFD23E", sill * (1 - stripe))
    _mix(page, "#1F2233", sill * stripe)
    way_in(page, x, y, px)
    # where the player arrives: a ring on the deck
    r = np.hypot(x, y - SPAWN[1])
    ring = np.maximum(band(r - 4.2, 0.14), band(r - 3.2, 0.06))
    _mix(page, "#E9E2D2", ring * 0.9)
    glow += 0.25 * ring
    return page, grey(marks(page, glow, x, y, px))


def spine(x, along, px):
    """The yard's main conduit down the plot's middle line, as its casing alone: no current in it yet. `along` is
    studs from where it starts; it runs on off the picture."""
    d = np.hypot(x, np.minimum(along, 0.0))
    clamp = ((along % PLATE) < 0.4).astype(np.float32)
    band = _band(px)
    return np.maximum(band(d, 0.8), band(d, 1.05) * clamp)


def yard_pictures(kind=None):
    """A yard block, half of it, laid again and again behind the court to the back wall: the deck with its lanes, the
    main conduit down the middle and a joint across its far edge. Dead, it is plain on purpose: nothing is marked on
    it, since nothing will stand on it (research, 2026-11-16). `live` is the block behind the court, the heart's: the
    way in's last studs, the well, the ring and the lines leaving it. `back` is the block behind that: the slant
    arriving at the battery's ground (the Training machine's, mirrored), and the main line going on, dormant."""
    n = 1024
    half, deep = COURT[0], BLOCK
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    x, y = (xx + 0.5) / n * half, (yy + 0.5) / n * deep
    px = (half + deep) / 2 / n
    band = _band(px)
    page = plates(x, y, 31, px)
    if not kind:
        page[..., :3] *= 0.9                                    # a shade under the court: nothing here is lit
    glow = np.zeros((n, n), np.float32)
    if kind != "live":
        _mix(page, "#D4DCEE", band(x - LANE, 0.11) * ((y % 4.0) < 2.0) * 0.45)
    # the joint across the block's far edge: where one block of the yard ends
    _mix(page, "#252B44", band(y - (deep - 0.2), 0.2))
    _mix(page, "#C9D2E6", band(y - (deep - 0.55), 0.07) * 0.5)
    if kind:
        front = COURT[1] + deep * ("live", "back").index(kind)  # the block's own front edge, in from the plot's
        way_in(page, x, y + front, px)
        return page, grey(marks(page, glow, x, y + front, px))
    _mix(page, "#141724", spine(x, y + PLATE, px))              # the main line, as its casing alone
    return page, grey(glow)


def wings_pictures(kind=None):
    """A wing block, one side's: the deck from the middle strip's edge out to the side wall (the picture's left to
    its right), laid again and again from the front wall back. Dead, the plainest ground of the base, kept for its
    later levels: two service lanes, the wall's foot, and the block's joint, with nothing marked on it. `live` is the heart's block, the second from the front: the bus runs in from the ring to an open
    bay's frame, and on, dead, to the next bay's place, asleep. `back` is the block behind it: the last bay's place."""
    n = 1024
    wide, deep = HALF - COURT[0], BLOCK
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    x, y = (xx + 0.5) / n * wide, (yy + 0.5) / n * deep
    px = (wide + deep) / 2 / n
    band = _band(px)
    page = plates(x, y, 47, px)
    if not kind:
        page[..., :3] *= 0.9
    glow = np.zeros((n, n), np.float32)
    # the wall's foot: a darker margin inside a pale line
    margin = np.clip((x - (wide - 3.0)) / px + 0.5, 0, 1)
    page[..., :3] *= (1.0 - 0.38 * margin)[..., None]
    _mix(page, "#C9D2E6", band(x - (wide - 3.0), 0.09) * 0.6)
    for lane in (6.0, 42.0):
        _mix(page, "#D4DCEE", band(x - lane, 0.11) * ((y % 4.0) < 2.0) * 0.4)
    _mix(page, "#252B44", band(y - (deep - 0.2), 0.2) * (x < wide - 3.0))
    _mix(page, "#C9D2E6", band(y - (deep - 0.55), 0.07) * (x < wide - 3.0) * 0.5)
    if kind:
        return page, grey(marks(page, glow, x + COURT[0], y + BLOCK * (1 + ("live", "back").index(kind)), px))
    return page, grey(glow)


FLOORS = {"Court1": lambda: court_pictures(1), "Yard": yard_pictures, "YardLive": lambda: yard_pictures("live"),
          "YardBack": lambda: yard_pictures("back"), "Wings": wings_pictures, "WingsLive": lambda: wings_pictures("live"),
          "WingsBack": lambda: wings_pictures("back")}


def write_pictures(out: Path, save=None, only=None):
    """The kit's pictures. `save` stands in for the sheet's own writer when Blender is closed; `only` names floors."""
    save = save or rs.save
    out.mkdir(parents=True, exist_ok=True)
    if only is None:
        page, glow = atlas()
        save(page, out / "Base_Kit_Color.png")
        save(grey(glow), out / "Base_Kit_Glow.png")
        save(deck_tile(), out / "Base_Deck_Color.png")
    for name, draw in FLOORS.items():
        if only is None or name in only:
            colour, lit = draw()
            save(colour, out / f"Base_{name}_Color.png")
            save(lit, out / f"Base_{name}_Glow.png")


# --- the pieces ------------------------------------------------------------------------------------------------------

def insulator(m, at, length, r=0.34, ribs=3, sides=5):
    """A ribbed ceramic stack standing up from `at`: what says power from a street away."""
    step = length / ribs
    profile = []
    for i in range(ribs):
        z = length - i * step
        profile += [(r * 0.45, z), (r, z - step * 0.4), (r * 0.45, z - step * 0.8)]
    profile.append((r * 0.45, 0.0))
    m.lathe(profile, at, sides, "ceramic")


def court(level):
    def make():
        """A level's court floor, the middle 88 studs by 48 from the front edge in: one picture, laid mirrored about
        the middle."""
        m = Mesh(None)
        half, deep = COURT
        m.face([Vector((0, -deep, 0.06)), Vector((half, -deep, 0.06)), Vector((half, 0, 0.06)), Vector((0, 0, 0.06))],
               [(0, 0), (1, 0), (1, 1), (0, 1)])
        m.face([Vector((-half, -deep, 0.06)), Vector((0, -deep, 0.06)), Vector((0, 0, 0.06)), Vector((-half, 0, 0.06))],
               [(1, 0), (0, 0), (0, 1), (1, 1)])
        return Piece(f"Court{level}", m, maps=f"Court{level}", solid="floor",
                     note="lies 0.06 over the deck, its front edge on the plot's; a Part under it carries the walking")
    return make


def yard(name="Yard"):
    """A yard block's floor, 88 studs by 48, its front edge at the piece's place: one picture, laid mirrored about the
    middle. Three stand behind the court, toward the back wall; YardLive is the same floor in the live picture."""
    m = Mesh(None)
    half, deep = COURT[0], BLOCK
    m.face([Vector((0, -deep, 0.06)), Vector((half, -deep, 0.06)), Vector((half, 0, 0.06)), Vector((0, 0, 0.06))],
           [(0, 0), (1, 0), (1, 1), (0, 1)])
    m.face([Vector((-half, -deep, 0.06)), Vector((0, -deep, 0.06)), Vector((0, 0, 0.06)), Vector((-half, 0, 0.06))],
           [(1, 0), (0, 0), (0, 1), (1, 1)])
    return Piece(name, m, maps=name, solid="floor",
                 note="lies 0.06 over the deck behind the court, block after block; a Part under it carries the walking")


def wings(name="Wings"):
    """A block of the deck each side of the middle strip, out to the side walls: 56 studs by 48 a side, its front
    edge at the piece's place, one picture mirrored about the middle. Four stand from the front wall back; WingsLive
    and WingsBack are the same floor in their own pictures."""
    m = Mesh(None)
    near, far, deep = COURT[0], HALF, BLOCK
    m.face([Vector((near, -deep, 0.06)), Vector((far, -deep, 0.06)), Vector((far, 0, 0.06)), Vector((near, 0, 0.06))],
           [(0, 0), (1, 0), (1, 1), (0, 1)])
    m.face([Vector((-far, -deep, 0.06)), Vector((-near, -deep, 0.06)), Vector((-near, 0, 0.06)), Vector((-far, 0, 0.06))],
           [(1, 0), (0, 0), (0, 1), (1, 1)])
    return Piece(name, m, maps=name, solid="floor",
                 note="lies 0.06 over the deck each side of the court and of the yard's blocks, the two sides one mesh; "
                      "a Part under it carries the walking")


def wall(run=16.0):
    """The yard's wall: a post on a concrete foot with a lamp on its cap, and a ribbed steel panel 16 studs along +X
    to the next post, a line of light under its bone coping. The half panel runs 8, so a wall closes on the plot's
    200. A run's last post is the same without the panel."""
    m = Mesh()
    m.box((2.0, 2.0, 1.2), (0, 0, 0.6), "concrete", ink=True)
    m.box((1.1, 1.1, 5.4), (0, 0, 3.9), "girder", ink=True)
    m.box((1.5, 1.5, 0.4), (0, 0, 6.8), "yellow")
    m.box((0.6, 0.6, 0.5), (0, 0, 7.25), "power")
    if run:
        panel, coping, print_ = {16.0: (14.9, 15.2, "panel"), 8.0: (6.9, 7.2, "half")}[run]
        m.box((panel, 1.0, 1.0), (run / 2, 0, 0.5), "concrete", ink=True)
        m.box((panel, 0.5, 3.6), (run / 2, 0, 2.8), "steel", pics={"+y": print_, "-y": print_}, ink=True)
        m.box((panel, 0.58, 0.14), (run / 2, 0, 4.72), "power")
        m.box((coping, 0.8, 0.3), (run / 2, 0, 4.95), "bone")
    name = {16.0: "Wall", 8.0: "WallHalf", 0.0: "WallEnd"}[float(run)]
    return Piece(name, m, solid="the post, and the panel as a wall 5 studs high" if run else "the post",
                 note=f"the panel runs {run:g} studs along +X to the next post" if run else "a run's last post: no panel")


def gate():
    """Level 1's gate on the Strip: two steel towers on concrete feet with hazard at the foot and an insulator and a
    beacon on the head, a truss between them carrying the base's plate, two floods under it, and a shoulder of wall
    out to each front wall's end. The Breaker shows under the truss from the Strip."""
    m = Mesh()
    for side in (-1, 1):
        x = side * GATE
        m.box((4.6, 4.6, 2.0), (x, 0, 1.0), "concrete", ink=True)
        m.box((2.6, 2.6, 15.4), (x, 0, 9.7), "girder", ink=True)
        m.box((2.8, 2.8, 1.5), (x, 0, 3.4), "yellow", pics={k: "hazard" for k in ("+x", "-x", "+y", "-y")})
        m.box((0.16, 1.0, 8.6), (x - side * 1.34, 0, 9.6), "power")          # a strip of light down the inner face
        m.box((3.2, 3.2, 0.5), (x, 0, 17.65), "bone", ink=True)
        insulator(m, (x, 0, 17.9), 2.2, r=0.55)
        m.box((0.5, 0.5, 0.5), (x, 0, 20.35), "beacon")
        mid, reach = side * (GATE + 2.3 + WING) / 2, WING - GATE - 2.3
        m.box((reach, 1.0, 1.0), (mid, 0, 0.5), "concrete")
        m.box((reach, 0.5, 3.6), (mid, 0, 2.8), "steel")
        m.box((reach, 0.58, 0.14), (mid, 0, 4.72), "power")
        m.box((reach, 0.8, 0.3), (mid, 0, 4.95), "bone")
    span = 2 * GATE - 2.6
    for z in (15.0, 17.0):
        for y in (-0.8, 0.8):
            m.box((span, 0.36, 0.36), (0, y, z), "steel")
    for y in (-0.8, 0.8):
        m.tube([(-span / 2 + span * i / 10, y, 15.0 if i % 2 == 0 else 17.0) for i in range(11)], 0.13, "steel")
    m.box((11.0, 2.2, 4.4), (0, 0, 16.0), "rubber", pics={"+y": "plate", "-y": "plate"}, ink=True)
    for x in (-13.0, 13.0):
        m.box((2.0, 1.3, 0.7), (x, 0, 14.45), "girder", ink=True)
        m.box((1.6, 0.9, 0.12), (x, 0, 14.05), "lamp")
    return Piece("Gate1", m, solid="a box round each tower's foot, 4.6 square, and the two shoulders as walls",
                 note="clear between the towers' feet: 39.4 studs, 14 under the floods; the plate's faces are +Y and "
                      "-Y, 11 by 4.4 at 16 up: the base's level is the builder's text on both")


def pylon():
    """A lattice pylon, 25 studs: four legs drawing in, braced on every face, two arms across its line with a hung
    insulator at each end, a beacon on its mast."""
    m = Mesh()
    top = 22.0
    levels = (0.0, 6.5, 12.0, 16.5, 20.0, top)
    signs = ((1, 1), (-1, 1), (-1, -1), (1, -1))
    wide = lambda z: 2.2 - 1.65 * z / top   # noqa: E731
    for sx, sy in signs:
        m.box((1.3, 1.3, 0.6), (sx * 2.2, sy * 2.2, 0.3), "concrete")
        m.tube([(sx * wide(z), sy * wide(z), z) for z in levels], 0.2, "girder")
    for z0, z1 in zip(levels, levels[1:]):
        a, b = wide(z0), wide(z1)
        for i in range(4):
            (sx, sy), (tx, ty) = signs[i], signs[(i + 1) % 4]
            m.tube([(sx * b, sy * b, z1), (tx * b, ty * b, z1)], 0.12, "girder")
            m.tube([(sx * a, sy * a, z0), (tx * b, ty * b, z1)], 0.1, "steel")
    for z, reach in ARMS:
        m.box((0.44, 2 * reach, 0.44), (0, 0, z), "girder", ink=True)
        for sy in (-1, 1):
            insulator(m, (0, sy * (reach - 0.3), z - HANG), HANG - 0.2)
    m.box((0.3, 0.3, 2.6), (0, 0, top + 1.3), "girder")
    m.box((0.6, 0.6, 0.6), (0, 0, top + 2.9), "beacon")
    return Piece("Pylon", m, solid="a box, 5 square, 8 high",
                 note="its arms lie along Y: stand it with its X along the line it carries")



def power_span():
    """The lines from one pylon to the next, 48 studs along +X: four cables hung from the insulators' feet."""
    m = Mesh(None)
    for z, reach in ARMS:
        for sy in (-1, 1):
            m.tube([(SPAN * t, sy * (reach - 0.3), z - HANG - 2.6 * (1 - (2 * t - 1) ** 2)) for t in np.linspace(0, 1, 9)],
                   0.08, "rubber")
    return Piece("PowerSpan", m, note="from a pylon's place to the next, 48 studs along +X, both pylons turned the same way")


def flood_mast():
    """A flood mast: a steel mast on a concrete foot, an arm toward +Y, two lamps looking down."""
    m = Mesh()
    _, reach, height = FLOOD
    m.box((1.6, 1.6, 0.8), (0, 0, 0.4), "concrete", ink=True)
    m.box((0.9, 0.9, 0.6), (0, 0, 1.4), "yellow", pics={k: "hazard" for k in ("+x", "-x", "+y", "-y")})
    m.box((0.5, 0.5, height + 0.6), (0, 0, (height + 0.6) / 2 + 0.8), "girder", ink=True)
    m.box((0.3, reach + 0.4, 0.3), (0, reach / 2, height + 1.2), "girder")
    m.box((3.0, 0.3, 0.3), (0, reach, height + 1.2), "girder")
    for x in (-0.9, 0.9):
        m.box((1.3, 1.0, 0.8), (x, reach, height + 0.7), "steel", ink=True)
        m.box((1.0, 0.7, 0.1), (x, reach, height + 0.26), "lamp")
    return Piece("FloodMast", m, lights=[("Pool", (0.0, reach, height), "#EAF6FF")], solid="the mast",
                 note="its head reaches 3 studs toward +Y; a SpotLight straight down from Pool where the plan has one")


def transformer():
    """A transformer: a finned steel tank on a concrete pad with a yellow band, three insulators on its lid, each
    with a lit tip."""
    m = Mesh()
    m.box((3.6, 3.0, 0.5), (0, 0, 0.25), "concrete", ink=True)
    m.box((2.8, 2.0, 2.6), (0, 0, 1.8), "steel", ink=True)
    m.box((2.86, 2.06, 0.34), (0, 0, 1.0), "yellow")
    for sx in (-1, 1):
        for k in range(4):
            m.box((0.36, 0.16, 2.0), (sx * 1.58, -0.75 + 0.5 * k, 1.9), "girder")
    m.box((3.0, 2.2, 0.24), (0, 0, 3.22), "girder")
    for x in (-0.9, 0.0, 0.9):
        insulator(m, (x, 0, 3.34), 1.5, r=0.3)
        m.box((0.3, 0.3, 0.3), (x, 0, 4.99), "power")
    return Piece("Transformer", m, solid="a box, 3.6 by 3 by 3.4")


PIECES = {"Court1": court(1), "Yard": yard, "Wings": wings, "YardLive": lambda: yard("YardLive"),
          "YardBack": lambda: yard("YardBack"), "WingsLive": lambda: wings("WingsLive"), "WingsBack": lambda: wings("WingsBack"), "Wall": wall, "WallHalf": lambda: wall(8.0),
          "WallEnd": lambda: wall(0.0), "Gate1": gate, "Pylon": pylon,
          "PowerSpan": power_span, "FloodMast": flood_mast, "Transformer": transformer,
          **machines.PIECES,       # and the machines' own models (AR15, base_machines.py)
          **mill.PIECES,           # and the generator, the Void Mill (AR19, base_mill.py)
          **show.PIECES}           # and the showcase's plinth (TR22, base_show.py)


def build(name):
    wear()
    return PIECES[name]()


class Stock:
    """Each piece built once, as one mesh with its ink, and stood wherever a plan says (the look's own)."""

    def __init__(self, maps: Path, scene, look_kit):
        self.scene, self.kit, self.made = scene, look_kit, {}
        self.mats = {name: kit.kit_material(maps, name, "Base", glow) for name, glow in MAPS.items()}

    def stand(self, name, tag, at, turn):
        if name not in self.made:
            piece = build(name)
            self.made[name] = (piece, piece.mesh.whole().to_object(name, self.mats[piece.maps]))
        obj = bpy.data.objects.new(f"{name}_{tag}", self.made[name][1])
        obj.location, obj.rotation_euler = at, (0, 0, math.radians(turn))
        self.scene.collection.objects.link(obj)
        self.kit.pieces.append(obj)
        return obj


# --- the handoff -----------------------------------------------------------------------------------------------------

def export(out: Path):
    scene = bl.reset_scene()
    folders = {name: out / name for name in ("meshes", "maps")}
    for f in folders.values():
        f.mkdir(parents=True, exist_ok=True)
    write_pictures(folders["maps"])
    listing = {}
    for name in PIECES:
        piece = build(name)
        obj = bpy.data.objects.new(name, piece.mesh.whole().to_object(name, None))
        scene.collection.objects.link(obj)
        tris = bl.export_mesh_json(obj, folders["meshes"] / f"{name}.json", uv=True)
        record = json.loads((folders["meshes"] / f"{name}.json").read_text())
        if name in ink.HULLED:                                    # a machine's round shapes get the edge the boxes have
            record = ink.hull(record)
            (folders["meshes"] / f"{name}.json").write_text(json.dumps(record, separators=(",", ":")))
            tris = len(record["f"]) // 9
        ps = np.array(record["p"], np.float32).reshape(-1, 3)
        tint, strength = MAPS[piece.maps]
        listing[name] = dict(
            mesh=f"meshes/{name}.json", triangles=tris, vertices=len(ps), centre=record["c"],
            size=[round(float(v), 3) for v in ps.max(0) - ps.min(0)],
            colour=f"maps/Base_{piece.maps}_Color.png", glow=f"maps/Base_{piece.maps}_Glow.png",
            glowTint=tint, glowStrength=strength, collision=piece.solid,
            lights=[dict(name=n, at=[round(at[0], 3), round(at[2], 3), round(-at[1], 3)], colour=c) for n, at, c in piece.lights],
            note=piece.note)
    manifest = dict(
        what="AR14: the base's own kit, a power yard. Made and laid as Lantern Row's kit is.",
        unit="1 = 1 stud",
        frame="Roblox's: a piece's front (Blender +Y) is -Z. A MeshPart goes at the piece's place times `centre`. "
              "A light's `at` is in the piece's own frame.",
        surface="one SurfaceAppearance per MeshPart: ColorMap `colour`, EmissiveMaskContent `glow`, EmissiveTint "
                "`glowTint`, EmissiveStrength from `glowStrength` (tuned in the engine). Single sided: each piece's ink "
                "is in its mesh, a hull turned inside out on the atlas's ink texel.",
        ink=f"the drawn edge is a hull {ink.INK:g} studs out (base_ink.py); Lantern Row's is {ink.SHARED:g}",
        shadows="CastShadow off on PowerSpan and the floors (Court1, Yard, Wings, YardLive, YardBack, WingsLive, WingsBack).",
        maps={"Base_Deck_Color.png": f"the plain deck, a tile {DECK[1]:g} studs square (four plates), for a Texture on a Part"},
        pieces=listing)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print(json.dumps({name: entry["triangles"] for name, entry in listing.items()}))


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "export"
    if mode == "pictures":
        write_pictures(out)
    elif mode == "export":
        export(out)


if __name__ == "__main__":
    main()
