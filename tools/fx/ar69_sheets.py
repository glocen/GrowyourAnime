"""AR69's target sheets (Scintilla, 2026-11-27): lays tools/blender/ar69_targets.py's renders on the game's own frames.

    py tools/fx/ar69_sheets.py <look> [times]

<look> is fall_a, fall_b, burn_a or burn_b. Reads build/scratch/scintilla/ar69/: the frames taken in Studio at the
pose (base_day_win.png and base_night_win.png with the foe, base_fall_*_win.png without it), the renders in
r_<look>_<day|night>/ (and r_<look>_h<deg>/ for the burn's headings), and writes the sheets to
build/handoff/ShadeFire/targets/.

How a frame is laid on (a model of the engine, as paintover.py's): the frame back to linear light; the light the effect
throws (its render on white bodies) multiplied into it; the effect's own layers alpha-blended over, their light added;
a bloom from what passes 1; the same soft clip toward white.
"""
from __future__ import annotations

import json
import math
import subprocess
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import BLOOM, KNEE, blur, linear_to_srgb, read_png, srgb_to_linear, write_png  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build" / "scratch" / "scintilla" / "ar69"
OUT = ROOT / "build" / "handoff" / "ShadeFire" / "targets"
VIEW = (40, 217, 2483, 1134)  # the game's viewport in a capture of the maximized Studio: x, y, w, h
LIGHT = 0.9  # how much of the effect's light on a white body comes onto the frame's colour
UNSCALE = 8.0  # the renders hold their light at an eighth (ar69_targets.SCALE): ffmpeg clips an EXR at 1
DARK = (0.012, 0.012, 0.016)  # linear: the plain dark the 64 px reads sit on


def read_exr(path: Path, size=(2483, 1134)) -> np.ndarray:
    w, h = size
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "gbrapf32le", "-"],
                         capture_output=True, check=True).stdout
    planes = np.frombuffer(raw, np.float32).reshape(4, h, w)
    g, b, r, a = planes
    return np.stack([r * UNSCALE, g * UNSCALE, b * UNSCALE, a], axis=-1)


def base(name: str) -> np.ndarray:
    x, y, w, h = VIEW
    img = read_png(WORK / name, (2560, 1494))
    return srgb_to_linear(img[y:y + h, x:x + w])


def finish(lin: np.ndarray, hot_from: np.ndarray) -> np.ndarray:
    h = lin.shape[0]
    hot = np.clip(hot_from - 0.85, 0, None)
    for sigma, k in BLOOM:
        lin = lin + blur(hot, sigma * h) * k
    over = np.clip(lin - KNEE, 0, None)
    lin = np.where(lin > KNEE, KNEE + (1 - KNEE) * (1 - np.exp(-over / (1 - KNEE))), lin)
    peak = lin.max(axis=2, keepdims=True)
    spill = np.clip((peak - 0.97) / 0.03, 0, 1) * np.clip(hot_from.max(axis=2, keepdims=True) - 1.4, 0, 1)
    lin = lin + (1 - lin) * spill * 0.85
    return linear_to_srgb(lin)


def lay(frame_lin: np.ndarray, fx: np.ndarray, light: np.ndarray | None) -> np.ndarray:
    lin = frame_lin
    if light is not None:
        lin = lin * (1 + LIGHT * light[..., :3])
    a = fx[..., 3:4]
    lin = lin * (1 - a) + fx[..., :3]
    return finish(lin, fx[..., :3])


def on_dark(fx: np.ndarray) -> np.ndarray:
    lin = np.ones(fx.shape[:2] + (3,), np.float32) * np.array(DARK, np.float32)
    a = fx[..., 3:4]
    return finish(lin * (1 - a) + fx[..., :3], fx[..., :3])


def grid(tiles, cols, gap=8, grey=0.16):
    h, w, _ = tiles[0].shape
    rows = math.ceil(len(tiles) / cols)
    sheet = np.full((rows * h + (rows + 1) * gap, cols * w + (cols + 1) * gap, 3), grey, np.float32)
    for i, t in enumerate(tiles):
        r, c = divmod(i, cols)
        y, x = gap + r * (h + gap), gap + c * (w + gap)
        sheet[y:y + h, x:x + w] = t
    return sheet


def resize(img: np.ndarray, w: int, h: int, flags="area") -> np.ndarray:
    ih, iw, _ = img.shape
    data = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    raw = subprocess.run(["ffmpeg", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{iw}x{ih}", "-i", "-",
                          "-vf", f"scale={w}:{h}:flags={flags}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         input=data, capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(h, w, 3).astype(np.float32) / 255


def at64(img: np.ndarray, show=4) -> np.ndarray:
    """The crop brought to 64 px high and shown `show` times bigger, pixel for pixel."""
    h, w, _ = img.shape
    small_w = max(2, round(w * 64 / h))
    small = resize(img, small_w, 64)
    return resize(small, small_w * show, 64 * show, "neighbor")


def caption(img: np.ndarray, text: str, size=30) -> np.ndarray:
    """img with a caption bar on top."""
    h, w, _ = img.shape
    bar = 56
    data = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    note = WORK / "caption.txt"  # the words by file: no escaping inside the filter
    note.write_text(text, encoding="utf-8")
    font = r"C\:/Windows/Fonts/segoeui.ttf"
    words = note.as_posix().replace(":", r"\:")
    vf = (f"pad=iw:ih+{bar}:0:{bar}:color=0x26262b,drawtext=fontfile='{font}':textfile='{words}':x=16:y=14:"
          f"fontsize={size}:fontcolor=white")
    raw = subprocess.run(["ffmpeg", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{w}x{h}", "-i", "-",
                          "-vf", vf, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], input=data, capture_output=True,
                         check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(h + bar, w, 3).astype(np.float32) / 255


def stack(parts, width, grey=0.16, gap=10):
    rows = []
    for part in parts:
        h, w, _ = part.shape
        if w < width:
            part = np.concatenate([part, np.full((h, width - w, 3), grey, np.float32)], axis=1)
        rows.append(part)
        rows.append(np.full((gap, width, 3), grey, np.float32))
    return np.concatenate(rows, axis=0)


def times_of(folder: Path):
    return sorted(float(p.stem[3:]) for p in folder.glob("fx_*.exr"))


TODAY = {"fall": "today_fall_night_3.7.png", "burn": "today_burn_night.png"}
HEADINGS = ((0, "the game's side"), (90, "front"), (135, "three-quarter"), (180, "the other side"), (270, "back"))


def main() -> int:
    look = sys.argv[1]
    peak = float(sys.argv[2]) if len(sys.argv) > 2 else None
    crop = json.loads((WORK / "crops.json").read_text())[look]  # x, y, w, h in the viewport
    cx, cy, cw, ch = crop
    fall = look.startswith("fall")
    runs = {}
    for light_name in ("day", "night"):
        folder = WORK / f"r_{look}_{light_name}"
        frame = base(f"base_fall_{light_name}_win.png" if fall else f"base_{light_name}_win.png")
        full, darks = {}, {}
        for t in times_of(folder):
            fx = read_exr(folder / f"fx_{t:.3f}.exr")
            full[t] = lay(frame, fx, read_exr(folder / f"light_{t:.3f}.exr"))
            darks[t] = on_dark(fx)
        runs[light_name] = (full, darks)
    times = sorted(runs["day"][0])
    p = peak if peak is not None else times[len(times) // 3]
    width = 2500
    parts = []
    # the whole frame at the peak, day and night
    halves = [resize(runs[n][0][p], 1240, 566) for n in ("day", "night")]
    parts.append(caption(np.concatenate([halves[0], np.full((566, 20, 3), 0.16, np.float32), halves[1]], axis=1),
                         f"AR69 {look}: the peak ({p:.2f} s), the whole frame at the player's camera; day, night"))
    # today beside the target, close
    today = srgb_to_linear(read_png(WORK / TODAY["fall" if fall else "burn"], (2483, 1134)))
    tw = 820
    th = round(tw * ch / cw)
    close = [resize(linear_to_srgb(today)[cy:cy + ch, cx:cx + cw], tw, th)]
    close += [resize(runs[n][0][p][cy:cy + ch, cx:cx + cw], tw, th) for n in ("day", "night")]
    row = np.concatenate([close[0], np.full((th, 10, 3), 0.16, np.float32), close[1],
                          np.full((th, 10, 3), 0.16, np.float32), close[2]], axis=1)
    parts.append(caption(row, "close: today's at night (the same camera; the foe stood a little apart), the target by "
                              "day, the target at night"))
    # the strip, day then night
    n = len(times)
    sw = (width - 10 * (n + 1)) // n
    sh = round(sw * ch / cw)
    for light_name in ("day", "night"):
        tiles = [resize(runs[light_name][0][t][cy:cy + ch, cx:cx + cw], sw, sh) for t in times]
        parts.append(caption(grid(tiles, n, gap=10), f"its life, {light_name}: " + ", ".join(f"{t:.2f}" for t in times)
                             + " s"))
    # at 64 px over dark
    smalls = [at64(runs["day"][1][t][cy:cy + ch, cx:cx + cw], 3) for t in times]
    parts.append(caption(grid(smalls, n, gap=10), "at 64 px over dark (shown x3), the same times"))
    if not fall:
        heads = []
        for deg, name in HEADINGS:
            folder = WORK / f"r_{look}_h{deg}"
            fx = read_exr(folder / f"fx_{p:.3f}.exr", (600, 600))
            img = on_dark(fx)
            heads.append(caption(at64(img, 4), name, 22))
        parts.append(caption(grid(heads, len(heads), gap=10), "from every side at 64 px over dark (shown x4), the foe in "
                                                              "grey"))
    sheet = stack(parts, max(width, max(x.shape[1] for x in parts)))
    OUT.mkdir(parents=True, exist_ok=True)
    write_png(sheet, OUT / f"{look}_sheet.png")
    for light_name in ("day", "night"):
        write_png(runs[light_name][0][p], OUT / f"{look}_peak_{light_name}.png")
    print("sheet", look, "peak", p, "times", times)
    return 0


if __name__ == "__main__":
    sys.exit(main())
