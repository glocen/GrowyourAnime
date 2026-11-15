"""AR16's blockout (docs/asset-requests.md, "The base, void and anime"): the base as a sanctum raised out of the void,
in stand-in shapes and flat colours, with the layout it proposes. Throwaway: nothing here is a kit piece, and nothing
is exported. The director's words it answers are in AR16.

The idea: the plot is the void itself, dark with stars. Stone is raised out of it: a causeway straight from the gate
and a round platform. The plant's heart, the generator, is a core turning inside rings over a well of void in the
platform's middle, and the bays' power runs to it as lines of light in the stone. Nothing stands across the way in.

    blender -b --factory-startup --python tools/blender/base_void_blockout.py -- <out> [fast] [clear] [both] [walk] [views...]

Views: walk1 to walk4 (in through the gate), court, heart, bay, down. `walk` renders the walk in as frames for a film; `clear` thins the dusk's haze, for the look down; `both` stands the plot across the Strip too.
"""
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import base_plan as plan  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402

PLOT, STRIP = plan.PLOT, plan.STRIP
AVENUE = 20.0                    # the causeway's width, clear from the gate to the platform
HEART = 80.0                     # the platform's middle, in from the front edge
PLATFORM, WELL = 46.0, 9.0       # the platform's radius, and the well of void in its middle
RING = 36.0                      # the bays stand this far from the heart
BAYS = (60.0, 100.0, 142.0)      # each pair's angle off the way in, either side: level 1's, then 2's, then 3's
SPAWN = 30.0                     # where the causeway meets the platform
BREAKER, DOOR = (-21.0, 47.0), (21.0, 47.0)     # either side of the causeway's end: across, in
FACING = math.radians(45.0)      # how far each of the two turns toward the causeway's end
TRAINING = (0.0, HEART + RING)   # behind the heart, on the way's own line
SHOWCASE = (16.0, 10.0)
SEATS = 8                        # the battery's crystals round the well; two are lit at level 1
STONE, STONE_TOP, VOID, SILVER = ("#34324C", "#14131F"), ("#2A2940", "#1E1D2C"), "#05050B", ("#D5DCEC", "#8C94AC")
CYAN, POWER, PALE, DARK_SIGIL = "#8CF6FF", "#FFE266", "#F6FCFF", "#34334A"
RARITY = ("#D29CFF", "#6FB6FF")  # the two workers': an Epic and a Rare


def crystal(name, r, up, down, sides, mat):
    """A cut stone: a ring of corners with a point over it and one under."""
    bm = bmesh.new()
    ring = [bm.verts.new((r * math.cos(math.tau * k / sides), r * math.sin(math.tau * k / sides), 0)) for k in range(sides)]
    top, foot = bm.verts.new((0, 0, up)), bm.verts.new((0, 0, -down))
    for k in range(sides):
        a, b = ring[k], ring[(k + 1) % sides]
        bm.faces.new((a, b, top))
        bm.faces.new((b, a, foot))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, mat)


def flecks(name, spots, mat):
    """Small flat squares, one mesh: each spot is x, y and its side."""
    bm = bmesh.new()
    for x, y, side in spots:
        h = side / 2
        bm.faces.new([bm.verts.new((x + sx * h, y + sy * h, 0.0)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    return bl.object_from_bmesh(name, bm, mat)


def annulus(name, r0, r1, high, mat, segs=64):
    """A round slab with a round hole, its top at `high`."""
    bm = bmesh.new()
    rows = []
    for r, z in ((r0, -1.0), (r0, high), (r1, high), (r1, -1.0)):
        rows.append([bm.verts.new((r * math.cos(math.tau * k / segs), r * math.sin(math.tau * k / segs), z)) for k in range(segs)])
    for i in range(3):
        for k in range(segs):
            bm.faces.new((rows[i][k], rows[i][(k + 1) % segs], rows[i + 1][(k + 1) % segs], rows[i + 1][k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, mat)


class Sanctum:
    def __init__(self, scene, out):
        self.scene = scene
        self.kit = look.Kit(look.DIRECTIONS["M"], look.glyph_images(out))
        self.m = {
            "stone": look.painted("Stone", *STONE), "top": look.painted("StoneTop", *STONE_TOP),
            "void": look.painted("Void", VOID, VOID), "silver": look.painted("Silver", *SILVER),
            "sigil": look.painted("DarkSigil", DARK_SIGIL, DARK_SIGIL), "person": look.painted("Person", "#E9E2D2", "#BDB5A4"),
            "street": look.painted("Street", "#4A4658", "#3A3646"), "ground": look.painted("Ground", "#1A1826", "#1A1826"),
            "star": look.glowing("Star", PALE, 1.6), "cyan": look.glowing("Cyan", CYAN, 2.4), "power": look.glowing("Power", POWER, 2.2),
            "pale": look.glowing("Pale", PALE, 1.4), "faint": look.glowing("Faint", "#9AA6D8", 0.5),
            "deep": look.glowing("Deep", "#2A2F7A", 0.5), "way": look.glowing("Way", "#7FE9FF", 0.9),
        }
        for i, code in enumerate(RARITY):
            self.m[f"rarity{i}"] = look.glowing(f"Rarity{i}", code, 2.4)
        _, self.watts, _ = look.DIRECTIONS["M"]["string_light"]
        self.front, self.face, self.tag = 0.0, 1, "A"

    # --- placing: across, in from the front edge, up --------------------------------------------------------------
    def at(self, x, inward, z=0.0):
        return (self.face * x, self.front - self.face * inward, z)

    def put(self, obj, x, inward, z=0.0, rot=(0, 0, 0), ink=True, big=True):
        obj.name = f"{obj.name}{self.tag}"
        obj.location = self.at(x, inward, z)
        obj.rotation_euler = (rot[0], rot[1], rot[2] + (0 if self.face > 0 else math.pi))
        return self.kit.add(obj, big, ink)

    def box(self, name, size, x, inward, z, mat, rot=(0, 0, 0), ink=False):
        return self.put(bl.box(name, size, self.m[mat]), x, inward, z, rot, ink)

    def disc(self, name, r, high, x, inward, z, mat, segs=32, ink=False):
        return self.put(bl.cylinder(name, r, high, segs, self.m[mat]), x, inward, z, ink=ink)

    def ring(self, name, r, thick, x, inward, z, mat, rot=(0, 0, 0), segs=48, ink=False):
        return self.put(bl.torus(name, r, thick, segs, 4, self.m[mat]), x, inward, z, rot, ink)

    def shard(self, name, r, high, x, inward, mat="stone", lean=(0.0, 0.0), sides=5, z=0.0, turn=0.0):
        """A standing stone, pointed: its foot on the ground."""
        obj = bl.cylinder(name, r, high, sides, self.m[mat], radius_top=r * 0.12)
        bl.place(obj, (0, 0, high / 2))
        return self.put(obj, x, inward, z, (lean[0], lean[1], turn))

    def stone(self, name, r, up, down, x, inward, z, mat, sides=6, rot=(0, 0, 0), ink=False):
        return self.put(crystal(name, r, up, down, sides, self.m[mat]), x, inward, z, rot, ink)

    def light(self, name, x, inward, z, code, power=1.0, reach=45.0):
        lamp = look.light(self.kit, self.scene, f"{name}{self.tag}", self.at(x, inward, z), code,
                          self.watts * kit.REAL_LIGHT * power, reach)
        lamp.data.use_shadow = False

    def person(self, x, inward, name, z=0.0):
        for part, size, up in (("Legs", (2, 1, 2), 1), ("Body", (4, 1, 2), 3), ("Head", (1.2, 1.2, 1.2), 4.6)):
            self.box(f"{name}{part}", size, x, inward, z + up, "person")

    def line(self, name, a, b, wide, mat, z=0.66):
        """A line of light in the stone, from a to b (across, in)."""
        (ax, ai), (bx, bi) = a, b
        length, turn = math.hypot(bx - ax, bi - ai), math.atan2(-(bi - ai), bx - ax)
        self.box(name, (length, wide, 0.08), (ax + bx) / 2, (ai + bi) / 2, z, mat, (0, 0, turn))

    def sigil(self, name, x, inward, r, mat, z=0.66):
        """A circle in the stone: two rings and six ticks between them. Plain geometry, no star and no letter."""
        self.ring(f"{name}Outer", r, 0.14, x, inward, z, mat)
        self.ring(f"{name}Inner", r * 0.66, 0.1, x, inward, z, mat)
        for k in range(6):
            a = math.tau * k / 6
            self.box(f"{name}Tick{k}", (r * 0.26, 0.18, 0.08), x + r * 0.83 * math.cos(a), inward + r * 0.83 * math.sin(a), z, mat, (0, 0, -a))

    # --- the plot ---------------------------------------------------------------------------------------------------
    def plot(self, front, face, rng):
        self.front, self.face, self.tag = front, face, "A" if face > 0 else "B"
        half = PLOT / 2
        self.box("VoidField", (PLOT, PLOT, 0.4), 0, half, -0.6, "void")
        for mat, count in (("star", 340), ("cyan", 80)):             # stars in it: one mesh a colour
            self.put(flecks(f"Stars{mat}", [(rng.uniform(-half + 2, half - 2), -rng.uniform(2, PLOT - 2),
                                             rng.choice((0.22, 0.22, 0.3, 0.42))) for _ in range(count)], self.m[mat]),
                     0, 0, -0.36, ink=False)
        for k in range(5):                                           # and a depth to it: far light under the dark
            self.disc(f"Deep{k}", rng.uniform(14, 26), 0.02, rng.uniform(-70, 70), rng.uniform(30, 180), -0.39, "deep", 20)
        self.boundary()
        self.box("Causeway", (AVENUE, SPAWN + 6.0, 1.6), 0, (SPAWN + 6.0) / 2 - 1.0, -0.2, "top", ink=True)
        for sx in (-1, 1):
            self.line(f"WayLine{sx}", (sx * (AVENUE / 2 - 0.8), 1.0), (sx * (AVENUE / 2 - 0.8), SPAWN + 2.0), 0.24, "faint", 0.64)
        self.put(annulus("Platform", WELL, PLATFORM, 0.6, self.m["top"]), 0, HEART, ink=True)
        self.ring("PlatformRim", PLATFORM - 0.6, 0.12, 0, HEART, 0.66, "faint", segs=64)
        self.disc("ShowPad", 5.5, 1.6, SHOWCASE[0] - 2.0, SHOWCASE[1], -0.2, "top", 16, ink=True)
        self.disc("ShowStep", 3.3, 0.7, *SHOWCASE, 0.95, "stone", 8, ink=True)
        self.ring("ShowRing", 2.4, 0.1, *SHOWCASE, 1.34, "pale", segs=8)
        self.person(*SHOWCASE, "Shown", 1.3)
        self.heart()
        self.bays()
        self.breaker()
        self.door()
        self.training()
        self.person(-1.8, SPAWN, "Player", 0.6)
        self.person(2.4, SPAWN + 1.0, "Lead", 0.6)

    def boundary(self):
        """The plot's edge: standing stones and a faint line, in place of a wall; the gate, two tall stones and a
        plate between them for the owner's name and the base's level."""
        half, k = PLOT / 2, 0
        edge = [(x, 0.0) for x in range(-100, 101, 25) if abs(x) > 20]
        edge += [(sx * half, float(i)) for sx in (-1, 1) for i in range(25, 200, 25)] + [(float(x), PLOT) for x in range(-100, 101, 25)]
        for x, i in edge:
            k += 1
            self.shard(f"Edge{k}", 1.5, 6.0 + 2.0 * (k % 3), x, i, lean=(0.06 * ((k % 3) - 1), 0.05 * ((k % 2) * 2 - 1)), turn=k * 0.7)
        for name, a, b in (("Front", (-half, 0), (-AVENUE / 2 - 2, 0)), ("Front2", (AVENUE / 2 + 2, 0), (half, 0)), ("Left", (-half, 0), (-half, PLOT)),
                           ("Right", (half, 0), (half, PLOT)), ("Back", (-half, PLOT), (half, PLOT))):
            self.line(f"EdgeLine{name}", a, b, 0.3, "faint", -0.34)
        for sx in (-1, 1):
            self.shard(f"Gate{sx}", 2.6, 17.0, sx * (AVENUE / 2 + 2.6), 0.0, lean=(0.0, -sx * 0.07))
            self.box(f"GateSeam{sx}", (0.16, 0.3, 9.0), sx * (AVENUE / 2 + 0.9), -0.2, 6.5, "cyan")
        self.box("GatePlate", (13.0, 0.5, 2.4), 0, 0, 12.2, "stone", ink=True)
        self.box("GatePlateLine", (11.4, 0.6, 0.14), 0, 0, 10.85, "pale")

    def heart(self):
        """The generator: a core turning inside two rings over a well of void, the battery's crystals round the rim."""
        self.disc("WellVoid", WELL, 0.1, 0, HEART, -0.9, "void", 48)
        self.disc("WellDeep", WELL * 0.7, 0.02, 0, HEART, -0.82, "deep", 32)
        rng = random.Random(7)
        spots = [(a, WELL * math.sqrt(rng.uniform(0, 0.9))) for a in (rng.uniform(0, math.tau) for _ in range(26))]
        self.put(flecks("WellStars", [(r * math.cos(a), r * math.sin(a), 0.2) for a, r in spots], self.m["star"]), 0, HEART, -0.78, ink=False)
        self.ring("WellRim", WELL + 0.2, 0.22, 0, HEART, 0.7, "power", segs=48)
        self.stone("Core", 3.2, 4.6, 4.6, 0, HEART, 15.0, "power", 4, (0, 0, 0.5))
        self.ring("CoreRingA", 6.4, 0.34, 0, HEART, 15.0, "silver", (math.radians(64), 0, math.radians(20)), ink=True)
        self.ring("CoreRingB", 8.2, 0.3, 0, HEART, 15.0, "silver", (math.radians(-48), math.radians(28), 0), ink=True)
        for k in range(3):
            a = math.tau * k / 3 + 0.4
            self.stone(f"CoreShard{k}", 0.7, 1.4, 1.0, 5.0 * math.cos(a), HEART + 5.0 * math.sin(a), 6.0 + 1.4 * k, "stone", 5, ink=True)
        self.light("Core", 0, HEART, 12.0, POWER, 2.4, 70.0)
        for k in range(SEATS):                                       # the battery: crystals round the well
            a = math.tau * (k + 0.5) / SEATS - math.pi / 2           # the first two toward the way in
            x, i = (WELL + 3.2) * math.sin(a), HEART - (WELL + 3.2) * math.cos(a)
            self.disc(f"Seat{k}", 1.1, 0.24, x, i, 0.72, "stone", 6, ink=True)
            if k in (1, 2):
                self.stone(f"Cell{k}", 0.75, 1.9, 1.1, x, i, 2.6, "power", 4)
            else:
                self.ring(f"SeatRing{k}", 0.8, 0.07, x, i, 0.86, "sigil", segs=6)

    def bays(self):
        """A bay: a circle in the stone under its worker, lit its rarity's colour, a halo over it, and its power's
        line to the heart. A bay not open yet is the same circle, dark."""
        index = 0
        for level, angle in enumerate(BAYS):
            for sx in (-1, 1):
                a = math.radians(angle)
                x, i = sx * RING * math.sin(a), HEART - RING * math.cos(a)
                rim = (sx * (WELL + 0.4) * math.sin(a), HEART - (WELL + 0.4) * math.cos(a))
                name = f"Bay{index}"
                if level == 0:
                    mat = f"rarity{index}"
                    self.sigil(name, x, i, 5.0, mat)
                    self.ring(f"{name}Halo", 2.5, 0.16, x, i, 7.6, mat, segs=24)
                    self.stone(f"{name}Stone", 0.6, 1.2, 0.8, x, i, 9.4, mat, 4)
                    self.line(f"{name}Line", (x - sx * 5.0 * math.sin(a), i + 5.0 * math.cos(a)), rim, 0.4, "power")
                    self.light(name, x, i, 3.0, RARITY[index], 0.8, 22.0)
                    self.person(x, i, f"Worker{index}", 0.6)
                else:
                    self.sigil(name, x, i, 5.0, "sigil")
                    self.line(f"{name}Line", (x - sx * 5.0 * math.sin(a), i + 5.0 * math.cos(a)), rim, 0.3, "sigil")
                index += 1

    def breaker(self):
        """The Void Breaker: a broken ring standing over two chambers, each a Void Shard held in its own rings."""
        x, i = BREAKER
        self.disc("BreakerDais", 6.5, 0.5, x, i, 0.85, "stone", 10, ink=True)
        ring = bl.torus("BreakerRing", 6.2, 0.55, 40, 4, self.m["stone"], arc=300.0)
        bl.place(ring, rotation=(90, 0, 0))                          # upright, its gap at the top
        bl.place(ring, rotation=(0, -120, 0))
        self.put(ring, x, i, 7.6, (0, 0, -FACING))
        inner = bl.torus("BreakerLight", 5.55, 0.12, 40, 4, self.m["cyan"], arc=300.0)
        bl.place(inner, rotation=(90, 0, 0))
        bl.place(inner, rotation=(0, -120, 0))
        self.put(inner, x, i, 7.6, (0, 0, -FACING), ink=False)
        self.stone("BreakerCrown", 1.1, 2.6, 1.8, x, i, 15.6, "cyan", 4)
        for k, side in enumerate((-1, 1)):
            cx, ci = x + side * 2.6 * math.cos(FACING), i + side * 2.6 * math.sin(FACING)
            self.stone(f"Chamber{k}", 0.8, 1.7, 1.2, cx, ci, 5.4, "cyan", 5)
            self.ring(f"Chamber{k}A", 1.9, 0.12, cx, ci, 5.5, "silver", (math.radians(60), 0, k * 1.2), segs=24, ink=True)
            self.ring(f"Chamber{k}B", 2.2, 0.1, cx, ci, 5.5, "silver", (math.radians(-40), math.radians(30), 0), segs=24, ink=True)
        self.line("BreakerLine", (x + 5.0, i + 4.0), (-(WELL + 0.4) * math.sin(math.radians(32)), HEART - (WELL + 0.4) * math.cos(math.radians(32))), 0.4, "power")
        self.light("Breaker", x, i, 6.0, CYAN, 1.2, 30.0)

    def door(self):
        """The Festival Door: two leaning stones meeting in a point, the void inside them."""
        x, i = DOOR
        turn = FACING
        for side in (-1, 1):
            px, pi = x + side * 3.9 * math.cos(turn), i - side * 3.9 * math.sin(turn)
            lean = side * 0.3
            self.shard(f"DoorStone{side}", 1.9, 14.0, px, pi, lean=(lean * math.sin(turn), -lean * math.cos(turn)))
        self.box("DoorWay", (5.6, 0.2, 8.6), x, i, 4.9, "void", (0, 0, turn))
        self.box("DoorGlow", (4.6, 0.26, 7.4), x, i, 4.6, "way", (0, 0, turn))
        self.disc("DoorStep", 4.4, 0.3, x, i, 0.75, "stone", 8, ink=True)
        self.light("Door", x - 2.0, i + 2.0, 5.0, CYAN, 0.6, 20.0)

    def training(self):
        """The Training machine: a ring to spar in, a stone floating at its far side to strike."""
        x, i = TRAINING
        self.sigil("Training", x, i, 5.5, "pale")
        self.stone("StrikeStone", 1.3, 1.8, 1.8, x, i + 3.4, 4.6, "pale", 6)
        self.ring("StrikeRing", 2.2, 0.12, x, i + 3.4, 4.6, "silver", (math.radians(70), 0, 0), segs=24, ink=True)
        self.person(x, i - 0.6, "Trainee", 0.6)


def see(out: Path, fast, only, walk, clear, both):
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1] * (0.15 if clear else 1.0), azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    views = {f"walk{k + 1}": plan.behind((0.0, y), -1) for k, y in enumerate((16.0, 2.0, -14.0, -SPAWN))}
    views.update(court=plan.behind((0.0, -(SPAWN + 14.0)), -1), heart=((17.0, -52.0, 5.5), (-2.0, -HEART, 12.0)),
                 bay=((-8.0, -46.0, 5.0), (-31.0, -62.0, 4.5)), down=((0.0, 34.0, 132.0), (0.0, -92.0, 0.0)))
    if walk:
        views = {f"film{k:03d}": plan.behind((0.0, 22.0 - k * (22.0 + SPAWN + 14.0) / 47), -1) for k in range(48)}
    elif only:
        views = {name: views[name] for name in only}
    s = Sanctum(scene, out)
    rng = random.Random(3)
    s.plot(0.0, 1, rng)
    if both:
        s.plot(STRIP, -1, rng)
    s.front, s.face, s.tag = 0.0, 1, "S"
    s.box("Strip", (3 * PLOT, STRIP, 0.4), 0, -STRIP / 2, -0.22, "street")
    s.box("Ground", (5 * PLOT, 4 * PLOT, 0.4), 0, -STRIP / 2, -0.9, "ground")
    s.person(6.0, -20.0, "Walker")
    for obj in s.kit.pieces:
        if obj.name.startswith(("Stars", "WellStars", "Deep", "VoidField", "Platform", "Causeway", "Strip", "Ground")):
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
    scene.eevee.taa_render_samples = 8 if fast or walk else 32
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    for name, (eye, target) in views.items():
        scene.camera = plan.camera(scene, name, eye, target)
        linear = look.render_linear(scene, out / f"void_{name}.exr")
        rs.save(look.finish(linear, d), out / f"void_{name}.png")
        (out / f"void_{name}.exr").unlink(missing_ok=True)
    for stray in ("glyph_row.png", "glyph_column.png"):
        (out / stray).unlink(missing_ok=True)
    print(f"{len(s.kit.pieces)} objects in the blockout")


def main():
    args = sys.argv[sys.argv.index("--") + 2:]
    see(bl.out_dir(), "fast" in args, [a for a in args if a not in ("fast", "walk", "clear", "both")], "walk" in args, "clear" in args,
        "both" in args)


if __name__ == "__main__":
    main()
