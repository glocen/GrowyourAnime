"""AR56's finish (docs/asset-requests.md, AR56, "Research's pick"): the Tower's room, the Crown, as a kit. The tower's
open top above the cloud: a round fight floor, a step ring round it, eight stone blades leaning out of the rim, the
floor's number on a slab afloat over the foe's floating steps, cloud drifts passing at the rim's height, and in the
sky under the horizon the cloud and the deep haze under it.

In the base's language (base_kit's swatches, AR40's C): the void machines' pale sand stone, teal bronze fittings, the
deck's plates, a warm white light that lies in a dark teal well. No violet on the room: violet is the foe's.

Made as the base's kit is (lantern_row_kit's mesh builder, swatch atlas, ink hull and manifest), on pictures of its
own. A piece's front faces +Y, one unit is one stud. The room's frame: its middle is the fight floor's middle at the
floor's level, the entrance at -Y, the foe's way in at +Y.

The pieces:
    CrownFloor, CrownFloorM   a quarter of the fight floor and its mirror, both on one drawn pair of pictures (Floor):
                              each stands twice, the second turned half round, so the floor is four parts
    CrownBody                 the step ring with its flagstones, the neck and the shaft
    CrownBlade, -Tall, -Low   a blade: sand stone on a teal socket, a line of light in a well up its inner face
    CrownSlab                 the number's slab, a part of its own: it turns half round at a win; the numerals are text
    CrownStep                 a floating step, a part of its own: the foe's four rise into place before it climbs
    CloudDrift, CloudDriftB   a drift of cloud near the room, passing slowly
    GateDais, GateVeil        the entrance on the lot behind the base: its dais and its door of light; with two blades
                              and the slab, which there carries the owner's record floor (`LOT`)
The sky's lower half is the sky's own: `skies` renders the six faces from the room's middle, with the cloud in three
layers (`cloud_sea`) and the haze under it (`haze_paint`), neither a part. No lower tower stands in it: from the
fight's camera a tower's blades read as pale spikes at any distance (research's look at the finish, "or none").

The four classes of research's pick, and where each is answered:
    1 air, not land   `SKY`, `SEA_LAYERS`, `HAZE`, `cloud_sea`, `DRIFTS`: research's look at the finish
                      asked that the band past the far rim read as looking down on cloud
    2 the floor       `floor_pictures`: a heart of stone at a mid value, a deck of steel round it, a lane from the
                      entrance to the foe's steps, the stands' ring and pads, a conduit from each blade round to the lane
    3 the fighters    `leads`: the fight's frame with three coloured leads against the same foe
    4 the beat        `beat`: the slab's half turn and the steps' rise, then the foe up them (seeds in BEAT)

Run, each `guard.ps1 tools/blender/tower_room_kit.py <abs out> <mode>` (Eevee, no lock):
    look      the frames: <out>/crown_<enter|fight|up|whole|above>.png, and crown_lead_<n>.png; names after it
              (enter fight up whole above leads) render only those
    beat      the take's frames, <out>/beat/f###.png: a win, with the drifts passing
    movie     <out>/crown_beat.mp4, from those
    sheet     <out>/crown.png and crown_64.png, from those
    stand     research's grey test, the player's stand raised: <out>/crown_stand_<back>_<height>.png and crown_stand.png
    landing   research's grey test of the height at the door: <out>/crown_landing_<frame>.png and crown_landing.png
    lot       the entrance on the lot and the record's marker: <out>/gate_<approach|door|visitor|far|back>.png
    lotsheet  <out>/gate.png, from those
    pictures  the maps alone, into <out>/maps
    export    <out> is the handoff folder: meshes, maps (the sky's faces too), manifest.json, plan.json, lighting.json
"""

import json
import math
import random
import sys
import textwrap
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))

import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402
import tower_block as tb  # noqa: E402
import tower_room_block as block  # noqa: E402

PREFIX = "TowerRoom"
FLOOR_R, STEP_R, STEP_DOWN = 48.0, 60.0, 1.5      # the fight floor; the step ring's outer edge, and how far it lies under
STAND = block.STAND
SHOWN = 17
A, CELL = kit.A, kit.CELL
MAPS = {"Kit": ("#FFFFFF", 1.3), "Floor": ("#FFFFFF", 1.1)}       # each pair's tint and glow strength, by day
# Swatches: the colour at the head, at the foot, and how much it glows (base_kit's names and colours where they exist).
SWATCHES = {
    "sand": ("#F4E6C8", "#B2946C", 0.0),          # the void machines' stone (base_kit's abyss, a breath paler at the head)
    "girder": ("#46A39C", "#1F5E64", 0.0), "bone": ("#FFF4DC", "#C2AE8C", 0.0),
    "well": ("#1A353C", "#1A353C", 0.0), "trail": ("#FFF8EA", "#F6DCA6", 1.0),
    "cloud": ("#FFFFFF", "#9DBBEE", 0.3),         # a drift: white at its head, a cool shadow at its foot, never grey
    "ink": ("#0C0A16", "#0C0A16", 0.0),
}
SWATCH_AT = {name: ((i % 16) * CELL[0], (i // 16) * CELL[1]) for i, name in enumerate(SWATCHES)}
# The room's own light (a client's Lighting while it stands in the room): a white sun low from the side, so the blades'
# shadows lie across the floor; a cool fill, so every shadow is blue; a haze that takes the far cloud.
SKY = dict(
    sky=((-0.2, "#C6DBF7"), (0.0, "#DCEAFB"), (0.05, "#B4D3F5"), (0.18, "#78B0EC"), (0.5, "#3F88DE"), (1.0, "#2A68C8")),
    clouds=("#FFFFFF", "#C4D8F4", 0.05, 0.16, 0.72), stars=0.0, moon=None,
    sun=(278.0, 34.0, "#FFF6E8", 1.35, True), ambient=("#C2CDE4", 0.8), fog=("#D2E2F8", 0.00042))
SEA = -150.0                                      # the cloud sea's level, studs under the floor
FAR = 12000.0                                     # how far a frame draws, studs
SEA_REACH = 5400.0                                # how far out its cloud stands
# The cloud is in three layers, its heads apart so the haze's deep blue shows between them and the eye looks down
# through: a near layer of small heads, low enough that the fight's camera sees them whole in the deep blue past the far
# rim with blue over them (it sees from the horizon to 7 degrees under it there: a cloud with sky above it and under
# the horizon can only be below the eye), the far deck, closing toward the horizon, and a low layer under the room,
# which a player at the rim looks down on. Each: how many heads,
# from and to how far, its tops' heights, a head's height, its width. The near layer is laid by the eye instead: `under`
# is how many degrees under the horizon a head's top stands from the floor, and its height and width are shares of how
# far off it is, so every near head is in the frame and none is lost under the rim.
SEA_LAYERS = (dict(heads=72, reach=(600.0, 1900.0), under=(2.6, 6.4), tall=(0.02, 0.036), wide=(0.06, 0.13), cuts=4, puffs=10),
              dict(heads=34, reach=(2800.0, SEA_REACH), top=(-95.0, -50.0), tall=(60.0, 120.0), wide=(220.0, 520.0), cuts=3, puffs=8),
              dict(heads=44, reach=(220.0, 1300.0), top=(-150.0, -75.0), tall=(30.0, 60.0), wide=(90.0, 200.0), cuts=4, puffs=10))
EYE = 8.8                                         # the player's eye over the floor in a fight's frame
SEA_EXTRA = []                                    # a test's own layers, after the room's (the room's heads keep their places)
SEA_GAP = 7.0                                     # degrees each side of the foe's way in that the near layer leaves open
HAZE = ((1000.0, "#4686E4"), (1800.0, "#6BA0EC"), (3000.0, "#A3C5F4"), (4500.0, "#CDE0F9"), (6000.0, "#DCEAFB"))   # the haze under the cloud, by how far off: deep, then the horizon's
# The floor's plates: each ring's inner and outer edge, its count of plates and its turn in plates; the two tones of
# the inner field, of the outer, and the lane's and the middle's. The ground under and behind the fighters is a mid
# value, so a pale lead and a dark one both stand off it (research's look at the finish); the light is the lines'.
FLOOR_RINGS = ((13.6, 21.8, 12, 0.0), (21.8, 30.0, 16, 0.5), (30.0, 37.3, 24, 0.0), (37.3, 44.5, 24, 0.5))
FLOOR_TONES = (("#928570", "#9D907A"), ("#6F8F90", "#7B9A99"), ("#A99C88", "#978A75"))
CONDUITS = ((67.5, 39.5), (22.5, 34.5))           # in a quarter: a blade's angle, and the radius its conduit turns at
BLADES = ((22.5, "CrownBladeLow"), (67.5, "CrownBladeTall"), (112.5, "CrownBladeTall"), (157.5, "CrownBladeLow"),
          (202.5, "CrownBlade"), (247.5, "CrownBlade"), (292.5, "CrownBlade"), (337.5, "CrownBlade"))
BLADE_TALL = {"CrownBlade": 46.0, "CrownBladeTall": 54.0, "CrownBladeLow": 40.0}
SLAB_AT = (0.0, 63.0, 20.0)
SLAB_SHAPE = ((-9.5, 7.5), (9.5, 7.5), (10.5, 6.0), (10.5, -2.5), (0.0, -9.5), (-10.5, -2.5), (-10.5, 6.0))   # x, z
SLAB_WELL = ((-8.4, -1.2), (8.4, 6.0))            # the well of the numerals, its corners
# The foe's steps lie nearly level, each a little under the one before: the fight's camera looks 6 degrees down at the
# far rim, so steps going down any steeper hide one behind the other. Risen, each shows its top and its lit edge past
# the one before; at rest each waits out of sight under the rim.
FOE_STEPS = ((0.0, 66.0, -1.0), (0.0, 80.0, -1.3), (0.0, 95.0, -1.6), (0.0, 111.0, -2.0))
IN_STEPS = ((0.0, -67.0, -3.0), (0.0, -82.0, -9.0))
# The drifts pass at the rim's height and just under it: (piece, x, y, z, turn, scale, studs a second along +X).
DRIFTS = (("CloudDriftB", -171.0, 171.0, -5.0, 30.0, 1.3, 7.0), ("CloudDrift", 150.0, 142.0, -10.0, 0.0, 1.1, 6.0),
          ("CloudDrift", 14.0, 255.0, -16.0, 200.0, 1.6, 5.0), ("CloudDriftB", 172.0, 62.0, -3.0, 110.0, 1.0, 8.0),
          ("CloudDrift", -178.0, 40.0, -9.0, 250.0, 1.2, 8.0), ("CloudDrift", -150.0, -80.0, -12.0, 300.0, 1.3, 6.0),
          ("CloudDriftB", 140.0, -90.0, 1.0, 70.0, 1.0, 7.0), ("CloudDrift", -40.0, -180.0, -10.0, 150.0, 1.2, 6.0),
          ("CloudDriftB", 60.0, -170.0, -16.0, 20.0, 1.0, 6.0), ("CloudDriftB", -40.0, 88.0, -30.0, 0.0, 1.6, 9.0))
# The climb's beat, seconds from a win (seeds; Config.Tower.Rise is 2.5): the slab's half turn, each step's rise from
# its rest under its place (the farthest first, the next foe standing on it), the foe's hops up them, its leap to the
# stand, the steps' sinking.
BEAT = dict(turn=(0.0, 0.5), rise=0.35, stagger=0.15, first=0.2, rest=(-10.0, -13.0, -16.0, -20.0),
            climb=(0.85, 1.75), leap=(1.75, 2.35), sink=(2.4, 2.9), span=(-0.2, 3.0))


# --- the pictures --------------------------------------------------------------------------------------------------------

def wear():
    """The mesh builder reads its atlas from the kit's module: the room's pieces wear the room's."""
    kit.SWATCHES, kit.SWATCH_AT, kit.PRINTS = SWATCHES, SWATCH_AT, {}


def atlas():
    page = np.zeros((A, A, 4), np.float32)
    page[..., :3], page[..., 3] = kit.code("#1A353C"), 1.0
    glow = np.zeros((A, A), np.float32)
    t = np.linspace(0, 1, CELL[1], dtype=np.float32)[:, None, None] ** 0.85   # down the cell: head to foot
    shade = 1.0 - 0.5 * np.clip((np.arange(CELL[0], dtype=np.float32) - 8) / 48, 0, 1)[None, :, None]
    for name, (top, bottom, lit) in SWATCHES.items():
        x, y = SWATCH_AT[name]
        cell = kit.code(top) * (1 - t) + kit.code(bottom) * t
        page[y:y + CELL[1], x:x + CELL[0], :3] = cell * (shade if lit < 0.1 else 1.0)
        glow[y:y + CELL[1], x:x + CELL[0]] = lit
    return page, glow


def floor_pictures():
    """A quarter of the fight floor, from above: the room's +X across the picture, its +Y up it. Mirrored and turned
    it makes the whole floor, so every line is its own mirror across both axes and nothing on the floor spins. The
    lane runs along Y only, from the entrance to the foe's steps. A blade's conduit comes in a short way, turns along
    the floor's curve and ends in the lane: the light runs to the middle, and is never a ray out of it."""
    n = 1024
    j, i = np.meshgrid(np.arange(n, dtype=np.float32), np.arange(n, dtype=np.float32))
    x, y = (j + 0.5) / n * FLOOR_R, (n - i - 0.5) / n * FLOOR_R
    r, th = np.hypot(x, y), np.arctan2(y, x)
    px = FLOOR_R / n
    rgb = np.zeros((n, n, 3), np.float32)
    glow = np.zeros((n, n), np.float32)
    ones = np.ones_like(r)
    wells = []                                     # each line of light: its distance field, and where it runs

    def line(d, half):
        return np.clip((half - np.abs(d)) / px + 0.5, 0, 1)

    def under(d):
        return np.clip(-d / px + 0.5, 0, 1)

    def lay(colour, a, lit=0.0):
        rgb[:] = rgb * (1 - a[..., None]) + kit.code(colour) * a[..., None]
        glow[:] = glow * (1 - a) + lit * a

    def noise(a, b):
        return np.modf(np.abs(np.sin(a * 12.9898 + b * 78.233) * 43758.5453))[0].astype(np.float32)

    # the plates: warm stone at a mid value, steel in the outer field, so a pale fighter and a dark one both read
    rgb[:] = kit.code(FLOOR_TONES[0][0])
    seam = np.full_like(r, 9.0)
    for k, (r0, r1, count, off) in enumerate(FLOOR_RINGS):
        inside = (r >= r0) & (r < r1)
        u = th / (2 * np.pi) * count + off
        tone = noise(float(k) + 1.0, np.floor(u))[..., None]
        a, b = FLOOR_TONES[0 if k < 2 else 1]
        rgb[inside] = (kit.code(a) * (1 - tone) + kit.code(b) * tone)[inside]
        f = np.modf(u)[0]
        seam = np.where(inside, np.minimum(np.minimum(f, 1 - f) * (2 * np.pi * r / count), np.minimum(r - r0, r1 - r)), seam)
    steel = under(30.0 - r)                                                 # the outer field: the deck, sea-grey steel
    lay("#B4AB9A", line(seam, 0.17) * 0.4 * (1 - steel))
    lay("#4E473C", line(seam, 0.06) * (1 - steel))
    lay("#A5BFBD", line(seam, 0.17) * 0.4 * steel)
    lay("#35504F", line(seam, 0.06) * steel)
    lay("#3F968F", under(np.abs(r - 30.0) - 0.42))                          # a band of teal bronze between the fields
    lay("#1F5E64", line(np.abs(r - 30.0) - 0.42, 0.05))
    # the lane, entrance to foe: a paler run of stone, a line of light down each edge
    lane = under(x - 4.5) * under(13.6 - r) * under(r - 44.5)
    lay(FLOOR_TONES[2][0], lane)
    lay("#6C6455", line(np.minimum(y % 6.2, 6.2 - y % 6.2), 0.05) * lane)
    wells.append((x - 4.5, under(12.9 - r) * under(r - 46.2)))
    # a blade's conduit: from the rim's ring in, then round to the lane
    nodes = []
    for deg, turn in CONDUITS:
        a0 = math.radians(deg)
        wells.append((r * np.sin(th - a0), under(turn - 0.14 - r) * under(r - 46.2) * under(-np.cos(th - a0))))
        wells.append((r - turn, under(a0 - th) * under(4.5 - x)))
        nodes.append(np.hypot(x - turn * math.cos(a0), y - turn * math.sin(a0)))
    # the rim: sand stone, a ring of light in its well
    lay("#E6D8BA", under(44.5 - r))
    lay("#8A7450", line(r - 44.5, 0.06))
    f = np.modf(th / (2 * np.pi) * 32 + 0.5)[0]
    lay("#8A7450", line(np.minimum(f, 1 - f) * (2 * np.pi * r / 32), 0.05) * under(44.5 - r) * under(r - 45.4))
    wells.append((r - 46.2, ones))
    # the middle: one calm run of stone inside the stands' ring of light, where the fighters are read
    lay(FLOOR_TONES[2][1], under(r - 12.4))
    lay("#6C6455", line(r - 7.0, 0.05))
    wells.append((r - 13.0, ones))
    for d, along in wells:
        lay("#1A353C", line(d, 0.5) * along)
    for d, along in wells:
        lay("#8FC4C8", (line(d - 0.42, 0.05) + line(d + 0.42, 0.05)) * along, 0.5)
    for d, along in wells:
        lay("#FFF8EA", line(d, 0.14) * along, 1.0)
    for node in nodes:
        lay("#1A353C", under(node - 1.15))
        lay("#FFF8EA", under(node - 0.5), 1.0)
    # a stand: a pad in the ring, where the avatar and the foe are set down
    pad = np.hypot(x, y - STAND)
    lay("#1A353C", under(pad - 2.1))
    lay(FLOOR_TONES[2][1], under(pad - 1.25))
    lay("#FFF8EA", line(pad - 1.6, 0.14), 1.0)
    rgb *= (1.04 - 0.1 * (r / FLOOR_R) ** 2)[..., None]                     # a breath lighter toward the middle
    page = np.ones((n, n, 4), np.float32)
    page[..., :3] = np.clip(rgb, 0, 1)
    # The joins are the left column (x = 0) and the bottom row (y = 0), and the game wraps the picture there: its
    # filtering and smaller mips read the right columns and the top rows across each join, which held the rim's
    # light sand and drew a light line along both (Faber, AR56). So the picture's far edges mirror the joins: 16
    # pixels deep where they lie outside the floor, 8 where the rim reaches them (only its outer sliver).
    for a in (page, glow):
        for k in range(16):
            use = (r[:, n - 1 - k] > FLOOR_R) | (k < 8)
            a[use, n - 1 - k] = a[use, k]
        for k in range(16):
            use = (r[k, :] > FLOOR_R) | (k < 8)
            a[k, use] = a[n - 1 - k, use]
    return page, glow


def write_pictures(out: Path):
    out.mkdir(parents=True, exist_ok=True)
    page, glow = atlas()
    rs.save(page, out / f"{PREFIX}_Kit_Color.png")
    rs.save(kit.grey(glow), out / f"{PREFIX}_Kit_Glow.png")
    page, glow = floor_pictures()
    rs.save(page, out / f"{PREFIX}_Floor_Color.png")
    rs.save(kit.grey(glow), out / f"{PREFIX}_Floor_Glow.png")


# --- the mesh builder's helpers ------------------------------------------------------------------------------------------

def loft(m, sections, sw, occ, ts, caps=(None, None), ink=False):
    """Sections of the same count joined in order, each face turned out. `occ` one value or one a side; `ts` the
    swatch's height at each section; a cap is (swatch, occ, t)."""
    n = len(sections[0])
    sections = [[Vector(p) for p in s] for s in sections]
    centre = sum((p for s in sections for p in s), Vector()) / (n * len(sections))
    for (a, ta), (b, tb_) in zip(zip(sections, ts), zip(sections[1:], ts[1:])):
        for i in range(n):
            j = (i + 1) % n
            o = occ[i] if isinstance(occ, (list, tuple)) else occ
            m.out([a[i], a[j], b[j], b[i]], [kit.sw_uv(sw, o, ta)] * 2 + [kit.sw_uv(sw, o, tb_)] * 2, centre)
    for cap, s in zip(caps, (sections[0], sections[-1])):
        if cap:
            m.out(list(s), [kit.sw_uv(*cap)] * n, centre)
    if ink and m.ink is not None:
        t = m.ink_t
        fat = []
        for s in sections:
            c = sum(s, Vector()) / n
            fat.append([p + (p - c).normalized() * t for p in s])
        axis = (sum(sections[-1], Vector()) - sum(sections[0], Vector())).normalized()
        fat[0], fat[-1] = [p - axis * t for p in fat[0]], [p + axis * t for p in fat[-1]]
        for a, b in zip(fat, fat[1:]):
            for i in range(n):
                j = (i + 1) % n
                m.out([a[i], a[j], b[j], b[i]], [(0, 0)] * 4, centre, ink=True)
        m.out(list(fat[0]), [(0, 0)] * n, centre, ink=True)
        m.out(list(fat[-1]), [(0, 0)] * n, centre, ink=True)


def rect(w, d, z, at=(0.0, 0.0)):
    x, y = at
    return [(x - w / 2, y - d / 2, z), (x + w / 2, y - d / 2, z), (x + w / 2, y + d / 2, z), (x - w / 2, y + d / 2, z)]


def plate(m, corners, sw, t=0.6, occ=0.0):
    """A flat patch seen from one side: its corners anticlockwise seen from where it is looked at."""
    m.face([Vector(c) for c in corners], [kit.sw_uv(sw, occ, t)] * len(corners))


# --- the pieces ------------------------------------------------------------------------------------------------------------

def crown_floor(mirror=False):
    m = kit.Mesh(None)
    a0 = math.pi / 2 if mirror else 0.0
    pts = [Vector((0, 0, 0))] + [Vector((FLOOR_R * math.cos(a0 + math.pi / 2 * s / 24), FLOOR_R * math.sin(a0 + math.pi / 2 * s / 24), 0))
                                 for s in range(25)]
    sign = -1.0 if mirror else 1.0
    m.face(pts, [(min(max(sign * p.x / FLOOR_R, 0.0), 1.0), min(max(p.y / FLOOR_R, 0.0), 1.0)) for p in pts])
    return kit.Piece("CrownFloorM" if mirror else "CrownFloor", m, maps="Floor", solid="floor",
                     note="a quarter of the fight floor; stands twice, the second turned 180. CastShadow off")


def crown_body():
    m = kit.Mesh()
    m.lathe([(FLOOR_R, -0.03), (FLOOR_R, -STEP_DOWN)], (0, 0, 0), 64, "sand", occ=0.5, caps=False)
    m.lathe([(FLOOR_R, -STEP_DOWN), (STEP_R, -STEP_DOWN)], (0, 0, 0), 64, "girder", occ=0.9, caps=False)
    m.lathe([(STEP_R, -STEP_DOWN), (STEP_R, -4.5), (57.0, -6.8), (52.0, -12.0), (50.0, -36.0), (46.0, -42.0), (43.0, -110.0)],
            (0, 0, 0), 64, "sand", occ=0.2, caps=False)
    m.lathe([(STEP_R + 0.35, -4.2), (57.3, -7.0)], (0, 0, 0), 64, "girder", caps=False)
    m.lathe([(52.4, -11.5), (52.0, -13.5)], (0, 0, 0), 64, "trail", caps=False)                 # a line of light under the rim
    rng = random.Random(4)
    for s in range(24):                                                                       # the step ring's flagstones
        a0, a1 = math.radians(15.0 * s + 0.16), math.radians(15.0 * s + 14.84)
        angles = [a0 + (a1 - a0) * q / 3 for q in range(4)]
        low = [(STEP_R - 0.4) * Vector((math.cos(a), math.sin(a), 0)) for a in angles] + \
              [(FLOOR_R + 0.4) * Vector((math.cos(a), math.sin(a), 0)) for a in reversed(angles)]
        t = 0.7 + 0.3 * rng.random()
        loft(m, [[p + Vector((0, 0, -STEP_DOWN)) for p in low], [p + Vector((0, 0, -STEP_DOWN + 0.28)) for p in low]],
             "sand", 0.3, [0.4, 0.6], caps=(None, ("sand", 0.0, t)))
    for sy in (-1, 1):                                        # the lane's two lines of light go on across the step ring
        for sx in (-1, 1):
            for half, up, sw in ((0.5, 0.05, "well"), (0.14, 0.09, "trail")):
                x, z = sx * 4.5, -STEP_DOWN + 0.28 + up
                y0, y1 = sorted((sy * (FLOOR_R + 0.3), sy * (STEP_R - 0.5)))
                plate(m, [(x - half, y0, z), (x + half, y0, z), (x + half, y1, z), (x - half, y1, z)], sw, t=0.8)
    return kit.Piece("CrownBody", m, solid="hull", note="the step ring, the neck and the shaft, one part")


def crown_blade(name):
    """A blade: its foot on the step ring's edge, leaning out (+Y). Seven sides: a flat inner face that carries the
    line of light, two chamfers, two flanks and a ridged back."""
    tall = BLADE_TALL[name]
    lean = 12.0 * tall / 46.0
    m = kit.Mesh()

    def section(u, grow=1.0):
        w, d = (14.0 + (3.4 - 14.0) * u) * grow, (5.4 + (2.0 - 5.4) * u) * grow
        z, y = tall * u, lean * u ** 1.25
        return [Vector((sx * w / 2, y + sy * d / 2, z)) for sx, sy in
                ((-1, -0.45), (-0.36, -1), (0.36, -1), (1, -0.45), (1, 0.5), (0, 1), (-1, 0.5))]

    us = (0.0, 0.3, 0.62, 0.93)
    occ = [0.15, 0.0, 0.15, 0.55, 0.8, 0.8, 0.55]
    loft(m, [section(u) for u in us], "sand", occ, [0.05 + 0.95 * u for u in us], ink=True)
    tip = section(1.0)
    loft(m, [section(0.93), tip], "bone", occ, [0.5, 1.0], caps=(None, ("bone", 0.0, 1.0)), ink=True)
    foot = [Vector((p.x * 1.1, p.y * 1.16, z)) for z in (-2.2, 2.6) for p in section(0.0)]
    loft(m, [foot[:7], foot[7:]], "girder", occ, [0.2, 0.9], caps=(("girder", 1.0, 0.0), ("girder", 0.0, 1.0)), ink=True)
    band = [Vector((p.x * 1.05, p.y * 1.08, z)) for z in (2.6, 3.3) for p in section(0.06)]
    loft(m, [band[:7], band[7:]], "bone", occ, [0.5, 0.9], caps=(None, ("bone", 0.0, 1.0)))
    for u0, u1, half, proud, sw in ((0.12, 0.8, 0.75, 0.04, "well"), (0.15, 0.77, 0.24, 0.08, "trail")):   # the line in its well
        steps = 6
        for q in range(steps):
            ua, ub = u0 + (u1 - u0) * q / steps, u0 + (u1 - u0) * (q + 1) / steps
            (a1, a2), (b1, b2) = (section(ua)[1:3]), (section(ub)[1:3])
            ca, cb = (a1 + a2) / 2 + Vector((0, -proud, 0)), (b1 + b2) / 2 + Vector((0, -proud, 0))
            ha, hb = min(half, (a2.x - a1.x) / 2 - 0.05), min(half, (b2.x - b1.x) / 2 - 0.05)
            plate(m, [ca + Vector((-ha, 0, 0)), ca + Vector((ha, 0, 0)), cb + Vector((hb, 0, 0)), cb + Vector((-hb, 0, 0))],
                  sw, t=0.3 + 0.7 * ub)
    return kit.Piece(name, m, solid="hull", note=f"{tall:g} tall, leaning out {lean:g} at its head; its front faces out of the room")


def crown_slab():
    """The number's slab, about its own middle: a stone tablet whose foot points down at the foe's stand. It turns
    half round at a win, so both faces carry a well for the numerals."""
    m = kit.Mesh()

    def outline(grow, y):
        return [Vector((x * grow, y, z * grow)) for x, z in SLAB_SHAPE]

    loft(m, [outline(1.0, -0.9), outline(1.0, 0.9)], "sand", 0.3, [0.5, 0.5],
         caps=(("sand", 0.1, 0.85), ("sand", 0.1, 0.85)), ink=True)
    loft(m, [outline(1.07, -0.5), outline(1.07, 0.5)], "girder", 0.2, [0.7, 0.7],
         caps=(("girder", 0.3, 0.5), ("girder", 0.3, 0.5)), ink=True)
    (x0, z0), (x1, z1) = SLAB_WELL
    for side in (-1, 1):
        y = side * 0.94
        well = [Vector((x, y, z)) for x, z in ((x0 + 0.7, z0), (x1 - 0.7, z0), (x1, z0 + 0.7), (x1, z1 - 0.7), (x1 - 0.7, z1),
                                               (x0 + 0.7, z1), (x0, z1 - 0.7), (x0, z0 + 0.7))]
        plate(m, well if side < 0 else well[::-1], "well")
        for half, y, sw in ((0.5, side * 0.94, "well"), (0.16, side * 0.98, "trail")):       # a line of light down to its point
            down = [Vector((x, y, z)) for x, z in ((-half, -7.6), (half, -7.6), (half, -3.4), (-half, -3.4))]
            plate(m, down if side < 0 else down[::-1], sw, t=0.8)
    return kit.Piece("CrownSlab", m, note="the floor's number: text on each face's well, 16.8 wide by 7.2 tall, its middle 2.4 "
                     "over the slab's; a part of its own, turned half round about its upright at a win")


def crown_step():
    """A floating step, its top's middle at its origin: sand stone on a teal keel, a line of light along its inner edge."""
    m = kit.Mesh()
    loft(m, [rect(14.0, 10.0, -1.3), rect(14.0, 10.0, 0.0)], "sand", [0.2, 0.5, 0.5, 0.5], [0.45, 0.8],
         caps=(("sand", 1.0, 0.0), ("sand", 0.0, 1.0)), ink=True)
    loft(m, [rect(3.6, 2.6, -6.2), rect(8.0, 5.6, -3.4), rect(12.4, 8.6, -1.3)], "girder", [0.2, 0.6, 0.7, 0.6], [0.0, 0.5, 0.9],
         caps=(("girder", 1.0, 0.0), None), ink=True)
    plate(m, rect(12.4, 1.3, 0.03, (0.0, -4.0)), "well")
    plate(m, rect(11.8, 0.6, 0.06, (0.0, -4.0)), "trail", t=0.8)
    return kit.Piece("CrownStep", m, solid="box", note="a part of its own: the foe's four rise into place before it climbs; "
                     "the lit edge faces the room (-Y)")


def cloud_drift(name, seed):
    """A drift: soft lumps heaped along its length, round under as over, white at the head and cool at the foot."""
    rng = random.Random(seed)
    lumps = [((0.0, 0.0, 0.0), (22.0, 13.0, 7.0))]
    for _ in range(9):
        lumps.append(((rng.uniform(-25, 25), rng.uniform(-9, 9), rng.uniform(-1.5, 3.0)),
                      (rng.uniform(6, 14), rng.uniform(5, 11), rng.uniform(4.0, 8.0))))
    low = min(c[2] - 0.6 * s[2] for c, s in lumps)
    high = max(c[2] + s[2] for c, s in lumps)
    m = kit.Mesh(None)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    ball = [[Vector(v.co) for v in f.verts] for f in bm.faces]
    bm.free()
    for (cx, cy, cz), (sx, sy, sz) in lumps:
        for tri in ball:
            pts = [Vector((cx + p.x * sx, cy + p.y * sy, cz + p.z * sz * (0.6 if p.z < 0 else 1.0))) for p in tri]
            m.face(pts, [kit.sw_uv("cloud", 0.0, tb.clamp((p.z - low) / (high - low)) ** 0.7) for p in pts])
    piece = kit.Piece(name, m, note="smooth; CastShadow off, no collision; its place carries a scale and a drift")
    piece.smooth = True
    return piece


PIECES = {
    "CrownFloor": crown_floor, "CrownFloorM": lambda: crown_floor(True), "CrownBody": crown_body,
    "CrownBlade": lambda: crown_blade("CrownBlade"), "CrownBladeTall": lambda: crown_blade("CrownBladeTall"),
    "CrownBladeLow": lambda: crown_blade("CrownBladeLow"), "CrownSlab": crown_slab, "CrownStep": crown_step,
    "CloudDrift": lambda: cloud_drift("CloudDrift", 3), "CloudDriftB": lambda: cloud_drift("CloudDriftB", 8),
}


def plan():
    """Where each piece stands in the room's frame: (piece, tag, x, y, z, turn in degrees, scale)."""
    rows = [("CrownFloor", "A", 0, 0, 0, 0, 1), ("CrownFloor", "C", 0, 0, 0, 180, 1), ("CrownFloorM", "B", 0, 0, 0, 0, 1),
            ("CrownFloorM", "D", 0, 0, 0, 180, 1), ("CrownBody", "", 0, 0, 0, 0, 1)]
    for k, (deg, name) in enumerate(BLADES):
        a = math.radians(deg)
        rows.append((name, str(k), 61.0 * math.cos(a), 61.0 * math.sin(a), -STEP_DOWN, deg - 90.0, 1))
    rows.append(("CrownSlab", "", *SLAB_AT, 0, 1))
    rows += [("CrownStep", f"Foe{k}", *at, 0, 1) for k, at in enumerate(FOE_STEPS)]
    rows += [("CrownStep", f"In{k}", *at, 180, 1) for k, at in enumerate(IN_STEPS)]
    rows += [(name, f"Drift{k}", x, y, z, turn, scale) for k, (name, x, y, z, turn, scale, _) in enumerate(DRIFTS)]
    return rows


# --- the room, built and lit -----------------------------------------------------------------------------------------------

def light():
    """The game's day (AR40's C), turned for the room."""
    tb.by_day()
    d = dict(look.DIRECTIONS["M"])
    az, el, colour, strength, shadow = SKY["sun"]
    d.update(sky=SKY["sky"], sky_away=SKY["sky"], clouds=SKY["clouds"], stars=SKY["stars"], moon=SKY["moon"],
             sun=(az, el, colour, strength, shadow), ambient=SKY["ambient"], fog=SKY["fog"], fog_away=SKY["fog"][0])
    look.FOG.update(colour=look.srgb(SKY["fog"][0]), density=SKY["fog"][1], azimuth=0.0, away=None)
    return d


def cloud_paint():
    """The cloud's paint: the haze's blue at a head's foot to white at its top, by the head's own height (the mesh's
    `lift`), and a share of it as its own light, so a head's shaded side is pale blue and never grey."""
    mat, p = look._new("CloudSea")
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    lift = nodes.new("ShaderNodeAttribute")
    lift.attribute_name = "lift"
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*look.srgb("#6E9FE8"), 1)
    ramp.color_ramp.elements[1].color = (*look.srgb("#FFFFFF"), 1)
    ramp.color_ramp.elements[1].position = 0.7
    mid = ramp.color_ramp.elements.new(0.3)
    mid.color = (*look.srgb("#D3E2FA"), 1)
    links.new(lift.outputs["Fac"], ramp.inputs[0])
    links.new(ramp.outputs["Color"], p.inputs["Base Color"])
    links.new(ramp.outputs["Color"], p.inputs["Emission Color"])
    p.inputs["Emission Strength"].default_value = 0.3
    look._fogged(mat, p.outputs[0])
    return mat


def haze_paint():
    """The haze under the cloud, its own light: deep blue under the eye, paling with distance to the horizon's own
    colour, so the sky has no line where it ends and nothing under the floor reads as ground or water."""
    mat = bpy.data.materials.new("Haze")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    place, far, span, ramp, glow, end = (nodes.new(kind) for kind in (
        "ShaderNodeNewGeometry", "ShaderNodeVectorMath", "ShaderNodeMapRange", "ShaderNodeValToRGB", "ShaderNodeEmission",
        "ShaderNodeOutputMaterial"))
    far.operation = "LENGTH"
    span.inputs["From Min"].default_value, span.inputs["From Max"].default_value = HAZE[0][0], HAZE[-1][0]
    ramp.color_ramp.elements[0].color = (*look.srgb(HAZE[0][1]), 1)
    ramp.color_ramp.elements[1].color = (*look.srgb(HAZE[-1][1]), 1)
    for at, colour in HAZE[1:-1]:
        stop = ramp.color_ramp.elements.new((at - HAZE[0][0]) / (HAZE[-1][0] - HAZE[0][0]))
        stop.color = (*look.srgb(colour), 1)
    links.new(place.outputs["Position"], far.inputs[0])
    links.new(far.outputs["Value"], span.inputs["Value"])
    links.new(span.outputs["Result"], ramp.inputs[0])
    links.new(ramp.outputs["Color"], glow.inputs["Color"])
    links.new(glow.outputs[0], end.inputs["Surface"])
    return mat


def cloud_sea(scene):
    """What the sky's lower half shows: a floor of haze far below, and cloud heads standing apart over it, in three
    layers (SEA_LAYERS). A head is a low dome with billows heaped on its top, white above and the haze's blue at its
    foot. Every top is under the floor's level."""
    rng = random.Random(56)

    def ball(cuts):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=cuts, radius=1.0)
        verts = np.array([v.co[:] for v in bm.verts], np.float32)
        tris = np.array([[v.index for v in f.verts] for f in bm.faces], np.int64)
        bm.free()
        return verts, tris

    verts, faces, lifts, count = [], [], [], 0
    for layer in SEA_LAYERS + tuple(SEA_EXTRA):
        middles, sizes, feet = [], [], []
        r0, r1 = layer["reach"]
        made = 0
        while made < layer["heads"]:
            a, r = rng.uniform(0, 2 * math.pi), r0 + (r1 - r0) * rng.random() ** (1.0 if "under" in layer else 1.3)
            x, y, eye = r * math.cos(a), r * math.sin(a), EYE
            if "eye" in layer:                                 # laid by sight from another eye: r is the way from it
                a = math.radians(90.0 + (a / math.pi - 1.0) * layer["fan"])
                x, y, eye = layer["eye"][0] + r * math.cos(a), layer["eye"][1] + r * math.sin(a), layer["eye"][2]
                if math.hypot(x, y) < layer["clear"]:
                    continue                                   # never under the tower itself
            elif r < SEA_LAYERS[0]["reach"][1] and abs(math.degrees(a) - 90.0) < SEA_GAP:
                continue                                       # the foe's way in keeps the deep haze behind it
            made += 1
            if "under" in layer:
                wide, tall = r * rng.uniform(*layer["wide"]), r * rng.uniform(*layer["tall"])
                top = eye - r * math.tan(math.radians(rng.uniform(*layer["under"])))
            else:
                grow = 1.0 + (r - r0) / (r1 - r0) * 0.6
                wide, tall = rng.uniform(*layer["wide"]) * grow, rng.uniform(*layer["tall"])
                top = rng.uniform(*layer["top"])
            foot = top - tall
            middle = Vector((x, y, foot + tall * 0.45))
            lumps = [(middle, (wide * 0.5, wide * 0.5 * rng.uniform(0.7, 1.0), tall * 0.45))]
            for _ in range(layer["puffs"]):
                turn, lift = rng.uniform(0, 2 * math.pi), math.radians(rng.uniform(15.0, 80.0))
                puff = wide * rng.uniform(0.12, 0.24)
                out = Vector((math.cos(turn) * math.cos(lift) * wide * 0.42, math.sin(turn) * math.cos(lift) * wide * 0.42,
                              math.sin(lift) * tall * 0.4))
                at = middle + out
                at.z = min(at.z, top - puff * 0.8)
                lumps.append((at, (puff, puff, puff * 0.8)))
            for at, size in lumps:
                middles.append(tuple(at))
                sizes.append(size)
                feet.append((foot, tall))
        unit, tris = ball(layer["cuts"])
        middles, sizes, feet = np.array(middles, np.float32), np.array(sizes, np.float32), np.array(feet, np.float32)
        pts = unit[None] * sizes[:, None, :] + middles[:, None, :]
        lifts.append(np.clip((pts[..., 2] - feet[:, None, 0]) / feet[:, None, 1], 0, 1).reshape(-1))
        verts.append(pts.reshape(-1, 3))
        faces.append((tris[None] + (count + np.arange(len(middles)) * len(unit))[:, None, None]).reshape(-1, 3))
        count += len(middles) * len(unit)
    mesh = bpy.data.meshes.new("CloudSea")
    mesh.from_pydata(np.concatenate(verts).tolist(), [], np.concatenate(faces).tolist())
    mesh.polygons.foreach_set("use_smooth", [True] * len(mesh.polygons))
    mesh.attributes.new("lift", "FLOAT", "POINT").data.foreach_set("value", np.concatenate(lifts))
    mesh.materials.append(cloud_paint())
    obj = bpy.data.objects.new("CloudSea", mesh)
    obj.visible_shadow = False
    scene.collection.objects.link(obj)
    reach, level = SEA_REACH * 1.6, SEA - 30.0
    sheet = bpy.data.meshes.new("Haze")                        # one sheet: a floor of wedges showed a seam between two
    sheet.from_pydata([(-reach, -reach, level), (reach, -reach, level), (reach, reach, level), (-reach, reach, level)], [], [(0, 1, 2, 3)])
    sheet.materials.append(haze_paint())
    floor = bpy.data.objects.new("Haze", sheet)
    floor.visible_shadow = False
    scene.collection.objects.link(floor)
    return [obj, floor]


class Built:
    pass


def mesh_of(piece, name, material):
    data = piece.mesh.whole().to_object(name, material)
    if getattr(piece, "smooth", False):
        for p in data.polygons:
            p.use_smooth = True
    return data


def build(out: Path, room=True):
    wear()
    d = light()
    scene = bl.reset_scene()
    maps = out / "maps"
    write_pictures(maps)
    b = Built()
    b.scene, b.d, b.objects, b.steps, b.slab, b.drifts = scene, d, [], [], None, []
    mats = {name: kit.kit_material(maps, name, prefix=PREFIX, glow=glow) for name, glow in MAPS.items()}
    if room:
        made = {}
        for name, tag, x, y, z, turn, scale in plan():
            if name not in made:
                piece = PIECES[name]()
                made[name] = (piece, mesh_of(piece, name, mats[piece.maps]))
            piece, data = made[name]
            obj = bpy.data.objects.new(f"{name}_{tag}", data)
            obj.location, obj.rotation_euler, obj.scale = (x, y, z), (0, 0, math.radians(turn)), (scale,) * 3
            if name.startswith(("CloudDrift", "CrownFloor")):
                obj.visible_shadow = False
            scene.collection.objects.link(obj)
            b.objects.append(obj)
            if tag.startswith("Foe"):
                b.steps.append(obj)
            if tag.startswith("Drift"):
                b.drifts.append((obj, x, DRIFTS[int(tag[5:])][6]))
            if name == "CrownSlab":
                b.slab = obj
        lit = look.glowing("Numeral", "#FFF8EA", 2.4)
        for words, side in ((str(SHOWN), -1), (str(SHOWN + 1), 1)):                 # the next number waits on the back
            curve = bpy.data.curves.new("Numeral", "FONT")
            curve.body, curve.size, curve.align_x, curve.align_y, curve.extrude = words, 7.6, "CENTER", "CENTER", 0.04
            curve.materials.append(lit)
            text = bpy.data.objects.new(f"Numeral{words}", curve)
            text.parent = b.slab
            text.location, text.rotation_euler = (0.0, side * 1.0, 2.4), (math.pi / 2, 0.0, 0.0 if side < 0 else math.pi)
            scene.collection.objects.link(text)
    b.sea = cloud_sea(scene)
    look.sky(scene, d)
    look.sun(scene, d)
    kit.eevee(scene, block.SIZE, 16)
    data = bpy.data.cameras.new("Player")
    data.sensor_fit, data.angle_y, data.clip_end = "VERTICAL", math.radians(look.FOV), FAR
    b.cam = bpy.data.objects.new("Player", data)
    scene.collection.objects.link(b.cam)
    scene.camera = b.cam
    return b


# --- the figures: coloured stand-ins ---------------------------------------------------------------------------------------

LEADS = {"pale": ("#F2ECE0", "#C9CEDA", "#F2D2B6"), "warm": ("#D8523C", "#3A3550", "#F2D2B6"), "dark": ("#2E3A66", "#1E2440", "#E6C2A2")}
FOE = ("#3A2A66", "#241A44", "#B79CFF")           # a Voidkin darkened, a void light at its head: violet is the foe's
AVATAR = ("#6C7480", "#4E5560", "#E6C8AC")
LEAD_AT, FOE_AT = (-4.5, -1.0), (4.0, 4.5)             # mid fight


class Figure:
    def __init__(self, scene, name, colours, scale=1.0, glow=0.0):
        body, legs, head = colours
        self.parts = []
        for part, size, z, code in (("Legs", (2.0, 1.0, 2.0), 0.0, legs), ("Body", (4.0, 1.0, 2.0), 2.0, body), ("Head", (1.2, 1.2, 1.2), 4.0, head)):
            mat = look.glowing(name + part, code, glow, base=code) if glow and part == "Head" else look.painted(name + part, code, code)
            obj = tb.solid(scene, name + part, block.box(*(s * scale for s in size)), mat)
            self.parts.append((obj, z * scale))

    def at(self, x, y, z=0.0, show=True):
        for obj, up in self.parts:
            obj.location, obj.hide_render = (x, y, z + up), not show


def cast(b, lead="pale"):
    b.avatar = Figure(b.scene, "Avatar", AVATAR)
    b.leads = {key: Figure(b.scene, "Lead" + key, colours, 1.15) for key, colours in LEADS.items()}
    b.foe = Figure(b.scene, "Foe", FOE, 1.15, glow=1.6)
    fight(b, lead)


def steps_at(b, up):
    """The foe's steps: 0 at rest under the rim, 1 risen to their places."""
    for obj, at, rest in zip(b.steps, FOE_STEPS, BEAT["rest"]):
        obj.location = (at[0], at[1], at[2] + rest * (1 - up))


def fight(b, lead="pale"):
    steps_at(b, 0.0)
    b.avatar.at(0.0, -STAND)
    for key, fig in b.leads.items():
        fig.at(*LEAD_AT, show=key == lead)
    b.foe.at(*FOE_AT)
    return (0.0, -STAND, 0.0)


def shot(b, eye, target, path, size=block.SIZE):
    """A frame from `eye` toward `target`. The sun's shadows come out soft whatever is set (their filter, their
    resolution, the depth drawn): the engine draws them firm."""
    b.cam.location = eye
    b.cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    b.scene.render.resolution_x, b.scene.render.resolution_y = size
    exr = path.with_suffix(".exr")
    rs.save(look.finish(look.render_linear(b.scene, exr), b.d), path)
    exr.unlink(missing_ok=True)


def looks(out, only=()):
    b = build(out)
    cast(b)
    foot = -STEP_DOWN + 0.28
    views = {"enter": block.behind(0.0, -54.0, foot, 20.0), "fight": block.behind(0.0, -STAND, 0.0, 20.0),
             "up": block.behind(0.0, -STAND, 0.0, -8.0), "whole": (Vector((105.0, -135.0, 70.0)), Vector((0.0, 0.0, 6.0))),
             "above": (Vector((0.0, -0.5, 150.0)), Vector((0.0, 0.0, 0.0)))}
    for name, (eye, target) in views.items():
        if only and name not in only:
            continue
        fight(b)
        steps_at(b, 1.0 if name in ("whole", "above") else 0.0)
        if name == "enter":
            b.avatar.at(0.0, -54.0, foot)
            b.leads["pale"].at(3.5, -51.5, foot)
            b.foe.at(0.0, STAND)
        shot(b, eye, target, out / f"crown_{name}.png")
    for key in LEADS:
        if only and "leads" not in only:
            continue
        avatar = fight(b, key)
        shot(b, *block.behind(*avatar, 20.0), out / f"crown_lead_{key}.png")
    count = {name: PIECES[name]().mesh.whole().tris() for name in PIECES}
    stood = {}
    for name, *_ in plan():
        stood[name] = stood.get(name, 0) + 1
    record = dict(pieces=count, stood=stood, parts=sum(stood.values()),
                  triangles=sum(count[name] * n for name, n in stood.items()))
    (out / "crown.json").write_text(json.dumps(record, indent=1), encoding="utf-8", newline="\n")
    print("AR56: looks done", record)


# --- the stand raised: research's grey test ----------------------------------------------------------------------------

# The fight's frame with the player's stand on a grey dais (AR56, "Research's second look"): from the floor the far rim
# hides everything more than 7 degrees under the horizon, so no cloud can read as far below; a raised eye clears it.
# Each: the dais's height, how far from the middle the stand is (the room's is STAND), and how far off the lane.
STAND_TEST = ((0.0, STAND, 0.0), (6.0, STAND, 0.0), (12.0, STAND, 0.0), (12.0, 30.0, -9.0), (6.0, 30.0, 0.0), (12.0, 30.0, 0.0))


def band(height, back):
    """How many degrees under the horizon the fight's camera sees past the far rim, from a stand that high and far back."""
    eye, _ = block.behind(0.0, -back, height, 20.0)
    return math.degrees(min(math.atan2(eye.z, FLOOR_R - eye.y), math.atan2(eye.z + STEP_DOWN, STEP_R - eye.y)))


def grey_sheet(out, file, title, tiles, notes, cols=3):
    """A grey test's page: its frames at half size, each under its line, and the notes."""
    import ui_sheet as ui

    gap = 14
    tw, th = block.SIZE[0] // 2, block.SIZE[1] // 2
    rows = -(-len(tiles) // cols)
    text = [ln for n in notes for ln in textwrap.wrap(n, 63 * cols)]
    ui.K = 1
    page = ui.Sheet(gap + cols * (tw + gap), 52 + rows * (th + 22 + gap) + 16 + len(text) * 19, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, title, "#EDE6D6", bold=0.2)
    for k, (name, said) in enumerate(tiles):
        x, y = gap + (k % cols) * (tw + gap), 48 + (k // cols) * (th + 22 + gap)
        t.text(x, y, 13, said, "#EDE6D6")
        rs.paste(page.px, rs.shrink(rs.load(out / f"{name}.png"), 0.5), x, y + 20)
    for n, ln in enumerate(text):
        t.text(gap, 48 + rows * (th + 22 + gap) + 4 + n * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / file)


def stand_test(out):
    b = build(out)
    cast(b)
    grey = look.painted("StandIn", "#A2A2A2", "#6C6C6C")
    tiles = []
    for height, back, side in STAND_TEST:
        fight(b)
        b.avatar.at(side, -back, height)
        dais = None
        if height:
            dais = tb.solid(b.scene, "StandIn", tb.sector(0.0, 4.0, 0.0, height, n=24), grey)
            dais.location = (side, -back, 0.0)
        name = f"crown_stand_{back:g}_{height:g}" + ("_side" if side else "")
        shot(b, *block.behind(side, -back, height, 20.0), out / f"{name}.png")
        if dais:
            dais.hide_render = True
        tiles.append((name, f"the stand {height:g} up, {back:g} from the middle{f', {abs(side):g} off the lane' if side else ''}: "
                      f"{band(height, back):.1f} degrees under the horizon seen"
                      if height else f"as it stands, on the floor: {band(height, back):.1f} degrees under the horizon seen"))
    notes = [
        "Research's grey test (AR56, the second look): the fight's frame with the player's stand raised on a grey dais, the camera "
        "the player's own (12.5 studs behind the avatar, 20 degrees down, FOV 70), at the smallest phone's size. The room, the "
        "fighters and the sky are the finish's, unchanged; only the dais is new, a grey cylinder 8 across.",
        f"The first row is the stand where the room has it, {STAND:g} studs from the middle. The second row is my own addition, the "
        "same dais set back to 30 studs from the middle, toward the entrance: it keeps the fighters clear of the dais and the "
        "avatar, at the cost of a narrower band and smaller fighters. Its first frame also sets the dais 9 studs off the lane, the "
        "camera still looking straight up the room, so the fighters stand beside the avatar and not behind it.",
    ]
    grey_sheet(out, "crown_stand.png", "Grow your Anime, the Tower's room (AR56): the player's stand raised, a grey test", tiles, notes)
    print("AR56: stand done", [(h, back, side, round(band(h, back), 1)) for h, back, side in STAND_TEST])


# --- the height at the door: research's second grey test ---------------------------------------------------------------

# The drop given to the way in (AR56, "Research's read of the stand test"): the player arrives on a landing over the
# entrance's end and walks down steps to the floor, where the fight's frame stays as it passed. Grey stand-ins.
# The landing's middle along the lane and its height; its slab; the steps' count and a tread (wide, deep, thick).
LANDING = dict(at=-76.0, up=12.0, slab=(14.0, 12.0, 1.2), steps=11, tread=(8.0, 2.4, 0.6))
# Cloud laid by sight from the landing's eye: what research asked (8 to 14 degrees under the horizon), and a few deeper,
# close in, for the frame's lower corners (mine). `fan`: degrees either side of the lane; `clear`: never this near the shaft.
LANDING_CLOUD = (dict(heads=46, reach=(260.0, 680.0), under=(8.0, 14.0), tall=(0.02, 0.036), wide=(0.07, 0.15), cuts=3, puffs=8,
                      fan=80.0, clear=110.0),
                 dict(heads=12, reach=(130.0, 330.0), under=(15.0, 24.0), tall=(0.03, 0.05), wide=(0.1, 0.2), cuts=3, puffs=8,
                      fan=75.0, clear=110.0))


def past_rim(eye, off):
    """Degrees under the horizon seen past the step ring's far edge, from `eye`, looking `off` degrees off the lane; None
    where the look misses the room altogether."""
    back, s = -eye.y, math.sin(math.radians(off))
    inside = STEP_R ** 2 - (back * s) ** 2
    if inside < 0:
        return None
    return math.degrees(math.atan2(eye.z + STEP_DOWN, back * math.cos(math.radians(off)) + math.sqrt(inside)))


def landing_test(out):
    at, up = LANDING["at"], LANDING["up"]
    eye, _ = block.behind(0.0, at, up, 20.0)
    SEA_EXTRA.extend(dict(layer, eye=(eye.x, eye.y, eye.z)) for layer in LANDING_CLOUD)
    b = build(out)
    cast(b)
    grey = look.painted("StandIn", "#A2A2A2", "#6C6C6C")
    w, d, h = LANDING["slab"]
    slab = tb.solid(b.scene, "Landing", block.box(w, d, h), grey)
    slab.location = (0.0, at, up - h)
    made = [slab]
    front, (tw, td, th) = at + d / 2, LANDING["tread"]
    run = (-FLOOR_R - 1.0 - front) / (LANDING["steps"] - 1) if LANDING["steps"] > 1 else 0.0
    drop = up / (LANDING["steps"] + 1)

    def tread(k):
        return front + 1.0 + k * run, up - (k + 1) * drop

    for k in range(LANDING["steps"]):
        y, top = tread(k)
        step = tb.solid(b.scene, f"Tread{k}", block.box(tw, td, th), grey)
        step.location = (0.0, y, top - th)
        made.append(step)
    mid = LANDING["steps"] // 2
    foot = -STEP_DOWN + 0.28
    frames = (
        ("today", "today: in on the step ring", (0.0, -54.0, foot), (3.5, -51.5, foot), False),
        ("arrive", f"arriving on the landing, {up:g} up", (0.0, at, up), (3.5, at + 2.5, up), True),
        ("steps", "halfway down the steps", (0.0, *tread(mid)), (3.0, *tread(mid + 1)), True),
        ("fight", "the fight's frame, from the floor", None, None, True),
        ("whole", "the room with its landing", None, None, True),
    )
    tiles = []
    for name, said, avatar, lead, shown in frames:
        fight(b)
        for obj in made:
            obj.hide_render = not shown
        if avatar:
            b.avatar.at(*avatar)
            b.leads["pale"].at(*lead)
            b.foe.at(0.0, STAND)
            view = block.behind(*avatar, 20.0)
        elif name == "fight":
            view = block.behind(0.0, -STAND, 0.0, 20.0)
        else:
            steps_at(b, 1.0)
            view = (Vector((125.0, -185.0, 80.0)), Vector((0.0, -22.0, 2.0)))
        shot(b, *view, out / f"crown_landing_{name}.png")
        tiles.append((f"crown_landing_{name}", said))
    walk = (-STAND - at, -STAND + 54.0)
    seen = {off: past_rim(eye, off) for off in (0, 20, 30, 40)}
    notes = [
        "Research's second grey test (AR56, the read of the stand test): the height at the door. The player arrives on a landing "
        f"{up:g} studs up over the entrance's end, {-at - STEP_R:g} studs out past the step ring, and walks down {LANDING['steps']} "
        "steps to the floor, where the fight is as it passed. The landing and the steps are grey stand-ins; the room, the fighters "
        "and the camera are the finish's (12.5 studs behind the avatar, 20 degrees down, FOV 70), at the smallest phone's size.",
        f"From the landing the far rim hides everything more than {seen[0]:.1f} degrees under the horizon straight up the lane, "
        f"{seen[20]:.1f} at 20 degrees off it, {seen[30]:.1f} at 30 and {seen[40]:.1f} at 40; past about "
        f"{math.degrees(math.asin(STEP_R / -eye.y)):.0f} degrees off the lane the look misses the room and nothing hides the drop. "
        "The cloud added for this test lies 8 to 14 degrees under the horizon from the landing's eye (research's ask), with a few "
        "heads deeper and closer for the frame's lower corners (mine). In the game the sky is six pictures with no depth, so these "
        "heads would be painted at those angles.",
        f"The walk from the landing to the stand is {walk[0]:g} studs, against {walk[1]:g} today from the step ring: "
        f"{walk[0] - walk[1]:g} more, about {(walk[0] - walk[1]) / 16:.1f} s at 16 studs a second.",
    ]
    grey_sheet(out, "crown_landing.png", "Grow your Anime, the Tower's room (AR56): the height at the door, a grey test", tiles, notes)
    print("AR56: landing done", {k: round(v, 1) for k, v in seen.items()}, walk)


# --- the climb's beat ------------------------------------------------------------------------------------------------------

def ease(u):
    u = tb.clamp(u)
    return u * u * (3 - 2 * u)


def back(u, over=0.18):
    """Ease out with a small overshoot at its end."""
    u = tb.clamp(u)
    return 1 + (over * 10 + 1) * (u - 1) ** 3 + over * 10 * (u - 1) ** 2


def beat_at(b, t):
    """Everything `t` seconds after a win: the old foe gone, the slab turning, the steps rising, the next foe coming."""
    b.slab.rotation_euler = (0.0, 0.0, math.pi * ease(tb.span(t, *BEAT["turn"])))
    for obj, x, speed in b.drifts:
        obj.location.x = x + speed * (t - BEAT["span"][0])
    places = []
    for k, (obj, at, rest) in enumerate(zip(b.steps, FOE_STEPS, BEAT["rest"])):
        start = BEAT["first"] + BEAT["stagger"] * (len(FOE_STEPS) - 1 - k)
        up = back(tb.span(t, start, start + BEAT["rise"])) - ease(tb.span(t, *BEAT["sink"]))
        obj.location = (at[0], at[1], at[2] + rest * (1 - up))
        places.append(Vector(obj.location))
    stops = places[::-1] + [Vector((0.0, FLOOR_R + 6.0, 0.0))]                         # the farthest step first, then the rim
    if t < 0.0:
        b.foe.at(*FOE_AT)
    elif t < BEAT["first"]:
        b.foe.at(0, 0, 0, show=False)
    elif t < BEAT["climb"][0]:
        b.foe.at(*stops[0])                                   # it comes up into sight on the farthest step
    elif t < BEAT["climb"][1]:
        u = tb.span(t, *BEAT["climb"]) * (len(stops) - 1)
        k = min(int(u), len(stops) - 2)
        f = u - k
        p = stops[k].lerp(stops[k + 1], ease(f))
        b.foe.at(p.x, p.y, p.z + 3.0 * math.sin(math.pi * f))
    else:
        u = tb.span(t, *BEAT["leap"])
        p = stops[-1].lerp(Vector((0.0, STAND, 0.0)), u)
        b.foe.at(p.x, p.y, p.z + 9.0 * math.sin(math.pi * u) * (1 - u * 0.2))


def beat(out):
    b = build(out)
    cast(b)
    avatar = fight(b)
    folder = out / "beat"
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob("f*.png"):
        old.unlink()
    a, z = BEAT["span"]
    for i in range(round((z - a) * block.RATE) + 1):
        beat_at(b, a + i / block.RATE)
        shot(b, *block.behind(*avatar, 20.0), folder / f"f{i:03d}.png", block.TAKE)
    print("AR56: beat done")


def movie(out):
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = *block.TAKE, 100
    scene.render.fps = 30
    folder = out / "beat"
    shots = sorted(folder.glob("f*.png"))
    files = [s.name for s in shots for _ in range(30 // block.RATE)] + [shots[-1].name] * 30
    se = scene.sequence_editor_create()
    strips = se.strips if hasattr(se, "strips") else se.sequences
    first = strips.new_image("Frames", str(folder / files[0]), 1, 1)
    first.directory = str(folder) + "/"
    first.elements[0].filename = files[0]
    for name in files[1:]:
        first.elements.append(name)
    scene.frame_start, scene.frame_end = 1, len(files)
    settings = scene.render.image_settings
    if hasattr(settings, "media_type"):
        settings.media_type = "VIDEO"
    settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format, scene.render.ffmpeg.codec = "MPEG4", "H264"
    scene.render.ffmpeg.constant_rate_factor = "HIGH"
    scene.render.filepath = str(out / "crown_beat.mp4")
    bpy.ops.render.render(animation=True)


# --- the sheet -------------------------------------------------------------------------------------------------------------

BEATS = (("the win", -0.07), ("the slab turns", 0.27), ("the steps rise, the foe on the far one", 0.67), ("the foe climbs", 1.27),
         ("over the rim", 1.73), ("the leap", 2.07), ("set down", 2.4), ("the steps sink", 2.87))


def sheet(out):
    import ui_sheet as ui

    gap = 14
    tw, th = block.SIZE[0] // 2, block.SIZE[1] // 2                     # the smallest phone
    qw, qh = block.TAKE[0] // 2, block.TAKE[1] // 2
    m = json.loads((out / "crown.json").read_text(encoding="utf-8"))
    rows = [[("crown_enter", "as the player steps in"), ("crown_fight", "a fight's frame"), ("crown_up", "the camera tilted 8 degrees up")],
            [("crown_whole", "the room whole"), ("crown_above", "from above"), None],
            [(f"crown_lead_{key}", f"the fighters: a {key} lead") for key in LEADS]]
    notes = [
        "Each frame is the smallest phone's size, 568 x 320, from the player's camera (12.5 studs behind the avatar, 20 degrees down, "
        "FOV 70) but the room whole and from above, which show the foe's steps risen. The figures are coloured boxes: the avatar grey, the lead, the foe a "
        "darkened Voidkin with a void light at its head (the only violet). The numerals are text on the slab.",
        "1, air: past the far rim the eye looks down through cloud. The haze under it is deep blue at the rim and pales to the "
        "horizon with no line; the cloud heads stand apart, small near ones low in the blue, the far deck at the "
        "horizon and a low layer under the room, every top under this floor; drifts pass at the rim's height (they move in the take); no lower tower, "
        "whose blades read as spikes from here. "
        "2, the floor: a heart of stone at a mid value where the fight is, so a pale lead and a dark one both "
        "stand off it, a deck of sea-grey steel round it, a lane from the entrance to the foe's steps with a line of light down "
        "each edge, the stands' ring and two pads, and a conduit from each blade's foot round to the lane. The blades' shadows "
        "lie across it (soft here; the engine draws them firm). "
        "3, the fighters: the third row, the same frame with a pale, a warm and a dark lead. "
        "4, the beat: the last rows, the slab's half turn to the next number, the four steps rising into sight past the far rim, "
        "the next foe on the farthest, its hops up them and its leap in.",
        f"The kit: {len(m['pieces'])} meshes, {m['parts']} parts a room, {m['triangles']} triangles a room (the cloud and the haze are the "
        "sky's six faces and cost none). Two pairs of pictures, the kit's atlas and the floor's quarter.",
    ]
    text = [ln for n in notes for ln in textwrap.wrap(n, 190)]
    per = 4
    beat_rows = math.ceil(len(BEATS) / per)
    width = gap + max(3 * (tw + gap), per * (qw + gap))
    height = 52 + 3 * (th + 22 + gap) + beat_rows * (qh + 22 + gap) + 16 + len(text) * 19
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "Grow your Anime, the Tower's room (AR56): the Crown, the finish's look", "#EDE6D6", bold=0.2)
    y = 48
    for row in rows:
        for c, cell in enumerate(row):
            if cell:
                x = gap + c * (tw + gap)
                t.text(x, y, 13, cell[1], "#EDE6D6")
                rs.paste(page.px, rs.shrink(rs.load(out / f"{cell[0]}.png"), 0.5), x, y + 20)
        y += th + 22 + gap
    shots = sorted((out / "beat").glob("f*.png"))
    a = BEAT["span"][0]
    for k, (said, at) in enumerate(BEATS):
        x, yy = gap + (k % per) * (qw + gap), y + (k // per) * (qh + 22 + gap)
        t.text(x, yy, 13, f"{said}, {at:+.2f} s", "#EDE6D6")
        rs.paste(page.px, rs.shrink(rs.load(shots[min(len(shots) - 1, round((at - a) * block.RATE))]), 0.5), x, yy + 20)
    y += beat_rows * (qh + 22 + gap)
    for n, ln in enumerate(text):
        t.text(gap, y + 4 + n * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "crown.png")
    # the read at 64 pixels high, over dark, shown three times over
    small, blow = 64, 3
    sw = round(block.SIZE[0] * small / block.SIZE[1])
    names = ("crown_enter", "crown_fight", "crown_lead_dark", "crown_whole", "crown_above")
    page = ui.Sheet(gap + len(names) * (sw * blow + gap), 44 + small * blow + gap, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 12, 16, "The Crown (AR56): the read at 64 pixels high", "#EDE6D6", bold=0.2)
    for k, name in enumerate(names):
        px = rs.shrink(rs.load(out / f"{name}.png"), small / block.SIZE[1])
        rs.paste(page.px, np.repeat(np.repeat(px, blow, axis=0), blow, axis=1), gap + k * (sw * blow + gap), 40)
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "crown_64.png")


# --- the lot: the entrance behind the base, and the record's marker --------------------------------------------------------

# The far end of the Crown, small: two of its blades, the number's slab between their heads, and under it a door of
# light where the foe would stand. The slab carries the owner's record floor, so a visitor reads how high they have
# climbed. The lot's frame: its middle at the ground, the base and its path at -Y. The Tower's footprint is 32 studs.
GATE_SCALE = 0.55
RECORD = 24
# The slab's middle and size: its number is whole in the player's frame from 44 studs off, the base's way out, since
# the frame's top is 15 degrees over the horizon; and it stands clear over the base's wall (5 studs) from inside.
RECORD_AT, RECORD_SCALE = 15.2, 0.66
DOOR = ((-3.0, 0.95), (3.0, 0.95), (3.4, 6.2), (0.0, 8.6), (-3.4, 6.2))
VEIL = 0.55                                        # the door's pane: how much of what is behind shows through it
BACK_WALL, WAY_OUT = -32.0, 8.0                    # the base's back wall from the lot's middle, and half its way out
LOT = (("GateDais", "", 0.0, 0.0, 0.0, 0.0, 1.0), ("GateVeil", "", 0.0, 1.0, 0.0, 0.0, 1.0),
       ("CrownBlade", "GateL", -9.0, 1.5, 0.6, 20.0, GATE_SCALE), ("CrownBlade", "GateR", 9.0, 1.5, 0.6, -20.0, GATE_SCALE),
       ("CrownSlab", "Record", 0.0, 1.0, RECORD_AT, 0.0, RECORD_SCALE))


def gate_dais():
    """The entrance's foot: a round dais of the Crown's sand stone, one step up, a ring of light in its well, and the
    lane's two lines from its front edge to the door's sill."""
    m = kit.Mesh()
    m.lathe([(11.0, 0.6), (11.0, 0.3), (13.0, 0.3), (13.0, 0.0)], (0, 0, 0), 48, "sand", occ=0.25, caps=True)
    for r0, r1, z, sw in ((9.2, 10.2, 0.63, "well"), (9.56, 9.84, 0.66, "trail"), (10.45, 10.75, 0.63, "girder")):
        m.lathe([(r0, z), (r1, z)], (0, 0, 0), 48, sw, caps=False)
    for sx in (-1, 1):
        for half, z, sw in ((0.42, 0.64, "well"), (0.12, 0.67, "trail")):
            x = sx * 2.4
            plate(m, [(x - half, -9.3, z), (x + half, -9.3, z), (x + half, 0.4, z), (x - half, 0.4, z)], sw, t=0.8)
    loft(m, [rect(7.6, 1.0, 0.6, (0.0, 1.0)), rect(7.2, 0.7, 0.95, (0.0, 1.0))], "girder", [0.2, 0.5, 0.6, 0.5], [0.4, 0.9],
         caps=(None, ("girder", 0.0, 1.0)), ink=True)                                    # the door's sill
    return kit.Piece("GateDais", m, solid="hull", note="the entrance's foot on the lot; its front faces the base's path")


def gate_veil():
    """The door: a pane of the Crown's own light, pointed at its head as the slab over it is pointed at its foot."""
    m = kit.Mesh(None)
    shape, top = DOOR, DOOR[3][1]
    for side in (-1, 1):
        pts = [Vector((x, side * 0.05, z)) for x, z in shape]
        m.face(pts if side < 0 else pts[::-1], [kit.sw_uv("trail", 0.0, 0.25 + 0.75 * z / top) for _, z in (shape if side < 0 else shape[::-1])])
    return kit.Piece("GateVeil", m, note="the door of light, both faces: Transparency about 0.55, CastShadow off, no "
                     "collision; stepping through it starts a run")


LOT_PIECES = {"GateDais": gate_dais, "GateVeil": gate_veil}


def veil_paint():
    """The door's pane for the stills, as the game shows it: the Crown's light, with the sky behind showing through."""
    mat = bpy.data.materials.new("GateVeil")
    mat.use_nodes = True
    mat.surface_render_method = "BLENDED"
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    glow, clear, mix, end = (nodes.new(kind) for kind in ("ShaderNodeEmission", "ShaderNodeBsdfTransparent", "ShaderNodeMixShader",
                                                          "ShaderNodeOutputMaterial"))
    glow.inputs["Color"].default_value, glow.inputs["Strength"].default_value = (*look.srgb("#FFF8EA"), 1), 1.1
    mix.inputs[0].default_value = VEIL
    links.new(glow.outputs[0], mix.inputs[1])
    links.new(clear.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], end.inputs["Surface"])
    return mat


def build_lot(out: Path):
    """The entrance on a stretch of the base's deck, in the game's day."""
    wear()
    tb.by_day()
    d = dict(look.DIRECTIONS["M"])
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0), away=None)
    scene = bl.reset_scene()
    maps = out / "maps"
    write_pictures(maps)
    mats = {name: kit.kit_material(maps, name, prefix=PREFIX, glow=glow) for name, glow in MAPS.items()}
    b = Built()
    b.scene, b.d, b.objects = scene, d, []
    made = {}
    for name, tag, x, y, z, turn, scale in LOT:
        if name not in made:
            piece = (LOT_PIECES.get(name) or PIECES[name])()
            made[name] = mesh_of(piece, name, mats[piece.maps])
        obj = bpy.data.objects.new(f"{name}_{tag}", made[name])
        obj.location, obj.rotation_euler, obj.scale = (x, y, z), (0, 0, math.radians(turn)), (scale,) * 3
        if name == "GateVeil":
            obj.visible_shadow = False
            obj.data.materials[0] = veil_paint()
        scene.collection.objects.link(obj)
        b.objects.append(obj)
        if name == "CrownSlab":
            lit = look.glowing("Numeral", "#FFF8EA", 2.4)
            for side in (-1, 1):                                              # the record, on both faces
                curve = bpy.data.curves.new("Numeral", "FONT")
                curve.body, curve.size, curve.align_x, curve.align_y, curve.extrude = str(RECORD), 7.6, "CENTER", "CENTER", 0.04
                curve.materials.append(lit)
                text = bpy.data.objects.new(f"Record{side}", curve)
                text.parent = obj
                text.location, text.rotation_euler = (0.0, side * 1.0, 2.4), (math.pi / 2, 0.0, 0.0 if side < 0 else math.pi)
                scene.collection.objects.link(text)
    tb.solid(scene, "Deck", block.box(260.0, 260.0, 1.0), look.painted("Deck", "#9EA7BC", "#9EA7BC")).location = (0, 0, -1.0)
    steel = look.painted("BackWall", "#B9C6CE", "#7E929E")
    for sx in (-1, 1):                                                        # the base's back wall as blocks, its way out between
        run = 64.0 - WAY_OUT
        tb.solid(scene, f"BackWall{sx}", block.box(run, 1.0, 5.1), steel).location = (sx * (WAY_OUT + run / 2), BACK_WALL, 0.0)
    look.sky(scene, d)
    look.sun(scene, d)
    kit.eevee(scene, block.SIZE, 16)
    data = bpy.data.cameras.new("Player")
    data.sensor_fit, data.angle_y, data.clip_end = "VERTICAL", math.radians(look.FOV), 4000
    b.cam = bpy.data.objects.new("Player", data)
    scene.collection.objects.link(b.cam)
    scene.camera = b.cam
    b.avatar = Figure(scene, "Avatar", AVATAR)
    return b


def lot_looks(out):
    b = build_lot(out)
    views = {"approach": (block.behind(0.0, BACK_WALL, 0.0, 20.0), (0.0, BACK_WALL)), "door": (block.behind(0.0, -9.0, 0.6, 20.0), (0.0, -9.0)),
             "visitor": ((Vector((-26.0, -27.0, 7.5)), Vector((0.0, 1.0, 9.5))), (-9.0, -13.0)),
             "far": (block.behind(0.0, BACK_WALL - 64.0, 0.0, 20.0), (0.0, BACK_WALL - 64.0)),
             "back": ((Vector((26.0, 44.0, 8.0)), Vector((0.0, 0.0, 9.0))), (-6.0, -12.0))}
    for name, ((eye, target), (x, y)) in views.items():
        b.avatar.at(x, y, 0.6 if name == "door" else 0.0)
        shot(b, eye, target, out / f"gate_{name}.png")
    count = {name: (LOT_PIECES.get(name) or PIECES[name])().mesh.whole().tris() for name in {row[0] for row in LOT}}
    record = dict(pieces=count, parts=len(LOT), triangles=sum(count[row[0]] for row in LOT))
    (out / "gate.json").write_text(json.dumps(record, indent=1), encoding="utf-8", newline="\n")
    print("AR56: lot done", record)


def lot_sheet(out):
    import ui_sheet as ui

    gap = 14
    tw, th = block.SIZE[0] // 2, block.SIZE[1] // 2
    m = json.loads((out / "gate.json").read_text(encoding="utf-8"))
    tiles = (("gate_approach", "through the base's way out, the player's camera"), ("gate_door", "at the door"),
             ("gate_visitor", "a visitor on the lot"), ("gate_far", "from the base's heart, over its back wall"),
             ("gate_back", "from behind"))
    notes = [
        "The entrance on the lot behind the base and the record's marker, in the Crown's language: two of the room's blades at "
        f"{GATE_SCALE:g} of their size, the number's slab between their heads carrying the owner's record floor on both faces, and "
        "under it a door of light on a round dais. A stretch of grey deck and blocks for the base's back wall stand in for the base.",
        f"Two new meshes (the dais and the door's pane, seen through in the game); the blades and the slab are the room's. {m['parts']} parts, "
        f"{m['triangles']} triangles. The numerals are text. Each frame is the smallest phone's size, 568 x 320, in the game's day.",
    ]
    text = [ln for n in notes for ln in textwrap.wrap(n, 190)]
    ui.K = 1
    page = ui.Sheet(gap + 3 * (tw + gap), 52 + 2 * (th + 22 + gap) + 16 + len(text) * 19, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "Grow your Anime, the Tower's entrance and record marker (AR56), in the Crown's language", "#EDE6D6", bold=0.2)
    for k, (name, said) in enumerate(tiles):
        x, y = gap + (k % 3) * (tw + gap), 48 + (k // 3) * (th + 22 + gap)
        t.text(x, y, 13, said, "#EDE6D6")
        rs.paste(page.px, rs.shrink(rs.load(out / f"{name}.png"), 0.5), x, y + 20)
    for n, ln in enumerate(text):
        t.text(gap, 48 + 2 * (th + 22 + gap) + 4 + n * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "gate.png")


# --- the handoff -------------------------------------------------------------------------------------------------------------

def skies(out: Path):
    """The room's sky as Roblox's six faces, from the floor's middle at a player's eye: the painted sky over the
    horizon, the cloud sea under it."""
    b = build(out.parent, room=False)
    kit.eevee(b.scene, (kit.SKY_PX, kit.SKY_PX), 16)
    cam = bpy.data.objects.new("SkyCam", bpy.data.cameras.new("SkyCam"))
    cam.data.sensor_fit, cam.data.angle, cam.data.clip_end = "HORIZONTAL", math.radians(90.0), 12000
    cam.location = (0.0, 0.0, 6.0)
    b.scene.collection.objects.link(cam)
    b.scene.camera = cam
    rng = np.random.default_rng(3)
    for face, (ahead, top) in kit.FACES.items():
        from mathutils import Matrix
        f, u = Vector(ahead), Vector(top)
        cam.rotation_euler = Matrix((f.cross(u), u, -f)).transposed().to_euler()
        linear = look.render_linear(b.scene, out / "_sky.exr")
        page = np.ones((kit.SKY_PX, kit.SKY_PX, 4), np.float32)
        page[..., :3] = kit.encode(linear[..., :3] * b.d["exposure"]) + (rng.random((kit.SKY_PX, kit.SKY_PX, 1), np.float32) - 0.5) / 255
        rs.save(np.clip(page, 0, 1), out / f"{PREFIX}_Sky_{face}.png")
    (out / "_sky.exr").unlink(missing_ok=True)
    return b.d


def export(out: Path):
    wear()
    folders = {name: out / name for name in ("meshes", "maps")}
    for f in folders.values():
        f.mkdir(parents=True, exist_ok=True)
    d = skies(folders["maps"])
    scene = bl.reset_scene()
    write_pictures(folders["maps"])
    listing = {}
    for name, make in {**PIECES, **LOT_PIECES}.items():
        piece = make()
        obj = bpy.data.objects.new(name, mesh_of(piece, name, None))
        scene.collection.objects.link(obj)
        tris = bl.export_mesh_json(obj, folders["meshes"] / f"{name}.json", uv=True)
        record = json.loads((folders["meshes"] / f"{name}.json").read_text())
        ps = np.array(record["p"], np.float32).reshape(-1, 3)
        tint, strength = MAPS[piece.maps]
        listing[name] = dict(
            mesh=f"meshes/{name}.json", triangles=tris, vertices=len(ps), centre=record["c"],
            size=[round(float(v), 3) for v in ps.max(0) - ps.min(0)],
            colour=f"maps/{PREFIX}_{piece.maps}_Color.png", glow=f"maps/{PREFIX}_{piece.maps}_Glow.png",
            glowTint=tint, glowStrength=strength, collision=piece.solid, note=piece.note)
    manifest = dict(
        what="AR56: the Tower's room, the Crown. Made and laid as the base's kit is.",
        unit="1 = 1 stud",
        frame="Roblox's: a piece's front (Blender +Y) is -Z. A MeshPart goes at the piece's place times `centre`.",
        surface="one SurfaceAppearance per MeshPart: ColorMap `colour`, EmissiveMaskContent `glow`, EmissiveTint `glowTint`, "
                "EmissiveStrength from `glowStrength` (tuned in the engine). Single sided: a piece's ink is in its mesh, a "
                "hull turned inside out on the atlas's ink texel.",
        shadows="CastShadow off on the four floor parts and on every CloudDrift; on for the blades, whose shadows across "
                "the floor are part of the look.",
        pieces=listing)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8", newline="\n")
    rest = BEAT["rest"]
    (out / "plan.json").write_text(json.dumps(dict(
        origin="the fight floor's middle, at the floor's level",
        axes="`at` is Roblox's (x, up, z): the entrance is at +Z, the foe's way in at -Z; `turn` is degrees anticlockwise "
             "seen from above; `scale` is the same on every axis",
        toRoblox="CFrame.new(at) * CFrame.Angles(0, math.rad(turn), 0), then the piece's `centre`",
        floor=dict(radius=FLOOR_R, stand=STAND, stepRing=[FLOOR_R, STEP_R], stepDown=STEP_DOWN),
        placements=[dict(piece=n, tag=tag, at=[round(x, 3), round(z, 3), round(-y, 3)], turn=turn, scale=scale)
                    for n, tag, x, y, z, turn, scale in plan()],
        drift=dict(note="each CloudDrift passes along +X at its speed, studs a second, and comes round again out of sight: "
                        "seeds, slow enough to be felt and never watched",
                   speed={f"Drift{k}": row[6] for k, row in enumerate(DRIFTS)}),
        lot=dict(note="the entrance on the lot behind the base and the record's marker: its own frame, the lot's middle at "
                      "the ground, the base and its path at +Z. The slab's numerals show the owner's record floor on both "
                      "faces, so a visitor reads it from the base and from the street behind. GateVeil is the door: "
                      "Transparency about 0.55, no shadow, no collision; stepping through it starts a run",
                 placements=[dict(piece=n, tag=tag, at=[round(x, 3), round(z, 3), round(-y, 3)], turn=turn, scale=scale)
                             for n, tag, x, y, z, turn, scale in LOT]),
        number=dict(piece="CrownSlab",
                    text=f"a SurfaceGui on each face's well, {SLAB_WELL[1][0] - SLAB_WELL[0][0]:g} studs wide by "
                         f"{SLAB_WELL[1][1] - SLAB_WELL[0][1]:g} tall, the well's middle {(SLAB_WELL[0][1] + SLAB_WELL[1][1]) / 2:g} over "
                         "the slab's place (all three times the slab's scale on the lot); in the room the face toward the "
                         "floor shows the floor's number and the back waits with the next; on the lot both show the record",
                    colour="#FFF8EA"),
        beat=dict(note="seeds, seconds from a win, for Config.Tower.Rise of 2.5; a fast floor keeps the turn and the leap",
                  slabTurn=BEAT["turn"], stepRise=BEAT["rise"], stepStagger=BEAT["stagger"], firstStep=BEAT["first"],
                  stepRest={f"Foe{k}": rest[k] for k in range(len(rest))},
                  restNote="a foe's step waits this far under its place and rises to it, the farthest first, with a small "
                           "overshoot; all four sink again once the foe is in",
                  climb=BEAT["climb"], leap=BEAT["leap"], sink=BEAT["sink"])), indent=1), encoding="utf-8", newline="\n")
    az, el, sun_code, sun_strength, shadow = d["sun"]
    a, e = math.radians(az), math.radians(el)
    amb_code, amb_strength = d["ambient"]
    fog_code, fog_k = d["fog"]
    threshold, intensity, sizes = d["bloom"]
    (out / "lighting.json").write_text(json.dumps(dict(
        note="the room's own Lighting, set on the client while it stands in the room and put back as it leaves",
        sky=dict(faces={f: f"maps/{PREFIX}_Sky_{f}.png" for f in kit.FACES}, StarCount=0, SunAngularSize=0, MoonAngularSize=0,
                 note="the cloud and the haze under it are in the faces, under the horizon; Ft is "
                      "toward the foe's way in (-Z)"),
        sun=dict(toward=[round(math.sin(a) * math.cos(e), 3), round(math.sin(e), 3), round(-math.cos(a) * math.cos(e), 3)],
                 elevationDegrees=el, colour=sun_code, strength=sun_strength, shadows=shadow,
                 note="low and from the side, so the blades' shadows lie across the floor; `toward` is the unit vector to it"),
        ambient=dict(colour=amb_code, strength=amb_strength,
                     asOne=kit.hex_of(np.array(look.srgb(amb_code), np.float32) * amb_strength)),
        atmosphere=dict(Color=fog_code, Decay=fog_code,
                        hazeAt={str(n): round(1 - math.exp(-fog_k * max(n - 20, 0)), 2) for n in (150, 400, 1000)},
                        note="`hazeAt` is how much of a thing the haze has taken at that many studs in these frames: a drift "
                             "barely; the far cloud is in the sky's faces, its haze with it"),
        bloom=dict(here=dict(threshold=threshold, intensity=intensity, sizesPx=list(sizes))),
        exposure=d["exposure"],
        glow={name: strength for name, (_, strength) in MAPS.items()}), indent=1), encoding="utf-8", newline="\n")
    print(json.dumps({name: entry["triangles"] for name, entry in listing.items()}))


def main():
    out = bl.out_dir()
    mode = sys.argv[sys.argv.index("--") + 2]
    if mode == "look":
        looks(out, sys.argv[sys.argv.index("--") + 3:])
    elif mode == "beat":
        beat(out)
    elif mode == "movie":
        movie(out)
    elif mode == "sheet":
        sheet(out)
    elif mode == "stand":
        stand_test(out)
    elif mode == "landing":
        landing_test(out)
    elif mode == "lot":
        lot_looks(out)
    elif mode == "lotsheet":
        lot_sheet(out)
    elif mode == "pictures":
        wear()
        write_pictures(out / "maps")
    elif mode == "export":
        export(out)


if __name__ == "__main__":
    main()
