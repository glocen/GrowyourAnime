"""AR12, the lead's card, a second round for the director's pick (the director, 2026-11-15, on the first three takes:
"let keep red.. it js need a different type of color different width (smaller imo) and  much better composition").

Health stays red, in a red that isn't the Shade's ember. "Smaller" is drawn both ways it can be read, thinner and
shorter. The card is composed again: one plate beside the portrait in place of a tab and two stepped blades, every row
ending on one slanted edge, the level's mark given a place of its own.

Mocks only, drawn here from the kit's shapes: the card's own art is tools/blender/lead_card_art.py, the builder's. The
portrait, its frame and the type's stud are the card's own images, unchanged.

    blender -b --factory-startup --python tools/blender/lead_card_round2.py -- build/handoff/UI/hud/lead_card_takes

Writes the sheet lead_card_round2.png.
"""
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lead_card_takes as lt  # noqa: E402

h, dk = lt.h, lt.dk
kit, ui, rs, c, lc, ss = h.kit, h.ui, h.rs, h.c, h.lc, h.ss
K4 = h.K4
WHITE = "#FFFFFF"
S = lc.SLANT
NORM = math.hypot(1.0, S)
MG = 14.0  # the drawing's margin round the card, for the plate's shadow
XA, INSET = 46.0, 4.0  # the plate's left end, under the frame; a slot's end inside the plate's

# A red: its ramp from lit top to deep foot, its sheen, the numbers' colour on it; `along`, its colours from root to front.
RUBY = dict(ramp=((0.0, "#FF9CAE"), (0.22, "#F2466A"), (0.5, "#D4163F"), (0.56, "#BE1238"), (1.0, "#6E0A26")),
            along=((0.0, "#6A0A2C"), (0.5, "#C41440"), (0.88, "#FF3D5E"), (1.0, "#FFB8C4")), sheen="#FFD9E0", text=WHITE)
CRIMSON = dict(ramp=RUBY["ramp"], sheen="#FFD9E0", text=WHITE)
ROSE = dict(ramp=((0.0, "#FFC6D2"), (0.22, "#FF7090"), (0.5, "#F0406A"), (0.56, "#DE3460"), (1.0, "#941A44")),
            sheen="#FFE8EE", text=WHITE)

TAKES = (
    dict(key="Now", name="as it is",
         notes=("Midnight, the Ember health bar 17 points thick and 143 long, the sky experience bar, the level on its old "
                "badge.", "Your health and the Shade's (top middle) are the same red.")),
    dict(key="D", name="Rail: thinner", pal=lt.VIOLET, hp=RUBY, xp=lt.LAVENDER, top=26.0, name_y=28.5, size=15.0,
         bar=(43.5, 52.5), xp_row=(54.5, 57.0), bottom=59.5, end=202.0, numbers="line", level="beside",
         notes=("\"Smaller\" read as thinner: 9 points thick (17 now), nearly as long. The numbers leave the bar and stand "
                "on the name's line. Ruby, wine at its root to hot at its front.",
                "One plate, every row ending on one edge; the level's mark tucked under it, beside the portrait.")),
    dict(key="E", name="Block: shorter", pal=lt.GRAPHITE, hp=CRIMSON, xp=lt.SKY, top=20.0, name_y=22.5, size=16.0,
         bar=(38.0, 54.0), xp_row=(56.0, 58.5), bottom=61.0, end=172.0, numbers="inside", level="under",
         notes=("\"Smaller\" read as shorter: 93 points long (143 now), as thick as now, the numbers still inside. A deep "
                "crimson. The name's row and the bar make one block of one length.",
                "The level's mark stands under the portrait, as a plinth. A long nickname would be set smaller here.")),
    dict(key="F", name="Cells: thinner and shorter", pal=lt.VIOLET, hp=ROSE, xp=lt.LAVENDER, top=26.0, name_y=28.5,
         size=15.0, bar=(43.5, 54.5), xp_row=(68.5, 71.0), bottom=73.5, end=176.0, numbers="under", num_y=58.0, cells=10,
         level="under",
         notes=("Both: 11 points thick and 97 long, in ten leaning cells, so its form differs from the Shade's bar as well "
                "as its red. A rose red. The numbers stand under it; experience is the plate's foot.",
                "The level's mark under the portrait.")),
)


def card(st, x, y, sc, take, p=None):
    """The lead's card composed again: one plate behind the portrait, its rows on one slant, a take's reds and sizes."""
    e = h.DATA["images"]

    def at(name, px=None):
        en = e[name]
        rs.paste(st.px, h.IMG[name] if px is None else px, round((x + en["at"][0] - en["pad"]) * K4),
                 round((y + en["at"][1] - en["pad"]) * K4))

    rarity, who, pal = sc["rarity"], sc["who"], take["pal"]
    trim, glow = h.TRIM[rarity], ui.RARITIES[rarity].get("glow")
    top, bottom, end = take["top"], take["bottom"], take["end"]
    by0, by1 = take["bar"]
    t = kit.blank(lc.W + 2 * MG, lc.H + 2 * MG)
    t.x -= MG
    t.y -= MG

    def lx(xr, yy):  # a point given on the plate's top line, carried down the slant
        return xr - (yy - top) * S

    def para(x0, x1, y0, y1):
        return t.poly([(lx(x0, y0), y0), (lx(x1, y0), y0), (lx(x1, y1), y1), (lx(x0, y1), y1)])

    def past(xr):  # how far right of the slanted line through xr
        return ((t.x - xr) + (t.y - top) * S) / NORM

    house = para(XA, end, top, bottom)
    t.glow(house, 4.5, ui.BLACK, 0.5)
    t.paint(house, lc.stops(t, (t.y - top) / (bottom - top), ((0, pal["body"][0]), (1, pal["body"][1]))))
    head = by0 - 1.5  # the name's row, in the tab's colours
    t.paint(np.maximum(house, t.y - head), lc.stops(t, (t.y - top) / (head - top), ((0, pal["tab"][0]), (1, pal["tab"][1]))))
    ui.over(t.px, c(WHITE), lc.cover(house) * np.clip(1 - np.abs(past(end - 44.0)) / 16.0, 0, 1) * 0.1)
    t.paint(np.maximum(house, np.abs(t.y - (top + 1.9)) - 0.55), c(pal["glint"]), 0.3)
    t.line(house + lc.RIM, 0.7, c(pal["ink"]), 0.8)
    t.line(house, lc.RIM, c(trim))

    fill0 = 61.0 + ((by0 + by1) / 2 - top) * S  # a bar's empty point: the frame's right side
    full = end - INSET - 1.5
    for key, (y0, y1), share in (("hp", take["bar"], sc["health"]), ("xp", take["xp_row"], sc["xp"])):
        light, tall = take[key], y1 - y0
        slot = para(XA + INSET, end - INSET, y0, y1)
        ui.over(t.px, lc.stops(t, (t.y - y0) / tall, ((0, pal["slot"][0]), (1, pal["slot"][1]))), lc.cover(slot) * 0.85)
        t.paint(np.maximum(slot, np.abs(t.y - y1 + 0.4) - 0.35), c(pal["glint"]), 0.18)
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
            col = lc.stops(t, past(fill0) * NORM / (front - fill0), light["along"])
            col = col + (1 - col) * (np.clip(1 - v / 0.35, 0, 1) * 0.3)[..., None]
            col = col * (1 - np.clip((v - 0.5) / 0.5, 0, 1) * 0.3)[..., None]
        t.paint(lit, col)
        t.paint(np.maximum(lit, np.abs(t.y - (y0 + tall * 0.22)) - max(tall * 0.07, 0.3)), c(light["sheen"]), 0.4)
        t.paint(np.maximum(lit, -ahead - 1.0), c(light["sheen"]), 0.5)
        if key == "hp" and take.get("cells"):
            for i in range(1, take["cells"]):
                seam = fill0 + (full - fill0) * i / take["cells"]
                t.paint(np.maximum(slot, np.abs(past(seam)) - 0.55), c(pal["slot"][0]), 0.95)
    h.place(st, t, x - MG, y - MG)

    n = sc["level"]
    if take["level"] == "beside":
        lt.level(st, x + 61, y + bottom + 2.5, n, pal, trim)
    at(f"CardFace{who}")
    if glow:
        at(f"CardFrame{rarity}", lc.tinted(kit.IMAGES[f"CardFrameHalo{rarity}"]["px"], glow[0]))
    at(f"CardFrame{rarity}")
    if f"CardHead{who}" in e:
        at(f"CardHead{who}")
    if take["level"] == "under":
        wide = {1: 56.0, 2: 64.0, 3: 73.0}[len(str(n))]
        lt.level(st, x + 29 - wide / 2, y + 76, n, pal, trim)
    r = h.STUD
    cx, cy = x + lc.FRAME[0] + lc.FRAME[2] + 0.5, y + (by0 + by1) / 2
    st.lay("CardStudGlow", cx - r, cy - r, tint=ss.TYPES[sc["type_"]])
    st.lay("CardStud", cx - r, cy - r, tint=ss.TYPES[sc["type_"]])
    st.icon(f"Gem{sc['type_']}", cx, cy, 2 * r * 0.8 + 1)
    size, ny = take["size"], take["name_y"]
    name_w = h.NAME_W[who] * size / 16.0
    st.text(x + 69, y + ny, size, who, h.IVORY)
    st.icon(f"Class{sc['class_']}", x + 69 + name_w + 11, y + ny + size * 0.34, 13.0)
    if take["numbers"] == "line":
        yy = ny + (size - 11) * ui.CAP
        st.text(x + lx(end, yy) - 9, y + yy, 11, sc["hp"], h.IVORY, "RIGHT")
    elif take["numbers"] == "inside":
        mid = (by0 + by1) / 2
        st.text(x + (lx(fill0, mid) + lx(full, mid)) / 2, y + by0 + (by1 - by0 - 12 * ui.CAP) / 2, 12, sc["hp"],
                take["hp"]["text"], "CENTER")
    else:
        st.text(x + 66, y + take["num_y"], 11, sc["hp"], h.IVORY)


def sheet(out, rows):
    ui.K = 2
    m, head, cap = 20.0, 64.0, 56.0
    w, tall = lt.CROP[2], lt.CROP[3]
    per = cap + tall + 6 + h.H / 2 + 16
    sh = ui.Sheet(h.W + 2 * m, head + len(rows) * per, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: the lead's card, round two: red kept, smaller, composed again (AR12)", h.HEAD)
    t.text(m, 40, 10, "Each take up close at dusk (Rook, Common) and at noon (Lyric's face on a Mythical), then on the whole "
           "HUD at a phone's size. The Shade's bar, top middle, keeps today's red. A red, a size and a body can be mixed.",
           h.NOTE)
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
            h.add(sh, h.halve(h.floats(px)), dk.small(items), m + i * (h.W / 2), y)
        y += h.H / 2 + 16
    kit.finish(sh, out / "lead_card_round2.png")


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
        shots = [lt.screen(sc, take, {} if "pal" in take else None) for sc in (h.SCENES[0], h.SCENES[1])]
        rows.append((take, shots, lt.levels(take)))
        h.stage(take["key"])
    h.BACKDROPS.clear()
    kit.IMAGES.clear()
    h.IMG.clear()
    sheet(out, rows)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
