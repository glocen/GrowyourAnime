"""The bag's skin in the seam's colours (AR18; the director's word, 2026-11-17, 02:40: "we should build the inventory
more with that color style not the old yellow brown", on AR24's A). The ledger's layout stays as the game builds it
(TR28, Faber's still tr28-left of 2026-11-16, 23:25, read at 2.35 pixels a point): the rail, the doll at the room's left
between its two columns of slots, a hairline, the kinds strip over the grid, the count under it, and a chosen item's card
sliding in at the room's right edge, the doll's width. Only the skin changes: the warm brown and brass give way to the
seam's violet-black and its pale light edges; the rarities keep their own colours on the cells (AR6's assembly).

The seam's language, carried from the chest opening (AR24's A, tools/blender/chest_band.py):
  - violet-black grounds, a ramp from the middle's violet to near black;
  - edges of pale light, strongest at their middle and fading to their ends, with a soft glow: the room's top, the
    hairline between the doll and the grid, the rail, the card's sliding edge;
  - what's lit is the light itself: the chosen kind's chip, the ring round a chosen cell and the slot it would fill,
    the one action (Equip) as a plate of light with dark words;
  - an upright shaft of light behind the Voidkin on its stage, cut hard, as behind the chest's best.

Drawn in three states at a phone's size in landscape (812 x 375 points, 2 pixels a point): the full bag; an item chosen,
its card open; a new account's empty bag. Then close-ups (the cells by rarity, Legendary's well today and proposed, the
chips, Equip), the palette in the kit's keys for Faber's rebuild, and a glance at the phone's own size. Text is
Blender's face standing in for the game's; the figure is Rook's sheet model in Workbench, standing in for the game's.

    blender -b --factory-startup --python tools/blender/bag_seam.py -- build/handoff/UI/inventory
"""
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_icons as gi  # noqa: E402
import inventory_directions as inv  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from inventory_directions import GEAR, H, K, RARITY, W, circle, mix, poly, rrect, vramp  # noqa: E402
from ui_sheet import c  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
UI_ART = REPO / "build" / "handoff" / "UI"

# The seam's palette, in the kit's keys (Config.UIKit.Palettes), for Faber's rebuild; `Light` is the seam's own.
SEAM = {
    "Backing": "#07060C",                    # behind the screen
    "Panel": ("#1A1430", "#0C0A16"),         # the room, top to foot (A's inside, its middle to its edge)
    "Card": ("#221A3C", "#0E0B18"),          # the card over the room, a step up
    "Well": ("#1B1728", "#0C0A13"),          # a cell's and a slot's well, top to foot (A's tile)
    "Channel": "#050409",                    # under a number, a seat, a bar's empty
    "Edge": "#3B3358",                       # a resting edge: a slot, a chip, a button
    "Light": "#EDE4FF",                      # the seam's light: lit edges, rings, the lit chip, Equip
    "Facet": "#8F84B8", "Glint": "#DCD3FF",  # a button's bevel
    "Text": "#F1ECFF", "Soft": "#B9B0D6", "Faint": "#6F6790",
    "Ink": "#0B0913",                        # words on the light
    "Button": ("#2A2244", "#1A1530"), "Pressed": ("#120E20", "#1A1430"),
    "Ground": "#1E1A2C",                     # the stage's floor
}
UP, DOWN, POWER = "#7CF0A4", "#FF7A66", ("#FFFFFF", "#9DBBF5", "#4A7BF5")
CREDITS = "#EEC65C"

# Where things stand, in points (Faber's still at 2.35 pixels a point)
ROOM = (63.0, 30.0, 806.0, 375.0)
RAIL_X, RAIL_YS, RAIL_CHOSEN = 31.0, (46.0, 89.0, 143.0, 180.0, 216.0, 264.0, 312.0), 1
PAGES = ("PageOverview", "PageBag", "PageKit", "PageStars", "PageForge", "PageJewels", "PageEmblems")
SOON = {"PageForge", "PageJewels", "PageEmblems"}
SLOT, PITCH, LEFT_X, RIGHT_X, SLOTS_Y = 46.0, 51.0, 66.0, 235.0, 50.0
LEFT = ("Helmet", "Shoulders", "Chest Armor", "Gloves", "Bracers", "Boots")
RIGHT = ("Cloak", "Amulet", "Ring I", "Ring II", "Earring I", "Earring II")
HANDS = (("Main Hand", 124.0), ("Off Hand", 175.0))
STAGE = (113.0, 50.0, 233.0, 260.0)
FIGURE_CX, FIGURE_FOOT, FIGURE_TALL = 173.0, 257.0, 148.0
PLATE = (113.0, 260.0, 233.0, 302.0)
SEAM_X = 286.0
GRID_X, GRID_Y, CELL, CELL_PITCH, ACROSS = 293.0, 75.0, 46.5, 51.6, 10
CHIPS = (("All", 290.0, 328.0), ("Weapons", 331.0, 382.0), ("Armour", 384.0, 426.0), ("Jewellery", 429.0, 481.0),
         ("Chests", 483.0, 524.0), ("Materials", 526.0, 576.0))
SORT = ("Sort: Rarity", 744.0, 803.0)
CHIP_Y = (38.0, 64.0)
CARD = (583.0, 30.0, 806.0, 375.0)  # the doll's width, at the room's right edge

# The content: Rook's bag, sorted by rarity, then the chests and the shards
ORDER = ("Legendary", "Epic", "Rare", "Uncommon", "Common")
ITEMS = sorted(inv.BAG[:16], key=lambda s: ORDER.index(GEAR[s]["rarity"]))
CHESTS = (("ChestKeeper", 1), ("ChestElite", 3), ("ChestShade", 5), ("ChestTower", 1))
HELD = {"Helmet": "GearTomoshibi", "Ring I": "GearStormcallLoop", "Main Hand": "GearStormcallBlade",
        "Off Hand": "GearEdgeOfEmbers"}
RAISES = {"GearKiribi", "GearYoiboshi", "GearGloamforgeEdge", "GearZansho"}
CHOSEN = dict(stem="GearKiribi", slot="Main Hand", kind="Sword", against="GearStormcallBlade", power="+1,238",
              basic=(("Might", "82", "+18"), ("Finesse", "35", "+4")),
              battle=(("Attack", "1,412", "+226"), ("Hit", "18.4%", "+2.6%"), ("Critical", "9.1%", "+0.8%")))
ROOK = dict(who="Rook", rarity="Common", cls="Warrior", level=5, power="15,318")
NEW = dict(ROOK, level=1, power="1,204", new=True)


def edge_light(t, d, profile, width=1.0, glow=4.0, cover=0.42, colour=None, outward=False):
    """A seam edge: a line of light along an outline `d`, its strength `profile` (0 to 1) along its length. Its glow
    spreads either side of the line, or with `outward` only outside a shape, so a ring never fills what it rings."""
    col = c(colour or SEAM["Light"])
    spread = np.where(d >= 0, d, 1e3) if outward else np.abs(d) - width * 0.6
    t.glow(spread, glow, col, np.clip(cover * profile, 0, 1))
    t.paint(np.abs(d) - width / 2, col, np.clip(profile, 0, 1))


def along(v, mid, spread, floor=0.15):
    """How strong a seam edge is at `v` along it: full at its middle, falling to `floor` at its ends."""
    return floor + (1 - floor) * np.exp(-((v - mid) / spread) ** 2)


def picture(path, side):
    return inv.picture(path, side)


def cut(x0, y0, x1, y1, k):
    """The game's cell outline: square, its top left and foot right cut."""
    return ui.cut_box(x0, y0, x1, y1, k, 0.0, k, 0.0)


# --- the pieces -------------------------------------------------------------------------------------------------------

def gear_cell(scr, x, y, s, stem, ring=False, raises=False, worn=False):
    """A cell on AR6's assembly, its well in the seam's (gear_icons.slot draws it as the game lays its layers)."""
    g = GEAR[stem]
    icon = rs.load(UI_ART / "gear" / "images" / f"{stem}.png")
    gi.slot(scr.sheet, scr.ox + x, scr.oy + y, s, g["rarity"], icon, z=s / 48.0,
            mark="Warrior" if g["kind"] in inv.WEAPON else None)
    corner_marks(scr, x, y, s, raises, worn, ring)


def corner_marks(scr, x, y, s, raises, worn, ring):
    t = scr.area(x, y, x + s, y + s, 24)
    if raises:
        t.paint(rrect(t, x + s - 15, y + 2, x + s - 3, y + 14, 2), c(SEAM["Channel"]), 0.85)
        inv.up_arrow(t, x + s - 9, y + 4, 8.0, UP)
    if worn:
        t.paint(rrect(t, x + 3, y + s - 15, x + 15, y + s - 3, 2), c(SEAM["Channel"]), 0.85)
        inv.tick(t, x + 9, y + s - 9, 7.0, SEAM["Text"], 1.5)
    if ring:
        d = ui.sd_polygon(t.X, t.Y, cut(x, y, x + s, y + s, 8.0 * s / 48.0))
        edge_light(t, d - 3.0, 1.0, width=1.6, glow=5.0, cover=0.5, outward=True)


def plain_cell(scr, x, y, s, image=None, count=0, slot=None, ring=False):
    """A plain well: a chest, a shard, or an empty slot with its piece's mark."""
    t = scr.area(x, y, x + s, y + s, 24)
    d = ui.sd_polygon(t.X, t.Y, cut(x, y, x + s, y + s, 8.0 * s / 48.0))
    t.glow(d, 4.0, c("#000000"), 0.22)
    t.paint(d, vramp(t, SEAM["Well"][0], SEAM["Well"][1], y, y + s))
    t.line(d, 1.0, c(SEAM["Edge"]))
    if slot:
        name = {"Chest Armor": "ChestArmor", "Ring I": "Ring", "Ring II": "Ring", "Earring I": "Earring",
                "Earring II": "Earring", "Main Hand": "MainHandWarrior", "Off Hand": "OffHandWarrior"}.get(slot, slot)
        px = picture(UI_ART / "slots" / "images" / f"SlotEmpty{name}.png", s * 32 / 44).copy()
        px[..., :3] = c(SEAM["Faint"])
        px[..., 3] *= 0.55
        scr.paste(px, x + s / 2 - px.shape[1] / K / 2, y + s / 2 - px.shape[0] / K / 2)
    if image is not None:
        scr.paste(picture(image, s * 0.9), x + s * 0.05, y + s * 0.03)
    if count > 1:
        scr.text(x + s - 4, y + s - 13, 10, f"×{count}", SEAM["Text"], "RIGHT", bold=0.25)
    if ring:
        edge_light(t, d - 3.0, 1.0, width=1.6, glow=5.0, cover=0.5, outward=True)


def backing(scr):
    t = scr.area(0, 0, W, H)
    t.paint(t.X * 0 - 1, c(SEAM["Backing"]))
    x0, y0, x1, y1 = ROOM
    d = rrect(t, x0, y0, x1, y1 + 20, 6.0)
    t.paint(d, vramp(t, SEAM["Panel"][0], SEAM["Panel"][1], y0, y1), 0.94)
    # the room's top edge: the seam's light, strongest over the room's middle
    top = np.maximum(np.abs(t.Y - y0) - 0.0, np.maximum(x0 + 6 - t.X, t.X - (x1 - 6)))
    edge_light(t, top, along(t.X, (x0 + x1) / 2, 300.0, 0.12), width=1.0, glow=4.0, cover=0.4)


def top_bar(scr, who):
    t = scr.area(80, 0, W, 30)
    for x0, x1 in ((87.0, 135.0), (141.0, 163.0), (167.0, 189.0), (193.0, 215.0)):
        d = rrect(t, x0, 4, x1, 25, 3.0)
        t.paint(d, vramp(t, SEAM["Button"][0], SEAM["Button"][1], 4, 25))
        t.line(d, 1.0, c(SEAM["Edge"]))
        t.paint(np.maximum(d + 0.5, np.abs(t.Y - 24.0) - 0.6), c(SEAM["Light"]), 0.75)  # its foot lit, the kit's base
    scr.mid(111, 14.5, 10, "Back", SEAM["Text"], "CENTER", bold=0.25)
    for cx, glyph in ((152.0, "PageForge"), (178.0, "LockOff"), (204.0, "Rename")):
        inv.mark(scr, glyph, cx, 14.5, 10.0, SEAM["Text"])
    for x0, x1, word, colour in ((607.0, 670.0, "3,453", CREDITS), (676.0, 806.0, "60.00 / 60 kWh", SEAM["Text"])):
        d = rrect(t, x0, 4, x1, 25, 3.0)
        t.paint(d, c(SEAM["Channel"]), 0.85)
        t.line(d, 1.0, c(SEAM["Edge"]), 0.8)
        scr.mid(x1 - 7, 14.5, 10, word, SEAM["Text"], "RIGHT", bold=0.25)
    t.paint(circle(t, 616.0, 14.5, 4.5), c(CREDITS))
    t.paint(poly(t, [(686.0, 9.0), (682.0, 15.5), (685.5, 15.5), (683.5, 20.5), (689.0, 13.0), (685.5, 13.0)]), c("#FFE266"))


def rail(scr):
    """The rail: a seam of light down the left, each page's mark on it; the chosen page ringed in light."""
    t = scr.area(0, 30, 62, 375)
    line = np.maximum(np.abs(t.X - RAIL_X) - 0.0, np.abs(t.Y - 180.0) - 150.0)
    edge_light(t, line, along(t.Y, RAIL_YS[RAIL_CHOSEN], 140.0, 0.2) * 0.75, width=1.0, glow=3.0, cover=0.35)
    for i, (page, y) in enumerate(zip(PAGES, RAIL_YS)):
        r = 17.0 if i == RAIL_CHOSEN else 10.5
        d = circle(t, RAIL_X, y, r)
        t.paint(d - 2.0, c(SEAM["Backing"]))
        t.paint(d, vramp(t, SEAM["Button"][0], SEAM["Button"][1], y - r, y + r))
        if i == RAIL_CHOSEN:
            edge_light(t, d, 1.0, width=1.6, glow=5.0, cover=0.55, outward=True)
        else:
            t.line(d, 1.0, c(SEAM["Edge"]))
    for i, (page, y) in enumerate(zip(PAGES, RAIL_YS)):
        chosen = i == RAIL_CHOSEN
        inv.mark(scr, page, RAIL_X, y, 14.0 if chosen else 9.0, SEAM["Text"] if chosen else SEAM["Soft"],
                 0.4 if page in SOON else 1.0)
        if chosen:
            scr.mid(RAIL_X, y + 26, 9, "Items", SEAM["Text"], "CENTER", bold=0.25)
        elif page in SOON:
            scr.mid(RAIL_X, y + 17, 8, "Soon", SEAM["Faint"], "CENTER")


def doll(scr, who, target=None):
    held = {} if who.get("new") else HELD
    x0, y0, x1, y1 = STAGE
    t = scr.area(x0, y0, x1, y1 + 4)
    inside = np.maximum.reduce([x0 - t.X, t.X - x1, y0 - t.Y, t.Y - y1])
    t.paint(inside, vramp(t, "#140F25", "#0A0812", y0, y1), 0.6)
    t.paint(inside, c(SEAM["Light"]), 0.13 * np.exp(-((t.X - FIGURE_CX) / 26.0) ** 2))  # the shaft, cut at the stage
    floor = np.hypot((t.X - FIGURE_CX) / 3.4, t.Y - FIGURE_FOOT) - 7.0
    t.paint(floor, c(SEAM["Ground"]), 0.9)
    edge_light(t, floor, 0.55, width=0.8, glow=3.0, cover=0.3, outward=True)
    inv.figure(scr, dict(who="Rook"), FIGURE_CX, FIGURE_FOOT + 2, FIGURE_TALL)
    scr.mid(118, 58, 13, who["who"], SEAM["Text"], bold=0.3)
    scr.mid(118 + inv.width(who["who"], 13) * 0.9 + 4, 59, 9, who["rarity"], RARITY[who["rarity"]])
    scr.mid(118, 74, 9, f"Lv {who['level']}  {who['cls']}", SEAM["Soft"])
    for column, x in ((LEFT, LEFT_X), (RIGHT, RIGHT_X)):
        for i, slot in enumerate(column):
            y = SLOTS_Y + i * PITCH
            if held.get(slot):
                gear_cell(scr, x, y, SLOT, held[slot], ring=slot == target)
            else:
                plain_cell(scr, x, y, SLOT, slot=slot, ring=slot == target)
    for slot, x in HANDS:
        y = SLOTS_Y + 5 * PITCH
        if held.get(slot):
            gear_cell(scr, x, y, SLOT, held[slot], ring=slot == target)
        else:
            plain_cell(scr, x, y, SLOT, slot=slot, ring=slot == target)
    # Combat Power on its plate, a line of light along its top
    px0, py0, px1, py1 = PLATE
    t = scr.area(px0, py0 - 16, px1, py1)
    d = np.maximum.reduce([px0 - t.X, t.X - px1, py0 - t.Y, t.Y - py1])
    t.paint(d, vramp(t, "#120E22", SEAM["Channel"], py0, py1), 0.92)
    edge_light(t, np.maximum(np.abs(t.Y - py0), np.maximum(px0 - t.X, t.X - px1)),
               along(t.X, (px0 + px1) / 2, 46.0, 0.0), width=1.0, glow=3.0, cover=0.45)
    scr.mid((px0 + px1) / 2, py0 + 9, 8, "COMBAT POWER", SEAM["Soft"], "CENTER", bold=0.15)
    scr.mid((px0 + px1) / 2, py0 + 27, 19, who["power"], "#C9DBFF", "CENTER", bold=0.45)
    # the hairline between the doll and the grid: the seam, strongest at its middle
    t = scr.area(SEAM_X - 22, 34, SEAM_X + 22, 372)
    edge_light(t, np.maximum(np.abs(t.X - SEAM_X), np.abs(t.Y - 202.0) - 166.0), along(t.Y, 202.0, 120.0, 0.12),
               width=1.0, glow=4.0, cover=0.4)


def chip(t, scr, word, x0, x1, lit):
    y0, y1 = CHIP_Y
    d = rrect(t, x0, y0, x1, y1, (y1 - y0) / 2)
    if lit:
        t.glow(d, 5.0, c(SEAM["Light"]), 0.3)
        t.paint(d, vramp(t, "#FFFFFF", SEAM["Light"], y0, y1))
    else:
        t.paint(d, c(SEAM["Well"][1]), 0.7)
        t.line(d, 1.0, c(SEAM["Edge"]))
    scr.mid((x0 + x1) / 2, (y0 + y1) / 2, 9, word, SEAM["Ink"] if lit else SEAM["Soft"], "CENTER", bold=0.3 if lit else 0.15)


def strip(scr):
    t = scr.area(GRID_X - 24, CHIP_Y[0] - 24, ROOM[2], CHIP_Y[1] + 10)
    for word, x0, x1 in CHIPS:
        chip(t, scr, word, x0, x1, word == "All")
    chip(t, scr, *SORT, False)


def grid(scr, who, chosen=None):
    if who.get("new"):
        cx = (GRID_X + ROOM[2]) / 2
        scr.mid(cx, 196, 13, "No gear yet", SEAM["Text"], "CENTER", bold=0.3)
        scr.mid(cx, 216, 10, "Shades and keepers drop it", SEAM["Soft"], "CENTER")
        scr.mid(GRID_X - 3, 365, 9, "0 / 300 in the bag", SEAM["Faint"], bold=0.2)
        return
    things = [("gear", s) for s in ITEMS] + [("chest", s) for s in CHESTS] + [("shard", ("shard_standard_small", 14))]
    for i, (kind, what) in enumerate(things):
        x, y = GRID_X + (i % ACROSS) * CELL_PITCH, GRID_Y + (i // ACROSS) * CELL_PITCH
        if kind == "gear":
            gear_cell(scr, x, y, CELL, what, ring=chosen == what, raises=what in RAISES,
                      worn=what in HELD.values())
        elif kind == "chest":
            plain_cell(scr, x, y, CELL, UI_ART / "chests" / "images" / f"{what[0]}.png", what[1])
        else:
            plain_cell(scr, x, y, CELL, UI_ART / "shards" / f"{what[0]}.png", what[1])
    scr.mid(GRID_X - 3, 365, 9, f"{len(ITEMS)} / 300 in the bag", SEAM["Faint"], bold=0.2)


def equip(scr, x0, y0, x1, y1, word, lit=True):
    t = scr.area(x0, y0, x1, y1, 28)
    d = rrect(t, x0, y0, x1, y1, 4.0)
    if lit:
        t.glow(d, 6.0, c(SEAM["Light"]), 0.3)
        t.paint(d, vramp(t, "#FFFFFF", SEAM["Light"], y0, y1))
        t.paint(np.maximum(d, -(t.Y - (y1 - 2.5))), c(SEAM["Facet"]), 0.8)  # the kit's base along its foot
        scr.mid((x0 + x1) / 2, (y0 + y1) / 2 - 1, 13, word, SEAM["Ink"], "CENTER", bold=0.35)
    else:
        t.paint(d, vramp(t, SEAM["Button"][0], SEAM["Button"][1], y0, y1), 0.9)
        t.line(d, 1.0, c(SEAM["Edge"]))
        scr.mid((x0 + x1) / 2, (y0 + y1) / 2, 13, word, SEAM["Faint"], "CENTER", bold=0.2)


def card(scr, chosen):
    x0, y0, x1, y1 = CARD
    t = scr.area(x0 - 44, y0, x1, y1)
    d = np.maximum.reduce([x0 - t.X, t.X - x1, y0 - t.Y, t.Y - y1])
    t.glow(d, 10.0, c("#000000"), 0.45)
    t.paint(d, vramp(t, SEAM["Card"][0], SEAM["Card"][1], y0, y1))
    # its sliding edge: the seam's light down its left, strongest at its middle
    edge_light(t, np.maximum(np.abs(t.X - x0), np.maximum(y0 - t.Y, t.Y - y1)), along(t.Y, 190.0, 110.0, 0.15),
               width=1.0, glow=4.0, cover=0.45)
    g, pad = GEAR[chosen["stem"]], 10.0
    lx, rx = x0 + pad, x1 - pad
    gear_cell(scr, lx, y0 + 10, 50.0, chosen["stem"])
    scr.mid(lx + 60, y0 + 22, 10, g["rarity"], RARITY[g["rarity"]], bold=0.3)
    scr.mid(lx + 60, y0 + 38, 9, chosen["kind"], SEAM["Soft"])
    t = scr.area(rx - 16, y0 + 8, rx + 2, y0 + 26)
    for a, b in (((rx - 13, y0 + 11), (rx - 1, y0 + 23)), ((rx - 13, y0 + 23), (rx - 1, y0 + 11))):
        t.paint(inv.seg(t, a, b) - 0.9, c(SEAM["Text"]))
    y = y0 + 76
    scr.mid(lx, y, 12, g["name"], SEAM["Text"], bold=0.3)
    y += 14
    t = scr.area(lx - 2, y, rx + 2, y + 30)
    plate = rrect(t, lx, y, rx, y + 28, 3.0)
    t.paint(plate, c(SEAM["Channel"]), 0.85)
    scr.mid(lx + 8, y + 14, 9, "Combat Power", SEAM["Soft"])
    scr.mid(rx - 20, y + 14, 14, chosen["power"], UP, "RIGHT", bold=0.4)
    inv.up_arrow(t, rx - 10, y + 8, 11.0, UP)
    y += 40
    scr.mid(lx, y, 9, "for", SEAM["Faint"])
    against = GEAR[chosen["against"]]
    scr.mid(lx + 18, y, 9, against["name"], RARITY[against["rarity"]], bold=0.25)
    y += 12
    t = scr.area(lx, y, rx, y + 2)
    t.paint(np.maximum(np.abs(t.Y - y - 0.5) - 0.4, np.maximum(lx - t.X, t.X - rx)), c(SEAM["Edge"]))
    y += 14
    for caption, rows in (("Basic", chosen["basic"]), ("Battle", chosen["battle"])):
        scr.mid(lx, y, 9, caption, SEAM["Glint"], bold=0.35)
        y += 15
        for name, value, delta in rows:
            scr.mid(lx, y, 9, name, SEAM["Soft"])
            scr.mid(rx - 44, y, 9, value, SEAM["Text"], "RIGHT", bold=0.2)
            scr.mid(rx, y, 9, delta.replace("-", "−"), UP if delta.startswith("+") else DOWN, "RIGHT", bold=0.25)
            y += 15
        y += 5
    equip(scr, lx, 318.0, rx, 360.0, "Equip")


def screen(state):
    who = NEW if state == "empty" else ROOK
    chosen = CHOSEN if state == "chosen" else None
    sheet = ui.Sheet(W, H, SEAM["Backing"])
    scr = inv.Screen(sheet, 0, 0)
    backing(scr)
    top_bar(scr, who)
    rail(scr)
    doll(scr, who, target=chosen["slot"] if chosen else None)
    strip(scr)
    grid(scr, who, chosen["stem"] if chosen else None)
    if chosen:  # the words under the card go with what it covers (they're drawn last, over everything)
        sheet.items = [i for i in sheet.items if not (i["x"] >= CARD[0] - 1 and i["y"] >= CARD[1])]
        card(scr, chosen)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


# --- close-ups and the palette ----------------------------------------------------------------------------------------

def close_ups():
    """Each rarity's cell twice the size, Legendary's well today (umber) and proposed (the seam's); the chips; Equip."""
    w, h = 812.0, 150.0
    sheet = ui.Sheet(w, h, SEAM["Panel"][1])
    scr = inv.Screen(sheet, 0, 0)
    swords = [s for s in GEAR if GEAR[s]["kind"] in inv.WEAPON]
    cells = [(next(s for s in swords if GEAR[s]["rarity"] == r), r) for r in ORDER[:0:-1]]
    cells += [("GearKiribi", "Legendary, today"), ("GearKiribi", "Legendary, proposed")]
    x = 30.0  # a cell's frame reaches 10 points out at this size (gear_icons.slot's pad): kept inside the sheet
    for stem, word in cells:
        if word == "Legendary, today":
            gi.UMBER = ("#34200E", "#1A1007")
        elif word == "Legendary, proposed":
            gi.UMBER = SEAM["Well"]
        gear_cell(scr, x, 22, 92.0, stem)
        scr.text(x, 124, 10, word, SEAM["Soft"])
        x += 110.0
    gi.UMBER = SEAM["Well"]
    t = scr.area(664, 0, 812, 150)
    for i, (word, lit) in enumerate((("All", True), ("Weapons", False))):
        y0 = 26.0 + i * 34
        d = rrect(t, 696, y0, 786, y0 + 26, 13)
        if lit:
            t.glow(d, 5.0, c(SEAM["Light"]), 0.3)
            t.paint(d, vramp(t, "#FFFFFF", SEAM["Light"], y0, y0 + 26))
        else:
            t.paint(d, c(SEAM["Well"][1]), 0.7)
            t.line(d, 1.0, c(SEAM["Edge"]))
        scr.mid(741, y0 + 13, 10, word, SEAM["Ink"] if lit else SEAM["Soft"], "CENTER", bold=0.3)
    equip(scr, 696.0, 96.0, 786.0, 124.0, "Equip")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


def palette_strip():
    keys = [("Backing", SEAM["Backing"]), ("Panel, top", SEAM["Panel"][0]), ("Panel, foot", SEAM["Panel"][1]),
            ("Card, top", SEAM["Card"][0]), ("Well, top", SEAM["Well"][0]), ("Well, foot", SEAM["Well"][1]),
            ("Channel", SEAM["Channel"]), ("Edge", SEAM["Edge"]), ("Button", SEAM["Button"][0]),
            ("Ground", SEAM["Ground"]), ("Faint", SEAM["Faint"]), ("Soft", SEAM["Soft"]), ("Facet", SEAM["Facet"]),
            ("Glint", SEAM["Glint"]), ("Text", SEAM["Text"]), ("Light", SEAM["Light"])]
    w, h = 812.0, 66.0
    sheet = ui.Sheet(w, h, "#16161A")
    t = sheet.tile(0, 0, w, h)
    t.X, t.Y = t.x, t.y
    step = (w - 16) / len(keys)
    for i, (name, code) in enumerate(keys):
        x0 = 8 + i * step
        t.paint(rrect(t, x0, 6, x0 + step - 6, 34, 3), c(code))
        t.line(rrect(t, x0, 6, x0 + step - 6, 34, 3), 0.8, c("#3A3A44"))
        t.text(x0, 40, 8, name, "#B6B2C2")
        t.text(x0, 52, 8, code, "#8C889A")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


def rook_figure():
    """Rook standing, three-quarter front, in Workbench from his sheet's model: a stand-in for the game's figure."""
    scene = bl.reset_scene()
    joints = rs.build(scene, rs.CHOSEN)
    rs.POSES["idle"](joints)
    bpy.context.view_layer.update()
    meshes = [o for o in scene.objects if o.type == "MESH"]
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    low, high = Vector([min(q[i] for q in pts) for i in range(3)]), Vector([max(q[i] for q in pts) for i in range(3)])
    return rs.trim(ks.render(scene, "figure", 158, 6, (low + high) / 2, (high - low).length * 1.02, ks.PX))


# --- the sheet --------------------------------------------------------------------------------------------------------

STATES = (("full", "The full bag: Rook, nothing chosen (All)"),
          ("chosen", "A Legendary sword chosen: its card slides in at the room's right edge, its slot ringed in light"),
          ("empty", "A new account's empty bag"))
NOTES = (
    "The director's word (2026-11-17, 02:40), on AR24's A: the bag in the seam's colours, not the old yellow brown. The "
    "ledger's layout stays as the game builds it (TR28); only its skin changes. The rarities keep their own colours on "
    "the cells: AR6's assembly is unchanged, its well in the seam's violet-black.",
    "The seam's language, as in the chest opening: violet-black grounds; edges of pale light, strongest at their middle "
    "and fading to their ends, with a soft glow (the room's top, the hairline between the doll and the grid, the rail, the "
    "card's sliding edge, Combat Power's plate); what's lit is the light itself (the chosen kind's chip, the ring round a "
    "chosen cell and the slot it would fill, Equip as a plate of light with dark words); an upright shaft of light behind "
    "the Voidkin, cut at its stage.",
    "For Faber's rebuild: the palette above in the kit's keys, as UIKit.Palettes.Seam (Panel, Card, Well, Channel, Edge, "
    "Facet, Glint, Text, Soft, Faint, Button, Pressed, Ground) with Light as its accent. A seam edge is a 1 point line in "
    "Light over a 4 point glow at 0.4, its transparency ramped along its length (a UIGradient: full at the middle, about "
    "0.15 at the ends). Rings: 1.6 points of Light, 3 points out from the cell, a 5 point glow at 0.5. The lit chip and "
    "Equip: a ramp from white to Light, words in Ink, a 5 to 6 point glow at 0.3. The stage's shaft: Light at 0.13, 26 "
    "points either side of the figure's middle, cut at the stage.",
    "Proposed, Legendary's well: the seam's violet-black in place of AR6's warm umber (close-ups: today, then proposed). "
    "Its gilt frame and gold light stay its own. It's one number pair in build/handoff/UI/gear/gear_icons.json (the well's "
    "`legendary`), for research to take or leave.",
    "Open, the Overview: TR24's fix 4 gives the Voidkin screen one palette across its tabs, so the shell is drawn in the "
    "seam here. The director's word names the inventory; whether the Overview's stage and panel follow is the director's "
    "to say.",
    "Stand-ins: the text is Blender's face; the figure is Rook's sheet model in Workbench; every number is a seed.",
)
M, HEAD = 20.0, 46.0


def main():
    out = ks.OUT = rs.OUT = bl.out_dir()
    inv.FIGURES["Rook"] = rook_figure()
    gi.WELL, gi.CHANNEL = SEAM["Well"]
    gi.UMBER = SEAM["Well"]
    screens = [(caption, screen(key)) for key, caption in STATES]
    extras = [("Close: each rarity's cell (Legendary's well today, then proposed); the chips; Equip", close_ups()),
              ("The palette, in the kit's keys", palette_strip())]
    lines = [line for n in NOTES for line in textwrap.wrap(n, 140)]
    h = HEAD + sum(18 + px.shape[0] / K + 14 for _, px in screens + extras) + len(lines) * 16 + 16
    sheet = ui.Sheet(W + 2 * M, h, "#16161A")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(M, 14, 18, "Grow your Anime, the bag in the seam's colours (AR18, the ledger's layout)", "#ECE8F2", bold=0.2 * K)
    y = HEAD
    for caption, px in screens + extras:
        t.text(M, y, 13, caption, "#9C98A8")
        rs.paste(sheet.px, px, round(M * K), round((y + 18) * K))
        y += 18 + px.shape[0] / K + 14
    for i, line in enumerate(lines):
        t.text(M, y + i * 16, 12, line, "#9C98A8")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "bag_seam.png")
    phone = [rs.shrink(px, 1 / K) for _, px in screens]  # the phone's own size, a pixel a point
    strip_px = rs.canvas(3 * round(W) + 32, round(H), (0.09, 0.09, 0.11))
    for i, px in enumerate(phone):
        rs.paste(strip_px, px, i * (round(W) + 16), 0)
    rs.save(strip_px, out / "bag_seam_phone.png")


if __name__ == "__main__":
    main()
