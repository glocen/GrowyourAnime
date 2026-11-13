"""The lead's card, as kit images (TR3, the director's eye, 2026-11-13). The director's picks from the mocks: the card in
Midnight, a lacquered black gradient with a navy undertone ("something mature so gradiant black"); the Ember bars, lit
at the top, deep at the foot; both bars a little thinner; the empty part of each a little see-through ("a bit
transparent not by much"). The rim takes the lead's rarity's colour (TR3's verdict, fix 3), so it's drawn white and
tinted. The portrait is the card's biggest thing, the head standing over the frame's top rim.

Drawn by the builder at the director's ask, in Modulo's toolkit (ui_sheet.py) and from its portrait renders
(hud_art.py); Modulo may re-cut any face (AR3, section 3). The layers, bottom to top, as src/client/UI/LeadCard.luau
lays them, in the card's own points (232 by 96, its top left at the HUD's PAD, TOP):

  CardHousing            the two blades on one slant: the body, the slots, the ink, the shadow
  CardHousingRim         its rim, white: tinted the rarity's colour
  CardLightHealth/Xp     a bar's light, sliced across: lit top, sheen, deep foot, a bright front on the slant, a glow ahead
  CardTab, CardTabRim    the tab under the name, sliced across to fit it; it covers the housing's rim where it sits
  CardFace<Who>          the face cut to its frame's opening, on Midnight's well, its foot faded
  CardFrame<Rarity>      the portrait's frame at the card's size: its glow and its rim, the opening clear
  CardHead<Who>          the head over the frame's top rim, along its straight top, its sides soft
  CardBadge, CardBadgeRim  the level's badge

    blender -b --factory-startup --python tools/blender/lead_card_art.py -- build/handoff/UI/hud/lead_card make
    blender -b --factory-startup --python tools/blender/lead_card_art.py -- build/handoff/UI/hud/lead_card sheet

`make` renders the faces (or reuses the uncut renders already in the out folder's renders/, kept out of git), writes
images/*.png and lead_card.json (tools/ui/kit_config.py reads it); `sheet` composes whole cards from them for review,
on a pale and a night ground.
"""
import json
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
    # The rim along the left edge to the tab's foot (it meets the housing's own there), the top, the right edge to Y0.
    keep = np.where(r.x < left(TAB_TOP) + TAB_REF / 2, r.y - TAB_FOOT, r.y - Y0 - 0.55)
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
    if "glow" in r:
        code, radius, strength = r["glow"]
        ui.over(t.px, c(code), strength * 0.8 * np.exp(-(np.maximum(d, 0) / (radius * scale)) ** 1.4) * outside(d))
    shadow(t, d, 5.0, 0.4)
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


def face_and_head(face, rarity, who, pal):
    x0, y0, w, h = FRAME
    x1, y1 = x0 + w, y0 + h
    img, fx, fy = placed(face, rarity, who)
    inside = Layer()
    t = inside.t
    r, d, scale, width = frame_geometry(t, rarity)
    t.paint(d, stops(t, (t.y - y0) / h, ((0, pal["well"][0]), (1, pal["well"][1]))))
    behind = np.exp(-(((t.x - (x0 + w / 2)) / 20.0) ** 2 + ((t.y - (y0 + h * 0.38)) / 16.0) ** 2))  # light behind the head
    ui.over(t.px, c(pal["tab"][0]), cover(d) * behind * 0.55)
    inside.image(img, fx, fy, d + width * 0.5)
    t.paint(np.maximum(d, y1 - h * 0.25 - t.y), BLACK, 0.18)
    over = Layer()
    o = over.t
    tl, tr = r["cut"][0], r["cut"][1]
    sx0, sx1 = x0 + max(tl * 0.6, width), x1 - max(tr * 0.6, width)
    band = o.poly([(sx0, HEAD_TOP - 20), (sx1, HEAD_TOP - 20), (sx1, y0 + width + 0.4), (sx0, y0 + width + 0.4)])
    over.image(img, fx, fy, band / 6.0)
    return inside.crop(x0, y0, x1, y1), over.crop(x0, HEAD_TOP, x1, y0 + 6.0)


# --- making ---------------------------------------------------------------------------------------------------------

def faces(out: Path):
    shots = {}
    renders = out / "renders"
    renders.mkdir(exist_ok=True)
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
    b_px, b_rim, pad = badge(pal)
    keep("CardBadge", b_px, BADGE[0] - BADGE[2] / 2, BADGE[1] - BADGE[3] / 2, pad, "the level's badge")
    keep("CardBadgeRim", b_rim, BADGE[0] - BADGE[2] / 2, BADGE[1] - BADGE[3] / 2, pad, "the badge's rim: tinted")
    for rarity in RARITIES:
        keep(f"CardFrame{rarity}", frame(rarity), FRAME[0], FRAME[1], FRAME_PAD, f"the portrait's frame, {rarity}")
    shots = faces(out)
    for who in hud_art.PORTRAITS:
        rarity = hud_art.voidkin_rarity(who)
        inside, head = face_and_head(shots[who], rarity, who, pal)
        keep(f"CardFace{who}", inside, FRAME[0], FRAME[1], 0.0, f"{who} in a {rarity} frame's opening, under the frame")
        keep(f"CardHead{who}", head, FRAME[0], HEAD_TOP, 0.0, f"{who}'s head over the frame's top rim, over the frame")
    for rarity in RARITIES:
        inside, _ = face_and_head(shots["Unknown"], rarity, "Unknown", pal)
        keep(f"CardFaceUnknown{rarity}", inside, FRAME[0], FRAME[1], 0.0,
             f"a Voidkin with no portrait yet, {rarity}: its head inside the frame, no head over it")
    lights = light_rows()
    geometry = dict(card=[W, H], frame=list(FRAME), housing=[X0, Y0, X1, Y1], slant=SLANT, inset=INSET,
                    lights=lights, fillFrom=FILL_FROM, step=STEP, tab=[TAB_TOP, TAB_FOOT, TAB_REF, left(TAB_TOP)],
                    glow=GLOW, badge=list(BADGE), mid=MID)
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


def compose(data, img, who, rarity, health, xp, name_w, ground):
    canvas = rs.canvas(round((W + 2 * M) * K), round((H + 2 * M) * K), tuple(c(ground)))

    def put(px, x, y):  # an opaque ground: rook_sheet's paste keeps the target's alpha
        rs.paste(canvas, px, round((x + M) * K), round((y + M) * K))

    def at(name, px=None, x=None, y=None):
        e = data[name]
        put(img[name] if px is None else px, (e["at"][0] if x is None else x) - e["pad"], (e["at"][1] if y is None else y) - e["pad"])

    trim = TRIM[rarity]
    at("CardHousing")
    at("CardHousingRim", tinted(img["CardHousingRim"], trim))
    rows = light_rows()
    for name, share in (("Health", health), ("Xp", xp)):
        if share <= 0:
            continue
        xl, y0, xr, h = rows[name]
        name = f"CardLight{name}"
        e = data[name]
        front = FILL_FROM + (xr - FILL_FROM) * share
        width = max(front - xl + h * SLANT + GLOW, e["cut"][0] + e["cut"][2])
        put(sliced(img[name], e["cut"], width), xl - h * SLANT, y0)
    tab_w = 66.0 + name_w + 22.0 - left(TAB_TOP)
    e = data["CardTab"]
    for name in ("CardTab", "CardTabRim"):
        px = sliced(img[name], e["cut"], tab_w + (TAB_FOOT - TAB_TOP) * SLANT + 2 * e["pad"])
        put(tinted(px, trim) if name.endswith("Rim") else px, e["at"][0] - e["pad"], e["at"][1] - e["pad"])
    face = who if who != "Unknown" else f"Unknown{rarity}"
    at(f"CardFace{face}")
    at(f"CardFrame{rarity}")
    if f"CardHead{face}" in data:
        at(f"CardHead{face}")
    at("CardBadge")
    at("CardBadgeRim", tinted(img["CardBadgeRim"], trim))
    return canvas[round((M - 8) * K):round((M + H) * K), round((M - 8) * K):round((M + W) * K)]


def sheet(out: Path):
    """Each card on a pale ground and a night one, at 4 pixels a point: the text is the game's own, not drawn here."""
    data = json.loads((out / "lead_card.json").read_text(encoding="utf-8"))["images"]
    img = {n: rs.load(out / e["file"]) for n, e in data.items()}
    rows = []
    for who, rarity, health, xp, name_w in (("Rook", "Common", 0.78, 0.42, 29.8), ("Pip", "Common", 0.35, 0.9, 19.2),
                                            ("Lyric", "Rare", 1.0, 0.05, 29.5), ("Unknown", "Uncommon", 0.5, 0.3, 50.0),
                                            ("Unknown", "Epic", 0.12, 0.6, 50.0), ("Unknown", "Legendary", 0.6, 0.0, 50.0),
                                            ("Unknown", "Mythical", 0.01, 1.0, 50.0)):
        rows.append(np.concatenate([compose(data, img, who, rarity, health, xp, name_w, ground)
                                    for ground in ("#8C9AB0", "#141925")], axis=1))
    rs.save(np.concatenate(rows[:3], axis=0), out / "lead_card_sheet.png")
    rs.save(np.concatenate(rows[3:], axis=0), out / "lead_card_sheet_unknown.png")


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
