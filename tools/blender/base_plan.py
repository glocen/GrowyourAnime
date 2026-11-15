"""The base dressed (AR14): where the festival kit's pieces stand on a plot, by the base's level, and a look at it.

blender.exe -b --factory-startup --python tools/blender/base_plan.py -- <out_dir> <mode>

  plan                  <out> is the handoff folder: plan.json, every level made so far
  look <level> [fast] [clear]
                        <out>/base_<level>_<view>.png: the plot dressed, its machines as coloured boxes, under Lantern
                        Row's dusk, from the spawn's camera (`home`), from the Strip (`gate`) and from above (`above`).
                        `clear`: from above alone with the haze thinned, to read the layout

Every piece is one of Lantern Row's kit (lantern_row_kit.py, build/handoff/LanternRow/): published already, so a level
is a plan and nothing to upload. The plot is the builder's (WorldService.plot, Config.World): the machines' places here
are copies of it, for the look only, and are read again when the layout moves.

The frame, as the kit's plan: `across` is the plot's own +X, to the right as the spawn looks; `along` is studs out of
the plot's front edge toward the Strip, so everything on the plot is negative; `turn` is degrees anticlockwise from
above, a piece's front (+Y) toward the Strip at 0. In the plot's own frame, a piece goes where the kit's Kit.Place puts
it with the front edge as its gate.

The levels (launch caps the base at 3; docs/design.md, "The base"):
  1, the yard    a paved court round the machines, between two low houses a side: two lantern strings run in from
                 the front, one down each lane beside the Breaker, over a runner of street stones; roped lamp posts
                 at the court's sides, with a way out between the houses; banners at the Festival Door; the level on
                 a sign at the front.
  2 and 3        not made yet: each adds to the one before, so nothing a player has seen goes away.
"""

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
KIT = REPO / "build" / "handoff" / "LanternRow"

# --- the plot, as the builder lays it (studs; `in` is from the front edge into the plot) --------------------------------

PLOT = 200.0
STRIP = 48.0
SPAWN = 40.0
BREAKER, BATTERY = 12.0, 26.0
BAYS = [(side * 22.0, 26.0 + row * 14.0) for row in range(3) for side in (-1, 1)]   # in the order they open
BAYS_AT = {1: 2, 2: 4, 3: 6}       # bays by the base's level (docs/design.md, research's seeds)
GENERATOR, DOOR = -17.0, 34.0      # across, level with the Breaker; the Training machine stands at -DOOR

# --- the dressing --------------------------------------------------------------------------------------------------------

COURT = (44.0, 48.0)   # the paved court: half across, and how far in from the front edge
LANE = 12.5            # a lane's middle, between the Breaker's line and the bays
RUN = 25.0             # a lane string's middle, in from the front: its far pole stands behind the spawn's camera
HOUSES = (9.5, 38.5)   # a side's two houses, in from the front, the rope's gap between them
LAMP = ("BreakerLamp", 0.0, BREAKER, 10.0, "#8CF6FF")   # the heart's own light, over the chambers
# What isn't a kit piece: flat colours for the builder's own slabs and boxes, from the kit's swatches.
GROUND = {"lot": "#8E86A6", "ground": "#2A2540", "note": "the lot is the plot's floor beyond the court: the paving tile "
          "too, its Texture's Color3 at `lot`, so the court is the brighter stone (the Kept and Tower overlays take "
          "it too, unmarked). The ground is the slab between plots, a flat colour. The Strip and the side street wear "
          "the paving tile untinted, as Lantern Row's floor does."}
STAND_INS = {"machine": "#B07A5A", "chamber": "#BFEFF5", "waiting": "#8A8098", "bay": "#3E8E8E", "locked": "#1E1426",
             "battery": "#D8A24A", "generator": "#D8A848", "training": "#C86A8A", "spawn": "#E8D8C0",
             "note": "until each machine has its model: the boxes in the kit's colours, so nothing on a plot is grey. "
                     "One lit-wood body for every machine, the stalls' own, and one accent each; the chambers glow (Neon)."}


def plan(level=1):
    """The placements and the real lights of a level, in the plan's frame."""
    places, lights = [], []

    def put(name, x, inward, turn=0.0):
        places.append((name, round(x, 2), round(-inward, 2), turn))

    half, deep = COURT
    # the lanes: a runner of street stones each side of the Breaker's line, a lantern string over each, front to back
    for side, name in ((-1, "Left"), (1, "Right")):
        put("StreetBay", side * LANE, RUN, 90)
        put("LanternString", side * LANE, RUN, 90)
        lights.append((f"Lane{name}Pool", side * LANE, -RUN, kit.POOL_HEIGHT, "#FFD49A", "spot"))
    # the court's sides: lamp posts and ropes, with a gap mid-side to walk out by; their lanterns hang in
    put("SquarePost", -half, 0, -90)
    put("SquarePostEnd", -half, 16, -90)
    put("SquarePost", -half, 32, -90)
    put("SquarePostEnd", -half, deep, -90)
    put("SquarePost", half, deep, 90)
    put("SquarePostEnd", half, 32, 90)
    put("SquarePost", half, 16, 90)
    put("SquarePostEnd", half, 0, 90)
    # the houses: two low ones a side behind the ropes, so the yard is a court off the Strip, not a slab in a field
    for side in (-1, 1):
        for inward in HOUSES:
            put("HouseLow", side * (half + 2.0), inward, 90 if side > 0 else -90)
    lights.append((*LAMP[:2], -LAMP[2], *LAMP[3:], "point"))
    # the way to the Festival Door: a banner each side of it, their cloth turned away from its light
    put("Banner", DOOR + 4.5, BREAKER, 0)
    put("Banner", DOOR - 4.5, BREAKER, 180)
    # the base's level, on a sign at the front, right of the lanes' mouth
    put("SignBoard", 22.0, 2.5, 0)
    return places, lights


def paving(level=1):
    half, deep = COURT
    return [dict(across=[-half, half], along=[-deep, 0.0])]


def write_plan(out: Path):
    pieces = json.loads((KIT / "manifest.json").read_text(encoding="utf-8"))["pieces"]
    levels = {}
    for level in (1,):
        places, lights = plan(level)
        counts = {}
        for name, *_ in places:
            counts[name] = counts.get(name, 0) + 1
        levels[str(level)] = dict(
            name="the yard",
            idea="a paved court round the machines, between two low houses a side: two lantern strings run in from "
                 "the front, one down each lane beside the Breaker; roped lamp posts at the court's sides; banners at "
                 "the Festival Door",
            bays=BAYS_AT[level],
            placements=[dict(piece=n, across=x, along=y, turn=t) for n, x, y, t in places],
            lights=[dict(name=n, across=x, along=y, up=z, colour=c, kind=k, cone=kit.POOL_CONE if k == "spot" else None)
                    for n, x, y, z, c, k in lights],
            paving=paving(level),
            levelMark=dict(piece="SignBoard", across=22.0, along=-2.5, up=6.2,
                           note="the level's number over the board's script, on both faces, in cream (#E8D8C0): the "
                                "builder's text until the gate has a piece of its own"),
            budget=dict(pieces=len(places), triangles=sum(pieces[n]["triangles"] * k for n, k in counts.items()),
                        lights=len(lights), counts=counts))
    (out / "plan.json").write_text(json.dumps(dict(
        what="AR14, the base dressed: where Lantern Row's kit stands on a plot, by the base's level",
        kit="build/handoff/LanternRow/manifest.json: every piece named here is one of its pieces, published already",
        origin="the middle of the plot's front edge (the edge on the Strip), on the plot's floor",
        axes="`across` is the plot's own +X, to the right as the spawn looks; `along` is studs out of the front edge "
             "toward the Strip, so everything on the plot is negative; `turn` is degrees anticlockwise seen from above",
        toRoblox="in the plot's own frame (WorldService.plot's `at`), Kit.Place(placement, piece, front, floorY) with "
                 "front = -deep / 2: CFrame.new(across, floorY, front - along) * CFrame.Angles(0, math.rad(turn), 0) * "
                 "centre. A light the same way, by Kit.Light.",
        levels=levels,
        pavingNote="each rectangle wears the kit's paving tile (LanternRow_Paving_Color.png, 8 studs square), as the "
                   "street's own floor does; the StreetBay runners lie over it, as in Lantern Row",
        ground=GROUND, standIns=STAND_INS,
        lighting="the base stands under Lantern Row's dusk: the same sky, ambient, fog and bloom "
                 "(build/handoff/LanternRow/sky/lighting.json). Under the place's daylight the lanterns don't read.",
        lightsNote="as Lantern Row's: a SpotLight straight down from each lane string's middle and a PointLight over "
                   "the Breaker's chambers, Shadows off; every other pool is painted in a runner's glow picture",
        collision="as Lantern Row's kit: the strings, the banners and the runners are look only; a post follows its "
                  "mesh and its rope is a low wall; the sign keeps its box"), indent=1), encoding="utf-8")
    for level, entry in levels.items():
        print(f"level {level}: {json.dumps(entry['budget'])}")


# --- the look: the plot in Blender, for the maker's eye ----------------------------------------------------------------

def paving_material(tint="#FFFFFF"):
    mat, p = look._new("BasePaving" + tint)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coord, mapping, tex = nodes.new("ShaderNodeTexCoord"), nodes.new("ShaderNodeMapping"), nodes.new("ShaderNodeTexImage")
    mapping.inputs["Scale"].default_value = (1 / kit.PAVING[1],) * 3
    tex.image = bpy.data.images.load(str(KIT / "maps" / "LanternRow_Paving_Color.png"), check_existing=True)
    links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], tex.inputs["Vector"])
    mix = nodes.new("ShaderNodeMix")
    mix.data_type, mix.blend_type = "RGBA", "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    mix.inputs[7].default_value = (*look.srgb(tint), 1)
    links.new(tex.outputs["Color"], mix.inputs[6])
    links.new(mix.outputs[2], p.inputs["Base Color"])
    look._fogged(mat, p.outputs[0])
    return mat


class Yard:
    """The Strip and the plots either side of it. A plot is stood by its front edge's place and the way it faces:
    `face` +1 is ours, its front toward +Y; -1 is the plot across the Strip."""

    def __init__(self, scene, level):
        self.scene, self.level = scene, level
        self.kit = look.Kit(look.DIRECTIONS["M"], look.glyph_images(bl.out_dir()))
        self.stock = kit.Stock(KIT / "maps", scene, self.kit)
        flat = {name: look.painted(f"Flat{name}", code, code) for name, code in {**STAND_INS, **GROUND}.items()
                if name != "note"}
        flat["light"] = look.glowing("DoorLight", "#8CF6FF", 1.2)
        flat["chamber"] = look.glowing("Chamber", STAND_INS["chamber"], 1.0)
        flat["lot"] = paving_material(GROUND["lot"])
        self.flat, self.stone = flat, paving_material()

    def at(self, front, face, x, inward, z=0.0):
        return (face * x, front - face * inward, z)

    def box(self, front, face, name, size, x, inward, z, mat):
        return self.kit.block(name, size, self.at(front, face, x, inward, z), mat)

    def plot(self, front, face):
        f, level = self.flat, self.level
        tag = "A" if face > 0 else "B"
        b = lambda name, size, x, i, z, mat: self.box(front, face, f"{name}{tag}", size, x, i, z, f[mat] if isinstance(mat, str) else mat)  # noqa: E731
        b("Lot", (PLOT, PLOT, 0.4), 0, PLOT / 2, -0.23, "lot")
        for rect in paving(level):
            (x0, x1), (y0, y1) = rect["across"], rect["along"]
            b("Court", (x1 - x0, y1 - y0, 0.4), (x0 + x1) / 2, -(y0 + y1) / 2, -0.21, self.stone)
        b("Breaker", (14, 6, 5), 0, BREAKER, 2.5, "machine")
        for x in (-3.5, 3.5):
            b("Chamber", (4, 4, 4), x, BREAKER, 7, "chamber")
        for k in range(3):
            b("Waiting", (2.5, 2.5, 1), 9 + 3 * k, BREAKER, 0.5, "waiting")
        for index, (x, inward) in enumerate(BAYS[:BAYS_AT[level]]):
            b("Bay", (10, 10, 0.4), x, inward, 0.2, "bay")
            if index:
                b("Locked", (10, 0.6, 3), x, inward - 5, 1.5, "locked")
        b("Battery", (6, 4, 3), 0, BATTERY, 1.5, "battery")
        b("Generator", (6, 5, 8), GENERATOR, BREAKER, 4, "machine")
        b("GeneratorFace", (4.4, 0.2, 3), GENERATOR, BREAKER + 2.6, 5.5, "generator")
        b("Training", (6, 5, 4), -DOOR, BREAKER, 2, "machine")
        b("TrainingTop", (6.2, 5.2, 0.5), -DOOR, BREAKER, 4.2, "training")
        b("TrainingPad", (4, 4, 0.4), -DOOR, BREAKER + 6, 0.2, "bay")
        for x in (-3.5, 3.5):
            b("DoorPost", (1, 1, 10), DOOR + x, BREAKER, 5, "machine")
        b("DoorLintel", (8, 1, 1), DOOR, BREAKER, 9.5, "machine")
        b("DoorWay", (6, 0.2, 9), DOOR, BREAKER, 4.5, "light")
        b("Spawn", (6, 6, 0.2), 0, SPAWN, 0.1, "spawn")
        places, lights = plan(level)
        colour, watts, _ = look.DIRECTIONS["M"]["string_light"]
        for i, (name, x, along, turn) in enumerate(places):
            self.stock.stand(name, f"{tag}{i}", self.at(front, face, x, -along), turn + (0 if face > 0 else 180))
        for name, x, along, z, code, kind in lights:
            lamp = look.light(self.kit, self.scene, f"{name}{tag}", self.at(front, face, x, -along, z), code,
                              watts * kit.REAL_LIGHT, 40.0, kind="SPOT" if kind == "spot" else "POINT")
            lamp.data.use_shadow = False
            if kind == "spot":
                lamp.data.spot_size, lamp.data.spot_blend = math.radians(kit.POOL_CONE), 0.7

    def person(self, at, name="Avatar"):
        """A player's size, in cream: where they stand."""
        x, y = at
        for part, size, z in (("Legs", (2, 1, 2), 1), ("Body", (4, 1, 2), 3), ("Head", (1.2, 1.2, 1.2), 4.6)):
            self.kit.block(f"{name}{part}", size, (x, y, z), self.flat["spawn"])


def camera(scene, name, eye, target):
    data = bpy.data.cameras.new(name)
    data.sensor_fit, data.angle_y, data.clip_end = "VERTICAL", math.radians(look.FOV), 2000
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = eye
    obj.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    return obj


def behind(at, heading):
    """The game's camera behind a player at `at`, looking along `heading` (+1 toward +Y): Roblox's start zoom and the
    replay's pitch, as the look script's."""
    pitch = math.radians(20.0)
    focus = Vector((at[0], at[1], 3.0 + look.FOCUS))
    eye = focus + Vector((0, -heading * math.cos(pitch), math.sin(pitch))) * look.ZOOM
    return tuple(eye), tuple(focus)


def see(out: Path, level, fast, clear):
    d = look.DIRECTIONS["M"]
    kit.PHASE["key"] = "M"
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1] * (0.15 if clear else 1.0), azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    yard = Yard(scene, level)
    yard.plot(0.0, 1)
    yard.plot(STRIP, -1)
    yard.kit.block("Strip", (3 * PLOT, STRIP, 0.4), (0, STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * PLOT, 4 * PLOT, 0.4), (0, STRIP / 2, -0.3), yard.flat["ground"])
    yard.person((0, -SPAWN))
    for obj in yard.kit.pieces:
        if obj.name.startswith(("LanternString", "StreetBay")):
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
    scene.eevee.taa_render_samples = 8 if fast else 32
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    views = {"home": behind((0, -SPAWN), 1), "gate": behind((0, STRIP / 2), -1),
             "above": ((0.0, -112.0, 78.0), (0.0, -20.0, 0.0))}
    if clear:   # the layout, with the dusk's haze thinned: from above the haze veils it
        views = {"above_clear": views["above"]}
    for name, (eye, target) in views.items():
        scene.camera = camera(scene, name, eye, target)
        linear = look.render_linear(scene, out / f"base_{level}_{name}.exr")
        rs.save(look.finish(linear, d), out / f"base_{level}_{name}.png")
        (out / f"base_{level}_{name}.exr").unlink(missing_ok=True)
    print(f"level {level}: {len(yard.kit.pieces)} objects in the look")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "plan"
    if mode == "plan":
        write_plan(out)
    elif mode == "look":
        see(out, int(args[1]), "fast" in args, "clear" in args)


if __name__ == "__main__":
    main()
