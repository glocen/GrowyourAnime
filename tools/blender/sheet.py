"""Tiles PNGs into one numbered contact sheet over a dark checker, so white-on-alpha art can be judged by eye (each tile
keeps its aspect, the checker shows its transparency, the number in its corner is its place in the list).

Run: blender.exe -b --factory-startup --python tools/blender/sheet.py -- <out.png> <tile size> <image.png> [...]

The strip row lays a fast moment out for the evidence pack, one track for ours and
one for each reference beside it, on one time axis:
  - the strip: a tile for every frame at its place on the grid, stamped with its time; a beat's name on the tile it
    starts in, a band in the beat's colour under the tile; a `=` on a tile that repeats the picture before it, so a
    take's real rate shows;
  - the onion: the moving parts of every Nth frame over what stays, the first cool and faint, the last warm and solid;
  - the 64 px row: the same crop at 64 px, area-averaged, the read at play distance (a crop round the subject: a whole
    frame at 64 px leaves the body a few pixels tall).

Run: blender.exe -b --factory-startup --python tools/blender/sheet.py -- strip <out.png>
         [--title TEXT] [--step 1/60] [--tile 150] [--cols 12]
         --track <name> [--rate 60] [--start 0] [--crop x,y,w,h] [--beats Dip=0,Slip=0.08] [--onion 3] [--same 0.02]
         <frame> [...] [--track <name> ...]
--step is the sheet's grid and --tile its width: a track's tiles are as wide as its own --rate's frames last, so a
30 fps reference's tiles span two columns of a 1/60 s grid. --start is the game time of a track's first frame, and
aligns the tracks (--start=-0.1 for a negative one). --onion 0 leaves a track's onion out: it reads a still ground, or a
camera that keeps the body in place, and a follow camera over a busy ground leaves only a blur. --same is how far apart
two pictures may be and still repeat: raise it for footage with noise of its own (0.25 for phone footage;
`NL_STRIP` prints the times it flags, so check them). A frame named `-` is a step with no frame: drawn and reported as
missing, never filled. Paths may be relative to the folder Blender runs from. No GPU and no render, so
build/locks/blender.lock isn't needed.
"""

import argparse
import math
import os
import sys

import bpy
import numpy as np

# 3x5 glyphs, row by row (1 = ink).
GLYPHS = {
    "0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
    "4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001010010010",
    "8": "111101111101111", "9": "111101111001111",
    "A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
    "E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
    "I": "111010010010111", "J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
    "M": "101111111101101", "N": "110101101101101", "O": "010101101101010", "P": "110101110100100",
    "Q": "010101101111011", "R": "110101110101101", "S": "011100010001110", "T": "111010010010010",
    "U": "101101101101111", "V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
    "Y": "101101010010010", "Z": "111001010100111",
    ".": "000000000000010", "-": "000000111000000", "+": "000010111010000", "=": "000111000111000",
    ":": "000010000010000", "/": "001001010100100", ",": "000000000010100", "'": "010010000000000",
    " ": "000000000000000",
}
INK = (1.0, 0.85, 0.3)
NAME_COLOUR = (0.8, 0.8, 0.8)
BEAT_COLOURS = ((1.0, 0.85, 0.3), (0.35, 0.8, 1.0), (0.75, 0.55, 1.0), (0.45, 0.9, 0.55))
SHEET_GROUND = 0.07
NO_FRAME_GROUND = 0.035  # a step this track's rate has no frame for
ONION_FIRST, ONION_LAST = np.array((0.3, 0.75, 1.0)), np.array((1.0, 0.75, 0.25))
ONION_MOVED = (0.05, 0.15)  # how far a pixel strays from what stays, from nothing to all of it
GUTTER = 14  # the column left of the grid that holds a track's name
SMALL = 64  # the read at play distance, pixels tall
VIEW_LIMIT = 2000  # a sheet's long side past this is shrunk when it's viewed, so its 64 px row is no longer 64 px
MISSING = "-"


def load(path):
    image = bpy.data.images.load(path)
    width, height = image.size
    data = np.empty(width * height * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape(height, width, 4)[::-1]  # row 0 = the top


def fit(rgba, size):
    """Nearest-neighbour scale into a size x size box, keeping the aspect (letterboxed, transparent)."""
    h, w = rgba.shape[:2]
    scale = size / max(h, w)
    nh, nw = max(1, int(h * scale)), max(1, int(w * scale))
    ys = np.minimum((np.arange(nh) / scale).astype(int), h - 1)
    xs = np.minimum((np.arange(nw) / scale).astype(int), w - 1)
    out = np.zeros((size, size, 4), dtype=np.float32)
    y0, x0 = (size - nh) // 2, (size - nw) // 2
    out[y0:y0 + nh, x0:x0 + nw] = rgba[ys][:, xs]
    return out


def resize(pixels, height, width):
    """Area-averaged scale: each new pixel is the mean of what it covers, from the running sum along each axis."""
    for axis, size in ((0, height), (1, width)):
        pixels = np.moveaxis(pixels, axis, 0)
        count = pixels.shape[0]
        total = np.cumsum(pixels, axis=0, dtype=np.float64)
        total = np.concatenate([np.zeros_like(total[:1]), total])
        edges = np.linspace(0, count, size + 1)
        whole = np.minimum(edges.astype(int), count - 1)
        at = total[whole] + (edges - whole).reshape(-1, 1, 1) * pixels[whole]
        pixels = np.moveaxis(((at[1:] - at[:-1]) * size / count).astype(np.float32), 0, axis)
    return pixels


def write(target, y, x, text, scale=2, colour=INK):
    for i, ch in enumerate(text.upper()):
        bits = GLYPHS.get(ch, GLYPHS[" "])
        for r in range(5):
            for c in range(3):
                if bits[r * 3 + c] == "1":
                    ty, tx = y + r * scale, x + (i * 4 + c) * scale
                    target[ty:ty + scale, tx:tx + scale, :3] = colour


def stamp(target, y, x, text, scale=2, colour=INK):
    """Text on a dark box, readable over any frame."""
    target[y:y + 5 * scale + 4, x:x + len(text) * 4 * scale + 3, :3] *= 0.2
    write(target, y + 2, x + 2, text, scale, colour)


def label(tile, number, scale=4):
    write(tile, 6, 6, str(number), scale)


def number(text):
    """A number or a fraction: 0.08, 1/60."""
    top, _, bottom = text.partition("/")
    return float(top) / float(bottom or 1)


def box(text):
    return tuple(int(part) for part in text.split(","))


def beats(text):
    """Dip=0,Slip=0.08 into [(name, seconds)], in time order."""
    marks = [mark.split("=") for mark in text.split(",")]
    return sorted(((name, number(at)) for name, at in marks), key=lambda mark: mark[1])


def parse(args):
    sheet = argparse.ArgumentParser(prog="sheet.py strip")
    sheet.add_argument("out")
    sheet.add_argument("--title", default="")
    sheet.add_argument("--step", type=number, default=1 / 60)
    sheet.add_argument("--tile", type=int, default=150)
    sheet.add_argument("--cols", type=int, default=12)
    track = argparse.ArgumentParser(prog="sheet.py strip --track")
    track.add_argument("name")
    track.add_argument("frames", nargs="+")
    track.add_argument("--rate", type=number, default=60)
    track.add_argument("--start", type=number, default=0)
    track.add_argument("--crop", type=box)
    track.add_argument("--beats", type=beats, default=[])
    track.add_argument("--onion", type=int, default=3)
    track.add_argument("--same", type=float, default=0.02)  # the most any pixel of two 64 px copies may differ
    groups = [[]]
    for arg in args:
        if arg == "--track":
            groups.append([])
        else:
            groups[-1].append(arg)
    tracks = [track.parse_args(group) for group in groups[1:]]
    if not tracks:
        sheet.error("at least one --track")
    return sheet.parse_args(groups[0]), tracks


def read(track, sheet, onion_width):
    """Loads a track's frames: a tile, an onion copy and a 64 px copy of each crop, None for a missing step."""
    track.tile_width = max(1, round(1 / (track.rate * sheet.step))) * sheet.tile
    track.tiles, track.wide, track.small, track.repeats = [], [], [], []
    last = None
    for path in track.frames:
        if path == MISSING:
            for copies in (track.tiles, track.wide, track.small):
                copies.append(None)
            track.repeats.append(False)
            continue
        if not os.path.isfile(path):
            sys.exit(f"NL_STRIP {track.name}: no file {path}")
        picture = load(os.path.abspath(path))
        if track.crop:
            x, y, w, h = track.crop
            picture = picture[y:y + h, x:x + w]
            if not picture.size:
                sys.exit(f"NL_STRIP {track.name}: --crop misses {path}")
        rgb = picture[..., :3] * picture[..., 3:4]
        aspect = rgb.shape[1] / rgb.shape[0]
        small = resize(rgb, SMALL, round(SMALL * aspect))
        track.tiles.append(resize(rgb, round(track.tile_width / aspect), track.tile_width))
        track.wide.append(resize(rgb, round(onion_width / aspect), onion_width))
        track.small.append(small)
        track.repeats.append(last is not None and float(np.abs(small - last).max()) < track.same)
        last = small
    shapes = [tile for tile in track.tiles if tile is not None]
    if not shapes:
        sys.exit(f"NL_STRIP {track.name}: no frames")
    track.tile_height = shapes[0].shape[0]
    track.small_size = track.small[track.tiles.index(shapes[0])].shape[:2]
    track.times = [track.start + i / track.rate for i in range(len(track.frames))]


def beat_at(track, seconds):
    """The index of the latest beat begun by this time, None before the first (as the Stage's stamp reads a beat)."""
    latest = None
    for i, (_, at) in enumerate(track.beats):
        if at <= seconds + 1e-6:
            latest = i
    return latest


def tile_for(track, i):
    """Frame i's tile with its stamp, its beat's band and any beat that starts on it."""
    tile = np.full((track.tile_height, track.tile_width, 3), SHEET_GROUND, dtype=np.float32)
    seconds = track.times[i]
    if track.tiles[i] is None:
        stamp(tile, track.tile_height // 2 - 7, 8, "MISSING")
    else:
        tile[:] = track.tiles[i]
    stamp(tile, 2, 2, f"{seconds:.3f}" + (" =" if track.repeats[i] else ""))
    beat = beat_at(track, seconds)
    if beat is not None:
        colour = BEAT_COLOURS[beat % len(BEAT_COLOURS)]
        tile[-4:] = colour
        if i == 0 or beat_at(track, track.times[i - 1]) != beat:
            tile[:, :2] = colour
            stamp(tile, track.tile_height - 20, 3, track.beats[beat][0], colour=colour)
    return tile


def track_row(track, sheet, width, first):
    """One row of the time grid, this track's tiles at their columns and its name up the gutter; None if it has none."""
    shown = [(i, column) for i, column in enumerate(track.columns) if first <= column < first + sheet.cols]
    if not shown:
        return None
    row = np.full((track.tile_height, width, 3), NO_FRAME_GROUND, dtype=np.float32)
    for i, column in shown:
        x = GUTTER + (column - first) * sheet.tile
        fits = min(track.tile_width, width - x)  # a tile past the row's end is cut, never moved off its time
        row[:, x:x + fits] = tile_for(track, i)[:, :fits]
    name = np.full((GUTTER, track.tile_height, 3), SHEET_GROUND, dtype=np.float32)
    write(name, 2, 2, track.name, 2, NAME_COLOUR)
    row[:, :GUTTER] = np.rot90(name)
    return row


def onion(pictures, every):
    """The moving parts of every Nth frame over what stays (their median), so spacing and arcs read in one picture."""
    picked = [picture for picture in pictures[::every] if picture is not None]
    ground = np.median(np.stack(picked), axis=0)
    out = ground.copy()
    for i, picture in enumerate(picked):
        age = i / max(1, len(picked) - 1)
        moved = np.abs(picture - ground).max(axis=-1, keepdims=True)
        alpha = np.clip((moved - ONION_MOVED[0]) / (ONION_MOVED[1] - ONION_MOVED[0]), 0, 1) * (0.35 + 0.6 * age)
        tint = ONION_FIRST * (1 - age) + ONION_LAST * age
        out = out * (1 - alpha) + (picture * 0.6 + tint * 0.4) * alpha
    return out.astype(np.float32)


def onion_band(tracks, width, onion_width):
    shown = [track for track in tracks if track.onion > 0]
    if not shown:
        return None
    pictures = [onion(track.wide, track.onion) for track in shown]
    band = np.full((max(p.shape[0] for p in pictures), width, 3), SHEET_GROUND, dtype=np.float32)
    for n, (track, picture) in enumerate(zip(shown, pictures)):
        x = GUTTER + n * (onion_width + 6)
        band[:picture.shape[0], x:x + onion_width] = picture
        stamp(band, 2, x + 2, f"{track.name} onion, every {track.onion}, cool first")
    return band


def small_band(track, width):
    """One row at play distance: as many of the frames as fit, evenly spaced, a missing one left empty."""
    height, small_width = track.small_size
    fits = max(1, (width - GUTTER) // (small_width + 2))
    every = max(1, math.ceil(len(track.small) / fits))
    band = np.full((height + 16, width, 3), SHEET_GROUND, dtype=np.float32)
    for n, picture in enumerate(track.small[::every]):
        x = GUTTER + n * (small_width + 2)
        if picture is not None:
            band[14:14 + height, x:x + small_width] = picture
    write(band, 2, GUTTER, f"{track.name} {height} px, every {every}", 2, NAME_COLOUR)
    return band


def strip(args):
    sheet, tracks = parse(args)
    width = GUTTER + sheet.cols * sheet.tile
    onion_width = min(4 * sheet.tile, (width - GUTTER - 6 * (len(tracks) - 1)) // len(tracks))
    for track in tracks:
        if track.rate * sheet.step > 1 + 1e-6:
            sys.exit(f"NL_STRIP {track.name}: its rate is finer than the sheet's --step")
        read(track, sheet, onion_width)
    begin = min(track.times[0] for track in tracks)
    for track in tracks:
        track.columns = [round((seconds - begin) / sheet.step) for seconds in track.times]
    steps = max(track.columns[-1] for track in tracks) + 1

    bands = []
    if sheet.title:
        title = np.full((30, width, 3), SHEET_GROUND, dtype=np.float32)
        write(title, 7, 6, sheet.title, 3)
        bands.append(title)
    for first in range(0, steps, sheet.cols):
        rows = [track_row(track, sheet, width, first) for track in tracks]
        bands.extend(row for row in rows if row is not None)
        bands.append(np.full((6, width, 3), SHEET_GROUND, dtype=np.float32))
    picture = onion_band(tracks, width, onion_width)
    if picture is not None:
        bands.append(picture)
    bands.extend(small_band(track, width) for track in tracks)
    pixels = np.concatenate(bands, axis=0)

    height = pixels.shape[0]
    rgba = np.concatenate([pixels, np.ones((height, width, 1), dtype=np.float32)], axis=-1)
    out = os.path.abspath(sheet.out)
    image = bpy.data.images.new("strip", width, height, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(rgba[::-1]).ravel())
    image.filepath_raw = out
    image.file_format = "PNG"
    image.save()
    print(f"NL_STRIP wrote {out} {width}x{height}")
    if max(width, height) > VIEW_LIMIT:
        print(f"NL_STRIP long side {max(width, height)} px, past {VIEW_LIMIT}: a view shrinks it; lower --tile")
    for track in tracks:
        frames = sum(tile is not None for tile in track.tiles)
        repeats = " ".join(f"{seconds:.3f}" for seconds, same in zip(track.times, track.repeats) if same)
        print(f"NL_STRIP {track.name}: {frames} frames, {len(track.tiles) - frames} missing, "
              f"{track.times[0]:.3f} to {track.times[-1]:.3f} s, repeats: {repeats or 'none'}")


def contact_sheet(args):
    out, size, paths = args[0], int(args[1]), args[2:]
    columns = min(6, len(paths))
    rows = math.ceil(len(paths) / columns)
    sheet = np.zeros((rows * size, columns * size, 4), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size]
    checker = np.where(((yy // 16) + (xx // 16)) % 2 == 0, 0.07, 0.11)[..., None] * np.array([1.0, 0.9, 1.1])
    for i, path in enumerate(paths):
        art = fit(load(path), size)
        alpha = art[..., 3:4]
        tile = np.concatenate([checker * (1 - alpha) + art[..., :3] * alpha, np.ones((size, size, 1))], axis=-1)
        label(tile, i + 1)
        r, c = divmod(i, columns)
        sheet[r * size:(r + 1) * size, c * size:(c + 1) * size] = tile
    image = bpy.data.images.new("sheet", columns * size, rows * size, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(sheet[::-1]).ravel())
    image.filepath_raw = out
    image.file_format = "PNG"
    image.save()
    print("NL_SHEET wrote", out)


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if args[0] == "strip":
        strip(args[1:])
    else:
        contact_sheet(args)


main()
