"""AR76's target sheets: Rook's Haymaker, its look overhauled, laid on Studio plates of Lantern Row at the game's camera.

    py tools/fx/ar76_sheets.py <hay_a|hay_b> [peak frame, 58]

Reads build/scratch/scintilla/ar76/r_<look>_{day,night}/fx_<frame>.exr and light_<frame>.exr (ar76_targets.py) and the
plates plates_{day,night}/plate_<frame>.png (the maximized Studio, frozen on the Haymaker's clip). Writes
build/handoff/Rook/fx/ar76/<look>_sheet.png: the peak, the whole frame, by day and at night; the hold (frame 36), the
whole frame; the strip of its life, close, by day and at night; and at 64 px over dark. Plus <look>_peak_{day,night}.png.
The helpers are AR69's (ar69_sheets)."""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar69_sheets as S  # noqa: E402

WORK = S.ROOT / "build" / "scratch" / "scintilla" / "ar76"
OUT = S.ROOT / "build" / "handoff" / "Rook" / "fx" / "ar76"
CROP = (700, 60, 1100, 840)  # x, y, w, h in the viewport: the foe, Rook and the fire's reach
BEATS = {20: "Charge", 36: "the mass formed", 52: "hold", 55: "Drop", 57: "Strike", 58: "Shock", 61: "", 66: "Step",
         75: "Vent", 90: "gone"}
NAMES = {"hay_a": "A, the ball", "hay_b": "B, the ram's square"}


def frames_of(folder: Path):
    return sorted(int(p.stem.split("_")[1]) for p in folder.glob("fx_*.exr"))


def main() -> int:
    look = sys.argv[1]
    peak = int(sys.argv[2]) if len(sys.argv) > 2 else 58
    cx, cy, cw, ch = CROP
    runs = {}
    for light_name in ("day", "night"):
        folder = WORK / f"r_{look}_{light_name}"
        full, darks = {}, {}
        for t in frames_of(folder):
            frame = S.base(str((WORK / f"plates_{light_name}" / f"plate_{t}.png").resolve()))
            fx = S.read_exr(folder / f"fx_{t}.exr")
            full[t] = S.lay(frame, fx, S.read_exr(folder / f"light_{t}.exr"))
            darks[t] = S.on_dark(fx)
        runs[light_name] = (full, darks)
    frames = sorted(runs["day"][0])
    width = 2500
    gap = np.full((566, 20, 3), 0.16, np.float32)
    parts = []
    for t, what in ((peak, "the peak"), (36, "the hold")):
        halves = [S.resize(runs[n][0][t], 1240, 566) for n in ("day", "night")]
        parts.append(S.caption(np.concatenate([halves[0], gap, halves[1]], axis=1),
                               f"AR76 {NAMES[look]}: {what} (frame {t} at 60 fps), the whole frame at the player's "
                               "camera; day, night"))
    n = len(frames)
    sw = (width - 10 * (n + 1)) // n
    sh = round(sw * ch / cw)
    for light_name in ("day", "night"):
        tiles = [S.resize(runs[light_name][0][t][cy:cy + ch, cx:cx + cw], sw, sh) for t in frames]
        parts.append(S.caption(S.grid(tiles, n, gap=10), f"its life, {light_name}, frames "
                               + ", ".join(f"{t}{' ' + BEATS[t] if BEATS.get(t) else ''}" for t in frames)))
    smalls = [S.at64(runs["day"][1][t][cy:cy + ch, cx:cx + cw], 3) for t in frames]
    parts.append(S.caption(S.grid(smalls, n, gap=10), "at 64 px over dark (shown x3), the same frames"))
    sheet = S.stack(parts, max(width, max(x.shape[1] for x in parts)))
    OUT.mkdir(parents=True, exist_ok=True)
    S.write_png(sheet, OUT / f"{look}_sheet.png")
    for light_name in ("day", "night"):
        S.write_png(runs[light_name][0][peak], OUT / f"{look}_peak_{light_name}.png")
    print("sheet", look, "peak", peak, "frames", frames)
    return 0


if __name__ == "__main__":
    sys.exit(main())
