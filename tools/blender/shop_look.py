"""AR38's colour pass: the Void Shop, the Hanging Stock (research's pick, 2026-11-17, 21:41), as the Strip kit's own
pieces (strip_kit.py: VoidShop, VoidShopMinute, VoidShopCrown) on the Strip as strip_plan lays it, from the same five
views as the grey block (shop_block.py), so the two sheets compare view for view.

The Shop stands where WorldService puts it: on the crossing's axis, 4 studs into its lot from the Strip's south edge,
its front looking at the Strip. The clock shows 3:20 to the next stock, as in the grey: the first minute spent (hidden,
its tooth gone), the second a third left (its tooth scaled from its root), three whole. The crown is lit in the
views that ask whether a rare offer is seen from afar. A minute is a tooth, a blade of void stone with a crack of the
void's light: a spent one is gone, the running one shortened from its root.

    blender -b --factory-startup --python tools/blender/shop_look.py -- <abs out> [view ...] [fast]
    blender -b --factory-startup --python tools/blender/shop_look.py -- <abs out> sheet <grey folder>

Writes look_<view>.png, then shop_look.png (the grey C above, the colour below). Eevee, no GPU turn.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import shop_block as sb  # noqa: E402
import strip_kit as strip  # noqa: E402

sp, block, look, plan, bl, rs = sb.sp, sb.block, sb.look, sb.plan, sb.bl, sb.rs
STRIP, CROSSING, VIEWS = sb.STRIP, sb.CROSSING, sb.VIEWS


class World(sb.World):
    def void_shop(self, crown):
        """The three pieces at the Shop's place, turned to face the Strip (the look's turn is the plan's plus 180)."""
        at = (CROSSING, STRIP + strip.SHOP_IN, 0.0)

        def place(x, y, z):                                # the Shop's frame to the look's: turned half round
            return (at[0] - x, at[1] - y, at[2] + z)

        stand = self.pieces.stand
        stand("VoidShop", "Shop", at, 180.0)
        for k, x in enumerate(strip.MINUTES):
            share = sb.lit_share(k)
            if share <= 0.0:
                continue
            obj = stand("VoidShopMinute", f"Minute{k}", place(x, strip.MINUTE_ALONG, strip.SLAB_Z), 180.0)
            obj.scale = (1.0, 1.0, share)
        if crown:
            stand("VoidShopCrown", "Crown", at, 180.0)
        made = self.pieces.made
        lights = list(made["VoidShop"][0].lights) + (list(made["VoidShopCrown"][0].lights) if crown else [])
        for name, (x, y, z), colour in lights:
            power, reach = (self.watts * 0.7, 60.0) if name == "Crown" else (self.watts * 0.45, 38.0)
            look.light(self.kit, self.scene, f"Shop{name}", place(x, y, z), colour, power, reach).data.use_shadow = False
        self.counter_at = (CROSSING, STRIP + strip.SHOP_IN + 10.5 - 6.5)


def see(out: Path, only, fast):
    d = dict(look.DIRECTIONS["M"])
    d["glow_az"] = 180.0
    az, *rest = d["sun"]
    d["sun"] = (az + 180.0, *rest)
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d["glow_az"], away=look.srgb(d["fog_away"]))
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
        world.dress(*sp.placements())       # Lantern Row past its gate is behind every view here: not laid
        world.void_shop(crown)
        if stand is None:
            stand = (world.counter_at, 0)
        world.person(stand[0], "AtView")
        for obj in world.kit.pieces:
            if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings", "Vein", "FarShard", "CrossingMark",
                                    "VoidShopMinute", "VoidShopCrown")):
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
        path = out / f"look_{name}.png"
        rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
        path.with_suffix(".exr").unlink(missing_ok=True)
        print(name, "done")
    for name in ("glyph_column.png", "glyph_row.png"):
        (out / name).unlink(missing_ok=True)


def sheet(out: Path, grey: Path):
    import numpy as np
    import ui_sheet as ui

    w, h = look.SIZE
    s = 0.5
    tw, th = int(w * s), int(h * s)
    gap, left, head = 14, 150, 30
    names = list(VIEWS) + ["street_close"]
    labels = dict({name: VIEWS[name][2] for name in VIEWS}, street_close="down the side street: the Shop, each pixel x3")
    cx, cy = (w - tw // 3) // 2, 66
    rows = (("Grey", "the pick, as judged", lambda name: grey / f"shop_C_{name}.png"),
            ("Colour", "the kit's pieces", lambda name: out / f"look_{name}.png"))
    width = left + len(names) * (tw + gap) + gap
    height = 70 + len(rows) * (th + head + gap) + 60
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "AR38, the Void Shop, C the Hanging Stock: the grey block and the colour pass, the clock at 3:20 "
                        "to the next stock", "#EDE6D6", bold=0.2)
    y = 56
    for key, said, src in rows:
        t.text(gap, y + head + th // 2 - 20, 16, key, "#EDE6D6", bold=0.3)
        t.text(gap, y + head + th // 2 + 2, 13, said, "#B4AC9C")
        for k, name in enumerate(names):
            x = left + gap + k * (tw + gap)
            t.text(x, y + 6, 13, labels[name], "#B4AC9C")
            if name == "street_close":
                px = rs.load(src("street"))[cy:cy + th // 3, cx:cx + tw // 3]
                rs.paste(page.px, np.repeat(np.repeat(px, 3, axis=0), 3, axis=1), x, y + head)
            else:
                rs.paste(page.px, rs.shrink(rs.load(src(name)), s), x, y + head)
        y += th + head + gap
    t.text(gap, page.h - 40, 13, "Each view is the game's camera behind a player (Roblox's start zoom, 70 degrees), at the "
                                 "place's dusk, in Blender at 960 x 540, shown at half size. The colour row wears the base "
                                 "kit's own pictures, its glow strengths as the manifest gives them.", "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "shop_look.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "sheet" in args:
        sheet(out, Path(args[args.index("sheet") + 1]))
        return
    only = [a for a in args if a in VIEWS] or list(VIEWS)
    see(out, only, "fast" in args)


if __name__ == "__main__":
    main()
