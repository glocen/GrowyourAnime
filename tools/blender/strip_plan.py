"""AR17: where the Strip's pieces stand, and the look of it from the player's camera.

It is laid out in the world's own frame (Config/World, WorldService) at plots of 128: studs, the crossing's middle at
the origin, the Strip along X from -432 to 432 and 48 wide, north toward -Z, the side street north from the Strip to
the festival gate at z = -200. It is written in Lantern Row's plan's frame and shape, so the builder's Kit.Place takes it as it is: from
the festival gate's middle, `across` toward +X and `along` toward -Z (the crossing's middle is at along -272), `turn`
in degrees anticlockwise seen from above, and the real lights in a list of their own. The pieces are strip_kit's:
the void's own, nothing of the festival's before its gate (the director, 2026-11-16).

The look stands the same placements in strip_block's scene (the blockout's bases and haze) in place of its blocks.

    blender -b --factory-startup --python tools/blender/strip_plan.py -- build/handoff/Strip [plan] [view ...] [fast]

`plan` writes plan.json alone. Otherwise writes strip_<view>.png. Eevee, no GPU turn.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import strip_block as block  # noqa: E402
import strip_kit as strip  # noqa: E402

plan, base, bl, kit, look, rs = block.plan, block.base, block.bl, block.kit, block.look, block.rs
ROW_PIECES = set(kit.PIECES)
# The world at 128 (Config/World; WorldService.lay): the Strip's width, the side street's, the crossing's middle to a
# Strip's end (432), and the festival gate (-200, the Strip's half, a plot, its path and its Tower).
STRIP, STREET, END = 48.0, 44.0, block.END
GATE = block.GATE - STRIP / 2
PLOTS = (block.CROSSING, block.CROSSING + block.PLOT + block.BETWEEN)   # a plot's middle each side of the crossing (128, 288); its gate's wings reach 28
OPEN = block.PLOT / 2                                   # the crossing's lot reaches this far each side of the side street's middle
ENDS = {"SealCalamity": -1, "SealClash": 1}             # which end each gate closes, the sign of its x: the Calamity west (docs/design.md)
REACH, WIDE = 13, 5                                     # the crack's tiles from the crossing's ring to a sealed gate; the wide ones first
UP, UP_WIDE = 6, 3                                      # the same up the side street: it stops 11 short of the festival gate
SEALS = strip.HEART + strip.TILE * REACH + 2.5          # a sealed gate's place: where the crack ends, on the Strip's slab (401.5, 30 from the end)
# The Strip's posts, each side of the crossing: the first two flank the side street's mouth and the Shop's, then a pair
# flanks each gate (its wings at 100 to 156 and 260 to 316), one between. Past the far gate the outcrops take over.
POSTS = (40.0, 98.0, 158.0, 208.0, 258.0, 318.0)
SOUTH_FIRST = 70.0                                      # but the first south pair stands out here, clear of the Tower's boards before the Shop (x 29 to 59 each side, faces at z 32; TR58): at 40 it swept across their titles
SIDE_POSTS = (-62.0, -114.0, -166.0)                    # up the side street, each side
FAR_RING = (END + 272.0, -GATE + 368.0)                 # the far shards' ring, across and along: as far past the ends and the gate as at 200


def placements():
    """The placements and the real lights, in the world's frame: (piece, x, z, turn) and (name, x, z, up, colour, kind)."""
    rng = np.random.default_rng(17)
    out, lights = [], []

    def put(piece, x, z, turn=0.0):
        out.append((piece, float(x), float(z), float(turn) % 360.0))

    put("CrossingMark", 0, 0, 0)
    put("CrossingShard", 0, 0, 0)
    lights.append(("Crossing", 0.0, 0.0, 24.0, "#B58CFF", "point"))
    for name, side in ENDS.items():
        put(name, side * SEALS, 0, side * 90)
        lights.append((name, side * SEALS, 0.0, 46.0, {"SealCalamity": "#B58CFF", "SealClash": "#7CE8FF"}[name], "point"))
    # The lamps: posts each side of the Strip, clear of every gate and of the crossing's two mouths (POSTS), and three a
    # side up the side street.
    for k, at in enumerate(POSTS):
        for sx in (-1, 1):
            for sz in (-1, 1):
                x, z = sx * (SOUTH_FIRST if k == 0 and sz > 0 else at), sz * (STRIP / 2 - 2.4)
                put("StripPost", x, z, sz * 90)
                if k == 0:   # the first pair each side carries a real light; the rest only glow
                    lights.append((f"Post{'W' if sx < 0 else 'E'}{'N' if sz < 0 else 'S'}", x, z - sz * strip.LAMP[0], strip.LAMP[1],
                                   "#C9B0FF", "point"))
    for z in SIDE_POSTS:
        for sx in (-1, 1):
            put("StripPost", sx * (STREET / 2 - 2.4), z, 90 + sx * 90)
    # The void's crack: down the Strip's middle from each sealed gate to the crossing's ring, wide near the crossing and
    # thin far off, up the side street until the festival's own light takes over, and a branch to the Shop and to
    # every base's gate.
    tile, heart = strip.TILE, strip.HEART
    for sx in (-1, 1):
        for k in range(REACH):
            put("VeinWide" if k < WIDE else "VeinThin", sx * (heart + tile * (k + 0.5)), 0, 90 + 180 * int(rng.integers(0, 2)))
    for k in range(UP):
        put("VeinWide" if k < UP_WIDE else "VeinThin", 0, -(heart + tile * (k + 0.5)), 180 * int(rng.integers(0, 2)))
    put("VeinBranch", 0, heart + strip.BRANCH / 2, 180)
    for x in PLOTS:
        for sx in (-1, 1):
            put("VeinBranch", sx * x, -(1.0 + strip.BRANCH / 2), 0)
            put("VeinBranch", sx * x, 1.0 + strip.BRANCH / 2, 180)
    # Where nobody has built, shards break out of the ground: in the open each side of the side street, and along the
    # street's edges before each sealed gate.
    for sx in (-1, 1):
        stood = []
        for _ in range(6):
            for _ in range(40):
                x = sx * (STREET / 2 + 10.0 + rng.random() * (OPEN - STREET / 2 - 22.0))
                z = -44.0 - rng.random() * (-GATE - 60.0)
                if all((x - a) ** 2 + (z - b) ** 2 > 26.0 ** 2 for a, b in stood):
                    break
            stood.append((x, z))
            put("ShardOutcrop", x, z, rng.uniform(0, 360))
        for k, back in enumerate((9.0, 20.0, 31.0, 42.0)):     # between the far plot's edge (352) and the gate
            put("ShardOutcrop", sx * (SEALS - back), (1 if k % 2 else -1) * (STRIP / 2 - 5.0 - 2.0 * k), rng.uniform(0, 360))
    # Past the edges: great shards far off in the haze, all round but the festival's sky.
    names = list(strip.SHARDS)
    for i in range(34):
        a = math.tau * (i + rng.random() * 0.6) / 34
        if abs(a - 1.5 * math.pi) < 0.3:
            continue
        far = 1.0 + 0.25 * rng.random()
        put(names[int(rng.integers(0, 3))], math.cos(a) * FAR_RING[0] * far, math.sin(a) * FAR_RING[1] * far, rng.uniform(0, 360))
    return out, lights


def write(out: Path):
    places, lights = placements()
    manifest = json.loads((out / "manifest.json").read_text(encoding="utf-8"))["pieces"]
    row = json.loads((block.ROW / "manifest.json").read_text(encoding="utf-8"))["pieces"]
    tally = {}
    for piece, *_ in places:
        tally[piece] = tally.get(piece, 0) + 1
    triangles = {name: n * (manifest.get(name) or row[name])["triangles"] for name, n in tally.items()}
    book = dict(
        what="AR17: the Strip, the crossing and the side street, dressed in the void's own: nothing of the festival's "
             "before its gate. Pieces from this folder's manifest.",
        origin=f"the festival gate's middle on the floor, as Lantern Row's plan: the world's (0, floor, {GATE:g}), with "
               f"plots of 128 studs, 32 apart (Config/World). The crossing's middle is at across 0, along {GATE:g}; the "
               f"Strip's ends at across {-END:g} and {END:g}.",
        axes="across toward +X, along toward -Z (so everything here has along under 0), turn in degrees anticlockwise "
             "seen from above: Kit.Place's own. At turn 0 a piece's front looks north.",
        placements=[dict(piece=piece, across=round(x, 2), along=round(GATE - z, 2), turn=round(turn, 1)) for piece, x, z, turn in places],
        lights=[dict(name=name, across=round(x, 2), along=round(GATE - z, 2), up=up, colour=colour, kind=kind,
                     **(dict(cone=66.0) if kind == "spot" else {})) for name, x, z, up, colour, kind in lights],
        lightsNote="seven real lights, Shadows off, in the plan's list as Lantern Row's are: a PointLight at the shard of "
                   "each of the four posts nearest the crossing, one in the crossing's great shard, and a faint one at each "
                   "sealed gate's shard, in its own colour. Everything else only glows. A manifest's `lights` name the "
                   "same points piece by piece.",
        bare="a plot with no player home, as the blockout showed it and research judged it from the Strip: the base's "
             "front walls and its gate standing with their glow at 0, on the plain deck floor. No machines, no Tower, "
             "no sleeping stone, no light of its own. The game today shows a bare lot as its floor alone: the walls and "
             "the gate asleep are a state to build, the builder's and research's call.",
        edges="nothing here closes the map: a sealed gate ends the street's own 48 studs, and the ground still ends at "
              "its edge. The far shards stand past it, their feet under the floor.",
        budget=dict(pieces=tally, placements=len(places), triangles=triangles, trianglesInAll=sum(triangles.values()),
                    lights=len(lights), note="counted from the plan, not measured on a device"))
    (out / "plan.json").write_text(json.dumps(book, indent=1), encoding="utf-8")
    print(json.dumps(book["budget"]))


class World(block.World):
    """The blockout's world, with the plan's pieces where its blocks stood."""

    def __init__(self, scene, d):
        super().__init__(scene, d)
        self.pieces = strip.Stock(block.BASE_MAPS, scene, self.kit)

    def here(self, x, z):
        return (block.CROSSING - x, z + STRIP / 2, 0.0)

    def floors(self):
        b, f = self.kit.block, self.flat
        long, mid = 2 * END, block.CROSSING
        b("Strip", (long, STRIP, 0.4), (mid, STRIP / 2, -0.22), self.stone)
        b("SideStreet", (STREET, -block.GATE, 0.4), (mid, block.GATE / 2, -0.22), self.stone)
        b("Ground", (3200, 3200, 0.4), (mid, STRIP / 2, -0.3), f["ground"])
        b("ShopFloor", (block.PLOT, block.PLOT, 0.4), (mid, STRIP + block.PLOT / 2, -0.24), f["lot_asleep"])
        b("Shop", (40, 28, 14), (mid, STRIP + 20, 7), f["machine"], big=True)
        b("ShopClock", (8, 1, 8), (mid, STRIP + 5.4, 10), f["waiting"])
        b("RowFloor", (STREET, 130, 0.4), (mid, block.GATE - 65, -0.22), self.stone)

    def dress(self, places, lights):
        for i, (piece, x, z, turn) in enumerate(places):
            stand = self.row_stand if piece in ROW_PIECES else self.pieces.stand
            stand(piece, f"P{i}", self.here(x, z), turn + 180.0)
        for name, x, z, up, colour, kind in lights:
            at = self.here(x, z)[:2] + (up,)
            if kind == "spot":
                pool = look.light(self.kit, self.scene, name, at, colour, self.watts, 40.0, kind="SPOT")
                pool.data.spot_size, pool.data.spot_blend, pool.data.use_shadow = math.radians(66.0), 0.7, False
            else:
                power, reach = (self.watts * 0.7, 60.0) if name.startswith(("Seal", "Crossing")) else (self.watts * 0.45, 38.0)
                look.light(self.kit, self.scene, name, at, colour, power, reach).data.use_shadow = False

    def beyond(self):
        """Lantern Row past its gate, as its own plan lays it: its gate and its first hundred studs."""
        self.row_stand("FestivalGate", "Gate", self.row_at(0, 0), 180)
        places = json.loads((block.ROW / "plan.json").read_text(encoding="utf-8"))["placements"]
        for i, p in enumerate(places):
            if 0 < p["along"] <= 100 or (p["along"] <= 0 and p["piece"] in ("StreetBay", "SignBoard")):
                self.row_stand(p["piece"], f"Row{i}", self.row_at(p["across"], p["along"]), p["turn"] + 180)
        glow = look.light(self.kit, self.scene, "RowGlow", (block.CROSSING, block.GATE - 40.0, 14.0), "#FFD49A", self.watts * 2.0, 90.0)
        glow.data.use_shadow = False


FAR = -(block.PLOT + block.BETWEEN)                      # the far plot's middle, in the look's frame
STANDS = dict(block.STANDS)
STANDS.update(far=((FAR, 12.0), 90), line=((-150.0, 24.0), 90), clash=((block.ENDS[0] + 110.0, 24.0), -90),
              calamity=((block.ENDS[1] - 110.0, 24.0), 90), mark=((block.CROSSING + 34.0, 24.0), -90),
              vein=((block.CROSSING - 52.0, 21.0), 60))
STANDS.pop("stone", None)
# Research's fix 3 (2026-11-16, 14:09), the great shard from a far gate, is `far` itself at 128: that gate stands 288
# from the crossing.


def see(out: Path, only, fast):
    d = dict(look.DIRECTIONS["M"])
    d["glow_az"] = 180.0                                           # the dusk's glow lies north, over the festival
    az, *rest = d["sun"]
    d["sun"] = (az + 180.0, *rest)
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d["glow_az"], away=look.srgb(d["fog_away"]))
    scene = bl.reset_scene()
    world = World(scene, d)
    for dx, row, who in block.PLOTS.values():
        if who in ("ours", "home"):
            world.home(dx, row)
        else:
            world.shell(dx, row, lit=who == "lit")
    world.floors()
    world.dress(*placements())
    world.beyond()
    for name in only or STANDS:
        world.person(STANDS[name][0], f"At{name}")
    for obj in world.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Floor", "Vein", "FarShard", "CrossingMark")):
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
    for name in only or STANDS:
        eye, target = block.behind(*STANDS[name])
        scene.camera = plan.camera(scene, name, eye, target)
        linear = look.render_linear(scene, out / f"strip_{name}.exr")
        rs.save(look.finish(linear, d), out / f"strip_{name}.png")
        (out / f"strip_{name}.exr").unlink(missing_ok=True)
    for name in ("glyph_column.png", "glyph_row.png"):
        (out / name).unlink(missing_ok=True)
    print(f"the Strip: {len(world.kit.pieces)} objects, {len(world.kit.lights)} lights")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "plan" in args:
        write(out)
    else:
        see(out, [a for a in args if a != "fast"], "fast" in args)


if __name__ == "__main__":
    main()
