"""A large picture of each Void Shard grade, for the Breaker's chambers and the bag (the director, 2026-11-15: "Make a
decal for each void shards they need to look more mature and not like a small icon"; docs/decisions.md; AR12).

The shard is AR3's own model (reveal_blockin.Shard: one body, a grade's spires beside its foot), seen from the
reveal's front. The picture is painted from what the model knows at each pixel, not lit by a renderer: three flat
Workbench shots carry each face's normal, each point's place and each face's kind (facet, bevel, a seam's wall); the
same from behind, mirrored, is the far side seen through the crystal; a shot with the seams a hair open is its lines.
From those: the model's four tones as one ramp that deepens down the body, the far facets showing through, a rim
from behind, a streak across the front table, the bevels cut bright, and the shard's own pale violet light inside.

A grade is told by its spires, as on the model, and by its charge: a Standard is quiet, its light low; an Enriched
is lit along its lines; a Prismatic splits the light it holds, its inner facets and its rim in a spectrum.

    blender -b --factory-startup --python tools/blender/shard_grade_art.py -- build/handoff/UI/shards [images]

Writes the sheet shard_grade_art.png, and with `images` each grade's picture, shard_<grade>.png, 1024 pixels square.
Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import reveal_art as ra  # noqa: E402
import reveal_blockin as rb  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from reveal_blockin import add, blur, soft  # noqa: E402
from ui_sheet import WHITE, c  # noqa: E402

SIZE, SPAN = 1024, 6.3          # the picture, and the units of the model it spans: the body stands 736 pixels
BODY_TALL = 4.53 / SPAN * SIZE  # the body's height in the picture, whatever grows beside it
AZIMUTH, ELEVATION = 14.0, 6.0  # the reveal's front
CENTRE = (0.0, 0.0, 0.02)
REACH = 3.0                     # a place is written as a colour from -REACH to REACH

SUN = ra.SUN                                        # the model's own light: upper left, in front
BEHIND = Vector((0.82, 0.42, 0.38)).normalized()    # the rim's light: from the right, behind
WITHIN = Vector((0.35, 0.62, 0.70)).normalized()    # the far facets that catch the light inside
LIGHT = rb.SHARD_LIGHT                              # the shard's own light, the same in every shard

# The model's four tones (reveal_art.TONES), as one ramp by the light on a facet: deeper at its foot, paler at its top.
BODY = ((-1.0, "#080618"), (-0.3, "#0F0A28"), (0.05, "#1A1340"), (0.36, "#2B2068"), (0.62, "#4B3BA0"),
        (0.86, "#8472DC"), (1.05, "#A998F5"), (1.3, "#D2C6FF"))
EDGE = ((0.0, "#5646BE"), (0.5, "#A493F0"), (1.0, "#F5F0FF"))
RIM, INNER, HALO = "#A26BFF", "#7C68E8", "#8E78F0"
SPECTRUM = ("#58E6FF", "#6F8BFF", "#B06BFF", "#FF70E0", "#FF9CC8", "#9C8CFF", "#58E6FF")  # cool only: no gold, no red

# A grade's charge: how lit it is inside, how lit its lines are, and how far it splits its light.
GRADES = {
    "Standard": dict(charge=0.22, lines=0.0, prism=0.0,
                     note="Quiet: a dark cut crystal, its light low. The far facets show through it."),
    "Enriched": dict(charge=0.6, lines=0.55, prism=0.0,
                     note="Charged: its core lit, its lines alight, one spire grown at its foot."),
    "Prismatic": dict(charge=0.85, lines=0.8, prism=1.0,
                      note="It splits the light it holds: the far facets and the rim in a spectrum, two spires."),
}


# --- the model's shots -------------------------------------------------------------------------------------------------

def lin(v):
    return np.where(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055) ** 2.4).astype(np.float32)


def raw(path):
    """A shot's own numbers: what the model wrote, before any colour space."""
    image = bpy.data.images.load(str(path))
    image.colorspace_settings.name = "Non-Color"
    w, h = image.size
    data = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    px = data.reshape(h, w, 4)[::-1].copy()
    px[..., :3] = lin(px[..., :3])
    return px


class Shard(rb.Shard):
    """The block-in's shard, each face written with what the painting reads: its normal, its place, its kind."""

    def __init__(self, grade):
        super().__init__(grade)
        self.pose()
        bpy.context.view_layer.update()
        self.solids = list(self.pieces.values()) + [o for o in self.scene.objects if o.name.startswith("Bud")]
        facets = ra.facet_normals()
        seams = [Vector(n).normalized() for _, n in rb.SEAMS.values()]
        half = Vector((0.5, 0.5, 0.5))
        for obj in self.solids:
            mesh, world = obj.data, obj.matrix_world
            turn = world.to_3x3().normalized()
            normal, place, kind = (mesh.color_attributes.new(name, "FLOAT_COLOR", "CORNER")
                                   for name in ("Normal", "Place", "Kind"))
            for poly in mesh.polygons:
                n = poly.normal
                if any(abs(n.dot(s)) > 0.9995 for s in seams):
                    what = (0.0, 0.0, 1.0)
                elif any(n.dot(f) > 0.9995 for f in facets):
                    what = (1.0, 0.0, 0.0)
                else:
                    what = (0.0, 1.0, 0.0)
                wn = (turn @ n).normalized() * 0.5 + half
                for li in poly.loop_indices:
                    p = (world @ mesh.vertices[mesh.loops[li].vertex_index].co) / (2 * REACH) + half
                    normal.data[li].color = (*wn, 1.0)
                    place.data[li].color = (*p, 1.0)
                    kind.data[li].color = (*what, 1.0)

    def aim(self, behind=False):
        a, e = math.radians(AZIMUTH), math.radians(ELEVATION)
        offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e))) * 40
        self.view = offset.normalized()
        if behind:
            offset = -offset
        self.cam.data.ortho_scale = SPAN
        self.cam.location = Vector(CENTRE) + offset
        self.cam.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()

    def read(self, out, layer, behind=False):
        """One layer, as the camera sees it. From behind and mirrored, it's the far side seen through the crystal."""
        for obj in self.solids:
            attrs = obj.data.color_attributes
            attrs.active_color = attrs[layer]
            attrs.render_color_index = attrs.find(layer)
        self.aim(behind)
        scene = self.scene
        rs.workbench(scene, SIZE, SIZE, flat=True)
        scene.display.shading.color_type = "VERTEX"
        scene.render.image_settings.color_depth = "16"
        self.core.hide_render = True
        scene.render.filepath = str(out / "_shard.png")
        bpy.ops.render.render(write_still=True)
        px = raw(out / "_shard.png")
        (out / "_shard.png").unlink()
        return px[:, ::-1].copy() if behind else px

    def shots(self, out):
        s = {}
        normal = self.read(out, "Normal")
        s["alpha"] = normal[..., 3]
        s["normal"] = normal[..., :3] * 2 - 1
        s["place"] = (self.read(out, "Place")[..., :3] - 0.5) * 2 * REACH
        s["kind"] = self.read(out, "Kind")[..., :3]
        back = self.read(out, "Normal", behind=True)
        s["far normal"], s["far alpha"] = back[..., :3] * 2 - 1, back[..., 3]
        s["far kind"] = self.read(out, "Kind", behind=True)[..., :3]
        self.pose(gaps=(0.035, 0.035, 0.035, 0.035))  # its lines: the seams a hair open, the core behind them
        self.scene.render.image_settings.color_depth = "8"
        s["lines"] = rb.Shard.shoot(self, out, (SIZE, SIZE), SPAN, AZIMUTH, ELEVATION, CENTRE)[1]
        self.pose()
        self.aim()
        s["view"] = np.array(self.view, dtype=np.float32)
        inside = s["alpha"] > 0.99
        length = np.linalg.norm(s["normal"][inside], axis=-1)
        print(f"shots: normals {length.mean():.3f} long (1 is right), the far side's outline "
              f"{np.abs(s['alpha'] - s['far alpha']).mean():.4f} off the near one's")
        return s


# --- the painting ------------------------------------------------------------------------------------------------------

def step(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def ramp(t, stops):
    xs = [s for s, _ in stops]
    cols = np.stack([c(code) for _, code in stops])
    return np.stack([np.interp(t, xs, cols[:, j]) for j in range(3)], axis=-1).astype(np.float32)


def spectrum(s):
    return ramp(np.mod(s, 1.0), tuple((i / (len(SPECTRUM) - 1), code) for i, code in enumerate(SPECTRUM)))


def light(px, colour, a):
    """Light over a picture, in one colour or a colour a pixel."""
    colour = np.asarray(colour, dtype=np.float32)
    px[..., :3] = 1.0 - (1.0 - px[..., :3]) * (1.0 - np.clip(a, 0, 1)[..., None] * colour)


def unit(v):
    return v / np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-6)


def picture(s, grade):
    """The grade's picture: straight colour and cover, its own light spilling a little past its outline."""
    g = GRADES[grade]
    alpha, n, p = s["alpha"], unit(s["normal"]), s["place"]
    facet, bevel = s["kind"][..., 0], s["kind"][..., 1]
    far_n, far_facet, far_bevel = unit(s["far normal"]), s["far kind"][..., 0], s["far kind"][..., 1]
    sun, view = np.array(SUN, dtype=np.float32), s["view"]
    gy, gx = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32) / SIZE
    lit = n @ sun
    facing = n @ view
    prism = g["prism"]

    # The body: the model's tones by the light on a facet. Each facet runs paler toward the light along its own
    # plane, and the whole crystal deepens away from the light.
    across = unit(sun[None, None, :] - lit[..., None] * n)
    px = np.zeros((SIZE, SIZE, 4), dtype=np.float32)
    px[..., :3] = ramp(0.84 * lit + 0.2 * (p @ sun) / 2.4 + 0.17 * np.sum(p * across, axis=-1) / 1.3 - 0.07, BODY)

    # Inside: the far facets that catch the light, and their cuts, through every face that isn't in full light; then
    # the shard's own light, low in its middle.
    veil = facet * (1 - 0.7 * step(lit, 0.3, 0.9))
    core = np.exp(-(((gx - 0.5) / 0.13) ** 2 + ((gy - 0.54) / 0.22) ** 2))
    caught = step(far_n @ np.array(WITHIN, dtype=np.float32), 0.4, 0.7) * far_facet
    inner = c(INNER) * (1 - prism) + spectrum(1.3 * (far_n @ np.array((0.7, 0.1, 0.7), dtype=np.float32)) + 0.9 * gy) * prism
    light(px, inner, caught * veil * (0.1 + (0.5 + 0.08 * prism) * g["charge"] * (0.3 + core)))
    light(px, c("#B7A8FF"), blur(far_bevel, 1) * veil * (0.07 + 0.16 * g["charge"]))
    light(px, c(LIGHT), core * facet * g["charge"] * 0.42)

    # The rim: light from behind, along the outline, strongest on the faces that turn from the eye.
    near = (1 - step(blur(alpha, 9), 0.54, 0.96)) * 0.85 + (1 - step(blur(alpha, 26), 0.56, 0.97)) * 0.15
    turned = near * (0.3 + 0.7 * step(n @ np.array(BEHIND, dtype=np.float32), -0.2, 0.6)) * facet
    rim = c(RIM) * (1 - prism) + spectrum(1.1 * gy + 0.5 * gx + 0.4 * (n @ np.array((0.3, 0.2, 0.9), dtype=np.float32))) * prism
    light(px, rim, turned * (0.62 + 0.3 * prism))

    # The table: a streak of light across the flat that faces the eye, a wide band and a thin one.
    table = facet * step(facing, 0.9, 0.95)
    d = gx + 0.5 * gy
    light(px, WHITE, table * (np.exp(-((d - 0.70) / 0.035) ** 2) * 0.16 + np.exp(-((d - 0.775) / 0.011) ** 2) * 0.32))

    # The cuts: every bevel bright by its light, and a bloom off the brightest.
    bright = step(lit, -0.3, 0.5)
    edge = ramp(bright, EDGE)
    if prism:
        edge = edge * 0.6 + spectrum(1.1 * gy + 0.5 * gx + 0.15) * 0.4
    px[..., :3] = px[..., :3] * (1 - bevel[..., None]) + edge * bevel[..., None]
    light(px, c(LIGHT), blur(bevel * bright, 3) * 0.36)

    # Its lines, lit: the seams it will part on.
    lines = s["lines"]
    if g["lines"]:
        light(px, c(LIGHT), soft(lines, 14) * g["lines"] * 1.1)
        light(px, c(LIGHT), blur(lines, 2) * g["lines"] * 1.2)
        light(px, WHITE, blur(lines, 1) * g["lines"] * 0.9)

    # Past its outline: its own light, a little.
    halo = np.clip(soft(alpha, 34) * (0.12 + 0.26 * g["charge"]) + soft(lines, 20) * g["lines"] * 0.8, 0, 1) * (1 - alpha)
    cover = alpha + halo
    px[..., :3] = (px[..., :3] * alpha[..., None] + c(HALO) * halo[..., None]) / np.maximum(cover, 1e-6)[..., None]
    px[..., 3] = cover
    return px


def pictures(out):
    made = {}
    for grade in GRADES:
        made[grade] = picture(Shard(grade).shots(out), grade)
    return made


# --- the sheet ---------------------------------------------------------------------------------------------------------

GROUND, INK, SOFT_INK = ra.SHEET_GROUND, ra.INK, ra.SOFT_INK
ROOM = rb.GROUNDS[0][1]
DUSK = rb.GROUNDS[1][1]


def at(px, tall):
    """The picture with its body `tall` points high."""
    return rs.shrink(px, tall * ui.K / BODY_TALL)


def put(sheet, px, cx, cy):
    rs.paste(sheet.px, px, round(cx * ui.K - px.shape[1] / 2), round(cy * ui.K - px.shape[0] / 2))


def todays(out):
    """Today's shard in the Breaker: the HUD's mark, and the model's flat finish."""
    import hud_colour_sheet as h
    ui.K = h.K4
    h.kit.panels()
    h.kit.buttons()
    h.icons()
    mark = h.kit.IMAGES["Shard"]["px"].copy()
    ui.K = 2
    shard = ra.Shard("Standard")
    shard.pose()
    flat = shard.shoot(out, (SIZE, SIZE), SPAN, AZIMUTH, ELEVATION, CENTRE)[0]
    return mark, flat


def sheet(out, made, mark, flat):
    ui.K = K = 2
    sh = ui.Sheet(1180, 1010, GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: a picture for each Void Shard grade, larger and older than a mark (AR12)", INK)
    t.text(20, 36, 9.5, "The director, 2026-11-15: \"Make a decal for each void shards they need to look more mature and not "
           "like a small icon\". AR3's own model from the reveal's front, painted: the far facets through it, a rim "
           "from behind, a streak on its table, its own light inside.", SOFT_INK)
    t.text(20, 50, 9.5, "A grade is told by its spires, as on the model, and by its charge. Each is one picture, 1024 "
           "pixels square, its light spilling a little past its outline.", SOFT_INK)

    # Today's, then the three, large.
    y, th = 72.0, 356.0
    tile = sh.tile(20, y, 196, th)
    tile.paint(tile.poly(ui.cut_box(0, 0, 196, th)), c(ROOM))
    t.text(28, y + 8, 10, "Today", INK)
    t.text(28, y + 22, 8.5, "The HUD's mark, as the chambers", SOFT_INK)
    t.text(28, y + 33, 8.5, "draw it (50 pt), and on a chip (26 pt)", SOFT_INK)
    put(sh, rs.shrink(mark, 50 * K / mark.shape[0]), 20 + 70, y + 96)
    put(sh, rs.shrink(mark, 26 * K / mark.shape[0]), 20 + 140, y + 96)
    t.text(28, y + 146, 8.5, "The model's flat finish, as the reveal", SOFT_INK)
    t.text(28, y + 157, 8.5, "has it: the same for every grade", SOFT_INK)
    put(sh, at(flat, 150), 20 + 98, y + 258)
    for i, (grade, px) in enumerate(made.items()):
        x = 228 + i * 312
        tile = sh.tile(x, y, 300, th)
        tile.paint(tile.poly(ui.cut_box(0, 0, 300, th)), c(ROOM))
        tile.glow(tile.poly([(150, 160), (151, 160), (151, 161)]), 90.0, c(rb.VIOLET["ground"]), 0.9)
        put(sh, at(px, 215), x + 150, y + 168)
        t.text(x + 10, y + 8, 11, grade, INK)
        t.text(x + 10, y + th - 20, 8.5, GRADES[grade]["note"], SOFT_INK)

    # At the sizes it's seen at, on the Breaker's dark and on a dusk street's paving.
    y = 446.0
    t.text(20, y, 10, "At the sizes it's seen at, on the Breaker's dark and on a dusk street. Left to right in each: Standard, "
           "Enriched, Prismatic; then today's mark at that size.", SOFT_INK)
    sizes = (("a chamber's window, 96 pt", 96.0), ("a chamber as drawn today, 50 pt", 50.0), ("the bag, 40 pt", 40.0),
             ("a waiting chip, 26 pt", 26.0))
    for j, (name, code) in enumerate((("the Breaker's dark", ROOM), ("a dusk street", DUSK))):
        ty = y + 18 + j * 176
        tile = sh.tile(20, ty, 1140, 168)
        tile.paint(tile.poly(ui.cut_box(0, 0, 1140, 168)), c(code))
        ink = INK if j == 0 else "#17141F"
        t.text(28, ty + 6, 9, name, ink)
        x = 50.0
        for what, tall in sizes:
            wide = tall * 0.78
            x0 = x
            for px in made.values():
                put(sh, at(px, tall), x + wide / 2, ty + 138 - tall / 2)
                x += wide + (10 if tall > 60 else 8)
            x += 8
            size = tall * 1.15  # the mark's box holds its shard at about 0.87 of its height
            put(sh, rs.shrink(mark, size * K / mark.shape[0]), x + size * 0.4, ty + 138 - tall / 2)
            x += size * 0.8
            t.text((x0 + x) / 2, ty + 150, 8.5, what, ink, "CENTER")
            x += 34

    # In a chamber: the window, the name on its plate.
    y = 822.0
    t.text(20, y, 10, "In a chamber, as a sketch of its window (not the screen's art): the shard at 96 points, its grade "
           "and its time on the plate.", SOFT_INK)
    for i, (grade, px) in enumerate(made.items()):
        x, cw, ch = 20 + i * 172, 160.0, 160.0
        tile = sh.tile(x, y + 18, cw, ch)
        box = tile.poly(ui.cut_box(0, 0, cw, ch, 10, 0, 10, 0))
        tile.paint(box, tile.ramp("#1A1533", "#0D0A1C", tile.y / ch))
        tile.glow(tile.poly([(cw / 2, 66), (cw / 2 + 1, 66), (cw / 2 + 1, 67)]), 44.0, c("#3B2C7A"), 0.75)
        plate = np.maximum(box, 118 - tile.y)
        tile.paint(plate, c("#201A3A"))
        tile.line(box, 1.2, c("#4A3F78"))
        put(sh, at(px, 96), x + cw / 2, y + 18 + 66)
        t.text(x + 9, y + 25, 8.5, f"Chamber {i + 1}", "#B9B2D6")
        t.text(x + cw / 2, y + 18 + 126, 11, grade, INK, "CENTER")
        t.text(x + cw / 2, y + 18 + 143, 8.5, ("0:24", "12:40", "2:41:07")[i], "#FFE9A6", "CENTER")
    t.text(548, y + 30, 9.5, "For research's read:", INK)
    notes = (
        "The colour stays the shard's dark violet in every grade: its light tells nothing of the rarity inside.",
        "Prismatic's spectrum is new, and a grade's tell only: it sits on the rim, the far facets and the cuts, never the body.",
        "Lit lines on Enriched and Prismatic are the reveal's own seams, so the picture opens where the reveal does.",
        "Named and Starter shards aren't drawn here: they'd take Standard's picture until a ruling says otherwise.",
        "The reveal's model keeps its flat finish. This is a picture for the Breaker, the bag and any card that shows a shard.",
    )
    for i, line in enumerate(notes):
        t.text(548, y + 48 + i * 15, 9, line, SOFT_INK)
    rb.finish(sh, out / "shard_grade_art.png")


def main():
    out = bl.out_dir()
    made = pictures(out)
    if "images" in sys.argv:
        for grade, px in made.items():
            rs.save(px, out / f"shard_{grade.lower()}.png")
    mark, flat = todays(out)
    sheet(out, made, mark, flat)


if __name__ == "__main__":
    main()
