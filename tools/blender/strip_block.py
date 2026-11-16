"""AR17's blockout: the rest of the map from the player's camera, for research's verdict. Throwaway: stand-ins and the
pieces the two kits already have, nothing polished and nothing exported.

The world is the grey one's (docs/design.md, "The world, in grey"; Config/World): eight plots in two rows across the
Strip, a crossing one plot wide, the side street north of it to the festival gate, the Shop's place south of it. Here
the player's plot is the north row's, east of the crossing (P3), and the frame is base_plan's: the plot's front edge
at y = 0, the Strip from 0 to 48, north toward -Y, the crossing toward +X.

What the block tries, each a stand-in:
- the Strip's street: Lantern Row's stones, a kerb where the plots' plates meet them, a lantern post every 62 studs;
- a gate lit where a player is home (its own light on the stones before it) and dark where none is;
- a bare lot: its wall and gate unlit, its floor dark, nothing in it; one of them with a sleeping stone at its heart;
- the crossing: a ring in the stones, and the side street's mouth under the first string of lanterns;
- the side street: Lantern Row's own strings closing up toward the gate, a field of small ground lanterns either
  side, three stalls a side before the gate, and the Row's first hundred studs beyond it as its plan lays them;
- past the edges: the Strip's two ends sealed by a dark arch with one faint shard, and a far ring of great shards
  standing in the haze.

    blender -b --factory-startup --python tools/blender/strip_block.py -- build/handoff/Strip [view ...] [fast] [clear]

Writes strip_block_<view>.png. Eevee, no GPU turn.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_plan as plan  # noqa: E402
import strip_kit  # noqa: E402

base, bl, kit, look, rs = plan.base, plan.bl, plan.kit, plan.look, plan.rs
REPO = Path(__file__).resolve().parents[2]
BASE_MAPS = REPO / "build" / "handoff" / "Base" / "maps"
ROW = REPO / "build" / "handoff" / "LanternRow"
ROW_WEARS = (kit.SWATCHES, kit.SWATCH_AT, kit.PRINTS)   # Lantern Row's own atlas: the base's builder swaps it out (base.wear)
PLOT, STRIP = plan.PLOT, plan.STRIP
BETWEEN = 48.0                              # between neighbours (Config/World, Plots.Between)
CROSSING = PLOT / 2 + PLOT / 2              # the crossing's middle, across: our plot is the first east of it
STREET = 44.0                               # the side street, wall to wall (Config/World, Row.Wide)
GATE = -(PLOT + sum(plan.TOWER_LOT))        # the festival gate, along: a plot, its path and its Tower up the side street
ENDS = (CROSSING - 628.0, CROSSING + 628.0)  # the Strip's two ends (two plots, their gap, and Strip.Ends)
NORTH, SOUTH = (0.0, 1), (STRIP, -1)        # a row's front edge and the way its plots face
# Who is home: ours, the plot across, and the one over the crossing. The rest are bare.
PLOTS = {"P3": (0.0, NORTH, "ours"), "P7": (0.0, SOUTH, "home"), "P2": (2 * CROSSING, NORTH, "lit"),
         "P4": (-(PLOT + BETWEEN), NORTH, "stone"), "P8": (-(PLOT + BETWEEN), SOUTH, "bare"),
         "P6": (2 * CROSSING, SOUTH, "bare"), "P1": (2 * CROSSING + PLOT + BETWEEN, NORTH, "bare"),
         "P5": (2 * CROSSING + PLOT + BETWEEN, SOUTH, "bare")}
STRINGS = (-246.0, -202.0, -158.0, -120.0, -88.0, -61.0, -38.0, -18.0)   # the side street's lantern strings, from the gate: closing up


class World(plan.Yard):
    """base_plan's yard, a plot stood anywhere along the Strip."""

    def __init__(self, scene, d):
        super().__init__(scene, 1, BASE_MAPS)
        self.dx, self.d = 0.0, d
        self.asleep = base.Stock(BASE_MAPS, scene, self.kit)
        self.asleep.mats = {name: kit.kit_material(BASE_MAPS, name, "Base", ("#FFFFFF", 0.0)) for name in base.MAPS}
        self.row = kit.Stock(ROW / "maps", scene, self.kit)
        f = self.flat
        f["lot_asleep"] = plan.tile_material("LotAsleep", BASE_MAPS / "Base_Deck_Color.png", base.DECK[1], strip_kit.LOT_TINT)
        f["kerb"] = look.painted("Kerb", "#3A4060", "#23273C")
        f["seal"] = look.painted("Seal", "#2A2148", "#120C26")
        f["far"] = look.painted("Far", "#3A2F62", "#171030")
        f["warm"] = look.glowing("Warm", "#FFE7B8", 2.4)
        f["field"] = look.glowing("Field", "#FFD9A0", 1.6)
        f["ring"] = look.glowing("Ring", "#FFE7B8", 0.5)
        f["home"] = look.glowing("Home", "#8CF6FF", 1.2)
        f["calamity"], f["clash"] = look.glowing("Calamity", "#A97CFF", 0.7), look.glowing("Clash", "#9EEBFF", 0.7)
        self.watts = d["string_light"][1] * kit.REAL_LIGHT

    def at(self, front, face, x, inward, z=0.0):
        return (self.dx + face * x, front - face * inward, z)

    def toward(self):
        return 1.0 if self.dx < CROSSING else -1.0

    # --- the plots ---

    def home(self, dx, row):
        """A plot whose player is home: the whole base, its Tower on the crossing's side, its gate's light on the Strip."""
        self.dx = dx
        self.plot(*row)
        tower = next(o for o in reversed(self.kit.pieces) if o.name.startswith("TowerSleeping"))
        tower.location.x = dx + self.toward() * plan.TOWER_AT[0]
        self.threshold(row)

    def threshold(self, row):
        front, face = row
        lamp = look.light(self.kit, self.scene, "Threshold", (self.dx, front + face * 7.0, 8.0), "#8CF6FF", self.watts * 0.5, 40.0)
        lamp.data.use_shadow = False

    def shell(self, dx, row, lit, stone=False):
        """A plot with no machines. Lit: its floors, wall, gate and lines, and its Tower: a neighbour seen from far.
        Unlit: a bare lot, its wall and gate dark over a dark floor."""
        self.dx = dx
        front, face = row
        tag = f"S{int(dx)}{face}"
        stock = self.stock if lit else self.asleep
        self.box(front, face, f"Lot{tag}", (PLOT, PLOT, 0.4), 0, PLOT / 2, -0.23, self.flat["lot" if lit else "lot_asleep"])
        for i, (name, x, along, turn) in enumerate(plan.plan(1)[0]):
            if lit and name != "Showcase" or name.startswith(("Wall", "Gate")):
                stock.stand(name, f"{tag}_{i}", self.at(front, face, x, -along), turn + (0 if face > 0 else 180))
        if lit:
            self.stock.stand("TowerSleeping", tag, (dx + self.toward() * plan.TOWER_AT[0], front - face * plan.TOWER_AT[1], 0), 0)
            self.threshold(row)
        if stone:
            self.asleep.stand("SleepingStone", tag, self.at(front, face, *plan.GENERATOR), 0)

    # --- the Strip ---

    def strip(self):
        b, f = self.kit.block, self.flat
        long, mid = ENDS[1] - ENDS[0], sum(ENDS) / 2
        b("Strip", (long, STRIP, 0.4), (mid, STRIP / 2, -0.22), self.stone)
        b("SideStreet", (STREET, -GATE, 0.4), (CROSSING, GATE / 2, -0.22), self.stone)
        b("Ground", (3200, 3200, 0.4), (CROSSING, STRIP / 2, -0.3), f["ground"])
        for y in (0.6, STRIP - 0.6):
            b(f"Kerb{y:.0f}", (long, 1.2, 0.5), (mid, y, 0.05), f["kerb"])
        gates = [dx for dx, _, _ in PLOTS.values()]
        for k, x in enumerate(np.arange(ENDS[0] + 28.0, ENDS[1], 62.0)):
            for y, out in ((2.4, 1), (STRIP - 2.4, -1)):
                clear = all(abs(x - g) > base.WING for g in gates) and not (y < 24 and abs(x - CROSSING) < STREET / 2 + 4)
                if clear and not (y > 24 and abs(x - CROSSING) < 30):
                    self.post(f"Lamp{k}{out}", x, y, out, lit=abs(x - 90.0) < 260)
        # the Shop's place stays as it is: its grey floor, its building and its clock
        b("ShopFloor", (PLOT, PLOT, 0.4), (CROSSING, STRIP + PLOT / 2, -0.24), f["lot_asleep"])
        b("Shop", (40, 28, 14), (CROSSING, STRIP + 20, 7), f["machine"], big=True)
        b("ShopClock", (8, 1, 8), (CROSSING, STRIP + 5.4, 10), f["waiting"])

    def post(self, name, x, y, out, lit):
        """A lantern post on the Strip's kerb: a dark post, an arm over the street, a paper lantern under it."""
        b, m = self.kit.block, self.kit.m
        b(name + "Post", (0.6, 0.6, 13.0), (x, y, 6.5), m["post"], big=True)
        b(name + "Arm", (0.3, 3.0, 0.3), (x, y + out * 1.3, 12.7), m["post"])
        b(name + "Paper", (1.5, 1.5, 2.2), (x, y + out * 2.6, 11.2), self.flat["warm"])
        if lit:
            lamp = look.light(self.kit, self.scene, name, (x, y + out * 2.6, 9.6), "#FFD49A", self.watts * 0.45, 38.0)
            lamp.data.use_shadow = False

    def crossing(self):
        ring = bl.torus("CrossingRing", 19.0, 0.5, 48, 4, self.flat["ring"])
        ring.scale, ring.location = (1, 1, 0.12), (CROSSING, STRIP / 2, 0.0)
        self.kit.pieces.append(ring)
        self.kit.block("CrossingHeart", (5, 5, 0.1), (CROSSING, STRIP / 2, 0.0), self.flat["ring"], rot=(0, 0, math.radians(45)))

    # --- the side street and the Row beyond its gate ---

    def row_stand(self, name, tag, at, turn):
        kit.SWATCHES, kit.SWATCH_AT, kit.PRINTS = ROW_WEARS
        return self.row.stand(name, tag, at, turn)

    def row_at(self, across, along):
        """Lantern Row's plan frame in this one: its gate's middle is the side street's end."""
        return (CROSSING - across, GATE - along, 0.0)

    def side_street(self):
        b, f, rng = self.kit.block, self.flat, np.random.default_rng(7)
        for i, along in enumerate(STRINGS):
            self.row_stand("LanternString", f"Side{i}", self.row_at(0, along), 180)
            if i % 2 == 0:
                x, y, _ = self.row_at(0, along)
                pool = look.light(self.kit, self.scene, f"SidePool{i}", (x, y, 14.2), "#FFD49A", self.watts, 40.0, kind="SPOT")
                pool.data.spot_size, pool.data.spot_blend, pool.data.use_shadow = math.radians(66.0), 0.7, False
            if i % 2 == 1:
                for side in (-1, 1):
                    self.row_stand("Banner", f"Side{i}{side}", self.row_at(side * 20.1, along + 6.0), 90 + 180)
        for side in (-1, 1):                                       # a low wall down each side, to the stalls
            b(f"SideWall{side}", (1.0, -GATE - 52.0, 3.2), (CROSSING + side * (STREET / 2 + 0.5), (GATE + 52.0) / 2, 1.6), f["kerb"], big=True)
            for k, along in enumerate((-14.0, -27.5, -41.0)):      # the festival comes out to meet the player
                self.row_stand("StallA" if k != 1 else "StallB", f"Out{side}{k}", self.row_at(side * 22.0, along), side * 90 + 180)
            for k, along in enumerate((-8.0, -24.0, -40.0)):
                self.row_stand("HouseTall" if k == 0 else "HouseLow", f"OutHouse{side}{k}", self.row_at(side * 30.0, along), side * 90 + 180)
            # a field of small ground lanterns from the wall out to the plots' side walls, thicker toward the gate
            for k in range(95):
                t = rng.random() ** 1.6                            # 0 at the gate's end
                y = GATE + 50.0 + t * (-GATE - 58.0)
                x = CROSSING + side * (STREET / 2 + 5.0 + rng.random() * 68.0)
                b(f"Field{side}{k}", (0.9, 0.9, 1.3), (x, y, 0.65), f["field"])
        self.row_stand("FestivalGate", "Gate", self.row_at(0, 0), 180)
        places = json.loads((ROW / "plan.json").read_text(encoding="utf-8"))["placements"]
        for i, p in enumerate(places):                             # the Row's first hundred studs, as its plan lays them
            if 0 < p["along"] <= 100 or (p["along"] <= 0 and p["piece"] in ("StreetBay", "SignBoard")):
                self.row_stand(p["piece"], f"Row{i}", self.row_at(p["across"], p["along"]), p["turn"] + 180)
        b("RowFloor", (STREET, 130, 0.4), (CROSSING, GATE - 65, -0.22), self.stone)
        glow = look.light(self.kit, self.scene, "RowGlow", (CROSSING, GATE - 40.0, 14.0), "#FFD49A", self.watts * 2.0, 90.0)
        glow.data.use_shadow = False

    # --- past the edges ---

    def edges(self):
        b, f, rng = self.kit.block, self.flat, np.random.default_rng(11)
        for x, light in ((ENDS[0], "calamity"), (ENDS[1], "clash")):    # each end sealed: a dark arch and one faint shard
            for side in (-1, 1):
                b(f"Seal{light}{side}", (14, 12, 46), (x, STRIP / 2 + side * 30, 23), f["seal"], big=True)
            b(f"Seal{light}Top", (14, 84, 12), (x, STRIP / 2, 52), f["seal"], big=True)
            b(f"Seal{light}Door", (6, 48, 46), (x, STRIP / 2, 23), f["seal"])
            b(f"Seal{light}Shard", (3, 3, 10), (x + (4 if x < 0 else -4), STRIP / 2, 30), f[light], rot=(0, 0, math.radians(45)))
        for i in range(34):                                        # great shards in the haze, round all but the festival's sky
            a = math.tau * (i + rng.random() * 0.6) / 34
            if abs(a - 1.5 * math.pi) < 0.3:                       # the side street's end keeps the dusk's glow clear
                continue
            far = 1.0 + 0.25 * rng.random()
            x, y = CROSSING + math.cos(a) * 900 * far, STRIP / 2 + math.sin(a) * 640 * far
            high, wide = 80 + 120 * rng.random(), 14 + 18 * rng.random()
            shard = bl.cylinder(f"Far{i}", wide, high, segments=4, material=f["far"], radius_top=wide * 0.06)
            shard.location, shard.rotation_euler = (x, y, high / 2 - 6), (rng.normal(0, 0.09), rng.normal(0, 0.09), rng.random() * 3)
            self.kit.pieces.append(shard)


def behind(at, yaw):
    """The game's camera behind a player at `at`, looking `yaw` degrees round from +Y toward +X."""
    pitch, a = math.radians(20.0), math.radians(yaw)
    focus = Vector((at[0], at[1], 3.0 + look.FOCUS))
    eye = focus + Vector((-math.sin(a) * math.cos(pitch), -math.cos(a) * math.cos(pitch), math.sin(pitch))) * look.ZOOM
    return tuple(eye), tuple(focus)


WEST = -(PLOT + BETWEEN)
STANDS = {"out": ((0.0, 9.0), 0), "down": ((6.0, 24.0), 90), "turn": ((0.0, 14.0), 62), "away": ((-40.0, 24.0), -90),
          "bare": ((WEST, 30.0), 180), "stone": ((WEST, -40.0), 180), "crossing": ((CROSSING, 26.0), 180),
          "street": ((CROSSING, -70.0), 180), "gate": ((CROSSING, -196.0), 180), "shop": ((CROSSING, 12.0), 0),
          "back": ((CROSSING, -150.0), 0), "end": ((ENDS[0] + 130.0, 24.0), -90)}


def see(out: Path, only, fast, clear):
    d = dict(look.DIRECTIONS["M"])
    d["glow_az"] = 180.0                                           # the dusk's glow lies north, over the festival
    az, *rest = d["sun"]
    d["sun"] = (az + 180.0, *rest)
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1] * (0.15 if clear else 1.0), azimuth=d["glow_az"],
                    away=look.srgb(d["fog_away"]))
    scene = bl.reset_scene()
    world = World(scene, d)
    for dx, row, who in PLOTS.values():
        if who in ("ours", "home"):
            world.home(dx, row)
        else:
            world.shell(dx, row, lit=who == "lit", stone=who == "stone")
    world.strip()
    world.crossing()
    world.side_street()
    world.edges()
    for name, (at, _) in STANDS.items():
        world.person(at, f"At{name}")
    for obj in world.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings", "Field", "Far")):
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
    views = {name: behind(at, yaw) for name, (at, yaw) in STANDS.items()}
    views["above"] = ((CROSSING - 60.0, 330.0, 470.0), (CROSSING - 60.0, -40.0, 0.0))
    for name in only or views:
        eye, target = views[name]
        scene.camera = plan.camera(scene, name, eye, target)
        tag = f"{name}_clear" if clear else name
        linear = look.render_linear(scene, out / f"strip_block_{tag}.exr")
        rs.save(look.finish(linear, d), out / f"strip_block_{tag}.png")
        (out / f"strip_block_{tag}.exr").unlink(missing_ok=True)
    for name in ("glyph_column.png", "glyph_row.png"):
        (out / name).unlink(missing_ok=True)
    print(f"the block: {len(world.kit.pieces)} objects, {len(world.kit.lights)} lights")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    see(out, [a for a in args if a not in ("fast", "clear")], "fast" in args, "clear" in args)


if __name__ == "__main__":
    main()
