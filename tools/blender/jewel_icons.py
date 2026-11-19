"""AR43 (Jewels): the 25 jewels' pictures, five colours by five levels, cut for Faber.

The director's jewels (docs/design.md, "Jewels"; D, 2026-11-19, 03:10, and 2026-11-17, 12:10): every gear piece holds
five, one of each colour, each giving flat points of its colour's Basic Attribute (red Strength, green Agility, blue
Intelligence, yellow Endurance, purple Spirit). "Its shape grows with its level: a small round grain, a tiny long
crystal, a bigger long crystal, a triangle, a square."

The feel line: in the bag and the sockets, a jewel reads first as its colour (which attribute), then by its cut (which
level), and always as a cut gem, never a shard: the shards are raw pointed crystals, the jewels are stones cut face up,
each with its table, its crown's facets and its girdle.

AR31's jewels, kept (research's verdict, 2026-11-17: "the jewels' cut", near exceptional): built in code as flat
facets, rendered in Workbench, each facet toned by its angle to a light from the upper left with a play of light round
the crown, then the colour's tones, dark to near white. No setting: the five levels are the stones' own cuts, larger
as they climb.
  1. the grain: a small round brilliant;
  2. the tiny long crystal: a small long hexagon, step cut, lying on the diagonal;
  3. the bigger long crystal: a long octagon with pointed ends, three steps, seen true and lying at 40 degrees, so it
     reaches across the cell from its lower left (polish-later, research, 2026-11-19: at 38 points it differed from 2
     only in size, both flat slivers on the view's tilt);
  4. the triangle: equilateral, its sides straight and its corners sharp, point up, seen square on, three steps (the
     director, 14:07: "the triangle need to be straight and perfect draw");
  5. the square: a square with its corners clipped, three steps.
The director, 14:07: "lvl 1 need to be even smaller but they need to look more shiny and mature". So the grain is
smaller; the tones are deep and saturated with few facets lit; the table carries streaks of reflection, every facet's
edge a line of light, and each stone one restrained glint (`shiny`, `sparkle`).

    blender -b --factory-startup --python tools/blender/jewel_icons.py -- <abs out>

Writes build/handoff/UI/jewels: images/Jewel<Colour><Level>.png (256 px, transparent), jewels.json and jewels_cut.png,
the check sheet (each close, in the bag's cell at 38 points, at 64 px over dark, and a row of the bag).
"""

import json
import math
import sys
from pathlib import Path

import bmesh
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import chest_icons as ch  # noqa: E402
import gear_icons as gi  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_icons as ic  # noqa: E402
from ui_sheet import c  # noqa: E402

HANDOFF = Path(__file__).resolve().parents[2] / "build" / "handoff" / "UI" / "jewels"
GEAR = Path(__file__).resolve().parents[2] / "build" / "handoff" / "UI" / "gear" / "images"

# A colour: its attribute, its stone's tones from its facets' shade to their light (a cut gem's colour), and `words`,
# the colour of a line naming it. The director, 14:07: "more shiny and mature": deep, saturated body tones, most facets
# in the rich colour and only a few lit toward white, never pastel. The red is a clear ruby whose lights run scarlet
# to near white, never a dark or wet red (rule 4).
COLOURS = {
    "Red": dict(attribute="Strength", tones=((0.0, "#22040B"), (0.3, "#7A0C20"), (0.55, "#C8142F"), (0.78, "#FF3F56"),
                                             (0.92, "#FFA6B0"), (1.0, "#FFF4F5")), light="#FFB3BC", words="#FF6B7A"),
    "Green": dict(attribute="Agility", tones=((0.0, "#02180D"), (0.3, "#055A30"), (0.55, "#0C9C50"), (0.78, "#36E388"),
                                              (0.92, "#B4FFD4"), (1.0, "#F3FFF8")), light="#B8F5D2", words="#5FE39A"),
    "Blue": dict(attribute="Intelligence", tones=((0.0, "#030C24"), (0.3, "#0C2E7C"), (0.55, "#1A56D8"), (0.78, "#4D9BFF"),
                                                  (0.92, "#BADAFF"), (1.0, "#F4F9FF")), light="#BCD8FF", words="#6FA8FF"),
    "Yellow": dict(attribute="Endurance", tones=((0.0, "#241503"), (0.3, "#7C4B05"), (0.55, "#D2900C"), (0.78, "#FFC93A"),
                                                 (0.92, "#FFEBA8"), (1.0, "#FFFDF3")), light="#FFE08A", words="#FFCF4D"),
    "Purple": dict(attribute="Spirit", tones=((0.0, "#14052A"), (0.3, "#481680"), (0.55, "#8034D8"), (0.78, "#B47AFF"),
                                              (0.92, "#E3CDFF"), (1.0, "#FBF8FF")), light="#DCC2FF", words="#B98AFF"),
}
LEVELS = ("a small round grain", "a tiny long crystal", "a bigger long crystal", "a triangle", "a square")
# How much of its square each level fills: the size climbs with the cut. Level 1 "even smaller" (the director, 14:07).
FILL = (0.34, 0.58, 0.74, 0.8, 0.88)
ic.VIEWS["jewel_true"] = (ic.VIEWS["jewel"][0], 0.0)      # the triangle seen square on, no spin


def shiny(px, n, where, tones, tilt):
    """AR31's facets made shinier: each facet's value from its angle to the light, its contrast pushed so most facets
    sit in the body's colour and few catch the light; the table carries two streaks of reflection across it; a crisp
    line of light runs along every facet's edge. Then the colour's tones. Replaces upgrade_icons.faceted here."""
    t = math.radians(tilt)
    table = np.array([0.0, math.cos(t), math.sin(t)])
    across, up = np.array([1.0, 0.0, 0.0]), np.cross(table, [1.0, 0.0, 0.0])
    az = np.arctan2(n @ up, n @ across)
    v = 0.06 + 0.86 * np.clip((n @ ic.FACET_LIGHT - 0.22) / 0.68, 0, 1) ** 1.5 + 0.13 * np.cos(6 * az + 0.9)
    gem = where > 0.5
    ys, xs = np.mgrid[0:px.shape[0], 0:px.shape[1]].astype(np.float32)
    if gem.any():
        y0, y1 = ys[gem].min(), ys[gem].max()
        x0, x1 = xs[gem].min(), xs[gem].max()
        size = max(x1 - x0, y1 - y0, 1.0)
        u = ((xs - (x0 + x1) / 2) + (ys - (y0 + y1) / 2)) / size      # along the diagonal, upper left to lower right
        streak = 0.3 + 0.62 * np.exp(-((u + 0.14) / 0.1) ** 2) + 0.3 * np.exp(-((u - 0.16) / 0.045) ** 2)
    else:
        streak = np.full(where.shape, 0.6, np.float32)
    v = np.where(n @ table > 0.995, streak, v)
    v = np.clip(v, 0, 1)
    at, stops = [s[0] for s in tones], np.array([c(s[1])[:3] for s in tones])
    tone = np.stack([np.interp(v, at, stops[:, i]) for i in range(3)], axis=-1).astype(np.float32)
    jump = np.zeros(where.shape, np.float32)                     # where the normal turns: a facet's edge
    jump[:, 1:] += np.linalg.norm(n[:, 1:] - n[:, :-1], axis=-1)
    jump[1:, :] += np.linalg.norm(n[1:, :] - n[:-1, :], axis=-1)
    inside = np.minimum.reduce([np.roll(where, s, axis=k) for s in (-3, 3) for k in (0, 1)] + [where])
    edge = np.clip((jump - 0.08) / 0.2, 0, 1) * inside
    edge = np.maximum.reduce([np.roll(edge, s, axis=k) for s in (-1, 0, 1) for k in (0, 1)])
    pale = np.array(c(tones[-2][1])[:3], np.float32)
    tone = tone + (pale - tone) * (0.55 * edge)[..., None]
    out = px.copy()
    out[..., :3] += (tone - out[..., :3]) * where[..., None]
    return out


def sparkle(px, light):
    """One restrained glint where the stone is brightest on its upper left: a soft core, two thin rays and two shorter
    ones between, tapering, white touched with the stone's light."""
    a = px[..., 3]
    ys, xs = np.mgrid[0:px.shape[0], 0:px.shape[1]].astype(np.float32)
    solid = a > 0.9
    y0, y1, x0, x1 = ys[solid].min(), ys[solid].max(), xs[solid].min(), xs[solid].max()
    size = max(x1 - x0, y1 - y0)
    bright = px[..., :3].mean(axis=-1) * solid * ((xs - x0) + (ys - y0) < 1.1 * size)
    cy, cx = np.unravel_index(np.argmax(bright), bright.shape)
    dx, dy = xs - cx, ys - cy
    reach = 0.24 * size
    glint = np.zeros(a.shape, np.float32)
    for (ux, uy), length, alpha in (((1, 0), reach, 1.0), ((0, 1), reach, 1.0),
                                    ((0.7071, 0.7071), 0.42 * reach, 0.6), ((0.7071, -0.7071), 0.42 * reach, 0.6)):
        along, off = dx * ux + dy * uy, -dx * uy + dy * ux
        fall = np.clip(1 - np.abs(along) / length, 0, 1) ** 2.2
        glint = np.maximum(glint, alpha * fall * np.exp(-(off / 1.6) ** 2))
    glint = np.maximum(glint, np.exp(-(np.hypot(dx, dy) / (0.035 * size)) ** 2))
    colour = np.array(c("#FFFFFF")[:3], np.float32) * 0.8 + np.array(c(light)[:3], np.float32) * 0.2
    out = px.copy()
    na = glint + a * (1 - glint)
    out[..., :3] = (px[..., :3] * (a * (1 - glint))[..., None] + colour * glint[..., None]) / np.maximum(na, 1e-6)[..., None]
    out[..., 3] = na
    return out


def turned(pts, degrees):
    a = math.radians(degrees)
    return [(x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)) for x, y in pts]


def stone(name, girdle, crown, table_offset=False, depth=0.7, rise=0.0):
    """A stone cut face up from its girdle's outline: steps of the crown at (scale, height), the last its flat table;
    with `table_offset`, the table's corners sit between the girdle's, so the crown is a brilliant's triangles. Its
    pavilion runs from the girdle to a point under it. `rise` moves each step back by its height times it, so the
    view's tilt lays the steps concentric on the screen."""
    bm = bmesh.new()
    rings = [[bm.verts.new((x, y, 0.0)) for x, y in girdle]]
    if rise:
        girdle_at = lambda s, h: [(x * s, y * s - h * rise) for x, y in girdle]  # noqa: E731
    else:
        girdle_at = lambda s, h: [(x * s, y * s) for x, y in girdle]  # noqa: E731
    n = len(girdle)
    for k, (s, h) in enumerate(crown):
        last = k == len(crown) - 1
        if last and table_offset:
            mids = [((girdle[i][0] + girdle[(i + 1) % n][0]) / 2, (girdle[i][1] + girdle[(i + 1) % n][1]) / 2)
                    for i in range(n)]
            table = [bm.verts.new((x * s, y * s, h)) for x, y in mids]
            below = rings[-1]
            for i in range(n):
                bm.faces.new((below[i], below[(i + 1) % n], table[i]))
                bm.faces.new((table[i - 1], below[i], table[i]))
            rings.append(table)
            continue
        ring = [bm.verts.new((x, y, h)) for x, y in girdle_at(s, h)]
        below = rings[-1]
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((below[i], below[j], ring[j], ring[i]))
        rings.append(ring)
    bm.faces.new(rings[-1])
    foot = bm.verts.new((0.0, 0.0, -depth))
    for i in range(n):
        bm.faces.new((rings[0][(i + 1) % n], rings[0][i], foot))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, ic.mat("gem"))     # lying face up, as AR31's brilliant: the view tilts it


def cut(level):
    """A level's stone: 1 to 5."""
    if level == 1:
        girdle = [(0.5 * math.cos(2 * math.pi * k / 10), 0.5 * math.sin(2 * math.pi * k / 10)) for k in range(10)]
        return [stone("Grain", girdle, [(0.56, 0.2)], table_offset=True, depth=0.36)]
    if level == 2:
        girdle = turned([(-0.8, 0), (-0.48, -0.3), (0.48, -0.3), (0.8, 0), (0.48, 0.3), (-0.48, 0.3)], 32)
        return [stone("Long", [(x * 0.62, y * 0.62) for x, y in girdle], [(0.76, 0.1), (0.54, 0.17)], depth=0.3)]
    tilt = math.radians(ic.VIEWS["jewel"][0])
    if level == 3:
        # Level 3's own read at 38 points: seen true as the triangle is (its depth stretched by 1/sin(tilt), no spin),
        # turned 40 degrees, so it reaches across the cell where level 2 lies flat. At FILL's 0.74 it covers about a
        # quarter of its square, between level 2's tenth and the triangle's 0.28.
        girdle = turned([(-1.0, 0), (-0.78, -0.22), (-0.48, -0.34), (0.48, -0.34), (0.78, -0.22), (1.0, 0),
                         (0.78, 0.22), (0.48, 0.34), (-0.48, 0.34), (-0.78, 0.22)], 40)
        girdle = [(x, y / math.sin(tilt)) for x, y in girdle]
        return [stone("Long", girdle, [(0.86, 0.1), (0.7, 0.18), (0.52, 0.24)], depth=0.42, rise=1 / math.tan(tilt))]
    if level == 4:
        # The director, 14:07: "the triangle need to be straight and perfect draw". An equilateral triangle, its sides
        # straight and its corners sharp, its point up, seen square on (no spin, TRUE_VIEW); its depth stretched by
        # 1/sin(tilt) so the view's tilt gives back a true equilateral on the screen. Three clean steps to its table.
        girdle = [(0.95 * math.cos(math.radians(90 + 120 * k)), 0.95 * math.sin(math.radians(90 + 120 * k)) / math.sin(tilt))
                  for k in range(3)]
        return [stone("Triangle", girdle, [(0.8, 0.1), (0.62, 0.18), (0.42, 0.24)], depth=0.5, rise=1 / math.tan(tilt))]
    q, k = 0.9, 0.24
    girdle = [(-q + k, -q), (q - k, -q), (q, -q + k), (q, q - k), (q - k, q), (-q + k, q), (-q, q - k), (-q, -q + k)]
    return [stone("Square", girdle, [(0.84, 0.1), (0.68, 0.19), (0.5, 0.26)], depth=0.6)]


def renders(out):
    shots = {}
    ic.faceted = shiny
    for name, col in COLOURS.items():
        look = dict(facets=col["tones"], light=(col["light"], (4, 0.7), (10, 0.3)))
        for level in range(1, 6):
            view = "jewel_true" if level in (3, 4) else "jewel"
            shot = ic.coloured(out, lambda: cut(level), view, FILL[level - 1], look)
            shots[f"Jewel{name}{level}"] = sparkle(shot, col["light"])
    return shots


def sheet(shots):
    ui.K = 2
    sh = ui.Sheet(1180, 760, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "AR43, Jewels: five colours by five levels, cut for Faber, for the content check", g.INK)
    t.text(20, 36, 9.5, "Each close, in the bag's cell at 38 points, and alone at 64 px over dark. Its colour is its "
           "attribute; its cut is its level: a grain, a tiny long crystal, a bigger one, a triangle, a square.", g.SOFT_INK)
    y = 62
    for row, (name, col) in enumerate(COLOURS.items()):
        yy = y + row * 104
        t.text(20, yy + 30, 11, name, g.INK)
        t.text(20, yy + 46, 9, col["attribute"], col["words"])
        for level in range(1, 6):
            x = 130 + (level - 1) * 204
            stem = f"Jewel{name}{level}"
            ic.plain(sh, x, yy, 92.0, shots[stem])
            ic.plain(sh, x + 100, yy, 38.0, shots[stem])
            ic.big_alone(sh, x + 100, yy + 46, shots[stem])
    y = 588
    row = [("GearMeigetsu", "Legendary"), ("JewelRed1", None), ("JewelGreen2", None), ("JewelBlue3", None),
           ("JewelYellow4", None), ("JewelPurple5", None), ("JewelRed5", None), ("JewelGreen4", None),
           ("JewelBlue1", None), ("JewelYellow2", None), ("JewelPurple3", None)]

    def picture(name):
        return rs.load(GEAR / f"{name}.png") if name.startswith("Gear") else shots[name]

    t.text(20, y, 11, "In the bag at 38 points, beside an item", g.INK)
    for i, (name, rarity) in enumerate(row):
        ch.cell(sh, 30 + i * 44, y + 20, 38.0, picture(name), rarity)
    t.text(20, y + 70, 11, "The same row at 76 points", g.INK)
    for i, (name, rarity) in enumerate(row):
        ch.cell(sh, 30 + i * 88, y + 88, 76.0, picture(name), rarity)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, HANDOFF / "jewels_cut.png")


def deliver(shots):
    (HANDOFF / "images").mkdir(parents=True, exist_ok=True)
    for stem, shot in shots.items():
        gi.keep(rs.shrink(shot, gi.ICON / shot.shape[0]), HANDOFF / "images" / f"{stem}.png")
    data = dict(
        what="AR43, Jewels: the 25 pictures, five colours (each its Basic Attribute) by five levels (each its cut), "
             "drawn in code by tools/blender/jewel_icons.py on AR31's faceted renderer; no image input",
        use="laid as a gear picture is, its square 0.94 of the cell, centred, never tinted; a jewel's cell keeps the "
            "plain edge, no rarity's bar, rim or light. The level's number and the stack's count are the bag's",
        pixels=[gi.ICON, gi.ICON],
        levels={str(k + 1): cut_said for k, cut_said in enumerate(LEVELS)},
        jewels={name: dict(attribute=col["attribute"], words=col["words"],
                           images=[f"images/Jewel{name}{level}.png" for level in range(1, 6)])
                for name, col in COLOURS.items()},
        replaces="AR31's jewels by type (Critical Damage, Critical Immunity, Lifesteal), retired by the director's five "
                 "colours (2026-11-19, 03:10)",
    )
    (HANDOFF / "jewels.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main():
    out = bl.out_dir()
    shots = renders(out)
    deliver(shots)
    sheet(shots)
    print(f"jewels: {len(shots)} pictures into {HANDOFF}")


if __name__ == "__main__":
    main()
