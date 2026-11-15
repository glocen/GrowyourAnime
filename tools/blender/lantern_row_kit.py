"""AR5 section 2: Lantern Row's kit (docs/asset-requests.md). The festival kit's pieces in the merge's look, as meshes
that share one colour picture and one glow picture, so another ground is a new pair of pictures, never new meshes.

How a piece is coloured. The atlas holds swatches and prints. A swatch is a flat colour with its shading painted in:
up a swatch is the height on the shape (dark at the foot), across it is how shut in the face is (clean at the left,
shaded at the right: under an awning, inside a stall). A print is a picture of cloth or a board with our script on it
(tools/blender/lantern_row_look.py, `glyph`, draw 2). The glow picture is the same layout in grey: how much of its
colour a texel gives off (a lantern, lit paper, a stall's lamp-lit back wall), so a stall glows with no Light of its
own and the street stays inside its light budget.

A piece's front faces +Y, its origin is the middle of its width on the building line at pavement level, one unit is
one stud (handbook, environment and worlds, "Kit standards"). Outlines are an inverted hull round a piece's big
shapes only, in the piece's own mesh on the atlas's ink texel, so a piece is one part.

The floor carries its own light. The street's paving is a module one bay long with the string's warm pool painted
into its glow picture, and the elite's square is one floor with its canopy's light painted the same way: a pool costs
no Light, it holds at night, and its shape is drawn, not left to a cone. Real lights stand only where fighters need
their bodies lit: over each pack's spot, the square, the two gates.

Where each piece stands is `plan()`: the dressing along docs/design.md's street, on one rhythm, a sixth of the pack
spacing. The same list dresses the street rendered here and is written out for the builder.

Run (Eevee, no lock), each `blender.exe -b --factory-startup --python tools/blender/lantern_row_kit.py -- <out> ...`:
  pictures                         the maps alone
  street <M|N> [fast] [far] [hit]  the look script's own frame (its camera, fighters, measures and targets) on the
                                   street dressed from the plan: <out>/kit_<D>_frame.png and kit_<D>.json
  pieces                           each piece alone, <out>/piece_<Name>.png, and pieces.json
  sheet                            the review sheet, from those files
  export                           <out> is the handoff folder: meshes, maps, manifest.json, plan.json, and the plan
                                   drawn from above, lantern_row_plan.png
  plan                             plan.json alone, beside the handoff's manifest.json (the paper's emitters, paper())
  sky <M> [N]                      each phase's six sky faces, lighting.json and the sky's sheet, into <out>

Dusk is the look script's merge with the verdict's notes; night is the same kit under another sky and other lights
(`look.DIRECTIONS["N"]`, below). The kit's pictures are the same in both.
"""

import json
import math
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402

A = 1024           # the atlas, pixels
CELL = (64, 128)   # a swatch
CLOTH_GLOW = 0.15  # an awning lit from under by its stall: what keeps its red red at dusk and at night
GLOW = 2.4         # the glow picture's white, as emission strength in these renders (the builder's EmissiveStrength)
HALF = look.HALF
# The street (docs/design.md, "Lantern Row"; Config.World.Row): studs from the festival gate, up the street.
SPACING = 80.0     # from stop to stop
STOPS = dict(packs=(32.0, 112.0, 192.0, 352.0, 432.0, 512.0), square=272.0, keeper=592.0)
SQUARE = 64.0      # the elite's square, across
BAY = SPACING / 6  # the kit's one rhythm: a stall with its gap, a lantern string, a module of paving
POOL = (11.0, 5.2, 1.3)   # a string's pool on the paving: its reach across the street and along it, how soft its edge
POOL_TINT = "#FFD49A"     # the floor's glow is tinted by the game (EmissiveTint), so a ground can change its lanterns
FLOOR_GLOW = 0.85         # the floor's glow picture's white, as emission strength (EmissiveStrength)
STREET_PX = (1024, 312)   # a bay of paving: 20 stones across, 12 rows

# Swatches: the colour at the head, at the foot, and how much it glows. The merge's own colours (the look script's M).
SWATCHES = {
    "wood": ("#5A3A4C", "#20151F", 0.0), "wood_lit": ("#B07A5A", "#5A3440", 0.16), "post": ("#6A2A34", "#2A141C", 0.0),
    "red": ("#C4424E", "#7A2A3C", 0.0), "cream": ("#E8D8C0", "#A8988E", 0.0), "indigo": ("#2C2A64", "#15143A", 0.0),
    "roof": ("#23234A", "#0E0E22", 0.0), "house": ("#2C2C56", "#151532", 0.0), "stone": ("#8A8098", "#544C62", 0.0),
    "paper": ("#FFEBC8", "#F0CC98", 0.22), "warm": ("#FFEBC2", "#FFC98A", 1.0), "cyan": ("#8CF6FF", "#3CC8E8", 1.0),
    "window": ("#FFD49A", "#F0A868", 0.8), "brass": ("#D8A24A", "#7A4E2A", 0.0), "rope": ("#C8B088", "#7A6650", 0.0),
    "teal": ("#3E8E8E", "#1E4A56", 0.0), "mustard": ("#D8A848", "#8A6230", 0.0), "rose": ("#C86A8A", "#7A3A5A", 0.0),
    "dark": ("#1E1426", "#0C0A12", 0.0), "ink": ("#0C0A16", "#0C0A16", 0.0),
}
SWATCH_AT = {name: ((i % 16) * CELL[0], (i // 16) * CELL[1]) for i, name in enumerate(SWATCHES)}
# Prints: where each sits (x, y, width, height), each with a 4 pixel bleed round it.
PRINTS = {"stripes": (8, 268, 320, 128), "noren": (344, 268, 512, 128), "board": (8, 412, 512, 128),
          "banner": (536, 412, 128, 512), "seal": (680, 412, 256, 256), "biglamp": (680, 684, 128, 224)}
PAVING = (512, 8.0)    # the paving's own tile: pixels, and the studs it covers
# Pools as pools (research's note on round 2), tried here three ways and measured by the Shades' edge (target 0.15):
# a light on every second string 0.08, on the three strings over a pack 0.09, on every string with a 46 degree cone
# 0.125. From the player's camera 27 studs of paving lie behind a Shade, feet to head, so any dark stone between
# pools is behind its head. So every string's pool is painted in the paving's glow, and one real light hangs over each
# pack, where the fight needs light on the fighters themselves. The cone, in degrees, and the light's height.
POOL_CONE, POOL_HEIGHT = 66.0, 14.2
# The merge with the verdict's notes that are numbers (AR5 section 2). Note 4: the lead's carried light stands between
# him and his target under the hat's height (studs ahead, studs up), so it lights his front and not the hats' tops.
# Nearer his chest than round 2's, so its power falls from 1050 to 560 or his face burns out.
# Note 1: the haze lighter back toward the gate (round 2's was #4A4290, and a Shade's edge fell to 0.11 looking back).
look.DIRECTIONS["M"] = dict(
    look.DIRECTIONS["M"], fighter_light=("#FFF1DD", 560.0, 12.0), fighter_light_ahead=(1.8, 3.8), fog_away="#7868B4",
    sky_away=((-0.2, "#3A3268"), (0.0, "#8674BC"), (0.08, "#5E54A0"), (0.3, "#2A2E6C"), (1.0, "#141A48")))
# Night (the director's word, 2026-11-12): B's canopy with the merge's warmth. The kit wears the same pictures, so only
# the sky, the lights, the haze and the bloom turn: the last of the afterglow is a violet breath at the street's end,
# a painted moon stands over it, and the one directional light keeps its place, dimmer and cooler, so no shadow swings
# as the phase turns. The lanterns and their pools are what's left, and they're still mostly warm.
look.DIRECTIONS["N"] = dict(
    look.DIRECTIONS["M"], name="Lantern night",
    idea="the merge gone to night: the same warm strings and pools under a dark blue sky, a painted moon up the street",
    sky=((-0.2, "#0E1230"), (0.0, "#5A5098"), (0.05, "#3A4488"), (0.2, "#16285C"), (0.5, "#0B1338"), (1.0, "#060A22")),
    sky_away=((-0.2, "#0A0E28"), (0.0, "#2A3E78"), (0.08, "#1C2E64"), (0.3, "#0F1A48"), (1.0, "#060A22")),
    clouds=("#3E4E90", "#0E1A40", 0.02, 0.18, 0.62), moon=((14.0, 24.0), 0.045, "#EAF6FF"), stars=0.9,
    sun=(200.0, 62.0, "#8FA8FF", 0.34, True), ambient=("#1E2A62", 0.40),
    fog=("#3A3C80", 0.0045), fog_away="#22306A", bloom=(0.7, 1.0, (7, 22)))
REAL_LIGHT = 1.5   # a real pool's power beside round 2's: one over each pack, where round 2 had one on every string


def code(c):
    return np.array(look.srgb_code(c), np.float32)


# --- the pictures ----------------------------------------------------------------------------------------------------

def glyphs():
    rng = np.random.default_rng(look.GLYPH_SEED)
    return [look.glyph(rng) for _ in range(8)]


def _resize(ink, w, h):
    """A grey picture at another size, by the sheet's own shrink (it only shrinks: the glyphs are drawn at 128)."""
    rgba = np.dstack([ink, ink, ink, np.ones_like(ink)])
    out = rs.shrink(rgba, max(w / ink.shape[1], h / ink.shape[0]))[..., 0]
    return out[:h, :w]


def _put(page, glow, rgb, x, y, lit=0.0):
    """A print into the atlas with its bleed, and its glow."""
    h, w = rgb.shape[:2]
    padded = np.pad(rgb, ((4, 4), (4, 4), (0, 0)), mode="edge")
    page[y - 4:y + h + 4, x - 4:x + w + 4, :3] = padded
    g = lit if np.ndim(lit) else np.full((h, w), lit, np.float32)
    glow[y - 4:y + h + 4, x - 4:x + w + 4] = np.pad(g, 4, mode="edge")


def atlas():
    """The kit's colour picture and its glow picture, as sRGB-coded arrays."""
    page = np.zeros((A, A, 4), np.float32)
    page[..., :3], page[..., 3] = code("#20151F"), 1.0
    glow = np.zeros((A, A), np.float32)
    t = np.linspace(0, 1, CELL[1], dtype=np.float32)[:, None, None] ** 0.85   # down the cell: head to foot
    shade = 1.0 - 0.5 * np.clip((np.arange(CELL[0], dtype=np.float32) - 8) / 48, 0, 1)[None, :, None]
    for name, (top, bottom, lit) in SWATCHES.items():
        x, y = SWATCH_AT[name]
        cell = code(top) * (1 - t) + code(bottom) * t
        page[y:y + CELL[1], x:x + CELL[0], :3] = cell * (shade if not lit else 1.0)
        glow[y:y + CELL[1], x:x + CELL[0]] = lit
    letters = glyphs()
    red, cream, indigo, ink, wood = (code(c) for c in ("#C4424E", "#E8D8C0", "#262454", "#1E1426", "#3A2434"))
    # the awning's cloth: five pairs of stripes, darker toward its low edge (the picture's foot)
    x, y, w, h = PRINTS["stripes"]
    band = ((np.arange(w) * 10 // w) % 2)[None, :, None]
    fall = 1.0 - 0.32 * np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
    _put(page, glow, (red * (1 - band) + cream * band) * fall, x, y, CLOTH_GLOW)
    # the curtain: indigo, the script in cream, a pale hem
    x, y, w, h = PRINTS["noren"]
    row = np.concatenate([np.pad(_resize(g, 96, 96), ((16, 16), (16, 16))) for g in letters[4:]], axis=1)
    cloth = indigo[None, None] * (1.0 - 0.25 * np.linspace(0, 1, h, dtype=np.float32)[:, None, None])
    rgb = cloth * (1 - row[..., None]) + cream * row[..., None]
    rgb[-7:-3] = cream * 0.9
    _put(page, glow, rgb, x, y, (0.08 + 0.34 * row).astype(np.float32))
    # the sign board: dark wood, a cream line round it, the script in cream
    x, y, w, h = PRINTS["board"]
    rgb = np.broadcast_to(wood, (h, w, 3)).copy()
    rgb[8:11, 8:-8], rgb[-11:-8, 8:-8], rgb[8:-8, 8:11], rgb[8:-8, -11:-8] = cream * 0.85, cream * 0.85, cream * 0.85, cream * 0.85
    rgb = rgb * (1 - row[..., None]) + cream * row[..., None]
    _put(page, glow, rgb, x, y, (0.3 * row).astype(np.float32))
    # the banner: cream cloth, the script down it in ink, a red band at head and foot
    x, y, w, h = PRINTS["banner"]
    column = np.concatenate([np.pad(_resize(g, 96, 96), ((10, 10), (16, 16))) for g in letters[:4]], axis=0)
    column = np.pad(column, ((24, 24), (0, 0)))
    rgb = cream[None, None] * (1.0 - 0.2 * np.linspace(0, 1, h, dtype=np.float32)[:, None, None])
    rgb = rgb * (1 - column[..., None]) + ink * column[..., None]
    rgb[:18], rgb[-18:] = red, red * 0.8
    _put(page, glow, rgb, x, y)
    # the seal: one letter in indigo on a cream disc, on a plaque of dark wood, for a gate's pillar and a door.
    # Never on a red field (the content check, 2026-11-12): the plaque is wood, and covers the red pillar's width.
    x, y, w, h = PRINTS["seal"]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    r = np.hypot(xx - w / 2, yy - h / 2)
    disc = np.clip(112 - r, 0, 1)[..., None]
    ring = (np.clip(104 - r, 0, 1) * np.clip(r - 96, 0, 1))[..., None]
    one = np.pad(_resize(letters[2], 128, 128), 64)[..., None]
    rgb = wood * (1 - disc) + cream * disc
    rgb = rgb * (1 - ring) + indigo * ring
    rgb = rgb * (1 - one * disc) + indigo * one * disc
    _put(page, glow, rgb, x, y)
    # a big lantern's paper: warm and lit, one letter in ink, dark bands at head and foot
    x, y, w, h = PRINTS["biglamp"]
    one = np.pad(_resize(letters[5], 96, 96), ((64, 64), (16, 16)))
    warm = code("#FFEBC2")[None, None] * (1 - 0.18 * np.linspace(0, 1, h, dtype=np.float32)[:, None, None])
    rgb = warm * (1 - one[..., None]) + ink * one[..., None]
    lit = 1.0 - one
    rgb[:14], rgb[-14:] = ink, ink
    lit[:14], lit[-14:] = 0.0, 0.0
    _put(page, glow, rgb, x, y, lit.astype(np.float32))
    return page, glow


def stones(w, h, cols, rows, d, seed):
    """Staggered flat stones in the ground's two colours with thin dark joints. It repeats both ways."""
    rng = np.random.default_rng(seed)
    a, b, joint = code(d["ground"][0]), code(d["ground"][1]), code(d["joint"])
    page = np.ones((h, w, 4), np.float32)
    ys = np.linspace(0, h, rows + 1).round().astype(int)
    xs = np.linspace(0, w, cols + 1).round().astype(int)
    for r in range(rows):
        for c in range(cols):
            shift = int(xs[1]) // 2 if r % 2 else 0
            across = np.arange(xs[c] + shift, xs[c + 1] + shift) % w
            k = rng.uniform(0.2, 0.8)
            page[ys[r]:ys[r + 1], across, :3] = a * (1 - k) + b * k
            page[ys[r]:ys[r] + 2, across, :3] = joint
            page[ys[r]:ys[r + 1], across[:2], :3] = joint
    return page


def grey(v):
    v = np.clip(v, 0, 1).astype(np.float32)
    return np.dstack([v, v, v, np.ones_like(v)])


def street_bay_pictures(d):
    """One bay of the street's paving, 44 studs by a bay, and its glow: the pool under its lantern string, lying along
    the string's own slant, with its neighbours' spill so the bays join."""
    w, h = STREET_PX
    page = stones(w, h, 20, 12, d, 7)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    x = (xx + 0.5) / w * 2 * HALF - HALF
    y = BAY / 2 - (yy + 0.5) / h * BAY                    # the picture's head is up the street
    slope = 6.0 / (2 * HALF - 0.8)
    pool = np.zeros((h, w), np.float32)
    for k in (-1, 0, 1):
        along = y - k * BAY - slope * x
        pool += np.exp(-((x / POOL[0]) ** 2 + (along / POOL[1]) ** 2) ** POOL[2])
    page[..., :3] *= (1.0 - 0.35 * np.clip((np.abs(x) - (HALF - 5.0)) / 5.0, 0, 1))[..., None]   # shaded at the stalls' feet
    return page, grey(pool)


def square_pictures(d, kit_page):
    """The elite's square's floor, 64 studs across: the street's stones, a border, a ring and four bars of pale stone,
    the seal where the elite stands. Its glow: the canopy's two crossing strings, the lamp where they cross, and the
    edge posts' lanterns."""
    n = 1024
    page = stones(n, n, 32, 64, d, 9)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    px = SQUARE / n
    x, y = (xx + 0.5) * px - SQUARE / 2, SQUARE / 2 - (yy + 0.5) * px
    r, box = np.hypot(x, y), np.maximum(np.abs(x), np.abs(y))
    band = lambda dist, half: np.clip((half - np.abs(dist)) / px + 0.5, 0, 1)   # noqa: E731
    border = np.clip((box - 30.0) / px + 0.5, 0, 1)
    ring = band(r - 20.0, 1.0)
    bars = np.maximum(band(x, 0.9), band(y, 0.9)) * (r > 21.0) * (box < 30.0)
    inlay = np.maximum.reduce([border, ring, bars])[..., None] * 0.8
    page[..., :3] = page[..., :3] * (1 - inlay) + code("#B4A8C0") * inlay
    sx, sy, sw_, sh = PRINTS["seal"]
    seal = rs.shrink(kit_page[sy:sy + sh, sx:sx + sw_].copy(), 160 / sw_)
    a = (n - seal.shape[0]) // 2
    disc = np.clip((4.3 - r[a:a + seal.shape[0], a:a + seal.shape[1]]) / px + 0.5, 0, 1)[..., None]
    page[a:a + seal.shape[0], a:a + seal.shape[1], :3] = page[a:a + seal.shape[0], a:a + seal.shape[1], :3] * (1 - disc) \
        + seal[..., :3] * disc
    d1, d2 = (x - y) / math.sqrt(2), (x + y) / math.sqrt(2)
    canopy = np.maximum(np.exp(-(d1 / 6.5) ** 2), np.exp(-(d2 / 6.5) ** 2)) * np.exp(-(r / 36.0) ** 4)
    glow = 0.7 * canopy + 0.4 * np.exp(-(r / 12.0) ** 2) + 0.1 * inlay[..., 0]
    for px_ in (-30.4, 30.4):
        for py in SQUARE_POSTS:
            glow += 0.7 * np.exp(-((x - px_) ** 2 + (y - py) ** 2) / 5.5 ** 2)
    return page, grey(glow)


def paper_picture():
    """Drifting paper, a particle's picture: four torn scraps on a 2 by 2 grid, cream with one fold each."""
    rng = np.random.default_rng(3)
    n = 128
    page = np.zeros((2 * n, 2 * n, 4), np.float32)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    x, y = (xx + 0.5) / n * 2 - 1, (yy + 0.5) / n * 2 - 1
    paper = code("#FFF2DC")
    for i in range(4):
        long = 0.78 if i != 3 else 0.9
        short = (0.5, 0.62, 0.4, 0.2)[i]
        turn = rng.uniform(0, math.pi)
        inside = np.ones((n, n), np.float32)
        for k in range(5):   # a torn sheet: five straight tears round its middle
            a = turn + math.tau * k / 5 + rng.uniform(-0.3, 0.3)
            reach = (long if k in (0, 2) else short) * rng.uniform(0.8, 1.0) if k != 4 else short * 0.7
            inside = np.minimum(inside, np.clip((reach - (x * math.cos(a) + y * math.sin(a))) * n / 2 + 0.5, 0, 1))
        fold = turn + rng.uniform(0.6, 1.2)
        side = np.clip((x * math.cos(fold) + y * math.sin(fold) + 0.08) * n / 2 + 0.5, 0, 1)
        cell = page[(i // 2) * n:(i // 2 + 1) * n, (i % 2) * n:(i % 2 + 1) * n]
        cell[..., :3] = paper * (0.8 + 0.2 * side)[..., None]
        cell[..., 3] = inside
    return page


def write_pictures(out: Path, d):
    page, glow = atlas()
    rs.save(page, out / "LanternRow_Kit_Color.png")
    rs.save(grey(glow), out / "LanternRow_Kit_Glow.png")
    rs.save(stones(PAVING[0], PAVING[0], 4, 8, d, 11), out / "LanternRow_Paving_Color.png")
    for name, (colour, lit) in (("Street", street_bay_pictures(d)), ("Square", square_pictures(d, page))):
        rs.save(colour, out / f"LanternRow_{name}_Color.png")
        rs.save(lit, out / f"LanternRow_{name}_Glow.png")
    rs.save(paper_picture(), out / "LanternRow_Paper.png")


# --- the mesh builder ------------------------------------------------------------------------------------------------

def sw_uv(name, occ, t):
    """A swatch's point: `occ` 0 clean to 1 shut in, `t` 0 the shape's foot to 1 its head."""
    x, y = SWATCH_AT[name]
    return ((x + 8 + occ * 48) / A, 1 - (y + 8 + (1 - t) * 112) / A)


def pic_uv(name):
    x, y, w, h = PRINTS[name]
    return (x / A, 1 - (y + h) / A, (x + w) / A, 1 - y / A)   # left, foot, right, head


BOX = {"+x": ((1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)), "-x": ((-1, 1, -1), (-1, -1, -1), (-1, -1, 1), (-1, 1, 1)),
       "+y": ((1, 1, -1), (-1, 1, -1), (-1, 1, 1), (1, 1, 1)), "-y": ((-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1)),
       "+z": ((-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)), "-z": ((-1, 1, -1), (1, 1, -1), (1, -1, -1), (-1, -1, -1))}


class Mesh:
    """Faces with their own corners (flat shading, as the look wants), each corner a point in the atlas."""

    def __init__(self, ink_t=0.14):
        self.v, self.f, self.uv = [], [], []
        self.ink = None if ink_t is None else Mesh(None)
        self.ink_t = ink_t

    def face(self, pts, uvs):
        i = len(self.v)
        self.v += [tuple(p) for p in pts]
        self.f.append(tuple(range(i, i + len(pts))))
        self.uv.append(list(uvs))

    def tris(self):
        return sum(len(f) - 2 for f in self.f)

    def box(self, size, at, sw, rot=None, occ=0.0, ink=False, pics=None, skip=()):
        if rot is None:
            rot = Matrix.Identity(3)
        elif not isinstance(rot, Matrix):
            rot = Euler(rot).to_matrix()
        half = Vector(size) / 2
        for key, corners in BOX.items():
            if key in skip:
                continue
            pts = [Vector(at) + rot @ Vector((c[0] * half.x, c[1] * half.y, c[2] * half.z)) for c in corners]
            if pics and key in pics:
                u0, v0, u1, v1 = pic_uv(pics[key])
                uvs = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
            elif key == "+z":
                uvs = [sw_uv(sw, occ * 0.5, 1.0)] * 4
            elif key == "-z":
                uvs = [sw_uv(sw, 1.0, 0.0)] * 4
            else:
                uvs = [sw_uv(sw, occ, (c[2] + 1) / 2) for c in corners]
            self.face(pts, uvs)
        if ink and self.ink is not None:
            big = Vector(size) + Vector((2, 2, 2)) * self.ink_t
            for corners in BOX.values():
                pts = [Vector(at) + rot @ Vector((c[0] * big.x / 2, c[1] * big.y / 2, c[2] * big.z / 2)) for c in corners]
                self.ink.face(pts[::-1], [(0, 0)] * 4)

    def cloth(self, bl_, br, tr, tl, pic, part=(0.0, 1.0)):
        """A sheet of printed cloth seen from both sides: its corners foot left, foot right, head right, head left."""
        u0, v0, u1, v1 = pic_uv(pic)
        ua, ub = u0 + (u1 - u0) * part[0], u0 + (u1 - u0) * part[1]
        self.face([bl_, br, tr, tl], [(ua, v0), (ub, v0), (ub, v1), (ua, v1)])
        self.face([br, bl_, tl, tr], [(ub, v0), (ua, v0), (ua, v1), (ub, v1)])

    def flat(self, pts, sw, occ=0.0, t=0.6):
        """A flat shape in one colour, seen from both sides."""
        uv = [sw_uv(sw, occ, t)] * len(pts)
        self.face(pts, uv)
        self.face(pts[::-1], uv)

    def out(self, pts, uvs, centre, ink=False):
        """A face turned away from `centre` (toward it for the ink's hull)."""
        n = (pts[1] - pts[0]).cross(pts[-1] - pts[0])
        away = n.dot(sum(pts, Vector()) / len(pts) - centre) >= 0
        target = self.ink if ink else self
        if away == ink:
            pts, uvs = pts[::-1], uvs[::-1]
        target.face(pts, uvs)

    def slab(self, bl_, br, tr, tl, thick, pic=None, edge="red", ink=False, sw=None, occ=0.0):
        """A thin board, a roof's slope or a stretched cloth, a print or a swatch on both faces: one face's corners,
        foot edge first; the slab's body lies under it."""
        top = [Vector(q) for q in (bl_, br, tr, tl)]
        n = (top[1] - top[0]).cross(top[3] - top[0]).normalized()
        if n.z < 0:
            n = -n
        low = [q - n * thick for q in top]
        centre = sum(top + low, Vector()) / 8
        if pic:
            u0, v0, u1, v1 = pic_uv(pic)
            uvs = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
            under = uvs
        else:
            zs = [q.z for q in top]
            uvs = [sw_uv(sw, occ, (q.z - min(zs)) / max(max(zs) - min(zs), 1e-6)) for q in top]
            under = [sw_uv(sw, 1.0, 0.3)] * 4
        self.out(top, uvs, centre)
        self.out(low, under, centre)
        for i in range(4):
            j = (i + 1) % 4
            self.out([low[i], low[j], top[j], top[i]], [sw_uv(edge, 0.3, 0.5)] * 4, centre)
        if ink and self.ink is not None:
            t = self.ink_t
            mid = sum(top, Vector()) / 4
            up = [q + (q - mid).normalized() * t * 1.4 + n * t for q in top]
            down = [q + (q - mid).normalized() * t * 1.4 - n * (thick + t) for q in top]
            self.out(up, [(0, 0)] * 4, centre, ink=True)
            self.out(down, [(0, 0)] * 4, centre, ink=True)
            for i in range(4):
                j = (i + 1) % 4
                self.out([down[i], down[j], up[j], up[i]], [(0, 0)] * 4, centre, ink=True)

    def lathe(self, profile, at, sides, sw, occ=0.0, caps=True, spin=0.0, pic=None):
        """A turned shape about Z: `profile` is (radius, height) from its head down. With `pic`, the print wraps it."""
        zs = [z for _, z in profile]
        z0, z1 = min(zs), max(zs)
        angles = [spin + math.tau * i / sides for i in range(sides + 1)]

        def ring(r, z):
            return [Vector(at) + Vector((r * math.cos(a), r * math.sin(a), z)) for a in angles]

        def uv(i, z):
            t = (z - z0) / max(z1 - z0, 1e-6)
            if pic:
                u0, v0, u1, v1 = pic_uv(pic)
                return (u0 + (u1 - u0) * i / sides, v0 + (v1 - v0) * t)
            return sw_uv(sw, occ, t)

        for (ra, za), (rb, zb) in zip(profile, profile[1:]):
            up, down = ring(ra, za), ring(rb, zb)
            for i in range(sides):
                self.face([down[i], down[i + 1], up[i + 1], up[i]], [uv(i, zb), uv(i + 1, zb), uv(i + 1, za), uv(i, za)])
        if caps:
            (r, z), (rb, zb) = profile[0], profile[-1]
            self.face(ring(r, z)[:-1], [sw_uv(sw, occ, 1.0)] * sides)
            self.face(ring(rb, zb)[:-1][::-1], [sw_uv(sw, 1.0, 0.0)] * sides)

    def tube(self, points, radius, sw):
        """A square cable along points."""
        for a, b in zip(points, points[1:]):
            a, b = Vector(a), Vector(b)
            d = (b - a).normalized()
            side = d.cross(Vector((0, 0, 1))).normalized() * radius
            up = side.cross(d).normalized() * radius
            offs = [side + up, -side + up, -side - up, side - up]
            for i in range(4):
                j = (i + 1) % 4
                pts = [a + offs[i], a + offs[j], b + offs[j], b + offs[i]]
                nrm = (pts[1] - pts[0]).cross(pts[3] - pts[0])
                if nrm.dot(offs[i] + offs[j]) < 0:
                    pts = pts[::-1]
                self.face(pts, [sw_uv(sw, 0.0, 0.5)] * 4)

    def whole(self):
        """The piece and its ink as one mesh: the hull's faces point at the atlas's ink texel, so a piece is one part."""
        both = Mesh(None)
        both.v, both.f, both.uv = list(self.v), list(self.f), list(self.uv)
        if self.ink is not None:
            for face in self.ink.f:
                both.face([self.ink.v[i] for i in face], [sw_uv("ink", 0.2, 0.5)] * len(face))
        return both

    def to_object(self, name, material):
        # Corners that meet share a vertex. Every face stays: a cloth is two faces on the same corners, one each way,
        # which a merge by distance would take for a double and drop.
        seen, verts, faces, uvs = {}, [], [], []
        for face, face_uv in zip(self.f, self.uv):
            ids = [seen.setdefault(tuple(round(c, 4) for c in self.v[i]), len(seen)) for i in face]
            while len(verts) < len(seen):
                verts.append(None)
            for i, j in zip(face, ids):
                verts[j] = self.v[i] if verts[j] is None else verts[j]
            if len(set(ids)) == len(ids):
                faces.append(ids)
                uvs.append(face_uv)
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        layer = mesh.uv_layers.new(name="UV")
        k = 0
        for face in uvs:
            for uv in face:
                layer.data[k].uv = uv
                k += 1
        mesh.update()
        if material is not None:
            mesh.materials.append(material)
        return mesh


# --- the pieces ------------------------------------------------------------------------------------------------------

class Piece:
    """`maps`: which pair of pictures it wears. `solid`: what the builder gives it to walk into."""

    def __init__(self, name, mesh, lights=(), note="", maps="Kit", solid="none"):
        self.name, self.mesh, self.lights, self.note, self.maps, self.solid = name, mesh, list(lights), note, maps, solid


def scallops(m, p0, p1, drop, count):
    """A cut hem from p0 to p1: `count` tongues, each a strip ending in a point, each one stripe of the awning."""
    p0, p1 = Vector(p0), Vector(p1)
    step, down = (p1 - p0) / count, Vector((0, 0, -drop))
    u0, v0, u1, v1 = pic_uv("stripes")
    for i in range(count):
        a = p0 + step * i
        pts = [a, a + down * 0.55, a + step / 2 + down, a + step + down * 0.55, a + step]
        uv = [(u0 + (u1 - u0) * (i % 10 + 0.5) / 10, v0 + (v1 - v0) * 0.3)] * 5
        m.face(pts, uv)
        m.face(pts[::-1], uv)


def hung_lamp(m, at, r=0.6, sw="paper", sides=8):
    """A paper lamp on a cord: the stall's own light."""
    x, y, z = at
    m.lathe([(r * 0.45, 0.62 * r * 2), (r * 0.9, 0.42 * r * 2), (r, 0.0), (r * 0.9, -0.42 * r * 2), (r * 0.45, -0.62 * r * 2)],
            at, sides, sw)
    m.box((0.5 * r, 0.5 * r, 0.14), (x, y, z + 0.66 * r * 2), "dark")
    m.box((0.5 * r, 0.5 * r, 0.14), (x, y, z - 0.66 * r * 2), "dark")


def lantern(m, at, sw, sides=6, k=1.0):
    x, y, z = at
    m.lathe([(0.22 * k, 0.74 * k), (0.52 * k, 0.3 * k), (0.52 * k, -0.3 * k), (0.22 * k, -0.74 * k)], at, sides, sw)
    m.box((0.4 * k, 0.4 * k, 0.16 * k), (x, y, z + 0.82 * k), "dark", skip=("-z",))
    m.box((0.4 * k, 0.4 * k, 0.16 * k), (x, y, z - 0.82 * k), "dark", skip=("+z",))
    # a tuft with a square end, in mustard: never a red shape that tapers down (the content check, 2026-11-12)
    m.flat([Vector((x - 0.09 * k, y, z - 0.9 * k)), Vector((x + 0.09 * k, y, z - 0.9 * k)),
            Vector((x + 0.09 * k, y, z - 1.3 * k)), Vector((x - 0.09 * k, y, z - 1.3 * k))], "mustard", t=0.8)


def big_lantern(m, at, r, h, sw=None, sides=8):
    """A great paper lantern: its paper printed with one letter (or one swatch), dark hoops at head and foot."""
    x, y, z = at
    prof = [(r * 0.62, h / 2), (r, h * 0.26), (r, -h * 0.26), (r * 0.62, -h / 2)]
    m.lathe(prof, at, sides, sw or "warm", pic=None if sw else "biglamp", spin=math.pi / sides)
    for k in (1, -1):
        m.lathe([(r * 0.66, 0.2), (r * 0.66, -0.2)], (x, y, z + k * (h / 2 + 0.2)), sides, "dark", spin=math.pi / sides)
    m.flat([Vector((x - 0.24, y, z - h / 2 - 0.4)), Vector((x + 0.24, y, z - h / 2 - 0.4)),
            Vector((x + 0.24, y, z - h / 2 - 1.4)), Vector((x - 0.24, y, z - h / 2 - 1.4))], "mustard", t=0.8)


def stall_a():
    """The counter stall: a lean-to with a striped awning and a cut hem, a split curtain, a board on its ridge, jars
    on the counter, a paper lamp under the cloth and its glow on the back wall."""
    m = Mesh()
    w = 12.0
    m.box((w, 6.8, 0.3), (0, -3.5, 0.15), "wood", occ=0.4)                                 # the floor
    m.box((11.0, 0.4, 3.0), (0, -1.0, 1.8), "wood", ink=True)                              # the counter's front
    for x in (-3.7, 0.0, 3.7):
        m.box((0.5, 0.14, 3.0), (x, -0.75, 1.8), "post", skip=("-y",))
    m.box((11.8, 2.3, 0.3), (0, -1.6, 3.45), "wood_lit", ink=True)                         # its top, in the lamp's light
    for x in (-5.6, 5.6):
        m.box((0.4, 5.2, 3.0), (x, -3.8, 1.8), "wood", occ=0.5)
        m.box((0.6, 0.6, 9.3), (x, -0.3, 4.65), "post", ink=True)                          # the front posts
        m.box((0.6, 0.6, 11.3), (x, -6.6, 5.65), "post", ink=True)                         # the back posts
    m.box((11.0, 0.4, 7.7), (0, -6.6, 7.15), "wood_lit", ink=True)                         # the back wall, lamp-lit
    m.box((11.0, 0.4, 3.0), (0, -6.6, 1.8), "wood", occ=0.8)
    m.box((10.4, 1.1, 0.25), (0, -5.9, 6.3), "wood", occ=0.2)                              # a shelf
    for i, (x, sw) in enumerate(((-4.0, "teal"), (-2.6, "mustard"), (-0.6, "rose"), (1.2, "teal"), (3.4, "mustard"))):
        m.box((1.1, 0.8, 0.9 + 0.3 * (i % 2)), (x, -5.9, 6.88 + 0.15 * (i % 2)), sw, occ=0.1)
    m.box((11.8, 0.4, 0.45), (0, -0.3, 8.3), "post", ink=True)                             # the front beam
    # the awning: from the back posts' heads down past the front beam, out over the street
    front, back, zf, zb = 1.7, -7.0, 8.55, 11.3
    m.slab((-w / 2 - 0.5, front, zf), (w / 2 + 0.5, front, zf), (w / 2 + 0.5, back, zb), (-w / 2 - 0.5, back, zb),
           0.22, "stripes", "red", ink=True)
    scallops(m, (-w / 2 - 0.5, front, zf - 0.2), (w / 2 + 0.5, front, zf - 0.2), 1.0, 10)
    for i in range(3):                                                                    # the curtain, in three
        a, b = -5.2 + i * 3.5, -5.2 + i * 3.5 + 3.4
        m.cloth((a, 0.0, 5.95), (b, 0.0, 5.95), (b, 0.0, 8.1), (a, 0.0, 8.1), "noren", (i / 3, (i + 1) / 3))
    m.box((7.0, 0.3, 1.8), (0, -6.6, 12.5), "dark", pics={"+y": "board"}, ink=True)        # the board on the ridge
    for x in (-2.8, 2.8):
        m.box((0.3, 0.3, 0.6), (x, -6.6, 11.45), "post")
    for i, x in enumerate((-4.2, -2.4, 2.0, 3.8)):                                         # jars, two lit
        m.lathe([(0.2, 0.75), (0.34, 0.6), (0.34, 0.0)], (x, -1.5, 3.6), 6, "paper" if i % 2 else "teal")
    hung_lamp(m, (0.0, -2.9, 7.5))
    m.tube([(0.0, -2.9, 8.3), (0.0, -2.9, 9.7)], 0.04, "dark")
    return Piece("StallA", m, lights=[("Lamp", (0.0, -2.9, 6.9), "#FFD49A")],
                 note="the counter stall; its lamp's glow is painted, a real light is the builder's to add near a fight")


def stall_b():
    """The prize stall: a little house with a gabled indigo roof and a red ridge, three shelves of prizes against a
    lamp-lit wall, one long curtain, small lanterns under the eave."""
    m = Mesh()
    m.box((12.0, 6.8, 0.3), (0, -3.5, 0.15), "wood", occ=0.4)
    m.box((11.0, 0.4, 2.4), (0, -1.0, 1.5), "wood", ink=True)
    for x in (-4.4, -1.5, 1.5, 4.4):
        m.box((0.4, 0.14, 2.4), (x, -0.75, 1.5), "red", skip=("-y",))
    m.box((11.8, 2.0, 0.3), (0, -1.5, 2.85), "wood_lit", ink=True)
    for x in (-5.6, 5.6):
        m.box((0.4, 5.2, 4.4), (x, -3.8, 2.5), "wood", occ=0.5)
        m.box((0.6, 0.6, 8.5), (x, -0.3, 4.25), "post", ink=True)
        m.box((0.6, 0.6, 8.9), (x, -6.6, 4.45), "post", ink=True)
    m.box((11.0, 0.4, 3.0), (0, -6.6, 1.8), "wood", occ=0.8)
    m.box((11.0, 0.4, 5.6), (0, -6.6, 6.1), "wood_lit", ink=True)
    prizes = ("teal", "cream", "rose", "mustard", "paper", "red", "teal", "mustard")
    for tier, z in enumerate((3.7, 5.3, 6.9)):
        m.box((10.4, 1.0, 0.2), (0, -5.9, z), "wood", occ=0.2)
        for i in range(6):
            sw = prizes[(i * 3 + tier * 2) % len(prizes)]
            h = 0.7 + 0.25 * ((i + tier) % 3)
            m.box((0.9, 0.7, h), (-4.3 + i * 1.72, -5.9, z + 0.1 + h / 2), sw, occ=0.1)
    # the roof: two slopes from a ridge along the street, the front one out over the counter
    ridge, eave_f, eave_b = (-3.2, 11.6), (1.7, 8.3), (-7.5, 8.9)
    for (ya, za), (yb, zb) in ((eave_f, ridge), (eave_b, ridge)):
        m.slab((-6.6, ya, za), (6.6, ya, za), (6.6, yb, zb), (-6.6, yb, zb), 0.3, sw="indigo", edge="cream", ink=True)
    for x in (-6.0, 6.0):
        m.flat([Vector((x, eave_f[0] - 0.6, eave_f[1] + 0.3)), Vector((x, eave_b[0] + 0.5, eave_b[1] + 0.2)),
                Vector((x, ridge[0], ridge[1] - 0.2))], "wood", occ=0.3, t=0.7)
    m.box((14.0, 0.45, 0.45), (0, ridge[0], ridge[1] + 0.2), "red", ink=True)
    for x in (-7.1, 7.1):
        m.box((0.3, 0.6, 0.6), (x, ridge[0], ridge[1] + 0.2), "brass")
    m.box((11.8, 0.4, 0.4), (0, -0.3, 8.1), "post", ink=True)
    m.cloth((-5.2, 0.0, 6.6), (5.2, 0.0, 6.6), (5.2, 0.0, 7.9), (-5.2, 0.0, 7.9), "noren")
    for i in range(5):
        lantern(m, (-4.4 + i * 2.2, 1.0, 7.1), "cyan" if i % 2 else "warm", k=0.55)
    m.box((0.14, 1.5, 3.4), (6.1, 0.2, 5.6), "red")
    m.box((0.16, 1.5, 0.3), (6.1, 0.2, 7.1), "cream")
    hung_lamp(m, (0.0, -3.0, 7.9))
    return Piece("StallB", m, lights=[("Lamp", (0.0, -3.0, 7.2), "#FFD49A")], note="the prize stall")


def stall_corner():
    """The corner stall: a kiosk open to the street and to its right, under a four-sided striped roof with a great
    lantern on its peak. It turns a corner of the elite's square, and ends a row."""
    m = Mesh()
    m.box((12.0, 12.0, 0.3), (0, -6.0, 0.15), "wood", occ=0.4)
    m.box((11.0, 0.4, 3.0), (0, -1.0, 1.8), "wood", ink=True)
    m.box((11.8, 2.3, 0.3), (0, -1.6, 3.45), "wood_lit", ink=True)
    m.box((0.4, 9.0, 3.0), (5.0, -6.6, 1.8), "wood", ink=True)
    m.box((2.3, 9.4, 0.3), (4.4, -7.1, 3.45), "wood_lit", ink=True)
    for x, y in ((-5.7, -0.3), (5.7, -0.3), (5.7, -11.7), (-5.7, -11.7)):
        m.box((0.6, 0.6, 8.5), (x, y, 4.25), "post", ink=True)
    m.box((6.6, 6.6, 8.2), (-2.4, -8.4, 4.4), "wood_lit", ink=True)                        # the lit core
    m.box((6.9, 1.0, 0.25), (-2.4, -4.9, 6.2), "wood")
    m.box((1.0, 6.9, 0.25), (1.1, -8.4, 6.2), "wood")
    for i, sw in enumerate(("teal", "mustard", "rose", "cream")):
        m.box((0.9, 0.7, 0.8), (-4.6 + i * 1.5, -4.9, 6.75), sw)
        m.box((0.7, 0.9, 0.8), (1.1, -10.6 + i * 1.5, 6.75), sw)
    low, high = ((-7.5, -13.5), (7.5, 1.7), 8.5), ((-2.6, -8.6), (2.6, -3.4), 11.7)       # the eave and the roof's top ring

    def ring(r):
        (x0, y0), (x1, y1), z = r
        return [Vector((x0, y1, z)), Vector((x1, y1, z)), Vector((x1, y0, z)), Vector((x0, y0, z))]   # front left, round

    e, t = ring(low), ring(high)
    for i in range(4):
        j = (i + 1) % 4
        m.slab(e[i], e[j], t[j], t[i], 0.22, "stripes", "red", ink=True)
    m.box((5.6, 5.6, 0.3), (0, -6.0, 11.8), "red", ink=True)
    big_lantern(m, (0, -6.0, 13.7), 1.25, 2.6)
    scallops(m, e[0] - Vector((0, 0, 0.2)), e[1] - Vector((0, 0, 0.2)), 1.0, 12)
    scallops(m, e[1] - Vector((0, 0, 0.2)), e[2] - Vector((0, 0, 0.2)), 1.0, 12)
    m.box((11.8, 0.4, 0.4), (0, -0.3, 8.2), "post", ink=True)
    m.box((0.4, 11.8, 0.4), (5.7, -6.0, 8.2), "post", ink=True)
    for i in range(3):
        a, b = -5.2 + i * 3.5, -5.2 + i * 3.5 + 3.4
        m.cloth((a, 0.0, 5.95), (b, 0.0, 5.95), (b, 0.0, 8.0), (a, 0.0, 8.0), "noren", (i / 3, (i + 1) / 3))
        m.cloth((6.0, -0.6 - i * 3.5, 5.95), (6.0, -4.0 - i * 3.5, 5.95), (6.0, -4.0 - i * 3.5, 8.0), (6.0, -0.6 - i * 3.5, 8.0),
                "noren", (i / 3, (i + 1) / 3))
    hung_lamp(m, (2.4, -2.6, 7.4))
    return Piece("StallCorner", m, lights=[("Lamp", (2.4, -2.6, 6.8), "#FFD49A")],
                 note="open to +Y and to +X; turn it for the other three corners")


def lantern_string():
    """One span across the street: two poles, a sagging cable from one stall line to the other, running six studs up
    the street as it crosses, eleven paper lanterns, two warm to one cyan."""
    m = Mesh()
    a, b = Vector((-HALF + 0.4, -3.0, 18.4)), Vector((HALF - 0.4, 3.0, 18.4))
    for end in (a, b):
        m.box((0.34, 0.34, 19.0), (end.x, end.y, 9.5), "post", ink=True)
        m.box((0.6, 0.6, 0.3), (end.x, end.y, 19.1), "brass")

    def at(t, drop=0.0):
        q = a.lerp(b, t)
        q.z -= 3.0 * (1 - (2 * t - 1) ** 2) + drop
        return q

    m.tube([at(t) for t in np.linspace(0, 1, 13)], 0.05, "dark")
    for j in range(1, 12):
        lantern(m, at(j / 12, 0.95), "cyan" if j % 3 == 0 else "warm")
    return Piece("LanternString", m, lights=[("Pool", (0.0, 0.0, POOL_HEIGHT), "#FFD49A")],
                 note="its pool is painted in the bay under it; over a pack, one SpotLight straight down from Pool (the plan's lights)")


def banner_pole():
    """A tall banner on a pole at the stall line: the script down the cloth, a brass cap."""
    m = Mesh()
    m.box((0.32, 0.32, 15.0), (0, 0, 7.5), "post", ink=True)
    m.lathe([(0.1, 0.5), (0.26, 0.25), (0.1, 0.0)], (0, 0, 15.0), 6, "brass")
    m.box((2.5, 0.16, 0.16), (1.15, 0, 13.9), "post")
    m.cloth((0.2, 0, 7.4), (2.2, 0, 7.4), (2.2, 0, 13.8), (0.2, 0, 13.8), "banner")
    return Piece("Banner", m, note="the cloth runs along the street: stand it with its X up the street")


def sign_board():
    """A standing sign: the script on a framed board between two posts, under a little red cap. Read from both sides."""
    m = Mesh()
    for x in (-3.0, 3.0):
        m.box((0.32, 0.32, 7.4), (x, 0, 3.7), "post", ink=True)
    m.box((6.6, 0.3, 1.65), (0, 0, 6.2), "dark", pics={"+y": "board", "-y": "board"}, ink=True)
    m.box((7.4, 1.0, 0.22), (0, 0, 7.5), "red", ink=True)
    return Piece("SignBoard", m, note="its face is +Y and -Y")


def festival_gate():
    """The festival gate, across the street's mouth: two red pillars on stone feet, each under a small indigo roof; a
    lower beam hung with four great lanterns and a cut striped hem; an upper beam running past the pillars; the
    street's name on a board between them; a seal on each pillar."""
    m = Mesh()
    for side in (-1, 1):
        x = side * 20.4
        m.box((4.6, 4.6, 2.2), (x, 0, 1.1), "stone", ink=True)
        m.box((2.4, 2.4, 22.6), (x, 0, 13.5), "red", ink=True)
        for z in (3.0, 16.6):
            m.box((2.8, 2.8, 0.7), (x, 0, z), "dark")
        m.box((2.6, 0.2, 2.6), (x, 1.25, 8.4), "wood", pics={"+y": "seal"}, skip=("-y",))
        m.box((2.6, 0.2, 2.6), (x, -1.25, 8.4), "wood", pics={"-y": "seal"}, skip=("+y",))
        e = [Vector((x + a, b, 24.6)) for a, b in ((-3.4, 3.4), (3.4, 3.4), (3.4, -3.4), (-3.4, -3.4))]
        t = [Vector((x + a, b, 26.6)) for a, b in ((-0.5, 0.5), (0.5, 0.5), (0.5, -0.5), (-0.5, -0.5))]
        for i in range(4):
            j = (i + 1) % 4
            m.slab(e[i], e[j], t[j], t[i], 0.3, sw="indigo", edge="cream", ink=True)
        m.lathe([(0.12, 1.0), (0.4, 0.5), (0.2, 0.0)], (x, 0, 26.5), 6, "brass")
    m.box((40.8, 1.5, 1.7), (0, 0, 18.6), "red", ink=True)                                 # the lower beam
    m.box((47.6, 1.8, 1.3), (0, 0, 22.4), "red", ink=True)                                 # the upper beam
    for side in (-1, 1):
        m.box((0.4, 2.2, 1.7), (side * 23.9, 0, 22.4), "brass")
    for x in (-10.0, 10.0):
        m.box((1.0, 1.2, 2.5), (x, 0, 20.6), "red")
    m.box((12.0, 0.5, 3.0), (0, 0.9, 20.5), "dark", pics={"+y": "board"}, ink=True)
    m.box((12.0, 0.5, 3.0), (0, -0.9, 20.5), "dark", pics={"-y": "board"}, ink=True)
    for x in (-13.5, -6.5, 6.5, 13.5):
        m.tube([(x, 0, 17.8), (x, 0, 17.0)], 0.07, "dark")
        big_lantern(m, (x, 0, 15.2), 1.5, 3.2)
    scallops(m, (-19.0, 0.0, 17.7), (19.0, 0.0, 17.7), 1.3, 30)
    return Piece("FestivalGate", m, lights=[("Pool", (0.0, 0.0, 13.0), "#FFD49A")],
                 note="clear between the pillars' feet: 36 studs; under the lanterns: 13.2")


def keepers_gate():
    """The keeper's gate, the street's end: stone piers, a wall to each stall line, a deep roofed lintel, and over the
    doorway the street's one great cyan lantern, the Lamplighter's. The two leaves are their own piece."""
    m = Mesh()
    for side in (-1, 1):
        m.box((6.0, 5.0, 20.0), (side * 13.0, 0, 10.0), "stone", ink=True)
        m.box((6.6, 5.6, 1.2), (side * 13.0, 0, 0.6), "stone")
        m.box((6.6, 5.6, 0.9), (side * 13.0, 0, 19.6), "dark")
        m.box((6.4, 2.0, 15.0), (side * 19.2, 0, 7.5), "house", ink=True)
        m.box((6.8, 2.6, 0.7), (side * 19.2, 0, 15.2), "red", ink=True)
        m.box((0.36, 0.36, 13.0), (side * 17.5, 4.2, 6.5), "post", ink=True)               # a lamp post each side
        m.box((0.2, 0.2, 2.2), (side * 16.5, 4.2, 12.6), "post")
        lantern(m, (side * 15.6, 4.2, 11.2), "warm", sides=8, k=1.5)
    m.box((34.0, 4.0, 2.6), (0, 0, 21.3), "post", ink=True)                                # the lintel
    ridge, eave = (0.0, 26.6), 22.7
    for y in (4.6, -4.6):
        m.slab((-19.5, y, eave), (19.5, y, eave), (17.0, ridge[0], ridge[1]), (-17.0, ridge[0], ridge[1]), 0.35,
               sw="indigo", edge="cream", ink=True)
    m.box((36.0, 0.6, 0.6), (0, 0, 26.8), "red", ink=True)
    for side in (-1, 1):
        m.box((0.4, 0.9, 0.9), (side * 18.2, 0, 26.8), "brass")
        m.flat([Vector((side * 18.6, 4.2, eave + 0.2)), Vector((side * 18.6, -4.2, eave + 0.2)),
                Vector((side * 16.6, 0, ridge[1] - 0.2))], "wood", occ=0.4, t=0.6)
    m.tube([(0, 2.8, 20.0), (0, 2.8, 19.0)], 0.1, "dark")
    big_lantern(m, (0, 2.8, 16.0), 2.5, 5.2, sw="cyan")
    scallops(m, (-10.0, 2.1, 19.9), (10.0, 2.1, 19.9), 1.2, 16)
    return Piece("KeepersGate", m, lights=[("Lamp", (0.0, 4.0, 12.5), "#8CF6FF")],
                 note="the doorway is 20 wide and 20 tall; KeepersDoor hangs at x -10 and, turned half round, at x 10")


def keepers_door():
    """One leaf of the keeper's gate: indigo boards in a dark frame, brass bosses, the seal. Its hinge is the piece's
    origin, its width runs +X."""
    m = Mesh()
    m.box((10.0, 0.7, 19.6), (5.0, 0, 9.8), "indigo", ink=True)
    for z in (0.5, 19.1):
        m.box((10.0, 0.9, 1.0), (5.0, 0, z), "dark")
    for x in (0.4, 9.6):
        m.box((0.8, 0.9, 19.6), (x, 0, 9.8), "dark")
    for y in (0.4, -0.4):
        key = "+y" if y > 0 else "-y"
        m.box((4.6, 0.12, 4.6), (5.0, y, 10.0), "wood", pics={key: "seal"}, skip=("-y" if y > 0 else "+y",))
        for i in range(4):
            for z in (4.0, 16.0):
                m.box((0.5, 0.2, 0.5), (2.0 + i * 2.0, y, z), "brass")
    return Piece("KeepersDoor", m, note="a hinge at its origin; the second leaf is this one turned half round")


SQUARE_POSTS = (-24.0, -8.0, 8.0, 24.0)   # where the edge's posts stand along a side, from the square's middle


def square_floor():
    """The elite's square's floor: one flat piece 64 studs across with its own pictures (the pale border, ring and
    bars, the seal, and the canopy's light), laid just over the paving."""
    m = Mesh(None)
    h = SQUARE / 2
    m.face([Vector((-h, -h, 0.06)), Vector((h, -h, 0.06)), Vector((h, h, 0.06)), Vector((-h, h, 0.06))],
           [(0, 0), (1, 0), (1, 1), (0, 1)])
    return Piece("SquareFloor", m, maps="Square", note="lies 0.06 over the paving; the seal's foot is toward the gate")


def street_bay():
    """A bay of the street's paving: 44 studs across, one bay long, the lantern string's pool painted in its glow."""
    m = Mesh(None)
    m.face([Vector((-HALF, -BAY / 2, 0)), Vector((HALF, -BAY / 2, 0)), Vector((HALF, BAY / 2, 0)), Vector((-HALF, BAY / 2, 0))],
           [(0, 0), (1, 0), (1, 1), (0, 1)])
    return Piece("StreetBay", m, maps="Street", solid="floor",
                 note="one under each lantern string; a Part under them carries the walking, this is the look")


def square_strings():
    """The square's canopy: two lantern strings crossing over its middle from four tall corner poles, a great lantern
    where they cross. Nothing stands in the square itself."""
    m = Mesh()
    c = SQUARE / 2 + 1.0
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        m.box((0.44, 0.44, 22.4), (sx * c, sy * c, 11.2), "post", ink=True)
        m.box((0.8, 0.8, 0.36), (sx * c, sy * c, 22.5), "brass")
    count = 0
    for sy in (1, -1):
        a, b = Vector((-c, -sy * c, 21.8)), Vector((c, sy * c, 21.8))

        def at(t, drop=0.0, a=a, b=b):
            q = a.lerp(b, t)
            q.z -= 5.4 * (1 - (2 * t - 1) ** 2) + drop
            return q

        m.tube([at(t) for t in np.linspace(0, 1, 21)], 0.06, "dark")
        for j in range(1, 24):
            if j == 12:
                continue                                  # the crossing: the great lantern's place
            lantern(m, at(j / 24, 0.95), "cyan" if count % 3 == 2 else "warm")
            count += 1
    big_lantern(m, (0, 0, 14.2), 1.5, 3.2)
    return Piece("SquareStrings", m, lights=[("Pool", (0.0, 0.0, 12.0), "#FFD49A")],
                 note="its middle is the square's; the poles stand a stud outside the floor's corners")


def square_post(rope=True):
    """The square's edge: a lamp post on a stone foot, a warm lantern on its arm, and a rope with paper tags to the
    next post, 16 studs along +X. A run's last post is the same without the rope."""
    m = Mesh()
    m.box((1.6, 1.6, 1.0), (0, 0, 0.5), "stone", ink=True)
    m.box((0.5, 0.5, 9.4), (0, 0, 5.2), "red", ink=True)
    m.lathe([(0.12, 0.6), (0.36, 0.3), (0.16, 0.0)], (0, 0, 9.9), 6, "brass")
    m.box((0.22, 1.9, 0.22), (0, 0.85, 9.0), "red")
    lantern(m, (0, 1.6, 7.7), "warm", sides=8, k=1.2)
    if rope:
        pts = [Vector((16.0 * t, 0, 3.6 - 1.1 * (1 - (2 * t - 1) ** 2))) for t in np.linspace(0, 1, 9)]
        m.tube(pts, 0.07, "rope")
        for i in range(1, 8):
            q = pts[i]
            m.flat([q + Vector((-0.28, 0, 0)), q + Vector((0.28, 0, 0)), q + Vector((0.28, 0, -0.9)),
                    q + Vector((0, 0, -1.15)), q + Vector((-0.28, 0, -0.9))], "paper" if i % 2 else "red", t=0.7)
    return Piece("SquarePost" if rope else "SquarePostEnd", m, lights=[("Lamp", (0.0, 1.6, 7.0), "#FFD49A")],
                 solid="the post, and the rope's line as a low wall",
                 note="the rope runs 16 studs along +X to the next post; its lantern hangs to +Y, into the square"
                 if rope else "a run's last post: no rope")


def house(height, name):
    def make():
        """A house behind the stalls, the street's skyline: a dark wall, a gabled roof with a red ridge, a few lit
        windows. Not in the request's list: the picked frame has them, so they're offered with the kit."""
        m = Mesh()
        m.box((16.0, 15.0, height), (0, -7.5, height / 2), "house", ink=True)
        for side in (-1, 1):
            m.slab((side * 8.8, 0.8, height - 0.3), (side * 8.8, -15.8, height - 0.3), (0, -15.8, height + 4.6),
                   (0, 0.8, height + 4.6), 0.4, sw="roof", edge="indigo", ink=True)
        m.flat([Vector((-8.0, 0.0, height)), Vector((8.0, 0.0, height)), Vector((0, 0.0, height + 4.3))], "house", t=0.9)
        m.box((0.5, 17.0, 0.5), (0, -7.5, height + 4.8), "red")
        rows = int((height - 9.0) // 5.0) + 1
        for row in range(rows):
            for col in (-1, 0, 1):
                lit = (row * 3 + col + int(height)) % 3 != 0
                m.box((2.2, 0.2, 2.6), (col * 4.6, 0.05, 11.0 + row * 5.0), "window" if lit else "dark", skip=("-y",))
                m.box((2.6, 0.24, 0.25), (col * 4.6, 0.05, 9.6 + row * 5.0), "wood", skip=("-y",))
        return Piece(name, m, note="offered: the skyline; its front stands a stud behind the stalls' backs")
    return make


PIECES = {"StallA": stall_a, "StallB": stall_b, "StallCorner": stall_corner, "LanternString": lantern_string,
          "Banner": banner_pole, "SignBoard": sign_board, "FestivalGate": festival_gate, "KeepersGate": keepers_gate,
          "KeepersDoor": keepers_door, "SquareFloor": square_floor, "SquareStrings": square_strings,
          "SquarePost": square_post, "SquarePostEnd": lambda: square_post(False), "StreetBay": street_bay,
          "HouseLow": house(15.0, "HouseLow"), "HouseTall": house(22.0, "HouseTall")}
SOLID = {"StallA": "a box, 12 by 7 by 9", "StallB": "a box, 12 by 7 by 9", "StallCorner": "a box, 12 by 12 by 9",
         "LanternString": "none: the poles stand in the gaps between stalls", "Banner": "none", "SignBoard": "a box, 7 by 1 by 8",
         "FestivalGate": "a box round each pillar's foot, 4.6 square", "KeepersGate": "the two piers and the two walls",
         "KeepersDoor": "a box, the leaf", "SquareStrings": "none: the poles stand outside the floor",
         "HouseLow": "a box, 16 by 15", "HouseTall": "a box, 16 by 15"}


# --- the dressing: where each piece stands ---------------------------------------------------------------------------

def plan():
    """The street dressed. Places are studs from the festival gate's middle at pavement level: `x` across (+ is the
    right-hand side walking in), `y` up the street; `turn` is degrees anticlockwise seen from above. A piece's front is
    its +Y, so a stall on the left turns -90 and one on the right +90. Returns the placements and the real lights."""
    packs, sq, keeper = STOPS["packs"], STOPS["square"], STOPS["keeper"]
    half = SQUARE / 2
    lo, hi = sq - half, sq + half
    places, lights = [], []

    def put(name, x, y, turn=0.0):
        places.append((name, round(x, 2), round(y, 2), turn))

    put("FestivalGate", 0, 0)
    put("KeepersGate", 0, keeper, 180)                    # its great lantern to the street
    put("KeepersDoor", -10, keeper)
    put("KeepersDoor", 10, keeper, 180)
    put("SquareFloor", 0, sq)
    put("SquareStrings", 0, sq)
    # the strings, one every bay, set so one hangs over each pack; none over the square, which has its canopy
    first = packs[0] - 2 * BAY
    bays = [first + k * BAY for k in range(-1, int((keeper - first) // BAY) + 1)]
    for y in bays:
        if not lo + BAY / 2 <= y <= hi - BAY / 2:         # the square's own floor lies there
            put("StreetBay", 0, y)
        if 0 < y < keeper - BAY / 2 and not lo < y < hi:
            put("LanternString", 0, y)
    # the stalls, a bay each, their gaps at the strings' poles; a corner stall at each corner of the square
    for side in (-1, 1):
        for k, ys in enumerate(bays[1:]):
            c = ys - side * (BAY / 2 - 3.0)
            clear = (8.0 <= c - 6 and c + 6 <= lo - 12) or (hi + 12 <= c - 6 and c + 6 <= keeper - 3)
            if not clear or (side > 0 and c < 16):        # the Festival Door's twin stands inside the gate, on the right
                continue
            put("StallB" if (k + (side > 0)) % 3 == 1 else "StallA", side * HALF, c, 90 if side > 0 else -90)
            if (k + (side > 0)) % 3 == 0:
                put("Banner", side * (HALF - 1.9), c - side * 6.3, 90 if side < 0 else -90)
    put("StallCorner", -(HALF + 6), lo, 0)
    put("StallCorner", HALF, lo - 6, 90)
    put("StallCorner", -HALF, hi + 6, -90)
    put("StallCorner", HALF + 6, hi, 180)
    # the square's edge: posts and ropes down both sides, the lanterns hanging in
    run = [sq + q for q in SQUARE_POSTS]
    for y in run[1:]:
        put("SquarePost", -half, y, -90)
    put("SquarePostEnd", -half, run[0], -90)
    for y in run[:-1]:
        put("SquarePost", half, y, 90)
    put("SquarePostEnd", half, run[-1], 90)
    # signs, where a stall line breaks: inside the gate, before the square, after it, before the keeper's gate
    for x, y, turn in ((-17.5, 6.0, -25), (-18.0, lo - 15.2, -25), (18.0, hi + 15.2, 25), (-17.5, keeper - 6.0, -25)):
        put("SignBoard", x, y, turn)
    # the skyline (offered): a house every 16 studs behind the stalls, set back where the square opens
    for side in (-1, 1):
        for k in range(38):
            y = (8.0 if side > 0 else 0.0) + 16.0 * k
            back = HALF + 8.0 + (6.0 if lo - 20 < y < hi + 20 else 0.0)
            put("HouseTall" if "LTLLTLTT"[(k + (side > 0) * 3) % 8] == "T" else "HouseLow", side * back, y, 90 if side > 0 else -90)
    # the real lights: a spot down from the string over each pack, the square's, the gates'
    for n, pack in enumerate(packs):
        lights.append((f"Pack{n + 1}Pool", 0.0, pack, POOL_HEIGHT, "#FFD49A", "spot"))
    lights.append(("SquarePool", 0.0, sq, 12.0, "#FFD49A", "spot"))
    lights.append(("GatePool", 0.0, 0.0, 13.0, "#FFD49A", "spot"))
    lights.append(("KeeperLamp", 0.0, keeper - 4.0, 12.5, "#8CF6FF", "point"))
    return places, lights


# --- the kit on the street, under the look script's camera -----------------------------------------------------------

# By phase. At night the floor is darker, so a pool does more of the work of a Shade's edge.
GLOWS, FLOOR_GLOWS, REAL_LIGHTS = {"M": GLOW, "N": 2.4}, {"M": FLOOR_GLOW, "N": 1.1}, {"M": REAL_LIGHT, "N": 1.5}
PHASE = {"key": "M"}                                                                # the phase a render is in


def maps():
    key = PHASE["key"]
    return {"Kit": ("#FFFFFF", GLOWS[key]), "Street": (POOL_TINT, FLOOR_GLOWS[key]), "Square": (POOL_TINT, FLOOR_GLOWS[key])}


def kit_material(out: Path, wears, prefix="LanternRow", glow=None):
    """A piece's pictures as Roblox draws them: the colour, and a glow that is mask x strength x tint x colour.
    Another kit gives its own `prefix` and its `glow`, a tint and a strength."""
    tint, strength = glow or maps()[wears]
    mat, p = look._new(prefix + wears)
    mat.use_backface_culling = True                       # as the engine draws a MeshPart: the ink is a hull turned inside out
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    col = nodes.new("ShaderNodeTexImage")
    col.image = bpy.data.images.load(str(out / f"{prefix}_{wears}_Color.png"), check_existing=True)
    lit = nodes.new("ShaderNodeTexImage")
    lit.image = bpy.data.images.load(str(out / f"{prefix}_{wears}_Glow.png"), check_existing=True)
    lit.image.colorspace_settings.name = "Non-Color"
    warm = nodes.new("ShaderNodeMix")
    warm.data_type, warm.blend_type = "RGBA", "MULTIPLY"
    warm.inputs[0].default_value = 1.0
    warm.inputs[7].default_value = (*look.srgb(tint), 1)
    em = nodes.new("ShaderNodeEmission")
    mul = nodes.new("ShaderNodeMath")
    mul.operation, mul.inputs[1].default_value = "MULTIPLY", strength
    add = nodes.new("ShaderNodeAddShader")
    links.new(col.outputs["Color"], p.inputs["Base Color"])
    links.new(col.outputs["Color"], warm.inputs[6])
    links.new(warm.outputs[2], em.inputs["Color"])
    links.new(lit.outputs["Color"], mul.inputs[0])
    links.new(mul.outputs[0], em.inputs["Strength"])
    links.new(p.outputs[0], add.inputs[0])
    links.new(em.outputs[0], add.inputs[1])
    look._fogged(mat, add.outputs[0])
    return mat


class Stock:
    """Each piece built once, as one mesh with its ink, and stood wherever the plan says."""

    def __init__(self, out, scene, kit):
        self.scene, self.kit, self.made = scene, kit, {}
        self.mats = {name: kit_material(out, name) for name in maps()}

    def stand(self, name, tag, at, turn):
        if name not in self.made:
            piece = PIECES[name]()
            self.made[name] = (piece, piece.mesh.whole().to_object(name, self.mats[piece.maps]))
        piece, data = self.made[name]
        obj = bpy.data.objects.new(f"{name}_{tag}", data)
        obj.location, obj.rotation_euler = at, (0, 0, math.radians(turn))
        self.scene.collection.objects.link(obj)
        self.kit.pieces.append(obj)
        return obj


def kit_street(out: Path):
    """The look script's `street`, dressed from the plan. The look's fight is staged at fixed places, so the plan is
    slid along the street until a pack's spot lies under it: the second pack from the gate's end, the fifth from the
    far end, so both frames have street before and behind."""

    def street(scene, d, images, near=0.0):
        far = near > 100
        write_pictures(out, d)
        kit = look.Kit(d, images)
        stock = Stock(out, scene, kit)
        fight = near - 11.0 if far else 11.0
        slide = fight - STOPS["packs"][4 if far else 1]
        low, high = (fight - 300, fight + 70) if far else (fight - 70, fight + 300)
        places, lights = plan()
        for i, (name, x, y, turn) in enumerate(places):
            if low <= y + slide <= high:
                stock.stand(name, i, (x, y + slide, 0), turn)
        colour, watts, _ = d["string_light"]
        for name, x, y, z, code_, kind in lights:
            if low <= y + slide <= high:
                lamp = look.light(kit, scene, name, (x, y + slide, z), code_, watts * REAL_LIGHTS[PHASE["key"]], 40.0,
                                  kind="SPOT" if kind == "spot" else "POINT")
                lamp.data.use_shadow = False              # Shadows off in the game too: a lantern never blots its own pool
                if kind == "spot":
                    lamp.data.spot_size, lamp.data.spot_blend = math.radians(POOL_CONE), 0.7
        kit.block("Under", (400, 380, 0.4), (0, (low + high) / 2, -0.25), look.painted("Under", d["ground"][1], d["ground"][1]))
        look.paper_in_air(kit, np.random.default_rng(5), near)
        for obj in kit.pieces:
            if obj.name.startswith(("Scrap", "LanternString", "SquareStrings")):
                obj.visible_shadow = False                # paper is particles, and a string's CastShadow is off: no blots
        for name, (piece, data) in stock.made.items():
            print(f"KIT {name}: {len(data.polygons)} faces")
        return kit

    return street


# --- the sky: six faces by direction, and the numbers the engine takes -------------------------------------------------

# Roblox's faces as Studio shows them (the handbook, visuals/lighting-and-mood.md, "Skies"), here in Blender's frame
# (Roblox X is X, Roblox Y is Z, Roblox Z is -Y): where a face's centre looks, and its top. Ft looks up the street.
FACES = {"Ft": ((0, 1, 0), (0, 0, 1)), "Lf": ((1, 0, 0), (0, 0, 1)), "Bk": ((0, -1, 0), (0, 0, 1)),
         "Rt": ((-1, 0, 0), (0, 0, 1)), "Up": ((0, 0, 1), (1, 0, 0)), "Dn": ((0, 0, -1), (-1, 0, 0))}
SKY_PX = 1024
PHASES = {"M": "Dusk", "N": "Night"}
# The engine's starting values, from the pair of presets that passed review in a dark, hazy world (the handbook, "A
# starting recipe"): practice, to be tuned in the engine against the two targets, not measured here.
RECIPE = {
    "Dusk": dict(atmosphere=dict(Density=0.22, Offset=0.12, Haze=1.0, Glare=0.2),
                 bloom=dict(Intensity=0.6, Size=24, Threshold=1.3), environmentDiffuseScale=0.6),
    "Night": dict(atmosphere=dict(Density=0.28, Offset=0.10, Haze=0.8, Glare=0.1),
                  bloom=dict(Intensity=0.85, Size=28, Threshold=1.2), environmentDiffuseScale=0.6),
}


def encode(linear):
    linear = np.clip(np.asarray(linear, np.float32), 0, 1)
    return np.where(linear <= 0.0031308, linear * 12.92, 1.055 * np.power(linear, 1 / 2.4) - 0.055)


def hex_of(linear):
    return "#" + "".join(f"{int(round(float(v) * 255)):02X}" for v in encode(linear))


def skies(out: Path, key):
    """The direction's painted sky as Roblox's six faces: each pixel drawn from its own direction, so no seam."""
    d = look.DIRECTIONS[key]
    scene = bl.reset_scene()
    look.sky(scene, d)
    eevee(scene, (SKY_PX, SKY_PX), 16)
    cam = bpy.data.objects.new("SkyCam", bpy.data.cameras.new("SkyCam"))
    cam.data.sensor_fit, cam.data.angle = "HORIZONTAL", math.radians(90.0)
    scene.collection.objects.link(cam)
    scene.camera = cam
    rng = np.random.default_rng(3)
    for face, (ahead, top) in FACES.items():
        f, u = Vector(ahead), Vector(top)
        cam.rotation_euler = Matrix((f.cross(u), u, -f)).transposed().to_euler()
        linear = look.render_linear(scene, out / "_sky.exr")
        page = np.ones((SKY_PX, SKY_PX, 4), np.float32)
        page[..., :3] = encode(linear[..., :3]) + (rng.random((SKY_PX, SKY_PX, 1), np.float32) - 0.5) / 255   # no banding
        rs.save(np.clip(page, 0, 1), out / f"LanternRow_Sky{PHASES[key]}_{face}.png")
    (out / "_sky.exr").unlink(missing_ok=True)


def lighting(key):
    """A direction as the builder's Config takes it. A colour, a direction, a place and a cone carry over as they
    are. A strength is this script's own unit: it's given so dusk and night keep their ratio, beside the engine's
    starting value where the handbook has one."""
    d, phase = look.DIRECTIONS[key], PHASES[key]
    az, el, sun_code, sun_strength, shadow = d["sun"]
    a, e = math.radians(az), math.radians(el)
    amb_code, amb_strength = d["ambient"]
    fog_code, fog_k = d["fog"]
    threshold, intensity, sizes = d["bloom"]
    pool_code, pool_watts, _ = d["string_light"]
    lead_code, lead_watts, lead_reach = d["fighter_light"]
    ahead, up = d["fighter_light_ahead"]
    return dict(
        phase=phase,
        sky=dict(faces={f: f"LanternRow_Sky{phase}_{f}.png" for f in FACES}, StarCount=0, SunAngularSize=0,
                 MoonAngularSize=0, note="our own stars and moon are in the faces; the afterglow is in Ft, up the street "
                 "(-Z). A day clock in both phases: at a night clock Roblox darkens a custom sky."),
        sun=dict(toward=[round(math.sin(a) * math.cos(e), 3), round(math.sin(e), 3), round(-math.cos(a) * math.cos(e), 3)],
                 elevationDegrees=el, colour=sun_code, strength=sun_strength, shadows=shadow,
                 note="the one directional light, high and from behind the player walking in, so the fight is lit the "
                      "same from either end; `toward` is the unit vector to it with the street running to -Z"),
        ambient=dict(colour=amb_code, strength=amb_strength, asOne=hex_of(np.array(look.srgb(amb_code), np.float32) * amb_strength),
                     note="a flat fill, Ambient and OutdoorAmbient alike; `asOne` is colour times strength"),
        atmosphere=dict(Color=fog_code, Decay=d.get("fog_away", fog_code),
                        hazeAt={str(n): round(1 - math.exp(-fog_k * n), 2) for n in (40, 100, 300)},
                        start=RECIPE[phase]["atmosphere"],
                        note="Color is the haze toward the street's far end, Decay the haze back toward the gate; "
                             "`hazeAt` is how much of a thing the haze has taken at that many studs in these frames"),
        bloom=dict(here=dict(threshold=threshold, intensity=intensity, sizesPx=list(sizes)), start=RECIPE[phase]["bloom"]),
        environmentDiffuseScale=RECIPE[phase]["environmentDiffuseScale"],
        glow=dict(kit=GLOWS[key], floor=FLOOR_GLOWS[key], floorTint=POOL_TINT,
                  note="EmissiveStrength for the kit's pieces and for the two floors, as these frames have them"),
        pools=dict(colour=pool_code, coneDegrees=POOL_CONE, up=POOL_HEIGHT, strength=round(pool_watts * REAL_LIGHTS[key]),
                   note="the SpotLight over each pack, the square's and the gate's (the plan's lights), Shadows off"),
        lead=dict(colour=lead_code, ahead=ahead, up=up, range=lead_reach, strength=lead_watts,
                  note="one PointLight carried by the lead: `ahead` studs toward his target, `up` studs over the "
                       "ground, under the hat's height"),
        targets=dict(lead=look.TARGETS["lead"], edge=look.TARGETS["edge"]))


def sky_sheet(out: Path, keys):
    """Each phase's six faces as a walk round the horizon and the two caps, with its numbers."""
    rs.OUT = out
    k = 0.44
    side = round(SKY_PX * k)
    W = 48 + 4 * side + 2 * (side // 2) + 24
    H = 100 + len(keys) * (side + 120) + 10
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    ink, soft = "#F2ECE2", "#B9B2C4"
    text = [(24, 18, 26, "Lantern Row's sky: six faces a phase, drawn by direction, and the numbers beside them (AR5, section 2).", ink),
            (24, 54, 15, "Left to right: up the street (Ft), the right-hand side (Lf), back to the gate (Bk), the left-hand side (Rt); "
                         "then straight up and straight down, half size.", soft)]
    y = 100
    for key in keys:
        phase = PHASES[key]
        x = 24
        for face in ("Ft", "Lf", "Bk", "Rt"):
            rs.paste(page, rs.shrink(rs.load(out / f"LanternRow_Sky{phase}_{face}.png"), k), x, y)
            x += side
        x += 24
        for face in ("Up", "Dn"):
            rs.paste(page, rs.shrink(rs.load(out / f"LanternRow_Sky{phase}_{face}.png"), k / 2), x, y)
            x += side // 2
        n = lighting(key)
        at, bloom, sun = n["atmosphere"], n["bloom"], n["sun"]
        lines = [
            f"{phase}. The one directional light: {sun['colour']}, {sun['elevationDegrees']:g} degrees up, toward {sun['toward']}, "
            f"strength {sun['strength']:g}. The fill: {n['ambient']['colour']} at {n['ambient']['strength']:g} ({n['ambient']['asOne']}).",
            f"Haze: {at['Color']} up the street, {at['Decay']} back toward the gate; it has taken "
            + ", ".join(f"{round(100 * v)}% at {s_} studs" for s_, v in at["hazeAt"].items())
            + f". To start in the engine: Density {at['start']['Density']}, Offset {at['start']['Offset']}, Haze {at['start']['Haze']}, "
              f"Glare {at['start']['Glare']}.",
            f"Bloom here: past {bloom['here']['threshold']}, {bloom['here']['intensity']} strong. To start: Intensity "
            f"{bloom['start']['Intensity']}, Size {bloom['start']['Size']}, Threshold {bloom['start']['Threshold']}. "
            f"Glow: the kit {n['glow']['kit']}, the floors {n['glow']['floor']} tinted {n['glow']['floorTint']}.",
            f"The pools: {n['pools']['colour']}, a {n['pools']['coneDegrees']:g} degree cone from {n['pools']['up']} studs. The lead's light: "
            f"{n['lead']['colour']}, {n['lead']['ahead']} studs ahead and {n['lead']['up']} up, range {n['lead']['range']:g}.",
        ]
        for i, line in enumerate(lines):
            text.append((24, y + side + 12 + 22 * i, 14, line, ink if i == 0 else soft))
        y += side + 120
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "lantern_row_sky_sheet.png")
    print("SKY SHEET", W, H)


# --- each piece alone ------------------------------------------------------------------------------------------------

SHOT = (460, 380)


def eevee(scene, size, samples):
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = *size, 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = samples
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass


def pieces(out: Path, key="M"):
    """Each piece alone on a patch of the tile, in the direction's own sky with a plain light from the camera's side,
    so its colours and its ink read; and pieces.json: triangles, size."""
    d = dict(look.DIRECTIONS[key], sun=(-35.0, 48.0, "#FFF4E8", 2.2, True), ambient=("#8A88B0", 0.8))
    scene = bl.reset_scene()
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=0.0, azimuth=0.0, away=None)
    images = look.glyph_images(out)
    write_pictures(out, d)
    kit = look.Kit(d, images)
    stock = Stock(out, scene, kit)
    look.sky(scene, d)
    look.sun(scene, d)
    eevee(scene, SHOT, 24)
    tile, p = look._new("Tile")
    tex = tile.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(str(out / "LanternRow_Paving_Color.png"))
    tile.node_tree.links.new(tex.outputs["Color"], p.inputs["Base Color"])
    look._fogged(tile, p.outputs[0])
    facts, cams = {}, {}
    for i, name in enumerate(PIECES):
        at = Vector((i * 400.0, 0, 0))
        obj = stock.stand(name, "alone", at, 0)
        piece = stock.made[name][0]
        pts = [Vector(v) for v in piece.mesh.v]
        low = Vector([min(q[k] for q in pts) for k in range(3)])
        high = Vector([max(q[k] for q in pts) for k in range(3)])
        flat = high.z - low.z < 1.0
        if not flat:
            span = max(high.x - low.x, high.y - low.y) / 2 + 6
            ground = Mesh(None)
            mid = (low + high) / 2
            ground.face([Vector((mid.x - span, mid.y - span, -0.02)), Vector((mid.x + span, mid.y - span, -0.02)),
                         Vector((mid.x + span, mid.y + span, -0.02)), Vector((mid.x - span, mid.y + span, -0.02))],
                        [(0, 0), (span / 4, 0), (span / 4, span / 4), (0, span / 4)])
            g = bpy.data.objects.new(f"Ground{name}", ground.to_object(f"Ground{name}", tile))
            g.location = at
            scene.collection.objects.link(g)
        centre, radius = (low + high) / 2, (high - low).length / 2
        aim = Vector((0.5, 0.78, 0.36)).normalized() if not flat else Vector((0.25, -0.55, 0.8)).normalized()
        cam = bpy.data.objects.new(f"Cam{name}", bpy.data.cameras.new(f"Cam{name}"))
        cam.data.lens, cam.data.clip_end = 70.0, 4000.0
        cam.location = at + centre + aim * radius * 4.4
        cam.rotation_euler = (-aim).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(cam)
        cams[name] = cam
        data = stock.made[name][1]
        data.calc_loop_triangles()
        facts[name] = dict(triangles=len(data.loop_triangles), ink=piece.mesh.ink.tris() if piece.mesh.ink else 0, maps=piece.maps,
                           size=[round(high[k] - low[k], 1) for k in range(3)], lights=len(piece.lights), note=piece.note)
    for name, cam in cams.items():
        scene.camera = cam
        linear = look.render_linear(scene, out / f"piece_{name}.exr")
        rs.save(look.finish(linear, d), out / f"piece_{name}.png")
        (out / f"piece_{name}.exr").unlink(missing_ok=True)
    (out / "pieces.json").write_text(json.dumps(facts, indent=1), encoding="utf-8")
    print(json.dumps({k: v["triangles"] for k, v in facts.items()}))


# --- the budget, from the plan -----------------------------------------------------------------------------------------

def budget(facts, reach=220.0):
    """Pieces, triangles and lights: the whole street, and the most within `reach` studs of anyone standing on it."""
    places, lights = plan()
    total = dict(pieces=len(places), triangles=sum(facts[n]["triangles"] for n, *_ in places), lights=len(lights) + 1)
    worst = dict(pieces=0, triangles=0, lights=0)
    for y0 in np.arange(0.0, STOPS["keeper"] + 1, 8.0):
        near = [n for n, _, y, _ in places if abs(y - y0) <= reach]
        lit = sum(1 for l in lights if abs(l[2] - y0) <= reach) + 1          # and the lead's own
        got = dict(pieces=len(near), triangles=sum(facts[n]["triangles"] for n in near), lights=lit)
        for k in got:
            if got[k] > worst[k]:
                worst[k], worst[k + "_at"] = got[k], float(y0)
    counts = {}
    for n, *_ in places:
        counts[n] = counts.get(n, 0) + 1
    return dict(reach_studs=reach, whole_street=total, worst_within_reach=worst, counts=counts)


# --- the drifting paper ----------------------------------------------------------------------------------------------

PAPER_BOXES = 8                 # boxes of air, gate to keeper's gate, each with one emitter
PAPER_UP = (4.0, 14.5)          # where scraps are born: the look's band, 2.5 to 14 (lantern_row_look.paper_in_air),
                                # raised by what a scrap sinks in a life, so the scraps that show fill the look's band
                                # (simulated, weighted by the fade: 5% under 3.5, half under 8.5, 95% under 13.5,
                                # against the look's 3.1, 8.25, 13.4; 0.01% of what shows is under the paving)
PAPER_PER_STUD = 70 / 108.0     # the look's still: 70 scraps alive over 108 studs of street
PAPER_LIFE = (7.0, 10.0)        # seconds
PAPER_SPEED = (0.2, 0.7)        # the launch's push, any way, studs/s
PAPER_DRAG = 0.3                # the push halves every 1 / 0.3 s
PAPER_WIND = (0.04, -0.1, -0.16)  # studs/s², world: a little across, down, and up the street (-Z on this plan)


def paper():
    """The drifting paper's emitters for the builder (TR8): the look's scraps, set moving. Each box of air over the
    street holds one ParticleEmitter on LanternRow_Paper.png, emitting through its volume. A scrap fades in where it is,
    drifts up the street and down at a walk's tenth, spins, turns edge-on now and then, and fades before the paving."""
    span = STOPS["keeper"]
    length = span / PAPER_BOXES
    life = sum(PAPER_LIFE) / 2
    rate = PAPER_PER_STUD * length / life
    tau = 1 / (PAPER_DRAG * math.log(2))  # Drag as the docs give it: speed halves every 1 / Drag seconds
    carried = tau * (1 - math.exp(-life / tau))  # how far a launch's 1 stud/s carries in a mean life
    blown = [a * tau * (life - carried) for a in PAPER_WIND]  # and how far the wind takes it
    worst = PAPER_UP[0] + blown[1] - PAPER_SPEED[1] * carried
    flips = [[0, 0], [0.08, 0], [0.13, 1], [0.18, 0], [0.4, 0], [0.45, 1], [0.5, 0], [0.7, 0], [0.75, 1], [0.8, 0], [1, 0]]
    return dict(
        note="One anchored Part a box, invisible, colliding with nothing, at CFrame.new(across, floor + up, gateZ - along), "
             "size [across, up, along] as `size`; one ParticleEmitter in it with `emitter`. The numbers are the look's "
             "still in motion and are seeds, live through Tune: the targets below decide. The same at dusk and at "
             "night: LightInfluence 0.78 is the look's paper, lit 22% by itself, so a scrap catches the pools and "
             "never vanishes between them. Performance mode halves Rate.",
        picture="maps/LanternRow_Paper.png",
        boxes=[dict(across=0.0, along=round(length * (i + 0.5), 2), up=round(sum(PAPER_UP) / 2, 2),
                    size=[2 * (look.HALF - 2), round(PAPER_UP[1] - PAPER_UP[0], 2), round(length, 2)])
               for i in range(PAPER_BOXES)],
        emitter=dict(
            Texture="LanternRow_Paper.png", FlipbookLayout="Grid2x2", FlipbookMode="Loop", FlipbookStartRandom=True,
            FlipbookFramerate=[0, 0], Shape="Box", ShapeStyle="Volume", EmissionDirection="Top",
            Rate=round(rate, 2), Lifetime=list(PAPER_LIFE), Speed=list(PAPER_SPEED), SpreadAngle=[180, 180],
            Acceleration=list(PAPER_WIND), Drag=PAPER_DRAG, WindAffectsDrag=False,
            Rotation=[0, 360], RotSpeed=[-60, 60], Orientation="FacingCamera",
            Size=[[0, 0.8, 0.2], [1, 0.8, 0.2]], Squash=flips,
            Transparency=[[0, 1], [0.12, 0], [0.85, 0], [1, 1]],
            Color="#FFFFFF", LightInfluence=0.78, LightEmission=0, Brightness=1, ZOffset=0, LockedToPart=False),
        keys="A NumberSequence is [time, value] or [time, value, envelope]; a NumberRange is [min, max].",
        reads=[f"about {PAPER_PER_STUD * span:.0f} scraps alive on the whole street, {PAPER_PER_STUD * 220:.0f} within "
               "the budget's 220-stud reach",
               f"over a mean life of {life:g} s the wind takes a scrap {-blown[2]:.1f} studs up the street, "
               f"{blown[0]:.1f} across, and down {-blown[1]:.1f}; its launch adds up to {PAPER_SPEED[1] * carried:.1f} "
               f"any way. So at worst a scrap born lowest, at {PAPER_UP[0]:g}, ends "
               f"{abs(worst):.1f} studs {'under' if worst < 0 else 'over'} the paving, by then faded",
               "Size 0.8 shows a scrap about 0.55 studs long, as the look's (a scrap fills about 70% of its cell)",
               "Squash above 0 narrows a scrap (the Roblox docs): three times a life it turns edge-on and back"],
        targets=["it reads as paper in the air, never as snow, sparks or confetti, at dusk and at night",
                 "never the brightest thing near the lead; it never crosses the fight's read. If a scrap at head height "
                 "does, the boxes' floor rises, over a fighter's head",
                 "no scrap sinks visibly into the paving: it has faded first"],
        install_checks=["FlipbookFramerate 0 should hold each scrap on its random first frame. If the engine changes "
                        "frames anyway, 0.1: a scrap turns over at most once a life",
                        "a box's volume emits all through it, and SpreadAngle 180 throws a scrap any way, whatever "
                        "the face"])


# --- the handoff -----------------------------------------------------------------------------------------------------

def write_plan(out: Path, facts):
    places, lights = plan()
    (out / "plan.json").write_text(json.dumps(dict(
        origin="the festival gate's middle at pavement level",
        axes="`across` is + to the right walking in (Roblox +X when the street runs toward -Z); `along` is studs up the "
             "street from the gate; `turn` is degrees anticlockwise seen from above",
        toRoblox="CFrame.new(across, 0, gateZ - along) * CFrame.Angles(0, math.rad(turn), 0)",
        spacing=SPACING, bay=round(BAY, 4), stops=STOPS,
        placements=[dict(piece=n, across=x, along=y, turn=t) for n, x, y, t in places],
        lights=[dict(name=n, across=x, along=y, up=z, colour=c, kind=k, cone=POOL_CONE if k == "spot" else None)
                for n, x, y, z, c, k in lights],
        lightsNote="Every static light the street has: a SpotLight straight down (Face Bottom, Angle = cone) or a "
                   "PointLight, Shadows off. Every other pool is painted in a floor's glow picture. The lead carries "
                   "one PointLight more. Brightness and Range are tuned in the engine against the two targets.",
        budget=budget(facts), paper=paper()), indent=1), encoding="utf-8")


def export(out: Path, key="M"):
    d = look.DIRECTIONS[key]
    scene = bl.reset_scene()
    folders = {name: out / name for name in ("meshes", "maps")}
    for f in folders.values():
        f.mkdir(parents=True, exist_ok=True)
    write_pictures(folders["maps"], d)
    listing, facts = {}, {}
    for name, make in PIECES.items():
        piece = make()
        data = piece.mesh.whole().to_object(name, None)
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        tris = bl.export_mesh_json(obj, folders["meshes"] / f"{name}.json", uv=True)
        record = json.loads((folders["meshes"] / f"{name}.json").read_text())
        ps = np.array(record["p"], np.float32).reshape(-1, 3)
        size = [round(float(v), 3) for v in ps.max(0) - ps.min(0)]
        tint, strength = maps()[piece.maps]
        listing[name] = dict(
            mesh=f"meshes/{name}.json", triangles=tris, vertices=len(ps), centre=record["c"], size=size,
            colour=f"maps/LanternRow_{piece.maps}_Color.png", glow=f"maps/LanternRow_{piece.maps}_Glow.png",
            glowTint=tint, glowStrength=strength, collision=SOLID.get(name, piece.solid),
            lights=[dict(name=n, at=[round(at[0], 3), round(at[2], 3), round(-at[1], 3)], colour=c) for n, at, c in piece.lights],
            note=piece.note)
        facts[name] = dict(triangles=tris)
    manifest = dict(
        unit="1 = 1 stud",
        frame="Roblox's: a piece's front (Blender +Y) is -Z. A MeshPart goes at the piece's place times `centre`. "
              "A light's `at` is in the piece's own frame.",
        surface="one SurfaceAppearance per MeshPart: ColorMap `colour`, EmissiveMaskContent `glow`, EmissiveTint "
                "`glowTint`, EmissiveStrength from `glowStrength` (tuned in the engine). Single sided: each piece's ink "
                "is in its mesh, a hull turned inside out on the atlas's ink texel, and a cloth is two faces, one each way.",
        shadows="CastShadow off on LanternString, SquareStrings and the two floors: a lantern never blots its own pool.",
        maps={"LanternRow_Paving_Color.png": f"the plain paving, a tile {PAVING[1]:g} studs square, for a Texture on a Part",
              "LanternRow_Paper.png": "drifting paper: a 2 by 2 flipbook for a ParticleEmitter"},
        pieces=listing)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    write_plan(out, facts)
    print(json.dumps(budget(facts), indent=1))


# --- the plan, seen from above -----------------------------------------------------------------------------------------

PLAN_COLOURS = {"StallA": "#C4424E", "StallB": "#3A3A7A", "StallCorner": "#D8A848", "HouseLow": "#2A2A4E", "HouseTall": "#22224A",
                "FestivalGate": "#E8D8C0", "KeepersGate": "#8CF6FF", "KeepersDoor": "#8CF6FF", "SquareFloor": "#8A8098",
                "StreetBay": "#5E566E", "Banner": "#E8D8C0", "SignBoard": "#E8D8C0", "SquarePost": "#C8B088",
                "SquarePostEnd": "#C8B088", "LanternString": "#FFD49A", "SquareStrings": "#FFD49A"}


def plan_picture(out: Path):
    """The dressing plan from above: the gate at the left, the keeper's gate at the right, the right-hand side of the
    street (walking in) at the bottom. Each piece is its footprint; a pool is a real light, a dot a pack's spot."""
    rs.OUT = out
    k, x0, y0 = 3.0, 16.0, 46.0                            # pixels a stud; studs before the gate; studs each side
    places, lights = plan()
    W, H = round((STOPS["keeper"] + 2 * x0) * k) + 48, round(2 * y0 * k) + 150
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    along, across = (xx - 24) / k - x0, (yy - 96) / k - y0
    field = (yy >= 96) & (yy < 96 + 2 * y0 * k)
    bounds = {}
    for name, make in PIECES.items():
        pts = np.array(make().mesh.v, np.float32)
        bounds[name] = (pts[:, 0].min(), pts[:, 0].max(), pts[:, 1].min(), pts[:, 1].max())
    order = ("StreetBay", "SquareFloor", "HouseLow", "HouseTall", "StallA", "StallB", "StallCorner", "FestivalGate",
             "KeepersGate", "KeepersDoor", "SquarePost", "SquarePostEnd", "Banner", "SignBoard")
    for wanted in order:
        for name, x, y, turn in places:
            if name != wanted:
                continue
            a = math.radians(turn)
            dx, dy = across - x, along - y
            px, py = dx * math.cos(a) + dy * math.sin(a), -dx * math.sin(a) + dy * math.cos(a)   # into the piece's frame
            lx, hx_, ly, hy = bounds[name]
            grow_ = 0.25 if hx_ - lx < 1.0 or hy - ly < 1.0 else 0.0
            inside = field & (px >= lx - grow_) & (px <= hx_ + grow_) & (py >= ly - grow_) & (py <= hy + grow_)
            edge = inside & ((px < lx + 0.4) | (px > hx_ - 0.4) | (py < ly + 0.4) | (py > hy - 0.4))
            colour = np.array(look.srgb(PLAN_COLOURS[name]), np.float32)
            page[inside, :3] = encode(colour * (0.55 if name in ("StreetBay", "SquareFloor") else 0.9))
            if name != "StreetBay":
                page[edge, :3] = encode(colour * 0.35)
    for name, x, y, turn in places:                        # the strings: a line across, slanting six studs
        if name == "LanternString":
            line = field & (np.abs(along - y - across * 6.0 / (2 * HALF - 0.8)) < 0.3) & (np.abs(across) < HALF)
            page[line, :3] = encode(np.array(look.srgb("#FFD49A"), np.float32))
    for name, x, y, z, code_, kind in lights:              # the real lights: a ring on the ground
        r = np.hypot(across - x, along - y)
        reach = z * math.tan(math.radians(POOL_CONE / 2)) if kind == "spot" else 8.0
        ring = field & (np.abs(r - reach) < 0.45)
        page[ring, :3] = encode(np.array(look.srgb(code_), np.float32))
    for y in STOPS["packs"]:
        page[field & (np.hypot(across, along - y) < 1.2), :3] = (1.0, 1.0, 1.0)
    ink, soft = "#F2ECE2", "#B9B2C4"
    b = json.loads((out / "plan.json").read_text(encoding="utf-8"))["budget"] if (out / "plan.json").exists() else None
    text = [(24, 18, 24, "Lantern Row dressed, from above: the festival gate at the left, the keeper's gate at the right; the "
                         "right-hand side walking in is at the bottom (AR5, section 2).", ink),
            (24, 52, 14, "Red: the counter stall. Indigo: the prize stall. Mustard: a corner stall. Dark: the skyline's houses. A warm "
                         "line: a lantern string, its pool painted on the bay under it. A ring: a real light. A white dot: a pack.", soft),
            (24, 72, 14, f"One rhythm: a bay is {BAY:.2f} studs (a stall with its gap, a string, a module of paving), six to a stop. "
                         "A string hangs over every pack; the square has its own canopy.", soft)]
    for label, y in (("the gate", 0.0), ("the square", STOPS["square"]), ("the keeper's gate", STOPS["keeper"])) \
            + tuple((f"pack {i + 1}", y) for i, y in enumerate(STOPS["packs"])):
        left = min(24 + round((y + x0) * k) - 30, W - 24 - 8 * len(f"{label}, {y:g}"))
        text.append((left, 96 + round(2 * y0 * k) + 8, 13, f"{label}, {y:g}", ink))
    if b:
        t, w_ = b["whole_street"], b["worst_within_reach"]
        text.append((24, H - 24, 14, f"The whole street: {t['pieces']} pieces, {t['triangles']:,} triangles, {t['lights']} lights with the "
                                     f"lead's. The most within {b['reach_studs']:g} studs of anyone on it: {w_['pieces']} pieces, "
                                     f"{w_['triangles']:,} triangles, {w_['lights']} lights (the ceiling is 14).", ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "lantern_row_plan.png")
    print("PLAN", W, H)


# --- the review sheet ------------------------------------------------------------------------------------------------

def sheet(out: Path):
    facts = json.loads((out / "pieces.json").read_text(encoding="utf-8"))
    shots = {n: rs.load(out / f"piece_{n}.png") for n in facts}
    names = ("Kit_Color", "Kit_Glow", "Street_Color", "Street_Glow", "Square_Color", "Square_Glow", "Paving_Color", "Paper")
    pics = {n: rs.load(out / f"LanternRow_{n}.png") for n in names}
    frames = [(tag, rs.load(out / f"kit_{tag}_frame.png"), json.loads((out / f"kit_{tag}.json").read_text()))
              for tag in ("M", "M_far", "N", "N_far") if (out / f"kit_{tag}_frame.png").exists()]
    b = budget(facts)
    rs.OUT = out
    cols, gap = 4, 12
    rows = -(-len(shots) // cols)
    W = 24 * 2 + cols * SHOT[0] + (cols - 1) * gap
    fw = (W - 48 - gap) // 2
    fh = round(fw * 9 / 16)
    H = 96 + rows * (SHOT[1] + 52) + 40 + 340 + 60 + -(-max(len(frames), 1) // 2) * (fh + 70) + 130
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    ink, soft = "#F2ECE2", "#B9B2C4"
    text = [(24, 18, 26, "Lantern Row's kit: the pieces, their maps, and the street dressed from the plan (AR5, section 2).", ink),
            (24, 54, 15, "Each piece is one mesh with its ink in it, wearing one colour picture and one glow picture. Shown alone in a plain "
                         "light on the paving tile; triangles count the ink.", soft)]
    y = 96
    for i, (name, shot) in enumerate(shots.items()):
        x, yy = 24 + (i % cols) * (SHOT[0] + gap), y + (i // cols) * (SHOT[1] + 52)
        rs.paste(page, shot, x, yy)
        f = facts[name]
        text.append((x, yy + SHOT[1] + 6, 15, f"{name}: {f['triangles']} triangles", ink))
        said = textwrap.wrap(f"{f['size'][0]:g} by {f['size'][1]:g} by {f['size'][2]:g} studs. {f['note']}", 96)[:2]
        for j, line in enumerate(said):
            text.append((x, yy + SHOT[1] + 25 + 13 * j, 11, line, soft))
    y += rows * (SHOT[1] + 52) + 8
    text.append((24, y, 16, "The maps: the kit's colour and its glow (what each texel gives off); a bay of the street and the square's floor, "
                            "each with its painted light; the plain tile; the paper", ink))
    y += 32
    x = 24
    for name, scale, dy in (("Kit_Color", 0.27, 0), ("Kit_Glow", 0.27, 0), ("Street_Color", 0.42, 0), ("Street_Glow", 0.42, 160),
                            ("Square_Color", 0.27, 0), ("Square_Glow", 0.27, 0), ("Paving_Color", 0.22, 0), ("Paper", 0.44, 0)):
        pic = rs.shrink(pics[name], scale)
        if name == "Street_Glow":
            x -= pic.shape[1] + 12
        if name == "Paper":
            back = rs.canvas(pic.shape[1], pic.shape[0], (0.16, 0.14, 0.22))
            rs.paste(back, pic, 0, 0)
            pic = back
        rs.paste(page, pic, x, y + dy)
        text.append((x, y + dy + pic.shape[0] + 4, 11, name.replace("_", ", ").lower(), soft))
        x += pic.shape[1] + 12
    text.append((W - 306, y + 136, 11, "each at 64 pixels, over dark", soft))
    for i, name in enumerate(names):                      # the size a moderation queue's tile shows
        small = rs.shrink(pics[name], 64 / pics[name].shape[1])
        back = rs.canvas(64, 64, (0.05, 0.045, 0.07))
        rs.paste(back, small, 0, (64 - small.shape[0]) // 2)
        rs.paste(page, back, W - 306 + (i % 4) * 70, y + 154 + (i // 4) * 70)
    y += 340
    text.append((24, y, 16, "From the player's camera, the street dressed from the plan. Targets: the lead at least 1.3 times what's round him, "
                            "a Shade's edge at least 0.15", ink))
    y += 30
    said = {"M": "dusk, from the gate's end", "M_far": "dusk, from the far end, looking back", "N": "night, from the gate's end",
            "N_far": "night, from the far end, looking back"}
    for i, (tag, frame, fact) in enumerate(frames):
        x, yy = 24 + (i % 2) * (fw + gap), y + (i // 2) * (fh + 70)
        rs.paste(page, rs.shrink(frame, fw / frame.shape[1]), x, yy)
        m, c = fact["measures"], fact["cost"]
        text.append((x, yy + fh + 6, 14, f"{said[tag]}: lead {m.get('lead_over_around')}, a Shade's edge {m.get('Shades_edge')}, "
                                         f"frame over the lead's top quarter {round(100 * m.get('brighter_than_lead_p75', 0))}%", ink))
        text.append((x, yy + fh + 26, 12, f"in this frame, within {c['reach_studs']:g} studs: {c['parts']} pieces, {c['triangles']} triangles, "
                                          f"{c['point_lights']} lights", soft))
    y += -(-max(len(frames), 1) // 2) * (fh + 70) + 10
    t, w_ = b["whole_street"], b["worst_within_reach"]
    text.append((24, y, 16, f"The phone budget, from the plan: the whole street is {t['pieces']} pieces, {t['triangles']} triangles, {t['lights']} lights "
                            f"with the lead's.", ink))
    text.append((24, y + 26, 14, f"The most within {b['reach_studs']:g} studs of anyone on the street: {w_['pieces']} pieces, {w_['triangles']} triangles, "
                                 f"{w_['lights']} lights. Round 2's ceiling is 14 lights.", ink))
    text.append((24, y + 50, 12, "Pieces used: " + ", ".join(f"{n} {k}" for n, k in b["counts"].items()), soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "lantern_row_kit_sheet.png")
    print("SHEET", W, H)


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "pictures"
    print("Blender", bpy.app.version_string)
    if mode == "pictures":
        write_pictures(out, look.DIRECTIONS["M"])
    elif mode == "street":
        key = PHASE["key"] = args[1]
        look.street = kit_street(out)
        look.direction(out, key, "fast" in args, far="far" in args, hit="hit" in args)
        tag = key + ("_far" if "far" in args else "") + ("_hit" if "hit" in args else "")
        for name in (f"{tag}_frame.png", f"{tag}.json", f"{tag}_fighters.png"):
            (out / name).replace(out / f"kit_{name}")
    elif mode == "pieces":
        pieces(out)
    elif mode == "sheet":
        sheet(out)
    elif mode == "export":
        export(out)
        plan_picture(out)
    elif mode == "plan":  # plan.json alone, its triangle counts from the handoff's manifest: no mesh or map rewritten
        pieces_now = json.loads((out / "manifest.json").read_text(encoding="utf-8"))["pieces"]
        write_plan(out, {name: dict(triangles=p["triangles"]) for name, p in pieces_now.items()})
    elif mode == "sky":
        for key in args[1:]:
            skies(out, key)
        sky_sheet(out, args[1:])
        (out / "lighting.json").write_text(json.dumps({PHASES[key]: lighting(key) for key in args[1:]}, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
