"""The lead's card, as kit images (TR3, the director's eye, 2026-11-13). The director's picks from the mocks: the card in
Midnight, a lacquered black gradient with a navy undertone ("something mature so gradiant black"); the Ember bars, lit
at the top, deep at the foot; both bars a little thinner; the empty part of each a little see-through ("a bit
transparent not by much"). The rim takes the lead's rarity's colour (TR3's verdict, fix 3), so it's drawn white and
tinted. The portrait is the card's biggest thing, the head standing over the frame's top rim.

Drawn by the builder at the director's ask, in Modulo's toolkit (ui_sheet.py) and from its portrait renders
(hud_art.py); Modulo may re-cut any face (AR3, section 3). The lead's card is take F since 2026-11-15 (AR12, "The
director's pick"). Its layers, bottom to top, as src/client/UI/LeadCard.luau lays them, in the card's own points (its top
left at the HUD's PAD, TOP):

  CardPlate, CardPlateRim  the plate beside the portrait: the name's row, the two slots, the ink; its rim white, tinted
  CardLeadHealth           the ruby, one solid bar, wine at its root to hot at its front, sliced across, anchored at its front
  CardLeadXp               the lavender thread at the plate's foot, sliced across
  CardFace<Who>            the face cut to its rarity's inner rim line, on Midnight's well, its foot faded
  CardFrame<Rarity>        the portrait's frame at the card's size: its rim and shadow, no glow round it, the opening clear
  CardHead<Who>            the head over the frame's top, its foot ended hard, an ink line round it above the frame
  CardStud(Glow)           Modulo's (hud/colour): the type's stud at the health bar's root, tinted the type, its gem on it
  LevelPlate(Edge)         Modulo's (voidkin/marks): the level's mark, under the frame's lowest point, with its chevrons

The target's card and the keeper's HUD are still built from take E's images, drawn here too: CardHousing(Rim), the two
blades; CardLightHealth/Xp, a bar's light; CardTab(Rim), the name's tab; CardBadge(Rim); CardTargetHousing(Rim), one blade.

    blender -b --factory-startup --python tools/blender/lead_card_art.py -- <abs path>/build/handoff/UI/hud/lead_card make
    blender -b --factory-startup --python tools/blender/lead_card_art.py -- <abs path>/build/handoff/UI/hud/lead_card sheet

Give Blender an absolute path: it resolves a relative one from the drive's root. `make` cuts the faces from the uncut
renders cached in RENDERS (out of git; hud_art shoots any that's missing), writes images/*.png and lead_card.json
(tools/ui/kit_config.py reads it).
`sheet` composes whole cards for review: every Voidkin at every rarity over night and noon sand at card size, each at 3x,
two at 2x, and the target's card.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_art  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

K = ui.K = 4
c = ui.c
WHITE, BLACK = ui.WHITE, ui.BLACK

# The card's points. The frame, the head over it; the housing in two blades on one slant, the name on a tab above.
W, H = 232.0, 96.0
M = 30.0  # the drawing's margin past the card on every side, for glows and crests
FRAME = (2.0, 20.0, 58.0, 62.0)
RISE = 14.0  # the head's top over the frame's top edge
X0, Y0, X1 = 40.0, 34.0, 210.0
INSET, GAP, HEALTH_H, XP_H = 3.4, 2.4, 17.0, 6.5
STEP = 30.0  # the lower blade ends short of the upper
SLANT = 0.45  # across per down, every slanted edge
TAB_TOP, TAB_REF = 18.0, 80.0  # the tab's top; its width as drawn (sliced to fit the name in the game)
HEALTH_Y0 = Y0 + INSET
XP_Y0 = HEALTH_Y0 + HEALTH_H + GAP
Y1 = XP_Y0 + XP_H + INSET
MID = HEALTH_Y0 + HEALTH_H + GAP / 2
TAB_FOOT = Y0 + 2.4  # the tab reaches into the housing this far, over its rim and the ink inside it
GLOW = 4.0  # a light's glow ahead of its front
FILL_FROM = FRAME[0] + FRAME[2] + 1.0  # a bar's empty point, along its top edge: the frame's right side; left of it, under the frame
RIM = 1.1
BADGE = (14.0, 80.0, 26.0, 16.0)  # centre, size

MIDNIGHT = dict(body=("#2A3456", "#05070D"), tab=("#38446E", "#121830"), glint="#CFDBFF",
                slot=("#010205", "#0A0E1C"), well=("#202846", "#04050A"), ink="#000000")
SLOT_ALPHA = 0.8  # "a bit transparent, not by much"
EMBER = dict(hp=((0.0, "#FFB27A"), (0.22, "#FF7E52"), (0.5, "#EE4E3A"), (0.56, "#DC3F33"), (1.0, "#9E2620")), hp_sheen="#FFE3B8",
             xp=((0.0, "#CDEBFF"), (0.22, "#7FC2FF"), (0.5, "#4E9BFF"), (0.56, "#3D86EE"), (1.0, "#1F4FA8")), xp_sheen="#E9F7FF")
RARITIES = ("Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical")
# zoom, lift (points). The Voidkin with no portrait yet keeps its head inside the frame: over the rim, its plain block
# read as a box stuck on the card.
FRAMING = {"Rook": (1.12, 0.0), "Lyric": (1.0, 3.0), "Pip": (0.9, 1.0), "Unknown": (1.0, RISE + 4.0)}
TRIM = {"Common": "#666C78", "Uncommon": "#7CF0A0", "Rare": "#6FB6FF", "Epic": "#D29CFF", "Legendary": "#FFD777",
        "Mythical": "#FF8794"}  # Config.Hud.Card.Trim, for the review sheet only: the game tints the white rims


def stops(t, v, pairs):
    v = np.clip(v, 0, 1)
    xs = [p for p, _ in pairs]
    cols = np.stack([c(code) for _, code in pairs])
    return np.stack([np.interp(v, xs, cols[:, i]) for i in range(3)], axis=-1).astype(np.float32)


def left(y):
    return X0 + (Y1 - y) * SLANT


def blade(ya, yb, end):
    right = lambda y: end - (y - Y0) * SLANT  # noqa: E731
    return [(left(ya), ya), (right(ya), ya), (right(yb), yb), (left(yb), yb)]


def cover(d):
    return np.clip(0.5 - d * K, 0, 1)


def outside(d):
    return np.clip(0.5 + d * K, 0, 1)


class Layer:
    """A transparent drawing over the card and its margin, measured in the card's own points."""

    def __init__(self):
        self.sheet = ui.Sheet(W + 2 * M, H + 2 * M, "#000000")
        self.sheet.px[:] = 0
        self.t = self.sheet.tile(0, 0, W + 2 * M, H + 2 * M)
        self.t.x -= M
        self.t.y -= M

    def image(self, rgba, x, y, d=None):
        self.t.image(rgba, x + M, y + M, d)

    def crop(self, x0, y0, x1, y1):
        return self.t.px[round((y0 + M) * K):round((y1 + M) * K), round((x0 + M) * K):round((x1 + M) * K)].copy()


def shadow(t, d, radius, strength, pad=None):
    """A soft shadow round a shape. Given its image's pad, it is gone before the image's edge: cut short there, it
    showed in the game as a faint box."""
    ui.over(t.px, BLACK, strength * np.exp(-(np.maximum(d, 0) / radius) ** 1.4) * outside(d) * fade(d, pad))


def fade(d, pad):
    """1 near a shape, to 0 at 0.9 of the pad (a slanted edge comes that close to the image's square edge), over the
    outer half of that reach only, so the shadow near the shape stays as it was."""
    if pad is None:
        return 1.0
    reach = 0.9 * pad
    v = np.clip((reach - np.maximum(d, 0)) / (reach / 2), 0, 1)
    return v * v * (3 - 2 * v)


def across(px, left_cap, right_cap):
    """A slice across only: its caps left and right, and top and bottom caps that meet but for one middle row of points.
    Roblox drew a slice whose middle ran the image's whole height from its top rows alone (the lights and the tab, in
    the first take): the middle must stop short of the top and the bottom."""
    half = (px.shape[0] / K - 0.5) / 2
    return [left_cap, half, right_cap, half]


def lacquer(t, region, top, pal):
    """Midnight's light: a soft line under a top edge."""
    ui.over(t.px, c(pal["glint"]), cover(np.maximum(region, np.abs(t.y - (top + 1.9)) - 1.1)) * 0.16)


# --- the housing ----------------------------------------------------------------------------------------------------

def housing_shape(t):
    upper = t.poly(blade(Y0, MID, X1))
    lower = t.poly(blade(MID - 0.5, Y1, X1 - STEP))
    return np.minimum(upper, lower)


def slots(t):
    return (t.poly(blade(HEALTH_Y0, HEALTH_Y0 + HEALTH_H, X1 - INSET * 1.3)),
            t.poly(blade(XP_Y0, XP_Y0 + XP_H, X1 - STEP - INSET * 1.3)))


def body(t, region, pal):
    t.paint(region, stops(t, (t.y - Y0) / (Y1 - Y0), ((0, pal["body"][0]), (1, pal["body"][1]))))


def housing(pal):
    lay = Layer()
    t = lay.t
    house = housing_shape(t)
    hslot, xslot = slots(t)
    either = np.minimum(hslot, xslot)
    pad = 6.0
    shadow(t, house, 4.5, 0.5, pad)
    body(t, np.maximum(house, -either), pal)
    sweep = np.clip(1 - np.abs((t.x + (t.y - Y0) * SLANT) - 145) / 22.0, 0, 1)  # the lacquer's sheen, on the slant
    ui.over(t.px, WHITE, cover(np.maximum(house, -either)) * sweep * 0.12)
    lacquer(t, np.maximum(house, -either), Y0, pal)
    for slot, y0, h in ((hslot, HEALTH_Y0, HEALTH_H), (xslot, XP_Y0, XP_H)):
        ui.over(t.px, stops(t, (t.y - y0) / h, ((0, pal["slot"][0]), (1, pal["slot"][1]))), cover(slot) * SLOT_ALPHA)
        t.paint(np.maximum(slot, np.abs(t.y - (y0 + h) + 0.5) - 0.45), c(pal["glint"]), 0.18)  # the slot's lower lip
    t.line(house - RIM, 0.7, c(pal["ink"]), 0.8)  # dark inside the rim
    t.line(house + RIM, 0.6, BLACK, 0.5)  # (inside the rim's own width: the rim is laid over it)
    top_edges = np.maximum(house + RIM, -(house + RIM + 1.2))
    lit_from_above = np.clip((np.roll(house, 3, axis=0) - house) * 1.5, 0, 1)
    ui.over(t.px, c(pal["glint"]), cover(top_edges) * lit_from_above * 0.7)
    rim = Layer()
    rim.t.line(housing_shape(rim.t), RIM, WHITE)
    box = (X0 - pad, Y0 - pad, X1 + pad, Y1 + pad)
    return lay.crop(*box), rim.crop(*box), pad


# --- the tab --------------------------------------------------------------------------------------------------------

def tab_shape(t, width=TAB_REF):
    x_top = left(TAB_TOP) + width
    return t.poly([(left(TAB_TOP), TAB_TOP), (x_top, TAB_TOP), (x_top - (TAB_FOOT - TAB_TOP) * SLANT, TAB_FOOT),
                   (left(TAB_FOOT), TAB_FOOT)])


def tab(pal):
    lay = Layer()
    t = lay.t
    d = tab_shape(t)
    pad = 5.0
    shadow(t, np.maximum(d, t.y - Y0), 4.0, 0.45, pad)
    above = np.maximum(d, t.y - Y0)
    t.paint(above, stops(t, (t.y - TAB_TOP) / (Y0 - TAB_TOP), ((0, pal["tab"][0]), (1, pal["tab"][1]))))
    lacquer(t, above, TAB_TOP, pal)
    patch = np.maximum(d, Y0 - 0.25 - t.y)  # over the housing's rim: the housing's own body and lacquer again
    body(t, patch, pal)
    lacquer(t, patch, Y0, pal)
    t.line(np.maximum(d, t.y - Y0) - RIM, 0.7, c(pal["ink"]), 0.8)
    edge = np.maximum(d + RIM, -(d + RIM + 1.2))
    lit_from_above = np.clip((np.roll(d, 3, axis=0) - d) * 1.5, 0, 1)
    ui.over(t.px, c(pal["glint"]), cover(np.maximum(edge, t.y - Y0)) * lit_from_above * 0.7)
    rim = Layer()
    r = rim.t
    dr = tab_shape(r)
    # The rim along the left edge to the tab's foot (it meets the housing's own there), the top, the right edge to Y0;
    # never along the foot itself, which lies inside the housing (it showed there as a line under the name).
    near_left = (r.x - left(r.y)) / np.hypot(1.0, SLANT) - (RIM + 0.6)
    keep = np.minimum(r.y - Y0 - 0.55, near_left)
    r.paint(np.maximum(np.abs(dr + RIM / 2) - RIM / 2, keep), WHITE)
    for layer in (lay, rim):  # nothing under the tab's foot: the housing is there (the kit's slice wants a pad all round)
        layer.t.px[..., 3] *= cover(layer.t.y - TAB_FOOT)
    box = (left(TAB_FOOT) - pad, TAB_TOP - pad, left(TAB_TOP) + TAB_REF + pad, TAB_FOOT + pad)
    run = (TAB_FOOT - TAB_TOP) * SLANT
    image = lay.crop(*box)
    return image, rim.crop(*box), pad, across(image, pad + run + 2.0, pad + run + 2.0)


# --- the lights -----------------------------------------------------------------------------------------------------

def light_rows():
    """Each light's top edge: its left end (under the frame), its y, its right end when full (one inset short of its
    slot's end, so the glow ahead stays in the slot), and its height."""
    rows = {}
    for name, y0, h, end in (("Health", HEALTH_Y0, HEALTH_H, X1), ("Xp", XP_Y0, XP_H, X1 - STEP)):
        slot_end = end - INSET * 1.3 - (y0 - Y0) * SLANT
        rows[name] = [left(y0) + INSET * 1.3, y0, slot_end - INSET * 1.3, h]
    return rows


def light(ramp, sheen, h, length=60.0):
    """A light `length` along its top edge, in a slot `h` high, its glow GLOW ahead: sliced across in the game."""
    lay = Layer()
    t = lay.t
    y0, xl = 40.0, 40.0  # anywhere on the drawing: the image is the light's own box
    xe = xl + length
    norm = np.hypot(1.0, SLANT)
    lit = t.poly([(xl, y0), (xe, y0), (xe - h * SLANT, y0 + h), (xl - h * SLANT, y0 + h)])
    cutoff = ((t.x - xe) + (t.y - y0) * SLANT) / norm
    band_y = np.abs(t.y - (y0 + h / 2)) - h / 2  # the slot's height
    ahead = np.clip(1 - np.maximum(cutoff, 0) / GLOW, 0, 1) * (cutoff > 0) * cover(band_y)
    ui.over(t.px, stops(t, np.full_like(t.y, 0.5), ramp), ahead * 0.35)
    t.paint(lit, stops(t, (t.y - y0) / h, ramp))
    t.paint(np.maximum(lit, np.abs(t.y - (y0 + h * 0.22)) - h * 0.07), c(sheen), 0.4)
    t.paint(np.maximum(lit, -cutoff - 1.0), c(sheen), 0.5)
    box = (xl - h * SLANT, y0, xe + GLOW, y0 + h)
    run = h * SLANT
    image = lay.crop(*box)
    return image, across(image, run + 0.5, run + 1.5 + GLOW)


# --- the target's card ---------------------------------------------------------------------------------------------
# Built like the lead's (TR3, point 3; research's pass on the lead card, 2026-11-13): one blade, the health slot only,
# on the lead's slant and in its gradient, so the lead's tab and light sit on it as they sit on the lead's. Drawn in the
# lead's points and moved by T_OFFSET into the target card's own (216 across, centred at the top). Sliced across: the
# game sets its length. No portrait: the type's stud pins the blade's left end, the light starting beside it.

T_W = 216.0
T_Y1 = HEALTH_Y0 + HEALTH_H + INSET  # the blade's foot
T_STUD = (left(HEALTH_Y0 + HEALTH_H / 2), HEALTH_Y0 + HEALTH_H / 2)  # on the blade's left edge, the slot's middle
T_OFFSET = (8.0 - T_STUD[0], -TAB_TOP)  # lead points to target points: the stud 8 in, the tab's top at 0
T_END = T_W - 1.0 - T_OFFSET[0]  # the blade's top right, in the lead's points


def t_slot(t, end):
    """The health slot, an inset in from both slanted ends (the lead's is open at its left, under the frame)."""
    ya, yb = HEALTH_Y0, HEALTH_Y0 + HEALTH_H
    right = lambda y: end - INSET * 1.3 - (y - Y0) * SLANT  # noqa: E731
    return t.poly([(left(ya) + INSET * 1.3, ya), (right(ya), ya), (right(yb), yb), (left(yb) + INSET * 1.3, yb)])


def target_housing(pal):
    lay = Layer()
    t = lay.t
    house = t.poly(blade(Y0, T_Y1, X1))
    slot = t_slot(t, X1)
    pad = 6.0
    shadow(t, house, 4.5, 0.5, pad)
    region = np.maximum(house, -slot)
    body(t, region, pal)  # the lead's gradient, over the lead's height: the tab's patch matches it
    lacquer(t, region, Y0, pal)  # no sheen sweep: the middle is stretched, so it stays the same column to column
    ui.over(t.px, stops(t, (t.y - HEALTH_Y0) / HEALTH_H, ((0, pal["slot"][0]), (1, pal["slot"][1]))), cover(slot) * SLOT_ALPHA)
    t.paint(np.maximum(slot, np.abs(t.y - (HEALTH_Y0 + HEALTH_H) + 0.5) - 0.45), c(pal["glint"]), 0.18)
    t.line(house - RIM, 0.7, c(pal["ink"]), 0.8)
    t.line(house + RIM, 0.6, BLACK, 0.5)
    top_edges = np.maximum(house + RIM, -(house + RIM + 1.2))
    lit_from_above = np.clip((np.roll(house, 3, axis=0) - house) * 1.5, 0, 1)
    ui.over(t.px, c(pal["glint"]), cover(top_edges) * lit_from_above * 0.7)
    rim = Layer()
    rim.t.line(rim.t.poly(blade(Y0, T_Y1, X1)), RIM, WHITE)
    box = (left(T_Y1) - pad, Y0 - pad, X1 + pad, T_Y1 + pad)
    run = (T_Y1 - Y0) * SLANT
    image = lay.crop(*box)
    cap = pad + run + INSET * 1.3 + 2.0  # each cap holds a slanted end and the slot's end inside it
    return image, rim.crop(*box), pad, across(image, cap, cap)


def target_geometry():
    """The target card's shape, in its own points: its size, the lead-points offset, the blade's box (its foot's left,
    its top, its top's right end, its foot), the light's row as light_rows() gives the lead's, and the stud."""
    dx, dy = T_OFFSET
    xl = left(HEALTH_Y0) + INSET * 1.3
    xr = T_END - INSET * 1.3 - (HEALTH_Y0 - Y0) * SLANT - INSET * 1.3
    return dict(size=[T_W, T_Y1 + dy], offset=[dx, dy], housing=[left(T_Y1) + dx, Y0 + dy, T_END + dx, T_Y1 + dy],
                health=[xl + dx, HEALTH_Y0 + dy, xr + dx, HEALTH_H], fillFrom=xl + dx, stud=[T_STUD[0] + dx, T_STUD[1] + dy])


# --- the badge ------------------------------------------------------------------------------------------------------

def badge(pal):
    cx, cy, w, h = BADGE
    lay = Layer()
    t = lay.t
    d = t.poly(ui.cut_box(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, 4.5, 0, 4.5, 0))
    pad = 4.0
    shadow(t, d, 3.0, 0.45, pad)
    t.paint(d, stops(t, (t.y - cy + h / 2) / h, ((0, pal["tab"][0]), (1, pal["body"][1]))))
    lacquer(t, d, cy - h / 2, pal)
    t.line(d - RIM, 0.6, c(pal["ink"]), 0.8)
    rim = Layer()
    rim.t.line(rim.t.poly(ui.cut_box(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, 4.5, 0, 4.5, 0)), 1.3, WHITE)
    box = (cx - w / 2 - pad, cy - h / 2 - pad, cx + w / 2 + pad, cy + h / 2 + pad)
    return lay.crop(*box), rim.crop(*box), pad


# --- the plate: take F (AR12) ---------------------------------------------------------------------------------------
# The director's pick, 2026-11-15: "let try F i dont want segments tho just a bar". Take F's composition (Modulo's
# tools/blender/lead_card_round2.py): one plate beside the portrait in place of the tab and the two blades, its rows on
# one slant, the name's row in the tab's colours; one solid health bar 11 points thick in D's ruby, wine at its root to
# hot at its front; experience a lavender thread at the plate's foot. The type's stud, the frame's halo and the level's
# mark are Modulo's images (AR12's colour, TR17's marks). The housing, tab, lights and badge above stay: the target's
# card and the keeper's HUD are built from them, and Modulo's mocks lay them.

P_LEFT, P_END, P_TOP, P_BOTTOM = 46.0, 176.0, 26.0, 73.5  # the plate: its top line's two ends, its top and its foot
P_NAME = 42.0  # the name's row reaches down to here, in the tab's colours
P_INSET = 4.0  # a slot's ends inside the plate's
P_HEALTH, P_XP = (43.5, 54.5), (68.5, 71.0)  # the slots' tops and feet
P_FULL = P_END - P_INSET - 1.5  # a light's front when full, on the top line
# Each light's empty point at its row's middle: health's at the type's stud's right edge, its root's slant tucked under
# the stud's lower half, so the least share shows (with its root under the stud, the first 5% hid there); experience's
# under the frame's right side, hidden.
P_ROOT = {"Health": 68.0, "Xp": 59.4}
P_STUD = (FRAME[0] + FRAME[2] + 0.5, sum(P_HEALTH) / 2, 8.5)  # centre and radius: Modulo's CardStud, 17 points across
P_HOT = 0.06  # the ruby's last stretch, hot to its front: this share of the full bar, kept that long at any share
VIOLET = dict(body=("#43348A", "#150F30"), tab=("#5545A6", "#211849"), glint="#E6DBFF", slot=("#07051A", "#120C2C"),
              ink="#000000")
RUBY = dict(ramp=((0.0, "#FF9CAE"), (0.22, "#F2466A"), (0.5, "#D4163F"), (0.56, "#BE1238"), (1.0, "#6E0A26")),
            along=((0.0, "#6A0A2C"), (0.5, "#C41440"), (0.9, "#F0284E"), (1.0, "#FF4A68")), sheen="#FFD9E0")
# The ruby's front stays a saturated hot red, the pale only in its 1-point front sheen: at a low share the hot stretch is
# all that shows, and a pale front then read as pink beside Mythical's trim.
LAVENDER = dict(ramp=((0.0, "#FFFFFF"), (0.22, "#EDE3FF"), (0.5, "#C9B2FF"), (0.56, "#B79CF5"), (1.0, "#6A52C4")),
                sheen="#FFFFFF")
LEAD_LIGHTS = {"Health": (P_HEALTH, RUBY), "Xp": (P_XP, LAVENDER)}


def plx(x, y):
    """A point given on the plate's top line, carried down its slant to y."""
    return x - (y - P_TOP) * SLANT


def para(t, x0, x1, y0, y1):
    return t.poly([(plx(x0, y0), y0), (plx(x1, y0), y0), (plx(x1, y1), y1), (plx(x0, y1), y1)])


def plate(pal):
    lay = Layer()
    t = lay.t
    house = para(t, P_LEFT, P_END, P_TOP, P_BOTTOM)
    pad = 6.0
    shadow(t, house, 4.5, 0.5, pad)
    t.paint(house, stops(t, (t.y - P_TOP) / (P_BOTTOM - P_TOP), ((0, pal["body"][0]), (1, pal["body"][1]))))
    t.paint(np.maximum(house, t.y - P_NAME), stops(t, (t.y - P_TOP) / (P_NAME - P_TOP), ((0, pal["tab"][0]), (1, pal["tab"][1]))))
    sweep = ((t.x - (P_END - 44.0)) + (t.y - P_TOP) * SLANT) / np.hypot(1.0, SLANT)  # the lacquer's sheen, on the slant
    ui.over(t.px, WHITE, cover(house) * np.clip(1 - np.abs(sweep) / 16.0, 0, 1) * 0.1)
    t.paint(np.maximum(house, np.abs(t.y - (P_TOP + 1.9)) - 0.55), c(pal["glint"]), 0.3)
    for y0, y1 in (P_HEALTH, P_XP):
        slot = para(t, P_LEFT + P_INSET, P_END - P_INSET, y0, y1)
        ui.over(t.px, stops(t, (t.y - y0) / (y1 - y0), ((0, pal["slot"][0]), (1, pal["slot"][1]))), cover(slot) * 0.85)
        t.paint(np.maximum(slot, np.abs(t.y - y1 + 0.4) - 0.35), c(pal["glint"]), 0.18)  # the slot's lower lip
    t.line(house + RIM, 0.7, c(pal["ink"]), 0.8)  # dark inside the rim
    rim = Layer()
    rim.t.line(para(rim.t, P_LEFT, P_END, P_TOP, P_BOTTOM), RIM, WHITE)
    box = (plx(P_LEFT, P_BOTTOM) - pad, P_TOP - pad, P_END + pad, P_BOTTOM + pad)
    return lay.crop(*box), rim.crop(*box), pad


def lead_row(name):
    """A lead light's top edge: its left end (its root, the empty point), its y, its right end when full; its height."""
    (y0, y1), _ = LEAD_LIGHTS[name]
    root = P_ROOT[name] + ((y0 + y1) / 2 - P_TOP) * SLANT  # on the top line
    return [plx(root, y0), y0, plx(P_FULL, y0), y1 - y0]


def lead_light(name):
    """A lead light drawn full, sliced across in the game: its root's slanted end the left cap, its front, its glow
    ahead and (the ruby) its hot last stretch the right cap, the middle stretching. The ruby runs along it, wine at the
    root to hot at the front; the lavender is lit at its top, deep at its foot, as the target's light."""
    (y0, y1), light = LEAD_LIGHTS[name]
    h = y1 - y0
    xl, _, xr, _ = lead_row(name)
    length = xr - xl
    lay = Layer()
    t = lay.t
    ty, tx = 40.0, 40.0  # anywhere on the drawing: the image is the light's own box
    te = tx + length
    lit = t.poly([(tx, ty), (te, ty), (te - h * SLANT, ty + h), (tx - h * SLANT, ty + h)])
    ahead = ((t.x - te) + (t.y - ty) * SLANT) / np.hypot(1.0, SLANT)
    band_y = np.abs(t.y - (ty + h / 2)) - h / 2
    glow = np.clip(1 - np.maximum(ahead, 0) / GLOW, 0, 1) * (ahead > 0) * cover(band_y)
    ui.over(t.px, stops(t, np.full_like(t.y, 0.5), light["ramp"]), glow * 0.35)
    v = np.clip((t.y - ty) / h, 0, 1)
    along = light.get("along")
    if along:
        col = stops(t, ((t.x - tx) + (t.y - ty) * SLANT) / length, along)
        col = col + (1 - col) * (np.clip(1 - v / 0.35, 0, 1) * 0.3)[..., None]  # lit toward the top
        col = col * (1 - np.clip((v - 0.5) / 0.5, 0, 1) * 0.3)[..., None]  # deep toward the foot
    else:
        col = stops(t, v, light["ramp"])
    t.paint(lit, col)
    t.paint(np.maximum(lit, np.abs(t.y - (ty + h * 0.22)) - max(h * 0.07, 0.3)), c(light["sheen"]), 0.4)
    t.paint(np.maximum(lit, -ahead - 1.0), c(light["sheen"]), 0.5)
    run = h * SLANT
    image = lay.crop(tx - run, ty, te + GLOW, ty + h)
    return image, across(image, run + 0.5, run + 1.5 + GLOW + (P_HOT * length if along else 0.0))


LEVEL_CLEAR = 2.0  # the level's mark stands this far clear of every frame at its widest (research's measure, AR12)
LEVEL_GAP = 1.5  # and this far under the plate's foot, off the experience line
LEVEL_H = 22.0  # TR17's LevelPlate


def rim_right(px):
    """How far right a frame's rim reaches, in the card's points: alpha past its shadow's (0.4 at most), so the Epic and
    Mythical side points count."""
    cols = np.where((px[..., 3] > 0.45).any(axis=0))[0]
    return FRAME[0] - FRAME_PAD + (cols.max() + 1) / K


# --- the portrait ---------------------------------------------------------------------------------------------------

def frame_geometry(t, rarity):
    x0, y0, w, h = FRAME
    r = ui.RARITIES[rarity]
    d = t.poly(ui.outline(x0, y0, x0 + w, y0 + h, r))
    scale = w / 80.0
    width = max(r["stroke"] * max(scale, 0.75) * 1.5, 1.8)
    return r, d, scale, width


FRAME_PAD = 24.0


def frame(rarity):
    lay = Layer()
    t = lay.t
    x0, y0, w, h = FRAME
    r, d, scale, width = frame_geometry(t, rarity)
    # No glow round the frame, its rarity's or Modulo's halo (the director, 2026-11-15: "there is a bit to much light
    # like it shine a bit to far from rare to mythical let remove this light aura"): the rim's colour, its shape and its
    # crests mark the rarity. Its shadow is cast from below its top line only: the crests stand behind the head, and their
    # shadow showed as a smudge above the hair on a pale ground.
    shadow(t, np.maximum(d, y0 - t.y), 5.0, 0.4)
    metal = t.ramp(r["metal"][0], r["metal"][1], (t.y - y0) / h)
    t.line(d, width, metal)
    t.line(d + width, 0.5, BLACK, 0.5)
    t.paint(np.maximum(d, np.abs(d + width * 0.35) - 0.3), WHITE, 0.35)
    if r.get("inner"):
        t.line(d + width + 1.2, 0.7, metal, 0.75)
    if r.get("hot"):
        t.line(d + width * 0.3, 0.8, WHITE, 0.9)
    box = (x0 - FRAME_PAD, y0 - FRAME_PAD, x0 + w + FRAME_PAD, y0 + h + FRAME_PAD)
    return lay.crop(*box)


def placed(face, rarity, who):
    """The face scaled and placed: its head's top RISE over the frame's top, its foot faded where it ends."""
    x0, y0, w, h = FRAME
    zoom, lift = FRAMING[who]
    fw = w * zoom
    img = rs.shrink(face, fw * K / face.shape[1]).copy()
    a = img[..., 3]
    mid = a[:, a.shape[1] * 3 // 10:a.shape[1] * 7 // 10]
    rows_filled = np.nonzero((mid > 0.5).any(axis=1))[0]
    top = rows_filled[0] / K
    fx, fy = x0 + (w - fw) / 2, y0 - RISE - top + lift
    foot = min((y0 + h - fy) - 1.0, (rows_filled[-1] + 1) / K)
    rows = (np.arange(img.shape[0]) + 0.5) / K
    img[..., 3] *= np.clip((foot - rows) / 14.0, 0, 1)[:, None]
    return img, fx, fy


HEAD_TOP = FRAME[1] - RISE - 12.0
HEAD_SIDE = 2.0  # the head's image reaches this far past the frame's sides, for its ink line
INK_LINE, INK_ALPHA = 1.0, 0.85  # the line round the head above the frame (the seam's fix c)


def openings(rarity, width):
    """Where the face stops inside the frame, and where the head over it ends: the seam's fixes (AR12, the director,
    2026-11-15: "there is some issue with the portrait see it merging"). The face is clipped at the rim's inner edge, or
    at the middle of the inner line where the rarity has one (d), and the head ends hard below that line (a)."""
    inner = ui.RARITIES[rarity].get("inner")
    return (width + 1.55 if inner else width + 0.25), FRAME[1] + width + (2.2 if inner else 0.9)


def dilate(alpha, radius):
    """An alpha grown by `radius` points: the most of it within a disc."""
    r = round(radius * K)
    grown = alpha.copy()
    h, w = alpha.shape
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy > r * r or (dx == 0 and dy == 0):
                continue
            src = alpha[max(-dy, 0):h - max(dy, 0), max(-dx, 0):w - max(dx, 0)]
            dst = grown[max(dy, 0):h - max(-dy, 0), max(dx, 0):w - max(-dx, 0)]
            np.maximum(dst, src, out=dst)
    return grown


def face_and_head(face, rarity, who, pal):
    x0, y0, w, h = FRAME
    x1, y1 = x0 + w, y0 + h
    img, fx, fy = placed(face, rarity, who)
    inside = Layer()
    t = inside.t
    r, d, scale, width = frame_geometry(t, rarity)
    clip, foot = openings(rarity, width)
    t.paint(d, stops(t, (t.y - y0) / h, ((0, pal["well"][0]), (1, pal["well"][1]))))
    behind = np.exp(-(((t.x - (x0 + w / 2)) / 20.0) ** 2 + ((t.y - (y0 + h * 0.38)) / 16.0) ** 2))  # light behind the head
    ui.over(t.px, c(pal["tab"][0]), cover(d) * behind * 0.55)
    inside.image(img, fx, fy, d + clip)
    t.paint(np.maximum(d, y1 - h * 0.25 - t.y), BLACK, 0.18)
    # The head over the frame: everything of the portrait above its foot, across the frame's whole width, so it stands
    # in front of the frame's top and its crest at every rarity (b); below the frame's top line only inside its sides.
    head = Layer()
    o = head.t
    band = np.maximum(o.y - foot, np.minimum(o.y - y0, np.maximum(x0 - o.x, o.x - x1)))
    head.image(img, fx, fy, band)
    # Its ink line (c), above the frame's rim's inner edge only: never along its cut foot, which the face continues.
    ink = np.clip(dilate(o.px[..., 3], INK_LINE) - o.px[..., 3], 0, 1) * cover(band) * cover(o.y - (y0 + width))
    over = Layer()
    over.t.px[..., 3] = ink * INK_ALPHA  # black: the Layer's colour is 0
    over.image(o.px, -M, -M)
    box = (x0 - HEAD_SIDE, HEAD_TOP, x1 + HEAD_SIDE, y0 + 6.0)
    return inside.crop(x0, y0, x1, y1), over.crop(*box)


# --- making ---------------------------------------------------------------------------------------------------------

RENDERS = Path(__file__).resolve().parents[2] / "build" / "scratch" / "faber" / "portraits"  # the uncut renders, out of git


def faces(out: Path):
    shots = {}
    renders = RENDERS
    renders.mkdir(parents=True, exist_ok=True)
    for who in list(hud_art.PORTRAITS) + ["Unknown"]:
        path = renders / f"{who}_uncut.png"
        if not path.exists():
            shot = hud_art.shoot_unknown(out) if who == "Unknown" else hud_art.shoot_portrait(who, out)
            rs.save(shot, path)
        shots[who] = rs.load(path)
    return shots


def make(out: Path):
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    listing = {}

    def keep(name, px, x0, y0, pad, use, cut=None):
        rs.save(px, images / f"{name}.png")
        entry = dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]],
                     points=[px.shape[1] / K, px.shape[0] / K], pad=pad, at=[x0, y0], use=use)
        if cut:
            entry["cut"] = cut
        listing[name] = entry

    pal = MIDNIGHT
    body_px, rim_px, pad = housing(pal)
    keep("CardHousing", body_px, X0, Y0, pad, "the two blades, Midnight; its box from X0, Y0 in the card's points")
    keep("CardHousingRim", rim_px, X0, Y0, pad, "the housing's rim: white, tinted the rarity's colour")
    tab_px, tab_rim, pad, cut = tab(pal)
    keep("CardTab", tab_px, left(TAB_FOOT), TAB_TOP, pad, "the name's tab, sliced across; its box from its foot's left", cut)
    keep("CardTabRim", tab_rim, left(TAB_FOOT), TAB_TOP, pad, "the tab's rim: white, tinted the rarity's colour", cut)
    for name, ramp, sheen, h in (("CardLightHealth", EMBER["hp"], EMBER["hp_sheen"], HEALTH_H),
                                 ("CardLightXp", EMBER["xp"], EMBER["xp_sheen"], XP_H)):
        px, cut = light(ramp, sheen, h)
        keep(name, px, 0.0, 0.0, 0.0, f"a light {h} high, sliced across: its box from its foot's left to its glow", cut)
    th_px, th_rim, pad, cut = target_housing(pal)
    keep("CardTargetHousing", th_px, left(T_Y1), Y0, pad, "the target's blade, sliced across; its box from its foot's left, in the lead's points", cut)
    keep("CardTargetHousingRim", th_rim, left(T_Y1), Y0, pad, "its rim: white, tinted", cut)
    b_px, b_rim, pad = badge(pal)
    keep("CardBadge", b_px, BADGE[0] - BADGE[2] / 2, BADGE[1] - BADGE[3] / 2, pad, "the level's badge")
    keep("CardBadgeRim", b_rim, BADGE[0] - BADGE[2] / 2, BADGE[1] - BADGE[3] / 2, pad, "the badge's rim: tinted")
    frame_right = 0.0
    for rarity in RARITIES:
        px = frame(rarity)
        frame_right = max(frame_right, rim_right(px))
        keep(f"CardFrame{rarity}", px, FRAME[0], FRAME[1], FRAME_PAD, f"the portrait's frame, {rarity}")
    p_px, p_rim, pad = plate(VIOLET)
    keep("CardPlate", p_px, plx(P_LEFT, P_BOTTOM), P_TOP, pad, "take F's plate, Violet; its box from its foot's left")
    keep("CardPlateRim", p_rim, plx(P_LEFT, P_BOTTOM), P_TOP, pad, "the plate's rim: white, tinted the rarity's colour")
    for name in LEAD_LIGHTS:
        px, cut = lead_light(name)
        keep(f"CardLead{name}", px, 0.0, 0.0, 0.0,
             f"the lead's {name} light on the plate, drawn full, sliced across: its box from its foot's left to its glow", cut)
    shots = faces(out)
    for who in hud_art.PORTRAITS:
        rarity = hud_art.voidkin_rarity(who)
        inside, head = face_and_head(shots[who], rarity, who, pal)
        keep(f"CardFace{who}", inside, FRAME[0], FRAME[1], 0.0, f"{who} in a {rarity} frame's opening, under the frame")
        keep(f"CardHead{who}", head, FRAME[0] - HEAD_SIDE, HEAD_TOP, 0.0, f"{who}'s head over the frame's top, over the frame")
    for rarity in RARITIES:
        inside, _ = face_and_head(shots["Unknown"], rarity, "Unknown", pal)
        keep(f"CardFaceUnknown{rarity}", inside, FRAME[0], FRAME[1], 0.0,
             f"a Voidkin with no portrait yet, {rarity}: its head inside the frame, no head over it")
    lights = light_rows()
    geometry = dict(card=[W, H], frame=list(FRAME), housing=[X0, Y0, X1, Y1], slant=SLANT, inset=INSET,
                    lights=lights, fillFrom=FILL_FROM, step=STEP, tab=[TAB_TOP, TAB_FOOT, TAB_REF, left(TAB_TOP)],
                    glow=GLOW, badge=list(BADGE), mid=MID, target=target_geometry(),
                    plate=dict(plate=[P_LEFT, P_TOP, P_END, P_BOTTOM], name=P_NAME, health=lead_row("Health"),
                               xp=lead_row("Xp"), stud=list(P_STUD), frameRight=frame_right,
                               level=[frame_right + LEVEL_CLEAR, P_BOTTOM + LEVEL_GAP, LEVEL_H]))
    (out / "lead_card.json").write_text(json.dumps(dict(pixelsPerPoint=K, geometry=geometry, images=listing), indent=1),
                                        encoding="utf-8", newline="\n")
    print(f"wrote {out / 'lead_card.json'}: {len(listing)} images")


# --- the review sheet: whole cards from the images, as the game lays them ---------------------------------------------

def tinted(px, colour):
    out = px.copy()
    out[..., :3] = c(colour)
    return out


def sliced(px, cut, width_pts):
    """A 9-slice across: the caps kept, the middle stretched (nearest), to `width_pts` points wide."""
    lc, rc = round(cut[0] * K), round(cut[2] * K)
    mid = px[:, lc:px.shape[1] - rc]
    want = max(round(width_pts * K) - lc - rc, 1)
    idx = np.minimum((np.arange(want) * mid.shape[1] / want).astype(int), mid.shape[1] - 1)
    return np.concatenate([px[:, :lc], mid[:, idx], px[:, px.shape[1] - rc:]], axis=1)


def tint(px, top, bottom=None):
    """The engine's tint: the image's colour times one colour, or two from its top to its foot (Skin.Tint's gradient)."""
    out = px.copy()
    a, b = c(top), c(bottom or top)
    v = ((np.arange(px.shape[0]) + 0.5) / px.shape[0])[:, None, None]
    out[..., :3] *= a + (b - a) * v
    return out


def mix(a, b, t):
    """Color3:Lerp, as the game mixes a trim toward white."""
    return "#" + "".join(f"{min(max(round(float(x) * 255), 0), 255):02X}" for x in c(a) * (1 - t) + c(b) * t)


def level_mark(geometry, digits):
    """The level's mark in D's place, beside the portrait under the plate (research's call, AR12, "The card's height"):
    its width by the level's digits (Modulo's mock, round two), its left 2 points clear of every frame at its widest."""
    x, y, _ = geometry["plate"]["level"]
    return x, y, {1: 56.0, 2: 64.0, 3: 73.0}[digits]


def compose_f(data, img, marks, geometry, face, head, rarity, kind, health, xp, digits, ground):
    """The lead's card, take F, as UI.LeadCard lays it: the plate and its rim, the two lights, the
    face, the frame, the head, the type's stud and the level's mark. The text is the game's own, not drawn here."""
    g = geometry["plate"]
    canvas = rs.canvas(round((W + 2 * M) * K), round((H + 2 * M) * K), tuple(c(ground)))

    def put(px, x, y):  # an opaque ground: rook_sheet's paste keeps the target's alpha
        rs.paste(canvas, px, round((x + M) * K), round((y + M) * K))

    def at(name, px=None):
        e = data[name]
        put(img[name] if px is None else px, e["at"][0] - e["pad"], e["at"][1] - e["pad"])

    trim = TRIM[rarity]
    at("CardPlate")
    at("CardPlateRim", tinted(img["CardPlateRim"], trim))
    for name, share in (("Health", health), ("Xp", xp)):
        if share <= 0:
            continue
        xl, y0, xr, h = g[name.lower()]
        e = data[f"CardLead{name}"]
        front = xl + (xr - xl) * share
        width = max(front - xl + h * SLANT + GLOW, e["cut"][0] + e["cut"][2])  # anchored at its front (LeadCard.Fill)
        put(sliced(img[f"CardLead{name}"], e["cut"], width), front + GLOW - width, y0)
    put(face, FRAME[0], FRAME[1])
    at(f"CardFrame{rarity}")
    if head is not None:
        put(head, FRAME[0] - HEAD_SIDE, HEAD_TOP)
    cx, cy, _ = g["stud"]
    for name in ("CardStudGlow", "CardStud"):
        put(tint(marks[name], TYPES[kind]), cx - 20.5, cy - 20.5)
    gem = rs.shrink(marks[f"Gem{kind}"], 14.6 * K / marks[f"Gem{kind}"].shape[1])
    put(gem, cx - gem.shape[1] / K / 2, cy - gem.shape[0] / K / 2)
    x, y, w = level_mark(geometry, digits)
    put(tint(sliced(marks["LevelPlate"], (24.0, 0, 8.0, 0), w), *VIOLET["tab"]), x, y)
    put(tint(sliced(marks["LevelPlateEdge"], (24.0, 0, 8.0, 0), w), mix(trim, "#FFFFFF", 0.6), trim), x, y)
    chevrons = tint(rs.shrink(marks["LevelChevrons"], 14.0 * K / marks["LevelChevrons"].shape[1]), VIOLET["body"][1])
    put(chevrons, x + 11.0 - 7.0, y + 11.0 - 7.0)
    return canvas[round((M - 8) * K):round((M + max(H, y + LEVEL_H) + 6.0) * K), round((M - 8) * K):round((M + W - 40.0) * K)]


def compose_target(data, img, geometry, health, text_w, ground):
    """The target's card as UI.TargetCard lays it: the blade, the light, the tab (the arrow, the name and the level
    are the game's own text, measured here by `text_w`, the name's left to the level's end)."""
    g = geometry["target"]
    tw, th = g["size"]
    dx, dy = g["offset"]
    canvas = rs.canvas(round((tw + 2 * M) * K), round((th + 2 * M) * K), tuple(c(ground)))

    def put(px, x, y):
        rs.paste(canvas, px, round((x + M) * K), round((y + M) * K))

    trim = TRIM["Common"]
    e = data["CardTargetHousing"]
    hx0, hy0, hx1, hy1 = g["housing"]
    for name in ("CardTargetHousing", "CardTargetHousingRim"):
        px = sliced(img[name], e["cut"], hx1 - hx0 + 2 * e["pad"])
        put(tinted(px, trim) if name.endswith("Rim") else px, hx0 - e["pad"], hy0 - e["pad"])
    xl, y0, xr, h = g["health"]
    if health > 0:
        el = data["CardLightHealth"]
        front = g["fillFrom"] + (xr - g["fillFrom"]) * health
        width = max(front - xl + h * SLANT + GLOW, el["cut"][0] + el["cut"][2])
        put(sliced(img["CardLightHealth"], el["cut"], width), xl - h * SLANT, y0)
    et = data["CardTab"]
    tab_w = (T_NAME_X - left(TAB_TOP)) + text_w + T_TAB_AFTER
    for name in ("CardTab", "CardTabRim"):
        px = sliced(img[name], et["cut"], tab_w + (TAB_FOOT - TAB_TOP) * SLANT + 2 * et["pad"])
        put(tinted(px, trim) if name.endswith("Rim") else px, et["at"][0] + dx - et["pad"], et["at"][1] + dy - et["pad"])
    return canvas[round((M - 8) * K):round((M + th + 8) * K), round((M - 8) * K):round((M + tw + 8) * K)]


T_NAME_X = 71.0  # the name's left on the tab, in the lead's points: the type edge's arrow before it (UI.TargetCard)
T_TAB_AFTER = 10.0  # the tab runs on past the level this far


TYPES = {"Strength": "#EA4B4F", "Endurance": "#F4902A", "Agility": "#3F9DF2", "Intelligence": "#A470F2",
         "Technique": "#42CC7E"}  # a type's colour, as Modulo's mocks tint the stud (tools/blender/shade_sheet.py)
GROUNDS = (("night", "#141925"), ("noon sand", "#D2BC93"))  # the seam's fix is read on both (AR12)
SHARES = ((0.78, 0.42, 1), (0.35, 0.9, 2), (1.0, 0.05, 2), (0.12, 0.6, 3), (0.04, 0.0, 2), (0.6, 1.0, 1))  # by rarity


def voidkin_type(name):
    text = (hud_art.REPO / "src" / "shared" / "Definitions" / "Voidkin.luau").read_text(encoding="utf-8")
    return re.search(r'Name = "%s", Rarity = "\w+", Type = "(\w+)"' % name, text).group(1)


def sheet(out: Path):
    """Take F's card, each portrait in all six rarities, on night and on noon sand: whole cards at the game's size (one
    pixel a point) and the portraits at 3x, for the seam's fix (AR12: "all six rarities are cut, with Rook, Lyric and a
    pale-haired Voidkin at card size and at 3x, over dark and over the noon sand"); two cards at 2x; then the target's
    card, unchanged."""
    listing = json.loads((out / "lead_card.json").read_text(encoding="utf-8"))
    data, geometry = listing["images"], listing["geometry"]
    img = {n: rs.load(out / e["file"]) for n, e in data.items()}
    ui_dir = out.parents[1]  # build/handoff/UI
    marks = {n: rs.load(ui_dir / "hud" / "colour" / "images" / f"{n}.png") for n in ("CardStud", "CardStudGlow")}
    marks |= {n: rs.load(ui_dir / "voidkin" / "marks" / "images" / f"{n}.png")
              for n in ("LevelPlate", "LevelPlateEdge", "LevelChevrons")}
    marks |= {f"Gem{k}": rs.load(ui_dir / "kit" / "images" / f"Gem{k}.png") for k in TYPES}
    shots = faces(out)

    def card(who, rarity, kind, health, xp, digits, ground):
        face, head = face_and_head(shots[who], rarity, who, MIDNIGHT)
        return compose_f(data, img, marks, geometry, face, None if who == "Unknown" else head, rarity, kind, health, xp,
                         digits, ground)

    cards = []
    for who in ("Rook", "Lyric", "Pip", "Unknown"):
        kind = voidkin_type(who) if who != "Unknown" else "Agility"
        row, zoom = [], []
        for _, ground in GROUNDS:
            line = []
            for rarity, (health, xp, digits) in zip(RARITIES, SHARES):
                px = card(who, rarity, kind, health, xp, digits, ground)
                row.append(rs.shrink(px, 1.0 / K))
                portrait = px[:round((8 + FRAME[1] + FRAME[3] + 10) * K), :round((8 + FRAME[0] + FRAME[2] + 14) * K)]
                line.append(rs.shrink(portrait, 3.0 / K))
            zoom.append(np.concatenate(line, axis=1))
        cards.append(np.concatenate(row, axis=1))
        if who != "Unknown":  # the portraits at 3x: night above, noon sand under
            rs.save(np.concatenate(zoom, axis=0), out / f"lead_card_portraits_3x_{who}.png")
    rs.save(np.concatenate(cards, axis=0), out / "lead_card_sheet.png")
    big = [card(who, rarity, voidkin_type(who), health, xp, digits, ground)
           for who, rarity, health, xp, digits in (("Rook", "Common", 0.78, 0.42, 1), ("Lyric", "Mythical", 0.12, 0.9, 3))
           for _, ground in GROUNDS]
    rs.save(np.concatenate([rs.shrink(px, 2.0 / K) for px in big], axis=1), out / "lead_card_sheet_2x.png")
    rows = [np.concatenate([compose_target(data, img, geometry, health, text_w, ground) for ground in ("#8C9AB0", "#141925")], axis=1)
            for health, text_w in ((1.0, 92.0), (0.46, 64.0), (0.08, 120.0))]
    rs.save(np.concatenate(rows, axis=0), out / "target_card_sheet.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "make"
    if mode == "make":
        make(out)
    elif mode == "sheet":
        sheet(out)


if __name__ == "__main__":
    main()
