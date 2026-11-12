"""One call from a tools/capture/grab.ps1 take to one sheet at most 2000 px wide: one
row a moment, one column a time, one decode of the take, no Blender. For a working read. It doesn't replace the strip row or the
full-size crop a final needs.

Run from the project root:
  py tools/capture/moments.py <take.mkv> <out.jpg> --work <folder> --at 2.65,5.88 --span -0.05,0.9,0.05
  py tools/capture/moments.py <take.mkv> <out.jpg> --work <folder> --stamped --span 0.3,0.6,1/60 --takes 2,7 --crop 1200:840:461:458

The moments, one of:
  --at       seconds of the take
  --stamped  each stamped action's zero, read by tools/capture/stamps.py from the row at --stamp-at; --states picks the states
             (default 1), --takes the stamp's take numbers
--span from,to,step  the times of a row, in seconds from its moment; a step may be written 1/60
--times a,b,c        or the times themselves
--crop w:h:x:y       of the window's pixels; the default is VIEW below
--cols n             to wrap a row; the default is one column a time
--gamma g            to lift a dark take; 1 leaves it as it is
--width n            the sheet's most width, 2000

Each tile is the picture nearest its time, within half a step, and a time with no picture is a black tile, never filled. The tiles
carry no text, since this ffmpeg's drawtext crashes: <out>.tsv lists each tile's moment, its time and the picture's real time. The
game's own label, when a take has one, is in the picture. --work names a folder of its own for this run; it is wiped at the start.
"""

import argparse
import bisect
import os
import shutil
import subprocess
import sys
from fractions import Fraction

GAP = 3
# Measure both for your window: one 2560x1494 Studio window at 150% scale.
VIEW = "2042:1240:40:218"  # the game view inside the window, w:h:x:y: this PC's Studio, measured 2026-11-12
STAMP_AT = "928,278"  # where the stamp row starts
DECODE_TERMS = 60


def ff(*args):
    subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "error", "-y", *args], check=True)


def seconds(text):
    return float(Fraction(text)) if "/" in text else float(text)


def numbers(text):
    return [seconds(each) for each in text.split(",")]


def picture_times(take):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "packet=pts_time", "-of", "csv=p=0", take],
                         capture_output=True, text=True, check=True).stdout.split()
    return sorted(float(each.strip(",")) for each in out)


def stamped(take, where, at, states, takes):
    path = f"{where}/stamps.tsv"
    subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "stamps.py"), take, "--at", at, "--out", path], check=True, capture_output=True)
    zeros = []
    for line in open(path, encoding="utf-8"):
        cells = line.rstrip("\r\n").split("\t")
        if cells[0] == "take":
            continue
        if int(cells[1]) in states and (not takes or int(cells[0]) in takes):
            zeros.append(float(cells[7]))
    return sorted(zeros)


def offsets(args):
    if args.times:
        return numbers(args.times)
    first, last, step = [each for each in args.span.split(",")]
    first, last, step = seconds(first), seconds(last), seconds(step)
    count = int(round((last - first) / step)) + 1
    return [first + i * step for i in range(count)]


def nearest(times, want, reach):
    i = bisect.bisect_left(times, want)
    near = [times[j] for j in (i - 1, i) if 0 <= j < len(times)]
    best = min(near, key=lambda t: abs(t - want))
    return best if abs(best - want) <= reach else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("take")
    parser.add_argument("out")
    parser.add_argument("--work", required=True, help="a folder for this run alone: wiped at the start")
    parser.add_argument("--at")
    parser.add_argument("--stamped", action="store_true")
    parser.add_argument("--stamp-at", default=STAMP_AT)
    parser.add_argument("--states", default="1")
    parser.add_argument("--takes", default="")
    parser.add_argument("--span")
    parser.add_argument("--times")
    parser.add_argument("--crop", default=VIEW)
    parser.add_argument("--cols", type=int)
    parser.add_argument("--gamma", type=float, default=1)
    parser.add_argument("--width", type=int, default=2000)
    args = parser.parse_args()
    if bool(args.at) == args.stamped or bool(args.span) == bool(args.times):
        parser.error("give one of --at and --stamped, and one of --span and --times")

    where = args.work
    raw = f"{where}/raw"
    shutil.rmtree(where, ignore_errors=True)
    os.makedirs(raw)

    states = [int(each) for each in args.states.split(",")]
    takes = [int(each) for each in args.takes.split(",")] if args.takes else []
    moments = numbers(args.at) if args.at else stamped(args.take, where, args.stamp_at, states, takes)
    if not moments:
        raise SystemExit("no moments found")
    times = picture_times(args.take)
    row = offsets(args)
    spacing = min((b - a for a, b in zip(row, row[1:])), default=1 / 60)
    reach = max(spacing / 2, 1 / 120)

    tiles = [(m, o, nearest(times, moment + o, reach)) for m, moment in enumerate(moments) for o in row]
    wanted = {t for _, _, t in tiles if t is not None}
    if not wanted:
        raise SystemExit("no pictures at those times")
    # A grab can hold two pictures with one time; the decode writes both, so they're counted here, and the later one is the tile.
    chosen = [t for t in times if t in wanted]

    # The wanted pictures in decodes of at most DECODE_TERMS times, then each picture's file by its place among them, and any count that disagrees stops.
    # One select of 106 times failed in ffmpeg ("Cannot allocate memory") where 85 had passed. Times closer than a pair a picture could match stay together.
    scale = (args.width - GAP * ((args.cols or len(row)) - 1)) // (args.cols or len(row))
    decodes = []
    for t in sorted(wanted):
        if decodes and (len(decodes[-1]) < DECODE_TERMS or t - decodes[-1][-1] < 0.005):
            decodes[-1].append(t)
        else:
            decodes.append([t])
    for part in decodes:
        ranges = "+".join(f"between(t,{t - 0.002:.6f},{t + 0.002:.6f})" for t in part)
        script = f"select='{ranges}',crop={args.crop},eq=gamma={args.gamma},scale={scale}:-2"
        # Only the stretch that holds them is decoded, with the take's own clock kept, so a sheet from a long take costs what a short one does.
        first, last = max(part[0] - 0.5, 0), part[-1] + 0.5
        ff("-ss", f"{first:.3f}", "-t", f"{last - first:.3f}", "-copyts", "-i", args.take, "-filter_threads", "1", "-vf", script, "-fps_mode", "passthrough", "-q:v", "2", "-start_number", str(len(os.listdir(raw))), f"{raw}/%05d.jpg")
    written = sorted(os.listdir(raw))
    if len(written) != len(chosen):
        raise SystemExit(f"wrote {len(written)} pictures for {len(chosen)} times")
    by_time = dict(zip(chosen, written))

    size = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=p=0", f"{raw}/{written[0]}"],
                          capture_output=True, text=True, check=True).stdout.strip().split(",")
    w, h = int(size[0]), int(size[1])
    black = f"{where}/black.jpg"
    ff("-f", "lavfi", "-i", f"color=c=black:s={w}x{h}", "-frames:v", "1", black)

    cols = args.cols or len(row)
    inputs, layout, listing, missing = [], [], ["moment\tseconds\tfrom_moment\tpicture"], 0
    for i, (m, offset, t) in enumerate(tiles):
        inputs += ["-i", black if t is None else f"{raw}/{by_time[t]}"]
        layout.append(f"{(i % cols) * (w + GAP)}_{(i // cols) * (h + GAP)}")
        missing += t is None
        listing.append(f"{m + 1}\t{moments[m]:.3f}\t{offset:+.3f}\t{'-' if t is None else format(t, '.3f')}")
    ff(*inputs, "-filter_complex", f"xstack=inputs={len(tiles)}:layout={'|'.join(layout)}:fill=0x101014", "-frames:v", "1", "-q:v", "3", args.out)
    with open(os.path.splitext(args.out)[0] + ".tsv", "w", encoding="utf-8") as out:
        out.write("\n".join(listing) + "\n")
    shutil.rmtree(where)
    print(f"NL_MOMENTS {args.out}: {len(moments)} moments, {len(row)} times, {cols} columns, tile {w} x {h}, {missing} with no picture")


main()
