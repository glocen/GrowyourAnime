"""The mobile inventory, in three directions, before anything is built: research's order of 2026-11-16, from the
director's package (item 4, and "UI Art Direction"; the words are in docs/archive/director-package-2026-11-16.md).
Mockups, not finished art. Each direction is drawn in three states at a phone's size in landscape (812 x 375 points, 2
pixels a point), with its own palette and composition:

  1. Rook, a Warrior, with a full bag: a Legendary with a 24-character name chosen, set against what he holds.
  2. Lyric, a Healer, in the same preset: a Warrior's sword chosen, which she can't wield; her own hands stand empty.
  3. A new account: an empty bag.

  A, Lacquer: the ledger. Warm black lacquer, brass hairlines, bone words. Three columns, always on.
  B, Nocturne: the ring. Cold slate night, silver and ice. The Voidkin stands in a ring of its fourteen slots.
  C, Porcelain: the case. Pale porcelain and ink, the items in dark inlays. The slots as one belt across the top.

Every shape is drawn here, as a distance from its outline. The gear is AR6's batch 1 as delivered; the figures are
Rook's and Lyric's own models; the rail's marks and Combat Power's emblem are TR17's delivered marks. Text is Blender's
face standing in for the game's. Numbers are stand-ins until research's simulation of the Basic Attributes.

    blender -b --factory-startup --python tools/blender/inventory_directions.py -- build/handoff/UI/inventory
"""
import json
import math
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_kit as kit  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
GEAR_ART = REPO / "build" / "handoff" / "UI" / "gear"
MARKS_ART = REPO / "build" / "handoff" / "UI" / "voidkin" / "marks"
PORTRAITS = REPO / "build" / "handoff" / "UI" / "hud" / "images"
MODELS = REPO / "build" / "scratch" / "modulo"

K = 2
ui.K = K
W, H = 812.0, 375.0
SAFE = (58.0, 56.0, 758.0, 375.0)  # measured on Faber's iPhone capture, 2026-11-14; Roblox's bar stands left of x 222

RARITY = {"Common": "#9AA0AC", "Uncommon": "#7CF0A0", "Rare": "#6FB6FF", "Epic": "#D29CFF", "Legendary": "#FFD777"}
RARITY_DEEP = {"Common": "#5E6470", "Uncommon": "#1C9A52", "Rare": "#2D6FD0", "Epic": "#8A45D6", "Legendary": "#A87A12"}
UP, DOWN = "#7CF0A4", "#FF7A66"  # the kit's GOOD and BAD: the server's yes and no, and a number's rise and fall
UP_DEEP, DOWN_DEEP = "#178A4A", "#C8442E"  # the same on porcelain
POWER_GOLD = "#FFD36B"


# --- the content: one account's bag, two Voidkin, one preset ---------------------------------------------------------

def gear_table():
    """Every batch 1 picture by its stem: its name, its rarity and its slot's kind."""
    table = {}
    data = json.loads((GEAR_ART / "gear_icons.json").read_text(encoding="utf-8"))
    hands = {kind: hand for hand, kind in data["hands"]["Warrior"].items()}  # this sheet's weapons are the Warrior's
    for where, designs in data["kinds"].items():
        for d in designs:
            table[Path(d["image"]).stem] = dict(name=d["name"], rarity=d["rarity"],
                                                kind=hands.get(where, where.replace(" I", "")))
    return table


GEAR = gear_table()
WEAPON = ("Main Hand", "Off Hand")
# The bag, best first. Worn: in the preset the shown Voidkin is linked to (an item stays in the bag when it's worn).
BAG = ("GearKiribi", "GearYoiboshi", "GearZansho", "GearTomoshibi", "GearStormcallBlade", "GearGloamforgeHelm",
       "GearStormcallLoop", "GearNightloomLoop", "GearGloamforgeEdge", "GearBladeOfHoarfrost", "GearHelmOfGales",
       "GearBandOfEmbers", "GearEdgeOfEmbers", "GearEdgeOfGales", "GearHelmOfEmbers", "GearRowsmithSword",
       "GearStallguardHelmet", "GearLanternsteelRing", "GearRowsmithShortSword", "GearIronSword", "GearBronzeHelmet",
       "GearScrapRing", "GearBronzeShortSword", "GearIronRing", "GearScrapHelmet")
WORN = {"GearTomoshibi", "GearStormcallBlade", "GearStormcallLoop", "GearEdgeOfEmbers"}
RAISES = {"Rook": {"GearKiribi", "GearYoiboshi", "GearGloamforgeEdge"}, "Lyric": {"GearYoiboshi"}}
SLOTS = ("Helmet", "Shoulders", "Chest Armor", "Gloves", "Bracers", "Boots",
         "Earring I", "Earring II", "Amulet", "Cloak", "Ring I", "Ring II")
PRESET = {"Helmet": "GearTomoshibi", "Ring I": "GearStormcallLoop"}
PAIRS = {"Warrior": {"Main Hand": "GearStormcallBlade", "Off Hand": "GearEdgeOfEmbers"}, "Healer": {}}

ROOK = dict(who="Rook", rarity="Common", cls="Warrior", level=12, power="27,433", blend="rook/model/rook_model.blend")
LYRIC = dict(who="Lyric", rarity="Rare", cls="Healer", level=18, power="15,711", blend="lyric/model/lyric_model.blend")
NEW = dict(ROOK, level=1, power="1,204", new=True)

# The chosen item in each state: what it is, and what the card says.
KIRIBI = dict(stem="GearKiribi", against="GearStormcallBlade", power="+1,238",
              basic=(("Strength", "STR", "82", "+18"), ("Agility", "AGI", "35", "+4"), ("Stamina", "STA", "48", "0"),
                     ("Spirit", "SPI", "20", "-2")),
              battle=(("Attack", "1,412", "+226"), ("Health", "1,561", "+18"), ("Hit", "338", "+26"),
                      ("Critical", "128", "-12")))
HOARFROST = dict(stem="GearBladeOfHoarfrost", lines=(("Attack", "+164"), ("Strength", "+11"), ("Hit", "+18")),
                 why="Lyric is a Healer")
STATES = (("full", ROOK, KIRIBI), ("other class", LYRIC, HOARFROST), ("empty", NEW, None))
CATEGORIES = (("Gear", "25", True), ("Shards", "79", True), ("Emblems", "", False), ("Jewels", "", False),
              ("Stones", "", False))
PAGES = ("PageOverview", "PageBag", "PageKit", "PageStars", "PageForge", "PageJewels", "PageEmblems")
PAGE_WORD = {"PageBag": "Items"}
SOON = {"PageForge", "PageJewels", "PageEmblems"}


def mix(a, b, t):
    v = c(a) + (c(b) - c(a)) * t
    return "#" + "".join(f"{int(round(min(max(x, 0.0), 1.0) * 255)):02X}" for x in v[:3])


def width(s, size):
    """About how wide a line of Blender's face is, in points: generous, so nothing laid by it overruns."""
    w = 0.0
    for ch in s:
        w += 0.7 if ch.isupper() else 0.56 if ch.isalpha() else 0.64 if ch.isdigit() else 0.33 if ch in " ,.:'" else 0.6
    return w * size


def wrap(s, size, room):
    words, lines = s.split(" "), [""]
    for word in words:
        trial = (lines[-1] + " " + word).strip()
        if width(trial, size) <= room or not lines[-1]:
            lines[-1] = trial
        else:
            lines.append(word)
    return lines


# --- drawing on a screen -------------------------------------------------------------------------------------------

class Screen:
    """One phone screen on a sheet, in its own points. Each piece is drawn on a small window of the sheet."""

    def __init__(self, sheet, ox, oy):
        self.sheet, self.ox, self.oy = sheet, ox, oy

    def area(self, x0, y0, x1, y1, m=0.0):
        x0, y0, x1, y1 = max(x0 - m, 0.0), max(y0 - m, 0.0), min(x1 + m, W), min(y1 + m, H)
        t = self.sheet.tile(self.ox + x0, self.oy + y0, x1 - x0, y1 - y0)
        t.X, t.Y = t.x + x0, t.y + y0
        return t

    def text(self, x, y, size, s, colour, align="LEFT", bold=0.0):
        """`y` is the capitals' top."""
        self.sheet.items.append(dict(x=self.ox + x, y=self.oy + y, size=size, text=s, colour=colour, align=align,
                                     layer="plain", shear=0.0, bold=bold * K))

    def mid(self, x, y_mid, size, s, colour, align="LEFT", bold=0.0):
        self.text(x, y_mid - size * ui.CAP / 2, size, s, colour, align, bold)

    def paste(self, rgba, x, y):
        """A picture on the screen, cut at the screen's edges."""
        x0, y0 = round(x * K), round(y * K)
        r0, c0 = max(0, -y0), max(0, -x0)
        r1, c1 = min(rgba.shape[0], round(H * K) - y0), min(rgba.shape[1], round(W * K) - x0)
        if r1 > r0 and c1 > c0:
            rs.paste(self.sheet.px, rgba[r0:r1, c0:c1], round(self.ox * K) + x0 + c0, round(self.oy * K) + y0 + r0)


def rrect(t, x0, y0, x1, y1, r):
    cx, cy, hw, hh = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2
    qx, qy = np.abs(t.X - cx) - hw + r, np.abs(t.Y - cy) - hh + r
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def circle(t, cx, cy, r):
    return np.hypot(t.X - cx, t.Y - cy) - r


def poly(t, pts):
    return ui.sd_polygon(t.X, t.Y, list(pts))


def seg(t, a, b):
    return ui.sd_segment(t.X, t.Y, a, b)


def stroke(t, pts, w, colour, alpha=1.0):
    """A line through points, in the screen's points (the tile's own stroke reads its own corner's)."""
    d = np.minimum.reduce([seg(t, a, b) for a, b in zip(pts, pts[1:])])
    t.paint(d - w / 2, colour, alpha)


def vramp(t, top, foot, y0, y1):
    return t.ramp(top, foot, (t.Y - y0) / max(y1 - y0, 1e-3))


IMAGES = {}


def picture(path, side, grey=False):
    """A picture brought to `side` points, kept once; `grey` drains and dims it, for an item this Voidkin can't use."""
    key = (str(path), side, grey)
    if key not in IMAGES:
        src = rs.load(path)
        px = rs.shrink(src, side * K / src.shape[1])
        if grey:
            lum = (px[..., :3] * np.array([0.3, 0.55, 0.15], dtype=np.float32)).sum(-1, keepdims=True)
            px[..., :3] = (px[..., :3] * 0.2 + lum * 0.8) * 0.55
        IMAGES[key] = px
    return IMAGES[key]


def item_art(scr, stem, x, y, side, grey=False):
    """The item's picture, square in its cell: the object already keeps its margin in it."""
    scr.paste(picture(GEAR_ART / "images" / f"{stem}.png", side, grey), x, y)


def mark(scr, name, cx, cy, size, tint, alpha=1.0):
    """One of TR17's white marks, tinted: a mark's shape is 24 points across on its 32 point image."""
    key = ("mark", name, size, tint, alpha)
    if key not in IMAGES:
        src = rs.load(MARKS_ART / "images" / f"{name}.png")
        px = rs.shrink(src, size * 32.0 / 24.0 * K / src.shape[1])
        if name != "CombatPower":
            px[..., :3] = c(tint)
        px[..., 3] *= alpha
        IMAGES[key] = px
    px = IMAGES[key]
    scr.paste(px, cx - px.shape[1] / K / 2, cy - px.shape[0] / K / 2)


def class_mark(scr, cls, cx, cy, r, colour, seat=None):
    t = scr.area(cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3)
    if seat:
        t.paint(circle(t, cx, cy, r + 2.2), c(seat), 0.92)
    t.paint(_glyph(t, cls, cx, cy, r * 0.78), c(colour))


def _glyph(t, cls, cx, cy, r):
    """kit.glyph reads a tile's own x and y: give it the screen's."""
    class View:
        pass
    v = View()
    v.x, v.y = t.X, t.Y
    return kit.glyph(cls, v, cx, cy, r)


def up_arrow(t, x, y, s, colour):
    """A rise: a short arrow, its head a chevron. `x, y` its tip."""
    head = poly(t, [(x, y), (x + s * 0.55, y + s * 0.55), (x + s * 0.2, y + s * 0.55), (x + s * 0.2, y + s),
                    (x - s * 0.2, y + s), (x - s * 0.2, y + s * 0.55), (x - s * 0.55, y + s * 0.55)])
    t.paint(head, c(colour))


def tick(t, x, y, s, colour, w=1.8):
    stroke(t, [(x - s * 0.5, y), (x - s * 0.12, y + s * 0.38), (x + s * 0.55, y - s * 0.42)], w, c(colour))


def empty_mark(t, slot, cx, cy, r):
    """An empty slot's plain mark (the shapes the Voidkin screen's mock stood in with)."""
    u, v = (t.X - cx) / r, (t.Y - cy) / r

    def p(pts):
        return ui.sd_polygon(u, v, list(pts)) * r

    def ring(x, y, outer, inner):
        d = np.hypot(u - x, v - y)
        return np.maximum(d - outer, inner - d) * r
    kind = slot.replace(" I", "")
    if kind == "Helmet":
        return np.maximum(np.hypot(u, v - 0.1) - 0.82, v - 0.2) * r
    if kind == "Shoulders":
        return p([(-1, 0.5), (-0.6, -0.5), (0, -0.15), (0.6, -0.5), (1, 0.5), (0.5, 0.25), (0, 0.45), (-0.5, 0.25)])
    if kind == "Chest Armor":
        return p([(-0.85, -0.8), (-0.35, -0.8), (0, -0.45), (0.35, -0.8), (0.85, -0.8), (0.75, 0.9), (-0.75, 0.9)])
    if kind == "Gloves":
        return p([(-0.5, -0.9), (0.45, -0.9), (0.45, -0.1), (0.85, -0.3), (0.95, 0.1), (0.45, 0.9), (-0.5, 0.9)])
    if kind == "Bracers":
        return p([(-0.62, -0.9), (0.62, -0.9), (0.42, 0.9), (-0.42, 0.9)])
    if kind == "Boots":
        return p([(-0.5, -0.95), (0.15, -0.95), (0.15, 0.2), (0.9, 0.45), (0.9, 0.9), (-0.5, 0.9)])
    if kind == "Cloak":
        return p([(-0.3, -0.95), (0.3, -0.95), (0.9, 0.7), (0.45, 0.95), (0, 0.7), (-0.45, 0.95), (-0.9, 0.7)])
    if kind == "Amulet":
        return np.minimum(p([(0, 0.05), (0.42, 0.45), (0, 0.95), (-0.42, 0.45)]),
                          np.maximum(np.abs(np.hypot(u, v + 0.35) - 0.62) - 0.08, v - 0.05) * r)
    if kind == "Ring":
        return np.minimum(ring(0, 0.22, 0.62, 0.36), p([(0, -0.95), (0.3, -0.55), (0, -0.3), (-0.3, -0.55)]))
    if kind == "Earring":
        return np.minimum(ring(0, -0.62, 0.26, 0.12), p([(0, -0.3), (0.4, 0.3), (0, 0.95), (-0.4, 0.3)]))
    if kind == "Main Hand":
        return np.minimum(ui.sd_segment(u, v, (-0.7, 0.7), (0.8, -0.8)) * r - 0.14 * r,
                          ui.sd_segment(u, v, (-0.62, 0.22), (-0.22, 0.62)) * r - 0.12 * r)
    return np.minimum(ui.sd_segment(u, v, (-0.5, 0.5), (0.6, -0.6)) * r - 0.13 * r,
                      ui.sd_segment(u, v, (-0.5, 0.05), (-0.05, 0.5)) * r - 0.11 * r)


def phone(scr, light=False):
    """The phone's own things: Roblox's bar, the island and the corners (as the HUD's sheets stand them in)."""
    t = scr.area(70, 10, 218, 56)
    shade, pale = c("#101116"), c("#E8E8E8")
    t.paint(np.hypot(t.X - 92.5, t.Y - 32.5) - 18.5, shade, 0.55 if light else 0.45)
    t.paint(np.hypot(np.maximum(np.abs(t.X - 165) - 29.5, 0), t.Y - 32.5) - 18.5, shade, 0.55 if light else 0.45)
    for cx in (147, 183):
        t.paint(np.maximum(np.abs(t.X - cx) - 7, np.abs(t.Y - 32.5) - 1.0), pale, 0.85)
    t.paint(np.maximum(np.abs(t.X - 92.5) - 6, np.abs(t.Y - 32.5) - 6), pale, 0.85)
    t = scr.area(768, 142, 806, 232)
    t.paint(np.hypot(t.X - 787.5, np.maximum(np.abs(t.Y - 187) - 42, 0)) - 16.5, c("#000000"))
    rr = 44.0
    for x0, y0 in ((0, 0), (W - rr, 0), (0, H - rr), (W - rr, H - rr)):
        t = scr.area(x0, y0, x0 + rr, y0 + rr)
        qx = np.maximum(np.abs(t.X - W / 2) - (W / 2 - rr), 0)
        qy = np.maximum(np.abs(t.Y - H / 2) - (H / 2 - rr), 0)
        t.paint(rr - np.hypot(qx, qy), c("#000000"))


def figure_render(blend):
    """A Voidkin's model, whole, three-quarter on, as the Voidkin screen's mock takes Rook."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Figure")
    with bpy.data.libraries.load(str(MODELS / blend)) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
        if o.type == "MESH":
            scene.collection.objects.link(o)
    rm.eevee(scene, 900, 1080)
    rm.sun_for(scene, 158)
    path = bl.out_dir() / "_figure.png"
    shot = rs.trim(rs.shoot(scene, path, 158, 6, (0, 0, 2.7), 6.4))
    path.unlink()
    return shot


FIGURES = {}


def figure(scr, who, cx, foot, tall, tint=None):
    key = (who["who"], tall)
    if key not in FIGURES:
        FIGURES[key] = rs.shrink(FIGURES[who["who"]], tall * K / FIGURES[who["who"]].shape[0])
    px = FIGURES[key]
    if tint is not None:
        px = px.copy()
        px[..., :3] = px[..., :3] * (1 - tint[1]) + c(tint[0]) * tint[1]
    scr.paste(px, cx - px.shape[1] / K / 2, foot - px.shape[0] / K)


def face(who, side):
    """The Voidkin's portrait, cut round."""
    key = ("face", who, side)
    if key not in IMAGES:
        src = rs.load(PORTRAITS / f"Portrait{who}.png")[244:584, 198:538].copy()
        px = rs.shrink(src, side * K / src.shape[1])
        n = px.shape[0]
        gy, gx = np.mgrid[0:n, 0:px.shape[1]]
        px[..., 3] *= np.clip(n / 2 - np.hypot(gx + 0.5 - n / 2, gy + 0.5 - n / 2), 0, 1)
        IMAGES[key] = px
    return IMAGES[key]


def slot_items(who):
    """What the shown Voidkin's preset holds in each of its fourteen slots."""
    if who.get("new"):
        return {}
    held = dict(PRESET)
    held.update(PAIRS[who["cls"]])
    return held


def bag_for(who):
    return () if who.get("new") else BAG


def usable(who, stem):
    return GEAR[stem]["kind"] not in WEAPON or who["cls"] == "Warrior"


# --- A, Lacquer: the ledger ------------------------------------------------------------------------------------------

A_BAG = 356.0  # where A's bag begins: the doll's column, a hairline, then the grid
LACQUER = dict(top="#1C1713", foot="#0C0A08", brass="#C9A56B", brass_dim="#5E4C34", text="#F0E8D7", soft="#AEA390",
               faint="#6E6556", field=("#221B16", "#16110E"), well=("#110E0B", "#070605"), umber=("#2E1E0E", "#140C05"))


def a_cell(scr, p, x, y, s, stem, who, chosen=False, target=False, slot=None):
    """A's cell: a lacquer well, its rarity a bar along its foot and a fine rim; Legendary a double rim in gold and a
    brass corner. Chosen: a bone ring outside it. An item this Voidkin can't use is drained, its class's mark on it."""
    t = scr.area(x, y, x + s, y + s, 6)
    d = rrect(t, x, y, x + s, y + s, 2.0)
    if stem is None:
        t.paint(d, vramp(t, mix(p["well"][0], p["top"], 0.4), p["well"][1], y, y + s), 0.9)
        t.line(d, 1.0, c(p["brass_dim"]), 0.7)
        if slot:
            t.paint(empty_mark(t, slot, x + s / 2, y + s / 2, s * 0.26), c(p["faint"]), 0.55)
        if target:
            t.line(d + 2.5, 1.6, c(p["text"]))
        return
    g = GEAR[stem]
    rarity, ok = g["rarity"], usable(who, stem)
    col = RARITY[rarity]
    legendary = rarity == "Legendary"
    t.paint(d, vramp(t, *(p["umber"] if legendary else p["well"]), y, y + s))
    t.glow(np.hypot((t.X - x - s / 2) * 0.75, t.Y - y - s) - s * 0.1, s * 0.32, c(col), 0.34 if ok else 0.12)
    t.line(d, 1.0, c(col), 0.55 if ok else 0.25)
    if legendary:
        t.line(d + 2.2, 0.7, c(col), 0.5)
        t.paint(poly(t, [(x, y), (x + 9, y), (x, y + 9)]), c(p["brass"]))
    t.paint(np.maximum(d, -(t.Y - (y + s - 3.0))), c(col), 0.95 if ok else 0.35)
    item_art(scr, stem, x + 1.5, y + 1.0, s - 3, grey=not ok)
    t = scr.area(x, y, x + s, y + s, 6)
    d = rrect(t, x, y, x + s, y + s, 2.0)
    if not ok:
        class_mark(scr, "Warrior", x + s - 8, y + s - 10, 6.0, p["soft"], seat="#0A0807")
    if stem in RAISES.get(who["who"], ()):
        t.paint(rrect(t, x + s - 14, y + 2, x + s - 2, y + 14, 2), c("#0A0807"), 0.85)
        up_arrow(t, x + s - 8, y + 4, 8.0, UP)
    if stem in WORN and ok:
        t.paint(rrect(t, x + 2, y + 2, x + 14, y + 14, 2), c("#0A0807"), 0.85)
        tick(t, x + 8, y + 8.5, 7.0, p["text"], 1.5)
    if chosen or target:
        t.line(d + 3.0, 1.8, c(p["text"]))


def a_rail(scr, p):
    """The rail, in brass: a hairline down the left, a mark on it for each page. The chosen page: a bone lozenge and
    its word. A page not built yet is a dim mark."""
    x, chosen = 84.0, 1
    ys, y = [], 72.0
    for i in range(len(PAGES)):
        ys.append(y)
        y += 41.0 + (17.0 if i == chosen else 0.0)
    t = scr.area(x - 24, 56, x + 24, 372)
    t.paint(np.maximum(np.abs(t.X - x) - 0.5, np.abs(t.Y - 214) - 150), c(p["brass_dim"]), 0.9)
    for i, (page, y) in enumerate(zip(PAGES, ys)):
        if i == chosen:
            d = poly(t, [(x, y - 21), (x + 21, y), (x, y + 21), (x - 21, y)])
            t.paint(d - 2.5, c(p["top"]))
            t.paint(d, vramp(t, p["text"], mix(p["text"], p["brass"], 0.45), y - 21, y + 21))
        else:
            t.paint(circle(t, x, y, 15.0), c(p["top"]))
            t.line(circle(t, x, y, 15.0), 0.9, c(p["brass_dim"]))
    for i, (page, y) in enumerate(zip(PAGES, ys)):
        if i == chosen:
            mark(scr, page, x, y, 17.0, "#17120E")
            scr.text(x, y + 26, 14, PAGE_WORD[page], p["text"], "CENTER")
        else:
            mark(scr, page, x, y, 14.0, p["soft"], 0.35 if page in SOON else 0.9)


def a_band(scr, p, who):
    t = scr.area(222, 10, 758, 50)
    stroke(t, [(240, 20), (232, 29), (240, 38)], 2.4, c(p["text"]))
    t.line(rrect(t, 222, 12, 262, 46, 3), 0.9, c(p["brass_dim"]))
    # the categories, over the bag: the chosen one is its word, the rest their marks; a brass rule runs under them
    x = A_BAG + 195 - (75 + 4 * 44)
    t.paint(np.maximum(np.abs(t.Y - 48.5) - 0.5, np.maximum(x - t.X, t.X - (A_BAG + 195))), c(p["brass_dim"]))
    for word, count, built in CATEGORIES:
        on = word == "Gear"
        w = 75.0 if on else 44.0
        if on:
            t.paint(np.maximum(np.abs(t.Y - 47.5) - 1.5, np.maximum(x + 4 - t.X, t.X - (x + w - 4))), c(p["brass"]))
            scr.mid(x + 8, 30, 15, word, p["text"], bold=0.12)
            scr.mid(x + 50, 30, 14, "0" if who.get("new") else count, p["brass"])
        else:
            cat_mark(t, word, x + w / 2, 30, 7.5, p["soft"], 0.9 if built else 0.3)
        x += w
    t.paint(rrect(t, 652, 14, 756, 44, 3), c(p["field"][0]), 0.9)
    t.line(rrect(t, 652, 14, 756, 44, 3), 0.9, c(p["brass_dim"]))
    scr.mid(664, 29, 14, "Preset 1", p["text"])
    stroke(t, [(737, 26), (742, 32), (747, 26)], 1.6, c(p["soft"]))


def cat_mark(t, word, cx, cy, r, colour, alpha):
    """A category's mark: a shard for Shards, a hex crest for Emblems, a cut gem for Jewels, a lump of ore for Stones,
    a blade over a helm's dome for Gear."""
    u, v = (t.X - cx) / r, (t.Y - cy) / r

    def p(pts):
        return ui.sd_polygon(u, v, list(pts)) * r
    if word == "Shards":
        d = p([(0, -1.1), (0.55, -0.1), (0.1, 1.1), (-0.5, 0.15)])
    elif word == "Emblems":
        d = p([(math.cos(math.radians(60 * i + 30)) * 1.0, math.sin(math.radians(60 * i + 30)) * 1.0) for i in range(6)])
        d = np.maximum(d, -(p([(math.cos(math.radians(60 * i + 30)) * 0.5, math.sin(math.radians(60 * i + 30)) * 0.5)
                               for i in range(6)])))
    elif word == "Jewels":
        d = p([(-0.95, -0.35), (-0.5, -0.85), (0.5, -0.85), (0.95, -0.35), (0, 0.95)])
    elif word == "Stones":
        d = p([(-0.9, 0.2), (-0.55, -0.6), (0.1, -0.85), (0.8, -0.4), (0.95, 0.35), (0.4, 0.85), (-0.5, 0.8)])
    else:
        d = np.minimum(ui.sd_segment(u, v, (-0.8, 0.8), (0.75, -0.75)) * r - 0.13 * r,
                       ui.sd_segment(u, v, (-0.75, 0.25), (-0.25, 0.75)) * r - 0.12 * r)
    t.paint(d, c(colour), alpha)


def a_doll(scr, p, who, target=None):
    """The Voidkin between its two columns of slots, its name over its head, Combat Power and its two hands at its
    feet."""
    held = slot_items(who)
    s, pitch, cx = 44.0, 49.0, 226.0
    t = scr.area(156, 52, 296, 300)
    t.glow(np.hypot((t.X - cx) * 0.9, t.Y - 190) - 40, 44.0, c("#3A2B1C"), 0.55)
    t.paint(np.hypot((t.X - cx) / 3.6, t.Y - 262) - 6, c(p["brass_dim"]), 0.5)
    t.line(np.hypot((t.X - cx) / 3.6, t.Y - 262) - 6, 0.8, c(p["brass"]), 0.6)
    figure(scr, who, cx, 266, 168)
    scr.mid(cx, 66, 16, who["who"], p["text"], "CENTER", bold=0.15)
    scr.mid(cx, 85, 14, f"Lv {who['level']}  {who['cls']}", p["soft"], "CENTER")
    for col, x in ((SLOTS[:6], 112.0), (SLOTS[6:], 296.0)):
        for i, slot in enumerate(col):
            a_cell(scr, p, x, 56 + i * pitch, s, held.get(slot), who, target=slot == target, slot=slot)
    t = scr.area(cx - 64, 268, cx + 64, 296)
    band = np.clip(1 - np.abs(t.X - cx) / 64, 0, 1)
    ui.over(t.px, c("#000000"), band * 0.45)
    w = width(who["power"], 18)
    mark(scr, "CombatPower", cx - w / 2 - 6, 282, 16.0, None)
    scr.mid(cx - w / 2 + 6, 282, 18, who["power"], POWER_GOLD, bold=0.15)
    for slot, x in zip(WEAPON, (cx - 50, cx + 6)):
        a_cell(scr, p, x, 302, s, held.get(slot), who, target=slot == target, slot=slot)
    if not who.get("new") and not PAIRS[who["cls"]]:
        scr.mid(cx, 358, 14, f"No {who['cls']} weapon", p["soft"], "CENTER")
    # the doll's column ends in a brass hairline before the bag
    t = scr.area(A_BAG - 9, 60, A_BAG - 5, 366)
    t.paint(np.maximum(np.abs(t.X - (A_BAG - 7)) - 0.4, np.abs(t.Y - 213) - 150), c(p["brass_dim"]), 0.8)


def a_bag(scr, p, who, chosen):
    items = bag_for(who)
    x0, y0, s, gap = A_BAG, 60.0, 45.0, 5.0
    if not items:
        t = scr.area(x0, y0, x0 + 4 * s + 3 * gap, 370)
        for i in range(16):
            x, y = x0 + (i % 4) * (s + gap), y0 + 8 + (i // 4) * (s + gap)
            t.line(rrect(t, x, y, x + s, y + s, 2), 0.8, c(p["brass_dim"]), 0.45)
        t.paint(rrect(t, x0 + 4, 150, x0 + 4 * s + 3 * gap - 4, 230, 3), c(p["top"]), 0.92)
        scr.mid(x0 + 97.5, 176, 16, "No gear yet", p["text"], "CENTER", bold=0.12)
        scr.mid(x0 + 97.5, 200, 14, "Shades and keepers drop it", p["soft"], "CENTER")
        return
    scr.mid(x0, y0 + 7, 14, f"{len(items)} / 60", p["soft"])
    scr.mid(x0 + 4 * s + 3 * gap, y0 + 7, 14, "Power", p["soft"], "RIGHT")
    t = scr.area(x0 + 4 * s + 3 * gap - 58, y0, x0 + 4 * s + 3 * gap - 48, y0 + 14)
    stroke(t, [(x0 + 4 * s + 3 * gap - 56, y0 + 5), (x0 + 4 * s + 3 * gap - 53, y0 + 9),
              (x0 + 4 * s + 3 * gap - 50, y0 + 5)], 1.4, c(p["soft"]))
    for i, stem in enumerate(items[:24]):
        x, y = x0 + (i % 4) * (s + gap), y0 + 20 + (i // 4) * (s + gap)
        a_cell(scr, p, x, y, s, stem, who, chosen=stem == chosen)
    t = scr.area(x0 - 4, 340, x0 + 4 * s + 3 * gap + 4, 375)
    fade = np.clip((t.Y - 340) / 26, 0, 1) ** 1.2
    ui.over(t.px, c(p["foot"]), fade)


def stat_row(scr, x0, x1, y, name, value, delta, p, colours=(UP, DOWN), size=14):
    scr.mid(x0, y, size, name, p["soft"])
    scr.mid(x1 - 44, y, size, value, p["text"], "RIGHT")
    if delta not in ("0", ""):
        scr.mid(x1, y, size, delta.replace("-", "−"), colours[0] if delta.startswith("+") else colours[1], "RIGHT")
    else:
        scr.mid(x1, y, size, "–", p["faint"], "RIGHT")


def a_card(scr, p, who, chosen):
    """The column on the right: the chosen item set against what's held. Nothing chosen: the Voidkin's attributes."""
    x0, y0, x1, y1 = 560.0, 56.0, 756.0, 370.0
    t = scr.area(x0, y0, x1, y1, 4)
    d = poly(t, [(x0 + 10, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0 + 10)])
    t.paint(d, vramp(t, *p["field"], y0, y1), 0.96)
    t.paint(np.maximum(d, np.abs(t.X - x0 - 0.5) - 0.5), c(p["brass_dim"]))
    stroke(t, [(x0, y0 + 10), (x0 + 10, y0)], 1.0, c(p["brass"]))
    lx, rx = x0 + 12, x1 - 10
    if chosen is None:
        scr.mid(lx, y0 + 18, 14, "Basic", p["brass"])
        rows = (("Strength", "48"), ("Agility", "22"), ("Stamina", "40"), ("Spirit", "18"))
        for i, (n, v) in enumerate(rows):
            scr.mid(lx, y0 + 42 + i * 19, 14, n, p["soft"])
            scr.mid(rx, y0 + 42 + i * 19, 14, v, p["text"], "RIGHT")
        scr.mid(lx, y0 + 130, 14, "Battle", p["brass"])
        rows = (("Attack", "212"), ("Health", "1,204"), ("Defence", "96"), ("Hit", "40"), ("Critical", "12"))
        for i, (n, v) in enumerate(rows):
            scr.mid(lx, y0 + 154 + i * 19, 14, n, p["soft"])
            scr.mid(rx, y0 + 154 + i * 19, 14, v, p["text"], "RIGHT")
        scr.mid((x0 + x1) / 2, y0 + 268, 14, "Tap an item to see it", p["faint"], "CENTER")
        return
    g = GEAR[chosen["stem"]]
    ok = usable(who, chosen["stem"])
    a_cell(scr, p, lx, y0 + 8, 44, chosen["stem"], who)
    class_mark(scr, "Warrior", lx + 37, y0 + 45, 5.5, p["text"], seat="#0A0807")
    scr.mid(lx + 54, y0 + 18, 14, g["rarity"], RARITY[g["rarity"]], bold=0.1)
    scr.mid(lx + 54, y0 + 36, 14, g["kind"], p["soft"])
    y = y0 + 66
    for line in wrap(g["name"], 16, rx - lx):
        scr.mid(lx, y, 16, line, p["text"], bold=0.15)
        y += 19
    if not ok:
        class_mark(scr, "Warrior", lx + 6, y + 2, 6.0, p["text"])
        scr.mid(lx + 16, y + 2, 14, "Warrior only", p["text"], bold=0.12)
        y += 18
        t = scr.area(x0, y - 4, x1, y + 2)
        t.paint(np.maximum(np.abs(t.Y - y + 1) - 0.4, np.maximum(lx - t.X, t.X - rx)), c(p["brass_dim"]))
        for i, (n, v) in enumerate(chosen["lines"]):
            scr.mid(lx, y + 14 + i * 19, 14, n, p["soft"])
            scr.mid(rx, y + 14 + i * 19, 14, v, p["text"], "RIGHT")
        scr.mid((lx + rx) / 2, 304, 14, chosen["why"], p["soft"], "CENTER")
        a_button(scr, p, lx, 324, rx - lx, 44, "Equip", False)
        return
    # what it does to Combat Power, right under the name; then what it replaces
    y -= 6
    t = scr.area(x0, y, x1, y + 26)
    t.paint(rrect(t, lx - 4, y, rx + 2, y + 24, 3), c("#0B0907"), 0.7)
    mark(scr, "CombatPower", lx + 8, y + 12, 14.0, None)
    scr.mid(lx + 20, y + 12, 14, "Power", p["soft"])
    up = scr.area(rx - 12, y + 4, rx + 2, y + 20)
    up_arrow(up, rx - 5, y + 5, 12.0, UP)
    scr.mid(rx - 16, y + 12, 18, chosen["power"], UP, "RIGHT", bold=0.15)
    y += 36
    scr.mid(lx, y, 14, "for", p["faint"])
    item_art(scr, chosen["against"], lx + 20, y - 10, 20)
    scr.mid(lx + 42, y, 14, GEAR[chosen["against"]]["name"], RARITY[GEAR[chosen["against"]]["rarity"]])
    y += 22
    # Basic Attributes, two to a row as short words; then Battle Attributes, one to a row
    for i, (_, short, value, delta) in enumerate(chosen["basic"]):
        bx = lx if i % 2 == 0 else (lx + rx) / 2 + 6
        by = y + (i // 2) * 17
        scr.mid(bx, by, 14, short, p["brass"])
        col = UP if delta.startswith("+") else DOWN if delta.startswith("-") else p["faint"]
        scr.mid(bx + 36, by, 14, delta.replace("-", "−") if delta != "0" else "–", col)
    y += 29
    t = scr.area(x0, y - 4, x1, y + 2)
    t.paint(np.maximum(np.abs(t.Y - y + 1) - 0.4, np.maximum(lx - t.X, t.X - rx)), c(p["brass_dim"]))
    y += 12
    for i, (n, v, dl) in enumerate(chosen["battle"]):
        stat_row(scr, lx, rx, y + i * 17, n, v, dl, p)
    a_button(scr, p, lx, 324, rx - lx, 44, "Equip", True)


def a_button(scr, p, x, y, w, h, label, enabled):
    t = scr.area(x, y, x + w, y + h, 6)
    d = poly(t, [(x + 8, y), (x + w, y), (x + w, y + h - 8), (x + w - 8, y + h), (x, y + h), (x, y + 8)])
    if enabled:
        t.glow(d, 5.0, c(p["brass"]), 0.25)
        t.paint(d, vramp(t, mix(p["text"], p["brass"], 0.2), p["brass"], y, y + h))
        scr.mid(x + w / 2, y + h / 2, 16, label, "#17120E", "CENTER", bold=0.2)
    else:
        t.paint(d, c(p["top"]), 0.9)
        t.line(d, 1.0, c(p["brass_dim"]), 0.8)
        scr.mid(x + w / 2, y + h / 2, 16, label, p["faint"], "CENTER")


def draw_a(scr, state, who, chosen):
    p = LACQUER
    t = scr.area(0, 0, W, H)
    t.paint(t.X * 0 - 1, vramp(t, p["top"], p["foot"], 0, H))
    t.glow(np.hypot((t.X - 226) * 0.6, t.Y - 180) - 60, 120.0, c("#2A2016"), 0.5)
    del t
    a_rail(scr, p)
    a_band(scr, p, who)
    target = None if chosen is None else GEAR[chosen["stem"]]["kind"] if usable(who, chosen["stem"]) else None
    a_doll(scr, p, who, target)
    a_bag(scr, p, who, None if chosen is None else chosen["stem"])
    a_card(scr, p, who, chosen)
    phone(scr)


# --- B, Nocturne: the ring -------------------------------------------------------------------------------------------

NOCTURNE = dict(top="#131B27", foot="#070A10", silver="#A9B6C8", silver_dim="#3D4A5C", ice="#EAF3FF", text="#E9EFF7",
                soft="#93A2B6", faint="#5A6679", field=("#18222F", "#0F1620"), well=("#0E141C", "#070A0F"),
                umber=("#2A1E10", "#120C06"))
RING = (262.0, 206.0, 120.0)  # the ring's middle and its radius
# Sixteen places round the ring, clockwise from the top, a slot's 22.5 degrees apart: the top left open for the head,
# the foot for the floor; the head's things high, the hands either side of the foot.
RING_ORDER = (None, "Earring I", "Earring II", "Amulet", "Cloak", "Ring I", "Ring II", "Off Hand", None,
              "Main Hand", "Boots", "Bracers", "Gloves", "Chest Armor", "Shoulders", "Helmet")


def b_cell(scr, p, cx, cy, r, stem, who, chosen=False, target=False, slot=None, square=False):
    """B's cell: round on the ring, a soft square in the bag. The rarity is a crescent of its light under the item, and
    a fine rim. Legendary: the crescent closes into a full gold ring. Chosen: an ice ring and its glow."""
    t = scr.area(cx - r, cy - r, cx + r, cy + r, 8)
    d = rrect(t, cx - r, cy - r, cx + r, cy + r, 11.0) if square else circle(t, cx, cy, r)
    if stem is None:
        t.paint(d, vramp(t, mix(p["well"][0], p["top"], 0.5), p["well"][1], cy - r, cy + r), 0.95)
        t.line(d, 1.0, c(p["silver_dim"]), 0.9)
        if slot:
            t.paint(empty_mark(t, slot, cx, cy, r * 0.52), c(p["faint"]), 0.6)
        if target:
            t.glow(d, 5.0, c(p["ice"]), 0.5)
            t.line(d + 2.5, 1.6, c(p["ice"]))
        return
    g = GEAR[stem]
    rarity, ok = g["rarity"], usable(who, stem)
    col = RARITY[rarity]
    if chosen or target:
        t.glow(d, 6.0, c(p["ice"]), 0.55)
    t.paint(d, vramp(t, *(p["umber"] if rarity == "Legendary" else p["well"]), cy - r, cy + r))
    t.glow(np.hypot(t.X - cx, (t.Y - cy - r * 0.55) * 1.4) - r * 0.25, r * 0.5, c(col), 0.4 if ok else 0.12)
    crescent = np.maximum(np.abs(d + 1.4) - 1.4, -(t.Y - cy - r * (0.05 if rarity != "Legendary" else -2)))
    t.paint(crescent, c(col), 0.95 if ok else 0.35)
    t.line(d, 0.8, c(col), 0.5 if ok else 0.2)
    item_art(scr, stem, cx - r * 0.92, cy - r * 0.95, r * 1.84, grey=not ok)
    t = scr.area(cx - r, cy - r, cx + r, cy + r, 8)
    d = rrect(t, cx - r, cy - r, cx + r, cy + r, 11.0) if square else circle(t, cx, cy, r)
    if not ok:
        class_mark(scr, "Warrior", cx + r * 0.62, cy + r * 0.6, 6.0, p["soft"], seat="#070A0F")
    if stem in RAISES.get(who["who"], ()):
        t.paint(circle(t, cx + r * 0.7, cy - r * 0.7, 7.0), c("#070A0F"), 0.9)
        up_arrow(t, cx + r * 0.7, cy - r * 0.7 - 4.5, 8.5, UP)
    if stem in WORN and ok and square:
        t.paint(circle(t, cx - r * 0.7, cy - r * 0.7, 3.2), c(p["ice"]))
    if chosen or target:
        t.line(d + 3.0, 1.8, c(p["ice"]))


def b_rail(scr, p):
    """The rail: a column of round marks; the chosen page an ice disc, its word under it."""
    x, chosen = 84.0, 1
    ys, y = [], 74.0
    for i in range(len(PAGES)):
        ys.append(y)
        y += 40.0 + (17.0 if i == chosen else 0.0)
    t = scr.area(x - 24, 52, x + 24, 372)
    for i, y in enumerate(ys):
        if i == chosen:
            t.glow(circle(t, x, y, 19), 7.0, c(p["ice"]), 0.35)
            t.paint(circle(t, x, y, 19), vramp(t, p["ice"], p["silver"], y - 19, y + 19))
        else:
            t.paint(circle(t, x, y, 16), vramp(t, *p["field"], y - 16, y + 16))
            t.line(circle(t, x, y, 16), 0.9, c(p["silver_dim"]))
    for i, (page, y) in enumerate(zip(PAGES, ys)):
        if i == chosen:
            mark(scr, page, x, y, 17.0, "#0E1520")
            scr.text(x, y + 25, 14, PAGE_WORD[page], p["ice"], "CENTER")
        else:
            mark(scr, page, x, y, 14.0, p["soft"], 0.35 if page in SOON else 0.9)


def b_ring(scr, p, who, target):
    cx, cy, R = RING
    held = slot_items(who)
    t = scr.area(cx - R - 30, cy - R - 30, cx + R + 30, cy + R + 30)
    t.paint(circle(t, cx, cy, R - 24), vramp(t, "#1B2737", "#0B111A", cy - R, cy + R), 0.85)
    t.glow(circle(t, cx, cy - 10, 30), 70.0, c("#2B3E58"), 0.45)
    t.line(np.abs(circle(t, cx, cy, R)) - 0.5, 1.0, c(p["silver_dim"]), 0.9)
    t.paint(np.abs(circle(t, cx, cy, R - 26)) - 0.4, c(p["silver_dim"]), 0.6)
    t.paint(np.hypot((t.X - cx) / 3.4, t.Y - cy - 76) - 7, c("#25344A"), 0.9)
    figure(scr, who, cx, cy + 82, 170)
    for i, slot in enumerate(RING_ORDER):
        if slot is None:
            continue
        a = math.radians(i * 22.5)
        x, y = cx + R * math.sin(a), cy - R * math.cos(a)
        weapon = slot in WEAPON
        b_cell(scr, p, x, y, 24.0 if weapon else 22.0, held.get(slot), who, target=slot == target, slot=slot)
    # Combat Power under the ring, between the hands' feet
    t = scr.area(cx - 70, 344, cx + 70, 372)
    ui.over(t.px, c("#000000"), np.clip(1 - np.abs(t.X - cx) / 70, 0, 1) * 0.5)
    w = width(who["power"], 18)
    mark(scr, "CombatPower", cx - w / 2 - 6, 358, 15.0, None)
    scr.mid(cx - w / 2 + 6, 358, 18, who["power"], POWER_GOLD, bold=0.15)
    if not who.get("new") and not PAIRS[who["cls"]]:
        scr.mid(186, 334, 14, f"No {who['cls']}", p["soft"], "RIGHT")
        scr.mid(186, 352, 14, "weapon", p["soft"], "RIGHT")


def b_band(scr, p, who):
    t = scr.area(222, 10, 758, 50)
    t.paint(circle(t, 244, 29, 17), c(p["field"][0]), 0.9)
    t.line(circle(t, 244, 29, 17), 0.9, c(p["silver_dim"]))
    stroke(t, [(248, 21), (240, 29), (248, 37)], 2.2, c(p["text"]))
    scr.mid(272, 29, 18, who["who"], p["text"], bold=0.15)
    x = 272 + width(who["who"], 18) + 10
    scr.mid(x, 30, 14, f"Lv {who['level']}", p["soft"])
    x += width(f"Lv {who['level']}", 14) + 12
    class_mark(scr, who["cls"], x + 6, 29, 6.5, p["text"])
    scr.mid(x + 16, 30, 14, who["cls"], p["soft"])
    x += 16 + width(who["cls"], 14) + 10
    scr.mid(x, 30, 14, who["rarity"], RARITY[who["rarity"]])
    t.paint(rrect(t, 652, 14, 756, 44, 15), c(p["field"][0]), 0.9)
    t.line(rrect(t, 652, 14, 756, 44, 15), 0.9, c(p["silver_dim"]))
    scr.mid(666, 29, 14, "Preset 1", p["text"])
    stroke(t, [(736, 26), (741, 32), (746, 26)], 1.6, c(p["soft"]))


def b_tabs(scr, p):
    """The bag's kinds, a column of marks at the right edge, under the right thumb; the chosen kind lit."""
    t = scr.area(708, 56, 756, 300)
    t.paint(rrect(t, 712, 58, 754, 296, 21), c(p["field"][1]), 0.92)
    t.line(rrect(t, 712, 58, 754, 296, 21), 0.9, c(p["silver_dim"]))
    for i, (word, count, built) in enumerate(CATEGORIES):
        y = 80 + i * 48.0
        if word == "Gear":
            t.paint(circle(t, 733, y, 19), vramp(t, p["ice"], p["silver"], y - 19, y + 19))
            cat_mark(t, word, 733, y, 8.5, "#0E1520", 1.0)
        else:
            cat_mark(t, word, 733, y, 8.0, p["soft"], 0.9 if built else 0.3)


def b_bag(scr, p, who, chosen):
    items = bag_for(who)
    x0, y0, s, gap = 424.0, 56.0, 50.0, 6.0
    if chosen:
        s, gap = 46.0, 5.0
    scr.mid(x0, y0 + 9, 16, "Gear", p["text"], bold=0.15)
    if not items:
        t = scr.area(x0, 80, 700, 370)
        for i in range(15):
            x, y = x0 + (i % 5) * (s + gap), 84 + (i // 5) * (s + gap)
            t.line(rrect(t, x, y, x + s, y + s, 11), 0.8, c(p["silver_dim"]), 0.5)
        t.paint(rrect(t, x0 + 30, 140, 670, 222, 18), c(p["foot"]), 0.9)
        scr.mid(562, 168, 16, "No gear yet", p["text"], "CENTER", bold=0.12)
        scr.mid(562, 192, 14, "Shades and keepers drop it", p["soft"], "CENTER")
        return
    scr.mid(x0 + 46, y0 + 10, 14, f"{len(items)} / 60", p["soft"])
    scr.mid(700, y0 + 10, 14, "Power", p["soft"], "RIGHT")
    rows = 2 if chosen else 5
    for i, stem in enumerate(items[:rows * 5 + 5]):
        x, y = x0 + (i % 5) * (s + gap), 78 + (i // 5) * (s + gap)
        if y > 370:
            break
        b_cell(scr, p, x + s / 2, y + s / 2, s / 2, stem, who, chosen=chosen is not None and stem == chosen["stem"],
               square=True)
    if not chosen:
        t = scr.area(x0 - 4, 340, 704, 375)
        ui.over(t.px, c(p["foot"]), np.clip((t.Y - 340) / 26, 0, 1) ** 1.2)


def b_sheet(scr, p, who, chosen):
    """The chosen item rises from the bag's foot: the grid keeps two rows above it."""
    x0, y0, x1, y1 = 418.0, 182.0, 704.0, 370.0
    t = scr.area(x0, y0, x1, y1, 10)
    d = rrect(t, x0, y0, x1, y1 + 20, 16)
    t.glow(d, 10.0, c("#000000"), 0.6)
    t.paint(d, vramp(t, *p["field"], y0, y1))
    t.line(d, 1.0, c(p["silver_dim"]))
    t.paint(np.maximum(np.abs(t.Y - y0 - 0.8) - 0.7, np.abs(t.X - (x0 + x1) / 2) - 40), c(p["ice"]), 0.8)
    g = GEAR[chosen["stem"]]
    ok = usable(who, chosen["stem"])
    lx, mx, rx = x0 + 14, x0 + 150, x1 - 14
    b_cell(scr, p, lx + 22, y0 + 28, 22.0, chosen["stem"], who, square=True)
    class_mark(scr, "Warrior", lx + 37, y0 + 44, 5.5, p["text"], seat="#070A0F")
    b_button(scr, p, x1 - 98, y0 + 6, 84, 44, "Equip", ok)
    nx = lx + 54
    y = y0 + 16
    for line in wrap(g["name"], 16, x1 - 106 - nx):
        scr.mid(nx, y, 16, line, p["text"], bold=0.15)
        y += 19
    if not ok:
        scr.mid(nx, y, 14, g["rarity"], RARITY[g["rarity"]])
    else:
        mark(scr, "CombatPower", nx + 7, y + 1, 14.0, None)
        scr.mid(nx + 18, y + 1, 18, chosen["power"], UP, bold=0.15)
    y = y0 + 80
    if not ok:
        # where it would go is told in words, since no slot on the ring can take it
        scr.mid(nx + width(g["rarity"], 14) + 8, y0 + 54, 14, g["kind"], p["soft"])
        class_mark(scr, "Warrior", lx + 6, y, 6.0, p["ice"])
        scr.mid(lx + 16, y, 14, "Warrior only", p["ice"], bold=0.12)
        scr.mid(lx + 16 + width("Warrior only", 14) + 12, y, 14, chosen["why"], p["soft"])
        for i, (n, v) in enumerate(chosen["lines"]):
            scr.mid(lx, y + 26 + i * 18, 14, n, p["soft"])
            scr.mid(lx + 150, y + 26 + i * 18, 14, v, p["text"], "RIGHT")
        return
    # Combat Power's change and what it replaces (the ring shows the slot, lit), then Basic and Battle side by side
    scr.mid(lx, y, 14, g["rarity"], RARITY[g["rarity"]], bold=0.1)
    x = lx + width(g["rarity"], 14) + 10
    scr.mid(x, y, 14, "for", p["faint"])
    item_art(scr, chosen["against"], x + 22, y - 11, 22)
    scr.mid(x + 46, y, 14, GEAR[chosen["against"]]["name"], RARITY[GEAR[chosen["against"]]["rarity"]])
    y += 24
    scr.mid(lx, y, 14, "Basic", p["silver"])
    scr.mid(mx, y, 14, "Battle", p["silver"])
    for i, (name, _, value, delta) in enumerate(chosen["basic"]):
        b_stat(scr, p, lx, mx - 16, y + 17 + i * 17, name, value, delta)
    for i, (name, value, delta) in enumerate(chosen["battle"]):
        b_stat(scr, p, mx, rx, y + 17 + i * 17, name, value, delta)


def b_stat(scr, p, x0, x1, y, name, value, delta):
    scr.mid(x0, y, 14, name, p["soft"])
    if delta in ("0", ""):
        scr.mid(x1, y, 14, "–", p["faint"], "RIGHT")
    else:
        scr.mid(x1, y, 14, delta.replace("-", "−"), UP if delta.startswith("+") else DOWN, "RIGHT")


def b_button(scr, p, x, y, w, h, label, enabled):
    t = scr.area(x, y, x + w, y + h, 8)
    d = rrect(t, x, y, x + w, y + h, h / 2)
    if enabled:
        t.glow(d, 6.0, c(p["ice"]), 0.3)
        t.paint(d, vramp(t, p["ice"], mix(p["ice"], p["silver"], 0.7), y, y + h))
        scr.mid(x + w / 2, y + h / 2, 16, label, "#0E1520", "CENTER", bold=0.2)
    else:
        t.paint(d, c(p["foot"]), 0.9)
        t.line(d, 1.0, c(p["silver_dim"]))
        scr.mid(x + w / 2, y + h / 2, 16, label, p["faint"], "CENTER")


def draw_b(scr, state, who, chosen):
    p = NOCTURNE
    t = scr.area(0, 0, W, H)
    t.paint(t.X * 0 - 1, vramp(t, p["top"], p["foot"], 0, H))
    del t
    b_rail(scr, p)
    b_band(scr, p, who)
    target = None if chosen is None else GEAR[chosen["stem"]]["kind"] if usable(who, chosen["stem"]) else None
    b_ring(scr, p, who, target)
    b_bag(scr, p, who, chosen)
    b_tabs(scr, p)
    if chosen is not None:
        b_sheet(scr, p, who, chosen)
    phone(scr)


# --- C, Porcelain: the case ------------------------------------------------------------------------------------------

# As delivered on 2026-11-16 (14:25): cool porcelain, paper white at its brightest. Kept to be drawn beside BONE.
PORCELAIN = dict(top="#EEEFF1", foot="#D9DCE1", ink="#16171C", soft="#4E5361", faint="#8B909C", line="#B8BDC7",
                 card=("#FBFBFC", "#F1F2F4"), well=("#1B1D24", "#0C0D11"), umber=("#33220F", "#160E06"),
                 glaze=("#FFFFFF", 0.9), lit="#FFFFFF", belt="#E3E5E9", slot=("#C9CDD4", "#BCC1C9"), slot_mark="#9298A4",
                 shut="#CDD1D8", pair="#F4F5F7", shadow="#B9BDC6", off="#E3E5E9", button="#2A2C34",
                 card_glow="#5A6070", glow=("#FFFFFF", 0.35), on_well="#C9CDD4", up=UP_DEEP, down=DOWN_DEEP,
                 deep=RARITY_DEEP)
# Research's fix 1 (2026-11-16, 14:27): warmed toward bone and darker than paper white, so the bag doesn't flash at
# night. The kit's own ivory (#F3EFE6) is the brightest thing on it, and only as a glaze line or a word on ink.
# Measured in inventory_night.png: a first bone (ground #D8CFBE to #C7BDAA) still stood 5.6 times the Row at night,
# so it went a step deeper. The coloured words went deeper with it: 4.5 to 1 or more on their own ground, Legendary's
# gold 3.85 (bold, and its band carries the colour; as delivered it was 3.34), faint 3.0 for headings.
BONE = dict(top="#BFB5A2", foot="#ADA28D", ink="#1B1814", soft="#3F3A32", faint="#5A5347", line="#8F8572",
            card=("#CFC6B4", "#C4BAA7"), well=("#1C1A1F", "#0D0C0F"), umber=("#33220F", "#160E06"),
            glaze=("#F3EFE6", 0.55), lit="#F3EFE6", belt="#B3A894", slot=("#A39985", "#978C78"), slot_mark="#6A6254",
            shut="#9B917E", pair="#C9C0AE", shadow="#948A77", off="#B6AC98", button="#2D2924",
            card_glow="#4A4337", glow=("#F3EFE6", 0.10), on_well="#D8CFBE", up="#0B572D", down="#882C1C",
            deep={"Common": "#3B3F48", "Uncommon": "#0A532A", "Rare": "#1A4687", "Epic": "#5B2B8F",
                  "Legendary": "#6B4D08"})


def c_cell(scr, p, x, y, s, stem, who, chosen=False, target=False, slot=None):
    """C's cell: a dark inlay set in the porcelain, a glaze line round it; the rarity an enamel band across its head
    and its light inside. Legendary: a gilt band and a gilt hairline. Chosen: an ink ring."""
    t = scr.area(x, y, x + s, y + s, 6)
    d = rrect(t, x, y, x + s, y + s, 7.0)
    t.paint(d - 1.2, c(p["glaze"][0]), p["glaze"][1])
    t.paint(d - 0.6, c(p["line"]), 0.7)
    if stem is None:
        t.paint(d, vramp(t, *p["slot"], y, y + s))
        if slot:
            t.paint(empty_mark(t, slot, x + s / 2, y + s / 2, s * 0.27), c(p["slot_mark"]), 0.9)
        if target:
            t.line(d - 2.6, 1.8, c(p["ink"]))
        return
    g = GEAR[stem]
    rarity, ok = g["rarity"], usable(who, stem)
    col = RARITY[rarity]
    legendary = rarity == "Legendary"
    t.paint(d, vramp(t, *(p["umber"] if legendary else p["well"]), y, y + s))
    t.glow(np.hypot(t.X - x - s / 2, (t.Y - y - s * 0.45) * 1.1) - s * 0.12, s * 0.3, c(col), 0.36 if ok else 0.1)
    band = np.maximum(d, t.Y - (y + 3.5))
    t.paint(band, c(col), 1.0 if ok else 0.35)
    if legendary:
        t.line(d + 1.6, 0.7, c(col), 0.6)
    item_art(scr, stem, x + 1.5, y + 2.0, s - 3, grey=not ok)
    t = scr.area(x, y, x + s, y + s, 6)
    d = rrect(t, x, y, x + s, y + s, 7.0)
    if not ok:
        class_mark(scr, "Warrior", x + s - 9, y + s - 9, 5.5, p["on_well"], seat="#0C0D11")
    if stem in RAISES.get(who["who"], ()):
        t.paint(rrect(t, x + s - 15, y + 5, x + s - 3, y + 17, 3), c(p["lit"]), 0.95)
        up_arrow(t, x + s - 9, y + 6.5, 8.5, p["up"])
    if stem in WORN and ok:
        t.paint(rrect(t, x + 3, y + 5, x + 15, y + 17, 3), c(p["lit"]), 0.95)
        tick(t, x + 9, y + 11.5, 7.0, p["ink"], 1.5)
    if chosen or target:
        t.line(d - 2.6, 1.8, c(p["ink"]))


def c_rail(scr, p):
    """The rail on porcelain: ink marks; the chosen page an ink disc with its word."""
    x, chosen = 84.0, 1
    ys, y = [], 74.0
    for i in range(len(PAGES)):
        ys.append(y)
        y += 40.0 + (17.0 if i == chosen else 0.0)
    t = scr.area(x - 24, 52, x + 24, 372)
    t.paint(np.maximum(np.abs(t.X - x - 26) - 0.4, np.abs(t.Y - 212) - 156), c(p["line"]))
    for i, y in enumerate(ys):
        if i == chosen:
            t.paint(circle(t, x, y, 19), c(p["ink"]))
    for i, (page, y) in enumerate(zip(PAGES, ys)):
        if i == chosen:
            mark(scr, page, x, y, 17.0, p["lit"])
            scr.text(x, y + 25, 14, PAGE_WORD[page], p["ink"], "CENTER", bold=0.1)
        else:
            mark(scr, page, x, y, 15.0, p["soft"], 0.35 if page in SOON else 0.95)


def c_band(scr, p, who):
    """The header: back, the Voidkin's face and name, its preset, its Combat Power."""
    t = scr.area(222, 8, 758, 54)
    stroke(t, [(240, 21), (232, 30), (240, 39)], 2.4, c(p["ink"]))
    t.paint(circle(t, 282, 30, 20), c(p["deep"][who["rarity"]]))
    t.paint(circle(t, 282, 30, 18.2), c("#1B1D24"))
    scr.paste(face(who["who"], 36), 264, 12)
    scr.mid(310, 22, 18, who["who"], p["ink"], bold=0.18)
    scr.mid(310, 42, 14, f"Lv {who['level']}", p["soft"])
    x = 310 + width(f"Lv {who['level']}", 14) + 10
    class_mark(scr, who["cls"], x + 6, 42, 6.0, p["ink"])
    scr.mid(x + 15, 42, 14, who["cls"], p["soft"])
    x += 15 + width(who["cls"], 14) + 9
    scr.mid(x, 42, 14, who["rarity"], p["deep"][who["rarity"]])
    t = scr.area(520, 10, 758, 50)
    t.line(rrect(t, 528, 14, 626, 44, 15), 1.0, c(p["ink"]))
    scr.mid(542, 29, 14, "Preset 1", p["ink"])
    stroke(t, [(607, 26), (612, 32), (617, 26)], 1.6, c(p["ink"]))
    mark(scr, "CombatPower", 650, 29, 16.0, None)
    scr.mid(752, 22, 20, who["power"], p["ink"], "RIGHT", bold=0.2)
    scr.mid(752, 42, 14, "Combat Power", p["soft"], "RIGHT")


def c_belt(scr, p, who, target):
    """The fourteen slots as one belt across the top: the hands, the body, the jewellery."""
    held = slot_items(who)
    groups = (WEAPON, SLOTS[:6], ("Cloak", "Amulet", "Ring I", "Ring II", "Earring I", "Earring II"))
    s, gap, x, y = 42.0, 2.5, 116.0, 60.0
    t = scr.area(108, 54, 758, 108)
    t.paint(rrect(t, 110, 56, 756, 106, 10), c(p["belt"]))
    t.line(rrect(t, 110, 56, 756, 106, 10), 0.8, c(p["line"]))
    ring = None
    for gi, group in enumerate(groups):
        for slot in group:
            c_cell(scr, p, x, y, s, held.get(slot), who, slot=slot)
            if slot == target:
                ring = x
            x += s + gap
        x += 10.0
    if ring is not None:  # the slot the chosen item would go to, ringed in ink over its neighbours
        t = scr.area(ring - 5, y - 5, ring + s + 5, y + s + 5)
        t.line(rrect(t, ring, y, ring + s, y + s, 7.0) - 2.4, 1.8, c(p["ink"]))
    if not who.get("new") and not PAIRS[who["cls"]]:
        # the hands' pair, empty for this class, says so in its own place
        t = scr.area(112, 56, 208, 106)
        d = rrect(t, 116, 60, 202.5, 102, 7)
        t.paint(d, c(p["pair"]))
        t.line(d, 1.0, c(p["faint"]))
        scr.mid(159.25, 73, 14, f"No {who['cls']}", p["ink"], "CENTER", bold=0.1)
        scr.mid(159.25, 90, 14, "weapon", p["ink"], "CENTER", bold=0.1)


def c_chips(scr, p, who):
    """The bag's kinds as chips, each with its word (research's fix 3: a mark alone can't be read at phone size).
    A kind not built yet is a faint chip with its word in faint ink. The five words fill the row before the card's
    edge (118 to 446 points), so the counts left the chips."""
    x, y = 118.0, 116.0
    for word, _, built in CATEGORIES:
        on = word == "Gear"
        w = max(width(word, 14) + 14, 44.0)
        t = scr.area(x, y, x + w, y + 34, 2)
        d = rrect(t, x, y, x + w, y + 34, 17)
        if on:
            t.paint(d, c(p["ink"]))
            scr.mid(x + w / 2, y + 17, 14, word, p["lit"], "CENTER", bold=0.1)
        elif built:
            t.line(d, 1.0, c(p["line"]))
            scr.mid(x + w / 2, y + 17, 14, word, p["soft"], "CENTER")
        else:
            t.line(d, 1.0, c(p["shut"]), 0.55)
            scr.mid(x + w / 2, y + 17, 14, word, p["faint"], "CENTER")
        x += w + 4
    assert x - 4 <= 446.0, f"the kinds' chips run to {x - 4:.0f}, past the card's edge"


def c_bag(scr, p, who, chosen):
    """The grid, five across at 60 points (research's brief asks about 64)."""
    items = bag_for(who)
    x0, y0, s, gap = 118.0, 158.0, 60.0, 5.5
    right = x0 + 5 * s + 4 * gap
    if not items:  # research's fix 2: the line alone, no box and no ghost cells (they read as loading)
        scr.mid((x0 + right) / 2, 238, 16, "No gear yet", p["ink"], "CENTER", bold=0.15)
        scr.mid((x0 + right) / 2, 262, 14, "Shades and keepers drop it", p["soft"], "CENTER")
        return
    for i, stem in enumerate(items[:20]):
        x, y = x0 + (i % 5) * (s + gap), y0 + (i // 5) * (s + gap)
        c_cell(scr, p, x, y, s, stem, who, chosen=chosen is not None and stem == chosen["stem"])
    t = scr.area(x0 - 4, 344, right + 4, 375)
    ui.over(t.px, c(p["foot"]), np.clip((t.Y - 344) / 24, 0, 1) ** 1.2)


def c_voidkin(scr, p, who):
    """The Voidkin's half, nothing chosen: its figure on the porcelain, its totals beside it. No box round it."""
    t = scr.area(452, 300, 640, 372)
    t.paint(np.hypot((t.X - 540) / 3.4, t.Y - 352) - 7, c(p["shadow"]), 0.7)
    figure(scr, who, 540, 354, 214)
    lx, rx = 642.0, 748.0
    scr.mid(lx, 128, 14, "Basic", p["faint"])
    for i, (n, v) in enumerate((("Strength", "48"), ("Agility", "22"), ("Stamina", "40"), ("Spirit", "18"))):
        scr.mid(lx, 147 + i * 18, 14, n, p["soft"])
        scr.mid(rx, 147 + i * 18, 14, v, p["ink"], "RIGHT")
    scr.mid(lx, 232, 14, "Battle", p["faint"])
    for i, (n, v) in enumerate((("Attack", "212"), ("Health", "1,204"), ("Defence", "96"), ("Hit", "40"))):
        scr.mid(lx, 251 + i * 18, 14, n, p["soft"])
        scr.mid(rx, 251 + i * 18, 14, v, p["ink"], "RIGHT")


def c_card(scr, p, who, chosen):
    """A chosen item's card, slid over the Voidkin's half; it closes back to the figure."""
    x0, y0, x1, y1 = 452.0, 116.0, 752.0, 370.0
    t = scr.area(x0, y0, x1, y1, 10)
    d = rrect(t, x0, y0, x1, y1 + 16, 14)
    t.glow(d, 8.0, c(p["card_glow"]), 0.25)
    t.paint(d, vramp(t, *p["card"], y0, y1))
    t.line(d, 0.9, c(p["line"]))
    lx, rx = x0 + 14, x1 - 14
    t = scr.area(708, 118, 746, 156)
    stroke(t, [(720, 130), (732, 142)], 1.8, c(p["soft"]))
    stroke(t, [(732, 130), (720, 142)], 1.8, c(p["soft"]))
    g = GEAR[chosen["stem"]]
    ok = usable(who, chosen["stem"])
    c_cell(scr, p, lx, y0 + 12, 68, chosen["stem"], who)
    class_mark(scr, "Warrior", lx + 59, y0 + 71, 6.0, p["lit"], seat="#0C0D11")
    nx = lx + 80
    y = y0 + 22
    for line in wrap(g["name"], 18, 700 - nx):
        scr.mid(nx, y, 18, line, p["ink"], bold=0.2)
        y += 21
    if ok:
        mark(scr, "CombatPower", nx + 8, y + 1, 16.0, None)
        up = scr.area(nx + 22, y - 9, nx + 38, y + 11)
        up_arrow(up, nx + 30, y - 7, 13.0, p["up"])
        scr.mid(nx + 41, y + 1, 20, chosen["power"], p["up"], bold=0.2)
        y += 21
    scr.mid(nx, y, 14, g["rarity"], p["deep"][g["rarity"]], bold=0.1)
    scr.mid(nx + width(g["rarity"], 14) + 8, y, 14, g["kind"], p["soft"])
    if not ok:
        class_mark(scr, "Warrior", nx + 6, y + 19, 6.0, p["ink"])
        scr.mid(nx + 16, y + 19, 14, "Warrior only", p["ink"], bold=0.15)
    y = y0 + 98
    t = scr.area(x0, y - 2, x1, y + 2)
    t.paint(np.maximum(np.abs(t.Y - y) - 0.4, np.maximum(lx - t.X, t.X - rx)), c(p["line"]))
    if not ok:
        for i, (n, v) in enumerate(chosen["lines"]):
            scr.mid(lx, y + 20 + i * 20, 14, n, p["soft"])
            scr.mid(lx + 150, y + 20 + i * 20, 14, v, p["ink"], "RIGHT")
        scr.mid(rx, y1 - 70, 14, chosen["why"], p["soft"], "RIGHT")
        c_button(scr, p, rx - 120, y1 - 52, 120, 44, "Equip", False)
        return
    y += 18
    mx = (x0 + x1) / 2 + 4
    scr.mid(lx, y, 14, "Basic", p["faint"])
    scr.mid(mx, y, 14, "Battle", p["faint"])
    for i, (name, _, value, delta) in enumerate(chosen["basic"]):
        c_stat(scr, p, lx, mx - 14, y + 18 + i * 18, name, value, delta)
    for i, (name, value, delta) in enumerate(chosen["battle"]):
        c_stat(scr, p, mx, rx, y + 18 + i * 18, name, value, delta)
    scr.mid(lx, y1 - 36, 14, "Replaces", p["faint"])
    item_art(scr, chosen["against"], lx - 3, y1 - 26, 22)
    scr.mid(lx + 21, y1 - 15, 14, GEAR[chosen["against"]]["name"], p["deep"][GEAR[chosen["against"]]["rarity"]])
    c_button(scr, p, rx - 96, y1 - 46, 96, 44, "Equip", True)


def c_stat(scr, p, x0, x1, y, name, value, delta):
    scr.mid(x0, y, 14, name, p["soft"])
    scr.mid(x1 - 40, y, 14, value, p["ink"], "RIGHT")
    if delta in ("0", ""):
        scr.mid(x1, y, 14, "–", p["faint"], "RIGHT")
    else:
        scr.mid(x1, y, 14, delta.replace("-", "−"), p["up"] if delta.startswith("+") else p["down"], "RIGHT")


def c_button(scr, p, x, y, w, h, label, enabled):
    t = scr.area(x, y, x + w, y + h, 6)
    d = rrect(t, x, y, x + w, y + h, h / 2)
    if enabled:
        t.glow(d, 4.0, c("#000000"), 0.2)
        t.paint(d, vramp(t, p["button"], p["ink"], y, y + h))
        scr.mid(x + w / 2, y + h / 2, 16, label, p["lit"], "CENTER", bold=0.2)
    else:
        t.paint(d, c(p["off"]))
        t.line(d, 1.0, c(p["line"]))
        scr.mid(x + w / 2, y + h / 2, 16, label, p["faint"], "CENTER")


def draw_c(scr, state, who, chosen, p=None):
    p = p or BONE
    t = scr.area(0, 0, W, H)
    t.paint(t.X * 0 - 1, vramp(t, p["top"], p["foot"], 0, H))
    t.glow(np.hypot((t.X - 300) * 0.5, t.Y - 60) - 40, 160.0, c(p["glow"][0]), p["glow"][1])
    del t
    c_rail(scr, p)
    c_band(scr, p, who)
    target = None if chosen is None else GEAR[chosen["stem"]]["kind"] if usable(who, chosen["stem"]) else None
    c_belt(scr, p, who, target)
    c_chips(scr, p, who)
    c_bag(scr, p, who, chosen)
    if chosen is None:
        c_voidkin(scr, p, who)
    else:
        c_card(scr, p, who, chosen)
    phone(scr, light=True)


# --- the sheets ------------------------------------------------------------------------------------------------------

DIRECTIONS = (
    ("A", "Lacquer: the ledger", draw_a, "#14110E", "#E9DFC8", "#A99C82", (
        "Warm black lacquer, brass hairlines, bone words. Three columns always on: the Voidkin between its two columns "
        "of slots, the bag's grid, and the chosen item set against what's held. No panel boxes: the columns part by "
        "tone and one brass rule each.",
        "Against research's brief: the doll, the bag and the comparison stay on screen together instead of a sheet "
        "sliding over the doll, so nothing opens or closes and the slot that changes stays in view. The price: cells at "
        "45 points (the brief asks about 64), a figure 168 tall, and the densest comparison of the three, its Basic "
        "Attributes two to a row as short words. Every target is 44 or more.",
        "Motion: a tap slides the column's contents up 8 points and the target slot's bone ring draws round once. "
        "Rarity: a bar of its colour along the foot and its light rising from it; Legendary, a gilt double rim and a "
        "brass corner.")),
    ("B", "Nocturne: the ring", draw_b, "#0B0F16", "#E3EBF5", "#8796AB", (
        "Cold slate night, silver lines, ice-white light. The Voidkin stands in a ring of its fourteen slots, the "
        "head's things high, the hands at its foot: the void's ring (the Door, the great ring) made the screen's "
        "frame. Combat Power stands under the ring. The bag's kinds are a column of marks at the right edge, under the "
        "right thumb.",
        "Against research's brief: a chosen item's sheet rises over the bag's foot, not over the Voidkin, so the ring "
        "stays in view with the slot that changes lit in ice, and the sheet needn't spell the slot. The price: the bag "
        "keeps two rows while an item is open, and cells at 50 (46 while open). Equip at the sheet's head under the "
        "right thumb; Combat Power's change under the name; Basic and Battle side by side.",
        "Motion: the sheet rises in 0.18 s and the ring's slot glows in; the ring turns a few degrees to bring the "
        "slot nearer the sheet. Rarity: a crescent of its light under the item; Legendary, the crescent closes into "
        "a gold ring.")),
    ("C", "Porcelain: the case", draw_c, "#BDB3A0", "#1B1814", "#4A443B", (
        "Bone porcelain and ink, the items in dark inlays, so each picture is a jewel in its case: the one light "
        "screen in a dark game, kept for the bag. The fourteen slots are one belt across the top, in three groups "
        "(hands, body, jewellery), always in view; the Voidkin's face, name and Combat Power stand in the header.",
        "On research's brief: two zones, the grid (five across at 60) and the Voidkin's half, its figure and its "
        "totals. A chosen item's card slides over the Voidkin's half and closes back, while the belt keeps every slot "
        "in view and rings in ink the one that changes. The card: the name, Combat Power's change under it, Basic "
        "and Battle as two tables with the value and its change, what it replaces, Equip at the right thumb.",
        "Motion: the card slides in from the right over the figure in 0.16 s, the chosen cell sinks 1 point, the "
        "belt's slot rings in ink. Rarity: an enamel band across the inlay's head and its light inside; Legendary, a "
        "gilt band and hairline.",
        "Research's fixes of 14:27: the porcelain warmed toward bone and darker than paper white, so the bag doesn't "
        "flash at night (inventory_night.png sets it beside the Row at night and today's bag, measured); the empty "
        "bag as its line alone; every kind's chip with its word, the counts gone from the chips to make the room.")),
)
CAPTIONS = ("1. Rook, a Warrior, full bag: a Legendary with a 24-character name, set against what he holds.",
            "2. Lyric, a Healer, the same preset: a Warrior's sword chosen; her own hands' slots stand empty.",
            "3. A new account: the bag empty.")
STANDINS = ("Stand-ins: every number, and the attributes' names (the register's point 1 may rename them); the text is "
            "Blender's face, not the game's. Roblox's buttons, the island and the corners are drawn where an iPhone puts "
            "them. Down red is kept for numbers; a class's limit is told in words and its mark. The tabs are the bag's "
            "kinds as the design has them (docs/design.md, \"The bag\"); the brief's list drops into any strip as it is.")
M, HEAD = 20.0, 46.0


def direction_sheet(out, key, title, draw, ground, head, note, notes):
    lines = [line for n in notes + (STANDINS,) for line in textwrap.wrap(n, 140)]
    h = HEAD + 3 * (H + 30) + 16 + len(lines) * 16 + 16
    sheet = ui.Sheet(W + 2 * M, h, ground)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(M, 14, 18, f"Grow your Anime, the mobile inventory: {key}, {title}", head, bold=0.2 * K)
    y = HEAD
    shots = []
    for (state, who, chosen), caption in zip(STATES, CAPTIONS):
        t.text(M, y, 13, caption, note)
        scr = Screen(sheet, M, y + 18)
        draw(scr, state, who, chosen)
        shots.append(y + 18)
        y += H + 30
    y += 4
    for i, line in enumerate(lines):
        t.text(M, y + i * 16, 12, line, note)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / f"inventory_{key}.png")
    first = sheet.px[round(shots[0] * K):round((shots[0] + H) * K), round(M * K):round((M + W) * K)].copy()
    return rs.shrink(first, 0.5)


def glance_sheet(out, firsts):
    """The three at a phone's own size, a pixel a point, side by side as they'd be judged."""
    gap = 16.0
    ui.K, kk = 1, K
    sheet = ui.Sheet(3 * W + 4 * gap, H + 60, "#202228")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    for i, ((key, title, *_), px) in enumerate(zip(DIRECTIONS, firsts)):
        x = gap + i * (W + gap)
        rs.paste(sheet.px, px, round(x), 40)
        t.text(x, 14, 16, f"{key}, {title}", "#E9E4D8")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    ui.K = kk
    rs.save(sheet.px, out / "inventory_glance.png")


# Faber's phone captures from TR24's run (2026-11-16, before 14:18): the Row at night with the HUD, and today's bag.
NIGHT_STILLS = REPO / "build" / "scratch" / "faber" / "tr24"


def light(px):
    """A screen's mean light: its relative luminance, linear, averaged over every pixel (1.0 is a white screen)."""
    v = np.clip(px[..., :3], 0.0, 1.0)
    lin = np.where(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055) ** 2.4)
    return float((lin @ np.array([0.2126, 0.7152, 0.0722])).mean())


def c_alone(p):
    """C with nothing chosen, as the bag opens, in palette p, at a pixel a point."""
    sheet = ui.Sheet(W, H, "#000000")
    draw_c(Screen(sheet, 0, 0), "full", ROOK, None, p)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return rs.shrink(sheet.px, 1 / K)


def night_sheet(out):
    """Research's fix 1, judged as a phone at night: the bag as it opens, beside the Row at night with its HUD and
    today's bag, each at a phone's size over a dark room, with each screen's mean light measured."""
    screens = [("The Row at night, the HUD (Faber's TR24 capture)", NIGHT_STILLS / "16-d-row-night.png"),
               ("Today's bag (Faber's TR24 capture)", NIGHT_STILLS / "14-bag.png"),
               ("C as delivered at 14:25: porcelain, paper white", PORCELAIN),
               ("C warmed to bone (research's fix 1)", BONE)]
    shots = []
    for label, source in screens:
        if isinstance(source, dict):
            px = c_alone(source)
        elif source.exists():
            px = rs.load(source)
            px = rs.shrink(px, H / px.shape[0])
        else:
            px = None
        shots.append((label, px))
    gap, top = 16.0, 44.0
    ui.K, kk = 1, K
    night = next((light(px) for _, px in shots if px is not None), None)
    sheet = ui.Sheet(2 * W + 3 * gap, top + 2 * (H + 34) + 40, "#050506")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 16, "C's bag at night: each screen at a phone's size, over a dark room, with its mean light",
           "#B4AC9C")
    for i, (label, px) in enumerate(shots):
        x, y = gap + (i % 2) * (W + gap), top + (i // 2) * (H + 34)
        if px is None:
            t.text(x, y + 20, 14, f"{label}: not found", "#B4AC9C")
            continue
        rs.paste(sheet.px, px, round(x), round(y + 22))
        lit = light(px)
        than = f", {lit / night:.1f} times the Row at night" if night and i else ""
        t.text(x, y, 14, f"{label}. Mean light {lit:.2f}{than}", "#EDE6D6")
    t.text(gap, sheet.h - 30, 12, "Mean light: relative luminance, linear, averaged over the screen (a white "
           "screen is 1.00). A monitor's picture of a phone, not a phone: the real check is on a device once built.",
           "#8F887A")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    ui.K = kk
    rs.save(sheet.px, out / "inventory_night.png")
    print("light:", {label: round(light(px), 3) for label, px in shots if px is not None})


def main():
    out = bl.out_dir()
    for who in (ROOK, LYRIC):
        FIGURES[who["who"]] = figure_render(who["blend"])
    firsts = []
    for key, title, draw, ground, head, note, notes in DIRECTIONS:
        firsts.append(direction_sheet(out, key, title, draw, ground, head, note, notes))
        IMAGES.clear()
        for k in [k for k in FIGURES if isinstance(k, tuple)]:
            del FIGURES[k]
    glance_sheet(out, firsts)
    night_sheet(out)


if __name__ == "__main__":
    main()
