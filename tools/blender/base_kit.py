"""AR14: the base's own kit (docs/asset-requests.md). The base is a power plant (docs/design.md, "The base"), so its
pieces are a power yard's and none of Lantern Row's: a deck of steel plates with the current running through it in
lit conduits, a panel wall with a line of light along its top, a gate on the Strip that carries the base's level,
lattice pylons with their lines, flood masts and transformers.

Made as Lantern Row's kit is (lantern_row_kit.py: its mesh builder, its swatch atlas, its ink hull, its manifest), on
pictures of its own, so the builder's Kit.Place and its upload take it unchanged. A piece's front faces +Y, toward the
Strip; its origin is on the floor; one unit is one stud.

The deck's look is sixteen floor pieces, a grid of four by four over the plot, each with its own pair of pictures: the
plates, each machine's ground, the well and the ring round it, and the conduits from the ring out to every machine,
glowing in the picture so they cost no Light. The yard isn't the same on its two sides (AR54), so no picture is
mirrored: each is drawn for its own ground, from the star's geometry (base_star.py).

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
import base_battery as battery  # noqa: E402
import base_bay as bays  # noqa: E402
import base_breaker as breaker  # noqa: E402
import base_ink as ink  # noqa: E402
import base_levels as levels  # noqa: E402
import base_machines as machines  # noqa: E402
import base_forge as forge  # noqa: E402
import base_forge_stages as forge_stages  # noqa: E402
import base_mill as mill  # noqa: E402
import base_show as show  # noqa: E402
import base_star as star  # noqa: E402
import base_training as training  # noqa: E402
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import rook_sheet as rs  # noqa: E402

Mesh, Piece, code, grey = ink.Mesh, kit.Piece, kit.code, kit.grey   # the kit's mesh, with the base's thinner hull
A, CELL = kit.A, kit.CELL

# --- the plot, as the builder lays it (WorldService.plot, Config.World): copies, read again when the layout moves ------
# Studs. `in` is from the plot's front edge, the one on the Strip, into the plot.

PLOT, STRIP = 128.0, 48.0
# The spread (AR16; the director, 2026-11-15: "just make it less clustered make it accross the base"). Each place is
# across and in. The placement is a star round the generator (the director, the same night, of one straight row:
# "i dont like the placement of the building it a bit to simplish"). The generator stands at the plot's heart, at the
# end of the way in, inside a ring of current open toward the gate, and the ring's two ends run out on the slant to the
# Breaker and the Door, nearer the gate.
# Laid again for Stage III (AR54, research's pick and second look of 2026-11-23): every spot is base_fit.PLAN's, held 12
# clear at each stage's footprints by part 7's tests and placed by what the game's camera sees from the gate. The yard
# is no longer the same on its two sides: the Door's side holds bays 1 and 2, the Training machine and the Forge; the
# Condenser stands at the back between the generator and the Breaker; bays 3 and 4 stand outside the Breaker, the
# battery and the Lab's stone behind it. The grounds and the lines to them are base_star.py's.
AVENUE = 20.0                      # the way in, clear from the gate to the generator
SPAWN = (0.0, 10.0)                # facing into the plot, the generator ahead
GENERATOR, ROW = star.GENERATOR, star.ROW   # the heart, and its line in from the front edge
RING, WELL, SLEEPS, LANE = star.RING, star.WELL, star.SLEEPS, star.LANE
BREAKER, DOOR, BATTERY, TRAINING = (star.spot(name) for name in ("breaker", "door", "battery", "training"))
LAB, CONDENSER, FORGE = (star.spot(name) for name in ("lab", "condenser", "forge"))
BAYS = [star.spot(f"bay{k}") for k in range(1, 7)]             # in the order they open
BAY_TURNS = [star.PLAN[f"bay{k}"][2] for k in range(1, 7)]     # the ring on the outer side: 0 on the Door's side, 180 on the Breaker's
DOOR_TURN = star.PLAN["door"][2]   # the Door's turn: its mouth looks down the way in
BAYS_AT = {1: 2, 2: 3, 3: 4}       # bays by the base's level (docs/design.md, "The base"); bays 5 and 6 stay locked at launch

# --- the yard ------------------------------------------------------------------------------------------------------------

COURT = (44.0, 32.0)   # the lit court at the front: half across, and how far in from the front edge
HALF = PLOT / 2        # the wall, across: the base is the whole plot (the director, 2026-11-15)
YARD = PLOT            # how far in the wall runs
BLOCK = 32.0           # a floor block behind the court: the yard's three, the heart's, the battery's and the sleeping three's
PYLON = (HALF - 4.5, 13.0)   # the pylons' line inside the side walls, and the first one's place in from the front: a
                             # span apart, each stands in a gap between two grounds of the outer column (AR54)
GATE = 22.0            # a gate tower's place, across
PLATE_UP = 21.6        # the gate's plate: its middle, up, on two posts over the truss: out of the gate's view from inside,
                       # read whole from the Strip (AR54, TR51's must-fix 1; research's pick of 2026-11-23). It was 16, on the truss
WING = 32.0            # where a front wall ends and the gate's shoulder begins: whole panels on to the corner
SPAN = 48.0            # from pylon to pylon
ARMS = ((16.5, 5.2), (20.0, 3.8))   # a pylon's arms: how high, and how far each reaches
HANG = 1.9             # an insulator's drop under its arm
EXIT = 8.0             # the way out at the back wall's middle, half its width: on to the Tower's path
FLOOD = (ROW - 16.6, 3.0, 12.0)   # a flood mast, one each side of the way in before the ring: in from the front; its head's reach toward the front, and its height.
# Laid again for AR54: each stands between the ring and where level 2's second ring will lie, 3.4 off the slant
# conduit's line. From the game's camera at the gate each stands before the generator's own flank (12.8 degrees off the
# middle line; the generator reaches 13.6), inside the Breaker's inner end at every stage (13.6 at Stage III, 16 at
# Stage I): measured on the handoff's meshes
COURT_GLOW = 1.0       # the court's glow picture's white, as emission strength (EmissiveStrength)
# The deck's sixteen floors, a grid over the plot: A to D across, from the Breaker's side wall to the Door's (left to
# right, seen from the gate), 1 to 4 from the gate in. Each: across from and to, inward from and to.
FLOOR_AT = {f"Floor{letter}{row}": (x0, x1, BLOCK * (row - 1), BLOCK * row)
            for letter, (x0, x1) in zip("ABCD", ((COURT[0], HALF), (0.0, COURT[0]), (-COURT[0], 0.0), (-HALF, -COURT[0])))
            for row in (1, 2, 3, 4)}
MAPS = {"Kit": ("#FFFFFF", kit.GLOW), **{name: ("#FFFFFF", COURT_GLOW) for name in FLOOR_AT}}   # each pair's tint and strength

# Swatches: the colour at the head, at the foot, and how much it glows. Pale concrete, the current in Power's yellow
# (the HUD's own), the Breaker's light in cyan. AR40's C, sandstone and teal (research's pick, 2026-11-18, 22:52, on the
# director's "too purple/black and somber"; tools/colour/ar40_directions.py): the void machines' stone is warm pale
# sand, their frames teal bronze, their fittings cream, the steel a pale sea grey, the trim violet, the far shards
# teal glass. The void's light (`void`, `cyan`) and the deck are as they were; the road's own light is `trail`. Before
# AR40: the stone a dark violet, navy frames.
SWATCHES = {
    "steel": ("#A9C2C8", "#62808A", 0.0), "girder": ("#46A39C", "#1F5E64", 0.0), "bone": ("#FFF4DC", "#C2AE8C", 0.0),
    "concrete": ("#C8CAD2", "#82858F", 0.0), "yellow": ("#FFD23E", "#B07A28", 0.05), "rubber": ("#2C2A44", "#181628", 0.0),
    "ceramic": ("#F4F0E8", "#A8A2B6", 0.0), "copper": ("#DE8E54", "#7C4630", 0.0), "power": ("#FFF6C4", "#FFD94A", 1.0),
    "cyan": ("#8CF6FF", "#3CC8E8", 1.0), "lamp": ("#F6FCFF", "#CDEEFF", 1.0), "beacon": ("#FF9A7A", "#FF6A52", 1.0),
    "dark": ("#5A4A9C", "#2A2258", 0.0), "ink": ("#0C0A16", "#0C0A16", 0.0),
    "void": ("#E9DBFF", "#A97CFF", 1.0), "abyss": ("#EEDDBC", "#B2946C", 0.0),   # the void machines': its light, its stone
    # the second row. The Festival Door's lines (AR15, section 7, take A): amber at the mouth, paler ring by ring
    "doormouth": ("#FF9038", "#FF9038", 1.0),
    "dawn": ("#FF9AD2", "#FF4FA6", 0.55),      # the Tower's own light, faint
    # The distance, painted in (AR20): with no haze to pale them, the far shards, the Tower asleep and the shards
    # breaking out beside the crossing stood as black cut-outs against the day sky, so each is lighter than a near
    # body, the farthest palest. AR40's must-fix on the director's "the map is a bit to purple ... that purple trail on
    # the road and crystal" (2026-11-19, 01:46): the crystals' bodies are C's deep teal glass, lit at the head as light
    # comes through glass, never violet; violet stays only in a small core or tip seen near (the outcrop's one shard of
    # light). Before: violet slate, #B8A8E0 to #8878BC, #A898D4 to #7868AE, #B0A0DC to #8070B8.
    "far": ("#8CC2C0", "#3E7A80", 0.0),        # the great shards past the map's edge (the Strip's FarShard pieces)
    "tower": ("#7AB4B4", "#336C74", 0.0),      # the Tower asleep, teal glass a step nearer
    "outcrop": ("#6AA6A8", "#28606A", 0.0),    # the Strip's ShardOutcrop, nearer, the deepest
    "doorarc1": ("#FFA448", "#FFA448", 1.0), "doorarc2": ("#FFB65C", "#FFB65C", 1.0),
    "doorarc3": ("#FFC977", "#FFC977", 1.0), "doorarc4": ("#FFDA98", "#FFDA98", 1.0),
    "doorcore": ("#FFCF7E", "#FF9A3C", 1.0),   # the core: its middle (the head) the palest, its rim (the foot) amber; gold
                                               # enough to hold its hue where the glow is full (a paler one burns white)
    # The Forge's field behind its gears: the void's foot one step dimmer, so from the court its head reads as one band,
    # not dark holes in bright lilac (AR36, research's pick of the court read, 2026-11-17)
    "voidfield": ("#A97CFF", "#A97CFF", 0.55),
    # A light's dark well (AR40, research's must-fix 1: a light on a pale body sits in a dark well, as a panel's bar sits
    # in its channel). Deep teal, one value head to foot, so two wells that meet never show a seam; the light stands a
    # hair proud of it. Never a body's colour: only the bed a line, a lamp or a ring of light sits in.
    "well": ("#1A353C", "#1A353C", 0.0),
    # The road's trail (AR40's must-fix, 2026-11-19, 01:46): the cracks of the void's power down the Strip and out to
    # each base's gate, its lamps and the crossing's light are a warm white in a dark bed (well), never violet, so they
    # read as power and not as paint. Its head is the main line's, its foot the branches', dimmer and warmer, about 2 to
    # 1 in light. The thin teal edge between the light and its bed glows a little, cooler than the light.
    "trail": ("#FFF8EA", "#DDB078", 1.0),
    "trailedge": ("#8FC4C8", "#5FA0A6", 0.5),
}
SWATCH_AT = {name: ((i % 16) * CELL[0], (i // 16) * CELL[1]) for i, name in enumerate(SWATCHES)}
# The wall's print, its darkest and its lightest: drawn on its old ramp (WALL_FROM) and moved along it to AR40's C
# channel by channel, as research saw it in AR40's renders (ar40_directions.py, C's "Panel"): sand, not indigo.
WALL_FROM, WALL = ("#20263E", "#93A0C8"), ("#8A6E4E", "#F0E2C4")
# Prints: where each sits (x, y, width, height), each with a 4 pixel bleed round it.
PRINTS = {"panel": (8, 268, 512, 160), "hazard": (536, 268, 256, 48), "plate": (536, 332, 256, 112)}
PRINTS["half"] = (8, 268, 256, 160)   # the panel's first 8 studs, for the half panel: the same pixels, not drawn again
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
    lo0, hi0, lo1, hi1 = (code(c) for c in WALL_FROM + WALL)     # AR40's C: the same print moved along its ramp
    rgb[..., :3] = np.clip(lo1 + (rgb[..., :3] - lo0) / (hi0 - lo0) * (hi1 - lo1), 0, 1)
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
    return page, glow


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


def deck(x, y, px):
    """The plot's own deck plates under a floor's field: one sheet of plates over the whole plot, so a plate that
    crosses two floors is one plate. `x` is across from the middle line, `y` in from the front edge."""
    rng = np.random.default_rng(31)
    a, b = code(DECK_TONES[0]), code(DECK_TONES[1])
    n = int(PLOT / PLATE) + 1
    k = rng.uniform(0.0, 1.0, (n, n)).astype(np.float32)[(y // PLATE).astype(int), ((x + HALF) // PLATE).astype(int)][..., None]
    page = np.ones((*x.shape, 4), np.float32)
    page[..., :3] = a * (1 - k) + b * k
    fx, fy = (x + HALF) % PLATE, y % PLATE
    near = np.minimum(np.minimum(fx, PLATE - fx), np.minimum(fy, PLATE - fy))
    _mix(page, DECK_TONES[3], ((np.minimum(fx, fy) < 3.2 * px) & (near >= 1.2 * px)).astype(np.float32) * 0.45)
    _mix(page, DECK_TONES[2], np.clip(1.7 - near / px, 0, 1))
    bolt = np.hypot(np.minimum(fx, PLATE - fx) - 0.42, np.minimum(fy, PLATE - fy) - 0.42)
    _mix(page, DECK_TONES[2], np.clip((0.12 - bolt) / px + 0.5, 0, 1) * 0.8)
    return page


def conduits(page, glow, x, y, px, live=(), dead=(), arcs=()):
    """The conduits in a floor's picture: a dark casing with a clamp every plate, and in a live one the current, a
    bright core with its halo. A run is two ends, at any slant. An arc is live: its middle, its radius, and the two
    turns it runs between, in degrees from the way toward the gate round by the Breaker's side (so the Door's side is
    below zero). A junction sits on each live end. A run or an arc that doesn't reach this field isn't drawn."""
    band = _band(px)
    laid = dict(casing=np.zeros_like(glow), core=np.zeros_like(glow), halo=np.zeros_like(glow))
    x0, x1, y0, y1 = float(x.min()) - 8.0, float(x.max()) + 8.0, float(y.min()) - 8.0, float(y.max()) + 8.0

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

    for lit, runs_ in ((True, live), (False, dead)):
        for (ax, ay), (bx, by) in runs_:
            if max(ax, bx) < x0 or min(ax, bx) > x1 or max(ay, by) < y0 or min(ay, by) > y1:
                continue
            length = math.hypot(bx - ax, by - ay)
            ux, uy = (bx - ax) / length, (by - ay) / length
            along, off = (x - ax) * ux + (y - ay) * uy, (y - ay) * ux - (x - ax) * uy
            lay(np.hypot(off, along - np.clip(along, 0.0, length)), along, lit)
            if lit:
                junction(ax, ay)
                junction(bx, by)
    for (cx, cy), radius, start, end in arcs:
        if cx + radius < x0 or cx - radius > x1 or cy + radius < y0 or cy - radius > y1:
            continue
        turn = np.degrees(np.arctan2(x - cx, cy - y))
        held = np.radians(np.clip(turn, start, end))
        lay(np.hypot(x - (cx + radius * np.sin(held)), y - (cy - radius * np.cos(held))), np.radians(turn) * radius, True)
        for at in (start, end):
            junction(cx + radius * math.sin(math.radians(at)), cy - radius * math.cos(math.radians(at)))
    _mix(page, "#141724", laid["casing"])
    _mix(page, "#FFF1A8", laid["core"])
    return np.maximum(glow + 0.3 * laid["halo"] * (1 - laid["casing"]), laid["core"])


def ring_arcs():
    """The ring of current round the well, its two halves: each from its open end, on the slant to the Breaker's
    ground or the Door's, round to the main line at its back. It stays open toward the gate, the way in running into
    it."""
    return [(GENERATOR, RING, 45.0, 180.0), (GENERATOR, RING, -180.0, -45.0)]


def runs():
    """The conduits' straight runs, each across and in: the live ones and the ones with no current yet. The well's
    rim is linked to the ring on each side and at its back; every place's line is the star's (base_star.lines); and
    the main line runs on, dormant, from the last sleeping bay to the way out at the back wall."""
    gx = GENERATOR[0]
    live = [((gx + side * (WELL + 0.6), ROW), (gx + side * RING, ROW)) for side in (-1, 1)]
    live.append(((gx, ROW + WELL + 0.6), (gx, ROW + RING)))
    dead = [((gx, star.ground("bay5")[3]), (gx, YARD + 2.0))]
    for line in star.lines().values():
        (live if line["live"] else dead).append((line["a"], line["b"]))
    return live, dead


def asleep(page, x, y, px, at):
    """A sleeping place's ground: a darker square inside a grey frame, heavy at its corners. Nothing in it is lit."""
    band = _band(px)
    dx, dy = np.abs(x - at[0]), np.abs(y - at[1])
    box = np.maximum(dx, dy)
    corner = (np.minimum(dx, dy) > SLEEPS - 2.6).astype(np.float32)
    page[..., :3] *= (1.0 - 0.22 * np.clip((SLEEPS - box) / px + 0.5, 0, 1))[..., None]
    _mix(page, "#7A84A6", np.maximum(band(box - SLEEPS, 0.1), band(box - SLEEPS, 0.28) * corner) * 0.6)


def pools(x, y):
    """The soft light on the deck round the heart: the well's, the Breaker's ground's, and the floods'. `y` is studs in
    from the plot's front edge."""
    bx0, bx1, by0, by1 = star.ground("breaker")
    return (0.22 * np.exp(-(np.hypot(x - GENERATOR[0], y - ROW) / 14.0) ** 2)
            + 0.3 * np.exp(-((x - (bx0 + bx1) / 2) ** 2 / 16.0 ** 2 + (y - (by0 + by1) / 2) ** 2 / 9.0 ** 2))
            + 0.3 * np.exp(-((np.abs(x) - flood_across()) ** 2 + (y - (FLOOD[0] - FLOOD[1])) ** 2) / 9.0 ** 2))


def well(page, glow, x, y, px):
    """The generator's ground: a well, the void under the plant's heart. Dark, a few far lights in it, a rim of the
    void's own violet inside Power's yellow: the one place the yard shows what its power is drawn from."""
    band = _band(px)
    gx = GENERATOR[0]
    r = np.hypot(x - gx, y - ROW)
    inside = np.clip((WELL - r) / px + 0.5, 0, 1)
    if not inside.any():
        return glow, inside
    page[..., :3] = page[..., :3] * (1 - inside[..., None]) + code("#0A0816") * inside[..., None]
    glow = glow * (1 - inside)
    rng = np.random.default_rng(72)
    for _ in range(int(0.92 * WELL ** 2)):
        a, q = rng.uniform(0, 2 * np.pi), (WELL - 1.2) * np.sqrt(rng.uniform(0.15, 1.0))
        far = band(np.hypot(x - (gx + q * np.sin(a)), y - (ROW + q * np.cos(a))), float(rng.choice((0.07, 0.07, 0.11))))
        _mix(page, "#E8DCFF", far)
        glow += 0.7 * far
    _mix(page, "#B98CFF", band(r - (WELL - 0.5), 0.16))
    _mix(page, "#FFD23E", band(r - WELL, 0.14))
    return glow + 0.6 * band(r - (WELL - 0.5), 0.16) + 0.5 * band(r - WELL, 0.14), inside


def flood_across():
    """A flood mast's place across: just outside the way in, its foot clear of the way's 20 studs."""
    return AVENUE / 2 + 1.8


def pad(page, glow, x, y, px, box, line, lit=0.45):
    """A machine's ground: a darker dais inside a line of its own colour. `box`: across from and to, in from and to."""
    band = _band(px)
    x0, x1, y0, y1 = box
    out = np.maximum(np.abs(x - (x0 + x1) / 2) - (x1 - x0) / 2, np.abs(y - (y0 + y1) / 2) - (y1 - y0) / 2)
    page[..., :3] *= (1.0 - 0.3 * np.clip(-out / px + 0.5, 0, 1))[..., None]
    _mix(page, line, band(out, 0.12))
    return glow + lit * band(out, 0.12)


def bay_frame(page, glow, x, y, px, at):
    """An open bay's ground: a frame of Power's yellow round its pad, heavy at its corners, lit."""
    band = _band(px)
    dx, dy = np.abs(x - at[0]), np.abs(y - at[1])
    box = np.maximum(dx, dy)
    corner = (np.minimum(dx, dy) > 3.6).astype(np.float32)
    frame = np.maximum(band(box - SLEEPS, 0.12), band(box - SLEEPS, 0.3) * corner)
    page[..., :3] *= (1.0 - 0.3 * np.clip((SLEEPS - box) / px + 0.5, 0, 1))[..., None]
    _mix(page, "#FFD23E", frame)
    return glow + 0.4 * frame + 0.16 * np.exp(-((x - at[0]) ** 2 + (y - at[1]) ** 2) / 8.0 ** 2)


def way_in(page, x, y, px):
    """The way in: a pale dashed line down each of its edges, from the gate to the ring's open ends."""
    reach = ROW - RING * math.sqrt(0.5) - 2.0
    _mix(page, "#D4DCEE", _band(px)(np.abs(x) - LANE, 0.11) * ((y % 4.0) < 2.0) * (y > 3.0) * (y < reach) * 0.45)


GROUNDS = (("breaker", "#BFEFF5", 0.45), ("door", "#BFEFF5", 0.45), ("battery", "#D4DCEE", 0.3),
           ("training", "#D4DCEE", 0.3), ("forge", "#D4DCEE", 0.3), ("condenser", "#D4DCEE", 0.3))   # each line's colour, and its glow


def box_mark(page, x, y, px, at):
    """A junction box on a live line: dark, in a rim of Power's yellow, a lamp at its middle. Its glow."""
    band = _band(px)
    e = np.maximum(np.abs(x - at[0]), np.abs(y - at[1]))
    rim, lamp = band(e, 1.5) * (1 - band(e, 1.15)), band(np.hypot(x - at[0], y - at[1]), 0.5)
    _mix(page, "#141724", band(e, 1.5))
    _mix(page, "#FFD23E", rim)
    _mix(page, "#FFF1A8", lamp)
    return lamp + 0.3 * rim


def marks(page, glow, x, y, px):
    """Everything the layout draws on the deck, in the plot's own studs: `x` across from the middle line, `y` in from
    the front edge. A floor's picture shows whatever of it falls on that floor, so a place that moves takes its marks
    with it: each machine's ground, each open bay's frame, each sleeping place's, the conduits and the ring, the box
    where the main line leaves the ring's back, the node where the Training machine's line leaves bay 2's, the well and
    the pools."""
    for name, line, lit in GROUNDS:
        glow = pad(page, glow, x, y, px, star.ground(name), line, lit)
    for name in star.OPEN:
        glow = bay_frame(page, glow, x, y, px, star.spot(name))
    for name in star.LATER + ("lab",):
        asleep(page, x, y, px, star.spot(name))
    live, dead = runs()
    glow = conduits(page, glow, x, y, px, live=live, dead=dead, arcs=ring_arcs())
    glow = glow + box_mark(page, x, y, px, star.node())
    glow = glow + box_mark(page, x, y, px, (GENERATOR[0], ROW + RING))
    glow, inside = well(page, glow, x, y, px)
    return glow + pools(x, y) * (1 - inside)


def grounded(x, y):
    """Where a ground lies, a machine's or a bay's: the deck's own lines stop at its edge."""
    inside = np.zeros(x.shape, bool)
    for name in star.MACHINES + star.FRAMED:
        x0, x1, y0, y1 = star.ground(name)
        inside |= (x > x0) & (x < x1) & (y > y0) & (y < y1)
    return inside.astype(np.float32)


def floor_pictures(name):
    """A floor's pair of pictures, the colour and the glow: its own ground of the plot, across from the picture's left
    to its right and in from the front edge down it. The deck's plates; the wall's foot along each side wall; a joint
    across each block's far edge; the threshold under the gate and the ring where a player arrives; the way in; and
    the layout's marks."""
    x0, x1, y0, y1 = FLOOR_AT[name]
    rows, cols = 512, (1024 if x1 - x0 > BLOCK else 512)   # 16 px a stud in, 23 or more across: the sixteen hold
    # fewer pixels than the seven mirrored floors did (12.6 million against 14.7), and no axis under 16 a stud (it was 11.6)
    yy, xx = np.mgrid[0:rows, 0:cols].astype(np.float32)
    x, y = x0 + (xx + 0.5) / cols * (x1 - x0), y0 + (yy + 0.5) / rows * (y1 - y0)
    px = ((x1 - x0) / cols + (y1 - y0) / rows) / 2
    band = _band(px)
    page = deck(x, y, px)
    glow = np.zeros((rows, cols), np.float32)
    # the wall's foot, along each side wall: a darker margin inside a pale line
    foot = HALF - 3.0
    page[..., :3] *= (1.0 - 0.38 * np.clip((np.abs(x) - foot) / px + 0.5, 0, 1))[..., None]
    _mix(page, "#C9D2E6", band(np.abs(x) - foot, 0.09) * 0.6)
    # the joint across each block's far edge, behind the court: where one block of the yard ends
    far = BLOCK - (y % BLOCK)
    free = 1.0 - grounded(x, y)
    joint = ((np.abs(x) < foot) & ((y > BLOCK) | (np.abs(x) > COURT[0]))).astype(np.float32) * free
    _mix(page, "#252B44", band(far - 0.2, 0.2) * joint)
    _mix(page, "#C9D2E6", band(far - 0.55, 0.07) * joint * 0.5)
    # the court's own line down each of its sides: the deck runs on past it into the outer columns
    _mix(page, "#C9D2E6", band(np.abs(x) - (COURT[0] - 0.4), 0.09) * (y < COURT[1]) * free * 0.6)
    # the threshold under the gate, between its towers' feet: hazard on the slant
    sill = (band(y - 0.9, 0.7) * (np.abs(x) < GATE - 2.6)).astype(np.float32)
    stripe = (((np.abs(x) + y) // 0.9) % 2).astype(np.float32)
    _mix(page, "#FFD23E", sill * (1 - stripe))
    _mix(page, "#1F2233", sill * stripe)
    way_in(page, x, y, px)
    # where the player arrives: a ring on the deck
    r = np.hypot(x - SPAWN[0], y - SPAWN[1])
    ring = np.maximum(band(r - 4.2, 0.14), band(r - 3.2, 0.06))
    _mix(page, "#E9E2D2", ring * 0.9)
    glow += 0.25 * ring
    return page, grey(marks(page, glow, x, y, px))


FLOORS = {name: (lambda name=name: floor_pictures(name)) for name in FLOOR_AT}


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


def floor(name):
    def make():
        """A floor of the deck's grid: a flat face its ground's size, its front edge at the piece's place and its
        middle on it, in its own pair of pictures."""
        x0, x1, y0, y1 = FLOOR_AT[name]
        half, deep = (x1 - x0) / 2, y1 - y0
        m = Mesh(None)
        m.face([Vector((-half, -deep, 0.06)), Vector((half, -deep, 0.06)), Vector((half, 0, 0.06)), Vector((-half, 0, 0.06))],
               [(0, 0), (1, 0), (1, 1), (0, 1)])
        return Piece(name, m, maps=name, solid="floor",
                     note=f"lies 0.06 over the deck, {2 * half:g} studs across by {deep:g} in, its front edge at its "
                          f"place; a Part under it carries the walking. A floor's look: its glow turns with the night")
    return make


def wall_line(m, run, at):
    """A wall's line of light under its coping, `run` along X, in a dark band a little taller (AR40)."""
    m.box((run, 0.58, 0.14), at, "power")
    m.box((run - 0.02, 0.54, 0.4), at, "well")


def wall(run=16.0):
    """The yard's wall: a post on a concrete foot with a lamp on its cap, and a ribbed steel panel 16 studs along +X
    to the next post, a line of light under its bone coping. The half panel runs 8, to close a run that isn't whole
    panels: at 128, the back wall at its way out. A run's last post is the same without the panel."""
    m = Mesh()
    m.box((2.0, 2.0, 1.2), (0, 0, 0.6), "concrete", ink=True)
    m.box((1.1, 1.1, 5.4), (0, 0, 3.9), "girder", ink=True)
    m.box((1.5, 1.5, 0.4), (0, 0, 6.8), "yellow")
    m.box((0.6, 0.6, 0.5), (0, 0, 7.25), "power")
    m.box((0.8, 0.8, 0.1), (0, 0, 7.05), "well")                                      # the lamp's dark collar (AR40)
    if run:
        panel, coping, print_ = {16.0: (14.9, 15.2, "panel"), 8.0: (6.9, 7.2, "half")}[run]
        m.box((panel, 1.0, 1.0), (run / 2, 0, 0.5), "concrete", ink=True)
        m.box((panel, 0.5, 3.6), (run / 2, 0, 2.8), "steel", pics={"+y": print_, "-y": print_}, ink=True)
        wall_line(m, panel, (run / 2, 0, 4.72))
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
        machines.lamp(m, (0.16, 1.0, 8.6), (x - side * 1.34, 0, 9.6), "power", 0, -side, pad=0.2)   # a strip of light down the inner face, in its dark bed
        m.box((3.2, 3.2, 0.5), (x, 0, 17.65), "bone", ink=True)
        insulator(m, (x, 0, 17.9), 2.2, r=0.55)
        m.box((0.5, 0.5, 0.5), (x, 0, 20.35), "beacon")
        m.box((0.6, 0.6, 0.1), (x, 0, 20.15), "well")                                 # the beacon's dark collar (AR40)
        mid, reach = side * (GATE + 2.3 + WING) / 2, WING - GATE - 2.3
        m.box((reach, 1.0, 1.0), (mid, 0, 0.5), "concrete")
        m.box((reach, 0.5, 3.6), (mid, 0, 2.8), "steel")
        wall_line(m, reach, (mid, 0, 4.72))
        m.box((reach, 0.8, 0.3), (mid, 0, 4.95), "bone")
    span = 2 * GATE - 2.6
    for z in (15.0, 17.0):
        for y in (-0.8, 0.8):
            m.box((span, 0.36, 0.36), (0, y, z), "steel")
    for y in (-0.8, 0.8):
        m.tube([(-span / 2 + span * i / 10, y, 15.0 if i % 2 == 0 else 17.0) for i in range(11)], 0.13, "steel")
    m.box((11.0, 2.2, 4.4), (0, 0, PLATE_UP), "rubber", pics={"+y": "plate", "-y": "plate"}, ink=True)
    if PLATE_UP - 2.2 > 17.0:                                       # raised over the truss: two posts carry it
        for x in (-4.2, 4.2):
            m.box((0.5, 0.5, PLATE_UP - 2.2 - 17.0), (x, 0, (PLATE_UP - 2.2 + 17.0) / 2), "girder", ink=True)
    for x in (-13.0, 13.0):
        m.box((2.0, 1.3, 0.7), (x, 0, 14.45), "girder", ink=True)
        m.box((1.6, 0.9, 0.12), (x, 0, 14.05), "lamp")
    return Piece("Gate1", m, solid="a box round each tower's foot, 4.6 square, and the two shoulders as walls",
                 note="clear between the towers' feet: 39.4 studs, 14 under the floods; the plate's faces are +Y and "
                      f"-Y, 11 by 4.4 at {PLATE_UP:g} up: the base's level is the builder's text on both")


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
        m.box((0.4, 0.4, 0.1), (x, 0, 4.89), "well")                                  # each tip's dark collar (AR40)
    return Piece("Transformer", m, solid="a box, 3.6 by 3 by 3.4")


PIECES = {**{name: floor(name) for name in FLOOR_AT}, "Wall": wall, "WallHalf": lambda: wall(8.0),
          "WallEnd": lambda: wall(0.0), "Gate1": gate, "Pylon": pylon,
          "PowerSpan": power_span, "FloodMast": flood_mast, "Transformer": transformer,
          **machines.PIECES,       # and the machines' own models (AR15, base_machines.py)
          **mill.PIECES,           # and the generator, the Void Mill (AR19, base_mill.py)
          **show.PIECES,           # and the showcase's plinth (TR22, base_show.py)
          **forge.PIECES,          # and the Forge and the Stone Condenser, Stage I (AR28, base_forge.py)
          **breaker.PIECES,        # and the Void Breaker's Stages II and III (AR32, base_breaker.py)
          **bays.PIECES,           # and the bays' Stages II and III (AR33, base_bay.py)
          **battery.PIECES,        # and the battery's Stages II and III (AR34, base_battery.py)
          **training.PIECES,       # and the Training machine's Stages II and III (AR35, base_training.py)
          **forge_stages.PIECES,   # and the Forge's and the Condenser's Stages II and III (AR36, base_forge_stages.py)
          **levels.PIECES}         # and what the yard gains at base levels 2 and 3 (AR50, base_levels.py)


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
    write_pictures(folders["maps"])   # after the meshes: a machine's ground is drawn from its own footprint (base_star.py)
    manifest = dict(
        what="AR14: the base's own kit, a power yard. Made and laid as Lantern Row's kit is.",
        unit="1 = 1 stud",
        frame="Roblox's: a piece's front (Blender +Y) is -Z. A MeshPart goes at the piece's place times `centre`. "
              "A light's `at` is in the piece's own frame.",
        surface="one SurfaceAppearance per MeshPart: ColorMap `colour`, EmissiveMaskContent `glow`, EmissiveTint "
                "`glowTint`, EmissiveStrength from `glowStrength` (tuned in the engine). Single sided: each piece's ink "
                "is in its mesh, a hull turned inside out on the atlas's ink texel.",
        ink=f"the drawn edge is a hull {ink.INK:g} studs out (base_ink.py); Lantern Row's is {ink.SHARED:g}",
        shadows="CastShadow off on PowerSpan and the sixteen floors (every piece named Floor: FloorA1 to FloorD4), "
                "and on the light laid on the deck (LevelFloor, LevelRays, BayWake3, BayWake4).",
        floors="the deck's look is a grid of sixteen floors over the plot, each in its own pair of pictures: A to D "
               "across from the Breaker's side wall to the Door's (left to right, seen from the gate), 1 to 4 from the "
               "gate in. A and D are 20 studs across, B and C 44, each 32 in. They replace Court1, Yard, YardLive, "
               "YardBack, Wings, WingsLive and WingsBack (AR54): the yard isn't the same on its two sides, so no "
               "picture is mirrored.",
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
