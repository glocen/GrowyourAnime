"""Combat Power's number, polished and in a colour of its own: takes for the director's pick (the director,
2026-11-15: "the combat power text need to be polished and have it own color"; docs/decisions.md).

The plate is the Voidkin screen's, at the game's sizes (Config.Hud.Voidkin.Power: 236 by 56 points, digits at 36): a
band of its rarity's light that fades at both ends, the emblem (TR17's three shards), the caption, the digits. A take
is the digits' finish: a ramp from lit top to deep foot with the kit's step at the middle, as the bars' lights have, an
ink stroke, and a glow. Each is shown at rest on a Common's and a Legendary's plate, rising on a Mythical's with the
gain in green, and narrow (no emblem, as between the two hands) on each rarity's light.

Mocks only. Every finish is one vertical gradient on the digits, a stroke and one glow image, so the engine can set it.

    blender -b --factory-startup --python tools/blender/combat_power_colour.py -- build/handoff/UI/voidkin/combat_power

Writes the sheet combat_power_colour.png.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402
import voidkin_marks as vm  # noqa: E402

kit, ui, rs, c, lc = h.kit, h.ui, h.rs, h.c, h.lc
K4 = h.K4
PW, PH, NUMBER, GAIN = 236.0, 56.0, 36.0, 26.0  # the plate, its digits, the gain (Config.Hud.Voidkin.Power)
LEFT = 56.0  # where the caption and the digits start, past the emblem
GOOD = "#7CF0A4"
INK = "#07080D"
RARITY = {"Common": "#8E95A3", "Uncommon": "#7CF0A0", "Rare": "#6FB6FF", "Epic": "#D29CFF", "Legendary": "#FFD777",
          "Mythical": "#FF8794"}
VALUE, ROSE_TO, PLUS = "27,433", "28,717", "+1,284"

# A finish: the digits' ramp from their capitals' top to their foot, the glow behind them, the caption's colour.
TAKES = (
    dict(key="Now", name="as it is, in grey", ramp=((0.0, "#FFFFFF"), (1.0, "#B0B6C4")), glow=None, caption="#9AA0AD",
         stroke=0.0, emblem=False,
         notes=("The block's stand-in: white to grey, no stroke, a grey diamond for the emblem.",)),
    dict(key="A", name="Platinum", ramp=((0.0, "#FFFFFF"), (0.3, "#F4F7FC"), (0.5, "#DCE4F0"), (0.56, "#BCC9DD"),
                                         (1.0, "#8296B8")), glow="#BFD4FF", caption="#C9D3E3", stroke=1.2, emblem=True,
         notes=("A cool polished metal, the one finish measured apart from every taken colour: its ramp stays 11.7 "
                "or more from each in plain sight, 5.6 or more for a colour-blind eye. Told from ivory by its blue foot.",
                "It holds on every rarity's light, since it borrows none of them.")),
    dict(key="B", name="Forge", ramp=((0.0, "#FFF1DC"), (0.3, "#FFC08F"), (0.5, "#FF7F47"), (0.56, "#F4622E"),
                                      (1.0, "#C2330F")), glow="#FF6A2B", caption="#FFC9A8", stroke=1.2, emblem=True,
         notes=("Hot metal, the warmest and the loudest. Its hue is Fire's neighbour: its middle stands 5.6 from "
                "Fire in plain sight and 2.1 for a deuteranope, its foot 12.8 from the Shade's health red.",
                "On a Legendary's gold and a Mythical's red light it sits among its neighbours.")),
    dict(key="C", name="Void-lit", ramp=((0.0, "#FFFFFF"), (0.3, "#F6F1FF"), (0.5, "#DCCBFF"), (0.56, "#C7B0FF"),
                                         (1.0, "#8B70E0")), glow="#B79CF5", caption="#D8C8FF", stroke=1.2, emblem=True,
         notes=("The emblem's own light: white-hot to the Voidkin's lavender. Not a colour of its own, the "
                "Voidkin's family: the number reads as part of the character.",
                "On an Epic's violet light it's the same hue as its plate.")),
)


def text(st, x, y, size, body, colour, align="LEFT", **more):
    st.items.append(dict(dict(x=x, y=y, size=size, text=body, colour=colour, align=align, layer="plain", shear=0.0,
                              bold=0.0), **more))


def wide(body, size):
    """The digits' width: about 0.62 of their size each, as the game counts them; a comma and a plus narrower."""
    return sum(0.3 if ch == "," else 0.62 for ch in body) * size


def digits(st, x, y, size, body, take, align="LEFT", lift=0.0):
    """The number in the take's finish: its glow, its ink stroke and its drop, then the ramp. `lift` brightens it."""
    box = dict(span=wide(body, size) + 16)
    if take["glow"]:
        text(st, x, y, size, body, take["glow"], align, layer="a_glow", **box)
    if take["stroke"]:
        text(st, x, y + 1.2, size, body, INK, align, layer="b_ink", bold=take["stroke"] * 2)
        text(st, x, y, size, body, INK, align, layer="b_ink", bold=take["stroke"] * 2)
    text(st, x, y, size, body, "#FFFFFF", align, layer="c_num" + take["key"], ramp=take["ramp"], lift=lift, **box)


def plate(st, x, y, w, rarity, take, value, narrow=False, rise=None):
    """Combat Power's plate as the screen lays it: the band, the emblem, the caption, the digits."""
    light = RARITY[rarity]
    t = kit.blank(w, PH)
    ends = np.clip(np.minimum(t.x, w - t.x) / (w * 0.22), 0, 1) ** 1.2
    ui.over(t.px, c("#000000"), ends * 0.5)
    ui.over(t.px, c(light), ends * 0.1)
    ui.over(t.px, c(light), ends * np.clip(1 - np.abs(t.y - (PH - 1)) / 1.6, 0, 1) * 0.9)
    ui.over(t.px, c(light), ends * np.clip(1 - np.abs(t.y - 1) / 1.2, 0, 1) * 0.45)
    if not narrow and not take["emblem"]:
        em = h.g_diamond(t, 34, PH / 2, 13.0, 13.0)
        t.paint(em, c("#2A2E38"))
        t.line(em, 1.6, c(light))
        t.paint(h.g_diamond(t, 34, PH / 2, 5.5, 5.5), c(light))
    h.place(st, t, x, y)
    if not narrow and take["emblem"]:
        st.icon("CombatPower", x + 33, y + PH / 2 + 1, 38.0)
    if narrow:
        size = float(min(max(int((w - 8) / (0.62 * len(value))), 20), NUMBER))
        text(st, x + w / 2, y + 4, 10, "COMBAT POWER", take["caption"], "CENTER", space=1.08)
        digits(st, x + w / 2, y + 16 + (PH - 16 - size * ui.CAP) / 2 - 2, size, value, take, "CENTER")
        return
    text(st, x + LEFT, y + 5, 10, "COMBAT POWER", take["caption"], space=1.08)
    size = NUMBER * (1.1 if rise else 1.0)
    digits(st, x + LEFT - (2 if rise else 0), y + 16 + (PH - 16 - size * ui.CAP) / 2 - 2, size, value, take,
           lift=0.4 if rise else 0.0)
    if rise:  # the gain floats off the plate's end, in green, as the director's reference has it
        text(st, x + w - 18, y - 4, GAIN, rise, INK, layer="b_ink", bold=2.0)
        text(st, x + w - 18, y - 4, GAIN, rise, GOOD)


def row(take):
    """A take on three plates: at rest on a Common's and a Legendary's, rising on a Mythical's; then narrow on all six."""
    p = h.ROOMS["Graphite, Voidkin"]
    st = kit.Stage(ROW_W, ROW_H, h.PARTS_GROUND)
    kit.panel(st, 0, 0, ROW_W, ROW_H, p)
    x = 16.0
    for rarity, rise in (("Common", None), ("Legendary", None), ("Mythical", PLUS)):
        plate(st, x, 22, PW, rarity, take, ROSE_TO if rise else VALUE, rise=rise)
        text(st, x + 8, 7, 9, f"{rarity}{', rising: the roll about half way' if rise else ', at rest'}", h.NOTE)
        x += PW + 18
    x = 16.0
    for rarity in RARITY:
        plate(st, x, 104, 124.0, rarity, take, VALUE, narrow=True)
        x += 124 + 14
    return h.bytes8(h.halve(st.px)), st.items


ROW_W, ROW_H = 852.0, 172.0


def finish(sheet, path):
    """Sets the sheet's text and saves it. A number's layer takes its ramp, top to foot, where each number stands; a
    glow's layer is its number, blurred."""
    k = ui.K
    layers = ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items)
    for name in sorted(layers):
        px = layers[name]
        for i in (i for i in sheet.items if i["layer"] == name and "span" in i):
            x0 = i["x"] - (i["span"] if i["align"] == "RIGHT" else i["span"] / 2 if i["align"] == "CENTER" else 8)
            a, b = max(round((x0 - 4) * k), 0), round((x0 + i["span"] + 12) * k)
            top, tall = i["y"] * k, i["size"] * ui.CAP * k
            r0, r1 = max(round(top - 8 * k), 0), round(top + tall + 10 * k)
            part = px[r0:r1, a:b]
            if "ramp" in i:
                v = np.clip((np.arange(r0, r0 + part.shape[0]) + 0.5 - top) / tall, 0, 1)
                xs = [s for s, _ in i["ramp"]]
                cols = np.stack([c(code) for _, code in i["ramp"]])
                col = np.stack([np.interp(v, xs, cols[:, j]) for j in range(3)], axis=-1)
                col = col + (1 - col) * i["lift"]
                part[..., :3] = col[:, None, :]
            else:  # a glow
                g = part[..., 3].copy()
                r = max(1, round(i["size"] * k / 14))
                for _ in range(3):
                    g = h.box(h.box(g, r, 0), r, 1)
                part[..., :3] = c(i["colour"])
                part[..., 3] = np.clip(g * 0.55, 0, 1)
        rs.paste(sheet.px, px, 0, 0)
    rs.save(sheet.px, path)


def sheet(out, rows):
    ui.K = 2
    m, head, cap = 20.0, 78.0, 56.0
    sh = ui.Sheet(ROW_W + 2 * m, head + len(rows) * (cap + ROW_H + 14) + 6, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: Combat Power's number, polished and in a colour of its own (AR12)", h.HEAD)
    t.text(m, 40, 10, "The Voidkin screen's plate at the game's size, in the Voidkin's room. A take is the digits' finish: "
           "a ramp top to foot with the kit's step, an ink stroke, a glow. The emblem and the plate don't change.", h.NOTE)
    t.text(m, 54, 10, "Each take at rest on a Common's and a Legendary's light, rising on a Mythical's with its gain in "
           "green, then narrow, as between the two hands, on every rarity's light.", h.NOTE)
    y = head
    for take, (px, items) in rows:
        tt = sh.tile(m, y, ROW_W, cap)
        tt.text(0, 6, 13, f"{take['key']}: {take['name']}", h.HEAD)
        for i, line in enumerate(take["notes"]):
            tt.text(0, 26 + i * 14, 10, line, h.NOTE)
        y += cap
        h.add(sh, px, items, m, y)
        y += ROW_H + 14
    finish(sh, out / "combat_power_colour.png")


def main():
    out = bl.out_dir()
    ui.K = K4
    h.stage("started")
    kit.panels()
    vm.marks()
    rows = [(take, row(take)) for take in TAKES]
    h.stage("the rows")
    kit.IMAGES.clear()
    sheet(out, rows)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
