"""The base dressed (AR14): where the base's own kit stands on a plot, by the base's level, and a look at it.

blender.exe -b --factory-startup --python tools/blender/base_plan.py -- <out_dir> <mode>

  plan                  <out> is the handoff folder: plan.json, every level made so far, beside the kit's manifest.json
  look <level> [fast] [clear] [views]
                        <out>/base_<level>_<view>.png: the plot dressed, its machines as coloured boxes, under Lantern
                        Row's dusk, from the spawn's camera (`home`), from the Strip (`gate`), from the court's back
                        looking down the yard (`yard`), from the yard's end looking home (`back`), from a front
                        corner across the whole base (`across`) and from above (`above`). Naming views renders those
                        alone.
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
  1, the yard    the whole plot walled, 200 studs by 200 (the director, 2026-11-15: "the base must be that 200x200",
                 after "the base should be much much longer, it fine if some part a plain due to being low levels").
                 At the front's middle the lit court round the machines, 88 across and 48 deep: the gate on the Strip
                 with the level on its plate, the current lit in the floor from each bay to the battery and the
                 Breaker, two flood masts at its back, a transformer each side of the battery's line and of the
                 Breaker's rail. Behind it three plain blocks: the main conduit dead down the middle, a lot marked
                 each side, a pilot lamp at each junction. Each side of both, the wings out to the walls: plain deck,
                 a lot marked a block, and the pylons with their lines down the inside of each side wall.
  2 and 3        not made yet: each lights the yard a block further, so nothing a player has seen goes away.
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
GROUND = {"lot": "#7C7C8E", "ground": "#1A1D2E", "note": "the lot is the plot's own floor under the kit's floors: the deck tile "
          "(Base_Deck_Color.png), its Texture's Color3 at `lot`. It shows only as the last 8 studs under the back "
          "wall, the darker foot of that wall (the Kept and Tower overlays take it too, unmarked). The ground is "
          "the slab between plots, a flat colour. The Strip and the "
          "side street wear Lantern Row's paving tile, as its street does: stepping off the stones onto the plates "
          "is coming home."}
STAND_INS = {"machine": "#7E8AB0", "chamber": "#BFEFF5", "waiting": "#A2A7BC", "bay": "#56628C", "locked": "#1F2233",
             "battery": "#FFD23E", "generator": "#FFD23E", "training": "#C86A8A", "spawn": "#E9E2D2",
             "note": "until each machine has its model: the boxes in the kit's colours, so nothing on a plot is grey. "
                     "One steel body for every machine and one accent each; the chambers glow (Neon)."}


def machines():
    """The machines that have their model (AR15), each where the builder's stand-in stands: piece, across, in from
    the front edge, up, and what it stands for."""
    chamber_x, _, _ = base.machines.CHAMBERS
    top = base.machines.BODY[2]
    made = [("Breaker", 0.0, BREAKER, 0.0, "the Breaker's body")]
    made += [("BreakerChamber", side * chamber_x, BREAKER, top, f"chamber {i + 1}") for i, side in enumerate((-1, 1))]
    made += [("BreakerWaiting", 9.0 + 3.0 * k, BREAKER, 0.0, f"waiting place {k + 1}") for k in range(3)]
    return made


def plan(level=1):
    """The placements and the real lights of a level, in the plan's frame."""
    places, lights = [], []

    def put(name, x, inward, turn=0.0):
        places.append((name, round(x, 2), round(-inward, 2), turn))

    deep, half, yard, block = base.COURT[1], base.HALF, base.YARD, int(base.BLOCK)
    put("Court1", 0, 0)
    put("Gate1", 0, 0)
    floors = range(0, int(yard) - block + 1, block)                 # as many whole blocks as the plot takes
    for inward in floors:
        if inward >= deep:
            put("Yard", 0, inward)                                  # the plain yard behind the court, block after block
        put("Wings", 0, inward)                                     # and the deck each side, out to the walls
    # the wall, on the plot's own edge, the same on both sides of the middle line: each post carries the panel to the
    # next, and a half panel closes a run on the plot's 200. The sides run in from the front corners' posts; the back
    # runs in from its corners' posts to the way out at its middle; the front runs out from the gate's shoulders
    # At level 1 the back right corner isn't hung yet: its posts stand, and barriers close it (`open_`)
    open_ = level == 1
    for side in (-1, 1):
        hung = int(yard) - 8 - (16 if open_ and side > 0 else 0)
        for inward in range(0, hung, 16):
            put("Wall", side * half, inward, -90)
        if hung < yard - 8:
            for inward in (hung, yard - 8):
                put("WallEnd", side * half, inward, 0)
            for inward in (hung + 4, hung + 12, yard - 4):
                put("Barrier", side * half, inward, 90)
        else:
            put("WallHalf", side * half, yard - 8, -90)
        turn = 0 if side < 0 else 180                               # along the back, toward the middle
        for k in range(5):
            if open_ and side > 0 and k < 2:
                put("WallEnd", side * (half - 16 * k), yard, 0)
                for step in (4, 12):
                    put("Barrier", side * (half - 16 * k - step), yard, 0)
            else:
                put("Wall", side * (half - 16 * k), yard, turn)
        put("WallHalf", side * 20, yard, turn)
        put("WallEnd", side * 12, yard, 0)
        turn = 180 if side < 0 else 0                               # along the front, toward the corner
        for k in range(4):
            put("Wall", side * (base.WING + 16 * k), 0, turn)
        put("WallHalf", side * (half - 8), 0, turn)
    # the lines: a pylon every span down the inside of each side wall, from the front to the back, and its lines:
    # the base's length and its width seen from the Strip, over everything
    across, first = base.PYLON
    for side in (-1, 1):
        for inward in range(int(first), int(yard), int(base.SPAN)):
            put("Pylon", side * across, inward, 90)
            if inward > first:
                put("PowerSpan", side * across, inward, 90)
    # the floods: a mast at the back of each lane, looking down the lane toward the front
    inward, reach, height = base.FLOOD
    for side, name in ((-1, "Left"), (1, "Right")):
        put("FloodMast", side * base.LANE, inward, 0)
        lights.append((f"Flood{name}", side * base.LANE, -(inward - reach), height, "#EAF6FF", "spot"))
    # the transformers: one each side of the battery's line to the Breaker, clear of the bays' conduit so the spawn
    # sees the current run, and one each side of the Breaker's rail
    # a pair for every two open bays (research, 2026-11-15, AR14): level 1 has the battery's pair
    for across, inward in ((5.6, BATTERY - 6.0), (25.5, BREAKER))[:base.BAYS_AT[level] // 2]:
        for side in (-1, 1):
            put("Transformer", side * across, inward, 0)
    lights.append((*LAMP[:2], -LAMP[2], *LAMP[3:], "point"))
    if level == 1:
        building_site(put, lights)
    return places, lights


def building_site(put, lights):
    """Level 1: the plant is still going up (the director, 2026-11-15: "at level 1 it rly need to look like it under
    construction"). Everything stands on a marked lot or along a wall, and the nearer the court, the further along:
    the next bays' foundations are poured and scaffolded under a work light, the ones behind them are poured, and the
    far end is stock on the ground. A level finishes its sites into what it opens."""
    reach = base.FLOOD[1]
    for side, name in ((-1, "Left"), (1, "Right")):
        # the court, fenced from the site: barriers down its sides and at its back corners, the lanes left open
        for inward in (18, 34):
            put("Barrier", side * 46, inward, 90)
        for across in (30, 38):
            put("Barrier", side * across, 50, 0)
        # bays 3 and 4's lots, at 72: poured, scaffolded, lit
        put("Foundation", side * 22, 72, 0)
        put("Scaffold", side * 31.5, 72, 90)
        for across in (18, 26):
            put("Barrier", side * across, 62, 0)
        turn = -135 * side
        put("FloodMast", side * 29.5, 64.5, -turn)
        lights.append((f"Site{name}", side * (29.5 - reach * 0.7071), -(64.5 + reach * 0.7071), base.FLOOD[2], "#EAF6FF", "spot"))
        # bays 5 and 6's lots, at 120: poured
        put("Foundation", side * 22, 120, 0)
        for across in (18, 26):
            put("Barrier", side * across, 110, 0)
        put("Stack", side * 34, 120, 90)
    # scaffolds on the inside of the front wall, where the spawn's camera finds them
    put("Scaffold", -40, 2.4, 0)
    put("Scaffold", 52, 2.4, 0)
    # the crane, at the left wing's edge, its load over bay 3's foundation
    crane, target = (-50.0, 84.0), (-22.0, 72.0)
    put("Crane", *crane, round(math.degrees(math.atan2(crane[1] - target[1], target[0] - crane[0])), 1))
    # the cable, not pulled yet: drums along the dead conduit and at the far lots
    put("Drum", 5, 98, 0)
    put("Drum", -5, 146, 0)
    put("Drum", 22, 166, 0)
    put("Drum", 25.5, 170.5, 30)
    put("Stack", -22, 168, 0)
    # the wings. Right: the cabin by the gate, a hall's frame, a foundation, a low frame at the far end
    put("Cabin", 62, 22, 90)
    put("Stack", 72, 31, 0)
    put("Frame", 68, 72, 90)
    put("Foundation", 68, 120, 0)
    put("Barrier", 68, 108, 0)
    put("Frame", 68, 166, 0)
    # left: the stock by the gate, the crane's stock, a hall's frame
    put("Stack", -64, 18, 0)
    put("Stack", -73, 29, 90)
    put("Drum", -59, 30, 20)
    put("Drum", -56, 25.5, 75)
    put("Stack", -66, 70, 0)
    put("Frame", -68, 120, 0)
    # the open corner at the back right: the wall's panels stacked, a scaffold at the posts
    put("Scaffold", 84, 196.6, 0)
    put("Stack", 82, 186, 90)


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
        machines=dict(
            note="AR15: the machines that have their model, each in place of the builder's stand-in, at every level. "
                 "Laid as a placement is, raised by `up`. A chamber is its own piece so the builder lights each by "
                 "its state (EmissiveStrength: full while it breaks a shard, low when empty).",
            placements=[dict(piece=n, across=x, along=-i, up=z, turn=0.0, standsFor=w) for n, x, i, z, w in machines()]),
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
        for x in (-3.5, 3.5):                                      # a shard in each chamber, the builder's own
            b("Shard", (1.0, 1.0, 1.7), x, BREAKER, sum(base.machines.GAP) / 2, "chamber")
        for i, (name, x, inward, up, _) in enumerate(machines()):
            self.stock.stand(name, f"{tag}m{i}", self.at(front, face, x, inward, up), 0 if face > 0 else 180)
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


def see(out: Path, level, fast, clear, only=()):
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
    yard.person((6.0, -120.0), "Walker")
    yard.person((66.0, -40.0), "Hand")
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings")):
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
             "yard": behind((0, -(base.COURT[1] + 8.0)), -1), "back": behind((0, -(base.YARD - 14.0)), 1),
             "across": ((-88.0, -6.0, 11.0), (30.0, -130.0, 4.0)),
             "breaker": ((9.0, -29.0, 9.5), (0.0, -BREAKER, 6.0)), "strip": ((-8.0, 9.0, 7.5), (0.0, -BREAKER, 6.5)),
             "above": ((0.0, 96.0, 118.0), (0.0, -92.0, 0.0))}
    if only:
        views = {name: views[name] for name in only}
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
        see(out, int(args[1]), "fast" in args, "clear" in args, [a for a in args[2:] if a not in ("fast", "clear")])


if __name__ == "__main__":
    main()
