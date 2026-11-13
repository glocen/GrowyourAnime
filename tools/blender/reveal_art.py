"""AR3, section 5: the reveal's look, the art sheet (docs/asset-requests.md; the block-in is section 4 and
reveal_blockin.py, whose form, beats and layout B research accepted). Finished here, with research's six fixes:

1. The name lands as a hit: larger, slammed to size in three frames with an overshoot, a glint along its rule, the
   screen kicked, and Rook's recoil under it (his Reveal clip's `Name` marker, rook_clips.py).
2. The name's size follows the rarity, Common's to 1.3 times at Mythical.
3. The split's flash follows the rarity: a pop held to the shard for a Common; only Legendary and Mythical white out.
4. The low rarities start the clip further in, so a Common's colours come 1.0 s after the tap.
5. The frame's base point reads from Epic up: he stands on the window's sill, the sill drawn over his soles, and the
   points hang free below it.
6. The fold keeps one readable line: Rook's head is up out of it (rook_clips.py).

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
  movie <rarity> i j / assemble <rarity>   at 60 a second, 1 px a point -> reveal_art_<rarity>.mp4
  parts                     the engine's files: images/, meshes/, reveal.json, and their review sheet
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
CX = rb.STAGE["B"]             # where he and the window stand once the name is down (layout B)
KNOCK, NAME = 51 / FPS, 55 / FPS   # Rook's Reveal: the ram fires; the kick's floor, where his name lands (rook_clips.py)
RARITIES = list(ui.RARITIES)
OFFSET = dict(zip(RARITIES, (0.40, 0.32, 0.18, 0.0, 0.0, 0.0)))     # fix 4: how far into the clip he appears
HOLD = dict(zip(RARITIES, (0.55, 0.65, 0.80, 0.95, 1.10, 1.25)))    # the name held before the card
NAME_SCALE = dict(zip(RARITIES, (1.0, 1.06, 1.12, 1.18, 1.24, 1.30)))  # fix 2
NAME_SIZE, NAME_LEFT, NAME_BASE = 58.0, 70.0, 214.0
NAME_MAX = 326.0               # the widest a name may land: from its left edge to 14 points short of the widest frame's wing
SLAM = 1.7                     # the name arrives this much larger, and is down in three frames
SHAKE = dict(zip(RARITIES, (2.5, 3.0, 3.5, 4.5, 5.5, 6.5)))         # points the screen kicks down as the name lands
# fix 3: the split's flash. A radius in points held to the shard, or None: the whole screen goes white.
FLASH = dict(zip(RARITIES, ((70.0, 0.55, 0.10), (95.0, 0.6, 0.11), (135.0, 0.7, 0.12), (190.0, 0.8, 0.14),
                            (None, 1.0, 0.22), (None, 1.0, 0.26))))
NAMES = dict(zip(RARITIES, ("ROOK", "SABLE", "LYRIC", "HALCYON", "STELLANE", "UMBRIEL")))


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
    """The name's size against its own at `u` seconds from landing: 1.7 times in, down in three frames, under its size
    on the frame it lands, then a small rebound and still."""
    if u < -0.05:
        return None
    if u < 0:
        return 0.93 + (SLAM - 0.93) * (-u / 0.05) ** 1.6
    return 1.0 - 0.07 * math.exp(-u / 0.03) * math.cos(u / 0.05 * math.pi)


def kick(u, rarity):
    """Points the screen sits below its rest as the name lands: down at once, a rebound, still in about 0.2 s."""
    if u < 0:
        return 0.0
    return SHAKE[rarity] * math.exp(-u / 0.05) * math.cos(u / 0.09 * 2 * math.pi)


class Stage(rb.Stage):
    """Everything a frame is made of, kept between frames: the block-in's stage, finished, layout B only."""

    def __init__(self, out: Path, rarity, name=None):
        self.out, self.rarity, self.layout = out, rarity, "B"
        self.plan, self.light, self.r = rb.PLANS[rarity], rb.LIGHT[rarity], rb.RARITIES[rarity]
        self.when = times(rarity)
        self.set_name(name or NAMES[rarity])
        self.figure = rb.Figure(out)
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

    def frame(self, t_):
        t, plan, light, r, K = self.t, self.plan, self.light, self.r, ui.K
        px = t.px
        px[..., :3], px[..., 3] = self.room, 1.0
        colour, level = self.glow_at(t_)
        split, tau = plan["split"], t_ - plan["split"]
        clip = tau + OFFSET[self.rarity]          # where his clip is
        cx = W / 2 + (CX - W / 2) * smooth((tau - 0.4) / 0.3)  # he steps right as he opens up
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
        x0 = round((cx - rb.TILE[0] / 2) * K)
        if tau >= 0:  # the fighter: dark first, then his colours from the ram as it fires
            shot = self.figure.at(clip)
            alpha = shot[..., 3]
            flood = (clip - KNOCK) / 0.1
            ax, ay = self.figure.accent
            yy, xx = np.mgrid[0:shot.shape[0], 0:shot.shape[1]].astype(np.float32)
            reach = np.hypot(xx - ax, yy - ay)
            edge = flood * 500.0 * K
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
            rs.paste(px, body, x0, -round(LIFT * K))
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
                    add(px, colour, rb.beams(leak, cx * K, cy * K, reach=0.9 + 1.6 * level, f=2 * K) * 1.6 * level)
                add(px, colour, blur(leak, 2.5 * K) * 1.8)
                add(px, WHITE, blur(leak, K / 2) * (0.55 + 0.45 * level) if K > 1 else leak * 0.8 * (0.55 + 0.45 * level))
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

    def draw_name(self, px, u, s):
        t, r, K = self.t, self.r, ui.K
        sprite = rs.shrink(self.name, s / SLAM)   # whole from its first frame: a hit doesn't fade in
        burn = max(0.0, 1.0 - max(u, 0.0) / 0.14) ** 2   # it arrives white-hot and cools to the room's ivory
        sprite[..., :3] = sprite[..., :3] + (WHITE - sprite[..., :3]) * burn
        width, height = self.name.shape[1] / SLAM, self.name.shape[0] / SLAM   # its size once down, in pixels
        mx, my = NAME_LEFT * K + width / 2, NAME_BASE * K - height / 2
        # it grows from a point on its foot, a third in: it comes down onto its rule, and the longest at Mythical's
        # size still clears the screen's left edge at 1.7 times
        rs.paste(px, sprite, round(NAME_LEFT * K + 0.3 * (width - sprite.shape[1])), round(NAME_BASE * K - sprite.shape[0]))
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
                (colours - 0.12, "the ram up, still dark (skip from 1.0)"), (colours + 0.017, "it fires: the colours"),
                (name - 0.025, "the name slams in"), (name + 0.033, "down: the kick, the glint"),
                (name + 0.15, "the glint off the rule's end"), (card, "held, the card next"))
    return ((-0.1, "the shard waits"), (0.05, "the tap: the slant opens"), (0.36, "green: past Common"), (0.54, "blue"),
            (0.72, "purple"), (0.98, "gold (skip from 1.0)"), (1.24, "the breath: dark, drawn in"),
            (split + 0.02, "the split: the screen goes white"), (split + 0.2, "the window: three points; his head up"),
            (colours + 0.017, "it fires: the colours"), (name + 0.033, "down: the kick, the glint"), (card - 0.02, "held, the card next"))


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
        for j in range(3):
            tile = rs.shrink(rs.load(out / "read" / f"{rarity}_{j}.png"), 0.6 * ui.K)
            rs.paste(sheet.px, tile, round((left + j * (tw + gap)) * ui.K), round(y * ui.K))
    rb.finish(sheet, out / "reveal_art_rarity.png")


NAME_CHECK = ("UMBRIEL", "SHIOMARU", "MARIGOLD", "IRONHYMN", "STELLANE", "SLIPTAIL")  # the roster's longest, by eight letters


def names_frames(out: Path):
    """Mythical's name size with the roster's longest names, held, layout B's left half: one stage, the name swapped."""
    stage = Stage(out, "Mythical")
    (out / "names").mkdir(exist_ok=True)
    fits = {}
    for name in NAME_CHECK:
        stage.set_name(name)
        fits[name] = dict(points=round(stage.wide, 1), fit=round(stage.fit, 3))
        rs.save(stage.frame(stage.when["card"] - 0.02), out / "names" / f"Mythical_{name}.png")
    (out / "names" / "fits.json").write_text(json.dumps(fits, indent=1), encoding="utf-8", newline="\n")
    print(json.dumps(fits))


def names_sheet(out: Path):
    fits = json.loads((out / "names" / "fits.json").read_text(encoding="utf-8"))
    tw, th, gap, top = W / 2, H / 2, 8.0, 64.0
    sheet = ui.Sheet(40 + 2 * tw + gap, top + 3 * (th + 30) + 8, SHEET_GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 12, 15, "The reveal, the art: the longest names at Mythical's size", INK)
    t.text(20, 36, 9.5, f"AR3 section 5, fix 2. A name is {NAME_SIZE:.0f} points at Common, {NAME_SCALE['Mythical']:.2f} times at "
           f"Mythical, and lands no wider than {NAME_MAX:.0f} points: a longer one is set smaller, never cut. Held, layout B, "
           "half size.", SOFT_INK)
    for i, name in enumerate(NAME_CHECK):
        row, col = divmod(i, 2)
        x, y = 20 + col * (tw + gap), top + row * (th + 30)
        rs.paste(sheet.px, rs.shrink(rs.load(out / "names" / f"Mythical_{name}.png"), 0.5), round(x * ui.K), round(y * ui.K))
        f = fits[name]
        said = "fits" if f["fit"] >= 1 else f"set at {f['fit']:.2f} to fit"
        t.text(x, y + th + 5, 9.5, f"{name.title()}{' (Mythical)' if name == NAMES['Mythical'] else ''}: "
               f"{f['points']:.0f} points at Mythical's size, {said}", "#E6E8EE")
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
    """The kit's slices with the director's hues on Uncommon, Rare and Epic: the metals the reveal's frames wear, which
    the kit's own tinting (the next piece) takes."""
    import ui_kit as kit
    saved = dict(ui.RARITIES)
    ui.RARITIES.update({k: rb.RARITIES[k] for k in ("Uncommon", "Rare", "Epic")})
    kit.IMAGES.clear()
    ui.K = kit.K
    kit.panels()
    kit.buttons()
    kit.frames()
    kit.icons()
    ui.RARITIES.update(saved)
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
    elif mode == "movie":
        movie(out, rarity, int(nums[0]), int(nums[1]))
    elif mode == "assemble":
        assemble(out, rarity)
    else:
        raise SystemExit(f"Unknown mode {mode}")


if __name__ == "__main__":
    main()
