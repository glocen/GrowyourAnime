"""AR43: Equipment's Jewels and War Emblems, each its own screen, opened from Home's Equipment row as Reinforce is (the
director, about 12:21; research's step into a screen, 13:20). At the smallest phone, in every state, for research's
verdict before the cut. Drawn in code: the kit's shapes from upgrade_pages.py, the shipped jewel and emblem pictures,
Blender's own face. Nothing is exported.

The director's words (docs/decisions.md, 2026-11-19, 02:58 to 03:38): jewels and War Emblems are put in and taken out
on Equipment's pages only; the gear's card just shows what's socketed. Every gear piece holds five jewels, one of each
colour, each giving flat points of its colour's Basic Attribute; three of one level make one of the next (12:10 of
2026-11-17). An item holds one emblem on Common, two on Uncommon, three on Rare, four from Epic; each emblem carries
one stat; putting one in or taking it out is free (docs/design.md, "Jewels", "War Emblems").

Equipment's frame: the band (Roblox's buttons, Back to Home, "Equipment", the Credits and kWh); Equipment's rail of
its three screens down the left, the open one larger and lit (the director, 14:59); the worn gear right of it, a row
each, the chosen one lit and pointing at the work; the chosen item's work on the right. In Seam's lit glass
(seam_kit.py; the director, 14:56, research's B, 15:04), as every screen Home opens; Settings too, with no rail. Each
list row shows what its item holds, so a gap is seen before a row is tapped:
    Jewels        the five sockets in a row, each ringed in its colour, its points under it; under them the bag's
                  jewels of the chosen socket's colour, levels 1 to 5 with their counts; one line of what the chosen
                  one does, and the presses: Put in (Replace when the socket holds one, Take out when the socket is
                  chosen alone) and Combine (three of a level into one of the next).
    War Emblems   the item's sockets by its rarity, each its emblem and its stat under it; under them the bag's
                  emblems by rarity, scrolling; one line of the chosen one, and the press: Put in, Replace or Take out.
Jewels' points and emblems' stats are stand-ins (research's numbers); no price is drawn, since putting in and taking
out are free and Combine's cost, if any, is research's.

    blender -b --factory-startup --python tools/blender/equipment_pages.py -- <abs out>

Writes home_settings.png, equipment_jewels.png, equipment_emblems.png and equipment_reinforce.png (each screen's
states) and equipment_close.png (one state of two at the phone's own pixels, three to a point, to read the small
parts); "settings" after the out folder writes Settings' sheet alone, "cut" the cut for Faber.
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import seam_kit as sk  # noqa: E402

P = up.P
sk.wear("B")                                   # Seam's lit glass, as every screen Home opens (research's B, 15:04)
W, H, SMALL, TITLE = up.W, up.H, up.SMALL, up.TITLE
TOP, FOOT = 60, up.FOOT                        # a screen's page under its band, as Reinforce's (home_panel.screen)
LIST, WORK = sk.LIST, (306, 560)              # the list right of Equipment's rail
JEWELS = json.loads((up.UI / "jewels" / "jewels.json").read_text())
EMBLEMS = {e["image"].removeprefix("Emblem"): e for e in json.loads((up.UI / "emblems" / "emblems.json").read_text())["emblems"]}
JEWEL_DIR, EMBLEM_DIR = up.UI / "jewels", up.UI / "emblems" / "images"
COLOURS = list(JEWELS["jewels"])               # Red, Green, Blue, Yellow, Purple
POINTS = (6, 12, 20, 32, 48)                   # a jewel's points by level: stand-ins
SOCKETS = {"Common": 1, "Uncommon": 2, "Rare": 3, "Epic": 4, "Legendary": 4}
RIM = up.RIM


def jewel_pic(colour, level):
    return JEWEL_DIR / JEWELS["jewels"][colour]["images"][level - 1]


def emblem_pic(key):
    return EMBLEM_DIR / f"{EMBLEMS[key]['image']}.png"


# --- the frame ------------------------------------------------------------------------------------------------------

def frame(t, page):
    """The ground, the band titled Equipment, and the rail with `page` open."""
    sk.backdrop(t)
    up.band(t, "Equipment")
    t.text(232, 20, TITLE, "Equipment", P["text"], bold=0.35)
    sk.rail(t, page)


def gear_rows(t, chosen, holds):
    """The worn gear down the left, as Reinforce's list: picture and name, and under the name what the item holds
    (`holds(t, x, y, slot)` draws it). The chosen row is lit and points at the work."""
    x0, x1 = LIST
    up.panel(t, x0, TOP, x1, FOOT)
    rows = t.sheet.tile(t.ox, t.oy, W, FOOT - 1)
    for k, (slot, name, rarity, image, _) in enumerate(up.WORN):
        y = TOP + 4 + k * 50
        if y > FOOT:
            break
        if slot == chosen:
            up.tab_glass(rows, x0 + 3, y, x1 - 3, y + 46)
            rows.paint(rows.poly([(x1 - 3, y + 15), (x1 + 6, y + 23), (x1 - 3, y + 31)]), P["light"])
        else:
            up.box(rows, x0 + 3, y, x1 - 3, y + 46, P["well"], P["edge"], 1.0, cuts=(6, 0, 0, 0))
        up.cell(rows, x0 + 6, y + 3, 40, rarity, up.GEAR / image)
        if y + 40 > FOOT:
            continue
        rows.text(x0 + 54, y + 5, SMALL, name, P["text"], bold=0.3)
        holds(rows, x0 + 54, y + 24, slot)


def well(t, x, y, s, rim=None, lit=False, rim_alpha=0.85):
    """A socket: the channel's dark, cut at two corners as the kit's cells, a rim in its colour; lit when chosen."""
    d = t.poly(ui.cut_box(x, y, x + s, y + s, s * 0.14, 0, s * 0.14, 0))
    if lit:
        t.glow(d, 6.0, P["light"], 0.55)
    t.paint(d, t.ramp(*sk.SOCKET_DARK, (t.y - y) / s))
    if rim:
        t.paint(d, rim, 0.08 + 0.18 * np.exp(-(((t.x - x - s / 2) / (s * 0.5)) ** 2 + ((t.y - y - s * 0.6) / (s * 0.5)) ** 2)))
    t.line(d, 2.2 if lit else 1.4, P["light"] if lit else (rim or P["edge"]), 1.0 if lit else rim_alpha)
    return d


def item_name(t, slot):
    _, name, rarity, _, _ = next(w for w in up.WORN if w[0] == slot)
    x0, x1 = WORK
    t.text((x0 + x1) / 2, TOP + 6, SMALL, name, RIM[rarity], "CENTER", bold=0.3)
    return rarity


def rule(t, y, words, right=None):
    x0, x1 = WORK
    t.stroke([(x0 + 10, y), (x1 - 10, y)], 1.0, P["facet"], 0.45)
    t.text(x0 + 12, y + 5, SMALL, words, P["soft"])
    if right:
        t.text(x1 - 12, y + 5, SMALL, right, P["soft"], "RIGHT")


def said(t, lines, y):
    """The chosen thing's one or two lines, left, from `y`."""
    x0 = WORK[0]
    for k, (words, colour, bold) in enumerate(lines):
        t.text(x0 + 12, y + k * 18, SMALL, words, colour, bold=bold)


def presses(t, kinds):
    """The presses at the foot right, the one of light last: (words, kind, width)."""
    x = WORK[1] - 10
    for words, kind, w in reversed(kinds):
        up.press(t, x - w, FOOT - 50, x, FOOT - 6, words, kind)
        x -= w + 8


# --- Jewels ---------------------------------------------------------------------------------------------------------

def jewel_holds(st):
    def draw(t, x, y, slot):
        held = st["worn"].get(slot, {})
        for k, colour in enumerate(COLOURS):
            cx, cy = x + 8 + k * 20, y + 8
            ring = JEWELS["jewels"][colour]["words"]
            if colour in held:
                up.pic(t, jewel_pic(colour, held[colour]), cx - 9, cy - 9, 18)
            else:
                d = np.hypot(t.x - cx, t.y - cy) - 4.5
                t.line(d, 1.2, ring, 0.7)
        if len(held) == 5:
            t.text(x + 104, y, SMALL, "Full", P["faint"])
    return draw


def jewels_work(t, st):
    x0, x1 = WORK
    up.panel(t, x0, TOP, x1, FOOT)
    item_name(t, st["slot"])
    held = st["worn"].get(st["slot"], {})
    s, gap = 44, 5
    left = (x0 + x1) / 2 - (5 * s + 4 * gap) / 2
    for k, colour in enumerate(COLOURS):
        x, y = left + k * (s + gap), TOP + 24
        ring = JEWELS["jewels"][colour]["words"]
        well(t, x, y, s, ring, lit=colour == st["colour"])
        if colour in held:
            up.pic(t, jewel_pic(colour, held[colour]), x + 2, y + 2, s - 4)
            t.text(x + s / 2, y + s + 4, SMALL, f"+{POINTS[held[colour] - 1]}", P["text"], "CENTER", bold=0.3)
        else:
            dia = np.abs(t.x - x - s / 2) + np.abs(t.y - y - s / 2) - 7
            t.line(dia, 1.2, ring, 0.55)
            t.text(x + s / 2, y + s + 4, SMALL, "-", P["faint"], "CENTER")
    colour = st["colour"]
    attribute = JEWELS["jewels"][colour]["attribute"]
    rule(t, TOP + 96, f"Your {colour.lower()} jewels", attribute)
    have = st["bag"]
    c, cgap = 40, 6
    left = (x0 + x1) / 2 - (5 * c + 4 * cgap) / 2
    for level in range(1, 6):
        x, y = left + (level - 1) * (c + cgap), TOP + 118
        n = have.get(level, 0)
        well(t, x, y, c, None, lit=level == st.get("pick"), rim_alpha=0.5)
        up.pic(t, jewel_pic(colour, level), x + 2, y + 2, c - 4, alpha=1.0 if n else 0.3)
        if n:
            up.box(t, x + c - 22, y + c - 15, x + c - 1.5, y + c - 1.5, P["channel"], cut=0)
            t.text(x + c - 11.5, y + c - 14, SMALL, f"{n}", P["text"], "CENTER", bold=0.3)
    said(t, st["said"], TOP + 164)                 # over the two presses
    presses(t, st["presses"])


def combine_live(bag, pick):
    """Combine can act: three or more of the chosen level, under the top level (research's must-fix, 14:27)."""
    return bool(pick) and pick < 5 and bag.get(pick, 0) >= 3


def jewel_state(slot, colour, bag, pick, worn):
    """A state of the Jewels screen, from what's chosen. Every press is drawn live only when it can act:
        Put in    a bag jewel chosen and the socket empty; Replace in its place when the socket holds one;
        Take out  the socket chosen alone, holding one;
        Combine   three or more of the chosen level, under level 5; quiet when live, never the lit one.
    With nothing it can do, a press is drawn off, the well's plate."""
    attribute = JEWELS["jewels"][colour]["attribute"]
    now = worn.get(slot, {}).get(colour)
    gain = lambda level: f"{attribute} +{POINTS[level - 1]}"  # noqa: E731
    combine = ("Combine", "quiet" if combine_live(bag, pick) else "off", 92)
    if pick:
        lines = [(f"Level {pick}: {gain(pick)}", P["text"], 0.3)]
        if now:
            lines.append((f"Its level {now} goes back to your bag", P["soft"], 0.0))
        elif combine_live(bag, pick):
            lines.append((f"Combine 3 into 1 of level {pick + 1}", P["soft"], 0.0))
        else:
            lines.append(("Free to put in and take out", P["soft"], 0.0))
        main = ("Replace" if now else "Put in", "one", 84)
    elif now:
        lines = [(f"Level {now}: {gain(now)}", P["text"], 0.3), ("It goes back to your bag", P["soft"], 0.0)]
        main = ("Take out", "one", 92)
    else:
        lines = [(f"No {colour.lower()} jewel in your bag", P["soft"], 0.0),
                 ("Chests and foes drop them", P["faint"], 0.0)]
        main = ("Put in", "off", 84)
    return dict(screen="Jewels", slot=slot, colour=colour, bag=bag, pick=pick, worn=worn, said=lines,
                presses=[combine, main])


WORN_JEWELS = {
    "Main Hand": {"Red": 3, "Green": 2, "Blue": 1, "Purple": 2},
    "Off Hand": {"Red": 1, "Green": 1},
    "Helmet": {"Red": 4, "Green": 3, "Blue": 3, "Yellow": 2, "Purple": 3},
    "Chest Armor": {"Yellow": 2},
}
JEWEL_STATES = [
    ("Nothing in it: Iron Shoulders' red, a level 2 chosen (two: Combine off)",
     jewel_state("Shoulders", "Red", {1: 7, 2: 2, 4: 1}, 2, WORN_JEWELS)),
    ("A better one for a held socket: the blade's red, level 3, for a level 4",
     jewel_state("Main Hand", "Red", {1: 7, 2: 2, 4: 1}, 4, WORN_JEWELS)),
    ("Seven level 1 reds chosen: Combine can act, three into one level 2",
     jewel_state("Shoulders", "Red", {1: 7, 2: 2, 4: 1}, 1, WORN_JEWELS)),
    ("The socket alone: the blade's yellow, empty, none in the bag",
     jewel_state("Main Hand", "Yellow", {}, None, WORN_JEWELS)),
    ("Full: the Stormcall Helm, its blue chosen alone, to take out",
     jewel_state("Helmet", "Blue", {1: 3}, None, WORN_JEWELS)),
]
JEWEL_NOTES = [
    "The director's jewels: every gear piece holds five, one of each colour, each giving its colour's Basic Attribute;",
    "put in and taken out here only. Reinforce's frame: the worn gear down the left, each row showing its five sockets",
    "(a jewel, or an empty ring in its colour), the chosen row pointing at the work. Right: the five sockets in a row,",
    "ringed in their colours, the chosen one lit, the points under each; the bag's jewels of that colour, levels 1 to 5",
    "with their counts (none dimmed); one line and the presses. Points are stand-ins; no price is drawn.",
]


# --- War Emblems ----------------------------------------------------------------------------------------------------

def star_outline(t, cx, cy, r):
    pts = [(cx + np.cos(a) * rr, cy + np.sin(a) * rr) for k in range(10)
           for a, rr in [(-np.pi / 2 + k * np.pi / 5, r if k % 2 == 0 else r * 0.48)]]
    return t.poly(pts)


def emblem_holds(st):
    def draw(t, x, y, slot):
        rarity = next(w for w in up.WORN if w[0] == slot)[2]
        held = st["worn"].get(slot, [])
        for k in range(SOCKETS[rarity]):
            cx, cy = x + 9 + k * 22, y + 8
            if k < len(held) and held[k]:
                up.pic(t, emblem_pic(held[k][0]), cx - 11, cy - 11, 22)
            else:
                t.line(star_outline(t, cx, cy + 0.5, 7.5), 1.1, P["faint"], 0.8)
    return draw


def emblems_work(t, st):
    x0, x1 = WORK
    up.panel(t, x0, TOP, x1, FOOT)
    rarity = item_name(t, st["slot"])
    held = st["worn"].get(st["slot"], [])
    n = SOCKETS[rarity]
    s, pitch = 46, 60
    left = (x0 + x1) / 2 - ((n - 1) * pitch) / 2 - s / 2
    for k in range(n):
        x, y = left + k * pitch, TOP + 24
        e = held[k] if k < len(held) else None
        well(t, x, y, s, RIM[EMBLEMS[e[0]]["rarity"]] if e else None, lit=k == st["socket"],
             rim_alpha=0.85 if e else 0.5)
        cx = x + s / 2
        if e:
            up.pic(t, emblem_pic(e[0]), x + 1, y + 1, s - 2)
            stat, value = e[1], e[2]
            t.text(cx, y + s + 4, SMALL, value, P["text"], "CENTER", bold=0.3)
            for j, words in enumerate(stat.split(" ")):
                t.text(cx, y + s + 20 + j * 15, SMALL, words, P["soft"], "CENTER")
        else:
            t.line(star_outline(t, cx, y + s / 2 + 1, 13), 1.2, P["faint"], 0.7)
            t.text(cx, y + s + 4, SMALL, "Empty", P["faint"], "CENTER")
    rule(t, TOP + 128, "Your emblems")
    up.box(t, x1 - 78, TOP + 131, x1 - 12, TOP + 151, P["button"], P["edge"], 0.8, 4)
    t.text(x1 - 45, TOP + 134, SMALL, "Rarity", P["text"], "CENTER")
    bag = t.sheet.tile(t.ox + x0 + 1, t.oy, x1 - x0 - 9, H)           # the row scrolls, cut inside the panel
    c, cgap = 40, 6
    for k, key in enumerate(st["bag"]):
        x, y = 12 + k * (c + cgap), TOP + 158
        if x > x1 - x0:
            break
        chosen = key == st.get("pick")
        if chosen:                                 # its light under it, its rim over it
            d = bag.poly(ui.cut_box(x - 1.5, y - 1.5, x + c + 1.5, y + c + 1.5, c * 0.14, 0, c * 0.14, 0))
            bag.glow(d, 5.0, P["light"], 0.5)
        up.cell(bag, x, y, c, EMBLEMS[key]["rarity"], emblem_pic(key))
        if chosen:
            bag.line(d, 2.2, P["light"])
    said(t, st["said"], FOOT - 46)                 # beside the one press
    presses(t, st["presses"])


STATS = {"Talon": ("Attack", "+40"), "Spearhead": ("Attack", "+40"), "Palisade": ("Defence", "+24"),
         "Tidebreak": ("Health", "+260"), "Warhorn": ("Attack", "+60"), "Compass": ("Hit", "+2%"),
         "SerpentCoil": ("Dodge", "+3%"), "SwornRings": ("Lifesteal", "+3%"), "Moonward": ("Critical Damage", "+8%"),
         "Zenith": ("Health", "+480"), "Highcrown": ("Critical Immunity", "+6%"), "Radiance": ("Attack", "+90")}


def emb(key):
    return (key, *STATS[key])


WORN_EMBLEMS = {
    "Main Hand": [emb("Talon"), emb("Warhorn"), emb("Compass")],
    "Off Hand": [emb("Spearhead")],
    "Helmet": [emb("Moonward"), emb("Tidebreak")],
    "Chest Armor": [emb("Palisade")],
}
BAG = ["Zenith", "Radiance", "SwornRings", "SerpentCoil", "Warhorn", "Tidebreak", "Spearhead", "Talon", "Palisade"]


def emblem_state(slot, socket, pick, worn=WORN_EMBLEMS, bag=BAG):
    """A state of War Emblems, from what's chosen; its one press live only when it can act, as Jewels' are: Put in
    (a bag emblem chosen, the socket empty), Replace (the socket holding one), Take out (the socket chosen alone,
    holding one); off with nothing to do."""
    rarity_of = lambda key: EMBLEMS[key]["rarity"]  # noqa: E731
    line = lambda key: (f"{EMBLEMS[key]['set']} · {rarity_of(key)}", RIM[rarity_of(key)], 0.3)  # noqa: E731
    stat = lambda key: f"{STATS[key][0]} {STATS[key][1]}"  # noqa: E731
    held = worn.get(slot, [])
    now = held[socket] if socket is not None and socket < len(held) else None
    if pick and now:
        lines = [line(pick), (f"{stat(pick)} (now {now[2]})", P["text"], 0.0)]
        kinds = [("Replace", "one", 84)]
    elif pick:
        lines, kinds = [line(pick), (stat(pick), P["text"], 0.0)], [("Put in", "one", 84)]
    elif now:
        lines, kinds = [line(now[0]), (f"{now[1]} {now[2]}", P["text"], 0.0)], [("Take out", "one", 92)]
    else:
        lines = [("Choose one below", P["soft"], 0.0), ("Putting in is free", P["faint"], 0.0)]
        kinds = [("Put in", "off", 84)]
    return dict(screen="War Emblems", slot=slot, socket=socket, pick=pick, worn=worn, bag=bag, said=lines,
                presses=kinds)


EMBLEM_STATES = [
    ("A Common item's one socket, empty, nothing chosen", emblem_state("Shoulders", 0, None)),
    ("The Epic helm's four, two empty: Zenith chosen for the third", emblem_state("Helmet", 2, "Zenith")),
    ("A held socket chosen alone: Moonward, to take out", emblem_state("Helmet", 0, None)),
    ("The Rare blade full: Radiance chosen for Warhorn's socket", emblem_state("Main Hand", 1, "Radiance")),
]
EMBLEM_NOTES = [
    "The director's War Emblems: a black rock star, its top its rarity's colour, a set's white mark; one socket on Common,",
    "two on Uncommon, three on Rare, four from Epic; one stat each; put in and taken out here only, free. Reinforce's",
    "frame: each row shows its item's sockets (an emblem, or an empty star). Right: the sockets, the chosen one lit, each",
    "emblem's stat under it; the bag's emblems by rarity (Rarity sorts), the row scrolling under the panel's edge; one",
    "line and the press: Put in, Replace or Take out. Stats are stand-ins; the sort's tap is 44 points over its pill.",
]


# --- Reinforce, its own screen ----------------------------------------------------------------------------------------
# upgrade_pages.py's Reinforce (research's verdicts, 03:44 and 12:56), under Home's band with Equipment's rail (the
# director, 14:59), in Seam's lit glass. Its list and work are the kit's own functions, worn by seam_kit.

up.TOP = TOP                                       # the kit's page top, under the band rather than the Menu's pages
REINFORCE_STATES = [(words, dict(st, screen="Reinforce")) for words, st in up.STATES]
REINFORCE_NOTES = [
    "Reinforce, from Home's Equipment row: the band (Back returns to Home), Equipment's rail with Reinforce open, the",
    "worn gear, the chosen row lit and pointing at the work; the gear in its ring, now and after on either",
    "side, the stone under the ring, the odds before every press (adding to 100), what's held, the cost and one press,",
    "lit only when it can go. In Seam's lit glass. Rates are research's seeds; every other number is a stand-in.",
]


# --- the sheets -----------------------------------------------------------------------------------------------------

# --- Settings, Home's other screen ----------------------------------------------------------------------------------
# Plain (the director's three sliders), in the same lit glass as Equipment's (research's scope of 14:56), with no rail:
# it's a group of one. One card in the middle, a row each.

SETTINGS = (88, 480)                               # the card, across the middle
SETTING_ROW = 64


def settings_work(t, st):
    x0, x1 = SETTINGS
    up.panel(t, x0, TOP + 8, x1, FOOT - 8)
    mid = (TOP + FOOT) / 2
    for k, (name, value) in enumerate(st["values"]):
        cy = mid + (k - 1) * SETTING_ROW
        held = name == st.get("held")
        t.text(x0 + 22, cy - 7, 15, name, P["light"] if held else P["text"], bold=0.3)
        sk.slider(t, x0 + 120, x1 - 78, cy, value, held)
        t.text(x1 - 22, cy - 7, SMALL, "Off" if value == 0 else f"{round(value * 100)}%",
               P["light"] if held else P["soft"], "RIGHT", bold=0.3 if held else 0.0)
        if k:
            t.stroke([(x0 + 18, cy - SETTING_ROW / 2), (x1 - 18, cy - SETTING_ROW / 2)], 1.0, P["edge"], 0.6)


REST = (("Music", 0.7), ("Sound", 0.85), ("Effects", 1.0))
SETTINGS_STATES = [
    ("At rest: the three as saved", dict(screen="Settings", values=REST)),
    ("Sound held, dragged to 40%: the knob grows, its ring and the row lit",
     dict(screen="Settings", values=(("Music", 0.7), ("Sound", 0.4), ("Effects", 1.0)), held="Sound")),
    ("Music off: the fill gone, the knob at the start, Off", dict(screen="Settings", values=(("Music", 0.0),) + REST[1:])),
]
SETTINGS_NOTES = [
    "Settings, Home's tall tile: the band (Back returns to Home, Settings), one card of three sliders, a row each. No",
    "rail, since it's a group of one. A slider is the kit's conduit filling with light, its knob the lit press's white;",
    "held, the knob grows from 10 to 12.5 points and its ring lights. Each change is heard or seen at once.",
]


def phone(sheet, ox, oy, st):
    t = sheet.tile(ox, oy, W, H)
    if st["screen"] == "Settings":
        sk.backdrop(t, ((SETTINGS[0] + SETTINGS[1]) / 2, (TOP + FOOT) / 2))
        up.band(t, "Settings")
        t.text(232, 20, TITLE, "Settings", P["text"], bold=0.35)
        settings_work(t, st)
        return
    frame(t, st["screen"])
    if st["screen"] == "Reinforce":
        up.gear_list(t, st, *LIST)
        up.work(t, st, *WORK)
    elif st["screen"] == "Jewels":
        gear_rows(t, st["slot"], jewel_holds(st))
        jewels_work(t, st)
    else:
        gear_rows(t, st["slot"], emblem_holds(st))
        emblems_work(t, st)


def sheet_of(out, name, head, cells, notes, across=2, k=2):
    ui.K = k
    gap, head_h = 24, 64
    rows = (len(cells) + across - 1) // across
    width = gap + across * (W + gap)
    height = head_h + rows * (H + 40) + len(notes) * 23 + 20
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, head, "#EDE6D6", bold=0.2)
    for n, (words, st) in enumerate(cells):
        x, y = gap + (n % across) * (W + gap), head_h + (n // across) * (H + 40)
        t.text(x, y - 4, SMALL, f"{n + 1}. {words}", "#B4AC9C")
        phone(sheet, x, y + 16, st)
    for n, words in enumerate(notes):
        t.text(gap + 8, head_h + rows * (H + 40) + n * 23, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / name)


# --- the cut for Faber ----------------------------------------------------------------------------------------------

HANDOFF = up.REPO / "build" / "handoff" / "UI" / "equipment"
CORNER = 0.14 * 44                     # a socket's two cut corners, drawn at 44 points
SLICE, LINE_PAD, GLOW_PAD = 8.0, 2.0, 18.0   # a glow's pad: three of its radii, where it's gone


def socket_box(t, x0, y0, s):
    return t.poly(ui.cut_box(x0, y0, x0 + s, y0 + s, CORNER, 0, CORNER, 0))


def cut_images():
    """The sockets' own images at 4 pixels a point, drawn at 44 points: the body in its own colours, the light, the
    rim plain and lit and the glow white for the game to tint; the empty marks white. Returns {name: (px, entry)}."""
    import foe_cards as fc
    ui.K = 4
    made = {}
    s = 44.0
    slice_note = (f"Sliced at Cut {SLICE:g} on every side: one image serves the 40, 44 and 46 point sockets, its corner "
                  f"cut {CORNER:.1f} at every size")
    t = fc.clear(s, s)
    t.paint(socket_box(t, 0, 0, s), t.ramp(*sk.SOCKET_DARK, t.y / s))
    made["SocketFill"] = (t.px.copy(), dict(points=[s, s], cut=[SLICE] * 4, tint=None,
                                            use="a socket's dark well, in its own colours, never tinted; the bottom "
                                                "of every socket and of the Jewels screen's bag cells. " + slice_note))
    t = fc.clear(s, s)
    glow = 0.08 + 0.18 * np.exp(-(((t.x - s / 2) / (s * 0.5)) ** 2 + ((t.y - s * 0.6) / (s * 0.5)) ** 2))
    t.paint(socket_box(t, 0, 0, s), "#FFFFFF", glow)
    made["SocketLight"] = (t.px.copy(), dict(points=[s, s], tint="the socket's colour (a jewel's ring, an emblem's "
                                                                 "rarity), ImageTransparency 0; its strength is in the "
                                                                 "picture",
                                             use="the colour's light rising in a held or coloured socket, over the "
                                                 "fill: stretched to the socket (ScaleType Stretch), never sliced. "
                                                 "Not on an empty emblem socket or a bag cell"))
    for name, width, tint in (("SocketEdge", 1.4, f"the socket's colour at ImageTransparency 0.15; a jewel bag cell's and an "
                                                  f"empty emblem socket's the screen's edge {P['edge']} at 0.5"),
                              ("SocketEdgeLit", 2.2, f"the screen's light {P['light']}, ImageTransparency 0")):
        w = s + 2 * LINE_PAD
        t = fc.clear(w, w)
        t.line(socket_box(t, LINE_PAD, LINE_PAD, s), width, "#FFFFFF")
        made[name] = (t.px.copy(), dict(points=[w, w], pad=LINE_PAD, cut=[SLICE + LINE_PAD] * 4, tint=tint,
                                        use=("a socket's rim, " + ("at rest" if name == "SocketEdge" else
                                                                   "the chosen socket's or bag cell's, in place of "
                                                                   "the rest rim")
                                             + f", {width:g} points on the outline, over the light. Its box is the "
                                               f"socket's with Pad on every side. Sliced at Cut {SLICE + LINE_PAD:g}")))
    w = s + 2 * GLOW_PAD
    t = fc.clear(w, w)
    t.glow(socket_box(t, GLOW_PAD, GLOW_PAD, s), 6.0, "#FFFFFF", 1.0)
    made["SocketGlow"] = (t.px.copy(), dict(points=[w, w], pad=GLOW_PAD, cut=[SLICE + GLOW_PAD] * 4,
                                            tint=f"the screen's light {P['light']} at ImageTransparency 0.45",
                                            use="the chosen socket's or bag cell's glow, under its fill. Its box is "
                                                f"the socket's with Pad on every side. Sliced at Cut "
                                                f"{SLICE + GLOW_PAD:g}"))
    t = fc.clear(16, 16)
    t.line(np.abs(t.x - 8) + np.abs(t.y - 8) - 7, 1.2, "#FFFFFF")
    made["SocketEmptyJewel"] = (t.px.copy(), dict(points=[16, 16], tint="the socket's jewel colour at "
                                                                        "ImageTransparency 0.45",
                                                  use="an empty jewel socket's mark, a diamond, its 16 point box "
                                                      "centred in the socket"))
    t = fc.clear(28, 28)
    t.line(star_outline(t, 14, 15, 13), 1.2, "#FFFFFF")
    made["SocketEmptyEmblem"] = (t.px.copy(), dict(points=[28, 28], tint=f"the screen's faint {P['faint']} at "
                                                                         "ImageTransparency 0.3",
                                                   use="an empty emblem socket's mark, a star, its 28 point box "
                                                       "centred in the socket"))
    t = fc.clear(12, 12)
    t.line(np.hypot(t.x - 6, t.y - 6) - 4.5, 1.2, "#FFFFFF")
    made["RowEmptyJewel"] = (t.px.copy(), dict(points=[12, 12], tint="the jewel's colour at ImageTransparency 0.3",
                                               use="a list row's empty jewel, a ring, its 12 point box centred where "
                                                   "the row's jewel would stand"))
    t = fc.clear(16, 16)
    t.line(star_outline(t, 8, 8.5, 7.5), 1.1, "#FFFFFF")
    made["RowEmptyEmblem"] = (t.px.copy(), dict(points=[16, 16], tint=f"the screen's faint {P['faint']} at "
                                                                      "ImageTransparency 0.2",
                                                use="a list row's empty emblem socket, a star, its 16 point box "
                                                    "centred where the row's emblem would stand"))
    return made


def placements():
    """Every piece's place, in points on the smallest phone (568 by 320), from the phone's top left."""
    lx0, lx1 = LIST
    wx0, wx1 = WORK
    cx = (wx0 + wx1) / 2
    row = dict(first=TOP + 4, pitch=50, height=46, box=[lx0 + 3, lx1 - 3],
               cell=dict(at=[lx0 + 6, 3], size=40, note="the bag's item cell (rarity tint, light, rim), the gear's "
                                                        "picture at 0.94"),
               name=dict(at=[lx0 + 54, 5], size=SMALL, bold=True, colour=P["text"]),
               holds=dict(top=24, note="what the item holds, under its name"),
               chosen="Reinforce's: the dark glass lit from its right edge and the light's point at its right end, "
                      "toward the work; the others the well's plate",
               scroll="the rows scroll; the panel's foot cuts the last")
    jewels = dict(
        rowHolds=dict(first=[lx0 + 62, 32], pitch=20, picture=18, empty="RowEmptyJewel, its 12 box",
                      full=dict(at=[lx0 + 158, 24], words="Full", colour=P["faint"],
                                note="when all five are in")),
        name=dict(at=[cx, TOP + 6], size=SMALL, bold=True, align="centre", colour="the item's rarity (the bag's)"),
        sockets=dict(first=[round(cx - 120, 2), TOP + 24], pitch=49, size=44, order=COLOURS,
                     picture="the jewel at 40, centred (2 points in)",
                     value=dict(at=[22, 48], size=SMALL, bold=True, align="centre", colour=P["text"],
                                words="+points; '-' in the faint when empty")),
        rule=dict(y=TOP + 96, ends=[wx0 + 10, wx1 - 10], colour=P["facet"], transparency=0.55),
        heading=dict(at=[wx0 + 12, TOP + 101], words="Your <colour> jewels", colour=P["soft"],
                     right=dict(at=[wx1 - 12, TOP + 101], words="the colour's attribute", colour=P["soft"])),
        bag=dict(first=[round(cx - 112, 2), TOP + 118], pitch=46, size=40, levels=[1, 2, 3, 4, 5],
                 picture="the jewel at 36, centred (2 in); at ImageTransparency 0.7 when none is held",
                 rim="SocketEdge in the screen's edge at 0.5; the chosen one SocketGlow and SocketEdgeLit",
                 count=dict(box=[18, 25, 38.5, 38.5], colour=P["channel"], number=dict(at=[28.5, 26], bold=True),
                            note="a Frame in the channel at the cell's foot right, the count in the text colour; "
                                 "none held, no chip")),
        said=dict(at=[wx0 + 12, TOP + 164], pitch=18, note="two lines over the presses: the first bold in the text "
                                                           "colour, the second soft"),
        presses=dict(right=wx1 - 10, top=FOOT - 50, foot=FOOT - 6, gap=8,
                     order=["Combine (92 wide)", "Put in, Replace (84) or Take out (92)"]))
    emblems = dict(
        rowHolds=dict(first=[lx0 + 63, 32], pitch=22, picture=22, empty="RowEmptyEmblem, its 16 box centred where the emblem would stand",
                      count="the item's sockets by its rarity: Common 1, Uncommon 2, Rare 3, Epic and above 4"),
        name=jewels["name"],
        sockets=dict(top=TOP + 24, pitch=60, size=46, centred=cx,
                     note="n sockets centred: the first's left at the middle - (n - 1) x 30 - 23",
                     picture="the emblem at 44, centred (1 point in)",
                     value=dict(at=[23, 50], size=SMALL, bold=True, align="centre", colour=P["text"]),
                     stat=dict(at=[23, 66], pitch=15, size=SMALL, align="centre", colour=P["soft"],
                               note="the stat's name, a word a line (Critical / Damage)"),
                     empty=dict(mark="SocketEmptyEmblem, its 28 box centred in the socket", words="Empty", colour=P["faint"],
                                at=[23, 50])),
        rule=dict(y=TOP + 128, ends=[wx0 + 10, wx1 - 10], colour=P["facet"], transparency=0.55),
        heading=dict(at=[wx0 + 12, TOP + 133], words="Your emblems", colour=P["soft"]),
        sort=dict(box=[wx1 - 78, TOP + 131, wx1 - 12, TOP + 151], words="Rarity", fill=P["button"][0],
                  edge=P["edge"], tap="44 points high over the pill, centred on it"),
        bag=dict(top=TOP + 158, first=wx0 + 13, pitch=46, size=40, clip=[wx0 + 1, wx1 - 8],
                 note="a scrolling row of the bag's item cells (the kit's, its emblems), cut 8 inside the panel's "
                      "edge; sorted by rarity, highest first; the chosen one SocketGlow under it and SocketEdgeLit over "
                      "it, both on a box 1.5 outside the cell"),
        said=dict(at=[wx0 + 12, FOOT - 46], pitch=18, note="two lines left of the press: the set and rarity in the "
                                                           "rarity's colour, bold; then the stat in the text colour"),
        presses=dict(right=wx1 - 10, top=FOOT - 50, foot=FOOT - 6, order=["Put in, Replace (84) or Take out (92)"]))
    return dict(frame=dict(band="Reinforce's (upgrade_pages.band): Roblox's buttons, Back, the screen's name, the "
                                "Credits and kWh",
                           title=dict(at=[232, 20], size=TITLE, bold=True, colour=P["text"]),
                           list=dict(panel=[lx0, TOP, lx1, FOOT], rows=row),
                           work=dict(panel=[wx0, TOP, wx1, FOOT]),
                           panel="the kit's panel (PanelShadow, PanelFill, PanelEdge) in Seam's lit glass, with "
                                 "seam.json's lift"),
                jewels=jewels, emblems=emblems)


def stretch(img, w, h):
    """img resampled to h by w pixels, bilinear."""
    def axis(n_in, n_out):
        at = np.clip((np.arange(n_out) + 0.5) * n_in / n_out - 0.5, 0, n_in - 1)
        lo = np.floor(at).astype(int)
        return lo, np.minimum(lo + 1, n_in - 1), (at - lo).astype(np.float32)
    y0, y1, fy = axis(img.shape[0], h)
    x0, x1, fx = axis(img.shape[1], w)
    top = img[y0][:, x0] * (1 - fx)[None, :, None] + img[y0][:, x1] * fx[None, :, None]
    foot = img[y1][:, x0] * (1 - fx)[None, :, None] + img[y1][:, x1] * fx[None, :, None]
    return top * (1 - fy)[:, None, None] + foot * fy[:, None, None]


def slice9(img, cut, w, h):
    """A sliced image (cut in pixels, every side) laid at w by h pixels, as Roblox's Slice scale type."""
    c = int(round(cut))
    out = np.zeros((h, w, 4), np.float32)
    ys = [(0, c, 0, c), (c, img.shape[0] - c, c, h - c), (img.shape[0] - c, img.shape[0], h - c, h)]
    xs = [(0, c, 0, c), (c, img.shape[1] - c, c, w - c), (img.shape[1] - c, img.shape[1], w - c, w)]
    for a0, a1, b0, b1 in ys:
        for p0, p1, q0, q1 in xs:
            out[b0:b1, q0:q1] = stretch(img[a0:a1, p0:p1], q1 - q0, b1 - b0)
    return out


def tinted(px, colour, transparency=0.0):
    """The game's tint on a white image, and its ImageTransparency."""
    im = px.copy()
    im[..., :3] *= np.array(rs.rgb(colour), np.float32)
    im[..., 3] *= 1 - transparency
    return im


def built_socket(made, s, rim, lit, light, rim_t, page):
    """A socket built from the images onto `page` (opaque, 4 pixels a point, s plus the glow's pad on each side): the
    glow (chosen), the fill, the light in the rim's colour (a coloured socket), the rim (the lit one when chosen)."""
    K = 4
    pad, lp, n = int(GLOW_PAD * K), int(LINE_PAD * K), int(round(s * K))
    if lit:
        rs.paste(page, tinted(slice9(made["SocketGlow"][0], (SLICE + GLOW_PAD) * K, n + 2 * pad, n + 2 * pad),
                              P["light"], 0.45), 0, 0)
    rs.paste(page, slice9(made["SocketFill"][0], SLICE * K, n, n), pad, pad)
    if light:
        rs.paste(page, tinted(stretch(made["SocketLight"][0], n, n), rim), pad, pad)
    edge = slice9(made["SocketEdgeLit" if lit else "SocketEdge"][0], (SLICE + LINE_PAD) * K, n + 2 * lp, n + 2 * lp)
    rs.paste(page, tinted(edge, P["light"] if lit else rim, 0.0 if lit else rim_t), pad - lp, pad - lp)
    return page


def drawn_socket(s, rim, lit, light, rim_t):
    """The same socket as the screens draw it (well())."""
    ui.K = 4
    sheet = ui.Sheet(s + 2 * GLOW_PAD, s + 2 * GLOW_PAD, "#000000")
    sheet.px[:] = 0
    t = sheet.tile(0, 0, s + 2 * GLOW_PAD, s + 2 * GLOW_PAD)
    well(t, GLOW_PAD, GLOW_PAD, s, rim if light else None, lit=lit, rim_alpha=1 - rim_t)
    return sheet.px.copy()


# --- the frame's rows and Reinforce's ring, cut ---------------------------------------------------------------------

ROW_H, ROW_SLICE, ROW_PIECE = 46.0, 8.0, 32.0   # a list row's height; its end slices; the piece it's drawn as
RING_R = 27.0                                    # Reinforce's ring (upgrade_pages.work)
# The ring's two lines as seam_kit.ring draws them, lit from above: their alpha at the top and at the foot
RING_LINES = (("ReinforceRing", RING_R, 1.8, f"at rest the light {P['light']}; risen {up.GOOD}, failed {up.HURT}",
               (0.95, 0.35), "the ring round the gear"),
              ("ReinforceRingOuter", RING_R + 4, 1.0, f"the facet {P['facet']}", (0.65, 0.25),
               "the ring's outer line, 4 points out"))


def top_lit(radius, box, top, foot):
    """A ring's light from above, as a UIGradient down its image: alpha `top` at the ring's top, `foot` at its foot."""
    at = (box / 2 - radius) / box
    return (f"a UIGradient down it (Rotation 90), Transparency {1 - top:.2f} at {at:.3f} and {1 - foot:.2f} at "
            f"{1 - at:.3f}, held past both: lit from above")


def graded(px, box, radius, top, foot):
    """An image's alpha under that gradient, for the fits."""
    h = px.shape[0]
    y = (np.arange(h) + 0.5) / h
    at = (box / 2 - radius) / box
    out = px.copy()
    out[..., 3] *= np.interp(y, [at, 1 - at], [top, foot]).astype(np.float32)[:, None]
    return out


def cut_frame_reinforce_images():
    """The list rows (every Equipment screen's frame) and Reinforce's ring, flash, wave glow and crack, at 4 pixels a
    point. Returns {name: (px, entry)}."""
    import foe_cards as fc
    ui.K = 4
    made = {}
    w, h = ROW_PIECE, ROW_H
    row_cut = [ROW_SLICE, 0, ROW_SLICE, 0]
    along = (f"Sliced at Cut, its ends only: drawn at its own height ({h:g}), it stretches along to the row, "
             f"{LIST[1] - LIST[0] - 6:g} points on the smallest phone")
    for name, fill, what in (("RowPlate", P["well"], "a list row at rest: the well's plate"),
                             ("RowGlass", P["card"], "the chosen row: the glass, its top lit")):
        t = fc.clear(w, h)
        d = t.poly(ui.cut_box(0, 0, w, h, 6, 0, 0, 0))
        t.paint(d, up.shade(t, fill, 0, h))
        if name == "RowGlass":
            t.paint(d, P["glint"], 0.16 * np.exp(-t.y / 9))
        made[name] = (t.px.copy(), dict(points=[w, h], cut=row_cut, tint=None,
                                        use=f"{what}, in its own colours, never tinted; its top left cut 6. {along}"))
    t = fc.clear(w + 2, h + 2)
    t.line(t.poly(ui.cut_box(1, 1, w + 1, h + 1, 6, 0, 0, 0)), 1.0, "#FFFFFF")
    made["RowEdge"] = (t.px.copy(), dict(points=[w + 2, h + 2], pad=1, cut=[ROW_SLICE + 1, 0, ROW_SLICE + 1, 0],
                                         tint=f"at rest the edge {P['edge']}, ImageTransparency 0; on the chosen "
                                              f"row the facet {P['facet']} at 0.1",
                                         use="a row's hairline over its plate or glass; its box the row's with Pad on "
                                             "every side, sliced as the row"))
    t = fc.clear(w, h)
    t.paint(t.poly([(0, 0), (w, 0), (w, h), (0, h)]), "#FFFFFF", np.clip(t.x / w, 0, 1) ** 1.6)
    made["RowGlassWash"] = (t.px.copy(), dict(points=[w, h], tint=f"the light {P['light']} at ImageTransparency 0.7",
                                              use="the chosen row's light, rising toward its lit right edge, over the "
                                                  "glass and under the hairline: stretched to the row (ScaleType "
                                                  "Stretch), never sliced"))
    t = fc.clear(22, h + 20)
    t.glow(t.poly([(9.5, 10), (12.5, 10), (12.5, h + 10), (9.5, h + 10)]), 3.5, "#FFFFFF", 0.6)
    t.stroke([(11, 10), (11, h + 10)], 2.4, "#FFFFFF")
    made["RowGlassLight"] = (t.px.copy(), dict(points=[22, h + 20], tint=f"the light {P['light']}, ImageTransparency 0",
                                               use="the chosen row's lit right edge and its glow: its box's middle "
                                                   "on the row's right edge, its top 10 above the row's"))
    g = 3 * 7.0                                  # the glass's outer glow, 7 round, gone by three radii
    t = fc.clear(w + 2 * g, h + 2 * g)
    t.glow(t.poly(ui.cut_box(g, g, w + g, h + g, 6, 0, 0, 0)), 7.0, "#FFFFFF", 1.0)
    made["RowGlassGlow"] = (t.px.copy(), dict(points=[w + 2 * g, h + 2 * g], pad=g,
                                              cut=[ROW_SLICE + g, 0, ROW_SLICE + g, 0],
                                              tint=f"the light {P['light']} at ImageTransparency 0.9",
                                              use="the chosen row's soft glow, under its glass: its box the row's with "
                                                  "Pad on every side, sliced at its ends as the row"))
    gw = h * 0.6 + 6 * 9.0                       # the idle's glint: a band 9 round, leaning 0.6 across the row
    t = fc.clear(gw, h)
    t.paint(t.poly([(0, 0), (gw, 0), (gw, h), (0, h)]), "#FFFFFF",
            np.exp(-(((t.x - 27) - t.y * 0.6) / 9) ** 2))
    made["RowGlint"] = (t.px.copy(), dict(points=[gw, h], tint=f"the glint {P['glint']} at ImageTransparency 0.8",
                                          use="the idle's glint down the chosen row: its left at at - 27, where at "
                                              "runs from the row's left - 40 to its right + 40 once a loop (seam.json, "
                                              "idle), its top on the row's; clipped to the row"))
    t = fc.clear(10, 18)
    t.paint(t.poly([(0, 1), (9, 9), (0, 17)]), "#FFFFFF")
    made["RowPoint"] = (t.px.copy(), dict(points=[10, 18], tint=f"the light {P['light']}",
                                          use="the chosen row's point toward the work: its box's left on the row's "
                                              "right edge, its top 14 below the row's"))
    s = 2 * (RING_R + 6)
    for name, radius, width, colour, (top, foot), use in RING_LINES:
        t = fc.clear(s, s)
        t.line(np.hypot(t.x - s / 2, t.y - s / 2) - radius, width, "#FFFFFF")
        made[name] = (t.px.copy(), dict(points=[s, s], tint=f"{colour}; {top_lit(radius, s, top, foot)}",
                                        use=f"{use}: its box's middle on the ring's, {radius:g} points round, "
                                            f"{width:g} wide"))
    b = 2 * (RING_R + 20)                        # the rarity's bloom behind the gear, cut square at the ring + 20
    t = fc.clear(b, b)
    t.paint(t.poly([(0, 0), (b, 0), (b, b), (0, b)]), "#FFFFFF",
            np.exp(-(np.hypot(t.x - b / 2, t.y - b / 2) / (RING_R * 0.85)) ** 2))
    made["ReinforceBloom"] = (t.px.copy(), dict(points=[b, b], tint=f"the item's rarity; risen {up.GOOD}, failed "
                                                                    f"{up.HURT}; ImageTransparency 0.66",
                                                use="the bloom behind the gear, under the ring: its box's middle on "
                                                    "the ring's"))
    c = 2 * (RING_R + 12)
    t = fc.clear(c, c)
    ang = np.arctan2(t.y - c / 2, t.x - c / 2)
    behind = np.mod(-np.pi / 2 - ang, 2 * np.pi)
    t.line(np.hypot(t.x - c / 2, t.y - c / 2) - RING_R + 0.2, 2.6, "#FFFFFF",
           0.95 * np.where(behind < 1.4, np.exp(-behind * 2.6), 0.0))
    t.glow(t.poly([(c / 2 - 1, c / 2 - RING_R - 1), (c / 2 + 1, c / 2 - RING_R - 1), (c / 2 + 1, c / 2 - RING_R + 1),
                   (c / 2 - 1, c / 2 - RING_R + 1)]), 3.5, "#FFFFFF", 0.75)
    made["ReinforceComet"] = (t.px.copy(), dict(points=[c, c], tint=f"the glint {P['glint']}",
                                                use="the idle's comet round the ring, its head at the top and its tail "
                                                    "behind it: its box's middle on the ring's, Rotation 360 x the "
                                                    "idle's phase (clockwise)"))
    f = 88.0
    t = fc.clear(f, f)
    d = np.hypot(t.x - f / 2, t.y - f / 2) - (RING_R - 1)
    t.glow(d, 6.0, "#FFFFFF", 0.6)
    t.paint(d, "#FFFFFF", 0.85)
    made["ReinforceFlash"] = (t.px.copy(), dict(points=[f, f], tint="white; ImageTransparency 1 - f, f = (1 - age / "
                                                                    "Flash)^2 from the yes",
                                                use="a success's flash, the ring filled with light and its glow, over "
                                                    "the gear: its box's middle on the ring's"))
    v = 80.0
    t = fc.clear(v, v)
    t.glow(np.abs(np.hypot(t.x - v / 2, t.y - v / 2) - RING_R) - 0.8, 4.0, "#FFFFFF", 1.0)
    made["ReinforceWaveGlow"] = (t.px.copy(), dict(points=[v, v], tint="the breath's light, the wave's green: see "
                                                                       "reinforce.motion",
                                                   use=f"the soft glow of a ring of light at {RING_R:g} points: scaled "
                                                       "with the breath and the wave, its box's middle on the ring's"))
    cw, ch = 60.0, 36.0
    t = fc.clear(cw, ch)
    import upgrade_motion as um
    pts = [(cw / 2 + x, ch / 2 + y) for x, y in um.CRACK]
    d = np.minimum.reduce([ui.sd_segment(t.x, t.y, a, b) for a, b in zip(pts, pts[1:])])
    t.glow(d - 0.8, 2.5, up.HURT, 0.4)
    t.stroke(pts, 1.6, up.HURT, 0.85)
    t.stroke(pts, 0.6, "#FFE2DC", 0.7)
    made["ReinforceCrack"] = (t.px.copy(), dict(points=[cw, ch], tint=None,
                                                use=f"a fail's crack across the ring, in its own colours ({up.HURT} "
                                                    "with a pale core), never tinted: its box's middle on the ring's; "
                                                    "drawn in left to right, then faded (reinforce.motion)"))
    return made


def reinforce_placements():
    """Reinforce's work, in points on the smallest phone, from upgrade_pages.work at the screen's TOP."""
    x0, x1 = WORK
    cx, y0 = (x0 + x1) / 2, TOP
    c0 = cx - 115
    return dict(
        rowSecond=dict(words="Reinforce", at=[LIST[0] + 54, 24], colour=P["soft"],
                       level=dict(at="right of the word, 3 points on", bold=True,
                                  colour=f"the light {P['light']}; the chosen row's {up.GOOD} once risen, "
                                         f"{up.HURT} once failed")),
        name=dict(at=[cx, y0 + 6], size=SMALL, bold=True, align="centre", colour="the item's rarity"),
        ring=dict(middle=[cx, y0 + 50], radius=RING_R,
                  stack="ReinforceBloom, ReinforceRing, ReinforceRingOuter, ReinforceComet, then the gear's cell"),
        gear=dict(cell=[cx - 20, y0 + 30], size=40, note="the kit's item cell in the item's rarity, the gear's picture "
                                                         "at 0.94"),
        now=dict(word=dict(at=[x0 + 10, y0 + 28], words="Reinforce", colour=P["soft"]),
                 level=dict(at=[x0 + 10, y0 + 44], size=TITLE, bold=True,
                            colour=f"the light; {up.GOOD} once risen, {up.HURT} once failed"),
                 stat=dict(at=[x0 + 10, y0 + 66], colour=P["text"], words="<stat> <now>")),
        after=dict(align="right", word=dict(at=[x1 - 10, y0 + 28], words="Reinforce", colour=P["soft"]),
                   level=dict(at=[x1 - 10, y0 + 44], size=TITLE, bold=True, colour=P["light"]),
                   stat=dict(at=[x1 - 10, y0 + 66], colour=P["text"], words="<stat> <after>"),
                   gain=dict(at=[x1 - 10, y0 + 82], bold=True, colour=up.GOOD, words="+<gain>")),
        stone=dict(cell=[cx - 13, y0 + 82], size=26, note="the kit's Common item cell, the stone's picture (AR31's "
                                                          "StoneLow, StoneMid, StoneHigh) at 0.94, a hairline in the "
                                                          f"edge {P['edge']} over its rim"),
        odds=dict(success=dict(at=[cx - 6, y0 + 113], align="right", bold=True, colour=P["light"],
                               words="Success <rate>%"),
                  dot=dict(at=[cx, y0 + 113], align="centre", colour=P["faint"], words="·"),
                  fail=dict(at=[cx + 6, y0 + 113], colour=P["soft"], words="Fail <100 - rate>%"),
                  note="before every press, the two adding to 100"),
        said=dict(at=[x0 + 10, y0 + 132], pitch=17, note="its lines by state (reinforce.states)"),
        cost=dict(stones=dict(pill=[c0, FOOT - 40, c0 + 64, FOOT - 8], picture=dict(at=[c0 + 4, FOOT - 35], size=22),
                              count=dict(at=[c0 + 58, FOOT - 31], align="right", bold=True,
                                         colour=f"the text; {up.HURT} when short", words="x<need>")),
                  credits=dict(pill=[c0 + 70, FOOT - 40, c0 + 144, FOOT - 8], picture=dict(at=[c0 + 74, FOOT - 33],
                                                                                           size=18, image="CoinMint"),
                               count=dict(at=[c0 + 138, FOOT - 31], align="right", bold=True, colour=P["text"])),
                  pill=f"the channel {P['channel']}, a hairline in the edge, cut 4 at every corner"),
        press=dict(box=[c0 + 150, FOOT - 46, c0 + 230, FOOT - 2], words="Reinforce",
                   kind="lit (one) when it can go; off, the well's plate with faint words, when the stones are short"))


REINFORCE_STATES_SAID = {
    "ready": ["You have <have> <stone> stones (soft)"],
    "short": ["You have <have> <stone> stones: <need - have> short (hurt, bold)", "The Stone Condenser makes them (soft)"],
    "rose": ["Reinforced to +<level> (good, bold)", "You have <have> <stone> stones (soft)"],
    "failed": ["Failed: it stays at +<level> (hurt, bold)", "Spent <need> <stone> stones and <credits> Credits (soft)"],
}


def reinforce_motion():
    """The strips' beats (upgrade_motion.py), for Config.Hud.Motion when the game builds them: in seconds from the
    touch, and `age` from the server's answer."""
    import upgrade_motion as um
    s = dict(um.SEEDS)
    return dict(
        seeds=dict(s, note="upgrade_motion.SEEDS: Answer is the stand-in server's, the game uses the real answer"),
        kit="Config.Hud.Motion.Press (the press), Count (the Credits and the stat), Burst (the sparks), Shine (the "
            "gear's one shine) and Config.Hud.Pop at Rungs.Level (the level), as the game has them",
        easing=dict(out3="1 - (1 - u)^3", in3="u^3", smooth="u^2 (3 - 2u)", expo="1 - 2^(-10u)"),
        rowTapped=[
            "the row squeezes and springs back past its size (Press), about its middle; nothing waits on the server",
            f"the glass (RowGlass, RowGlassWash, RowGlassLight, RowPoint) glides to it over Glide {s['Glide']:g} s, "
            "out3, no overshoot: a marker",
            f"the old work fades over Leave {s['Leave']:g} s (smooth) sliding Slide {s['Slide']:g} points left; the "
            f"new one fades in over Cross {s['Cross']:g} s (out3) from {s['Slide']:g} points right, from the touch"],
        reinforce=[
            f"the press squeezes (Press); from Press.Least its light holds at Pending {s['Pending']:g} until the answer, "
            "then returns over 0.1 s",
            f"the stones: {int(s['Stones'])} of the cost's stone, each k leaving at k x Apart {s['Apart']:g} s and "
            f"flying Fly {s['Fly']:g} s: e = u^2 (eased in) along a quadratic curve from the pill's stone, through "
            "(the pill's x, the ring's y), into the ring's middle; its size 1 - 0.4 e; it fades over its last quarter",
            "the breath, from 0.06 s to the answer + 0.03: u = (t - 0.06) / (Answer - 0.06); a circle (UICorner 0.5, "
            f"UIStroke 1.6 in the light) of radius {RING_R:g} + Inhale x (1 - in3(u)), the stroke's transparency "
            "1 - (0.25 + 0.6u); ReinforceWaveGlow scaled to it in the light at transparency 1 - 0.35u; inside, a "
            f"circle of radius {RING_R - 2:g} in the glint at transparency 1 - 0.14u",
            f"the gear's cell grows to 1 + Lift x in3(u), Lift {s['Lift']:g}"],
        answer=[
            "either way the cost leaves: the Credits count down (Count, expo over Count.Seconds)",
            "the ring (ReinforceRing, ReinforceBloom) and the levels, by the ring and in the row, turn over 0.08 s "
            "(out3): the old fading as the new one shows"],
        success=[
            f"the flash: ReinforceFlash, transparency 1 - f, f = (1 - age / Flash)^2, Flash {s['Flash']:g}",
            f"the wave, for WaveFor {s['WaveFor']:g} s, v = age / WaveFor: a circle of radius {RING_R:g} + Wave x "
            f"out3(v), Wave {s['Wave']:g}, its UIStroke 0.4 + 2.2 (1 - v) wide, white turning {up.GOOD} by "
            "min(2.5v, 1), transparency 1 - (1 - v)^1.5; ReinforceWaveGlow scaled with it in the green at "
            "transparency 1 - 0.5 (1 - v)",
            f"the sparks: Burst from the ring's edge (radius {RING_R - 4:g}), in {up.GOOD}",
            f"the gear: size 1 + Lift x (1 - out3(age / Pop.Seconds)) + Kick x the pop's swell, Kick {s['Kick']:g}; "
            "Shine across its picture",
            f"the level pops at its rung (Pop) in {up.GOOD}, by the ring and in the row; the stat counts to its after "
            "(Count)",
            f"the next rank's lines fade in Texts {s['Texts']:g} s after the yes, over Cross; the glow is gone by "
            f"Settle {s['Settle']:g} s"],
        fail=[
            f"no flash: a circle of radius {RING_R - 1:g} in #FFD2CC at transparency 1 - 0.3 f",
            f"the crack: ReinforceCrack drawn in left to right over Crack {s['Crack']:g} s (a clip widening), then "
            f"faded over CrackFade {s['CrackFade']:g} s",
            f"the gear dims to Dim {s['Dim']:g} over 0.08 s and back by 0.45 s; its size 1 + Lift - (Lift + Sink) x "
            f"out3(age / 0.1) + Sink x smooth((age - 0.15) / 0.25), Sink {s['Sink']:g}",
            f"the work shakes: x + Shake x sin(age / ShakeFor x 6 pi) x (1 - age / ShakeFor), Shake {s['Shake']:g}, "
            f"ShakeFor {s['ShakeFor']:g}: the ring, the gear, the levels, the stat, the lines and the press",
            f"the level stays, in {up.HURT}; the lines fade in at Texts / 2"])


def slice_ends(img, cut, w):
    """An image sliced at its ends only (cut pixels each), laid w pixels wide at its own height."""
    c = int(round(cut))
    out = np.zeros((img.shape[0], w, 4), np.float32)
    out[:, :c] = img[:, :c]
    out[:, w - c:] = img[:, img.shape[1] - c:]
    out[:, c:w - c] = stretch(img[:, c:img.shape[1] - c], w - 2 * c, img.shape[0])
    return out


def row_fit(made, chosen):
    """A list row built from the images and drawn by the kit (upgrade_pages.gear_list), on the panel: (built, drawn)."""
    K, wide = 4, LIST[1] - LIST[0] - 6
    W2, H2 = wide + 20, ROW_H + 16
    ui.K = K
    sheet = ui.Sheet(W2, H2, "#000000")
    t = sheet.tile(0, 0, W2, H2)
    t.paint(t.poly([(0, 0), (W2, 0), (W2, H2), (0, H2)]), P["panel"][1])
    built = sheet.px.copy()
    x0, y0, x1 = 4.0, 8.0, 4.0 + wide
    if chosen:
        up.tab_glass(t, x0, y0, x1, y0 + ROW_H)
        t.paint(t.poly([(x1, y0 + 15), (x1 + 9, y0 + 23), (x1, y0 + 31)]), P["light"])
    else:
        up.box(t, x0, y0, x1, y0 + ROW_H, P["well"], P["edge"], 1.0, cuts=(6, 0, 0, 0))
    drawn = sheet.px.copy()
    n = int(round(wide * K))
    plate = made["RowGlass" if chosen else "RowPlate"][0]
    if chosen:
        g = int(round(21 * K))
        glow = slice_ends(made["RowGlassGlow"][0], ROW_SLICE * K + g, n + 2 * g)
        rs.paste(built, tinted(glow, P["light"], 0.9), int(x0 * K) - g, int(y0 * K) - g)
    rs.paste(built, slice_ends(plate, ROW_SLICE * K, n), int(x0 * K), int(y0 * K))
    if chosen:
        rs.paste(built, tinted(stretch(made["RowGlassWash"][0], n, int(ROW_H * K)), P["light"], 0.7),
                 int(x0 * K), int(y0 * K))
    edge = slice_ends(made["RowEdge"][0], (ROW_SLICE + 1) * K, n + 2 * K)
    rs.paste(built, tinted(edge, P["facet"] if chosen else P["edge"], 0.1 if chosen else 0.0),
             int((x0 - 1) * K), int((y0 - 1) * K))
    if chosen:
        rs.paste(built, tinted(made["RowGlassLight"][0], P["light"]), int((x1 - 11) * K), int((y0 - 10) * K))
        rs.paste(built, tinted(made["RowPoint"][0], P["light"]), int(x1 * K), int((y0 + 14) * K))
    return built, drawn


def ring_fit(made, lit):
    """Reinforce's ring and its glow built from the images and drawn by the kit (upgrade_pages.ring): (built, drawn)."""
    K, s = 4, 136.0
    ui.K = K
    sheet = ui.Sheet(s, s, "#000000")
    t = sheet.tile(0, 0, s, s)
    t.paint(t.poly([(0, 0), (s, 0), (s, s), (0, s)]), P["panel"][1])
    built = sheet.px.copy()
    sk.NOW.update(phase=0.0, rarity="Rare")
    up.ring(t, s / 2, s / 2, RING_R, lit)
    drawn = sheet.px.copy()
    box = 2 * (RING_R + 6)
    layers = [tinted(made["ReinforceBloom"][0], lit or RIM["Rare"], 0.66)]
    for (name, radius, _, _, (top, foot), _), colour in zip(RING_LINES, (lit or P["light"], P["facet"])):
        layers.append(tinted(graded(made[name][0], box, radius, top, foot), colour))
    layers.append(tinted(made["ReinforceComet"][0], P["glint"]))
    for px in layers:
        rs.paste(built, px, int(round((s / 2) * K - px.shape[1] / 2)), int(round((s / 2) * K - px.shape[0] / 2)))
    return built, drawn


def reinforce_fit(made, path):
    """equipment_cut_frame.png: the frame's and Reinforce's images as tinted, then rows and rings built against drawn.
    Returns [(case, mean, 99th)]."""
    ui.K = 4
    width, height = 1560, 620
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(20, 16, 20, "AR43, the Equipment frame's rows and Reinforce's ring: the images as tinted, then built "
                       "against drawn", "#EDE6D6", bold=0.2)
    t.paint(t.poly([(10, 56), (width - 10, 56), (width - 10, 216), (10, 216)]), P["panel"][1])
    shown = [("RowPlate", None, 0.0), ("RowGlass", None, 0.0), ("RowEdge", P["edge"], 0.0),
             ("RowGlassGlow", P["light"], 0.9), ("RowGlassWash", P["light"], 0.7), ("RowGlint", P["glint"], 0.8),
             ("RowGlassLight", P["light"], 0.0), ("RowPoint", P["light"], 0.0),
             ("ReinforceRing", P["light"], 0.1), ("ReinforceRingOuter", P["facet"], 0.5),
             ("ReinforceBloom", RIM["Rare"], 0.66), ("ReinforceComet", P["glint"], 0.0),
             ("ReinforceFlash", "#FFFFFF", 0.0),
             ("ReinforceWaveGlow", up.GOOD, 0.5), ("ReinforceCrack", None, 0.0)]
    x = 20.0
    for name, colour, transparency in shown:
        px = made[name][0]
        rs.paste(sheet.px, tinted(px, colour, transparency) if colour else px, round(x * 4), round(70 * 4))
        t.text(x, 196, 9, name, P["soft"])
        x += max(px.shape[1] / 4 + 4, 90) if px.shape[1] / 4 < 100 else px.shape[1] / 4 - 20
    t.paint(t.poly([(10, 228), (width - 10, 228), (width - 10, 606), (10, 606)]), P["panel"][1])
    t.text(20, 234, 14, "Built from the images (left, or above) and drawn by the kit (right, or below)", "#EDE6D6")
    worst = []
    y = 260.0
    for chosen in (False, True):
        b, d = row_fit(made, chosen)
        diff = np.abs(b[..., :3] - d[..., :3]).max(axis=-1)
        words = "the chosen row" if chosen else "a row at rest"
        worst.append((words, float(diff.mean()), float(np.percentile(diff, 99))))
        rs.paste(sheet.px, b, round(20 * 4), round(y * 4))
        rs.paste(sheet.px, d, round(340 * 4), round(y * 4))
        t.text(660, y + 20, 11, f"{words}: mean {worst[-1][1]:.3f}, 99th {worst[-1][2]:.3f}", P["soft"])
        y += ROW_H + 26
    x = 20.0
    for lit, words in ((None, "the ring at rest"), (up.GOOD, "risen"), (up.HURT, "failed")):
        b, d = ring_fit(made, lit)
        diff = np.abs(b[..., :3] - d[..., :3]).max(axis=-1)
        worst.append((words, float(diff.mean()), float(np.percentile(diff, 99))))
        rs.paste(sheet.px, b, round(x * 4), round(y * 4))
        rs.paste(sheet.px, d, round((x + 140) * 4), round(y * 4))
        t.text(x, y + 138, 11, f"{words}: mean {worst[-1][1]:.3f}, 99th {worst[-1][2]:.3f}", P["soft"])
        x += 300
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, path)
    return worst


def cut(out):
    """Writes build/handoff/UI/equipment: images/, equipment.json, equipment_cut.png (each image as the game tints it,
    then the sockets built from the images beside the drawn ones at 40, 44 and 46, with their differences)."""
    HANDOFF.joinpath("images").mkdir(parents=True, exist_ok=True)
    made = cut_images()
    made.update(cut_frame_reinforce_images())
    for name, (px, _) in made.items():
        rs.save(px, HANDOFF / "images" / f"{name}.png")
    entries = {name: dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]], **entry)
               for name, (px, entry) in made.items()}
    data = dict(
        what="AR43, Equipment's three screens, Reinforce, Jewels and War Emblems, each its own screen opened from "
             "Home's Equipment row: the frame's rows, the sockets' and Reinforce's images and every placement, from "
             "tools/blender/equipment_pages.py (cut); drawn in code, no image input",
        pixelsPerPoint=4,
        palette=dict(P, good=up.GOOD, hurt=up.HURT, note="Seam's lit glass (research's B, 15:04), as every screen "
                                                         "Home opens; its kit is build/handoff/UI/seam/seam.json; good "
                                                         "and hurt a rise's and a fail's"),
        layout=dict(placements(), reinforce=reinforce_placements(),
                    rowImages="every screen's list rows: at rest RowPlate and RowEdge; the chosen row RowGlassGlow, "
                              "RowGlass, RowGlassWash, RowGlint (clipped to the row), RowEdge (in the facet), "
                              "RowGlassLight and RowPoint, gliding as one"),
        reinforce=dict(states=dict(
            said=REINFORCE_STATES_SAID,
            ready="the press lit; the levels in the light", short="the press off; the stones' count in the hurt",
            neverReinforced="+0 to +1 at 100%: the same layout", rose="the chosen row's level, the level by the "
            "ring, the ring and its glow in the good", failed="the same in the hurt; the level stays"),
            motion=reinforce_motion(),
            rules="the odds before every press, adding to 100; nothing protects a fail; the odds and price keep "
                  "docs/roblox-rules.md's paid random items' rules (Reinforce's piece)"),
        layoutNote="measured on the smallest phone (568 by 320); the screen takes the phone's whole width as "
                   "Reinforce's does",
        presses=dict(
            rule="a press is drawn live only when it can act (research's must-fix, 14:27); with nothing to do it is "
                 "off, the well's plate with faint words. The lit one is Put in, Replace or Take out; Combine is "
                 "quiet when live, never lit",
            jewels={"Put in": "a bag jewel chosen and the socket empty", "Replace": "a bag jewel chosen and the "
                    "socket holding one, which goes back to the bag", "Take out": "the socket chosen alone, holding "
                    "one", "Combine": "three or more of the chosen level, under level 5; free and sure, its price "
                    "the three jewels (research, 14:27)"},
            emblems={"Put in": "a bag emblem chosen and the socket empty", "Replace": "a bag emblem chosen and the "
                     "socket holding one", "Take out": "the socket chosen alone, holding one"},
            free="putting in and taking out are free; no price is drawn"),
        numbers="jewel points by level and emblem stats are stand-ins until TR47 (research)",
        images=entries)
    (HANDOFF / "equipment.json").write_text(json.dumps(data, indent=2), encoding="utf-8", newline="\n")
    # the sheet: each image as tinted in the game, then built against drawn
    ui.K = 4
    rings = [JEWELS["jewels"][c]["words"] for c in COLOURS]
    width, height = 1240, 420
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(20, 16, 20, "AR43, Equipment's sockets: the images as the game tints them, then built against drawn",
           "#EDE6D6", bold=0.2)
    shown = [("SocketFill", None, 0.0), ("SocketLight", rings[0], 0.0), ("SocketEdge", rings[2], 0.15),
             ("SocketEdgeLit", P["light"], 0.0), ("SocketGlow", P["light"], 0.45),
             ("SocketEmptyJewel", rings[3], 0.45), ("SocketEmptyEmblem", P["faint"], 0.3),
             ("RowEmptyJewel", rings[1], 0.3), ("RowEmptyEmblem", P["faint"], 0.2)]
    x = 20.0
    t.paint(t.poly([(10, 60), (width - 10, 60), (width - 10, 210), (10, 210)]), P["panel"][1])
    for name, colour, transparency in shown:
        px = made[name][0]
        im = tinted(px, colour, transparency) if colour else px
        rs.paste(sheet.px, im, round(x * 4), round(80 * 4))
        t.text(x, 186, 12, name, P["soft"])
        x += max(px.shape[1] / 4 + 30, 128)
    t.paint(t.poly([(10, 230), (width - 10, 230), (width - 10, 400), (10, 400)]), P["panel"][1])
    t.text(20, 236, 14, "Built from the images (left of each pair) and drawn by the screens' code (right), on the "
                        "panel's dark, at 40, 44 and 46", "#EDE6D6")
    x, worst = 20.0, []
    cases = [(44, rings[0], False, True, 0.15, "a held red socket"), (44, rings[2], True, True, 0.15, "the chosen blue"),
             (46, RIM["Epic"], False, True, 0.15, "an Epic emblem's"), (46, P["edge"], False, False, 0.5, "an empty emblem"),
             (40, P["edge"], False, False, 0.5, "a bag cell"), (40, P["edge"], True, False, 0.5, "the chosen bag cell")]
    for s, rim, lit, light, rim_t, words in cases:
        d = drawn_socket(s, rim, lit, light, rim_t)
        ground = np.zeros_like(d)
        ground[..., :3], ground[..., 3] = rs.rgb(P["panel"][1]), 1.0
        gb, gd = ground.copy(), ground.copy()
        built_socket(made, s, rim, lit, light, rim_t, gb)          # rs.paste keeps the target's alpha: build on ground
        rs.paste(gd, d, 0, 0)
        diff = np.abs(gb[..., :3] - gd[..., :3]).max(axis=-1)
        worst.append((f"{words}, {s}", float(diff.mean()), float(np.percentile(diff, 99))))
        rs.paste(sheet.px, gb, round(x * 4), round(262 * 4))
        rs.paste(sheet.px, gd, round((x + s + 2 * GLOW_PAD + 4) * 4), round(262 * 4))
        t.text(x, 262 + s + 2 * GLOW_PAD + 6, 11, f"{words}, {s}", P["soft"])
        t.text(x, 262 + s + 2 * GLOW_PAD + 22, 11, f"mean {worst[-1][1]:.3f}, 99th {worst[-1][2]:.3f}", P["faint"])
        x += 2 * (s + 2 * GLOW_PAD) + 34
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, HANDOFF / "equipment_cut.png")
    worst += reinforce_fit(made, HANDOFF / "equipment_cut_frame.png")
    for words, mean, p99 in worst:
        print(f"fit {words}: mean {mean:.4f}, 99th {p99:.4f}")
    print(f"cut: {len(made)} images and equipment.json into {HANDOFF}")


def main():
    out = bl.out_dir()
    if "cut" in sys.argv[sys.argv.index("--") + 1:]:
        cut(out)
        return
    common = "at the smallest phone (568 x 320 points), in Seam's lit glass"
    sheet_of(out, "home_settings.png", f"AR43, Settings, its own screen from Home, {common}", SETTINGS_STATES,
             SETTINGS_NOTES)
    if "settings" in sys.argv[sys.argv.index("--") + 1:]:
        return
    sheet_of(out, "equipment_jewels.png", f"AR43, Equipment's Jewels, its own screen from Home, {common}",
             JEWEL_STATES, JEWEL_NOTES)
    sheet_of(out, "equipment_emblems.png", f"AR43, Equipment's War Emblems, its own screen from Home, {common}",
             EMBLEM_STATES, EMBLEM_NOTES)
    sheet_of(out, "equipment_reinforce.png", f"AR43, Equipment's Reinforce, its own screen from Home, {common}",
             REINFORCE_STATES, REINFORCE_NOTES)
    up._pics.clear()
    sheet_of(out, "equipment_close.png", "AR43, the two screens at a phone's own pixels (three a point)",
             [JEWEL_STATES[1], EMBLEM_STATES[1]], [], across=1, k=3)


if __name__ == "__main__":
    main()
