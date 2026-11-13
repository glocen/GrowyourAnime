"""The effects kit (AR8, "The method"; docs/asset-requests.md): the meshes and textures every effect is built from in
the engine, played as rows by Faber's player. Made once; each effect after it is rows, plus any texture it lacks.

blender.exe -b --factory-startup --python tools/blender/fx_kit.py -- <out_dir>

Meshes, at a unit size in studs (a MeshPart's Size scales them freely), one UV set in 0 to 1 each, both sides built
where a far side shows its inside (the body stands inside hoops and shells; a coil's far side faces in):
- FxCoil3 and FxCoil2: strands wound up a funnel, wide at the foot, drawn in toward the top and to a flame's point.
  They lie on the funnel, upright bands, so from the side they never go edge-on. U across a strand, V along it
  (0 the foot). Each also comes cut along V into BANDS pieces, _Burn1 (the foot) to _Burn6 (the tips): fade them
  foot first and the burn climbs (AR8's order, B1: "burning off from its foot as its transparency moves up").
  FxCoil2 also has _Front1 to _Front5 (B1's finish, fix 3): the burning front where _Burn<b> meets _Burn<b+1>, a
  bright line across each strand and a ragged row of upright tongues off it, on fx_rise_<P>; shown while _Burn<b> burns.
- FxShell: a sphere. U round, V pole to pole (0 the bottom).
- FxHoop: a flat ring with an upright band round its rim (the handbook's depth rule: a flat ring vanishes edge-on).
  U round; V 0 to .5 the ring, inner to outer, .5 to 1 the band, floor to lip: one gradient out and up.
- FxCrescent: a tapered arc, its outer edge lifted (a shallow cup, never flat edge-on). U across (0 the inner
  edge), V along (0 the tail, 1 the head; the widest point past the middle, toward the head).
- FxColumn: an open cylinder. U round, V up.
- FxChip1 to 3: faceted shards, closed, planar UVs.
- FxBar: one stroke of a frame (Rook's square, AR8 B5): a box, its front edges chamfered all round, on fx_across: the
  chamfers and walls on its crisp rim, the front deep to the core and back. A square is four of them, its plate in it.
- FxPlate: the pane a frame holds, a thin box on fx_rise: the core at its foot, deeper up.

Textures:
- For MeshPart.TextureID, opaque, in each palette (Grey for the block-ins, Flame for Pip, Warm for the Lamplighter,
  Ember for Rook): fx_across_<P> (a strand's bright core down its middle, its saturated edge a crisp rim; deeper at
  the foot, hotter at the tip), fx_rise_<P> (the core at V 0 to the deep colour at V 1), fx_ribs_<P> (lit paper
  between six dark ribs: a lantern's look on a shell or a column). Drawn in their own colours, so nothing rests on
  whether a MeshPart's Color tints its texture; opaque, so nothing rests on what a MeshPart does with a texture's
  alpha. The silhouettes are the geometry's, and a fade is the part's Transparency. fx_fire_<P> (B1's bands on fire:
  a dark saturated rim, the body, gold licks and a white core) is drawn for the engine's self-lit look at Glow
  FIRE_GLOW, not in flat colours: through `engine` it comes out in FIRE's colours, so tune its row's Glow, never it.
- White with alpha, tinted in the game (Beams, Trails and particles multiply by Color): fx_beam (across a beam: a
  bright core, a lower edge, clear outside; tiles along), fx_tongues (a flame's tongues licking off the left edge,
  tiles along: on a Trail they rise off Attachment0's side), fx_streak (a needle moving left, for VelocityParallel),
  fx_spark (a four-point glint), fx_ember (2 x 2 blobs: Loop, FlipbookStartRandom, FlipbookFramerate 0), fx_glow (a
  soft round light), fx_flame (a 2 x 2 OneShot flame: three tongues licking up from an open foot, one size every
  frame, frame 1 whole on its own). Colour bled into the clear texels.

Writes meshes/*.json (blcommon.export_mesh_json), images/*.png, fx_kit.json (the recipe), fx_kit_sheet.png (each
mesh in grey and in colour, unlit and lit, on a dark and a bright floor; the burn), fx_kit_64.png (grey and colour
at 64 px) and fx_kit_textures.png. Workbench, so no GPU turn.
"""
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402

PALETTES = {  # core, mid, deep, edge (sRGB)
    "Grey": ("#F2F2F2", "#C4C4C4", "#8E8E8E", "#55575C"),   # the block-ins
    "Flame": ("#FFF4DC", "#FFC65A", "#FF8A3D", "#A85A1A"),  # Pip: Lantern Burst's ladder and the coil's amber rim
    "Warm": ("#FFF3DC", "#FFEBC2", "#FFC98A", "#A8682E"),   # the Lamplighter: its light's core, Lantern Row's warm
    "Ember": ("#FFF1CC", "#FFCF73", "#FFA630", "#7A3E0E"),  # Rook: Haymaker's core and Ember
}
LADDER = (0.0, 0.3, 0.65, 1.0)  # where edge, deep, mid and core sit on a ramp's 0 to 1
DARK, BRIGHT, TINT = "#1E2230", "#D8D2C4", "#FFC65A"  # the review's floors; the white textures' tint there

# The coil: the foot's radius, the top's, its height, a strand's width at the foot (K's 2.7 studs round 4.75, AR8
# B1), how much it narrows up the column, the share of its length its head tapers over, samples along, burn bands
C_FOOT, C_TOP, C_HEIGHT, C_WIDTH, C_NARROW, C_HEAD, C_SAMPLES, BANDS = 1.0, 0.45, 2.2, 0.6, 0.37, 0.35, 48, 6
COILS = {"FxCoil3": (3, 0.7), "FxCoil2": (2, 1.0)}  # strands, turns each
RIM = 0.1   # fx_across: the share of a strand's half width its crisp edge takes, each side
RIBS = 6
TILE = 256  # a review tile, px


# --- textures ------------------------------------------------------------------------------------------------

def rgb(hex_):
    return np.array([int(hex_[i:i + 2], 16) / 255 for i in (1, 3, 5)], dtype=np.float32)


def smooth(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)


def grid(w, h):
    """u, v at texel centres, v up: row 0 is the image's bottom row, as Blender stores it and as UV V 0 reads it."""
    u = (np.arange(w, dtype=np.float32) + 0.5) / w
    v = (np.arange(h, dtype=np.float32) + 0.5) / h
    return np.meshgrid(u, v)


def ladder(t, palette):
    core, mid, deep, edge = (rgb(c) for c in PALETTES[palette])
    stops, colours = np.array(LADDER, dtype=np.float32), np.stack([edge, deep, mid, core])
    t = np.clip(t, 0.0, 1.0)
    out = np.empty(t.shape + (4,), dtype=np.float32)
    for c in range(3):
        out[..., c] = np.interp(t, stops, colours[:, c])
    out[..., 3] = 1.0
    return out


def white(value, cover):
    out = np.empty(value.shape + (4,), dtype=np.float32)
    out[..., :3] = np.clip(value, 0.0, 1.0)[..., None]
    out[..., 3] = np.clip(cover, 0.0, 1.0)
    return out


def across(palette, w=128, h=256):
    u, v = grid(w, h)
    side = 1 - np.abs(2 * u - 1)  # 0 at a strand's edges, 1 down its middle
    body = (0.3 + 0.7 * smooth((side - RIM) / 0.75)) * (0.74 + 0.26 * smooth(v / 0.6)) + 0.12 * smooth((v - 0.8) / 0.2)
    return ladder(np.where(side < RIM, 0.0, body), palette)


def rise(palette, w=64, h=256):
    u, v = grid(w, h)
    return ladder(1 - 0.88 * v ** 1.15, palette)


def ribs(palette, w=64, h=256):
    u, v = grid(w, h)
    d = np.abs((v * RIBS) % 1.0 - 0.5) / RIBS          # V to the nearest rib (at (k + .5) / RIBS)
    paper = 0.55 + 0.35 * smooth(d * RIBS * 2) - 0.15 * v  # each panel brightest at its middle, a little deeper up
    rib = 1 - smooth((d - 0.006) / 0.004)                # about 4 px across
    return ladder(paper * (1 - rib) + 0.06 * rib, palette)


# Fire (AR8 B1, research's fix 3: the bands read as gold silk, not fire). Drawn for the engine, not flat: a kit look is
# a SurfaceAppearance whose emissive mask is its own colour map, and Roblox draws (mask x EmissiveStrength + light) x
# colour map (AR2, section 4), the texel squared times the Glow, so a flat ramp at Glow 2 to 4 blows its middle out to
# one pale gold and its thin rim to red. Each step here is the texel that comes out as its colour (drawn_for).
FIRE = {"Flame": ("#FFF6E2", "#FFC650", "#FF8A3D", "#B5500F")}  # core, gold, body, rim, as they come out in the game
FIRE_GLOW, FIRE_LIGHT = 2.0, 0.3   # the Glow it's drawn for (a whole band's), and the light on it (a dusk street's)
FIRE_STEPS = (0.24, 0.6, 0.88)     # across a strand (0 its edges, 1 its middle): rim to body, body to gold, gold to the
# core; between the licks a thin white core down the middle, at a lick gold and white swell out toward the rim
FIRE_REACH = (0.03, 0.3, 0.36)     # how far a lick at its fullest brings each step out toward the rim
FIRE_LICKS = 6                     # licks along a strand, each a tongue: a round foot, its point toward the tips


def aces(x):
    return np.clip(x * (2.51 * x + 0.03) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0)


def to_linear(c):
    c = np.asarray(c, dtype=np.float32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(np.asarray(c, dtype=np.float32), 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def engine(texture, glow, light):
    """A kit mesh's texture as the game draws it: (mask x Glow + light) x colour map, the mask the colour map, through a
    filmic curve. sRGB in and out. A model, without bloom: the take is the judge."""
    t = to_linear(texture[..., :3])
    return to_srgb(aces(t * t * glow + light * t))


def drawn_for(colour, glow=FIRE_GLOW, light=FIRE_LIGHT):
    """The texel (sRGB) that comes out as `colour`: the curve undone, then glow T^2 + light T = x solved for T."""
    xs = np.linspace(0.0, 16.0, 64001, dtype=np.float32)
    x = np.interp(np.minimum(to_linear(rgb(colour)), 0.985), aces(xs), xs)
    t = (-light + np.sqrt(light * light + 4 * glow * x)) / (2 * glow)
    return to_srgb(np.minimum(t, 1.0))


def fire(palette="Flame", w=128, h=512):
    """A strand on fire (fx_fire_<P>): hard steps across it from a dark saturated rim through the orange body and gold
    to a thin white core down its middle (rule 3); at each lick the gold and the white swell out toward the rim, a
    tongue with a round foot pointing to the tips, a little hotter toward them. Drawn for the engine (`drawn_for`), so
    the file looks paler and pinker than it plays."""
    u, v = grid(w, h)
    side = 1 - np.abs(2 * u - 1)
    right = (u > 0.5).astype(np.float32)
    along = v * FIRE_LICKS + 0.5 * right + 0.1 * np.sin(19.0 * v + 2.0 * right)
    n, phase = np.floor(along), along % 1.0
    size = 0.8 + 0.2 * np.sin(n * 2.4 + 1.3 * right)  # each lick its own size
    lick = size * (1 - phase) ** 1.3 * smooth(phase / 0.2)  # a tongue: a round foot, its point up the strand (+V)
    hot = 0.06 * smooth((v - 0.4) / 0.6)
    cuts = [step - reach * lick - (hot if i else 0.0) for i, (step, reach) in enumerate(zip(FIRE_STEPS, FIRE_REACH))]
    colours = [drawn_for(c) for c in FIRE[palette][::-1]]  # rim, body, gold, core
    out = np.empty(u.shape + (4,), dtype=np.float32)
    out[..., :3] = colours[0]
    for cut, colour in zip(cuts, colours[1:]):
        k = smooth((side - cut) * w / 2 + 0.5)[..., None]  # a step a texel wide
        out[..., :3] = out[..., :3] * (1 - k) + colour * k
    out[..., 3] = 1.0
    return out


def beam(w=64, h=256):
    u, v = grid(w, h)
    side = 1 - np.abs(2 * u - 1)
    return white(0.62 + 0.38 * smooth((side - 0.35) / 0.55), smooth(side / 0.55) ** 1.3)


TONGUES = ((0.04, 0.92, 0.075, 0.05), (0.21, 0.62, 0.06, -0.04), (0.36, 0.85, 0.07, 0.03), (0.55, 0.55, 0.055, -0.03),
           (0.70, 0.95, 0.08, 0.04), (0.86, 0.68, 0.06, -0.05))  # where along (V), reach across (U), half width, lean


def tongues(w=128, h=256):
    u, v = grid(w, h)
    cover = smooth((0.16 - u) / 0.05)  # the base, along the left edge
    for at, reach, half, lean in TONGUES:
        x = u / reach                                   # 0 at the base, 1 at the tip
        dv = (v - (at + lean * x ** 2) + 0.5) % 1.0 - 0.5  # wrapped: the strip tiles along
        edge_px = (half * np.clip(1 - x, 0, 1) ** 0.75 - np.abs(dv)) * h
        cover = np.maximum(cover, smooth(edge_px / 2.0 + 0.5) * (x < 1))
    return white(1.0 - 0.3 * smooth(u / 0.9), cover)


def streak(n=128):
    x, y = grid(n, n)
    head, tail, r = 0.1, 0.94, 0.05
    s = np.clip((x - head) / (tail - head), 0, 1)       # 0 at the head (left), 1 at the tail
    d = np.abs(y - 0.5)
    edge = np.minimum(np.where(x >= head, r * (1 - s) ** 0.8 - d, r - np.hypot(x - head, d)), tail - x)  # no thread past the tail
    return white(1.0 - 0.25 * s, smooth(edge * n / 1.5 + 0.5))


def spark(n=128):
    x, y = grid(n, n)
    dx, dy = np.abs(x - 0.5), np.abs(y - 0.5)

    def arm(along, off, length, strength):
        k = np.clip(1 - along / length, 0, 1)
        return np.exp(-(off / (0.022 * k + 1e-4)) ** 2) * k ** 1.5 * strength

    p, q = (dx + dy) / math.sqrt(2), np.abs(dx - dy) / math.sqrt(2)
    cover = np.maximum.reduce([np.exp(-(np.hypot(dx, dy) / 0.07) ** 2), arm(dx, dy, 0.46, 1.0), arm(dy, dx, 0.46, 1.0),
                               arm(p, q, 0.22, 0.6)])
    return white(np.ones_like(x), cover)


def flipbook(cells, size):
    """Cells in Roblox's order (left to right, top row first) into a 2 x 2 sheet, bottom row first as Blender stores it."""
    out = np.zeros((2 * size, 2 * size, 4), dtype=np.float32)
    for k, cell in enumerate(cells):
        row = (1 - k // 2) * size
        out[row:row + size, (k % 2) * size:(k % 2 + 1) * size] = cell
    out[..., :3] = np.where(out[..., 3:] > 0, out[..., :3], 0.75)  # bleed: the clear padding keeps a light value
    return out


def ember(n=128):
    cell, cells = n // 2, []
    for k, (p1, p2) in enumerate(((0.3, 1.9), (2.2, 0.7), (4.1, 3.3), (5.4, 2.6))):
        x, y = grid(cell, cell)
        dx, dy = x - 0.5, y - 0.5
        a, r = np.arctan2(dy, dx), np.hypot(dx, dy)
        rim = (0.22 + 0.03 * (k % 2)) * (1 + 0.16 * np.sin(3 * a + p1) + 0.1 * np.sin(5 * a + p2))  # under .33: 10 px padding
        cells.append(white(0.7 + 0.3 * smooth(1 - r / rim), smooth((rim - r) * cell / 1.5 + 0.5)))
    return flipbook(cells, cell)


def glow(n=128):
    x, y = grid(n, n)
    return white(np.ones_like(x), np.exp(-(np.hypot(x - 0.5, y - 0.5) / 0.2) ** 2))


FLAMES = (  # each frame: its three tongues (where along the foot, half width there, tip's height, tip's lean), the
    # sides' wave phase. One size every frame (the content check: frames that shrink read as a drip); the lick moves
    # by which tongue is tallest and which way it leans.
    (((0.5, 0.17, 0.88, 0.04), (0.38, 0.1, 0.66, -0.08), (0.62, 0.1, 0.72, 0.07)), 0.0),
    (((0.5, 0.17, 0.84, -0.05), (0.37, 0.1, 0.74, -0.06), (0.63, 0.09, 0.62, 0.09)), 1.6),
    (((0.51, 0.16, 0.9, 0.06), (0.39, 0.09, 0.6, -0.1), (0.61, 0.1, 0.78, 0.05)), 3.1),
    (((0.49, 0.16, 0.86, -0.04), (0.38, 0.1, 0.7, -0.07), (0.62, 0.09, 0.68, 0.08)), 4.7))
FLAME_FOOT = 0.1  # where the tongues stand; under it the flame fades out, open, never a round foot (the content check)


def flame(n=256):
    """Each frame three tongues licking up from one body, wavy sides, a forked top: the middle one tallest, the
    outer two shorter and leaning out. The foot is open, fading out under FLAME_FOOT."""
    cell, cells = n // 2, []
    for licks, phase in FLAMES:
        x, y = grid(cell, cell)
        edge_px = np.full_like(x, -1e3)
        for at, half, tip, lean in licks:
            s = np.clip((y - FLAME_FOOT) / (tip - FLAME_FOOT), 0, 1)
            wave = 1 + 0.12 * np.sin(2 * math.pi * 3 * y + phase + 7 * at)
            side = (half * wave * (1 - s) ** 1.1 - np.abs(x - (at + lean * s ** 2))) * cell
            edge_px = np.maximum(edge_px, np.minimum(side, (tip - y) * cell))  # clear past each tip
        edge_px = np.minimum(edge_px, (y - 0.04) * cell)                       # the padding under it stays clear
        cover = smooth(edge_px / 1.5 + 0.5) * smooth((y - 0.06) / 0.25)        # the open foot
        cells.append(white(0.72 + 0.28 * smooth(edge_px / (0.08 * cell)) * (1 - 0.4 * smooth((y - 0.5) / 0.4)), cover))
    return flipbook(cells, cell)


def flame_review(pixels, out):
    """fx_flame for the content check: on a checker, then tinted over the dark floor at full size, then each frame
    at 64 px (the sheet halved) over the same floor."""
    p = pixels["fx_flame"]
    yy, xx = np.mgrid[0:256, 0:256]
    back = np.where(((yy // 16 + xx // 16) % 2)[..., None] == 0, 0.34, 0.46).astype(np.float32)
    checker = np.concatenate([p[..., :3] * p[..., 3:] + back * (1 - p[..., 3:]), np.ones((256, 256, 1), np.float32)], axis=2)
    lit = np.concatenate([np.clip(rgb(DARK) + p[..., :3] * rgb(TINT) * p[..., 3:], 0, 1), np.ones((256, 256, 1), np.float32)], axis=2)
    small = np.zeros((256, 128, 4), dtype=np.float32)
    small[..., :3], small[..., 3] = rgb(DARK), 1.0
    small[128:] = shrink(lit, 2)
    gap = np.zeros((256, 8, 4), dtype=np.float32)
    gap[..., 3] = 1.0
    write("fx_flame_review", np.concatenate([checker, gap, lit, gap, small], axis=1), out)


def textures():
    """Every texture: name -> (pixels, recipe entry)."""
    out = {}
    for p in PALETTES:
        out[f"fx_across_{p}"] = (across(p), {"for": "MeshPart.TextureID: a coil's strands, the crescent", "alpha": "opaque"})
        out[f"fx_rise_{p}"] = (rise(p), {"for": "MeshPart.TextureID: the column, the hoop, a shell, chips", "alpha": "opaque"})
        out[f"fx_ribs_{p}"] = (ribs(p), {"for": "MeshPart.TextureID: a lantern's ribs on a shell or a column", "alpha": "opaque"})
    for p in FIRE:
        out[f"fx_fire_{p}"] = (fire(p), {"for": "MeshPart.TextureID: a coil's strands on fire (B1's bands)", "alpha": "opaque",
                                         "drawn": f"for the engine at Glow {FIRE_GLOW:g}: each step the texel that comes "
                                                  "out as its colour, (mask x Glow + light) x colour map; the file "
                                                  "looks paler and pinker than it plays",
                                         "colours": dict(zip(("core", "gold", "body", "rim"), FIRE[p]))})
    out["fx_beam"] = (beam(), {"for": "Beam or Trail: across it a bright core and a lower edge, clear outside; tiles along",
                               "set": "TextureMode Wrap or Stretch; TextureSpeed 0 unless it flows"})
    out["fx_tongues"] = (tongues(), {"for": "Beam or Trail: a flame's tongues off Attachment0's side (the image's left), tiles along",
                                     "set": "TextureSpeed for the lick to travel"})
    out["fx_streak"] = (streak(), {"for": "ParticleEmitter: a needle, moving left", "set": "Orientation VelocityParallel; Squash negative stretches it"})
    out["fx_spark"] = (spark(), {"for": "ParticleEmitter: a four-point glint"})
    out["fx_ember"] = (ember(), {"for": "ParticleEmitter: embers, one blob each", "layout": "Grid4",
                                 "set": "FlipbookMode Loop, FlipbookStartRandom on, FlipbookFramerate 0",
                                 "never": "tinted red or maroon, or shed from a struck body falling under gravity (the content check)"})
    out["fx_glow"] = (glow(), {"for": "ParticleEmitter or a card: a soft round light"})
    out["fx_flame"] = (flame(), {"for": "ParticleEmitter: a small flame, three tongues licking up from an open foot", "layout": "Grid4",
                                 "set": "FlipbookMode OneShot; Lifetime .3 to .5 s; frame 1 reads alone",
                                 "never": "tinted red or dark (the content check)"})
    for name, (pixels, entry) in out.items():
        entry.setdefault("alpha", "white, tinted by Color in the game")
    return out


def save(name, pixels, folder):
    h, w = pixels.shape[:2]
    image = bpy.data.images.new(name, w, h, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(pixels, dtype=np.float32).ravel())
    image.filepath_raw, image.file_format = str(folder / f"{name}.png"), "PNG"
    image.save()
    return image


# --- meshes --------------------------------------------------------------------------------------------------

def new_bm():
    bm = bmesh.new()
    return bm, bm.loops.layers.uv.new("UVMap")


def surface(bm, uv, points, us, vs, closed=False, smooth_=True):
    """A quad grid, points[i][j]: rows i along V, columns j along U. `us` holds a U per column, one more when closed
    (the seam's U of 1), `vs` a V per row."""
    verts = [[bm.verts.new(p) for p in row] for row in points]
    cols = len(points[0])
    for i in range(len(points) - 1):
        for j in range(cols if closed else cols - 1):
            k = (j + 1) % cols
            quad = ((i, j, j), (i, k, j + 1), (i + 1, k, j + 1), (i + 1, j, j))
            face = bm.faces.new([verts[a][b] for a, b, _ in quad])
            corners = {verts[a][b]: (us[c], vs[a]) for a, b, c in quad}
            for loop in face.loops:
                loop[uv].uv = corners[loop.vert]
            face.smooth = smooth_
    return verts


def both_sides(bm):
    """Every face again, facing the other way, on vertices of its own: shading and UVs stay apart."""
    made = bmesh.ops.duplicate(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces))
    bmesh.ops.reverse_faces(bm, faces=[g for g in made["geom"] if isinstance(g, bmesh.types.BMFace)])


def coil_point(s, base, turns):
    radius = C_TOP + (C_FOOT - C_TOP) * (1 - s) ** 1.6
    angle = base + 2 * math.pi * turns * s
    return Vector((radius * math.cos(angle), radius * math.sin(angle), C_HEIGHT * s)), angle


def coil(strands, turns, lo=0.0, hi=1.0):
    """The strands from s = lo to hi (0 the foot, 1 the tips), on the same samples whatever the cut, so the bands
    meet the whole coil exactly. Three points across each, the middle bulged out a little for a rounded strand."""
    bm, uv = new_bm()
    steps = round((hi - lo) * C_SAMPLES)
    ss = [lo + (hi - lo) * i / steps for i in range(steps + 1)]
    for k in range(strands):
        base, rows = 2 * math.pi * k / strands, []
        for s in ss:
            p, angle = coil_point(s, base, turns)
            tangent = coil_point(min(s + 1e-3, 1.0), base, turns)[0] - coil_point(max(s - 1e-3, 0.0), base, turns)[0]
            out = Vector((math.cos(angle), math.sin(angle), 0.0))
            side = tangent.cross(out).normalized()  # U's way: the face's normal, side x along, points out
            width = max(C_WIDTH * (1 - C_NARROW * s) * min(1.0, (1 - s) / C_HEAD) ** 0.85, 0.004)
            rows.append([p + side * width * (u - 0.5) + out * 0.12 * width * (1 - (2 * u - 1) ** 2) for u in (0.0, 0.5, 1.0)])
        surface(bm, uv, rows, (0.0, 0.5, 1.0), ss)
    both_sides(bm)
    return bm


FRONT_TONGUES, FRONT_LIFT = 4, 0.015  # tongues across a strand; how far off its faces a front lies (unit coil)


def strand_at(base, turns, s):
    """A strand's frame at s: its centre, its across way (U), its outward normal, its width and how long it runs a
    unit of s, as coil() lays it."""
    p, angle = coil_point(s, base, turns)
    tangent = coil_point(min(s + 1e-3, 1.0), base, turns)[0] - coil_point(max(s - 1e-3, 0.0), base, turns)[0]
    out = Vector((math.cos(angle), math.sin(angle), 0.0))
    side = tangent.cross(out).normalized()
    normal = side.cross(tangent).normalized()
    normal = normal if normal.dot(out) > 0 else -normal
    width = max(C_WIDTH * (1 - C_NARROW * s) * min(1.0, (1 - s) / C_HEAD) ** 0.85, 0.004)
    run = tangent.length / (min(s + 1e-3, 1.0) - max(s - 1e-3, 0.0))
    return p, side, out, normal, width, run


def front(strands, turns, s, seed):
    """The burning front where band b meets b + 1 (s = b / BANDS): on each strand, a bright line across the cut, and a
    ragged row of tongues standing up off it, upright, each on the funnel's tangent there (its face out from the axis),
    so they rise past the strand's own edge into the air like a flame eating up it. Both sides built. On fx_rise: V 0,
    the core, along the line and at each tongue's foot; the tips 0.75. A tongue's height is in unit coil: the game
    stretches the coil about 1.7 times taller than wide, and the tongues with it."""
    rng = random.Random(seed)
    bm, uv = new_bm()
    up = Vector((0.0, 0.0, 1.0))

    def point(base, u, ss):
        p, side, out, normal, width, _ = strand_at(base, turns, ss)
        return p + side * width * (u - 0.5) + out * 0.12 * width * (1 - (2 * u - 1) ** 2) + normal * FRONT_LIFT

    def face(verts, uvs):
        f = bm.faces.new(verts)
        for loop, (a, b) in zip(f.loops, uvs):
            loop[uv].uv = (a, b)
        f.smooth = False
        f.normal_update()
        centre = f.calc_center_median()
        if f.normal.dot(Vector((centre.x, centre.y, 0.0))) < 0:
            f.normal_flip()

    for k in range(strands):
        base = 2 * math.pi * k / strands
        _, _, _, _, width, run = strand_at(base, turns, s)
        line = 0.07 * width / run  # the line's half width, in s
        us = [j / 8 for j in range(9)]
        lo = [bm.verts.new(point(base, u, s - line)) for u in us]
        hi = [bm.verts.new(point(base, u, s + line)) for u in us]
        for j in range(8):
            face([lo[j], lo[j + 1], hi[j + 1], hi[j]], [(us[j], 0.0), (us[j + 1], 0.0), (us[j + 1], 0.04), (us[j], 0.04)])
        for i in range(FRONT_TONGUES):
            root = point(base, min(0.95, max(0.05, (i + 0.5) / FRONT_TONGUES + rng.uniform(-0.05, 0.05))), s)
            radial = Vector((root.x, root.y, 0.0)).normalized()
            circ = up.cross(radial)
            half = width * 0.5 / FRONT_TONGUES * rng.uniform(1.1, 1.5)
            tall, lean = width * rng.uniform(0.3, 0.7), width * rng.uniform(-0.12, 0.12)
            steps, rows = 5, []
            for n in range(steps + 1):
                a = n / steps
                centre = root + up * tall * a + circ * lean * a * a + radial * 0.4 * FRONT_LIFT * a
                h = half * (1 - a) ** 0.75 * (1 + 0.35 * math.sin(math.pi * a))
                rows.append([bm.verts.new(centre)] if n == steps else [bm.verts.new(centre + circ * d * h) for d in (-1, 1)])
            for n in range(steps):
                a0, a1 = 0.75 * n / steps, 0.75 * (n + 1) / steps
                left, right = rows[n]
                if len(rows[n + 1]) == 1:
                    face([left, right, rows[n + 1][0]], [(0.0, a0), (1.0, a0), (0.5, a1)])
                else:
                    face([left, right, rows[n + 1][1], rows[n + 1][0]], [(0.0, a0), (1.0, a0), (1.0, a1), (0.0, a1)])
    both_sides(bm)
    return bm


def shell(rings=12, segs=24):
    bm, uv = new_bm()
    lats = [-math.pi / 2 + math.pi * i / rings for i in range(1, rings)]
    thetas = [2 * math.pi * j / segs for j in range(segs)]
    rows = surface(bm, uv, [[Vector((math.cos(a) * math.cos(t), math.cos(a) * math.sin(t), math.sin(a))) for t in thetas]
                            for a in lats], [j / segs for j in range(segs + 1)], [i / rings for i in range(1, rings)], closed=True)
    for row, z, v, near in ((rows[0], -1.0, 0.0, 1 / rings), (rows[-1], 1.0, 1.0, 1 - 1 / rings)):
        pole = bm.verts.new((0.0, 0.0, z))
        for j in range(segs):
            face = bm.faces.new((pole, row[j], row[(j + 1) % segs]))
            corners = {pole: ((j + 0.5) / segs, v), row[j]: (j / segs, near), row[(j + 1) % segs]: ((j + 1) / segs, near)}
            for loop in face.loops:
                loop[uv].uv = corners[loop.vert]
            face.smooth = True
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    both_sides(bm)
    return bm


def hoop(inner=0.7, band=0.3, segs=48):
    """The ring on the floor and the band round its rim, apart at the rim so the crease stays sharp; V runs on
    across the crease."""
    bm, uv = new_bm()
    thetas = [2 * math.pi * j / segs for j in range(segs)]
    us = [j / segs for j in range(segs + 1)]
    radii = [inner + (1 - inner) * i / 3 for i in range(4)]
    surface(bm, uv, [[Vector((r * math.cos(t), r * math.sin(t), 0.0)) for t in thetas] for r in radii], us,
            [0.5 * i / 3 for i in range(4)], closed=True)
    surface(bm, uv, [[Vector((math.cos(t), math.sin(t), band * i / 3)) for t in thetas] for i in range(4)], us,
            [0.5 + 0.5 * i / 3 for i in range(4)], closed=True)
    both_sides(bm)
    return bm


CRESCENT_SEGS = 40


def crescent(span=160.0, segs=CRESCENT_SEGS, width=0.38, cup=0.45):
    """Centred on +X, swept counterclockwise seen from above, tail to head; the inner edge on the floor's level at
    its widest, the outer lifted `cup` studs per stud out."""
    bm, uv = new_bm()
    rows, vs, low = [], [], 1 - width
    for i in range(segs + 1):
        t = i / segs
        a = math.radians(-span / 2 + span * t)
        w = max(width * math.sin(math.pi * t ** 1.4) ** 0.75, 0.004)
        row = []
        for c in range(4):
            r = 1 - w * (1 - c / 3)
            row.append(Vector((r * math.cos(a), r * math.sin(a), cup * (r - low))))
        rows.append(row)
        vs.append(t)
    surface(bm, uv, rows, [c / 3 for c in range(4)], vs)
    both_sides(bm)
    return bm


def column(height=2.0, segs=40, rows=5):
    bm, uv = new_bm()
    thetas = [2 * math.pi * j / segs for j in range(segs)]
    surface(bm, uv, [[Vector((math.cos(t), math.sin(t), height * i / rows)) for t in thetas] for i in range(rows + 1)],
            [j / segs for j in range(segs + 1)], [i / rows for i in range(rows + 1)], closed=True)
    both_sides(bm)
    return bm


def chip(seed):
    """A flat crystal chip: an uneven pointed outline, a ridge above and below its middle, flat faces."""
    rng = random.Random(seed)
    outline = [(0.5, rng.uniform(-0.03, 0.03)), (0.12 + rng.uniform(-0.06, 0.06), rng.uniform(0.15, 0.2)),
               (-0.3 + rng.uniform(-0.05, 0.05), rng.uniform(0.1, 0.16)), (-0.5, rng.uniform(-0.04, 0.04)),
               (-0.22 + rng.uniform(-0.05, 0.05), -rng.uniform(0.12, 0.18)), (0.18 + rng.uniform(-0.05, 0.05), -rng.uniform(0.1, 0.15))]
    lo_x, hi_x = min(p[0] for p in outline), max(p[0] for p in outline)
    lo_y, hi_y = min(p[1] for p in outline), max(p[1] for p in outline)
    bm, uv = new_bm()
    ring = [bm.verts.new((x, y, 0.0)) for x, y in outline]
    cx, thick = rng.uniform(-0.12, 0.08), rng.uniform(0.07, 0.1)
    for z in (thick, -thick * 0.8):
        top = bm.verts.new((cx, 0.0, z))
        for j in range(len(ring)):
            face = bm.faces.new((top, ring[j], ring[(j + 1) % len(ring)]))
            for loop in face.loops:
                co = loop.vert.co
                loop[uv].uv = ((co.x - lo_x) / (hi_x - lo_x), (co.y - lo_y) / (hi_y - lo_y))
            face.smooth = False
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    return bm


def bar(across=0.15, deep=0.3, end=0.025, rim=0.06, v=0.7):
    """FxBar: one stroke of a frame, a box with its front edges chamfered all round, flat-faced. X along it, Z across,
    Y its depth, the front at +Y (Roblox's -Z, where a part looks). The chamfers take `across` of its width each side
    and `end` of its length at each end, `deep` of its depth. U: the chamfers and walls on fx_across's crisp rim, the
    front from `rim` to 1 - `rim`, deep to the core and back; V holds in across's flat stretch, the same all along."""
    bm, uv = new_bm()
    a = 0.5 - across

    def ring(x, h, d):  # the corners round, in (along, across): -,- then +,- then +,+ then -,+
        return [bm.verts.new((sx * x, d, sh * h)) for sx, sh in ((-1, -1), (1, -1), (1, 1), (-1, 1))]

    front, foot, back = ring(0.5 - end, a, 0.5), ring(0.5, 0.5, 0.5 - deep), ring(0.5, 0.5, -0.5)
    hold = 0.02  # an end chamfer's U: all rim

    def face(verts, us):
        f = bm.faces.new(verts)
        for loop in f.loops:
            loop[uv].uv = (us[verts.index(loop.vert)], v)
        f.smooth = False

    face(front, (rim, rim, 1 - rim, 1 - rim))
    face([front[0], front[1], foot[1], foot[0]], (rim, rim, 0.0, 0.0))          # the chamfer along its low edge
    face([front[2], front[3], foot[3], foot[2]], (1 - rim, 1 - rim, 1.0, 1.0))  # along its high edge
    face([front[1], front[2], foot[2], foot[1]], (hold,) * 4)                  # the ends
    face([front[3], front[0], foot[0], foot[3]], (hold,) * 4)
    face([foot[0], foot[1], back[1], back[0]], (0.0,) * 4)                     # the walls, the back: the rim
    face([foot[2], foot[3], back[3], back[2]], (1.0,) * 4)
    face([foot[1], foot[2], back[2], back[1]], (0.0,) * 4)
    face([foot[3], foot[0], back[0], back[3]], (0.0,) * 4)
    face(back, (0.0,) * 4)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    return bm


def plate(top=0.75):
    """FxPlate: the pane a frame holds, a thin box. X across, Z up, Y its depth (the front at +Y). V from 0 at its foot
    to `top` at its top edge: on fx_rise, the core where it leads down, deeper up; U across."""
    bm, uv = new_bm()
    bmesh.ops.create_cube(bm, size=1.0)
    for f in bm.faces:
        for loop in f.loops:
            loop[uv].uv = (loop.vert.co.x + 0.5, top * (loop.vert.co.z + 0.5))
        f.smooth = False
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    return bm


def meshes():
    """name -> (bmesh, recipe entry). The coils' bands follow their coil."""
    out = {}
    for name, (strands, turns) in COILS.items():
        out[name] = (coil(strands, turns), {"strands": strands, "turns": turns, "textures": "fx_across_<P>",
                                            "uv": "U across a strand, V along it: 0 the foot, 1 the tips"})
        for b in range(BANDS):
            out[f"{name}_Burn{b + 1}"] = (coil(strands, turns, b / BANDS, (b + 1) / BANDS),
                                          {"of": name, "band": b + 1, "textures": "fx_across_<P>"})
        if name == "FxCoil2":  # B1's coil (fix 3): the burning front at the top of each band but the tips'
            for b in range(1, BANDS):
                out[f"{name}_Front{b}"] = (front(strands, turns, b / BANDS, 40 + b),
                                           {"of": name, "front": b, "textures": "fx_rise_<P>",
                                            "uv": "U across a tongue, V up it: 0 the line along the cut (the core), 0.75 the tips",
                                            "place": f"as the bands: where _Burn{b} meets _Burn{b + 1}; shown while _Burn{b} burns"})
    out["FxShell"] = (shell(), {"textures": "fx_rise_<P> or fx_ribs_<P>", "uv": "U round, V pole to pole: 0 the bottom"})
    out["FxHoop"] = (hoop(), {"textures": "fx_rise_<P>", "uv": "U round; V 0 to .5 the floor ring, inner to outer; .5 to 1 the band, floor to lip"})
    out["FxCrescent"] = (crescent(), {"textures": "fx_across_<P>", "uv": "U across: 0 the inner edge; V along: 0 the tail, 1 the head"})
    out["FxColumn"] = (column(), {"textures": "fx_rise_<P> or fx_ribs_<P>", "uv": "U round, V up"})
    for k in range(3):
        out[f"FxChip{k + 1}"] = (chip(11 + 7 * k), {"textures": "fx_rise_<P>, or none: Neon in a Color", "uv": "planar, across its face"})
    out["FxBar"] = (bar(), {"textures": "fx_across_<P>", "uv": "U across: 0 and 1 its long edges (the chamfers and walls on "
                            "the rim), the front 0.06 to 0.94; V 0.7 all along",
                            "axes": "X along it, Y across, Z its depth; its front faces -Z, the way a part looks",
                            "frame": "a square's four strokes: the posts the full height and turned 90 degrees round Z, "
                                     "the rails between them a little shallower, their ends inside the posts"})
    out["FxPlate"] = (plate(), {"textures": "fx_rise_<P>", "uv": "U across, V up: 0 at its foot (the core) to 0.75 at its top",
                                "axes": "X across, Y up, Z its depth; its front faces -Z"})
    return out


# --- the review ----------------------------------------------------------------------------------------------

def stage():
    scene = bl.reset_scene()
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.display.render_aa = "8"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = scene.render.resolution_y = TILE
    data = bpy.data.cameras.new("Camera")
    data.lens = 50
    camera = bpy.data.objects.new("Camera", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return scene, camera


def textured(obj, image):
    mat = obj.data.materials[0] if obj.data.materials else None
    if mat is None:
        mat = bpy.data.materials.new(f"{obj.name}_Look")
        mat.use_nodes = True
        tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
        mat.node_tree.links.new(tex.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
        mat.node_tree.nodes.active = tex
        obj.data.materials.append(mat)
    mat.node_tree.nodes.active.image = image


def shot(scene, camera, shown, light, tmp, frame=None):
    """The objects in `shown` from the game's raised three-quarter view, framed on the bounding sphere of `frame`
    (the shown ones by default)."""
    for obj in scene.objects:
        if obj.type == "MESH":
            obj.hide_render = obj not in shown
    bpy.context.view_layer.update()
    corners = [o.matrix_world @ Vector(c) for o in (frame or shown) for c in o.bound_box]
    centre = sum(corners, Vector()) / len(corners)
    radius = max((c - centre).length for c in corners)
    az, el = math.radians(35), math.radians(24)
    way = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))
    camera.location = centre + way * radius / math.sin(camera.data.angle / 2) * 0.92
    camera.rotation_euler = (-way).to_track_quat("-Z", "Y").to_euler()
    scene.display.shading.light = light
    scene.render.filepath = str(tmp)
    bpy.ops.render.render(write_still=True)
    image = bpy.data.images.load(str(tmp))
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(TILE, TILE, 4)
    bpy.data.images.remove(image)
    return pixels


def over(tile, floor):
    a = tile[..., 3:]
    out = np.empty_like(tile)
    out[..., :3] = tile[..., :3] * a + rgb(floor) * (1 - a)
    out[..., 3] = 1.0
    out[:, -1], out[-1] = (0.0, 0.0, 0.0, 1.0), (0.0, 0.0, 0.0, 1.0)  # a dark line between tiles
    return out


def shrink(tile, k):
    h, w = tile.shape[:2]
    return tile.reshape(h // k, k, w // k, k, 4).mean(axis=(1, 3))


def write(name, sheet, folder):
    image = bpy.data.images.new(name, sheet.shape[1], sheet.shape[0], alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(sheet, dtype=np.float32).ravel())
    image.filepath_raw, image.file_format = str(folder / f"{name}.png"), "PNG"
    image.save()


CELLS = ("FxCoil3", "FxCoil2", "FxShell", "FxHoop", "FxCrescent", "FxColumn", "Chips", "Square")
LOOK = {"FxCoil3": ("across", "Flame"), "FxCoil2": ("across", "Ember"), "FxShell": ("ribs", "Warm"),
        "FxHoop": ("rise", "Ember"), "FxCrescent": ("across", "Ember"), "FxColumn": ("rise", "Warm"), "Chips": ("rise", "Flame"),
        "Square": ("across", "Ember")}  # the square's plate takes fx_rise
SQUARE = (4.6, 0.85, 0.5)  # the review's square: B5's side and bar (Config.Effects.Haymaker.Stamp), the strokes' depth


def square(objects):
    """FxBar four times as a frame, its plate in it, turned to face the review's camera: posts the full height, rails
    between them 0.9 as deep (their front faces never on the posts'), their ends at the posts' middles."""
    side, width, depth = SQUARE
    parts = []
    for k, (at, turn, size) in enumerate([((s * side / 2, 0, 0), (0, 90, 180), (side + width, depth, width)) for s in (-1, 1)] +
                                         [((0, 0, s * side / 2), (0, 0, 180), (side, 0.9 * depth, width)) for s in (-1, 1)]):
        obj = objects["FxBar"] if k == 0 else bpy.data.objects.new(f"FxBar{k + 1}", objects["FxBar"].data)
        if k:
            bpy.context.scene.collection.objects.link(obj)
        obj.location, obj.rotation_euler, obj.scale = at, tuple(math.radians(a) for a in turn), size
        parts.append(obj)
    pane = objects["FxPlate"]
    pane.rotation_euler, pane.scale = (0, 0, math.pi), (side - width, 0.06, side - width)
    return parts + [pane]


def review(objects, images, out):
    scene, camera = bpy.context.scene, bpy.context.scene.camera
    tmp = out / "_tile.png"
    chips = [objects[f"FxChip{k + 1}"] for k in range(3)]
    for obj, at, turn in zip(chips, ((-0.75, 0.0, 0.0), (0.35, 0.35, 0.15), (0.8, -0.35, -0.1)), ((20, 10, 15), (-35, 25, 80), (60, -15, -40))):
        obj.location, obj.rotation_euler = at, tuple(math.radians(a) for a in turn)
    groups = {name: ([objects[name]] if name not in ("Chips", "Square") else chips) for name in CELLS}
    groups["Square"] = square(objects)

    def row(palette, light, floor, small=False):
        tiles = []
        for name in CELLS:
            kind, colour = LOOK[name]
            for obj in groups[name]:
                textured(obj, images[f"fx_{'rise' if obj.name == 'FxPlate' else kind}_{palette or colour}"])
            tiles.append(over(shot(scene, camera, groups[name], light, tmp), floor))
        strip = np.concatenate(tiles, axis=1)
        return shrink(strip, TILE // 64) if small else strip

    rows = [row("Grey", "FLAT", DARK), row("Grey", "FLAT", BRIGHT), row(None, "FLAT", DARK), row(None, "FLAT", BRIGHT),
            row(None, "STUDIO", DARK)]
    burn = []
    for name, gone in [("FxCoil3", g) for g in range(BANDS)] + [("FxCoil2", BANDS // 2)]:
        bands = [objects[f"{name}_Burn{b + 1}"] for b in range(BANDS)]
        on_fire = name == "FxCoil2"  # B1's: on fire, its front where the burn has reached (the texture as the file is)
        for obj in bands:
            textured(obj, images["fx_fire_Flame" if on_fire else f"fx_across_{LOOK[name][1]}"])
        shown = bands[gone:]
        if on_fire:
            textured(objects[f"{name}_Front{gone}"], images["fx_rise_Flame"])
            shown = shown + [objects[f"{name}_Front{gone}"]]
        burn.append(over(shot(scene, camera, shown, "FLAT", tmp, frame=bands), DARK))  # framed on every band
    while len(burn) < len(CELLS):
        burn.append(over(np.zeros((TILE, TILE, 4), dtype=np.float32), DARK))
    rows.append(np.concatenate(burn, axis=1))
    write("fx_kit_sheet", np.concatenate(rows[::-1], axis=0), out)
    small = [row("Grey", "FLAT", DARK, True), row(None, "FLAT", DARK, True), row(None, "FLAT", BRIGHT, True)]
    write("fx_kit_64", np.concatenate(small[::-1], axis=0), out)
    tmp.unlink()


def texture_sheet(pixels, out):
    """The mesh textures as they are, then the white ones on a checker (their alpha), then tinted over the dark floor
    the way an additive Beam or particle draws them; each 256 px tall, 8 px apart."""
    def tall(p):
        k = 256 // p.shape[0]
        return np.repeat(np.repeat(p, k, axis=0), k, axis=1)

    def strip(items):
        gap = np.zeros((256, 8, 4), dtype=np.float32)
        gap[..., 3] = 1.0
        parts = []
        for p in items:
            parts += [p, gap]
        return np.concatenate(parts, axis=1)

    def checker(p):
        h, w = p.shape[:2]
        yy, xx = np.mgrid[0:h, 0:w]
        back = np.where(((yy // 16 + xx // 16) % 2)[..., None] == 0, 0.34, 0.46).astype(np.float32)
        out_ = p.copy()
        out_[..., :3] = p[..., :3] * p[..., 3:] + back * (1 - p[..., 3:])
        out_[..., 3] = 1.0
        return out_

    def lit(p):
        out_ = p.copy()
        out_[..., :3] = np.clip(rgb(DARK) + p[..., :3] * rgb(TINT) * p[..., 3:], 0, 1)
        out_[..., 3] = 1.0
        return out_

    mesh_side = [tall(pixels[f"fx_{kind}_{p}"]) for kind in ("across", "rise", "ribs") for p in PALETTES]
    mesh_side += [shrink(pixels[f"fx_fire_{p}"], pixels[f"fx_fire_{p}"].shape[0] // 256) for p in FIRE]  # 512 tall
    whites = [tall(pixels[n]) for n in ("fx_beam", "fx_tongues", "fx_streak", "fx_spark", "fx_ember", "fx_glow", "fx_flame")]
    rows = [strip(mesh_side), strip([checker(p) for p in whites]), strip([lit(p) for p in whites])]
    width = max(r.shape[1] for r in rows)
    padded = []
    for r in rows:
        pad = np.zeros((256, width - r.shape[1], 4), dtype=np.float32)
        pad[..., 3] = 1.0
        padded.append(np.concatenate([r, pad], axis=1))
    gap = np.zeros((8, width, 4), dtype=np.float32)
    gap[..., 3] = 1.0
    write("fx_kit_textures", np.concatenate([padded[2], gap, padded[1], gap, padded[0]], axis=0), out)


# --- main ----------------------------------------------------------------------------------------------------

def main():
    sys.stdout.reconfigure(line_buffering=True)
    out = bl.out_dir()
    (out / "meshes").mkdir(exist_ok=True)
    (out / "images").mkdir(exist_ok=True)
    stage()
    recipe = {"name": "FxKit", "made_by": "tools/blender/fx_kit.py",
              "frame": "Roblox studs, Y up. Each mesh is centred on its box; 'size' is that box at the unit size, and "
                       "a MeshPart's Size scales it freely.",
              "use": "MeshPart.TextureID for the meshes (a warm pass preloads it; SurfaceAppearance can't be). The mesh "
                     "textures are opaque and drawn in each palette's own colours: a fade is the part's Transparency, a "
                     "silhouette is the mesh. The white textures are for Beams, Trails and particles, tinted by Color.",
              "burn": f"Each coil also comes as {BANDS} bands along its length, _Burn1 at the foot: place each band at the "
                      "coil's centre plus its 'offset' times the coil's scale (Size over 'size'), and fade them foot first.",
              "palettes": {p: dict(zip(("core", "mid", "deep", "edge"), c)) for p, c in PALETTES.items()},
              "meshes": {}, "textures": {}}
    pixels, images = {}, {}
    for name, (data, entry) in textures().items():
        pixels[name], images[name] = data, save(name, data, out / "images")
        recipe["textures"][name] = {"file": f"images/{name}.png", "pixels": [data.shape[1], data.shape[0]], **entry}
    objects = {}
    for name, (bm, entry) in meshes().items():
        obj = objects[name] = bl.object_from_bmesh(name, bm)
        path = out / "meshes" / f"{name}.json"
        tris = bl.export_mesh_json(obj, path, uv=True)
        record = json.loads(path.read_text())
        p = np.array(record["p"], dtype=np.float64).reshape(-1, 3)
        recipe["meshes"][name] = {"file": f"meshes/{name}.json", "size": [round(float(v), 4) for v in p.max(0) - p.min(0)],
                                  "tris": tris, "centre": record["c"], **entry}
    for name, entry in recipe["meshes"].items():
        if "of" in entry:
            whole = recipe["meshes"][entry["of"]]["centre"]
            entry["offset"] = [round(a - b, 4) for a, b in zip(entry["centre"], whole)]
    verts, centre = objects["FxCrescent"].data.vertices, Vector(recipe["meshes"]["FxCrescent"]["centre"])
    for end, first in (("tail", 0), ("head", 4 * CRESCENT_SEGS)):  # the front side's first and last rows, four across
        at = sum((Vector((v.co.x, v.co.z, -v.co.y)) for v in verts[first:first + 4]), Vector()) / 4 - centre
        recipe["meshes"]["FxCrescent"][end] = [round(v, 3) for v in at]
    for name, entry in recipe["meshes"].items():
        print(f"{name}: {entry['size']} studs, {entry['tris']} tris" + (f", offset {entry['offset']}" if "offset" in entry else ""))
    (out / "fx_kit.json").write_text(json.dumps(recipe, indent=1))
    texture_sheet(pixels, out)
    flame_review(pixels, out)
    review(objects, images, out)
    print(f"Wrote {len(recipe['meshes'])} meshes, {len(recipe['textures'])} textures, the sheets, to {out}")


if __name__ == "__main__":  # fx_rows.py builds the same meshes for its previews
    main()
