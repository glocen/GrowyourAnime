"""AR3, section 4: the reveal's block-in (docs/asset-requests.md; docs/design.md, "Shards and the Void Breaker";
docs/ui.md, "The reveal"). In grey and stand-ins, nothing finished: the Void Shard's one form for its three grades with
the lines it cracks along, the reveal's beats with their times for a Common and for a Legendary, the rarity's read
before the name, and the larger frame's cut.

Run: blender -b --factory-startup --python tools/blender/reveal_blockin.py -- <out_dir> <mode> ...
  shard                   the form: three grades, its lines, the turn, four sizes -> reveal_shard.png
  figure                  Rook's Reveal clip from its own front camera, every other frame, cut out -> <out>/figure/
  beats <rarity> [A|B] i j   beats i to j - 1, each at 2 px a point -> beats/
  strip <rarity> [A|B]       the beats put together -> reveal_strip_<rarity>_<layout>.png
  frame <rarity> [A|B] t ... single frames at t seconds from the tap -> frame_<rarity>_<layout>_<t>.png
  read                       the six rarities' frames at the silhouette's beat (made by frame mode), put together, and the
                             larger frame's cut -> reveal_rarity.png
  variants                   layouts A and B at the name and held (made by frame mode), put together -> reveal_variants.png
  movie <rarity> [A|B] i j   movie frames i to j - 1 at 30 a second -> movie_<rarity>_<layout>/
  assemble <rarity> [A|B]    those frames -> reveal_<rarity>_<layout>.mp4
One Blender run stays under the PC's memory floor for about four frames at 2 px a point, so frames are made in runs.

The shard is five pieces that meet on four seams, so "its own lines" are where it's already parted. A pale core stands
inside it: where a seam opens the core shows through, and that's the leak, shot as a pass of its own and laid on as
light. The fighter is Rook's model on his Reveal clip (rook_clips.py). No Legendary is built, so his body stands in under
a Legendary's name. Text is Blender's own face, a stand-in for the game's. Nothing is taken from anywhere else.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import frames_to_movie  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_kit  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import WHITE, c  # noqa: E402

K = ui.K                      # pixels a point: 2 for the beats, 1 for the movies (set_scale)
W, H = 844, 390               # a phone's screen in points, landscape
FPS = 60
VIOLET = ui_kit.PALETTES["Void Violet"]
UNIT = 50.0                   # points one of the shard's units: it stands 4.5 units, 225 points, in the reveal
STUD = 46.0                   # points a stud of the fighter: Rook's five studs stand 230 points
FLOOR = 356.0                 # the row the fighter's feet stand on
TILE = (320, 390)             # the fighter's own tile, in points, its middle on the stage's middle
CAMERA = (38.0, 8.0)          # rook_clips.FRONT: the camera every Reveal clip was judged from
ACCENT, HOLD, CLIP = 0.85, 0.97, 1.6   # Rook's Reveal: the ram fires (Knock), the held pose begins, the clip ends
STAGE = {"A": 422.0, "B": 548.0}       # where the fighter stands once the name is down
SLANT = 0.176                 # the kit's slant, 10 degrees

# --- the shard --------------------------------------------------------------------------------------------------------

# The body from its front, clockwise from the top: a piece broken off something larger. The top is the break, a slant;
# its right shoulder sits high and its left one low, so it leans; the foot is off to the left. Seven sides, long ones.
# Convex, so every piece of it is too.
OUTLINE = ((0.44, 2.28), (0.96, 0.95), (0.50, -1.45), (-0.16, -2.25), (-0.96, -0.40), (-0.74, 1.25), (-0.30, 1.96))
assert all((b[0] - a[0]) * (d[1] - b[1]) - (b[1] - a[1]) * (d[0] - b[0]) < 0
           for a, b, d in zip(OUTLINE, OUTLINE[1:] + OUTLINE[:1], OUTLINE[2:] + OUTLINE[:2])), "the outline must be convex"
TABLE = (0.5, (0.06, 0.1), -0.6)      # the front's flat: the outline shrunk about a point, this far forward
KEEL = (0.24, (-0.05, 0.0), 0.7)      # the back's
SEAMS = {  # a point on each and its normal (x, y, z; the normal's side is "+"). A is the slant the others hang from.
    "A": ((0.0, 0.0, 0.016), (-0.545, 0.18, 0.839)),
    "B": ((-0.18, 0.0, -0.10), (0.9946, -0.12, -0.104)),
    "C": ((0.30, 0.0, 0.21), (0.969, 0.15, 0.246)),
    "D": ((-0.55, 0.0, -0.34), (0.9955, -0.10, 0.0966)),
}
PIECES = (  # its side of each seam that bounds it
    ("UpperLeft", {"A": 1, "B": -1}), ("Tip", {"A": 1, "B": 1}), ("Sliver", {"A": -1, "D": -1}),
    ("Foot", {"A": -1, "D": 1, "C": -1}), ("Chip", {"A": -1, "C": 1}))
LOOSE = {"B": ("UpperLeft", -1), "C": ("Chip", 1), "D": ("Sliver", -1)}  # the piece a hanging seam lets slide, and which way
BUDS = {  # a grade's growths: the body again, smaller, rising from beside its foot: (piece, scale, place, lean in degrees)
    "Standard": (),
    "Enriched": (("Foot", 0.5, (0.78, 0.05, -1.05), 24.0),),
    "Prismatic": (("Foot", 0.5, (0.78, 0.05, -1.05), 24.0), ("Sliver", 0.4, (-0.98, -0.05, -1.0), -36.0)),
}
GREY = (0.36, 0.36, 0.40, 1.0)


def hull(points):
    bm = bmesh.new()
    for p in points:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts[:])
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(1.0), verts=bm.verts[:], edges=bm.edges[:])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm


def body_points(scale=1.0):
    pts = [(x, 0.0, z) for x, z in OUTLINE]
    for k, (ox, oz), y in (TABLE, KEEL):
        pts += [(ox + (x - ox) * k, y, oz + (z - oz) * k) for x, z in OUTLINE]
    return [tuple(v * scale for v in p) for p in pts]


def piece_points(sides):
    """The body, cut down to one piece: what's left on its side of each of its seams."""
    bm = hull(body_points())
    for seam, side in sides.items():
        co, no = SEAMS[seam]
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=co, plane_no=no,
                               clear_inner=side > 0, clear_outer=side < 0)
    pts = [tuple(v.co) for v in bm.verts]
    bm.free()
    return pts


def slide(seam):
    """The way a hanging seam's piece goes: off its seam, along the slant it hangs from."""
    a, n = Vector(SEAMS["A"][1]).normalized(), Vector(SEAMS[seam][1]).normalized()
    return (n - n.dot(a) * a).normalized()


class Shard:
    """The shard in a scene of its own: five pieces, a grade's buds, and the core that shows where it opens."""

    def __init__(self, grade="Standard"):
        self.scene = scene = bl.reset_scene()
        scene.world = bpy.data.worlds.new("Void")
        clay = bpy.data.materials.new("Clay")
        clay.diffuse_color = GREY
        self.root = bpy.data.objects.new("Shard", None)
        scene.collection.objects.link(self.root)
        self.pieces, self.away = {}, {}
        for name, sides in PIECES:
            obj = bl.object_from_bmesh(name, hull(piece_points(sides)), clay)
            bl.bevel(obj, 0.022, segments=1, angle=12.0)
            obj.parent, obj.color = self.root, (0, 0, 0, 1)
            middle = sum((Vector(v.co) for v in obj.data.vertices), Vector()) / len(obj.data.vertices)
            self.pieces[name], self.away[name] = obj, Vector((middle.x, middle.y * 0.4, middle.z)).normalized()
        for host, scale, place, lean in BUDS[grade]:
            bud = bl.object_from_bmesh(f"Bud{len(self.pieces)}", hull(body_points(scale)), clay)
            bl.bevel(bud, 0.016, segments=1, angle=12.0)
            bud.parent, bud.color = self.pieces[host], (0, 0, 0, 1)
            bud.location, bud.rotation_euler = place, (0.0, math.radians(lean), math.radians(18.0))
        self.core = bl.object_from_bmesh("Core", hull(body_points(0.93)), clay)
        self.core.parent, self.core.color = self.root, (1, 1, 1, 1)
        self.cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
        scene.collection.objects.link(self.cam)
        scene.camera, self.cam.data.type, self.cam.data.clip_end = self.cam, "ORTHO", 200

    def pose(self, gaps=(0, 0, 0, 0), fly=0.0, spin=0.0, at=(0.0, 0.0), scale=(1.0, 1.0), core=1.0, turn=0.0):
        """Opens each seam by its gap (A, B, C, D), sends the pieces out by `fly` units, each turning as it goes."""
        g = dict(zip("ABCD", gaps))
        a = Vector(SEAMS["A"][1]).normalized()
        for i, (name, sides) in enumerate(PIECES):
            move = a * sides["A"] * g["A"] / 2
            for seam, (who, way) in LOOSE.items():
                if who == name:
                    move += slide(seam) * way * g[seam]
            reach = (0.75, 1.0, 1.25, 0.85, 1.1)[i]
            self.pieces[name].location = move + self.away[name] * fly * reach
            self.pieces[name].rotation_euler = Euler(((0.5 + i) * spin * 0.6, (i - 2) * spin * 0.8, (2 - i) * spin * 0.3))
        self.root.location = (at[0], 0.0, at[1])
        self.root.scale = (scale[0], scale[0], scale[1])
        self.root.rotation_euler = (0.0, 0.0, turn)
        self.core.scale = (core,) * 3

    def shoot(self, out: Path, size, span, azimuth=14.0, elevation=6.0, centre=(0.0, 0.0, 0.05)):
        """Two pictures from one camera: the clay, and the leak (white where the core shows through)."""
        scene, cam = self.scene, self.cam
        cam.data.ortho_scale = span
        a, e = math.radians(azimuth), math.radians(elevation)
        offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e))) * 40
        cam.location = Vector(centre) + offset
        cam.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()
        shots = []
        for flat in (False, True):
            rs.workbench(scene, size[0], size[1], flat=flat)
            scene.display.shading.color_type = "OBJECT" if flat else "MATERIAL"
            self.core.hide_render = not flat
            scene.render.filepath = str(out / "_shard.png")
            bpy.ops.render.render(write_still=True)
            shots.append(rs.load(out / "_shard.png"))
        (out / "_shard.png").unlink()
        return shots[0], shots[1][..., 0] * shots[1][..., 3]


# --- light ------------------------------------------------------------------------------------------------------------

def set_scale(k):
    """Pixels a point, here and in the kit's drawing."""
    global K
    K = ui.K = k


def smooth(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def back(u):
    u = min(1.0, max(0.0, u)) - 1.0
    return 1.0 + u * u * (2.70158 * u + 1.70158)


def snap(tau):
    """A seam opening: past its width at once, then settled."""
    if tau < 0:
        return 0.0
    return 1.35 * tau / 0.03 if tau < 0.03 else 1.0 + 0.35 * math.exp(-(tau - 0.03) / 0.05)


def add(px, colour, a):
    """Light over a picture: it brightens and never darkens."""
    px[..., :3] = 1.0 - (1.0 - px[..., :3]) * (1.0 - np.clip(a, 0, 1)[..., None] * np.asarray(colour, dtype=np.float32))


def blur(a, r):
    """Three box passes: close to a Gaussian about r pixels wide."""
    r = int(round(r))
    if r < 1:
        return a
    out = a.astype(np.float32)
    for _ in range(3):
        for axis in (0, 1):
            n = out.shape[axis]
            first, last = np.take(out, [0], axis=axis), np.take(out, [n - 1], axis=axis)
            pad = np.concatenate([np.repeat(first, r + 1, axis=axis), out, np.repeat(last, r, axis=axis)], axis=axis)
            total = np.cumsum(pad, axis=axis, dtype=np.float64)
            out = ((np.take(total, range(2 * r + 1, n + 2 * r + 1), axis=axis) - np.take(total, range(0, n), axis=axis))
                   / (2 * r + 1)).astype(np.float32)
    return out


def soft(a, r, f=4):
    """A wide blur, made small and brought back."""
    h, w = a.shape
    small = a[:h - h % f, :w - w % f].reshape(h // f, f, w // f, f).mean(axis=(1, 3))
    big = np.repeat(np.repeat(blur(small, r / f), f, axis=0), f, axis=1)
    out = np.zeros_like(a, dtype=np.float32)
    out[:big.shape[0], :big.shape[1]] = big
    return blur(out, 2)


def beams(a, cx, cy, reach=1.6, steps=22, f=4):
    """Light thrown out of a leak, away from a point: the leak drawn again and again, each time larger."""
    h, w = a.shape
    small = a[:h - h % f, :w - w % f].reshape(h // f, f, w // f, f).mean(axis=(1, 3))
    yy, xx = np.mgrid[0:small.shape[0], 0:small.shape[1]].astype(np.float32)
    out = np.zeros_like(small)
    for i in range(1, steps + 1):
        s = 1.0 + reach * i / steps
        ys = np.clip(np.rint(cy / f + (yy - cy / f) / s), 0, small.shape[0] - 1).astype(np.intp)
        xs = np.clip(np.rint(cx / f + (xx - cx / f) / s), 0, small.shape[1] - 1).astype(np.intp)
        out += small[ys, xs] * (1.0 - i / (steps + 1)) ** 1.5
    big = np.repeat(np.repeat(blur(out / steps * 4.0, 1), f, axis=0), f, axis=1)
    full = np.zeros_like(a)
    full[:big.shape[0], :big.shape[1]] = big
    return full


def rays(x, y, cx, cy, count, turn, reach):
    """Bars of light from a point, uneven in width and strength, the same every frame but for their turn."""
    angle, far = np.arctan2(y - cy, x - cx), np.hypot(x - cx, y - cy)
    rng, out = np.random.default_rng(5), np.zeros(x.shape, dtype=np.float32)
    for i in range(count):
        centre = turn + 2 * math.pi * (i + rng.uniform(-0.28, 0.28)) / count
        width, strength = rng.uniform(0.03, 0.085), rng.uniform(0.45, 1.0)
        d = np.abs((angle - centre + math.pi) % (2 * math.pi) - math.pi)
        out = np.maximum(out, np.clip(1.0 - d / width, 0, 1) * strength)
    return out * np.exp(-far / reach) * np.clip(far / 40.0, 0, 1)


# --- the rarities -----------------------------------------------------------------------------------------------------

SHARD_LIGHT = "#C9B8FF"  # the shard's own light: pale violet, the same in every shard, before it tells anything
# The director, 2026-11-13: "i believe uncommon should be green, rare should be blue, epic should be purple". The kit's
# ladder (ui_sheet.RARITIES) was a shape and a light, never a hue; the reveal's block-in takes the director's hues on the
# same shapes. The kit's frames aren't changed here.
HUES = {"Uncommon": "#7CF0A0", "Rare": "#6FB6FF", "Epic": "#D29CFF", "Legendary": "#FFD777", "Mythical": "#FF2848"}
RARITIES = {name: dict(r) for name, r in ui.RARITIES.items()}
RARITIES["Uncommon"].update(metal=("#D2FFE0", "#4FBF7A"))
RARITIES["Rare"].update(metal=("#DDEEFF", "#4C8FE0"), glow=("#6FB6FF", 6.0, 0.6))
RARITIES["Epic"].update(metal=("#F3E2FF", "#9A5BE8"), glow=("#C98CFF", 10.0, 0.8))
LIGHT = {  # a rarity's light: its colour, how strong, how far the window glows (points), its rays, its core
    "Common": dict(colour="#A9AFBD", level=0.42, halo=10.0, rays=0, core=0.0),
    "Uncommon": dict(colour=HUES["Uncommon"], level=0.6, halo=16.0, rays=0, core=0.15),
    "Rare": dict(colour=HUES["Rare"], level=0.76, halo=30.0, rays=0, core=0.35),
    "Epic": dict(colour=HUES["Epic"], level=0.9, halo=44.0, rays=7, core=0.55),
    "Legendary": dict(colour="#FFD777", level=1.0, halo=56.0, rays=11, core=0.75),
    "Mythical": dict(colour="#FF2848", level=1.0, halo=60.0, rays=14, core=0.85, ray="#FFF1F2"),  # its rays are white-hot, never red bars
}
SHARD = (0.03, SHARD_LIGHT, 0.4, 1.0)
CLIMB = ((0.30, HUES["Uncommon"], 0.5, 1.2), (0.48, HUES["Rare"], 0.6, 1.45), (0.66, HUES["Epic"], 0.72, 1.7),
         (0.84, HUES["Legendary"], 0.92, 2.3), (1.25, HUES["Mythical"], 1.0, 2.8))  # the leak climbs the ladder to its own rung
PLANS = {  # seconds from the tap. Drawn: Common and Legendary. The other four are the same ladder, proposed.
    "Common": dict(grade="Standard", name="ROOK", cracks=(0.03, 0.14, 0.25, 0.34), steps=(SHARD,),
                   breath=None, split=0.55, end=2.15, reach=3.4),
    "Uncommon": dict(grade="Standard", name="SABLE", cracks=(0.03, 0.14, 0.25, 0.34), steps=(SHARD,) + CLIMB[:1],
                     breath=None, split=0.6, end=2.2, reach=4.0),
    "Rare": dict(grade="Enriched", name="LYRIC", cracks=(0.03, 0.14, 0.25, 0.34), steps=(SHARD,) + CLIMB[:2],
                 breath=None, split=0.85, end=2.5, reach=5.5),
    "Epic": dict(grade="Enriched", name="HALCYON", cracks=(0.03, 0.14, 0.25, 0.34), steps=(SHARD,) + CLIMB[:3],
                 breath=(0.85, 1.05), split=1.05, end=2.9, reach=8.0),
    "Legendary": dict(grade="Prismatic", name="STELLANE", cracks=(0.03, 0.14, 0.25, 0.34), steps=(SHARD,) + CLIMB[:4],
                      breath=(1.05, 1.3), split=1.3, end=3.4, reach=11.0),
    "Mythical": dict(grade="Prismatic", name="UMBRIEL", cracks=(0.03, 0.14, 0.25, 0.34), steps=(SHARD,) + CLIMB,
                     breath=(1.5, 1.8), split=1.8, end=4.0, reach=11.0),
}
BIG = (240.0, 288.0)  # the larger frame's opening: the 80 by 96 one, three times


def big_outline(cx, top, r, sx=1.0, sy=1.0):
    """The larger frame's cut. The 80 point frame three times over would be a slab: here the corner cuts grow by two,
    the crest's points by three in height and 2.4 in width, the wings by 2.5, so the points are what grows."""
    w, h = BIG[0] * sx, BIG[1] * sy
    x0, x1, y0, y1 = cx - w / 2, cx + w / 2, top + BIG[1] * (1 - sy) / 2, top + BIG[1] * (1 + sy) / 2
    tl, tr, br, bl_ = (v * 2.0 * min(sx, 1.0) for v in r["cut"])
    n, my = r.get("wing", 0) * 2.5 * sx, (y0 + y1) / 2
    pts = [(x0, y0 + tl), (x0 + tl, y0)] if tl else [(x0, y0)]
    for f, hw, hh in r.get("crest", ()):
        pts += [(x0 + w * f - hw * 2.4 * sx, y0), (x0 + w * f, y0 - hh * 3.0 * sy), (x0 + w * f + hw * 2.4 * sx, y0)]
    pts += [(x1 - tr, y0), (x1, y0 + tr)] if tr else [(x1, y0)]
    if n:
        pts += [(x1, my - n * 1.3), (x1 + n, my), (x1, my + n * 1.3)]
    pts += [(x1, y1 - br), (x1 - br, y1)] if br else [(x1, y1)]
    for f, hw, hh in sorted(r.get("base", ()), reverse=True):
        pts += [(x0 + w * f + hw * 2.4 * sx, y1), (x0 + w * f, y1 + hh * 2.6 * sy), (x0 + w * f - hw * 2.4 * sx, y1)]
    pts += [(x0 + bl_, y1), (x0, y1 - bl_)] if bl_ else [(x0, y1)]
    if n:
        pts += [(x0, my + n * 1.3), (x0 - n, my), (x0, my - n * 1.3)]
    return pts


def big_frame(t, d, cx, top, rarity, show=1.0):
    """The larger frame's metal on its window's outline `d`: thinner for its size than the small one, twice lined
    where the ladder asks, with the splinters its cuts threw off."""
    r = RARITIES[rarity]
    metal = t.ramp(r["metal"][0], r["metal"][1], (t.y - top) / BIG[1])
    width = 2.0 if rarity == "Common" else r["stroke"] * 1.45
    t.line(d - width * 0.5, width, metal, show)
    if r.get("inner"):
        t.line(d + width * 0.5 + 3.0, 1.2, metal, 0.8 * show)
    if r.get("hot"):
        t.line(d - width * 0.1, 1.1, WHITE, 0.9 * show)
    x0, x1, y0, y1 = cx - BIG[0] / 2, cx + BIG[0] / 2, top, top + BIG[1]
    for i in range(r.get("shards", 0)):
        o, s = 9.0 + i * 8.0, 10.0 - i * 2.0
        for px, py, sx, sy in ((x1, y1, 1, 1), (x0, y0, -1, -1))[:1 + (i > 0)]:
            ax, ay = px + sx * o * 0.7, py + sy * o * 0.7
            tri = t.poly([(ax + sx * s, ay - sy * s * 0.2), (ax - sx * s * 0.2, ay + sy * s), (ax + sx * s * 0.75, ay + sy * s * 0.75)])
            t.glow(tri, 4.0, WHITE, 0.3 * show)
            t.paint(tri, c(r["splinter"]) if "splinter" in r else metal, show)


# --- the fighter ------------------------------------------------------------------------------------------------------

def shoot_figure(out: Path):
    """Rook through his Reveal, every other frame, from the clip's own camera, on nothing."""
    folder = out / "figure"
    folder.mkdir(exist_ok=True)
    scene, rig, costume, undress, feet = rc.build()
    take = rc.Take(rig, feet, "Reveal", 0)
    rc.CLIPS["Reveal"](take)
    rc.ground(rig, feet, [take])
    bpy.data.objects["Floor"].hide_render = True
    r = scene.render
    r.resolution_x, r.resolution_y, r.resolution_percentage = TILE[0] * K, TILE[1] * K, 100
    r.film_transparent, r.image_settings.file_format, r.image_settings.color_mode = True, "PNG", "RGBA"
    scene.display.render_aa = "16"
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera, cam.data.type, cam.data.clip_end = cam, "ORTHO", 200
    cam.data.ortho_scale = TILE[1] / STUD
    a, e = math.radians(180.0 - CAMERA[0]), math.radians(CAMERA[1])  # the model faces +Y; its right is +X
    offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e))) * 40
    cam.location = Vector((0.0, 0.0, (FLOOR - H / 2) / STUD)) + offset  # his soles on the floor's row
    cam.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()
    for f in range(0, take.end + 1, 2):
        scene.frame_set(take.start + f)
        scene.render.filepath = str(folder / f"{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print(f"wrote {folder}: {take.end // 2 + 1} frames")


class Figure:
    """The fighter's frames, read as they're asked for."""

    def __init__(self, out: Path):
        self.folder, self.kept = out / "figure", {}
        if not (self.folder / "000.png").exists():
            raise SystemExit(f"No frames in {self.folder}: run the figure mode first")
        fire = self.at(ACCENT)
        ys, xs = np.nonzero(fire[..., 3] > 0.5)
        top = ys.min()
        self.accent = (float(xs[ys == top].mean()), float(top))  # the ram's head as it fires: where the colours start

    def at(self, seconds):
        f = int(min(CLIP * FPS, max(0, round(seconds * FPS / 2) * 2)))
        if f not in self.kept:
            if len(self.kept) > 6:
                self.kept.clear()
            shot = rs.load(self.folder / f"{f:03d}.png")  # shot at 2 pixels a point
            self.kept[f] = shot if K == 2 else rs.shrink(shot, K / 2)
        return self.kept[f]


# --- one frame --------------------------------------------------------------------------------------------------------

def name_sprite(out, text, size, colour, shear=0.0, space=1.0):
    item = dict(x=20.0, y=20.0, size=size, text=text, colour=colour, align="LEFT", layer="name", shear=shear, bold=0.0, space=space)
    layer = ui.text_layers(1600, round((size + 40) * K), [item])["name"]
    return rs.trim(layer)


class Stage:
    """Everything a frame is made of, kept between frames."""

    def __init__(self, out: Path, rarity, layout="A"):
        self.out, self.rarity, self.layout = out, rarity, layout
        self.plan, self.light, self.r = PLANS[rarity], LIGHT[rarity], RARITIES[rarity]
        big = 1.45
        self.names = (name_sprite(out, self.plan["name"], 30 * big, VIOLET["text"], space=1.12) if layout == "A" else
                      name_sprite(out, self.plan["name"], 58 * big, VIOLET["text"], shear=SLANT, space=1.04))
        self.big = big
        self.figure = Figure(out)
        self.shard = Shard(self.plan["grade"])
        sheet = ui.Sheet(W, H, VIOLET["panel"][1])
        self.t = sheet.tile(0, 0, W, H)
        t = self.t
        far = np.hypot((t.x - W / 2) / (W * 0.62), (t.y - H * 0.52) / (H * 0.8))
        room = t.ramp(VIOLET["ground"], VIOLET["panel"][1], far * 1.15)
        self.room = t.ramp(room, VIOLET["channel"], (far - 0.75) * 1.6)
        self.windows = {}

    def window(self, cx, sx=1.0, sy=1.0):
        key = (round(cx), round(sx, 3), round(sy, 3))
        if key not in self.windows:
            if len(self.windows) > 3:
                self.windows.clear()
            self.windows[key] = self.t.poly(big_outline(cx, 46.0, self.r, sx, sy))
        return self.windows[key]

    def glow_at(self, t_):
        """The light's colour and strength at a time: the leak's steps, the breath, then the rarity's own."""
        plan, colour, level = self.plan, c(SHARD_LIGHT), 0.0
        for when, code, lv, _ in plan["steps"]:
            if t_ >= when:
                w = smooth((t_ - when) / 0.06)
                colour, level = colour * (1 - w) + c(code) * w, level * (1 - w) + lv * w
        if plan["breath"] and t_ >= plan["breath"][0]:
            level *= 1.0 - 0.8 * smooth((t_ - plan["breath"][0]) / (plan["breath"][1] - plan["breath"][0]) * 1.6)
        if t_ >= plan["split"]:
            colour, level = c(self.light["colour"]), self.light["level"]
        return colour, level

    def shard_pose(self, t_):
        plan = self.plan
        widen = 1.0
        for when, _, _, wide in plan["steps"]:
            if t_ >= when:
                widen = max(widen, 1.0 + (wide - 1.0) * smooth((t_ - when) / 0.08))
        gaps = [0.045 * snap(t_ - t0) * widen for t0 in plan["cracks"]]
        _, level = self.glow_at(t_)
        shake = 0.0 if t_ < 0 else 0.006 + 0.022 * level * widen / 2.0
        at = [math.sin(t_ * 173.0) * shake, 0.03 * math.sin(t_ * 3.1) + math.sin(t_ * 211.0 + 1.0) * shake]
        tap = math.exp(-t_ / 0.035) if t_ >= 0 else 0.0
        sx, sz = 1.0 + 0.07 * tap, 1.0 - 0.07 * tap
        rise = 0.25 * smooth((t_ - 0.4) / 0.6) if len(plan["steps"]) > 1 else 0.0
        swell = 1.0 + 0.05 * smooth((t_ - (plan["split"] - 0.15)) / 0.15)
        if plan["breath"]:
            b0, b1 = plan["breath"]
            swell = 1.0 + 0.06 * smooth((t_ - 0.4) / 0.6) - 0.16 * smooth((t_ - b0) / (b1 - b0) * 1.4)
            if t_ >= b0:
                at[0], at[1] = at[0] * 0.2, at[1] * 0.2 + 0.03
        tau = t_ - plan["split"]
        fly = plan["reach"] * (1.0 - math.exp(-tau / 0.13)) if tau > 0 else 0.0
        core = 1.0 if tau <= 0 else max(0.0, 1.0 - tau / 0.09)
        return dict(gaps=gaps, fly=fly, spin=max(0.0, tau) * 5.0 + fly * 0.22, at=(at[0], at[1] + rise), scale=(sx * swell, sz * swell),
                    core=core)

    def frame(self, t_):
        t, plan, light, r = self.t, self.plan, self.light, self.r
        px = t.px
        px[..., :3], px[..., 3] = self.room, 1.0
        colour, level = self.glow_at(t_)
        split, tau = plan["split"], t_ - plan["split"]
        name_at = split + HOLD + 0.05
        cx = W / 2
        if self.layout == "B":  # he steps right as he opens up, so nothing but the name moves when it lands
            cx += (STAGE["B"] - W / 2) * smooth((t_ - split - 0.4) / 0.3)
        cy = H / 2 - 0.05 * UNIT
        far = np.hypot(t.x - cx, t.y - cy)
        ray_colour = c(light.get("ray", light["colour"]))
        if level > 0:  # the room takes the light
            add(px, colour, 0.34 * level * np.exp(-(far / 300.0) ** 2))
        for when, _, lv, wide in plan["steps"][1:]:  # a ring off each step up
            age = t_ - when
            if 0 <= age < 0.3:
                add(px, colour, 0.5 * lv * (1 - age / 0.3) * np.exp(-((far - 30.0 - age * 900.0) / (10.0 + age * 60.0)) ** 2))
        if tau >= 0:  # the window: the larger frame's own shape, opening from the slant's slit
            opened = back(tau / 0.16)
            d = self.window(cx, 0.03 + 0.97 * opened, 0.72 + 0.28 * smooth(tau / 0.12))
            if light["rays"]:
                add(px, ray_colour, 0.5 * opened * rays(t.x, t.y, cx, 46.0 + BIG[1] * 0.45, light["rays"], 0.12 * tau, 250.0))
            t.glow(d, light["halo"], colour, min(1.0, 0.25 + level * 0.7))
            inside = np.clip(0.5 - d * K, 0, 1)
            lift = np.exp(-(np.hypot((t.x - cx) / 120.0, (t.y - (46.0 + BIG[1] * 0.5)) / 150.0)) ** 2)
            fill = t.ramp(colour * 0.12, colour * (0.55 + 0.45 * level), lift)
            fill = fill + (WHITE - fill) * (light["core"] * lift ** 2)[..., None]
            ui.over(px, fill, inside * (0.55 + 0.45 * level))
            add(px, colour, 0.45 * level * np.exp(-((t.y - FLOOR) / 5.0) ** 2) * np.exp(-((t.x - cx) / 170.0) ** 2))  # the floor it stands on
            framed = smooth((tau - 0.08) / 0.12)  # the metal comes with the window: the rarity reads before the name
            if framed > 0:
                big_frame(t, self.window(cx), cx, 46.0, self.rarity, framed)
        flash = 0.0
        if 0 <= tau < 0.12:
            flash = (1.0 - tau / 0.12) ** 2 * (0.2 + 0.7 * light["level"])
        for when, _, lv, _ in plan["steps"][1:]:
            if 0 <= t_ - when < 0.08:
                flash = max(flash, 0.35 * lv * (1 - (t_ - when) / 0.08))
        if tau >= 0:  # the fighter: dark first, then his colours from where his clip strikes
            shot = self.figure.at(tau)
            alpha = shot[..., 3]
            flood = (tau - ACCENT) / 0.2
            ax, ay = self.figure.accent
            yy, xx = np.mgrid[0:shot.shape[0], 0:shot.shape[1]].astype(np.float32)
            reach = np.hypot(xx - ax, yy - ay)
            edge = flood * 500.0 * K
            lit = np.clip((edge - reach) / (45.0 * K), 0, 1) if flood > 0 else np.zeros_like(alpha)
            body = shot.copy()
            dark = c(VIOLET["channel"])
            body[..., :3] = dark + (shot[..., :3] - dark) * lit[..., None]
            rim = np.clip((alpha - blur(alpha, 2 * K)) * 2.6, 0, 1)  # a band just inside his outline: the glow behind him wraps it
            rim = rim * (1 - lit) * min(1.0, 0.45 + 0.55 * level) * back(tau / 0.16)
            body[..., :3] = body[..., :3] + (colour - body[..., :3]) * (rim * 0.8)[..., None]
            if 0 < flood < 1.3:  # the line the colours come in behind
                band = np.exp(-((reach - edge + 22.5 * K) / (25.0 * K)) ** 2) * alpha * (1.0 - flood / 1.3) * 0.7
                body[..., :3] = body[..., :3] + (colour + (WHITE - colour) * 0.6 - body[..., :3]) * band[..., None]
            body[..., 3] *= smooth(tau / 0.06)
            x0 = round((cx - TILE[0] / 2) * K)
            rs.paste(px, body, x0, 0)
            if 0 <= tau - ACCENT < 0.25 and light["rays"]:  # a rare one's strike throws its own light up
                age = (tau - ACCENT) / 0.25
                column = np.exp(-((t.x - (x0 + ax) / K) / (7.0 + 30.0 * age)) ** 2) * np.clip(1.2 - (t.y - ay / K) / 60.0, 0, 1)
                add(px, ray_colour, 0.8 * (1 - age) * column)
                flash = max(flash, 0.3 * (1 - age) ** 2)
        if t_ < split + 0.7:  # the shard, and what leaks from it
            self.shard.pose(**self.shard_pose(t_))
            clay, leak = self.shard.shoot(self.out, (W * K, H * K), W / UNIT, centre=(0.0, 0.0, 0.05))
            gone = 1.0 - smooth((tau - 0.22) / 0.3) if plan["reach"] < 6 else 1.0
            clay[..., 3] *= gone
            rs.paste(px, clay, 0, 0)
            if level > 0 and leak.max() > 0.01:
                leak = leak * min(1.0, level + 0.35)
                add(px, colour, soft(leak, 20 * K, f=2 * K) * 2.2 * level)
                if len(plan["steps"]) > 1 and t_ > plan["steps"][1][0]:
                    add(px, colour, beams(leak, cx * K, cy * K, reach=0.9 + 1.6 * level, f=2 * K) * 1.6 * level)
                add(px, colour, blur(leak, 2.5 * K) * 1.8)
                add(px, WHITE, blur(leak, K / 2) * (0.55 + 0.45 * level) if K > 1 else leak * 0.8 * (0.55 + 0.45 * level))
        if t_ >= name_at - 0.02:  # the name
            landed = min(1.0, (t_ - name_at + 0.02) / 0.09)
            size = 1.0 + (self.big - 1.0) * (1.0 - landed) ** 2
            sprite = rs.shrink(self.names, size / self.big)
            sprite[..., 3] *= smooth(landed * 2.0)
            metal = t.ramp(r["metal"][0], r["metal"][1], (t.y - 46.0) / BIG[1])
            if self.layout == "A":
                plate = t.poly(ui.cut_box(cx - 112.0, 316.0, cx + 112.0, 356.0, 9.0, 0.0, 9.0, 0.0))
                t.paint(plate, c(VIOLET["well"]), 0.94 * smooth(landed * 2.0))
                t.line(plate, 1.6, metal, smooth(landed * 2.0))
                rs.paste(px, sprite, round(cx * K - sprite.shape[1] / 2), round(336.0 * K - sprite.shape[0] / 2))
            else:
                left, base = 70.0, 214.0
                rs.paste(px, sprite, round(left * K), round(base * K - sprite.shape[0]))
                rule = t.poly([(left - 6.0, base + 12.0), (left + self.names.shape[1] / self.big / K + 22.0, base + 12.0),
                               (left + self.names.shape[1] / self.big / K + 16.0, base + 17.0), (left - 10.0, base + 17.0)])
                t.paint(rule, metal, smooth(landed * 2.0))
            if landed < 1.0:
                flash = max(flash, 0.22 * (1 - landed))
        if flash > 0:
            add(px, WHITE if tau >= 0 else colour * 0.5 + 0.5, flash * np.exp(-(far / (200.0 + 340.0 * light["level"])) ** 2))
        return px.copy()


# --- the sheets -------------------------------------------------------------------------------------------------------

BEATS = {
    "Common": ((-0.1, "the shard waits"), (0.05, "the tap: the slant opens"), (0.3, "its lines, one by one"),
               (0.5, "it swells"), (0.56, "the split"), (0.68, "the window; he's folded small"),
               (1.05, "he opens up (skip from 1.0)"), (1.33, "the ram up"), (1.43, "it fires: the colours"),
               (1.52, "the colours in"), (1.6, "the name lands"), (2.15, "held")),
    "Legendary": ((-0.1, "the shard waits"), (0.05, "the tap: the slant opens"), (0.36, "green: past Common"),
                  (0.54, "blue"), (0.72, "purple"), (0.98, "gold (skip from 1.0)"), (1.24, "the breath: dark, drawn in"),
                  (1.32, "the split"), (1.46, "the window: three points"), (2.18, "it fires: the colours"),
                  (2.42, "the name lands"), (3.3, "held")),
}


def finish(sheet, path):
    layers = ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items)
    for layer in layers.values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, path)


def beats(out: Path, rarity, layout, first, last):
    """Beats first to last - 1, each at 2 pixels a point, into beats/."""
    stage = Stage(out, rarity, layout)
    (out / "beats").mkdir(exist_ok=True)
    for i, (when, _) in list(enumerate(BEATS[rarity]))[first:last]:
        rs.save(stage.frame(when), out / "beats" / f"{rarity}_{layout}_{i:02d}.png")


def strip(out: Path, rarity, layout):
    """The beats, put together from beats/."""
    tiles = [rs.shrink(rs.load(out / "beats" / f"{rarity}_{layout}_{i:02d}.png"), 0.5) for i in range(len(BEATS[rarity]))]
    cols, gap, top = 4, 8.0, 64.0
    tw, th = W / 2, H / 2
    rows = math.ceil(len(tiles) / cols)
    sheet = ui.Sheet(20 * 2 + cols * tw + (cols - 1) * gap, top + rows * (th + 26.0) + 8, "#1B1D24")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    plan = PLANS[rarity]
    t.text(20, 12, 15, f"The reveal, block-in: {rarity}, from a {plan['grade']} shard. Layout {layout}.", "#F3EFE6")
    t.text(20, 36, 9.5, f"AR3 section 4. The full-screen camera at 1 pixel a point, on Void Violet. Seconds from the tap. The split at "
           f"{plan['split']:.2f}, the colours at {plan['split'] + ACCENT:.2f}, the name at {plan['split'] + HOLD + 0.05:.2f}, the card after "
           f"{plan['end']:.2f}. Grey shard, Rook's model" + (" standing in for a Legendary" if rarity != "Common" else "") +
           ", Blender's face for the type.", "#C9CDD6")
    for i, tile in enumerate(tiles):
        row, col = divmod(i, cols)
        x, y = 20 + col * (tw + gap), top + row * (th + 26.0)
        rs.paste(sheet.px, tile, round(x * K), round(y * K))
        when, label = BEATS[rarity][i]
        t.text(x, y + th + 5, 9.5, f"{when:.2f} s", "#FFE266")
        t.text(x + 44, y + th + 5, 9.5, label, "#E6E8EE")
    finish(sheet, out / f"reveal_strip_{rarity}_{layout}.png")


MOVIE = (-0.3, 0.4)  # seconds before the tap, and after the card would come


def movie_length(rarity):
    return round((PLANS[rarity]["end"] + MOVIE[1] - MOVIE[0]) * 30) + 1


def movie(out: Path, rarity, layout, first, last):
    """Movie frames first to last - 1, at 30 a second and 1 pixel a point, into movie_<rarity>_<layout>/."""
    set_scale(1)
    stage = Stage(out, rarity, layout)
    folder = out / f"movie_{rarity}_{layout}"
    folder.mkdir(exist_ok=True)
    for i in range(first, min(last, movie_length(rarity))):
        rs.save(stage.frame(MOVIE[0] + i / 30), folder / f"{i:04d}.png")


def assemble(out: Path, rarity, layout):
    folder = out / f"movie_{rarity}_{layout}"
    missing = [i for i in range(movie_length(rarity)) if not (folder / f"{i:04d}.png").exists()]
    if missing:
        raise SystemExit(f"{len(missing)} frames missing in {folder}, the first {missing[0]}")
    frames_to_movie.assemble(folder, out / f"reveal_{rarity}_{layout}.mp4", 30)


READ = 0.74  # seconds after the split: the silhouette's beat, the ram going up, before any colour or name


def read(out: Path):
    """The six at the same beat, before any colour or name: what tells them apart is the light and the window's shape.
    Put together from the frame mode's pictures at the split + READ."""
    tiles = [rs.shrink(rs.load(out / f"frame_{rarity}_A_{PLANS[rarity]['split'] + READ:.2f}.png"), 0.5) for rarity in ui.RARITIES]
    tw, th, gap = W / 2, H / 2, 8.0
    cuts = frame_cuts(out)
    sheet = ui.Sheet(40 + 3 * tw + 2 * gap, 64 + 2 * (th + 24) + 30 + th / 2 + 24 + 30 + cuts.shape[0] / K + 40, "#1B1D24")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal, block-in: the rarity's read before the name", "#F3EFE6")
    t.text(20, 36, 9.5, "The six at the silhouette's beat, 0.74 s after the split, the ram going up: no colour on him yet and no name. "
           "The light's hue (the director's: green, blue, purple), its strength and the window's shape tell it. Under them, in grey.", "#C9CDD6")
    for i, (rarity, tile) in enumerate(zip(ui.RARITIES, tiles)):
        row, col = divmod(i, 3)
        x, y = 20 + col * (tw + gap), 64 + row * (th + 24)
        rs.paste(sheet.px, tile, round(x * K), round(y * K))
        t.text(x, y + th + 5, 9.5, rarity, "#E6E8EE")
        small = rs.grey(rs.shrink(tile, 0.5))
        rs.paste(sheet.px, small, round((20 + i * (tw / 2 + 4)) * K), round((64 + 2 * (th + 24) + 20) * K))
    t.text(20, 64 + 2 * (th + 24) + 4, 9.5, "In grey, 211 points wide: the order still reads left to right.", "#C9CDD6")
    y = 64 + 2 * (th + 24) + 30 + th / 2 + 24
    t.text(20, y + 4, 9.5, "The larger frame's cut, at half size: 240 by 288 points in the reveal. The thin blue line is the 80 point frame's outline "
           "drawn 240 wide. Against the small frame, the corner cuts are twice, the points three times as tall and 2.4 as wide, the wings 2.5, the stroke 1.45.", "#C9CDD6")
    rs.paste(sheet.px, cuts, round(20 * K), round((y + 26) * K))
    for i, rarity in enumerate(ui.RARITIES):
        t.text(20 + i * CUT_STEP / 2 + 8, y + 26 + cuts.shape[0] / K - 14, 9, rarity, "#E6E8EE")
    finish(sheet, out / "reveal_rarity.png")


CUT_STEP = 420.0  # points between the cuts on their own sheet, before it's halved


def frame_cuts(out: Path):
    """The six larger frames, flat: the window's dark, its metal, and under it the small frame three times over."""
    sheet = ui.Sheet(6 * CUT_STEP, 480, "#1B1D24")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    for i, rarity in enumerate(ui.RARITIES):
        r, cx, top = RARITIES[rarity], i * CUT_STEP + CUT_STEP / 2, 90.0
        d = t.poly(big_outline(cx, top, r))
        if "glow" in r:
            t.glow(d, r["glow"][1] * 2.2, c(r["glow"][0]), r["glow"][2] * 0.6)
        t.paint(d, c(VIOLET["well"]), 0.92)
        big_frame(t, d, cx, top, rarity)
        naive = t.poly(ui.outline(cx - BIG[0] / 2, top, cx + BIG[0] / 2, top + BIG[1], r))
        t.line(naive + 1.0, 1.4, c("#8FD3FF"), 0.8)
    return rs.shrink(sheet.px, 0.5)


def variants(out: Path):
    """The two layouts at the name's beat and held, for both rarities drawn: made by the frame mode, put together here."""
    shots = []
    for rarity in ("Common", "Legendary"):
        name_at = PLANS[rarity]["split"] + HOLD + 0.05
        for layout in STAGE:
            for when in (name_at + 0.03, BEATS[rarity][-1][0]):
                shots.append((rarity, layout, when, rs.shrink(rs.load(out / f"frame_{rarity}_{layout}_{when:.2f}.png"), 0.5)))
    tw, th, gap = W / 2, H / 2, 8.0
    sheet = ui.Sheet(40 + 4 * tw + 3 * gap, 64 + 2 * (th + 26) + 8, "#1B1D24")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal, block-in: the two layouts for the name", "#F3EFE6")
    t.text(20, 36, 9.5, "A: he stays in the middle and the name lands on a plate across his shins. B: he steps right and the name "
           "lands large and slanted beside him. At 1 pixel a point, the name's beat and held.", "#C9CDD6")
    for i, (rarity, layout, when, tile) in enumerate(shots):
        row, col = divmod(i, 4)
        x, y = 20 + col * (tw + gap), 64 + row * (th + 26)
        rs.paste(sheet.px, tile, round(x * K), round(y * K))
        t.text(x, y + th + 5, 9.5, f"{rarity}, {layout}, {when:.2f} s", "#E6E8EE")
    finish(sheet, out / "reveal_variants.png")


GROUNDS = (("the reveal's room", VIOLET["panel"][1]), ("a dusk street", "#6C5F7C"))


def shard_sheet(out: Path):
    """The form: its three grades, the lines it parts on, in the round, and at the four sizes it's seen at."""
    shots = {}
    for grade in BUDS:
        shard = Shard(grade)
        shard.pose()
        shots[grade, "big"] = shard.shoot(out, (300 * K, 250 * K), 6.0)[0]
        shots[grade, "world"] = shard.shoot(out, (300 * K, 250 * K), 6.0, azimuth=24.0, elevation=20.0)[0]
        if grade == "Standard":
            for i, azimuth in enumerate((60.0, 104.0, 150.0, 194.0)):
                shots["turn", i] = shard.shoot(out, (150 * K, 250 * K), 5.0, azimuth=azimuth)[0]
            shard.pose(gaps=(0.07, 0.07, 0.07, 0.07))
            shots["lines"] = shard.shoot(out, (300 * K, 250 * K), 6.0)
            shard.pose(gaps=(0.07, 0.07, 0.07, 0.07), fly=0.34, spin=0.2, core=0.0, at=(0.0, -0.3))
            shots["parts"] = shard.shoot(out, (300 * K, 250 * K), 6.0)[0]
    sheet = ui.Sheet(1180, 760, "#1B1D24")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The Void Shard, block-in: one form, three grades, the lines it cracks along", "#F3EFE6")
    t.text(20, 36, 9.5, "AR3 section 4. Grey clay, no colour: a piece broken off something larger, its top the break, leaning on its foot, in "
           "five pieces on four seams. A grade is the same body with the spires grown beside it: none, one, two.", "#C9CDD6")
    for i, grade in enumerate(BUDS):
        x = 20 + i * 232
        tile = sheet.tile(x, 64, 224, 260)
        tile.paint(tile.poly(ui.cut_box(0, 0, 224, 260)), c(VIOLET["panel"][1]))
        rs.paste(sheet.px, shots[grade, "big"], round((x - 38) * K), round(69 * K))
        t.text(x + 8, 72, 10, grade, "#F3EFE6")
    x = 20 + 3 * 232
    tile = sheet.tile(x, 64, 224, 260)
    tile.paint(tile.poly(ui.cut_box(0, 0, 224, 260)), c(VIOLET["panel"][1]))
    clay, leak = shots["lines"]
    dim = clay.copy()
    dim[..., :3] *= 0.55
    rs.paste(sheet.px, dim, round((x - 38) * K), round(69 * K))
    region = sheet.px[round(69 * K):round(69 * K) + leak.shape[0], round((x - 38) * K):round((x - 38) * K) + leak.shape[1]]
    add(region, c(SHARD_LIGHT), soft(leak, 16) * 1.6)
    add(region, WHITE, blur(leak, 1))
    t.text(x + 8, 72, 10, "Its lines, lit: the order they open in", "#F3EFE6")
    for label, (lx, ly) in (("1", (180, 84)), ("2", (120, 30)), ("3", (168, 186)), ("4", (56, 196))):
        t.text(x + lx, 64 + ly, 11, label, "#FFE266")
    x = 20 + 4 * 232
    tile = sheet.tile(x, 64, 212, 260)
    tile.paint(tile.poly(ui.cut_box(0, 0, 212, 260)), c(VIOLET["panel"][1]))
    rs.paste(sheet.px, shots["parts"][:, 44 * K:-44 * K], round(x * K), round(69 * K))
    t.text(x + 8, 72, 10, "The five pieces, parted", "#F3EFE6")
    t.text(20, 338, 10, "In the round (Standard): a quarter turn at a time from its front", "#C9CDD6")
    for i in range(4):
        x = 20 + i * 120
        tile = sheet.tile(x, 356, 112, 150)
        tile.paint(tile.poly(ui.cut_box(0, 0, 112, 150)), c(VIOLET["panel"][1]))
        rs.paste(sheet.px, rs.shrink(shots["turn", i], 0.6), round((x + 11) * K), round(356 * K))
    t.text(520, 338, 10, "The four sizes, on the reveal's dark and on a dusk street's paving. Left to right in each: Standard, Enriched, Prismatic.",
           "#C9CDD6")
    sizes = (("the Breaker's chamber", 96.0, "big"), ("the bag", 40.0, "big"), ("the world's drop", 34.0, "world"))
    for j, (ground, code) in enumerate(GROUNDS):
        y = 356 + j * 192
        tile = sheet.tile(520, y, 640, 184)
        tile.paint(tile.poly(ui.cut_box(0, 0, 640, 184)), c(code))
        t.text(528, y + 6, 9, ground, "#F3EFE6" if j == 0 else "#17141F")
        x = 540.0
        for what, tall, view in sizes:
            for grade in BUDS:
                shot = rs.trim(shots[grade, view])
                small = rs.shrink(shot, tall * K / 450.0)
                rs.paste(sheet.px, small, round(x * K), round((y + 150) * K) - small.shape[0])
                x += small.shape[1] / K + (16 if tall > 50 else 12)
            t.text(x - 150 if tall > 50 else x - 104, y + 160, 8.5, f"{what}, {tall:.0f} pt", "#F3EFE6" if j == 0 else "#17141F")
            x += 30
    t.text(20, 520, 9.5, "The reveal shows it 225 points tall (the top row is that size). A chamber, the bag and the drop are drawn at 2 pixels a point,", "#C9CDD6")
    t.text(20, 536, 9.5, "the drop from the fight camera's height. At 34 points the grade is the count of spires: one, two, three.", "#C9CDD6")
    finish(sheet, out / "reveal_shard.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "shard"
    layout = next((a for a in args if a in STAGE), "A")
    rarity = next((a for a in args if a in PLANS), "Common")
    nums = [a for a in args[1:] if a.replace(".", "", 1).replace("-", "", 1).isdigit()]
    if mode == "shard":
        shard_sheet(out)
    elif mode == "figure":
        shoot_figure(out)
    elif mode == "beats":
        beats(out, rarity, layout, int(nums[0]) if nums else 0, int(nums[1]) if len(nums) > 1 else 99)
    elif mode == "strip":
        strip(out, rarity, layout)
    elif mode == "read":
        read(out)
    elif mode == "variants":
        variants(out)
    elif mode == "movie":
        movie(out, rarity, layout, int(nums[0]), int(nums[1]))
    elif mode == "assemble":
        assemble(out, rarity, layout)
    elif mode == "frame":
        stage = Stage(out, rarity, layout)
        for when in (float(a) for a in nums):
            rs.save(stage.frame(when), out / f"frame_{rarity}_{layout}_{when:.2f}.png")
    else:
        raise SystemExit(f"Unknown mode {mode}")


if __name__ == "__main__":
    main()
