"""The hit sparks' star as flipbook sheets (AR61, research's round of 2026-11-27, 12:35: "fewer arms, shorter and wider,
with a soft falloff"). Scintilla's.

    py tools/fx/hit_star_sheets.py [out_dir]        (default: build/handoff/Hits/sheets)

The star in the game was the kit's spark sheet: eight long thin arms, outlined, at about twice the target's reach. The
target's star (tools/fx/spark_targets.py, star) is four arms at rung 2, six at 3 and nine at 4, each 0.9 of a rung's
size long and 0.16 wide, soft, snapping open in 2 frames and breaking outward, gone by frame 10, 12 or 14. These sheets
are that star, drawn by the target's own geometry, frame by frame, facing the camera:

- hit_star{4,6,9}_light: the arms and their core as light, in the rung's colour baked in (the plain hit's warm white,
  the critical's gold). Hue held: where the light passes 1 it's scaled down whole, never pushed toward white, so the gold
  stays gold at night (research: "rung 4 must read gold, as by day"). The target's bloom, kept in the same hue.
- hit_star{4,6,9}_ink: the target's ink twin, twice the arm's width, half seen, under the light: its read on the pale deck.

Every arm is the same length but the odd ones (0.75): the arm along the blow, the target's longest, is the rows' Lance,
which follows the blow from any camera; a sheet can't. Arm 0 points up.

Sheet: Grid4x4 of 256 px cells, one OneShot particle a life of (end + 1) / 60 s; cell i is the target's frame
i (end + 1) / 16. The cell is HALF studs each way of a rung's size: a particle's Size is its half-width (measured: the
kit's spark sheet at Size 2.97 drew its arms at about 2.5 studs, twice the target's, AR61's take of 2026-11-27), so its
Size is HALF times the rung's size. Light only: no wound, nothing red, nothing left behind (AGENTS.md, rule 4).
"""
import math
import subprocess
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import BLOOM, blur, linear_to_srgb  # noqa: E402
from spark_targets import GOLD, INK, PLAIN, SIZE, ease_out, fade, life  # noqa: E402

OUT = ROOT / "build" / "handoff" / "Hits" / "sheets"
CELL = 256
HALF = 1.6  # the cell's half-width, in a rung's size (the arms' furthest reach is 1.215, their soft ends past it)
PX = CELL / (2 * HALF)  # pixels a rung's size, in the cell
ARMS = {2: 4, 3: 6, 4: 9}
END = {2: 10, 3: 12, 4: 14}
DECK_H, DECK_PX = 1134, 40.26  # the target's deck frame: its height, and its pixels a stud at the contact (stage_deck)
# Only the target's tight bloom is baked in: its wide one is the rows' Back, kept at its size (research, 12:35), and in
# a cell it would run past the edge.
TIGHT = BLOOM[0]
_yy, _xx = np.mgrid[0:CELL, 0:CELL].astype(np.float32)


def streak(field, a, b, w, soft):
    """The target's streak (paintover.Frame.streak), in cell pixels: a line from a to b, w wide, its falloff soft."""
    d = b - a
    L2 = max(float(d @ d), 1e-6)
    t = np.clip(((_xx - a[0]) * d[0] + (_yy - a[1]) * d[1]) / L2, 0, 1)
    dist = np.hypot(_xx - (a[0] + t * d[0]), _yy - (a[1] + t * d[1]))
    wid = w / 2
    field += np.clip(1 - (dist - wid * (1 - soft)) / max(wid * soft * 2, 0.6), 0, 1) ** 2


def cell(rung, f):
    """Frame f of the target's star at this rung, as (light RGB, linear, unclipped; ink coverage)."""
    light = np.zeros((CELL, CELL, 3), np.float32)
    ink = np.zeros((CELL, CELL), np.float32)
    if f < 0 or f > END[rung]:
        return light, ink
    c = np.array([CELL / 2, CELL / 2])
    hue = np.asarray(GOLD if rung >= 4 else PLAIN, np.float32)
    L, W = 0.9 * PX, 0.16 * PX
    open_ = ease_out((f + 1) / 2)
    brk = life(f, 2, END[rung])
    k = 2.6 * fade(f, 3, END[rung])
    arms = ARMS[rung]
    for i in range(arms):
        a = -math.pi / 2 + i / arms * 2 * math.pi
        long = 0.75 if i % 2 else 1.0
        v = np.array([math.cos(a), math.sin(a)])
        root = c + v * L * (0.05 + 0.6 * brk) * long
        tip = c + v * L * long * (open_ + 0.35 * brk)
        w = W * (1 - 0.55 * brk)
        lay = np.zeros((CELL, CELL), np.float32)
        streak(lay, root, tip, w * 2.0, 0.7)
        ink += np.clip(lay * 0.5 * fade(f, 2, END[rung]), 0, 1) * (1 - ink)
        arm = np.zeros((CELL, CELL), np.float32)
        streak(arm, root, tip, w, 0.55)
        light += arm[..., None] * hue * k
    r = 0.16 * PX * (1 - 0.5 * brk)  # the core: a tight disk in its own glow (paintover.Frame.core)
    d = np.hypot(_xx - c[0], _yy - c[1])
    kc = 3.2 * fade(f, 1, 6)
    light += (np.exp(-(d / max(r, 0.5)) ** 4) * kc + np.exp(-(d / max(r * 2.4, 0.5)) ** 1.6) * kc * 0.35)[..., None] * hue
    hot = np.clip(light - 0.6, 0, None)
    sigma, s = TIGHT
    light = light + blur(hot, sigma * DECK_H / DECK_PX * PX / SIZE[rung]) * s
    edge = np.clip((CELL / 2 - 2 - np.hypot(_xx - c[0], _yy - c[1])) / 18, 0, 1)  # nothing reaches the cell's edge
    return light * edge[..., None], ink * edge


def to_light(light):
    """Light as an additive particle's picture: alpha the light's height, colour its hue, held where it passes 1."""
    peak = light.max(axis=2, keepdims=True)
    a = np.clip(peak, 0, 1)
    rgb = np.where(peak > 1e-4, light / np.maximum(peak, 1e-4), 0)  # the hue at full strength
    return np.concatenate([linear_to_srgb(rgb), a], axis=2)


def to_ink(ink):
    rgb = np.broadcast_to(linear_to_srgb(np.asarray(INK, np.float32)), ink.shape + (3,))
    return np.concatenate([rgb, ink[..., None]], axis=2)


def write_rgba(img, path):
    h, w, _ = img.shape
    data = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{w}x{h}", "-i", "-",
                    "-pix_fmt", "rgba", str(path)], input=data, check=True)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    for rung, arms in ARMS.items():
        sheets = {"light": np.zeros((CELL * 4, CELL * 4, 4), np.float32), "ink": np.zeros((CELL * 4, CELL * 4, 4), np.float32)}
        for i in range(16):
            f = i * (END[rung] + 1) / 16
            light, ink = cell(rung, f)
            y, x = (i // 4) * CELL, (i % 4) * CELL
            sheets["light"][y:y + CELL, x:x + CELL] = to_light(light)
            sheets["ink"][y:y + CELL, x:x + CELL] = to_ink(ink)
        for name, img in sheets.items():
            path = out / f"hit_star{arms}_{name}.png"
            write_rgba(img, path)
            print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}: rung {rung}, "
                  f"life {(END[rung] + 1) / 60:.4f} s, Size {HALF} x the rung's size")


if __name__ == "__main__":
    main()
