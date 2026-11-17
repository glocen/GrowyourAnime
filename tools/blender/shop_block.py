"""AR38's blockout: the Void Shop's building in grey, three directions, for research's pick. Throwaway: stand-ins on
the Strip as strip_plan lays it, nothing polished and nothing exported.

The Shop stands in its lot south of the crossing (Config/World, "Strip"; WorldService's grey slab): the lot is a plot
square, from the Strip's south edge (y = 48 in the look's frame) back 128 studs, the crossing's width across. Here
`u` runs across from the Shop's axis (the crossing's middle) and `v` inward from the Strip's edge.

What every direction has to meet (measured on the Strip's renders, 2026-11-17):
- the crossing's great shard hangs from 8.5 to 46 studs over the crossing's middle, about 17 across. From the side
  street it hides anything on the Shop's axis higher than about 8 studs, within about 10 of the axis;
- from the crossing (the player 12 studs into the Strip, the Shop's front about 42 off), the game's camera sees up to
  about 20 studs over the Shop's front, and no higher.

So the clock stands low or off the axis, and the crown is wide or to one side. The class is the void's own, as the
base's machines are: never a market stall, a vending machine, a shop front or a wall clock, and nothing of Lantern
Row's lanterns.

  A, the Five Stones: a low vault of void stone, the counter in its mouth. The clock is five shards standing in an arc
     on the forecourt, one a minute, each going dark as its minute runs out. The crown is the vault's horned crest.
  B, the Spire: a spire beside a low pavilion. The clock is a gauge of five slots up the spire's face, draining from
     the top. The crown is the spire's split tip.
  C, the Hanging Stock: a slab of void stone hovering over the counter. The clock is five shards hanging from its
     front edge. The crown is the slab's whole front rim, lit.

The clock is shown at 3:20 to the next stock: one minute spent, the second a third left, three whole. The crown is lit
in the views that ask whether a rare offer is seen from afar, and unlit at the counter.

    blender -b --factory-startup --python tools/blender/shop_block.py -- <abs out> [A|B|C ...] [view ...] [fast]
    blender -b --factory-startup --python tools/blender/shop_block.py -- <abs out> sheet

Writes shop_<direction>_<view>.png, then shop_block.png. Eevee, no GPU turn.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import strip_plan as sp  # noqa: E402

block = sp.block
plan, look, bl, rs = block.plan, block.look, block.bl, block.rs
STRIP, CROSSING = sp.STRIP, block.CROSSING

LEFT = 3 + 20 / 60          # minutes to the next stock in every view
DIRECTIONS = {"A": "the Five Stones", "B": "the Spire", "C": "the Hanging Stock"}
# Where the player stands for each view (the look's frame, yaw from +Y toward +X) and whether the crown is lit.
VIEWS = {
    "crossing": (((CROSSING, 12.0), 0), False, "from the crossing"),
    "crossing_on": (((CROSSING, 12.0), 0), True, "from the crossing, a rare offer in"),
    "street": (((CROSSING, -150.0), 0), True, "down the side street, 160 studs off, a rare offer in"),
    "street_off": (((CROSSING, -150.0), 0), False, "down the side street, 160 studs off, the clock alone"),
    # 110 east of the crossing's middle: from 150 the bare plot's front wall still hides the Shop
    "along": (((CROSSING + 110.0, 24.0), -90), True, "walking the Strip from the east, 110 off, a rare offer in"),
    "counter": (None, False, "at the counter"),
}


def lit_share(k):
    """How much of the clock's k-th minute (0 first) is still to run: 1 whole, 0 spent."""
    spent = 5 - LEFT
    return max(0.0, min(1.0, 1.0 - (spent - k)))


class World(sp.World):
    def __init__(self, scene, d):
        super().__init__(scene, d)
        f = self.flat
        f["shop"] = look.painted("ShopStone", "#A3A8BA", "#5F6579")
        f["shop_dark"] = look.painted("ShopDark", "#5C6174", "#363A4B")
        f["shop_lit"] = look.glowing("ShopLit", "#F2F2F8", 2.4)
        f["shop_spent"] = look.painted("ShopSpent", "#43475A", "#2B2E3C")
        f["shop_crown"] = look.glowing("ShopCrown", "#FFFFFF", 4.5)
        f["shop_shelf"] = look.glowing("ShopShelf", "#D6D9E6", 0.9)
        self.counter_at = (CROSSING, STRIP + 10.0)

    def floors(self):
        """strip_plan's floors without the grey Shop: its lot's floor stays."""
        b, f = self.kit.block, self.flat
        long, mid = 2 * sp.END, CROSSING
        b("Strip", (long, STRIP, 0.4), (mid, STRIP / 2, -0.22), self.stone)
        b("SideStreet", (sp.STREET, -block.GATE, 0.4), (mid, block.GATE / 2, -0.22), self.stone)
        b("Ground", (3200, 3200, 0.4), (mid, STRIP / 2, -0.3), f["ground"])
        b("ShopFloor", (block.PLOT, block.PLOT, 0.4), (mid, STRIP + block.PLOT / 2, -0.24), f["lot_asleep"])
        b("RowFloor", (sp.STREET, 130, 0.4), (mid, block.GATE - 65, -0.22), self.stone)

    # --- the pieces, in the Shop's own frame ---

    def p(self, u, v, z=0.0):
        return (CROSSING + u, STRIP + v, z)

    def sbox(self, name, size, u, v, z, mat, rot=(0, 0, 0)):
        return self.kit.block(f"Shop{name}", size, self.p(u, v, z), self.flat[mat], big=True, rot=rot)

    def shard(self, name, u, v, z, r, h, mat, tip=0.12, rot=(0, 0, 0), down=False):
        """A four-sided shard standing on (u, v, z), or hanging from it when `down`."""
        obj = bl.cylinder(f"Shop{name}", r * tip if down else r, h, segments=4, material=self.flat[mat],
                          radius_top=r if down else r * tip)
        obj.location = self.p(u, v, z - h / 2 if down else z + h / 2)
        obj.rotation_euler = (rot[0], rot[1], rot[2] + math.pi / 4)
        return self.kit.add(obj, True)

    def minute_shard(self, name, k, u, v, z, r, h, down=False, tip=0.12):
        """The clock's k-th minute as a shard: lit while it's to run, dark once spent, the running one lit in part
        (standing, from its foot up; hanging, from its root down)."""
        share = lit_share(k)
        if share >= 1.0 or share <= 0.0:
            self.shard(name, u, v, z, r, h, "shop_lit" if share >= 1.0 else "shop_spent", tip=tip, down=down)
            return
        cut = h * share
        r_cut = r + (r * tip - r) * share
        if down:
            lit = bl.cylinder(f"Shop{name}Lit", r_cut, cut, segments=4, material=self.flat["shop_lit"], radius_top=r)
            lit.location = self.p(u, v, z - cut / 2)
            rest = bl.cylinder(f"Shop{name}Rest", r * tip, h - cut, segments=4, material=self.flat["shop_spent"],
                               radius_top=r_cut)
            rest.location = self.p(u, v, z - cut - (h - cut) / 2)
        else:
            lit = bl.cylinder(f"Shop{name}Lit", r, cut, segments=4, material=self.flat["shop_lit"], radius_top=r_cut)
            lit.location = self.p(u, v, z + cut / 2)
            rest = bl.cylinder(f"Shop{name}Rest", r_cut, h - cut, segments=4, material=self.flat["shop_spent"],
                               radius_top=r * tip)
            rest.location = self.p(u, v, z + cut + (h - cut) / 2)
        for obj in (lit, rest):
            obj.rotation_euler = (0, 0, math.pi / 4)
            self.kit.add(obj, True)

    def counter(self, u, v, wide):
        """The counter: a slab of void stone at a player's waist, facing the Strip."""
        self.sbox("Counter", (wide, 2.4, 3.2), u, v, 1.6, "shop_dark")
        self.counter_at = (CROSSING + u, STRIP + v - 6.5)

    # --- the three directions ---

    def five_stones(self, crown):
        # the vault, its mouth open to the Strip with the counter in it, its back wall the shelf's light
        self.sbox("Vault", (36, 16, 9), 0, 30, 4.5, "shop")
        self.sbox("Roof", (30, 13, 1.2), 0, 30.5, 9.6, "shop_dark")
        for s in (-1, 1):
            self.sbox(f"Cheek{s}", (8, 6, 9), s * 14, 19, 4.5, "shop")
        self.sbox("Lintel", (20, 6, 2.5), 0, 19, 7.75, "shop")
        self.sbox("Shelf", (19.6, 0.4, 5.4), 0, 21.9, 3.4, "shop_shelf")
        self.counter(0, 17.6, 14)
        # the crown: two horns leaning out from the front corners, three points on the front edge between them
        mat = "shop_crown" if crown else "shop"
        for s in (-1, 1):
            self.shard(f"Horn{s}", s * 16.5, 22.5, 8.6, 1.3, 10, mat, rot=(0, s * math.radians(34), 0))
        for k, (u, h) in enumerate(((-6, 3.2), (0, 4.4), (6, 3.2))):
            self.shard(f"Crest{k}", u, 23, 9.0, 0.9, h, mat)
        # the clock: five stones in a row facing the Strip on the forecourt's east side (u under 0 is the world's east),
        # the first minute the farthest out: clear of the way in to the counter, and of the crossing shard's cover from
        # the side street
        for k, u in enumerate((-36.0, -31.5, -27.0, -22.5, -18.0)):
            v = 6.0 + 0.04 * (u + 27.0) ** 2 * 0.25
            self.sbox(f"StoneFoot{k}", (3.2, 3.2, 0.6), u, v, 0.3, "shop_dark", rot=(0, 0, math.pi / 4))
            self.minute_shard(f"Stone{k}", k, u, v, 0.6, 1.2, 7.5)

    def spire(self, crown):
        su, sv = 22.0, 12.0
        self.sbox("SpirePlinth", (9, 9, 1.4), su, sv, 0.7, "shop_dark", rot=(0, 0, math.pi / 4))
        self.shard("Spire", su, sv, 1.4, 4.2, 33, "shop", tip=0.16)
        # the gauge: five slots up the spire's north face, the first minute the highest, so it drains from the top;
        # all under 21 studs, where the game's camera at the crossing still sees the spire
        for k in range(5):
            z = 19.0 - k * 3.8
            face = 4.2 / math.sqrt(2) * (1 - (1 - 0.16) * (z - 1.4) / 33)   # the face's distance at that height
            share = lit_share(k)
            if 0 < share < 1:
                self.sbox(f"Slot{k}Rest", (1.6, 0.4, 3.0 * (1 - share)), su, sv - face - 0.15, z + 1.5 * share,
                         "shop_spent")
                self.sbox(f"Slot{k}Lit", (1.6, 0.4, 3.0 * share), su, sv - face - 0.15, z - 1.5 * (1 - share), "shop_lit")
            else:
                self.sbox(f"Slot{k}", (1.6, 0.4, 3.0), su, sv - face - 0.15, z, "shop_lit" if share >= 1 else "shop_spent")
        # the crown: the spire's tip split in three
        mat = "shop_crown" if crown else "shop"
        for k, lean in enumerate((-24, 0, 24)):
            self.shard(f"Tip{k}", su + lean * 0.06, sv, 33.4, 0.8, 7.5 if lean == 0 else 5.5, mat,
                       rot=(0, math.radians(lean), 0))
        # the pavilion: a slab on two leaning stones over the counter, the shelf's light on its back wall
        self.sbox("PavilionRoof", (24, 14, 1.4), -3, 15, 9.4, "shop_dark")
        for s, u in ((-1, -13.5), (1, 7.5)):
            self.sbox(f"Leg{s}", (2.2, 2.2, 9.6), u, 15, 4.6, "shop", rot=(0, s * math.radians(-8), 0))
        self.sbox("BackWall", (21, 1.4, 7), -3, 21, 3.5, "shop")
        self.sbox("Shelf", (17, 0.4, 4.6), -3, 20.2, 3.6, "shop_shelf")
        self.counter(-3, 11.5, 13)

    def hanging_stock(self, crown):
        # the slab, hovering: nothing holds it up
        self.sbox("Slab", (34, 18, 1.8), 0, 18, 12.2, "shop_dark")
        self.sbox("SlabTop", (28, 13, 1.2), 0, 19, 13.6, "shop")
        rim = "shop_crown" if crown else "shop"
        self.sbox("RimFront", (34.4, 0.8, 1.2), 0, 8.8, 12.0, rim)
        for s in (-1, 1):
            self.sbox(f"RimSide{s}", (0.8, 18.4, 1.2), s * 17.2, 18, 12.0, rim)
        # the counter under it, three standing slabs behind as its back, the shelf's light between
        self.counter(0, 14.5, 16)
        for k, (u, turn) in enumerate(((-10, 14), (0, 0), (10, -14))):
            self.sbox(f"Back{k}", (9, 1.4, 7.5), u, 22.5, 3.75, "shop", rot=(0, 0, math.radians(turn)))
        self.sbox("Shelf", (22, 0.4, 4.6), 0, 21.4, 3.6, "shop_shelf")
        # the clock: five shards hanging from the east half of the slab's front edge, the first minute the farthest out:
        # clear of the crossing shard's tip (it hides about 3 studs either side of the axis there, seen from the
        # crossing) and of the way in to the counter
        for k, u in enumerate((-17, -14, -11, -8, -5)):
            self.minute_shard(f"Drop{k}", k, u, 9.6, 11.3, 1.1, 5.4, down=True)


def see(out: Path, which, only, fast):
    d = dict(look.DIRECTIONS["M"])
    d["glow_az"] = 180.0
    az, *rest = d["sun"]
    d["sun"] = (az + 180.0, *rest)
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d["glow_az"], away=look.srgb(d["fog_away"]))
    for key in which:
        for name in only:
            stand, crown, _ = VIEWS[name]
            scene = bl.reset_scene()
            world = World(scene, d)
            for dx, row, who in block.PLOTS.values():
                if who in ("ours", "home"):
                    world.home(dx, row)
                else:
                    world.shell(dx, row, lit=who == "lit")
            world.floors()
            world.dress(*sp.placements())   # Lantern Row past its gate is behind every view here: not laid, to save memory
            {"A": world.five_stones, "B": world.spire, "C": world.hanging_stock}[key](crown)
            if stand is None:
                stand = (world.counter_at, 0)
            world.person(stand[0], "AtView")
            for obj in world.kit.pieces:
                if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings", "Vein", "FarShard", "CrossingMark")):
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
            scene.eevee.taa_render_samples = 8 if fast else 16
            for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
                try:
                    setattr(scene.eevee, attr, val)
                except AttributeError:
                    pass
            eye, target = block.behind(*stand)
            scene.camera = plan.camera(scene, name, eye, target)
            path = out / f"shop_{key}_{name}.png"
            rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            print(key, name, "done")
    for name in ("glyph_column.png", "glyph_row.png"):
        (out / name).unlink(missing_ok=True)


def sheet(out: Path):
    import numpy as np
    import ui_sheet as ui

    w, h = look.SIZE
    s = 0.5
    tw, th = int(w * s), int(h * s)
    gap, left, head = 14, 150, 30
    names = list(VIEWS) + ["street_close"]
    labels = dict({name: VIEWS[name][2] for name in VIEWS}, street_close="down the side street: the Shop, each pixel x3")
    cx, cy = (w - tw // 3) // 2, 66                    # the side street's view, where the Shop stands in it
    width = left + len(names) * (tw + gap) + gap
    height = 70 + len(DIRECTIONS) * (th + head + gap) + 60
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "AR38, the Void Shop in grey: three directions on the Strip, the clock at 3:20 to the next stock",
           "#EDE6D6", bold=0.2)
    y = 56
    for key, said in DIRECTIONS.items():
        t.text(gap, y + head + th // 2 - 20, 16, key, "#EDE6D6", bold=0.3)
        t.text(gap, y + head + th // 2 + 2, 13, said, "#B4AC9C")
        for k, name in enumerate(names):
            x = left + gap + k * (tw + gap)
            t.text(x, y + 6, 13, labels[name], "#B4AC9C")
            if name == "street_close":
                px = rs.load(out / f"shop_{key}_street.png")[cy:cy + th // 3, cx:cx + tw // 3]
                rs.paste(page.px, np.repeat(np.repeat(px, 3, axis=0), 3, axis=1), x, y + head)
            else:
                rs.paste(page.px, rs.shrink(rs.load(out / f"shop_{key}_{name}.png"), s), x, y + head)
        y += th + head + gap
    t.text(gap, page.h - 40, 13, "Each view is the game's camera behind a player (Roblox's start zoom, 70 degrees), at the "
                                 "place's dusk, in Blender at 960 x 540, shown at half size. Grey stand-ins: the lit "
                                 "parts are the clock's minutes still to run, the crown when lit, and the shelf's light.",
           "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "shop_block.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "sheet" in args:
        sheet(out)
        return
    which = [a for a in args if a in DIRECTIONS] or list(DIRECTIONS)
    only = [a for a in args if a in VIEWS] or list(VIEWS)
    see(out, which, only, "fast" in args)


if __name__ == "__main__":
    main()
