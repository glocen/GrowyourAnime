"""The base dressed (AR14): where the base's own kit stands on a plot, by the base's level, and a look at it.

blender.exe -b --factory-startup --python tools/blender/base_plan.py -- <out_dir> <mode>

  plan                  <out> is the handoff folder: plan.json, every level made so far, beside the kit's manifest.json
  look <level> [fast] [clear]
                        <out>/base_<level>_<view>.png: the plot dressed, its machines as coloured boxes, under Lantern
                        Row's dusk, from the spawn's camera (`home`), from the Strip (`gate`) and from above (`above`).
                        The kit's pictures are written into <out>/maps first. `clear`: from above alone with the haze
                        thinned, to read the layout

The base is a power plant (docs/design.md, "The base") and looks like one: every piece is the base kit's own
(base_kit.py), and none is Lantern Row's (the director, 2026-11-15: "it need look like an base not lantern row
ground"). The plot is the builder's (WorldService.plot, Config.World): the machines' places are copies of it, kept in
base_kit.py, for the floor's picture and for the look.

The frame, as Lantern Row's plan: `across` is the plot's own +X, to the right as the spawn looks; `along` is studs out
of the plot's front edge toward the Strip, so everything on the plot is negative; `turn` is degrees anticlockwise from
above, a piece's front (+Y) toward the Strip at 0. In the plot's own frame, a piece goes where the kit's Kit.Place puts
it with the front edge as its gate.

The levels (launch caps the base at 3):
  1, the yard    a walled court of deck plates round the machines: the gate on the Strip with the level on its plate,
                 the current lit in the floor from each bay to the battery and the Breaker, a pylon at each corner
                 with its lines down the sides, two flood masts at the back, a transformer each side of the battery's
                 line and of the Breaker's rail.
  2 and 3        not made yet: each adds to the one before, so nothing a player has seen goes away.
"""

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_kit as base  # noqa: E402
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
STREET = REPO / "build" / "handoff" / "LanternRow" / "maps" / "LanternRow_Paving_Color.png"   # the Strip's own stones

PLOT, STRIP, SPAWN, BREAKER, BATTERY = base.PLOT, base.STRIP, base.SPAWN, base.BREAKER, base.BATTERY
LAMP = ("BreakerLamp", 0.0, BREAKER, 10.0, "#8CF6FF")   # the heart's own light, over the chambers
LEVEL_NAMES = {1: "the yard"}
# What isn't a kit piece: flat colours for the builder's own slabs and boxes, from the kit's swatches.
GROUND = {"lot": "#7C7C8E", "ground": "#1A1D2E", "note": "the lot is the plot's floor beyond the court: the deck tile "
          "(Base_Deck_Color.png), its Texture's Color3 at `lot`, so the court is the brighter deck (the Kept and Tower "
          "overlays take it too, unmarked). The ground is the slab between plots, a flat colour. The Strip and the "
          "side street wear Lantern Row's paving tile, as its street does: stepping off the stones onto the plates "
          "is coming home."}
STAND_INS = {"machine": "#7E8AB0", "chamber": "#BFEFF5", "waiting": "#A2A7BC", "bay": "#56628C", "locked": "#1F2233",
             "battery": "#FFD23E", "generator": "#FFD23E", "training": "#C86A8A", "spawn": "#E9E2D2",
             "note": "until each machine has its model: the boxes in the kit's colours, so nothing on a plot is grey. "
                     "One steel body for every machine and one accent each; the chambers glow (Neon)."}


def plan(level=1):
    """The placements and the real lights of a level, in the plan's frame."""
    places, lights = [], []

    def put(name, x, inward, turn=0.0):
        places.append((name, round(x, 2), round(-inward, 2), turn))

    half, deep = base.COURT
    put("Court1", 0, 0)
    put("Gate1", 0, 0)
    # the wall: each post carries the panel to the next. The left side runs in from the front, the back runs to the
    # way out at its middle, the right side runs out to the front, and a wing closes each front corner to the gate
    for inward in (0, 16, 32):
        put("Wall", -half, inward, -90)
        put("Wall", half, deep - inward, 90)
    for x in (-half, -half + 16):
        put("Wall", x, deep, 0)
        put("Wall", x + 56, deep, 0)
    put("WallEnd", -half + 32, deep, 0)
    put("Wall", -base.WING, 0, 180)
    put("Wall", half, 0, 180)
    put("WallEnd", base.WING, 0, 0)
    # the lines: a pylon outside each corner, its lines down each side from the back to the front
    for side in (-1, 1):
        for inward in (0, deep):
            put("Pylon", side * (half + 4.5), inward, 90)
        put("PowerSpan", side * (half + 4.5), deep, 90)
    # the floods: a mast at the back of each lane, looking down the lane toward the front
    inward, reach, height = base.FLOOD
    for side, name in ((-1, "Left"), (1, "Right")):
        put("FloodMast", side * base.LANE, inward, 0)
        lights.append((f"Flood{name}", side * base.LANE, -(inward - reach), height, "#EAF6FF", "spot"))
    # the transformers: one each side of the battery's line to the Breaker, clear of the bays' conduit so the spawn
    # sees the current run, and one each side of the Breaker's rail
    for side in (-1, 1):
        put("Transformer", side * 5.6, BATTERY - 6.0, 0)
        put("Transformer", side * 25.5, BREAKER, 0)
    lights.append((*LAMP[:2], -LAMP[2], *LAMP[3:], "point"))
    return places, lights


def write_plan(out: Path):
    pieces = json.loads((out / "manifest.json").read_text(encoding="utf-8"))["pieces"]
    levels = {}
    for level in (1,):
        places, lights = plan(level)
        counts = {}
        for name, *_ in places:
            counts[name] = counts.get(name, 0) + 1
        levels[str(level)] = dict(
            name=LEVEL_NAMES[level], bays=base.BAYS_AT[level],
            placements=[dict(piece=n, across=x, along=y, turn=t) for n, x, y, t in places],
            lights=[dict(name=n, across=x, along=y, up=z, colour=c, kind=k, cone=kit.POOL_CONE if k == "spot" else None)
                    for n, x, y, z, c, k in lights],
            levelMark=dict(piece="Gate1", across=0.0, along=0.0, up=16.0, size=[11.0, 4.4], depth=2.2,
                           note="the level's number on the gate's plate, on both faces (+Y and -Y), in Power's yellow "
                                "(#FFD23E): the builder's text"),
            budget=dict(pieces=len(places), triangles=sum(pieces[n]["triangles"] * k for n, k in counts.items()),
                        lights=len(lights), counts=counts))
    (out / "plan.json").write_text(json.dumps(dict(
        what="AR14, the base dressed: where the base's own kit stands on a plot, by the base's level",
        kit="manifest.json, beside this file: every piece named here is one of its pieces",
        origin="the middle of the plot's front edge (the edge on the Strip), on the plot's floor",
        axes="`across` is the plot's own +X, to the right as the spawn looks; `along` is studs out of the front edge "
             "toward the Strip, so everything on the plot is negative; `turn` is degrees anticlockwise seen from above",
        toRoblox="in the plot's own frame (WorldService.plot's `at`), Kit.Place(placement, piece, front, floorY) with "
                 "front = -deep / 2: CFrame.new(across, floorY, front - along) * CFrame.Angles(0, math.rad(turn), 0) * "
                 "centre. A light the same way, by Kit.Light.",
        levels=levels, ground=GROUND, standIns=STAND_INS,
        lighting="the base stands under Lantern Row's dusk: the same sky, ambient, fog and bloom "
                 "(build/handoff/LanternRow/sky/lighting.json). The conduits, the wall's line and the lamps are "
                 "drawn for dusk, and under the place's daylight they don't read.",
        lightsNote="a SpotLight straight down from each flood mast's head and a PointLight over the Breaker's "
                   "chambers, Shadows off; everything else that glows is in a glow picture",
        collision="each piece's `collision` in the manifest; the court's floor and the lines are look only"),
        indent=1), encoding="utf-8")
    for level, entry in levels.items():
        print(f"level {level}: {json.dumps(entry['budget'])}")


# --- the look: the plot in Blender, for the maker's eye ----------------------------------------------------------------

def tile_material(name, image: Path, studs, tint="#FFFFFF"):
    mat, p = look._new(name)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coord, mapping, tex = nodes.new("ShaderNodeTexCoord"), nodes.new("ShaderNodeMapping"), nodes.new("ShaderNodeTexImage")
    mapping.inputs["Scale"].default_value = (1 / studs,) * 3
    tex.image = bpy.data.images.load(str(image), check_existing=True)
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

    def __init__(self, scene, level, maps: Path):
        self.scene, self.level = scene, level
        self.kit = look.Kit(look.DIRECTIONS["M"], look.glyph_images(bl.out_dir()))
        self.stock = base.Stock(maps, scene, self.kit)
        flat = {name: look.painted(f"Flat{name}", code, code) for name, code in {**STAND_INS, **GROUND}.items()
                if name != "note"}
        flat["light"] = look.glowing("DoorLight", "#8CF6FF", 1.2)
        flat["chamber"] = look.glowing("Chamber", STAND_INS["chamber"], 1.0)
        flat["lot"] = tile_material("Lot", maps / "Base_Deck_Color.png", base.DECK[1], GROUND["lot"])
        self.flat, self.stone = flat, tile_material("Stones", STREET, kit.PAVING[1])

    def at(self, front, face, x, inward, z=0.0):
        return (face * x, front - face * inward, z)

    def box(self, front, face, name, size, x, inward, z, mat):
        return self.kit.block(name, size, self.at(front, face, x, inward, z), mat)

    def plot(self, front, face):
        f, level = self.flat, self.level
        tag = "A" if face > 0 else "B"
        b = lambda name, size, x, i, z, mat: self.box(front, face, f"{name}{tag}", size, x, i, z, f[mat] if isinstance(mat, str) else mat)  # noqa: E731
        door, generator = base.DOOR, base.GENERATOR
        b("Lot", (PLOT, PLOT, 0.4), 0, PLOT / 2, -0.23, "lot")
        b("Breaker", (14, 6, 5), 0, BREAKER, 2.5, "machine")
        for x in (-3.5, 3.5):
            b("Chamber", (4, 4, 4), x, BREAKER, 7, "chamber")
        for k in range(3):
            b("Waiting", (2.5, 2.5, 1), 9 + 3 * k, BREAKER, 0.5, "waiting")
        for index, (x, inward) in enumerate(base.BAYS[:base.BAYS_AT[level]]):
            b("Bay", (10, 10, 0.4), x, inward, 0.2, "bay")
            if index:
                b("Locked", (10, 0.6, 3), x, inward - 5, 1.5, "locked")
        b("Battery", (6, 4, 3), 0, BATTERY, 1.5, "battery")
        b("Generator", (6, 5, 8), generator, BREAKER, 4, "machine")
        b("GeneratorFace", (4.4, 0.2, 3), generator, BREAKER + 2.6, 5.5, "generator")
        b("Training", (6, 5, 4), -door, BREAKER, 2, "machine")
        b("TrainingTop", (6.2, 5.2, 0.5), -door, BREAKER, 4.2, "training")
        b("TrainingPad", (4, 4, 0.4), -door, BREAKER + 6, 0.2, "bay")
        for x in (-3.5, 3.5):
            b("DoorPost", (1, 1, 10), door + x, BREAKER, 5, "machine")
        b("DoorLintel", (8, 1, 1), door, BREAKER, 9.5, "machine")
        b("DoorWay", (6, 0.2, 9), door, BREAKER, 4.5, "light")
        b("Spawn", (6, 6, 0.2), 0, SPAWN, 0.1, "spawn")
        places, lights = plan(level)
        _, watts, _ = look.DIRECTIONS["M"]["string_light"]
        for i, (name, x, along, turn) in enumerate(places):
            self.stock.stand(name, f"{tag}{i}", self.at(front, face, x, -along), turn + (0 if face > 0 else 180))
        for name, x, along, z, code, kind in lights:
            lamp = look.light(self.kit, self.scene, f"{name}{tag}", self.at(front, face, x, -along, z), code,
                              watts * kit.REAL_LIGHT, 40.0, kind="SPOT" if kind == "spot" else "POINT")
            lamp.data.use_shadow = False
            if kind == "spot":
                lamp.data.spot_size, lamp.data.spot_blend = math.radians(kit.POOL_CONE), 0.7

    def person(self, at, name="Avatar"):
        """A player's size, in bone: where they stand."""
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
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1] * (0.15 if clear else 1.0), azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = Yard(scene, level, out / "maps")
    yard.plot(0.0, 1)
    yard.plot(STRIP, -1)
    yard.kit.block("Strip", (3 * PLOT, STRIP, 0.4), (0, STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * PLOT, 4 * PLOT, 0.4), (0, STRIP / 2, -0.3), yard.flat["ground"])
    yard.person((0, -SPAWN))
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Court")):
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
