"""AR12, the HUD's and the UI's colour (docs/asset-requests.md, AR12), round 2: the director picked B, Conduit (each
piece's rim, thread and base light in its system's colour), then asked for the colour to go vivid across the HUD and
the UI, with more colours in the palette. This draws B as picked beside two vivid strengths on the same structure, for
research's verdict before any image is made. Round 1's three directions are this file at 77c591e.

What every column holds:
  - a colour per system, each with its own icon so they part without colour too: Power keeps electricity's yellow on a
    bolt; Credits a teal on a coin; Voidkin the void's lavender on a shard; Regalia an indigo on a crest; the Map a rose
    on a folded map. The Base's dock button wears Power's yellow: the base is the power plant. A button's colour is its
    screen's colour.
  - the Power pill in kW: generation, then what's used, a thread for the share; over generation, the battery's mark and
    the thread's last part drawn in dashes, from the battery.
  - the lead's card: the type's stud bigger, the rarity's glow harder (Common keeps no glow: its first glow is Rare's).
  - the signature's readout and the spectate eye as one family, cut as the dock's buttons are, under the lead's card.
    They stay ivory: among coloured pieces, the white-hot ready plate is the one white thing.
How vivid is the axis: B, as picked, on Graphite; Deep, each piece's body a saturated dark of its colour and its words
in its pale; Block, Deep with the icon in ink on a block of its colour.

`ui` draws the screens' side: the kit's four palettes as they are, then the vivid rows, each screen wearing its system's
colour, with a filled main button.

The phone: the HUD lives inside the safe area measured on Faber's capture of an iPhone in landscape (Roblox's bar above,
the island's inset at each side). The thumbstick, the jump button, Roblox's bar and the island are drawn as plain stand-ins
for the room they take. The dusk street is Lantern Row's look (tools/blender/lantern_row_look.py, `M`); the noon street is
ui_sheet's drawn stand-in. Text is Blender's face standing in for the game's.

    blender -b --factory-startup --python tools/blender/hud_colour_sheet.py -- build/handoff/UI/hud/colour [hud|ui|voidkin|images]
"""
import ctypes
import gc
import json
import math
import sys
import textwrap
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

# A system's colour: measured apart from every colour that already means something, and from each other in plain sight
# and under deuteranopia and protanopia (build/scratch/modulo/hud/colours.py; the numbers are in AR12's record).
POWER, CREDITS, VOIDKIN, REGALIA, MAP = ui.CHARGE, "#40DCC6", "#DCCBFF", "#6C7BFF", "#FF5C93"
PALE = {POWER: "#FFF7C2", CREDITS: "#D6FFF7", VOIDKIN: "#FAF7FF", REGALIA: "#E2E6FF", MAP: "#FFE3EE"}
DEEP = {POWER: "#B88A14", CREDITS: "#13867A", VOIDKIN: "#7C66CC", REGALIA: "#3340B8", MAP: "#B8245C"}
NIGHT = {POWER: ("#4D3711", "#211605"), CREDITS: ("#0E4541", "#071E1F"), VOIDKIN: ("#35286B", "#171033"),
         REGALIA: ("#1D2A6E", "#0C1233"), MAP: ("#5A1D3F", "#260B1B")}  # a piece's body from Deep on: top, foot

TRIM = {"Common": "#8E95A3", "Mythical": "#FF8794"}
NAME_W = {"Rook": 40.0, "Lyric": 41.0}  # the names' widths in Blender's face, which stands in for the game's here

B, DEEPER, BLOCK = 0, 1, 2  # how vivid: a column's level
DIRECTIONS = (
    ("B", "Conduit, as picked", B, "The director's pick: each piece's rim, its thread and its base light take its "
                                   "system's colour, on Graphite. Research's three fixes are in."),
    ("V1", "Vivid, Deep", DEEPER, "B's structure. Each piece's body is a saturated dark of its own colour, its glint "
                                  "and its words take the colour's pale."),
    ("V2", "Vivid, Block", BLOCK, "Deep, and each icon sits in ink on a block of its system's colour: the HUD's five "
                                  "colours as five solid marks."),
)
# The three screens: who leads, the readout's state, the eye's, and the Power pill's.
ROOK = dict(who="Rook", rarity="Common", type_="Strength", class_="Warrior", level=12, hp="1,204 / 1,543", health=0.78,
            xp=0.42, signature="Haymaker")
SCENES = (
    dict(ROOK, kind="dusk", share=1.0, eye=False, covering=False,
         caption="Dusk, in a fight: Rook leads (Common), his Haymaker ready; spectate off; Power at rest, 24 of 30 kW used."),
    dict(kind="noon", who="Lyric", rarity="Mythical", type_="Technique", class_="Healer", level=48, hp="9,870 / 14,200",
         health=0.69, xp=0.8, share=0.62, eye=True, covering=True, signature="HeldNote",
         caption="Noon (a drawn stand-in street): a Mythical lead (Lyric's face, for the sheet), her Held Note filling; "
                 "spectate on; demand over generation, the battery covering 4 kW."),
    dict(ROOK, kind="noon", share=1.0, eye=False, covering=False,
         caption="Noon again, for the white plate on a pale street: Rook's Haymaker ready; spectate off; Power at rest."),
)


# --- colour --------------------------------------------------------------------------------------------------------

def mix(a, b, t):
    v = c(a) + (c(b) - c(a)) * t
    return "#" + "".join(f"{int(round(min(max(x, 0.0), 1.0) * 255)):02X}" for x in v[:3])


def palette(accent, level):
    """Graphite with the kit's bold rim in the system's colour: B. From Deep on, the body is the colour's own night."""
    p = dict(GRAPHITE, edge=accent, border=1.6, glint=mix(GRAPHITE["glint"], accent, 0.6),
             channel=mix(GRAPHITE["channel"], accent, 0.1), accent=accent)
    if level >= DEEPER:
        top, foot = NIGHT[accent]
        p.update(panel=(top, foot), button=(mix(top, accent, 0.14), mix(foot, accent, 0.08)), pressed=(foot, top),
                 glint=PALE[accent], channel=mix(GRAPHITE["channel"], accent, 0.16), text=PALE[accent],
                 soft=mix(GRAPHITE["soft"], accent, 0.45))
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


BLOCKS = {"BlockPill": ("PanelFill", 30.0, 31.0), "BlockDock": ("ButtonFill", 52.0, 32.0)}  # its slice, height, width


def block_tint(accent):
    """A block's two colours, top and foot."""
    return mix(accent, PALE[accent], 0.35), mix(accent, DEEP[accent], 0.3)


def block_images():
    """Block's block, an image a piece: the piece's own body slice at the piece's height, kept to its left end, its
    right side leaning as the bars' fronts do and ending on a dark seam, so it ends on a cut and not on a blur. White,
    for the engine to tint top to foot; the seam is baked dark and stays dark under any tint."""
    for name, (slice_name, h, width) in BLOCKS.items():
        im = kit.IMAGES[slice_name]
        w = float(math.ceil(width + h * 0.15 + 2.0))
        px = kit.stretch(im["px"], im["cut"], w + 24.0, h)[:, :round(w * K4)]
        rows, cols = px.shape[:2]
        past = np.arange(cols)[None, :] / K4 - (width + (h / 2 - np.arange(rows)[:, None] / K4) * 0.3)
        body = px[..., 3] * np.clip(0.5 - past * K4, 0, 1)
        seam = px[..., 3] * 0.7 * np.clip(0.5 - (np.abs(past - 0.5) - 0.6) * K4, 0, 1)
        t = kit.blank(w, h)
        cover = body + seam * (1 - body)
        t.px[..., :3] = ((body * (1 - seam))[..., None] + seam[..., None] * c(INK)[:3]) / np.maximum(cover, 1e-6)[..., None]
        t.px[..., 3] = cover
        kit.keep(name, t, "the system's block colours, top to foot",
                 use=f"Block: over {slice_name}, under its edge, at the piece's left top; {width:g} points of colour")


def block(st, name, x, y, accent):
    """Block's mark on a piece: its block, in its system's colour."""
    st.lay(name, x, y, tint=block_tint(accent))


def seg(t, a, b, w):
    return ui.sd_segment(t.x, t.y, a, b) - w / 2


def place(st, t, x, y):
    rs.paste(st.px, t.px, round(x * K4), round(y * K4))


# --- glyphs: shapes as distances, negative inside --------------------------------------------------------------------

def g_haymaker(t, cx, cy, r):
    """Rook's Haymaker by its hero shape, B5's stamp, coming down on a slant: the square's frame round its plate,
    leaning into its fall, its speed lines behind it on the same slant, and the floor it comes down on."""
    lean = math.radians(28)
    ax, ay = math.cos(lean), -math.sin(lean)  # the stamp's own right
    dx, dy = math.sin(lean), math.cos(lean)  # its own down: the way it falls
    ox, oy = cx + 0.2 * r, cy + 0.1 * r

    def at(u, v):
        return ox + u * ax + v * dx, oy + u * ay + v * dy

    def box_in(i):
        hw, hh, k = 0.58 * r - i, 0.44 * r - i, 0.14 * r
        return t.poly([at(u, v) for u, v in ((-hw + k, -hh), (hw - k, -hh), (hw, -hh + k), (hw, hh), (-hw, hh),
                                             (-hw, -hh + k))])
    frame = np.maximum(box_in(0.0), -box_in(0.15 * r))
    plate = box_in(0.27 * r)
    lines = [seg(t, at(u, -(0.44 + gap) * r), at(u, -(0.44 + gap + length) * r), 0.13 * r)
             for u, gap, length in ((-0.36, 0.2, 0.5), (0.0, 0.26, 0.78), (0.36, 0.2, 0.42))]
    yf = cy + 0.98 * r
    floor = t.poly([(cx - 1.15 * r, yf), (cx - 0.5 * r, yf - 0.07 * r), (cx + 0.5 * r, yf - 0.07 * r), (cx + 1.15 * r, yf),
                    (cx + 0.5 * r, yf + 0.07 * r), (cx - 0.5 * r, yf + 0.07 * r)])
    return np.minimum.reduce([frame, plate, floor] + lines)


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


def g_bolt(t, cx, cy, r):
    return t.poly([(cx + r * u, cy + r * v) for u, v in BOLT])


def g_coin(t, cx, cy, r):
    return t.poly([(cx + r * math.cos(a), cy + r * math.sin(a)) for a in (math.radians(22.5 + 45 * i) for i in range(8))])


def g_diamond(t, cx, cy, rx, ry):
    return t.poly([(cx, cy - ry), (cx + rx, cy), (cx, cy + ry), (cx - rx, cy)])


def g_crest(t, cx, cy, r):
    """Regalia: a crown's three points over a shield's foot."""
    return t.poly([(cx + r * u, cy + r * v) for u, v in ((-0.88, -0.84), (-0.42, -0.42), (0.0, -0.98), (0.42, -0.42),
                                                          (0.88, -0.84), (0.88, 0.18), (0.0, 1.0), (-0.88, 0.18))])


MAP_FOLD = 0.34  # where the map folds, as a share of its half width


def g_map(t, cx, cy, r):
    """The Map: a sheet folded in three, each fold a step."""
    return t.poly([(cx + r * u, cy + r * v) for u, v in ((-1.0, -0.62), (-MAP_FOLD, -0.9), (MAP_FOLD, -0.62), (1.0, -0.9),
                                                          (1.0, 0.62), (MAP_FOLD, 0.9), (-MAP_FOLD, 0.62), (-1.0, 0.9))])


def map_route(t, cx, cy, r, w):
    """The way across it: two legs and where it ends."""
    a, b, e = (cx - 0.68 * r, cy + 0.34 * r), (cx - 0.08 * r, cy - 0.2 * r), (cx + 0.5 * r, cy + 0.22 * r)
    return np.minimum.reduce([seg(t, a, b, w), seg(t, b, e, w), g_diamond(t, e[0] + 0.1 * r, e[1], 0.24 * r, 0.3 * r)])


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

INK_ICON = {"Bolt": "InkBolt", "CoinMint": "InkCoin", "Shard": "InkShard", "Plant": "InkPlant", "Crest": "InkCrest",
            "Route": "InkRoute"}  # a system's icon, and its mark on Block's block

def icons():
    m, r = BOX / 2, 12.0

    def body(t, d, accent):
        t.paint(d - 2.0, c(STROKE))
        t.paint(d, ramp3(t, PALE[accent], accent, DEEP[accent], (t.y - m + r) / (2 * r)))

    t = kit.blank(BOX, BOX)  # Credits: a minted coin
    d = g_coin(t, m, m, r)
    body(t, d, CREDITS)
    t.line(d + 1.7, 1.0, c(DEEP[CREDITS]), 0.9)
    t.paint(g_diamond(t, m, m, r * 0.32, r * 0.44), c(DEEP[CREDITS]))
    kit.keep("CoinMint", t, use="Credits")

    t = kit.blank(BOX, BOX)  # Regalia: a crest, a gem set in it
    d = g_crest(t, m, m, r)
    body(t, d, REGALIA)
    t.line(d + 1.9, 1.0, c(DEEP[REGALIA]), 0.9)
    gem = g_diamond(t, m, m + 0.14 * r, r * 0.3, r * 0.4)
    t.paint(gem - 1.0, c(DEEP[REGALIA]))
    t.paint(gem, c(PALE[REGALIA]))
    kit.keep("Crest", t, use="Regalia")

    t = kit.blank(BOX, BOX)  # the Map: folded in three, its middle fold in shade, a way drawn across it
    d = g_map(t, m, m, r)
    body(t, d, MAP)
    t.paint(np.maximum(d, np.abs(t.x - m) - MAP_FOLD * r), c(DEEP[MAP]), 0.45)
    t.paint(np.maximum(d, map_route(t, m, m, r, 1.5)), c(INK))
    kit.keep("Route", t, use="the Map")

    # Block's marks: the same five shapes and the plant, in ink, what's inside them cut clean through to the colour
    for name, d in (("InkBolt", lambda t: g_bolt(t, m, m, r * 1.02)),
                    ("InkCoin", lambda t: np.maximum(g_coin(t, m, m, r), -g_diamond(t, m, m, r * 0.34, r * 0.48))),
                    ("InkShard", lambda t: np.maximum(g_shard(t, m, m, r), -np.minimum(
                        seg(t, (m + 0.12 * r, m - 0.66 * r), (m, m + 0.12 * r), 1.7),
                        seg(t, (m, m + 0.12 * r), (m - 0.14 * r, m + 0.66 * r), 1.7)))),
                    ("InkPlant", lambda t: np.maximum(g_plant(t, m, m, r), -g_bolt(t, m, m + r * 0.22, r * 0.6))),
                    ("InkCrest", lambda t: np.maximum(g_crest(t, m, m, r), -g_diamond(t, m, m + 0.14 * r, r * 0.3, r * 0.4))),
                    ("InkRoute", lambda t: np.maximum(g_map(t, m, m, r), -map_route(t, m, m, r, 1.9)))):
        t = kit.blank(BOX, BOX)
        t.paint(d(t), c(INK))
        kit.keep(name, t, use="Block: on a block of its system's colour")

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
    block_images()
    readout_parts()
    eye_parts()


# --- the pieces -----------------------------------------------------------------------------------------------------

def pill(st, x, y, w, accent, level, icon, value, extra=None, extra_colour=None, fill=None, drain=0.0, mark=None):
    p = palette(accent, level)
    solid = level >= BLOCK
    st.lay("PanelShadow", x, y, w, PILL)
    st.lay("PanelFill", x, y, w, PILL, tint=p["panel"], alpha=p["alpha"])
    if solid:
        block(st, "BlockPill", x, y, accent)
    st.lay("PanelEdgeBold", x, y, w, PILL, tint=p["edge"])
    st.lay("PanelGlint", x, y, w, PILL, tint=p["glint"])
    lift = 2 if fill is not None else 0
    left = 41.0 if solid else 31.0  # where the words start
    if solid:
        st.icon(INK_ICON[icon], x + 16.5, y + PILL / 2, 20.0)
    else:
        st.icon(icon, x + 17, y + PILL / 2 - lift / 2, 21.0)
    ty = y + (PILL - 14 * ui.CAP) / 2 - lift
    st.text(x + left, ty, 14, value, p["text"])
    if extra:
        st.text(x + w - 10, ty, 14, extra, extra_colour or p["soft"], "RIGHT")
    if mark:
        st.icon(mark[0], x + mark[1] + (left - 31.0) * 0.6, y + PILL / 2 - lift / 2, 17.0)
    if fill is not None:
        tx, tw = x + left, w - left - 9
        kit.bar(st, tx, y + PILL - 8, tw, 3.0, fill, p, accent)
        if drain:  # the share the battery covers: the light in dashes, from the battery's end
            x0 = tx + tw * (1 - drain)
            cols, rows = round((tx + tw - 2 - x0) * K4), round(3.0 * K4)
            dash = np.zeros((rows, cols, 4), np.float32)
            dash[..., :3] = c(p["channel"])
            dash[..., 3] = (((np.arange(cols) / K4) % 4.0) < 2.0)[None, :] * 1.0
            rs.paste(st.px, dash, round(x0 * K4), round((y + PILL - 8) * K4))


def dock(st, x, y, label, icon, accent, level):
    """A dock button, as kit.button lays one at rest; on Block, its block goes in between the body and the rim."""
    p = palette(accent, level)
    w, h = 96.0, 52.0
    st.lay("ButtonShadow", x, y, w, h)
    st.lay("ButtonFill", x, y, w, h, tint=p["button"])
    if level >= BLOCK:
        block(st, "BlockDock", x, y, accent)
    st.lay("ButtonEdgeBold", x, y, w, h, tint=p["edge"])
    st.lay("ButtonBase", x, y, w, h, tint=accent)
    st.lay("ButtonBaseGlow", x, y, w, h, tint=accent, alpha=0.45)
    if level >= BLOCK:
        st.icon(INK_ICON[icon], x + 17.5, y + 24.5, 23.0)
        st.text(x + 40, y + (h - 14 * ui.CAP) / 2 - 1, 14, label, p["text"])
    else:
        st.icon(icon, x + 22, y + 25, 24.0)
        st.text(x + 38, y + (h - 14 * ui.CAP) / 2 - 1, 14, label, p["text"])


def hint(st, x, y, w, text, level):
    """The hint wears the icon and the colour of the system it points to: here, shards, so Voidkin's."""
    p = palette(VOIDKIN, level)
    st.lay("PanelShadow", x, y, w, PILL)
    st.lay("PanelFill", x, y, w, PILL, tint=p["panel"], alpha=p["alpha"])
    if level >= BLOCK:
        block(st, "BlockPill", x, y, VOIDKIN)
    st.lay("PanelEdgeBold", x, y, w, PILL, tint=p["edge"])
    st.lay("PanelGlint", x, y, w, PILL, tint=p["glint"])
    if level >= BLOCK:
        st.icon("InkShard", x + 16.5, y + PILL / 2, 20.0)
    else:
        st.icon("Shard", x + 18, y + PILL / 2, 20.0)
    st.text(x + w / 2 + 10, y + (PILL - 14 * ui.CAP) / 2, 14, text, p["text"] if level >= DEEPER else IVORY, "CENTER")


def plate(t, o, s, cut):
    return t.poly(cut_box(o, o, o + s, o + s, cut, 0, cut, 0))


READOUT, EYE, WELL = 58.0, 44.0, 4.0  # the readout's side, the eye's, and how far the readout's well sits in
READOUT_PAD, EYE_PAD = 26.0, 20.0  # how far each image reaches past its piece, for its glow
LEAN = 0.12  # the light's front rises this much a point to the right, as a bar's end leans
# The light across its front: points below the line (above it is negative), how solid, its colour. Past the last, it holds.
FRONT = ((-5.8, 0.0, IVORY), (-1.35, 0.55, IVORY), (-1.25, 1.0, "#FFFFFF"), (1.25, 1.0, "#FFFFFF"), (1.35, 0.78, IVORY),
         (5.8, 0.36, IVORY), (8.0, 0.28, IVORY))


def readout_parts():
    """The signature's readout in layers, as the engine stacks them: a plate cut as the dock's buttons are, its well a
    conduit that fills with light from the foot, the light's front leaning as a bar's does and lit along its edge, the
    plate's face over it, then the signature's own icon. Ready, it's one image: full, white-hot, glowing, its icon dark
    on the light, the loudest thing on the HUD. It's ivory at every strength: it belongs to the fight, not to a system."""
    s, g = READOUT, READOUT_PAD
    cut = s * 0.2

    def tile():
        t = kit.blank(s + 2 * g, s + 2 * g)
        return t, plate(t, g, s, cut), plate(t, g + WELL, s - 2 * WELL, cut * 0.75)

    def body(t):
        return t.ramp(GRAPHITE["button"][0], GRAPHITE["button"][1], (t.y - g) / s)

    t, outer, inner = tile()
    t.glow(outer, 4.0, ui.BLACK, 0.35)
    t.paint(outer, body(t), 0.96)
    t.paint(inner, c(GRAPHITE["channel"]))
    kit.keep("ReadoutPlate", t, pad=g, use="the readout, charging: its plate and dark well, under the light")
    t, outer, inner = tile()
    t.paint(np.maximum(outer, -inner), body(t), 0.96)
    t.line(inner, 0.8, c(IVORY), 0.35)
    t.line(outer, 1.0, c(GRAPHITE["edge"]))
    kit.keep("ReadoutFace", t, pad=g, use="the readout, charging: over the light, the plate's face round the well and its rims")
    w = s - 2 * WELL
    t = kit.blank(w, w)  # the well's own shape: a box clip would let the light out past the two cut corners
    t.paint(plate(t, 0.0, w, cut * 0.75), c("#FFFFFF"))
    kit.keep("ReadoutLight", t, use="the readout, charging: the well's shape, white. The light is this image under a "
                                    "gradient that carries the front (pieces.readout)")
    t, outer, inner = tile()
    top, low = g + WELL, g + s - WELL
    t.glow(outer, 9.0, c(IVORY), 0.72)
    t.glow(outer, 4.0, ui.BLACK, 0.35)
    t.paint(outer, body(t), 0.96)
    t.paint(inner, t.ramp("#FFFDF6", IVORY, (t.y - top) / (low - top)))
    t.paint(np.maximum(inner, np.abs(t.x - g - s / 2) - s * 0.16), c("#FFFFFF"), 0.5)
    t.line(inner, 0.8, c(IVORY), 0.9)
    t.line(outer, 1.0, c(IVORY))
    kit.keep("ReadoutReady", t, pad=g, use="the readout, ready: the whole plate, white-hot, with its glow")
    for name, draw in SIGNATURES.items():
        for ready in (False, True):
            t = kit.blank(s, s)
            d = draw(t, s / 2, s / 2 + 1, s * 0.27)
            if ready:
                t.paint(d - 1.4, c("#FFFFFF"))
                t.paint(d, c(INK))
            else:  # dark-edged, so it holds over the light as it rises
                t.paint(d - 2.3, c(STROKE))
                t.paint(d, c(IVORY), 0.92)
            kit.keep(f"Signature{name}" + ("Ready" if ready else ""), t,
                     use=f"{name}'s icon on the readout, " + ("ready: dark on the light" if ready else "charging"))


def readout(st, x, y, s, share, signature):
    """The readout, stacked from its layers as the engine stacks them."""
    if share >= 1.0:
        st.lay("ReadoutReady", x, y)
        return st.lay(f"Signature{signature}Ready", x, y)
    st.lay("ReadoutPlate", x, y)
    w = s - 2 * WELL
    shape = kit.IMAGES["ReadoutLight"]["px"]
    rows, cols = shape.shape[:2]
    py, px = (np.mgrid[0:rows, 0:cols] + 0.5) / K4
    under = py - w * (1 - share) + (px - w / 2) * LEAN  # points below the front's line, as the gradient measures them
    at = [k[0] for k in FRONT]
    light = np.zeros((rows, cols, 4), np.float32)
    for i in range(3):
        light[..., i] = np.interp(under, at, [c(k[2])[i] for k in FRONT])
    light[..., 3] = np.interp(under, at, [k[1] for k in FRONT]) * shape[..., 3]
    rs.paste(st.px, light, round((x + WELL) * K4), round((y + WELL) * K4))
    st.lay("ReadoutFace", x, y)
    st.lay(f"Signature{signature}", x, y)


def eye_parts():
    """The spectate eye, the readout's small sibling, an image a state: open and lit when on, shut and dim when off."""
    s, g = EYE, EYE_PAD
    for on in (False, True):
        t = kit.blank(s + 2 * g, s + 2 * g)
        outer = plate(t, g, s, s * 0.2)
        if on:
            t.glow(outer, 5.0, c(IVORY), 0.45)
        t.glow(outer, 4.0, ui.BLACK, 0.35)
        t.paint(outer, t.ramp(GRAPHITE["button"][0], GRAPHITE["button"][1], (t.y - g) / s) * (1.0 if on else 0.8), 0.96)
        t.line(outer, 1.0, c(GRAPHITE["edge"]))
        if on:
            t.line(outer + 0.6, 1.4, c(IVORY))
            t.paint(np.maximum(outer + 0.8, g + s - 2.6 - t.y), c(IVORY))
            eye_open(t, g + s / 2, g + s / 2, s * 0.32, IVORY, INK)
        else:
            eye_shut(t, g + s / 2, g + s / 2, s * 0.32, GRAPHITE["soft"])
        kit.keep("EyeOn" if on else "EyeOff", t, pad=g, use="the spectate eye, " + ("on" if on else "off"))


def spectate(st, x, y, s, on):
    st.lay("EyeOn" if on else "EyeOff", x, y)


# --- the lead's card and the target's, from their images --------------------------------------------------------------

DATA, IMG = None, None


def card_images():
    global DATA, IMG
    DATA = json.loads((CARD / "lead_card.json").read_text(encoding="utf-8"))
    IMG = {n: rs.load(CARD / e["file"]) for n, e in DATA["images"].items()}
    card_parts()


STUD, STUD_PAD = 8.5, 12.0  # the type's stud on the lead's card: its radius, and how far its images reach past it


def card_parts():
    """What Conduit adds to the lead's card. A frame's own glow, burned harder: a halo an image for each rarity that
    glows, white, for the engine to tint. And the type's stud where the bars meet the frame: bigger, its rim and its
    glow in the type's own colour."""
    for rarity, r in ui.RARITIES.items():
        if "glow" in r:
            en = DATA["images"][f"CardFrame{rarity}"]
            kit.IMAGES[f"CardFrameHalo{rarity}"] = dict(
                px=halo(IMG[f"CardFrame{rarity}"][..., 3], "#FFFFFF", 5.0, 1.3), w=en["points"][0], h=en["points"][1],
                tint="the rarity's glow, " + r["glow"][0], cut=None, pad=en["pad"],
                use=f"under CardFrame{rarity}, at its place and size", ship=True)
    size = 2 * STUD + 2 * STUD_PAD
    t = kit.blank(size, size)
    t.glow(np.hypot(t.x - size / 2, t.y - size / 2) - STUD, 3.5, c("#FFFFFF"), 0.55)
    kit.keep("CardStudGlow", t, "the type's colour", pad=STUD_PAD, use="under CardStud")
    t = kit.blank(size, size)
    d = np.hypot(t.x - size / 2, t.y - size / 2) - STUD
    t.paint(d, c("#000000"))
    t.line(d, 1.6, c("#FFFFFF"))
    kit.keep("CardStud", t, "the type's colour", pad=STUD_PAD,
             use="the type's stud, where the bars meet the frame, the type's gem on it at 14.6 points; its dark stays dark")


def lead(st, x, y, sc):
    """The lead's card as B has it. Its colours are its rarity's and its type's, so no level changes it."""
    e = DATA["images"]

    def at(name, px=None):
        en = e[name]
        rs.paste(st.px, IMG[name] if px is None else px, round((x + en["at"][0] - en["pad"]) * K4),
                 round((y + en["at"][1] - en["pad"]) * K4))

    rarity, who = sc["rarity"], sc["who"]
    trim, glow = TRIM[rarity], ui.RARITIES[rarity].get("glow")
    fx, fy, fw, fh = lc.FRAME
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
    if glow:  # the frame's own glow, burned harder
        at(f"CardFrame{rarity}", lc.tinted(kit.IMAGES[f"CardFrameHalo{rarity}"]["px"], glow[0]))
    at(f"CardFrame{rarity}")
    if f"CardHead{who}" in e:
        at(f"CardHead{who}")
    at("CardBadge")
    at("CardBadgeRim", lc.tinted(IMG["CardBadgeRim"], trim))
    # the type's stud, where the bars meet the frame: bigger, its rim and its glow in the type's own colour
    type_colour = ss.TYPES[sc["type_"]]
    r = STUD
    cx, cy = x + fx + fw + 0.5, y + DATA["geometry"]["mid"]
    st.lay("CardStudGlow", cx - r, cy - r, tint=type_colour)
    st.lay("CardStud", cx - r, cy - r, tint=type_colour)
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


BACKDROPS = {}  # each street drawn once, kept in 8 bits


def backdrop(kind):
    if kind not in BACKDROPS:
        BACKDROPS[kind] = bytes8(street(kind))
    return floats(BACKDROPS[kind])


def street(kind):
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


def phone(st, controls=True):
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
    if controls:  # a full screen hides the thumbstick and the jump button
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


def screen(sc, level):
    """The HUD as the game lays it out today: the dock's two buttons that exist. The dock of four is on the parts' sheet."""
    st = kit.Stage.__new__(kit.Stage)  # its ground is the street, not a fill
    st.w, st.h, st.items = W, H, []
    st.px = backdrop(sc["kind"])
    l, tp, r, b = SAFE
    phone(st)
    target(st, (l + r) / 2 - 108, tp + TOP + 18, 0.56)
    lead(st, l + PAD, tp + TOP, sc)
    card_foot = tp + TOP + 89
    readout(st, l + PAD + 2, card_foot + 10, 58.0, sc["share"], sc["signature"])
    spectate(st, l + PAD + 2 + 58 + 10, card_foot + 10 + 7, 44.0, sc["eye"])
    px = r - PAD
    pill(st, px - 120, tp + TOP, 120, CREDITS, level, "CoinMint", "35,170")
    py = tp + TOP + PILL + GAP
    if sc["covering"]:
        pill(st, px - 200, py, 200, POWER, level, "Bolt", "30 kW", "34 kW used", POWER, 1.0, drain=4 / 34,
             mark=("Battery", 96))
    else:
        pill(st, px - 200, py, 200, POWER, level, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
    mid = (l + r) / 2
    hint(st, mid - 144, b - PAD - 52 - GAP - PILL, 288, "65 shards: into the Breaker", level)
    dock(st, mid - 99, b - PAD - 52, "Voidkin", "Shard", VOIDKIN, level)
    dock(st, mid + 3, b - PAD - 52, "Base", "Plant", POWER, level)
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
    sheet = ui.Sheet(W + 2 * m, 62 + len(SCENES) * (H + cap) + 8, GROUND)
    t = sheet.tile(0, 0, sheet.w, 60)
    t.text(m, 14, 17, f"Grow your Anime: the HUD's colour, {key}: {name}", HEAD)
    t.text(m, 40, 10, note, NOTE)
    for i, ((px, items), sc) in enumerate(zip(shots, SCENES)):
        y = 62 + i * (H + cap)
        add(sheet, px, items, m, y)
        sheet.tile(m, y + H + 8, W, 16).text(0, 0, 10, sc["caption"], NOTE)
    kit.finish(sheet, out / f"vivid_{key}.png")


STRIP_H = 96.0  # the readout at true size, under the screens on the glance strip
PALE_GROUND = "#E9DFC4"  # about the noon street's sand


def readout_strip():
    """The readout at 30 and 70 in 100 and ready, over a dark ground and a pale one, drawn at the kit's 4 pixels a point
    and brought down to 1: how full it is must read at a phone's size. The same at every level."""
    st = kit.Stage(W, STRIP_H, "#241B33")
    st.px[:, round(W / 2 * K4):, :3] = c(PALE_GROUND)
    st.text(8, 4, 10, "The readout at true size, the same in all three: 30 and 70 in 100, then ready.", HEAD)
    for half, x0 in enumerate((14.0, W / 2 + 14)):
        for i, share in enumerate((0.3, 0.7, 1.0)):
            readout(st, x0 + i * 72, 26, 58.0, share, "Haymaker")
    return bytes8(rs.shrink(st.px, 1 / K4)), st.items


def glance_sheet(out, shots, strip):
    """The three side by side at 1 pixel a point: about a phone's size on a monitor."""
    ui.K = 1
    m, head = 16.0, 30.0
    rows = len(SCENES)
    sheet = ui.Sheet(3 * W + 4 * m, head + rows * (H + m) + STRIP_H + m, GROUND)
    for j, (key, name, _, _) in enumerate(DIRECTIONS):
        x = m + j * (W + m)
        sheet.tile(x, 0, W, head).text(0, 10, 14, f"{key}: {name}", HEAD)
        for i, (px, items) in enumerate(shots[key]):
            add(sheet, halve(floats(px)), items, x, head + i * (H + m))
    add(sheet, *strip, m, head + rows * (H + m))
    kit.finish(sheet, out / "vivid_glance.png")


DEUTERANOPIA = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413],
                         [-0.011820, 0.042940, 0.968881]], np.float32)  # Machado, Oliveira and Fernandes 2009, severity 1


def deuteranopia_sheet(out):
    """The glance again as deuteranopia sees it, for AR12's check: the accents must still part, and they part by icon."""
    px = rs.load(out / "vivid_glance.png")
    rgb = px[..., :3]
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    lin = np.clip(lin @ DEUTERANOPIA.T, 0, 1)
    px[..., :3] = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)
    rs.save(px, out / "vivid_glance_deuteranopia.png")


PARTS_K = 3  # the parts sheet's pixels a point: each row is drawn at the kit's 4, then brought down
PARTS_W, PARTS_ROW = 860.0, 104.0
PARTS_GROUND = "#1C1A26"


def parts_rows():
    """The parts up close, drawn at the kit's 4 pixels a point and kept at 3: the readout and the eye once, since no
    level changes them, then a row a level with the dock of four as it will be, the pills and the hint."""
    rows = []
    st = kit.Stage(PARTS_W, PARTS_ROW, PARTS_GROUND)
    st.px[:, round(PARTS_W / 2 * K4):, :3] = c(PALE_GROUND)
    st.text(12, 6, 11, "The readout and the eye, ivory in all three: 30, 70, ready; off, on.", HEAD)
    st.text(PARTS_W / 2 + 12, 6, 11, "On a pale ground: Held Note at 55 and ready; Haymaker at 30 and 70; the eye on.", INK)
    for i, share in enumerate((0.3, 0.7, 1.0)):
        readout(st, 14 + i * 70, 30, 58.0, share, "Haymaker")
    spectate(st, 240, 37, 44.0, False)
    spectate(st, 296, 37, 44.0, True)
    readout(st, PARTS_W / 2 + 20, 30, 58.0, 0.55, "HeldNote")
    readout(st, PARTS_W / 2 + 90, 30, 58.0, 1.0, "HeldNote")
    readout(st, PARTS_W / 2 + 180, 30, 58.0, 0.3, "Haymaker")
    readout(st, PARTS_W / 2 + 250, 30, 58.0, 0.7, "Haymaker")
    spectate(st, PARTS_W / 2 + 330, 37, 44.0, True)
    rows.append((bytes8(rs.shrink(st.px, PARTS_K / K4)), st.items))
    for key, name, level, _ in DIRECTIONS:
        st = kit.Stage(PARTS_W, PARTS_ROW, PARTS_GROUND)
        st.text(12, 6, 11, f"{key}: {name}", HEAD)
        for i, (label, icon, accent) in enumerate((("Voidkin", "Shard", VOIDKIN), ("Regalia", "Crest", REGALIA),
                                                   ("Base", "Plant", POWER), ("Map", "Route", MAP))):
            dock(st, 14 + i * 102, 30, label, icon, accent, level)
        pill(st, 432, 26, 200, POWER, level, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
        pill(st, 640, 26, 200, POWER, level, "Bolt", "30 kW", "34 kW used", POWER, 1.0, drain=4 / 34, mark=("Battery", 96))
        pill(st, 432, 62, 120, CREDITS, level, "CoinMint", "35,170")
        hint(st, 560, 62, 288, "65 shards: into the Breaker", level)
        rows.append((bytes8(rs.shrink(st.px, PARTS_K / K4)), st.items))
    return rows


def parts_sheet(out, rows):
    ui.K = PARTS_K
    sheet = ui.Sheet(PARTS_W, 24 + len(rows) * PARTS_ROW, PARTS_GROUND)
    sheet.tile(0, 0, PARTS_W, 24).text(12, 8, 12, "The parts up close. The dock as it will be, four buttons, each in its "
                                       "screen's colour; the Power pill at rest and covering; Credits; the hint.", NOTE)
    for j, (px, items) in enumerate(rows):
        add(sheet, px, items, 0, 24 + j * PARTS_ROW)
    kit.finish(sheet, out / "vivid_parts.png")


# --- the screens' side: a room's colour ------------------------------------------------------------------------------

PEARL = kit.PALETTES["Pearl Light"]


def toward(accent, t):
    """Graphite leaning to a system's colour: the body stays near neutral, so a rarity's own colour still reads true on
    it; the rim, the glint and the lights are the system's."""
    top, foot = NIGHT[accent]
    return dict(GRAPHITE, panel=(mix(GRAPHITE["panel"][0], top, t), mix(GRAPHITE["panel"][1], foot, t)),
                button=(mix(GRAPHITE["button"][0], top, t), mix(GRAPHITE["button"][1], foot, t)),
                edge=mix(GRAPHITE["edge"], accent, 0.5), facet=mix(GRAPHITE["facet"], accent, 0.6),
                glint=mix(GRAPHITE["glint"], accent, 0.7), soft=mix(GRAPHITE["soft"], accent, 0.25), accent=accent)


# A room is a palette row, as kit.PALETTES holds them. The four above the line on the sheet are the kit's, as they are.
ROOMS = {
    "Graphite, Voidkin": toward(VOIDKIN, 0.6),
    "Pearl, the Map": dict(PEARL, accent=MAP),
    "Dynamo, vivid": dict(kit.PALETTES["Dynamo"], panel=("#3E2E0E", "#1A1306"), edge="#9A7A22", facet="#D9B85A",
                          glint="#FFE9A0", soft="#C9B787", faint="#8F7F52", button=("#57421A", "#33260F"),
                          pressed=("#241A08", "#3E2E0E"), ground="#3A311C"),
    "Void Violet, vivid": dict(kit.PALETTES["Void Violet"], panel=("#30226A", "#150D33"), edge="#7A5FE0",
                               facet="#B49CFF", glint="#E6DCFF", soft="#BDB0E6", faint="#8577B8",
                               button=("#47348F", "#2B1F5C"), pressed=("#1F1547", "#30226A"), ground="#2F2752"),
    "Graphite, Regalia": toward(REGALIA, 0.6),
    "Tide": dict(kit.PALETTES["Dynamo"], panel=("#0E3B3C", "#061A1D"), edge="#1E8F86", facet="#5FD9CC", glint="#C8FFF6",
                 soft="#9CC9C3", faint="#5F8F8A", channel="#04090A", well="#07100F", button=("#165052", "#0D3133"),
                 pressed=("#082527", "#0E3B3C"), ground="#1F3537", accent=CREDITS),
}
ROOM_USE = {
    "Graphite, Voidkin": "Voidkin, one Voidkin: lavender, the dock button's colour",
    "Pearl, the Map": "the map, and what's read like a page: Pearl, its lights in the Map's rose",
    "Dynamo, vivid": "the Breaker, the base's bays: a richer amber iron, Power's yellow",
    "Void Violet, vivid": "the reveal, later the Void Shop: a deeper, more saturated violet",
    "Graphite, Regalia": "Regalia: indigo, the dock button's colour",
    "Tide": "new: where Credits are earned and spent (rewards, a shop's counter): Credits' teal",
}
TODAY = (("Graphite Dark", "Legendary"), ("Pearl Light", "Epic"), ("Dynamo", "Rare"), ("Void Violet", "Mythical"))
VIVID = (("Graphite, Voidkin", "Legendary"), ("Pearl, the Map", "Epic"), ("Dynamo, vivid", "Rare"),
         ("Void Violet, vivid", "Mythical"))
MORE = (("Graphite, Regalia", "Epic"), ("Tide", "Legendary"))


def main_button(st, x, y, w, h, label, p, pressed=False):
    """A screen's one main action: the button filled with the room's colour, its label in ink. The kit's own slices."""
    accent = p["accent"]
    y += 1.0 if pressed else 0.0
    top, foot = mix(accent, PALE[accent], 0.3), mix(accent, DEEP[accent], 0.4)
    if not pressed:
        st.lay("ButtonShadow", x, y, w, h)
        st.lay("ButtonRingGlow", x, y, w, h, tint=accent, alpha=0.5)
    st.lay("ButtonFill", x, y, w, h, tint=(foot, top) if pressed else (top, foot))
    st.lay("ButtonEdgeBold", x, y, w, h, tint=INK if p.get("border", 1.0) > 1.0 else DEEP[accent])
    if pressed:
        st.lay("ButtonPressedShade", x, y, w, h)
    st.lay("ButtonBase", x, y, w, h, tint=PALE[accent])
    st.text(x + w / 2, y + (h - 14 * ui.CAP) / 2, 14, label, INK, "CENTER")


def room(p, face, rarity, filled):
    """kit.demo's corner of a screen; with `filled`, its main action is the filled button, at rest and pressed."""
    st = kit.Stage(*kit.BLOCK, "#23262D")
    st.px[: round(40 * K4), :, :3] = c("#3B3350")  # a strip of dusk behind the pills
    kit.pill(st, 8, 6, 100, p, "Coin", "12,480")
    kit.pill(st, 114, 6, 162, p, "Bolt", "8,240 / 9,000", "+12/s", 0.9)
    kit.panel(st, 8, 46, 268, 212, p)
    st.text(20, 58, 14, "Bay 2", p["text"])
    st.text(264, 58, 14, "Lv 12", p["soft"], "RIGHT")
    kit.frame(st, 20, 92, rarity, p, face)
    st.icon("GemStrength", 118, 89, BOX * 6.0 / 12.0)
    st.icon("ClassWarrior", 133, 89, BOX * 5.5 / 13.0)
    st.icon("ElementFire", 148, 89, BOX * 6.0 / 12.0)
    st.text(160, 84, 14, "Rook", p["text"])
    for i, (fill, word) in enumerate(((1.0, "full"), (0.22, "low"), (0.0, "empty"))):
        kit.bar(st, 112, 108 + i * 20, 152, 10.0, fill, p)
        st.text(264, 120 + i * 20, 8, word, p["faint"], "RIGHT")
    kit.bar(st, 112, 170, 152, 4.0, 0.6, p, "#C9B8FF")
    if filled:
        main_button(st, 20, 204, 118, 44, "Break", p)
    else:
        kit.button(st, 20, 204, 118, 44, "Break", p)
    kit.button(st, 146, 204, 118, 44, "Voidkin", p, "selected")
    kit.panel(st, 8, 268, 268, 136, p)
    for i, (state, label) in enumerate((("pressed", "Break"), ("disabled", "Break"), ("waiting", ""))):
        if filled and state == "pressed":
            main_button(st, 18, 278, 78, 44, label, p, pressed=True)
        else:
            kit.button(st, 18 + i * 84, 278, 78, 44, label, p, state, "Needs 200" if state == "disabled" else None)
    kit.button(st, 18, 340, 120, 44, "Done", p, "succeeded")
    kit.button(st, 146, 340, 120, 44, "Break", p, "failed", "No free chamber")
    return bytes8(rs.shrink(st.px, kit.SK / K4)), st.items


def rooms_sheet(out, name, title, note, rows):
    """Rows of rooms at 2 pixels a point; `rows` is (a row's heading, its (room's name, its words, its picture))."""
    ui.K = kit.SK
    bw, bh = kit.BLOCK
    gap, head = 16.0, 34.0
    cols = max(len(blocks) for _, blocks in rows)
    pitch = head + bh + 42
    width = gap + cols * (bw + gap)
    lines = textwrap.wrap(note, int(width / 5.2))
    first = 48 + 14 * len(lines)
    sheet = ui.Sheet(width, first + len(rows) * pitch, "#33363E")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 17, title, HEAD)
    for k, line in enumerate(lines):
        t.text(gap, 38 + 14 * k, 10, line, NOTE)
    for j, (heading, blocks) in enumerate(rows):
        y = first + j * pitch
        t.text(gap, y + 2, 12, heading, HEAD)
        for i, (label, words, (px, items)) in enumerate(blocks):
            x = gap + i * (bw + gap)
            t.text(x, y + 20, 11, label, HEAD)
            add(sheet, px, items, x, y + head)
            for k, line in enumerate(textwrap.wrap(words, 64)[:2]):
                t.text(x, y + head + bh + 6 + k * 11, 8, line, NOTE)
    kit.finish(sheet, out / name)


# --- one Voidkin, full screen (the director, 2026-11-15) -----------------------------------------------------------------
# The whole screen is the Voidkin's room. The gear's slots stand in two columns round the figure, Combat Power between
# them at its feet; each Voidkin's menu is a column on the left; the Voidkin to choose from scroll along the foot.
# The gear is the account's, and each Voidkin's screen shows its own set: the preset it's linked to, the twelve shared
# slots and its class's weapon pair (docs/design.md, "Presets"; research, 2026-11-15).

def _poly(t, cx, cy, r, pts):
    return t.poly([(cx + r * u, cy + r * v) for u, v in pts])


def _ring(t, cx, cy, radius, width):
    return np.abs(np.hypot(t.x - cx, t.y - cy) - radius) - width / 2


GEAR = {  # a slot's own mark, plain shapes: stand-ins until the gear has its icons
    "Helmet": lambda t, x, y, r: np.minimum(np.maximum(np.hypot(t.x - x, t.y - y - 0.1 * r) - 0.82 * r, t.y - y - 0.2 * r),
                                            _poly(t, x, y, r, ((-0.98, 0.2), (0.98, 0.2), (0.98, 0.5), (-0.98, 0.5)))),
    "Shoulders": lambda t, x, y, r: _poly(t, x, y, r, ((-1, 0.5), (-0.6, -0.5), (0, -0.15), (0.6, -0.5), (1, 0.5),
                                                       (0.55, 0.2), (0, 0.5), (-0.55, 0.2))),
    "Chest Armor": lambda t, x, y, r: _poly(t, x, y, r, ((-0.85, -0.8), (-0.35, -0.8), (0, -0.45), (0.35, -0.8), (0.85, -0.8),
                                                         (0.7, 0.9), (-0.7, 0.9))),
    "Gloves": lambda t, x, y, r: _poly(t, x, y, r, ((-0.5, -0.9), (0.45, -0.9), (0.45, -0.1), (0.85, -0.3), (0.95, 0.1),
                                                    (0.45, 0.45), (0.4, 0.95), (-0.5, 0.95))),
    "Bracers": lambda t, x, y, r: np.maximum(_poly(t, x, y, r, ((-0.62, -0.9), (0.62, -0.9), (0.42, 0.9), (-0.42, 0.9))),
                                             0.09 * r - np.minimum(np.abs(t.y - y + 0.4 * r), np.abs(t.y - y - 0.35 * r))),
    "Boots": lambda t, x, y, r: _poly(t, x, y, r, ((-0.5, -0.95), (0.15, -0.95), (0.15, 0.2), (0.9, 0.45), (0.9, 0.9),
                                                   (-0.5, 0.9))),
    "Cloak": lambda t, x, y, r: _poly(t, x, y, r, ((-0.3, -0.95), (0.3, -0.95), (0.9, 0.7), (0.45, 0.95), (0, 0.7),
                                                   (-0.45, 0.95), (-0.9, 0.7))),
    "Main Hand": lambda t, x, y, r: np.minimum(seg(t, (x - 0.75 * r, y + 0.75 * r), (x + 0.78 * r, y - 0.78 * r), 0.3 * r),
                                               seg(t, (x - 0.62 * r, y - 0.02 * r), (x + 0.02 * r, y + 0.62 * r), 0.22 * r)),
    "Off Hand": lambda t, x, y, r: _poly(t, x, y, r, ((-0.8, -0.85), (0.8, -0.85), (0.8, 0.1), (0, 0.95), (-0.8, 0.1))),
    "Amulet": lambda t, x, y, r: np.minimum.reduce([seg(t, (x - 0.7 * r, y - 0.9 * r), (x, y + 0.05 * r), 0.15 * r),
                                                    seg(t, (x + 0.7 * r, y - 0.9 * r), (x, y + 0.05 * r), 0.15 * r),
                                                    g_diamond(t, x, y + 0.42 * r, 0.4 * r, 0.52 * r)]),
    "Ring": lambda t, x, y, r: np.minimum(_ring(t, x, y + 0.22 * r, 0.56 * r, 0.26 * r),
                                          g_diamond(t, x, y - 0.56 * r, 0.32 * r, 0.36 * r)),
    "Earring": lambda t, x, y, r: np.minimum(_ring(t, x, y - 0.62 * r, 0.24 * r, 0.16 * r),
                                             g_diamond(t, x, y + 0.3 * r, 0.36 * r, 0.62 * r)),
}
ITEM = {"Uncommon": "#7CF0A0", "Rare": "#6FB6FF", "Epic": "#D29CFF", "Legendary": "#FFD777",
        "Mythical": "#FF2848"}  # an item's rarity, its rim
HIGH = {"Legendary": "#FFF3C4", "Mythical": "#FF8794"}  # the tiers whose frame steps, and their light
CROWN = {  # the crown on a high frame's top edge, in points from the edge's middle: Legendary's whole, Mythical's broken
    "Legendary": (((-8.0, 0.8), (-8.0, -3.4), (-4.4, -1.2), (0.0, -6.2), (4.4, -1.2), (8.0, -3.4), (8.0, 0.8)),),
    "Mythical": (((-8.6, 0.8), (-8.6, -4.4), (-5.6, -1.4), (-2.8, -5.8), (-1.2, 0.8)),
                 ((1.9, 0.8), (3.3, -3.4), (5.5, -1.0), (8.6, -5.0), (8.6, 0.8))),
}
# The fourteen (docs/design.md, "Regalia"): the slot, what's in it for the sheet, its forge rank. The twelve shared
# slots stand a column of six each side of the figure; the class's weapon pair sits at its feet, either side of Combat
# Power (the director, 2026-11-15).
SLOTS = ((("Helmet", "Legendary", 3), ("Shoulders", "Uncommon", 1), ("Chest Armor", "Mythical", 4), ("Gloves", None, 0),
          ("Bracers", "Uncommon", 0), ("Boots", "Rare", 2)),
         (("Cloak", "Epic", 2), ("Amulet", "Epic", 1), ("Ring I", "Uncommon", 0), ("Ring II", None, 0),
          ("Earring I", "Rare", 1), ("Earring II", None, 0)))
WEAPONS = (("Main Hand", "Legendary", 5), ("Off Hand", "Rare", 2))


def high_frame(st, x, y, s, rarity):
    """From Legendary a gear frame steps (docs/research/gear-icons.md, "The frame steps at Legendary"): its two cuts
    become lit facets, a second rim of light runs inside, and a small crown rises from its top edge, the crown a
    Legendary portrait wears. Mythical keeps the form, its crown broken and its light red."""
    rim, light, o = ITEM[rarity], HIGH[rarity], 9.0
    t = kit.blank(s + 2 * o, s + 2 * o)
    outer = t.poly(cut_box(o, o, o + s, o + s, 8.0, 0.0, 8.0, 0.0))
    t.line(t.poly(cut_box(o + 3.6, o + 3.6, o + s - 3.6, o + s - 3.6, 6.0, 0.0, 6.0, 0.0)), 0.9, c(light), 0.9)
    for a, b in (((o, o + 8.0), (o + 8.0, o)), ((o + s, o + s - 8.0), (o + s - 8.0, o + s))):
        facet = np.maximum(seg(t, a, b, 5.6), outer - 0.9)
        t.glow(facet, 2.4, c(rim), 0.6)
        t.paint(facet, c(light))
        t.paint(np.maximum(seg(t, a, b, 2.0), outer - 0.9), c("#FFFFFF"))
    mid = o + s / 2 + 4.0  # the top edge's middle: the edge starts past the cut
    crown = np.minimum.reduce([t.poly([(mid + u, o + v) for u, v in part]) for part in CROWN[rarity]])
    t.glow(crown, 2.6, c(rim), 0.55)
    t.paint(crown - 1.1, c(STROKE))
    t.paint(crown, t.ramp(light, rim, (t.y - o + 6.0) / 6.0))
    place(st, t, x - o, y - o)


def slot(st, x, y, s, p, name, rarity, rank):
    """One gear slot: the kit's button cut, small. Rarity in layers (docs/research/gear-icons.md, DESIGN): the rim, an
    inner light that's brighter behind the object, then the object, which fills most of the square; the forge rank sits
    at the frame's corner. Empty, the slot's mark is faint. The marks are plain stand-ins until the gear has its art."""
    st.lay("ButtonShadow", x, y, s, s)
    st.lay("ButtonFill", x, y, s, s, tint=(p["well"], p["channel"]))
    if rarity:  # the inner light, kept inside the slot's own cut
        def light(rows, cols):
            v = np.hypot((np.arange(cols)[None, :] / cols - 0.5) * 1.15, np.arange(rows)[:, None] / rows - 0.46)
            return (np.clip(1 - v / 0.62, 0, 1) ** 1.3 * 0.62 + 0.14).astype(np.float32)
        st.lay("ButtonFill", x, y, s, s, tint=(mix(ITEM[rarity], "#FFFFFF", 0.2), ITEM[rarity]), window=light)
    st.lay("ButtonEdge" + ("Bold" if rarity else ""), x, y, s, s, tint=ITEM[rarity] if rarity else p["edge"],
           alpha=1.0 if rarity else 0.7)
    if rarity in HIGH:
        high_frame(st, x, y, s, rarity)
    t = kit.blank(s, s)
    d = GEAR[name.split(" I")[0]](t, s / 2, s / 2 - 0.02 * s, s * 0.33)
    if rarity:
        t.glow(d, 2.2, ui.BLACK, 0.55)
        t.paint(d, t.ramp("#FFFFFF", mix(IVORY, ITEM[rarity], 0.5), (t.y / s - 0.15) / 0.7))
    else:
        t.paint(d, c(p["faint"]), 0.45)
    if rank:  # the forge rank, a badge on the frame's square corner, never over the object's middle
        t.paint(t.poly(cut_box(1.6, s - 14.6, 21.0, s - 1.6, 0.0, 3.5, 0.0, 0.0)), c(STROKE), 0.88)
    place(st, t, x, y)
    if rank:
        st.text(x + 3.8, y + s - 13.2, 11, f"+{rank}", "#FFFFFF")


def stand_in(st, cx, foot, height):
    """A plain figure where the Voidkin's live model stands, when its render isn't to hand."""
    u = height / 10.0
    t = kit.blank(8 * u, height)
    parts = [cut_box(4 * u - w, y0 * u, 4 * u + w, y1 * u, 0.3 * u, 0, 0.3 * u, 0) for w, y0, y1 in
             ((1.1 * u, 0.0, 2.1), (1.7 * u, 2.3, 6.0), (1.5 * u, 6.2, 10.0))]
    parts += [cut_box(4 * u + s * 2.0 * u - 0.55 * u, 2.4 * u, 4 * u + s * 2.0 * u + 0.55 * u, 6.2 * u) for s in (-1.3, 1.3)]
    d = np.minimum.reduce([t.poly(pts) for pts in parts])
    t.paint(d, t.ramp("#B9AEDB", "#6F6592", t.y / height))
    place(st, t, cx - 4 * u, foot - height)


def mark_button(st, x, y, s, p, draw):
    """Favourite, lock, rename: small, beside the name."""
    kit.button(st, x, y, s, s, "", p)
    t = kit.blank(s, s)
    t.paint(draw(t, s / 2, s / 2 - 1, s * 0.24), c(p["text"]))
    place(st, t, x, y)


MARKS = (
    lambda t, x, y, r: _poly(t, x, y, r, [(math.sin(a) * k, -math.cos(a) * k) for a, k in
                                         ((math.radians(36 * i), 1.15 if i % 2 == 0 else 0.5) for i in range(10))]),
    lambda t, x, y, r: np.minimum(_poly(t, x, y, r, ((-0.85, -0.1), (0.85, -0.1), (0.85, 1.0), (-0.85, 1.0))),
                                  np.maximum(_ring(t, x, y - 0.25 * r, 0.52 * r, 0.26 * r), t.y - y + 0.1 * r)),
    lambda t, x, y, r: np.minimum(seg(t, (x - 0.45 * r, y + 0.45 * r), (x + 0.75 * r, y - 0.75 * r), 0.46 * r),
                                  _poly(t, x, y, r, ((-1.0, 1.0), (-0.86, 0.36), (-0.36, 0.86)))),
)
TABS = ("Overview", "Stats", "Kit", "Stars")


def _star(t, x, y, r):
    return _poly(t, x, y, r, [(math.sin(a) * k, -math.cos(a) * k) for a, k in
                              ((math.radians(36 * i), 1.0 if i % 2 == 0 else 0.44) for i in range(10))])


MENU = {  # a page's own mark on its round button, plain shapes
    "Overview": lambda t, x, y, r: np.minimum(
        np.hypot(t.x - x, t.y - y + 0.5 * r) - 0.44 * r,
        np.maximum(np.hypot(t.x - x, t.y - y - 1.05 * r) - 0.95 * r, t.y - y - 0.95 * r)),
    "Stats": lambda t, x, y, r: np.minimum.reduce([
        _poly(t, x, y, r, ((u - 0.22, 0.9), (u - 0.22, top), (u + 0.22, top), (u + 0.22, 0.9)))
        for u, top in ((-0.64, 0.2), (0.0, -0.3), (0.64, -0.9))]),
    "Kit": lambda t, x, y, r: _poly(t, x, y, r, [(math.sin(a) * k, -math.cos(a) * k) for a, k in
                                                 ((math.radians(45 * i), 1.12 if i % 2 == 0 else 0.3) for i in range(8))]),
    "Stars": lambda t, x, y, r: np.minimum(_star(t, x - 0.2 * r, y + 0.18 * r, 0.86 * r),
                                           _star(t, x + 0.72 * r, y - 0.7 * r, 0.4 * r)),
}
RAIL_REST, RAIL_ON = 13.0, 21.0  # a round button's radius: about 7% and 12% of the screen's height across (research)
RAIL_WORD = 16.0  # the room the chosen page's word takes under its button: the pages after it stand that much lower


def rail(st, x, y0, y1, p, tabs, chosen, soon=()):
    """The Voidkin's menu (the director, 2026-11-15; docs/research/voidkin-screen.md, "The rail, ours"): a thin conduit
    line down the left, a round button strung on it for each page. At rest a button is a small cut ring round its mark.
    Chosen, it's larger, its ring lit in the room's colour, and light runs along the line to it. A page in `soon`
    isn't built yet: its mark is greyed."""
    accent, g, span = p["accent"], 22.0, y1 - y0
    step = (span - 2 * RAIL_REST - 24.0 - RAIL_WORD) / (len(tabs) - 1)
    ys = [y0 + RAIL_REST + 6.0 + i * step + (RAIL_WORD if i > chosen else 0.0) for i in range(len(tabs))]
    t = kit.blank(2 * g, span + 2 * g)
    line = np.maximum(np.abs(t.x - g) - 0.8, np.abs(t.y - g - span / 2) - span / 2)
    word = ys[chosen] - y0 + g + RAIL_ON + 9.5  # the line stops for the chosen page's word
    line = np.maximum(line, 8.5 - np.abs(t.y - word))
    t.paint(line - 1.3, c(STROKE), 0.85)
    t.paint(line, c(p["edge"]), 0.8)
    near = np.clip(1 - np.abs(t.y - g - (ys[chosen] - y0)) / 62.0, 0, 1)
    ui.over(t.px, c(accent), np.clip(0.5 - (line - 2.4) * K4, 0, 1) * near * 0.35)
    ui.over(t.px, c(PALE[accent]), np.clip(0.5 - line * K4, 0, 1) * near)
    for i, py in enumerate((g, g + span)):  # the line's ends
        d = g_diamond(t, g, py, 3.4, 4.4)
        t.paint(d - 1.2, c(STROKE))
        t.paint(d, c(p["edge"]))
    place(st, t, x - g, y0 - g)
    for i, (tab, y) in enumerate(zip(tabs, ys)):
        on = i == chosen
        rad = RAIL_ON if on else RAIL_REST
        m = rad + 16.0
        t = kit.blank(2 * m, 2 * m)
        d = np.hypot(t.x - m, t.y - m) - rad
        v = (t.y - m + rad) / (2 * rad)
        cuts = 1.5 - np.abs((t.x - m) - (t.y - m)) / math.sqrt(2)  # the kit's two cut corners, as gaps in the ring
        if on:
            t.glow(d, 8.0, c(accent), 0.62)
        t.glow(d, 3.0, ui.BLACK, 0.45)
        t.paint(d - 1.6, c(STROKE))
        t.paint(d, t.ramp(mix(p["button"][0], accent, 0.16 if on else 0.0), p["button"][1], v))
        if on:  # the ring lit: the room's colour, white-hot along its middle, a fine ring inside
            ring = np.abs(d + 1.7) - 1.7
            t.paint(ring, t.ramp(PALE[accent], accent, v))
            t.line(d + 1.7, 0.9, c("#FFFFFF"), 0.85)
            t.line(d + 5.4, 0.8, c(accent), 0.5)
        else:  # a small cut ring in the room's edge, a glint on its head
            ring = np.maximum(np.abs(d + 1.0) - 0.85, cuts)
            t.paint(ring, c(p["edge"]))
            t.paint(np.maximum(ring, t.y - m + rad * 0.5), c(p["glint"]), 0.75)
        t.paint(MENU[tab](t, m, m + 0.5, rad * 0.5), c(PALE[accent] if on else p["text"]),
                1.0 if on else 0.34 if tab in soon else 0.85)
        place(st, t, x - m, y - m)
        if on:  # the one word on the rail, at a size that reads on a phone: a page at rest is known by its mark
            st.text(x, y + rad + 4.0, 11, tab, PALE[accent], "CENTER")
STRIP = ("Legendary", "Mythical", "Epic", "Rare", "Epic", "Uncommon", "Rare", "Common", "Uncommon", "Common", "Rare",
         "Common", "Uncommon", "Common", "Common")  # the strip's frames, the shown Voidkin first


def voidkin_screen(p, figure=None, faces=()):
    """One Voidkin, full screen, at a phone's size in landscape. `figure`: the Voidkin's render; `faces`: portraits for
    the strip. The Voidkin's rarity lights its stage and its floor takes its element, as TR17's stage does."""
    st = kit.Stage(W, H, "#000000")
    accent = p["accent"]
    top, foot = NIGHT[accent]
    st.px[..., :3] = kit.shade((mix(top, accent, 0.1), mix(NIGHT[REGALIA][1], "#000000", 0.15)), st.px.shape[0])
    l, r = SAFE[0] + PAD, SAFE[2] - PAD
    rarity, element = "#FFD777", ui.ELEMENTS["Fire"]
    cx, floor, tall = 315.0, 264.0, 232.0
    # the stage: the rarity's light behind the figure, the element's on the floor
    t = kit.blank(420, 300)
    t.glow(np.hypot((t.x - 210) * 0.8, t.y - 140) - 60, 50.0, c(rarity), 0.5)
    t.glow(np.hypot((t.x - 210) * 0.9, t.y - 150) - 30, 26.0, c(mix(rarity, "#FFFFFF", 0.4)), 0.3)
    t.glow(np.hypot((t.x - 210) / 4.6, t.y - 268) - 9, 9.0, c(element), 0.6)
    t.paint(np.hypot((t.x - 210) / 5.2, t.y - 268) - 7.5, c(mix(element, "#FFFFFF", 0.35)), 0.5)
    place(st, t, cx - 210, floor - 268 + 2)
    if figure is None:
        stand_in(st, cx, floor + 2, tall - 8.0)
    else:
        fig = rs.shrink(figure, tall * K4 / figure.shape[0])
        rs.paste(st.px, fig, round(cx * K4 - fig.shape[1] / 2), round((floor + 4) * K4) - fig.shape[0])
    # the gear: the twelve shared slots, a column of six each side of the figure
    s, pitch, y0 = 40.0, 41.0, 56.0
    for column, x in zip(SLOTS, (118.0, 472.0)):
        for i, (name, item, rank) in enumerate(column):
            slot(st, x, y0 + i * pitch, s, p, name, item, rank)
    # Combat Power, at its feet: a plate in the rarity's light that fades at both ends
    t = kit.blank(204, 34)
    band = np.clip(1 - np.abs(t.x - 102) / 100, 0, 1) ** 1.2
    ui.over(t.px, c("#000000"), band * 0.55)
    ui.over(t.px, c(rarity), band * np.clip(1 - np.abs(t.y - 33) / 1.6, 0, 1) * 0.9)
    ui.over(t.px, c(rarity), band * np.clip(1 - np.abs(t.y - 1) / 1.2, 0, 1) * 0.45)
    em = g_diamond(t, 40, 17, 9.5, 11.5)
    t.paint(em, c(STROKE))
    t.line(em, 1.6, c(rarity))
    t.paint(g_diamond(t, 40, 17, 4.2, 5.2), c(rarity))
    place(st, t, cx - 102, 268)
    st.text(cx - 46, 271, 8, "COMBAT POWER", mix(rarity, IVORY, 0.4))
    st.text(cx - 47, 280, 20, "27,433", IVORY)
    # the class's weapon pair, larger, at the figure's feet either side of Combat Power
    for (name, item, rank), x in zip(WEAPONS, (166.0, 418.0)):
        slot(st, x, 257.0, 46.0, p, name, item, rank)
    # the name, its marks and its level on one line, right of Roblox's bar and over the figure's head; the close
    st.text(226, 14, 18, "Rook", p["text"])
    for i, mark in enumerate(("GemStrength", "ClassWarrior", "ElementFire")):
        st.icon(mark, 283 + i * 17, 25.0, 14.0)
    st.text(336, 20, 10, "Lv 12", p["soft"])
    st.text(226, 36, 10, "Legendary", rarity)
    # the preset this Voidkin is linked to, in Regalia's colour: the gear is Regalia's
    gear = palette(REGALIA, DEEPER)
    st.lay("PanelShadow", 440, 16, 104, 28)
    st.lay("PanelFill", 440, 16, 104, 28, tint=gear["panel"], alpha=gear["alpha"])
    st.lay("PanelEdgeBold", 440, 16, 104, 28, tint=gear["edge"])
    st.lay("PanelGlint", 440, 16, 104, 28, tint=gear["glint"])
    st.icon("Crest", 456, 30, 19.0)
    st.text(470, 16 + (28 - 12 * ui.CAP) / 2, 12, "Preset 1", gear["text"])
    for i, draw in enumerate(MARKS):
        mark_button(st, 566 + i * 38, 14, 32.0, p, draw)
    kit.button(st, r - 62, 14, 62, 32, "Close", p)
    # the menu, this Voidkin's own: a line down the left, a round button for each page
    rail(st, l + 22.0, 58.0, 300.0, p, TABS, TABS.index("Stats"))
    # the chosen menu's panel
    px, pw = 526.0, r - 526.0
    kit.panel(st, px, 56, pw, 248, p)
    st.text(px + 12, 66, 13, "Stats", p["text"])
    # each stat in a colour of its own: health's red and the heal's green as the fight has them, a plain hit's ivory
    # for attack, steel for defence; the thread shows the Voidkin's own share, the rest is its gear's
    for i, (name, value, own, share, colour) in enumerate((
            ("Health", "1,847", "Own 1,543, gear 304", 1543 / 1847, "#EE4E3A"), ("Attack", "295", "Own 241, gear 54", 241 / 295, IVORY),
            ("Defence", "212", "Own 180, gear 32", 180 / 212, "#9FB4D9"), ("Regen", "14", "Own 14", 1.0, "#6FE695"))):
        y = 90 + i * 38
        t = kit.blank(14, 14)
        d = g_diamond(t, 7, 7, 4.6, 5.8)
        t.paint(d - 1.2, c(STROKE))
        t.paint(d, c(colour))
        place(st, t, px + 9, y - 1)
        st.text(px + 26, y, 13, name, p["text"])
        st.text(px + pw - 12, y, 13, value, mix(colour, IVORY, 0.35), "RIGHT")
        st.text(px + 26, y + 17, 9, own, p["soft"])
        kit.bar(st, px + 12, y + 30, pw - 24, 3.0, share, p, colour)
    main_button(st, px + 10, 254, (pw - 26) / 2, 40, "Lead", p)
    kit.button(st, px + 16 + (pw - 26) / 2, 254, (pw - 26) / 2, 40, "Send to work", p)
    # the Voidkin to choose from, scrolling along the foot
    kit.panel(st, l - 2, 308, r - l + 4, 58, p)
    for i, frame_rarity in enumerate(STRIP):
        x = l + 2 + i * 46.0
        if x + 40 > r:
            break
        face = faces[i] if i < len(faces) else None
        kit.IMAGES.pop("_FaceFrame" + frame_rarity + "Small", None)  # cut_face keeps one face a frame: let it go
        kit.frame(st, x, 312 - (2 if i == 0 else 0), frame_rarity, p, face, small=True)
        if i == 0:  # the one shown: lifted, a light under it
            st.lay("ButtonBase", x, 314, 40, 48, tint=accent)
    kit.bar(st, l + 2, 363, r - l - 4, 3.0, 0.0, p)
    thumb = kit.blank(150, 3)
    thumb.paint(thumb.poly(cut_box(0, 0, 150, 3)), c(accent), 0.9)
    place(st, thumb, l + 2, 363)
    phone(st, controls=False)
    return bytes8(halve(st.px)), st.items


def figure_render():
    """Rook's model, whole, three-quarter on, as ui.portrait takes his face."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Figure")
    with bpy.data.libraries.load(str(ui.ROOK / "rook_model.blend")) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
        if o.type == "MESH":
            scene.collection.objects.link(o)
    ui.rm.eevee(scene, 900, 1080)
    ui.rm.sun_for(scene, 158)
    path = bl.out_dir() / "_figure.png"
    shot = rs.trim(rs.shoot(scene, path, 158, 6, (0, 0, 2.7), 6.4))
    path.unlink()
    return shot


def voidkin_sheet(out, shot):
    ui.K = 2
    m = 20.0
    notes = (
        "The director, 2026-11-15: the Voidkin's screen is the full screen, its gear round the figure, the Voidkin to "
        "choose from scrolling along the foot. Then: the gear's slots a bit bigger; the menu much smaller, a line with "
        "round buttons on it; the two weapon slots at the figure's feet, either side of Combat Power.",
        "The rail: a thin line, a small cut ring for each page (26 points across), the chosen one larger (42) with its "
        "ring lit in the room's colour and light on the line beside it. The filled button stays the screen's one main action.",
        "The gear: twelve slots at 40 points in two columns of six, the weapon pair at 46. Rarity in layers: the rim, an "
        "inner light behind the object, the object large. From Legendary the frame steps: lit facets on its cuts, a second "
        "rim of light inside, a small crown on its top edge; Mythical's crown is broken and its light red.",
        "Stand-ins: the gear's marks (plain shapes until the gear has its modelled art), the numbers, the strip's empty "
        "frames, Blender's face for the text; Rook is shown as a Legendary for the light.",
        "Colours with a meaning: a slot's rim is its item's rarity; the preset is Regalia's indigo; health's red, "
        "attack's ivory, defence's steel, the heal's green; the stage in the rarity's gold over the element's orange.",
    )
    notes = [line for note in notes for line in textwrap.wrap(note, 150)]
    sheet = ui.Sheet(W + 2 * m, 44 + H + 14 + len(notes) * 15 + 12 + H / 2 + 30, GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(m, 14, 17, "Grow your Anime: one Voidkin, full screen, in its room's colour", HEAD)
    add(sheet, *shot, m, 44)
    y = 44 + H + 14
    for i, line in enumerate(notes):
        t.text(m, y + i * 15, 10, line, NOTE)
    y += len(notes) * 15 + 12
    t.text(m, y, 10, "At a phone's size, 1 pixel a point:", NOTE)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    small = rs.shrink(sheet.px[44 * 2:round((44 + H) * 2), round(m * 2):round((m + W) * 2)].copy(), 0.5)
    kit.put(sheet, small, m * 2, (y + 16) * 2)
    rs.save(sheet.px, out / "vivid_voidkin.png")


def ui_main(out, rooms=True):
    """The screens' side. Today's four palettes, then the same screens in their rooms' colours, then the two new rooms.
    `rooms` off draws the Voidkin's sheet alone."""
    figure = figure_render()
    stage("Rook's figure")
    ui.K = K4
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.frames()
    kit.icons()
    icons()
    images = REPO / "build" / "handoff" / "UI" / "hud" / "images"
    faces = [rs.load(images / f"Portrait{who}.png")[244:584, 198:538].copy() for who in ("Rook", "Lyric", "Pip")]
    face = faces[0]
    stage("the kit's slices")
    shot = voidkin_screen(ROOMS["Graphite, Voidkin"], figure, faces)
    del figure
    stage("one Voidkin, full screen")
    if not rooms:
        kit.IMAGES.clear()
        return voidkin_sheet(out, shot)
    today = [(n, kit.SCREENS[n], room(kit.PALETTES[n], face, rarity, False)) for n, rarity in TODAY]
    vivid = [(n, ROOM_USE[n], room(ROOMS[n], face, rarity, True)) for n, rarity in VIVID]
    more = [(n, ROOM_USE[n], room(ROOMS[n], face, rarity, True)) for n, rarity in MORE]
    kit.IMAGES.clear()
    stage("the rooms, the slices let go")
    voidkin_sheet(out, shot)
    del shot
    stage("the Voidkin's sheet")
    rule = ("A room's colour is its system's: the button that opens a screen and the screen wear the same colour. "
            "Each screen's one main action is a filled button in that colour. Frames, gems, marks, green and red: unchanged.")
    rooms_sheet(out, "vivid_ui.png", "Grow your Anime: the screens' colour, today and vivid", rule,
                (("Today: the kit's four palettes, as they are", today), ("Vivid: the same four, each in its room's colour", vivid)))
    stage("the screens' sheet")
    rooms_sheet(out, "vivid_ui_more.png", "Grow your Anime: the screens' colour, the two rooms more", rule,
                (("Vivid: two rooms the kit doesn't have yet", more),))
    stage("the two rooms more")


# --- the HUD's images in Block, for the build ------------------------------------------------------------------------

SYSTEMS = {  # what the HUD colours: its colour, its icon in light, its mark in ink for a block
    "Power": (POWER, "Bolt", "InkBolt"), "Base": (POWER, "Plant", "InkPlant"), "Credits": (CREDITS, "CoinMint", "InkCoin"),
    "Voidkin": (VOIDKIN, "Shard", "InkShard"), "Regalia": (REGALIA, "Crest", "InkCrest"), "Map": (MAP, "Route", "InkRoute"),
}
PIECES = dict(
    pill=dict(
        height=PILL, layers=["PanelShadow", "PanelFill: palette.panel, palette.alpha", "BlockPill: block, top to foot",
                             "PanelEdgeBold: palette.edge", "PanelGlint: palette.glint"],
        mark="the system's ink mark, 20 points, its middle 16.5 from the left, at mid height",
        words="from 41, palette.text; a second value right-aligned 10 from the right, palette.soft",
        bar="Power's: a thread 3 tall, 8 above the foot, from 41 to 9 short of the right, its light the system's colour; "
            "the words sit 2 higher. Its fill is demand over generation",
        covering="when the battery covers demand: the second value in the system's colour, the Battery icon at 17 points "
                 "102 from the left, and the bar's last share (covered over demand) in dashes, 2 on 2 off, palette.channel"),
    hint=dict(like="pill, in the colours and with the mark of the system it points to",
              words="centred 10 right of the middle, palette.text"),
    dock=dict(size=[96.0, 52.0], layers=["ButtonShadow", "ButtonFill: palette.button", "BlockDock: block, top to foot",
                                         "ButtonEdgeBold: palette.edge", "ButtonBase: colour",
                                         "ButtonBaseGlow: colour, 45 in 100"],
              mark="the system's ink mark, 23 points, its middle at 17.5, 24.5", words="from 40, palette.text"),
    readout=dict(
        size=READOUT, well=[WELL, WELL, READOUT - WELL, READOUT - WELL],
        charging=["ReadoutPlate", "ReadoutLight at the well's box, under one gradient: the light and its front",
                  "ReadoutFace", "Signature<Name>"],
        light="one gradient on ReadoutLight carries the light's colour and how solid it is. Its line's middle sits at "
              "well top + (1 - share) x well height, on the well's middle column; nothing shows above the front, and "
              "the last stop holds down to the foot. Moving the gradient moves the level. A box clip isn't used: it "
              "lets the light out past the two cut corners",
        front=[dict(below=at, solid=solid, colour=colour) for at, solid, colour in FRONT],
        lean=f"the front's line rises {LEAN:g} of a point for each point to the right (about 6.8 degrees)",
        ready=["ReadoutReady", "Signature<Name>Ready"],
        place="under the lead's card: 10 under its foot, 2 right of its left"),
    eye=dict(size=EYE, images=["EyeOff", "EyeOn"], place="beside the readout: 10 right of it, 7 lower than its top"),
    card=dict(halo="CardFrameHalo<Rarity> under CardFrame<Rarity>, at its place, tinted its rarity's glow; "
                   "Common and Uncommon have none",
              stud="CardStudGlow then CardStud, tinted the type's colour, its middle 0.5 right of the frame's right edge "
                   "at lead_card.json's geometry.mid; then the type's gem at 14.6 points"),
    main=dict(what="a screen's one main action, filled with its room's colour",
              layers=["ButtonShadow", "ButtonRingGlow: colour, 50 in 100", "ButtonFill: main, top to foot",
                      "ButtonEdgeBold: deep (the palette's ink on a bordered palette)", "ButtonBase: pale"],
              words="in ink #14161B", pressed="1 lower, no shadow or glow, main foot to top, ButtonPressedShade over the edge"),
)
SHEET_ICONS = ("Bolt", "CoinMint", "Shard", "Plant", "Crest", "Route", "Battery")


def colour_manifest(out, names):
    def row(p):
        return {k: (list(v) if isinstance(v, tuple) else v) for k, v in p.items()}

    def system(accent, lit, ink):
        p = palette(accent, BLOCK)
        return dict(colour=accent, pale=PALE[accent], deep=DEEP[accent], night=list(NIGHT[accent]), icon=lit, mark=ink,
                    block=list(block_tint(accent)), main=[mix(accent, PALE[accent], 0.3), mix(accent, DEEP[accent], 0.4)],
                    palette=row({k: p[k] for k in ("panel", "alpha", "button", "pressed", "edge", "border", "glint",
                                                   "channel", "text", "soft")}))

    data = dict(
        pixelsPerPoint=K4, strength="V2, Block (research's verdict on AR12's delivery 2, 2026-11-15)",
        note="The HUD's colour, on the kit's slices (build/handoff/UI/kit/kit.json) and the lead's card "
             "(build/handoff/UI/hud/lead_card/lead_card.json). A piece wears its system's row: `palette` colours the "
             "kit's slices, `block` tints the piece's block top to foot, `mark` is the ink icon on the block. A white "
             "image takes its tint; a dark part baked into one stays dark. `pad` is how far an image reaches past its "
             "piece's box on every side. Indigo and rose never go on a portrait's or an item's frame.",
        systems={name: system(*v) for name, v in SYSTEMS.items()}, pieces=PIECES,
        rooms={name: row(p) for name, p in ROOMS.items()}, roomUse=ROOM_USE,
        images={name: dict(file=f"images/{name}.png", pixels=[im["px"].shape[1], im["px"].shape[0]], points=[im["w"], im["h"]],
                           **({"tint": im["tint"]} if im["tint"] else {}), **({"pad": im["pad"]} if im["pad"] else {}),
                           **({"use": im["use"]} if im["use"] else {}))
                for name, im in ((n, kit.IMAGES[n]) for n in names)})
    (out / "hud_colour.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print(f"wrote {out / 'hud_colour.json'}: {len(data['images'])} images")


def images_shot():
    """The delivered images on one picture: each icon at the image's own size and at 64 pixels, then the pieces stacked
    from them as the engine stacks them."""
    st = kit.Stage(880.0, 648.0, PARTS_GROUND)
    st.text(12, 8, 11, "The icons: above, 64 points across (on this sheet, the image's own 128 pixels); below, at 64 pixels. "
            "A mark in ink is shown on its system's block colours.", HEAD)
    inks = {ink: accent for accent, _, ink in SYSTEMS.values()}
    for i, name in enumerate(SHEET_ICONS + tuple(inks)):
        cx = 12 + 33 + i * 66
        for cy, size in ((68, 64.0), (126, 32.0)):
            if name in inks:
                x0, x1 = round((cx - size / 2 - 1) * K4), round((cx + size / 2 + 1) * K4)
                y0, y1 = round((cy - size / 2 - 1) * K4), round((cy + size / 2 + 1) * K4)
                st.px[y0:y1, x0:x1, :3] = kit.shade(block_tint(inks[name]), y1 - y0)
            st.icon(name, cx, cy, size)
        st.text(cx, 147, 9, name, NOTE, "CENTER")
    st.text(12, 168, 11, "Block, stacked from the images: the pills, the hint, the dock of four. Right: the two blocks "
            "as delivered, white, and in each system's colours.", HEAD)
    pill(st, 12, 190, 120, CREDITS, BLOCK, "CoinMint", "35,170")
    pill(st, 140, 190, 200, POWER, BLOCK, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
    pill(st, 348, 190, 200, POWER, BLOCK, "Bolt", "30 kW", "34 kW used", POWER, 1.0, drain=4 / 34, mark=("Battery", 96))
    hint(st, 556, 190, 288, "65 shards: into the Breaker", BLOCK)
    for i, (label, icon, accent) in enumerate((("Voidkin", "Shard", VOIDKIN), ("Regalia", "Crest", REGALIA),
                                               ("Base", "Plant", POWER), ("Map", "Route", MAP))):
        dock(st, 12 + i * 102, 232, label, icon, accent, BLOCK)
    for i, accent in enumerate((None, POWER, CREDITS, VOIDKIN, REGALIA, MAP)):
        st.lay("BlockPill", 440 + i * 46, 232, tint=block_tint(accent) if accent else None)
        st.lay("BlockDock", 440 + i * 46, 266, tint=block_tint(accent) if accent else None)
    st.text(12, 330, 11, "The readout's layers (plate, the light's shape, face, ready, the icons), then stacked: Haymaker at "
            "30, 70 and ready, Held Note at 55 and ready; the eye off and on.", HEAD)
    for i, name in enumerate(("ReadoutPlate", "ReadoutLight", "ReadoutFace", "ReadoutReady")):
        st.lay(name, 20 + i * 76 + (WELL if name == "ReadoutLight" else 0), 360 + (WELL if name == "ReadoutLight" else 0))
    for i, name in enumerate(("SignatureHaymaker", "SignatureHaymakerReady", "SignatureHeldNote", "SignatureHeldNoteReady")):
        if name.endswith("Ready"):
            st.px[round(364 * K4):round(414 * K4), round((324 + i * 62) * K4):round((374 + i * 62) * K4), :3] = c(IVORY)
        st.lay(name, 320 + i * 62, 360)
    st.px[round(432 * K4):round(520 * K4), round(476 * K4):, :3] = c(PALE_GROUND)
    for x0 in (20, 488):
        for i, (share, signature) in enumerate(((0.3, "Haymaker"), (0.7, "Haymaker"), (1.0, "Haymaker"), (0.55, "HeldNote"),
                                                (1.0, "HeldNote"))):
            readout(st, x0 + i * 66, 446, READOUT, share, signature)
        if x0 == 20:
            spectate(st, x0 + 338, 453, EYE, False)
        spectate(st, x0 + (336 if x0 > 20 else 392), 453, EYE, True)
    st.text(12, 530, 11, "The lead's card with its frame's halo and its type's stud: a Common, which has no halo, and a "
            "Mythical. Right: the Rare, Epic and Legendary frames on their halos.", HEAD)
    lead(st, 12, 548, SCENES[0])
    lead(st, 300, 548, SCENES[1])
    for i, rarity in enumerate(("Rare", "Epic", "Legendary")):
        en = DATA["images"][f"CardFrame{rarity}"]
        at = round((590 + i * 96 - en["pad"]) * K4), round((556 - en["pad"]) * K4)
        rs.paste(st.px, lc.tinted(kit.IMAGES[f"CardFrameHalo{rarity}"]["px"], ui.RARITIES[rarity]["glow"][0]), *at)
        rs.paste(st.px, IMG[f"CardFrame{rarity}"], *at)
    return bytes8(halve(st.px)), st.items


def images_main(out):
    """The HUD's images in Block, for the build: images/, hud_colour.json and a sheet of them, in the handoff folder."""
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    theirs = set(kit.IMAGES)
    icons()
    card_images()
    names = [n for n in kit.IMAGES if n not in theirs and not n.startswith("_")]
    stage("the kit's slices, the card's images, ours")
    (out / "images").mkdir(exist_ok=True)
    for name in names:
        px = kit.IMAGES[name]["px"].copy()
        kit.bleed(px)
        rs.save(px, out / "images" / f"{name}.png")
    colour_manifest(out, names)
    shot = images_shot()
    kit.IMAGES.clear()
    IMG.clear()
    stage("the images saved, the sheet's picture drawn")
    ui.K = 2
    m = 20.0
    sheet = ui.Sheet(880 + 2 * m, 44 + 648 + 16, GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(m, 14, 17, "Grow your Anime: the HUD's images in Block, as delivered", HEAD)
    add(sheet, *shot, m, 44)
    kit.finish(sheet, out / "hud_colour_images.png")
    stage("the images' sheet")


def main():
    out = bl.out_dir()
    mode = (sys.argv[sys.argv.index("--") + 2:] or ["hud"])[0]
    ui.K = K4
    stage("started")
    if mode in ("ui", "voidkin"):
        return ui_main(out, mode == "ui")
    if mode == "images":
        return images_main(out)
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    icons()
    card_images()
    stage("the kit's slices and the card's images")
    # Every picture is composed first and kept in 8 bits; the text comes after, since its render brings up the GPU.
    shots = {}
    for key, name, level, note in DIRECTIONS:
        shots[key] = []
        for sc in SCENES:
            shots[key].append(screen(sc, level))
            stage(f"{key}, {sc['kind']}")
    rows = parts_rows()
    strip = readout_strip()
    BACKDROPS.clear()
    kit.IMAGES.clear()
    IMG.clear()
    stage("the parts' rows and the strip, the slices let go")
    parts_sheet(out, rows)
    del rows
    stage("the parts' sheet")
    for key, name, level, note in DIRECTIONS:
        direction_sheet(out, key, name, note, shots[key])
        stage(f"sheet {key}")
    glance_sheet(out, shots, strip)
    stage("the glance")
    deuteranopia_sheet(out)


if __name__ == "__main__":
    main()
