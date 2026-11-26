"""AR7's targets: the Lamplighter's swing and challenge, painted over frames of the game, for research's pick in pairs
(AGENTS.md, "Every action, world, effect and screen"). Scintilla's.

    py tools/fx/keeper_targets.py <stage.json> [out_dir] [S1_sweep,S2_two_lights,S3_cut | C1_ring,C2_rays]
    (default out: build/handoff/Lamplighter/targets; default: the move's own targets, by the stage's Move)

A stage, written at the capture (the keeper held on its move's beat, Strike or Stamp, as shade_targets.py's):
    {"Picture": "<held frame>.png", "Camera": {...}, "Kind": "Keeper", "Move": "swing"|"challenge",
     "Points": {"ShadeRoot", "ShadeChest", "LeadRoot", "LeadChest"}, "Ground": y,
     "Paths": {"PoleFoot": [[f, x, y, z], ...], "Lantern": [...]},   (f: frames from the held beat, at 60 a second)
     "Steps": [f, ...], "Tiles": {"<f>": "<frame>.png"},             (the keeper's own pose at each strip frame)
     "Masks": {"Lead": ..., "Shade": ...}, "Hud": ..., "Crop": [x, y, w, h], "Name": ...}
Each strip tile is drawn over the keeper's pose at its own frame; the lead, held at Rook's Hit3, lies over what's
behind it in every tile (its mask). The keeper's own body isn't laid back: where the foot passes behind its hip in the
draw-back, the light draws over it, a limit of these targets.

The keeper's light is its lantern's: warm white, the kit's Warm palette, the family of its signature (KeeperSignature's
Paper glow and its column). One hue, a white core. Nothing red, nothing left behind on the street.

The swing (Definitions.Actions, KeeperSwing: Strike 0.8 s, Recover 1.0 s). Feel line: the keeper draws its pole's foot
back past its hip like a lance, then sweeps it round and across at your fighter's chest, the lantern flung wide behind
its shoulder. Levers: anticipation (the light grows into the blow), weight (the lantern's lag), punctuation (the cut).
- S1, the sweep: one ribbon of light swept by the pole's foot over the last nine frames, widest at its head, a white
  core down it, tapering to nothing behind; it grows in through the draw-back and fades in eight frames after Strike.
- S2, two lights: S1's ribbon, thinner, and the lantern's own glow smeared behind it, later: its weight, flung wide.
- S3, the cut: through the sweep only the foot glows; on Strike, a crisp crescent flashes along the last five frames
  of its path, thick in its middle, with needles off its head along the blow, gone in six frames.

The challenge (KeeperChallenge: Lift 0.7333 s, Stamp 0.9667 s). Feel line: it hears you, lifts its face to you, and
stamps its pole once. Both flare the lantern on Lift (it notices you), so only the stamp's shape differs:
- C1, the ring: on Stamp a thin ring of light runs out over the street from the pole's foot, a white core, and dust
  rises a breath after;
- C2, the rays: on Stamp short rays of light crack out flat along the street from the foot, and the street under it
  lights for a moment.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import Frame, hexc, phone_sheets, read_png, strip, write_png  # noqa: E402
from shade_targets import Stage, crop, ease_out, life  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Lamplighter" / "targets"

WARM = hexc("#FFC98A")  # FxKit.Palettes.Warm's Deep: the light's hue
WARM_MID = hexc("#FFEBC2")  # its Mid: the core's edge
WHITE = hexc("#FFF6E8")  # its core, a warm white
DUST = hexc("#D9CFC0")  # the street's dust, lit

TARGETS = {  # name: (move, peak frame, strip frames)
    "S1_sweep": ("swing", 0, [-8, -6, -4, -2, 0, 2, 4, 8]),
    "S2_two_lights": ("swing", 0, [-8, -6, -4, -2, 0, 2, 4, 8]),
    "S3_cut": ("swing", 1, [-8, -4, -2, 0, 2, 4, 8, 12]),
    "C1_ring": ("challenge", 4, [-16, -14, -10, -4, 0, 2, 4, 8, 12]),
    "C2_rays": ("challenge", 2, [-16, -14, -10, -4, 0, 2, 4, 8, 12]),
}
TRAIL = 9  # frames of the foot's path a sweep covers
LIFT = -14  # the challenge's Lift, in frames from Stamp


class KeeperStage(Stage):
    def __init__(self, path: Path):
        super().__init__(path)
        data = json.loads(path.read_text(encoding="utf-8"))
        self.move = data.get("Move", "swing")
        self.paths = {k: np.array(v, float) for k, v in data.get("Paths", {}).items() if v}
        self.tiles = {int(k): (path.parent / v).resolve() for k, v in data.get("Tiles", {}).items()}

    def point(self, name, f):
        """Where a sampled point is at frame f, between samples by line; held at the path's ends."""
        p = self.paths[name]
        f = min(max(f, p[0, 0]), p[-1, 0])
        return np.array([np.interp(f, p[:, 0], p[:, c]) for c in (1, 2, 3)])

    def frame_at(self, f) -> Frame:
        tile = self.tiles.get(f)
        if tile is None or f == 0:
            return self.frame()
        return Frame(tile, self.camera, base=read_png(tile))


def ribbon(fr: Frame, pts, head_width, colour, k, core=True):
    """A ribbon of light along pts (oldest first): widest at its head, to nothing at its tail, a white core down it."""
    n = len(pts)
    for i in range(n - 1):
        t0, t1 = i / (n - 1), (i + 1) / (n - 1)
        w0, w1 = head_width * t0 ** 1.4, head_width * t1 ** 1.4
        fr.streak(pts[i], pts[i + 1], w0, w1, colour, k * (0.35 + 0.65 * t1), soft=0.7)
        if core:
            fr.streak(pts[i], pts[i + 1], w0 * 0.3, w1 * 0.3, WHITE, k * 1.2 * t1, soft=0.5)


def path_pts(st: KeeperStage, name, a, b, step=0.5):
    if b <= a:
        return []
    return [st.point(name, x) for x in np.arange(a, b + 1e-6, step)]


def draw_swing(fr: Frame, st: KeeperStage, f, shape):
    grow = ease_out(life(f, -10, -1))  # the light grows into the blow
    fade = 1 - life(f, 0, 8)
    k = grow * fade
    if shape in ("S1_sweep", "S2_two_lights") and k > 0:
        width = 0.55 if shape == "S1_sweep" else 0.38
        pts = path_pts(st, "PoleFoot", f - TRAIL + life(f, 0, 8) * TRAIL, f)  # its tail catches up after Strike
        if len(pts) > 1:
            ribbon(fr, pts, width * (0.5 + 0.5 * grow), WARM, 1.6 * k)
        fr.glow(st.point("PoleFoot", f), 0.35, WARM_MID, 1.4 * k)
    if shape == "S2_two_lights":
        lag = ease_out(life(f, -8, 2)) * (1 - life(f, 4, 14))  # the lantern's weight: it trails, later and longer
        pts = path_pts(st, "Lantern", f - 14, f - 2, 1.0)
        for i, q in enumerate(pts):
            t = (i + 1) / max(len(pts), 1)
            fr.glow(q, 0.45 + 0.35 * t, WARM, 0.5 * lag * t)
        fr.glow(st.point("Lantern", f), 0.8, WARM, 0.9 * max(lag, 0.3))
    if shape == "S3_cut":
        if f < 0:  # only the foot glows through the sweep
            fr.glow(st.point("PoleFoot", f), 0.3 + 0.3 * grow, WARM, 1.2 * grow)
        g = f - 0
        if 0 <= g <= 6:
            pts = path_pts(st, "PoleFoot", -5, 0, 0.25)
            n = len(pts)
            thin = 1 - life(g, 1, 6)
            for i in range(n - 1):
                t = (i + 0.5) / (n - 1)
                w = 0.6 * math.sin(math.pi * t) ** 0.8 * thin + 0.02  # a crescent: thick in its middle
                fr.streak(pts[i], pts[i + 1], w, w, WARM, 2.2 * thin, soft=0.55)
                fr.streak(pts[i], pts[i + 1], w * 0.35, w * 0.35, WHITE, 2.6 * thin, soft=0.45)
            head = st.point("PoleFoot", 0)
            way = st.point("PoleFoot", 0) - st.point("PoleFoot", -1)
            way /= max(np.linalg.norm(way), 1e-6)
            rng = np.random.default_rng(5)
            for i in range(5):
                d = way + rng.normal(0, 0.25, 3)
                d /= np.linalg.norm(d)
                reach = 0.3 + 1.8 * ease_out(g / 6)
                fr.streak(head + d * max(reach - 0.8, 0.1), head + d * reach, 0.06, 0.01, WHITE, 1.8 * (1 - life(g, 2, 6)))
            fr.core(head, 0.22, WARM_MID, 2.4 * (1 - life(g, 0, 4)))


def lantern_flare(fr: Frame, st: KeeperStage, f):
    """The lantern notices you: its glow flares on Lift and settles brighter than before."""
    if "Lantern" not in st.paths:
        return
    rise = life(f, LIFT - 2, LIFT + 1) * (1 - 0.45 * life(f, LIFT + 1, LIFT + 9))
    p = st.point("Lantern", f)
    fr.glow(p, 0.9 + 0.9 * rise, WARM, 0.6 + 1.4 * rise)
    fr.core(p, 0.18 + 0.1 * rise, WHITE, 0.8 + 2.0 * rise)


def draw_challenge(fr: Frame, st: KeeperStage, f, shape):
    lantern_flare(fr, st, f)
    g = f
    if g < 0:
        return
    foot = st.point("PoleFoot", 0).copy()
    foot[1] = st.ground + 0.05
    if shape == "C1_ring" and g <= 16:
        r = 0.3 + 3.7 * ease_out(g / 14)
        k = 1 - life(g, 2, 16)
        fr.ring(foot, r, 0.14 * (1 - 0.6 * life(g, 0, 14)), WARM, 1.5 * k)
        fr.ring(foot, r, 0.05, WHITE, 1.6 * k)
        fr.core(foot + np.array([0, 0.1, 0]), 0.25, WARM_MID, 2.4 * (1 - life(g, 0, 5)))
        if g >= 3:  # the dust, a breath after: low, slow, cream
            rng = np.random.default_rng(9)
            rise = ease_out(life(g, 3, 16))
            motes = []
            for i in range(14):
                a = rng.uniform(0, 2 * math.pi)
                d = rng.uniform(0.4, 1.0) * r * 0.8
                motes.append(foot + np.array([math.cos(a) * d, 0.1 + rise * rng.uniform(0.2, 0.7), math.sin(a) * d]))
            fr.motes(motes, 0.18, DUST, 0.55 * (1 - life(g, 10, 16)))
    if shape == "C2_rays" and g <= 12:
        k = 1 - life(g, 1, 10)
        fr.spikes(foot, 9, 2.8 * (0.4 + 0.6 * ease_out(g / 5)), 0.16, WARM, 1.8 * k, seed=4, flat=0.3, spread=(0.5, 1.0))
        fr.spikes(foot, 9, 2.0 * (0.4 + 0.6 * ease_out(g / 5)), 0.05, WHITE, 1.6 * k, seed=4, flat=0.3, spread=(0.5, 1.0))
        fr.glow(foot, 2.2, WARM, 0.55 * (1 - life(g, 0, 12)))
        fr.core(foot + np.array([0, 0.1, 0]), 0.25, WARM_MID, 2.4 * (1 - life(g, 0, 5)))


def render(st: KeeperStage, name, f):
    fr = st.frame_at(f)
    (draw_swing if TARGETS[name][0] == "swing" else draw_challenge)(fr, st, f, name)
    out = fr.render()
    lead = st.masks.get("Lead")
    if lead is not None:  # the lead, nearer the camera, holds still: laid back over the light in every tile
        out = out * (1 - lead[..., None]) + fr.base * lead[..., None]
    base = fr.base
    return out if st.hud is None else out * (1 - st.hud) + base * st.hud


def main(argv):
    st = KeeperStage(Path(argv[0]))
    out = Path(argv[1]) if len(argv) > 1 else OUT
    only = argv[2].split(",") if len(argv) > 2 else None
    out.mkdir(parents=True, exist_ok=True)
    peaks, names = [], []
    for name, (move, peak, times) in TARGETS.items():
        if (only and name not in only) or (not only and move != st.move):
            continue
        path = out / f"{name}_{st.name}_peak.png"
        write_png(render(st, name, peak), path)
        peaks.append(path)
        names.append(f"{name} ({st.name}, frame {peak})")
        strip([crop(render(st, name, f), st.crop) for f in times], out / f"{name}_{st.name}_strip.png")
        beat = "Strike" if move == "swing" else "Stamp"
        (out / f"{name}_{st.name}_strip.txt").write_text(
            f"frames from {beat}, at 60 a second: " + ", ".join(map(str, times)) + "\n", encoding="utf-8")
        print(name, st.name, "peak", peak)
    if peaks:
        sheet = out / f"phone_{st.name}"
        sheet.mkdir(exist_ok=True)
        phone_sheets(peaks, sheet, names)


if __name__ == "__main__":
    main(sys.argv[1:])
