"""AR61's targets: the shared kit's landed hit at rungs 2, 3 and 4, painted over a frozen impact frame of the game, for
research's pick (AGENTS.md, "Every action, world, effect and screen"). Three techniques: the star, the crescent and the pop.
Scintilla's.

    py tools/fx/spark_targets.py <stage.json> [out_dir] [star,crescent,pop]     (default out: build/handoff/Hits/targets)

A stage (written by the capture: the frame, its camera, and the hit's world points, as AR58's):
    {"Picture": "backdrop_deck.png", "Camera": {"CFrame": [12], "Fov": deg, "Viewport": [w, h]},
     "Points": {"Surface": [x,y,z], "AttackerRoot": [...], "StruckRoot": [...], "AttackerChest": [...], "StruckChest": [...]},
     "Scale": 1.0, "Crop": [x, y, w, h], "Hud": "hud_mask_deck.png", "Name": "deck"}
The blow is StruckRoot - AttackerRoot flattened on the ground, as the hook anchors it (AR61, "The hook asked of Faber").

Feel line (AR61): your fighter's blow lands and a crisp shape of light snaps open on the struck side, its needles flung on
along the blow and slowing, gone before the next blow lands; a combo's last opens wider with a ring, and a critical bursts
gold and lights the two bodies.

Every technique keeps the request's levers on the same frames, so only the hero shape differs:
- frame 0, the hit's frame: the hero shape's first frame and a backlight under it (punctuation);
- frame 1: the needles, thrown along the blow, fast then slow (Drag 9), stretched along their travel;
- frame 3, rungs 3 and 4: the ring, a breath after;
- rung 4: gold (the critical's number, #FFCF4D) and a light on the two bodies.
Warm white (the plain number, #F8F1DF) with its ink twin (#1C1726) laid under the hero's edge, so it holds on the pale deck.
Light only: no drop, no splash, nothing red, nothing falling (the content check's conditions on AR61's spec).
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np

from paintover import Frame, hexc, phone_sheets, read_png, strip, write_png

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Hits" / "targets"
PLAIN = hexc("#F8F1DF")  # UIKit.Numbers' plain hit
GOLD = hexc("#FFCF4D")  # UIKit.Numbers' critical
INK = hexc("#1C1726")  # the kit's Sheet Dark
UP = np.array([0.0, 1.0, 0.0])
DRAG = 9.0
RUNGS = (2, 3, 4)
SIZE = {2: 1.0, 3: 1.35, 4: 1.7}  # the hero's size by rung, a share of rung 2's
NEEDLES = {2: 5, 3: 8, 4: 12}


def ease_out(t):
    t = min(max(t, 0.0), 1.0)
    return 1 - (1 - t) ** 3


def life(f, a, b):
    return min(max((f - a) / (b - a), 0.0), 1.0) if b > a else float(f >= a)


def fade(f, a, b):
    return 1.0 - life(f, a, b)


def flat(v):
    v = np.array(v, float)
    v[1] = 0
    n = np.linalg.norm(v)
    return v / n if n > 1e-6 else np.array([0.0, 0.0, -1.0])


class Stage:
    def __init__(self, path: Path):
        data = json.loads(path.read_text(encoding="utf-8"))
        self.name = data.get("Name", path.stem)
        self.picture = (path.parent / data["Picture"]).resolve()
        self.camera = data["Camera"]
        v = {k: np.array(p, float) for k, p in data["Points"].items()}
        self.surface = v["Surface"]
        self.a_chest, self.s_chest = v["AttackerChest"], v["StruckChest"]
        self.blow = flat(v["StruckRoot"] - v["AttackerRoot"])
        self.side = np.cross(UP, self.blow)  # across the blow, on the ground
        self.scale = data.get("Scale", 1.0)
        self.base = read_png(self.picture)
        self.crop = data.get("Crop")
        hud = data.get("Hud")
        self.hud = read_png((path.parent / hud).resolve())[..., :1] if hud else None

    def frame(self) -> Frame:
        return Frame(self.picture, self.camera, base=self.base)


def colour(rung):
    return GOLD if rung >= 4 else PLAIN


# --- shared levers ------------------------------------------------------------------------------------------------------
def backlight(fr: Frame, s: Stage, f: float, rung: int):
    """Under the hero on the hit's frame: a soft warm glow, gone in 5 frames; at rung 4 a light on the two bodies."""
    k = fade(f, 0, 5) * (f >= 0)
    if k > 0:
        fr.glow(s.surface, 0.9 * SIZE[rung] * s.scale, colour(rung), 0.5 * k)
    if rung >= 4:
        lit = fade(f, 1, 12) * (f >= 0)
        if lit > 0:
            for p in (s.s_chest, s.a_chest):
                fr.glow(p, 1.8 * s.scale, GOLD, 0.08 * lit, falloff=1.6)


def needles(fr: Frame, s: Stage, f: float, rung: int, seed=5, start=1, speed=(26, 38), cone=0.55, up=0.15):
    """Thin straight light lines thrown on along the blow from the frame after the hit, fast then slow (Drag 9), each
    stretched along its travel and gone as it slows: never a round head, never falling."""
    t = (f - start) / 60
    if t < 0:
        return
    rng = np.random.default_rng(seed + rung)
    for i in range(NEEDLES[rung]):
        lean = s.side * rng.uniform(-cone, cone) + UP * rng.uniform(-cone * 0.6, cone * 0.6 + up)
        d = s.blow + lean
        d /= np.linalg.norm(d)
        v0 = rng.uniform(*speed) * (1 + 0.2 * (rung - 2)) * s.scale
        span = rng.uniform(0.16, 0.26)  # its life, in seconds
        if t > span:
            continue
        head = (v0 / DRAG) * (1 - math.exp(-DRAG * t))
        vel = v0 * math.exp(-DRAG * t)
        length = max(0.25, vel * 0.035) * s.scale
        k = fade(t, span * 0.45, span) * 2.0
        a = s.surface + d * max(0.0, head - length)
        b = s.surface + d * (head + 0.05)
        fr.streak(a, b, 0.02 * s.scale, 0.09 * s.scale, colour(rung), k, soft=0.5)


def ring(fr: Frame, s: Stage, f: float, rung: int, at=3, r0=0.5, r1=1.9):
    """At rungs 3 and 4, a breath after: a thin ring facing the camera, swelling and fading."""
    if rung < 3 or f < at:
        return
    t = f - at
    k = fade(t, 2, 12)
    if k <= 0:
        return
    c = fr.at(s.surface)
    r = fr.cam.px(s.surface, (r0 + (r1 - r0) * ease_out(t / 10)) * SIZE[rung] / SIZE[3] * s.scale)
    w = max(1.5, fr.cam.px(s.surface, 0.07 * s.scale) * (1 - 0.6 * life(t, 0, 10)))
    steps = 72
    pts = [c + r * np.array([math.cos(a), math.sin(a)]) for a in np.linspace(0, 2 * math.pi, steps + 1)]
    for p0, p1 in zip(pts, pts[1:]):
        fr.streak(p0, p1, w, w, colour(rung), 1.6 * k, soft=0.8, screen=True)


def screen_dir(fr: Frame, p, d):
    """A world direction at p as a unit direction on the screen."""
    a, b = fr.at(p), fr.at(p + d * 0.5)
    v = b - a
    n = np.linalg.norm(v)
    return v / n if n > 1e-6 else np.array([1.0, 0.0])


# --- the three heroes ---------------------------------------------------------------------------------------------------
def star(fr: Frame, s: Stage, f: float, rung: int):
    """The kit's starburst, facing the camera: snaps open in 2 frames, then its arms break off outward and thin, gone by
    frame 10 (rung 2) to 14 (rung 4). Four arms at rung 2, six at 3, nine at 4; the arm along the blow longest."""
    if f < 0:
        return
    arms = {2: 4, 3: 6, 4: 9}[rung]
    end = {2: 10, 3: 12, 4: 14}[rung]
    if f > end:
        return
    c = fr.at(s.surface)
    blow = screen_dir(fr, s.surface, s.blow)
    base = math.atan2(blow[1], blow[0])
    L = fr.cam.px(s.surface, 0.9 * SIZE[rung] * s.scale)
    W = fr.cam.px(s.surface, 0.16 * SIZE[rung] * s.scale)
    open_ = ease_out((f + 1) / 2)
    brk = life(f, 2, end)  # the break: the arm's root leaves the centre and the arm thins
    k = 2.6 * fade(f, 3, end)
    for i in range(arms):
        a = base + i / arms * 2 * math.pi
        long = 1.25 if i == 0 else (0.75 if i % 2 else 1.0)
        v = np.array([math.cos(a), math.sin(a)])
        root = c + v * L * (0.05 + 0.6 * brk) * long
        tip = c + v * L * long * (open_ + 0.35 * brk)
        w = W * (1 - 0.55 * brk)
        fr.streak(root, tip, w * 2.0, 1.2, INK, ink=0.5 * fade(f, 2, end), screen=True, soft=0.7)  # the ink twin
        fr.streak(root, tip, w, 0.6, colour(rung), k, soft=0.55, screen=True)
    fr.core(s.surface, 0.16 * SIZE[rung] * s.scale * (1 - 0.5 * brk), colour(rung), 3.2 * fade(f, 1, 6))


def crescent(fr: Frame, s: Stage, f: float, rung: int):
    """A crescent of light across the contact, bowed along the blow (its back to the striker), opening in 2 frames, then
    sliding on along the blow and thinning, gone by frame 10 (rung 2) to 14 (rung 4). Rung 3 and up a second, fainter
    crescent inside it; rung 4 a glint at its heart."""
    if f < 0:
        return
    end = {2: 10, 3: 12, 4: 14}[rung]
    if f > end:
        return
    c = fr.at(s.surface)
    blow = screen_dir(fr, s.surface, s.blow)
    across = np.array([-blow[1], blow[0]])
    R = fr.cam.px(s.surface, 0.85 * SIZE[rung] * s.scale)
    W = fr.cam.px(s.surface, 0.2 * SIZE[rung] * s.scale)
    open_ = ease_out((f + 1) / 2)
    go = ease_out(life(f, 1, end))
    k = 2.6 * fade(f, 3, end)
    for n, (bow, kk, ww) in enumerate(((1.0, 1.0, 1.0), (0.62, 0.45, 0.55))):
        if n == 1 and rung < 3:
            break
        centre = c + blow * R * (0.45 * go - 0.15)
        steps = 28
        sweep = 1.15 * open_  # half the arc, radians
        pts, wid = [], []
        for j in range(steps + 1):
            u = -sweep + 2 * sweep * j / steps
            p = centre + across * math.sin(u) * R * bow + blow * (math.cos(u) - 1) * R * 0.55 * bow
            pts.append(p)
            wid.append(W * ww * (1 - 0.6 * go) * math.cos(u * 0.9 / max(sweep, 0.1) * 1.2) ** 2 + 0.8)
        for j in range(steps):
            fr.streak(pts[j], pts[j + 1], wid[j] * 1.9, wid[j + 1] * 1.9, INK, ink=0.45 * kk * fade(f, 2, end), screen=True, soft=0.7)
        for j in range(steps):
            fr.streak(pts[j], pts[j + 1], wid[j], wid[j + 1], colour(rung), k * kk, soft=0.55, screen=True)
    if rung >= 4:
        fr.core(s.surface, 0.18 * s.scale, GOLD, 3.0 * fade(f, 1, 6))
        fr.spikes(s.surface, 4, 0.7 * s.scale, 0.06 * s.scale, GOLD, k=2.0 * fade(f, 1, 7), seed=3, spread=(0.8, 1.0), inner=0.05)


def pop(fr: Frame, s: Stage, f: float, rung: int):
    """A round flash: a white-hot disc for 2 frames, then a thin ring thrown out fast round it, gone by frame 8 (rung 2)
    to 12 (rung 4); rung 3 and up a second ring a beat behind (the request's ring is this one)."""
    if f < 0:
        return
    end = {2: 8, 3: 10, 4: 12}[rung]
    if f > end + 4:
        return
    disc = fade(f, 1, 4)
    if disc > 0:
        fr.core(s.surface, 0.2 * SIZE[rung] * s.scale * (1 + 0.3 * ease_out(f / 3)), colour(rung), 2.6 * disc)
    c = fr.at(s.surface)
    for n, lag in enumerate((0, 2)):
        if n == 1 and rung < 3:
            break
        t = f - lag
        if t < 0:
            continue
        k = fade(t, 2, end - lag)
        if k <= 0:
            continue
        r = fr.cam.px(s.surface, (0.3 + 1.1 * ease_out(t / 6)) * SIZE[rung] * s.scale * (1 - 0.25 * n))
        w = max(1.5, fr.cam.px(s.surface, 0.12 * s.scale) * (1 - 0.7 * life(t, 0, end)))
        steps = 72
        pts = [c + r * np.array([math.cos(a), math.sin(a)]) for a in np.linspace(0, 2 * math.pi, steps + 1)]
        for p0, p1 in zip(pts, pts[1:]):
            fr.streak(p0, p1, w * 1.9, w * 1.9, INK, ink=0.4 * k, screen=True, soft=0.8)
        for p0, p1 in zip(pts, pts[1:]):
            fr.streak(p0, p1, w, w, colour(rung), 1.8 * k, soft=0.7, screen=True)


def technique(hero, own_ring=True):
    def draw(fr: Frame, s: Stage, f: float, rung: int):
        backlight(fr, s, f, rung)
        hero(fr, s, f, rung)
        needles(fr, s, f, rung)
        if own_ring:
            ring(fr, s, f, rung)
    return draw


TARGETS = {  # name: (draw, peak frame, the strip's frames from the hit)
    "star": (technique(star), 2, (-2, 0, 1, 2, 4, 7, 11, 16)),
    "crescent": (technique(crescent), 2, (-2, 0, 1, 2, 4, 7, 11, 16)),
    "pop": (technique(pop, own_ring=False), 2, (-2, 0, 1, 2, 4, 7, 11, 16)),
}


def render(s: Stage, fn, f: float, rung: int) -> np.ndarray:
    fr = s.frame()
    fn(fr, s, f, rung)
    out = fr.render()
    return out if s.hud is None else out * (1 - s.hud) + s.base * s.hud


def crop(img, box):
    if not box:
        return img
    x, y, w, h = box
    return img[y:y + h, x:x + w]


def main(argv):
    stage = Stage(Path(argv[0]))
    out = Path(argv[1]) if len(argv) > 1 else OUT
    only = argv[2].split(",") if len(argv) > 2 else None
    out.mkdir(parents=True, exist_ok=True)
    peaks, names = [], []
    for name, (fn, peak, times) in TARGETS.items():
        if only and name not in only:
            continue
        rungs = [crop(render(stage, fn, peak, r), stage.crop) for r in RUNGS]
        strip(rungs, out / f"{name}_{stage.name}_rungs.png")
        for r in RUNGS:
            path = out / f"{name}_{stage.name}_peak{r}.png"
            write_png(render(stage, fn, peak, r), path)
            if r == 3:
                peaks.append(path)
                names.append(f"{name} ({stage.name}, rung 3)")
        tiles = [crop(render(stage, fn, f, 3), stage.crop) for f in times]
        strip(tiles, out / f"{name}_{stage.name}_strip.png")
        (out / f"{name}_{stage.name}_strip.txt").write_text(
            "rung 3, frames from the hit's frame, at 60 a second: " + ", ".join(str(t) for t in times) + "\n"
            f"{name}_{stage.name}_rungs.png: the peak (frame {peak}) at rungs 2, 3 and 4, left to right.\n", encoding="utf-8")
        print(name, stage.name, "peak", peak, "strip", times)
    if peaks:
        sheet = out / f"phone_{stage.name}"
        sheet.mkdir(exist_ok=True)
        phone_sheets(peaks, sheet, names)


if __name__ == "__main__":
    main(sys.argv[1:])
