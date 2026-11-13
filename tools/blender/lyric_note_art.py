"""Lyric's Held Note in its art, on her clip (AR4, section 10; the block-in's A, the crests, section 9).

blender.exe -b --factory-startup --python tools/blender/lyric_note_art.py -- <out_dir> [pictures | strip]

A, the crests, with research's two fixes: the cone is 14 studs from her, and each crest thins to nothing over its last
4; and no dead air, each crest living on until the next is halfway out. And research's three asks on the block in the
game: a bright leading ribbon whose veil falls away behind it, so five arrivals read with two crests on screen; an arc,
never flat panels; her lunge into the mic (in lyric_clips.py). Three pictures:
- lyric_note_crest.png, 1024 x 256: the ribbon, one crest's leading edge, for a Beam across the cone, stretched once
  along it (U from one end of the arc to the other) and its height across (V). Two white strands edged in her Storm
  cross and cross again, the note's wave, one for each speaker, over a thin pale core. Its ends are round: a crest is
  never a blade.
- lyric_note_veil.png, 1024 x 256: the veil, the same band's body in two see-through steps, a pale white with a touch
  of her Storm, rimmed in Storm along its top and bottom. A second Beam under the ribbon, on the same two ends; it
  falls away VEIL_HOLD frames after the throw, over VEIL_FADE, so an older crest is a bright line only.
- lyric_note_touch.png, 1024 x 512, 256 cells: the hit's four frames (row 0: a white ping and her Storm crackling out
  from it, short strokes that never fall), the heal's ring (row 1, cell 0: a plain ring, mint in her Limelight), the
  rings' flash (row 1, cell 1: white only, beside her face).
Hard edges and steps, no blur, nothing liquid, nothing red: her conditions 11 to 13 and the block-in's six.
The crest is the hero: thrown from the rings on every half-beat (30, 45, 60, 75, 90), it punches out to most of the
cone in PUNCH frames and drifts on to its end, born unseen out of the rings' flash and thinning to nothing over its last
THIN studs, so one crest is always on its way. Each Shade it reaches takes the hit's four frames; each ally the ring.
Writes the three pictures, the sheet lyric_note_art.png (her clip from the player's camera and four other views, at
64 px on dark and on bright, the share of the screen), and lyric_note_art.json (what plays on every frame, for the
builder). With `pictures`, only the pictures; with `strip`, the pictures and lyric_note_strip.png, eight frames from
the player's camera, a light look when memory is short. Needs lyric_model.py's output, as lyric_clips.py does. Workbench, so no
GPU turn. Stage directions as lyric_note_fx.py: right, forward, up, in studs, from where she stands; she faces forward.
"""
import json
import math
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lyric_clips as lc  # noqa: E402
import lyric_note_fx as nf  # noqa: E402  (the block-in: its cone, stage, cameras and figures)
import lyric_sheet as ls  # noqa: E402
import rook_haymaker_art as ha  # noqa: E402  (picture)
import rook_haymaker_fx as hx  # noqa: E402  (camera, clamp, out_fast)
import rook_sheet as rs  # noqa: E402

STORM, LIME, INK = ls.PALETTE["Storm"], ls.PALETTE["Limelight"], ls.PALETTE["Ink"]
WHITE, MINT = "#FFFFFF", "#C8F5DA"
K = 2                          # supersampling, then a box down
CREST_PX = (1024, 256)
CELL = 256
TOUCH_PX = (4 * CELL, 2 * CELL)
# research's fix 1 (AR4, section 9): the cone ends 14 studs out from her, and a crest thins to nothing over its last 4
REACH, THIN = 14.0, 4.0
# research's fix 2: no dead air. A crest punches out to PUNCH_SHARE of the cone in PUNCH frames, as the block-in's
# throw did, while drifting on to the end over LIFE: so it's still a third there when the next is at its full.
PUNCH, PUNCH_SHARE, LIFE = 7, 0.7, 34
BIRTH = 2.5                    # studs past the rings over which a crest comes up out of their flash: unseen at her face
# research's ask (AR4, section 10): five arrivals must read even with two crests on screen. The veil is full as a crest
# is thrown and washes over the target (about its third frame), then falls away; the ribbon lives on, so an older crest
# is a bright line, never a second veil stacked on the new one
VEIL_HOLD, VEIL_FADE = 3, 8
# the clip's markers: a crest is thrown on each of the half-beats from the Note to the Release, as the speakers kick,
# and each crest that shows a hit lands one (research's five touches, AR4 section 9; the markers Faber's, for the beats)
MARKS = {**nf.MARKS, "Crest2": 45, "Crest3": 60, "Crest4": 75}
CRESTS = tuple(MARKS[name] for name in ("Note", "Crest2", "Crest3", "Crest4", "Release"))
HIT, HIT_SIZE, HIT_UP = 2, 3.0, 3.0  # the hit: frames a cell, studs square, its middle above the floor
HIT_FORWARD = 1.2              # studs toward the camera from the Shade's middle: in front of its coat
HEAL_LIFE, HEAL_R = 14, 1.6    # the heal's ring: frames it rises, its radius at the start
FLASH = {30: (0.9, 0.6)}       # the rings' flash on a crest's frame and the next, in studs; the Note's the biggest
SWELL = (22, 0.25, 0.55)       # the charge before the Note: from this frame, from this size to this


def mix(a, b, t):
    a, b = np.array(rs.rgb(a)), np.array(rs.rgb(b))
    return tuple(a * (1 - t) + b * t)


VEIL = mix(WHITE, STORM, 0.15)  # a pale white with a touch of her Storm
# the effects pass (AR8, part B): a bright interior with a darker, saturated edge, so it holds on a bright sky as well as
# at night (docs/research/vfx-reference.md, rule 3). The edge is her Rose taken a fifth toward her Ink: a deep magenta,
# never red
DEEP = mix(ls.PALETTE["Rose"], INK, 0.2)


# --- the pictures ----------------------------------------------------------------------------------------------------

def grid(w, h):
    """Pixel centres at K times over, x and y from -1 to 1 (y up)."""
    xs = (np.arange(w * K) + 0.5) / (w * K) * 2 - 1
    ys = 1 - (np.arange(h * K) + 0.5) / (h * K) * 2
    return np.meshgrid(xs, ys)


def down(rgba):
    h, w = rgba.shape[0] // K, rgba.shape[1] // K
    return rgba.reshape(h, K, w, K, 4).mean(axis=(1, 3)).astype(np.float32)


def over(base, colour, alpha):
    """Paints `colour` at `alpha` (an array) over `base`, straight alpha."""
    a = np.clip(alpha, 0, 1)[..., None]
    out_a = a + base[..., 3:4] * (1 - a)
    rgb = (np.array(colour)[None, None, :] * a + base[..., :3] * base[..., 3:4] * (1 - a)) / np.maximum(out_a, 1e-6)
    return np.concatenate([rgb, out_a], axis=-1)


def taper(x):
    """The band's half height along the arc, as a share: full in the middle, a third at its ends."""
    return 0.34 + 0.66 * (1 - np.abs(x) ** 2.2)


def band_grid():
    """The crest's pictures share their frame: U along the arc, V across its height, the band's taper and its round
    caps, and `level(s)`, 1 on the edge of a step `s` of the band's height."""
    w, h = CREST_PX
    X, Y = grid(w, h)
    T = taper(X)
    cap = np.clip((np.abs(X) - 0.86) / 0.14, 0, None)  # the ends: each step closes in a round cap

    def level(s):
        return np.sqrt((Y / (s * T)) ** 2 + cap ** 2)

    return X, Y, T, cap, level


def crest_picture():
    """The crest's ribbon, its leading light, there the crest's whole life: a narrow core of the pale light, and two
    strands crossing and crossing again through it, the note's wave, one for each speaker. Bold for the effects pass:
    each strand a white core twice as thick as before, in her Storm, rimmed in the deep magenta, so it reads on the
    bright sky as on the night; and fewer crossings, so each one carries at phone size. They fade out before the ends
    rather than closing to points: never a blade."""
    w, h = CREST_PX
    X, Y, T, cap, level = band_grid()
    pic = np.zeros(X.shape + (4,))
    pic = over(pic, VEIL, np.where(level(0.36) <= 1, 0.45, 0.0))
    phase = math.pi * 3.0 * (X + 1)
    curve = 0.52 * T * np.sin(phase)
    slope = np.gradient(curve, axis=1) * (w * K / 2) * (h / w)  # in pixels across over pixels along
    thick = (12.0 + 7.0 * T) / (h / 2)
    storm, deep = 3.0 / (h / 2), 6.5 / (h / 2)  # the Storm band, then the deep rim outside it
    fade = np.clip((0.86 - np.abs(X)) / 0.24, 0, 1)
    dist = [np.abs(Y - sign * curve) / np.sqrt(1 + slope ** 2) for sign in (1, -1)]
    for colour, out in ((DEEP, deep), (rs.rgb(STORM), storm)):  # rims first, so where the strands cross both whites
        for d in dist:                                           # lie over both rims
            pic = over(pic, colour, np.where(d <= thick / 2 + out, fade, 0.0))
    for d in dist:
        pic = over(pic, rs.rgb(WHITE), np.where(d <= thick / 2, fade, 0.0))
    return down(pic)


def veil_picture():
    """The crest's veil, the soft light behind its ribbon: two wide see-through steps of the pale light, edged in her
    Storm along the top and the bottom only, fading out round the ends: an arc of light, never a closed outline. It
    shows as a crest is thrown and washes over the target, and falls away after, so the crests never stack into a
    wall (research, AR4 section 10)."""
    w, h = CREST_PX
    X, Y, T, cap, level = band_grid()
    pic = np.zeros(X.shape + (4,))
    for s, alpha in ((1.0, 0.18), (0.68, 0.28)):
        pic = over(pic, VEIL, np.where(level(s) <= 1, alpha, 0.0))
    edge = 10 / (h / 2)  # px of the half height: the deep rim, with her Storm on its inner side
    outer = level(1.0)
    rim = 0.9 * np.clip(1 - cap / 0.5, 0, 1)
    pic = over(pic, DEEP, np.where((outer <= 1) & (outer > 1 - edge / T), rim, 0.0))
    pic = over(pic, rs.rgb(STORM), np.where((outer <= 1 - 0.55 * edge / T) & (outer > 1 - edge / T), rim, 0.0))
    return down(pic)


def jag(points, offsets):
    """A crackle: the line through `points`, each inner point pushed sideways by its offset."""
    out = [points[0]]
    for p, q, o in zip(points[:-1], points[1:], offsets):
        n = Vector((-(q - p).y, (q - p).x)).normalized()
        out.append((p + q) / 2 + n * o)
        out.append(q)
    return out


def stroke(X, Y, path, width):
    """Coverage of a polyline `width` wide."""
    d = np.full(X.shape, np.inf)
    for a, b in zip(path[:-1], path[1:]):
        ab = b - a
        t = np.clip(((X - a.x) * ab.x + (Y - a.y) * ab.y) / max(ab.length_squared, 1e-9), 0, 1)
        d = np.minimum(d, np.hypot(X - (a.x + t * ab.x), Y - (a.y + t * ab.y)))
    return d <= width / 2


def touch_picture():
    """The touches' atlas, in 256 cells: the hit's four frames, the heal's ring, the rings' flash. A cell's x and y run
    from -1 to 1; the hit's cell is HIT_SIZE studs across, so a stud is 2 / HIT_SIZE of it."""
    atlas = np.zeros((TOUCH_PX[1], TOUCH_PX[0], 4), dtype=np.float32)
    X, Y = grid(CELL, CELL)
    R = np.hypot(X, Y)
    stud = 2 / HIT_SIZE
    sparks = 7
    # Each crackle its own (the content check before upload, 2026-11-13: even angles and one mirrored jag sat near a
    # wheel of glyphs): its own angle off the even spacing, its own length, two, three or four bends, and kinks of its
    # own size and side on every frame. Seeded, so a rebuild draws the same picture.
    rng = random.Random(4417)
    spread = [rng.uniform(-0.2, 0.2) for _ in range(sparks)]
    reach = [rng.uniform(0.8, 1.2) for _ in range(sparks)]
    bends = [3, 2, 3, 4, 3, 2, 3]
    rng.shuffle(bends)
    for n in range(4):
        cell = np.zeros(X.shape + (4,))
        ring_r, ring_w = (0.25, 0.55, 0.85, 1.1)[n] * stud, (0.24, 0.17, 0.1, 0.05)[n] * stud
        if n == 0:
            cell = over(cell, rs.rgb(WHITE), np.where(R <= 0.32 * stud, 1.0, 0.0))
        cell = over(cell, rs.rgb(WHITE), np.where(np.abs(R - ring_r) <= ring_w / 2, 0.95, 0.0))
        inner, outer = ((0.3, 0.78), (0.55, 1.15), (0.88, 1.36), (1.15, 1.45))[n]
        width = (0.13, 0.11, 0.08, 0.05)[n] * stud
        for j in range(sparks):
            # the crackle shifts a little each frame, each spark its own way
            a = 2 * math.pi * j / sparks + 0.35 + spread[j] + rng.uniform(-0.08, 0.08)
            way = Vector((math.cos(a), math.sin(a)))
            far = min(inner + (outer - inner) * reach[j], 1.4)  # inside the 3-stud cell, never cut flat
            b = bends[j] if n < 2 else max(2, bends[j] - 1)  # dying, it has fewer bends: short and tight reads as a letter
            pts = [way * (inner + (far - inner) * k / b) * stud for k in range(b + 1)]
            seg = (far - inner) / b  # each kink sized to its own segment, so every spark keeps a bolt's proportions
            side = rng.choice((1, -1))
            kinks = []
            for _ in range(b):
                kinks.append(side * rng.uniform(0.3, 0.55) * seg * stud)
                side = -side if rng.random() < 0.8 else side  # mostly a zigzag, now and then two bends one way
            path = jag(pts, kinks)
            cell = over(cell, DEEP, np.where(stroke(X, Y, path, width + 0.05), 1.0, 0.0))  # the deep rim (AR8)
            cell = over(cell, rs.rgb(STORM), np.where(stroke(X, Y, path, width), 1.0, 0.0))
            if n < 2:  # a white core in the first two, while it's hot
                cell = over(cell, rs.rgb(WHITE), np.where(stroke(X, Y, path, width * 0.4), 1.0, 0.0))
        atlas[0:CELL, n * CELL:(n + 1) * CELL] = down(cell)
    ring = np.zeros(X.shape + (4,))  # the heal: a plain ring, mint, its two rims in her Limelight
    ring = over(ring, rs.rgb(MINT), np.where(np.abs(R - 0.8) <= 0.1, 0.95, 0.0))
    for rim in (0.7, 0.9):
        ring = over(ring, rs.rgb(LIME), np.where(np.abs(R - rim) <= 0.022, 1.0, 0.0))
    atlas[CELL:2 * CELL, 0:CELL] = down(ring)
    flash = np.zeros(X.shape + (4,))  # the rings' flash: white only, beside her face
    flash = over(flash, rs.rgb(WHITE), np.where(R <= 0.55, 1.0, 0.0))
    flash = over(flash, rs.rgb(WHITE), np.where(np.abs(R - 0.8) <= 0.05, 0.8, 0.0))
    atlas[CELL:2 * CELL, CELL:2 * CELL] = down(flash)
    return atlas


CELLS = {"hit0": (0, 0), "hit1": (1, 0), "hit2": (2, 0), "hit3": (3, 0), "heal": (0, 1), "flash": (1, 1)}


def rect(name):
    c, r = CELLS[name]
    return (c * CELL, r * CELL, CELL, CELL)


# --- what plays on every frame ---------------------------------------------------------------------------------------

def crest(cone, t):
    """A crest `t` frames after it's thrown: (its radius off the apex, how much of its ribbon shows, its height's share,
    how much of its veil shows), or None once it's gone."""
    if not 0 <= t <= LIFE:
        return None
    travel = PUNCH_SHARE * hx.out_fast(t / PUNCH) + (1 - PUNCH_SHARE) * t / LIFE
    radius = cone.start + (cone.end - cone.start) * travel
    born = nf.smooth((radius - cone.start) / BIRTH)
    thin = hx.clamp((radius - (cone.end - THIN)) / THIN)
    shows = born * (1 - thin)
    return radius, shows, 1 - 0.6 * thin, shows * (1 - nf.smooth((t - VEIL_HOLD) / VEIL_FADE))


def band(cone, radius, height):
    """The crest's band at a radius: its bottom and top, the block-in's span, its height thinned by `height`."""
    bottom, top = cone.span(radius)
    mid, half = (bottom + top) / 2, (top - bottom) / 2 * height
    return mid - half, mid + half


def touches(stage):
    """Each figure in the cone, and the frames a crest reaches it: its radius at or past the figure's, a half width
    (0.7) short, while the crest still shows."""
    out = {}
    cone = stage.cone
    for name, at in stage.figures.items():
        radius, angle = cone.place(at)
        if abs(angle) > cone.half or radius > cone.end:
            out[name] = []
            continue
        seen = []
        for born in CRESTS:
            for t in range(LIFE + 1):
                c = crest(cone, t)
                if c and c[0] >= radius - 0.7:
                    if c[1] > 0.05:
                        seen.append(born + t)
                    break
        out[name] = seen
    return out


def flash_size(f):
    if SWELL[0] <= f < nf.NOTE:
        return SWELL[1] + (SWELL[2] - SWELL[1]) * nf.smooth((f - SWELL[0]) / (nf.NOTE - SWELL[0]))
    for born in CRESTS:
        if f in (born, born + 1):
            return FLASH.get(born, (0.6, 0.4))[f - born]
    return None


def art(stage, f):
    """Everything drawn on frame f: ("crest", born, radius, shows, height, veil), ("quad", cell, centre, size),
    ("ring", centre, radius, shows)."""
    out = []
    for born in CRESTS:
        c = crest(stage.cone, f - born)
        if c and c[1] > 0.004:
            out.append(("crest", born, *c))
    size = flash_size(f)
    if size:
        for name in (lc.SR, lc.SL):
            out.append(("quad", "flash", stage.ring[name][f] + stage.axis[name][f] * 0.15, size))
    for name, frames in stage.touched.items():
        x, y = stage.figures[name]
        for at in frames:
            t = f - at
            if name == "Ally" and 0 <= t <= HEAL_LIFE:
                u = t / HEAL_LIFE
                out.append(("ring", Vector((x, y, 0.4 + 4.6 * hx.out_fast(u))), HEAL_R * (1 - 0.3 * u),
                            1 - hx.clamp((t - (HEAL_LIFE - 5)) / 5)))
            elif name != "Ally" and 0 <= t < 4 * HIT:
                out.append(("quad", f"hit{t // HIT}", Vector((x, y, HIT_UP)), HIT_SIZE))
    return out


# --- the stage: her clip, the cone, and the pictures drawn as the game draws them ------------------------------------

def to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def cut(pic, name):
    x, y, w, h = rect(name)
    return pic[y:y + h, x:x + w]


class Stage(nf.Stage):
    """The block-in's stage, its grey shapes off, drawing the pictures instead: each crest a ribbon standing up across
    the cone at its radius, as a Beam with its width upright draws it; the hit and the flash facing the camera, as a
    BillboardGui; the heal's ring lying flat, as a Decal on a Part's top. Workbench draws a texture opaque, its alpha
    ignored, so each piece is a layer of its own (an object with its own picture), placed on every frame and left
    hidden; `shoot` shows them one at a time, painted black, then their alpha as grey, then their colour times their
    alpha, and lays them over the shaded clip by the differences."""

    def __init__(self, scene, rig, frames, rest, crest_pic, veil_pic, touch_pic):
        self.ready, self.layers = False, []
        self.solo, self.coat, self.painted = None, "black", {}  # the layer shown, the pass it's painted for
        self.crest_pic, self.veil_pic, self.touch_pic = crest_pic, veil_pic, touch_pic
        super().__init__(scene, rig, frames, rest)
        self.touched = touches(self)
        self.slots = [self.layer(f"Fx.Crest{i}", crest_pic) for i in range(3)]  # at most three crests are out at once
        self.veils = [self.layer(f"Fx.Veil{i}", veil_pic) for i in range(3)]
        self.quads = []
        self.heal = self.layer("Fx.Heal", cut(touch_pic, "heal"), horizontal=True)
        self.ready = True

    def layer(self, name, pic, horizontal=None):
        """An object with a picture of its own: a mesh remade each frame (horizontal None), or a unit quad standing
        (False) or lying flat (True)."""
        mesh = bpy.data.meshes.new(name)
        if horizontal is not None:
            corners = ((-0.5, -0.5, 0), (0.5, -0.5, 0), (0.5, 0.5, 0), (-0.5, 0.5, 0)) if horizontal else \
                      ((-0.5, 0, -0.5), (0.5, 0, -0.5), (0.5, 0, 0.5), (-0.5, 0, 0.5))
            mesh.from_pydata(corners, [], [(0, 1, 2, 3)])
            uv = mesh.uv_layers.new(name="UV")
            for loop, co in zip(uv.data, ((0, 0), (1, 0), (1, 1), (0, 1))):
                loop.uv = co
        mesh.materials.append(ha.picture(name, pic))
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.display.show_shadows = False
        obj.hide_render = True
        return obj

    def show_solo(self):
        """Shows the one layer `solo`, painted for the pass `coat`; the rest stay hidden. Called by `set` too, as a
        render fires the frame's handler again."""
        if self.solo is None or self.solo >= len(self.layers):
            return
        obj, pic, shows, _ = self.layers[self.solo]
        wanted = (self.coat, shows, pic.ctypes.data)  # the picture by where its pixels live: a cell keeps its own
        if self.painted.get(obj.name) != wanted:
            self.paint(obj, pic, shows, self.coat)
            self.painted[obj.name] = wanted
        obj.hide_render = False

    @staticmethod
    def paint(obj, pic, shows, mode):
        """Paints a layer's picture for one pass: black; its alpha as grey; its colour times its alpha (in linear
        light, written back as the sRGB the picture is read in). Opaque, as Workbench draws it anyway."""
        a = pic[..., 3:4] * shows
        if mode == "black":
            rgb = np.zeros(pic.shape[:2] + (3,))
        elif mode == "alpha":
            rgb = np.repeat(to_srgb(a), 3, axis=-1)
        else:
            rgb = to_srgb(to_linear(pic[..., :3]) * a)
        out = np.concatenate([rgb, np.ones(pic.shape[:2] + (1,))], axis=-1).astype(np.float32)
        image = obj.data.materials[0].node_tree.nodes.active.image
        image.pixels.foreach_set(np.ascontiguousarray(out[::-1]).ravel())
        image.update()

    def ribbon(self, obj, radius, bottom, top, steps=32):
        """A crest's ribbon across the whole cone at `radius`, standing from `bottom` to `top`, U along it. Two-sided,
        as a Beam is drawn: her scene culls back faces, as Roblox does a MeshPart's."""
        cone = self.cone
        verts, faces, uvs = [], [], []
        for i in range(steps + 1):
            a = math.radians(-cone.half + 2 * cone.half * i / steps)
            p = cone.apex + Vector((math.sin(a), math.cos(a))) * radius
            verts += [(p.x, p.y, bottom), (p.x, p.y, top)]
        back = len(verts)
        verts += verts[:]
        for i in range(steps):
            u0, u1 = i / steps, (i + 1) / steps
            faces.append((2 * i, 2 * i + 2, 2 * i + 3, 2 * i + 1))  # facing her
            uvs += [(u0, 0), (u1, 0), (u1, 1), (u0, 1)]
            faces.append((back + 2 * i, back + 2 * i + 1, back + 2 * i + 3, back + 2 * i + 2))  # facing out
            uvs += [(u0, 0), (u0, 1), (u1, 1), (u1, 0)]
        mesh = obj.data
        mesh.clear_geometry()
        mesh.from_pydata(verts, [], faces)
        layer = mesh.uv_layers.new(name="UV")
        for loop, co in zip(layer.data, uvs):
            loop.uv = co
        mesh.update()

    def set(self, scene, *_):
        """Places every piece drawn on this frame, hidden, and lists them as layers, the farthest from the camera
        first: (object, picture, how much of it shows, its middle)."""
        if not self.ready:
            return
        f = scene.frame_current
        self.place_avatar(scene)
        for obj in self.slots + self.veils + self.quads + [self.heal]:
            obj.hide_render = True
        self.layers = []
        if not (self.show and scene.camera):
            return
        eye = scene.camera.matrix_world.translation
        view = scene.camera.matrix_world.to_3x3().normalized()
        face = Matrix((view.col[0], -view.col[2], view.col[1])).transposed()  # across the screen, at the camera, up it
        slots, veils, used = iter(self.slots), iter(self.veils), 0
        for item in art(self, f):
            if item[0] == "crest":
                _, born, radius, shows, height, veil = item
                obj = next(slots)
                bottom, top = band(self.cone, radius, height)
                self.ribbon(obj, radius, bottom, top)
                centre = Vector((*(self.cone.apex + Vector((0.0, radius))), (bottom + top) / 2))
                self.layers.append((obj, self.crest_pic, shows, centre))
                if veil > 0.004:  # on the ribbon's own arc, drawn under it (in Roblox: the same attachments, a lower ZOffset)
                    under = next(veils)
                    self.ribbon(under, radius, bottom, top)
                    self.layers.append((under, self.veil_pic, veil, centre + (centre - eye).normalized() * 0.01))
            elif item[0] == "ring":
                _, centre, radius, shows = item
                across = radius * 2 / 0.8  # the ring is drawn at 0.8 of its cell's half
                self.heal.matrix_world = Matrix.Translation(centre) @ Matrix.Diagonal((across, across, 1, 1))
                self.layers.append((self.heal, cut(self.touch_pic, "heal"), shows, centre))
            else:
                _, cell, centre, size = item
                if cell.startswith("hit"):  # in front of the Shade's coat, toward the camera
                    centre = centre + (eye - centre).normalized() * HIT_FORWARD
                if used == len(self.quads):
                    self.quads.append(self.layer(f"Fx.Quad{used}", cut(self.touch_pic, cell), horizontal=False))
                obj = self.quads[used]
                used += 1
                obj.matrix_world = Matrix.Translation(centre) @ (face @ Matrix.Diagonal((size, 1, size))).to_4x4()
                self.layers.append((obj, cut(self.touch_pic, cell), 1.0, centre))
        self.layers.sort(key=lambda layer: -(layer[3] - eye).length)
        self.show_solo()


# --- the sheet -------------------------------------------------------------------------------------------------------

def shoot(scene, stage, camera, f, label, size, out):
    """One tile: the clip shaded, and each piece laid over it, the farthest first, by its alpha, unlit in its own
    colours, in linear light; and the count of the pixels the effect covers (over 3%)."""
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = size
    shading = scene.display.shading
    path = out / "_tile.png"
    scene.render.filepath = str(path)
    scene.render.stamp_note_text = label

    def render(flat):
        shading.light = "FLAT" if flat else "STUDIO"
        shading.show_shadows = shading.show_cavity = shading.show_object_outline = not flat
        scene.render.use_stamp = bool(label) and not flat
        bpy.ops.render.render(write_still=True)
        return to_linear(rs.load(path)[..., :3])

    stage.show, stage.solo = True, None
    scene.frame_set(f)
    tile = render(False)
    cover = np.zeros(tile.shape[:2])
    for i in range(len(stage.layers)):
        passes = []
        for coat in ("black", "alpha", "colour"):
            stage.solo, stage.coat = i, coat
            stage.show_solo()
            passes.append(render(True))
        stage.layers[i][0].hide_render = True
        stage.solo = None
        black, alpha, colour = passes
        a = np.clip((alpha - black).mean(axis=-1), 0, 1)
        tile = (colour - black) + (1 - a[..., None]) * tile
        cover = 1 - (1 - cover) * (1 - a)
    path.unlink()
    tile = np.concatenate([to_srgb(tile), np.ones(tile.shape[:2] + (1,))], axis=-1)
    return tile, int((cover > 0.03).sum())


SHEET = (22, 30, 31, 32, 33, 35, 40, 45, 47, 50, 55, 60, 75, 90, 95, 110)  # the player's camera, four rows of four
ROW = (30, 33, 40, 45, 48, 60, 92, 100)                                     # the other views
SMALL = (30, 32, 34, 36, 40, 45, 48, 52, 60, 75, 92, 100)                   # at 64 px
SHARE = (30, 32, 34, 36, 40, 50, 65, 80, 92, 98)                            # the block-in's frames, to set beside it
STRIP = (31, 33, 36, 40, 45, 47, 50, 55)                                    # `strip`: two crests out, from 45
NAMES = {f: name for name, f in MARKS.items()}


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def table(stage):
    """What plays on every frame, for the builder, by rule from the speakers rather than by place."""
    c = stage.cone
    frames = {}
    for f in range(SWELL[0], CRESTS[-1] + LIFE + 1):
        entry = {}
        crests = []
        for born in CRESTS:
            at = crest(c, f - born)
            if at and at[1] > 0.004:
                radius, shows, height, veil = at
                bottom, top = band(c, radius, height)
                crests.append({"born": born, "radius": round(radius, 3), "transparency": round(1 - shows, 3),
                               "veil_transparency": round(1 - veil, 3),
                               "middle": round((bottom + top) / 2, 3), "width": round(top - bottom, 3)})
        if crests:
            entry["crests"] = crests
        size = flash_size(f)
        if size:
            entry["flash"] = round(size, 3)
        if entry:
            frames[str(f)] = entry
    return {
        "pictures": {"lyric_note_crest.png": list(CREST_PX), "lyric_note_veil.png": list(CREST_PX),
                     "lyric_note_touch.png": list(TOUCH_PX)},
        "fps": 60, "markers": MARKS, "crests": list(CRESTS),
        "cone": {"apex": [round(v, 3) for v in c.apex], "half": round(c.half, 2), "start": round(c.start, 3),
                 "end": round(c.end, 3), "rings_up": round(c.height, 3), "fall": round(c.fall, 4),
                 "spread": nf.SPREAD, "reach": REACH, "thin": THIN,
                 "axes": "right, forward, up, studs, from where she stands, the floor under her; she faces forward. "
                         "Radii are off the apex. Read off her speakers in the hold (frame 60)"},
        "crest": {"punch": PUNCH, "punch_share": PUNCH_SHARE, "life": LIFE, "birth": BIRTH,
                  "rule": "travel = punch_share * out_fast(t / punch) + (1 - punch_share) * t / life; radius = start + "
                          "(end - start) * travel; shows = smooth((radius - start) / birth) * (1 - clamp((radius - (end - "
                          "thin)) / thin)); its height is the span's, times 1 - 0.6 * clamp(...); the veil shows = "
                          "shows * (1 - smooth((t - veil_hold) / veil_fade))",
                  "veil_hold": VEIL_HOLD, "veil_fade": VEIL_FADE,
                  "beam": {"FaceCamera": False, "the width": "upright", "Segments": 24, "TextureMode": "Stretch",
                           "TextureLength": 1, "TextureSpeed": 0, "LightInfluence": 0, "Color": "white",
                           "ends": "the arc's two ends, at plus and minus the half angle, on the radius, at `middle`",
                           "CurveSize": "0.2834 x radius at each end, along the arc's tangent toward the other end: "
                                        "a circle's arc of twice the half angle. An arc, never flat panels "
                                        "(research, AR4 section 10)",
                           "two": "each crest is two Beams on the same two attachments: the ribbon "
                                  "(lyric_note_crest.png, `transparency`) over the veil (lyric_note_veil.png, "
                                  "`veil_transparency`), the veil's ZOffset below the ribbon's"}},
        "hit": {"cells": ["hit0", "hit1", "hit2", "hit3"], "frames_a_cell": HIT, "size": HIT_SIZE, "up": HIT_UP,
                "toward_the_camera": HIT_FORWARD,
                "when": "the frame a crest that still shows reaches a Shade's radius, 0.7 short"},
        "heal": {"cell": "heal", "life": HEAL_LIFE, "radius": HEAL_R,
                 "rule": "flat, rising from 0.4 to 5.0 up (out_fast), its radius 1.6 down to 1.12, gone over its last 5 "
                         "frames; the ring is drawn at 0.8 of its cell's half, so the Part is radius * 2 / 0.8 across"},
        "flash": {"cell": "flash", "where": "each speaker's ring, 0.15 out along its cone", "swell": list(SWELL),
                  "sizes": "0.9 and 0.6 on the Note and the frame after; 0.6 and 0.4 on each crest after"},
        "cells": {name: list(rect(name)) for name in CELLS},
        "frames": frames,
    }


def main():
    out = bl.out_dir()
    rs.OUT = out
    crest_pic, veil_pic, touch_pic = crest_picture(), veil_picture(), touch_picture()
    rs.save(crest_pic, out / "lyric_note_crest.png")
    rs.save(veil_pic, out / "lyric_note_veil.png")
    rs.save(touch_pic, out / "lyric_note_touch.png")
    if "pictures" in sys.argv[sys.argv.index("--") + 1:]:
        return

    nf.REACH = REACH                 # research's 14 (the block-in's stand-in was 16)
    nf.OTHER = (3.0, 12.6)           # the second Shade inside the 14 studs, where the block-in's stood past them
    scene, rig, costume, undress, feet, ctl, motors = lc.build()
    bpy.context.view_layer.update()
    rest = {}
    for name in (lc.SR, lc.SL):
        m = bpy.data.objects[name].matrix_world
        rest[name] = (m.inverted() @ nf.RINGS[name], (m.to_3x3().inverted() @ nf.AXES[name]).normalized())
    count = nf.key(rig, MARKS)
    print(f"HeldNote: {count} frames, the markers at {MARKS}")
    stage = Stage(scene, rig, count, rest, crest_pic, veil_pic, touch_pic)
    print(f"  touched: {json.dumps(stage.touched)}")
    cams = {}
    for name in ("fight", "fight50", "beside", "hidden"):
        look, spot = nf.staged(name)
        azimuth = math.degrees(math.atan2(-look.x, -look.y))
        cams[name] = hx.camera(scene, name, azimuth, nf.PITCH, nf.EYE / math.cos(math.radians(nf.PITCH)),
                               (spot.x, spot.y, 4.5), 50.0 if name == "fight50" else 70.0)
        radius, angle = stage.cone.place((spot.x, spot.y))
        print(f"  {name}: the avatar {Vector((spot.x, spot.y)).length:.1f} studs from her, {angle:.0f} degrees off the "
              f"cone's middle ({'in' if abs(angle) <= stage.cone.half and radius <= stage.cone.end else 'out of'} it)")
    cams["side"] = hx.camera(scene, "side", 90.0, 6.0, 27.0, (0.0, 8.0, 3.0), 40.0)
    bpy.data.objects["Floor"].scale *= 4
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk, bright = tuple(floor.diffuse_color), (0.74, 0.72, 0.68, 1)
    r = scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note, r.stamp_font_size = True, 18

    big, row, tiny, share_px = (456, 256), (228, 128), (75, 64), (480, 270)
    if "strip" in sys.argv[sys.argv.index("--") + 1:]:  # a light look: eight frames from the player's camera only
        strip = rs.canvas(4 * big[0] + 50, 2 * big[1] + 30, rs.PAPER)
        for i, f in enumerate(STRIP):
            rs.paste(strip, shoot(scene, stage, cams["fight"], f, label(f), big, out)[0],
                     10 + (i % 4) * (big[0] + 10), 10 + (i // 4) * (big[1] + 10))
        rs.save(strip, out / "lyric_note_strip.png")
        return
    game = [shoot(scene, stage, cams["fight"], f, label(f), big, out) for f in SHEET]
    rows = {view: [shoot(scene, stage, cams[view], f, label(f), row, out)[0] for f in ROW]
            for view in ("beside", "hidden", "side")}
    small = {"dark": [shoot(scene, stage, cams["fight50"], f, "", tiny, out) for f in SMALL]}
    share = {f: shoot(scene, stage, cams["fight"], f, "", share_px, out)[1] for f in SHARE}
    floor.diffuse_color = bright
    rows["bright"] = [shoot(scene, stage, cams["fight"], f, label(f), row, out)[0] for f in ROW]
    small["bright"] = [shoot(scene, stage, cams["fight50"], f, "", tiny, out) for f in SMALL]
    floor.diffuse_color = dusk
    bpy.app.handlers.frame_change_pre.remove(stage.set)

    area = share_px[0] * share_px[1]
    numbers = table(stage)
    block = {}
    blockin = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "lyric" / "note" / "heldnote.json"
    if blockin.exists():
        block = json.loads(blockin.read_text()).get("share", {}).get("A", {})
    numbers["checks"] = {
        "touched": stage.touched,
        "share": {str(f): {"block": block.get(str(f)), "art": round(n / area, 4)} for f, n in share.items()},
        "pixels_at_64": {key: dict(zip(map(str, SMALL), (t[1] for t in tiles))) for key, tiles in small.items()},
        "camera": f"the player's: behind the avatar, {nf.EYE} studs, {nf.PITCH} degrees down, 70 degrees"}
    (out / "lyric_note_art.json").write_text(json.dumps(numbers, indent=1))
    print(json.dumps(numbers["checks"], indent=1))

    W, H = 1920, 2810
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft = INK, "#6A655E"
    x0 = 40
    text = [(x0, 30, 54, "LYRIC'S HELD NOTE, THE ART", ink),
            (860, 30, 20, "The block-in's A, the crests, with research's fixes: the cone ends 14 studs out, each crest thinning to", ink),
            (860, 54, 20, "nothing over its last 4; one always on its way; a bright ribbon whose veil falls away; an arc; her lunge.", ink)]
    y = 104
    text.append((x0, y, 20, "lyric_note_crest.png, the ribbon, and lyric_note_veil.png, under it, 1024 x 256 each, Beams' pictures stretched once along the arc; lyric_note_touch.png, 1024 x 512", ink))
    crest_small, veil_small = rs.shrink(crest_pic, 0.5), rs.shrink(veil_pic, 0.5)
    touch_small = rs.shrink(touch_pic, 0.5)
    for i, (ground, grey) in enumerate(((rs.NIGHT, False), (rs.DAY, False), (rs.rgb("#77777B"), True))):
        rs.fill(page, x0 + i * 620, y + 30, 532, 288, ground)
        rs.paste(page, rs.grey(crest_small) if grey else crest_small, x0 + 10 + i * 620, y + 40)
        rs.paste(page, rs.grey(veil_small) if grey else veil_small, x0 + 10 + i * 620, y + 180)
        rs.fill(page, x0 + i * 620, y + 328, 532, 276, ground)
        rs.paste(page, rs.grey(touch_small) if grey else touch_small, x0 + 10 + i * 620, y + 338)
    for i, words in enumerate((
            f"The crest: thrown from the rings on every half-beat ({', '.join(map(str, CRESTS))}), {PUNCH_SHARE:.0%} of the way out in {PUNCH} frames, then drifting to the end over {LIFE}; "
            f"unseen for its first {BIRTH} studs (out of the rings' flash), thinning over its last {THIN}. Its veil holds {VEIL_HOLD} frames and falls away over {VEIL_FADE}.",
            f"The hit: a white ping and Storm crackling out, {HIT} frames a cell, {HIT_SIZE} studs, on a Shade's chest the frame a crest reaches it. "
            f"The heal: the plain ring rising round an ally, {HEAL_LIFE} frames. The flash: white, at each ring.")):
        text.append((x0, y + 614 + i * 20, 15, words, soft))
    y = 790
    text.append((x0, y, 20, "From the player's camera: behind the avatar, the lead past its target turned 45 degrees (the clip's frames, 60 a second; the Note is 30, the Release 90)", ink))
    for n, (tile, _) in enumerate(game):
        rs.paste(page, tile, x0 + (n % 4) * 466, y + 28 + (n // 4) * 266)
    y = 1890
    for title, key in (("On a bright floor", "bright"), ("Beside: an elite's spot, the wave crossing the screen", "beside"),
                       ("Hidden: the avatar facing its target dead on", "hidden"), ("From the side", "side")):
        text.append((x0, y, 18, title, ink))
        for c, tile in enumerate(rows[key]):
            rs.paste(page, tile, x0 + c * 232, y + 24)
        y += 160
    y += 10
    text.append((x0, y, 18, "At 64 px from the player's camera, on dark and on bright, then in grey. Under each, the effect's pixels", ink))
    for i, key in enumerate(("dark", "bright")):
        for c, (tile, n) in enumerate(small[key]):
            rs.paste(page, tile, x0 + c * 80, y + 26 + i * 86)
            text.append((x0 + c * 80 + 2, y + 26 + i * 86 + 66, 12, f"{SMALL[c]}: {n}", soft))
    for c, (tile, _) in enumerate(small["dark"]):
        rs.paste(page, rs.grey(tile), x0 + 1000 + (c % 6) * 80, y + 26 + (c // 6) * 86)
    y += 200
    shares = ", ".join(f"{f}: {(block.get(str(f)) or 0):.1%} to {n / area:.1%}" for f, n in share.items())
    for i, words in enumerate((f"The share of the player's screen, the block-in's A to the art: {shares}.",
                               "The pictures are drawn flat and unlit, with no glow added: the game's bloom is the builder's. lyric_note_art.json has what plays on every frame.")):
        text.append((x0, y + i * 24, 16, words, soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "lyric_note_art.png")


if __name__ == "__main__":
    main()
