"""AR69's checkpoint sheets (Scintilla, 2026-11-27): the rows in src, drawn offline by tools/blender/ar69_rows.py in
the target's scene, beside the picked target (tools/blender/ar69_targets.py), time for time, by day and at night.

    py tools/fx/ar69_checkpoint.py      (after ar69_rows.py's renders in build/scratch/scintilla/ar69/r_*_rows_*)

Writes build/handoff/ShadeFire/checkpoint/ar69_checkpoint_burn.png and ar69_checkpoint_fall.png. The rows' drawing is a
model of the engine: their geometry, timing and the beams' picture are the rows' own; a SurfaceAppearance's shading,
Neon and Roblox's bloom are approximations, the same for both sides. The Studio take is the judge.
"""
import os
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar69_sheets as S  # noqa: E402

OUT = S.ROOT / "build" / "handoff" / "ShadeFire" / "checkpoint"
WIDTH = 2500
GAP = 10
GREY = 0.16
# where the rows came from: src, or a round's handoff not yet installed (AR69_ROWS, as tools/blender/ar69_rows.py reads)
SOURCE = os.environ.get("AR69_SOURCE", "the rows in src")
NOTE = ("A model of the engine: the rows' geometry, timing and beams' picture are their own; SurfaceAppearance "
        "shading, Neon and bloom are approximate, alike on both sides. The Studio take is the judge.")


def crop_of(look):
    return S.json.loads((S.WORK / "crops.json").read_text())[look]


def frame_at(look, light, t, base_name):
    folder = S.WORK / f"r_{look}_{light}"
    return S.lay(S.base(base_name), S.read_exr(folder / f"fx_{t:.3f}.exr"), S.read_exr(folder / f"light_{t:.3f}.exr"))


def strip(look, light, times, crop, base_name, n_cols):
    cx, cy, cw, ch = crop
    sw = (WIDTH - GAP * (n_cols + 1)) // n_cols
    sh = round(sw * ch / cw)
    tiles = [S.resize(frame_at(look, light, t, base_name)[cy:cy + ch, cx:cx + cw], sw, sh) for t in times]
    return S.grid(tiles, n_cols, gap=GAP)


def beside(left, right):
    h = max(left.shape[0], right.shape[0])
    pad = lambda img: np.concatenate(  # noqa: E731
        [img, np.full((h - img.shape[0], img.shape[1], 3), GREY, np.float32)]) if img.shape[0] < h else img
    return np.concatenate([pad(left), np.full((h, GAP * 2, 3), GREY, np.float32), pad(right)], axis=1)


def close(target, rows, light, t, crop, base_target, base_rows, t_rows=None):
    cx, cy, cw, ch = crop
    w = (WIDTH - GAP * 2) // 2
    h = round(w * ch / cw)
    a = S.resize(frame_at(target, light, t, base_target)[cy:cy + ch, cx:cx + cw], w, h)
    b = S.resize(frame_at(rows, light, t if t_rows is None else t_rows, base_rows)[cy:cy + ch, cx:cx + cw], w, h)
    return beside(a, b)


def burn():
    crop = crop_of("burn_a")
    times = S.times_of(S.WORK / "r_burn_a_day")
    peak = 0.16
    parts = [S.caption(close("burn_a", "burn_rows", "day", peak, crop, "base_day_win.png", "base_day_win.png"),
                       f"AR69 burn A at {peak:.2f} s, by day: the target (left), {SOURCE} (right). {NOTE}", 24)]
    parts.append(S.caption(close("burn_a", "burn_rows", "night", peak, crop, "base_night_win.png", "base_night_win.png"),
                           "the same at night: the target (left), the rows (right)"))
    for light in ("day", "night"):
        parts.append(S.caption(strip("burn_a", light, times, crop, f"base_{light}_win.png", len(times)),
                               f"the target's life, {light}: " + ", ".join(f"{t:.2f}" for t in times) + " s"))
        parts.append(S.caption(strip("burn_rows", light, times, crop, f"base_{light}_win.png", len(times)),
                               f"the rows' life, {light}, the same times: each tongue on its own beat"))
    for look, who in (("burn_a", "the target"), ("burn_rows", "the rows")):
        heads = []
        for deg, name in S.HEADINGS:
            fx = S.read_exr(S.WORK / f"r_{look}_h{deg}" / f"fx_{peak:.3f}.exr", (600, 600))
            heads.append(S.caption(S.at64(S.on_dark(fx), 4), name, 22))
        parts.append(S.caption(S.grid(heads, len(heads), gap=GAP),
                               f"{who} from every side at {peak:.2f} s, 64 px over dark (shown x4): every tongue's tip up"))
    return S.stack(parts, WIDTH)


def fall():
    crop = crop_of("fall_a")
    times = S.times_of(S.WORK / "r_fall_a_day")
    pre = S.times_of(S.WORK / "r_burn_fall_rows_day")
    parts = [S.caption(close("fall_a", "fall_rows", "day", 0.1, crop, "base_fall_day_win.png", "base_fall_day_win.png"),
                       f"AR69 fall A at 0.10 s, by day: the target (left), {SOURCE} (right). {NOTE}", 24)]
    parts.append(S.caption(close("fall_a", "fall_rows", "night", 0.22, crop, "base_fall_night_win.png",
                                 "base_fall_night_win.png"), "at 0.22 s, at night: the target (left), the rows (right)"))
    # before the body goes: the rows' ball swells round the foe, who hides 4 frames after the play
    cx, cy, cw, ch = crop
    w = (WIDTH - GAP * 5) // 4
    h = round(w * ch / cw)
    tiles = []
    for light in ("day", "night"):
        for t in pre:
            tiles.append(S.resize(frame_at("burn_fall_rows", light, t, f"base_{light}_win.png")[cy:cy + ch, cx:cx + cw],
                                  w, h))
    parts.append(S.caption(S.grid(tiles, 4, gap=GAP), "the rows before the body goes ("
                           + ", ".join(f"{t:.3f}" for t in pre) + " s; day, then night): the ball blooms round the "
                           "body, the body inside it, never beside"))
    for light in ("day", "night"):
        parts.append(S.caption(strip("fall_a", light, times, crop, f"base_fall_{light}_win.png", len(times)),
                               f"the target's life, {light}: " + ", ".join(f"{t:.2f}" for t in times) + " s"))
        parts.append(S.caption(strip("fall_rows", light, times, crop, f"base_fall_{light}_win.png", len(times)),
                               f"the rows' life, {light}, the same times"))
    return S.stack(parts, WIDTH)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in (("burn", burn), ("fall", fall)):
        path = OUT / f"ar69_checkpoint_{name}.png"
        S.write_png(make(), path)
        print("wrote", path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
