"""AR51, the blockout's second half (docs/asset-requests.md, AR51): the Stone Condenser's share on the Power screen: its
colour, its chip and its light beside the Void Breaker's silver, the Training machine's cyan and the battery's yellow,
under Auto and in a split, on a phone. Drawn with power_vivid_sheet.py's own parts (the bar as AR12 cut it in Eclipse,
the kit's slices) on the system slab AR40's C gave the screen (Config.UIKit, System); the layout is TR18's, with the
battery's plate in the head. The numbers are made up for the picture. Text is Blender's face.

    blender -b --factory-startup --python-exit-code 1 --python tools/blender/condenser_power.py -- <abs out dir>

Writes condenser_power.png. The world behind is Faber's stills of TR18 (build/captures/tr18), cut as
power_vivid_sheet.py's head says.
"""
import sys
import textwrap
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import power_vivid_sheet as pv  # noqa: E402

h, sv, kit, ui, rs, c = pv.h, pv.sv, pv.kit, pv.ui, pv.rs, pv.c
W, H, K4 = pv.W, pv.H, pv.K4
PX, PY, PW, PH, BX, BR = pv.PX, pv.PY, pv.PW, pv.PH, pv.BX, pv.BR
POWER, TRAINING, BREAKER = pv.POWER, pv.TRAINING, "#E6ECF7"      # Eclipse: the Breaker's light is silver
# The system slab (Config.UIKit, System): the screen's window since AR40's C. The bar keeps its own dark bed (Config.Hud).
ROOM = dict(pv.ROOM, panel=("#34606C", "#2A4E5A"), edge="#E2CFA4", facet="#A9DCD4", glint="#F2FFF9", text="#FFF6E2",
            soft="#D9E8E2", faint="#A9C0BC", button=("#447480", "#366270"), pressed=("#2A4E5A", "#34606C"),
            ground="#3E6872", channel="#080705", well="#0E0C09")
# The Condenser's colour, three ways
COLOURS = (("Rose", "#FF8FAE", "a rose no other light on the screen is near"),
           ("Seam", "#FFAE78", "the forge stones' own seam (AR31), what the machine makes"),
           ("Jade", "#74E3A8", "a green between the Training machine's cyan and Power's yellow"))
# Each still's plant: the bar's cuts, the head's second line, Auto, and each machine's reading, speed, share and
# stuck - and +
STATES = {
    "auto": dict(cuts=(0.75, 0.75, 1.0), over="The battery covers the rest", warn=True, auto=True, demand="40 kW",
                 rows=(("Void Breaker", "30 / 30 kW", "100%", "75%", (False, True)),
                       ("Training machine", "", "", "0%", (True, True)),
                       ("Stone Condenser", "10 / 10 kW", "100%", "25%", (False, True))), stored=19),
    "split": dict(cuts=(0.4, 0.6, 0.8), over="A split you made", warn=False, auto=False, demand="52 kW",
                  rows=(("Void Breaker", "8.4 / 30 kW", "28%", "40%", (False, False)),
                        ("Training machine", "4.2 / 12 kW", "35%", "20%", (False, False)),
                        ("Stone Condenser", "4.2 / 10 kW", "42%", "20%", (False, False))), stored=18),
}
HEX = True     # the Condenser's chip six-sided, a cup of its Comb; False: the other chips' cut stone


def stills():
    """power_vivid_sheet's stills, cut again from Faber's captures when the scratch folder is gone."""
    pv.STILLS.mkdir(parents=True, exist_ok=True)
    for key in ("auto", "split"):
        if not (pv.STILLS / f"power_{key}.png").exists():
            px = rs.load(h.REPO / "build" / "captures" / "tr18" / f"retake_{key}.png")
            rs.save(px[19:19 + 430, 11:11 + 936].copy(), pv.STILLS / f"power_{key}.png")


def cup_chip(st, x, cy, colour, size=13.0):
    """The Condenser's key to its light: a six-sided cup of its Comb, in the chips' own make."""
    pad, r = 5.0, size / 2
    t = kit.blank(size + 2 * pad, size + 2 * pad)
    mid = pad + r
    d = t.poly([(mid + r * np.cos(np.radians(a)), mid + r * np.sin(np.radians(a))) for a in range(0, 360, 60)])
    t.glow(d, 3.0, c(colour), 0.35)
    t.paint(d - 1.1, c(h.STROKE))
    t.paint(d, t.ramp(h.mix(colour, "#FFFFFF", 0.45), colour, (t.y - pad) / size))
    t.paint(d + 3.4, c(h.STROKE), 0.5)                                # the cup's dark middle
    t.paint(d + 4.4, t.ramp(colour, h.mix(colour, "#FFFFFF", 0.5), (t.y - pad) / size))
    h.place(st, t, x - pad, cy - size / 2 - pad)


def bus(st, x, y, w, hh, cuts, colours, p):
    """power_vivid_sheet.bus for any count of lights: the whole generation as one conduit, a light a machine and
    Power's for the rest."""
    pad, rim = 16.0, 2.0
    t = kit.blank(w + 2 * pad, hh + 2 * pad)
    d = t.poly(ui.cut_box(pad, pad, pad + w, pad + hh, 5.0, 1.5, 5.0, 1.5))
    t.glow(d, 5.0, ui.BLACK, 0.35)
    t.paint(d, c(p["channel"]))
    edges = (0.0, *cuts, 1.0)
    across = np.clip(1 - np.abs(2 * (t.y - pad) / hh - 1), 0, 1)
    lights = []
    for i, colour in enumerate(colours):
        a, b = (pad + rim + (w - 2 * rim) * e for e in edges[i:i + 2])
        if b - a < 1.0:
            continue
        a, b = a + (1.0 if edges[i] > 0 else 0.0), b - (1.0 if edges[i + 1] < 1 else 0.0)
        lights.append((np.maximum(d + rim, np.maximum(a - t.x, t.x - b)), c(colour), b))
    for lit, colour, _ in lights:
        t.glow(lit, hh * 0.5, colour, 0.42)
    for lit, colour, b in lights:
        inside = np.clip(0.5 - lit * ui.K, 0, 1)
        t.paint(lit, t.ramp(colour * 0.66, 0.86 * colour + 0.14 * ui.WHITE, across ** 1.2))
        ui.over(t.px, ui.WHITE, inside * np.exp(-((t.y - pad - hh * 0.3) / (hh * 0.1)) ** 2) * 0.22)
        ui.over(t.px, ui.WHITE, inside * np.clip(1 + (t.x - b) / (hh * 1.6), 0, 1) * 0.3)
    t.line(d, 0.9, c("#9A7A22"), 0.95)
    for share in (0.25, 0.5, 0.75):
        tx = pad + rim + (w - 2 * rim) * share
        t.paint(np.maximum(np.abs(t.x - tx) - 0.5, np.abs(t.y - (pad + hh + 5.5)) - 2.0), c("#8F7F52"), 0.8)
    h.place(st, t, x - pad, y - pad)


def lights(state, colour):
    idle = not state["rows"][1][1]
    return (BREAKER, POWER if idle else TRAINING, colour, POWER)


def well(st, ty, th, p):
    pv.breath(st, PX + PW / 2, ty + th / 2, 290.0, 60.0, pv.EMBER, 0.16)
    st.lay("ButtonFill", BX, ty - 13, BR - BX, th + 28, tint=p["well"], alpha=0.85)
    st.lay("ButtonEdge", BX, ty - 13, BR - BX, th + 28, tint="#9A7A22", alpha=0.5)


def row(st, top, p, r, colour, hexa=False, cut=None):
    name, reading, speed, share, (no_minus, no_plus) = r
    if hexa:
        cup_chip(st, BX - 0.5, top + 11, colour)
    else:
        pv.chip(st, BX, top + 11, colour, top=cut)
    if cut is not None:
        return
    pv.word(st, BX + 18, top + 11, 14, name, p["text"])
    if reading:
        pv.runs(st, BX + 18, top + 36, pv.SMALL, ((reading, POWER), ("·", p["faint"]), (speed, p["soft"])))
    else:
        pv.word(st, BX + 18, top + 36, pv.SMALL, "Idle", p["soft"])
    kit.button(st, pv.MINUS, top, pv.ROW_H, pv.ROW_H, "−", p, "disabled" if no_minus else "rest")
    pv.word(st, pv.SHARE, top + pv.ROW_H / 2, 14, share, p["text"], "CENTER")
    kit.button(st, pv.PLUS, top, pv.ROW_H, pv.ROW_H, "+", p, "disabled" if no_plus else "rest")


def screen(p, world, key, colour):
    """The Power screen with a third machine: TR18's layout, the battery's plate in the head."""
    s = STATES[key]
    st = pv.stage_over(world)
    kit.panel(st, PX, PY, PW, PH, p)
    pv.word(st, PX + 17, PY + 29, 17, "Power", p["text"])
    pv.battery_plate(st, PX + 190, PY + 15, p, s["stored"])
    kit.button(st, PX + 520, PY + 4, 72, 44, "Close", p)
    cy = pv.AUTO[1] + 25
    pv.runs(st, BX, cy, 14, (("Generation", p["text"]), ("21 kW", POWER), ("·", p["faint"]), ("Demand", p["text"]),
                             (s["demand"], pv.OVER if s["warn"] else p["text"])))
    pv.word(st, BX, cy + 22, pv.SMALL, s["over"], pv.OVER if s["warn"] else p["soft"])
    if s["auto"]:
        h.main_button(st, *pv.AUTO, "Auto", p)
    else:
        kit.button(st, *pv.AUTO, "Auto", p)
    tx, ty, tw, th = pv.TRACK
    well(st, ty, th, p)
    bus(st, tx, ty, tw, th, s["cuts"], lights(s, colour), p)
    for cut in sorted(set(s["cuts"])):
        if cut < 1.0 or not s["auto"]:
            pv.grip(st, tx + 2.0 + (tw - 4.0) * cut, ty + th / 2)
    for top, r, tint in zip(pv.ROWS, s["rows"], (BREAKER, TRAINING)):
        row(st, top, p, r, tint)
    foot = PY + PH - 5.0
    row(st, pv.ROWS[2], p, s["rows"][2], colour, cut=foot - (pv.ROWS[2] + 5))   # the third row, under the list's foot
    pv.thumb(st, 686.0, pv.ROWS[0] + 1, pv.ROWS[0] + 70, p)
    return h.bytes8(h.halve(st.px)), st.items


def strip(p, key, colour, hexa):
    """A colour on trial: the bar as the state has it, and the list scrolled to its foot, the Condenser's row whole."""
    s = STATES[key]
    st = kit.Stage(W, 132.0, h.GROUND)
    kit.panel(st, PX, 2, PW, 128, p)
    tx, ty, tw, th = pv.TRACK[0], 23.0, pv.TRACK[2], pv.TRACK[3]
    well(st, ty, th, p)
    bus(st, tx, ty, tw, th, s["cuts"], lights(s, colour), p)
    for cut in sorted(set(s["cuts"])):
        if cut < 1.0 or not s["auto"]:
            pv.grip(st, tx + 2.0 + (tw - 4.0) * cut, ty + th / 2)
    row(st, 72.0, p, s["rows"][2], colour, hexa=hexa)
    return h.bytes8(h.halve(st.px)), st.items


def deuteranopia(shot):
    px, items = shot
    rgb = px[..., :3].astype(np.float32) / 255
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    lin = np.clip(lin @ h.DEUTERANOPIA.T, 0, 1)
    out = px.copy()
    out[..., :3] = (np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055) * 255 + 0.5).astype(np.uint8)
    return out, items


NOTES = (
    "The Stone Condenser as a third share on the Power screen (AR51). The bar's order is the machines': the Void Breaker, "
    "the Training machine, the Stone Condenser, and what's left charges the battery. Top: the screen under Auto (the "
    "Training machine idle, so two lights) and in a split with all three at work (four lights, three handles), in the "
    "first colour. Under them each colour on trial: the bar under Auto and in the split, with the Condenser's row as the "
    "list shows it once scrolled, then the same as deuteranopia sees it.",
    "On a phone the list holds two rows over its foot, so the Condenser's row is the third and only its chip's top "
    "shows until a scroll: the build's layout, drawn as it would stand. The chip is shown both ways: six-sided, a cup "
    "of its Comb (left column), and the other two's cut stone (right column). Stand-ins: Blender's face for the game's "
    "text; the numbers are made up for the picture; the window is the system slab's colours drawn with the kit's "
    "slices, not a capture.",
)


def main():
    out = bl.out_dir()
    h.stage("started")
    stills()
    sv.slices()
    p = ROOM
    first = COLOURS[0][1]
    befores, shots = {}, {}
    for key in STATES:
        befores[key], big = pv.world(key)
        shots[key] = screen(p, big, key, first)
        del big
        h.stage(f"Power, {key}")
    rows = []
    for name, colour, why in COLOURS:
        made = [strip(p, key, colour, hexa) for key, hexa in (("auto", True), ("split", False))]
        rows.append((f"{name} {colour}: {why}. Under Auto, the chip six-sided; in the split, the chip a cut stone", made))
        rows.append((f"{name}, as deuteranopia sees it", [deuteranopia(s) for s in made]))
        h.stage(name)
    kit.IMAGES.clear()
    ui.K = 2
    m, gap = 20.0, 16.0
    lines = [line for note in NOTES for line in textwrap.wrap(note, 300)]
    sh = ui.Sheet(2 * m + 2 * W + gap, 62 + H + 14 + len(rows) * (14.0 + 132.0 + 8.0) + len(lines) * 15 + 14, h.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(m, 14, 17, "Grow your Anime, AR51: the Stone Condenser's share on the Power screen, its colour three ways", h.HEAD)
    for i, label in enumerate((f"Auto: the Breaker and the Condenser share by their demand ({COLOURS[0][0]})",
                               f"A split the player made, all three at work ({COLOURS[0][0]})")):
        t.text(m + i * (W + gap), 44, 11, label, h.HEAD)
    for i, key in enumerate(STATES):
        h.add(sh, *shots[key], m + i * (W + gap), 62)
    y = 62 + H + 14
    for caption, made in rows:
        t.text(m, y, 10, caption, h.NOTE)
        for i, shot in enumerate(made):
            h.add(sh, *shot, m + i * (W + gap), y + 14)
        y += 14.0 + 132.0 + 8.0
    for i, line in enumerate(lines):
        t.text(m, y + i * 15, 10, line, h.NOTE)
    kit.finish(sh, out / "condenser_power.png")
    h.stage("the sheet")


if __name__ == "__main__":
    main()
