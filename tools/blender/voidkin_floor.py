"""TR50's class line (research, 2026-11-20, 00:11: every art tile's ground), the one instance the sweep of 2026-11-23
left: the floor under the fighter on the Voidkin screen. It's a disc in the fighter's element (Fire orange, Storm
pink, Void violet), so a Storm or Void fighter stands on a pink or violet ground. A colour block-in for research's
pick: the stage as it stands today, beside two steps.

    blender -b --factory-startup --python tools/blender/voidkin_floor.py -- <abs out>

Writes voidkin_floor.png (three fighters by three takes, at the smallest phone's own pixels, 1.5 a point) and
voidkin_floor.json (each take's colours).

The stage is laid from VoidkinScreen's stageIn and dress and Config.Hud's Seam.Stage, and its colours as the game
shows them are read from Faber's capture (build/captures/ar43/take2-lead.png: the Fire floor shows #AB9F52, since the
viewport dulls a Neon part). Storm's and Void's floors as shown are estimates by the same dulling. The fighter is a
grey stand-in. The takes:
    A  one floor for every fighter: pale stone, the stage's own. The element stays in the fighter's words.
    B  the same floor, and the element as a thin rim of light round it: an accent, not a ground.
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

_over = ui.over
ui.over = lambda dst, colour, a: _over(dst, ui.c(colour) if isinstance(colour, str) else colour, a)  # codes, painted

K = 1.5
W, H = 310.0, 220.0                       # the stage's corner of the phone
STAGE = ("#140F25", "#2A2B36")            # Seam.Stage, its foot 0.35 toward Common's trim
TRIM, LIGHT = "#666C78", "#EDE4FF"
STONE = "#A9A59B"                         # the floor as shown: pale stone, as bright as today's Fire floor
RIM = 1.1                                 # the element's rim at the floor's front, in points: a ring 0.03 of the floor across
FIGHTERS = [("Rook", "Fire", "#FF8A3D", "#AB9F52"),     # the element's colour, and its floor as the game shows it
            ("Watt", "Storm", "#FF6FD8", "#A98AA6"),
            ("Kirra", "Void", "#B58CFF", "#8F84B4")]
TAKES = [("Today", "Today: the floor in the element's colour"),
         ("A", "A. One floor: pale stone"),
         ("B", "B. Pale stone, the element as a rim of light")]


def ellipse(t, cx, cy, rx, ry):
    return (np.hypot((t.x - cx) / rx, (t.y - cy) / ry) - 1) * ry


def stand_in(t, cx, foot):
    """A grey fighter, the rig's proportions: a stand-in."""
    body, dark, pale = "#7E8088", "#3A3C44", "#B4B2AC"
    for x in (-12, 1):
        t.paint(t.poly(ui.cut_box(cx + x, foot - 44, cx + x + 11, foot, 1, 1, 1, 1)), dark)
    t.paint(t.poly(ui.cut_box(cx - 24, foot - 84, cx + 24, foot - 44, 2, 2, 2, 2)), body)
    for x in (-37, 25):
        t.paint(t.poly(ui.cut_box(cx + x, foot - 84, cx + x + 12, foot - 46, 1, 1, 1, 1)), pale)
    t.paint(t.poly(ui.cut_box(cx - 14, foot - 110, cx + 14, foot - 85, 3, 3, 3, 3)), pale)
    t.paint(t.poly(ui.cut_box(cx - 15, foot - 116, cx + 15, foot - 104, 2, 2, 2, 2)), dark)


def stage(t, take, fighter):
    name, element, colour, shown = fighter
    t.paint(t.poly([(0, 0), (W, 0), (W, H), (0, H)]), "#010111")
    x0, y0, x1, y1 = 7, 10, 301, 208
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 4, 4, 4, 4))
    t.paint(d, t.ramp(STAGE[0], STAGE[1], (t.y - y0) / (y1 - y0)))
    cx = (x0 + x1) / 2
    inside = np.maximum(d, 0) * 1e3                                    # everything stays on the stage
    t.paint(np.maximum(np.hypot(t.x - cx, t.y - 100) - 54, d), TRIM, 0.18)
    t.paint(d, LIGHT, 0.13 * np.exp(-((t.x - cx) / 26) ** 2))
    floor = ellipse(t, cx, 162, 123, 17)
    t.paint(floor + inside, shown if take == "Today" else STONE)
    if take != "Today":                                                # the stage's own light on its stone
        t.paint(floor + inside, "#FFFFFF", 0.22 * np.exp(-((t.x - cx) / 70) ** 2))
    if take == "B":                                                    # a band at the floor's edge: the stone stays stone
        band = np.abs(floor + RIM / 2) - RIM / 2 + inside
        t.glow(band, 3.0, colour, 0.4)
        t.paint(band, colour)
    t.paint(ellipse(t, cx, 163, 40, 6), "#000000", 0.35)               # the fighter's shade on its floor
    stand_in(t, cx, 163)
    t.text(x0 + 28, y0 + 6, 14, name, "#F1ECFF", bold=0.3)
    t.text(x0 + 28 + len(name) * 8.4 + 4, y0 + 7, 12, f"Common · {element}", "#8279A6")


def main():
    out = bl.out_dir()
    ui.K = K
    gap, head, label = 12.0, 30.0, 22.0
    width = gap + (W + gap) * len(TAKES)
    height = head + len(FIGHTERS) * (label + H + gap)
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 9, 15, "The Voidkin screen's floor under the fighter, at the smallest phone's pixels", "#EDE6D6",
           bold=0.2)
    for row, fighter in enumerate(FIGHTERS):
        y = head + row * (label + H + gap)
        for col, (take, words) in enumerate(TAKES):
            x = gap + col * (W + gap)
            t.text(x, y + 3, 13, f"{fighter[0]}, {fighter[1]}. {words}" if col == 0 else words, "#B4AC9C")
            stage(sheet.tile(x, y + label, W, H), take, fighter)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "voidkin_floor.png")
    takes = {
        "Today": {"floor": "the element's colour (UIKit.Elements), or Seam.Facet with none", "as shown":
                  {f[1]: f[3] for f in FIGHTERS}},
        "A": {"floor as shown": STONE, "rim": None},
        "B": {"floor as shown": STONE, "rim": {"colour": "the element's (UIKit.Elements)", "wide": RIM, "glow": 0.4,
              "glow's reach": 3.0}},
    }
    (out / "voidkin_floor.json").write_text(json.dumps(takes, indent=1))
    print(f"wrote {out / 'voidkin_floor.png'}")


if __name__ == "__main__":
    main()
