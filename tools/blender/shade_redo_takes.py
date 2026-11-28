"""The Shades redone in the make (docs/requests/AR75.md: the director's "everything in that screen ... need an
upgrade/complete overhaul", 2026-11-28, 00:23; research's order of 00:49, two or three targets beside the new Pip and
Rook, and its must-fix of 01:1x: off red and black, so Pip and Rook stand clear of them).

Today's Shade is a near-black robe with its type's colour at the hem and seams and a cream mask: beside Pip's picked
take (brick, black, pale gold) and Rook (a slate navy coat, a red tee, near-black trousers) it is the same red and black.
Each take here is a festival-goer the Void has filled (docs/roster.md, "Enemies: Shades"), in the Voidkin's own make:
R6's blocks with the clothes painted on, the mask drawn on the round head, the Void in it lit cyan. The type's colour
(Config.Shades.Tint) leaves the body's mass and keeps one place of its own; the body's mass is off red, black, navy and
brick. The mask is the Brawler's, round and grinning; the Guard's, the Dasher's and the Support's follow the pick.

    A, ash: a pale ash festival coat over a slate under-robe, its collar band and hem in slate, a crest on its back, a
       slate sash tied with a cord in the type's colour; a head of slate smoke rising from the mask; the hands smoke,
       the Void at their ends.
    B, sage: a long sage coat to the knee, its front edges, hem and cuffs lit in the type's colour (today's outline, on
       a mid body instead of a black one); a sage hood framing the mask, the type's paint on the mask.
    C, lantern: a festival lantern for a head, the mask painted on its paper, lit from within, a lacquer ring at its
       top and foot and the Void's smoke leaving its top; a paper coat ribbed as the lantern is, faintly lit; the
       type's colour as the mask's paint and a paper slip at the sash.

The folds are this script's own `cel`: hard-edged shade shapes in each garment's own shade, a crease line in each,
drawn where that cloth pulls, never the kit's soft crescent (am.creases), which research read as a print tiled over
everything (AR63, 2026-11-28).

    blender.exe -b --factory-startup --python tools/blender/shade_redo_takes.py -- <out_dir> takes [Pip A B C]
    blender.exe -b --factory-startup --python tools/blender/shade_redo_takes.py -- <out_dir> rook|shade|sheet

`takes` draws the three and Pip's picked take (pip_redo_takes.take_c); `rook` today's Rook and `shade` today's
Brawler, as the game has them. `sheet` lays <out_dir>/shade_redo_takes.png and its parts: each take from the front and
the game's camera, its head from six sides, each Shade fighting Pip and Rook on the deck, each as a pack in Lantern
Row's street (TR24's still: its HUD and its Rook are the old ones), the line-up, and 64 pixels. Beside a shipped frame
(internal, build/reference/takes/shade_redo_beside.png): the street beside Jujutsu Infinite's frames at the same height.
"""
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import pip_make as pm  # noqa: E402
import pip_make_takes as pt  # noqa: E402
import pip_redo_takes as pr  # noqa: E402
import rook_make_takes as rt  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402
from anime_make import cel, mix, rgb, tone  # noqa: E402
from rook_make_takes import band, blocks_of, dark, grain, line, lit, neck, shadow  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
STILL = REPO / "build" / "scratch" / "faber" / "stills" / "tr24-07-row-fight.jpg"   # Lantern Row by day, the game's camera
SHIPPED = (REPO / "build" / "reference" / "jujutsu-infinite" / "J1_ocean_curse.png",
           REPO / "build" / "reference" / "jujutsu-infinite" / "J2_finger_bearer.png")
VOID = "#86F0FF"          # the Void in a Shade: the mask's cuts lit from within (AR57's cyan)
VOID_CORE = "#E6FFFF"
GLOW = {"head": 1.4, "rs": 1.6, "ls": 1.6, "torso": 1.6, "rh": 1.6, "lh": 1.6}   # each piece's glow strength

SAID = {
    "Shade": ("Today's Brawler", ("the game today: a near-black robe,", "its type's colour at the hem")),
    "A": ("A, ash", ("a pale ash festival coat, slate bands", "a head of slate smoke over the mask",
                     "a slate sash, a cord in the type's colour", "smoke hands, the Void at their ends")),
    "B": ("B, sage", ("a long sage coat to the knee", "its edges lit in the type's colour",
                      "a sage hood framing the mask", "the type's paint on the mask")),
    "C": ("C, lantern", ("a festival lantern for a head, lit", "the mask painted on its paper",
                         "a ribbed paper coat, faintly lit", "the type's colour on the mask and a slip")),
    "Pip": ("Pip (C, the finish)", ()),
    "Rook": ("Rook (today)", ()),
}
WHO = ("A", "B", "C")
FOES = ("Shade",) + WHO
LEADS = ("Pip", "Rook")
ROW = ("Rook", "Pip", "Shade", "A", "B", "C")
ROW_X = (-10.0, -6.0, -2.0, 2.0, 6.0, 10.0)
STREET = (("near", -7.0, -3.0, (0.0, 8.0)), ("far", -7.0, -12.0, (0.0, 8.0)), ("side", 12.5, -5.0, (3.5, -0.5)))
# the sheet's own words and files: round 1's here; a later round's script sets its own (shade_void_takes.py)
STEM, BESIDE = "shade_redo_takes", "shade_redo_beside.png"
TITLE = "AR75: THE SHADES IN THE MAKE, THREE TAKES"
ABOUT = ("The Brawler, a festival-goer the Void has filled, in the Voidkin's make: R6's blocks with the clothes painted "
         "on, the mask drawn on the round head, the Void in its cuts lit cyan. Off red and black so Pip and Rook stand clear "
         "(research, 2026-11-28): the body's mass is off red, black, navy and brick, and the type's colour (Red, the Brawler's) "
         "keeps one place of its own. Folds are hard-edged shade shapes in each cloth's own shade. Research picks one; the "
         "Guard's, the Dasher's and the Support's masks follow the pick.")
ROW_SAID = "Rook, Pip, today's Brawler, A, B, C"


def tint():
    """The Brawler's type, Red, from its home (Config.Shades.Tint), never copied."""
    import hard_cut as hc
    return "#" + hc.type_tints()["Red"]


# --- the paint every take shares --------------------------------------------------------------------------------------

def glow_where(px, colour, k=1.0, near=0.3):
    """What glows on a picture: every texel drawn in `colour` (one nothing else on it uses), read before the light
    and the shade are painted over it."""
    d = np.abs(px - rgb(colour)).sum(axis=2)
    return np.clip(1 - d / near, 0, 1).astype(np.float32) * k


def lights(block, colour, k=1.0, near=0.3):
    m = glow_where(block.px, colour, k, near)
    block.glow = m if block.glow is None else np.maximum(block.glow, m)


def void_hands(a, smoke, top=0.62):
    """The hand as smoke from `top` down, darker to its end, the Void lit at the very end (its glow by the height,
    so no pale cloth near the Void's colour is lit with it)."""
    for p in a.sides:
        p.lay(p.rise(top, 0.0) ** 1.2, smoke, 0.9)
        p.lay(p.rise(0.16, 0.0), VOID, 0.85)
    a.faces["bottom"].px[:] = rgb(VOID)
    m = np.zeros(a.px.shape[:2], np.float32)
    m[:a.wrap.rows] = a.wrap.rise(0.16, 0.0) * 0.8
    x, y, fw, fh = a.at["bottom"]
    m[int(round(y * am.PPU)):int(round((y + fh) * am.PPU)), int(round(x * am.PPU)):int(round((x + fw) * am.PPU))] = 0.8
    a.glow = m if a.glow is None else np.maximum(a.glow, m)


def brawler_mask(p, plate, paint, rim):
    """The Brawler's mask, round and grinning, drawn over the head's face: a domed plate shaded to its rim and
    lipped in `rim`, two eyes cut slanting down to the middle, a wide grin cut under fangs, the cuts lit by the Void
    (VOID, a white core), the festival's `paint` on the brow only (or none): never on the cheeks by the grin, where a falling mark reads as blood at the mouth (the content check, 2026-11-28). Its glow is read from VOID."""
    cx, cy, rx, ry = 0.0, 0.6, 0.6, 0.53
    disc = p.ellipse(cx, cy, rx, ry)
    p.lay(np.clip(p.ellipse(cx, cy - 0.01, rx + 0.035, ry + 0.035) - disc, 0, 1), rim)
    p.lay(disc, plate)
    p.lay(np.clip(disc - p.ellipse(cx + 0.03, cy + 0.05, rx * 0.8, ry * 0.8), 0, 1), tone(plate, 0.8), 0.8)
    p.lay(np.minimum(p.ellipse(cx + 0.12, cy + 0.2, rx * 0.4, ry * 0.26, turn=-15), disc), mix(plate, "#FFFFFF", 0.6), 0.5)
    if paint:
        for s in (-1, 1):
            p.lay(np.minimum(p.stroke([(s * 0.08, 0.98), (s * 0.24, 1.02), (s * 0.4, 0.96)], (0.02, 0.07, 0.05, 0.01)), disc), paint)
    cuts = np.zeros(p.X.shape, np.float32)
    for s in (-1, 1):
        eye = am.smooth2([(s * 0.09, 0.66), (s * 0.24, 0.74), (s * 0.4, 0.84), (s * 0.43, 0.74), (s * 0.3, 0.62), (s * 0.14, 0.58)], 20)
        cuts = np.maximum(cuts, p.poly(eye))
    upper = am.smooth2([(-0.42, 0.44), (-0.22, 0.33), (0.0, 0.3), (0.22, 0.33), (0.42, 0.44)], 24)
    lower = am.smooth2([(0.42, 0.44), (0.24, 0.2), (0.0, 0.14), (-0.24, 0.2), (-0.42, 0.44)], 24)
    grin = p.poly(np.vstack([upper, lower[1:-1]]))
    for tx in (-0.27, -0.13, 0.0, 0.13, 0.27):
        top = float(np.interp(tx, upper[:, 0], upper[:, 1]))
        grin = np.clip(grin - p.poly([(tx - 0.045, top + 0.02), (tx + 0.045, top + 0.02), (tx, top - 0.1)]), 0, 1)
    cuts = np.maximum(cuts, grin)
    p.lay(np.clip(p.soft(cuts, 0.018) * 2.4, 0, 1), tone(plate, 0.28))     # the cut's depth: a dark lip round it
    p.lay(cuts, VOID)
    core = np.clip(p.soft(cuts, 0.03) * 1.6 - 1.15, 0, 1)   # a thin white core: the cut itself stays cyan
    p.lay(core, VOID_CORE)
    return cuts


def figure(joints, folder, b, head, hair, glow_head, built=(), cast="#12161C", cast_alpha=0.6):
    """The blocks, head and hair (rook_make_takes.figure), the built pieces on the neck, the hair cast on the head,
    and every glowing piece lit by its own map."""
    made = rt.figure(joints, folder, b, head, hair)
    for piece in built:
        made[piece.name] = piece.build(folder)
        wt.on(joints, "neck", made[piece.name])
    pm.hair_shadow(made, cast, alpha=cast_alpha)
    am.GLOWS[made["head"].name] = glow_head
    for key, obj in made.items():
        mask = am.GLOWS.get(obj.name)
        if mask is None or GLOW.get(key, 1.2) <= 0 or float(mask.max()) <= 0:
            continue
        path = folder / f"{key}_glow.png"
        rs.save(np.dstack([mask, mask, mask, np.ones_like(mask)]), path)
        pm.emit(obj.active_material, path, GLOW.get(key, 1.2))
    return made


# --- A, ash ------------------------------------------------------------------------------------------------------------

def take_a(joints, folder):
    coat, slate, under, trouser, smoke, void, plate, pale = ("#D9D4C9", "#4A5466", "#3A4251", "#5A6170", "#2A303A",
                                                             "#262C36", "#F2EDE3", "#9AA8BE")
    red = tint()
    b = blocks_of({"torso": coat, "rs": coat, "ls": coat, "rh": trouser, "lh": trouser})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # the slate under-robe in the V, the collar band down the left panel over the right, on to the hem
    f.lay(f.poly([(-0.36, 2.0), (0.36, 2.0), (0.02, 1.22)]), under)
    for pts, wide in (([(-0.36, 2.0), (-0.16, 1.6), (0.02, 1.26)], 0.15), ([(0.36, 2.0), (0.14, 1.6), (-0.04, 1.22), (-0.12, 0.6), (-0.14, 0.0)], 0.16)):
        line(f, pts, wide, slate, 1.0)
        line(f, pts, 0.018, pale, 0.8)
    back.lay(back.rect(-0.36, 1.84, 0.36, 2.0), slate)
    # folds: from the shoulders to the sash, and from the sash to the hem, each the coat's own
    for s in (-1, 1):
        cel(f, [(s * 0.92, 1.96), (s * 0.78, 1.5), (s * 0.66, 0.96)], 0.22, coat)
        cel(f, [(s * 0.54, 0.62), (s * 0.62, 0.3), (s * 0.68, 0.04)], 0.16, coat)
        cel(back, [(s * 0.94, 1.9), (s * 0.8, 1.36), (s * 0.7, 0.94)], 0.22, coat)
        cel(back, [(s * 0.46, 0.62), (s * 0.52, 0.3), (s * 0.56, 0.04)], 0.14, coat)
    # the crest on the back: a ring round a shard
    back.lay(np.clip(back.ellipse(0, 1.3, 0.42, 0.42) - back.ellipse(0, 1.3, 0.34, 0.34), 0, 1), slate)
    back.lay(back.poly([(0.0, 1.56), (0.14, 1.3), (0.0, 1.04), (-0.14, 1.3)]), slate)
    # the hem's band with two pale lines, the sash, its cord and knot in the type's colour
    band(w, 0.0, 0.28, slate, tone(slate, 0.6))
    for y in (0.08, 0.2):
        w.lay(w.rect(-9, y, 9, y + 0.018), pale, 0.85)
    band(w, 0.62, 0.86, slate, tone(slate, 0.55))
    w.lay(w.rect(-9, 0.72, 9, 0.755), red)
    f.lay(f.ellipse(0.34, 0.74, 0.075, 0.06), red)
    for end in ((0.4, 0.5), (0.28, 0.52)):
        line(f, [(0.34, 0.72), end], 0.04, red, 1.0)
    shadow(t, 0.26)
    lit(t)
    grain(t, seed=201)
    neck(t, void)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        aw = a.wrap
        # the wide sleeve to the elbow, its hem banded; the forearm in the under-robe's slate; the hand smoke
        aw.lay(aw.rect(-9, 0.0, 9, 1.0), under)
        band(aw, 1.0, 1.12, slate, tone(slate, 0.6))
        for p in a.sides:
            dark(p, p.soft(p.rect(-9, 0.84, 9, 1.0), 0.04), 0.45)
        am.cel_sides(a, {k: v for k, v in am.SLEEVE_CEL.items() if k != "out"}, coat)   # the wide sleeve: no cuff to gather
        am.cel_sides(a, {"out": am.SLEEVE_CEL["out"][:1]}, coat)
        am.cel_sides(a, {"front": [([(-0.3, 0.86), (-0.06, 0.66), (0.16, 0.6)], 0.12)]}, under, 0.72, 0.45)
        void_hands(a, smoke)
        shadow(a, 0.26, low=0.0)
        lit(a)
        a.faces["top"].px[:] = rgb(coat)
        grain(a, seed=202 + i)
    pr.tops(b, coat)

    for i, key in enumerate(("rh", "lh")):
        g = b[key]
        am.cel_sides(g, am.LEG_CEL, trouser)
        rt.wraps(g, 0.3, 0.92, coat, gap=0.1)
        band(g.wrap, 0.0, 0.3, smoke, tone(smoke, 0.6))
        g.faces["bottom"].px[:] = rgb(smoke)
        shadow(g, 0.26, low=0.0)
        lit(g, 0.1)
        grain(g, seed=204 + i)

    head = am.Head(void)
    glow = brawler_mask(head.paint, plate, slate, tone(void, 0.6))
    hair = am.Hair("#1F252E", "#5E6E84", seed=207, band=(0.5, 0.12, 0.12), scalp=am.HEAD_EGG)
    # the smoke: one dark mass close on the head behind the mask, streaming back off it as a flame is blown, broad
    # tongues lying back and lifting at their ends: no lock stands up, so it never reads as a head of hair
    hair.mass(am.hairline(front=5.02, temple=4.5, nape=3.98), (180, 30), opening=0.08, seed=207,
              tips=((180, 24, 16), (140, 16, 10), (220, 16, 10)), lift=0.04, off=(0.0, 0.08), ease=2.0, tuck=0.09)
    for a, ph, length, width, heading in ((-40, 22, 1.2, 0.56, 10), (0, 18, 1.36, 0.62, 0), (40, 22, 1.2, 0.56, -10)):
        hair.clump(a, ph, length, width, heading=heading, off=0.08, flick=24, hold=0.7, comb=(0, -1.0, 0.18), thick=width * 0.26)
    for a, length in ((140, 1.1), (180, 1.3), (220, 1.1)):
        hair.clump(a, 34, length, 0.56, heading=0, off=0.08, flick=30, hold=0.62, comb=(0, -1.0, 0.1), thick=0.14)
    for s in (-1, 1):
        hair.clump(s * 96, 36, 0.96, 0.5, heading=-s * 12, off=0.07, flick=28, hold=0.62, comb=(0, -1.0, 0.12), thick=0.13)
    return figure(joints, folder, b, head, hair, glow, cast="#0E1218")


# --- B, sage -----------------------------------------------------------------------------------------------------------

def take_b(joints, folder):
    sage, lining, trouser, smoke, hood_c, void, plate = "#56634F", "#3B4537", "#454C47", "#2E3430", "#4B5746", "#262B27", "#EFE8DA"
    red = tint()
    hem = 0.9   # on the legs: where the coat ends
    b = blocks_of({"torso": sage, "rs": sage, "ls": sage, "rh": trouser, "lh": trouser})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    # closed off the middle, the lining showing in a narrow fall; both front edges lit in the type's colour
    f.lay(f.poly([(-0.08, 2.0), (0.12, 2.0), (0.16, 0.0), (-0.12, 0.0)]), lining)
    for x0, x1 in ((-0.08, -0.12), (0.12, 0.16)):
        line(f, [(x0, 2.0), (x1, 0.0)], 0.04, red, 1.0)
    for s in (-1, 1):
        cel(f, [(s * 0.92, 1.94), (s * 0.72, 1.46), (s * 0.58, 0.94)], 0.22, sage)
        cel(f, [(s * 0.4, 0.68), (s * 0.48, 0.36), (s * 0.52, 0.04)], 0.16, sage)
        cel(back, [(s * 0.94, 1.9), (s * 0.74, 1.36), (s * 0.6, 0.7)], 0.22, sage)
    line(back, [(0.0, 1.8), (0.0, 0.0)], 0.016, tone(sage, 0.5), 0.8)
    band(w, 0.7, 0.84, lining, tone(lining, 0.55))   # a belt, the coat's own dark
    f.lay(f.rect(-0.12, 0.7, 0.16, 0.84), lining)
    back.lay(back.rect(-0.5, 1.84, 0.5, 2.0), lining)
    lights(t, red)
    shadow(t, 0.28)
    lit(t)
    grain(t, seed=301)
    neck(t, void)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        aw = a.wrap
        band(aw, 0.36, 0.5, lining, None)
        aw.lay(aw.rect(-9, 0.36, 9, 0.4), red)
        am.cel_sides(a, am.SLEEVE_CEL, sage)
        lights(a, red)
        void_hands(a, smoke, 0.36)
        shadow(a, 0.28, low=0.0)
        lit(a)
        a.faces["top"].px[:] = rgb(sage)
        grain(a, seed=302 + i)
    pr.tops(b, sage)

    for i, (key, s) in enumerate((("rh", -1), ("lh", 1))):
        g = b[key]
        gw, gf = g.wrap, g.faces["front"]
        # the coat's tails to the knee, round the sides and back; the trousers' front between them
        gw.lay(gw.rect(-9, hem, 9, 2.0), sage)
        gf.lay(gf.poly([(s * 0.5, 2.0), (-s * 0.5, 2.0), (-s * 0.5, hem), (s * 0.5, hem)]), trouser)
        gf.lay(gf.poly([(s * 0.5, 2.0), (s * 0.28, 2.0), (s * 0.34, hem), (s * 0.5, hem)]), sage)
        line(gf, [(s * 0.28, 2.0), (s * 0.34, hem)], 0.04, red, 1.0)
        am.cel_sides(g, {"out": [([(0.38, 1.9), (0.22, 1.4), (0.14, 1.0)], 0.16)],
                         "back": [([(0.36, 1.88), (0.2, 1.4), (0.1, 1.0)], 0.16)]}, sage)
        gw.lay(gw.rect(-9, hem - 0.02, 9, hem + 0.02), red)                 # the hem lit, round the tails only
        lo, hi = sorted((-s * 0.5, s * 0.31))
        gf.lay(gf.rect(lo, hem - 0.03, hi, hem + 0.03), trouser)
        cel(gf, [(-s * 0.3, 0.86), (-s * 0.1, 0.6), (-s * 0.04, 0.4)], 0.12, trouser)
        band(gw, 0.0, 0.42, smoke, tone(smoke, 0.6))
        g.faces["bottom"].px[:] = rgb(smoke)
        lights(g, red)
        shadow(g, 0.26, low=0.0)
        lit(g, 0.1)
        grain(g, seed=304 + i)

    head = am.Head(void)
    glow = brawler_mask(head.paint, plate, red, tone(void, 0.6))
    hood = am.Hair("#3C4638", "#6E7C66", seed=307, band=(0.5, 0.12, 0.12), scalp=am.HEAD_EGG)
    # the hood: one cloth over the head, its edge framing the mask, drawn back to a point behind
    hood.mass(am.hairline(front=5.08, temple=4.3, nape=3.86), (180, 34), opening=0.02, seed=307, grooves=5,
              tips=((180, 26, 16),), lift=0.1, off=(0.06, 0.16), ease=1.4, tuck=0.06)
    hood.clump(180, 46, 0.62, 0.5, heading=0, off=0.12, flick=10, hold=0.7, comb=(0, -1.0, -0.6), thick=0.12)
    return figure(joints, folder, b, head, hood, glow, cast="#0C100C", cast_alpha=0.7)


# --- C, lantern --------------------------------------------------------------------------------------------------------

def ribs(p, y0, y1, gap, colour, alpha=0.75):
    y = y0 + gap
    while y < y1 - 0.02:
        p.lay(p.rect(-9, y - 0.011, 9, y + 0.011), colour, alpha)
        y += gap


def take_c(joints, folder):
    paper, rib, frame, smoke, void, plate = "#E2ECEA", "#97A3A8", "#38424E", "#3F4858", "#2B323D", "#F6F3EC"
    red = tint()
    b = blocks_of({"torso": paper, "rs": paper, "ls": paper, "rh": smoke, "lh": smoke})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    ribs(w, 0.0, 2.0, 0.26, rib)
    # the crossed collar in the lacquer's slate, the sash, a paper slip in the type's colour at it
    f.lay(f.poly([(-0.32, 2.0), (0.32, 2.0), (0.0, 1.3)]), smoke)
    for pts in ([(-0.32, 2.0), (-0.12, 1.6), (0.04, 1.3)], [(0.32, 2.0), (0.1, 1.58), (-0.08, 1.26), (-0.14, 0.0)]):
        line(f, pts, 0.12, frame, 1.0)
    back.lay(back.rect(-0.32, 1.86, 0.32, 2.0), frame)
    for s in (-1, 1):
        cel(f, [(s * 0.9, 1.92), (s * 0.72, 1.46), (s * 0.6, 0.98)], 0.2, paper, 0.82, 0.62)
        cel(back, [(s * 0.9, 1.86), (s * 0.7, 1.36), (s * 0.58, 0.9)], 0.2, paper, 0.82, 0.62)
    band(w, 0.6, 0.82, frame, tone(frame, 0.6))
    f.lay(f.poly([(0.36, 0.74), (0.5, 0.74), (0.52, 0.22), (0.38, 0.24)]), red)
    line(f, [(0.37, 0.6), (0.5, 0.6)], 0.014, tone(red, 0.5), 0.9)
    band(w, 0.0, 0.08, frame, None)
    lights(t, paper, 0.14, 0.12)
    shadow(t, 0.2)
    lit(t)
    grain(t, 0.04, seed=401)
    neck(t, void)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        aw = a.wrap
        ribs(aw, 0.4, 2.0, 0.26, rib)
        band(aw, 0.36, 0.44, frame, None)
        am.cel_sides(a, am.SLEEVE_CEL, paper, 0.82, 0.62, scale=0.9)
        lights(a, paper, 0.14, 0.12)
        aw.lay(aw.rect(-9, 0.0, 9, 0.36), smoke)
        void_hands(a, void, 0.36)
        shadow(a, 0.22, low=0.0)
        lit(a)
        a.faces["top"].px[:] = rgb(paper)
        grain(a, 0.04, seed=402 + i)
    pr.tops(b, paper)

    for i, key in enumerate(("rh", "lh")):
        g = b[key]
        am.cel_sides(g, am.LEG_CEL, smoke)
        rt.wraps(g, 0.3, 0.86, paper, gap=0.1)
        band(g.wrap, 0.0, 0.3, void, tone(void, 0.6))
        g.faces["bottom"].px[:] = rgb(void)
        shadow(g, 0.26, low=0.0)
        lit(g, 0.1)
        grain(g, seed=404 + i)

    head = am.Head(paper)
    p = head.paint
    ribs(p, 0.0, 1.25, 0.2, rib, 0.6)
    lit_paper = glow_where(head.px, paper, 0.16, 0.12)   # faint: the paper keeps its shade, the cuts burn
    glow = np.maximum(brawler_mask(p, plate, red, frame), lit_paper)
    top, foot = pm.LitBuilt("HeadTop"), pm.LitBuilt("HeadFoot")
    for piece, z in ((top, 5.04), (foot, 3.84)):
        piece.loop((0.0, 0.0, z), 0.53, 0.13, frame, thick=0.1, segments=28)
    top.tube([[(0.2 * math.sin(a), 0.2 * math.cos(a), 5.15) for a in np.linspace(0, 2 * math.pi, 12, endpoint=False)],
              [(0.2 * math.sin(a), 0.2 * math.cos(a), 5.22) for a in np.linspace(0, 2 * math.pi, 12, endpoint=False)]],
             lambda i, k: tone(frame, 1.1 if k % 3 else 0.8), caps=(None, tone(frame, 0.7)))
    smoke_hair = am.Hair("#3A4352", "#C3D2E0", seed=407, band=(0.5, 0.12, 0.2), scalp=am.HEAD_EGG)
    # the Void's smoke leaving the lantern's top
    for a, length, heading in ((-40, 0.7, 20), (20, 0.86, -6), (150, 0.6, 10)):
        smoke_hair.clump(a, 4, length, 0.3, heading=heading, off=0.24, flick=40, hold=0.4, comb=(0, -0.3, 1.0), thick=0.08)
    return figure(joints, folder, b, head, smoke_hair, glow, built=(top, foot), cast="#7D8A92", cast_alpha=0.0)


TAKES = {"Pip": pr.finish_c, "A": take_a, "B": take_b, "C": take_c}


# --- where each stands -------------------------------------------------------------------------------------------------

def spots(key):
    """Where a figure stands, as rook_make_takes.spots: (stem, x, z, faces toward). The leads fight on the deck; each
    Shade is their foe, and in the street a pack of three; all of them in the line-up."""
    import shade_elites as el
    x = ROW_X[ROW.index(key)]
    out = [("row", x, rt.ROW_Z, el.toward((x, rt.ROW_Z), 26.0))]
    if key in LEADS:
        out.append(("fight", *rt.LEAD, rt.FOE))
    else:
        out.append(("foe", *rt.FOE, rt.LEAD))
        out += [(f"pack_{name}", sx, sz, faces) for name, sx, sz, faces in STREET]
    return out


# --- the sheet ---------------------------------------------------------------------------------------------------------

def sheet_run(out):
    import hard_cut as hc
    bm, _, he, el, phone, laid, box, over = rt.stage(out)
    layers, shots = out / "layers", out / "shots"
    gap, W = 24, 1900
    ink, soft, paper, plate = "#EDE6D6", "#B4AC9C", "#101117", "#1A1B24"
    parts, text_of = [], []

    def part(height, name):
        page = rs.canvas(W, height, rs.rgb(paper))
        parts.append((name, page))
        text_of.append([])
        return page, text_of[-1]

    def layer(stem):
        got = np.load(layers / f"{stem}.npz")
        px, (x0, y0) = got["px"].astype(np.float32), got["at"]
        full = np.zeros((he.H, he.W, 4), np.float32)
        full[y0:y0 + px.shape[0], x0:x0 + px.shape[1]] = px
        return full

    still = rs.load(STILL)
    street_bg = still.copy()
    street_bg[..., :3] = he.to_linear(still[..., :3])
    gx, gz = he.ground_points()

    def street(key):
        stems = [(f"{key}_pack_{name}", sx, sz) for name, sx, sz, _ in STREET]
        got = [(he.project((sx, 0, sz))[2], layer(stem)) for stem, sx, sz in stems]
        return he.lay(street_bg, got, [(sx, sz, 1.0) for _, sx, sz in stems], "Normal", gx, gz)

    # 1. each take from the front and from the game's camera
    col = (W - 2 * gap) // 3
    page, text = part(1150, "full")
    text.append((gap, 20, 30, TITLE, ink))
    text += hc.wrapped(gap, 60, 16, ABOUT, soft, W - 2 * gap)
    for i, key in enumerate(WHO):
        x0 = gap + i * col
        title, lines = SAID[key]
        text.append((x0, 150, 24, title, ink))
        text += [(x0, 184 + k * 20, 14, line_, soft) for k, line_ in enumerate(lines)]
        front = rs.shrink(rs.trim(rs.load(shots / f"{key}_front.png")), 0.7)
        game = rs.shrink(rs.trim(rs.load(shots / f"{key}_game.png")), 0.48)
        rs.stand(page, front, x0, 800, col - gap)
        rs.stand(page, game, x0, 1136, col - gap)

    # 2. the head from six sides
    turn = {key: rs.shrink(rs.load(shots / f"{key}_turn.png"), (W - 4 * gap) / 3 / 1260) for key in WHO}
    th = turn[WHO[0]].shape[0]
    page, text = part(46 + th + 40, "heads")
    text.append((gap, 14, 18, "The head from six sides: face on, each three-quarter, a side, the back, and the game's camera.", ink))
    for i, key in enumerate(WHO):
        x0 = gap + i * (turn[key].shape[1] + gap)
        rs.paste(page, turn[key], x0, 46)
        text.append((x0, 46 + th + 10, 14, SAID[key][0], soft))

    # 3. each fighting Pip, then Rook, on the deck
    fight_box = box([rt.LEAD, rt.FOE], 3.2, 10)
    cell = (W - 5 * gap) // 4
    fights = {(lead, key): rs.shrink(he.crop(laid([(f"{lead}_fight", *rt.LEAD), (f"{key}_foe", *rt.FOE)]), *fight_box), phone)
              for lead in LEADS for key in FOES}
    fw, fh = fights["Pip", WHO[0]].shape[1], fights["Pip", WHO[0]].shape[0]
    k = max(1, min(3, cell // fw))
    page, text = part(60 + 2 * (fh * k + 40), "fight")
    text.append((gap, 14, 18, f"Fighting Pip (C, the finish), then Rook, on the deck from the player's camera: the smallest phone ({el.PHONE_H} "
                              f"pixels high) at {k} times. The deck is a stand-in; the camera and the light are the game's.", ink))
    for r, lead in enumerate(LEADS):
        for i, key in enumerate(FOES):
            x0, y0 = gap + i * (cell + gap), 46 + r * (fh * k + 40)
            rs.paste(page, bm.zoomed(fights[lead, key], k), x0, y0)
            text.append((x0, y0 + fh * k + 6, 14, f"{SAID[key][0]} against {lead}", soft))

    # 4. each as a pack in Lantern Row's street
    frames = {key: street(key) for key in FOES}
    small = {key: rs.shrink(frames[key], 0.42) for key in FOES}
    sw_, sh_ = small[WHO[0]].shape[1], small[WHO[0]].shape[0]
    page, text = part(60 + 2 * (sh_ + 34), "street")
    text.append((gap, 14, 18, "A pack of three in Lantern Row's street by day, from the game's camera (TR24's still: its HUD, its avatar and "
                              "its Rook are the old ones).", ink))
    for i, key in enumerate(FOES):
        x0, y0 = gap + (i % 2) * (sw_ + gap), 46 + (i // 2) * (sh_ + 34)
        rs.paste(page, small[key], x0, y0)
        text.append((x0, y0 + sh_ + 6, 14, SAID[key][0], soft))

    # 5. the line-up at the lead's distance
    row_box = box([(ROW_X[0], rt.ROW_Z), (ROW_X[-1], rt.ROW_Z)], 3.0, 10)
    row = rs.shrink(he.crop(laid([(f"{key}_row", x, rt.ROW_Z) for key, x in zip(ROW, ROW_X)]), *row_box), phone)
    rw, rh = row.shape[1], row.shape[0]
    kr = max(1, min(4, (W - 3 * gap - rw) // rw))
    page, text = part(60 + rh * kr + 20, "row")
    text.append((gap, 14, 18, f"At the lead's distance, turned to the player: {ROW_SAID}. At the smallest phone, then "
                              f"{kr} times.", ink))
    rs.paste(page, row, gap, 46)
    rs.paste(page, bm.zoomed(row, kr), gap + rw + gap, 46)

    # 6. at 64 pixels
    page, text = part(400, "small")
    text.append((gap, 14, 18, "At 64 pixels to a 5-stud body: turned to the player, then fighting. Over night, over the deck, and the outline.", ink))
    x = gap
    for key in ROW:
        place = (ROW_X[ROW.index(key)], rt.ROW_Z)
        pair = [(f"{key}_row", place), (f"{key}_fight", rt.LEAD) if key in LEADS else (f"{key}_foe", rt.FOE)]
        text.append((x, 46, 14, SAID[key][0], soft))
        widest = 0
        for stem, at in pair:
            for r, (ground, dark_) in enumerate((("#101117", False), ("#CCD2D9", False), ("#E9E4D8", True))):
                tile = over(stem, at, ground, dark_)
                rs.paste(page, tile, x + widest, 72 + r * 106 + (100 - tile.shape[0]))
            widest += tile.shape[1] + 8
        x += widest + 26

    height = sum(page.shape[0] for _, page in parts)
    whole = rs.canvas(W, height, rs.rgb(paper))
    y = 0
    for (name, page), text in zip(parts, text_of):
        rs.paste(page, rs.text_layer(W, page.shape[0], text), 0, 0)
        rs.save(page, out / f"{STEM}_{name}.png")
        whole[y:y + page.shape[0]] = page
        y += page.shape[0]
    rs.save(whole, out / f"{STEM}.png")
    beside(out, frames, rs, he)


def beside(out, frames, rs_, he):
    """Internal: the street frames beside Jujutsu Infinite's at the same height (build/reference/takes/ only)."""
    tall = 420
    ours = [rs_.shrink(frames[key], tall / he.H) for key in FOES]
    shipped = []
    for path in SHIPPED:
        img = rs_.load(path)
        shipped.append(rs_.shrink(img, tall / img.shape[0]))
    gap = 16
    wide = max(sum(p.shape[1] for p in ours[:2]) + gap * 3, sum(p.shape[1] for p in shipped) + gap * 3)
    page = rs_.canvas(wide, 60 + 3 * (tall + 40), rs_.rgb("#101117"))
    text = [(gap, 14, 18, "AR75's Shades beside Jujutsu Infinite at the same height (internal: the shipped frames are reference)", "#EDE6D6")]
    for r, row in enumerate((ours[:2], ours[2:], shipped)):
        x = gap
        for i, p in enumerate(row):
            y = 46 + r * (tall + 40)
            rs_.paste(page, p, x, y)
            name = SAID[FOES[r * 2 + i]][0] if r < 2 else ("Jujutsu Infinite, a curse" if i == 0 else "Jujutsu Infinite, a boss fight")
            text.append((x, y + tall + 6, 14, name, "#B4AC9C"))
            x += p.shape[1] + gap
    rs_.paste(page, rs_.text_layer(wide, page.shape[0], text), 0, 0)
    rs_.save(page, rt.internal(BESIDE))


if __name__ == "__main__":
    rt.TAKES, rt.SAID, rt.WHO = TAKES, SAID, tuple(TAKES)
    rt.spots = spots
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "sheet"
    if mode == "takes":
        rt.takes_run(OUT, rest[1:] or list(TAKES), finish=pt.measured)
    elif mode == "rook":
        rt.rook_run(OUT)
    elif mode == "shade":
        rt.shade_run(OUT)
    elif mode == "sheet":
        sheet_run(OUT)
