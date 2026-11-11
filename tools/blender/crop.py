"""crops boxes (x0, y0, x1, y1 in pixels from the top left) out of a PNG into one row.
blender -b --factory-startup --python crop.py -- <in.png> <out.png> x0,y0,x1,y1 [...]"""
import sys
from pathlib import Path

import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1:]
args[:2] = [str(Path(a).resolve()) for a in args[:2]]  # absolute: Blender saves a relative path at the drive's root
image = bpy.data.images.load(args[0])
w, h = image.size
pixels = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]  # the top row first
boxes = [tuple(int(v) for v in a.split(",")) for a in args[2:]]
tiles = [pixels[y0:y1, x0:x1] for x0, y0, x1, y1 in boxes]
H = max(t.shape[0] for t in tiles)
W = sum(t.shape[1] for t in tiles) + 4 * (len(tiles) - 1)
out = np.zeros((H, W, 4), dtype=np.float32)
out[..., 3] = 1.0
x = 0
for t in tiles:
    out[:t.shape[0], x:x + t.shape[1]] = t
    x += t.shape[1] + 4
result = bpy.data.images.new("crop", W, H, alpha=True)
result.pixels = out[::-1].ravel()
result.filepath_raw = args[1]
result.file_format = "PNG"
result.save()
print(f"[crop] {args[1]}: {W}x{H}")
