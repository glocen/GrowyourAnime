"""AR3, section 5: the reveal's look, the art sheet (docs/asset-requests.md; the block-in is section 4 and
reveal_blockin.py, whose form, beats and layout B research accepted). Finished here, with research's six fixes:

1. The name lands as a hit: larger, slammed to size in four frames with an overshoot, a glint along its rule, the
   screen kicked, and Rook's recoil under it (his Reveal clip's `Name` marker, rook_clips.py).
2. The name's size follows the rarity, Common's to 1.3 times at Mythical.
3. The split's flash follows the rarity: a pop held to the shard for a Common; only Legendary and Mythical white out.
4. The low rarities start the clip further in, so a Common's colours come 1.0 s after the tap.
5. The frame's base point reads from Epic up: he stands on the window's sill, the sill drawn over his soles, and the
   points hang free below it.
6. The fold keeps one readable line: Rook's head is up out of it (rook_clips.py).

Then research's three on the art (section 5): a Common's pieces clear the window before he stands (they fly out past
the frame, behind him, and fade); the colours run down him from the strike over about 8 frames; the shard answers each
rung of its climb with a swell, a tick aside and its seams burning brighter.

And the shard's finish: crystal, a dark violet cut in four flat tones with lit edges, painted into the model so the
engine's model looks the same. The three colour checks of research's verdict are their own sheet.

Run: blender -b --factory-startup --python tools/blender/reveal_art.py -- <out_dir> <mode> ...
  figure                    Rook's Reveal from its own front camera, every other frame -> <out>/figure/
  shard                     the shard's finish: grades, lines, turn, four sizes -> reveal_art_shard.png
  beats <rarity> i j        beats i to j - 1, each at 2 px a point -> beats/
  strip <rarity>            the beats put together -> reveal_art_strip_<rarity>.png
  frame <rarity> t ...      single frames at t seconds from the tap -> frame_<rarity>_<t>.png
  read <rarity> / readsheet the six: the split's flash, him dark, the name, at 1 px a point -> read/, reveal_art_rarity.png
  names / namesheet         the roster's longest names at Mythical's size, layout B -> names/, reveal_art_names.png
  colours                   research's three colour checks -> reveal_art_colours.png
  clear                     the broken pieces seen inside the window, every frame from the split -> clear.json
  movie <rarity> i j / assemble <rarity>   at 60 a second, 1 px a point -> reveal_art_<rarity>.mp4
  parts                     the engine's files -> parts/: images/, meshes/, reveal.json
  compare <rarity>          the art's frame and the engine's, laid from the parts alone, at four moments -> parts/compare/
  partsheet                 the parts at a glance, at 64 px, and the compare -> parts/reveal_parts*.png, reveal.json's checks
Text is Blender's own face, standing in for the game's. Nothing is taken from anywhere else.
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
import reveal_blockin as rb  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from reveal_blockin import add, back, blur, smooth, soft  # noqa: E402
from ui_sheet import WHITE, c  # noqa: E402

W, H, FPS, UNIT = rb.W, rb.H, rb.FPS, rb.UNIT
VIOLET = rb.VIOLET
SHEET_GROUND, INK, SOFT_INK, NOTE = "#1B1D24", "#F3EFE6", "#C9CDD6", "#FFE266"

# --- the shard's finish -----------------------------------------------------------------------------------------------

# A dark violet crystal: four flat tones by how a facet faces the light (painted into the model, not lit, so the
# engine's model is the same in a viewport, a chamber or the street), its edges cut bright, its inner walls pale where a
# seam opens onto the core. The light is the shard's own, upper left and in front.
TONES = ("#9886EC", "#5B49B2", "#33276F", "#1A1340")
EDGES = ("#F5F0FF", "#A493F0")
WALL = "#C3B3FF"
CORE = "#FFFFFF"
PALETTE = TONES + EDGES + (WALL, CORE)  # the engine's swatches, in this order
SUN = Vector((-0.66, -0.34, 0.67)).normalized()
STEPS = (0.62, 0.3, -0.1)  # the light a facet needs for each of the first three tones


def facet_normals():
    bm = rb.hull(rb.body_points())
    normals = [f.normal.copy() for f in bm.faces]
    bm.free()
    return normals


def paint(obj, sun_local):
    """Each face gets its swatch: a facet by the light on it, a bevel as an edge, a seam's face as an inner wall. A UV
    map puts every corner of a face on its swatch's middle, for the engine's palette image."""
    facets = facet_normals()
    seams = [Vector(n).normalized() for _, n in rb.SEAMS.values()]
    mesh = obj.data
    tone = mesh.color_attributes.new("Tone", "BYTE_COLOR", "CORNER")
    uv = mesh.uv_layers.new(name="Palette")
    for poly in mesh.polygons:
        n = poly.normal
        lit = n.dot(sun_local)
        if any(abs(n.dot(s)) > 0.9995 for s in seams):
            swatch = PALETTE.index(WALL)
        elif any(n.dot(f) > 0.9995 for f in facets):
            swatch = next((i for i, step in enumerate(STEPS) if lit > step), 3)
        else:
            swatch = 4 if lit > 0.15 else 5
        for li in poly.loop_indices:
            tone.data[li].color_srgb = (*ui.c(PALETTE[swatch]), 1.0)
            uv.data[li].uv = ((swatch + 0.5) / len(PALETTE), 0.5)
    mesh.color_attributes.active_color = tone
    mesh.color_attributes.render_color_index = mesh.color_attributes.find("Tone")


class Shard(rb.Shard):
    """The block-in's shard, painted."""

    def __init__(self, grade="Standard"):
        super().__init__(grade)
        for obj in list(self.pieces.values()) + [o for o in self.scene.objects if o.name.startswith("Bud")]:
            sun = obj.matrix_basis.to_3x3().inverted() @ SUN if obj.name.startswith("Bud") else SUN
            paint(obj, sun.normalized())
        paint(self.core, SUN)

    def shoot(self, out: Path, size, span, azimuth=14.0, elevation=6.0, centre=(0.0, 0.0, 0.05)):
        """Two pictures from one camera: the painted crystal, and the leak (white where the core shows through)."""
        scene, cam = self.scene, self.cam
        cam.data.ortho_scale = span
        a, e = math.radians(azimuth), math.radians(elevation)
        offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e))) * 40
        cam.location = Vector(centre) + offset
        cam.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()
        shots = []
        for leak in (False, True):
            rs.workbench(scene, size[0], size[1], flat=True)
            scene.display.shading.color_type = "OBJECT" if leak else "VERTEX"
            self.core.hide_render = not leak
            scene.render.filepath = str(out / "_shard.png")
            bpy.ops.render.render(write_still=True)
            shots.append(rs.load(out / "_shard.png"))
        (out / "_shard.png").unlink()
        return shots[0], shots[1][..., 0] * shots[1][..., 3]


def lit_lines(clay, leak, colour, k):
    """The shard with its lines lit by a colour: the crystal a little dimmed, the leak laid on as light."""
    out = clay.copy()
    add(out, colour, soft(leak, 8 * k, f=k) * 1.5)
    add(out, colour, blur(leak, 1.5 * k) * 1.4)
    add(out, WHITE, blur(leak, max(1, k // 2)) * 0.9)
    return out


def shard_sheet(out: Path):
    """The finish: its three grades, the lines it parts on, in the round, and at the four sizes it's seen at."""
    K = ui.K
    shots = {}
    for grade in rb.BUDS:
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
    sheet = ui.Sheet(1180, 760, SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The Void Shard, finished: dark violet crystal, its edges cut bright", INK)
    t.text(20, 36, 9.5, "AR3 section 5. Four flat tones by how a facet faces the shard's own light, the bevels pale, the walls inside a seam "
           "paler still. Painted into the model: the engine's model is these swatches, not lit.", SOFT_INK)
    room = c(VIOLET["panel"][1])
    for i, grade in enumerate(rb.BUDS):
        x = 20 + i * 232
        tile = sheet.tile(x, 64, 224, 260)
        tile.paint(tile.poly(ui.cut_box(0, 0, 224, 260)), room)
        tile.glow(tile.poly([(112, 130), (113, 130), (113, 131)]), 70.0, c(VIOLET["ground"]), 0.9)
        rs.paste(sheet.px, shots[grade, "big"], round((x - 38) * K), round(69 * K))
        t.text(x + 8, 72, 10, grade, INK)
    x = 20 + 3 * 232
    tile = sheet.tile(x, 64, 224, 260)
    tile.paint(tile.poly(ui.cut_box(0, 0, 224, 260)), room)
    rs.paste(sheet.px, lit_lines(*shots["lines"], c(rb.SHARD_LIGHT), K), round((x - 38) * K), round(69 * K))
    t.text(x + 8, 72, 10, "Its lines, lit: the order they open in", INK)
    for label, (lx, ly) in (("1", (180, 84)), ("2", (120, 30)), ("3", (168, 186)), ("4", (56, 196))):
        t.text(x + lx, 64 + ly, 11, label, NOTE)
    x = 20 + 4 * 232
    tile = sheet.tile(x, 64, 212, 260)
    tile.paint(tile.poly(ui.cut_box(0, 0, 212, 260)), room)
    rs.paste(sheet.px, shots["parts"][:, 44 * K:-44 * K], round(x * K), round(69 * K))
    t.text(x + 8, 72, 10, "The five pieces, parted: the walls", INK)
    t.text(20, 338, 10, "In the round (Standard): a quarter turn at a time from its front", SOFT_INK)
    for i in range(4):
        x = 20 + i * 120
        tile = sheet.tile(x, 356, 112, 150)
        tile.paint(tile.poly(ui.cut_box(0, 0, 112, 150)), room)
        rs.paste(sheet.px, rs.shrink(shots["turn", i], 0.6), round((x + 11) * K), round(356 * K))
    t.text(520, 338, 10, "The four sizes, on the reveal's dark and on a dusk street's paving. Left to right in each: Standard, Enriched, Prismatic.",
           SOFT_INK)
    sizes = (("the Breaker's chamber", 96.0, "big"), ("the bag", 40.0, "big"), ("the world's drop", 34.0, "world"))
    for j, (ground, code) in enumerate(rb.GROUNDS):
        y = 356 + j * 192
        tile = sheet.tile(520, y, 640, 184)
        tile.paint(tile.poly(ui.cut_box(0, 0, 640, 184)), c(code))
        t.text(528, y + 6, 9, ground, INK if j == 0 else "#17141F")
        x = 540.0
        for what, tall, view in sizes:
            for grade in rb.BUDS:
                shot = rs.trim(shots[grade, view])
                small = rs.shrink(shot, tall * K / 450.0)
                rs.paste(sheet.px, small, round(x * K), round((y + 150) * K) - small.shape[0])
                x += small.shape[1] / K + (16 if tall > 50 else 12)
            t.text(x - 150 if tall > 50 else x - 104, y + 160, 8.5, f"{what}, {tall:.0f} pt", INK if j == 0 else "#17141F")
            x += 30
    t.text(20, 520, 9.5, "The swatches, in the engine's palette image's order: the four tones, the two edges, the wall, the core.", SOFT_INK)
    for i, code in enumerate(PALETTE):
        sw = sheet.tile(20 + i * 58, 540, 50, 50)
        sw.paint(sw.poly(ui.cut_box(0, 0, 50, 50, 6, 0, 6, 0)), c(code))
        t.text(20 + i * 58, 596, 8, code, SOFT_INK)
    rb.finish(sheet, out / "reveal_art_shard.png")


# --- the beats --------------------------------------------------------------------------------------------------------

BIG = rb.BIG                   # the larger frame's opening, 240 by 288 points
TOP = 58.0                     # the window's top: Mythical's tallest point stands 10 points under the screen's edge
SILL = TOP + BIG[1]            # 346: the window's foot, where he stands (fix 5)
LIFT = rb.FLOOR - SILL         # the figure was shot with his soles on rb.FLOOR
GROW = 2.4                     # the larger frame's points against the small frame's, in height and width alike: the kit's
#                                condition 10 keeps a point no taller for its width than the passed crown
SILL_BAND = 16.0               # how much of the frame's foot is drawn over his soles: the line, the cuts, the base points
CX = 600.0                     # where he and the window stand once the name is down (layout B): 52 points right of the
#                                block-in's, so the roster's widest names land at their rarity's size (the names check)
STEP = (0.4, 0.3)              # he steps right from the screen's middle at this point of his clip, over this long
KNOCK, NAME = 51 / FPS, 55 / FPS   # Rook's Reveal: the ram fires; the kick's floor, where his name lands (rook_clips.py)
RARITIES = list(ui.RARITIES)
OFFSET = dict(zip(RARITIES, (0.40, 0.32, 0.18, 0.0, 0.0, 0.0)))     # fix 4: how far into the clip he appears
HOLD = dict(zip(RARITIES, (0.55, 0.65, 0.80, 0.95, 1.10, 1.25)))    # the name held before the card
NAME_SCALE = dict(zip(RARITIES, (1.0, 1.06, 1.12, 1.18, 1.24, 1.30)))  # fix 2
NAME_SIZE, NAME_LEFT, NAME_BASE = 58.0, 70.0, 214.0
WING = max(r.get("wing", 0) for r in rb.RARITIES.values()) * GROW
NAME_MAX = CX - BIG[0] / 2 - WING - 14.0 - NAME_LEFT   # the widest a name may land: 14 points short of the widest wing
SLAM = 1.7                     # the name arrives this much larger, and is down in four frames at 60
SHAKE = dict(zip(RARITIES, (2.5, 3.0, 3.5, 4.5, 5.5, 6.5)))         # points the screen kicks down as the name lands
# fix 3: the split's flash. A radius in points held to the shard, or None: the whole screen goes white.
FLASH = dict(zip(RARITIES, ((70.0, 0.55, 0.10), (95.0, 0.6, 0.11), (135.0, 0.7, 0.12), (190.0, 0.8, 0.14),
                            (None, 1.0, 0.22), (None, 1.0, 0.26))))
NAMES = dict(zip(RARITIES, ("ROOK", "SABLE", "LYRIC", "HALCYON", "STELLANE", "UMBRIEL")))
# Research's three fixes on the art (section 5):
REACH = dict(zip(RARITIES, (8.0, 8.5, 9.0, 9.5, 11.0, 11.0)))  # 1: how far the pieces fly, in the shard's units: out past
#                                                                  the frame, every rarity, before he stands
GONE = (0.18, 0.25)            # 1: the pieces fade from this long after the split, over this long
FLOOD = 0.13                   # 2: the colours run from the strike to his farthest point in about 8 frames
RUNG = dict(swell=0.05, tick=0.08, light=0.8)   # 3: a rung's answer: the shard swells, ticks aside (in its units), and
#                                                  its seams burn brighter, each as a share of its own size or light


def times(rarity):
    """Seconds from the tap: the split, the colours (the Knock), the name (the kick), the card."""
    split = rb.PLANS[rarity]["split"]
    colours = split + KNOCK - OFFSET[rarity]
    name = split + NAME - OFFSET[rarity]
    return dict(split=split, colours=colours, name=name, card=name + HOLD[rarity])


def outline(cx, top, rarity, sx=1.0, sy=1.0):
    """The larger frame's cut: the opening three times the small frame's, the corner cuts twice, the points and the
    wings 2.4 times in both directions."""
    r = rb.RARITIES[rarity]
    w, h = BIG[0] * sx, BIG[1] * sy
    x0, x1, y0, y1 = cx - w / 2, cx + w / 2, top + BIG[1] * (1 - sy) / 2, top + BIG[1] * (1 + sy) / 2
    tl, tr, br, bl_ = (v * 2.0 * min(sx, 1.0) for v in r["cut"])
    n, my = r.get("wing", 0) * GROW * sx, (y0 + y1) / 2
    pts = [(x0, y0 + tl), (x0 + tl, y0)] if tl else [(x0, y0)]
    for f, hw, hh in r.get("crest", ()):
        pts += [(x0 + w * f - hw * GROW * sx, y0), (x0 + w * f, y0 - hh * GROW * sy), (x0 + w * f + hw * GROW * sx, y0)]
    pts += [(x1 - tr, y0), (x1, y0 + tr)] if tr else [(x1, y0)]
    if n:
        pts += [(x1, my - n * 1.3), (x1 + n, my), (x1, my + n * 1.3)]
    pts += [(x1, y1 - br), (x1 - br, y1)] if br else [(x1, y1)]
    for f, hw, hh in sorted(r.get("base", ()), reverse=True):
        pts += [(x0 + w * f + hw * GROW * sx, y1), (x0 + w * f, y1 + hh * GROW * sy), (x0 + w * f - hw * GROW * sx, y1)]
    pts += [(x0 + bl_, y1), (x0, y1 - bl_)] if bl_ else [(x0, y1)]
    if n:
        pts += [(x0, my + n * 1.3), (x0 - n, my), (x0, my - n * 1.3)]
    return pts


def clear_tile(w, h):
    sheet = ui.Sheet(w, h, "#000000")
    sheet.px[:] = 0
    return sheet.tile(0, 0, w, h)


def frame_layer(cx, rarity):
    """The frame's metal alone, on nothing, the screen's size: drawn behind him, and its foot again over his soles."""
    t = clear_tile(W, H)
    rb.big_frame(t, t.poly(outline(cx, TOP, rarity)), cx, TOP, rarity)
    return t.px.copy()


def slam(u):
    """The name's size against its own at `u` seconds from landing: the engine's stamp (Rules.Reveal.Slam, with
    Config.Reveal.Stamp; TR4, research's fix 2). 1.7 times in, falling onto its place over four frames at 60, faster
    each frame, under its size on the frame it lands, then a small rebound and still. The art's first slam eased into
    its landing over three frames, and on the phone that read as a cut."""
    lead = 4 / 60
    if u < -lead - 1e-9:
        return None
    if u < 0:
        return 0.93 + (SLAM - 0.93) * (1.0 - (1.0 + u / lead) ** 2)
    return 1.0 - 0.07 * math.exp(-u / 0.03) * math.cos(u / 0.05 * math.pi)


def kick(u, rarity):
    """Points the screen sits below its rest as the name lands: down at once, a rebound, still in about 0.2 s."""
    if u < 0:
        return 0.0
    return SHAKE[rarity] * math.exp(-u / 0.05) * math.cos(u / 0.09 * 2 * math.pi)


def bump(age):
    """A rung's answer at `age` seconds: up in about 0.025 s, gone by about 0.25; 1 at its height."""
    if age < 0:
        return 0.0
    return math.exp(-age / 0.06) * (1.0 - math.exp(-age / 0.015)) / 0.5364


def run(u):
    """How far down him the colours are, 0 to 1, at `u` of their run: quick off the strike, easing down his legs."""
    return 1.0 - (1.0 - min(1.0, max(0.0, u))) ** 1.4


class Stage(rb.Stage):
    """Everything a frame is made of, kept between frames: the block-in's stage, finished, layout B only."""

    def __init__(self, out: Path, rarity, name=None, probe=False):
        self.out, self.rarity, self.layout = out, rarity, "B"
        self.plan, self.light, self.r = dict(rb.PLANS[rarity], reach=REACH[rarity]), rb.LIGHT[rarity], rb.RARITIES[rarity]
        self.when = times(rarity)
        self.probe = [] if probe else None
        self.set_name(name or NAMES[rarity])
        self.figure = rb.Figure(out)
        shot = self.figure.at(KNOCK + FLOOD / 2)   # how far the colours run: the ram's head to his farthest pixel, mid-run
        ys, xs = np.nonzero(shot[..., 3] > 0.5)
        ax, ay = self.figure.accent
        self.run = float(np.hypot(xs - ax, ys - ay).max()) + 45.0 * ui.K
        self.shard = Shard(self.plan["grade"])
        sheet = ui.Sheet(W, H, VIOLET["panel"][1])
        self.t = t = sheet.tile(0, 0, W, H)
        far = np.hypot((t.x - W / 2) / (W * 0.62), (t.y - H * 0.52) / (H * 0.8))
        room = t.ramp(VIOLET["ground"], VIOLET["panel"][1], far * 1.15)
        self.room = t.ramp(room, VIOLET["channel"], (far - 0.75) * 1.6)
        self.windows, self.frames = {}, {}

    def set_name(self, name):
        """The name's sprite, made at its slam size. Blender's text resets the scene: after the stage is built, only a
        frame past the shard's time may follow a new name."""
        size = NAME_SIZE * NAME_SCALE[self.rarity]
        self.name = rb.name_sprite(self.out, name, size * SLAM, VIOLET["text"], shear=rb.SLANT, space=1.04)
        self.wide = self.name.shape[1] / SLAM / ui.K   # its width at its rarity's size, in points
        self.fit = min(1.0, NAME_MAX / self.wide)      # a name too long for its rarity's size is set smaller, never cut
        if self.fit < 1.0:
            self.name = rs.shrink(self.name, self.fit)

    def window(self, cx, sx=1.0, sy=1.0):
        key = (round(cx), round(sx, 3), round(sy, 3))
        if key not in self.windows:
            if len(self.windows) > 3:
                self.windows.clear()
            self.windows[key] = self.t.poly(outline(cx, TOP, self.rarity, sx, sy))
        return self.windows[key]

    def metal(self, cx):
        key = round(cx)
        if key not in self.frames:
            if len(self.frames) > 2:
                self.frames.clear()
            self.frames[key] = frame_layer(cx, self.rarity)
        return self.frames[key]

    def shard_pose(self, t_):
        """The block-in's pose, and each rung of the climb answered (fix 3): a swell, and a tick aside that settles."""
        pose = super().shard_pose(t_)
        (sx, sz), (ax, az) = pose["scale"], pose["at"]
        for i, (when, _, lv, _) in enumerate(self.plan["steps"][1:]):
            age, amp = t_ - when, 0.6 + 0.4 * lv
            if 0 <= age < 0.3:
                grow = 1.0 + RUNG["swell"] * amp * bump(age)
                jolt = RUNG["tick"] * amp * math.exp(-age / 0.025) * math.cos(age / 0.05 * 2 * math.pi)
                sx, sz = sx * grow, sz * grow
                ax, az = ax + (1 if i % 2 == 0 else -1) * jolt, az + 0.35 * jolt
        pose["scale"], pose["at"] = (sx, sz), (ax, az)
        return pose

    def push(self, t_):
        """How much brighter the seams burn on a rung (fix 3): 1, up to 1 + RUNG's light just after a new colour."""
        return 1.0 + RUNG["light"] * max([bump(t_ - when) * (0.6 + 0.4 * lv) for when, _, lv, _ in self.plan["steps"][1:]] or [0.0])

    def frame(self, t_):
        t, plan, light, r, K = self.t, self.plan, self.light, self.r, ui.K
        px = t.px
        px[..., :3], px[..., 3] = self.room, 1.0
        colour, level = self.glow_at(t_)
        split, tau = plan["split"], t_ - plan["split"]
        clip = tau + OFFSET[self.rarity]          # where his clip is
        cx = W / 2 + (CX - W / 2) * smooth((clip - STEP[0]) / STEP[1])  # he steps right as he opens up, on his clip's
        #                                                                  time, so he's still before the ram fires
        cy = H / 2 - 0.05 * UNIT
        far = np.hypot(t.x - cx, t.y - cy)
        ray_colour = c(light.get("ray", light["colour"]))
        hot = colour + (WHITE - colour) * 0.55
        if level > 0:  # the room takes the light
            add(px, colour, 0.34 * level * np.exp(-(far / 300.0) ** 2))
        for when, _, lv, _ in plan["steps"][1:]:  # a ring off each step up
            age = t_ - when
            if 0 <= age < 0.3:
                add(px, colour, 0.5 * lv * (1 - age / 0.3) * np.exp(-((far - 30.0 - age * 900.0) / (10.0 + age * 60.0)) ** 2))
        framed = smooth((tau - 0.08) / 0.12)
        if tau >= 0:  # the window: the larger frame's own shape, opening from the slant's slit
            opened = back(tau / 0.16)
            d = self.window(cx, 0.03 + 0.97 * opened, 0.72 + 0.28 * smooth(tau / 0.12))
            if light["rays"]:
                add(px, ray_colour, 0.5 * opened * rb.rays(t.x, t.y, cx, TOP + BIG[1] * 0.45, light["rays"], 0.12 * tau, 250.0))
            t.glow(d, light["halo"], colour, min(1.0, 0.25 + level * 0.7))
            inside = np.clip(0.5 - d * K, 0, 1)
            lift = np.exp(-(np.hypot((t.x - cx) / 120.0, (t.y - (TOP + BIG[1] * 0.5)) / 150.0)) ** 2)
            fill = t.ramp(colour * 0.12, colour * (0.55 + 0.45 * level), lift)
            fill = fill + (WHITE - fill) * (light["core"] * lift ** 2)[..., None]
            ui.over(px, fill, inside * (0.55 + 0.45 * level))
            add(px, colour, 0.45 * level * np.exp(-((t.y - SILL) / 5.0) ** 2) * np.exp(-((t.x - cx) / 170.0) ** 2))
            if framed > 0:
                layer = self.metal(cx).copy()
                layer[..., 3] *= framed
                rs.paste(px, layer, 0, 0)
        flash = 0.0
        for when, _, lv, _ in plan["steps"][1:]:  # each step up flashes at the shard, never the screen
            if 0 <= t_ - when < 0.08:
                flash = max(flash, 0.35 * lv * (1 - (t_ - when) / 0.08))
        pieces = None
        if t_ < split + 0.7:  # the shard, and what leaks from it: over the window, behind him (fix 1)
            self.shard.pose(**self.shard_pose(t_))
            clay, leak = self.shard.shoot(self.out, (W * K, H * K), W / UNIT, centre=(0.0, 0.0, 0.05))
            clay[..., 3] *= 1.0 - smooth((tau - GONE[0]) / GONE[1])
            rs.paste(px, clay, 0, 0)
            pieces = clay[..., 3]
            if level > 0 and leak.max() > 0.01:
                leak = leak * min(1.0, level + 0.35)
                burn = self.push(t_)
                add(px, colour, soft(leak, 20 * K, f=2 * K) * 2.2 * level * burn)
                if len(plan["steps"]) > 1 and t_ > plan["steps"][1][0]:
                    add(px, colour, rb.beams(leak, cx * K, cy * K, reach=0.9 + 1.6 * level, f=2 * K) * 1.6 * level * burn)
                add(px, colour, blur(leak, 2.5 * K) * 1.8 * burn)
                add(px, WHITE, blur(leak, K / 2) * (0.55 + 0.45 * level) if K > 1 else leak * 0.8 * (0.55 + 0.45 * level))
        x0 = round((cx - rb.TILE[0] / 2) * K)
        if tau >= 0:  # the fighter: dark first, then his colours run down from the ram as it fires
            body = self.body(clip, tau, colour, level, hot)
            ax, ay = self.figure.accent
            rs.paste(px, body, x0, -round(LIFT * K))
            if self.probe is not None and pieces is not None:  # fix 1's measure: the pieces seen in the window, round him
                him, drop = np.zeros_like(pieces), round(LIFT * K)
                him[:body.shape[0] - drop, x0:x0 + body.shape[1]] = body[drop:, :, 3]
                seen = pieces * (1.0 - him)
                self.probe.append((t_, tau, float((seen * inside).sum()) / K ** 2, float(seen.sum()) / K ** 2))
            hx, hy = (x0 + ax) / K, ay / K - LIFT   # the ram's head as it fires, in points
            age = clip - KNOCK
            if 0 <= age < 0.25:  # the shot: a ring off the ram's head, every rarity, louder as it climbs
                ring = np.exp(-((np.hypot(t.x - hx, t.y - hy) - 14.0 - age * 820.0) / (5.0 + age * 40.0)) ** 2)
                add(px, hot, (0.35 + 0.5 * light["level"]) * (1 - age / 0.25) * ring)
                add(px, WHITE, 0.7 * max(0.0, 1 - age / 0.06) * np.exp(-(np.hypot(t.x - hx, t.y - hy) / 22.0) ** 2))
            if 0 <= age < 0.25 and light["rays"]:  # a rare one's strike throws its own light up
                column = np.exp(-((t.x - hx) / (7.0 + 30.0 * age / 0.25)) ** 2) * np.clip(1.2 - (t.y - hy) / 60.0, 0, 1)
                add(px, ray_colour, 0.8 * (1 - age / 0.25) * column)
        if tau >= 0 and framed > 0:  # the frame's foot over his soles: the base points hang free under it
            layer = self.metal(cx).copy()
            layer[..., 3] *= framed * np.clip((t.y - (SILL - SILL_BAND)) / 2.0, 0, 1)
            rs.paste(px, layer, 0, 0)
        if flash > 0:
            add(px, colour * 0.5 + 0.5, flash * np.exp(-(far / 110.0) ** 2))
        u = t_ - self.when["name"]
        s = slam(u)
        if s is not None:  # the name: in large, down hard, a glint along its rule
            self.draw_name(px, u, s)
        radius, strength, length = FLASH[self.rarity]
        if 0 <= tau < length:  # the split: a pop at the shard, or the whole screen white
            if radius is None:
                fade = 1.0 if tau < 0.035 else (1.0 - (tau - 0.035) / (length - 0.035)) ** 1.5
                add(px, WHITE, np.full(far.shape, strength * fade, dtype=np.float32))
            else:
                add(px, WHITE, strength * (1 - tau / length) ** 2 * np.exp(-(far / radius) ** 2))
        dy = round(kick(u, self.rarity) * K)
        if dy:
            px = np.roll(px, dy, axis=0)
            if dy > 0:
                px[:dy] = px[dy]
            else:
                px[dy:] = px[dy - 1]
        return px.copy()

    def body(self, clip, tau, colour, level, hot):
        """The fighter's tile at a point of his clip: dark with a rim of the light, and from the strike his colours
        running down him from the ram's head (fix 2), a hot line ahead of them."""
        K = ui.K
        shot = self.figure.at(clip)
        alpha = shot[..., 3]
        flood = (clip - KNOCK) / FLOOD   # fix 2: 0 at the strike, 1 once the colours reach his farthest point
        ax, ay = self.figure.accent
        yy, xx = np.mgrid[0:shot.shape[0], 0:shot.shape[1]].astype(np.float32)
        reach = np.hypot(xx - ax, yy - ay)
        edge = self.run * run(flood)
        lit = np.clip((edge - reach) / (45.0 * K), 0, 1) if flood > 0 else np.zeros_like(alpha)
        body = shot.copy()
        dark = c(VIOLET["channel"])
        body[..., :3] = dark + (shot[..., :3] - dark) * lit[..., None]
        rim = np.clip((alpha - blur(alpha, 2 * K)) * 2.6, 0, 1)
        rim = rim * (1 - lit) * min(1.0, 0.45 + 0.55 * level) * back(tau / 0.16)
        body[..., :3] = body[..., :3] + (colour - body[..., :3]) * (rim * 0.8)[..., None]
        if 0 < flood < 1.3:  # the line the colours come in behind
            band = np.exp(-((reach - edge + 22.5 * K) / (25.0 * K)) ** 2) * alpha * (1.0 - flood / 1.3) * 0.8
            body[..., :3] = body[..., :3] + (hot - body[..., :3]) * band[..., None]
        body[..., 3] *= smooth((tau - 0.03) / 0.08)   # in once the pop has cleared the shard, never a ghost through it
        return body

    def draw_name(self, px, u, s):
        t, r, K = self.t, self.r, ui.K
        sprite = rs.shrink(self.name, s / SLAM)   # whole from its first frame: a hit doesn't fade in
        burn = max(0.0, 1.0 - max(u, 0.0) / 0.14) ** 2   # it arrives white-hot and cools to the room's ivory
        sprite[..., :3] = sprite[..., :3] + (WHITE - sprite[..., :3]) * burn
        width, height = self.name.shape[1] / SLAM, self.name.shape[0] / SLAM   # its size once down, in pixels
        mx, my = NAME_LEFT * K + width / 2, NAME_BASE * K - height / 2
        # it grows from a point on its foot, a quarter in: it comes down onto its rule, and the widest a name may land
        # still clears the screen's left edge at 1.7 times
        rs.paste(px, sprite, round(NAME_LEFT * K + 0.25 * (width - sprite.shape[1])), round(NAME_BASE * K - sprite.shape[0]))
        landed = smooth((u + 0.02) / 0.03)
        if landed <= 0:
            return
        right = NAME_LEFT + width / K
        end = min(right + 22.0, NAME_LEFT + NAME_MAX + 6.0)
        rule = t.poly([(NAME_LEFT - 6.0, NAME_BASE + 12.0), (end, NAME_BASE + 12.0),
                       (end - 6.0, NAME_BASE + 17.0), (NAME_LEFT - 10.0, NAME_BASE + 17.0)])
        metal = t.ramp(r["metal"][0], r["metal"][1], (t.y - TOP) / BIG[1])
        t.paint(rule, metal, landed)
        if u >= 0:
            run = u / 0.2   # the glint runs the rule's length in 0.2 s and is gone by 0.3
            gx = NAME_LEFT - 10.0 + run * (right + 32.0 - NAME_LEFT)
            band = np.exp(-((t.x - gx) / 14.0) ** 2) * np.clip(0.5 - rule * K, 0, 1) * max(0.0, 1 - u / 0.3)
            add(px, WHITE, band * 1.4)
            add(px, c(self.light["colour"]), 0.6 * max(0.0, 1 - u / 0.3) * np.exp(-(((t.x - gx) / 22.0) ** 2 + ((t.y - NAME_BASE - 14.5) / 9.0) ** 2)))
            add(px, WHITE, 0.3 * max(0.0, 1 - u / 0.1) * np.exp(-(((t.x - mx / K) / (width / K * 0.6)) ** 2 + ((t.y - my / K) / 40.0) ** 2)))


# --- the sheets -------------------------------------------------------------------------------------------------------

def beats_of(rarity):
    w = times(rarity)
    split, colours, name, card = w["split"], w["colours"], w["name"], w["card"]
    if rarity == "Common":
        return ((-0.1, "the shard waits"), (0.05, "the tap: the slant opens"), (0.3, "its lines, one by one"),
                (0.5, "it swells"), (split + 0.017, "the split: a pop at the shard"), (split + 0.11, "the window; him dark"),
                (colours - 0.12, "the ram up, still dark (skip from 1.0)"), (colours + 0.017, "it fires; the name comes in"),
                (name - 0.025, "the name slams in"), (name + 0.033, "down: the kick, the glint"),
                (name + 0.15, "the glint off the rule's end"), (card, "held, the card next"))
    return ((-0.1, "the shard waits"), (0.05, "the tap: the slant opens"), (0.36, "green: past Common"), (0.54, "blue"),
            (0.72, "purple"), (0.98, "gold (skip from 1.0)"), (1.24, "the breath: dark, drawn in"),
            (split + 0.02, "the split: the screen goes white"), (split + 0.2, "the window: three points; his head up"),
            (colours + 0.017, "it fires; the name comes in"), (name + 0.033, "down: the kick, the glint"), (card - 0.02, "held, the card next"))


def beats(out: Path, rarity, first, last):
    stage = Stage(out, rarity)
    (out / "beats").mkdir(exist_ok=True)
    for i, (when, _) in list(enumerate(beats_of(rarity)))[first:last]:
        rs.save(stage.frame(when), out / "beats" / f"{rarity}_{i:02d}.png")


def strip(out: Path, rarity):
    shown = beats_of(rarity)
    tiles = [rs.shrink(rs.load(out / "beats" / f"{rarity}_{i:02d}.png"), 0.5) for i in range(len(shown))]
    cols, gap, top = 4, 8.0, 64.0
    tw, th = W / 2, H / 2
    rows = math.ceil(len(tiles) / cols)
    sheet = ui.Sheet(20 * 2 + cols * tw + (cols - 1) * gap, top + rows * (th + 26.0) + 8, SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    w = times(rarity)
    t.text(20, 12, 15, f"The reveal, the art: {rarity}, from a {rb.PLANS[rarity]['grade']} shard", INK)
    t.text(20, 36, 9.5, f"AR3 section 5. The full-screen camera at 1 pixel a point, on Void Violet, layout B. Seconds from the tap. The split at "
           f"{w['split']:.2f}, the colours at {w['colours']:.2f}, the name at {w['name']:.2f}, the card at {w['card']:.2f}. Rook's model"
           + (" standing in for a Legendary" if rarity != "Common" else "") + ", Blender's face for the type.", SOFT_INK)
    for i, tile in enumerate(tiles):
        row, col = divmod(i, cols)
        x, y = 20 + col * (tw + gap), top + row * (th + 26.0)
        rs.paste(sheet.px, tile, round(x * ui.K), round(y * ui.K))
        when, label = shown[i]
        t.text(x, y + th + 5, 9.5, f"{when:.2f} s", NOTE)
        t.text(x + 44, y + th + 5, 9.5, label, "#E6E8EE")
    rb.finish(sheet, out / f"reveal_art_strip_{rarity}.png")


def read_moments(rarity):
    w = times(rarity)
    return ((w["split"] + 0.017, "the split's flash"), (w["split"] + 0.2, "him dark in the window"),
            (w["name"] + 0.15, "the name down, the glint gone"))


def read_frames(out: Path, rarity):
    rb.set_scale(1)
    stage = Stage(out, rarity)
    (out / "read").mkdir(exist_ok=True)
    for i, (when, _) in enumerate(read_moments(rarity)):
        rs.save(stage.frame(when), out / "read" / f"{rarity}_{i}.png")


def read_sheet(out: Path):
    rb.set_scale(2)
    tw, th, gap, left, top = 253.0, 117.0, 8.0, 112.0, 74.0
    sheet = ui.Sheet(left + 3 * (tw + gap) + 12, top + 6 * (th + gap) + 8, SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal, the art: the six read apart", INK)
    t.text(20, 36, 9.5, "AR3 section 5. Each rarity at three moments, at 1 pixel a point shown at 0.6: the split's flash "
           "(fix 3), him dark in the window 0.2 s after it, and the name down (fix 2). Rook's model stands in for each.", SOFT_INK)
    for j, (_, label) in enumerate(read_moments("Common")):
        t.text(left + j * (tw + gap), top - 16, 9.5, label, "#E6E8EE")
    for i, rarity in enumerate(RARITIES):
        y = top + i * (th + gap)
        w = times(rarity)
        t.text(20, y + 4, 12, rarity, INK)
        t.text(20, y + 22, 9, f"{rb.PLANS[rarity]['grade']} shard", SOFT_INK)
        t.text(20, y + 36, 9, f"split {w['split']:.2f} s", SOFT_INK)
        t.text(20, y + 48, 9, f"colours {w['colours']:.2f} s", SOFT_INK)
        t.text(20, y + 60, 9, f"name {w['name']:.2f} s", SOFT_INK)
        t.text(20, y + 72, 9, f"card {w['card']:.2f} s", SOFT_INK)
        radius, _, length = FLASH[rarity]
        t.text(20, y + 88, 9, f"flash {length:.2f} s:", NOTE)
        t.text(20, y + 100, 9, "the screen white" if radius is None else f"{radius:.0f} points round", NOTE)
        for j in range(3):
            shot = rs.load(out / "read" / f"{rarity}_{j}.png")
            tile = rs.shrink(shot, tw * ui.K / shot.shape[1])   # the frame at 1 pixel a point, to its slot on the sheet
            rs.paste(sheet.px, tile, round((left + j * (tw + gap)) * ui.K), round(y * ui.K))
    rb.finish(sheet, out / "reveal_art_rarity.png")


VOIDKIN = Path(__file__).resolve().parents[2] / "src" / "shared" / "Definitions" / "Voidkin.luau"


def roster():
    """Every Voidkin's name and rarity, read from the game's own definitions."""
    import re
    rows = re.findall(r'Name = "([^"]+)", Rarity = "(\w+)"', VOIDKIN.read_text(encoding="utf-8"))
    return [(name.upper(), rarity) for name, rarity in rows]


def names_frames(out: Path):
    """Every name in the roster measured at its own rarity's size, and at Mythical's (research's check); the six
    widest at their own size drawn held, layout B, each on its own rarity's stage."""
    (out / "names").mkdir(exist_ok=True)
    fits = {}
    for name, rarity in roster():
        sprite = rb.name_sprite(out, name, NAME_SIZE * NAME_SCALE[rarity] * SLAM, VIOLET["text"], shear=rb.SLANT, space=1.04)
        wide = sprite.shape[1] / SLAM / ui.K
        mythical = wide * NAME_SCALE["Mythical"] / NAME_SCALE[rarity]
        fits[name] = dict(rarity=rarity, points=round(wide, 1), fit=round(min(1.0, NAME_MAX / wide), 3),
                          mythical=round(mythical, 1), mythical_fit=round(min(1.0, NAME_MAX / mythical), 3))
    shown = sorted(fits, key=lambda n: -fits[n]["points"])[:6]
    for rarity in RARITIES:   # one stage a rarity; only held frames follow a new name (Stage.set_name)
        mine = [n for n in shown if fits[n]["rarity"] == rarity]
        if mine:
            stage = Stage(out, rarity, mine[0])
            for name in mine:
                stage.set_name(name)
                rs.save(stage.frame(stage.when["card"] - 0.02), out / "names" / f"{name}.png")
    (out / "names" / "fits.json").write_text(json.dumps(dict(max=round(NAME_MAX, 1), shown=shown, names=fits), indent=1),
                                             encoding="utf-8", newline="\n")
    print(json.dumps({n: fits[n] for n in shown}))


def names_sheet(out: Path):
    found = json.loads((out / "names" / "fits.json").read_text(encoding="utf-8"))
    fits, shown = found["names"], found["shown"]
    squeezed = sorted((f["mythical_fit"], n) for n, f in fits.items() if f["mythical_fit"] < 1)
    tw, th, gap, top = W / 2, H / 2, 8.0, 88.0
    sheet = ui.Sheet(40 + 2 * tw + gap, top + 3 * (th + 30) + 8, SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal, the art: the roster's widest names, each at its own rarity's size", INK)
    t.text(20, 36, 9.5, f"AR3 section 5, fix 2. A name is {NAME_SIZE:.0f} points at Common, {NAME_SCALE['Mythical']:.2f} times at "
           f"Mythical, and lands no wider than {NAME_MAX:.0f} points: a wider one is set smaller, never cut.", SOFT_INK)
    t.text(20, 50, 9.5, f"All {len(fits)} names from the game's definitions (Voidkin.luau); the six widest, held, layout B, "
           "half size.", SOFT_INK)
    t.text(20, 66, 9.5, "Research's check, every name at Mythical's size: "
           + ("all fit." if not squeezed else ", ".join(f"{n.title()} set at {f:.2f}" for f, n in squeezed)
              + f"; the rest fit."), NOTE)
    for i, name in enumerate(shown):
        row, col = divmod(i, 2)
        x, y = 20 + col * (tw + gap), top + row * (th + 30)
        rs.paste(sheet.px, rs.shrink(rs.load(out / "names" / f"{name}.png"), 0.5), round(x * ui.K), round(y * ui.K))
        f = fits[name]
        said = "fits" if f["fit"] >= 1 else f"set at {f['fit']:.2f} to fit"
        t.text(x, y + th + 5, 9.5, f"{name.title()}, {f['rarity']}: {f['points']:.0f} points at its size, {said}", "#E6E8EE")
    rb.finish(sheet, out / "reveal_art_names.png")


# --- the colour checks (AR3 section 4: the director's rarity colours, settled with three checks) ----------------------

PAIRS = (("Uncommon", "Technique"), ("Rare", "Agility"), ("Epic", "Intelligence"))
GRAPHITE = dict(ui.THEMES["Graphite Dark"], accent=ui.LIGHT, core=0.5)   # the kit's Graphite row (ui_kit.PALETTES)
GROUNDS = (("Graphite", GRAPHITE["panel"][0]), ("Void Violet", VIOLET["panel"][0]), ("black", "#0A0B0F"))


def oklab(code):
    lin = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in (int(code[i:i + 2], 16) / 255 for i in (1, 3, 5))]
    lms = [sum(m * v for m, v in zip(row, lin)) ** (1 / 3) for row in (
        (0.4122214708, 0.5363325363, 0.0514459929), (0.2119034982, 0.6806995451, 0.1073969566),
        (0.0883024619, 0.2817188376, 0.6299787005))]
    return tuple(sum(m * v for m, v in zip(row, lms)) for row in (
        (0.2104542553, 0.7936177850, -0.0040720468), (1.9779984951, -2.4285922050, 0.4505937099),
        (0.0259040371, 0.7827717662, -0.8086757660)))


def oklch(code):
    L, a, b = oklab(code)
    return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360


def distance(one, two):
    return math.dist(oklab(one), oklab(two))


def tinted_kit():
    """The kit's slices, its frames in the director's hues on Uncommon, Rare and Epic (ui_sheet.RARITIES)."""
    import ui_kit as kit
    kit.IMAGES.clear()
    ui.K = kit.K
    kit.panels()
    kit.buttons()
    kit.frames()
    kit.icons()
    return kit


def grey(px):
    out = px.copy()
    out[..., :3] = (px[..., :3] @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32))[..., None]
    return out


def zoom(px, n):
    return np.repeat(np.repeat(px, n, axis=0), n, axis=1)


def colours_sheet(out: Path):
    face = ui.portrait()
    kit = tinted_kit()

    def piece(rarity, type_, ground, wide=64):  # the full cut as the engine layers it, `wide` pixels across
        st = kit.Stage(92, 108, ground)
        kit.frame(st, 6, 6, rarity, GRAPHITE, face, type_=type_)
        return rs.shrink(st.px, wide / (80 * kit.K))

    ui.K = 2
    sheet = ui.Sheet(1200, 720, SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal, the art: the three colour checks of the director's rarity colours", INK)
    t.text(20, 36, 9.5, "AR3 section 5, for section 4's checks. The kit's full cut with the director's metals, as the engine "
           "layers it. Distances are OKLab's (0 is one colour; about 0.02 is the least two flat colours are told apart).", SOFT_INK)
    # one: the near gem pairs, 64 px wide over dark
    y = 70.0
    t.text(20, y, 12, "1. The near pairs at 64 px: a type gem in its dark seat on the frame of its own hue", INK)
    for i, (rarity, type_) in enumerate(PAIRS):
        x = 20 + i * 390.0
        for j, (_, ground) in enumerate(GROUNDS):
            rs.paste(sheet.px, piece(rarity, type_, ground), round((x + j * 40) * ui.K), round((y + 24) * ui.K))
        rs.paste(sheet.px, grey(piece(rarity, type_, GROUNDS[0][1])), round((x + 120) * ui.K), round((y + 24) * ui.K))
        rs.paste(sheet.px, zoom(piece(rarity, type_, GROUNDS[0][1]), 3), round((x + 166) * ui.K), round((y + 24) * ui.K))
        gem, deep = ss_types()[type_], rb.RARITIES[rarity]["metal"][1]
        hg, hm = oklch(gem)[2], oklch(deep)[2]
        t.text(x, y + 166, 9.5, f"{type_} on {rarity}: gem {gem}, the metal's deep end {deep}", "#E6E8EE")
        t.text(x, y + 179, 9, f"apart by {distance(gem, deep):.3f}, hue {hg:.0f} against {hm:.0f} degrees", SOFT_INK)
        t.text(x, y + 191, 9, "Graphite, Void Violet, black; in grey; three times", SOFT_INK)
    # two: Rare's blue beside Frost's light
    y = 290.0
    rare, frost = rb.HUES["Rare"], ui.ELEMENTS["Frost"]
    t.text(20, y, 12, "2. Rare's blue beside Frost's light", INK)
    for i, (word, code) in enumerate((("Rare", rare), ("Frost", frost))):
        L, C, h = oklch(code)
        kit.chip(sheet, (20 + i * 110) * ui.K, (y + 24) * ui.K, 100 * ui.K, 56 * ui.K, code)
        t.text(20 + i * 110, y + 86, 9.5, f"{word} {code}", "#E6E8EE")
        t.text(20 + i * 110, y + 99, 9, f"L {L:.2f}  C {C:.3f}  h {h:.0f}", SOFT_INK)
    t.text(20, y + 114, 9, f"apart by {distance(rare, frost):.3f}, {oklch(frost)[2] - oklch(rare)[2]:+.0f} degrees of hue", SOFT_INK)
    st = kit.Stage(330, 124, GRAPHITE["panel"][0])  # a Rare Frost Voidkin's card, as the collection lays it
    kit.frame(st, 10, 14, "Rare", GRAPHITE, face, type_="Agility")
    st.icon("ElementFrost", 112, 26, kit.BOX * 6.0 / 12.0)
    st.icon("ClassMage", 128, 26, kit.BOX * 5.5 / 13.0)
    st.text(140, 20, 14, "Lyric", GRAPHITE["text"])
    st.text(106, 46, 22, "112", frost)
    st.text(170, 46, 22, "112", rare)
    st.text(106, 82, 9, "a Frost hit, and the same in Rare's blue", GRAPHITE["soft"])
    rs.paste(sheet.px, rs.shrink(st.px, ui.K / kit.K), round(250 * ui.K), round((y + 24) * ui.K))
    sheet.items += [dict(item, x=250 + item["x"], y=y + 24 + item["y"]) for item in st.items]
    glow = ui.Sheet(300, 124, VIOLET["panel"][1])   # the reveal's light: a Rare window's, and a Frost hit's in the street
    g = glow.tile(0, 0, 300, 124)
    for gx, code in ((80, rare), (220, frost)):
        far = np.hypot(g.x - gx, g.y - 62)
        add(g.px, c(code), 0.9 * np.exp(-(far / 34.0) ** 2))
        add(g.px, WHITE, 0.6 * np.exp(-(far / 10.0) ** 2))
    rs.paste(sheet.px, glow.px, round(600 * ui.K), round((y + 24) * ui.K))
    t.text(600, y + 154, 9, "the two lights on the reveal's violet: Rare's window, a Frost hit", SOFT_INK)
    # three: a rarity's green and a state's green
    y = 470.0
    good = ui.GOOD
    t.text(20, y, 12, "3. A rarity's green comes with its frame's shape; a state's green comes with words", INK)
    st = kit.Stage(420, 124, GRAPHITE["panel"][0])
    kit.frame(st, 10, 14, "Uncommon", GRAPHITE, face, type_="Technique")
    kit.button(st, 110, 22, 120, 44, "Done", GRAPHITE, "succeeded")
    st.text(250, 26, 22, "+240", ui.NUMBER["heal"])
    st.text(110, 82, 9, "the server's yes, and a heal's number", GRAPHITE["soft"])
    for k, px in enumerate((st.px, grey(st.px))):
        rs.paste(sheet.px, rs.shrink(px, ui.K / kit.K), round((20 + k * 430) * ui.K), round((y + 24) * ui.K))
        sheet.items += [dict(item, x=20 + k * 430 + item["x"], y=y + 24 + item["y"]) for item in st.items]
    u = rb.HUES["Uncommon"]
    t.text(20, y + 154, 9.5, f"Uncommon {u}, the server's yes {good}, a heal {ui.NUMBER['heal']}", "#E6E8EE")
    t.text(20, y + 167, 9, f"apart by {distance(u, good):.3f} and {distance(u, ui.NUMBER['heal']):.3f}: one green. The frame's cut "
           "and its gem carry the rarity; the tick and the word carry the state; the number says what it is.", SOFT_INK)
    t.text(450, y + 154, 9, "in grey: what's left when the colour is gone", SOFT_INK)
    rb.finish(sheet, out / "reveal_art_colours.png")


def ss_types():
    import shade_sheet as ss
    return ss.TYPES


def clear(out: Path):
    """Fix 1's measure: for each rarity, the broken pieces seen inside the window (not behind him), in square points,
    every frame from the split, and when they're last seen there."""
    rb.set_scale(1)
    found = {}
    for rarity in RARITIES:
        stage = Stage(out, rarity, probe=True)
        for i in range(round(0.6 * FPS)):
            stage.frame(stage.plan["split"] + i / FPS)
        rows = stage.probe
        last = max((tau for _, tau, inwin, _ in rows if inwin > 12.0), default=0.0)
        found[rarity] = dict(last=round(last, 3), at=[[round(tau, 3), round(inwin), round(seen)] for _, tau, inwin, seen in rows[::3]])
        print(rarity, f"last seen in the window (over 12 sq pt) at {last:.3f} s after the split; he stands at "
              f"{0.11:.2f}; window opens by 0.16")
        print("  ", " ".join(f"{tau:.2f}:{inwin:.0f}" for _, tau, inwin, _ in rows[:24:2]))
    (out / "clear.json").write_text(json.dumps(found, indent=1), encoding="utf-8", newline="\n")


MOVIE = (-0.3, 0.5)


def movie_length(rarity):
    return round((times(rarity)["card"] + MOVIE[1] - MOVIE[0]) * FPS) + 1


def movie(out: Path, rarity, first, last):
    """Movie frames first to last - 1, at 60 a second and 1 pixel a point."""
    rb.set_scale(1)
    stage = Stage(out, rarity)
    folder = out / f"movie_{rarity}"
    folder.mkdir(exist_ok=True)
    for i in range(first, min(last, movie_length(rarity))):
        rs.save(stage.frame(MOVIE[0] + i / FPS), folder / f"{i:04d}.png")


def assemble(out: Path, rarity):
    folder = out / f"movie_{rarity}"
    missing = [i for i in range(movie_length(rarity)) if not (folder / f"{i:04d}.png").exists()]
    if missing:
        raise SystemExit(f"{len(missing)} frames missing in {folder}, the first {missing[0]}")
    rb.frames_to_movie.assemble(folder, out / f"reveal_art_{rarity}.mp4", FPS)


# --- the engine's parts -----------------------------------------------------------------------------------------------

# What the builder's reveal is made of. The UI has no adding blend, so every light is an image laid over, white or in
# its own colour, its strength its cover, tinted by the engine. The shard is meshes on one palette, for a ViewportFrame
# lit flat. reveal.json holds every number and rule a frame is made of. EngineStage lays the frame from these files
# alone, as the engine would, beside the art's frame: what the engine can draw, seen against what was drawn.

GAP = 0.045                       # a seam's width once its snap has settled, in the shard's units: the leak cells' own
RINGS = (0.33, 0.2, 0.12, 0.07)   # the ring cells: a ring's width against its radius
RAYS_SPAN = 1520.0                # points across a rays image: past the screen's corners from anywhere the window stands
COLUMN = (400.0, 72.0)            # the column's image reaches this far above the ram's head, and this far below
SEAM_ORDER = "ABCD"
PIECE_NAMES = [name for name, _ in rb.PIECES]
BUD_NAMES = ("BudFoot", "BudSliver")   # in the order a grade grows them: Enriched the first, Prismatic both
VIEW_FOV = 2.0                    # degrees: the ViewportFrames' cameras, far off and narrow, so near enough flat
CORE_SWATCH = len(PALETTE) - 1


def parts_dir(out: Path):
    return out / "parts"


def blank(w, h, k):
    """A transparent picture w by h points at k pixels a point (the drawing scale is left at k)."""
    rb.set_scale(k)
    return clear_tile(w, h)


def cut(px, pad=2):
    """Trimmed to what's drawn in it, kept `pad` pixels clear, and where the cut began."""
    ys, xs = np.nonzero(px[..., 3] > 1.0 / 255)
    y0, x0 = max(int(ys.min()) - pad, 0), max(int(xs.min()) - pad, 0)
    y1, x1 = min(int(ys.max()) + 1 + pad, px.shape[0]), min(int(xs.max()) + 1 + pad, px.shape[1])
    return px[y0:y1, x0:x1].copy(), x0, y0


def white(alpha):
    px = np.ones(alpha.shape + (4,), np.float32)
    px[..., 3] = np.clip(alpha, 0, 1)
    return px


def hexa(colour):
    return "#" + "".join(f"{round(float(v) * 255):02X}" for v in np.clip(colour, 0, 1))


def room_image():
    t = blank(W, H, 1024 / W)
    far = np.hypot((t.x - W / 2) / (W * 0.62), (t.y - H * 0.52) / (H * 0.8))
    room = t.ramp(VIOLET["ground"], VIOLET["panel"][1], far * 1.15)
    t.px[..., :3], t.px[..., 3] = t.ramp(room, VIOLET["channel"], (far - 0.75) * 1.6), 1.0
    return t.px.copy()


def glow_image(n=256):
    """One soft dot for every round light: its cover exp(-(r / s) ** 2), the picture 6 s across."""
    g = ((np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1) * 3
    x, y = np.meshgrid(g, g)
    return white(np.exp(-(x * x + y * y)))


def rings_image(n=512):
    """Four rings, one a cell, each a width against its radius: exp(-((r - R) / (q R)) ** 2)."""
    px = np.zeros((2 * n, 2 * n, 4), np.float32)
    px[..., :3] = 1.0
    g = np.arange(n, dtype=np.float32) + 0.5 - n / 2
    x, y = np.meshgrid(g, g)
    r, cells = np.hypot(x, y), {}
    for i, q in enumerate(RINGS):
        R = (n / 2 - 4) / (1 + 3 * q)
        row, col = divmod(i, 2)
        px[row * n:(row + 1) * n, col * n:(col + 1) * n, 3] = np.exp(-((r - R) / (q * R)) ** 2)
        cells[f"{q:g}"] = dict(rect=[col * n, row * n, n, n], ratio=q, radius=round(R / n, 5))
    return px, cells


def column_image(w=64, h=1024):
    """A rare strike's column: exp(-(x / wd) ** 2) across, 6 wd wide; full above the head, gone 72 points below it."""
    up, down = COLUMN
    xs = ((np.arange(w, dtype=np.float32) + 0.5) / w * 2 - 1) * 3
    ys = (np.arange(h, dtype=np.float32) + 0.5) / h * (up + down) - up
    return white(np.exp(-xs[None, :] ** 2) * np.clip(1.2 - ys[:, None] / 60.0, 0, 1))


def rays_image(count, n=1024):
    g = (np.arange(n, dtype=np.float32) + 0.5) / n * RAYS_SPAN - RAYS_SPAN / 2
    x, y = np.meshgrid(g, g)
    keep = np.clip((RAYS_SPAN / 2 - np.hypot(x, y)) / 60.0, 0, 1)
    return white(0.5 * rb.rays(x, y, 0.0, 0.0, count, 0.0, 250.0) * keep)


def window_images(rarity):
    """The window's three: its halo (1 pixel a point, smooth), its fill and its frame (2 pixels a point). Each with
    the window's middle, the point it scales about as it opens, as a share of the picture."""
    light = rb.LIGHT[rarity]
    colour, level = c(light["colour"]), light["level"]
    pts = outline(0.0, TOP, rarity)
    bx0, bx1 = min(p[0] for p in pts), max(p[0] for p in pts)
    by0, by1 = min(p[1] for p in pts), max(p[1] for p in pts)
    made = {}
    for part, k, margin in (("halo", 1, 3.3 * light["halo"]), ("window", 2, 2.0), ("frame", 2, 44.0)):
        t = blank(bx1 - bx0 + 2 * margin, by1 - by0 + 2 * margin, k)
        lx, top = margin - bx0, TOP - by0 + margin
        d = t.poly(outline(lx, top, rarity))
        if part == "halo":
            t.glow(d, light["halo"], colour, min(1.0, 0.25 + level * 0.7))
        elif part == "window":
            inside = np.clip(0.5 - d * k, 0, 1)
            lift = np.exp(-(np.hypot((t.x - lx) / 120.0, (t.y - (top + BIG[1] * 0.5)) / 150.0)) ** 2)
            fill = t.ramp(colour * 0.12, colour * (0.55 + 0.45 * level), lift)
            fill = fill + (WHITE - fill) * (light["core"] * lift ** 2)[..., None]
            ui.over(t.px, fill, inside * (0.55 + 0.45 * level))
        else:
            rb.big_frame(t, d, lx, top, rarity)
        px, x0, y0 = cut(t.px)
        made[part] = (px, k, ((lx * k - x0) / px.shape[1], ((top + BIG[1] / 2) * k - y0) / px.shape[0]))
    return made


def rule_image(span=120.0, k=2):
    """The name's rule in white, for a nine-slice: its left end leans 4 points over its 5, its right end 6."""
    t = blank(span + 4.0, 9.0, k)
    t.paint(t.poly([(6.0, 2.0), (span + 2.0, 2.0), (span - 4.0, 7.0), (2.0, 7.0)]), WHITE)
    return t.px.copy()


def palette_image(swatch=32, high=32):
    px = np.ones((high, swatch * len(PALETTE), 4), np.float32)
    for i, code in enumerate(PALETTE):
        px[:, i * swatch:(i + 1) * swatch, :3] = c(code)
    return px


def shelf(cells, limit=1024):
    """Packs pictures into one, row by row, tallest first: their places, and the whole's size."""
    order = sorted(cells, key=lambda k: -cells[k].shape[0])
    x = y = row = 0
    places = {}
    for k in order:
        h, w = cells[k].shape[:2]
        if x + w > limit:
            x, y, row = 0, y + row, 0
        places[k] = (x, y)
        x, row = x + w, max(row, h)
    width = max(places[k][0] + cells[k].shape[1] for k in order)
    height = max(places[k][1] + cells[k].shape[0] for k in order)
    if width > limit or height > limit:
        raise SystemExit(f"the atlas is {width} by {height}, past {limit}")
    sheet = np.zeros((height, width, 4), np.float32)
    for k, (x, y) in places.items():
        sheet[y:y + cells[k].shape[0], x:x + cells[k].shape[1]] = cells[k]
    return sheet, places


def shard_camera(shard):
    """Where the shard's root lands on the screen, and how a move of it shows: points a unit of X and of Z."""
    from bpy_extras.object_utils import world_to_camera_view
    scene, cam = shard.scene, shard.cam

    def screen(p):
        v = world_to_camera_view(scene, cam, Vector(p))
        return (v.x * W, (1.0 - v.y) * H)

    o, x, z = screen((0, 0, 0)), screen((1, 0, 0)), screen((0, 0, 1))
    return dict(origin=[round(o[0], 3), round(o[1], 3)],
                per_x=[round(x[0] - o[0], 3), round(x[1] - o[1], 3)], per_z=[round(z[0] - o[0], 3), round(z[1] - o[1], 3)])


RUNG_WIDTHS = tuple(wide for _, _, _, wide in (rb.SHARD,) + rb.CLIMB)


def leak_sets():
    """The leak's sets of cells, in the order the shard goes through them: the seams cracked one by one (A, AB, ABC,
    at their width), then all four at each rung's width. Each: which seams are open, how wide, the level its beams
    are thrown at, and how far the shard has risen when they show (the art's beams spread from the screen's middle,
    not from the risen shard)."""
    first = rb.SHARD[2]
    out = [dict(seams=SEAM_ORDER[:n], width=1.0, lv=first, beam_lv=rb.CLIMB[0][2], rise=0.0) for n in (1, 2, 3)]
    for when, _, lv, wide in (rb.SHARD,) + rb.CLIMB:
        out.append(dict(seams=SEAM_ORDER, width=wide, lv=lv, beam_lv=max(lv, rb.CLIMB[0][2]),
                        rise=0.25 * smooth((when + 0.05 - 0.4) / 0.6)))
    return out


def widen_at(plan, t_):
    """How far the rungs have widened the seams: the art's own rule."""
    widen = 1.0
    for when, _, _, wide in plan["steps"]:
        if t_ >= when:
            widen = max(widen, 1.0 + (wide - 1.0) * smooth((t_ - when) / 0.08))
    return widen


def leak_pick(plan, t_):
    """Which leak sets show at a time, how much of each, and how much stronger than its own width the light runs
    (a seam snaps open past its width, and a rung widens the seams while they still crack)."""
    snaps = [rb.snap(t_ - t0) for t0 in plan["cracks"]]
    n = sum(1 for t0 in plan["cracks"] if t_ >= t0)
    if n == 0:
        return [], 0.0
    over = max(1.0, sum(snaps[:n]) / n)
    widen = widen_at(plan, t_)
    if n < 4 or snaps[3] < 1.0:
        f = min(1.0, snaps[n - 1])
        return ([(n - 2, 1.0 - f), (n - 1, blend(f))] if n > 1 else [(0, f)]), over * widen
    picked = shares(widen, RUNG_WIDTHS)
    if len(picked) == 2:
        (lo, f0), (hi, f) = picked
        picked = [(lo, f0), (hi, blend(f))]
    return [(3 + j, share) for j, share in picked], over


def blend(f):
    """The upper set's share as two sets cross: one laid over the other at 1 - f and f dims where both are bright, so
    the upper one comes in sooner, level for a light of 0.6."""
    return f / (1.0 - 0.6 * (1.0 - f))


HOT = 0.667              # the art adds its light, so where the sum runs past full it goes white: alpha-over can't, so
#                           a white cell is laid over the coloured one, (sum - 1) times this (a colour's least channel 0.4)
PIECES = 1.6              # the art's light added over the shard's pale pieces turns them white well before full: a white
#                           cell of the wide glow and the beams on the pale faces alone, this much stronger


def light_stage(rarity):
    """A stage with only what the light's rules read: no shard, no fighter."""
    st = Stage.__new__(Stage)
    st.rarity, st.plan, st.light = rarity, dict(rb.PLANS[rarity], reach=REACH[rarity]), rb.LIGHT[rarity]
    return st


def set_tops():
    """The strongest each leak set's lights are driven while it shows, over the six rarities at 60 a second: a, the
    wide glow and the pieces; b, the beams; c, the tight glow."""
    tops = [dict(a=0.0, b=0.0, c=0.0) for _ in leak_sets()]
    for rarity in RARITIES:
        st = light_stage(rarity)
        steps = st.plan["steps"]
        for i in range(round(st.plan["split"] * FPS) + 1):
            t_ = i / FPS
            _, level = st.glow_at(t_)
            picked, over = leak_pick(st.plan, t_)
            m, burn = min(1.0, level + 0.35), st.push(t_) * over
            for j, share in picked:
                if share > 0:
                    top = tops[j]
                    top["a"] = max(top["a"], m * level * burn)
                    top["c"] = max(top["c"], m * burn)
                    if len(steps) > 1 and t_ > steps[1][0]:
                        top["b"] = max(top["b"], m * level * burn)
    return tops


def leak_alpha(cell, drive):
    """A leak cell's alpha at a drive: a scale turns it down below it; a ramp brings a boost in between its ends; a
    curve is straight between its points, held past its ends."""
    if "curve" in cell:
        return float(np.interp(drive, [p[0] for p in cell["curve"]], [p[1] for p in cell["curve"]]))
    if "ramp" in cell:
        lo, hi = cell["ramp"]
        return float(np.clip((drive - lo) / (hi - lo), 0, 1))
    return min(1.0, drive / cell["scale"])


def shares(g, widths):
    """Which of the cells drawn at `widths` a seam opened g times shows, and how much of each."""
    if g <= widths[0]:
        return [(0, max(0.0, g / widths[0]))]
    for i in range(len(widths) - 1):
        if g <= widths[i + 1]:
            f = (g - widths[i]) / (widths[i + 1] - widths[i])
            return [(i, 1.0 - f), (i + 1, f)]
    return [(len(widths) - 1, 1.0)]


def leak_images(out: Path):
    """The light the shard leaks, from the reveal's camera, a set of cells for each of leak_sets: the wide glow, the
    whitening of the pale pieces under it, the beams and their white (half a pixel a point), the tight glow and its
    white (1 pixel a point). The tight glow keeps off the seam's own line, which is the core's mesh showing through,
    so the line stays white-hot under it. A coloured cell is stored at its set's settled strength (its scale), clipped
    as the art clips, so at rest it is the art's exactly, with a boost up to the strongest its set is driven (set_tops).
    A white cell holds what the art's added light runs past full there (HOT), with a curve for how much of it shows at
    each strength; it is left out where nothing runs past full. One atlas holds them all."""
    rb.set_scale(2)
    K = 2
    shard = Shard("Standard")
    shots = []
    for s in leak_sets():
        shard.pose(gaps=[GAP * s["width"] if seam in s["seams"] else 0.0 for seam in SEAM_ORDER])
        clay, mask = shard.shoot(out, (W * K, H * K), W / UNIT, centre=(0.0, 0.0, 0.05))
        lum = clay[..., :3] @ np.array([0.3, 0.59, 0.11], np.float32)
        shots.append((s, mask, clay[..., 3] * np.clip((lum - 0.25) / 0.45, 0, 1)))
    shard.pose()
    view = shard_camera(shard)   # after a shot: the camera is only aimed when it shoots
    ox, oy = view["origin"]
    cells, info = {}, {}

    def store(name, alpha, k, **more):
        px = rs.shrink(white(alpha), k / K)
        if px[..., 3].max() <= 1.0 / 255:
            return   # nothing in it: left out
        px, x0, y0 = cut(px)
        cells[name] = px
        info[name] = dict({key: v for key, v in more.items()}, points=[round(px.shape[1] / k, 2), round(px.shape[0] / k, 2)],
                          anchor=[round((ox * k - x0) / px.shape[1], 5), round((oy * k - y0) / px.shape[0], 5)])

    def coloured(name, light, k, settled, top):
        """At rest exactly the art's, clipped as it clips. A light that never runs past full is one cell, stored at
        its top and turned down. One that does is a base at rest and a boost to the top: the boost is made so laid
        over the base at full it gives the art's clip at the top, and part way, the straight line between."""
        top = max(top, settled * 1.05)
        if float(light.max()) * top <= 1.0:
            store(name, light * top, k, scale=round(top, 4))
            return
        base, high = np.clip(light * settled, 0, 1), np.clip(light * top, 0, 1)
        store(name, base, k, scale=round(settled, 4))
        store(name + "Boost", (high - base) / np.maximum(1.0 - base, 1e-4) * (base < 0.999), k,
              ramp=[round(settled, 4), round(top, 4)])

    def hot(name, light, k, settled, top):
        """The white past full at the top, and how much shows from where it begins."""
        top = max(top, settled * 1.05)
        past = lambda d: float(np.clip((light * d - 1.0) * HOT, 0, 1).sum())  # noqa: E731
        if past(top) <= 0:
            return
        begins = 1.0 / float(light.max())
        curve = [[begins, 0.0], [top, 1.0]]
        if begins < settled:
            curve.insert(1, [settled, past(settled) / past(top)])
        store(name, (light * top - 1.0) * HOT, k, curve=[[round(d, 4), round(a, 4)] for d, a in curve])

    tops = set_tops()
    for i, (s, mask, pale) in enumerate(shots):
        m, mb = min(1.0, s["lv"] + 0.35), min(1.0, s["beam_lv"] + 0.35)
        a, b, c_ = m * s["lv"], mb * s["beam_lv"], m      # the settled drives: no push, no snap, the core whole
        top = tops[i]
        wide = soft(mask, 20 * K, f=2 * K) * 2.2
        coloured(f"wide{i}", wide, 0.5, a, top["a"])
        zx, zy = W / 2 - s["rise"] * view["per_z"][0], H / 2 - 0.05 * UNIT - s["rise"] * view["per_z"][1]
        beams = rb.beams(mask, zx * K, zy * K, reach=0.9 + 1.6 * s["beam_lv"], f=2 * K) * 1.6
        coloured(f"piecesHot{i}", (wide + (beams if top["b"] > 0 else 0.0)) * PIECES * pale, 0.5, a, top["a"])
        if top["b"] > 0:   # the cracking sets the beams never reach go without
            coloured(f"beams{i}", beams, 0.5, b, top["b"])
        tight = blur(mask, 2.5 * K) * 1.8
        coloured(f"tight{i}", tight * (1.0 - 0.85 * np.clip(blur(mask, K / 2) * 1.6, 0, 1)), 1, c_, top["c"])
        # the white: the art's lights add before they run past full, so one cell from their sum, at the set's level
        hot(f"hot{i}", s["lv"] * (wide + (beams if top["b"] > 0 else 0.0)) + tight, 1, c_, top["c"])
    atlas, places = shelf(cells)
    for name, (x, y) in places.items():
        h, w = cells[name].shape[:2]
        info[name]["rect"] = [x, y, w, h]
    return atlas, info, view, shard


def white_core(shard):
    uv = shard.core.data.uv_layers["Palette"]
    tone = shard.core.data.color_attributes["Tone"]
    for poly in shard.core.data.polygons:
        for li in poly.loop_indices:
            uv.data[li].uv = ((CORE_SWATCH + 0.5) / len(PALETTE), 0.5)
            tone.data[li].color_srgb = (1.0, 1.0, 1.0, 1.0)


def shard_meshes(folder: Path):
    """The five pieces, the two buds and the core, in Roblox's frame, on the palette (blcommon.export_mesh_json)."""
    shard = Shard("Prismatic")
    white_core(shard)
    shard.pose()
    listing = {}
    for name, obj in shard.pieces.items():
        tris = bl.export_mesh_json(obj, folder / f"Shard_{name}.json", uv=True)
        listing[name] = dict(mesh=f"meshes/Shard_{name}.json", triangles=tris,
                             centre=json.loads((folder / f"Shard_{name}.json").read_text())["c"])
    buds = [o for o in shard.scene.objects if o.name.startswith("Bud")]
    buds.sort(key=lambda o: o.name)
    for name, bud in zip(BUD_NAMES, buds):
        data = bud.data.copy()
        data.transform(bud.matrix_basis)   # into its host's frame, which at rest is the root's
        obj = bpy.data.objects.new(name, data)
        shard.scene.collection.objects.link(obj)
        tris = bl.export_mesh_json(obj, folder / f"Shard_{name}.json", uv=True)
        listing[name] = dict(mesh=f"meshes/Shard_{name}.json", triangles=tris, host=bud.parent.name,
                             centre=json.loads((folder / f"Shard_{name}.json").read_text())["c"])
    tris = bl.export_mesh_json(shard.core, folder / "Shard_Core.json", uv=True)
    listing["Core"] = dict(mesh="meshes/Shard_Core.json", triangles=tris,
                           centre=json.loads((folder / "Shard_Core.json").read_text())["c"])
    return listing


def roblox(v):
    """A direction or a place from Blender's frame to Roblox's: X, Z up, -Y."""
    return [round(float(v[0]), 5), round(float(v[2]), 5), round(float(-v[1]), 5)]


def parts(out: Path):
    folder = parts_dir(out)
    for sub in ("images", "meshes"):
        (folder / sub).mkdir(parents=True, exist_ok=True)
    images = {}

    def write(name, px, k, use, anchor=None, points=None, **more):
        rs.save(rs.bleed(px), folder / "images" / f"{name}.png")
        h, w = px.shape[:2]
        if w > 1024 or h > 1024:
            raise SystemExit(f"{name} is {w} by {h}, past the 1024 cap")
        entry = dict(file=f"images/{name}.png", pixels=[w, h], points=points or [round(w / k, 2), round(h / k, 2)], use=use)
        if anchor is not None:
            entry["anchor"] = [round(a, 5) for a in anchor]
        entry.update(more)
        images[name] = entry

    write("reveal_room", room_image(), 1024 / W, "the room: full screen, under everything")
    write("reveal_glow", glow_image(), 1.0, "every round light: its cover exp(-(r / s) ** 2) for a light s points "
          "round, drawn 6 s across (6 sx by 6 sy for a stretched one), tinted, its strength as its cover",
          points="6 s by 6 s")
    px, cells = rings_image()
    write("reveal_rings", px, 1.0, "a ring of radius R and width w: the cell whose ratio is nearest w / R, drawn "
          "R / radius across (radius is the ring's share of its cell's width), tinted", points="R / radius square",
          cells=cells)
    write("reveal_column", column_image(), 1.0, f"a rare strike's column: wd wide is 6 wd across, "
          f"{sum(COLUMN):g} points tall, its top {COLUMN[0]:g} points over the ram's head; stretched across only",
          points=f"6 wd by {sum(COLUMN):g}")
    for count in sorted({v["rays"] for v in rb.LIGHT.values() if v["rays"]}):
        write(f"reveal_rays{count}", rays_image(count), 1024 / RAYS_SPAN,
              f"{count} rays (0.5 baked in), {RAYS_SPAN:g} points square, its middle on the rays' point, turned "
              "clockwise by the rule, tinted")
    for rarity in RARITIES:
        for part, (px, k, anchor) in window_images(rarity).items():
            write(f"reveal_{part}_{rarity}", px, k, {"halo": "the window's halo, its colour and strength baked",
                                                      "window": "the window's light inside it, baked",
                                                      "frame": "the frame's metal, untinted"}[part], anchor)
    rule = rule_image()
    write("reveal_rule", rule, 2, "the name's rule, white, tinted by the rarity's metal: a nine-slice, "
          "SliceCenter in pixels, SliceScale 0.5", slice=[16, 0, rule.shape[1] - 20, rule.shape[0]], span=120.0)
    write("reveal_palette", palette_image(), 1.0, "the shard's meshes' texture: eight swatches, a face's UV on "
          "its swatch's middle", points="a texture", swatches=list(PALETTE))
    atlas, leak, view, shard = leak_images(out)
    write("reveal_leak", atlas, 1.0, "the light the shard leaks, one atlas of nine sets (the seams cracking, then "
          "each rung's width): the wide glow, the pieces' whitening, the beams (half a pixel a point), the tight glow "
          "and the white where the lights together run past full (1); each cell with its own points and its anchor on "
          "the shard's root",
          points="by its cells", cells=leak,
          sets=[dict(seams=s["seams"], width=s["width"]) for s in leak_sets()])
    camera_dir = Vector((math.cos(math.radians(6.0)) * math.sin(math.radians(14.0)),
                         -math.cos(math.radians(6.0)) * math.cos(math.radians(14.0)), math.sin(math.radians(6.0))))
    a = Vector(rb.SEAMS["A"][1]).normalized()
    pieces = shard_meshes(folder / "meshes")
    for i, (name, sides) in enumerate(rb.PIECES):
        pieces[name].update(order=i, side_A=sides["A"], away=roblox(shard.away[name]), reach=(0.75, 1.0, 1.25, 0.85, 1.1)[i])
    for seam, (who, way) in rb.LOOSE.items():
        pieces[who]["slides"] = dict(seam=seam, way=way, along=roblox(rb.slide(seam)))
    rb.set_scale(2)
    figure = rb.Figure(out)
    stage_run = Stage(out, "Common").run
    spec = dict(
        about="AR3 section 5, the reveal's engine parts (tools/blender/reveal_art.py parts). Points on the 844 by 390 "
              "screen, x right, y down from its top left; seconds from the tap unless said. Every light is laid over, "
              "never added: an image tinted by `tint`, its cover times `alpha`. The rules are the art's own, written "
              "out; EngineStage in the script lays frames from these files to check them.",
        screen=dict(points=[W, H], fps=FPS),
        images=images,
        order=[
            "1 the room: reveal_room, full screen",
            "2 the room's light: reveal_glow at (cx, cy), s 300, tint the light, alpha 0.34 level",
            "3 each rung's ring, for 0.3 s after it: reveal_rings at (cx, cy), R 30 + 900 age, w 10 + 60 age, tint the "
            "light, alpha 0.5 lv (1 - age / 0.3)",
            "4 from the split, the rays (rarities with rays): reveal_rays<n> centred on (cx, 187.6), turned "
            "0.12 tau radians clockwise, tint the rays' colour, alpha min(1, opened)",
            "5 the window's halo, then its fill: reveal_halo_<rarity>, reveal_window_<rarity>, anchored on (cx, 202), "
            "sized their points times (sx, sy)",
            "6 the sill's line: reveal_glow at (cx, 346), s 170 across and 5 down, tint the light, alpha 0.45 level",
            "7 the frame: reveal_frame_<rarity> anchored on (cx, 202) at its size, alpha framed",
            "8 the shard's ViewportFrame (the pieces, the buds, the core), its cover the pieces' fade",
            "9 the leak over it, until the split's core is gone: the picked sets' wide glow, the pieces' white, the "
            "beams, the tight glow, the white (shard.leak)",
            "10 the fighter's ViewportFrame",
            "11 the strike, for 0.25 s from the Knock: a ring, a white dot and, with rays, the column",
            "12 the frame again, cut to the rows below 330 (its foot over his soles: a Frame clipping a copy)",
            "13 a rung's flash at the shard: reveal_glow at (cx, cy), s 110, tint mix(light, white, 0.5), alpha flash",
            "14 the name, its rule, the glint, the wash",
            "15 the split's flash: reveal_glow at (cx, cy), s the rarity's radius, or a white Frame over the screen",
            "16 the whole screen kicked down by the name's kick"],
        places=dict(
            cx="W / 2 + (600 - W / 2) smooth((clip - 0.4) / 0.3): the window and the fighter stand on it",
            cy=round(H / 2 - 0.05 * UNIT, 3), window_middle=[None, TOP + BIG[1] / 2], window_top=TOP, sill=SILL,
            foot_band=SILL - SILL_BAND, rays_point=round(TOP + BIG[1] * 0.45, 2),
            clip="tau + offset: where his Reveal clip is; tau = t - split"),
        curves=dict(
            smooth="u clamped to 0..1; u u (3 - 2 u)",
            back="u clamped to 0..1, v = u - 1; 1 + v v (2.70158 v + 1.70158)",
            snap="0 before 0; 1.35 a / 0.03 to 0.03 s; then 1 + 0.35 exp(-(a - 0.03) / 0.05)",
            bump="0 before 0; exp(-a / 0.06) (1 - exp(-a / 0.015)) / 0.5364",
            run="1 - (1 - clamp(u, 0, 1)) ** 1.4",
            slam="the engine's (Rules.Reveal.Slam, Config.Reveal.Stamp): none before -4/60; to 0: 0.93 + 0.77 (1 - (1 + u / (4/60)) ** 2); then 1 - 0.07 exp(-u / 0.03) cos(u / 0.05 pi)",
            kick="0 before 0; shake exp(-u / 0.05) cos(u / 0.09 2 pi), points down"),
        light=dict(
            shard=rb.SHARD_LIGHT,
            rule="Start at the shard's light, level 0. Each step (when, colour, lv, wide) the time has passed: w = "
                 "smooth((t - when) / 0.06), colour and level mixed toward its by w. With a breath (b0, b1), from b0: "
                 "level times 1 - 0.8 smooth((t - b0) / (b1 - b0) 1.6). From the split: the rarity's own colour and level.",
            burn="the rungs' push on the seams: 1 + 0.8 max over the steps after the first of bump(t - when) (0.6 + 0.4 lv)"),
        shard=dict(
            meshes=pieces,
            grades={"Standard": [], "Enriched": [BUD_NAMES[0]], "Prismatic": list(BUD_NAMES)},
            frame="Roblox's: 1 = one of the shard's units. Each MeshPart is CFrame(location) * rotation * "
                  "CFrame(centre) from the root; a bud goes on its host piece the same way, welded.",
            surface=f"TextureID reveal_palette.png on every piece and bud; the core takes no texture, its Color by "
                    f"the rule, SmoothPlastic. The ViewportFrame lit flat: Ambient white, LightColor black (to be "
                    f"read in the engine against the palette's swatches)",
            camera=dict(target=[0.0, 0.05, 0.0], direction=roblox(camera_dir), fov=VIEW_FOV,
                        distance=round((H / UNIT / 2) / math.tan(math.radians(VIEW_FOV / 2)), 3),
                        frame="a ViewportFrame the screen's size, transparent, the camera CFrame.lookAt(target + "
                              "direction * distance, target)"),
            root=dict(view, rule="The root's sway and squash move the ViewportFrame on the screen, not the camera: its "
                                 "AnchorPoint on `origin`, placed at origin + at.x per_x + at.z per_z, sized the screen "
                                 "times (scale.x, scale.z). The leak's cells ride with it, sized by the same."),
            seams=dict(cracks="each rarity's `cracks`, seams A to D", gap="0.045 snap(t - crack) widen(t)",
                       widen="the most over the steps passed of 1 + (wide - 1) smooth((t - when) / 0.08); 1 before any"),
            pose=dict(
                shake="0 before 0; 0.006 + 0.022 level widen / 2",
                at="(sin(173 t) shake, 0.03 sin(3.1 t) + sin(211 t + 1) shake)",
                tap="exp(-t / 0.035) from 0: scale (1 + 0.07 tap, 1 - 0.07 tap)",
                rise="with a climb: 0.25 smooth((t - 0.4) / 0.6) added to at.z",
                swell="1 + 0.05 smooth((t - (split - 0.15)) / 0.15); with a breath (b0, b1): 1 + 0.06 smooth((t - 0.4) / "
                      "0.6) - 0.16 smooth((t - b0) / (b1 - b0) 1.4), and from b0 at is (0.2 at.x, 0.2 at.z + 0.03) "
                      "before the rise; scale times swell",
                rung="each step after the first, i from 0, age = t - when, amp = 0.6 + 0.4 lv, while 0 <= age < 0.3: "
                     "scale times 1 + 0.05 amp bump(age); jolt = 0.08 amp exp(-age / 0.025) cos(age / 0.05 2 pi); "
                     "at.x plus jolt (minus for odd i), at.z plus 0.35 jolt",
                fly="reach (1 - exp(-tau / 0.13)) from the split",
                spin="max(0, tau) 5 + fly 0.22",
                core="1 to the split, then max(0, 1 - tau / 0.09): the core's scale",
                piece="location = side_A A_normal gap_A / 2 + (its seam's way along gap) + away fly reach; rotation "
                      "(Blender's XYZ, written for Roblox) = Y((2 - i) spin 0.3) * Z(-(i - 2) spin 0.8) * "
                      "X((0.5 + i) spin 0.6), each CFrame.fromAxisAngle, i the piece's order",
                A_normal=roblox(a),
                fade="the pieces' cover 1 - smooth((tau - 0.18) / 0.25)"),
            core_colour="mix(#07050C, mix(light, white, 0.55 + 0.45 level), min(1, level + 0.35))",
            leak="Every cell is in reveal_leak, anchored on the root, sized the root's scale. m = min(1, level + 0.35), "
                 "k = the core's scale, burn the rung's push. The cells come in nine sets, i = 0 to 8 (sets): 0 to 2 the "
                 "seams cracked one by one (A, AB, ABC) at their width, 3 to 8 all four at each rung's width "
                 "(1, 1.2, 1.45, 1.7, 2.3, 2.8). Which show: snap_n = snap(t - crack n) for each crack; n = the cracks "
                 "begun. None before the first. While n < 4 or snap_4 < 1: f = min(1, snap_n); set n-2 by 1 - f and "
                 "set n-1 by blend(f) (n = 1: set 0 by f alone); over = max(1, mean of snap_1..n) times widen (the "
                 "rungs' widening, the pose's rule). After: widen picks the two rung sets either side of it, f by how "
                 "near it is to the upper (past 2.8, set 8 alone): the lower by 1 - f, the upper by blend(f); over = "
                 "max(1, mean of the four snaps). blend(f) = f / (1 - 0.6 (1 - f)). Lay the lower set first. burn' = burn "
                 "over. a = m level burn' k; b = a once the first rung has come, else no beams; c = m burn' k. "
                 "piecesHot and hot cells are white, the rest tinted the light. A cell's alpha at its drive x: with a "
                 "scale, min(1, x / scale); with a ramp [lo, hi], clamp((x - lo) / (hi - lo), 0, 1); with a curve "
                 "([x, alpha] points), straight between them, held past the ends. For each kind in this order, each "
                 "picked set's cell and then its Boost, alpha times the set's share: wide<i> from a; piecesHot<i> from "
                 "a; beams<i> from b; tight<i> from c; hot<i> from c. A cell missing from the atlas had nothing in it: "
                 "skip it."),
        rarities={},
        figure=dict(
            tile=list(rb.TILE), centre="(cx, 185): his soles on the sill",
            camera=dict(look_at="3.5 studs over his soles", direction_in_his_frame=roblox(Vector((
                math.cos(math.radians(rb.CAMERA[1])) * math.sin(math.radians(180.0 - rb.CAMERA[0])),
                -math.cos(math.radians(rb.CAMERA[1])) * math.cos(math.radians(180.0 - rb.CAMERA[0])),
                math.sin(math.radians(rb.CAMERA[1]))))), fov=VIEW_FOV,
                distance=round((rb.TILE[1] / rb.STUD / 2) / math.tan(math.radians(VIEW_FOV / 2)), 3),
                note="rook_clips.FRONT: 38 degrees round to his right, 8 up; 390 points are 8.48 studs"),
            dark=VIOLET["channel"],
            rim="the light's colour over his edge, 2 points in, at 0.8 x min(1, 0.45 + 0.55 level) back(tau / 0.16), "
                "where his colours haven't come",
            flood=dict(origin_in_tile=[round(figure.accent[0] / 2, 1), round(figure.accent[1] / 2, 1)],
                       reach=round(stage_run / 2, 1), soft=45.0, seconds=FLOOD,
                       rule="from the Knock, edge = reach run((clip - Knock) / 0.13); a point d from the origin shows "
                            "his colours by clamp((edge - d) / 45, 0, 1), dark under; the hot line mix(light, white, "
                            "0.55) at exp(-((d - edge + 22.5) / 25) ** 2) (1 - u / 1.3) 0.8 while u < 1.3"),
            cover="smooth((tau - 0.03) / 0.08)", knock=round(KNOCK, 5), name_marker=round(NAME, 5)),
        strike=dict(
            ring="reveal_rings at the ram's head, R 14 + 820 age, w 5 + 40 age, tint mix(light, white, 0.55), alpha "
                 "(0.35 + 0.5 level) (1 - age / 0.25)",
            dot="reveal_glow at the head, s 22, white, alpha 0.7 max(0, 1 - age / 0.06)",
            column="with rays: reveal_column, wd 7 + 30 age / 0.25, tint the rays' colour, alpha 0.8 (1 - age / 0.25)",
            head="the flood's origin in his tile, on the screen"),
        name=dict(
            face="the game's: Builder Sans ExtraBold, Italic (the critical's slant)", colour=VIOLET["text"],
            size="58 x the rarity's name scale (TextSize)", left=NAME_LEFT, baseline=NAME_BASE,
            widest=round(NAME_MAX, 1), fit="a name wider than `widest` at its size is set smaller to fit, never cut",
            slam="its size times slam(u), u = t - name time; it grows from the point a quarter along its foot",
            burn="mix(colour, white, max(0, 1 - max(u, 0) / 0.14) ** 2)",
            rule="from u = -0.02, cover smooth((u + 0.02) / 0.03): reveal_rule from x = left - 12, y = baseline + 10, 9 "
                 "tall, its span from left - 10 to min(right + 22, left + widest + 6), tinted the rarity's `rule`",
            glint="from u = 0 for 0.3 s: gx = left - 10 + (u / 0.2) (right + 32 - left); reveal_glow at (gx, baseline + "
                  "14.5), s 14 across and 40 down, white, alpha 1 - u / 0.3, clipped to the rule's box; and reveal_glow "
                  "at (gx, baseline + 14.5), s 22 by 9, tint the light, alpha 0.6 (1 - u / 0.3)",
            wash="reveal_glow on the name's middle, s 0.6 its width by 40, white, alpha 0.3 max(0, 1 - u / 0.1)"),
        split_flash="radius, strength, seconds a rarity: reveal_glow at (cx, cy) s the radius, white, alpha strength "
                    "(1 - tau / seconds) ** 2; with no radius a white Frame over the screen, alpha strength, then from "
                    "0.035 s strength (1 - (tau - 0.035) / (seconds - 0.035)) ** 1.5",
        skip="open from 1.0 s, every rarity")
    for rarity in RARITIES:
        plan, light, r = rb.PLANS[rarity], rb.LIGHT[rarity], rb.RARITIES[rarity]
        metal = c(r["metal"][0]) + (c(r["metal"][1]) - c(r["metal"][0])) * ((NAME_BASE + 14.5 - TOP) / BIG[1])
        radius, strength, length = FLASH[rarity]
        spec["rarities"][rarity] = dict(
            times={k: round(v, 4) for k, v in times(rarity).items()}, grade=plan["grade"], cracks=list(plan["cracks"]),
            steps=[dict(when=w, colour=code, level=lv, wide=wide) for w, code, lv, wide in plan["steps"]],
            breath=list(plan["breath"]) if plan["breath"] else None, offset=OFFSET[rarity], reach=REACH[rarity],
            light=dict(colour=light["colour"], level=light["level"], rays=light["rays"],
                       rays_colour=light.get("ray", light["colour"])),
            flash=dict(radius=radius, strength=strength, seconds=length), name_scale=NAME_SCALE[rarity],
            shake=SHAKE[rarity], hold=HOLD[rarity], rule=hexa(metal))
    (folder / "reveal.json").write_text(json.dumps(spec, indent=1), encoding="utf-8", newline="\n")
    print(f"wrote {folder}: {len(images)} images, {len(pieces)} meshes")


def load_parts(out: Path):
    folder = parts_dir(out)
    spec = json.loads((folder / "reveal.json").read_text(encoding="utf-8"))
    pics = {name: rs.load(folder / entry["file"]) for name, entry in spec["images"].items()}
    return spec, pics


def sample(img, u, v):
    """Bilinear, on premultiplied colour, nothing outside the picture."""
    ih, iw = img.shape[:2]
    inside = ((u > -0.5) & (u < iw - 0.5) & (v > -0.5) & (v < ih - 0.5)).astype(np.float32)
    u, v = np.clip(u, 0, iw - 1), np.clip(v, 0, ih - 1)
    u0, v0 = np.floor(u).astype(np.intp), np.floor(v).astype(np.intp)
    u1, v1 = np.minimum(u0 + 1, iw - 1), np.minimum(v0 + 1, ih - 1)
    fu, fv = (u - u0)[..., None], (v - v0)[..., None]
    pm = img.copy()
    pm[..., :3] *= pm[..., 3:]
    s = (pm[v0, u0] * (1 - fu) * (1 - fv) + pm[v0, u1] * fu * (1 - fv) + pm[v1, u0] * (1 - fu) * fv + pm[v1, u1] * fu * fv)
    s *= inside[..., None]
    a = s[..., 3]
    rgb = s[..., :3] / np.maximum(a, 1e-6)[..., None]
    return rgb, a


def lay(px, img, box, tint=WHITE, alpha=1.0, turn=0.0):
    """An image laid as the engine lays it: over, its colour times `tint`, its cover times `alpha`; `box` its left,
    top, width and height in points, `turn` radians clockwise about its middle."""
    alpha = min(1.0, alpha)
    if alpha <= 0.002:
        return
    K = ui.K
    x0, y0, w, h = box
    mx, my = x0 + w / 2, y0 + h / 2
    reach = math.hypot(w, h) / 2 if turn else 0.0
    lo_x, hi_x = (mx - reach, mx + reach) if turn else (x0, x0 + w)
    lo_y, hi_y = (my - reach, my + reach) if turn else (y0, y0 + h)
    i0, i1 = max(0, int(lo_y * K)), min(px.shape[0], int(math.ceil(hi_y * K)))
    j0, j1 = max(0, int(lo_x * K)), min(px.shape[1], int(math.ceil(hi_x * K)))
    if i1 <= i0 or j1 <= j0:
        return
    yy, xx = np.mgrid[i0:i1, j0:j1].astype(np.float32)
    X, Y = (xx + 0.5) / K - mx, (yy + 0.5) / K - my
    if turn:
        cs, sn = math.cos(turn), math.sin(turn)
        X, Y = cs * X + sn * Y, -sn * X + cs * Y
    ih, iw = img.shape[:2]
    rgb, a = sample(img, (X / w + 0.5) * iw - 0.5, (Y / h + 0.5) * ih - 0.5)
    a = (a * alpha)[..., None]
    region = px[i0:i1, j0:j1]
    region[..., :3] = region[..., :3] * (1 - a) + rgb * np.asarray(tint, np.float32) * a


class EngineStage(Stage):
    """The art's stage, which also lays its frames from the engine's parts alone."""

    def __init__(self, out: Path, rarity):
        super().__init__(out, rarity)
        self.spec, self.pics = load_parts(out)
        self.view = self.spec["shard"]["root"]

    def entry(self, name):
        return self.spec["images"][name]

    def dot(self, px, x, y, sx, sy, tint, alpha):
        lay(px, self.pics["reveal_glow"], (x - 3 * sx, y - 3 * sy, 6 * sx, 6 * sy), tint, alpha)

    def ring(self, px, x, y, R, w, tint, alpha):
        cells = self.entry("reveal_rings")["cells"]
        cell = min(cells.values(), key=lambda q: abs(math.log(q["ratio"] / (w / R))))
        cx_, cy_, cw, ch = cell["rect"]
        size = R / cell["radius"]
        lay(px, self.pics["reveal_rings"][cy_:cy_ + ch, cx_:cx_ + cw], (x - size / 2, y - size / 2, size, size), tint, alpha)

    def anchored(self, px, name, x, y, sx=1.0, sy=1.0, tint=WHITE, alpha=1.0, img=None, entry=None):
        entry = entry or self.entry(name)
        (pw, ph), (ax, ay) = entry["points"], entry["anchor"]
        lay(px, self.pics[name] if img is None else img, (x - ax * pw * sx, y - ay * ph * sy, pw * sx, ph * sy), tint, alpha)

    def engine(self, t_):
        t, plan, light, K = self.t, self.plan, self.light, ui.K
        px = t.px
        px[..., 3] = 1.0
        lay(px, self.pics["reveal_room"], (0, 0, W, H))
        colour, level = self.glow_at(t_)
        split, tau = plan["split"], t_ - plan["split"]
        clip = tau + OFFSET[self.rarity]
        cx = W / 2 + (CX - W / 2) * smooth((clip - STEP[0]) / STEP[1])
        cy = H / 2 - 0.05 * UNIT
        ray_colour = c(light.get("ray", light["colour"]))
        hot = colour + (WHITE - colour) * 0.55
        middle = TOP + BIG[1] / 2
        if level > 0:
            self.dot(px, cx, cy, 300.0, 300.0, colour, 0.34 * level)
        for when, _, lv, _ in plan["steps"][1:]:
            age = t_ - when
            if 0 <= age < 0.3:
                self.ring(px, cx, cy, 30.0 + age * 900.0, 10.0 + age * 60.0, colour, 0.5 * lv * (1 - age / 0.3))
        framed = smooth((tau - 0.08) / 0.12)
        if tau >= 0:
            opened = back(tau / 0.16)
            sx, sy = 0.03 + 0.97 * opened, 0.72 + 0.28 * smooth(tau / 0.12)
            if light["rays"]:
                rays = f"reveal_rays{light['rays']}"
                lay(px, self.pics[rays], (cx - RAYS_SPAN / 2, TOP + BIG[1] * 0.45 - RAYS_SPAN / 2, RAYS_SPAN, RAYS_SPAN),
                    ray_colour, opened, turn=0.12 * tau)
            self.anchored(px, f"reveal_halo_{self.rarity}", cx, middle, sx, sy)
            self.anchored(px, f"reveal_window_{self.rarity}", cx, middle, sx, sy)
            self.dot(px, cx, SILL, 170.0, 5.0, colour, 0.45 * level)
            if framed > 0:
                self.anchored(px, f"reveal_frame_{self.rarity}", cx, middle, alpha=framed)
        flash = 0.0
        for when, _, lv, _ in plan["steps"][1:]:
            if 0 <= t_ - when < 0.08:
                flash = max(flash, 0.35 * lv * (1 - (t_ - when) / 0.08))
        if t_ < split + 0.7:  # the shard's ViewportFrame: its pieces, and its core where it shows
            pose = self.shard_pose(t_)
            self.shard.pose(**pose)
            clay, leak = self.shard.shoot(self.out, (W * K, H * K), W / UNIT, centre=(0.0, 0.0, 0.05))
            m = min(1.0, level + 0.35)
            core = c(VIOLET["channel"]) + ((colour + (WHITE - colour) * (0.55 + 0.45 * level)) - c(VIOLET["channel"])) * m
            ui.over(clay, core, leak)
            clay[..., 3] *= 1.0 - smooth((tau - GONE[0]) / GONE[1])
            rs.paste(px, clay, 0, 0)
            k = pose["core"]
            if level > 0 and k > 0:
                (ax_, az_), (s0, s1) = pose["at"], pose["scale"]
                ox = self.view["origin"][0] + ax_ * self.view["per_x"][0] + az_ * self.view["per_z"][0]
                oy = self.view["origin"][1] + ax_ * self.view["per_x"][1] + az_ * self.view["per_z"][1]
                picked, over = leak_pick(plan, t_)
                burn = self.push(t_) * over
                cells, atlas = self.entry("reveal_leak")["cells"], self.pics["reveal_leak"]

                def cell(name, alpha, tint=colour):
                    if name in cells:   # a white cell with nothing in it was left out
                        x_, y_, w_, h_ = cells[name]["rect"]
                        self.anchored(px, name, ox, oy, s0, s1, tint, alpha, img=atlas[y_:y_ + h_, x_:x_ + w_],
                                      entry=cells[name])

                a, tight = m * level * burn * k, m * burn * k
                b = a if len(plan["steps"]) > 1 and t_ > plan["steps"][1][0] else 0.0
                layers = [("wide", a, colour), ("piecesHot", a, WHITE)]
                if b > 0:
                    layers.append(("beams", b, colour))
                layers += [("tight", tight, colour), ("hot", tight, WHITE)]
                for kind, drive, tint in layers:
                    for j, share in picked:
                        for name in (f"{kind}{j}", f"{kind}{j}Boost"):
                            e = cells.get(name)
                            if e is not None:
                                cell(name, leak_alpha(e, drive) * share, tint)
        x0 = round((cx - rb.TILE[0] / 2) * K)
        if tau >= 0:
            body = self.body(clip, tau, colour, level, hot)
            rs.paste(px, body, x0, -round(LIFT * K))
            ax, ay = self.figure.accent
            hx, hy = (x0 + ax) / K, ay / K - LIFT
            age = clip - KNOCK
            if 0 <= age < 0.25:
                self.ring(px, hx, hy, 14.0 + age * 820.0, 5.0 + age * 40.0, hot, (0.35 + 0.5 * light["level"]) * (1 - age / 0.25))
                self.dot(px, hx, hy, 22.0, 22.0, WHITE, 0.7 * max(0.0, 1 - age / 0.06))
                if light["rays"]:
                    wd = 7.0 + 30.0 * age / 0.25
                    lay(px, self.pics["reveal_column"], (hx - 3 * wd, hy - COLUMN[0], 6 * wd, sum(COLUMN)), ray_colour,
                        0.8 * (1 - age / 0.25))
        if tau >= 0 and framed > 0:  # the foot, a clipped copy of the frame
            copy = px.copy()
            self.anchored(copy, f"reveal_frame_{self.rarity}", cx, middle, alpha=framed)
            row = round((SILL - SILL_BAND) * K)
            px[row:] = copy[row:]
        if flash > 0:
            self.dot(px, cx, cy, 110.0, 110.0, colour * 0.5 + 0.5, flash)
        u = t_ - self.when["name"]
        s = slam(u)
        if s is not None:
            self.engine_name(px, u, s)
        radius, strength, length = FLASH[self.rarity]
        if 0 <= tau < length:
            if radius is None:
                fade = 1.0 if tau < 0.035 else (1.0 - (tau - 0.035) / (length - 0.035)) ** 1.5
                a = strength * fade
                px[..., :3] = px[..., :3] * (1 - a) + a
            else:
                self.dot(px, cx, cy, radius, radius, WHITE, strength * (1 - tau / length) ** 2)
        dy = round(kick(u, self.rarity) * K)
        if dy:
            px = np.roll(px, dy, axis=0)
            if dy > 0:
                px[:dy] = px[dy]
            else:
                px[dy:] = px[dy - 1]
        return px.copy()

    def engine_name(self, px, u, s):
        """The name as the engine sets it: the art's sprite stands in for the game's text; the rule a nine-slice, the
        glint and the wash the soft dot."""
        K = ui.K
        sprite = rs.shrink(self.name, s / SLAM)
        burn = max(0.0, 1.0 - max(u, 0.0) / 0.14) ** 2
        sprite[..., :3] = sprite[..., :3] + (WHITE - sprite[..., :3]) * burn
        width, height = self.name.shape[1] / SLAM, self.name.shape[0] / SLAM
        rs.paste(px, sprite, round(NAME_LEFT * K + 0.25 * (width - sprite.shape[1])), round(NAME_BASE * K - sprite.shape[0]))
        landed = smooth((u + 0.02) / 0.03)
        if landed <= 0:
            return
        right = NAME_LEFT + width / K
        end = min(right + 22.0, NAME_LEFT + NAME_MAX + 6.0)
        span = end - (NAME_LEFT - 10.0)
        rule, e = self.pics["reveal_rule"], self.entry("reveal_rule")
        left, mid, rgt = rule[:, :16], rule[:, 16:e["slice"][2]], rule[:, e["slice"][2]:]
        wide_px = max(1, round((span + 4.0) * 2) - 16 - rgt.shape[1])
        stretched = np.concatenate([left, mid[:, np.linspace(0, mid.shape[1] - 1, wide_px).round().astype(int)], rgt], axis=1)
        tint = c(self.spec["rarities"][self.rarity]["rule"])
        lay(px, stretched, (NAME_LEFT - 12.0, NAME_BASE + 10.0, span + 4.0, 9.0), tint, landed)
        if u >= 0:
            gx = NAME_LEFT - 10.0 + u / 0.2 * (right + 32.0 - NAME_LEFT)
            copy = px.copy()
            self.dot(copy, gx, NAME_BASE + 14.5, 14.0, 40.0, WHITE, max(0.0, 1 - u / 0.3))
            r0, r1 = round((NAME_BASE + 12.0) * K), round((NAME_BASE + 17.0) * K)
            c0, c1 = round((NAME_LEFT - 10.0) * K), round(end * K)
            px[r0:r1, c0:c1] = copy[r0:r1, c0:c1]
            self.dot(px, gx, NAME_BASE + 14.5, 22.0, 9.0, c(self.light["colour"]), 0.6 * max(0.0, 1 - u / 0.3))
            mx, my = NAME_LEFT + width / K / 2, NAME_BASE - height / K / 2
            self.dot(px, mx, my, width / K * 0.6, 40.0, WHITE, 0.3 * max(0.0, 1 - u / 0.1))


def compare_moments(rarity):
    w, plan = times(rarity), rb.PLANS[rarity]
    last = plan["steps"][-1][0]
    return ((max(last + 0.05, 0.36), "the leak at its last rung"), (w["split"] + 0.2, "him dark in the window"),
            (w["colours"] + FLOOD / 2, "his colours running"), (w["name"] + 0.15, "the name down"))


def compare(out: Path, rarity):
    """The art's frame and the engine's, at four moments, at 1 pixel a point; how far apart, in the sRGB 0 to 255."""
    rb.set_scale(1)
    folder = parts_dir(out) / "compare"
    folder.mkdir(exist_ok=True)
    stage = EngineStage(out, rarity)
    found = []
    for i, (when, label) in enumerate(compare_moments(rarity)):
        art, engine = stage.frame(when), stage.engine(when)
        rs.save(art, folder / f"{rarity}_{i}_art.png")
        rs.save(engine, folder / f"{rarity}_{i}_engine.png")
        d = np.abs(art[..., :3] - engine[..., :3]).max(axis=2) * 255
        found.append(dict(t=round(when, 3), moment=label, mean=round(float(d.mean()), 2),
                          over_24=round(float((d > 24).mean()), 4), worst=round(float(np.percentile(d, 99.5)), 1)))
        print(rarity, found[-1])
    (folder / f"{rarity}.json").write_text(json.dumps(found, indent=1), encoding="utf-8", newline="\n")


def fit(px, wide, high):
    """Shrunk, never grown, to fit a box of pixels."""
    f = min(1.0, wide / px.shape[1], high / px.shape[0])
    return rs.shrink(px, f) if f < 1.0 else px


def parts_sheets(out: Path):
    """The parts at a glance (reveal_parts.png), at 64 pixels on dark and on grey for the content check
    (reveal_parts_64.png), and the art beside the engine at four moments a rarity (reveal_parts_compare.png). The
    compare's numbers go into reveal.json's checks."""
    folder = parts_dir(out)
    spec, pics = load_parts(out)
    names = list(spec["images"])
    rb.set_scale(2)
    K = 2
    # one: every image, at most 200 points, on the room's dark
    cols, tw, th = 6, 200.0, 200.0
    rows = math.ceil(len(names) / cols)
    sheet = ui.Sheet(40 + cols * (tw + 12), 70 + rows * (th + 40), SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal, the engine's parts: every image", INK)
    t.text(20, 36, 9.5, "AR3 section 5. Each on the reveal's dark at up to 200 points, lights white as the engine "
           "tints them. Sizes in pixels; the 1024 cap holds for each. reveal.json says how each is laid.", SOFT_INK)
    for i, name in enumerate(names):
        row, col = divmod(i, cols)
        x, y = 20 + col * (tw + 12), 70 + row * (th + 40)
        t.paint(t.poly(ui.cut_box(x, y, x + tw, y + th)), c(VIOLET["panel"][1]))
        pic = fit(pics[name], tw * K, th * K)
        rs.paste(sheet.px, pic, round(x * K + (tw * K - pic.shape[1]) / 2), round(y * K + (th * K - pic.shape[0]) / 2))
        w, h = spec["images"][name]["pixels"]
        t.text(x, y + th + 5, 9.5, name.replace("reveal_", ""), "#E6E8EE")
        t.text(x, y + th + 18, 8.5, f"{w} by {h} pixels", SOFT_INK)
    rb.finish(sheet, folder / "reveal_parts.png")
    # two: at 64 pixels, on dark and on grey, and the shard's model at 64
    rb.set_scale(1)
    cols, cell = 6, 150.0
    rows = math.ceil((len(names) + 1) / cols)
    sheet = ui.Sheet(40 + cols * (cell + 10), 60 + rows * (84 + 26), SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 10, 13, "The reveal's parts at 64 pixels, for the content check", INK)
    t.text(20, 30, 9, "Each image at 64 pixels its longest side, on near black and on grey; last, the shard's meshes "
           "on their palette.", SOFT_INK)
    shard = Shard("Prismatic")
    white_core(shard)
    shard.pose()
    model, _ = shard.shoot(out, (64, 64), 5.4)
    entries = [(n.replace("reveal_", ""), pics[n]) for n in names] + [("the shard's meshes", model)]
    for i, (label, pic) in enumerate(entries):
        row, col = divmod(i, cols)
        x, y = 20 + col * (cell + 10), 60 + row * 110
        for j, ground in enumerate(("#0A0B0F", "#8A8F99")):
            t.paint(t.poly(ui.cut_box(x + j * 70, y, x + j * 70 + 66, y + 66)), c(ground))
            small = rs.shrink(pic, 64 / max(pic.shape[:2]))
            rs.paste(sheet.px, small, round(x + j * 70 + 1 + (64 - small.shape[1]) / 2), round(y + 1 + (64 - small.shape[0]) / 2))
        t.text(x, y + 72, 8.5, label, "#E6E8EE")
    rb.finish(sheet, folder / "reveal_parts_64.png")
    # three: the art beside the engine
    rb.set_scale(2)
    checks = {}
    tw, th, left = W / 4, H / 4, 96.0
    block = 2 * th + 34
    sheet = ui.Sheet(left + 4 * (tw + 8) + 12, 84 + len(RARITIES) * (block + 10), SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal: the art's frame over the engine's, laid from the parts alone", INK)
    t.text(20, 36, 9.5, "AR3 section 5. Each moment the art's frame above, the engine's below: the parts laid over, "
           "tinted, never added. Under each, how far apart in the sRGB 0 to 255: the mean, and the share past 24.", SOFT_INK)
    t.text(20, 50, 9.5, "The name is the art's sprite in both: the game's face sets it in the engine.", SOFT_INK)
    for j, (_, label) in enumerate(compare_moments("Common")):
        t.text(left + j * (tw + 8), 68, 9.5, label, "#E6E8EE")
    for i, rarity in enumerate(RARITIES):
        y = 84 + i * (block + 10)
        found = json.loads((folder / "compare" / f"{rarity}.json").read_text(encoding="utf-8"))
        checks[rarity] = found
        t.text(20, y + 4, 12, rarity, INK)
        for j, f in enumerate(found):
            x = left + j * (tw + 8)
            for k, kind in enumerate(("art", "engine")):
                shot = rs.load(folder / "compare" / f"{rarity}_{j}_{kind}.png")
                rs.paste(sheet.px, rs.shrink(shot, tw * K / shot.shape[1]), round(x * K), round((y + k * (th + 2)) * K))
            t.text(x, y + 2 * th + 8, 8.5, f"{f['t']:.2f} s: mean {f['mean']:.1f}, past 24 {100 * f['over_24']:.1f}%", SOFT_INK)
    rb.finish(sheet, folder / "reveal_parts_compare.png")
    spec["checks"] = dict(compare=checks, note="the art's frame against the engine's laid from these files, at 1 pixel "
                          "a point: mean, the share of pixels past 24 of 255, and the 99.5th percentile (worst)")
    (folder / "reveal.json").write_text(json.dumps(spec, indent=1), encoding="utf-8", newline="\n")


# --- main -------------------------------------------------------------------------------------------------------------

def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "shard"
    rarity = next((a for a in args if a in rb.PLANS), "Common")
    nums = [a for a in args[1:] if a.replace(".", "", 1).replace("-", "", 1).isdigit()]
    if mode == "figure":
        rb.shoot_figure(out)
    elif mode == "shard":
        shard_sheet(out)
    elif mode == "beats":
        beats(out, rarity, int(nums[0]) if nums else 0, int(nums[1]) if len(nums) > 1 else 99)
    elif mode == "strip":
        strip(out, rarity)
    elif mode == "frame":
        stage = Stage(out, rarity)
        for when in (float(a) for a in nums):
            rs.save(stage.frame(when), out / f"frame_{rarity}_{when:.3f}.png")
    elif mode == "read":
        read_frames(out, rarity)
    elif mode == "readsheet":
        read_sheet(out)
    elif mode == "names":
        names_frames(out)
    elif mode == "namesheet":
        names_sheet(out)
    elif mode == "colours":
        colours_sheet(out)
    elif mode == "clear":
        clear(out)
    elif mode == "movie":
        movie(out, rarity, int(nums[0]), int(nums[1]))
    elif mode == "assemble":
        assemble(out, rarity)
    elif mode == "parts":
        parts(out)
    elif mode == "compare":
        compare(out, rarity)
    elif mode == "partsheet":
        parts_sheets(out)
    else:
        raise SystemExit(f"Unknown mode {mode}")


if __name__ == "__main__":
    main()
