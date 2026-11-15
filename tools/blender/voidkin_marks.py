"""TR17, the Voidkin screen's marks (docs/test-requests.md, TR17, "The director's notes on the mock"; the build's grey
stand-ins are in src/client/UI/VoidkinScreen/init.luau): the rail's seven pages, favourite, lock and rename beside the
name, the level's mark (the director, 2026-11-15: "also the levels text design of voidkin need to change"), and Combat
Power's emblem.

A mark is one plain shape, white, so the screen tints it by its state: it has to read at 14 points across on a rail
button. Combat Power's emblem is the one image in colour. The shapes are distances, negative inside, as the kit's are.

    blender -b --factory-startup --python tools/blender/voidkin_marks.py -- build/handoff/UI/voidkin/marks

Writes images/, voidkin_marks.json and the sheet voidkin_marks.png.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402

kit, ui, rs, c = h.kit, h.ui, h.rs, h.c
K4, BOX = h.K4, kit.BOX
WHITE = "#FFFFFF"


def poly(t, x, y, r, pts):
    return t.poly([(x + r * u, y + r * v) for u, v in pts])


def line(t, x, y, r, a, b, w):
    return h.seg(t, (x + r * a[0], y + r * a[1]), (x + r * b[0], y + r * b[1]), w * r)


def disc(t, x, y, r, at, radius):
    return np.hypot(t.x - x - r * at[0], t.y - y - r * at[1]) - radius * r


def arc(t, x, y, r, at, radius, w):
    return np.abs(np.hypot(t.x - x - r * at[0], t.y - y - r * at[1]) - radius * r) - w * r / 2


def star(t, x, y, r, at, size, points=5, inner=0.44):
    return poly(t, x + r * at[0], y + r * at[1], r * size, [
        (math.sin(a) * k, -math.cos(a) * k) for a, k in
        ((math.pi * i / points, 1.0 if i % 2 == 0 else inner) for i in range(2 * points))])


def cut(d, *holes):
    """A shape with others cut clean out of it."""
    return np.maximum(d, -np.minimum.reduce(holes))


# --- the rail's pages ---------------------------------------------------------------------------------------------

def overview(t, x, y, r):
    """The Voidkin itself: a head over its shoulders."""
    return np.minimum(disc(t, x, y, r, (0, -0.5), 0.42),
                      np.maximum(disc(t, x, y, r, (0, 1.0), 0.98), t.y - y - 0.92 * r))


def bag(t, x, y, r):
    """A satchel: its handle, its flap cut across the body, its clasp."""
    body = poly(t, x, y, r, ((-0.95, -0.3), (0.95, -0.3), (0.82, 0.72), (0.55, 1.0), (-0.55, 1.0), (-0.82, 0.72)))
    flap = np.minimum(line(t, x, y, r, (-0.95, -0.3), (0, 0.28), 0.19), line(t, x, y, r, (0, 0.28), (0.95, -0.3), 0.19))
    handle = np.maximum(arc(t, x, y, r, (0, -0.3), 0.5, 0.26), t.y - y + 0.3 * r)
    clasp = poly(t, x, y, r, ((0, 0.02), (0.24, 0.3), (0, 0.6), (-0.24, 0.3)))
    return np.minimum.reduce([cut(body, flap), handle, clasp])


def kit_page(t, x, y, r):
    """An ability's tile, the kit's own two cut corners, a spark cut through it."""
    k = 0.42
    tile = poly(t, x, y, r, ((-0.95 + k, -0.95), (0.95, -0.95), (0.95, 0.95 - k), (0.95 - k, 0.95), (-0.95, 0.95), (-0.95, -0.95 + k)))
    return cut(tile, star(t, x, y, r, (0, 0), 0.74, 4, 0.3))


def stars(t, x, y, r):
    """Star rank: one star and the next, smaller."""
    return np.minimum(star(t, x, y, r, (-0.2, 0.18), 0.86), star(t, x, y, r, (0.72, -0.7), 0.4))


def forge(t, x, y, r):
    """An anvil: its horn to the left, its waist, its foot."""
    return poly(t, x, y, r, ((-1.0, -0.55), (-0.3, -0.78), (1.0, -0.78), (1.0, -0.3), (0.42, -0.1), (0.3, 0.26), (0.8, 0.5),
                             (0.8, 0.86), (-0.72, 0.86), (-0.72, 0.5), (-0.22, 0.26), (-0.3, -0.08), (-0.64, -0.2)))


def jewels(t, x, y, r):
    """A cut stone from the side: its crown, its girdle, its point."""
    stone = poly(t, x, y, r, ((-0.56, -0.82), (0.56, -0.82), (1.0, -0.3), (0, 0.96), (-1.0, -0.3)))
    w = 0.15
    return cut(stone, line(t, x, y, r, (-1.0, -0.3), (1.0, -0.3), w),
               line(t, x, y, r, (-0.32, -0.3), (0, 0.96), w), line(t, x, y, r, (0.32, -0.3), (0, 0.96), w),
               line(t, x, y, r, (-0.56, -0.82), (-0.32, -0.3), w), line(t, x, y, r, (0.56, -0.82), (0.32, -0.3), w))


def emblems(t, x, y, r):
    """A war banner hung from its bar, swallow-tailed, a chevron cut in it."""
    bar = poly(t, x, y, r, ((-0.95, -0.98), (0.95, -0.98), (0.95, -0.72), (-0.95, -0.72)))
    cloth = poly(t, x, y, r, ((-0.7, -0.58), (0.7, -0.58), (0.7, 0.98), (0, 0.5), (-0.7, 0.98)))
    chevron = np.minimum(line(t, x, y, r, (-0.4, -0.22), (0, 0.1), 0.22), line(t, x, y, r, (0, 0.1), (0.4, -0.22), 0.22))
    return np.minimum(bar, cut(cloth, chevron))


# --- beside the name ----------------------------------------------------------------------------------------------

def heart(t, x, y, r):
    """Favourite: a round heart (the Healer's mark is a cut one, so this one has no straight edge above its point)."""
    return np.minimum.reduce([disc(t, x, y, r, (-0.46, -0.3), 0.52), disc(t, x, y, r, (0.46, -0.3), 0.52),
                              poly(t, x, y, r, ((-0.93, -0.08), (0, -0.3), (0.93, -0.08), (0, 0.98)))])


def heart_off(t, x, y, r):
    return cut(heart(t, x, y, r), heart(t, x, y + 0.03 * r, 0.68 * r))


def _lock(t, x, y, r, open_):
    body = poly(t, x, y, r, ((-0.8, -0.08), (0.8, -0.08), (0.8, 0.74), (0.58, 0.96), (-0.58, 0.96), (-0.8, 0.74)))
    hole = np.minimum(disc(t, x, y, r, (0, 0.3), 0.17), line(t, x, y, r, (0, 0.3), (0, 0.62), 0.16))
    up = -0.62 if open_ else -0.34
    bow = np.maximum(arc(t, x, y, r, (0, up), 0.46, 0.26), t.y - y - up * r)
    legs = np.minimum(line(t, x, y, r, (-0.46, up), (-0.46, 0.0), 0.26),
                      line(t, x, y, r, (0.46, up), (0.46, up + 0.2 if open_ else 0.0), 0.26))
    return np.minimum.reduce([cut(body, hole), bow, legs])


def lock_on(t, x, y, r):
    return _lock(t, x, y, r, False)


def lock_off(t, x, y, r):
    return _lock(t, x, y, r, True)


def rename(t, x, y, r):
    """A pencil on the slant, its band cut, and the line it writes."""
    shaft = line(t, x, y, r, (-0.36, 0.3), (0.62, -0.68), 0.5)
    band = line(t, x, y, r, (0.1, -0.52), (0.46, -0.16), 0.12)
    tip = poly(t, x, y, r, ((-1.0, 0.94), (-0.84, 0.36), (-0.42, 0.78)))
    under = line(t, x, y, r, (0.0, 0.9), (0.95, 0.9), 0.17)
    return np.minimum.reduce([cut(shaft, band), tip, under])


def chevrons(t, x, y, r):
    """The level's mark: two chevrons, rising."""
    def one(o):
        return np.minimum(line(t, x, y, r, (-0.8, 0.16 + o), (0, -0.5 + o), 0.3), line(t, x, y, r, (0, -0.5 + o), (0.8, 0.16 + o), 0.3))
    return np.minimum(one(-0.3), one(0.42))


PAGES = (("Overview", overview, "the Voidkin's whole sheet"), ("Bag", bag, "the bag"), ("Kit", kit_page, "its abilities"),
         ("Stars", stars, "its star rank"), ("Forge", forge, "the forge"), ("Jewels", jewels, "jewels"),
         ("Emblems", emblems, "War Emblems"))
WORDS = {"Emblems": "War Emblems"}  # a page's word under its button, where it isn't its image's name
SOON = ("Forge", "Jewels", "War Emblems")  # drawn greyed on the sheet, to see a mark hold at a third of its light
BESIDE = (("FavouriteOn", heart, "favourite, set"), ("FavouriteOff", heart_off, "favourite, not set"),
          ("LockOn", lock_on, "locked"), ("LockOff", lock_off, "not locked"), ("Rename", rename, "rename"),
          ("LevelChevrons", chevrons, "the level's mark, dark on its plate's lit cap"))
PLATE = (54.0, 22.0, 5.0, 17.0)  # the level's plate: its width as drawn, its height, each end's lean, its lit cap


def marks():
    m, r = BOX / 2, 12.0
    for name, draw, use in tuple(("Page" + n, d, "the rail: " + u) for n, d, u in PAGES) + BESIDE:
        t = kit.blank(BOX, BOX)
        t.paint(draw(t, m, m, r), c(WHITE))
        kit.keep(name, t, "text", use=use)
    # The level's plate: a tab that leans as the bars do, a lit cap at its left end for the chevrons. Its body and its
    # light are two white images: the body takes the room's button colours, the light (the rim and the cap) the room's
    # accent. It stretches between its two ends.
    w, hh, lean, cap = PLATE
    ends = (lean + cap + 2, 0, lean + 3, 0)
    t = kit.blank(w, hh)
    d = t.poly([(lean, 0), (w, 0), (w - lean, hh), (0, hh)])
    t.paint(d, c(WHITE))
    kit.keep("LevelPlate", t, "button", cut=ends, use="the level's plate: its body")
    t = kit.blank(w, hh)
    t.paint(np.minimum(np.abs(d + 0.7) - 0.7, t.poly([(lean, 0), (lean + cap, 0), (cap, hh), (0, hh)])), c(WHITE))
    kit.keep("LevelPlateEdge", t, "accent", cut=ends, use="the level's plate: its rim and its lit cap, over the body")
    # Combat Power: three shards rising from one foot, the middle one white-hot. The Voidkin's lavender, since it's the
    # Voidkin's own strength; the one image here in colour.
    a = h.VOIDKIN
    t = kit.blank(BOX, BOX)
    mid = poly(t, m, m, r, ((0, -1.06), (0.32, -0.22), (0.15, 0.98), (-0.15, 0.98), (-0.32, -0.22)))
    left = poly(t, m, m, r, ((-0.84, -0.5), (-0.5, -0.06), (-0.36, 0.98), (-0.62, 0.98), (-0.98, 0.04)))
    right = poly(t, m, m, r, ((0.84, -0.5), (0.5, -0.06), (0.36, 0.98), (0.62, 0.98), (0.98, 0.04)))
    d = np.minimum.reduce([mid, left, right])
    v = (t.y - m + r) / (2 * r)
    t.paint(d - 2.0, c(h.STROKE))
    t.paint(np.minimum(left, right), h.ramp3(t, a, h.mix(a, h.DEEP[a], 0.45), h.DEEP[a], v))
    t.paint(mid, h.ramp3(t, WHITE, h.PALE[a], a, v))
    t.paint(np.maximum(mid, t.x - m), c(h.DEEP[a]), 0.28)  # its far facet in shade
    t.paint(np.maximum(mid, h.seg(t, (m, m - 0.92 * r), (m, m + 0.9 * r), 1.0)), c(WHITE), 0.9)
    kit.keep("CombatPower", t, use="Combat Power, left of its number")


def shot():
    """The marks on one picture: each at three sizes, then in their places."""
    p = h.ROOMS["Graphite, Voidkin"]
    accent = p["accent"]
    st = kit.Stage(880.0, 560.0, h.PARTS_GROUND)
    st.text(12, 8, 11, "Each mark at 48, 24 and 14 points across (14 is its size on a rail button at rest). White: the screen tints it.", h.HEAD)
    names = ["Page" + n for n, _, _ in PAGES] + [n for n, _, _ in BESIDE] + ["CombatPower"]
    for i, name in enumerate(names):
        cx = 12 + 30 + i * 61
        for cy, size in ((62, 48.0), (112, 24.0), (140, 14.0)):
            st.icon(name, cx, cy, size)
        st.text(cx, 156, 9, name.replace("Page", ""), h.NOTE, "CENTER")
    st.text(12, 180, 11, "In their places, in the Voidkin's room: the rail with three pages chosen in turn, the unbuilt ones "
            "greyed; the name with its marks; the level's mark; Combat Power.", h.HEAD)
    h.MENU.update({WORDS.get(n, n): d for n, d, _ in PAGES})
    tabs = tuple(WORDS.get(n, n) for n, _, _ in PAGES)
    kit.panel(st, 12, 200, 856, 348, p)
    for i, chosen in enumerate((1, 3, 0)):
        h.rail(st, 50 + i * 68, 216, 532, p, tabs, chosen, SOON)
    L = 236.0
    # the name over the stage, one line: its rarity in its colour, the three marks small beside it
    st.text(L, 216, 20, "Marigold", p["text"])
    st.text(L + 86, 222, 12, "Epic", h.ITEM["Epic"])
    for i, (name, tint) in enumerate((("FavouriteOn", h.MAP), ("LockOn", p["text"]), ("Rename", p["soft"]))):
        st.icon(name, L + 136 + i * 26, 228, 16.0, tint=tint)
    st.text(L, 250, 20, "Rook", p["text"])
    st.text(L + 48, 256, 12, "Common", "#AEB4C0")
    for i, (name, tint) in enumerate((("FavouriteOff", p["soft"]), ("LockOff", p["soft"]), ("Rename", p["soft"]))):
        st.icon(name, L + 116 + i * 26, 262, 16.0, tint=tint)
    # the same three inside their taps: 44 points each, the mark 16
    st.text(L, 452, 20, "Marigold", p["text"])
    for i, (name, tint) in enumerate((("FavouriteOn", h.MAP), ("LockOn", p["text"]), ("Rename", p["soft"]))):
        t = kit.blank(44.0, 44.0)
        t.line(np.maximum(np.abs(t.x - 22) - 21.5, np.abs(t.y - 22) - 21.5), 0.6, c(p["edge"]), 0.7)
        h.place(st, t, L + 96 + i * 44, 440)
        st.icon(name, L + 118 + i * 44, 462, 16.0, tint=tint)
    st.text(L, 492, 9, "Each of the three in its 44 point tap, outlined here only to show its size.", h.NOTE)
    # the level's mark, at one, two and three figures
    for i, (level, w) in enumerate(((3, 56.0), (12, 64.0), (100, 73.0))):
        x, y = L + i * 88, 296
        st.lay("LevelPlate", x, y, w, PLATE[1], tint=p["button"])
        st.lay("LevelPlateEdge", x, y, w, PLATE[1], tint=(h.PALE[accent], accent))
        st.icon("LevelChevrons", x + 11, y + 11, 14.0, tint=h.NIGHT[accent][1])
        st.text(x + 27, y + 6, 11, "Lv", p["soft"])
        st.text(x + 41, y + 4, 15, str(level), p["text"])
    st.text(L, 326, 9, "The level's mark: its plate, its light, the chevrons, \"Lv\", the number.", h.NOTE)
    # Combat Power at the figure's feet
    st.icon("CombatPower", L + 14, 372, 30.0)
    st.text(L + 34, 360, 22, "32,151", p["text"])
    st.text(L + 36, 386, 11, "Combat Power", p["soft"])
    st.icon("CombatPower", L + 170, 372, 20.0)
    st.text(L + 184, 364, 15, "27,433", p["text"])
    # the same marks on a pale ground, to see the stroke and the white hold
    x0 = 520
    st.px[round(212 * K4):round(352 * K4), round(x0 * K4):round(856 * K4), :3] = c(h.PALE_GROUND)
    st.text(x0 + 10, 218, 9, "Tinted in ink on a pale ground, and Combat Power on it:", h.INK)
    for i, name in enumerate(names):
        st.icon(name, x0 + 26 + (i % 7) * 47, 262 + (i // 7) * 52, 26.0, tint=None if name == "CombatPower" else h.INK)
    return h.bytes8(h.halve(st.px)), st.items


def main():
    out = bl.out_dir()
    ui.K = K4
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    theirs = set(kit.IMAGES)
    marks()
    names = [n for n in kit.IMAGES if n not in theirs]
    (out / "images").mkdir(parents=True, exist_ok=True)
    for name in names:
        px = kit.IMAGES[name]["px"].copy()
        kit.bleed(px)
        rs.save(px, out / "images" / f"{name}.png")
    data = dict(pixelsPerPoint=K4,
                note="The Voidkin screen's marks (TR17). A white image takes its tint from its state; CombatPower is in colour. "
                     "A rail mark is 14 points across on its button; favourite, lock and rename are 16 beside the name, each "
                     "inside a 44 point tap. The level's plate stretches between its `cut` ends: body, then rim, then the "
                     "chevrons, \"Lv\" and the number.",
                images={n: dict(file=f"images/{n}.png", pixels=[im["px"].shape[1], im["px"].shape[0]], points=[im["w"], im["h"]],
                                **({"tint": im["tint"]} if im["tint"] else {}), **({"cut": list(im["cut"])} if im["cut"] else {}),
                                use=im["use"]) for n, im in ((n, kit.IMAGES[n]) for n in names)})
    (out / "voidkin_marks.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    picture = shot()
    kit.IMAGES.clear()
    ui.K = 2
    m = 20.0
    sheet = ui.Sheet(880 + 2 * m, 44 + 560 + 16, h.GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(m, 14, 17, "Grow your Anime: the Voidkin screen's marks (TR17)", h.HEAD)
    h.add(sheet, *picture, m, 44)
    kit.finish(sheet, out / "voidkin_marks.png")
    print(f"wrote {len(names)} images and the sheet")


if __name__ == "__main__":
    main()
