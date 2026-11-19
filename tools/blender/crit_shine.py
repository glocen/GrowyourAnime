"""The critical's shine, a blockout (the director, 2026-11-19, about 23:28: "the crit text isnt chromatic shiny right now
it look sad and meh"). Three takes on the critical's digits beside the game's own, in motion from the land, over the
dark fight and Lantern Row by day, at the phone's size and up close. Blender's face stands in for the game's.

    blender -b --factory-startup --python tools/blender/crit_shine.py -- <abs out>

The takes keep everything the critical has but its fill (Config.Hud.Numbers.Critical: the splash, the outline, the
cast, the pop), and use only what a Roblox TextLabel can do, so each is a Config change and a few labels for the
builder:
    Now   the measured ramp, gold drifting to an olive khaki (AR44, 12:48).
    A     gold chrome: the label's vertical UIGradient a polished metal, near-white at its top, rich gold down to a
          hard dark horizon just under the middle, a hot amber below, a light lip at its foot. On the land a white
          flash (a white copy over it, gone in 4 frames), then one glint: a white copy whose transparency gradient is
          one narrow slanted band, its Offset swept across the digits in 0.22 s.
    B     prism foil: A, with a copy over it in a slanted rainbow gradient (gold, peach, rose, mint, sky) at 0.55
          see-through, drifting slowly along, so the gold shifts colour across the number.
    C     chromatic split: A, with a cyan and a red copy behind it, struck wide apart on the land and drawn in to sit
          just outside the outline, so a thin cyan and red fringe stays on the number's two sides.
The pop as the game's: it lands at Pop 1.3 and settles over Count 0.12 s (Config.Combat.Numbers).
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_art as ha  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
SPLASH = REPO / "build" / "handoff" / "UI" / "hud" / "images" / "CritSweep.png"
DARK = REPO / "build" / "scratch" / "faber" / "stills" / "burst-crowded-phone.png"   # a fight, about 1.1 px a point
DAY = REPO / "build" / "scratch" / "faber" / "stills" / "tr24-07-row-fight.jpg"                # Lantern Row by day, in a fight
K = ui.K                       # 2 pixels a point
SIZE = 40                      # points: the critical's text, 24 authored pixels times 1.6
TEXT = "1,204"
TILE = (200, 92)               # points
FRAMES = (0, 2, 4, 6, 9, 13, 18, 24, 33, 45)   # at 60 from the land
POP, COUNT = 1.3, 0.12         # Config.Combat.Numbers
SHEAR = ha.SHEAR

CHROME = ((0.0, "#FFFDF0"), (0.15, "#FFF2B0"), (0.35, "#FFD84A"), (0.49, "#FFB300"), (0.5, "#7A3A00"),
          (0.58, "#B85E00"), (0.75, "#FF9A1A"), (0.92, "#FFD36B"), (1.0, "#FFF0B8"))
# B: the label's own gradient is the rainbow, slanted and drifting; a copy over it carries the metal's light, its own
# vertical gradient white at the top, clear, a dark horizon, clear, a pale lip (colour, then how see-through)
PRISM = ((0.0, "#FFD23F"), (0.2, "#FF8A5C"), (0.4, "#FF5FA2"), (0.6, "#5CFFC4"), (0.8, "#5CC8FF"), (1.0, "#FFD23F"))
PRISM_DRIFT = 0.6                           # the rainbow's Offset, a second
SHEEN = ((0.0, "#FFFFFF", 0.1), (0.3, "#FFFFFF", 1.0), (0.47, "#FFFFFF", 1.0), (0.5, "#3A1800", 0.35),
         (0.62, "#3A1800", 1.0), (0.9, "#FFFFFF", 1.0), (1.0, "#FFFFFF", 0.5))
GLINT = dict(start=0.08, seconds=0.25, width=0.1, trail=0.13, slant=-70)  # half widths, of the number's width
FLASH = 4 / 60
# C's split: struck `wide` apart on the land, drawn in to `rest` over `seconds`, eased out. Research's condition on its
# pick (23:36): a hairline each side at rest at the phone's size by day; 3.4 vanished, 5.8 doubled the 1 (crit_rest.png)
SPLIT = dict(cyan="#3DEBFF", red="#FF3D5E", wide=7.0, rest=4.6, seconds=0.2, alpha=0.85, rest_alpha=0.95)
TAKES = ("Now", "A", "B", "C")
NAMES = {"Now": "Now: the measured gold to khaki (AR44)", "A": "A, gold chrome: a polished ramp, a white flash, one glint",
         "B": "B, prism foil: a drifting rainbow under A's light", "C": "C, chromatic split: A with a cyan and a red fringe"}


def ease(u):
    u = np.clip(u, 0, 1)
    return 1 - (1 - u) ** 2


def ramp(stops, at):
    pos = [p for p, _ in stops]
    cols = np.array([rs.rgb(c) for _, c in stops], np.float32)
    return np.stack([np.interp(at, pos, cols[:, k]) for k in range(3)], -1).astype(np.float32)


def shifted(a, dx, dy):
    out = np.zeros_like(a)
    h, w = a.shape[:2]
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    out[yd, xd] = a[ys, xs]
    return out


class Number:
    def __init__(self, cover):
        self.cover = cover
        h, w = cover.shape
        rows, cols = np.where(cover.any(1))[0], np.where(cover.any(0))[0]
        self.top, self.left, self.right = rows[0], cols[0], cols[-1]
        self.tall = round(SIZE * ui.CAP * K)
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        self.at = np.clip((yy - self.top) / self.tall, 0, 1)                    # down the digits, 0 to 1
        self.along = (xx - self.left) / max(self.right - self.left, 1)          # across the number, 0 to 1
        # the slanted coordinate for a gradient at `slant` degrees: along the number, leaning with the italic
        self.leaning = self.along + (yy - self.top) / max(self.right - self.left, 1) * 0.36
        self.edge = ui.spread(cover, round(ha.DIGITS["outlinePoints"] * K))
        commas = TEXT.count(",")
        digit = (self.right - self.left) / (len(TEXT) - 0.5 * commas + (len(TEXT) - 1) * ha.DIGITS["gap"])
        lay = ha.SWEEP_LAY
        sh = round(lay["height"] * self.tall)
        sw = round(max(lay["width"] * (self.right - self.left), lay["least"] * sh))
        self.splash = (ha.stretched(rs.load(SPLASH), sw, sh), round(self.left - lay["left"] * digit),
                       round(self.top + self.tall / 2 - sh / 2))

    def badge(self, take, t):
        """The critical at a time t from its land, before the pop's scale: an RGBA layer."""
        h, w = self.cover.shape
        layer = np.zeros((h, w, 4), np.float32)
        mark, sx, sy = self.splash
        canvas = np.zeros((h, w, 4), np.float32)
        rs.paste(canvas, mark, sx, sy)
        alpha = np.zeros((h, w), np.float32)
        hh, ww = mark.shape[:2]
        y0, x0 = max(sy, 0), max(sx, 0)
        alpha[y0:sy + hh, x0:sx + ww] = mark[y0 - sy:min(sy + hh, h) - sy, x0 - sx:min(sx + ww, w) - sx, 3]
        ui.over(layer, canvas[..., :3], alpha)
        dark = ui.c(ha.DIGITS["outline"])
        dx, dy = (round(p * K) for p in ha.DIGITS["cast"])
        ui.over(layer, dark, shifted(self.edge, dx, dy))
        if take == "C":
            u = ease(t / SPLIT["seconds"])
            d = SPLIT["wide"] + (SPLIT["rest"] - SPLIT["wide"]) * u
            a = SPLIT["alpha"] + (SPLIT["rest_alpha"] - SPLIT["alpha"]) * u
            off = round(d * K)
            ui.over(layer, ui.c(SPLIT["cyan"]), shifted(self.cover, -off, -round(off / 4)) * a)
            ui.over(layer, ui.c(SPLIT["red"]), shifted(self.cover, off, round(off / 4)) * a)
        ui.over(layer, dark, self.edge)
        if take == "Now":
            fill = ramp(ha.DIGITS["ramp"], self.at)
        else:
            fill = ramp(CHROME, self.at)
            if take == "B":
                fill = ramp(PRISM, (self.leaning + PRISM_DRIFT * t) % 1.0)
                pos = [q for q, _, _ in SHEEN]
                cols = np.array([rs.rgb(c) for _, c, _ in SHEEN], np.float32)
                light = np.stack([np.interp(self.at, pos, cols[:, k]) for k in range(3)], -1)
                a = 1 - np.interp(self.at, pos, [v for _, _, v in SHEEN])
                fill = fill * (1 - a[..., None]) + light * a[..., None]
            if t < FLASH:
                fill = fill + (1 - fill) * (1 - t / FLASH)
            g = (t - GLINT["start"]) / GLINT["seconds"]
            if 0 <= g <= 1:
                centre = -0.15 + 1.3 * g
                band = np.exp(-((self.leaning - centre) / GLINT["width"]) ** 2)
                band = np.maximum(band, 0.6 * np.exp(-((self.leaning - centre + GLINT["trail"]) / (GLINT["width"] * 0.35)) ** 2))
                fill = fill + (1 - fill) * band[..., None] * 0.95
        ui.over(layer, fill, self.cover)
        return layer


def popped(layer, t):
    s = 1 + (POP - 1) * (1 - ease(t / COUNT)) if t < COUNT else 1.0
    h, w = layer.shape[:2]
    big = ha.stretched(layer, round(w * s), round(h * s))
    return big, round((w - big.shape[1]) / 2), round((h - big.shape[0]) / 2)


def lettered(sheet, words, band=360):
    """The sheet's words a band at a time (one text render at the sheet's whole size outgrows the PC's free memory)."""
    height, width = sheet.shape[:2]
    for top in range(0, height, band):
        items = [(x, y - top, size, text, code) for x, y, size, text, code in words if top <= y < top + band]
        if items:
            rs.paste(sheet, rs.text_layer(width, band + 40, items), 0, top)


def rests(out, number, grounds, w, h, tries=(3.4, 4.2, 4.6, 5.0, 5.8)):
    """C at rest (frame 45) with its split's resting width tried wider, at the phone's size and at 2 px a point."""
    gap, margin, head = 8, 16, 22
    width = margin * 2 + len(tries) * (w + gap)
    height = 70 + len(grounds) * (head + h + 10 + h // 2 + 10) + 20
    sheet = rs.canvas(width, height, tuple(rs.rgb("#101117")))
    words = [(margin, 12, 20, "C at rest (frame 45): the split's resting width, each beside the next", "#EDE6D6"),
             (margin, 40, 13, "Each try at 2 pixels a point, then at the phone's own size under it. The fringe should read "
                              "as a hairline each side, never as a second number.", "#A9A398")]
    y = 70
    keep = dict(SPLIT)
    rest_alpha = SPLIT["rest_alpha"]
    for gname, ground in grounds.items():
        words.append((margin, y + 3, 14, f"over {gname}", "#EDE6D6"))
        for i, rest in enumerate(tries):
            SPLIT["rest"], SPLIT["rest_alpha"] = rest, rest_alpha
            big, ox, oy = popped(number.badge("C", 0.75), 0.75)
            tile = ground.copy()
            rs.paste(tile, big, ox, oy)
            x = margin + i * (w + gap)
            rs.paste(sheet, tile, x, y + head)
            rs.paste(sheet, rs.shrink(tile, 0.5), x, y + head + h + 6)
            words.append((x + w // 2 + 8, y + head + h + 10, 13, f"rest {rest:g} pt", "#EDE6D6"))
        y += head + h + 10 + h // 2 + 10
    SPLIT.update(keep)
    lettered(sheet, words)
    rs.save(sheet, out / "crit_rest.png")


def cut():
    """C, research's pick (23:36), as numbers for Config.Hud.Numbers.Critical: what changes, and the labels it adds."""
    import json
    path = REPO / "build" / "handoff" / "UI" / "hud" / "critical_shine.json"
    keys = lambda stops: [[p, c] for p, c in stops]   # noqa: E731
    path.write_text(json.dumps(dict(
        take="C, the chromatic split (research's pick, 2026-11-19, 23:36), on the director's \"the crit text isnt "
             "chromatic shiny right now it look sad and meh\" (about 23:28)",
        keeps="the splash (Sweep), Outline #211306 at Weight 2.4, the Cast, Italic, Gap and the pop (Land, Pop, Count): "
              "unchanged",
        ramp=dict(stops=keys(CHROME), note="replaces Critical.Ramp, top to foot (Rotation 90). The two stops at 0.49 and "
                                           "0.5 make the hard horizon: keep them apart by no more"),
        split=dict(cyan=SPLIT["cyan"], red=SPLIT["red"], landPoints=SPLIT["wide"], restPoints=SPLIT["rest"],
                   seconds=SPLIT["seconds"], ease="quad out", landTransparency=round(1 - SPLIT["alpha"], 2),
                   restTransparency=round(1 - SPLIT["rest_alpha"], 2),
                   note="two copies of the digits, no stroke, behind the critical's own label and over its cast and "
                        "splash: cyan moved left and up, red right and down, each by d along and d/4 across (authored "
                        "pixels), d from landPoints to restPoints over seconds from the land; their TextTransparency "
                        "from land to rest with it. They pop and rise with the number"),
        flash=dict(seconds=round(FLASH, 4), colour="#FFFFFF",
                   note="a white copy of the digits over the critical's label, no stroke: TextTransparency 0 at the "
                        "land to 1 at `seconds`, linear"),
        glint=dict(start=GLINT["start"], seconds=GLINT["seconds"], halfWidth=GLINT["width"], trail=GLINT["trail"],
                   trailStrength=0.6, trailHalfWidth=round(GLINT["width"] * 0.35, 3), strength=0.95,
                   note="a white copy of the digits over the label, no stroke, its UIGradient's Transparency 1 but for "
                        "a band (0.05 at its middle, 0.5 at about halfWidth, 1 by twice it) and a thinner trailing "
                        "band `trail` behind it at trailStrength. The band leans with the italic, its top to the right, "
                        "about 20 degrees off upright. Its Offset carries the band from 0.15 of the number's width "
                        "before it to 0.15 past it, linear, from `start` seconds after the land over `seconds`. Once"),
        sheet="build/scratch/modulo/crit/crit_shine.png (C's rows), crit_rest.png (the resting split)",
    ), indent=1), encoding="utf-8")
    print(f"wrote {path}")


def main():
    out = bl.out_dir()
    rs.OUT = out
    w, h = TILE[0] * K, TILE[1] * K
    item = dict(x=TILE[0] / 2, y=TILE[1] / 2 - SIZE * ui.CAP / 2, size=SIZE, text=TEXT, colour="#FFFFFF",
                align="CENTER", layer="number", shear=SHEAR, bold=0.012, space=ha.SPACE)
    number = Number(ui.text_layers(w, h, [item])["number"][..., 3])
    dark, day = rs.load(DARK), rs.load(DAY)
    print(f"the dark still {dark.shape[1]}x{dark.shape[0]}, the day capture {day.shape[1]}x{day.shape[0]}")
    gd = ha.doubled(dark[270:270 + TILE[1], 210:210 + TILE[0]].copy())
    dy0, dx0 = int(day.shape[0] * 0.30), int(day.shape[1] * 0.42)
    k = day.shape[1] / 950                                   # the capture's pixels to the phone's
    crop = day[dy0:dy0 + round(TILE[1] * k), dx0:dx0 + round(TILE[0] * k)].copy()
    gday = ha.stretched(crop, w, h)
    grounds = {"the dark fight": gd, "Lantern Row by day": gday}
    if sys.argv[-1] == "rest":
        rests(out, number, grounds, w, h)
        return
    if sys.argv[-1] == "cut":
        cut()
    tiles = {}
    for take in TAKES:
        for gname, ground in grounds.items():
            for f in FRAMES:
                t = f / 60
                big, ox, oy = popped(number.badge(take, t), t)
                tile = ground.copy()
                rs.paste(tile, big, ox, oy)
                tiles[take, gname, f] = tile
    gap, margin, head = 6, 16, 22
    close_f = 13                                            # mid-glint, settled
    cw = w
    pw, ph = w // 2, h // 2
    width = margin * 2 + cw + gap * 2 + len(FRAMES) * (pw + gap)
    row_h = head + h + 10
    title = 70
    height = title + len(TAKES) * len(grounds) * row_h + 60
    sheet = rs.canvas(width, height, tuple(rs.rgb("#101117")))
    words = [(margin, 12, 22, "The critical's shine: three takes beside the game's own, from the land", "#EDE6D6"),
             (margin, 42, 14, f"Left: frame {close_f} at 2 pixels a point (mid-glint). Right: frames 0 to 45 at 60 from the "
                              "land, at the phone's own size, with the pop. The splash, outline and cast as the game "
                              "has them. Blender's face stands in.", "#A9A398")]
    y = title
    for take in TAKES:
        for gname in grounds:
            words.append((margin, y + 3, 14, f"{NAMES[take]}, over {gname}", "#EDE6D6"))
            rs.paste(sheet, tiles[take, gname, close_f], margin, y + head)
            for i, f in enumerate(FRAMES):
                x = margin + cw + gap * 2 + i * (pw + gap)
                rs.paste(sheet, rs.shrink(tiles[take, gname, f], 0.5), x, y + head + (h - ph) // 2)
                if take == TAKES[0] and gname == "the dark fight":
                    words.append((x, y + head - 2 + (h - ph) // 2 - 16, 11, f"{f}", "#8C877E"))
            y += row_h
    words.append((margin, y + 8, 13, "A: one vertical UIGradient (a hard horizon at 0.49/0.5), a white copy for the flash "
                                     "(4 frames) and one for the glint (a transparency band, its Offset swept in 0.22 s). "
                                     "B: the label's gradient a slanted rainbow, drifting, under a copy carrying A's light (white top, dark horizon). C: plus a cyan and a red copy "
                                     "behind, drawn in from 7 to 3.4 points.", "#A9A398"))
    lettered(sheet, words)
    rs.save(sheet, out / "crit_shine.png")


if __name__ == "__main__":
    main()
