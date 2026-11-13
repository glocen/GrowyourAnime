"""The Lamplighter's signature effect, drawn (AR7, section 6): A, the column, with research's fixes of 2026-11-13, and
its leap and taper from the final (AR8, "The leap and the final": Faber's, at research's verdict).
1. It leaps: its height comes in its first five frames, then foot and top climb away together on an ease-in, its light
   held until the climb is under way.
2. Narrow and tall, so the slam's pose and the lead's flash stay seen through 119 to 121, its share over the coil's.
3. The keeper's own shape, not the teardrop: lamplight widest at the foot, the paper lantern's ribs as bands of light
   climbing it, in Lantern Row's cyan and warm white.

blender.exe -b --factory-startup --python tools/blender/lamplighter_signature_art.py -- <out_dir>

The column is three Beams, as the engine draws them (handbook/visuals/vfx-engine-facts.md, "Beam"), standing where the
lantern lands:
- the shaft, Width1 = TAPER Width0 (widest at the foot), its picture wrapped (TextureMode Wrap): one period is one rib,
  so the ribs repeat up it every TextureLength, and TextureSpeed makes them climb. Its foot is faded by its Transparency.
- the tip on top of it, the shaft's width there, its picture stretched once: the spike, drawn in the picture, so its
  edges stay clean whatever the Beam's width (a Beam narrowed to nothing skews its picture across its two triangles).
- the halo behind both, from the foot to the point, wider, faint, tapered as the shaft: the light's glow, and on the
  slam, wider still, the slam's flash.
Pictures, straight alpha, the Beam's Color white:
- lamplighter_column.png, one period: the lantern's warm white heart, its cyan paper, then the deeper cyan at the
  sides, where it ends in a short fade: a bright interior with a darker saturated edge (docs/research/vfx-reference.md,
  rule 3). One rib across it, brighter, in the lantern's warm white, the ring's near half bowed down as a ring is seen
  from above, its far half fainter through the paper.
- lamplighter_column_tip.png: the spike, the same light drawn in to a needle, thinning toward its point.
- lamplighter_column_halo.png: the glow, cyan, faint, gone at its sides, faded in at the foot and out toward the top.
- lamplighter_glow.png: the lantern's light through the hold, a BillboardGui over the drum: a warm white heart, the cyan
  round it.
The trail down from over the hat is a third Beam with the tip's picture, pointed at its tail. The chips, a breath after
the peak, are small wedges of Neon, cyan and warm (no picture); the motes drawn into the lantern, thin cyan ones.

Drawn as the engine composes them: the clip shaded in Workbench, the effect laid over it per pixel from its own
pictures, hidden where the bodies stand in front of it (a pass per layer in a code colour gives what's seen of it, its
place on the picture from the camera's ray), with LightEmission between a normal blend and an add. The game's tone and
bloom aren't drawn. The keeper plays its delivered Signature clip on lamplighter_signature_fx's stage, from the same
cameras: the game's, the ring's, the flank's, a bright floor, at 64 px from each, and once in a dark colour.
Numbers are in the keeper's units (1.5 studs), and in studs where Faber's Config takes them.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lamplighter_clips as lc  # noqa: E402
import lamplighter_signature_fx as sig  # noqa: E402  (the stage, the clip, the cameras, the gathering's timing)
import lantern_row_kit as kit  # noqa: E402  (Lantern Row's swatches)
import pip_burst_fx as pf  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402
import rook_sheet as rs  # noqa: E402

S = sig.S
SLAM, WRENCH, HANG, LOOK, LIGHT = sig.SLAM, sig.WRENCH, sig.HANG, sig.LOOK, sig.LIGHT
CYAN, CYAN_EDGE = kit.SWATCHES["cyan"][:2]
WARM, WARM_DEEP = kit.SWATCHES["warm"][:2]
CORE = "#FFF3DC"   # the light's middle: the lantern's heart, white a breath toward the warm
HEART = "#FFF9EE"  # a rib's middle, brighter
DARK = "#262B3A"   # condition 7's dark colour, the shape alone

# --- the column, frame by frame (t: frames from the slam) ------------------------------------------------------------
WIDE = 4.0       # the shaft's width at its foot at its height (6 studs; the grey's belly was 7.6): the keeper's body clear
TOP = 9.0        # the shaft's length once it has leapt (13.5 studs); the spike over it
SPIKE = 0.95     # the spike's length over the column's width (never over WIDE's): long, so it reads as light, not a point
HALO = 1.4       # the glow round it: a third Beam this many times its width, from its foot to its point (1.9 until
# research's final of 2026-11-13: the shaft crisp with a soft edge, not a haze)
TAPER = 0.5      # the shaft's and the halo's width at their top, over their foot's (a Beam's Width1 over its Width0):
# widest at the foot; the tip, footed on the shaft's top, takes the width there
LEAP = tuple(v / S for v in (2.0, 7.5, 11.0, 12.6, 13.3, 13.5))  # the shaft's top as it leaps, from the slam to its
# height on LETGO (studs, over S)
WIDTHS = {0: 1.15, 1: 1.06, 2: 1.02}  # its width (over WIDE) as it leaps, narrowing to its height
FLASH = {0: 1.6, 1: 1.25}  # the slam's flash: the halo this much wider on the slam and the frame after
CHIPS, LETGO, END = 4, 5, 22  # the chips fly (122), the column at its height and its foot letting go (123), gone by 140
RISE, RISE_END, RISE_EASE = 20.0, 21, 2.2  # from LETGO, foot and top climb together on an ease-in, RISE (30 studs) by
# RISE_END (139)
CLEAR = {15: 0.08, 16: 0.18, 17: 0.32, 18: 0.48, 19: 0.64, 20: 0.8, 21: 0.93}  # its Transparency: its light held until
# the climb is under way (to 132), then gone by END
FOOT = 1.4       # the length over which the shaft's foot fades in (its Transparency), in the keeper's units
PERIOD = 1.75    # a rib to the next: the shaft's TextureLength, in the keeper's units
CLIMB = 7.0      # periods a second the ribs climb the shaft: its TextureSpeed
EMISSION = 0.7   # the Beams' LightEmission: light over the night street, its cyan edge still seen on a bright floor
BOW, RIB = 0.16, 0.1  # a rib's bow (its ring seen from a little above) and its half thickness, in periods
CHIP_EDGE, CHIP_SIZE = 0.45, 0.6
TRAIL_W = 2.2
GLOW_OUT = 1.5 * lc.LAMP_R  # how far toward the camera the lantern's glow is laid, past the drum's tilted ends
GLOW = 0.95      # the glow's quad: its half width over the block-in light's radius (sig.halo), through the hold and the
# fall: the light kept to the drum, its ribs seen through it, never a disc over the hat (the content check's condition 6)
FLARE = 1.3      # the same, from the wrench to the hang, the lantern high over the hat: the flare, eased back by 113
CODE = (1.0, 0.0, 1.0)
K = 4
PX = 256
FILES = {"column": "column", "tip": "column_tip", "halo": "column_halo", "glow": "glow"}
STRIP = sig.STRIP
HOLD = (60, 84, LOOK, 100, 104, WRENCH, HANG, 114, 116)  # the close-ups of the light by the hat, at 64 px
TIMES = range(0, END + 1)


def smooth(e0, e1, x):
    u = np.clip((x - e0) / (e1 - e0), 0, 1)
    return u * u * (3 - 2 * u)


def column_at(t):
    """The column on frame `t` after the slam: its foot, the shaft's top, its width and the spike's length, in the
    keeper's units; how opaque it is, and how far its ribs have climbed, in periods. None outside its life."""
    if not 0 <= t < END:
        return None
    tau = max(0, t - LETGO)
    foot = RISE * hx.clamp(tau / (RISE_END - LETGO)) ** RISE_EASE  # lets go and climbs away, faster and faster
    top = LEAP[t] if t < len(LEAP) else TOP + foot  # it leaps to its height, then climbs whole, foot and top together
    width = WIDE * WIDTHS.get(t, 1.0) * (1 - 0.45 * hx.clamp(tau / (END - LETGO)))  # and thins
    opaque = 1 - CLEAR.get(t, 0.0)
    return {"foot": foot, "top": top, "width": width, "spike": SPIKE * min(width, WIDE), "opaque": opaque,
            "scroll": CLIMB * t / 60}


def glow_at(f):
    """The lantern's light through the hold, from lamplighter_signature_fx.halo: its quad's width and height and how
    opaque it is; None outside the hold."""
    light = sig.halo(f)
    if not light:
        return None
    r, shade, tall = light
    if shade == "mid":
        opaque = 0.45 + 0.25 * pf.smooth((f - LIGHT) / (LOOK - LIGHT))
    else:
        opaque = 1.0 if f < HANG else 0.9
    over = FLARE + (GLOW - FLARE) * pf.smooth((f - HANG) / 3) if f >= WRENCH else GLOW
    w = 2 * r * over
    return w, w * tall, opaque


# --- the pictures ----------------------------------------------------------------------------------------------------

def light(x):
    """Across the light, x from -1 to 1, between the ribs: colour and alpha. The lantern's warm white heart, its cyan
    paper, the deeper cyan at the sides, then a short fade: straight sides. Between the ribs it's the light through
    the paper, a little see-through, so the ribs read brighter."""
    d = np.abs(x)
    core, cyan, edge = (np.array(rs.rgb(c)) for c in (CORE, CYAN, CYAN_EDGE))
    rgb = core + (cyan - core) * smooth(0.15, 0.58, d)[..., None]
    rgb = rgb + (edge - rgb) * smooth(0.55, 0.9, d)[..., None]
    side = 1 - smooth(0.82, 1.0, d)
    return rgb, (0.74 - 0.12 * smooth(0.2, 0.7, d)) * side, side


def halo_picture():
    """The glow round the column, stretched from its foot (the top row) to its point: Lantern Row's cyan, faint, gone
    at its sides, faded in at the foot and out toward the top, so it never stands as a box."""
    x, s = grid(PX, PX // 4)
    d = np.abs(x)
    cyan, edge = (np.array(rs.rgb(c)) for c in (CYAN, CYAN_EDGE))
    rgb = cyan + (edge - cyan) * smooth(0.3, 0.9, d)[..., None]
    alpha = 0.36 * (1 - smooth(0.0, 1.0, d)) ** 1.4 * smooth(0.0, 0.14, s) * (1 - smooth(0.5, 1.0, s))
    return finish(rgb, alpha, PX // 4, PX, CYAN_EDGE)


def rib(x, s):
    """How much of a rib is at x across and s along one period (0 at the foot's side): the ring's near half bowed down,
    its far half bowed up and fainter, seen through the paper."""
    r = np.sqrt(np.clip(1 - x * x, 0, 1))
    near = 1 - smooth(0.4 * RIB, RIB, np.abs(s - (0.5 - BOW * r)))
    far = 1 - smooth(0.3 * RIB, 0.7 * RIB, np.abs(s - (0.5 + BOW * r)))
    return np.maximum(near, 0.35 * far)


def rib_colour(x):
    d = np.abs(x)[..., None]
    heart, warm, deep = (np.array(rs.rgb(c)) for c in (HEART, WARM, WARM_DEEP))
    t = smooth(0.2, 0.95, d)
    return np.where(t < 0.5, heart + (warm - heart) * t * 2, warm + (deep - warm) * (t * 2 - 1))


def finish(rgb, alpha, h, w, bleed):
    """Supersampled colour and alpha, boxed down on premultiplied colour; clear pixels carry `bleed`."""
    pm = np.concatenate([rgb * alpha[..., None], alpha[..., None]], axis=-1).reshape(h, K, w, K, 4).mean(axis=(1, 3))
    a = pm[..., 3:4]
    rgb = np.where(a > 1e-4, pm[..., :3] / np.maximum(a, 1e-4), np.array(rs.rgb(bleed)))
    return np.concatenate([rgb, a], axis=-1).astype(np.float32)


def grid(w, h):
    xs = (np.arange(w * K) + 0.5) / (w * K) * 2 - 1
    ss = (np.arange(h * K) + 0.5) / (h * K)
    return np.meshgrid(xs, ss)


def column_picture():
    """One period of the shaft, its top row at the foot's side (Attachment0)."""
    x, s = grid(PX, PX)
    rgb, alpha, side = light(x)
    k = rib(x, s)
    rgb = rgb + (rib_colour(x) - rgb) * k[..., None]
    return finish(rgb, alpha + (side - alpha) * k, PX, PX, CYAN_EDGE)


def tip_picture():
    """The spike: the same light, its sides drawn in straight to a point at the bottom row (Attachment1), going thin
    toward it as light does, never a solid point."""
    x, s = grid(PX, PX)
    half = np.maximum((1 - s) ** 1.7, 1e-4)  # drawn in faster than straight: a needle of light, never a cut gem's point
    rgb, alpha, _ = light(np.clip(x / half, -1, 1))
    alpha = alpha * (1 - 0.6 * smooth(0.3, 1.0, s))
    return finish(rgb, np.where(np.abs(x) < half, alpha, 0.0), PX, PX, CYAN_EDGE)


def glow_picture():
    """The lantern's light: a warm white heart, the warm, then the cyan, thinning to nothing; a drum's height over its
    width, as the halo's quad is laid. Its heart is part see-through, so the drum's ribs still read in it: the paper
    lit, not a disc laid over the lantern."""
    x, y = grid(PX, PX)
    r = np.sqrt(x * x + (y * 2 - 1) ** 2)
    heart, warm, cyan, edge = (np.array(rs.rgb(c)) for c in (HEART, WARM, CYAN, CYAN_EDGE))
    rgb = heart + (warm - heart) * smooth(0.1, 0.32, r)[..., None]
    rgb = rgb + (cyan - rgb) * smooth(0.3, 0.6, r)[..., None]
    rgb = rgb + (edge - rgb) * smooth(0.6, 0.9, r)[..., None]
    alpha = (1 - smooth(0.15, 1.0, r)) ** 1.2 * 0.6
    return finish(rgb, alpha, PX, PX, CYAN_EDGE)


# --- the effect, frame by frame --------------------------------------------------------------------------------------

def art(stage, f):
    """Every layer drawn on clip frame f. A layer's kind is a beam (from a0 to a1), a board (a BillboardGui) or solids
    (Neon parts)."""
    out = []
    g = glow_at(f)
    if g:
        w, h, opaque = g
        out.append({"kind": "board", "layer": "glow", "at": stage.lamp[f], "w": w, "h": h, "pic": "glow",
                    "opaque": opaque, "emission": 1.0})
    motes = []
    for start, way in stage.motes:
        a = f - start
        if 0 <= a < sig.MOTE_FLIGHT and f < SLAM:
            u = a / sig.MOTE_FLIGHT
            p = stage.lamp[f] + way * (1.0 + sig.MOTE_FROM * (1 - u * u))
            motes.append((p, (0.16, 0.16, 0.4 + 1.4 * u), pf.toward(way)))
    if motes:
        out.append({"kind": "solid", "layer": "mote", "boxes": motes, "colour": CYAN, "opaque": 0.9, "emission": 1.0})
    if HANG < f < SLAM:  # on the slam the column's birth takes its place
        head, tail = stage.lamp[f], stage.lamp[max(HANG, f - sig.TRAIL)]
        if (tail - head).length > 0.3:
            out.append({"kind": "beam", "layer": "trail", "a0": head, "a1": tail + (tail - head).normalized() * 0.6,
                        "width": TRAIL_W, "pic": "tip", "wrap": False, "opaque": 0.85, "emission": 1.0})
    c = column_at(f - SLAM)
    if c:
        p = stage.hit
        foot, top = Vector((p.x, p.y, c["foot"])), Vector((p.x, p.y, c["top"]))
        halo = HALO * FLASH.get(f - SLAM, 1.0) * c["width"]
        out.append({"kind": "beam", "layer": "halo", "a0": foot, "a1": top + Vector((0, 0, c["spike"])),
                    "width": halo, "width1": halo * TAPER, "pic": "halo", "wrap": False, "opaque": c["opaque"],
                    "emission": 1.0})
        out.append({"kind": "beam", "layer": "shaft", "a0": foot, "a1": top, "width": c["width"],
                    "width1": c["width"] * TAPER, "pic": "column", "wrap": True, "scroll": c["scroll"], "fade": FOOT,
                    "opaque": c["opaque"], "emission": EMISSION})
        out.append({"kind": "beam", "layer": "tip", "a0": top, "a1": top + Vector((0, 0, c["spike"])),
                    "width": c["width"] * TAPER, "pic": "tip", "wrap": False, "opaque": c["opaque"], "emission": EMISSION})
    t = f - SLAM
    for tint in (CYAN, WARM):
        boxes = []
        for i, (angle, reach, lift, lag) in enumerate(stage.chips):
            if (tint == CYAN) != (i % 2 == 0):
                continue
            a = t - CHIPS - lag
            if 0 <= a <= 18:
                d, s = CHIP_EDGE * WIDE + 5.0 * reach * hx.out_fast(a / 10), CHIP_SIZE * (1 - a / 18) ** 0.8
                centre = Vector((stage.hit.x + d * math.cos(angle), stage.hit.y + d * math.sin(angle),
                                 0.8 + 5.5 * lift * hx.out_fast(a / 14)))
                turn = Quaternion(sig.UP, angle) @ Quaternion((1.0, 0.0, 0.0), 0.785) @ Quaternion((0.0, 1.0, 0.0), 0.6)
                boxes.append((centre, (s, s * 0.6, s * 1.4), turn))
        if boxes:
            out.append({"kind": "solid", "layer": f"chip{tint}", "boxes": boxes, "colour": tint, "opaque": 1.0,
                        "emission": 0.4})
    return out


class Stage(sig.Stage):
    """The block-in's stage (its grey A, for the row beside), and the art: a quad per beam and board, a box per Neon
    part, each in the code colour, shown one layer at a time to find what of it the camera sees."""

    def __init__(self, scene, lantern, frames):
        self.mode, self.items, self.only = "art", [], None
        super().__init__(scene, lantern, frames)
        self.code = r6.flat_material("Art.Code", CODE)
        self.quads, self.boxes = {}, {}

    def quad(self, layer):
        if layer not in self.quads:
            mesh = bpy.data.meshes.new(f"Art.{layer}")
            mesh.from_pydata([(0, 0, 0)] * 4, [], [(0, 1, 2, 3)])
            mesh.materials.append(self.code)
            obj = bpy.data.objects.new(f"Art.{layer}", mesh)
            bpy.context.scene.collection.objects.link(obj)
            obj.display.show_shadows, obj.hide_render = False, True
            self.quads[layer] = obj
        return self.quads[layer]

    def box(self, layer, n):
        pool = self.boxes.setdefault(layer, [])
        while len(pool) <= n:
            obj = bl.box(f"Art.{layer}", (1, 1, 1), self.code)
            obj.display.show_shadows, obj.rotation_mode, obj.hide_render = False, "QUATERNION", True
            pool.append(obj)
        return pool[n]

    def set(self, scene, *_):
        if not hasattr(self, "quads"):
            return
        f, keep = scene.frame_current, self.show
        self.variant, self.show = "A", keep and self.mode == "grey"
        sig.Stage.set(self, scene)  # the grey shapes in grey mode, and the avatar where the camera is behind it
        self.show = keep
        self.items = art(self, f) if keep and self.mode == "art" and scene.camera and f < len(self.lamp) else []
        if self.items:
            m = scene.camera.matrix_world
            eye, right, up = m.translation, m.col[0].to_3d().normalized(), m.col[1].to_3d().normalized()
        used = {}
        for item in self.items:
            if item["kind"] == "solid":
                for n, (centre, size, turn) in enumerate(item["boxes"]):
                    obj = self.box(item["layer"], n)
                    obj.location, obj.scale, obj.rotation_quaternion = centre, size, turn
                used[item["layer"]] = len(item["boxes"])
                continue
            if item["kind"] == "beam":
                a0, a1 = item["a0"], item["a1"]
                axis = (a1 - a0).normalized()
                across = axis.cross(eye - (a0 + a1) / 2).normalized()
                item.update(origin=a0, x=across, y=axis, length=(a1 - a0).length)
                w0, w1 = item["width"] / 2, item.get("width1", item["width"]) / 2  # Width0 at a0, Width1 at a1
                corners = (a0 - across * w0, a0 + across * w0, a1 + across * w1, a1 - across * w1)
            else:  # a BillboardGui, laid over the drum: toward the camera past the drum, however it's tilted
                at = item["at"] + (eye - item["at"]).normalized() * GLOW_OUT
                item.update(origin=at, x=right, y=up)
                w, h = item["w"] / 2, item["h"] / 2
                corners = (at - right * w - up * h, at + right * w - up * h, at + right * w + up * h, at - right * w + up * h)
            obj = self.quad(item["layer"])
            for v, co in zip(obj.data.vertices, corners):
                v.co = co
            obj.data.update()
            used[item["layer"]] = 1
        self.used = used
        self.reveal(self.only)

    def reveal(self, layer):
        """Shows only `layer`'s objects (None: none of the art)."""
        self.only = layer
        used = getattr(self, "used", {})
        for name, obj in self.quads.items():
            obj.hide_render = name != layer or name not in used
        for name, pool in self.boxes.items():
            for n, obj in enumerate(pool):
                obj.hide_render = name != layer or n >= used.get(name, 0)


# --- drawing it as the engine does -----------------------------------------------------------------------------------

def render(scene, path, flat=False, label=""):
    shading = scene.display.shading
    shading.light = "FLAT" if flat else "STUDIO"
    shading.show_shadows = shading.show_cavity = shading.show_object_outline = not flat
    scene.view_settings.view_transform = "Raw" if flat else "Standard"
    scene.render.use_stamp = bool(label) and not flat
    scene.render.stamp_note_text = label
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    return rs.load(path)


def camera_rays(scene, camera, w, h):
    """The eye, and a ray through the middle of every pixel (row 0 at the top)."""
    m = camera.matrix_world
    tr, br, bl_, tl = (np.array(m @ v) for v in camera.data.view_frame(scene=scene))
    xs = ((np.arange(w) + 0.5) / w)[None, :, None]
    ys = ((np.arange(h) + 0.5) / h)[:, None, None]
    top, bottom = tl + (tr - tl) * xs, bl_ + (br - bl_) * xs
    eye = np.array(m.translation)
    return eye, top + (bottom - top) * ys - eye


def sample(pic, u, v, wrap):
    """The picture at u across (0 to 1) and v down (0 to 1, row 0 the top; repeating if `wrap`), bilinear on
    premultiplied colour: its colour and alpha."""
    h, w = pic.shape[:2]
    pm = np.concatenate([pic[..., :3] * pic[..., 3:], pic[..., 3:]], axis=-1)
    x, y = u * w - 0.5, (np.mod(v, 1.0) if wrap else v) * h - 0.5
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]

    def at(yy, xx):
        return pm[np.mod(yy, h) if wrap else np.clip(yy, 0, h - 1), np.clip(xx, 0, w - 1)]

    c = (at(y0, x0) * (1 - fx) + at(y0, x0 + 1) * fx) * (1 - fy) + (at(y0 + 1, x0) * (1 - fx) + at(y0 + 1, x0 + 1) * fx) * fy
    a = c[..., 3]
    inside = (u >= 0) & (u <= 1) & (True if wrap else (v >= 0) & (v <= 1))
    return c[..., :3] / np.maximum(a, 1e-6)[..., None], np.where(inside, a, 0.0)


def lay(item, pics, eye, rays, pixels):
    """The colour and alpha of a beam or board on the pixels `pixels` (an index into the tile)."""
    r = rays[pixels]
    origin, x_axis, y_axis = (np.array(item[k]) for k in ("origin", "x", "y"))
    n = np.cross(x_axis, y_axis)
    denom = r @ n
    t = ((origin - eye) @ n) / np.where(np.abs(denom) < 1e-9, 1e-9, denom)
    rel = eye + r * t[:, None] - origin
    px, py = rel @ x_axis, rel @ y_axis
    pic = pics[item["pic"]]
    if item["kind"] == "board":
        rgb, a = sample(pic, px / item["w"] + 0.5, 0.5 - py / item["h"], False)
        return rgb, a * item["opaque"]
    w0, w1 = item["width"], item.get("width1", item["width"])  # the width from a0 to a1, straight between
    u = px / (w0 + (w1 - w0) * np.clip(py / item["length"], 0.0, 1.0)) + 0.5
    if item["wrap"]:  # every TextureLength, the texture slid up by its climb; the foot faded by its Transparency
        rgb, a = sample(pic, u, py / PERIOD - item["scroll"], True)
        a = a * smooth(0.0, item["fade"], py) * (py <= item["length"])
    else:
        rgb, a = sample(pic, u, py / item["length"], False)
    return rgb, a * item["opaque"]


def compose(shaded, bare, codes, items, pics, eye, rays, dark=None):
    """The shaded frame with every layer laid over it, far to near, where the camera sees it, blended by its
    LightEmission: B (1 - a (1 - e)) + a C. `dark`: every layer in that colour, a normal blend, the shape alone."""
    out = shaded[..., :3].copy()
    seat = Vector(eye.tolist())
    order = sorted(items, key=lambda i: (-(seat - (i["origin"] if "origin" in i else i["boxes"][0][0])).length,
                                         i["layer"] != "halo"))  # the halo behind the column it stands round
    for item in order:
        code, b = codes[item["layer"]][..., :3], bare[..., :3]
        k = np.array(CODE) - b
        cover = np.clip(((code - b) * k).sum(-1) / np.maximum((k * k).sum(-1), 1e-4), 0, 1)
        pixels = np.nonzero(cover > 0.002)
        if not len(pixels[0]):
            continue
        if item["kind"] == "solid":
            rgb, a = np.broadcast_to(np.array(rs.rgb(item["colour"])), (len(pixels[0]), 3)), np.full(len(pixels[0]), item["opaque"])
        else:
            rgb, a = lay(item, pics, eye, rays, pixels)
        a = a * cover[pixels]
        e = item["emission"]
        if dark:
            rgb, e = np.broadcast_to(np.array(rs.rgb(dark)), rgb.shape), 0.0
        out[pixels] = out[pixels] * (1 - a * (1 - e))[:, None] + a[:, None] * rgb
    return np.clip(out, 0, 1)


def shoot(scene, stage, camera, f, size, tmp, pics, label="", mode="art", dark=None):
    """One tile from `camera`: the effect over the clip, and the clip without it."""
    stage.mode = mode
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = size
    stage.show, stage.only = True, None
    scene.frame_set(f)
    drawn = render(scene, tmp, label=label)
    if mode == "grey":
        stage.show = False
        scene.frame_set(f)
        bare_shaded = render(scene, tmp)
        stage.show = True
        return drawn[..., :3], bare_shaded[..., :3]
    bare = render(scene, tmp, flat=True)
    codes = {}
    for item in stage.items:
        stage.reveal(item["layer"])
        codes[item["layer"]] = render(scene, tmp, flat=True)
    stage.reveal(None)
    eye, rays = camera_rays(scene, camera, *size)
    return compose(drawn, bare, codes, stage.items, pics, eye, rays, dark), drawn[..., :3]


def masks(scene, stage, camera, f, size, tmp, lead, keeper):
    """What of the lead, and of the keeper, the camera sees on frame f, without the effect."""
    stage.mode, scene.camera = "art", camera
    scene.render.resolution_x, scene.render.resolution_y = size
    stage.show = False
    scene.frame_set(f)
    every = render(scene, tmp, flat=True)
    out = {}
    for name, objs in (("lead", lead), ("keeper", keeper)):
        kept = [o.hide_render for o in objs]
        for o in objs:
            o.hide_render = True
        out[name] = np.abs(render(scene, tmp, flat=True)[..., :3] - every[..., :3]).max(-1) > 0.01
        for o, k in zip(objs, kept):
            o.hide_render = k
    stage.show = True
    return out


def hat_gap(scene, stage, camera, f, size, tmp, pics, hat, drum):
    """Condition 6, at 64 px from `camera` on frame f: the clear pixels between the head and hat (its whole silhouette,
    the drum hidden) and the lantern's glow (where it changes the frame by more than 0.03, the share's measure), and
    between the head and hat and the drum itself; 0 where they touch, minus the pixels they share where they overlap.
    None where there's no glow, or the head isn't seen."""
    stage.mode, scene.camera = "art", camera
    scene.render.resolution_x, scene.render.resolution_y = size
    stage.show = False
    scene.frame_set(f)

    def hidden(objs):
        kept = [o.hide_render for o in objs]
        for o in objs:
            o.hide_render = True
        picture = render(scene, tmp, flat=True)[..., :3]
        for o, k in zip(objs, kept):
            o.hide_render = k
        return picture

    every, no_drum = render(scene, tmp, flat=True)[..., :3], hidden(drum)
    drum_m = np.abs(no_drum - every).max(-1) > 0.01
    hat_m = np.abs(hidden(drum + hat) - no_drum).max(-1) > 0.01
    stage.show = True
    scene.frame_set(f)
    glow = next((i for i in stage.items if i["layer"] == "glow"), None)
    if glow is None or not hat_m.any():
        return None
    eye, rays = camera_rays(scene, camera, *size)
    every_px = np.nonzero(np.ones(size[::-1], dtype=bool))
    rgb, a = lay(glow, pics, eye, rays, every_px)
    glow_m = np.zeros(size[::-1], dtype=bool)
    glow_m[every_px] = a * rgb.max(-1) > 0.03

    def gap(m):
        if not m.any():
            return None
        if (m & hat_m).any():
            return -float((m & hat_m).sum())
        pa, pb = np.argwhere(edge(m)), np.argwhere(edge(hat_m))
        return round(float(np.sqrt(((pa[:, None, :] - pb[None, :, :]) ** 2).sum(-1)).min()) - 1, 1)

    return gap(glow_m), gap(drum_m)


def edge(m):
    """The pixels of mask m with a neighbour outside it: all a distance between two masks needs."""
    inner = m.copy()
    inner[1:] &= m[:-1]
    inner[:-1] &= m[1:]
    inner[:, 1:] &= m[:, :-1]
    inner[:, :-1] &= m[:, 1:]
    return m & ~inner


def close_up(scene, stage, camera, f, size, tmp, pics, hat, scale=3, box=(140, 100)):
    """A 64 px tile's patch round the hat and the lantern on frame f, its pixels enlarged `scale` times, unfiltered."""
    tile = shoot(scene, stage, camera, f, size, tmp, pics)[0]
    middle = sum((o.matrix_world.translation for o in hat), Vector()) / len(hat)
    middle = (middle + stage.lamp[f]) / 2
    at = world_to_camera_view(scene, camera, middle)
    w, h = size
    cx = int(np.clip(at.x * w - box[0] / 2, 0, w - box[0]))
    cy = int(np.clip((1 - at.y) * h - box[1] / 2, 0, h - box[1]))
    patch = tile[cy:cy + box[1], cx:cx + box[0]]
    return np.repeat(np.repeat(patch, scale, axis=0), scale, axis=1)


def sheet(tiles, columns):
    h, w = tiles[0].shape[:2]
    rows = math.ceil(len(tiles) / columns)
    out = np.zeros((rows * h, columns * w, 4), dtype=np.float32)
    out[..., 3] = 1
    for i, tile in enumerate(tiles):
        r, c = divmod(i, columns)
        out[r * h:(r + 1) * h, c * w:c * w + tile.shape[1], :3] = tile[:, :, :3]
    return out


def stack(rows):
    width = max(r.shape[1] for r in rows)
    padded = []
    for r in rows:
        pad = np.zeros((r.shape[0], width, 4), dtype=np.float32)
        pad[..., 3] = 1
        pad[:, :r.shape[1]] = r
        padded.append(pad)
    return np.concatenate(padded, axis=0)


def edged(tile):
    tile = tile.copy()
    tile[:, -2:] = tile[-2:] = 0.0
    return tile


def apex_over_top(stage, camera):
    """How far the spike's point stands over the frame's top edge from `camera`, in degrees, frame by frame."""
    inv, edge, over = camera.matrix_world.inverted(), math.degrees(camera.data.angle_y) / 2, {}
    for t in TIMES:
        c = column_at(t)
        if c:
            local = inv @ Vector((stage.hit.x, stage.hit.y, c["top"] + c["spike"]))
            over[SLAM + t] = round(math.degrees(math.atan2(local.y, -local.z)) - edge, 1)
    return over


def caption_sheet(pics, out, numbers):
    """The three pictures, on the night street's floor and on a bright one, large, with what they are."""
    night, day = rs.rgb("#25212C"), rs.rgb("#BDB8AE")
    scale, pad = 2, 24
    col = np.concatenate([pics["column"]] * 3, axis=0)  # three periods: the wrap
    items = [("column, three periods", col), ("tip", pics["tip"]), ("halo", pics["halo"]), ("glow", pics["glow"])]
    w = pad + sum(p.shape[1] * scale + pad for _, p in items)
    h = 70 + 2 * (col.shape[0] * scale + pad) + 210
    canvas = rs.canvas(w, h, rs.rgb("#14121A"))
    x = pad
    for _, p in items:
        big = np.repeat(np.repeat(p, scale, axis=0), scale, axis=1)
        for row, ground in enumerate((night, day)):
            y = 70 + row * (col.shape[0] * scale + pad)
            rs.fill(canvas, x, y, big.shape[1], col.shape[0] * scale, ground)
            rs.paste(canvas, big, x, y)
        x += big.shape[1] + pad
    text = [(pad, 16, 26, "The Lamplighter's signature, drawn: the column's pictures (Beam Color white, straight alpha)", "#FFFFFF")]
    x = pad
    for name, p in items:
        text.append((x, 50, 16, name, "#C8C8D0"))
        x += p.shape[1] * scale + pad
    y = 70 + 2 * (col.shape[0] * scale + pad) + 6
    for line in numbers:
        text.append((pad, y, 17, line, "#E0E0E8"))
        y += 26
    layer = rs.text_layer(w, h, text)
    rs.paste(canvas, layer, 0, 0)
    rs.save(canvas, out)


def main():
    sys.stdout.reconfigure(line_buffering=True)
    out = bl.out_dir()
    tmp = out / "_tile.png"
    pics = {"column": column_picture(), "tip": tip_picture(), "halo": halo_picture(), "glow": glow_picture()}
    for name, pic in pics.items():
        rs.save(pic, out / f"lamplighter_{FILES[name]}.png")
    scene, rig, costume, *_ = lc.build(out)
    frames = sig.key(rig)
    stage = Stage(scene, costume[lc.LAMP], frames)
    scene.render.dither_intensity = 0.0
    r = scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note = True
    cams = lc.cameras(scene, rig)
    game = sig.game_camera(scene, "game")
    flank = lc.stage_camera(scene, -90.0, 4.0, 30.0, (0.0, 2.0, 6.0), fov=40.0, name="flank")
    bpy.data.objects["Floor"].scale *= 4
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk = tuple(floor.diffuse_color)
    lead = [o for o in scene.objects if o.name.startswith("Fx.Lead")]
    keeper = [o for o in costume.values() if not o.hide_render]
    hat = [costume[f"{lc.NAME}_Head"]]  # the hat is merged into the head's piece: the gap is to the head and hat
    print(f"the lead: {len(lead)} objects, the keeper: {len(keeper)}; it lands at {tuple(round(v, 2) for v in stage.hit.xy)}")

    # the game's camera, the whole signature
    r.stamp_font_size = 22
    tiles = []
    for f in sig.SHEET:
        tiles.append(edged(shoot(scene, stage, game, f, (480, 270), tmp, pics, label=sig.label(f))[0]))
    rs.save(sheet(tiles, 5), out / "signature_art.png")

    # the strip from every view, beside the block-in's A
    r.stamp_font_size = 14
    size, rows = (256, 144), []
    views = (("game, the block-in's A", game, "grey", None), ("game, drawn", game, "art", None),
             ("ring", cams["ring"], "art", None), ("flank", flank, "art", None))
    for name, camera, mode, dark in views:
        rows.append(sheet([edged(shoot(scene, stage, camera, f, size, tmp, pics, label=f"{name} {f}" if f == STRIP[0]
                                       else str(f), mode=mode)[0]) for f in STRIP], len(STRIP)))
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    for name, dark in (("game, a bright floor", None), ("game, a dark colour", DARK)):
        rows.append(sheet([edged(shoot(scene, stage, game, f, size, tmp, pics, label=f"{name} {f}" if f == STRIP[0]
                                       else str(f), dark=dark)[0]) for f in STRIP], len(STRIP)))
    floor.diffuse_color = dusk
    rs.save(stack(rows), out / "signature_art_views.png")

    # at 64 px (each tile sized so the keeper, floor to hat at rest, stands 64 px tall from its camera), from each
    # heading, then the game's on the bright floor and in the dark colour; and the hold close up, enlarged
    rows, tiles64 = [], {}
    headings = (("game", game), ("ring", cams["ring"]), ("flank", flank))
    for name, camera in headings:
        tiles64[name] = sig.keeper_64(scene, camera)
        rows.append(sheet([edged(shoot(scene, stage, camera, f, tiles64[name], tmp, pics)[0]) for f in STRIP], len(STRIP)))
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    for dark in (None, DARK):
        rows.append(sheet([edged(shoot(scene, stage, game, f, tiles64["game"], tmp, pics, dark=dark)[0]) for f in STRIP],
                          len(STRIP)))
    floor.diffuse_color = dusk
    rs.save(stack(rows), out / "signature_art_64.png")
    rows = [sheet([edged(close_up(scene, stage, camera, f, tiles64[name], tmp, pics, hat)) for f in HOLD], len(HOLD))
            for name, camera in headings]
    rs.save(stack(rows), out / "signature_art_64_hold.png")

    # condition 6: the gap between the lantern's light and the hat, at 64 px from each heading, through the hold
    gaps = {name: {} for name, _ in headings}
    for name, camera in headings:
        for f in range(LIGHT, SLAM, 2):
            g = hat_gap(scene, stage, camera, f, tiles64[name], tmp, pics, hat, [costume[lc.LAMP]])
            if g:
                gaps[name][f] = g
    closest = {name: min(((v[0], f) for f, v in g.items() if v[0] is not None), default=None)
               for name, g in gaps.items()}
    print(f"the glow's gap to the hat at 64 px, the least: {closest}")
    for name, g in gaps.items():
        print(f"  {name}: " + " ".join(f"{f}:{v[0]}/{v[1]}" for f, v in g.items()))
    # the measures: its share of the game's screen, and what it covers of the lead and the keeper
    share, covered = {"art": {}, "grey": {}}, {"art": {}, "grey": {}}
    for f in sig.SHARE:
        for mode in ("art", "grey"):
            drawn, bare = shoot(scene, stage, game, f, (480, 270), tmp, pics, mode=mode)
            changed = np.abs(drawn - bare).max(-1)
            share[mode][f] = round(float((changed > 0.03).mean()), 4)
            if SLAM <= f <= SLAM + 4:
                seen = masks(scene, stage, game, f, (480, 270), tmp, lead, keeper)
                covered[mode][f] = {k: round(float((changed[m] > 0.15).mean()), 3) for k, m in seen.items()}
    over = apex_over_top(stage, game)
    table = {
        "column": {SLAM + t: {k: round(v * (S if k in ("foot", "top", "width", "spike") else 1), 3)
                              for k, v in column_at(t).items()} for t in TIMES if column_at(t)},
        "glow": {f: [round(v * (S if i < 2 else 1), 2) for i, v in enumerate(glow_at(f))] for f in range(LIGHT, SLAM, 4)},
        "share": share, "covered_over_015": covered, "apex_over_frame_top_degrees": over,
        "hat_gap_px_at_64": {name: {f: {"glow": v[0], "drum": v[1]} for f, v in g.items()} for name, g in gaps.items()},
        "tile_at_64": {name: list(t) for name, t in tiles64.items()},
        "units": "the column in studs (foot, top: up from the street; width; spike: its length); scroll in periods. "
                 "hat_gap_px_at_64: clear pixels between the hat and the lantern's glow (where it changes the frame by "
                 "over 0.03) or the drum, 0 where they touch, in tile_at_64's tile, where the keeper stands 64 px tall",
    }
    (out / "lamplighter_signature_art.json").write_text(json.dumps(table, indent=1))
    print(json.dumps({"share": share, "covered": covered, "apex_over_top": over}))
    tmp.unlink(missing_ok=True)
    peak = column_at(LETGO)
    rs.OUT = out  # where rook_sheet.text_layer draws its text
    caption_sheet(pics, out / "signature_art_pictures.png", [
        f"The shaft: a Beam, Wrap, TextureLength {PERIOD * S:.2f} studs (one rib), TextureSpeed {CLIMB:g} (the ribs climb), "
        f"Width1 = {TAPER} Width0, LightEmission {EMISSION}, LightInfluence 0; its foot faded over {FOOT * S:.1f} studs.",
        f"The tip: a Beam, Stretch, TextureLength 1, TextureSpeed 0, the shaft's width at its top, its length {SPIKE} of "
        f"the shaft's foot. The halo: a Beam, Stretch, from the foot to the point, {HALO} times as wide, Width1 = "
        f"{TAPER} Width0, LightEmission 1.",
        f"At its height (123): {peak['width'] * S:.1f} studs wide at the foot, the shaft to {peak['top'] * S:.1f} studs, "
        f"the point at {(peak['top'] + peak['spike']) * S:.1f}. Then it climbs, {RISE * S:.0f} studs by 139; gone by 140.",
        f"The glow: a BillboardGui over the lantern's drum, through the hold, LightInfluence 0.",
        f"Colours: Lantern Row's cyan {CYAN} and {CYAN_EDGE}, its warm {WARM} and {WARM_DEEP}; a core of {CORE}, a rib's "
        f"middle {HEART}.",
    ])


if __name__ == "__main__":
    main()
