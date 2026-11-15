"""AR12, delivery 3: the galaxy Breaker's motion test (the director, 2026-11-15: "even animated if possible"). Plain
numpy and ffmpeg, no Blender: run it with any python that has numpy (Blender's own does).

It takes the screen drawn twice by screens_vivid_sheet.py's `motion` mode, over a black sky and over a white one, works
out from the pair what covers the sky and by how much, and lays the moving sky under it, frame by frame:

    python void_breaker_motion.py <folder with screen_black.npy and screen_white.npy> <out.mp4> [seconds]

What moves, and nothing else (research's measures, 2026-11-15: darker and stiller than the reveal; no moving light
behind a number; no layer turning faster than once in about 20 s; all of it stops with reduced motion on):

    a thin mist of the sky's colours drifts along the chambers' row, void_sky.BREAKER["drift"] points a second;
    the large stars breathe, each on its own clock;
    a working shard's light breathes, once in BREATH seconds;
    one falling star crosses a window, at FALL seconds.

The clip on one page, a frame a second from 0.75 s (so the fourth holds the falling star), for a check that can't play it:

    ffmpeg -ss 0.75 -i vivid3_breaker_motion.mp4 -vf "fps=1,scale=812:-1,tile=2x5" -frames:v 1 vivid3_breaker_motion_frames.png
"""
import math
import subprocess
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import void_sky as vs  # noqa: E402

K, FPS = 2, 30
BREATH, SWELL = 2.6, 0.07  # a shard's light: seconds a breath, and how far it swells
FALL, FALLS = 3.4, 0.7  # the falling star: when it starts, how long it lasts
LAVENDER = "#DCCBFF"


def main():
    folder, out = Path(sys.argv[1]), Path(sys.argv[2])
    seconds = float(sys.argv[3]) if len(sys.argv) > 3 else 10.0
    black = np.load(folder / "screen_black.npy").astype(np.float32) / 255
    white = np.load(folder / "screen_white.npy").astype(np.float32) / 255
    rows, cols = black.shape[:2]
    px, py, pw, ph = (round(v * K) for v in vs.PANEL)
    look = vs.BREAKER
    clear = np.clip((white - black).mean(axis=-1), 0, 1)[py:py + ph, px:px + pw, None]  # how much of the sky shows
    base = vs.ground(ph, pw, K, look)
    y, x = np.mgrid[0:rows, 0:cols].astype(np.float32)
    breath = np.zeros((rows, cols), np.float32)
    for sx, sy in look["shards"]:
        breath += np.exp(-(((x + 0.5) / K - vs.PANEL[0] - sx) ** 2 + ((y + 0.5) / K - vs.PANEL[1] - sy) ** 2) / (2 * 17.0 ** 2))
    breath = breath[..., None] * vs.rgb(LAVENDER)
    pipe = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{cols}x{rows}",
                             "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-crf", "17", "-pix_fmt", "yuv420p", str(out)],
                            stdin=subprocess.PIPE)
    for i in range(round(seconds * FPS)):
        t = i / FPS
        sky = vs.sky(K, t, base)
        if FALL <= t <= FALL + FALLS:
            vs.lay(sky, vs.streak(ph, pw, K, *look["streak"], (t - FALL) / FALLS))
        frame = black.copy()
        frame[py:py + ph, px:px + pw] += sky * clear
        frame += breath * (SWELL * math.sin(2 * math.pi * t / BREATH))
        pipe.stdin.write((np.clip(frame, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes())
        if i % FPS == 0:
            print(f"{t:.0f} s", flush=True)
    pipe.stdin.close()
    pipe.wait()
    print("wrote", out)


if __name__ == "__main__":
    main()
