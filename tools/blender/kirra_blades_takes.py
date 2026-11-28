"""Kirra's blades, overhauled (docs/requests/AR78.md): the targets, the belt pair at three sizes beside today's pair.

The director, 2026-11-28, about 02:40: "kirra swords model on her back is horrible still look like toys". Research's
cause: thick flat blades in an even grey with a soft shine, like plastic; a guard and a grip too large for the blade;
bare steel worn on the back. Its direction: two short blades, sheathed in dark scabbards, crossed low on her back,
the grips wrapped in her blue, the metal thin and dark with one bright line, no shine.

Round 1 drew three carries at 1.58 studs (a low cross at 30 degrees, a belt pair at 8, a steep cross at 55). The
director, 2026-11-28, 11:04, on its sheet: "they are way to small and i like B pose more". So round 2 is B, the belt pair
(a flat X across her belt, 8 degrees off level, the grips out past her hips), at three sizes. Each scales research's
proportions whole, so the grip and guard stay in proportion to the blade (a guard and grip too large for it was a toy
cue):
- the blade: 1.58 x S studs from the pommel's end to the scabbard's end (today's 1.86), its grip 0.44 of them, in a
  cord of her blue wound in diamonds over the dark, a dark iron cap, a small oval guard of dark iron whose rim is the
  one bright line;
- a slim scabbard in near-black lacquer, matte; a dark iron mouth and end; her teal cord wound once under the mouth,
  a dark loop lower down (a lit line along it, tried, didn't read at 4x: dropped);
- the steel stays in it (its drawn look comes with the pick, for Scarf Step).

    blender.exe -b --factory-startup --python tools/blender/kirra_blades_takes.py -- <out_dir> takes [T B1 B2 B3]
    blender.exe -b --factory-startup --python tools/blender/kirra_blades_takes.py -- <out_dir> sheet

`takes` draws today's Kirra (T) and the three from her back, from behind her left, from the game's camera and in the
game's frame; `sheet` lays them side by side: at the reference unit's size, at the smallest phone's size in the game's
frame, and up close (internal, beside an Anime Vanguards unit: build/reference/takes/kirra_blades_beside.png; ours
alone: <out_dir>/kirra_blades.png).
"""
import math
import sys
from pathlib import Path

import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make as km  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import rook_make_takes as rmt  # noqa: E402
import rook_sheet as rs  # noqa: E402
from anime_make import tone  # noqa: E402

TODAY = dict(ks.SHEATHS)
NAVY, TEAL = "#26345F", "#1FA39A"                       # her top and her scarf
LACQUER, IRON, LINE = "#14171F", "#2A2F3A", "#D3DCE8"   # the scabbard, the fittings, the one bright line
CORD, UNDER = "#3A5598", "#0D1017"                      # her blue, lifted off her navy top, and the dark under it
LOOP = "#1B1F2B"
BASE = 1.58     # round 1's length, the pommel's end to the scabbard's end; each size scales it and every section whole
SIZES = {"B1": 1.4, "B2": 1.6, "B3": 1.8}
S = 1.0         # the take's size, set before its make


def carry(size, angle=8.0, z=2.62):
    """B's lines at `size`, (the pommel's end, the scabbard's end), the right one under: a flat X across her belt,
    `angle` degrees off level, each pommel out past her hip by 0.3 x size, the pair standing off her back by its
    thickness."""
    length, x = BASE * size, 1.0 + 0.3 * size
    inner = -0.52 - 0.06 * size
    outer = inner - 0.12 * size
    d = Vector((-math.cos(math.radians(angle)), 0.0, -math.sin(math.radians(angle))))
    right, left = Vector((x, inner, z)), Vector((-x, outer, z))
    return {"Right": (tuple(right), tuple(right + d * length)),
            "Left": (tuple(left), tuple(left + Vector((-d.x, 0.0, d.z)) * length))}


CARRIES = {k: carry(v) for k, v in SIZES.items()}
SAID = {
    "T": ("Today", ("the lacquered pair, in the game:", "crossed high, 1.86 studs, light fittings")),
    **{k: (f"B at {BASE * v:.1f} studs", ("the belt pair, a flat X at 8 degrees,", f"the grips past her hips, x{v:g} round 1"))
       for k, v in SIZES.items()},
}


def sized(rings):
    """Rings drawn at round 1's size, at the take's: along, across and through, all by S."""
    return [tuple(v * S for v in r) for r in rings]


def wrapped_grip(b, side, a, b_, w, t, rows=9):
    """The grip from `a` to `b_`: her blue cord wound in diamonds over the dark, each turn a stretch, the cord's
    crossings stepping round a side a turn."""
    rings = sized([(a + (b_ - a) * i / rows, w, t) for i in range(rows + 1)])
    km.turned(b, side, rings, lambda i, k: CORD if (i + k) % 2 == 0 else UNDER)


def hilt(b, side):
    km.turned(b, side, sized([(0.0, 0.042, 0.036), (0.01, 0.062, 0.052), (0.03, 0.062, 0.052)]), [IRON, IRON])   # the cap
    wrapped_grip(b, side, 0.03, 0.47, 0.058, 0.05, rows=8)
    # the guard: small and oval, dark iron, its rim the one bright line
    km.turned(b, side, sized([(0.47, 0.064, 0.052), (0.47, 0.1, 0.07), (0.482, 0.106, 0.074), (0.495, 0.1, 0.07),
                              (0.495, 0.064, 0.052)]), [IRON, LINE, LINE, IRON], sides=12, offset=15.0)


def scabbard(b, side):
    rings = [(0.497, 0.074, 0.056), (0.54, 0.074, 0.056),                             # the mouth, dark iron
             (0.54, 0.07, 0.052), (0.57, 0.07, 0.052),
             (0.57, 0.078, 0.06), (0.62, 0.078, 0.06), (0.62, 0.07, 0.052),           # her teal cord, wound once
             (0.98, 0.066, 0.05), (0.98, 0.075, 0.059), (1.04, 0.075, 0.059), (1.04, 0.066, 0.05),   # the loop
             (BASE - 0.08, 0.06, 0.046), (BASE - 0.08, 0.064, 0.049), (BASE - 0.025, 0.054, 0.043),
             (BASE, 0.026, 0.022)]   # the end, iron
    cols = [IRON, LACQUER, TEAL, TEAL, TEAL, LACQUER, LOOP, LOOP, LOOP, LACQUER, IRON, IRON, IRON, IRON]
    km.turned(b, side, sized(rings), cols)


def pair(line):
    """The make for kt.take_a: the scarf, a hilt a blade on its own piece, the scabbards one piece, the tail."""
    def make(colour, ends, guards):
        ks.SHEATHS = dict(line)
        blades = []
        for piece, side in km.BLADES.items():
            b = am.Built(piece)
            hilt(b, side)
            blades.append(b)
        sheaths = am.Built("Sheaths")
        for side in km.BLADES.values():
            scabbard(sheaths, side)
        return [kt.scarf(colour, ends, long_tail=False), *blades, sheaths, *km.tail_chain(colour, ends)]
    return make


def belted(key):
    """A take: her, with a belt right round her hips in place of the strap from her shoulder (it held the blades high;
    the scabbards ride the belt now), and the pair on `key`'s carry."""
    def run(joints, folder):
        global S
        S = SIZES[key]
        held, blocks_of, strap = {}, kt.blocks_of, kt.strap

        def keep(*args, **kw):
            held["b"] = blocks_of(*args, **kw)
            return held["b"]

        def belt(p, a, b, colour, wide=0.1):
            if "belt" not in held:   # once, all round: the strap was drawn on her front and her back
                held["belt"] = rmt.band(held["b"]["torso"].wrap, 0.36, 0.48, colour, tone(colour, 0.5))
        kt.blocks_of, kt.strap = keep, belt
        try:
            return kt.take_a(joints, folder, pieces=pair(CARRIES[key]), face_draw=km.PICK["face"])
        finally:
            kt.blocks_of, kt.strap = blocks_of, strap
    return run


def today(joints, folder):
    ks.SHEATHS = dict(TODAY)
    return kt.take_a(joints, folder, pieces=km.gear_pieces(km.lacquer), face_draw=km.PICK["face"])


TAKES = {"T": today, **{k: belted(k) for k in CARRIES}}


# --- the sheet -------------------------------------------------------------------------------------------------------

def up(img, k):
    return np.repeat(np.repeat(img, k, axis=0), k, axis=1)


def sheet_run(out):
    import hard_ember as he
    import shade_elites as el
    shots, layers = out / "shots", out / "layers"
    ink, soft, paper, pale = "#EDE6D6", "#B4AC9C", "#101117", "#DFE1E6"
    keys = list(TAKES)
    gap, W = 24, 2560
    views = (("back", "from behind"), ("game", "the game's camera"))
    full = {(k, v): rs.trim(rs.load(shots / f"{k}_{v}.png")) for k in keys for v in ("back", "back34", "game")}
    k_ = 0.46   # then smaller, all alike, till the row and the reference fit the page
    av_w = rmt.reference(kt.BESIDE[0][0], rmt.SHOT / rmt.SPAN * k_, kt.BESIDE[0][1]).shape[1]
    row_w = av_w + gap + sum(full[(k, v)].shape[1] * k_ + 10 for k in keys for v, _ in views) + gap * len(keys)
    k_ *= min(1.0, (W - 2 * gap) / row_w)
    per = rmt.SHOT / rmt.SPAN * k_
    tiles = {key: rs.shrink(t, k_) for key, t in full.items()}
    tall = max(t.shape[0] for t in tiles.values())
    phone = {k: rs.trim(rs.shrink(np.load(layers / f"{k}_fight.npz")["px"], el.PHONE_H / he.H)) for k in keys}
    ph = max(p.shape[0] for p in phone.values()) * 3
    close_h, close_w = 330, 360
    H = 70 + tall + 60 + 40 + ph + 50 + 40 + close_h * 2 + 90
    for beside in (True, False):
        page = rs.canvas(W, H, rs.rgb(paper))
        text = [(gap, 16, 20, "AR78: Kirra's blades, the belt pair at three sizes beside today's pair, from behind and from "
                              "the game's camera, at the same pixels a stud" + (" as an Anime Vanguards unit (reference)." if beside
                                                                               else "."), ink)]
        rs.fill(page, 0, 56, W, tall + 14, rs.rgb(pale))
        x = gap
        if beside:
            av = rmt.reference(kt.BESIDE[0][0], per, kt.BESIDE[0][1])
            rs.paste(page, av, x, 56 + tall - av.shape[0])
            x += av.shape[1] + gap
        for k in keys:
            for v, said in views:
                t = tiles[(k, v)]
                rs.paste(page, t, x, 56 + tall - t.shape[0])
                text.append((x, 56 + tall + 22, 14, f"{SAID[k][0]}, {said}", soft))
                x += t.shape[1] + 10
            x += gap
        y = 56 + tall + 60
        text.append((gap, y, 18, "In the game's frame on the smallest phone: each at its own pixels, then three times them.", ink))
        x = gap
        for k in keys:
            p = phone[k]
            rs.paste(page, p, x, y + 40 + ph - p.shape[0])
            big = up(p, 3)
            rs.paste(page, big, x + p.shape[1] + 12, y + 40 + ph - big.shape[0])
            text.append((x, y + 40 + ph + 8, 14, SAID[k][0], soft))
            x += p.shape[1] + big.shape[1] + gap * 2
        y += 40 + ph + 50
        text.append((gap, y, 18, "Up close: from behind and from behind her left, at twice the size above.", ink))
        x = gap
        for k in keys:
            for row, v in enumerate(("back", "back34")):
                t = full[(k, v)]
                h, w = t.shape[:2]
                # her middle, from the waist to the shoulders: the carry's rows on the full shot
                mid_x, mid_y = w // 2, int(h * 0.42)
                crop = t[max(0, mid_y - close_h // 2): mid_y + close_h // 2, max(0, mid_x - close_w // 2): mid_x + close_w // 2]
                rs.paste(page, crop, x, y + 40 + row * (close_h + 8))
            for i, said in enumerate((f"{SAID[k][0]}:", *SAID[k][1])):
                text.append((x, y + 40 + 2 * (close_h + 8) + i * 18, 14, said, soft))
            x += close_w + gap
        rs.paste(page, rs.text_layer(W, H, text), 0, 0)
        rs.save(page, rmt.internal("kirra_blades_beside.png") if beside else (out / "kirra_blades.png").resolve())


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "takes"
    rmt.TAKES, rmt.SAID, rmt.WHO = TAKES, SAID, tuple(TAKES)
    rmt.VIEWS.update(back=(0, 6), back34=(326, 6))
    if mode == "takes":
        rmt.takes_run(OUT, rest[1:] or list(TAKES), finish=kt.measured)
    elif mode == "sheet":
        sheet_run(OUT)
