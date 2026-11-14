"""AR12, the HUD's colour (docs/asset-requests.md, AR12): three directions for the director's pick, over the HUD as the
game lays it out on a phone in landscape, over a dusk street and a noon one, with the glance strip at true size and the
new parts up close.

What every direction holds:
  - a colour per system, each with its own icon so they part without colour too: Power keeps electricity's yellow (the
    same meaning, not a reuse) on a bolt; Credits takes a new teal on a coin; Voidkin takes the void's lavender, the light
    a shard opens with (Void Violet's accent), on a shard. The Base's dock button wears Power's yellow: the base is the
    power plant. The hint wears the icon and colour of the system it points to.
  - the Power pill in kW: generation, then what's used, a thread for the share; over generation, the battery's mark and
    the thread's last part drawn in dashes, from the battery.
  - the lead's card: the type's stud bigger, the rarity's glow harder (Common keeps no glow: its first glow is Rare's).
  - the signature's readout and the spectate eye redrawn as one family, cut as the dock's buttons are: the readout is a
    plate holding the signature's own icon, its well filling with light like a conduit, slanted as the bars are; ready,
    it's full, white-hot, and its icon turns dark on the light. The eye opens when spectate is on and shuts when it's
    off. Both sit under the lead's card, the lead's own corner, clear of both thumbs.
How far the colour goes is the axis: A, accents only; B, edges and channels; C, a light field behind each piece.

The phone: the HUD lives inside the safe area measured on Faber's capture of an iPhone in landscape (Roblox's bar above,
the island's inset at each side). The thumbstick, the jump button, Roblox's bar and the island are drawn as plain stand-ins
for the room they take. The dusk street is Lantern Row's look (tools/blender/lantern_row_look.py, `M`); the noon street is
ui_sheet's drawn stand-in. Text is Blender's face standing in for the game's.

    blender -b --factory-startup --python tools/blender/hud_colour_sheet.py -- build/handoff/UI/hud/colour
"""
import ctypes
import gc
import json
import math
import sys
from ctypes import wintypes
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lead_card_art as lc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402
import ui_kit as kit  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c, cut_box  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
CARD = REPO / "build" / "handoff" / "UI" / "hud" / "lead_card"
DUSK = REPO / "build" / "scratch" / "modulo" / "lanternrow" / "M_frame.png"
K4 = kit.K
BOX = kit.BOX

W, H = 812.0, 375.0
SAFE = (58.0, 56.0, 758.0, 375.0)  # left, top, right, bottom: measured on Faber's iPhone capture, 2026-11-14
PAD, TOP, GAP, PILL = 8.0, 17.0, 6.0, 30.0
IVORY, INK, STROKE = ui.LIGHT, "#14161B", ui.STROKE
GRAPHITE = kit.PALETTES["Graphite Dark"]

POWER, CREDITS, VOIDKIN = ui.CHARGE, "#40DCC6", "#DCCBFF"
PALE = {POWER: "#FFF7C2", CREDITS: "#D6FFF7", VOIDKIN: "#FAF7FF"}
DEEP = {POWER: "#B88A14", CREDITS: "#13867A", VOIDKIN: "#7C66CC"}

TRIM = {"Common": ("#666C78", "#8E95A3"), "Mythical": ("#FF8794", "#FF8794")}  # at reach 1, and from reach 2
GLOW = {"Common": None, "Mythical": "#FF2848"}  # the frames' own glow colours (ui_sheet.RARITIES)
NAME_W = {"Rook": 40.0, "Lyric": 41.0}  # the names' widths in Blender's face, which stands in for the game's here

DIRECTIONS = (
    ("A", "Signal", 1, "Accents only. Each system's icon and its words carry its colour; the panels stay Graphite."),
    ("B", "Conduit", 2, "The colour reaches the edges and channels: each piece's rim, its thread and its base light take "
                        "its system's colour; the rarity's glow and the type's stud burn harder."),
    ("C", "Glow", 3, "A coloured light field behind each piece, its body warmed toward its colour, and the lead's rarity "
                     "lighting the card from behind."),
)
# The two screens: who leads, the readout's state, the eye's, and the Power pill's.
SCENES = (
    dict(kind="dusk", who="Rook", rarity="Common", type_="Strength", class_="Warrior", level=12, hp="1,204 / 1,543",
         health=0.78, xp=0.42, share=1.0, eye=False, covering=False, signature="Haymaker"),
    dict(kind="noon", who="Lyric", rarity="Mythical", type_="Technique", class_="Healer", level=48, hp="9,870 / 14,200",
         health=0.69, xp=0.8, share=0.62, eye=True, covering=True, signature="HeldNote"),
)


# --- colour --------------------------------------------------------------------------------------------------------

def mix(a, b, t):
    v = c(a) + (c(b) - c(a)) * t
    return "#" + "".join(f"{int(round(min(max(x, 0.0), 1.0) * 255)):02X}" for x in v[:3])


def palette(accent, reach):
    """Graphite, with the system's colour as far as the direction takes it."""
    p = dict(GRAPHITE)
    if reach >= 2:  # the kit's bold rim, in the system's colour
        p.update(edge=accent, border=1.6, glint=mix(GRAPHITE["glint"], accent, 0.6),
                 channel=mix(GRAPHITE["channel"], accent, 0.1), accent=accent)
    if reach >= 3:
        p.update(panel=(mix(GRAPHITE["panel"][0], accent, 0.3), mix(GRAPHITE["panel"][1], accent, 0.12)),
                 button=(mix(GRAPHITE["button"][0], accent, 0.3), mix(GRAPHITE["button"][1], accent, 0.12)))
    return p


def ramp3(t, pale, mid, deep, v):
    v = np.clip(v, 0, 1)[..., None]
    a, b, d = c(pale), c(mid), c(deep)
    return np.where(v < 0.5, a + (b - a) * (v * 2), b + (d - b) * (v * 2 - 1)).astype(np.float32)


# --- drawing helpers ------------------------------------------------------------------------------------------------

def box(a, r, axis):
    a = np.moveaxis(a, axis, 0)
    p = np.concatenate([np.zeros((r + 1,) + a.shape[1:], a.dtype), a, np.zeros((r,) + a.shape[1:], a.dtype)])
    s = np.cumsum(p, axis=0, dtype=np.float32)
    return np.moveaxis((s[2 * r + 1:] - s[:-2 * r - 1]) / (2 * r + 1), 0, axis)


def halo(alpha, colour, radius_pts, strength):
    """A soft glow from a picture's cover, in one colour."""
    r = max(1, round(radius_pts * K4 / 2))
    g = alpha.astype(np.float32)
    for _ in range(3):
        g = box(box(g, r, 0), r, 1)
    out = np.zeros(alpha.shape + (4,), np.float32)
    out[..., :3] = c(colour)
    out[..., 3] = np.clip(g * strength, 0, 1)
    return out


def field(st, x, y, w, h, colour, radius, strength, cut=8.0):
    """A light field behind a piece: its colour spilling into the world round it."""
    m = radius * 3
    t = kit.blank(w + 2 * m, h + 2 * m)
    t.glow(t.poly(cut_box(m, m, m + w, m + h, cut, 0, cut, 0)), radius, c(colour), strength)
    rs.paste(st.px, t.px, round((x - m) * K4), round((y - m) * K4))


def seg(t, a, b, w):
    return ui.sd_segment(t.x, t.y, a, b) - w / 2


def place(st, t, x, y):
    rs.paste(st.px, t.px, round(x * K4), round(y * K4))


# --- glyphs: shapes as distances, negative inside --------------------------------------------------------------------

def g_haymaker(t, cx, cy, r):
    """Rook's Haymaker by its hero shape, B5's stamp: the square's frame round its plate, come down and squashed on the
    floor, the floor's two runs going out from its foot, and the fall's speed lines above it, apart from it."""
    x0, y0, x1, y1 = cx - 0.66 * r, cy - 0.12 * r, cx + 0.66 * r, cy + 0.56 * r

    def box_in(i):
        return t.poly(cut_box(x0 + i, y0 + i, x1 - i, y1 - i, 0.14 * r, 0.14 * r, 0, 0))
    frame = np.maximum(box_in(0.0), -box_in(0.15 * r))
    plate = box_in(0.27 * r)
    runs = [t.poly([(cx + s * 0.58 * r, y1 - 0.2 * r), (cx + s * 1.24 * r, y1 - 0.02 * r), (cx + s * 0.58 * r, y1)])
            for s in (1, -1)]
    lines = [seg(t, (cx + dx * r, y0 - 0.24 * r), (cx + dx * r, y0 - (0.24 + length) * r), 0.13 * r)
             for dx, length in ((-0.42, 0.42), (0.0, 0.66), (0.42, 0.42))]
    return np.minimum.reduce([frame, plate] + runs + lines)


def g_heldnote(t, cx, cy, r):
    """Lyric's Held Note: the note's source and two crests spreading from it."""
    sx = cx - 0.82 * r
    dx, dy = t.x - sx, t.y - cy
    dist, ang = np.hypot(dx, dy), np.abs(np.arctan2(dy, dx))
    parts = [dist - 0.26 * r]
    for radius, w, half in ((0.86 * r, 0.22 * r, 0.66), (1.46 * r, 0.26 * r, 0.54)):
        parts.append(np.maximum(np.abs(dist - radius) - w / 2, (ang - half) * radius))
    return np.minimum.reduce(parts)


SIGNATURES = {"Haymaker": g_haymaker, "HeldNote": g_heldnote}


def g_shard(t, cx, cy, r):
    return t.poly([(cx + r * u, cy + r * v) for u, v in ((0.12, -1.0), (0.58, -0.32), (0.4, 0.96), (-0.22, 1.0),
                                                          (-0.62, 0.14), (-0.3, -0.56))])


def g_plant(t, cx, cy, r):
    return t.poly([(cx + r * u, cy + r * v) for u, v in ((0, -1.0), (0.96, -0.16), (0.96, 0.96), (-0.96, 0.96),
                                                          (-0.96, -0.16))])


BOLT = ((0.25, -1), (-0.55, 0.12), (-0.05, 0.12), (-0.3, 1), (0.55, -0.2), (0.05, -0.2))


def lens(t, cx, cy, a, b):
    rad = (a * a + b * b) / (2 * b)
    k = rad - b
    return np.maximum(np.hypot(t.x - cx, t.y - (cy + k)) - rad, np.hypot(t.x - cx, t.y - (cy - k)) - rad)


def eye_open(t, cx, cy, r, colour, iris):
    d = lens(t, cx, cy, 0.98 * r, 0.58 * r)
    t.paint(d - 1.4, c(STROKE))
    t.paint(d, c(colour))
    t.paint(np.maximum(np.hypot(t.x - cx, t.y - cy) - 0.42 * r, d), c(iris))
    t.paint(np.hypot(t.x - cx - 0.13 * r, t.y - cy + 0.13 * r) - 0.12 * r, c(colour))


def eye_shut(t, cx, cy, r, colour):
    def lid(u):
        return cx + 0.98 * r * u, cy - 0.1 * r + 0.34 * r * (1 - u * u)
    pts = [lid(u) for u in np.linspace(-1, 1, 15)]
    parts = [seg(t, a, b, 0.17 * r) for a, b in zip(pts, pts[1:])]
    for u in (-0.6, 0.0, 0.6):
        px, py = lid(u)
        parts.append(seg(t, (px, py), (px + 0.2 * r * u, py + 0.34 * r), 0.15 * r))
    d = np.minimum.reduce(parts)
    t.paint(d - 1.4, c(STROKE))
    t.paint(d, c(colour))


# --- the icons, kept as the kit keeps its own ------------------------------------------------------------------------

def icons():
    m, r = BOX / 2, 12.0

    def body(t, d, accent):
        t.paint(d - 2.0, c(STROKE))
        t.paint(d, ramp3(t, PALE[accent], accent, DEEP[accent], (t.y - m + r) / (2 * r)))

    t = kit.blank(BOX, BOX)  # Credits: a minted coin
    d = t.poly([(m + r * math.cos(a), m + r * math.sin(a)) for a in (math.radians(22.5 + 45 * i) for i in range(8))])
    body(t, d, CREDITS)
    t.line(d + 1.7, 1.0, c(DEEP[CREDITS]), 0.9)
    t.paint(t.poly([(m, m - r * 0.44), (m + r * 0.32, m), (m, m + r * 0.44), (m - r * 0.32, m)]), c(DEEP[CREDITS]))
    kit.keep("CoinMint", t, use="Credits")

    t = kit.blank(BOX, BOX)  # Voidkin: a shard, its far facet in shade, a crack of light down its ridge
    d = g_shard(t, m, m, r)
    body(t, d, VOIDKIN)
    shade = t.poly([(m + r * u, m + r * v) for u, v in ((0.12, -1.0), (0.0, 0.12), (-0.22, 1.0), (-0.62, 0.14), (-0.3, -0.56))])
    t.paint(np.maximum(d, shade), c(DEEP[VOIDKIN]), 0.55)
    t.paint(np.maximum(d, np.minimum(seg(t, (m + 0.12 * r, m - 0.9 * r), (m, m + 0.12 * r), 1.1),
                                     seg(t, (m, m + 0.12 * r), (m - 0.18 * r, m + 0.9 * r), 1.1))), c("#FFFFFF"), 0.9)
    kit.keep("Shard", t, use="Voidkin; a hint that points to shards")

    t = kit.blank(BOX, BOX)  # the Base: the plant, a bolt cut through it
    d = g_plant(t, m, m, r)
    body(t, d, POWER)
    t.paint(t.poly([(m + r * 0.55 * u, m + r * 0.22 + r * 0.6 * v) for u, v in BOLT]), c(INK))
    kit.keep("Plant", t, use="the Base")

    t = kit.blank(BOX, BOX)  # the battery, covering demand: two of its three cells left
    cell = t.poly(cut_box(m - 12, m - 7, m + 9, m + 7, 2, 0, 2, 0))
    nub = t.poly(cut_box(m + 9, m - 3.2, m + 12.5, m + 3.2))
    d = np.minimum(cell, nub)
    t.paint(d - 2.0, c(STROKE))
    t.paint(d, c(DEEP[POWER]))
    t.paint(cell + 1.6, c(GRAPHITE["channel"]))
    for i in range(2):
        t.paint(t.poly(cut_box(m - 9.6 + i * 6.2, m - 4.4, m - 5.0 + i * 6.2, m + 4.4)), ramp3(t, PALE[POWER], POWER, DEEP[POWER], (t.y - m + 5) / 10))
    kit.keep("Battery", t, use="the battery, when it covers demand over generation")


# --- the pieces -----------------------------------------------------------------------------------------------------

def pill(st, x, y, w, accent, reach, icon, value, extra=None, extra_colour=None, fill=None, drain=0.0, mark=None):
    p = palette(accent, reach)
    if reach >= 3:
        field(st, x, y, w, PILL, accent, 11.0, 0.55, cut=9)
    st.lay("PanelShadow", x, y, w, PILL)
    st.lay("PanelFill", x, y, w, PILL, tint=p["panel"], alpha=p["alpha"])
    st.lay("PanelEdge" + ("Bold" if reach >= 2 else ""), x, y, w, PILL, tint=p["edge"], alpha=0.95 if reach < 2 else 1.0)
    st.lay("PanelGlint", x, y, w, PILL, tint=p["glint"])
    lift = 2 if fill is not None else 0
    st.icon(icon, x + 17, y + PILL / 2 - lift / 2, 21.0)
    ty = y + (PILL - 14 * ui.CAP) / 2 - lift
    st.text(x + 31, ty, 14, value, p["text"])
    if extra:
        st.text(x + w - 10, ty, 14, extra, extra_colour or p["soft"], "RIGHT")
    if mark:
        st.icon(mark[0], x + mark[1], y + PILL / 2 - lift / 2, 17.0)
    if fill is not None:
        tx, tw = x + 31, w - 40
        kit.bar(st, tx, y + PILL - 8, tw, 3.0, fill, p, accent)
        if drain:  # the share the battery covers: the light in dashes, from the battery's end
            x0 = tx + tw * (1 - drain)
            cols, rows = round((tx + tw - 2 - x0) * K4), round(3.0 * K4)
            dash = np.zeros((rows, cols, 4), np.float32)
            dash[..., :3] = c(p["channel"])
            dash[..., 3] = (((np.arange(cols) / K4) % 4.0) < 2.0)[None, :] * 1.0
            rs.paste(st.px, dash, round(x0 * K4), round((y + PILL - 8) * K4))


def dock(st, x, y, label, icon, accent, reach):
    p = palette(accent, reach)
    if reach >= 3:
        field(st, x, y, 96, 52, accent, 12.0, 0.5)
    kit.button(st, x, y, 96, 52, "", p, "rest")
    st.icon(icon, x + 22, y + 25, 24.0)
    st.text(x + 38, y + (52 - 14 * ui.CAP) / 2 - 1, 14, label, p["text"])


def hint(st, x, y, w, text, reach):
    p = palette(VOIDKIN, reach)
    if reach >= 3:
        field(st, x, y, w, PILL, VOIDKIN, 10.0, 0.4, cut=9)
    kit.panel(st, x, y, w, PILL, p)
    st.icon("Shard", x + 18, y + PILL / 2, 20.0)
    st.text(x + w / 2 + 10, y + (PILL - 14 * ui.CAP) / 2, 14, text, IVORY, "CENTER")


def plate(t, o, s, cut):
    return t.poly(cut_box(o, o, o + s, o + s, cut, 0, cut, 0))


def readout(st, x, y, s, share, signature, reach):
    """The signature's readout: a plate cut as the dock's buttons are, its well a conduit that fills with light from the
    foot, its front slanted as the bars' is, the signature's own icon over it. Ready, it's full and white-hot, it glows,
    and its icon turns dark on the light: the loudest thing on the HUD."""
    ready = share >= 1.0
    g = 26.0
    if ready and reach >= 3:
        field(st, x, y, s, s, IVORY, 13.0, 0.42, cut=s * 0.2)
    t = kit.blank(s + 2 * g, s + 2 * g)
    cut, inset = s * 0.2, 4.0
    outer = plate(t, g, s, cut)
    inner = plate(t, g + inset, s - 2 * inset, cut * 0.75)
    if ready:
        t.glow(outer, (7.0, 9.0, 11.0)[reach - 1], c(IVORY), (0.6, 0.72, 0.85)[reach - 1])
    t.glow(outer, 4.0, ui.BLACK, 0.35)
    t.paint(outer, t.ramp(GRAPHITE["button"][0], GRAPHITE["button"][1], (t.y - g) / s), 0.96)
    t.paint(inner, c(GRAPHITE["channel"]))
    top, low = g + inset, g + s - inset
    level = low - (low - top) * share - (t.x - g - s / 2) * 0.12  # the light's front, leaning as a bar's does
    lit = np.maximum(inner, level - t.y)
    if ready:
        t.paint(inner, t.ramp("#FFFDF6", IVORY, (t.y - top) / (low - top)))
        t.paint(np.maximum(inner, np.abs(t.x - g - s / 2) - s * 0.16), c("#FFFFFF"), 0.5)
    else:  # dim light below its front, brightest just under it, the front a bright line
        t.paint(lit, c(IVORY), 0.34)
        under = np.clip(1 - (t.y - level) / 11.0, 0, 1)
        ui.over(t.px, c(IVORY), np.clip(0.5 - lit * K4, 0, 1) * under * 0.5)
        t.paint(np.maximum(inner, np.abs(t.y - level) - 0.9), c(IVORY), 0.95)
    if reach >= 2 or ready:
        t.line(inner, 0.8, c(IVORY), 0.35 if not ready else 0.9)
    t.line(outer, 1.0, c(IVORY if ready else GRAPHITE["edge"]))
    d = SIGNATURES[signature](t, g + s / 2, g + s / 2 + 1, s * 0.27)
    if ready:
        t.paint(d - 1.4, c("#FFFFFF"))
        t.paint(d, c(INK))
    else:
        t.paint(d - 1.6, c(STROKE))
        t.paint(d, c(IVORY), 0.92)
    place(st, t, x - g, y - g)


def spectate(st, x, y, s, on, reach):
    """The spectate eye, the readout's small sibling: open and lit when on, shut and dim when off."""
    g = 20.0
    t = kit.blank(s + 2 * g, s + 2 * g)
    cut = s * 0.2
    outer = plate(t, g, s, cut)
    if on:
        t.glow(outer, 5.0, c(IVORY), 0.45 if reach < 3 else 0.6)
    t.glow(outer, 4.0, ui.BLACK, 0.35)
    t.paint(outer, t.ramp(GRAPHITE["button"][0], GRAPHITE["button"][1], (t.y - g) / s) * (1.0 if on else 0.8), 0.96)
    t.line(outer, 1.0, c(GRAPHITE["edge"]))
    if on:
        t.line(outer + 0.6, 1.4, c(IVORY))
        t.paint(np.maximum(outer + 0.8, g + s - 2.6 - t.y), c(IVORY))
        eye_open(t, g + s / 2, g + s / 2, s * 0.32, IVORY, INK)
    else:
        eye_shut(t, g + s / 2, g + s / 2, s * 0.32, GRAPHITE["soft"])
    place(st, t, x - g, y - g)


# --- the lead's card and the target's, from their images --------------------------------------------------------------

DATA, IMG = None, None


def card_images():
    global DATA, IMG
    DATA = json.loads((CARD / "lead_card.json").read_text(encoding="utf-8"))
    IMG = {n: rs.load(CARD / e["file"]) for n, e in DATA["images"].items()}


def lead(st, x, y, sc, reach):
    e = DATA["images"]

    def at(name, px=None):
        en = e[name]
        rs.paste(st.px, IMG[name] if px is None else px, round((x + en["at"][0] - en["pad"]) * K4),
                 round((y + en["at"][1] - en["pad"]) * K4))

    rarity, who = sc["rarity"], sc["who"]
    trim, glow = TRIM[rarity][0 if reach < 2 else 1], GLOW[rarity]
    fx, fy, fw, fh = lc.FRAME
    if glow and reach >= 3:  # the rarity lights the card from behind
        t = kit.blank(fw + 120, fh + 120)
        t.glow(np.hypot(t.x - 60 - fw / 2, (t.y - 60 - fh / 2) * 1.1) - fw * 0.45, 16.0, c(glow), 0.5)
        place(st, t, x + fx - 60, y + fy - 60)
    at("CardHousing")
    at("CardHousingRim", lc.tinted(IMG["CardHousingRim"], trim))
    rows = lc.light_rows()
    for name, share in (("Health", sc["health"]), ("Xp", sc["xp"])):
        xl, y0, xr, h = rows[name]
        n = f"CardLight{name}"
        front = lc.FILL_FROM + (xr - lc.FILL_FROM) * share
        width = max(front - xl + h * lc.SLANT + lc.GLOW, e[n]["cut"][0] + e[n]["cut"][2])
        rs.paste(st.px, lc.sliced(IMG[n], e[n]["cut"], width), round((x + xl - h * lc.SLANT) * K4), round((y + y0) * K4))
    name_w = NAME_W[who]
    tab_w = 66.0 + name_w + 22.0 - lc.left(lc.TAB_TOP)
    et = e["CardTab"]
    for n in ("CardTab", "CardTabRim"):
        px = lc.sliced(IMG[n], et["cut"], tab_w + (lc.TAB_FOOT - lc.TAB_TOP) * lc.SLANT + 2 * et["pad"])
        at(n, lc.tinted(px, trim) if n.endswith("Rim") else px)
    at(f"CardFace{who}")
    frame = IMG[f"CardFrame{rarity}"]
    if glow and reach >= 2:  # the frame's own glow, burned harder
        at(f"CardFrame{rarity}", halo(frame[..., 3], glow, 5.0, (1.3, 1.7)[reach - 2]))
    at(f"CardFrame{rarity}")
    if f"CardHead{who}" in e:
        at(f"CardHead{who}")
    at("CardBadge")
    at("CardBadgeRim", lc.tinted(IMG["CardBadgeRim"], trim))
    # the type's stud, where the bars meet the frame: bigger, its rim in the type's own colour from reach 2
    type_colour = ss.TYPES[sc["type_"]]
    r = 8.5
    cx, cy = x + fx + fw + 0.5, y + DATA["geometry"]["mid"]
    t = kit.blank(2 * r + 24, 2 * r + 24)
    d = np.hypot(t.x - r - 12, t.y - r - 12) - r
    if reach >= 2:
        t.glow(d, (3.5, 5.0)[reach - 2], c(type_colour), (0.55, 0.75)[reach - 2])
    t.paint(d, c("#000000"))
    t.line(d, 1.6, c(type_colour if reach >= 2 else trim))
    place(st, t, cx - r - 12, cy - r - 12)
    st.icon(f"Gem{sc['type_']}", cx, cy, 2 * r * 0.8 + 1)
    st.icon(f"Class{sc['class_']}", x + 66 + name_w + 11, y + 26, 13.0)
    st.text(x + 66, y + 20.6, 16, who, IVORY)
    st.text(x + 14, y + 80 - 14 * ui.CAP / 2, 13, str(sc["level"]), "#F2CB62", "CENTER")
    xl, y0, xr, h = rows["Health"]
    front = lc.FILL_FROM + (xr - lc.FILL_FROM) * sc["health"]
    st.text(x + (xl + front) / 2 + 4, y + y0 + (h - 13 * ui.CAP) / 2, 13, sc["hp"], "#FFFFFF", "CENTER")


def target(st, x, y, health):
    """The target's card, as UI.TargetCard lays it, with a Shade's grey trim. Unchanged by the directions."""
    e, g = DATA["images"], DATA["geometry"]["target"]
    dx, dy = g["offset"]
    hx0, hy0, hx1, hy1 = g["housing"]
    trim = "#666C78"
    eh = e["CardTargetHousing"]
    for n in ("CardTargetHousing", "CardTargetHousingRim"):
        px = lc.sliced(IMG[n], eh["cut"], hx1 - hx0 + 2 * eh["pad"])
        rs.paste(st.px, lc.tinted(px, trim) if n.endswith("Rim") else px, round((x + hx0 - eh["pad"]) * K4),
                 round((y + hy0 - eh["pad"]) * K4))
    xl, y0, xr, h = g["health"]
    el = e["CardLightHealth"]
    front = g["fillFrom"] + (xr - g["fillFrom"]) * health
    width = max(front - xl + h * lc.SLANT + lc.GLOW, el["cut"][0] + el["cut"][2])
    rs.paste(st.px, lc.sliced(IMG["CardLightHealth"], el["cut"], width), round((x + xl - h * lc.SLANT) * K4), round((y + y0) * K4))
    et = e["CardTab"]
    tab_w = (lc.T_NAME_X - lc.left(lc.TAB_TOP)) + 74.0 + lc.T_TAB_AFTER
    for n in ("CardTab", "CardTabRim"):
        px = lc.sliced(IMG[n], et["cut"], tab_w + (lc.TAB_FOOT - lc.TAB_TOP) * lc.SLANT + 2 * et["pad"])
        rs.paste(st.px, lc.tinted(px, trim) if n.endswith("Rim") else px, round((x + et["at"][0] + dx - et["pad"]) * K4),
                 round((y + et["at"][1] + dy - et["pad"]) * K4))
    nx = x + lc.T_NAME_X + dx
    st.text(nx, y + 2.6, 16, "Shade", IVORY)
    st.text(nx + 50, y + 3.6, 13, "Lv 3", "#F2CB62")


# --- the screen -------------------------------------------------------------------------------------------------------

class _Memory(ctypes.Structure):
    _fields_ = [("cb", wintypes.DWORD), ("faults", wintypes.DWORD)] + [
        (n, ctypes.c_size_t) for n in ("peak", "now", "qpp", "qp", "qpn", "qn", "page", "peak_page")]


def stage(name):
    """Prints what this Blender holds after each stage, so a guard's stop says where the memory went."""
    gc.collect()
    m = _Memory()
    m.cb = ctypes.sizeof(m)
    k32 = ctypes.windll.kernel32
    k32.GetCurrentProcess.restype = wintypes.HANDLE
    k32.K32GetProcessMemoryInfo.argtypes = (wintypes.HANDLE, ctypes.POINTER(_Memory), wintypes.DWORD)
    k32.K32GetProcessMemoryInfo(k32.GetCurrentProcess(), ctypes.byref(m), m.cb)
    print(f"{name}: {m.now / 2 ** 20:.0f} MB, peak {m.peak / 2 ** 20:.0f} MB", flush=True)


def resize(px, w, h):
    """Drawn up by Blender's own scaler, which needs none of numpy's full-size temporaries."""
    sh, sw = px.shape[:2]
    image = bpy.data.images.new("Up", sw, sh, alpha=True, float_buffer=False)  # 8 bits: a street needs no more
    image.pixels.foreach_set(np.ascontiguousarray(px[::-1], np.float32).ravel())
    image.scale(w, h)
    out = np.empty(w * h * 4, np.float32)
    image.pixels.foreach_get(out)
    bpy.data.images.remove(image)
    return np.flip(out.reshape(h, w, 4), 0)  # row 0 = the top, as a view: no second copy


def backdrop(kind):
    if kind == "dusk":
        src = rs.load(DUSK)
        sh, sw = src.shape[:2]
        ch = round(sw * H / W)
        top = (sh - ch) // 2
        src = src[top:top + ch]
    else:  # drawn at 2 pixels a point, then drawn up: it's only the world behind
        ui.K = 2
        sheet = ui.Sheet(W, H, "#000000")
        ui.world(sheet.tile(0, 0, W, H), "noon")
        ui.K = K4
        src = sheet.px
    px = resize(src, round(W * K4), round(H * K4))
    px[..., 3] = 1.0
    return px


def phone(st):
    """The room the phone's own things take: Roblox's bar, the thumbstick, the jump button, the island, the corners.
    Each on a small tile of its own, in the screen's points."""
    shade, pale = c("#101116"), c("#D9DADF")

    def tile(x0, y0, x1, y1, draw):
        t = kit.blank(x1 - x0, y1 - y0)
        draw(t, t.x + x0, t.y + y0)
        place(st, t, x0, y0)

    def bar(t, x, y):
        t.paint(np.hypot(x - 92.5, y - 32.5) - 18.5, shade, 0.45)
        t.paint(np.hypot(np.maximum(np.abs(x - 165) - 29.5, 0), y - 32.5) - 18.5, shade, 0.45)
        for cx in (147, 183):
            t.paint(np.maximum(np.abs(x - cx) - 7, np.abs(y - 32.5) - 1.0), c("#E8E8E8"), 0.85)
        t.paint(np.maximum(np.abs(x - 92.5) - 6, np.abs(y - 32.5) - 6), c("#E8E8E8"), 0.85)

    def stick(t, x, y):
        d = np.hypot(x - 121, y - 323)
        t.paint(d - 34, shade, 0.35)
        t.line(d - 34, 2.0, pale, 0.55)
        t.paint(d - 15, pale, 0.45)

    def jump(t, x, y):
        d = np.hypot(x - 703, y - 323)
        t.paint(d - 33, shade, 0.4)
        t.line(d - 33, 2.0, pale, 0.6)
        arrow = [(703, 309), (715, 323), (708, 323), (708, 335), (698, 335), (698, 323), (691, 323)]
        t.paint(ui.sd_polygon(x, y, arrow), pale, 0.7)

    def island(t, x, y):
        t.paint(np.hypot(x - 787.5, np.maximum(np.abs(y - 187) - 42, 0)) - 16.5, c("#000000"))

    rr = 44.0

    def corners(t, x, y):
        qx = np.maximum(np.abs(x - W / 2) - (W / 2 - rr), 0)
        qy = np.maximum(np.abs(y - H / 2) - (H / 2 - rr), 0)
        t.paint(rr - np.hypot(qx, qy), c("#000000"))

    tile(70, 10, 218, 56, bar)
    tile(84, 286, 158, 360, stick)
    tile(667, 287, 739, 359, jump)
    tile(768, 142, 806, 232, island)
    for x0, y0 in ((0, 0), (W - rr, 0), (0, H - rr), (W - rr, H - rr)):
        tile(x0, y0, x0 + rr, y0 + rr, corners)


def halve(px):
    """Half the size, each pixel the mean of four, on premultiplied colour. Works in the picture's own memory, so the
    picture given is spent."""
    h, w = px.shape[0] // 2 * 2, px.shape[1] // 2 * 2
    pm = px[:h, :w]
    pm[..., :3] *= pm[..., 3:]
    pm = pm.reshape(h // 2, 2, w // 2, 2, 4).mean(axis=(1, 3), dtype=np.float32)
    pm[..., :3] /= np.maximum(pm[..., 3:], 1e-6)
    return pm


def screen(sc, reach):
    st = kit.Stage.__new__(kit.Stage)  # its ground is the street, not a fill
    st.w, st.h, st.items = W, H, []
    st.px = backdrop(sc["kind"])
    l, tp, r, b = SAFE
    phone(st)
    target(st, (l + r) / 2 - 108, tp + TOP + 18, 0.56)
    lead(st, l + PAD, tp + TOP, sc, reach)
    card_foot = tp + TOP + 89
    readout(st, l + PAD + 2, card_foot + 10, 58.0, sc["share"], sc["signature"], reach)
    spectate(st, l + PAD + 2 + 58 + 10, card_foot + 10 + 7, 44.0, sc["eye"], reach)
    px = r - PAD
    pill(st, px - 120, tp + TOP, 120, CREDITS, reach, "CoinMint", "35,170")
    py = tp + TOP + PILL + GAP
    if sc["covering"]:
        pill(st, px - 200, py, 200, POWER, reach, "Bolt", "30 kW", "34 kW used", POWER, 1.0, drain=4 / 34,
             mark=("Battery", 96))
    else:
        pill(st, px - 200, py, 200, POWER, reach, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
    mid = (l + r) / 2
    hint(st, mid - 144, b - PAD - 52 - GAP - PILL, 288, "65 shards: into the Breaker", reach)
    dock(st, mid - 99, b - PAD - 52, "Voidkin", "Shard", VOIDKIN, reach)
    dock(st, mid + 3, b - PAD - 52, "Base", "Plant", POWER, reach)
    return bytes8(halve(st.px)), st.items  # kept in 8 bits till the sheets: a quarter of the memory


def bytes8(px):
    return (np.clip(px, 0, 1) * 255 + 0.5).astype(np.uint8)


def floats(px):
    return px.astype(np.float32) / 255 if px.dtype == np.uint8 else px


# --- the sheets -------------------------------------------------------------------------------------------------------

GROUND, HEAD, NOTE = "#191B21", "#F3EFE6", "#C9CDD6"


def add(sheet, px, items, x, y):
    kit.put(sheet, floats(px), x * ui.K, y * ui.K)
    sheet.items += [dict(i, x=i["x"] + x, y=i["y"] + y) for i in items]


def direction_sheet(out, key, name, note, shots):
    ui.K = 2
    m, cap = 20.0, 28.0
    sheet = ui.Sheet(W + 2 * m, 62 + 2 * (H + cap) + 8, GROUND)
    t = sheet.tile(0, 0, sheet.w, 60)
    t.text(m, 14, 17, f"Grow your Anime: the HUD's colour, direction {key}, {name}", HEAD)
    t.text(m, 40, 10, note, NOTE)
    for i, ((px, items), sc) in enumerate(zip(shots, SCENES)):
        y = 62 + i * (H + cap)
        add(sheet, px, items, m, y)
        words = ("Dusk, in a fight: Rook leads (Common), his Haymaker ready; spectate off; Power at rest, 24 of 30 kW used."
                 if sc["kind"] == "dusk" else
                 "Noon (a drawn stand-in street): a Mythical lead (Lyric's face, for the sheet), her Held Note filling; "
                 "spectate on; demand over generation, the battery covering 4 kW.")
        sheet.tile(m, y + H + 8, W, 16).text(0, 0, 10, words, NOTE)
    kit.finish(sheet, out / f"hud_colour_{key}.png")


def glance_sheet(out, shots):
    """The three directions side by side at 1 pixel a point: about a phone's size on a monitor."""
    ui.K = 1
    m, head = 16.0, 30.0
    sheet = ui.Sheet(3 * W + 4 * m, head + 2 * H + 3 * m, GROUND)
    for j, (key, name, _, _) in enumerate(DIRECTIONS):
        x = m + j * (W + m)
        sheet.tile(x, 0, W, head).text(0, 10, 14, f"{key}, {name}", HEAD)
        for i, (px, items) in enumerate(shots[key]):
            add(sheet, halve(floats(px)), items, x, head + i * (H + m))
    kit.finish(sheet, out / "hud_colour_glance.png")


DEUTERANOPIA = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413],
                         [-0.011820, 0.042940, 0.968881]], np.float32)  # Machado, Oliveira and Fernandes 2009, severity 1


def deuteranopia_sheet(out):
    """The glance again as deuteranopia sees it, for AR12's check: the accents must still part, and they part by icon."""
    px = rs.load(out / "hud_colour_glance.png")
    rgb = px[..., :3]
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    lin = np.clip(lin @ DEUTERANOPIA.T, 0, 1)
    px[..., :3] = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)
    rs.save(px, out / "hud_colour_glance_deuteranopia.png")


PARTS_K = 3  # the parts sheet's pixels a point: each row is drawn at the kit's 4, then brought down


def parts_rows():
    """The new parts up close, one row a direction, drawn at the kit's 4 pixels a point and kept at 3."""
    rowh, rows = 150.0, []
    for key, name, reach, _ in DIRECTIONS:
        st = kit.Stage(860, rowh, "#1C1A26")
        st.text(12, 6, 11, f"{key}, {name}", HEAD)
        for i, share in enumerate((0.3, 0.7, 1.0)):
            readout(st, 14 + i * 70, 26, 58.0, share, "Haymaker", reach)
        spectate(st, 232, 33, 44.0, False, reach)
        spectate(st, 288, 33, 44.0, True, reach)
        dock(st, 350, 29, "Voidkin", "Shard", VOIDKIN, reach)
        dock(st, 452, 29, "Base", "Plant", POWER, reach)
        readout(st, 568, 26, 58.0, 0.55, "HeldNote", reach)
        readout(st, 638, 26, 58.0, 1.0, "HeldNote", reach)
        pill(st, 14, 102, 200, POWER, reach, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
        pill(st, 222, 102, 200, POWER, reach, "Bolt", "30 kW", "34 kW used", POWER, 1.0, drain=4 / 34, mark=("Battery", 96))
        pill(st, 430, 102, 120, CREDITS, reach, "CoinMint", "35,170")
        hint(st, 558, 102, 288, "65 shards: into the Breaker", reach)
        rows.append((rs.shrink(st.px, PARTS_K / K4), st.items))
    return rows, rowh


def parts_sheet(out, rows, rowh):
    ui.K = PARTS_K
    sheet = ui.Sheet(860, 24 + len(rows) * rowh, "#1C1A26")
    sheet.tile(0, 0, 860, 24).text(12, 8, 12, "The new parts up close. The readout filling, at 30 and 70 in 100, and "
                                   "ready; the eye off and on; the dock; the Power pill at rest and covering; Credits; the hint.", NOTE)
    for j, (px, items) in enumerate(rows):
        add(sheet, px, items, 0, 24 + j * rowh)
    kit.finish(sheet, out / "hud_colour_parts.png")


def main():
    out = bl.out_dir()
    ui.K = K4
    stage("started")
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    icons()
    card_images()
    stage("the kit's slices and the card's images")
    shots = {}
    for key, name, reach, note in DIRECTIONS:
        shots[key] = []
        for sc in SCENES:
            shots[key].append(screen(sc, reach))
            stage(f"{key}, {sc['kind']}")
    rows, rowh = parts_rows()
    stage("the parts' rows")
    parts_sheet(out, rows, rowh)
    del rows
    stage("the parts' sheet")
    for key, name, reach, note in DIRECTIONS:
        direction_sheet(out, key, name, note, shots[key])
        stage(f"sheet {key}")
    glance_sheet(out, shots)
    stage("the glance")
    deuteranopia_sheet(out)


if __name__ == "__main__":
    main()
