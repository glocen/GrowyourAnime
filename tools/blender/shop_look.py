"""AR38's colour pass: the Void Shop, the Hanging Stock (research's pick, 2026-11-17, 21:41), as the Strip kit's own
pieces (strip_kit.py: VoidShop, VoidShopMinute, VoidShopCrown) on the Strip as strip_plan lays it, from the same views
as the grey block (shop_block.py), so the two compare view for view.

The Shop stands where WorldService puts it: on the crossing's axis, 4 studs into its lot from the Strip's south edge,
its front looking at the Strip. The clock shows 3:20 to the next stock, as in the grey: the first minute spent (its
tooth gone), the second a third left (its tooth scaled from its root), three whole. The crown is lit in the views that
ask whether a rare offer is seen from afar.

The clock's numbers can be tried without an edit: blade=, rim=, bright= and sw= set the minute's half width, its dark
rim's size over the tooth's, its glow over the kit's and its swatch, and tag= names the try's files. Each render writes,
beside its picture, where the clock and the counter fall in it (projected from the camera), for the measures.

    blender -b --factory-startup --python tools/blender/shop_look.py -- <abs out> [view ...] [fast] [day] [tag=..] [rim=..]
    blender -b --factory-startup --python tools/blender/shop_look.py -- <abs out> sheet <grey folder>
    blender -b --factory-startup --python tools/blender/shop_look.py -- <abs out> clock <grey folder> <tag> [tag ...]

Writes look_<view>[_<tag>].png and .json; shop_look.png (the grey C above, the colour below); clock_look.png and
clock_measures.json (the clock alone: the grey and each try, measured). Eevee, no GPU turn.
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import shop_block as sb  # noqa: E402
import strip_kit as strip  # noqa: E402

sp, block, look, plan, bl, rs = sb.sp, sb.block, sb.look, sb.plan, sb.bl, sb.rs
STRIP, CROSSING, VIEWS = sb.STRIP, sb.CROSSING, sb.VIEWS
AT = (CROSSING, STRIP + strip.SHOP_IN, 0.0)       # the Shop's place in the look's frame
LIT, SHOWN = 0.75, 4                               # a lit pixel's luminance; the minutes shown at 3:20


def place(x, y, z):
    """The Shop's frame to the look's: turned half round."""
    return (AT[0] - x, AT[1] - y, AT[2] + z)


class World(sb.World):
    def void_shop(self, crown):
        """The three pieces at the Shop's place, turned to face the Strip (the look's turn is the plan's plus 180)."""
        stand = self.pieces.stand
        stand("VoidShop", "Shop", AT, 180.0)
        for k, x in enumerate(strip.MINUTES):
            share = sb.lit_share(k)
            if share <= 0.0:
                continue
            obj = stand("VoidShopMinute", f"Minute{k}", place(x, strip.MINUTE_ALONG, strip.SLAB_Z), 180.0)
            obj.scale = (1.0, 1.0, share)
        if crown:
            stand("VoidShopCrown", "Crown", AT, 180.0)
        made = self.pieces.made
        lights = list(made["VoidShop"][0].lights) + (list(made["VoidShopCrown"][0].lights) if crown else [])
        for name, (x, y, z), colour in lights:
            power, reach = (self.watts * 0.7, 60.0) if name == "Crown" else (self.watts * 0.45, 38.0)
            look.light(self.kit, self.scene, f"Shop{name}", place(x, y, z), colour, power, reach).data.use_shadow = False
        self.counter_at = (CROSSING, STRIP + strip.SHOP_IN + 10.5 - 6.5)


def boxes(scene, cam):
    """Where the clock and the counter (its edge, the shelf and its six lines) fall in the picture: pixel boxes."""
    from bpy_extras.object_utils import world_to_camera_view
    from mathutils import Vector

    w, h = look.SIZE
    reach = strip.MINUTE + 0.6
    parts = {"clock": [(x, strip.MINUTE_ALONG, z) for x in (strip.MINUTES[0] + 1.2, strip.MINUTES[-1] - 1.2)
                       for z in (strip.SLAB_Z - 0.3, strip.SLAB_Z - reach)],
             "counter": [(x, y, z) for x in (-11.5, 11.5) for y in (-9.0, -17.7) for z in (3.0, 6.0)]}
    found = {}
    for name, corners in parts.items():
        pts = [world_to_camera_view(scene, cam, Vector(place(*c))) for c in corners]
        if any(p.z <= 0 for p in pts):
            continue
        xs, ys = [p.x * w for p in pts], [(1 - p.y) * h for p in pts]
        found[name] = [round(min(xs)), round(min(ys)), round(max(xs)), round(max(ys))]
    return found


def tune(args):
    """The try's numbers, from the command line: the minute's blade and dark rim, its glow and its swatch."""
    said = dict(a.split("=", 1) for a in args if "=" in a)
    strip.BLADE = float(said.get("blade", strip.BLADE))
    strip.RIM = float(said.get("rim", strip.RIM))
    strip.BRIGHT["VoidShopMinute"] = float(said.get("bright", strip.BRIGHT["VoidShopMinute"]))
    strip.MINUTE_SW = said.get("sw", strip.MINUTE_SW)
    return said.get("tag", "")


def see(out: Path, only, fast, tag=""):
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
        path = out / f"look_{name}{'_' + tag if tag else ''}.png"
        rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
        path.with_suffix(".exr").unlink(missing_ok=True)
        path.with_suffix(".json").write_text(json.dumps(boxes(scene, scene.camera)), encoding="utf-8")
        print(name, "done")
    for name in ("glyph_column.png", "glyph_row.png"):
        (out / name).unlink(missing_ok=True)


def luminance(path):
    px = rs.load(path)[..., :3]
    return px @ np.array([0.2126, 0.7152, 0.0722])          # on the picture's sRGB values, as the eye reads it


def cut(lum, box, pad=0):
    x0, y0, x1, y1 = box
    h, w = lum.shape
    return lum[max(0, y0 - pad):min(h, y1 + pad + 1), max(0, x0 - pad):min(w, x1 + pad + 1)]


def count(lum, box):
    """The clock as a count of lights, from far off. Across the clock's middle rows (clear of the roots, where a glow
    joins them, and of the points), the mean light down each column. A lit minute is a run of columns over the middle
    of that profile's range AND lighter than the open sky beside the clock: a gap that shows the sky is not a light.
    Gives the runs, the weakest run's light over the valley beside it, and the weakest run's light over the sky."""
    x0, y0, x1, y1 = box
    top, bottom = y0 + round((y1 - y0) * 0.25), y0 + max(round((y1 - y0) * 0.6), round((y1 - y0) * 0.25) + 1)
    profile = lum[top:bottom + 1, x0 - 1:x1 + 2].mean(axis=0)
    wide = max(4, (x1 - x0) // 2)
    sky = float(np.median(lum[top:bottom + 1, max(0, x0 - 4 - wide):max(1, x0 - 4)]))
    low, high = float(profile.min()), float(profile.max())
    over = profile > (low + high) / 2
    peaks, valleys, k = [], [], 0
    while k < len(over):
        if over[k]:
            start = k
            while k < len(over) and over[k]:
                k += 1
            peaks.append(float(profile[start:k].max()))
            gap = k
            while k < len(over) and not over[k]:
                k += 1
            if k < len(over):
                valleys.append(float(profile[gap:k].min()))
        else:
            k += 1
    lights = [p for p in peaks if p > sky + 0.02]
    drop = min(peaks) - max(valleys) if valleys else 0.0
    return dict(runs=len(lights), overValley=round(drop, 3), overSky=round(min(peaks) - sky, 3) if peaks else 0.0,
                sky=round(sky, 3))


def measure(out: Path, grey: Path, tags):
    rows = {"grey": lambda view: grey / f"shop_C_{view}.png"}
    rows.update({tag: (lambda view, tag=tag: out / f"look_{view}_{tag}.png") for tag in tags})
    found = {}
    for row, src in rows.items():
        geometry = {v: json.loads((out / f"look_{v}_{tags[0]}.json").read_text()) for v in ("counter", "crossing", "street_off")}
        lum = {v: luminance(src(v)) for v in geometry}
        near = {}
        for part in ("clock", "counter"):
            c = cut(lum["counter"], geometry["counter"][part])
            near[part] = dict(p99=round(float(np.percentile(c, 99)), 3), lit=round(float((c > LIT).mean()), 3),
                              litPx=int((c > LIT).sum()))
        found[row] = dict(counter=near, crossing=count(lum["crossing"], geometry["crossing"]["clock"]),
                          street=count(lum["street_off"], geometry["street_off"]["clock"]))
        print(row, json.dumps(found[row]))
    (out / "clock_measures.json").write_text(json.dumps(found, indent=1), encoding="utf-8")
    return found


def sheet(out: Path, grey: Path):
    import ui_sheet as ui

    w, h = look.SIZE
    s = 0.5
    tw, th = int(w * s), int(h * s)
    gap, left, head = 14, 150, 30
    names = [n for n in VIEWS if n != "street_off"] + ["street_close"]
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


def zoom(path, box, times, size):
    """The clock's box, centred, at `times` its pixels, cut to `size`."""
    px = rs.load(path)
    cw, ch = size[0] // times, size[1] // times
    mx, my = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
    h, w = px.shape[:2]
    x0, y0 = max(0, min(w - cw, mx - cw // 2)), max(0, min(h - ch, my - ch // 2))
    part = px[y0:y0 + ch, x0:x0 + cw]
    return np.repeat(np.repeat(part, times, axis=0), times, axis=1)


def clock_sheet(out: Path, grey: Path, tags):
    """The clock alone, as research asked for its second look: from the crossing, at 160 studs and at the counter, the
    grey and each try, with the measures under each row's name."""
    import ui_sheet as ui

    found = measure(out, grey, tags)
    w, h = look.SIZE
    s = 0.5
    tw, th = int(w * s), int(h * s)
    gap, left, head = 14, 260, 30
    geometry = {v: json.loads((out / f"look_{v}_{tags[0]}.json").read_text()) for v in ("crossing", "street_off")}
    columns = (("crossing", "from the crossing, the crown off", None),
               ("crossing", "from the crossing: the clock, each pixel x3", 3),
               ("street_off", "160 studs down the side street: the clock, each pixel x6", 6),
               ("counter", "at the counter", None))
    sources = {"grey": lambda view: grey / f"shop_C_{view}.png"}
    sources.update({tag: (lambda view, tag=tag: out / f"look_{view}_{tag}.png") for tag in tags})
    width = left + len(columns) * (tw + gap) + gap
    height = 70 + len(sources) * (th + head + gap) + 60
    ui.K = 1
    page = ui.Sheet(width, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "AR38, the Void Shop: the clock alone at 3:20 (four minutes shown), the grey and each try",
           "#EDE6D6", bold=0.2)
    y = 56
    for row, src in sources.items():
        m = found[row]
        near, far, cross = m["counter"], m["street"], m["crossing"]
        t.text(gap, y + head + 4, 16, "Grey C" if row == "grey" else row, "#EDE6D6", bold=0.3)
        lines = (f"counter: clock p99 {near['clock']['p99']:.2f}, lit {near['clock']['lit'] * 100:.0f}%",
                 f"  its own light: p99 {near['counter']['p99']:.2f}, lit {near['counter']['lit'] * 100:.0f}%",
                 f"crossing: {cross['runs']} of {SHOWN} lights, {cross['overValley']:+.2f} over the valley",
                 f"  {cross['overSky']:+.2f} over the sky",
                 f"160 studs: {far['runs']} of {SHOWN} lights, {far['overValley']:+.2f} over the valley",
                 f"  {far['overSky']:+.2f} over the sky")
        for k, line in enumerate(lines):
            t.text(gap, y + head + 30 + 19 * k, 13, line, "#B4AC9C")
        for k, (view, said, times) in enumerate(columns):
            x = left + gap + k * (tw + gap)
            t.text(x, y + 6, 13, said, "#B4AC9C")
            if times:
                rs.paste(page.px, zoom(src(view), geometry[view]["clock"], times, (tw, th)), x, y + head)
            else:
                rs.paste(page.px, rs.shrink(rs.load(src(view)), s), x, y + head)
        y += th + head + gap
    t.text(gap, page.h - 40, 13, "Measured on the pictures' sRGB luminance in the clock's and the counter's boxes, "
                                 f"projected from the camera; lit is over {LIT}. 'Lights' counts the minutes that stand "
                                 "apart across the clock AND are lighter than the open sky beside it: four should.",
           "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "clock_look.png")


def by_day():
    """The game's day as the kit wears it since AR40's pick (C, 2026-11-18, 22:40): base_light's day under C's keys,
    no mist, the kit's glow at the day's share. Without it a render keeps the look's dusk, the light the grey was
    judged in."""
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "colour"))
    import ar40_see as seen

    seen.lighting(seen.EVERY[seen.KIT])
    seen.day.light("day")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "day" in args:
        by_day()
    if "sheet" in args:
        sheet(out, Path(args[args.index("sheet") + 1]))
        return
    if "clock" in args:
        rest = args[args.index("clock") + 1:]
        clock_sheet(out, Path(rest[0]), rest[1:])
        return
    tag = tune(args)
    only = [a for a in args if a in VIEWS] or list(VIEWS)
    see(out, only, "fast" in args, tag)


if __name__ == "__main__":
    main()
