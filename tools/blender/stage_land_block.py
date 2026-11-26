"""AR37: a stage lands, the grey block (docs/asset-requests.md, AR37). The effect a base machine plays when it changes
stage. A, the Climbing Ring, is research's pick; C, the Coil, waits in polish-later as a variant (B, the Pillar, is out;
it's in f2dc53e). The hero rises up the machine from the ground, accelerating, and bursts at its top. The cover is the
machine's own shape: a Highlight on the old model fills to full as the climb rises, the swap happens under the full
fill, and the new model's fill cools (research's must-fix, AR37, "Research's verdict and pick").

Every part is sized from the machine's box (the larger of its two stages): `r`, half its footprint's diagonal plus 0.6,
and `h`, its height plus 0.5. The beats are frames at 60 (BEATS), the same in all three; the frames are drawn at 30 a
second. Grey: the effect is a near-white light, the yard in its colours at base level 2, under the place's dusk.

Two views: the player's camera at the Forge's prompt, turned to it, as the Forge goes from Stage I to II; and from the
court, turned to the plot's middle, as the generator, the Forge and the Training machine go to Stage II together (a
base level-up). Rendered in Blender; nothing is seen in Studio.

blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/stage_land_block.py -- <abs out_dir> render forge|court [A|C ...] [void]
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/stage_land_block.py -- <abs out_dir> sheet [void]
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/stage_land_block.py -- <abs out_dir> movie forge|court

`void` draws the colour pass, in the void's light (LOOKS); without it, the grey block. Give each its own out_dir.
"""

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

GREY = "#F2EEFA"                 # the block's light: near white, a breath of the void's violet
# The looks. Each part's colour runs up it (z 0 its foot, 1 its top) through (z, colour) stops. The void's is the colour
# pass, as the game draws it from the kit (AR37, "The colour pass"): the hoop and the shaft are FxColumn in fx_rise_Void
# (tools/blender/fx_kit.py, its Void palette; the hoop turned over, so the core is its top edge), their ladder's stops
# here where fx_rise puts them; the thrown ring is a short FxColumn in Neon, the game's Void violet; the light in that
# violet; the Highlight's fill near white, its outline the violet.
VOID = dict(core="#F6F0FF", mid="#E2D0FF", deep="#A97CFF", foot="#7A57D4", neon="#B58CFF")   # foot: fx_rise's V 1
LOOKS = {
    "grey": dict(said="in grey", hoop=[(0, GREY), (1, GREY)], hoop_floor=0.0, hoop_power=2.5,
                 shaft=[(0, GREY), (1, GREY)], thrown=GREY, thrown_upright=False, light=GREY, fill=GREY, line=GREY,
                 thrown_glow=2.4, shaft_glow=2.2),
    "void": dict(said="in the void's light", hoop=[(0, VOID["foot"]), (0.18, VOID["deep"]), (0.55, VOID["mid"]), (1, VOID["core"])],
                 hoop_floor=0.45, hoop_power=1.2,
                 shaft=[(0, VOID["core"]), (0.45, VOID["mid"]), (0.82, VOID["deep"]), (1, VOID["foot"])],
                 thrown=VOID["neon"], thrown_upright=True, light=VOID["neon"], fill="#EEE4FF", line=VOID["neon"],
                 thrown_glow=1.6, shaft_glow=1.5),
}
LOOK = LOOKS["grey"]
RATE = 30                        # frames drawn a second
BEATS = dict(rise=33, swap=35, peak=37, end=63)   # at 60: the climb's top, the swap, the cover's last full frame, gone
BEFORE, AFTER = 0.1, 0.12        # seconds drawn before the climb starts and after it's gone
DIRECTIONS = ("A", "C")
NAMES = {"A": "the Climbing Ring", "C": "the Coil"}
OUTLINE_PX = 2.0                 # the Highlight's outline, in pixels high on a 540 frame
TURNS = 2.25                     # C: the coil's turns from the ground to h
TAIL = 0.75                      # C: its tail, in turns
FILL_FROM = 12                   # at 60: the cover, a Highlight: the old model's fill starts, full at the climb's top
COOL = 56                        # at 60: the new model's fill is gone
LINE_FROM, LINE_GONE = 6, 60     # at 60: the outline comes in as the climb leaves the ground, and goes last
CLIMB = 2.6                      # the climbing hero's light at its top
THROWN_TALL = (0.3, 0.02)        # the void look's thrown ring, an upright band: studs, plus a share of r


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def ease_in(u):
    return clamp(u) ** 2


def ease_out(u):
    return 1.0 - (1.0 - clamp(u)) ** 3


def span(f, a, b):
    """How far frame f (at 60) is from a to b, 0 to 1."""
    return clamp((f - a) / (b - a))


# --- the parts: plain meshes, one material each, set frame by frame ---------------------------------------------------

def light_material(name, power=1.0, floor=1.0, attribute=False, colours=None):
    """Additive light, as a Neon part or a LightEmission 1 Beam: emission over a clear surface. Up the shape (its
    Generated Z), the light goes as floor + (1 - floor) * z^power, so a band can carry a bright top edge, and its
    colour runs through `colours`, (z, colour) stops (one colour, the look's, if none)."""
    import bpy
    import lantern_row_look as look
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.use_backface_culling = False
    for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
        try:
            setattr(mat, attr, val)
        except (AttributeError, TypeError):
            pass
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    coord, sep = nodes.new("ShaderNodeTexCoord"), nodes.new("ShaderNodeSeparateXYZ")
    pw, scale, add, strength = (nodes.new("ShaderNodeMath") for _ in range(4))
    pw.operation, scale.operation, add.operation, strength.operation = "POWER", "MULTIPLY", "ADD", "MULTIPLY"
    pw.inputs[1].default_value = power
    scale.inputs[1].default_value = 1.0 - floor
    add.inputs[1].default_value = floor
    strength.inputs[1].default_value = 0.0
    links.new(coord.outputs["Generated"], sep.inputs[0])
    links.new(sep.outputs["Z"], pw.inputs[0])
    links.new(pw.outputs[0], scale.inputs[0])
    links.new(scale.outputs[0], add.inputs[0])
    if attribute:                                           # C's ribbon: its fade along it, in a colour attribute
        col, by = nodes.new("ShaderNodeVertexColor"), nodes.new("ShaderNodeMath")
        col.layer_name, by.operation = "Fade", "MULTIPLY"
        links.new(add.outputs[0], by.inputs[0])
        links.new(col.outputs["Color"], by.inputs[1])
        links.new(by.outputs[0], strength.inputs[0])
    else:
        links.new(add.outputs[0], strength.inputs[0])
    em, clear, both = nodes.new("ShaderNodeEmission"), nodes.new("ShaderNodeBsdfTransparent"), nodes.new("ShaderNodeAddShader")
    stops = colours or [(0, LOOK["fill"]), (1, LOOK["fill"])]
    ramp = nodes.new("ShaderNodeValToRGB")
    elements = ramp.color_ramp.elements
    while len(elements) < len(stops):
        elements.new(0.5)
    for element, (z, code) in zip(elements, stops):
        element.position, element.color = z, (*look.srgb(code), 1)
    links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], em.inputs["Color"])
    links.new(strength.outputs[0], em.inputs["Strength"])
    links.new(clear.outputs[0], both.inputs[0])
    links.new(em.outputs[0], both.inputs[1])
    links.new(both.outputs[0], out.inputs["Surface"])
    return mat, dict(strength=strength.inputs[1], floor=add.inputs[1], scale=scale.inputs[1], power=pw.inputs[1])


def band(sides=64, flare=1.0):
    """An open upright band: radius 1 at its foot, `flare` at its top, from z 0 to 1."""
    verts, faces = [], []
    for k in range(sides):
        a = 2 * math.pi * k / sides
        verts += [(math.cos(a), math.sin(a), 0.0), (flare * math.cos(a), flare * math.sin(a), 1.0)]
    for k in range(sides):
        a, b = 2 * k, 2 * ((k + 1) % sides)
        faces.append((a, b, b + 1, a + 1))
    return verts, faces


def ring(sides=96, inner=0.9):
    """A flat ring in the world's plane, outer radius 1."""
    verts, faces = [], []
    for k in range(sides):
        a = 2 * math.pi * k / sides
        verts += [(math.cos(a), math.sin(a), 0.0), (inner * math.cos(a), inner * math.sin(a), 0.0)]
    for k in range(sides):
        a, b = 2 * k, 2 * ((k + 1) % sides)
        faces.append((a, b, b + 1, a + 1))
    return verts, faces


def shaft(sides=24):
    verts, faces = band(sides)
    top = len(verts)
    verts.append((0.0, 0.0, 1.0))
    faces += [(2 * k + 1, 2 * ((k + 1) % sides) + 1, top) for k in range(sides)]
    return verts, faces


class Part:
    def __init__(self, scene, name, geometry, **light):
        import bpy
        verts, faces = geometry
        data = bpy.data.meshes.new(name)
        data.from_pydata(verts, [], faces)
        self.mat, self.knobs = light_material(name, **light)
        data.materials.append(self.mat)
        self.obj = bpy.data.objects.new(name, data)
        self.obj.visible_shadow = False
        scene.collection.objects.link(self.obj)
        self.hide()

    def hide(self):
        self.obj.hide_render = True

    def show(self, at, size, strength, floor=None):
        self.obj.hide_render = strength <= 0.002
        self.obj.location, self.obj.scale = at, size
        self.knobs["strength"].default_value = strength
        if floor is not None:
            self.knobs["floor"].default_value = floor
            self.knobs["scale"].default_value = 1.0 - floor


class Coil:
    """C's ribbon, drawn again each frame: a band wound up the helix, its width up and down, fading to its tail."""

    def __init__(self, scene, name):
        import bpy
        self.scene, self.name = scene, name
        self.mat, self.knobs = light_material(name, power=1.0, floor=1.0, attribute=True)
        self.obj = None

    def show(self, centre, r, h, f):
        import bpy
        if self.obj is not None:
            data = self.obj.data
            bpy.data.objects.remove(self.obj)
            bpy.data.meshes.remove(data)
            self.obj = None
        u = ease_in(f / BEATS["rise"])
        if f < 0 or f > BEATS["rise"] + 4:
            return
        full = 2 * math.pi * TURNS
        head = full * u
        tail = max(0.0, head - 2 * math.pi * TAIL)
        knot = span(f, BEATS["rise"] - 1, BEATS["rise"] + 3)
        n = max(8, int((head - tail) / (2 * math.pi) * 96))
        verts, faces, fades = [], [], []
        for i in range(n + 1):
            s = i / n                                       # 0 the tail, 1 the head
            a = tail + (head - tail) * s
            z = h * a / full
            rr = r * (1.0 - (2 / 3) * knot * s ** 3)      # the head draws in to a knot at the top
            width = 0.5 + 1.5 * s ** 0.6                    # wide at the head, thin at the tail
            x, y = centre[0] + rr * math.cos(a), centre[1] + rr * math.sin(a)
            verts += [(x, y, z - width / 2), (x, y, z + width / 2)]
            fades.append(s ** 1.6)
        for i in range(n):
            faces.append((2 * i, 2 * i + 2, 2 * i + 3, 2 * i + 1))
        data = bpy.data.meshes.new(self.name)
        data.from_pydata(verts, [], faces)
        attr = data.color_attributes.new("Fade", "FLOAT_COLOR", "POINT")
        for i, fade in enumerate(fades):
            for k in (2 * i, 2 * i + 1):
                attr.data[k].color = (fade, fade, fade, 1.0)
        data.materials.append(self.mat)
        self.obj = bpy.data.objects.new(self.name, data)
        self.obj.visible_shadow = False
        self.scene.collection.objects.link(self.obj)
        fade_out = 1.0 - span(f, BEATS["rise"] + 1, BEATS["rise"] + 4)
        self.knobs["strength"].default_value = (1.4 + 1.3 * (CLIMB - 1.0) * u) * fade_out


# --- the cover: the machine's own shape, lit -----------------------------------------------------------------------------

def cover(f):
    """The cover's Highlight at frame f (at 60): (fill, outline), each 0 to 1 against FillTransparency and
    OutlineTransparency. The old model's fill eases in as the climb rises, full at its top; the swap is under the full
    fill; the new model's fill cools. The outline comes first, as the climb leaves the ground, and goes last."""
    if f < BEATS["peak"]:
        fill = ease_in(span(f, FILL_FROM, BEATS["rise"]))
    else:
        fill = (1 - span(f, BEATS["peak"], COOL)) ** 2
    line = ease_out(span(f, LINE_FROM, LINE_FROM + 14)) * (1 - span(f, COOL - 12, LINE_GONE)) ** 2
    return fill, line


def highlight(px, mask, fill, line):
    """A Highlight with DepthMode Occluded, drawn as Roblox draws one, over the finished frame: the fill a flat colour
    over the model's visible pixels, the outline a line OUTLINE_PX wide round them. `mask` is those pixels, 0 to 1."""
    import numpy as np

    def code(c):
        return np.array([int(c[k:k + 2], 16) / 255 for k in (1, 3, 5)], np.float32)

    grown, r = mask.copy(), int(math.ceil(OUTLINE_PX))
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= OUTLINE_PX * OUTLINE_PX:
                grown = np.maximum(grown, np.roll(np.roll(mask, dy, axis=0), dx, axis=1))
    a_fill, a_line = (fill * mask)[..., None], (line * np.clip(grown - mask, 0, 1))[..., None]
    px[..., :3] = px[..., :3] * (1 - a_fill - a_line) + code(LOOK["fill"]) * a_fill + code(LOOK["line"]) * a_line
    return px


# --- one machine's effect ----------------------------------------------------------------------------------------------

class Landing:
    """The directions' parts for one machine, and its two stages' objects to swap."""

    def __init__(self, scene, tag, old, new):
        import bpy
        from mathutils import Vector
        import lantern_row_look as look
        self.old, self.new = old, new
        bpy.context.view_layer.update()
        corners = [o.matrix_world @ Vector(c) for o in (old + new) for c in o.bound_box]
        lo = Vector([min(c[i] for c in corners) for i in range(3)])
        hi = Vector([max(c[i] for c in corners) for i in range(3)])
        self.centre = ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2)
        self.foot = max(lo.z, 0.0)
        self.w, self.d = hi.x - lo.x, hi.y - lo.y
        self.r = 0.5 * math.hypot(self.w, self.d) + 0.6
        self.h = hi.z - self.foot + 0.5
        self.hoop = Part(scene, f"{tag}Hoop", band(), power=LOOK["hoop_power"], floor=LOOK["hoop_floor"],
                         colours=LOOK["hoop"])
        if LOOK["thrown_upright"]:                          # the kit's depth rule: a short upright band, never edge-on
            self.thrown = Part(scene, f"{tag}Thrown", band(96), colours=[(0, LOOK["thrown"]), (1, LOOK["thrown"])])
        else:
            self.thrown = Part(scene, f"{tag}Thrown", ring(inner=0.93))
        self.shaft = Part(scene, f"{tag}Shaft", shaft(), power=1.0, floor=1.0, colours=LOOK["shaft"])
        self.coil = Coil(scene, f"{tag}Coil")
        data = bpy.data.lights.new(f"{tag}Light", "POINT")
        data.color = (0.95, 0.93, 1.0) if LOOK is LOOKS["grey"] else look.srgb(LOOK["light"])
        data.use_shadow, data.shadow_soft_size = False, 1.0
        self.light = bpy.data.objects.new(f"{tag}Light", data)
        scene.collection.objects.link(self.light)
        self.parts = (self.hoop, self.thrown, self.shaft)

    def at(self, z):
        return (self.centre[0], self.centre[1], self.foot + z)

    def frame(self, direction, f):
        """Everything at frame f (at 60) of `direction`."""
        for p in self.parts:
            p.hide()
        self.coil.show(self.centre, self.r, self.h, -1)
        swapped = f >= BEATS["swap"]
        for o in self.old:
            o.hide_render = swapped
        for o in self.new:
            o.hide_render = not swapped
        r, h, rise = self.r, self.h, BEATS["rise"]
        u = ease_in(f / rise) if f >= 0 else 0.0
        light_z, light_power = 0.0, 0.0
        if direction == "A":
            if 0 <= f <= rise + 3:
                pull = span(f, rise, rise + 3)
                tall = (0.5 + 1.3 * u) * (1.0 - 0.7 * pull)
                top = h * u
                self.hoop.show(self.at(max(top - tall, 0.0)), (r * (1 - (2 / 3) * ease_out(pull)),) * 2 + (tall,),
                               1.0 + (CLIMB - 1.0) * u + 1.0 * pull)
                light_z, light_power = top, 0.3 + 0.7 * u
        elif direction == "C":
            self.coil.show(self.centre, r, h, f)
            if 0 <= f <= rise:
                light_z, light_power = h * u, 0.3 + 0.7 * u
        if f > rise + 3:                                    # the light stays with the cover's fill
            light_z, light_power = h * 0.5, 0.8 * cover(f)[0]
        if direction in ("A", "C") and rise + 1 <= f <= 60:
            k = span(f, rise + 1, 60)
            tall = THROWN_TALL[0] + THROWN_TALL[1] * r       # the upright band's height, studs (the flat ring's is 1)
            self.thrown.show(self.at(h - tall / 2 if LOOK["thrown_upright"] else h),
                             (r * (0.4 + 1.3 * ease_out(k)),) * 2 + ((tall if LOOK["thrown_upright"] else 1.0),),
                             LOOK["thrown_glow"] * (1 - k) ** 2)
        if direction in ("A", "C") and BEATS["swap"] <= f <= 50:
            k = span(f, BEATS["swap"], 50)
            thick = 0.35 - 0.25 * k
            self.shaft.show(self.at(h), (thick, thick, 0.6 * h * ease_out(k) + 0.1), LOOK["shaft_glow"] * (1 - k) ** 2)
        self.light.location = self.at(light_z)
        self.light.data.energy = 9000.0 * light_power * (r / 8.0)
        self.light.hide_render = light_power <= 0.0


# --- the scene ---------------------------------------------------------------------------------------------------------

def frames():
    """The frames drawn: (index, frame at 60), at RATE a second."""
    step = 60 / RATE
    first = -round(BEFORE * RATE)
    last = round((BEATS["end"] / 60 + AFTER) * RATE)
    return [(i, (first + i) * step) for i in range(last - first + 1)]


def build(view):
    import bpy
    from mathutils import Vector
    import base_kit as base
    import base_plan as plan
    import base_training as training
    import base_forge_stages as fs
    import base_mill as mill
    import blcommon as bl
    import lantern_row_look as look

    out = bl.out_dir()
    made_rows = plan.machines
    plan.machines = lambda lv=1: [row for row in made_rows(lv) if not (
        row[0].startswith(("Generator", "Training")) or (row[0] == "SleepingStone" and "the Forge's place" in row[5]))]
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, 2, out / "maps")
    yard.plot(0.0, 1)
    yard.plot(plan.STRIP, -1)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Floor")):
            obj.visible_shadow = False
    look.sky(scene, d)
    look.sun(scene, d)
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = *look.SIZE, 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 12
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    kit_mat = yard.stock.mats["Kit"]

    def stand(name, mesh, x, inward):
        data = mesh.whole().to_object(name, kit_mat)
        obj = bpy.data.objects.new(name, data)
        obj.location = (x, -inward, 0.0)
        scene.collection.objects.link(obj)
        return obj

    def generator(stage):
        m = mill.Mesh()
        for row in base.generator.stages()[str(stage)]:
            mill.put(m, base.PIECES[row["piece"]]().mesh, mill.at(*row["at"]))
        return m

    fx, fin = base.FORGE
    if view == "court":
        player, target = (-10.0, 28.0), (0.0, 76.0)      # the court's back: the generator to one side, Training and the Forge past it
    else:
        player, target = (fx + 5.0, fin - 11.0), (fx, fin)
    eye, focus = fs.toward(player, target)
    scene.camera = plan.camera(scene, f"Cam{view}", eye, focus)

    def landing(tag, old, new, x, inward):
        return Landing(scene, tag, [stand(f"{tag}1", old, x, inward)], [stand(f"{tag}2", new, x, inward)])

    landings = [landing("Forge", fs.whole("forge", 1)[0], fs.whole("forge", 2)[0], fx, fin)]
    if view == "court":
        landings.append(landing("Generator", generator(1), generator(2), *base.GENERATOR))
        landings.append(landing("Training", training.whole(1), training.whole(2), *base.TRAINING))
    return scene, d, landings


def machine_mask(scene, landings, exr):
    """The machines' visible pixels, 0 to 1: drawn again with everything else held out (still hiding what stands
    behind it, as DepthMode Occluded) and the effect's own parts hidden, on a clear film; its alpha is the mask."""
    import lantern_row_look as look
    machines = {o for landing in landings for o in landing.old + landing.new}
    parts = [p.obj for landing in landings for p in landing.parts]
    parts += [landing.coil.obj for landing in landings if landing.coil.obj is not None]
    shown = [o for o in parts if not o.hide_render]
    held = [o for o in scene.objects if o.type == "MESH" and o not in machines and o not in parts]
    for o in shown:
        o.hide_render = True
    for o in held:
        o.is_holdout = True
    scene.render.film_transparent = True
    try:
        alpha = look.render_linear(scene, exr)[..., 3].copy()
    finally:
        scene.render.film_transparent = False
        for o in held:
            o.is_holdout = False
        for o in shown:
            o.hide_render = False
        exr.unlink(missing_ok=True)
    return alpha


def render(out, view, directions):
    import lantern_row_look as look
    import rook_sheet as rs
    scene, d, landings = build(view)
    shares = {}
    for direction in directions:
        folder = out / view / direction
        folder.mkdir(parents=True, exist_ok=True)
        for i, f in frames():
            for landing in landings:
                landing.frame(direction, f)
            path = folder / f"f{i:03d}.png"
            linear = look.render_linear(scene, path.with_suffix(".exr"))
            px = look.finish(linear, d)
            fill, line = cover(f)
            if fill > 0.002 or line > 0.002:
                px = highlight(px, machine_mask(scene, landings, path.with_suffix(".mask.exr")), fill, line)
            rs.save(px, path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            grey = px[..., :3] @ [0.2126, 0.7152, 0.0722]
            shares[f"{direction} {i}"] = round(float((grey >= 243 / 255).mean()), 5)   # the view's near-white share
        print(direction, view, "done")
    path = out / f"{view}_shares.json"
    old = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    path.write_text(json.dumps({**old, **shares}), encoding="utf-8")


# --- the sheets and the movies -----------------------------------------------------------------------------------------

def drawn_directions(out):
    return [dr for dr in DIRECTIONS if (out / "forge" / dr).is_dir() and (out / "court" / dr).is_dir()]


def sheet(out):
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    w, h = look.SIZE
    marks = list(frames())
    shares = {v: json.loads((out / f"{v}_shares.json").read_text(encoding="utf-8")) for v in ("forge", "court")}

    def tile(view, direction, i):
        return rs.load(out / view / direction / f"f{i:03d}.png")

    def index(f60):
        return min(range(len(marks)), key=lambda k: abs(marks[k][1] - f60))

    # the beats: the directions drawn, side by side, from both views
    drawn = drawn_directions(out)
    beats = [("the fill rising", 23), ("the climb's top, the fill full", BEATS["rise"]),
             ("the swap, under the fill", BEATS["swap"] + 1), ("cooling", 45), ("gone", BEATS["end"])]
    gap, tw, th = 14, w // 2, h // 2
    width = len(beats) * (tw + gap) + gap + 150
    rows = [(v, dr) for v in ("forge", "court") for dr in drawn]
    height = 60 + len(rows) * (th + gap) + 40 + 4 * 19
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, f"Grow your Anime, a stage lands (AR37): the cover in the machine's own shape, at the beats, "
                        f"{LOOK['said']}", "#EDE6D6", bold=0.2)
    for k, (said, f60) in enumerate(beats):
        t.text(150 + gap + k * (tw + gap), 42, 14, f"{said}, frame {f60} at 60", "#B4AC9C")
    y = 62
    for view, direction in rows:
        t.text(gap, y + th // 2 - 20, 14, f"{direction}, {NAMES[direction].split(' ', 1)[1]}", "#EDE6D6")
        t.text(gap, y + th // 2, 13, "at the Forge" if view == "forge" else "from the court", "#B4AC9C")
        for k, (_, f60) in enumerate(beats):
            rs.paste(page.px, rs.shrink(tile(view, direction, index(f60)), 0.5), 150 + gap + k * (tw + gap), y)
        y += th + gap
    notes = ["At the Forge: the player's camera at its prompt, turned to it, as it goes from Stage I to II. From the court: "
             "a player at the court's back turned to the plot's middle, as the generator, the Forge and the Training "
             "machine go to Stage II together.",
             f"The yard at base level 2 under the place's dusk, in Blender; the effect {LOOK['said']}. Peak "
             "near-white share of the view, the frame's pixels at 243 or over (the vfx handbook's YAVG measure, in numpy): "
             + "; ".join(f"{dr} {v} {max(val for key, val in shares[v].items() if key.startswith(dr)):.1%}"
                         for v in ("forge", "court") for dr in drawn) + "."]
    import textwrap
    lines = [ln for n in notes for ln in textwrap.wrap(n, 260)]
    for k, ln in enumerate(lines):
        t.text(gap, y + 10 + k * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "stage_land_beats.png")

    # the read at 64: each beat shrunk to 64 pixels high, then shown three times over, pixel for pixel
    import numpy as np
    small, blow = 64, 3
    sw = round(w * small / h)
    page = ui.Sheet(150 + len(beats) * (sw * blow + gap) + gap, 50 + len(rows) * (small * blow + gap) + 10, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, f"A stage lands (AR37), {LOOK['said']}: the read at 64 pixels high, at the same beats", "#EDE6D6",
           bold=0.2)
    y = 48
    for view, direction in rows:
        t.text(gap, y + small * blow // 2 - 10, 14, f"{direction}, {'at the Forge' if view == 'forge' else 'the court'}",
               "#EDE6D6")
        for k, (_, f60) in enumerate(beats):
            px = rs.shrink(tile(view, direction, index(f60)), small / h)
            rs.paste(page.px, np.repeat(np.repeat(px, blow, axis=0), blow, axis=1), 150 + gap + k * (sw * blow + gap), y)
        y += small * blow + gap
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "stage_land_64.png")

    # each direction's strip: every frame at 30, both views, a quarter size
    qw, qh, cols = w // 4, h // 4, 8
    for direction in drawn:
        n = len(marks)
        block = math.ceil(n / cols) * (qh + 22)
        page = ui.Sheet(cols * (qw + 8) + 2 * gap, 60 + 2 * (block + 30) + 40, "#14151C")
        t = page.tile(0, 0, page.w, page.h)
        t.text(gap, 14, 20, f"A stage lands (AR37), {direction}, {NAMES[direction]}, {LOOK['said']}: every frame at 30 a "
                            "second", "#EDE6D6", bold=0.2)
        y = 50
        for view in ("forge", "court"):
            t.text(gap, y, 14, "at the Forge" if view == "forge" else "from the court", "#B4AC9C")
            y += 22
            for k, (i, f60) in enumerate(marks):
                x0, y0 = gap + (k % cols) * (qw + 8), y + (k // cols) * (qh + 22)
                rs.paste(page.px, rs.shrink(tile(view, direction, i), 0.25), x0, y0)
                s = shares[view][f"{direction} {i}"]
                t.text(x0, y0 + qh + 2, 12, f"{f60:+.0f}" + (f"  white {s:.1%}" if s >= 0.005 else ""),
                       "#EDE6D6" if BEATS["rise"] <= f60 <= BEATS["peak"] else "#8E887C")
            y += block + 8
        for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
            rs.paste(page.px, layer, 0, 0)
        rs.save(page.px, out / f"stage_land_{direction}.png")


def movie(out, view):
    """The view's three directions one after another, at 30 a second, as an MP4 (Blender's own encoder)."""
    import bpy
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 960, 540, 100
    scene.render.fps = RATE
    se = scene.sequence_editor_create()
    strips = se.strips if hasattr(se, "strips") else se.sequences     # an empty collection is falsy: no `or`
    files = []
    for direction in drawn_directions(out):
        shots = sorted((out / view / direction).glob("f*.png"))
        files += [f"{direction}/{s.name}" for s in shots] + [f"{direction}/{shots[-1].name}"] * 12   # a breath between
    first = strips.new_image("Frames", str(out / view / files[0]), 1, 1)
    first.directory = str(out / view) + "/"
    first.elements[0].filename = files[0]
    for name in files[1:]:
        first.elements.append(name)
    scene.frame_start, scene.frame_end = 1, len(files)
    settings = scene.render.image_settings
    if hasattr(settings, "media_type"):
        settings.media_type = "VIDEO"
    settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format, scene.render.ffmpeg.codec = "MPEG4", "H264"
    scene.render.ffmpeg.constant_rate_factor = "HIGH"
    scene.render.filepath = str(out / f"stage_land_{view}.mp4")
    bpy.ops.render.render(animation=True)


def main():
    import blcommon as bl
    global LOOK
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    LOOK = LOOKS["void" if "void" in args else "grey"]
    if args[0] == "render":
        render(out, args[1], [a for a in args[2:] if a in DIRECTIONS] or list(DIRECTIONS))
    elif args[0] == "sheet":
        sheet(out)
    elif args[0] == "movie":
        movie(out, args[1])


if __name__ == "__main__":
    main()
