"""AR12, the lead's card's colours in AR12's palette, for research's verdict and the director's pick (TR24, the director's
run, 2026-11-17: "voidkin hud being completely off"; asked on the card: "cant you see the level below it being not
composited well also yeah the colors might be an issue").

Take F as built stays: one plate beside the portrait, one ruby bar 11 points thick (the director's red), the numbers
under it, experience at the plate's foot. Only its colours change, and the level moves onto a badge on the portrait's
frame (`docs/ui.md`, the HUD, top left; TR24's must-fix 6, Faber's), drawn here in each take's own colours so the badge
and the card are picked together. The pills beside it wear V2, Block: a dark body of the system's colour, an edge in it,
and a block of it holding an ink mark. The takes ask which of that the card wears.

Mocks only: the card's own art is tools/blender/lead_card_art.py, the builder's. The portrait, its frame and the type's
stud are the card's own images, unchanged.

    blender -b --factory-startup --python tools/blender/lead_card_colours.py -- build/handoff/UI/hud/lead_card_takes

Writes the sheet lead_card_colours.png.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lead_card_round2 as r2  # noqa: E402

lt, h = r2.lt, r2.h
kit, ui, rs, c, lc, ss = h.kit, h.ui, h.rs, h.c, h.lc, h.ss
K4, S, MG = h.K4, r2.S, r2.MG
INK = h.INK

# Take F as built (Config.UIKit.LeadPlate): the plate's top and foot, its right end, the rows.
TOP, BOTTOM, END, XA, INSET = 26.0, 73.5, 176.0, 46.0, 4.0
NAME_Y, SIZE, NUM_Y = 28.5, 15.0, 58.0
BAR = (43.5, 54.5)

# The Voidkin's row in V2, Block (Config.UIKit.Systems.Voidkin).
LAV, LAV_PALE, LAV_BLOCK = "#DCCBFF", "#FAF7FF", ("#E7DAFF", "#BFADF0")
VK_PANEL = ("#35286B", "#171033")

TAKES = (
    dict(key="Now", name="as it is", body=lt.VIOLET["body"], band=lt.VIOLET["tab"], glint="#E6DBFF",
         slot=lt.VIOLET["slot"], edge="trim", edge_w=lc.RIM, xp=2.5, badge=None,
         notes=("Take F as built: a violet body with a lighter violet band behind the name, a rim in the rarity's trim, the "
                "experience thread 2.5 thick.", "The level's mark hangs under the plate on its own indigo, at another slant.")),
    dict(key="A", name="The Voidkin's block", body=VK_PANEL, band=None, glint=LAV_PALE, slot=("#0A0718", "#151030"),
         edge=LAV, edge_w=1.5, xp=3.0, badge="lavender",
         notes=("The card wears the Voidkin's row as the pills wear theirs: one dark violet body (no band), a lavender edge, "
                "and its block, the badge on the frame, the level in ink on lavender.",
                "Experience a lavender thread 3 thick, as Power's pill has its thread.")),
    dict(key="B", name="Graphite, lit lavender", body=("#2E323C", "#111318"), band=None, glint="#E4E8F2",
         slot=("#06070A", "#0E1015"), edge=LAV, edge_w=1.5, xp=3.0, badge="lavender",
         notes=("As A on the dock's graphite: no violet body, so the ruby sits on a neutral dark and the lavender is the "
                "card's only hue.", "The badge, the edge and experience lavender, as A.")),
    dict(key="C", name="Ink, its rarity", body=("#1B1828", "#09080F"), band=None, glint="#E6E2F2",
         slot=("#040308", "#0C0A14"), edge="trim", edge_w=1.5, xp=3.0, badge="trim",
         notes=("A near-black body; the edge and the badge take the lead's rarity, so the whole card says it, as the frame "
                "does.", "Experience lavender. A Mythical's edge stands near the ruby, a Legendary's near Power's yellow.")),
)


def badge_width(n):
    return {1: 33.0, 2: 41.0, 3: 49.0}[len(str(n))]


def badge(st, x, y, n, take, trim):
    """The level on a badge on the portrait frame's foot, its left at the frame's left: a block on the card's slant, the
    level's chevrons and number in ink on it."""
    w, tall = badge_width(n), 17.0
    t = kit.blank(w + 2 * MG, tall + 2 * MG)
    t.x -= MG
    t.y -= MG
    block = t.poly([(S * tall, 0), (w, 0), (w - S * tall, tall), (0, tall)])
    if take["badge"] == "lavender":
        top, foot, rim = LAV_BLOCK[0], LAV_BLOCK[1], INK
    else:
        top, foot, rim = h.mix(trim, "#FFFFFF", 0.45), h.mix(trim, "#FFFFFF", 0.1), INK
    t.glow(block, 3.0, ui.BLACK, 0.55)
    t.paint(block, lc.stops(t, t.y / tall, ((0, top), (1, foot))))
    t.paint(np.maximum(block, np.abs(t.y - 1.3) - 0.45), c("#FFFFFF"), 0.45)
    t.line(block, 1.0, c(rim), 0.9)
    h.place(st, t, x - MG, y - MG)
    st.icon("LevelChevrons", x + 11.0, y + tall / 2, 11.5, tint=INK)
    st.text(x + 18.5, y + 1.7, 14, str(n), INK)


def card(st, x, y, sc, take, p=None):
    """Take F as built, in a take's colours, the level on the take's badge (or, for today's, its mark under the plate)."""
    e = h.DATA["images"]

    def at(name, px=None):
        en = e[name]
        rs.paste(st.px, h.IMG[name] if px is None else px, round((x + en["at"][0] - en["pad"]) * K4),
                 round((y + en["at"][1] - en["pad"]) * K4))

    rarity, who = sc["rarity"], sc["who"]
    trim = h.TRIM[rarity]
    t = kit.blank(lc.W + 2 * MG, lc.H + 2 * MG)
    t.x -= MG
    t.y -= MG

    def lx(xr, yy):
        return xr - (yy - TOP) * S

    def para(x0, x1, y0, y1):
        return t.poly([(lx(x0, y0), y0), (lx(x1, y0), y0), (lx(x1, y1), y1), (lx(x0, y1), y1)])

    def past(xr):
        return ((t.x - xr) + (t.y - TOP) * S) / r2.NORM

    house = para(XA, END, TOP, BOTTOM)
    t.glow(house, 4.5, ui.BLACK, 0.5)
    t.paint(house, lc.stops(t, (t.y - TOP) / (BOTTOM - TOP), ((0, take["body"][0]), (1, take["body"][1]))))
    if take["band"]:
        head = BAR[0] - 1.5
        t.paint(np.maximum(house, t.y - head),
                lc.stops(t, (t.y - TOP) / (head - TOP), ((0, take["band"][0]), (1, take["band"][1]))))
        ui.over(t.px, c("#FFFFFF"), lc.cover(house) * np.clip(1 - np.abs(past(END - 44.0)) / 16.0, 0, 1) * 0.1)
    t.paint(np.maximum(house, np.abs(t.y - (TOP + 1.9)) - 0.55), c(take["glint"]), 0.3)
    t.line(house + lc.RIM, 0.7, c("#000000"), 0.8)
    t.line(house, take["edge_w"], c(trim if take["edge"] == "trim" else take["edge"]))

    xp_row = (BOTTOM - 2.0 - take["xp"], BOTTOM - 2.0)
    fill0 = 61.0 + (sum(BAR) / 2 - TOP) * S
    full = END - INSET - 1.5
    for key, (y0, y1), share in (("hp", BAR, sc["health"]), ("xp", xp_row, sc["xp"])):
        light, tall = (r2.RUBY if key == "hp" else lt.LAVENDER), y1 - y0
        slot = para(XA + INSET, END - INSET, y0, y1)
        ui.over(t.px, lc.stops(t, (t.y - y0) / tall, ((0, take["slot"][0]), (1, take["slot"][1]))), lc.cover(slot) * 0.85)
        front = fill0 + (full - fill0) * share
        ahead = past(front)
        ui.over(t.px, c(light["ramp"][2][1]),
                np.clip(1 - np.maximum(ahead, 0) / lc.GLOW, 0, 1) * (ahead > 0) * lc.cover(slot) * 0.35)
        if key == "hp":
            t.paint(para(front, min(front + (full - fill0) * lt.LOST, full), y0, y1), c(lt.HURT), 0.95)
        lit = para(XA + INSET, front, y0, y1)
        v = np.clip((t.y - y0) / tall, 0, 1)
        col = lc.stops(t, v, light["ramp"])
        if light.get("along"):
            col = lc.stops(t, past(fill0) * r2.NORM / (front - fill0), light["along"])
            col = col + (1 - col) * (np.clip(1 - v / 0.35, 0, 1) * 0.3)[..., None]
            col = col * (1 - np.clip((v - 0.5) / 0.5, 0, 1) * 0.3)[..., None]
        t.paint(lit, col)
        t.paint(np.maximum(lit, np.abs(t.y - (y0 + tall * 0.22)) - max(tall * 0.07, 0.3)), c(light["sheen"]), 0.4)
        t.paint(np.maximum(lit, -ahead - 1.0), c(light["sheen"]), 0.5)
    h.place(st, t, x - MG, y - MG)

    n = sc["level"]
    if take["badge"] is None:
        lt.level(st, x + 67, y + 75, n, lt.VIOLET, trim)
    at(f"CardFace{who}")
    at(f"CardFrame{rarity}")
    if f"CardHead{who}" in e:
        at(f"CardHead{who}")
    if take["badge"]:
        badge(st, x + 1.0, y + 74.0, n, take, trim)
    r = h.STUD
    cx, cy = x + lc.FRAME[0] + lc.FRAME[2] + 0.5, y + sum(BAR) / 2
    st.lay("CardStudGlow", cx - r, cy - r, tint=ss.TYPES[sc["type_"]])
    st.lay("CardStud", cx - r, cy - r, tint=ss.TYPES[sc["type_"]])
    st.icon(f"Gem{sc['type_']}", cx, cy, 2 * r * 0.8 + 1)
    name_w = h.NAME_W[who] * SIZE / 16.0
    words = LAV_PALE if take["badge"] == "lavender" else h.IVORY
    st.text(x + 69, y + NAME_Y, SIZE, who, words)
    st.icon(f"Class{sc['class_']}", x + 69 + name_w + 11, y + NAME_Y + SIZE * 0.34, 13.0)
    st.text(x + 66, y + NUM_Y, 11, sc["hp"], words)


def levels(take):
    """The badge at 3, 12 and 100, on a Common's frame colours and a Mythical's."""
    st = kit.Stage(lt.STRIP_W, lt.CROP[3], h.PARTS_GROUND)
    if take["badge"] is None:
        st.text(lt.STRIP_W / 2, 54, 10, "Today: TR17's mark under the plate.", h.NOTE, "CENTER")
        return h.bytes8(h.halve(st.px)), st.items
    st.text(10, 10, 10, "The badge at 3, 12 and 100:", h.NOTE)
    for j, rarity in enumerate(("Common", "Mythical")):
        bx = 10.0
        for n in (3, 12, 100):
            badge(st, bx, 34 + j * 40, n, take, h.TRIM[rarity])
            bx += badge_width(n) + 10
    return h.bytes8(h.halve(st.px)), st.items


def sheet(out, rows):
    ui.K = 2
    m, head, cap = 20.0, 64.0, 56.0
    w, tall = lt.CROP[2], lt.CROP[3]
    per = cap + tall + 6 + h.H / 2 + 16
    sh = ui.Sheet(h.W + 2 * m, head + len(rows) * per, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: the lead's card's colours in AR12's palette (TR24)", h.HEAD)
    t.text(m, 40, 10, "Take F as built, its colours only, the level on a badge on the frame. Up close at dusk (Rook, Common) "
           "and noon (a Mythical), then the whole HUD at a phone's size. Health stays ruby.", h.NOTE)
    y = head
    for take, shots, strip in rows:
        tt = sh.tile(m, y, h.W, cap)
        tt.text(0, 6, 13, f"{take['key']}: {take['name']}", h.HEAD)
        for i, line in enumerate(take["notes"]):
            tt.text(0, 26 + i * 14, 10, line, h.NOTE)
        y += cap
        for i, (px, items) in enumerate(shots):
            h.add(sh, *lt.crop(px, items), m + i * w, y)
        h.add(sh, *strip, m + 2 * w, y)
        y += tall + 6
        for i, (px, items) in enumerate(shots):
            h.add(sh, h.halve(h.floats(px)), lt.dk.small(items), m + i * (h.W / 2), y)
        y += h.H / 2 + 16
    kit.finish(sh, out / "lead_card_colours.png")


def main():
    out = bl.out_dir()
    ui.K = K4
    h.stage("started")
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    h.icons()
    h.card_images()
    lt.vm.marks()
    lt.card = card  # lt.screen lays its card through the module's name
    rows = []
    for take in TAKES:
        shots = [lt.screen(sc, take, {}) for sc in (h.SCENES[0], h.SCENES[1])]
        rows.append((take, shots, levels(take)))
        h.stage(take["key"])
    h.BACKDROPS.clear()
    kit.IMAGES.clear()
    h.IMG.clear()
    sheet(out, rows)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
