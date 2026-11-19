"""AR43: Seam's lit glass cut for Faber (research's B, 15:04; the four screens passed at 15:49, "Cut them for Faber").
The kit every screen Home opens wears in B, beside Config.UIKit's Seam: the palette, the panel's lift, the screen's
ground, Equipment's rail, the lit press, Settings' sliders, the idle loop and the motion. Equipment's list rows and
Reinforce's ring are in build/handoff/UI/equipment (equipment_pages.py, "cut").

    blender -b --factory-startup --python tools/blender/seam_cut.py -- <abs out>

Writes build/handoff/UI/seam: images/ (white masks unless said, 4 pixels a point), seam.json, and seam_cut.png: each
image as the game tints it, then the panel, the rail, the press and the sliders built from the images beside the kit's
drawing (seam_kit.py), with their differences. Drawn in code from polygons and distance fields, no image input.
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402,F401
import foe_cards as fc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import equipment_pages as ep  # noqa: E402  (wears B on import)
import seam_kit as sk  # noqa: E402
import seam_motion as sm  # noqa: E402

P = up.P
K = 4
HANDOFF = up.REPO / "build" / "handoff" / "UI" / "seam"
WHITE = "#FFFFFF"
KIT_CUTS = (10.0, 3.0, 10.0, 3.0)        # Config.UIKit's PanelFill and PanelEdge corners (ui_kit.panels): 32 points, Cut 12
SHEEN, SHEEN_H = sk.STYLES["B"]["sheen"], 96.0   # the panel's lift: 0.11 exp(-y / 24) from its top, gone by 96 points
CORNER = (200.0, 160.0)                  # the corner's glint, 0.85 exp(-d / 46) from 24 points along the top
BLOOM_SPAN = 2.5                         # the screen's bloom drawn out to 2.5 of its radii each way
RC, RR = sk.RAIL_R_CHOSEN, sk.RAIL_R     # a rail button's radius, chosen and at rest
KH, KR = sk.KNOB_R_HELD, sk.KNOB_R       # a slider's knob, held and at rest
COMET = 0.95 * 0.95                      # the rail's comet: seam_kit.comet's 0.95 on the rail's 0.95
MADE = {}


def disc_tile(r, pad):
    """A transparent tile round a disc of radius r with pad points about it: (tile, its middle, the disc's field)."""
    s = 2 * (r + pad)
    t = fc.clear(s, s)
    return t, s / 2, np.hypot(t.x - s / 2, t.y - s / 2)


def gaps(ang):
    """1 on the rail's outer ring, 0 in its two gaps (top left and foot right, where the kit cuts its corners)."""
    wrap = lambda a: np.abs(np.mod(a + np.pi, 2 * np.pi) - np.pi)  # noqa: E731
    return np.where((wrap(ang + 3 * np.pi / 4) < 0.3) | (wrap(ang - np.pi / 4) < 0.3), 0.0, 1.0)


def keep(name, t, **entry):
    MADE[name] = (t.px.copy(), dict(points=[t.w, t.h], **entry))


def images():
    ui.K = K
    # --- the panel and the ground
    t = fc.clear(32, SHEEN_H)
    t.paint(t.poly(ui.cut_box(0, 0, 32, SHEEN_H + 40, *KIT_CUTS)), WHITE, np.exp(-t.y / 24))
    keep("PanelSheen", t, cut=[12, 0, 12, 0], tint=f"the glint {P['glint']} at ImageTransparency {1 - SHEEN:.2f}",
         use="the panel's lift: across its top at its own height (96), sliced at its ends, over PanelFill")
    w, h = CORNER
    t = fc.clear(w, h)
    t.line(t.poly(ui.cut_box(0, 0, w + 40, h + 40, *KIT_CUTS)), 1.3, WHITE, np.exp(-np.hypot(t.x - 24, t.y) / 46))
    keep("PanelCornerGlint", t, tint=f"the glint {P['glint']} at ImageTransparency 0.15",
         use="the light along the panel's top-left corner, over PanelEdge: its top left on the panel's; on a panel "
             "under 200 by 160 points, clipped to it")
    n = 64.0
    t = fc.clear(n, n)
    u, v = (t.x - n / 2) / (n / 2) * BLOOM_SPAN, (t.y - n / 2) / (n / 2) * BLOOM_SPAN
    t.paint(t.poly([(0, 0), (n, 0), (n, n), (0, n)]), WHITE, np.exp(-(u * u + v * v)))
    colour, strength = sk.STYLES["B"]["bloom"]
    (rx, ry) = sk.BLOOM_SIZE
    keep("ScreenBloom", t, laid=[2 * BLOOM_SPAN * rx, 2 * BLOOM_SPAN * ry],
         tint=f"{colour} at ImageTransparency {1 - strength:.2f}",
         use="the bloom behind the work: laid at 750 by 600 points (its two radii 150 and 120, drawn to 2.5 of each), "
             "its middle on the bloom's (seam.json, ground); a smooth falloff, so 256 pixels serve it stretched")
    # --- the rail
    t, m, dist = disc_tile(RC, 1)
    t.paint(dist - RC, WHITE)
    keep("RailDisc", t, tint="a UIGradient down it (Rotation 90): Color the Card top to foot when chosen, the "
                             "Button's at rest, held at 1/56 and 55/56 (the disc's top and foot)",
         use="a rail button's glass: its middle on the button's, laid at 2 (r + 1) points for its radius r")
    t, m, dist = disc_tile(RC, 1)
    t.paint(dist - RC, WHITE, np.exp(-np.maximum(t.y - (m - RC), 0) / (RC * 0.45)))
    keep("RailSheen", t, tint=f"the glint {P['glint']} at ImageTransparency 0.78 chosen, 0.88 at rest",
         use="the light on a rail button's top: laid as RailDisc")
    t, m, dist = disc_tile(RC, 1)
    t.paint(dist - RC, WHITE, np.clip((t.x - m + RC) / (2 * RC), 0, 1) ** 2)
    keep("RailLight", t, tint=f"the light {P['light']} at ImageTransparency 0.82",
         use="the chosen button's glass lit toward its right: laid as RailDisc; chosen only")
    t, m, dist = disc_tile(RC, 24)
    t.glow(dist - RC, 8.0, WHITE, 1.0)
    keep("RailGlow", t, pad=24, tint=f"the light {P['light']} at ImageTransparency 0.78",
         use="the chosen button's glow, under its disc: laid at 2 (r + 24) points; chosen only")
    for name, r, tint in (("RailEdge", RR, f"the edge {P['edge']} at ImageTransparency 0.2"),
                          ("RailEdgeChosen", RC, f"the facet {P['facet']} at ImageTransparency 0.2")):
        t, m, dist = disc_tile(r, 1)
        t.line(dist - r, 1.0, WHITE)
        keep(name, t, tint=tint, use=f"a button's hairline, 1 point wide inside its disc, drawn at {r:g}: laid at "
                                     f"2 (r + 1) points")
    for name, r, width, tint in (("RailRing", RR, 1.0, f"the facet {P['facet']}"),
                                 ("RailRingChosen", RC, 1.6, f"the light {P['light']}")):
        t, m, dist = disc_tile(r + 3.5, 1)
        ang = np.arctan2(t.y - m, t.x - m)
        t.line(dist - r - 3.5, width, WHITE, gaps(ang) * (0.45 + 0.5 * (1 - np.sin(ang)) / 2))
        keep(name, t, tint=tint, use=f"a button's outer ring, {width:g} wide just inside {r + 3.5:g} points round, "
                                     "broken top left and foot right, lit from above: laid at 2 (r + 4.5) points")
    t, m, dist = disc_tile(RC + 3.5, 1)
    ang = np.arctan2(t.y - m, t.x - m)
    behind = np.mod(-np.pi / 2 - ang, 2 * np.pi)
    t.line(dist - RC - 3.3, 2.2, WHITE, np.where(behind < 1.4, np.exp(-behind * 2.6), 0.0))
    keep("RailComet", t, tint=f"the glint {P['glint']} at ImageTransparency {1 - COMET:.2f}",
         use="the idle's comet on the chosen button's ring, its head at the top: laid as RailRingChosen, Rotation "
             "360 x the idle's phase (clockwise); it runs on over the ring's two gaps, which a turning image can't "
             "keep")
    t = fc.clear(4, 96)
    t.paint(np.abs(t.x - 2) - 1.0, WHITE, np.exp(-((t.y - 48) / 16) ** 2))
    keep("RailRunner", t, tint=f"the glint {P['glint']} at ImageTransparency 0.15",
         use="the idle's light down the rail's line: its middle at x 48 and y = the rail's top + (its foot - its "
             "top) x the idle's phase; clipped to each piece of the line")
    # --- the lit press
    t = fc.clear(28, 28)
    t.paint(t.poly(ui.cut_box(0, 0, 28, 28, 5, 5, 5, 5)), WHITE)
    keep("PressFill", t, cut=[8] * 4, tint="a UIGradient down it (Rotation 90), Color as seam.json's press.fill: "
                                          "white falling to lavender, its foot more so",
         use="the lit press's body: its box the press's, sliced")
    t = fc.clear(28, 28)
    t.line(t.poly(ui.cut_box(0, 0, 28, 28, 5, 5, 5, 5)), 1.0, WHITE)
    keep("PressEdge", t, cut=[8] * 4, tint="white at ImageTransparency 0.1", use="the lit press's hairline: as PressFill")
    g = 21.0
    t = fc.clear(28 + 2 * g, 28 + 2 * g)
    t.glow(t.poly(ui.cut_box(g, g, g + 28, g + 28, 5, 5, 5, 5)), 7.0, WHITE, 1.0)
    keep("PressGlow", t, cut=[8 + g] * 4, pad=g, tint=f"the lavender {P['lit'][1]} at ImageTransparency 0.55",
         use="the lit press's glow, under it: its box the press's with Pad on every side, sliced")
    # --- Settings' slider
    t = fc.clear(16, 8)
    d = t.poly(ui.cut_box(0, 0, 16, 8, 3, 3, 3, 3))
    t.paint(d, P["channel"])
    t.line(d, 1.0, P["edge"], 0.9)
    keep("SliderTrack", t, cut=[4, 0, 4, 0], tint=None,
         use="the slider's channel, in its own colours: from the slider's start to its end, 8 high on its middle, "
             "sliced at its ends")
    t = fc.clear(16, 6)
    d = t.poly(ui.cut_box(0, 0, 16, 6, 2, 0, 2, 0))
    t.paint(d, WHITE)
    keep("SliderFill", t, cut=[3, 0, 3, 0], tint="a UIGradient across it (Rotation 0): Color the facet to the light",
         use="the light filling the channel: from 1 past its start to the knob's middle, 6 high; hidden under 6 "
             "points long")
    t = fc.clear(16, 6)
    t.paint(d, WHITE, np.exp(-t.y / 1.5))
    keep("SliderFillLight", t, cut=[3, 0, 3, 0], tint="white at ImageTransparency 0.75, 0.55 held",
         use="the fill's lit top: laid as SliderFill")
    g = 12.0
    t = fc.clear(16 + 2 * g, 6 + 2 * g)
    t.glow(t.poly(ui.cut_box(g, g, g + 16, g + 6, 2, 0, 2, 0)), 4.0, WHITE, 1.0)
    keep("SliderFillGlow", t, cut=[3 + g, 0, 3 + g, 0], pad=g,
         tint=f"the light {P['light']} at ImageTransparency 0.86, 0.70 held",
         use="the fill's glow, over the fill: SliderFill's box with Pad on every side, sliced at its ends")
    t, m, dist = disc_tile(KH, 1)
    t.paint(dist - KH, WHITE)
    keep("SliderKnob", t, tint=f"a UIGradient down it (Rotation 90): Color {P['lit'][0]} to {P['lit'][1]}, held at "
                               "1/27 and 26/27 (the disc's top and foot)",
         use=f"the knob, drawn at its held radius {KH:g}: its middle on the fill's end, laid at 2 (r + 1) points, "
             f"r {KR:g} at rest")
    t, m, dist = disc_tile(KH, 1)
    t.paint(dist - KH, WHITE, np.exp(-np.maximum(t.y - (m - KH), 0) / (KH * 0.35)))
    keep("SliderKnobSheen", t, tint="white at ImageTransparency 0.4", use="the knob's lit top: laid as SliderKnob")
    t, m, dist = disc_tile(KR, 1)
    t.line(dist - KR, 1.0, WHITE)
    keep("SliderKnobEdge", t, tint=f"the facet {P['facet']} at ImageTransparency 0.1",
         use=f"the knob's hairline, drawn at rest ({KR:g}): laid at 2 (r + 1) points, so held it is 1.25 wide")
    t, m, dist = disc_tile(KR, 18)
    t.glow(dist - KR, 6.0, WHITE, 1.0)
    keep("SliderKnobGlow", t, pad=18, tint=f"the lavender {P['lit'][1]} at ImageTransparency 0.65, 0.35 held",
         use=f"the knob's glow, under it, drawn at rest: laid at 2 (r + 18) x r / {KR:g} points")
    t, m, dist = disc_tile(KH + 4.5, 1)
    t.line(dist - KH - 4.5, 1.4, WHITE)
    keep("SliderKnobRing", t, tint=f"the light {P['light']} at ImageTransparency 0.15",
         use=f"held only: the ring round the knob, 1.4 wide just inside {KH + 4.5:g} points round, laid at "
             f"{2 * (KH + 5.5):g} points on the knob's middle")
    return MADE


# --- built from the images, as the game lays them ------------------------------------------------------------------

def stops_rgb(stops, n):
    u = (np.arange(n) + 0.5) / n
    cols = np.array([rs.rgb(c) for _, c in stops], np.float32)
    return np.stack([np.interp(u, [p for p, _ in stops], cols[:, k]) for k in range(3)], -1).astype(np.float32)


def lay(dst, name, x, y, w, h, *tint, **kw):
    """`name` laid at x, y, w by h points onto dst (see laid)."""
    rs.paste(dst, laid(name, w, h, *tint, **kw), int(round(x * K)), int(round(y * K)))


def laid(name, w, h, colour=None, transparency=0.0, colours=None, fades=None, axis="y"):
    """`name` at w by h points: sliced as its entry says, else stretched; `colours` a UIGradient's Color stops and
    `fades` its Transparency stops along `axis`, then the tint and the ImageTransparency."""
    px, entry = MADE[name]
    wp, hp = int(round(w * K)), int(round(h * K))
    cut = entry.get("cut")
    if cut and cut[1] == 0 and cut[3] == 0:
        img = ep.slice_ends(px, cut[0] * K, wp)
    elif cut:
        img = ep.slice9(px, cut[0] * K, wp, hp)
    else:
        img = ep.stretch(px, wp, hp)
    img = img.astype(np.float32)
    n = img.shape[0] if axis == "y" else img.shape[1]
    if colours:
        g = stops_rgb(colours, n)
        img[..., :3] *= g[:, None, :] if axis == "y" else g[None, :, :]
    if fades:
        a = np.interp((np.arange(n) + 0.5) / n, [p for p, _ in fades], [1 - f for _, f in fades]).astype(np.float32)
        img[..., 3] *= a[:, None] if axis == "y" else a[None, :]
    if colour:
        img[..., :3] *= np.array(rs.rgb(colour), np.float32)
    img[..., 3] *= 1 - transparency
    return img


def lay_disc(dst, name, cx, cy, r_drawn, r, pad, **kw):
    """A disc's image drawn at r_drawn with `pad`, laid for radius r on the middle cx, cy."""
    s = 2 * (r_drawn + pad) * r / r_drawn
    lay(dst, name, cx - s / 2, cy - s / 2, s, s, **kw)


def press_fill_stops():
    """The lit press's Color down it: seam_kit.press's white-to-lavender ramp with its foot washed in the lavender
    (0.35 from 40% down), as one gradient: lit0 + (lit1 - lit0) (v + 0.35 max(v - 0.4, 0) (1 - v))."""
    a, b = np.array(rs.rgb(P["lit"][0])), np.array(rs.rgb(P["lit"][1]))
    out = []
    for v in (0.0, 0.4, 0.55, 0.7, 0.85, 1.0):
        f = v + 0.35 * max(v - 0.4, 0.0) * (1 - v)
        out.append((v, "#" + "".join(f"{round(float(c) * 255):02X}" for c in a + (b - a) * f)))
    return out


def top_light_stops():
    return [(y / 160, round(1 - 0.06 * np.exp(-y / 40), 4)) for y in (0, 10, 20, 40, 60, 90, 120, 160)]


def kit_panel_masks():
    """Stand-ins for Config.UIKit's PanelFill and PanelEdge (ui_kit.panels: 32 points, the corners 10 and 3, Cut 12)."""
    t = fc.clear(32, 32)
    d = t.poly(ui.cut_box(0, 0, 32, 32, *KIT_CUTS))
    t.paint(d, WHITE)
    MADE["KitPanelFill"] = (t.px.copy(), dict(cut=[12] * 4))
    t = fc.clear(32, 32)
    t.line(d, 1.0, WHITE)
    MADE["KitPanelEdge"] = (t.px.copy(), dict(cut=[12] * 4))


def ground(w, h, colour):
    sheet = ui.Sheet(w, h, "#000000")
    t = sheet.tile(0, 0, w, h)
    t.paint(t.poly([(0, 0), (w, 0), (w, h), (0, h)]), colour)
    return sheet, t


def fit_panel():
    x0, y0, x1, y1 = 10.0, 10.0, 10 + sk.LIST[1] - sk.LIST[0], 10 + ep.FOOT - ep.TOP
    sheet, t = ground(x1 + 10, y1 + 10, P["backing"][1])
    built = sheet.px.copy()
    sk.panel(t, x0, y0, x1, y1, KIT_CUTS)
    w, h = x1 - x0, y1 - y0
    lay(built, "KitPanelFill", x0, y0, w, h, colours=[(0, P["panel"][0]), (1, P["panel"][1])])
    lay(built, "PanelSheen", x0, y0, w, SHEEN_H, P["glint"], 1 - SHEEN)
    lay(built, "KitPanelEdge", x0, y0, w, h, P["facet"], fades=[(0, 0.1), (0.85, 0.7), (1, 0.7)])
    lay(built, "PanelCornerGlint", x0, y0, *CORNER, P["glint"], 0.15)
    return built, sheet.px


def fit_rail(chosen):
    sheet = ui.Sheet(100, 320, "#000000")
    t = sheet.tile(0, 0, 100, 320)
    sk.backdrop(t)
    built = sheet.px.copy()
    mark, up.mark = up.mark, (lambda *a, **k: None)          # the marks are the game's own pictures, not this cut's
    try:
        sk.rail(t, chosen)
    finally:
        up.mark = mark
    size = {name: (RC if name == chosen else RR) for name, _ in sk.RAIL}
    pieces = sk.rail_spans(chosen, size)
    x = sk.RAIL_X
    for a, b in pieces:
        frame = ui.Sheet(100, 320, "#000000")
        f = frame.tile(0, 0, 100, 320)
        f.px[:] = 0
        f.paint(f.poly([(x - 0.6, a), (x + 0.6, a), (x + 0.6, b), (x - 0.6, b)]), WHITE, 0.45)
        line = frame.px.copy()
        line[..., :3] = np.array(rs.rgb(P["facet"]), np.float32)
        rs.paste(built, line, 0, 0)
    runner = laid("RailRunner", 4, 96, P["glint"], 0.15)
    top = sk.RAIL_TOP - 48
    ys = top + (np.arange(runner.shape[0]) + 0.5) / K
    inside = np.zeros(runner.shape[0], bool)
    for a, b in pieces:
        inside |= (ys >= a) & (ys < b)
    runner[~inside, :, 3] = 0                                 # clipped to the line's pieces
    rs.paste(built, runner, int(round((x - 2) * K)), int(round(top * K)))
    for name, cy in sk.RAIL:
        big, r = name == chosen, size[name]
        if big:
            lay_disc(built, "RailGlow", x, cy, RC, r, 24, colour=P["light"], transparency=0.78)
        fill = P["card"] if big else P["button"]
        lay_disc(built, "RailDisc", x, cy, RC, r, 1, colours=[(0, fill[0]), (1 / 56, fill[0]), (55 / 56, fill[1]),
                                                               (1, fill[1])])
        lay_disc(built, "RailSheen", x, cy, RC, r, 1, colour=P["glint"], transparency=0.78 if big else 0.88)
        if big:
            lay_disc(built, "RailLight", x, cy, RC, r, 1, colour=P["light"], transparency=0.82)
            lay_disc(built, "RailRingChosen", x, cy, RC + 3.5, r + 3.5, 1, colour=P["light"])
            lay_disc(built, "RailEdgeChosen", x, cy, RC, r, 1, colour=P["facet"], transparency=0.2)
            lay_disc(built, "RailComet", x, cy, RC + 3.5, r + 3.5, 1, colour=P["glint"], transparency=1 - COMET)
        else:
            lay_disc(built, "RailRing", x, cy, RR + 3.5, r + 3.5, 1, colour=P["facet"])
            lay_disc(built, "RailEdge", x, cy, RR, r, 1, colour=P["edge"], transparency=0.2)
    return built, sheet.px


def fit_press():
    x0, y0, x1, y1 = 24.0, 24.0, 116.0, 68.0
    sheet, t = ground(140, 92, P["panel"][1])
    built = sheet.px.copy()
    sk.NOW["phase"] = 0.0                                    # the sheen waits off the press's left
    sk.press(t, x0, y0, x1, y1, "", "one")
    w, h = x1 - x0, y1 - y0
    lay(built, "PressGlow", x0 - 21, y0 - 21, w + 42, h + 42, P["lit"][1], 0.55)
    lay(built, "PressFill", x0, y0, w, h, colours=press_fill_stops())
    lay(built, "PressEdge", x0, y0, w, h, WHITE, 0.1)
    return built, sheet.px


def fit_slider(value, held):
    x0, x1, cy = 20.0, 228.0, 26.0
    sheet, t = ground(250, 52, P["panel"][0])
    built = sheet.px.copy()
    sk.slider(t, x0, x1, cy, value, held)
    at = x0 + (x1 - x0) * value
    lay(built, "SliderTrack", x0, cy - 4, x1 - x0, 8)
    if at > x0 + 2:
        lay(built, "SliderFill", x0 + 1, cy - 3, at - x0 - 1, 6, colours=[(0, P["facet"]), (1, P["light"])], axis="x")
        lay(built, "SliderFillLight", x0 + 1, cy - 3, at - x0 - 1, 6, WHITE, 0.55 if held else 0.75)
        lay(built, "SliderFillGlow", x0 + 1 - 12, cy - 15, at - x0 - 1 + 24, 30, P["light"], 0.70 if held else 0.86)
    r = KH if held else KR
    lay_disc(built, "SliderKnobGlow", at, cy, KR, r, 18, colour=P["lit"][1], transparency=0.35 if held else 0.65)
    lay_disc(built, "SliderKnob", at, cy, KH, r, 1, colours=[(0, P["lit"][0]), (1 / 27, P["lit"][0]),
                                                             (26 / 27, P["lit"][1]), (1, P["lit"][1])])
    lay_disc(built, "SliderKnobSheen", at, cy, KH, r, 1, colour=WHITE, transparency=0.4)
    lay_disc(built, "SliderKnobEdge", at, cy, KR, r, 1, colour=P["facet"], transparency=0.1)
    if held:
        lay_disc(built, "SliderKnobRing", at, cy, KH + 4.5, KH + 4.5, 1, colour=P["light"], transparency=0.15)
    return built, sheet.px


# --- seam.json ------------------------------------------------------------------------------------------------------

def palette():
    hexes = lambda pair: list(pair)  # noqa: E731
    glass = dict(Panel=hexes(P["panel"]), Alpha=0, Edge=P["edge"], Facet=P["facet"], Glint=P["glint"], Text=P["text"],
                 Soft=P["soft"], Faint=P["faint"], Channel=P["channel"], Well=P["well"][0], WellFoot=P["well"][1],
                 Button=hexes(P["button"]), Pressed=["#120E20", "#1A1430"], Ground="#1E1A2C", Accent=P["light"],
                 Core=0.5, Backing=hexes(P["backing"]), Light=P["light"], Ink=P["ink"], Card=hexes(P["card"]))
    lit = dict(Panel=hexes(P["lit"]), Button=hexes(P["lit"]),
               note="SeamLit with its Panel and Button white falling to this lavender; the rest SeamLit's")
    return dict(SeamGlass=glass, SeamGlassLit=lit,
                note="beside Seam and SeamLit in Config.UIKit's Palettes, for every screen Home opens (Equipment's "
                     "three, Settings; AR42's picker later, by the register's scope). Seam's own values where B kept "
                     "them (Pressed, Ground, Core); Backing is a gradient here, top to foot; Well's foot is WellFoot, "
                     "as Config.Hud.Seam.WellFoot is Seam's. The Voidkin screen and the bag stay on Seam until the "
                     "director's word")


def rail_layout():
    out = {}
    for chosen, _ in sk.RAIL:
        size = {name: (RC if name == chosen else RR) for name, _ in sk.RAIL}
        out[chosen] = [[a, b] for a, b in sk.rail_spans(chosen, size)]
    return out


def seam_json():
    m = sm.MOTION
    top, foot = ep.TOP, ep.FOOT
    sx0, sx1 = ep.SETTINGS
    mid = (top + foot) / 2
    entries = {name: dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]], **entry)
               for name, (px, entry) in MADE.items() if not name.startswith("Kit")}
    bx, by = sk.BLOOM_AT
    return dict(
        what="AR43, Seam's lit glass (research's B, 15:04; the four screens passed at 15:49): the kit every screen "
             "Home opens wears, beside Config.UIKit's Seam. Equipment's rows and Reinforce's ring are in "
             "../equipment/equipment.json. From tools/blender/seam_cut.py; drawn in code, no image input",
        pixelsPerPoint=K,
        palette=palette(),
        ground=dict(
            backing="a Frame over the whole screen, under the band: UIGradient Rotation 90, Color Backing top to foot",
            bloom=dict(image="ScreenBloom", equipment=[bx, by], settings=[(sx0 + sx1) / 2, mid],
                       note=f"its middle, in points on the smallest phone: on Equipment the work panel's middle across, "
                            f"{by - top:g} under the page's top; on Settings the card's middle"),
            topLight=dict(colour=P["glint"], height=160, transparency=top_light_stops(),
                          note="a Frame across the screen's top under the band, the glint, a UIGradient down it "
                               "(Rotation 90) with these Transparency stops: 1 - 0.06 exp(-y / 40)")),
        panel=dict(
            stack=["PanelFill (the kit's): a UIGradient down it (Rotation 90), Color Panel top to foot; "
                   "ImageTransparency 0, the panel solid",
                   "PanelSheen: across the panel's top at its own height, the glint at 0.89",
                   "PanelEdge (the kit's): the facet, a UIGradient down it (Rotation 90), Transparency 0.1 at 0, 0.7 "
                   "at 0.85 and at 1: lit from above",
                   "PanelCornerGlint: its top left on the panel's, the glint at 0.15"],
            corners="the kit's PanelFill and PanelEdge corners (10 and 3), as the game has them; the sheets drew 8 and "
                    "0, and seam_cut.png's fit is drawn on the kit's",
            shadow="none: the sheets draw none"),
        rail=dict(
            x=sk.RAIL_X, top=sk.RAIL_TOP, foot=sk.RAIL_FOOT, width=96,
            buttons=[dict(name=name, middle=[sk.RAIL_X, cy], mark=f"VoidkinPage{up.PAGE_ICON.get(name, name)}".replace(
                " ", "")) for name, cy in sk.RAIL],
            radius=dict(rest=RR, chosen=RC),
            line=dict(width=1.2, colour=P["facet"], transparency=0.55, pieces=rail_layout(),
                      note="Frames centred on x, in pieces (top, foot) by the open screen: between the buttons, never "
                           "through a button or a word"),
            runner="RailRunner, clipped to the pieces",
            chosen=["RailGlow", "RailDisc (the Card)", "RailSheen at 0.78", "RailLight", "RailRingChosen",
                    "RailEdgeChosen", "the mark (1.05 r high, the glint)", "the word", "RailComet"],
            rest=["RailDisc (the Button)", "RailSheen at 0.88", "RailRing", "RailEdge", "the mark (1.05 r high, the "
                  "soft)", "the word"],
            words=dict(top="the button's middle + r + 7", chosen=dict(size=sk.RAIL_WORD_CHOSEN, bold=True,
                                                                      colour=P["light"]),
                       rest=dict(size=sk.RAIL_WORD, bold=False, colour=P["soft"]), align="centre on x 48"),
            touch="the button's disc and its word, at least 44 points each way; a tap on the open one does nothing",
            back="Back stays top left and returns to Home; the title reads Equipment (the director, 14:59)"),
        press=dict(
            stack=["PressGlow", "PressFill", "PressEdge", "the words in the Ink, 14 bold, centred", "the sheen"],
            fill=press_fill_stops(),
            sheen="once a loop, a white band across the press, 0.75 at its middle, 6 points round (exp(-(d / 6)^2)), "
                  "leaning 0.5 points left for each point down, its middle at the top running from 30 left of the "
                  "press to 30 right of it with the idle's phase: the kit's Shine (UI/Kit/Shine) on a white copy of "
                  "PressFill keeps it inside the press's cut corners",
            note="the lit press only (Put in, Replace, Take out, Reinforce); quiet and off presses stay Seam's"),
        settings=dict(
            card=[sx0, top + 8, sx1, foot - 8], rows=[mid - ep.SETTING_ROW, mid, mid + ep.SETTING_ROW],
            name=dict(x=sx0 + 22, size=15, bold=True, colour=P["text"], held=P["light"], note="its middle on the row's"),
            slider=dict(start=sx0 + 120, end=sx1 - 78),
            value=dict(right=sx1 - 22, size=up.SMALL, colour=P["soft"], held=P["light"], words="Off at 0, else N%",
                       note="bold when held"),
            dividers=dict(at="between the rows", left=sx0 + 18, right=sx1 - 18, height=1, colour=P["edge"],
                          transparency=0.4),
            stack=["SliderTrack", "SliderFill", "SliderFillLight", "SliderFillGlow", "SliderKnobGlow", "SliderKnob",
                   "SliderKnobSheen", "SliderKnobEdge", "SliderKnobRing (held)"],
            held="while dragged: the knob 12.5 (from 10) over 0.08 s (out3), its ring shown, the fill's light at "
                 "0.55 and its glow at 0.70, the knob's glow at 0.35, the name and value in the light; back the same "
                 "way on release. Each change is heard or seen at once",
            touch="the whole row drags its slider; the knob's touch at least 44 points"),
        idle=dict(
            loop=sk.LOOP, phase="(time mod loop) / loop, one phase for every piece on the screen",
            pieces=["ReinforceComet and RailComet: Rotation 360 x phase", "RailRunner down the rail's line",
                    "RowGlint down the chosen row (../equipment)", "the lit press's sheen"],
            reducedMotion="with the player's reduced motion on, nothing idles (as the kit's Shine)"),
        motion=dict(
            numbers=dict(m),
            easing=dict(out3="1 - (1 - u)^3", smooth="u^2 (3 - 2u)", backOut="1 + (s + 1)(u - 1)^3 + s (u - 1)^2"),
            open=[f"the screen fades in over open_time (out3), rising open_rise points to its place, over the game",
                  "row k fades in sliding from row_from points left, from row_start + k x row_gap over row_time (out3)",
                  "the work fades in from work_start over work_time (out3)",
                  "Reinforce's ring draws round once, clockwise from the top, from ring_start over ring_time (smooth)",
                  "the gear grows from pop_from to 1 from pop_start over pop_time (backOut, s = pop_back), fading in "
                  "over its first third",
                  "the band and the rail are there from the start"],
            switch=["a rail tap: the tapped button grows 20 to 27 as the last shrinks 27 to 20, over switch_time "
                    "(backOut, s = switch_back); their looks, chosen or at rest, change at the tap",
                    "the rail's words and the rows crossfade over cross_time (smooth)",
                    "the work dips: the old fades out over the first half of cross_time, the new in over the second "
                    "(smooth), never both at once; the panel stays"],
            clip="build/scratch/modulo/equipment/seam_motion.mp4 (sent to research at 15:47)"),
        images=entries)


# --- the sheet ------------------------------------------------------------------------------------------------------

SHOWN = [("PanelSheen", P["glint"], 1 - SHEEN), ("PanelCornerGlint", P["glint"], 0.15),
         ("ScreenBloom", sk.STYLES["B"]["bloom"][0], 0.70), ("RailDisc", P["card"][0], 0.0),
         ("RailSheen", P["glint"], 0.78), ("RailLight", P["light"], 0.82), ("RailGlow", P["light"], 0.78),
         ("RailEdge", P["edge"], 0.2), ("RailEdgeChosen", P["facet"], 0.2), ("RailRing", P["facet"], 0.0),
         ("RailRingChosen", P["light"], 0.0), ("RailComet", P["glint"], 1 - COMET), ("RailRunner", P["glint"], 0.15),
         ("PressFill", P["lit"][1], 0.0), ("PressEdge", WHITE, 0.1), ("PressGlow", P["lit"][1], 0.55),
         ("SliderTrack", None, 0.0), ("SliderFill", P["facet"], 0.0), ("SliderFillLight", WHITE, 0.75),
         ("SliderFillGlow", P["light"], 0.86), ("SliderKnob", P["lit"][1], 0.0), ("SliderKnobSheen", WHITE, 0.4),
         ("SliderKnobEdge", P["facet"], 0.1), ("SliderKnobGlow", P["lit"][1], 0.65), ("SliderKnobRing", P["light"], 0.15)]


def sheet_of(path):
    ui.K = K
    width, height = 1480, 760
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(20, 16, 20, "AR43, Seam's lit glass, cut: the images as the game tints them, then built against drawn",
           "#EDE6D6", bold=0.2)
    t.paint(t.poly([(10, 54), (width - 10, 54), (width - 10, 326), (10, 326)]), P["panel"][1])
    x, y = 20.0, 70.0
    for name, colour, transparency in SHOWN:
        px = MADE[name][0]
        im = ep.tinted(px, colour, transparency) if colour else px
        if px.shape[1] / K > 120:
            im = ep.stretch(im, int(px.shape[1] * 120 / (px.shape[1] / K)), int(px.shape[0] * 120 / (px.shape[1] / K)))
        wpt = im.shape[1] / K
        if x + wpt > width - 20:
            x, y = 20.0, y + 124
        rs.paste(sheet.px, im, round(x * K), round(y * K))
        t.text(x, y + 104, 11, name, P["soft"])
        x += max(wpt + 24, 96)
    t.paint(t.poly([(10, 336), (width - 10, 336), (width - 10, height - 10), (10, height - 10)]), P["panel"][1])
    t.text(20, 342, 14, "Built from the images (left of each pair) and drawn by seam_kit.py (right), as the game lays "
                        "them", "#EDE6D6")
    worst = []
    fits = [("the panel, at the list's 202 by 252", fit_panel(), 20, 366),
            ("the rail, Reinforce open", fit_rail("Reinforce"), 500, 366),
            ("the rail, War Emblems open", fit_rail("War Emblems"), 720, 366),
            ("the lit press, 92 by 44", fit_press(), 960, 366),
            ("a slider at rest, 70%", fit_slider(0.7, False), 960, 492),
            ("a slider held, 40%", fit_slider(0.4, True), 960, 602)]
    for words, (b, d), fx, fy in fits:
        diff = np.abs(b[..., :3] - d[..., :3]).max(axis=-1)
        worst.append((words, float(diff.mean()), float(np.percentile(diff, 99))))
        wpt = b.shape[1] / K
        rs.paste(sheet.px, b, round(fx * K), round(fy * K))
        rs.paste(sheet.px, d, round((fx + wpt + 6) * K), round(fy * K))
        t.text(fx, fy + b.shape[0] / K + 4, 11, f"{words}: mean {worst[-1][1]:.3f}, 99th {worst[-1][2]:.3f}",
               P["soft"])
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px.astype(np.float32), path)
    return worst


def main():
    HANDOFF.joinpath("images").mkdir(parents=True, exist_ok=True)
    images()
    for name, (px, _) in MADE.items():
        rs.save(px.astype(np.float32), HANDOFF / "images" / f"{name}.png")
    kit_panel_masks()
    worst = sheet_of(HANDOFF / "seam_cut.png")
    (HANDOFF / "seam.json").write_text(json.dumps(seam_json(), indent=2), encoding="utf-8", newline="\n")
    for words, mean, p99 in worst:
        print(f"fit {words}: mean {mean:.4f}, 99th {p99:.4f}")
    print(f"cut: {sum(not n.startswith('Kit') for n in MADE)} images and seam.json into {HANDOFF}")


if __name__ == "__main__":
    main()
