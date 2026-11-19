"""AR40's must-fix on the road's trail and the crystals (the director, 2026-11-19, 01:4x: "the map is a bit to purple
does it, that purple trail on the road and crystal"; docs/asset-requests.md, AR40, "The director: still too purple"):
today's swatches beside the new, flat, sampled as the kit's atlas samples them. It's no render and no verdict: the check
is Faber's install capture by day from a phone's camera.

    1. The road's trail on the Strip's stones by day: the wide crack, the thin one and a branch to a gate.
    2. The crystals against the day sky: the far shards, the Tower asleep, and an outcrop with its one small shard of
       the void's light.
    3. The lights: a post's lamp, the crossing's heart, and their PointLights' colour.
    4. The swatches by name, head over foot.

The new values live in base_kit.SWATCHES and strip_kit.LIGHT; today's are kept here, as they stood before.

    blender -b --factory-startup --python tools/blender/ar40_trail_sheet.py -- <abs out>
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_kit as base  # noqa: E402
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import strip_kit as strip  # noqa: E402
import ui_sheet as ui  # noqa: E402

_over = ui.over
ui.over = lambda dst, colour, a: _over(dst, ui.c(colour) if isinstance(colour, str) else colour, a)

NEW = dict(base.SWATCHES)
TODAY = dict(NEW, far=("#B8A8E0", "#8878BC", 0.0), tower=("#A898D4", "#7868AE", 0.0), outcrop=("#B0A0DC", "#8070B8", 0.0))
LOOKS = {"Today": dict(sw=TODAY, bed="dark", edge=None, light="void", lamp="#C9B0FF", heart="#B58CFF"),
         "New": dict(sw=NEW, bed="well", edge="trailedge", light="trail", lamp=strip.LIGHT, heart=strip.LIGHT)}
SKY, STONES, JOINT, INK = ("#4FA3E0", "#C4DCF2"), "#F2EDE4", "#B2946C", "#EDE6D6"


def code(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float64) / 255.0


def hexof(c):
    return "#" + "".join(f"{int(round(v * 255)):02X}" for v in np.clip(c, 0, 1))


def sample(sw, name, u, v):
    """A swatch where the kit samples it: v 1 its head, 0 its foot; an unlit swatch darkens across its cell, as the
    atlas draws it (base_kit.atlas)."""
    top, foot, lit = sw[name]
    t = (1 - v) ** 0.85
    c = code(top) * (1 - t) + code(foot) * t
    if lit < 0.5:
        c = c * (1 - 0.5 * np.clip((u * 64 - 8) / 48, 0, 1))
    return hexof(c)


def polyline_sdf(t, pts):
    return np.minimum.reduce([ui.sd_segment(t.x, t.y, a, b) for a, b in zip(pts, pts[1:])])


def crack(t, look, line, rank, ox, oy, s):
    """One crack, as strip_kit.crack lays it: its bed, its edge (new), its light, at the mean of its half widths."""
    sw = look["sw"]
    points, widths, sides = line
    for pts, ws in [(points, widths)] + list(sides):
        half = float(np.mean(ws))
        xy = [(ox + along * s, oy + across * s) for across, along in pts]
        d = polyline_sdf(t, xy)
        t.paint(d - (half * 2 + 0.08) * s, sample(sw, look["bed"], 0.5, 0.6))
        if look["edge"]:
            t.paint(d - (half * 1.35 + 0.04) * s, sample(sw, look["edge"], 0.0, rank))
        light = sample(sw, look["light"], 0.0, rank)
        t.glow(d - half * s, 3.0, light, 0.35)
        t.paint(d - half * s, light)


def stones(t, x0, y0, x1, y1):
    t.paint(t.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)]), STONES)
    for k, y in enumerate(np.arange(y0 + 22, y1, 22)):
        t.stroke([(x0, y), (x1, y)], 1.2, JOINT, 0.55)
        for x in np.arange(x0 + (k % 2) * 17 + 8, x1, 34):
            t.stroke([(x, y - 22), (x, y)], 1.2, JOINT, 0.55)


def kite(t, sw, name, cx, foot_y, high, wide, lean=0.12):
    """A shard as the kit's horn reads from the side: two faces, the lit one full, the far one darker, head at top."""
    tip = (cx + wide * lean * 2, foot_y - high)
    mid_y = foot_y - high * 0.3
    left = [(cx - wide / 2, foot_y), (cx - wide * 0.5, mid_y), tip, (cx + wide * 0.08, foot_y)]
    right = [(cx + wide * 0.08, foot_y), tip, (cx + wide * 0.5 + wide * lean, mid_y), (cx + wide / 2, foot_y)]
    for face, u in ((left, 0.0), (right, 1.0)):
        d = t.poly(face)
        frac = (foot_y - t.y) / high                       # 0 at the foot, 1 at the tip
        t.paint(d, t.ramp(sample(sw, name, u, 0.0), sample(sw, name, u, 1.0), frac))


def crystals(t, look, x0, y0, w, h):
    sw = look["sw"]
    ground = y0 + h - 26
    t.paint(t.poly([(x0, y0), (x0 + w, y0), (x0 + w, ground), (x0, ground)]), t.ramp(SKY[0], SKY[1], (t.y - y0) / (ground - y0)))
    for cx, high, wide in ((x0 + 40, 150, 34), (x0 + 120, 104, 26), (x0 + 470, 186, 40), (x0 + 535, 120, 28)):
        kite(t, sw, "far", cx, ground, high, wide)
    # the Tower asleep: stacked tiers, the kit's lathe of four sides
    for k, (half, top) in enumerate(((44, 52), (34, 92), (24, 128), (12, 150))):
        d = t.poly([(x0 + 230 - half, ground), (x0 + 230 - half * 0.9, ground - top), (x0 + 230 + half * 0.9, ground - top),
                    (x0 + 230 + half, ground)])
        t.paint(d, t.ramp(sample(sw, "tower", 0.3, 0.1), sample(sw, "tower", 0.3, 0.9), (ground - t.y) / 150))
    t.paint(t.poly([(x0, ground), (x0 + w, ground), (x0 + w, y0 + h), (x0, y0 + h)]), STONES)
    for cx, high, wide, lean in ((x0 + 350, 108, 30, 0.1), (x0 + 322, 62, 20, -0.5), (x0 + 384, 74, 22, 0.45),
                                 (x0 + 300, 40, 14, -0.7)):
        kite(t, sw, "outcrop", cx, ground + 8, high, wide, lean)
    core = t.poly([(x0 + 366, ground + 6), (x0 + 361, ground - 22), (x0 + 372, ground - 50), (x0 + 377, ground - 20)])
    t.glow(core, 5.0, sample(sw, "void", 0.0, 0.8), 0.4)
    t.paint(core, t.ramp(sample(sw, "void", 0.0, 0.0), sample(sw, "void", 0.0, 1.0), (ground + 6 - t.y) / 56))


def lights(t, look, x0, y0, w, h):
    sw = look["sw"]
    t.paint(t.poly([(x0, y0), (x0 + w, y0), (x0 + w, y0 + h), (x0, y0 + h)]), t.ramp(SKY[0], SKY[1], (t.y - y0) / h))
    # a post's lamp: its ring of void stone with the dark lip, its shard of light
    cx, cy = x0 + 90, y0 + h / 2
    t.paint(np.hypot(t.x - cx, t.y - cy) - 34, sample(sw, "abyss", 0.0, 0.6))
    t.paint(np.hypot(t.x - cx, t.y - cy) - 29, sample(sw, "well", 0.5, 0.5))
    shard = t.poly([(cx, cy - 30), (cx + 10, cy - 4), (cx, cy + 22), (cx - 10, cy - 4)])
    t.glow(shard, 10.0, look["lamp"], 0.5)
    t.paint(shard, t.ramp(sample(sw, look["light"], 0.0, 1.0), sample(sw, look["light"], 0.0, 0.3), (t.y - cy + 30) / 52))
    t.text(cx, y0 + h - 22, 14, "a post's lamp", "#1E3238", align="CENTER", bold=0.2)
    # the crossing's heart: the great shard of light between two of its three stone parts, the small shards adrift
    cx = x0 + 300
    for sx in (-1, 1):
        t.paint(t.poly([(cx + sx * 16, y0 + 16), (cx + sx * 46, y0 + h / 2), (cx + sx * 18, y0 + h - 40), (cx + sx * 8, y0 + h / 2)]),
                sample(sw, "abyss", 0.3 if sx < 0 else 0.9, 0.5))
    heart = t.poly([(cx, y0 + 10), (cx + 9, y0 + h / 2 - 6), (cx, y0 + h - 34), (cx - 9, y0 + h / 2 - 6)])
    t.glow(heart, 14.0, look["heart"], 0.45)
    t.paint(heart, t.ramp(sample(sw, look["light"], 0.0, 1.0), sample(sw, look["light"], 0.0, 0.5), (t.y - y0) / h))
    for dx, dy in ((-70, 40), (66, 26), (-58, 120), (74, 104)):
        small = t.poly([(cx + dx, y0 + dy - 12), (cx + dx + 4, y0 + dy), (cx + dx, y0 + dy + 9), (cx + dx - 4, y0 + dy)])
        t.paint(small, sample(sw, "void", 0.0, 0.8))
    t.text(cx, y0 + h - 22, 14, "the crossing's heart", "#1E3238", align="CENTER", bold=0.2)
    # the PointLights' colour
    for k, (said, colour) in enumerate((("post", look["lamp"]), ("heart", look["heart"]))):
        y = y0 + 22 + k * 64
        t.paint(t.poly([(x0 + 450, y), (x0 + 500, y), (x0 + 500, y + 44), (x0 + 450, y + 44)]), colour)
        t.text(x0 + 508, y + 6, 14, said, "#1E3238", bold=0.2)
        t.text(x0 + 508, y + 24, 14, colour, "#1E3238")


CHIPS = ("far", "tower", "outcrop", "trail", "trailedge", "well", "void")


def chips(t, look, x0, y0):
    sw = look["sw"]
    for k, name in enumerate(CHIPS):
        if name not in sw or (look is LOOKS["Today"] and name in ("trail", "trailedge")):
            continue
        x = x0 + k * 80
        top, foot, lit = sw[name]
        t.paint(t.poly([(x, y0), (x + 70, y0), (x + 70, y0 + 64), (x, y0 + 64)]), t.ramp(top, foot, (t.y - y0) / 64))
        t.text(x, y0 + 72, 14, name, INK, bold=0.2)
        t.text(x, y0 + 90, 14, top, "#B4AC9C")
        t.text(x, y0 + 106, 14, foot, "#B4AC9C")


def main():
    out = bl.out_dir()
    ui.K = 1
    w, pad = 600, 24
    rows = [("The road's trail on the Strip's stones by day: the wide crack, the thin one, a branch to a gate", 300),
            ("The crystals against the day sky: far shards, the Tower asleep, an outcrop with its one small shard", 230),
            ("The lights: a post's lamp, the crossing's heart, their PointLights", 170),
            ("The swatches, head over foot", 130)]
    width = pad + 2 * (w + pad)
    height = 70 + sum(h + 44 for _, h in rows)
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(pad, 16, 20, "AR40's must-fix: the road's trail and the crystals, today beside the new. Flat swatches, no render",
           "#EDE6D6", bold=0.2)
    for k, key in enumerate(LOOKS):
        t.text(pad + k * (w + pad), 46, 17, key, "#EDE6D6", bold=0.3)
    y = 70
    for said, h in rows:
        t.text(pad, y + 4, 14, said, "#B4AC9C")
        y += 26
        for k, (key, look) in enumerate(LOOKS.items()):
            x0 = pad + k * (w + pad)
            if said.startswith("The road"):
                stones(t, x0, y, x0 + w, y + h)
                for line, rank, oy in ((strip.WIDE, 1.0, 84), (strip.THIN, 0.7, 205), (strip.TWIG, 0.0, 272)):
                    crack(t, look, line, rank, x0 + w / 2, y + oy, 17.0)
            elif said.startswith("The crystals"):
                crystals(t, look, x0, y, w, h)
            elif said.startswith("The lights"):
                lights(t, look, x0, y, w, h)
            else:
                chips(t, look, x0, y)
        y += h + 18
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "ar40_trail.png")


if __name__ == "__main__":
    main()
