"""AR12, Power's cut images (docs/asset-requests.md, AR12, "Power's cut images, in Eclipse"): the bar research accepted
on power_vivid_sheet.py's sheets, cut into the images the build stacks, with the Void Breaker's light in Eclipse's
silver (the palette's pick, A). The machines' room stays "Dynamo, vivid".

Each image comes from a function of its own here. Nothing of a capture is in one, and no word: the sheet's captions
are Blender's face, on the sheet only.

Writes into the handoff folder: images/Power*.png, power_images.json (sizes, slices, the lights' colours down their
height, how the bar is stacked) and power_images.png, the images beside the bar stacked from them as the engine
stacks them and the bar as the accepted sheet drew it. The check copies (each image over dark, whole and at 64 pixels)
go to build/scratch/modulo/power_images/.

    blender -b --factory-startup --python tools/blender/power_images.py -- build/handoff/UI/hud/colour [images|sheet]
"""
import json
import math
import sys
import textwrap
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import power_vivid_sheet as pv  # noqa: E402

h, kit, ui, rs, c = pv.h, pv.kit, pv.ui, pv.rs, pv.c
K4 = pv.K4
ROOM = pv.ROOM
POWER, TRAINING, EMBER, OVER = pv.POWER, pv.TRAINING, pv.EMBER, pv.OVER
BREAKER = "#E6ECF7"  # Eclipse: the Breaker's light is silver (palette_compose_sheet.py, A)
LIGHTS = {"Breaker": BREAKER, "Training": TRAINING, "Battery": POWER}
CHECK = h.REPO / "build" / "scratch" / "modulo" / "power_images"

HIGH = 24.0  # the bar's height
ENDS = (5.0, 1.5, 5.0, 1.5)  # its cut corners, clockwise from the top left
RIM = 2.0  # the dark channel round the lights
GAP = 1.0  # the channel shown each side of a cut between two lights
SLICE = 8.0  # a slice's corner, past every cut
SHADOW, GLOW = 16.0, 32.0  # how far the channel's shadow and a light's glow reach past their boxes
GLOW_ALPHA, EDGE_ALPHA = 0.42, 0.95
SHEEN = (0.3, 0.1, 0.22)  # a pale band across a light: where down the bar, how wide, how strong
ARRIVE = (HIGH * 1.6, 0.3)  # a light is brightest where it arrives: over this many points, up to this much white
TICKS = ((0.25, 0.5, 0.75), (1.0, 4.0), 3.5, 0.8)  # the quarters; a tick's size; under the bar by; its alpha, in faint
STOPS = 17  # a light's colours down the bar, for a UIGradient (20 at most)
GRIP = (9.0, 40.0)
CHIP = 12.0
EMBER_SIZE, EMBER_ALPHA = (580.0, 168.0), 0.16


def box(t, pad, wide=2 * SLICE + 8, high=HIGH):
    """The bar's outline on a tile, as a distance."""
    return t.poly(ui.cut_box(pad, pad, pad + wide, pad + high, *ENDS))


def nine(pad=0.0):
    return (SLICE + pad,) * 4


# --- the images, one function each ----------------------------------------------------------------------------------

def channel():
    """The conduit's dark bed with its shadow under it: white, so the room's channel colour tints it; the shadow is
    black and stays black."""
    t = kit.blank(2 * SLICE + 8 + 2 * SHADOW, HIGH + 2 * SHADOW)
    d = box(t, SHADOW)
    t.glow(d, 5.0, ui.BLACK, 0.35)
    t.paint(d, ui.WHITE)
    kit.keep("PowerBusChannel", t, "channel", nine(SHADOW), SHADOW, "the bar's bed, under everything; sliced")


def glow():
    """A light's glow on the iron round it: soft, white, tinted its light's colour."""
    wide, high = 2 * SLICE + 8, HIGH - 2 * RIM
    t = kit.blank(wide + 2 * GLOW, high + 2 * GLOW)
    d = t.poly(ui.cut_box(GLOW, GLOW, GLOW + wide, GLOW + high))
    t.glow(d, HIGH * 0.5, ui.WHITE, 1.0)
    kit.keep("PowerBusGlow", t, "its light's colour", nine(GLOW), GLOW,
             f"on each light's own box, under every light, at {GLOW_ALPHA}; sliced")


def light():
    """The lights' shape: the bar's outline drawn in by the rim, white. A light is this image at the bar's whole size
    behind an upright window, so its ends wear the bar's cuts and its cuts stay straight."""
    t = kit.blank(2 * SLICE + 8, HIGH)
    t.paint(box(t, 0.0) + RIM, ui.WHITE)
    kit.keep("PowerBusLight", t, None, nine(), 0.0,
             "a light: the bar's whole size, shown through its segment's window, coloured by its gradient; sliced")


def edge():
    """The bar's outline, a thin line over the lights: white, tinted the room's edge."""
    t = kit.blank(2 * SLICE + 8, HIGH)
    t.line(box(t, 0.0), 0.9, ui.WHITE)
    kit.keep("PowerBusEdge", t, "edge", nine(), 0.0, f"over the lights, at {EDGE_ALPHA}; sliced")


def handle():
    """A handle: a brass slider upright over the bar, with a thumb's three even notches."""
    (gw, gh), pad = GRIP, 8.0
    t = kit.blank(gw + 2 * pad, gh + 2 * pad)
    d = t.poly(ui.cut_box(pad, pad, pad + gw, pad + gh, 2.5, 2.5, 2.5, 2.5))
    t.glow(d, 4.0, ui.BLACK, 0.5)
    t.paint(d - 1.2, c(h.STROKE))
    t.paint(d, t.ramp("#FFFDF2", h.PALE[POWER], (t.y - pad) / gh))
    t.paint(np.maximum(d + 1.0, pad + gw * 0.55 - t.x), c(h.DEEP[POWER]), 0.28)  # its shaded side
    for dy in (-4.0, 0.0, 4.0):
        t.paint(np.maximum(np.abs(t.x - (pad + gw / 2)) - 2.6, np.abs(t.y - (pad + gh / 2 + dy)) - 0.55), c(h.DEEP[POWER]), 0.9)
    kit.keep("PowerHandle", t, None, None, pad, "a handle's upright, its middle on the cut; its colours are its own")


def chip(name, colour):
    """A row's key to its light on the bar: a small cut stone of the light's colour."""
    pad = 5.0
    t = kit.blank(CHIP + 2 * pad, CHIP + 2 * pad)
    d = t.poly(ui.cut_box(pad, pad, pad + CHIP, pad + CHIP, 3.2, 0, 3.2, 0))
    t.glow(d, 3.0, c(colour), 0.35)
    t.paint(d - 1.1, c(h.STROKE))
    t.paint(d, t.ramp(h.mix(colour, "#FFFFFF", 0.45), colour, (t.y - pad) / CHIP))
    t.paint(np.maximum(d + 1.2, (t.x - pad) + (t.y - pad) - CHIP * 0.8), c("#FFFFFF"), 0.35)
    kit.keep(f"PowerChip{name}", t, None, None, pad, f"the {name} row's chip; its colour is its own")


def ember():
    """The room lit by its own conduit: one soft light, white, tinted the ember's colour. Drawn at a pixel a point: it
    has no edge to keep."""
    w, hh = (v / K4 for v in EMBER_SIZE)
    t = kit.blank(w, hh)
    d = np.hypot((t.x - w / 2) / (w / 2), (t.y - hh / 2) / (hh / 2))
    t.px[..., :3] = 1.0
    t.px[..., 3] = np.clip(1 - d, 0, 1) ** 1.6
    kit.keep("PowerEmber", t, "ember", None, 0.0, f"behind the bar's well, its middle on the bar's, at {EMBER_ALPHA}")


def cut_images():
    channel()
    glow()
    light()
    edge()
    handle()
    chip("Breaker", BREAKER)
    chip("Training", TRAINING)
    ember()
    return ["PowerBusChannel", "PowerBusGlow", "PowerBusLight", "PowerBusEdge", "PowerHandle", "PowerChipBreaker",
            "PowerChipTraining", "PowerEmber"]


# --- a light's colours ----------------------------------------------------------------------------------------------

def light_stops(colour):
    """A light's colours from the bar's top to its foot: dark at the rims, its own colour paled at the middle, the
    sheen's band across it. A UIGradient turned upright holds them."""
    col, out = c(colour).astype(np.float64), []
    for i in range(STOPS):
        t = i / (STOPS - 1)
        across = 1 - abs(2 * t - 1)
        v = col * 0.66 + (0.86 * col + 0.14 - col * 0.66) * across ** 1.2
        a = SHEEN[2] * math.exp(-((t - SHEEN[0]) / SHEEN[1]) ** 2)
        v = v * (1 - a) + a
        out.append([round(t, 4), "#" + "".join(f"{int(round(min(max(x, 0.0), 1.0) * 255)):02X}" for x in v)])
    return out


def stops_rows(colour, rows):
    stops = light_stops(colour)
    at, cols = np.array([s[0] for s in stops]), np.array([c(s[1]) for s in stops])
    y = (np.arange(rows) + 0.5) / rows
    return np.stack([np.interp(y, at, cols[:, k]) for k in range(3)], axis=1).astype(np.float32)[:, None, :]


# --- the bar, stacked as the engine stacks it -----------------------------------------------------------------------

def spans(w, cuts, lit):
    """Each light's left and right on a bar w wide, and its colour."""
    edges, out = (0.0, cuts[0], cuts[1], 1.0), []
    for i, colour in enumerate(lit):
        a, b = (RIM + (w - 2 * RIM) * e for e in edges[i:i + 2])
        a, b = a + (GAP if edges[i] > 0 else 0.0), b - (GAP if edges[i + 1] < 1 else 0.0)
        if b - a >= 1.0:
            out.append((a, b, colour))
    return out


def stacked(st, x, y, w, cuts, lit, p):
    """The bar from its images: the bed, each light's glow, each light through its window with its colours and its
    brighter arriving end, the outline, the quarters' ticks."""
    st.lay("PowerBusChannel", x, y, w, HIGH, tint=p["channel"])
    here = spans(w, cuts, lit)
    for a, b, colour in here:
        st.lay("PowerBusGlow", x + a, y + RIM, b - a, HIGH - 2 * RIM, tint=colour, alpha=GLOW_ALPHA)
    im = kit.IMAGES["PowerBusLight"]
    shape = kit.stretch(im["px"], im["cut"], w, HIGH)
    cols = (np.arange(shape.shape[1]) + 0.5) / K4
    for a, b, colour in here:
        window = ((cols >= a) & (cols < b)).astype(np.float32)[None, :]
        px = shape.copy()
        px[..., :3] = stops_rows(colour, shape.shape[0])
        px[..., 3] *= window
        rs.paste(st.px, px, round(x * K4), round(y * K4))
        px = shape.copy()
        px[..., 3] *= window * (np.clip(1 + (cols - b) / ARRIVE[0], 0, 1) * ARRIVE[1]).astype(np.float32)[None, :]
        rs.paste(st.px, px, round(x * K4), round(y * K4))
    st.lay("PowerBusEdge", x, y, w, HIGH, tint=p["edge"], alpha=EDGE_ALPHA)
    shares, (tw, th), under, alpha = TICKS
    for share in shares:
        t = kit.blank(tw, th)
        t.px[..., :3], t.px[..., 3] = c(p["faint"]), alpha
        h.place(st, t, x + RIM + (w - 2 * RIM) * share - tw / 2, y + HIGH + under)


def ember_lay(st, cx, cy, rx, ry):
    px = np.array(h.resize(kit.IMAGES["PowerEmber"]["px"], round(2 * rx * K4), round(2 * ry * K4)))
    px[..., :3] = c(EMBER)
    px[..., 3] *= EMBER_ALPHA
    rs.paste(st.px, px, round((cx - rx) * K4), round((cy - ry) * K4))


def bar_row(p, cuts, lit, drawn=False):
    """The bar in its well on the room's panel: stacked from the images, or drawn whole as the accepted sheet drew it."""
    st = kit.Stage(pv.W, 70.0, h.GROUND)
    kit.panel(st, pv.PX, 2, pv.PW, 66, p)
    tx, ty, tw, th = pv.TRACK[0], 23.0, pv.TRACK[2], HIGH
    if drawn:
        pv.breath(st, pv.PX + pv.PW / 2, ty + th / 2, 290.0, 60.0, EMBER, EMBER_ALPHA)
    else:
        ember_lay(st, pv.PX + pv.PW / 2, ty + th / 2, 290.0, 60.0)
    st.lay("ButtonFill", pv.BX, ty - 13, pv.BR - pv.BX, th + 28, tint=p["well"], alpha=0.6)
    st.lay("ButtonEdge", pv.BX, ty - 13, pv.BR - pv.BX, th + 28, tint=p["edge"], alpha=0.4)
    if drawn:
        pv.bus(st, tx, ty, tw, th, cuts, lit, p)
    else:
        stacked(st, tx, ty, tw, cuts, lit, p)
    for cut in sorted(set(cuts)):
        gx = tx + RIM + (tw - 2 * RIM) * cut
        if drawn:
            pv.grip(st, gx, ty + th / 2)
        else:
            st.lay("PowerHandle", gx - GRIP[0] / 2, ty + th / 2 - GRIP[1] / 2)
    return h.bytes8(h.halve(st.px)), st.items


def chips_row(p):
    """The chips on the room's panel, beside their rows' names."""
    st = kit.Stage(pv.W, 40.0, h.GROUND)
    kit.panel(st, pv.PX, 2, pv.PW, 36, p)
    x = pv.BX
    for name, label in (("Breaker", "Void Breaker"), ("Training", "Training machine")):
        st.lay(f"PowerChip{name}", x, 20 - CHIP / 2)
        pv.word(st, x + 18, 20, 14, label, p["text"])
        x += 190
    return h.bytes8(h.halve(st.px)), st.items


# --- what's written -------------------------------------------------------------------------------------------------

def manifest(out, names):
    p = ROOM
    images = {}
    for name in names:
        im = kit.IMAGES[name]
        points = list(EMBER_SIZE) if name == "PowerEmber" else [im["w"], im["h"]]
        images[name] = dict(file=f"images/{name}.png", pixels=[im["px"].shape[1], im["px"].shape[0]], points=points,
                            **({"tint": im["tint"]} if im["tint"] else {}),
                            **({"cut": list(im["cut"])} if im["cut"] else {}),
                            **({"pad": im["pad"]} if im["pad"] else {}), use=im["use"])
    data = dict(
        pixelsPerPoint=K4, palette="A, Eclipse (AR12, the pick of 2026-11-15)", room="Dynamo, vivid",
        note="Power's bar, cut. A white image takes its tint; a dark part baked into one stays dark. `cut` is a slice's "
             "insets in points (left, top, right, bottom): the slice's centre is the image less its cut, at 4 pixels a "
             "point. `pad` is how far an image reaches past its piece's box on every side. PowerEmber is drawn at one "
             "pixel a point and shown at its points' size. The stack is DESIGN, untried in Studio.",
        colours=dict(breaker=BREAKER, training=TRAINING, battery=POWER, ember=EMBER, caution=OVER, channel=p["channel"],
                     edge=p["edge"], faint=p["faint"], well=p["well"]),
        lights={name: dict(colour=colour, gradient=light_stops(colour)) for name, colour in LIGHTS.items()},
        bar=dict(
            height=HIGH, rim=RIM, gap=GAP,
            stack=[
                "PowerEmber: behind the well, tinted `ember`, its middle on the bar's",
                "the well: the kit's ButtonFill tinted `well` at 0.6 and ButtonEdge tinted `edge` at 0.4, 13 past the "
                "bar above and 15 under it, 26 past each end",
                "PowerBusChannel: on the bar's box, tinted `channel`",
                "PowerBusGlow: one a light, on the light's own box (the bar's height less the rim top and foot), tinted "
                "the light's colour, under every light and outside any clip",
                "a light: a plain clipping frame from cut to cut (upright sides, the gap left each side of a cut "
                "between two lights), holding PowerBusLight at the bar's whole size and place, with a UIGradient turned "
                "90 degrees set to its `gradient`",
                "a light's arriving end: PowerBusLight again in the same frame, white, with a UIGradient whose "
                "Transparency goes from 1 to 0.7 over `arrive.points` ending at the light's right side",
                "PowerBusEdge: on the bar's box, tinted `edge`",
                "the ticks: plain frames under the bar, in `faint`",
                "PowerHandle: its box's middle on each cut, above everything",
            ],
            lights="from `rim` inside the bar's left to `rim` inside its right; a cut at share s stands at rim + "
                   "(width - 2 * rim) * s; an idle machine's light wears the battery's gradient",
            glowAlpha=GLOW_ALPHA, edgeAlpha=EDGE_ALPHA, emberAlpha=EMBER_ALPHA,
            arrive=dict(points=ARRIVE[0], transparency=[1.0, 1.0 - ARRIVE[1]]),
            ticks=dict(at=list(TICKS[0]), size=list(TICKS[1]), under=TICKS[2], alpha=TICKS[3]),
            handle=dict(box=list(GRIP)), chip=dict(box=[CHIP, CHIP])),
        images=images)
    (out / "power_images.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print(f"wrote {out / 'power_images.json'}: {len(images)} images")


def over_dark(px, size=None):
    """An image on the sheet's dark ground: whole, or fitted into a square of `size` pixels."""
    if size:
        px = kit.fit(px, size)
    hh, w = (size, size) if size else px.shape[:2]
    ground = rs.canvas(w, hh, tuple(c(h.PARTS_GROUND)))
    rs.paste(ground, px, (w - px.shape[1]) // 2, (hh - px.shape[0]) // 2)
    return ground


NOTES = (
    "Power's bar, cut for the build (AR12). The palette is A, Eclipse: the Void Breaker's light is silver, the Training "
    "machine's the cyan, the battery's Power's yellow; the machines' room is Dynamo, vivid, unchanged. The first bar is "
    "drawn whole, as the accepted sheet drew it; the bars under it are stacked from the images the way "
    "power_images.json says the engine stacks them.",
    "A light is one white image of the bar's inner shape, shown through its segment's upright window and coloured by a "
    "gradient down its height, so the bar's cut ends stay true and a cut between two lights stays straight. The "
    "outline, the bed and each light's glow are slices. The ticks are plain frames. A handle and a chip are one image "
    "each, in their own colours. The ember is one soft image. Stand-ins: Blender's face for the game's text.",
)


def sheet(out, names, rows):
    """The images over dark, whole and at 64 pixels, then the bars."""
    ui.K = 2
    m, gap = 20.0, 12.0
    lines = [line for note in NOTES for line in textwrap.wrap(note, 190)]
    tall = max(kit.IMAGES[n]["px"].shape[0] for n in names if n != "PowerEmber") / 2
    y_whole, y_small = 62.0, 62.0 + tall + 34.0
    y_rows = y_small + max(32.0, EMBER_SIZE[1] / 2) + 34.0
    extra = sum(14.0 + shot[0].shape[0] / 2 + 8.0 for _, shot in rows)
    sh = ui.Sheet(2 * m + pv.W, y_rows + extra + len(lines) * 15 + 14, h.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(m, 14, 17, "Grow your Anime: Power's bar, its images as delivered (Eclipse)", h.HEAD)
    t.text(m, 44, 11, "Each image over dark at its own pixels; under them, each at 64 pixels, and the ember whole.", h.HEAD)
    x = m
    for name in names:
        if name == "PowerEmber":
            continue
        px = over_dark(kit.IMAGES[name]["px"])
        kit.put(sh, px, x * 2, y_whole * 2)
        t.text(x, y_whole + px.shape[0] / 2 + 4, 9, name, h.NOTE)
        x += max(px.shape[1] / 2, 96.0) + gap
    x = m
    for name in names:
        kit.put(sh, over_dark(kit.IMAGES[name]["px"], 64), x * 2, y_small * 2)
        x += 32.0 + gap
    kit.put(sh, over_dark(kit.IMAGES["PowerEmber"]["px"]), (x + 20) * 2, y_small * 2)
    t.text(x + 20, y_small + EMBER_SIZE[1] / 2 + 4, 9, "PowerEmber", h.NOTE)
    y = y_rows
    for caption, shot in rows:
        t.text(m, y, 10, caption, h.NOTE)
        h.add(sh, *shot, m, y + 14)
        y += 14.0 + shot[0].shape[0] / 2 + 8.0
    for i, line in enumerate(lines):
        t.text(m, y + i * 15, 10, line, h.NOTE)
    kit.finish(sh, out / "power_images.png")


def main():
    out = bl.out_dir()
    mode = (sys.argv[sys.argv.index("--") + 2:] or ["all"])[0]  # all; images: no sheet; sheet: nothing saved but it
    h.stage("started")
    pv.sv.slices()
    names = cut_images()
    h.stage("the images")
    if mode != "sheet":
        (out / "images").mkdir(exist_ok=True)
        CHECK.mkdir(parents=True, exist_ok=True)
        for name in names:
            px = kit.IMAGES[name]["px"].copy()
            kit.bleed(px)
            rs.save(px, out / "images" / f"{name}.png")
            rs.save(over_dark(kit.IMAGES[name]["px"]), CHECK / f"{name}_whole.png")
            rs.save(over_dark(kit.IMAGES[name]["px"], 64), CHECK / f"{name}_64.png")
        manifest(out, names)
        h.stage("the images saved")
    if mode == "images":
        return
    p = ROOM
    both = (BREAKER, TRAINING, POWER)
    rows = (
        ("Drawn whole, as the accepted sheet drew it: the Void Breaker at 50%, the Training machine at 25%, the rest charging:",
         bar_row(p, (0.5, 0.75), both, drawn=True)),
        ("The same, stacked from the images:", bar_row(p, (0.5, 0.75), both)),
        ("Stacked: under Auto, the Void Breaker taking everything:", bar_row(p, (1.0, 1.0), (BREAKER, POWER, POWER))),
        ("Stacked: a split the player made, the Void Breaker at 25%, the Training machine idle:",
         bar_row(p, (0.25, 0.25), (BREAKER, POWER, POWER))),
        ("The chips beside their rows' names:", chips_row(p)),
    )
    h.stage("the bars")
    sheet(out, names, rows)
    kit.IMAGES.clear()
    h.stage("the sheet")


if __name__ == "__main__":
    main()
