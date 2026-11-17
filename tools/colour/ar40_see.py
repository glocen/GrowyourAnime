"""AR40's block, rendered (docs/asset-requests.md, AR40): the plot from the spawn and the Strip from the crossing, by
day, from the game's camera at its start zoom, in today's colours and in each of ar40_directions.py's three.

Nothing is built here: the kit's own pieces on the plan (base_plan, strip_plan) in base_light's day, with a direction's
swatches painted into the kit's atlas for this run only, the wall's print moved along its ramp, the Strip's stones
lifted to their colour in a scratch copy, and the day's sun, fill, exposure and glow set from the direction's lighting
keys. No file of the kit's is written over.

One direction and one place a run, under the guard (each is a whole world in memory):

    guard.ps1 tools/colour/ar40_see.py <abs out> <Today|A|B|C> <base|strip> [fast]
    guard.ps1 tools/colour/ar40_see.py <abs out> sheet

Writes <out>/<key>/base_1_home.png or strip_crossing.png at the phone's shape, then <out>/ar40_plot.png,
ar40_strip.png (today's and the three, with the HUD's pieces over each) and ar40_64.png (the same at 64 px high).

The HUD over each is the game's own, cut from one of Faber's day captures (HUD_FROM) and pasted where it sits: its
pieces are slanted, so a sliver of that capture's sky shows at their corners. It's there to read the HUD's values over
each world, not its edges.
"""
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "blender"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar40_directions as data  # noqa: E402
import base_light as day  # noqa: E402

splan, block = day.splan, day.block
plan, base, look, kit, bl = day.plan, day.base, day.look, day.kit, day.bl
rs = plan.rs

SIZE = (960, 438)     # the phone's shape (Faber's captures are 1920 by 876); the camera keeps its height's angle
VIEWS = {"base": ("base_1_home.png", "the plot from the spawn"), "strip": ("strip_crossing.png", "the Strip from the crossing")}
HUD_FROM = ROOT / "build" / "scratch" / "faber" / "stills" / "ar20-start-day.jpg"   # 1920 by 876, by day
# The HUD's pieces in that capture: left, top, right, bottom
HUD_PIECES = {"the lead's card": (8, 112, 322, 270), "the pills": (1688, 95, 1908, 214), "the dock": (792, 742, 1128, 862)}
EVERY = {"Today": data.TODAY, **{d["Key"]: d for d in data.DIRECTIONS}}


def wear(d, out: Path):
    """A direction's colours over the kit's, for this run."""
    for name, (head, foot) in d["Swatches"].items():
        base.SWATCHES[name] = (head, foot, base.SWATCHES[name][2])
    lo0, hi0 = (kit.code(c) for c in data.TODAY["Panel"])
    lo1, hi1 = (kit.code(c) for c in d["Panel"])
    paint = base.atlas

    def atlas():
        page, glow = paint()
        x, y, w, h = base.PRINTS["panel"]
        cut = page[y:y + h, x:x + w, :3]
        page[y:y + h, x:x + w, :3] = np.clip(lo1 + (cut - lo0) / (hi0 - lo0) * (hi1 - lo1), 0, 1)
        return page, glow
    base.atlas = atlas
    # the stones: the Strip's own tile, its light times the direction's gain, in a scratch copy
    page = rs.load(plan.STREET)
    c = page[..., :3]
    lit = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4) * np.array(data.gain(d["Stones"]), np.float32)
    page[..., :3] = kit.encode(np.clip(lit, 0, 1))
    path = out / "stones" / plan.STREET.name
    path.parent.mkdir(parents=True, exist_ok=True)
    rs.save(page, path)
    plan.STREET = path
    # the day's light: the sun's colour and strength, the fill, the exposure, the kit's glow by day
    keys = d["Lighting"]
    az, el, _, _, shadow = day.DAY["sun"]
    day.DAY["sun"] = (az, el, keys["Phases.Day.Sun"], keys["Clear.Phases.Day.Brightness"] / 3, shadow)
    day.C["day"] = dict(ambient=(keys["Clear.Phases.Day.Ambient"], 1.0), exposure=2 ** keys["Clear.Phases.Day.Exposure"])
    day.SHARES["day"]["glow"] = keys["Phases.Day.Glow"]


def see(out: Path, key, where, fast):
    folder = out / key
    folder.mkdir(parents=True, exist_ok=True)
    if key != "Today":
        wear(EVERY[key], folder)
    look.SIZE = SIZE
    day.light("day")
    if where == "base":
        plan.see(folder, 1, fast, False, ["home"])
    else:
        base.write_pictures(folder / "maps")
        block.BASE_MAPS = folder / "maps"
        splan.see(folder, ["crossing"], fast)
    print(f"AR40: {key} {where} done")


def hud(page):
    """The game's HUD over a render: its pieces from a day capture, at the render's scale."""
    shot = rs.load(HUD_FROM)
    scale = page.shape[1] / shot.shape[1]
    for left, top, right, bottom in HUD_PIECES.values():
        piece = shot[top:bottom, left:right].copy()
        piece[..., 3] = 1.0
        rs.paste(page, rs.shrink(piece, scale), round(left * scale), round(top * scale))
    return page


def sheet(out: Path):
    rs.OUT = out
    w, h = SIZE
    pad, head = 12, 30
    names = ["Today"] + [d["Key"] for d in data.DIRECTIONS]
    titles = {"Today": "Today"} | {d["Key"]: d["Name"] for d in data.DIRECTIONS}
    small = []
    for where, (file, what) in VIEWS.items():
        got = [k for k in names if (out / k / file).exists()]
        if not got:
            continue
        board = rs.canvas(2 * w + 3 * pad, 2 * (h + head) + pad, (0.93, 0.93, 0.94))
        words = []
        for i, k in enumerate(got):
            x, y = pad + (i % 2) * (w + pad), (i // 2) * (h + head) + head
            page = hud(rs.load(out / k / file))
            page[..., 3] = 1.0
            rs.paste(board, page, x, y)
            words.append((x, y - 22, 15, f"{titles[k]}: {what}, by day", "#16182A"))
            small.append((k, where, rs.shrink(page, 64 / h)))
        rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
        rs.save(board, out / f"ar40_{'plot' if where == 'base' else 'strip'}.png")
    if small:
        tw = small[0][2].shape[1]
        board = rs.canvas(len(names) * (tw + pad) + pad, 2 * (64 + pad) + pad, (0.93, 0.93, 0.94))
        for k, where, tile in small:
            rs.paste(board, tile, pad + names.index(k) * (tw + pad), pad + (where == "strip") * (64 + pad))
        rs.save(board, out / "ar40_64.png")
    print("AR40: sheets done")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args[0] == "sheet":
        sheet(out)
    else:
        see(out, args[0], args[1], "fast" in args)


if __name__ == "__main__":
    main()
