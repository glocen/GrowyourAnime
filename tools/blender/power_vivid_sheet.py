"""AR12, delivery 3 (docs/asset-requests.md, AR12, "Delivery 3, the older screens, vivid"): "the bays in Dynamo vivid
first", which since TR18 is the Power screen. This draws the sheets research judges before any image is made: today
beside vivid, at a phone's size, the layout Faber's (src/client/UI/PowerScreen.luau), unchanged.

Today's side is Faber's own retake of the grey build (TR18), cut to the phone's screen:

    ffmpeg -i build/captures/tr18/retake_auto.png -vf crop=936:430:11:19 build/scratch/modulo/d3p/power_auto.png
    ffmpeg -i build/captures/tr18/retake_split.png -vf crop=936:430:11:19 build/scratch/modulo/d3p/power_split.png

The vivid side is drawn over the same still, so the world behind is the game's own. The room is "Dynamo, vivid"
(hud_colour_sheet.ROOMS); the pieces are the kit's slices and AR12's icons; the numbers are the stills' own. Text is
Blender's face standing in for the game's.

    blender -b --factory-startup --python tools/blender/power_vivid_sheet.py -- build/handoff/UI/hud/colour
"""
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402
import screens_vivid_sheet as sv  # noqa: E402

kit, ui, rs, c = h.kit, h.ui, h.rs, h.c
W, H, K4 = h.W, h.H, h.K4
STILLS = h.REPO / "build" / "scratch" / "modulo" / "d3p"
POWER = h.POWER
ROOM = dict(h.ROOMS["Dynamo, vivid"], alpha=1.0)  # solid here: the mock is drawn over the built screen
SMALL = sv.SMALL
# A machine's light on the bar and on its row's chip (the build: "each in a grey colour until AR12's pick"). The room
# is amber and the battery's share is Power's yellow, so the machines are the cool lights: the Breaker the void's
# violet, its own room's colour; the Training machine a cyan no rarity and no currency wears.
BREAKER, TRAINING = "#9B8CFF", "#4FD1FF"
EMBER = "#F2A63B"  # the conduit's warmth on the iron round it
OVER = "#FF9A4D"  # demand over generation, under Auto: a caution, never the failed button's red
# The screen's panel and its body, measured on the still (points on the 812 by 375 screen).
PX, PY, PW, PH = 108.0, 64.0, 600.0, 304.0
BX, BR = 125.0, 693.0
AUTO = (596.0, 124.0, 96.0, 48.0)
TRACK = (151.0, 195.0, 514.0, 24.0)
ROWS, ROW_H = (241.0, 297.0, 353.0), 50.0
MINUS, PLUS, SHARE = 511.0, 631.0, 596.0

# The plant in each still: the bar's cuts, the head's second line and whether it warns, Auto, each machine's reading,
# share and which of its - and + are stuck, and the battery (kWh stored, its share, the work it holds).
STATES = {
    "auto": dict(cuts=(1.0, 1.0), over="The battery covers the rest", warn=True, auto=True,
                 rows=(("Void Breaker", BREAKER, "30 / 30 kW", "100%", "100%", (False, True)),
                       ("Training machine", TRAINING, "", "", "0%", (True, True))),
                 battery=(19, "0%", "38 min")),
    "split": dict(cuts=(0.25, 0.25), over="The Void Breaker at 25%", warn=False, auto=False,
                  rows=(("Void Breaker", BREAKER, "5.1 / 30 kW", "25%", "25%", (False, False)),
                        ("Training machine", TRAINING, "", "", "0%", (True, False))),
                  battery=(18, "75%", "36 min")),
}
CAP_KWH = 60


def width(text, size):
    """A word's width in points, in Blender's face."""
    curve = bpy.data.curves.new("Measure", "FONT")
    curve.body, curve.size = text, size
    obj = bpy.data.objects.new("Measure", curve)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    wide = obj.dimensions.x
    bpy.data.objects.remove(obj)
    bpy.data.curves.remove(curve)
    return wide


def runs(st, x, cy, size, parts):
    """Words on one line, each in its own colour, their middle at cy. Returns where the line ends."""
    y = cy - size * ui.CAP / 2
    for text, colour in parts:
        st.text(x, y, size, text, colour)
        x += width(text, size) + size * 0.4
    return x


def word(st, x, cy, size, text, colour, align="LEFT"):
    st.text(x, cy - size * ui.CAP / 2, size, text, colour, align)


def chip(st, x, cy, colour, size=12.0, top=None):
    """A row's key to its light on the bar: a small cut stone of the light's colour. `top`: only this much of it, from
    its top, where the list's foot cuts a row."""
    pad = 5.0
    t = kit.blank(size + 2 * pad, (top if top is not None else size + pad) + pad)
    d = t.poly(ui.cut_box(pad, pad, pad + size, pad + size, 3.2, 0, 3.2, 0))
    t.glow(d, 3.0, c(colour), 0.35)
    t.paint(d - 1.1, c(h.STROKE))
    t.paint(d, t.ramp(h.mix(colour, "#FFFFFF", 0.45), colour, (t.y - pad) / size))
    t.paint(np.maximum(d + 1.2, (t.x - pad) + (t.y - pad) - size * 0.8), c("#FFFFFF"), 0.35)
    h.place(st, t, x - pad, cy - size / 2 - pad)


def bus(st, x, y, w, hh, cuts, colours, p):
    """The bar: the whole generation as one conduit, a light for each machine and Power's for the rest, which charges
    the battery. Its cuts are upright, so a share reads true at the handle; its ends wear the kit's cut."""
    pad, rim = 16.0, 2.0
    t = kit.blank(w + 2 * pad, hh + 2 * pad)
    d = t.poly(ui.cut_box(pad, pad, pad + w, pad + hh, 5.0, 1.5, 5.0, 1.5))
    t.glow(d, 5.0, ui.BLACK, 0.35)
    t.paint(d, c(p["channel"]))
    edges = (0.0, cuts[0], cuts[1], 1.0)
    across = np.clip(1 - np.abs(2 * (t.y - pad) / hh - 1), 0, 1)
    lights = []
    for i, colour in enumerate(colours):
        a, b = (pad + rim + (w - 2 * rim) * e for e in edges[i:i + 2])
        if b - a < 1.0:
            continue
        a, b = a + (1.0 if edges[i] > 0 else 0.0), b - (1.0 if edges[i + 1] < 1 else 0.0)
        lights.append((np.maximum(d + rim, np.maximum(a - t.x, t.x - b)), c(colour), b))
    for lit, colour, _ in lights:  # every glow first, so no light is clouded by its neighbour's
        t.glow(lit, hh * 0.5, colour, 0.42)
    for lit, colour, b in lights:
        inside = np.clip(0.5 - lit * ui.K, 0, 1)
        t.paint(lit, t.ramp(colour * 0.66, 0.86 * colour + 0.14 * ui.WHITE, across ** 1.2))
        ui.over(t.px, ui.WHITE, inside * np.exp(-((t.y - pad - hh * 0.3) / (hh * 0.1)) ** 2) * 0.22)  # the sheen
        ui.over(t.px, ui.WHITE, inside * np.clip(1 + (t.x - b) / (hh * 1.6), 0, 1) * 0.3)  # brightest where it arrives
    t.line(d, 0.9, c(p["edge"]), 0.95)
    for share in (0.25, 0.5, 0.75):  # a quarter's ticks under the bar: a quarter is the least a machine runs at
        tx = pad + rim + (w - 2 * rim) * share
        t.paint(np.maximum(np.abs(t.x - tx) - 0.5, np.abs(t.y - (pad + hh + 5.5)) - 2.0), c(p["faint"]), 0.8)
    h.place(st, t, x - pad, y - pad)


def grip(st, cx, cy):
    """A handle: a brass slider upright over the bar, the one thing on it a thumb takes."""
    gw, gh, pad = 9.0, 40.0, 8.0
    t = kit.blank(gw + 2 * pad, gh + 2 * pad)
    d = t.poly(ui.cut_box(pad, pad, pad + gw, pad + gh, 2.5, 2.5, 2.5, 2.5))
    t.glow(d, 4.0, ui.BLACK, 0.5)
    t.paint(d - 1.2, c(h.STROKE))
    t.paint(d, t.ramp("#FFFDF2", h.PALE[POWER], (t.y - pad) / gh))
    t.paint(np.maximum(d + 1.0, pad + gw * 0.55 - t.x), c(h.DEEP[POWER]), 0.28)  # its shaded side
    for dy in (-4.0, 0.0, 4.0):  # three notches where the thumb sits
        t.paint(np.maximum(np.abs(t.x - (pad + gw / 2)) - 2.6, np.abs(t.y - (pad + gh / 2 + dy)) - 0.55), c(h.DEEP[POWER]), 0.9)
    h.place(st, t, cx - gw / 2 - pad, cy - gh / 2 - pad)


def breath(st, cx, cy, rx, ry, colour, strength):
    """The room lit by its own conduit: one soft warm light on the panel, behind the bar."""
    t = kit.blank(2 * rx, 2 * ry)
    d = np.hypot((t.x - rx) / rx, (t.y - ry) / ry)
    ui.over(t.px, c(colour), (strength * np.clip(1 - d, 0, 1) ** 1.6).astype(np.float32))
    h.place(st, t, cx - rx, cy - ry)


def thumb(st, x, y0, y1, p):
    t = kit.blank(5, y1 - y0)
    t.paint(t.poly(ui.cut_box(1, 0, 4, y1 - y0, 1.2, 1.2, 1.2, 1.2)), c(p["facet"]), 0.55)
    h.place(st, t, x, y0)


def battery_plate(st, x, y, p, stored):
    """The battery as the Breaker's screen shows it: its mark, a charge bar, what it holds against its cap."""
    sv.box(st, x - 8, y - 7, 262, 28, p)
    st.icon("Battery", x + 11, y + 7, 22.0)
    kit.bar(st, x + 27, y + 2, 132, 10.0, stored / CAP_KWH, p, POWER)
    st.text(x + 167, y + 1, 13, f"{stored} / {CAP_KWH} kWh", POWER)


def machine_row(st, top, p, row):
    name, colour, reading, speed, share, (no_minus, no_plus) = row
    chip(st, BX, top + 11, colour)
    word(st, BX + 18, top + 11, 14, name, p["text"])
    if reading:  # what it draws against its rating, in Power's yellow; its speed beside it
        runs(st, BX + 18, top + 36, SMALL, ((reading, POWER), ("·", p["faint"]), (speed, p["soft"])))
    else:
        word(st, BX + 18, top + 36, SMALL, "Idle", p["soft"])  # the room's faint is under 4.5 here: dots only
    kit.button(st, MINUS, top, ROW_H, ROW_H, "−", p, "disabled" if no_minus else "rest")
    word(st, SHARE, top + ROW_H / 2, 14, share, p["text"], "CENTER")
    kit.button(st, PLUS, top, ROW_H, ROW_H, "+", p, "disabled" if no_plus else "rest")


def battery_row(st, x, top, p, state, right):
    """The battery's row, reworked: its mark for a chip, a charge bar beside its name, its kWh against its cap in
    Power's yellow, the work it holds, and its share of the bar: the rest."""
    stored, share, holds = state["battery"]
    st.icon("Battery", x + 7, top + 11, 22.0)
    word(st, x + 23, top + 11, 14, "Battery", p["text"])
    kit.bar(st, x + 84, top + 6, 150, 10.0, stored / CAP_KWH, p, POWER)
    runs(st, x + 23, top + 36, SMALL, ((f"{stored} / {CAP_KWH} kWh", POWER), ("·", p["faint"]),
                                       (f"holds {holds} of work", p["soft"])))
    word(st, right, top + ROW_H / 2, 14, share, POWER, "CENTER")


def stage_over(world):
    st = kit.Stage.__new__(kit.Stage)
    st.w, st.h, st.items = W, H, []
    st.px = world
    return st


def power(p, world, key):
    """The Power screen as Faber built it, in the machine room's colours."""
    s = STATES[key]
    st = stage_over(world)
    kit.panel(st, PX, PY, PW, PH, p)
    word(st, PX + 17, PY + 29, 17, "Power", p["text"])
    kit.button(st, PX + 520, PY + 4, 72, 44, "Close", p)
    # the head: generation in Power's yellow; demand in the caution's colour when Auto can't meet it
    cy = AUTO[1] + 25
    runs(st, BX, cy, 14, (("Generation", p["text"]), ("21 kW", POWER), ("·", p["faint"]), ("Demand", p["text"]),
                          ("30 kW", OVER if s["warn"] else p["text"])))
    if s["warn"]:  # the battery's mark beside the words, so the colour isn't the caution's only sign
        st.icon("Battery", BX + 8, cy + 22, 17.0)
        word(st, BX + 21, cy + 22, SMALL, s["over"], OVER)
    else:
        word(st, BX, cy + 22, SMALL, s["over"], p["soft"])
    if s["auto"]:  # Auto on is the screen's one filled thing: the plant runs itself
        h.main_button(st, *AUTO, "Auto", p)
    else:
        kit.button(st, *AUTO, "Auto", p)
    # the bar, in a well of its own
    tx, ty, tw, th = TRACK
    breath(st, PX + PW / 2, ty + th / 2, 290.0, 84.0, EMBER, 0.16)
    st.lay("ButtonFill", BX, ty - 13, BR - BX, th + 28, tint=p["well"], alpha=0.6)
    st.lay("ButtonEdge", BX, ty - 13, BR - BX, th + 28, tint=p["edge"], alpha=0.4)
    lights = (BREAKER, POWER if not s["rows"][1][2] else TRAINING, POWER)  # an idle machine's share is the battery's
    bus(st, tx, ty, tw, th, s["cuts"], lights, p)
    for cut in sorted(set(s["cuts"])):
        grip(st, tx + 2.0 + (tw - 4.0) * cut, ty + th / 2)
    # the machines, and the battery's row under the list's foot
    for top, row in zip(ROWS, s["rows"]):
        machine_row(st, top, p, row)
    foot = PY + PH - 5.0
    chip(st, BX + 1, ROWS[2] + 11, POWER, 12.0, top=foot - (ROWS[2] + 5))
    thumb(st, 686.0, ROWS[0] + 1, ROWS[0] + 84, p)
    return h.bytes8(h.halve(st.px)), st.items


def row_strip(p, key):
    """The battery's row as it reads once the list is scrolled to it, at the list's own width."""
    st = kit.Stage(W, 66.0, h.GROUND)
    kit.panel(st, PX, 2, PW, 62, p)
    battery_row(st, BX, 8.0, p, STATES[key], SHARE)
    return h.bytes8(h.halve(st.px)), st.items


def head_strip(p, key):
    """Proposed: the battery in the screen's head, as on the Breaker's, so it's read without a scroll."""
    st = kit.Stage(W, 66.0, h.GROUND)
    kit.panel(st, PX, 6, PW, 120, p)
    word(st, PX + 17, 6 + 29, 17, "Power", p["text"])
    battery_plate(st, PX + 196, 6 + 15, p, STATES[key]["battery"][0])
    kit.button(st, PX + 520, 6 + 4, 72, 44, "Close", p)
    return h.bytes8(h.halve(st.px)), st.items


def bar_strip(p):
    """The bar with both machines at work, which neither still shows: the three lights side by side."""
    st = kit.Stage(W, 70.0, h.GROUND)
    kit.panel(st, PX, 2, PW, 66, p)
    tx, ty, tw, th = TRACK[0], 23.0, TRACK[2], TRACK[3]
    breath(st, PX + PW / 2, ty + th / 2, 290.0, 60.0, EMBER, 0.16)
    st.lay("ButtonFill", BX, ty - 13, BR - BX, th + 28, tint=p["well"], alpha=0.6)
    st.lay("ButtonEdge", BX, ty - 13, BR - BX, th + 28, tint=p["edge"], alpha=0.4)
    cuts = (0.5, 0.75)
    bus(st, tx, ty, tw, th, cuts, (BREAKER, TRAINING, POWER), p)
    for cut in cuts:
        grip(st, tx + 2.0 + (tw - 4.0) * cut, ty + th / 2)
    return h.bytes8(h.halve(st.px)), st.items


def words_strip(p):
    """Each coloured word this room may hold, on the room's own panel, to judge them side by side."""
    st = kit.Stage(W, 44.0, h.GROUND)
    kit.panel(st, 0, 2, W, 40, p)
    x = runs(st, 16, 22, 12, (("21 kW", POWER), ("19 / 60 kWh", POWER))) + 14
    st.icon("Battery", x + 8, 22, 17.0)
    x = runs(st, x + 21, 22, 12, (("The battery covers the rest", OVER),)) + 16
    for name, colour in (("Void Breaker", BREAKER), ("Training machine", TRAINING), ("Battery", POWER)):
        chip(st, x, 22, colour)
        x = runs(st, x + 18, 22, 12, ((name, p["text"]),)) + 14
    runs(st, x, 22, 12, (("The Void Breaker at 25%", p["soft"]), ("Idle", p["soft"])))
    return h.bytes8(h.halve(st.px)), st.items


def luminance(code):
    v = c(code).astype(np.float64)
    v = np.where(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055) ** 2.4)
    return float(v @ (0.2126, 0.7152, 0.0722))


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def measures(p):
    """Each word's contrast on the panel's top, where the head stands, and on its foot's side, where the rows do."""
    for ground_name, ground in (("the panel's top", p["panel"][0]), ("its middle", h.mix(*p["panel"], 0.5))):
        said = ", ".join(f"{name} {contrast(colour, ground):.1f}" for name, colour in (
            ("text", p["text"]), ("soft", p["soft"]), ("faint", p["faint"]), ("Power", POWER), ("the caution", OVER),
            ("the Breaker's light", BREAKER), ("the Training machine's", TRAINING)))
        print(f"contrast on {ground_name} ({ground}): {said}")
    print(f"ink on the filled Auto: {contrast(h.INK, POWER):.1f}")


NOTES = (
    "Delivery 3 (the director, 2026-11-15: \"we need to add more colors and appealing to each old full dark ui\"; \"the "
    "battery text need a rework also like it energy colors\"): the bays' screen, which since TR18 is Power, in the machine "
    "room's Dynamo, vivid. The layout is Faber's grey build, unchanged; the words are the build's own.",
    "The room is amber iron, and the bar is the one live thing in it: the whole generation as a conduit in a well, a light "
    "for each machine and Power's yellow for the rest, which charges the battery. The machines are the cool lights in a "
    "warm room: the Void Breaker the void's violet, the Training machine a cyan no rarity and no currency wears. A row's "
    "chip is a small cut stone of its light. An idle machine's share is drawn as the battery's, as in the build.",
    "The handles are brass sliders, upright, with a thumb's notches; quarter ticks stand under the bar (a quarter is the "
    "least a machine runs at). Auto, on, is the screen's one filled thing, in Power's yellow with ink words; off, it's a "
    "plain button and the handles are what's live. A stuck - or + is the kit's disabled button.",
    "Words wear their meaning's colour: kW and kWh in Power's yellow, the rest ivory. Under Auto, demand over generation "
    "wears the caution's orange, with the battery's mark beside \"The battery covers the rest\" so the colour isn't its only "
    "sign; under a split the player made, the fact stands plainly in soft text, as research ruled on the block.",
    "Stand-ins: Blender's face for the game's text; the world behind is the still's own.",
)
SPLIT_NOTES = (
    "A split the player made: the Void Breaker held to a quarter, the rest pouring into the battery. Auto is off, so "
    "nothing on the screen is filled, and the bar and its handle carry it. Demand over generation isn't a caution here, "
    "since the player chose it: the number is ivory and the line under it is soft.",
    "For research and Faber, tier 2, not built: the battery's row stands under the list's foot on a phone (only its chip's "
    "top shows), so the battery, the screen's one store, is read only after a scroll. The strip offers it in the head, on "
    "the same plate and in the same place as on the Breaker's screen: its mark, a charge bar, kWh against its cap. Its "
    "row would then keep the work it holds and its share, or leave the list. The layout above is the build's, untouched.",
)


def sheet(out, name, title, labels, before, after, notes, strips):
    """Today beside vivid, then each strip under its caption, then the notes."""
    ui.K = 2
    m, gap = 20.0, 16.0
    lines = [line for note in notes for line in textwrap.wrap(note, 300)]
    extra = sum(14.0 + shot[0].shape[0] / 2 + 8.0 for _, shot in strips)
    sh = ui.Sheet(2 * m + 2 * W + gap, 62 + H + 14 + extra + len(lines) * 15 + 14, h.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(m, 14, 17, title, h.HEAD)
    for i, label in enumerate(labels):
        t.text(m + i * (W + gap), 44, 11, label, h.HEAD)
    kit.put(sh, before, m * 2, 62 * 2)
    h.add(sh, *after, m + W + gap, 62)
    y = 62 + H + 14
    for caption, shot in strips:
        t.text(m, y, 10, caption, h.NOTE)
        h.add(sh, *shot, m, y + 14)
        y += 14.0 + shot[0].shape[0] / 2 + 8.0
    for i, line in enumerate(lines):
        t.text(m, y + i * 15, 10, line, h.NOTE)
    kit.finish(sh, out / name)


def world(key):
    """The game's own world behind the screen: Faber's still, at the sheet's size and at the kit's."""
    still = rs.load(STILLS / f"power_{key}.png")
    small = h.bytes8(h.resize(still, round(W * 2), round(H * 2)))
    big = np.ascontiguousarray(h.resize(still, round(W * K4), round(H * K4)))
    big[..., 3] = 1.0
    return small, big


def main():
    out = bl.out_dir()
    h.stage("started")
    sv.slices()
    p = ROOM
    measures(p)
    shots, befores = {}, {}
    for key in STATES:
        befores[key], big = world(key)
        shots[key] = power(p, big, key)
        del big
        h.stage(f"Power, {key}")
    strips = {
        "auto": (("The battery's row, once the list is scrolled to it: its mark, a charge bar, kWh against its cap, the work it holds:", row_strip(p, "auto")),
                 ("The bar with both machines at work, which neither still shows: the Void Breaker at 50%, the Training machine at 25%, the rest charging:", bar_strip(p)),
                 ("The coloured words this room may hold, on its panel:", words_strip(p))),
        "split": (("The battery's row, once the list is scrolled to it; its share is the rest:", row_strip(p, "split")),
                  ("Proposed (tier 2, not built): the battery in the head, on the Breaker's own plate:", head_strip(p, "split"))),
    }
    kit.IMAGES.clear()
    labels = ("Today: Faber's retake of the grey build (TR18)", "Dynamo, vivid: the same screen in the machine room's colours")
    sheet(out, "vivid3_power.png", "Grow your Anime: Power, today and in Dynamo vivid. Auto, the battery covering the rest",
          labels, h.floats(befores["auto"]), shots["auto"], NOTES, strips["auto"])
    h.stage("Power's sheet")
    sheet(out, "vivid3_power_split.png", "Grow your Anime: Power, today and in Dynamo vivid. A split the player made",
          labels, h.floats(befores["split"]), shots["split"], SPLIT_NOTES, strips["split"])
    h.stage("the split's sheet")


if __name__ == "__main__":
    main()
