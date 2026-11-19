"""AR49, Home's panel: three cards with their own art (Modulo, 2026-11-19). C, the stage, research's pick (23:54),
cut for Faber.

Research's ask, on the director's word of 23:20 ("MAKE IT LOOOK GOOD"): three cards with their own art replace AR43's
eight lilac buttons. The blockout's three compositions (A the row, B the stack, C the stage) are in 230d739; research
picked C: Voidkin in the middle over Home's tile, the lead's head rising over the frame as on the lead's card,
Equipment at its left, Settings at its right.

Research's must-fixes on the pick:
    1  the lead is the brightest thing on every rarity: a dark ground, the rarity's light as a back glow and a rim,
       the forge's glow a step down;
    2  Equipment shows our own jewel crystal set in the guard and one of our own emblem icons, not a crown badge;
    3  no Quest guide: Settings fills its column as a tall card for now;
    4  every label checked in every state.

The lead is a live view for the build, a ViewportFrame of the lead's own model in its idle, lit from behind in its
rarity's light (the rim). That works for every Voidkin with no art for each one. Here Rook rendered waist up in his
portrait's pose and light stands in for it, with a drawn rim.

The panel sits over the world dimmed to 0.6 with the dock left lit (Home's tile is its root). It is clear of the
lead's card and above the dock, and it fits the smallest phone (568 x 320). Taps 44 points or more, words 14 or
more. The world is Faber's phone still of a fight (home_panel's FIGHT).

The cut: each piece an image at 4 pixels a point, edge alpha 0, laid by home_cards.json in the panel's points. The
words are TextLabels. The sheet is built from those images, as Faber lays them.

    blender -b --factory-startup --python tools/blender/home_cards.py -- <abs out> lead   (Rook waist up, first)
    blender -b --factory-startup --python tools/blender/home_cards.py -- <abs out> cut    (the images, the json,
                                                                                          home_cards_cut.png)
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import foe_cards as fc  # noqa: E402
import home_panel as hp  # noqa: E402
import lead_card_art as lca  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402

K = 4                                               # the cut's pixels a point, the kit's
SHEET_K = hp.K                                      # the sheet's, 2
REPO = fc.REPO
UI = REPO / "build" / "handoff" / "UI"
HANDOFF = UI / "home_cards"
LEAN = hp.LEAN                                      # the dock's lean, 0.2 across per down
PANEL = (371.0, 184.0)                              # the glass: wide, high
PAD = 8.0
LEAD_RIGHT = {"game": 247.0, "small": 183.0}        # the lead's card's right edge, its equipment slot under it
DOCK_GAP = 9.0
DIM = 0.6                                           # the world under Home: the HUD's corner pieces recede with it
RISE = 14.0                                         # the lead's hair over the card's top
TOP, FOOT = PAD, PANEL[1] - PAD                     # every card's top and foot
CARDS = {"Equipment": (0.0, 96.0), "Voidkin": (104.0, 238.0), "Settings": (246.0, 321.0)}   # each foot's x
PIECE_PAD = 10.0                                    # a card's image past its outline, for its shadow
GLASS_PAD = 16.0
GLASS_ALPHA = 1.0                                   # opaque, so the live view's frame matches it exactly
IVORY = "#F5EFE2"
EM = 0.46                                           # the face's mean width a letter, in its size
EMBLEM = 28.0                                       # Equipment's emblem socket
MAT = {
    "Voidkin": dict(body=("#1C2234", "#040509"), glint="#CFDBFF"),
    "Equipment": dict(body=("#36230F", "#090503"), light="#FF8A3D", rim="#D9A85B", glint="#FFE2B0"),
    "Settings": dict(body=("#3B424C", "#121519"), light="#AEB7C2", rim="#8F99A6", glint="#E2E8EF"),
}
TRIM = lca.TRIM


def light_of(rarity):
    """Home's light for a rarity: Config.Hud.Card.Trim lifted a step toward white, so Common's grey still lights."""
    v = ui.c(TRIM[rarity]) * 0.6 + 0.4
    return "#" + "".join(f"{round(float(x) * 255):02X}" for x in v)


LEAD_PNG = "_lead_Rook.png"
LEAD_SPAN, LEAD_CENTRE_Z, LEAD_SIZE = 6.0, 3.5, (600, 700)   # the render: studs across, its middle, pixels
LEAD_BELT = 515                                     # the belt's row in the render (read off it)


# --- the lead, waist up ---------------------------------------------------------------------------------------------

def lead(out):
    """Rook waist up in his portrait's pose and light (hud_art's shoot_portrait with a wider frame)."""
    import hud_art as ha
    p = ha.PORTRAITS["Rook"]
    p["centre"], p["span"] = (p["centre"][0], p["centre"][1], LEAD_CENTRE_Z), LEAD_SPAN
    shot = ha.shoot_portrait("Rook", out, size=LEAD_SIZE)
    rs.save(shot, out / LEAD_PNG)
    print(f"wrote {out / LEAD_PNG} {shot.shape[1]}x{shot.shape[0]}")


def lead_top(px):
    """The hair's top row in the render."""
    return int(np.argmax(px[..., 3].max(axis=1) > 0.5))


# --- the geometry, in the panel's points ----------------------------------------------------------------------------

def at(fx, y):
    """A card's side at height y: its foot's x, leaning LEAN right per point up."""
    return PAD + fx + LEAN * (FOOT - y)


def card_pts(name, cut=7.0):
    fx0, fx1 = CARDS[name]
    y0, y1 = TOP, FOOT
    if name == "Settings":
        cut = 5.0
    return [(at(fx0, y0 + cut), y0 + cut), (at(fx0, y0) + cut, y0), (at(fx1, y0), y0), (at(fx1, y1 - cut), y1 - cut),
            (at(fx1, y1) - cut, y1), (at(fx0, y1), y1)]


def card_box(name):
    """The card's outline's box: left at its foot, right at its top."""
    fx0, fx1 = CARDS[name]
    return at(fx0, FOOT), TOP, at(fx1, TOP), FOOT


def padded(box, pad):
    x0, y0, x1, y1 = box
    return x0 - pad, y0 - pad, x1 + pad, y1 + pad


def middle(name, y):
    fx0, fx1 = CARDS[name]
    return (at(fx0, y) + at(fx1, y)) / 2


def viewport_box():
    """The live view's frame: the Voidkin card's box, reaching RISE and 10 more over its top for the hair."""
    x0, y0, x1, y1 = card_box("Voidkin")
    return x0, y0 - RISE - 10, x1, y1


def ring_of():
    """Equipment's ring: its middle and its size."""
    fx0, fx1 = CARDS["Equipment"]
    size = word_size("Equipment", fx1 - fx0, 20)
    room = (FOOT - TOP) - size - 14
    ring = min((fx1 - fx0) * 0.86, room * 0.9)
    ry = TOP + 4 + room * 0.5
    return middle("Equipment", ry), ry, ring


def word_size(text, width, most):
    return max(14.0, min(most, (width - 22) / (EM * len(text))))


# --- drawing --------------------------------------------------------------------------------------------------------

def cover(d):
    return np.clip(0.5 - d * ui.K, 0, 1)


def outside(d):
    return np.clip(0.5 + d * ui.K, 0, 1)


def col(colour):
    return ui.c(colour) if isinstance(colour, str) else np.asarray(colour, dtype=np.float32)


def image(path, width_pt, tint=None, alpha=1.0):
    """An image `width_pt` points wide at the current pixels a point, tinted (its light multiplied) and faded."""
    px = rs.load(path) if isinstance(path, Path) else path
    f = width_pt * ui.K / px.shape[1]
    im = (rs.shrink(px, f) if f < 1 else fc.scaled(px, f)).copy()
    if tint is not None:
        im[..., :3] *= ui.c(tint)
    im[..., 3] *= alpha
    return im


def lay(t, img, x, y, d=None):
    """An image with its top left at (x, y) panel points onto a piece's tile."""
    t.image(img, x - t.org[0], y - t.org[1], d)


def radial(t, d, cx, cy, rx, ry, colour, strength):
    r2 = ((t.x - cx) / rx) ** 2 + ((t.y - cy) / ry) ** 2
    ui.over(t.px, col(colour), strength * np.exp(-r2) * cover(d))


def shadow(t, d, radius, strength, pad):
    """A soft shadow round a shape, gone before its image's edge (AR45's lesson)."""
    ui.over(t.px, ui.BLACK, strength * np.exp(-(np.maximum(d, 0) / radius) ** 1.4) * outside(d) * lca.fade(d, pad))


def binding(t, d, y0, y1, glint, foot=0.32, edge=0.45, head=False):
    """What binds a card's art into its frame: a shade in from the edge, a dark rising at the foot under the word, the
    lacquer's line under the top edge. Under a head that rises over the top (`head`), no lacquer and no shade at the
    top, so the head stands in front of the frame."""
    inside = cover(d)
    shade = np.exp(np.minimum(d, 0) / 7.0)
    if head:
        shade = shade * np.clip((t.y - y0) / 24.0, 0, 1)
    ui.over(t.px, ui.BLACK, edge * shade * inside)
    h = (y1 - y0) * foot
    v = np.clip((t.y - (y1 - h)) / h, 0, 1)
    ui.over(t.px, ui.c("#05060A"), 0.82 * v * v * (3 - 2 * v) * inside)
    if not head:
        ui.over(t.px, col(glint), cover(np.maximum(d, np.abs(t.y - (y0 + 2.2)) - 1.0)) * 0.28)


def press(t, d, pad):
    """The kit's lit press, white for the game to tint: a wash in, a glow out, the rim lit."""
    ui.over(t.px, ui.WHITE, 0.16 * cover(d))
    ui.over(t.px, ui.WHITE, 0.6 * np.exp(-(np.maximum(d, 0) / 5.0) ** 1.4) * outside(d) * lca.fade(d, pad))
    t.line(d, 2.0, ui.WHITE)


def glass_fill(t, region, alpha):
    """The dark glass: falling darker, a faint diagonal sheen. In the panel's points, so a piece matches the panel."""
    ui.over(t.px, t.ramp("#1A2131", "#07090E", t.y / PANEL[1]), cover(region) * alpha)
    band = np.exp(-((t.x - t.y * 1.6 - PANEL[0] * 0.18) / 46.0) ** 2)
    ui.over(t.px, ui.c("#A9C1E8"), 0.05 * band * cover(region) * alpha)


# --- the pieces: each draws on a tile measured in the panel's points ------------------------------------------------

def glass(t):
    d = t.poly(ui.cut_box(0, 0, PANEL[0], PANEL[1], 12, 0, 12, 0))
    shadow(t, d, 10.0, 0.55, GLASS_PAD)
    glass_fill(t, d, GLASS_ALPHA)
    t.line(d, 1.0, ui.c("#2E3749"), 0.95)
    ui.over(t.px, ui.c("#CFDBFF"), cover(np.maximum(d, np.abs(t.y - 1.6) - 0.7)) * 0.3)


POINTER = (20.0, 8.0)                               # its foot's width, its depth below the glass


def pointer(t):
    """The point down at Home's tile, its middle at x = 0, its top 1 point inside the glass's foot."""
    w, h = POINTER
    d = t.poly([(-w / 2, PANEL[1] - 1.0), (w / 2, PANEL[1] - 1.0), (0, PANEL[1] + h)])
    glass_fill(t, d, GLASS_ALPHA)
    sides = np.minimum(ui.sd_segment(t.x, t.y, (-w / 2, PANEL[1]), (0, PANEL[1] + h)),
                       ui.sd_segment(t.x, t.y, (w / 2, PANEL[1]), (0, PANEL[1] + h)))
    ui.over(t.px, ui.c("#2E3749"), cover(sides - 0.5) * 0.95)


def voidkin_back(t):
    d = t.poly(card_pts("Voidkin"))
    shadow(t, d, 7.0, 0.6, PIECE_PAD)
    t.paint(d, t.ramp(MAT["Voidkin"]["body"][0], MAT["Voidkin"]["body"][1], (t.y - TOP) / (FOOT - TOP)))


def voidkin_glow(t):
    """The rarity's back glow, white for the game to tint: behind the head and shoulders, the foot left dark."""
    d = t.poly(card_pts("Voidkin"))
    fx0, fx1 = CARDS["Voidkin"]
    wide, high = fx1 - fx0, FOOT - TOP
    cx = middle("Voidkin", TOP + high * 0.3)
    radial(t, d, cx + wide * 0.05, TOP + high * 0.28, wide * 0.5, high * 0.42, "#FFFFFF", 0.5)
    radial(t, d, cx + wide * 0.05, TOP + high * 0.2, wide * 0.24, high * 0.2, "#FFFFFF", 0.3)


def voidkin_frame(t):
    """Over the live view: the glass again where the view's box spills past the card's slanted sides, then the
    binding. The Equipment and Settings cards are laid after it, over its corners."""
    d = t.poly(card_pts("Voidkin"))
    x0, y0, x1, y1 = viewport_box()
    box = t.poly([(x0, TOP), (x1, TOP), (x1, y1), (x0, y1)])
    corners = np.maximum(box, -d)
    glass_fill(t, corners, 1.0)
    ui.over(t.px, ui.BLACK, 0.6 * np.exp(-(np.maximum(d, 0) / 7.0) ** 1.4) * outside(d) * lca.fade(d, PIECE_PAD)
            * cover(corners))                       # the card's shadow again, where the corners hid it
    binding(t, d, TOP, FOOT, MAT["Voidkin"]["glint"], foot=0.3, edge=0.38, head=True)


RIM_SPLIT = TOP + 1.6                               # the rim's top edge (under the live view) from the rest (over it)


def voidkin_rim_top(t):
    """The rim's top edge, white, under the live view: the head rises in front of it."""
    t.paint(np.maximum(np.abs(t.poly(card_pts("Voidkin")) + 0.6) - 0.6, t.y - RIM_SPLIT), ui.WHITE, 0.95)


def voidkin_rim(t):
    """The rim's sides and foot, white, over the live view."""
    t.paint(np.maximum(np.abs(t.poly(card_pts("Voidkin")) + 0.6) - 0.6, RIM_SPLIT - t.y), ui.WHITE, 0.95)


def equipment(t, art):
    d = t.poly(card_pts("Equipment"))
    m = MAT["Equipment"]
    shadow(t, d, 7.0, 0.6, PIECE_PAD)
    t.paint(d, t.ramp(m["body"][0], m["body"][1], (t.y - TOP) / (FOOT - TOP)))
    rx, ry, ring = ring_of()
    # the forge's light, a step under the lead's: a warm core in the ring falling off to dark bronze, a few embers
    radial(t, d, rx, ry, ring * 0.48, ring * 0.48, "#FF5E14", 0.4)
    radial(t, d, rx, ry, ring * 0.2, ring * 0.2, "#FFC27A", 0.3)
    rng = np.random.default_rng(7)
    for _ in range(14):
        a = rng.uniform(0, 2 * np.pi)
        r = ring * rng.uniform(0.3, 0.75)
        ex, ey = rx + np.cos(a) * r * 0.8, ry + np.sin(a) * r - ring * rng.uniform(0.0, 0.25)
        dot = np.hypot(t.x - ex, (t.y - ey) * 0.7) - rng.uniform(0.6, 1.4)
        ui.over(t.px, ui.c("#FFC27A" if rng.random() < 0.5 else "#FF8A3D"),
                cover(np.maximum(dot, d)) * rng.uniform(0.35, 0.8))
    lay(t, image(art["ring"], ring, "#E9B970", 0.95), rx - ring / 2, ry - ring / 2, d + 1.2)
    bw = ring * 1.24
    bx, by = rx - bw / 2, ry - bw / 2
    lay(t, image(art["blade"], bw, "#FFF0DC"), bx, by, d + 1.2)
    # the jewel set in the guard, a seat of dark under it
    jw = bw * 0.24
    jx, jy = bx + 0.29 * bw, by + 0.70 * bw
    ui.over(t.px, ui.c("#120A06"), cover(np.maximum(np.hypot(t.x - jx, t.y - jy) - jw * 0.42, d)) * 0.7)
    lay(t, image(art["jewel"], jw), jx - jw / 2, jy - jw / 2 - jw * 0.04, d + 1.2)
    # the emblem in the kit's socket on the ring's foot right, set over the ring
    s = EMBLEM
    ex, ey = rx + ring * 0.26, ry + ring * 0.3
    sx, sy = ex - s / 2, ey - s / 2
    lay(t, image(art["socket"], s), sx, sy, d + 1.2)
    lay(t, image(art["edge"], s, "#E9B970"), sx, sy, d + 1.2)
    lay(t, image(art["emblem"], s * 0.92), sx + s * 0.04, sy + s * 0.04, d + 1.2)
    binding(t, d, TOP, FOOT, m["glint"])
    t.line(d, 1.2, ui.c(m["rim"]), 0.95)


def settings(t):
    d = t.poly(card_pts("Settings"))
    m = MAT["Settings"]
    shadow(t, d, 6.0, 0.55, PIECE_PAD)
    t.paint(d, t.ramp(m["body"][0], m["body"][1], (t.y - TOP) / (FOOT - TOP)))
    cx, cy, s = cog_of()
    radial(t, d, cx, cy, s * 1.1, s * 1.1, m["light"], 0.2)
    binding(t, d, TOP, FOOT, m["glint"], foot=0.3)
    t.line(d, 1.2, ui.c(m["rim"]), 0.95)


def cog_of():
    """Settings' cog: its middle and its size, a little over the card's middle."""
    cy = TOP + (FOOT - TOP) * 0.42
    return middle("Settings", cy), cy, 30.0


def card_press(name):
    return lambda t: press(t, t.poly(card_pts(name)), PIECE_PAD)


# The pieces, bottom to top: name, its box in the panel's points, how it's drawn, its tint, what it is.
def pieces(art):
    vb = padded(card_box("Voidkin"), PIECE_PAD)
    eb = padded(card_box("Equipment"), PIECE_PAD)
    sb = padded(card_box("Settings"), PIECE_PAD)
    w, h = POINTER
    return [
        ("HomeGlass", padded((0, 0, PANEL[0], PANEL[1]), GLASS_PAD), glass, None,
         "the panel's dark glass, its shadow faded inside its pad"),
        ("HomePointer", (-w / 2 - 2, PANEL[1] - 3, w / 2 + 2, PANEL[1] + h + 2), pointer, None,
         "the point down at Home's tile, its box's middle on the tile's middle"),
        ("HomeVoidkinBack", vb, voidkin_back, None, "the Voidkin card's dark ground and its shadow"),
        ("HomeVoidkinGlow", vb, voidkin_glow, "light", "the rarity's back glow, white: ImageColor3 the lead's light"),
        ("HomeVoidkinRimTop", vb, voidkin_rim_top, "light",
         "the rim's top edge, white, under the live view so the head rises in front of it: ImageColor3 the lead's "
         "light"),
        ("HomeVoidkinFrame", vb, voidkin_frame, None,
         "over the live view: the glass where the view's box spills past the card's sides, the shade in from the "
         "sides, the dark at the foot"),
        ("HomeVoidkinRim", vb, voidkin_rim, "light",
         "the rim's sides and foot, white, over the live view: ImageColor3 the lead's light"),
        ("HomeEquipment", eb, lambda t: equipment(t, art), None,
         "the Equipment card whole: the forge, the ring, the blade, the jewel, the emblem, the binding, the rim"),
        ("HomeSettings", sb, settings, None, "the Settings card, its cog the kit's HomeMarkSettings over it"),
        ("HomeVoidkinPress", vb, card_press("Voidkin"), "light", "the press, white: ImageColor3 the lead's light"),
        ("HomeEquipmentPress", eb, card_press("Equipment"), MAT["Equipment"]["light"],
         "the press, white: ImageColor3 the forge's #FF8A3D"),
        ("HomeSettingsPress", sb, card_press("Settings"), MAT["Settings"]["light"],
         "the press, white: ImageColor3 the steel's #AEB7C2"),
    ]


def cut_piece(box, draw):
    """One piece alone at 4 pixels a point on transparency, its tile measured in the panel's points."""
    x0, y0, x1, y1 = box
    ui.K = K
    sheet = ui.Sheet(x1 - x0, y1 - y0, "#000000")
    sheet.px[:] = 0
    t = sheet.tile(0, 0, x1 - x0, y1 - y0)
    t.x += x0
    t.y += y0
    t.org = (x0, y0)
    draw(t)
    return sheet.px


def edge_alpha(px):
    a = px[..., 3]
    return float(max(a[0].max(), a[-1].max(), a[:, 0].max(), a[:, -1].max()))


# --- the words, as Faber's TextLabels -------------------------------------------------------------------------------

def words():
    """Each label: its text, its capitals' top left (panel points), its size, colour, and a soft dark under it."""
    out = []
    for name, most in (("Equipment", 20), ("Voidkin", 22)):
        fx0, fx1 = CARDS[name]
        size = round(word_size(name, fx1 - fx0, most), 1)
        out.append(dict(text=name, x=round(at(fx0, FOOT - 10) + 10, 1), y=round(FOOT - 10 - size * 0.72, 1),
                        size=size, colour=IVORY, align="LEFT"))
    size = 14.0
    out.append(dict(text="Settings", x=round(middle("Settings", FOOT - 9), 1), y=round(FOOT - 9 - size * 0.72, 1),
                    size=size, colour=IVORY, align="CENTER"))
    rx, ry, ring = ring_of()
    plus = round(max(16.0, ring * 0.2), 1)
    out.append(dict(text="+7", x=round(rx - ring * 0.36, 1), y=round(ry - ring * 0.56, 1), size=plus,
                    colour="#FFD36B", align="LEFT", bold=0.45))
    return out


def text_items(ox, oy):
    items = []
    for w in words():
        for dx, dy, code, layer in ((0.8, 1.2, "#000000", "a_shade"), (0, 0, w["colour"], "plain")):
            items.append(dict(x=ox + w["x"] + dx, y=oy + w["y"] + dy, size=w["size"], text=w["text"], colour=code,
                              align=w["align"], layer=layer, shear=LEAN, bold=w.get("bold", 0.3)))
    return items


# --- building it from the cut, as Faber lays it ---------------------------------------------------------------------

def panel_at(w, h, which):
    pw, ph = PANEL
    foot = h - hp.DOCK_UP - DOCK_GAP
    left = max(LEAD_RIGHT[which] + 8, w / 2 - pw / 2)
    return min(left, w - 6 - pw), foot - ph


def stand_in(lead_px, rarity):
    """The live view's stand-in: Rook's render scaled into the view, a rim of the lead's light on his edges where the
    view's light from behind would catch him."""
    x0, y0, x1, y1 = viewport_box()
    head = TOP - RISE
    scale = (FOOT - 6 - head) / (LEAD_BELT - lead_top(lead_px))          # points a render pixel
    fig = image(lead_px, lead_px.shape[1] * scale)
    a = fig[..., 3]
    edge = np.zeros_like(a)
    for dy, dx in ((2, 0), (0, 2), (0, -2)):                             # lit from behind: the top and both sides
        moved = np.roll(np.roll(a, dy, 0), dx, 1)
        edge = np.maximum(edge, a * (1 - moved))
    fig[..., :3] = fig[..., :3] * (1 - edge[..., None] * 0.6) + ui.c(light_of(rarity)) * (edge[..., None] * 0.6)
    fx = middle("Voidkin", (TOP + FOOT) / 2) - fig.shape[1] / ui.K / 2
    fy = head - lead_top(lead_px) * scale
    view = np.zeros((round((y1 - y0) * ui.K), round((x1 - x0) * ui.K), 4), np.float32)   # the view's box clips it
    ox, oy = round((fx - x0) * ui.K), round((fy - y0) * ui.K)
    sy0, sx0 = max(0, -oy), max(0, -ox)
    ty0, tx0 = max(0, oy), max(0, ox)
    hh = min(fig.shape[0] - sy0, view.shape[0] - ty0)
    ww = min(fig.shape[1] - sx0, view.shape[1] - tx0)
    view[ty0:ty0 + hh, tx0:tx0 + ww] = fig[sy0:sy0 + hh, sx0:sx0 + ww]
    return view


def built(world, which, made, lead_px, pressed=None, rarity="Common"):
    """The phone with Home open, laid from the cut's images (each shrunk to the sheet's 2 pixels a point)."""
    w, h = hp.size_of(world)
    px0, py0 = panel_at(w, h, which)
    out = hp.dimmed(world, "B", DIM)
    light = light_of(rarity)
    for name, box, _draw, tint, _use in made["pieces"]:
        if name.endswith("Press") and name != f"Home{pressed}Press":
            continue
        x, y = px0 + box[0], py0 + box[1]
        if name == "HomePointer":
            x = w / 2 + box[0]
        fc.put(out, made["px"][name], x, y, tint=light if tint == "light" else tint)
        if name == "HomeVoidkinRimTop":                                  # the live view, over the rim's top
            ui.K = SHEET_K
            vx, vy = viewport_box()[:2]
            rs.paste(out, stand_in(lead_px, rarity), round((px0 + vx) * SHEET_K), round((py0 + vy) * SHEET_K))
        if name == "HomeSettings":                                       # the kit's cog over its card
            cx, cy, s = cog_of()
            fc.put(out, made["cog"], px0 + cx - s / 2, py0 + cy - s / 2, s / (made["cog"].shape[1] / K), "#C9D0D9")
    ui.K = SHEET_K
    for got in ui.text_layers(out.shape[1], out.shape[0], text_items(px0, py0)).values():
        ui.over(out, got[..., :3], got[..., 3])
    return out


# --- the cut and its sheet ------------------------------------------------------------------------------------------

def lettered(sheet, items, band=360):
    height, width = sheet.shape[:2]
    for top in range(0, height, band):
        got = [(x, y - top, size, text, code) for x, y, size, text, code in items if top <= y < top + band]
        if got:
            rs.paste(sheet, rs.text_layer(width, band + 40, got), 0, top)


def cut(out):
    eq = UI / "equipment" / "images"
    art = dict(ring=rs.load(eq / "ReinforceRing.png"), blade=rs.load(UI / "gear" / "images" / "GearLanternsteelSword.png"),
               jewel=rs.load(UI / "jewels" / "images" / "JewelRed4.png"),
               emblem=rs.load(UI / "emblems" / "images" / "EmblemRadiance.png"),
               socket=rs.load(eq / "SocketFill.png"), edge=rs.load(eq / "SocketEdge.png"))
    images = HANDOFF / "images"
    images.mkdir(parents=True, exist_ok=True)
    made = dict(pieces=pieces(art), px={}, cog=rs.load(UI / "home" / "images" / "HomeMarkSettings.png"))
    record = {}
    for name, box, draw, tint, use in made["pieces"]:
        px = cut_piece(box, draw)
        made["px"][name] = px
        rs.save(px, images / f"{name}.png")
        e = edge_alpha(px)
        print(f"{name:20s} {px.shape[1]}x{px.shape[0]}  edge alpha {e * 255:.1f}")
        assert e * 255 < 1.0, f"{name} has alpha at its edge"
        record[name] = dict(box=[round(v, 2) for v in (box[0], box[1], box[2] - box[0], box[3] - box[1])],
                            tint=("the lead's light" if tint == "light" else tint), use=use)
    rx, ry, ring = ring_of()
    cx, cy, s = cog_of()
    vx0, vy0, vx1, vy1 = viewport_box()
    (HANDOFF / "home_cards.json").write_text(json.dumps(dict(
        take="AR49, C the stage: research's pick (2026-11-19, 23:54) with its four must-fixes",
        units="points; every box is left, top, width, height from the glass's top left; images at 4 pixels a point",
        panel=dict(size=list(PANEL), place="its left max(the lead's card's right + 8, the phone's middle - half its "
                                           "width), and never past the phone's right less 6; its foot 9 over the "
                                           "dock's top", dim=DIM,
                   dimNote="the world under Home dims to 0.6 toward #05090B, the dock left lit; the HUD's corner "
                           "pieces fade with it (the glass would cut the pills mid-word)"),
        order="bottom to top as `images` lists them; a press image shows only while its card is held",
        images=record,
        liveView=dict(box=[round(v, 2) for v in (vx0, vy0, vx1 - vx0, vy1 - vy0)],
                      laid="between HomeVoidkinRimTop and HomeVoidkinFrame; BackgroundTransparency 1",
                      framing=f"the lead's own model in its idle, waist up: its hair's top {RISE:g} points over the "
                              f"card's top ({TOP - RISE:g}), its belt 6 over the card's foot, its head on the card's "
                              "middle; turned 34 degrees to its right, the head brought back 22 (the portrait's pose)",
                      light="LightColor the lead's light, LightDirection from behind and above (the rim); Ambient "
                            "#B4B8C2 so the face stays the brightest thing on the card"),
        lights={r: light_of(r) for r in lca.RARITIES},
        lightsNote="the lead's light: Config.Hud.Card.Trim lifted 40% toward white, so Common's grey still lights",
        cog=dict(image="HomeMarkSettings (AR43's, in build/handoff/UI/home/images)", centre=[round(cx, 2), round(cy, 2)],
                 size=s, colour="#C9D0D9", laid="over HomeSettings"),
        words=words(),
        wordsNote="TextLabels in the kit's face, bold and italic (leaning with the cards); x, y their capitals' top "
                  "left (Settings' its middle); a soft dark copy under each, 0.8 right and 1.2 down, at #000000",
        ring=dict(centre=[round(rx, 2), round(ry, 2)], size=round(ring, 2),
                  note="Equipment's art is one image; +7 is a label, for the build to keep or bind"),
        press="the kit's lit press: the card's press image shown while held, with the dock's squeeze",
        sheet="build/handoff/UI/home_cards/home_cards_cut.png",
    ), indent=1), encoding="utf-8")

    lead_px = rs.load(out / LEAD_PNG)
    world = hp.worlds()
    game, small = world["game"], world["small"]
    gh, gw = game.shape[:2]
    margin, gap, head = 24, 16, 60
    # the panel's own crops for the presses: the panel and its rise, at 2 pixels a point
    gx0, gy0 = panel_at(gw / SHEET_K, gh / SHEET_K, "game")
    crop = (round((gx0 - 14) * SHEET_K), round((gy0 - 30) * SHEET_K), round((gx0 + PANEL[0] + 14) * SHEET_K),
            round((gy0 + PANEL[1] + 14) * SHEET_K))
    cw_, ch_ = crop[2] - crop[0], crop[3] - crop[1]
    width = margin * 2 + gw + gap + small.shape[1] // 2
    width = max(width, margin * 2 + 3 * (cw_ + gap))
    strip_h = 230
    vb = padded(card_box("Voidkin"), PIECE_PAD)
    rw = round((vb[2] - vb[0]) * SHEET_K)
    rh = round((vb[3] - vb[1] + RISE + 10) * SHEET_K)
    height = 120 + head + strip_h + head + gh + head + ch_ + head + rh + 40
    page = rs.canvas(width, height, tuple(rs.rgb("#101117")))
    text = [(margin, 22, 34, "AR49, Home's panel, C the stage: the cut, built from its images as Faber lays them",
             "#EDE6D6"),
            (margin, 74, 20, "Research's must-fixes in: the lead brightest on every rarity (dark ground, back glow, "
                             "rim), our own jewel in the guard and our emblem in its socket, Settings a tall card, "
                             "every label in every state.", "#A9A398")]
    y = 120
    text.append((margin, y + 12, 24, "The images (4 pixels a point, shown at 1), each on the panel's dark, edge alpha 0",
                 "#EDE6D6"))
    x = margin
    for name, _box, _d, tint, _u in made["pieces"]:
        px = made["px"][name]
        im = rs.shrink(px, 0.25).copy()
        if tint is not None:
            im[..., :3] *= ui.c(light_of("Legendary") if tint == "light" else tint)
        if x + im.shape[1] > width - margin:
            break
        tile = rs.canvas(max(im.shape[1] + 8, 70), strip_h - 30, tuple(rs.rgb("#0B0D12")))
        rs.paste(tile, im, 4, 4)
        rs.paste(page, tile, x, y + head)
        text.append((x, y + head + strip_h - 24, 13, name.replace("Home", ""), "#A9A398"))
        x += tile.shape[1] + 10
    y += head + strip_h
    text.append((margin, y + 12, 24, "At rest in the fight capture (2 pixels a point), and the smallest phone at its own "
                                     "size", "#EDE6D6"))
    rest = built(game, "game", made, lead_px)
    rs.paste(page, rest, margin, y + head)
    del rest
    tiny = built(small, "small", made, lead_px)
    rs.paste(page, rs.shrink(tiny, 0.5).copy(), margin + gw + gap, y + head)
    del tiny
    y += head + gh
    text.append((margin, y + 12, 24, "Each card pressed, the panel up close", "#EDE6D6"))
    for k, name in enumerate(("Voidkin", "Equipment", "Settings")):
        lit = built(game, "game", made, lead_px, pressed=name)
        rs.paste(page, lit[crop[1]:crop[3], crop[0]:crop[2]].copy(), margin + k * (cw_ + gap), y + head)
        del lit
    y += head + ch_
    text.append((margin, y + 12, 24, "The Voidkin card on each rarity's light (Config.Hud.Card.Trim lifted toward white)",
                 "#EDE6D6"))
    dark = np.zeros_like(game)
    dark[..., :3], dark[..., 3] = ui.c("#0B0D12"), 1.0
    vx = round((gx0 + vb[0]) * SHEET_K)
    vy = round((gy0 + vb[1] - RISE - 10) * SHEET_K)
    for k, rarity in enumerate(lca.RARITIES):
        one = built(dark, "game", made, lead_px, rarity=rarity)
        rs.paste(page, one[vy:vy + rh, vx:vx + rw].copy(), margin + k * (rw + gap), y + head)
        text.append((margin + k * (rw + gap), y + head + rh + 4, 14, rarity, "#A9A398"))
        del one
    lettered(page, text)
    rs.save(page, HANDOFF / "home_cards_cut.png")
    print(f"wrote {HANDOFF / 'home_cards_cut.png'} {width}x{height}")


def main():
    out = bl.out_dir()
    rs.OUT = out                                    # rook_sheet's lettering writes its passes there
    if sys.argv[-1] == "lead":
        lead(out)
    else:
        cut(out)


if __name__ == "__main__":
    main()
