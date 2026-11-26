"""TR70 B: the frames of the takes of tools/fx/reveal_capture.lua (Scintilla's). Finds each step by the marker the script
stamps at the viewport's top left, takes the middle frame of each, and writes what reveal_targets.py reads:
- figures/world.png, the screen the void closes over;
- figures/<Model>_<clip time>.png, each figure's matte: the same frame over black and over white, alpha = 1 - (white -
  black), its colour the black frame unpremultiplied;
- today/<Model>_<stage time>.png, today's stage at each time of the strip.

    py tools/fx/reveal_frames.py <take>.mkv [<take>.mkv ...] [--out <dir>]   (default build/handoff/Reveal/new_stage)

A step missing from one take may come from another (a rerun numbered on from where the first ended). The takes are
the Studio window from tools/capture/grab.ps1 -Lossless; the game's viewport sits at VIEW inside it.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Reveal" / "new_stage"
VIEW = (2042, 1134, 40, 218)  # w, h, x, y of the viewport in the Studio window's take (the stage stills' crop)
MATTES = [("Lyric", [1.4, 1.5, 1.6, 1.75, 2.0, 2.25, 2.6, 2.95]), ("Rook", [0.85, 1.2, 1.6])]  # reveal_capture.lua's
TODAY = [("Lyric", [0.15, 0.35, 0.75, 0.87, 0.95, 1.1, 1.6, 2.4]), ("Rook", [0.1, 0.3, 0.55, 0.7, 1.1, 1.62])]


def steps():
    """What each step of the script shows, in its order: ("world",), ("matte", model, t, bg) or ("today", model, t)."""
    out = [("world",)]
    for model, times in MATTES:
        for t in times:
            out += [("matte", model, t, "black"), ("matte", model, t, "white")]
    for model, times in TODAY:
        out += [("today", model, t) for t in times]
    return out


def markers(take):
    w, h, x, y = VIEW
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(take), "-vf", f"crop=8:8:{x + 2}:{y + 2}", "-fps_mode",
                          "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    px = np.frombuffer(raw, np.uint8).reshape(-1, 8, 8, 3).astype(np.float32).mean(axis=(1, 2))
    on = (px[:, 0] > 200)
    return np.where(on, np.round((px[:, 1] - 16) / 32) + 8 * np.round((px[:, 2] - 16) / 48), -1).astype(int)


def runs(step, found, take):
    """Each step's longest run in this take (at least 10 frames), kept where it beats the one already found."""
    n = len(step)
    i = 0
    while i < n:
        j = i
        while j < n and step[j] == step[i]:
            j += 1
        s = step[i]
        if s >= 1 and j - i >= 10 and (s not in found or j - i > found[s][2] - found[s][1]):
            found[s] = (take, i, j)
        i = j


def grab(take, frames, folder, tag):
    """The frames, by number, cropped to the viewport, as PNGs."""
    w, h, x, y = VIEW
    folder.mkdir(parents=True, exist_ok=True)
    pick = "+".join(f"eq(n\\,{f})" for f in sorted(frames))
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(take), "-vf", f"select='{pick}',crop={w}:{h}:{x}:{y}",
                    "-fps_mode", "passthrough", str(folder / f"{tag}_%03d.png")], check=True)
    return {(take, f): folder / f"{tag}_{k + 1:03d}.png" for k, f in enumerate(sorted(frames))}


def read(path):
    w, h = VIEW[:2]
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(h, w, 3).astype(np.float32) / 255


def write(img, path, alpha=None):
    h, w, _ = img.shape
    if alpha is not None:
        img = np.concatenate([img, alpha[..., None]], axis=2)
    fmt = "rgba" if alpha is not None else "rgb24"
    data = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", fmt, "-s", f"{w}x{h}", "-i", "-",
                    str(path)], input=data, check=True)


def main(argv):
    out = OUT
    if "--out" in argv:
        k = argv.index("--out")
        out = Path(argv[k + 1])
        argv = argv[:k] + argv[k + 2:]
    takes = [Path(a) for a in argv]
    plan = steps()
    found = {}
    for take in takes:
        runs(markers(take), found, take)
    missing = [s for s in range(1, len(plan) + 1) if s not in found]
    if missing:
        raise SystemExit(f"steps not found in the takes: {missing}")
    at = {s: (found[s][0], (found[s][1] + found[s][2]) // 2) for s in range(1, len(plan) + 1)}
    files = {}
    for n, take in enumerate(takes):
        frames = {f for (t, f) in at.values() if t == take}
        if frames:
            files.update(grab(take, frames, out / "frames", f"t{n}"))
    blacks = {}
    for s, what in enumerate(plan, start=1):
        img = read(files[at[s]])
        if what[0] == "world":
            write(img, out / "figures" / "world.png")
        elif what[0] == "today":
            write(img, out / "today" / f"{what[1]}_{what[2]:.2f}.png")
        elif what[3] == "black":
            blacks[(what[1], what[2])] = img
        else:
            black = blacks.pop((what[1], what[2]))
            alpha = np.clip(1 - (img - black).mean(axis=2), 0, 1)
            colour = black / np.maximum(alpha[..., None], 1e-3)
            h, w = alpha.shape
            alpha[: int(0.12 * h), : int(0.14 * w)] = 0  # the marker and Roblox's menu buttons
            alpha[:, int(0.84 * w):] = 0  # the player's chip at the top right (the figure stands in the middle)
            write(colour, out / "figures" / f"{what[1]}_{what[2]:.2f}.png", alpha)
        print(s, what, at[s][0].name, "frame", at[s][1])
    for f in files.values():
        f.unlink()
    (out / "frames").rmdir()


if __name__ == "__main__":
    main(sys.argv[1:])
