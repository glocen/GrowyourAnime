"""The effects kit (AR8, "The method"; docs/asset-requests.md): the meshes and textures every effect is built from in
the engine, played as rows by Faber's player. Made once; each effect after it is rows, plus any texture it lacks.

blender.exe -b --factory-startup --python tools/blender/fx_kit.py -- <out_dir>

Meshes, at a unit size in studs (a MeshPart's Size scales them freely), one UV set in 0 to 1 each, both sides built
where a far side shows its inside (the body stands inside hoops and shells; a coil's far side faces in):
- FxCoil3 and FxCoil2: strands wound up a funnel, wide at the foot, drawn in toward the top and to a flame's point.
  They lie on the funnel, upright bands, so from the side they never go edge-on. U across a strand, V along it
  (0 the foot). Each also comes cut along V into BANDS pieces, _Burn1 (the foot) to _Burn6 (the tips): fade them
  foot first and the burn climbs (AR8's order, B1: "burning off from its foot as its transparency moves up").
- FxShell: a sphere. U round, V pole to pole (0 the bottom).
- FxHoop: a flat ring with an upright band round its rim (the handbook's depth rule: a flat ring vanishes edge-on).
  U round; V 0 to .5 the ring, inner to outer, .5 to 1 the band, floor to lip: one gradient out and up.
- FxCrescent: a tapered arc, its outer edge lifted (a shallow cup, never flat edge-on). U across (0 the inner
  edge), V along (0 the tail, 1 the head; the widest point past the middle, toward the head).
- FxColumn: an open cylinder. U round, V up.
- FxChip1 to 3: faceted shards, closed, planar UVs.

Textures:
- For MeshPart.TextureID, opaque, in each palette (Grey for the block-ins, Flame for Pip, Warm for the Lamplighter,
  Ember for Rook): fx_across_<P> (a strand's bright core down its middle, its saturated edge a crisp rim; deeper at
  the foot, hotter at the tip), fx_rise_<P> (the core at V 0 to the deep colour at V 1), fx_ribs_<P> (lit paper
  between six dark ribs: a lantern's look on a shell or a column). Drawn in their own colours, so nothing rests on
  whether a MeshPart's Color tints its texture; opaque, so nothing rests on what a MeshPart does with a texture's
  alpha. The silhouettes are the geometry's, and a fade is the part's Transparency.
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


def meshes():
    """name -> (bmesh, recipe entry). The coils' bands follow their coil."""
    out = {}
    for name, (strands, turns) in COILS.items():
        out[name] = (coil(strands, turns), {"strands": strands, "turns": turns, "textures": "fx_across_<P>",
                                            "uv": "U across a strand, V along it: 0 the foot, 1 the tips"})
        for b in range(BANDS):
            out[f"{name}_Burn{b + 1}"] = (coil(strands, turns, b / BANDS, (b + 1) / BANDS),
                                          {"of": name, "band": b + 1, "textures": "fx_across_<P>"})
    out["FxShell"] = (shell(), {"textures": "fx_rise_<P> or fx_ribs_<P>", "uv": "U round, V pole to pole: 0 the bottom"})
    out["FxHoop"] = (hoop(), {"textures": "fx_rise_<P>", "uv": "U round; V 0 to .5 the floor ring, inner to outer; .5 to 1 the band, floor to lip"})
    out["FxCrescent"] = (crescent(), {"textures": "fx_across_<P>", "uv": "U across: 0 the inner edge; V along: 0 the tail, 1 the head"})
    out["FxColumn"] = (column(), {"textures": "fx_rise_<P> or fx_ribs_<P>", "uv": "U round, V up"})
    for k in range(3):
        out[f"FxChip{k + 1}"] = (chip(11 + 7 * k), {"textures": "fx_rise_<P>, or none: Neon in a Color", "uv": "planar, across its face"})
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


CELLS = ("FxCoil3", "FxCoil2", "FxShell", "FxHoop", "FxCrescent", "FxColumn", "Chips")
LOOK = {"FxCoil3": ("across", "Flame"), "FxCoil2": ("across", "Ember"), "FxShell": ("ribs", "Warm"),
        "FxHoop": ("rise", "Ember"), "FxCrescent": ("across", "Ember"), "FxColumn": ("rise", "Warm"), "Chips": ("rise", "Flame")}


def review(objects, images, out):
    scene, camera = bpy.context.scene, bpy.context.scene.camera
    tmp = out / "_tile.png"
    chips = [objects[f"FxChip{k + 1}"] for k in range(3)]
    for obj, at, turn in zip(chips, ((-0.75, 0.0, 0.0), (0.35, 0.35, 0.15), (0.8, -0.35, -0.1)), ((20, 10, 15), (-35, 25, 80), (60, -15, -40))):
        obj.location, obj.rotation_euler = at, tuple(math.radians(a) for a in turn)
    groups = {name: ([objects[name]] if name != "Chips" else chips) for name in CELLS}

    def row(palette, light, floor, small=False):
        tiles = []
        for name in CELLS:
            kind, colour = LOOK[name]
            for obj in groups[name]:
                textured(obj, images[f"fx_{kind}_{palette or colour}"])
            tiles.append(over(shot(scene, camera, groups[name], light, tmp), floor))
        strip = np.concatenate(tiles, axis=1)
        return shrink(strip, TILE // 64) if small else strip

    rows = [row("Grey", "FLAT", DARK), row("Grey", "FLAT", BRIGHT), row(None, "FLAT", DARK), row(None, "FLAT", BRIGHT),
            row(None, "STUDIO", DARK)]
    burn = []
    for name, gone in [("FxCoil3", g) for g in range(BANDS)] + [("FxCoil2", BANDS // 2)]:
        bands = [objects[f"{name}_Burn{b + 1}"] for b in range(BANDS)]
        for obj in bands:
            textured(obj, images[f"fx_across_{LOOK[name][1]}"])
        burn.append(over(shot(scene, camera, bands[gone:], "FLAT", tmp, frame=bands), DARK))  # framed on every band
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
