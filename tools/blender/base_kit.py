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
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import rook_sheet as rs  # noqa: E402

Mesh, Piece, code, grey = kit.Mesh, kit.Piece, kit.code, kit.grey
A, CELL = kit.A, kit.CELL

# --- the plot, as the builder lays it (WorldService.plot, Config.World): copies, read again when the layout moves ------
# Studs. `in` is from the plot's front edge, the one on the Strip, into the plot.

PLOT, STRIP, SPAWN = 200.0, 48.0, 40.0
BREAKER, BATTERY = 12.0, 26.0
BAYS = [(side * 22.0, 26.0 + row * 14.0) for row in range(3) for side in (-1, 1)]   # in the order they open
BAYS_AT = {1: 2, 2: 4, 3: 6}       # bays by the base's level (docs/design.md, research's seeds)
GENERATOR, DOOR = -17.0, 34.0      # across, level with the Breaker; the Training machine stands at -DOOR

# --- the yard ------------------------------------------------------------------------------------------------------------

COURT = (44.0, 48.0)   # the walled court: half across, and how far in from the front edge
LANE = 12.5            # a lane's middle, between the Breaker's line and the bays
GATE = 22.0            # a gate tower's place, across
WING = 28.0            # where a front wall ends and the gate's shoulder begins
SPAN = 48.0            # from pylon to pylon
ARMS = ((16.5, 5.2), (20.0, 3.8))   # a pylon's arms: how high, and how far each reaches
HANG = 1.9             # an insulator's drop under its arm
FLOOD = (45.5, 3.0, 12.0)   # a flood mast: in from the front; its head's reach toward the front, and its height
COURT_GLOW = 1.0       # the court's glow picture's white, as emission strength (EmissiveStrength)
MAPS = {"Kit": ("#FFFFFF", kit.GLOW), "Court1": ("#FFFFFF", COURT_GLOW)}   # each pair's tint and strength

# Swatches: the colour at the head, at the foot, and how much it glows. Steel and bone under the dusk, the current in
# Power's yellow (the HUD's own), the Breaker's light in cyan.
SWATCHES = {
    "steel": ("#62709A", "#2C3556", 0.0), "girder": ("#3A4468", "#181D32", 0.0), "bone": ("#E9E2D2", "#9C95A6", 0.0),
    "concrete": ("#A2A7BC", "#5A5F78", 0.0), "yellow": ("#FFD23E", "#B07A28", 0.05), "rubber": ("#1F2233", "#0E101A", 0.0),
    "ceramic": ("#F4F0E8", "#A8A2B6", 0.0), "copper": ("#DE8E54", "#7C4630", 0.0), "power": ("#FFF6C4", "#FFD94A", 1.0),
    "cyan": ("#8CF6FF", "#3CC8E8", 1.0), "lamp": ("#F6FCFF", "#CDEEFF", 1.0), "beacon": ("#FF9A7A", "#FF6A52", 1.0),
    "dark": ("#1E1426", "#0C0A12", 0.0), "ink": ("#0C0A16", "#0C0A16", 0.0),
}
SWATCH_AT = {name: ((i % 16) * CELL[0], (i // 16) * CELL[1]) for i, name in enumerate(SWATCHES)}
# Prints: where each sits (x, y, width, height), each with a 4 pixel bleed round it.
PRINTS = {"panel": (8, 268, 512, 160), "hazard": (536, 268, 256, 48), "plate": (536, 332, 256, 112)}
DECK = (512, 8.0)      # the deck's own tile: pixels, and the studs it covers (four plates)
PLATE = 4.0            # a deck plate, studs
DECK_TONES = ("#6C7698", "#535C7E", "#252B44", "#8A94B6")   # a plate's two colours, its seam, its lit edge


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


def court_pictures(level=1):
    """A level's court, half of it: across from the plot's middle line out to the wall (the picture's left to its
    right), in from the front edge (its head to its foot). The colour, and the glow: the conduits' current, the lit
    bays' frames, the Breaker's ground, and the floods' pools."""
    n = 1024
    half, deep = COURT
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    x, y = (xx + 0.5) / n * half, (yy + 0.5) / n * deep
    px = (half + deep) / 2 / n
    band = lambda dist, reach: np.clip((reach - np.abs(dist)) / px + 0.5, 0, 1)   # noqa: E731
    page = plates(x, y, 14 + level, px)
    glow = np.zeros((n, n), np.float32)
    # the wall's foot: a darker margin inside a pale line, at the side and at the back
    margin = np.clip((np.maximum(x - (half - 3.0), y - (deep - 3.0))) / px + 0.5, 0, 1)
    page[..., :3] *= (1.0 - 0.38 * margin)[..., None]
    _mix(page, "#C9D2E6", np.maximum(band(x - (half - 3.0), 0.09) * (y < deep - 3.0), band(y - (deep - 3.0), 0.09) * (x < half - 3.0)) * 0.6)
    # the threshold under the gate, between its towers' feet: hazard on the slant
    sill = (band(y - 0.9, 0.7) * (x < GATE - 2.6)).astype(np.float32)
    stripe = (((x + y) // 0.9) % 2).astype(np.float32)
    _mix(page, "#FFD23E", sill * (1 - stripe))
    _mix(page, "#1F2233", sill * stripe)
    # the lanes: a pale dashed line down each, front to back
    _mix(page, "#D4DCEE", band(x - LANE, 0.11) * ((y % 4.0) < 2.0) * (y > 3.0) * (y < deep - 4.0) * 0.45)
    # the bays: a frame of Power's yellow round each pad, heavy at its corners; lit where the bay is open
    for index, (bx, by) in enumerate(BAYS):
        if bx < 0 or by + 7.0 > deep:
            continue
        dx, dy = np.abs(x - bx), np.abs(y - by)
        box = np.maximum(dx, dy)
        corner = (np.minimum(dx, dy) > 3.6).astype(np.float32)
        frame = np.maximum(band(box - 6.2, 0.12), band(box - 6.2, 0.3) * corner)
        open_ = index < BAYS_AT[level]
        page[..., :3] *= (1.0 - 0.3 * np.clip((6.2 - box) / px + 0.5, 0, 1))[..., None]
        _mix(page, "#FFD23E" if open_ else "#7A84A6", frame * (1.0 if open_ else 0.55))
        if open_:
            glow += 0.4 * frame + 0.16 * np.exp(-((x - bx) ** 2 + (y - by) ** 2) / 8.0 ** 2)
    # the Breaker's ground: a darker dais inside a pale cyan line
    dx, dy = np.abs(x) - 9.5, np.abs(y - BREAKER) - 5.2
    box = np.maximum(dx, dy)
    page[..., :3] *= (1.0 - 0.3 * np.clip(-box / px + 0.5, 0, 1))[..., None]
    _mix(page, "#BFEFF5", band(box, 0.12))
    glow += 0.45 * band(box, 0.12) + 0.3 * np.exp(-(x ** 2 + (y - BREAKER) ** 2) / 11.0 ** 2)
    # where the player arrives: a ring on the deck
    r = np.hypot(x, y - SPAWN)
    ring = np.maximum(band(r - 4.2, 0.14), band(r - 3.2, 0.06))
    _mix(page, "#E9E2D2", ring * 0.9)
    glow += 0.25 * ring
    # the conduits: a dark casing, the current a bright core, a clamp every plate; each bay to the battery, the
    # battery to the Breaker, and the Breaker's rail out under the generator and the waiting line to the two doors
    runs = [((3.0, BATTERY), (17.6, BATTERY)), ((0.0, BREAKER + 3.2), (0.0, BATTERY - 2.0)), ((7.2, BREAKER), (31.0, BREAKER))]
    casing, core, halo = np.zeros_like(glow), np.zeros_like(glow), np.zeros_like(glow)
    for (x0, y0), (x1, y1) in runs:
        along = (x - x0) if y0 == y1 else (y - y0)
        length = (x1 - x0) if y0 == y1 else (y1 - y0)
        off = (y - y0) if y0 == y1 else (x - x0)
        d = np.hypot(off, along - np.clip(along, 0.0, length))
        clamp = ((along % PLATE) < 0.4).astype(np.float32)
        casing = np.maximum(casing, np.maximum(band(d, 0.8), band(d, 1.05) * clamp))
        core = np.maximum(core, band(d, 0.32) * (1 - clamp))
        halo = np.maximum(halo, np.exp(-(d / 2.4) ** 2))
        for ex, ey in ((x0, y0), (x1, y1)):                       # a junction at each end
            e = np.hypot(x - ex, y - ey)
            casing = np.maximum(casing, band(e, 1.3))
            core = np.maximum(core, band(e - 0.75, 0.16))
    _mix(page, "#141724", casing)
    _mix(page, "#FFF1A8", core)
    glow = np.maximum(glow + 0.3 * halo * (1 - casing), core)
    # the floods' pools on the lanes, behind the arrival
    glow += 0.3 * np.exp(-((x - LANE) ** 2 + (y - (FLOOD[0] - FLOOD[1])) ** 2) / 9.0 ** 2)
    return page, grey(glow)


def write_pictures(out: Path):
    out.mkdir(parents=True, exist_ok=True)
    page, glow = atlas()
    rs.save(page, out / "Base_Kit_Color.png")
    rs.save(grey(glow), out / "Base_Kit_Glow.png")
    rs.save(deck_tile(), out / "Base_Deck_Color.png")
    colour, lit = court_pictures(1)
    rs.save(colour, out / "Base_Court1_Color.png")
    rs.save(lit, out / "Base_Court1_Glow.png")


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
        """A level's court floor, 88 studs by 48 from the front edge in: one picture, laid mirrored about the middle."""
        m = Mesh(None)
        half, deep = COURT
        m.face([Vector((0, -deep, 0.06)), Vector((half, -deep, 0.06)), Vector((half, 0, 0.06)), Vector((0, 0, 0.06))],
               [(0, 0), (1, 0), (1, 1), (0, 1)])
        m.face([Vector((-half, -deep, 0.06)), Vector((0, -deep, 0.06)), Vector((0, 0, 0.06)), Vector((-half, 0, 0.06))],
               [(1, 0), (0, 0), (0, 1), (1, 1)])
        return Piece(f"Court{level}", m, maps=f"Court{level}", solid="floor",
                     note="lies 0.06 over the deck, its front edge on the plot's; a Part under it carries the walking")
    return make


def wall(run=True):
    """The yard's wall: a post on a concrete foot with a lamp on its cap, and a ribbed steel panel 16 studs along +X
    to the next post, a line of light under its bone coping. A run's last post is the same without the panel."""
    m = Mesh()
    m.box((2.0, 2.0, 1.2), (0, 0, 0.6), "concrete", ink=True)
    m.box((1.1, 1.1, 5.4), (0, 0, 3.9), "girder", ink=True)
    m.box((1.5, 1.5, 0.4), (0, 0, 6.8), "yellow")
    m.box((0.6, 0.6, 0.5), (0, 0, 7.25), "power")
    if run:
        m.box((14.9, 1.0, 1.0), (8.0, 0, 0.5), "concrete", ink=True)
        m.box((14.9, 0.5, 3.6), (8.0, 0, 2.8), "steel", pics={"+y": "panel", "-y": "panel"}, ink=True)
        m.box((14.9, 0.58, 0.14), (8.0, 0, 4.72), "power")
        m.box((15.2, 0.8, 0.3), (8.0, 0, 4.95), "bone")
    return Piece("Wall" if run else "WallEnd", m, solid="the post, and the panel as a wall 5 studs high" if run else "the post",
                 note="the panel runs 16 studs along +X to the next post" if run else "a run's last post: no panel")


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


PIECES = {"Court1": court(1), "Wall": wall, "WallEnd": lambda: wall(False), "Gate1": gate, "Pylon": pylon,
          "PowerSpan": power_span, "FloodMast": flood_mast, "Transformer": transformer}


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
        shadows="CastShadow off on PowerSpan and the court's floor.",
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
