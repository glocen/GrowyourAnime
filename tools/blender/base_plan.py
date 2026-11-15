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
  1, the yard    the whole plot walled, 200 studs by 200 (the director, 2026-11-15: "the base must be that 200x200"),
                 and its machines spread across it (the same day: "just make it less clustered make it accross the
                 base"). A way in 20 studs wide runs clear from the gate to the generator, the plant's heart, 40 in,
                 over a well of void in the floor. One bus crosses the base through it: the Void Breaker and the
                 Festival Door 30 either side of the heart, a bay at each end, 68 out in the wings. Behind, in the
                 yard's first block, the main line runs to a junction and out to the battery and the Training
                 machine, 28 either side. No machine stands nearer another than 25 studs. Two flood masts flank the
                 heart, a transformer stands by each bay's line, the pylons run down the inside of each side wall,
                 and nothing else is stood: no site, no stock. Behind all of it the yard's blocks lie dormant: the
                 main conduit dead down the middle, a lot marked each side, a pilot lamp at each junction.
  2 and 3        not made yet: each wakes the yard a block further, so nothing a player has seen goes away.
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

PLOT, STRIP, SPAWN = base.PLOT, base.STRIP, base.SPAWN
GENERATOR, BREAKER, DOOR, BATTERY, TRAINING = base.GENERATOR, base.BREAKER, base.DOOR, base.BATTERY, base.TRAINING
SHOWCASE = (14.0, 4.9)     # the showcase's plinth, just inside the gate, beside the way in: across, in (TR22)
LAMP = ("BreakerLamp", *BREAKER, 10.0, "#8CF6FF")   # the Breaker's own light, over the chambers
WELL_LIGHT = ("VoidWell", *GENERATOR, 1.6, "#B98CFF")   # the void's light under the generator, out of its well
APART = 25.0               # the least from one machine's middle to the next (AR16)
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


BAY_LOTS = base.BAYS       # in the order they open
SLEEPING = dict(forge=base.FORGE, condenser=base.CONDENSER, lab=base.LAB)   # what the base wakes in later phases


def machines(level=1):
    """The machines that have their model (AR15), each where the builder's stand-in stands: piece, across, in from
    the front edge, up, turn, and what it stands for. A bay's halo stands only while a worker works there."""
    chamber_x, _, _ = base.machines.CHAMBERS
    top = base.machines.BODY[2]
    bx, by = BREAKER
    made = [("Breaker", bx, by, 0.0, 0.0, "the Breaker's body")]
    made += [("BreakerChamber", bx + side * chamber_x, by, top, 0.0, f"chamber {i + 1}") for i, side in enumerate((-1, 1))]
    made += [("BreakerWaiting", bx + 9.0 + 3.0 * k, by, 0.0, 0.0, f"waiting place {k + 1}") for k in range(3)]   # in a row on its outer side
    for index, (x, inward) in enumerate(BAY_LOTS[:base.BAYS_AT[level]]):
        turn = 0.0 if x < 0 else 180.0                              # the ring on the outer side
        made.append(("Bay", x, inward, 0.0, turn, f"bay {index + 1}"))
        made.append(("BayHalo", x, inward, 0.0, turn, f"bay {index + 1}'s light, while a worker works there"))
    for index, (x, inward) in enumerate(BAY_LOTS):
        if index >= base.BAYS_AT[level]:
            made.append(("BaySleeping", x, inward, 0.0, 0.0 if x < 0 else 180.0, f"bay {index + 1}, asleep until level {index // 2 + 1}"))
    for name, (x, inward) in SLEEPING.items():
        made.append(("SleepingStone", x, inward, 0.0, 0.0, f"the {name.capitalize()}'s place, asleep"))
    made.append(("Generator", *GENERATOR, 0.0, 0.0, "the generator"))
    made.append(("GeneratorRotor", *GENERATOR, base.machines.AXLE, 0.0, "the generator's rotor, turning about its own X"))
    made.append(("GeneratorRing", *GENERATOR, base.machines.AXLE, 90.0, "the generator's great ring, turning about its own X, slowly, against the rotor"))
    made.append(("BatteryRack", *BATTERY, 0.0, 0.0, "the battery"))
    for index, (x, y) in enumerate(base.machines.SEATS[:base.machines.CELLS_AT[level]]):
        made.append(("BatteryCell", BATTERY[0] + x, BATTERY[1] - y, base.machines.SEAT, 0.0, f"the battery's cell {index + 1}"))
    made.append(("Door", *DOOR, 0.0, 90.0, "the Festival Door, its way looking down the way in"))
    made.append(("DoorWay", *DOOR, 0.0, 90.0, "the Door's way of light"))
    made.append(("Training", *TRAINING, 0.0, 0.0, "the Training machine, its pad toward the front"))
    made.append(("TrainingCrown", *TRAINING, base.machines.CROWN, 0.0, "the Training machine's crown, turning about its own upright while a Voidkin trains"))
    return made


def stations(level=1):
    """Everything a player walks to, by name: across and in. The measure of the spread is taken on these."""
    named = dict(generator=GENERATOR, breaker=BREAKER, door=DOOR, battery=BATTERY, training=TRAINING)
    named.update({f"bay{i + 1}": at for i, at in enumerate(BAY_LOTS[:base.BAYS_AT[level]])})
    return named


def spread(level=1):
    """The spread's own check: the nearest two places, the sleeping ones counted, and whether anything stands in the
    way in."""
    named = stations(level)
    named.update({f"bay{i + 1}": at for i, at in enumerate(BAY_LOTS)})
    named.update(SLEEPING)
    names = sorted(named)
    near = min((math.dist(named[a], named[b]), a, b) for i, a in enumerate(names) for b in names[i + 1:])
    reach = {"Showcase": 3.05, "FloodMast": 1.7, "Transformer": 1.95}   # half a piece's width, of what stands near the way
    inside = [name for name, x, along, _ in plan(level)[0]
              if name in reach and abs(x) - reach[name] < base.AVENUE / 2 and -along < GENERATOR[1]]
    inside += [name for name, at in named.items() if abs(at[0]) < base.AVENUE / 2 + 5.0 and at[1] < GENERATOR[1]]
    return dict(nearest=[round(near[0], 1), near[1], near[2]], least=APART, inTheWay=inside)


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
        if inward >= deep:                                          # the yard behind the court, block after block:
            put({deep: "YardLive", deep + block: "YardBack"}.get(inward, "Yard"), 0, inward)   # the heart's, the battery's, then dormant
        put({block: "WingsLive", 2 * block: "WingsBack"}.get(inward, "Wings"), 0, inward)   # and the deck each side: the bus's block, the last bays', the rest plain
    # the wall, on the plot's own edge, the same on both sides of the middle line: each post carries the panel to the
    # next, and a half panel closes a run on the plot's 200. The sides run in from the front corners' posts; the back
    # runs in from its corners' posts to the way out at its middle; the front runs out from the gate's shoulders
    for side in (-1, 1):
        for inward in range(0, int(yard) - 8, 16):
            put("Wall", side * half, inward, -90)
        put("WallHalf", side * half, yard - 8, -90)
        turn = 0 if side < 0 else 180                               # along the back, toward the middle
        for k in range(5):
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
    # the floods: a mast each side of the way in, before the ring's open ends, looking toward the gate: the generator
    # stands between them from the gate
    inward, reach, height = base.FLOOD
    for side, name in ((-1, "Left"), (1, "Right")):
        put("FloodMast", side * base.flood_across(), inward, 0)
        lights.append((f"Flood{name}", side * base.flood_across(), -(inward - reach), height, "#EAF6FF", "spot"))
    # the transformers: one by each open bay's line, behind the bus, where the bay's current joins it
    # a pair for every two open bays (research, 2026-11-15, AR14)
    for x, inward in BAY_LOTS[:base.BAYS_AT[level]]:
        put("Transformer", math.copysign(abs(x) - 16.0, x), inward + 5.5, 0)
    lights.append((*LAMP[:2], -LAMP[2], *LAMP[3:], "point"))
    lights.append((*WELL_LIGHT[:2], -WELL_LIGHT[2], *WELL_LIGHT[3:], "point"))
    # the showcase: the owner's Voidkin on its plinth, on the gate's right, beside the way in and never in it, so the
    # Strip sees it through the gate and a player walks past it to the heart
    _, (sx, sy, sz), colour = base.show.LIGHT
    put("Showcase", SHOWCASE[0], SHOWCASE[1], 0)
    lights.append(("Showcase", SHOWCASE[0] + sx, round(-(SHOWCASE[1] - sy), 2), sz, colour, "point"))
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
        what="AR14 and AR16, the base dressed and spread: where the base's own kit stands on a plot, by the base's level",
        kit="manifest.json, beside this file: every piece named here is one of its pieces",
        origin="the middle of the plot's front edge (the edge on the Strip), on the plot's floor",
        axes="`across` is the plot's own +X, to the right as the spawn looks; `along` is studs out of the front edge "
             "toward the Strip, so everything on the plot is negative; `turn` is degrees anticlockwise seen from above",
        toRoblox="in the plot's own frame (WorldService.plot's `at`), Kit.Place(placement, piece, front, floorY) with "
                 "front = -deep / 2: CFrame.new(across, floorY, front - along) * CFrame.Angles(0, math.rad(turn), 0) * "
                 "centre. A light the same way, by Kit.Light.",
        levels=levels, ground=GROUND, standIns=STAND_INS,
        layout=dict(
            note="AR16, the spread: where each thing a player walks to stands, across and in from the front edge "
                 "(`along` is minus `in`). Modulo's proposal for the builder's Config.World: the floor's pictures are "
                 "drawn for these places, so a place that moves takes its picture with it. The placement is a star "
                 "round the generator, which stands at the plot's heart inside a ring of current open toward the "
                 "gate: the Breaker and the Door on the two slants toward the gate, level 1's bays at the bus's "
                 "ends, the battery and the Training machine on the two slants toward the back. The way in is "
                 "`avenue` studs wide down the middle line, clear from the gate to the generator. The Breaker's "
                 "chambers and waiting places keep their offsets from its body, and every machine keeps its turn. "
                 "What the base will wake stands asleep where it will stand, dark, on a dead line that lights "
                 "out to it when it wakes: bays 3 and 4 on the bus's line outward (level 2), bays 5 and 6 back along "
                 "the side walls (level 3), and in the back half the Lab on the main line with the Forge and the "
                 "Condenser on a spoke each (`sleeping`). Nothing new stands between the gate and the generator.",
            avenue=base.AVENUE, least=APART, ring=base.RING,
            spawn=dict(across=SPAWN[0], inward=SPAWN[1], facing="into the plot"),
            showcase=dict(across=SHOWCASE[0], inward=SHOWCASE[1]),
            stations={name: dict(across=x, inward=i) for name, (x, i) in stations().items()},
            laterBays=[dict(across=x, inward=i) for x, i in BAY_LOTS[base.BAYS_AT[1]:]],
            sleeping={name: dict(across=x, inward=i) for name, (x, i) in SLEEPING.items()},
            check=spread()),
        current=dict(
            note="the live conduits drawn in the floor, each from the generator's end outward: where the current "
                 "runs. For a pulse of light along each, if the builder's effect takes it: a small touch, at "
                 "research's verdict.",
            runs=[dict(across=[round(side * x0, 2) + 0.0, round(side * x1, 2) + 0.0], along=[round(-y0, 2), round(-y1, 2)])
                  for (x0, y0), (x1, y1) in base.live_runs() for side in ((1, -1) if x0 or x1 else (1,))],
            ring=dict(across=GENERATOR[0], along=-GENERATOR[1], radius=base.RING, open=90.0,
                      note="the ring round the well: a circle of this radius about the generator, less the quarter "
                           "that faces the gate. Its current runs from the bus's two joints and the main line's, "
                           "toward its open ends.")),
        machines=dict(
            note="AR15: the machines that have their model, each in place of the builder's stand-in, at every level. "
                 "Laid as a placement is, raised by `up`. A chamber is its own piece so the builder lights each by "
                 "its state (EmissiveStrength: full while it breaks a shard, low when empty). A bay's halo is "
                 "its own piece in one pale swatch: it stands only while a worker works there, in the worker's "
                 "rarity colour (TR22). The list is level 1's: bays 3 to 6 stand the same way on the yard's lots "
                 "(`layout.laterBays`).",
            placements=[dict(piece=n, across=x, along=-i, up=z, turn=t, standsFor=w) for n, x, i, z, t, w in machines()],
            battery=dict(
                note="the battery is a bank: a cell a seat, in this order, as its cap grows with the base's level. "
                     "The builder lights the cells one after another as the charge rises.",
                cellsAt=base.machines.CELLS_AT, up=base.machines.SEAT,
                seats=[dict(across=round(BATTERY[0] + x, 2), along=round(-(BATTERY[1] - y), 2)) for x, y in base.machines.SEATS])),
        lighting="the base stands under Lantern Row's dusk: the same sky, ambient, fog and bloom "
                 "(build/handoff/LanternRow/sky/lighting.json). The conduits, the wall's line and the lamps are "
                 "drawn for dusk, and under the place's daylight they don't read.",
        lightsNote="a SpotLight straight down from each flood mast's head, a PointLight over the Breaker's "
                   "chambers and one low in the generator's well, in the void's violet, Shadows off; everything "
                   "else that glows is in a glow picture",
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
        b("Lot", (PLOT, PLOT, 0.4), 0, PLOT / 2, -0.23, "lot")
        for x in (-3.5, 3.5):                                      # a shard in each chamber, the builder's own
            b("Shard", (1.0, 1.0, 1.7), BREAKER[0] + x, BREAKER[1], sum(base.machines.GAP) / 2, "chamber")
        for i, (name, x, inward, up, turn, _) in enumerate(machines(level)):
            self.stock.stand(name, f"{tag}m{i}", self.at(front, face, x, inward, up), turn + (0 if face > 0 else 180))
        for index, (x, inward) in enumerate(BAY_LOTS[:base.BAYS_AT[level]]):   # a worker's size, on each bay
            wx, wy, _ = self.at(front, face, x, inward)
            self.person((wx, wy), f"Worker{tag}{index}")
        wx, wy, _ = self.at(front, face, *SHOWCASE)                # and the owner's Voidkin on the showcase
        self.person((wx, wy), f"Shown{tag}", base.show.TOP)
        wx, wy, _ = self.at(front, face, TRAINING[0], TRAINING[1] - base.machines.TRAINEE)   # and one who trains
        self.person((wx, wy), f"Trainee{tag}", 0.56)
        b("Spawn", (6, 6, 0.2), *SPAWN, 0.1, "spawn")
        places, lights = plan(level)
        _, watts, _ = look.DIRECTIONS["M"]["string_light"]
        for i, (name, x, along, turn) in enumerate(places):
            self.stock.stand(name, f"{tag}{i}", self.at(front, face, x, -along), turn + (0 if face > 0 else 180))
        for name, x, along, z, code, kind in lights:
            lamp = look.light(self.kit, self.scene, f"{name}{tag}", self.at(front, face, x, -along, z), code,
                              watts * kit.REAL_LIGHT * (0.1 if name == "Showcase" else 1.0), 40.0,   # a near light
                              kind="SPOT" if kind == "spot" else "POINT")
            lamp.data.use_shadow = False
            if kind == "spot":
                lamp.data.spot_size, lamp.data.spot_blend = math.radians(kit.POOL_CONE), 0.7

    def person(self, at, name="Avatar", up=0.0):
        """A player's size, in bone: where they stand."""
        x, y = at
        for part, size, z in (("Legs", (2, 1, 2), 1), ("Body", (4, 1, 2), 3), ("Head", (1.2, 1.2, 1.2), 4.6)):
            self.kit.block(f"{name}{part}", size, (x, y, z + up), self.flat["spawn"])


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
    yard.person((SPAWN[0], -SPAWN[1]))
    yard.person((6.0, -120.0), "Walker")
    yard.person((base.OUTER - 9.0, -(base.ROW - 7.0)), "Hand")
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
    (gx, gi), (bx, bi), (tx, ti) = GENERATOR, BREAKER, BATTERY
    views = {"home": behind((SPAWN[0], -SPAWN[1]), -1), "gate": behind((0, STRIP / 2), -1),
             "yard": behind((0, -(base.COURT[1] + 8.0)), -1), "back": behind((0, -(base.YARD - 14.0)), 1),
             "across": ((-88.0, -6.0, 11.0), (30.0, -130.0, 4.0)),
             "breaker": ((bx - 9.0, -(bi - 17.0), 9.5), (bx, -bi, 6.0)), "strip": ((-8.0, 9.0, 7.5), (gx, -gi, 5.0)),
             "bay": ((-(base.OUTER - 17.0), -(gi - 11.0), 6.0), (-base.OUTER, -gi, 5.0)),
             "bays": ((-10.0, -(gi - 26.0), 6.5), (base.OUTER, -gi, 4.0)),
             "heart": behind((0, -(gi - 34.0)), -1), "star": ((0.0, -8.0, 150.0), (0.0, -(gi + 6.0), 0.0)),
             "generator": ((gx - 15.0, -(gi - 34.0), 8.0), (gx, -gi, 11.5)),
             "battery": ((tx - 5.5, -(ti - 9.5), 4.6), (tx, -ti, 1.4)),
             "show": ((6.0, 22.0, 6.0), (SHOWCASE[0], -SHOWCASE[1], 4.5)), "shown": ((21.5, -13.5, 5.5), (SHOWCASE[0], -SHOWCASE[1], 3.6)),
             "door": ((DOOR[0] + 20.0, -(DOOR[1] - 9.0), 6.0), (DOOR[0], -DOOR[1], 6.6)),
             "training": ((TRAINING[0] + 11.0, -(TRAINING[1] - 17.0), 5.5), (TRAINING[0], -(TRAINING[1] - 2.0), 4.2)),
             "above": ((0.0, 96.0, 118.0), (0.0, -92.0, 0.0))}
    if only:
        views = {name: views[name] for name in only}
    if clear:   # the layout, with the dusk's haze thinned: from above the haze veils it
        views = {f"{name}_clear": view for name, view in (views.items() if only else [("above", views["above"])])}
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
