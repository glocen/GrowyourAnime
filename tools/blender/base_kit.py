"""AR14: the base's own kit (docs/asset-requests.md), made simpler by AR65 (research's pick of 2026-11-26, target A,
`build/handoff/Base/ar65_targets/`): graphite machines on pale warm stone, each machine told apart by its shape and one
accent of its own, a warm grey panel wall, a gate on the Strip that carries the base's level. The pylons, the flood
masts and the transformers are still made here; the builder leaves them out of the yard (Config.World.Cut).

Made as Lantern Row's kit is (lantern_row_kit.py: its mesh builder, its swatch atlas, its ink hull, its manifest), on
pictures of its own, so the builder's Kit.Place and its upload take it unchanged. A piece's front faces +Y, toward the
Strip; its origin is on the floor; one unit is one stud.

The deck's look is sixteen floor pieces, a grid of four by four over the plot, each with its own pair of pictures: the
stone's slabs, one calm tone from the gate, the ring where a player arrives and the Mill's well. The yard isn't the
same on its two sides (AR54), so no picture is mirrored: each is drawn for its own ground.

Each machine wears its own copy of the atlas, at half its size (WEARS): the same cells, its accent on its frames and
its lights, so no mesh changes when a colour does.

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
import base_generator as generator  # noqa: E402
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
MAPS = {"Kit": ("#FFFFFF", kit.GLOW), **{name: ("#FFFFFF", kit.GLOW) for name in ("Mill", "Breaker", "Bay", "Training",
       "Condenser", "Door", "Yard")}, **{name: ("#FFFFFF", COURT_GLOW) for name in FLOOR_AT}}   # each pair's tint and strength

# Swatches: the colour at the head, at the foot, and how much it glows. Pale concrete, the current in Power's yellow
# (the HUD's own), the Breaker's light in cyan. AR40's C, sandstone and teal (research's pick, 2026-11-18, 22:52, on the
# director's "too purple/black and somber"; tools/colour/ar40_directions.py): the void machines' stone is warm pale
# sand, their frames teal bronze, their fittings cream, the steel a pale sea grey, the trim violet, the far shards
# teal glass. The void's light (`void`, `cyan`) and the deck are as they were; the road's own light is `trail`. Before
# AR40: the stone a dark violet, navy frames.
# AR65 (research's pick in pairs of 2026-11-26, target A, `build/handoff/Base/ar65_targets/`): the machines' shared
# neutrals are style frame A's graphite (AR62), the stone a pale warm grey, and the colour each machine owns is its own
# copy of this atlas (WEARS, below). Before AR65: steel a pale sea grey, girder teal bronze, bone cream, concrete a cool
# pale grey, dark violet, abyss warm sand, well deep teal.
SWATCHES = {
    "steel": ("#8C929C", "#555A63", 0.0), "girder": ("#4A4F5A", "#2A2D34", 0.0), "bone": ("#6B717D", "#454A55", 0.0),
    "concrete": ("#D6D1C7", "#9A958B", 0.0), "yellow": ("#FFD23E", "#B07A28", 0.05), "rubber": ("#2C2A44", "#181628", 0.0),
    "ceramic": ("#F4F0E8", "#A8A2B6", 0.0), "copper": ("#DE8E54", "#7C4630", 0.0), "power": ("#FFF6C4", "#FFD94A", 1.0),
    "cyan": ("#8CF6FF", "#3CC8E8", 1.0), "lamp": ("#F6FCFF", "#CDEEFF", 1.0), "beacon": ("#FF9A7A", "#FF6A52", 1.0),
    "dark": ("#2C2E35", "#1C1D22", 0.0), "ink": ("#0C0A16", "#0C0A16", 0.0),
    "void": ("#E9DBFF", "#A97CFF", 1.0), "abyss": ("#4E535E", "#2F3239", 0.0),   # the void machines': its light, its stone
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
    "well": ("#16171B", "#16171B", 0.0),
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
WALL_FROM, WALL = ("#20263E", "#93A0C8"), ("#77736B", "#C4BFB5")   # AR65: a warm grey under the pale stone (it was sand)
# Prints: where each sits (x, y, width, height), each with a 4 pixel bleed round it.
PRINTS = {"panel": (8, 268, 512, 160), "hazard": (536, 268, 256, 48), "plate": (536, 332, 256, 112)}
PRINTS["half"] = (8, 268, 256, 160)   # the panel's first 8 studs, for the half panel: the same pixels, not drawn again
DECK = (512, 8.0)      # the deck's own tile: pixels, and the studs it covers (four plates)
PLATE = 4.0            # a deck plate, studs
# AR65's floor: warm stone in slabs (research's must-fix 1: stone, never a bare baseplate). A slab's two tones, its
# joint, the lit lip on its near edges; a slab across and in, studs, each course offset by half a slab. Research's gate
# (2026-11-26, 18:55): open floor from installed_day's camera, x 40 to 300 and y 360 to 420 of 852 x 480, Rec. 709 mean
# 206 +-8, detail at least 2.0. Measured there (Faber's captures): maps at a mean of 210 read 235, at 176.5 read 219.7,
# at 135 read 182.0 (the game's tone curve bends: flat near white, steep lower). Read between the last two, the maps sit
# at 160, a slab's step 33. The game warms the floor (a map's R/G of 1.01 reads 1.06), so the stone is drawn near
# neutral, R/G 0.99 and B/G 0.98, to read as target A's 1.02 and 0.95. Before: "#969490", "#7A7874", "#6E6C67",
# "#9D9C99"; "#BCB9B1", "#AEA9A1", "#959087", "#C3C1BB"; first "#DCD8CF", "#D4CFC5", "#B3ADA2", "#E9E6DF".
STONE = ("#AEB0AD", "#8D8F8C", "#7F807E", "#B8BAB6")
MOTTLE = 0.01
SLAB = (8.0, 4.0)

# Each machine's own colour (AR65, the feel line: "every machine told apart by its shape and its one colour"): a copy of
# the atlas at half its size, the same cells, so a mesh's corners point where they did and no mesh changes. On a
# machine, the frames (girder) take its accent, and every light (void, cyan, power, lamp, beacon) its accent lit, so
# it glows in one colour; its yellow trim goes to the fittings' graphite. No two machines share an accent. The Door
# keeps its gold and wears its own copy for its rim's glow alone, a step down (research's must-fix 3: its rim at dusk
# stays under the Mill's glow); its core keeps the builder's own cap (Config.Lighting.Glow.CoreBloom). The wall, the
# gate and its fins wear the yard's copy: their lamps and their gold unlit, so nothing round the yard glows but the
# gate's plate (AR65: "nothing glowing but what calls you"). Left on the shared atlas: what the builder tints (BayHalo,
# CondenserJewel), the void's stones in the Condenser's cups, the light laid on the deck, and what's out of the yard
# at launch (the Forge, the battery, the grid).
WEARS = {
    "Mill": "#33D6E6",        # the Void Mill (the generator), the landmark
    "Breaker": "#B784FF",     # the Void Breaker: violet, what's alive and for sale (AR62)
    "Bay": "#FF7A59",
    "Training": "#5EDB72",
    "Condenser": "#5C86FF",
    "Door": None,
    "Yard": None,             # the wall and the gate
}
DOOR_GLOW = 0.4           # the Door's rim's glow against the kit's: its mouth's line and its rings' arcs
WEAR_PX = 512             # a wear's atlas: half the shared one's 1024


def wear_of(name):
    """The wear a piece of the base takes: a machine's own, or the shared atlas ("Kit")."""
    if name.startswith("Generator"):
        return "Mill"
    if name.startswith("Breaker"):
        return "Breaker"
    if name in ("Bay", "Bay2", "Bay3", "BayCog", "BayCogOuter", "BaySleeping"):
        return "Bay"
    if name.startswith("Training"):
        return "Training"
    if name in ("Condenser", "Condenser2", "Condenser3", "CondenserCore"):
        return "Condenser"
    if name.startswith("Door"):
        return "Door"
    if name in ("Wall", "WallHalf", "WallEnd", "Gate1", "LevelFin", "LevelFinOuter"):   # the fins: the gate's own make
        return "Yard"
    return "Kit"


def mix_hex(colour, toward, k):
    """A colour `k` of the way to another, as a hex code."""
    a, b = code(colour), code(toward)
    return "#" + "".join(f"{round(float(v) * 255):02X}" for v in (a * (1 - k) + b * k))


def swatches_of(wear):
    """The swatches a wear paints its copy of the atlas with: the shared ones, its accent laid over."""
    out = dict(SWATCHES)
    if wear == "Door":
        for name in ("doormouth", "doorarc1", "doorarc2", "doorarc3", "doorarc4"):
            top, bottom, lit = out[name]
            out[name] = (top, bottom, lit * DOOR_GLOW)
        return out
    if wear == "Yard":
        for name in ("power", "lamp", "beacon"):
            out[name] = ("#F3EEE4", "#CFC9BD", 0.0)
        out["yellow"] = SWATCHES["bone"]
        return out
    acc = WEARS[wear]
    out["girder"] = (acc, mix_hex(acc, "#1C1D22", 0.5), 0.0)
    for name in ("void", "cyan", "power", "lamp", "beacon"):
        out[name] = (mix_hex(acc, "#FFFFFF", 0.55), acc, 1.0)
    out["yellow"] = SWATCHES["bone"]
    return out


def wear():
    """The mesh builder reads its atlas from the kit's module: the base's pieces wear the base's."""
    kit.SWATCHES, kit.SWATCH_AT, kit.PRINTS = SWATCHES, SWATCH_AT, PRINTS


# --- the pictures ----------------------------------------------------------------------------------------------------

def _mix(page, colour, amount):
    page[..., :3] = page[..., :3] * (1 - amount[..., None]) + code(colour) * amount[..., None]


def atlas(swatches=None):
    """The kit's colour picture and its glow picture, as sRGB-coded arrays: the shared swatches, or a wear's."""
    swatches = swatches or SWATCHES
    page = np.zeros((A, A, 4), np.float32)
    page[..., :3], page[..., 3] = code("#181D32"), 1.0
    glow = np.zeros((A, A), np.float32)
    t = np.linspace(0, 1, CELL[1], dtype=np.float32)[:, None, None] ** 0.85   # down the cell: head to foot
    shade = 1.0 - 0.5 * np.clip((np.arange(CELL[0], dtype=np.float32) - 8) / 48, 0, 1)[None, :, None]
    for name, (top, bottom, lit) in swatches.items():
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
    # a tower's collar: plain graphite, a pale line at its head (AR65 cut the hazard's yellow and black, a building
    # site's mark)
    x, y, w, h = PRINTS["hazard"]
    yy = np.mgrid[0:h, 0:w][0].astype(np.float32)
    rgb = np.empty((h, w, 3), np.float32)
    rgb[...] = code(SWATCHES["bone"][1])
    rgb[yy < 4] = code(SWATCHES["bone"][0])
    kit._put(page, glow, rgb, x, y)
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


def stone(x, y, px, tile=False):
    """AR65's floor: warm stone in slabs, at target A's value. `x` is across from the middle line, `y` in from the front
    edge, so a slab that crosses two floors is one slab. Each slab its own tone, a step apart; a thin joint a hair
    darker, with a lit lip on its near edges; a faint mottle over all. Read close, the joints and the tones say stone;
    by the gate's distance the joints melt, and the slabs' tone steps still show (research's must-fix 1, in game).
    `tile`: the deck's tile, `DECK` studs square, repeating: its two courses' tones and its mottle repeat with it."""
    rng = np.random.default_rng(31)
    a, b = code(STONE[0]), code(STONE[1])
    course = np.floor(y / SLAB[1]).astype(int)
    xs = x + HALF + (course % 2) * SLAB[0] / 2
    col = np.floor(xs / SLAB[0]).astype(int)
    tones = rng.uniform(0.0, 1.0, (int(PLOT / SLAB[1]) + 2, int(PLOT / SLAB[0]) + 3)).astype(np.float32)
    k = (tones[course % 2, col % 1] if tile else tones[course, col])[..., None]
    page = np.ones((*x.shape, 4), np.float32)
    page[..., :3] = a * (1 - k) + b * k
    waves = rng.uniform((0.15, 0.15, 0, 0), (0.6, 0.6, 6.3, 6.3), (4, 4))
    if tile:   # whole waves across the tile
        waves[:, :2] = np.maximum(1, np.round(waves[:, :2] * DECK[1] / (2 * np.pi))) * 2 * np.pi / DECK[1]
    mottle = sum(np.sin(x * f + p) * np.sin(y * g + q) for f, g, p, q in waves)
    page[..., :3] *= (1.0 + MOTTLE * mottle)[..., None]
    fx, fy = xs % SLAB[0], y % SLAB[1]
    near = np.minimum(np.minimum(fx, SLAB[0] - fx), np.minimum(fy, SLAB[1] - fy))
    _mix(page, STONE[3], ((np.minimum(fx, fy) < 2.2 * px) & (near >= 1.0 * px)).astype(np.float32) * 0.5)
    _mix(page, STONE[2], np.clip(1.4 - near / px, 0, 1) * 0.6)
    return page


def deck_tile():
    """The plain stone, a tile `DECK` studs square, for a Texture on a Part."""
    n = DECK[0]
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    px = DECK[1] / n
    return stone((xx + 0.5) * px - HALF, (yy + 0.5) * px, px, tile=True)


def _band(px):
    return lambda dist, reach: np.clip((reach - np.abs(dist)) / px + 0.5, 0, 1)


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


def well(page, glow, x, y, px):
    """The generator's ground: a well, the void under the plant's heart. Dark graphite, a few far lights in it, and one
    rim in the Mill's own cyan (AR65: one glow a machine, the Mill's its own; it was violet inside Power's yellow)."""
    band = _band(px)
    gx = GENERATOR[0]
    r = np.hypot(x - gx, y - ROW)
    inside = np.clip((WELL - r) / px + 0.5, 0, 1)
    if not inside.any():
        return glow, inside
    page[..., :3] = page[..., :3] * (1 - inside[..., None]) + code("#121317") * inside[..., None]
    glow = glow * (1 - inside)
    rng = np.random.default_rng(72)
    for _ in range(int(0.92 * WELL ** 2)):
        a, q = rng.uniform(0, 2 * np.pi), (WELL - 1.2) * np.sqrt(rng.uniform(0.15, 1.0))
        far = band(np.hypot(x - (gx + q * np.sin(a)), y - (ROW + q * np.cos(a))), float(rng.choice((0.07, 0.07, 0.11))))
        _mix(page, "#C8F6FA", far)
        glow += 0.7 * far
    _mix(page, WEARS["Mill"], band(r - (WELL - 0.25), 0.16))
    return glow + 0.6 * band(r - (WELL - 0.25), 0.16), inside


def floor_pictures(name):
    """A floor's pair of pictures, the colour and the glow: its own ground of the plot, across from the picture's left
    to its right and in from the front edge down it. AR65's calm floor (research's pick, target A): the stone's slabs,
    a soft shade at the wall's foot, the ring where a player arrives, and the Mill's well. Gone with AR65: the
    machines' pads and the bays' frames, the conduits and their boxes, the joints, the court's lines, the way in's
    dashes and the hazard under the gate."""
    x0, x1, y0, y1 = FLOOR_AT[name]
    rows, cols = 512, (1024 if x1 - x0 > BLOCK else 512)   # 16 px a stud in, 23 or more across
    yy, xx = np.mgrid[0:rows, 0:cols].astype(np.float32)
    x, y = x0 + (xx + 0.5) / cols * (x1 - x0), y0 + (yy + 0.5) / rows * (y1 - y0)
    px = ((x1 - x0) / cols + (y1 - y0) / rows) / 2
    band = _band(px)
    page = stone(x, y, px)
    glow = np.zeros((rows, cols), np.float32)
    # the wall's foot: the stone a little darker for its last 3 studs, so the wall stands on it
    foot = HALF - 3.0
    page[..., :3] *= (1.0 - 0.12 * np.clip((np.abs(x) - foot) / 3.0, 0, 1))[..., None]
    # where the player arrives: a ring on the stone, pale and quiet
    r = np.hypot(x - SPAWN[0], y - SPAWN[1])
    ring = np.maximum(band(r - 4.2, 0.14), band(r - 3.2, 0.06))
    _mix(page, "#F3EEE4", ring * 0.8)
    glow += 0.25 * ring
    glow, _ = well(page, glow, x, y, px)
    return page, grey(glow)


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
        half = A // WEAR_PX
        for name in WEARS:                       # each machine's own copy, at half the size: the same cells
            page, glow = atlas(swatches_of(name))
            page = page.reshape(WEAR_PX, half, WEAR_PX, half, 4).mean((1, 3))
            glow = glow.reshape(WEAR_PX, half, WEAR_PX, half).mean((1, 3))
            save(page, out / f"Base_{name}_Color.png")
            save(grey(glow), out / f"Base_{name}_Glow.png")
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
    """Level 1's gate on the Strip: two steel towers on concrete feet with a collar at the foot and an insulator and a
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
          **generator.PIECES,      # and the Generator, the held core (AR67, base_generator.py)
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
    piece = PIECES[name]()
    if piece.maps == "Kit":
        piece.maps = wear_of(name)   # a machine wears its own copy of the atlas (AR65)
    return piece


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
        what="AR14: the base's own kit, made simpler by AR65: graphite machines on pale stone, each in one accent of "
             "its own. Made and laid as Lantern Row's kit is.",
        wears="each machine wears its own pair of pictures, half the size of the kit's and with the same cells (a "
              "piece's `colour` and `glow`): Base_Mill_ (the generator's pieces), Base_Breaker_, Base_Bay_, "
              "Base_Training_, Base_Condenser_, Base_Door_ (the Door's rim a step down) and Base_Yard_ (the wall, the "
              "gate and its fins, unlit but the gate's plate). BayHalo and CondenserJewel keep the kit's, for the "
              "builder's tint.",
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
        maps={"Base_Deck_Color.png": f"the plain stone, a tile {DECK[1]:g} studs square (two courses of slabs), for a Texture on a Part"},
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
