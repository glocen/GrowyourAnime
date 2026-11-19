"""AR43: Equipment's Jewels and War Emblems, each its own screen, opened from Home's Equipment row as Reinforce is (the
director, about 12:21; research's step into a screen, 13:20). At the smallest phone, in every state, for research's
verdict before the cut. Drawn in code: the kit's shapes from upgrade_pages.py, the shipped jewel and emblem pictures,
Blender's own face. Nothing is exported.

The director's words (docs/decisions.md, 2026-11-19, 02:58 to 03:38): jewels and War Emblems are put in and taken out
on Equipment's pages only; the gear's card just shows what's socketed. Every gear piece holds five jewels, one of each
colour, each giving flat points of its colour's Basic Attribute; three of one level make one of the next (12:10 of
2026-11-17). An item holds one emblem on Common, two on Uncommon, three on Rare, four from Epic; each emblem carries
one stat; putting one in or taking it out is free (docs/design.md, "Jewels", "War Emblems").

Reinforce's frame, kept: the band (Roblox's buttons, Back, the screen's name, the Credits and kWh); only the worn gear
down the left, a row each, the chosen one lit and pointing at the work; the chosen item's work on the right. In AR40's
C, as every screen Home opens. Each list row shows what its item holds, so a gap is seen before a row is tapped:
    Jewels        the five sockets in a row, each ringed in its colour, its points under it; under them the bag's
                  jewels of the chosen socket's colour, levels 1 to 5 with their counts; one line of what the chosen
                  one does, and the presses: Put in (Replace when the socket holds one, Take out when the socket is
                  chosen alone) and Combine (three of a level into one of the next).
    War Emblems   the item's sockets by its rarity, each its emblem and its stat under it; under them the bag's
                  emblems by rarity, scrolling; one line of the chosen one, and the press: Put in, Replace or Take out.
Jewels' points and emblems' stats are stand-ins (research's numbers); no price is drawn, since putting in and taking
out are free and Combine's cost, if any, is research's.

    blender -b --factory-startup --python tools/blender/equipment_pages.py -- <abs out>

Writes equipment_jewels.png and equipment_emblems.png (each screen's states) and equipment_close.png (one state of
each at the phone's own pixels, three to a point, to read the small parts).
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

P = dict(up.C_SYS)
up.P = P                                       # the kit draws in C, as every screen Home opens (research, 12:56)
W, H, SMALL, TITLE = up.W, up.H, up.SMALL, up.TITLE
TOP, FOOT = 60, up.FOOT                        # a screen's page under its band, as Reinforce's (home_panel.screen)
LIST, WORK = (8, 300), (306, 560)
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

def frame(t, name):
    up.box(t, 0, 0, W, H, P["backing"], cut=0)
    up.band(t, "Equipment")
    t.text(232, 20, TITLE, name, P["text"], bold=0.35)


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
    t.paint(d, t.ramp("#0B1418", "#08100F", (t.y - y) / s))
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


def jewel_state(slot, colour, bag, pick, worn, mode):
    """A state of the Jewels screen: `mode` is what the chosen pair asks (put, replace, out, combine, none)."""
    attribute = JEWELS["jewels"][colour]["attribute"]
    now = worn.get(slot, {}).get(colour)
    gain = lambda level: f"{attribute} +{POINTS[level - 1]}"  # noqa: E731
    if mode == "put":
        lines = [(f"Level {pick}: {gain(pick)}", P["text"], 0.3), ("Free to put in and take out", P["soft"], 0.0)]
        kinds = [("Combine", "quiet", 92), ("Put in", "one", 84)]
    elif mode == "replace":
        lines = [(f"Level {pick}: {gain(pick)}", P["text"], 0.3),
                 (f"Its level {now} goes back to your bag", P["soft"], 0.0)]
        kinds = [("Combine", "quiet", 92), ("Replace", "one", 84)]
    elif mode == "out":
        lines = [(f"Level {now}: {gain(now)}", P["text"], 0.3), ("It goes back to your bag", P["soft"], 0.0)]
        kinds = [("Take out", "one", 92)]
    elif mode == "combine":
        lines = [(f"3 of level {pick} make 1 of level {pick + 1}", P["text"], 0.3),
                 (f"You have {bag[pick]}", P["soft"], 0.0)]
        kinds = [("Put in", "quiet", 84), ("Combine", "one", 92)]
    else:
        lines = [(f"No {colour.lower()} jewel in your bag", P["soft"], 0.0),
                 ("Chests and foes drop them", P["faint"], 0.0)]
        kinds = [("Put in", "off", 84)]
    return dict(screen="Jewels", slot=slot, colour=colour, bag=bag, pick=pick, worn=worn, said=lines,
                presses=kinds)


WORN_JEWELS = {
    "Main Hand": {"Red": 3, "Green": 2, "Blue": 1, "Purple": 2},
    "Off Hand": {"Red": 1, "Green": 1},
    "Helmet": {"Red": 4, "Green": 3, "Blue": 3, "Yellow": 2, "Purple": 3},
    "Chest Armor": {"Yellow": 2},
}
JEWEL_STATES = [
    ("Nothing in it: Iron Shoulders, the red socket, a level 2 chosen",
     jewel_state("Shoulders", "Red", {1: 7, 2: 2}, 2, WORN_JEWELS, "put")),
    ("A better one for a held socket: the blade's red, level 3, for a level 4",
     jewel_state("Main Hand", "Red", {1: 7, 2: 2, 4: 1}, 4, WORN_JEWELS, "replace")),
    ("Three of a level make one of the next: seven level 1 reds",
     jewel_state("Main Hand", "Red", {1: 7, 2: 2, 4: 1}, 1, WORN_JEWELS, "combine")),
    ("The socket alone: the blade's yellow, empty, none in the bag",
     jewel_state("Main Hand", "Yellow", {}, None, WORN_JEWELS, "none")),
    ("Full: the Stormcall Helm, its blue chosen to take out",
     jewel_state("Helmet", "Blue", {1: 3}, None, WORN_JEWELS, "out")),
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


def emblem_state(slot, socket, pick, mode, worn=WORN_EMBLEMS, bag=BAG):
    rarity_of = lambda key: EMBLEMS[key]["rarity"]  # noqa: E731
    line = lambda key: (f"{EMBLEMS[key]['set']} · {rarity_of(key)}", RIM[rarity_of(key)], 0.3)  # noqa: E731
    stat = lambda key: f"{STATS[key][0]} {STATS[key][1]}"  # noqa: E731
    held = worn.get(slot, [])
    now = held[socket] if socket is not None and socket < len(held) else None
    if mode == "put":
        lines, kinds = [line(pick), (stat(pick), P["text"], 0.0)], [("Put in", "one", 84)]
    elif mode == "replace":
        lines = [line(pick), (f"{stat(pick)} (now {now[2]})", P["text"], 0.0)]
        kinds = [("Replace", "one", 84)]
    elif mode == "out":
        lines, kinds = [line(now[0]), (f"{now[1]} {now[2]}", P["text"], 0.0)], [("Take out", "one", 92)]
    else:
        lines = [("Choose one below", P["soft"], 0.0), ("Putting in is free", P["faint"], 0.0)]
        kinds = [("Put in", "off", 84)]
    return dict(screen="War Emblems", slot=slot, socket=socket, pick=pick, worn=worn, bag=bag, said=lines,
                presses=kinds)


EMBLEM_STATES = [
    ("A Common item's one socket, empty, nothing chosen", emblem_state("Shoulders", 0, None, "none")),
    ("The Epic helm's four, two empty: Zenith chosen for the third", emblem_state("Helmet", 2, "Zenith", "put")),
    ("A held socket chosen alone: Moonward, to take out", emblem_state("Helmet", 0, None, "out")),
    ("The Rare blade full: Radiance chosen for Warhorn's socket", emblem_state("Main Hand", 1, "Radiance", "replace")),
]
EMBLEM_NOTES = [
    "The director's War Emblems: a black rock star, its top its rarity's colour, a set's white mark; one socket on Common,",
    "two on Uncommon, three on Rare, four from Epic; one stat each; put in and taken out here only, free. Reinforce's",
    "frame: each row shows its item's sockets (an emblem, or an empty star). Right: the sockets, the chosen one lit, each",
    "emblem's stat under it; the bag's emblems by rarity (Rarity sorts), the row scrolling under the panel's edge; one",
    "line and the press: Put in, Replace or Take out. Stats are stand-ins; the sort's tap is 44 points over its pill.",
]


# --- the sheets -----------------------------------------------------------------------------------------------------

def phone(sheet, ox, oy, st):
    t = sheet.tile(ox, oy, W, H)
    frame(t, st["screen"])
    if st["screen"] == "Jewels":
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


def main():
    out = bl.out_dir()
    common = "at the smallest phone (568 x 320 points), in AR40's C"
    sheet_of(out, "equipment_jewels.png", f"AR43, Equipment's Jewels, its own screen from Home, {common}",
             JEWEL_STATES, JEWEL_NOTES)
    sheet_of(out, "equipment_emblems.png", f"AR43, Equipment's War Emblems, its own screen from Home, {common}",
             EMBLEM_STATES, EMBLEM_NOTES)
    up._pics.clear()
    sheet_of(out, "equipment_close.png", "AR43, the two screens at a phone's own pixels (three a point)",
             [JEWEL_STATES[1], EMBLEM_STATES[1]], [], across=1, k=3)


if __name__ == "__main__":
    main()
