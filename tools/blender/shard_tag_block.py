"""Where a shard came from: the festival tag, as a block (AR12, "Where a shard came from: the festival tag"; research's
design of 2026-11-15 on the director's "it need to be more intuitive to know where it came from").

A small paper tag hangs from the shard's shoulder by a short thread, a quarter of the shard's height, in its ground's
two colours with the ground's mark. The crystal isn't touched: the pictures are the shard grades' own
(build/handoff/UI/shards/, shard_grade_art.py), and the tag is laid beside them.

The block: Lantern Row's tag (a lantern, cyan and warm white) and Drum Court's (a drum, red) on the three grades at
each size, on the Breaker's dark and a dusk street; a chamber as today beside one with the tag and the two-line name.
At 96 and 50 points the shard carries its tag; at 40 only the tag's mark, at the shard's foot; the 26-point chip has a
band of the ground's colour along its foot.

The block passed research's verdict (2026-11-15), and its drawing is the build's: shard_tag_images.py writes the tag's
images from `tag` and `token`. Workbench only, and only for the sheet's words.

    blender -b --factory-startup --python tools/blender/shard_tag_block.py -- build/handoff/UI/shards/tag

Writes the sheet shard_tag_block.png.
"""
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import reveal_art as ra  # noqa: E402
import reveal_blockin as rb  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

SHARDS = Path(__file__).resolve().parents[2] / "build" / "handoff" / "UI" / "shards"
GRADES = ("Standard", "Enriched", "Prismatic")
BODY = 736.0  # the body's height in a grade's 1024-pixel picture (shard_grade_art.BODY_TALL)
GROUND, INK, SOFT_INK = ra.SHEET_GROUND, ra.INK, ra.SOFT_INK
ROOM, DUSK = rb.GROUNDS[0][1], rb.GROUNDS[1][1]
KEY = "#0B0820"  # the dark line round a tag, the small shard's own

# A ground's two colours and its mark. Lantern Row's and Drum Court's first colours are the roster's words; Drum
# Court has one colour there, so its second, a drumskin's cream, is this block's.
FESTIVALS = {
    "Lantern Row": dict(body="#35CFEA", second="#FFF1D8", mark="lantern"),
    "Drum Court": dict(body="#DD3A32", second="#FFE7C6", mark="drum"),
}
DRAWN = 16  # pixels a point the tag is drawn at, before it's brought down to a size
TILT = math.radians(9.0)  # how far it hangs off the upright
SHOULDER = (0.19, -0.29)  # where the thread is tied, from the picture's middle, in body heights
SHARE = 0.25  # the tag's height against the shard's
TAG, TIE = (24.0, 36.0), (15.0, 2.0)  # the tag's drawing in points, and where its thread is tied in it: hanging off the
# upright, its foot swings left of its tie


def ellipse(u, v, cx, cy, a, b):
    return (np.sqrt(((u - cx) / a) ** 2 + ((v - cy) / b) ** 2) - 1) * min(a, b)


def box(u, v, x0, y0, x1, y1):
    return np.maximum(np.maximum(x0 - u, u - x1), np.maximum(y0 - v, v - y1))


def mark(kind, u, v):
    """A ground's mark as one silhouette, about ten units high, its middle at 0, 0. The distance from its outline."""
    if kind == "lantern":  # a paper lantern: its round body, a cap at each end, a tassel
        return np.minimum.reduce([ellipse(u, v, 0, -0.3, 3.7, 3.6), box(u, v, -1.9, -4.9, 1.9, -3.5),
                                  box(u, v, -1.9, 2.9, 1.9, 3.9), box(u, v, -0.45, 3.9, 0.45, 5.4)])
    # a drum: its barrel, wider at its waist, and two sticks held over it. The sticks stand apart: crossed on red,
    # they read as a cancel mark.
    barrel = ui.sd_polygon(u, v, [(-4.2, -1.6), (4.2, -1.6), (4.8, 1.2), (4.2, 4.6), (-4.2, 4.6), (-4.8, 1.2)])
    sticks = np.minimum(ui.sd_segment(u, v, (-4.2, -5.0), (-1.1, -2.5)), ui.sd_segment(u, v, (4.2, -5.0), (1.1, -2.5))) - 0.55
    heads = np.minimum(ellipse(u, v, -4.2, -5.0, 1.0, 1.0), ellipse(u, v, 4.2, -5.0, 1.0, 1.0))
    return np.minimum.reduce([barrel, sticks, heads])


def cuts(kind, u, v):
    """What's cut back out of a mark in the tag's colour, so it reads as the thing: the lantern's ribs, the drum's rims."""
    if kind == "lantern":
        return np.minimum(box(u, v, -4, -1.75, 4, -1.25), box(u, v, -4, 0.65, 4, 1.15))
    return np.minimum(box(u, v, -5, -0.5, 5, 0.1), box(u, v, -5, 3.0, 5, 3.6))


def tag(name):
    """A ground's tag with its thread, drawn large: the pixels, and where its thread is tied, in points at 96."""
    ui.K = DRAWN
    f = FESTIVALS[name]
    sheet = ui.Sheet(*TAG, "#000000")
    sheet.px[:] = 0
    t = sheet.tile(0, 0, *TAG)
    tie = TIE
    x, y = t.x - tie[0], t.y - tie[1]
    u, v = math.cos(TILT) * x + math.sin(TILT) * y, -math.sin(TILT) * x + math.cos(TILT) * y  # the tag's own upright
    plaque = ui.sd_polygon(u, v, [(-4.5, 5), (4.5, 5), (8.5, 9), (8.5, 29), (-8.5, 29), (-8.5, 9)])
    thread = ui.sd_segment(u, v, (0, 0), (0, 8)) - 0.45
    t.paint(np.minimum(plaque, thread) - 1.0, c(KEY))
    t.paint(thread, c("#E9DCC0"))
    t.paint(plaque, t.ramp(f["body"], c(f["body"]) * 0.82, (v - 5) / 24))
    t.paint(np.maximum(plaque, 25.4 - v), c(f["second"]))
    m = mark(f["mark"], (u - 0) / 1.25, (v - 16.4) / 1.25) * 1.25
    t.paint(m, c(f["second"]))
    t.paint(np.maximum(m + 0.2, cuts(f["mark"], u / 1.25, (v - 16.4) / 1.25) * 1.25), c(f["body"]))
    t.paint(ellipse(u, v, 0, 8.0, 1.25, 1.25), c(KEY))
    return sheet.px, tie


def token(name):
    """The tag's mark alone, on a disc of the ground's colour: for 40 points, at the shard's foot."""
    ui.K = DRAWN
    f = FESTIVALS[name]
    sheet = ui.Sheet(16.0, 16.0, "#000000")
    sheet.px[:] = 0
    t = sheet.tile(0, 0, 16.0, 16.0)
    u, v = t.x - 8, t.y - 8
    disc = ellipse(u, v, 0, 0, 6.6, 6.6)
    t.paint(disc - 1.0, c(KEY))
    t.paint(disc, c(f["body"]))
    m = mark(f["mark"], u / 0.95, v / 0.95) * 0.95
    t.paint(m, c(f["second"]))
    t.paint(np.maximum(m + 0.2, cuts(f["mark"], u / 0.95, v / 0.95) * 0.95), c(f["body"]))
    return sheet.px


def sized(px, tall, small=False):
    """A grade's picture with its body `tall` points high on the sheet."""
    return rs.shrink(px, tall * ui.K / (BODY / 4 if small else BODY))


def put(sh, px, cx, cy):
    rs.paste(sh.px, px, round(cx * ui.K - px.shape[1] / 2), round(cy * ui.K - px.shape[0] / 2))


def tagged(sh, shard, piece, cx, cy, tall, share=SHARE):
    """A shard, its body `tall` points high with its middle at cx, cy, and its ground's tag hung from its shoulder."""
    put(sh, sized(shard, tall), cx, cy)
    if piece is None:
        return
    px, tie = piece
    scale = tall * share / 24.0  # the plaque is 24 points high as drawn
    little = rs.shrink(px, scale * ui.K / DRAWN)
    x, y = cx + SHOULDER[0] * tall - tie[0] * scale, cy + SHOULDER[1] * tall - tie[1] * scale
    rs.paste(sh.px, little, round(x * ui.K), round(y * ui.K))


def marked(sh, shard, disc, cx, cy, tall=40.0):
    """The small shard with the tag's mark at its foot."""
    put(sh, sized(shard, tall, small=True), cx, cy)
    if disc is not None:
        put(sh, rs.shrink(disc, 13.0 / 13.2 * ui.K / DRAWN), cx + 0.3 * tall, cy + 0.36 * tall)


def chip(sh, shard, name, x, y, size=26.0):
    """A 26-point chip: the small shard, and a band of the ground's colour along its foot."""
    tile = sh.tile(x, y, size, size)
    edge = tile.poly(ui.cut_box(0, 0, size, size, 5, 0, 5, 0))
    tile.paint(edge, tile.ramp("#221B40", "#120E26", tile.y / size))
    if name:
        tile.paint(np.maximum(edge, size - 3.6 - tile.y), c(FESTIVALS[name]["body"]))
    tile.line(edge, 1.0, c("#4A3F78"))
    put(sh, sized(shard, 18.0, small=True), x + size / 2, y + size / 2 - (1.4 if name else 0))


def chamber(sh, t, shard, piece, x, y, index, lines, time):
    """A chamber's window as a sketch (the shard grades' sheet's own), with the name on its plate."""
    cw, ch = 160.0, 160.0 + (12 if len(lines) > 1 else 0)
    tile = sh.tile(x, y, cw, ch)
    edge = tile.poly(ui.cut_box(0, 0, cw, ch, 10, 0, 10, 0))
    tile.paint(edge, tile.ramp("#1A1533", "#0D0A1C", tile.y / ch))
    tile.glow(tile.poly([(cw / 2, 66), (cw / 2 + 1, 66), (cw / 2 + 1, 67)]), 44.0, c("#3B2C7A"), 0.75)
    tile.paint(np.maximum(edge, 118 - tile.y), c("#201A3A"))
    tile.line(edge, 1.2, c("#4A3F78"))
    tagged(sh, shard, piece, x + cw / 2, y + 66, 96.0)
    t.text(x + 9, y + 7, 8.5, f"Chamber {index}", "#B9B2D6")
    ty = y + 125
    if len(lines) > 1:
        t.text(x + cw / 2, ty, 8.5, lines[0], "#B9B2D6", "CENTER")
        ty += 13
    t.text(x + cw / 2, ty, 11, lines[-1], INK, "CENTER")
    t.text(x + cw / 2, ty + 17, 8.5, time, "#FFE9A6", "CENTER")
    return cw


def sheet(out, big, small, tags, discs):
    ui.K = 2
    sh = ui.Sheet(1180, 1016, GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: where a shard came from, the festival tag: a block (AR12)", INK)
    t.text(20, 36, 9.5, "Research's design on the director's word, 2026-11-15: \"it need to be more intuitive to know where it "
           "came from\". A paper tag in the ground's two colours with its mark, hung from the shard's shoulder, a quarter "
           "of its height. The crystal isn't touched.", SOFT_INK)
    t.text(20, 50, 9.5, "A block: Lantern Row (a lantern, cyan and warm white) and Drum Court (a drum, red) only. At 96 and 50 "
           "points the shard carries its tag; at 40 the tag's mark sits at its foot; a 26-point chip has the colour along "
           "its foot.", SOFT_INK)

    # The tags, large, and each on a Prismatic.
    y, th = 72.0, 250.0
    tile = sh.tile(20, y, 1140, th)
    tile.paint(tile.poly(ui.cut_box(0, 0, 1140, th)), c(ROOM))
    x = 40.0
    for name in FESTIVALS:
        t.text(x, y + 10, 11, name, INK)
        rs.paste(sh.px, rs.shrink(tags[name][0], 5.0 * ui.K / DRAWN), round((x + 15) * ui.K), round((y + 30) * ui.K))
        t.text(x + 77, y + 232, 8.5, "the tag, five times its size at 96 pt", SOFT_INK, "CENTER")
        put(sh, rs.shrink(discs[name], 5.0 * 13.0 / 13.2 * ui.K / DRAWN), x + 222, y + 110)
        t.text(x + 222, y + 232, 8.5, "its mark for 40 pt, five times", SOFT_INK, "CENTER")
        tile.glow(tile.poly([(x + 400, 120), (x + 401, 120), (x + 401, 121)]), 70.0, c(rb.VIOLET["ground"]), 0.8)
        tagged(sh, big["Prismatic"], tags[name], x + 420, y + 122, 190.0)
        t.text(x + 420, y + 232, 8.5, "on a Prismatic, twice a chamber's 96 pt", SOFT_INK, "CENTER")
        x += 570

    # Every size, on the two grounds.
    y = 334.0
    t.text(20, y, 10, "At each size, on the Breaker's dark and on a dusk street. In each group: Lantern Row's Standard, Enriched "
           "and Prismatic, then Drum Court's; then one as today, with no tag.", SOFT_INK)
    for j, (ground, code) in enumerate((("the Breaker's dark", ROOM), ("a dusk street", DUSK))):
        ty = y + 18 + j * 232
        tile = sh.tile(20, ty, 1140, 224)
        tile.paint(tile.poly(ui.cut_box(0, 0, 1140, 224)), c(code))
        ink = INK if j == 0 else "#17141F"
        t.text(28, ty + 6, 9, ground, ink)
        pairs = [(name, grade) for name in FESTIVALS for grade in GRADES] + [(None, "Prismatic")]
        x = 64.0
        for tall, step in ((96.0, 98.0), (50.0, 54.0)):
            x0 = x
            for name, grade in pairs:
                tagged(sh, big[grade], tags.get(name), x, ty + 128 - tall / 2, tall)
                x += step
            t.text((x0 + x - step) / 2, ty + 136, 8.5, f"{tall:g} pt: the shard with its tag", ink, "CENTER")
            x += 26 - (step - tall * 0.78) / 2
        x = 52.0
        x0 = x
        for name, grade in pairs:
            marked(sh, small[grade], discs.get(name), x, ty + 176)
            x += 46
        t.text((x0 + x - 46) / 2, ty + 206, 8.5, "40 pt: the tag's mark at the shard's foot", ink, "CENTER")
        x += 30
        x0 = x
        for name, grade in pairs:
            chip(sh, small[grade], name, x, ty + 163)
            x += 36
        t.text((x0 + x - 10) / 2, ty + 206, 8.5, "a 26 pt chip: the ground's colour along its foot", ink, "CENTER")
        x += 40
        x0 = x
        for name, grade in pairs[2::3][:2]:  # a third in place of a quarter, for the comparison
            tagged(sh, big[grade], tags[name], x, ty + 198 - 25, 50.0, 1 / 3)
            x += 58
        t.text((x0 + x - 58) / 2, ty + 206, 8.5, "50 pt, the tag a third", ink, "CENTER")

    # A chamber today, and with the tag and the two-line name.
    y = 822.0
    t.text(20, y, 10, "A chamber as today, then with the tag and the name on two lines: the ground small, the grade large "
           "(a sketch of the window, not the screen's art).", SOFT_INK)
    x = 20.0
    x += chamber(sh, t, big["Prismatic"], None, x, y + 18, 1, ("Prismatic",), "2:41:07") + 28
    for i, (name, grade, time) in enumerate((("Lantern Row", "Prismatic", "2:41:07"), ("Drum Court", "Enriched", "12:40"),
                                             ("Lantern Row", "Standard", "0:24"))):
        x += chamber(sh, t, big[grade], tags[name], x, y + 18, i + 1, (name, f"{grade} Shard"), time) + 12
    t.text(x + 16, y + 26, 9.5, "For research's read:", INK)
    notes = (
        "The tag hangs off the crystal's right shoulder, on the ground beside it, so it never covers a spire.",
        "At a quarter, 50 points leaves the mark about 6 points high: the colour tells the ground, the mark confirms it.",
        "Lantern Row's cyan stands 8 from Frost's blue and Drum Court's red 6 from health's (CIEDE2000):",
        "the tag's shape and place carry it.",
        "Drum Court's cream is this block's: the roster names red alone.",
        "Still to draw: the other four grounds' marks. Mask Parade's violet will sit on a violet shard",
        "in a violet room.",
    )
    for i, line in enumerate(notes):
        t.text(x + 16, y + 44 + i * 15, 9, line, SOFT_INK)
    rb.finish(sh, out / "shard_tag_block.png")


def main():
    out = bl.out_dir()
    big = {g: rs.load(SHARDS / f"shard_{g.lower()}.png") for g in GRADES}
    small = {g: rs.load(SHARDS / f"shard_{g.lower()}_small.png") for g in GRADES}
    tags = {name: tag(name) for name in FESTIVALS}
    discs = {name: token(name) for name in FESTIVALS}
    sheet(out, big, small, tags, discs)


if __name__ == "__main__":
    main()
