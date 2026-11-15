"""AR12, the lead's card mocked again, for the director's pick (the director, 2026-11-15: "I believe we should edit the
size and colors of the the top left voidkin hud actually.. like the hb color and width same for xp color and width and
onyx might not be the color it need add the new level icon"; research's list for the sheet is in AR12).

Mocks only: the card's own art is tools/blender/lead_card_art.py, the builder's. A take sets that script's sizes and
colours for the length of one drawing, draws its housing, its tab and its two lights again, and puts them back. The
portrait, its frame and the type's stud are the card's own images, unchanged. Each take is laid on the HUD as V2, Block
has it, with the new dock, over the dusk street and the noon one.

    blender -b --factory-startup --python tools/blender/lead_card_takes.py -- build/handoff/UI/hud/lead_card_takes

Writes the sheet lead_card_takes.png.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402
import hud_dock_sheet as dk  # noqa: E402
import voidkin_marks as vm  # noqa: E402

kit, ui, rs, c, lc, ss = h.kit, h.ui, h.rs, h.c, h.lc, h.ss
K4 = h.K4
WHITE = "#FFFFFF"

# A light: its ramp from its lit top to its deep foot, its sheen, the colour of the numbers written on it.
EMBER = dict(ramp=lc.EMBER["hp"], sheen=lc.EMBER["hp_sheen"], text=WHITE)
GREEN = dict(ramp=((0.0, "#D6FFE2"), (0.22, "#8CF5AE"), (0.5, "#45D27C"), (0.56, "#37BE6C"), (1.0, "#177A42")),
             sheen="#F0FFF4", text="#0B2A17")
IVORY = dict(ramp=((0.0, "#FFFFFF"), (0.22, "#FFF7E0"), (0.5, "#F3E3BC"), (0.56, "#E6D3A6"), (1.0, "#A8905E")),
             sheen=WHITE, text="#14161B")
SKY = dict(ramp=lc.EMBER["xp"], sheen=lc.EMBER["xp_sheen"])
LAVENDER = dict(ramp=((0.0, "#FFFFFF"), (0.22, "#EDE3FF"), (0.5, "#C9B2FF"), (0.56, "#B79CF5"), (1.0, "#6A52C4")), sheen=WHITE)
INDIGO = dict(ramp=((0.0, "#DDE2FF"), (0.22, "#A3AEFF"), (0.5, "#6C7BFF"), (0.56, "#5A69EE"), (1.0, "#2B36A8")), sheen="#EEF0FF")
HURT, LOST = "#8A3238", 0.08  # health just lost: a muted red ahead of the light, this share of the bar

# A body, as lead_card_art's Midnight is written.
VIOLET = dict(body=("#43348A", "#150F30"), tab=("#5545A6", "#211849"), glint="#E6DBFF", slot=("#07051A", "#120C2C"), ink="#000000")
GRAPHITE = dict(body=("#383E4C", "#15171C"), tab=("#464D5E", "#20242C"), glint="#D5DDEE", slot=("#050609", "#0E1015"), ink="#000000")
ROYAL = dict(body=("#2C44A8", "#0A1238"), tab=("#3B57C6", "#152058"), glint="#D6E0FF", slot=("#03061A", "#0A1030"), ink="#000000")

TAKES = (
    dict(key="Now", name="as it is", note="Midnight, the Ember health bar, the sky experience bar, the level on its old badge. "
         "Your health and the Shade's are the same red."),
    dict(key="A", name="Violet night", pal=VIOLET, hp=GREEN, xp=LAVENDER, hp_h=19.0, xp_h=6.0, x1=210.0, step=30.0,
         note="The body in the Voidkin's own violet, as the dock's Inventory. Health green and 2 points thicker, so yours "
              "never reads as the Shade's; experience in the Voidkin's lavender. Its length as now."),
    dict(key="B", name="Graphite", pal=GRAPHITE, hp=IVORY, xp=INDIGO, hp_h=16.0, xp_h=4.5, x1=210.0, step=8.0,
         note="The body in the dock's graphite. Health ivory, the fight's own light, a point thinner; experience an "
              "indigo thread nearly as long as the health bar. Its length as now."),
    dict(key="C", name="Royal, longer", pal=ROYAL, hp=GREEN, xp=IVORY, hp_h=17.0, xp_h=5.5, x1=226.0, step=40.0,
         note="The body a real blue in place of the near black. Health green and 16 points longer; experience a short "
              "ivory bar. It ends 6 points from the target's card here: on a 667 point phone it would run under it."),
)
CARD_X, CARD_Y = h.SAFE[0] + h.PAD, h.SAFE[1] + h.TOP
CROP = (58.0, 60.0, 290.0, 124.0)  # the card up close, cut from a screen: left, top, width, height


def parts(take):
    """A take's housing, tab and lights, drawn by the card's own script at the take's sizes, and where each goes."""
    names = ("HEALTH_H", "XP_H", "X1", "STEP", "XP_Y0", "Y1", "MID")
    kept = {n: getattr(lc, n) for n in names}
    lc.HEALTH_H, lc.XP_H, lc.X1, lc.STEP = take["hp_h"], take["xp_h"], take["x1"], take["step"]
    lc.XP_Y0 = lc.HEALTH_Y0 + lc.HEALTH_H + lc.GAP
    lc.Y1 = lc.XP_Y0 + lc.XP_H + lc.INSET
    lc.MID = lc.HEALTH_Y0 + lc.HEALTH_H + lc.GAP / 2
    try:
        body, rim, pad = lc.housing(take["pal"])
        tab, tab_rim, tpad, tcut = lc.tab(take["pal"])
        return dict(housing=(body, rim, pad), tab=(tab, tab_rim, tpad, tcut, lc.left(lc.TAB_FOOT), lc.left(lc.TAB_TOP)),
                    rows=lc.light_rows(), mid=lc.MID,
                    hp=lc.light(take["hp"]["ramp"], take["hp"]["sheen"], lc.HEALTH_H),
                    xp=lc.light(take["xp"]["ramp"], take["xp"]["sheen"], lc.XP_H))
    finally:
        for n, v in kept.items():
            setattr(lc, n, v)


def level(st, x, y, n, pal, trim):
    """TR17's level mark, in the card's colours: its plate the tab's, its light the rarity's."""
    w = {1: 56.0, 2: 64.0, 3: 73.0}[len(str(n))]
    st.lay("LevelPlate", x, y, w, vm.PLATE[1], tint=pal["tab"])
    st.lay("LevelPlateEdge", x, y, w, vm.PLATE[1], tint=(h.mix(trim, WHITE, 0.6), trim))
    st.icon("LevelChevrons", x + 11, y + 11, 14.0, tint=pal["body"][1])
    st.text(x + 27, y + 6, 11, "Lv", h.mix(trim, WHITE, 0.55))
    st.text(x + 41, y + 4, 15, str(n), h.IVORY)


def card(st, x, y, sc, take, p):
    """The lead's card as hud_colour_sheet.lead lays it, a take's parts in the housing's, the tab's and the lights'
    places, health just lost in a muted red, and the level's mark where the badge was."""
    e = h.DATA["images"]

    def paste(px, cx, cy):
        rs.paste(st.px, px, round((x + cx) * K4), round((y + cy) * K4))

    def at(name, px=None):
        en = e[name]
        paste(h.IMG[name] if px is None else px, en["at"][0] - en["pad"], en["at"][1] - en["pad"])

    rarity, who = sc["rarity"], sc["who"]
    trim, glow = h.TRIM[rarity], ui.RARITIES[rarity].get("glow")
    body, rim, pad = p["housing"]
    paste(body, lc.X0 - pad, lc.Y0 - pad)
    paste(lc.tinted(rim, trim), lc.X0 - pad, lc.Y0 - pad)
    for key, name, share in (("hp", "Health", sc["health"]), ("xp", "Xp", sc["xp"])):
        xl, ly, xr, tall = p["rows"][name]
        px, cut = p[key]
        front = lc.FILL_FROM + (xr - lc.FILL_FROM) * share
        run = tall * lc.SLANT
        if key == "hp":
            lost = min(front + (xr - lc.FILL_FROM) * LOST, xr)
            ox = front - run - 1.0
            t = kit.blank(lost - ox + 1.0, tall)
            t.paint(t.poly([(front - ox, 0), (lost - ox, 0), (lost - run - ox, tall), (front - run - ox, tall)]), c(HURT), 0.95)
            h.place(st, t, x + ox, y + ly)
        paste(lc.sliced(px, cut, max(front - xl + run + lc.GLOW, cut[0] + cut[2])), xl - run, ly)
    tab, tab_rim, tpad, tcut, tx, tleft = p["tab"]
    name_w = h.NAME_W[who]
    wide = 66.0 + name_w + 22.0 - tleft + (lc.TAB_FOOT - lc.TAB_TOP) * lc.SLANT + 2 * tpad
    paste(lc.sliced(tab, tcut, wide), tx - tpad, lc.TAB_TOP - tpad)
    paste(lc.tinted(lc.sliced(tab_rim, tcut, wide), trim), tx - tpad, lc.TAB_TOP - tpad)
    at(f"CardFace{who}")
    if glow:
        at(f"CardFrame{rarity}", lc.tinted(kit.IMAGES[f"CardFrameHalo{rarity}"]["px"], glow[0]))
    at(f"CardFrame{rarity}")
    if f"CardHead{who}" in e:
        at(f"CardHead{who}")
    level(st, x + 1, y + 75, sc["level"], take["pal"], trim)
    fx, fy, fw, fh = lc.FRAME
    r = h.STUD
    cx, cy = x + fx + fw + 0.5, y + p["mid"]
    st.lay("CardStudGlow", cx - r, cy - r, tint=ss.TYPES[sc["type_"]])
    st.lay("CardStud", cx - r, cy - r, tint=ss.TYPES[sc["type_"]])
    st.icon(f"Gem{sc['type_']}", cx, cy, 2 * r * 0.8 + 1)
    st.icon(f"Class{sc['class_']}", x + 66 + name_w + 11, y + 26, 13.0)
    st.text(x + 66, y + 20.6, 16, who, h.IVORY)
    xl, ly, xr, tall = p["rows"]["Health"]
    front = lc.FILL_FROM + (xr - lc.FILL_FROM) * sc["health"]
    st.text(x + (xl + front) / 2 + 4, y + ly + (tall - 13 * ui.CAP) / 2, 13, sc["hp"], take["hp"]["text"], "CENTER")


def screen(sc, take, p):
    """The HUD as V2, Block lays it out, with the new dock, and the lead's card as the take has it."""
    st = kit.Stage.__new__(kit.Stage)  # its ground is the street, not a fill
    st.w, st.h, st.items = h.W, h.H, []
    st.px = h.backdrop(sc["kind"])
    l, tp, r, b = h.SAFE
    h.phone(st)
    h.target(st, (l + r) / 2 - 108, tp + h.TOP + 18, 0.56)
    if p is None:
        h.lead(st, CARD_X, CARD_Y, sc)
    else:
        card(st, CARD_X, CARD_Y, sc, take, p)
    foot = tp + h.TOP + 89
    h.readout(st, l + h.PAD + 2, foot + 10, 58.0, sc["share"], sc["signature"])
    h.spectate(st, l + h.PAD + 2 + 58 + 10, foot + 10 + 7, 44.0, sc["eye"])
    px, py = r - h.PAD, tp + h.TOP + h.PILL + h.GAP
    h.pill(st, px - 120, tp + h.TOP, 120, h.CREDITS, h.BLOCK, "CoinMint", "35,170")
    if sc["covering"]:
        h.pill(st, px - 200, py, 200, h.POWER, h.BLOCK, "Bolt", "30 kW", "34 kW used", h.POWER, 1.0, drain=4 / 34,
               mark=("Battery", 96))
    else:
        h.pill(st, px - 200, py, 200, h.POWER, h.BLOCK, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
    dk.dock(st, (l + r) / 2 - dk.DW / 2, b - h.PAD - dk.DH)
    return h.bytes8(h.halve(st.px)), st.items


STRIP_W = 232.0


def levels(take):
    """The level's mark at 3, 12 and 100, in a Common's grey and a Mythical's red, on the take's body."""
    st = kit.Stage(STRIP_W, CROP[3], h.PARTS_GROUND)
    pal = take.get("pal")
    if pal is None:
        st.text(STRIP_W / 2, 54, 10, "The old badge holds the number alone.", h.NOTE, "CENTER")
        return h.bytes8(h.halve(st.px)), st.items
    st.text(10, 10, 10, "The level's mark at 3, 12 and 100:", h.NOTE)
    for j, rarity in enumerate(("Common", "Mythical")):
        x = 10.0
        for n in (3, 12, 100):
            level(st, x, 34 + j * 40, n, pal, h.TRIM[rarity])
            x += {1: 56.0, 2: 64.0, 3: 73.0}[len(str(n))] + 8
    return h.bytes8(h.halve(st.px)), st.items


def crop(px, items):
    """The card's corner of a screen, as drawn, and the words that fall in it."""
    x0, y0, w, tall = CROP
    k = 2  # a screen is kept at two pixels a point
    cut = px[round(y0 * k):round((y0 + tall) * k), round(x0 * k):round((x0 + w) * k)]
    words = [dict(i, x=i["x"] - x0, y=i["y"] - y0) for i in items
             if x0 <= i["x"] <= x0 + w - 30 and y0 <= i["y"] <= y0 + tall - 8]
    return cut, words


def sheet(out, rows):
    ui.K = 2
    m, head = 20.0, 64.0
    per = 40.0 + CROP[3] + 6 + h.H / 2 + 16
    sh = ui.Sheet(h.W + 2 * m, head + len(rows) * per, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: the lead's card, three takes beside today's (AR12)", h.HEAD)
    t.text(m, 40, 10, "Each take up close at dusk (Rook, Common) and at noon (Lyric's face on a Mythical), then on the whole "
           "HUD at a phone's size. A body, a health bar and an experience bar can be picked from different takes.", h.NOTE)
    y = head
    for take, shots, strip in rows:
        tt = sh.tile(m, y, h.W, 40)
        tt.text(0, 6, 13, f"{take['key']}: {take['name']}", h.HEAD)
        tt.text(0, 26, 10, take["note"], h.NOTE)
        y += 40
        for i, (px, items) in enumerate(shots):
            h.add(sh, *crop(px, items), m + i * CROP[2], y)
        h.add(sh, *strip, m + 2 * CROP[2], y)
        y += CROP[3] + 6
        for i, (px, items) in enumerate(shots):
            h.add(sh, h.halve(h.floats(px)), dk.small(items), m + i * (h.W / 2), y)
        y += h.H / 2 + 16
    kit.finish(sh, out / "lead_card_takes.png")


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
    vm.marks()
    rows = []
    for take in TAKES:
        p = parts(take) if "pal" in take else None
        shots = [screen(sc, take, p) for sc in (h.SCENES[0], h.SCENES[1])]
        rows.append((take, shots, levels(take)))
        h.stage(take["key"])
    h.BACKDROPS.clear()
    kit.IMAGES.clear()
    h.IMG.clear()
    sheet(out, rows)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
