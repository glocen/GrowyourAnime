"""TR5's frames (Modulo, 2026-11-14): the keeper's HUD and the elite's card, as kit images.

The keeper's HUD is Faber's (src/client/UI/BossBar.luau), rebuilt on the director's words of 2026-11-14 ("much better
... this is so empty", the health "purpleish", "well compose", "it does need to looks very light too else we see
nothing"): no plate, nothing solid over the fight. Research's word of the same day: the title's frame is the two rules
with diamond tips and a small crest at the middle top, as one ornament; the bar twice as thick, 20, its number inside
its right end (TR5's verdict, fixes 1 and 2). So the keeper's pieces are line art in the kit's metal: white to tint
(Config.Hud.Boss.Rim), lit from above, with a dark hairline baked in so each reads on Lantern Row's pale floor.

  BossBarRim               the bar's rim, outside the channel's box; sliced: its box is the channel's
  BossBarCap               an end cap: a faceted lozenge centred on the bar's end
  BossBarMark              a phase mark: a narrower lozenge centred on the bar at its share
  BossTitleRuleLeft/Right  a rule, its diamond tip at the outer end, tapering toward the title; sliced across
  BossTitleCrest           the small crest over the title's middle

The elite's card (TR5's C) is the target card (tools/blender/lead_card_art.py, Faber's) made heavier, drawn with its
helpers in the lead's points and at the target's true length (lead_card_art.T_END):

  CardTargetEliteHousing(Rim)  the blade 6 taller, its slot 23 high, the light one piece in it; sliced across
  CardLightHealthElite         the Ember light 23 high; sliced across
  CardTargetEliteFrame         the heavier frame round the blade and the Elite tab, the crest notch on the tab: white,
                               tinted; sliced across, the tab in its right cap
  CardTargetEliteTab(Rim)      the tab at the blade's right end, for the word Elite in the card's ink

    blender -b --factory-startup --python tools/blender/boss_hud_art.py -- <out> make
    blender -b --factory-startup --python tools/blender/boss_hud_art.py -- <out> sheet

`make` writes images/*.png and boss.json (lead_card.json's schema: `at` is the piece's box, the image reaching `pad`
past it on every side; `cut` is left, top, right, bottom in points). `sheet` composes the keeper's HUD and the elite's
card from them as the game lays them, with stand-in text in Blender's own face, at 2 and 1 pixels a point (1 is a phone),
on the sky, the pale floor and the night: boss_sheet.png.
"""
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lead_card_art as lc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

K = ui.K = 4
c = ui.c
WHITE, BLACK = ui.WHITE, ui.BLACK
DARK = c("#0A0B0F")  # the kit's baked dark: it stays dark under any tint
ROOT = Path(__file__).resolve().parents[2]
LEAD = ROOT / "build" / "handoff" / "UI" / "hud" / "lead_card"
KIT = ROOT / "build" / "handoff" / "UI" / "kit" / "images"

HAIR, HAIR_A = 0.6, 0.85  # the dark hairline round each piece, and its cover
LIT, SHADE = 1.0, 0.56  # the metal facing up, facing down: white to tint


def blank(w, h):
    sheet = ui.Sheet(w, h, "#000000")
    sheet.px[:] = 0
    return sheet.tile(0, 0, w, h)


def facing(d):
    """How far a shape's outward side faces down: -1 on a top edge, +1 on a bottom one."""
    gy, gx = np.gradient(d)
    return gy / (np.hypot(gx, gy) + 1e-6)


def metal(t, band, hair_a=HAIR_A):
    """A band of the kit's metal (`band` its signed distance, negative inside), bevelled and lit from above: the half
    of it that faces up is bright, the half that faces down in shade. A dark hairline round it."""
    t.paint(np.abs(band - HAIR / 2) - HAIR / 2, DARK, hair_a)
    shade = LIT - (LIT - SHADE) * (facing(band) + 1) / 2
    t.paint(band, WHITE * shade[..., None])


def lozenge(t, cx, cy, a, b, hair_a=HAIR_A):
    """A faceted lozenge, `a` across and `b` up from its centre: four facets lit from the top left, a glint on its two
    upper edges, a dark hairline round it."""
    d = t.poly([(cx, cy - b), (cx + a, cy), (cx, cy + b), (cx - a, cy)])
    t.paint(np.abs(d - HAIR / 2) - HAIR / 2, DARK, hair_a)
    wl = np.clip(0.5 - (t.x - cx) * K, 0, 1)
    wt = np.clip(0.5 - (t.y - cy) * K, 0, 1)
    shade = wt * (wl * 0.9 + (1 - wl) * 0.76) + (1 - wt) * (wl * 0.6 + (1 - wl) * 0.46)
    t.paint(d, WHITE * shade[..., None])
    t.paint(np.maximum(np.abs(d + 0.3) - 0.3, t.y - cy + 0.4), WHITE, 0.9)  # the glint
    return d


def taper(t, pts, w0, power=0.8):
    """A blade along a polyline, `w0` thick at its first point and coming to a point at its last."""
    n = len(pts) - 1
    d = np.full(t.x.shape, 1e9, dtype=np.float32)
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        ex, ey = b[0] - a[0], b[1] - a[1]
        u = np.clip(((t.x - a[0]) * ex + (t.y - a[1]) * ey) / (ex * ex + ey * ey), 0, 1)
        half = w0 / 2 * (1 - (i + u) / n) ** power
        d = np.minimum(d, np.hypot(t.x - a[0] - ex * u, t.y - a[1] - ey * u) - half)
    return d


# --- the keeper's HUD -------------------------------------------------------------------------------------------------

BAR_H = 20.0  # Config.Hud.Boss.Top.Bar: twice the grey's 10 (TR5's verdict, fix 2)
RIM_BAND = 1.6  # the bar's rim, outside the channel
CAP = (6.0, 14.5)  # the end cap's half across, half up: 12 by 29, standing 4.5 past the bar each way
MARK = (3.5, 13.0)  # the phase mark's: 7 by 26
RULE_W, TIP, TIP_GAP, TAPER = 1.5, (5.5, 3.2), 1.0, 24.0  # the rule's thickness (BossBar's RULE); its tip; the gap after the tip; the taper toward the title
CREST = (24.0, 11.0)  # the crest's box


def bar_rim():
    w, pad = 60.0, 3.0
    t = blank(w + 2 * pad, BAR_H + 2 * pad)
    d = t.poly(ui.cut_box(pad, pad, pad + w, pad + BAR_H))
    t.paint(np.abs(d + 0.35) - 0.35, DARK, 0.6)  # inside the rim, over the fill's edge: it seats the light
    metal(t, np.abs(d - RIM_BAND / 2) - RIM_BAND / 2)
    cap = pad + 5.0
    return t.px, pad, [cap, cap, cap, cap]


def bar_lozenge(half):
    a, b = half
    pad = 1.5
    t = blank(2 * a + 2 * pad, 2 * b + 2 * pad)
    lozenge(t, pad + a, pad + b, a, b)
    return t.px, pad


def title_rule(length=80.0):
    """The left rule: its tip at the outer end, the line from just past it, tapering to a point at the title's side."""
    a, b = TIP
    pad = 1.5
    t = blank(length + 2 * pad, 2 * b + 2 * pad)
    cy = pad + b
    lozenge(t, pad + a, cy, a, b, hair_a=0.6)
    x0, x1 = pad + 2 * a + TIP_GAP, pad + length
    half = RULE_W / 2 * np.clip((x1 - t.x) / TAPER, 0, 1) ** 0.6
    line = np.maximum(np.abs(t.y - cy) - half, np.maximum(x0 - t.x, t.x - x1))
    metal(t, line, hair_a=0.6)
    return t.px, pad, lc.across(t.px, pad + 2 * a + TIP_GAP + 2.0, TAPER + pad + 1.0)


def title_crest():
    """A lozenge standing over the title's middle, two thin wings swept out and down from its waist: the rules' tip
    and their taper, drawn as one small crest."""
    w, h = CREST
    pad = 1.5
    t = blank(w + 2 * pad, h + 2 * pad)
    cx, cy = pad + w / 2, pad + h / 2
    for s in (-1, 1):
        wing = taper(t, [(cx + s * 1.6, cy + 0.6), (cx + s * 6.5, cy + 1.3), (cx + s * w / 2, cy + 3.6)], 2.0)
        metal(t, wing, hair_a=0.7)
    lozenge(t, cx, cy, 2.9, h / 2, hair_a=0.7)
    return t.px, pad


# --- the elite's card -----------------------------------------------------------------------------------------------
# In the lead's points (lead_card_art), at the target's true length: the blade's top right at T_END.

E_H = lc.HEALTH_H + 6.0  # the slot 23 high: Config.Hud.Boss.Frame.Under folded into one light
E_Y1 = lc.HEALTH_Y0 + E_H + lc.INSET  # the blade's foot
END = lc.T_END
DX, DY = lc.T_OFFSET
ETAB_TOP = lc.TAB_TOP + 3.0  # the Elite tab's top, under the name tab's: the crest notch stands over it
ETAB_LEDGE = 5.0  # its right edge this far in from the blade's right end
ETAB_W = 46.0  # its top edge: the word at Caption and room either side
E_GAP, E_BAND = 0.9, 2.2  # the frame: its dark gap outside the housing's rim, its band
NOTCH = (3.8, 5.5)  # the crest notch's half across, half up: its foot clear of the word
E_PAD = 10.0


def etab_pts():
    right = lambda y: END - ETAB_LEDGE - (y - lc.Y0) * lc.SLANT  # noqa: E731
    xr = right(ETAB_TOP)
    xl = xr - ETAB_W
    run = (lc.TAB_FOOT - ETAB_TOP) * lc.SLANT
    return [(xl, ETAB_TOP), (xr, ETAB_TOP), (xr - run, lc.TAB_FOOT), (xl - run, lc.TAB_FOOT)]


def notch_centre():
    (xl, y), (xr, _) = etab_pts()[:2]
    return (xl + xr) / 2, y - E_GAP - E_BAND / 2 - 2.2


class Area:
    """A transparent drawing over a box in the lead's points."""

    def __init__(self):
        self.x0, self.y0 = lc.left(E_Y1) - 16.0, ETAB_TOP - 16.0
        x1, y1 = END + 16.0, E_Y1 + 16.0
        self.sheet = ui.Sheet(x1 - self.x0, y1 - self.y0, "#000000")
        self.sheet.px[:] = 0
        self.t = self.sheet.tile(0, 0, x1 - self.x0, y1 - self.y0)
        self.t.x += self.x0
        self.t.y += self.y0

    def crop(self, x0, y0, x1, y1):
        return self.t.px[round((y0 - self.y0) * K):round((y1 - self.y0) * K), round((x0 - self.x0) * K):round((x1 - self.x0) * K)].copy()


def e_slot(t):
    ya, yb = lc.HEALTH_Y0, lc.HEALTH_Y0 + E_H
    right = lambda y: END - lc.INSET * 1.3 - (y - lc.Y0) * lc.SLANT  # noqa: E731
    return t.poly([(lc.left(ya) + lc.INSET * 1.3, ya), (right(ya), ya), (right(yb), yb), (lc.left(yb) + lc.INSET * 1.3, yb)])


def elite_housing(pal):
    """lead_card_art.target_housing, the slot 6 taller."""
    lay = Area()
    t = lay.t
    house = t.poly(lc.blade(lc.Y0, E_Y1, END))
    slot = e_slot(t)
    pad = 6.0
    lc.shadow(t, house, 4.5, 0.5, pad)
    region = np.maximum(house, -slot)
    lc.body(t, region, pal)
    lc.lacquer(t, region, lc.Y0, pal)
    ui.over(t.px, lc.stops(t, (t.y - lc.HEALTH_Y0) / E_H, ((0, pal["slot"][0]), (1, pal["slot"][1]))), lc.cover(slot) * lc.SLOT_ALPHA)
    t.paint(np.maximum(slot, np.abs(t.y - (lc.HEALTH_Y0 + E_H) + 0.5) - 0.45), c(pal["glint"]), 0.18)
    t.line(house - lc.RIM, 0.7, c(pal["ink"]), 0.8)
    t.line(house + lc.RIM, 0.6, BLACK, 0.5)
    top_edges = np.maximum(house + lc.RIM, -(house + lc.RIM + 1.2))
    lit_from_above = np.clip((np.roll(house, 3, axis=0) - house) * 1.5, 0, 1)
    ui.over(t.px, c(pal["glint"]), lc.cover(top_edges) * lit_from_above * 0.7)
    rim = Area()
    rim.t.line(rim.t.poly(lc.blade(lc.Y0, E_Y1, END)), lc.RIM, WHITE)
    box = (lc.left(E_Y1) - pad, lc.Y0 - pad, END + pad, E_Y1 + pad)
    run = (E_Y1 - lc.Y0) * lc.SLANT
    cap = pad + run + lc.INSET * 1.3 + 2.0
    image = lay.crop(*box)
    return image, rim.crop(*box), pad, lc.across(image, cap, cap)


def frame_box():
    """The frame's box, its pad past it: the blade and the tab."""
    return lc.left(E_Y1), ETAB_TOP, max(END, etab_pts()[1][0]), E_Y1


def elite_frame():
    """A second, heavier rim outside the housing's: a dark gap, a bevelled band of metal, its hairline and a soft
    shadow, round the blade and the Elite tab as one shape; the crest notch on the band over the tab. The name's tab
    lies over its top edge, as it lies over the housing's rim."""
    lay = Area()
    t = lay.t
    shape = np.minimum(t.poly(lc.blade(lc.Y0, E_Y1, END)), t.poly(etab_pts()))
    out = E_GAP + E_BAND
    lc.shadow(t, shape - out - HAIR, 3.0, 0.4, E_PAD - out - HAIR)
    t.paint(np.abs(shape - E_GAP / 2) - E_GAP / 2, DARK, 0.9)
    metal(t, np.abs(shape - E_GAP - E_BAND / 2) - E_BAND / 2)
    nx, ny = notch_centre()
    lozenge(t, nx, ny, *NOTCH)
    x0, y0, x1, y1 = frame_box()
    image = lay.crop(x0 - E_PAD, y0 - E_PAD, x1 + E_PAD, y1 + E_PAD)
    left_cap = E_PAD + (E_Y1 - lc.Y0) * lc.SLANT + out + 3.0
    right_cap = (x1 + E_PAD) - (etab_pts()[3][0] - out - 3.0)
    return image, E_PAD, lc.across(image, left_cap, right_cap)


def elite_tab(pal):
    """lead_card_art.tab's make, at the blade's right end: Midnight's tab gradient, its lacquer and ink, a patch of
    the housing's own body over the housing's rim where it sits; its rim up its two sides and across its top. No
    shadow of its own: the frame round it gives the edge."""
    pts = etab_pts()
    lay = Area()
    t = lay.t
    d = t.poly(pts)
    pad = 5.0
    above = np.maximum(d, t.y - lc.Y0)
    t.paint(above, lc.stops(t, (t.y - ETAB_TOP) / (lc.Y0 - ETAB_TOP), ((0, pal["tab"][0]), (1, pal["tab"][1]))))
    lc.lacquer(t, above, ETAB_TOP, pal)
    patch = np.maximum(d, lc.Y0 - 0.25 - t.y)
    lc.body(t, patch, pal)
    lc.lacquer(t, patch, lc.Y0, pal)
    t.line(above - lc.RIM, 0.7, c(pal["ink"]), 0.8)
    edge = np.maximum(d + lc.RIM, -(d + lc.RIM + 1.2))
    lit_from_above = np.clip((np.roll(d, 3, axis=0) - d) * 1.5, 0, 1)
    ui.over(t.px, c(pal["glint"]), lc.cover(np.maximum(edge, t.y - lc.Y0)) * lit_from_above * 0.7)
    rim = Area()
    r = rim.t
    dr = r.poly(pts)
    r.paint(np.maximum(np.abs(dr + lc.RIM / 2) - lc.RIM / 2, r.y - lc.Y0 - 0.55), WHITE)
    for layer in (lay, rim):
        layer.t.px[..., 3] *= lc.cover(layer.t.y - lc.TAB_FOOT)
    box = (pts[3][0] - pad, ETAB_TOP - pad, pts[1][0] + pad, lc.TAB_FOOT + pad)
    return lay.crop(*box), rim.crop(*box), pad


def elite_geometry():
    """The elite's card in the target card's own points (UIKit.TargetCard's frame of reference)."""
    xl = lc.left(lc.HEALTH_Y0) + lc.INSET * 1.3
    xr = END - lc.INSET * 1.3 - (lc.HEALTH_Y0 - lc.Y0) * lc.SLANT - lc.INSET * 1.3
    mid = lc.HEALTH_Y0 + E_H / 2
    pts = etab_pts()
    word_y = (ETAB_TOP + lc.Y0) / 2
    word_x = (pts[0][0] + pts[1][0]) / 2 - (word_y - ETAB_TOP) * lc.SLANT
    nx, ny = notch_centre()
    return dict(size=[lc.T_W, E_Y1 + DY], housing=[lc.left(E_Y1) + DX, lc.Y0 + DY, END + DX, E_Y1 + DY],
                health=[xl + DX, lc.HEALTH_Y0 + DY, xr + DX, E_H], fillFrom=xl + DX, stud=[lc.left(mid) + DX, mid + DY],
                tab=[[x + DX, y + DY] for x, y in pts], word=[word_x + DX, word_y + DY],
                nameTabEnd=pts[0][0] - 4.0 + DX, artTop=ny - NOTCH[1] - HAIR + DY)


# --- make -----------------------------------------------------------------------------------------------------------

def make(out: Path):
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    listing = {}

    def keep(name, px, at, pad, use, cut=None):
        rs.save(rs.bleed(px), images / f"{name}.png")
        entry = dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]],
                     points=[px.shape[1] / K, px.shape[0] / K], pad=pad, at=list(at), use=use)
        if cut:
            entry["cut"] = cut
        listing[name] = entry

    px, pad, cut = bar_rim()
    keep("BossBarRim", px, (0.0, 0.0), pad, f"the bar's rim, white, tinted Rim: sliced, its box the channel's ({BAR_H:g} high); "
         "outside it a band of metal and a hairline, inside a dark line over the fill's edge", cut)
    px, pad = bar_lozenge(CAP)
    keep("BossBarCap", px, (0.0, 0.0), pad, "an end cap, white, tinted Rim: centred on the channel's end, both ends")
    px, pad = bar_lozenge(MARK)
    keep("BossBarMark", px, (0.0, 0.0), pad, "a phase mark, white, tinted Rim: centred on the channel at its share")
    px, pad, cut = title_rule()
    keep("BossTitleRuleLeft", px, (0.0, 0.0), pad, "the left rule, white, tinted Rim: sliced across; its box from the "
         "tip's outer point to the taper's end, centred on the title's middle", cut)
    keep("BossTitleRuleRight", px[:, ::-1].copy(), (0.0, 0.0), pad, "the right rule, the left's mirror", [cut[2], cut[1], cut[0], cut[3]])
    px, pad = title_crest()
    keep("BossTitleCrest", px, (0.0, 0.0), pad, f"the crest, white, tinted Rim: {CREST[0]:g} by {CREST[1]:g}, its foot's "
         "middle on the title's top middle")

    pal = lc.MIDNIGHT
    px, rim, pad, cut = elite_housing(pal)
    keep("CardTargetEliteHousing", px, (lc.left(E_Y1), lc.Y0), pad, "the elite's blade, 6 taller, sliced across; "
         "its box from its foot's left, in the lead's points", cut)
    keep("CardTargetEliteHousingRim", rim, (lc.left(E_Y1), lc.Y0), pad, "its rim: white, tinted TargetTrim", cut)
    px, cut = lc.light(lc.EMBER["hp"], lc.EMBER["hp_sheen"], E_H)
    keep("CardLightHealthElite", px, (0.0, 0.0), 0.0, f"the elite's light, {E_H:g} high, sliced across: its box from "
         "its foot's left to its glow", cut)
    px, pad, cut = elite_frame()
    x0, y0, _, _ = frame_box()
    keep("CardTargetEliteFrame", px, (x0, y0), pad, "the heavier frame round the blade and the Elite tab, the crest notch "
         "on the tab: white, tinted; sliced across, the tab in its right cap; its box from the blade's foot's left and "
         "the tab's top, in the lead's points; under the name's tab", cut)
    px, rim, pad = elite_tab(pal)
    foot_left = etab_pts()[3][0]
    keep("CardTargetEliteTab", px, (foot_left, ETAB_TOP), pad, "the Elite tab at the blade's right end; its box from "
         "its foot's left, in the lead's points; the word Elite in the card's ink on it")
    keep("CardTargetEliteTabRim", rim, (foot_left, ETAB_TOP), pad, "its rim: white, tinted TargetTrim")

    geometry = dict(bar=dict(height=BAR_H, cap=[2 * CAP[0], 2 * CAP[1]], mark=[2 * MARK[0], 2 * MARK[1]],
                             rim=RIM_BAND + HAIR, rule=dict(width=RULE_W, tip=[2 * TIP[0], 2 * TIP[1]], gap=TIP_GAP, taper=TAPER),
                             crest=list(CREST)),
                    elite=elite_geometry())
    (out / "boss.json").write_text(json.dumps(dict(pixelsPerPoint=K, geometry=geometry, images=listing), indent=1),
                                   encoding="utf-8", newline="\n")
    print(f"wrote {out / 'boss.json'}: {len(listing)} images")


# --- the review sheet -------------------------------------------------------------------------------------------------

GROUNDS = {"sky": "#A9CBE0", "floor": "#CDD1D9", "night": "#141925"}
RIM_TINT, RIM_ALPHA, RULE_ALPHA = "#DCCBFF", 0.85, 0.7  # Config.Hud.Boss: Rim, Look.Rim 0.15, Look.Rule 0.3
FRAME_TINT = "#C9D2E4"  # Graphite's glint: the kit's steel, a proposal for the elite's frame
TRIM = "#666C78"  # Config.Hud.Card.TargetTrim
IVORY, GOLD, TITLE = "#F3EFE6", "#F2CB62", "#D9CFEA"


def tinted(px, colour, alpha=1.0):
    out = px.copy()
    out[..., :3] *= c(colour)
    out[..., 3] *= alpha
    return out


def edged(layer, radius_pts=1.5, alpha=0.75):
    """A dark edge round text: its cover spread by `radius_pts`."""
    a = layer[..., 3]
    r = round(radius_pts * K)
    grown = a.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                grown = np.maximum(grown, np.roll(np.roll(a, dy, axis=0), dx, axis=1))
    edge = np.zeros_like(layer)
    edge[..., :3] = DARK
    edge[..., 3] = grown * alpha
    return edge


def resize(px, pts):
    """A square picture to `pts` points (nearest): the review's stand-in gems."""
    n = round(pts * K)
    ys = (np.arange(n) * px.shape[0] / n).astype(int)
    xs = (np.arange(n) * px.shape[1] / n).astype(int)
    return px[ys][:, xs]


def shrink(px, f):
    h, w = px.shape[0] // f * f, px.shape[1] // f * f
    return px[:h, :w].reshape(h // f, f, w // f, f, 4).mean(axis=(1, 3))


class Board:
    """A composite in points, on a ground, its text set at the end."""

    def __init__(self, w, h, ground):
        self.sheet = ui.Sheet(w, h, ground)
        self.t = self.sheet.tile(0, 0, w, h)

    def put(self, px, x, y):
        rs.paste(self.sheet.px, px, round(x * K), round(y * K))

    def text(self, x, y_mid, size, text, colour, align="LEFT", bold=0.0):
        self.t.text(x, y_mid - size * ui.CAP / 2, size, text, colour, align=align, bold=bold)

    def done(self, edge=True):
        for layer in ui.text_layers(self.sheet.px.shape[1], self.sheet.px.shape[0], self.sheet.items).values():
            if edge:
                rs.paste(self.sheet.px, edged(layer), 0, 0)
            rs.paste(self.sheet.px, layer, 0, 0)
        return self.sheet.px


def sliced(px, cut, width_pts):
    return lc.sliced(px, cut, width_pts)


def keeper(data, img, ground, width=300.0, share=0.62, trail=0.7):
    """The keeper's HUD as BossBar lays B, with research's fixes: the title and its ornament, the name row, the bar 20
    high with its number inside its right end. Faber's own parts (the glow, the channel, the trail, the fill) drawn as
    he builds them."""
    m = 10.0
    b = Board(width + 2 * m, 96.0, GROUNDS[ground])
    x0 = m
    crest_h = CREST[1]
    title_y = 4.0 + crest_h - 2.0  # the title row's top: the crest's foot 2 into it
    e = data["BossTitleCrest"]
    b.put(tinted(img["BossTitleCrest"], RIM_TINT, RIM_ALPHA), x0 + width / 2 - CREST[0] / 2 - e["pad"], title_y + 2.0 - crest_h - e["pad"])
    mid = title_y + 8.0
    b.text(x0 + width / 2, mid, 14, "Keeper of Lantern Row", TITLE, align="CENTER")
    title_w = 140.0  # the title's measured width, about, at Caption
    reach = (width - title_w) / 2 - 8.0
    for name, x in (("BossTitleRuleLeft", x0), ("BossTitleRuleRight", x0 + width - reach)):
        e = data[name]
        px = sliced(img[name], e["cut"], reach + 2 * e["pad"])
        b.put(tinted(px, RIM_TINT, RULE_ALPHA), x - e["pad"], mid - TIP[1] - e["pad"])
    name_mid = title_y + 16.0 + 13.0
    gem = img.get("GemIntelligence")
    name_w, level_w = 150.0, 26.0  # the stand-in face's widths
    row = 20.0 + 6 + name_w + 6 + level_w
    rx = x0 + width / 2 - row / 2
    if gem is not None:
        b.put(resize(gem, 20.0), rx, name_mid - 10.0)
    b.text(rx + 26.0, name_mid, 20, "The Lamplighter", IVORY, bold=0.25 * K)
    b.text(rx + 26.0 + name_w + 6.0, name_mid + 1.0, 14, "Lv 9", GOLD)
    top = title_y + 16.0 + 26.0 + 1.0
    glow_h = 4.0 * 2 + BAR_H
    t = b.t
    across = np.clip(np.minimum((t.x - x0) / (0.15 * width), (x0 + width - t.x) / (0.15 * width)), 0, 1)
    pill = t.poly(ui.cut_box(x0, top, x0 + width, top + glow_h))
    ui.over(t.px, c("#9150FF"), lc.cover(pill) * across * 0.18)
    inset = 7.0
    cx0, cy0, cx1, cy1 = x0 + inset, top + 4.0, x0 + width - inset, top + 4.0 + BAR_H
    channel = t.poly(ui.cut_box(cx0, cy0, cx1, cy1))
    ui.over(t.px, c("#0E0F13"), lc.cover(channel) * 0.7)
    long = cx1 - cx0
    ui.over(t.px, c("#F3E9FF"), lc.cover(np.maximum(channel, t.x - (cx0 + long * trail))) * 0.85)
    fill = np.maximum(channel, t.x - (cx0 + long * share))
    ramp = lc.stops(t, (t.y - cy0) / BAR_H, ((0, "#CDA6FF"), (0.45, "#9150FF"), (1, "#5A27C9")))
    ui.over(t.px, ramp, lc.cover(fill))
    e = data["BossBarRim"]
    px = sliced_box(img["BossBarRim"], e["cut"], long + 2 * e["pad"], BAR_H + 2 * e["pad"])
    b.put(tinted(px, RIM_TINT, RIM_ALPHA), cx0 - e["pad"], cy0 - e["pad"])
    for name, x in (("BossBarMark", cx0 + long * 0.5), ("BossBarCap", cx0), ("BossBarCap", cx1)):
        e = data[name]
        px = img[name]
        b.put(tinted(px, RIM_TINT, RIM_ALPHA), x - px.shape[1] / K / 2, (cy0 + cy1) / 2 - px.shape[0] / K / 2)
    b.text(cx1 - 9.0, (cy0 + cy1) / 2, 14, "12,767/15,457", IVORY, align="RIGHT", bold=0.12 * K)
    return b.done()


def sliced_box(px, cut, w_pts, h_pts):
    """A 9-slice to w by h points: its corners kept, its edges and middle stretched (nearest)."""
    l, t_, r, bt = (round(v * K) for v in cut)
    want_w, want_h = round(w_pts * K), round(h_pts * K)

    def axis(n, a, b_, want):
        mid = np.arange(a, n - b_)
        m = max(want - a - b_, 1)
        return np.concatenate([np.arange(a), mid[np.minimum((np.arange(m) * len(mid) / m).astype(int), len(mid) - 1)],
                               np.arange(n - b_, n)])

    ys = axis(px.shape[0], t_, bt, want_h)
    xs = axis(px.shape[1], l, r, want_w)
    return px[ys][:, xs]


def elite_card(data, img, lead, ground, elite=True, share=0.62):
    """The target card as UI.TargetCard lays it, plain or the elite's. Text in Blender's face stands in for the game's."""
    m = 12.0
    geo = elite_geometry() if elite else json.loads((LEAD / "lead_card.json").read_text(encoding="utf-8"))["geometry"]["target"]
    tw, th = geo["size"]
    b = Board(tw + 2 * m, 46.0 + 2 * m, GROUNDS[ground])

    def put(px, x, y):
        b.put(px, x + m, y + m)

    hx0, hy0, hx1, hy1 = geo["housing"]
    names = ("CardTargetEliteHousing", "CardTargetEliteHousingRim") if elite else ("CardTargetHousing", "CardTargetHousingRim")
    source = img if elite else lead
    for name in names:
        e = source[name + ".e"]
        px = sliced(source[name], e["cut"], hx1 - hx0 + 2 * e["pad"])
        put(tinted(px, TRIM) if name.endswith("Rim") else px, hx0 - e["pad"], hy0 - e["pad"])
    if elite:
        e = img["CardTargetEliteFrame.e"]
        fx, fy = e["at"]
        width = (max(END, etab_pts()[1][0]) - lc.left(E_Y1)) + 2 * e["pad"]
        put(tinted(sliced(img["CardTargetEliteFrame"], e["cut"], width), FRAME_TINT), fx + DX - e["pad"], fy + DY - e["pad"])
    xl, y0, xr, h = geo["health"]
    lname = "CardLightHealthElite" if elite else "CardLightHealth"
    e = source[lname + ".e"]
    front = geo["fillFrom"] + (xr - geo["fillFrom"]) * share
    width = max(front - xl + h * lc.SLANT + lc.GLOW, e["cut"][0] + e["cut"][2])
    put(sliced(source[lname], e["cut"], width), xl - h * lc.SLANT, y0)
    et = lead["CardTab.e"]
    text_w = 52.0 + 5.0 + 26.0  # "Brawler", the gap, "Lv 12"
    tab_w = (lc.T_NAME_X - lc.left(lc.TAB_TOP)) + text_w + lc.T_TAB_AFTER
    for name in ("CardTab", "CardTabRim"):
        px = sliced(lead[name], et["cut"], tab_w + (lc.TAB_FOOT - lc.TAB_TOP) * lc.SLANT + 2 * et["pad"])
        put(tinted(px, TRIM) if name.endswith("Rim") else px, et["at"][0] + DX - et["pad"], et["at"][1] + DY - et["pad"])
    if elite:
        for name in ("CardTargetEliteTab", "CardTargetEliteTabRim"):
            e = img[name + ".e"]
            px = img[name]
            put(tinted(px, TRIM) if name.endswith("Rim") else px, e["at"][0] + DX - e["pad"], e["at"][1] + DY - e["pad"])
    sx, sy = geo["stud"]
    well = np.hypot(b.t.x - sx - m, b.t.y - sy - m) - 6.5
    b.t.paint(well, c("#000000"))
    b.t.line(well, 1.5, c(TRIM))
    gem = lead.get("GemStrength")
    if gem is not None:
        put(resize(gem, 11.0), sx - 5.5, sy - 5.5)
    tab_mid = (lc.TAB_TOP + lc.Y0) / 2 + DY
    b.text(m + 72 + DX, m + tab_mid, 14, "Brawler", IVORY, bold=0.25 * K)
    b.text(m + 72 + DX + 52 + 5, m + tab_mid, 14, "Lv 12", GOLD)
    if elite:
        wx, wy = geo["word"]
        b.text(m + wx, m + wy, 14, "Elite", IVORY, align="CENTER", bold=0.25 * K)
    b.text(m + (xl + xr) / 2, m + y0 + h / 2, 14, "1,240/2,000", IVORY, align="CENTER", bold=0.12 * K)
    return b.done()


def stack(rows, gap=8, ground="#0B0C10"):
    w = max(r.shape[1] for r in rows)
    out = rs.canvas(w, sum(r.shape[0] for r in rows) + gap * (len(rows) - 1), tuple(c(ground)))
    y = 0
    for r in rows:
        rs.paste(out, r, 0, y)
        y += r.shape[0] + gap
    return out


def side(cols, gap=8, ground="#0B0C10"):
    h = max(r.shape[0] for r in cols)
    out = rs.canvas(sum(r.shape[1] for r in cols) + gap * (len(cols) - 1), h, tuple(c(ground)))
    x = 0
    for r in cols:
        rs.paste(out, r, x, 0)
        x += r.shape[1] + gap
    return out


def sheet(out: Path):
    data = json.loads((out / "boss.json").read_text(encoding="utf-8"))["images"]
    img = {n: rs.load(out / e["file"]) for n, e in data.items()}
    img.update({n + ".e": e for n, e in data.items()})
    ldata = json.loads((LEAD / "lead_card.json").read_text(encoding="utf-8"))["images"]
    lead = {n: rs.load(LEAD / ldata[n]["file"]) for n in ("CardTargetHousing", "CardTargetHousingRim", "CardLightHealth", "CardTab", "CardTabRim")}
    lead.update({n + ".e": ldata[n] for n in ("CardTargetHousing", "CardTargetHousingRim", "CardLightHealth", "CardTab", "CardTabRim")})
    for gem, into in (("GemIntelligence", img), ("GemStrength", lead)):
        if (KIT / f"{gem}.png").exists():
            into[gem] = rs.load(KIT / f"{gem}.png")
    keepers = {g: keeper(data, img, g) for g in GROUNDS}
    plains = {g: elite_card(data, img, lead, g, elite=False) for g in GROUNDS}
    elites = {g: elite_card(data, img, lead, g) for g in GROUNDS}
    rows = []
    for f in (2, 4):  # 2 and 1 pixels a point
        rows.append(side([shrink(keepers[g], f) for g in GROUNDS]))
        rows.append(side([stack([shrink(plains[g], f), shrink(elites[g], f)], gap=4) for g in GROUNDS]))
    rs.save(stack(rows, gap=16), out / "boss_sheet.png")
    zoom = side([keepers["floor"][:, keepers["floor"].shape[1] - round(150 * K):], elites["floor"][:, elites["floor"].shape[1] - round(110 * K):]])
    rs.save(zoom, out / "boss_sheet_zoom.png")
    print(f"wrote {out / 'boss_sheet.png'}")


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
