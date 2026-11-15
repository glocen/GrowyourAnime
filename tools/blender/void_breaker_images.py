"""The galaxy Breaker's sky as images for the build (AR12, delivery 3; the look is the director's accepted one,
2026-11-15: "ok we keep it good job"). The sky is void_sky.py's own, cut into the flat layers the game stacks:

    images/BreakerSkyLeft.png, BreakerSkyRight.png  the still night in the panel's shape, in two halves that lap in the
                                                    gap between the fourth chamber and the chosen shard's panel
    images/BreakerMist.png         the mist's lumps, white, one turn of the panel's width: slid along each window, tinted
    images/BreakerStar.png         a large star, white: tinted and breathing, six times
    images/BreakerFallingStar.png  the falling star at its brightest, at its path's angle
    images/BreakerLight.png        the soft light behind a shard, white: lavender while it works, gold when it's broken
    breaker_sky.json               where each lies, how it moves, each window's tint and how the mist lies down it
    breaker_sky_images.png         the images stacked by the json's own numbers beside the accepted sky, then each alone

Every place and size is in points from the panel's corner (void_sky.PANEL: 684 by 306 on the 812 by 375 screen).

    blender -b --factory-startup --python tools/blender/void_breaker_images.py -- build/handoff/UI/breaker

Workbench only, and only for the sheet's words.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import reveal_art as ra  # noqa: E402
import reveal_blockin as rb  # noqa: E402
import rook_sheet as rs  # noqa: E402
import screens_vivid_sheet as sv  # noqa: E402
import ui_kit as kit  # noqa: E402
import ui_sheet as ui  # noqa: E402
import void_breaker_motion as vm  # noqa: E402
import void_sky as vs  # noqa: E402
from ui_sheet import c  # noqa: E402

LOOK = vs.BREAKER
PW, PH = vs.PANEL[2:]
K_SKY = 43.0 / 18.0  # pixels a point in the night: the most that keeps its left half within 1024 and its sizes whole
LEFT, RIGHT = 1024, 1006  # the left half's width in pixels, and where the right half starts: they lap by 18
K_MIST = 1024.0 / PW  # the mist is soft: one turn of the panel's width in 1024 pixels
K_SMALL = 8  # the star and the falling star
# The four chambers' windows, between a chamber's name strip and its plate (screens_vivid_sheet.chamber).
WINDOWS = [(14.0 + 103.0 * i, 60.0 + 144.0 * sv.HEAD, 96.0, 144.0 * (sv.SPLIT - sv.HEAD)) for i in range(4)]
STAR = 24.0  # a star's image, in points, for a star of size 1.5: sixteen times its size
FALL = dict(points=(28.0, 24.0), head=(4.0, 20.0))  # the falling star's image, and where its head is in it
LIGHT = 256  # the light's image, in pixels: four times its radius across
SHOWN = 3.75  # the moment the sheet stacks: the falling star is halfway


def hexed(rgb):
    return "#" + "".join(f"{round(float(v) * 255):02X}" for v in rgb)


def resize(px, rows, cols):
    """Bilinear, on premultiplied colour: for a picture drawn larger than it was made."""
    pm = px.astype(np.float32).copy()
    pm[..., :3] *= pm[..., 3:]
    ys = np.clip((np.arange(rows) + 0.5) * px.shape[0] / rows - 0.5, 0, px.shape[0] - 1)
    xs = np.clip((np.arange(cols) + 0.5) * px.shape[1] / cols - 0.5, 0, px.shape[1] - 1)
    y0, x0 = np.floor(ys).astype(int), np.floor(xs).astype(int)
    y1, x1 = np.minimum(y0 + 1, px.shape[0] - 1), np.minimum(x0 + 1, px.shape[1] - 1)
    fy, fx = (ys - y0)[:, None, None], (xs - x0)[None, :, None]
    out = (pm[y0][:, x0] * (1 - fx) + pm[y0][:, x1] * fx) * (1 - fy) + (pm[y1][:, x0] * (1 - fx) + pm[y1][:, x1] * fx) * fy
    out[..., :3] = np.where(out[..., 3:] > 1e-6, out[..., :3] / np.maximum(out[..., 3:], 1e-6), 0)
    return out


# --- the images -------------------------------------------------------------------------------------------------------

def night():
    """The still night in the panel's shape, at K_SKY: painted at twice that and brought down, so its smallest stars
    keep their light."""
    rows, cols = round(PH * K_SKY), round(PW * K_SKY)
    big = np.ones((rows * 2, cols * 2, 4), np.float32)
    big[..., :3] = vs.ground(rows * 2, cols * 2, K_SKY * 2, LOOK)
    px = rs.shrink(big, 0.5)
    del big
    ui.K = kit.K
    kit.panels()
    fill = kit.IMAGES["PanelFill"]
    shape = kit.stretch(fill["px"], fill["cut"], PW, PH)[..., 3:]
    px[..., 3:] = rs.shrink(np.repeat(shape, 4, axis=-1), K_SKY / kit.K)[..., 3:]
    return px


def mist_tile():
    """The mist's lumps over its band, white, covering at most LOOK["mist"]. Where it lies and its colour are the
    window's (ramps, tints): they stay still while this slides."""
    top, foot = LOOK["band"]
    y0, y1 = int(top * K_MIST), int(foot * K_MIST) + 1
    n = vs.lumps(y0, y1, 1024, K_MIST)[0]
    px = np.ones((y1 - y0, 1024, 4), np.float32)
    px[..., 3] = n * LOOK["mist"]
    return px, y0 / K_MIST, (y1 - y0) / K_MIST


def ramps(top, tall):
    """How much of the mist shows down its image, for each window: (share of the image's height, cover) keys. Between
    two keys it runs straight, as a gradient does."""
    first, last = ((WINDOWS[0][1] + d - top) / tall for d in (0.0, WINDOWS[0][3]))
    shares = [0.0] + [float(v) for v in np.linspace(first, last, 9)] + [1.0]
    out = []
    for x, _, w, _ in WINDOWS:
        xp, yp = np.meshgrid(np.linspace(x + 1, x + w - 1, 24), [top + s * tall for s in shares])
        out.append([(round(s, 4), round(float(v), 3)) for s, v in zip(shares, vs.held(LOOK, xp, yp).mean(axis=1))])
    return out


def tints():
    """Each window's colour of the river, at its middle."""
    return [hexed(vs.ramp(np.clip(vs.along(LOOK, np.float32(x + w / 2), np.float32(y + hh / 2))[0], 0, 1), LOOK["palette"]))
            for x, y, w, hh in WINDOWS]


def band(top, tall):
    """The mist as one band along the row of chambers, gaps included (research, 2026-11-15): where it lies, the
    river's colours across it, and how much shows down the mist's image, as the windows' ramps give it for one."""
    x0, x1 = WINDOWS[0][0], WINDOWS[-1][0] + WINDOWS[-1][2]
    y, tall_w = WINDOWS[0][1], WINDOWS[0][3]
    across = [float(v) for v in np.linspace(0.0, 1.0, 9)]
    xs = np.array([x0 + s * (x1 - x0) for s in across], np.float32)
    s_river = np.clip(vs.along(LOOK, xs, np.full_like(xs, y + tall_w / 2))[0], 0, 1)
    tint = [[round(s, 4), hexed(col)] for s, col in zip(across, vs.ramp(s_river, LOOK["palette"]))]
    first, last = ((y + d - top) / tall for d in (0.0, tall_w))
    shares = [0.0] + [float(v) for v in np.linspace(first, last, 9)] + [1.0]
    xp, yp = np.meshgrid(np.linspace(x0, x1, 96), [top + s * tall for s in shares])
    down = [(round(s, 4), round(float(v), 3)) for s, v in zip(shares, vs.held(LOOK, xp, yp).mean(axis=1))]
    return dict(at=[x0, round(y, 2)], points=[x1 - x0, round(tall_w, 2)], tint=tint, down=down)


def star():
    side = round(STAR * K_SMALL)
    return vs.glints(side, side, K_SMALL, ((STAR / 2, STAR / 2, STAR / 16, "#FFFFFF", 1.0, 0.25),))  # at its full light


def falling():
    (ax, ay), (bx, by) = LOOK["streak"]
    half = ((bx - ax) / 2, (by - ay) / 2)
    hx, hy = FALL["head"]
    rows, cols = round(FALL["points"][1] * K_SMALL), round(FALL["points"][0] * K_SMALL)
    return vs.streak(rows, cols, K_SMALL, (hx - half[0], hy - half[1]), (hx + half[0], hy + half[1]), 0.5)


def light():
    """screens_vivid_sheet.light at its full strength, white."""
    r = LIGHT / 4
    y, x = np.mgrid[0:LIGHT, 0:LIGHT].astype(np.float32) + 0.5
    d = np.hypot(x - 2 * r, y - 2 * r)
    px = np.ones((LIGHT, LIGHT, 4), np.float32)
    px[..., 3] = np.exp(-(np.maximum(d - r * 0.3, 0) / (r * 0.7)) ** 1.4) * np.clip((2 * r - d) / (0.8 * r), 0, 1)
    return px


# --- the json ---------------------------------------------------------------------------------------------------------

def manifest(out, images, top, tall, keys, colours):
    (ax, ay), (bx, by) = LOOK["streak"]
    accent = sv.GALAXY["accent"]
    data = dict(
        note="The galaxy Breaker's sky (AR12, delivery 3). Every place and size is in points from the panel's corner; "
             "the panel is 684 by 306 on the 812 by 375 screen, and the night carries the panel's own shape, so it fits "
             "that size. Layers from the back: the night, the mist (see `mist`), the stars, the falling star, then a "
             "chamber's glass, its light and its shard, and every plate. With reduced motion on, nothing moves and the "
             "falling star never falls. DESIGN, untried in Studio.",
        images={name: dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]]) for name, px in images.items()},
        night=dict(
            pixelsPerPoint=round(K_SKY, 4),
            left=dict(image="BreakerSkyLeft", at=[0, 0], points=[round(LEFT / K_SKY, 3), PH]),
            right=dict(image="BreakerSkyRight", at=[round(RIGHT / K_SKY, 3), 0], points=[round(PW - RIGHT / K_SKY, 3), PH]),
            note="two halves of one picture. They lap by 7.5 points, between the fourth chamber and the chosen shard's "
                 "panel, and show the same sky there, so either may lie on top. The panel's own fill stays under them."),
        mist=dict(
            image="BreakerMist", at=[0, round(top, 3)], points=[PW, round(tall, 3)], turn=PW, drift=LOOK["drift"],
            note="white, tinted. Placed as if it lay on the panel at `at`; it slides left `drift` points a second and "
                 "comes round every `turn` points, so two copies side by side cover the turn. Two ways to show it. "
                 "`band`, tried first (research, 2026-11-15): one band along the row of chambers, behind them, gaps "
                 "included; the copies slide inside a group that holds still and carries `band.tint` as one gradient "
                 "from left to right, so the colour stays put while the lumps move. `windows`, the fallback: each "
                 "window clips its own copy in that window's one `tint`. In both, `down` is the cover down the image's "
                 "height (share of the height, cover): a gradient from top to foot, which sliding sideways never "
                 "changes.",
            band=band(top, tall),
            windows=[dict(chamber=i + 1, at=[x, round(y, 2)], points=[w, round(hh, 2)], tint=colours[i], down=keys[i])
                     for i, (x, y, w, hh) in enumerate(WINDOWS)]),
        stars=dict(
            image="BreakerStar", sideForSize=16,
            note="white, tinted. A star's image is `sideForSize` times its size across, its middle on the star. Its "
                 "light is 0.775 + 0.225 * sin(2 pi * (t / seconds + start)): the image's transparency is 1 less that.",
            each=[dict(at=[x, y], size=size, tint=colour, seconds=period, start=phase)
                  for x, y, size, colour, period, phase in LOOK["glints"]]),
        fallingStar=dict(
            image="BreakerFallingStar", points=list(FALL["points"]), head=list(FALL["head"]),
            start=[ax, ay], end=[bx, by], seconds=vm.FALLS, clip="chamber 4's window, under its glass",
            note="the image's `head` runs from `start` to `end` in `seconds`, at an even speed; its light is "
                 "sin(pi * s) ^ 0.6, s from 0 to 1. Pale, never tinted. The first falls `first` seconds after the "
                 "screen opens, then one every `every` seconds, each drawn at random between the two (research, "
                 "2026-11-15: seeds, tuned in play).",
            first=[3, 6], every=[15, 30]),
        light=dict(
            image="BreakerLight", sideForRadius=4,
            note="white, tinted. The image is `sideForRadius` times the light's radius across, its middle 58 points "
                 "under the chamber's top, behind the shard. `cover` is 1 less its transparency.",
            working=dict(tint=vm.LAVENDER, radius=27, cover=0.36, breath=dict(seconds=vm.BREATH, swell=vm.SWELL),
                         breathNote="the cover swells and falls by `swell` round its rest, once in `seconds`"),
            ready=[dict(tint=sv.EMBER, radius=36, cover=0.42), dict(tint=accent, radius=22, cover=0.5),
                   dict(tint=sv.h.PALE[accent], radius=13, cover=0.7)]),
        glass=dict(
            colour=sv.GLASS, nameStrip=round(sv.HEAD, 4), plate=round(sv.SPLIT, 4), window=0.1, lockedWindow=0.13,
            note="no image: a chamber's fill in `colour`, solid over its name strip (to `nameStrip` of its height) and "
                 "its plate (from `plate`), and covering `window` of the sky between them, over 0.04 of the height "
                 "under the strip and 0.06 above the plate."))
    (out / "breaker_sky.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print("wrote", out / "breaker_sky.json")


# --- the sheet --------------------------------------------------------------------------------------------------------

def stacked(images, top, tall, keys, colours, t, k=2):
    """The sky at `t` seconds, laid from the delivered images by the json's numbers, k pixels a point."""
    rows, cols = round(PH * k), round(PW * k)
    px = np.empty((rows, cols, 4), np.float32)
    px[..., :3], px[..., 3] = c(ra.SHEET_GROUND), 1.0
    rs.paste(px, rs.shrink(images["BreakerSkyLeft"], k / K_SKY), 0, 0)
    rs.paste(px, rs.shrink(images["BreakerSkyRight"], k / K_SKY), round(RIGHT / K_SKY * k), 0)
    slid = np.roll(images["BreakerMist"], -round(LOOK["drift"] * t * K_MIST), axis=1)
    big = resize(slid, round(tall * k), cols)
    for (x, y, w, hh), colour, key in zip(WINDOWS, colours, keys):
        x0, y0, x1, y1 = round(x * k), round(y * k), round((x + w) * k), round((y + hh) * k)
        r0 = y0 - round(top * k)
        part = big[r0:r0 + y1 - y0, x0:x1].copy()
        share = (np.arange(r0, r0 + y1 - y0) + 0.5) / big.shape[0]
        part[..., :3] = vs.rgb(colour)
        part[..., 3] *= np.interp(share, [s for s, _ in key], [v for _, v in key]).astype(np.float32)[:, None]
        rs.paste(px, part, x0, y0)
    for x, y, size, colour, period, phase in LOOK["glints"]:
        one = rs.shrink(images["BreakerStar"], 16 * size * k / images["BreakerStar"].shape[1])
        one[..., :3] = vs.rgb(colour)
        one[..., 3] *= 0.775 + 0.225 * math.sin(2 * math.pi * (t / period + phase))
        rs.paste(px, one, round(x * k - one.shape[1] / 2), round(y * k - one.shape[0] / 2))
    s = (t - vm.FALL) / vm.FALLS
    if 0.0 <= s <= 1.0:
        (ax, ay), (bx, by) = LOOK["streak"]
        x, y, w, hh = WINDOWS[3]
        x0, y0 = round(x * k), round(y * k)
        one = rs.shrink(images["BreakerFallingStar"], k / K_SMALL)
        one[..., 3] *= math.sin(math.pi * s) ** 0.6
        rs.paste(px[y0:round((y + hh) * k), x0:round((x + w) * k)], one,
                 round((ax + (bx - ax) * s - FALL["head"][0]) * k) - x0, round((ay + (by - ay) * s - FALL["head"][1]) * k) - y0)
    return px


def accepted(t, k=2):
    """The same moment from void_sky.py, as the accepted sheets and the clip drew it."""
    rows, cols = round(PH * k), round(PW * k)
    px = vs.sky(k, t)
    s = (t - vm.FALL) / vm.FALLS
    if 0.0 <= s <= 1.0:
        vs.lay(px, vs.streak(rows, cols, k, *LOOK["streak"], s))
    return np.dstack([px, np.ones((rows, cols, 1), np.float32)])


def framed(px, k=2):
    """A chamber's solid parts over a sky, its name strip and its plate, so its window reads as one."""
    for x, y, w, hh in WINDOWS:
        x0, x1 = round(x * k), round((x + w) * k)
        px[round(60.0 * k):round(y * k), x0:x1, :3] = c(sv.GLASS)
        px[round((y + hh) * k):round(204.0 * k), x0:x1, :3] = c(sv.GLASS)
    return px


def over_dark(px, ground="#05040E"):
    out = np.empty(px.shape, np.float32)
    out[..., :3], out[..., 3] = c(ground), 1.0
    rs.paste(out, px, 0, 0)
    return out


def sheet(out, images, top, tall, keys, colours):
    ui.K = 2
    sh = ui.Sheet(1420, 960, ra.SHEET_GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: the galaxy Breaker's sky as images for the build (AR12, delivery 3)", ra.INK)
    t.text(20, 36, 9.5, "The accepted sky, cut into the flat layers the game stacks: the still night in two halves, the mist's "
           "lumps, a star, the falling star, a shard's light. Places, tints and timings are in breaker_sky.json.", ra.SOFT_INK)
    y = 62.0
    mine, theirs = framed(stacked(images, top, tall, keys, colours, SHOWN)), framed(accepted(SHOWN))
    for x, px, label in ((20.0, mine, f"Stacked from the images by the json's numbers, at {SHOWN} s: the mist shows in the four windows only. Each chamber's strip and plate are blocked in"),
                         (716.0, theirs, f"The accepted sky at {SHOWN} s (void_sky.py): the mist lies along the whole row, the gaps included")):
        rs.paste(sh.px, px, round(x * ui.K), round(y * ui.K))
        t.text(x, y + PH + 6, 9, label, ra.SOFT_INK)
    apart = []
    for wx, wy, ww, wh in WINDOWS:
        a = mine[round(wy * 2):round((wy + wh) * 2), round(wx * 2):round((wx + ww) * 2), :3]
        b = theirs[round(wy * 2):round((wy + wh) * 2), round(wx * 2):round((wx + ww) * 2), :3]
        apart.append(float(np.abs(a - b).mean()) * 255)
    print("apart in each window, of 255:", [round(v, 2) for v in apart])
    t.text(20, y + PH + 20, 9, "The two differ in each window by " + ", ".join(f"{v:.1f}" for v in apart) + " of 255 on average "
           "(a window's mist takes one tint and one fall-off down its height; the night under it is softer at 2.4 pixels a point).",
           ra.SOFT_INK)

    # each image alone, over dark
    y = 420.0
    t.text(20, y, 10, "Each image alone, a pixel of it to a pixel of this sheet, over dark. The night's two halves lap by 18 "
           "pixels; its cut corners are the panel's.", ra.SOFT_INK)
    y += 18
    x = 20.0
    for name in ("BreakerSkyLeft", "BreakerSkyRight"):
        px = images[name]
        rs.paste(sh.px, over_dark(px, "#3A3550"), round(x * ui.K), round(y * ui.K))
        t.text(x, y + px.shape[0] / 2 + 4, 8.5, f"{name}, {px.shape[1]} by {px.shape[0]}", ra.SOFT_INK)
        x += px.shape[1] / 2 + 12
    x += 8
    side = y
    for name in ("BreakerMist", "BreakerStar", "BreakerFallingStar", "BreakerLight"):
        px = images[name]
        rs.paste(sh.px, over_dark(px), round(x * ui.K), round(side * ui.K))
        t.text(x, side + px.shape[0] / 2 + 4, 8.5, f"{name}, {px.shape[1]} by {px.shape[0]}", ra.SOFT_INK)
        side += px.shape[0] / 2 + 24
        if name == "BreakerMist":  # the three small ones stand in a row under the mist
            row = side
        elif name != "BreakerLight":
            x, side = x + px.shape[1] / 2 + 16, row
    # each at 64 pixels across, over dark
    y += 731 / 2 + 26
    t.text(20, y, 10, "Each at 64 pixels across, over dark, shown at twice that:", ra.SOFT_INK)
    x = 20.0
    for name, px in images.items():
        small = over_dark(rs.shrink(px, 64.0 / px.shape[1]))
        rs.paste(sh.px, resize(small, small.shape[0] * 2, 128), round(x * ui.K), round((y + 18) * ui.K))
        t.text(x, y + 22 + small.shape[0], 8.5, name, ra.SOFT_INK)
        x += 110
    rb.finish(sh, out / "breaker_sky_images.png")


def main():
    out = bl.out_dir()
    (out / "images").mkdir(exist_ok=True)
    whole = night()
    tile, top, tall = mist_tile()
    images = {"BreakerSkyLeft": whole[:, :LEFT].copy(), "BreakerSkyRight": whole[:, RIGHT:].copy(), "BreakerMist": tile,
              "BreakerStar": star(), "BreakerFallingStar": falling(), "BreakerLight": light()}
    for name, px in images.items():
        kit.bleed(px)
        rs.save(px, out / "images" / f"{name}.png")
    keys, colours = ramps(top, tall), tints()
    manifest(out, images, top, tall, keys, colours)
    sheet(out, images, top, tall, keys, colours)


if __name__ == "__main__":
    main()
