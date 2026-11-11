"""PNGs tiled into one sheet, left to right and top to bottom, in Blender's Python (no PIL here).
blender -b --factory-startup --python tile.py -- <out.png> <columns> [scale <f>] [gap <px>] <png>...
Internal study only when the inputs hold reference frames: keep the sheet in a gitignored folder."""
import sys
from pathlib import Path

import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1:]
out, columns, rest = str(Path(args[0]).resolve()), int(args[1]), args[2:]  # absolute: Blender saves a relative path at the drive's root
scale, gap = 1.0, 0
while rest and rest[0] in ("scale", "gap"):
    if rest[0] == "scale":
        scale = float(rest[1])
    else:
        gap = int(rest[1])
    rest = rest[2:]


def load(path):
    image = bpy.data.images.load(path)
    w, h = image.size
    array = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(array)
    bpy.data.images.remove(image)
    array = array.reshape(h, w, 4)
    if scale != 1.0:
        nw, nh = round(w * scale), round(h * scale)
        array = array[(np.arange(nh) * h / nh).astype(int)][:, (np.arange(nw) * w / nw).astype(int)]
    return array


tiles = [load(str(Path(p).resolve())) for p in rest]  # absolute, as Blender reads and writes relative paths at the drive's root
h, w = max(t.shape[0] for t in tiles), max(t.shape[1] for t in tiles)
rows = (len(tiles) + columns - 1) // columns
H, W = rows * h + (rows - 1) * gap, columns * w + (columns - 1) * gap
sheet = np.zeros((H, W, 4), dtype=np.float32)
sheet[..., :3], sheet[..., 3] = 0.12, 1.0
for i, tile in enumerate(tiles):
    r, c = divmod(i, columns)
    top = r * (h + gap)  # from the sheet's top; Blender's pixels start at the bottom row
    y0 = H - top - tile.shape[0]
    x0 = c * (w + gap)
    sheet[y0:y0 + tile.shape[0], x0:x0 + tile.shape[1]] = tile
image = bpy.data.images.new("Sheet", W, H, alpha=True)
image.pixels.foreach_set(sheet.ravel())
image.filepath_raw = out
image.file_format = "PNG"
image.save()
print(f"[tile] {out}: {len(tiles)} tiles, {W}x{H}")
