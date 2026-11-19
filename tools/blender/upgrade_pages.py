"""AR43: the Menu (the dock's Inventory, renamed) on its three tabs; its Equipment tab's Reinforce page, where a worn
gear is reinforced, in every state; and the prompt when a new item replaces one. At the smallest phone. Drawn in code:
shapes and Blender's own face stand in for the kit's. Nothing is rendered, nothing is exported.

The director's words, 2026-11-19 (docs/decisions.md; AR43's record):
    the Menu   03:37-03:38: tabs down the left, Inventory, Equipment and Settings (Quest later); each tab's pages run
               across the top of its panel. Inventory: Overview, Kit, Inventory (the gear slots and the bag), Stars.
               Equipment: Reinforce, Jewels, War Emblems; jewels and emblems are managed on those pages only.
    Reinforce  03:14-03:17: only the worn gear, listed on the left; the chosen one's reinforce on the right, "exactly
               like this except ofc we dont use item that protect against fail"; no Voidkin, no Combat Power. The
               odds before every press, success and fail adding to 100; a fail spends the cost and the level stays.
Rates are research's seeds (100% to +5, then 80, 70, 60 ...); every other number is a stand-in. The Jewels and War
Emblems pages wait for the emblem's look and the jewel icons.

The screen's own colours (Config.UIKit, Palettes.Seam): the Voidkin screen is kept as it is (research's triage of AR40,
2026-11-17, 23:04), so the Menu wears it. One cell is drawn again in AR40's C to compare. The band is the screen's own
(AR29, B): Roblox's buttons, Back, the Voidkin's three marks on Inventory, the Credits and kWh. Inventory's Overview
is cut from Faber's capture of it at this size (build/scratch/faber/ar29/shots/phone-overview.png); without it, a
block stands in.

    blender -b --factory-startup --python tools/blender/upgrade_pages.py -- <abs out>

Writes:
    upgrade_menu.png         the Menu on Inventory, Equipment and Settings
    upgrade_equipment.png    Reinforce: ready, too few stones, never reinforced, succeeded, failed
    upgrade_transfer.png     the prompt, everything moves and some of it stays
    upgrade_palette.png      Reinforce in the screen's colours and in AR40's C
    upgrade_64.png           every phone at 64 pixels high, over dark
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

W, H = 568, 320          # the smallest phone, in points
SMALL, TITLE = 14, 17
REPO = Path(__file__).resolve().parents[2]
UI = REPO / "build" / "handoff" / "UI"
GEAR, UPG, CHROME = UI / "gear" / "images", UI / "upgrades" / "images", UI / "voidkin" / "chrome" / "images"
COIN = UI / "hud" / "colour" / "images" / "CoinMint.png"
CAPTURE = REPO / "build" / "scratch" / "faber" / "ar29" / "shots" / "phone-overview.png"
CUT = (slice(311, 692), slice(143, 883))   # the capture's page, right of its rail: the card, the stats, the roster

# The screen's own (Config.UIKit, Palettes.Seam and SeamLit), and AR40's C system panel for the one comparison.
SEAM = dict(backing="#07060C", panel=("#1A1430", "#0C0A16"), edge="#3B3358", facet="#8F84B8", glint="#DCD3FF",
            text="#F1ECFF", soft="#B9B0D6", faint="#6F6790", channel="#050409", well=("#1B1728", "#110E1B"),
            button=("#2A2244", "#1A1530"), light="#EDE4FF", ink="#0B0913", lit=("#FFFFFF", "#EDE4FF"),
            card=("#221A3C", "#0E0B18"))
C_SYS = dict(backing="#2E525C", panel=("#34606C", "#2A4E5A"), edge="#E2CFA4", facet="#8FC4C8", glint="#FFF6E2",
             text="#FFF6E2", soft="#D9E8E2", faint="#A9C0BC", channel="#0E1D23", well=("#21414A", "#1B3840"),
             button=("#447480", "#366270"), light="#F0E2C4", ink="#1E3238", lit=("#F0E2C4", "#DCCBA6"),
             card=("#3C6A76", "#2A4E5A"))
P = dict(SEAM)
GOOD, HURT = ui.GOOD, "#FF786E"                   # a gain, as the comparison's; Theme.Colour.Hurt
RIM = {"Common": "#8A909C", "Uncommon": "#7CF0A0", "Rare": "#6FB6FF", "Epic": "#D29CFF", "Legendary": "#FFD777"}

_over = ui.over
ui.over = lambda dst, colour, a: _over(dst, ui.c(colour) if isinstance(colour, str) else colour, a)  # codes, painted
_pics = {}

# Rook's worn set, hands first (stand-ins): slot, name, rarity, picture, level. The stat is the slot's (Config.Chests).
WORN = [
    ("Main Hand", "Blade of Embers", "Rare", "GearBladeOfEmbers.png", 7),
    ("Off Hand", "Rowsmith Short Sword", "Uncommon", "GearRowsmithShortSword.png", 4),
    ("Helmet", "Stormcall Helm", "Epic", "GearStormcallHelm.png", 5),
    ("Shoulders", "Iron Shoulders", "Common", "GearIronShoulders.png", 0),
    ("Chest Armor", "Cuirass of Hoarfrost", "Rare", "GearCuirassOfHoarfrost.png", 6),
    ("Gloves", "Rowsmith Gloves", "Uncommon", "GearRowsmithGloves.png", 3),
]
TABS = ("Inventory", "Equipment", "Settings")     # Quest joins when it's designed
PAGES = {"Inventory": ("Overview", "Kit", "Inventory", "Stars"), "Equipment": ("Reinforce", "Jewels", "War Emblems"),
         "Settings": ()}
# The pages' shipped icons (Inventory's is the bag's, Reinforce's the anvil); the tabs' Inventory shard and Settings
# cog are drawn here as stand-ins.
PAGE_ICON = {"Inventory": "Items", "Reinforce": "Forge", "War Emblems": "WarEmblems"}
TINY = 64 / (H * 2)                                # a phone at 64 pixels high, from the sheet's two pixels a point
STRIP, TOP, FOOT = 92, 100, 312                    # the tabs' strip's width; a page's top and foot under its pages


def wide_of(words, size):
    """About how wide Blender's face sets a line, in points (it runs nearer 0.48; this errs wide)."""
    return len(words) * size * 0.58


# --- the kit's pieces ----------------------------------------------------------------------------------------------

def shade(t, fill, y0, y1):
    return t.ramp(fill[0], fill[1], (t.y - y0) / max(y1 - y0, 1)) if isinstance(fill, tuple) else fill


def box(t, x0, y0, x1, y1, fill, line=None, lw=1.0, cut=3.0, cuts=None):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, *(cuts or (cut, cut, cut, cut))))
    t.paint(d, shade(t, fill, y0, y1))
    if line:
        t.line(d, lw, line)
    return d


def panel(t, x0, y0, x1, y1):
    """The screen's panel: the bag's cut (top left and foot right), its dark falling darker, a hairline edge."""
    return box(t, x0, y0, x1, y1, P["panel"], P["edge"], 1.0, cuts=(8, 0, 8, 0))


def pic(t, path, x, y, size, tint=None, alpha=1.0):
    """A picture of the game's at `size` points, its corner at x, y; a white mark takes `tint`."""
    key = (str(path), size, ui.K, tint)
    if key not in _pics:
        rgba = rs.load(path)
        rgba = rs.shrink(rgba, size * ui.K / rgba.shape[1])
        if tint:
            rgba = rgba.copy()
            rgba[..., :3] = rgba[..., :3] * ui.c(tint)
        _pics[key] = rgba
    img = _pics[key]
    if alpha != 1.0:
        img = img.copy()
        img[..., 3] *= alpha
    t.image(img, x, y)


def arrow(t, cx, cy, colour, s=10.0):
    t.stroke([(cx - s * 0.5, cy), (cx + s * 0.4, cy)], 1.6, colour)
    t.stroke([(cx + s * 0.05, cy - s * 0.36), (cx + s * 0.5, cy), (cx + s * 0.05, cy + s * 0.36)], 1.6, colour)


def check(t, cx, cy, r, colour):
    t.stroke([(cx - r * 0.55, cy), (cx - r * 0.12, cy + r * 0.42), (cx + r * 0.6, cy - r * 0.45)], r * 0.3, colour)


def press(t, x0, y0, x1, y1, words, kind="one"):
    fill, edge, colour = {"one": (P["lit"], P["light"], P["ink"]), "quiet": (P["button"], P["edge"], P["text"]),
                          "off": (P["well"], P["edge"], P["faint"])}[kind]
    if kind == "one":
        t.glow(t.poly(ui.cut_box(x0, y0, x1, y1, 5, 5, 5, 5)), 5.0, P["light"], 0.35)
    box(t, x0, y0, x1, y1, fill, edge, 1.0, 5)
    if words:
        t.text((x0 + x1) / 2, (y0 + y1) / 2 - 5, SMALL, words, colour, "CENTER", bold=0.3)


def mark(t, name, cx, cy, s, colour, alpha=1.0, tab=False):
    """A tab's or a page's mark, `s` points high."""
    if tab and name == "Inventory":
        pts = [(cx, cy - s * 0.5), (cx + s * 0.3, cy - s * 0.2), (cx + s * 0.22, cy + s * 0.32), (cx, cy + s * 0.5),
               (cx - s * 0.22, cy + s * 0.32), (cx - s * 0.3, cy - s * 0.2)]
        t.paint(t.poly(pts), colour, alpha)
        t.stroke([(cx, cy - s * 0.5), (cx + s * 0.05, cy + s * 0.12), (cx, cy + s * 0.5)], s * 0.07, P["ink"],
                 0.55 * alpha)
        return
    if tab and name == "Settings":
        teeth = [(cx + np.cos(a) * r, cy + np.sin(a) * r) for k in range(32)
                 for a, r in [(k * np.pi / 16 + np.pi / 32, s * (0.5 if k % 4 in (0, 1) else 0.36))]]
        hole = s * 0.15 - np.hypot(t.x - cx, t.y - cy)
        t.paint(np.maximum(t.poly(teeth), hole), colour, alpha)
        return
    icon = "Forge" if tab else PAGE_ICON.get(name, name)
    pic(t, CHROME / f"VoidkinPage{icon}.png", cx - s / 2, cy - s / 2, s, tint=colour, alpha=alpha)


def tab_glass(t, x0, y0, x1, y1):
    """A chosen thing's dark glass, washed with light toward its lit right edge (the rail's tab, a chosen row)."""
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 6, 0, 0, 0))
    t.paint(d, shade(t, P["card"], y0, y1))
    t.paint(d, P["light"], np.clip((t.x - x0) / (x1 - x0), 0, 1) ** 2 * 0.22)
    t.line(d, 1.0, P["facet"], 0.8)
    t.glow(t.poly([(x1 - 1.5, y0), (x1 + 1.5, y0), (x1 + 1.5, y1), (x1 - 1.5, y1)]), 3.0, P["light"], 0.55)
    t.stroke([(x1, y0), (x1, y1)], 2.4, P["light"])


# --- the frame: the band, the tabs down the left, a tab's pages across the top ---------------------------------------

def band(t, tab):
    """The screen's band: Roblox's buttons, Back, the Voidkin's three marks on Inventory, the Credits and kWh."""
    box(t, 6, 8, 160, 50, P["channel"], P["edge"], 1.0, 6)
    t.text(83, 15, SMALL, "Roblox's", P["faint"], "CENTER")
    t.text(83, 31, SMALL, "buttons", P["faint"], "CENTER")
    t.text(196, 22, SMALL, "<  BACK", P["text"], "CENTER", bold=0.3)
    t.stroke([(178, 44), (214, 44)], 1.4, P["light"], 0.8)
    if tab == "Inventory":
        box(t, 230, 8, 362, 50, P["channel"], P["edge"], 1.0, cuts=(0, 0, 6, 0))
        for k, name in enumerate(("VoidkinFavourite", "VoidkinLock", "VoidkinRename")):
            cx = 252 + k * 44
            pic(t, CHROME / f"{name}.png", cx - 11, 18, 22, tint=P["text"])
            if k:
                t.stroke([(cx - 22, 18), (cx - 22, 40)], 1.0, P["edge"])
    for x0, x1, words in ((372, 458, "15,274"), (464, 548, "60.00")):
        box(t, x0, 14, x1, 44, P["channel"], P["edge"], 1.0, 4)
        t.text(x1 - 8, 23, SMALL, words, P["text"], "RIGHT", bold=0.3)
    pic(t, COIN, 378, 20, 18)
    ui.bolt(t, 480, 29, 7)


def tabs(t, chosen):
    """The Menu's tabs in a darker strip down the left, each its mark over its word; the chosen one dark glass lit
    from its right edge, as the rail's was."""
    t.paint(t.poly([(0, 54), (STRIP, 54), (STRIP, H), (0, H)]), P["channel"])
    t.stroke([(STRIP, 54), (STRIP, H)], 1.0, P["edge"])
    for k, name in enumerate(TABS):
        y0 = 58 + k * 62
        cx, cy = (STRIP - 2) / 2, y0 + 29
        on = name == chosen
        if on:
            tab_glass(t, 2, y0, STRIP - 4, y0 + 58)
        mark(t, name, cx, cy - 9, 22, P["light"] if on else P["text"], 1.0 if on else 0.7, tab=True)
        t.text(cx, cy + 8, SMALL, name, P["text"] if on else P["soft"], "CENTER", bold=0.3 if on else 0.0)


def pages(t, tab, chosen, words=True):
    """A tab's own pages across the top of its panel, the chosen one's word lit over a gliding underline."""
    names = PAGES[tab]
    x0, x1, y0, y1 = STRIP + 6, 550, 52, 96
    wide = (x1 - x0) / len(names)
    t.stroke([(x0, y1), (x1, y1)], 1.0, P["facet"], 0.45)
    for k, name in enumerate(names):
        cx = x0 + wide * (k + 0.5)
        on = name == chosen
        span = wide_of(name, SMALL) * 0.84 + 26
        mark(t, name, cx - span / 2 + 9, (y0 + y1) / 2, 18, P["light"] if on else P["text"], 1.0 if on else 0.7)
        if words:                                  # under a card, no words: they lie over every shape
            t.text(cx - span / 2 + 24, (y0 + y1) / 2 - 6, SMALL, name, P["text"] if on else P["soft"],
                   bold=0.3 if on else 0.0)
        if on:
            u = t.poly([(cx - span / 2, y1 - 2.5), (cx + span / 2, y1 - 2.5), (cx + span / 2, y1), (cx - span / 2, y1)])
            t.glow(u, 4.0, P["light"], 0.5)
            t.paint(u, P["light"])


# --- Inventory -------------------------------------------------------------------------------------------------------

def overview(t, x0, y0, x1, y1):
    """The Voidkin screen's Overview as Faber built it, cut from the capture and fitted to the room it has."""
    key = ("page", x1 - x0, y1 - y0, ui.K)
    if key not in _pics:
        if CAPTURE.exists():
            crop = rs.load(CAPTURE)[CUT].copy()
            crop[..., 3] = 1.0
            scale = min((x1 - x0) / crop.shape[1], (y1 - y0) / crop.shape[0]) * ui.K
            _pics[key] = rs.shrink(crop, scale)
        else:
            _pics[key] = None
    img = _pics[key]
    if img is None:
        panel(t, x0, y0, x1, y1)
        return
    t.image(img, x0, y0)


def figure(t, x, y, w, cols=(150, 490)):
    """Rook as he stands on the Overview at this size, cut from Faber's capture, its edges eased into the stage. A
    block stands in when the capture isn't there."""
    key = ("figure", w, cols, ui.K)
    if key not in _pics:
        if CAPTURE.exists():
            crop = rs.load(CAPTURE)[338:548, cols[0]:cols[1]].copy()
            h, wd = crop.shape[:2]
            fy = np.clip(np.minimum(np.arange(h) / (h * 0.03), np.arange(h)[::-1] / (h * 0.16)), 0, 1)
            fx = np.clip(np.minimum(np.arange(wd), np.arange(wd)[::-1]) / (wd * 0.12), 0, 1)
            crop[..., 3] = fy[:, None] * fx[None, :]
            _pics[key] = rs.shrink(crop, w * ui.K / wd)
        else:
            _pics[key] = None
    img = _pics[key]
    if img is None:
        box(t, x + w * 0.38, y + 6, x + w * 0.62, y + 120, "#4A4458", cut=4)
        return
    t.image(img, x, y)


# --- Equipment: Reinforce --------------------------------------------------------------------------------------------

def cell(t, x, y, s, rarity, image, rank=None):
    """An item's cell as the bag's: its well, its rarity's tint, light and rim, the picture at 0.94; the level on the
    foot-left corner and nothing else."""
    d = t.poly(ui.cut_box(x, y, x + s, y + s, s * 0.14, 0, s * 0.14, 0))
    t.paint(d, t.ramp("#0B0C10", "#07080B", (t.y - y) / s))
    rim = RIM[rarity]
    t.paint(d, rim, 0.112 if rarity == "Common" else 0.14)
    t.paint(d, rim, 0.3 * np.exp(-(((t.x - x - s / 2) / (s * 0.5)) ** 2 + ((t.y - y - s * 0.62) / (s * 0.5)) ** 2)))
    pic(t, image, x + s * 0.03, y + s * 0.03, s * 0.94)
    t.line(d, 1.5, rim)
    if rank:
        box(t, x + 1.5, y + s - 17, x + 23, y + s - 1.5, P["channel"], cut=0)
        t.text(x + 12, y + s - 15, SMALL, f"+{rank}", P["text"], "CENTER", bold=0.3)
    return d


def gear_list(t, st, x0, x1):
    """The worn gear, a row each: picture, name, level; the chosen row lit, pointing at the work. It scrolls: a row
    the panel's foot cuts shows its cell and no words."""
    panel(t, x0, TOP, x1, FOOT)
    rows = t.sheet.tile(t.ox, t.oy, W, FOOT - 1)
    for k, (slot, name, rarity, image, level) in enumerate(WORN):
        y = TOP + 4 + k * 50
        if y > FOOT:
            break
        chosen = slot == st["slot"]
        if chosen:
            tab_glass(rows, x0 + 3, y, x1 - 3, y + 46)
            rows.paint(rows.poly([(x1 - 3, y + 15), (x1 + 6, y + 23), (x1 - 3, y + 31)]), P["light"])
        else:
            box(rows, x0 + 3, y, x1 - 3, y + 46, P["well"], P["edge"], 1.0, cuts=(6, 0, 0, 0))
        cell(rows, x0 + 6, y + 3, 40, rarity, GEAR / image)
        if y + 40 > FOOT:
            continue
        level = st["rank"][0] if chosen else level
        colour = {"rose": GOOD, "failed": HURT}.get(st.get("done")) if chosen else None
        rows.text(x0 + 54, y + 5, SMALL, name, P["text"], bold=0.3)
        rows.text(x0 + 54, y + 24, SMALL, "Reinforce", P["soft"])
        rows.text(x0 + 54 + wide_of("Reinforce", SMALL) * 0.8 + 3, y + 24, SMALL, f"+{level}", colour or P["light"],
                  bold=0.35)


def ring(t, cx, cy, r, lit):
    d = np.hypot(t.x - cx, t.y - cy) - r
    t.glow(t.poly([(cx - 1, cy - 1), (cx + 1, cy - 1), (cx + 1, cy + 1), (cx - 1, cy + 1)]), r * 0.9, lit or P["glint"],
           0.18)
    t.line(d, 1.6, lit or P["light"], 0.9)
    t.line(d - 4, 1.0, P["facet"], 0.5)


def work(t, st, x0, x1):
    """The chosen gear in a ring with its stone under it, its level and stat now and after on either side, the odds,
    what's held, the cost and one press."""
    y0 = TOP
    panel(t, x0, y0, x1, FOOT)
    slot, name, rarity, image, _ = next(w for w in WORN if w[0] == st["slot"])
    cx = (x0 + x1) / 2
    t.text(cx, y0 + 6, SMALL, name, RIM[rarity], "CENTER", bold=0.3)
    lit = {"rose": GOOD, "failed": HURT}.get(st.get("done"))
    ring(t, cx, y0 + 50, 27, lit)
    cell(t, cx - 20, y0 + 30, 40, rarity, GEAR / image)
    a, b = st["rank"]
    stat, now, after, gain = st["stat"]
    t.text(x0 + 10, y0 + 28, SMALL, "Reinforce", P["soft"])
    t.text(x0 + 10, y0 + 44, TITLE, f"+{a}", lit or P["light"], bold=0.4)
    t.text(x0 + 10, y0 + 66, SMALL, f"{stat} {now}", P["text"])
    t.text(x1 - 10, y0 + 28, SMALL, "Reinforce", P["soft"], "RIGHT")
    t.text(x1 - 10, y0 + 44, TITLE, f"+{b}", P["light"], "RIGHT", bold=0.4)
    t.text(x1 - 10, y0 + 66, SMALL, f"{stat} {after}", P["text"], "RIGHT")
    t.text(x1 - 10, y0 + 82, SMALL, gain, GOOD, "RIGHT", bold=0.3)
    stone = cell(t, cx - 13, y0 + 82, 26, "Common", UPG / f"Stone{st['stone']}.png")
    t.line(stone, 1.0, P["edge"])
    rate = st["rate"]                              # the odds, before every press, adding to 100
    t.text(cx - 6, y0 + 113, SMALL, f"Success {rate}%", P["light"], "RIGHT", bold=0.35)
    t.text(cx, y0 + 113, SMALL, "·", P["faint"], "CENTER")
    t.text(cx + 6, y0 + 113, SMALL, f"Fail {100 - rate}%", P["soft"], bold=0.2)
    lines(t, x0, y0 + 132, st)
    cost(t, cx, FOOT - 2, st)


def lines(t, x0, y, st):
    stones = f"{st['stone']} stones"
    if st["have"] < st["need"]:
        said = [(f"You have {st['have']} {stones}: {st['need'] - st['have']} short", HURT),
                ("The Stone Condenser makes them", P["soft"])]
    elif st.get("done") == "rose":
        said = [(f"Reinforced to +{st['rank'][0]}", GOOD), (f"You have {st['have']} {stones}", P["soft"])]
    elif st.get("done") == "failed":
        said = [(f"Failed: it stays at +{st['rank'][0]}", HURT),
                (f"Spent {st['need']} {stones} and {st['credits']} Credits", P["soft"])]
    else:
        said = [(f"You have {st['have']} {stones}", P["soft"])]
    for k, (words, colour) in enumerate(said):
        t.text(x0 + 10, y + k * 17, SMALL, words, colour, bold=0.3 if colour in (GOOD, HURT) else 0.0)


def cost(t, cx, y1, st):
    """The cost in two pills, what's short in red, and the press: lit when it can go, the well's plate when not."""
    short = st["have"] < st["need"]
    x0, y0 = cx - 115, y1 - 44
    box(t, x0, y0 + 6, x0 + 64, y1 - 6, P["channel"], P["edge"], 1.0, 4)
    pic(t, UPG / f"Stone{st['stone']}.png", x0 + 4, y0 + 11, 22)
    t.text(x0 + 58, y0 + 15, SMALL, f"x{st['need']}", HURT if short else P["text"], "RIGHT", bold=0.3)
    box(t, x0 + 70, y0 + 6, x0 + 144, y1 - 6, P["channel"], P["edge"], 1.0, 4)
    pic(t, COIN, x0 + 74, y0 + 13, 18)
    t.text(x0 + 138, y0 + 15, SMALL, st["credits"], P["text"], "RIGHT", bold=0.3)
    press(t, x0 + 150, y0, x0 + 230, y1, "Reinforce", "off" if short else "one")


# --- Settings --------------------------------------------------------------------------------------------------------

def slider(t, x0, x1, cy, value):
    """A conduit filling with light to the value, its knob a disc of light (the kit's bars: docs/ui.md, rule 3)."""
    at = x0 + (x1 - x0) * value
    box(t, x0, cy - 4, x1, cy + 4, P["channel"], P["edge"], 1.0, 0)
    fill = t.poly([(x0 + 1, cy - 3), (at, cy - 3), (at, cy + 3), (x0 + 1, cy + 3)])
    t.paint(fill, t.ramp(P["facet"], P["light"], (t.x - x0) / max(at - x0, 1)))
    knob = np.hypot(t.x - at, t.y - cy) - 10
    t.glow(knob, 5.0, P["light"], 0.35)
    t.paint(knob, P["light"])
    t.line(knob, 1.0, P["facet"])


def settings(t, x0, x1):
    """Settings, plain: three sliders, each row 60 points high. No pages, so its panel starts under the band."""
    panel(t, x0, 56, x1, FOOT)
    for k, (name, value) in enumerate((("Music", 0.7), ("Sound", 0.85), ("Effects", 1.0))):
        cy = 94 + k * 60
        t.text(x0 + 18, cy - 7, SMALL, name, P["text"], bold=0.3)
        slider(t, x0 + 110, x1 - 70, cy, value)
        t.text(x1 - 18, cy - 7, SMALL, f"{round(value * 100)}%", P["soft"], "RIGHT")
        if k:
            t.stroke([(x0 + 14, cy - 30), (x1 - 14, cy - 30)], 1.0, P["edge"], 0.7)


# --- the phone ------------------------------------------------------------------------------------------------------

def menu(t, st):
    tab = st.get("tab", "Equipment")
    page = st.get("page", PAGES[tab][0] if PAGES[tab] else None)
    left = STRIP + 6
    box(t, 0, 0, W, H, P["backing"], cut=0)
    band(t, tab)
    tabs(t, tab)
    if PAGES[tab]:
        pages(t, tab, page, words=not st.get("transfer"))
    if tab == "Inventory":
        if st.get("transfer"):
            mid = (left + 550) / 2
            panel(t, left, TOP, mid - 3, FOOT)
            figure(t.sheet.tile(t.ox + left, t.oy + TOP, mid - 3 - left, FOOT - TOP), 10, 12, 180)
            panel(t, mid + 3, TOP, 550, FOOT)
        else:
            overview(t, left, TOP, 550, FOOT + 2)
    elif tab == "Equipment":
        gear_list(t, st, left, 300)
        work(t, st, 306, 550)
    else:
        settings(t, left, 550)


def phone(sheet, ox, oy, st):
    global P
    keep = P
    P = dict(C_SYS if st.get("palette") == "C" else SEAM)
    t = sheet.tile(ox, oy, W, H)
    menu(t, st)
    if st.get("transfer"):
        prompt(t, st)
    P = keep


def prompt(t, st):
    """The one card when a new item replaces one that holds levels or emblems: what moves and what can't."""
    t.paint(t.poly([(0, 0), (W, 0), (W, H), (0, H)]), P["channel"], 0.62)
    x0, y0, x1, y1 = 124, 62, 444, 314
    t.glow(t.poly(ui.cut_box(x0, y0, x1, y1, 10, 0, 10, 0)), 8.0, P["channel"], 0.8)
    box(t, x0, y0, x1, y1, P["card"], P["facet"], 1.0, cuts=(10, 0, 10, 0))
    cx = (x0 + x1) / 2
    t.text(cx, y0 + 10, TITLE, "Move the upgrades across?", P["text"], "CENTER", bold=0.3)
    (oname, orar, oimg, orank), (nname, nrar, nimg) = st["old"], st["new"]
    cell(t, cx - 104, y0 + 36, 44, orar, GEAR / oimg, rank=orank)
    cell(t, cx + 60, y0 + 36, 44, nrar, GEAR / nimg)
    arrow(t, cx, y0 + 58, P["soft"], 18)
    t.text(cx - 82, y0 + 84, SMALL, oname, RIM[orar], "CENTER")
    t.text(cx + 82, y0 + 84, SMALL, nname, RIM[nrar], "CENTER")
    t.stroke([(x0 + 16, y0 + 106), (x1 - 16, y0 + 106)], 1.0, P["edge"])
    for k, (moves, words) in enumerate(st["lines"]):
        y = y0 + 113 + k * 20
        if moves:
            check(t, x0 + 26, y + 5, 7, GOOD)
        else:
            t.stroke([(x0 + 21, y + 5), (x0 + 31, y + 5)], 2.0, P["soft"])
        t.text(x0 + 40, y, SMALL, words, P["text"] if moves else P["soft"])
    press(t, x0 + 12, y1 - 52, cx - 4, y1 - 8, "Leave them", "quiet")
    press(t, cx + 4, y1 - 52, x1 - 12, y1 - 8, "Move across", "one")


READY = dict(slot="Main Hand", rank=(7, 8), stat=("Attack", "412", "436", "+24"), stone="Mid", need=6, have=14,
             credits="1,200", rate=70)
MENU = [
    ("Inventory, on its Overview", dict(tab="Inventory")),
    ("Equipment, on Reinforce, the blade ready", dict(READY)),
    ("Settings", dict(tab="Settings")),
]
MENU_NOTES = [
    "The director's Menu (03:37-03:38): tabs down the left with their words under their marks; a tab's own pages",
    "across the top of its panel, the chosen one lit over a gliding underline. Inventory: Overview, Kit, Inventory (the",
    "gear slots and the bag), Stars. Equipment: Reinforce, Jewels, War Emblems. Settings: three sliders. The band",
    "keeps Back and the Credits and kWh; the Voidkin's marks only on Inventory, whose pages are the chosen Voidkin's,",
    "chosen as today by the roster under its figure. Inventory's shard and Settings' cog are drawn stand-ins; the",
    "pages keep their shipped icons. Jewels and War Emblems wait for their own sheets.",
]
STATES = [
    ("A Rare blade at +7, enough to reinforce it", dict(READY)),
    ("Too few stones: the press off, saying why", dict(READY, have=4)),
    ("Never reinforced: Common shoulders at +0, sure to rise", dict(
        slot="Shoulders", rank=(0, 1), stat=("Defense", "38", "41", "+3"), stone="Low", need=2, have=31, credits="80",
        rate=100)),
    ("Succeeded: the blade at +8, lit green", dict(
        READY, rank=(8, 9), stat=("Attack", "436", "461", "+25"), have=8, credits="1,350", rate=60, done="rose")),
    ("Failed: the blade stays at +7, the cost spent", dict(READY, have=8, done="failed")),
]
NOTES = [
    "The director's layout. Left, only the gear the Voidkin wears, a row each: picture, name, level; the chosen row lit,",
    "pointing at the work. Right, the gear in a ring with its stone under it, its level and stat now (left) and after",
    "(right), the gain in green; the odds before every press, success and fail adding to 100; what's held; the cost and",
    "one press. No Voidkin, no Combat Power, nothing that protects a fail. A level lights green when it rises and red",
    "when it fails, in its row and by the ring. Rates are research's seeds; every other number is a stand-in.",
]
TRANSFER = [
    ("Everything moves: a Rare blade at +7 for an Epic", dict(
        tab="Inventory", page="Inventory", transfer=True, old=("Blade of Embers", "Rare", "GearBladeOfEmbers.png", 7),
        new=("Stormcall Blade", "Epic", "GearStormcallBlade.png"),
        lines=[(True, "Reinforce +7"), (True, "2 War Emblems"), (True, "The jewels")])),
    ("Some stays: an Epic helm for an Uncommon one", dict(
        tab="Inventory", page="Inventory", transfer=True, old=("Stormcall Helm", "Epic", "GearStormcallHelm.png", 5),
        new=("Rowsmith Helmet", "Uncommon", "GearRowsmithHelmet.png"),
        lines=[(True, "Reinforce +5"), (True, "2 War Emblems"), (False, "1 War Emblem stays: 2 sockets")])),
]
TRANSFER_NOTES = [
    "The prompt, over Inventory's gear slots: the old item and the new, then one line a thing, checked if it moves,",
    "dashed if it stays on the old item (which goes to the bag with it). Leave them keeps everything on the old item;",
    "Move across is the one press of light. Jewels: five sockets on every piece, so they always move.",
]
PALETTE = [
    ("Reinforce in the screen's own colours (Palettes.Seam)", dict(READY)),
    ("The same in AR40's C, as AR43 asked", dict(READY, palette="C")),
]
PALETTE_NOTES = [
    "AR43 asked for AR40's C, but the Menu's Inventory tab is the Voidkin screen, whose look research's triage kept",
    "(AR40, 2026-11-17, 23:04). In C the Equipment tab turns teal while Inventory beside it stays violet-dark: two",
    "kits in one Menu, its colour changing tab to tab. Modulo's lean: the screen's own colours on every tab.",
]


def sheet_of(out, name, head, cells, notes, across=2):
    """Each cell's phone `across` to a row, its words over it, the notes under. Returns each phone at 64 pixels."""
    ui.K = 2
    gap, head_h = 24, 64
    rows = (len(cells) + across - 1) // across
    width = gap + across * (W + gap)
    height = head_h + rows * (H + 40) + len(notes) * 23 + 20
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, head, "#EDE6D6", bold=0.2)
    spots = []
    for k, (said, st) in enumerate(cells):
        x, y = gap + (k % across) * (W + gap), head_h + (k // across) * (H + 40)
        t.text(x, y - 4, SMALL, f"{k + 1}. {said}", "#B4AC9C")
        phone(sheet, x, y + 16, st)
        spots.append((x, y + 16))
    for k, words in enumerate(notes):
        t.text(gap + 8, head_h + rows * (H + 40) + k * 23, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / name)
    return [rs.shrink(sheet.px[round(y * 2):round((y + H) * 2), round(x * 2):round((x + W) * 2)], TINY)
            for x, y in spots]


def main():
    out = bl.out_dir()
    common = "at the smallest phone (568 x 320 points)"
    shots = [sheet_of(out, "upgrade_menu.png", f"AR43, the Menu on its three tabs, {common}", MENU, MENU_NOTES,
                      across=3),
             sheet_of(out, "upgrade_equipment.png", f"AR43, Equipment's Reinforce, {common}", STATES, NOTES),
             sheet_of(out, "upgrade_transfer.png", f"AR43, the prompt when a new item replaces one, {common}",
                      TRANSFER, TRANSFER_NOTES)]
    sheet_of(out, "upgrade_palette.png", f"AR43, which colours: the screen's own or AR40's C, {common}", PALETTE,
             PALETTE_NOTES)
    gap = 12
    sw, sh = max(s.shape[1] for row in shots for s in row), max(s.shape[0] for row in shots for s in row)
    tiny = np.zeros((len(shots) * (sh + gap) + gap, max(map(len, shots)) * (sw + gap) + gap, 4), dtype=np.float32)
    tiny[..., :3], tiny[..., 3] = ui.c("#101117"), 1.0
    for r, row in enumerate(shots):
        for k, shot in enumerate(row):
            rs.paste(tiny, shot, gap + k * (sw + gap), gap + r * (sh + gap))
    rs.save(tiny, out / "upgrade_64.png")


if __name__ == "__main__":
    main()
