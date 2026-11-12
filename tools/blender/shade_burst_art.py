"""The Shade's burst into light and paper in its art, on its Burst clip (AR2, section 8; handbook/visuals/vfx.md, step 4).

blender.exe -b --factory-startup --python tools/blender/shade_burst_art.py -- <out_dir> [pictures]

The block-in's C, the sky lantern (shade_burst_fx.py), with research's three fixes: the flame carries the read to frame
34, larger and brighter in its first six frames and tapering; the scraps rise under it, in its column; a dark rim on the
flare and the flame for a bright floor. One picture, shade_burst.png, 1024 x 768:
- the flame, eight frames of 128 x 256 along its top: it burns upward, two hot frames it boils between, then six in
  which it's eaten from its tongues and edges back to an ember at its base, cooling from the core to the gold to the rim;
- the paper, four torn scraps in four rows of eight frames of 128 x 128: whole, then burnt from one side, a char line
  and a gold front eating across it.
Every element is a flat picture facing the camera, upright on the screen, as a BillboardGui's ImageLabel draws it: the
charge (the flame small in the collar), the flare (the flame the coat's size, on the Burst frame), the flame let go,
and the ten scraps. The light is the masks' warm white and a lantern's gold: nothing in it is red.
Writes shade_burst.png, the sheet shade_burst_art.png, and shade_burst_art.json (every element on every frame, for the
builder). With `pictures`, only the picture. Workbench, so no GPU turn.
Stage directions as shade_burst_fx.py: right, forward, up, in studs, from where the Shade stands; it faces forward.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_haymaker_art as ha  # noqa: E402  (picture)
import rook_haymaker_fx as hx  # noqa: E402  (camera, clamp, out_fast)
import rook_sheet as rs  # noqa: E402
import shade_burst_fx as fx  # noqa: E402
import shade_clips as sc  # noqa: E402
import shade_sheet as ss  # noqa: E402

CORE, GOLD, EMBER = "#FFF8EA", "#FFC861", "#FFB040"
PAPER, FOLD, INK = ss.PALETTE["Paper"], ss.PALETTE["PaperShade"], ss.PALETTE["Ink"]
FW, FH, SW, FRAMES, SHAPES = 128, 256, 128, 8, 4   # a flame frame, a scrap frame; eight frames; four scraps
ATLAS = (FRAMES * FW, FH + SHAPES * SW)            # 1024 x 768
FLAME_GONE = (0, 0, 0.08, 0.18, 0.32, 0.48, 0.64, 0.80)
PAPER_GONE = (0, 0.10, 0.22, 0.36, 0.50, 0.64, 0.78, 0.90)
RIM = 7.0          # px of ink round the flame, in its 128-wide frame: about a pixel at 64 px
HOT = 6            # frames after the Burst the flame boils hot, before it's eaten: the read carries to 34
LIFE = 17          # frames a scrap lives once it lifts
SCRAP = 1.3        # studs a scrap's frame is across; the paper fills about 70% of it
FLARE = (3.8, 5.4)  # the flare's frame on the Burst: the coat's outline engulfed, the largest the light is
# The flame's outline in its frame, two boils: px across from its middle, px up from its foot. It burns upward: a round
# base, hottest low in its middle, and three tongues pointing up, the middle one tallest. Nothing hangs from it.
FLAME = (
    ((0, 4), (24, 8), (42, 24), (54, 52), (54, 84), (46, 112), (46, 140), (40, 196), (26, 150), (22, 186), (12, 226),
     (-4, 254), (-16, 222), (-20, 186), (-24, 168), (-40, 178), (-42, 140), (-52, 108), (-56, 74), (-50, 42),
     (-36, 18), (-18, 6)),
    ((2, 4), (26, 10), (44, 28), (54, 58), (52, 92), (46, 120), (48, 150), (44, 178), (28, 140), (24, 180), (16, 222),
     (4, 250), (-10, 228), (-18, 196), (-22, 172), (-36, 206), (-44, 160), (-52, 120), (-56, 84), (-50, 48),
     (-36, 22), (-18, 8)),
)
# Cameras (azimuth from the Shade's front, positive to its right; elevation; distance; focus; field of view).
# The player's: the lead fights beyond its target, 45 degrees off the line (Combat.Lead.Frame), so the player, behind
# the avatar, sees the Shade it fights from behind on its right. The front: another Shade of the pack, facing the camera.
GAME = (135.0, 20.0, 20.0, (0.0, 0.5, 5.5), 50.0)
FRONT = (-24.0, 14.0, 20.0, (0.0, 1.0, 5.5), 50.0)
SIDE = (90.0, 6.0, 26.0, (0.0, 3.0, 5.5), 36.0)
GAME_ROWS = ((18, 22, 25, 27, 28, 29, 30, 31), (32, 33, 34, 36, 38, 41, 45, 49))
ROW = (27, 28, 29, 31, 34, 38, 44, 49)
STRIP = (25, 27, 28, 29, 30, 31, 32, 34, 36, 38, 41, 45)
NAMES = {fx.LETGO: "lets go", fx.BURST: "Burst", fx.BURST + HOT + 1: "the read's end"}


# --- the picture ----------------------------------------------------------------------------------------------

def grid(w, h, k):
    """Texel centres in px: x across from the middle, y up from the foot; row 0 at the top."""
    return np.meshgrid((np.arange(w * k) + 0.5) / k - w / 2, h - (np.arange(h * k) + 0.5) / k)


def sdf(points, X, Y):
    """Distance to a closed outline, in px: positive inside, negative outside."""
    P = np.asarray(points, dtype=np.float64)
    d, inside = np.full(X.shape, np.inf), np.zeros(X.shape, dtype=bool)
    for (ax, ay), (bx, by) in zip(P, np.roll(P, -1, axis=0)):
        ex, ey, wx, wy = bx - ax, by - ay, X - ax, Y - ay
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        d = np.minimum(d, np.hypot(wx - ex * t, wy - ey * t))
        inside ^= ((ay > Y) != (by > Y)) & (X < ex * (Y - ay) / (ey + 1e-12) + ax)
    return np.where(inside, d, -d)


def finish(colour, keep, k):
    """Straight alpha at the frame's size; an empty texel keeps the ink's colour, so nothing fringes."""
    frame = np.empty((*keep.shape, 4), dtype=np.float32)
    frame[..., :3], frame[..., 3] = colour, keep
    frame = rs.shrink(frame, 1 / k)
    frame[..., :3] = np.where(frame[..., 3:] > 1e-6, frame[..., :3], np.array(rs.rgb(INK), dtype=np.float32))
    return frame


def flame_frames():
    """The flame's eight frames, FH x FW. One field says how hot a texel is, deepest low in its middle; a frame keeps
    what's hotter than its threshold, so the tongues and the edges go first and it dies back to an ember at its base,
    and the tones follow the edge in: as it's eaten it cools, from the core to the gold to the ink."""
    k = 2
    X, Y = grid(FW, FH, k)
    ink, gold, core = (np.array(rs.rgb(c), dtype=np.float32) for c in (INK, GOLD, CORE))
    frames = []
    for n, gone in enumerate(FLAME_GONE):
        d = sdf(FLAME[n % 2], X, Y)
        inside = d > 0
        heat = np.clip(d / d.max(), 0, 1) ** 0.8 * (1 - 0.75 * np.clip((Y - 60) / 190, 0, 1))
        heat /= heat.max()
        left = heat - (np.quantile(heat[inside], gone) if gone else 0.0)
        keep = inside & (left > 0)
        edge = (d < RIM) | ((left < 0.06) if gone else False)
        colour = np.where(edge[..., None], ink, np.where((left < 0.3)[..., None], gold, core))
        frames.append(finish(colour, keep, k))
    return frames


def torn(rng):
    """A scrap's outline: a long piece with four or five corners, some edges cut straight, the others torn into short
    jagged steps, so it reads as paper and not as a chip of stone."""
    n = int(rng.integers(4, 6))
    angles = np.arange(n) / n * 2 * np.pi + rng.uniform(-0.3, 0.3, n) + rng.uniform(0, 2 * np.pi)
    turn = rng.uniform(0, np.pi)
    corners = []
    for r, a in zip(rng.uniform(40, 54, n), np.sort(angles)):
        x, y = 1.3 * r * math.cos(a), 0.75 * r * math.sin(a)
        corners.append(np.array((x * math.cos(turn) - y * math.sin(turn), x * math.sin(turn) + y * math.cos(turn))))
    torn_edges = rng.permutation(n)[: max(2, n // 2)]
    out = []
    for i in range(n):
        a, b = corners[i], corners[(i + 1) % n]
        if i not in torn_edges:
            out.append(a)
            continue
        normal = np.array((b[1] - a[1], a[0] - b[0])) / np.linalg.norm(b - a)
        steps = max(3, int(np.linalg.norm(b - a) / 6))
        for j in range(steps):
            out.append(a + (b - a) * j / steps + normal * (rng.uniform(-4.0, 4.0) if j else 0.0))
    return out


def scrap_frames(seed=11):
    """The four scraps, each in eight frames of SW x SW: whole paper with a fold and an ink edge, then burnt from one
    side, a char line and a gold front eating across it."""
    k = 2
    X, Y = grid(SW, SW, k)
    Y = Y - SW / 2
    rng = np.random.default_rng(seed)
    ink, ember, paper, fold = (np.array(rs.rgb(c), dtype=np.float32) for c in (INK, EMBER, PAPER, FOLD))
    rows = []
    for _ in range(SHAPES):
        d = sdf(torn(rng), X, Y)
        inside = d > 0
        phi, c = rng.uniform(0, 2 * np.pi), rng.uniform(-10, 10)
        side = (X * math.cos(phi) + Y * math.sin(phi) - c) > 0
        towards = rng.uniform(0, 2 * np.pi)
        proj = X * math.cos(towards) + Y * math.sin(towards)
        proj = (proj - proj[inside].min()) / (np.ptp(proj[inside]) + 1e-9)
        wobble = sum(np.sin(X * rng.uniform(0.05, 0.12) + Y * rng.uniform(-0.12, 0.12) + rng.uniform(0, 6)) for _ in range(3))
        wobble = (wobble - wobble.min()) / (np.ptp(wobble) + 1e-9)
        burn = 0.6 * proj + 0.25 * np.clip(d / d.max(), 0, 1) + 0.15 * wobble
        row = []
        for gone in PAPER_GONE:
            left = burn - (np.quantile(burn[inside], gone) if gone else -1.0)
            keep = inside & (left > 0)
            body = np.where(side[..., None], fold, paper)
            if gone:
                body = np.where((left < 0.035)[..., None], ink, np.where((left < 0.11)[..., None], ember, body))
            colour = np.where((d < 4.0)[..., None], ink, body)
            row.append(finish(colour, keep, k))
        rows.append(row)
    return rows


def atlas(flames, scraps):
    sheet = np.zeros((ATLAS[1], ATLAS[0], 4), dtype=np.float32)
    sheet[..., :3] = rs.rgb(INK)
    for n, frame in enumerate(flames):
        sheet[:FH, n * FW:(n + 1) * FW] = frame
    for s, row in enumerate(scraps):
        for n, frame in enumerate(row):
            sheet[FH + s * SW:FH + (s + 1) * SW, n * SW:(n + 1) * SW] = frame
    return sheet


def flame_rect(n):
    return (n * FW, 0, FW, FH)


def scrap_rect(s, n):
    return (n * SW, FH + s * SW, SW, SW)


# --- the effect, frame by frame ---------------------------------------------------------------------------------

def height(t):
    """Studs the flame's head stands over the collar, t frames after the Burst: the block-in's leap and climb."""
    return fx.RISE * hx.out_fast(t / fx.FLY) + max(0, t - fx.FLY) * 0.2


def flame_box(t):
    """The flame's frame t frames after the Burst: width, length (stretched while it's fast), and its picture."""
    speed = height(t) - height(t - 1)
    length = (3.4 + 0.8 * speed) * (1 - 0.04 * max(0, t - HOT))
    width = 3.0 - 0.08 * (min(t, HOT) - 1)
    width *= 1 - 0.05 * max(0, t - HOT)
    frame = t % 2 if t <= HOT else min(7, 1 + int((t - HOT) * 6 / (fx.OUT - HOT) + 0.5))
    return width, length, frame


def art(stage, f):
    """Every picture on frame `f`: what it is, its centre, its frame's size in studs (across, up the screen), its
    rectangle in the picture, its turn on the screen in degrees, and how much its width is squeezed (a scrap's flutter)."""
    out, t, up = [], f - fx.BURST, Vector((0.0, 0.0, 1.0))
    if fx.CHARGE <= f < fx.BURST:
        u = hx.clamp((f - fx.CHARGE) / (fx.BURST - fx.CHARGE))
        w, l = 0.6 + 0.6 * u, 0.4 + 1.8 * u * u  # light spilling up out of the collar as the mask tips off it
        out.append(dict(what="charge", centre=stage.collars[f] + up * (l / 2), size=(w, l), rect=flame_rect((f // 2) % 2),
                        rot=0.0, squash=1.0))
    if f == fx.BURST:
        w, l = FLARE
        out.append(dict(what="flare", centre=stage.collar + up * (0.9 - l / 2), size=(w, l), rect=flame_rect(0), rot=0.0, squash=1.0))
    if 1 <= t <= fx.OUT:
        w, l, n = flame_box(t)
        h = height(t)
        head = stage.collar + Vector((0.0, -math.tan(fx.BACK) * h, h))
        out.append(dict(what="flame", centre=head - up * (l / 2), size=(w, l), rect=flame_rect(n), rot=0.0, squash=1.0))
    if t >= 1:
        for i, scrap in enumerate(stage.scraps):
            a = t - scrap.lag
            if a >= LIFE:
                continue
            if a <= 0:  # the coat in pieces where it stood, until each lifts
                at, size, n = Vector(scrap.start), 1.0, 0
            else:  # drawn in to the flame's line and up it, turning round it, smaller as it climbs and burning
                radius = scrap.radius0 * (1 - hx.out_fast(a / 6)) + 0.15 + 1.2 * scrap.lift
                angle = scrap.angle0 + 0.2 * a
                z = scrap.start.z + 8.0 * hx.clamp(a / 18) ** 1.4 * scrap.speed
                axis = Vector((stage.collar.x, stage.collar.y - math.tan(fx.BACK) * (z - stage.collar.z), z))
                at = axis + Vector((radius * math.cos(angle), radius * math.sin(angle), 0.0))
                size, n = 1 - 0.35 * hx.clamp(a / 16), min(FRAMES - 1, int(a * FRAMES / LIFE))
            turn = max(0.0, a)
            out.append(dict(what="scrap", centre=at, size=(SCRAP * size, SCRAP * size), rect=scrap_rect(i % SHAPES, n),
                            rot=math.degrees(scrap.turn0.z + scrap.spin.z * turn),
                            squash=max(0.45, abs(math.cos(scrap.turn0.x + 0.3 * turn)))))
    return out


class Stage(fx.Stage):
    """The block-in's stage: its boxes for the block-in's C, or the pictures, each a quad facing the camera."""

    def __init__(self, scene, rig, sheet):
        self.show, self.mode, self.quads, self.light_only = False, "art", [], False
        super().__init__(scene, rig)
        self.variant = "C"
        self.material = ha.picture("Fx.Burst", sheet)
        torso, self.collars = rig.parts["Torso"], {}
        for f in range(fx.CHARGE, fx.BURST):
            scene.frame_set(f)
            fx.r6._refresh()
            self.collars[f] = torso.matrix_world @ Vector(fx.COLLAR)
        scene.frame_set(fx.BURST)
        self.show = True

    def quad(self):
        mesh = bpy.data.meshes.new("Fx.Picture")
        mesh.from_pydata([(-0.5, 0, -0.5), (0.5, 0, -0.5), (0.5, 0, 0.5), (-0.5, 0, 0.5)], [], [(0, 1, 2, 3)])
        mesh.uv_layers.new(name="UV")
        mesh.materials.append(self.material)
        obj = bpy.data.objects.new("Fx.Picture", mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.display.show_shadows = False
        obj.hide_render = True
        return obj

    @staticmethod
    def rect(obj, rect):
        x, y, w, h = rect
        u0, u1 = x / ATLAS[0], (x + w) / ATLAS[0]
        v0, v1 = 1 - (y + h) / ATLAS[1], 1 - y / ATLAS[1]
        for loop, uv in zip(obj.data.uv_layers[0].data, ((u0, v0), (u1, v0), (u1, v1), (u0, v1))):
            loop.uv = uv

    def set(self, scene, *_):
        if not hasattr(self, "material"):
            return
        f = scene.frame_current
        if self.show and self.mode == "block":
            super().set(scene)
            for obj in self.quads + (self.pool["mid"] if self.light_only else []):
                obj.hide_render = True
            return
        for obj, hidden in self.dressed.items():
            obj.hide_render = hidden or f >= fx.BURST
        self.charge.hide_render = self.flare.hide_render = True
        for objs in self.pool.values():
            for obj in objs:
                obj.hide_render = True
        items = art(self, f) if self.show and scene.camera else []
        if self.light_only:
            items = [item for item in items if item["what"] != "scrap"]
        if items:
            view = scene.camera.matrix_world.to_3x3().normalized()
            face = Matrix((view.col[0], -view.col[2], view.col[1])).transposed()  # across the screen, at the camera, up it
        for n, item in enumerate(items):
            if n == len(self.quads):
                self.quads.append(self.quad())
            obj, (w, h) = self.quads[n], item["size"]
            turn = Matrix.Rotation(math.radians(item["rot"]), 3, "Y")
            obj.matrix_world = Matrix.Translation(item["centre"]) @ (face @ turn @ Matrix.Diagonal((w * item["squash"], 1, h))).to_4x4()
            self.rect(obj, item["rect"])
            obj.hide_render = False
        for obj in self.quads[len(items):]:
            obj.hide_render = True


# --- the sheet --------------------------------------------------------------------------------------------------

def shoot(scene, stage, camera, f, label, size, out, mode="art"):
    """One tile, as rook_haymaker_art.shoot: the clip shaded, and the effect over it unlit in its own colours. Also the
    count of the effect's pixels."""
    stage.mode = mode
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = size
    shading = scene.display.shading
    path = out / "_tile.png"
    scene.render.filepath = str(path)
    passes = []
    for flat, show in ((False, False), (True, True), (True, False)):
        stage.show = show
        shading.light = "FLAT" if flat else "STUDIO"
        shading.show_shadows = shading.show_cavity = shading.show_object_outline = not flat
        scene.render.use_stamp = bool(label) and not flat
        scene.render.stamp_note_text = label
        scene.frame_set(f)
        bpy.ops.render.render(write_still=True)
        passes.append(rs.load(path))
    shaded, lit, bare = passes
    drawn = np.abs(lit[..., :3] - bare[..., :3]).max(axis=-1) > 0.03
    light = drawn.sum()
    if not label:  # a small tile: count the light alone too, the flame without the paper
        stage.show, stage.light_only = True, True
        scene.frame_set(f)
        bpy.ops.render.render(write_still=True)
        alone = rs.load(path)
        light = (np.abs(alone[..., :3] - bare[..., :3]).max(axis=-1) > 0.03).sum()
        stage.light_only = False
    path.unlink()
    stage.show, stage.mode = True, "art"
    return np.where(drawn[..., None], lit, shaded), int(light)


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def table(stage):
    """Every picture on every frame, for the builder: centres from the collar (the Torso's on the charge's frames, then
    where it stood on the Burst frame), in the Shade's right, forward and up."""
    frames = {}
    for f in range(fx.CHARGE, fx.BURST + max(fx.OUT, max(s.lag for s in stage.scraps) + LIFE) + 1):
        items = []
        for item in art(stage, f):
            origin = stage.collars[f] if item["what"] == "charge" else stage.collar
            items.append({"what": item["what"], "at": [round(v, 3) for v in item["centre"] - origin],
                          "size": [round(v, 3) for v in item["size"]], "rect": list(item["rect"]),
                          "rotation": round(item["rot"] % 360, 1), "squash": round(item["squash"], 3)})
        if items:
            frames[str(f)] = items
    return {"picture": "shade_burst.png", "size": list(ATLAS), "fps": 60, "burst": fx.BURST,
            "collar_at_burst": [round(v, 3) for v in stage.collar],
            "axes": "right, forward, up, studs, in the Shade's own frame as it stood at the Burst",
            "frames": frames}


def main():
    out = bl.out_dir()
    rs.OUT = out
    flames, scraps = flame_frames(), scrap_frames()
    sheet = atlas(flames, scraps)
    rs.save(sheet, out / "shade_burst.png")
    print(f"wrote {out / 'shade_burst.png'} {sheet.shape[1]}x{sheet.shape[0]}")
    if "pictures" in sys.argv[sys.argv.index("--") + 1:]:
        return

    scene, rig, undress, wear, feet = sc.build()
    print(f"Burst: {fx.key(rig)} frames, the marker at {fx.BURST}")
    stage = Stage(scene, rig, sheet)
    cams = {name: hx.camera(scene, name, az, el, d, focus, fov) for name, (az, el, d, focus, fov) in
            (("game", GAME), ("front", FRONT), ("side", SIDE))}
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk, bright = tuple(floor.diffuse_color), (0.74, 0.72, 0.68, 1)
    r = scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note, r.stamp_font_size = True, 18

    big, side, tiny = (220, 250), (220, 170), (56, 64)
    game_rows = [[shoot(scene, stage, cams["game"], f, label(f), big, out)[0] for f in row] for row in GAME_ROWS]
    front_row = [shoot(scene, stage, cams["front"], f, label(f), big, out)[0] for f in ROW]
    side_row = [shoot(scene, stage, cams["side"], f, label(f), side, out)[0] for f in ROW]
    small = {"block": [shoot(scene, stage, cams["game"], f, "", tiny, out, "block") for f in STRIP],
             "dark": [shoot(scene, stage, cams["game"], f, "", tiny, out) for f in STRIP]}
    floor.diffuse_color = bright
    bright_row = [shoot(scene, stage, cams["game"], f, label(f), big, out)[0] for f in ROW]
    small["bright"] = [shoot(scene, stage, cams["game"], f, "", tiny, out) for f in STRIP]
    floor.diffuse_color = dusk
    bpy.app.handlers.frame_change_pre.remove(stage.set)
    numbers = table(stage)
    numbers["pixels_at_64"] = {key: dict(zip(map(str, STRIP), (n for _, n in tiles))) for key, tiles in small.items()}
    (out / "shade_burst_art.json").write_text(json.dumps(numbers, indent=1))
    for key, tiles in small.items():
        print(f"64 px, {key}: " + ", ".join(f"{f} {n}" for f, (_, n) in zip(STRIP, tiles)))

    W, H = 1920, 2210
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    x0 = 40
    text = [(x0, 30, 54, "THE SHADE'S BURST, THE ART", ink),
            (830, 30, 20, "The block-in's C, the sky lantern, with research's three fixes: the flame carries the read to 34,", ink),
            (830, 54, 20, "the paper rises in its column, and an ink rim holds both on a bright floor. Warm white and gold: no red.", ink)]
    # the picture, on a dark ground, a bright one, and in grey
    y = 104
    text.append((x0, y, 20, "shade_burst.png, 1024 x 768, one upload: the flame's eight frames along the top, four torn scraps of paper below", ink))
    shrunk = rs.shrink(sheet, 0.5)
    for i, (ground, grey) in enumerate(((rs.NIGHT, False), (rs.DAY, False), (rs.rgb("#77777B"), True))):
        rs.fill(page, x0 + i * 600, y + 30, 532, 404, ground)
        rs.paste(page, rs.grey(shrunk) if grey else shrunk, x0 + 10 + i * 600, y + 40)
    text.append((x0, y + 444, 15, "The flame burns upward: frames 0 and 1 it boils between while hot, to 33; then 2 to 7, eaten from its tongues and edges back to an "
                 "ember at its base: 8, 18, 32, 48, 64 and 80% gone, cooling from the core to the gold to the rim.", soft))
    text.append((x0, y + 464, 15, "The paper: frame 0 whole, a fold and an ink edge; then burnt from one side, a char line before a gold front: 10 to 90% gone. "
                 "Each frame's rectangle: the flame's n at (128 n, 0), 128 x 256; scrap s's n at (128 n, 256 + 128 s), 128 x 128.", soft))
    # the effect, played
    y = 600
    text.append((x0, y, 20, "From the player's camera: behind the Shade's right, the lead beyond it at 45 degrees, 20 studs (the clip's frames, 60 a second; Burst is 27)", ink))
    for i, row in enumerate(game_rows):
        for c, tile in enumerate(row):
            rs.paste(page, tile, x0 + c * 230, y + 28 + i * 258)
    y = 1150
    text.append((x0, y, 20, "On a bright floor", ink))
    for c, tile in enumerate(bright_row):
        rs.paste(page, tile, x0 + c * 230, y + 28)
    y = 1440
    text.append((x0, y, 20, "From the front: another Shade of the pack, facing the camera (the block-in's camera)", ink))
    for c, tile in enumerate(front_row):
        rs.paste(page, tile, x0 + c * 230, y + 28)
    y = 1730
    text.append((x0, y, 20, "From the side", ink))
    for c, tile in enumerate(side_row):
        rs.paste(page, tile, x0 + c * 230, y + 28)
    y = 1940
    text.append((x0, y, 20, "At 64 px from the player's camera: the block-in's C, then the art on dark and on bright, and in grey. Under each, the light's own pixels, without the paper", ink))
    for i, key in enumerate(("block", "dark", "bright")):
        for c, (tile, n) in enumerate(small[key]):
            rs.paste(page, tile, x0 + c * 62, y + 28 + i * 84)
            text.append((x0 + c * 62 + 2, y + 28 + i * 84 + 64, 12, f"{STRIP[c]}: {n}", soft))
        text.append((x0 + 12 * 62 + 8, y + 50 + i * 84, 14, ("the block-in", "the art, dark", "the art, bright")[i], soft))
    for c, (tile, _) in enumerate(small["dark"]):
        rs.paste(page, rs.grey(tile), x0 + 1000 + c * 62, y + 28)
    for i, words in enumerate(("The Shade's body, masks and ties hide on the Burst frame, as the game does.",
                               "The pictures are drawn flat and unlit, facing the camera, with no glow added: the game's bloom is the builder's.",
                               "shade_burst_art.json has every picture on every frame, for the builder.")):
        text.append((x0 + 1000, y + 110 + i * 22, 14, words, soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "shade_burst_art.png")
    print(f"wrote {out / 'shade_burst_art.png'} {W}x{H}")


if __name__ == "__main__":
    main()
